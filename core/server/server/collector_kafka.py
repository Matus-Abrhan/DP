from kafka import KafkaConsumer, KafkaAdminClient
from kafka.admin.new_partitions import NewPartitions
from kafka.admin.new_topic import NewTopic
from multiprocessing import Process
from server.collector import Collector
from threading import Thread
import logging
import socket
import signal
import json

from server.general.utils import RequestIdentifier, WIN_EVENT_OBJECT
from server.general.utils import RWQueue, ProcessCommand

logger = logging.getLogger(__name__)

BOOTSTRAP_SERVER = '192.168.122.31:9092'


class KafkaCollectorProcess(Process):
    def __init__(self, event_q, manager_rw, app_rw,
                 host=None, port=None) -> None:
        super().__init__()
        self.event_q = event_q
        self.manager_rw = manager_rw
        self.app_rw: RWQueue = app_rw

    def menu(self):
        while True:
            command = None
            data = None
            source = None

            if not self.manager_rw.empty():
                command, data = self.manager_rw.get()
                source = 'manager'
            elif not self.app_rw.empty():
                command, data = self.app_rw.get()
                source = 'app'

            if command == ProcessCommand.REGISTER and source == 'manager':
                id, addr, partition = data.split('#')
                with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
                    data = '#'.join([id, partition])
                    s.sendto(bytes(data, 'utf-8'), (addr, 9002))
            elif command == ProcessCommand.REGISTER and source == 'app':
                pass
            elif command == ProcessCommand.UNREGISTER and source == 'manager':
                pass
            elif command == ProcessCommand.STATUS and source == 'app':
                self.manager_rw.put((command, data))
            elif command == ProcessCommand.STATUS and source == 'manager':
                self.app_rw.put((command, data))

    def run(self):
        signal.signal(signal.SIGINT, signal.SIG_IGN)

        kafka_admin = KafkaAdminClient(bootstrap_servers=BOOTSTRAP_SERVER)
        consumer = KafkaConsumer(bootstrap_servers=BOOTSTRAP_SERVER)

        topic_list = kafka_admin.list_topics()
        num_partitions = dict()
        for iden in RequestIdentifier:
            if iden.value not in topic_list:
                print(f'created topic {iden.value}')
                kafka_admin.create_topics([
                    NewTopic(iden.value,
                             num_partitions=1,
                             replication_factor=1)
                ])
            part = consumer.partitions_for_topic(iden.value)
            if part is not None:
                num_partitions[iden.value] = len(part)

        subscribe_list = [
            RequestIdentifier.WIN_EVENT.value,
            RequestIdentifier.REGISTER.value,
            RequestIdentifier.UNREGISTER.value
        ]
        consumer.subscribe(subscribe_list)

        def kafka_winevt_loop():
            for msg in consumer:
                print(msg)
                identifier: RequestIdentifier = RequestIdentifier(msg.topic)

                if identifier is RequestIdentifier.WIN_EVENT:
                    client_id = msg.key
                    try:
                        (iden, client_id, data) = msg.value.decode(
                            'utf-8').split('#')
                    except ValueError:
                        continue
                    data_list = json.loads(data)
                    event = WIN_EVENT_OBJECT.get_event(data_list)
                    if event is not None:
                        self.event_q.put((client_id, event))
                elif identifier is RequestIdentifier.REGISTER:
                    client_addr = msg.key.decode('utf-8')
                    topic = msg.value.decode('utf-8')
                    kafka_admin.create_partitions(
                        {topic: NewPartitions(num_partitions[topic]+1)})
                    self.manager_rw.put((
                        ProcessCommand.REGISTER,
                        '#'.join([client_addr, str(num_partitions[topic]-1)])))
                    num_partitions[topic] += 1
                    consumer.subscribe(subscribe_list)
                elif identifier is RequestIdentifier.UNREGISTER:
                    client_id = msg.key.decode('utf-8')
                    self.manager_rw.put((
                        ProcessCommand.UNREGISTER,
                        client_id))
                elif identifier is RequestIdentifier.RAW:
                    pass

        self.server_thread = Thread(target=kafka_winevt_loop)
        self.server_thread.start()

        self.menu()

    def terminate(self):
        self.manager_rw.put((ProcessCommand.STOP, ''))
        super().terminate()


class KafkaCollector(Collector):

    def start_collection(self, event_q, manager_rw, app_rw,
                         host=None, port=None) -> None:
        self.server_process = KafkaCollectorProcess(
            event_q, manager_rw, app_rw)
        self.server_process.start()
        print('Starting Collector')
        logger.info('Starting Collector')

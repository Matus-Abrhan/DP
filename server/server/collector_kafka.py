from kafka import KafkaConsumer, KafkaAdminClient, KafkaProducer
from kafka.admin.new_topic import NewTopic
from multiprocessing import Process
from server.collector import Collector
from threading import Thread
import logging
import socket
import signal
import json

from server.general.utils import RequestIdentifier, WIN_EVENT_OBJECT
from server.general.utils import RWQueue, ProcessCommand, Encoding

logger = logging.getLogger(__name__)

BOOTSTRAP_SERVER = '10.110.110.160:9092'


class KafkaCollectorProcess(Process):
    def __init__(self, event_q, manager_rw, app_rw,
                 host=None, port=None) -> None:
        super().__init__()
        self.event_q = event_q
        self.manager_rw = manager_rw
        self.app_rw: RWQueue = app_rw

    def menu(self):
        self.producer = KafkaProducer(bootstrap_servers=[BOOTSTRAP_SERVER])
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
                id = data['id']
                addr = data['addr']
                with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
                    s.sendto(Encoding.encode(id), (addr, 9002))
            elif command == ProcessCommand.REGISTER and source == 'app':
                pass
            elif command == ProcessCommand.UNREGISTER and source == 'manager':
                pass
            elif command == ProcessCommand.STATUS and source == 'app':
                self.manager_rw.put((command, data))
            elif command == ProcessCommand.STATUS and source == 'manager':
                self.app_rw.put((command, data))
            elif command == ProcessCommand.RESULT and source == 'manager':
                id = data['id']
                msg = data['msg']
                self.producer.send(RequestIdentifier.RESULT.value,
                                   key=Encoding.encode(id),
                                   value=Encoding.encode(msg))

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
            while True:
                part = consumer.partitions_for_topic(iden.value)
                if part is not None:
                    num_partitions[iden.value] = len(part)
                    break

        subscribe_list = [
            RequestIdentifier.WIN_EVENT.value,
            RequestIdentifier.REGISTER.value,
            RequestIdentifier.UNREGISTER.value,
            RequestIdentifier.RESULT.value
        ]
        consumer.subscribe(subscribe_list)

        def kafka_winevt_loop() -> None:
            for msg in consumer:
                identifier: RequestIdentifier = RequestIdentifier(msg.topic)

                if identifier is RequestIdentifier.WIN_EVENT:
                    client_id = Encoding.decode(msg.key)
                    data = Encoding.decode(msg.value)
                    data_list = json.loads(data)
                    event = WIN_EVENT_OBJECT.get_event(data_list)
                    if event is not None:
                        self.event_q.put((client_id, event))

                elif identifier is RequestIdentifier.REGISTER:
                    client_addr = Encoding.decode(msg.key)

                    self.manager_rw.put((
                        ProcessCommand.REGISTER, {'addr': client_addr}))

                elif identifier is RequestIdentifier.UNREGISTER:
                    client_id = Encoding.decode(msg.key)
                    self.manager_rw.put((
                        ProcessCommand.UNREGISTER, {'id': client_id}))
                elif identifier is RequestIdentifier.RAW:
                    pass

        self.server_thread = Thread(target=kafka_winevt_loop)
        self.server_thread.start()

        self.menu()

    def terminate(self):
        self.manager_rw.put((ProcessCommand.STOP, {}))
        super().terminate()


class KafkaCollector(Collector):

    def start_collection(self, event_q, manager_rw, app_rw,
                         host=None, port=None) -> None:
        self.server_process = KafkaCollectorProcess(
            event_q, manager_rw, app_rw)
        self.server_process.start()
        print('Starting Collector')
        logger.info('Starting Collector')

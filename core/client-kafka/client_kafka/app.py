
from winevt import EventLog
from socket import socket, AF_INET, SOCK_DGRAM, gethostbyname, gethostname
from kafka import KafkaProducer
from contextlib import contextmanager
from queue import Queue
import xmltodict
from collections import OrderedDict
from typing import List, Dict
import re

from client_kafka.general.utils import Encoding, RequestIdentifier
from client_kafka.general.utils import WIN_EVENT_OBJECT

event_queue: Queue = Queue()


class Capture:
    SYSLOG_PATH = 'Microsoft-Windows-Sysmon/Operational'

    def __init__(self, ip_addr: str, port: int) -> None:
        self.ip_addr = ip_addr
        self.port = port
        self.producer = KafkaProducer(
            bootstrap_servers=[f'{self.ip_addr}:{self.port}'])

    @staticmethod
    def _handle_event(action, p_context, event):
        event_queue.put(event.xml)

    @contextmanager
    def cm(self):
        log_sess = EventLog.Subscribe(path=self.SYSLOG_PATH,
                                      query='*',
                                      callback=Capture._handle_event)
        self.register()

        yield self

        log_sess.unsubscribe()
        self.unregister()

    def register(self):
        with socket(AF_INET, SOCK_DGRAM) as s:
            s.bind(('', 9002))

            self.producer.send(
                RequestIdentifier.REGISTER.value,
                key=bytes(gethostbyname(gethostname()), 'utf-8'),
                value=bytes(RequestIdentifier.WIN_EVENT.value, 'utf-8'),
                partition=0)

            data, server = s.recvfrom(1024)
            print("Registered")
            data = data.decode('utf-8')
            id, partition = data.split('#')
            self.id = id
            self.partition = int(partition)
            print(id)

        while self.partition not in self.producer.partitions_for(RequestIdentifier.WIN_EVENT.value):
            pass
        print(partition)

    def unregister(self):
        self.producer.send(RequestIdentifier.UNREGISTER.value,
                           key=bytes(self.id, 'utf-8'),
                           value=b'',
                           partition=0)

    def send(self):
        try:
            while True:
                xml_event = event_queue.get()
                event_dict = self.process_xml(xml_event)
                event = WIN_EVENT_OBJECT.get_event(event_dict)
                msg = RequestIdentifier.WIN_EVENT.add_data([self.id, event])
                msg = Encoding.encode(msg)

                print(msg)
                self.producer.send(
                    RequestIdentifier.WIN_EVENT.value,
                    key=bytes(self.id, 'utf-8'),
                    value=msg,
                    partition=self.partition)
        except KeyboardInterrupt:
            pass

    def process_xml(self, xml_event) -> Dict[str, str]:
        event_full = xmltodict.parse(
            xml_event, attr_prefix='', cdata_key='text')

        data = OrderedDict()
        data['system'] = event_full['Event']['System']
        data['eventData'] = self.join_elements(
            event_full['Event']['EventData']['Data'])

        flat_data = OrderedDict()
        self.flatten(data, flat_data)
        return flat_data

    def join_elements(self, data_list: List[Dict]):
        res = OrderedDict()
        for item in data_list:
            key = item.get('Name', None)
            value = item.get('text', None)
            if key and value:
                res[key] = value
        return {'Data': res}

    def flatten(self, branch: Dict, target: Dict, path: str = ''):
        for key, value in branch.items():
            new_path = key if not path else f'{path}{key}'
            if isinstance(value, Dict):
                self.flatten(value, target, new_path)
            elif isinstance(value, str):
                value = re.sub('["#]+', '', value)
                value = re.sub('[\n]+', ' ', value)
                target[new_path] = value
            else:
                target[new_path] = value

from winevt import EventLog
from socket import socket, AF_INET, SOCK_DGRAM
from contextlib import contextmanager
from queue import Queue
import xmltodict
from collections import OrderedDict
from typing import List, Dict
import re

from client.general.utils import Encoding, RequestIdentifier, WIN_EVENT_OBJECT

event_queue: Queue = Queue()


class Capture:
    SYSLOG_PATH = 'Microsoft-Windows-Sysmon/Operational'

    def __init__(self, ip_addr: str, port: int) -> None:
        self.ip_addr = ip_addr
        self.port = port

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

            msg = RequestIdentifier.REGISTER.add_data(['', ''])
            msg = Encoding.encode(msg)
            s.sendto(msg, (self.ip_addr, self.port))

            data, server = s.recvfrom(1024)
            print("Registered")
            id = data.decode('utf-8')
            self.id = id
            print(id)

    def unregister(self):
        with socket(AF_INET, SOCK_DGRAM) as s:
            msg = RequestIdentifier.UNREGISTER.add_data([self.id, ''])
            msg = Encoding.encode(msg)
            s.sendto(msg, (self.ip_addr, self.port))
            print("Unregistered")

    def send(self):
        keys = set()
        with socket(AF_INET, SOCK_DGRAM) as s:
            with open('event_log.txt', 'w+') as f:
                while True:
                    try:
                        xml_event = event_queue.get()
                        event_dict = self.process_xml(xml_event, keys)
                        event = WIN_EVENT_OBJECT.get_event(event_dict)
                        f.write(event + '\n')
                        msg = RequestIdentifier.WIN_EVENT.add_data(
                            [self.id, event])
                        msg = Encoding.encode(msg)
                        s.sendto(msg, (self.ip_addr, self.port))
                    except KeyboardInterrupt:
                        break

    def process_xml(self, xml_event, keys) -> Dict[str, str]:
        event_full = xmltodict.parse(
            xml_event, attr_prefix='', cdata_key='text')

        data = OrderedDict()
        data['system'] = event_full['Event']['System']
        data['eventData'] = self.join_elements(
            event_full['Event']['EventData']['Data'])

        flat_data = OrderedDict()
        self.flatten(data, flat_data)
        keys.update(flat_data.keys())
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

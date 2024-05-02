from winevt import EventLog
from socket import socket, AF_INET, SOCK_DGRAM
from contextlib import contextmanager
from queue import Queue
import json
import xmltodict
from collections import OrderedDict
from typing import List, Dict

from client.general.utils import Encoding, RequestIdentifier

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
        yield self

        log_sess.unsubscribe()

    def send(self):
        keys = set()
        with socket(AF_INET, SOCK_DGRAM) as s:
            while True:
                try:
                    xml_event = event_queue.get()
                    event = self.process_xml(xml_event, keys)
                    msg = RequestIdentifier.WIN_EVENT.add_data(event)
                    msg = Encoding.encode(msg)
                    s.sendto(msg, (self.ip_addr, self.port))
                except KeyboardInterrupt:
                    break
        event_def = dict()
        for key in keys:
            event_def[key] = 'string'
        print(json.dumps(event_def))

    def process_xml(self, xml_event, keys):
        event_full = xmltodict.parse(
            xml_event, attr_prefix='', cdata_key='text')

        data = OrderedDict()
        data['System'] = event_full['Event']['System']
        data['EventData'] = self.join_elements(
            event_full['Event']['EventData']['Data'])

        flat_data = OrderedDict()
        self.flatten(data, flat_data)
        for key, value in flat_data.items():
            keys.add(key)
        return json.dumps(flat_data)

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
            new_path = key if not path else f'{path}.{key}'
            if isinstance(value, Dict):
                self.flatten(value, target, new_path)
            else:
                target[new_path] = value

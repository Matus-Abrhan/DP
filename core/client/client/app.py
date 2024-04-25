from winevt import EventLog
from socket import socket, AF_INET, SOCK_DGRAM
from contextlib import contextmanager
from queue import Queue

from client.general.utils import AESCypher, RequestIdentifier

event_queue: Queue = Queue()


class Capture:
    SYSLOG_PATH = 'Microsoft-Windows-Sysmon/Operational'

    def __init__(self, ip_addr: str, port: int) -> None:
        self.ip_addr = ip_addr
        self.port = port

    @staticmethod
    def _handle_event(action, p_context, event):
        # print(event.xml)
        event_queue.put(event.xml)

    @contextmanager
    def cm(self):
        log_sess = EventLog.Subscribe(path=self.SYSLOG_PATH,
                                      query='*',
                                      callback=self._handle_event)
        yield self

        log_sess.unsubscribe()

    def send(self):
        with socket(AF_INET, SOCK_DGRAM) as s:
            while True:
                try:
                    event = event_queue.get()
                    msg = RequestIdentifier.WIN_EVENT.add_data(event)
                    msg = AESCypher.encrypt(msg)
                    s.sendto(msg, (self.ip_addr, self.port))
                except KeyboardInterrupt:
                    break

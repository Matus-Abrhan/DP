from time import sleep
from contextlib import contextmanager
import logging
from typing import Optional
import socketserver
import socket
import signal
import json
from functools import partial
from multiprocessing import Process, Queue
from threading import Thread

from server.general.utils import Encoding, RequestIdentifier, WIN_EVENT_OBJECT
from server.general.utils import RWQueue, ProcessCommand, CLIENT_ID_BYTES

logger = logging.getLogger(__name__)


class RequestHandler(socketserver.BaseRequestHandler):
    def handle(self) -> None:
        # logger.debug(f'Handling request {self.request}')
        enc_request: bytes = self.request[0]
        encoding = Encoding()
        request = encoding.decode(enc_request)
        client_addr = self.client_address[0]
        try:
            (iden, client_id, data) = request.split('#')
        except ValueError as e:
            logger.warning(f'Incorrect request format from user {client_addr}')
            logger.warning(e)
            return
        identifier: RequestIdentifier = RequestIdentifier(iden)
        # Sysmon events
        if identifier is RequestIdentifier.WIN_EVENT:
            data_list = json.loads(data)
            event = WIN_EVENT_OBJECT.get_event(data_list)
            if event is not None:
                # logger.debug(f'writeing to queue: {event}')
                self.server.event_q.put((client_id, event))
        elif identifier is RequestIdentifier.REGISTER:
            self.server.manager_rw.put((ProcessCommand.REGISTER, client_addr))
        elif identifier is RequestIdentifier.UNREGISTER:
            self.server.manager_rw.put((ProcessCommand.UNREGISTER, client_id))
        elif identifier is RequestIdentifier.RAW:
            logger.debug(f'writing to queue: {data}')
            self.server.event_q.put((client_addr, data))


class CustomServer(socketserver.ThreadingUDPServer):
    def __init__(self, event_q, manager_rw, *args, **kwargs) -> None:
        self.event_q: Queue = event_q
        self.manager_rw: RWQueue = manager_rw

        super().__init__(*args, **kwargs)


class CollectorProcess(Process):
    def __init__(self, event_q, manager_rw, app_rw,
                 host=None, port=None) -> None:
        super().__init__()
        self.app_rw: RWQueue = app_rw
        self.host: str = '0.0.0.0' if not host else host
        self.port: int = 9001 if not port else port

        Server = partial(CustomServer, event_q, manager_rw)
        self.server = Server((self.host, self.port), RequestHandler)

    def menu(self):
        while True:
            command = None
            data = None
            source = None

            if not self.server.manager_rw.empty():
                command, data = self.server.manager_rw.get()
                source = 'manager'
            elif not self.app_rw.empty():
                command, data = self.app_rw.get()
                source = 'app'

            if command == ProcessCommand.REGISTER and source == 'manager':
                id, addr = data.split('#')
                with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
                    s.sendto(int(id).to_bytes(CLIENT_ID_BYTES), (addr, 9002))

            elif command == ProcessCommand.REGISTER and source == 'app':
                self.server.manager_rw.put((command, data))

            elif command == ProcessCommand.UNREGISTER and source == 'manager':
                pass

            elif command == ProcessCommand.STATUS and source == 'app':
                self.server.manager_rw.put((command, data))

            elif command == ProcessCommand.STATUS and source == 'manager':
                self.app_rw.put((command, data))

    def run(self):
        signal.signal(signal.SIGINT, signal.SIG_IGN)

        self.server_thread = Thread(
            target=self.server.serve_forever,
        )
        self.server_thread.start()
        print(f'Starting Collector server {self.host}, {self.port}')

        self.menu()

    def terminate(self):
        self.server.server_close()
        self.server.manager_rw.put((ProcessCommand.STOP, ''))
        super().terminate()


class Collector:
    def __init__(self) -> None:
        self.server_process: Optional[Process] = None

    def start_collection(self, event_q, manager_rw, app_rw,
                         host=None, port=None) -> None:
        self.server_process = CollectorProcess(event_q, manager_rw, app_rw)
        self.server_process.start()
        print('Starting Collector')
        logger.info('Starting Collector')

    @contextmanager
    def cm(self, event_q: Queue, manager_rw: RWQueue, app_rw: RWQueue,
           delay: float = .1):
        self.start_collection(event_q, manager_rw, app_rw)
        sleep(delay)
        yield self

        sleep(delay)
        self.quit()

    def quit(self) -> None:
        print('Stopping Collector')
        logger.info('Stopping Collector')
        if isinstance(self.server_process, Process):
            self.server_process.terminate()
            self.server_process.join()

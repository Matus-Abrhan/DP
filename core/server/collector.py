import logging
from typing import List, Optional, Generator
import socketserver
import json
from enum import Enum
from functools import partial
from multiprocessing import Process, Queue
from contextlib import contextmanager
from time import sleep

from general.utils import AESCypher

logger = logging.getLogger(__name__)


class RequestIdentifier(Enum):
    RAW = 'raw'
    WIN_EVENT = 'winevt'
    EXIT = 'exit'


class RequestHandler(socketserver.BaseRequestHandler):
    def handle(self) -> None:
        logger.debug(f'Handling request {self.request}')
        enc_request: bytes = self.request[0]
        crypto = AESCypher()
        request = crypto.decrypt(enc_request)
        client_addr = self.client_address[0]
        (iden, data) = request.split('#')
        identifier: RequestIdentifier = RequestIdentifier(iden)
        # Sysmon events
        if identifier is RequestIdentifier.WIN_EVENT:
            event = Collector.parse_win_event(
                self.server.onto_prim_types,
                data)
            logger.debug(f'writeing to queue: {event}')
            self.server.queue.put((client_addr, event))

        elif identifier is RequestIdentifier.RAW:
            logger.debug(f'writeing to queue: {data}')
            self.server.queue.put((client_addr, data))

        elif identifier is RequestIdentifier.EXIT:
            logger.debug("Server shutting down")
            self.server.shutdown()


class CustomServer(socketserver.ThreadingUDPServer):
    def __init__(self, onto_prim_types, queue, *args, **kwargs):
        self.onto_prim_types = onto_prim_types
        self.queue = queue
        super().__init__(*args, **kwargs)


class Collector:
    def __init__(self, onto_prim_types: List[str], request_queue: Queue):
        self.onto_prim_types: List[str] = onto_prim_types
        self.request_queue: Queue = request_queue
        self.started: bool = True
        self.server_process: Optional[Process] = None

    def start_collection(self,
                         host: str = '0.0.0.0',
                         port: int = 9001) -> None:
        print(f'Starting Collector server {host}, {port}')
        logger.info(f'Starting Collector server {host}, {port}')

        Server = partial(
            CustomServer, self.onto_prim_types, self.request_queue)
        with Server((host, port), RequestHandler) as server:
            self.server_process = Process(target=server.serve_forever)
            self.server_process.start()
            if self.server_process.is_alive():
                self.started = True

    @contextmanager
    def cm(self, delay: float = .1):
        self.start_collection()
        sleep(delay)
        yield self

        sleep(delay)
        self.quit()

    def is_running(self) -> bool:
        alive = False
        if isinstance(self.server_process, Process):
            alive = self.server_process.is_alive()
        return self.started and alive

    def quit(self) -> None:
        logger.info('Quitting Collector')
        if isinstance(self.server_process, Process):
            self.server_process.kill()
        self.started = False

    @staticmethod
    def parse_win_event(data, onto_prim_types) -> str:
        try:
            flg = True
            curr_event = ''
            event = json.loads(data)
            c = 0
            for attribute in onto_prim_types:
                # vect_temp = []
                fl = False
                for evt_attribute, value in event.items():
                    evt_attribute_ = evt_attribute.lower().replace(
                        "eventdata.", "").replace(
                        "system.", "").replace('.', '_')
                    if attribute in evt_attribute_:
                        fl = True
                        if flg:
                            curr_event = 'e("' +\
                                str(value.encode(
                                    'utf-8',
                                    'ignore'
                                )).replace('"', '') + '","'
                            flg = False
                            c = c+1
                        else:
                            curr_event = curr_event + \
                                str(value.encode('utf-8', 'ignore')
                                    ).replace('"', '') + '","'
                            c = c+1
                if not fl:
                    if flg:
                        curr_event = 'e("","'
                        flg = False
                        c = c+1
                    else:
                        curr_event = curr_event + '","'
                        c = c+1
            curr_event = curr_event[:-2]
            if c == 39:
                curr_event = curr_event[:-3]
            if c == 40:
                curr_event = curr_event[:-3]
            if 'e("3"' in curr_event:
                curr_event = curr_event.replace(
                    '"","S-1-5-18"', '"S-1-5-18"')
            curr_event = curr_event + \
                (')' if curr_event.endswith('"') else '")')

            return curr_event

        except Exception as e:
            logger.error(f"Parse event error, {e}")
            return ''

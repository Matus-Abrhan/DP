import logging
from typing import Optional
import socketserver
import json
from functools import partial
from multiprocessing import Process, Queue
from contextlib import contextmanager
from time import sleep

from server.general.utils import Encoding, RequestIdentifier, WIN_EVENT_OBJECT

logger = logging.getLogger(__name__)


class RequestHandler(socketserver.BaseRequestHandler):
    def handle(self) -> None:
        logger.debug(f'Handling request {self.request}')
        enc_request: bytes = self.request[0]
        encoding = Encoding()
        request = encoding.decode(enc_request)
        client_addr = self.client_address[0]
        (iden, data) = request.split('#')
        identifier: RequestIdentifier = RequestIdentifier(iden)
        # Sysmon events
        if identifier is RequestIdentifier.WIN_EVENT:
            # event = Collector.parse_win_event(
            #    data,
            #    self.server.onto_prim_types
            # )
            data_dict = json.loads(data)
            event = WIN_EVENT_OBJECT.get_event(data_dict)
            logger.debug(f'writeing to queue: {event}')
            self.server.queue.put((client_addr, event))

        elif identifier is RequestIdentifier.REGISTER:
            pass

        elif identifier is RequestIdentifier.RAW:
            logger.debug(f'writeing to queue: {data}')
            self.server.queue.put((client_addr, data))

        elif identifier is RequestIdentifier.EXIT:
            logger.debug("Server shutting down")
            self.server.shutdown()


class CustomServer(socketserver.ThreadingUDPServer):
    def __init__(self, queue, *args, **kwargs):
        # self.onto_prim_types = onto_prim_types
        self.queue = queue
        super().__init__(*args, **kwargs)


class Collector:
    def __init__(self, request_queue: Queue):
        # self.onto_prim_types: List[str] = onto_prim_types
        self.request_queue: Queue = request_queue
        self.started: bool = True
        self.server_process: Optional[Process] = None

    def start_collection(self,
                         host: str = '0.0.0.0',
                         port: int = 9001) -> None:
        print(f'Starting Collector server {host}, {port}')
        logger.info(f'Starting Collector server {host}, {port}')

        Server = partial(
            CustomServer, self.request_queue)
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

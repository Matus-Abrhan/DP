import logging
import socketserver
import json
from functools import partial
from multiprocessing import Queue
from time import sleep

from general.utils import AESCypher

logger = logging.getLogger(__name__)


class RequestHandler(socketserver.BaseRequestHandler):
    def __init__(self, onto_prim_types, queue, *args, **kwargs):
        self.onto_prim_types = onto_prim_types
        self.queue = queue
        super().__init__(*args, **kwargs)

    def handle(self) -> None:
        logger.debug(f'Handling request {self.request}')
        enc_request: bytes = self.request[0]
        crypto = AESCypher()
        request = crypto.decrypt(enc_request)
        client_addr = self.client_address[0]
        (iden, data) = request.split('#')
        # Sysmon events
        if iden == "winevt":
            event = Collector.parse_win_event()

        # NOTE: for testing purposes
        elif iden == "raw":
            logger.debug(f'writeing to queue: {data}')
            self.queue.put((client_addr, data))

        elif iden == "exit":
            logger.debug("Server shutting down")
            self.server.shutdown()


class Collector:
    def __init__(self, onto_prim_types):
        self.onto_prim_types = onto_prim_types

    # @staticmethod
    def start_collection(onto_prim_types,
                         request_queue: Queue,
                         host: str = '0.0.0.0',
                         port: int = 9001) -> None:
        print(f'Starting cap server {host}, {port}')
        logger.info(f'Starting cap server {host}, {port}')
        handler = partial(
            RequestHandler, onto_prim_types, request_queue
        )

        with socketserver.UDPServer((host, port), handler) as server:
            # TODO: On specific request stop server
            server.serve_forever()

    def is_running(self):
        # TODO: Implement correct startup check
        pass

    def quit(self):
        # TODO: implement context manager and cleanup
        pass

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

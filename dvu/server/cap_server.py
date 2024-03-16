from typing import Dict, List
from pathlib import Path
import json
import sys
import yaml  # pip3 install yaml
import socketserver
import logging
from .wrapper_iASTD import iASTD
from multiprocessing import Process, Queue
import functools
from time import sleep

logger = logging.getLogger(__name__)


class RequestHandler(socketserver.BaseRequestHandler):
    # request, client_address, server, onto_prim_types):
    def __init__(self, onto_prim_types, queue, *args, **kwargs):
        self.onto_prim_types = onto_prim_types
        self.queue = queue
        super().__init__(*args, **kwargs)

    def handle(self) -> None:
        logger.debug(f'Handling request {self.request}')
        enc_data: bytes = self.request[0]
        crypto = AESCypher()
        data = crypto.decrypt(enc_data)
        self.queue.put(data)
        # client_addr = self.client_address[0]
        data_ = data.split('#')
        iden = data_[0]
        # Sysmon events
        if iden == "winevt":
            try:
                flg = True
                curr_event = ''
                event = json.loads(data_[1])
                c = 0
                for attribute in self.onto_prim_types:
                    # vect_temp = []
                    fl = False
                    for evt_attribute, value in event.items():
                        evt_attribute_ = evt_attribute.lower().replace(
                            "eventdata.", "").replace("system.", "").replace('.', '_')
                        if attribute in evt_attribute_:
                            fl = True
                            if flg:
                                curr_event = 'e("' + str(value.encode('utf-8',
                                                                      'ignore')).replace('"', '') + '","'
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

                # print(curr_event)
                logger.info(curr_event)
                self.queue.put(curr_event)

                # TODO: use queue for evaluation of events
                # queue.put(curr_event)
            except Exception as e:
                print(f"Parse event error, {e}")


class Collector:
    HOST = '0.0.0.0'
    PORT = 9001
    # ontology_types = {}

    def __init__(self, onto_spec_types: List[str] = ['WinEventLog']) -> None:
        config_file_path: Path = Path('./iASTD/config.yaml')
        with open(config_file_path, 'r') as config_file:
            config = yaml.load(config_file, Loader=yaml.FullLoader)
            json_onto_feeds: Path = Path(
                config['CONFIGS']['ONTOLOGY_CONFIGS']['FEED_CHANNELS']['channel1']['target']
            )

            onto_feeds: Dict[str, Dict[str, str]] = dict()
            if json_onto_feeds:
                with open(config_file_path.parent.absolute() /
                          json_onto_feeds, 'r') as feeds:
                    onto_feeds = json.load(feeds)

        self.onto_prim_types: List[str] = list(
            onto_feeds[onto_spec_types[0]].keys()
        )
        cplex_type = "wineventlog"

        self.root_iASTD = iASTD(
            Path('./iASTD/admin/server/spec/TEST/test.spec').absolute()
        )
        self.root_queue: Queue = Queue()
        self.collect_process = Process(
            target=self.start_collection,
            args=(self.HOST, self.PORT, self.onto_prim_types, self.root_queue)
        )
        self.collect_process.start()
        sleep(.5)

    @staticmethod
    def start_collection(host, port, onto_prim_types, root_queue) -> None:
        print(f'Starting cap server {host}, {port}')
        logger.info(f'Starting cap server {host}, {port}')
        # try:
        #    server_sock = socketserver.UDPServer(
        #        (self.HOST, self.PORT), xASTD_hcap_server)
        #    while True:
        #        event = server_sock.handle_request()
        #        logger.info(event)
        # except KeyboardInterrupt:
        #    sys.exit()
        # except (IOError, SystemExit):
        #    raise

        handler = functools.partial(
            RequestHandler, onto_prim_types, root_queue
        )

        with socketserver.UDPServer((host, port), handler) as server:
            server.serve_forever()

    def is_running(self):
        # TODO: Implement correct startup check
        pass

    def quit(self):
        # TODO: implement context manager and cleanup
        pass


class AESCypher:
    DECRYPT_KEY = 'HKLlbF514I09oYcv'

    def decrypt(self, msg: bytes) -> str:
        # aes = pyaes.AESModeOfOperationCTR(self.DECRYPT_KEY)
        # return aes.decrypt(msg)
        return str(msg, encoding='utf-8')


if __name__ == "__main__":
    app = Collector()
    while True:
        data = app.root_queue.get()
        print(data)

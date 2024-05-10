from typing import Dict, List, Union, Optional
import logging
from contextlib import contextmanager
from time import sleep
from multiprocessing import Process, Queue
from threading import Thread
import signal
import random

from server.wrapper.iASTD import iASTD
from server.wrapper.echoShell import echoShell
from server.general.utils import Spec, ProcessCommand, RWQueue, CLIENT_ID_BYTES

logger = logging.getLogger(__name__)


class ManagerProcess(Process):
    ROOT_CLIENT = '0'

    def __init__(self, event_q, collector_rw) -> None:
        super().__init__()
        self.event_q: Queue = event_q
        self.collector_rw: RWQueue = collector_rw
        self.clients: Dict[str, List[Union[iASTD, echoShell]]] = dict()

        self.clients[self.ROOT_CLIENT] = list()

    def status(self) -> Dict[str, str]:
        status = dict()

        status['events_processed'] = str(self.processed_counter)
        status['events_pending'] = str(self.event_q.qsize())
        status['clients'] = str(self.clients)
        return status

    def menu(self):

        while True:
            command, data = self.collector_rw.get()

            if command == ProcessCommand.STOP:
                for astd_list in self.clients.values():
                    for astd in astd_list:
                        astd.stop()
                break

            elif command == ProcessCommand.STATUS:
                data.update(self.status())
                self.collector_rw.put((command, data))

            elif command == ProcessCommand.REGISTER:
                r = random.getrandbits(CLIENT_ID_BYTES*8)
                _ = self.clients.setdefault(str(r), list())
                data = '#'.join([str(r), data])
                self.collector_rw.put((command, data))

            elif command == ProcessCommand.UNREGISTER:
                astd_list = self.clients.pop(data, list())
                for astd in astd_list:
                    astd.stop()

    def run(self):
        signal.signal(signal.SIGINT, signal.SIG_IGN)

        def read_loop() -> None:
            self.start_iASTD(self.ROOT_CLIENT, Spec.ROOT)
            self.processed_counter = 0
            while True:
                (client, event) = self.event_q.get()
                self.processed_counter += 1
                # logger.debug(f'read from queue: {(client, event)}')
                # print(f'read from queue: {(client, event)}')

                root_result = self.feed_root(event)
                # logger.info(root_result)
                print(f'Root: {root_result}')
                if len(root_result) > 0:
                    for result in set(root_result):
                        spec = Spec.value_of(result)
                        if isinstance(spec, Spec):
                            self.start_iASTD(client, spec)

                client_result = self.feed_client(client, event)
                print(f'{client}: {client_result}')

        self.read_thread = Thread(target=read_loop)
        self.read_thread.start()

        self.menu()

    def start_iASTD(self, client: str, spec: Spec) -> None:
        client_astds = self.clients.get(client, None)
        if client_astds is not None:
            client_astds.append(iASTD(spec))
            # self.clients[client] = client_astds

    def start_echo_shell(self, client: str, spec: Spec) -> None:
        client_astds = self.clients.get(client, None)
        if client_astds is not None:
            client_astds.append(echoShell(spec))
            # self.clients[client] = client_astds

    def feed_root(self, event: str) -> List[str]:
        return self.clients[self.ROOT_CLIENT][0].process_event(event)

    def feed_client(self, client: str, event: str) -> List[str]:
        astd_list = self.clients.get(client, None)

        result = list()
        remove_list = list()
        if astd_list:
            for idx, astd in enumerate(astd_list):
                if isinstance(astd, (iASTD, echoShell)):
                    instance_result = astd.process_event(event)
                    if len(instance_result) > 0 and 'exit' in instance_result:
                        remove_list.append(idx)
                    result.extend(instance_result)
            if len(remove_list) > 0:
                remove_list.reverse()
                for idx in remove_list:
                    # del astd_list[idx]
                    astd = astd_list.pop(idx)
                    astd.stop()

                # TODO: check if this assignment is needed
                self.clients[client] = astd_list
        return result


class Manager:
    def __init__(self) -> None:
        self.manager_process: Optional[Process] = None

    @contextmanager
    def cm(self, event_q, collector_rw, delay: float = .1):
        self.start_manager(event_q, collector_rw)
        sleep(delay)
        yield self

        sleep(delay)
        self.quit()

    def start_manager(self, event_q, collector_rw) -> None:
        self.manager_process = ManagerProcess(event_q, collector_rw)
        self.manager_process.start()
        print('Starting Manager')

    def quit(self) -> None:
        logger.info("Stopping Manager")
        print("Stopping Manager")
        if isinstance(self.manager_process, Process):
            self.manager_process.terminate()
            self.manager_process.join()

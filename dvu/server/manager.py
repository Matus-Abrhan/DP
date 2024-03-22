from typing import Dict, List, Union, Optional
import logging
from multiprocessing import Queue, Process
from pathlib import Path
from dataclasses import dataclass
from contextlib import contextmanager
from time import sleep

from server.wrapper_iASTD import iASTD, Spec
from server.wrapper_echoShell import echoShell
from general.utils import SERVER_DIR

logger = logging.getLogger(__name__)


@dataclass(eq=True, frozen=True)
class Client:
    ip: str
    mac: str


class Manager:
    ROOT_CLIENT = Client('0', '0')

    # def __del__(self):
    #    for instance in self.clients.values():
    #        for element in instance:
    #            element.stop()

    def __init__(self, request_queue: Queue) -> None:
        self.queue = request_queue
        self.clients: Dict[int, List[Union[iASTD, echoShell]]] = dict()
        self.start_echo_shell(
            self.ROOT_CLIENT
        )
        self.read_process: Optional[Process] = None
        logger.debug('Manager started')

    def start_iASTD(self, client: Client, spec: Spec) -> None:
        self.clients.setdefault(client.__hash__(), list()).append(iASTD(spec))

    def start_echo_shell(self, client: Client) -> None:
        self.clients.setdefault(client.__hash__(), list()).append(echoShell())

    def status(self) -> List[bool]:
        result: List[bool] = list()
        for instance in self.clients.values():
            for elem in instance:
                result.append(elem.is_running())
        return result

    @contextmanager
    def cm(self):
        self.start_manager()
        sleep(.1)
        yield self

        self.quit()

    def start_manager(self) -> None:
        def loop(queue: Queue, clients):
            while True:
                (ip_addr, event) = self.queue.get()
                logger.info((ip_addr, event))
                # client = Client(ip_addr, 'MAC')
                # for instance in clients.get(client.__hash__(), list()):
                #     instance.process_event(event)
                # logger.info(event)
                # print(event)
                # logger.info(Manager.ROOT_CLIENT.__hash__())
                result = clients[Manager.ROOT_CLIENT.__hash__()
                                 ][0].process_event(event)
                logger.info(result)
                # print(result)
        self.read_process = Process(
            target=loop,
            args=(self.queue, self.clients))
        self.read_process.start()
        logger.info("i should see this")

    def quit(self) -> None:
        if isinstance(self.read_process, Process):
            self.read_process.kill()

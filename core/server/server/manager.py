from typing import Dict, List, Union, Optional
import logging
from multiprocessing import Queue
from dataclasses import dataclass
from contextlib import contextmanager
from time import sleep
from threading import Thread

from server.wrapper.wrapper_iASTD import iASTD
from server.wrapper.wrapper_echoShell import echoShell
from server.general.utils import Spec

logger = logging.getLogger(__name__)


@dataclass(eq=True, frozen=True)
class Client:
    ip: str
    mac: str


class Manager:
    ROOT_CLIENT = Client('root', 'root')

    def __init__(self, request_queue: Queue, test: bool = True) -> None:
        self.queue = request_queue
        self.read_thread: Optional[Thread] = None

        self.clients: Dict[int, List[Union[iASTD, echoShell]]] = dict()

        if test:
            self.start_echo_shell(
                self.ROOT_CLIENT,
                Spec.ROOT
            )
        else:
            self.start_iASTD(
                self.ROOT_CLIENT,
                Spec.ROOT
            )

    def start_iASTD(self, client: Client, spec: Spec) -> None:
        self.clients.setdefault(
            client.__hash__(), list()).append(iASTD(spec))

    def start_echo_shell(self, client: Client, spec: Spec) -> None:
        self.clients.setdefault(
            client.__hash__(), list()).append(echoShell(spec))

    def feed_root(self, event: str) -> Optional[List[str]]:
        astd_list = self.clients.get(
            self.ROOT_CLIENT.__hash__(), None)

        result = None
        if astd_list:
            astd = astd_list[0]
            if isinstance(astd, (iASTD, echoShell)):
                result = astd.process_event(event)

        return result

    def feed_client(self,
                    client: Client,
                    event: str) -> List[Optional[List[str]]]:
        astd_list = self.clients.get(
            client.__hash__(), list())

        result = list()
        remove_list = list()
        if astd_list:
            for idx, astd in enumerate(astd_list):
                if isinstance(astd, (iASTD, echoShell)):
                    instance_result = astd.process_event(event)
                    if instance_result and 'exit' in instance_result:
                        remove_list.append(idx)
                    result.append(instance_result)
        if len(remove_list) > 0:
            remove_list.reverse()
            for idx in remove_list:
                del astd_list[idx]
            self.clients[client.__hash__()] = astd_list

        return result

    def status(self) -> List[bool]:
        result: List[bool] = list()
        for instance in self.clients.values():
            for elem in instance:
                result.append(elem.is_running())
        return result

    @contextmanager
    def cm(self, delay: float = .1):
        self.start_manager()
        sleep(delay)
        yield self

        sleep(delay)
        self.quit()

    def start_manager(self) -> None:
        if self.read_thread:
            return

        def loop() -> None:
            while True:
                (ip_addr, event) = self.queue.get()
                if not ip_addr and not event:
                    break
                logger.info(f'read from queue: {(ip_addr, event)}')

                client = Client(ip_addr, 'MAC')
                root_result = self.feed_root(event)
                if root_result:
                    spec = Spec.value_of(root_result[0])
                    if isinstance(spec, Spec):
                        self.start_iASTD(client, spec)

                client_result = self.feed_client(client, event)
                logger.info(
                    f'results: client={client_result}, root={root_result}')

        self.read_thread = Thread(
            target=loop,
        )
        self.read_thread.start()
        logger.info('Manager started')

    def quit(self) -> None:
        logger.info("Quitting Manager")
        for client in self.clients.values():
            for instance in client:
                instance.stop()
        if isinstance(self.read_thread, Thread):
            self.queue.put(('', ''))
            self.read_thread.join()

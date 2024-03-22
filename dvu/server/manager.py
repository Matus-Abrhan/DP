from typing import Dict, List
import logging
# from multiprocessing import Queue
from pathlib import Path
from dataclasses import dataclass

from server.wrapper_iASTD import iASTD, Spec
from general.utils import SERVER_DIR

logger = logging.getLogger(__name__)


@dataclass(eq=True, frozen=True)
class Client:
    ip: str
    mac: str


class Manager:
    ROOT_CLIENT = Client('0', '0')

    def __del__(self):
        for instance in self.clients.values():
            for element in instance:
                element.stop()

    def __init__(self) -> None:
        self.clients: Dict[int, List[iASTD]] = dict()
        self.start_iASTD(
            self.ROOT_CLIENT,
            Spec.TEST  # Spec.TEST
        )
        logger.info(self.clients)
        logger.info('Manager started')

    def start_iASTD(self, client: Client, spec: Spec) -> None:
        self.clients.setdefault(client.__hash__(), list()).append(iASTD(spec))

    def status(self) -> List[bool]:
        result: List[bool] = list()
        for instance in self.clients.values():
            for elem in instance:
                result.append(elem.is_running())
        return result

    @staticmethod
    def read_queue(clients: Dict[int, List[iASTD]],
                   request_queue) -> None:
        # def read_queue(self):
        while True:
            (ip_addr, event) = request_queue.get()
            logger.info((ip_addr, event))
            # client = Client(ip_addr, 'MAC')
            # for instance in clients.get(client.__hash__(), list()):
            #     instance.process_event(event)
            # logger.info(event)
            # print(event)
            # logger.info(Manager.ROOT_CLIENT.__hash__())
            # result = clients[Manager.ROOT_CLIENT.__hash__()
            #                  ][0].process_event(event)
            # logger.info(result)
            # print(result)

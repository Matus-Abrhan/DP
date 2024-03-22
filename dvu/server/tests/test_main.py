import pytest
from typing import List, Optional
from pathlib import Path
import logging
import socket
from time import sleep
from multiprocessing import Process, Queue

from server.main import Main
from server.manager import Spec, Client
from server.collector import Collector
from general.utils import SERVER_DIR

logger = logging.getLogger(__name__)


# @pytest.mark.skip(reason='Broken')
def test_root_astd_start() -> None:

    app = Main()
    app.manager.start_iASTD(
        Client(ip='1', mac='1'),
        Spec.TEST
    )
    app.manager.start_iASTD(
        Client(ip='2', mac='2'),
        Spec.PORTSCAN
    )
    result = app.manager.status()
    logger.info(result)
    assert all(result)


@pytest.mark.skip(reason='Broken')
def test_send_logs() -> None:
    app = Main()

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        event = 'e("72.5.65.99","53")'
        data = 'raw#' + event
        msg = bytes(data, encoding='utf-8')
        s.sendto(msg, ('127.0.0.1', 9001))

    sleep(2)
    res = app.request_queue.empty()
    logger.info(res)


def test_fuuuck() -> None:

    queue: Queue = Queue()
    collector_process = Process(
        target=Collector.start_collection,
        args=(None, queue)
    )
    collector_process.start()
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        for _ in range(10):
            event = 'e("72.5.65.99","53")'
            data = 'raw#' + event
            msg = bytes(data, encoding='utf-8')
            s.sendto(msg, ('127.0.0.1', 9001))
            res = queue.get()
            logger.info(res)

import pytest
from typing import List, Optional
from pathlib import Path
import logging
import socket
from time import sleep
from multiprocessing import Process, Queue

from server.main import start_main
from server.manager import Manager
from general.utils import SERVER_DIR

logger = logging.getLogger(__name__)


# @pytest.mark.skip(reason='Takes too long')
def test_write_client() -> None:
    manager = Manager()

    event = 'e("72.5.65.99","53")'
    stat = manager.clients[Manager.ROOT_CLIENT.__hash__()
                           ][0].is_running()
    logger.info(stat)
    res = manager.clients[Manager.ROOT_CLIENT.__hash__()][0].process_event(
        event)
    logger.info(res)


def test_queue_read() -> None:
    manager = Manager()

    queue: Queue = Queue()
    # NOTE: try using manager object
    manager_process = Process(target=Manager.read_queue,
                              args=(Manager.ROOT_CLIENT, queue))

    manager_process.start()
    event = 'e("72.5.65.99","53")'
    for _ in range(10):
        queue.put(('123123', event))

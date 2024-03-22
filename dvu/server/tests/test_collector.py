import logging
import socket
from multiprocessing import Process, Queue
from time import sleep

from server.collector import Collector

logger = logging.getLogger(__name__)


def test_collector() -> None:
    request_queue: Queue = Queue()
    onto_prim_types = 'some data here'

    collector_process = Process(
        target=Collector.start_collection,
        args=(onto_prim_types, request_queue),
        daemon=True
    )
    collector_process.start()
    sleep(0.1)

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        event = 'e("72.5.65.99","53")'
        data = 'exit#' + event
        msg = bytes(data, encoding='utf-8')
        s.sendto(msg, ('127.0.0.1', 9001))
    # collector_process.join()

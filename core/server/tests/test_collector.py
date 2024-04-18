import logging
import socket
from multiprocessing import Queue
from time import sleep

from server.collector import Collector, RequestIdentifier

logger = logging.getLogger(__name__)


def test_collector() -> None:
    NUM_REQ = 10
    request_queue: Queue = Queue()
    onto_prim_types = ['some data here']
    collector = Collector(onto_prim_types, request_queue)

    with collector.cm():
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            event = 'e("72.5.65.99","53")'
            data = RequestIdentifier.RAW.value + '#' + event
            msg = bytes(data, encoding='utf-8')
            for _ in range(NUM_REQ):
                s.sendto(msg, ('127.0.0.1', 9001))
            sleep(.1)  # NOTE: time for request processing

        counter = 0
        while not request_queue.empty():
            result = request_queue.get()
            logger.info(f'Read from queue {result}')
            counter += 1
    assert NUM_REQ == counter

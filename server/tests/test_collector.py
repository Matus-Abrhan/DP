import logging
import socket
from multiprocessing import Queue
from time import sleep

from server.collector import Collector, RequestIdentifier
from server.general.utils import RWQueue

logger = logging.getLogger(__name__)


def test_collector() -> None:
    NUM_REQ = 10
    event_queue: Queue = Queue()
    q1, q2 = Queue(), Queue()
    q3, q4 = Queue(), Queue()

    collector = Collector()
    with collector.cm(event_queue, RWQueue(q2, q1), RWQueue(q4, q3)):
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            event = 'e("72.5.65.99","53")'
            data = RequestIdentifier.RAW.add_data(['123', event])
            msg = bytes(data, encoding='utf-8')
            for _ in range(NUM_REQ):
                s.sendto(msg, ('127.0.0.1', 9001))
            sleep(.1)  # NOTE: time for request processing

        counter = 0
        while not event_queue.empty():
            result = event_queue.get()
            logger.info(f'Read from queue {result}')
            counter += 1
    assert NUM_REQ == counter

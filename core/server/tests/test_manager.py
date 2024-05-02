import logging
from time import sleep
from multiprocessing import Queue

from server.manager import Manager, Client
from server.wrapper.wrapper_echoShell import echoShell
from server.general.utils import Spec

logger = logging.getLogger(__name__)


def test_echo_shell():
    shell = echoShell(Spec.ROOT)
    input = 'blabla'
    result = shell.process_event(input)
    assert input in result


def test_add_clients():
    queue = Queue()
    manager = Manager(queue)

    counter = 10
    with manager.cm():
        num_clients = len(manager.clients)
        for i in range(counter):
            client = Client(str(i), str(i))
            manager.start_echo_shell(client, Spec.DUMMY1)
        assert num_clients + counter == len(manager.clients)
        assert num_clients + \
            counter == len([x for x in manager.status() if x])


def test_read_queue():
    queue = Queue()
    manager = Manager(queue)

    counter = 1
    with manager.cm():
        result = len([x for x in manager.status() if x])
        for _ in range(counter):
            queue.put(('1123', 'PORTSCAN'))
        sleep(.5)  # NOTE: time for request processing
        logger.info(manager.clients)
        assert result + counter == len([x for x in manager.status() if x])

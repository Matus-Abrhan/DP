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
from server.wrapper_echoShell import echoShell

logger = logging.getLogger(__name__)


def test_echo_shell():
    shell = echoShell()
    input = 'blabla'
    result = shell.process_event(input)
    assert f'Echo: {input}' in result


def test_manager():
    queue = Queue()

    with Manager(queue).cm():
        queue.put(('1123', 'dadfaf'))
        sleep(1)

import pytest
from typing import List, Optional
from pathlib import Path
import logging
import socket
from time import sleep
from multiprocessing import Process, Queue

from server.main import Main
from server.manager import Spec, Client
from server.collector import Collector, RequestIdentifier
from general.utils import SERVER_DIR

logger = logging.getLogger(__name__)


# @pytest.mark.skip(reason='Broken')
def test_root_astd_start() -> None:

    app: Main = Main()
    with app.cm() as app:
        assert app.collector.started
        assert app.manager.thread_alive


# @pytest.mark.skip(reason='Broken')
def test_send_logs() -> None:
    app: Main = Main()

    with app.cm() as app:
        status_start = len([x for x in app.manager.status() if x])
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            event = 'DUMMY2'
            data = RequestIdentifier.RAW.value + '#' + event
            msg = bytes(data, encoding='utf-8')
            s.sendto(msg, ('127.0.0.1', 9001))
            sleep(.1)  # NOTE: time for request processing
        assert status_start + 1 == len([x for x in app.manager.status() if x])

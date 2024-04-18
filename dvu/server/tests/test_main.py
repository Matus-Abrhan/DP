import pytest
from typing import List
import logging
import socket
from time import sleep

from server.main import Main
from server.manager import Spec
from server.collector import RequestIdentifier

logger = logging.getLogger(__name__)


# @pytest.mark.skip(reason='Broken')
def test_start() -> None:
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
            event = 'PORTSCAN'
            data = RequestIdentifier.RAW.value + '#' + event
            msg = bytes(data, encoding='utf-8')
            s.sendto(msg, ('127.0.0.1', 9001))
            sleep(.5)  # NOTE: time for request processing
        assert status_start + 1 == len([x for x in app.manager.status() if x])


def test_dummy1_dummy2() -> None:
    app: Main = Main(manager_test=False)

    with app.cm() as app:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            events = ['e(1,"","","","","","")',
                      'e("192.168.100.2","80","","","","","")',
                      'e(2,"","","","","","")',
                      'e("8.8.8.8","42","","","","","")']
            for event in events:
                data = RequestIdentifier.RAW.value + '#' + event
                msg = bytes(data, encoding='utf-8')
                s.sendto(msg, ('127.0.0.1', 9001))
                sleep(2)
                pass

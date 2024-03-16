import pytest
from typing import List, Optional
from ..cap_server import Collector
from pathlib import Path
import logging
import socket
from time import sleep

logger = logging.getLogger(__name__)


def test_root_astd_start() -> None:

    collector = Collector()
    assert collector.root_iASTD.is_running()

    collector.collect_process.kill()


# @pytest.mark.skip(reason='fucked')
def test_send_logs() -> None:
    collector = Collector()
    # sleep(1)

    '''
       data: Optional[List[str]] = proc.process_event('e("72.5.65.99","53")')
       assert data == ['Alert - Bench Test']
    '''

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        data = 'winevt#' + 'e("72.5.65.99","53")'
        msg = bytes(data, encoding='utf-8')
        # FIX: cannot send data to localhost
        s.sendto(msg, ('127.0.0.1', 9001))
        event = collector.root_queue.get()
        assert event == data

    collector.collect_process.kill()

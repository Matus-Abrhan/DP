import pytest
from typing import List, Optional
from pathlib import Path
import logging

from server.wrapper.wrapper_iASTD import iASTD
from server.general.utils import Spec

logger = logging.getLogger(__name__)


# @pytest.mark.skip(reason='Broken')
def test_start() -> None:
    proc = iASTD(Spec.TEST)
    assert proc.is_running()


# @pytest.mark.skip(reason='Broken')
def test_process_event() -> None:
    proc = iASTD(Spec.TEST)
    data: Optional[List[str]] = proc.process_event(
        'e("72.5.65.99","53","","","","","")')
    assert data == ['Alert - Bench Test']


# @pytest.mark.skip(reason='Takes too long')
def test_iASTD_threat_detection() -> None:
    proc = iASTD(Spec.PORTSCAN)
    event_file = Path(proc.spec_path.parent / 'events.log')
    data: List[str] = list()
    with open(event_file, 'r') as f:
        for event in f.readlines():
            event = event[:-2] + ',"")'
            res: Optional[List[str]] = proc.process_event(event)
            if res is not None:
                data.append(res[0])

    assert 'Alert Portscan attack' in data

from typing import List, Optional
from pathlib import Path
from enum import Enum
import logging

from server.wrapper.iASTD import iASTD

logger = logging.getLogger(__name__)


class Spec(Enum):
    PORTSCAN = Path('./iASTD/spec/PORTSCAN/portscan.spec')
    TEST = Path('./iASTD/spec/TEST/test.spec')


# @pytest.mark.skip(reason='Broken')
def test_start() -> None:
    proc = iASTD(Spec.TEST)
    assert proc.is_running()


# @pytest.mark.skip(reason='Broken')
def test_process_event() -> None:
    proc = iASTD(Spec.TEST)
    data: Optional[str] = proc.process_event(
        'e("1", "")')
    assert data == ['Alert: 1']


# @pytest.mark.skip(reason='Takes too long')
def test_iASTD_threat_detection() -> None:
    proc = iASTD(Spec.PORTSCAN)
    event_file = Path(proc.spec_path.parent / 'events.log')
    data: List[str] = list()
    with open(event_file, 'r') as f:
        for event in f.readlines():
            event = event[:-2] + ',"")'
            res: Optional[str] = proc.process_event(event)
            if res is not None:
                data.append(res)

    assert any(['Alert Portscan attack' in x for x in data])

import pytest
from typing import List, Optional
from ..wrapper_iASTD import iASTD
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


def test_start() -> None:
    proc = iASTD(Path('./iASTD/admin/server/spec/TEST/test.spec'))
    assert proc.is_running()


def test_process_event() -> None:
    proc = iASTD(Path('./iASTD/admin/server/spec/TEST/test.spec'))
    data: Optional[List[str]] = proc.process_event('e("72.5.65.99","53")')
    assert data == ['Alert - Bench Test']


@pytest.mark.skip(reason='Takes too long')
def test_iASTD_threat_detection() -> None:
    proc = iASTD(Path('./iASTD/admin/server/spec/PORTSCAN/portscan.spec'))
    event_file = Path(proc.spec_dir / 'events.log')
    data: List[str] = list()
    with open(event_file, 'r') as f:
        for event in f.readlines():
            # logger.info(event)
            res: Optional[List[str]] = proc.process_event(event)
            if res is not None:
                data.append(res[0])

    logger.info(data)

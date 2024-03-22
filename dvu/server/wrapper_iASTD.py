from pexpect import spawn
from pathlib import Path
from typing import List, Optional
from time import sleep
import logging
from enum import Enum

from general.utils import SERVER_DIR

logger = logging.getLogger(__name__)


class SysmonEvent():
    def __init__(self, data: str) -> None:
        self.data: str = data


class Spec(Enum):
    TEST = Path('./iASTD/admin/server/spec/TEST/test.spec')
    PORTSCAN = Path('./iASTD/admin/server/spec/PORTSCAN/portscan.spec')


class iASTD():
    _EXPECT: str = 'Enter action :'
    _IASTD_DIR: Path = SERVER_DIR / Path('./iASTD/iASTD')

    def __init__(self, spec: Spec) -> None:
        self.bin: Path = self._IASTD_DIR
        if not self.bin.exists():
            raise OSError(f'Binsty {self.bin} does not exist')
        spec_path = SERVER_DIR / spec.value
        if not spec_path.exists():
            raise OSError(f'Spec {spec_path} does not exist')
        if not spec_path.is_file():
            raise OSError(f'Path {spec_path} is not file')

        self.spec_file: Path = spec_path.absolute()
        self.spec_dir: Path = self.spec_file.parent

        command = " ".join([str(self.bin), '-s', str(self.spec_file)])
        self.app_instance = spawn(command, cwd=self.bin.parent)
        _ = self._read_stdout()
        logger.info(f'Started: {self}')

    def is_running(self) -> bool:
        return self.app_instance.isalive()

    def process_event(self, event: str) -> Optional[List[str]]:
        event = event.strip()
        # logger.debug(event)
        self.app_instance.sendline(event)
        data: str = self._read_stdout().decode('utf-8')
        result = data.strip().split('\r\n')
        if len(result) > 1:
            return result[1:]
        return None

    def stop(self) -> None:
        self.app_instance.close()

    def _read_stdout(self) -> bytes:
        self.app_instance.expect(self._EXPECT)
        data = self.app_instance.before
        return data

    def __repr__(self) -> str:
        return f'iASTD(path={str(self.spec_file)}, alive={self.is_running()})'

from pexpect import spawn
from pathlib import Path
from typing import List, Optional
from time import sleep
import logging

logger = logging.getLogger(__name__)


class SysmonEvent():
    def __init__(self, data: str) -> None:
        self.data: str = data


class iASTD():
    _EXPECT = 'Enter action :'
    _IASTD_DIR = Path('./iASTD/iASTD').absolute()

    def __init__(self, spec_path: Path) -> None:
        self.bin: Path = Path('./iASTD/iASTD').absolute()
        if not self.bin.exists():
            raise OSError(f'Binsty {self.bin} does not exist')
        if not spec_path.exists():
            raise OSError(f'Spec {spec_path} does not exist')
        if not spec_path.is_file():
            raise OSError(f'Path {spec_path} is not file')

        self.spec_file: Path = spec_path.absolute()
        self.spec_dir: Path = self.spec_file.parent

        command = " ".join([str(self.bin), '-s', str(self.spec_file)])
        self.app_instance = spawn(command, cwd=self.bin.parent)
        _ = self._read_stdout()

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

    def _read_stdout(self) -> bytes:
        self.app_instance.expect(self._EXPECT)
        data = self.app_instance.before
        return data

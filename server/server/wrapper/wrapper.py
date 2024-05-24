from abc import ABC, abstractmethod
from pexpect import spawn
from typing import List
from pathlib import Path
import logging

from server.general.utils import ROOT_DIR, Spec

logger = logging.getLogger(__name__)


class Wrapper(ABC):

    _BIN_PATH: Path
    _EXPECT_STRING: str

    @abstractmethod
    def __init__(self, spec: Spec) -> None:
        if not self.bin_path.exists():
            raise OSError(f'Binsty {self.bin_path} does not exist')

        self.spec: Spec = spec
        if not self.spec_path.exists():
            raise OSError(f'Spec {self.spec_path} does not exist')
        if not self.spec_path.is_file():
            raise OSError(f'Path {self.spec_path} is not file')

        self.app_instance = None

    @abstractmethod
    def start(self, command: str, **kwargs) -> None:
        self.app_instance = spawn(command, **kwargs)
        _ = self._read_stdout()
        logger.info(f'Started: {self}')
        print(self)

    @property
    def bin_path(self) -> Path:
        return ROOT_DIR / self._BIN_PATH

    @property
    def spec_path(self) -> Path:
        return ROOT_DIR / self.spec.value

    @property
    def expect_string(self) -> str:
        return self._EXPECT_STRING

    def is_running(self) -> bool:
        if self.app_instance is not None:
            return self.app_instance.isalive()
        return False

    def process_event(self, event: str) -> List[str]:
        event = event.strip()
        if self.app_instance:
            self.app_instance.sendline(event)
            data: str = self._read_stdout().decode('utf-8')
            result = data.strip().split('\r\n')
            if len(result) > 1:
                return result[1:]
            return list()
        raise ValueError(f'Process {self.bin_path.name} is not running')

    def stop(self) -> None:
        if self.app_instance:
            self.app_instance.close()
            logger.info(f'Stopped: {self}')
            print(f'Stopped: {self}')

    def _read_stdout(self) -> bytes:
        if self.app_instance:
            self.app_instance.expect(self.expect_string)
            data = self.app_instance.before
            return data
        return bytes()

    def __repr__(self) -> str:
        return f'{self.bin_path.name}(spec={str(self.spec_path.name)},'\
            f' alive={self.is_running()})'

from pexpect import spawn
from pathlib import Path
from typing import List, Optional
import logging

from server.general.utils import SERVER_DIR, Spec

logger = logging.getLogger(__name__)


class echoShell:
    _EXPECT: str = 'prompt# '
    _ECHO_SHELL_BIN: Path = SERVER_DIR / Path('./iASTD/echoShell')

    def __init__(self, spec: Spec):
        self.spec = spec
        self.app_instance = spawn(str(self._ECHO_SHELL_BIN))
        self._read_stdout()
        logger.debug(self)

    def is_running(self) -> bool:
        return self.app_instance.isalive()

    def process_event(self, input: str) -> Optional[List[str]]:
        input = input.strip()
        # logger.debug(event)
        self.app_instance.sendline(input)
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
        return f'echoShell(spec={self.spec}, alive={self.is_running()})'

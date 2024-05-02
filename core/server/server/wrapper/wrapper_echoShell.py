from pathlib import Path

from server.wrapper.wrapper import Wrapper


class echoShell(Wrapper):
    _EXPECT_STRING: str = 'prompt# '
    _BIN_PATH: Path = Path('./iASTD/echoShell')

    def __init__(self, spec) -> None:
        super().__init__(spec)
        self.start()

    def start(self):
        command = str(self.bin_path)
        super().start(command)

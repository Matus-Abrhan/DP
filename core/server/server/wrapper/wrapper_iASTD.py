from pathlib import Path

from server.wrapper.wrapper import Wrapper


class iASTD(Wrapper):
    _EXPECT_STRING: str = 'Enter action :'
    _BIN_PATH: Path = Path('./iASTD/iASTD')

    def __init__(self, spec) -> None:
        super().__init__(spec)
        self.start()

    def start(self):
        command = " ".join([str(self.bin_path), '-s', str(self.spec_path)])
        super().start(command, cwd=self.bin_path.parent)

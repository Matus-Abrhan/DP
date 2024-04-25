from pathlib import Path
from enum import Enum


ROOT_DIR: Path = Path(__file__).absolute().parent.parent


class Encoding:
    def decode(self, msg: bytes) -> str:
        return str(msg, encoding='utf-8')

    def encode(self, msg: str) -> bytes:
        return bytes(msg, encoding='utf-8')


class Spec(Enum):
    ROOT = Path('./iASTD/admin/server/spec/ROOT/root.spec')
    DUMMY1 = Path('./iASTD/admin/server/spec/DUMMY1/dummy1.spec')
    DUMMY2 = Path('./iASTD/admin/server/spec/DUMMY2/dummy2.spec')
    TEST = Path('./iASTD/admin/server/spec/TEST/test.spec')
    PORTSCAN = Path('./iASTD/admin/server/spec/PORTSCAN/portscan.spec')
    RAT = Path('./iASTD/admin/server/spec/RAT/rat.spec')

    @classmethod
    def value_of(cls, value):
        for k, v in cls.__members__.items():
            if k == value:
                return v
        else:
            return None


class RequestIdentifier(Enum):
    RAW = 'raw'
    WIN_EVENT = 'winevt'
    EXIT = 'exit'

    def add_data(cls, data) -> str:
        return '#'.join([cls.value, data])

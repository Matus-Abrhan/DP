from pathlib import Path
from enum import Enum
from typing import Set, Dict
import json
import shutil
import os


ROOT_DIR: Path = Path(__file__).absolute().parent.parent


class Encoding:
    def decode(self, msg: bytes) -> str:
        return str(msg, encoding='utf-8')

    def encode(self, msg: str) -> bytes:
        return bytes(msg, encoding='utf-8')


class EventName(Enum):
    WIN_EVENT_LOG = 'WinEventLog'


class Spec(Enum):
    ROOT = Path('./iASTD/spec/ROOT/root.spec')
    DUMMY1 = Path('./iASTD/spec/DUMMY1/dummy1.spec')
    DUMMY2 = Path('./iASTD/spec/DUMMY2/dummy2.spec')
    TEST = Path('./iASTD/spec/TEST/test.spec')
    PORTSCAN = Path('./iASTD/spec/PORTSCAN/portscan.spec')
    RAT = Path('./iASTD/spec/RAT/rat.spec')

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
    REGISTER = 'reg'
    UNREGISTER = 'unreg'
    EXIT = 'exit'

    def add_data(cls, data) -> str:
        return '#'.join([cls.value, data])


def get_event_def(event_name: EventName) -> Dict:
    file: Path = ROOT_DIR / Path('./iASTD/event_defs.json')
    with open(file, 'r') as event_defs:
        print(event_defs)
        defs_dict: Dict = json.load(event_defs)
        res = defs_dict.get(event_name.value, None)
        if res:
            return res
        else:
            raise ValueError(
                f'Error reading {event_name.value} from event definitions')


class WinEvent:
    def __init__(self) -> None:
        evet_def_data = get_event_def(EventName.WIN_EVENT_LOG)
        self.event_def: Set = set(evet_def_data.keys())

    def get_event(self, data: Dict) -> str:
        keys = self.event_def.union(data.keys())
        full_event = dict()
        for key in keys:
            full_event[key] = data.get(data[key], None)

        def get_str(x):
            if not x:
                return ''
            else:
                return x

        res = ','.join([get_str(x) for x in full_event.values()])

        return 'e(' + res + ')'


WIN_EVENT_OBJECT = WinEvent()


def translate_spec_type(event_name: str, event_def: Dict) -> None:
    def get_event_string(data):
        output = list()
        for item in data:
            output.append(f'?{item}:string')
        return ','.join(output)

    event_string = get_event_string(event_def)
    for spec in Spec:
        src: Path = ROOT_DIR / spec.value
        dst = src.parent / ('backup_' + src.name)
        shutil.copy(src, dst)
        os.system(
            f"sed -i 's/?[[:print:]]:{event_name}/{event_string}/' {src}"
        )


def cleanup_spec_type() -> None:
    for spec in Spec:
        dst: Path = ROOT_DIR / spec.value
        src: Path = dst.parent / ('backup_' + dst.name)
        os.remove(dst)
        shutil.move(src, dst)

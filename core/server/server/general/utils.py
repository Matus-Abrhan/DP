from pathlib import Path
from enum import Enum
from typing import Dict, Tuple, List, Optional
import json
import shutil
import os
from multiprocessing import Queue


ROOT_DIR: Path = Path(__file__).absolute().parent.parent
CLIENT_ID_BYTES = 4


class Encoding:

    @staticmethod
    def decode(msg: bytes) -> str:
        return str(msg, encoding='utf-8')

    @staticmethod
    def encode(msg: str) -> bytes:
        return bytes(msg, encoding='utf-8')


class EventName(Enum):
    WIN_EVENT_LOG = 'WinEventLog'


class Spec(Enum):
    ROOT = Path('./iASTD/spec/ROOT/root.spec')
    # T1053 = Path('./iASTD/spec/T1053/t1053.spec')
    # T1056 = Path('./iASTD/spec/T1056/t1056.spec')
    # T1059 = Path('./iASTD/spec/T1059/t1059.spec')
    # T1083 = Path('./iASTD/spec/T1083/t1083.spec')
    # T1202 = Path('./iASTD/spec/T1202/t1202.spec')
    # T1222 = Path('./iASTD/spec/T1222/t1222.spec')
    # T1486 = Path('./iASTD/spec/T1486/t1486.spec')
    RANSOMWARE = Path('./iASTD/spec/RANSOMWARE/ransomware.spec')
    KEYLOGGER = Path('./iASTD/spec/KEYLOGGER/keylogger.spec')

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
    RESULT = 'result'
    EXIT = 'exit'

    def add_data(cls, data: List[str]) -> str:
        join_list = [cls.value]
        join_list.extend(data)
        return '#'.join(join_list)


def get_event_def(event_name: EventName) -> Dict:
    file: Path = ROOT_DIR / Path('./iASTD/event_defs.json')
    with open(file, 'r') as event_defs:
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
        self.event_def = evet_def_data.keys()

    def get_event(self, data: List[str]) -> Optional[str]:
        if len(data) != len(self.event_def):
            return None

        def get_str(x):
            if not x:
                return '""'
            else:
                return '"' + x + '"'

        res = ','.join([get_str(x) for x in data])

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


def create_global_func_links() -> None:
    for spec in Spec:
        spec_path: Path = ROOT_DIR / spec.value
        link_src: Path = spec_path.parent.parent / 'global_functions.ml'
        link_dst: Path = spec_path.parent / 'global_functions.ml'
        try:
            os.symlink(link_src, link_dst)
        except FileExistsError:
            continue


def cleanup_spec_type() -> None:
    for spec in Spec:
        dst: Path = ROOT_DIR / spec.value
        src: Path = dst.parent / ('backup_' + dst.name)
        if src.exists() and dst.exists():
            os.remove(dst)
            shutil.move(src, dst)


class ProcessCommand(Enum):
    STOP = 0
    STATUS = 1
    REGISTER = 2
    UNREGISTER = 3
    RESULT = 4


class RWQueue:
    def __init__(self, q1, q2) -> None:
        self._r_q: Queue = q1
        self._w_q: Queue = q2

    def put(self, item: Tuple[ProcessCommand, Dict[str, str]]) -> None:
        self._w_q.put(item)

    def get(self) -> Tuple[ProcessCommand, Dict[str, str]]:
        return self._r_q.get()

    def empty(self) -> bool:
        return self._r_q.empty()


def next_power_of_2(x):
    return 2**(x - 1).bit_length()

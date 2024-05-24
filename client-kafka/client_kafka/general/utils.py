from pathlib import Path
from enum import Enum
import json
from typing import Dict, Optional, List


ROOT_DIR: Path = Path(__file__).absolute().parent.parent


class Encoding:

    @staticmethod
    def decode(msg: bytes) -> str:
        return str(msg, encoding='utf-8')

    @staticmethod
    def encode(msg: str) -> bytes:
        return bytes(msg, encoding='utf-8')


class RequestIdentifier(Enum):
    RAW = 'raw'
    WIN_EVENT = 'winevt'
    REGISTER = 'reg'
    UNREGISTER = 'unreg'

    def add_data(cls, data: List[str]) -> str:
        join_list = [cls.value]
        join_list.extend(data)
        return '#'.join(join_list)


class EventName(Enum):
    WIN_EVENT_LOG = 'WinEventLog'


def get_event_def(event_name: EventName) -> Dict[str, str]:
    file: Path = ROOT_DIR / Path('./event_defs.json')
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

    def get_event(self, data: Dict[str, str]) -> str:
        full_event: Dict[str, Optional[str]] = dict()
        for key in self.event_def:
            full_event[key] = data.get(key, None)

        return json.dumps(list(full_event.values()))


WIN_EVENT_OBJECT = WinEvent()

import logging
from typing import Optional
import re

from server.manager import Spec
from general.utils import SERVER_DIR

logger = logging.getLogger(__name__)


def get_first_transition(spec: Spec) -> Optional[str]:
    spec_path = SERVER_DIR / spec.value
    with open(spec_path, 'r') as f:
        for line in f:
            if re.search('guard1', line):
                transition = line.strip().replace(' ', '')
                transition = transition.replace(
                    'action1', 'alert_' + spec.name).replace(
                    'guard1', 'guard_' + spec.name)
                return transition
    return None


def create_guard(spec: Spec, line: str):
    new_guard = list()
    attr_pattern = re.compile(r'\?\w+:')
    attributes = [attr[1:-1] for attr in attr_pattern.findall(line)]

    guard_path = (SERVER_DIR / spec.value).parent / 'guard1'
    with open(guard_path, 'r') as f:
        contents = f.read().replace(' ', '')
        for attr in contents.split('&&'):
            if attr.split('=')[0] in attributes:
                new_guard.append(attr)

    return '&&'.join(new_guard)


def create_alert(spec: Spec):
    alert = f'let alert_{spec.name} () : unit =\n'\
        f'\tprint_endline "{spec.name}";;\n'

    return alert


if __name__ == "__main__":
    for s in [Spec.TEST]:
        res = get_first_transition(s)
        print(res)
        if res:
            print(create_guard(s, res))
            print(create_alert(s))

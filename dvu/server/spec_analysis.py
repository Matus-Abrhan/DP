import logging
from typing import Optional
import re
import shutil
import os

from server.manager import Spec
from general.utils import SERVER_DIR

logger = logging.getLogger(__name__)


class Root_spec:
    def __init__(self):
        self.transitions = list()
        self.elements = list()
        self.final = list()
        self.directory = Spec.ROOT.value.parent
        shutil.rmtree(self.directory)
        os.mkdir(self.directory)

    def create(self):
        self.elements.append('(n0->elem)')
        for i, spec in enumerate(Spec):
            index = i+1
            transition = get_first_transition(spec)
            if transition:
                with open(self.directory / ('guard_' + spec.name), 'w+') as guard:
                    data = create_guard(spec, transition)
                    guard.write(data)
                with open(self.directory / 'functions.ml', 'a+') as functions:
                    data = create_alert(spec)
                    functions.write(data)
                data = create_transition(spec, transition, index)
                self.transitions.append(data)
                self.elements.append(f'(n{index}->elem)')
                self.final.append(f'n{index}')
        transitions = ',\n\t\t\t'.join(self.transitions)
        elements = ',\n\t\t\t'.join(self.elements)
        final = ','.join(self.final)
        final = '{' + final + '};'

        def get_spec(elements, transitions, final):
            return (
                f'(MAIN,\n'
                f'\t<*;\n'
                f'\t\t<aut;\n'
                '\t\t\timports: {"functions.ml"};\n'
                f'\t\t\t{{\n'
                f'\t\t\t{elements}\n'
                '\t\t\t};\n'
                '\t\t\t{\n'
                f'\t\t\t{transitions}\n'
                '\t\t\t};\n'
                f'\t\t\t{final}\n'
                '\t\t\t{};\n'
                '\t\t\tn0\n'
                '\t\t>\n'
                '\t>\n'
                ')'
            )
        with open(self.directory / 'root.spec', 'w+') as spec:
            spec.write(get_spec(elements, transitions, final))


def get_first_transition(spec: Spec) -> Optional[str]:
    spec_path = SERVER_DIR / spec.value
    if not spec_path.exists():
        return None
    with open(spec_path, 'r') as f:
        for line in f:
            if re.search('(local,n0,n1)', line):
                transition = line.strip().replace(' ', '')
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
        f'\tprint_endline "{spec.name}";;\n\n'

    return alert


def create_transition(spec, line, index):
    parts = list()
    parts.append(f'(local, n0, n{index})')
    event_pattern = re.compile(r'e\([\w,?:]+\)')
    event = event_pattern.search(line).group(0)
    parts.append(event)
    guard = '{file:"guard_' + spec.name + '"}'
    parts.append(guard)
    alert = f'"Functions.alert_{spec.name}"'
    parts.append(alert)
    parts.append('false')

    transition = ','.join(parts)
    transition = '(' + transition + ')'
    return transition


if __name__ == "__main__":
    # for i, s in enumerate(Spec):
    #    index = i+1
    #    res = get_first_transition(s)
    #    if res:
    #        print(create_guard(s, res))
    #        print(create_alert(s))
    #        print(create_transition(s, res, index))
    #    print('===============================')
    root_spec = Root_spec()
    root_spec.create()

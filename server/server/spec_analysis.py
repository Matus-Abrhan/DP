import logging
from typing import Optional, List
import re
import shutil
import os

from server.general.utils import ROOT_DIR, Spec, WIN_EVENT_OBJECT

logger = logging.getLogger(__name__)


class RootSpec:
    def __init__(self):
        self.automatons = list()
        self.directory = ROOT_DIR / Spec.ROOT.value.parent
        if self.directory.exists():
            shutil.rmtree(self.directory)
        os.mkdir(self.directory)

    def create(self):
        for spec in Spec:
            if spec.name == "ROOT":
                continue
            transition = get_first_transition(spec)
            if transition:
                with open(self.directory / ('guard_' + spec.name), 'w+') as g:
                    data = create_guard(spec, transition)
                    g.write(data)
                with open(self.directory / 'functions.ml', 'a+') as f:
                    data = create_alert(spec)
                    f.write(data)
                data = create_transition(spec, transition)
                self.automatons.append(create_automaton(data))

        synchron = create_synchron(self.automatons)

        def get_spec(synchron):
            return (
                '(MAIN,\n'
                '<*;\n'
                'imports: {"global_functions.ml", "functions.ml"};\n'
                'attributes: {};\n'
                f'{synchron}\n'
                '>\n'
                ')'
            )
        with open(self.directory / 'root.spec', 'w+') as spec:
            spec.write(get_spec(synchron))


def join_synchron(a: str, b: str) -> str:
    if len(a) == 0 and len(b) > 0:
        return b
    elif len(b) == 0 and len(a) > 0:
        return a
    elif len(a) > 0 and len(b) > 0:
        synchron = [
            '<||;',
            ';\n'.join([a, b]),
            '>'
        ]
        return '\n'.join(synchron)
    raise ValueError(f'At least one of {a} or {b} should not be empty')


def create_synchron(elements: List[str]) -> str:
    if len(elements) == 1:
        return elements[0]
    else:
        new_elements = list()
        if (len(elements) % 2) != 0:
            elements.append('')
        half = int(len(elements)/2)
        for a, b in zip(elements[:half], elements[half:]):
            new_elements.append(join_synchron(a, b))
        return create_synchron(new_elements)


def create_automaton(transition: str, tabs: int = 2) -> str:
    def get_aut(tranistion):
        return [
            '\t<aut;',
            '\t{',
            '\t(n0->elem),',
            '\t(n1->elem)',
            '\t};',
            '\t{',
            f'\t{transition}',
            '\t};',
            '\t{n1};',
            '\t{};',
            '\tn0',
            '\t>'
        ]
    space = '\n'
    result = space.join(get_aut(transition))
    return result


def get_first_transition(spec: Spec) -> Optional[str]:
    spec_path = ROOT_DIR / spec.value
    if not spec_path.exists():
        return None
    with open(spec_path, 'r') as f:
        for line in f:
            line = line.strip().replace(' ', '')
            if re.search('(local,n0,n1)', line):
                return line
    return None


def create_guard(spec: Spec, line: str):
    or_list = list()
    and_list = list()
    attributes = WIN_EVENT_OBJECT.event_def

    guard_name = re.search(r'guard[_0-9a-zA-Z]*', line)
    guard_path = (ROOT_DIR / spec.value).parent / guard_name.group(0)
    with open(guard_path, 'r') as f:
        contents = ' '.join(f.read().split())
        for and_part in contents.split('&&'):
            for or_part in and_part.split('||'):
                if any([part in attributes for part in or_part.split()]):
                    or_list.append(or_part)
            and_list.append(' ||\n'.join(or_list))
            or_list.clear()
        and_list = [x for x in and_list if x]
        new_guard = '\n&&\n'.join(and_list)

    return new_guard


def create_alert(spec: Spec):
    alert = f'let alert_{spec.name} () : unit =\n'\
        f'\tprint_endline "{spec.name}";;\n\n'

    return alert


def create_transition(spec, line):
    parts = list()
    parts.append('(local, n0, n1)')
    event_pattern = re.compile(r'e\([\w,?:]+\)')
    event = event_pattern.search(line).group(0)
    parts.append(event)
    guard = '{file:"guard_' + spec.name + '"}'
    parts.append(guard)
    alert = f'"Functions.alert_{spec.name}()"'
    parts.append(alert)
    parts.append('false')

    transition = ','.join(parts)
    transition = '(' + transition + ')'
    return transition


if __name__ == "__main__":
    root_spec = RootSpec()
    root_spec.create()

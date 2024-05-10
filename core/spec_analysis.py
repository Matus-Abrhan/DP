import logging
from typing import Optional, List
import re
import shutil
import os

from server.general.utils import ROOT_DIR, Spec, WIN_EVENT_OBJECT

logger = logging.getLogger(__name__)


class RootSpec:
    def __init__(self):
        # self.transitions = list()
        # self.elements = list()
        # self.final = list()
        self.automatons = list()
        self.directory = ROOT_DIR / Spec.ROOT.value.parent
        if self.directory.exists():
            shutil.rmtree(self.directory)
        os.mkdir(self.directory)
        link_src = ROOT_DIR / './iASTD/spec/global_functions.ml'
        link_dst = self.directory / 'global_functions.ml'
        os.symlink(link_src, link_dst)

    def create(self):
        for i, spec in enumerate(Spec):
            if spec.name == "ROOT":
                continue
            index = i+1
            transition = get_first_transition(spec)
            if transition:
                with open(self.directory / ('guard_' + spec.name), 'w+') as guard:
                    data = create_guard(spec, transition)
                    guard.write(data)
                with open(self.directory / 'functions.ml', 'a+') as functions:
                    data = create_alert(spec)
                    functions.write(data)
                data = create_transition(spec, transition)
                self.automatons.append(create_automaton(data))

        # automatons = ';\n\t\t'.join(self.automatons)
        logger.info(len(self.automatons))
        synchron = create_synchron(self.automatons)

        def get_spec(synchron):
            return (
                '(MAIN,\n'
                '<*;\n'
                'imports: {"global_functions.ml", "functions.ml"};\n'
                'attributes: {};\n'
                # TODO: add list of automatons
                f'{synchron}\n'
                '>\n'
                ')'
            )
        with open(self.directory / 'root.spec', 'w+') as spec:
            spec.write(get_spec(synchron))


def join_synchron(a: str, b: Optional[str]) -> str:
    if a is None:
        return b
    elif b is None:
        return a

    synchron = [
        '<||;',
        ';\n'.join([a, b]),
        '>'
    ]
    # logger.info('\n'.join(synchron))
    return '\n'.join(synchron)


def create_synchron(elements: List[str]) -> str:
    logger.info(elements)
    if len(elements) == 1:
        return elements[0]
    else:
        new_elements = list()
        if (len(elements) % 2) != 0:
            elements.append(None)
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
    space = '\n'  # + ('\t'*tabs)
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

    guard_path = (ROOT_DIR / spec.value).parent / 'guard1'
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

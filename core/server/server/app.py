import logging
from multiprocessing import Queue
from contextlib import contextmanager

from server.manager import Manager
from server.collector import Collector
from server.spec_analysis import RootSpec
from server.general.utils import translate_spec_type, cleanup_spec_type
from server.general.utils import EventName, get_event_def, ProcessCommand
from server.general.utils import RWQueue, create_global_func_links


logger = logging.getLogger(__name__)


class App:
    def __init__(self, event_name=EventName.WIN_EVENT_LOG) -> None:
        cleanup_spec_type()
        root_spec = RootSpec()
        root_spec.create()
        self.event_def = get_event_def(event_name)
        translate_spec_type(event_name.value, self.event_def)
        create_global_func_links()

        self.collector = Collector()
        self.manager = Manager()

    def status(self):
        self.collector_rw.put((ProcessCommand.STATUS, dict()))
        (command, data) = self.collector_rw.get()

        return data

    @contextmanager
    def cm(self):
        event_q = Queue()
        q1, q2 = Queue(), Queue()
        q3, q4 = Queue(), Queue()
        self.collector_rw: RWQueue = RWQueue(q3, q4)
        with self.manager.cm(event_q, RWQueue(q1, q2)):
            with self.collector.cm(event_q,
                                   RWQueue(q2, q1),
                                   RWQueue(q4, q3)):
                yield self
                while self.status()['events_pending'] != '0':
                    pass
        # cleanup_spec_type()


def main() -> None:
    app: App = App()
    with app.cm() as app:
        try:
            while True:
                x = input('> ')
                if x == 'status':
                    print(app.status())
                elif x == 'register':
                    app.collector_rw.put(
                        (ProcessCommand.REGISTER, 'localhost'))
                elif x == 'exit':
                    break
                elif x == '?' or x == 'help':
                    print(
                        'Options:\n'
                        'status\n'
                        'register\n'
                        'exit\n')
        except KeyboardInterrupt:
            pass
    exit(0)

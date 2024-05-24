import logging
from multiprocessing import Queue
from contextlib import contextmanager

from server.manager import Manager
from server.collector_kafka import KafkaCollector
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

        self.collector = KafkaCollector()
        self.manager = Manager()

    def status(self):
        self.collector_rw.put((ProcessCommand.STATUS, dict()))
        (command, data) = self.collector_rw.get()

        return data

    @contextmanager
    def cm(self, finish=True):
        event_q = Queue()
        q1, q2 = Queue(), Queue()
        q3, q4 = Queue(), Queue()
        self.collector_rw: RWQueue = RWQueue(q3, q4)
        with self.manager.cm(event_q, RWQueue(q1, q2)):
            with self.collector.cm(event_q,
                                   RWQueue(q2, q1),
                                   RWQueue(q4, q3)):
                yield self
                if finish:
                    while events := self.status()['events_pending'] != '0':
                        logger.info(events)
                        pass


def main() -> None:
    app: App = App()
    with app.cm() as app:
        while True:
            pass

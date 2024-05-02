import logging
from multiprocessing import Queue
from contextlib import contextmanager
from time import sleep

from server.manager import Manager
from server.collector import Collector
from server.spec_analysis import RootSpec
from server.general.utils import translate_spec_type, cleanup_spec_type, EventName, get_event_def


logger = logging.getLogger(__name__)


class App:
    def __init__(self, event_name=EventName.WIN_EVENT_LOG,
                 manager_test: bool = True) -> None:

        root_spec = RootSpec()
        root_spec.create()
        self.event_def = get_event_def(event_name)
        translate_spec_type(event_name.value, self.event_def)

        # INFO: starting server
        self.request_queue: Queue = Queue()
        self.collector = Collector(self.request_queue)
        self.manager = Manager(self.request_queue, manager_test)

    @contextmanager
    def cm(self):
        with self.collector.cm():
            with self.manager.cm():
                yield self

        self.request_queue.close()
        cleanup_spec_type()


def main() -> None:
    app: App = App()
    with app.cm() as app:
        try:
            while True:
                sleep(2)
                print(app.request_queue.qsize())
                # pass
        except KeyboardInterrupt:
            pass

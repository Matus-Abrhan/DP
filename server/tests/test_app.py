import logging
import socket
import json

from server.app import App
from server.collector import RequestIdentifier
from server.general.utils import ROOT_DIR, Spec, EventName, get_event_def
from server.general.utils import translate_spec_type, WIN_EVENT_OBJECT, create_global_func_links
from server.wrapper.iASTD import iASTD
from server.spec_analysis import RootSpec

logger = logging.getLogger(__name__)


def test_start() -> None:
    app: App = App()
    with app.cm(finish=False) as app:
        assert app.collector.server_process is not None
        assert app.collector.server_process.is_alive()
        assert app.manager.manager_process is not None
        assert app.manager.manager_process.is_alive()


def test_root_spec() -> None:
    root_spec = RootSpec()
    root_spec.create()
    event_name = EventName.WIN_EVENT_LOG
    event_def = get_event_def(event_name)
    translate_spec_type(event_name.value, event_def)
    create_global_func_links()

    iastd = iASTD(Spec.ROOT)
    expected = {'T1083': 1, 'T1202': 1, 'T1222': 1}
    for spec, tests in expected.items():
        counter = 0
        log_path = ROOT_DIR.parent / f'tests/logs/{spec}.log'
        with open(log_path, 'r') as f:
            for event_raw in f.readlines():
                event_list = json.loads(event_raw)
                event = WIN_EVENT_OBJECT.get_event(event_list)

                res = iastd.process_event(event)
                if spec in res:
                    counter += 1
        assert counter >= tests, f'counter too low for spec {spec}'


def test_dummy1() -> None:
    app: App = App()

    with app.cm() as app:

        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            log_path = ROOT_DIR.parent / 'tests/logs/T1083.log'
            with open(log_path, 'r') as f:
                for event in f.readlines():
                    data = RequestIdentifier.WIN_EVENT.add_data(['123', event])
                    msg = bytes(data, encoding='utf-8')
                    s.sendto(msg, ('127.0.0.1', 9001))

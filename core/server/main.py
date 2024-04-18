from typing import Dict, List
from pathlib import Path
import json
import yaml
import logging
from multiprocessing import Queue
from contextlib import contextmanager

from server.manager import Manager
from server.collector import Collector
from general.utils import SERVER_DIR

logger = logging.getLogger(__name__)


class Main:
    # ontology_types = {}

    def __init__(self, onto_spec_types: List[str] = ['WinEventLog'],
                 manager_test: bool = True) -> None:
        # INFO: reading configuration files
        config_file_path: Path = SERVER_DIR / Path('./iASTD/config.yaml')
        with open(config_file_path, 'r') as config_file:
            config = yaml.load(config_file, Loader=yaml.FullLoader)
            json_onto_feeds: Path = Path(
                config['CONFIGS']['ONTOLOGY_CONFIGS']['FEED_CHANNELS']['channel1']['target']
            )
            onto_feeds: Dict[str, Dict[str, str]] = dict()
            if json_onto_feeds:
                with open(config_file_path.parent.absolute() /
                          json_onto_feeds, 'r') as feeds:
                    onto_feeds = json.load(feeds)
        self.onto_prim_types: List[str] = list(
            onto_feeds[onto_spec_types[0]].keys()
        )
        # cplex_type = "wineventlog"

        # INFO: starting server
        self.request_queue: Queue = Queue()
        self.collector = Collector(self.onto_prim_types, self.request_queue)
        self.manager = Manager(self.request_queue, manager_test)

    @ contextmanager
    def cm(self):
        with self.collector.cm():
            with self.manager.cm():
                yield self

        self.request_queue.close()


if __name__ == "__main__":
    app = Main()
    with app.cm() as app:
        try:
            while True:
                pass
        except KeyboardInterrupt:
            pass

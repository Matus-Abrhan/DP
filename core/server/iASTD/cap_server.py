# Author Lionel Nganyewou Tidjon
# Copyright (c) 2017-2018, GRIL
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of the <organization> nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL GRIL BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
from typing import Dict, List
import json
import sys
import yaml  # pip3 install yaml
import socketserver
import logging
from subprocess import Popen, PIPE
import pwn


class xASTD_hcap_server(socketserver.BaseRequestHandler):
    # parse syslog events
    # def xparse(self, syslog):
    #    ints = Word(nums)
    #    priority = Suppress("<") + ints + Suppress(">")
    #    month = Word(string.uppercase, string.lowercase, exact=3)
    #    day = ints
    #    hour = Combine(ints + ":" + ints + ":" + ints)
    #    timestamp = month + day + hour
    #    hostname = Word(alphas + nums + "_" + "-" + ".")
    #    appname = Word(alphas + "/" + "-" + "_" + ".") + Optional(Suppress("[") + ints + Suppress("]")) + Suppress(":")
    #    message = Regex(".*")
    #    __pattern = priority + timestamp + hostname + appname + message
    #    syslog_obj= __pattern.parseString(syslog)
    #    syslog_obj["priority"] = __pattern[0]
    #    syslog_obj["timestamp"] = time.strftime("%Y-%m-%d %H:%M:%S")
    #    syslog_obj["hostname"] = __pattern[4]
    #    syslog_obj["appname"] = __pattern[5]
    #    syslog_obj["procid"] = __pattern[6]
    #    syslog_obj["msg"] = __pattern[7]
    #    syslog_obj["version"] = "3.16.1"
    #    syslog_obj["msgid"] = base64.urlsafe_b64encode(os.urandom(6))
    #    syslog_obj["structureddata"] = ""

    #    return syslog_obj

    def handle(self) -> None:
        enc_data: bytes = self.request[0]
        crypto = AESCypher()
        data = crypto.decrypt(enc_data)
        # client_addr = self.client_address[0]
        data_ = data.split('#')
        iden = data_[0]
        # Sysmon events
        if iden == "winevt":
            try:
                flg = True
                curr_event = ''
                event = json.loads(data_[1])
                c = 0
                for attribute in onto_prim_types:
                    # vect_temp = []
                    fl = False
                    for evt_attribute, value in event.items():
                        evt_attribute_ = evt_attribute.lower().replace(
                            "eventdata.", "").replace("system.", "").replace('.', '_')
                        if attribute in evt_attribute_:
                            fl = True
                            if flg:
                                curr_event = 'e("' + str(value.encode('utf-8',
                                                                      'ignore')).replace('"', '') + '","'
                                flg = False
                                c = c+1
                            else:
                                curr_event = curr_event + \
                                    str(value.encode('utf-8', 'ignore')
                                        ).replace('"', '') + '","'
                                c = c+1
                    if not fl:
                        if flg:
                            curr_event = 'e("","'
                            flg = False
                            c = c+1
                        else:
                            curr_event = curr_event + '","'
                            c = c+1
                curr_event = curr_event[:-2]
                if c == 39:
                    curr_event = curr_event[:-3]
                if c == 40:
                    curr_event = curr_event[:-3]
                if 'e("3"' in curr_event:
                    curr_event = curr_event.replace(
                        '"","S-1-5-18"', '"S-1-5-18"')
                curr_event = curr_event + \
                    (')' if curr_event.endswith('"') else '")')

                print(curr_event)
                # output = iASTD.communicate(input=curr_event)
                # print(output)
            except Exception as e:
                print(f"Parse event error, {e}")


class xASTD_host_collector:
    HOST = '0.0.0.0'
    PORT = 9093
    # ontology_types = {}

    def start_collection(self) -> None:
        print("Starting cap server")
        try:
            server_sock = socketserver.UDPServer(
                (self.HOST, self.PORT), xASTD_hcap_server)
            while True:
                server_sock.handle_request()
        except KeyboardInterrupt:
            sys.exit()
        except (IOError, SystemExit):
            raise


class AESCypher:
    DECRYPT_KEY = 'HKLlbF514I09oYcv'

    def decrypt(self, msg: bytes) -> str:
        # aes = pyaes.AESModeOfOperationCTR(self.DECRYPT_KEY)
        # return aes.decrypt(msg)
        return str(msg, encoding='utf-8')


msg_cnt = ""
if __name__ == "__main__":

    if len(sys.argv) < 2:
        print("python cap_server.py [onto_spec_types]")
    else:
        onto_spec_types = str(sys.argv[1]).split('@')
        if not onto_spec_types:
            print("No Custom types found.")
        else:
            ymlfile = "config.yaml"
            cfg = yaml.load(open(ymlfile, "r"), Loader=yaml.FullLoader)

            json_onto_feeds = cfg['CONFIGS']['ONTOLOGY_CONFIGS']['FEED_CHANNELS']['channel1']['target']
            onto_feeds: Dict[str, Dict[str, str]] = dict()
            if json_onto_feeds:
                with open(json_onto_feeds, "r") as f:
                    onto_feeds = json.load(f)

            for onto_spec_type in onto_spec_types:
                if "packet" in onto_spec_type.lower() or "flow" in onto_spec_type.lower():
                    logging.info(f'{onto_spec_type} is not implemented')
                elif "session" in onto_spec_type.lower():
                    logging.info(f'{onto_spec_type} is not implemented')
                elif "log" in onto_spec_type.lower():
                    iASTD = Popen(['./RAT/iASTD', '-s', './RAT/rat.spec'],
                                  stdout=PIPE, stdin=PIPE, stderr=PIPE)
                    print(iASTD.stdout)
                    # iASTD = pwn.process(
                    #    'iASTD rat.spec', shell=True, cwd='./RAT/')
                    # iASTD.recv()
                    # iASTD.send(b'aaaaa\n')
                    hcap = xASTD_host_collector()
                    cplex_type = "syslog"
                    if "wineventlog" in onto_spec_type.lower():
                        cplex_type = "wineventlog"
                    onto_prim_types: List[str] = list(
                        onto_feeds[onto_spec_type].keys())
                    hcap.HOST = cfg['CONFIGS']['SERVER_CONFIGS']['HOST']
                    hcap.PORT = cfg['CONFIGS']['SERVER_CONFIGS']['PORT']
                    hcap.start_collection()

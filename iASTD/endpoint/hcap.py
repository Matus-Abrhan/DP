#Author Lionel Nganyewou Tidjon
#Copyright (c) 2017-2018, GRIL
#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of the GRIL nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#DISCLAIMED. IN NO EVENT SHALL GRIL BE LIABLE FOR ANY
#DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import socket
import sys
import os
import argparse
import time
import json
import Evtx.Evtx as evtx  # pip3 install python-evtx
import xmltodict  # pip3 install xmltodict
from collections import OrderedDict
import pyaes #pip3 install pyaes


class xASTD_hcap_client:

        BUFFER_MAX_SIZE=1024
        WAITING_TIME_MILLISECS=200

        def join_key_value_pairs(self,data_list):

            flat = OrderedDict()
            for pair in data_list:
                name, value = '', ''
                try:
                    name = pair['@Name']
                    value = pair['#text']
                except KeyError:
                    pass
                if name in flat:
                    raise KeyError('Duplicate key: "%s"' % name)
                if name:
                    flat[name] = value

            return flat

        def flatten_dict(self, branch, flat, current_path=''):

            for k, v in branch.items():
                key = k.lstrip('#@')
                path = key if not current_path else '%s.%s' % (current_path, key)
                if isinstance(v, dict):
                    self.flatten_dict(v, flat, current_path=path)
                else:
                    flat[path] = v

        def flatten_xml_event(self,xml_event):

            xml = xmltodict.parse(xml_event)
            del xml['Event']['@xmlns']  # xml version is redundant
            xml['Event']['EventData']['Data'] = self.join_key_value_pairs(xml['Event']['EventData']['Data'])
            flat = OrderedDict()
            self.flatten_dict(xml['Event'], flat)
            return flat

        def format_compact(self,record):
            return json.dumps(record)
       
        def format_pretty(self,record):
            return json.dumps(record, indent=4)
       
        def start_capture(self):

            if len(sys.argv) < 3:
                print("Usage : python hcap.py hostname port")
                sys.exit()
            else:
                server_address = (sys.argv[1], int(sys.argv[2]))
                # buf = self.BUFFER_MAX_SIZE
                client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                client_socket.settimeout(2)

                crypto = AESCypher()

                platform = str(sys.platform).lower()

               # print("Current platform => " + platform)

                if platform == "win32": #win32

                        winpath = os.environ['WINDIR'] + "\\System32\\winevt\\Logs\\"
                        sysmon_channel = winpath + "Microsoft-Windows-Sysmon%4Operational.evtx"

                        try:
                            with evtx.Evtx(winpath + sysmon_channel) as log:
                                counter = log.get_file_header().first_chunk().log_first_record_number() - 1
                                #count = log = log.__enter__()
                                tmp_str = "0123456789"
                                while True:
                                    try:
                                        counter += 1
                                        event_record = log.get_record(counter)
                                        if event_record is None:
                                            time.sleep(self.WAITING_TIME_MILLISECS/1000.0)
                                            continue

                                        event = self.flatten_xml_event(event_record.xml())

                                        if not event:
                                            continue
                                        output_string = self.format_pretty(event)
                                        print(output_string)
                                        if not (tmp_str in output_string):

                                            client_socket.sendto(crypto.encrypt("winevt#"+output_string), server_address)
                                            tmp_str = output_string
                                            print(output_string)
                                        else:
                                            continue
                                    except:
                                        pass
                        except:
                              print("ERROR: Sending to "+str(sys.argv[1])+" failed !!")

                if platform == "linux2":

                        print("======== READ ME ===========")
                        print("1) Install syslog")
                        print("# apt-get install syslog-ng")
                        print("2) Update syslog-ng.conf")
                        print("# nano /etc/syslog-ng/syslog-ng.conf")
                        print("EDIT: destination d_net { tcp(\"YOUR_SERV_ADDR\" port(YOUR_PORT));"
                              " udp(\"YOUR_SERV_ADDR\" port(YOUR_PORT)); };")
                        print("EDIT: log { source(s_src); destination(d_net); };") 
                        print("3) Restart syslog service")
                        print("# /etc/init.d/syslog-ng restart")
                        print("============================")
                        time.sleep(3)
                        os.system("sudo apt-get install syslog-ng && sudo nano /etc/syslog-ng/syslog-ng.conf "
                                  "&& sudo /etc/init.d/syslog-ng restart")


class AESCypher:

    ENCRYPT_KEY = 'HKLlbF514I09oYcv'

    def encrypt(self, msg):
        aes = pyaes.AESModeOfOperationCTR(self.ENCRYPT_KEY)
        return aes.decrypt(msg)


if __name__ == "__main__":

        hcap = xASTD_hcap_client()
        hcap.start_capture()

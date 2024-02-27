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

import logging
import SocketServer
import pyaes  # pip3 install pyaes
import yaml  # pip3 install yaml
import os
import sys
import json
import datetime
import time
import base64
import random
from scapy.all import * #pip3 install scapy


class xASTD_net_cap:

    QUEUE_MAX_SIZE = 65565

    # network interface
    # payload view mode
    INTERFACE = "eth0"

    ASCII = 0x00
    BIN = 0x01
    HEX = 0x02

    defaultViewMode = ASCII
    #filterstate = ON

    # filter options
    HTTP_OPT = "tcp dst port 80 or tcp dst port 443"
    SSH_OPT = "tcp dst port 22"
    DNS_OPT = "udp dst port 53"
    MODBUS_OPT = "dst port 502"
    
    FULL_OPTS = HTTP_OPT +" or " + DNS_OPT #+ " or " + SSH_OPT
    
    # Ontology types
    onto_prim_types = []
    cplex_type=""

    data=""
    # show payload modes
    #def show(self, payload, viewmode):
    #    if viewmode == self.HEX:
    #        return str(binascii.hexlify(payload))
    #    elif viewmode == self.BIN:
    #        return str(bin(int(binascii.hexlify(payload), 16)))
    #    else:
    #        return str(payload).replace('"', '')

   # def HTTPParser(self,http_payload, opts=0):
   #     http_c = ""
   #     if opts == 0:
   #        regex = ur"(?:[\r\n]{0,1})(\w+\-\w+|\w+)(?:\ *:\ *)([^\r\n]*)(?:[\r\n]{0,1})"
   #        headers = re.findall(regex, http_payload, re.UNICODE)
   #        for key, val in headers:
   #            http_c = http_c + str(key)+": "+str(val)+"\n"
   #     elif opts == 1:
   #         patterns = re.compile("(?:GET|POST|PUT|DELETE) [\-_a-zA-Z0-9./?&:=@]+ HTTP/1\.1")
   #         uris = patterns.findall(http_payload)
   #         if not uris:
   #            http_c = ""
   #         else:
   #            http_c = str(uris[0])
   #     return http_c

    def HTTPParser(self,http_payload, opts=0):
        http_c = ""
        if opts == 0:
           regex = ur"(?:[\r\n]{0,1})(\w+\-\w+|\w+)(?:\ *:\ *)([^\r\n]*)(?:[\r\n]{0,1})"
           headers = re.findall(regex, http_payload, re.UNICODE)
           for key, val in headers:
               http_c = http_c + str(key)+": "+str(val)+" "
               self.data = self.data.replace(str(key)+": "+str(val), "")
        elif opts == 1:
            patterns = re.compile("(?:GET|POST) [\-_a-zA-Z0-9\./?&:=@]+ HTTP/1\.1")
            uris = patterns.findall(http_payload)
            if not uris:
               http_c = ""
            else:
               http_c = str(uris[0])
               self.data = self.data.replace(http_c,"")
        return http_c


    def got_packet(self, packets):
        sessions = packets.sessions()
        for session in sessions:
            ipsrc =  ""
            ipdst = ""
            for stream in sessions[session]:
                if IP in stream:
                   ipsrc = str(stream[IP].src)
                   ipdst = str(stream[IP].dst)
                if TCP in stream :
                   protocol = "tcp"
                   portsrc = str(stream[TCP].sport)
                   portdst = str(stream[TCP].dport)
                   tcp_payload = str(stream[TCP].payload)
                   self.data = tcp_payload
                   msg_req = self.HTTPParser(tcp_payload,1)
                   msg_hdr = self.HTTPParser(tcp_payload,0)
                   timestamp=datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
                   msg_cnt = self.data.replace('"',"'")
                   msg_hdr = msg_hdr.replace('"',"'")
                   #if portdst == "80":
                   curr_event=("e(\""+protocol+"\",\""+ipdst+"\",\""+portdst+"\",\""+ipsrc+"\",\""+msg_cnt+"\",\""+msg_req+"\",\""+msg_hdr+"\",\""+timestamp+"\",\""+portsrc+"\")\n")
                   print(curr_event)
                elif UDP in stream:
                   protocol = "udp"
                   portsrc = str(stream[UDP].sport)
                   portdst = str(stream[UDP].dport)
                   udp_payload = str(stream[UDP].payload)
                   msg_req = "A"
                   msg_hdr = ""
                   msg_cnt = udp_payload.replace('"',"'")
                   timestamp=datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
                   #if portdst =="53":
                   curr_event=("e(\""+protocol+"\",\""+ipdst+"\",\""+portdst+"\",\""+ipsrc+"\",\""+""+"\",\""+msg_req+"\",\""+msg_hdr+"\",\""+timestamp+"\",\""+portsrc+"\")\n")
                   print(curr_event)

    # decoding tcp flags
    def tochar(self, flag):
        if flag == 0x01: return 'F'
        elif flag == 0x02: return 'S'
        elif flag == 0x03: return 'FS'
        elif flag == 0x08: return 'P'
        elif flag == 0x09: return 'FP'
        elif flag == 0x0A: return 'SP'
        elif flag == 0x10: return 'A'
        elif flag == 0x11: return 'FA'
        elif flag == 0x12: return 'SA'
        elif flag == 0x18: return 'PA'
        else: return flag

    # packet shipping and decoding
    def start_capture(self):
        try:
            if self.cplex_type == "packet":
               packet = sniff(count=1, iface=self.INTERFACE,filter=self.FULL_OPTS)
               current_event=str(packet.show())
               print(current_event)
            elif self.cplex_type == "flow":
               flow = sniff(count=1, iface=self.INTERFACE, filter=self.FULL_OPTS)
               current_event=str(flow.show())
               print(current_event)
            elif "session" in self.cplex_type:
               packets=sniff(count=6, iface=self.INTERFACE, filter=self.FULL_OPTS) #set your interface in config.yaml
               #print(str(packets.show()))
               self.got_packet(packets)

        except (Exception) as e: print str(e)

class xASTD_hcap_server(SocketServer.BaseRequestHandler):
    
    #parse syslog events
    def xparse(self, syslog):
        ints = Word(nums)
        priority = Suppress("<") + ints + Suppress(">")
        month = Word(string.uppercase, string.lowercase, exact=3)
        day = ints
        hour = Combine(ints + ":" + ints + ":" + ints)
        timestamp = month + day + hour
        hostname = Word(alphas + nums + "_" + "-" + ".")
        appname = Word(alphas + "/" + "-" + "_" + ".") + Optional(Suppress("[") + ints + Suppress("]")) + Suppress(":")
        message = Regex(".*")
        __pattern = priority + timestamp + hostname + appname + message
        syslog_obj= __pattern.parseString(syslog)
        syslog_obj["priority"] = __pattern[0]
        syslog_obj["timestamp"] = time.strftime("%Y-%m-%d %H:%M:%S")
        syslog_obj["hostname"] = __pattern[4]
        syslog_obj["appname"] = __pattern[5]
        syslog_obj["procid"] = __pattern[6]
        syslog_obj["msg"] = __pattern[7]
        syslog_obj["version"] = "3.16.1"
        syslog_obj["msgid"] = base64.urlsafe_b64encode(os.urandom(6))
        syslog_obj["structureddata"] = ""

        return syslog_obj

    #handles the collection of both sysmon and syslog events
    def handle(self):

        enc_data = str(self.request[0])
        crypto = AESCypher()
        data = crypto.decrypt(enc_data)
        client_addr = self.client_address[0]
        data_ = data.split('#')
        iden = data_[0]
        # Sysmon events
        if iden == "winevt":
              try:
                flg = True
                curr_event = ''
                event = json.loads(data_[1])
                c=0
                for attribute in onto_prim_types:
                    vect_temp =[]
                    fl = False
                    for evt_attribute, value in event.iteritems():
                        evt_attribute_ = evt_attribute.lower().replace("eventdata.","").replace("system.","").replace('.','_')
                        if attribute in evt_attribute_:
                            fl = True
                            if flg:
                                curr_event = 'e("' + str(value.encode('utf-8','ignore')).replace('"','') + '","'
                                flg = False
                                c=c+1
                            else:
                                curr_event = curr_event + str(value.encode('utf-8','ignore')).replace('"','') + '","'
                                c=c+1
                    if not fl:
                        if flg:
                           curr_event = 'e("","'
                           flg = False
                           c=c+1
                        else:
                           curr_event = curr_event + '","'
                           c=c+1
                curr_event = curr_event[:-2]
                if c==39:
                   curr_event = curr_event[:-3]
                if c==40:
                   curr_event = curr_event[:-3]
                if 'e("3"' in curr_event:
                   curr_event = curr_event.replace('"","S-1-5-18"','"S-1-5-18"')
                curr_event = curr_event + (')' if curr_event.endswith('"') else '")')
                print(curr_event)
              except:
                print("Parse event error")
        # Syslog events
        else:
            if cplex_type == "syslog":

                flg = True
                curr_event = ''
                event = self.xparse(data_[0])
                for evt_attribute, value in event.iteritems():
                    for attribute in self.onto_prim_types:
                        evt_attribute_ = evt_attribute.lower()
                        if SequenceMatcher(None, str(attribute), evt_attribute_).ratio() >= 0.75:
                            if flg:
                                curr_event = 'e("' + str(value).encode('utf-8','ignore').replace('"','') + '","'
                                flg = False
                            else:
                                curr_event = curr_event + str(value).encode('utf-8','ignore').replace('"','') + '","'
                curr_event = curr_event[:-2]
                curr_event = curr_event + ')'
                print(curr_event)


class xASTD_host_collector:
    HOST = '0.0.0.0'
    PORT = 9093
    ontology_types = {}
    def start_collection(self):
        try:
            server_sock = SocketServer.UDPServer((self.HOST, self.PORT), xASTD_hcap_server)
            server_sock.handle_request()
        except (IOError, SystemExit):
            raise

class AESCypher:

    DECRYPT_KEY = 'HKLlbF514I09oYcv'

    def decrypt(self, msg):
        aes = pyaes.AESModeOfOperationCTR(self.DECRYPT_KEY)
        return aes.decrypt(msg)



msg_cnt=""

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
            onto_feeds = ''
            if json_onto_feeds:
                  with open(json_onto_feeds, "r") as f:
                    onto_feeds = json.load(f)
            f.close()

            for onto_spec_type in onto_spec_types:
                if "packet" in onto_spec_type.lower() or "flow" in onto_spec_type.lower():
                    netcap = xASTD_net_cap()
                    netcap.cplex_type = "packet" if "packet" in onto_spec_type.lower() else "flow"
                    netcap.onto_prim_types = onto_feeds[onto_spec_type].keys()
                    netcap.INTERFACE = cfg['CONFIGS']['NETWORK_CONFIGS']['INTERFACES']['interface_1']
                    netcap.QUEUE_MAX_SIZE = cfg['CONFIGS']['NETWORK_CONFIGS']['QUEUE_MAX_SIZE']
                    netcap.defaultViewMode = cfg['CONFIGS']['NETWORK_CONFIGS']['PAYLOAD_FORMAT']
                    netcap.start_capture()
                elif "session" in onto_spec_type.lower():
                    netcap = xASTD_net_cap()
                    netcap.cplex_type = "httpsession"  if "httpsession" in onto_spec_type.lower() else "dnssession"
                    netcap.onto_prim_types = onto_feeds[onto_spec_type].keys()
                    netcap.INTERFACE = cfg['CONFIGS']['NETWORK_CONFIGS']['INTERFACES']['interface_1']
                    netcap.QUEUE_MAX_SIZE = cfg['CONFIGS']['NETWORK_CONFIGS']['QUEUE_MAX_SIZE']
                    netcap.defaultViewMode = cfg['CONFIGS']['NETWORK_CONFIGS']['PAYLOAD_FORMAT']
                    netcap.start_capture()
                elif "log" in  onto_spec_type.lower():
                    hcap = xASTD_host_collector()
                    cplex_type = "wineventlog" if "wineventlog" in  onto_spec_type.lower() else "syslog"
                    onto_prim_types = onto_feeds[onto_spec_type].keys()
                    hcap.HOST = cfg['CONFIGS']['SERVER_CONFIGS']['HOST']
                    hcap.PORT = cfg['CONFIGS']['SERVER_CONFIGS']['PORT']
                    hcap.start_collection()

#
# SIMPLE PREPROCESSING FOR BENCHMARK ANALYSIS
#

import os
from scapy.all import * #pip3 install scapy
import re 
import zlib
import time
import datetime
import sys

msg_cnt = ""

def HTTPParser(http_payload, opts=0):
    
        http_c = ""
        msg_cnt=http_payload
        if opts == 0:
           regex = r"(?:[\r\n]{0,1})(\w+\-\w+|\w+)(?:\ *:\ *)([^\r\n]*)(?:[\r\n]{0,1})"
           headers = re.findall(regex, http_payload, re.UNICODE)
           for key, val in headers:
              http_c = http_c + str(key)+": "+str(val)+" "
              msg_cnt = msg_cnt.replace(str(key)+": "+str(val),"")
        elif opts == 1:
           patterns = re.compile("(?:POST|GET|DELETE|PUT) [\-_a-zA-Z0-9./?&:=@]+ HTTP/1\..")
           uris = patterns.findall(http_payload)
           if not uris:
              http_c = ""
           else:
              http_c = str(uris[0])
           msg_cnt.replace(http_c,"")
 
        return http_c

def extractText(headers, http_payload):
    text = None
    try:
            if 'text/plain' in headers['Content-Type']:
                text = http_payload[http_payload.index("\r\n\r\n")+4:]
                try:
                    if "Accept-Encoding" in headers.keys():
                        if headers['Accept-Encoding'] == "gzip":
                            text = zlib.decompress(text,  16+zlib.MAX_WBITS)
                    elif headers['Content-Encoding'] == "deflate":
                        text = zlib.decompress(text)
                except: pass

    except: pass


if __name__ == "__main__":

   data = str(sys.argv[1])
   a = rdpcap(data)
   sessions = a.sessions()
   #carved_texts = 1
   for session in sessions:

      protocol = ""
      ipsrc =  ""
      ipdst = ""
      portsrc = ""
      portdst = ""
      msg_req = ""
      msg_hdr = ""

      for stream in sessions[session]:
              #print(packet)
              if IP in stream:
                 ipsrc = str(stream[IP].src)
                 ipdst = str(stream[IP].dst)
              
              if TCP in stream:
                 protocol = "tcp"
                 portsrc = str(stream[TCP].sport)
                 portdst = str(stream[TCP].dport)
                 http_payload = str(stream[TCP].payload)
                 msg_req = HTTPParser(http_payload,1)
                 msg_hdr = HTTPParser(http_payload,0)
                 timestamp=datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
                 msg_cnt=msg_cnt.replace('"',"'")
                 msg_cnt=msg_cnt.replace("\n","")
                 msg_hdr = msg_hdr.replace('"',"'")
                 curr_event=("e(\""+protocol+"\",\""+ipdst+"\",\""+portdst+"\",\""+ipsrc+"\",\""+msg_cnt+"\",\""+msg_req+"\",\""+msg_hdr+"\",\""+timestamp+"\",\""+portsrc+"\")\n")
                 print(curr_event)
              if UDP in stream:
                 protocol = "udp"
                 portsrc = str(stream[UDP].sport)
                 portdst = str(stream[UDP].dport)
                 dns_payload = str(stream[UDP].payload)
                 msg_req = "A"
                 msg_hdr = ""
                 msg_cnt = dns_payload.replace('"',"'")
                 msg_cnt = msg_cnt.replace("\n","")
                 timestamp=datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
                 curr_event=("e(\""+protocol+"\",\""+ipdst+"\",\""+portdst+"\",\""+ipsrc+"\",\""+msg_cnt+"\",\""+msg_req+"\",\""+msg_hdr+"\",\""+timestamp+"\",\""+portsrc+"\")\n")
                 print(curr_event)
      #text = extractText(headers,http_payload)
      #if text is not None:
      #     print (text)

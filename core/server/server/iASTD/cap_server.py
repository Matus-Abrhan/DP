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

import socketserver
import sys


class xASTD_net_cap:

    def HTTPParser(self, http_payload, opts=0):
        pass

    def got_packet(self, packets):
        pass

    # decoding tcp flags
    def tochar(self, flag):
        pass

    # packet shipping and decoding
    def start_capture(self):
        pass


class xASTD_hcap_server(socketserver.BaseRequestHandler):

    # parse syslog events
    def xparse(self, syslog):
        pass

    # handles the collection of both sysmon and syslog events
    def handle(self):
        pass


class xASTD_host_collector:

    def start_collection(self):
        pass


class AESCypher:

    DECRYPT_KEY = 'HKLlbF514I09oYcv'

    def decrypt(self, msg):
        # aes = pyaes.AESModeOfOperationCTR(self.DECRYPT_KEY)
        # return aes.decrypt(msg)
        return msg


msg_cnt = ""

if __name__ == "__main__":

    if len(sys.argv) < 2:
        print("python cap_server.py [onto_spec_types]")
    else:
        pass

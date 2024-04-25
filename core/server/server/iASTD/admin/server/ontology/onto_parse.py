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
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import rdflib  # pip3 install rdflib
import sys
import json

if len(sys.argv) < 2:
    print("Usage : python onto_parse.py rdf_file [metadata_link]\n default "
          "metadata_link: http://www.semanticweb.org/sock_connect__/ontologies/2018/0/event_rdf#")
    sys.exit()
else:

    g = rdflib.Graph()

    if len(sys.argv) == 2:
        SUBJECT_METADATA = "http://www.semanticweb.org/sock_connect__/ontologies/2018/0/event_rdf#"
    elif len(sys.argv) == 3:
        SUBJECT_METADATA = sys.argv[2]

    PREDICATE_METADATA = "http://www.w3.org/2000/01/rdf-schema#"
    OBJECT_METADATA = "http://www.w3.org/2001/XMLSchema#"

    DOMAIN_METADATA = PREDICATE_METADATA + "domain"
    RANGE_METADATA = PREDICATE_METADATA + "range"
    COMMENT_METADATA = PREDICATE_METADATA + "comment"

    OCAML_COMMENT_QUOTES = ["(* ", " *)"]

    col_type = {}
    ent_col = {}
    col_com = {}
    g.load(sys.argv[1])
    u_entity = set()

    for s, p, o in g:

        if RANGE_METADATA in p:
            _column = s.replace(SUBJECT_METADATA, "")
            _type = o.replace(OBJECT_METADATA, "")
            col_type[_column] = _type

        if DOMAIN_METADATA in p:
            _column = s.replace(SUBJECT_METADATA, "")
            _entity = o.replace(OBJECT_METADATA, "").replace(SUBJECT_METADATA, "")
            ent_col[_column] = _entity
            u_entity.add(_entity)

    lck = False
    string = ""
    types = {}

    for _entity in u_entity:
        for c, e in ent_col.items():
            if e in _entity:
                if not lck:
                    types[_entity] = {}
                    types[_entity][c.lower()] = col_type[c].lower()
                    lck = True
                else:
                    types[_entity][c.lower()] = col_type[c].lower()

        lck = False

    json_file = open("onto_feeds.json", "w")
    json.dump(types, json_file)
    json_file.close()
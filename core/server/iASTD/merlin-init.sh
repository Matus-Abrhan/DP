#!/bin/sh

if test -f .merlin; then

    echo ".merlin already exists, not going to do anything. Delete .merlin to generate it." >&2
    exit 1

else

    # Default EXT's:
    cat >.merlin <<EOF
S .
S UnitTests
B _build
B UnitTests/_build
EOF

    # Add PKG's:
    ocamlfind list \
	| awk '{ print "PKG "$1 }' >>.merlin

    # See https://github.com/the-lambda-church/merlin/wiki/Letting-merlin-locate-go-to-stuff-in-.opam
    find ~/.opam -name '*.cmt' -print0 \
	| xargs -0 -I{} dirname '{}' \
	| sort -u \
	| awk '{ print "S "$0"\nB "$0 }' >> .merlin

fi

#!/bin/sh
# Edge lines for web/parity.test.js. Not meant to run. Each line probes one
# boundary of the lint rules so the browser copy cannot drift from bin/rosetta.
  # declare -A inside an indented comment: skipped
	# tab-indented comment with ${x,,}: skipped
typeset -A env_map
first=${name^}
low1=${name,}
echo -n "x"
echo -nx "not the -n flag"
echo -e
tee >(cat) </dev/null
cat <((ls))
some_cmd &>> /tmp/log
readarray -t rows
x=${HOME}   # plain expansion, no finding
echo "declare -A in a string still counts"

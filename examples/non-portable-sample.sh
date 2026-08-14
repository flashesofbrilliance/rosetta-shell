#!/usr/bin/env bash
# Deliberately non-portable — feed it to `rosetta lint` to see the findings.
declare -A config
config[name]=arcs
name="HELLO"
echo -e "lowered: ${name,,}"
mapfile -t lines < input.txt
result=$(some_cmd) &> /dev/null
diff <(sort a) <(sort b)

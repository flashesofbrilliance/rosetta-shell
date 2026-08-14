#!/usr/bin/env sh
# Fixture: exercises the rosetta map with tricky keys/values. Its stdout MUST be
# byte-identical under every shell — that identity IS the losslessness proof.
. "${ROSETTA_LIB:?set ROSETTA_LIB}/rosetta.sh"

rosetta_map_set colors red   "#FF0000"
rosetta_map_set colors green "#00FF00"
rosetta_map_set colors "key with spaces" "value	with	tabs"
rosetta_map_set colors "quote'd" 'weird$value{}'
rosetta_map_set colors red "#F00"          # overwrite, must keep order

printf 'size=%s\n' "$(rosetta_map_size colors)"
printf 'red=%s\n' "$(rosetta_map_get colors red)"
printf 'spaces=%s\n' "$(rosetta_map_get colors 'key with spaces')"
printf 'quote=%s\n' "$(rosetta_map_get colors "quote'd")"
printf 'has_green=%s\n' "$(rosetta_map_has colors green && echo yes || echo no)"
printf 'has_blue=%s\n' "$(rosetta_map_has colors blue && echo yes || echo no)"

echo '--- keys in insertion order ---'
rosetta_map_keys colors

rosetta_map_del colors green
echo '--- after del green ---'
rosetta_map_keys colors
printf 'size=%s\n' "$(rosetta_map_size colors)"

echo '--- case shims ---'
printf 'lower=%s\n' "$(rosetta_lower 'HeLLoWORLD')"
printf 'upper=%s\n' "$(rosetta_upper 'HeLLo world')"

echo '--- split ---'
emit() { printf '[%s]' "$1"; }
rosetta_split ':' 'a:bb:ccc:' emit
printf '\n'

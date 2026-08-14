#!/usr/bin/env sh
# Fixture: adversarial values — empty, newline-bearing, unicode, whitespace.
# Byte-identical stdout across shells proves the store is truly lossless.
. "${ROSETTA_LIB:?set ROSETTA_LIB}/rosetta.sh"

rosetta_map_set m empty ""
rosetta_map_set m multiline "line1
line2
line3"
rosetta_map_set m unicode "café — naïve — 日本語 — ✓"
rosetta_map_set m padded "  spaced  "
rosetta_map_set m "" "empty-key-value"

printf 'empty=[%s]\n' "$(rosetta_map_get m empty)"
printf 'multiline=[%s]\n' "$(rosetta_map_get m multiline)"
printf 'unicode=[%s]\n' "$(rosetta_map_get m unicode)"
printf 'padded=[%s]\n' "$(rosetta_map_get m padded)"
printf 'emptykey=[%s]\n' "$(rosetta_map_get m '')"
printf 'size=%s\n' "$(rosetta_map_size m)"
echo '--- keys ---'
rosetta_map_keys m

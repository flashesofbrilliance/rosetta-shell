#!/usr/bin/env sh
# Demo: the SAME script, sourcing rosetta.sh, runs natively in bash 3.2, zsh,
# and POSIX sh — no `declare -A`, no `${v,,}`, no arrays. "Service localization":
# the script speaks each shell's locale through the rosetta phrasebook.
#
# Run it under any shell:  bash examples/translate-demo.sh / zsh ... / dash ...
. "$(dirname "$0")/../lib/rosetta.sh"

rosetta_version

# A config map that would need `declare -A` (broken in bash 3.2 & POSIX):
rosetta_map_set env NAME    "ARCS"
rosetta_map_set env REGION  "us-east"
rosetta_map_set env "feature flag" "on"

echo
echo "Localized config:"
rosetta_map_keys env | while IFS= read -r k; do
  printf '  %-14s = %s\n' "$k" "$(rosetta_map_get env "$k")"
done

echo
echo "Case-fold (needs bash4 case-expansion natively):"
printf '  lower(%s) = %s\n' "ARCS" "$(rosetta_lower ARCS)"

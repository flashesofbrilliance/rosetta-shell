#!/usr/bin/env sh
# Conformance runner. For every fixture, execute it under each installed shell
# locale and assert byte-identical stdout. The reference is the first shell that
# runs; any divergence is a losslessness FAILURE.
#
# Exit 0 iff every fixture is byte-identical across every present shell.
set -u

_self=$0
case "$_self" in */*) _cdir=${_self%/*} ;; *) _cdir=. ;; esac
CONF_DIR=$(cd "$_cdir" && pwd)
ROOT=$(cd "$CONF_DIR/.." && pwd)
ROSETTA_LIB="$ROOT/lib"
export ROSETTA_LIB

CANDIDATES="/bin/bash bash zsh /bin/dash /bin/sh ksh"

# Resolve the shells actually present, de-duplicated by their real path so we
# don't count the same binary twice (e.g. bash == /bin/bash).
SHELLS=""
_seen=""
for s in $CANDIDATES; do
  _p=$(command -v "$s" 2>/dev/null) || continue
  _rp=$(cd "$(dirname "$_p")" 2>/dev/null && printf '%s/%s' "$(pwd)" "$(basename "$_p")")
  # Label by version so /bin/bash 3.2 and bash 5 are treated as distinct locales
  _ver=$("$s" -c 'echo "${BASH_VERSION:-${ZSH_VERSION:-posix}}"' 2>/dev/null || echo '?')
  _tag="$s@$_ver"
  case " $_seen " in *" $_tag "*) continue ;; esac
  _seen="$_seen $_tag"
  SHELLS="$SHELLS $s"
done

printf 'rosetta-shell conformance\n'
printf 'locales:%s\n\n' "$(for s in $SHELLS; do printf ' %s(%s)' "$s" "$("$s" -c 'echo "${BASH_VERSION:-${ZSH_VERSION:-posix}}"' 2>/dev/null)"; done)"

FIXTURES=$(ls "$CONF_DIR"/fixtures/*.sh 2>/dev/null)
PASS=0
FAIL=0

for fx in $FIXTURES; do
  _name=$(basename "$fx")
  _ref=""
  _refshell=""
  _ok=1
  _detail=""
  for s in $SHELLS; do
    _out=$(ROSETTA_LIB="$ROSETTA_LIB" "$s" "$fx" 2>&1)
    _hash=$(printf '%s' "$_out" | cksum | awk '{print $1"-"$2}')
    if [ -z "$_ref" ]; then
      _ref=$_hash; _refshell=$s
    elif [ "$_hash" != "$_ref" ]; then
      _ok=0
      _detail="$_detail\n    DIVERGES: $s ($_hash) vs $_refshell ($_ref)"
    fi
  done
  if [ "$_ok" -eq 1 ]; then
    printf '  [PASS] %-20s identical across %s locale(s)\n' "$_name" "$(printf '%s\n' $SHELLS | grep -c .)"
    PASS=$((PASS+1))
  else
    printf '  [FAIL] %-20s%b\n' "$_name" "$_detail"
    FAIL=$((FAIL+1))
  fi
done

printf '\n%s passed, %s failed.\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

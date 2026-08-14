#!/usr/bin/env sh
# Smoke test: runs the conformance suite + a lint/doctor sanity check.
# CI entrypoint (mirrors germinate's `sh packages/shell/test.sh`).
set -eu
_self=$0
case "$_self" in */*) _dir=${_self%/*} ;; *) _dir=. ;; esac
ROOT=$(cd "$_dir" && pwd)

echo "# conformance"
sh "$ROOT/conformance/run.sh"

echo
echo "# lint self-detects the non-portable sample"
if "$ROOT/bin/rosetta" lint "$ROOT/examples/non-portable-sample.sh" >/dev/null 2>&1; then
  echo "FAIL: lint should have found non-portable constructs" >&2
  exit 1
fi
echo "  [PASS] lint flagged the sample (nonzero exit as expected)"

echo
echo "# crossrun passes on a portable script, fails on a bashism"
"$ROOT/bin/rosetta" crossrun "$ROOT/examples/translate-demo.sh" >/dev/null 2>&1 \
  && echo "  [PASS] crossrun clean on portable script" \
  || { echo "FAIL: crossrun should pass on translate-demo" >&2; exit 1; }
_bad=$(mktemp)
printf '#!/bin/sh\ndeclare -A m\nm[x]=1\n' > "$_bad"
if "$ROOT/bin/rosetta" crossrun "$_bad" >/dev/null 2>&1; then
  echo "FAIL: crossrun should fail on declare -A (breaks dash)" >&2; rm -f "$_bad"; exit 1
fi
rm -f "$_bad"
echo "  [PASS] crossrun flagged the bashism"

echo
echo "# doctor runs"
"$ROOT/bin/rosetta" doctor >/dev/null
echo "  [PASS] doctor ran"

echo
echo "ALL SMOKE CHECKS PASSED"

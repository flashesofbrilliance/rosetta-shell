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
echo "# doctor runs"
"$ROOT/bin/rosetta" doctor >/dev/null
echo "  [PASS] doctor ran"

echo
echo "ALL SMOKE CHECKS PASSED"

#!/usr/bin/env bash
# build_and_smoke.sh — local "build + boot-smoke" gate (the local stand-in for CI).
#
# Runs the FULL build (which now includes the build-time CoffeeScript syntax gate,
# see buildSystem/check-coffee-syntax.js) and, if that succeeds, headless-boots the
# produced world (native + SWCanvas) and fails on any boot/console error
# (see ../Fizzygum-tests/scripts/smoke-boot-headless.js). One command, on demand —
# no cloud CI. build_it_please.sh alone stays the fast inner-loop build; this is the
# pre-commit-quality check.
#
# All args are forwarded to build_it_please.sh (e.g. --keepTestsDirectoryAsIs).
# PREREQUISITE for the smoke step: install Puppeteer once:
#     cd ../Fizzygum-tests && npm i
# (If Puppeteer is missing, the smoke step exits 2 and this gate fails with a hint.)
#
# Like build_it_please.sh, this script has NO `set -e`; it checks $? explicitly.

# always operate from the Fizzygum/ repo root (build_it_please.sh assumes this)
cd "$(dirname "$0")" || exit 2

# A tests-stripped build has no Mousetrap, so the SWCanvas boot leg would crash;
# fall back to a native-only smoke in that case.
SMOKE_ARGS=""
case " $* " in
  *" --homepage "*|*" --notests "*)
    echo "(tests-stripped build detected -> boot smoke runs native-only; SWCanvas needs a full build)"
    SMOKE_ARGS="--native-only"
    ;;
esac

echo "==> building (with CoffeeScript syntax gate) ..."
./build_it_please.sh "$@"
if [ "$?" != "0" ]; then
  echo "build_and_smoke: BUILD stage failed -- aborting (boot smoke not run)." 1>&2
  exit 1
fi

echo ""
echo "==> boot smoke test ..."
node ../Fizzygum-tests/scripts/smoke-boot-headless.js $SMOKE_ARGS
if [ "$?" != "0" ]; then
  echo "build_and_smoke: SMOKE stage failed." 1>&2
  exit 1
fi

echo ""
echo "build_and_smoke: OK (build + boot smoke passed)."

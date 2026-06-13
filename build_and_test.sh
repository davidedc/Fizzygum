#!/usr/bin/env bash
# build_and_test.sh — THE PREFERRED, DEFAULT way to test a change.
#
# Full build (incl. the CoffeeScript syntax gate) and, if it succeeds, runs the
# WHOLE SystemTest suite HEADLESS, CONCURRENTLY (parallel shards), at the FASTEST
# playback speed, at dpr 1 — the combination that runs the entire 160-test suite in
# ~1 min on a many-core machine. THIS is the default inner-loop verification for a
# behaviour change; prefer it over opening a browser and watching (~15 min) or running
# tests one at a time. The lighter relatives: build_and_smoke.sh = boot-only gate;
# build_it_please.sh = bare build.
#
# A FULL build is REQUIRED — the headless suite needs the test harness + reference
# assets a full build copies in — so --homepage / --notests are rejected here. Other
# args are forwarded to build_it_please.sh (e.g. --keepTestsDirectoryAsIs to skip the
# test recopy when you only changed framework source, --noSyntaxCheck).
# PREREQUISITE: install Puppeteer once: cd ../Fizzygum-tests && npm i
#
# Default browser is Chrome (Puppeteer). Set FIZZYGUM_TEST_BROWSER=webkit to instead run
# the suite under Safari's engine (Playwright) as a cross-engine check — one-time setup:
# cd ../Fizzygum-tests && npm i && npx playwright install webkit.
#
# Like the sibling scripts, NO `set -e`; $? is checked explicitly.

# always operate from the Fizzygum/ repo root (build_it_please.sh assumes this)
cd "$(dirname "$0")" || exit 2

case " $* " in
  *" --homepage "*|*" --notests "*)
    echo "build_and_test: a tests-stripped build can't run the SystemTest suite -- drop --homepage/--notests (use build_and_smoke.sh for a boot-only check of those)." 1>&2
    exit 2
    ;;
esac

echo "==> building (with CoffeeScript syntax gate) ..."
./build_it_please.sh "$@"
if [ "$?" != "0" ]; then
  echo "build_and_test: BUILD stage failed -- aborting (tests not run)." 1>&2
  exit 1
fi

echo ""
BROWSER_ARG=""
if [ "$FIZZYGUM_TEST_BROWSER" != "" ]; then
  BROWSER_ARG="--browser=$FIZZYGUM_TEST_BROWSER"
  echo "==> headless SystemTest suite ($BROWSER_ARG, parallel shards, speed=fastest, dpr 1) ..."
else
  echo "==> headless SystemTest suite (parallel shards, speed=fastest, dpr 1) ..."
fi
( cd ../Fizzygum-tests && node scripts/run-all-headless.js $BROWSER_ARG )
if [ "$?" != "0" ]; then
  echo "build_and_test: TEST stage failed." 1>&2
  exit 1
fi

echo ""
echo "build_and_test: OK (build + full headless suite passed)."

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
# A FULL build is REQUIRED — the headless suite needs the test harness, and the
# js/tests link to the reference assets, that only a build shipping the harness part
# puts in place — so a profile without it is rejected here. Other args are forwarded
# to build_it_please.sh (e.g. --noSyntaxCheck).
# PREREQUISITE: install Puppeteer once: cd ../Fizzygum-tests && npm i
#
# Default browser is Chrome (Puppeteer). Set FIZZYGUM_TEST_BROWSER=webkit to instead run
# the suite under Safari's engine (Playwright) as a cross-engine check — one-time setup:
# cd ../Fizzygum-tests && npm i && npx playwright install webkit.
#
# Like the sibling scripts, NO `set -e`; $? is checked explicitly.

# always operate from the Fizzygum/ repo root (build_it_please.sh assumes this)
cd "$(dirname "$0")" || exit 2

# Reject a tests-stripped profile by asking the profile itself, not by matching flavour NAMES: the
# question is "does this build have the test machinery in it", and any future profile that drops the
# harness part must be caught too. (The old guard matched --homepage/--notests literally, so a new
# tests-stripped profile would have sailed past it and handed the suite runner a world with no
# Automator and no js/tests link — a confusing failure a long way from its cause.)
PROFILE_VARS=$(python3 -B ./buildSystem/buildProfile.py --shell "$@")
if [ "$?" != "0" ]; then
  echo "build_and_test: could not read the build profile -- aborting." 1>&2
  exit 2
fi
eval "$PROFILE_VARS"
if ! $PROFILE_SHIPS_TESTS ; then
  echo "build_and_test: profile '$PROFILE_NAME' ships no test machinery, so it can't run the SystemTest suite -- use the default (dev) profile, or build_and_smoke.sh for a boot-only check of this one." 1>&2
  exit 2
fi

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

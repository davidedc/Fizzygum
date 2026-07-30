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
# All args are forwarded to build_it_please.sh (e.g. --noSyntaxCheck).
# PREREQUISITE for the smoke step: install Puppeteer once:
#     cd ../Fizzygum-tests && npm i
# (If Puppeteer is missing, the smoke step exits 2 and this gate fails with a hint.)
#
# Like build_it_please.sh, this script has NO `set -e`; it checks $? explicitly.

# always operate from the Fizzygum/ repo root (build_it_please.sh assumes this)
cd "$(dirname "$0")" || exit 2

# WHICH SMOKE THIS TREE GETS is derived from the profile being built, by the same reader the build
# uses (buildSystem/buildProfile.py) — so this script cannot disagree with the build about what is
# in the tree it is about to boot. It used to pattern-match --homepage / --notests out of "$*",
# which meant a third place that had to know what a flavour contains.
#   form precompiled  -> the production assertions (booted from the pre-compiled image, and no
#                        SWCanvas-only payload left in the tree). Implies the native leg only.
#   no SWCanvas entry -> native leg only: there is no index-sw.html to boot.
# ⚠ substitute, check, THEN eval — see the same note in build_it_please.sh.
PROFILE_VARS=$(python3 -B ./buildSystem/buildProfile.py --shell "$@")
if [ "$?" != "0" ]; then
  echo "build_and_smoke: could not read the build profile -- aborting." 1>&2
  exit 1
fi
eval "$PROFILE_VARS"

SMOKE_ARGS=""
if [ "$PROFILE_FORM" = "precompiled" ]; then
  echo "(profile $PROFILE_NAME is precompiled -> boot smoke runs native-only + production-tree assertions)"
  SMOKE_ARGS="--production"
elif ! $PROFILE_SHIPS_SWCANVAS_ENTRY ; then
  echo "(profile $PROFILE_NAME ships no SWCanvas entry page -> boot smoke runs native-only)"
  SMOKE_ARGS="--native-only"
fi

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

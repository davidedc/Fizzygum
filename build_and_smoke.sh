#!/usr/bin/env bash
# build_and_smoke.sh — local "build + boot-smoke" gate (the local stand-in for CI): the FULL build (which includes the
# build-time CoffeeScript syntax gate, see buildSystem/check-coffee-syntax.js) and, if that succeeds, a headless boot
# of every entry page the produced world ships, failing on any boot/console error (see
# ../Fizzygum-tests/scripts/smoke-boot-headless.js). One command, on demand — no cloud CI. build_it_please.sh alone
# stays the fast inner-loop build; this is the pre-commit-quality check.
#
# All args are forwarded to build_it_please.sh (e.g. --noSyntaxCheck). This is its LAUNCHER; the check itself is
# buildSystem/run-build-and-smoke.js. PREREQUISITE for the smoke step: install Puppeteer once:
#     cd ../Fizzygum-tests && npm i
# (If Puppeteer is missing, the smoke step exits 2 and this gate fails with a hint.)

# always operate from the Fizzygum/ repo root (the build assumes this)
cd "$(dirname "$0")" || exit 2

# node runs the check (and reads the profile first): the one check that cannot be made by the program it would run
if ! command -v node &> /dev/null
then
  echo "build_and_smoke.sh: node: command not found" 1>&2
  echo "build_and_smoke: could not read the build profile -- aborting." 1>&2
  exit 1
fi

exec node buildSystem/run-build-and-smoke.js "$@"

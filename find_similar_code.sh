#!/usr/bin/env bash
# find_similar_code.sh — STRUCTURAL (similar, not just copy-pasted) duplicate-code detector.
#
# Complements find_duplicated_code.sh: jscpd there matches EXACT token runs, so a renamed
# identifier — or an interleaved comment — breaks a match, and CoffeeScript's terseness
# keeps whole duplicated methods below its token window. This script instead matches AST
# STRUCTURE: it compiles src/**/*.coffee to a plain-ES5 mirror (CoffeeScript 1 via
# buildSystem/coffee-to-js-mirror.js — see there for why CS1 + the __SUPER__ shim) and runs
# jsinspect's node-type matching over it, which catches renamed/near-miss clones the exact
# scan can't. First run on 2026-07-14 found 125 structural matches jscpd was blind to.
#
# (jsinspect is the same tool as the owner's Oct-2019 experiment — it died on modern JS,
# but the CS1 mirror is plain ES5, which it parses happily. similarity-ts, the modern
# Rust AST tool, was evaluated 2026-07-14 and its v0.5.0 prebuilt mac binary is broken —
# finds nothing even on byte-identical functions; re-check it in future versions.)
#
# Usage (invocable from anywhere; the script cd's itself to the repo root):
#   ./find_similar_code.sh            # default: jsinspect threshold 30 AST nodes
#   ./find_similar_code.sh -t 20      # finer; all args are forwarded to jsinspect
#   ./find_similar_code.sh --tests    # scan the sibling Fizzygum-tests repo instead: node
#                                     # scripts are scanned DIRECTLY (real line numbers!),
#                                     # the harness .coffee via a CS1 mirror -> reports in
#                                     # duplication-report/tests/ (src reports untouched)
#
# Output -> duplication-report/ (gitignored):
#   js-mirror/                 the compiled-ES5 mirror (dir__Class.js; regenerated per run)
#   jsinspect-report.json      machine-readable matches, incl. matched code
#   jsinspect-report.txt       human-readable report with code excerpts
#   jsinspect-report.ai.txt    compact "src/A.coffee @method(jsLx-y) ~ ..." list for LLMs
#
# ⚠ Line numbers in all three reports are COMPILED-JS mirror lines, not .coffee lines —
#   locate findings via file (one class per file) + @method name.
#
# PREREQUISITE: `npm install` once in Fizzygum/ (jsinspect + coffeescript-v1 devDeps).
# Docs: docs/duplicated-code-detection.md. No `set -e`; exit codes checked explicitly.

cd "$(dirname "$0")" || exit 2

JSINSPECT=node_modules/.bin/jsinspect
if [ ! -x "$JSINSPECT" ]; then
  echo "find_similar_code: $JSINSPECT not found -- run \`npm install\` in Fizzygum/ first." 1>&2
  exit 2
fi

# --tests: structural scan of the sibling Fizzygum-tests repo. scripts/*.js is plain node
# JS, so jsinspect reads it in place (REAL line numbers — no mirror caveat); only the
# harness .coffee needs the CS1 mirror. jsinspect's --ignore is a path REGEX (not a glob),
# so unlike jscpd it CAN exclude the dot-dir .scratch.
if [ "$1" = "--tests" ]; then
  shift
  HARNESS_MIRROR=duplication-report/tests/harness-mirror
  echo "==> compiling the Fizzygum-tests harness to an ES5 mirror ..."
  node buildSystem/coffee-to-js-mirror.js "$HARNESS_MIRROR" ../Fizzygum-tests/Automator-and-test-harness-src
  if [ "$?" != "0" ]; then
    echo "find_similar_code: harness mirror compile FAILED." 1>&2
    exit 1
  fi
  JIARGS=("$@"); [ $# -eq 0 ] && JIARGS=(-t 30)
  # ⚠ jsinspect's CLI HARD-CODES ignoring any path matching node_modules|bower_components|
  # test|spec (its --ignore only APPENDS) — "Fizzygum-tests", ".../tests/..." and even
  # "Inspector" (In-SPEC-tor) all match. Explicit FILE arguments bypass that filter, so we
  # always expand the file lists ourselves (no spaces in these repos' script paths).
  SCRIPT_FILES=$(find ../Fizzygum-tests/scripts -name '*.js' -not -path '*node_modules*' -not -path '*/.scratch/*')
  echo "==> jsinspect structural scan of Fizzygum-tests (args: ${JIARGS[*]}) ..."
  "$JSINSPECT" "${JIARGS[@]}" --reporter json \
    "$HARNESS_MIRROR"/*.js $SCRIPT_FILES > duplication-report/tests/jsinspect-report.json
  RC=$?
  if [ "$RC" != "0" ] && [ "$RC" != "5" ]; then
    echo "find_similar_code: jsinspect (--tests) FAILED (exit $RC)." 1>&2
    exit "$RC"
  fi
  "$JSINSPECT" "${JIARGS[@]}" \
    "$HARNESS_MIRROR"/*.js $SCRIPT_FILES > duplication-report/tests/jsinspect-report.txt
  RC=$?
  if [ "$RC" != "0" ] && [ "$RC" != "5" ]; then
    echo "find_similar_code: jsinspect (--tests, text reporter) FAILED (exit $RC)." 1>&2
    exit "$RC"
  fi
  node buildSystem/jsinspect-compact-report.js duplication-report/tests/jsinspect-report.json \
    "$HARNESS_MIRROR" Automator-and-test-harness-src/ > duplication-report/tests/jsinspect-report.ai.txt
  if [ "$?" != "0" ]; then
    echo "find_similar_code: compact-report generation (--tests) FAILED." 1>&2
    exit 1
  fi
  echo ""
  tail -1 duplication-report/tests/jsinspect-report.ai.txt | sed 's/^/find_similar_code: DONE (Fizzygum-tests). /'
  echo "Reports: duplication-report/tests/jsinspect-report.{json,txt,ai.txt}"
  echo "(scripts/* lines are REAL; harness lines are jsL mirror lines)"
  exit 0
fi

echo "==> compiling src/ to the ES5 mirror ..."
node buildSystem/coffee-to-js-mirror.js duplication-report/js-mirror
if [ "$?" != "0" ]; then
  echo "find_similar_code: mirror compile FAILED (a src file no longer compiles under CS1" 1>&2
  echo "  + __SUPER__ shim -- see buildSystem/coffee-to-js-mirror.js header)." 1>&2
  exit 1
fi

# jsinspect exit codes: 0 = ran fine & no matches, 5 = ran fine & matches found (its
# CI-gate convention); anything else is a real error.
JIARGS=("$@"); [ $# -eq 0 ] && JIARGS=(-t 30)

echo "==> jsinspect structural scan (args: ${JIARGS[*]}) ..."
# ⚠ Pass the mirror as EXPLICIT FILES, never as a directory: jsinspect's CLI hard-codes
# ignoring any path matching test|spec when it expands directories — which silently dropped
# meta__InspectorWdgt.js + meta__ClassInspectorWdgt.js ("Inspector" contains "spec") from
# every directory-based scan. Explicit file arguments bypass the filter.
"$JSINSPECT" "${JIARGS[@]}" --reporter json duplication-report/js-mirror/*.js > duplication-report/jsinspect-report.json
RC=$?
if [ "$RC" != "0" ] && [ "$RC" != "5" ]; then
  echo "find_similar_code: jsinspect FAILED (exit $RC)." 1>&2
  exit "$RC"
fi

"$JSINSPECT" "${JIARGS[@]}" duplication-report/js-mirror/*.js > duplication-report/jsinspect-report.txt
RC=$?
if [ "$RC" != "0" ] && [ "$RC" != "5" ]; then
  echo "find_similar_code: jsinspect (text reporter) FAILED (exit $RC)." 1>&2
  exit "$RC"
fi

node buildSystem/jsinspect-compact-report.js duplication-report/jsinspect-report.json > duplication-report/jsinspect-report.ai.txt
if [ "$?" != "0" ]; then
  echo "find_similar_code: compact-report generation FAILED." 1>&2
  exit 1
fi

echo ""
tail -1 duplication-report/jsinspect-report.ai.txt | sed 's/^/find_similar_code: DONE. /'
echo "Reports: duplication-report/jsinspect-report.{json,txt,ai.txt}"
echo "LLM handoff file: duplication-report/jsinspect-report.ai.txt (jsL = compiled-JS lines!)"

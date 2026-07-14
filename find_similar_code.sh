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
"$JSINSPECT" "${JIARGS[@]}" --reporter json duplication-report/js-mirror > duplication-report/jsinspect-report.json
RC=$?
if [ "$RC" != "0" ] && [ "$RC" != "5" ]; then
  echo "find_similar_code: jsinspect FAILED (exit $RC)." 1>&2
  exit "$RC"
fi

"$JSINSPECT" "${JIARGS[@]}" duplication-report/js-mirror > duplication-report/jsinspect-report.txt
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

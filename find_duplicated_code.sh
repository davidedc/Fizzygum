#!/usr/bin/env bash
# find_duplicated_code.sh — duplicated-code (copy/paste) detector over the framework source.
#
# HISTORY: replaces the manual Oct-2019 jsinspect pipeline (copy src/**/*.coffee out by
# hand, batch-compile with `coffee -b -c`, delete the mixins the compiler chokes on,
# then hand-strip the compiled-JS preambles from the report). jsinspect is abandoned
# (last release 2017); jscpd tokenizes CoffeeScript NATIVELY, so this scans the real
# src/**/*.coffee in place — no compile step, and every finding points at editable
# source lines instead of generated JS.
#
# Usage (invocable from anywhere; the script cd's itself to the repo root):
#   ./find_duplicated_code.sh                  # defaults from .jscpd.json (min-tokens 50)
#   ./find_duplicated_code.sh --min-tokens 35  # finer sweep; any jscpd flag forwards
# (Don't override --output / -o: the LLM-handoff file below is written to the
#  default duplication-report/ regardless.)
#
# Output -> duplication-report/ (gitignored, refreshed per run):
#   jscpd-report.json     full machine-readable clone list, incl. the code fragments
#   jscpd-report.md       per-format summary table
#   html/index.html       browsable report
#   jscpd-report.ai.txt   compact "fileA:x-y ~ fileB:x-y" pair list (jscpd's `ai`
#                         reporter) — the token-efficient handoff to paste to an LLM
#
# PREREQUISITE: `npm install` once in Fizzygum/ (jscpd is a devDependency).
# Tuning guide + gotchas (silent big-file skip!): docs/duplicated-code-detection.md
# Like build_it_please.sh, no `set -e` — exit codes are checked explicitly.

cd "$(dirname "$0")" || exit 2

JSCPD=node_modules/.bin/jscpd
if [ ! -x "$JSCPD" ]; then
  echo "find_duplicated_code: $JSCPD not found -- run \`npm install\` in Fizzygum/ first." 1>&2
  exit 2
fi

echo "==> jscpd scan (defaults from .jscpd.json; extra args: $*) ..."
"$JSCPD" "$@"
RC=$?
if [ "$RC" != "0" ]; then
  echo "find_duplicated_code: jscpd FAILED (exit $RC)." 1>&2
  exit "$RC"
fi

# Second, silent pass for the LLM-handoff file: the `ai` reporter only writes to
# stdout, so it can't share the run above (the two outputs would interleave). The
# rescan costs ~1.5s, and jscpd does NOT wipe the output dir between runs, so the
# first pass's reports survive. ANSI codes are stripped and the output is cut at
# the trailing "time:" line (which the sponsor banner follows); the clone list and
# both summary lines are kept.
ESC=$(printf '\033')
"$JSCPD" "$@" --reporters ai,silent 2>/dev/null \
  | sed "s/${ESC}\[[0-9;]*m//g" \
  | awk '/^time:/{exit} {print}' \
  > duplication-report/jscpd-report.ai.txt
RC=${PIPESTATUS[0]}
if [ "$RC" != "0" ]; then
  echo "find_duplicated_code: ai-reporter pass FAILED (exit $RC)." 1>&2
  exit "$RC"
fi

echo ""
echo "find_duplicated_code: DONE. Reports in duplication-report/ :"
ls -1 duplication-report
echo "LLM handoff file: duplication-report/jscpd-report.ai.txt"

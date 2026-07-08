#!/bin/bash
# run-campaign.sh — the COMPLETE profiling campaign, exactly as run on 2026-07-07
# (phases A–F), consolidated with the lessons learned baked in:
#   - counter runs may overlap (counts are load-independent); all but the first need
#     FIZZYGUM_KEEP_STALE_BROWSERS=1 or the startup pkill culls the sibling's browser;
#   - CPU-profile runs MUST be serial (contention distorts sampling);
#   - the native backend (--sw=0) is SKIPPED: it does not run headless (first test hangs
#     on SWCanvas-oriented reference/settle gates) — derive the framework share by
#     bucketing the sw=1 profile instead;
#   - A/B wall-clock runs carry no profiler/counters, and dpr2 is the density where wall
#     time responds ~1:1 to CPU (dpr1 is frame-count-bound at ~57fps).
#
# Prereqs: FULL fresh build (cd Fizzygum && ./build_it_please.sh) and Puppeteer
# (cd Fizzygum-tests && npm i). ~55 min total on a many-core box. All runs must end
# "failed=0" — a red instrumented run means the harness (not the world) broke.
#
# Usage: bash run-campaign.sh [workdir]        (default /tmp/fizzygum-profiling)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${1:-/tmp/fizzygum-profiling}"
mkdir -p "$WORK"
LOG="$WORK/campaign.log"
note () { echo "$* $(date +%H:%M:%S)" | tee -a "$LOG"; }

SHADOW="$WORK/shadow-build"
NOLOG="$WORK/shadow-build-nolog"
bash "$HERE/mk-shadow-build.sh" "$SHADOW"
node "$HERE/mk-nolog-build.js" "$SHADOW" "$NOLOG"

note "=== phase A: workload counters, REAL minified build, 2 configs CONCURRENT"
node "$HERE/prof-run.js" --sw=1 --dpr=1 --tests=all --counters \
  --out="$WORK/cnt-sw1-dpr1" > "$WORK/cnt-sw1-dpr1.log" 2>&1 &
P1=$!
sleep 8   # let the first run's stale-browser pkill finish before starting siblings
FIZZYGUM_KEEP_STALE_BROWSERS=1 node "$HERE/prof-run.js" --sw=1 --dpr=2 --tests=all --counters \
  --out="$WORK/cnt-sw1-dpr2" > "$WORK/cnt-sw1-dpr2.log" 2>&1 &
P2=$!
wait $P1; wait $P2
note "phase A done"

note "=== phase B: CPU profiles, shadow (unminified) build, SERIAL"
FIZZYGUM_KEEP_STALE_BROWSERS=1 node "$HERE/prof-run.js" --build="$SHADOW" --sw=1 --dpr=1 --tests=all \
  --profile --sample-us=300 --out="$WORK/prof-sw1-dpr1" > "$WORK/prof-sw1-dpr1.log" 2>&1
note "prof sw1 dpr1 exit=$?"
FIZZYGUM_KEEP_STALE_BROWSERS=1 node "$HERE/prof-run.js" --build="$SHADOW" --sw=1 --dpr=2 --tests=all \
  --profile --sample-us=500 --timeout-mins=40 --out="$WORK/prof-sw1-dpr2" > "$WORK/prof-sw1-dpr2.log" 2>&1
note "prof sw1 dpr2 exit=$?"

note "=== phase C: boot profile (navigation→ready; one quick test)"
FIZZYGUM_KEEP_STALE_BROWSERS=1 node "$HERE/prof-run.js" --build="$SHADOW" --sw=1 --dpr=1 \
  --tests=macroAnalogClockInspectEdit --profile --profile-boot --sample-us=200 \
  --out="$WORK/prof-boot" > "$WORK/prof-boot.log" 2>&1
note "boot profile exit=$?"

note "=== phase D: S1 (drawImage console.log) A/B, dpr1, no profiler"
FIZZYGUM_KEEP_STALE_BROWSERS=1 node "$HERE/prof-run.js" --build="$SHADOW" --sw=1 --dpr=1 --tests=all \
  --out="$WORK/ab-baseline" > "$WORK/ab-baseline.log" 2>&1
note "A baseline exit=$?"
FIZZYGUM_KEEP_STALE_BROWSERS=1 node "$HERE/prof-run.js" --build="$NOLOG" --sw=1 --dpr=1 --tests=all \
  --out="$WORK/ab-nolog" > "$WORK/ab-nolog.log" 2>&1
note "B nolog exit=$?"

note "=== phase E: post-S1 profile on NOLOG build + eval'd-source capture (method-level names)"
FIZZYGUM_KEEP_STALE_BROWSERS=1 node "$HERE/prof-run.js" --build="$NOLOG" --sw=1 --dpr=1 --tests=all \
  --profile --save-sources --sample-us=300 --out="$WORK/prof-framework" > "$WORK/prof-framework.log" 2>&1
note "phase E exit=$?"

note "=== phase F: S1 A/B at dpr2 (CPU-bound density → wall shows the win)"
FIZZYGUM_KEEP_STALE_BROWSERS=1 node "$HERE/prof-run.js" --build="$SHADOW" --sw=1 --dpr=2 --tests=all \
  --timeout-mins=40 --out="$WORK/ab2-baseline" > "$WORK/ab2-baseline.log" 2>&1
note "A dpr2 baseline exit=$?"
FIZZYGUM_KEEP_STALE_BROWSERS=1 node "$HERE/prof-run.js" --build="$NOLOG" --sw=1 --dpr=2 --tests=all \
  --timeout-mins=40 --out="$WORK/ab2-nolog" > "$WORK/ab2-nolog.log" 2>&1
note "B dpr2 nolog exit=$?"

note "=== aggregate"
node "$HERE/prof-aggregate.js" "$WORK/prof-sw1-dpr1" --segments="$SHADOW/segments.json" --top=45 > "$WORK/prof-sw1-dpr1.report.txt"
node "$HERE/prof-aggregate.js" "$WORK/prof-sw1-dpr2" --segments="$SHADOW/segments.json" --top=45 > "$WORK/prof-sw1-dpr2.report.txt"
node "$HERE/prof-aggregate.js" "$WORK/prof-boot"     --segments="$SHADOW/segments.json" --top=30 > "$WORK/prof-boot.report.txt"
node "$HERE/prof-aggregate.js" "$WORK/prof-framework" --segments="$SHADOW/segments.json" --top=45 > "$WORK/prof-framework.report.txt"
node "$HERE/prof-groups.js" "$WORK/prof-sw1-dpr1" "$SHADOW/segments.json" > "$WORK/prof-sw1-dpr1.groups.txt"
node "$HERE/prof-groups.js" "$WORK/prof-sw1-dpr2" "$SHADOW/segments.json" > "$WORK/prof-sw1-dpr2.groups.txt"
node "$HERE/prof-groups.js" "$WORK/prof-framework" "$SHADOW/segments.json" > "$WORK/prof-framework.groups.txt"
note "=== campaign done — wall times: grep 'run took' $WORK/*.log; reports: $WORK/*.report.txt *.groups.txt"

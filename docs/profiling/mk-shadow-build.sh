#!/bin/bash
# Assemble a "shadow build" of the Fizzygum test harness that runs the UNMINIFIED
# boot bundle (deterministic-trig + vendor swcanvas.js + fizzygum-boot.js) so CPU
# profiles carry real function names. Nothing in Fizzygum-builds is touched:
# the shadow dir symlinks js/, icons/, font-assets/ and carries its own HTML +
# concatenated profile-boot.js. Segment line offsets are recorded in
# segments.json for bucket attribution of profile frames (prof-aggregate.js).
#
# Usage: bash mk-shadow-build.sh [output-dir]   (default /tmp/fizzygum-profiling/shadow-build)
# Requires a FULL normal build in ../Fizzygum-builds/latest first.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
FIZ="$(cd "$HERE/../.." && pwd)"                      # Fizzygum repo root
LATEST="$(cd "$FIZ/../Fizzygum-builds/latest" && pwd)"
OUT="${1:-/tmp/fizzygum-profiling/shadow-build}"

rm -rf "$OUT"
mkdir -p "$OUT"
ln -s "$LATEST/js" "$OUT/js"
ln -s "$LATEST/icons" "$OUT/icons"
ln -s "$LATEST/font-assets" "$OUT/font-assets"

BOOT="$OUT/profile-boot.js"
SEGJSON="$OUT/segments.json"

line=1
echo -n "[" > "$SEGJSON"

append_segment () { # name, file
  local name="$1" file="$2"
  local start=$line
  cat "$file" >> "$BOOT"
  printf '\n;\n' >> "$BOOT"
  local n
  n=$(wc -l < "$BOOT")
  line=$((n + 1))
  if [ "$start" -ne 1 ]; then echo -n "," >> "$SEGJSON"; fi
  echo -n "{\"name\":\"$name\",\"startLine\":$start,\"endLine\":$n}" >> "$SEGJSON"
}

: > "$BOOT"
append_segment "DetTrig" "$FIZ/runtime-prelude/deterministic-trig.js"
printf ';try { DetTrig.install(Math); } catch (e) {}\n;\n' >> "$BOOT"
line=$(( $(wc -l < "$BOOT") + 1 ))
append_segment "SWCanvas" "$FIZ/vendor/swcanvas/swcanvas.js"
append_segment "FizzygumBoot" "$LATEST/js/fizzygum-boot.js"
echo "]" >> "$SEGJSON"

sed 's|js/fizzygum-boot-min.js|profile-boot.js|' "$LATEST/worldWithSystemTestHarness.html" > "$OUT/worldWithSystemTestHarness.html"

echo "shadow build ready: $OUT"
cat "$SEGJSON"

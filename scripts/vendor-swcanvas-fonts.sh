#!/bin/bash
#
# vendor-swcanvas-fonts.sh — vendor SWCanvas's bitmap-font assets into
# font-assets/ (gitignored). The companion of vendor-swcanvas.sh: that one
# vendors the engine *code*; this one vendors the font *data*, pinned
# independently via vendor/swcanvas-release.pin (a release tag).
#
# The atlases are loaded at RUNTIME (never embedded in the bundle). Over file://
# the browser blocks cross-file Image loads, so SWCanvas ships each atlas
# pre-wrapped as a <script>-injectable .js (atlas-...-webp.js); those plus
# metrics-bundle.js and positioning-bundle-density-*.js are what we copy.
#
# Modes:
#   --source <path>   copy from a local SWCanvas checkout's font-assets/ dir
#                     (for cross-project dev). <path> is the SWCanvas repo root.
#   (from-pin)        [TODO] download the release tarball named in the pin.
#
# Flags:
#   --with-atlases    also copy the wrapped atlas .js files (needed for actual
#                     text rendering). Without it, only metrics + positioning
#                     are copied (enough to boot + measure text; glyphs render
#                     as placeholders until atlases are present).
#   --atlas-max-size N  with --with-atlases, copy atlas .js for sizes 9..N only
#                     (default 24 — covers Fizzygum's UI text; larger sizes stay
#                     as placeholders). Copying all sizes is ~137MB.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIZZ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="$FIZZ_ROOT/font-assets"

SOURCE_PATH=""
WITH_ATLASES=false
ATLAS_MAX_SIZE=24

while [ $# -gt 0 ]; do
  case "$1" in
    --source)        SOURCE_PATH="${2:-}"; shift 2 ;;
    --with-atlases)  WITH_ATLASES=true; shift ;;
    --atlas-max-size) ATLAS_MAX_SIZE="${2:-}"; shift 2 ;;
    -h|--help)       grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "vendor-swcanvas-fonts.sh: unknown argument '$1'" >&2; exit 1 ;;
  esac
done

if [ -z "$SOURCE_PATH" ]; then
  echo "error: from-pin download is not implemented yet; pass --source <SWCanvas repo path>" >&2
  exit 1
fi

SRC="$(cd "$SOURCE_PATH" && pwd)/font-assets"
if [ ! -f "$SRC/metrics-bundle.js" ]; then
  echo "error: $SRC/metrics-bundle.js not found (is SWCanvas's font-assets populated? run its npm run text:download-assets)" >&2
  exit 1
fi

mkdir -p "$DEST"
echo "vendoring SWCanvas font metrics + positioning bundles from $SRC"
cp "$SRC/metrics-bundle.js" "$DEST/"
cp "$SRC"/positioning-bundle-density-*.js "$DEST/"

if $WITH_ATLASES; then
  echo "vendoring wrapped atlas .js for sizes 9..${ATLAS_MAX_SIZE} (all families/styles/densities)..."
  count=0
  size=9
  while [ "$size" -le "$ATLAS_MAX_SIZE" ]; do
    for frac in 0 5; do
      for f in "$SRC"/atlas-*-size-${size}-${frac}-webp.js; do
        [ -e "$f" ] || continue
        cp "$f" "$DEST/"
        count=$((count + 1))
      done
    done
    size=$((size + 1))
  done
  echo "copied $count atlas .js files"
fi

# Completion sentinel records the release tag we vendored against.
cp "$FIZZ_ROOT/vendor/swcanvas-release.pin" "$DEST/VERSION" 2>/dev/null || true
echo "vendored SWCanvas font assets -> $DEST"

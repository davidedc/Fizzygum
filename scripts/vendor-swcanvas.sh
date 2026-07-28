#!/bin/bash
#
# vendor-swcanvas.sh — vendor SWCanvas's built bundle into vendor/swcanvas/.
#
# This mirrors how SWCanvas itself vendors BitmapText: the bulk SWCanvas bytes
# are NOT committed to Fizzygum's git (vendor/swcanvas/ is gitignored). Only the
# one-line pin (vendor/swcanvas.pin, a commit SHA) is committed. A fresh clone's
# first build auto-fetches the pinned bundle (see build_it_please.sh).
#
# Two modes:
#   (default, from-pin)   reads vendor/swcanvas.pin and downloads that exact
#                         commit's tarball from GitHub, vendoring its prebuilt
#                         dist/. No local SWCanvas checkout needed.
#   --source <path>       vendors the locally-built dist/ from a SWCanvas
#                         checkout (for cross-project dev) and rewrites
#                         vendor/swcanvas.pin to that checkout's HEAD SHA so the
#                         next person's from-pin fetch matches what you vendored.
#       --no-pin-update   with --source, do not rewrite the pin (throwaway test).
#
# Safety (mirrors SWCanvas's vendor script):
#   - the source is fully resolved into a staging dir BEFORE vendor/swcanvas is
#     removed, so a failed fetch leaves the existing vendor intact;
#   - vendor/swcanvas/VERSION is written LAST as a completion sentinel, so an
#     interrupted run is re-fetched on the next build.

set -euo pipefail

REPO="davidedc/swcanvas.js"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIZZ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PIN_FILE="$FIZZ_ROOT/vendor/swcanvas.pin"
DEST="$FIZZ_ROOT/vendor/swcanvas"

SOURCE_PATH=""
UPDATE_PIN=true

while [ $# -gt 0 ]; do
  case "$1" in
    --source)        SOURCE_PATH="${2:-}"; shift 2 ;;
    --no-pin-update) UPDATE_PIN=false; shift ;;
    -h|--help)       grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "vendor-swcanvas.sh: unknown argument '$1'" >&2; exit 1 ;;
  esac
done

mkdir -p "$FIZZ_ROOT/vendor"

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

if [ -n "$SOURCE_PATH" ]; then
  # ----- vendor from a local SWCanvas checkout -----
  SRC="$(cd "$SOURCE_PATH" && pwd)"
  for f in dist/swcanvas.js dist/swcanvas.min.js dist/swcanvas-3d-core.js dist/swcanvas-3d-core.min.js dist/sw3d.min.js examples/sw3d.js; do
    if [ ! -f "$SRC/$f" ]; then
      echo "error: $SRC/$f not found — build SWCanvas first (npm run build:prod)" >&2
      exit 1
    fi
  done
  cp "$SRC/dist/swcanvas.js" "$SRC/dist/swcanvas.min.js" \
     "$SRC/dist/swcanvas-3d-core.js" "$SRC/dist/swcanvas-3d-core.min.js" \
     "$SRC/dist/sw3d.min.js" "$SRC/examples/sw3d.js" "$STAGING/"
  SHA="$(git -C "$SRC" rev-parse HEAD 2>/dev/null || echo unknown)"

  if git -C "$SRC" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if ! git -C "$SRC" diff --quiet || ! git -C "$SRC" diff --cached --quiet; then
      echo "warning: SWCanvas checkout has uncommitted changes — a from-pin fetch of $SHA will NOT reproduce this dist. Commit + push, then re-run." >&2
    elif ! git -C "$SRC" branch -r --contains HEAD 2>/dev/null | grep -q .; then
      echo "warning: SWCanvas HEAD $SHA is not on any remote branch — a from-pin fetch would 404 until you push." >&2
    fi
  fi
  echo "vendoring SWCanvas dist from local checkout: $SRC (HEAD $SHA)"
else
  # ----- vendor from the committed pin (download tarball) -----
  if [ ! -f "$PIN_FILE" ]; then
    echo "error: $PIN_FILE missing and no --source given" >&2
    exit 1
  fi
  SHA="$(tr -d '[:space:]' < "$PIN_FILE")"
  URL="https://github.com/$REPO/archive/$SHA.tar.gz"
  echo "fetching SWCanvas $SHA from $URL"
  curl -fsSL "$URL" -o "$STAGING/swcanvas.tar.gz"
  tar -xzf "$STAGING/swcanvas.tar.gz" -C "$STAGING"
  EXTRACTED="$(find "$STAGING" -maxdepth 1 -type d -name 'swcanvas.js-*' | head -1)"
  if [ -z "$EXTRACTED" ]; then
    echo "error: no extracted swcanvas.js-* directory in the fetched tarball" >&2
    exit 1
  fi
  for f in dist/swcanvas.js dist/swcanvas.min.js dist/swcanvas-3d-core.js dist/swcanvas-3d-core.min.js dist/sw3d.min.js examples/sw3d.js; do
    if [ ! -f "$EXTRACTED/$f" ]; then
      echo "error: $f not found in the fetched tarball (pin predates the 3D-core dist target?)" >&2
      exit 1
    fi
  done
  cp "$EXTRACTED/dist/swcanvas.js" "$EXTRACTED/dist/swcanvas.min.js" \
     "$EXTRACTED/dist/swcanvas-3d-core.js" "$EXTRACTED/dist/swcanvas-3d-core.min.js" \
     "$EXTRACTED/dist/sw3d.min.js" "$EXTRACTED/examples/sw3d.js" "$STAGING/"
fi

# Source is fully staged — now it is safe to replace the vendor tree.
rm -rf "$DEST"
mkdir -p "$DEST"
# swcanvas.{js,min.js}        = the full SWCanvas Core+2D+text engine (the SW
#                               boot bundle's backend);
# swcanvas-3d-core.{js,min.js} = the subtractive 3D-core target — Surface +
#                               DepthBuffer + Texture3D + Triangle3DOps only
#                               (the native boot bundle's SW3D substrate);
# sw3d.js / sw3d.min.js       = the userland software-3D engine layer
#                               (examples/sw3d.js), bundled next to whichever
#                               SWCanvas target the entry page loads.
cp "$STAGING/swcanvas.js" "$STAGING/swcanvas.min.js" \
   "$STAGING/swcanvas-3d-core.js" "$STAGING/swcanvas-3d-core.min.js" \
   "$STAGING/sw3d.js" "$STAGING/sw3d.min.js" "$DEST/"

if [ -n "$SOURCE_PATH" ] && $UPDATE_PIN && [ "$SHA" != "unknown" ]; then
  echo "$SHA" > "$PIN_FILE"
  echo "updated $PIN_FILE -> $SHA"
fi

# Completion sentinel, written LAST.
printf '%s\n' "$SHA" > "$DEST/VERSION"
echo "vendored SWCanvas -> $DEST (VERSION $SHA)"

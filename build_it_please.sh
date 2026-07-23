#!/bin/bash

# Examples:
#   ./build_it_please --homepage
#     leaves out all tests and removes experimental parts of the code
#   ./build_it_please.sh --homepage --keepTestsDirectoryAsIs
#     homepage build, but if there are any tests in the current build, it leaves them there,
#     so you can do a full-test build much quicker later
#   ./build_it_please --notests
#     removes tests, leaves in experimental parts of the code
#   ./build_it_please --keepTestsDirectoryAsIs
#     leaves in experimental parts of the code, leaves the whole "tests" directory AS IS, which saves a loooot of time
#   ./build_it_please.sh --keepTestsDirectoryAsIs --includeVideoPlayer --includeVideos
#     as before but also includes the video player and the videos
#   ./build_it_please.sh --keepTestsDirectoryAsIs --includeVideoPlayer --includeVideos; cp -R /Volumes/Seagate\ 5tb/Fizzygum-videos-private ../Fizzygum-builds/latest/videos
#     as before but also includes the video player and the videos, and copies the private videos
#   ./build_it_please.sh --keepTestsDirectoryAsIs --includeVideoPlayer --includeVideos --keepPreviousPrivateVideos
#     as before but instead of copying the private videos, keep the existing ones (as these can take a long time to copy otherwise)
#   ./build_it_please
#     leaves in tests and experimental parts of the code

# SELF-LOCATE: always run from this script's own directory (Fizzygum/), regardless of the caller's cwd.
# The Bash cwd often resets to the umbrella Fizzygum-all/ between calls, and every path below is relative
# to Fizzygum/ -- without this, a bare `./build_it_please.sh` from the wrong dir is "no such file" and a
# `path/to/build_it_please.sh` would build against the wrong tree. Fail loudly if we cannot cd.
cd "$(dirname "$0")" || { echo "build_it_please.sh: FATAL — cannot cd to my own directory ($(dirname "$0"))" >&2; exit 1; }

BUILD_PATH=../Fizzygum-builds/latest
SCRATCH_PATH=$BUILD_PATH/delete_me

# save the arguments because we are going to shift them to parse them here,
# but we need to pass them as-is to the python script
args=( "$@" )

# parse the arguments ###################################################################

# we'll put the switches in these variables:
homepage=false
keepTestsDirectoryAsIs=false
notests=false
includeVideoPlayer=false
includeVideos=false
keepPreviousPrivateVideos=false
# --noSyntaxCheck skips the build-time CoffeeScript syntax gate (default: gate runs).
noSyntaxCheck=false

# see https://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash
while test $# -gt 0; do
  case "$1" in
    --homepage)
      homepage='true'
      shift
      ;;
    --keepTestsDirectoryAsIs)
      keepTestsDirectoryAsIs='true'
      shift
      ;;
    --includeVideoPlayer)
      includeVideoPlayer='true'
      shift
      ;;
    --includeVideos)
      includeVideos='true'
      shift
      ;;
    --keepPreviousPrivateVideos)
      keepPreviousPrivateVideos='true'
      shift
      ;;
    --notests)
      notests='true'
      shift
      ;;
    --noSyntaxCheck)
      # consumed here only; it is ALSO a no-op in build.py, so the forwarded
      # "${args[@]}" (which still contains it) does not trip build.py's argparse.
      noSyntaxCheck='true'
      shift
      ;;
    *)
      break
      ;;
  esac
done


if [ ! -d ../../Fizzygum-all ]; then
  echo
  echo ----------- error -------------
  echo You miss the overarching Fizzygum directory.
  echo ...the directory structure should be
  echo   Fizzygum-all
  echo      - Fizzygum
  echo      - Fizzygum-builds
  echo      - Fizzygum-tests
  echo      - Fizzygum-website
  echo
  # exit NON-ZERO: a bare `exit` here returned the last echo's 0, so an aborted build read as
  # SUCCESS — a baseline clone under a mis-named umbrella "built" green while writing NOTHING
  # and an A/B ran vacuously against the wrong build (ordered-downwalk plan §11, 2026-07-16).
  exit 1
fi

if [ ! -d ../Fizzygum-builds ]; then
  echo
  echo ----------- warning! -------------
  echo You miss the destination Fizzygum-builds directory.
  echo I\'ll create one for you, but ideally you should have
  echo checked-out such directory from github
  echo
  mkdir ../Fizzygum-builds
fi

if ! command -v terser &> /dev/null
then
    echo "Terser could not be found, please see https://www.npmjs.com/package/terser"
    exit 1
fi

if ! command -v coffee &> /dev/null
then
    echo "CoffeeScript could not be found, please install it using:"
    echo "npm install --global coffeescript"
    exit 1
fi

# node runs the build-time syntax gate (buildSystem/check-coffee-syntax.js).
if ! $noSyntaxCheck && ! command -v node &> /dev/null
then
    echo "Node.js could not be found; it is needed for the CoffeeScript syntax gate."
    echo "Install Node, or re-run with --noSyntaxCheck to skip the gate."
    exit 1
fi

echo coffeescript version -------------
coffee --version

# --- SWCanvas backend: ensure the vendored engine bundle is present ----------
# Mirrors SWCanvas's own BitmapText auto-fetch gate. The bulk SWCanvas bytes are
# gitignored; on a fresh clone we fetch them from the committed pin so that
# "git clone && build" Just Works (needs GitHub access on the first build only).
SWCANVAS_VENDOR=vendor/swcanvas
SWCANVAS_PIN=vendor/swcanvas.pin
if [ ! -f "$SWCANVAS_VENDOR/swcanvas.min.js" ] || [ ! -f "$SWCANVAS_VENDOR/sw3d.js" ] || [ ! -f "$SWCANVAS_VENDOR/VERSION" ]; then
  echo "SWCanvas bundle (incl. sw3d.js) missing — fetching from $SWCANVAS_PIN ..."
  ./scripts/vendor-swcanvas.sh
elif [ -f "$SWCANVAS_PIN" ]; then
  PINNED_SHA=$(tr -d '[:space:]' < "$SWCANVAS_PIN")
  VENDORED_SHA=$(tr -d '[:space:]' < "$SWCANVAS_VENDOR/VERSION")
  if [ "$PINNED_SHA" != "$VENDORED_SHA" ]; then
    echo "warning: vendor/swcanvas.pin ($PINNED_SHA) != vendored SWCanvas ($VENDORED_SHA)."
    echo "         Run ./scripts/vendor-swcanvas.sh to refresh (not auto-refreshing to avoid a surprise long build)."
  fi
fi

if [ ! -d $BUILD_PATH ]; then
  mkdir $BUILD_PATH
fi


# ---------------------------------------- cleanup -------------------------------------------

rm -rf $BUILD_PATH/*.html
rm -rf $BUILD_PATH/icons

if $keepTestsDirectoryAsIs ; then
  if [ ! -d $BUILD_PATH/js/tests ]; then
    echo
    echo ----------- error -------------
    echo You asked to keep the tests but there
    echo is no tests directory
    echo
    exit 1
  else
    # delete everything in $BUILD_PATH/js apart from the $BUILD_PATH/js/tests directory
    find $BUILD_PATH/js/ -maxdepth 1 ! -path $BUILD_PATH/js/ -not -name "tests" -exec rm -r {} \;
  fi
else
  # remove the whole $BUILD_PATH/js directory
  rm -rf $BUILD_PATH/js
fi

if $keepPreviousPrivateVideos ; then
  if [ ! -d $BUILD_PATH/videos/Fizzygum-videos-private ]; then
    echo
    echo ----------- error -------------
    echo You asked to keep the private videos but there
    echo is such directory
    echo
    exit 1
  else
    # delete everything in $BUILD_PATH/videos apart from the $BUILD_PATH/videos/Fizzygum-videos-private directory
    find $BUILD_PATH/videos -maxdepth 1 ! -path $BUILD_PATH/videos -not -name "Fizzygum-videos-private" -exec rm -r {} \;
  fi
else
  # remove the whole $BUILD_PATH/videos directory
  rm -rf $BUILD_PATH/videos
fi

# read -p "Directories should be clean, press key to continue... " -n1 -s


# --------------------------------------------------------------------------------------------


if [ ! -d $BUILD_PATH/js ]; then
  mkdir $BUILD_PATH/js
fi

if [ ! -d $BUILD_PATH/icons ]; then
  mkdir $BUILD_PATH/icons
fi

if $includeVideos ; then
  if [ ! -d $BUILD_PATH/videos ]; then
    mkdir $BUILD_PATH/videos
  fi
fi

if [ ! -d $BUILD_PATH/js/libs ]; then
  mkdir $BUILD_PATH/js/libs
fi

if [ ! -d $BUILD_PATH/js/coffeescript-sources ]; then
  mkdir $BUILD_PATH/js/coffeescript-sources
fi

if [ ! -d $BUILD_PATH/js/src ]; then
  mkdir $BUILD_PATH/js/src
fi

if [ ! -d $SCRATCH_PATH ]; then
  mkdir $SCRATCH_PATH
fi

# make space for the test files
if [ ! -d $BUILD_PATH/js/tests ]; then
  mkdir $BUILD_PATH/js/tests
fi

# generate the Fizzygum coffee file in the delete_me directory
# note that this file won't contain much code.
# All the code of the morphs is put in other .coffee files
# which just contain the coffeescript source as the text!
# the first parameter "--homepage" specifies whether this
# is a build for the homepage, in which case a lot of
# legacy code and test-supporting code is left out.
python3 ./buildSystem/build.py "${args[@]}"

# --- build-time CoffeeScript syntax gate ----------------------------------------
# The ~470 class/mixin sources ship as TEXT and are compiled in-browser, so without
# this a "green" build can still contain syntax errors that only blow up at boot.
# The gate loads the REAL src/meta/Class.coffee + Mixin.coffee and drives every
# shipped source through them (see buildSystem/check-coffee-syntax.js). We pass
# "${args[@]}" so the gate checks exactly the files THIS build ships.
# NOTE: this script has no `set -e`, so we MUST check $? explicitly to abort
# (mirrors the terser error-check further below). --noSyntaxCheck is the escape hatch.
if ! $noSyntaxCheck ; then
  echo "checking CoffeeScript syntax of all shipped sources ..."
  node ./buildSystem/check-coffee-syntax.js "${args[@]}"
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: CoffeeScript syntax check failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... CoffeeScript syntax OK"
fi

# --- build-time SHIPPABLE-COVERAGE gate (every src/ dir with .coffee files must ship) --
# build.py's shipped-file list (~lines 191-233) is a hand-maintained sequence of
# glob("src/<dir>/*.coffee") calls, one per directory. A NEW src/ subdirectory ships NOTHING
# until a matching glob() line is added by hand -- the build still exits 0, and the syntax
# gate above (which reads the same --list-shippable set) silently skips the new dir too; the
# only symptom is a runtime `<NewClass> is not defined`. This gate diffs "every .coffee file
# that actually exists under src/" against build.py's own --list-shippable output and fails
# loudly on any survivor (allowlisting the two legitimate exceptions: src/video-player/, which
# ships only behind --includeVideoPlayer, and src/boot/, which build_it_please.sh compiles
# directly and build.py never globs at all -- see buildSystem/check-shippable-coverage.js for
# the full rationale). We pass "${args[@]}" so it checks exactly the flags THIS build uses.
# Same --noSyntaxCheck escape hatch and explicit $? check as the syntax gate above.
if ! $noSyntaxCheck ; then
  echo "checking shippable-source coverage of all src/ directories ..."
  node ./buildSystem/check-shippable-coverage.js "${args[@]}"
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: shippable-coverage check failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... shippable-source coverage OK"
fi

# --- build-time layering / flow-soundness gate (self-settling public geometry API) -----
# Enforces the call-graph layering the self-settling API relies on. A low-level method (raw*/silent*/
# fullRaw*/_*, a *NoSettle core, or the _reLayout* / _positionAndResizeChildren / _reLayoutScrollbars
# layout passes) must NOT reach UP into the public self-flushing layer: [A] no public geometry/text
# setter or recalculateLayouts; [G] no structural self-settling wrapper (destroy/close/fullDestroy/
# createReference/... — discovered structurally as the _settleLayoutsAfter callers); [B] recalculate-
# Layouts() only from doOneCycle / the _settleLayoutsAfter(Batch) settle tiers; [C] no public setter
# calls another; [E] a raw/silent/fullRaw mutator must not _invalidateLayout; [F] a non-mutator handler
# must DEFER a container apply or mark it; [D] a SystemTest macro must not call a private/low-level
# method. (buildSystem/check-layering.js — same --noSyntaxCheck escape hatch and explicit $? check as the
# syntax gates around it; scans src/ + the tests' macros directly so needs no args.)
if ! $noSyntaxCheck ; then
  echo "checking public-API layering of all shipped sources ..."
  node ./buildSystem/check-layering.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: layering gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... layering OK"
fi

# --- build-time INVALIDATION-RECEIVERS gate -------------------------------------------
# Enforces widget-citizenship contract point 2: invalidation is SELF-invalidation — a widget
# never calls changed()/fullChanged() on another widget (if A's action affects B, B marks
# itself changed in the method A invoked on it). Allowed receivers: @ (self) and the shared
# singletons world / world.caret / world.hand; genuine dispatcher plumbing (the structural
# add/drop/z-order movers, the selection-overlay reconciler, …) carries an explicit
# `# cross-invalidation-sanctioned: <reason>` marker. (buildSystem/check-invalidation-receivers.js
# -- same --noSyntaxCheck escape hatch and explicit $? check as the gates around it.)
if ! $noSyntaxCheck ; then
  echo "checking invalidation receivers (self-invalidation contract) ..."
  node ./buildSystem/check-invalidation-receivers.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: invalidation-receivers gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... invalidation-receivers check OK"
fi

# --- build-time DEAD-METHOD gate ------------------------------------------------------
# Flags methods DEFINED in src but referenced NOWHERE (src + tests + harness) -- catches
# dead code like the addRaw / fullRawMoveCenterTo deletions. A baseline of known-dead methods
# is allowlisted in buildSystem/dead-method-allowlist.txt (a to-triage list); the gate FAILS
# only on a NEW dead method not in that list. (buildSystem/check-dead-methods.js -- self-skips
# if the sibling Fizzygum-tests repo is absent, e.g. a --homepage build; same --noSyntaxCheck
# escape hatch and explicit $? check as the layering gate above.)
if ! $noSyntaxCheck ; then
  echo "checking for dead (never-referenced) methods ..."
  node ./buildSystem/check-dead-methods.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: dead-method gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... dead-method check OK"
fi

# --- build-time UNRESOLVED-SENDS gate -------------------------------------------------
# The exact INVERSE of the dead-method gate above: it flags a CALL `[@.]name(` whose name is
# IMPLEMENTED NOWHERE in src + harness -- a guaranteed runtime TypeError on any path reaching it.
# (Pharo's ReSentNotImplementedRule, carried over 2026-07-15.) Deliberately built for ZERO false
# positives at the cost of reach: the def set is over-approximated, paren-less/string-dispatched
# sends are out of scope. Vendor + genuinely-dynamic names are exempted, with a REASON, in
# buildSystem/unresolved-sends-allowlist.txt; standard JS/DOM/canvas API lives in the checker's
# in-file BUILTINS set. (buildSystem/check-unresolved-sends.js -- self-skips if the sibling
# Fizzygum-tests repo is absent, since its harness is part of the definition universe; same
# --noSyntaxCheck escape hatch and explicit $? check as the gates above.)
if ! $noSyntaxCheck ; then
  echo "checking for unresolved sends (calls nobody implements) ..."
  node ./buildSystem/check-unresolved-sends.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: unresolved-sends gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... unresolved-sends check OK"
fi

# --- build-time STINK gate (baseline-ratcheted) ---------------------------------------
# Enforces "stinks": named smells ratcheted at a baseline COUNT. Each stink has its baseline inline in
# buildSystem/check-stinks.js; the gate FAILS only when a stink EXCEEDS its baseline (a regression) --
# mirroring the dead-method allowlist ratchet above -- and prints a "tighten me" note when one drops
# BELOW. Seven are seeded (2026-07-15, docs/archive/lint-generic-rules-carryover-plan.md Phase 2): debugger 36,
# undefined 89, null 10, wall-clock 19, timer 3, Math.random 5, instanceof 105 -- the determinism and
# nil-convention rules that were manual-only until then. Same --noSyntaxCheck escape hatch and explicit
# $? check as the gates above; scans src/ only, so it runs for every build flavour (incl. --homepage).
if ! $noSyntaxCheck ; then
  echo "checking for stinks (smells ratcheted to a baseline) ..."
  node ./buildSystem/check-stinks.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: stink gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... stink check OK"
fi

# --- build-time THIN-WRAP gate --------------------------------------------------------
# Enforces the ONE canonical shape for a public self-settling method that owns a private *Core twin:
# `[guards] @mutateGeometryThenSettle => @_<name>Core <args>` -- it must do no work of its own, only
# delegate to the core through the single-mutation settle tier. Genuine exceptions carry a per-method
# `# thin-wrap-exempt: <reason>` marker (no central allowlist). (buildSystem/check-thin-wraps.js --
# complements check-layering.js, which enforces that the CORE reaches no public setter. Same
# --noSyntaxCheck escape hatch + explicit $? abort as the gates above; scans src/ only.)
if ! $noSyntaxCheck ; then
  echo "checking public/Core thin-wrap shape ..."
  node ./buildSystem/check-thin-wraps.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: thin-wrap gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... thin-wrap check OK"
fi

# --- build-time HYGIENE gates (ported from the retired SourceVault console tool, P2-T3 follow-up) ------
# Three cheap line-scanner lints, each with the same --noSyntaxCheck escape hatch + explicit $? abort as
# the gates above; all scan src/ only, so they run for every build flavour (incl. --homepage):
#   * check-trailing-whitespace.js — no trailing whitespace after content on a line.
#   * check-scheduled-checks.js     — no OVERDUE `# CHECK AFTER <date>` reminder (a build-dated time bomb).
#   * check-stringified-scripts.js  — no `new ScriptWdgt """..."""` stringified-code literal in core.
if ! $noSyntaxCheck ; then
  echo "checking for trailing whitespace ..."
  node ./buildSystem/check-trailing-whitespace.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: trailing-whitespace gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... trailing-whitespace check OK"

  echo "checking for overdue CHECK-AFTER markers ..."
  node ./buildSystem/check-scheduled-checks.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: scheduled-checks gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... scheduled-checks OK"

  echo "checking for stringified scripts in core ..."
  node ./buildSystem/check-stringified-scripts.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: stringified-scripts gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... stringified-scripts check OK"
fi

# --- build-time CONSTRUCTOR-BUILD gate ------------------------------------------------
# Enforces the "all constructors settle" end-state (Topic 4 part 2): a `constructor:` body must NOT build
# its own children inline (@add / @addNoSettle / @addMany / @_addNoSettle / … on `this`). Child-building
# belongs in the _buildAndConnectChildrenNoSettle core, reached from the constructor via the settling
# wrapper @_buildAndConnectChildren() (or @_buildScrollFrame() for the ScrollPanelWdgt base) -- so the
# settle-tier FLUSHES a top-level `new X()` and AUTO-DEFERS one built in-flush (inside a callback). Genuine
# exceptions carry a per-constructor `# constructor-build-exempt: <reason>` marker (no central allowlist).
# (buildSystem/check-constructors-build.js -- same --noSyntaxCheck escape hatch + explicit $? abort as the
# gates above; scans src/ only, so it runs for every build flavour incl. --homepage.)
if ! $noSyntaxCheck ; then
  echo "checking constructors do not build children inline ..."
  node ./buildSystem/check-constructors-build.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: constructor-build gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... constructor-build check OK"
fi

# --- build-time CALL-SEPARATION gate ([S]/[U]) ----------------------------------------
# Enforces the public/private call-separation ratchets (docs/archive/public-private-call-separation-plan.md):
# [S] a PRIVATE method must not @-self-call a public COMMAND (settling / effectful callee -- queries and
# the changed/fullChanged react verbs stay free); [U] a public method referenced ONLY by @-self calls is
# provably not external API and must be _-tier (deliberate end-user inspector/scripting API goes in
# buildSystem/public-api-allowlist.txt). Both are inline count-BASELINES (the check-stinks idiom): the
# gate FAILS only when a count EXCEEDS its baseline; tighten the baseline to lock gains. Per-site escape
# hatch for [S]: mark the CALLER `# public-call-sanctioned: <why>`. Measurement engine:
# buildSystem/census-public-private-calls.js (also a standalone census CLI). [U] self-skips without the
# sibling Fizzygum-tests repo (e.g. --homepage), like the dead-method gate. (buildSystem/
# check-call-separation.js -- same --noSyntaxCheck escape hatch + explicit $? abort as the gates above.)
if ! $noSyntaxCheck ; then
  echo "checking public/private call separation ..."
  node ./buildSystem/check-call-separation.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: call-separation gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... call-separation check OK"
fi

# --- build-time RELAYOUT-BOUNDS-FIRST gate --------------------------------------------
# Enforces that a `_reLayout` override APPLIES ITS OWN BOUNDS before it reads its own geometry to position
# children -- else the children lay out against the PREVIOUS pass's frame and lag one layout cadence on a
# resize/move (the dpr2 "one-cadence-lag" flake fixed in InspectorWdgt and swept across the patch/prompt/app
# widgets). A _reLayout that positions children from the newBoundsForThisLayout PARAM (or positions none)
# passes trivially. Genuine exceptions carry a per-method `# relayout-bounds-first-exempt: <reason>` marker
# (no central allowlist). (buildSystem/check-relayout-bounds-first.js -- same --noSyntaxCheck escape hatch +
# explicit $? abort as the gates above; scans src/ only, so it runs for every build flavour incl. --homepage.)
if ! $noSyntaxCheck ; then
  echo "checking _reLayout applies own bounds before reading own geometry ..."
  node ./buildSystem/check-relayout-bounds-first.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: relayout-bounds-first gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... relayout-bounds-first check OK"
fi

# --- build-time RELAYOUT-REPAINTS gate ([INV-1]) --------------------------------------
# Static sibling to the runtime paint-truthfulness capstone (Fizzygum-tests/scripts/run-paint-audit.js).
# Enforces [INV-1] (docs/layout-regressions-2026-07-icons-plots-editghosts-plan.md): a `_reLayoutSelf` that
# opens a `world.disableTrackChanges()` frame MUST issue a covering `@fullChanged()` after its LAST
# `world.maybeEnableTrackChanges()` -- else a raw-applied child move made inside the suppressed frame leaves
# a stale/"ghost" region (the 2026-07 D2 edit/view-toggle ghosts, Fizzygum a88a1673). Scoped to _reLayoutSelf
# (the covering-repaint owner); genuine exceptions carry a `# relayout-repaint-exempt: <reason>` marker.
# (buildSystem/check-relayout-repaints.js -- same --noSyntaxCheck escape hatch + explicit $? abort as the
# gates above; scans src/ only, so it runs for every build flavour incl. --homepage.)
if ! $noSyntaxCheck ; then
  echo "checking tracking-suppressing _reLayoutSelf issues its covering fullChanged ([INV-1]) ..."
  node ./buildSystem/check-relayout-repaints.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: relayout-repaints gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... relayout-repaints check OK"
fi

# --- build-time RAW-POINTER-READS gate ------------------------------------------------
# Enforces that a pointer-event HANDLER body never consumes the raw SCREEN-plane pointer
# (`world.hand.position()`) unmapped: since affine Phase 4A the dispatcher hands every handler a
# position already inverse-mapped into the receiver's plane, and mixing the raw point with
# plane-local geometry works aligned but silently breaks TILTED (the 2026-07-17 spreadsheet
# tilted-selection bug). Per-frame sampling is allowed only mapped at the read site
# (`screenPointToMyPlane` on the same line — the drag-scroll idiom). Genuine exceptions carry a
# per-method `# raw-screen-pointer-sanctioned: <reason>` marker. (buildSystem/
# check-raw-pointer-reads.js -- same --noSyntaxCheck escape hatch + explicit $? abort as the
# gates above; scans src/ only, so it runs for every build flavour incl. --homepage.)
if ! $noSyntaxCheck ; then
  echo "checking pointer handlers consume the plane-mapped pointer (raw-pointer gate) ..."
  node ./buildSystem/check-raw-pointer-reads.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: raw-pointer-reads gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... raw-pointer-reads check OK"
fi

# --- build-time test-.js syntax gate (only when tests are part of this build) ---------
# Each SystemTest's _automationCommands.js carries its macro inside a backtick-delimited JS
# template literal; a stray backtick silently corrupts the file so the test never loads (with
# corrupted/missing screenshots, not an obvious error). This runs `node --check` over every
# tests/*.js (see ../Fizzygum-tests/scripts/check-tests-syntax.js) to catch that — and any JS
# syntax error — BEFORE the build copies them in. Same --noSyntaxCheck escape hatch and explicit
# $? check as the CoffeeScript gate above; skipped under --homepage/--notests (no tests shipped)
# or when the sibling Fizzygum-tests repo is absent.
if ! $noSyntaxCheck && ! $homepage && ! $notests && [ -d ../Fizzygum-tests ] ; then
  echo "checking JS syntax of all shipped test sources ..."
  node ../Fizzygum-tests/scripts/check-tests-syntax.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: test .js syntax check failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... test .js syntax OK"
fi

# --- build-time SWCanvas reference-image gate (only when tests are part of this build) ---------
# build.py sweeps EVERY ref file in tests/ into the asset manifest, so a STRAY/duplicate ref (e.g.
# left by a capture undone with `git checkout`, which leaves the new-hash file untracked) would
# enter the build and let a WRONG render false-PASS (compareScreenshots matches ANY candidate).
# check-refs.js fails on >1 dataHash per (test,image,dpr,OS) or an orphaned .js/.png BEFORE the
# build ships them. Structural only, no pixel decode (~0.2s). The PIXEL half — decode all 1542 refs
# and assert each re-hashes to its stored hashOfData — is `check-refs.js --pixels` (~10s), and is
# deliberately NOT here: 10s on every inner-loop build to re-check references that only change on a
# recapture is a bad trade. It runs as the gauntlet's `refs` leg, or by hand via
# `npm run check-refs:pixels` in Fizzygum-tests. (It needs no PNG optimizer either — recompress
# --check-only never picks one; the old note claiming otherwise was wrong.) Same --noSyntaxCheck
# escape hatch / $? check / homepage-notests-sibling guard as the gates above.
if ! $noSyntaxCheck && ! $homepage && ! $notests && [ -d ../Fizzygum-tests ] ; then
  echo "checking SWCanvas reference images for strays/duplicates ..."
  node ../Fizzygum-tests/scripts/check-refs.js --quiet
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: SWCanvas reference check failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... SWCanvas references OK"
fi

touch $SCRATCH_PATH/fizzygum-boot.coffee

if $notests || $homepage ; then
  printf "BUILDFLAG_LOAD_TESTS = false\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
else
  printf "BUILDFLAG_LOAD_TESTS = true\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
fi


# turn the coffeescript file into js in the js directory
echo "compiling boot file..."

cat $SCRATCH_PATH/numberOfSourceBatches.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/globalFunctions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

# extensions -----------------------------------------------------

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/Array-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/Map-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/Object-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/CanvasRenderingContext2D-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/CanvasGradient-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/SWCanvasElement-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/Math-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/Number-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/String-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/HTMLCanvasElement-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

if $includeVideoPlayer ; then
  printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
  cat src/boot/extensions/HTMLVideoElement-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee
  cat src/boot/extensions/Image-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee
fi

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/Date-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

# extensions -----------------------------------------------------

if ! $homepage ; then
  printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
  cat src/boot/numbertimes.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee
fi

printf "\nbuildVersion = 'version of $(date)'" >> $SCRATCH_PATH/fizzygum-boot.coffee

coffee -b -c -o $BUILD_PATH/js/ $SCRATCH_PATH/fizzygum-boot.coffee
echo "... done compiling boot file"

echo "minifying boot file..."

if $homepage ; then
  # There are a few
  #    "if Automator? ...", "if AutomatorRecorder? ...", "if AutomatorPlayer? ..."
  #    "if Automator? and ...", "if AutomatorRecorder? and ...", "if AutomatorPlayer? and ..."
  # sections in the boot code. In the homepage version we don't use any of those three classes,
  # and the code in those sections is completely dead,
  # so we can search/replace those checks with "if (false", so that terser can just eliminate
  # both the checks and the dead-code sections.
  #
  # notice that OSX sed is different from GNU sed, so we need to give the -i '' parameter which means
  # "in-place editing, but don't make a backup file"
  sed -i '' 's/if ((typeof Automator[a-zA-Z]* !== \"undefined\" && Automator[a-zA-Z]* !== null)/if (false/g' $BUILD_PATH/js/fizzygum-boot.js
  sed -i '' 's/if (typeof Automator[a-zA-Z]* !== \"undefined\" && Automator[a-zA-Z]* !== null)/if (false)/g' $BUILD_PATH/js/fizzygum-boot.js
fi

terser --compress --mangle --output $BUILD_PATH/js/fizzygum-boot-min.js -- $BUILD_PATH/js/fizzygum-boot.js
#cp $BUILD_PATH/js/fizzygum-boot.js $BUILD_PATH/js/fizzygum-boot-min.js
echo "... done minifying boot file"

if [ "$?" != "0" ]; then
  tput bel;
  echo "!!!!!!!!!!! error: coffeescript compilation failed!" 1>&2
  exit 1
fi

# Prepend the vendored SWCanvas engine to the boot bundle so window.SWCanvas is
# defined before boot() runs. The minified Fizzygum bundle thus contains the
# SWCanvas engine code (mirroring swcanvas.min.js containing BitmapText); font
# atlases are never embedded — they are loaded at runtime. SWCanvas is always
# bundled and only *used* when the runtime flag (?sw=1) is on.
echo "prepending the deterministic-trig shim + SWCanvas engine + SW3D to the boot bundle..."
# DETERMINISM: install engine-independent sin/cos/tan/atan2/asin/acos (a pure-arithmetic fdlibm
# port — only +,-,*,/ and sqrt, all IEEE-754-exact) over Math.* BEFORE anything renders, so
# SWCanvas's rotate()/arc()/round-joins rasterize bit-identically on every JS engine. Without it
# the platform Math transcendentals differ by ~1 ULP across engines (e.g. Safari's JavaScriptCore
# vs Chrome's V8 disagree on ~10-20% of values), which shifts curved/rotated SWCanvas output a
# pixel or two and breaks the exact SHA-256 reference match (axis-aligned, trig-free content is
# unaffected). Measured: it matches native V8 pixel-for-pixel across the suite, so it is a drop-in.
# See runtime-prelude/deterministic-trig.js and src/macros/MACRO-PATTERNS.md.
# IMPORTANT: swcanvas.min.js ends with a "//# sourceMappingURL=..." line comment and no trailing
# newline; the "\n;\n" separators terminate it and defend against ASI between each concatenated unit.
cat runtime-prelude/deterministic-trig.js > $BUILD_PATH/js/fizzygum-boot-min.js.tmp
printf '\n;try { DetTrig.install(Math); } catch (e) {}\n;\n' >> $BUILD_PATH/js/fizzygum-boot-min.js.tmp
cat $SWCANVAS_VENDOR/swcanvas.min.js >> $BUILD_PATH/js/fizzygum-boot-min.js.tmp
printf '\n;\n' >> $BUILD_PATH/js/fizzygum-boot-min.js.tmp
# SW3D — the software-3D userland engine (examples/sw3d.js), bundled UNMINIFIED
# right after SWCanvas so window.SW3D exists at boot. It reads SWCanvas.Core.*
# lazily (only inside makeEngine at render time), so loading it after SWCanvas
# is sufficient. Ships in ALL builds (symmetric with SWCanvas-always-bundled);
# fizzytiles software-renders through it, replacing the removed twgl WebGL demo.
cat $SWCANVAS_VENDOR/sw3d.js >> $BUILD_PATH/js/fizzygum-boot-min.js.tmp
printf '\n;\n' >> $BUILD_PATH/js/fizzygum-boot-min.js.tmp
cat $BUILD_PATH/js/fizzygum-boot-min.js >> $BUILD_PATH/js/fizzygum-boot-min.js.tmp
mv $BUILD_PATH/js/fizzygum-boot-min.js.tmp $BUILD_PATH/js/fizzygum-boot-min.js
echo "... done prepending deterministic-trig + SWCanvas + SW3D"

# Copy the vendored SWCanvas font assets (metrics + positioning bundles, and
# the wrapped atlas .js if vendored) so the SWCanvas text backend can load them
# at runtime over file://. These are font DATA, never embedded in the bundle,
# and only fetched when ?sw=1 is on. Populated by scripts/vendor-swcanvas-fonts.sh.
if [ -d font-assets ]; then
  echo "copying SWCanvas font assets..."
  mkdir -p $BUILD_PATH/font-assets
  cp -R font-assets/* $BUILD_PATH/font-assets/
  echo "... done copying SWCanvas font assets"
fi

# copy the html files
cp src/index.html $BUILD_PATH/

# copy the interesting js files from the submodules
cp auxiliary\ files/FileSaver/FileSaver.min.js $BUILD_PATH/js/libs/
cp auxiliary\ files/JSZip/jszip.min.js $BUILD_PATH/js/libs/
cp auxiliary\ files/CoffeeScript/fizzygum-coffeescript-min.js $BUILD_PATH/js/libs/
# (twgl-full.js removed: fizzytiles now software-renders through SW3D, not WebGL)

# code that can be loaded after a pre-compiled world has started
coffee -b -c -o $BUILD_PATH/js/src/ src/boot/dependencies-finding.coffee
terser --compress --output $BUILD_PATH/js/src/dependencies-finding-min.js -- $BUILD_PATH/js/src/dependencies-finding.js

coffee -b -c -o $BUILD_PATH/js/src/ src/boot/loading-and-compiling-coffeescript-sources.coffee
terser --compress --output $BUILD_PATH/js/src/loading-and-compiling-coffeescript-sources-min.js -- $BUILD_PATH/js/src/loading-and-compiling-coffeescript-sources.js
#cp $BUILD_PATH/js/src/loading-and-compiling-coffeescript-sources.js $BUILD_PATH/js/src/loading-and-compiling-coffeescript-sources-min.js

coffee -b -c -o $BUILD_PATH/js/src/ src/boot/logging-div.coffee
terser --compress --output $BUILD_PATH/js/src/logging-div-min.js -- $BUILD_PATH/js/src/logging-div.js

echo "copying pre-compiled file"
cp auxiliary\ files/pre-compiled.js $BUILD_PATH/js/pre-compiled.js
echo "... done"

# copy aux icon files
echo "copying icon files..."
cp auxiliary\ files/additional-icons/*.png $BUILD_PATH/icons/
cp auxiliary\ files/additional-icons/spinner.svg $BUILD_PATH/icons/

if $includeVideos ; then
  cp ../Fizzygum-videos-public/* $BUILD_PATH/videos/
fi

echo "... done copying icon files"


if ! $notests && ! $homepage && ! $keepTestsDirectoryAsIs ; then

  # read -p "Got in the notests area. Press any key to continue... " -n1 -s

  # the tests files are copied from a directory
  # where they are organised in a clean structure
  # so we copy them with their structure first...
  mkdir $BUILD_PATH/js/tests/assets
  echo "copying all tests (this could take a minute)..."
  cp -r ../Fizzygum-tests/tests/* $BUILD_PATH/js/tests/assets &

  # ------  spinning wheel  -------
  pid=$! # Process Id of the previous running command
  spin='-\|/'
  i=0
  TOTAL_NUMBER_OF_FILES=$(ls -afq ../Fizzygum-tests/tests/ | wc -l)

  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    CURRENT_NUMBER_OF_FILES=$(ls -afq $BUILD_PATH/js/tests/assets | wc -l)
    printf "\r${spin:$i:1} %s / %s" $CURRENT_NUMBER_OF_FILES $TOTAL_NUMBER_OF_FILES
    sleep 1
  done
  # ------  END OF spinning wheel  -------


  echo "... done copying all tests"

  # ...however, the system actually needs the "body"
  # of the test (the one file with the commands)
  # all into one directory.
  # So we go through what we just copied and pick the
  # test body files and move them all into one
  # directory
  echo "moving all tests body into the same directory..."
  # we don't seem to need the escaping in Windows Subsystem for Linux, while in OSX we needed \{\}
  # The test-BODY files are the SystemTest_<name>.js metadata + ..._automationCommands.js;
  # they are exactly the SystemTest_*.js files WITHOUT a "-dataHash" in the name. The
  # reference-image files DO carry "-dataHash" and must be left under js/tests/assets/ for
  # the next step to flatten there.
  # NOTE: this used to match filenames ending in six NON-digits, which mis-filed any
  # SWCanvas reference whose 64-hex SHA-256 ended in six hex letters (~0.28% of them) as a
  # "body" file — moving it out of assets/ so the loader 404'd and the test falsely failed.
  # The "-dataHash" discriminator is hash-format-agnostic and leaves the native set unchanged.
  find $BUILD_PATH/js/tests -iname 'SystemTest_*.js' ! -iname '*-dataHash*' -exec mv {} $BUILD_PATH/js/tests \;
  echo "...done"

  # also all the assets are lumped-in into another directory
  # this is because the path would otherwise be too long to be
  # accessed by browsers (both Edge and Chrome in Nov 2018) in
  # Windows.
  echo "moving all tests assets into the same directory..."
  # we don't seem to need the escaping in Windows Subsystem for Linux, while in OSX we needed \{\}
  find $BUILD_PATH/js/tests/assets -iname 'SystemTest_*.js' -exec mv {} $BUILD_PATH/js/tests/assets \;
  echo "...done"
fi


echo "cleanup unneeded files"
rm -rdf $SCRATCH_PATH
echo "...done"

if $homepage ; then
  rm $BUILD_PATH/worldWithSystemTestHarness.html
  rm $BUILD_PATH/icons/doubleClickLeft.png
  rm $BUILD_PATH/icons/middleButtonPressed.png
  rm $BUILD_PATH/icons/scrollUp.png
  rm $BUILD_PATH/icons/doubleClickRight.png
  rm $BUILD_PATH/icons/rightButtonPressed.png
  rm $BUILD_PATH/icons/xPointerImage.png
  rm $BUILD_PATH/icons/leftButtonPressed.png
  rm $BUILD_PATH/icons/scrollDown.png
  rm $BUILD_PATH/js/fizzygum-boot.js
  
  ls -d -1 $BUILD_PATH/js/coffeescript-sources/* | grep -v /sources_batch | grep -v /Mixin_coffeSource | grep -v /Class_coffeSource | xargs rm -f
  
  echo "generating the pre-compiled file via the browser. this might take a few seconds..."
  . ./buildSystem/generate-pre-compiled-file-via-browser.sh

  if ! $keepTestsDirectoryAsIs ; then
    rm -rdf $BUILD_PATH/js/tests
  fi

  rm $BUILD_PATH/js/libs/FileSaver.min.js
  rm $BUILD_PATH/js/libs/jszip.min.js

  rm $BUILD_PATH/js/src/dependencies-finding.js
  rm $BUILD_PATH/js/src/loading-and-compiling-coffeescript-sources.js
  rm $BUILD_PATH/js/src/logging-div.js


  # There are many
  #    "if Automator? ...", "if AutomatorRecorder? ...", "if AutomatorPlayer? ..."
  #    "if Automator? and ...", "if AutomatorRecorder? and ...", "if AutomatorPlayer? and ..."
  # sections in the code. In the homepage version we don't use any of those three classes,
  # and the code in those sections is completely dead,
  # so we can search/replace those checks with "if (false", so that terser can just eliminate
  # both the checks and the dead-code sections.
  # At the moment this was put in place, this line saves around 12kBs
  # (11990 bytes to be precise) in the final build.
  #
  # notice that OSX sed is different from GNU sed, so we need to give the -i '' parameter which means
  # "in-place editing, but don't make a backup file"
  sed -i '' 's/if ((typeof Automator[a-zA-Z]* !== \"undefined\" && Automator[a-zA-Z]* !== null)/if (false/g' $BUILD_PATH/js/pre-compiled.js
  sed -i '' 's/if (typeof Automator[a-zA-Z]* !== \"undefined\" && Automator[a-zA-Z]* !== null)/if (false)/g' $BUILD_PATH/js/pre-compiled.js

  terser --compress --mangle --output $BUILD_PATH/js/pre-compiled-min.js -- $BUILD_PATH/js/pre-compiled.js
  mv $BUILD_PATH/js/pre-compiled.js $BUILD_PATH/js/pre-compiled-max.js
  mv $BUILD_PATH/js/pre-compiled-min.js $BUILD_PATH/js/pre-compiled.js
fi

# BUILD STAMP: touched ONLY here, at the very end of a successful build, so its mtime == build-completion
# time. The headless test runners refuse to run if any source .coffee is newer than this stamp (or it is
# missing) -- so a build that didn't run / failed / ran from the wrong cwd can never be tested as if fresh.
# See Fizzygum-tests/scripts/lib/assert-build-fresh.js.
touch "$BUILD_PATH/.build-stamp"

# for OSX: say build done
tput bel
echo done!!!!!!!!!!!!
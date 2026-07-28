#!/bin/bash

# Examples:
#   ./build_it_please --homepage
#     leaves out all tests and removes experimental parts of the code
#   ./build_it_please --notests
#     removes tests, leaves in experimental parts of the code
#   ./build_it_please.sh --includeVideoPlayer --includeVideos
#     also includes the video player and the videos
#   ./build_it_please.sh --includeVideoPlayer --includeVideos; cp -R /Volumes/Seagate\ 5tb/Fizzygum-videos-private ../Fizzygum-builds/latest/videos
#     as before, and copies the private videos
#   ./build_it_please.sh --includeVideoPlayer --includeVideos --keepPreviousPrivateVideos
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
# The 3D-core artifacts are part of the presence check too: a vendor tree that
# predates that dist target would silently fail the native bundle's assembly, so
# treat it as not-populated and re-fetch.
if [ ! -f "$SWCANVAS_VENDOR/swcanvas.min.js" ] || [ ! -f "$SWCANVAS_VENDOR/sw3d.js" ] || \
   [ ! -f "$SWCANVAS_VENDOR/swcanvas-3d-core.min.js" ] || [ ! -f "$SWCANVAS_VENDOR/sw3d.min.js" ] || \
   [ ! -f "$SWCANVAS_VENDOR/VERSION" ]; then
  echo "SWCanvas bundle (incl. sw3d.js + the 3D-core target) missing — fetching from $SWCANVAS_PIN ..."
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


# ---- the test-serving link: the ONLY two operations allowed on $BUILD_PATH/js/tests ----
#
# $BUILD_PATH/js/tests is a relative SYMLINK to the sibling tests repo's tests/ directory
# (created below), so the built world serves the tests where they actually live — no copy.
# That makes the path DANGEROUS to spell casually: a trailing-slash `rm -rf $BUILD_PATH/js/tests/`
# or a `find -L` over the build tree DELETES THE REAL TESTS through the link (measured), while
# the slash-less form only removes the link. So this script contains exactly two operations on
# that path, and nothing else may touch it:
#   - remove_tests_link below;
#   - the single `ln -sfn` that creates it (-n so a re-run REPLACES the link instead of writing
#     a stray link INSIDE the target).
# Recursive / `find` operations on $BUILD_PATH/js/tests are banned in any spelling.
#
# The path only ever holds a SYMLINK (a tests-stripped build creates nothing there at all), so
# this is one guarded `rm -f` — which refuses a directory outright and cannot recurse. No
# spelling here, even a wrong one, can reach the real tests through the link.
remove_tests_link() {
  if [ -L "$BUILD_PATH/js/tests" ]; then
    rm -f "$BUILD_PATH/js/tests"
  fi
  return 0
}

# ---------------------------------------- cleanup -------------------------------------------

rm -rf $BUILD_PATH/*.html
rm -rf $BUILD_PATH/icons

# Drop the link BEFORE wiping js/ — `rm -rf` on a directory CONTAINING a symlink removes the
# link and never descends through it (verified), but removing it first means the recursive
# delete never meets a symlink at all.
remove_tests_link
# remove the whole $BUILD_PATH/js directory
rm -rf $BUILD_PATH/js

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

# ---- serve the tests through a link instead of copying them in ----
# $BUILD_PATH/js/tests -> the sibling tests repo's tests/ directory. RELATIVE (so the whole
# umbrella can be moved/renamed), and from $BUILD_PATH/js that is three levels up to
# Fizzygum-all/ then down into Fizzygum-tests/tests. Everything loads over file:// by
# <script> injection, which follows the link happily on both engines the suite drives.
# A --homepage / --notests build ships NO js/tests entry at all (see remove_tests_link above).
if $homepage || $notests ; then
  # No js/tests entry AT ALL in a tests-stripped tree. A --homepage build's pre-compile pass
  # boots ?generatePreCompiled, and that boot loads no test machinery whatsoever (the load
  # condition is plain BUILDFLAG_LOAD_TESTS — see globalFunctions.coffee), so it needs nothing here.
  remove_tests_link
else
  ln -sfn ../../../Fizzygum-tests/tests $BUILD_PATH/js/tests
  # The two manifests the booting world loads (js/tests/testsManifest.js +
  # testsAssetsManifest.js) are DERIVED from the tests/ tree and gitignored, so generate them
  # here — that keeps "build, then open index.html in a browser" working with no extra step.
  # Every headless runner and capture script ALSO regenerates them at startup, which is what
  # makes a stale manifest impossible: a test added after this build is picked up with no
  # rebuild. (This is deliberately NOT gated on --noSyntaxCheck; it is not a check.)
  if [ -d ../Fizzygum-tests ] && command -v node &> /dev/null ; then
    node ../Fizzygum-tests/scripts/generate-tests-manifests.js --quiet || exit 1
  fi
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
cat src/boot/extensions/Object-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/CanvasRenderingContext2D-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

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

# ---- the two boot bundles ------------------------------------------------------------------
#
# The rendering backend is a BUILD-TIME property of the entry page, so the SAME minified boot JS
# is fronted by two different engine preludes and each page (build.py's ENTRY_PAGES) loads the
# one carrying the engine it can actually use. That way no artifact ships an engine it will never
# call, and there is no runtime switch to get wrong. Both flavours come out of the ONE terser
# pass above — the split is pure concatenation, which is why a second bundle costs ~1s.
#
#   fizzygum-boot-sw-min.js      det-trig + the FULL SWCanvas engine + SW3D + boot
#                                -> worldWithSystemTestHarness.html, index-sw.html
#   fizzygum-boot-native-min.js  the SWCanvas 3D CORE + SW3D + boot
#                                -> index.html
#
# window.SWCanvas must exist before boot() runs, hence the prepend rather than a second <script>.
# IMPORTANT: the minified vendor files end with a "//# sourceMappingURL=..." line comment and no
# trailing newline; the "\n;\n" separators terminate it and defend against ASI between each unit.
BOOT_MIN=$BUILD_PATH/js/fizzygum-boot-min.js

if ! $homepage ; then
  echo "assembling the SW boot bundle (deterministic-trig + SWCanvas + SW3D + boot)..."
  # DETERMINISM: install engine-independent sin/cos/tan/atan2/asin/acos (a pure-arithmetic fdlibm
  # port — only +,-,*,/ and sqrt, all IEEE-754-exact) over Math.* BEFORE anything renders, so
  # SWCanvas's rotate()/arc()/round-joins rasterize bit-identically on every JS engine. Without it
  # the platform Math transcendentals differ by ~1 ULP across engines (e.g. Safari's JavaScriptCore
  # vs Chrome's V8 disagree on ~10-20% of values), which shifts curved/rotated SWCanvas output a
  # pixel or two and breaks the exact SHA-256 reference match (axis-aligned, trig-free content is
  # unaffected). Measured: it matches native V8 pixel-for-pixel across the suite, so it is a drop-in.
  # It rides ONLY on this bundle: it exists for SWCanvas's cross-engine byte-exactness, and the
  # native page's pixels are not reference-matched.
  # See runtime-prelude/deterministic-trig.js and src/macros/MACRO-PATTERNS.md.
  cat runtime-prelude/deterministic-trig.js > $BUILD_PATH/js/fizzygum-boot-sw-min.js
  printf '\n;try { DetTrig.install(Math); } catch (e) {}\n;\n' >> $BUILD_PATH/js/fizzygum-boot-sw-min.js
  cat $SWCANVAS_VENDOR/swcanvas.min.js >> $BUILD_PATH/js/fizzygum-boot-sw-min.js
  printf '\n;\n' >> $BUILD_PATH/js/fizzygum-boot-sw-min.js
  # SW3D — the software-3D userland engine (examples/sw3d.js), bundled UNMINIFIED right after
  # SWCanvas so window.SW3D exists at boot. It reads SWCanvas.Core.* lazily (only inside
  # makeEngine at render time), so loading it after SWCanvas is sufficient.
  cat $SWCANVAS_VENDOR/sw3d.js >> $BUILD_PATH/js/fizzygum-boot-sw-min.js
  printf '\n;\n' >> $BUILD_PATH/js/fizzygum-boot-sw-min.js
  cat $BOOT_MIN >> $BUILD_PATH/js/fizzygum-boot-sw-min.js
  echo "... done assembling the SW boot bundle"
fi

# The native page paints its 2D through the platform canvas, but fizzytiles still software-renders
# its 3D — so it needs SW3D, which needs a sliver of SWCanvas (Surface + DepthBuffer + Texture3D +
# Triangle3DOps). That sliver is SWCanvas's own subtractive dist target, ~14 KB instead of ~263 KB,
# and it is pixel-identical to the full engine on the 3D path (SWCanvas's examples/3d-core-node.js
# witness). No det-trig here (see above); SW3D is minified since nothing debugs through it here.
echo "assembling the native boot bundle (SWCanvas 3D core + SW3D + boot)..."
cat $SWCANVAS_VENDOR/swcanvas-3d-core.min.js > $BUILD_PATH/js/fizzygum-boot-native-min.js
printf '\n;\n' >> $BUILD_PATH/js/fizzygum-boot-native-min.js
cat $SWCANVAS_VENDOR/sw3d.min.js >> $BUILD_PATH/js/fizzygum-boot-native-min.js
printf '\n;\n' >> $BUILD_PATH/js/fizzygum-boot-native-min.js
cat $BOOT_MIN >> $BUILD_PATH/js/fizzygum-boot-native-min.js
echo "... done assembling the native boot bundle"

# The bare minified boot JS is an intermediate, never an entry page's bundle.
rm $BOOT_MIN

# Copy the vendored SWCanvas font assets (metrics + positioning bundles, and the wrapped atlas .js
# if vendored) so the SWCanvas text backend can load them at runtime over file://. These are font
# DATA, never embedded in a bundle. Only the SW pages can use them, so a --homepage tree (native
# only) does not carry them — that is ~90 MB not deployed.
# Populated by scripts/vendor-swcanvas-fonts.sh.
if [ -d font-assets ] && ! $homepage ; then
  echo "copying SWCanvas font assets..."
  mkdir -p $BUILD_PATH/font-assets
  cp -R font-assets/* $BUILD_PATH/font-assets/
  echo "... done copying SWCanvas font assets"
fi

# (the entry pages themselves are written by build.py from src/index.html — see its ENTRY_PAGES)

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


echo "cleanup unneeded files"
rm -rdf $SCRATCH_PATH
echo "...done"

if $homepage ; then
  # $BUILD_PATH is shared across build flavours and font-assets survives the cleanup section
  # (unlike js/, icons/ and *.html, which are wiped), so a homepage build following a dev build
  # would otherwise inherit ~90 MB of SWCanvas font data that no page here can load.
  rm -rf $BUILD_PATH/font-assets
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
  
  # Generate the pre-compiled image. It MUST happen here: after the per-class source files are
  # pruned (the generating boot only needs sources_batch_* + Class/Mixin, kept above) and while
  # js/pre-compiled.js is still the `window.preCompiled = false` stub — compile-at-boot is
  # exactly the mode that builds the image. The driver lives in the tests repo because Node
  # resolves require('puppeteer') from the SCRIPT's directory; the explicit cd in a subshell is
  # what keeps that true regardless of this build's cwd.
  echo "generating the pre-compiled file headlessly. this might take a few seconds..."
  ( cd ../Fizzygum-tests && node scripts/generate-pre-compiled-headless.js ) || {
    echo "!!!!!!!!!!! error: pre-compiled generation failed" 1>&2
    exit 1
  }

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
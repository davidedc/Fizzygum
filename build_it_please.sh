#!/bin/bash

# A BUILD FLAVOUR IS A PROFILE, NOT A FLAG (arc 5). buildSystem/profiles/<name>.json declares three
# facts -- which parts ship, which code form, which entry pages -- and buildSystem/buildProfile.py
# DERIVES from them everything this script used to decide by asking "is this the homepage?": the
# tests link, BUILDFLAG_LOAD_TESTS, which build gates run, the boot-bundle prelude, whether the
# SWCanvas bundle and its ~90 MB of font assets are built, and whether the pre-compile driver runs.
# The --homepage and --notests flags are GONE; so is the per-flavour list of files to delete again at
# the end of a build. `--profile homepage` and `--profile dev-notests` replace them.
#
# Examples:
#   ./build_it_please.sh
#     the dev profile (the default): every part, compiled in the browser, all three entry pages
#   ./build_it_please.sh --profile homepage
#     the production artifact: pre-compiled, native-only, no test machinery
#   ./build_it_please.sh --profile dev-notests
#     the dev world with the test machinery left out
#   ./build_it_please.sh --includeVideoPlayer --includeVideos
#     also includes the video player and the videos
#   ./build_it_please.sh --includeVideoPlayer --includeVideos; cp -R /Volumes/Seagate\ 5tb/Fizzygum-videos-private ../Fizzygum-builds/latest/videos
#     as before, and copies the private videos
#   ./build_it_please.sh --includeVideoPlayer --includeVideos --keepPreviousPrivateVideos
#     as before but instead of copying the private videos, keep the existing ones (as these can take a long time to copy otherwise)

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

# we'll put the switches in these variables. NOTE what is NOT here: the build FLAVOUR. That is
# --profile, parsed by buildSystem/buildProfile.py (see the profile block further down) so that this
# script, build_and_smoke.sh and build.py cannot disagree about which profile is being built.
includeVideoPlayer=false
includeVideos=false
keepPreviousPrivateVideos=false
# --noSyntaxCheck skips the build-time CoffeeScript syntax gate (default: gate runs).
noSyntaxCheck=false

# see https://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash
while test $# -gt 0; do
  case "$1" in
    --profile)
      # The NAME is buildProfile.py's business (it re-reads "${args[@]}"); here we only step over
      # both tokens so the rest of the loop sees the next real flag.
      if [ -z "$2" ]; then
        echo "build_it_please.sh: --profile needs a name, e.g. --profile homepage" 1>&2
        exit 1
      fi
      shift 2
      ;;
    --profile=*)
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
    --noSyntaxCheck)
      # consumed here only; it is ALSO a no-op in build.py, so the forwarded
      # "${args[@]}" (which still contains it) does not trip build.py's argparse.
      noSyntaxCheck='true'
      shift
      ;;
    *)
      # Unknown arguments used to `break` out of the loop and be forwarded silently, so a typo (or
      # the retired --homepage / --notests) reached build.py's argparse -- or nothing at all -- and
      # the build made something other than what was asked for. Say so instead.
      echo "build_it_please.sh: unknown argument '$1'." 1>&2
      echo "  A build flavour is a PROFILE: --profile <name>, one of $(ls buildSystem/profiles/*.json 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.json$//' | tr '\n' ' ')" 1>&2
      echo "  (--homepage and --notests were retired: use --profile homepage / --profile dev-notests.)" 1>&2
      echo "  Other options: --includeVideoPlayer --includeVideos --keepPreviousPrivateVideos --noSyntaxCheck" 1>&2
      exit 1
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

# ---- THE FLAVOUR: resolve the profile ------------------------------------------------------------
# buildSystem/buildProfile.py loads buildSystem/profiles/<name>.json (default: dev) and hands back
# the derived facts this script needs, as shell assignments:
#   PROFILE_NAME PROFILE_FORM PROFILE_SHIPS_TESTS PROFILE_SHIPS_SWCANVAS_ENTRY PROFILE_BOOT_PRELUDE
# It gets the WHOLE arg list because it owns --profile parsing for every caller.
# ⚠ SUBSTITUTE FIRST, THEN eval. `eval "$(cmd)"` reports the EVAL's exit code, not the command's, so
# a profile that failed to load would leave every PROFILE_* unset and this script would cheerfully
# build a nameless flavour -- the same masked-exit-code class as the build.py call below, which went
# unchecked for years (found 2026-07-30).
# NO __pycache__ IN THE SOURCE TREE. build.py now IMPORTS buildProfile.py, so CPython would write
# cached bytecode into buildSystem/ -- a generated artifact inside a source tree, which is the thing
# this whole program is about not doing. Exported (not just -B on the calls below) because the build
# reaches python3 by four paths: this script twice, and three JS gates that shell out to
# `build.py --list-shippable`; -B on our own two calls left the gates writing it anyway (measured).
export PYTHONDONTWRITEBYTECODE=1
PROFILE_VARS=$(python3 -B ./buildSystem/buildProfile.py --shell "${args[@]}")
if [ "$?" != "0" ]; then
  tput bel
  echo "!!!!!!!!!!! error: could not read the build profile -- aborting build." 1>&2
  exit 1
fi
eval "$PROFILE_VARS"
echo "profile: $PROFILE_NAME — form $PROFILE_FORM, tests $PROFILE_SHIPS_TESTS, SWCanvas entry $PROFILE_SHIPS_SWCANVAS_ENTRY"

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
# A build whose profile does not ship the harness part ships NO js/tests entry at all (see
# remove_tests_link above).
if ! $PROFILE_SHIPS_TESTS ; then
  # No js/tests entry AT ALL in a tests-stripped tree. A precompiled profile's pre-compile pass
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
# The flavour reaches build.py as --profile <name> inside "${args[@]}" (it resolves the profile
# itself, through the same buildSystem/buildProfile.py this script read above), and that decides
# which parts' sources it wraps, which assets and vendor payloads it writes, and which entry pages
# it generates.
# ⚠ CHECK $? — this script has no `set -e`, and for years this call had NO check at all, so the
# single most important step of the build (wrapping every source into the SourceVault batches,
# writing the parts manifest, generating the entry pages, copying each part's assets) could fail
# outright and the build still printed "done!!!" and exited 0. Found 2026-07-30 by planting a
# deliberately missing part asset: build.py correctly printed its ERROR and exited 1, and the build
# reported OK. Same masked-failure class as the umbrella-directory check at the top of this file.
python3 -B ./buildSystem/build.py "${args[@]}"
if [ "$?" != "0" ]; then
  tput bel
  echo "!!!!!!!!!!! error: buildSystem/build.py failed -- aborting build." 1>&2
  exit 1
fi

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
# if the sibling Fizzygum-tests repo is absent, e.g. a production build; same --noSyntaxCheck
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
# $? check as the gates above; scans src/ only, so it runs for every build flavour (incl. production).
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

# --- build-time ARGUMENT-HOLE gate (baseline-ratcheted) --------------------------------
# Enforces the HOLE TEST (R3 of docs/architecture/constructor-and-parameter-conventions.md): if any
# call site must pass `undefined` to reach a later argument, the parameter list is wrong. Shares ONE
# parser with buildSystem/census-call-arity.js (the advisory view behind `fg critique`), so the gate
# and the census can never disagree about what a hole is. This is the HONEST count: the
# `positional-hole` stink above matches only two `undefined`s adjacent on one line, and reading its 0
# as "clean" is how the conformance arc came to be archived complete and re-opened the same day with
# ~50 holes standing. Baseline inline in the check; FAILS on a rise, prints a tighten-me note on a
# drop. Scans src/ only (the tests repo's metadata PROSE would false-positive a build). Same
# --noSyntaxCheck escape hatch + explicit $? abort as the gates above.
if ! $noSyntaxCheck ; then
  echo "checking for argument holes (the R3 hole test, ratcheted) ..."
  node ./buildSystem/check-argument-holes.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: argument-hole gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... argument-hole check OK"
fi

# --- build-time MENU-ACTION WIRING gate -----------------------------------------------
# A menu item is dispatched through ButtonWdgt's FIXED four-slot convention
# (`@target[@action].call @target, menuItem, panelTarget, arg1, arg2`), and nothing at the call site
# says so -- `menu.addMenuItem "label", target, "verb"` names none of the four arguments `verb` will
# receive. Three failure modes follow, all of which were LIVE when this gate was written: a FUNCTION
# LITERAL in the action slot (dispatch is `@target[@action]`, so it throws when clicked -- three
# SliderWdgt items sat broken behind ButtonWdgt's runtime tripwire, because a runtime tripwire needs
# someone to CLICK and the suite never clicks a slider's "floor..."); a STRING where the options
# object goes; and a signature PADDED with unread slots to reach the one it wants, which puts widgets
# into parameters whose names promise otherwise and forces every other caller to punch `undefined`
# through. Rules 1-2 are sound negatives and HARD; rule 3 is a ratchet at 0 -- pad if you must, but
# NAME the slot `ignored`/`unused`. Same --noSyntaxCheck escape hatch + explicit $? abort as above.
if ! $noSyntaxCheck ; then
  echo "checking menu-action wiring ..."
  node ./buildSystem/check-menu-actions.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: menu-action gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... menu-action check OK"
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
# Four cheap line-scanner lints, each with the same --noSyntaxCheck escape hatch + explicit $? abort as
# the gates above; all scan src/ only, so they run for every build flavour (incl. production):
#   * check-trailing-whitespace.js — no trailing whitespace after content on a line.
#   * check-scheduled-checks.js     — no OVERDUE `# CHECK AFTER <date>` reminder (a build-dated time bomb).
#   * check-stringified-scripts.js  — no `new ScriptWdgt """..."""` stringified-code literal in core.
#   * check-region-markers.js       — the `»>>` region-exclusion mechanism, ratcheted per kind to zero.
#   * check-source-vault.js         — the retired `window.<Name>_coffeSource` source delivery, at zero.
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

  echo "checking region markers ..."
  node ./buildSystem/check-region-markers.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: region-markers gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... region-markers check OK"

  echo "checking the retired source-delivery patterns stay dead ..."
  node ./buildSystem/check-source-vault.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: source-vault gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... source-vault check OK"

  echo "checking whole-file exclusion markers ..."
  node ./buildSystem/check-whole-file-markers.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: whole-file-markers gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... whole-file-markers check OK"

  # The partition's one hard discipline: core must not name a part-owned class unguarded, or the
  # artifact that lacks the part throws when the user clicks. NOT derivable from the boot dependency
  # scanner (it cannot see `new X` in a method body) -- see the gate's header.
  echo "checking core->part edges are guarded ..."
  node ./buildSystem/check-part-edges.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: part-edges gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... part-edges check OK"
fi

# --- build-time CONSTRUCTOR-BUILD gate ------------------------------------------------
# Enforces the "all constructors settle" end-state (Topic 4 part 2): a `constructor:` body must NOT build
# its own children inline (@add / @addNoSettle / @addMany / @_addNoSettle / … on `this`). Child-building
# belongs in the _buildAndConnectChildrenNoSettle core, reached from the constructor via the settling
# wrapper @_buildAndConnectChildren() (or @_buildScrollFrame() for the ScrollPanelWdgt base) -- so the
# settle-tier FLUSHES a top-level `new X()` and AUTO-DEFERS one built in-flush (inside a callback). Genuine
# exceptions carry a per-constructor `# constructor-build-exempt: <reason>` marker (no central allowlist).
# (buildSystem/check-constructors-build.js -- same --noSyntaxCheck escape hatch + explicit $? abort as the
# gates above; scans src/ only, so it runs for every build flavour incl. production.)
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
# sibling Fizzygum-tests repo (e.g. a production build), like the dead-method gate. (buildSystem/
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
# explicit $? abort as the gates above; scans src/ only, so it runs for every build flavour incl. production.)
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

# --- build-time WIDGET-CONFORMANCE ratchet --------------------------------------
# The ratcheted half of buildSystem/census-widget-conformance.js, which re-derives the mechanical facets of
# docs/measurements/widget-practices-survey-2026-08-14.md. Only TWO facets are objective enough to gate --
# instance fields written but never DECLARED at class level (they are invisible to duplication,
# serialization and the inspector until declared), and classes still spelling out the `_reLayout` prologue
# instead of taking Widget._reLayoutWithOwnContents. Everything else the census reports is a heuristic and
# stays advisory: run `node ./buildSystem/census-widget-conformance.js` (or --json) to see it all.
# ⚠ BOTH BASELINES ARE FLOORS, NOT ZEROS, and each remaining occurrence is a stated decision named in the
# script. Green means "nothing got worse", never "nothing is left".
# (same --noSyntaxCheck escape hatch + explicit $? abort as the gates above; scans src/ only, so it runs
# for every build flavour incl. production.)
if ! $noSyntaxCheck ; then
  echo "checking widget-practices conformance ratchets ..."
  node ./buildSystem/census-widget-conformance.js --gate
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: widget-conformance ratchet failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... widget-conformance check OK"
fi

# --- build-time RELAYOUT-REPAINTS gate (TOMBSTONE) ------------------------------------
# Static sibling to the runtime paint-truthfulness capstone (Fizzygum-tests/scripts/run-paint-audit.js),
# which is unchanged. [INV-1] -- a `_reLayoutSelf` that suppresses change-tracking MUST issue a covering
# `_fullChanged()` after its last re-enable (born from the 2026-07 D2 edit/view-toggle ghosts,
# docs/archive/layout-regressions-2026-07-icons-plots-editghosts-plan.md) -- is now STRUCTURAL: bulk child
# positioning coalesces through `Widget._repaintAsOneUnit fn`, whose `finally` both restores
# `world._damageSuppressionDepth` and issues the owner's covering repaint, so neither half can be forgotten
# or lost to an exception. What is left to lint is only that nobody resurrects the retired imperative
# spelling: `disableTrackChanges` / `maybeEnableTrackChanges` must not reappear. Like check-region-markers.js
# and check-whole-file-markers.js, the gate slot stays occupied so the retirement cannot silently un-happen.
# (buildSystem/check-relayout-repaints.js -- same --noSyntaxCheck escape hatch + explicit $? abort as the
# gates above; scans src/ plus the harness src, which compiles into the same world, so it runs for every
# build flavour incl. production.)
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
# gates above; scans src/ only, so it runs for every build flavour incl. production.)
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

# --- plane-discipline gate (paint-time scroll model) --------------------------------
# Three statically-checkable rules of the stored-offset model (viewports-and-planes.md):
# A) scrollOffsetX/Y written ONLY through the _writeScrollOffset funnel (a bare write skips
#    the geometryVersion bump -- the measured hit-invisible-scrolled-row class); B) a count
# ratchet over lines mixing two receivers' POSITIONAL geometry with no mapping call (the
# silent dormant-at-offset-0 class -- new lines must be classified, drops ratchet down);
# C) a positional pointer handler on a scroll-translation provider must re-derive its pos
#    (escalateEvent forwards descendant-plane args verbatim). (buildSystem/
# check-plane-discipline.js -- same --noSyntaxCheck escape hatch as the gates above.)
if ! $noSyntaxCheck ; then
  echo "checking plane discipline (offset funnel / positional mixing / escalation boundary) ..."
  node ./buildSystem/check-plane-discipline.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: plane-discipline gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... plane-discipline check OK"
fi

# --- build-time test-.js syntax gate (only when tests are part of this build) ---------
# Each SystemTest's _automationCommands.js carries its macro inside a backtick-delimited JS
# template literal; a stray backtick silently corrupts the file so the test never loads (with
# corrupted/missing screenshots, not an obvious error). This runs `node --check` over every
# tests/*.js (see ../Fizzygum-tests/scripts/check-tests-syntax.js) to catch that — and any JS
# syntax error — BEFORE the build copies them in. Same --noSyntaxCheck escape hatch and explicit
# $? check as the CoffeeScript gate above; skipped when the profile ships no test machinery, or
# when the sibling Fizzygum-tests repo is absent.
if ! $noSyntaxCheck && $PROFILE_SHIPS_TESTS && [ -d ../Fizzygum-tests ] ; then
  echo "checking JS syntax of all shipped test sources ..."
  node ../Fizzygum-tests/scripts/check-tests-syntax.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: test .js syntax check failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... test .js syntax OK"
fi

# --- build-time macro EVAL-DISCIPLINE gate (only when tests are part of this build) ------------
# A macro body IS CoffeeScript, so a call written as a string for `world.evaluateString` throws
# away its bindings, this syntax gate, and any rename sweep's chance of finding it. Worse, it is
# not a plain call: Widget.evaluateString ends in `_reLayoutSelf()` + `_changed()`, so the world
# form DAMAGES THE WHOLE WORLD — a fixture step written that way forces a full repaint that masks
# a missing self-invalidation in whatever it just drove, which is exactly the defect class the
# suite's incremental damage-rect screenshots exist to catch. The gate holds two rules over the
# macro sources ONLY (see ../Fizzygum-tests/scripts/check-macro-eval-discipline.js): `@evaluateString`
# is always wrong (that is MacroToolkit's own, a different method), and `world.evaluateString` is
# allowed only where the test DECLARES the eval as its subject via its `evaluateString` tag —
# a declaration rather than a count, so there is no baseline number to rot. Its own acceptance
# corpus is scripts/check-macro-eval-discipline-selftest.js, in `npm run selftest`. Pure text,
# milliseconds. Same --noSyntaxCheck escape hatch / $? check / ships-tests + sibling guard as above.
if ! $noSyntaxCheck && $PROFILE_SHIPS_TESTS && [ -d ../Fizzygum-tests ] ; then
  echo "checking macro sources for eval discipline ..."
  node ../Fizzygum-tests/scripts/check-macro-eval-discipline.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: macro eval-discipline check failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... macro eval discipline OK"
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
# escape hatch / $? check / ships-tests + sibling guard as the gates above.
if ! $noSyntaxCheck && $PROFILE_SHIPS_TESTS && [ -d ../Fizzygum-tests ] ; then
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

# The one runtime flag that says "this build has test machinery in it" -- which is precisely
# whether the harness part ships. It used to be its own pair of flavour flags, i.e. the same fact
# spelled twice, with nothing making the two agree.
if $PROFILE_SHIPS_TESTS ; then
  printf "BUILDFLAG_LOAD_TESTS = true\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
else
  printf "BUILDFLAG_LOAD_TESTS = false\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
fi

# WHEN (or whether) the reflective layer loads -- the class source text plus the meta-system that
# parses it. globalFunctions reads this; buildProfile.py's SOURCES_POLICIES documents the values.
# "none" ships no source text at all, so the boot must not go looking for it.
printf "BUILDFLAG_SOURCES = '%s'\n" "$PROFILE_SOURCES" >> $SCRATCH_PATH/fizzygum-boot.coffee


# turn the coffeescript file into js in the js directory
echo "compiling boot file..."

# SourceVault FIRST, before anything else in the bundle: every generated sources_batch_*.js file
# is a sequence of SourceVault.store(...) calls, and the bundle is the entry page's first script,
# so the vault has to exist before any batch can run. It is deliberately NOT one of the standalone
# js/src/*-min.js boot files further down — those are loaded later in the boot sequence, by which
# time the batches would already have needed it.
cat src/boot/source-vault.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

# The parts manifest (window.FIZZYGUM_PARTS: per part, its batch files, eagerness and vendor
# payloads) goes IN the bundle rather than being fetched: the batch loader needs it immediately.
# build.py writes it from buildSystem/parts.json. It replaced numberOfSourceBatches.coffee, which
# only ever said "there are N batches called sources_batch_0..N-1".
printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat $SCRATCH_PATH/partsManifest.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

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

# Boot-bundle pieces contributed by the parts that SHIP: prototype extensions that belong in the
# bundle (they must exist before any class runs) but exist only for one part -- today that is
# src/boot/numbertimes.coffee, which extends Number for the fizzytiles LiveCodeLang preprocessor and
# is declared in fizzytiles' "bootPrelude" (buildSystem/parts.json). It used to be appended under
# `if ! $homepage`: a fact about a part, hard-coded in the build script, in the one place where
# nothing would ever check it against the part.
for eachPreludePiece in "${PROFILE_BOOT_PRELUDE[@]}" ; do
  printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
  cat "$eachPreludePiece" >> $SCRATCH_PATH/fizzygum-boot.coffee
done

# Stamp the build with its SOURCE COMMIT, never the wall clock. `buildVersion` is a human
# affordance only — nothing reads it in code; you type it in the browser console to see which build
# you are looking at — but it is compiled into BOTH shipped boot bundles, so whatever goes in here
# lands in their bytes. With $(date) in it, every build of identical sources produced a different
# bundle, which made a byte/hash comparison useless for the one question it should answer: "did this
# bundle actually change?". A commit id answers "which build is this?" at least as well AND is a pure
# function of the sources, so two builds of a clean tree at the same commit are now byte-identical.
# All three git reads degrade to a harmless literal outside a git checkout (e.g. a source tarball).
FG_BUILD_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "no-git")
FG_BUILD_WHEN=$(git log -1 --format=%cI 2>/dev/null || echo "unknown-date")
# a dirty tree cannot be named by a commit, so say so rather than claim the commit's identity
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then FG_BUILD_DIRTY=" +local-changes"; else FG_BUILD_DIRTY=""; fi
printf "\nbuildVersion = 'Fizzygum %s (%s)%s'" "$FG_BUILD_SHA" "$FG_BUILD_WHEN" "$FG_BUILD_DIRTY" >> $SCRATCH_PATH/fizzygum-boot.coffee

# Compiled into the SCRATCH dir, not the build tree: no entry page ever loads the unminified boot
# JS, so it is an intermediate like $BOOT_MIN below (which the SW/native assembly already removes
# with the same reasoning). Keeping intermediates out of the tree is what makes "what a flavour
# ships" derivable instead of something a per-flavour prune list has to remember.
coffee -b -c -o $SCRATCH_PATH/ $SCRATCH_PATH/fizzygum-boot.coffee
BOOT_JS=$SCRATCH_PATH/fizzygum-boot.js
echo "... done compiling boot file"

echo "minifying boot file..."

if ! $PROFILE_SHIPS_TESTS ; then
  # There are a few
  #    "if Automator? ...", "if AutomatorRecorder? ...", "if AutomatorPlayer? ..."
  #    "if Automator? and ...", "if AutomatorRecorder? and ...", "if AutomatorPlayer? and ..."
  # sections in the boot code. Every Automator* class lives in the HARNESS part, so when that part
  # does not ship none of them exist, the code in those sections is completely dead,
  # so we can search/replace those checks with "if (false", so that terser can just eliminate
  # both the checks and the dead-code sections.
  #
  # notice that OSX sed is different from GNU sed, so we need to give the -i '' parameter which means
  # "in-place editing, but don't make a backup file"
  sed -i '' 's/if ((typeof Automator[a-zA-Z]* !== \"undefined\" && Automator[a-zA-Z]* !== null)/if (false/g' $BOOT_JS
  sed -i '' 's/if (typeof Automator[a-zA-Z]* !== \"undefined\" && Automator[a-zA-Z]* !== null)/if (false)/g' $BOOT_JS
fi

terser --compress --mangle --output $BUILD_PATH/js/fizzygum-boot-min.js -- $BOOT_JS
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

if $PROFILE_SHIPS_SWCANVAS_ENTRY ; then
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
  # ⚠ THE INSTALL LINE IS LOAD-BEARING FOR src/, NOT JUST FOR SWCANVAS. The rotation math in
  # TransformSpec._cosSin and HandleWdgt._pointerAngleToTargetAnchorDegrees calls Math.cos/sin/atan2,
  # so on THESE pages — and only these — those calls resolve to the fdlibm port, which is what makes
  # rotated composites cross-engine byte-identical on the reference-matched pages. It runs before any
  # class source compiles, so no widget can ever observe the un-patched Math. Do not move it later.
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
# witness). SW3D is minified since nothing debugs through it here.
#
# NO det-trig here, deliberately (owner call 2026-07-30). This page's pixels are not reference-matched,
# so its rotations do not need to be cross-engine reproducible — platform Math trig is what we want.
# That is SAFE because no source names `DetTrig`: the two rotation-math sites (TransformSpec._cosSin,
# HandleWdgt._pointerAngleToTargetAnchorDegrees) call Math.cos/sin/atan2, which resolve to whatever the
# page installed — the fdlibm port on the SW pages above, the platform's own trig here. Anything that
# reached for the global by name would throw `DetTrig is not defined` the moment a window was rotated;
# ../Fizzygum-tests/scripts/smoke-boot-headless.js rotates a widget on this page to keep that honest.
echo "assembling the native boot bundle (boot only — the 3D vendor rides with its part)..."
cat $BOOT_MIN > $BUILD_PATH/js/fizzygum-boot-native-min.js
echo "... done assembling the native boot bundle"

# ---- the fizzytiles 3D vendor payload, as a PART file --------------------------------------------
#
# The 3D sliver used to be prepended to the native bundle, i.e. every visitor of index.html
# downloaded and parsed a software 3D engine to look at a desktop. It has exactly ONE consumer
# (src/fizzytiles/FridgeMagnets3DCanvasWdgt, which reads window.SWCanvas.Core.* / window.SW3D lazily
# inside _ensureEngine, never at class-definition time), so it belongs to that part and arrives when
# the part does — buildSystem/parts.json names it in fizzytiles' "vendor" list, and PartsRegistry
# injects it before the part's sources.
#
# ⚠ The SW pages must NOT load it: their boot bundle carries the FULL SWCanvas engine (it is their
# renderer) plus SW3D, so injecting the subtractive 3D-CORE build over it would replace a superset
# with a subset. PartsRegistry's vendor step is idempotent and skips it when window.SW3D and
# SWCanvas.Core.Triangle3DOps are already there.
#
# ⚠ ASSEMBLED BY build.py (arc 5 PR-D6), not here. parts.json declares the payload in fizzytiles'
# "vendor" list as an `out` path plus the vendored pieces to concatenate, and build.py writes it
# only for the flavours that SHIP that part. It used to be assembled here under `if the vendored
# source file exists` -- no part or flavour test at all, while this very comment claimed it was
# "emitted for every flavour that ships the part" -- so a --homepage tree carried 18.9 KB of
# software-3D engine for a part it does not ship. Only build.py knows which parts ship.

# The bare minified boot JS is an intermediate, never an entry page's bundle.
rm $BOOT_MIN

# Copy the vendored SWCanvas font assets (metrics + positioning bundles, and the wrapped atlas .js
# if vendored) so the SWCanvas text backend can load them at runtime over file://. These are font
# DATA, never embedded in a bundle. ONLY an SWCanvas entry page can use them, so a native-only tree
# does not carry them — that is ~90 MB not deployed.
# Populated by scripts/vendor-swcanvas-fonts.sh.
#
# ⚠ BOTH DIRECTIONS LIVE HERE, and the else branch is not redundant: $BUILD_PATH is shared across
# flavours and font-assets/ SURVIVES the cleanup section (unlike js/, icons/ and *.html, which are
# wiped), so a native-only build following a full one would otherwise inherit ~90 MB of font data no
# page in it can load. That re-prune used to sit ~50 lines below, inside the --homepage block, where
# it read as belt-and-braces duplication rather than as the other half of one decision.
if $PROFILE_SHIPS_SWCANVAS_ENTRY ; then
  if [ -d font-assets ] ; then
    echo "copying SWCanvas font assets..."
    mkdir -p $BUILD_PATH/font-assets
    cp -R font-assets/* $BUILD_PATH/font-assets/
    echo "... done copying SWCanvas font assets"
  fi
else
  rm -rf $BUILD_PATH/font-assets
fi

# (the entry pages themselves are written by build.py from src/index.html — see its ENTRY_PAGES)

# (The vendored js/libs files and the aux icons are copied by build.py, from the "assets" list of
# whichever PART owns each one -- FileSaver/JSZip and the three harness pointer icons belong to the
# harness part, the compiler and the boot splash/spinner to core. They used to be copied here
# unconditionally and then deleted again by the --homepage block below; owning them by part means a
# flavour stops shipping an asset because the part is absent, with no prune list to maintain.
# twgl-full.js is gone entirely: fizzytiles software-renders through SW3D, not WebGL.)

# Code that can be loaded after a pre-compiled world has started. EVERY boot loads only the
# minified twin (globalFunctions.coffee fetches js/src/<name>-min.js), on the precompiled path as
# much as the compile-at-boot one -- so the unminified .js is a pure INTERMEDIATE and is compiled
# into the scratch dir, never into the tree. It used to be compiled into js/src/ and then deleted
# again by the --homepage prune, which is the same untidiness with a per-flavour list in front of it.
JSSRC_SCRATCH=$SCRATCH_PATH/js-src
mkdir -p $JSSRC_SCRATCH
# js/src/ used to be created as a side effect of compiling INTO it; terser will not create its
# output's directory, so make it explicitly now that only minified files land there.
mkdir -p $BUILD_PATH/js/src

# dependencies-finding computes the class LOAD ORDER from the source text, so it belongs to the
# reflective layer and is loaded only from inside it (globalFunctions' loadReflectiveLayerPromise).
# ⚠ It is built for EVERY profile even so, and dropped later for the ones that cannot use it: the
# pre-compile driver harvests the image by booting this tree in COMPILE-AT-BOOT mode, which runs
# that layer and fetches this file. Skipping it here made a lean build hang until puppeteer's
# protocol timeout, with no error naming the missing file (measured).
coffee -b -c -o $JSSRC_SCRATCH/ src/boot/dependencies-finding.coffee
terser --compress --output $BUILD_PATH/js/src/dependencies-finding-min.js -- $JSSRC_SCRATCH/dependencies-finding.js

coffee -b -c -o $JSSRC_SCRATCH/ src/boot/loading-and-compiling-coffeescript-sources.coffee
terser --compress --output $BUILD_PATH/js/src/loading-and-compiling-coffeescript-sources-min.js -- $JSSRC_SCRATCH/loading-and-compiling-coffeescript-sources.js

coffee -b -c -o $JSSRC_SCRATCH/ src/boot/logging-div.coffee
terser --compress --output $BUILD_PATH/js/src/logging-div-min.js -- $JSSRC_SCRATCH/logging-div.js

echo "copying pre-compiled file"
cp auxiliary\ files/pre-compiled.js $BUILD_PATH/js/pre-compiled.js
echo "... done"


if $includeVideos ; then
  cp ../Fizzygum-videos-public/* $BUILD_PATH/videos/
fi

echo "... done copying icon files"


echo "cleanup unneeded files"
rm -rdf $SCRATCH_PATH
echo "...done"

# ---- form: precompiled ---------------------------------------------------------------------------
# What is left of what used to be the `if $homepage` block, and it is now exactly one question: does
# this profile ship a PRE-COMPILED image instead of compiling the classes in the browser? Everything
# else that lived in here was a per-flavour prune list, and every item of it has been re-homed --
# assets and vendor payloads to their owning part, the intermediates to the scratch dir, the
# font-assets re-prune to the copy decision above (arc 5 PR-D6: derive the tail, never declare it).
if [ "$PROFILE_FORM" = "precompiled" ] ; then
  # (There used to be a prune of the per-class source files here — build.py wrote one js file per
  # class next to the batches and nothing ever loaded them, so this line deleted ~500 of them again
  # for the production tree. Arc 4 stopped emitting them, so there is nothing left to prune: the
  # sources directory now holds only the batches plus the two individually-loaded Class/Mixin sources.)

  # Generate the pre-compiled image. It MUST happen here, while js/pre-compiled.js is still the
  # `window.preCompiled = false` stub — compile-at-boot is exactly the mode that builds the image.
  # The driver lives in the tests repo because Node resolves require('puppeteer') from the SCRIPT's
  # directory; the explicit cd in a subshell is what keeps that true regardless of this build's cwd.
  echo "generating the pre-compiled file headlessly. this might take a few seconds..."
  ( cd ../Fizzygum-tests && node scripts/generate-pre-compiled-headless.js ) || {
    echo "!!!!!!!!!!! error: pre-compiled generation failed" 1>&2
    exit 1
  }

  # (The unminified boot JS and the three unminified js/src helpers used to be pruned here. They
  # are build INTERMEDIATES that no page loads in any flavour, so they are now compiled into the
  # scratch dir and never enter the tree at all -- see the $BOOT_JS / $JSSRC_SCRATCH assignments.)


  # There are many
  #    "if Automator? ...", "if AutomatorRecorder? ...", "if AutomatorPlayer? ..."
  #    "if Automator? and ...", "if AutomatorRecorder? and ...", "if AutomatorPlayer? and ..."
  # sections in the code. A precompiled artifact is only built for a profile without the harness
  # part, so none of those three classes exists, the code in those sections is completely dead,
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
  mv $BUILD_PATH/js/pre-compiled-min.js $BUILD_PATH/js/pre-compiled.js

  # sources: "none" -- the appliance artifact. The class source text was a build INPUT: the driver
  # above harvested the pre-compiled image by booting this very tree in compile-at-boot mode and
  # compiling every source. Now that the image exists, the text does not ship -- ~40% of the tree,
  # and with it the ability to inspect and rewrite the system (buildProfile.py SOURCES_POLICIES).
  # This is a DERIVED consequence of the policy, not a list of files to delete: one directory, and
  # what goes in it was never enumerated here.
  # ⚠ The parts manifest compiled into the boot bundle still NAMES those batch files, because it was
  # written before the driver ran and lives inside a minified bundle. Nothing in this artifact reads
  # the list -- globalFunctions skips the whole reflective layer under "none", and a lazy part (the
  # other reader) is refused with this policy by buildProfile.py, precisely because a lazy part
  # arrives AS SOURCE and so could never load here.
  # ⚠ EVERYTHING THE REFLECTIVE LAYER NEEDS IS AN INPUT TO THIS STEP, so nothing it needs can be
  # skipped earlier -- it can only be dropped here, once the image exists. Both of these were
  # learned by watching a lean build fail: skip the source text and the driver harvests nothing;
  # skip dependencies-finding and the generation boot hangs on a 404 until puppeteer times out.
  if [ "$PROFILE_SOURCES" = "none" ] ; then
    echo "sources policy 'none': dropping the reflective layer (it was only an input to the pre-compiled image)"
    rm -rf $BUILD_PATH/js/coffeescript-sources
    rm -f $BUILD_PATH/js/src/dependencies-finding-min.js
  fi
fi

# BUILD STAMP: touched ONLY here, at the very end of a successful build, so its mtime == build-completion
# time. The headless test runners refuse to run if any source .coffee is newer than this stamp (or it is
# missing) -- so a build that didn't run / failed / ran from the wrong cwd can never be tested as if fresh.
# See Fizzygum-tests/scripts/lib/assert-build-fresh.js.
touch "$BUILD_PATH/.build-stamp"

# for OSX: say build done
tput bel
echo done!!!!!!!!!!!!
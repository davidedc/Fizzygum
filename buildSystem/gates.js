'use strict';
// gates.js — THE BUILD'S GATE SEQUENCE, as data. One row per static gate the build runs, in the order it runs them:
// the script, its arguments, WHEN it runs, the line it prints before it runs, the line it prints (with the terminal
// bell) when it fails, and the line it prints when it passes. buildSystem/run-gates.js runs the rows in order and stops
// at the first failure (build_it_please.sh calls it once, after build.js has written the tree). lib/what-runs.js
// requires this table and reads each row as the command line it is, `node <script> <args>`, so the census in
// run-selftests.js holds every gate listed here to its rule registry and its proof, and a self-test discovered by its
// gate's line is discovered from its row. What each gate checks, and what it cannot see:
// docs/architecture/lint-and-static-checks.md. The comments above each row are the build's own, verbatim, as they
// stood beside that gate's block in build_it_please.sh: where one names the shell's explicit `$?` abort, read the
// runner's stop at the first failure; where one names `"${args[@]}"`, read BUILD_ARGS.
const path = require('path');

const BUILD_SYSTEM = __dirname;
// the sibling tests repo: where its gates' scripts live, and the directory whose presence the testsShipped and
// testsRepo rows ask about (run-gates.js reads it from here, so the two cannot name different places)
const TESTS_REPO = path.join(__dirname, '..', '..', 'Fizzygum-tests');
const TESTS_SCRIPTS = path.join(TESTS_REPO, 'scripts');

// WHEN a row runs — every gate stands behind the build's --noSyntaxCheck escape hatch:
//   checked       unless --noSyntaxCheck;
//   testsShipped  and the profile ships the tests (the harness part) and TESTS_REPO is a directory;
//   testsRepo     and TESTS_REPO is a directory, whatever the profile ships.
const WHEN = ['checked', 'testsShipped', 'testsRepo'];

// A row whose args are BUILD_ARGS is handed the build's own arguments, as the build was invoked.
const BUILD_ARGS = 'BUILD_ARGS';
const GATES = [
  // --- the self-tests: every checker's proof that it can fail, FIRST ----------------
  // A gate whose own proof fails gives verdicts not worth reading, so the proofs run before any
  // gate does. A self-test is a FILE, `<subject>-selftest.js`, found by NAME in buildSystem/ and
  // (when present) Fizzygum-tests/scripts/ — never listed — through lib/what-runs.js's naming table,
  // which check-hand-lists.js reads too, so a sanction may lean on a self-test exactly because this
  // runs it. Each must end with the shared verdict line and a case count (one that judged nothing
  // fails), and a self-test flag offered anywhere else in a script's code fails the step: a
  // self-test nothing runs is the defect this exists to make impossible
  // (docs/archive/unrun-checks-plan.md). Pure Node, ~2 s. (buildSystem/run-selftests.js -- same
  // --noSyntaxCheck escape hatch and explicit $? abort as every gate below.)
  { script: path.join(BUILD_SYSTEM, "run-selftests.js"),
    args: [],
    when: "checked",
    banner: "running the gates' and tools' self-tests ...",
    failure: "!!!!!!!!!!! error: a self-test failed -- aborting build." },
  // --- build-time CoffeeScript syntax gate ----------------------------------------
  // The ~470 class sources ship as TEXT and are compiled in-browser, so without
  // this a "green" build can still contain syntax errors that only blow up at boot.
  // The gate loads the REAL src/meta/Class.coffee and drives every shipped source
  // through it (see buildSystem/check-coffee-syntax.js). We pass
  // "${args[@]}" so the gate checks exactly the files THIS build ships.
  // NOTE: this script has no `set -e`, so we MUST check $? explicitly to abort
  // (mirrors the terser error-check further below). --noSyntaxCheck is the escape hatch.
  { script: path.join(BUILD_SYSTEM, "check-coffee-syntax.js"),
    args: BUILD_ARGS,
    when: "checked",
    banner: "checking CoffeeScript syntax of all shipped sources ...",
    failure: "!!!!!!!!!!! error: CoffeeScript syntax check failed -- aborting build.",
    ok: "... CoffeeScript syntax OK" },
  // --- build-time SHIPPABLE-COVERAGE gate (every directory of the compiled sources must ship) --
  // The shipped-file list is buildSystem/parts.json's `dirs`, named directory by directory. A NEW
  // directory of src/ or of the harness ships NOTHING until a part claims it -- the build still exits 0,
  // and the syntax gate above (which reads the same --list-shippable set) skips it too; the only symptom
  // is a runtime `<NewClass> is not defined`. This gate diffs every .coffee file the build could compile
  // (buildSystem/lib/source-files.js compiledFiles: src/ and the harness) against build.js's own
  // --list-shippable output, and every src/boot file against the parts' boot declarations (--list-boot),
  // and fails loudly on any survivor.
  // We pass "${args[@]}" so it checks exactly the flags THIS build uses.
  // Same --noSyntaxCheck escape hatch and explicit $? check as the syntax gate above.
  { script: path.join(BUILD_SYSTEM, "check-shippable-coverage.js"),
    args: BUILD_ARGS,
    when: "checked",
    banner: "checking shippable-source coverage of the compiled sources (src/ and the harness) ...",
    failure: "!!!!!!!!!!! error: shippable-coverage check failed -- aborting build.",
    ok: "... shippable-source coverage OK" },
  // --- build-time layering / flow-soundness gate (self-settling public geometry API) -----
  // Enforces the call-graph layering the self-settling API relies on. A low-level method (raw*/silent*/
  // fullRaw*/_*, a *NoSettle core, or the _reLayout* / _positionAndResizeChildren / _reLayoutScrollbars
  // layout passes) must NOT reach UP into the public self-flushing layer: [A] no public geometry/text
  // setter or recalculateLayouts; [G] no structural self-settling wrapper (destroy/close/fullDestroy/
  // createReference/... — discovered structurally as the _settleLayoutsAfter callers); [B] recalculate-
  // Layouts() only from doOneCycle / the _settleLayoutsAfter(Batch) settle tiers; [C] no public setter
  // calls another; [E] a raw/silent/fullRaw mutator must not _invalidateLayout; [F] a non-mutator handler
  // must DEFER a container apply or mark it; [D] a SystemTest macro must not call a private/low-level
  // method. (buildSystem/check-layering.js — same --noSyntaxCheck escape hatch and explicit $? check as the
  // syntax gates around it; reads the compiled sources (src/ and the harness) and the tests' macros directly, so
  // needs no args.)
  { script: path.join(BUILD_SYSTEM, "check-layering.js"),
    args: [],
    when: "checked",
    banner: "checking public-API layering of all shipped sources ...",
    failure: "!!!!!!!!!!! error: layering gate failed -- aborting build.",
    ok: "... layering OK" },
  // --- build-time INVALIDATION-RECEIVERS gate -------------------------------------------
  // Enforces widget-citizenship contract point 2: invalidation is SELF-invalidation — a widget
  // never calls changed()/fullChanged() on another widget (if A's action affects B, B marks
  // itself changed in the method A invoked on it). Allowed receivers: @ (self) and the shared
  // singletons world / world.caret / world.hand; genuine dispatcher plumbing (the structural
  // add/drop/z-order movers, the selection-overlay reconciler, …) carries an explicit
  // `# cross-invalidation-sanctioned: <reason>` marker. (buildSystem/check-invalidation-receivers.js
  // -- same --noSyntaxCheck escape hatch and explicit $? check as the gates around it.)
  { script: path.join(BUILD_SYSTEM, "check-invalidation-receivers.js"),
    args: [],
    when: "checked",
    banner: "checking invalidation receivers (self-invalidation contract) ...",
    failure: "!!!!!!!!!!! error: invalidation-receivers gate failed -- aborting build.",
    ok: "... invalidation-receivers check OK" },
  // --- build-time DEAD-METHOD gate ------------------------------------------------------
  // Flags methods DEFINED in the compiled sources (src/ and the harness) but referenced NOWHERE (them + the tests'
  // macros and scripts) -- catches
  // dead code like the addRaw / fullRawMoveCenterTo deletions. A baseline of known-dead methods
  // is allowlisted in buildSystem/dead-method-allowlist.txt (a to-triage list); the gate FAILS
  // only on a NEW dead method not in that list. (buildSystem/check-dead-methods.js -- self-skips
  // if the sibling Fizzygum-tests repo is absent, e.g. a production build; same --noSyntaxCheck
  // escape hatch and explicit $? check as the layering gate above.)
  { script: path.join(BUILD_SYSTEM, "check-dead-methods.js"),
    args: [],
    when: "checked",
    banner: "checking for dead (never-referenced) methods ...",
    failure: "!!!!!!!!!!! error: dead-method gate failed -- aborting build.",
    ok: "... dead-method check OK" },
  // --- build-time HAND-LIST gate (baseline-ratcheted) -----------------------------------
  // A string-list literal that NAMES classes or members declared elsewhere is a second source of truth:
  // when the declaration moves, the list -- and any gate keyed on it -- silently checks less. Such a
  // list must be the class's own DECLARATION (`@serializationTransients`, `requiredParts`,
  // `optionalParts`), carry `hand-list-sanctioned: <what fails>` naming a REAL guard (a gate/rig file,
  // a SystemTest, or a token the code emits), or be counted against a per-repo inline baseline that
  // only falls. Multi-line by design: the lists that rot are one name per line, which no per-line stink
  // can see. (buildSystem/check-hand-lists.js -- reads src/ + buildSystem/ and, when the sibling
  // Fizzygum-tests repo is present, its scripts/ + harness; without it the tests half SKIPS and says
  // so. Same --noSyntaxCheck escape hatch and explicit $? check as the gates above.)
  { script: path.join(BUILD_SYSTEM, "check-hand-lists.js"),
    args: [],
    when: "checked",
    banner: "checking for hand-kept name lists (declared, sanctioned or ratcheted) ...",
    failure: "!!!!!!!!!!! error: hand-list gate failed -- aborting build.",
    ok: "... hand-list check OK" },
  // --- build-time UNRESOLVED-SENDS gate -------------------------------------------------
  // The exact INVERSE of the dead-method gate above: it flags a CALL `[@.]name(` whose name is
  // IMPLEMENTED NOWHERE in src + harness -- a guaranteed runtime TypeError on any path reaching it.
  // (Pharo's ReSentNotImplementedRule, carried over 2026-07-15.) Deliberately built for ZERO false
  // positives at the cost of reach: the def set is over-approximated, paren-less/string-dispatched
  // sends are out of scope. Vendor + genuinely-dynamic names are exempted, with a REASON, in
  // buildSystem/unresolved-sends-allowlist.txt; standard JS/DOM/canvas API lives in the checker's
  // in-file BUILTINS set. (buildSystem/check-unresolved-sends.js -- self-skips if the sibling
  // Fizzygum-tests repo is absent, since its harness is part of the definition universe; same
  // --noSyntaxCheck escape hatch and explicit $? check as the gates above.)
  { script: path.join(BUILD_SYSTEM, "check-unresolved-sends.js"),
    args: [],
    when: "checked",
    banner: "checking for unresolved sends (calls nobody implements) ...",
    failure: "!!!!!!!!!!! error: unresolved-sends gate failed -- aborting build.",
    ok: "... unresolved-sends check OK" },
  // --- build-time STINK gate (baseline-ratcheted) ---------------------------------------
  // Enforces "stinks": named smells ratcheted at a baseline COUNT. Each stink has its baseline inline in
  // buildSystem/check-stinks.js; the gate FAILS only when a stink EXCEEDS its baseline (a regression) --
  // mirroring the dead-method allowlist ratchet above -- and prints a "tighten me" note when one drops
  // BELOW. Seven are seeded (2026-07-15, docs/archive/lint-generic-rules-carryover-plan.md Phase 2): debugger 36,
  // undefined 89, null 10, wall-clock 19, timer 3, Math.random 5, instanceof 105 -- the determinism and
  // nil-convention rules that were manual-only until then. Same --noSyntaxCheck escape hatch and explicit
  // $? check as the gates above; reads the compiled sources (src/ and the harness) whatever the flavour ships, so it runs for every build flavour (incl. production).
  { script: path.join(BUILD_SYSTEM, "check-stinks.js"),
    args: [],
    when: "checked",
    banner: "checking for stinks (smells ratcheted to a baseline) ...",
    failure: "!!!!!!!!!!! error: stink gate failed -- aborting build.",
    ok: "... stink check OK" },
  // --- build-time CALL-ARGUMENTS gate (exact zero, both repos) ---------------------------
  // Every call's arguments against its callee (docs/architecture/constructor-and-parameter-conventions.md):
  // HOLE — the R3 hole test, if any call site must pass `undefined` to reach a later argument, the
  // parameter list is wrong (judged by the CALLERS TEST: a hole iff another call of the same callee
  // passes fewer arguments — the gate prints that witness, else the `undefined` is the operand's value);
  // EXTRA_ARGUMENT — a call passes more arguments than any definition it can reach declares (judged
  // only where its target is certainly among those); POSITIONAL_INTO_OPTIONS — `@`, a literal, an array, a
  // function or a `new` lands in an `opts = {}` slot. Every call site in BOTH repos — src, the harness,
  // every macro source, the MacroToolkit heredocs, the tests repo's scripts — read by real parsers
  // (buildSystem/lib/call-sites.js, which census-call-arity.js queries too). Exact zero, no baseline;
  // exit 2 (INVALID) when it cannot read a source. The tests repo absent, it judges src alone and says
  // so. Same --noSyntaxCheck escape hatch + explicit $? abort as the gates above.
  { script: path.join(BUILD_SYSTEM, "check-call-arguments.js"),
    args: [],
    when: "checked",
    banner: "checking call arguments (holes, extra arguments, positionals into options; both repos) ...",
    failure: "!!!!!!!!!!! error: call-arguments gate failed -- aborting build.",
    ok: "... call-arguments check OK" },
  // --- build-time MENU-ACTION WIRING gate -----------------------------------------------
  // A menu item is dispatched through ButtonWdgt's FIXED four-slot convention
  // (`@target[@action].call @target, menuItem, panelTarget, arg1, arg2`), and nothing at the call site
  // says so -- `menu.addMenuItem "label", target, "verb"` names none of the four arguments `verb` will
  // receive. Three failure modes follow, all of which were LIVE when this gate was written: a FUNCTION
  // LITERAL in the action slot (dispatch is `@target[@action]`, so it throws when clicked -- three
  // SliderWdgt items sat broken behind ButtonWdgt's runtime tripwire, because a runtime tripwire needs
  // someone to CLICK and the suite never clicks a slider's "floor..."); a STRING where the options
  // object goes; and a signature PADDED with unread slots to reach the one it wants, which puts widgets
  // into parameters whose names promise otherwise and forces every other caller to punch `undefined`
  // through. Rules 1-2 are sound negatives and HARD; rule 3 is a ratchet at 0 -- pad if you must, but
  // NAME the slot `ignored`/`unused`. Same --noSyntaxCheck escape hatch + explicit $? abort as above.
  { script: path.join(BUILD_SYSTEM, "check-menu-actions.js"),
    args: [],
    when: "checked",
    banner: "checking menu-action wiring ...",
    failure: "!!!!!!!!!!! error: menu-action gate failed -- aborting build.",
    ok: "... menu-action check OK" },
  // --- build-time THIN-WRAP gate --------------------------------------------------------
  // Enforces the ONE canonical shape for a public self-settling method that owns a private *Core twin:
  // `[guards] @mutateGeometryThenSettle => @_<name>Core <args>` -- it must do no work of its own, only
  // delegate to the core through the single-mutation settle tier. Genuine exceptions carry a per-method
  // `# thin-wrap-exempt: <reason>` marker (no central allowlist). (buildSystem/check-thin-wraps.js --
  // complements check-layering.js, which enforces that the CORE reaches no public setter. Same
  // --noSyntaxCheck escape hatch + explicit $? abort as the gates above; reads the compiled sources (src/ and the harness).)
  { script: path.join(BUILD_SYSTEM, "check-thin-wraps.js"),
    args: [],
    when: "checked",
    banner: "checking public/Core thin-wrap shape ...",
    failure: "!!!!!!!!!!! error: thin-wrap gate failed -- aborting build.",
    ok: "... thin-wrap check OK" },
  // --- build-time HYGIENE gates (ported from the retired SourceVault console tool, P2-T3 follow-up) ------
  // Four cheap line-scanner lints, each with the same --noSyntaxCheck escape hatch + explicit $? abort as
  // the gates above; all read the compiled sources (src/ and the harness, buildSystem/lib/source-files.js) whatever the flavour ships, so they run for every build flavour (incl. production):
  //   * check-trailing-whitespace.js — no trailing whitespace after content on a line.
  //   * check-scheduled-checks.js     — no OVERDUE `# CHECK AFTER <date>` reminder (a build-dated time bomb).
  //   * check-stringified-scripts.js  — no `new ScriptWdgt """..."""` stringified-code literal in core.
  //   * check-region-markers.js       — the `»>>` region-exclusion mechanism, ratcheted per kind to zero.
  //   * check-source-vault.js         — the retired `window.<Name>_coffeSource` source delivery, at zero.
  { script: path.join(BUILD_SYSTEM, "check-trailing-whitespace.js"),
    args: [],
    when: "checked",
    banner: "checking for trailing whitespace ...",
    failure: "!!!!!!!!!!! error: trailing-whitespace gate failed -- aborting build.",
    ok: "... trailing-whitespace check OK" },
  { script: path.join(BUILD_SYSTEM, "check-scheduled-checks.js"),
    args: [],
    when: "checked",
    banner: "checking for overdue CHECK-AFTER markers ...",
    failure: "!!!!!!!!!!! error: scheduled-checks gate failed -- aborting build.",
    ok: "... scheduled-checks OK" },
  { script: path.join(BUILD_SYSTEM, "check-stringified-scripts.js"),
    args: [],
    when: "checked",
    banner: "checking for stringified scripts in core ...",
    failure: "!!!!!!!!!!! error: stringified-scripts gate failed -- aborting build.",
    ok: "... stringified-scripts check OK" },
  { script: path.join(BUILD_SYSTEM, "check-region-markers.js"),
    args: [],
    when: "checked",
    banner: "checking region markers ...",
    failure: "!!!!!!!!!!! error: region-markers gate failed -- aborting build.",
    ok: "... region-markers check OK" },
  { script: path.join(BUILD_SYSTEM, "check-source-vault.js"),
    args: [],
    when: "checked",
    banner: "checking the retired source-delivery patterns stay dead ...",
    failure: "!!!!!!!!!!! error: source-vault gate failed -- aborting build.",
    ok: "... source-vault check OK" },
  { script: path.join(BUILD_SYSTEM, "check-whole-file-markers.js"),
    args: [],
    when: "checked",
    banner: "checking whole-file exclusion markers ...",
    failure: "!!!!!!!!!!! error: whole-file-markers gate failed -- aborting build.",
    ok: "... whole-file-markers check OK" },
  // The partition's one hard discipline: core must not name a part-owned class unguarded, or the
  // artifact that lacks the part throws when the user clicks. NOT derivable from the boot dependency
  // scanner (it cannot see `new X` in a method body) -- see the gate's header.
  { script: path.join(BUILD_SYSTEM, "check-part-edges.js"),
    args: [],
    when: "checked",
    banner: "checking core->part edges are guarded ...",
    failure: "!!!!!!!!!!! error: part-edges gate failed -- aborting build.",
    ok: "... part-edges check OK" },
  // --- build-time CONSTRUCTOR-BUILD gate ------------------------------------------------
  // Enforces the "all constructors settle" end-state (Topic 4 part 2): a `constructor:` body must NOT build
  // its own children inline (@add / @addNoSettle / @addMany / @_addNoSettle / … on `this`). Child-building
  // belongs in the _buildAndConnectChildrenNoSettle core, reached from the constructor via the settling
  // wrapper @_buildAndConnectChildren() (or @_buildScrollFrame() for the ScrollPanelWdgt base) -- so the
  // settle-tier FLUSHES a top-level `new X()` and AUTO-DEFERS one built in-flush (inside a callback). Genuine
  // exceptions carry a per-constructor `# constructor-build-exempt: <reason>` marker (no central allowlist).
  // (buildSystem/check-constructors-build.js -- same --noSyntaxCheck escape hatch + explicit $? abort as the
  // gates above; reads the compiled sources (src/ and the harness) whatever the flavour ships, so it runs for every build flavour incl. production.)
  { script: path.join(BUILD_SYSTEM, "check-constructors-build.js"),
    args: [],
    when: "checked",
    banner: "checking constructors do not build children inline ...",
    failure: "!!!!!!!!!!! error: constructor-build gate failed -- aborting build.",
    ok: "... constructor-build check OK" },
  // --- build-time CALL-SEPARATION gate ([S]/[U]) ----------------------------------------
  // Enforces the public/private call-separation ratchets (docs/archive/public-private-call-separation-plan.md):
  // [S] a PRIVATE method must not @-self-call a public COMMAND (settling / effectful callee -- queries and
  // the changed/fullChanged react verbs stay free); [U] a public method referenced ONLY by @-self calls is
  // provably not external API and must be _-tier (deliberate end-user inspector/scripting API goes in
  // buildSystem/public-api-allowlist.txt). Both are inline count-BASELINES (the check-stinks idiom): the
  // gate FAILS only when a count EXCEEDS its baseline; tighten the baseline to lock gains. Per-site escape
  // hatch for [S]: mark the CALLER `# public-call-sanctioned: <why>`. Measurement engine:
  // buildSystem/census-public-private-calls.js (also a standalone census CLI). [U] self-skips without the
  // sibling Fizzygum-tests repo (e.g. a production build), like the dead-method gate. (buildSystem/
  // check-call-separation.js -- same --noSyntaxCheck escape hatch + explicit $? abort as the gates above.)
  { script: path.join(BUILD_SYSTEM, "check-call-separation.js"),
    args: [],
    when: "checked",
    banner: "checking public/private call separation ...",
    failure: "!!!!!!!!!!! error: call-separation gate failed -- aborting build.",
    ok: "... call-separation check OK" },
  // --- build-time RELAYOUT-BOUNDS-FIRST gate --------------------------------------------
  // Enforces that a `_reLayout` override APPLIES ITS OWN BOUNDS before it reads its own geometry to position
  // children -- else the children lay out against the PREVIOUS pass's frame and lag one layout cadence on a
  // resize/move (the dpr2 "one-cadence-lag" flake fixed in InspectorWdgt and swept across the patch/prompt/app
  // widgets). A _reLayout that positions children from the newBoundsForThisLayout PARAM (or positions none)
  // passes trivially. Genuine exceptions carry a per-method `# relayout-bounds-first-exempt: <reason>` marker
  // (no central allowlist). (buildSystem/check-relayout-bounds-first.js -- same --noSyntaxCheck escape hatch +
  // explicit $? abort as the gates above; reads the compiled sources (src/ and the harness) whatever the flavour ships, so it runs for every build flavour incl. production.)
  { script: path.join(BUILD_SYSTEM, "check-relayout-bounds-first.js"),
    args: [],
    when: "checked",
    banner: "checking _reLayout applies own bounds before reading own geometry ...",
    failure: "!!!!!!!!!!! error: relayout-bounds-first gate failed -- aborting build.",
    ok: "... relayout-bounds-first check OK" },
  // --- build-time WIDGET-CONFORMANCE ratchet --------------------------------------
  // The ratcheted half of buildSystem/census-widget-conformance.js, which re-derives the mechanical facets of
  // docs/measurements/widget-practices-survey-2026-08-14.md. Only TWO facets are objective enough to gate --
  // instance fields written but never DECLARED at class level (they are invisible to duplication,
  // serialization and the inspector until declared), and classes still spelling out the `_reLayout` prologue
  // instead of taking Widget._reLayoutWithOwnContents. Everything else the census reports is a heuristic and
  // stays advisory: run `node ./buildSystem/census-widget-conformance.js` (or --json) to see it all.
  // ⚠ BOTH BASELINES ARE FLOORS, NOT ZEROS, and each remaining occurrence is a stated decision named in the
  // script. Green means "nothing got worse", never "nothing is left".
  // (same --noSyntaxCheck escape hatch + explicit $? abort as the gates above; reads the compiled sources (src/ and the harness) whatever the flavour ships, so it runs
  // for every build flavour incl. production.)
  { script: path.join(BUILD_SYSTEM, "census-widget-conformance.js"),
    args: ["--gate"],
    when: "checked",
    banner: "checking widget-practices conformance ratchets ...",
    failure: "!!!!!!!!!!! error: widget-conformance ratchet failed -- aborting build.",
    ok: "... widget-conformance check OK" },
  // --- build-time BACK-BUFFER-MEMOS gate -------------------------------------------------
  // A widget keeps no memo of its back buffer: every field a back-buffer builder (_createRefreshOrGetBackBuffer,
  // and the same-class methods it reaches) writes must be a serialization transient of the class chain, or a
  // field declared as saved content with a `# saved-content: <reason>` marker on (or directly above) its
  // declaration. The back buffer itself is a transient, so a memo of it that rides a save outlives the raster
  // it describes and the restored widget skips the paint it needs. Reads ALL of src/ -- every part, shipped or
  // not, so it covers the flag-gated video-player part no default build carries. (buildSystem/
  // check-back-buffer-memos.js -- same --noSyntaxCheck escape hatch + explicit $? abort as the gates above.)
  { script: path.join(BUILD_SYSTEM, "check-back-buffer-memos.js"),
    args: [],
    when: "checked",
    banner: "checking back-buffer builders keep no saved memo ...",
    failure: "!!!!!!!!!!! error: back-buffer-memos gate failed -- aborting build.",
    ok: "... back-buffer-memos check OK" },
  // --- build-time PAGE-LOADED-ELEMENTS gate ----------------------------------------------
  // An element the page loads (an image, a video) is a page fact derived from its holder's own path: every
  // field a class assigns one (new Image / new Audio / document.createElement of an img, video or audio) must
  // be a serialization transient of the class chain, and the chain must define both _afterDeserialization and
  // _reactToBeingCopied, the hooks that re-make it after a restore and after a copy -- neither walker carries
  // an element. An element constructed into no field says why with `# page-element-not-held: <reason>`. Reads
  // ALL of src/ -- every part, shipped or not, so it covers the flag-gated video-player part no default build
  // carries. (buildSystem/check-page-loaded-elements.js -- same --noSyntaxCheck escape hatch + explicit $?
  // abort as the gates above.)
  { script: path.join(BUILD_SYSTEM, "check-page-loaded-elements.js"),
    args: [],
    when: "checked",
    banner: "checking elements the page loads are re-made by their holders ...",
    failure: "!!!!!!!!!!! error: page-loaded-elements gate failed -- aborting build.",
    ok: "... page-loaded-elements check OK" },
  // --- build-time RELAYOUT-REPAINTS gate (TOMBSTONE) ------------------------------------
  // Static sibling to the runtime paint-truthfulness capstone (Fizzygum-tests/scripts/run-paint-audit.js),
  // which is unchanged. [INV-1] -- a `_reLayoutSelf` that suppresses change-tracking MUST issue a covering
  // `_fullChanged()` after its last re-enable (born from the 2026-07 D2 edit/view-toggle ghosts,
  // docs/archive/layout-regressions-2026-07-icons-plots-editghosts-plan.md) -- is now STRUCTURAL: bulk child
  // positioning coalesces through `Widget._repaintAsOneUnit fn`, whose `finally` both restores
  // `world._damageSuppressionDepth` and issues the owner's covering repaint, so neither half can be forgotten
  // or lost to an exception. What is left to lint is only that nobody resurrects the retired imperative
  // spelling: `disableTrackChanges` / `maybeEnableTrackChanges` must not reappear. Like check-region-markers.js
  // and check-whole-file-markers.js, the gate slot stays occupied so the retirement cannot silently un-happen.
  // (buildSystem/check-relayout-repaints.js -- same --noSyntaxCheck escape hatch + explicit $? abort as the
  // gates above; scans src/ plus the harness src, which compiles into the same world, so it runs for every
  // build flavour incl. production.)
  { script: path.join(BUILD_SYSTEM, "check-relayout-repaints.js"),
    args: [],
    when: "checked",
    banner: "checking tracking-suppressing _reLayoutSelf issues its covering fullChanged ([INV-1]) ...",
    failure: "!!!!!!!!!!! error: relayout-repaints gate failed -- aborting build.",
    ok: "... relayout-repaints check OK" },
  // --- build-time RAW-POINTER-READS gate ------------------------------------------------
  // Enforces that a pointer-event HANDLER body never consumes the raw SCREEN-plane pointer
  // (`world.hand.position()`) unmapped: since affine Phase 4A the dispatcher hands every handler a
  // position already inverse-mapped into the receiver's plane, and mixing the raw point with
  // plane-local geometry works aligned but silently breaks TILTED (the 2026-07-17 spreadsheet
  // tilted-selection bug). Per-frame sampling is allowed only mapped at the read site
  // (`screenPointToMyPlane` on the same line — the drag-scroll idiom). Genuine exceptions carry a
  // per-method `# raw-screen-pointer-sanctioned: <reason>` marker. (buildSystem/
  // check-raw-pointer-reads.js -- same --noSyntaxCheck escape hatch + explicit $? abort as the
  // gates above; reads the compiled sources (src/ and the harness) whatever the flavour ships, so it runs for every build flavour incl. production.)
  { script: path.join(BUILD_SYSTEM, "check-raw-pointer-reads.js"),
    args: [],
    when: "checked",
    banner: "checking pointer handlers consume the plane-mapped pointer (raw-pointer gate) ...",
    failure: "!!!!!!!!!!! error: raw-pointer-reads gate failed -- aborting build.",
    ok: "... raw-pointer-reads check OK" },
  // --- plane-discipline gate (paint-time scroll model) --------------------------------
  // Three statically-checkable rules of the stored-offset model (viewports-and-planes.md):
  // A) scrollOffsetX/Y written ONLY through the _writeScrollOffset funnel (a bare write skips
  //    the geometryVersion bump -- the measured hit-invisible-scrolled-row class); B) a count
  // ratchet over lines mixing two receivers' POSITIONAL geometry with no mapping call (the
  // silent dormant-at-offset-0 class -- new lines must be classified, drops ratchet down);
  // C) a positional pointer handler on a scroll-translation provider must re-derive its pos
  //    (escalateEvent forwards descendant-plane args verbatim). (buildSystem/
  // check-plane-discipline.js -- same --noSyntaxCheck escape hatch as the gates above.)
  { script: path.join(BUILD_SYSTEM, "check-plane-discipline.js"),
    args: [],
    when: "checked",
    banner: "checking plane discipline (offset funnel / positional mixing / escalation boundary) ...",
    failure: "!!!!!!!!!!! error: plane-discipline gate failed -- aborting build.",
    ok: "... plane-discipline check OK" },
  // --- build-time test-.js syntax gate (only when tests are part of this build) ---------
  // Each SystemTest's _automationCommands.js carries its macro inside a backtick-delimited JS
  // template literal; a stray backtick silently corrupts the file so the test never loads (with
  // corrupted/missing screenshots, not an obvious error). This runs `node --check` over every
  // tests/*.js (see ../Fizzygum-tests/scripts/check-tests-syntax.js) to catch that — and any JS
  // syntax error — BEFORE the build copies them in. Same --noSyntaxCheck escape hatch and explicit
  // $? check as the CoffeeScript gate above; skipped when the profile ships no test machinery, or
  // when the sibling Fizzygum-tests repo is absent.
  { script: path.join(TESTS_SCRIPTS, "check-tests-syntax.js"),
    args: [],
    when: "testsShipped",
    banner: "checking JS syntax of all shipped test sources ...",
    failure: "!!!!!!!!!!! error: test .js syntax check failed -- aborting build.",
    ok: "... test .js syntax OK" },
  // --- build-time macro EVAL-DISCIPLINE gate (only when tests are part of this build) ------------
  // A macro body IS CoffeeScript, so a call written as a string for `world.evaluateString` throws
  // away its bindings, this syntax gate, and any rename sweep's chance of finding it. Worse, it is
  // not a plain call: Widget.evaluateString ends in `sourceChanged()` (a re-layout and a repaint), so the world
  // form DAMAGES THE WHOLE WORLD — a fixture step written that way forces a full repaint that masks
  // a missing self-invalidation in whatever it just drove, which is exactly the defect class the
  // suite's incremental damage-rect screenshots exist to catch. The gate holds two rules over the
  // macro sources ONLY (see ../Fizzygum-tests/scripts/check-macro-source-discipline.js): `@evaluateString`
  // is always wrong (that is MacroToolkit's own, a different method), and `world.evaluateString` is
  // allowed only where the test DECLARES the eval as its subject via its `evaluateString` tag —
  // a declaration rather than a count, so there is no baseline number to rot. Its own acceptance
  // corpus is scripts/check-macro-source-discipline-selftest.js, in `npm run selftest`. Pure text,
  // milliseconds. Same --noSyntaxCheck escape hatch / $? check / ships-tests + sibling guard as above.
  { script: path.join(TESTS_SCRIPTS, "check-macro-source-discipline.js"),
    args: [],
    when: "testsShipped",
    banner: "checking macro sources for source discipline ...",
    failure: "!!!!!!!!!!! error: macro source-discipline check failed -- aborting build.",
    ok: "... macro source discipline OK" },
  // --- build-time SWCanvas reference-image gate (only when tests are part of this build) ---------
  // the tests' asset manifest (Fizzygum-tests/scripts/generate-tests-manifests.js) sweeps EVERY ref file in tests/, so a STRAY/duplicate ref (e.g.
  // left by a capture undone with `git checkout`, which leaves the new-hash file untracked) would
  // enter the build and let a WRONG render false-PASS (compareScreenshots matches ANY candidate).
  // check-refs.js fails on >1 dataHash per (test,image,dpr,OS) or an orphaned .js/.png BEFORE the
  // build ships them. Structural only, no pixel decode (~0.2s). The PIXEL half — decode EVERY ref
  // and assert each re-hashes to its stored hashOfData — is `check-refs.js --pixels` (~10s), and is
  // deliberately NOT here: 10s on every inner-loop build to re-check references that only change on a
  // recapture is a bad trade. It runs as the gauntlet's `refs` leg, or by hand via
  // `npm run check-refs:pixels` in Fizzygum-tests. (It needs no PNG optimizer either — recompress
  // --check-only never picks one; the old note claiming otherwise was wrong.) Same --noSyntaxCheck
  // escape hatch / $? check / ships-tests + sibling guard as the gates above.
  { script: path.join(TESTS_SCRIPTS, "check-refs.js"),
    args: ["--quiet"],
    when: "testsShipped",
    banner: "checking SWCanvas reference images for strays/duplicates ...",
    failure: "!!!!!!!!!!! error: SWCanvas reference check failed -- aborting build.",
    ok: "... SWCanvas references OK" },
  // --- build-time visualisation-page gate (only when tests are part of this build) ---------------
  // A test's visualisation.html EMBEDS its reference filenames, and a reference filename carries the
  // image's dataHash -- so anything that renames or re-captures a reference without regenerating the
  // page leaves it pointing at a PNG that no longer exists. That break is SILENT: nothing in CI opens
  // these pages, so a broken one looks exactly like a working one until a human clicks it. Measured
  // twice: 10 of 305 pages were already broken on 2026-08-21, and the 2026-08-22 filename-grammar
  // migration would have broken 279 in a single commit. The capture path regenerates a page at its
  // write site, which covers captures; this covers everything else by checking the property itself
  // instead of trusting every writer to remember the rule. No image decode, no browser (~0.2s). Same
  // --noSyntaxCheck escape hatch / $? check / ships-tests + sibling guard as the gates above.
  { script: path.join(TESTS_SCRIPTS, "check-visualisations.js"),
    args: ["--quiet"],
    when: "testsShipped",
    banner: "checking visualisation pages for broken image references ...",
    failure: "!!!!!!!!!!! error: visualisation page check failed -- aborting build.",
    ok: "... visualisation pages OK" },
  // --- the aim census's TABLES (../Fizzygum-tests/scripts/aim-census.js --tables-only) ------------
  // The census of where every macro test aims is a measurement, never a gate — but its own tables
  // classify every MacroToolkit verb and name the classes and members it reads, and those are held to
  // Fizzygum's source both ways (AIM-CENSUS STALE NAME / UNCLASSIFIED VERB / UNKNOWN VERB). Run here
  // so a verb deleted or renamed in src/macros fails the change that did it; check-hand-lists accepts
  // the census's sanctions because this runs them. ~0.2 s. Reads Fizzygum's src and the tests' macro
  // sources, whatever the profile ships, so it runs whenever the sibling repo is present (as
  // check-hand-lists' tests half does). Same --noSyntaxCheck escape hatch + explicit $? abort.
  { script: path.join(TESTS_SCRIPTS, "aim-census.js"),
    args: ["--tables-only"],
    when: "testsRepo",
    banner: "checking the aim census's tables against the source ...",
    failure: "!!!!!!!!!!! error: the aim census's tables are stale -- aborting build." },
  // --- the method-count and cognitive-complexity ratchets ----------------------------------------
  // Two recorded values that may fall and may not rise, in the stinks' style: the methods of the four
  // classes that grew with nothing holding them (Widget, WorldWdgt, ActivePointerWdgt, FrameWdgt), and
  // the cognitive complexity of every function of the compiled sources (above 15, only the functions
  // recorded when the ratchet landed, each at its value). Its analyzer is vendored
  // (vendor/coffeescript-cognitive-complexity/) and runs on the global CoffeeScript the build already
  // requires. A class or function under its record prints UNDER: lower the record, to lock the gain in.
  // ~2 s.
  { script: path.join(BUILD_SYSTEM, "check-complexity-ratchets.js"),
    args: [],
    when: "checked",
    banner: "checking the method-count and cognitive-complexity ratchets ...",
    failure: "!!!!!!!!!!! error: a method-count or complexity ratchet rose -- aborting build.",
    ok: "... method-count and complexity ratchets OK" },
];

module.exports = { GATES, WHEN, BUILD_ARGS, TESTS_REPO };

> **ARCHIVED — COMPLETE (2026-07-17 restructure).** Memory ledger records PUSHED 2026-07-13; file's own header still reads PLANNED/not-started (stale).
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Duplication & per-widget save must preserve affine transforms — root cause + fix plan

**Status: PLANNED, not started.** Authored 2026-07-13 from a code-read root-cause session
(high-confidence: the mechanism is airtight in the source; a 2-minute step-0 repro is still
prescribed below). This plan is self-contained: an implementing session needs no other
context beyond the referenced files.

## 0. The reported bug and the governing principle

Duplicating a rotated/scaled widget produces an UN-transformed copy ("duplication resets
transforms"). Owner-stated principle (2026-07-13, locked): duplication is conceptually (and
partly mechanically) serialization+deserialization; serializing a WORLD keeps every widget's
transform, so by generalization a serialized/deserialized WIDGET must keep its transform, and
by analogy a DUPLICATED widget must too. The fix must make duplication — and the per-widget
"save to file…" — transform-preserving.

**Step 0 (cheap repro, do first):** build (`/Users/davidedellacasa/code/Fizzygum-all/fg build`),
open `Fizzygum-builds/latest/index.html`, drop any widget on the desktop, rotate it via the
halo rotate handle (or in console: `w.setRotationDegrees 30`), right-click it → "duplicate".
Expected bug: the copy appears with NO rotation. Same with "save to file…" → reload the
`*.fzw.json`: restored widget is un-rotated.

## 1. Root cause (confirmed by code read)

A widget's transform does NOT live on the widget. It lives on an enclosing
**`TransformFrameWdgt` "island"** (`src/TransformFrameWdgt.coffee`) whose
**`TransformSpec`** (`src/TransformSpec.coffee` — canonical scalars `rotationDegrees`,
`scale`, `anchor`, `claimsSpace`) is the ONLY transform truth. Rotating/scaling a plain
widget via the property sugar (`Widget.setRotationDegrees` / `setScaleFactor`,
`src/basic-widgets/Widget.coffee:1443-1467`) MATERIALIZES a sole-content
`TrackingTransformFrameWdgt` sugar island around it
(`Widget._materializeSugarIslandNoSettle`, `Widget.coffee:1483`), i.e. the widget's PARENT
holds the transform.

The island is deliberately hit-transparent plumbing (`TransformFrameWdgt` ctor:
`noticesTransparentClick = false`, `isTransparentAt -> true`,
`src/TransformFrameWdgt.coffee:101-133`), so a right-click on a transformed widget always
opens the **content widget's** menu — `@` in every menu action is the content, never the
island. And:

- `Widget.duplicateMenuAction` (`Widget.coffee:3126`) and
  `Widget.duplicateMenuActionAndPickItUp` (`Widget.coffee:3133`) call `@fullCopy()`
  (`Widget.coffee:3168`), whose copy scope is `allWidgetsInStructure =
  @allChildrenBottomToTop()` — **the widget's own subtree only**. The enclosing island is an
  *external* widget to the walker (`DeepCopierMixin.deepCopy`,
  `src/mixins/DeepCopierMixin.coffee:38`), so the copy is created bare, gets `world.add`-ed →
  identity → "transform reset".
- `Widget.saveToFile` (`Widget.coffee:3198`) serializes `@` — and the Serializer nils the
  ROOT's `parent` by policy (`src/serialization/Serializer.coffee:254-256`, reference doc
  §4.3) — so the island (the transform) never enters the envelope. The `*.fzw.json` restores
  un-transformed. **Same root cause, serialization face.**

So the defect is NOT in the copy/serialize machinery — it is **target resolution at the
user-facing entry points**: they operate on the content widget when they should operate on
the *figure* (widget + its transform plumbing).

### 1a. The machinery below the entry points is already transform-clean (verified)

- Duplication of an ISLAND works today (islands nested inside a copied container are
  deep-copied): `TransformSpec`, `Point`, `Rectangle`, `Color` all
  `@augmentWith DeepCopierMixin`; `TransformFrameWdgt._reactToBeingCopied`
  (`src/TransformFrameWdgt.coffee:226`) drops the derived island-buffer cache on the clone;
  `_materializedBySugar` / `cachesBuffer` copy as plain booleans.
- Serialization of an ISLAND round-trips, incl. sugar-removability: proven by the existing
  test `SystemTest_macroSugarIslandSurvivesSerializationRoundTrip` (Fizzygum-tests) — but
  note it calls `serialiseToMemory()` **on the island itself**, which is exactly why it never
  caught this bug: the gap is entry-point targeting, not the round-trip.
- **Answer to "does ser/deser preserve transforms?" (owner P.S.):** whole-WORLD snapshot —
  YES (islands are ordinary members of `world.children`; reference doc §11; pixel-identical
  round-trips proven). Single-widget machinery — YES *when handed the island*. The
  per-widget "save to file…" MENU action — NO, because it hands the machinery the content
  widget (this plan's bug).

## 2. Fix shape (confident sketch — details left to the implementing session)

**Resolve the figure at the entry points; leave the primitives untouched.** The codebase
already has the canonical verb: `Widget._enclosingIslandFigure()` (`Widget.coffee:1659`) —
climbs to the outermost island of which I am transitively the SOLE content (sugar or
explicit), returns `@` off any island. Its doc comment already mandates exactly this usage
("ONE greppable home for every re-home site — route close/reopen/eject through this, NEVER
inline the climb"); precedent consumer: `IconicDesktopSystemWindowedApp.coffee:59`. The drag
pipeline makes the same move at ITS entry point (`determineGrabs` resolves
`_resolvePickOutFigureNoSettle` before grabbing, `src/ActivePointerWdgt.coffee:1075`).

Do NOT change `fullCopy`/`deepCopy`/`Serializer` semantics — `fullCopy` is a load-bearing
primitive with non-menu callers that must stay content-scoped (template drag copy
`ActivePointerWdgt.coffee:1055`, `GlassBoxTopWdgt.coffee:15`, `PopUpWdgt.coffee:95`
override), and the SystemTest suite bakes duplication pixels in.

Concretely (all in `src/basic-widgets/Widget.coffee` unless noted):

1. **`duplicateMenuAction` (:3126):**
   ```coffee
   figure = @_enclosingIslandFigure()
   aFullCopy = figure.fullCopy()
   return if !aFullCopy?
   aFullCopy._unlockFromPanels()
   world.add aFullCopy
   aFullCopy._applyMoveTo figure.position().add new Point 10, 10   # offset from the FIGURE
   aFullCopy._rememberFractionalSituationInHoldingPanel()
   ```
   Note the island's `_applyMoveTo`/`_applyMoveBy` overrides already ride a pinned anchor
   along (`TransformFrameWdgt.coffee:302-313`), so a plain offset move of the copied figure
   is anchor-safe.

2. **`duplicateMenuActionAndPickItUp` (:3133):** same figure resolution, then — because the
   copy goes ONTO THE HAND — normalize a possibly-pinned anchor first, matching the Bug-G
   pick-up seam (`_normalizePinnedAnchorNoSettle`, `TransformFrameWdgt.coffee:326`; the whole
   hand-carry pipeline assumes a slot-centre pivot):
   ```coffee
   figure = @_enclosingIslandFigure()
   aFullCopy = figure.fullCopy()
   aFullCopy?._normalizePinnedAnchorNoSettle?()   # only islands define it; copy is detached so no settle needed
   aFullCopy?.pickUp()
   ```

3. **`saveToFile` (:3198):** serialize the figure, keep the filename derived from the
   CONTENT (the thing the user believes they are saving):
   ```coffee
   figure = @_enclosingIslandFigure()
   envelope = figure.serialize prettyPrint: true    # inside the existing try/catch
   baseName = (@colloquialName?() or @constructor.name.replace "Wdgt", "") or "widget"
   ```
   Restore needs NO change: `FileLoading` attaches whatever the envelope's root is, and a
   restored `TransformFrameWdgt` root is proven live (§1a).

4. **Dormancy argument (why the existing suite stays green):** off any island,
   `_enclosingIslandFigure()` returns `@` — every changed entry point is byte-identical for
   un-transformed widgets. Expected screenshot-recapture count for the existing suite: **0**
   (verify, don't assume — run the full gauntlet; if any existing macro duplicates a
   TRANSFORMED widget it would newly — correctly — show two transformed copies, which is the
   fix working, and wants a recapture + a note).

### 2a. Sibling defect, same class (fix here or file as follow-on — small)

The **"pick up" menu item** (`Widget.coffee:3809`/`3816`) calls `pickUp` (:3493) →
`world.hand.grab @` directly — which does NOT resolve the pick-out figure (resolution lives
only in the drag path, `determineGrabs`, `ActivePointerWdgt.coffee:1075-1087`). Code-read
consequence for a transformed widget (needs the behavioural confirm): the CONTENT is ripped
onto the hand un-transformed AND the now-empty sugar island stays stranded in the tree
(nothing dissolves a contentless island; `TrackingTransformFrameWdgt._reLayoutChildren`
no-ops with no content). Recommended same-shape fix: give the MENU a `pickUpMenuAction` that
mirrors the determineGrabs trio (resolve figure → Bug-F identity-wrapper dissolve → grab),
ideally by extracting that trio into one shared self-settling helper so the two entry points
cannot drift; leave bare `pickUp` untouched (it has many programmatic callers on detached
widgets, e.g. `deserialiseFromMemoryAndAttachToHand` :3784, for which figure resolution is a
no-op anyway).

### 2b. Explicitly OUT of scope (owner-gated Phase 2, do NOT slip it in)

- **Sub-part duplication:** `@` a genuine sub-part of a multi-child island (not sole
  content) still duplicates bare — `_enclosingIslandFigure` deliberately does not climb.
  Pick-out DRAG of a sub-part wraps the extract in a fresh island carrying the accumulated
  similitude (`_pickOutRotatedFigureNoSettle`, `Widget.coffee:1620`); duplicate-parity would
  fold `figure.accumulatedRotationDegrees()`/`accumulatedScaleFactor()` of the ORIGINAL into
  the copy the same way.
- **Nested planes:** duplicating the sole-content figure of an island that itself sits
  INSIDE another non-identity plane copies the RELATIVE spec; `world.add` then renders the
  relative, not the accumulated, look. Same accumulated-fold answer (Bug-F math,
  `Widget.coffee:1580-1604`).
- Both are WYSIWYG-consistency refinements of rarer cases; decide with the owner after the
  core fix lands.
- Also untouched: dev-only `serialiseToMemory` (:3771 — the existing round-trip test targets
  the island itself through it; changing its targeting is an owner call), template-drag copy
  (`isTemplate`), `GlassBoxTopWdgt`, `attach…`, `createReference`. Buttons wired to
  `duplicateMenuAction*` (see `LabelButtonWdgt.coffee:168` note) inherit the fix for free.

## 3. Tests to author (a required deliverable of the implementing session)

Author as macro SystemTests (the only test style — `Fizzygum/src/macros/CLAUDE.md`, the
`/author-macro-test` skill in Fizzygum-tests; beware: a backtick in a macro COMMENT kills the
test-.js gate). Each must FAIL against pre-fix code (verify by stashless A/B: WIP commit or
worktree — never `git stash` in these repos) and pass post-fix:

1. **`SystemTest_macroDuplicatePreservesTransform`** (name indicative): tilt+scale a
   rectangle via public sugar (`setRotationDegrees 30`, `setScaleFactor 1.5` — or the halo
   handle for end-to-end realism), menu-duplicate it (drive the real context-menu path, both
   `duplicateMenuAction` and the pick-up variant if feasible), drop the copy on the desktop.
   Assertions: screenshot with BOTH widgets visibly transformed + value asserts (the
   duplicate's parent is a `TransformFrameWdgt` with equal `rotationDegrees`/`scale`;
   original island untouched; copy's island still `_materializedBySugar`-removable — de-tilt
   to 0 dissolves it, mirroring the existing sugar round-trip test's behavioural-removability
   pattern).
2. **Save-path leg:** prove the ENTRY-POINT resolution round-trips — e.g. a macro modelled on
   `SystemTest_macroSugarIslandSurvivesSerializationRoundTrip` but driven from the CONTENT
   widget through the fixed path (if `saveToFile`'s download step is awkward headless,
   refactor it minimally into a testable resolve+serialize seam and exercise that), then
   deserialize + attach and assert the restored figure keeps 30°/1.5×.
3. **If 2a lands:** menu pick-up of a tilted widget keeps the tilt on the hand AND leaves no
   stranded island (assert the world's `TransformFrameWdgt` count).

New tests need reference captures: `fg recapture <name>` (dpr1+dpr2 Chrome + the WebKit leg
reuses the same refs). ⚠ After any recapture, REBUILD before re-running suites (stale-build
trap), and re-run the failed shard rather than trusting a partial capture.

## 4. Verification gates (workspace-standard)

- Inner loop: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (~3.5 min).
- Commit gate: `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet` (~4.5-5 min, parallel;
  launch via Bash `run_in_background: true` redirected to a log — never foreground-poll).
- Expected: 0 recaptures on the existing suite (the §2 dormancy argument) + the new tests
  green. Any unexpected diff in an existing test = investigate before touching references.
- Per owner standing preference: present the summary + proposed commit message and WAIT for
  explicit approval before any commit/push (both repos: Fizzygum + Fizzygum-tests move
  together — code + new tests).

## 5. Estimated size

Small-to-medium: ~15 lines of production change across 3-4 methods in
`Widget.coffee` (+ optional `pickUpMenuAction` + shared resolve helper), zero machinery
changes, plus 2-3 new macro tests with captures. The risk is concentrated in the tests'
determinism (follow `Fizzygum-tests/DETERMINISM.md`: event-time only, no wall-clock).

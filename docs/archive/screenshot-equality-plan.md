# SCREENSHOT-EQUALITY-PLAN.md — make within-test screenshot byte-equality a first-class assertion

> ✅ **PLAN CLOSED 2026-06-12** (same day it was drawn up; Batches 64–66). The construct
> (`AutomatorPlayer.liveScreenshotFingerprints` + `MacroToolkit.assertScreenshotsIdentical`)
> shipped, every claimed within-test pair is asserted in-run (27 tests / 36 assertions),
> docs + skill + memory mandate it for new pairs. This file stays as the record of the
> design and the per-test verdicts. New byte-equality pairs need no plan — just the
> assertion, per src/macros/MACRO-PATTERNS.md's preamble.

Drawn up 2026-06-12, right after MIGRATION-PLAN.md closed. Owner-approved ("yes make a plan
for this"). Same consumption model as the migration plan: each batch takes the next
unchecked items, ticks boxes, appends a status line. ASK before every commit/push.

## Why (the hole this closes)

SWCanvas + the event queue made runs deterministic, and ~22 shipped macros now assert a
property by claiming two screenshots in the SAME test are byte-identical (the no-op /
round-trip idiom: undo restores, collapse/uncollapse restores, a cancelled prompt leaves
zero residue, ...). Today that equality is enforced only TRANSITIVELY: each shot is
hash-matched against its OWN committed reference (`AutomatorPlayer.compareScreenshots`,
AutomatorPlayer.coffee:344 — per-image-name candidates, raw-pixel SHA-256 under SWCanvas),
and the two committed references happen to share a dataHash. So at REPLAY a broken
identity does fail — but nothing in the TEST declares the pair, which means:
- a `capture-macro-test-references.js --clean` after a regression that breaks an identity
  silently stores two DIFFERENT hashes and the assertion evaporates with no error;
- the claim lives only in prose (`assertions` metadata + `#` comments) and in the
  authoring-time habit of reading the dataHash in the two reference filenames.

The fix: an explicit, in-run, live-vs-live equality assertion through the harness's
existing non-screenshot assertion channel.

## Design (decided)

1. **Recording the live fingerprints.** In `compareScreenshots`
   (AutomatorPlayer.coffee:344), record each shot's live fingerprint into a per-test map
   on the player, e.g. `@liveScreenshotFingerprints[testNameWithImageNumber] = liveHash`:
   - SWCanvas branch: the already-computed `liveHash` (raw-pixel SHA-256);
   - native/HTML5 branch: the obtained PNG data-URL string (string equality == byte
     equality; keeps the assertion backend-agnostic).
   Reset the map at test start in `startTestPlaying` (AutomatorPlayer.coffee:710).
2. **The assertion method** — a toolkit L2 assertion (no input events → NO `_InputEvents`
   suffix; no mid-name "Macro" token, rule 3):
   `assertScreenshotsIdentical: (earlierImageName, laterImageName)` in
   `../Fizzygum/src/macros/MacroToolkit.coffee`, next to `assertTopMenuItemCount`. It reads
   both fingerprints from `world.automator.player.liveScreenshotFingerprints` and calls
   `world.automator.player.recordMacroAssertion(equal, "screenshots <A> and <B> are
   byte-identical", <earlier fingerprint>, <later fingerprint>)`
   (recordMacroAssertion: AutomatorPlayer.coffee:237 — fails the test red like a
   screenshot mismatch, does NOT stop the macro). Missing fingerprint (typo'd name /
   assertion before the shot) => FAIL with a clear "no such screenshot taken" message,
   never a silent pass.
3. **Usage in macro source** — immediately after the LATER shot:
   `takeScreenshot_InputEvents_Macro "...image_5"` then
   `@assertScreenshotsIdentical "...image_3", "...image_5"` (full image names, exactly as
   passed to the screenshot verb). The loader's reference-name extraction only scans for
   the screenshot verb, so the new call cannot confuse it — verify this while implementing.
4. **Why this also guards recapture:** the capture script's VERIFY legs replay the test
   (PLAYING state, both dprs); with the assertion in-source, a regression that breaks an
   identity fails the verify leg, so `--clean` recapture can no longer silently dissolve a
   pair. (While implementing, ALSO check the capture leg's `Automator.state` — if it is
   PLAYING too, the assertion bites even earlier; `recordMacroAssertion` gates on
   `Automator.state == Automator.PLAYING`, Automator.coffee:3-4 for the states.)
5. **Docs**: add the method to the L2 assertion list in `../Fizzygum/src/macros/CLAUDE.md`;
   UPDATE MACRO-PATTERNS.md's byte-equality idiom entry (the "Undo" entry and the no-op
   idiom mentions) to mandate the explicit assertion for every new pair. Two-repo commit
   (toolkit + docs are in Fizzygum; tests + harness in Fizzygum-tests).

## Batches

- [x] **Batch 64 — the construct.**
  (a) Player: fingerprint map + reset + recording in both branches of
  `compareScreenshots`. (b) Toolkit: `assertScreenshotsIdentical` + doc-comment.
  (c) Docs: CLAUDE.md L2 list + MACRO-PATTERNS byte-equality entry update.
  (d) Proof retrofit on TWO macros: `macroStringWdgtEditDefersToPromptWhenCropped`
  (image_4 == image_3) and `macroWindowCellsInConstrainedScrollStackReflow`
  (image_3 == image_1 AND image_6 == image_5). (e) FULL build + run the two retrofitted
  macros headless at dpr 1 and 2 — they must PASS with "PASS screenshots ... are
  byte-identical" lines in the console output; ALSO sanity-check the standard probe
  (macroWrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved, dpr 1).
  (f) NEGATIVE check (one-off, not committed): temporarily flip one asserted name to a
  non-identical shot, rebuild, confirm the test FAILS red, revert, rebuild.
- [x] **Batch 65 — mechanical enumeration + full retrofit.**
  (a) Enumerate ground truth: a small one-off script/pipeline that, per test dir, groups
  SWCanvas dpr-1 reference files by the dataHash in their filenames and lists image-name
  groups sharing a hash (cross-check dpr-2 agrees). (b) Cross-reference the groups against
  the ~22 macros whose metadata/comments CLAIM identity (grep
  "byte-identical|byte-IDENTICAL|same dataHash|identical dataHash|pixel-identical" in
  tests/*/SystemTest_macro*.js minus automationCommands): retrofit the assertion for every
  CLAIMED pair; list (in this plan, do not assert) any UNCLAIMED accidental identities the
  enumeration surfaces. (c) Rebuild + run every retrofitted macro headless at dpr 1; spot
  dpr 2 on three of them. NO recapture anywhere — the assertion changes no screenshots and
  no reference names; references stay byte-identical.
- [x] **Batch 66 — closure.** Update the `/migrate-systemtest` skill text if it mentions
  the byte-equality idiom (it does — "anchor byte-equality pairs..."), update the project
  memory note, append the closing status line here.

## Status log

- **Batch 64 done (2026-06-12).** Construct shipped: `AutomatorPlayer.liveScreenshotFingerprints`
  (recorded in BOTH compareScreenshots branches, reset in startTestPlaying) +
  `MacroToolkit.assertScreenshotsIdentical` (missing fingerprint = loud FAIL) + docs (CLAUDE.md
  L2 list; MACRO-PATTERNS preamble mandate + the Undo / assert-by-byte-equality entries). Proof
  retrofits on macroStringWdgtEditDefersToPromptWhenCropped (3==4) and
  macroWindowCellsInConstrainedScrollStackReflow (1==3, 5==6) PASS at dpr 1 AND 2 with
  "PASS screenshots … are byte-identical" console lines; sanity probe green. NEGATIVE check
  verified: pointing the cropped-edit assertion at image_2 fails the test red with
  expected-vs-found hashes (then reverted + rebuilt + re-verified green). No references touched.
  Confirmed while implementing: the loader's reference-name regex only matches
  `takeScreenshot_InputEvents_Macro` literals, so the assertion call cannot confuse extraction;
  and the capture script's CAPTURE leg also replays in PLAYING state (the runner waits on
  Automator.IDLE after a normal play), so a broken pair already fails at capture, not just at
  the verify legs.

- **Batch 65 done (2026-06-12).** ENUMERATION (one-off script, grouping each test's SWCanvas
  reference filenames by dataHash): 28 tests have within-test identical reference groups, and
  dpr-1/dpr-2 AGREE on every one. CROSS-CHECK vs the 22 grep-claiming tests + metadata reads of
  the 8 tests whose identities are claimed in other words ("== image_1", "back to image_1's
  state", "unchanged", "same stacking"): RETROFITTED 33 assertions across 25 tests (every
  claimed within-test pair; groups of three anchored to the earliest shot). All 25 pass headless
  at dpr 1 with the expected PASS lines; dpr-2 spot checks green on macroStringWdgtImprovedSelection,
  macroWindowsNestedCollapsingUncollapsing, macroWrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved.
  No recaptures — references untouched. With Batch 64's two tests: **27 tests / 36 in-run
  byte-equality assertions** total. NON-TARGETS, recorded as decided:
  - `macroDuplicatedMenuAutoPinsOnDesktop` — its "byte-identical" phrase is provenance prose
    about the retired ORIGINAL's shots; this macro's own images are intentionally all distinct.
  - `macroSimpleDocumentRemovingLastParagraphUpdatesScrollbarAndLeavesViewportAtEndOfDocument` —
    claims REGIONAL identity only (viewport text image_4≈image_2; document region image_5==image_2)
    while the full screenshots legitimately differ (scrollbar/desktop); a whole-screenshot
    assertion cannot express it. A region-scoped assertion would be a separate construct.
  - UNCLAIMED accidental identity (listed, NOT asserted): `macroMenusCloseOnMouseDownOutside`
    image_4 == image_6 — real and stable (both shots are "dropped rectangle, cascade gone,
    pointer pressed at the same spot") but its metadata never claims the equality.
  - CROSS-TEST identity (out of scope for a within-test assertion):
    `macroLayoutsAndCollapsing` image_1/image_5 == `macroLayoutsAndVisibility`'s counterparts
    (documented in MACRO-PATTERNS.md; reference comparison still guards it transitively).

- **Batch 66 done (2026-06-12) — PLAN CLOSED.** Skill text updated in three spots
  (`.claude/skills/migrate-systemtest/SKILL.md`: the `Δprev: 0%` digest note, the authoring
  step 3 — which now mandates the in-run assertion for every designed pair — and the
  pin-survives-outside-click gotcha). Project memory updated (the byte-equality idiom bullet
  now points at `@assertScreenshotsIdentical` + this plan as the closed record). Final state:
  the harness records live fingerprints per test, 27 macros carry 36 in-run byte-equality
  assertions, recapture can no longer silently dissolve a pair, and the docs
  (src/macros/CLAUDE.md L2 list, MACRO-PATTERNS.md preamble, the skill) make the assertion
  mandatory for every future pair.

## Standing rules (inherited from the migration plan)

- ASK before any commit/push; per-batch commit pairs (Fizzygum-tests + Fizzygum when the
  toolkit/docs change); never commit Fizzygum's pre-existing package*.json refresh;
  comparison.html stays untracked.
- EVERY shell command gets its own absolute `cd /abs/path && ...`.
- FULL build (`cd ../Fizzygum && ./build_it_please.sh`) after ANY tests/ or harness
  change; the build's syntax gate compiles the FRAGMENTED way (e.g. it rejects multiline
  arrays containing only comments — keep `[]` one-liners).
- The harness `.coffee` and the toolkit ship as text and compile in-browser; `nil` not
  null; one class per file.

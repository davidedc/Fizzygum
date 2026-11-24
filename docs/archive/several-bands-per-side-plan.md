# Several bands per side — a slot holds a list, view mode hides only the tools, a toolbar docks at the depth it floats at

**Status: COMPLETE 2026-11-24.** Executed by the several-bands loop overnight 2026-11-23/24 in six units (U1b
added by the owner's O4 during U1), every one CLOSED, none parked; the commit pairs are in the unit table below. The
living truth is `docs/architecture/toolbars.md` (§1, §2, §4.4, §8, §9), `docs/architecture/layout.md` (§4.2, §4.3) and
`docs/architecture/visual-design-system.md` (the bar's pieces, the embedded toolbar row). Below, the plan as it was
executed, each phase with its Landed paragraph. Authored 2026-11-23, written to be executed COLD by an LLM/engineer
with ZERO prior context (the design session ran on another model; the executing session shares none of it). Every
fact below was read from the source, or measured on an in-page prototype, on 2026-11-23 at Fizzygum `b8f0e275`
and Fizzygum-tests `ee76daf2c`. Line numbers drift: a method's NAME and the quoted code are authoritative, so
grep them fresh before trusting a number.

**Mandate: transformation, not accommodation.** After this plan the rule "at most one docked frame per side"
does not exist anywhere: a side of a window holds a LIST of bands, no path destroys a band to make room for
another, and a content change retires only the band its content brought (O4). View mode puts away what is there for editing and nothing else. A toolbar's depth in a slot is a
record of the attachment, like every other payload's cross extent. Nothing is special-cased by payload class,
and no second mechanism is added beside the edge dock.

**Owner decisions.**

| # | Decision | State |
|---|---|---|
| O1 | View mode hides only TOOL bands; a docked document stays | RULED 2026-11-23 ("Yes only tools") |
| O2 | Several bands END TO END in one row (tiers) | OUT, ruled 2026-11-23 |
| O3 | The bar for this work: "keep Fizzygum compact and with only bang-for-the-buck features that COMPOSE" | RULED 2026-11-23 |
| D1 | A newcomer joins its side NEAREST THE CONTENT | RULED 2026-11-23, after the review page ("I agree with recommendations") |
| D2 | Two bands of one side stand as far apart as bands of different sides do where they meet (8 px on a Maker) | RULED 2026-11-23, as D1 |
| D3 | A docked document keeps the mode it docked with (no code; §10 files it) | RULED 2026-11-23, as D1 |
| D4 | The paint toolbar is TWO cells deep, in this plan | RULED 2026-11-23 ("I want this now rather than later with paint") |
| D5 | Today's corner rule stays (top and bottom span, the sides sit between); no drag to reorder | advised 2026-11-23, the owner said "go ahead" |
| D6 | A band's strip offers its collapse piece only where collapsing gives room back; a strip that shows no piece shows a GRIP MARK, a FIELD OF DOTS | proposed by the owner and RULED 2026-11-23, after the review page's section 7: "yes", and of the three looks "(b) a field of dots" |
| O4 | A content change retires ONLY the band its content brought (the content's own toolbar); every other band (one a person docked) stays where it is | RULED 2026-11-23 during U1, of three options (keep every band; float the person's out; this): "go with (a) and add to the loop, in the proper sequence and properly grouped if needed" |

**How this plan is run.** By the loop prepared in `Fizzygum-tests/.scratch/several-bands-loop/` (`BRIEF.md` is the
process, `LEDGER.md` the state, `LOOP-PROMPT.md` what the owner types), unattended, in six units (U1b added by the owner's O4 during U1). Where the brief
and §0.5 below disagree on PROCESS, the brief wins: the prompt's grants replace "wait for the owner's word", and
each unit recaptures its own pictures instead of one wave in Phase 4. Run WITHOUT the loop (a plain cold
execution, the owner present), §0.5 stands as written.

| Unit | What | Sections | State |
|---|---|---|---|
| U1 | A side holds a list of bands; a dock destroys nothing | §4 R1–R5, R8; Phase 0, Phase 1; Phase 4 test 1 | CLOSED 2026-11-24 (`b3f6ddf4` / `2827060f2`) |
| U1b | A content change retires only the band its content brought | §4 R12; Phase 1b; Phase 4 test 1b | CLOSED 2026-11-24 (`94596606` / `e9d27e551`) |
| U2 | View mode puts away only what is there for editing | §4 R6; Phase 2; Phase 4 test 2 | CLOSED 2026-11-24 (`85846e10` / `847337a4c`) |
| U3 | A toolbar docks at the depth it floats at; the paint toolbox is two cells deep | §4 R7, R9; Phase 3; Phase 4 test 3 | CLOSED 2026-11-24 (`fd223cd0` / `66ccddd54`) |
| U4 | A band's strip: its collapse piece only where it gives room back, a field of dots otherwise | §4 R10, R11; Phase 3b; Phase 4 test 4 | CLOSED 2026-11-24 (`622c3064` / `1ec64a7ae`) |
| U5 | Close | Phase 5 (what the units did not already write), Phase 6 | CLOSED 2026-11-24 (this archive) |

---

## §0 Orientation

### What this workspace is (one hop each)

Fizzygum is a CoffeeScript GUI framework drawn on one `<canvas>`. Three sibling repos under
`/Users/davidedellacasa/code/Fizzygum-all/`: `Fizzygum/` (source; the only place behaviour is edited),
`Fizzygum-tests/` (the SystemTest suite and its references), `Fizzygum-builds/` (generated; never edited). Read
`Fizzygum-all/CLAUDE.md`, `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md` before the first command, then
`Fizzygum/docs/architecture/toolbars.md` (whole) and `Fizzygum/docs/architecture/layout.md` §4.2. Every build
and test command goes through the wrapper, by ABSOLUTE path: `/Users/davidedellacasa/code/Fizzygum-all/fg <cmd>`
(bare `fg` prints the roster).

### Why this plan exists

Docking is general: any frame docks into any edge slot of a window, and the owner now composes windows that
way (a Docs Maker with a second toolbar docked at its left and a document docked at its bottom). Three things
stand in the way of that composition:

1. **A second dock on a side destroys the first.** `FrameWdgt._dockFrameNoSettle` runs
   `@dockedFrames[side]?._fullDestroyNoSettle()` before it adds the newcomer. A person who drops a toolbar on
   the top edge of a Docs Maker loses the Maker's text bar, with no warning and no undo.
2. **View mode hides every band, a docked document included**, because `_engageDocksNoSettle` disengages every
   dock. A window built from a document and a docked document shows half of itself in view mode.
3. **A toolbar is one cell deep in a slot, always.** `ToolbarWdgt.dockThickness` answers a theme dial
   (`Theme.toolRows`, 1). A person who shaped a floating toolbar into a two-cell column loses the shape at the
   dock. The paint revamp wants a two-column toolbox.

### The critical reframes

- **Only the cardinality changes.** A band stays an ordinary `FrameWdgt` carrying an `EdgeDockLayoutSpec`; it
  stays a direct child of its host; the hand's offer (`dockSideAt`) still answers a SIDE; the measure and the
  arrange keep their terms. A side's bands measure TOGETHER exactly as one thicker band would, then stand
  side by side inside that box. With one band per side every number is today's (measured: byte-identical
  render, §4).
- **Whether a band stands in view mode is the PAYLOAD's question.** The host asks the payload a capability
  ("are you an amenity for editing?"); a toolbar says yes; anything else is never asked twice. No class test.
- **Depth is a record of the attachment, in CELLS.** Every payload that declares no thickness already has its
  arrival extent recorded on the edge spec. A toolbar gets the same treatment, quantised: the spec records how
  many cells deep it stood when it arrived, and the toolbar turns the count into pixels at every measure, so
  the band still follows the theme.

### What is deliberately NOT in this plan

Drag-to-reorder and a choice of corners; bands end to end in a row; a resize control on a band; desktop-edge
docking; a holder's tray, a Maker declaring several bands, flyout cells (these three wait for the paint
revamp, §10). Do not build any of them here. The paint toolbar's two-cell depth IS here (D4).

---

## §0.5 Cold-execution protocol

1. Read the three `CLAUDE.md` files and the two architecture docs named above. Run
   `/Users/davidedellacasa/code/Fizzygum-all/fg status`: both source repos must be clean and the build FRESH
   (if STALE: `fg build`).
2. Do Phase 0, then Phases 1 to 6 IN ORDER (3b after 3). Phases 1, 2, 3 and 3b are separate behaviour
   changes: finish and gate each before starting the next. Phases 3 and 3b change many pictures by rule; in a
   plain execution their recapture is ONE wave, in Phase 4, after every source change is in (under the loop,
   each unit recaptures its own set, with the test of Phase 4 that belongs to it).
3. **The inner loop after every phase is `fg presuite`**, launched in the background with its output in a log
   (`fg presuite > /tmp/fg-presuite-run.log 2>&1`, `run_in_background: true`); read `/tmp/fg-presuite.verdict`
   at the end. Never pipe a gating `fg` call through `tail` or `grep`. Never run two `fg` long operations at
   once.
4. **Every failing test is ATTRIBUTED before anything is recaptured or edited**: name the rule of §4 that
   changes it, or it is a bug in the change. §5 predicts the failing set per phase; a test outside the
   prediction is a finding to understand, not a reference to refresh. See its pictures with
   `fg diffpage <SystemTest_name>`.
5. Single-test runs: `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node
   scripts/run-macro-test-headless.js SystemTest_<name> --all-logs`, and read every failure with
   `grep 'FAIL (assertion)'` (without `--all-logs` the runner prints only the tail). Add `--pointer=finger` for
   the finger run. A new test is proven with a FOLLOWER, on both pointers:
   `node scripts/run-sequence-headless.js SystemTest_<new> SystemTest_<any>`, zero `WORLD_INVENTORY_` lines.
6. Recapture only through `fg recapture --auto --dprs=1,2`, then
   `fg recapture --auto --pointer=finger --dprs=1,2`, and only after a fresh build. A "NEEDS RECAPTURE" on a
   test just captured is a finding (two runs of one build disagree), never a re-run.
7. **A gate finding is answered by its class** (`docs/architecture/lint-and-static-checks.md` §3b): an
   invariant is fixed at its cause; a convention is met or takes its marker with a real reason; a budget may
   be raised in the same change with a dated reason beside the number. Never bend a shape to fit a count.
   §5 names the budget this plan is expected to raise.
8. Stop and report to the owner when: two fix shapes for one problem have been falsified; a test outside §5's
   prediction changes and you cannot attribute it; a gate reports an invariant you cannot fix at its cause.
9. **Never commit or push without the owner's word.** At the end (Phase 6) present a summary, the review page
   and the proposed commit messages, and wait. Write commit messages to a file and use `git commit -F`.
   Use `git -C <abs repo>` for every git command. Never `git stash`.
10. Edit `.coffee` files with the Edit tool, never with a blanket script. The one mechanical edit this plan
    allows by script is Phase 1's `dockedFrames.<side>` reads in the tests (§5, Phase 1, step 5), and its diff
    is read line by line afterwards.

---

## §1 The mechanism as it stands (verified 2026-11-23)

All in `Fizzygum/src/FrameWdgt.coffee` unless a file is named. The dock family is about 40 members and 222
code lines of that file; the hand's part is about 22 lines of `src/ActivePointerWdgt.coffee`.

### §1.1 The slots

- `@DOCK_SIDES: ["top", "bottom", "left", "right"]`: the order the arrange places the sides in.
- `dockedFrames`: a `side -> FrameWdgt` map, built per instance in the constructor (`@dockedFrames = {}`).
  Its readers are all in this file: `_dockedFrameAt`, `_freeDockSlotOf`, `_isMyDockedFrame`,
  `_dockFrameNoSettle`, `_reflectDockVisibilityNoSettle`, `_engageDocksNoSettle`, `_dockedToolbarFrame`,
  `dockedPayloads`, `_retireDockedFramesNoSettle`, `_reSideMyDockNoSettle`.
- `_dockedFrameAt(side)`: the occupant WHEN IT COUNTS (still my child, its spec `engaged`, and I am not
  collapsed). The measure and the arrange read only this.

### §1.2 The measure and the arrange (they must agree: one home per term)

- `_bandThicknessUnder(dockSpec)` (asked of the BAND): what the spec grants the payload
  (`EdgeDockLayoutSpec.thicknessGrantedTo`) plus the band's own chrome across itself; collapsed, its strip.
- `_slotThicknessFor(bandThickness)`: `@_dockedBandInset() + bandThickness + @_bodyMargin()`, what a band takes
  out of the body.
- `_dockThicknessAt(side)`: `@_slotThicknessFor` of the counting occupant's thickness, else 0. The four named
  terms `_topDockThickness` … `_rightDockThickness` call it, and `_chromeBesidesStripsAcross`, `_chromeHeight`,
  `_chromeWidth` and `_payloadOffset` are built from those.
- `_bandBoundsAt(side, bandThickness, topDockThickness, stackHeight)`: where a band stands. Pure. Top and bottom
  bands span the body less the band inset at each end; left and right columns span the content's height.
- The tail of `_positionAndResizeChildren` places the bands:

  ```coffee
      topDockThickness = @_topDockThickness()
      for side in FrameWdgt.DOCK_SIDES
        dockedFrame = @_dockedFrameAt side
        continue unless dockedFrame?
        dockedFrame._reLayout @_bandBoundsAt side, (dockedFrame._bandThicknessUnder dockedFrame.layoutSpec), topDockThickness, stackHeight
  ```

- `bandBoxIfDocked(aFrame, side)` (public, asked by the hand at every pointer dispatch of a hover): the box
  `aFrame` would have, derived with nothing docked. Today it REPLACES the side's slot in the arithmetic
  (`chromeHeight += slotThickness - @_dockThicknessAt side`), because the occupant would go.
- `smallestExtentKeepingMyControlsUsable`: the floor a person's grip drag stops at; loops the sides and asks
  each counting band's payload `shortestDockedRun`.

### §1.3 Docking, leaving, re-siding

```coffee
  _dockFrameNoSettle: (aFrame, side) ->
    payload = aFrame.contents
    dockSpec = @_edgeDockSpecFor aFrame, side
    @dockedFrames[side]?._fullDestroyNoSettle()          # <- the destroyed occupant
    @_addNoSettle aFrame, notContent: true, layoutSpec: dockSpec
    @dockedFrames[side] = aFrame
    @_reflectDockVisibilityNoSettle()
    @_invalidateLayout()
    payload.noteDockedOn? @
```

`_reSideMyDockNoSettle(side)` (the band's "Dock ▸ side" row) destroys the target side's occupant the same way
(`host.dockedFrames[side]?._fullDestroyNoSettle()`). `_reactToChildRemoved` frees the slot of a band that
leaves (`_freeDockSlotOf`) and tells its payload `noteUndockedFrom`. `wantsDetachOfChild(aWdgt)` answers
`@_isMyDockedFrame aWdgt`, which is what lets a drag on a band's strip lift the band out.

The hand: `ActivePointerWdgt._dockBandUnderPointerFor` climbs from the widget under the pointer and asks each
frame `dockSideAt` (nearest first); a release over an offer adds the frame with `dockSide: side`, which
`FrameWdgt._addNoSettle` routes to `_dockFrameNoSettle`. `dockSideAt` answers nothing for a collapsed frame, a
pop-up, a frame in view mode or one standing in view-mode content. **None of the hand's code changes in this
plan.**

### §1.4 View mode

`showViewModeInBar` calls `@_engageDocksNoSettle false`, `showEditModeInBar` calls it with `true`. It sets
`engaged` on EVERY docked frame's spec; `_reflectDockVisibilityNoSettle` then hides what does not count.
`_edgeDockSpecFor` gives a fresh dock `engaged = @_myModeEngagesMyDocks()`.

### §1.5 A toolbar's depth

`EdgeDockLayoutSpec.thicknessGrantedTo: (payload) -> payload?.dockThickness?() ? @thickness`.
`ToolbarWdgt.dockThickness: -> @contents.naturalGridCrossExtent()` and
`ToolPanelWdgt.naturalGridCrossExtent: -> @_naturalRunFor @_stripDepthInCells(), 0`, where
`_stripDepthInCells` is `Math.max 1, WorldWdgt.theme.toolRows`. `_edgeDockSpecFor` records an arrival
thickness only for a payload with no `dockThickness`. The toolbar grid itself fills whatever box it is given
(`ToolPanelWdgt._layOutOwnContents`), so a deeper band already shows more columns with no grid change.

### §1.6 Who reads the map outside the source

- 29 test command files read `dockedFrames.<side>` as a frame, 74 reads in all
  (`grep -rnoE "dockedFrames\.(top|bottom|left|right)" Fizzygum-tests/tests --include="*_automationCommands.js"`).
- `Fizzygum-tests/scripts/menu-click-sweep-headless.js` reads `maker.dockedFrames.top` three times.
- `Fizzygum/src/macros/MACRO-PATTERNS.md` teaches `host.dockedFrames[side] == guest` (three passages: grep
  `dockedFrames`).
- Nothing in `src/` outside `FrameWdgt.coffee` reads it; the serializer and the duplicator treat it as an
  ordinary field.

---

## §2 Why it is shaped this way

The slot began as "the toolbar slot" of a Maker: one content, one toolbar. The frame-lifetime arc
(`docs/archive/frame-lifetime-and-docking-plan.md`, rulings C11–C13) turned it into a placement any frame can
take and gave a window four of them, "at most one per side" being the smallest generalisation of one toolbar.
Replacing the occupant was the cheapest answer to "the side is taken", and nothing then docked two things on a
side. View mode's blanket disengage dates from when every band was a toolbar. The one-cell depth is a theme
dial because, until a person could dock a toolbar they had shaped themselves, every toolbar in a slot was one
a Maker built.

## §3 The distilled argument

- The destruction is the one place in the dock family where a gesture loses the person's work silently. A
  list removes the case instead of guarding it.
- A list costs almost nothing: a side's bands measure together as one band of
  `sum of slots - (band inset + body margin)` would, so `_slotThicknessFor`, `_bandBoundsAt`, the four named
  thickness terms, `_chromeHeight`, `_chromeWidth` and `_payloadOffset` are untouched, and `bandBoxIfDocked`
  gets SIMPLER (it adds a slot instead of swapping one). Estimated net source change for Phase 1: about zero
  lines.
- It was run, not argued: the whole suite under an in-page prototype of all three phases, live in 8 of 8
  shards, passes 463 of 465 tests at density 1, and the two failures are exactly the two tests that assert the
  replacement (§5, "Predicted failing set").
- Alternatives that looked more general were weighed and rejected for cause (§8).

---

## §4 The target state (measured on the prototype)

The prototype is `Fizzygum-tests/.scratch/slotting-proto/` (gitignored, this machine): `proto-patch.js` (the
three phases as in-page overrides), `probe.js` (the scenes), `review.html` (the owner's review page, renders in
`out/`), `suite-prelude.js` and `suite-under-proto-2.log` (the suite run). It is a reference for BEHAVIOUR, not
for code: it routes the arrange through a stand-in object to avoid rewriting it in the page. Write the source
as §5 says.

**The rules.**

- **R1.** A side of a window holds its bands in a list, OUTERMOST FIRST. A frame docked on a side joins that
  list at its END: nearest the content. Nothing is destroyed.
- **R2.** A side's bands stand side by side from the body's edge inward. Two bands of one side stand
  `@_dockedBandInset() + @_bodyMargin()` apart, the distance bands of different sides already keep where they
  meet. Measured on a Docs Maker 580 wide: top bands at y 74 and y 128, each 46 deep (8 between); left bands at
  x 29 and x 83, each 46 wide.
- **R3.** With one band per side nothing moves: the owner's composite renders byte-identical with and without
  the prototype.
- **R4.** The corner rule is today's: top and bottom bands span the body, left and right columns stand between
  them.
- **R5.** A band that leaves (dragged out, floated, destroyed, re-sided) leaves its list; the others close up.
  A band re-sided by its "Dock ▸ side" row joins the new side nearest the content.
- **R6.** View mode disengages a band exactly when its payload answers `isAnAmenityForEditing` true (a
  toolbar). Any other band (a docked document, a palette field, a band whose payload left) stands in both
  modes. While the host views, a band stays where it is: a drag on its strip moves the host, and its "Dock" and
  "Float" rows are not offered. Measured: a text window docked at the bottom of a viewing Docs Maker, dragged by
  its strip 160 right and 90 down, moved the Maker by exactly that and stayed in its list.
- **R7.** A payload that measures itself in cells (a toolbar) docks at the depth it STANDS at when it arrives
  from somewhere (a window on the desktop, a frame on the hand): the number of whole cells its SHORTER side
  holds. A frame fresh from its constructor (a Maker's own toolbar) has no shape of its own and docks at the
  toolbar's own depth, as today. Measured: a floating toolbar 94 across (two cells) dropped on a Slides
  Maker's left edge outlines, then makes, a band at x 83, 96 wide, beside the Maker's own 46 wide one.
- **R8.** The outline the hand shows over an offer is still the band the release makes (the existing rule),
  now for a joining band and at its arrival depth.
- **R9.** A toolbar has a depth of its own, in cells: the theme's `toolRows` (1) unless its class states one.
  The paint toolbar states 2 (D4). It is the depth a toolbar is born at floating (its window hugs two columns)
  and the depth a Maker's own toolbar docks at. Measured: a Drawings Maker's toolbox band 96 wide, the four
  tools in a 2 × 2 grid; a floating paint toolbar 96 × 199.
- **R10 (D6).** A band's strip offers its collapse piece only where collapsing gives room back: where the band,
  expanded, is thicker than its own strip, or while it is collapsed (the way back). A strip is 46 across and a
  one-row toolbar band is 46 deep, so such a band shows no piece; a two-cell toolbox (96) and a docked document
  keep theirs. A window on the desktop always offers it. Measured in the page: on the owner's composite the
  four one-row toolbar bands lose the piece, the docked document keeps it.
- **R12 (O4).** A window whose content changes (its content leaves it by any door, a widget dropped into it
  becomes its content, a Maker rebuilds its payload) retires only the band its content BROUGHT: the toolbar the
  window docked for that content (`FrameWdgt._buildDockedToolbarNoSettle`, reached by the window's construction and
  rebuild and by its "Toolbar" row). Every other band stays where it is, in its list, alive. A Maker whose payload is
  rebuilt keeps its own band: the Maker's KIND declares that toolbar, not the payload that left (ruled in U1b from
  O4; a retire-and-rebuild would move the bar under a person's band, lose its re-side and collapse, and reset a
  Drawings Maker's tool). The window offers its
  content's toolbar (the rebuild, the "Toolbar" row) while no band its content brought is docked, whatever else is.
- **R11 (D6).** A band's strip that shows no piece shows a GRIP MARK, a field of dots centred in it: the strip is the band's handle,
  and a bare grey square does not say so. It is paint, not a control: a press anywhere on the strip is still
  the strip's. A strip too short for its piece (a band 41 deep) shows the mark too, for the same reason.

---

## §5 The fix, by phase

### Predicted failing set (dpr 1, mouse; the finger and dpr 2 legs follow the same two tests)

Measured by `node scripts/run-all-headless.js --prelude=<suite-prelude.js>` on 2026-11-23: 465 tests, 2 failed,
0 gate violations, the patch reported installed in 8 of 8 shards.

| Test | Why it changes | What to do |
|---|---|---|
| `SystemTest_macroDockOutlineIsTheBandItMakes` | its case 4 asserts a toolbar "docked in the top slot, in the text bar's place" (R1); its palette windows are built at the default 300 × 300, whose payload is 298 × 211, four cells on the shorter side, so under R7 they dock four deep and images 0–2 change | rewrite case 4 to the joining band (Phase 1); give each palette window `sizeToPayloadNaturalExtent()` before `world.add`, as the product's own openers do, so the test keeps its subject (Phase 3) |
| `SystemTest_macroViewModeWindowOffersNoDockSlot` | asserts that a guest released over a docked bar in edit mode becomes `host.dockedFrames.top` (R1): it now joins under the bar | rewrite that assertion and recapture its image 1 (Phase 1) |

The prototype kept `dockedFrames.<side>` readable as "the outermost band", so the 29 files of §1.6 pass under
it; in the real change they are edited mechanically (Phase 1, step 5). Any OTHER failing test is outside the
prediction: attribute it before touching it (§0.5 step 4).

Known benign rider: a change to `FrameWdgt`'s member list can shift the member list an inspector shows for a
window, and with it a scroll offset in an inspector test. If such a test fails with a diff confined to an
inspector's list, it is benign churn: name it in the unit's predicted set and recapture it with the rest,
through `fg recapture --auto` (never `fg recapture-inspector`).

### Phase 0 — re-verify, no source change

1. `fg status`; confirm the heads or note what moved since `b8f0e275` / `ee76daf2c`.
2. Re-grep §1's facts: `grep -nE "dockedFrames|_dockedFrameAt|DOCK_SIDES" Fizzygum/src/FrameWdgt.coffee`
   (expect the readers §1.1 lists), and the 29/74 count of §1.6.
3. Open `Fizzygum-tests/.scratch/slotting-proto/review.html` if it is there. If the directory is gone the plan
   is still complete: §4 is the specification.

### Phase 1 — a list per side (R1–R5, R8)

**1. The field and the constructor.** Rewrite `dockedFrames`'s comment for the new shape (a
`side -> [FrameWdgt, …]` map, outermost first, a newcomer joins at the end) and build the four lists per
instance where the constructor has `@dockedFrames = {}`:

```coffee
    @dockedFrames = {}
    for side in FrameWdgt.DOCK_SIDES
      @dockedFrames[side] = []
```

**2. The readers.** Delete `_dockedFrameAt`. Add, beside the other slot terms:

```coffee
  # The frames docked at `side` THAT COUNT, outermost first: each still my child, its dock engaged
  # (view mode disengages a band that is there for editing), and my body there to hold it -- a
  # collapsed frame is just its titlebar. Pure reads: the measures consume these.
  _bandsAt: (side) ->
    return [] if @contents?.collapsed
    (band for band in (@dockedFrames?[side] ? []) when band.parent == @ and band._myEdgeDockSpec()?.engaged)

  # Each counting band's own thickness at `side`, outermost first.
  _bandThicknessesAt: (side) ->
    (band._bandThicknessUnder band.layoutSpec for band in @_bandsAt side)

  # Every frame in my slots, in my slots' order (DOCK_SIDES, then outermost first), counting or not.
  _framesInMySlots: ->
    frames = []
    for side in FrameWdgt.DOCK_SIDES
      frames = frames.concat (@dockedFrames?[side] ? [])
    frames
```

**3. The measure.**

```coffee
  _dockThicknessAt: (side) ->
    thickness = 0
    for bandThickness in @_bandThicknessesAt side
      thickness += @_slotThicknessFor bandThickness
    thickness
```

`_bandBoundsAt` stays as it is. Add the one new placement term, which asks it for the box of the side's bands
TOGETHER and cuts that box:

```coffee
  # WHERE EACH BAND OF ONE SIDE STANDS, outermost first, given each one's thickness. The side's bands
  # measure together as one band would -- their slots, less the inset and the margin _bandBoundsAt adds
  # around the whole -- and stand side by side inside that box from its OUTER edge inward, each a slot
  # past the one before, so two bands of a side stand as far apart as bands of different sides do
  # where they meet. PURE, and the one home of the placement: my arrange places the bands I hold by it
  # and the picture of a dock not yet made asks it the same terms (bandBoxIfDocked).
  _bandBoxesAt: (side, thicknesses, topDockThickness, stackHeight) ->
    return [] if thicknesses.length is 0
    together = -(@_dockedBandInset() + @_bodyMargin())
    for thickness in thicknesses
      together += @_slotThicknessFor thickness
    whole = @_bandBoundsAt side, together, topDockThickness, stackHeight
    offset = 0
    for thickness in thicknesses
      box = switch side
        when 'top' then (new Rectangle new Point whole.left(), whole.top() + offset).setBoundsWidthAndHeight whole.width(), thickness
        when 'bottom' then (new Rectangle new Point whole.left(), whole.bottom() - offset - thickness).setBoundsWidthAndHeight whole.width(), thickness
        when 'right' then (new Rectangle new Point whole.right() - offset - thickness, whole.top()).setBoundsWidthAndHeight thickness, whole.height()
        else (new Rectangle new Point whole.left() + offset, whole.top()).setBoundsWidthAndHeight thickness, whole.height()
      offset += @_slotThicknessFor thickness
      box
```

Check it by hand for ONE band before building: `together` is the band's own thickness and the slice is the
whole box, so every number is today's. The arrange's tail becomes:

```coffee
    topDockThickness = @_topDockThickness()
    for side in FrameWdgt.DOCK_SIDES
      boxes = @_bandBoxesAt side, (@_bandThicknessesAt side), topDockThickness, stackHeight
      for band, i in @_bandsAt side
        band._reLayout boxes[i]
```

Keep the long comment above that tail (why the bands are driven through `_reLayout` with bounds) and reword
its first line for "each side's bands".

`bandBoxIfDocked` adds a slot where it swapped one:

```coffee
  bandBoxIfDocked: (aFrame, side) ->
    dockSpec = @_edgeDockSpecFor aFrame, side
    bandThickness = aFrame._bandThicknessUnder dockSpec
    slotThickness = @_slotThicknessFor bandThickness
    topDockThickness = @_topDockThickness() + (if side is "top" then slotThickness else 0)
    chromeHeight = @_chromeHeight()
    chromeWidth = @_chromeWidth()
    if side is "top" or side is "bottom"
      chromeHeight += slotThickness
    else
      chromeWidth += slotThickness
    boxes = @_bandBoxesAt side, ((@_bandThicknessesAt side).concat [bandThickness]), topDockThickness, (@_steadyContentHeight @width(), chromeWidth, chromeHeight)
    aFrame._bandBoxTakenOf boxes[boxes.length - 1], dockSpec
```

Rewrite its comment: the frame would stand NEAREST THE CONTENT on its side, beside whatever holds the side
now.

**4. The doors.**

- `_dockFrameNoSettle`: delete the `_fullDestroyNoSettle()` line; `@dockedFrames[side] = aFrame` becomes
  `@dockedFrames[side].push aFrame` (still AFTER the add, for the reason its comment gives). Reword the comment's
  "An occupied slot's previous holder is set free first -- one frame per side".
- `_reSideMyDockNoSettle`: delete its `_fullDestroyNoSettle()` line; `host.dockedFrames[side] = @` becomes
  `host.dockedFrames[side].push @`.
- `_freeDockSlotOf(child)`: `@dockedFrames[side] = (each for each in @dockedFrames[side] when each isnt child)`
  for each side, behind `return unless @dockedFrames?`. In `_reactToChildRemoved` call it only when
  `wasDocked`, so an ordinary child leaving allocates nothing.
- `_isMyDockedFrame(aWdgt)`: `aWdgt in @_framesInMySlots()`.
- `_reflectDockVisibilityNoSettle`: for each side, `counting = @_bandsAt side`, then for each frame of
  `@dockedFrames?[side] ? []` that is still my child, `show()` if it is `in counting`, else `hide()`. KEEP the
  `# public-call-sanctioned:` comment on the show/hide line, word for word: the layering gate reads it.
- `_engageDocksNoSettle(engaged)`: loop `@_framesInMySlots()` (Phase 2 changes what it writes).
- `_dockedToolbarFrame`, `dockedPayloads`: over `@_framesInMySlots()`, the same `parent` tests as today.
- `_retireDockedFramesNoSettle`: take `@_framesInMySlots()`, empty the four lists, THEN destroy each (the slot
  is cleared before the destroy today too).
- `smallestExtentKeepingMyControlsUsable`: `for side …` / `for band in @_bandsAt side`, the same body per
  band. If the complexity gate reports the function over 15, lift the per-band floor into a helper
  (`_floorKeepingBandUsable band, side, emptyWidth, emptyHeight`, answering a `Point` or nothing) instead of
  flattening the logic.
- The comments naming one frame per side: the header of `src/EdgeDockLayoutSpec.coffee` ("at most one docked
  frame per edge"), `dockedPayloads`, `dockSideAt`'s block, `wantsDetachOfChild`. Reword each in the present
  tense for a list; a comment is a deliverable.

**5. The readers outside the source (§1.6).** `dockedFrames.<side>` named ONE frame; with one band per side
`dockedFrames.<side>[0]` names the same one. Replace the token in the 29 test command files and in
`menu-click-sweep-headless.js`:

```sh
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests
grep -rlE "dockedFrames\.(top|bottom|left|right)" tests scripts --include="*.js" \
  | xargs perl -pi -e 's/dockedFrames\.(top|bottom|left|right)(?!\[)/dockedFrames.$1\[0\]/g'
git -C /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests diff --stat
```

The pattern touches no leading whitespace. Then READ the diff, every hunk: each read must still say what its
test means. A test that walks the map another way (`Object.keys`, `for side of`, `dockedFrames[side]`) is not
caught by the pattern: `grep -rn "dockedFrames" tests scripts --include="*.js" | grep -v "\[0\]"` and fix each
by hand. Any `visualisation.html` is generated and is not edited. Update the three passages of
`Fizzygum/src/macros/MACRO-PATTERNS.md` (`guest in host.dockedFrames[side]`).

**6. The two predicted tests.** Rewrite `macroDockOutlineIsTheBandItMakes` case 4 and the one assertion of
`macroViewModeWindowOffersNoDockSlot` to R1: the guest is the LAST of `host.dockedFrames.top`, the bar that was
there is still the first, still alive (`!textBar.destroyed`), and the outline seen during the hold is the box
of the docked guest (the existing check, unchanged). Update each test's `scenario`, `assertions` and step
comments, then run `fg visualise SystemTest_<name>` for a test whose prose changed and whose pictures did not
(a capture rewrites the page itself; the gauntlet's `refs` leg fails on a stale one).

**7. Gate, then recapture.** `fg presuite`. Expected failures: the two tests (their rewritten assertions pass;
their images differ where a band joins). Attribute, `fg diffpage` each, then recapture both pointers. Expected
static-gate findings and their answers:

- `buildSystem/check-complexity-ratchets.js`, `METHOD_CEILINGS.FrameWdgt` (176): this phase is +3 methods (`_bandsAt`,
  `_bandThicknessesAt`, `_framesInMySlots`, `_bandBoxesAt` in; `_dockedFrameAt` out), +4 with the floor helper.
  A budget: raise it in the same change, with a dated sentence continuing that entry's own history ("for the
  several bands of a side: …"), under the owner's standing ruling it already cites.
- A complexity record for `FrameWdgt#_positionAndResizeChildren` (46): if the tail's inner loop raises it, the
  same class of answer; if the score falls, lower the record to the new score.
- Anything else is not predicted: read the gate's own advice row first.

**Landed 2026-11-23 (U1 of the several-bands loop).** Built as steps 1–6 say, with these corrections, measured:
the per-band floor is its own method, `_floorKeepingBandUsable (band, side, emptyWidth, emptyHeight)` (with the
nested loop inline `smallestExtentKeepingMyControlsUsable` scores 18; lifted, 10 and 5); the `# public-call-sanctioned:`
comment on the show/hide line is read by no gate (call-separation [S] reads that marker, for `@`-self calls only) and
stays for its reason; `dockSideAt`'s comment needed no change, while about twenty FrameWdgt comments, the
`EdgeDockLayoutSpec` header and `docs/specs/drag-embed-interaction-spec.md` (the outline over a held side) did.
Program ruling C12's "one per side" is amended by this plan (D1, D2, O2): a side's slot is a list. A consequence
the plan states only in Phase 5 lands here, in `toolbars.md` §4.4: a palette dropped onto a side another palette
holds joins it, so the host keeps its own tool. The scripted `[0]` edit touched 30 files (74 reads in 29 tests, 3
in the menu sweep); every read keeps its meaning but the two this step rewrites by hand. Test 1,
`SystemTest_macroSecondBandJoinsItsSide`, checks R2 by EQUALITIES of laid-out gaps (layering rule [D] bans a
private read in a macro, so "read both terms off the host" became "the gap between two bands of a side equals the
gap where the top meets the left column", 8 = 8); its guests are hugged one-row toolbar windows, so Phase 3 leaves
it alone and Phase 3b changes its strips. Bites: the dock door destroying the side's bands, the re-side door
destroying the target side's, a copy sharing the original's lists, each failing its own assertion under both
pointers; its follower clean on both. Presuite: the predicted two failed, on pictures only (DockOutline images 1
and 2, ViewModeWindowOffersNoDockSlot image 1), recaptured. The unit's review found no behaviour defect; it found the
sum of a side's slots computed twice (the measure and the placement), now one term, `_sideThicknessFor`, and two
rules bitten only as side effects, now each by its own plant (the outline keeping the one-band swap; a side's bands
standing flush). Ratchet: `METHOD_CEILINGS.FrameWdgt` 176 → 181 (`_bandsAt`, `_bandThicknessesAt`,
`_sideThicknessFor`, `_bandBoxesAt`, `_framesInMySlots`, `_floorKeepingBandUsable` in; `_dockedFrameAt` out);
`_positionAndResizeChildren` stays at 46.

### Phase 1b — a content change retires only the band its content brought (R12, O4)

Added 2026-11-23 by the owner's ruling O4, during U1, after U1's review traced it (`FrameWdgt` at U1's tree): the
three content-change doors, `FrameWdgt._resetToDefaultContents` (a content that LEAVES: the placeholder comes
back), `FrameWdgt._reactToChildDropped` (a widget dropped into an empty window becomes its content) and
`MakerDocumentWdgt._resetToDefaultContents` (a Maker whose payload left builds a fresh one), each call
`_retireDockedFramesNoSettle`, which destroys EVERY band in the window's slots, a window a person docked included,
with what it holds (a docked text window's typing): silently, with no undo. The rule dates from when a slot held
only the content's own toolbar (the method was `_destroyToolbarNoSettle` before docking took any frame); no ruling
gives a reason for destroying a band the content did not bring. With several bands a side, the collision that
replacing used to avoid is gone. The rebuild's guard (`@_buildDockedToolbarNoSettle() unless
@_dockedToolbarFrame()?`) and the host's "Toolbar" row (`_offersAFreshToolbar`) ask whether ANY band is docked; under
R12 they ask whether a band the content brought is.

The shape is the unit's research's to propose on its merits and verify: how the window knows which band its content
brought (a RECORD of the attachment on the band's `EdgeDockLayoutSpec`, written by the one door that docks a content's
variant, which copies and saves with the band, is the expected shape; derive it if a derivation exists that a
person's own second copy of the same toolbar class cannot fool, as U1's test docks one); what a content toolbar
floated away and docked back by a person is (a fresh spec: the person's); what each of the three doors keeps; what a
Maker's rebuild of its own payload does with its own band (retired and rebuilt, or kept). Find every reader of
`_dockedToolbarFrame` and `_retireDockedFramesNoSettle` in both repos. The noted-not-queued line on
`_offersAFreshToolbar` (this plan's ledger) closes with this phase.

**Test 1b, `SystemTest_macroContentChangeKeepsThePersonsBands`** (R12). A window whose content brought a toolbar,
with a band a person docked beside it (a text window holding typed text, and a second toolbar): the content leaves
by a door a PERSON has (the unit's research names it and the mode it needs); the content's own toolbar is retired,
the person's bands stay alive in their lists, the text keeps its typing; a new content arrives (a drop into the
emptied window, or the Maker's rebuild) and its own toolbar docks beside them. Both pointers, dpr 1 and 2, the
follower proof, and plants: the retirement destroying every band (the old rule); the rebuild's guard asking for any
band.

**Landed 2026-11-24 (U1b of the several-bands loop).** The record is `EdgeDockLayoutSpec.broughtByContent`
(class-level false), written only by `_buildDockedToolbarNoSettle` right after its dock (the spec builder stays pure:
the hover's outline shares it) and cleared by `notePayloadLeft`. `_dockedToolbarFrame` (which answered any band) is
`_bandsMyContentBrought`, a list over every band still a child, counting or not (a disengaged or collapsed content
band still counts); the retirement, `_retireBandsMyContentBroughtNoSettle`, frees and destroys only those; the
rebuild's guard and `_offersAFreshToolbar` ask whether that list is empty. No derivation could stand in for the record:
a person's second copy of the content's toolbar class fools a class match (U1's test docks one). Ruled in the unit:
a Maker keeps its own band when its payload is rebuilt (R12's last sentence), and `_reactToChildDropped`'s retirement
is deleted (an empty window wears no band its content brought). A defect found on the way and fixed at its cause
(`Fizzygum-tests/.scratch/several-bands-loop/u1b/investigate/REPORT.md`): a band built inside the settle that docks it
took the first-placement negotiation's height (its payload's 50×40 construction extent: a 40 px viewport in a 44 grant,
a 46×87 stub in a side column), reached by the rebuild and the "Toolbar" row; a band's first placement now negotiates
nothing, in the arrange and the measure (`layout.md` §4.3). Test 1b, `SystemTest_macroContentChangeKeepsThePersonsBands`
(a person's note and Slides bands survive two page leaves with the note's typing; the "Toolbar" row offered exactly
while the content's band is gone; a fresh bar fills its grant, as deep as the bar born with the Maker; an emptied band
loses the record; on a plain window a person's band survives a drop and a leave), bitten by seven plants (the old rule
at the Maker's door, at the drop door and at the leave door, the guard asking for any band, the record never written, an
emptied band keeping it, the band negotiating its first placement), each failing its own assertion under both pointers;
its follower clean on both. The unit's review found the rule correct at every door and the two plain-window doors
untested (now the test's last leg), and one rewritten assertion short of its witness (WindowWhoseContentLeaves L3 reads
the toggle, the band and the fresh document together). Three value assertions of existing tests rewritten (WindowWhoseContentLeaves L1 and L3, TiltedMaker… L1: the
Maker keeps its band) and PanePickedUp…'s prose. Ratchets: `FrameWdgt#_positionAndResizeChildren` 46 → 47 and
`FrameWdgt#preferredExtentForWidth` 17 → 18 (the band's condition); FrameWdgt stays at 181. Filed: Attach onto an
occupied window orphans its content (medium); a Maker dropped into an empty window gets a second text bar; a pinned
"Toolbar" submenu docks one more bar per click; a toolbar window put into another window shows a clipped strip (the
free-window sibling of the defect, an owner question).

### Phase 2 — view mode hides only the tool bands (R6)

1. `src/app-kit/ToolbarWdgt.coffee`, beside `identifiesItself`:

   ```coffee
     # I AM THERE FOR EDITING: my tools change the content of the window I work for, so a window that
     # holds an edit mode puts my band away while it is viewing (FrameWdgt._engageDocksNoSettle asks,
     # as a capability: a payload with no answer stands in both modes).
     isAnAmenityForEditing: ->
       true
   ```

2. `FrameWdgt._engageDocksNoSettle(engaged)`: per frame,
   `wanted = engaged or not dockedFrame.contents?.isAnAmenityForEditing?()`, and write `wanted` where it wrote
   `engaged`. Keep the `engaged` PARAMETER (the mode's answer is handed in by `showEditModeInBar` /
   `showViewModeInBar`; do not re-read the mode here). Rewrite its comment: viewing puts away what is there
   for editing; any other band stands.
3. `FrameWdgt._edgeDockSpecFor`: `dockSpec.engaged = @_myModeEngagesMyDocks() or not payload.isAnAmenityForEditing?()`.
4. A viewing host keeps its bands where they are:

   ```coffee
     wantsDetachOfChild: (aWdgt) ->
       @_isMyDockedFrame(aWdgt) and @_myModeEngagesMyDocks()
   ```

   and the band's own rows and verbs ask that one public answer of the host:
   in `addWidgetSpecificMenuEntries`, `if @_myEdgeDockSpec()? and @parent.wantsDetachOfChild @`; in
   `floatOutOfDock` and `_reSideMyDockNoSettle`, return unless `@parent?.wantsDetachOfChild? @` (in the second
   it replaces the `_isMyDockedFrame?` test). `dockSideAt` is unchanged: a viewing window still offers no
   slot.
5. `fg presuite`. No test is predicted to change (the suite docks only toolbars into windows it then flips,
   and a toolbar still hides). `SystemTest_macroViewModeDisengagesDocks` must pass untouched.

**Landed 2026-11-24 (U2 of the several-bands loop).** Built as steps 1–4 say, with the rule given ONE home where the
plan wrote it twice: `EdgeDockLayoutSpec.engagedUnder (hostEngagesEveryDock, payload)`, a pure query beside
`thicknessGrantedTo` (the spec already asks its payload a capability), read by `_engageDocksNoSettle` per band and by
`_edgeDockSpecFor`. The host send is guarded the same way everywhere (`@parent?.wantsDetachOfChild? @`: the band's
rows, `floatOutOfDock`, `_reSideMyDockNoSettle`). `_myModeEngagesMyDocks` keeps its name; it answers whether my mode
engages EVERY dock. `ToolbarWdgt.isAnAmenityForEditing`'s comment states its difference from
`providesAmenitiesForEditing` (a container that HOLDS a mode). The research corrected §6: a docked document's content
is view-only while a MAKER host views; a plain window whose mode lives in its content does not reach a band. Test 2,
`SystemTest_macroViewModeHidesOnlyToolBands`, takes its identity pair before its refusals (a strip drag moves the host,
which would break the pair), drags the strip by point under each pointer (`titleGrabPoint` refuses a band its viewing
host keeps), and is bitten by three plants (every band disengaged; the host letting a band go in any mode; the rows
offered on the edge spec alone, the Float verb ignoring the viewing host — a pinned menu's "Float" pressed while the host
views), each failing its own assertion under both pointers. Presuite: no existing test changed, as predicted (468 and
455 under the finger). No ratchet moved. The unit's review found the rule right on its door, and two claims too wide: a
viewing window's composition is not fixed (the dev menu's generic rows still act on a band; reworded to "the gestures
that compose it refuse"), and a docked MAKER stands in its host's view mode with its own toolbar shown (R6 asks the
payload, D3 keeps the docked window's mode): filed as an owner question. Not worked (the plan's ledger already notes the pinned rows): a band whose
payload is swapped while a PLAIN host views keeps its engagement until the next flip (reached only through dev menus).

### Phase 3 — a toolbar docks at the depth it floats at (R7)

1. `src/EdgeDockLayoutSpec.coffee`: a field and the pass-through.

   ```coffee
     # how many cells deep my carrier's payload stands, for a payload that measures itself in cells (a
     # toolbar) and arrived with a shape of its own; undefined otherwise, and the payload then answers
     # its own depth. A COUNT, so the pixels it means are derived at every measure, in the theme of the
     # world that lays the band out.
     depthInCells: undefined

     thicknessGrantedTo: (payload) ->
       payload?.dockThickness?(@depthInCells) ? @thickness
   ```

   Rewrite the class header's thickness paragraph to say so.
2. `src/app-kit/ToolPanelWdgt.coffee`:

   ```coffee
     naturalGridCrossExtent: (depthInCells) ->
       @_naturalRunFor (depthInCells ? @_stripDepthInCells()), 0

     # how many whole cells a run ACROSS a strip holds (a strip has no padding across itself)
     cellsAcross: (run) ->
       @_cellsFittingIn run, 0
   ```

3. `src/app-kit/ToolbarWdgt.coffee`:

   ```coffee
     dockThickness: (depthInCells) ->
       @contents.naturalGridCrossExtent depthInCells

     # THE DEPTH I STAND AT NOW, in cells: what my shorter side holds. A band asks it as I arrive from
     # somewhere, so I dock at the depth I floated at (FrameWdgt._edgeDockSpecFor). Collapsed I show no
     # grid and answer nothing.
     depthInCellsAsIStand: ->
       return undefined if @collapsed
       @contents.cellsAcross Math.min @width(), @height()
   ```

   Update `dockThickness`'s comment (it is still pure: a count and theme dials).
4. `FrameWdgt._edgeDockSpecFor`, after the spec is built:

   ```coffee
       # a payload that measures itself in cells keeps the depth it STANDS at where it stands somewhere
       # (a window on the desktop, a frame on the hand); a frame fresh from its constructor has no shape
       # of its own yet, and its payload answers its own depth
       dockSpec.depthInCells = payload.depthInCellsAsIStand?() if aFrame.parent?
   ```

   Measured why the `parent` test is needed: a fresh `new FrameWdgt new PaintToolbarWdgt` is 300 × 300 with a
   298 × 211 payload and no parent, which the shorter-side rule would read as four cells.
5. **A toolbar's own depth (R9, D4).** `src/app-kit/ToolbarWdgt.coffee`, a class-level field beside `dockSide`:

   ```coffee
     # MY OWN DEPTH, in cells: how many cells deep my strip is where nothing else says (a band's edge
     # spec does, for a toolbar that arrived with a shape of its own). undefined: the theme's toolRows.
     # A per-type class default, like dockSide.
     depthInCells: undefined
   ```

   `src/authoring/PaintToolbarWdgt.coffee`: `depthInCells: 2`, with one line saying why (a toolbox, two
   columns). `src/app-kit/ToolPanelWdgt.coffee`, the one reader:

   ```coffee
     _stripDepthInCells: ->
       Math.max 1, (@parent?.depthInCells ? WorldWdgt.theme.toolRows)
   ```

   (`@parent` is the viewport around the grid, as in `_layOutOwnContents`'s `@parent?.widthContentsMustFitWithin?()`;
   a grid in a plain viewport reads the theme.) Nothing else changes: `naturalGridCrossExtent` and the
   floating hug (`naturalGridExtentWithin`) both read `_stripDepthInCells`.
6. `macroDockOutlineIsTheBandItMakes`: `palette.sizeToPayloadNaturalExtent()` before `world.add palette` in
   its `paletteWindow` helper (the product's own openers do the same; a default 300 × 300 toolbar window would
   dock four deep). Its palettes then dock at the paint toolbar's own two cells.
7. `fg presuite`. Predicted failing set, measured with the paint depth on (465 tests, 15 failed, the
   patch live in 8 of 8 shards): the two tests of Phase 1, and thirteen that show a paint toolbar.
   - ONE assertion to update: `SystemTest_macroToolbarBandIsAsDeepAsAStrip`, "a floating toolbar's window is as
     wide: Slides, Paint, Sheet, Super", expected `46,46,46,46`, found `46,96,46,46`. Read the test: its subject
     is a ONE-row band; state the paint toolbox's two cells as its own fact (from the grid's measures, never
     the literal 96).
   - TWELVE pixel-only (a paint toolbox two cells deep, or a floating one two columns wide):
     `macroDimmedToolsWakeWithTheirSubject`, `macroDockedCreatorPlacesOnlyIntoItsHost`,
     `macroDockedTextBarActsOnlyInItsWindow`, `macroDrawingTakesNoClickPlacedWidget`,
     `macroDrawingToolReachesEveryDrawingOfItsHolder`, `macroDrawingsMakerReEnableEditing`,
     `macroEditModeSlidingToggle`, `macroMixedToolbarKeepsEveryLookCurrent`,
     `macroPageSelectionRingInWindowGutter`, `macroPencilPaintsStrokeOnLeftDrag`,
     `macroPaletteDockUndockKeepsTheTool`, `macroTwoDrawingsKeepTheirOwnTools`. Attribute each with
     `fg diffpage` (the only change is the toolbox's shape and what it moves); recapture them in Phase 4's
     wave, not here. ⚠ A test that CLICKS a paint tool by a position it computed from a one-column strip would
     show as an assertion failure, not a picture: none did in the measured run.

**Landed 2026-11-24 (U3 of the several-bands loop).** Built as steps 1–6 say, but for step 5's reader: the TOOLBAR hands
its depth to its grid (`ToolbarWdgt._ownDepthInCells`, read by `dockThickness` and by the floating hug), the grid's
measures take the depth as an argument (`naturalGridCrossExtent(depthInCells)`, `naturalGridExtentWithin(room,
depthInCells)`), and `ToolPanelWdgt._stripDepthInCells` is deleted: the depth is the toolbar's (R9), the spec's record
and the class's depth meet in one place (`dockThickness`), and the grid reads no toolbar field across its parent link.
`_edgeDockSpecFor` writes the record guarded (a frame standing somewhere, a payload that answers a depth), so a
non-toolbar spec carries no field of it, and stays pure. Test 3, `SystemTest_macroToolbarDocksAtTheDepthItFloatsAt`,
reads "two cells" from the grid (distinct column lefts, row tops) and resizes a toolbar by its grip to one pitch and 20
px: docked, its payload is two columns wide, 20 px less than floating (the count is recorded, not the pixels); bitten
by three plants (the spec recording no depth; the paint toolbar's own depth deleted; the depth read off the longer
side), each failing its own assertion under both pointers. `macroDockOutlineIsTheBandItMakes`'s palettes hug as the
product's openers do, and `macroToolbarBandIsAsDeepAsAStrip` states the paint toolbox's two columns from its grid (its
assertion bites under the second plant). Presuite: the predicted 14 failed on pictures only, test for test; the diff
page shows the toolbox docked two by two, the floating paint window two columns wide (wide enough for its "−"), the
drawings' canvases 50 px narrower beside it; recaptured. The unit's review found a class-A defect the two-cell
toolbox makes reachable, fixed at its cause: the grid took its direction from its box's aspect, so a two-cell side band
squashed shorter than its depth (a Drawings Maker at its grip floor) laid one column and showed only its chevron; a
docked band's direction is a fact of its dock (`ToolbarWdgt.stripRunsVertically`, from the band's edge spec's run
axis; a floating toolbar keeps the aspect rule), and a lone slot whose run cannot hold it with its padding stands
centred (`ToolPanelWdgt._slotOffsets`; identical at runs of 60 and more), so a squeezed band shows its tool whole
(DockOutline's image 2, recaptured again). Test 3 gained a leg that docks a toolbar wider than deep (the shorter side,
not the width), a leg that squashes the Drawings Maker, and three more plants (the fresh-frame guard removed, the depth
read off the width, the grid's direction from its aspect alone), six in all; DockOutline's column check counts the two
columns. Seen, for the owner: a paint toolbox docked across a TOP or BOTTOM band is two rows deep with its four tools in
one row (R7 and R9 as ruled); filed: an enlarged toolbar window docks as deep as its shorter side (no bound). No ratchet
moved.

### Phase 3b — the strip of a band: a collapse piece only where it gives room back, a grip mark otherwise (R10, R11, D6)

**Ruled by the owner (D6).** Measured why: every strip is 46 px across
(`theme.frameBorderWidth + theme.barIconSize + theme.barRuleWidth`), and a one-row toolbar band is 46 deep by
construction, so collapsing it hides its tools and frees nothing; and no strip shows a cursor or a mark of its
own, so a bare one reads as a grey square, on a touch screen above all.

1. **The roster (R10).** `FrameWdgt._barSpec` pushes `"collapse"` unconditionally today. The bar already builds
   AND retires the piece by the roster (`FrameBarWdgt._reDeriveRosterNoSettle`: `if "collapse" in pieces … else
   if @collapseUncollapseSwitchButton?`, and `_rosterDisagreesWithSpec` asks `collapseWanted`), and the frame
   re-derives its roster at the top of every arrange, so this is the whole change:

   ```coffee
       pieces.push "collapse" if @_offersCollapse()
   ```

   ```coffee
     # DO I OFFER MY COLLAPSE PIECE? A window always does. A band does where collapsing gives room back:
     # collapsed, I am my strip (_bandThicknessUnder), so a band no thicker than its own strip -- a one-row
     # toolbar, as deep as a strip by construction -- would hide what it holds and free nothing; and while
     # I am collapsed, the piece is the way back. Pure: theme dials and my band's own measure.
     _offersCollapse: ->
       dockSpec = @_myEdgeDockSpec()
       return true if !dockSpec? or @contents?.collapsed
       (@_bandThicknessUnder dockSpec) > @_stripThickness()
   ```

   Give the strip's thickness ONE home, read by `_barSpec`'s `thickness:` and by this:
   `_stripThickness: -> theme.frameBorderWidth + theme.barIconSize + theme.barRuleWidth` (with
   `theme = WorldWdgt.theme`). ⚠ `_bandThicknessUnder` asks `@_barSpec().thickness` in its COLLAPSED branch and
   `_barSpec` now asks `_offersCollapse`: the early return for a collapsed frame is what keeps that from
   recursing, so keep its order; point `_bandThicknessUnder`'s collapsed branch at `_stripThickness()` too. A
   pop-up's strip (`_transientBarSpec`) is not touched.
2. **The mark (R11).** PAINT of the strip, shown exactly while the strip's arrange leaves NO piece showing and
   no title (`FrameBarWdgt._positionAndResizeChildren` already computes `showing` and `titleShows`): record
   that answer as a layout OUTPUT on the bar and repaint the strip's background when it flips. Read
   `docs/architecture/appearance-paint-convention.md` and `visual-design-system.md` ("Window bar", "Grip strip")
   before choosing where it is painted: the strip's background is a `BoxWdgt` the frame's look skins
   (`_buildTitlebarBackground`, `_skinTitlebarBackgroundTo`), and the mark belongs to that skin, in the look's
   glyph ink at rest strength, with its dot size, pitch and count as theme dials beside the other bar dials.
   Integer pixels on both backends (the software backend does not anti-alias). No new widget class for a
   control: it is not one. The look is the owner's pick, (b) of the review page's section 7: A FIELD OF DOTS. As
   rendered there (`Fizzygum-tests/.scratch/slotting-proto/out/grip-A-b.png`, composed by `grip-compose.py`):
   square dots 2 px a side on a 6 px pitch, the field centred in the strip and kept 12 px in from the strip's
   edges on both axes, so `columns = floor((stripWidth - 24) / 6) + 1` and the same down (a 46 × 46 strip: 4 × 4
   dots; a 46 × 41 one: 4 × 3; a strip with no room for one dot shows none); ink rgb(112, 112, 106) on a band's
   strip in that render, to be stated as a role of the frame's look beside `barGlyph` (a card's strip and a
   window's differ), quieter than a glyph. Lengths are logical pixels: at density 2 a dot is 4 device pixels.
3. `fg presuite`. Predicted failing set, measured with every rule of this plan on and the collapse rule in
   the page (465 tests, 66 failed, the patch live in 8 of 8 shards; the mark itself was not painted in that run,
   and it changes only strips the missing piece already changes): the 15 of Phase 3 and 51 more.
   - THREE tests press the collapse piece of a ONE-ROW docked toolbar, which no longer exists, and fail on
     `AIM MISSED … must land on a SwitchButtonWdgt`: `SystemTest_macroCollapsedDockIsAnEdgeSliver`,
     `SystemTest_macroViewModeDisengagesDocks`, `SystemTest_macroToolbarBandIsAsDeepAsAStrip` (its "collapsed,
     the top band is still 46 deep" step). Each keeps its subject on a band that still collapses: a docked
     DOCUMENT, or the Drawings Maker's two-cell toolbox. Read each test's `intent` first; where the subject was
     "a collapsed one-row band is as deep as its strip", that fact is now R10's reason, and the step asserts
     the absent piece instead. Never press through with a raw coordinate.
   - 49 pixel-only beyond Phase 3's twelve, every one a window showing a one-row docked band whose strip loses
     its "−" (and gains the mark): `macroDimmedToolCellStaysDarkUnderThePointer`, `macroDockAnyFrame`,
     `macroDockedFrameHasNoCloseNoResizer`, `macroDocsToolbarDockSidesAndFloat`,
     `macroDocsToolbarSlotEditViewToggle`, `macroDocumentKeepsItsMargin`,
     `macroEditingFollowsAParagraphOffScreen`, `macroFoldersAndTheBinStayInEditMode`,
     `macroMenuRowKeepsTheSelection`, `macroOverflowRowOfADimmedToolIsDisabled`,
     `macroPinnedMenuTicksFollowTheirState`, `macroPinnedTextMenuGreysItsEditingRowsInViewMode`,
     `macroPinnedToolbarFontsMenuGreysWithItsTool`, `macroSampleSlideEditViewToggle`,
     `macroSaveAsPromptAboveTiltedWindow`, `macroSelectionOverlaySurvivesBringToFront`,
     `macroSheetScrollIndicators`, `macroSheetsMakerViewMode`, `macroSlidePanelEditingToggleReachesItsWindow`,
     `macroStretchChildHandleResizeSurvivesReflow`, `macroTabletDockedToolbarChevron`,
     `macroTextMenuShowsItsStateAsTicks`, `macroToolbarGridPacksAndSpreadsOnlyWhenFull`, and the 26
     `macroSpreadsheet…` tests that show the Sheets Maker's bar (`ColorCell`, `DragWidgetOutOfCell`,
     `DropWidgetIntoCell`, `Duplicate`, `EditCancel`, `EditCaret`, `EnterTabDeleteMoves`, `ErrorPropagation`,
     `FormulaBarEditsAndErrors`, `KeysFollowFocus`, `LiteralEntry`, `LoopRejected`, `MenuTicksStayLive`,
     `OpenGrid`, `PageAndZoom`, `RefsRecalc`, `ResizeViewport`, `ScrollKeyboardFollow`,
     `ScrollRichCellRetain`, `ScrollWheel`, `SecondsCell`, `Selection`, `SliderCell`, `TextSpill`,
     `TiltedClickSelectsCell`, `ToolbarActsOnSelection`). Attribute by sampling: `fg diffpage` on five of them,
     one per Maker kind, must show a difference confined to band strips; then the whole set goes into Phase 4's
     wave. A difference anywhere else is a finding.

**Landed 2026-11-24 (U4 of the several-bands loop).** R10 is `FrameWdgt._offersCollapse`, read by `_barSpec`'s roster;
the strip's thickness has one home, a derived Theme dial, `barStripThickness` (the `frameGripStripThickness`
precedent), read by `_barSpec`, `_bandThicknessUnder`'s collapsed branch (so `_offersCollapse` cannot recurse) and
`_offersCollapse`. R11 is paint: `FrameStripAppearance` (the twin of `FrameBodyAppearance`), worn by every strip,
paints the dots in `_paintBandOverMyFill` from its own box's plate (the strip's background less its rule: 12 px in,
which reproduces the approved render; the plan's formula on the strip's length broke its own inset at some lengths),
whole device pixels on both backends; whether it shows is a layout OUTPUT of the bar's arrange
(`FrameBarWdgt.gripMarkShows`: no piece and no title showing), handed to the appearance by `_shapeTitlebarBackground`;
its ink a card's look role, `cardBarGripMark` (the palette's `muted`, 6 levels from the render's 112,112,106: reuse over
a one-off colour, for the owner's look), none on a window's. Found on the way and fixed at its cause: a collapse piece
built on an already-collapsed frame showed "−" (the add resets a switch to its first state):
`FrameBarWdgt._addCollapseSwitchNoSettle` shows the frame's state. Four tests that asserted or pressed a one-row band's
piece keep their subjects: `macroDockedFrameHasNoCloseNoResizer` asserts the absent piece; `macroToolbarBandIsAsDeepAsAStrip`
asserts it and the info band's kept piece; `macroCollapsedDockIsAnEdgeSliver` runs C13 and C17 on a docked note (and
asserts an identity pair); `macroViewModeDisengagesDocks` on the Drawings Maker's two-cell toolbox. Test 4,
`SystemTest_macroBandStripOffersCollapseOnlyWhereItGivesRoom`, reads the dots off the canvas by meaning (16 dots, 12 px
in), bitten by four plants (the piece always offered; the mark never painted; the switch built showing "−"; the mark
catching presses). Presuite: the predicted 64 failed on pictures only, test for test (48 one-row-band strips, the 26
spreadsheet tests among them; the four rewritten; eight re-changed; the loop's four); the diff page classified by
script (every change a strip's, whole dots) and by eye (the tilted strips, the two moved tests); recaptured. Ratchets:
`METHOD_CEILINGS.FrameWdgt` 181 → 182 (`_offersCollapse`), `FrameBarWdgt#_positionAndResizeChildren` 33 → 34
(`gripMarkShows`), `FrameWdgt#_frameLook` 24 → 25 (the role); `FrameBarWdgt#_reDeriveRosterNoSettle` lowered 23 → 20.
For the owner's look: a toolbar window narrowed below one piece shows a bare strip and no mark (D6 ruled the band's).

### Phase 4 — tests

Author with the `/author-macro-test` skill in `Fizzygum-tests`. Each new test: both pointers, dpr 1 and 2, the
follower proof (§0.5 step 5), and a BITE proof: put the old behaviour back with a `--prelude=` plant under
`Fizzygum-tests/.scratch/` and see the test fail on the assertion that names the rule.

1. **`SystemTest_macroSecondBandJoinsItsSide`** (R1, R2, R5, R8). A Docs Maker. Dwell-drag a hugged toolbar
   window onto its TOP edge (the `holdOverOffer` idiom of `macroDockOutlineIsTheBandItMakes`): the outline is
   a band under the text bar; release; `host.dockedFrames.top` is `[textBar, guest]`, the text bar alive, the
   guest's top `@_dockedBandInset() + @_bodyMargin()` below the bar's bottom (read both terms off the host, never
   a literal). The same on the LEFT, twice. Lift the OUTER left band out by its strip: the inner one closes up
   to the body's edge. Re-side the remaining left band to the top by its "Dock ▸ Top" row: it is the last of
   the top list. Duplicate the window: the copy holds its own bands, as many per side. Plant: restore the
   `_fullDestroyNoSettle()` line.
2. **`SystemTest_macroViewModeHidesOnlyToolBands`** (R6). A Docs Maker with a toolbar docked left and a text
   window docked at the bottom. Flip to view mode: the two toolbar bands are hidden and take no room, the
   text band is visible where it stood, and its text refuses typing. A drag on the text band's strip moves the
   HOST (the band is still in `host.dockedFrames.bottom`). Its context menu offers neither "Dock" nor "Float".
   Flip back: everything returns, pixel-identical to the first shot (`@assertScreenshotsIdentical`). Run the
   refusals under the finger too. Plant: `_engageDocksNoSettle` writing `engaged` for every band.
3. **`SystemTest_macroToolbarDocksAtTheDepthItFloatsAt`** (R7, R8). A hugged floating toolbar docks one cell
   deep. A second one, resized BY ITS GRIP to two cells across, is held over a Slides Maker's left edge: the
   outline is two cells wide, beside the Maker's own band; released, the band is that box and its grid shows
   two columns. Lifted out again it floats two cells across; dropped on the TOP edge it is two ROWS deep. A
   Docs Maker's own toolbar, built docked, is one cell deep; a Drawings Maker's is two (R9). Plant:
   `_edgeDockSpecFor` leaving `depthInCells` unset.
4. **`SystemTest_macroBandStripOffersCollapseOnlyWhereItGivesRoom`** (R10, R11). A Docs Maker: its text bar's
   strip carries no collapse piece (`!textBar.collapseUncollapseSwitchButton?`) and shows the grip mark; a drag
   on that strip still lifts the band out. A document docked at its bottom carries the piece; tapped, the band
   is its strip and the page grows by the room it gave back; tapped again it returns. A Drawings Maker's
   two-cell toolbox carries the piece and gives back one cell's depth. A one-row band collapsed by its menu
   shows the piece while collapsed, and loses it once expanded. Under the finger too. Plant: `_offersCollapse`
   answering true.

Then the full recapture wave for every test whose pictures changed by rule, both pointers.

### Phase 5 — docs and backlog (present tense, woven in, no "now" or "used to")

- `docs/architecture/toolbars.md`: §1 "Two homes, one object" and "A band is as deep as a strip" (a side holds
  several bands; depth by arrival); §2 (the slot is a list; "A band the host's view mode disengages" becomes
  the amenity rule; a viewing host keeps its bands in place); §4.4 (delete "A palette dropped into an OCCUPIED
  slot destroys the occupant first…": a second palette joins, and the host keeps its tool because another
  payload already wears drawing tools); §8 "A toolbar"; §9 (the three new tests).
- `docs/architecture/layout.md` §4.2: the `EdgeDockLayoutSpec` sentences (`engaged`, `depthInCells`).
- `docs/architecture/visual-design-system.md`: the embedded-toolbar row (the gap between two bands of a side;
  the paint toolbox's two cells); if Phase 3b ran, the "Window bar" row (when a band's strip offers its
  collapse piece, the grip mark and its dials).
- `docs/architecture/toolbars.md` §1 also takes R9 (a toolbar's own depth, the paint toolbar's 2) and, if Phase
  3b ran, one bullet on a band's strip (R10, R11); §8 "A toolbar" names `depthInCells`.
- `src/macros/MACRO-PATTERNS.md`: the dock passages (done in Phase 1; re-read them against Phases 2 and 3).
- `docs/BACKLOG.md`: this plan's section loses its "not started" line; §10's two items stay.
- `fg doc-narration` must report nothing.

### Phase 6 — close

`fg gauntlet` (background, about 15 minutes), then `fg homepage`. Build a local review page for the owner
(`Fizzygum-tests/.scratch/<topic>/review.html`, opened with `open`): today and after for the rewritten
tests, the new ones, and one Maker of each kind as it now opens (the paint toolbox; the strips, if Phase 3b
ran). Present the summary, the method-ceiling change with its reason, and the two
commit messages (Fizzygum, Fizzygum-tests). WAIT for the owner's word before any commit or push. After it:
`git mv` this plan to `docs/archive/`, stamp it, add its `archive/INDEX.md` line, move its closed BACKLOG lines
into its ledger.

---

## §6 Central risks

- **The measure and the arrange disagree.** Every band term has one home; the settle re-visit gate
  (`fg revisits`, a gauntlet leg, baseline EMPTY) and `fg census` fail on a disagreement. Do not compute a
  band's place anywhere but `_bandBoxesAt`.
- **A list keeps a dead frame.** Every exit of a band goes through `_reactToChildRemoved` (which frees its
  place) or `_retireBandsMyContentBroughtNoSettle` (a content change's retirement, which frees the place first). The
  object-lifetime legs (`WORLD_INVENTORY_*`, `fg vmtruth`) catch
  a leftover reference; a new test must leave the world as it found it.
- **Copy and save.** `dockedFrames` is an ordinary field holding arrays of widgets that are also children; the
  duplicator and the serializer walk it by identity. The gauntlet's `serialization` leg and the duplicate
  step of test 1 are the proof; a failure there is a finding to report, not to route around.
- **The tests' mechanical edit hides a meaning change.** Read the diff (Phase 1, step 5).
- **A hover writes state.** `bandBoxIfDocked` runs at every pointer dispatch of a hold. It must stay pure:
  `_edgeDockSpecFor` builds a spec and writes nothing on the frame or its payload. The prototype cut this
  corner (it wrote a field on the toolbar); the source must not.
- **A view-mode band still takes input it should not.** R6's refusals are the drag, the two rows and the two
  verbs; a docked document's own content is already view-only while a MAKER host views (measured:
  `sitsInViewModeContent` is true for a text in it; a plain window whose mode lives in its content does not reach a
  band, found by U2's research), and it offers no slot (`dockSideAt`).

## §7 Verification protocol (summary)

Per phase: `fg presuite` green, or every failure attributed to a rule of §4. New tests: single runs on both
pointers with `--all-logs`, the follower proof, the bite proof. End: `fg gauntlet` 20 of 20 and `fg homepage`.
A leg retried as a "load-flake" is read where it stopped before it is believed.

## §8 Rejected alternatives (do not re-attempt)

- **The window body as division stacks** (rows and columns with splitters, `StackLayoutEngine`): one engine for
  every split, but a window sizes its content by another model (hug, height from width, first placement), and
  row containers between a band and its host break `FrameWdgt.dockHost` ("my parent, when my spec is an edge
  dock"), which the rule "who a tool works for" stands on.
- **A container payload holding a row of toolbars**: its toolbars would be content, so by `toolbars.md` §2 they
  would work for the person, not the window; and the chrome doubles.
- **One ordered list for all four sides, corners by docking order**: the outcome would depend on the order
  things happened to be docked in, and it needs a reorder gesture to be usable. Advised against and not
  chosen; today's corner rule stays (D5).
- **Bands end to end in a row** (tiers): ruled out by the owner (O2).
- **A docked document follows its host's pencil**: prototyped; with the host editing, the document's own text
  bar engages inside its band and the window shows two text bars (a band is not its host's content, so the
  host's bar does not reach it). Not recommended (D3); §10 files the observation.
- **A resize control on a band** (a seam drag, a grip piece, menu rows): the composition already answers it.
  A window is sized on the desktop and keeps that size as a band; a toolbar keeps its depth (R7).
- **Guarding the destruction with a confirmation**: it keeps the rule that causes it.

## §9 References

- `docs/architecture/toolbars.md` (who a tool works for; the dock rules §2), `docs/architecture/layout.md`
  §4.2 (the layout-spec family), `docs/architecture/lint-and-static-checks.md` (the gates, §3b for classes).
- `docs/archive/frame-lifetime-and-docking-plan.md` (C11–C13: docking as placement),
  `docs/archive/docked-and-floating-toolbars-plan.md` (R1–R10), `docs/archive/toolbar-grid-and-bar-run.md`
  (the grid fills its box; groups and separators ruled out), `docs/archive/toolbar-band-depth-plan.md`.
- Tests that hold the neighbouring rules: `SystemTest_macroDockAnyFrame`,
  `SystemTest_macroDocsToolbarDockSidesAndFloat`, `SystemTest_macroViewModeDisengagesDocks`,
  `SystemTest_macroCollapsedDockIsAnEdgeSliver`, `SystemTest_macroPaletteDockUndockKeepsTheTool`,
  `SystemTest_macroGripStopsWhereDockedBarsStayUsable`.
- The prototype: `Fizzygum-tests/.scratch/slotting-proto/` (see §4).

## §10 Deferred, with their reasons

See `## BACKLOG detail` below.

---

## BACKLOG detail (open items, moved from docs/BACKLOG.md)

### A docked document has no pencil

A docked frame offers no edit toggle (`FrameWdgt.offersEditToggle` asks `!@_myEdgeDockSpec()?`), so its content
keeps the mode it had when it docked. Measured 2026-11-23: an info document, born in view mode and docked at
the bottom of a Docs Maker, answers `isInEditMode` false and its text `sitsInViewModeContent` true while the
Maker around it is editing. The way through today: lift the band out, flip its pencil, dock it back. The
alternative (the band follows its host's pencil) was prototyped and shows two text bars in one window, because
the document's own toolbar engages inside its band; a ruling on it would also have to say whether a host's
toolbar should reach a band's content. Reachable, low.

### The paint revamp's toolbar pieces

Three pieces were designed with this plan and left for their first consumer, the paint revamp:

- **A holder holds a tray.** `armedDrawingTool` / `armDrawingTool` (on `User` and on `FrameWdgt`, 19 code lines
  over 9 files on 2026-11-23) generalised to named aspects (tool, ink, paper, size), so a colour swatch or a
  line width is an ordinary mode tool with an active state on the existing holder and refresh machinery.
  Estimated +10 to +25 lines.
- **A Maker declares several bands**, in order, where `buildToolbar` returns one
  (`FrameWdgt._buildDockedToolbarNoSettle`). Estimated +5 to +8 lines.
- **Flyout cells** (a brush or shape gallery): a cell opens a TRANSIENT frame holding a toolbar; pinning it
  makes a floating toolbar, which docks. Reuses frame lifetime as it stands. Estimated +20 to +30 lines.

### Attach onto an occupied window orphans its content

Measured 2026-11-24 during U1b (`Fizzygum-tests/.scratch/several-bands-loop/u1b/probe-f2.log`): in dev mode the
Widget menu's "Attach" chooser offers a window that already holds a content. On a plain window holding a panel, the
attached rectangle becomes the content and the panel is left with no parent, not destroyed and off the world tree; on
a Docs Maker the page is lost the same way, the Maker shrinks to about 80 px wide around the rectangle, its text bar
squeezed, its title still "Docs Maker". The cause is `FrameWdgt._addNoSettle`'s content branch, which replaces the
content with `removeChild @contents` and tells nobody (no `_reactToChildRemoved`, no reset, no rebuild). The same
door reaches a BAND (the chooser offers any visible widget that overlaps, a Maker's text-bar band among them, by U1b's
review): the band then holds the attached widget while its record `broughtByContent` still says it holds what its host's
content brought (no `notePayloadLeft` runs), so the Maker never offers its "Toolbar" row again and its toolbar is left
off the tree, and the band's spec has no
recorded `thickness` (its toolbar declared one), so the band measures NaN. The decision to take: whether an occupied
window is an Attach target at all, or the attach goes through the content-change door.

### A toolbar window put into another window shows a clipped strip

Measured 2026-11-24 during U1b (`Fizzygum-tests/.scratch/several-bands-loop/u1b/investigate/REPORT.md`,
`probe-extra.*.log`): the sibling of the defect U1b fixed for bands. A FREE toolbar window whose strip runs down its
side, first placed with its height given (a picked-up toolbar added into an empty window: 555×44 in a 118 room; a
fresh one 50×40 with both scroll indicators), takes the first-placement negotiation's height, its payload's
construction extent, and no later pass corrects it. A wider form of U1b's rule (a frame whose strip runs down its
side also skips the negotiation) heals it and measured 110 of 111 candidate tests byte-identical with no re-visit,
but it changes a free window's first placement: an owner question. A window first placed as a division cell (300×87
where the cell grants more) has the same cause; no person's door to it was found.

### A Maker docked in a viewing window keeps its own toolbar showing

Read 2026-11-24 by U2's review (the trace; not run): R6 asks a band's PAYLOAD whether it is there for editing, one level
down, so a docked MAKER (a band whose payload is its page) stands in its host's view mode, and the Maker keeps the mode
it docked with (D3: a docked frame offers no pencil). Its own text bar therefore stays engaged and shown inside it while
the host views; its page refuses typing (the host's view mode reaches it through the chrome walk), so the bar's tools
have nothing to act on; and its bar's "Dock" and "Float" rows are offered and act (the Maker, editing, lets its band go),
while a drag on the same strip climbs to the host and moves it (the Maker stands in view-mode content), and the dock
offer refuses it. To see it: the end state of `SystemTest_macroViewModeWindowOffersNoDockSlot` (a Docs Maker docked on a
Docs Maker), then the host's pencil. The decision to take: whether a viewing window's view mode reaches the bands of a
window docked on it (its tools put away too), or the docked window keeps its own mode; one uniform piece either way:
`wantsDetachOfChild` refusing while the host stands in view-mode content, the mirror of `dockSideAt`, so the rows agree
with the drag.

### An enlarged toolbar window docks as deep as its shorter side

Read 2026-11-24 by U3's review (not run): R7 records the depth a toolbar STANDS at as it arrives, the whole cells its
shorter side holds, with no bound. A toolbar window a person enlarges (a 400 × 400 Super toolbar holds about 6 cells; a
600 × 600 one about 10) docks that deep: a band wider than a Docs Maker's body. What a host does with a band thicker than
its body was not determined. The decision to take: a bound on the recorded depth (the toolbar's own depth, the cells
its tools need, a share of the host's body), or none.

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] Phases 1–6, not started: a list of bands per side (no dock destroys a band), view mode hides only tool bands, a toolbar docks at the depth it floats at; four new tests, two rewritten; owner decisions D1–D6 ruled. — CLOSED 2026-11-24 (several-bands loop, U5): every unit landed, U1b added by the owner's O4; five new tests (not four: U1b's), eight existing tests rewritten.

Closed 2026-11-24 by the owner's rulings on three of the questions the loop filed (no plan of their own; the test
`SystemTest_macroAWindowWearsOneCopyOfItsToolbar`, bitten by six plants under both pointers):

- [x] **A Maker's own toolbar moved by its strip stops being its own** — dragged to another side of the same Maker it is re-docked as a person's band, unlike a re-side by its row: the Maker then offers its Toolbar row and a page leave docks a second text bar — reachable (dev mode), low. — CLOSED 2026-11-24 (owner ruling: a drag from one side to another of the same window keeps the band the window's own): a band lifted out by a grab carries the host whose content brought it across the gesture (`FrameWdgt._liftedAsTheOwnBandOf`), and docked again on that same host by the drop that ends it, it is recorded as that host's own again (`FrameWdgt._reactToBeingDropped`); docked anywhere else, or later, it is a person's.
- [x] **A Maker dropped into an empty window gets a second text bar** — the outer window docks the Maker's own toolbar again (and takes its title), so two identical bars reach one page — reachable, low. — CLOSED 2026-11-24 (owner ruling: a window whose content is a window docks nothing): a window docks only the toolbar its own kind declares (`FrameWdgt._buildDockedToolbarNoSettle` and `_offersAFreshToolbar` ask `_buildToolbar` of the frame alone), so the content branch went, and with it `_retireBandsMyContentBroughtNoSettle`, which had nothing left to retire; the hook, asked only by the frame itself, is `_buildToolbar` (the call-separation gate's [U] rule). The title was not ruled on and is unchanged.
- [x] **A pinned "Toolbar" submenu docks one more bar per click** — the row has no guard of its own, so each click docks another copy of the content's toolbar — reachable, low. — CLOSED 2026-11-24 (owner: fix): `FrameWdgt.addToolbarAtSide` asks `_offersAFreshToolbar` again at the click, as a band's pinned Dock and Float rows ask whether the host lets the band go.

### A Maker's own toolbar moved by its strip stops being its own

Read 2026-11-24 by U1b's review (not probed): a Maker's own toolbar band dragged by its strip and dropped on another
side of the same Maker (past the dwell) is re-docked under a fresh spec, so it is recorded as a person's band
(`broughtByContent` false), while the same move made by its "Dock ▸ side" row keeps the record. After the drag the Maker
offers its "Toolbar" row with its bar docked, and its next page leave docks a second text bar beside the moved one. Two
gestures for one intent end differently. The plan's Phase 1b reads a band floated away and docked again as a person's;
whether a band that never left its host's slots (a drag from one side to another) keeps the record is the owner's
question.

### A Maker dropped into an empty window gets a second text bar

Measured 2026-11-24 during U1b (`u1b/probe-f1.log`): a Docs Maker dwell-dropped into an empty plain window (the
Windows toolbar's "empty window" creator makes one) becomes that window's content, and the outer window's rebuild
docks the toolbar its content declares (`_buildDockedToolbarNoSettle`'s `@contents?.buildToolbar?()` branch, reached
only here, since only Makers declare one) beside the Maker's own: two identical text bars, one working for the Maker
and one for the outer window, which reaches the same page. The outer window also takes the title "Docs Maker". The
decision to take: whether a window whose content is itself a framed citizen docks anything.

### A pinned "Toolbar" submenu docks one more bar per click

Measured 2026-11-24 during U1b (`u1b/probe-f3.log`): the host's "Toolbar" submenu offers "Pin"; pinned, each click of
a side row runs `addToolbarAtSide`, which docks the content's toolbar with no guard of its own, so a second click
docks a second copy (each recorded as the content's). The row is offered only while no band the content brought is
docked, but a pinned copy outlives that answer. Its rows could ask the same question at the click
(`_offersAFreshToolbar`), the way a pinned text menu re-asks its enablement.

Noted, not queued:

- [x] `FrameWdgt._offersAFreshToolbar` offers a host's "Toolbar" row only while NO band is docked at all
  (`_dockedToolbarFrame()` answers any band). With several bands a side, a window whose own toolbar was floated
  away and which holds some other band is not offered its toolbar back by that row. Unreached in the shipped
  windows; left as it is. — CLOSED 2026-11-24 (several-bands loop, U1b): the row asks whether a band the
  content brought is docked (`_bandsMyContentBrought`).
- A band menu pinned in edit mode keeps its "Dock" and "Float" rows across a flip to view mode; the verbs
  refuse (Phase 2, step 4), the rows do not grey.
- A band COLLAPSED in its slot and carried to another slot docks at its payload's own depth, not the depth it
  had: a collapsed payload shows no grid to measure (`depthInCellsAsIStand` answers nothing). Expanding it
  first keeps the depth.

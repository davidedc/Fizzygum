# Menu-sandwich dissolution — the rows panel as the viewport's own contents

> **PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
> Authored 2026-08-20 against Fizzygum master `89db5c88` / Fizzygum-tests master `5afa6e4b3`
> (both pushed; gauntlet 17/17, suite 306 at these heads). Every `file:line` here is a hint
> that WILL drift — the method name and the quoted code are authoritative; grep them fresh
> before trusting any line number. STATUS: **not started; Phase 0 spikes MANDATORY before
> any phase executes.**

## STATUS BOX

| Phase | State | Evidence |
|---|---|---|
| 0 — S1 residual-oscillation probe | not started | — |
| 0 — S2 pixel-identity A/B | not started | — |
| 1 — the dissolution (pop-ups) | not started | — |
| 2 — ListWdgt uniformity (ASSESS-first) | not started | — |
| 3 — retirement + truth | not started | — |

## §0 Orientation

Fizzygum (CoffeeScript, single `<canvas>`, byte-exact SystemTest suite — `fg status` prints
the live count) keeps every pop-up's rows in a scrolling viewport, ALWAYS (reachability: a
menu taller than the world scrolls instead of losing rows). Between the viewport and the
rows panel sits a THIRD node — the sandwich:

```
PopUpWdgt (MenuWdgt / PromptWdgt)
└─ PopUpRowsViewportWdgt            (extends ViewportWdgt; alpha 0, hit-transparent)
   └─ PopUpRowsPaneWdgt             (extends ScrolledPaneWdgt; alpha 0, hit-transparent)  ← THE SANDWICH
      └─ MenuRowsPanelWdgt          (extends VerticalStackPanelWdgt; draws the WHOLE body)
         └─ the rows
```

The sandwich exists because the rows panel is a SELF-FRAME-WRITING plane — its arrange
re-applies its hug (widest row + 2·padding, tight height) — and the viewport arrange is its
plane's SOLE FRAME COMMITTER. Two writers with different arithmetic oscillate forever
(`RECALC_NONCONVERGENCE`). This was falsified TWICE, most recently 2026-08-19 with the full
scrolled-content contract declared (probe:
`Fizzygum-tests/.scratch/sandwich-direct-livelock-probe.js`; measured record: the §7.2
refusal line in `docs/BACKLOG.md`), which set the reopen condition this plan now meets:
*"redesign the hug into a pure measure with the container as sole committer."*

**The critical reframe — THREE things changed since the falsification, and each removes one
leg of it:**

1. **The paint-time scroll arc landed** (`docs/archive/paint-time-scroll-translation-plan.md`,
   Phases 0–3, 2026-08-20): scrolling never moves the plane — the offset is stored on the
   viewport and applied at paint. The frame no longer has to be repositioned on scroll, so
   nothing about scrolling requires the viewport to write the plane's frame; only the ARRANGE
   still does.
2. **The hug already exists as an HONEST PURE MEASURE, with no consumer.** The
   menu-row-conformance arc's Phase 3 gave `MenuRowsPanelWdgt` measure overrides that answer
   the hug (`preferredExtentForWidth` / `subWidgetsMergedPreferredBounds` — quoted in §1.2),
   its own comment saying *"No consumer exists today … model honesty for the next
   consumer."* This plan is that consumer. The 2026-08-19 spike's measured width
   disagreement (committed 62 vs hug 64: *"the base stack measure distributes padding INSIDE
   availW"*) is an artifact of the BASE measure — the overridden measure answers 64.
3. **The rows viewport is UNCONDITIONAL** (`PopUpWdgt._buildRowsViewportNoSettle` — a menu
   that fits simply has nothing to scroll), so the BACKLOG's worry that the redesign *"must
   also serve the pop-up's own `_layOutAndHugRowsPanel` path, where no viewport commits for
   the panel"* dissolves: that path already re-lays the viewport
   (`_refitRowsViewportNoSettle` calls `@rowsViewport._reLayoutChildren()`), so under
   container-as-sole-committer the same call is what commits the panel's frame there.

**Mandate: dissolve the sandwich — delete `PopUpRowsPaneWdgt` and make `MenuRowsPanelWdgt`
the rows viewport's direct `contents`,** with the viewport committing the panel's frame from
the honest hug measure and the panel's arrange no longer writing its own frame. One node
fewer in EVERY pop-up in the system (every context menu, every prompt), a 67-line class and
its forwarding chain deleted, and the doctrine extended: a hug-sizing plane is a legal
committed contents once its hug is a measure. This is a structural-simplification arc: if
Phase 0 shows byte-identity is unreachable without a mass menu recapture, PARK the plan with
the evidence rather than forcing it (menus render in essentially every reference image).

## §1 The mechanism as it stands today (verified 2026-08-20 at `89db5c88`)

### 1.1 The pop-up composite and its two sizing paths

- `PopUpWdgt.rowsPanel` — the `MenuRowsPanelWdgt` that *"is this pop-up's whole visible
  body (box, optional title header, and the rows)"*; built by the subclasses (`MenuWdgt`,
  `PromptWdgt`), free-floating inside the pane.
- `PopUpWdgt._buildRowsViewportNoSettle` (~PopUpWdgt.coffee:115): builds
  `new PopUpRowsViewportWdgt()` (whose ctor does `super new PopUpRowsPaneWdgt()` and pins
  `@alpha = 0`), sets `@rowsPanel.isLockingToPanels = true`, adds the viewport to the
  pop-up and the panel INTO the pane: `@rowsViewport.contents._addNoSettle @rowsPanel`.
  Its long comment holds the ⛔ litigation record (do-not-inline warning, the per-class
  declarations, the conditional-viewport rejection) — Phase 1 REWRITES it, Phase 3 keeps its
  history honest.
- Sizing path A — `_layOutAndHugRowsPanel` (~:64): `@rowsPanel._reLayoutChildren()` (the
  panel lays out AND self-sizes), then `_refitRowsViewportNoSettle` (~:80): viewport moved
  to the pop-up's position, extent = `min(@rowsPanel.width/height, world.width/height)`
  via the non-notifying twins, then `@rowsViewport._reLayoutChildren()`; finally the pop-up
  takes the viewport's extent (`@_applyExtentBase @rowsViewport.extent()`). Driven by
  `MenuWdgt` at popUp, `PromptWdgt` at build, `popUp` itself, and the absorb seam.
- Sizing path B — the membership-change absorb: `VerticalStackPanelWdgt._reactToChildRemoved`
  asks its DIRECT parent `_reLayOutAfterContainedPanelChange`; today that parent is the
  PANE, which forwards to `@firstParentThatIsAPopUp()._reLayOutAfterContainedPanelChange?()`
  (→ `_layOutAndHugRowsPanel`). ⚠ Note `ViewportWdgt` itself carries a
  `_reLayOutAfterContainedPanelChange` hook (the "viewport re-fits its contained stack"
  notification; `ListWdgt` opts OUT of it) — after dissolution the stack's direct parent is
  the viewport's contents… which IS the stack's parent chain through the viewport: the ask
  lands on the VIEWPORT (the panel's new direct parent is the viewport? NO — the panel
  becomes `@rowsViewport.contents`, so the panel's direct parent is the VIEWPORT and the
  ask lands on `ViewportWdgt._reLayOutAfterContainedPanelChange`). Phase 1 overrides it on
  `PopUpRowsViewportWdgt` to forward to the pop-up — ONE forward replacing the pane's.
- The always-on reachability guard: `PopUpWdgt._assertFitsInTheWorld` — `console.error`s
  `POPUP_LARGER_THAN_WORLD`, fail-gated by the headless runners. This is a free behavioral
  tripwire for the whole arc.

### 1.2 The hug — one frame WRITE, two honest MEASURES

`MenuRowsPanelWdgt` (extends `VerticalStackPanelWdgt`):

```coffee
_positionAndResizeChildren: ->                                     # the SELF-WRITE (~:235)
  @_applyExtentBase new Point (@maxWidthOfMenuEntries() + 2 * @padding), @height()
  super()

preferredExtentForWidth: (availW) ->                               # honest measures (~:249)
  hugW = @maxWidthOfMenuEntries() + 2 * @padding
  new Point hugW, (super hugW).y
subWidgetsMergedPreferredBounds: (availW) ->
  super (@maxWidthOfMenuEntries() + 2 * @padding)
```

`VerticalStackPanelWdgt.scrolledContentMeasure` is `@subWidgetsMergedPreferredBounds
@width()` — with the override above, **a MenuRowsPanelWdgt's `scrolledContentMeasure`
already answers the hug box** (width ignored). The height side: the base stack measure hugs
height tight, and the honest override rides it at the hug width. The self-write at the top
is the ONE thing that makes this panel a second frame-writer.

⚠ `MenuRowsPanelWdgt`'s constructor (`super padding: 2`) does NOT pass
`constrainContentWidth`, so it inherits the stack default `true` →
`viewportConstrainsMyWidth()` answers TRUE. Harmless today only because the sandwich shields
it from any viewport; under dissolution the viewport would width-normalize the menu. Phase 1
declares the truth: a menu owns its width (`constrainContentWidth: false`, the free-width
stack path — "owns its width PASSIVELY").

### 1.3 The viewport arrange under the offset model (what the committer will do)

`ViewportWdgt._positionAndResizeChildren` (post paint-time-scroll arc): the content-sizing
branch computes `newBounds` from the §4.1 pure measure (`scrolledContentMeasure`) and — only
when the measured content is SHORTER than the window — grows it to fill
(`newBounds.growBy 0, @height() - newBounds.height()`); the non-content-sizing branch merges
`windowInPlane` (frame origin + offset + extent). The commit runs through
`@contents._commitBounds newBounds` + origin-shift offset bookkeeping + the tail clamp
(`_keepScrollOffsetInBounds`). Two facts matter here:

- On the POP-UP path the viewport's extent is `min(panel hug, world)` ≤ the hug, so
  **grow-to-fill never fires in steady state** (the spike's measured h 21→40 came from a
  fixed 40-tall spike viewport over 21-tall content — not the pop-up geometry). Transients
  (a row removed while the viewport still has its old extent) end at the absorb re-fit.
- The scrolled-content declarations the committer reads off the plane:
  `viewportConstrainsMyWidth()` (→ must become false, §1.2), `arrangesOwnScrolledChildren()`
  (stack: true — the viewport delegates the interior arrange, keeps the frame),
  `scrolledContentMeasure(widthHint)` (already the hug), `managesOwnScrollPinning()` (stack:
  true — resize does not reset scroll), `isContentSizing` (the stack IS content-sizing —
  verify which branch the arrange takes for it and that the committed box == the hug
  EXACTLY; this is spike S1's job, not an assumption).

### 1.4 The five declarations the pane carries (what must be re-homed or die)

From `PopUpRowsPaneWdgt` (each was a shipped defect when wrong — see the class comments):
`alpha: 0` (the viewport ctor's own `@alpha = 0` pin STAYS — ⚠ without it the mimic would
copy the menu's paint values onto the viewport's RECTANGULAR appearance and paint square
corners behind the rounded menu box); `isTransparentAt -> true` (the pane spanned the
pop-up's rect and had to let clicks fall through the rounded corners — after dissolution the
panel IS the body and is legitimately hit-opaque in its box; the VIEWPORT's own
`isTransparentAt true` stays and covers the corner fall-through);
`providesAmenitiesForEditing: undefined` (the viewport declares its own; the PANEL — check
what `MenuRowsPanelWdgt` answers and pin `undefined` if it inherits the stack/panel `true`);
`isLockingToPanels` (the panel already gets `isLockingToPanels = true` in
`_buildRowsViewportNoSettle` — keeps drag-by-header moving the pop-up);
`_acceptsDrops: false` (the viewport declares it; verify a drop aimed at a menu row cannot
reach the panel as contents — `wantsDropOfChild` consults the contents' veto, so the PANEL
needs the no-drops answer after dissolution); the absorb forward (§1.1 path B).

### 1.5 The parallel sandwich: ListWdgt (Phase 2's subject, NOT Phase 1's)

`ListWdgt._buildAndConnectChildrenNoSettle` builds `@listContents = new MenuRowsPanelWdgt
target:@, selectsItemsOnClick:true` INSIDE `@contents` — same shape, different host: the
list opts OUT of the viewport re-fit notification (`_reLayOutAfterContainedPanelChange ->
undefined`), rebuilds rows from `@elements`, runs its own anti-vacant-space `_applyExtent`,
and its plane answers `contentsPanelHoldsLooseContent` false. Phase 2 ASSESSES whether the
same dissolution pays there or whether List's opt-outs make it a different animal — do not
assume uniformity, and do not let Phase 1 grow List work.

## §2 The distilled argument

1. The reopen condition set by the falsification is now HALF-BUILT IN-TREE (the honest
   measures) and the other half (sole committer both paths) became structurally cheap when
   the rows viewport went unconditional. What remains is deleting the self-write, one
   declaration (`constrainContentWidth: false`), one absorb forward, and the restructure.
2. The offset model removed the only RUNTIME reason a viewport must write its plane's frame
   (scroll used to MOVE it); the arrange-time committer role it keeps is exactly the role
   this plan hands it for the menu panel.
3. The payoff is real and system-wide: one node per pop-up (pop-ups open constantly), a
   67-line chrome class + its forwarding deleted, the `_buildRowsViewportNoSettle`
   litigation comment collapses to a positive statement, and the doctrine gains its missing
   case: *a hug-sizing plane is legal contents when its hug is a measure*.
4. The risk is concentrated and measurable up front: menu pixels appear in most of the 306
   references, so Phase 0's byte-identity spike is the go/no-go — the committed frame must
   equal today's self-written frame EXACTLY, in every state a test reaches.

## §3 Fix shape (Phase 1, after spikes pass)

1. `MenuRowsPanelWdgt`: declare `constrainContentWidth: false` (with the §1.2 truth in the
   comment); delete the `_applyExtentBase` line from `_positionAndResizeChildren` (the
   arrange lays rows at the COMMITTED width; `super()` distributes `@width()`, which the
   committer set to the hug). Verify no OTHER self-frame write hides in the class or its
   `MenuHeader`/row machinery (grep `_applyExtent|_moveRightSideTo|_moveBottomSideTo` in the
   menu-system directory).
2. `PopUpRowsViewportWdgt`: ctor stops building a pane — the panel arrives as contents
   (either ctor param or `PopUpWdgt._buildRowsViewportNoSettle` restructures to
   `@rowsViewport = new PopUpRowsViewportWdgt @rowsPanel` / uses the viewport's contents
   plumbing; pick the spelling that keeps `setContents`' scaffold-destroy semantics —
   ViewportWdgt's ctor builds a default plane; `setContents` destroys it and installs the
   real one, resetting offsets: likely exactly right here). Add the absorb override
   (`_reLayOutAfterContainedPanelChange: -> @firstParentThatIsAPopUp()...`, the pane's
   forward moved up one level). Keep `@alpha = 0` AFTER the contents install (the mimic
   ordering in §1.4). Add the panel-facing declarations the pane's death orphans (§1.4:
   drops veto / editing-amenities check on the PANEL side).
3. Delete `PopUpRowsPaneWdgt.coffee`; rewrite `_buildRowsViewportNoSettle`'s comment (the ⛔
   direct-contents warning becomes "the panel IS the contents — legal since the hug became a
   pure measure and the committer is sole"; keep a one-line pointer to the falsification
   record for archaeology).
4. `_layOutAndHugRowsPanel`: re-derive — the panel no longer self-sizes, so the hug the
   pop-up reads must come from the measure or from the viewport's committed frame after
   `_refitRowsViewportNoSettle` re-lays it. ⚠ ORDER: today it reads `@rowsPanel.width()`
   BEFORE refitting the viewport; under the committer model the panel's width is only
   current AFTER the viewport arrange runs. Restructure to: measure
   (`@rowsPanel.scrolledContentMeasure undefined` — width-ignoring, §1.2) → size the
   viewport `min(measure, world)` → `@rowsViewport._reLayoutChildren()` (commits the
   panel's frame) → `@_applyExtentBase @rowsViewport.extent()`. Byte-identity of the
   resulting extents is spike S2's whole question.
5. Serialization/duplication: pop-up snapshots and deep copies stop containing a pane node.
   Owner standing rule: NO serialization compat obligations — old snapshots restoring a pane
   are out of scope; verify the two serialization rigs + the pop-up snapshot-hygiene gates
   pass (they ride `fg gauntlet`).

## §4 Central risks

- **R1 — menu pixel identity (the go/no-go).** The committed frame must equal the
  self-written hug in EVERY reached state: steady, mid-compose (`addMenuItem` on an open
  menu), row-removed absorb, prompt widening (`SaveShortcutPromptWdgt`), world-capped
  overflow (both axes). Spike S2 measures this before any real edit.
- **R2 — residual oscillation.** The falsified spike predates the honest measures AND the
  offset model. S1 re-runs the probe on TODAY's tree with the Phase-1 declarations
  hand-applied; the pass condition is zero `RECALC_NONCONVERGENCE` across the menu-opening
  test set, not an argument.
- **R3 — the mimic/appearance ordering** (§1.4): the viewport must stay pinned `alpha 0`
  after the contents install or square corners appear behind every rounded menu.
- **R4 — hit-testing:** the panel as contents must catch row clicks exactly as before
  (`menusweep` + the suite cover this densely) and drops must still be refused.
- **R5 — the absorb chain:** a row dragged out of a LIVE menu must still shrink the pop-up
  NOW (the pane's forward is load-bearing; its replacement in §3.2 must be exercised by the
  row-extraction test — `SystemTest_macroExtractMenuRowFromPinnedMenu`).

## §5 Phases

**Phase 0 — spikes (MANDATORY, throwaway, `.scratch` + uncommitted src hacks; revert after).**
- **S1 residual-oscillation probe**: take
  `Fizzygum-tests/.scratch/sandwich-direct-livelock-probe.js`, update it to today's tree,
  hand-apply the §3.1/§3.2 edits uncommitted, and run the menu-opening test set headless.
  Decides: does anything still oscillate, and WHICH axis (record the ring like the original
  spike did).
- **S2 pixel-identity A/B**: with the same uncommitted hacks, run the full suite; the
  verdict is the failing-test list. ZERO fails = green light. A small, EXPLAINABLE set
  (e.g. a 1px border interaction) = eyeball with `fg diffpage` and bring the finding back
  to the owner BEFORE proceeding — a mass menu recapture is a PARK signal, not a budget.
- Verdicts into the STATUS BOX before Phase 1.

**Phase 1 — the dissolution (pop-ups).** §3's steps in one arc, suite-gated per step where
separable; close with `fg gauntlet` (menusweep + both serialization rigs + the
`POPUP_LARGER_THAN_WORLD` tripwire all ride it). No recaptures expected; any needs the
gated flow + owner eyeball.

**Phase 2 — ListWdgt uniformity (ASSESS-first, separately committed).** Re-derive §1.5
against the landed Phase 1; produce a KEEP-or-CONVERT verdict with evidence; convert only
if the same shape drops out (the anti-vacant-space `_applyExtent` and the `elements` rebuild
are the likely blockers). A KEEP verdict with reasons is a valid close.

**Phase 3 — retirement + truth.** `viewports-and-planes.md`: the scrolled-content
contract's frame-ownership paragraph gains the hug-as-measure case; the BACKLOG §7.2
refusal line is rewritten as RESOLVED-BY this arc (keep the falsification history — it is
the reason the redesign has its shape); `PopUpWdgt`/`MenuRowsPanelWdgt` comments; memory
note; archive this plan.

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — confirm both repos at or past the
   §-header heads, clean; build FRESH or rebuild.
2. Read this plan in full, then re-grep every quoted symbol (§1's method names) before
   trusting any line reference; if the arrange or the menu system moved, update §1 first.
3. Phase 0 spikes; verdicts into the STATUS BOX; ⛔ two falsified fix shapes on the same
   problem = stop and re-frame with the owner (standing rule).
4. One phase per session-ish; update the STATUS BOX in the same pass as each landing.
5. Owner working rules: ask before commit/push; `git commit -F <file>`; long ops once via
   `run_in_background` + verdict files; never edit src/tests while an fg run is live;
   recaptures only gated + eyeballed + webkit-verified.

## §6 Verification protocol

- Inner loop: `fg presuite` (~3 min). Menus are everywhere, so the dpr1 suite is already a
  dense menu-pixel gate.
- Behavioral rigs that specifically cover this machinery: `fg menusweep` (clicks every menu
  item + presses every prompt Ok), the `serialization` gauntlet leg (pop-up
  snapshot-hygiene + teardown-hygiene checks), `SystemTest_macroExtractMenuRowFromPinnedMenu`
  (the absorb), `SystemTest_macroMenuPinnedInScrollPanel` / `macroMenuInWindowInScrollStackStaysLive`
  (menus living inside scrolled panes), the prompt family (PromptWdgt sizes inline).
- Phase close: `fg gauntlet` (17 legs).
- The always-on `POPUP_LARGER_THAN_WORLD` fail-gate covers the world-cap path in every test
  that opens any pop-up.

## §7 Rejected alternatives — do NOT re-attempt

- **⛔ Direct contents WITHOUT the pure-measure redesign** — falsified twice, the second
  time (2026-08-19) with the full scrolled-content contract declared; permanent two-writer
  oscillation, measured (probe + ring buffer; record: BACKLOG §7.2, soon rewritten by
  Phase 3 but preserved). This plan exists BECAUSE that shape fails; Phase 1 is legal only
  with §3.1 landed first.
- **⛔ A conditional / lazily-materialized viewport** (only when rows overflow) — litigated
  and rejected in `_buildRowsViewportNoSettle`'s comment: a threshold is a mid-life
  restructure someone must get right during the very membership change that provoked it.
- **Route (c): the viewport stops committing frames for self-sizing planes** (an
  `ownsItsFrame()` capability; the viewport only clamps offsets + places bars from the
  content extent). Deliberately NOT taken: it forks the frame-ownership doctrine for one
  consumer, touches the arrange for EVERY viewport, and buys nothing the
  container-as-sole-committer shape doesn't — reconsider only if Phase 0 falsifies the
  chosen shape.
- **The transform-island machinery as the pop-up carrier** — rejected long since (islands
  are raster-warp with per-island buffers; see the paint-time scroll plan §1.2).

## §8 References

- `docs/BACKLOG.md` §7.2 refusal line (the falsification record + probe name).
- `docs/archive/paint-time-scroll-translation-plan.md` — the offset model (STATUS BOX = its
  ledger); `docs/architecture/viewports-and-planes.md` — the living contract this plan
  amends.
- `docs/archive/menu-row-conformance-plan.md` — the arc that built the honest measures
  (Phase 3) and the row-equalization the arrange relies on.
- `docs/archive/scroll-frame-role-architecture-plan.md` §7 — the role vocabulary + the
  first falsification.
- Src anchors (grep the symbols): `PopUpWdgt._buildRowsViewportNoSettle` /
  `_layOutAndHugRowsPanel` / `_refitRowsViewportNoSettle` / `_reLayOutAfterContainedPanelChange`;
  `MenuRowsPanelWdgt._positionAndResizeChildren` / `preferredExtentForWidth` /
  `subWidgetsMergedPreferredBounds` / `maxWidthOfMenuEntries`;
  `PopUpRowsViewportWdgt` / `PopUpRowsPaneWdgt` (both whole-file);
  `ViewportWdgt._positionAndResizeChildren` / `setContents` / `_writeScrollOffset`.

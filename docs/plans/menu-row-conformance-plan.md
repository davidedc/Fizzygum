# Menu-row conformance + hug-class stack — ironing out the §5.2e residual wrinkles

> **STATUS: ✅ ARC COMPLETE 2026-07-19 (same day as authored).** Phases 1, 2a–2e and 3 ALL
> LANDED + PUSHED (`11dbee31`→`daf46382`→`91fab1c8`→`7685dfce`→`645299dd`→`2ea6f06b`→
> `1a806e9c`; one mid-2e falsification+revert `dc351521`→`c1392eb2`, see §1). Phase 4 RUN AND
> FALSIFIED (#2) — the tracking-pop-up shape is permanently CLOSED; see its section + §8 for
> the evidence and the only sanctioned re-frame. Every §5.2e wrinkle is eliminated at the
> root: pure row measures, four conformant row types, no post-pass, honest hug-class
> measures. The doc below is kept as the arc's record (original plan text unedited except
> the two falsification notes).
>
> *(original header)* **PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO
> prior context.** STATUS: AUTHORED 2026-07-19, no code written. Follow-on of the
> container-regularization arc (`docs/plans/container-regularization-plan.md` §5.2e, landed
> 2026-07-19). Do NOT start this plan until that arc's §5.2e commit has LANDED (recapture +
> gauntlet green + pushed) — this plan edits the same files.
>
> **MANDATE: complete elimination of the non-conformance, not deeper burial.** The four
> §5.2e wrinkles (double-write arrange, hand-rolled-tracker row types, width-flow
> asymmetry, current-width ratchet) share ONE root — the menu row types predate the
> layout engine's child contract and hand-roll their innard re-layout in bespoke
> `_applyWidth`/`_applyExtent` overrides. This plan makes the row types CONFORM to the
> engine's model, at which point the panel's compensations delete themselves. It does
> NOT add compatibility shims, marker methods, or new parallel mechanisms.

## §0 Orientation

**Framework.** Fizzygum: CoffeeScript single-canvas GUI framework; `nil` = undefined;
one class per file, filename == class name; classes are globals compiled in-browser.
Layout reference: `docs/architecture/layout.md` (READ ITS §on settle tiers + the
new-layout rulebook before editing). Build/test wrapper: the umbrella `fg` script —
invoke as `/Users/davidedellacasa/code/Fizzygum-all/fg …` (never `./fg`; cwd is a trap).

**The immediately-prior arc (§5.2e, landed 2026-07-19).** `MenuRowsPanelWdgt` — the
shared rows-panel that is the whole visible body of every `MenuWdgt`, `PromptWdgt`
and `ListWdgt.listContents` — was re-based from a hand-laying `Widget` subclass onto
`SimpleVerticalStackPanelWdgt`, the ONE vertical-stack engine. Menu-ness now enters
only through the base's policy seams:

- `interElementGap()` — new base policy method (default `@padding`, byte-identical for
  every pre-existing stack), overridden to `0` on the panel: rows sit FLUSH inside a
  2px border (`super nil, nil, 2` in the panel ctor).
- ~~`_childWidthInStack` override → every row is handed the full available width.~~
  **⚠⚠ FALSIFIED at Phase 2e's first landing (2026-07-19, reverted `dc351521`→`c1392eb2`): this
  override NEVER existed in the landed §5.2e** — equalization lived ENTIRELY in the post-pass, and
  deleting the post-pass alone left rows at their narrow spec widths (7 gauntlet legs red). The
  corrected 2e adds the override + deletes the post-pass TOGETHER. Every other §1 citation was
  re-verified live; this one had been carried from the §5.2e design notes instead of the code.
- ONE arrange specialization on the panel (quoted in §1.4 below): hug own width to
  widest row → `super()` → post-pass stretching every row via the VIRTUAL `_applyWidth`.
- `PopUpWdgt` gained the shared `rowsPanel` field, `_layOutAndHugRowsPanel`, and a
  `_reLayOutAfterContainedPanelChange` membership absorber (the same designed seam
  `ScrollPanelWdgt` uses); `MenuWdgt`/`PromptWdgt` inherit all three.

Evidence at landing: `fg census` 0 movers / 1623 targets (arrange is a fixed point);
`fg revisits` profile == the EMPTY baseline (no settle re-visits); 0 integer-placement
violations; 54-test conscious recapture (menus 1px shorter under the title, untitled
panels' rows 1px lower — owner-eyeballed and approved).

**Why this plan exists.** §5.2e left four candidly-named wrinkles (see §3). They were
quarantined behind one panel override rather than fixed, because the fix's blast radius
(row types used outside menus; engine-wide discriminator flips) deserved its own gated
arc. This is that arc.

**⚠ CRITICAL REFRAME — read this first.** The wrinkles are NOT four problems. They are
one problem seen four times: **`SliderWdgt`, `StringFieldWdgt`, `ColorPickerWdgt` and
`MenuHeader` are "leaves with internal arrangement"** — widgets whose innards must
re-arrange when their frame changes, implemented as bespoke `_applyWidth`/`_applyExtent`
overrides instead of the engine's two sanctioned shapes (deferred `_reLayout`, or
size-tracking `_reLayoutChildren`). Everything else in this plan is a consequence:
the panel's post-pass exists to fire those bespoke overrides; the ratchet exists
because their `menuEntryPreferredWidth` reads applied geometry instead of a pure
measure; the width-flow asymmetry persists because the panel's measures can't be
honest until the row measures are.

## §0.5 Cold-execution protocol

1. Verify state: `/Users/davidedellacasa/code/Fizzygum-all/fg status` — all three repos
   clean-or-known-dirty, build FRESH, no zombie browsers. The container-regularization
   §5.2e commit must be in `Fizzygum` history (grep `git -C …/Fizzygum log --oneline -5`
   for the §5.2e commit).
2. Re-verify EVERY code citation in §1 against current src before trusting it — line
   numbers drift; the method name + quoted code is authoritative. `grep -n` each symbol.
3. Execute phases IN ORDER (1 → 2 → 3 → 4). Phases are independently committable;
   each closes with the §6 verification protocol. Do not batch two phases into one
   commit on the first attempt.
4. Phase 2 is per-TYPE (2a…2d): one row type per step, each gated. STOP a step after
   two falsified fix-shapes (owner standing rule) and record the falsification here.
5. Pixel policy: phases 1–3 aim BYTE-IDENTICAL (they re-route the same numbers through
   different code paths). Phase 4 aims byte-identical too but is an EXPERIMENT (§5.4).
   ANY pixel shift ⇒ `fg diffpage <tests>` + owner eyeball BEFORE recapture; never
   recapture unattended.
6. Never edit `src/**` while a suite/recapture is running. `fg killz` clears browsers.

## §1 Architecture as it stands (verified 2026-07-19 — re-grep before trusting)

### 1.1 The engine's child contract (the model rows must conform to)

`SimpleVerticalStackPanelWdgt._positionAndResizeChildren` sizes each child by KIND
(quoted from src, comments elided):

```coffee
if widget._reLayoutChildren?
  elementHeight = widget._setWidthSizeHeightAccordingly recommendedElementWidth
else
  measured = @_childMeasuredExtentInStack widget, recommendedElementWidth
  widget._applyExtentBase measured
  elementHeight = measured.y
```

- **TRACKING child** (`_reLayoutChildren?` defined — today only
  `SimpleVerticalStackPanelWdgt` (+ subclasses `WindowWdgt`, `MenuRowsPanelWdgt`),
  `ScrollPanelWdgt`, `TrackingTransformFrameWdgt`): sized via
  `Widget._setWidthSizeHeightAccordingly` =
  ```coffee
  @_applyWidth newWidth            # VIRTUAL — subclass overrides fire
  if @implementsDeferredLayout()
    @_reLayout()                   # synchronous innard re-fit, no invalidate
  @height()                        # Path B: height handed forward, never read back
  ```
- **LEAF child** (everything else): pure measure + the override-BYPASSING
  `_applyExtentBase`. The engine assumes a leaf has NO internal arrangement.

Two more load-bearing base facts:

- `Widget.implementsDeferredLayout: -> @_reLayout != Widget::_reLayout` — **DERIVED**:
  overriding `_reLayout` is what makes a widget "deferred". (The stack PINS it false
  explicitly with a comment explaining why — do not copy that pin onto row types.)
- `Widget._applyExtent` (the rule-[E] sanctioned schedule-valve):
  ```coffee
  _applyExtent: (aPoint) ->
    if aPoint.equals @extent() then return
    @_applyExtentBase aPoint
    if @children.length != 0
      @_scheduleRelayoutRespectingPhase()
  ```
  Any child-bearing widget resized through the VIRTUAL `_applyExtent` gets a re-layout
  scheduled (in-pass: `__markForRelayout`; off-pass: `_invalidateLayout`).

### 1.2 The `_reLayoutChildren?` discriminator sites (the Phase-2 gate-flip surface)

Declaring `_reLayoutChildren` on a row type flips its classification at exactly these
sites (grep `_reLayoutChildren?` to re-enumerate; verified count 2026-07-19, excluding
`_reLayoutChildrenAndScrollbars`):

| Site | Effect of the flip on a row type |
|---|---|
| `SimpleVerticalStackPanelWdgt.coffee:268` (arrange, size branch) | DESIRED: routes through `_setWidthSizeHeightAccordingly` (virtual `_applyWidth` + synchronous deferred re-fit) |
| `SimpleVerticalStackPanelWdgt.coffee:298` (arrange, move branch) | row moved via `_applyMoveTo` (polymorphic) instead of `_applyMoveToBase` — a repaint-path change for CLIPPING widgets only (`StringFieldWdgt extends PanelWdgt` — check its clip mixin) |
| `Widget.coffee:2376` `_reFitContainer` | a row's CHILD calling `_reFitContainer(@parent)` now enqueues the row (was: silent no-op) |
| `Widget.coffee:4650` freefloating-child invalidate climb | a FREEFLOATING child's off-pass invalidate now climbs THROUGH into the row |
| `WindowWdgt.coffee:772` | window `@contents` only — inapplicable to row types |

### 1.3 The four row types' CURRENT shapes (three different patterns — verified)

**SliderWdgt** (`src/basic-widgets/SliderWdgt.coffee`) — innards = `@button` (thumb):
```coffee
menuEntryPreferredWidth: -> @width()          # ← read-back ratchet
_applyExtent: (aPoint) ->                     # ← bespoke innard hook
  unless aPoint.equals @extent()
    super aPoint
    @button._reLayoutSelf()
_reLayoutSelfAndButton: ->                    # value/geometry-change couplet (KEEP)
  @_reLayoutSelf()
  if @button? and @button instanceof SliderButtonWdgt
    @button._reLayoutSelf()
  @_changed()
```
No `_reLayout` override ⇒ deferred = false. `_reactToBeingAdded -> @_reLayoutSelfAndButton()`.

**StringFieldWdgt** (`src/basic-widgets/StringFieldWdgt.coffee`) — `extends PanelWdgt`;
innards = `@text` (a StringWdgt, lazily built):
```coffee
menuEntryPreferredWidth: -> @width()          # ← ratchet
_applyWidth: (newWidth) ->                    # ← bespoke innard hook
  super
  @text._applyWidth 300
_reLayoutSelf: ->                             # lazy-builds @text, then:
  ...
  @text._applyMoveTo @position().add new Point 5,2
  @text._applyExtent new Point 300, 18
  @__commitExtent new Point @width(), 18
calculateAndUpdateExtent: ->                  # the BUILD-time natural width:
  ...
  @_applyWidth Math.max @minTextWidth, text.width()   # minTextWidth default 100
```
The inner text is deliberately 300-wide + SCALEDOWN (header comment: keeps
`StringWdgt.edit` on its INLINE branch — do not "fix" the 300).

**ColorPickerWdgt** (`src/ColorPickerWdgt.coffee`) — innards = `@colorPalette`,
`@grayPalette`, `@feedback`; ALREADY on the deferred pattern:
```coffee
menuEntryPreferredWidth: -> @width()          # ← ratchet (natural = ctor's 80×80)
constructor: -> ... @_applyExtent new Point 80, 80 ...
_reLayout: (newBoundsForThisLayout) ->        # full bounds-first custom _reLayout:
  ...                                         #   applies own bounds, arranges the
  @_applyBounds newBoundsForThisLayout        #   palettes/feedback from the frame,
  @colorPalette._applyMoveTo @position() ...  #   idempotent since the V3 fix
  ...
  super
  @_markLayoutAsFixed()
```
⇒ deferred = TRUE (derived). NO `_applyExtent`/`_applyWidth` override: in a stack's
LEAF branch, `_applyExtentBase` bypasses the valve, so its palettes are kept fresh in
menus TODAY only because the panel's post-pass `_applyWidth` fires the valve
(`children.length != 0 → schedule`). **The post-pass is currently load-bearing for
ColorPickerWdgt — delete it only after 2c makes the picker a tracking child.**

**MenuHeader** (`src/basic-widgets/menu-system/MenuHeader.coffee`) — `extends BoxWdgt`;
innards = `@text` (centred title):
```coffee
_applyWidth: (theWidth) ->                    # ← bespoke innard hook
  super
  @text._applyMoveTo (@center().subtract @text.extent().floorDivideBy 2).round()
_buildAndConnectChildrenNoSettle: ->          # natural extent = text + 2:
  ... @_applyExtent @text.extent().add 2
```
No `menuEntryPreferredWidth` — the panel's `maxWidthOfMenuEntries` special-cases it:
`if @label then w = Math.max w, @label.width()` (a read-back: post-stretch it ratchets).

**The ratchet, precisely:** on the FIRST arrange all four report/carry their natural
widths; the post-pass stretches every row to the widest; on any LATER arrange the three
`-> @width()` measures and the `@label.width()` special case report the STRETCHED
width, so the hug can never shrink (a row removal leaves the panel at the old width).
Stable and census-proven idempotent — but measurement-by-read-back, and no-shrink.

### 1.4 The panel's §5.2e arrange (what Phase 2 lets us shrink)

`src/basic-widgets/menu-system/MenuRowsPanelWdgt.coffee`:
```coffee
_positionAndResizeChildren: ->
  world.disableTrackChanges()
  @_applyExtentBase new Point (@maxWidthOfMenuEntries() + 2 * @padding), @height()
  super()
  w = @availableWidthForContents()
  @children.forEach (item) ->
    item._applyWidth w                        # ← the double-write / post-pass
  world.maybeEnableTrackChanges()
  @_fullChanged()
```
The post-pass exists ONLY because the leaf branch's `_applyExtentBase` cannot fire the
four types' bespoke hooks (§1.3). Every row already RECEIVES the full width from the
`_childWidthInStack` override — with conformant rows, both engine branches emerge
pre-equalized and the post-pass deletes.

### 1.5 The width-spec model (context for why grow/desired need no changes)

`VerticalStackLayoutSpec`: `width = round(min(availW, desired + grow*(availW-desired)))`;
capture derives desired from the element's natural width at placement. The panel's
`_childWidthInStack` override bypasses spec width entirely for rows, so NO spec changes
are needed anywhere in this plan.

## §2 Why it's shaped this way (history)

The four row types predate the modern engine: they were menu furniture when the menu
hand-laid its rows (`item._applyWidth w` in the old `adjustWidthsOfMenuEntries`), so
"stretch fires my bespoke width hook" WAS the contract. §5.2a lifted the menu's layout
into `MenuRowsPanelWdgt` verbatim; §5.2e replaced the layout with the stack engine but
kept the virtual-`_applyWidth` post-pass precisely so the four types' hooks kept firing
— correctness first, conformance deferred to this plan.

## §3 The distilled argument

- The engine has exactly two sanctioned shapes for "my innards track my frame":
  deferred `_reLayout` (ColorPicker already has it) and tracking `_reLayoutChildren`
  (+ the `_setWidthSizeHeightAccordingly` synergy when both are present). Bespoke
  `_applyWidth`/`_applyExtent` innard hooks are a THIRD, unsanctioned shape that only
  works when every resizer remembers to use the virtual path — the stack's leaf branch
  deliberately does not (it uses the proven byte-exact `_applyExtentBase`).
- Making the four types conform (a) deletes the panel's double-write post-pass as a
  CONSEQUENCE, not a patch; (b) is proven-or-falsified cheaply per type by the same
  three gates that just validated §5.2e (suite byte-diff, census 0 movers, revisits
  empty); (c) fixes the same latent staleness everywhere else these types are resized
  through base paths (sliders/pickers in document stacks).
- Pure row measures (Phase 1) then make `maxWidthOfMenuEntries` a true content measure,
  which unlocks honest panel measures (Phase 3) and shrink-on-remove.
- Phase 4 re-tests the §5.2d-falsified "menu as tracking container" under the ONE
  changed precondition (the arrange is now a fixed point — census-proven). Either
  outcome is clean: green ⇒ delete the custom popUp drive + absorber (menus fully
  standard); red ⇒ falsification #2, lay-once is permanent, documented here.

## §4 Target invariant (the plan's definition of done)

> Every menu row type's internal arrangement is reachable ONLY via the engine's
> standard chokepoints (`_reLayout` / `_reLayoutChildren`); no widget re-lays its
> innards from a bespoke `_applyWidth`/`_applyExtent` override; every
> `menuEntryPreferredWidth` is a pure content measure (no `@width()` read-back);
> the panel's arrange contains no post-pass; the panel's pure measures describe its
> actual (content-driven) width policy.

## §5 The phases

### Phase 1 — pure row measures (kills the ratchet; enables Phase 3)

For each of the three `menuEntryPreferredWidth: -> @width()` sites, replace the
read-back with the type's REAL content measure. Verified natural widths:

- **SliderWdgt**: no intrinsic content width — its natural width is whatever the
  builder sized it to. Capture at build: in the ctor (after super), store
  `@menuEntryNaturalWidth = @width()` is WRONG (ctor width is default) — instead
  capture at the FIRST `menuEntryPreferredWidth` call if unset, or (better) have the
  prompt/menu builder that sizes the slider record it. SPIKE S1 (30 min): grep who
  builds slider rows (`PromptWdgt`/`NumberPromptWdgt` slider case, popover sliders)
  and where their width is set; pick the capture point that equals today's
  first-arrange answer BYTE-EXACTLY; only then implement.
- **StringFieldWdgt**: the natural width already exists —
  `calculateAndUpdateExtent`'s `Math.max @minTextWidth, text.width()`. Store it there
  (`@menuEntryNaturalWidth = …`) and answer it; fall back to `@width()` if the field
  was never measured (guard, not shim — grep callers to confirm every build path runs
  `calculateAndUpdateExtent`; if one doesn't, that's the spike finding to fix).
- **ColorPickerWdgt**: natural = the ctor's design extent (80) or the builder's resize.
  Same spike S1 treatment as the slider.
- **MenuHeader**: ADD `menuEntryPreferredWidth: -> @text.width() + 2` (its build
  formula) and DELETE the `if @label` special case in
  `MenuRowsPanelWdgt.maxWidthOfMenuEntries` — the walk becomes uniform.

Behaviour change (intended, tiny): the hug can now SHRINK when rows are removed from
an open menu (absorber path). No test covers that today (verified §5.2d: no test
exercises remove-post-popup); pixels should hold byte-identical everywhere else —
verify per §6, diffpage anything that moves.

### Phase 2 — row-type conformance (kills the root; the post-pass deletes at the end)

One type per step, EACH gated per §6 before the next. Target shape per type (adapted,
not one-size — §1.3 shows three starting patterns):

- **2a MenuHeader** (smallest, menus-only — do first):
  `_reLayoutChildren: -> <the text re-centre line from _applyWidth>`;
  `_reLayout: (nb) -> super; @_reLayoutChildren()`; DELETE the `_applyWidth` override.
  Note deferred flips true (derived) — check the two read sites
  (`Widget.coffee:778/1171`, bounds-vs-fullBounds contribution): the centred text is
  inside the header's bounds ⇒ identical. Header is now a TRACKING child in the panel
  ⇒ sized via `_setWidthSizeHeightAccordingly` → virtual `_applyWidth` (base now) +
  synchronous `_reLayout` ⇒ re-centred in one write.
- **2b SliderWdgt**: `_reLayoutChildren: -> if @button? and @button instanceof
  SliderButtonWdgt then @button._reLayoutSelf()`;
  `_reLayout: (nb) -> super; @_reLayoutChildren()`; DELETE the `_applyExtent`
  override; `_reLayoutSelfAndButton` STAYS (value-change couplet) but its body can
  now be `@_reLayoutSelf(); @_reLayoutChildren(); @_changed()`. ⚠ sliders live in
  document stacks + windows + popovers: the discriminator flip (§1.2) re-routes them
  in EVERY stack. Aim byte-identical; the suite's slider tests
  (`macroSlider*`, `macroLonelySlider*`, `macroMovingSlidersSideways…`,
  `macroPopoverStaysOpenWhenSliderDraggedOut`) are the canary set.
- **2c ColorPickerWdgt**: extract the arrange lines of its custom `_reLayout` (palette
  moves/extents + feedback, between `@_applyBounds` and `world.maybeEnableTrackChanges`)
  into `_reLayoutChildren: ->`; `_reLayout` keeps its bounds-first shape and calls it
  (mirroring the stack's own composition). Deferred already true ⇒
  `_setWidthSizeHeightAccordingly` now re-fits it SYNCHRONOUSLY in stack arranges —
  this REPLACES the panel-post-pass valve dependency (§1.3 warning).
- **2d StringFieldWdgt**: `_reLayoutChildren: ->` = the text move/extent lines from
  `_reLayoutSelf` (keep the lazy build in `_reLayoutSelf`); wire `_reLayout` like 2a;
  DELETE the `_applyWidth` override (its `@text._applyWidth 300` folds into
  `_reLayoutChildren`; keep the 300 — see §1.3 note). ⚠ extends PanelWdgt (clipping):
  the arrange's move branch flips to `_applyMoveTo` (the clip mixin's scroll-optimized
  override) — a repaint-path change; watch the prompt tests.
- **2e Delete the panel's post-pass** (the `w = …; @children.forEach …` lines in
  §1.4's quote) — every child now takes the tracking branch (2a–2d) or is a true leaf
  (`MenuItemWdgt` — label-only, base `_applyWidth` has no override; `DividerWdgt` —
  a stretched rectangle). **AND add the `_childWidthInStack -> availForContents`
  width-policy override in the SAME step** — it did not exist (see the §1 falsification
  note): without it the engine sizes rows at their narrow spec widths and the deletion
  alone reds out 7 gauntlet legs. Also delete the now-unneeded
  `world.disableTrackChanges()` bracket IF the remaining body is just hug+super
  (super's own applies handle repaint; verify no paint-audit regression).

STOP RULE: any step that falsifies twice (oscillation, pixel shift the owner rejects,
gate red that resists one re-frame) → revert that step, record the falsification in
this doc, CONTINUE with the next type. Partial conformance is fine; 2e requires ALL
of 2a–2d landed.

### Phase 3 — honest panel measures (kills the width-flow asymmetry)

With Phase 1's pure `maxWidthOfMenuEntries`:
- Override on the panel: `preferredExtentForWidth: (availW) -> new Point
  (@maxWidthOfMenuEntries() + 2 * @padding), <height from the base measure at that
  width>` — the panel's width is content-driven, availW-independent; reuse the base's
  height arithmetic (call `super` with the hug width, take `.y`).
- Mirror `subWidgetsMergedPreferredBounds` the same way.
- The arrange's width-hug line then IS "apply my own pure measure" — the standard
  hug-class pattern (`WindowWdgt.preferredExtentForWidth` precedent; and note the base
  already hugs HEIGHT via `tight: true` — a menu panel hugs both axes).
- Do NOT add a `hugsContentWidth` knob to the base now (no second client; YAGNI —
  noted for promotion if one appears).
Consumers today: NONE (ListWdgt is excluded from the scroll-stack refit via its
`_reLayOutAfterContainedPanelChange: -> nil`; grep to re-verify) — so this phase is
byte-identical BY CONSTRUCTION and exists for model honesty + future consumers.

### Phase 4 — EXPERIMENT: menus/prompts as true tracking containers
**⛔ RUN AND FALSIFIED 2026-07-19 (falsification #2) — the shape is CLOSED. Nothing committed
(verdict read before commit; working tree reverted to `1a806e9c`). THE EVIDENCE, precisely:**
NOT the §5.2d ±1px oscillation — census stayed 0 movers and no re-visit profile change was
ever measured (the gates abort on a failing suite). ONE test failed all suite legs:
`macroInspectorWorkAreaEvaluatesCoffeeScript`. The pixel evidence, measured (not eyeballed):
the inform popup did NOT move — a horizontal-translation sweep over the changed rows has its
MINIMUM residual at dx=0 — but its "Ok" row's HOVER-HIGHLIGHT state changed (rows spanning
the full popup width differ in place; the owner identified it on sight). That is EXACTLY the
§5.2d user-visible symptom class — "un-hovered the item under the pointer" — the same class
`isTransparentAt -> true` fixed in §5.2d/§5.6, now re-surfaced by the tracking re-visit
interfering with the pointer-hover pipeline. (A first-draft record here blamed a
`popUpCenteredAtHand` half-width mis-placement; the dx sweep FALSIFIED that reading — kept as
a warning that diff crops mislead and translation must be MEASURED.) Root interaction not
fully diagnosed — deliberately: falsification #2 closes the shape, and a diagnosis would only
serve a banned third attempt. Any future re-frame must FIRST explain the tracking↔hover
interaction (see [[hover-resync-after-flush-swap]] memory: the hand re-checks hover after
`recalculateLayouts` — an extra menu re-visit inside that window is the prime suspect).

*The original experiment spec (kept for the record):*

§5.2d FALSIFIED menu-as-tracking-container: "an on-every-settle re-drive shifted the
menu ±1px, un-hovering the item under the pointer" (container-regularization-plan.md
§5.2d lesson 2). The CAUSE was the old non-idempotent hand arrange (zero-extent →
place → `fullBounds()+2` read-back). That cause is GONE: the §5.2e arrange is
census-proven a fixed point. One changed precondition ⇒ one sanctioned re-test:

1. `MenuWdgt._reLayoutChildren: -> @_layOutAndHugRowsPanel()` (PromptWdgt inherits
   nothing here — add the same on PromptWdgt if step 3 applies to it).
2. Gates: census + revisits MUST stay 0/empty; the dpr1 suite byte-identical.
   ANY oscillation ⇒ falsification #2 of this shape ⇒ revert, mark §8
   do-not-re-attempt, DONE (lay-once is then permanent and documented).
3. If green: try DELETING `MenuWdgt._reactToBeingAdded` (the custom popUp drive) and
   the `PopUpWdgt._reLayOutAfterContainedPanelChange` absorber — SPIKE S2 first:
   verify the add path actually visits a fresh menu's `_reLayout` in the popUp's
   settle (instrument or headless-probe; `popUp` → `widgetToAttachTo.add @` — confirm
   the add invalidates the menu's layout). If it does not, KEEP `_reactToBeingAdded`
   as the drive and delete only the absorber (the settle's ordered up-edge re-fit
   covers membership changes for a tracking container). Placement safety (verified):
   `popUpCenteredAtHand` reads `@extent()` BEFORE `popUp` — extent is zero pre-layout
   under BOTH models ⇒ placement byte-identical.
4. Deferred flips true for menus (derived): check the bounds-vs-fullBounds read sites
   as in 2a (panel is inside the menu's hugged bounds; shadow is `@shadowInfo`, not a
   child ⇒ identical).

Success deletes ~25 lines of special-casing (menus become fully standard containers);
failure costs one revert and buys a documented second falsification. Both are wins.

## §6 Verification protocol (per phase / per Phase-2 step)

1. `/Users/davidedellacasa/code/Fizzygum-all/fg build` — must be EXIT=0 (syntax gate +
   stinks/thin-wraps/call-separation baselines).
2. `/Users/davidedellacasa/code/Fizzygum-all/fg suite` (dpr1, ~1.5 min) — expect
   **0 failures** (byte-identical; the §5.2e references are the baseline). Any failure
   ⇒ `fg diffpage <test…>` + owner eyeball; do not recapture without approval.
3. `/Users/davidedellacasa/code/Fizzygum-all/fg census` — MUST stay 0 movers.
4. `/Users/davidedellacasa/code/Fizzygum-all/fg revisits` — profile MUST equal the
   committed EMPTY baseline. (If the suite has failures the gate aborts before
   comparing; re-check the profile alone with
   `cd Fizzygum-tests && node scripts/revisit-gate.js --audit-dir=.scratch/revisit-gate-out`.)
5. Close each phase (before its commit) with the full
   `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet` — 11/11 required.
   Long ops: `run_in_background`, wait for the notification; never foreground-poll.
6. Commit per phase, owner approval first (ask-before-commit), `git commit -F <file>`,
   stage ONLY the files this plan touched.

## §7 Pixel-risk map

| Phase | Risk | Canary tests |
|---|---|---|
| 1 | ~nil (measures equal today's first-arrange answers by construction; shrink-on-remove has no covering test) | the 54-test §5.2e recapture set |
| 2a | nil expected (same centring line, new home) | all titled-menu tests |
| 2b | LOW but broad (sliders re-routed in every stack) | `macroSlider*`, `macroLonelySlider*`, `macroMovingSlidersSideways…`, `macroPopoverStaysOpenWhenSliderDraggedOut` |
| 2c | LOW (synchronous re-fit replaces valve-scheduled re-fit — same numbers, earlier timing) | `macroBoxTransparencyAndColorChanging`, `macroCanMoveAndResizeColorPaletteWdgt`, `macroSpreadsheetColorCell` |
| 2d | LOW-MED (clip-mixin move-path flip) | prompt tests: `macroSaveAsPromptAboveTiltedWindow`, `macroStringWdgtEditDefersToPromptWhenCropped`, `macroPromptShadowFollowsOnDrag` |
| 2e | nil expected (post-pass is a no-op once 2a–2d landed) | full suite |
| 3 | nil by construction (no consumers) | full suite |
| 4 | the §5.2d ±1px oscillation, if the fixed-point premise is wrong | census/revisits + `macroHoppingBetweenSubMenus`, `macroMenuRepositionsToStayOnScreen` |

## §8 Rejected alternatives — do NOT re-attempt blind

- **Empty-marker `_reLayoutChildren: ->` on row types** (to route the tracking branch
  without real bodies): a lying classifier — the codebase's type-test-elimination
  convention rejects marker methods; and it leaves the innard hooks bespoke. Rejected
  at authoring, never attempted.
- **Making the engine's LEAF branch dispatch virtually** (`_applyExtent` instead of
  `_applyExtentBase`): the base's leaf path is deliberately override-bypassing and
  proven byte-exact for text/clock/box (§1.1 quote's provenance comment); flipping it
  re-fires every leaf's `_applyExtent` valve on every stack arrange, engine-wide.
  Rejected at authoring.
- **A `_applyChildSizeInStack` policy seam on the base** (panel overrides the APPLY):
  considered during §5.2e; rejected as speculative base surface once the post-pass
  (temporary) + this conformance arc (permanent) covered both horizons.
- **Menu-as-tracking-container — PERMANENTLY CLOSED (two falsifications, different doors):**
  #1 2026-07-18 (§5.2d): with the old non-idempotent hand arrange, an on-every-settle re-drive
  oscillated the menu ±1px (census/revisits red). #2 2026-07-19 (this plan's Phase 4): with the
  fixed-point arrange the oscillation was indeed gone (census 0), but the SAME user-visible
  symptom class returned by another door — the inform's "Ok" row lost its hover highlight
  (no translation: the dx-sweep's minimum residual is at 0;
  `macroInspectorWorkAreaEvaluatesCoffeeScript`), i.e. the tracking re-visit interferes with
  the pointer-hover pipeline. Do not attempt a third shape; any re-frame must FIRST explain
  the tracking↔hover interaction (see the Phase 4 falsification note).
- **`--no-build` capture shortcuts** during any recapture this plan needs: hard-banned
  (capture script refuses; see its header for the two audited incident classes).

## §9 References + BACKLOG lines

- `docs/plans/container-regularization-plan.md` — §5.2a–§5.2e history + lessons.
- `docs/architecture/layout.md` — settle tiers, rulebook, chokepoint vocabulary.
- `docs/architecture/layering-naming-convention.md` §6 — container roles.
- Memory: `onion-widget-composition-arc` (arc state), `stop-iterating-fix-shapes-after-two-falsifications`, `dont-let-recapture-churn-dictate-design`.
- **BACKLOG lines to add** (NOT yet added — `docs/BACKLOG.md` is currently dirty with
  the unrelated pixel-icons arc; add these verbatim when that resolves, or fold into
  this plan's first commit if BACKLOG is clean by then):
  - `- Menu-row types hand-roll innard re-layout (Slider/StringField/ColorPicker/MenuHeader) → docs/plans/menu-row-conformance-plan.md §5 Phase 2`
  - `- MenuRowsPanelWdgt post-pass double-write + width-flow asymmetry → docs/plans/menu-row-conformance-plan.md §5 Phases 2e/3`
  - `- menuEntryPreferredWidth current-width ratchet (no-shrink hug) → docs/plans/menu-row-conformance-plan.md §5 Phase 1`

## §10 Ready-to-paste start prompt (fresh session)

```
Execute Fizzygum/docs/plans/menu-row-conformance-plan.md — the follow-on arc that
makes the four menu row types conform to the layout engine's child contract and then
deletes MenuRowsPanelWdgt's compensating post-pass. PLAN IS SELF-CONTAINED: read it
top-to-bottom first; §0.5 is the execution protocol, §1 the verified current state
(re-grep every citation before trusting), §5 the phases (1 → 2a–2e → 3 → 4, one
commit each, gated per §6). Verify workspace state with
/Users/davidedellacasa/code/Fizzygum-all/fg status; the container-regularization
§5.2e commit must already be in Fizzygum history. Owner rules: ask before commit/push;
byte-identical or diffpage+eyeball before any recapture; stop a step after two
falsified fix-shapes and record the falsification in the plan.
```

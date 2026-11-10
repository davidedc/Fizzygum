# Mixin removal — every mixin to an ordinary home, then delete the mechanism

**STATUS: PLAN ONLY — AUTHORED 2026-11-10. No code written. Phase 0 (investigations S1–S3, owner
decisions D1–D5) is the next step.** Written to be executed COLD by an LLM/engineer with ZERO prior
context: everything needed is embedded here or one named-doc hop away.

Every fact below was read on 2026-11-10 at Fizzygum `a37b8ba4` (its `src/` unchanged since
`2bc853f9`) / Fizzygum-tests `61adb7ce1`. **Line numbers are hints and drift; the quoted method name is authoritative — grep it
fresh before trusting a line.** Counts come with the command that produced them (§2.4); re-run it
rather than carrying a number forward.

**Mandate.** Complete elimination: all eight mixins move to homes the rest of the system already
understands (a base class, an `Appearance`, a collaborator, a hook on the object that owns the
fact), and then the mechanism itself is deleted — `src/meta/Mixin.coffee`, `augmentWith`, the
emulated `super`, the inspector's donor vocabulary, the mixin edit/replay paths, and the mixin DSL
branches in the build tools. Not "fewer mixins", and not a mixin mechanism kept dormant "in case".
The arc is a net simplification only if no mixin is replaced by NEW machinery (§8 R1).

---

## §0 Orientation

### 0.1 What Fizzygum is, in three lines

A CoffeeScript GUI framework ("web operating system") drawn on one `<canvas>`, descended from
Morphic.js. No module system: every class is a global, one class per file, sources ship as text and
compile in the browser; `src/meta/Class.coffee` and `src/meta/Mixin.coffee` parse each source at
run time, which is what makes every class inspectable and editable live. Repo layout, build and
test commands: `../../CLAUDE.md` and the umbrella `Fizzygum-all/CLAUDE.md`.

### 0.2 Why this plan exists now

`docs/architecture/mixins.md` holds the standing position: **keep the mechanism** (its §1, §7),
verified 2026-08-16. On 2026-11-10 the owner stated the opposite preference — mixins "add complexity
to the codebase in terms of their injection, their tracking, how the inspector handles them" — and
asked for a path to remove them. Two independent analysis passes the same day (the second
re-verified the first against `src/`) found that the keep position rests on two premises that do
not hold, and that a removal path exists for all eight. This plan records that reasoning and turns
it into investigations and phases. **Until it executes, `mixins.md` still describes how the
mechanism WORKS; only its keep-vs-remove POSITION is superseded by this plan.**

### 0.3 The critical reframes — read these before anything else

1. **The hierarchy is flat, so "unrelated branches" is mostly false.** `mixins.md` §1 argues the
   consumers "share no usable base". Of the 28 consumer classes, 19 extend `Widget` directly, 8 sit
   one level below it and 1 sits two levels below (§2.2). For most mixins an ordinary base class
   between `Widget` and the consumers is available at no cost, because the inheritance slot it
   would occupy is unused.
2. **This is the weak kind of mixin: members are COPIED onto the consumer's prototype.** There is
   no linearised chain, so a consumer that overrides a mixin member cannot `super` into the mixin's
   version. Three of the eight mixins already have consumers working around exactly that (§2.3).
   A base class removes the workaround; it is not merely "as good".
3. **`BackBufferMixin` is the crux, and it is NOT a blocker.** It cannot end as a base class:
   `CanvasWdgt` needs it together with clipping, and `StringWdgt`/`PaletteWdgt` need it together
   with wiring. It must become a paint strategy (an `Appearance`) or, at worst, three widgets with
   three one-line overrides over one shared helper (§6 S1). Either way removal is possible; the
   investigation chooses the shape.
4. **Pointer state has five homes today, not one.** `HighlightableMixin` is one; four classes
   hand-roll the same hover/pressed machine beside it (§2.5). The job is ONE pointer-state
   mechanism for about ten classes, not "re-home a mixin with six consumers".
5. **`BubblesEditModeToCoordinatorMixin` is the one genuine cross-branch case, and it must not be
   "folded into its consumers".** It was created on 2026-07-27 precisely because its two cores sat
   byte-identical in three classes (`docs/archive/mixin-application-tidyups-plan.md`, Item A).
   Copying them back re-creates that triplication. It needs a single non-mixin home (§6 S3).

### 0.4 What is NOT decided — the owner's calls

| # | Decision | Recommendation here | Where |
|---|---|---|---|
| D1 | The shape of the one pointer-state mechanism | decide after S2 reports | §6 S2 |
| D2 | `ControllerMixin`: base class, or a per-widget wiring collaborator | base class as the removal step; the collaborator is a separate question | §5.4 |
| D3 | Names of the new classes (all names in this plan are WORKING names) | — | §5 |
| D4 | The inspector loses "from `<X>Mixin`", "Override in this class" and the Add… destination step, with nothing in their place | accept: they exist only because of mixins | §7 Phase 8 |
| D5 | Sequencing against the Smalltalk talk (2026-11-25, freeze 2026-11-21): `plans/smalltalk-talk-2026-11-plan.md` builds on mixin-aware meta features | no code phase of this plan lands before the talk unless the owner says so | §11 |

### 0.5 Cold-execution protocol

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status`. If a long op is `RUNNING`, another
   session owns `src/` and the tests: read and plan only, edit docs at most.
2. Read this plan whole, then `docs/architecture/mixins.md` §2 (how the mechanism works) and
   `docs/architecture/widget-authoring-guidelines.md`.
3. Re-run the scan in §2.4 and compare with §2.2/§2.3. If anything differs, the tree moved: fix the
   plan's facts FIRST, in place, before executing.
4. Phase 0 before any product edit. Each investigation ends by writing its verdict into §13 of
   this file; D1–D5 are put to the owner with the evidence, and their answers recorded there too.
5. Then one phase at a time, in the order of §7. Each phase: edit → `fg presuite` while iterating
   → `fg gauntlet` (and `fg homepage` where the phase says) at the close → present a summary and a
   commit message to the owner and WAIT. Never commit or push without that approval.
6. A phase that fails its gate twice with two different fix shapes stops: the model is wrong;
   re-frame and report rather than trying a third.
7. Standing rules that bite here: never `git stash` in this repo; never recapture a reference to
   make a failure go away — attribute the pixels first (§9); a base-class change is ONE commit for
   the whole family it touches.

---

## §1 The mechanism as it stands

The full present-tense reference is `docs/architecture/mixins.md` §2. The parts this plan deletes:

- **A mixin** is an object literal `<Name>Mixin = onceAddedClassProperties: (fromClass) ->
  @addInstanceProperties fromClass, { …members… }` in a `.coffee` file. A class opts in with
  `@augmentWith <Name>Mixin, @name` in its body.
- **Injection** (`src/boot/extensions/Object-extensions.coffee`): `Object::augmentWith` records the
  consumer on the literal (`consumerClassNames`) and fires the hook; `Object::addInstanceProperties`
  writes each member onto the consumer's prototype and, for a function, a companion
  `<member>_class_injected_in` naming the consumer. It throws on a mixin injected at two levels of
  one chain (the same function at two levels would recurse forever through that companion).
- **`super` is emulated** (`Mixin._rewriteSuperCalls`): each `super` in a mixin member is rewritten
  to `window[@[arguments.callee.name + '_class_injected_in']].__super__[arguments.callee.name]`.
  The only two uses of `arguments.callee` in `src/` are this rewrite and a debugging line in
  `HighlightableMixin.pressBegan`.
- **Override rule: the class body wins.** `Class` emits the `augmentWith(...)` calls before the
  class's own prototype assignments, so a same-named class-body member shadows the mixin's, and a
  `super` in that member goes to the consumer's PARENT class, skipping the mixin.
- **Reflective twin.** `Mixin` is a second meta-object beside `Class`: its own member-source store,
  its own live-edit verbs (`applyMemberEdit`, `removeMember`), donor resolution (`Mixin.donorOf`),
  boot-source comparison for snapshot loads, and a catch-up for a class a lazy part defines after a
  mixin edit (`Class._takeMixinMembersFromTheStores`). The inspectors carry a donor label, an
  "Override in this class" destination and a class-or-mixin step when adding a member;
  `SourceEditsRegistry` records and replays mixin-scope edits.
- **Two detectors** decide "is this file a mixin": `buildSystem/build.py` `IS_MIXIN`
  (`^(\w+Mixin)[ ]*=`) and the boot loader's `/^  onceAddedClassProperties:/m`
  (`src/boot/loading-and-compiling-coffeescript-sources.coffee`). `src/boot/dependencies-finding.coffee`
  `REQUIRES_MIXIN` gives the load-order edge.

---

## §2 Exact current state

### 2.1 Inventory

Eight mixins, 1,218 lines, 35 consumer slots over 28 classes. Six live in `src/mixins/` (part
`core`), two in `src/app-kit/` (the lazy `app-kit` part).

| Mixin | Lines | Members | Consumers | Members that call `super` |
|---|---|---|---|---|
| `ControllerMixin` | 582 | 31 | `SliderWdgt`, `StringWdgt`, `PaletteWdgt`, `ColorPickerWdgt`, `FanoutWdgt`, `FanoutPinWdgt`, `PatchNodeWdgt` | `graphEdgesOut` |
| `ClippingAtRectangularBoundsMixin` | 206 | 10 | `PanelWdgt`, `ViewportWdgt`, `FrameWdgt`, `InspectorWdgt`, `SimpleSpreadsheetWdgt`, `VerticalStackPanelWdgt`, `ClippingBoxWdgt` | `fullPaintIntoAreaOrBlitFromBackBuffer` |
| `BackBufferMixin` | 178 | 11 | `CanvasWdgt`, `StringWdgt`, `PaletteWdgt` | none |
| `HighlightableMixin` | 74 | 13 | `ButtonWdgt`, `CreatorButtonWdgt`, `GlassBoxTopWdgt`, `DesktopLinkWdgt`, `EditorContentPropertyChangerButtonWdgt`, `UpperRightTriangleIconicButtonWdgt` | `pressBegan` |
| `KeepsRatioWhenInVerticalStackMixin` | 69 | 6 | `IconWdgt` (72 direct subclasses), `GraphsPlotsChartsWdgt`, `PlotWithAxesWdgt` | none |
| `BubblesEditModeToCoordinatorMixin` | 51 | 2 | `StretchablePanelWdgt`, `StretchableWidgetContainerWdgt`, `VerticalStackViewportWdgt` | both |
| `WidgetCreatorAndSmartPlacerOnClickMixin` | 37 | 1 | `CreatorButtonWdgt` (16 subclasses), `GlassBoxTopWdgt` | none |
| `ParentStainerMixin` | 21 | 1 | `CreatorButtonWdgt`, `GlassBoxTopWdgt`, `EditorContentPropertyChangerButtonWdgt`, `CodeInjectingSimpleRectangularButtonWdgt` | none |

Classes that take more than one mixin — these are the real single-inheritance constraints:

- `StringWdgt`, `PaletteWdgt`: Controller + BackBuffer.
- `CanvasWdgt`: BackBuffer, on top of Clipping inherited from `PanelWdgt`.
- `CreatorButtonWdgt`, `GlassBoxTopWdgt`: Highlightable + ParentStainer + SmartPlacer — **the same
  three, and both extend `Widget` directly.**
- `EditorContentPropertyChangerButtonWdgt`: Highlightable + ParentStainer, on top of KeepsRatio
  inherited from `IconWdgt`.
- `CodeInjectingSimpleRectangularButtonWdgt`: ParentStainer, on top of Highlightable inherited from
  `ButtonWdgt`.

### 2.2 Where the consumers sit

- Directly under `Widget` (19): `PanelWdgt`, `ViewportWdgt`, `FrameWdgt`, `InspectorWdgt`,
  `SimpleSpreadsheetWdgt`, `VerticalStackPanelWdgt`, `StringWdgt`, `ColorPickerWdgt`, `PaletteWdgt`,
  `FanoutPinWdgt`, `FanoutWdgt`, `PatchNodeWdgt`, `CreatorButtonWdgt`, `GlassBoxTopWdgt`,
  `ButtonWdgt`, `GraphsPlotsChartsWdgt`, `PlotWithAxesWdgt`, `IconWdgt`,
  `StretchableWidgetContainerWdgt`.
- One level below (8): `ClippingBoxWdgt < BoxWdgt`, `SliderWdgt < CircleBoxWdgt`,
  `CanvasWdgt < PanelWdgt`, `EditorContentPropertyChangerButtonWdgt < IconWdgt`,
  `UpperRightTriangleIconicButtonWdgt < UpperRightTriangleWdgt`,
  `DesktopLinkWdgt < WidgetHolderWithCaptionWdgt`, `StretchablePanelWdgt < PanelWdgt`,
  `VerticalStackViewportWdgt < ViewportWdgt`.
- Two levels below (1): `CodeInjectingSimpleRectangularButtonWdgt < SimpleRectangularButtonWdgt <
  ButtonWdgt`.

The two thin intermediate parents, in full: `BoxWdgt` is a constructor `(@cornerRadius = 4)` that
sets `@appearance = new BoxyAppearance @`; `CircleBoxWdgt` is a constructor that sets
`new CircleBoxyAppearance(@)` and commits extent 20×100, plus `colloquialName` and `autoOrientation`
(its other subclass is `SliderButtonWdgt`).

### 2.3 Where consumers already fight the mechanism

A class-body member that shadows a mixin member, with whether it calls `super`:

| Site | What it does | Why it is a workaround |
|---|---|---|
| `ViewportWdgt._fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow` and `…JustShadow` (`ViewportWdgt.coffee` ~:340, ~:365) | adds the scroll translation; on the zero-offset path calls `PanelWdgt::<same method>.call @, …` | it cannot `super` into the mixin's copy, so it borrows `PanelWdgt`'s injected copy |
| `FrameWdgt`, the same two methods (`FrameWdgt.coffee` ~:2148, ~:2163) | adds the rounded child clip; the clip-off path calls `PanelWdgt::….call @` | same |
| `PaletteWdgt.paintIntoAreaOrBlitFromBackBuffer` (~:52) | re-declares `Widget`'s body (`@appearance?.paintIntoAreaOrBlitFromBackBuffer …`) | to UNDO the mixin's member, so `PaletteAppearance` can blit and then draw its mark |
| `DesktopLinkWdgt.pressBegan` (`super` = YES) | retypes the mixin's two lines (`@state = @STATE_PRESSED`, `@_updateColor()`) under a condition, then `super` | its `super` skips the mixin and reaches `Widget.pressBegan` — today that is what it wants |
| `DesktopLinkWdgt._updateColor`, `UpperRightTriangleIconicButtonWdgt._updateColor` | replace the look | plain overrides, no `super` |
| `StringWdgt.catchesPointerAt` | bounds / rounded-item test | replaces the mixin's per-pixel test, which is wrong for text |

Subclasses below a consumer that override a mixin member (their `super` reaches the consumer's
prototype, i.e. the injected member, today and after conversion alike):
`TransformFrameWdgt` (three Clipping members, two with `super`), `WorldWdgt.fullPaintIntoAreaOrBlitFromBackBuffer`
(`super`), `CanvasGlassTopWdgt`/`VideoPlayerCanvasWdgt`/`SimpleImageWdgt` `.catchesPointerAt` (no
`super`), `LabelButtonWdgt` and `MenuItemWdgt` (all five pointer hooks; `MenuItemWdgt`'s three press
hooks `super` into `LabelButtonWdgt`'s), `SimpleButtonWdgt`/`IconButtonWdgt`/`OverflowChevronButtonWdgt`
`._updateColor`, `ToolbarCreatorButtonWdgt.activated`.

**What each mixin `super` resolves to today** (the consumer's parent chain): every one reaches
`Widget`'s member, with ONE exception — the two Bubbles cores injected into
`VerticalStackViewportWdgt` reach `ViewportWdgt._enableDragsDropsAndEditingNoSettle` /
`_disable…`. No thin intermediate parent (`BoxWdgt`, `CircleBoxWdgt`, `IconWdgt`,
`UpperRightTriangleWdgt`, `WidgetHolderWithCaptionWdgt`, `PanelWdgt`) defines a member a mixin
`super`s into.

### 2.4 The scan that produced §2.1–§2.3 (re-run it; do not trust the tables)

For each `.coffee` under `src/`: a mixin is a file matching `^\w+Mixin\s*=`; its members are the
6-space keys (`^      (name) *:`); consumers are `^  @augmentWith (\w+)` lines; a class body defines
a member at 2-space indentation (`^  name *:`); "calls super" means `\bsuper\b` on a non-comment
line of that member's body; parents come from `^class X extends Y`. Print, per mixin: members,
consumers, each consumer's shadowing members, each descendant's overriding members, and for each
`super`-calling mixin member the first ancestor of each consumer whose class body defines it.
Quick cross-checks:

```
cd Fizzygum
grep -rn "^  @augmentWith" src --include='*.coffee' | wc -l            # 35 consumer slots
grep -rnE "[A-Z][A-Za-z]+Wdgt::[A-Za-z_]+\.(call|apply)" src --include='*.coffee'   # the 4 borrow sites
grep -rnE "arguments\.callee" src --include='*.coffee'                  # 2 lines, both mixin machinery
```

### 2.5 Pointer state: five implementations

The hand (`src/ActivePointerWdgt.coffee`) tells widgets five things, all through `?()` except the
press: `hoverEntered`, `hoverExited`, `pressBegan` (climbs while each receiver passes it on — the
press's AUDIENCE, held in `_pressAudience`), `pressEnded`, `pressCancelled`. It also answers
`pointerCanRest()` (false for a finger) and `restsOn(aWdgt)` (`pointerCanRest() and
@mouseOverList.has aWdgt`). Who turns those into a look:

1. `HighlightableMixin` — `state` ∈ `STATE_NORMAL/HIGHLIGHTED/PRESSED`; every transition calls
   `_updateColor`; `hoverEntered`/`hoverExited` also start and cancel the tooltip countdown;
   `pressBegan` ends in `super`.
2. `LabelButtonWdgt` — inherits the mixin from `ButtonWdgt` and shadows all five hooks with the same
   transitions, calling `@_changed()` where the mixin calls `_updateColor`; `activated` forces
   `HIGHLIGHTED`. `MenuItemWdgt` overrides again on top.
3. `SliderButtonWdgt` — its own copy of the three `STATE_*` constants and `state`; ignores a hover
   while pressed or dragging; keeps its look when the pointer leaves mid-drag.
4. `HandleWdgt` — `_setPointerState(isHovered, isPressed)`, two booleans; also cleared by
   `endOfNonFloatDrag`.
5. `LayoutChromeWdgt` — the same two-boolean `_setPointerState`, pressed only where
   `_showsPressOnMyPlate()`.

One class reads ANOTHER widget's stored state: `GlassBoxBottomWdgt.fillForToolState(stateHolder, …)`
reads `stateHolder.state` against `stateHolder.STATE_PRESSED` / `STATE_HIGHLIGHTED`, driven by
`ParentStainerMixin._updateColor` → `@parent?.noteItemStateChanged?()`.

### 2.6 What the mechanism costs today

- `src/meta/Mixin.coffee`: 299 lines. Mixin-only members elsewhere, by name:
  `Class.findMixinsInTheClass`, `removeAugmentations`, `_takeMixinMembersFromTheStores`,
  `_bootDonorOf`, `augmentedWith`, `augmentRegex`, the donor fallback in `Class.removeMember`;
  `ClassInspectorWdgt._editMixinMember`, `_removeMixinMember`, `addPropertyToMixin`,
  `overrideInThisClass`; `InspectorWdgt.mixinDonorLabel`, `currentPropertySourceMixinName`,
  `_currentPropertySourceMixin`, the `_class_injected_in` half of `_isACompanion`;
  `SourceEditsRegistry.recordMixinEdit`, `recordMixinMemberRemoval`, `replayMixinEdits`, the mixin
  half of `returnThePageToBootSources`.
- 45 files under `buildSystem/` and 16 under the tests repo's `scripts/` (its `.scratch/` aside)
  match the pattern in §7 Phase 8; none in the harness source. Not yet classified into comment /
  DSL parsing / name-keyed rule.
- It is not stable machinery: `Mixin.coffee` and `Object-extensions.coffee` were touched by 23
  commits between June and November 2026 (1 in June, 9 in July, 4 in August, 9 in November) —
  `git log --since=2025-11-01 --format=%ad --date=format:%Y-%m -- src/meta/Mixin.coffee
  src/boot/extensions/Object-extensions.coffee | sort | uniq -c`.
- It gives the person at the screen no composition power in return: the inspector reads a class's
  `augmentedWith` list but cannot add or remove an augmentation.

---

## §3 Why it is shaped this way

- Morphic.js, the ancestor, has no mixins; these were added one by one as needs arose —
  `ControllerMixin` 2014, `BackBufferMixin` 2015, `HighlightableMixin` 2017, Clipping / KeepsRatio /
  ParentStainer / SmartPlacer in early 2018 (`git log --follow --diff-filter=A` on each file). The
  oldest two predate `Appearance` (first committed 2017-05); all but Bubbles predate the spec
  objects that now carry most composition (`PinSpec`/`WireSpec` are from 2026-08).
- The count has been falling since it was first examined. Early July 2026 there were 14: dead
  `ContainerMixin` was deleted (`3267b0dd`), five misfiled ones were folded into ordinary homes
  (`194e252d`), `DeepCopierMixin` became the `Duplicator` engine (`a70efe23`). In the same program
  the owner asked for the INVERSE audit — what in the tree would be better AS a mixin — and a
  whole-tree duplication scan found one case, the 51-line Bubbles mixin (`34eeeab3`,
  `docs/archive/mixin-application-tidyups-plan.md`).
- Live mixin EDITING was then built out (`docs/archive/mixin-editing-v2-plan.md`): the reflective
  twin of §1. Every reflective feature since has needed a mixin half.
- The keep position (`mixins.md` §5, §7, 2026-08-16) priced removal at "≈100+ forwarding stubs or
  hierarchy surgery" and "new `Widget` extension points on the paint/input/geometry hot paths". It
  considered a base class only for single-subtree mixins and assumed the rest sat on unrelated
  branches.

---

## §4 The distilled argument

**Why remove.**

1. *The problem mixins solve is one this architecture mostly avoids.* Mixins share behaviour across
   the branches of a deep class tree. Fizzygum's tree is flat and it composes through objects —
   appearances (140 `*Appearance` files), layout specs, pin and wire specs, `world.*` services,
   capability queries. A mixin is a second composition mechanism beside that one; the owner's
   principle is ONE of each thing.
2. *Each of the eight, examined, is something else in disguise.* Clipping and KeepsRatio are
   classes; BackBuffer is a paint strategy (its own header says back-buffering "should be
   transparent and automatic"); SmartPlacer and ParentStainer belong to one two-class family;
   Highlightable is one of five copies of a protocol whose facts the hand owns; Controller is a
   protocol with its own state. Only Bubbles is a true cross-branch case, and it is 51 lines.
3. *The mechanism is the weak kind* (§0.3 point 2, §2.3): consumers already work around it.
4. *It doubles the reflective layer, which is the product's signature.* "Where does this member
   live, and what does my edit touch?" has three answers (instance, class, donor) instead of two,
   and each new reflective feature is built twice (§2.6).

**Why now.** The owner asked; the mechanism is being actively maintained (§2.6), so the cost is
current, not sunk; and planned work gets simpler without it (`plans/single-file-save-plan.md`
ships `Mixin-source.js` and replays mixin edits; November's snapshot-replay, lazy-part and
inspector-churn work each needed a mixin half — the commit subjects in
`git log --since=2026-11-01 -i --grep=mixin`).

**What is different from the 2026-08 analysis.** It priced only two shapes — forwarding stubs and
`Widget` extension points — for the four large mixins. This plan uses a third for three of them (a
base class in the unused inheritance slot) and re-homes the fourth on the paint strategy that
already exists. The stub count goes from "≈100+" to at most nine (§6 S1's fallback).

**The honest case for keeping, and the answer.**

- *It works and is gated; removal is behaviour-neutral churn through paint and input code.* True.
  It is a one-off cost, mostly moves of unchanged method bodies under the gauntlet, against a cost
  that recurs.
- *A future widget may need two orthogonal hook-overriding behaviours.* Today's overlaps (§2.1) all
  resolve by putting each axis on a different mechanism; a future one gets a strategy slot, the
  house answer.
- *`ControllerMixin` is a capability, not an identity.* Fair — see D2 and R1.

---

## §5 Fix shape — the target home of each mixin

**The lookup rule for a base-class conversion** (state it in each phase's commit message). Today a
mixin member sits on the CONSUMER's own prototype. Afterwards it sits on base `B`, with the
consumer extending `B`. For a consumer that extended `Widget` directly: every lookup resolves to
the same body it does today, the consumer's own same-named members still win, and exactly two
things change — (a) `super` inside a consumer member that shadows a moved member now reaches `B`'s
member where it used to reach `Widget`'s; (b) the member is inherited, no longer the prototype's
own, which changes inspector member lists and class chips. For a consumer that had another parent
(§2.2's eight), that parent's contribution must be restated on the consumer, and nothing else.

### 5.1 `ClippingAtRectangularBoundsMixin` → base class `ClippingWdgt extends Widget` (core)

The ten members move verbatim; `fullPaintIntoAreaOrBlitFromBackBuffer`'s `super` becomes a real
one. `PanelWdgt`, `ViewportWdgt`, `FrameWdgt`, `InspectorWdgt`, `SimpleSpreadsheetWdgt`,
`VerticalStackPanelWdgt` change `extends Widget` to `extends ClippingWdgt`. `ClippingBoxWdgt`
(demos) extends `ClippingWdgt` and takes `BoxWdgt`'s one-line constructor body itself. The four
`PanelWdgt::….call @` borrows (§2.3) become `super`. Of §2.3's shadowing members here none calls
`super`, so change (a) does not arise. `docs/architecture/viewports-and-planes.md` states why
`PanelWdgt` is purely the SURFACE class; a clipping base above it is consistent with that.

### 5.2 `KeepsRatioWhenInVerticalStackMixin` → base class (core; working name `AspectLockedWdgt`)

Six members, no `super`, no shadowing; all three consumers extend `Widget` directly. The base
lives in core because `IconWdgt` is core and a base class may cross a part boundary only under
`requires` (the plots are in a lazy part; core is always present). ⛔ Do not convert the two
pinned-`@ratio` variants (`Example3DPlotWdgt`, `StretchableWidgetContainerWdgt`) or the square/grid
measures (`AnalogClockWdgt`, `GenericCompositeIconWdgt`, `WidgetHolderWithCaptionWdgt`,
`TrackingTransformFrameWdgt`): that conversion was falsified (§10).

### 5.3 `BackBufferMixin` → a paint strategy — shape chosen by S1

`Widget` already delegates the three things the mixin overrides: `catchesPointerAt` →
`@appearance.shapeContainsPoint` (~:547), `paintIntoAreaOrBlitFromBackBuffer` →
`@appearance?.paintIntoAreaOrBlitFromBackBuffer` (~:595), `opaqueCoveredRect` →
`@appearance?.opaqueCoveredRect()` (~:3079). Base `Appearance` answers `shapeContainsPoint` (bounds)
and `opaqueCoveredRect` (`undefined`). See §6 S1 for the candidate shapes and the fallback.

### 5.4 `ControllerMixin` → base class `ControllerWdgt extends Widget` (core) — D2

Six consumers extend `Widget` directly; `SliderWdgt` takes `CircleBoxWdgt`'s constructor body and
two methods itself (`SliderButtonWdgt` keeps `CircleBoxWdgt`). `graphEdgesOut`'s `super()` becomes
real. Zero call-site changes, zero snapshot-format change (`@wires` stays a widget own-property).
While `BackBufferMixin` is still a mixin, `StringWdgt` and `PaletteWdgt` can extend `ControllerWdgt`
and keep augmenting it, so this does not wait on S1.

The alternative — a per-widget wiring collaborator (`@wiring`) owning the `WireSpec` list — moves
about 19 lines in 10 `src/` files and 42 lines in 23 tests-repo files (pattern in §9.4), changes
the snapshot format, and re-targets every wiring menu row. Its benefit is unrelated to mixins: it
is the right design if ANY widget should be able to drive another (the target half of the wire
protocol — `pins()`, `principalPin()` — is already on `Widget`). Recommendation: take the base
class here; raise the collaborator as its own arc if wanted. Moving a base class to a collaborator
later is no harder than moving a mixin to one now.

### 5.5 `WidgetCreatorAndSmartPlacerOnClickMixin` + two of `ParentStainerMixin`'s four → a shared base in `app-kit` (working name `WidgetCreatingToolWdgt`)

`CreatorButtonWdgt` and `GlassBoxTopWdgt` both extend `Widget` directly and carry the same three
mixins. A shared base in `src/app-kit/` takes SmartPlacer's `activated` and the pair's pointer-state
and parent-stain behaviour. This is `mixins.md`'s own rule for a single-subtree mixin. (The first
analysis proposed a world service for SmartPlacer; the shared base is smaller and keeps app-kit code
in the lazy part.) `ToolbarCreatorButtonWdgt.activated` keeps overriding without `super`.

### 5.6 `HighlightableMixin` + the rest of `ParentStainerMixin` → ONE pointer-state mechanism — D1, shape chosen by S2

Target: the transition rules exist once; each of the roughly ten classes in §2.5 states only its
look and its exceptions. `ParentStainerMixin` is that mechanism's look hook answered with
`@parent?.noteItemStateChanged?()`; its two remaining consumers
(`EditorContentPropertyChangerButtonWdgt`, `CodeInjectingSimpleRectangularButtonWdgt`) state that
one line themselves.

### 5.7 `BubblesEditModeToCoordinatorMixin` → a single non-mixin home — shape chosen by S3

Not a copy per consumer (§0.3 point 5).

---

## §6 Phase 0 — investigations

Each runs on a throwaway WIP branch or `git worktree` (never `git stash`), lands nothing, and ends
with a verdict written into §13.

### S1 — back buffer as a paint strategy (the crux; run first)

**Question.** Can the three back-buffered widgets paint, hit-test and report coverage through
`@appearance`, with the blit body existing once and no member injected or re-declared?

**Facts to design against.**
- The mixin holds four fields (`backBuffer`, `backBufferContext`, `_backBufferShadowSilhouette`,
  `_backBufferShadowSilhouetteSource` — all in `Widget.@serializationTransients`), the blit
  (`blitBackBufferInto`, with `calculateKeyValues` and `_shadowSilhouetteOfBackBuffer`), the pixel
  read (`getPixelColor`), and three overrides (`paintIntoAreaOrBlitFromBackBuffer`,
  `catchesPointerAt` per pixel, `opaqueCoveredRect` → `undefined`).
- Each consumer family supplies `_createRefreshOrGetBackBuffer` (seven definers: `CanvasWdgt`,
  `StretchableCanvasWdgt`, `SimpleImageWdgt`, `VideoPlayerCanvasWdgt`, `StringWdgt`, `TextWdgt`,
  `PaletteWdgt`) and reads `@backBuffer`/`@backBufferContext` freely in its own code. Text and
  palette buffers are shared, immutable and cached by content; a canvas's raster is mutated in
  place and can be saved content (`CanvasWdgt.drawnRaster`).
- Outside the three families, `PenWdgt`, `ToolTipWdgt` and `PaletteAppearance` read the buffer or
  call `getPixelColor` / `blitBackBufferInto`.
- `StringWdgt` has NO appearance today, so every `@appearance?` read in `Widget` answers "none" for
  text: `outlineIsStroked`, `paintStroke`, `addShapeSpecificMenuItems`, `_fillColor`,
  `opaqueCoveredRect`, `clipToOutline`, `outlineCornerRadii`, `pins`
  (`grep -nE "@appearance\??\." src/basic-widgets/Widget.coffee`). Giving text an appearance changes
  each of those unless the new appearance answers exactly as "none" does.
- `CanvasWdgt` keeps `PanelWdgt`'s `RectangularAppearance` for its border: the clipping
  `fullPaint…` tail calls `@paintStroke`, which is the appearance's. So a canvas needs the
  rectangular answers AND the blit.
- `buildSystem/check-back-buffer-memos.js` is a gate about these fields and reads `@augmentWith`.

**Candidate shapes.**
- *A — the appearance owns the route.* `BackBufferAppearance extends Appearance`: paint = the blit,
  `shapeContainsPoint` = the per-pixel test, coverage = inherited `undefined`. `PaletteAppearance`
  extends it and calls `super` before its mark (`PaletteWdgt`'s re-declared paint goes). Text takes
  it bare. Open sub-question: the canvas needs it on top of `RectangularAppearance` — which is the
  same "one behaviour, two branches" problem one level down, in the appearance tree. It is solved
  if the blit body lives on something both appearance classes can call in one line.
- *B — the fallback, always available.* A plain helper holding the blit, the silhouette twin and
  the pixel read as functions of a widget; each of the three consumers declares its fields and
  three one-line overrides. At most nine stubs (`StringWdgt` already overrides `catchesPointerAt`,
  and with no appearance its coverage already answers `undefined`).

**Accept when** the full gauntlet passes with ZERO reference recaptures at dpr 1, dpr 2 and WebKit
(this is a pure re-routing) — including its `vmtruth` and `serialization` legs, which hold object
lifetime and the transients — `check-back-buffer-memos.js` is re-pointed and its bite-proof still
bites, and — for shape A — each `@appearance?` read above is listed with text's answer before and
after, all equal.

**If A fails twice,** take B. Do not start a third shape.

### S2 — one pointer-state mechanism

**Question.** Can one implementation of the transition rules serve all of §2.5, and where does it
live?

**Candidates.**
- *Derived from the hand.* No stored per-widget state: the hand already holds both facts
  (`restsOn`, `_pressAudience`). It calls ONE optional hook at each transition; a widget's look
  asks the hand what its state is. Costs nothing on `Widget`, and matches "derived, never stored".
  Must be tested against: `SliderButtonWdgt` and `HandleWdgt` keeping the pressed look while the
  pointer leaves mid-drag; `LabelButtonWdgt.activated` forcing the hover look; `DesktopLinkWdgt`'s
  press on its plate NOT pressing the tile; `LayoutChromeWdgt._showsPressOnMyPlate`; a finger never
  hovering; the tooltip countdown that today rides `hoverEntered`/`hoverExited`; and
  `GlassBoxBottomWdgt` reading a child's state.
- *Stored once, opt-in on `Widget`.* `Widget` answers the five hooks for widgets that opt in and
  calls one look hook (the first analysis estimated about 35 lines; it replaces five copies).
  Against the shrink-`Widget` and no-base-default-for-a-capability rules, so it needs the owner's
  approval (D1).
- *Base class plus re-parenting.* Works for `ButtonWdgt` and the app-kit pair; leaves
  `DesktopLinkWdgt`, the two icon buttons and the four hand-rolled copies where they are. Listed
  for completeness; it does not reach the target.

**Determinism.** The look must stay a function of the event stream: read
`../../Fizzygum-tests/DETERMINISM.md` (§3n is the finger/hover case `pointerCanRest` cites) before
designing, and prove any candidate with `fg fuzz` as well as the dpr 2 leg.

**Accept when** the transition rules exist once, every class in §2.5 keeps only its look and its
stated exception, and the gauntlet passes with zero recaptures.

**One `super` flips meaning under any base-class shape:** `DesktopLinkWdgt.pressBegan` (§2.3). Its
`super` would start reaching the new base's `pressBegan`, pressing the tile on a caption press —
the very thing the method exists to avoid. Restructure it in the same commit.

### S3 — the single home for the edit-mode relay

**Facts.** The two cores take `(triggeringWidget)`, show the edit/view mode in the parent's bar,
and — when the parent answers `coordinatesDragsDropsAndEditingForChildren?()` and is not the
trigger — relay the toggle to it; otherwise `super()`. One class answers that query:
`StretchableWidgetContainerWdgt` (~:268). `Widget`, `FrameWdgt` and `ViewportWdgt` define cores
that take no parameter; `FrameWdgt` and `ViewportWdgt` call their `@contents`' cores passing `@`.
The three consumers sit under three different parents (`Widget`, `PanelWdgt`, `ViewportWdgt`), and
in `VerticalStackViewportWdgt` the `super()` reaches `ViewportWdgt`'s cores.

**Candidates.** (a) `Widget`'s own two cores do the relay, scoped by the parent query the mixin
already asks — then ANY child of a coordinator relays; establish which classes can be such a child
and whether that changes behaviour. (b) The coordinator owns the relay and its children's toggle
entry points call it. (c) Anything else that leaves ONE copy. A copy per consumer is not a
candidate.

**Accept when** one copy exists, no consumer names a mixin, and the gauntlet passes with zero
recaptures (the 2026-07-27 arc that created the mixin was pixel-neutral; so is its inverse).

---

## §7 Phases

Order: the three base-class moves first (independent of every investigation), then the phases that
wait on S1–S3, then the teardown. Each phase closes on `fg gauntlet`; the ones marked ⌂ also run
`fg homepage` (they touch a lazy part or the meta layer).

| Phase | What | Waits on | Expected references |
|---|---|---|---|
| 1 | Clipping → `ClippingWdgt` (§5.1) | — | pixel-identical; inspector member-list and class-chip shots move |
| 2 | KeepsRatio → base class (§5.2) | — | same |
| 3 | Controller → `ControllerWdgt` (§5.4) | D2 | same |
| 4 ⌂ | The app-kit pair's shared base; SmartPlacer mixin deleted (§5.5) | — | same |
| 5 | BackBuffer per S1 (§5.3) | S1 | pixel-identical |
| 6 ⌂ | Pointer state per S2; Highlightable and ParentStainer deleted (§5.6) | S2, D1, Phase 4 | pixel-identical |
| 7 ⌂ | Edit-mode relay per S3; Bubbles deleted (§5.7) | S3 | pixel-identical |
| 8 ⌂ | Mechanism teardown | Phases 1–7, D4 | inspector shots; two tests retired |
| 9 | Docs and close | Phase 8 | — |

**Per-phase recipe for a base-class move (Phases 1–4).**
1. Create the class file (one class per file, filename = class name) in a directory its part owns;
   move the members verbatim; turn the emulated `super`s into real ones.
2. Re-parent each consumer; restate what a dropped intermediate parent contributed (§2.2).
3. Replace §2.3's workarounds that the move dissolves; delete the mixin file; remove its
   `@augmentWith` lines.
4. Update comments that name the mixin (`grep -rn "<Name>Mixin" src ../Fizzygum-tests`), including
   test descriptor metadata.
5. Gate (§9). For Phase 1 also fix the LOCKSTEP comment on the two paint bodies and
   `docs/BACKLOG.md`'s owner-gated "lift scroll … to the clipping-mixin level" wording.

**Phase 8 — teardown.** With zero `@augmentWith` lines left
(`grep -rn "augmentWith" src --include='*.coffee'` shows only the machinery):
- Delete `src/meta/Mixin.coffee`; `Object::augmentWith` / `addInstanceProperties` and
  `MixedClassKeywords` (`src/boot/`); the `REQUIRES_MIXIN` edge; the boot loader's mixin branch and
  `build.py`'s `IS_MIXIN` branch (including "Class and Mixin are the two sources loaded
  individually and EARLY"); `"src/mixins"` in `buildSystem/parts.json`.
- Delete the mixin-only members listed in §2.6, and the mixin branches inside shared methods of
  `Class`, both inspectors and `SourceEditsRegistry` (a snapshot's mixin-scope records stop
  existing; there is no compatibility obligation for old files).
- Build tools and rigs: classify every hit of
  `grep -rlE "[Mm]ixin|augmentWith|augmentedWith|_class_injected_in|onceAddedClassProperties|addInstanceProperties" buildSystem ../Fizzygum-tests/scripts ../Fizzygum-tests/Automator-and-test-harness-src`
  as comment, DSL parsing, or a rule keyed on a mixin name; remove the parsing, re-point or retire
  the rules (`SHADOWS-MIXIN` in `census-hierarchy-duplication.js`, `MIXIN_MEMBER_UNRECORDED` in
  `lib/gate-tokens.js`, `LAZY_CONSUMER_TAKES_MIXIN_EDITS` in `parts-lazy-load-headless.js` and its
  self-test), keeping every surviving gate's bite-proof biting.
- Tests: retire `SystemTest_macroMixinEditDonorAndOverride` and
  `SystemTest_macroMixinFieldEditDonorAndOverride` (they test the mechanism);
  `SystemTest_macroClassInspectorSaveRefusesCodeThatDoesNotCompile` and
  `SystemTest_macroInspectorOffersOnlyWhatItsSubjectOwns` assert on a member donated by
  `HighlightableMixin` and need a new subject. 39 test directories name a `*Mixin` in all — the
  rest in descriptor metadata or comments (`grep -rlE "[A-Za-z]+Mixin\b" ../Fizzygum-tests/tests`).
- The compiled output no longer needs `arguments.callee`; whether to move to strict mode is out of
  scope — record it in `docs/BACKLOG.md`.

**Phase 9 — docs and close.** `git mv docs/architecture/mixins.md` to `docs/archive/` with a
SUPERSEDED stamp and an `archive/INDEX.md` line; rewrite the two "Mixins" bullets in
`Fizzygum/CLAUDE.md` and the mentions in the umbrella `CLAUDE.md`; sweep the living docs
(`grep -rliE "mixin" docs/architecture docs/specs docs/plans docs/tooling docs/explainers
src/*/CLAUDE.md ../Fizzygum-tests/CLAUDE.md ../Fizzygum-tests/DETERMINISM.md`), present tense, no
changelog prose; add the base-class lookup rule and the new classes to
`widget-authoring-guidelines.md`; close this plan per `docs/README.md` rule 2.

---

## §8 Central risks

- **R1 — the complication moves instead of leaving.** The arc fails its purpose if it ends with new
  machinery on `Widget`, a forest of stubs, or a second mechanism under another name. Test for
  every phase: the mixin's replacement is something every existing tool, gate and inspector already
  understands without a line of new support.
- **R2 — a capability dressed as an identity.** `ControllerWdgt` says "is a controller" of a text.
  Accepted as the removal step (D2); not accepted as the reason to pile a second capability onto
  the same slot later.
- **R3 — paint-path determinism.** Phases 1 and 5 move the clipping and blit bodies. They are
  moves, not edits: diff each moved body against its source and require zero recaptures outside
  inspector member lists.
- **R4 — `super` flips.** One known (`DesktopLinkWdgt.pressBegan`); re-run §2.4 at every phase,
  because a member added meanwhile can create another.
- **R5 — inspector references.** Members stop being a prototype's own and new classes appear in
  class chips, so member-list shots move. Recapture only those, only after attributing the diff
  (§9.3).
- **R6 — lazy parts and the pre-compiled image.** The app-kit classes load after boot in
  production. A base class crosses a part boundary only under `requires`; keep each new base in
  core or in the part that owns all its subclasses, and run `fg homepage`.
- **R7 — the two detectors and the syntax gate** read the mixin DSL through the real `Mixin` class
  (`buildSystem/lib/meta-compiler.js`). Phase 8 removes them together; removing one half first
  breaks the build.

---

## §9 Verification protocol

1. **Inner loop:** `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (build + dpr 1 suite ∥
   paint audit ∥ the fractional-plane dpr 2 rider, ~3–4 min). Invoke `fg` by absolute path; never
   pipe a gating call through `tail`/`grep`.
2. **Phase close:** `fg gauntlet`, launched once in the background with output to a log; wait for
   the exit notification, read `/tmp/fg-gauntlet.verdict`. ⌂ phases add `fg homepage`.
3. **References.** Expected outcome of every phase is pixel-identical outside inspector member
   lists and class chips. A diff elsewhere is a finding: attribute the pixels before anything else
   (`fg diffpage`), and never recapture to make it pass. Member-list churn is recaptured with
   `fg recapture-inspector`, after a fresh build.
4. **Counts to re-derive, not copy.** Wiring call sites, should D2 choose the collaborator:
   `grep -rnE "\.(wireTo|unwireFrom|bindTo|declareWireTo|trackTarget|isWiredTo|isWiredToActionOf|openTargetSelector|setTargetAndActionWithOnesPickedFromMenu|disconnectWire|toggleFiresPerEventOfWire|toggleTrackingOfWire|openWireMenu|openConnectionGestureMenu|openBindSelector|canBind)\b"`
   over `src` (excluding the mixin file) and over the tests repo's `tests`, `scripts` and
   `Automator-and-test-harness-src`.
5. **End of arc:** the §2.4 cross-checks all print nothing but machinery-free results —
   zero `@augmentWith`, zero `…Wdgt::….call` borrows, zero `arguments.callee`, no file matching
   `^\w+Mixin\s*=`.

---

## §10 Rejected alternatives — do not re-attempt

- **Keep the mechanism with a narrow remit** (`mixins.md` §1). Its two premises are falsified by
  §2.2 and §5; its "stable machinery" by §2.6.
- **Forwarding stubs everywhere** (`mixins.md` §5-A): about 100 hand-written forwards. Unneeded
  once a base class or the appearance takes the member.
- **`BackBufferMixin` as a base class.** Impossible: §2.1's overlaps.
- **Folding the Bubbles cores into the three consumers.** Re-creates the triplication the mixin was
  created to remove (`docs/archive/mixin-application-tidyups-plan.md`, Item A).
- **Converting the pinned-`@ratio` variants onto the ratio protocol's shared home.** Falsified in
  that same plan (Item C, its §3).
- **A world service for SmartPlacer.** Works, but puts app-kit-only code in core; the shared base
  (§5.5) is smaller.
- **Making mixins "real"** — subclass factories (`class X extends Clipping(Widget)`) that put each
  application in the prototype chain. It would fix the `super` weakness and add an anonymous class
  per application, against one-class-per-file, the `Class` meta-object and by-name serialization:
  more machinery, not less.
- **A `@target`/`@action`-style compatibility shim of any kind** during the conversion: every site
  converts in the phase that moves its mixin.

---

## §11 Interactions with other plans and open items

- `plans/smalltalk-talk-2026-11-plan.md` (talk 2026-11-25, freeze 2026-11-21) describes
  `Mixin.coffee`, mixin edit records and a "from mixins" protocol group as demo material — D5.
- `plans/single-file-save-plan.md` ships `Mixin-source.js` and lists a mixin-then-class edit
  replay; both shrink after Phase 8. Whichever arc runs second re-verifies against the other.
- `plans/creation-and-templates-plan.md` §4.3 plans to fold the creator zoo (`CreatorButtonWdgt`
  among it); Phase 4's shared base should not fight that — read it first.
- `docs/BACKLOG.md`, open items that change: "A snapshot's source edits of a lazy part's classes
  are dropped…" loses its mixin half; the owner-gated paint-time-scroll Phase 4 ("lift … to the
  clipping-mixin level") reads "to the clipping base class" after Phase 1 and becomes simpler; the
  `fg recapture-inspector` item names the two tests Phase 8 retires.

---

## §12 References

- `docs/architecture/mixins.md` — the mechanism (§2) and the superseded keep position (§1, §5, §7).
- `docs/archive/mixin-application-tidyups-plan.md`, `docs/archive/mixin-editing-v2-plan.md`,
  `docs/archive/god-class-decomposition-plan.md` — the prior mixin arcs and the delegation
  precedent.
- `docs/architecture/widget-authoring-guidelines.md`, `appearance-paint-convention.md`,
  `viewports-and-planes.md`, `input-and-gestures.md`, `lint-and-static-checks.md`,
  `serialization-duplication-reference.md`, `build-and-packaging.md`.
- `../../Fizzygum-tests/DETERMINISM.md` — before touching pointer state or the paint path.
- `src/dataflow/CLAUDE.md` — before touching wiring.

---

## §13 Ledger — verdicts and decisions (filled in as the plan runs)

| Item | Verdict / decision | Date | Evidence |
|---|---|---|---|
| S1 back buffer as a paint strategy | — | | |
| S2 one pointer-state mechanism | — | | |
| S3 the edit-mode relay's single home | — | | |
| D1 pointer-state shape | — | | |
| D2 Controller: base class or collaborator | — | | |
| D3 class names | — | | |
| D4 inspector loses the donor vocabulary | — | | |
| D5 sequencing against the talk | — | | |

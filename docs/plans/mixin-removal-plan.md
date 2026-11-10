# Mixin removal — every mixin to an ordinary home, then delete the mechanism

**STATUS: PLAN ONLY — AUTHORED 2026-11-10. No code written.** Written to be executed COLD by an
LLM/engineer with ZERO prior context: everything needed is embedded here or one named-doc hop away.
**Where it stands (§13):** D2 and D5 are decided. The three investigations have been done BY
READING — each has a paper verdict, and an empirical half (a build and a gauntlet) still owed. D1,
D3 and D4 are open. Phases 1–4 wait on nothing.

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
   with wiring. Its three overrides dissolve onto the appearances a palette and a canvas already
   have, plus one line on `StringWdgt`; what needs a home is its KIT — the blit, the pixel read
   and the shadow twin (§6 S1).
4. **Pointer state has five homes today, not one.** `HighlightableMixin` is one; four classes
   hand-roll the same hover/pressed machine beside it (§2.5). The job is ONE pointer-state
   mechanism for about ten classes, not "re-home a mixin with six consumers".
5. **`BubblesEditModeToCoordinatorMixin` sits on three branches, and its relay is live on ONE.** It
   was created on 2026-07-27 because its two cores sat byte-identical in three classes
   (`docs/archive/mixin-application-tidyups-plan.md`, Item A), so copying them back is not an
   option. Reading shows the relay can fire only in `StretchablePanelWdgt` (§6 S3): that class
   keeps it as its own two methods, and the other two consumers inherit.

### 0.4 What is NOT decided — the owner's calls

| # | Decision | Recommendation / decision | Where |
|---|---|---|---|
| D1 | The shape of the one pointer-state mechanism | open: three candidates stand after S2's paper half | §6 S2 |
| D2 | `ControllerMixin`: base class, or a per-widget wiring collaborator | **DECIDED 2026-11-10: base class** | §5.4 |
| D3 | Names of the new classes (all names in this plan are WORKING names) | — | §5 |
| D4 | The inspector loses "from `<X>Mixin`", "Override in this class" and the Add… destination step, with nothing in their place | accept: they exist only because of mixins | §7 Phase 8 |
| D5 | Coupling with the Smalltalk talk (2026-11-25, freeze 2026-11-21) | **DECIDED 2026-11-10: the talk plan drops mixins** (its D7), so neither plan builds on the other. When a code phase lands relative to the freeze is asked at that phase's commit | §11 |

### 0.5 Cold-execution protocol

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status`. If a long op is `RUNNING`, another
   session owns `src/` and the tests: read and plan only, edit docs at most.
2. Read this plan whole, then `docs/architecture/mixins.md` §2 (how the mechanism works) and
   `docs/architecture/widget-authoring-guidelines.md`.
3. Re-run the scan in §2.4 and compare with §2.2/§2.3. If anything differs, the tree moved: fix the
   plan's facts FIRST, in place, before executing.
4. Phases 1–4 wait on no investigation. Before Phase 5, 6 or 7, run the EMPIRICAL half of its
   investigation (§6): each paper verdict in §13 was reached by reading and is a hypothesis until
   a gauntlet has passed on it. Verdicts, and the owner's answers to D1, D3 and D4, go into §13.
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

One member shadows `Widget`'s for callers that never asked for the mixin:
`BackBufferMixin.calculateKeyValues`. It clamps the source rectangle to the BUFFER's pixel size
where `Widget.calculateKeyValues` clamps to the widget's extent, and it needs `@backBuffer` to
exist. On a back-buffered widget it answers `Appearance._calculateKeyValuesOrNil` (so a palette's
mark and a canvas's border are clipped by it) and `Widget._paintEditorSelectionOverlayIfSelected`
as well as the blit.

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

Two facts about the hand's order of work, which decide what a hook may ask it:
- `_dispatchEventsFollowingMouseMove` sends `hoverExited` to the leavers and `hoverEntered` to the
  joiners BEFORE it replaces `mouseOverList` (the assignment is at its tail, ~:1925). Inside either
  hook `restsOn(@)` still gives the previous answer.
- `_climbPressFrom` adds a receiver to `_pressAudience` before telling it `pressBegan`, and both
  endings strike a member off before telling it. Inside a press hook the audience is current.

And why the copies exist: the mixin's look hook STORES. `_updateColor`'s default writes `@color`;
`LabelButtonWdgt` restates the hooks, by its own comment, because the mixin's would "clobber" its
fill — its look is read from `state` at paint (`LabelButtonAppearance`). `DesktopLinkWdgt` gets the
same result by answering `_updateColor` with a bare `@_changed()`.

### 2.6 What the mechanism costs today

- `src/meta/Mixin.coffee`: 299 lines. Mixin-only members elsewhere, by name:
  `Class.findMixinsInTheClass`, `removeAugmentations`, `_takeMixinMembersFromTheStores`,
  `_bootDonorOf`, `augmentedWith`, `augmentRegex`, the donor fallback in `Class.removeMember`;
  `ClassInspectorWdgt._editMixinMember`, `_removeMixinMember`, `addPropertyToMixin`,
  `overrideInThisClass`; `InspectorWdgt.mixinDonorLabel`, `currentPropertySourceMixinName`,
  `_currentPropertySourceMixin`, the `_class_injected_in` half of `_isACompanion`;
  `SourceEditsRegistry.recordMixinEdit`, `recordMixinMemberRemoval`, `replayMixinEdits`, the mixin
  half of `returnThePageToBootSources`.
- 45 files under `buildSystem/` and 16 under the tests repo's `scripts/` reference the mechanism,
  none in the harness source. Classified file by file in
  `docs/measurements/mixin-teardown-census-2026-11-10.md`: in `buildSystem/`, 13 are comments only,
  20 parse or model the mixin DSL, 6 hold a rule or plant keyed on a mixin, 6 do both; in the rigs,
  8 are comments only and 8 hold expectations.
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

### 5.3 `BackBufferMixin` → the two appearances that exist, one line on text, and a kit — S1

`Widget` already delegates the three things the mixin overrides: `catchesPointerAt` →
`@appearance.shapeContainsPoint` (~:547), `paintIntoAreaOrBlitFromBackBuffer` →
`@appearance?.paintIntoAreaOrBlitFromBackBuffer` (~:595), `opaqueCoveredRect` →
`@appearance?.opaqueCoveredRect()` (~:3079). Base `Appearance` answers `shapeContainsPoint` (bounds)
and `opaqueCoveredRect` (`undefined`). A palette answers through `PaletteAppearance`, a canvas
through a `CanvasAppearance extends RectangularAppearance`, a text keeps one line and no
appearance; the blit, the pixel read and the shadow twin move to one plain class. Detail, what is
still open and the fallback: §6 S1.

### 5.4 `ControllerMixin` → base class `ControllerWdgt extends Widget` (core) — decided, D2

Six consumers extend `Widget` directly; `SliderWdgt` takes `CircleBoxWdgt`'s constructor body and
two methods itself (`SliderButtonWdgt` keeps `CircleBoxWdgt`; nothing in `src/` or the tests
type-tests a slider as a `CircleBoxWdgt`). `graphEdgesOut`'s `super()` becomes real. Zero call-site
changes, zero snapshot-format change (`@wires` stays a widget own-property). While
`BackBufferMixin` is still a mixin, `StringWdgt` and `PaletteWdgt` can extend `ControllerWdgt` and
keep augmenting it, so this does not wait on S1.

Not chosen: a per-widget wiring collaborator (`@wiring`) owning the `WireSpec` list. It would touch
about 19 lines in 10 `src/` files and 42 in 23 tests-repo files, change the snapshot format and
re-target every wiring menu row, for a benefit unrelated to mixins — it is the right design only
if ANY widget should be able to drive another (the target half of the wire protocol, `pins()` and
`principalPin()`, is already on `Widget`). That is its own arc if ever wanted; moving a base class
to a collaborator then is no harder than moving a mixin to one now.

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

### 5.7 `BubblesEditModeToCoordinatorMixin` → two methods of `StretchablePanelWdgt` — S3

The relay can fire in one class only, so that class owns it; `StretchableWidgetContainerWdgt` and
`VerticalStackViewportWdgt` drop the augmentation and inherit their parents' cores. Not a copy per
consumer (§0.3 point 5). The argument, and what a build must still show: §6 S3.

---

## §6 Phase 0 — investigations

Each has two halves. The PAPER half was done on 2026-11-10 by reading the source, with nothing
built or run; its verdict is below and in §13, and it is a hypothesis. The EMPIRICAL half runs on
a throwaway WIP branch or `git worktree` (never `git stash`), lands nothing, and ends by confirming
or correcting that verdict in §13.

### S1 — the back buffer (the crux)

**Question.** Can the three back-buffered widgets paint, hit-test and report coverage with the blit
body existing once and no member injected or re-declared?

**Facts to design against.**
- The mixin holds four fields (`backBuffer`, `backBufferContext`, `_backBufferShadowSilhouette`,
  `_backBufferShadowSilhouetteSource` — all in `Widget.@serializationTransients`), the blit
  (`blitBackBufferInto`, with `calculateKeyValues` and `_shadowSilhouetteOfBackBuffer`), the pixel
  read (`getPixelColor`), and three overrides (`paintIntoAreaOrBlitFromBackBuffer`,
  `catchesPointerAt` per pixel, `opaqueCoveredRect` → `undefined`).
- Each consumer family supplies `_createRefreshOrGetBackBuffer` (seven definers: `CanvasWdgt`,
  `StretchableCanvasWdgt`, `SimpleImageWdgt`, `VideoPlayerCanvasWdgt`, `StringWdgt`, `TextWdgt`,
  `PaletteWdgt`) and reads `@backBuffer`/`@backBufferContext` freely — about 140 sites in 16 files.
  Text and palette buffers are shared, immutable and cached by content; a canvas's raster is
  mutated in place and can be saved content (`CanvasWdgt.drawnRaster`).
- Outside the three families, `PenWdgt`, `ToolTipWdgt` and `PaletteAppearance` read the buffer or
  call `getPixelColor` / `blitBackBufferInto`.
- `StringWdgt` has NO appearance today. Every optional answer `Widget` asks an appearance for is
  probed with `?` — `outlineIsStroked`, `paintStroke`, `addShapeSpecificMenuItems`, `_fillColor`,
  `outlineCornerRadii`, `pins` (`grep -n "@appearance" src/basic-widgets/Widget.coffee`) — and base
  `Appearance` defines none of them, so a bare appearance would answer exactly as "none" does.
- The serializer walks an appearance like any other object: an appearance is one more live object
  and one more record in a saved file, per widget.
- `CanvasWdgt` keeps `PanelWdgt`'s `RectangularAppearance` for its border: the clipping
  `fullPaint…` tail calls `@paintStroke`, which is the appearance's. So a canvas needs the
  rectangular answers AND the blit.
- No class below the three consumers assigns an appearance of its own (13 subclasses checked), so
  an answer on the family's appearance reaches all of them.
- `calculateKeyValues` is shadowed for every caller (§2.3). A palette's and a canvas's buffers are
  made at extent × pixel ratio, so the two variants agree there once the buffer is fresh. A text's
  buffer is sized by its text and cached by content; nothing read so far shows it equals the
  widget's bounds.
- `buildSystem/check-back-buffer-memos.js` is a gate about these fields and reads `@augmentWith`.

**Paper verdict.** One appearance for all three is not the shape to build: every text would gain
an appearance object (each menu row's label is a `StringWdgt`) to carry a one-line paint, and the
canvas would need a second class on the `RectangularAppearance` branch anyway. Build this instead:

- **Palette.** `PaletteAppearance` answers all three: paint = the blit, then its mark, as today;
  `shapeContainsPoint` = the per-pixel test; coverage = base `undefined`. `PaletteWdgt`'s
  re-declared paint (§2.3) is deleted. No widget-side override.
- **Canvas.** `CanvasAppearance extends RectangularAppearance` answers the three — paint = the
  blit; `shapeContainsPoint` per pixel; coverage `undefined`, where `RectangularAppearance` claims
  its box — and `CanvasWdgt` constructs it in place of the panel's. The three subclasses that
  answer `catchesPointerAt` themselves keep doing so.
- **Text.** No appearance. `StringWdgt` keeps ONE line, `paintIntoAreaOrBlitFromBackBuffer` calling
  the blit. It already answers `catchesPointerAt`, and with no appearance
  `Widget.opaqueCoveredRect` already answers `undefined`.
- **The kit** — the blit, the buffer-clamped key values, the pixel read, the shadow twin — moves
  to ONE plain class the three call. The four fields stay widget fields (140 sites).

**Still open; the empirical half decides them first.**
- Where the four fields are declared once the mixin is gone, and whether the shadow twin stays two
  per-widget fields or becomes a cache keyed by the buffer (texts sharing one immutable buffer
  would then share one twin). Read `docs/architecture/world-lifetime-and-inventory.md` before
  adding any page-lifetime state.
- Whether `calculateKeyValues` must keep shadowing on text. Unless the two variants are shown equal
  there, it stays a member of the text family; dropping it silently changes the clip of a selected
  text's selection ring.

**Empirical half — accept when** the full gauntlet passes with ZERO reference recaptures at dpr 1,
dpr 2 and WebKit (this is a pure re-routing) — including its `vmtruth` and `serialization` legs,
which hold object lifetime and the transients — `check-back-buffer-memos.js` is re-pointed and its
bite-proof still bites, and a selected text, a selected palette and a selected canvas each paint
their selection overlay as before (if no reference shows one, add the test BEFORE the change).

**Fallback, always available.** Each of the three consumers declares three one-line overrides over
the same kit: at most nine stubs, fewer in practice (text needs one). If the shape above fails
twice, take this; do not start a third.

### S2 — one pointer-state mechanism

**Question.** Can one implementation of the transition rules serve all of §2.5, and where does it
live?

**Paper findings.**
1. *A hover hook cannot ask the hand; a press hook can* (§2.5's two ordering facts). "Derived from
   the hand" therefore works only if the look is read at PAINT time, the hook merely invalidating —
   or if the hand's hover bookkeeping is reordered, in the most determinism-sensitive file in the
   tree.
2. *The shared transitions must end in a look hook that stores nothing by default* (§2.5, why the
   copies exist). With that, `LabelButtonWdgt` needs the hook and its two real differences, not
   five restated methods.
3. *The tooltip countdown is part of the protocol:* the same two lines (`startCountdownForBubbleHelp`
   on entry, `world.destroyToolTips()` on exit) sit in three of the five hover implementations.
4. *What each class keeps as its own exception:*

   | Class | What it does differently |
   |---|---|
   | `DesktopLinkWdgt` | a press on its caption plate is not a press on its tile |
   | `LayoutChromeWdgt` | pressed only where `_showsPressOnMyPlate()` |
   | `SliderButtonWdgt`, `HandleWdgt` | stay pressed while the hand non-float-drags them, whatever the pointer is over; ignore a hover that arrives meanwhile |
   | `HandleWdgt`, `LayoutChromeWdgt` | also end the pressed look at `endOfNonFloatDrag` |
   | `LabelButtonWdgt` | `pressEnded` changes nothing; `activated` forces the hover look — for a finger too, which the mixin never shows hovered |
   | `MenuItemWdgt` | a list row shows hover on its plate and ends its press at rest; it also highlights the widget it stands for |

**Candidates after the paper half.**
- *The hand tells an optional collaborator* (new). A widget that wants a pointer look owns one
  small plain object; the hand sends the five facts to it beside the hooks it already sends; the
  object keeps the state, runs the tooltip countdown and calls the widget's ONE look hook. No line
  on `Widget`, no forwarding method, and the hand's bookkeeping order is untouched — the object is
  TOLD, it never asks. Cost: five sends in `ActivePointerWdgt`, and one field per opted-in widget.
- *Stored once, opt-in on `Widget`.* `Widget` answers the five hooks for widgets that opt in and
  calls one look hook (the first analysis estimated about 35 lines; it replaces five copies).
  Against the shrink-`Widget` and no-base-default-for-a-capability rules.
- *Derived at paint time.* No stored state; each look asks the hand as it paints. It needs every
  consumer's look to be read at paint — true of `LabelButtonWdgt` and `DesktopLinkWdgt`, false of
  every class whose `_updateColor` writes `@color` — so it is the largest change of the three.
- Not a candidate: a base class plus re-parenting. It serves `ButtonWdgt` and the app-kit pair and
  leaves `DesktopLinkWdgt`, the two icon buttons and the four hand-rolled copies where they are.

**Determinism.** The look must stay a function of the event stream: read
`../../Fizzygum-tests/DETERMINISM.md` (§3n is the finger/hover case `pointerCanRest` cites) before
building, and prove the chosen candidate with `fg fuzz` as well as the dpr 2 leg.

**Empirical half — accept when** the transition rules exist once, every class in §2.5 keeps only
its look and its row of the table above, and the gauntlet passes with zero recaptures.

**One `super` flips meaning under any shape that puts the transitions above `DesktopLinkWdgt`:**
its `pressBegan` (§2.3) would start reaching them, pressing the tile on a caption press — the very
thing the method exists to avoid. Restructure it in the same commit.

### S3 — the edit-mode relay

**Facts.** The two cores take `(triggeringWidget)`, tell the parent's bar the new mode, and — when
the parent answers `coordinatesDragsDropsAndEditingForChildren?()` and is not the trigger — relay
the toggle to it; otherwise `super()`. `Widget`, `FrameWdgt` and `ViewportWdgt` define cores that
take no parameter; `FrameWdgt`'s and `ViewportWdgt`'s call their `@contents`' cores passing `@`,
and `Widget.editButtonPressedFromFrameBar` passes `@` to the public verbs. The three consumers are
exactly the three classes whose menus offer "Enable editing" / "Disable editing"
(`_addEditingLockMenuEntries`).

**Paper verdict: the relay is live in one class.**
- One class answers the coordinator query, `StretchableWidgetContainerWdgt` (~:268), and it has no
  subclass. Through its constructor and its `add`, its direct children are its `@contents` — a
  `StretchablePanelWdgt` unless a caller
  passes one (`ImageWdgt` passes a `StretchableCanvasWdgt`, which is no consumer) — and what answers
  `attachesToViewportDirectly` (`HandleWdgt`, `ModifiedTextTriangleAnnotationWdgt`), neither of
  which toggles edit mode. Nothing in `src/` or the tests makes a `VerticalStackViewportWdgt`, or
  a second container, a coordinator's direct child.
- So in `VerticalStackViewportWdgt` and in the container itself the relay test is false wherever
  they are built today, and the injected core reduces to an early `@parent?.showEditModeInBar?()`
  — sent BEFORE the mode flag is written — followed by `super()`. `Widget`'s and `ViewportWdgt`'s
  cores make that same call themselves after writing the flag, so the early one is superseded.
- `triggeringWidget` exists to stop a relay bouncing back, and it cannot bounce: the coordinator's
  core is `Widget`'s, which acts on `@contents` by writing its flag, never by calling its core.
  Nobody passes the container as the trigger.

**Shape.** `StretchablePanelWdgt` defines the two cores in its own class body: the guard, the
relay when its parent coordinates, else a real `super()`. `StretchableWidgetContainerWdgt` and
`VerticalStackViewportWdgt` drop the augmentation and inherit. One copy, in the one class that
uses it. (Moving the relay into `Widget`'s cores instead would also start relaying from the canvas
of an image window, which does not relay today.)

**Then, in the same phase if the empirical half agrees:** the `triggeringWidget` parameter is dead
everywhere — the two Stretchables' public wrappers, the `@` the three callers above pass, and the
comments in `Widget`, `FrameWdgt` and `ViewportWdgt` that explain it. Delete it;
`buildSystem/check-call-arguments.js` holds the call sites consistent.

**Empirical half — accept when:**
1. BEFORE the change, a `console.error` planted in the mixin's relay branch for any receiver that
   is not a `StretchablePanelWdgt` (through a prelude, as the gates' bite-proofs plant) prints
   nothing over the whole suite. That shows no test reaches it; the bullets above are the argument
   that nothing else does.
2. After the change the gauntlet passes with zero recaptures.
3. One state is settled by hand: `Widget`'s core returns early, before telling the bar, when
   `@contents` already holds the target mode and the receiver does not. Today the injected early
   call still tells the bar in that state. Establish whether it can arise; if it can, keep a call.

---

## §7 Phases

Order: the base-class moves first (Phases 1–4, independent of every investigation), then the
phases that wait on an investigation's empirical half, then the teardown. Each phase closes on `fg gauntlet`; the ones marked ⌂ also run
`fg homepage` (they touch a lazy part or the meta layer).

| Phase | What | Waits on | Expected references |
|---|---|---|---|
| 1 | Clipping → `ClippingWdgt` (§5.1) | — | pixel-identical; inspector member-list and class-chip shots move |
| 2 | KeepsRatio → base class (§5.2) | — | same |
| 3 | Controller → `ControllerWdgt` (§5.4) | — | same |
| 4 ⌂ | The app-kit pair's shared base; SmartPlacer mixin deleted (§5.5) | — | same |
| 5 | BackBuffer per S1 (§5.3) | S1's empirical half | pixel-identical |
| 6 ⌂ | The relay into `StretchablePanelWdgt`; Bubbles and `triggeringWidget` deleted (§5.7) | S3's empirical half | pixel-identical |
| 7 ⌂ | Pointer state per S2; Highlightable and ParentStainer deleted — the LAST mixins (§5.6) | D1, S2's empirical half, Phase 4 | pixel-identical; two tests retired, two re-pointed |
| 8 ⌂ | Mechanism teardown | Phases 1–7, D4 | inspector shots |
| 9 | Docs and close | Phase 8 | — |

**The mechanism is FROZEN from Phase 1.** No mixin feature changes while this plan runs. Its own
tests and rig checks use a mixin as their subject, so they stop being runnable phase by phase, well
before Phase 8 — the census's §1 and §4 list every one. The rule, applied in the phase that deletes
the subject: a check that exists ONLY for the mechanism is retired there; a general check that
merely uses a mixin as its example gets a new subject there, and keeps biting.

| Phase | Check whose subject this phase deletes | Do |
|---|---|---|
| 2 | `parts-lazy-load-headless.js`, the `LAZY_CONSUMER_TAKES_MIXIN_EDITS` section, with its self-test's plants and second run (subject: KeepsRatio, through the lazy `plots` part) | retire (mechanism-only) |
| 3 | `serialization-roundtrip-headless.js`, `world.inspector.classSubjectsSurviveSnapshot` (subject member: `openTargetSelector`) | drop its donor-attribution fact; point the rest at a member `SliderWdgt` owns or inherits |
| 5 | `buildSystem/check-stinks.js`, the sanctioned entry naming `mixins/BackBufferMixin.coffee` / `getPixelColor` | re-point at the kit's new file (it fails loud, `STALE_SANCTION`, if forgotten) |
| 7 | `SystemTest_macroMixinEditDonorAndOverride`, `SystemTest_macroMixinFieldEditDonorAndOverride`, and their two lines in `inspector-churn-set.json` | retire |
| 7 | `SystemTest_macroClassInspectorSaveRefusesCodeThatDoesNotCompile`, `SystemTest_macroInspectorOffersOnlyWhatItsSubjectOwns` (they assert on a member `HighlightableMixin` gives `ButtonWdgt`) | new subject |
| 7 | the serialization rig's four donor checks (`sourceEdits.removedOverrideRestoresDonor`, `…donatedRenameRoutesToDonor`, `…removedOverrideRestoresTheWinningDonor`, `…removalIsAllOrNothing`) | retire, with their names in `lib/serialization-expectations.js` |
| 7 | `sourceEdits.loadOverPageEditsIsTheFilesWorld` and its two siblings; `boot.classNamedIsTheOneDefinition` | drop their mixin steps |
| 7 | `smoke-boot-headless.js`, the three mixin verdicts (one requires `augmentations > 0`) | retire |

Pointer state goes last among the mixins (Phase 7) because all four mixin-dependent SystemTests and
most of the rig checks use `HighlightableMixin`: they then stand until the phase before the
teardown.

**Per-phase recipe for a base-class move (Phases 1–4).**
1. Create the class file (one class per file, filename = class name) in a directory its part owns;
   move the members verbatim; turn the emulated `super`s into real ones.
2. Re-parent each consumer; restate what a dropped intermediate parent contributed (§2.2).
3. Replace §2.3's workarounds that the move dissolves; delete the mixin file; remove its
   `@augmentWith` lines.
4. Update comments that name the mixin (`grep -rn "<Name>Mixin" src ../Fizzygum-tests`), including
   test descriptor metadata, and apply the row of the table above for this phase.
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
- Build tools and rigs: work through the census file by file
  (`docs/measurements/mixin-teardown-census-2026-11-10.md` §3; re-derive its file set first, with
  `grep -rliE "mixin|augmentWith|augmentedWith|_class_injected_in|onceAddedClassProperties|addInstanceProperties" buildSystem ../Fizzygum-tests/scripts`
  — case-INSENSITIVE, because the tokens are spelled `MIXIN_…`, and expect "mixing" among the
  hits). Remove the DSL parsing; retire what remains of the mechanism-only rules
  (`SHADOWS-MIXIN`, `MIXIN_MEMBER_UNRECORDED`, `BUILDER_IN_MIXIN`, `ELEMENT_FIELD_IN_MIXIN`) each
  with its bite-proof; rename `MIXIN_CHAIN_TERMINATES`, a general check, in the rig and its
  self-test together.
- The loaders change in the SAME commit that deletes `Mixin.coffee` (census §4 answer 2):
  `buildSystem/lib/meta-compiler.js`, `lib/call-sites.js` (it dereferences `Mixin`
  unconditionally), `check-coffee-syntax.js` with its self-test's `pass` regex, and the three
  self-tests that copy the file. Otherwise the syntax gate exits 2 and the build aborts.
- `"src/mixins"` must leave `parts.json` by hand: `build.py` globs a missing directory to nothing,
  so a stale entry is silent.
- Tests: by now the four mixin-dependent SystemTests were handled in Phase 7. What remains is
  prose — 39 test directories name a `*Mixin` in descriptor metadata or comments
  (`grep -rlE "[A-Za-z]+Mixin\b" ../Fizzygum-tests/tests`).
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
- **R8 — a new home the gates cannot see.** `buildSystem/lib/coffee-method-header.js` (19 files
  import it) is what lets a gate see a member written deeper than two spaces inside an object
  literal — a mixin's. A member moved into a class body, at two spaces, is seen by the ordinary path; one
  moved into any other object literal is seen by NOTHING, and a blind gate reports nothing. So
  every new home in this plan is a class. Three gates then judge the moved members differently, in
  the loud direction: `census-widget-conformance.js` wants each field declared in the consumer's
  `extends` chain; `check-layering.js` starts resolving a definer kind for them; and
  `check-plane-discipline.js` checks a base class's pointer handlers against the base, not against
  its subclasses (census §3).

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
   `fg recapture-inspector`, after a fresh build. The shots that can move are those of the
   inspector churn set — the tests whose screenshots render a live member list, 18 today
   (`../Fizzygum-tests/scripts/inspector-churn-set.json`, re-derived by
   `scripts/derive-inspector-churn-set.js`): an inspector lists a prototype's OWN members unless
   "Inherited" is on, so a member that moves up to a base class leaves its consumer's list. Two of
   the 18 are the mixin tests Phase 7 retires.
4. **Counts are re-derived, never copied.** §5.4's wiring call-site figures, for the arc D2 did
   not choose, come from
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
- **An appearance on every text, to carry the blit.** One more live object and one more saved
  record per `StringWdgt`, for a one-line paint (§6 S1).
- **A wiring collaborator inside this arc.** Not chosen (D2, §5.4): its cost and its benefit are
  both unrelated to removing mixins.
- **Deriving a pointer look from the hand inside a hover hook.** The hand's over-list is not yet
  updated when the hook runs (§2.5).
- **The edit-mode relay in `Widget`'s cores.** It would widen the relay to every child of a
  coordinator, the canvas of an image window among them (§6 S3).
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

- `plans/smalltalk-talk-2026-11-plan.md` (talk 2026-11-25, freeze 2026-11-21) shows nothing of
  mixins and builds nothing for them (its D7, this plan's D5). Its §1.1 states what its views leave
  uncovered while the mechanism is still in the tree; that note goes when Phase 8 lands.
- `plans/single-file-save-plan.md` ships `Mixin-source.js` and lists a mixin-then-class edit
  replay; both shrink after Phase 8. Whichever arc runs second re-verifies against the other.
- `plans/creation-and-templates-plan.md` §4.3 plans to fold the creator zoo (`CreatorButtonWdgt`
  among it); Phase 4's shared base should not fight that — read it first.
- `docs/BACKLOG.md`, open items that change: "A snapshot's source edits of a lazy part's classes
  are dropped…" loses its mixin half; the owner-gated paint-time-scroll Phase 4 ("lift … to the
  clipping-mixin level") reads "to the clipping base class" after Phase 1 and becomes simpler; the
  `fg recapture-inspector` item names the two tests Phase 7 retires.

---

## §12 References

- `docs/architecture/mixins.md` — the mechanism (§2) and the superseded keep position (§1, §5, §7).
- `docs/archive/mixin-application-tidyups-plan.md`, `docs/archive/mixin-editing-v2-plan.md`,
  `docs/archive/god-class-decomposition-plan.md` — the prior mixin arcs and the delegation
  precedent.
- `docs/architecture/widget-authoring-guidelines.md`, `appearance-paint-convention.md`,
  `viewports-and-planes.md`, `input-and-gestures.md`, `lint-and-static-checks.md`,
  `serialization-duplication-reference.md`, `build-and-packaging.md`.
- `docs/measurements/mixin-teardown-census-2026-11-10.md` — every build tool and rig that
  references the mechanism, what each needs, and which checks break in which phase.
- `../../Fizzygum-tests/DETERMINISM.md` — before touching pointer state or the paint path.
- `src/dataflow/CLAUDE.md` — before touching wiring.

---

## §13 Ledger — verdicts and decisions (filled in as the plan runs)

| Item | Verdict / decision | Date | Evidence |
|---|---|---|---|
| S1 the back buffer — paper half | Palette and canvas answer through their appearance; text keeps one line and no appearance; the kit moves to one plain class. Open: where the fields are declared, the shadow twin's home, whether text keeps the shadowing `calculateKeyValues` | 2026-11-10 | by reading; §6 S1 |
| S1 — empirical half | — | | |
| S2 pointer state — paper half | No candidate chosen. A hover hook cannot ask the hand; the look hook must store nothing by default; a new candidate (the hand tells an optional collaborator) joins the list | 2026-11-10 | by reading; §2.5, §6 S2 |
| S2 — empirical half | — | | |
| S3 the edit-mode relay — paper half | Live in `StretchablePanelWdgt` only: it keeps the two cores, the other two consumers inherit, and `triggeringWidget` can go | 2026-11-10 | by reading; §6 S3 |
| S3 — empirical half | — | | |
| Teardown census (Phase 8's input) | 61 files classified; checks break in the phase that deletes their subject, so the mechanism is frozen and pointer state goes last | 2026-11-10 | by reading; `docs/measurements/mixin-teardown-census-2026-11-10.md` |
| D1 pointer-state shape | open | | |
| D2 Controller: base class or collaborator | base class | 2026-11-10 | owner |
| D3 class names | open | | |
| D4 inspector loses the donor vocabulary | open | | |
| D5 coupling with the talk | the talk plan drops mixins (its D7) | 2026-11-10 | owner |

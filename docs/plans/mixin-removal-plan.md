# Mixin removal — every mixin to an ordinary home, then delete the mechanism

**STATUS: EXECUTING — AUTHORED 2026-11-10, MEASURED 2026-11-12; Phases 1–6 landed 2026-11-12 (§13).** Written to be
executed COLD by an LLM/engineer with ZERO prior context: everything needed is embedded here or one
named-doc hop away.
**Where it stands (§13):** all eleven owner decisions are made — on the owner's stated criterion, the
tree's cleanliness and regularity, whatever the churn. The three investigations have a paper
verdict (2026-11-10, by reading) and, since 2026-11-12, their MEASURED half: instruments over the
whole suite and two direct probes, with nothing in `src/` changed. The measurements settled S1's
open question, confirmed S3 and showed the suite cannot see its relay, and turned S2's promised
behaviour questions into five decisions, D6–D10, which the owner made the same day. What each
investigation still owes is its change under the gauntlet, which is its phase (S1's landed with
Phase 5 and S3's with Phase 6; S2's is Phase 7). No phase waits on the owner; Phases 7, 8 and 9 wait on the phases before them (§7).

Every fact below was read on 2026-11-10 at Fizzygum `a37b8ba4` / Fizzygum-tests `61adb7ce1` and
re-checked on 2026-11-12 at Fizzygum `59728ec2` / Fizzygum-tests `e2ea7ad0d`: the §2.4 scan gives
the same consumers, shadowing members and `super` targets; the counts and line hints that had
drifted are corrected in place. **Line numbers are hints and drift; the quoted method name is
authoritative — grep it fresh before trusting a line.** Counts come with the command that produced
them (§2.4); re-run it rather than carrying a number forward. The scan as a script, the
instruments, the probes and their output are in
`Fizzygum-tests/.scratch/mixin-removal-loop/investigations/` (untracked).

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
   have, plus one line on `StringWdgt`; the rest of it — the blit, the pixel read, the shadow twin
   — is the buffer's own behaviour, and becomes a `BackBuffer` object (§6 S1).
4. **Pointer state has five homes today, not one.** `HighlightableMixin` is one; four classes
   hand-roll the same hover/pressed machine beside it (§2.5). The job is ONE pointer-state
   mechanism for about ten classes, not "re-home a mixin with six consumers".
5. **`BubblesEditModeToCoordinatorMixin` sits on three branches, and its relay is live on ONE.** It
   was created on 2026-07-27 because its two cores sat byte-identical in three classes
   (`docs/archive/mixin-application-tidyups-plan.md`, Item A), so copying them back is not an
   option. Reading shows the relay can fire only in `StretchablePanelWdgt` (§6 S3): that class
   keeps it as its own two methods, and the other two consumers inherit.

### 0.4 The owner's decisions

| # | Decision | Recommendation / decision | Where |
|---|---|---|---|
| D1 | The shape of the one pointer-state mechanism | **DECIDED 2026-11-10: the hand knows, a widget asks as it paints** — no widget stores a pointer state | §6 S2 |
| D2 | `ControllerMixin`: base class, or a per-widget wiring collaborator | **DECIDED 2026-11-10: base class** | §5.4 |
| D3 | Names of the new classes, and of the two new members on the hand's protocol | **DECIDED 2026-11-10:** `ClippingWdgt`, `RatioLockedWdgt`, `ControllerWdgt`, `CreatorWdgt`, `CanvasAppearance`, `BackBuffer`; `pressesOn`, `notePointerStateChanged` | §5.8 |
| D4 | The inspector loses "from `<X>Mixin`", "Override in this class" and the Add… destination step, with nothing in their place | **DECIDED 2026-11-10: accepted** | §7 Phase 8 |
| D5 | Coupling with the Smalltalk talk (2026-11-25, freeze 2026-11-21) | **DECIDED 2026-11-10: the talk plan drops mixins** (its D7), so neither plan builds on the other. When a code phase lands relative to the freeze is asked at that phase's commit | §11 |
| D6 | Pointer looks where a stored state lagged the pointer | **DECIDED 2026-11-12: the look follows the pointer.** A held press that slides back onto its widget shows pressed again; no pressed or hovered look is left behind by a release that was no click, a cancelled press, a click made by code, or a re-parented chrome plate. Nothing is remembered to reproduce the old looks | §6 S2 |
| D7 | The slider thumb's two quirks | **DECIDED 2026-11-12: the thumb follows the rule every button follows.** Hovered at once when its drag ends with the pointer on it; not left hovered after a click when the pointer is elsewhere. The references that show either state are recaptured after each is looked at | §6 S2 |
| D8 | A finger over a handle or a layout-chrome plate | **DECIDED 2026-11-12: one rule — a finger rests nowhere, so it is shown no hover, on anything.** These two families lose the exception they had by omission; a drop slot no longer lights under a finger carrying a payload | §6 S2 |
| D9 | The eight classes that carry a `toolTipMessage` they never show (§2.5) | **DECIDED 2026-11-12: no widget gains a tooltip, and `toolTipMessage` means one thing** — the tooltip shown when the pointer rests on me, which the hand shows. The eight stop carrying one; what a tool panel shows for a tool is the tool's NAME, stated apart (§6 S2) | §6 S2 |
| D10 | The selection ring of a one-line text whose buffer is smaller than its box (a bare, top-left `StringWdgt` set to `SCALEUP`) | **DECIDED 2026-11-12: it rings the box,** as every other widget's does; the text family keeps no `calculateKeyValues` of its own | §6 S1 |
| D11 | Phase 4 changes one digit outside an inspector: two mixin tests show "Saved to HighlightableMixin (6 consumer classes updated)", and it reads 5 once `CreatorButtonWdgt` and `GlassBoxTopWdgt` become ONE consumer, `CreatorWdgt` | **DECIDED 2026-11-12: A — recapture the two shots** (raised by the loop's U5, Phase 4, which resumes from its kept patch). What a person sees: the pop-up after saving a Highlightable member in a class inspector counts one class fewer; nothing else moves outside inspector member lists. The count is true; the loop's recapture grant does not cover a message pop-up, so it asks. (A) recapture the two shots — `SystemTest_macroMixinEditDonorAndOverride` and `SystemTest_macroMixinFieldEditDonorAndOverride` image_2, mouse and finger, dpr 1 and 2 (8 references; both tests retire in Phase 7). (B) keep `CreatorButtonWdgt` and `GlassBoxTopWdgt` augmenting the pair themselves until Phase 7, `CreatorWdgt` carrying only `activated` — the count stays 6, the augmentations stay stated twice, against §5.5. **Recommendation: A** — Phase 4 as §5.5 designs it; the shots are mechanism-only and the measurement is one digit (6 px at dpr 1, 38 at dpr 2: `Fizzygum-tests/.scratch/mixin-removal-loop/u5-creator/diffpage/`). The same move teaches the lookup rule a fourth effect: a mixin that survives a phase can lose consumers, when two of them become one base | §5.5, §7 |

### 0.5 Cold-execution protocol

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status`. If a long op is `RUNNING`, another
   session owns `src/` and the tests: read and plan only, edit docs at most.
2. Read this plan whole, then `docs/architecture/mixins.md` §2 (how the mechanism works) and
   `docs/architecture/widget-authoring-guidelines.md`.
3. Re-run the scan in §2.4 and compare with §2.2/§2.3, less what the §13 rows of landed phases removed.
   If anything else differs, the tree moved: fix the plan's facts FIRST, in place, before executing.
4. Phases 1–4 wait on nothing. Each investigation has its paper verdict and its measured half
   (§6, §13); what it still owes is its change under the gauntlet, which IS its phase — and a
   measured verdict is still a hypothesis until that gauntlet has passed. Verdicts go into §13.
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

**As of 2026-11-12, before Phase 1.** A landed phase moves these facts: its §13 row says what it
removed (Phase 1: the Clipping row of §2.1, its 7 consumer slots, its four borrow sites of §2.3; Phase 2: the
KeepsRatio row, its 3 slots; Phase 3: the Controller row, its 7 slots; Phase 4: the SmartPlacer row, and
`CreatorButtonWdgt` and `GlassBoxTopWdgt` as consumers of Highlightable and ParentStainer, which `CreatorWdgt` now is;
Phase 5: the BackBuffer row, its 3 slots,
§2.3's `PaletteWdgt.paintIntoAreaOrBlitFromBackBuffer` and `StringWdgt.catchesPointerAt` rows, its `calculateKeyValues`
paragraph, and the three `catchesPointerAt` overriders in its subclass list, which now override `Widget`'s; Phase 6: the Bubbles row, its 3 slots, and §2.3's sentence on the
two Bubbles cores injected into `VerticalStackViewportWdgt`, which now inherits `ViewportWdgt`'s), and
§2.4's cross-checks then print the remainder.

### 2.1 Inventory

Eight mixins, 1,226 lines, 35 consumer slots over 28 classes. Six live in `src/mixins/` (part
`core`), two in `src/app-kit/` (the lazy `app-kit` part).

| Mixin | Lines | Members | Consumers | Members that call `super` |
|---|---|---|---|---|
| `ControllerMixin` | 582 | 31 | `SliderWdgt`, `StringWdgt`, `PaletteWdgt`, `ColorPickerWdgt`, `FanoutWdgt`, `FanoutPinWdgt`, `PatchNodeWdgt` | `graphEdgesOut` |
| `ClippingAtRectangularBoundsMixin` | 212 | 10 | `PanelWdgt`, `ViewportWdgt`, `FrameWdgt`, `InspectorWdgt`, `SimpleSpreadsheetWdgt`, `VerticalStackPanelWdgt`, `ClippingBoxWdgt` | `fullPaintIntoAreaOrBlitFromBackBuffer` |
| `BackBufferMixin` | 178 | 11 | `CanvasWdgt`, `StringWdgt`, `PaletteWdgt` | none |
| `HighlightableMixin` | 74 | 13 | `ButtonWdgt`, `CreatorButtonWdgt`, `GlassBoxTopWdgt`, `DesktopLinkWdgt`, `EditorContentPropertyChangerButtonWdgt`, `UpperRightTriangleIconicButtonWdgt` | `pressBegan` |
| `KeepsRatioWhenInVerticalStackMixin` | 69 | 6 | `IconWdgt` (72 direct subclasses), `GraphsPlotsChartsWdgt`, `PlotWithAxesWdgt` | none |
| `BubblesEditModeToCoordinatorMixin` | 51 | 2 | `StretchablePanelWdgt`, `StretchableWidgetContainerWdgt`, `VerticalStackViewportWdgt` | both |
| `WidgetCreatorAndSmartPlacerOnClickMixin` | 39 | 1 | `CreatorButtonWdgt` (16 subclasses), `GlassBoxTopWdgt` | none |
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
| `ViewportWdgt._fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow` and `…JustShadow` (`ViewportWdgt.coffee` ~:363, ~:388) | adds the scroll translation; on the zero-offset path calls `PanelWdgt::<same method>.call @, …` | it cannot `super` into the mixin's copy, so it borrows `PanelWdgt`'s injected copy |
| `FrameWdgt`, the same two methods (`FrameWdgt.coffee` ~:2150, ~:2165) | adds the rounded child clip; the clip-off path calls `PanelWdgt::….call @` | same |
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
grep -rn "^  @augmentWith" src --include='*.coffee' | wc -l            # 35 consumer slots before Phase 1
grep -rnE "[A-Z][A-Za-z]+Wdgt::[A-Za-z_]+\.(call|apply)" src --include='*.coffee'   # the 4 borrow sites before Phase 1 (none after it)
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
`ParentStainerMixin._updateColor` → `@parent?.noteItemStateChanged?()`. It then STORES the answer:
`_deriveMyLook` writes `@color` and `@cornerRadius`, a second copy of the tool's state.

What else hangs on the same hooks (the 2026-11-12 survey, §6 S2):
- `FrameGripWdgt` (a `HandleWdgt`) overrides `_setPointerState` to keep a third stored fact,
  `_activeLookShowing`, and with it two pieces of WORLD state: the canvas cursor and the resize
  outline it declares in `world.widgetsToBeHighlighted`.
- `StackElementsSizeAdjustingWdgt` (a `LayoutChromeWdgt`) and `ExternalLinkButtonWdgt` set the
  canvas cursor in their hover hooks. `SliderButtonWdgt` also answers `hoverMoved` and `activated`.
- `HandleWdgt` and `LayoutChromeWdgt` light their plate on `hoverEntered` without asking
  `pointerCanRest()`: they are the two families that show a hover under a finger.
- Two of the hand's facts are written from OUTSIDE it: `WorldWdgt._softResetWorld` (the recovery
  after a thrown error) clears `hand.mouseOverList` and `hand.nonFloatDraggedWdgt`, telling no
  widget.
- `_updateColor` has callers that are not transitions: constructors, `SimpleButtonWdgt.setEnabled`,
  `LabelledToggleWdgt.setOn`, `IconButtonWdgt`'s ink setter.
- `toolTipMessage` is carried by eight classes that never show it — `RectangleWdgt`,
  `SpeechBubbleWdgt` and six of `src/authoring-icons/` (`BrushIconWdgt`, `DestroyIconWdgt`,
  `EraserIconWdgt`, `MapPinIconWdgt`, `Pencil2IconWdgt`, `ToothpasteIconWdgt`): each holds one only
  so that `ToolPanelWdgt` can copy it onto the `GlassBoxTopWdgt` standing over it in a tool panel.
  (`OverflowChevronButtonWdgt` names a tool `tool.toolTipMessage ? tool.colloquialName()`.)

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

- `src/meta/Mixin.coffee`: 308 lines. Mixin-only members elsewhere, by name:
  `Class.findMixinsInTheClass`, `removeAugmentations`, `_takeMixinMembersFromTheStores`,
  `_bootDonorOf`, `augmentedWith`, `augmentRegex`, the donor fallback in `Class.removeMember`;
  `ClassInspectorWdgt._editMixinMember`, `_removeMixinMember`, `addPropertyToMixin`,
  `overrideInThisClass`; `InspectorWdgt.mixinDonorLabel`, `currentPropertySourceMixinName`,
  `_currentPropertySourceMixin`, the `_class_injected_in` half of `_isACompanion`;
  `SourceEditsRegistry.recordMixinEdit`, `recordMixinMemberRemoval`, `replayMixinEdits`, the mixin
  half of `returnThePageToBootSources`.
- 45 files under `buildSystem/` and 19 under the tests repo's `scripts/` reference the mechanism,
  none in the harness source. The census classifies the 45 and 16 of the 19 file by file
  (`docs/measurements/mixin-teardown-census-2026-11-10.md`): in `buildSystem/`, 13 are comments
  only, 20 parse or model the mixin DSL, 6 hold a rule or plant keyed on a mixin, 6 do both; in the
  rigs, 8 are comments only and 8 hold expectations. Three rig files are newer than the census and
  all three hold expectations: `parts-snapshot-load-headless.js` with its self-test, and
  `smoke-boot-selftest-headless.js` (their checks are in §7's table).
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
things change for its members — (a) `super` inside a consumer member that shadows a moved member now
reaches `B`'s member where it used to reach `Widget`'s; (b) the member is inherited, no longer the
prototype's own, which changes inspector member lists and class chips — and one for its statics:
(c) a class copies its parent's own statics when it is defined (`extend`, `src/boot/globalFunctions.coffee`),
so a consumer defined after boot (a lazy part's) starts `instancesCounter` and
`lastBuiltInstanceNumericID` from `B`'s, never instantiated and so 0, where it took `Widget`'s live
count. That reaches only the numbers in instance names (messages, saved files) until the next world
reset, which zeroes every `lastBuiltInstanceNumericID`, and the never-reset profiling count `instancesCounter`. (A base
that is itself defined after boot, with its consumers, copies `Widget`'s live count and hands it on: no change.) For a
consumer that had another parent (§2.2's eight), that parent's contribution must be restated on the consumer, and nothing
else. And one for a mixin that survives the phase: (d) when two of its consumers become one base that states the
augmentation once, it loses a consumer — what the class inspector's save pop-up counts ("N consumer classes updated"),
one fewer (Phase 4, D11).

### 5.1 `ClippingAtRectangularBoundsMixin` → base class `ClippingWdgt extends Widget` (core)

The ten members move verbatim; `fullPaintIntoAreaOrBlitFromBackBuffer`'s `super` becomes a real
one. `PanelWdgt`, `ViewportWdgt`, `FrameWdgt`, `InspectorWdgt`, `SimpleSpreadsheetWdgt`,
`VerticalStackPanelWdgt` change `extends Widget` to `extends ClippingWdgt`. `ClippingBoxWdgt`
(demos) extends `ClippingWdgt` and takes `BoxWdgt`'s one-line constructor body itself. The four
`PanelWdgt::….call @` borrows (§2.3) become `super`. Of §2.3's shadowing members here none calls
`super`, so change (a) does not arise. `docs/architecture/viewports-and-planes.md` states why
`PanelWdgt` is purely the SURFACE class; a clipping base above it is consistent with that.

### 5.2 `KeepsRatioWhenInVerticalStackMixin` → base class `RatioLockedWdgt extends Widget` (core)

Six members, no `super`, no shadowing; all three consumers extend `Widget` directly. The base
lives in core because `IconWdgt` is core and a base class may cross a part boundary only under
`requires` (the plots are in a lazy part; core is always present). ⛔ Do not convert the two
pinned-`@ratio` variants (`Example3DPlotWdgt`, `StretchableWidgetContainerWdgt`) or the square/grid
measures (`AnalogClockWdgt`, `GenericCompositeIconWdgt`, `WidgetHolderWithCaptionWdgt`,
`TrackingTransformFrameWdgt`): that conversion was falsified (§10).

### 5.3 `BackBufferMixin` → two appearances, one line on text, and a `BackBuffer` object — S1

`Widget` already delegates the three things the mixin overrides: `catchesPointerAt` →
`@appearance.shapeContainsPoint` (~:547), `paintIntoAreaOrBlitFromBackBuffer` →
`@appearance?.paintIntoAreaOrBlitFromBackBuffer` (~:595), `opaqueCoveredRect` →
`@appearance?.opaqueCoveredRect()` (~:3079). Base `Appearance` answers `shapeContainsPoint` (bounds)
and `opaqueCoveredRect` (`undefined`). A palette answers through `PaletteAppearance`, a canvas
through a `CanvasAppearance extends RectangularAppearance`, a text keeps one line and no
appearance; the blit, the pixel read and the shadow twin become methods of the buffer itself, a
plain class `BackBuffer`. Detail, what is still open and the fallback: §6 S1.

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

### 5.5 `WidgetCreatorAndSmartPlacerOnClickMixin` + two of `ParentStainerMixin`'s four → `CreatorWdgt`, a shared base in `app-kit`

`CreatorButtonWdgt` and `GlassBoxTopWdgt` both extend `Widget` directly and carry the same three
mixins. `CreatorWdgt extends Widget`, in `src/app-kit/`, takes SmartPlacer's `activated` and, until
Phase 7, the pair's two other augmentations (stated once instead of twice). This is `mixins.md`'s
own rule for a single-subtree mixin. (The first analysis proposed a world service for SmartPlacer;
the shared base is smaller and keeps app-kit code in the lazy part.)
`ToolbarCreatorButtonWdgt.activated` keeps overriding without `super`.
Two rigs name this pair's consumers: `parts-snapshot-load-headless.js` reads a replayed edit of
`ParentStainerMixin._updateColor` on `CreatorButtonWdgt.prototype`, and the serialization rig's winning-donor check
overrides and removes that member on `CreatorButtonWdgt` (re-pointed, §7 table, Phase 4 row). Once `CreatorWdgt` is the
consumer the member is inherited there, so the reading still finds it — confirm with the `parts`
leg, do not assume.

### 5.6 `HighlightableMixin` + `ParentStainerMixin` → the hand knows, a widget asks as it paints — D1

No widget stores a pointer state. The hand answers `restsOn` and `pressesOn` about a widget; each
look is computed where it is painted; the hand sends one notification, `notePointerStateChanged`,
and a widget's answer to it is its whole pointer-look code outside its paint. `ParentStainerMixin`
is that answer spelled `@parent?.noteItemStateChanged?()`: `CreatorWdgt` states it once for its
pair, and `EditorContentPropertyChangerButtonWdgt` and `CodeInjectingSimpleRectangularButtonWdgt`
each state it themselves. The shape, why, and what a build must settle: §6 S2.

### 5.7 `BubblesEditModeToCoordinatorMixin` → two methods of `StretchablePanelWdgt` — S3

The relay can fire in one class only, so that class owns it; `StretchableWidgetContainerWdgt` and
`VerticalStackViewportWdgt` drop the augmentation and inherit their parents' cores. Not a copy per
consumer (§0.3 point 5). The argument, and what a build must still show: §6 S3.

### 5.8 Names (D3)

Each takes the word the tree already uses for the thing.

| Name | What it is | Why this word |
|---|---|---|
| `ClippingWdgt` | base of the seven widgets that clip their children at their bounds | the docs and comments say "clipping widget" and "clips its children" (about twenty uses); `ClippingBoxWdgt` then reads as what it is, a clipping widget with a box look |
| `RatioLockedWdgt` | base of `IconWdgt` and the two plot bases | "ratio-locked" is the tree's phrase for the behaviour, and its methods say `_constrainToRatio`; "aspect" names the protocol ("the aspect contract"), which seven classes answer, not this one answer to it |
| `ControllerWdgt` | base of the seven widgets that own wires | the wire code calls the widget that owns the wires the controller ("a controller owns a LIST of wires"); "producer", the dataflow engine's word, means any node with an out-edge — a cell, a wire record — and is wider than this class |
| `CreatorWdgt` | `app-kit` base of `CreatorButtonWdgt` and `GlassBoxTopWdgt` | both answer `createWidgetToBeHandled`; "creator" is the family's own noun ("creator buttons"), and the subclass names then say what kind of creator each is |
| `CanvasAppearance` | a canvas's appearance | the `<subject>Appearance` pattern (`PaletteAppearance`, `LabelButtonAppearance`) |
| `BackBuffer` | the buffer itself, as an object: canvas, context and shadow twin (§6 S1) | it is the thing the mixin was a kit for; a plain class, so no `Wdgt` |
| `pressesOn(aWdgt)` | the hand's second question about a widget | the pair of `restsOn(aWdgt)` |
| `notePointerStateChanged` | what the hand tells a widget whose answers may have changed | the `note…Changed` family (`noteItemStateChanged`, `noteTextChanged`, `noteWallpaperChanged`) |

---

## §6 Phase 0 — investigations

Each has three parts. The PAPER verdict was reached on 2026-11-10 by reading the source, with
nothing built or run. The MEASURED half was done on 2026-11-12 with nothing in `src/` changed:
instruments riding the suite's `--audit-prelude=` rail, and direct probes of the states no test
reaches; it confirmed or corrected the paper verdict, below and in §13. What is left is the CHANGE
under the gauntlet, which is the investigation's phase (§7) and has an accept condition here.

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
- No class below the three consumers assigns an appearance of its own (15 subclasses checked), so
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
- **The kit is the buffer.** A plain class `BackBuffer` owns the canvas, its context and its
  shadow twin, and the blit, the buffer-clamped source rectangle and the pixel read are its
  methods. A widget holds ONE field, a `BackBuffer`; `_createRefreshOrGetBackBuffer` answers one;
  the immutable-buffer cache holds them, where today it holds `[canvas, context]` pairs that every
  caller destructures. Texts sharing a buffer share its twin, and a canvas that draws on its
  raster tells its buffer the twin is stale. `CanvasWdgt.drawnRaster` goes on naming the canvas
  itself. About 140 sites in 16 files change spelling (`@backBufferContext` → the buffer's
  context); `Widget`'s transient list and `check-back-buffer-memos.js` follow the one field.

**Measured 2026-11-12 — whether `calculateKeyValues` must keep shadowing on text (nothing in
`src/` changed).** The two bodies differ in one term: the mixin clamps the width and height to the
BUFFER's size, `Widget` to the widget's (`boundingBox()` is `@bounds`). An instrument on the
suite's `--audit-prelude=` rail compared the two answers at every call of the mixin's member, and
the buffer's size with the widget's extent times the pixel ratio, over the whole suite at dpr 1 and
dpr 2 (`s1-s3-instrument.js`, output in `s1s3-dpr1/` and `s1s3-dpr2/`). Every call gave the same
answer, whoever asked — the blit, the selection overlay, an appearance — on every back-buffered
class the suite paints, texts included, and every buffer was exactly its widget's extent times the
ratio.

They can differ in ONE state, which a probe builds and no test reaches (`s1-s3-direct-probe.js`): a
one-line `StringWdgt` set to `SCALEUP`, aligned top-left, with no background and no inset, in a box
larger than its scaled text. `StringWdgt._createRefreshOrGetBackBuffer` then makes the buffer the
TEXT's size: in a 300×120 box holding a 154×116 buffer, the mixin answers 154×116 and `Widget`
300×120. (`TextWdgt`, whose default is `SCALEUP`, always makes its buffer its extent; a
`StringWdgt`'s default is `FLOAT`, which takes the whole widget.)

**Verdict.** The buffer-clamped rectangle is the BLIT's — a blit must never read past its buffer —
and moves with it into `BackBuffer`. Nothing else needs it: text does NOT keep a shadowing
`calculateKeyValues`, and the overlay and the appearances ask `Widget`'s. The one visible
consequence is decision D10 (§0.4): the selection ring of a text in that state rings its box.

25 tests paint the selection overlay of a back-buffered widget: a text in 23 of them, a palette in
`macroPaletteDragPicksCorrectColourInRotatedIsland`, a canvas in `macroDemoMenuCatalogueParade` and
`macroEveryPressIsToldItsEnding`. Phase 5 looks at those three tests' shots before it changes
anything; if none holds the ring of a palette or of a canvas, it adds that shot first.

**The change — accept when** the full gauntlet passes with ZERO reference recaptures at dpr 1,
dpr 2 and WebKit outside inspector member lists (this is a pure re-routing of the paint; the
mixin's names leave the consumers' own member lists, which R5 recaptures) — including its `vmtruth` and `serialization` legs,
which hold object lifetime and the transients — `check-back-buffer-memos.js` is re-pointed and its
bite-proof still bites, and a selected text, a selected palette and a selected canvas each paint
their selection overlay as before (the tests named above).

**Fallback, always available.** Each of the three consumers declares three one-line overrides over
the same `BackBuffer`: at most nine stubs, fewer in practice (text needs one). If the shape above fails
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

**The shape (D1): the hand knows; a widget asks as it paints.**
- *One home for the facts.* The hand already holds them, and answers two questions about a widget:
  `restsOn(aWdgt)`, which exists, and `pressesOn(aWdgt)` — the hand is non-float-dragging `aWdgt`,
  or `aWdgt` is in the press's audience AND the pointer is over it. The second half is measured,
  not assumed: a press that slides off its widget shows no pressed look today, under a mouse or a
  finger (the survey below met it on a button, a menu row and a handle), so membership of the
  audience alone is not the look. No widget stores a pointer state.
- *One home for each look.* A look is computed where it is painted — the appearance's `_fillColor`
  and its siblings, the paint-time hooks `DesktopLinkWdgt._fillForMyState`,
  `SimpleButtonWdgt._fillForMyState` and `LabelButtonAppearance` already are — from those two
  answers and the class's own row of the table above, which becomes a condition in that function
  instead of a restated hook.
- *One notification.* AFTER its own bookkeeping is written, the hand tells each widget whose
  answers may have changed: `aWdgt.notePointerStateChanged?()`. A widget's answer is its whole
  pointer-look code outside its paint: `@_changed()`, or for a toolbar tool
  `@parent?.noteItemStateChanged?()`. It is sent from every place the hand writes `mouseOverList`,
  `_pressAudience`, `nonFloatDraggedWdgt`, `pointerType` or `_pointerIsAbsent`. The existing hooks
  keep their order and their timing: this is a send added after the writes, not a reordering.
- *The five hooks keep their ACTIONS* — raising on a press, highlighting the widget a row stands
  for, a list row's selection — and lose every look.
- *Tooltips separate.* The countdown three hover implementations start by hand becomes the hand's
  business for any widget it enters that carries a `toolTipMessage`. That is behaviour-neutral
  only once the field means one thing — the tooltip shown when the pointer rests on me — and eight
  classes carry one they never show (§2.5). By D9 they stop: what they held is the NAME OF THE
  TOOL they make in a panel, a different fact, which has two readers today (`ToolPanelWdgt`, which
  hands it to the cell's `GlassBoxTopWdgt` as that top's tooltip, and the overflow chevron's row)
  and one reading, the chevron's: the tool's own word, else its colloquial name. For
  `RectangleWdgt` and `SpeechBubbleWdgt` the colloquial name already IS the word, so their line
  just goes. The six icons' colloquial names are other words — a `BrushIconWdgt` is a "brush
  icon" and its tool a "brush", a `DestroyIconWdgt` is a `"Destroy" icon` and its tool an
  "explosion" — so each of the six states its tool's word as a class-level field, `toolName`, and
  both readers ask `toolName ? colloquialName()`. No line on `Widget`. Phase 7 proves the wording
  held: every tool cell's tooltip and every overflow row, listed before and after, read the same.
- *What it deletes:* `state`, the `STATE_*` constants and their copy in `SliderButtonWdgt`;
  `_updateColor` and every colour written at a transition; `HandleWdgt`'s and
  `LayoutChromeWdgt`'s `_setPointerState`; `LabelButtonWdgt._reactToBeingCopied`, which exists to
  un-hover a copy; `DesktopLinkWdgt.pressBegan` (§2.3); the read of a child's `state` in
  `GlassBoxBottomWdgt.fillForToolState`, which asks the hand about its item instead. A saved or a
  duplicated widget no longer carries a hover it does not have.

**Why this one.** It is the tree's own rule applied to the pointer: a fact is stated once and
derived where it is used (`FrameWdgt.isInEditMode`; `ControllerMixin._isTwoWayWire`;
`PaletteWdgt.positionForColor`, "asked on every paint rather than cached"). The stored copies have
already disagreed with the hand: `../../Fizzygum-tests/DETERMINISM.md` §3n (a finger's hover look
depended on how the cycles fell, because two paths chose a look from different facts), the sweep
`_dissolveHoverStateOfTouchStroke` exists to perform, and the un-hover hook on a copied label
button. The two candidates below keep a stored copy and only reduce how often its upkeep is written.

**Not chosen.**
- *The hand tells an optional collaborator.* A widget that wants a pointer look owns a small plain
  object; the hand sends it the five facts; it keeps the state and calls the widget's one look
  hook. No line on `Widget` and no forwarding method — but a new kind of object and a field per
  widget, to hold a second copy of what the hand knows.
- *Stored once, opt-in on `Widget`.* `Widget` answers the five hooks for widgets that opt in (the
  first analysis estimated about 35 lines). The same copy, on the class the tree is shrinking.
- Not a candidate: a base class plus re-parenting. It serves `ButtonWdgt` and the app-kit pair and
  leaves `DesktopLinkWdgt`, the two icon buttons and the four hand-rolled copies where they are.

**What the change must hold to.**
- *Every write is followed by the notification.* A missed one leaves stale pixels; the paint audit,
  which holds incremental paint to a full repaint, is the gate that sees a miss. The writes, by
  method (`grep -nE "mouseOverList|_pressAudience|nonFloatDraggedWdgt *=|pointerType *=|_pointerIsAbsent *="`
  over `src/ActivePointerWdgt.coffee` and `src/WorldWdgt.coffee`):
  - `mouseOverList`: `_dispatchEventsFollowingMouseMove` (the one that matters, at its tail),
    `_dissolveHoverStateOfTouchStroke`, `_forgetGestureBookkeepingNoSettle`;
  - `_pressAudience`: `_climbPressFrom`, `_cancelPressOf`, `_endPressAt`,
    `_forgetBookingsLeavingWith`, `_forgetPressBookkeeping`;
  - `nonFloatDraggedWdgt`: `determineGrabs`, `nonFloatDragWdgtFarAwayToHere`, `processPointerUp`,
    `_forgetBookingsLeavingWith`, `_forgetPressBookkeeping`;
  - `pointerType`: `processPointerDown`, `processPointerMove`;
  - `_pointerIsAbsent`: `processPointerDown`, `processPointerMove`,
    `_dissolveHoverStateOfTouchStroke`, `_forgetGestureBookkeepingNoSettle`;
  - and from outside the hand, `WorldWdgt._softResetWorld` (`mouseOverList`,
    `nonFloatDraggedWdgt`), which becomes a call of a verb of the hand's.
- *Where a stored state carried HISTORY the hand does not,* the look changes, and only as D6–D8
  rule (the survey below lists every case). The expectation is pixel-identical EXCEPT those cases,
  and none is recaptured before it is ruled on.
- *Determinism.* Read `../../Fizzygum-tests/DETERMINISM.md` before building; prove the result with
  `fg fuzz` as well as the dpr 2 leg.

**Measured 2026-11-12 — the survey (nothing in `src/` changed).** An instrument riding the
suite's `--audit-prelude=` rail compared, at the end of every world cycle, each widget's STORED
pointer state (the `STATE_*` family's `state`; the `_setPointerState` family's two booleans) with
the state the hand's own facts give — pressed when the widget is in the press's audience or is
non-float-dragged, hovered when the pointer can rest and the over-list holds it, at rest otherwise
— over the whole suite, as a mouse (389 tests) and as a finger (374). The instrument and its
per-test output: `Fizzygum-tests/.scratch/mixin-removal-loop/investigations/` (`s2-instrument.js`,
`s2-mouse-dpr1/`, `s2-finger-dpr1/`).

The two agree in every lit state the suite shows, on 35 classes, EXCEPT these (the count is
the tests that reach the state, not the references that show it):

| What the suite reaches | Stored today | The hand's facts | Tests | Verdict |
|---|---|---|---|---|
| A list row under the pointer (`MemberRowWdgt`, a `MenuItemWdgt` list row) | at rest (its highlighted look is its list's selection; its hover is its plate, when it has one) | hovered | 32 | not history: the row's own rule, which becomes a condition where it paints |
| A press that slid off its widget, still held (a button, a menu row, a handle) | at rest | in the audience | 3 | not history once `pressesOn` asks that the pointer be over the widget (above) |
| A slider thumb, the drag just ended with the pointer on it | at rest, until the pointer next moves | hovered | 6 | HISTORY — D7 |
| A slider thumb after a click, the pointer elsewhere | hovered, until the pointer next crosses it | at rest | 2 | HISTORY — D7 |
| A handle, or a layout-chrome plate (one of them a droplet under a finger carrying a payload), under a finger | hovered | at rest (a finger rests nowhere) | 2 | HISTORY of a kind: two families that never asked `pointerCanRest()` — D8 |
| A desktop shortcut, the cycle after an error recovery emptied the over-list from outside the hand (`_softResetWorld`, §2.5) | hovered | at rest | 1 | a stale copy, gone a cycle later; the recovery's two writes move into a verb of the hand's, which tells |

What the suite never reaches, found by reading, each a stored state the pointer has since left
behind:
- *Pressed, slid off, slid back, still held.* Today the widget shows its hover look under a mouse
  and its rest look under a finger; a release there clicks it all the same (the hand clicks when
  the widget under the release is the one the press landed on). Asked at paint it shows pressed
  again. Every button family, the handles and the layout chrome. — D6
- *A label button whose release is not a click* (a hold took the stroke, or a scroll) while the
  pointer is still on it stays pressed until the pointer leaves; one `activated` by code stays
  hovered with no pointer on it. — D6
- *A slider thumb whose press is cancelled before it drags* stays pressed until the pointer
  leaves: it answers neither ending, and its hover guards ignore a move while it is pressed. — D6
- *A layout-chrome plate moved to another parent mid-press* drops its press today
  (`_reactToBeingAdded`); asked at paint it shows the press while the hand still holds it. — D6
- *A desktop shortcut pressed on its caption plate* shows no press on its tile. That needs where
  the press LANDED, which the hand holds (`mouseDownPosition`): no change in behaviour, one more
  thing the look asks the hand.

So the paper verdict holds, with one correction (`pressesOn`) and one retraction (the tooltip
bullet), and the behaviour questions it promised are D6–D9 in §0.4, decided the same day. None of D6's cases is reached
by a test, so none moves a reference; D7's and D8's are, and U8's diff page will show which
shots hold one.

**Accept when** no widget holds a pointer state, every class in §2.5 keeps only a paint-time look
and its row of the table above, and the gauntlet passes with no difference outside the ruled cases.

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

**Then, in the same phase:** the `triggeringWidget` parameter is dead
everywhere — the two Stretchables' public wrappers, the `@` the three callers above pass, and the
comments in `Widget`, `FrameWdgt` and `ViewportWdgt` that explain it. Delete it;
`buildSystem/check-call-arguments.js` holds the call sites consistent.

**What the paper verdict left to be shown** (each is answered under "Measured", below):
1. BEFORE the change, no test reaches the relay branch on a receiver that is not a
   `StretchablePanelWdgt`.
2. After the change the gauntlet passes with zero recaptures.
3. One state: `Widget`'s core returns early, before telling the bar, when `@contents` already
   holds the target mode and the receiver does not. Today the injected early call still tells the
   bar in that state. Can it arise? If it can, keep a call.

**Measured 2026-11-12 (nothing in `src/` changed).**
- *Step 1 holds, and shows more than it asked.* The instrument recorded every call of the two
  injected cores on the three consumers over the whole suite, at dpr 1 and dpr 2 (82 distinct
  facts in 23 tests; `s1-s3-instrument.js`). The relay branch never fires and the early-return
  state is never met — and the cores injected into `StretchablePanelWdgt` are never CALLED: no test
  toggles editing from a stretchable panel's own menu. So the suite cannot see the relay at all,
  and step 2's "zero recaptures" says nothing about it.
- *The relay is live, from one door.* A probe builds a slide — a `StretchableWidgetContainerWdgt`
  in a window — and calls the lock verbs as the product does (`s1-s3-direct-probe.js`). The PANEL's
  own menu verbs relay: its core hands the toggle to the container, naming itself. The container's
  verbs and the window's do not relay. Every path leaves the window's, the container's and the
  panel's modes agreeing. In that world the only direct child of a coordinator is the one
  `StretchablePanelWdgt`.
- *The bar is told two or three times a toggle today* — by the injected early call, by the core,
  and by the frame for its own verb. `showEditModeInBar` / `showViewModeInBar` are idempotent
  reflectors (their own comment), and the last telling always follows the flag: once the early
  call goes, one fewer.
- *Step 3, as measured: no path the suite or the probe took reaches the state.* ⚠ U7's review then found
  one that does, and the container KEEPS the call (§13, Phase 6): "Pick up" on a slide's page drops it on the
  desktop while the container keeps it as `@contents`; disable the page from its own menu, press the window's
  edit toggle, and `Widget`'s core writes the container's flag, finds the page already in view mode and returns
  before telling the bar. The rest of this bullet is the measurement as made: `Widget`'s core writes
  the container's flag and its contents' together; the panel's own core relays whenever its parent
  coordinates; nobody calls the panel's core naming the container; a load and a copy carry both
  flags as saved; and no call in the suite meets it. The probe makes it by writing the panel's flag
  by hand: there the early call is all that tells the bar today.

**So Phase 6 opens with a test, not with the change:** a macro test that toggles editing from a
stretchable panel's own menu inside a slide window, under both pointers, and asserts the three
modes and the bar's after each toggle — landed green on the unchanged tree. The change is then
held by it, and the accept condition is that test and the gauntlet, not the gauntlet alone.

---

## §7 Phases

Order: the base-class moves first (Phases 1–4, independent of every investigation), then the three
phases that carry an investigation's change, then the teardown. Each phase closes on `fg gauntlet`;
the ones marked ⌂ also run `fg homepage` (they touch a lazy part or the meta layer).

| Phase | What | Waits on | Expected references |
|---|---|---|---|
| 1 | Clipping → `ClippingWdgt` (§5.1) | — | pixel-identical; inspector member-list and class-chip shots move |
| 2 | KeepsRatio → base class (§5.2) | — | same |
| 3 | Controller → `ControllerWdgt` (§5.4) | — | same |
| 4 ⌂ | The app-kit pair's shared base; SmartPlacer mixin deleted (§5.5) | — | same |
| 5 | BackBuffer per S1 (§5.3) | — | pixel-identical; inspector member-list shots move |
| 6 ⌂ | A test of the relay first, then the relay into `StretchablePanelWdgt`; Bubbles and `triggeringWidget` deleted (§5.7, §6 S3) | — | pixel-identical; one new test; inspector member-list shots move |
| 7 ⌂ | Pointer state per S2; Highlightable and ParentStainer deleted — the LAST mixins (§5.6) | Phase 4 | pixel-identical outside the cases D6–D8 rule; two tests retired, two re-pointed |
| 8 ⌂ | Mechanism teardown | Phases 1–7 | inspector shots |
| 9 | Docs and close | Phase 8 | — |

**The mechanism is FROZEN from Phase 1.** No mixin feature changes while this plan runs. Its own
tests and rig checks use a mixin as their subject, so they stop being runnable phase by phase, well
before Phase 8 — the census's §1 and §4 list every one. The rule, applied in the phase that deletes
the subject: a check that exists ONLY for the mechanism is retired there; a general check that
merely uses a mixin as its example gets a new subject there, and keeps biting.

| Phase | Check whose subject this phase deletes | Do |
|---|---|---|
| 1 | `serialization-roundtrip-headless.js`, `inspector.aClassFieldRowShowsItsRecordOnlyWhileItsValueHolds` (newer than the census: three facts on the field `clipsAtRectangularBounds` the mixin donated to `VerticalStackPanelWdgt`) | retire the two donor facts (`donatedRecordShows`, `aMixinEditReadsAsItsSource`); keep the run's-write fact on the same field, now inherited from `ClippingWdgt` (`aRunsWriteOnAnInheritedFieldReadsAsItsValue`), seen failing on a plant |
| 1 | `SystemTest_macroInspectorOpensAClassInItsClassInspector` (assertion-only: `ClippingBoxWdgt`'s `__super__` row opens `BoxWdgt`'s class inspector, then its `constructor` row) | its example becomes `PointerWdgt`, the other `BoxWdgt` subclass: `ClippingWdgt`'s class inspector lists its ten members, and the `constructor` row falls below the visible list |
| 1 | `SystemTest_macroInstancesRegistry` (assertion-only: a `CanvasWdgt`'s chain of instances sets) | the chain gains `ClippingWdgt`: name it |
| 2 | `parts-lazy-load-headless.js`, the `LAZY_CONSUMER_TAKES_MIXIN_EDITS` section, with its self-test's plants and second run (subject: KeepsRatio, through the lazy `plots` part) | retire (mechanism-only) |
| 3 | `serialization-roundtrip-headless.js`, `world.inspector.classSubjectsSurviveSnapshot` (subject member: `openTargetSelector`) | drop its donor-attribution fact; point the rest at a member `SliderWdgt` owns or inherits |
| 3 | `SystemTest_macroInspectorResizingOKEvenWhenTakenApart`, `SystemTest_macroWrappingTextFieldResizesOK`, `SystemTest_macroMultilineTextInputScrollsWell` (each selects `_fireConnection`, BY NAME, in an object inspector on a `StringWdgt`; inherited from `ControllerWdgt`, it leaves the default own-members list, and the click verb throws) | new subject: `selectAll`, a member `StringWdgt` owns; the first test's two code-pane shots then show it (recaptured after looking), the other two clear the pane at once |
| 4 | `serialization-roundtrip-headless.js`, `sourceEdits.removedOverrideRestoresTheWinningDonor` (`R.winningDonorFacts` and the author page's override-then-remove of `_updateColor` on `CreatorButtonWdgt`, which no longer owns it, and which now shares ONE inherited `_updateColor` with `GlassBoxTopWdgt`, so the "edit reached it" fact would pass vacuously) | re-point at `EditorContentPropertyChangerButtonWdgt` (the same pair, the same order), compared with `CreatorWdgt`; seen failing on a plant; it still retires at Phase 7 (below) |
| 5 | `buildSystem/check-stinks.js`, the sanctioned entry naming `mixins/BackBufferMixin.coffee` / `getPixelColor` | re-point at `BackBuffer`'s file (it fails loud, `STALE_SANCTION`, if forgotten) |
| 7 | `SystemTest_macroMixinEditDonorAndOverride`, `SystemTest_macroMixinFieldEditDonorAndOverride`, and their two lines in `inspector-churn-set.json` | retire |
| 7 | `SystemTest_macroClassInspectorSaveRefusesCodeThatDoesNotCompile`, `SystemTest_macroInspectorOffersOnlyWhatItsSubjectOwns` (they assert on a member `HighlightableMixin` gives `ButtonWdgt`) | new subject |
| 7 | the serialization rig's four donor checks (`sourceEdits.removedOverrideRestoresDonor`, `…donatedRenameRoutesToDonor`, `…removedOverrideRestoresTheWinningDonor`, `…removalIsAllOrNothing`) | retire, with their names in `lib/serialization-expectations.js` |
| 7 | `sourceEdits.loadOverPageEditsIsTheFilesWorld` and its two siblings; `boot.classNamedIsTheOneDefinition` | drop their mixin steps |
| 7 | `smoke-boot-headless.js`, the three mixin verdicts (one requires `augmentations > 0`), with the plant of them in `smoke-boot-selftest-headless.js` (rule `LAZY_SOURCES_MIXINS`: `Mixin.named` answering nothing to the smoke's own reading) | retire |
| 7 | `parts-snapshot-load-headless.js`, the mixin-scope half of `SOURCE_EDITS_LOAD_THEIR_PARTS` (subject: an edit of `ParentStainerMixin._updateColor`, read on `CreatorButtonWdgt`'s live member), with the plant `NO_MIXIN_EDIT_PRELOAD` in its self-test | retire the mixin half; the class-scope half (an edit of `CreatorButtonWdgt`) stays and keeps its plant |

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
   test descriptor metadata, and apply the row of the table above for this phase. An assertion that
   spells a consumer's class chain, or opens an inspector on a consumer's superclass, moves with the
   new base: grep the tests for each consumer's name beside its old parent's.
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
  updated when the hook runs (§2.5). The look is asked at paint instead.
- **A stored pointer state, wherever it is kept** — on each widget as today, once on `Widget`, or
  in a collaborator the hand tells (D1, §6 S2). Each is a second copy of what the hand knows.
- **A remembered fact kept to reproduce a look the stored state used to give** — "this press left
  its widget once", a thumb's "not hovered until the pointer next moves" (D6, D7). It is the
  stored copy again, one case at a time.
- **An exemption letting handles and layout plates light under a finger** (D8). If a finger
  dragging a payload should be shown its drop target, that is a drop cue, for a mouse and a finger
  alike, and the drag machinery's to give — its own arc, not a hover exception.
- **Tooltips left in each family's hover hooks, or the eight name-only carriers gaining a tooltip**
  (D9).
- **The text family keeping its own `calculateKeyValues`** (D10).
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
| S1 the back buffer — paper half | Palette and canvas answer through their appearance; text keeps one line and no appearance; the rest becomes a `BackBuffer` object (D3). Open: whether text keeps the shadowing `calculateKeyValues` | 2026-11-10 | by reading; §6 S1 |
| S1 — measured half | The two `calculateKeyValues` agree on every call the suite makes, at both densities; they differ only for a bare top-left `SCALEUP` `StringWdgt` in a box larger than its text. The buffer clamp is the blit's and goes into `BackBuffer`; text keeps no shadowing member (D10). The suite already paints a selected text, palette and canvas | 2026-11-12 | instrument over the suite at dpr 1 and 2, and a direct probe; §6 S1 |
| Phase 1 — Clipping → `ClippingWdgt` | Landed as a pure move: the ten members moved verbatim into `src/basic-widgets/ClippingWdgt.coffee` (the text diff is one comment); seven consumers re-parented, `ClippingBoxWdgt` states `BoxWdgt`'s constructor; the four `PanelWdgt::….call @` borrows are `super`. The resolution map's every changed line is a spelling the compile path explains (a class member's function is named; the real `super` spells its target), each proven by undoing it and getting the old hash back. The map lists every member but constructors and statics, over the 547 classes of the dev build: `ClippingBoxWdgt`'s restated constructor, and the two descendants in the flag-gated `video-player` part (`SimpleImageWdgt`, `VideoPlayerCanvasWdgt`, which define no moved member), were checked by reading and by the independent review | 2026-11-12 | loop U2: `Fizzygum-tests/.scratch/mixin-removal-loop/u2-clipping/` (PREP.md, the map diffs, `reverse-check.py`); `fg presuite`, `fg gauntlet`, `fg homepage` (its LEDGER) |
| Phase 2 — KeepsRatio → `RatioLockedWdgt` | Landed as a pure move: the six members and the mixin's ASPECT CONTRACT header moved verbatim into `src/basic-widgets/RatioLockedWdgt.coffee` (the header gains an opening paragraph — what the class is, and its two deliberate non-subclasses — and "this mixin's" reads "mine"); `IconWdgt`, `GraphsPlotsChartsWdgt`, `PlotWithAxesWdgt` re-parented — no `super`, no shadowing, no borrow. The lazy-load rig's `LAZY_CONSUMER_TAKES_MIXIN_EDITS` retired with both its plants (mechanism-only, §7 table). The resolution map's every changed line is the class path naming a moved function, each proven by undoing it; the one change outside the map is (c) of the lookup rule above (the lazy plot bases' instance counters) | 2026-11-12 | loop U3: `Fizzygum-tests/.scratch/mixin-removal-loop/u3-ratio/`; `fg presuite`, `fg gauntlet`, `fg homepage` (its LEDGER) |
| Phase 3 — Controller → `ControllerWdgt` | Landed as a pure move: the 31 members moved verbatim into `src/basic-widgets/ControllerWdgt.coffee` (a new header says what the class is; the mixin's "ideal use of mixins" header does not move); seven consumers re-parented — none shadows a member, and BackBuffer, still augmenting `StringWdgt` and `PaletteWdgt`, shares no member name with it; `graphEdgesOut`'s `super` is real. `SliderWdgt` states `CircleBoxWdgt`'s constructor lines and `autoOrientation`, and loses its `colloquialName`, which existed only because the chain held `CircleBoxWdgt` (the derivation answers "slider"). The serialization check `world.inspector.classSubjectsSurviveSnapshot` selects a member `SliderWdgt` owns (`showAsScrollIndicator`), its two donor facts dropped (§7 table), seen failing on a plant  Three inspector tests that selected `_fireConnection` by name take `selectAll` (§7 table). The map covers the dev build's 549 classes; the four descendants in the flag-gated `video-player` part (`VideoScrubberWdgt`, `HhmmssLabelWdgt`, `VideoDurationLabelWdgt`, `VideoTimeLabelWdgt`) define none of the 31 names, checked by reading, as were the constructors. Twelve inspector tests' member-list and class-chip shots recaptured (74 shots, every one inside an inspector, looked at first), mouse and finger | 2026-11-12 | loop U4: `Fizzygum-tests/.scratch/mixin-removal-loop/u4-controller/`; `fg presuite`, `fg gauntlet`, `fg homepage` (its LEDGER) |
| Phase 4 — `CreatorWdgt`; SmartPlacer deleted | Landed: `CreatorWdgt extends Widget` (`src/app-kit/`) augments Highlightable then ParentStainer (the order that keeps ParentStainer's `_updateColor`) and owns SmartPlacer's `activated`, moved verbatim; `CreatorButtonWdgt` and `GlassBoxTopWdgt` extend it, their three augment lines gone; the SmartPlacer mixin deleted. Highlightable's emulated `pressBegan` super still reaches `Widget`'s (its companion now names `CreatorWdgt`). The resolution map changes only `activated` on the 18 classes that reach it (the class path names the moved function, proven by undoing it). Statics: `CreatorWdgt` is itself in the lazy part, defined with the two, so it copies `Widget`'s live counters and they copy those — the same values as before (lookup rule (c), corrected on review). Highlightable and ParentStainer each lose a consumer, so the save pop-up of two mixin tests counts 5 for 6 (lookup rule (d)): recaptured as D11 decided, 8 references, the moved pixels checked to be that digit and nothing more. The serialization donor check re-pointed (§7 table, Phase 4 row), seen failing on a plant. Parked on D11 from 14:20 to its decision, resumed from the kept patch | 2026-11-12 | loop U5: `Fizzygum-tests/.scratch/mixin-removal-loop/u5-creator/`; `fg presuite`, `fg gauntlet`, `fg homepage` (its LEDGER) |
| Phase 5 — the back buffer as an object | Landed as S1 designs it: `BackBufferMixin` deleted; a plain core class `src/basic-widgets/BackBuffer.coffee` owns the canvas, its context (`canvasContext`, so a copy rebuilds it by the name convention), the shadow twin, the blit with its buffer-clamped rectangle and the pixel read (bodies made from the mixin by script and diffed). A widget holds one `backBuffer`, which its `_createRefreshOrGetBackBuffer` keeps and answers; the cache holds BackBuffers; a shared one holds no widget, so where a widget meets its buffer is class-side (`blitOf`, `pixelColorOf`, `isPaintedAt`), building it after the shown check as the mixin did. `PaletteAppearance` answers paint and the per-pixel shape (`PaletteWdgt`'s re-declared paint gone); `CanvasAppearance extends RectangularAppearance` answers paint, shape and no coverage, built through `createAppearance` as `ToolPanelWdgt` builds its own; a text keeps one line. Lookup: the mixin's members leave the three consumers' prototypes, so `calculateKeyValues` and `opaqueCoveredRect` fall to `Widget`'s (D10) and `catchesPointerAt` to `Widget`'s, which asks the appearance; no `super` reached a removed member. The resolution map's every changed line explained (the palette's paint is unchanged: its deleted re-declaration was `Widget`'s very text). A test of a selected palette's and canvas's ring landed first (Fizzygum-tests `624b79d36`). Eleven inspector tests' member-list shots recaptured (66 shots, each looked at; two show the inspector's own list lifted out by the test), mouse and finger; `check-stinks`' sanction follows the pixel read to `BackBuffer.pixelColorAt` | 2026-11-12 | loop U6: `Fizzygum-tests/.scratch/mixin-removal-loop/u6-backbuffer/`; `fg presuite`, `fg gauntlet`, `fg homepage` (its LEDGER) |
| Phase 6 — the edit-mode relay into `StretchablePanelWdgt` | Landed as §6 S3 shapes it, after its test (`SystemTest_macroSlidePanelEditingToggleReachesItsWindow`, Fizzygum-tests `364e4113b`: the panel's own menu toggles the whole slide; green on the unchanged tree, mouse and finger, and failing on a plant that stops the container coordinating). `StretchablePanelWdgt` owns the two cores — the guard, the relay to a parent that coordinates, else `super()` (which reaches `Widget`'s, as the emulated one did); `StretchableWidgetContainerWdgt` and `VerticalStackViewportWdgt` drop the augmentation; the vertical stack inherits `ViewportWdgt`'s cores, and the container keeps two of its own, the mixin's body less the relay (unreachable there): its early bar call tells the window's bar in the one state `Widget`'s core returns before telling it, which U7's review found reachable (§6 S3 step 3); the panel's early call goes (the core that follows tells the bar after its flag). `triggeringWidget` is deleted: the two Stretchables' public wrappers (then `Widget`'s very text, so deleted), the `@` FrameWdgt's and ViewportWdgt's cores and `editButtonPressedFromFrameBar` passed, and the comments explaining it; the `…FromMenu` adapters it justified go too, the lock rows naming the verbs. The mixin is deleted. The resolution map's every changed line is one of those edits. One inspector test's member-list shots recaptured (`SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly`: the inherited list loses the two adapters' rows), mouse and finger | 2026-11-12 | loop U7: `Fizzygum-tests/.scratch/mixin-removal-loop/u7-relay/`; `fg presuite`, `fg gauntlet`, `fg homepage` (its LEDGER) |
| S1 — the change under the gauntlet | Held: the shape of the paper verdict landed as designed, with no stub (the fallback was not needed); no paint moved — the only recaptures are inspector member lists the mixin's names left (R5) — see Phase 5 | 2026-11-12 | loop U6 |
| S2 pointer state — paper half | A hover hook cannot ask the hand, so a look is asked at paint; the copies exist because the mixin's look hook stores a colour; the shape is D1's | 2026-11-10 | by reading; §2.5, §6 S2 |
| S2 — measured half | Stored state and the hand's facts agree in every lit state the suite shows (35 classes, mouse and finger) but six cases, of which two are the classes' own rules and one a stale copy; `pressesOn` must ask that the pointer be over the widget; the tooltip bullet as first written would have given eight classes a tooltip. Questions D6–D9 | 2026-11-12 | instrument over the suite as a mouse and as a finger, and reading; §2.5, §6 S2 |
| S2 — the change under the gauntlet | — (Phase 7) | | |
| S3 the edit-mode relay — paper half | Live in `StretchablePanelWdgt` only: it keeps the two cores, the other two consumers inherit, and `triggeringWidget` can go | 2026-11-10 | by reading; §6 S3 |
| S3 — measured half | The relay is live from one door, a stretchable panel's own menu, which no test opens; the early-return state is reached by no product path; the bar is told two or three times a toggle today. Phase 6 opens with a test | 2026-11-12 | instrument over the suite at dpr 1 and 2, and a direct probe; §6 S3 |
| S3 — the change under the gauntlet | Held: the relay lives in `StretchablePanelWdgt` alone, as the shape says; step 3's state proved reachable, so the container keeps its early bar call (Phase 6); the test that opens Phase 6 holds it (and fails on a plant that stops the container coordinating) — see Phase 6 | 2026-11-12 | loop U7 |
| Teardown census (Phase 8's input) | 61 files classified; checks break in the phase that deletes their subject, so the mechanism is frozen and pointer state goes last | 2026-11-10 | by reading; `docs/measurements/mixin-teardown-census-2026-11-10.md` |
| D1 pointer-state shape | the hand knows, a widget asks as it paints (§6 S2) | 2026-11-10 | owner, confirming the recommendation made on their criterion (cleanliness and orthogonality, whatever the churn) |
| D2 Controller: base class or collaborator | base class | 2026-11-10 | owner |
| D3 names | the table of §5.8, `BackBuffer` as an object included | 2026-11-10 | owner, confirming the recommendation, same criterion |
| D4 inspector loses the donor vocabulary | accepted | 2026-11-10 | owner |
| D5 coupling with the talk | the talk plan drops mixins (its D7) | 2026-11-10 | owner |
| Baseline re-check | The §2.4 scan unchanged in structure; counts and line hints corrected; three rig files newer than the census, their checks added to §7's table; the churn set and the four mixin-dependent tests as recorded | 2026-11-12 | §2, §7; `investigations/scan-2026-11-12.txt` |
| D6 pointer looks where a stored state lagged | the look follows the pointer; nothing remembered | 2026-11-12 | owner, choosing the recommended option of two |
| D7 the slider thumb | the rule every button follows | 2026-11-12 | owner, the recommended option of two |
| D8 a finger over handles and layout chrome | one rule, no hover under a finger; not the exemption, and not a drop cue filed apart | 2026-11-12 | owner, the recommended option of three |
| D9 the eight name-only tooltip carriers | no widget gains a tooltip; the tool's name is stated apart (`toolName`, §6 S2) | 2026-11-12 | owner, the recommended option of three |
| D10 the ring of a text smaller than its box | it rings the box | 2026-11-12 | owner, the recommended option of two |
| D11 Phase 4's one-digit change in the mixin save pop-up | A: recapture the two shots (`SystemTest_macroMixinEditDonorAndOverride`, `SystemTest_macroMixinFieldEditDonorAndOverride` image_2, mouse and finger, dpr 1 and 2); Phase 4 lands as §5.5 designs it | 2026-11-12 | owner, the recommended option of two |

---

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] §0.4: owner decisions D1 (pointer-state shape, three candidates), D3 (class names), D4 (the inspector's donor vocabulary) — all three made by the owner on 2026-11-10, as §13 records: D1, the hand knows and a widget asks as it paints; D3, the names of §5.8; D4, accepted.
- [x] §6 S1: the back buffer as a `BackBuffer` object — empirical half (a build and a gauntlet on the paper verdict); open: whether text keeps the shadowing `calculateKeyValues` — CLOSED 2026-11-12 as an item: its measured half is done (§6 S1, §13: the two `calculateKeyValues` agree on every call the suite makes at both densities, and text keeps no shadowing member), and what it still owed, the change under the gauntlet, is the Phase 5 line's.
- [x] §6 S2: pointer state asked of the hand at paint — empirical half: every write of the hand's facts followed by the notification, and each case where a stored state carried history put to the owner — CLOSED 2026-11-12 as an item: the cases are measured and put to the owner as D6–D9 (§0.4, §6 S2), the writes outside the hand are listed (§2.5), and the change under the gauntlet is the Phase 7 line's.
- [x] §6 S3: the edit-mode relay into `StretchablePanelWdgt` — empirical half — CLOSED 2026-11-12 as an item: its measured half is done (§6 S3: the relay is live from one door, which no test opens; the early-return state is reached by no product path), and the change, opened by a test of the relay, is the Phase 6 line's.
- [x] §0.4: owner decisions D6–D9 (pointer looks that follow the pointer where a stored state lagged it; the slider thumb; a finger's hover on handles and layout chrome; the eight classes carrying a tooltip they never show) and D10 (the selection ring of a text smaller than its box) — each with a recommendation; Phase 7 waits on D6–D9, Phase 5 on D10 — CLOSED 2026-11-12: the owner chose the recommended option of each ("All A"), as §0.4 and §13 record; no phase waits on the owner.
- [x] §7 Phase 1: Clipping → `ClippingWdgt` — CLOSED 2026-11-12 (loop). The ten members moved verbatim into the core base class `ClippingWdgt` (`src/basic-widgets/`), the seven consumers re-parented (`ClippingBoxWdgt` states `BoxWdgt`'s constructor), the four `PanelWdgt::….call @` borrows became `super`, the mixin file deleted. Proven by the resolution map over the dev build's 547 classes (every changed line explained and hash-proven; constructors, statics and the flag-gated video-player part checked by reading), the presuite, the gauntlet and `fg homepage`; one serialization fact re-pointed onto the inherited field and seen failing on a plant, two donor facts retired (§7 table, Phase 1 rows).
- [x] §7 Phase 2: KeepsRatio → `RatioLockedWdgt` — CLOSED 2026-11-12 (loop). The six members and the aspect-contract header moved verbatim into the core base class `RatioLockedWdgt` (`src/basic-widgets/`); `IconWdgt` and the two plot bases re-parented; the mixin file deleted; `parts-lazy-load-headless.js`'s `LAZY_CONSUMER_TAKES_MIXIN_EDITS` retired with its two plants (§7 table). Proven by the resolution map (every changed line explained and hash-proven), the presuite, the gauntlet and `fg homepage`.
- [x] §7 Phase 3: Controller → `ControllerWdgt` — CLOSED 2026-11-12 (loop). The 31 members moved verbatim into the core base class `ControllerWdgt` (`src/basic-widgets/`); `SliderWdgt`, `StringWdgt`, `PaletteWdgt`, `ColorPickerWdgt`, `FanoutWdgt`, `FanoutPinWdgt`, `PatchNodeWdgt` re-parented (`SliderWdgt` states `CircleBoxWdgt`'s part and drops its now-redundant `colloquialName`); the mixin file deleted; the serialization check re-pointed at an owned member (§7 table). Proven by the resolution map, the presuite, the gauntlet and `fg homepage`.
- [x] §7 Phase 4: the app-kit pair's shared base `CreatorWdgt`; the SmartPlacer mixin deleted — CLOSED 2026-11-12 (loop). `CreatorWdgt` (`src/app-kit/`) carries SmartPlacer's `activated` and states the pair's Highlightable and ParentStainer augmentations once; `CreatorButtonWdgt` and `GlassBoxTopWdgt` extend it; the serialization donor check re-pointed at `EditorContentPropertyChangerButtonWdgt` (§7 table); the two mixin tests' save pop-up count recaptured as D11 decided. Proven by the resolution map, the presuite, the gauntlet (its `parts` leg confirms the replayed ParentStainer edit on `CreatorButtonWdgt`) and `fg homepage`.
- [x] §7 Phase 5: the back buffer as two appearances, one line on text and a `BackBuffer` object — CLOSED 2026-11-12 (loop). `BackBufferMixin` deleted; the plain core class `BackBuffer` (`src/basic-widgets/`) owns the canvas, its context, the shadow twin, the blit and the pixel read; `PaletteAppearance` and a new `CanvasAppearance` answer paint, shape and coverage, a text keeps one line; `getPixelColor` is `BackBuffer.pixelColorOf`. A ring test landed first. Proven by the resolution map, the presuite, the gauntlet and `fg homepage`.
- [x] §7 Phase 6: a test of the edit-mode relay, then the relay into `StretchablePanelWdgt`; Bubbles and `triggeringWidget` deleted — CLOSED 2026-11-12 (loop). The test landed first (Fizzygum-tests `364e4113b`); `StretchablePanelWdgt` owns the two cores, the vertical stack inherits `ViewportWdgt`'s, the container keeps its early bar call for a reachable state; `triggeringWidget` and the `…FromMenu` adapters are gone; the mixin file deleted. Proven by the new test, the resolution map, the presuite, the gauntlet and `fg homepage`.
- [x] §0.4 D11 (OWNER, OPEN 2026-11-12): may Phase 4 recapture the one-digit change ("6 consumer classes" → "5") in two mixin tests' save pop-up — recommendation A; Phase 4 is parked on it, its patch kept — CLOSED 2026-11-12 (owner): A, recapture the two shots; Phase 4 resumes from its patch.

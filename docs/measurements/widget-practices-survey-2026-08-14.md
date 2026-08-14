# Widget practices survey — 2026-08-14

**What this is.** A dated, mechanical snapshot of *how the 270 widget classes in `src/` are actually
written*, facet by facet. It answers one question per facet — "when a widget has to do X, how many
different ways does the tree do it?" — with counts, the full or exemplary class lists, and a verdict.

**What this is NOT.** It is not a plan and not a backlog. Per the census convention
(`docs/architecture/lint-and-static-checks.md` §3c) **a finding here is a question, not an
instruction**: several of the divergences below are principled, and at least one "obvious cleanup"
in an earlier census round would have broken the product. Acting on anything here is a separate,
verified arc with its own plan doc. The companion prescriptive doc — what a *new* widget should do —
is [`../architecture/widget-authoring-guidelines.md`](../architecture/widget-authoring-guidelines.md).

**Provenance.** Measured 2026-08-14 against `src/` at `21d5b64`, by static scan of the CoffeeScript
sources plus the repo's own tools (`buildSystem/census-*.js`, `check-stinks.js`,
`check-call-separation.js`). Reproduction commands are in §12. Counting is line/regex-based on class
bodies, so it shares the blind spots of every scanner here: dynamic dispatch is invisible, `super`
is meta-compiled, and property access is partly dynamic (§12).

---

## 1. The population

| | count |
|---|---|
| classes in `src/` | 482 |
| **`Widget` descendants (this survey's population)** | **270** |
| `Appearance` descendants | 112 |
| `InputEvent` descendants | 19 |
| `LayoutSpec` descendants | 5 |
| widget source lines | 31,124 |
| median widget class | 25 lines |
| mean widget class | 115 lines |
| widget classes under 30 lines | 147 (54%) |

Method tiers across the 270 (`docs/architecture/layering-naming-convention.md` §1):

| tier | methods | share |
|---|---|---|
| public `name` | 1,494 | 70% |
| internal `_name` | 632 | 30% |
| leaf `__name` | 15 | 0.7% |

The distribution is extremely top-heavy. Ten classes carry a third of all widget source:

`Widget` 5,286 · `WorldWdgt` 2,999 · `StringWdgt` 1,622 · `ActivePointerWdgt` 1,192 ·
`FrameWdgt` 1,165 · `SimpleSpreadsheetWdgt` 926 · `ScrollPanelWdgt` 894 ·
`TransformFrameWdgt` 744 · `InspectorWdgt` 721 · `TextWdgt` 718.

`Widget` alone declares 228 public methods (417 members). Everything below has to be read against
that fact: most "widget practice" is really *base-class practice*, inherited by 269 classes that
never restate it.

The big sub-families (descendant counts, transitive):

| base | descendants | character |
|---|---|---|
| `IconWdgt` | 83 | leaf shape classes; 67 of them are **two methods long** (`colloquialName` + `createAppearance`) |
| `PanelWdgt` | 31 | clipping containers |
| `CreatorButtonWdgt` | 24 | drag-to-create palette thumbnails |
| `ButtonWdgt` | 13 | pressable things |
| `ScrollPanelWdgt` | 12 | scroll frames + toolbars |
| `FrameWdgt` | 11 | window/card chrome |
| `StringWdgt` | 8 | text |
| `PopUpWdgt` | 6 | menus + prompts |

**Consequence for reading this survey:** an "N/270" ratio is usually misleading on its own, because
more than half the population is small shape/creator leaves that legitimately have no constructor, no
layout, no input and no menu — 147 widget classes are under 30 lines, and 67 icon classes are
literally two methods long. Where it matters, the denominator below is narrowed to the classes for
which the facet is a live question.

---

## 2. Identity and file shape

### F1 — Class naming · **CONVERGED (3 stragglers)**

266 of 270 end in `Wdgt`. The exceptions are `FrameContentsPlaceholderText`, `MenuHeader`,
`VideoPlayPauseToggle` (plus the root `Widget` itself, which is correct). One class per file, and
filename == class name, holds at 100% — the build keys off it.

The `*Morph` → `*Wdgt` migration named in `CLAUDE.md` is **complete in `src/`**: zero `*Morph`
classes remain.

### F2 — The `Simple*` prefix carries two unrelated meanings · **PATCHWORK (naming)**

17 classes start with `Simple`. The frame model
([`../architecture/regularity-principles.md`](../architecture/regularity-principles.md)) reserves
`Simple*Wdgt` for **"naked capability — data plus a self-mutation API, no chrome"**. Some classes use
it that way; others use it as a plain English "the basic one":

| reading | classes |
|---|---|
| frame-model *naked capability* | `SimpleTextWdgt`, `SimpleSpreadsheetWdgt`, `SimpleImageWdgt`, `SimpleDropletWdgt`, `SimpleLinkWdgt`, `SimpleVideoLinkWdgt`, `SimpleTextPanelWdgt`, `SimpleTextScrollPanelWdgt`, `SimpleDocumentScrollPanelWdgt` |
| plain "basic variant of" | `SimpleButtonWdgt`, `SimpleRectangularButtonWdgt`, `SimpleRasterImageButtonWdgt`, `SimpleVerticalStackPanelWdgt`, `SimpleVerticalStackScrollPanelWdgt`, `SimpleSlideIconWdgt`, `SimpleUSAMapIconWdgt`, `SimpleWorldMapIconWdgt` |

A reader cannot tell from the name alone which axis it serves — the exact failure mode
`regularity-principles.md` rule 2 exists to prevent. (`SimpleVerticalStackPanelWdgt` is the sharpest
case: it is a full container with layout knobs, not a naked payload.)

### F3 — Header comment on the class file · **THIN (45%)**

122 of 270 files open with a comment saying what the class is. The gap is concentrated where a family
convention makes it *look* redundant:

| directory | files with no header |
|---|---|
| `authoring/` | 27 |
| `authoring-icons/` | 23 |
| `demos-icons/` | 19 |
| `icons/` | 17 |
| root `src/` | 13 |
| `graphs-plots-charts/` | 12 |
| everything else | 17 |

For an icon leaf whose entire body is `colloquialName` + `createAppearance`, the absence is defensible.
For a substantial class it is not, and plenty of substantial classes open straight into `class …`:
`AnalogClockWdgt`, `FridgeMagnetsWdgt`, `FolderWindowWdgt`, `ClassInspectorWdgt`, `EditableMarkWdgt`,
`FanoutWdgt`, `CreatorButtonWdgt`, `Example3DPlotWdgt`.

Where headers exist, the best of them are *family instructions*, not descriptions — `IconButtonWdgt`
lists exactly which four members a subclass supplies, and `ToolbarWdgt` explains why one construction
serves both the floating and the docked home. That shape is the one worth copying.

Comment density spans two orders of magnitude: `TrackingTransformFrameWdgt` 156 comment lines / 208
code lines, `ExamplesFolderWindowWdgt` 84/106, against `WelcomeMessageInfoWdgt` 0/71,
`RegexSubstitutionPatchNodeWdgt` 9/73, `FanoutWdgt` 10/70.

---

## 3. Construction

131 of 270 widgets define a constructor. This is the single most divergent facet in the tree.

### F4 — Constructor parameter shape · **PATCHWORK, with a live migration**

Only **4** widgets take an options object at all — `FrameWdgt`, `MenuWdgt`, `MenuRowsPanelWdgt`,
`SliderWdgt` — and each of those still leads with one to four positional slots. Every other
constructor is positional-only, up to seventeen slots deep. Counting slots (an `opts = {}` trailer
counts as one):

| slots | classes | examples |
|---|---|---|
| 0 | 35 | `ToolbarWdgt`, `CanvasWdgt`, `SimpleButtonWdgt`, … |
| 1–3 | 75 | the norm — `BoxWdgt`, `HandleWdgt`, `InspectorWdgt`, `FrameWdgt`, `MenuWdgt`, … |
| 4–8 | 18 | `SimpleTextWdgt` (8), `TextWdgt` (8), `StringFieldWdgt` (7), `ListWdgt` (6), `SliderWdgt` (5) |
| **9+** | **3** | `LabelButtonWdgt` (**17**), `ButtonWdgt` (**12**), `NumberPromptWdgt` (9) |

`SliderWdgt`'s header records the reasoning that produced the mixed form — positional for the four
numbers that are a natural ordered tuple *and* a user-typed spelling in spreadsheet formulas, an
options object for the two flag-ish knobs whose callers wanted disjoint tails. That is a stated
criterion, not a coin-flip, and it is the only place in the tree where the choice is argued.

The 12- and 17-slot constructors are the scars: `LabelButtonWdgt` takes
`ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, labelString, fontSize, fontStyle,
centered, environment, widgetEnv, toolTipMessage, color, bold, italic, doubleClickAction,
argumentToAction1, argumentToAction2, representsAWidget` — every caller wanting the last one must
type sixteen holes. Note that the *menu-item* API next door already solved exactly this problem:
`addMenuItem label, target, action, opts` (§8, F20) is options-object and has 326 call sites.

### F5 — The `@param` shadowing hazard, and its cost · **3 workaround fields**

`CLAUDE.md` documents the law: a CoffeeScript `@param` in a constructor signature assigns the field
**unconditionally**, so it shadows the class-level default whether or not the parameter has one.

Three classes pay for it with a *parallel shadow field* rather than a guarded assignment:
`IconButtonWdgt`, `CreatorButtonWdgt` and `EditorContentPropertyChangerButtonWdgt` each declare
`iconToolTipMessage` and copy it into `@toolTipMessage` after `super`, because `ButtonWdgt`'s
constructor takes `@toolTipMessage` as a parameter defaulting back to `undefined` and would clobber
a prototype override. `IconButtonWdgt` says so explicitly in a comment.

The guarded-assignment alternative already exists in the tree and is the documented pattern —
`StringWdgt`'s `@backgroundColor = backgroundColor if backgroundColor?` (`StringWdgt.coffee:216`) and
`RectangleWdgt`'s `@color = color if color?` (`RectangleWdgt.coffee:18`).

### F6 — Where `super` sits · **CONVERGED for 99, long tail of 32**

| position of `super` in the constructor | count |
|---|---|
| first statement | 99 |
| after 1–3 statements | 14 |
| after 4–9 statements | 14 |
| after 11–18 statements | 4 — `ListWdgt` 11, `ButtonWdgt` 13, `StringWdgt` 16, `LabelButtonWdgt` 18 |

Some pre-`super` work is required and reasoned: `SliderWdgt` assigns its two option-object knobs
before `super()` "preserving the order the all-`@param` form compiled to"; `AnalogClockWdgt` sets
`@fps` and joins `world.steppingWdgts` first; `HandleWdgt` seeds a default `@inset` the corner spec
then reads. The 11-to-18-statement cases are simply large parameter-normalisation preambles.

### F7 — Setting the initial extent in a constructor · **PATCHWORK (5 different verbs)**

23 constructors size themselves, through five different tiers of the geometry-apply 2×2:

| verb | tier | count | classes |
|---|---|---|---|
| `@_applyExtent` | `_` polymorphic, reacts | 9 | `AnalogClockWdgt`, `BouncerWdgt`, `ColorPickerWdgt`, `Example3DPlotWdgt`, `FrameWdgt`, `GraphsPlotsChartsWdgt`, `PenWdgt`, `SaveShortcutPromptWdgt`, `SimpleSpreadsheetWdgt` |
| `@__commitExtent` | `__` silent leaf | 8 | `CircleBoxWdgt`, `InspectorWdgt`, `ModifiedTextTriangleAnnotationWdgt`, `PaletteWdgt`, `RectangleWdgt`, `SimpleVerticalStackPanelWdgt`, `SliderWdgt`, `UpperRightTriangleWdgt` |
| `@_commitBounds` | `_` silent | 3 | `ActivePointerWdgt`, `SimpleTextWdgt`, `Widget` |
| `@setExtent` | public, settles | 2 | `FrameWdgt`, `FolderWindowWdgt` |
| `@setBounds` | public, settles | 1 | `WorldWdgt` |

The public-setter cases are *deliberate and documented*: `FrameWdgt` explains that its trailing
`setExtent` is the constructor's last act precisely so `new FrameWdgt` returns **settled** (the
orphan-settledness contract), and that folding it into the shared build core would reset a
user-resized window. The `__commitExtent` vs `_applyExtent` split, by contrast, carries no stated
criterion anywhere — the two differ in whether the write repaints and re-lays the widget's own
content, which matters for a class that has content at that point and not otherwise.

### F8 — Building children · **CONVERGED (gate-enforced), with a named-variant tail**

`buildSystem/check-constructors-build.js` forbids a constructor from adding its own children inline;
the child-building belongs in `_buildAndConnectChildrenNoSettle`, reached via a settling wrapper.

| | count |
|---|---|
| classes defining `_buildAndConnectChildren` (wrapper) | 31 |
| …whose body is **exactly** `@_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()` | **31 / 31** |
| classes defining `_buildAndConnectChildrenNoSettle` (core) | 38 |
| cores with no local wrapper (inherit one) | 10 |
| wrappers with no local core (subclass supplies it) | 3 |
| constructors reaching a **differently named** builder | 5 |
| `# constructor-build-exempt:` markers in the tree | 0 |

This is the healthiest facet in the survey, and it is healthy *because a gate holds it*. The five
differently-named builders are each documented as deliberate: `ScrollPanelWdgt._buildScrollFrame` and
`MenuRowsPanelWdgt._buildMenuLabel` use distinct names so the base constructor does not dispatch into
a subclass override during `super()` (CoffeeScript binds a subclass's constructor parameters only
*after* `super()`); `SimpleSpreadsheetWdgt._buildChromeNoSettle` and the two
`_makeStartingPayload`s (`DocumentWdgt`, `GenericPanelWdgt`) name a different job.

`PromptWdgt` records the same constraint from the other side: it deliberately does **not** call
`@_buildAndConnectChildren()` in its own constructor, leaving each subclass to call it after `super`
so the editor-row hook sees its bound parameters.

---

## 4. State, fields and the graph engines

### F9 — Declaring instance fields at class level · **PATCHWORK (58% complete)**

The duplicator walks **own enumerable properties**; the shell is `Object.create(prototype)`, so a
prototype declaration is what makes a lazily-initialised field visible to duplication, serialization
and the inspector. `ColorPickerWdgt` states the rule in a comment: *"declare every child field here
(not only set in the constructor) so the Duplicator's walk picks it up even under lazy
initialisation."* `PromptWdgt` and `StringFieldWdgt` repeat it.

Measured over the 136 widgets that assign at least one own field (declaration searched across the
whole ancestor chain **and** applied mixins):

| | count |
|---|---|
| every assigned field declared somewhere in the chain | **79** |
| at least one undeclared assigned field | **57** |
| undeclared field assignments in total | **135** |

Worst offenders (undeclared count): `WorldWdgt` 17, `SimpleSpreadsheetWdgt` 16, `CellWdgt` 7,
`FrameWdgt` 6, `IconicDesktopSystemWindowedAppLauncherWdgt` 4, `SheetHeaderCellWdgt` 4,
`FridgeMagnetsWdgt` 4, `SpeechBubbleWdgt` 4.

Note the shape of the misses: `target`/`title`/`icon`/`callback` are undeclared in all four
`IconicDesktopSystem*ShortcutWdgt` classes even though they are pure constructor `@param`s — i.e. the
convention is *understood* in the classes that wrote it down and simply unknown elsewhere. The
project's own census warns that the converse cleanup (demoting a write-only field) is a false-positive
factory, so this facet is safe only in the *declare more* direction.

### F10 — Serialization / duplication declarations · **THIN, and demonstrably load-bearing**

| declaration | widget classes |
|---|---|
| `@serializationTransients` | 9 — `Widget`, `PopUpWdgt`, `CellWdgt`, `SheetHeaderCellWdgt`, `SimpleSpreadsheetWdgt`, `TransformFrameWdgt`, `CalculatingPatchNodeWdgt`, `ScriptWdgt`, `FridgeMagnets3DCanvasWdgt` |
| `_reactToBeingCopied` (post-duplicate fixup) | 3 — `SimpleSpreadsheetWdgt`, `LabelButtonWdgt`, `TransformFrameWdgt` |
| `_afterDeserialization` (post-restore fixup) | 2 — `SimpleSpreadsheetWdgt` (+ `SheetCellRecord`) |
| `keptByReferenceOnDeepCopy` | 0 widgets (it is for value classes and world singletons) |

Nine declarers is not obviously too few — most widgets genuinely hold no derived state. But the
reference doc records that `CalculatingPatchNodeWdgt.functionFromCompiledCode` was *documented as the
canonical example while never actually being declared*, and every snapshot containing a
patch-programming window crashed until it was. The failure mode is silent until someone saves a world
containing the widget, and the only gate that can catch it is the production smoke's snapshot
round-trip.

Standing ban, recorded in the same doc and worth restating because it is invisible to every scanner:
**instance-assigned handler functions are not a state idiom.** A mode a widget can be in is a
serializable field consumed by prototype methods, never a pair of own function properties installed
by an `enable*` call.

---

## 5. Appearance and painting

### F11 — How a widget gets its `*Appearance` · **TWO IDIOMS, one clearly better**

| idiom | count | who |
|---|---|---|
| **`createAppearance: -> new FooAppearance @`** overridable factory | **109** | the whole `IconWdgt` family (83) + `CreatorButtonWdgt`/`IconButtonWdgt` families |
| `@appearance = new FooAppearance @` in the constructor body | 32 | `PanelWdgt`, `BoxWdgt`, `RectangleWdgt`, `HandleWdgt`, `WorldWdgt`, `AnalogClockWdgt`, … |
| inherit whatever the base wired | 129 | most leaves |

The factory-method form is the better one and `IconWdgt` says why in a comment: *"a method, not a class
field, so the build's dependency-finder still sees the `new <X>IconAppearance` edge and orders the
appearance before the icon"* — and, unstated but equally true, it gives every subclass a one-line
override point (`HeartIconWdgt`'s entire body is `colloquialName` + `createAppearance`).

Two classes swap appearance at runtime rather than at construction, both legitimately:
`FrameWdgt._deriveAndSetBodyAppearance` (rectangular vs boxy by parentage) and
`EditIconButtonWdgt` (pencil vs eye by edit mode) — the "skin swap never changes identity" principle
in action.

Cosmetic tail: `new FooAppearance @` (paren-free, 31 sites) vs `new CircleBoxyAppearance(@)` (1 site,
`CircleBoxWdgt`).

### F12 — Where hit-testing lives · **SPLIT (7 widget-side vs 5 appearance-side), rule unstated**

`isTransparentAt` is implemented **7 times on widgets** (`Widget`, `FrameBarWdgt`, `MenuWdgt`,
`PromptWdgt`, `SimpleImageWdgt`, `TransformFrameWdgt`, `VideoPlayerCanvasWdgt`) and **5 times on
appearances** (`Appearance`, `RectangularAppearance`, `BoxyAppearance`, `CircleBoxyAppearance`,
`UpperRightTriangleAppearance`). The base `Widget` delegates to its appearance, so both are reachable;
the split means "is this pixel mine?" is answered on the shape side for shape-driven widgets and on
the widget side for content-driven ones. Defensible, but nothing states the rule.

---

## 6. Layout participation

### F13 — The shape of a `_reLayout` override · **TWO IDIOMS + a copy-pasted prologue**

39 classes define `_reLayout`. They fall into two clean groups plus six others:

| shape | count |
|---|---|
| **A — own prologue, then `super`, then `@_markLayoutAsFixed()`** | 24 |
| **B — `super` first, then `@_reLayoutChildren()`** | 9 |
| neither (no prologue, trailing `super`) | 3 (`VideoControlsPaneWdgt`, `VideoPlayerWdgt`, `VideoPlayerWithRecommendationsWdgt`) |
| no `super` at all | 2 (`CaretWdgt`, `LabelButtonWdgt`) |
| the base itself | 1 (`Widget`) |

Shape A's prologue is six lines repeated verbatim 24 times:

```coffee
newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout
if @_handleCollapsedStateShouldWeReturn() then return
@_applyGrantedBounds newBoundsForThisLayout      # bounds FIRST — gated
…own child placement…
super
@_markLayoutAsFixed()
```

The bounds-first half is *required* and gated (`check-relayout-bounds-first.js`, born from the
`InspectorWdgt` one-cadence-lag bug), and several classes carry the same explanatory comment
near-verbatim (`ButtonWdgt`, `ColorPickerWdgt`, `PatchNodeWdgt` all say "do NOT defer this to the
trailing super"). One class has already factored the variable part behind a hook —
`PatchNodeWdgt._layOutNodeContents` — which is the shape the other 23 are implicitly asking for.

Shape B is the *container* shape and is exactly the set flagged in F14.

### F14 — `_reLayoutChildren`, the size-tracking-container marker · **CONVERGED**

`docs/architecture/layout.md` §2.4 states the invariant: *"`_reLayoutChildren` is defined by every
size-tracking container and nothing else."* Measured: 10 definers — `SimpleVerticalStackPanelWdgt`,
`ScrollPanelWdgt`, `FrameWdgt`, `FrameBarWdgt`, `TrackingTransformFrameWdgt`, the four size-tracking
menu-row widgets (`SliderWdgt`, `StringFieldWdgt`, `ColorPickerWdgt`, `MenuHeader`), and
`PaintToolbarWdgt`, which the doc's enumeration does not name but which is the same kind of thing (a
docked toolbar slot driving its chrome synchronously, in its own words "the `FrameBarWdgt` pattern").
The doc's list is one entry short; the invariant itself holds.

This is the survey's best example of a facet that *was* patchwork and got converged by a named arc:
each of the four menu-row widgets carries a comment recording that its bespoke `_applyExtent` /
`_applyWidth` hook was replaced by conforming to the engine's child contract.

### F15 — Pure measure and the sizing protocol · **CONVERGED where it applies**

| method | definers |
|---|---|
| `preferredExtentForWidth` (side-effect-free measure) | 12 — `Widget`, `TextWdgt`, `SimpleVerticalStackPanelWdgt`, `FrameWdgt`, `AnalogClockWdgt`, `MenuRowsPanelWdgt`, `TransformFrameWdgt`, `TrackingTransformFrameWdgt`, `StretchableWidgetContainerWdgt`, `Example3DPlotWdgt`, `GenericCompositeIconWdgt`, `WidgetHolderWithCaptionWdgt` |
| `_setWidthSizeHeightAccordingly` (width→height, hands the height back) | 7 |
| `initialiseDefault*LayoutSpec` overrides | 15 |
| `_reLayoutSelf` (self-only heal) | 7 |
| `_applyExtentBase` / `_applyExtent` overrides | 2 / 5 |

The measure/apply separation holds: no widget reads back applied geometry to decide a size, and the
one sanctioned applied read-back (`subWidgetsMergedFullBounds` on the folder/toolbar frame) is
singular and documented as such.

### F16 — Settle tiers · **CONVERGED, gate-held**

60 of 270 widget classes define at least one `_<name>NoSettle` core. `check-thin-wraps.js` requires
every public twin to be the mechanical one-line wrap, `check-call-separation.js` reports **0
unsanctioned private→public-command self-calls** (27 sanctioned), and `check-layering.js` rules
[A]–[T] hold the flow. This is the most thoroughly enforced area of widget practice in the codebase
and shows essentially no divergence.

---

## 7. Invalidation and repaint

### F17 — Self-invalidation · **CONVERGED, gate-held**

Widget-citizenship point 2 — a widget invalidates only itself — is enforced by
`check-invalidation-receivers.js`: no `<expr>._changed()` on another widget, singletons included.

| | count |
|---|---|
| widget classes calling `@_changed()` | 31 |
| widget classes calling `@_fullChanged()` | 6 |
| widget classes using `@_repaintAsOneUnit` | 28 |
| sanctioned cross-invalidation sites tree-wide | 9 |

The ratio is the interesting number: `_changed` (self only) outnumbers `_fullChanged` (self +
subtree) five to one, which is the correct direction — a subtree repaint is the expensive answer.

---

## 8. Input, menus, self-description

### F18 — Input handlers · **CONVERGED in form, sparse in coverage**

43 widget classes define at least one pointer handler.

| handler | definers |
|---|---|
| `mouseClickLeft` | 34 |
| `mouseDownLeft` | 11 |
| `mouseLeave` / `mouseEnter` | 8 / 7 |
| `nonFloatDragging` | 4 |
| `mouseUpLeft` / `mouseDoubleClick` / `mouseMove` | 3 / 3 / 3 |
| `wheel` / `mouseTripleClick` | 2 / 2 |
| `processKeyDown` | 3 |
| `escalateEvent` (pass the event to the parent) | 14 files |
| `excludedFromEditorFocusTracking` (chrome opt-out) | 12 |

Two conventions hold, each because something holds it:

- **Handlers consume the plane-mapped `pos` parameter**, never the raw `world.hand.position()` — held
  by `check-raw-pointer-reads.js`, currently at **zero** sanctioned sites. The one deliberate
  raw-screen read (`HandleWdgt._pointerAngleToTargetAnchorDegrees`, whose angle must be measured in
  the screen plane and not in the plane it is rotating) sits in a *helper*, which the gate's heuristic
  does not scan, and carries a paragraph explaining itself.
- **Hover/press colour feedback comes from `HighlightableMixin`** (`color_normal` / `color_hover` /
  `color_pressed`) rather than per-class ad-hoc colouring — 7 consumers. `HandleWdgt` is the one class
  that hand-rolls a two-state version of the same thing (`STATE_NORMAL` / `STATE_HIGHLIGHTED` +
  `mouseEnter`/`mouseLeave` marking itself changed).

### F19 — Widget-specific menu entries · **CONVERGED (16/18)**

19 classes define `addWidgetSpecificMenuEntries` — the `Widget` base plus 18 overrides. Of the 18,
**16 open with `super`**, which is what preserves the base's layout-editing entries. One forwards
conditionally and deliberately (`ScrollPanelWdgt` hands the menu to its single content child when
`takesOverAndMergesChildrensMenus`, else calls `super`). Two simply omit it — `PointerWdgt` and
`IconicDesktopSystemScriptShortcutWdgt` — so a pointer or a script shortcut sitting in a division
stack offers no layout submenu.

### F20 — The `addMenuItem` API · **CONVERGED (323/326), with 3 malformed call sites**

`addMenuItem(label, target, action, opts = {})` — an options object with `toolTip`, `arg1`, `arg2`,
`closesUnpinnedPopUps`, `representsAWidget`, `bold`, … — across 326 call sites. `action` is a
**string method name on `target`**; `ButtonWdgt.trigger` carries a dev-build tripwire that throws when
it is not (added after a 2026-07-06 incident).

Three call sites do not match the contract, all in `SliderWdgt.addWidgetSpecificMenuEntries` (the
`floor…` / `ceiling…` / `button size…` entries):

```coffee
menu.addMenuItem "floor...", @, (->            # 3rd slot: a FUNCTION, not a string action
  @prompt menu.title + "\nfloor:",
    @setStart,                                 # prompt's 2nd slot is `target`; this is a method VALUE
    @start.toString(),                         # …so every later argument is shifted one place
    undefined, 0, @stop - @size, true
), "set the minimum value\nwhich can be selected"   # 4th slot: a STRING where `opts` is expected
```

`ButtonWdgt.trigger`'s own tripwire comment names this class as carrying "the same latent misuse".
Every other `@prompt` call site in the tree — `Widget.transparencyPopout`, `StringWdgt`'s font-size
and text prompts, `InspectorWdgt`'s add/rename-property — uses the aligned form
`@prompt msg, @, "methodName", defaultContents, …`, and inserting `@, ` and quoting the method name
is exactly what these three need. *(Static reading only — this container cannot build or run.)*

### F21 — How a widget describes itself · **THIN**

| | covered (own or inherited below `Widget`) |
|---|---|
| `colloquialName` | **106 / 270** — 164 widgets answer the base `"generic widget"` |
| `representativeIcon` | **13 / 270** — 257 answer the base `new WidgetIconWdgt` |
| `toolTipMessage` | 19 files set it, in four different ways |

`colloquialName` is consumed by window titles (`FrameWdgt` builds `"<colloquialName>: <title>"`),
inspector and console titles, the drag-embed hint, and the shortcut auto-namer — so a widget without
one is literally labelled *"generic widget"* in the product. Among the 164 are `ButtonWdgt`,
`CreatorButtonWdgt`, `CodeAreaWdgt`, `FanoutWdgt`, `AxisWdgt`, `BinOpenerWdgt`, `CaretWdgt` and the
whole plot-creator-button family — i.e. not only icon leaves.

The `toolTipMessage` idioms: a constructor parameter (`ButtonWdgt`, `LabelButtonWdgt`), a plain
constructor assignment (`RectangleWdgt`, `SpeechBubbleWdgt`, six `authoring-icons` classes), a
prototype `iconToolTipMessage` copied after `super` (the three F5 classes), or written from outside
(`ToolPanelWdgt` copies a payload's tooltip onto a glass-box top).

---

## 9. Wiring, dataflow and time

### F22 — Pins and the setter contract · **PATCHWORK (two argument conventions)**

| | classes |
|---|---|
| `@augmentWith ControllerMixin` (can drive a target) | 7 — `SliderWdgt`, `StringWdgt`, `SimpleTextWdgt`, `PaletteWdgt`, `PatchNodeWdgt`, `FanoutWdgt`, `FanoutPinWdgt` |
| declares a `numerical`/`string`/`color` setter list (can be driven) | 8 — the above minus `SimpleTextWdgt`, plus `Widget` and `Example3DPlotWdgt` |
| `getValue` / `exportedValue` (value export) | 2 / 1 |

A pin setter can be invoked along **two different paths, which put the value in different argument
slots**:

- a **wire**: `DataflowEngine._applyWireValue` calls `consumer[action](value)` — raw value in **slot 1**;
- a **menu / prompt / button**: `ButtonWdgt.trigger` calls
  `@target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, arg1, arg2`, and
  `CodePromptWdgt` calls `@target[@callback].call @target, undefined, @textWidget` — the value-giving
  **widget in slot 2**.

The tree handles this three different ways:

| convention | reads | classes |
|---|---|---|
| `(valueOrWidgetGivingValue, widgetGivingValue)` — coerce **slot 2** | slot 2's `getColor?()`/`getValue?()`, else slot 1 | `Widget.setColor`, `setBackgroundColor`, `setPadding*` (5), `setAlphaScaled`, `BoxWdgt.setCornerRadius`, `StringWdgt.setFontSize`, `PanelWdgt`/`ScrollPanelWdgt` overrides, the two layout-spec setter families |
| `(valueOrWidgetGivingValue)` — coerce **slot 1** | slot 1's `getValue?()` | `SliderWdgt.setStart`, `setStop`, `setSize` |
| plain value | neither | `SliderWdgt.setValue`, `NumberPromptWdgt.takeSliderValue` |

`SliderWdgt` therefore exposes `value`, `start`, `stop` and `size` as numerical pins whose four
setters use two conventions between them, and neither is the one the rest of the tree uses.

Secondary divergence inside the same family: the **idempotence guard** (`return if @color?.equals
aColor`) and the **return-the-coerced-value tail** are present in `Widget.setColor`/`setBackgroundColor`
/`setPadding*`/`setAlphaScaled` and absent from `BoxWdgt.setCornerRadius` and all four `SliderWdgt`
setters — the guard is what stops a wired circuit from re-firing on an unchanged value.

### F23 — Stepping · **TWO IDIOMS**

15 classes define `step`; 16 sites subscribe to `world.steppingWdgts`; 6 sites unsubscribe.

| idiom | classes |
|---|---|
| **subscribe once in the constructor, never unsubscribe** | `AnalogClockWdgt`, `BlinkerWdgt`, `BouncerWdgt`, `GraphsPlotsChartsWdgt`, `Example3DPlotWdgt`, `FridgeMagnets3DCanvasWdgt`, `VideoScrubberWdgt`, `VideoTimeLabelWdgt`, `VideoDurationLabelWdgt`, `VideoPlayPauseToggle`, `VideoPlayerCanvasWdgt` |
| **subscribe on demand, unsubscribe when idle** | `ScrollPanelWdgt` (momentum only), `SimpleImageWdgt`, `VideoPlayerWithRecommendationsWdgt`, `ExamplesFolderWindowWdgt` — and, outside the widget population, `DataflowSource`, which subscribes only while it has subscriber edges |

Both are safe for *lifetime* reasons — `Widget._destroyNoSettle` removes the widget from the set, and
`alignCopiedWidgetToSteppingStructures` carries membership across a duplicate — so the difference is
purely about whether an idle widget burns a slot in the once-per-cycle `forEach`. The always-on group
is the majority; the demand-driven group is the newer code.

`fps` and `synchronisedStepping` are set per class (`AnalogClockWdgt` `fps: 1` + synchronised;
`BlinkerWdgt` takes `@fps = 2` as a constructor parameter), and nothing documents the choice.

---

## 10. Cross-cutting

### F24 — Overriding teardown: public wrapper vs core · **PATCHWORK (2 vs 1), rule already written down**

`IconicDesktopSystemShortcutWdgt` states the rule in a comment: *"never touch the public wrapper — an
override there leaves every bulk-destroyed shortcut behind in the tracker"*, and overrides
`_destroyNoSettle`. Bulk teardown (`fullDestroyChildren`, `closeChildren`, `_fullDestroyNoSettle`)
recurses **cores**, so a public-wrapper override is skipped there.

Two classes override the public wrapper anyway: `SimpleSpreadsheetWdgt.destroy` (drops keyboard focus
and every cell's dataflow edges) and `PopUpWdgt.destroy` (`world.openPopUps.delete @`). Both have a
mitigation that makes the divergence survivable rather than broken — `PopUpWdgt` also deletes from the
set in its `_closeNoSettle` core, *and* `WorldWdgt` re-sweeps the open-pop-up set every cycle with a
comment saying exactly why (*"the destroy() function used everywhere is not recursive"*). That
world-level sweep is the cost of the inconsistency, made visible.

### F25 — Type tests vs capability queries · **CONVERGED direction, bounded tail**

The type-test-elimination campaign closed 2026-07-17 with a ranked decision framework (move the
behaviour → capability query named for the *capability* → singleton identity → leave). Current state:

| | count |
|---|---|
| `instanceof` sites tree-wide | 169 |
| …counted by the `instanceof-type-test` stink (baseline 87, currently 87) | 87 |
| widget classes using `instanceof` at all | 42 |
| distinct `?()`-dispatched method names tree-wide (mostly capability/role queries) | 94 |

The concentration is in the machinery, not the leaves: `Widget` 25, `ScrollPanelWdgt` 12,
`SimpleSpreadsheetWdgt` 9, `FrameWdgt` 7 — and the surviving ones carry `LEAVE`-verdict comments
(`PanelWdgt._amITheContentsPanelOfAScrollPanelWdgt` is explicitly "ONE place tests the class").
Capability queries live on the answering subclass with no base default, exactly as the framework
prescribes: `isLayoutInert` (11 call sites), `isDivisionElement` (12), `isConnectionPin`,
`attachesToScrollFrameDirectly`, `sliderTrackPressJumpsButton`, `hostsContentStackDropSlots`, …

### F26 — Where colours come from · **TWO IDIOMS**

| source | widget classes |
|---|---|
| `WorldWdgt.preferencesAndSettings.*` | 79 |
| interned `Color.BLACK` / `Color.WHITE` / … | 47 |
| `Color.create r, g, b` with literal channels | **40** |
| `'#RRGGBB'` string literals | 4 (`AnalogClockWdgt`, the three `Example*PlotWdgt`) |

`PreferencesAndSettings` is a per-world object explicitly meant to be the theming surface, but 40
widget classes hard-code channel triples — including chrome that is arguably theme-owned
(`FrameWdgt` `Color.create 248,248,248` for the window body and `125,125,125` for its stroke,
`IconButtonWdgt` `255,153,0` for hover, `CreatorButtonWdgt` `230,230,230`). The hex-string sites
(`AnalogClockWdgt`'s `'#D40000'`) bypass `Color` entirely.

### F27 — Mixins · **CONVERGED (policy is written and followed)**

8 mixins; usage across the 270 widgets:

`ControllerMixin` 7 · `HighlightableMixin` 7 · `ClippingAtRectangularBoundsMixin` 5 ·
`KeepsRatioWhenInVerticalStackMixin` 3 · `BubblesEditModeToCoordinatorMixin` 3 · `BackBufferMixin` 3 ·
`ParentStainerMixin` 2 · `WidgetCreatorAndSmartPlacerOnClickMixin` 2.

Every one is applied to classes on unrelated branches and overrides framework hooks — which is the
stated remit. No single-consumer mixins remain. `census-hierarchy-duplication.js` reports
**0 / 0 / 0** (identical-to-inherited, shadows-mixin, just-sends-super) across all 504 classes.

One purely cosmetic split inside the facet: the application line is written both as
`@augmentWith FooMixin, @name` (17 files) and `@augmentWith FooMixin` (11). The two are
**behaviourally identical**: `Class.coffee` strips the source line and re-emits it as
`window.<Class>.augmentWith(window.<Mixin>, '<Class>')`, so the consumer class name is supplied
whatever the source says, and `Object::augmentWith` falls back to `@name` even without it.

### F28 — Part awareness · **CONVERGED, tiny surface**

Only 8 files touch `world.parts`, and each uses the right one of the three questions:
`isAvailable` ("did this build ship it" — menu-item visibility), `whenAllLoaded` ("fetch it; the part
*constitutes* the result"), `whenOptionalPartsLoaded` ("fetch it if present; it only *enriches*").
`check-part-edges.js` fails the build on an unguarded core reference into a part, which is why this
facet has no drift.

---

## 11. Scorecard

Verdicts: **CONVERGED** one practice ≥ 90% · **TWO IDIOMS** two coherent practices, each principled ·
**PATCHWORK** no dominant practice, or variation with no stated criterion · **THIN** a practice exists
but is adopted by few.

| # | Facet | Verdict | Held by |
|---|---|---|---|
| F1 | Class naming / one class per file | CONVERGED | build (filename == class) |
| F2 | `Simple*` prefix meaning | PATCHWORK | — |
| F3 | Class header comment | THIN (45%) | — |
| F4 | Constructor parameter shape | PATCHWORK | — |
| F5 | `@param` shadowing avoidance | PATCHWORK | docs only (`CLAUDE.md`) |
| F6 | `super` position | CONVERGED (76%) | — |
| F7 | Initial extent verb in a constructor | PATCHWORK (5 verbs) | — |
| F8 | Child building | CONVERGED | `check-constructors-build.js` |
| F9 | Class-level field declaration | PATCHWORK (58%) | — |
| F10 | Serialization transients / copy hooks | THIN | production smoke round-trip |
| F11 | Appearance wiring | TWO IDIOMS | — |
| F12 | `isTransparentAt` placement | TWO IDIOMS (rule unstated) | — |
| F13 | `_reLayout` override shape | TWO IDIOMS + duplicated prologue | `check-relayout-bounds-first.js` (half of it) |
| F14 | `_reLayoutChildren` as the container marker | CONVERGED | `layout.md` §2.4 |
| F15 | Pure-measure protocol | CONVERGED | — |
| F16 | Settle tiers / `*NoSettle` cores | CONVERGED | `check-layering`, `check-thin-wraps`, `check-call-separation` |
| F17 | Self-invalidation | CONVERGED | `check-invalidation-receivers.js` |
| F18 | Input handlers / plane-mapped `pos` | CONVERGED | `check-raw-pointer-reads.js` |
| F19 | `addWidgetSpecificMenuEntries` calls `super` | CONVERGED (16/18) | — |
| F20 | `addMenuItem` options object | CONVERGED (323/326) | `ButtonWdgt.trigger` tripwire |
| F21 | `colloquialName` / `representativeIcon` | THIN (39% / 5%) | — |
| F22 | Pin-setter argument contract | PATCHWORK (3 conventions) | — |
| F23 | Stepping subscription | TWO IDIOMS | — |
| F24 | Teardown override tier | PATCHWORK (2 vs 1) | — |
| F25 | Type tests vs capability queries | CONVERGED | `instanceof-type-test` stink |
| F26 | Colour sourcing | TWO IDIOMS | — |
| F27 | Mixins | CONVERGED | `mixins.md` policy + census |
| F28 | Part awareness | CONVERGED | `check-part-edges.js` |

**The pattern is unmistakable: every CONVERGED facet has a gate, a census, or a named architecture
doc behind it; every PATCHWORK facet has none.** The `buildSystem/check-*.js` gates are, between
them, the reason the settle/invalidation/layout core is uniform — and the absence of any check on
constructor shape, field declaration, self-description or pin-setter arguments is exactly where the
tree diverges. Nothing here suggests writing more gates for their own sake (the severity policy in
`lint-and-static-checks.md` §3b is explicit that an unsound signal must never gate), but it does say
where an unwritten rule cannot be relied on.

---

## 12. Method, and its blind spots

Reproduce the counts from the repo root:

```sh
node ./buildSystem/census-public-private-calls.js      # public/private self-call mixing
node ./buildSystem/census-hierarchy-duplication.js     # 0/0/0 today
node ./buildSystem/census-property-placement.js        # PULL-UP / DEMOTE candidates
node ./buildSystem/check-stinks.js                     # instanceof / wall-clock / narration counts
node ./buildSystem/check-call-separation.js            # [S]/[U] baselines
```

The per-facet counts come from a regex scan over `src/**/*.coffee` that builds the class model
(parent chain + `@augmentWith` mixins + 2-space-indent member declarations) and then asks one pattern
per facet. Known limits, all shared with the repo's own scanners:

- **`super` is meta-compiled** (`src/meta/Class.coffee` rewrites every `super` form at fragment
  compile time), so textual body equivalence is not dispatch equivalence.
- **Property access is partly dynamic** — the duplicator walks `@[property]`, serialization drives off
  name strings, menu and button actions are string-dispatched. A field or method that only those
  reach looks unused.
- **Comment stripping is naive**; a pattern inside a string literal can be counted.
- **Inherited behaviour is invisible to an "N/270" ratio.** Where the denominator matters, §1's family
  table is the correction.
- **Nothing here was executed.** This container can neither build nor run the suite, so every claim is
  a claim about the source text and the documented contracts it is read against. The one finding that
  asserts a behavioural consequence (F20, the three `SliderWdgt` menu entries) is marked as such.

---

## See also

- [`../architecture/widget-authoring-guidelines.md`](../architecture/widget-authoring-guidelines.md) — the prescriptive companion: what a new widget should do, facet by facet.
- [`../architecture/widget-citizenship.md`](../architecture/widget-citizenship.md) — the contract these facets serve.
- [`../architecture/layering-naming-convention.md`](../architecture/layering-naming-convention.md) · [`../architecture/layout.md`](../architecture/layout.md) — the mechanics behind F13–F17.
- [`../architecture/lint-and-static-checks.md`](../architecture/lint-and-static-checks.md) — every gate named in the scorecard.
- [`../architecture/serialization-duplication-reference.md`](../architecture/serialization-duplication-reference.md) — the contract behind F9/F10.

# Widget-practices convergence — acting on the 2026-08-14 survey

**STATUS — IN PROGRESS, last updated 2026-08-17.**

| phase | state |
|---|---|
| W0–W5, W9 | ✅ **DONE 2026-08-16** (Fizzygum `f66da43d` / tests `d3f0a22ff`) |
| W6a — widen the setters | ✅ **DONE 2026-08-17** (`2b61249a`) — and it was a LIVE BUG: three slider prompts stored the slider's value, not the typed one |
| W7 — self-description | ✅ **DONE 2026-08-17** — landed **DERIVED**, not hand-written; see §2.7 "As landed" |
| W6b — idempotence guards | ☐ owner-gated (D3); re-check the P2 interaction first |
| W8 — constructor shapes | ✅ executed elsewhere, as P3 of `archive/constructor-parameter-conformance-plan.md` |
| W10 — closeout | ☐ |

⚠ Each phase's section carries an **"As landed"** block where it deviated from the sketch above it —
read that before trusting the sketch. W7's is the largest deviation in the plan.
Self-contained / runnable cold. Anchor on **symbol names** (verified 2026-08-14 at `21d5b64` +
the survey commit); line numbers drift — grep the symbol.

This plan turns the findings of
[`../measurements/widget-practices-survey-2026-08-14.md`](../measurements/widget-practices-survey-2026-08-14.md)
into an ordered, verifiable arc. The survey is the EVIDENCE (counts, class lists, per-facet
verdicts); [`../architecture/widget-authoring-guidelines.md`](../architecture/widget-authoring-guidelines.md)
is the TARGET STATE (the rule each phase converges on). Read neither to execute a phase — every
fact a phase needs is restated here.

---

## 0. Goal, non-goals, honest possible verdicts

**Goal.** Close the gap between how widgets are written and how the guidelines say they should be,
**in order of (defect severity × safety)**, and — for the facets where a convention is worth keeping —
leave behind a *mechanism* that keeps it closed, at the correct severity tier.

**The survey's structural finding is the plan's organising principle:** every CONVERGED facet has a
gate, a census, or a named architecture doc behind it; every PATCHWORK facet has none. So the arc is
not only "fix 124 declarations": it is "fix what is wrong, decide what is a real convention, and give
each surviving convention a mechanism" (W9).

**Acceptance for the arc.** Full `fg gauntlet` green (build gates + dpr 1 + dpr 2 + WebKit + apps +
tier-naming + notification-settle + capstone + paint-readonly) plus `fg homepage`; every phase
byte-identical **except** the phases whose recapture budget is stated up front (W3, W7, and the
inspector member-list churn of W4) — and for those, only the budgeted tests recapture.

**Non-goals.**
- No `*Wdgt` renames (F2's `Simple*` split is PARKED — §10).
- No theming work (F26 colours — PARKED pending an owner decision on whether `PreferencesAndSettings`
  is meant to be a real theme surface).
- No new *runtime* mechanism: every check W9 proposes is build-time or advisory.
- No behaviour change is smuggled in as a cleanup. Where a normalization would change behaviour
  (W6b's idempotence guards), it is a separate, owner-gated step with its own evidence.

**Honest possible verdicts per work item** (all three are acceptable outcomes, as in
`archive/menu-slider-ctor-conversion-plan.md`):
1. **CONVERGED** — the item is brought to the guideline shape, byte-identically (or within its stated
   recapture budget).
2. **PARTIALLY CONVERGED** — part of the item lands; the residue gets a factual comment at the site
   and a `BACKLOG.md` line.
3. **BY-DESIGN** — two falsified shapes (stop rule, §6) prove the divergence is correct; record the
   evidence in §10 and **update the survey's verdict and the guidelines' exception list** so the next
   reader is not sent back down the same path.

---

## 0.5 P0 verification findings (2026-08-14, gathered while authoring)

Recorded here because they **correct the survey**, which was published minutes earlier from a
coarser scan. Both corrections are already applied to the survey; they are restated because a cold
executor working from an older copy would otherwise chase phantom work.

- **F9 is 52 classes / 124 fields, not 57 / 135.** The first scan missed two things: mixin members
  declared through the DSL (`@addInstanceProperties fromClass, …` at 6-space indent inside a
  `*Mixin = ` literal, which is **not** a `class`, so a class-only scan never opened those files),
  and `#` comments (`Widget.coffee` ~:4611 mentions `@action = that setter` inside prose). Correct
  denominators: 136 widgets assign at least one own field, **84** declare all of them, **52** have a
  gap. ⚠ Any re-derivation must parse `src/mixins/*.coffee` + `src/app-kit/*Mixin.coffee` and strip
  comments, or it will re-report `state`, `color_hover`, `color_pressed` and `action` as missing.
- **48 of the 124 fields are eight REPEATED fields** — `toolTipMessage` (11 classes), `target` (10),
  `icon` (8), `cornerSpec` (5), `title` (5), `callback` / `cornerRadius` / `seed` (3 each). So W4 is
  eight structural decisions plus ~76 clerical lines, not 124 clerical lines. This is what makes W4
  worth doing at all.
- **`toolTipMessage` has no declaration on `Widget`** (only on `ButtonWdgt` ~:23 and `MenuItemSpec`),
  yet **`Widget.startCountdownForBubbleHelp` (~:369) is the reader**, and non-button widgets set it
  (`RectangleWdgt` ~:19, `SpeechBubbleWdgt` ~:21, six `authoring-icons` classes). The icons' tooltips
  are not dead: `ToolPanelWdgt` (~:59) copies a payload's `toolTipMessage` onto the highlightable
  glass-box top, which is what makes them show. So the field is a genuine cross-family concept —
  W4b's PULL-UP question is real, not cosmetic.
- **`cornerSpec` is a named family concept with no declaration anywhere.** `layout.md` §4.2 calls it
  the carrier-owned corner KNOB; five carriers set it (`HandleWdgt`, `AnalogClockWdgt`,
  `BinOpenerWdgt`, `ModifiedTextTriangleAnnotationWdgt`, `UpperRightTriangleWdgt`) and three call
  sites read it off another object (`WorldWdgt.createDesktop` ~:643, `MenusHelper` ~:25, and the two
  `parent?.add @, undefined, @cornerSpec` sites).
- **The `_reLayout` prologue is copy-pasted in exactly 23 classes** (survey F13 shape A), listed in
  §2.5. One class already has the hook the other 23 want: `PatchNodeWdgt._layOutNodeContents`.
- **The pin-setter divergence is FOUR conventions, not three** (the survey says three). The fourth is
  `setText: (theTextContent, stringFieldWidget)` (`StringWdgt` ~:1315), where slot 2 is a *field
  widget* and the value is dug out as `stringFieldWidget.text.text`. The patch-node family
  (`setInput1..4`, `FanoutWdgt.setInput`, `SliderWdgt.setValue`) is a fifth shape in effect —
  `(newvalue, ignored)`, which silently discards the menu/prompt path's widget.
- **`census-hierarchy-duplication.js` is 0/0/0 and `check-call-separation.js` is 0/0** at authoring,
  so this arc starts from a clean advisory baseline; any non-zero after a phase is that phase's doing.
- ⚠ **Nothing in this plan has been executed or verified against a build.** It was authored in a
  container that can neither build nor run the suite. Every "byte-identical" below is a REQUIREMENT
  to be demonstrated, never a claim.

---

## 1. Cold start — workspace, commands, ground rules

- **Layout (the build aborts without it):**
  ```
  Fizzygum-all/
    Fizzygum/          ← the ONLY repo you edit
    Fizzygum-builds/   ← generated; NEVER hand-edit
    Fizzygum-tests/    ← SystemTests + Automator (separate repo; test edits need no rebuild)
    Fizzygum-website/
  ```
  The umbrella is not a git repo. Use `git -C <repo>` rather than `cd`-chains.
- **Build / verify:** `./build_it_please.sh` (runs every gate) · `./build_and_smoke.sh` (build + boot
  both entry pages) · `./build_and_test.sh` (build + whole SystemTest suite, headless, sharded,
  `speed=fastest`, dpr 1, ~1 min). Where the local `fg` wrapper exists: `fg build` · `fg lint` ·
  `fg presuite` · `fg gauntlet` · `fg homepage` · `fg critique` · `fg recapture <test>`.
- **First action:** `git -C Fizzygum status`. Expect a clean tree. If `src/**` is already dirty, STOP
  and ask.
- **One commit per phase.** Never push without explicit approval.
- **Scope every grep to `Fizzygum/src`** — `Fizzygum-builds/latest` is ~1.3 GB.
- **House invariants that bite in this arc** (each already cost someone a session):
  - `undefined` is the one absence value; `nil` is retired and gated at zero.
  - A CoffeeScript `@param` assigns the field **unconditionally** and shadows the class-level default.
  - One class per file, filename == class name; reference classes by bare identifier
    (`extends X` / `@augmentWith X` / `new X`) so the boot dependency finder sees the edge.
  - `super` is **meta-compiled** (`src/meta/Class.coffee` rewrites every form at fragment-compile
    time), so textual equivalence is not dispatch equivalence — never reason about a `super` change
    without running it.
  - Never `git stash` in this repo (a `stash pop` once emptied both the tree and the stash list).
- **No conclusions before evidence.** Do not write "byte-identical", "safe" or "no-op" in a comment,
  doc or commit message before the corresponding gate has actually passed.

---

## 2. The work items — exact anchors and current state

### 2.1 W1 · The three malformed `SliderWdgt` menu entries (survey F20) — a real defect

`src/basic-widgets/SliderWdgt.coffee`, `addWidgetSpecificMenuEntries` (~:207-238). Current text of
the first of three identically-shaped entries:

```coffee
menu.addMenuItem "floor...", @, (->
  @prompt menu.title + "\nfloor:",
    @setStart,
    @start.toString(),
    undefined,
    0,
    @stop - @size,
    true
), "set the minimum value\nwhich can be selected"
```

Two contract breaches, both provable from the callee signatures:

1. **`addMenuItem label, target, action, opts = {}`** (`MenuWdgt` ~:133 → `MenuRowsPanelWdgt` ~:181 →
   `MenuItemSpec`). Slot 3 receives a **function**, but the action is dispatched as
   `@target[@action]` (`ButtonWdgt.trigger` ~:106) — a function coerces to an undefined key.
   `ButtonWdgt.trigger` (~:100-105) carries a dev-build tripwire that **throws** on a non-string
   action, and its comment names this class: *"SliderWdgt carried the same latent misuse"*. Slot 4
   receives a **string** where `opts` is expected, so `opts.toolTip` is `undefined` and the tooltip is
   lost.
2. **`Widget.prompt (msg, target, callback, defaultContents, width, floorNum, ceilingNum, isRounded)`**
   (~:4224). The call passes `msg, @setStart, @start.toString(), undefined, 0, @stop - @size, true` —
   seven arguments where the intended eight begin `msg, @, "setStart"`. Every argument after slot 1 is
   shifted one place: `target` gets a method value, `callback` gets the current value string, `width`
   gets `0`, `floorNum` gets the ceiling, `ceilingNum` gets `true`.

The intended form, which every other `@prompt` site in the tree already uses (`Widget.transparencyPopout`
~:4203, `StringWdgt` ~:987 and ~:999, `InspectorWdgt` ~:680 and ~:704):

```coffee
menu.addMenuItem "floor...", @, "promptForFloor", toolTip: "set the minimum value\nwhich can be selected"
…
promptForFloor: (ignored, ignored2, menuItem) ->
  @prompt (menuItem?.parent?.title ? "slider") + "\nfloor:", @, "setStart", @start.toString(),
    undefined, 0, @stop - @size, true
```

⚠ The closure captured `menu.title`; a string action cannot. `MenuItemWdgt` reaches its menu as
`@parent` (the rows panel) — resolve the title the way `Widget.transparencyPopout` does
(`menuItem.parent.title`) and confirm the menu-item argument order at the call site before relying on
it. Scope: exactly three sites, all in this method; `grep -n 'addMenuItem .*(->' src` returns these
three and nothing else.

### 2.2 W2 · Teardown overrides on the public wrapper (survey F24)

Bulk teardown recurses **cores**: `Widget.fullDestroyChildren` / `closeChildren` /
`_fullDestroyNoSettle` (~:656-700) all loop `_fullDestroyNoSettle` / `_closeNoSettle`, never the
public verbs. `IconicDesktopSystemShortcutWdgt` (~:45) states the rule in a comment and overrides
`_destroyNoSettle`. Two classes override the public wrapper instead:

- `src/spreadsheet/SimpleSpreadsheetWdgt.coffee` `destroy:` (~:922) — drops keyboard focus and calls
  `world.dataflow?.removeAllEdgesOf` for every cell.
- `src/PopUpWdgt.coffee` `destroy:` (~:204) — `world.openPopUps.delete @`.

`PopUpWdgt` is the *mitigated* case, and the mitigation is visible: it also deletes from the set in
its `_closeNoSettle` core (~:217), and `WorldWdgt` (~:691-700) re-sweeps `openPopUps` every cycle with
the comment *"the destroy() function used everywhere is not recursive"*. `SimpleSpreadsheetWdgt` has
no such sweep — a sheet torn down as part of a subtree keeps its cells' dataflow edges.

### 2.3 W3 · Two `addWidgetSpecificMenuEntries` overrides that drop `super` (survey F19)

`src/demos/PointerWdgt.coffee` (~:76) and `src/IconicDesktopSystemScriptShortcutWdgt.coffee` (~:25).
Both open with `menu.addLine…` instead of `super`, so the base's block (`Widget` ~:4281) never runs and
those two widgets offer no layout submenu when they sit in a division stack or a content stack.
`ScrollPanelWdgt` (~:829) also omits it, but *conditionally and deliberately* — leave it alone.

### 2.4 W4 · Undeclared instance fields (survey F9) — 51 classes / 120 fields

The full list is reproducible with the §7 snippet. The decomposition that makes it tractable:

- **W4a — clerical, 11 classes / 13 fields, no PULL-UP question:** `ButtonWdgt` (`faceWidget`),
  `DragChargingRingWdgt` (`_lastRingCenter`), `Example3DPlotWdgt` (`edges`), `FolderWindowWdgt`
  (`internal`), `InspectorWdgt` (`resizer`, `textWidget`), `MenuItemWdgt` (`actionableAsThumbnail`),
  `PaintToolbarWdgt` (`queue`), `SimpleTextPanelWdgt` (`isTextLineWrapping`, `textAsString`),
  `SimpleVerticalStackPanelWdgt` (`padding`), `SliderButtonWdgt` (`offset`), `TextWdgt` (`alignment`).
- **W4b — the eight repeated fields (46 occurrences), each a placement DECISION:**

  | field | classes | the question |
  |---|---|---|
  | `toolTipMessage` | 11 | declare on `Widget` (the reader `startCountdownForBubbleHelp` lives there) or on each setter? |
  | `target` | 9 | `ControllerMixin` declares it for controllers; the shortcut / prompt / console families each re-declare it as a `@param`. One home or four? |
  | `icon` | 8 | `WidgetHolderWithCaptionWdgt` + the shortcut family + the generic-icon family |
  | `cornerSpec` | 5 | the carrier-owned corner knob — `Widget`, or a `layout.md`-named family base? |
  | `title` | 5 | the `IconicDesktopSystem*` shortcut family — pull up to `IconicDesktopSystemShortcutWdgt` |
  | `callback` | 2 | `CodePromptWdgt`, `IconicDesktopSystemWindowedAppLauncherWdgt` |
  | `cornerRadius` | 3 | `MenuRowsPanelWdgt`, `SpeechBubbleWdgt`, `ToolTipWdgt` (`BoxWdgt` already declares it) |
  | `seed` | 3 | the three `Example*PlotWdgt` — pull up to `GraphsPlotsChartsWdgt` |

  ⚠ `callback` now stands at 2 classes, below the ≥3 threshold that picked the other seven; it stays
  in the table because it is still a placement decision, not because it is still a repeat. Two more
  fields sit at 2 (`_sheetWidget` in `CellWdgt`/`SheetHeaderCellWdgt`, `contentsWidget` in
  `SpeechBubbleWdgt`/`ToolTipWdgt`); both are W4c business.

- **W4c — the four big classes:** `WorldWdgt` (16), `SimpleSpreadsheetWdgt` (16), `CellWdgt` (7),
  `SheetHeaderCellWdgt` (4) — plus `FrameWdgt` (6), `FridgeMagnetsWdgt` (4), `SpeechBubbleWdgt` (4),
  `IconicDesktopSystemWindowedAppLauncherWdgt` (4).

### 2.5 W5 · The `_reLayout` prologue (survey F13)

⚠ **"Verbatim in 23" was WRONG — measured 2026-08-16, the exact count is 18.** The corrected list is
below; the five that were miscounted are named after it, each with the difference that would have
broken a blind conversion. Re-derive with `grep -rn '^  _reLayout:' src` (39 definitions in all:
these, plus shape B's 9 containers, `Widget` itself, and 11 one-off shapes).

Shape A, verbatim in each of: `AxisWdgt`, `BinWdgt`, `ButtonWdgt`, `CodePromptWdgt`,
`ColorPickerWdgt`, `ConsoleWdgt`, `ErrorsLogViewerWdgt`, `FanoutWdgt`, `FridgeMagnetsWdgt`,
`GenericObjectIconWdgt`, `GenericShortcutIconWdgt`, `PatchNodeWdgt`, `PlotWithAxesWdgt`, `ScriptWdgt`,
`SimpleLinkWdgt`, `StretchableWidgetContainerWdgt`, `ToolPanelWdgt`, `WidgetHolderWithCaptionWdgt`.

**NOT shape A, though this plan listed them as such:**

| class | how it actually differs |
|---|---|
| `SimpleSpreadsheetWdgt` | no trailing `@_markLayoutAsFixed()` — the body ends at `super` |
| `SpeechBubbleWdgt` | `@_applyGrantedBounds` sits *inside* the `_repaintAsOneUnit` block |
| `StretchableCanvasWdgt` | same |
| `StretchablePanelWdgt` | inside the block **and last**, after the children loop — bounds are applied AFTER the children are laid out |
| `SwitchButtonWdgt` | no collapsed guard, no repaint unit, and the tail is `super newBoundsForThisLayout` with no `@_markLayoutAsFixed()` |

```coffee
_reLayout: (newBoundsForThisLayout) ->
  newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout
  if @_handleCollapsedStateShouldWeReturn() then return
  @_applyGrantedBounds newBoundsForThisLayout      # bounds FIRST — gated
  …the only part that varies…
  super
  @_markLayoutAsFixed()
```

Shape B (container: `super` then `@_reLayoutChildren()`) is the other 9 and is already the guideline
shape — leave it alone.

### 2.6 W6 · The pin-setter contract (survey F22) — five shapes in the tree

A pin setter is reached along two paths that put the value in **different argument slots**:

- **wire** — `DataflowEngine._applyWireValue` (~:359) calls `consumer[action] value` → raw value in
  **slot 1**;
- **menu / prompt / button** — `ButtonWdgt.trigger` (~:106) calls
  `@target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, arg1, arg2`, and
  `CodePromptWdgt` (~:50) calls `@target[@callback].call @target, undefined, @textWidget` → the
  value-giving **widget in slot 2**.

| shape | reads | sites |
|---|---|---|
| A `(valueOrWidget, widgetGiving)` — coerce slot 2 | `widgetGiving?.getColor?()` / `.getValue?()` | `Widget.setColor` ~:2486, `setBackgroundColor` ~:2501, `setPadding*` ×5 ~:4332-4396, `setAlphaScaled` ~:4399, `BoxWdgt.setCornerRadius` ~:15, `StringWdgt.setFontSize` ~:1369, the `PanelWdgt`/`ScrollPanelWdgt` overrides, the two layout-spec setter families |
| B `(valueOrWidget)` — coerce slot 1 | `valueOrWidget.getValue?()` | `SliderWdgt.setStart` ~:260, `setStop` ~:276, `setSize` ~:307 |
| C `(newvalue, ignored)` — discard slot 2 | nothing | `SliderWdgt.setValue` ~:146, `CalculatingPatchNodeWdgt.setInput1..4`, `DiffingPatchNodeWdgt.setInput1`, `RegexSubstitutionPatchNodeWdgt.setInput1`, `FanoutWdgt.setInput`, `FanoutPinWdgt.setInput` |
| D `(theTextContent, stringFieldWidget)` — dig `.text.text` out of slot 2 | a *field* widget | `StringWdgt.setText` ~:1315, `SimpleTextWdgt.setText` ~:140, `FizzytilesCodeWdgt.setText` ~:11 |
| E plain value | nothing | `NumberPromptWdgt.takeSliderValue` ~:32 (a pure sink; correct as-is) |

Secondary divergence: the **idempotence guard** (`return if @color?.equals aColor`) and the
**return-the-coerced-value tail** exist in shape A and are absent from B, C and D.

#### ⭐ RE-DERIVED 2026-08-17, after connector P1 — W6 is THREE SETTERS AND A LIVE BUG

The owner's direction was to re-derive this table once P1 landed. Done, with a probe that drives the
REAL prompt end-to-end (open it, type, click Ok) rather than reading signatures. **The table above is
still accurate — P1 touched no setter body — but its framing was wrong: this is not an inconsistency
to tidy, it is a user-visible defect in three menu items.**

**What actually reaches a setter, measured.** Of 60 distinct setter names, only **8** are reachable
by BOTH paths. The second path is `@prompt` / `@pickColor` — *not* `addMenuItem`, which is why a
first pass looking for menu actions found none. `ButtonWdgt.trigger` dispatches
`@target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, …`, and for a prompt
`MenuRowsPanelWdgt.createMenuItem` sets `dataSource: @target` (the widget being configured) and
`widgetEnv: @environment` (the entry field). So **slot 1 = the target widget, slot 2 = the
value-giving field** — the table's claim, confirmed.

| shape | prompt-reached? | verdict |
|---|---|---|
| **A** — arity 2, coerces slot 2 | yes: `setAlphaScaled`, `setCornerRadius`, `setFontSize`, the four layout-spec setters | ✅ **correct, and correct for wires too** (a wire leaves slot 2 undefined, so it falls through to slot 1) |
| **B** — arity 1, coerces slot 1 | yes: `SliderWdgt.setStart`, `setStop`, `setSize` | ❌ **BROKEN — see below** |
| **C** — `(newvalue, ignored)` | **no** — `setValue`, `setInput*`, `setInput` are reached only by `wireTo` | ✅ no change needed; discarding a slot nobody fills is harmless |
| **D** — digs `.text.text` out of slot 2 | yes: `setText` | ✅ handles the prompt path, and has a `_setTextConnector` lane for wires |
| **E** — plain value | pure sink | ✅ as the table already said |

⇒ **Shape A is simply the correct shape, and B is simply wrong.** C and D need nothing.

**The live bug (verified, `Fizzygum-tests/.scratch/w6-prompt-slot-probe.js`).** `SliderWdgt`'s three
prompts — "floor", "ceiling", "button size" — **discard what you type and store the slider's current
value instead**:

```
setStart   typed 25, slider value 50 → start became 50   (slot1 = the SliderWdgt itself)
setStop    typed 75, slider value 50 → stop  became 50
setSize    typed 30, slider value 50 → size  became 50
setFontSize typed 22               → fontSize became 22   ← the arity-2 CONTRAST: works
```

Same prompt, same dispatch, same slots; the only difference is which slot the setter coerces. That
is the proof that the cause is precisely the slot-1 coercion.

⚠ **Why it is silent rather than loud, and the general lesson.** `numOrWidgetGivingNum.getValue?()`
is a duck-typed probe. `SliderWdgt.getValue` did not exist until it was added for the SPREADSHEET
value protocol (dataflow Phase 4, `getValue: -> @value`). Before that the probe missed, the slider
object fell through to `parseFloat`, and the prompt visibly did nothing. **Adding a reader for one
subsystem silently changed the behaviour of an unrelated subsystem's duck-typed coercion, turning a
visible failure into a plausible wrong answer.** This is the same class of hazard connector P1
removed from `exportedValue` — and it is the strongest argument against W6a standardising ON slot-2
duck-typing rather than reducing it.

**Revised W6a scope: three setters** (`SliderWdgt.setStart` / `setStop` / `setSize`) widened to the
shape-A signature `(numOrWidget, widgetGivingValue)` and coercing slot 2 first. Not 19 setters, not
five shapes. **W6b/D3 (idempotence guards) is unaffected and stays gated separately.**

#### ✅ W6a LANDED 2026-08-17 (owner-approved as a bug fix)

The three setters now check slot 2 first, then slot 1, then the raw value — so the prompt path and
the wire path both work (a wire leaves slot 2 undefined and falls through). Verified with the probe
that found the bug: `0 → 25`, `100 → 75`, `10 → 30`, all taking the typed value.

**Regression guard: `SystemTest_macroSliderFloorPromptTakesTypedValue`** — opens a slider's
"floor..." prompt, types 25, clicks Ok, asserts `slider.start == 25`. ⭐ **Confirmed to FAIL against
the bug before being trusted**: with the pre-fix slot-1 reading planted back it reports
`FAIL … expected: 25 found: 50` *and* image_3 mismatches (the thumb neither moves nor grows). It
catches the defect by assertion and by pixels.

⚠ **There was no test over ANY property prompt before this one.** That is the whole reason a
user-visible defect in three shipping menu items survived indefinitely — not the shape of the
setters. Worth remembering when judging the rest of §2.6: an inconsistency nothing exercises is
indistinguishable from a bug nothing exercises.

**⚠ Three corrections to this section, measured 2026-08-16 while running W0–W2. Read them before
starting W6.**

1. **There is a SIXTH route the table omits, and it is the tree's existing answer to this very
   problem: the `_<action>Connector` lane.** `DataflowEngine._applyWireValue` (~:359) computes
   `connectorName = "_#{action}Connector"` and prefers that method when the consumer defines it —
   so a class can give the WIRE path its own entry point and leave the menu/button signature alone,
   instead of widening one method to serve both. Three sites use it today:
   `StringWdgt._setTextConnector`, `StringWdgt._setFontSizeConnector`,
   `NumberPromptWdgt._takeSliderValueConnector`. W6a must decide whether it is unifying the setters
   or promoting this lane; those are different plans, and the second needs no signature widening.
2. **W6b's idempotence guard is NOT redundant with the engine's cutoff, but it is close enough to
   need care.** The engine's equal-value cutoff (`_valuesEqual`, ~:253; the widget-sink branch
   ~:394) decides only whether to traverse ONWARD from a sink — `_applyWireValue` still CALLS the
   setter with an equal value. So a per-setter guard would newly suppress the setter's own side
   effects (its `_changed()` repaint and any onward fire), which is a real behaviour change and the
   reason D3 wants its own commit.
3. **W6a collided with the sibling arc's P1 in DIRECTION, not just in files — ✅ RESOLVED: P1 went
   first (landed 2026-08-16), on the owner's direction.**
   [`connector-ubiquity-and-reflection-plan.md`](connector-ubiquity-and-reflection-plan.md) §P1
   replaced the duck-typed `getColor?() ? getValue?() ? @text` coercion with declared `PinSpec`
   readers, over "~19 setter overrides on 9 classes" — the same overrides W6a would rewrite. Had W6a
   gone first and standardised ON the slot-2 duck-typed coercion, it would have entrenched what P1
   deletes, at the cost of a double rewrite.
   ⚠ **What P1 actually did is NARROWER than that prediction, so re-derive §2.6 rather than assuming
   it dissolved.** P1 replaced the pin DECLARATION (the four setter tables → one `pins` list of
   `PinSpec` records) and the exported-value reader — it did **not** touch a single setter BODY. So
   the five shapes below are all still in the tree and this table is, as far as anything verified,
   still accurate; re-derive it from `node buildSystem/census-widget-conformance.js --json` (facet 5)
   before starting, since the counts here are a 2026-08-14 snapshot. The one change that matters to
   W6: `exportedValue` no longer probes `getValue?()`, so a setter's slot-2 coercion is now the LAST
   duck-typed reader in this family — which strengthens the case for W6a rather than dissolving it.
   ⚠ Also worth checking before D3: P2's proposed bind-time rule ("the side whose menu you opened
   pushes") depends on both wires FIRING at bind time; an idempotence guard could swallow the second
   fire when the two sides already agree.

### 2.7 W7 · Self-description (survey F21)

164 of 270 widgets answer the base `colloquialName` → `"generic widget"`; 257 answer the base
`representativeIcon` → `new WidgetIconWdgt`. Consumers that put the string on screen: `FrameWdgt`
(~:344 and ~:363, window titles), `InspectorWdgt` (~:67), `ConsoleWdgt` (~:13),
`ActivePointerWdgt` (~:284, the drag-embed hint), `Widget` (~:3558, the shortcut auto-namer).
The non-icon classes among the 164 include `ButtonWdgt`, `CreatorButtonWdgt`, `CodeAreaWdgt`,
`FanoutWdgt`, `AxisWdgt`, `BinOpenerWdgt`, `CaretWdgt` and the whole plot-creator-button family.

### 2.8 W8 · Constructor parameter shape (survey F4/F5)

- `src/LabelButtonWdgt.coffee` — **17** positional slots (~:30-48).
- `src/ButtonWdgt.coffee` — **12** positional slots (~:36-50).
- `src/NumberPromptWdgt.coffee` — 9.
- The `@param` shadowing consequence: `IconButtonWdgt` (~:41-45), `CreatorButtonWdgt` (~:26-29) and
  `EditorContentPropertyChangerButtonWdgt` (~:40-42) each carry a **parallel shadow field**
  `iconToolTipMessage`, copied into `@toolTipMessage` after `super`, precisely because `ButtonWdgt`
  takes `@toolTipMessage` as a parameter defaulting to `undefined`. `IconButtonWdgt`'s comment says so.

Precedent for the conversion: `21d5b64` (`SliderWdgt`: positional numbers + an options object) and
`archive/menu-slider-ctor-conversion-plan.md`.

⚠ **W8 was EXECUTED as P3 of `archive/constructor-parameter-conformance-plan.md`** (authored the same day, from
the constructor survey rather than the widget survey). That plan states the general RULE — now
[`architecture/constructor-and-parameter-conventions.md`](../architecture/constructor-and-parameter-conventions.md)
— sweeps all five families that carry it (the button family is one of them), and seeds the
`positional-hole` ratchet. **The button conversion is ONE piece of work; do it once.** Whichever arc
reaches it first executes it and the other de-scopes to a pointer. The shadow-field finding above is
this section's own and must ride along either way: the options conversion is what lets those three
`iconToolTipMessage` fields be DELETED rather than perpetuated.

**Status, verified 2026-08-16 (W0):** the CONSTRUCTOR half landed — `LabelButtonWdgt` and
`ButtonWdgt` are both `(target, action, opts = {})`, and `ButtonWdgt` now reads its tooltip
GUARDED (`@toolTipMessage = opts.toolTip if opts.toolTip?`, ~:60), with a comment saying that is
precisely what lets a subclass declare `toolTipMessage:` on its prototype and have it survive.
**The shadow-field half did NOT ride along.** `iconToolTipMessage` is present in 35 files: 33
subclass declarations carrying the actual string, plus the two base classes that declare it
`undefined` and copy it after `super` — `CreatorButtonWdgt` (~:21, ~:28) and
`EditorContentPropertyChangerButtonWdgt` (~:35, ~:42), each `@toolTipMessage = @iconToolTipMessage`.
`IconButtonWdgt` has already moved off it entirely (zero mentions; its header comment tells
subclasses to write `toolTipMessage:` directly), so the enabling change is done and only the cleanup
is outstanding — two copy lines deleted and 33 declarations renamed.
⭐ This is the same decision as W4b's `toolTipMessage` row: renaming those 33 IS the "declare it on
the prototype" answer, so **do W4b's `toolTipMessage` and this together, or neither.**

---

## 3. The core engineering facts every phase rests on

1. **The one-flush invariant.** One settle per outermost public mutation; low-level code never
   settles. A public mutator is a thin wrap over its `_<name>NoSettle` core
   (`check-thin-wraps.js`); anything inside a layout pass, a constructor, a notification callback or a
   teardown chain calls cores. Rules [A]–[T] in `check-layering.js`.
2. **Bulk teardown recurses cores** (§2.2) — this is the whole of W2.
3. **The duplicator walks own enumerable properties** and restores into `Object.create(prototype)`;
   serialization drives off name strings. A prototype declaration is what makes a lazily-initialised
   field visible to duplication, serialization and the inspector — the whole of W4.
4. **⚠ The mixin/class-body ORDER trap.** `src/meta/Class.coffee` (~:376-382) emits **all**
   `augmentWith` calls **before** all class-body fields, and
   `Object::addInstanceProperties` (`src/boot/extensions/Object-extensions.coffee` ~:22) writes
   `@::[key] = value`. So a class-body `foo: undefined` added to a class whose chain mixes in a
   `foo` **CLOBBERS the mixin's value**. This is the exact mechanism behind the
   `census-property-placement` PULL-UP false positive that "would have turned the desktop icons
   near-white" (`archive/duplication-triage-2026-07-15-hierarchy-round4.md`). **Before adding any
   declaration in W4, check the field against every mixin in the chain** (§7 snippet does this).
5. **Adding a property to a class whose instances a SystemTest inspects lengthens that test's member
   list.** This is a *benign* recapture, not a diff to chase — but it must be budgeted, and it is why
   W4b's "declare on `Widget`" option is the expensive one (every inspector test).
6. **`colloquialName` is DRAWN** (§2.7). Adding one to a class whose window title or hierarchy-menu
   entry appears in a screenshot moves pixels. This is why W7 is owner-gated, not clerical.
7. **A wire carries no value** — `_fireConnection` marks the producer stale and the drain PULLS
   `dataflowValue`. Delivery routes to `_<action>Connector` when the target defines one, else to the
   public `@action` (`DataflowEngine._applyWireValue`). W6 must not disturb either lane.
8. **Determinism.** Render/layout/input must be a pure function of the event stream and final
   geometry — no wall-clock, timers, frame counts or randomness. `../../Fizzygum-tests/DETERMINISM.md`.

---

## 4. Why the obvious approach does not just drop in

- **W1** — the three entries capture `menu.title` in a closure; a string action cannot close over
  anything, so the title has to be recovered from the menu-item argument (`menuItem.parent.title`,
  the `Widget.transparencyPopout` idiom). Confirm the argument the menu machinery actually passes
  before relying on it — `@target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, …`
  means the *menu item* is not automatically slot 3.
- **W2** — moving `SimpleSpreadsheetWdgt.destroy`'s body to `_destroyNoSettle` makes it run on paths
  it never ran on (every bulk teardown of a subtree containing a sheet, including `resetWorld`
  between SystemTests). That is the POINT, and it is also the risk: `removeAllEdgesOf` on a
  half-torn-down model must tolerate a `@model` that is already gone. Read
  `SimpleSpreadsheetWdgt._recommitAllCells` / `model.forEachCell` before moving.
- **W4b** — see §3.4 (mixin clobber) and §3.5 (inspector member lists). Also: `target` is *already*
  declared by `ControllerMixin` for controllers; pulling a second `target` onto `Widget` would give
  every widget a prototype `target` and change what the inspector and the target-chooser menus show.
  The safe direction is a **family base**, not `Widget`, unless the owner wants the global concept.
- **W5** — the prologue is not pure boilerplate: the trailing `super` runs the base's corner pass and
  its own `_applyMoveTo`/`_applyExtent`, so a template method must call the hook **between**
  `_applyGrantedBounds` and `super`, exactly where the copies do. Moving the hook one line either way
  changes the frame children see. `check-relayout-bounds-first.js` will catch the bounds half; nothing
  catches the ordering half except the suite.
- **W6** — widening a setter to accept both slots is purely ADDITIVE and should be byte-identical.
  Adding the **idempotence guard** is NOT: a wired circuit that currently re-fires on an equal value
  would stop, which is the desired behaviour but *is* a behaviour change, observable in the
  patch-programming and °C↔°F converter macros. Hence W6a (widen) and W6b (guard, owner-gated) are
  separate.
- **W7** — see §3.6. Also, a colloquial name flows into the shortcut auto-namer, so adding one can
  change generated shortcut names, which appear in folder windows.
- **W8** — `LabelButtonWdgt`'s 17 slots are forwarded positionally from `MenuItemWdgt` (~:18) and
  `MenuItemSpec` (~:38). The conversion is therefore a three-class change, and `MenuItemSpec` is the
  serialized carrier of menu-item state — changing its shape touches snapshots.

---

## 5. Phases — one per commit point, ordered by (defect severity × safety)

Ordering principle: fix defects first, then invisible structure, then the items that move pixels or
need an owner decision, then the mechanism that keeps it all closed.

**W0 — preliminaries (no edits).**
1. `git -C Fizzygum status` clean; `fg gauntlet` green as a baseline (record the suite count).
2. Re-derive the §2 counts with the §7 snippet; if any differs from this plan, fix the plan first.
3. **Recapture-risk survey** (do this ONCE, it serves W3/W4/W7): grep
   `../Fizzygum-tests/tests/**/*_automationCommands.js` for the tests that (a) screenshot an
   inspector member list, (b) screenshot a window title bar, (c) open a widget context menu. Write the
   three lists into §10. These are the only tests any phase here can legitimately recapture.
4. `node ./buildSystem/census-property-placement.js` and `census-hierarchy-duplication.js` — record
   the starting numbers, so a phase's effect on them is visible.

**W1 — the SliderWdgt menu entries.** (§2.1) Convert all three to string actions + `opts`, add the
three small action methods, verify the tooltips appear. Verdict 1 expected.
Coverage: any macro opening a slider's context menu, plus the scrollbar-heavy macros incidentally
(every `ScrollPanelWdgt` bar is a `SliderWdgt`). Recapture budget: **0**, unless a test already
screenshots the (currently tooltip-less) slider menu — then one budgeted recapture, noted in §10.

**W2 — teardown tier.** (§2.2) Move both bodies from `destroy` to `_destroyNoSettle`, `super` first.
Delete the now-redundant `world.openPopUps.delete @` if and only if the core already covers every
path — otherwise keep both and say why. Consider whether `WorldWdgt`'s per-cycle `openPopUps` sweep
(~:691) can then go; **do not remove it in this phase** — bank it as a follow-up with evidence.
Recapture budget: **0**.

**W3 — the two missing `super`s.** (§2.3) *Owner-gated*: this ADDS menu entries to two widgets, so
any test opening those menus recaptures. Ask first (D1). Recapture budget: whatever W0.3 list says.

**W4 — field declarations.** Three commits.
- **W4a** (11 classes / 13 fields) — pure additions, each checked against §3.4. Recapture: only the
  inspector member-list tests from W0.3, and only if they inspect one of these classes.
- **W4b** (the eight repeated fields) — one owner decision per field (D2), then execute. Prefer a
  **family base** over `Widget` wherever a family base exists; `toolTipMessage` is the one genuine
  `Widget` candidate, and it is also the most expensive.
- **W4c** (the four big classes) — `WorldWdgt` and `SimpleSpreadsheetWdgt` first; both are
  inspected rarely and hold the most state.

**W5 — the `_reLayout` template.** (§2.5) Add the hook to `Widget` (name it for the role —
`_layOutOwnContents`, empty base), convert the 23 classes one small batch at a time (suggested
batches: the 5 code-area/prompt classes · the 4 stretchable classes · the 5 icon/holder classes · the
rest). Byte-identity is the acceptance; any diff means the hook is in the wrong place (§4).
Recapture budget: **0** — a diff here is a bug, never a new baseline.

**W6a — widen the pin setters.** (§2.6) ⚠ **Coordinate with
[`connector-ubiquity-and-reflection-plan.md`](connector-ubiquity-and-reflection-plan.md) first** — that
arc (authored the same day) re-examines the whole pin protocol from the other end (a controller is a
view of the value it controls; what announces itself, and which classes can be a source at all), and
its §2 inventories the same setter tables. If it lands first, re-derive §2.6 against the tree it
leaves. If this lands first, W6a is a pure widening that its work sits on top of. Either way the two
must not edit the same setter bodies in parallel.

Bring shapes B, C and D to shape A's coercion, keeping each body's existing clamping and firing
untouched:
```coffee
value = widgetGiving?.getValue?() ? valueOrWidget?.getValue?() ? valueOrWidget
```
Purely additive: a caller that passed a raw value in slot 1 still lands on the same branch. Include
the `return <coerced>` tail. Recapture budget: **0**.

**W6b — idempotence guards.** *Owner-gated* (D3): adds `return @foo if @foo is foo` to shapes B/C/D.
Behaviour change (§4). Run the patch-programming and converter macros explicitly.

**W7 — self-description.** *Owner-gated* (D4). Add `colloquialName` to the substantial classes among
the 164 (start with the ~30 non-icon ones listed in survey F21), and `representativeIcon` to anything
that can be referenced from the desktop. Recapture budget: the window-title and menu lists from W0.3.

#### As landed — 2026-08-17: DERIVED, not hand-written

⚠ **The instruction above — "add `colloquialName` to the substantial classes" — is the expensive way
to buy the cheap half of this.** `Widget.colloquialName` returned the flat string `"generic widget"`,
and that truthy default was already **shadowing a derivation the tree had written and forgotten**: the
save-to-file auto-namer read
`(@colloquialName?() or @constructor.name.replace "Wdgt", "") or "widget"`, whose second arm could
never run. So every un-overriding class saved its file as `generic widget.fzw.json`.

What landed instead: **the base DERIVES** from the class name — split camelCase into lowercase words,
drop the `Wdgt`/`Morph` suffix — so an override becomes an editorial improvement rather than the only
escape from a lie, and the auto-namer collapses to `@colloquialName()`.

⭐⭐ **The correction that mattered: `colloquialName` is INHERITED, and the first survey ignored the
chain.** Comparing each class's override to its own derivation says nothing about what deleting it
would produce. Resolved properly (`Fizzygum-tests/.scratch/w7-colloquial-inheritance-survey.js`):

| | |
|---|---|
| classes that GAIN the derivation | **162** (they answered `"generic widget"`) |
| shadowed by an intermediate override | **38** |
| overrides the derivation reproduces exactly ⇒ deleted | **10** |
| overrides that LOOK redundant but would REGRESS if deleted | **3** — `SliderWdgt` falls to `CircleBoxWdgt`, `DividerWdgt` to `"rectangle"`, `SpreadsheetWdgt` to `FrameWdgt`'s `"window"` |
| deliberate overrides kept | 44 literal + 10 computed |

⭐ **Deleting a redundant intermediate override is worth more than deleting a leaf one, because it
UNSHADOWS descendants.** `PanelWdgt`'s `"panel"` was exactly its own derivation and was also the
answer given by `CanvasWdgt`, `StringFieldWdgt`, `FridgeWdgt` and ten others; `BoxWdgt`'s `"box"` was
what `PointerWdgt` called itself. Removing those three (`PanelWdgt`, `BoxWdgt`, `RectangleWdgt`) let
17 descendants derive their own names.

**Three classes state a name because the camelCase split mangles it** — `Plot3DCreatorButtonWdgt` and
`FridgeMagnets3DCanvasWdgt` (the split reads `3` and `D` as separate humps) and `Pencil2IconWdgt` (the
digit stays glued). The four `Arrow<N|S|E|W>IconWdgt` and `ChapterXIconWdgt` derive a bare letter
(`"arrow e icon"`) and are left: they are icon leaves whose name rarely surfaces, and the reading is
still true.

**Verified in the running world** (`.scratch/w7-derived-name-probe.js`), not from the source: the
meta-system does resolve `constructor.name`, and **0 of 258 classes still answer `"generic widget"`.**
⚠ That probe reads each class through a bare `Object.create(prototype)`, so the classes whose override
is COMPUTED from instance state necessarily throw in it — a probe artifact, not a finding.

#### The capitalisation pass — owner-confirmed, landed same day

Split out of the mechanism change above because it is a **taste call** (which names are descriptions
and which are proper nouns), then confirmed by the owner and applied: 15 overrides lowercased to the
house style, and these left capitalised because they are NAMES — `"Desktop"`, `"Bin"`, `"Shelf"`,
`"Fizzytiles"`, `"Patch Programming"`, the four `"… Maker"`s, plus `"3D plot"`, `"HH:MM:SS label"` and
the two quoted-icon names.

⭐ **It was not just a re-casing.** Lowercasing made **8 of the 15 identical to what the derivation
produces**, so they stopped being overrides at all and were deleted — and one of those, `DividerWdgt`,
only became deletable because W7 had already removed `RectangleWdgt`'s override from its chain. ⇒ **A
cosmetic normalisation can turn a "deliberate" override into a redundant one; re-run the resolver
after the edit rather than before.**

⚠ **And the inheritance trap fired a second time, in the same shape:** lowercasing `GenericPanelWdgt`
to `"generic panel"` made it look identical to its derivation, but it **extends `FrameWdgt`** — so
deleting it would have answered `"window"`. Kept, for the same reason `SpreadsheetWdgt` is.

Verified in the running world (`Fizzygum-tests/.scratch/w7-capitalisation-check.js`): all 27 touched
or must-not-touch classes resolve exactly as intended. ⚠ Five of them live in the `video-player` PART,
so a default build legitimately has none of them — that leg was covered by a second run against
`--includeVideoPlayer` rather than left as an unchecked `<absent>`.

**W8 — constructor shapes.** *Owner-gated* (D5), and the largest blast radius. Order:
`ButtonWdgt` (12 → essentials + `opts`) → `LabelButtonWdgt` (17 → essentials + `opts`, with
`MenuItemWdgt`/`MenuItemSpec`) → retire the three `iconToolTipMessage` shadow fields by taking
`toolTipMessage` plainly and assigning it guarded. Recapture budget: **0** (a pure signature change
must not move a pixel); any diff is a faithfulness bug in the call-site rewrite.

**W9 — make it stick.** Give each surviving convention a mechanism at the right severity tier
(`lint-and-static-checks.md` §3b: sound negative → hard gate; count-shaped smell → ratcheted stink;
heuristic → advisory census).
- **HARD GATE — `check-menu-actions.js`.** A `[@.]addMenuItem` call whose 3rd argument is a function
  literal (`(->` / `->` / `=>`), or whose 4th argument is a string literal, is *provably* wrong
  (`@target[<function>]`; `opts` is an object). Sound negative, zero false positives, and W1 makes it
  land green. Extend to `[@.]prompt` whose 3rd argument is not a string literal.
- **ADVISORY CENSUS — `census-widget-conformance.js`** (exit 0, `--json`): re-derives the survey's
  mechanical facets on demand — undeclared fields (mixin-aware, comment-stripped), missing
  `colloquialName`, constructor slot counts, `_reLayout` prologue copies, pin-setter shapes, classes
  with no header comment. This is what turns the survey from a one-off into something re-runnable, and
  it is the correct tier: every one of those signals needs a human to confirm.
- **RATCHET** the census's two most objective headline counts (undeclared fields; prologue copies)
  the way `check-stinks.js` ratchets, so the numbers cannot climb back.
- ⚠ Do **not** gate `colloquialName` coverage, `super`-in-menu-overrides, or the setter shapes:
  each has a legitimate exception in the tree today (`ScrollPanelWdgt`'s conditional forward,
  `NumberPromptWdgt`'s pure sink), so a gate would cry wolf and train people to reach for
  `--noSyntaxCheck`.

**W10 — closeout.**
1. Sync `architecture/widget-authoring-guidelines.md`: any rule that turned out to have a real
   exception gains it; any rule that gained a gate flips `[convention]` → `[gated — <file>]`.
2. Add a **"state at close"** delta table to the survey (never rewrite its measurements — it is a
   dated snapshot; append).
3. `lint-and-static-checks.md`: add the W9 gate + census rows.
4. `git mv` this plan to `archive/`, stamp the status, add the `archive/INDEX.md` line, remove the
   `BACKLOG.md` lines for everything that landed and rewrite the rest as residual items.
5. Full `fg gauntlet` + `fg homepage`.

---

## 6. Verification protocol (every phase)

- `fg lint` (≈2 s) → `fg presuite` (≈3.5 min) after EVERY shape, before moving on.
- **Byte-identity is the default acceptance.** A screenshot diff in a phase whose recapture budget is
  **0** means the shape is wrong ⇒ revert. Never recapture past a diff you did not predict.
- Where a phase has a budget, the budgeted tests are named in §10 *before* the work, from W0.3 — a
  test that recaptures without being on the list is a finding, not a formality.
- **Two-falsification stop rule:** if two shapes of the same item fail, your model of the code is
  wrong. Stop, write the evidence into §10 as verdict 3, move on. Do not try a third variant.
- Arc end: full `fg gauntlet` (dpr 1 + dpr 2 + WebKit + apps + tier-naming + notification-settle +
  capstone + paint-readonly) + `fg homepage`.
- A phase that changes anything a snapshot carries (W4, W6, W8) also runs the serialization
  round-trip: `cd ../Fizzygum-tests && node scripts/serialization-roundtrip-headless.js`.

---

## 7. Reproducing the work lists

Run from `Fizzygum/`. This is the scanner the plan's counts come from; it is mixin-aware and
comment-stripping (§0.5), which the survey's first pass was not.

```python
# python3 - <<'PY'   (from the Fizzygum repo root)
import os, re
src = {}
for dp, _, fn in os.walk('src'):
    for f in fn:
        if f.endswith('.coffee'):
            src[os.path.join(dp, f)] = open(os.path.join(dp, f), encoding='utf-8').read()
cls = {}; mix = {}
for p, s in src.items():
    m = re.search(r'^class\s+(\w+)(?:\s+extends\s+(\w+))?', s, re.M)
    if m: cls[m.group(1)] = (m.group(2), s)
    m = re.search(r'^(\w+Mixin)\s*=', s, re.M)
    if m: mix[m.group(1)] = s
def strip(s):  # naive, same trade the repo's own scanners make
    return '\n'.join(l if l.find('#') < 0 else l[:l.find('#')] for l in s.split('\n'))
def chain(c):
    out = [c]
    while cls.get(c, (None,))[0]: c = cls[c][0]; out.append(c)
    return out
def decls(n):
    if n in cls: return set(re.findall(r'^  ([A-Za-z_]\w*)\s*:\s*(?!\(|->|=>)', cls[n][1], re.M))
    if n in mix: return set(re.findall(r'^\s{4,}([A-Za-z_]\w*)\s*:\s*(?!\(|->|=>)', mix[n], re.M))
    return set()
def mixinsOf(c): return re.findall(r'@augmentWith\s+(\w+)', cls.get(c, (None, ''))[1])
for c in sorted(cls):
    if 'Widget' not in chain(c)[1:] and c != 'Widget': continue
    ch = chain(c); s = strip(cls[c][1])
    declared = set()
    for a in ch + sorted({m for x in ch for m in mixinsOf(x)}): declared |= decls(a)
    written = set(re.findall(r'@([a-z_]\w*)\s*=(?!=|>)', s))
    m = re.search(r'^  constructor:\s*\(([^)]*)\)', s, re.M | re.S)
    params = set(re.findall(r'@([A-Za-z_]\w*)', m.group(1))) if m else set()
    miss = sorted(x for x in (written | params) if x not in declared)
    if miss: print(f'{c:44s} {len(miss):2d}  ' + ', '.join(miss))
# PY
```

Other lists: `grep -rn '^  _reLayout:' src` (W5) · `grep -rn '^  colloquialName:' src` (W7) ·
`grep -rn 'addMenuItem .*(->' src` (W1) · `grep -rn '^  set[A-Z]\w*: *(' src` (W6).

The **recapture-risk lists** of §11.1, run from `../Fizzygum-tests/tests`. ⚠ Comments must be
stripped: the macros carry long explanatory headers, and matching them inflates the inspector list
from 18 to 43 — a list that over-reports is worse than none, because it stops distinguishing the
tests that will actually move.

```python
# python3 - <<'PY'   (from Fizzygum-tests/tests)
import os, re
tests = sorted(d for d in os.listdir('.') if os.path.isdir(d))
def code(d):
    out = []
    for f in os.listdir(d):
        if f.endswith('.js'):
            for l in open(os.path.join(d, f), encoding='utf-8', errors='replace'):
                out.append(l.split('#')[0])          # executable text only
    return '\n'.join(out)
pat = {
  'inspector': r'openInspector|InspectorWdgt|"inspect"|\binspect\b\s*\(',
  'titlebar':  r'FrameBarWdgt|titleBar|\.label\b|setTitle',
  'menu':      r'rightClick|contextMenu|MenuWdgt|rightMouse|openMenu',
}
for k, p in pat.items():
    hits = [t for t in tests if re.search(p, code(t), re.I)]
    print(f'=== {k}: {len(hits)} ==='); [print('   ', t) for t in hits]
# PY
```

---

## 8. Landmines (each bought with evidence — do not rediscover)

- **⚠⚠ Mixin clobber (§3.4).** A class-body field added to a class whose chain mixes the same name in
  silently overrides the mixin value, because `augmentWith` is emitted before class-body fields. The
  survey's own first pass fell into the adjacent trap (reporting mixin-injected fields as
  undeclared). Check every W4 addition.
- **`super` is meta-compiled** — textual equivalence is not dispatch equivalence, and a trailing space
  after a bare `super` once silently dropped forwarded arguments (the reason
  `check-trailing-whitespace.js` exists). Relevant to W3, W5, W8.
- **CoffeeScript binds a subclass's constructor params only AFTER `super()`** — a base constructor
  calling a virtual builder sees them unbound. This is why `ScrollPanelWdgt` uses `_buildScrollFrame`
  and `MenuRowsPanelWdgt` uses `_buildMenuLabel`. Relevant to W8.
- **A `@param` assigns unconditionally** and shadows the class default — the reason the three
  `iconToolTipMessage` shadow fields exist (W8), and a live hazard whenever W4 adds a default to a
  class that also takes that field as a `@param`.
- **Adding a property to a class some test INSPECTS is not pixel-free** (§3.5 — reworded 2026-08-16
  from "adding properties to a base class", which is backwards). `InspectorWdgt.showingInherited`
  defaults to **false**, so a member list shows the inspected class's OWN members: a pull-up to a
  base is inspector-free (W4b's `Widget.toolTipMessage`, 11 writers, 0 recaptures), while a
  declaration on the inspected class itself costs (W4a's `ButtonWdgt.faceWidget`, 20 references).
  Predict from §11.1's list of which class each test opens, not from how many classes inherit.
- **`colloquialName` is drawn** (§3.6).
- **The 2026-07-02 meaning swap:** in history before that date, `_applyExtent` names what is today
  `_applyExtentBase`. Reading old commits around the layout code will mislead otherwise.
- **`world.openPopUps` is pruned LAZILY, not every cycle** (corrected 2026-08-16; the claim here was
  "swept every cycle"). The pruning lives inside `WorldWdgt.mostRecentlyCreatedPopUp` (~:687), which
  `ActivePointerWdgt` asks on a CLICK — `Serializer.coffee` ~:313 already calls it "the lazy orphan
  pruning". It also prunes on a different predicate: `isOrphan()` ("my root is neither the world nor
  the hand"), which is broader than `destroyed`. So W2's `PopUpWdgt` half still fixes a latent tier
  violation rather than a visible leak — but **the pruning is NOT redundant with it and must not be
  deleted**: a pop-up can leave the tree without dying, and nothing else notices.
- **⚠⚠ When you diff a dumped failure by hand, match the reference's `systemInfoHash` and assert
  exactly ONE match** (measured 2026-08-16, W4c batch 3). `.scratch/<test>/dpr1/` **persists across
  sessions**, so it can hold several dumps of the same `image_N` under different `systemInfoHash`
  values; a `readdirSync().find(x => x.includes('_image_1-'))` picks whichever sorts first, which
  may be a stale artifact from another run. Doing exactly that turned a 554-pixel, single-row,
  one-transition colour flip into an apparent **19,253-pixel, 56-transition, whole-pane** diff and
  nearly triggered a revert of a correct change. Filter on the reference's own hash, and throw if
  the match count is not 1 — a hand-rolled comparison that silently compares the wrong pair is
  worse than no comparison. (The suite itself is immune: it matches on the raw-pixel `dataHash`.)
- **⚠⚠ Adding any named METHOD to `Widget` is not pixel-free either, and the §3.5 rule does not cover
  it** (measured 2026-08-16, W5). The meta-system installs class-body members with a plain
  `@::[key] = value` (`Object::addInstanceProperties`), so they are **enumerable**, and
  `InspectorWdgt.showingMethods` defaults to **true** — so `_filterProperties`' `for property of @target`
  lists prototype METHODS, not just fields. §3.5's "predict from which class a test opens" holds only
  while `showingInherited` is false (its default); a test that TOGGLES it on sees the whole chain, and
  a `Widget`-level addition shifts its list. Exactly one test does this today —
  `macroDuplicatedInspectorDrivesCopiedTargetOnly` ("show inherited properties, so 'alpha' is
  reachable") — and W5's two new `Widget` methods cost it 4 references. ⓘ The diff is NOT a clean row
  shift: that macro reaches the row by dragging the scroll HANDLE, whose mapping is quantized to
  scrollbar pixels, so a changed member count lands the pane on different rows entirely. The macro
  selects by MEANING (`m.text == "alpha"`), so a recapture cannot blind it — its own comment records
  the same hazard from the kept-spec arc.
- **⚠⚠ A gate that scans BY METHOD NAME goes blind the moment you move code into a differently-named
  method — silently, and while still reporting success.** `check-relayout-bounds-first.js` scans only
  bodies named `_reLayout`; W5's hook extraction would have reclassified all 16 converted classes from
  its `apply-first` bucket into "positions no children", i.e. out of coverage, with the gate still
  printing OK. Extend the gate in the SAME commit as the motion (W5 added a `template` bucket plus a
  hook-side rule). Same family as the `coffee-method-header` blind spot that hid 45 methods from six
  gates.
- **`implementsDeferredLayout` is `@_reLayout != Widget::_reLayout`** — a literal identity test, read at
  four sites (`Widget` ~:821 and ~:1215, `FrameWdgt` ~:1091, `ScrollPanelWdgt` ~:477) and explicitly
  PINNED by five classes. So a refactor may not simply delete a `_reLayout` override, however empty it
  becomes: doing so flips the predicate for that class. W5's converted classes keep a two-line
  delegating override for exactly this reason.
- **Never recapture your way past a diff** in a zero-budget phase — but check first that the budget was
  ACHIEVABLE. W5's stated zero was not: any hook on `Widget` adds a name, and the landmine above makes
  a name visible. Establish the cause with an A/B (convert ONE class the failing test never touches —
  if it still fails, the cause is the base-class addition, not the code motion), then put the corrected
  budget to the owner rather than either recapturing quietly or abandoning the phase.

---

## 9. Owner decisions

| # | Decision | Recommendation |
|---|---|---|
| D1 | **W3** — add the base menu block to `PointerWdgt` and `IconicDesktopSystemScriptShortcutWdgt`? (adds layout entries; recaptures their menu shots) | **Yes** — the omission looks accidental (both open with `menu.addLine`), and the entries are the base affordance every other widget has. |
| D2 | **W4b** — for each of the eight repeated fields, `Widget` / family base / leave? | **Family base wherever one exists**; `Widget` only for `toolTipMessage` (its reader is already on `Widget`), accepting the inspector recapture. `target` stays per-family — see the corrected reason below. ✅ Its deferral of `target`/`callback` to the connector arc's P9 is DISCHARGED: P9 landed 2026-08-16 and all 11 fields are declared (baseline 9/11 → 0). |

✅ **D1 and D2 DECIDED by the owner, 2026-08-16.** D1: yes (W3 landed). D2: the recommended split —
`toolTipMessage` → `Widget` **together with** deleting the 33 `iconToolTipMessage` declarations and
their two copy lines (§2.8); `title` → `IconicDesktopSystemShortcutWdgt`; `seed` →
`GraphsPlotsChartsWdgt`; `icon` → the two family bases; `cornerRadius` declared per class (the three
do not extend `BoxWdgt`); `target` **left alone** pending the connector arc's P9; `callback` dropped
from the table, now below threshold. The inspector recapture is accepted.

⚠ **D2 correction, measured 2026-08-16 (W0).** The original reason given for keeping `target`
per-family — "a `Widget.target` would collide conceptually with `ControllerMixin`'s" — is **false**:
`ControllerMixin` declares NO fields at all (its own comment says "class properties here: none"); it
only assigns `@target = theTarget` inside `setTargetAndActionWithOnesPickedFromMenu`. The conclusion
survives on better evidence: **`target` is already declared independently by 12 classes**
(`HandleWdgt`, `PaletteWdgt`, `PromptWdgt`, `ButtonWdgt`, `ListWdgt`, `CaretWdgt`, `SliderWdgt`,
`MenuWdgt`, `MenuItemSpec`, `MenuRowsPanelWdgt`, `InspectorWdgt`, `FanoutPinWdgt`) on top of the 9
that write it undeclared — 21 classes in which a caret's target, a menu's target, a handle's target
and a wire's target are four different concepts. That is exactly what the sibling arc's
[P9](connector-ubiquity-and-reflection-plan.md) proposes to SPLIT, so pulling the name up to
`Widget` now would entrench the ambiguity P9 exists to remove. **Leave `target` alone until P9
decides the vocabulary.**

Mixin-clobber pre-check (landmine §8) for the other seven: **none** of `toolTipMessage`, `icon`,
`cornerSpec`, `title`, `callback`, `cornerRadius`, `seed` is declared by any mixin, so a class-body
declaration cannot clobber a mixin value for any of them. The landmine still applies to whatever W4c
proposes.
| D3 | **W6b** — add idempotence guards to the B/C/D setters? (behaviour change: a wired circuit stops re-firing on an equal value) | **Yes, but as its own commit**, after W6a is green, with the patch-programming + converter macros run explicitly. |
| D4 | **W7** — is the `"generic widget"` label worth a recapture round? | **Yes for the ~30 substantial non-icon classes**, no for the icon leaves (their colloquial name rarely reaches a title bar). ⚠ **The premise changed at execution:** the answer assumes the names are HAND-WRITTEN, so each one costs. A DERIVED default costs nothing per class, which is why all 162 got a true name rather than the ~30 — and the recapture round stayed small anyway (16 tests), because only the classes a test actually TITLES on screen move pixels. See §2.7 "As landed". |
| D5 | **W8** — convert `ButtonWdgt`/`LabelButtonWdgt` to options objects? | **Yes, last**, and only if W1–W6 landed clean: it is the highest-churn item and the one most likely to reveal a call site nobody knew about. |
| D6 | **F26 colours** — should `PreferencesAndSettings` become a real theme surface (40 classes hard-code channel triples)? | **Park** until there is a second theme to serve. Recorded in §10. |

---

## 10. Parked — recorded so they are not re-proposed

- **F2 — the `Simple*` prefix's two meanings.** A rename touches identifiers, filenames and
  serialization, and menu/hierarchy labels strip `Wdgt`, so it is not pixel-free. Low value against
  that cost. Revisit only if a `Simple*` class is being renamed for another reason.
- **F7 — five geometry verbs in constructors.** The right output is a *stated criterion*, which
  `widget-authoring-guidelines.md` §3.6 now has. Converting existing sites is not worth a suite run
  each; convert opportunistically when a constructor is touched for another reason.
- **F11 — the 32 constructor-assigned appearances.** The factory form buys an override point; a leaf
  class that nothing subclasses gains nothing. Convert only when a class grows a subclass.
- **F12 — `isTransparentAt` on the widget vs the appearance.** Doc-only: the guidelines state the
  rule ("hit-testing follows the shape"); no code change proposed.
- **F23 — always-on stepping subscriptions.** A performance question (an idle widget costs a slot in
  the once-per-cycle walk), not a correctness one, and `Widget._destroyNoSettle` already keeps the set
  honest. Needs a measurement before it needs a change.
- **F26 — hard-coded colours** (D6).
- **F3 — missing header comments.** Not a phase: a drive-by rule. Any file this arc opens gets its
  header comment before the commit.

---

## 11. Status ledger

- **2026-08-14 — AUTHORED (this doc).** No code changes. Companion docs committed the same day:
  `measurements/widget-practices-survey-2026-08-14.md` (evidence) and
  `architecture/widget-authoring-guidelines.md` (target state). Survey corrected in the same commit
  as this plan for the two §0.5 findings (F9 → 52 classes / 124 fields; the eight repeated fields).
- **2026-08-16 — W0 DONE.** Baseline `fg gauntlet` green on `972e5050` (15/15 legs, 353 s; suite
  **294** SystemTests). Counts re-derived with the §7 scanner and this doc corrected: F9 is **51
  classes / 120 fields**, not 52/124, and W4b is **46** occurrences, not 48. The whole delta is the
  prompt-family constructor conversion (`6c5e616f`, P4 of the constructor-conformance arc):
  `ErrorsLogViewerWdgt` leaves the list entirely (`callback`, `msg`, `target` now declared) and
  `CodePromptWdgt` loses `msg`. W4a (11 classes / 13 fields) and W4c are unchanged.
- **W1 · ALREADY CONVERGED — landed by another arc, no work needed here.** `6c5e616f` converted the
  three `SliderWdgt` entries to string actions with `@` as target, and the three `@prompt` calls to
  `(msg, target, action, opts)` reading the title as `menuItem.parent.title`. It resolved the handler
  signature as `(menuItem)` — NOT the `(ignored, ignored2, menuItem)` this plan predicted in §2.1:
  the menu-action wiring arc established that dispatch slot 1 IS the menu item. ⚠ §2.1's proposed
  form is therefore wrong in its signature; trust the landed code, not the snippet. Recaptures: 0.
- **W2 · CONVERGED, 2026-08-16.** Both overrides moved from the public wrapper to the core:
  `SimpleSpreadsheetWdgt.destroy` → `_destroyNoSettle`, `PopUpWdgt.destroy` → `_destroyNoSettle`,
  both `super`-first like `IconicDesktopSystemShortcutWdgt`. Recaptures: **0** — `fg presuite`
  294/294; `fg gauntlet` 15/15 legs, 333 s, dpr1 + dpr2 + webkit all 294/294 with 0 failed and 0
  geometry violations; `fg homepage` OK. Two findings from doing it:
  - The sheet's `world?.keyboardEventsReceivers?.delete @` was **redundant** and is gone —
    `Widget._destroyNoSettle` already does that unconditionally, and its own preceding line would
    have thrown first if `world` were absent, so the `?.` guards bought nothing. The surviving body
    is the cell-edge sweep alone.
  - `src/spreadsheet/CLAUDE.md` named `destroy` as the home of node death; updated in the same
    commit.
  The `@model?` guard needed no strengthening: `@model` is assigned in the constructor and never
  cleared, `forEachCell` is a `Map.forEach` (no-op when empty), and the guard already covers the
  `Object.create` deserialization window. `WorldWdgt`'s per-cycle `openPopUps` sweep is untouched —
  banked as a follow-up, per §8.
- **W3 · CONVERGED (code), but the new affordance is UNCOVERED — 2026-08-16.** D1 approved.
  `PointerWdgt` (~:66) and `IconicDesktopSystemScriptShortcutWdgt` (~:25) now open with `super`,
  the house shape. `ScrollPanelWdgt` left alone as directed — it calls `super` in its `else` branch
  and delegates to the single child when `takesOverAndMergesChildrensMenus`. Verified the scope: a
  body scan of all 21 `addWidgetSpecificMenuEntries` definitions finds exactly five without `super`,
  and the other three are correct (`Widget` is the base; `DivisionStackLayoutSpec` and
  `VerticalStackLayoutSpec` are specs, not Widgets).
  Recaptures: **0** — predicted and confirmed. The base block adds nothing unless the widget has an
  active stack/division `layoutSpec` or hosts division children, which a desktop-resident pointer or
  script shortcut does not; so every existing menu screenshot is unchanged.
  ⚠⚠ **That same fact means the gates prove NO REGRESSION and do not prove the FIX.** Nothing
  exercises the added entries: the suite has **zero** references to either class (all 47 apparent
  `PointerWdgt` hits are `ActivePointerWdgt`), and `menu-click-sweep-headless.js` builds menus only
  for `world` plus 14 named `REPRESENTATIVES`, which include neither. The change is correct by
  construction — the base block is generic over `@layoutSpec`, and the only reason it never ran was
  the missing `super` — but that is reasoning, not measurement.
  **Follow-up worth taking:** add both classes to the sweep's `REPRESENTATIVES` (its own comment says
  a root that fails to build is a coverage gap worth reporting), or author a macro that drops one
  into a division stack and screenshots the menu. Until then W3 is a code fix with no witness.
- **W4a · CONVERGED — 2026-08-16.** All 11 classes / 13 fields declared, every one `: undefined`
  following `BoxWdgt`'s precedent (`cornerRadius: undefined` declared even though the constructor
  defaults it to 4). The §7 scanner drops 51 classes / 120 fields → **40 / 107**, exactly −11 / −13.
  Mixin-clobber pre-check (landmine §8) run first: no mixin declares ANY of the 13, so no
  declaration could clobber a donated value.
  Two of the thirteen are declared `undefined` for a REASON, not just convention, and the comments
  say so: `Example3DPlotWdgt.edges` and `PaintToolbarWdgt.queue` are both arrays built lazily/in the
  constructor — a prototype `[]` would be ONE array shared by every instance, and `queue`'s lazy
  build keys off `if !@queue?`. `InspectorWdgt.resizer` likewise must stay undefined through its own
  `add`, which its existing comment already documents.
  **Recaptures: 2 tests / 20 references (40 files) — the FIRST non-zero budget of this arc.**
  `ButtonWdgt.faceWidget` is a member, so `ButtonWdgt`'s class-inspector member list gained one row,
  and both mixin-donor tests screenshot exactly that list.
  ⭐ **The diff was confirmed benign by looking, not by assuming**: `faceWidget` inserts
  alphabetically after `doubleClickAction`, everything below shifts one row, the pane re-clips its
  last row — and the selected member is unchanged, because the macros select by LABEL
  (`selectInspectorRow_InputEvents_Macro ci, "color_hover"`), not by index. Had they selected by
  index, a recapture would have baked in a test that silently checks the wrong member.
  Recaptured with `fg recapture --auto`: verdict **✅ RECAPTURE COMPLETE**, suite green at dpr 1 and
  dpr 2, nothing else stale.
  ⛔ **A scale warning issued here — "`toolTipMessage` on `Widget` puts a row in EVERY widget's
  inspector list, budget for most of §11.1's 18" — was WRONG, and W4b measured 0.** The reason is
  worth keeping: `InspectorWdgt.showingInherited` defaults to **false**, so a member list shows the
  inspected class's OWN members only. See the rule under W4b.
- **W4b · CONVERGED — 2026-08-16.** D2's placements landed in two gated batches; the scanner goes
  40 classes / 107 fields → 33 / 88 → **23 / 77**. `target` (9) and `callback` (2) are deliberately
  NOT declared, per D2.
  - *Batch 1 — four fields, SEVEN declarations, 0 recaptures.* The families nest more tightly than
    §2.4 assumed, so two of D2's placements are corrected here:
    **`title` goes on `IconicDesktopSystemLinkWdgt`, not `IconicDesktopSystemShortcutWdgt`** —
    `IconicDesktopSystemWindowedAppLauncherWdgt` is a SIBLING of that class, not a subclass, so the
    plan's home would have missed one of the five writers. And **`icon` needs only two homes**
    because `IconicDesktopSystemLinkWdgt extends WidgetHolderWithCaptionWdgt`: declaring on
    `WidgetHolderWithCaptionWdgt` covers 5 of the 8 writers, `GenericCompositeIconWdgt` the other 3.
    `seed` → `GraphsPlotsChartsWdgt` (3) and `cornerRadius` per class (3, none extends `BoxWdgt`) are
    as planned.
  - *Batch 2 — `toolTipMessage` on `Widget`, plus retiring `iconToolTipMessage`, 0 recaptures.* One
    declaration on `Widget` cleared all 11 writers. The shadow family is gone with it: 33 subclass
    declarations renamed `iconToolTipMessage:` → `toolTipMessage:` (anchored rewrite, whole diff
    read back — the de-indent trap), and both base classes lost their `iconToolTipMessage: undefined`
    plus their `@toolTipMessage = @iconToolTipMessage` copy line. `grep iconToolTipMessage src` is
    now empty. ⓘ `CreatorButtonWdgt extends Widget`, NOT `ButtonWdgt` — which is why it needed the
    shadow at all, and why a `Widget`-level declaration is what retires it.
  - *Batch 3 — `cornerSpec` (5), 0 recaptures.* ⚠ This one was **omitted from the D2 recommendation
    as put to the owner** and had to be caught afterwards, so W4b briefly stood "complete" while one
    of the eight fields was untouched. Declared PER CLASS, matching `cornerRadius`: four of the five
    writers extend `Widget` directly and `BinOpenerWdgt` extends `IconicDesktopSystemLinkWdgt`, so
    there is no family base to pull up to, and a niche layout knob does not belong on the root.
    ⭐ **Lesson: a decision put to the owner must be checked against the table it answers.** The
    eight-row table was the spec; the recommendation covered seven rows and nothing flagged it.
  ⭐⭐ **AND THE TWO WAYS A DECLARATION SHOWS UP, which are different pixels.** `cornerSpec` cost one
  test (`macroNakedInspectorRendersResizesAndEdits`, which inspects an `AnalogClockWdgt` INSTANCE),
  and the diff was not a moved row: all 150 changed pixels were one colour flip, `0,0,180` → `0,180,0`.
  `InspectorWdgt._filterProperties` colours members most-general-first, and the specific criterion is
  `@target.constructor.prototype.hasOwnProperty(element)` — **blue means "not declared on the class",
  green means "declared"**. So:
  - an **OBJECT** inspector already lists the field (the constructor made it an own property); the
    declaration flips its colour blue → green;
  - a **CLASS** inspector (`ClassInspectorWdgt X.prototype`) does not list it at all until it is
    declared; the declaration ADDS A ROW (W4a's `faceWidget`).
  ⭐ That colour flip is the inspector reporting the fix, so the recapture is EVIDENCE the phase
  worked — §2.4's whole premise is that an undeclared field is invisible to the inspector.
  ⭐⭐ **THE RULE THIS PHASE BOUGHT — a base-class declaration is inspector-FREE; a declaration on the
  class being INSPECTED is what costs.** `InspectorWdgt.showingInherited` defaults to **false**, so a
  member list shows own members only. That is why `Widget.toolTipMessage` (a base, 11 writers) cost
  ZERO references while W4a's `ButtonWdgt.faceWidget` (the class the two mixin-donor tests actually
  inspect) cost 20. ⛔ It also means landmine §3.5 as written — "adding properties to a base class is
  not pixel-free for inspector tests" — is **backwards for a pull-up**, and should be read as: adding
  to a class some test INSPECTS is not pixel-free. Predict recapture from *which class a test opens*,
  not from how many classes inherit the field.
- **W4c · CONVERGED — 2026-08-16.** The scanner goes 20 classes / 72 fields → 19 / 56 → 10 / 12 →
  **9 / 11**, in three gated batches. Every field `: undefined`, no mutable `[]`/`{}` anywhere.
  ⭐ **The mixin-clobber pre-check is INHERENT to the §7 scanner and need not be run separately:**
  the scanner unions the whole chain's declarations *with every mixin's* before reporting a field
  as undeclared, so a field it reports is by construction donated by no mixin. (It was still run
  explicitly for `WorldWdgt`, and agreed.)
  - *Batch 1 — `WorldWdgt` alone, 16 fields, 0 recaptures.* Done first and alone because it is the
    one class whose declarations could disturb the `RESETWORLD_INCOMPLETE` ratchet. **They cannot,
    and the reason is structural:** `WorldTestSupport._fingerprintWorldStateNoSettle` sweeps own
    properties AND the whole prototype chain, and reads each name as its EFFECTIVE value rather
    than as "does the world own it" — its own comment says *own-ness is not state, the value is*.
    All sixteen are assigned in the constructor or during boot, so each is already an own property
    when the pristine fingerprint is taken at the end of the first `resetWorld`; a prototype
    declaration underneath an own property changes no value, adds no name and shifts no summary.
    The harness's `WorldTestSupport`, which copies members onto this prototype at boot, declares
    none of the sixteen either. Placed by family (render-canvas pair, island buffer cache, the
    hidden keyboard input element, the pointer/caret/edit state, the four shipped collaborators
    plus the two optional ones, `isDevMode` beside `isIndexPage`), not in one block.
  - *Batch 2 — nine classes, 44 fields, 0 recaptures.* `SimpleSpreadsheetWdgt` 16, `CellWdgt` 7,
    `FrameWdgt` 6, `SheetHeaderCellWdgt` 4, `FridgeMagnetsWdgt` 4, `PlotWithAxesWdgt` 3,
    `SpeechBubbleWdgt` 2, `ToolTipWdgt` 1, `WidgetHolderWithCaptionWdgt` 1. Two classes documented
    each field with a trailing comment on its constructor assignment (`CellWdgt`,
    `SheetHeaderCellWdgt`); those descriptions moved up to the declarations, since the declaration
    is the field's documented home and the same sentence should not sit in two places.
    ⭐ `SimpleSpreadsheetWdgt`'s seven colours MUST stay `: undefined` and be built in the
    constructor — a class-level `Color.create` would run at class-definition time, before `Color`
    loads. The constructor already carried that warning; the declaration now repeats it where
    someone tempted to add a "real" default will read it. Same for `PlotWithAxesWdgt.plot` and
    `WidgetHolderWithCaptionWdgt.labelContent`, which are constructor `@param`s: the declaration is
    documentation, never a default, because a `@param` assigns unconditionally (landmine §8).
  - *Batch 3 — `AnalogClockWdgt.synchronisedStepping` alone, kept separate because its recapture was
    PREDICTED rather than hoped to be zero.* **1 test / 4 references** (`fg recapture --auto`:
    ✅ RECAPTURE COMPLETE, suite green at dpr 1 and 2), and the pixels are exactly what §2.4's
    premise says they should be: **554 changed pixels over the two shots, ONE transition family,
    `0,0,180` → `0,180,0`, confined to a single 11px row of the member list** (the `0,0,97` and
    `0,0,162` pairs are that same text's anti-aliased edges). `image_0` matched and was left alone.
    ⭐ The row moves COLOUR and not POSITION, and `_filterProperties` says why: its
    `!showingInherited` filter is `prototype.hasOwnProperty(prop) or (prop not of prototype)`, so
    the field passes BOTH before (let through as "stitched on, in no class") and after (let through
    as "own property of the immediate prototype"). A declaration can only ADD a row where the field
    was in neither category — i.e. on a CLASS inspector (W4a's `faceWidget`).
  ⭐⭐ **W4c had a FLOOR, not a zero: 9 classes / 11 fields, every one of them the `target`/`callback`
  pair, parked on the connector arc's P9 by D2.** ✅ **RETIRED 2026-08-16 when P9 landed** — the four
  shortcut classes' referent became `referencedWidget`, the inspector pair's subject became
  `inspectedObject`, and the five genuinely dispatch/tool `target`s were declared under that name.
  `census-widget-conformance.js`'s undeclared-field baseline is now **0/0**. The floor as it stood: `BinOpenerWdgt`,
  `ConsoleWdgt`, `PointerWdgt`, the four `IconicDesktopSystem*Shortcut` classes (`target` each),
  plus `CodePromptWdgt` and `IconicDesktopSystemWindowedAppLauncherWdgt` (`target` + `callback`).
  ⚠ **`callback` was re-examined and deliberately LEFT with `target`,** though D2 dropped it from
  the repeated-field table for being below the ≥3 threshold — which is a statement that it is not a
  shared-*placement* question, not that it is exempt from declaration. Both classes use it as the
  ACTION half of the pair, at one call-site shape (`@target[@callback].call @target, …`), and
  `IconicDesktopSystemWindowedAppLauncherWdgt`'s existing `appClassName` comment already treats the
  two as one thing ("undefined means `@target`/`@callback` are live"). Declaring half a pair that
  P9 will rename whole is worse than leaving it. (P9's text covers `@target` only — `callback`
  appears nowhere in `connector-ubiquity-and-reflection-plan.md` — so this is a coherence
  judgement, not a blocking dependency. Reversible in one commit if the owner prefers.)
- **W5 · CONVERGED — 2026-08-16.** `Widget` gains the own-contents template
  `_reLayoutWithOwnContents` plus the empty hook `_layOutOwnContents`; **16 classes** convert to a
  two-line `_reLayout` that delegates, with their varying pass moved into the hook. Net over 21 files:
  451 insertions / 526 deletions — the six-line prologue ×16 and, with it, the SAME three-line "apply
  my own bounds FIRST" rationale copy-pasted into all sixteen (48 lines of duplicated reasoning), now
  stated once on the template. `PatchNodeWdgt`'s private family hook `_layOutNodeContents` folds into
  the house one: its three subclasses override `_layOutOwnContents` directly and `Widget`'s empty base
  replaces the family's.
  - *The list was wrong, and the shape's real work was the measurement.* §2.5's "verbatim in 23" is
    **18** (corrected in place, with a table of how the five miscounted ones actually differ — one has
    no `@_markLayoutAsFixed()` tail, three apply their bounds INSIDE the repaint unit, one has no
    collapse guard at all). Of the 18, **`ButtonWdgt` and `ColorPickerWdgt` are deliberately NOT
    converted**: neither has a `_repaintAsOneUnit` unit, so the template would newly coalesce their
    damage to `@_fullChanged()` — strictly larger, pixel-identical in principle, but a behaviour change
    with no upside for a two-line and a one-line pass. `ButtonWdgt` has a second reason: it is the only
    one of the 18 whose contents pass reads `newBoundsForThisLayout` rather than its own just-committed
    frame, so it would need the hook to take an argument the other 17 ignore.
  - *The zero budget was unachievable, and the reason is structural* — see the two new §8 landmines.
    Any hook on `Widget` adds an enumerable prototype method, `InspectorWdgt.showingMethods` defaults
    true, and one test toggles `showingInherited` on. **Budget corrected to 1 test / 4 references by
    owner decision**, after an A/B established the cause: converting a SINGLE class that test never
    touches (`GenericShortcutIconWdgt`, a desktop icon; the scenario is a panel + rectangle +
    inspector) reproduces the failure identically. The code motion itself is inert — 293/294 with the
    full conversion, 0 geometry violations, paint audit green.
  - *The gate had to move with the code.* `check-relayout-bounds-first.js` scans only bodies named
    `_reLayout`, so the extraction would have dropped all 16 out of its coverage while it still printed
    OK. It now has a `template` bucket (a delegating `_reLayout` is apply-first by construction) and a
    hook-side rule (a `_layOutOwnContents` reading own geometry in a file whose `_reLayout` does NOT
    delegate is a violation), with its one honest blind spot stated in the header: a file defining the
    hook and NO `_reLayout` inherits one this line-scanner cannot follow. Counts move
    17 apply-first / 21 trivial → **4 apply-first / 16 template / 18 trivial** (totals conserved).
  - ⚠ `implementsDeferredLayout` is `@_reLayout != Widget::_reLayout` — which is why every converted
    class keeps the two-line override rather than dropping it (§8).
  Verification: `fg presuite` 293/294 (the one budgeted test) → `fg recapture --auto`
  **✅ RECAPTURE COMPLETE**, suite green at dpr 1 and dpr 2.
- W6a widen setters / W6b guards (D3): ☐ ☐
- **W7 · DONE — 2026-08-17.** DERIVED, not hand-written: 162 classes gain a true name, 10 redundant overrides deleted (3 unshadowing 17 descendants), 3 stated where the camelCase split mangles them. See §2.7 "As landed". Recapture: the inspector member lists + the window titles that showed "generic widget".
- W7 residue: the capitalisation pass + `representativeIcon` — both in `docs/BACKLOG.md`.
- W8 constructor shapes (D5): ☐
- **W9 · CONVERGED — 2026-08-16.** All three tiers landed, plus the three W5 residue items.
  - **HARD GATE.** §5 proposed `check-menu-actions.js`, which the menu-action wiring arc had already
    built — RULE 1 and RULE 2 were in place. What was missing is its `prompt` half, now added as
    RULE 1's **second door**: `prompt`/`textPrompt` take a `callback` that `PromptWdgt` hands to a menu
    item verbatim (`panel.addMenuItem "Ok", @target, @callback`), so it is the same slot one hop later
    and a function literal there is wrong by the same proof.
    ⚠ §5 said "extend to `[@.]prompt` whose 3rd argument is **not a string literal**" — deliberately NOT
    implemented that way. That would flag a variable holding a method name, which is legitimate and
    which RULE 1 already tolerates for `addMenuItem`; holding both doors to one standard is what keeps
    the gate a sound negative. ⭐ **The prompt door pays twice:** those callbacks are now visible to the
    RULE 3 unread-parameter ratchet too, taking coverage 255 → **269** verbs, and it immediately found
    three (`ClassInspectorWdgt.addProperty`, `InspectorWdgt.addProperty`/`renameProperty`) whose skipped
    slot was named `ignoringThis` rather than the house `ignored`. Renamed rather than widening the
    allowlist. ⚠ My first spelling of the rule keyed on the first ARGUMENT and matched only quoted/`@`
    openers, so it silently missed EVERY real call site (all open with an expression) — caught only
    because the plant test was run; the rule now keys on the RECEIVER.
  - **ADVISORY CENSUS — `census-widget-conformance.js`** (new): six facets, exit 0, `--json`. It
    independently reproduces both recorded floors (9 classes / 11 fields; 8 prologue copies), which is
    what makes it trustworthy as the survey's re-runnable half. Its mixin-awareness is PROVEN in both
    directions, not assumed: a planted `@color_hover` (donated by `HighlightableMixin`) is not
    reported, a planted `@notDonatedAtAll` is.
  - **RATCHET** — the same script's `--gate`, wired into `build_it_please.sh`. Verified by planting a
    violation of each ratchet and confirming the BUILD aborts on it (the first attempt aborted at the
    dead-method gate instead, which proved nothing — the plant has to sit in an existing method).
  - Advisory numbers worth having on record: **270** widget classes · 202 without `colloquialName`
    (W7's real scope) · **0** constructors over four positional slots without an options bag — the
    constructor arc closed that facet completely · 68 pin setters over 28 classes, arity 1→26, 2→38,
    3→4 (W6's table, re-derivable) · 148 without a header comment.
  - **W5 residue closed here.** (a) The `_reLayout` template's trailing `@_markLayoutAsFixed()` was
    MEASURED redundant and deleted — suite green AND the settle re-visit profile still empty, so it
    added no iterations; all sixteen copies had carried it. (b) `check-relayout-bounds-first.js` no
    longer trusts an inherited `_reLayout`: it reads every `class X extends Y` line and resolves the
    nearest ancestor that defines one, which moves the three `PatchNodeWdgt` subclasses from assumed-safe
    to verified (template bucket 16 → 19). Proven by planting a non-delegating base and watching all
    three fail. (c) The prologue-copy floor of 8 is now the ratchet's baseline, per W4c's precedent.
- W10 closeout: ☐

### 11.1 Recapture-risk lists (produced by W0, 2026-08-16)

Which SystemTests put each recapture-sensitive surface on screen. Derived by matching the macros'
**executable** lines only (comments stripped — the macros are heavily commented, and a naive grep
inflates the inspector list from 18 to 43). Regenerate with the snippet in §7; treat these as the
blast radius to check FIRST when a phase touches the surface, not as a proof of completeness.

- **(a) Inspector member list — 18 tests** (the surface D2/W4b's `Widget`-level declarations would
  disturb, per landmine §3.5): `macroAddEditSaveRenameRemoveProperty`, `macroAnalogClockInspectEdit`,
  `macroDuplicateComplexWidgetPaintsCleanly`, `macroDuplicatedInspectorDrivesCopiedTargetOnly`,
  `macroDuplicatedInspectorsCloseIndependently`, `macroInspectorRejectsDrops`,
  `macroInspectorResizingOKEvenWhenTakenApart`, `macroInspectorScrollbarUnplugged`,
  `macroInspectorWorkAreaEvaluatesCoffeeScript`, `macroMixinEditDonorAndOverride`,
  `macroMixinFieldEditDonorAndOverride`,
  `macroMovingSlidersSidewaysDoesntCauseContentToMoveSideways`,
  `macroMultilineTextInputScrollsWell`, `macroNakedInspectorRendersResizesAndEdits`,
  `macroPickingUpPartsFromInspector`, `macroResizingPristineInspector`,
  `macroSimpleDocumentHandlesOldInspector`, `macroWrappingTextFieldResizesOK`.
- **(b) Window title bar — 22 tests** (the surface W7/D4's `colloquialName` would disturb, per
  landmine §3.6): `macroCollapsingTiltedWindowKeepsTitleBarStill`,
  `macroDragEmbedRepositionNestedWindowStaysWithoutDwell`, `macroDuplicateComplexWidgetPaintsCleanly`,
  `macroDuplicatedInspectorsCloseIndependently`, `macroEditButtonLabelText`,
  `macroFontsMenuTickTracksSelection`, `macroMenuInWindowInScrollStackStaysLive`,
  `macroMenuPinnedByHeaderClick`, `macroMenuPinnedInScrollPanel`,
  `macroMenuShadowCorrectWhileAndAfterDrag`,
  `macroMenusAndSubMenusRemainOpenWhileDraggingMenusOnly`,
  `macroPinnedMenuKeepsCorrectShadowWhenBroughtToForeground`, `macroPromptShadowFollowsOnDrag`,
  `macroScrollPanelUpdatesCorrectlyOnCollapsingAndUncollapsingAndClosingWindow`,
  `macroSimpleDocumentHandlesOldInspector`, `macroSpreadsheetResizeViewport`,
  `macroSubMenuDroppedIntoPanelPinsItself`, `macroTiltedWindowDropRequiresDwell`,
  `macroWallpaperMenuTickTracksSelection`, `macroWindowWithAClockInAWindowConstructionTwo`,
  `macroWindowWithPlainWrappingTextResizingFollowsContentSize`,
  `macroWindowsNestedCollapsingUncollapsing`.
- **(c) Open widget context menu — 64 tests**, the largest blast radius, and the one W3 (D1) walks
  into: adding the base menu block changes the item COUNT, so a menu screenshot shifts height. Too
  long to inline; regenerate with the §7 snippet. ⚠ `macroCheckNumberOfItemsInWorldMenu` asserts a
  menu item count directly and will need attention in W3 even though it is a world menu.

## 12. Cross-links

- Evidence: [`../measurements/widget-practices-survey-2026-08-14.md`](../measurements/widget-practices-survey-2026-08-14.md)
- Target state: [`../architecture/widget-authoring-guidelines.md`](../architecture/widget-authoring-guidelines.md)
- Mechanics this arc must respect: [`../architecture/layering-naming-convention.md`](../architecture/layering-naming-convention.md) ·
  [`../architecture/layout.md`](../architecture/layout.md) ·
  [`../architecture/serialization-duplication-reference.md`](../architecture/serialization-duplication-reference.md) ·
  [`../architecture/widget-citizenship.md`](../architecture/widget-citizenship.md)
- Gate/severity policy + how to add a check: [`../architecture/lint-and-static-checks.md`](../architecture/lint-and-static-checks.md) §3b
- Closest precedent for the phase shape and the stop rule:
  [`../archive/menu-slider-ctor-conversion-plan.md`](../archive/menu-slider-ctor-conversion-plan.md);
  the constructor contract it locked in: [`../archive/all-constructors-settle-plan.md`](../archive/all-constructors-settle-plan.md)
- **Sibling arc, same territory:** [`connector-ubiquity-and-reflection-plan.md`](connector-ubiquity-and-reflection-plan.md)
  — the pin protocol seen from the value's side (the controller-is-a-view law). Overlaps W6; see §5.
- Case law on why census findings are questions, not instructions:
  [`../archive/duplication-triage-2026-07-15-hierarchy-round4.md`](../archive/duplication-triage-2026-07-15-hierarchy-round4.md) ·
  [`../archive/census-findings-triage-plan.md`](../archive/census-findings-triage-plan.md)

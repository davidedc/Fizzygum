# Constructor-parameter conformance — combing the codebase onto the head/tail convention

**STATUS: ACTIVE, not started.** Owner-gated per family.

**What this is.** The execution arc that brings `src/` onto the convention stated in
[`../architecture/constructor-and-parameter-conventions.md`](../architecture/constructor-and-parameter-conventions.md)
(positional head for identity, one trailing `opts` object for configuration, hole test
decisive). The convention doc is the law and the reference; this file is the work list, the
measured facts it rests on, and the order to do it in.

**Predecessor.** `archive/accidental-complexity-reduction-plan.md` **P5** ("Retire
positional-boolean/nil argument soup") landed families 1–4 — `addMenuItem`/`prependMenuItem`,
the `MenuWdgt` constructor, the `FrameWdgt` (then `WindowWdgt`) constructor, and the four
`_addNoSettle` overrides. It converted the *specific* families it named and never stated a
general rule, so everything it did not name stayed as it was. `SliderWdgt` (2026-08-14,
`21d5b64`) was the next one-off and is what prompted writing the rule down. This arc finishes
the sweep against a stated rule instead of case by case.

---

## 0. Measured facts (2026-08-14, this tree)

All figures from `src/` only; the sibling `Fizzygum-tests` repo is **not checked out in this
session** and must be re-measured before each family lands (§5).

- **139 constructors.** Arity histogram:

  | params | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 17 |
  |---|---|---|---|---|---|---|---|---|---|---|---|---|---|
  | count | 62 | 25 | 20 | 10 | 5 | 4 | 2 | 4 | 1 | 2 | 1 | 2 | 1 |

  117 at ≤4 (conformant or exempt); **22 at ≥5** — the work list.
- **51 lines** across **26 files** carry ≥2 consecutive bare `undefined` arguments (the
  proposed `positional-hole` stink baseline). **0** of them are in `events-input/`.
- 67 lines carry ≥2 consecutive bare `true`/`false`/`undefined`; **38** carry ≥3.
- Allocation-path evidence for the exemptions: **941** `new Point`, **94** `new Rectangle`,
  **1** `new Color` (against `Color.create`, the intended door).

### The ≥5 inventory

`new` = explicit construction sites in `src/`; `sub` = direct subclasses (each a `super` that
must move with the base).

| params | new | sub | class | disposition |
|---|---|---|---|---|
| 17 | 0 | 2 | `LabelButtonWdgt` | **P3** |
| 12 | 1 | 4 | `ButtonWdgt` | **P3** |
| 12 | 1 | 0 | `MenuItemSpec` | **P1** |
| 11 | 1 | 0 | `WheelInputEvent` | **exempt E3** |
| 10 | 2 | 0 | `MousemoveInputEvent` | **exempt E3** |
| 10 | 35 | 2 | `StringWdgt` | **P2** |
| 9 | 1 | 0 | `NumberPromptWdgt` | **P4** |
| 8 | 16 | 1 | `SimpleTextWdgt` | **P2** |
| 8 | 0 | 2 | `KeyboardInputEvent` | **exempt E3** |
| 8 | 0 | 4 | `MouseInputEvent` | **exempt E3** |
| 8 | 17 | 3 | `TextWdgt` | **P2** |
| 7 | 0 | 3 | `TouchInputEvent` | **exempt E3** |
| 7 | 2 | 0 | `StringFieldWdgt` | **P5** |
| 6 | 0 | 4 | `PromptWdgt` | **P4** |
| 6 | 3 | 0 | `ListWdgt` | **P5** |
| 6 | 1 | 0 | `TextPromptWdgt` | **P4** |
| 6 | 1 | 0 | `MenuItemWdgt` | **P3** |
| 5 | 1 | 0 | `TextEditingState` | **P5** |
| 5 | 1 | 0 | `ToolTipWdgt` | **P5** |
| 5 | 3 | 0 | `SaveShortcutPromptWdgt` | **P4** |
| 5 | 1 | 0 | `ColorPromptWdgt` | **P4** |
| 5 | 13 | 1 | `SliderWdgt` | ✅ **done** (`21d5b64`) |

Six of the 22 are exempt under E3 (foreign-API records reached through
`fromBrowserEvent`); one is done. **15 remain**, in five families.

---

## 1. P0 — Seed the gate (do first, lands alone)

Add to `STINKS` in `buildSystem/check-stinks.js`:

```js
{ id: 'positional-hole', baseline: 51,   // seeded 2026-08-14; target 0. A hole proves the
                                         // skipped parameter is configuration, not identity
                                         // (docs/architecture/constructor-and-parameter-conventions.md R3)
  why: 'a call punching `undefined` through to a later argument',
  re: /\bundefined\b\s*,\s*\bundefined\b/ },
```

Seeding at the measured 51 keeps the build green today and makes every later phase's gain
self-locking: each family that lands drops the count, and the check prints the
tighten-the-baseline reminder. **Tighten the baseline in the same commit that drops it** — that
is the established ratchet discipline.

⚠ Confirm the regex is evaluated against non-comment source with the existing scope machinery
(the stink runner already distinguishes `scope: 'comments'`); two of the current 51-ish
matches in a naive scan are prose inside comments, so the seeded number must come from the
runner's own count, not from this document's.

**Verification:** `./build_it_please.sh` green, `[stinks] positional-hole: N site(s)` printed.

## 2. P1 — `MenuItemSpec` (warm-up: 12 positional, 1 call site)

The irony worth fixing first: `MenuItemSpec` **is** a parameter object, constructed
positionally.

```coffee
# now — src/basic-widgets/menu-system/MenuItemSpec.coffee
constructor: (@label, @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = true, @target, @action,
  @toolTipMessage, @color, @bold = false, @italic = false, @doubleClickAction,
  @argumentToAction1, @argumentToAction2, @representsAWidget = false) ->
```

Its sole construction site already *has* the options object and unpacks it back into
positional order:

```coffee
# src/basic-widgets/menu-system/MenuRowsPanelWdgt.coffee:188
new MenuItemSpec label, opts.closesUnpinnedPopUps, target, action,
  opts.toolTip, opts.color, opts.bold, opts.italic,
  opts.doubleClickAction, opts.arg1, opts.arg2, opts.representsAWidget
```

**Target:** `constructor: (@label, @target, @action, opts = {}) ->` reading the remaining nine
from `opts` — so `_menuItemSpecFrom` forwards its `opts` straight through instead of
re-ordering it into twelve slots. Keep every default identical (closes-unpinned `true`; bold /
italic / representsAWidget `false`).

**Risk: minimal.** One call site, no subclasses, not constructed anywhere else, and the spec's
own field defaults are unchanged. This is the phase that proves the idiom end to end.

**Verification:** `./build_and_test.sh` — menus are exercised heavily by the suite; expect
**zero** reference churn.

## 3. P2 — The text family (biggest payoff; `StringWdgt` / `TextWdgt` / `SimpleTextWdgt`)

The single largest hole cluster in the codebase. ~20 call sites share one shape:

```coffee
super "Drop a widget in here",undefined,undefined,undefined,undefined,undefined,
  WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1
```

— in `TitleWdgt`, `DocumentWdgt`, `TemplatesWindowWdgt` (×4), `WelcomeMessageInfoWdgt` (×2),
`HowToSaveMessageApp` (×2), `SimpleDocumentScrollPanelWdgt`, `SimpleTextScrollPanelWdgt`,
`SimpleVerticalStackScrollPanelWdgt`, `FrameContentsPlaceholderText`, `SampleDocApp`,
`SimpleTextPanelWdgt`, `DemoMenus` (×3), `FridgeMagnetsWdgt`. Every one of them wants exactly
two things — a colour and a transparency — and pays five holes to reach them.

Current signatures (note the shared trailing pair, already plain non-`@` params precisely
because of the R5 hazard):

```coffee
StringWdgt:     (@text, @originallySetFontSize, @fontName, @isBold, @isItalic,
                 @isHeaderLine, @isNumeric, @color, backgroundColor, backgroundTransparency)
TextWdgt:       (@text, @originallySetFontSize, @fontName, @isBold, @isItalic,
                 @color, backgroundColor, backgroundTransparency)
SimpleTextWdgt: (@text, @originallySetFontSize, @fontName, @isBold, @isItalic,
                 @color, backgroundColor, backgroundTransparency)
```

**Target head:** `(text, fontSize, opts = {})` for all three — `text` is the identity,
`fontSize` is the one other argument callers routinely pass positionally (`new StringWdgt
scalarText, 12` in `CellWdgt:105`/`:234`, `new StringWdgt eachNamedClass, …` in
`InspectorWdgt:211`). Everything else — `fontName`, `isBold`, `isItalic`, `isHeaderLine`,
`isNumeric`, `color`, `backgroundColor`, `backgroundTransparency` — moves to `opts`.

The 15-site cluster then reads:

```coffee
super "Drop a widget in here",
  undefined,
  color: WorldWdgt.preferencesAndSettings.editableItemBackgroundColor,
  backgroundTransparency: 1
```

⚠ Or better: give the family a **named factory** for this recurring look, since fifteen sites
asking for the same two knobs is a shape, not a coincidence. Decide at execution time; the
mechanical conversion is correct either way and the factory can land on top.

⚠ **`text` must stay a plain guarded parameter or keep its conditional default** — `StringWdgt`'s
is `@text = (if text is "" then "" else "StringWdgt")`, which distinguishes "" from absent.
Transcribe it exactly; do not "simplify" it.

**Risks.** Largest blast radius of the arc (**68** `new` sites in `src/` across the three
classes, plus subclass `super` chains and the tests repo). All three classes convert in ONE
commit (R7). `TextWdgt extends StringWdgt`, `SimpleTextWdgt extends TextWdgt` — a two-level
chain, so both `super` calls move together.

**Verification:** `./build_and_test.sh`. This family draws text everywhere; any mis-bound
field shows up as reference churn immediately. Expect **zero** churn — investigate any.

## 4. P3 — The button family (deepest `super` chain; convert atomically)

`LabelButtonWdgt` at **17** parameters is the codebase's worst, and it is a *pure forwarder*:
eleven of its arguments are threaded straight into `ButtonWdgt`'s twelve-slot `super`.

```coffee
# src/LabelButtonWdgt.coffee — the super it exists to make
super ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, undefined, environment,
  widgetEnv, toolTipMessage, doubleClickAction, argumentToAction1, argumentToAction2, representsAWidget
```

Note `ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = true` occupying the **first**
positional slot in both classes — so nearly every call site in the codebase opens with a bare
`true`, the exact smell R1 names. And `SimpleRasterImageButtonWdgt:27` is the arc's worst
single line:

```coffee
super true, target, action, @imageWdgt, undefined, undefined, undefined, undefined,
  argumentToAction1,undefined,undefined,2
```

**Target head:** `(target, action, opts = {})` throughout the family — `target`/`action` are the
established pair and the only two a typical caller passes. `closesUnpinnedPopUps`,
`faceWidget`, `dataSourceWidgetForTarget`, `widgetEnv`, `toolTip`, `doubleClickAction`,
`arg1`, `arg2`, `representsAWidget`, `padding` and the label knobs (`labelString`, `fontSize`,
`fontStyle`, `centered`, `color`, `bold`, `italic`) all move to `opts`.

**Reuse the P1 vocabulary** (`closesUnpinnedPopUps`, `toolTip`, `arg1`, `arg2`,
`representsAWidget` are already the `addMenuItem` option names — R4/R8). `MenuItemWdgt` is
built from a `MenuItemSpec`, so P1 and P3 meet here; do P1 first and let the spec's field names
drive.

**Atomic unit:** `ButtonWdgt`, `LabelButtonWdgt`, `MenuItemWdgt`, `MagnetWdgt`,
`SimpleButtonWdgt`, `SimpleRectangularButtonWdgt`, `SimpleRasterImageButtonWdgt` — one commit.

⚠ **P3 overlaps `plans/widget-practices-convergence-plan.md` W8** (§2.8, authored the same day from
the widget survey), which is **owner-gated (D5) and deliberately sequenced LAST** in that arc, after
its W1–W6, as its highest-churn item. **Same work; do it once** — whichever arc reaches it first
executes, the other de-scopes to a pointer. Honour W8's gating: if that arc is live, P3 waits for D5
rather than racing it.

⭐ **W8's own finding, which this plan must carry:** `IconButtonWdgt` (~:41-45), `CreatorButtonWdgt`
(~:26-29) and `EditorContentPropertyChangerButtonWdgt` (~:40-42) each keep a **parallel shadow
field** `iconToolTipMessage`, copied into `@toolTipMessage` after `super`, purely because
`ButtonWdgt` takes `@toolTipMessage` as a `@param` defaulting to `undefined` (`IconButtonWdgt`'s
comment says so outright). That is the R5 hazard wearing a workaround. Moving `toolTip` into `opts`
lets all three shadow fields be **deleted** — a concrete correctness win riding on the conversion, so
verify they are gone when P3 lands.

⚠ `LabelButtonWdgt` passes `undefined` for `faceWidget` deliberately (it draws its own
`@label`). Under an options object it simply omits the key — but check `ButtonWdgt` treats an
absent `faceWidget` identically to an explicitly-`undefined` one before relying on that.

**Verification:** `./build_and_test.sh`; buttons and menu rows are on nearly every screenshot.

## 5. P4 — The prompt family

Six classes sharing a prefix that has drifted — some bind `@`, some don't:

```coffee
PromptWdgt:             (widgetOpeningThePopUp, @msg, @target, @callback, @defaultContents, @intendedWidth)
TextPromptWdgt:         (widgetOpeningThePopUp, msg, target, callback, defaultContents, intendedWidth)
ColorPromptWdgt:        (widgetOpeningThePopUp, msg, target, callback, defaultContents)
NumberPromptWdgt:       (widgetOpeningThePopUp, msg, target, callback, defaultContents,
                         intendedWidth, @floorNum, @ceilingNum, @isRounded)
SaveShortcutPromptWdgt: (widgetOpeningThePopUp, @target, @defaultContents, @intendedWidth = 100,
                         @wdgtWhereReferenceWillGo)
CodePromptWdgt:         (@msg, @target, @callback, @defaultContents)
```

**Target head:** `(widgetOpeningThePopUp, msg, target, callback, opts = {})` — four operands,
at the R1 cap, and every prompt genuinely needs all four. `defaultContents`, `intendedWidth`,
`floorNum`, `ceilingNum`, `isRounded`, `wdgtWhereReferenceWillGo` move to `opts`. This also
regularises the family onto one prefix, which is the larger win: `NumberPromptWdgt`'s three
trailing `@`-bound numerics are exactly the holes-in-waiting R3 describes.

⚠ `SaveShortcutPromptWdgt` and `CodePromptWdgt` deviate from the prefix (no `msg`, no
`callback` respectively). Do **not** force them into the shared head if the argument is
genuinely absent — an unused positional slot is the disease, not the cure. Give each the head
it actually needs and share only the `opts` vocabulary.

**Verification:** `./build_and_test.sh`, plus a manual open of each prompt — prompts are
modal and some paths may be thin on suite coverage. Check `world.errorConsole` is clean.

## 6. P5 — Stragglers

`StringFieldWdgt` (7), `ListWdgt` (6), `ToolTipWdgt` (5), `TextEditingState` (5), and the
sub-5 classes that still show holes: `SimpleVerticalStackPanelWdgt` (`new … undefined,
undefined, undefined, false` at `DemoMenus:513`), `TransformSpec` (**reorder**, not opts —
value class, E1), `IconicDesktopSystemWindowedAppLauncherWdgt`, `VideoScrubberWdgt`,
`FormatAsCodeButtonWdgt`, `DegreesConverterApp` (6 hole lines — the densest single file).

Low call-site counts, no deep chains; batch by directory. `TextEditingState` is a plain record
and may be exempt on inspection (E5-adjacent) — check before converting.

## 7. P6 — Close out

1. Drive `positional-hole` to **0** and make it a HARD rule (baseline 0), alongside
   `nil-literal` and `comment-past-receipt`.
2. Any surviving hole must be **named with its reason** at the site, or the class listed as
   exempt in the convention doc §3 — not silently tolerated.
3. Update §7 of
   [`../architecture/constructor-and-parameter-conventions.md`](../architecture/constructor-and-parameter-conventions.md)
   with the final conformance numbers.
4. `git mv` this plan to `docs/archive/`, stamp it, add its `archive/INDEX.md` line, remove its
   `BACKLOG.md` entries (filing rules 2 and 5).

---

## 8. Standing hazards (read before every phase)

- **Serialization and duplication are safe.** Both instantiate via `Object.create`; the
  constructor is never run (`Deserializer.coffee:192`, `Duplicator.coffee:168`). A reorder cannot break a saved
  snapshot. **Only explicit `new X(...)` and `super` sites matter** — but *all* of them do.
- **Grep both repos, four ways.** `new X`, `super`, `@method` self-calls (a `.method`-anchored
  transform misses these — P5 case law), and the sibling **`Fizzygum-tests`** repo, which is
  not checked out here. It carries construction sites in test macros, in **spreadsheet formula
  strings**, and in plain JS rig code (`new SliderWdgt(0, 100, 40, 10)`). The `SliderWdgt`
  conversion touched 19 of them.
- **Verify the call spellings against the compiler before converting a family.** All four forms
  need checking — positional, no-arg, trailing implicit object, and the multi-line paren form —
  in particular that a trailing `key: value` lands as a **separate final argument** rather than
  folding into the positionals. This was done for `SliderWdgt` and must be redone per family;
  the paren-less call form (`addMenuItem (expr)…`) is where it bites.
- **Do not re-arm the `@param` hazard** (R5). A field whose absence must mean "keep the class
  default" is read from `opts` with `?`, or taken as a plain parameter and assigned guarded —
  never as a bare `@param`.
- **Options are read where the `@param`s were assigned** (R6): above `super()` when a
  superclass constructor reads the field.
- **No constructor-build regressions.** `archive/menu-slider-ctor-conversion-plan.md` retired
  ctor-build patterns; converting a signature must not reintroduce one. Keep the
  `_buildAndConnectChildren` / `…NoSettle` pair intact and settle exactly once.
- **Reference churn is a red flag, not an expected cost.** Every landed phase should be
  pixel-identical. `SliderWdgt` and P5 families 1–4 all landed with zero churn. If a phase
  churns references, a field is mis-bound — find it before recapturing anything.

## 9. Order and independence

**P0 → P1 → P2 → P3 → P4 → P5 → P6.**

P0 first so every later gain locks itself in. P1 is the warm-up that proves the idiom at
near-zero risk. P2 next because it is the biggest payoff and its blast radius, while wide, is
shallow (no deep `super` chain). P3 after P1 so it inherits the settled option vocabulary. Each
phase is independently landable and independently revertible; stop-anywhere is safe. Run
`./build_and_test.sh` after **each** family, never batched.

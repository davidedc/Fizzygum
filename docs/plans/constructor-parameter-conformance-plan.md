# Constructor-parameter conformance — combing the codebase onto the head/tail convention

**STATUS: ACTIVE. P0, P1, P2 and P3 landed 2026-08-15. P4 (prompts) next.** Owner-gated per family.

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

## 1. P0 — Seed the gate (do first, lands alone) ✅ DONE 2026-08-15

Added to `STINKS` in `buildSystem/check-stinks.js`, **baseline 51** — the runner's own count:

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
is the established ratchet discipline. (P2 duly took it to **30**.)

The ⚠ this phase carried — *the seeded number must come from the runner's own count, not this
document's, because a naive scan counts comment prose* — was **checked and found moot for this
particular regex**: `undefined\s*,\s*undefined` matches nothing inside a comment anywhere in
`src/`, so the runner's comment-stripped hits and a naive `grep`'s are the **same 51 lines**, set
for set (verified by diffing the two `file:line` lists, not by comparing totals — two counts can
agree while their contents differ). The discipline still stands for the next stink; it simply had
nothing to correct here.

**Verified:** `./build_it_please.sh` green; `[stinks] positional-hole: 51 site(s) (baseline 51)
-- OK`. Counted by hand off the runner's `--list`, the 51 sites split **26 construction holes**
(`new`/`super` — the work of P2–P5) against **25 that are not constructor calls at all**:
`setFontName`/`_setFontNameNoSettle` (7), `setTargetAndActionWithOnesPickedFromMenu` (10),
`setPattern` (2), `makeFolder`, `add`, `_fromCatalogEntry`, and three `return [undefined,
undefined, error]` tuples in `LCLCodePreprocessor`. **Half the gate's population is method
signatures, which the ≥5 constructor inventory never counted** — the stink is a *hole* gate, not a
*constructor* gate, so
driving it to 0 (P6) means converting those methods too, or naming each survivor's reason at the
site. ⚠ The three `LCLCodePreprocessor` returns are **not holes at all** — they are a positional
result tuple `[a, b, error]`, the shape R3 does not address; expect them to need an explicit
exemption or a small refactor rather than an options object.

## 2. P1 — `MenuItemSpec` (warm-up: 12 positional, 1 call site) ✅ DONE 2026-08-15

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

**As built.** `constructor: (@label, @target, @action, opts = {})`, the nine knobs read
`opts.<key> ? <default>` in the body — keyed by the **`addMenuItem` vocabulary**
(`closesUnpinnedPopUps` / `toolTip` / `arg1` / `arg2` / …), not by the field names they land in
(R4). That is what turns `_menuItemSpecFrom` into a pure forward: `new MenuItemSpec label,
target, action, opts`, so an option added to `addMenuItem` reaches the spec with no edit in
between. The method survives (it names the step) but no longer transcribes anything.

⚠ **The plan's site count was two short, and both were in the tests repo** — `MenuItemSpec` is
built directly inside the CoffeeScript macro source of `macroBareButtonFloatDragsWithoutTriggering`
and `macroEditButtonLabelText`, plus a third edit in the former's `provenance` metadata string,
which quotes its own construction line verbatim. **A macro source is CoffeeScript inside a JS
template literal, so no `.coffee` search will ever find it** — search the tests repo by class
name across `*.js` too. Both sites also shed arguments they were passing at the default: the
explicit `true` for closes-unpinned, and a `undefined, undefined` target/action pair.

**Verified:** `fg presuite` green — dpr1 suite PASS (294 tests), paint-truthfulness PASS,
fracplane dpr2 rider PASS. **Zero reference churn**, as predicted.

Rewriting the class header to describe the shape it now has also dropped its one
`comment-narration` hit, so that stink tightens 104 → 103 in the same commit (ratchet discipline).

## 3. P2 — The text family (biggest payoff; `StringWdgt` / `TextWdgt` / `SimpleTextWdgt`) ✅ DONE 2026-08-15

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

**Target head:** `(text, opts = {})` for all three — `text` alone is the identity. Everything
else, **`fontSize` included**, moves to `opts`: `fontName`, `bold`, `italic`, `headerLine`,
`numeric`, `color`, `backgroundColor`, `backgroundTransparency`.

⚠ This head is a **correction to the one first specified here**, `(text, fontSize, opts)`, which
rested on the claim that `fontSize` "is the one other argument callers routinely pass
positionally" and cited three sites for it. Measurement says otherwise — see the boxed finding
below, which is the record of why.

The 15-site cluster then reads:

```coffee
super "Drop a widget in here",
  backgroundColor: WorldWdgt.preferencesAndSettings.editableItemBackgroundColor
  backgroundTransparency: 1
```

⚠ **`backgroundColor:`, not `color:`** — this snippet said `color:` when it was authored, and that
is a mis-binding, not a typo with local blast radius: slot 7 of the old signature is
`backgroundColor` (slot 6, the text colour, is one of the five `undefined`s), and the argument's
own name says so. Taken literally it would have painted the text in the background colour at
~60 sites.

⚠ Or better: give the family a **named factory** for this recurring look, since fifteen sites
asking for the same two knobs is a shape, not a coincidence. Decide at execution time; the
mechanical conversion is correct either way and the factory can land on top.

⚠ ~~**`text` must stay a plain guarded parameter or keep its conditional default** — `StringWdgt`'s
is `@text = (if text is "" then "" else "StringWdgt")`, which distinguishes "" from absent.
Transcribe it exactly; do not "simplify" it.~~ **FALSIFIED at execution — transcribing it exactly
would have preserved a latent crash.** CoffeeScript renames the parameter to `text1` and leaves
the default expression referring to a free `text`, so `new StringWdgt()` raises
`ReferenceError: text is not defined`; when the argument IS supplied the default never evaluates
at all. The conditional is inert in both directions. `""` does survive as a real value, but
because ES defaults fire on `undefined` only — nothing to do with the conditional. The spelling
that has the intended meaning *and* no crash is the plain `@text = text ? "StringWdgt"`, which is
what landed. (Nothing constructs a `StringWdgt` with no arguments, which is why the crash has
never fired.)

**Risks.** Largest blast radius of the arc (**68** `new` sites in `src/` across the three
classes, plus subclass `super` chains and the tests repo). All three classes convert in ONE
commit (R7). `TextWdgt extends StringWdgt`, `SimpleTextWdgt extends TextWdgt` — a two-level
chain, so both `super` calls move together.

**Verification:** `./build_and_test.sh`. This family draws text everywhere; any mis-bound
field shows up as reference churn immediately. Expect **zero** churn — investigate any.

### What the conversion exposed

The value of naming the slots is that three things nobody could see in a row of `undefined`s
became obvious the moment they had names. The P2 commit itself stays **pixel-neutral**; anything
with a visible result lands separately, so it stays bisectable.

1. **`SpeechBubbleWdgt` passed `"center"` as its TEXT COLOUR.** Old slot 6 of `TextWdgt` is
   `color`, and the site passed the string `"center"` — an alignment argument aimed at the wrong
   signature, while `@contentsWidget.alignCenter()` two lines below already does the real job. As
   a literal `color: "center"` it is self-evidently wrong on sight; as the sixth of eight
   positionals it was invisible. Its effect is the `dropped-background-fill` failure mode again:
   an invalid value handed to a canvas property is not loud — HTML5 says ignore it — so the
   bubble's text painted in whatever `fillStyle` happened to be set last. ⭐ **The generalisation
   worth keeping: that arc's lesson reads as being about `backgroundTransparency`, but the real
   rule is that ANY invalid value assigned to ANY canvas property fails silently.** FIXED in its
   own follow-up commit (option deleted, so the text takes `StringWdgt`'s default): it moves 8
   references, and an A/B with just this line reverted proved those 8 are the ONLY pixels either
   change touches.
2. **`SimpleTextWdgt`'s declared defaults never reached an instance.** `12` and `Color.BLACK` (and
   `"SimpleText"`) were overwritten on every construction by the base's own defaults, via the
   bare-`super` mechanism now written up in the convention doc's R7. The dead declarations are
   deleted; the behaviour is untouched. ⭐ The gap is much smaller than it looks, which is why
   restoring the intent was rejected rather than deferred: **`normalTextFontSize` IS 12**, so the
   size half was always a no-op, and `"SimpleText"` is unreachable because nothing constructs one
   with no arguments. Only `Color.BLACK` vs `Color(37,37,37)` ever differed — and repainting every
   contained text in the system on the strength of a declaration that has never once been true is
   a design change, not a bug fix.
3. **The specified head would have left a single `undefined` hole at 50 sites** — measured and
   rejected; see below.

### ⚠ The head is `(text, opts = {})` — §3's `(text, fontSize, opts)` was measured and rejected

§3 asserted `fontSize` "is the one other argument callers routinely pass positionally", citing
three sites. Measured across all **186** construction sites: **84 pass only `text`, 33 pass
`text, fontSize`, and 69 pass more** — and of those 69, **50 pass `undefined` for `fontSize`**
purely to reach a later argument.

So a size is supplied by **28%** of callers, which fails R1's "the *typical* caller passes it",
and 50 sites must skip it, which is R3's hole test failing outright. §4's own procedure routes
this to step 4: *"Does any call site still need a hole? → go back to 2; you got one wrong."* The
decisive comparison is that **the group paying the hole (50) is larger than the group gaining the
terseness (33)** — in the family this plan calls its biggest payoff.

⚠ The `SliderWdgt` precedent does **not** carry over, and this is where it would have misled: its
four numbers stayed positional under **E4**, because `new SliderWdgt 0, 100, 30, 10` is a
spelling users type into spreadsheet formulas. Checked for this family — `MACRO-PATTERNS.md`
documents no constructor spelling for it and no formula string constructs one. **E4 is absent, so
only R1 and R3 apply, and both say the same thing.** A size is not half of a tuple here; it is
the most popular of nine knobs.

Result: the family contributes **zero** sites to `positional-hole`. Final shape across both
repos — **84 sites pass `text` alone, 103 pass `text` + an options object, none pass more.**

## 4. P3 — The button family (deepest `super` chain; convert atomically) ✅ DONE 2026-08-15

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

**Atomic unit:** ⚠⚠ **NOT the seven classes this line used to list — compute the descendant
CLOSURE from the source.** `ButtonWdgt` has **thirteen** descendants, and the two the list omitted
are exactly where P3 broke: `CodeInjectingSimpleRectangularButtonWdgt` kept
`super true, @, 'injectCodeIntoTarget', face`, which against `(target, action, opts)` binds `true`
to target, `@` to action, the ACTION STRING to opts, and drops `face` entirely — the Drawings
Maker's pencil/brush/spray/eraser buttons rendered as empty grey boxes.
(`VideoThumbnailWdgt`, the other omission, is genuinely safe: it supers into
`SimpleRasterImageButtonWdgt`'s own unchanged signature.) The rewriter deliberately never touches
`super`, so enumerating the closure is a MANDATORY manual step, not a check:

```
LabelButtonWdgt, SimpleButtonWdgt, IconButtonWdgt, SimpleRectangularButtonWdgt, MenuItemWdgt,
MagnetWdgt, SimpleRasterImageButtonWdgt, EditIconButtonWdgt, CloseIconButtonWdgt,
UncollapseIconButtonWdgt, CollapseIconButtonWdgt, CodeInjectingSimpleRectangularButtonWdgt,
VideoThumbnailWdgt
```

**As built.** `(target, action, opts = {})` on `ButtonWdgt` and `LabelButtonWdgt`;
`(menuItemSpec, opts = {})` on `MenuItemWdgt`; `(target)` on `MagnetWdgt`. 42 call sites rewritten
mechanically + 8 by hand. `positional-hole` 30 → 28. Zero reference churn.

⚠ Two naming decisions worth knowing: the option is **`face`**, not `faceWidget`, because the value
is as often a STRING as a widget (`ButtonWdgt` wraps a string into a centred `StringWdgt`); and
`LabelButtonWdgt`'s "environment" is **`dataSource`**, the same key `ButtonWdgt` uses, because one
field under two names is precisely what a FORWARDED options bag cannot survive — the receiver would
never read the alias.

⚠ **P3 overlaps `plans/widget-practices-convergence-plan.md` W8** (§2.8, authored the same day from
the widget survey), which is **owner-gated (D5) and deliberately sequenced LAST** in that arc, after
its W1–W6, as its highest-churn item. **Same work; do it once** — whichever arc reaches it first
executes, the other de-scopes to a pointer. Honour W8's gating: if that arc is live, P3 waits for D5
rather than racing it.

⭐ **W8's own finding — and it is ONE THIRD right, which is worth recording.** W8 states that
`IconButtonWdgt`, `CreatorButtonWdgt` and `EditorContentPropertyChangerButtonWdgt` each keep a
parallel `iconToolTipMessage` *because* `ButtonWdgt` takes `@toolTipMessage` as a `@param`. Only
`IconButtonWdgt` extends `ButtonWdgt`; the other two extend `Widget` and `IconWdgt`, which never
take or clobber the field (`toolTipMessage` is declared on `ButtonWdgt` alone). So the R5 hazard
explains exactly one of them, and P3 deleted exactly that one: `ButtonWdgt` now reads
`opts.toolTip` **guarded**, so the four `IconButtonWdgt` subclasses simply declare
`toolTipMessage:` on their prototypes. The other ~14 carriers have a different cause and want
their own small cleanup — not a P3 deliverable, and NOT evidence that P3 under-delivered.

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
   `nil-literal` and `comment-past-receipt`. ⚠ P2–P5 cannot get there on their own: **25 of the
   51 seeded sites are method calls, not constructions** (§1) — chiefly `setFontName` and
   `setTargetAndActionWithOnesPickedFromMenu`, whose own signatures need the same head/tail
   treatment. Budget that as its own step; the convention is not widget-constructor-specific.
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
  ⚠ **The tests repo has no `.coffee` construction sites at all** — a macro's `mainMacroSource`
  is CoffeeScript inside a **JS template literal** in `tests/**/*_automationCommands.js`, and the
  four mandatory metadata strings in `tests/**/SystemTest_<name>.js` quote construction lines as
  prose. Search by CLASS NAME across the whole repo, never by file extension. (P1 found two live
  sites and one prose quote this way; P2's tests-repo count exceeds its `src/` count.)
- **⚠⚠ `new X (expr), a, b` is a PAREN-LESS call with a parenthesised FIRST ARGUMENT, not a paren
  call.** The space matters: CoffeeScript reads `f (a), b` as `f(a, b)` and `f(a), b` as
  `(f(a)), b`. Any scanner that skips whitespace before testing for `(` reads the whole call as
  one argument, silently classifies an 8-argument site as a 1-argument one, and leaves it
  unconverted. P2 hit this exactly once in 186 sites
  (`macroTextWdgtCaretPlacementUnderAlignments`), and **the suite is what caught it** — a single
  red test in an otherwise-clean run. Treat "reference churn is a red flag" as covering this too:
  the failure of a conversion to REACH a site looks identical to a mis-binding.
- **Count arity with a paren/quote-aware scan, not a comma grep.** `Fizzygum-tests/.scratch/
  ctor-arity-scan.js` (gitignored, written at P2) joins continuation lines and counts TOP-LEVEL
  arguments for every `new <Class>` in both repos, with a histogram. A single-line comma grep gets
  this wrong in both directions: it counts commas inside string literals and nested calls
  (`Color.create(230, 230, 130)`) as argument separators, and it cannot see the multi-line paren
  form — which is precisely where the long calls live. Only sites passing MORE positionals than
  the new head need editing, so this list IS the work list.
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

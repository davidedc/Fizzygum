> **ARCHIVED — COMPLETE (2026-08-18).** P1–P9 plus P10(c)+(d) landed between 2026-08-16 and
> 2026-08-18, making a controller a VIEW of the value it controls: readable `PinSpec`s, `bind ⇄` as
> two ordinary wires, one announcement verb, a controller's LIST of wires, non-widget state as nodes,
> the palette's marker, ticks as reflection, scroll in the public wire vocabulary, and a switch as a
> view of its index. P10(a) is a recorded REFUSAL; P10(b) (command-edge indexing) is RE-HOMED to
> `graph-edges-and-lifecycle-plan.md` §4.2 and is not open here.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Connector ubiquity & the controller-is-a-view law

**STATUS: ✅ ARC CLOSED 2026-08-18 — executed in full, with one item RE-HOMED rather than left open.
AUTHORED 2026-08-14, owner-gated. P1–P9 ALL LANDED** between 2026-08-16 and 2026-08-18, and so are
**P10(d)** (2026-08-18, `6a58bb4c` — a switch is a view of a value: `SwitchButtonWdgt` declares the
readable `shown button` pin as its `principalPinLabel`, and §8's Q9 dissolved rather than got decided)
and **P10(c)** (re-aimed by measurement on 2026-08-18 — the gap is a LIFETIME, not a vocabulary: drag
a menu row out and keep it — then closed the same day, its hard part by `acffb8b2` (a reflecting row
owns its own subscription) and the gesture itself by `9f4ba5d4` (a pinned menu gives up its command
rows)). **P10(a) is a recorded REFUSAL**, not an open step. **P10(b)** — index button `@target`s as
non-traversed command edges — is **RE-HOMED, not abandoned**: it rides
[`../plans/graph-edges-and-lifecycle-plan.md`](../plans/graph-edges-and-lifecycle-plan.md) §4.2 ("one
graph index, not two"), whose own scope decision (its G1) is owner-pending, and §8's Q8 travels with
it. **§6's sequencing table is the status ledger — read it first**, and then a section's **"As
landed"** block before trusting its sketch: each says what actually landed, what deviated from its
sketch, and what it deliberately left alone.
Anchor on **symbol names**; §2's current-state survey was verified against `src/` on 2026-08-14 and
its §2.4 is now history — P1 replaced the write-only tables it describes. Line numbers drift.
Self-contained.

**Not** a plan to extend the wire *vocabulary* — that arc exists and is untouched by this one
([`wire-vocabulary-extensions-plan.md`](../plans/wire-vocabulary-extensions-plan.md): per-event delivery,
cold edges, buffer payloads). This arc asks the opposite question: **how much of what the system
already does could be, but is not, expressed with the connectors it already has** — and what has to
change so that expressing it is natural rather than heroic.

---

## 1. The complaint, and the law it implies

Three observations from the owner, which turn out to be three symptoms of one thing:

1. **Sliders that scroll are not connected as connectors.** A `ScrollPanelWdgt`'s scrollbar *is*
   wired (`@target`/`@action`), but only in the forward direction, and only through a private
   field. Duplicate the bar and the copy scrolls the content while ignoring it — the two bars do
   not move in unison.
2. **The colour palette controls a colour without showing it.** Wire a `ColorPaletteWdgt` to a
   widget and nothing on the palette says which colour is current — no marker, no ring, no swatch.
3. **The wallpaper menu is one-directional.** It writes `world.wallpaper.patternName` and does not
   observe it; two open pattern menus disagree, and so does a menu open across a snapshot load.
   `Wallpaper.updatePatternsMenuEntriesTicks` carries a comment apologising for exactly this.

Morphic's founding decision — restated in
[`../architecture/widget-citizenship.md`](../architecture/widget-citizenship.md) — is that Model,
View and Controller live in **one object**, and in particular that *view and controller are the
same thing*. A slider is not a controller *attached to* a rendering of a number; the slider **is**
the number's picture and the number's handle at once.

That gives the law this arc is about:

> **A controller is a view of the value it controls, and stays a view however that value changes.**

A slider's thumb is a view of the value. A palette's marker (absent today) would be a view of the
picked colour. A menu's tick is a view of the chosen setting. Where a widget offers the handle but
not the picture, or offers a picture that only tracks its *own* gesture, the MVC unification has
quietly been given up — and, per
[`../architecture/regularity-principles.md`](../architecture/regularity-principles.md), that is an
irregularity to remove rather than a special case to deepen.

The corollary is the mechanism half: **the picture cannot stay true unless the value announces
itself**, and today values almost never do.

---

## 2. Current-state truth (verified against `src/` 2026-08-14)

### 2.1 The set of things that can be a dataflow SOURCE is six classes

`updateTarget` — the one onward-fire verb — is defined on exactly:

| class | fires on | ships in production? |
|---|---|---|
| `SliderWdgt` | `setValue`, `setStart`, `setStop`, `reactToTargetConnection` | yes (core) |
| `StringWdgt` (⇒ `SimpleTextWdgt`, `TextWdgt`) | every `_setTextNoSettle` | yes (core) |
| `PaletteWdgt` (⇒ `ColorPaletteWdgt`, `GrayPaletteWdgt`) | `mouseDownLeft`, `nonFloatDragging` | yes (core) |
| `PatchNodeWdgt` (⇒ `CalculatingPatchNodeWdgt`) | any `setInput*`, `bang` | base core; `Calculating` in `authoring` |
| `FanoutWdgt` / `FanoutPinWdgt` | `setInput` | **no** (`patch-programming-experimental`) |

Everything else in ~470 classes is a pure **sink**. A widget is a source only for the one property
its own input gesture writes; the same property written by a menu, a script, the loader, or another
widget's method call is invisible to the graph.

### 2.2 A wire is a SINGLE-SLOT, ONE-WAY edge

- `ControllerMixin` stores exactly one `@target` and one `@action`. The engine's index supports many
  out-edges per producer (`edgesFrom` maps producer → a `Set` of records), but
  `DataflowEngine.ensureWireEdge` mirrors the single pair and calls `_removeOutgoingEdgesOf` on a
  mismatch — so **a controller has at most one out-edge, ever**.
- There is **no un-wire idiom** in `ControllerMixin`. `src/spreadsheet/CellWdgt.coffee` says so in a
  comment ("no un-wire idiom exists in `ControllerMixin` — verified 2026-07-17") and clears the
  fields by hand.
- `FanoutWdgt` is the workaround: a widget whose whole job is to turn one input into four pins,
  each with its own `@target`. It lives in `patch-programming-experimental` and **production does
  not ship it** (`buildSystem/profiles/homepage.json`).

⚠ This directly contradicts a claim already made in the architecture docs.
`widget-citizenship.md` §"The stance" says the MVC unification keeps multiple-views-on-one-model
because *"any widget can be targeted by any number of controllers … and the dataflow engine lets
many widgets derive from one source."* The first half is true (`edgesTo` is a Set of producers). The
second half is true **only for the spreadsheet client** — a cell can be referenced by many cells.
For wires it is false today.

### 2.3 The reverse channel exists — as private field plumbing, not as an edge

The scroll case, end to end:

```
ScrollPanelWdgt (:65-79)     @hBar.target = @ ; @hBar.action = "adjustContentsBasedOnHBar"
                             @vBar.target = @ ; @vBar.action = "adjustContentsBasedOnVBar"
FORWARD  bar → panel         a real dataflow edge, derived lazily by ensureWireEdge on first fire
                             (this is exactly what the 6c reconciliation was for)
REVERSE  panel → bar         ScrollPanelWdgt._reLayoutScrollbars (:157-220):
                               if @hBar.target == @ … @hBar.updateSpecs start, stop, value, size
                               if @vBar.target == @ … @vBar.updateSpecs …
```

Three things follow:

- The reverse path addresses **one specific bar object through a field** (`@hBar` / `@vBar`), so
  only the panel's own two bars ever learn anything. A duplicated bar keeps `target == thePanel`
  (the `Duplicator` keeps out-of-structure widget references as-is), so it still *drives* the
  content — but the panel holds no field pointing at it and never reflects into it. **That is
  precisely the "duplicate the slider and they don't move in unison" symptom.**
- `updateSpecs` deliberately does **not** call `updateTarget` — the loop is broken by refusing to
  announce, rather than by the engine's cutoff. So the reflection is invisible to the graph and
  cannot compose with anything.
- The guard `if @hBar.target == @` is a hand-rolled ownership test standing in for "is there an
  edge between us".

`SliderWdgt` already has the honest name for the reverse operation:

```coffee
# it does what setValue does, but it doesn't update the target i.e. it doesn't "fire" …
# This is useful when the slider needs to reflect the state of something that has been
# independently changed
_updateHandlePosition: (newvalue) ->
```

It exists on one class and has exactly one caller in the whole tree
(`VideoScrubberWdgt`, `:29`). **The concept "reflect without firing" is already named and is
already understood; it is simply not a system.**

### 2.4 The pin vocabulary is WRITE-ONLY — ⚠ **SUPERSEDED by P1 (landed 2026-08-16)**

*This section describes the state P1 changed; it is kept because it is the argument FOR P1, and
because the last paragraph's two riders are the record of what P1 then found. For what the pin
protocol is now, read P1's "As landed" and
[`../architecture/widget-authoring-guidelines.md`](../architecture/widget-authoring-guidelines.md) §11.*

`Widget.colorSetters()` / `stringSetters()` / `numericalSetters()` / `allSetters()` returned a pair of
parallel arrays — `[labels], [setterMethodNames]` — and that is the entire pin protocol. There is
**no reader table**. Consequences:

- the engine cannot pull *a property* of a node, only *the node's* one `dataflowValue()` (which for
  a plain widget is `exportedValue()` = `getColor?() ? getValue?() ? @text`);
- so a reverse edge cannot be constructed generically: nothing can answer "what is the target's
  `color` right now?" in the same vocabulary that wrote it;
- so the connect menus cannot show current values;
- so a spreadsheet reference cannot read a widget's *n*-th property, only its principal one.

The setter tables are also unevenly implemented. `Example3DPlotWdgt.numericalSetters` does **not**
call `super`, so it silently drops every inherited pin (width/height/alpha/padding) and advertises
only `param`; and its `reactToTargetConnection` is dead code (that hook fires on the *producer*, and
a plot is never one). Both are evidence that the pin protocol is convention rather than contract.

### 2.5 Non-widget state is not addressable at all

Three important state holders are neither widgets nor nodes, declare no pins, and
therefore cannot be wired, read, or observed:

| state | home | how it changes | who is told |
|---|---|---|---|
| desktop wallpaper pattern | `world.wallpaper.patternName` (`Wallpaper`, a plain delegated collaborator) | `Wallpaper.setPattern` | `world.noteWallpaperChanged()` (repaint only) + the **one** menu that was clicked |
| input mode, fonts, wheel scaling, handle size… | `WorldWdgt.preferencesAndSettings` (`PreferencesAndSettings`) | `toggleInputMode` etc. | nobody |
| scroll offset | `ScrollPanelWdgt` (`@contents` position) | `scrollX`/`scrollY`, wheel, drag, `scrollTo`, the bars | `_reLayoutScrollbars` → its own two bars |

Note the engine does **not** require node-ness to be widget-ness: `SecondsSource` and `FrameSource`
are plain non-widget objects that implement `dataflowValue()` and nothing else. **Making `Wallpaper`
a node costs zero engine change.**

### 2.6 Views that don't subscribe: the tick family

Four independent hand-rolled "refresh my own checkmarks" routines exist, each reflecting state it
does not own, each only for its own instance and only at the moment it was clicked:

- `Wallpaper.updatePatternsMenuEntriesTicks` — rewrites `rows[1]`…`rows[7]` **by index**;
- `StringWdgt`'s font menu (`:1066-1071`) — same shape over nine font stacks;
- `TextWdgt` "soft wrap" (`:609`) and `ControllerMixin` "fires per event" (`:92-95`) — label built
  once at menu-build time with `String::tick()`.

`Wallpaper`'s own comment is the specification of the gap:

> *cheap way to keep menu consistency when pinned … note that there is no consistency in case there
> are multiple copies of this menu changing the wallpaper, since there is no real subscription of a
> menu to react to wallpaper change coming from other menus or other means (e.g. API)…*

The `rows[1..7]` indexing is separately fragile: it breaks the day someone adds a divider.

### 2.7 Controllers that aren't views: the palette — ⚠ **SUPERSEDED by P6 (landed 2026-08-17)**

The shared-immutable-buffer FACT below still holds and is still the constraint; what has changed is
the consequence. The palette now paints its choice live OVER the blit (`PaletteAppearance`), both
riders are resolved (the choice seed is deleted, not relocated — see P6 "As landed" (iii)), and
`ColorPickerWdgt` has the `ControllerMixin`, so neither class is missing its half any more.


`PaletteWdgt` holds `@choice` and paints **nothing** about it. Its pixels come from a back buffer
that is *shared and immutable*: `_createRefreshOrGetBackBuffer` keys
`world.cacheForImmutableBackBuffers` on `constructor.name + extent`, so **every palette of the same
size shares one canvas** — a per-instance marker can never be painted into the buffer.

Two riders found while reading it:

- `_createRefreshOrGetBackBuffer` sets `@choice = Color.BLACK` on a cache **miss** only, so the
  first palette of a given size has its choice reset by buffer construction while later ones do
  not. A fused axis (buffer building vs. state initialisation) worth splitting regardless of this
  arc.
- The answer already exists next door and doesn't compose: `ColorPickerWdgt` shows its colour with a
  `feedback` `RectangleWdgt`, driven by giving its two child palettes `@target = @feedback`. But
  `ColorPickerWdgt` is *not* a controller (its file opens with "the ColorPicker has no *set
  target…* from the menu"). So the system has **the picture without the handle in one class and the
  handle without the picture in the other**.

### 2.8 What duplication actually does to a wire

`Duplicator._duplicate` keeps out-of-structure widget references as-is
(`keptByReferenceOnDeepCopy` / the dispatch core). So duplicating a wired controller yields a second
controller **pointing at the same target**, and `ControllerMixin._fireConnection`'s lazy
`ensureWireEdge` gives it a working edge on its first fire. Fan-**in** therefore already works by
duplication: two sliders, one target, both drive it.

What does not work is fan-**out** and reflection. The design principle
([`../architecture/design-principles.md`](../architecture/design-principles.md), "Duplication as a
first-class power") promises the copy is *alive*, with "in-group wiring … along". Today that is true
of the wire the copy *owns* and false of everything aimed *at* the original.

### 2.9 The competing mechanism already in the tree: per-cycle reconcilers

`doOneCycle` runs, **after** the dataflow drain and after the layout flush:

```
@pinouts?.reconcile()
@addHighlightingWidgets()
@_updateEditorSelectionOverlay()
@addDragAffordanceWidgets()
```

These are declare-and-reconcile passes: a producer writes a declaration into a world-level Map
(`world.widgetsToBeHighlighted`), and one reconciler adds/updates/removes the overlay widgets,
emitting **zero damage** when nothing changed. This is a real, working, second answer to "a view
that must track state it doesn't own" — and it is the *right* answer for **ephemeral overlays**. It
is the wrong answer for **values**, because it polls. The line between them should be stated
explicitly (§5), because the temptation to reconcile the palette marker or the menu ticks will be
strong and it would fork the mechanism.

---

## 3. The five gaps, named

| # | Gap | Blocks |
|---|---|---|
| **G1** | ~~**Write-only pins.**~~ ✅ **CLOSED by P1** (2026-08-16): a `PinSpec` may declare a reader, and `Widget.exportedValue` is now a declared principal pin rather than a duck-typed probe. What remains is populating readers — most pins are still write-only, honestly so. | ~~any generic reverse edge; showing current values; per-property spreadsheet reads~~ |
| **G2** | ~~**Single-slot, one-way wires.**~~ ✅ **CLOSED by P4** (2026-08-17): a controller owns an ordered `@wires` list of `WireSpec` records, `wireTo` ADDS, `unwireFrom` removes, and the menu shows one row per live wire with a `disconnect`. The engine mirrors the list (`ensureWireEdges`) and now delivers EVERY record joining a pair, which single-slot wiring had hidden. ⇒ §P2's return wire has a slot, and `FanoutWdgt` is an affordance over a universal capability. | ~~two-way binding (the return wire has nowhere to live); the citizenship doc's own claim~~ — **unblocked** |
| **G3** | **Change announcement is opt-in and rare.** Six classes announce, for one property each. ⚠ **PARTLY closed for NON-WIDGET holders by P5+P7** (2026-08-17): `Wallpaper` and `PreferencesAndSettings` now announce, and their menu rows follow from anywhere. For a WIDGET it is still all-or-nothing — one `dataflowValue`, so announcing a property change fires its wires — which makes **P3 a hard prerequisite for the rest of P7**, not an independent proposal. | anything driven by a menu, a script, the loader, or another widget's method call |
| **G4** | ~~**Non-widget state has no node identity.**~~ ✅ **CLOSED by P5** (2026-08-17) for `Wallpaper` and `PreferencesAndSettings` — both are dataflow nodes now, with zero engine change, exactly as `SecondsSource`/`FrameSource` predicted. Scroll offset remains, and belongs to §P8. | ~~the wallpaper-menu complaint outright~~ — **closed** |
| **G5** | **Reflection is private field plumbing.** `if @vBar.target == @ … updateSpecs`; `_updateHandlePosition` on one class with one caller. | duplicated/foreign controllers following the value |

Complaint ① is G5 + G1 + G4(scroll). Complaint ② is the *view* half of the law plus G1. Complaint
③ is G4 + G3 + G6-as-view (§2.6).

---

## 4. Proposals

Ordered by dependency, not by value. §6 gives the recommended landing order, which is different.

### P1 — Pins become readable — ✅ **LANDED 2026-08-16**

Replace the parallel-array pin tables with a record per pin, the way `MenuItemSpec` already replaced
a twelve-argument positional list:

```coffee
# sketch only
class PinSpec
  constructor: (@label, @kind, @set, @get) ->   # kind: "numerical" | "string" | "color"
```

- `@get` may be `undefined`: that declares a **write-only pin**, and `bang` is the canonical one. A
  write-only pin can be driven and can never be bound two-way. *Name the asymmetry; do not fake a
  reader.*
- `Widget.exportedValue()` becomes "the value of my principal pin" instead of the duck-typed
  `getColor?() ? getValue?() ? @text` chain — one chain fewer, and it stops being a coincidence that
  `SliderWdgt` had to grow `getValue: -> @value` to join the spreadsheet protocol.
- `DataflowEngine.pullValue` gains a pin-aware sibling (`pullPinValue node, pinName`), used by the
  reverse edge. The forward path is unchanged.
- Riders that fall out for free: `Example3DPlotWdgt`'s missing `super`, and the fact that
  `ScrollPanelWdgt` advertises no pins at all today (§P8).

Cost is real but bounded: ~19 setter overrides on 9 classes. Menu labels are unchanged, so screenshot
churn should be limited to inspector member-list shifts (the familiar benign recapture class).

#### As landed

`src/basic-widgets/PinSpec.coffee` + `Widget.pins` / `pinsOfKind` / `pinLabelled` / `principalPin`,
replacing `colorSetters` / `stringSetters` / `numericalSetters` / `allSetters` /
`deduplicateSettersAndSortByMenuEntryString` / `_appendSettersAndDedup` /
`addShapeSpecificNumericalSetters` (all DELETED). **19 setter overrides on 9 classes → 9 `pins`
declarations.**

Six deviations from the sketch above, each because building it made the sketch wrong:

| # | sketch | as landed | why |
|---|---|---|---|
| 1 | `@set` / `@get` | `setterName` / `getterName` | they hold method NAMES; `pin.get()` is a call waiting to be written by mistake |
| 2 | `(label, kind, set, get)` positional | `(label, kind, opts)` with `set`/`get` in `opts` | `set` and `get` are *independently* optional, so positional forces a hole (constructor conventions R3) |
| 3 | `kind` is one of three strings | one kind, an ARRAY of kinds, or `"any"` | `bang` accepts anything and a patch-node input accepts string-or-numerical. **This is where the 19→9 collapse comes from**: one table per kind meant a pin taking any value had to be declared once per table |
| 4 | `get: undefined` ⇒ write-only | *plus* `set: undefined` ⇒ READ-ONLY | `ColorPickerWdgt.getColor` reads `@feedback.color` while `Widget.setColor` writes `@color` — different properties. The arrays could not express a readable-but-undrivable pin at all |
| 5 | principal pin named by setter | named by LABEL (`principalPinLabel`) | a read-only principal pin has no setter to be named by |
| 6 | `DataflowEngine.pullPinValue` lands here | lands with its first caller (P2/P7) | it has no consumer until the reverse edge, and the dead-method gate is right to refuse an unverifiable method. `Widget.pinLabelled` + `PinSpec.getterName` are the whole mechanism; the pull is three lines on top |

**`producesPinKind` is the other half.** Every controller declared the kind it drives TWICE, in two
unrelated places — by which setter table its `openTargetPropertySelector` passed, and by the word its
`_addTargetConnectionMenuEntries` put in a tooltip — and nothing compared them. Two disagreed
(`SimpleTextWdgt` said "numerical" while offering string pins; `FanoutPinWdgt` said "color" while
offering all of them). One class-level field now feeds both, which let the 5 per-class
`openTargetPropertySelector` stubs collapse into one shared method on `Widget`.

**Three defects the arrays were hiding**, each found by having to state a pin exactly once:

1. **`StringWdgt` advertised a `bang` pin it does not implement.** `bang` is on `SimpleTextWdgt`, so
   wiring anything to a plain `TextWdgt`/`StringWdgt` offered a target property that dispatched to
   nothing — `consumer[action]?.call` swallows the miss silently. The pin now sits on the class with
   the verb.
2. **`Example3DPlotWdgt.numericalSetters` did not call `super`** (the rider the plan predicted): it
   rebuilt the accumulator from scratch, so a plot advertised `param` and *nothing else* — no
   width/height/alpha/padding, no shape pins. With parallel arrays, forgetting to chain looks
   identical to declaring your own table; `super().concat` cannot make that mistake.
3. **`deduplicateSettersAndSortByMenuEntryString` deduped its two arrays INDEPENDENTLY**, with two
   separate `Set`s. A label repeated against a different setter (or the reverse) shortened one array
   and not the other, silently pairing every later label with the wrong setter. Latent, not live —
   every duplicate in the tree happened to be a 1:1 pair — and gone by construction now that a pin is
   one object.

**`exportedValue` is now the principal pin's value**, not `getColor?() ? getValue?() ? @text`. The
old chain's `@text` arm was wrong for the two classes where `@text` holds a child WIDGET
(`StringFieldWdgt`, `MenuHeader`) and only got `StringFieldWdgt` right by accident, because
`getValue` came earlier in the probe order. `MenuHeader` now exports nothing, which is correct.

**One cost, measured not assumed.** `exportedValue` is reached by `dataflowValue`, which the drain
PULLS on every pass — and it now walks `pins()`, which BUILDS its `PinSpec` list per call (~10 for a
bare widget, ~15 for a slider). The old duck-typed chain was three property lookups and zero
allocation. Measured: the dpr1 suite ran 64 s against 63 s before, and the paint audit 92 s against
92 s — no detectable change, which is unsurprising in a tree with 941 `new Point` sites on hotter
paths than this. **So it is recorded, not optimised.** If it ever does show up, the fix is a per-class
memo of the DECLARED pins (sound: only the appearance's contribution is instance-dependent, and the
principal pin is never an appearance pin) — do not reach for it without a measurement that says so.

**Deliberately NOT done:** `width`/`height` stay WRITE-ONLY although `width()`/`height()` are right
there — a HOLDING position, not a verdict. It costs nothing today (no binding exists and no menu shows
current values) and is one line to reverse. §8 q1 was reframed on 2026-08-17: the live candidates are
(c) and (d), and §P8 is the experiment that chooses between them. `ScrollPanelWdgt` still advertises no pins (§P8 owns that).

### P2 — Reciprocal binding: **two wires, not a new edge kind** — ✅ **LANDED 2026-08-17**

The tempting move is a `reflects: true` attribute on the edge record (which already carries
`{consumer, action, firesPerEvent, cold}`). **Recommend against it.** The system already has a
working, measured, in-production two-way binding: the °C↔°F converter
(`src/examples/degrees-converter/DegreesConverterApp.coffee`) is a **six-node ring of ordinary
one-way wires**, and the engine's visit-once + equal-value cutoff walk it exactly one lap and stop
where the change entered (spec §7; measured at 1 pass in
`docs/measurements/dataflow-measurements.md`).

So a binding should be *the pair of wires*, and the new thing is a **gesture**, not a mechanism:

- a `bind ⇄` menu entry alongside `connect to ➜` that creates both wires at once, given a pin on
  each side (source pin needs `@get`; both need `@set`);
- nothing new in the engine, nothing new in serialization, no new failure mode.

Its hard prerequisite is **G2**: the return wire needs a free slot on a widget that is very often
already wired. That is why P4 comes before P2 in dependency order even though P2 is the headline.

Open sub-question for the owner: **who wins at bind time.** Both wires would run their
`reactToTargetConnection` and fire; today the second one wired wins. Proposed rule: *the side whose
menu you opened is the source of truth at bind time* — it pushes, the other reflects.

#### As landed

**"Given a pin on each side" is NOT expressible with two ordinary wires, and that is what shaped the
gesture.** A wire delivers its producer's PRINCIPAL value — `DataflowEngine.pullValue` →
`Widget.dataflowValue` → `exportedValue` → the principal pin's reader — and the pin chosen on the
receiving side supplies only the SETTER. So a return wire aimed at anything but the initiator's
principal pin would carry a quantity its producer does not own. A bind is therefore **principal ⇄
principal**, both pins are forced, and `bind ⇄` has **no property step at all** — pick a target and you
are done, where `connect to ➜` still has to ask which pin.

⭐ **The engine has exactly TWO production granularities, and a bind exists at each — both already
built.** This is the frame the sketch was missing:

| granularity | announce verb | the edge | the consumer |
|---|---|---|---|
| the **NODE** — *"a node has exactly ONE value"* | `markStale` | a wire | is HANDED the value |
| a **PIN** — *"an object has many properties… announcing those with markStale would be a lie"* | `markNonValueChange` | `firesOnAnyChange` | RE-READS the producer |

A bind at node granularity **is two wires** (this section). A bind at pin granularity **is
`trackTarget`** (§P8), whose reverse half asks its consumer to re-read. There is no third thing to
build, which is why nothing was added to the engine, to serialization, or to the failure modes — as
promised, though not for the reason given.

⭐⭐ **Restricting to principal ⇄ principal is what makes the offer HONEST, and that is the real
argument for it.** The precondition "both sides announce when their value changes" has no declaration
behind it — nothing on a `PinSpec` says *"I announce"* — so a pin-to-pin gesture could offer binds
whose reverse half silently never fires. At node granularity the precondition is **equivalent to a
checkable one**: a widget with a read/write principal pin *and* the `ControllerMixin` verbs is exactly
a widget that announces (verified across all four: `SliderWdgt`, `StringWdgt`/`SimpleTextWdgt`,
`PaletteWdgt`, `ColorPickerWdgt` — each `updateTarget` → `_fireConnection` → `markStale`). So
`ControllerMixin.canBind` is not a proxy for the property that matters; it IS that property.
⚠ **This was true for a BIND and false for a FOLLOW until 2026-08-18** — `_fireConnection` was silent
while the widget held no wires, which is exactly a follower's situation. See the residue note at the
end of this section.

⇒ **`DataflowEngine`'s reserved pin-aware `pullValue` sibling is ANSWERED, not consumed.** Its comment
named "the `bind` gesture (P2/P7)" as the first caller it was waiting for. The pin-aware pull belongs
to the RE-READ edge, which already has it (`Widget.pinDrivenBy` → `getterName`, landed with §P8), so
the reservation is deleted rather than fulfilled — a method with no caller still cannot be kept honest.

**The shape.** `bindTo` is the fourth binding verb, and it is where §8 q3 gets its answer:

```coffee
@wireTo theTarget, theTarget.principalPin().setterName      # I push MY value
theTarget.declareWireTo @, @principalPin().setterName        # the return wire moves nothing
```

⇒ **§8 q3 ANSWERED: the side whose menu you opened pushes** — and P4's third verb is what makes it
*exact* rather than aspirational. Two pushes would merely let the later one win, which is an accident;
`declareWireTo` states the rule. The alternative (an explicit source/mirror step) was rejected on two
grounds: every other connect gesture already takes the opened menu as its subject, so bind would be
the only one asking again; and the choice's consequence is invisible one frame later, since the pair
is then equal. The tooltip carries it instead.

**The target chooser FILTERS, where `connect to ➜` defers to a property menu.** Four conditions, one
per thing that must hold for both wires to be real (`_canBindTo`): not myself, each side owns a
read/write principal pin, it can hold a wire back (`declareWireTo?` — a capability probe), and each
principal pin accepts the kind the other produces. Widgets whose value is COMPUTED — `PatchNodeWdgt`,
`FanoutWdgt`, `FanoutPinWdgt` — declare no principal pin and so never offer or accept a bind, which is
correct: there is nothing to write back into. ⭐ A free side-effect: the filter DISSOLVES the "a
Slider" / "a SliderButton" prefix ambiguity that forces the older patch-cycle tests to pick their
target by meaning — a `SliderButtonWdgt` owns no value, so it is never listed.
  The same list decides whether the ITEM appears at all: `bind ⇄` is absent when nothing can be bound
to, which is `canBind`'s rule applied to the world rather than to the subject. The asymmetry with the
always-offered `connect to ➜` is earned — almost anything has a drivable pin, so connecting is nearly
always possible, whereas binding needs the other side to own a value of a matching kind, which is rare
among the widgets one happens to overlap. Asking inside the submenu rather than in the enclosing menu
also keeps the candidate walk on a CLICK instead of on every context menu a controller opens.

⭐ **`⇄` is DERIVED, and that is the whole design.** A wire's row is drawn `⇄` when the relationship
carries values both ways — `wire.tracks`, or the target holds a wire back onto my principal pin
(`isWiredToActionOf`, a public reader added because the `[U]` rule rightly forbids reaching into
another object's `_wireFor`). Nothing records that a pair is bound. Three consequences fall out and
none of them needed code: a pair wired BY HAND in two separate `connect to ➜` gestures *is* bound and
reads as bound (the gesture is a shortcut, not a distinct object); a 3-node ring correctly reads
one-way at every row; and DUPLICATING half a bound pair yields a copy that drives the original while
nothing drives the copy — whose row says `➜` with no bookkeeping to have gone stale.

**`disconnect` ends the relationship in BOTH directions**, and this is a consequence of P4 rather than
a new rule: `unwireFrom` already revokes the reverse edge of a *tracking* wire. The row named a
two-way relationship, so ending it leaves neither half — otherwise the surviving wire is invisible
from the menu you cut it in. The reciprocal call needs no guard (`unwireFrom` returns at once when
there is no such record) and cannot recur (it is `unwireFrom` being called, not `disconnectWire`).

⚠⚠ **THE GESTURES ARE GROUPED BEHIND ONE `connect ➜` ROW, and that is not cosmetic — it is what makes a
second gesture affordable.** The first shape gave `bind ⇄` its own top-level row beside `connect to ➜`,
and that row broke a test by making a menu item UNREACHABLE: **a pop-up taller than the world has no
handling at all.** `PopUpWdgt.popUp` clamps a pop-up's POSITION (`_moveWithin`) and can do nothing for
one that does not FIT, so the overflow is simply drawn past the bottom edge. A `SimpleTextWdgt` inside a
scroll panel already builds a merged menu of exactly full height, so one added row pushed its last item
(`soft wrap`) off the edge — the macro's click missed, the toggle never happened, and the test STALLED
rather than merely mismatching. Owner call (2026-08-17): group them. `connect ➜` opens a submenu of
`connect to ➜` + `bind ⇄`, so the enclosing menu gains **zero** rows, and the split is honest on its own
terms — the gesture rows are the things you can DO, the wire rows below are things that ARE.
⇒ **a feature that costs every context menu a row is charging rent against a budget nothing measures**;
(⚠ **the budget is measured now**: the pop-up-overflow arc bounds a pop-up to the world and scrolls the
overflow, so a menu row no longer costs reachability — see `docs/BACKLOG.md`. The grouping stands on its
own terms, and the same arc found that the constraint recorded here was already being VIOLATED in the
shipped build by two other menus, which is why "the trip-wire is not armed" below was wrong.)
ask what the row costs before asking whether the feature is worth it. The overflow itself is filed
(BACKLOG) as its own arc: the next row anyone adds re-arms it, and no gate watches for it.

⚠ **The grouped row must REPLACE its parent menu, not stack on it** — it deliberately does not pass
`closesUnpinnedPopUps: false`, unlike the `wallpapers ➜` / `test menu ➜` submenu convention it otherwise
follows. `openTargetSelector` enumerates world widgets, so a parent menu left standing offers its own
`MenuItem`/`Text` children as plausible targets: the chooser filled with `a Menu ➜ | a MenuRowsPanel ➜ |
a MenuItem ➜ …`. ⇒ **a menu is part of the world it is a menu for**, so any gesture that ENUMERATES
widgets must run with the menus already gone. This was caught only because three tests
(`macroLonelySliderTargetsWorldOnly`, `macroUniqueTargetAndPropertyAreStillPresented`,
`macroAttachTargetExcludesClippedWidget`) assert the chooser's contents BY STRING — a screenshot-only
test would have baselined a chooser full of menu internals as "the new look".

⚠ **A copy-paste that the acceptance test caught, worth keeping.** The bind chooser's items first
carried `closesUnpinnedPopUps: false`, lifted from `openTargetSelector` without asking what it is FOR:
there the click opens a SECOND menu (the property chooser) that must stack on a chooser still standing
underneath. A bind target item is TERMINAL, so the flag stranded the menu open — visible in the
reference image as a live menu and a still-highlighted target (a `representsAWidget` item's
`mouseLeave`, which clears the highlight, cannot fire on an item destroyed by the click).
⇒ **an option copied from a sibling call site is a claim about THIS call site**, and the two differ
exactly when one gesture continues and the other completes.

**Acceptance: `SystemTest_macroBindTwoSlidersAndUnbind`** (new). Two sliders started at DIFFERENT
values, so the precedence rule is PHOTOGRAPHED rather than asserted — image_2 shows B jumping up to
meet A. Then B drives A (the direction a one-way wire cannot carry), and after `disconnect` the
discriminating image is **A** dragged, not B: A's wire is the half a one-sided cut would leave
standing. ⚠ Its `⇄` assertion is a LABEL-STRING match, not a pixel: under SWCanvas neither `➜` nor
`⇄` is in the bitmap font and both render as the same box glyph, so the screenshot proves the row
exists and is unique and nothing more. The match was verified to bite by planting the wrong arrow —
the macro stops short and the harness's MACRO INCOMPLETE guard fails the test.
⇒ **when a distinction lives in a glyph, assert the STRING** — a reference image cannot see the
difference between two characters the font does not have.

⚠ **What P2 did NOT do: the pin-granularity GESTURE — ✅ LANDED 2026-08-18, and it turned out not to
be a gesture at all.** `PinSpec` gains `announces`; the reachable gesture is the row **"follows it
too"** in a WIRE's own menu, promoting a wire that already exists rather than choosing a new target —
because `pinsOfKind` has always offered `scroll y`, so "connect to ➜" could already build that wire
and only its reverse half was missing. `trackTarget` was written for this caller before it had one.
⭐ **The audit was the work, and its domain was TWO PINS.** Of 40 `PinSpec`s, 33 are write-only (this
section's own reverse half is not expressible for them) and six of the seven readable ones are
PRINCIPAL pins that this section already covers — so every readable non-principal pin in the tree is
`ScrollPanelWdgt`'s `scroll x`/`scroll y`.
⭐⭐ **And the equivalence this section leaned on was narrower than it reads — it named a DEFECT.**
*"A widget with a read/write principal pin and the `ControllerMixin` verbs is exactly a widget that
announces"* held for a BIND, whose reverse half is an ordinary wire the target holds, and failed for a
FOLLOW: `_fireConnection` made the announcement a side effect of the DELIVERY, so its wire guard
silenced both — and a follower subscribes without being driven. **One event, two jobs, one guard on
the wrong one.** Fixed here: it announces first and delivers second, and `StringWdgt` `text` plus both
`picked color` pins now declare `announces: true` truthfully. `SliderWdgt.value` still cannot — its
REFLECTION paths have no equal-value cutoff, so announcing there would re-fire every drain pass with
no cycle involved — and that, the second reflector it would serve, and the mutual-tracking cycle rule
are one arc, filed in `BACKLOG.md`.

### P3 — One announcement verb, and where it may not live — ✅ **LANDED 2026-08-17**

For a reverse edge to fire, a sink must mark itself stale when its property changes **by any means**.
Proposal: one intent-named public note, the generalisation of `WorldWdgt.noteWallpaperChanged`:

```coffee
# Widget (sketch)
_notePinChanged: (pinName) ->
  return unless world.dataflow.hasOutEdges @    # cheap: dark when nothing is wired
  world.dataflow.markStale @
```

called from the small set of pin setters (`setColor`, `setBackgroundColor`, `_setTextNoSettle`
already effectively does it via `updateTarget`, `setPattern`, …). `updateTarget` then reads as the
special case of `_notePinChanged` for the principal pin.

#### As landed

⚠ **The sketch above ignores its own `pinName`, and that is exactly where it is wrong.** A node has
ONE value (`Widget.dataflowValue` → `exportedValue()`), so `markStale` can only ever mean *"my value
changed"*. Announcing a **non-value** property with it is a lie the engine then acts on. **Measured**,
not argued (`Fizzygum-tests/.scratch/p3-announcement-falsefire-probe.js`) — a naive `markStale @`
costs a wired widget exactly one spurious apply per wire:

| target pin | what the spurious apply does |
|---|---|
| an ordinary value pin (`setValue`) | **inert** — the target re-applies a value it already holds, and its own equal-value cutoff stops the traversal there (0 onward marks) |
| **`bang`** | **cascades** — `bang` is a FORCE-fire (`markStale @, true`), which is exempt from the cutoff by design, so the spurious fire propagates onward (1 onward mark) |

⇒ the plan's framing ("would deliver its *text* to whatever it drives") is right about the mechanism
and overstates the general harm while understating the specific one. **What landed is a split, not a
verb**, and it lives on the engine beside its sibling rather than as a `Widget` wrapper (which would
be a thin wrap over one engine call, and rightly rejected as one):

```coffee
markStale node            # my VALUE changed        -> fires EVERY out-edge   (unchanged)
markNonValueChange node   # a non-value property    -> fires only `firesOnAnyChange` edges
```

and the matching half on the edge: **`firesOnAnyChange: true`** says *"my consumer RE-READS the
producer rather than receiving its value, so wake it for either announcement."* That is precisely a
reflected menu row — it ignores the delivered value and re-reads through its own `readerName` — so
`MenuRowsPanelWdgt._subscribeToReflectedSource` declares it and wires do not.

**Additive by construction: every existing edge and every existing `markStale` keeps its exact
meaning, and the new announcement fires strictly FEWER edges.** Before anything declares
`firesOnAnyChange`, the whole change is a no-op — which is what made it safe to land at the root of
the drain. `markNonValueChange` is also **dark unless someone re-reads** (`_hasAnyChangeSubscriber`),
which matters because its callers are ordinary property setters.

**⭐ The trap it exposed, which had nothing to do with the announcement.** `_removeOutgoingEdgesOf`
cleared **every** out-edge of a re-wired producer, resting on a comment that said why that was safe:
*"a ControllerMixin producer owns at most one out-edge (one `@target`/`@action`)"*. True until P5/P7
made a widget subscribable — after which re-wiring a text whose fonts menu is open would **silently
unsubscribe that menu**, resurrecting the exact stale-tick bug this arc exists to kill. Now
`_removeOutgoingWireEdgesOf`, which spares `firesOnAnyChange` edges, with `_wireEdgeRecord` (the wire
specifically) split from `_edgeRecord` (any edge) so a reflection can never be mistaken for the wire.

**Verified, four claims, `Fizzygum-tests/.scratch/p3-nonvalue-announcement-probe.js`:** (A) a
non-value announcement does not fire a wire — 0 bangs; (B) a value announcement still does — 1 bang;
(C) a reflecting menu hears the non-value change — the fonts tick moves Arial → Mono on a pure API
call, with ONE out-edge on the text; (D) a re-wire spares the subscription — old wire dropped, new
wire present, menu still subscribed AND still following changes.

**P7's remaining three sites are converted** (see §P7's table), which is what P3 was blocking:

| site | reader | retired |
|---|---|---|
| `StringWdgt` fonts menu | `currentFontName` | `updateFontsMenuEntriesTicks` + `@FONT_STACK_MENU_ENTRIES` + the `rows[i+1]` indexing + `_setFontNameNoSettle`'s `menuItem` parameter |
| `TextWdgt` "soft wrap" | `isSoftWrapping` | the build-time `if @softWrap then …tick() else …` fork |
| `ControllerMixin` "fires per event" | `isFiringPerEvent` | ditto |

⚠ **Not pixel-free, deliberately.** `MenuRowReflectionSpec.tickWhen` pads an unticked label with
`untick` (four spaces); the two toggle rows previously showed a bare label when off, so they were the
only ticked-family rows that did not reserve the tick column. They now align like every other one.

**⭐ A second regression, from the same change and nothing to do with announcing.** `SimpleTextWdgt`
removes the "soft wrap" row it inherits **by its decorated label**, trying three spellings
(`"soft wrap"`, `"soft wrap".tick()`, and a duplicate of the first). Turning the row into a reflection
made its unticked spelling `untick + "soft wrap"`, which matches none of them — the row would have
silently reappeared. Fixed at the root rather than by adding a fourth spelling:
`MenuRowsPanelWdgt.removeMenuItem` compares **undecorated** on both sides (new
`String::withoutTickDecoration`), and the three lines collapse to one. ⇒ **Making a label DYNAMIC
breaks everything that matched it as a CONSTANT.** Two SystemTests were failing on this and pass
again untouched, which is how it was confirmed rather than assumed.

**Recaptures: 11**, all the inspector member-list class (the list gained `_fontStackMenuEntries` and
lost `updateFontsMenuEntriesTicks`; every changed region is one row at a fixed coordinate). Discovery
first reported 13 — the two that dropped out are the `removeMenuItem` repair.

⚠ **Geometry pins are the genuinely hard case and should be excluded from v1.** `width`/`height`/
`padding` are pins today (`Widget.pins` → `_applyWidth`, `_applyHeight`, `setPadding` — all
WRITE-ONLY, which is P1's holding position on exactly this question),
and they are written *inside the layout settle*. The engine's standing law is that the coupling is
one-way — dataflow may dirty layout; **layout must never mark dataflow stale** (spec §5, the
`DataflowEngine` class header, the `doOneCycle` comment). A `_notePinChanged` in `_applyWidth`
would break it. Options, none free:

- (a) geometry pins stay **write-only** for binding purposes (honest, cheap, and consistent with
  §P1's write-only concept);
- (b) announce from the *desired* funnel only (`Widget._moveToNoSettle` / `__commitExtent`) and
  accept that engine-driven geometry does not re-announce — needs proof that the funnel is never
  reached from inside a settle, which it certainly is;
- (c) a deferred announcement drained on the *next* cycle — reintroduces the one-cadence lag the
  drain placement was chosen to avoid (spec §4.1).

#### ⚠ REFRAMED 2026-08-17 after an owner challenge — the earlier "recommend (a)" was under-argued

**The one-way law is a consequence of the CYCLE ORDER, not a preference.** `doOneCycle` runs
`recalculateDataflow()` (values) and *then* `recalculateLayouts()` (geometry). So dataflow→layout
lands in the SAME frame's paint, while anything layout marks stale has already missed the dataflow
station. That is the whole content of "layout must never mark dataflow stale".

**Two facts weaken the case for (a) as a permanent answer, and both were missed above:**

1. **Layout ALREADY notifies dependents.** `ScrollPanelWdgt._reLayoutScrollbars` does
   `if @hBar.target == @ … @hBar.updateSpecs start, stop, value, size` — literally "the layout
   settled, tell the bound thing", done synchronously and by hand to one hard-coded object. That is
   gap **G5**. Routing it through the drain GENERALISES a direction the system already has; it does
   not invent one.
2. **"It would be a second cadence model" is a weak objection.** The engine already has ordered
   settle stations. *"Values derived from geometry arrive one station later"* is a statable rule.

**The one real cost is narrower than "a lag": a TRACKING PAIR shears by one frame under fast
motion.** A monitor showing a window's width does not care about 16 ms. A scrollbar tracking its
content does — and that is complaint ① exactly. Today the bar and content are welded within a frame
because `updateSpecs` is synchronous.

**⭐ Whether the shear is VISIBLE is unknown and measurable, and that is the deciding fact.** The
thumb moves proportionally less than the content (a 300 px content move might be 20 px of thumb), so
one frame at speed is perhaps 3–5 px. **§P8 is the first real consumer and therefore the experiment:
build it against (c), drive a fast wheel-scroll, and look.** Do not settle this from priors.

| option | what it costs |
|---|---|
| **(a) write-only** | no geometry binding; no current values in connect menus. **The HOLDING position, not the answer** — costs nothing today because neither consumer exists yet, and is one line to reverse |
| **(b) announce from the desired funnel** | ⛔ **does not work**: `_moveToNoSettle`/`__commitExtent` are the leaves BOTH paths funnel through (a stack arrange calls `_applyWidth` → `__commitExtent` on its children), so it announces from inside the settle — the violation itself |
| **(b′) announce unless `world._recalculatingLayouts`** | ⛔ **REJECTED PERMANENTLY.** Works for gesture-driven changes and is SILENTLY WRONG for engine-driven ones (resize a window ⇒ its stacked children's widths change inside the settle ⇒ nothing announces). A reader that is right *sometimes*, with the asymmetry invisible to the author, is worse than none — §P1's own "name the asymmetry, do not fake a reader" |
| **(c) notify at end of layout, drain NEXT frame** | 🟢 **LIVE.** One frame of lag; no extra work. Cost falls only on tracking pairs (see the shear measurement) |
| **(d) notify at end of layout, drain SAME frame** | 🟢 **LIVE.** No lag; needs a second `recalculateLayouts` in the same cycle (the re-entrancy guard throws only on re-entry from INSIDE a pass, so a sequential second call is legal). `layout → dataflow → layout` is a fixpoint one level up from what each station already does. Wants a cap, as the drain has `DATAFLOW_NONCONVERGENCE` |
| **(e) readable-for-display, not bindable** | orthogonal and cheap: a menu showing current values needs a PULL, not an announcement, so geometry could answer it with no law involvement. Needs `PinSpec` to separate "has a reader" from "can be bound" — **introduce it with P2**, which must answer "which pins can be bound?" anyway, rather than before a caller exists |

**⇒ Decision recorded: keep (a) as the holding position; (c) and (d) are the live candidates; (b) and
(b′) are closed. The deciding experiment belongs to §P8.**

### P4 — A controller owns a LIST of wires — ✅ **LANDED 2026-08-17**

Replace the `@target`/`@action` pair with an ordered list of wire records on the widget:

```coffee
@wires: [{target, action, firesPerEvent, cold}, …]
```

- `@target`/`@action` survive as accessors onto `@wires[0]` through the migration, so the ~15 direct-
  assignment sites (scrollbars, prompt slider, `DegreesConverterApp`) keep working while they are
  converted.
- `ensureWireEdge` mirrors the **list** instead of the pair; `_removeOutgoingEdgesOf` stops being a
  blunt "clear all my out-edges" and becomes a per-wire removal.
- **Un-wiring falls out**: removing a record is the missing idiom, and a "disconnect ➜" menu entry
  becomes writable.
- Serialization: an array of plain records; in-structure widget references are already handled by
  the `{"$r": n}` machinery, out-of-structure ones by the existing external-reference rule
  ([`../architecture/serialization-duplication-reference.md`](../architecture/serialization-duplication-reference.md)).
  The `own-only-when-set` idiom is preserved by leaving `@wires` a prototype-level `undefined`.
- **`FanoutWdgt` becomes a visual affordance over a capability every citizen has**, instead of the
  only way to have one. That is what citizenship point 5 ("it composes, and decomposes") wants, and
  it removes a reason the class is stuck outside production.

This is the single change that unblocks the most, and it is the one with real serialization
surface. It deserves its own arc.

#### As landed

**The `@target`/`@action` accessor shim above is NOT BUILDABLE, and finding that out is what shaped
the arc.** `Class`/`Mixin` emit every declared member as `prototype.<name> = <expr>` — they parse a
field's source text and assign it — so a getter/setter cannot be *declared* in this codebase at all,
and there is not one instance accessor anywhere in `src/` (the only `Object.defineProperty` calls
name a function or patch a vendored SWCanvas prototype). A shim was also the wrong thing on its own
terms: it would state each wire's target twice, which is the drift `PinSpec`'s own header warns
about. So there is no migration period — **every site converted in one pass**, which the owner's
standing constraints (no serialised worlds of interest, recapture churn irrelevant) made free.

The record is a class, **`WireSpec`** (`src/basic-widgets/WireSpec.coffee`, beside `PinSpec`), not a
bare literal — the layout-spec family is the precedent: one spec object per ATTACHMENT, living on the
widget, serialized with it, carrying knobs. ⚠ It is explicitly a MUTABLE spec, not an immutable value
class: `firesPerEvent` is flipped in place by its menu row. Its prototype-level defaults are what keep
an untoggled wire serializing as just `{target, action}` — the own-only-when-set idiom, one level down
— and `@wires` itself is a prototype-level `undefined` (never a shared array), so an unwired widget
serializes byte-for-byte as before and `unwireFrom` `delete`s the field rather than leaving `[]`.

**Both per-wire policies MOVED ONTO the record.** `firesPerEvent` was already documented as "a
per-wire delivery policy" while living on the controller, where it could only ever be one policy for
every wire; `tracksTarget` (§P8) became `WireSpec.tracks`, because tracking is a property of the
RELATIONSHIP — a controller may follow one target while merely driving another. That is what forces
the menu shape below: with N wires there is no single row for "the" policy.

⭐ **THREE binding verbs now, and the third is §P8's lesson finishing itself.** §P8 established that
the direction of the on-connect push is part of what a bind MEANS. The full set:

| verb | the wire | on connect |
|---|---|---|
| `wireTo` | I drive it | I push MY value (`reactToTargetConnection`) |
| `trackTarget` | I drive it **and follow it** | I take ITS value (§P8) |
| `declareWireTo` | I drive it | **nothing moves** |

The third exists because `NumberPromptWdgt` poked `@target`/`@action` directly and therefore never
fired — silence that was incidental then and is now stated. It is not a nuance: that slider's action
rewrites the entry field to the ROUNDED slider value and opens an edit on it, so firing at
construction would round a fractional default away and pop a caret before the prompt is on screen.

**The menu is where G2 actually closes.** `wireTo` ADDS (idempotent per target+action), so
"connect to ➜" adds a connection, and each live wire gets its OWN row labelled by what it drives —
`"a Panel . color ➜"`, the target as the connect menus name it plus the PIN's label, not the raw
setter — opening that wire's little menu of "fires per event" + "disconnect". ⛔ The
`world.isIndexPage` label fork is deleted: "set target" is the name of a single-slot world and would
be a false promise once the gesture connects *a* target, one of several. (The fork had already rotted
— `StringWdgt`'s hand-rolled copy nested `if world.isIndexPage` inside itself, so its "set target"
branch was unreachable.) ⭐ The rows are the real payoff: a single-slot controller's one connection
was INVISIBLE and re-targeting silently dropped it; wiring is now legible and reversible.

⭐ **A `WireSpec` is a dataflow node.** Its "fires per event" row is a `MenuRowReflectionSpec` whose
`source` is the wire itself, so two wires' rows tick independently and a flip made anywhere re-ticks
every open menu. That needs nothing but a reader method and a `markNonValueChange` — the zero-engine-
change trick §P5 played for `Wallpaper`, and the reason the node protocol is duck-typed.

⚠⚠ **A LATENT ENGINE DEFECT that P4 makes reachable, found by reading the delivery path.**
`_applyIncomingWireEdges` walked `edgesTo` — which maps consumer → a Set of **producers**, collapsing
a pair however many records join them — and then took ONE record per pair via `_edgeRecord`. So two
wires from one controller onto two different pins of the SAME target would have delivered one and
silently dropped the other; and where a pair carries a wire *plus* a `firesOnAnyChange` subscription,
it could pick the valueless record and deliver NEITHER. The RECORD layer always supported many per
pair — `_removeOutgoingWireEdgesOf` checks "no record at all is left", and `_wireEdgeRecord` existed
precisely to tell a wire from a subscription — only DELIVERY collapsed them. `_edgeRecord`/
`_wireEdgeRecord` became `_edgeRecords`/`_wireEdgeRecords` and both readers now walk all of them.
Unreachable before P4 (one wire per controller), which is why it sat there.

**`ensureWireEdge` → `ensureWireEdges producer, wires`**: the index mirrors the LIST, rebuilt whole on
any mismatch (`_wireEdgesMatch` counts BOTH ways — a wire with no edge and an edge with no wire are
equally a mismatch, and it is the second that un-wiring produces). ⭐ So **per-wire removal needed no
engine verb**: drop the record, reconcile, and the edge is gone because nothing derives it. The one
addition is `removeAnyChangeEdge`, for the tracking half — an edge OUT of the target that only its
subscriber can revoke — and it spares wire records in the same direction, which matters the moment
§P2 binds two widgets to each other.

**`unwireFrom` landed with its first caller already in the tree**: `CellWdgt._reactToChildGrabbed`
cleared the fields by hand under a comment reading *"no un-wire idiom exists in ControllerMixin —
verified 2026-07-17"*. Its blanket `removeAllEdgesOf` is gone too — it got away with being blunt only
because a value-widget in a cell had no other edges to lose.

⚠ **Two vestiges the conversion exposed, both deleted.**
1. `PaletteWdgt`'s constructor took `@target` as its FIRST parameter — a textbook positional hole
   (R3): every caller wanting a size passed `undefined` through it, ELEVEN of them in the suite, and
   the one caller passing a real target wired itself properly a line later anyway. It could not carry
   an action either, which is why `updateTarget` carried a "default the action to `setColor`" repair —
   so that repair was load-bearing, not vestigial, and both go together. ⚠ The `positional-hole` stink
   reads `src/` only, so eleven live holes sat in the tests repo where no gate could see them.
2. `argumentToAction` — declared on three controllers, written by one site, and read by NOBODY
   (`_fireConnection` documents that it ignores it). A field that was declared, duplicated and
   serialized to say nothing.

**Acceptance: `SystemTest_macroPaletteRetargetsToNewWidget` → `macroPaletteFansOutAndDisconnects`.**
Its stated intent was *"exactly one live target at a time"* — a recording of gap G2, not of a desired
behaviour — so it was rewritten to assert the capability: wire the palette to a Panel, ALSO wire it to
a Rectangle (image_3: **both go blue on one click**), then cut the Panel's wire from the palette's own
menu (image_4: **the Rectangle goes magenta, the Panel stays blue**). Images 1-2 kept their exact
dataHashes, which is the tidiest possible proof that only the new steps changed. New verb:
`disconnectControllerWire_InputEvents_Macro`.
⇒ **a test whose stated intent is a LIMITATION is the acceptance test for the arc that removes it** —
the §P8 lesson again, and it is worth looking for such a test before writing a new one.

⚠ **What P4 did NOT do.** `FanoutWdgt` is unchanged. The capability it wraps is now universal, so it
is a visual affordance over one rather than the only way to have one — but rewriting it is not
required by anything here, and it lives in a part production does not ship. Left for whoever next
needs it.

### P5 — Non-widget state becomes nodes (zero engine change) — ✅ **LANDED 2026-08-17** (`Wallpaper` + `PreferencesAndSettings`; `ScrollPanelWdgt` stays with §P8)

`SecondsSource`/`FrameSource` prove the node protocol is duck-typed and does not require Widget-ness.
So:

- **`Wallpaper`** gains `dataflowValue: -> @patternName`; `setPattern` gains
  `world.dataflow.markStale @`. Every pattern menu declares an edge `wallpaper → menu` whose action
  is the (renamed, connector-lane) `updatePatternsMenuEntriesTicks`. Then: N open menus agree, the
  API path agrees, and a snapshot load agrees. `Wallpaper`'s apologetic comment becomes deletable —
  which is the cleanest possible acceptance test for this proposal.
- **`PreferencesAndSettings`** the same, for at least `inputMode` (the world menu's label flips
  between "touch screen settings" and "standard settings" purely from a read of it).
- **`ScrollPanelWdgt`** gains real scroll pins (§P8).

Lifecycle is already safe: `Widget._destroyNoSettle` calls `world.dataflow.removeAllEdgesOf @`, so a
closed menu drops its edges. ⚠ But the world-teardown completeness ratchet
(`WorldWdgt._auditWorldResetCompletenessNoSettle`) and `world.teardownHygiene.*` both watch
world-level mutable state — a `Wallpaper` that is now a live node needs its edges dropped on
`resetWorld` like everything else, or `RESETWORLD_INCOMPLETE` will (correctly) fire.

### P6 — Give the palette its picture — ✅ **LANDED 2026-08-17**

Two independent halves; the first is worth doing on its own merits and needs nothing else in this
document.

**(i) Draw the marker.** It cannot go in the back buffer (shared + immutable, §2.7). Two shapes fit
the house conventions:

- paint it in the appearance pass on top of the blitted buffer, in widget-local logical coordinates
  inside the one `Appearance._paintInLocalScope` preamble
  ([`../architecture/appearance-paint-convention.md`](../architecture/appearance-paint-convention.md));
  or
- a small layout-inert child, the way `ColorPickerWdgt` already uses a `feedback` `RectangleWdgt`.

Recommend the appearance route for the palette itself (a ring/crosshair at the pick point) *and*
keeping the picker's swatch, because they answer different questions ("where on the map" vs "what
colour").

**(ii) Place the marker when the colour arrives from outside.** Today the palette stores only
`@choice` (a `Color`), not *where* it was picked. Under a reverse edge the colour may arrive from
anywhere. Rule to adopt:

> **A palette that can be driven declares the inverse of its own `fillPaletteBuffer`.**

For `ColorPaletteWdgt` the map is exact and invertible (`hue → x`, `lightness → y`, saturation
pinned at 100%); for `GrayPaletteWdgt` likewise. Store `@choicePosition` for the picked case, and
**mark the marker "off-map"** (a distinct rendering) when an externally-set colour is not on the
palette's surface — which for the HSL field is any colour with saturation ≠ 100%, i.e. most of them.
That honesty is better than snapping the marker to a lie.

**(iii) Rider:** move the `@choice = Color.BLACK` initialisation out of
`_createRefreshOrGetBackBuffer` into the constructor (§2.7).

**(iv) Harmonisation:** `ColorPaletteWdgt` has the handle without the picture; `ColorPickerWdgt` has
the picture without the handle. Give `ColorPickerWdgt` the `ControllerMixin` too — a colour picker
that cannot be pointed at a target is an odd citizen in a system whose principle is "a colour is
changed with a picker aimed at the thing".

#### As landed

All four parts, plus one addition the sketch did not ask for and one rider that inverted.

**(i) The marker is an appearance, and the blit got a name.** New `PaletteAppearance` (core),
reached the ordinary way: `PaletteWdgt` declares `@appearance` and defines
`paintIntoAreaOrBlitFromBackBuffer` as the plain delegation, which is needed only to un-shadow
`BackBufferMixin`'s member (a class-body member out-ranks a mixin's, `src/meta/Mixin.coffee`). The
appearance then composes the two layers exactly as `AnalogClockAppearance` does for its cached face
plus live hands: the mixin's blit in device space, then the marker inside the one
`Appearance._paintInLocalScope`. To make that composition possible the mixin's blit body is now
`blitBackBufferInto`, with `paintIntoAreaOrBlitFromBackBuffer` delegating to it — a name for a thing
that already existed, so a widget whose picture is "cached raster PLUS something live" can reach the
first half.
  The marker is skipped on the shadow pass. It lands inside the buffer's own opaque footprint and is
clipped to it, so it adds no COVERAGE, and coverage is the whole of what a shadow is.
  ⚠ A layout-inert child (the other shape §P6 offered) is ruled out by more than taste: the gesture
is a DRAG ACROSS the palette, and a child under the pointer would take the events the pick needs.

**(ii) The position is DERIVED, not stored — the sketch's `@choicePosition` is not there.** Each
subclass declares `positionForColor`, the inverse of its own `fillPaletteBuffer`, and the appearance
asks it on every paint. Storing a picked position alongside `@choice` would state one fact in two
places, which is the shape P1 already caught disagreeing (2 of 5 sites); deriving also means a
colour arriving by ANY route — pick, wire, snapshot, duplicate, script — is placed by the one path.
The inverse is exact, not approximate: an `hsl(h,100%,l)` colour still reports saturation 1 after the
browser rounds it to integer channels, and one column spans far more hue than that rounding can
move, so a colour picked off the field inverts back to the very pixel it came from (verified in the
references — the ring lands on the clicked pixel at both densities).
  Off-map is a frame, never a snap (§8 q4, owner-answered): a colour band round the whole field,
laid between two black hairlines so it reads against the white corner as well as the black one. It
claims no position, which is the point.
  `Color.hueSaturationLightness` is new and public — the inverse needs HSL, and reaching into
`_r/_g/_b` from outside is what `channelDistanceTo` exists to avoid.

**⭐ The addition: the palette's picked colour became a read/WRITE pin** (`getChoice` / `setChoice`,
`principalPinLabel: "picked color"`, and the `dataflowValue` override deleted — Widget's base now
covers it). Not in the sketch, and required by it: (ii) is about a colour "arriving from outside",
and there was no way for one to arrive. Every colour a palette PRODUCES is on its own surface by
construction, so without a setter the off-map rendering is unreachable code and the inverse is
untestable. `setChoice` deliberately does not fire onward — a value delivered to me is not a pick,
and re-firing it would make the palette an echo.

**(iii) The rider INVERTED: the `@choice = Color.BLACK` initialisation is DELETED, not relocated.**
Moving it was the right call while the choice was invisible. Once it is DRAWN, the fabrication
shows: a palette nobody has picked from has no choice, and a seeded black makes the marker assert a
pick, at hue 0, that never happened. `undefined` was already the handled state (`bang` declines,
`reactToTargetConnection` deliberately fires nothing), and deleting the seed unfuses the two axes
more completely than relocating it would — no palette anywhere gets a phantom choice. ⇒ **Making a
value visible can turn a refactor into a correctness question, and answer it differently.**

**(iv) `ColorPickerWdgt` is a controller**, and the change reached further than the mixin. Its two
palettes now wire to the PICKER (`wireTo @, "setPickedColor"`) instead of straight to the feedback
swatch: the picker is what knows a pick happened, so it can keep the swatch showing it AND fire its
own wire onward — aimed at the swatch, a pick would update it and nothing would ever tell the picker.
That relay makes `setPickedColor` a real write for `getColor`'s property, so the picker's principal
pin stopped being read-only and its apology comment is gone. ⚠ Both `PinSpec` and
`Widget.principalPinLabel` cited it as the canonical READ-ONLY pin; they now cite
`StringFieldWdgt.value`, which is read-only for a structural reason (its string lives in a child
widget, so there is no one-call setter twin).

**⭐⭐ One live defect found, in the crash the first render produced rather than by reasoning:**
`Color.hueSaturationLightness` was first written with CoffeeScript's `%%`, which compiles to a
`modulo` HELPER FUNCTION — and the meta-system strips the emitted `var` block, where helpers land,
out of every member it compiles (`Class._removeHelperFunctions`). So the operator became a call to
something that does not exist. Nothing caught it: it parses, so the syntax gate passed it, and the
strip's own guard enumerates three helper names (`indexOf`/`hasProp`/`slice`) and does not know
about this one. It surfaced as `ReferenceError: modulo is not defined` in the error console, with the
palette banned from repainting — i.e. as a screenshot diff that a mass recapture would have baked
in. Now a **zero-baseline `helper-compiling-operator` stink**, proven to fail on a planted `%%`.
⇒ **Looking at the pixels before recapturing is what caught it; the "REVIEW: 260k px changed"
verdict alone read as "the marker landed".**

**Deliberate simplification:** one marker shape for both palettes (a ring with a radius that shrinks
on a palette too small to hold it), not a ring for the 2-D field and a bar for the 1-D strip. The
1-D case would read slightly better as a bar; it is one method to override if it ever matters.

New test: `SystemTest_macroPaletteMarksItsChoice` — six shots covering unmarked, picked, driven
on-map, driven off-map, and both on the gray strip. It is the only coverage the off-map branch has,
and it reaches it through the pin, the route a wire delivers on.

### P7 — Ticks become a reflection, not a redraw — ✅ **LANDED 2026-08-17 (for the non-widget half)**

A menu item declares the pin it reflects and the value that ticks it; one shared reconciliation runs
when that pin's edge delivers. This retires four hand-rolled routines, kills the `rows[1]…rows[7]`
index fragility, and makes ticks correct across instances, API changes and snapshot loads. It is the
view half of P5 and should land with it.

#### As landed

`MenuRowReflectionSpec {source, readerName, whenValue, labelWhenTrue, labelWhenFalse}` — carried as a
`reflection:` opt on `MenuItemSpec`, held by `MenuItemWdgt` (which is BORN showing the current value,
so the build-then-fix-up dance goes), reconciled by `MenuRowsPanelWdgt._reconcileReflectedRowsConnector`,
and subscribed by `_subscribeToReflectedSource` — **one edge per PANEL, deduped through the new
`DataflowEngine.hasEdge`** rather than a bookkeeping field the panel would have to declare, deep-copy
and serialize.

`readerName` is a METHOD NAME, so a source needs neither `pins()` nor Widget-ness — which is the
point: `Wallpaper` and `PreferencesAndSettings` are plain collaborators.

**Acceptance (the one the plan named).** `Wallpaper`'s apologetic comment is DELETED, and the probe
`Fizzygum-tests/.scratch/p5-wallpaper-reflection-probe.js` opens TWO wallpaper menus and changes the
pattern three ways — through menu A, through the plain API, through menu B. All four snapshots AGREE,
and the wallpaper carries exactly 2 out-edges (one per panel, not one per row). Under the old
fix-up only the first case worked, and only for the menu that was clicked; the API case had no
mechanism at all, which is what the comment was apologising for.

⭐ **`addEdge`, not `ensureWireEdge`.** The fan-out this needs (one source → N open menus) has always
been supported by the engine's index — `edgesFrom` maps a producer to a **Set** of records. Only
`ensureWireEdge`, which mirrors a controller's single `@target`, collapses it to one. So gap **G2 is a
property of the WIRE vocabulary, not of the engine**, and a non-wire client can fan out today.

**Lifecycle needed nothing, and the plan's `resetWorld` caveat is answered.** A closed menu is
destroyed, `Widget._destroyNoSettle` calls `removeAllEdgesOf`, and `removeEdgesInto` deletes the
producer's entry outright once its last consumer goes (`@edgesFrom.delete producer if outSet.size is
0`) — so a `Wallpaper` that is now a live node leaves no residue behind a teardown, and
`RESETWORLD_INCOMPLETE` stays quiet (the whole suite runs the ratchet).

⚠ **SCOPE CORRECTION — P7 landed in TWO steps, and the plan did not anticipate the split.** Only the
non-widget half was convertible with P5; the other three sites needed **P3** first:

| site | source | status |
|---|---|---|
| `Wallpaper.updatePatternsMenuEntriesTicks` | `Wallpaper` (plain collaborator) | ✅ **retired** with P5 |
| world menu's input-mode row | `PreferencesAndSettings` (plain collaborator) | ✅ **converted** with P5 (one row that reflects, instead of two rows chosen by an `if`) |
| `StringWdgt.updateFontsMenuEntriesTicks` | a **StringWdgt** | ✅ **retired** with P3 |
| `TextWdgt` "soft wrap" · `ControllerMixin` "fires per event" | a **Widget** | ✅ **converted** with P3 |

The reason for the split is exactly gap **G1/G3**: `Widget.dataflowValue` is `@exportedValue()`, so a
widget has **ONE** staleness signal. A `TextWdgt` announcing "my `softWrap` changed" via `markStale`
fires its dataflow WIRES, delivering its *text* to whatever it drives — measurably a spurious apply,
and a cascading FORCE-fire when the target pin is `bang`. A non-widget holder has no such conflict,
which is why P5's own title — *non-widget state becomes nodes* — was the exact boundary of what P7
could convert alone. **P3's answer is `markNonValueChange` + the edge's `firesOnAnyChange`** (see §P3
"As landed"), which is what unblocked the remaining three.

### P8 — Scroll joins the public wire vocabulary — ✅ **LANDED 2026-08-17**

`ScrollPanelWdgt` defines **no** setter table override at all today, so its scroll position is not
offered by any connect menu and `adjustContentsBasedOnHBar` / `adjustContentsBasedOnVBar` are
reachable only by direct assignment. Proposal:

- advertise user-meaningful numerical pins (`scroll x`, `scroll y`) with readers, renaming the
  actions to match the pin (`setScrollX`, or keep the existing names behind the `PinSpec.set`);
- bind the panel's own bars with the same public mechanism everyone else would use;
- **retire `_reLayoutScrollbars`'s `if @hBar.target == @ … updateSpecs` field plumbing** in favour of
  the reverse edge, so any number of bars — including duplicates and bars belonging to nobody —
  follow the content. That is complaint ① closed.

⭐ **§P8 IS THE EXPERIMENT that settles §8 q1 (geometry pins).** It is the first real tracking pair —
a bar that must stay welded to its content — so it is where "does a one-frame lag SHEAR visibly?" gets
measured rather than argued. Build the reverse channel against **(c)** (notify at the end of layout,
drain next frame), drive a fast wheel-scroll, and look at the bar. If it shears, **(d)** (same-frame
drain + a second bounded `recalculateLayouts`) is the answer; if it does not, (c) is, and it is the
cheaper one. Record the measurement either way — that question has been argued from priors twice.

⚠ **`updateSpecs` carries four numbers, not one** (`start`, `stop`, `value`, `size`): the bar's
*range* changes when the content resizes, not only its value. So the reverse channel is genuinely a
structured update. Two options:

- a small immutable value class as the payload (house law:
  [`../architecture/immutable-value-classes.md`](../architecture/immutable-value-classes.md) —
  operations return new instances, `equals` for the cutoff); or
- four pins set cold, then one hot — **which is exactly the cold-edge idiom that
  [`wire-vocabulary-extensions-plan.md`](../plans/wire-vocabulary-extensions-plan.md) §4.W2 reserves and
  whose open question is "no customer exists yet".** ⭐ **Here is a customer, and it is product code,
  not a hypothetical sequencer.** Whichever option wins, this fact should be recorded in that plan.

#### As landed

**The reverse channel carries NO payload, so the four-number question dissolved rather than being
answered.** Both options above assume the numbers travel — as one value object, or as four cold pins
then a hot one. Neither is possible as posed: the engine PULLS one value per node
(`Widget.dataflowValue` → the principal pin), and a scroll frame has no one number, so a pushed
payload could not distinguish the horizontal bar's business from the vertical's without inventing
per-axis sub-nodes. What fits is the shape §P3 already built: **`firesOnAnyChange`, the edge that
says "wake me, I re-read you"** — the same one a reflected menu row uses. So:

```coffee
world.dataflow.markNonValueChange @          # ScrollPanelWdgt._reLayoutScrollbars: "my scroll geometry moved"
world.dataflow.addEdge @target, @, action: "reflectTarget", firesOnAnyChange: true   # the bar subscribes
```

and the bar re-reads **the pin its own `@action` writes** — `pinDrivenBy(@action)` → the pin's
`getterName` for the value, plus `sliderRangeForPin` (capability-probed) for the scale. That is what
lands `Widget.pinDrivenBy`, which `Widget.coffee` had reserved for "its first caller"; this is it.
⭐ **A duplicated bar therefore tracks what it drives with NO field naming the property twice** — it
keeps `@target`/`@action`/`@tracksTarget` and re-derives both edges, which is exactly why complaint ①
closes for a duplicate and not just for the panel's own two bars.

Only the VALUE needed a home, and it already had one; the three-number SCALE became `SliderRange`
(new, immutable, transient). ⇒ **§8 q5 is answered "neither": the payload question was a consequence
of assuming a push.** Recorded in `wire-vocabulary-extensions-plan.md` §4.W2 — W2 still has no
customer.

**⭐⭐ THE MEASUREMENT (§8 q1), and it inverts the objection.** §P3 feared that (c) makes a tracking
pair shear by a frame under fast motion, and guessed 3–5 px. Measured
(`Fizzygum-tests/.scratch/p8-scroll-shear-probe.js`, a wheel notch per frame over a 2700 px scale,
sampled after each cycle has painted):

| what moves the scroll | where the announcement is raised | measured lag |
|---|---|---|
| a **gesture** — wheel, thumb drag, track click | `_playQueuedEvents`, at the TOP of `doOneCycle` — **before** `recalculateDataflow` | **0 frames** (max, at every fling rate) |
| a **layout** re-fit — content resized, so the bar's RANGE changes | inside `recalculateLayouts` — **after** this cycle's dataflow station | **1 frame** |

⇒ **(c), and (d) is closed.** The objection assumed "announce at the end of layout" means the
announcement always misses the drain. It does not, because the cycle plays INPUT first: every
gesture-driven scroll is announced in time for the same cycle's drain. **The shear (d) would buy back
cannot occur on the only path that has motion to shear against**, and the residual one frame falls
exactly where nothing is moving. (d) would add a second `recalculateLayouts` to every cycle for that.

⚠ **Two bugs found on the way, both worth keeping:**

1. **A TRACKING bind must not push on connect.** `wireTo` fires the controller's current value at its
   new target, which is right for a control that OWNS the value and wrong for one that MIRRORS it: a
   `SliderWdgt` is born at 50 of 1..100, so binding a scrollbar scrolled its panel to 50. And because
   the fire POOLS, it landed on the next drain — by which time a panel that had nothing to scroll at
   construction had gained content. It cascaded into `RECALC_NONCONVERGENCE` (100 000 re-lays) and
   `NON_FINITE_GEOMETRY`. ⇒ the reciprocal verb `trackTarget theTarget, action` takes the initial
   value FROM the target. **The direction of the on-connect push is part of what a bind MEANS**, and
   §P2 inherits that rule.
2. **`markNonValueChange` must NOT copy `markStale`'s echo rule.** It did, verbatim. `markStale`
   drops a re-mark of the node being applied into because the engine already owns that node's
   VALUE-downstream walk — but a non-value announcement wakes a DIFFERENT edge set (the re-readers),
   which the engine is not walking for a node it reached as a wire CONSUMER (such a node is not in
   `noted`). So the guard did not deduplicate the announcement, it **deleted** it: a panel told to
   scroll never told its OTHER bars. Removed; it now pools and drains on the next pass of the SAME
   drain, which is also what makes the drag path 0 frames rather than "1 frame, if some later
   relayout happens to run".

**Also:** `setScrollX`/`setScrollY` (the renamed `adjustContentsBasedOnHBar`/`VBar`) are now CLAMPED
through the same `scrollX`/`scrollY` every other scroll path uses. The predecessors moved the content
raw — the over-scroll defect `scrollTo`'s own comment already recorded — and clamping is also what
makes a stale value from a hidden bar a no-op instead of shoving the content off its viewport.

**Recaptures: the inspector member-list class.** Every `ControllerMixin` member is copied in as an
OWN member of each controller (`Widget.coffee` says so where it explains why
`_popUpTargetPropertyMenu` lives on `Widget` instead), so the four new ones shift every inspected
controller's list. Kept on the mixin regardless: they are about `@target`/`@action`, which is the
mixin's remit, and recapture churn does not decide placement.
**`SystemTest_macroInspectorScrollbarUnplugged` is the acceptance test** — it existed to record the
ASYMMETRY (drag the duplicate and the original follows; drag the original and the duplicate stays
put). Its final image now shows both knobs meeting. Its four prose fields and its macro comments were
rewritten to assert the symmetry instead.

### P10 — Buttons: **NO** to engine delivery, **YES** to the gesture and the index
*(a) REFUSED · (b) RE-HOMED to the graph-edges plan §4.2 · (c) + (d) ✅ **LANDED 2026-08-18***

Owner question, 2026-08-14: *"buttons don't connect to their destinations using the connection
system. Should they?"* The honest answer splits three ways, and the split is worth recording as a
law, because "unify the two `@target`/`@action` mechanisms" looks obviously right and is not.

**Current state (dispatch shape as of the 2026-08-18 dispatch-slot protocol arc).** `ButtonWdgt`
holds `@target` / `@action` / `@doubleClickAction` / `@argumentToAction1` / `@argumentToAction2` /
`@subjectOfAction`, and `trigger()` is one synchronous call inside the click handler:

```coffee
@target[@action].call @target, @, @subjectOfAction, @argumentToAction1, @argumentToAction2
```

It does **not** `@augmentWith ControllerMixin`, declares no edge, and declares no pins of its own. The
population is large: `MenuItemWdgt` extends `LabelButtonWdgt` extends `ButtonWdgt`, so **every one of
the 328 `addMenuItem` call sites in `src/` is a button edge** — roughly two orders of magnitude more
than the wire edges.

#### (a) Delivery: NO — a command is not a current value

Five independent reasons, any one of which is sufficient:

1. **Count matters and pooling destroys it.** `@stalePool` / `@forcedPool` are `Set`s, so two bangs
   in one cycle are one fire. Click a button twice, get one invocation. Count-preserving delivery is
   exactly the deferred `firesPerEvent` mini-pass
   ([`wire-vocabulary-extensions-plan.md`](../plans/wire-vocabulary-extensions-plan.md) W1) — **so routing
   buttons through the engine today would be a regression, not a unification.**
2. **A button has no value to pull.** The engine's model is "notifications carry no values; the drain
   PULLS the producer's `dataflowValue`" (spec §3). A button's payload is *four positional
   arguments*, none of which is its value. It would be a `bang` with baggage the edge record cannot
   carry.
3. **Button actions are commands, not pins.** `makeFolder`, `saveWorldSnapshotToFile`, `openFromFile`,
   `inspect`, `toggleDevMode`, `wallpapersMenu` — these open dialogs, do file I/O, spawn windows. The
   setter tables deliberately advertise *properties others may drive*, not the whole method surface.
   Feeding commands into the pin vocabulary would destroy the one thing that makes the target-chooser
   menus meaningful.
4. **The settle discipline forbids it at scale.** Engine sinks must route through `_<action>Connector`
   lanes or bare mutators, never public self-settling setters, because the drain holds one settle
   open per pass. Button actions are overwhelmingly public and self-settling. The case law is exact:
   in 6c, the **single** prompt slider whose action reached `edit()` required building a whole
   `_*NoSettle` lattice (`WorldWdgt.edit`/`_editNoSettle`, `StringWdgt._editNoSettle`,
   `PromptWdgt.takeSliderValue`). Doing that 328 times is not a plan — and it would be *wrong*: those
   actions **should** self-settle, because they run at event time in their own event, which is where
   they belong.
5. **It would move work later for no gain.** A click invokes synchronously in `_playQueuedEvents`;
   through the engine it would be deferred to the drain station later in the same cycle, breaking
   read-your-writes inside event handlers.

⇒ **Law to record:** *a wire carries a current value; a button carries a command invocation. Two
delivery mechanisms, deliberately.* This is the same message-vs-signal split
[`wire-vocabulary-extensions-plan.md`](../plans/wire-vocabulary-extensions-plan.md) §8 already makes for
audio, one level up.

#### (b) The index: YES — one edge vocabulary, two delivery mechanisms

The button's `@target` **is** an information-flow edge, and today nothing indexes it — so the system
cannot answer "what does this button touch?", cannot show the wiring, and cannot count it for
reachability. That is precisely what
[`graph-edges-and-lifecycle-plan.md`](../plans/graph-edges-and-lifecycle-plan.md) §4.2/§4.3 wants (a common
add/remove/enumerate accessor over containment ∪ target ∪ reference, and one GC walk over the
union), and §4.2's ruling — *"keep the dataflow index as the single home of the target edges, don't
fork it"* — already covers buttons whether or not anyone noticed.

Shape: a button declares `addEdge @, @target, {action, command: true}`, and a **command edge is
excluded from the downstream closure** — indexed, never traversed, never delivered. That is
mechanically the same exclusion `cold` needs (W2), reached from a different direction. Zero change
to invocation; the payoff is discoverability, GC reachability, and the ability to *draw* the wiring.

#### (c) The gesture: YES, and this is the real gap — RE-AIMED then ✅ **CLOSED 2026-08-18**

You can point a slider at any widget through `connect to ➜` and pick a pin. **You cannot point a
button at anything** — a button's `@target`/`@action` is set at construction, in code, always. There
is no direct-manipulation path from "here is a button" to "make it do X to Y".

That is a live failure against
[`../architecture/design-principles.md`](../architecture/design-principles.md)'s route 2 ("an app
assembled by direct manipulation, no code") and against citizenship point 5, which claims *"menu
entries are widgets, so handy commands can in principle be extracted into a custom control panel"* —
**in principle**, because no mechanism exists.

What is missing is the command-side twin of §P1's `PinSpec`: a **command table** — "which of my
methods may a button invoke?" — with the same chain-through-`super` shape as the setter tables, and
the same `_popUpTargetPropertyMenu` gesture. Note the vocabulary already half-exists: **`bang!`
appears in every setter table**, and a bang *is* the button semantic expressed inside the wire
system. So the coherent story is not "make buttons use wires" but:

> **A button is a bang source. Give it the same target-chooser gesture and the same index; keep its
> delivery synchronous.**

And if W1 ever lands, a button gains the *option* of engine delivery (count-preserving, ordered,
fan-out to several targets) for the subset of actions that are drain-safe — with `firesPerEvent`
being exactly the switch that makes it legal. That is the honest dependency: **W1 is the
prerequisite for buttons ever joining the engine, and until it lands the answer is no.**

**As re-aimed and landed 2026-08-18 — the gap is a LIFETIME, not a vocabulary, and the command table
above is NOT what got built.** Measured what such a table would curate FROM (402 methods on a plain
`Widget`, 517 on `WorldWdgt`, 6923 across 15 representative classes) and what already curates it (the
context menu: 234 commands on those same classes, labelled, per-class, chaining through `super`,
well-formed at 273/274). ⭐ **The decisive fact is that a context menu is not a TABLE of commands — it
is a PANEL OF BUTTONS ALREADY POINTED AT THINGS** (`MenuItemWdgt extends LabelButtonWdgt extends
ButtonWdgt`, 328 sites). Pointing a button at something is therefore not missing; it happens every
time a menu opens. What is missing is that the button is DESTROYED when the menu closes — precisely
what citizenship point 5's "in principle" is describing. ⇒ the arc became **drag a menu row out and
keep it**: no second declaration of the same fact at 328 sites (§P1's "a fact stated twice will
disagree"), no harvesting API, and no menu row spent (§P2's rent law). Two things were built — the
`rejectDrags` opt-out (buttons are deliberately slippery so menus can be swiped, so a **pinned** menu
is what gives up its rows, composing two existing gestures with no new mode) and the row-owned
reflection subscription (a reflecting row `addEdge`s for itself, so an extracted row keeps ticking
after its menu is destroyed).

#### (d) Toggles and switches: here the answer flips to YES — ✅ **LANDED 2026-08-18**

`ToggleButtonWdgt` / `SwitchButtonWdgt` are a different animal and belong in the value world:
`@buttonShown` **is state**, and a toggle **is a view of a boolean**. Today they advertise no pins,
have no reader, and — the tell — `ToggleButtonWdgt.select` changes state by *simulating an input
event*:

```coffee
select: (whichOne) ->
  if @buttonShown != whichOne
    @buttons[@buttonShown].mouseClickLeft()
```

There is no non-firing reflect path, so nothing can drive a toggle without faking a click. That is
§2.3's `_updateHandlePosition` gap again, in a class that never got the verb. A toggle should have a
value pin and be bindable exactly like a slider — which also raises the missing payload kind: the
three tables are colour/string/numerical, and **there is no boolean**. Decide whether a toggle
exports `0`/`1` as numerical (cheap, honest enough) or whether a fourth kind is warranted (probably
not — per facet 9, payloads are the cheap axis but a kind that only one widget uses is not worth its
menu).

**As landed 2026-08-18.** `SwitchButtonWdgt` declares `shown button` — the **INDEX** of the button it
shows — as its `principalPinLabel` (`numerical`, `setToggleState`/`getToggleState`, `announces: true`),
so a toggle is driven through the ordinary "set target" gesture with no machinery of its own, and
`exportedValue()` answers `0` where it answered `undefined`.
  ⭐ **The payload question DISSOLVED rather than got decided**, and the general class is where it
dissolves: a switch is n-way and its state is an index into `@buttons` — a boolean is only what the
n=2 case looks like from outside. Hence the pin sits on `SwitchButtonWdgt` rather than the two-button
subclass, an ordinary numerical wire drives it, the setter CLAMPS, and no fourth kind is invented for
one widget.
  ⚠⚠ **The sketch above was wrong on two of its three claims**, measured on a live instance before
anything changed: the "non-firing reflect path" it calls missing is `setToggleState`/`_setToggleState`,
which exist, work and provably fire nothing (5 call sites); the "no reader" is `isSelected`, which
`RadioButtonsHolderWdgt` uses. What was genuinely missing was the pin — and the FUNNEL that earns its
`announces`: `@buttonShown` had THREE write paths and now has one, because a pin announcing from only
some of its write paths leaves a follower silently stale exactly when it matters. ⇒ the
`ToggleButtonWdgt.select`/`.toggle` pair quoted above as the tell is DELETED (zero callers).
  ⚠ Deliberately NOT done: `sliderRangeForPin`, which would let a slider FOLLOW a toggle and scale to
it — that belongs to the parked FOLLOWER arc, where the cycle rule a two-way pin relationship needs
also lives.

### P9 — Naming: `@target` means four different things — ✅ **LANDED 2026-08-16**

Prerequisite hygiene for even discussing bindings. `@target` was: the dataflow target
(`ControllerMixin`), the dispatch target (`ButtonWdgt`), the inspected object (`InspectorWdgt`), and
the referent (`IconicDesktopSystemShortcutWdgt`).
[`graph-edges-and-lifecycle-plan.md`](../plans/graph-edges-and-lifecycle-plan.md) §4.1 already proposed
`referencedWidget` for the fourth; `inspectedObject` for the third. Per
`regularity-principles.md`, the rename *is* part of the fix.

**As landed.** The two overloaded meanings were renamed and the other two keep the name, because for
them it is correct:

| meaning | classes | outcome |
|---|---|---|
| referent | `IconicDesktopSystemShortcutWdgt` + Document/Folder/Script | → **`referencedWidget`** (21 sites + the 2 cross-file readers: `StorageSorter` keeping a referent reachable, `WorldWdgt`'s referrer lookup) |
| inspected object | `InspectorWdgt`, `ClassInspectorWdgt` | → **`inspectedObject`** (40 sites, no cross-file readers) |
| dataflow target | `ControllerMixin` and the wire path | unchanged — this IS the information-flow meaning the other two were borrowing |
| dispatch target | `ButtonWdgt`, `CodePromptWdgt`, `IconicDesktopSystemWindowedAppLauncherWdgt` | unchanged |

⭐ **The membership test is what settles which classes are referents, not the word "link".**
`BinOpenerWdgt` and `IconicDesktopSystemWindowedAppLauncherWdgt` are SIBLINGS of the shortcut base
(all three extend `IconicDesktopSystemLinkWdgt`) and neither joins
`world.widgetsReferencingOtherWidgets`, so neither was renamed: calling their field
`referencedWidget` would imply a tracked reference edge they do not have, blurring the distinction
this rename exists to sharpen.

⚠⚠ **The sweep must cover `Fizzygum-tests/scripts/`, and that is what this rename got wrong first.**
`src/`, `tests/` and `Automator-and-test-harness-src/` were all swept clean and the SUITE stayed green
— and the gauntlet's **`apps` and `parts`** legs still failed, because `smoke-apps-headless.js` and
`parts-lazy-icons-headless.js` read `folderShortcut.target.contents.contents` at three sites inside
`page.evaluate` bodies. Those rigs drive `index.html`, which the suite never touches, so no amount of
suite-green says anything about them.

⚠ **Residue — three `target`s that are neither dataflow, dispatch, nor a tracked reference**, left as
`target` and now DECLARED with a comment saying what each actually is: `BinOpenerWdgt` (the bin it
opens), `PointerWdgt` (the widget it points at), `ConsoleWdgt` (the object typed code is evaluated
against). Each wants its own name and none is obvious; that is a small separate decision, not a
reason to hold P9.

⭐ **Rider: this retired the widget-practices arc's last open floor.** Its W4c parked 9 classes / 11
undeclared fields on this rename (D2); with the meanings settled, all 11 are declared and
`census-widget-conformance.js`'s undeclared-field baseline drops **9/11 → 0**.

---

## 5. Why this is affordable — and where it is not

**Loop termination is already solved and already measured.** Every mechanism a two-way binding needs
exists and is exercised in production today:

- **visit-once per pass + the equal-value cutoff** walk a ring one lap and stop
  (`DataflowEngine._walkOrderedPass` / `_processNode`);
- **echo suppression** (`@_applyingNode`) drops precisely the marking a controller emits while the
  engine is writing into it — which is what a two-way binding does on *every* delivery. The
  expensive half of bidirectionality was built for the 6b port and is measured at 1 pass;
- **the setters themselves already dedupe**: `Widget.setColor` / `setBackgroundColor` return early
  on `@color?.equals aColor`; `StringWdgt._setTextNoSettle` guards on `@text != theNewText`. A
  binding cycle dies at the setter before the engine's cutoff is even consulted;
- **`DATAFLOW_NONCONVERGENCE`** is the loud net if any of that is wrong.

**Quantisation is a behaviour, not a bug — but it must be stated.** A bound controller reads back
what the target actually stored, and the target's store is often quantised: every widget is placed
and sized in **integer pixels** by law
([`../architecture/integer-pixel-placement-and-sizing.md`](../architecture/integer-pixel-placement-and-sizing.md)),
and `SliderWdgt.updateValue` rounds. So writing `10.4` and reading back `10` is normal. Rounding is
**idempotent** (`read(write(read(write(v)))) == read(write(v))`), so the drain converges in at most
one extra pass — and the visible effect is the controller **snapping to the granularity of what it
drives**, which is correct and is already what a scrollbar does. Adopt it as a rule: *a pin's
read-back must be a projection.* A pin whose write-then-read is not idempotent must not be bound.

**Where it is genuinely not affordable:** geometry pins under the one-way layout↔dataflow law (§P3),
and any temptation to answer reflection by **polling** in a per-cycle reconciler (§2.9). Reconcilers
are for ephemeral overlays whose declarations are rebuilt each frame; values belong to the drain,
which is dark-cheap when nothing is stale (empty-pool early return) and would not be if it were
replaced by a per-cycle sweep.

---

## 6. Recommended sequencing

Deliberately **not** dependency order: the two cheapest items close two of the three complaints and
carry zero engine risk, which makes them the right way to test the law before paying for P1/P4.

| step | item | engine change | closes |
|---|---|---|---|
| 1 | **P5 + P7** — wallpaper (and input mode) as nodes; ticks as reflection ✅ **LANDED 2026-08-17** | **none** | complaint ③ (the non-widget half; the three WIDGET-owned ticks turned out to need P3 first — see P7 "As landed") |
| 1b | **P3** — `markNonValueChange` + the edge's `firesOnAnyChange`; P7's remaining three sites ✅ **LANDED 2026-08-17** | the two announcements, additive | complaint ③ (the widget half); unblocks every reverse edge |
| 2 | **P6** — the palette's marker (+ the two riders, + picker gets `ControllerMixin`) ✅ **LANDED 2026-08-17** | **none** | complaint ②'s view half |
| 3 | **P9** — the `@target` renames ✅ **LANDED 2026-08-16** | none | reading hazard |
| 4 | **P1** — `PinSpec` with readers ✅ **LANDED 2026-08-16** | none (the pull lands with P2) | unblocks 5–6 |
| 5 | **P4** — a controller owns a list of wires ✅ **LANDED 2026-08-17** | index mirroring; **serialization surface** | G2; frees `FanoutWdgt` |
| 6 | **P2** — the `bind ⇄` gesture ✅ **LANDED 2026-08-17** | none (two ordinary wires) | the headline |
| 7 | **P8** — scroll pins + reverse edge, retire the field plumbing ✅ **LANDED 2026-08-17** | none, given 1/4/5 | complaint ① |
| 8 | **P10(d)** — switch gains a value pin (the INDEX of the button it shows) ✅ **LANDED 2026-08-18** (`6a58bb4c`: `SwitchButtonWdgt`'s readable `shown button` pin, one write funnel, Q9 dissolved) | none, given 4 | the `mouseClickLeft()`-to-set-state smell |
| — | **P10(c)** — RE-AIMED then ✅ **CLOSED 2026-08-18** (`acffb8b2` + `9f4ba5d4`): not a command table — drag a menu row out and keep it | none | citizenship point 5's "in principle" |
| — | **P10(b)** — index button edges as command edges | index only, no delivery | ⇢ **RE-HOMED, not this arc's step**: rides [`../plans/graph-edges-and-lifecycle-plan.md`](../plans/graph-edges-and-lifecycle-plan.md) §4.2 |

Steps 1 and 2 were each a self-contained session; step 5 was its own arc and needed the serialization
round-trip legs; step 7 needed the `updateSpecs` payload decision (§P8), which answered NO payload at
all — and is also the answer the wire-vocabulary plan's W2 is still waiting for a customer for.

---

## 7. Rejected / do-not-attempt

- **A parallel observer/listener mechanism.** `graph-edges-and-lifecycle-plan.md` G2 already ruled:
  one graph index, not two. Reflection rides the dataflow index or it does not exist.
- **Polling for values** (a per-cycle "sync all bound controllers" reconciler). Kills the drain's
  dark-cheap empty-pool early return and re-imports the one-cadence-lag class the drain placement was
  chosen to avoid.
- **Making every wire bidirectional by default.** A slider driving a text's font size must not make
  the text drive the slider. Binding is opt-in, per wire pair, per gesture.
- **A `reflects` flag on the edge record** in preference to a second wire (§P2) — it would add a
  second way to express a ring that the engine already handles, and would need its own
  serialization, menu and failure modes for nothing.
- **Deep-comparing values to detect change.** `_valuesEqual` is `a.equals?(b)` else identity, by
  design; immutable value classes make that correct
  ([`../architecture/immutable-value-classes.md`](../architecture/immutable-value-classes.md)).
- **Routing `ButtonWdgt.trigger` through the dataflow drain** (§P10a). Pooling destroys click counts,
  a button has no value to pull, its actions are commands rather than pins, and 328 menu actions
  would each need the `_*NoSettle` lattice the single 6c prompt slider needed. One edge *vocabulary*,
  two delivery *mechanisms*. Revisit only if W1 (per-event delivery) lands — and even then, opt-in
  per button, for drain-safe actions only.

---

## 8. Open questions for the owner

1. ~~**Geometry pins**~~ — **ANSWERED 2026-08-17 by MEASUREMENT: (c)**, landed for the scroll pins in
   §P8, with (d) closed. A tracking pair does NOT shear, because `doOneCycle` plays INPUT before the
   dataflow station: a gesture-driven change is announced in time for the same cycle's drain (0
   frames measured), and the one-frame lag falls only on a change originating inside
   `recalculateLayouts`, where nothing is moving. See §P8 "As landed" for the table and the probe.
   ⚠ This licenses a READABLE, bindable geometry-ish pin where a consumer needs one — it does not
   retroactively make `width`/`height` readable: those are still write-only, now as a positive choice
   (nothing needs to bind them) rather than as a holding position.
2. ~~**`PinSpec` record vs. keeping parallel arrays** with a third `[readers]` column.~~ **ANSWERED
   2026-08-16 — the record**, and the third column would not have been enough anyway: a reader is
   only one of the two things arrays cannot state (the other is a pin accepting more than one kind,
   which is where 19 overrides collapsed to 9). See P1 "As landed".
3. ~~**Bind-time precedence** — "the side whose menu you opened pushes" (§P2), or an explicit
   source/mirror choice in the gesture?~~ **ANSWERED 2026-08-17: the side whose menu you opened
   pushes**, spelled `wireTo` + `declareWireTo` — P4's third verb is what makes the rule exact instead
   of leaving the later wire to win by accident. The explicit choice was rejected because every other
   connect gesture already takes the opened menu as its subject, and because the answer stops being
   observable one frame later, when the two are equal. See §P2 "As landed".
4. ~~**Palette off-map colours** — distinct "off-map" marker, nearest-point snap, or no marker at
   all when the colour is not on the surface?~~ **ANSWERED — a distinct rendering, and NEVER a
   snap**, because a snapped ring displays a position the value does not have. As landed it is a
   colour band round the whole field, claiming no position. See P6 "As landed" (ii).
5. ~~**Scroll's four-number reverse channel**~~ — **ANSWERED 2026-08-17: NEITHER.** The reverse edge
   carries no payload at all — it wakes the bar and the bar RE-READS (`firesOnAnyChange`), because a
   node has one value and a scroll frame has no one number. So three of the four travel as a
   `SliderRange` the consumer PULLS, and the fourth is the pin's own reader. **W2 still has no
   customer.** See §P8 "As landed".
6. ~~**Does `@wires` (P4) get a serialization version bump**, or does the `@target`/`@action`
   accessor shim make old snapshots load unchanged?~~ **ANSWERED 2026-08-17: NEITHER, and the question
   dissolved with its premise.** The accessor shim is not buildable in this codebase (`Class`/`Mixin`
   emit `prototype.<name> = <expr>`; there is no instance accessor anywhere in `src/`), so there was
   never a shim to load old snapshots THROUGH. And no bump: `Serializer.FORMAT_VERSION` gates only
   "newer than this build understands", there is no per-version migration machinery to hang one on,
   and the owner confirmed (2026-08-17) there are **no serialised worlds of interest** — so paying
   for compatibility nobody needs would have bought a migration path to nowhere. An old snapshot's own
   `target`/`action` properties simply restore as inert own-props on a widget that no longer reads
   them. See §P4 "As landed".
7. ~~**Scope of P5** — wallpaper only, or wallpaper + `PreferencesAndSettings` in the same session?~~
   **ANSWERED BY EVENTS 2026-08-17: both, in one session** — §P5 landed `Wallpaper` and
   `PreferencesAndSettings` together (`ScrollPanelWdgt`, the third candidate, went with §P8 instead,
   where its reverse edge belonged). See the §P5 heading.
8. **Command edges (§P10b)** — index button `@target`s in `world.dataflow` as non-traversed command
   edges, or leave the button edge unindexed until the unified collector arc actually needs it?
   **RE-HOMED 2026-08-18, not answered here:** it is no longer this arc's question — it travels with
   §P10(b) to
   [`../plans/graph-edges-and-lifecycle-plan.md`](../plans/graph-edges-and-lifecycle-plan.md) §4.2,
   whose own scope decision (its G1) is itself still owner-pending, and it is answered there or
   nowhere.
9. ~~**Boolean payloads (§P10d)** — a bound toggle exports `0`/`1` as numerical, or does a fourth
   payload kind earn its menu?~~ **RESOLVED — DISSOLVED 2026-08-18 (`6a58bb4c`) rather than
   decided:** a switch is n-way and
   its state is an INDEX into `@buttons`, so a boolean is only the n=2 case seen from outside. The pin
   is an ordinary numerical one on `SwitchButtonWdgt` whose setter clamps; no fourth kind. See
   §P10(d) "As landed".

---

## 9. Cross-links

- Law and lineage: [`../architecture/widget-citizenship.md`](../architecture/widget-citizenship.md)
  (MVC united; citizenship points 1, 4, 5),
  [`../architecture/design-principles.md`](../architecture/design-principles.md)
  ("Connections over wiring code", "Duplication as a first-class power"),
  [`../architecture/regularity-principles.md`](../architecture/regularity-principles.md)
  (separate the fused axes; the name encodes the role).
- Engine contract: [`../specs/dataflow-engine-spec.md`](../specs/dataflow-engine-spec.md) §2 (edges
  live locally), §3 (two verbs, notifications carry no values), §5 (re-entrancy, one-way coupling),
  §7 (cycles), §8 (the wire client); `src/dataflow/DataflowEngine.coffee` class header;
  [`../../src/dataflow/CLAUDE.md`](../../src/dataflow/CLAUDE.md) (6a–6d landing record).
- Sibling arcs: [`wire-vocabulary-extensions-plan.md`](../plans/wire-vocabulary-extensions-plan.md) (payload
  and edge *semantics*; W2 wants the customer §P8 supplies),
  [`graph-edges-and-lifecycle-plan.md`](../plans/graph-edges-and-lifecycle-plan.md) (the three-edge
  vocabulary; `@target` disambiguation), [`reference-widgets-plan.md`](../plans/reference-widgets-plan.md).
- Constraints: [`../architecture/layering-naming-convention.md`](../architecture/layering-naming-convention.md)
  (rule **[P]**: only `_<name>Connector` may join an enclosing pass),
  [`../architecture/integer-pixel-placement-and-sizing.md`](../architecture/integer-pixel-placement-and-sizing.md)
  (the quantisation §5 depends on),
  [`../architecture/serialization-duplication-reference.md`](../architecture/serialization-duplication-reference.md)
  (P4's surface), `../../../Fizzygum-tests/DETERMINISM.md`.
- Measured convergence: [`../measurements/dataflow-measurements.md`](../measurements/dataflow-measurements.md).

## Case law (moved from widget-authoring-guidelines.md §11)

The incident narratives, refusal stories and who-holds-what censuses that §11 of
[`../architecture/widget-authoring-guidelines.md`](../architecture/widget-authoring-guidelines.md)
had accumulated, relocated VERBATIM on 2026-08-18 so that section can be the prescriptive rulebook it
claims to be; each rule they back stays there, and cites these entries by their `CL` number.

### CL1 — Write-only pins, and why `width`/`height` are deliberately not readable

- **`get` is optional and its absence is a statement**: a pin with no reader is WRITE-ONLY — it can
  be driven and can never be bound two-way. Do not invent a reader method to fill the slot; most of
  `Widget`'s own pins are write-only because no reader method exists for them, and *that is the
  honest declaration*. `width`/`height` are write-only **deliberately** even though `width()` and
  `height()` exist: a readable pin is a licence to bind, and nothing has ever wanted to track a
  widget's width. That is a positive choice, not a prohibition: connector §P8 narrowed the one-way
  law to "layout may never `markStale`, but it MAY `markNonValueChange`", which is the licence
  `ScrollPanelWdgt`'s readable `scroll x` / `scroll y` run on. The bar for a readable geometry pin is
  a real CONSUMER — add the reader when something needs to track it.

### CL2 — `announces`: how many pins carry it, and why counting by hand is the wrong instinct

  ⚠ **Read the section below before ticking it.** The word looks obvious for any pin whose setter
  fires, and it is a promise about every OTHER path too — which is why only a handful of pins in the
  tree carry it. `Fizzygum-tests/scripts/pin-sweep-headless.js` enumerates them and drives each one's
  setter as a necessary-condition check; ask it rather than counting by hand.

### CL3 — An appearance's pins are the WIDGET's to service — the `corner radius` incident

- ⚠ **An APPEARANCE's pins are serviced by the WIDGET, not by the appearance.** `Widget.pins`
  concatenates `@appearance?.pins?()`, and a pin's setter is dispatched on the widget — so declaring
  a pin on a shape is a demand on *everything that wears it*, including subclasses of the wearers.
  `corner radius` was declared by three appearances and implemented on one class, which left sixteen
  advertising a control that could not work; the field and its setter now live on `Widget`, beside
  `appearance`, because the shape reads `@widget.cornerRadius` unconditionally and so the property
  was always part of that contract. If you give a shape a pin, put its verb where every wearer can
  answer it.

### CL4 — A tracking bind does not push on connect — the scrollbar born at 50

- ⚠ **A tracking bind does not push on connect.** `wireTo` fires your current value at the new
  target, which is right when you OWN the value and wrong when you MIRROR it — the target is the
  source of truth, so the initial value must flow target → you. This is not a nicety: a `SliderWdgt`
  is born at 50 of 1..100, so a scrollbar that pushed on connect scrolled its panel to 50, and
  because the fire POOLS it landed a cycle later, on a panel that may have gained content in the
  meantime. `trackTarget` takes the value from the target for exactly this reason.

### CL5 — "follows it too" is a PROMOTION of an existing wire, not a second chooser

**A user reaches this from the wire's own menu row — "follows it too" — which promotes a wire they
already made.** There is no separate "bind a pin" chooser and there should not be: "connect to ➜"
already offers every drivable pin, so the wire exists; what the gesture adds is the reverse half. It
is offered only where all three preconditions hold, each asked of whoever owns the answer — the pin
is readable and `announces` (the `PinSpec`), the follower can render *that* pin
(`SliderWdgt._canReflectPin` wants a `SliderRange`), and the follower is not already following
something else (one thumb, one value).

### CL6 — `announces` is a claim about a FUNNEL — `ScrollPanelWdgt` as the model

⚠ **`announces` is a claim about a FUNNEL, not a property of your setter — audit every write path
before declaring it.** `ScrollPanelWdgt` can claim it because it is built so that it can: wheel,
thumb drag, track click, caret-into-view, a drop that re-fits it, `scrollTo`, both setters — every
path that moves its content ends at `_reLayoutScrollbars`, and the announcement is raised there. If
your pin has no funnel, build one or leave the flag alone.

### CL7 — Announcing and firing onward are DIFFERENT refusals

⚠ **Announcing and firing onward are DIFFERENT refusals, and conflating them silences pins that
should speak.** `markNonValueChange` wakes only the re-readers and hands them nothing, so it is never
the echo a sink is right to avoid. Two places got this wrong and are worth knowing as case law:

- `ControllerMixin._fireConnection` used to make the announcement a side effect of the DELIVERY, so
  its "do I have wires?" guard silenced both. A follower is precisely a widget that subscribes
  without being driven, so an unwired controller changed its value to an audience of nobody. It now
  separates the two: an unwired controller `markNonValueChange`s and returns, and a wired one
  `markStale`s — which wakes the same re-readers on its way to the wires. Two jobs, and the wire
  guard sits only on the one that needs it.
- `PaletteWdgt.setChoice` refuses to fire a value delivered TO it (that would make it an echo) and
  used to refuse to announce as well — one refusal too many, since its choice really did change.

### CL8 — A REFLECTION path is the one place silence is still right

⚠ **A REFLECTION path is the one place silence is still right, and it needs more than a flag.** A
slider's `_updateHandlePosition` / `_updateSpecs` show a value they do not own. Announcing there
without an equal-value cutoff re-fires on every drain pass — a self-sustaining loop with no cycle in
it — which is why `SliderWdgt`'s `value` is the one readable pin in the tree that cannot yet declare
`announces`. If you write a reflector, give it the cutoff first.

### CL9 — Why both connection gestures share one menu row

The parenthetical §11 carried on `bindTo`, arguing the menu-rent question that §P2's own "a feature
costing every menu a ROW charges rent nothing measures" opened:

(one level down, behind the shared block's single `connect ➜` row: both connection gestures are
grouped there so that having two costs a controller's menu no extra height — a menu row is cheap now
that an over-tall pop-up scrolls rather than spilling off the world, but a shorter menu is still the
better menu)

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

The closed items this plan owned, relocated VERBATIM from `docs/BACKLOG.md` on 2026-08-18 so
that file can go back to being an index of OPEN work only (`docs/README.md` filing rule 2: an
arc's items leave BACKLOG when it closes). Nothing above this line changed; any item of this
arc still OPEN stayed in `docs/BACKLOG.md`.

- [x] P5+P7: ✅ **DONE 2026-08-17.** `Wallpaper` and `PreferencesAndSettings` are dataflow nodes (zero engine change, as `SecondsSource`/`FrameSource` predicted), and a menu row can DECLARE that it shows somebody's value — `MenuRowReflectionSpec {source, readerName, whenValue, labelWhenTrue, labelWhenFalse}` as a `reflection:` opt, reconciled by the ROW itself (`MenuItemWdgt._applyRowReflectionConnector`), subscribed ONE EDGE PER REFLECTING ROW. (⇒ landed as one edge per PANEL, deduped via the new `DataflowEngine.hasEdge`; moved onto the row 2026-08-18 — see the entry below.) Acceptance met: `Wallpaper`'s apologetic comment is DELETED and the probe (`Fizzygum-tests/.scratch/p5-wallpaper-reflection-probe.js`) shows two open wallpaper menus agreeing when the pattern is changed via menu A, via the plain API, and via menu B. The `rows[1..7]` index fragility is gone. ⭐ **`addEdge` fans out where `ensureWireEdge` does not** — `edgesFrom` has always mapped a producer to a SET, so gap G2 is a property of the WIRE vocabulary, not of the engine. ⚠⚠ **SCOPE CORRECTION: this retires ONE of the four hand-rolled tick routines, not four.** The other three (`StringWdgt` fonts, `TextWdgt` soft wrap, `ControllerMixin` fires-per-event) have a **WIDGET** as their source, and `Widget.dataflowValue` is `@exportedValue()` — one staleness signal — so announcing "my softWrap changed" would fire the widget's dataflow WIRES. ⇒ **P3 is now a hard prerequisite for the rest of P7.** 0 recaptures.
- [x] **`PreferencesAndSettings` was missing `keptByReferenceOnDeepCopy` — ✅ VERIFIED BROKEN, then FIXED 2026-08-17.** Probe (`Fizzygum-tests/.scratch/prefs-bag-duplication-probe.js`): duplicating the world menu CLONED the prefs bag, so the copy's "touch screen settings" row toggled a **dead clone** instead of the real settings — exactly the failure the same flag on `Wallpaper` exists to prevent. Pre-existing (the row has TARGETED the bag for a long time); P5+P7 surfaced it by also making the row READ the bag. Fixed by adding `keptByReferenceOnDeepCopy: true` + `wellKnownKey: "preferences"`; re-run of the same probe shows the copy driving the REAL bag (`0 -> 1`). ⭐ Serialization needed nothing — `WellKnownObjects` already matched the bag BY IDENTITY with both a `keyFor` and a `resolve` arm, so only the DUPLICATION path was broken. ⚠ The lesson generalises: a well-known singleton needs BOTH mechanisms, and having one is no evidence of the other.
- [x] P3: one announcement verb — ✅ **DONE 2026-08-17, and it landed as a SPLIT, not a verb.** The plan's sketch ignores its own `pinName`, which is exactly where it is wrong: a node has ONE value (`Widget.dataflowValue` → `exportedValue()`), so `markStale` can only mean "my value changed". ⭐ **MEASURED before designing** (`Fizzygum-tests/.scratch/p3-announcement-falsefire-probe.js`): a naive `markStale @` costs a wired widget one spurious apply per wire — **inert** for an ordinary value pin (the target's equal-value cutoff stops it, 0 onward marks) and **cascading** for a `bang` pin (a bang is a FORCE-fire, exempt from the cutoff by design, 1 onward mark). So the plan's framing overstated the general harm and understated the specific one. What landed: `DataflowEngine.markNonValueChange node` beside `markStale`, plus the matching half on the edge — **`firesOnAnyChange: true`** = "my consumer RE-READS the producer rather than receiving its value". A reflected menu row is exactly that shape (it ignores the delivered value), so `MenuRowsPanelWdgt` declares it and wires do not. **Additive by construction** — every existing edge and `markStale` keeps its meaning and the new announcement fires strictly FEWER edges, so before anything declares the flag the change is a no-op; it is also DARK unless a re-reading subscriber exists. ⭐⭐ **The trap it exposed had nothing to do with announcing:** `_removeOutgoingEdgesOf` cleared EVERY out-edge of a re-wired producer on the comment's premise "a ControllerMixin producer owns at most one out-edge" — true until P5/P7 made a widget subscribable, after which re-wiring a text whose fonts menu is open would silently unsubscribe that menu, resurrecting the very bug this arc kills. Now `_removeOutgoingWireEdgesOf` (spares `firesOnAnyChange`), with `_wireEdgeRecord` split from `_edgeRecord`. **P7's remaining three sites converted** (`StringWdgt` fonts → `currentFontName`, retiring `updateFontsMenuEntriesTicks` + `@FONT_STACK_MENU_ENTRIES` + the `rows[i+1]` indexing; `TextWdgt` soft wrap → `isSoftWrapping`; `ControllerMixin` fires-per-event → `isFiringPerEvent`). Four claims verified in `.scratch/p3-nonvalue-announcement-probe.js`, and a new SystemTest `macroFontsMenuFollowsAnApiChange` asserts both halves in one fixture. ⭐⭐ **A SECOND regression from the same change, also nothing to do with announcing:** `SimpleTextWdgt` removes the inherited "soft wrap" row **by its decorated label**, trying three spellings — turning the row into a reflection made the unticked spelling `untick + "soft wrap"`, matching none of them, so the row would have silently reappeared. Fixed at the root: `removeMenuItem` compares UNDECORATED on both sides (new `String::withoutTickDecoration`) and the three lines collapse to one. ⇒ **making a label DYNAMIC breaks everything that matched it as a CONSTANT.** Two SystemTests were failing on it and pass again untouched. ⚠ NOT pixel-free: `tickWhen` pads an unticked label with `untick`, and the two toggle rows previously showed a bare label when off — they were the only ticked-family rows not reserving the tick column, and now align. **Recaptures: 11**, all the inspector member-list class (discovery first said 13; the two that dropped out are the `removeMenuItem` repair).
- [x] P6: the palette gets its picture — ✅ **DONE 2026-08-17.** New `PaletteAppearance` composes the two layers the way `AnalogClockAppearance` does (the mixin's buffer blit in device space — now NAMED `blitBackBufferInto` so an appearance can reach it — then the marker inside the one `_paintInLocalScope`); the widget defines `paintIntoAreaOrBlitFromBackBuffer` as the plain delegation purely to un-shadow the mixin's member. Both subclasses declare `positionForColor`, the inverse of their own `fillPaletteBuffer`, and off-map renders as a colour band round the field — **never a snap** (§8 q4 answered: a snapped ring displays a position the value does not have). ⭐ **The sketch's `@choicePosition` is NOT there:** the position is DERIVED from `@choice` on every paint, so one fact is stated once (P1's "a fact stated twice will disagree") and a colour arriving by ANY route is placed by the one path; the inverse is exact, since an `hsl(h,100%,l)` colour still reports saturation 1 after integer-channel rounding. ⭐ **Addition the sketch required but did not ask for:** the picked colour became a read/WRITE pin (`getChoice`/`setChoice`, `principalPinLabel`, the `dataflowValue` override deleted) — every colour a palette PRODUCES is on its own surface by construction, so without a setter the off-map branch is unreachable code and (ii) is untestable. ⭐⭐ **Rider (iii) INVERTED: the `Color.BLACK` seed is DELETED, not relocated** — moving it was right while the choice was invisible; once DRAWN, a seeded black makes the marker assert a pick at hue 0 that never happened. ⇒ *making a value visible can turn a refactor into a correctness question and answer it differently.* (iv) `ColorPickerWdgt` has the `ControllerMixin`, and its palettes now wire to the PICKER (`setPickedColor`) rather than the swatch — the picker is what knows a pick happened, so it can relay AND fire onward; that relay made its principal pin genuinely read/write, so `PinSpec` and `Widget.principalPinLabel` now cite `StringFieldWdgt.value` as the canonical READ-ONLY pin instead. ⭐⭐ **One live defect, caught by looking at the pixels rather than by reasoning:** `Color.hueSaturationLightness` written with CoffeeScript's `%%` compiled to a `modulo` HELPER the meta-system strips out of every member — it parses, so the syntax gate passed it, and it surfaced only as a palette banned from repainting. Now the zero-baseline `helper-compiling-operator` stink, plant-proven. New test `macroPaletteMarksItsChoice` (6 shots, the only off-map coverage anywhere)
- [x] P9: `@target` disambiguation — ✅ **DONE 2026-08-16.** `InspectorWdgt`/`ClassInspectorWdgt` → `inspectedObject` (40 sites); the shortcut family (base + Document/Folder/Script) → `referencedWidget` (21 sites + 2 cross-file readers: `StorageSorter`'s reachability walk, `WorldWdgt`'s referrer lookup). The dataflow and dispatch meanings KEEP the name — for them it is correct. ⭐ **Membership of `world.widgetsReferencingOtherWidgets`, not the word "link", is what decides a referent**: `BinOpenerWdgt` and `IconicDesktopSystemWindowedAppLauncherWdgt` are siblings of the shortcut base and join no tracker, so renaming them would have implied an edge they do not have. ⚠ Residue: three `target`s that are neither dataflow, dispatch nor tracked reference (`BinOpenerWdgt` = the bin it opens, `PointerWdgt` = the widget it points at, `ConsoleWdgt` = the object code evaluates against) are left as `target`, now DECLARED with a comment saying what each is; each wants its own name, which is a small separate decision. ⭐ Rider: this retired the widget arc's last floor — undeclared-field baseline 9/11 → **0**. Recaptures: 0.
- [x] P1: pins become readable — ✅ **DONE 2026-08-16.** `PinSpec` + `Widget.pins`/`pinsOfKind`/`pinLabelled`/`principalPin` replace the four parallel-array tables and their three helpers; **19 setter overrides on 9 classes → 9 `pins` declarations**, because a pin now states its own kinds (`"any"`, or an array) instead of being repeated once per kind-table. `exportedValue` reads a DECLARED principal pin (`principalPinLabel`) instead of `getColor?() ? getValue?() ? @text`. `producesPinKind` replaces the same fact being stated twice per controller in two unrelated places, which collapsed the 5 `openTargetPropertySelector` stubs into one shared method. **Three defects it exposed:** `StringWdgt` advertised a `bang` pin it does not implement (`bang` is on `SimpleTextWdgt`; the miss dispatched silently); `Example3DPlotWdgt.numericalSetters` really did drop its `super`, narrowing a plot to ONE pin; and `deduplicateSettersAndSortByMenuEntryString` deduped its two arrays independently, so a label repeated against a different setter would have silently mis-paired every later row. ⚠ Deviations from the sketch (all in the plan's "As landed" table): fields are `setterName`/`getterName`, `set`/`get` ride an `opts` bag, `kind` may be an array or `"any"`, `set: undefined` declares a READ-ONLY pin too, the principal pin is named by LABEL, and **`DataflowEngine.pullPinValue` was NOT added** — it has no caller until P2/P7 and the dead-method gate correctly refuses an unverifiable method. `width`/`height` stay write-only pending the geometry-pin question below. Recaptures: see the arc note.
- [x] **FOUND WHILE LANDING P8 (menu sweep) and FIXED 2026-08-17 — `Widget.createPointerWdgt` assumed `add` is ADDITIVE.** ⚠ First recorded (wrongly) as a rig churn artefact and "not a wiring defect"; instrumenting the sweep's own walk overturned that. A `FrameWdgt` holds exactly ONE content widget and its `_addNoSettle` EVICTS the current occupant (`@removeChild @contents`), so for a receiver that IS a window's content, `@parent.add pointer` performed the removal half of the swap and the `@removeFromTree()` two lines later died on an undefined `@parent`. Right-click a window's content → "make pointer" → throw: real and user-reachable, not sweep-only. Fixed by capturing the obligation rather than the symptom — `return unless @parent?` up front, and `@removeFromTree() if @parent?` at the end, with the comment stating that adding is not universally additive. ⛔ Deliberately NOT soaking `removeFromTree`'s `@parent.removeChild`: that is the operation the method IS, and soaking it would turn a caller error into a silent global no-op to serve one caller. ⛔ Deliberately NOT introducing `@parent.replaceChild me, replacement` — the tidier container protocol, but a ONE-caller abstraction; **introduce it with the second caller**. The sweep's KNOWN entry is deleted, per that list's own rule
- [x] **`BackBufferMixin.isTransparentAt` could never answer true — ✅ FIXED 2026-08-18.** It tested `data.a is 0` on the `Color` that `getPixelColor` returns, and a `Color` keeps its alpha in `_a` with no public `a`, so the test read `undefined is 0`: false for every pixel. Now `@getPixelColor(aPoint).isFullyTransparent()` — the spelling P6 added for exactly this question. Proven to work: on a 50x40 `StringWdgt` the method now answers true for **1946 of 2000 px** and false for the 54 ink px; before it answered false for all 2000.
      ⚠⚠ **BOTH HALVES OF THIS ENTRY'S PREDICTED COST WERE WRONG, and measuring first is what showed it.** It said the repair "flips hit-testing across the whole text layer, which wants its own before/after and its own recapture pass". (a) The text layer CANNOT be affected: `StringWdgt` and `TextWdgt` both set `noticesTransparentClick = true`, and the pointer gate is `(m.noticesTransparentClick or not m.isTransparentAt …)` — the opt-out short-circuits the test entirely. ⭐ That pairing is not incidental: a string is ~97% transparent by this measure, which is exactly WHY it opts out, so anyone deleting that flag as redundant would make text clickable only on its ink. (b) There was no recapture: the suite is 300/300 green and hit-testing paints nothing.
      ⚠ **Behaviour-NEUTRAL today, and that is the honest status** — not a behaviour win. The only back-buffered widgets without the opt-out are `CanvasWdgt` and `PaletteWdgt`, and both paint OPAQUE backgrounds (a blank canvas pixel measures `_a: 255`), so nothing currently reaches a transparent pixel through this path. The fix restores the method's ability to answer its own question for the next consumer that needs it — e.g. a canvas with a transparent background.
- [x] P4: a controller owns a LIST of wires (`@wires`, one `WireSpec` each) — **LANDED 2026-08-17, G2 CLOSED.** `wireTo` ADDS (idempotent per target+action), `unwireFrom` removes, `declareWireTo` is the third binding verb (bind and move nothing — §P8's on-connect-direction lesson finishing itself), `ensureWireEdges` mirrors the list so per-wire removal needs no engine verb, and the menu shows one row per live wire ("a Panel . color ➜") carrying that wire's `fires per event` + `disconnect`. ⛔ NO `@target`/`@action` shim: `Class`/`Mixin` emit `prototype.<name> = <expr>`, so an accessor is not expressible here (zero instance accessors in `src/`) — one-pass conversion instead. Also fixed a LATENT engine defect it made reachable (`_applyIncomingWireEdges` delivered ONE record per producer→consumer pair) and deleted two vestiges (`PaletteWdgt`'s `@target` ctor hole — 11 test call sites passed `undefined` through it; `argumentToAction`, written once and read by nobody). See §P4 "As landed".
- [x] P2: the `bind ⇄` gesture — ✅ **DONE 2026-08-17.** Two ordinary wires made in one gesture, no new edge kind, nothing new in the engine or in serialization. ⭐ **The sketch's "a pin on each side" is not expressible:** a wire delivers its producer's PRINCIPAL value (`pullValue` → `dataflowValue`), so both pins are FORCED and the gesture has NO property step — shorter than `connect to ➜`, not longer. The frame that resolves it: the engine has exactly TWO production granularities, and a bind exists at each — the NODE (`markStale`, a wire, value handed over) is this, the PIN (`markNonValueChange`, `firesOnAnyChange`, consumer re-reads) is §P8's `trackTarget`. No third thing to build. ⭐⭐ Restricting to principal ⇄ principal is what makes the offer HONEST: nothing on a `PinSpec` declares "I announce", but at node granularity that precondition is EQUIVALENT to a checkable one — a controller with a read/write principal pin is exactly a widget that announces (verified on all four). ⇒ `DataflowEngine`'s reserved pin-aware `pullValue` sibling is **answered, not consumed** — the pin-aware pull belongs to the re-read edge, which already has it — so the reservation comment is deleted. **§8 Q3 answered: the side whose menu you opened pushes** (`wireTo` + `declareWireTo`; P4's third verb makes the rule exact instead of letting the later wire win by accident). ⭐ `⇄` is DERIVED, not stored, so a pair wired BY HAND in two `connect to ➜` gestures reads as bound, a 3-node ring correctly reads one-way, and a DUPLICATE of half a bound pair tells the truth with no bookkeeping. `disconnect` ends both directions — a consequence of P4 (`unwireFrom` already revokes a tracking wire's reverse edge), not a new rule. See §P2 "As landed".
- [x] **A pop-up TALLER THAN THE WORLD had no handling at all — ✅ FIXED 2026-08-17.** `PopUpWdgt.popUp` clamps a pop-up's POSITION (`_moveWithin`) and can do nothing about a FIT, so the overflow was drawn past the bottom edge and unreachable: no scroll, no column wrap, no indication. **⚠ The filing was wrong about the danger being latent.** §P2 grouped both connection gestures behind one `connect ➜` row and concluded "the trip-wire is not armed"; measuring it first would have shown it was **already firing in the shipped build** — against the 960×440 harness world a plain `TextWdgt`'s own context menu wants **498px and loses three whole rows** (`shrink to fit`, `soft wrap`, `run contents`), and a `StringWdgt`'s 462px loses one. The §P2 fixture that surfaced it (435px) merely had the *thinnest* margin, 5px. ⇒ **a defect filed as "reachable in principle" is worth MEASURING before it is filed as latent.** Independently filed by the layout-spec-family arc as its F1 find (above), which knew the half §P2's filing did not: the defect had already been absorbed into the macro vocabulary as sanctioned direct calls.
      **The fix:** a pop-up's rows ALWAYS live in a `ScrollPanelWdgt`, sized to `min(natural, world)` on both axes. ⭐ **Unconditional on purpose** (owner call): a conditional frame buys a few widgets per menu at the price of a THRESHOLD, and a threshold is a state transition to get wrong — a menu composed short and grown later (`addMenuItem` on an open menu) would have to restructure itself mid-life, during the very membership change that provoked it. With the frame always present there is nothing to cross. ⛔ The rows panel must NOT be the frame's `contents`: `ScrollPanelWdgt._positionAndResizeChildren` constrains a contained `SimpleVerticalStackPanelWdgt`'s width to the viewport while `MenuRowsPanelWdgt` hugs its width back to its widest row — they fight and `recalculateLayouts` raises `RECALC_NONCONVERGENCE`. The rows go INSIDE the frame's own default plain-`PanelWdgt` contents, which is exactly how `ListWdgt` is built and why. ⭐⭐ **Inserting a plain `PanelWdgt` into a menu's ancestry is not neutral:** `PanelWdgt.providesAmenitiesForEditing` is `true`, and the editor SELECTION walk (`WorldWdgt._widgetBeingEdited`, D21) climbs to the first ancestor with an OPINION — so every clicked menu row was framed as "a selected item inside an editor" until the two added widgets were made to answer `undefined` like the rows panel and the pop-up already do. Guarded by the always-on `POPUP_LARGER_THAN_WORLD` assert (`PopUpWdgt._assertFitsInTheWorld`, wired into both headless runners' fail-gate) plus `SystemTest_macroOverTallMenuScrollsToReachItsLastRow`, which scrolls to a formerly-lost row and CLICKS it.
- [x] **P2 residue — the pin-granularity bind GESTURE — ✅ DONE 2026-08-18.** `PinSpec` gains `announces`, and the gesture is `ControllerMixin.toggleTrackingOfWire`, offered as the row **"follows it too"** in a wire's own menu beside "fires per event" (`_canTrackWire` guards it; `SliderWdgt._canReflectPin` is the follower's half). Acceptance test `SystemTest_macroSliderPromotedToFollowAScrollPanel` (5 images, 13 assertions).
      ⭐⭐⭐ **IT IS NOT A SECOND CHOOSER — the wire the gesture needs ALREADY EXISTS.** `pinsOfKind` keeps `scroll x`/`scroll y`, so "connect to ➜" has always offered a slider → panel `scroll y` wire; the only thing missing was the reverse half. So the gesture is a PROMOTION of the wire you are looking at, it costs the enclosing menu ZERO rows, and `trackTarget` was already written for it — its own note reads *"say it again for a plain wire being promoted to a tracking one"*, a caller-less sentence since §P8.
      ⭐⭐⭐ **THE AUDIT'S DOMAIN WAS TWO PINS, NOT THE WHOLE PIN TABLE — and measuring that first is what stopped a whole-table sweep.** Of 39 `PinSpec`s, 31 are write-only (no reverse half is expressible — `PinSpec` refuses one) and of the 8 readable ones SIX are PRINCIPAL pins, already covered by §P2's node-granularity bind. **Every readable non-principal pin in the tree is `ScrollPanelWdgt`'s `scroll x`/`scroll y`** — one class, because "readable and not principal" means "more than one readable quantity", and only a scroll frame has that.
      ⭐⭐⭐ **`announces` IS A CLAIM ABOUT A FUNNEL — and the audit found a real DEFECT behind the four obvious candidates, since fixed.** `ControllerMixin._fireConnection` made the announcement a SIDE EFFECT of the delivery, so its `return unless @wires?.length` guard silenced both — and a follower is exactly a widget that subscribes without being driven, so an unwired controller changed its value in total silence. **One event, two jobs, and the guard belonged to only one of them.** It now announces first (`markNonValueChange`, dark without a subscriber; identical to `markStale` here, since with no wires the only reachable out-edges are the re-reading ones) and delivers second. Same over-broad refusal in `PaletteWdgt.setChoice`, which correctly refuses to FIRE a delivered value and wrongly refused to ANNOUNCE it. ⇒ `StringWdgt` `text`, `PaletteWdgt` and `ColorPickerWdgt` `picked color` now declare `announces: true` TRUTHFULLY.
      ⚠ **Do not read "no consumer yet" as licence to leave a wrong guard.** The bar "wait for a real consumer" governs ADDING a pin or a reader (`Widget.width`/`height`); it does not govern a verb whose guard is in the wrong place. The tell was that the first pass shipped FOUR COMMENTS EXPLAINING A HOLE instead of closing it.
      ⚠ **`ScrollPanelWdgt` still earns the word differently, and that is the model**: every scroll path — wheel, thumb, track click, caret-into-view, re-fit, `scrollTo`, both setters — ends at `_reLayoutScrollbars`. A funnel, not a remembered call.
      ⚠ One hole the gesture would have opened and `_canTrackWire` closes: `_trackingWire` takes the FIRST tracking wire, so promoting a second one would be silently ignored — the row disappears from every other wire while one is followed.
- [x] **A2 residue — `announces` is a declaration nothing verifies — ✅ DONE 2026-08-18, folded into the pin sweep as designed.** Section 3 of `pin-sweep-headless.js`: every pin declaring `announces` must have a FIXTURE that builds a live instance, drives the pin's own setter, and sees a dataflow mark. ⚠ It is a **NECESSARY condition, not a proof** — the promise is about every write path and no analysis can enumerate paths; what is checkable is that the setter announces, which is a sound negative. An unfixtured declaration FAILS rather than being skipped, so the section cannot rot as pins are added. ⚠ Fixtures are keyed on the DECLARING class, so a subclass that adds a write path bypassing the funnel is NOT covered — a stated blind spot, not a silent one.
- [x] **P4 residue — the `<action>IsConnected` flags — ✅ DONE 2026-08-17 (with P2's follow-ups).** The write in `ControllerMixin._addWire` and all twelve declarations are gone (`CalculatingPatchNodeWdgt` 4, `RegexSubstitutionPatchNodeWdgt` 4, `DiffingPatchNodeWdgt` 4). Verified read by NOBODY first — a sweep of `src/`, `tests/`, `scripts/` AND `Automator-and-test-harness-src/`, since a member can have zero `src` references and still break a rig. ⚠ One of the twelve was `setInput2HotConnected`, missing the `Is` — so `_addWire`, which writes `<action>IsConnected`, never even set that one: a vestige of a vestige, and the kind of thing only deletion finds. The `W2` line above still names these flags as a rider; that rider is now discharged. ⭐ The filed cost was wrong in the cheap direction: this entry predicted "it shifts three more inspector member lists — a second recapture round", and the suite came back **green with zero recaptures**, because no test inspects those three patch-node classes. A deferral justified by a cost nobody measured cost nothing to undo.
- [x] **The menu sweep walked FOUR of the desktop's THIRTEEN rows — ✅ FIXED 2026-08-18, and it had hidden a nine-year-old crash.** Found while measuring §P10(c)'s domain, not by looking for it. `WorldWdgt.buildContextMenu` opens `if @isIndexPage … return menu` with a four-row product menu, and `isIndexPage` is false ONLY on `worldWithSystemTestHarness` — so on the `index-sw.html` the rig drives, the world root never reached the long branch, and the rig's own `world.isDevMode = true` (commented "the demo submenus — where both crash-class bugs lived — are only offered when it is on") was enabling a branch behind an early return. Both branches are real menus somebody sees, so BOTH are now swept (`world[product]`, `world[desktop]`; 17 roots → 18). ⭐ What it hid: **`"about Fizzygum..."` dispatches `WorldWdgt.about`, a method deleted in 2017** (`8394c1a3`, "removing the about method") with its row left behind — a menu item that throws, in the first menu anyone opens, for nine years. The row is DELETED (the method's removal was deliberate; inventing an about box is a product decision, not a defect fix). Plant-proven: with the row restored the extended rig FAILS `UNRESOLVED_ACTION` where the old one passed on the same tree. ⇒ ⭐⭐ **when a rig STATES a coverage, check the statement** — this one's own comment called the world root "the door to the demo tree" while walking four rows of it. ⚠ A second-order defect fell out of the fix and is also closed: an action can flip the very flags that decide a menu's shape (`switch to user mode` → `toggleDevMode`), which left every LATER widget menu empty and reported as "no menu returned" — 16 of 18 roots silently unavailable — so `sweepRoot` now restores `isDevMode`/`isIndexPage` per root, the same "put the world back as we found it" rule it already applied to children.
- [x] **`check-dead-methods.js` is blind to a method whose NAME is an ordinary English word — ⇒ MEASURED 2026-08-18 AND DELIBERATELY NOT FIXED.** It is NAME-keyed (it must be: a computed-name dispatch can name any method) and harvests every identifier from `src/`, the harness and test `.js`. So `ToggleButtonWdgt.select`/`.toggle` sat dead and invisible, and were found by hand. Three candidate fixes were measured and all three fail:
  ① **Class-awareness is not viable.** 210 of 1826 method names (11.5%) are defined in two or more UNRELATED classes — the population where a live method masks a dead one — but only **10% of references to those names carry any class information** (`@name`); the rest are `x.name`, whose receiver needs real type inference, or bare words. An attributable-only analysis flags **543** (class, method) pairs, essentially all false.
  ② **Harvesting rules do not help**, and this was PLANT-TESTED rather than argued: excluding prose (the five mandatory descriptive metadata fields, plus `//` and macro `#` comments) reveals **0** methods today and would NOT have caught either of the two. `toggle` survives on a LOCAL LOOP VARIABLE (`for toggle in @_toolToggles()`) and on an assertion description string; `select` survives because `ListWdgt.select` is genuinely live. Neither is strippable without parsing CoffeeScript and resolving receivers, which the gate's header explicitly disclaims.
  ③ **The one sharp-looking signal is a pure false-positive generator.** The 21 (class, method) pairs reachable ONLY by a bare word are exactly the STRING-DISPATCHED population — `PinSpec` setters (`bang`, `setInput1..4`) and `addMenuItem`/`wireTo` actions (`setFontNameFromMenu`, `setAlignmentToLeft`, `doSelection`). All 21 are live.
  ⭐⭐ **And ③ is the synthesis, which is why not fixing this is the right answer rather than a shrug: the class of method a static reference scan cannot see is precisely the class the two RUNTIME sweeps already cover.** `pin-sweep-headless.js` proves every `PinSpec` setter/getter RESOLVES and `menu-click-sweep-headless.js` proves every menu action does — both strictly stronger than "the name appears somewhere in the tree". The blind spot is covered where it matters; what remains (a method shadowed by a same-named local, or by a human-readable string) is a small residue no scanner can close, and it stays STATED in `architecture/lint-and-static-checks.md`. Surveys: `Fizzygum-tests/.scratch/a2-dead-method-collision-survey.js`, `a2-prose-reference-survey.js`.
- [x] P8: scroll joins the wire vocabulary — ✅ **DONE 2026-08-17.** `ScrollPanelWdgt` gains readable `scroll x`/`scroll y` pins, its bars bind with the new reciprocal verb `ControllerMixin.trackTarget`, and `_reLayoutScrollbars`'s four-number push is one `markNonValueChange` ⇒ ANY number of bars follow, duplicates included (complaint ① closed; `macroInspectorScrollbarUnplugged`, which existed to record the ASYMMETRY, now shows both knobs meeting). ⭐ **The four-number channel did NOT become W2's customer — it carries no payload at all:** a node has one value and a scroll frame has no one number, so the edge is `firesOnAnyChange` ("wake me, I re-read you") and the bar pulls the value through the pin its own `@action` writes (`Widget.pinDrivenBy`, landing with the first caller it was reserved for) plus a `SliderRange` for the scale. ⇒ **before reaching for a multi-field PUSH, ask whether the consumer can re-read.** Two bugs found: a TRACKING bind must not push on connect (a slider is born at 50, so binding a scrollbar scrolled its panel to 50 — via a POOLED fire, landing a cycle later ⇒ `RECALC_NONCONVERGENCE` + `NON_FINITE_GEOMETRY`), and `markNonValueChange` must NOT copy `markStale`'s echo rule (it wakes a different edge set, so the guard DELETED the announcement rather than deduplicating it). `setScrollX/Y` are now clamped like every other scroll path
- [x] P10(d): a switch is a VIEW OF A VALUE — ✅ **DONE 2026-08-18.** `SwitchButtonWdgt` declares `shown button` (numerical, `setToggleState`/`getToggleState`, `announces: true`) as its `principalPinLabel`, so a toggle is driven through the ordinary "set target" gesture with no new machinery, and `exportedValue()` answers `0` where it answered `undefined`. ⭐ **The plan's open question — boolean payload vs `0`/`1` — DISSOLVES rather than gets decided**, and the general class is where it dissolves: a switch is n-way and its state is an INDEX into `@buttons`, so a boolean is only what the n=2 case looks like from outside. No fourth payload kind for one widget; the setter clamps instead. ⚠⚠ **THE FILING WAS WRONG ON TWO OF ITS THREE CLAIMS, measured on a live instance before any change**: the "non-firing reflect path" it says is missing is `setToggleState`/`_setToggleState`, which exist, work, and provably fire nothing (5 call sites across `PaintToolbarWdgt` and `VideoPlayPauseToggle`); the "no reader" is `isSelected`, which exists and `RadioButtonsHolderWdgt` uses. What was really missing was the pin — and the FUNNEL that earns its `announces`: `@buttonShown` had THREE write paths (`mouseClickLeft`, `_setToggleState`, `_resetSwitchButton`) and now has one. ⇒ `ToggleButtonWdgt.select` and `.toggle`, the `mouseClickLeft()`-simulating pair the filing quotes, are DELETED — both had zero callers. ⚠ They were invisible to `check-dead-methods.js`, which is NAME-keyed and harvests every word of every comment and test-metadata string: `toggle` and `select` are ordinary English words, and a live `ListWdgt.select` covers a dead `ToggleButtonWdgt.select` besides. New test `macroSliderDrivesAToggleButton` drives the pin through the real gesture (a pin verified only where it is constructed is §P4's green-while-asserting-nothing trap) — and the image that carries it is the one taken BEFORE any drag, since binding pushes the controller's current value and so the toggle flips on connect. ⚠ NOT done and deliberately so: `sliderRangeForPin`, which would let a slider FOLLOW a toggle and scale to it — that is the parked FOLLOWER arc, and its cycle rule lives there.
- [x] P10(c) — ⇒ **RE-AIMED 2026-08-18 BY MEASUREMENT (the gap is a LIFETIME, not a vocabulary), then ✅ CLOSED the same day.** The filing asks for a COMMAND table, the button-side twin of `PinSpec`. Measured what such a table would curate FROM: **402 methods on a plain `Widget`, 517 on `WorldWdgt`, 6923 across 15 representative classes** — where a pin table is small because "properties others may drive" is naturally tiny. Measured what already curates it: **the context menu, 234 commands on those same 15 classes**, labelled, per-class, chaining through `super`, and well-formed at **273 of 274** (0 missing targets, 0 non-string actions). ⭐ **But the decisive fact is that a context menu is not a TABLE of commands — it is a PANEL OF BUTTONS ALREADY POINTED AT THINGS** (`MenuItemWdgt extends LabelButtonWdgt extends ButtonWdgt`, 328 of them). So "let the user point a button at something" is not missing; it happens every time a menu opens. What is missing is that the button is DESTROYED when the menu closes — which is exactly what citizenship point 5's "menu entries are widgets, so handy commands can **in principle** be extracted into a custom control panel" is describing. ⇒ the arc is **drag a menu row out and keep it**, not a second declaration of the same fact at 328 sites (§P1's "a fact stated twice will disagree") and not a harvesting API either. It costs no menu row, which is what §P2's rent law asks of a feature. ⚠ Verified feasible before filing it this way: `MenuRowsPanelWdgt.createMenuItem` resolves all four dispatch slots at CONSTRUCTION and stores them as fields — in the common branch `dataSourceWidgetForTarget = item` (the row) and `widgetEnv = @target` (the widget the menu was FOR) — so an extracted row carries a complete, valid dispatch that references the target widget, not the menu (both fields were retired the same day by the dispatch-slot-protocol arc — see the entries below; the dispatch itself still resolves at construction). Two things to build: the `rejectDrags` opt-out (buttons are deliberately "slippery" so menus can be swiped — the proposed resolution is that a PINNED menu gives up its rows, composing two existing gestures with no new mode), and ~~the sharp edge: reflected rows~~ — ✅ **ANSWERED AND CLOSED 2026-08-18, before the rest of the arc: see the entry below.** It was filed as "an extracted row would freeze — re-subscribe or refuse", and measuring dissolved the choice: the ROW already did 100% of the reflecting, so the subscription simply belongs on it. ⇒ **the `rejectDrags` opt-out is BUILT — ✅ DONE 2026-08-18, and the arc is closed.**
  ⭐ **A PINNED menu gives up its command rows**, which is the proposal the filing made and measurement kept: an unpinned pop-up IS
  mid-gesture UI and a pinned one IS desktop furniture — `PopUpWdgt` already draws exactly that distinction and its serializer already
  turns on it — so the deliberate act is the pinning, which already exists, and extraction costs no new gesture, no new mode and no menu row.
  ⚠⚠ **THE FILING NAMED ONE THING TO BUILD AND THERE WERE THREE** (the fifth filing in a row wrong about its own scope). `rejectDrags`
  is only ONE of the two questions a grab asks: measured on a live pinned menu, a row also answers `grabsToParentWhenDragged() == true`
  (its parent is a `SimpleVerticalStackPanelWdgt`, not a `PanelWdgt`, so the rule falls through to solid-with-parent), so freeing
  `rejectDrags` alone would have lifted the whole MENU. ⇒ the fix is ONE declaration read by BOTH questions:
  `MenuRowsPanelWdgt.wantsDetachOfChild` — the existing parent-side opt-in (first client: the spreadsheet `CellWdgt`'s hosted payload) —
  with `ButtonWdgt.rejectDrags` gaining a clause that consults it. ⭐ **That generalisation states the rule where it belongs**: a button is
  slippery unless its PARENT says it is a payload rather than a part, and resting on the desktop is the same statement made by the one
  parent with no reason to spell it out. ⭐ **And it fixed a live contradiction, plant-proven both ways**: `CellWdgt` has declared
  `wantsDetachOfChild` since F4, and for the whole button family `rejectDrags` was silently vetoing it — a `SimpleButtonWdgt` hosted in a
  cell is refused under the old rule and grabbable under the new clause. The third thing was **a cut wire**: the absorb query
  `SimpleVerticalStackPanelWdgt._reactToChildRemoved` puts to its DIRECT parent reaches the `PopUpRowsPaneWdgt`, not the pop-up, so a row
  leaving a LIVE menu left the pop-up drawn at its old height with a blank strip where the row was — dormant only because every
  `removeMenuItem` call in the tree runs inside an `addWidgetSpecificMenuEntries` override, while the menu is still being composed.
  `PopUpRowsPaneWdgt` now forwards it. ⚠ The header and the dividers are rows too, and are protected TODAY *only* by
  `grabsToParentWhenDragged` (both answer `rejectDrags: false`), so a blanket opt-in would have TORN THE HEADER OFF — the panel hands out
  a row carrying an `action`, which over 281 rows of 12 menus is exactly the `MenuItemWdgt` population and is the fact that matters
  rather than a proxy for the class. A `ListWdgt`'s rows panel needs no exception: it is in no pop-up, so the climb reaches the world,
  which holds no opinion about being pinned. New test `macroExtractMenuRowFromPinnedMenu` drives the whole thing through the REAL gesture
  (§P4's green-while-asserting-nothing rule) and pins the negative too. ⚠ Authoring note now in MACRO-PATTERNS: a press-drag whose RELEASE
  lands off an UNPINNED menu dismisses that menu — the release is a click outside — so the pinned/unpinned contrast cannot share one menu
  and is not a byte-identical no-op pair.
- [x] **A reflecting menu ROW owns its own subscription — ✅ DONE 2026-08-18.** Filed as §P10(c)'s hard part ("an extracted row would freeze silently; re-subscribe or refuse to extract") and it turned out to be **neither option: it is a simplification worth doing on its own merits, extraction or no extraction.** ⭐ **The panel was subscribing to something only the ROW does.** All of reflecting is `MenuItemWdgt._applyRowReflectionNoSettle` — three lines, reading MY source through MY `readerName` and setting MY label; the panel contributed the subscription alone, and paid for it by fanning out over EVERY child on each delivery and deduping its own edges (several rows routinely share one source: 7 wallpapers, 9 fonts). Now each reflecting row calls `addEdge source, @, action: "applyRowReflection", firesOnAnyChange: true` in its constructor. `MenuRowsPanelWdgt._subscribeToReflectedSource`, `_reconcileReflectedRowsConnector` and `_reconcileReflectedRowsNoSettle` are DELETED and the panel takes no part in reflection at all. ⇒ Costs at most 9 edges per open menu where there was 1, and each delivery wakes exactly the row whose value moved instead of walking every child. ⚠ No gate concession needed: check-layering's `[P]` is a SHAPE rule (the caller must be a `_<name>Connector`), so the row's lane satisfies it — only the dead-method allowlist line moved, since a connector is reached by computed name. **Probe** (`Fizzygum-tests/.scratch/a1-row-owns-reflection-probe.js`) pins both halves: two open wallpaper menus still agree across an API change (nothing regressed), AND a row re-parented out of its menu — with that menu then DESTROYED — still ticked itself when its value won (`"    plain"` → `"✓ plain"`), which is the capability the extraction arc needs and which a panel-held subscription could not have. 0 recaptures.
- [x] **The desktop menu's `isIndexPage` fork DELETED, and a liftable row now SAYS it is liftable — ✅ DONE 2026-08-18 (both owner-decided).** ⇒ **THE FORK.** Owner call: a leftover, unify. Measured first, and the fork was worse than filed: on a product page `isDevMode` made **NO DIFFERENCE AT ALL** (the early return preceded every dev item), so dev mode was unreachable there AND there was no row with which to turn it on — while the block's own comment claimed the six items a product desktop wants were "unconditional now, so the homepage gains them" when they sat inside `if @isDevMode` **and** behind the early return. `isIndexPage` is false ONLY on the test harness, so forking on it forks "the product" against "the tests", which is not a distinction a menu has any business drawing: what a desktop can offer depends on which PARTS shipped and whether dev mode is on, and both are asked per item. Now ONE menu — 10 rows in user mode, 14 in dev, identical on both pages. ⚠ Every dev item was dispatch-tested under product conditions first (`isIndexPage` true, `isDevMode` false): all clean, nothing assumed dev-only state. ⚠ The unification runs BOTH ways — the harness GAINS `save world snapshot…` and `open from file…`, which the fork had made product-only, so `assertTopMenuItemCount` moves 15 → 17. ⚠⚠ **A CoffeeScript trap worth knowing: an `if` expression written directly as an implicit-object value on its own line does not become that value.** Writing the title that way yielded `undefined`, which cost the menu its entire `MenuHeader` row — and with it the thing you click to drag the menu and the thing you click to PIN it. The build was perfectly happy; only measuring the built menu caught it. Compute such a value into a local first. ⇒ **THE AFFORDANCE.** Owner call: a visible mark on liftable rows. A 2px bar down the row's left edge, `Color.DARKGRAY`, stopping 3px short top and bottom so consecutive rows read as separate grips rather than one rule down the menu; drawn in `LabelButtonAppearance`, driven by `ButtonWdgt.isDetachablePayloadOfMyParent` — **the same declaration the grab reads**, so the mark and the behaviour cannot disagree. ⚠ **DRAWN, not a glyph in the label**, for two reasons and the second is the bigger: many characters are absent from the bitmap-font atlas and render as a black box (owner-flagged), and the label STRING is an IDENTITY — menus are driven, swept and tested by matching it, so decorating it would rename every row it marked. ⚠ Pinning had to be taught to invalidate its rows (`PopUpWdgt._invalidateRowsAfterPinChange`): their paint derives from a flag on the POP-UP, and the shadow swap cannot stand in for it — it marks the pop-up, which re-blits its buffer without re-rendering the rows inside. ⭐⭐ **And the grip's geometry was placed relative to `localDamageBox`, which is the DAMAGE BOX and not the widget's rect** — so on a partial repaint it landed relative to whatever region was redrawing, and a row that moved up when its neighbour was dragged out came back three pixels short. Caught by the paint-truthfulness gate; **no screenshot test can see this class**, because the reference simply bakes it in. Law now stated in `docs/architecture/appearance-paint-convention.md`, and the parameter renamed `localArea` → `localDamageBox` (with `clipsToLocalArea` → `clipsToDamageBox`) because two comments already had to gloss it as "the damage box" at the point of use. 20 tests recaptured, gate COMPLETE. ⇒ **Two owner confirmations closing this out, recorded so they are not re-litigated: (a) the grip's LOOK is approved as shipped** (2px, `Color.DARKGRAY`, inset 1px, 3px short top and bottom); **(b) product pages reaching dev mode is INTENDED** — deleting the fork gave the product desktop the `switch to dev mode` row it never had, and that is the point: a desktop that cannot be switched into dev mode has no developer affordances at all. ⚠ And the grip family is NOT over-broad in practice, measured in a world holding a pinned menu, an unpinned menu, a spreadsheet, a list, a tool panel and a paint toolbar: the entire population is `MenuItemWdgt` — 15 in the pinned menu and 0 everywhere else, because a grip needs BOTH a `LabelButtonAppearance` and a parent that declares payloads, and only `MenuRowsPanelWdgt` and `CellWdgt` do. A `MenuItemWdgt` in a cell is by construction an EXTRACTED command someone carried there, so marking it still-liftable is correct rather than merely tolerable. ⚠ Unverified corner: that cell-hosted case would not render in the probe fixture, so its appearance is reasoned from shared drawing code, not seen.
- [x] **open Q — geometry pins: ✅ ANSWERED 2026-08-17 BY MEASUREMENT — (c), and (d) is closed.** The fear was that a TRACKING PAIR shears by one frame under fast motion (guessed at 3–5 px). It does not, and the reason inverts the argument: `doOneCycle` plays INPUT before the dataflow station, so every gesture-driven scroll — wheel, thumb drag, track click — announces itself in time for the SAME cycle's drain. **Measured 0 frames at every fling rate** (`Fizzygum-tests/.scratch/p8-scroll-shear-probe.js`), and **exactly 1 frame** only for a change born inside `recalculateLayouts` (a content re-fit changing the bar's RANGE) — the case with no motion to shear against. ⇒ the one-way law is narrowed, not broken: layout may never `markStale`, but it MAY `markNonValueChange` (wakes only re-readers, pulls nothing, marks nothing). ⛔ (b)/(b′) were already closed; (d) now joins them — it would add a second `recalculateLayouts` per cycle to buy back a lag that is zero where it would be visible. ⚠ `width`/`height` stay write-only, now as a positive choice (nothing binds them) rather than a holding position: the bar for a readable geometry pin is a real consumer. (e) readable-but-not-bindable is still orthogonal and still lands with P2.
- [x] **P1 residue — a gate for "a pin's setter must exist" — ✅ DONE 2026-08-18.** `Fizzygum-tests/scripts/pin-sweep-headless.js` (`npm run pin-sweep`): 238 instantiable classes, 2471 pin checks, 22 abstract bases skipped, 3 appearances checked on their 22 wearers, 6 `announces` fixtures. Rule (b) as designed — resolve DOWNWARD, derived, no `isAbstract` marker — and it BITES: planting a missing setter on `RectangleWdgt` was caught on `RectangleWdgt` **and both its subclasses**, an announcing-but-silent pin was caught, and an `announces` with no fixture was caught.
      ⭐⭐⭐ **IT WAS NOT A REGRESSION GUARD. The filed "BASELINE: ZERO live violations" WAS WRONG, and the reason is instructive: the filing knew of ONE appearance-contributed pin (`BoxyAppearance` corner radius, called legitimate) when there are THREE** — `BubblyAppearance` and `MenuAppearance` inherit it from `BoxyAppearance`, which is the only one that declares it. `setCornerRadius` lived on `BoxWdgt` alone, so **16 other classes** — windows, buttons, images, tooltips, speech bubbles, menu panels — advertised a `corner radius` pin that resolved to nothing AND a "corner radius..." menu item whose Ok **THREW** (`@widget[action].call` on undefined; the pin's `?.` is silent, the prompt's dispatch is not). Verified on live instances before anything changed: `BoxWdgt` went 4 → 23, `FrameWdgt` and `ImageWdgt` threw.
      ⇒ FIXED by moving `cornerRadius` + `setCornerRadius` onto `Widget`, beside `appearance`: every rounded appearance already reads `@widget.cornerRadius` unconditionally and supplies its own default, so the field was ALWAYS part of the widget↔appearance contract and merely undeclared. Test: `SystemTest_macroCornerRadiusPromptOnANonBoxWidget`.
      ⚠ **`fg menusweep` could not catch this class — SO IT WAS EXTENDED, same day.** It dispatched the menu action, which opens the prompt perfectly well, and never pressed its Ok; a rig that stops at the first dispatch cannot see a two-step gesture, and an item ending in "..." does its real work in the prompt's callback (`@target[@callback].call`, no `?.`). It now presses every prompt's Ok with the prompt's own default contents (coverage 515 → 589 distinct pairs, 36 prompt Oks). ⭐ **Proven by planting the corner-radius defect back**: the extended rig FAILS with `PROMPT_OK_THREW` on `FrameWdgt` and `FolderWindowWdgt` where the old one passed. ⚠ It catches 2 of the 16 affected classes and the pin sweep catches all 16 — its coverage model is hand-picked REPRESENTATIVE roots, not exhaustion, so the two rigs are complementary rather than redundant.
      ⚠ The appearance section needs its own discovery path: `@appearance` is assigned in a CONSTRUCTOR, so a bare `Object.create(proto)` has none and those pins are invisible to the main sweep. Wearers are found by the `new <X>Appearance` edge in the source text — sound for THIS question (unlike the composed-`pins()` question the runtime sweep exists for) and the same edge the boot scanner already reads.
      The design reasoning that produced it, kept verbatim below because every conclusion held:
- [x] **P1 residue — a gate for "a pin's setter must exist" (the ANALYSIS).** P1 found `StringWdgt` advertising a `bang` pin implemented only on `SimpleTextWdgt`: the menu offered a target property whose dispatch (`consumer[action]?.call`) swallowed the miss, so it silently did nothing, indefinitely. Nothing catches this class — `check-unresolved-sends.js` cannot see a computed-name dispatch, and the `pins` declarations are data. A `PinSpec` naming a setter/getter that does not resolve is a **sound negative** ⇒ hard gate, per `architecture/lint-and-static-checks.md` §3b. Scoped deliberately OUT of P1: discovered there, not part of it.
      **✅ DESIGN QUESTION ANSWERED + BASELINE MEASURED 2026-08-17.** The filed question was how to express "concrete", given that `PatchNodeWdgt` declares `setInput1..4` its subclasses implement. Options were (a) a class-level `isAbstract` marker, (b) resolve DOWNWARD, (c) allowlist the abstract bases.
      ⇒ **(b), DERIVED — a pin must resolve on every LEAF of the declaring class's subtree, and on the declaring class itself unless it has subclasses.** ⛔ (c) is wrong on CORRECTNESS, not taste: allowlisting a base silences the base AND everything under it, so a concrete subclass inheriting a pin it does not implement would never be checked — exactly the bug the gate exists to catch would be the thing the allowlist hides. ⛔ (a) states a second time what the class graph already shows (a fact stated twice will disagree — mark a class abstract, let someone instantiate it later, and nothing notices), and it is a tree-wide declaration for ONE consumer; introduce it with a SECOND one (creation menus refusing to instantiate a base, the dead-code gate), not this. The residual hole in (b) — a class that is both a base AND instantiated — closes with "is it ever `new`-ed", derivable from the same regex scan `src/boot/dependencies-finding.coffee` already performs. No new vocabulary either way.
      ⚠⚠ **THE HARDER PROBLEM IS NOT THE ABSTRACT MARKER — IT IS COMPOSITION, and a TEXT SCAN CANNOT DO IT.** `pins()` is composed (`super().concat @_inputPins()`), and a subclass may NARROW the inherited set by overriding the helper: `DiffingPatchNodeWdgt` overrides `_inputPins` to declare only `in1`/`in2`/`in1 hot`/`in2 hot`, so it never advertises `in3`/`in4`. A textual "PinSpec site → declaring class" analysis therefore reports pins a class does not have — measured, by writing exactly that analysis and having it accuse `DiffingPatchNodeWdgt` of a defect it does not have.
      ⇒ **Build it as a RUNTIME sweep, the split the tree already uses for menus** (`check-menu-actions.js` static ∥ `fg menusweep` runtime): boot a page, and per class `inst = Object.create(X.prototype)`, call `inst.pins()`, check `typeof inst[pin.setterName] is "function"`. That evaluates the REAL composed list, so helper overrides are handled for free and there is nothing to keep in sync.
      ⚠ **An appearance-contributed pin resolves on the WIDGET, not on the declarer** — `Widget.pins` concatenates `@appearance?.pins?()`, and `BoxyAppearance`'s `corner radius` setter lives on `BoxWdgt` (its own comment says so). Model that, or report those pins as UNCHECKED — a visible blind spot, never a silent exemption.
      ⚠ **BASELINE: ZERO live violations** (14 classes declare pins; the only two that do not resolve on their declaring class are `PatchNodeWdgt` in1..in4 and `BoxyAppearance` corner radius, both legitimate per the two rules above). ⇒ this is a REGRESSION GUARD, not a bug hunt — price it accordingly.

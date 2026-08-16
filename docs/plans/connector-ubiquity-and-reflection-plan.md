# Connector ubiquity & the controller-is-a-view law

**STATUS: design-stage, AUTHORED 2026-08-14. Owner-gated. ONE step executed: P9 LANDED 2026-08-16**
(the `@target` disambiguation — §6's step 3; see the P9 section for what actually landed and what it
deliberately left alone). Everything else is still design-stage with no code written.
Anchor on **symbol names** (verified against `src/` on 2026-08-14); line numbers drift.
Self-contained.

**Not** a plan to extend the wire *vocabulary* — that arc exists and is untouched by this one
([`wire-vocabulary-extensions-plan.md`](wire-vocabulary-extensions-plan.md): per-event delivery,
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

### 2.4 The pin vocabulary is WRITE-ONLY

`Widget.colorSetters()` / `stringSetters()` / `numericalSetters()` / `allSetters()` return a pair of
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

Three important state holders are neither widgets nor nodes, appear in no setter table, and
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

### 2.7 Controllers that aren't views: the palette

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
| **G1** | **Write-only pins.** Setter tables have no reader twin; a node has one `dataflowValue()`, not a value per pin. | any generic reverse edge; showing current values; per-property spreadsheet reads |
| **G2** | **Single-slot, one-way wires.** One `@target`/`@action` ⇒ one out-edge; no un-wire; fan-out only via a non-production widget. | two-way binding (the return wire has nowhere to live); the citizenship doc's own claim |
| **G3** | **Change announcement is opt-in and rare.** Six classes announce, for one property each. | anything driven by a menu, a script, the loader, or another widget's method call |
| **G4** | **Non-widget state has no node identity.** Wallpaper, preferences, scroll offset. | the wallpaper-menu complaint outright |
| **G5** | **Reflection is private field plumbing.** `if @vBar.target == @ … updateSpecs`; `_updateHandlePosition` on one class with one caller. | duplicated/foreign controllers following the value |

Complaint ① is G5 + G1 + G4(scroll). Complaint ② is the *view* half of the law plus G1. Complaint
③ is G4 + G3 + G6-as-view (§2.6).

---

## 4. Proposals

Ordered by dependency, not by value. §6 gives the recommended landing order, which is different.

### P1 — Pins become readable

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

### P2 — Reciprocal binding: **two wires, not a new edge kind**

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

### P3 — One announcement verb, and where it may not live

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

⚠ **Geometry pins are the genuinely hard case and should be excluded from v1.** `width`/`height`/
`padding` are pins today (`Widget.numericalSetters` → `_applyWidth`, `_applyHeight`, `setPadding`),
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

**Recommend (a) for v1**, and record (b)/(c) as considered-and-deferred so nobody re-derives them.

### P4 — A controller owns a LIST of wires

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

### P5 — Non-widget state becomes nodes (zero engine change)

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

### P6 — Give the palette its picture

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

### P7 — Ticks become a reflection, not a redraw

A menu item declares the pin it reflects and the value that ticks it; one shared reconciliation runs
when that pin's edge delivers. This retires four hand-rolled routines, kills the `rows[1]…rows[7]`
index fragility, and makes ticks correct across instances, API changes and snapshot loads. It is the
view half of P5 and should land with it.

### P8 — Scroll joins the public wire vocabulary

`ScrollPanelWdgt` defines **no** setter table override at all today, so its scroll position is not
offered by any connect menu and `adjustContentsBasedOnHBar` / `adjustContentsBasedOnVBar` are
reachable only by direct assignment. Proposal:

- advertise user-meaningful numerical pins (`scroll x`, `scroll y`) with readers, renaming the
  actions to match the pin (`setScrollX`, or keep the existing names behind the `PinSpec.set`);
- bind the panel's own bars with the same public mechanism everyone else would use;
- **retire `_reLayoutScrollbars`'s `if @hBar.target == @ … updateSpecs` field plumbing** in favour of
  the reverse edge, so any number of bars — including duplicates and bars belonging to nobody —
  follow the content. That is complaint ① closed.

⚠ **`updateSpecs` carries four numbers, not one** (`start`, `stop`, `value`, `size`): the bar's
*range* changes when the content resizes, not only its value. So the reverse channel is genuinely a
structured update. Two options:

- a small immutable value class as the payload (house law:
  [`../architecture/immutable-value-classes.md`](../architecture/immutable-value-classes.md) —
  operations return new instances, `equals` for the cutoff); or
- four pins set cold, then one hot — **which is exactly the cold-edge idiom that
  [`wire-vocabulary-extensions-plan.md`](wire-vocabulary-extensions-plan.md) §4.W2 reserves and
  whose open question is "no customer exists yet".** ⭐ **Here is a customer, and it is product code,
  not a hypothetical sequencer.** Whichever option wins, this fact should be recorded in that plan.

### P10 — Buttons: **NO** to engine delivery, **YES** to the gesture and the index

Owner question, 2026-08-14: *"buttons don't connect to their destinations using the connection
system. Should they?"* The honest answer splits three ways, and the split is worth recording as a
law, because "unify the two `@target`/`@action` mechanisms" looks obviously right and is not.

**Current state.** `ButtonWdgt` holds `@target` / `@action` / `@doubleClickAction` /
`@argumentToAction1` / `@argumentToAction2` / `@dataSourceWidgetForTarget` / `@widgetEnv`, and
`trigger()` is one synchronous call inside the click handler:

```coffee
@target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, @argumentToAction1, @argumentToAction2
```

It does **not** `@augmentWith ControllerMixin`, declares no edge, and appears in no setter table. The
population is large: `MenuItemWdgt` extends `LabelButtonWdgt` extends `ButtonWdgt`, so **every one of
the 328 `addMenuItem` call sites in `src/` is a button edge** — roughly two orders of magnitude more
than the wire edges.

#### (a) Delivery: NO — a command is not a current value

Five independent reasons, any one of which is sufficient:

1. **Count matters and pooling destroys it.** `@stalePool` / `@forcedPool` are `Set`s, so two bangs
   in one cycle are one fire. Click a button twice, get one invocation. Count-preserving delivery is
   exactly the deferred `firesPerEvent` mini-pass
   ([`wire-vocabulary-extensions-plan.md`](wire-vocabulary-extensions-plan.md) W1) — **so routing
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
[`wire-vocabulary-extensions-plan.md`](wire-vocabulary-extensions-plan.md) §8 already makes for
audio, one level up.

#### (b) The index: YES — one edge vocabulary, two delivery mechanisms

The button's `@target` **is** an information-flow edge, and today nothing indexes it — so the system
cannot answer "what does this button touch?", cannot show the wiring, and cannot count it for
reachability. That is precisely what
[`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md) §4.2/§4.3 wants (a common
add/remove/enumerate accessor over containment ∪ target ∪ reference, and one GC walk over the
union), and §4.2's ruling — *"keep the dataflow index as the single home of the target edges, don't
fork it"* — already covers buttons whether or not anyone noticed.

Shape: a button declares `addEdge @, @target, {action, command: true}`, and a **command edge is
excluded from the downstream closure** — indexed, never traversed, never delivered. That is
mechanically the same exclusion `cold` needs (W2), reached from a different direction. Zero change
to invocation; the payoff is discoverability, GC reachability, and the ability to *draw* the wiring.

#### (c) The gesture: YES, and this is the real gap

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

#### (d) Toggles and switches: here the answer flips to YES

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

### P9 — Naming: `@target` means four different things — ✅ **LANDED 2026-08-16**

Prerequisite hygiene for even discussing bindings. `@target` was: the dataflow target
(`ControllerMixin`), the dispatch target (`ButtonWdgt`), the inspected object (`InspectorWdgt`), and
the referent (`IconicDesktopSystemShortcutWdgt`).
[`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md) §4.1 already proposed
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
| 1 | **P5 + P7** — wallpaper (and input mode) as nodes; ticks as reflection | **none** | complaint ③ |
| 2 | **P6** — the palette's marker (+ the two riders, + picker gets `ControllerMixin`) | **none** | complaint ②'s view half |
| 3 | **P9** — the `@target` renames ✅ **LANDED 2026-08-16** | none | reading hazard |
| 4 | **P1** — `PinSpec` with readers | pull-a-pin | unblocks 5–6 |
| 5 | **P4** — a controller owns a list of wires | index mirroring; **serialization surface** | G2; frees `FanoutWdgt` |
| 6 | **P2** — the `bind ⇄` gesture | none (two ordinary wires) | the headline |
| 7 | **P8** — scroll pins + reverse edge, retire the field plumbing | none, given 1/4/5 | complaint ① |
| 8 | **P10(d)** — toggle/switch gain a value pin and a non-firing reflect path | none, given 4 | the `mouseClickLeft()`-to-set-state smell |
| — | **P10(b)** — index button edges as command edges | index only, no delivery | rides `graph-edges-and-lifecycle-plan.md` §4.2, not this arc |
| — | **P10(c)** — a command table + "make this button do X to Y" gesture | none | its own arc; needs P1's shape first |

Steps 1 and 2 are each a self-contained session. Step 5 is its own arc and needs the serialization
round-trip legs. Step 7 needs the `updateSpecs` payload decision (§P8), which is also the answer the
wire-vocabulary plan's W2 is waiting for.

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

1. **Geometry pins** — accept write-only (§P3 option a), or is a bounded exception to the one-way
   layout↔dataflow law worth designing?
2. **`PinSpec` record vs. keeping parallel arrays** with a third `[readers]` column. The record is
   the regularity-principles answer; the arrays are the smaller diff.
3. **Bind-time precedence** — "the side whose menu you opened pushes" (§P2), or an explicit
   source/mirror choice in the gesture?
4. **Palette off-map colours** — distinct "off-map" marker, nearest-point snap, or no marker at all
   when the colour is not on the surface?
5. **Scroll's four-number reverse channel** — an immutable `SliderRange` value payload, or the first
   real use of cold edges (and therefore a decision that belongs jointly to
   `wire-vocabulary-extensions-plan.md` W2)?
6. **Does `@wires` (P4) get a serialization version bump**, or does the `@target`/`@action`
   accessor shim make old snapshots load unchanged?
7. **Scope of P5** — wallpaper only, or wallpaper + `PreferencesAndSettings` in the same session?
8. **Command edges (§P10b)** — index button `@target`s in `world.dataflow` as non-traversed command
   edges, or leave the button edge unindexed until the unified collector arc actually needs it?
9. **Boolean payloads (§P10d)** — a bound toggle exports `0`/`1` as numerical, or does a fourth
   payload kind earn its menu?

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
- Sibling arcs: [`wire-vocabulary-extensions-plan.md`](wire-vocabulary-extensions-plan.md) (payload
  and edge *semantics*; W2 wants the customer §P8 supplies),
  [`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md) (the three-edge
  vocabulary; `@target` disambiguation), [`reference-widgets-plan.md`](reference-widgets-plan.md).
- Constraints: [`../architecture/layering-naming-convention.md`](../architecture/layering-naming-convention.md)
  (rule **[P]**: only `_<name>Connector` may join an enclosing pass),
  [`../architecture/integer-pixel-placement-and-sizing.md`](../architecture/integer-pixel-placement-and-sizing.md)
  (the quantisation §5 depends on),
  [`../architecture/serialization-duplication-reference.md`](../architecture/serialization-duplication-reference.md)
  (P4's surface), `../../../Fizzygum-tests/DETERMINISM.md`.
- Measured convergence: [`../measurements/dataflow-measurements.md`](../measurements/dataflow-measurements.md).

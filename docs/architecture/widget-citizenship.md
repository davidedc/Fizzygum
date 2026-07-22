# Widget citizenship — one live object carries state, presentation, and behaviour

A widget is a self-contained live object: it holds its own data, draws itself, and handles
its own input. That fusion — the three MVC roles united in one object — is the founding
design decision of the Morphic family Fizzygum descends from, and everything a widget is
expected to *do* for the rest of the system (the citizenship contract below) follows from it.

## The stance: MVC united in one object

Classic MVC (Trygve Reenskaug, Xerox PARC, 1979; institutionalised in Smalltalk-80) splits a
UI element across three classes: a Model holding the data, a View drawing it, a Controller
handling input. Morphic collapsed the split, from two observations:

- View and Controller classes were so interdependent they could only ever be used as an
  inseparable pair — the separation was ceremony, not modularity.
- Many graphical objects need no external model at all, and some are their own model: a
  string widget holds its own string rather than a reference to a potentially shared
  StringModel. (In Fizzygum: `SimpleTextWdgt` holds its text; a spreadsheet cell holds its
  value and formula.)

Uniting the roles does **not** forfeit MVC's one genuine power, multiple views on one model.
Fizzygum recovers it where it is actually wanted, through connections rather than class
structure: any widget can be *targeted* by any number of controllers and observed through
inspectors (`InspectorWdgt` is a live view onto any object), and the dataflow engine lets many
widgets derive from one source.

One separation IS kept, inside the object: what a widget *is* (state, geometry, behaviour) is
distinct from how it *draws* — painting lives in a pluggable `*Appearance` object, so a skin
can be swapped without touching identity (see
[`regularity-principles.md`](regularity-principles.md)). This is an internal seam of the
widget, not a return of MVC: the appearance has no independent life, no separate lifecycle,
and moves with the widget through duplication and serialization.

## Lineage

Fizzygum's widgets are the current end of a thirty-year line; "Wdgt" is the modern name for
what every ancestor system called a *Morph* (Greek *morphé*: shape), and Fizzygum itself was
called **Zombie Kernel** in its early years — older notes and commits use both legacy names.

- **Morphic in Self** (Randall B. Smith & John Maloney, Sun Microsystems, ~1993–95; UIST '95
  paper *"Directness and Liveness in the Morphic User Interface Construction Environment"*).
  The original statement of the two ruling qualities: **directness** (you manipulate the
  object itself, not a description of it) and **liveness** (the world is always running —
  there is no separate edit mode).
- **Morphic in Squeak Smalltalk** (Maloney's port, ~1997). Squeak's main UI, host of EToys
  and of Scratch 1.x; Maloney's chapter *"An Introduction to Morphic"* (2001) is the source
  of the classic formulations quoted throughout this doc (the StringMorph example, the
  "uniformity as a physics of morphs" framing). Continued today in Cuis and Pharo.
- **Lively Kernel** (Dan Ingalls et al., 2008) brought Morphic to JavaScript in the browser.
- **morphic.js** (Jens Mönig; the UI substrate of Snap!) — Morphic on a single HTML5 canvas.
  **Fizzygum forked morphic.js in October 2012** and over the following years rewrote most
  of it (display-list rendering, the settle/layout engine, class+instance tracking, mixins,
  serialization, dataflow); the `*Morph` classes have since been fully renamed to `*Wdgt`.

## The citizenship contract

What the system may assume of every widget, and what a new widget must provide to be a good
citizen:

1. **It carries its own state.** Everything the widget needs to function travels with it:
   duplicating any widget or subtree (the one graph copier, `DeepCopierMixin`) yields an
   independent working copy — state, connections among the copied group, and ongoing
   processes included — and serialization ships the same closure to disk. A widget that
   quietly depends on state parked elsewhere breaks both.
2. **It draws itself** — through its pluggable `*Appearance`, never by reaching into another
   widget's rendering. A widget invalidates only itself (`changed()` /`fullChanged()`); it
   never calls `changed()` *on another widget* — if A's action affects B, B marks itself
   changed in the method A invoked on it.
3. **It handles its own input**, and exposes its affordances uniformly: the right-click menu
   is the universal front door (edit, inspect, resize, attach, duplicate…), so every widget
   is automatically editable and inspectable without any per-widget tooling.
4. **It exposes pins.** A citizen is *wireable*: it enumerates the properties others may
   drive (`numericalSetters()` / `stringSetters()` — which populate the target-chooser menus)
   and can itself drive a chosen `@target`/`@action` (`ControllerMixin`). These wires are not
   decoration: a wire IS a dataflow edge (the engine's edge index derives from
   `@target`/`@action` — [`../specs/dataflow-engine-spec.md`](../specs/dataflow-engine-spec.md)
   §8). The standing direction is to prefer such connector endpoints over bespoke
   callbacks/firing methods, because only pins are discoverable, rewireable, and
   serializable by the generic machinery. In patch programming the pins are literal widgets
   (`FanoutPinWdgt` on a `FanoutWdgt`).
5. **It composes, and decomposes.** Any widget can contain widgets and be contained
   (`TreeNode` → `Widget` is the whole ontology); a composite behaves like an atomic widget.
   The flip side is mandatory: parts can be *taken out* and reused in other combinations —
   e.g. menu entries are widgets, so handy commands can in principle be extracted into a
   custom control panel. A widget that only works inside the assembly it was born in is a
   bad citizen.
6. **It doesn't bake in its editing chrome.** Content, manipulation chrome, and editing
   tools are separate citizens (the `Simple*` / plain / `FrameWdgt` tiers —
   [`regularity-principles.md`](regularity-principles.md)): a `Simple*Wdgt` is a naked
   capability (data + a self-mutation API), and rich editing arrives from *outside*, as an
   external toolbar operating on whichever compatible widget has focus (`TextToolbarWdgt`
   over any text). This keeps content embeddable anywhere and lets any number of editor
   styles serve the same content API.
7. **It steps politely.** A widget wanting a process subscribes itself to the world's
   activity list (`world.steppingWdgts`, hook `step:`) rather than owning a timer — that is
   how a clock ticks (`AnalogClockWdgt`) and how the stepping survives duplication and
   serialization with the widget.
8. **It obeys the house mechanics** — the settle/naming tiers, the notification grid, and
   integer placement ([`layering-naming-convention.md`](layering-naming-convention.md),
   [`layout.md`](layout.md),
   [`integer-pixel-placement-and-sizing.md`](integer-pixel-placement-and-sizing.md)).

## The acid test

> A mark of whether an application fits in the general citizenship of Fizzygum is whether it
> could be assembled manually using existing, simpler components.

Take the clock, the inspector, a paint app: each should be — at least in principle — a plain
assembly of simpler citizens plus small scripts, not a sealed special-case. The converse
test is disassembly: a good-citizen application can be taken apart and its parts recombined
into things its author never anticipated (mashups). The tools pass their own test: the
inspectors (`InspectorWdgt`, `ClassInspectorWdgt`) are themselves assemblies of ordinary
widgets, and can in turn be manipulated, inspected, and recomposed.

## Worked examples

- **`SimpleTextWdgt` + `TextToolbarWdgt`** — the tiering in action: the Simple widget owns
  the text and the mutation API; the external toolbar edits whichever text is focused;
  nothing is baked into the content.
- **`AnalogClockWdgt`** — a widget with a subscribed step function, not a special mechanism;
  duplicate it and both copies tick.
- **`SliderWdgt` / `ColorPaletteWdgt`** — generic controllers: pick any target from the
  chooser menu and drive any of its advertised numerical/colour pins.
- **`PatchNodeWdgt` family + `FanoutWdgt`/`FanoutPinWdgt`** — computing citizens whose
  inputs and outputs are explicit pins, wired into the same dataflow engine that serves the
  spreadsheet.
- **`FrameWdgt`** — manipulation chrome as a separate citizen wrapped around content;
  whether a content type is framed is intrinsic to the type, how the frame is skinned is
  derived from parentage.

See [`design-principles.md`](design-principles.md) for the system-wide principles this
contract serves.

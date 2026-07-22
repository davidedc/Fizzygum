# Fizzygum design principles — a direct-manipulation, authoring-first live environment

Fizzygum is a self-contained live environment — a "web operating system" on a single canvas —
built around three goals:

- **authoring via direct manipulation**: creating and reshaping things by grabbing the things
  themselves, with programming available at every depth but required at none;
- **live programming**: the environment never stops; users change any part of it — including
  the environment itself — from within, while it runs;
- **composition and mashups**: applications share one world, so they can share input, state,
  computation and output, be taken apart, and be recombined.

A fourth, structural goal disciplines the other three: the whole system stays small enough to
be **understandable and modifiable by one person**.

## Direct manipulation and liveness

The two ruling qualities, inherited from Morphic (see the lineage in
[`widget-citizenship.md`](widget-citizenship.md)): you manipulate the object itself, not a
description of it, and the world is always running — there is no separate edit mode, no
edit-compile-run cycle for changes made in-world. Text is edited by clicking on it; things
move by being dragged; a colour is changed with a picker aimed at the thing, not by locating
an RGB triplet in a file. Where a property has no direct-manipulation gesture, the right-click
menu is the universal fallback — and behind the menu, the inspectors go all the way down to
data and source.

## Authoring-first, not presentation-first

The DOM began as a presentation format: out of the box a page can be *viewed*, but nearly
every act of *authoring* (edit this text, restructure this tree) requires externally-supplied
scripting. Fizzygum inverts the default: every widget carries viewing AND authoring
affordances from birth — editable, movable, attachable, inspectable — because widgets are
objects that carry their own editing capabilities rather than inert markup awaiting a
separate editor. (This is the old Smalltalk argument against flat file formats; Fizzygum
adopts it *pragmatically* — flat formats are ubiquitous and have real virtues, so the claim
is only that inside this world, objects are the representation.)

## Uniformity — everything is a widget

Morphic's "physics": one general model, no special cases, so users can reason about the
system and combine parts in ways the designers never anticipated.

- Everything on screen is a widget; every widget descends from `Widget` (root: `TreeNode`,
  world: `WorldWdgt`).
- Any widget can contain widgets or be contained; a composite behaves like an atomic widget.
- The tools obey the same physics as the content: menus are made of widgets, the inspectors
  are assemblies of widgets, the world is a widget. Whatever holds for a rectangle holds for
  the debugger of the rectangle.

Every exception to uniformity undermines the user's ability to predict the system, so
distinctions that would break it are avoided; where a genuine distinction is needed, it is
separated and named per [`regularity-principles.md`](regularity-principles.md).

## Composition over chiselling

When building a new capability, first compose and configure existing widgets; only
custom-"chisel" a new class for what genuinely cannot be composed (text rendering is the
canonical irreducible). Even then, the new class should be *made of* existing pieces as much
as possible, and its parts designed for reuse outside it. The aspirational ceiling: complex
tools (an inspector, a class browser) buildable by composition alone — and the composition
process able to emit reasonable source code for the result.

The same app should be buildable three ways:

1. **from source** — a class that constructs and wires its widgets (how most of `src/apps/`
   is built today); code/run modes, but leaves named, inspectable, restartable source;
2. **by direct manipulation** — dragging, attaching and wiring live parts with little or no
   code;
3. **programmatically, step by step** — same as 2 but driven from a console.

Routes 2 and 3 are live but leave a *web of objects* with no blueprint source; route 1 leaves
source but not liveness of construction. Both forms are legitimate ways for an artifact to
exist — the web-of-objects form persists through duplication and serialization instead of
through source. This trade-off is accepted, not solved.

## Duplication as a first-class power

Any widget, group, or whole application can be duplicated, and the copy is *alive*:
state, in-group wiring, and ongoing processes come along (the one graph copier,
`DeepCopierMixin`). Duplication is therefore also the safety valve of liveness: experiment
aggressively on a copy, keep it if it's better. And since each object or assembly carries its
own state (see [`widget-citizenship.md`](widget-citizenship.md)), copies don't tread on their
originals.

## Connections over wiring code

Widgets are combined not just spatially but functionally: a controller targets any widget and
drives any of the pins that widget advertises, and such wires are dataflow edges in one
engine serving both the spreadsheet and patch programming
([`../specs/dataflow-engine-spec.md`](../specs/dataflow-engine-spec.md)). Preferring
discoverable, rewireable connections over bespoke callbacks is what makes route 2 above (an
app assembled by direct manipulation, no code) reachable at all.

## Metacircular, within limits

The system can inspect and modify itself from within: all ~470 classes ship as CoffeeScript
source text, compiled in the browser at boot and paired with their running code, so the class
inspector edits the actual system and every instance updates live (`src/meta/`; classes track
their instances for exactly this). Two honest limits are acknowledged rather than papered
over:

- **not "widgets all the way down"** — the machinery *supporting* widgets (rendering loop,
  layout engine, compiler plumbing) is made of plain non-widget classes;
- **a native floor** — the JavaScript runtime and the canvas are below the reach of in-system
  inspection and editing.

## A cooperative world

One shared, mutable world; widgets are assumed cooperative, not sandboxed. Self-modification
therefore has failsafes rather than guarantees: static errors are caught and reported with a
chance to correct, runtime errors are caught and can stop an offending activity from being
rescheduled, and the per-object carrying of state naturally limits the blast radius of a bad
change. The cheap, encouraged path to safety is social, not structural: work on a duplicate.

## Where these principles bind

- The per-widget obligations they imply: [`widget-citizenship.md`](widget-citizenship.md).
- The code-regularity law (separate fused axes; the name encodes the role):
  [`regularity-principles.md`](regularity-principles.md).
- The mechanics that keep liveness honest — settle tiers, notification grid, integer
  placement: [`layout.md`](layout.md),
  [`layering-naming-convention.md`](layering-naming-convention.md),
  [`integer-pixel-placement-and-sizing.md`](integer-pixel-placement-and-sizing.md).

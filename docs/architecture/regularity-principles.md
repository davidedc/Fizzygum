# Regularity principles — separate the fused axes; the name encodes the role

The house law, stated once. Fizzygum's recurring de-byzantination move is always the same
two-step, and new code is expected to follow it from the start:

1. **Separate the fused axes.** When one object, method, or name is serving two orthogonal
   concerns at once (what a thing *is* vs how it *draws*; which *plane* a coordinate lives in;
   which *phase* of a mutation a hook runs in), split them — don't special-case the fusion
   deeper in.
2. **The name encodes the role.** After the split, a reader must be able to tell from the
   symbol name alone which axis it serves — no call-site archaeology, no "check the class to
   know what this returns."

## Where this already holds (the standing embodiments)

- **Geometry — the two-vocabulary law** ([`transforms.md`](transforms.md)). The layout-box
  family (`width`/`height`/`bounds`/`center`/…) is plane-local and integer; the `screen*`
  family (`screenBounds()`/`localPointToScreen()`/…) is derived, post-transform, possibly
  fractional. Every name containing `screen` reads through the affine islands; every name
  without it stays in the widget's own plane. Layout/content code uses only the first
  vocabulary; hit-test/damage/paint the second.
- **Method tiers** ([`layering-naming-convention.md`](layering-naming-convention.md)). Public
  `name` (self-settling entry point) / `_name` (orchestrator, runs inside an enclosing settle)
  / `__name` (leaf commit, notifies nobody). The prefix *is* the settle/layering contract, and
  the static gates enforce that callers respect it.
- **The notification grid** ([`layout.md`](layout.md)). Structural events are named on a
  `(event × perspective × phase)` grid — `_beforeChildDropped`, `_reactToBeingAdded`, … — so
  the name spells out which event, seen from whose side, at which phase. Callbacks are
  settle-neutral; the dispatcher owns the one settle.
- **`*Appearance`.** What a widget *is* (behaviour, geometry, children) is separate from how
  it *draws*: painting lives in pluggable `*Appearance` objects. A skin swap never changes
  identity — a window flips `BoxyAppearance`/`RectangularAppearance` on (un)nesting without
  changing class.

## The frame model — content vs chrome

The same law applies to content vs chrome (the frame model, see
[`../plans/onion-widget-composition-plan.md`](../plans/onion-widget-composition-plan.md)). The
vocabulary below is the convention for all new code:

- **`Simple*Wdgt` — naked capability.** Data plus a self-mutation API, no chrome; a payload.
- **Plain `*Wdgt` — manipulable citizen.** A first-class thing you can directly edit, move,
  resize, remove. Plain means *citizen*, not *framed*: a self-affording citizen is naked
  (text), one that isn't self-affording is framed (image).
- **`FrameWdgt` — the manipulation chrome.** Whether a content type is framed at all is
  **intrinsic to the type** (settled once, holds everywhere it sits); how an existing frame is
  **skinned** (window vs card) is **contextual**, derived from parentage.

## How to apply it

When introducing a class, method, or field, ask which axis it serves; if the honest answer is
"two", split it first. When touching code where the fusion already exists, prefer the
separation over another special case — and when a rename would make the role legible, the
rename is part of the fix, not churn (recapture/serialization fallout is accepted; there are
no serialization compat obligations).

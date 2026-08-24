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
[`../archive/onion-widget-composition-plan.md`](../archive/onion-widget-composition-plan.md)). The
vocabulary below is the convention for all new code:

- **`Simple*Wdgt` — naked capability.** Data plus a self-mutation API, no chrome; a payload.
- **Plain `*Wdgt` — manipulable citizen.** A first-class thing you can directly edit, move,
  resize, remove. Plain means *citizen*, not *framed*: a self-affording citizen is naked
  (text), one that isn't self-affording is framed (image).
- **`FrameWdgt` — the one manipulation chrome.** Whether a content type is framed at all is
  **intrinsic to the type** (settled once, holds everywhere it sits). Everything else about a
  frame is a separate axis, never fused into a class or a flag:
  - `lifetime: 'transient' | 'persistent'` (`setLifetime`) is the one runtime **state**. Pin —
    a tap on the title, or simply grabbing a transient frame, which pins it at the grab rather
    than at the drop ("you moved it, it stays") — is the sole user-facing verb that sets it;
    there is no reverse gesture.
  - Parentage (on the world vs nested in another container) is **context**.
  - Crossing lifetime with parentage gives exactly three manifestations — never a stored flag,
    never a subclass: **menu** (transient, always a world child), **window** (persistent on
    the world), **card** (persistent, nested). Skin, bar roster, shadow, and colloquial name
    are all **derived** from the pair, re-derived at every (re)parenting and every lifetime
    change, never read back from a field.
  - The bar roster follows the same derivation: transient wears its title alone (tap pins);
    a free-floating persistent frame wears close + collapse + title + a pencil (iff its
    payload affords editing); one whose host owns its membership drops close, since you leave
    by dragging out, not by a button; a docked band goes further and keeps only collapse +
    title, because editing what a band holds is not a band's gesture. Close button and resize
    handle show **iff `isFreeFloating()`**; right-click → close stays the universal fallback
    everywhere, and closes the nested frame **alone** — a frame's own content redirects a
    close to its frame, but a frame reached that way does not redirect again, so the host
    reverts to empty rather than leaving with its content.
  - **Docking is a placement, not a rebuild**: a docked frame is a card under a host-owned
    `EdgeDockLayoutSpec` (`side` / `thickness` / `engaged`) — the same widget that sits in the
    slot floats free the moment it is dragged out, because leaving the slot is exactly
    dropping the spec. The payload receives the spec's `thickness` exactly (its own declared
    `dockThickness` if it has one); the band contributes only its own margin on top. A
    collapsed frame **is** its bar, and the whole bar — not just the collapse control — taps
    to expand it.
  - `MenuWdgt` / `PromptWdgt` are framed citizens (`extends FrameWdgt`, born transient): a
    menu or a prompt is a frame around a rows payload, not a parallel hierarchy alongside it.

## How to apply it

When introducing a class, method, or field, ask which axis it serves; if the honest answer is
"two", split it first. When touching code where the fusion already exists, prefer the
separation over another special case — and when a rename would make the role legible, the
rename is part of the fix, not churn (recapture/serialization fallout is accepted; there are
no serialization compat obligations).

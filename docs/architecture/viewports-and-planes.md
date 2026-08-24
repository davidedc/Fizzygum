# Viewports and planes — the scrolling-container architecture

Present-tense reference for the container family around `ViewportWdgt` / `PanelWdgt` /
`ScrolledPaneWdgt`. As-built by the scroll-frame role arc
(`docs/archive/scroll-frame-role-architecture-plan.md`, 2026-08-19) and the paint-time
scroll-translation arc (`docs/archive/paint-time-scroll-translation-plan.md` — the stored-offset
model); read those for the rationale trails, the falsified alternatives, and the member-audit
tables.

## The three roles

A scrolling container decomposes into three responsibilities, each with an honest home:

1. **The viewport** — `ViewportWdgt extends Widget` (NOT a panel: its children are chrome, not
   content). An invisible-in-effect composite: its color/alpha MIMIC the plane's, so its own
   painted rect always lies under the plane, indistinguishable (only the pop-up pair pins a
   true `alpha 0`); the `RectangularAppearance` is there for hit-testing parity. It wears
   `ClippingAtRectangularBoundsMixin` directly and owns three pieces of chrome: the contents
   panel and two `SliderWdgt` bars. `add` redirects any non-chrome child into the contents
   (chrome self-identifies via `attachesToViewportDirectly?()`). Scrolling never moves the
   plane: the offset is STORED TRUTH — two integer scalars `scrollOffsetX/Y`, frame-relative
   (the visible window's plane rect is `contents.position() + offset .. + my extent`) —
   applied as a paint-time translation around the contents recursion
   (`_scrollTranslation`; dormant, same-object/stock-path, at zero) and carried identically
   by the screen↔plane walks for input, hit-testing, damage and clipping. Every offset write
   goes through the one funnel `_writeScrollOffset` (clamped by the movement cores
   `scrollX`/`scrollY`, which refuse under `'never'`; the offset is MAPPING state, so the
   funnel breaks the `geometryVersion`-keyed caches exactly as a bounds write does), the
   getters read the fields, the bars are wired through the public pin vocabulary, and every
   scroll path announces at `_reLayoutScrollbars`. The caret follow (`scrollCaretIntoView`,
   refusing `'never'` at its own gate) writes offsets directly and deliberately UN-clamped:
   the arrange's window merge then grows the frame and the tail clamp normalizes, so the
   follow's margin overshoot sticks — the one licensed bypass of the cores' clamp.
2. **The plane** — the panel the viewport clips and scrolls, the coordinate surface content
   actually lives on. Plane-ness is a ROLE, not a class: the default `ScrolledPaneWdgt`, a
   `FolderPanelWdgt`, a `ToolPanelWdgt` or a vertical stack all play it. Every topology
   question is therefore a parent-based query, never a class test:
   - `ViewportWdgt.isMyContentsPanel(aWdgt)` — the one place the composite's shape is stated
     (the plane-side twin of `isMyScrollBar`); consumed by
     `PanelWdgt._amITheContentsPanelOfAViewport` and `Widget._amIDirectlyInsideViewport`.
   - `contentsPanelHoldsLooseContent()` — do the plane's direct children live there as loose
     scrollable content (drag-scroll-vs-detach, caret follow, the soft-wrap menu row,
     container re-fit climbs)? `ListWdgt` answers false: its pane holds rows machinery.
   - `hidesContainedWidgetFromHierarchyMenu(aWdgt)` — internal structure stays out of the
     hierarchy (disambiguation) menu; `FolderWindowWdgt` declares the same for its viewport.
   `ScrolledPaneWdgt` carries what is true of the default plane by construction: it never
   notices transparent clicks, relays membership changes to the viewport's HOLDER
   (`_reactToChild*InViewport` — the bin is the one implementor), forwards an empty-area
   click to a lone editable text child, and owns the FIT_BOX_TO_TEXT re-wrap
   (`_reWrapTextChildrenTo`). The color/alpha up-relays that keep the viewport's mimic true
   are NOT here — every panel-family plane relays, so they live on `PanelWdgt` (see
   Boundaries).
3. **`PanelWdgt`** — purely the SURFACE class: a clipping, drop-accepting, free-placement
   editing surface (the desktop family, the shelf, transform islands, the spreadsheet cells
   plane). It has no scroll personality of its own: no back-pointer, no stored role — where
   plane-ness matters (the detach/grab-to-parent policy, the up-relays, the measure) it asks
   the parent per query (`_amITheContentsPanelOfAViewport`), inert under any non-viewport
   parent.

## Scroll policy — behavior is POLICY, never structure

`ViewportWdgt.scrollPolicy` is `'auto'` (default: scroll iff content overflows — bars are the
visible CONSEQUENCE of overflow, and a fitting viewport is already behaviorally a plain panel)
or `'never'` (a cropping panel: the movement cores refuse, the wheel escalates, gestures fall
through, bars never show). `setScrollPolicy` flips a LIVE widget with no tree change;
`toggleScrollPolicyFromMenu` exposes it on the generic viewport's menu only
(`offersScrollPolicyToggle` — the dedicated subclasses design their scrolling in and opt out
with stated reasons). The plane is ALWAYS present: a conditional/lazily-materialized frame is
a threshold somebody must cross mid-life, litigated and rejected in `PopUpRowsViewportWdgt`'s
own class comment — a menu/prompt frame's rows viewport is ORDINARY `FrameWdgt` content
(`MenuWdgt`/`PromptWdgt extends FrameWdgt` directly; the viewport IS `@contents`, no separate
pop-up class in between), and it keeps its rows in a viewport unconditionally for the same
reason, whatever the frame's `lifetime`. Its pure measure (`preferredExtentForWidth`) is the
rows' hug capped at the world MINUS the frame's own chrome, in BOTH lifetimes — never the bare
world extent, or the frame (viewport + bar) would overflow it by exactly that chrome and
`_assertFitsInTheWorld` would fire. A row added or removed mid-life re-fits through the
viewport's own `_reLayOutAfterContainedPanelChange` override, not the frame's standard
child-removed path (which would leave the frame latched at its old first-placement width) — and
that absorb fires only because the pop-up climb (`enclosingFrame`) STOPS at the frame
instead of walking past it to the world. Test: `SystemTest_macroScrollPolicyNeverFlip`.

## The scrolled-content contract

The viewport's arrange reads DECLARATIONS off its plane instead of testing classes
(`_positionAndResizeChildren` / `_applyExtent`):

- `viewportConstrainsMyWidth()` — a width-constraining stack tracks the viewport; a
  free-width stack owns its width (the point of the horizontal bar). The menu rows panel
  decouples the two facts: its INTERIOR width-distribution stays on
  (`constrainContentWidth` true — row equalization rides it) while this viewport-facing
  answer is false — its width is the hug.
- `arrangesOwnScrolledChildren()` — the viewport delegates the interior arrange (stacks);
  it owns the plane's FRAME either way.
- `scrolledContentMeasure(widthHint)` — the §4.1 pure measure: `PanelWdgt` measures its
  children at the viewport's hint, a stack at its own width; a folder/toolbar plane is never
  content-sizing, so the viewport reads applied bounds back (`isContentSizing`).
- `managesOwnScrollPinning()` — the reset-scroll-on-resize POLICY: a real resize of a
  wrapping viewport zeroes the offset (re-wrapped text re-reads from the top) unless the
  plane declares it keeps its scroll across resizes (the wrapping stack — its scroll
  position belongs to the arrange's clamp). Under the offset model this is purely policy:
  nobody writes a plane's position on a scroll any more.
- `scrolledContentMeasureIsMyFrame()` — a plane whose measure is its WHOLE frame (a tight
  both-axes hug: `MenuRowsPanelWdgt` — the untitled plain rows stack a menu/prompt frame's
  own chrome now owns in its place, no title, no corner radius, no header child of its
  own — as a pop-up's rows plane) gets the measure committed VERBATIM — the content-sizing
  commit's window-width floor and grow-to-fill are skipped, because those adjustments suit
  a `tight: false` plane and against a tight hug they manufacture a two-writer fight in any
  state where the viewport is transiently larger than the hug (measured: menu-compose and
  duplication livelocks, the menu-sandwich dissolution's Phase 0).

For the boolean queries capability ABSENCE is the panel default — there are no
base-class stubs; the measure alone has a real base implementation
(`PanelWdgt.scrolledContentMeasure`), which the stack overrides. The contract's core split
is frame OWNERSHIP — and its precise law is AGREEMENT, not exclusivity. The viewport
commits its plane's frame at arrange time, and a stack plane's own arrange also self-writes
(the base stack hugs its height; a menu's rows panel hugs both axes), so two writers exist
for every stack-under-viewport: what keeps that sound is that at the fixpoint they write
byte-the-same box — the §4.1 measures answer what the arrange will commit (mirrored
arithmetic, or saturation at the same window bound for a `tight: false` plane under
grow-to-fill), and the commit's `unless equals` guard then skips. A self-writer whose box the committer's
arithmetic does NOT reproduce oscillates forever (`RECALC_NONCONVERGENCE`) — the menu rows
panel was exactly that (the base children-union measure misses its bottom border, and the
window-floor/grow-to-fill adjustments fight its tight hug; the BACKLOG's §7.2 record holds
the falsification history), until `scrolledContentMeasureIsMyFrame` + its full-self-box
`scrolledContentMeasure` made the committer's box identical to the hug in every state —
which is what let the pop-up's rows panel become its viewport's DIRECT contents (the
menu-sandwich dissolution; `PopUpRowsPaneWdgt` is deleted). A free-width stack is fine as
direct contents with no such declaration: it owns its width PASSIVELY (the declaration
turns the normalization off), and its `tight: false` height AGREES with grow-to-fill by
construction. ⚠ `ListWdgt` keeps the interposed-pane shape deliberately: its design sizes
the rows panel PAST the hug (anti-vacant-space, `ListWdgt._applyExtent`), so the panel's
unconditional hug self-write and the list's committed frame structurally disagree — there
the pane IS the second surface that keeps the writers apart.

## Naming

The construct family is role-named: `ViewportWdgt`, `ScrolledPaneWdgt`,
`PopUpRowsViewportWdgt`, `VerticalStackViewportWdgt`, `TextAreaWdgt`,
`DocumentViewportWdgt`, and the already-role-named `ListWdgt`/`ToolbarWdgt`. "Scroll"
survives only where it names actual scrolling (`scrollX`, the scroll pins,
`_reLayoutScrollbars`, `isMyScrollBar`). ⛔ "Frame" belongs to other constructs (the window
`FrameWdgt`, the island `TransformFrameWdgt`) and never names this family. Colloquials: a
generic viewport is "viewport"; composites take their contents' name
(`viewportColloquialName` — "folder", "toolbar").

## Boundaries and horizons

- Scrolling = a stored offset applied at paint time (UIScrollView's `bounds.origin` model);
  the plane is pinned and `_applyMoveBy` moves whole panels/windows, never a scroll step.
  The `screenPointToMyPlane`/`localPointToScreen`/`mapRectToScreen`/`screenBounds` walks are
  TWO-ARM — an island step (affine) and a translation step (scroll) share one climb, each
  ancestor answering per child edge via `scrollTranslationOfChild?(child)` — so a plane's
  residents keep integer plane-local `@bounds` while their screen positions are derived, the
  same two-vocabulary law the islands introduced. ⚠ One rule this imposes on INPUT handlers:
  `escalateEvent` forwards its args verbatim, so a `pos` escalated across a plane boundary
  is still plane-local to the SENDER — a pos-consuming handler on a plane's ancestor must
  re-derive (`@screenPointToMyPlane world.hand.position()`, as `ViewportWdgt.mouseDownLeft`
  does), never trust the parameter. The remaining horizon — lifting the offset + paint
  interception from `ViewportWdgt` to the clipping-mixin level, making scrollability a
  property of every panel — is designed but deliberately unlifted until a second user
  exists (the plan's owner-gated Phase 4).
- The color/alpha up-relay serves EVERY plane: the pair lives on `PanelWdgt` (parent-soaked,
  a no-op under any non-viewport parent), and the stack — a `Widget`, not a panel — declares
  its own; only `ViewportWdgt` implements the receiving hooks.
- Viewport-anchored vs plane-anchored children is answered STRUCTURALLY: a child of the
  viewport is fixed chrome, a child of the plane scrolls.

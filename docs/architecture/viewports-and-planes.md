# Viewports and planes — the scrolling-container architecture

Present-tense reference for the container family around `ViewportWdgt` / `PanelWdgt` /
`ScrolledPaneWdgt`. As-built by the scroll-frame role arc
(`docs/archive/scroll-frame-role-architecture-plan.md`, 2026-08-19); read that plan for the
rationale trail, the falsified alternatives, and the member-audit tables.

## The three roles

A scrolling container decomposes into three responsibilities, each with an honest home:

1. **The viewport** — `ViewportWdgt extends Widget` (NOT a panel: its children are chrome, not
   content). An invisible composite (`alpha 0`, never paints itself; a `RectangularAppearance`
   for hit-testing only) wearing `ClippingAtRectangularBoundsMixin` directly and owning three
   pieces of chrome: the contents panel and two `SliderWdgt` bars. `add` redirects any
   non-chrome child into the contents (chrome self-identifies via
   `attachesToViewportDirectly?()`). Scrolling physically MOVES the contents panel (absolute
   coordinates, the Morphic inheritance); the scroll offset is derived
   (`getScrollX/getScrollY`), the bars are wired through the public pin vocabulary, and every
   scroll path funnels through the `scrollX`/`scrollY` movement cores and announces at
   `_reLayoutScrollbars`.
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
   notices transparent clicks, keeps the viewport's mimic paint values true via the
   `_reactToChildColorChanged`/`_reactToChildAlphaChanged` up-relays, relays membership
   changes to the viewport's HOLDER (`_reactToChild*InViewport` — the bin is the one
   implementor), forwards an empty-area click to a lone editable text child, and owns the
   FIT_BOX_TO_TEXT re-wrap (`_reWrapTextChildrenTo`).
3. **`PanelWdgt`** — purely the SURFACE class: a clipping, drop-accepting, free-placement
   editing surface (the desktop family, the shelf, transform islands, the spreadsheet cells
   plane). It has no scroll personality: no back-pointer, no plane-conditional branches.

## Scroll policy — behavior is POLICY, never structure

`ViewportWdgt.scrollPolicy` is `'auto'` (default: scroll iff content overflows — bars are the
visible CONSEQUENCE of overflow, and a fitting viewport is already behaviorally a plain panel)
or `'never'` (a cropping panel: the movement cores refuse, the wheel escalates, gestures fall
through, bars never show). `setScrollPolicy` flips a LIVE widget with no tree change;
`toggleScrollPolicyFromMenu` exposes it on the generic viewport's menu only
(`offersScrollPolicyToggle` — the dedicated subclasses design their scrolling in and opt out
with stated reasons). The plane is ALWAYS present: a conditional/lazily-materialized frame is
a threshold somebody must cross mid-life, litigated and rejected in
`PopUpWdgt._buildRowsViewportNoSettle`'s comment — pop-ups keep their rows in a viewport
unconditionally for the same reason. Test: `SystemTest_macroScrollPolicyNeverFlip`.

## The scrolled-content contract

The viewport's arrange reads DECLARATIONS off its plane instead of testing classes
(`_positionAndResizeChildren` / `_applyExtent`):

- `viewportConstrainsMyWidth()` — a width-constraining stack tracks the viewport; a
  free-width stack owns its width (the point of the horizontal bar).
- `arrangesOwnScrolledChildren()` — the viewport delegates the interior arrange (stacks);
  it owns the plane's FRAME either way.
- `scrolledContentMeasure(widthHint)` — the §4.1 pure measure: `PanelWdgt` measures its
  children at the viewport's hint, a stack at its own width; a folder/toolbar plane is never
  content-sizing, so the viewport reads applied bounds back (`isContentSizing`).
- `managesOwnScrollPinning()` — a wrapping stack's position belongs to the arrange's clamp,
  so the reset-scroll-on-resize pin skips it.

Capability ABSENCE is the panel default — there are no base-class stubs. A width-OWNING
content (a menu's rows panel hugging its widest row) must never be the width-constrained
contents of anything: that shape does not terminate (`RECALC_NONCONVERGENCE`), which is why a
pop-up interposes `PopUpRowsPaneWdgt` between its rows panel and its `PopUpRowsViewportWdgt`.

## Naming

The construct family is role-named: `ViewportWdgt`, `ScrolledPaneWdgt`,
`PopUpRowsViewportWdgt`, `SimpleVerticalStackViewportWdgt`, `SimpleTextViewportWdgt`,
`SimpleDocumentViewportWdgt`, and the already-role-named `ListWdgt`/`ToolbarWdgt`. "Scroll"
survives only where it names actual scrolling (`scrollX`, the scroll pins,
`_reLayoutScrollbars`, `isMyScrollBar`). ⛔ "Frame" is the window vocabulary (`FrameWdgt`) and
never names this family. Colloquials: a generic viewport is "viewport"; composites take their
contents' name (`viewportColloquialName` — "folder", "toolbar").

## Boundaries and horizons

- Scrolling = physically moving the plane, because coordinates are absolute. Scroll offset as
  a paint-time translation (the transform-island machinery; UIScrollView's `bounds.origin`
  model) would make scrollability a property of every panel and dissolve the middle node —
  a separate large arc; see `docs/BACKLOG.md`.
- The color/alpha up-relay serves EVERY plane: the pair lives on `PanelWdgt` (parent-soaked,
  a no-op under any non-viewport parent), and the stack — a `Widget`, not a panel — declares
  its own; only `ViewportWdgt` implements the receiving hooks.
- Viewport-anchored vs plane-anchored children is answered STRUCTURALLY: a child of the
  viewport is fixed chrome, a child of the plane scrolls.

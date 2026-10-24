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
   `ScrolledPaneWdgt` carries what is true of the default plane by construction: it wears its
   viewport's LOOK (holding no colour of its own, it paints in the viewport's pane fill and
   border — `ViewportWdgt._paneFill` / `_surfaceStroke` — so the box the composite presents
   wears ONE look: a class's own pane fill, `_defaultPaneFill`, or the roles a builder dressed
   the viewport in by NAME, `wearPaneRoles`, which travel with the viewport wherever it is
   taken), never notices transparent clicks, relays membership changes to the viewport's HOLDER
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
`_assertFitsInTheWorld` would fire. A row added, removed or RELABELLED mid-life re-fits through
the viewport's own `_reLayOutAfterContainedPanelChange` override, not the frame's standard
child-removed path (which would leave the frame latched at its old first-placement width) — and
that absorb fires only because the pop-up climb (`enclosingFrame`) STOPS at the frame
instead of walking past it to the world. A relabel reaches it through the rows panel
(`LabelButtonWdgt._setLabelNoSettle` rebuilds the label at once, then tells its container,
`CommandPanelWdgt._reactToChildRelabelled`); in a LIST the rows panel stands on the list's scrolled
pane, which absorbs nothing, and the relabel's own climbing invalidate re-lays the panel. Tests:
`SystemTest_macroScrollPolicyNeverFlip`, `SystemTest_macroRelabelledLabelButtonsStayPlaced`.

## Scroll indicators — one presentation, over the same two bars

The viewport's two `SliderWdgt` bars (`hBar`/`vBar`) stay the wiring endpoint — `trackTarget`,
`isWiredTo`, the reverse-edge announcement, serialization — and layer an INDICATOR presentation
on top of it. Visibility is DERIVED from overflow, never asked of a bar itself:
`ViewportWdgt.isScrollableNow()` (overflow ∧ `scrollPolicy` isnt `'never'`) is the one
scrollability question every drag-scroll consumer asks — `grabsToParentWhenDragged`'s
foreground- and background-drag-scroll branches (`Widget.coffee`/`PanelWdgt.coffee`) among
them; `anyScrollBarShowing()`, the visibility-as-scrollability proxy, is retired. The derivation is a pure function of layout
state, nothing time-driven on any path: while content overflows the bar shows THIN
(`scrollIndicatorThickness`, thumb-only painting, no track, `scrollIndicatorEdgeInset` in from the
viewport's edge so no border covers it) and passes the pointer through to
the content under it — `SliderWdgt.catchesPointerAt` answers false whenever
`indicatorIsIntangible()` (thin or hidden; an indicator is not a target); resting the pointer
within `scrollBarsThickness` of the viewport's scroll edge (the hover pass —
`ViewportWdgt.hoverMoved`/`hoverExited` → `_updatePointerInScrollBand`, since the viewport is
always in the hand's mouse-over ancestry for content under it) fattens both bars to FAT — full
painting at `scrollBarsThickness`, full interactivity (thumb-drag, track-jump); leaving the band,
or the content no longer overflowing, reverts to thin or hidden. A bar also stays hidden, however
much the content overflows, when its frame has no room for its thumb
(`ViewportWdgt._barFrameHasRoomForThumb`: the frame must be at least as long as the thumb a press
meets is wide). Under a resizer, a viewport shorter than the corner reserve has a frame whose
length is not even positive, and the bar would be a 1px sliver no pointer can work. The pane
still scrolls, since scrollability is asked of overflow.

The CORNER RESERVE is what occupies the bottom-right corner, and nothing more
(`ViewportWdgt._cornerReserveFor`, read by `_barFrameAt`):
- a resizer over the corner takes the room it names (`HandleWdgt.cornerFootprint`), never less
  than a bar: a frame's grip its inset plus its side (`FrameGripWdgt.footprint`), a naked
  inspector's handle its side (`handleSize`). The climb that finds it (`_resizerOverMyCorner`)
  answers the resizer itself;
- failing that, the other bar, where it crosses, takes `scrollBarsThickness`;
- with neither, the bar runs its side's full length.

Each answer comes from STRUCTURE, because the passes that read it are still laying out geometry
and visibility:
- **The other bar** is read from the overflow its showing derives from, without its own
  room-for-thumb check, so neither bar's length waits on whether the other one shows.
- **The resizer** is found by climbing the corner chain. A container that runs a child out to its
  own bottom-right corner names it (`bottomRightCornerReachedBy`): a frame names its payload
  and its bottom/right bands, a read-only inspector its code pane (an inspector that ends in its
  footer band names none), a patch node its bottom text box. The
  first container on the climb whose resizer would show answers (`HandleWdgt.wouldShow`, what
  showing derives from, never `isVisible`).
- **A container that names nobody ends the climb**, and a viewport names nobody: its contents
  scroll under its corner.
- **When the corner chain changes** — a resizer comes or goes (`HandleWdgt.updateVisibility`), or a
  docked band is re-sided into or out of the slots its host names (`FrameWdgt._reSideMyDockNoSettle`)
  — `Widget.noteCornerChainChanged` tells the viewports down that corner chain
  (`noteCornerResizerChanged`), and each re-lays what it keeps clear of the corner: its bars, and
  through its arrange the contents that lay pieces out to its far edges (a toolbar's strip keeps
  its last slot clear of the resizer, `ViewportWdgt.cornerResizerFootprint`). Docking and undocking
  change the band's spec, which shows or hides its own grip, so they reach the same walk.

A container that runs a viewport into its corner WITHOUT naming it leaves that viewport's bar
running under the resizer, so a new container of that shape names its corner child.
No activity stamps, no clock,
no stepping registration: a capture taken a second after a scroll shows the same pixels as one
taken at rest, so the indicator carries no determinism question.

The presentation itself lives on `SliderWdgt.indicatorMode` (`'thin' | 'fat' | undefined` —
`undefined` means "not an indicator", the plain-slider look) as a `@serializationTransients`
field: a restored world carries no mode, and the owning viewport re-derives thin-or-hidden from
overflow at its first arrange, exactly as a freshly built one does. Ownership is stated, not
inferred from the field: `@hBar`/`@vBar` survive a bar being picked up off the viewport (they
are properties, not children, so `isWiredTo?` still finds the wiring wherever the bar lands),
but an indicator presentation is something a VIEWPORT IMPOSES ON THE BAR IT HOLDS — a bar
outside a viewport's children is a plain slider somebody dropped elsewhere, and its look and
thickness are its own business (`_barIsMineToPresent`: `bar.parent is @`). The moment a bar
lands anywhere else it reverts to a plain slider (`SliderWdgt._reactToBeingAdded`:
`showAsScrollIndicator undefined unless whereTo.isMyScrollBar? @`) — a thin, pointer-through
look must never survive being picked up, or the bar becomes a widget on the desktop nothing can
click and no scroll band left to hover it back.

The mode is also an input to the thumb's GEOMETRY: `SliderWdgt.thumbInsetInTrack` is 0 for a thin
indicator (the thumb fills the bar) and 2 otherwise, read by `SliderButtonWdgt._reLayoutSelf`. So
`showAsScrollIndicator` re-lays the thumb whenever a flip changes that inset — at the one door the
mode changes through, because both its callers lay the bar out for the OLD look first
(`_reLayoutScrollbars` sizes and re-lays each bar before `_refreshScrollIndicators` decides the
look; `_reactToBeingAdded` re-lays before reverting to plain). Nothing else may be trusted to repair
a thumb sized for the other look: the reverse edge's re-read does it only for a bar that has one,
and only at the next drain.

A press never meets the thin look. The thin thumb is intangible, and the pointer's ARRIVAL fattens
the bar before any press is dispatched — a mouse's approach crosses the band first, and a finger's
own down runs its position head (the hover move) ahead of the press (`input-and-gestures.md`
§"Touch hover dissolution") — so what a press can take is the FAT thumb, which is wider and placed
differently. `ViewportWdgt.buttonScreenBoxOnArrival` answers where that is without fattening
anything, from the same two derivations the arrange commits: `_barFrameAt` (where the viewport
places a bar of a given thickness and edge inset — both looks come from it: the thin one 2 px in, the
fat one flush, so every aim derived from the fat frame is unchanged by the inset) and
`SliderButtonWdgt.boxInSliderFrame` (the thumb's box inside a frame of a given extent and track
inset, `SliderWdgt.trackThumbInset` for every pressable look). Its client is the macro toolkit's
`sliderButtonPressPoint`: a press aimed at the thin thumb's centre can fall on the track beside the
fat thumb, where it pages the bar and drags a thumb teleported under the pointer instead. Its
sibling `barScreenFrameOnArrival` answers the frame that box lies in. The fat thumb can be LONGER
than the thin one, since a thumb is never shorter than it is wide (10px fat where 4px show), so a
drag that carries the thumb a fraction of its travel measures that travel from these two, not from
the bar as drawn. Measured from the thin look, it overshoots by a share that grows with the
distance dragged.

The indicator's COLOURS are the theme's and follow its presentation, read as the bar paints. A bar
holds no track colour of its own (unless its viewport's builder names one, `sliderColor`): while
presented, its track wears `scrollIndicatorTrack` (`SliderWdgt._surfaceFill`), which the fat look shows
faintly (`scrollIndicatorTrackAlpha`) and the thin look not at all. The thumb's look is a function of
the presentation and its state, `SliderButtonWdgt._fillForMyState` and `_strokeForMyState`:
- thin: `scrollIndicatorThumb` (the `scrollbar` token) in every state, no border;
- fat: that colour at rest, `scrollIndicatorThumbHighlight` under a pointer, `scrollIndicatorThumbPress`
  while pressed, no border;
- no presentation: a content slider's look, the button's (`sliderThumbFill` inside a 1 px
  `sliderThumbStroke`, `sliderThumbHoverFill` hovered, `sliderThumbPressFill` inside
  `sliderThumbPressStroke` pressed; a fill override the thumb holds for a state wins), over the
  `sliderTrack` groove.

So a bar picked up off its viewport is a plain slider: the opaque groove and the button-look thumb.

## Drag-to-scroll — the plane's other scroll gesture

Float-dragging a viewport's contents scrolls it too — the gesture beside the bars above
(opt-in `isScrollingByfloatDragging`). A stroke has ONE drag-scroll step, on the pane that takes
the stroke (`ViewportWdgt.takeStrokeScrollFrom`): while the hand's button is down and nothing is
being float-dragged, the step samples the hand's position each frame (mapped into that pane's own
plane) and moves the offset by the delta through `scrollX`/`scrollY` — the same funnel the bars
and the wheel write through. A pane that takes no scroll gesture — `scrollPolicy 'never'`, or one
that does not drag-scroll — is TRANSPARENT to the press, as it is to the wheel: `pressBegan` passes
the press on, so a drag over a cropping pane nested in a scrolling one reaches the scrolling one. Release seeds a
POST-RELEASE MOMENTUM glide (friction 0.8, tracked in `world.wdgtsWithOngoingScrollMomentum`),
suppressed under the Automator's pacing control so screenshots stay event-determined.

The step's DETACH GATE (`_strokeWouldLiftWhatItPressed`) decides whether a press here means
"scroll the pane" or "pick the pressed thing up". On a `'mouse'`/`'pen'` stroke it holds steady
when `wdgtToGrab?.detachesWhenDragged()` — a float-draggable widget sits under the hand, probably
about to be lifted. An un-armed `'touch'` stroke widens the gate: it holds only when that widget
detaches AND `world.hand.strokeMeansMouseDrag()` — an un-armed finger scrolls over ANY content,
detachable or not, because a plain finger drag over a viewport's content always means scroll until the hand's
press-and-hold recognizer arms the stroke ([`input-and-gestures.md`](input-and-gestures.md)); once armed, the gate reads
exactly as the mouse's. The mouse reading is untouched.

A drag-scroll is NOT A CLICK, on any pointer: the stroke's scroll OWNER — the innermost pane the
press reaches with something to scroll (`claimsPlainDragsForScrolling`) — tells the hand at the
press (`notePressTakenForScrolling`, passing itself), and a stroke that then travels past `grabDragThreshold` releases
without dispatching `activated` — the content carried the pressed widget along with the pointer, so
the release lands back on it and would otherwise click (select, and fire) whatever was scrolled
(`ActivePointerWdgt._strokeOwesNoClick`, [`input-and-gestures.md`](input-and-gestures.md)).

THE DIRECTION LATCH — nested panes. One pane takes a stroke and takes all of it. A lone pane takes
the stroke at the press and scrolls from its first pixel. With panes NESTED, nothing scrolls until
the stroke first leaves the grab radius; at that DRAINED event the hand
(`_notePressTravelledPastDragThreshold`) asks the owner to latch (`latchStrokeScroll`) from the press
point and the crossing point — two points the event stream fixed, so which pane takes the stroke
never depends on which frame first saw the hand past the radius. The choice is
`ViewportWdgt.strokeScrollPaneFor`: by the stroke's DOMINANT axis, the innermost candidate that
scrolls along that axis and is not already at its clamp in the stroke's direction; else the
innermost that scrolls along that axis; else the owner. The latched pane catches up from the press
point and takes the rest of the stroke; travel past its clamp is DROPPED until the next stroke,
which latches anew — nothing hands on within a stroke. The hand keeps the pane as the stroke's
fact (`_strokeScrollPane`). It is the wheel's rule (a notch goes to the innermost `scrolledBy` that
can move, and passes outward only when that pane is already at its edge) applied per stroke, and
what WebKit, Chrome's touch scrolling and iOS do with nested scrollers. The macro toolkit's wheel
aim check asks the same two functions (`ActivePointerWdgt.wheelTakerAbove`,
`ViewportWdgt.strokeScrollPaneFor`), so a check cannot drift from the dispatch. Test:
`SystemTest_macroNestedPanesDragLatchesOnePane`.

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
  both-axes hug: `CommandPanelWdgt`'s `'column'` arrangement — the untitled plain rows stack a menu/prompt frame's
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
the pane IS the second surface that keeps the writers apart. (A MEMBER list's panel — the Object Inspector's —
does not hug: it takes the list's width, `ListWdgt._positionAndResizeChildren` / `CommandPanelWdgt._myArrangedWidth`.)

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
  is still plane-local to the SENDER — a pos-consuming GESTURE handler (`activated`,
  `doubleActivated`, the ones that still climb by escalation) on a plane's ancestor must
  re-derive (`@screenPointToMyPlane world.hand.position()`), never trust the parameter. The
  press facts are exempt by construction: the hand drives the press climb and its endings and
  maps the pointer into EACH receiver's plane (the press lifecycle,
  [`input-and-gestures.md`](input-and-gestures.md)). The remaining horizon — lifting the offset + paint
  interception from `ViewportWdgt` to the clipping-mixin level, making scrollability a
  property of every panel — is designed but deliberately unlifted until a second user
  exists (the plan's owner-gated Phase 4).
- The color/alpha up-relay serves EVERY plane: the pair lives on `PanelWdgt` (parent-soaked,
  a no-op under any non-viewport parent), and the stack — a `Widget`, not a panel — declares
  its own; only `ViewportWdgt` implements the receiving hooks.
- Viewport-anchored vs plane-anchored children is answered STRUCTURALLY: a child of the
  viewport is fixed chrome, a child of the plane scrolls.

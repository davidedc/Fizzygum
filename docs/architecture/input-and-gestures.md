# Input and gestures — the pointer pipeline and the touch grammar

Present-tense reference for how pointer input reaches the world, and for the one gesture grammar
that lets a mouse, a pen and a finger drive the same geometry. Read
[`viewports-and-planes.md`](viewports-and-planes.md) for the scrolling-container side of the
grammar (the scroll-drag step this doc's hand installs the arming for),
[`widget-authoring-guidelines.md`](widget-authoring-guidelines.md) §9 for what a widget author
consults, [`../specs/drag-embed-interaction-spec.md`](../specs/drag-embed-interaction-spec.md) §6
for the dwell-to-arm machine the hold recognizer below is built on, and
[`../../Fizzygum-tests/DETERMINISM.md`](../../Fizzygum-tests/DETERMINISM.md) for the event-time
doctrine this whole pipeline obeys.

## The event family and the two construction boundaries

`PointerInputEvent extends InputEvent` (`src/events-input/PointerInputEvent.coffee`) is the ONE
family for every pointer kind: a mouse, a pen and a finger all arrive as W3C Pointer Events, so the
kind rides each EVENT as `pointerType` (`'mouse' | 'pen' | 'touch'`) rather than being implied by
which listener set delivered it — a hybrid machine (a trackpad and a touchscreen on the same
laptop) gets each stroke right with no device-level switch anywhere. Four subclasses carry no
fields of their own, only a `processEvent` that dispatches to the matching hand method —
`PointerdownInputEvent` → `world.hand.processPointerDown`, and the `move`/`up`/`cancel` siblings
the same way. Every event carries `worldX`/`worldY` (`undefined` when the event states no place —
see the position-head note below), `pointerId`, `isPrimary`, `pressure`, `button`/`buttons`, and
the four modifier keys.

Two construction boundaries build these events, and nothing else does:

- **`@fromBrowserEvent(event, isSynthetic, time)`** — the BROWSER boundary. A browser pointer
  event states PAGE coordinates; this is the one place `world.getCanvasPosition()` runs the
  page→world conversion, rounding to whole pixels (a pointer position can be fractional — a
  finger, a scaled page — and the rest of the system has no use for a fractional input position).
  `pointerType` is read straight off the DOM event, so it is real hardware fact, never a guess.
- **`@synthetic(...)` / `@syntheticTouch(...)`** — the MACRO boundary (the `Fizzygum-tests`
  toolkit is the one caller). Everything a browser reports about the pointer DEVICE is a
  deterministic constant here: `synthetic` bakes `pointerType: 'mouse', pointerId: 1,
  isPrimary: true, pressure: 0`; `syntheticTouch` bakes `pointerType: 'touch'` and
  `pressure: 0.5`. ONE factory per KIND, not one factory taking a kind argument, because what
  differs between them is exactly the device constants each bakes — the argument list is
  identical, so a caller learns nothing new to synthesise the other kind. Both take
  `worldX`/`worldY` last: a down/up usually states no place at all (only a move does), so no
  caller ever passes a hole to reach a later argument.

Every constructed event lands on `world.inputEventsQueue`, and the queue drains by EVENT TIME, not
arrival order or wall clock: `WorldWdgt._playQueuedEvents` walks the queue and stops the moment it
meets an event whose `.time` is later than `WorldWdgt.dateOfCurrentCycleStart` — the rest waits for
a later cycle. While an event is being dispatched, `WorldWdgt.timeOfEventBeingProcessed` holds
*that* event's own `.time` (cleared to `undefined` at the tail of every cycle, so anything reading
it between cycles — a probe, page-side tooling — must not mistake the gap for a live value); this
is the ONE clock every deterministic recognizer in the hand reads. **This is the determinism law
the whole pipeline stands on: a recognizer decides on the EVENT's own time, never
`Date.now()`/`setTimeout`** — see `Fizzygum-tests/DETERMINISM.md`. A macro's non-scaled recognition
windows (`clickGuardWindowMs`, `dragFloorMs`, the hold's own margin) exist to keep a
compressed-speed replay crossing those same windows in real terms; none of them relax the law
itself.

## The hand's per-stroke model

`ActivePointerWdgt` — "the hand" — is the world's one pointer: hit-testing, grabs/drops,
multi-click recognition, the drag-embed dwell machine, pop-up dismissal, and the press-and-hold
recognizer below. Its entry points take the immutable event value directly:
`processPointerDown/Move/Up/Cancel(e)`. It records `@pointerType` off every down and every move —
**the branch key for the whole grammar, and it is per-STROKE, never a device mode**: a hybrid
machine mixes a trackpad, a pen and a finger in one session, and each stroke answers for itself. A
`'mouse'` or `'pen'` stroke takes exactly the paths it always has; only a `'touch'` stroke consults
anything below.

### The press-and-hold recognizer

Built to the drag-embed dwell machine's exact template (`drag-embed-interaction-spec.md` §6): the
decision is elapsed EVENT time from the press origin while the pointer stays within
`grabDragThreshold` (7 px — the dwell's own notion of "stationary", reused rather than duplicated)
of it, decided on `WorldWdgt.timeOfEventBeingProcessed`, never a wall-clock timer.
`_beginPressAndHoldRecognition` starts it at every `processPointerDown`, recording
`pressOriginPoint`/`pressOriginEventTime`; a `'mouse'`/`'pen'` stroke arms immediately and consults
no clock at all, so every path from here on is the path those strokes have always taken.

A `'touch'` press arms immediately too, in exactly one case: `_touchPressArmsAtOnce` walks the
pressed widget's ancestry and answers `true` the moment it finds a chrome surface
(`ownsDragsStartingOnMe?()`), or answers `true` if NOTHING in the ancestry would claim a plain
drag for scrolling (`claimsPlainDragsForScrolling?()`) — a hold is demanded only where a plain drag
would already mean a scroll. Otherwise the press must HOLD: `_advancePressAndHoldRecognition` runs
at every drained pointer event of a live press **and** at the per-cycle hover re-sync
(`WorldWdgt.doOneCycle` → `@hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges()`
→ `dispatchEventsFollowingMouseMove` → the recognizer's own tail) — the same seat the dwell
machine uses, so a moving finger and a motionless one are both advanced. The between-events check
reads `_holdDecisionTime`: at a drained event that IS the event's own time; between events it may
also consult `WorldWdgt.dateOfCurrentCycleStart`, but that consultation is SUPPRESSED whenever
`Automator.animationsPacingControl` is active and the Automator is not idle — the momentum glide's
own idiom (see `viewports-and-planes.md`) — so a replayed macro stroke stays purely
event-determined and its screenshots reproduce, while a real finger holding perfectly still off
the harness still gets its menu on time. Once elapsed time crosses `pressAndHoldMs` (500,
`PreferencesAndSettings.pressAndHoldMs`) the hold FIRES, at most once per stroke.

Two things silence it first: a press that has already become a float-drag (the dwell machine owns
that territory), and a booked non-float target that has already MOVED away from the press origin
(a slider or handle actually being dragged) — but NOT one that is merely booked and hasn't moved
yet, so a finger resting on a slider still gets its hold. And a move past `grabDragThreshold`
before the hold fires does NOT re-anchor the way the dwell's linger does: it commits the stroke as
a plain drag — a scroll — for the rest of its life, and if a hold menu was already standing, that
move dismisses it (the same dismissal sweep the press-down path itself runs,
`cleanupMenuWdgts alsoKillFreshMenus: true`).

### Arming and its two capabilities

The recognizer's one derived fact is `_pressArmedForMouseSemantics` — do this stroke's drags mean
what a mouse's would? — read everywhere as `strokeMeansMouseDrag()`
(`pointerType isnt 'touch' or _pressArmedForMouseSemantics`). It becomes true at the down for
`'mouse'`/`'pen'` and for a touch press on chrome, and at the hold's firing otherwise. Two
capability queries decide chrome and scroll-claiming, dispatched `?()` — nothing stubbed on
`Widget`, the capability-query idiom `widget-authoring-guidelines.md` §14 documents — and asked by
ANCESTRY, so a leaf of composed chrome (a bar's close button, a slider's thumb) answers through
its owner:

- **`ownsDragsStartingOnMe()`** — does a chrome surface own a press that starts on me? — answered
  `true` by `HandleWdgt`, `PaletteWdgt`, `FrameBarWdgt`, `StackElementsSizeAdjustingWdgt`, and
  `SliderWdgt` (whose thumb only answers while its indicator presentation is `'fat'` — a thin
  indicator is intangible and can't be pressed at all).
- **`claimsPlainDragsForScrolling()`** — would a plain drag here be claimed by a scroll surface? —
  answered by `ViewportWdgt`: `isScrollingByfloatDragging and isScrollableNow()`, the same three
  facts (takes drags at all, policy allows scrolling, overflow to move) its own scroll-drag step
  installs on.

### The three consumers of `strokeMeansMouseDrag()`

- **The float arms** (`ActivePointerWdgt.determineGrabs`) — a widget that `detachesWhenDragged()`
  (or a template) is picked up onto the hand only while the stroke means a mouse drag; an
  un-armed touch stroke falls through and the scroll surface underneath takes the gesture
  instead. The non-float arm (sliders, handles) is untouched — reaching it already means the
  press landed on chrome, which arms at the down.
- **`ViewportWdgt`'s scroll-drag step** — see [`viewports-and-planes.md`](viewports-and-planes.md).
- **The pressed-move `mouseMove` channel**, at both its dispatch sites: `determineGrabs`'
  `topWdgt.mouseMove` and the over-list `mouseMove` in `dispatchEventsFollowingMouseMove`. While a
  touch stroke is un-armed, neither site dispatches a pressed move — a finger sliding over text
  must not extend the selection, and one sliding over a paint canvas must not draw, while the
  surface beneath it scrolls instead. Hover (no-button) moves are untouched;
  `'mouse'`/`'pen'` always mean a mouse drag, so both sites read exactly as they did before the
  grammar existed.

### Hold-as-right-click, and what a hold's release owes

The hold fires by calling `ActivePointerWdgt.openContextMenuAtPointer` on the pressed widget — the
EXACT method `Widget.mouseClickRight` calls on a real right-click — so it is an alternate TRIGGER
for the right-click's own verb, not a parallel path: the titled menu, the dev-mode
disambiguation, and the world's own menu (`WorldWdgt.mouseDownRight` is a no-op; the climb reaches
the world's `buildContextMenu` the same way a raw right-click over empty desktop does) are all
inherited, not reimplemented. Every widget's context menu is already titled with its
class-derived name (`Widget.buildBaseWidgetClassContextMenu`), so the hold needs no title
mechanism of its own.

A hold-consumed stroke's release dispatches no click — the same shape a right press has always
had (a right press never fires `mouseClickLeft` either) — via `_strokeOwesNoClick()`, which is
also true for an un-armed touch stroke that left the hold radius (a plain drag, i.e. a scroll).
That second case is load-bearing, not cosmetic: a scroll-drag carries the pressed row WITH the
finger, so the release lands on the very widget the press landed on, and a plain `w ==
@mouseDownWdgt` test cannot tell a scroll from an ordinary click — without the carried-row fact,
every scroll swipe would end in a spurious click on whatever it scrolled past. A hold menu still
standing at release (the finger let go without moving) stays open as an ordinary transient menu;
the next outside tap dismisses it like any other.

### Touch hover dissolution and the pointer-absence state

A mouse or a pen rests where it stops; a finger does not rest anywhere between strokes — the
finger left the glass. At a touch stroke's up or cancel, `_dissolveHoverStateOfTouchStroke`
dispatches `mouseLeave`/`mouseLeavefloatDragging` to the whole `mouseOverList` and empties it,
then sets `@_pointerIsAbsent = true`. That flag is what makes the dissolution STICK: the
per-cycle hover re-sync would otherwise re-derive the over-list from wherever the hand happens to
stand a cycle later, re-entering whatever the finger last touched — tooltip and highlight
included. While `_pointerIsAbsent` is true, `dispatchEventsFollowingMouseMove` treats the
mouse-over set as empty: nothing is under a pointer that is not there. The next
`processPointerDown` of ANY kind clears the absence (a down states a position — the pointer is
back), and so does any hover-capable move (a real mouse/pen move). A `'mouse'`/`'pen'` stroke
never sets the flag, so their strokes keep today's persistent pointer-under state
byte-identically.

### Cancel semantics

`processPointerCancel` is its own method, not a flag on the up — an up means exactly what a
cancel does not: the browser confiscated the stroke (a system gesture, a palm rejection, the tab
going away), so nothing that means "the user chose this spot" may happen — no click, no menu
dismissal, no embed, no dock. A float-drag's payload still lands on the world where it visibly is
(it may be the user's only copy of something); a non-float drag is told it ended; the shared
press clear (`_forgetPressBookkeeping` → `_forgetPressAndHoldRecognition`) takes the recognizer's
state with it — a confiscated press states no intent, so it can neither arm nor open a menu,
though a menu that had ALREADY opened stays (the cancel is not a click outside it). Touch hover
dissolution runs on cancel exactly as it does on an ordinary up.

### The touch-stroke grab-threshold rules

`checkDraggingThreshold` (reached from `determineGrabs`) carries two touch-specific rules ahead
of the ordinary grab-threshold test: a zero-displacement move on a touch stroke NEVER grabs — a
finger holding perfectly still still emits a move to cross its hold window, and floating the
pressed widget on that move would end the gesture before the hold ever got to recognise it. And
the desktop's instant-grab carve-out (no threshold at all for a non-editable widget sitting
directly on the desktop) is MOUSE/PEN-ONLY: a touch stroke always takes the full
`grabDragThreshold` before it can grab, because the press-and-hold recognizer is *defined* as
staying inside that same radius — a trembling finger needs the full threshold to ever hold long
enough to open anything.

### The virtual keyboard, keyed on the starting tap

`WorldWdgt.edit` (the caret-creation seam) summons the hidden DOM input `_initVirtualKeyboard`
builds iff `@hand.pointerType is 'touch' and WorldWdgt.preferencesAndSettings.useVirtualKeyboard`
— the STARTING tap's kind, not a session-level device flag: an edit begun by a finger has no
physical keyboard behind it and needs the on-screen one; an edit begun by a mouse or a pen leaves
the canvas's own keyboard listeners to do the typing. A machine that mixes the two answers per
stroke, exactly like every other branch of this grammar. `useVirtualKeyboard` (default `true`) is
the opt-out for a touch machine that has a real keyboard anyway.

## See also

- [`viewports-and-planes.md`](viewports-and-planes.md) — the scroll-drag step's own side of the
  grammar (the widened detach gate, the at-edge escalation).
- [`widget-authoring-guidelines.md`](widget-authoring-guidelines.md) §9 — the two capability
  queries a widget author may declare or consult.
- [`../specs/drag-embed-interaction-spec.md`](../specs/drag-embed-interaction-spec.md) §6 — the
  dwell-to-arm machine the press-and-hold recognizer is built on.
- [`../../Fizzygum-tests/DETERMINISM.md`](../../Fizzygum-tests/DETERMINISM.md) — the event-time
  doctrine binding every recognizer above.
- `src/macros/CLAUDE.md` / `MACRO-PATTERNS.md` — how a macro synthesises a touch stroke, and how
  the finger run mode translates an existing mouse-flavoured macro into one.

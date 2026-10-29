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

### The widget-facing dispatch surface, named by TIER

The hand's five entry points turn each event into dispatches onto widgets, and the names say which
of two tiers a handler is on — the boundary is legible in the name SHAPE, so a widget author can
see at a glance whether a verb carries a certified meaning or a raw phase:

- **Facts — stroke-phase narration, no interpretation.** `pressBegan(pos)`, `pressMoved(pos,
  button)`, `pressEnded(pos, button, buttons, ctrl, shift, alt, meta)`, `pressCancelled()`,
  `hoverEntered()`,
  `hoverMoved(pos)`, `hoverExited()`, plus the in-place drag pair `nonFloatDragging` /
  `endOfNonFloatDrag`. A fact says what the pointer did and nothing about what it meant; a paint
  canvas, a slider, a text selection and a hover highlight all want the raw phase.
- **Gestures — the guarantee the hand CERTIFIES before dispatching.** `activated(pos, …)` means
  "this stroke, examined, meant an activation": multi-click recognition ran, a drag away
  suppressed it (`w == @mouseDownWdgt`), a hold or a drag-scroll suppressed it
  (`_strokeOwesNoClick()`). `doubleActivated(pos)` / `tripleActivated(pos)` are the folded
  multi-click; `contextMenuRequested(pos)` is the context gesture from either trigger;
  `scrolledBy(deltaX, deltaY, deltaZ, altKey, button, buttons)` is "a scroll step was asked of
  you". Buttons, toggles and menus consume gestures and never facts.

A gesture is named for what it certifies, never for the presumed use — `activated`, not `chosen`
or `buttonPressed`, because whether the consumer treats an activation as a choice is the
consumer's business. Nothing at this boundary carries a device word: `scrolledBy` is the WIDGET
verb, while `wheel`/`WheelInputEvent`/`processWheel` name the W3C stream on the pipeline side,
where the device is the literal truth.

### The press lifecycle — one beginning, exactly one ending

A primary press is a BEGINNING told to an AUDIENCE, and every member of that audience is told
exactly one ENDING. The contract lives once, beside the hand's `_pressAudience`:

- **The climb.** The hand drives it (`_climbPressFrom`): `pressBegan` goes to the widget the press
  hit, with the pointer in its own plane, then to its parent, for as long as each receiver answers
  that it passes the press on — `pressBegan` RETURNS `true` to hand it up and anything else to keep
  it (`Widget.pressBegan` raises and answers `true`; a halo handle, a 3D plot, a selectable text — on
  a mouse or pen stroke, or a finger stroke the grammar armed —, a slider's jump, a palette and the
  world keep it). Who heard the press is RECORDED, leaf first,
  and never re-walked: a lift re-parents what it picks up, so the chain at the release is not the
  chain the press climbed.
- **The endings.** `pressCancelled()` the moment the stroke becomes something that is not a press
  on that content — a SCROLL (decided once, at the drained event where the press leaves the grab
  radius, by `_strokeScrolls`, the same predicate the click decision reads): the members INSIDE the
  pane that took the stroke are cancelled, since the pane carries them and does not press them,
  while that pane and the members above it keep the press; a LIFT (the hand starts a float-drag):
  the whole audience, and the drop owes nothing more; an ABORT (`processPointerCancel`): whatever is
  still owed; a CLOSE (`noteWidgetClosed`): the members inside a widget put away mid-stroke. Otherwise `pressEnded(pos, …)` at the RELEASE, to every member still owed one, leaf
  first, each with the pointer in its own plane — wherever the release lands, on every release,
  a hold-consumed one and a scroll's included. A member is struck off before it is told, so nobody
  hears twice; a member that dies mid-stroke leaves the audience with its subtree, and one put away
  mid-stroke is told `pressCancelled` as it goes.
- **A scroll ends where its stroke does.** The pane a stroke's scroll went to keeps the press, so it
  hears the ending too, and its drag-scroll step pays the stroke's release flush THERE —
  `pressEnded` from the release point, `pressCancelled` from where the pointer stands — never in
  whichever frame first sees the hand let go (`ViewportWdgt.pressEnded`). A release and the next
  press drained in one frame therefore lose nothing: the next press stopping the step ends only a
  glide (`Fizzygum-tests/DETERMINISM.md` §3l).
- **The look.** Neither ending says where the pointer is. A receiver picks the look it ends in from
  where the pointer actually stands, by asking the hand (`restsOn` — a mouse or a pen rests on what
  it stopped over; a finger never rests anywhere), never by assuming it is still over it. The hover
  look on ARRIVAL asks the same fact (`pointerCanRest`, of which `restsOn` is the per-widget form), so
  a finger lights nothing as it arrives: were it lit on arrival and left at rest by its press's
  ending, the look under a finger would depend on whether a burst of its moves got ahead of content
  its drag-scroll had not moved yet and came back over it at the next re-sync
  (`Fizzygum-tests/DETERMINISM.md` §3n). So
  `HighlightableMixin` ends HIGHLIGHTED under a resting mouse and NORMAL otherwise, on both
  endings. A list row's look of being its list's SELECTION is no state it keeps, so neither ending
  has a selection to restore: the row reads it from the list's model as it paints
  (`MenuItemWdgt._shownState` → `CommandPanelWdgt.showsAsItsSelection`, the list's `selected`), a
  live press on one of the list's rows taking it off the others while it lasts — so either ending
  leaves the row at rest and the list showing its model's selection, whether the release clicked,
  landed elsewhere, or the stroke scrolled.
- **The click** is a separate verdict, made after the endings and gated exactly as before.

It is what iOS (`touchesCancelled` when a scroll view takes the touch), Android (`ACTION_CANCEL`
when a parent intercepts) and the web (`pointercancel` when the browser pans) do: the container
taking the gesture cancels the content's press. Pinned by `SystemTest_macroEveryPressIsToldItsEnding`
(both pointers) and `SystemTest_macroMouseDragScrollOfMenuRowsFiresNoRow` (mouse).

### The press-and-hold recognizer

Built to the drag-embed dwell machine's exact template (`drag-embed-interaction-spec.md` §6): the
decision is elapsed EVENT time from the press origin while the pointer stays within
`grabDragThreshold` (7 px — the dwell's own notion of "stationary", reused rather than duplicated)
of it, decided on `WorldWdgt.timeOfEventBeingProcessed`, never a wall-clock timer.
`_beginPressAndHoldRecognition` starts it at every `processPointerDown`, recording
`pressOriginPoint`/`pressOriginEventTime`; a `'mouse'`/`'pen'` stroke arms immediately and consults
no clock at all: all the recognizer keeps for it is whether the stroke travelled past
`grabDragThreshold` (`_pressTravelledPastDragThreshold`), which the release's click decision reads.

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
`PreferencesAndSettings.pressAndHoldMs`) the hold FIRES, at most once per stroke. It is the context
gesture's alternate trigger: it SELECTS the pressed widget as a right-click release does (the leaf the press
hit, under the same ancestry opt-out — `world._setEditorFocusNoSettle`, focus first), then dispatches
`contextMenuRequested` on it, so a finger sees which widget the menu acts on. A plain finger drag leaves
the hold radius first, so the hold never selects for it: over a scrolling surface it scrolls and selects
nothing (a scroll is not a click, on any pointer — below), and on a surface that arms at once (a paint
canvas) its release selects what it acted on, exactly as a mouse stroke's does.

**That suppression is an IDIOM with three applications, and the third one is the pressed-move
channel.** Anything a per-cycle re-entry produces is counted in CYCLES — wall clock — while
everything a drained event produces is counted in EVENT time; where the two can disagree
visibly, the cycle-driven half is suppressed while `Automator.animationsPacingControl` is active
and the Automator is not idle. Beyond the momentum glide (`viewports-and-planes.md`) and the
hold's between-events check above, `dispatchEventsFollowingMouseMove` takes an `atDrainedEvent`
seat argument — `true` from the move pipeline and the teleport, `false` from the per-cycle hover
re-sync — and under a paced replay it dispatches `pressMoved` only from the drained-event seat.
The reason is reproducibility of paint-by-drag: every pressed-move consumer is idempotent at a
standing position, so off the harness the re-sync's extra moves cost nothing and a finger holding
perfectly still keeps receiving them; but a cycle landing between the event that ARMS a touch
stroke and the next queued move turns one withheld move into a delivered one, and a paint tool
lays a dab another run does not (measured: one 4×4 dab, 1 run in 5). Hover moves are unaffected —
re-deriving who the pointer is over is exactly what the re-sync exists for.

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

### The four consumers of `strokeMeansMouseDrag()`

- **The float arms** (`ActivePointerWdgt.determineGrabs`) — a widget that `detachesWhenDragged()`
  (or a template) is picked up onto the hand only while the stroke means a mouse drag; an
  un-armed touch stroke falls through and the scroll surface underneath takes the gesture
  instead. The non-float arm (sliders, handles) is untouched — reaching it already means the
  press landed on chrome, which arms at the down.
- **`ViewportWdgt`'s scroll-drag step** — see [`viewports-and-planes.md`](viewports-and-planes.md).
- **The `pressMoved` channel**, at its ONE dispatch site: the over-list loop in
  `dispatchEventsFollowingMouseMove`, which dispatches `hoverMoved(pos)` when no button is down and
  `pressMoved(pos, button)` when one is. While a touch stroke is un-armed, no pressed move is
  dispatched at all — a finger sliding over text must not extend the selection, and one sliding
  over a paint canvas must not draw, while the surface beneath it scrolls instead. Hover moves are
  untouched; `'mouse'`/`'pen'` always mean a mouse drag, so the channel reads exactly as it did
  before the grammar existed. **One pressed move per pressed event, from one site**: the
  `button` on `pressMoved` is a plain FACT (`"left"`/`"right"`), not a discriminator between
  meanings — a paint tool lays paint under the primary button and previews under any other. The
  pressed move reaches every widget under the pointer, whoever's press it is: a receiver that acts
  only on its OWN press (the 3D plot's spin, `Example3DPlotWdgt`) knows that press by an anchor set
  at `pressBegan` and dropped at either ending — and while that press is live, its ending, not a
  `hoverExited`, is what ends the press's effects.
- **A selectable text's press** (`StringWdgt.pressBegan`). Selectable text takes a press for itself
  — it starts a selection, and an editable one opens its edit at the press — so the pane above it
  never hears that press. For an un-armed touch stroke it does not: the press may be the start of a
  scroll, so the text arms nothing and passes it on, and the pane takes the stroke, as iOS and
  Android give a scroll view the touch over its text. A tap is still the text's (its release clicks
  it), and so is a finger press the grammar arms at once (no scroll surface above). The text's own
  selectable flag cannot decide this: it is disarmed by a HOVER move, a mouse's notion, so a finger
  landing where a mouse last stood finds it armed. Pinned by
  `SystemTest_macroFingerSwipeOverSelectableTextScrolls`.

### The context gesture's two triggers, and what a hold's release owes

The context gesture is ONE widget verb, `contextMenuRequested(pos)`, with TWO triggers that meet
AT the widget rather than one level below it. A secondary press's release climbs to a
`contextMenuRequested` implementor and calls it; the hold fires by climbing from the pressed
widget to the same implementor and calling the same verb. `Widget.contextMenuRequested` is the
base every widget inherits — its body is `world.hand.openContextMenuAtPointer @` — so the titled
menu, the dev-mode disambiguation, the world's own menu (the climb reaches the world's
`buildContextMenu` the same way a raw right-click over empty desktop does) AND any override a
widget declares are inherited whole by BOTH triggers. Every widget's context menu is already
titled with its class-derived name (`Widget.buildBaseWidgetClassContextMenu`), so the hold needs
no title mechanism of its own. (A secondary press dispatches no down-fact of its own: there is no
secondary-press channel on the widget surface, only the hand's own right-press bookkeeping.)

A hold-consumed stroke's release dispatches no click — the same shape a right press has always
had (a right press never fires `activated` either) — via `_strokeOwesNoClick()`, which is
also true for a SCROLL, on any pointer (`_strokeScrolls`): **a stroke selects what it acts on, and
a scroll acts on the pane alone.** A finger's scroll is decided by the grammar (an un-armed touch
stroke that left the hold radius is a plain drag, i.e. a scroll, for its whole life); a mouse's or a
pen's is a stroke whose scroll owner — the innermost pane the press reaches with something to scroll,
told at the press (`ViewportWdgt.pressBegan` → `notePressTakenForScrolling`, not derived from the
pressed widget's ancestry, because a widget in between — a selectable text on a mouse or pen stroke, a
3D plot — can take the press for itself) — latched a pane as the press left the grab radius (it latches none for a stroke
that is lifting what it pressed), with no value control dragging. Neither a hold nor a scroll
withholds the press's ENDING: a hold-consumed release still ends the press (`pressEnded`), and a
scroll's release ends it for the pane and the members above it, the ones inside having been
cancelled at the commit (the press lifecycle, above). That rule is load-bearing,
not cosmetic: a scroll-drag carries the pressed row WITH the pointer, so the release lands on the
very widget the press landed on, and a plain `w == @mouseDownWdgt` test cannot tell a scroll from
an ordinary click — without it, every scroll would end in a click on whatever it scrolled past,
selecting it and firing it (a menu row's action, closing the menu). Pinned by
`SystemTest_macroMouseDragScrollOfMenuRowsFiresNoRow` (mouse) and the finger reference axis. A hold menu still
standing at release (the finger let go without moving) stays open as an ordinary transient menu;
the next outside tap dismisses it like any other.

### Touch hover dissolution and the pointer-absence state

A mouse or a pen rests where it stops; a finger does not rest anywhere between strokes — the
finger left the glass. At a touch stroke's up or cancel, `_dissolveHoverStateOfTouchStroke`
dispatches `hoverExited` to the whole `mouseOverList` and empties it, then sets
`@_pointerIsAbsent = true`. That flag is what makes the dissolution STICK: the
per-cycle hover re-sync would otherwise re-derive the over-list from wherever the hand happens to
stand a cycle later, re-entering whatever the finger last touched — its tooltip countdown and a
represented widget's highlight included. While `_pointerIsAbsent` is true, `dispatchEventsFollowingMouseMove` treats the
mouse-over set as empty: nothing is under a pointer that is not there. The next
`processPointerDown` of ANY kind clears the absence (a down states a position — the pointer is
back), and so does any hover-capable move (a real mouse/pen move). A `'mouse'`/`'pen'` stroke
never sets the flag, so their strokes keep today's persistent pointer-under state
byte-identically.

The dissolution is the stroke's LAST act: the up (or the cancel) tells the press's audience its
ending and clears the stroke's press and drag state FIRST, so the exit it delivers is final (and
an ending's look never sees a finger resting: `restsOn` answers no for a touch stroke). Three `hoverExited` handlers defer to a live
drag — a slider thumb keeps its pressed look while the pointer outruns it, a halo handle keeps its
pressed plate, and a size adjuster keeps its resize cursor — and an exit delivered while the drag still stands is one they ignore.
That matters most for a thumb a finger dragged and let go of ON the thumb: the release is a click
on it, and `SliderButtonWdgt.activated` lights it up, so the dissolution is the only thing left
that can put it out.

A touch stroke still makes exactly ONE hover move: its down's own position head
(`processPointerDown` runs the move pipeline before the press, with no button recorded yet), so
the finger ARRIVING is delivered as a pointer walking to the press point. That move is
load-bearing twice over:
- **Text:** `StringWdgt.hoverMoved` ends a stale selecting gesture on it.
- **Scrollbars:** it is how a finger reaches a scroll indicator. Landing within a viewport's
  scroll band fattens the bars (`ViewportWdgt.hoverMoved`), so the press lands on a fat, tangible
  bar — chrome the finger then drags or pages like a mouse does.

The arrival is a hover move even when the finger lands exactly where the previous stroke went
down. `dispatchEventsFollowingMouseMove` sends moves only "if the pointer actually moved", measured
against the stroke's down position (`@mouseDownPosition`) so that a press held still is not
dragging; a press beginning drops the previous stroke's down position before its position head
runs, so that comparison can never swallow the arrival. Kept, it would make a finger re-touching
the spot its last stroke started from arrive with no hover move: the bar under it would stay thin
and the press fall through to the content, and an armed text selection would open an edit.

Nor is the arrival skipped when the finger lands exactly where its previous stroke ENDED. The head
itself is skipped for a down whose stated position equals the hand's — a pointer that already
stands there needs no second move — but an ABSENT pointer stands nowhere, even on the pixel it
lifted from, so `processPointerDown` reads the absence before clearing it and runs the head
whenever it was set. Skipped, a re-landing on the lift pixel would meet the over-list its lift
emptied: the same thin bar and the same fall-through onto the row beneath. That re-landing is
routine, not contrived — a one-pixel thumb drag lifts exactly where the next one-pixel drag of the
moved thumb presses, so the macro toolkit's corrective list nudge would lose every second step to
a stray row click.

The fattening and the press are therefore ALWAYS in one event for a finger, which is why a
dataflow drain must not depend on whether they share a cycle (`Fizzygum-tests/DETERMINISM.md`
§3j).

### Cancel semantics

`processPointerCancel` is its own method, not a flag on the up — an up means exactly what a
cancel does not: the browser confiscated the stroke (a system gesture, a palm rejection, the tab
going away), so nothing that means "the user chose this spot" may happen — no click, no menu
dismissal, no embed, no dock. A float-drag's payload still lands on the world where it visibly is
(it may be the user's only copy of something); a non-float drag is told it ended; the shared
press clear (`_forgetPressBookkeeping` → `_forgetPressAndHoldRecognition`) takes the recognizer's
state with it, the press's audience having been told `pressCancelled` first — a confiscated press states no intent, so it can neither arm nor open a menu,
though a menu that had ALREADY opened stays (the cancel is not a click outside it). Touch hover
dissolution runs on cancel exactly as it does on an ordinary up.

### A widget that dies or is put away mid-stroke

A press books widgets the rest of its stroke acts on — `wdgtToGrab` (what a drag picks up),
`mouseDownWdgt` (what the release's click and a finger's hold are about), `nonFloatDraggedWdgt`
(what a non-float drag steps), the pane that took the press and the one its latch chose — and the
hand carries a float drag's payload. A booking left naming a widget that has left the world the
stroke acts on would be acted on at a later event of the same stroke: a pressed move lifts it onto
the hand, and the release drops it back on the desktop. A widget leaves that world two ways, and
each way has ONE funnel that tells the hand:

- **A death.** `Widget._destroyNoSettle`, the funnel every death passes through, tells the hand
  (`ActivePointerWdgt.noteWidgetDestroyed`), as it tells the world's other registries of live
  widgets (the caret, the editor focus, stepping, the keyboard receivers, dataflow). A corpse is
  owed nothing.
- **Being put away** — into storage alive (the bin, or the shelf when something still reaches it).
  `Widget._closeNoSettle`, the funnel every close passes through (a close button, a menu's Close or
  Move to trash, a filing, a drop on the bin's icon, which IS Move to trash), tells the hand the
  FIGURE that leaves (`noteWidgetClosed`; the island a tilted widget rides in), before it leaves its
  parent. Two storage moves state the same fact where they happen, since neither can pass through
  the close funnel: the storage sorter, when it files a resident of the bin (which an open bin
  window shows) away to the shelf, and the bin itself, when its window closes and takes it off the
  desktop. A widget put away can come back, so it is owed what the stroke owes it before it goes:
  the audience members inside it are told `pressCancelled`, and the widget a non-float drag steps
  is told `endOfNonFloatDrag`, as a release would tell it — either look left standing would come
  back out of storage with it.

Either way the hand forgets every booking the leaving widget IS OR CONTAINS — containment, because
a single-widget `destroy()` orphans the subtree under it — forgets the pick-up when its carried
payload leaves (that pick-up can be the template the payload was copied from), and prunes the
press's AUDIENCE the same way, so no ending reaches a widget that has left. The stroke goes on
without them. Not forgotten: the over-list (the next dispatch re-derives it, and it owes the leaving
widget its last `hoverExited`), the multi-click candidates (they recognize only the widget a release
lands on), and the drag-embed state (the next dispatch takes it down once nothing rides the hand).
No built-in gesture closes a booked widget mid-stroke — every close control fires at a release or a
drop —; a program does (a formula fed by the stroke's own slider, a timer). Test:
`SystemTest_macroWidgetDestroyedOrClosedMidStrokeIsNotPickedUpAgain`.

### The grab-threshold rules

A press lifts nothing until the pointer has travelled `grabDragThreshold` from where it went down,
and what lifts then is the widget under the PRESS; `grab` moves it by that travel, so the hand
carries it by the very point the press went down on. That correction — and every other placement
relative to the hand, the switcheroo centring and the glass-box inflate — is applied only AFTER the
release settle (`_beforeBeingGrabbed`): the release re-lays the host being left, and a host that
places its children (a document's flow) would otherwise put the widget back, leaving it riding the
hand off by the threshold travel. Playback runs these exact rules: there is no Automator carve-out,
so a replayed mouse drag waits out the threshold as a user's does, and a test cannot ask otherwise
(`AutomatorEventCommandStartMacro` refuses the retired `grabDragThreshold` metadata key).
Pinned by the value assertions of `SystemTest_macroSimpleDocumentHandlesOldInspector` (a window
dragged out of a document lands exactly where the drag puts it, on either pointer).

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
  grammar (the widened detach gate, the direction latch).
- [`widget-authoring-guidelines.md`](widget-authoring-guidelines.md) §9 — the two capability
  queries a widget author may declare or consult.
- [`../specs/drag-embed-interaction-spec.md`](../specs/drag-embed-interaction-spec.md) §6 — the
  dwell-to-arm machine the press-and-hold recognizer is built on.
- [`../../Fizzygum-tests/DETERMINISM.md`](../../Fizzygum-tests/DETERMINISM.md) — the event-time
  doctrine binding every recognizer above.
- `src/macros/CLAUDE.md` / `MACRO-PATTERNS.md` — how a macro synthesises a touch stroke, and how
  the finger run mode translates an existing mouse-flavoured macro into one.

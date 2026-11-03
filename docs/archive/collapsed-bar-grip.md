> **ARCHIVED — COMPLETE (2026-11-01).** Decision record for the resize grip on a collapsed window and for the bar's own
> width. The present-tense description lives in `docs/architecture/visual-design-system.md` (the "Resize grip" row), in
> `docs/architecture/regularity-principles.md` and in the headers of `src/FrameGripWdgt.coffee` and the comments on
> `FrameWdgt.offersAResizeHandle` and `FrameWdgt.barsOwnWidth`. Index: `docs/archive/INDEX.md`.
> ⚠ **Amended 2026-11-03** by `docs/archive/toolbar-grid-and-bar-run.md`: a bar's pieces now keep their ends unless one
> stands alone, so "if there is space" below is the padding, the pieces and ONE reach of the grip (129 px for close and
> collapse), not the pieces with a reach on both sides (168 px); and `_gripStripThickness` is now `_gripStripSide`.

# A collapsed window keeps its grip, and its bar can have a width of its own

## What it is now

A collapsed window keeps its grip while its bar has room for it. The grip stands at its usual place relative to the
corner, on the bar, in the bar's glyph inks. Dragging it sizes the bar's width, and the cursor says so (`ew-resize`). It
stops at the narrowest bar that keeps it. A tap on it expands the window, as a tap anywhere on the bar does.

A bar nobody has resized is as wide as its window. A width given to a collapsed bar is the bar's own: the window comes back
exactly as it was, the bar goes back to that width at each collapse, and resizing the window leaves it alone. Nothing makes
such a bar follow its window again.

The window expands from wherever its bar is. Moving a bar moves the window.

## The two things the owner asked for

1. "When collapsed, it would be useful to still have the resizing handle if there is space. Of course the other elements
   in the bar are more important."
2. A bug, on the Docs Maker info window: collapse (right), uncollapse (right), resize, collapse again: the bar is the
   *previous* size.

## The bug, measured

Reproduced with real input on the real page, on the Docs Maker info window and on a plain window alike, so it was the
frame's bookkeeping and nothing of the Docs Maker's. Bar 365 for a window of 290, bar 420 for a window of 345.

`FrameWdgt` recorded a width for its bar at every uncollapse (`widthWhenCollapsed`), whether anyone had resized the bar or
not, and re-applied it at the next collapse. It dates from a 2017 design in which a collapsed bar had its own width. When
the grip left collapsed bars on 2026-08-24 nothing could set that width any more, the recording stayed, and every window
resized between two collapses came back at the stale width. `widthWhenUnCollapsed`, which only repeated
`extentWhenCollapsed`, went with it.

## Rulings

- **The bar's width is the bar's (owner, 2026-11-01), compared against two alternatives.**
  - *One shared width*, where resizing a bar sets the width the window comes back at, was built first and reversed. While
    collapsed there is no content to judge a width by, so a width chosen on a bar is about the bar: fitting it on the desktop,
    reading its title. And the cost was lopsided: tidying a bar brought a carefully sized window back 168 wide, its text
    rewrapped, its old width gone with no way back but dragging by eye.
  - *A bar width that lasts until you expand* needs no memory at all, but every quick look at a parked window would send its
    bar back to full width, so a tidy row of narrow bars would not stay tidy.
  - *The chosen rule* costs the ability to change a window's width while it is collapsed, which is one click away.
  - A bar's width is recorded only when one is asked of it (`_noteAWidthAskedOfMyBar`), never at an uncollapse, so a bar
    nobody resized has none and cannot go stale. That is the difference from the bug.
- **Resizing the window leaves the bar's width alone (owner, 2026-11-02).** The first version ended the bar's width when the
  window was resized, and the bar took the window's new width at the next collapse. The owner saw that and asked whether it
  was right. It was not. A window's resize says nothing about what the bar's width was for, fitting the desktop or reading the
  title. Expanding one bar of a tidy row, enlarging its window and collapsing it again left that bar wider than the row, which
  is the failure used above to reject a width that lasts until you expand. The cost is that a bar once given a width never
  follows its window again, and one narrowed by accident stays narrow until dragged.
- **A bar's width has no reset (owner, 2026-11-02).** A snap at the window's width during the drag, after which the bar would
  follow its window again, was proposed and dropped: a snap distance, a hidden rule and more to test on both pointers, for
  something rarely wanted. A double-click on the grip cannot work, because the first tap has already expanded the window. A menu
  row would add a row few would find. Dragging a bar back by eye leaves it a few pixels off its window, which does no harm: the
  mismatch cannot be seen while the window is collapsed, and the window comes back at its own width regardless.
- **Position is not restored (owner, 2026-11-01).** "Restore" fits a window's size but not its place. A bar's position is no
  blind choice, since it is where the window's title will be. Today the close and collapse buttons stay under the pointer as a
  window unrolls, so a second tap collapses it again; a window jumping back would vanish from under the pointer, and each
  toggle would travel between two places. Width does not have this problem: the window's left edge and buttons stay put and
  it only grows to the right.
- **Nothing keeps an expanding window on the desktop (owner, 2026-11-01).** Measured: a 300-tall window whose bar was parked at
  the bottom of a 720-tall desktop expands down to y=977, its grip out of reach. Moving it just enough to fit, and back on
  collapsing, was proposed and declined: dragging the bar is easy enough. A narrow bar near the right edge can do the same.
- **"If there is space" means the grip takes nothing.** The pieces lie out as they would with no grip: a strip too short for
  a title centres them, a longer one leads them from its start and keeps its title as far from either end as they reach. So
  the room needed is the tight case, the pieces' length with the grip's reach free on both sides of them
  (`FrameBarWdgt.shortestStripLeaving`), 168 px for a window's close and collapse. Below that the bar shows its pieces and no
  grip. A piece trailing at that end, which a band collapsed while docked gains when it is lifted out, leaves no room at
  any width.
- **The drag stops at the narrowest bar that keeps the grip.** A grip narrowed out of existence would leave no way back
  short of expanding, and would vanish from under the pointer holding it.
- **A tap on the grip expands.** Ruling C17 says the whole bar of a collapsed frame expands it, and a touch-sized target in
  its corner must not take a part of that away. The grip holds off resizing until the press has travelled the same grab
  threshold a press on the bar must, so a trembling tap neither resizes nor stops being a tap.
- **Its inks are the strip's.** The grip strip stays light whatever the focus, but the title strip goes dark on the focused
  window, so `frameGripInk` would barely show there.

## What this supersedes

The 2026-08-24 ruling, carried out in the frames program, hid the handle on every collapsed frame. Its reasons were C5's
letter (a resizer belongs to a payload that sizes) and a 44 px plate entirely covering a small collapsed frame, which
defeated C17. The owner has now asked for the handle back, the room test keeps it off a bar it would cover, and the
tap-through keeps C17 whole. The archived plans stay as they are.

## Constraints kept

- **A visibility is never a layout input.** `_gripStripThickness` answers 0 for a collapsed frame before it asks the grip
  anything, so the width-dependent answer reaches no measure and no arrange, and a collapsed frame's height never depends
  on its width.
- **Measure and arrange agree.** Neither changed: collapsed, both say the strip's thickness.
- **No re-visits.** The grip re-asks at the frame's own arrange, once the width has landed, and `noteMyGripCameOrWent`
  schedules nothing for a collapsed frame, whose bar the grip takes no room from. Nothing in the arrange reads the answer.
- **One funnel for a wish.** Every way of asking a free-floating widget for an extent writes `@desiredExtent`, so
  `_noteAWidthAskedOfMyBar` covers the grip, a halo's handle and a setter alike, and a width a host grants a docked sliver,
  which is no wish, is no width of the bar's.

## Case law

- ⭐⭐⭐ **A design argued from code needs a separate pass asking what the person is doing.** The one shared width was chosen on
  two arguments: the structural neatness of having no second field, and a test's provenance calling the old sticky width
  "rent nothing paid for". That note was weighing code against a gesture that no longer existed, and was no evidence about
  people. The owner asking "what is best from a UX perspective?" reversed it in one step: nobody can judge a window's width
  with its content hidden. Claude had also told the owner a remembered width "would recreate the mismatch you reported", which
  overstated it: the report was about a stale width nobody chose, and a width given on purpose is not that.
- ⭐⭐⭐ **An exception with no reason given is a finding.** This record stated "one exception" to the bar's own width and never
  argued for it, and it failed the same record's own argument against the width that lasts until you expand. The owner noticed
  it by using the feature, a day after it was pushed. Before calling a rule settled, ask of each exception what it is for.
- ⭐⭐ **Do not add machinery to repair a harm nobody has shown.** Claude proposed the snap because a width cannot be matched by
  eye with the content hidden, without asking whether matching matters. It does not, for the same reason.
- ⭐⭐⭐ **A comment that states a contract is a hypothesis too.** A test's own intent said there was "no second,
  separately-tracked collapsed size", beside a field that was one and was the bug. Grep for what a contract says does not exist.
- ⭐⭐ **The hand sends `activated` after a drag too**, whenever the release lands on the widget that was pressed
  (`ActivePointerWdgt.processPointerUp`). A handle's `activated` was empty, so nothing had ever had to tell a tap from a
  drag there. The grip now does, and the test releases a drag at its origin to prove it.
- ⭐⭐ **A regression test is proven by putting the bug back.** A prelude restoring the old recording in the page made the new
  test fail with the report's own numbers: expected 290, found 365.

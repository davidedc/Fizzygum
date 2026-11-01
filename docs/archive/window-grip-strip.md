> **ARCHIVED — COMPLETE (2026-10-31).** Decision record for the window resize grip's strip. The present-tense
> description lives in `docs/architecture/visual-design-system.md` (the "Resize grip" and "Grip strip" rows and the
> `frameGrip*` metrics), in `docs/architecture/viewports-and-planes.md` (the corner reserve) and in the headers of
> `src/FrameGripWdgt.coffee` and `src/FrameBodyAppearance.coffee`. Index: `docs/archive/INDEX.md`.

# Every window's grip lies in a strip of its own

## What it is now

A window that can be resized has a 42 px strip along its bottom edge, inside its border: the grip's 36 px square with
its 3 px inset above and below. The grip is the same size and in the same place relative to the window's corner as
before. The strip is part of the window's own body, so a press on it moves the window. The window's content stops
above it, keeping the same margin it keeps from the title strip.

Hovering the grip darkens its strokes, sets the resize cursor and outlines the window that would resize. A window
standing in a window in view mode has no grip and no strip, and its content takes that room back.

## The problem, measured

Big corner grips overlapped each other, and it was unclear which one a press would take. Real drags on nested windows
showed it was worse than unclear:

- When a nested window's corner reached its parent's, the parent's grip lay on top. Pressing Q4's strokes resized
  **Sales**. Only a sliver about 3 px wide, in an L, resized Q4.
- The grip had no hover or press look and did not change the cursor, so nothing said which window would respond.
- A nested window's grip still showed and still resized it inside a parent in view mode.

## The options, seen on real windows

All of these ran as a runtime patch over the real framework, in one nested scene, on a comparison board with live
links:

- **Today**, as the baseline.
- **A+B+C**: where grips overlap the nested one wins, a small mark inside the same clickable area, and hover feedback.
- **E, empty**: a strip on every window holding only the grip.
- **E, with the toggle**: the same strip also holding the edit-mode toggle.

I recommended A+B+C because a strip costs content height on every window. The owner chose **E, empty**, at the
original grip size, which made the strip 42 px rather than the 32 px first prototyped. A+B+C's weakness, seen on the
board: the parent's grip becomes the hard one to reach in the shared corner, and the marks still touch. Do not re-argue
this without new evidence.

## Rulings

- **A window in a view-mode parent is not resizable**, and shows neither grip nor strip. "Parent" is the nearest window
  around it, so a window in an edit-mode window keeps its grip whatever stands further out. A drag where the grip was
  takes hold of the parent window, as a drag anywhere on a locked nested window does.
- **The strip is on every window that can be resized**, including a window whose content ends in a footer band, where
  the two together take 94 px.
- **A toolbar is a window, and follows the same rule.** It is a frame holding a toolbar, so docked it has neither grip nor
  strip (the host's strip runs below it), and floating it has both. A floating column, the shape one opens in, is 11 px
  taller than before: it used to keep 39 px clear for the grip at its far end, and now keeps its 8 px padding above the
  42 px strip. A floating row, the shape "Float" leaves it in, goes from 103 px to 145 px tall and gains 31 px of run for
  its cells. A toolbar does not strictly need the strip, since it holds no windows and always kept its own room for the
  grip. Exempting it was weighed and left out: it would restore the keep-clear code for one kind of window, and give
  grips a second look.
- **The strip stays light when its window has focus.** Focus dresses the title strip, which names the window.

## What the strip made unnecessary

Nothing lies under a window's grip any more, so everything that kept clear of it went: `FrameGripWdgt.footprint`,
`resizerCanOverlapContents`, `FrameWdgt.bottomRightCornerReachedBy` and the patch nodes' copies,
`ViewportWdgt.cornerResizerFootprint`, `ToolPanelWdgt._farAlongPadding`. Scroll bars now run their full length in a
window, and a footer band's right group reaches its inset. The window page gutter's precision follow-up (a document's
bars reserving the grip's full footprint, 8 px more than a page's corner needed) went with them: no reserve is left to
make exact.

The corner chain and `footerGripClearance` remain for one case: a naked inspector, whose plain handle really does stand
over its own corner.

## Case law

- ⭐⭐⭐ **The recapture's own gate found a product bug that every check of the hover had passed.** A press on a grip
  raises the window, and the raise (`Widget.bringToForeground`) moved the window past its own outline, which stands
  beside it on the desktop, so a person resting on a grip saw the outline vanish the moment they pressed. A macro's move
  and press normally drain in one cycle: the raise happens first and the outline is built on top, so the suite showed the
  outline and a person did not. A cycle start falling in the gap between them gave a macro the person's order, about one
  capture in 25 under recapture's load, and those references kept failing afterwards. Holding each press back until the
  arrivals had drained turned the live hash into the failing reference's exact hash, which proved the mechanism. The band
  a raise neither climbs past nor buries (`Widget._bandAboveMe`) now includes ephemeral overlays. Asserting
  `world.widgetsToBeHighlighted.has` could never catch this: the declaration stands while the pixels are gone, so the
  new test asserts the outline's z-order, with a cycle between hover and press on purpose. Case law also in
  `Fizzygum-tests/DETERMINISM.md` §3o.
- ⭐⭐⭐ **A recapture would have frozen a macro that stopped doing its job.** `macroWindowCellsInConstrainedScrollStackReflow`
  released a window low in its host. The strip moved the bottom dock band up by 42 px, so the release docked instead of
  stacking. Every later step ran, and only an unrelated aim missed further on. That prompted a **behaviour trace**: a
  prelude logs what each press hit, what each grab took, where each drop landed and each dock, per test, on a baseline
  build and on the new one. Run after fixing that one fixture, it showed nothing else had changed meaning.
  Pixel comparison cannot ask this question, since every affected pixel is expected to change.
- ⭐⭐⭐ **A strip that depends on where a window stands makes that window's measure depend on it too.** The chrome used
  to be the same whatever held the window, so nothing had ever needed to ask in what order a host adopts a child and
  reads its height. `Widget._setWidthSizeHeightAccordingly` hands back the applied height, which still counted the strip
  the adoption had just removed: the host sized itself by it, the window shed it at its own arrange, and the up-edge
  re-visited the host. `fg revisits` caught it in two tests. The height now changes as the grip comes or goes
  (`FrameWdgt.noteMyGripCameOrWent`).
- ⭐⭐⭐ **A prototype's sweep hid a real ordering bug.** The prototype re-derived grips every 100 ms, so it never had to
  be told about a mode change. The real hook runs in `showEditModeInBar` / `showViewModeInBar`, and `ViewportWdgt` alone
  told its window before writing its own flag, so a window in a scrolling window read the old mode and kept its strip.
  `fg census` caught it, in the Sample slide as built. A window's mode is its payload's, so the order mattered for the
  first time.
- ⭐⭐ **Attribution still earns its keep when the change is broad.** "Every changed pixel lies inside a window a strip
  can touch" flagged 29 of 282 shots at dpr 1. Six were the new test, which had no references yet. The rest were real
  and explained: windows carried on the hand (the walk missed them), pieces dragged out of an inspector landing elsewhere
  because a macro grabs by the centre and the panes are shorter, and a prompt that follows the hand.
- ⭐⭐ **The strip is body, not a child widget.** A press, a drop and a right-click on it needed no new code, and a copy, a
  save and the world inventory meet nothing new.
- ⭐ **Ink read at paint.** The grip's hover ink is derived as it paints (`FrameGripWdgt._gripInk`), not written to its
  `color`. Written, a window saved while hovered would come back with a dark grip that nothing could clear, because the
  flag saying so does not survive the save.
- ⭐ **A rule stated as one query is cheap to keep true.** The strip, the grip and the view-mode ruling all answer
  `HandleWdgt.wouldShow`, so they cannot disagree about whether a window can be resized.

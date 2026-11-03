> **ARCHIVED — COMPLETE (2026-11-03).** Decision record for the toolbar grid (packed, spread only while full, filling
> its box) and for a frame's RUN, which decides which side its bar takes, whether it shows a title and where its grip strip
> lies. The present-tense description lives in `docs/architecture/visual-design-system.md` (the "Window bar", "Edit-mode
> toggle", "Grip strip" and "Embedded toolbar" rows) and in the comments on `ToolPanelWdgt._layOutOwnContents`,
> `FrameWdgt._runAxis` / `_barAxis` / `_gripStripSide`, `FrameBarWdgt._positionAndResizeChildren` and
> `EditModeToggleAppearance`. Index: `docs/archive/INDEX.md`.

# A toolbar packs its tools, fills its box, and its window's bar runs across its length

## What it is now

**The toolbar grid.** A toolbar is a grid that fills its box: as many columns as fit across it and as many rows as fit
down it, at the least gap, in reading order, with the last slot the » whenever the tools do not all fit. A strip is a box
one cell deep, so a docked band is one row or one column because that is all its box holds. While every tool fits, the
tools are packed from the top-left and the leftover lies past the last one, so a tool keeps its place however long the
strip grows. While the toolbar is full (the » shows), the leftover is always less than one cell, and it is shared between
the slots along each axis, which puts the » at the far end and moves each tool by a few pixels at most.

**A frame's run.** Every frame may have a RUN, the axis it is long along, given by whatever shapes it: a host's slot gives
the length of its edge, expanded or collapsed; otherwise a payload that identifies itself (a toolbar, whose tools are its
identity) gives the frame's longer side while it shows; otherwise there is none. From the run alone:

- **the bar** runs across the top when there is no run, across the run at its leading end when expanded (down the left of
  a wide toolbar window, across the top of a tall one), and along the run when collapsed;
- **the title** shows on a horizontal bar unless the payload is showing and identifies itself, so a collapsed toolbar
  window shows its title again, exactly when its tools are hidden;
- **the grip strip** lies along the edge opposite the bar: the bottom, or the right beside a bar down the left. The grip
  keeps its corner either way.

| Frame | Run | Expanded bar | Collapsed bar |
|---|---|---|---|
| Docked top/bottom | slot: horizontal | vertical, no title | horizontal strip, title |
| Docked left/right | slot: vertical | horizontal | vertical sliver |
| Floating toolbar, wide | its shape: horizontal | down the left, no title | along the top, title |
| Floating toolbar, tall | its shape: vertical | along the top, no title | along the top, title |
| Any other window | none | along the top, title | along the top, title |

**The bar's pieces.** A lone piece alone on its strip centres. Anything more keeps its ends, whether a title shows between
them or not: close in the leading corner, the edit toggle at the far end.

**The edit toggle** lies along its box's longer side, eye at the leading end: left to right across a top strip, top to
bottom down a side strip. One drawing does both, written in the track's own along/across directions and mapped into the
box once.

**Words.** "Toolbar" is the family's name everywhere. "Palette" means only a set you pick from where the pick stays: the
colour palettes (`PaletteWdgt`) and the paint toolbar's armed tool.

## What the owner asked (2026-11-03)

1. "When toolbars get long, the distribution of icons looks a little silly" (the Docs Maker band at 1264 px, ten tools
   spread over the whole width).
2. "Perhaps simply all windows that have such elongated width could just appear with the titlebar put vertically at the
   left side, and the status bar with the handle at the right."
3. "When a toolbar is resized beyond the cases of thin vertical or horizontal stripe, whether its contents should take a
   multi-column or multi-row (i.e. some kind of grid) shape."

With the standing condition: "consistency and architectural uniformity … rather than having special cases all over the
place." The options were brainstormed in text, then prototyped by runtime overrides on the real page and shown to the owner
as real renders.

## Rulings (owner, 2026-11-03)

- **Pack (1A).** Rejected: centring the run (every tool still moves on resize), groups with separators (1C) and a flexible
  space (1D). Groups stay possible later through the menu's own `DividerWdgt` vocabulary, at the cost of variable-width
  slots in the grid's arithmetic.
- **Spread only while full** — the owner's refinement of 1A: "until there is the need for », probably we can indeed spread
  the icons. It's when all the icons are in that we can proceed to not spread them." Measured: at the default Docs Maker
  width the space after a packed » looks like room for one more tool and is 5 px short (53 of the 58 a tool needs: its 6 px
  gap, its 44 px cell, the 8 px end padding). Spreading while full keeps the » at the far end and moves each tool a few
  pixels. The overflow case is exactly the spreading code that shipped before, so nothing new was needed for it. A
  prototype that packed and then moved the » to the end shifted the strip 21 px sideways through the viewport's
  measure-then-commit re-fit, on both attempts, and was dropped.
- **Grids (3A).** Fill the box in reading order. Rejected: filling tall boxes column by column, whose order would flip as a
  box goes from wide to tall.
- **The side bar is not for every window.** Shown as real renders: a title cannot run sideways (text is on horizontal bars
  only, C13), the edit toggle had no vertical form, collapsing needed a ruling, and a window whose content sets its own
  height, near a shape threshold, could flip its chrome and fail to settle. The rationale for two cases, weighed in this
  order: (1) does the content identify the window — a toolbar's tools do, two text panes do not; (2) palette versus
  document, the tool windows of most window systems; (3) the docked and floating forms of a toolbar match; (4) keying the
  rule on what the content is, not on the window's shape, means a document window never changes chrome. Chosen form: one
  capability, `identifiesItself` (on `ToolbarWdgt`), named by the question the frame asks rather than by a role noun — a
  menu's rows are commands like a toolbar's, but its title names the widget they act on.
- **A collapsed frame's bar runs along whatever holds it** — owner, asked whether floating toolbars should collapse as
  docked ones do. A docked frame's runs along its slot's edge (C13); a free frame is held by nothing, so its bar runs along
  its top (C15). For a wide floating toolbar both rules agree (a horizontal bar with its title, as a collapsed top band
  already was). For a tall one the dock's rule would give a full-height sliver, rejected: the slot dictates a docked
  sliver's shape and a free frame has no slot; the sliver shows no title exactly when the title is the only thing
  identifying it; its expand button would move from under the pointer; the collapsed bar's grip and its own width are
  horizontal; and it keeps the long dimension. Cost accepted: collapsing a wide toolbar moves the − from below the × to
  beside it.
- **A lone piece centres; anything more keeps its ends** (supersedes the C13 amendment of 2026-08-24, "a textless bar
  centres its piece group"). That amendment's examples were all docked bands with their one collapse glyph, and its reason
  ("a lone collapse glyph pinned to one end of a long empty band reads as an accident") is about a lone glyph. The
  implementation applied it to every bar showing no title, so a free window too narrow for its title centred its close,
  collapse and edit toggle, a case nobody had judged. Asked when centring happens today and why it was decided so, the
  rule was restated as its reason.
- **The vertical toggle is the same implementation** — owner: "in some kind of clever way that doesn't need a different
  implementation than the horizontal case". It is placed by one along/across mapping and never rotated, so its glyphs stay
  upright and the horizontal case is the identity.
- **A free toolbar runs along its longer side; a square has no run** and keeps its bar on top. No hysteresis: a margin
  between the switch points would depend on history, which a derived skin may not (C4).
- **Names.** Keep "toolbar"; keep "palette" for the pick-and-keep sense; nine loose comment uses in the toolbar classes and
  three in the drag-embed spec were reworded. Theme dials renamed where the side bar made their names untrue:
  `frameGripStripHeight` → `frameGripStripThickness`, `barToggleBoxWidth`/`TrackWidth`/`TrackHeight`/`KnobWidth` →
  `barToggleBoxLength`/`TrackLength`/`TrackThickness`/`KnobLength`.

## What this overturns or amends

- **C15** ("free windows keep the bar on TOP, always") holds for every frame whose bar carries a title; a frame whose
  payload identifies itself takes its bar across its run. Recorded in the program ledger.
- **C13's 2026-08-24 amendment** on textless bars, as above.
- **`collapsed-bar-grip.md`, "if there is space"**: with the pieces leading from the start, the room a collapsed bar needs
  for its grip is its padding, its pieces and one reach of the grip (129 px for close and collapse), not the pieces with a
  reach on both sides (168 px).
- **The redesign draft's tool spacing** ("spread evenly (space-between) with 8px of side padding",
  `docs/archive/redesign/UI-guidelines.md`), written at a width that showed four tools.

## Constraints kept

- **A visibility is never a layout input.** The grip strip's side asks the grip whether it *would* show (`wouldShow`),
  never whether it does.
- **Measure and arrange agree.** The chrome terms read the same body edges; the right edge is now `_bodyEdgeRight`, used by
  the chrome width, the body width the bands are laid in, the right band's place and the dock-band box.
- **Nothing feeds back.** The run reads the frame's own extent, which a person set or which wraps a payload of the same
  proportions (a band lifted out of its slot keeps its band's; a new toolbar window starts square and hugs a column),
  never the payload's box, which the bar's side would change.
- **Docked frames and titled windows are unchanged.** Their runs and bars come out exactly as before; only the grid's
  spacing and narrow windows' piece layout move for them.

## Verification

- Before any reference was touched, every one of the 47 tests the change failed at dpr 1 was traced to a ruling by a
  pixel-attribution pass (diff clusters, then reference-over-live crops): pieces keeping their ends on bars too narrow for a
  title (narrow windows, pinned menus, prompts, collapsed bars, a tilted window); docked columns packing (the paint toolbar,
  the chevron test); the floated band wearing its side bar; and the collapsed bar's lower grip floor. Nothing unexplained
  moved, and no test's prose described the old spreading or centring.
- Those same 47 tests, and no others, were recaptured at dpr 1 and 2 under both pointers; the recapture's completeness gate
  then passed the whole suite at each density.
- The two new tests (`macroToolbarGridPacksAndSpreadsOnlyWhenFull`, `macroToolbarWindowBarCrossesItsRun`) pass followed by
  `macroWindowsEmptyCollapsingUncollapsing` under both pointers, with no world-inventory leak.
- `fg gauntlet` passed all 19 legs (finger included), then `fg homepage`.

## Case law

- ⭐⭐⭐ **An implementation's generalisation is not a ruling.** The textless-bar amendment was ruled with docked examples; its
  plan line "falls out for every bar the title rule leaves textless" meant narrow free windows centred their pieces without
  anyone deciding it. Claude first recommended keeping it only because it needed no new rule, the weakest kind of
  uniformity. The owner asked when it happens and why it was decided so, and the honest answer reversed the recommendation.
- ⭐⭐⭐ **Check what existing rules do to a new case before describing the case.** Claude told the owner "the close button
  stays in the top-left corner either way" while recommending the side bar; the textless centring made that false for any
  bar longer than its pieces. It came out only when checking for decisions before implementing.
- ⭐⭐ **Prototype UI with runtime overrides in the real page** (`page.addScriptTag` of prototype methods with a mode switch
  whose "today" calls the original): real renders, no source change, no build. Check the "today" render against the
  owner's screenshot first.
- ⭐⭐ **A review page of project screenshots is a local HTML file beside its images**, opened in the browser. An artifact copy
  showed no images, and Claude had not looked at it before sending the link.
- ⭐⭐ **Stop after two failed fixes of a variant nobody asked for.** The »-at-the-end variant failed twice the same way; the
  owner's own refinement then made it unnecessary.

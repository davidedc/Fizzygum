# Toolbar band depth — a band as deep as a strip, pictures in a mark box

**Status: COMPLETE 2026-11-23.** Authored 2026-11-23 and executed cold the same day; Phases 1–6 landed as
written, Phase 3 included, with the deviations the ledger at the end records. The living truth is
`docs/architecture/toolbars.md` §1 and `docs/architecture/visual-design-system.md` ("The tool cell", the
embedded toolbar row). The shape is owner-approved ("A with smaller pictures", 2026-11-23, chosen from five
rendered geometries). Below, the plan as it was executed.

**Mandate: transformation, not accommodation.** After this plan there is ONE depth for a row of chrome
targets in a frame — a window's strip, a band's grip strip and a toolbar band are all 46 px — so any
composition of docked frames lines up, on every side. No strip is thickened, no side is special-cased, and
no constant is added to make one composition look right.

---

## §0 Orientation

### What this workspace is (one hop each)

Fizzygum is a CoffeeScript GUI framework drawn on one `<canvas>`. Three sibling repos under
`/Users/davidedellacasa/code/Fizzygum-all/`: `Fizzygum/` (source; the only place behaviour is edited),
`Fizzygum-tests/` (the SystemTest suite and its references), `Fizzygum-builds/` (generated; never edited).
Read `Fizzygum-all/CLAUDE.md`, `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md` before the first command.
Every build and test command goes through the wrapper, by ABSOLUTE path:
`/Users/davidedellacasa/code/Fizzygum-all/fg <cmd>` (bare `fg` prints the roster).

### Why this plan exists

The docking mechanism is general: any frame docks into any edge slot of a window (arc "View-mode and dock
conformance", Fizzygum `70867283`, Fizzygum-tests `7a642ccbe`). The owner docked a document into the bottom
of a Docs Maker and a second text toolbar at its left, and saw that the left toolbar stands 12 px past the
grey grip strips of the bands above and below it.

### The critical reframe

The step is NOT "a vertical title bar is thinner than a horizontal one". Every strip is 46 px across, both
ways. What has two depths is *a row of chrome targets*:

| Row | Across | Made of |
|---|---|---|
| a window's strip, a band's grip strip | 46 | 1 px border + one row of 44 px targets + 1 px rule |
| a toolbar band | 58 | 1 px border + 6 px air + the 44 px cell + 6 px air + 1 px border |

The 12 px is the two 6 px of air: the theme's `toolCrossPadding`. Remove it and a band is one row of cells
and its two border lines: 46, a strip's thickness.

The second reframe: that air is today the ONLY margin around a picture tool, because a picture fills its
whole 44 px cell. The margin has to move from the band INTO the cell: the cell stays the 44 px target, and
the picture stands in a 32 px **mark box** centred in it (6 px inside the cell, exactly the margin it has
today). "A target and its mark are separate dials" is already the house rule (ruling G3) for strip buttons
and for the overflow chevron; the picture tools are the one place that does not follow it yet.

### What the owner decided, and what is deferred

- DO: thin bands, with the picture tools drawn smaller, as prototyped.
- AWARE AND ACCEPTED: many picture faces look rough at 32 px on the non-anti-aliased software backend,
  because they scale a fixed drawing (the old icon mechanism). They are NOT redrawn in this plan. Their
  size-aware redraw is filed (`docs/BACKLOG.md`, this plan's section; detail in `## BACKLOG detail` below).

---

## §0.5 Cold-execution protocol

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status`. Both repos must be level with their remotes and
   the build FRESH. The only uncommitted files allowed in `Fizzygum/` are this plan and `docs/BACKLOG.md`
   (this plan's section), in case the plan was handed over before its commit; `Fizzygum-tests/` must be
   clean. Anything else: stop and report.
2. Read, in this order: this whole file; `Fizzygum/docs/architecture/visual-design-system.md` §4.2 and the
   paragraph starting "**The tool cell**"; `Fizzygum/docs/architecture/toolbars.md` §1–§3;
   `Fizzygum/docs/architecture/widget-authoring-guidelines.md` (the checklist);
   `Fizzygum/docs/architecture/lint-and-static-checks.md` §3b (how a gate finding is answered).
3. Do the phases IN ORDER. Each phase ends with its own check. Do not recapture references before Phase 4:
   between Phases 1 and 3 the suite is EXPECTED to fail on pixels, and that is not a signal.
4. Line numbers in this file drift. The quoted code and the method names are the authority: grep them fresh.
5. Rules that have each cost a re-run before:
   - never pipe a gating `fg` call through `| tail` / `| grep` (the pipe hides the exit code);
   - one long `fg` operation at a time; launch a long one with the Bash tool's `run_in_background: true`,
     output to a log file, and wait for the completion notice (no foreground polling loops);
   - a running long operation owns `src/` and `tests/`: do not edit them until it ends;
   - absolute paths and `git -C <abs-repo>` always; never `git stash` in these repos;
   - never aim a recursive delete at `Fizzygum-builds/latest/js/tests` (a symlink into the real suite);
   - ad-hoc Node probes live under `Fizzygum-tests/.scratch/` (gitignored), never elsewhere.
6. A gate that fires is answered by its CLASS, never by bending the design: an invariant is fixed at its
   cause; a convention is met; a budget (a method-count or complexity ceiling) may be raised in the same
   change with a dated reason beside the number (owner ruling 2026-11-16: the right shape over the count).
7. Comments and docs are a deliverable. Present tense only: the `comment-narration` stink fails the build on
   words like "no longer", "now", "used to", "previously" in a source comment.
8. **Never commit or push without the owner's word.** At the end present a summary, the two commit messages
   and the review page, then wait. Commit with `git commit -F <absolute path to a message file>` (backticks
   in a shell-quoted message get corrupted).
9. Give an ETA before each long operation and a status line about every five minutes while it runs.

---

## §1 The mechanism as it stands (verified 2026-11-23 at Fizzygum `70867283`)

### §1.1 A strip's thickness

`src/FrameWdgt.coffee`, `_barSpec`:

```coffee
    thickness: theme.frameBorderWidth + theme.barIconSize + theme.barRuleWidth
    slotSize: theme.barIconSize
```

`src/Theme.coffee`: `@frameBorderWidth = 1`, `@barIconSize = 44`, `@barRuleWidth = 1`. So 46, for every
frame and both axes. This plan does not touch it.

### §1.2 A toolbar band's depth

The chain, each link read at every measure (nothing is stored):

1. `src/Theme.coffee` (around line 959):
   ```coffee
       @toolThumbnailSize = 44
       @toolInternalPadding = 6
       @toolAlongPadding = 8
       @toolCrossPadding = 6
       @toolRows = 1
   ```
2. `src/app-kit/ToolPanelWdgt.coffee`: the readers `_cellSide`, `_minimumGap`, `_alongPadding`,
   `_crossPadding`, `_stripDepthInCells`, and
   ```coffee
     naturalGridCrossExtent: ->
       @_naturalRunFor @_stripDepthInCells(), @_crossPadding()
   ```
   which is `1 * (44 + 6) - 6 + 2 * 6 = 56`.
3. `src/app-kit/ToolbarWdgt.coffee`: `dockThickness: -> @contents.naturalGridCrossExtent()`.
4. `EdgeDockLayoutSpec.thicknessGrantedTo` hands that to the band's frame, and
   `FrameWdgt._bandThicknessUnder` adds the frame's own two border lines
   (`_chromeBesidesStripsAcross`): `56 + 2 = 58`.

`_crossPadding()` is called in four methods, all in `ToolPanelWdgt.coffee`: the provisional seat in
`_addNoSettle`, `naturalGridCrossExtent`, `naturalGridExtentWithin` (twice), and the `paddingX` / `paddingY`
choice in `_layOutOwnContents` (twice). `toolCrossPadding` is read nowhere else in `src/`, the harness or the tests
(grep both repos again before deleting it).

### §1.3 Measured today (software backend, density 1)

A Docs Maker 660 × 710 at (20, 20), its own text toolbar on top, a second text toolbar docked left, its
info document docked at the bottom:

| | Box | Its grip strip | Its payload |
|---|---|---|---|
| top band | 642 × 58 | 46 × 58 (down its left) | 595 × 56 |
| left band | 58 × 213 | 58 × 46 (across its top) | 56 × 166 |
| bottom band (a document) | 642 × 318 | 46 × 318 | 595 × 316 |
| a floating vertical text toolbar | 58 wide | | |

Collapsing the top band moves the page under it: the band goes 58 → 46 high and the page's top 132 → 120.

### §1.4 The tool cell

`src/GlassBoxBottomWdgt.coffee` (core part), a `BoxWdgt` built at `toolCellCornerRadius`. Its layout:

```coffee
  _reLayoutSelf: ->
    @_repaintAsOneUnit =>
      thumbnailSize = @width()
      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()
      for w in childrenNotHandlesNorCarets
        if w.isTextSizedGlassBoxItem?()
          w._applyMoveTo @topLeft().add((new Point 0 ,(@height() - w.height())/2 ).round())
        else
          if w.idealRatioWidthToHeight?
            ...                       # aspect-fit into thumbnailSize
          else
            w._applyExtent new Point thumbnailSize, thumbnailSize
          w._applyMoveTo ...          # centred in the cell
```

Every child, the tool and the lid alike, is sized to the cell's whole side. Two more members matter:

```coffee
  thumbnailClickReceiver: ->
    @lid ? @glassBoxItem()
```

"the widget a TAP on me actually reaches": the lid when the cell has one, else the tool. And the fill it
paints for its state, `_fillForMyState`, which `BoxyAppearance.fillOutline` paints over the cell's WHOLE box.

`buildSystem/check-complexity-ratchets.js` records `'GlassBoxBottomWdgt#_reLayoutSelf': 17`.

### §1.5 The tool families (who is the target, who draws the picture)

`ToolPanelWdgt._addNoSettle` wraps each tool in a cell, and puts a lid (`GlassBoxTopWdgt`) over a tool that
is not `actionableAsThumbnail`.

| Family | Base class | Target of a tap | The picture is | Count |
|---|---|---|---|---|
| Template (any widget, dragged out) | anything | the LID, cell-sized | the tool widget itself | most Slides / Dashboards cells |
| creator button | `CreatorButtonWdgt` (`src/app-kit`) | the tool | its own icon appearance | 24 classes, and their shared base `ToolbarCreatorButtonWdgt` |
| paint tool | `CodeInjectingSimpleRectangularButtonWdgt` (`src/authoring`) | the tool | its `faceWidget`, an `IconWdgt` | 4 tools |
| text / sheet tool | `EditorContentPropertyChangerButtonWdgt` (`src/authoring`), an `IconWdgt` | the tool | its own icon appearance | 14 classes |

All 24 creator buttons paint through `IconAppearance` (20 of them) or `SizeAwareIconAppearance` (4), verified
by listing each subclass's `createAppearance`.

Most text and sheet faces are GLYPHS drawn for the whole 44 px cell, carrying their own white space (about
20 px of ink): the script A, B, I, `</>`, A+ / A−, the align trio, the Templates page, the two decimals.
Three faces break the family pattern:

- `FillColorButtonWdgt` (the paint bucket) and `SliderInCellButtonWdgt` (the slider node) are text-family
  tools whose face is a PICTURE that fills the cell.
- `UsefulTextSnippetsToolbarCreatorButtonWdgt` (in the Super toolbar) is a creator whose face is the
  Templates GLYPH (`TemplatesIconAppearance`), the same face the text toolbar's `TemplatesButtonWdgt` wears.

### §1.6 The dial that already separates a mark from its target: `glyphSize`

`src/icons/IconAppearance.coffee`, `calculateRectangleOfIcon`:

```coffee
    glyphSide = @widget.glyphSize
    height = if glyphSide? then Math.min boxHeight, glyphSide else boxHeight
    width = if glyphSide? then Math.min boxWidth, glyphSide else boxWidth
```

`SizeAwareIconAppearance` and `TypedFaceIconAppearance` read `@widget.glyphSize` too. The convention is
"whoever PLACES me writes it": `FrameBarWdgt` writes `piece.glyphSize` for each strip piece,
`SwitchButtonWdgt` for each of its buttons, and `ToolPanelWdgt._layOutOverflowChevron` writes
`@overflowChevron.glyphSize = WorldWdgt.theme.toolOverflowGlyphSize` at every arrange. The value only ever
SHRINKS the mark (`Math.min`), so a tool pictured in a smaller box (a toolbar overflow menu's row) still
fills that box.

`glyphSize` is declared on `IconButtonWdgt`, `SwitchButtonWdgt`, `MenuRowIndicatorWdgt` and
`BreadcrumbSeparatorWdgt`. It is NOT declared on `CreatorButtonWdgt`, `IconWdgt`,
`EditorContentPropertyChangerButtonWdgt` or `CodeInjectingSimpleRectangularButtonWdgt`.

A button's face widget gets its box from a soft hook, `src/ButtonWdgt.coffee`, `_reLayout`:

```coffee
      faceRoom = newBoundsForThisLayout.insetBy @padding
      @faceWidget._applyGrantedBounds (@_faceBoundsIn?(faceRoom) ? faceRoom)
```

(`SimpleButtonWdgt` is the one class defining `_faceBoundsIn` today.)

### §1.7 The state plate

`src/basic-widgets/BoxyAppearance.coffee`: `paintIntoAreaOrBlitFromBackBuffer` sets the fill and calls
`@fillOutline ctx`, which is `context.fillRoundRect 0, 0, @widget.width(), @widget.height(), @_roundRectRadii()`.
The same class answers `shapeContainsPoint` (the hit shape), `outlineCornerRadii` (the clip of the cell's
children) and

```coffee
  opaqueCoveredRect: ->
    @widget.boundingBox().insetBy Math.max(@_cornerRadii()...) + 1
```

(the rectangle the world may treat as hidden behind this widget's opaque fill).

The overflow chevron stands in no cell and paints the same plate itself,
`src/app-kit/OverflowChevronAppearance.coffee`:

```coffee
        ctx.fillStyle = plateFill.toString()
        ctx.fillRoundRect 0, 0, @widget.width(), @widget.height(), WorldWdgt.theme.toolCellCornerRadius
```

---

## §2 Why it is shaped this way

- The toolbar grid came from a visual draft: cells 44, least gap 6, 8 along the ends, 6 across, "so a
  one-row strip is 56 deep" (`visual-design-system.md`, the row "Embedded toolbar with its title strip").
  The strip's 46 came from a different rule, the 44 rule plus the frame's own two lines. Nothing ever
  compared the two numbers, because until docking became general a toolbar was the only thing in a slot and
  it sat alone under the window's strip.
- A Template's thumbnail fills its cell because a cell was first a "glass box" around a live widget: the
  widget is simply resized to the box. The creator buttons inherited the same full-cell picture.
- The text tools were redrawn later as size-aware glyphs with their own white space, which is why two
  conventions for "where is the margin" coexist in one toolbar family today.

---

## §3 The distilled argument

1. **One depth is the only fix that holds for every composition.** Making side strips 58 fixes the reported
   picture and leaves a side band's own grip (46 tall) unequal to a top band's (58 wide), and the window's
   strip (46) unequal to the toolbar under it (58). Making every strip 58 is uniform and costs 12 px on
   every window and band at every nesting depth, in a system whose point is nesting.
2. **Touch is unaffected.** The cell is the target and stays 44 × 44; the air was never a target (a press
   there lands on the panel).
3. **The margin belongs to the cell, because a toolbar accepts any widget as a tool.** A dropped widget
   brings no white space of its own; a margin that lives in each drawing cannot cover it, a mark box can.
4. **The mechanism exists.** `glyphSize` already draws a mark smaller than its target, and a cell already
   knows which child a tap reaches (`thumbnailClickReceiver`). The plan adds one dial and one declaration,
   and deletes one dial.
5. **A side effect worth having:** a collapsed band is its strip (46). With bands at 46, collapsing a top
   toolbar leaves the page where it is.

Prototyped in the page with no source change (see §9): the numbers of §4 were MEASURED on that prototype.

---

## §4 The target state (measured on the prototype)

The composition of §1.3:

| | Today | Target |
|---|---|---|
| top band | 642 × 58, payload 595 × 56 | 642 × 46, payload 595 × 44 |
| left band | 58 wide, payload 56 wide | 46 wide, payload 44 wide |
| left band's right edge vs the top and bottom bands' strip's right edge | 12 px past | equal |
| a floating vertical toolbar | 58 wide | 46 wide |
| collapsing the top band | page top 132 → 120 | page top 120 → 120 |

One cell of each family, at the target:

| Family | The cell | What a tap reaches | The picture |
|---|---|---|---|
| Template under a lid | 44 × 44 | the lid, 44 × 44 | the tool, 32 × 32, 6 px in from the cell on both axes |
| creator button | 44 × 44 | the tool, 44 × 44 | drawn at `glyphSize` 32, centred |
| paint tool | 44 × 44 | the tool, 44 × 44 | its face widget, 32 × 32, 6 px in |
| text / sheet glyph tool | 44 × 44 | the tool, 44 × 44 | as today (no `glyphSize`) |

A picture with a locked aspect ratio (`idealRatioWidthToHeight`) fits the 32 box on its longer side, as it
fits the 44 box today.

The state plate (hover, pressed, active): the cell's box 3 px in on every side, 38 × 38, radius 6.

---

## §5 The fix, by phase

Names below (`toolMarkSize`, `toolCellPlateInset`, `drawsFaceInToolMarkBox`, `_seatAtSide`,
`ToolCellAppearance`, `fillStatePlate`) are this plan's proposals. Keep them unless a gate, or a reading of
the neighbouring code, gives a better one; if you rename, rename everywhere, docs included.

### Phase 1 — thin bands

1. `src/Theme.coffee`: delete `@toolCrossPadding = 6`. Rewrite the comment block above the grid dials so it
   states the present design: the grid has padding ALONG the strip only; a one-row strip is one cell deep,
   44, so its band is 46 with the card's two border lines, a strip's thickness.
2. `src/app-kit/ToolPanelWdgt.coffee`: delete the reader `_crossPadding` and the padding it supplied at its
   four call sites. Where a helper takes a padding argument for the cross axis (`_cellsFittingIn`,
   `_naturalRunFor`, `_slotOffsets`) the cross axis passes none (0); the along axis keeps
   `@_alongPadding()`. The provisional seat in `_addNoSettle` becomes `@topLeft()`. Update every comment in
   the file that names the cross padding (the class header, "my grid's dials", `naturalGridCrossExtent`,
   `naturalGridExtentWithin`, `_layOutOwnContents`).
3. `src/app-kit/ToolbarWdgt.coffee`: the comment on `dockThickness` says "plus the grid's cross padding";
   make it true.
4. Grep both repos for `toolCrossPadding`, `_crossPadding`, `cross padding`, `56 deep`: nothing may remain
   but this plan and the archive.

**Check:** `/Users/davidedellacasa/code/Fizzygum-all/fg build` (exit 0). Then measure the composition of
§1.3 with a probe (§9 has one ready): the "Target" column of the first table of §4 must hold, including the
collapse row. Do not run the suite for pixels yet.

### Phase 2 — the mark box

1. `src/Theme.coffee`, beside the grid dials: `@toolMarkSize = 32`, with a comment that states what it is:
   the side of the box a tool's PICTURE stands in, centred in its cell, the cell staying the target (G3);
   the 6 px it leaves around a picture is the margin a picture keeps from the band's border.
2. `src/GlassBoxBottomWdgt.coffee`, `_reLayoutSelf`: seat each child by its ROLE. Sketch:

   ```coffee
     _reLayoutSelf: ->
       @_repaintAsOneUnit =>
         markSide = WorldWdgt.theme.toolMarkSize
         target = @thumbnailClickReceiver()
         for w in @childrenNotHandlesNorCarets()
           # a menu item is sized to its text
           if w.isTextSizedGlassBoxItem?()
             w._applyMoveTo @topLeft().add((new Point 0, (@height() - w.height()) / 2).round())
           else if w is target
             # what a tap on me reaches is the TARGET: my whole box. A tool that is its own target draws
             # its picture inside that box, at the side I name, when it says its face is a picture.
             w.glyphSize = markSide if w.drawsFaceInToolMarkBox
             @_seatAtSide w, @width()
           else
             # a tool under my lid is the MARK: it stands in the mark box
             @_seatAtSide w, markSide

     # size `w` to a square of `side` (to the side's fit of its own ratio, where it locks one) and
     # centre it in my box
     _seatAtSide: (w, side) ->
       if w.idealRatioWidthToHeight?
         ratio = w.idealRatioWidthToHeight
         if ratio > 1
           w._applyExtent new Point side, side / ratio
         else
           w._applyExtent new Point side * ratio, side
       else
         w._applyExtent new Point side, side
       w._applyMoveTo @topLeft().add((new Point (@width() - w.width()) / 2, (@height() - w.height()) / 2).round())
   ```

   Write `glyphSize` BEFORE seating the tool: a button lays its face out when its box is applied (§1.6).
   The split into `_seatAtSide` is a real seam and brings `_reLayoutSelf` under its recorded complexity
   (17): lower that record in `buildSystem/check-complexity-ratchets.js` to what the build's NOTE prints.
   Rewrite the class header comment so it states the two roles.
3. The declaration, a class-level field beside each family's `actionableAsThumbnail: true`, with a comment
   saying what it declares (my face is a PICTURE that fills its box, so the cell I stand in names the side
   it is drawn at; a face drawn as a glyph for the whole cell carries its own white space and says false):

   | Class | `drawsFaceInToolMarkBox` | Also |
   |---|---|---|
   | `CreatorButtonWdgt` | `true` | declare `glyphSize: undefined` |
   | `UsefulTextSnippetsToolbarCreatorButtonWdgt` | `false` (its face is the Templates glyph) | |
   | `CodeInjectingSimpleRectangularButtonWdgt` | `true` | declare `glyphSize: undefined`; define `_faceBoundsIn` (below) |
   | `EditorContentPropertyChangerButtonWdgt` | `false` (the family's faces are glyphs) | declare `glyphSize: undefined` |
   | `FillColorButtonWdgt`, `SliderInCellButtonWdgt` | `true` (their faces are pictures) | |

   Each `glyphSize` declaration carries a comment in the spirit of `IconButtonWdgt`'s: the side my picture
   is drawn at inside my box; the cell I stand in writes it; unset, my picture fills my box.

   The paint tool seats its face widget in that side, through the existing soft hook:

   ```coffee
     # MY FACE'S BOX in the room my padding leaves: the mark box my cell names (glyphSize), centred;
     # all of the room while no cell has named one.
     _faceBoundsIn: (room) ->
       return room unless @glyphSize?
       side = Math.min @glyphSize, room.width(), room.height()
       origin = new Point room.left() + Math.round((room.width() - side) / 2), room.top() + Math.round((room.height() - side) / 2)
       origin.extent new Point side, side
   ```

   The cell (core part) reads a FIELD and names no class of a lazy part, which is what
   `buildSystem/check-part-edges.js` requires.
4. Result to expect: the same face has the same size in every toolbar (the Templates glyph in the text and
   Super toolbars; the slider node in the Patch programming and sheet toolbars).

**Check:** `fg build` (exit 0), then the second table of §4 with the probe (it prints one cell of each
family and one lidded cell: boxes, `glyphSize`, face box, what a tap reaches). Then look at the probe's
gallery picture: no picture may touch a band's border.

### Phase 3 — the state plate stands inside the cell (planner's addition; the owner may strike it)

With the air gone, a cell's hover, pressed and active plate reaches both border lines of its band. The
target stays the cell; the PAINTED plate moves 3 px in.

1. `src/Theme.coffee`, beside the tool cell's fills: `@toolCellPlateInset = 3`, commented.
2. New file `src/ToolCellAppearance.coffee` (core, beside `GlassBoxBottomWdgt.coffee`; one class per file):

   ```coffee
   class ToolCellAppearance extends BoxyAppearance

     # my fill is the STATE PLATE: my widget's box, toolCellPlateInset in on every side, rounded at the
     # tool cell's radius. My shape and my children's clip stay my widget's whole box: the cell is the
     # target, the plate only what its state paints (G3).
     fillOutline: (context) ->
       ToolCellAppearance.fillStatePlate context, @widget.width(), @widget.height()

     # THE PLATE for a `width` x `height` tool-cell-sized box, in the fill the context already carries.
     # ONE geometry for every wearer of the look: my cells, and the overflow chevron, which stands in
     # no cell (OverflowChevronAppearance).
     @fillStatePlate: (context, width, height) ->
       theme = WorldWdgt.theme
       inset = theme.toolCellPlateInset
       context.fillRoundRect inset, inset, width - 2 * inset, height - 2 * inset, theme.toolCellCornerRadius

     # what my fill hides is inside the PLATE, never my whole box
     opaqueCoveredRect: ->
       (@widget.boundingBox().insetBy WorldWdgt.theme.toolCellPlateInset).insetBy WorldWdgt.theme.toolCellCornerRadius + 1
   ```

   ⚠ `opaqueCoveredRect` is not optional. The inherited answer claims the cell's box inset by radius + 1 as
   hidden behind the fill; it happens to stay inside a plate inset by up to 5 px, and a claim that is right
   by arithmetic coincidence is the bug class `BubblyAppearance`'s own `opaqueCoveredRect` comment records.
3. `src/GlassBoxBottomWdgt.coffee`: wear it. Follow `widget-authoring-guidelines.md` on the
   `createAppearance` factory: after `super`, `@appearance = @createAppearance()`, with
   `createAppearance: -> new ToolCellAppearance @`.
4. `src/app-kit/OverflowChevronAppearance.coffee`: replace its own `fillRoundRect` with
   `ToolCellAppearance.fillStatePlate ctx, @widget.width(), @widget.height()`; update its header comment
   (the plate is the cell's plate, inset; the SHAPE stays the whole box rounded).
5. Do not change any `shapeContainsPoint`.

**Check:** `fg build`, then the probe's composition picture: the hovered "B" in the left band and the
active align tool in the top band show a 38 × 38 plate with 3 px to each border line.

### Phase 4 — tests

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg presuite > /tmp/fg-presuite-run.log 2>&1` in the
   background (about 4 min). EXPECT many failures. Read the failure list from the summary's
   `failed tests (N): [...]` line, then for the assertion failures grep `FAIL (assertion)` in the log (the
   single runner's summary shows only its last dozen assertion lines).
2. Sort every failing test into one of two kinds:
   - **an assertion fails**: its premise names the old geometry. Fix the TEST's premise, never by reading
     the product's own rule for the expected value. Candidates found by grep:
     `SystemTest_macroToolbarGridPacksAndSpreadsOnlyWhenFull` (it computes a pitch from the theme),
     `SystemTest_macroDockOutlineIsTheBandItMakes`, `SystemTest_macroGripStopsWhereDockedBarsStayUsable`,
     `SystemTest_macroDockAnyFrame`.
   - **pixels only**: recapture in step 5.
   ⚠ When a default changes, also re-read the tests that still PASS and lean on it: a test that clicks a
   Template by a fixed offset inside its cell may now press the cell's ring. Grep `tests/` for macros that
   press inside a toolbar by anything other than a live widget's own centre.
3. Author ONE new SystemTest with the `/author-macro-test` skill of `Fizzygum-tests`
   (`.claude/skills/author-macro-test/`): `SystemTest_macroToolbarBandIsAsDeepAsAStrip`. It builds the
   composition of §1.3 plus one floating toolbar of each family, and asserts, with LITERAL expected values
   (44, 32, 38 and equalities between independently laid-out widgets, never a theme dial or a product
   method):
   - the left band's right edge equals the right edge of the top band's grip strip and of the bottom
     band's; the left band's width equals the top band's height equals the window strip's height;
   - every visible cell of every toolbar is 44 × 44, and what a tap on it reaches is 44 × 44;
   - a lidded Template is at most 32 on its longer side and centred in its cell; a creator's and a paint
     tool's picture box is 32; a text glyph tool carries no `glyphSize`;
   - collapsing the top band (through its collapse piece, by the macro toolkit) leaves the page's top
     where it was;
   - screenshots: the composition at rest; one cell hovered; one tool active.
   Its four metadata fields (`intent`, `scenario`, `assertions`, `provenance`) are mandatory. It destroys
   everything it builds.
4. Prove the new test BITES, with plants under `Fizzygum-tests/.scratch/band-depth-plants/` run through
   `node scripts/run-macro-test-headless.js SystemTest_macroToolbarBandIsAsDeepAsAStrip --prelude=/abs/plant.js`.
   Each plant must make the test fail by an assertion line that names the planted fact; read the lines.
   Plant skeleton (it waits for the class it patches):

   ```js
   (function () {
     var tries = 0;
     var tick = function () {
       if (typeof ToolPanelWdgt === 'function' && ToolPanelWdgt.prototype.naturalGridCrossExtent) {
         var original = ToolPanelWdgt.prototype.naturalGridCrossExtent;
         ToolPanelWdgt.prototype.naturalGridCrossExtent = function () { return original.call(this) + 12; };
         console.log('PLANT_APPLIED band-12px-deeper');
         return;
       }
       if (++tries > 6000) { console.error('PLANT_NOT_APPLIED band-12px-deeper'); return; }
       setTimeout(tick, 5);
     };
     tick();
   })();
   ```

   At least three plants: the band 12 px deeper (the alignment assertions fail); the cell seating a lidded
   tool at the cell's side (the mark assertions fail); the cell seating its target at the mark side (the
   "what a tap reaches is 44 × 44" assertion fails).
5. Follower proof, both pointers, zero `WORLD_INVENTORY_` lines:
   `node scripts/run-sequence-headless.js SystemTest_macroToolbarBandIsAsDeepAsAStrip SystemTest_macroAnalogClockInspectEdit`
   and the same with `--pointer=finger`.
6. Recapture, AFTER a fresh build and with no further source edit (a later edit trips the stale-build
   guard), each in the background, one at a time:
   - `/Users/davidedellacasa/code/Fizzygum-all/fg recapture --auto --dprs=1,2`
   - `/Users/davidedellacasa/code/Fizzygum-all/fg recapture --auto --pointer=finger --dprs=1,2`
   Each must end `RECAPTURE COMPLETE`. A test it files as *needs-a-fix* or *UNSTABLE* is a finding to
   work, never something to recapture again. A new finger reference that differs from its mouse twin is a
   translation defect until proven otherwise.
7. Look before trusting: `fg diffpage` on three tests of different Makers (a Docs test, a Slides test, a
   Draw test), and check that the only differences are the band depth, the picture sizes and the plate.

### Phase 5 — docs and backlog

Weave, never append; present tense.

- `docs/architecture/visual-design-system.md`:
  - the METRICS row of the tokens table: `toolCrossPadding` leaves the list, `toolMarkSize` and
    `toolCellPlateInset` join it;
  - §4.2: one sentence that a tool's picture stands in the mark box inside its 44 cell;
  - the "**The tool cell**" paragraph: the plate is inset; the two roles (target, mark); which faces are
    glyphs for the whole cell and which are pictures (`drawsFaceInToolMarkBox`);
  - the components row "Embedded toolbar with its title strip": a one-row strip is one cell deep, its band
    46, a strip's thickness; no padding across.
  - the sentence on `glyphSize` in the icons section ("A widget with a `glyphSize` (a chrome button sized
    to its whole target) …"): a tool that is its own target in a cell is the second case.
- `docs/architecture/toolbars.md`: where a cell is described (the bullet naming `actionableAsThumbnail`),
  add the two roles, the mark box, and the rule for a new tool: a tool that is its own target and whose
  face is a picture declares `drawsFaceInToolMarkBox: true` and a `glyphSize` field. State that a band is
  as deep as a strip. Leave its "verified against src on" date alone unless you re-verify the whole
  document.
- `src/macros/MACRO-PATTERNS.md`: re-read the toolbar section (around "theme.toolThumbnailSize +
  theme.toolInternalPadding") and correct anything the change falsifies.
- `docs/BACKLOG.md`, this plan's section: delete the "Phases 1–6" line; keep the icon item. Run
  `node buildSystem/check-doc-narration.js` (exit 0) after touching it: an item over 325 characters fails
  the gauntlet's `refs` leg.

### Phase 6 — close

1. `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet > /tmp/fg-gauntlet-run.log 2>&1` in the background
   (about 26 min; 20 legs). Every leg PASS. Then `/Users/davidedellacasa/code/Fizzygum-all/fg homepage`.
2. Build a LOCAL before/after review page (HTML with the images embedded, at most 780 px wide, opened with
   `open`; the owner's standing preference, never a hosted page): the composition of §1.3 and the
   nine-toolbar gallery, today's renders beside the new ones.
3. Close the arc with the `/close-arc` skill: `git mv` this plan to `docs/archive/`, stamp its status, add
   its line to `docs/archive/INDEX.md`, move the section heading in `docs/BACKLOG.md` to the archive path
   (the open icon item stays), fill `## BACKLOG ledger`.
4. Present the summary, the two commit messages and the page. **Wait for the owner before committing.**

---

## §6 Central risks

| Risk | How it shows | Answer |
|---|---|---|
| A paint tool's face is not re-seated when only `glyphSize` changes | the face stays 44 × 44 in the probe's family row | `glyphSize` is written before the tool's box is applied (Phase 2 step 2); if the box is unchanged across a later arrange the face already stands in its box |
| The picture of a tool in the toolbar's overflow menu changes | a `»` menu row's miniature shrinks | it cannot: `glyphSize` only caps (`Math.min`), and a row's box is smaller than 32; verify one `»` menu by eye |
| A Template dragged out of a toolbar takes the wrong size | the dropped widget is 32 × 32 | `extentToGetWhenDraggedFromGlassBox` is recorded at add, before the cell sizes anything; covered by the existing drag-out tests |
| A cell whose lid has left (`_reactToChildRemoved`) | its tool fills the cell again | accepted: the tool is then its own target and keeps the box, as today; reachable only through the developer's "Attach" |
| `opaqueCoveredRect` over-claims after the plate moves in | stale pixels around a hovered cell; the gauntlet's `paint` leg | Phase 3 step 2 overrides it |
| A new class is unreached or mis-ordered at boot | the build's shippable-coverage gate, or the boot smoke | `new ToolCellAppearance @` is written literally in `GlassBoxBottomWdgt` (the dependency scan reads that form) |
| A ratchet fires (method count, complexity, comment narration) | the build names it | §0.5 item 6 |
| The recapture is large (every test that shows a toolbar) | hundreds of references in two pointer kinds and two densities | `fg recapture --auto` with its completeness gate; never hand-pick a footprint |

---

## §7 Verification protocol (summary)

| When | Command | Passes when |
|---|---|---|
| after each of Phases 1–3 | `fg build` | exit 0 |
| after each of Phases 1–3 | the probe of §9 | the tables of §4 hold |
| Phase 4 | `fg presuite` | only expected failures, each sorted |
| Phase 4 | the new test, its three plants, its two follower runs | the test passes; each plant fails it by its own line; zero `WORLD_INVENTORY_` lines |
| Phase 4 | `fg recapture --auto --dprs=1,2`, then with `--pointer=finger` | `RECAPTURE COMPLETE` twice |
| Phase 5 | `node buildSystem/check-doc-narration.js` (from `Fizzygum/`) | exit 0 |
| Phase 6 | `fg gauntlet`, `fg homepage` | all 20 legs PASS; homepage OK |

All `fg` commands by absolute path, never piped.

---

## §8 Rejected alternatives (do not re-attempt)

- **Strips down a side at 58** (prototyped, rendered). The reported composition lines up, and a side band's
  own grip stays 46 tall while a top band's is 58 wide; the window's strip still differs from its toolbar.
  Two thicknesses by axis with no rule behind them.
- **Every strip at 58** (prototyped, rendered). Uniform, 12 px thicker on every window and band at every
  nesting depth; a left band shows one tool fewer in the same height; nothing gained for touch.
- **Thin bands with the pictures left at 44** (prototyped, rendered). The pictures touch the band's
  borders: the Slides toolbar's dark rectangle and video tile span the whole band.
- **Shrinking every tool to the mark box, targets included.** A creator or a paint tool is its own target;
  at 32 it breaks the 44 rule ("a target never extends beyond the widget that owns it").
- **The cell writing `glyphSize` on every target tool.** The text glyphs are drawn for the whole cell;
  their ink goes from about 20 px to about 14.5 px.
- **Deciding by toolbar class** (the first prototype did). The Super toolbar's Templates glyph came out
  tiny and the sheet toolbar's bucket and slider stayed large: the fact belongs to the tool's face, not to
  the toolbar that holds it.
- **Keeping `toolCrossPadding` as a dial set to 0.** A dial whose only allowed value is "none" is a second
  home for the rule "a band is as deep as a strip".
- **Redrawing the picture faces in this arc.** Owner-deferred (2026-11-23); filed below.

---

## §9 References

- The owner's choice and the renders: a local page on the planner's machine,
  `Fizzygum-tests/.scratch/dock-geometry/review.html` (gitignored; this plan does not depend on it).
- The probe that measured §1.3 and §4, same folder: `node .scratch/dock-geometry/probe.js current` (run
  from `Fizzygum-tests/`) builds the composition and the nine-toolbar gallery against the CURRENT build,
  prints every band's box and one cell of each family, and writes `out/current-*.png`. Its variant
  `planned3` is the in-page prototype of this plan (it patches the page, so its numbers are the target
  even before any source change). Copy `out/current-*.png` aside before Phase 1 as the "before" pictures.
  If the folder is absent, write the same measurement as a fresh probe: boot
  `Fizzygum-builds/latest/worldWithSystemTestHarness.html?dpr=1&speed=normal&intro=0`, wait for
  `window.world.macroToolkit`, then `world.resetWorld()`,
  `host = world.openFrameWith(new DocumentWdgt(), new Point(660, 710), new Point(20, 20))`,
  `host.dockFrame(InfoDocs.createNextTo('SimpleDocumentApp', host), 'bottom')`,
  `host.dockFrame(new FrameWdgt(new TextToolbarWdgt()), 'left')`, and read `host.dockedFrames[side].bounds`,
  `.bar.bounds`, `.contents.bounds`. A floating toolbar that hugs its tools:
  `f = new FrameWdgt(new SlidesToolbarWdgt()); f.sizeToPayloadNaturalExtent(); world.add(f)`.
- Architecture: `docs/architecture/visual-design-system.md` (§4.1–§4.3, the tool cell, the components
  table), `docs/architecture/toolbars.md`, `docs/architecture/layout.md` (settle tiers, what a `_reLayout`
  may do), `docs/architecture/widget-authoring-guidelines.md`, `docs/architecture/lint-and-static-checks.md`.
- The docking arc this follows: `docs/specs/drag-embed-interaction-spec.md` §4.1;
  `docs/archive/frame-lifetime-and-docking-plan.md`; `docs/archive/toolbar-grid-and-bar-run.md` (the grid:
  pack, spread while full, the bar's side).
- The size-aware icon track the deferred item belongs to: `docs/plans/pixel-icons-plan.md` §5b and the
  local skill `/convert-icon-size-aware`.

---

## BACKLOG detail

### The toolbars' picture faces scale a fixed drawing

Owner-deferred on 2026-11-23, with the choice of this plan's shape: "most icons still follow the old icons
mechanism and they need a redesign and need to use the newer mechanism of rendering that is aware of the
size and draws well also in the sw renderer."

What is rough: on the software backend at density 1, a face that scales a fixed design space (an
`IconAppearance` with a `paintFunction`, or a live widget resized as a Template's thumbnail) loses its thin
lines and small text at the 32 px mark box. Seen worst on the speech bubble, the scooter, the plant, the box
of toys, the two maps and the plot faces of the Slides, Dashboards and Plots toolbars, and on Draw's four
tools.

What to do: redraw each as a size-aware face (`SizeAwareIconAppearance`: integer device-pixel geometry, one
line unit), one face at a time through the `/convert-icon-size-aware` skill and its owner review, as the
desktop icons and the text tools were (`docs/plans/pixel-icons-plan.md` §5b). Of the 24 creator buttons, 20
still paint through plain `IconAppearance`; the four paint tools' faces and the Templates' live thumbnails
are separate cases (a Template is a real widget, and its thumbnail may want a drawn face of its own).

What it would let go: once every face is drawn for the mark box, the glyph faces included, the
`drawsFaceInToolMarkBox` declaration has one answer and can be deleted, the cell naming the mark side to
every tool it seats as its target.

Reach: every Maker's toolbar, at a glance. Severity: low (a look, nothing refused or lost).

## BACKLOG ledger

**Landed (2026-11-23).** Phases 1–3 as written: `toolCrossPadding` deleted (a band 46 deep), `toolMarkSize` 32 and
the cell seating by role (`_seatAtSide`), `drawsFaceInToolMarkBox` and `glyphSize` on the four families (creators;
the paint tools, through `_faceBoundsIn`; the property tools, the bucket and the slider node saying true; the
Templates-glyph creator false), `ToolCellAppearance` with its `fillStatePlate` shared by the overflow chevron and
its own `opaqueCoveredRect`. Phase 4: the new `SystemTest_macroToolbarBandIsAsDeepAsAStrip`, its three plants each
failing it by its own line, its followers clean under both pointers, the end-of-cycle probe silent on it; 70
tests recaptured under the mouse and 66 under the finger (the mouse-only ones skipped) at densities 1 and 2,
`RECAPTURE COMPLETE` both times, nothing filed as needs-a-fix or UNSTABLE. Phase 5's docs, and the comment drift the mark box made in
`IconAppearance` and `SizeAwareIconAppearance` (a toolbar thumbnail named no glyph side).

**Deviations from the plan as written.**
- The complexity record `GlassBoxBottomWdgt#_reLayoutSelf` was DELETED, not lowered: the split took the function
  under the ceiling, and the gate reads a record of a function below it as stale.
- One test besides the plan's four candidates stated the old geometry in its premises:
  `SystemTest_macroCollapsedDockIsAnEdgeSliver` held a collapsed band thinner than the expanded one and an
  expanded grip taller than wide. A collapsed band is now exactly as thick as the expanded one, so the expansion is
  read by the collapsed state and the grip's place. The four candidates passed their assertions unchanged.
- Five tests shaped a floating toolbar into a column 58 wide, the width a one-column toolbar hugged; it is 46, and
  at 58 the column stood packed left with 12 px over. They shape it 46 wide.
- The new test's hovered cell is hovered AFTER a click into the page: a property tool with nothing to act on is
  dimmed and shows no hover plate.
- Step 7's `fg diffpage` was replaced by a comparison of the committed references with the recaptured ones (after a
  recapture a diff page has nothing to show) on a Docs, a Slides and a Draw test: the band, the pictures and the
  plate change, and content takes the room a thinner band gives (a slide scales up a little).
- One finger reference newly differs from its mouse twin, and it is no translation defect:
  `SystemTest_macroDrawingTakesNoClickPlacedWidget` image_1. The thinner floating Slides bar puts its text creator
  6 px nearer the desktop's left edge; the mouse lifts the made text after 7 px of travel, where it would stand at
  x = -5, so the grab fits it inside the desktop (`ActivePointerWdgt.grab`, `_moveWithin world`) and it lands 5 px
  right of the finger's, which lifts after 24 px with nothing to fit. Both behaviours predate this arc.

**Left open (BACKLOG).** The picture faces' size-aware redraw (below, "BACKLOG detail"); and what extent a
Template placed by a CLICK on its lid takes (see BACKLOG).

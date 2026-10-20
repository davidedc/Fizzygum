# The visual design system — where the look is decided, and the rules it follows

Fizzygum has ONE visual design system. Every colour a piece of chrome paints with, every chrome font,
every chrome dimension and every shadow is decided in one class, `src/Theme.coffee`, under a name that
says what it is FOR. This doc says what those names are, the rules a widget's look follows, how the
design maps onto the widget tree, and how a new widget picks its look.

The design itself — its tokens, its drawing rules and a reference drawing — lives with the redesign
plan that brings the system to it: [`../plans/redesign/UI-guidelines.md`](../plans/redesign/UI-guidelines.md)
(the rules and tokens), `desktop-canvas.html` (a flat Canvas-2D drawing of the target) and
[`../plans/redesign/redesign-plan.md`](../plans/redesign/redesign-plan.md) (which surfaces wear the
design so far, and the decisions behind each rule below).

---

## 1. One place decides the look: `Theme`

A world builds its theme as it is constructed: `WorldWdgt.theme`, a sibling of
`WorldWdgt.preferencesAndSettings`. The split between the two is the whole point:

- **`Theme` is the LOOK** — anything that changes only what the world looks like.
- **`PreferencesAndSettings` is BEHAVIOUR** — input, timing, thresholds (wheel scaling, drag and dwell
  thresholds, press-and-hold time, title-ellipsis rules).

A snapshot never saves or restores the theme: a look is not user state, so a restored world wears the
look of the page that loads it. A reader copies a theme value where it needs it (a constructor taking
its fill, a layout reading a metric); nothing holds the theme object itself.

`Theme` has five sections, all assigned in its constructor (a class-level declaration may not reference
another class, and most values are `Color`s):

| Section | What it holds |
|---|---|
| **PALETTE** | The design's named colours (§2), at the design's values. A palette colour paints nothing by itself. |
| **ROLES** | What each SURFACE paints with — `windowBarFill`, `menuRowText`, `speechBubbleStroke`, `seamRule`, … One role per surface: two surfaces that paint the same colour still hold two roles, so one can be restyled without moving the other. A role's value is either a palette colour (the surface wears the design: `@seamRule = @chrome`), a value the design gives that surface alone, outside the palette (`clockMark`, the clock's marks), or the exact value the surface painted with before it adopted the design. |
| **FONT ROLES** | `@fonts`: plain `{family, size, bold}` objects, optionally with a `lineHeight` (§3, the line box) — `menuRow`, `listRow`, `labelButton`, `menuHeader`, `windowTitle`, `buttonLabel`, `defaultText`, `tooltip`, `speechBubble`, `prompt`, `desktopCaption`, `memberName`, `memberKindTag`, `code`, `document`, and the text tools' typed faces `boldToolFace`, `italicToolFace`, `codeToolFace` (a role may also carry `italic`). |
| **METRICS** | Chrome geometry: the bar button's box (`barIconSize`) and the glyphs inside it (`barControlGlyphSize` for × − +, `barActionGlyphSize` for the pencil / eye), a menu row's glyph box (`menuRowGlyphSize`), its side inset, icon gap and hover-plate radius (`menuRowSideInset`, `menuRowIconGap`, `menuRowPlateRadius`; a list row's `listRowSideInset`, `listRowIconGap`), its two drawn indicators' glyph squares and gaps (the submenu chevron's `menuRowChevronSize` and `menuRowChevronGap` before it; the leading tick column's `menuRowTickSize` and `menuRowTickGap` after it), a pop-up's content padding and its header's rule and title inset (`menuContentPadding`, `menuHeaderRuleWidth`, `menuHeaderTitleInset`; a list's rows panel `rowsPanelPadding`), a group divider's band (`menuDividerGap`, `menuDividerRuleWidth`), the scroll indicator's edge inset (`scrollIndicatorEdgeInset`), a tooltip plate's rounding and paddings (`tooltipCornerRadius`, `tooltipHorizontalPadding`, `tooltipVerticalPadding`; its line box is `fonts.tooltip`'s), the frame's border width, the strip's rule and the body margin (`frameBorderWidth`, `barRuleWidth`, `frameBodyMargin`), the window and card corner radii, the menu row height, a plain handle's side (`handleSize`) and the frame grip's side and inset (`frameGripSize`, `frameGripInset`), the toolbar grid's cell, least gap and padding along and across the strip (`toolThumbnailSize`, `toolInternalPadding`, `toolAlongPadding`, `toolCrossPadding`, `toolRows`) and a docked band's inset from its host (`dockedBandInset`), the scroll indicator's resting and hovered widths, chrome corner radii, a button's height, horizontal paddings and rounding (`buttonHeight`, `buttonPaddingX`, `primaryButtonPaddingX`, `buttonCornerRadius`), the least side of a chrome target (`minimumTargetSize`), a footer band's height, rule, inset, button gap and grip clearance (`footerBandHeight`, `footerRuleWidth`, `footerInset`, `footerGap`, `footerGripClearance`), a toggle's and a chip's height, padding and rounding (`toggleHeight`, `togglePaddingX`, `toggleCornerRadius`; `chipHeight`, `chipPaddingX`, `chipCornerRadius`), the Object Inspector's bands (`breadcrumbBandHeight`, `breadcrumbInset`, `breadcrumbCaptionGap`, `breadcrumbGap`, `breadcrumbDonorGap`, `breadcrumbSeparatorSize`; `toggleBandHeight`, `toggleBandInset`, `toggleBandGap`; `inspectorRuleWidth`, `inspectorListColumnWidth`), a member row's geometry (`memberRowHeight`, `memberRowPlateHeight`, `memberRowPlateRadius`, `memberRowSideInset`, `memberRowTagGap`, `memberRowTagColumnWidth`, `memberRowsPanelPadding`), a code pane's padding (`codePanePadding`), the text caret's width and gap (`caretWidth`, `caretGap`), a document's item spacing and its items' rounding and text padding (`documentItemSpacing`, `documentItemCornerRadius`, `documentItemHorizontalPadding`, `documentItemVerticalPadding`), and a desktop icon's geometry, all from ONE knob, the tile's side (`desktopIconTile`, 64): the glyph square, the tile's rounding and the cell's width derive from it (`desktopIconGlyphSize`, `desktopIconTileRadius`, `desktopIconCellWidth`), the draft's fixed values sit beside it (`desktopIconPadding`, `desktopIconTilePlateGap`, `desktopIconPlateHorizontalPadding`, `desktopIconPlateVerticalPadding`, `desktopIconPlateRadius`, `desktopIconCaptionMaxLines`; the caption's line box is `fonts.desktopCaption`'s), and so do the icon's height and extent (`desktopIconHeight`, `desktopIconExtent`: one two-line pitch for every icon), the icon grid's gaps and origin (`desktopIconColumnGap`, `desktopIconRowGap`, `desktopIconGridOrigin`), the rows a folder window opens showing (`folderWindowIconRows`) and the bin's corner insets (`desktopBinRightInset`, `desktopBinBottomInset`); the desktop clock's side and corner insets (`desktopClockSize`, `desktopClockRightInset`, `desktopClockTopInset`). |
| **SHADOWS** | The ONE shadow every desktop object casts at rest (windows, menus, prompts, tooltips, icons, the clock) and the drag lift a carried widget takes (offset + alpha each), and `shadowColor`, the one colour every shadow silhouette is filled with. |

**The ratchet.** A colour literal in a chrome file is a look decided outside this system — a restyle
edits `Theme` and cannot reach it. The `raw-chrome-color` stink (`buildSystem/check-stinks.js`; table in
[`lint-and-static-checks.md`](lint-and-static-checks.md)) counts them outside content, icon art and the
colour plumbing, and only ever goes down. Its tolerated tail is listed there.

## 2. The palette

| Token | Value | Use |
|---|---|---|
| `ink` | `#1E1E1C` | Text and icon strokes; never large fills |
| `chromeDark` | `#4A4A46` | Reserved for a focused window (no focus state exists yet) |
| `chrome` | `#E2E2DE` | Title bars, the embedded toolbar strip, 1 px rules inside windows (`seamRule`), the disabled button outline |
| `line` | `#C9C9C4` | Control and tile borders, the title bar's bottom rule, the strip divider |
| `frame` | `#B9B9B4` | Frames of windows and menus |
| `chip` | `#D2D2CD` | Border of a chip that is not selected |
| `desk` | `#ECECE8` | Wallpaper, active tool button, highlighted menu row, pale fill inside icons |
| `plate` | `#F4F4F1` | Desktop icon label plates, the tooltip |
| `item` | `#F0F0EC` | A document paragraph item |
| `panel` | `#FAFAF8` | The Object Inspector's body |
| `paper` | `#FFFFFF` | Window content, tiles, menus, the clock face, buttons |
| `muted` | `#6A6A66` | Window title text and bar controls |
| `muted2` | `#8A8A85` | Secondary labels: "Class", `fn`, a menu header |
| `muted3` | `#A5A5A0` | Chevrons and breadcrumb separators |
| `text2` | `#55554F` | Text on toggles and chips that are off; a toolbar strip's glyph |
| `code` | `#3A3A36` | Source code text |
| `grip` | `#BDBDB8` | The resize grip's strokes |
| `disabledText` | `#B9B9B4` | Text of a disabled button |
| `accent` | `#2F5BEA` | Focused, selected and "on" ONLY — the text caret (the editing focus) included (the clock's second hand is the one exception: it is live) |
| `accentTint` | `#2F5BEA` at 12% | The fill of an "on" or selected control |
| `danger` | `#C4321C` | Destructive actions only |
| `scrollbar` | `rgba(30,30,28,0.35)` | The overlay scrollbar thumb |

## 3. Fonts

A text widget takes its font as a ROLE: `new StringWdgt text, fontRole: WorldWdgt.theme.fonts.windowTitle`
gives family, size and bold at once. An explicit `fontName` / `fontSize` / `bold` wins over the role's
member, so a caller can take a role and override one member. A text built without a role takes
`fonts.defaultText`. `StringWdgt` and everything built on it read the role; `LabelButtonWdgt` (default
`labelButton`), `MenuItemWdgt` (`menuRow` or `listRow`, by the panel that builds it; a `MemberRowWdgt` takes `memberName`, its kind tag `memberKindTag`) and `StringFieldWdgt`
forward it.

**The line box.** Every line of a text stands in a line box, answered from ONE home on `StringWdgt` (the
"THE LINE BOX" block: `linePitch`, `caretBoxInLine`, `caretTopLeftAt` and their private helpers), which wrapping,
measuring, box sizing, paint, selection, `slotCoordinates` / `slotAt`, the caret and the macro toolkit's text aims
all read. A role may carry `lineHeight`, its line box's height AT THE ROLE'S SIZE (an explicit `lineHeight` option
is stated at the size the text is set in); at any other size the pitch scales with the font's em box,
`round(lineHeight × fontHeight(size) / fontHeight(statedSize))`, so a line box is never shorter than its em box.
- **Unset** (no line height): the box is the em box, `fontHeight` = `ceil(1.2 × size)` tall, and a line is drawn
  `textBaseline "bottom"` at the box's bottom, its baseline the font's descent above it.
- **Set**: the baseline follows the design's explicit-line-height rule, `floor((pitch − (A + D)) / 2) + A`, with A
  and D the font box's ascent and descent rounded to whole pixels (measured on the widgets' own measuring context
  about the alphabetic baseline), and a line is drawn `"alphabetic"` at it. The design's formula is never applied to
  an unset text: at the em-box pitch it would put every baseline 1 px higher.
- The caret stands in the font's EM BOX within the line, `[baseline + D − P, baseline + D)` (P = `fontHeight`): the
  whole box when unset. Every caret wears one look: `caretWidth` (2) wide, or a twentieth of its height where that is
  wider, painted `caretFill` (the accent), `caretGap` (1) right of its slot's boundary (`CaretWdgt._myTopLeftAtSlot`;
  `slotCoordinates` and `caretTopLeftAt` keep the boundary). Following a caret through a scrolling field keeps its
  whole box inside the field less `viewPadding` at each side, so it stays visible at either edge; inside a viewport's
  plane the viewport's own follow keeps it in view instead (the two would disagree), and every follow pass reads its
  text re-fitted, so the pass run during a keystroke and the settle's confirming pass agree. A selection spans the whole line box, so a multi-line selection has no gaps.
- Every number is a whole logical pixel, so dpr 2 doubles each exactly. The line height is part of the wrap and
  back-buffer cache keys.
- Four roles state a line height, at the draft's values: `document` 22, `code` 18, `desktopCaption` 16, `tooltip` 16.
- A text dressed as a document item (§5) stands its line boxes in its text area, inset from its box.

**Typed icon faces.** The text tools' B, I and `</>` are TYPED from the atlases (`TypedFaceIconAppearance`; the
draft's serif and mono faces), in their font roles, which are stated at a tool cell's side: Times New Roman bold 20 and
italic 20, Courier New 15. They paint in the widget's logical coordinates inside the standard paint scope (crisp on
SWCanvas only there: in a device-pixel body a typed glyph comes out half size at dpr 2). In a box of side s the size is
the role's × s / `toolThumbnailSize`, snapped to 0.5 and kept within the atlases' 9–96; they are centred across by
their advance and down by the draft's "line centred in a taller box" rule, `round((h − (A + D)) / 2) + A`. A face's
family names the literal family first and the generic last (`"Times New Roman", serif`): SWCanvas picks an atlas by the
generic word, so a bare literal would type Arial. Shown as a menu row's picture, a typed face is worn live by the
holder (`livePictureOn`), never photographed, so it is retyped when its atlas arrives.

The families are the three the SWCanvas glyph atlases cover — **Arial** (sans), **Courier New** (mono,
through `StringWdgt.monoFontStack`), **Times** (serif) — at normal or bold, normal or italic, sizes
9–96. A design weight maps onto them: **600 → bold, 500 → regular**. There is no letter-spacing.
Both backends use the same families.

## 4. Rules

### 4.1 One line between panes: the CONTAINER owns the seam
A 1 px line between two sibling panes belongs to their container, never to either pane. The container
places its panes exactly 1 px apart and answers those gaps from `_seamRects()` (widget-local
rectangles; `Widget` answers none); its appearance (`Appearance._paintSeamRules`, called by
`RectangularAppearance`, `BoxyAppearance` and `SeamRulesAppearance` — the painter of a container with no look of its own, which paints its seams and nothing else) fills them with `seamRule` after its own fill and before
its children. A seam is a gap, so no child ever paints over it, every pixel has exactly one owner, and
a pane reused elsewhere carries no stray line.
- A BAND paints its OWN edge rule (a title bar's bottom rule, a menu header's rule): the line is part
  of the band's look whatever sits next to it. Mechanism: three fields on the band's `BoxyAppearance`
  (`ruledEdge`, `ruleColor`, `ruleWidth`), painted after the fill and under the stroke; a frame's strip
  draws the `barRule` role along its content-facing edge. A menu's group divider is such a band too: 9 px
  with no fill of its own, painting its own centred 1 px rule (`DividerWdgt`, `DividerAppearance`).
- Overlapping two panes' borders so they coincide is rejected: double ownership, double paint under
  anti-aliasing, and it must be re-established at every resize.
- Resizing a split stays a halo affordance: a target of at least 44 cannot hide inside a 1 px line.

### 4.2 The 44 rule binds CHROME
Every chrome target is at least 44×44: bar buttons, menu rows, toolbar cells, buttons, handles. A
smaller visible control sits in a row at least 44 tall. Content widgets (spreadsheet cells, patch pins,
a slider inside content) keep their own sizes. A target never extends beyond the widget that owns it:
a target that must be big is drawn big.

### 4.3 A bordered rounded rectangle means "press me"
Anything pressable has a border and rounded corners; anything that is not drops the border and changes
shape (the clock: a round face, no border). A disabled control keeps its shape and loses contrast: no
fill, a `chrome` outline, `disabledText` text — never a dashed outline or a grey fill. A disabled
button (`SimpleButtonWdgt.setEnabled false`) still catches a press, and does nothing with it.

**The toggle** (`LabelledToggleWdgt`, a `SimpleButtonWdgt`) has a FIXED label and a look that says whether it
is on: off, no fill inside a `line` border with `text2` text (hovered `desk`, pressed `chrome` inside a `frame`
border, as the button); on, an `accentTint` fill inside an `accent` border with `accent` text, in every state. Its
state is its HOST's: a click dispatches its one action, and the host decides the new state and shows it on the
toggle (`setOn`); the toggle never flips itself. `toggleHeight` tall, its label plus `togglePaddingX` at each side
plus its border wide, never narrower than `minimumTargetSize`.

**The chip** (`ChipWdgt`, a `SimpleButtonWdgt`): a label control `chipHeight` (32) tall at radius
`chipCornerRadius` (16), its label plus `chipPaddingX` at each side plus its border wide, never narrower
than `minimumTargetSize`; no fill inside a `chip` border with `text2` text (hovered `desk`, pressed `chrome`
inside a `frame` border); the CURRENT chip an `accentTint` fill inside an `accent` border with `accent` text, in
every state. The Object Inspector's breadcrumb is a band of them: "Class" in `muted2`, then the class chain base
first, each chip followed by a drawn `›` (`BreadcrumbSeparatorWdgt`, `muted3`, never a pointer target), the
current class last; a mixin-donated member's donor label (`muted2`, no border) follows the chips. The band wraps
to another row, 36 lower, when the next piece would pass its right inset.

**The button** (`SimpleButtonWdgt`) sizes itself: `preferredExtent` is `buttonHeight` tall and its
label plus `buttonPaddingX` at each side plus its border wide (`primaryButtonPaddingX` for a primary
action), never narrower than `minimumTargetSize`. A one-line text face sits in a box one line tall,
`floor((h − lineHeight) / 2)` down. Its look is re-derived from its state at every transition: `paper`
with a `line` border at rest, `desk` hovered, `chrome` with a `frame` border pressed, text `ink`. A
window content that ends in buttons lays them in a **footer band** (`FooterBandLayout`): 52 tall
including its 1 px `chrome` top rule, which is the host's seam (§4.1); buttons at their own size,
`footerInset` from the edge and `footerGap` apart, a left group and a right group, the right group
ending `footerGripClearance` short of the corner the frame's grip sits in. When both groups do not fit,
the right group follows the left one, and what runs past it is clipped (by the window, or by a container that clips
its own children: the Object Inspector does, naked or windowed).

**The tool cell** (`GlassBoxBottomWdgt`, a toolbar's cell, holding one tool) is a pressable square with no border: at
rest no fill at all (the band's `paper` shows), hovered `toolCellHoverFill` (`desk`), pressed `toolCellPressedFill`
(`chrome`), ACTIVE `toolCellActiveFill` (`desk`, the draft's active tool), rounded at `toolCellCornerRadius` (6). The cell
derives that look itself, from the state of the widget a tap on it reaches (its lid, or its tool) and from its tool's
`isActiveTool`, every time a tool tells it something changed (`noteItemStateChanged`, through `ParentStainerMixin` for
the pointer state, and from whatever decides the active state: Draw's armed tool, the text tools' mirror of the edited
text), so no tool leaves a stale colour on it. The text tools MIRROR the edited text (the editor focus,
`world.editorFocusWdgt`): B is active while it is bold, I while it is italic, `</>` while it is monospaced, an align tool
while it has that alignment. The focus has ONE write (`WorldWdgt._setEditorFocusNoSettle`), and a text's style setters
announce a change while it is the focus (`noteStyleChanged`); each text toolbar hears both through one dataflow edge
world → toolbar, so it follows in the same cycle with no timer. A hidden active tool ticks its row in the `»` menu. It clips its tool to its rounded outline, so a press in a corner notch
falls through. Every glyph in a toolbar is `toolbarGlyph` (`ink`); the overflow `»` is the drawn double chevron at
`toolOverflowGlyphSize` (16) on the same state plate.

**The desktop icon** (`WidgetHolderWithCaptionWdgt`, painted by `DesktopIconAppearance`) is a pressable tile
and a label plate in a cell of the standard desktop-icon extent (the cell by a two-line height, all from the one
knob `desktopIconTile`). The TILE is `desktopIconTile` square, `desktopIconPadding` below the cell's top and
centred across it, rounded at `desktopIconTileRadius`, with the button's state look: `paper` inside a 1 px `line`
border at rest, `desk` hovered, `chrome` inside a `frame` border pressed (a desktop link, `DesktopLinkWdgt`; a
bare holder shows the rest look only). The glyph (the holder's `icon`) is the `desktopIconGlyphSize` square
centred in the tile, in `ink`, and in a desktop link it is a PICTURE, never a pointer target
(`_showsChildAsAPicture`, asked by `Widget.isPointerTargetAt` on its ancestor walk), so a press on it is a press on
the tile, and the tile takes the press, the release and the click together. The PLATE is `plate`, rounded at
`desktopIconPlateRadius`, no border: the caption's box outset by the plate's padding, `desktopIconTilePlateGap`
below the tile. The caption (the holder's `label`, `ink`, 12 px) hugs one line of text, or wraps across the cell
less the plate's padding (its plate spanning the cell), at most `desktopIconCaptionMaxLines` lines, cut with "…";
its lines stand on the role's 16 px line boxes (baselines 12 and 28 below the caption's top). A press on the plate edits the caption
(a rename; the tile keeps its look); the holder re-lays its plate as the caption's text changes. The holder's
shape is the tile and the plate, so a press or a drop in a cell's empty corners or in the gap reaches whatever
lies behind it. Icons stand on an ICON GRID (`IconGridPanelWdgt`: the desktop column by column, five to a column; a
folder's panel row by row, three to a row; from `desktopIconGridOrigin`, one cell plus a gap apart): an icon made
or moved in later — a new folder, a "create shortcut", a filing, an icon dropped onto a folder's icon — takes the
grid's NEXT FREE SLOT (the first one no other icon overlaps, so a slot an icon has left is reused), at the standard
extent; an icon the user drops somewhere (on the desktop, or into an open folder window) stays where it was
dropped.

### 4.4 Shadows are solid
A shadow is a copy of the object's shape filled with `shadowColor` (solid black) at the shadow's alpha,
offset — no blur, no gradient. Every object on the desktop casts the ONE shared desktop shadow,
transient pop-ups included; only a dragged object has its own (the lift). The shadow pass paints a widget's SILHOUETTE
(its per-pixel coverage), so an icon or a rounded box casts its own shape. A desktop icon casts its OWN
silhouette only, its tile and its plate (its shadow pass skips its children), so its shadow at rest and its
drag lift are those two shapes, with no glyph or caption marks.

### 4.5 Symbols: an ICON or a GLYPH, decided by MEANING
A symbol that stands on its own — a control's face, or an indicator of state or behaviour (× − +, a
submenu chevron ›, a breadcrumb separator ›, an overflow », a tick ✓, the resize grip) — is an ICON: a drawn, size-aware icon,
never a character typed into a string. A character that is part of a label's own wording ("…" in
"Save world snapshot…", "—" in a title) is a GLYPH: it renders from a font atlas, and where an atlas
lacks it, it is ADDED to an atlas — the font's own for a typographic character, `BitmapTextInvariant`
for a font-independent symbol — never swapped for an icon. Fonts are not a vector format: no icon fonts.
On SWCanvas a character missing from every atlas paints a placeholder box; the atlases cover a
character at every family, size and density alike or not at all.

### 4.6 Icons are size-aware integer geometry
An icon computes integer device-pixel geometry from the size it actually paints at
(`SizeAwareIconAppearance`: `_paintSizeAware ctx, x0, y0, wDev, hDev`), so the non-anti-aliased
backend renders it crisply at every size. A widget with a `glyphSize` (a chrome button sized to its
whole target) gets its icon painted as a `glyphSize` square centred in its box. An appearance is named
for its SHAPE (`CrossIconAppearance`, `ChevronRightIconAppearance`, `GripIconAppearance`, …); the
button that wears it carries the MEANING (`CloseIconButtonWdgt`). The method — probe ladder, preview,
owner review — is the `convert-icon-size-aware` skill. SWCanvas has no `Path2D`: a design's SVG path is
hand-translated into drawing calls.

**The desktop icons are one family in the design's style** (Examples, Bin, How to save?, Fizzytiles, Draw's spray
can, Patch programming, Slides Maker, Generic panel, Dashboards, Super toolbar, Docs Maker), and share its rules:
- **One line unit**, `SizeAwareIconAppearance._glyphLineUnit S` = one unit of the design's 44-unit grid, at least
  1 px: 1 px at the 40 px tile glyph, 2 px at dpr 2 (half the design's 2-unit stroke; the owner judged that heavy).
  Every wall of a shape is that one thickness, horizontal and vertical alike; a filled feature (a chart's bar) may be
  a whole multiple of it.
- **Paper interiors, no halo**: a shape is its ink fill, then the same shape inset by the line in `iconPaper`
  (`_usePaper`, which, like `_useLight`, erases coverage on the shadow pass, so an icon's shadow is its ink). The
  tile is the ground, so no light envelope surrounds the art.
- **Slanted walls** are two parallel edges an integer step apart, the inner one moved along the axis nearest the
  edge's normal, so a slanted wall is one line per row and stays connected.
- **Small round features** (dots, magnets, keys) follow one size rule: hand-placed squares under 4 px, round dots
  from 4, rings only where the ring's hole survives.
- **Shared shapes**: Patch programming, Slides Maker, Generic panel and Dashboards stand on ONE content card
  (`_contentCardMetrics` / `_contentCard`: the design's 34 × 24 motif at the family's line).
- Constants are in design units over `GLYPH_GRID`, so each proportion is a named knob; detail drops by rule (a
  chart loses bars before its rise, a row of lines drops as a unit), never regressing as the size grows.
- Fills only where shapes overlap: SWCanvas leaves the overlap of two round-capped subpaths in one `stroke()`
  unpainted.

### 4.7 Corners and outlines
- A rounded box's radius is one number, or per corner — a 4-array `[topLeft, topRight, bottomRight,
  bottomLeft]` in `cornerRadius` (HTML5 `roundRect()` semantics), e.g. `[7, 7, 0, 0]` for a title bar
  inside a radius-8 window. `BoxyAppearance` fills, strokes and hit-tests by it.
- A frame's strip rounds exactly the corners it shares with the body's outline, at the body radius less
  the border: `[r, r, 0, 0]` for a strip across the top, `[r, 0, 0, r]` for a strip down the side, all
  four when the frame is collapsed (the strip IS the frame). It is set at every arrange of the strip
  (`FrameBarWdgt._shapeTitlebarBackground`), because collapsing and re-siding a dock change it without a
  re-derivation of the look. `FrameWdgt._deriveAndSetSkin` re-derives the body and the strip as one act,
  and a transform island re-homed with a frame as its sole content re-derives that frame
  (`TransformFrameWdgt._reactToBeingAdded`), so a tilted window dropped into a panel wears the card look.
- The hit shape of a rounded box is its FILLED pixels: a logical pixel belongs to it iff its pixel
  centre is inside the outline, the same in all four corners. A rounded corner's notch is pointer-through.
- A 1 px outline is stroked inset half a pixel with the same radius as the fill (the house crisp
  spelling, `strokeRoundRect 0.5, 0.5, w − 1, h − 1, r`).
- A tool cell clips its tool to its rounded outline the same way a rounded frame clips its children (the shared
  `Widget._paintChildrenInsideMyRoundedOutline` family).
- A clipping widget whose outline must be painted OVER its content sets `strokesOverChildren` on its
  `BoxyAppearance`: the outline is then stroked once, after the children, instead of with the fill.
- A frame clips its children to its RECTANGLE, so content laid flush against a rounded corner shows its
  own pixels outside the curve unless something stops it. Two mechanisms exist: a flush child can take
  the host's corner radii on its own background (per-corner fill — enough only for content whose corner
  pixels are its background), and `FrameWdgt` can clip its children to its rounded outline
  (its body appearance's `clipsChildrenToOutline` knob, which `_frameLook` turns on for every rounded
  frame — a window, a card, a docked band, a menu, a prompt; a pop-up in the flat look is square and has
  no notch).
  - A repaint whose damage reaches one of the frame's corner squares paints the children under ONE
    rounded clip, through `BoxyAppearance.clipToOutline`. Any other repaint paints them under the
    rectangle, as before.
  - A press in the notch falls through to whatever is behind.
  - The design adopts the clip (redesign plan §3a, and §4 F S1c for the measurements). It costs under
    2 % of suite time on SWCanvas, whose clip is an optional mask AND a rect: a child's rectangle clip
    under the rounded one never builds a mask.

### 4.8 Colour use
The accent says "focused", "selected" or "on" — nothing else. Selected and "on" controls use the
`accentTint` fill with an `accent` border and text, never a solid dark fill. `danger` marks destructive
actions only.

### 4.9 Wording and case
- **Case is shown, never stored.** A text shows its words in a DISPLAY CASE (`StringWdgt.displayCase`: none, "upper"
  or "sentence"), applied in `transformTextOneToOne`, the one hook that measuring, fitting, wrapping, the back-buffer
  key and painting read, so a box that hugs its text hugs what shows. `text` keeps the stored words for every reader of
  them: a pinned menu carries its header's stored words into its window title, a prompt's title is built from its
  menu's (`CommandPanelWdgt.promptTitleAsking`), and `colloquialName` names saved files. The transform is one
  character for one (a character whose capital is longer, "ß", is kept), and a password shows no case.
- **A bar title's case is the frame's to decide** (`FrameWdgt._titleDisplayCase`), and the bar builds every title
  piece in it: a pop-up header that NAMES something (a widget's menu, the desktop's, a section, a chooser) shows in
  capitals; every other title reads as a sentence, its first character a capital: a window's, a pinned or collapsed
  one's, a card's, a prompt's question, and a pop-up whose title is a MESSAGE (an inform, an empty chooser's "no
  targets available", the bin's confirmation: `MenuWdgt`'s `titleIsAMessage` option).
- **Human names, never class names.** A widget's menu is headed by its `colloquialName()` ("RECTANGLE", "DESKTOP"); a
  chooser's header names what its rows offer ("NEW PARENT", "TARGET", "TARGET PROPERTY", "CONNECT", "BIND WITH").
  `colloquialName` answers lowercase words by contract (they go mid-sentence too); a proper name keeps its capitals; a
  name derived from a class that reads like a programmer's word is overridden where it shows ("text", "slider knob",
  "list"). Titles that carry a name put it after a dash, as stored: "Object Inspector — analog clock", "Console — Docs
  Maker"; a class inspector names its class as the data it is, "Class Inspector — RectangleWdgt".
- **A row, a button and a toggle are in sentence case** ("Duplicate", "Pick up", "Own props only", "OK"). A row whose
  label is a VALUE is capitalised where the row is built and the value stays as it is (`CommandPanelWdgt.rowLabelOfValue`:
  the dock sides, the wallpapers, the property chooser's pin names, an overflow row built from a tool's tooltip) — never
  inside `MenuItemWdgt`, whose label is a property name in the Inspector's member list and code in Fizzytiles. Data is
  never re-cased: font names, member names, class names.
- **"…" (U+2026) ends a label exactly when its action needs more from you before it completes**: a prompt, a colour
  prompt, a code prompt, the file chooser, a download, a confirmation, or the resize handles ("Color…", "Save to file…",
  "Empty bin…", "Resize/move…", "Add…"). A row that opens a submenu has none (its chevron says it: "Attach"), nor a row
  that opens a window ("Inspect", "Edit script"), nor "Delete all". ASCII "..." ends no label. `fg menusweep` proves the
  rule and sentence case at runtime (`ELLIPSIS_MISMATCH`, `SENTENCE_CASE`).
- **A row that names a widget reads its human name** (`Widget.rowName`), told apart from its menu's other rows only
  where two would read alike (`CommandPanelWdgt.rowLabelsNaming`): first by a detail in straight quotes (a text by its
  start, a window by its title: 'Text "Hello"', 'Window "Docs Maker"'), then by a number ("Rectangle 2"). Never an
  instance number, never a class name. A wire row reads its target and pin, then its direction ("Slider · value ⇄").
- **Typed symbols that are wording** (a wire's ➜ / ⇄, the text menu's ← → ↑ ↓ ∸ ⍿ ☓ ⋯ pictograms, "°C ↔ °F") come
  from the font-independent symbols atlas (`BitmapTextInvariant`), appended to its set; they render at the text's size
  and density, never bold.

## 5. The design on the widget tree
The design paints flat; Fizzygum paints a tree (parent, then children), so every pixel of the design has
exactly one owning widget:

| Design element | Owner |
|---|---|
| Window shadow, fill, 1 px frame | `FrameWdgt`'s body appearance (`BoxyAppearance`); the shadow is its `ShadowInfo` |
| Title bar fill and its bottom rule | `FrameBarWdgt`'s `titlebarBackground` (the rule is the band's own edge, §4.1) |
| × / − in 44×44 targets | `CloseIconButtonWdgt`, `CollapseIconButtonWdgt` (in a `SwitchButtonWdgt`), children of `FrameBarWdgt` |
| Window title | `FrameBarWdgt`'s label `StringWdgt` (`fonts.windowTitle`), its stored name shown as a sentence (§4.9) |
| Pencil / eye | `EditIconButtonWdgt` |
| Resize grip | `FrameGripWdgt` (a `HandleWdgt`, child of the frame, bottom-right, `frameGripInset` in from the content area) and `GripIconAppearance`; its hit area is its whole `frameGripSize` square. A halo's and a naked inspector's resizers stay plain `HandleWdgt`s, on `HandleAppearance`'s triangle |
| Embedded toolbar with its title strip | a docked `FrameWdgt` (a card under an `EdgeDockLayoutSpec`) holding a toolbar; its bar runs vertically. The band stands `dockedBandInset` in from the host's body on its three outer sides and flush with the payload on the fourth; its thickness is the toolbar's `dockThickness`, derived from the theme's grid dials at every measure (`EdgeDockLayoutSpec.thicknessGrantedTo`). The toolbar and its grid paint nothing (`SeamRulesAppearance`): the band's card is the one line around them. Its cells (44, least 6 apart) spread space-between along the strip, `toolAlongPadding` from each end, `toolCrossPadding` across it, so a one-row strip is 56 deep; the far end keeps clear of a resizer over the strip's bottom-right corner (a floating toolbar's grip, or the host's over a right or bottom band: `ViewportWdgt.cornerResizerFootprint`, the reserve the scroll bars keep); a strip too short for every cell shows the prefix that fits and a trailing `»` |
| Document paragraph items | `SimpleTextWdgt` paragraphs in `DocumentViewportWdgt`, a borderless `documentPageFill` page whose stack keeps `documentItemSpacing` from the page's edges and between items (read at every arrange). Every paragraph a document builds comes from `getNormalParagraph`: `fonts.document` (15 px on 22 px lines; a title at its own size keeps that line height scaled with its em box) in `documentText`, on `editableItemFill` (= `item`); in view mode an item melts into the page it sits on (`blendInWithPanelColor`, both colours read live), and a background the user set stays. Every text standing on the page (a template excepted) wears the ITEM SHAPE, asked at every measure, paint and point mapping and never stored (`StringWdgt._itemShape` → its stack → `DocumentViewportWdgt.itemShapeOfTextOnPlane`): its fill rounded at `documentItemCornerRadius`, its text inset `documentItemHorizontalPadding` from the sides and `documentItemVerticalPadding` from top and bottom, so a one-line paragraph is 34 tall and wraps at its width less 20; a press in the padding picks the nearest slot of the nearest line, and the hit shape is the rounded fill. Off the page (dragged to the desk, in the hand) the same text is plain. A widget dropped into the stack goes before the first item whose middle is below the drop point |
| Menu container, header, rows, group rules | `MenuWdgt` (a transient `FrameWdgt`) → bar (header) → `PopUpRowsViewportWdgt` → `CommandPanelWdgt` → `MenuItemWdgt` rows + `DividerWdgt` |
| Inspector bands and the list \| code line | `InspectorWdgt`'s children; the lines are container-owned seams (§4.1) |
| Inspector breadcrumb | `InspectorWdgt`'s children: a "Class" caption and the donor label (`StringWdgt`s), the class `ChipWdgt`s and their `BreadcrumbSeparatorWdgt`s, placed by `_breadcrumbIn` |
| A window content's row of buttons | its footer band (`FooterBandLayout`, the geometry); the rule is the host's seam, painted by its appearance (`SeamRulesAppearance` for a host with no look of its own) |
| Desktop icon tile, glyph and label plate | `WidgetHolderWithCaptionWdgt` and its appearance `DesktopIconAppearance` (the tile and the plate are paint; its hit shape and its silhouette are the two shapes); the glyph is its `icon` child in the glyph square, the caption its `label` `TextWdgt` on the plate (§4.3) |
| Clock | `AnalogClockWdgt` + `AnalogClockAppearance`: an opaque `clockFace` disc (no border) that is also its hit shape and its silhouette, four `clockMark` dots, hour and minute hands in `ink`, the second hand and the centre dot in `accent`; every width a whole number of device pixels of the face's parity (`pixelsForUnits`), so a hand is one width pointing any way; round caps from 4 px |

Menus, windows, cards and docked bands are ONE class, `FrameWdgt`; which skin a frame wears is derived
from its lifetime and its parentage ([`regularity-principles.md`](regularity-principles.md), "The frame
model"). **`FrameWdgt._frameLook()` is the one place a frame's look is decided**: a pure query answering
one record — the manifestation (menu, window, card), the body's appearance, fill, stroke and rounding,
the strip background's appearance, colours, rounding and rule, the title's ink, and the shadow
it casts at rest — from the frame's lifetime and parentage. The body (`_deriveAndSetBodyAppearance`), the strip (`FrameBarWdgt`) and the shadow (`addShadow`)
all READ it; none decides a look of its own. A focus state, when one exists, enters
there and nowhere else. Collapsed and docked are not inputs: a collapsed frame wears its expanded look,
and a docked band is the card its parentage makes it; only the strip's corners follow the collapse and
the strip's axis, set at every arrange (§4.7). The whole skin is applied on EVERY derivation, as one act
(`FrameWdgt._deriveAndSetSkin`): the body (appearance, colours, rounding, and the stroke-last and
rounded-clip knobs) and the strip (its background's appearance, fill and rule, its title's ink, and
its glyphs' ink: `muted` in a window's strip, `text2` in a card's, `ink` while a glyph is hovered or
pressed — the glyph recolours in place, with no plate behind it). A
derivation is construction, re-parenting, lifetime change, and the re-homing of a transform island the
frame rides in as its sole content. So a pinned menu wears the window's skin, a window nested into a
panel wears the card's, and a corner radius set by hand lasts until the frame next changes parent or
lifetime.

**A pop-up** (a transient frame: a menu or a prompt) has the following parts.
- **Body:** a `paper` body inside a 1 px `frame` border at radius 10, stroked after its children, with
  its children clipped to the rounded outline. An overflowing menu's scrolled rows and its scroll
  indicator therefore stop at the outline, and nothing catches a press in its notches.
- **Content box:** inside the border, `menuContentPadding` in on every side. The rows panel
  (`CommandPanelWdgt`, alpha 0) lays its rows, dividers and editors out across it.
- **Header** (titled only): a band across the content box, 44 tall plus its own 1 px `chrome` rule
  along its bottom edge. Its title sits `menuHeaderTitleInset` in, 11 px `muted2`, left-aligned, in capitals when it
  names something and as a sentence when it is a message or a prompt's question (§4.9).
- **Rows** (`MenuItemWdgt`): label 15 px `ink`, 10 px in from each side. A `desk` plate of radius 6
  over the whole row while hovered, `chrome` while pressed (`LabelButtonAppearance`), and no hairline.
- **Groups:** a `DividerWdgt` band between groups, 9 px with its own centred `chrome` rule.
- **Buttons** (a prompt): one last row (`PromptButtonsRowWdgt`), `minimumTargetSize` tall (the 44 rule's row for
  36-tall controls, §4.2), holding `SimpleButtonWdgt`s at their own size, right-aligned flush to the content box,
  `footerGap` apart, centred down the row: [Close] [OK] with OK primary; a save-shortcut prompt [Don't save] [Cancel]
  [OK]. The row answers `menuEntryPreferredWidth`, so the pop-up widens to fit it. `Widget.inform` is a menu: its OK
  stays a row.
- **Indicators** (`MenuRowIndicatorWdgt`), pointer-transparent children of the row:
  - a row that opens a submenu (`opensSubmenu`) draws a `muted3` chevron whose ink ends 10 px from its
    right edge;
  - a menu with any ticking row reserves a leading tick column in every row, and a ticked row draws
    an `ink` tick there.

The row's label stays its plain wording. A plain LIST's rows (`ListWdgt` without `memberFactsQuery`) and fizzytiles
magnets keep their own look until their families are restyled.

**Code panes** (the Object Inspector's code pane, the script window, the code prompt, the console, the error log)
are built in the code role: `fonts.code` (12 px mono), `codeText`, `codePanePadding` (12) — a `TextAreaWdgt`
forwards `fontRole` and `textColor` to its text. A code area that is its window's content is borderless: the
window's border, its strip's rule and its footer's rule are its lines (every other `TextAreaWdgt` keeps its
border). A patch node's text boxes take `fonts.code` at their own padding and ink. Its lines stand on the role's 18 px
line boxes (the draft's; on SWCanvas: baseline 12, caret rows 1–15 of each line).

**The Object Inspector's member list** wears the member-row look: the inspector builds its `ListWdgt` with
`memberFactsQuery`, and the list's rows panel builds `MemberRowWdgt`s (`CommandPanelWdgt._createMenuItem`). Each
row is `memberRowHeight` (42) tall and flush, as wide as the list less the panel's 4 px padding (no hug to the
widest name, no horizontal bar); the kind tag (`fn` for a function, else `var`, 10 px bold `muted2`, `accent`
while the row is selected) sits in an 18 px column at x 8, and the name (13 px mono, `ink` for an own member,
`muted` for an inherited one) at x 34 in a box that crops with "…". The selected row paints a 40 px `accentTint`
plate of radius 6 at its top; no row paints a hairline, and the panel opts out of the editor-selection frame
(`providesAmenitiesForEditing = false`), so a selected member shows only its plate.

## 6. How a new widget picks its look

1. **Chrome or content?** Content (a shape the user draws, a plot series, a document's text) keeps its
   own colours and sizes. Chrome — anything that frames, controls or annotates content — takes its look
   from `Theme`.
2. **Colours:** read the role named for your surface (`WorldWdgt.theme.<role>`); if your surface has
   none, add one to `Theme`'s ROLES section, named for the surface, at the value it paints with.
   Never a colour literal in a chrome file (§1, the ratchet).
3. **Text:** `fontRole: WorldWdgt.theme.fonts.<role>`.
4. **Sizes:** chrome dimensions are `Theme` metrics; a chrome target is at least 44 (§4.2).
5. **Shape:** pressable ⇒ bordered and rounded (§4.3); per-corner radii where it sits inside a rounded
   host (§4.7).
6. **Symbols:** drawn size-aware icons, named for their shape (§4.5, §4.6).
7. **Lines between your panes:** seams you own (`_seamRects`, §4.1), not pane borders.
8. **Shadow:** nothing to do — an object on the desktop casts the shared shadow.

See also [`widget-authoring-guidelines.md`](widget-authoring-guidelines.md) §15 and
[`appearance-paint-convention.md`](appearance-paint-convention.md) (how an appearance paints).

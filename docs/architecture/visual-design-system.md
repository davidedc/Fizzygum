# The visual design system — where the look is decided, and the rules it follows

Fizzygum has ONE visual design system. Every colour a piece of chrome paints with, every chrome font,
every chrome dimension and every shadow is decided in one class, `src/Theme.coffee`, under a name that
says what it is FOR. This doc says what those names are, the rules a widget's look follows, how the
design maps onto the widget tree, and how a new widget picks its look.

The design this system implements — its tokens, its drawing rules and a reference drawing — is
archived with the redesign plan that brought the system to it:
[`../archive/redesign/UI-guidelines.md`](../archive/redesign/UI-guidelines.md) (the rules and tokens),
`desktop-canvas.html` (a flat Canvas-2D drawing of the target) and
[`../archive/redesign/redesign-plan.md`](../archive/redesign/redesign-plan.md) (the decisions behind
each rule below, and where the system departs from the draft). Where this doc and the draft disagree,
this doc is the look Fizzygum wears.

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
| **FONT ROLES** | `@fonts`: plain `{family, size, bold}` objects, optionally with a `lineHeight` (§3, the line box) — `menuRow`, `listRow`, `menuHeader`, `windowTitle`, `buttonLabel`, `defaultText`, `tooltip`, `speechBubble`, `prompt`, `desktopCaption`, `memberName`, `memberKindTag`, `code`, `document`, `spreadsheetCell`, `spreadsheetHeader`, `spreadsheetFormulaBar`, `fizzytilesCaption`, and the typed faces of the text and sheet tools `boldToolFace`, `italicToolFace`, `codeToolFace`, `decimalsToolFace` (a role may also carry `italic`). |
| **METRICS** | Chrome geometry: the bar button's box (`barIconSize`) and the glyphs inside it (`barControlGlyphSize` for × − +), the strip's thickness (`barStripThickness`, derived: the border, the bar button and the rule) and the house's grip dots (`gripDotSize`, `gripDotPitch`: a band strip's, kept `barGripMarkInset` in; a split adjuster's, `layoutAdjusterThickness` across and at most `layoutAdjusterGripDotsAlong` dots along; and the field on the split button that joins an adjuster as a tab, `splitButtonWidth` along the adjuster's axis, at most `splitButtonGripDots` dots each way), the strip's edit-mode toggle, lengths along it and thicknesses across it (`barToggleBoxLength`, `barToggleTrackLength`, `barToggleTrackThickness`, `barToggleKnobLength`, `barToggleKnobInset`, `barToggleGlyphSize`, and its slide's `barToggleSlideMs`), a menu row's glyph box (`menuRowGlyphSize`), its side inset, icon gap and hover-plate radius (`menuRowSideInset`, `menuRowIconGap`, `menuRowPlateRadius`; a plain list row's height, plate height and rounding `listRowHeight`, `listRowPlateHeight`, `listRowPlateRadius`, its `listRowSideInset`, `listRowIconGap`), its two drawn indicators' glyph squares and gaps (the submenu chevron's `menuRowChevronSize` and `menuRowChevronGap` before it; the leading tick column's `menuRowTickSize` and `menuRowTickGap` after it), a pop-up's content padding and its header's rule and title inset (`menuContentPadding`, `menuHeaderRuleWidth`, `menuHeaderTitleInset`; a plain list's rows panel `listRowsPanelPadding`), a group divider's band (`menuDividerGap`, `menuDividerRuleWidth`), a thin scroll indicator's clearance from the line at its viewport's edge and its inset from its side's ends (`scrollIndicatorEdgeClearance`, `scrollIndicatorEndInset`), a tooltip plate's rounding and paddings (`tooltipCornerRadius`, `tooltipHorizontalPadding`, `tooltipVerticalPadding`; its line box is `fonts.tooltip`'s), the frame's border width, the strip's rule and the body margin (`frameBorderWidth`, `barRuleWidth`, `frameBodyMargin`), the window and card corner radii, the menu row height, a plain handle's side (`handleSize`) and the frame grip's side and inset and the thickness of the strip that holds it (`frameGripSize`, `frameGripInset`, `frameGripStripThickness`), the toolbar grid's cell, least gap and padding along the strip (`toolThumbnailSize`, `toolInternalPadding`, `toolAlongPadding`, `toolRows`), the mark box a tool's picture stands in (`toolMarkSize`), the inset of a tool cell's state plate (`toolCellPlateInset`) and a docked band's inset from its host (`dockedBandInset`), the scroll indicator's resting and hovered widths, chrome corner radii, a button's height, horizontal paddings and rounding (`buttonHeight`, `buttonPaddingX`, `primaryButtonPaddingX`, `buttonCornerRadius`), the least side of a chrome target (`minimumTargetSize`), a footer band's height, rule, inset and button gap (`footerBandHeight`, `footerRuleWidth`, `footerInset`, `footerGap`), a toggle's height, padding and rounding (`toggleHeight`, `togglePaddingX`, `toggleCornerRadius`), an inspector's bands (their rule, `inspectorRuleWidth`; the header's `inspectorHeaderHeight`, `inspectorHeaderInset`, `inspectorHeaderGap`; a member list's toggles band's and an inspector's chooser band's `toggleBandHeight`, `toggleBandInset`, `toggleBandGap`; an inspector browser's trail chevron's glyph square, `inspectorTrailChevronSize`; a list's verb buttons' mark square, `inspectorVerbMarkSize`) and a member editor's least width (`inspectorEditorLeastWidth`), a member row's geometry (`memberRowHeight`, `memberRowPlateHeight`, `memberRowPlateRadius`, `memberRowSideInset`, `memberRowTagGap`, `memberRowTagColumnWidth`, `memberRowsPanelPadding`), a code pane's padding (`codePanePadding`), a prompt's text field's rounding (`textFieldCornerRadius`), the text caret's width and gap (`caretWidth`, `caretGap`), a document's item spacing and its items' rounding and text padding (`documentItemSpacing`, `documentItemCornerRadius`, `documentItemHorizontalPadding`, `documentItemVerticalPadding`), and a desktop icon's geometry, all from ONE knob, the tile's side (`desktopIconTile`, 64): the glyph square, the tile's rounding and the cell's width derive from it (`desktopIconGlyphSize`, `desktopIconTileRadius`, `desktopIconCellWidth`), the draft's fixed values sit beside it (`desktopIconPadding`, `desktopIconTilePlateGap`, `desktopIconPlateHorizontalPadding`, `desktopIconPlateVerticalPadding`, `desktopIconPlateRadius`, `desktopIconCaptionMaxLines`; the caption's line box is `fonts.desktopCaption`'s), and so do the icon's height and extent (`desktopIconHeight`, `desktopIconExtent`: one two-line pitch for every icon), the icon grid's gaps and origin (`desktopIconColumnGap`, `desktopIconRowGap`, `desktopIconGridOrigin`), the rows a folder window opens showing (`folderWindowIconRows`) and the bin's corner insets (`desktopBinRightInset`, `desktopBinBottomInset`); the desktop clock's side and corner insets (`desktopClockSize`, `desktopClockRightInset`, `desktopClockTopInset`). |
| **SHADOWS** | The ONE shadow every desktop object casts at rest (windows, menus, prompts, tooltips, icons, the clock) and the drag lift a carried widget takes (offset + alpha each), and `shadowColor`, the one colour every shadow silhouette is filled with. |

**The ratchet.** A colour literal in a chrome file is a look decided outside this system — a restyle
edits `Theme` and cannot reach it. The `raw-chrome-color` stink (`buildSystem/check-stinks.js`; table in
[`lint-and-static-checks.md`](lint-and-static-checks.md)) counts them outside content, icon art and the
colour plumbing, and it is at 0: any such literal fails the build. A literal in a counted file that is data rather
than a look decision (a wallpaper pattern, palette data, a paint tool's source text, a new shape's content default)
is DECLARED in the stink's `sanctioned` list by file and member, with its reason, and an entry that no longer matches
its member's literals fails too.

## 2. The palette

| Token | Value | Use |
|---|---|---|
| `ink` | `#1E1E1C` | Text and icon strokes; never large fills |
| `chromeDark` | `#4A4A46` | The FOCUSED window's strip and 1 px frame (§5) |
| `chrome` | `#E2E2DE` | Title bars, the embedded toolbar strip, 1 px rules inside windows (`seamRule`), a text's header-line rule, the disabled button outline, a split's piece at rest (`splitPieceFill`: a divider and the split button joined to it) |
| `line` | `#C9C9C4` | Control and tile borders, the title bar's bottom rule, the strip divider, a free-standing panel's border, a split's piece pressed or dragged (`splitPiecePressFill`) |
| `frame` | `#B9B9B4` | Frames of windows and menus |
| `chip` | `#D2D2CD` | A split's piece hovered (`splitPieceHoverFill`) |
| `desk` | `#ECECE8` | Wallpaper, active tool button, highlighted menu row, pale fill inside icons |
| `plate` | `#F4F4F1` | Desktop icon label plates, the tooltip, the speech bubble |
| `item` | `#F0F0EC` | A document paragraph item |
| `panel` | `#FAFAF8` | The body of an inspector browser; a bare panel's or viewport's fill |
| `paper` | `#FFFFFF` | Window content, tiles, menus, the clock face, buttons, code panes, lists and text areas, a canvas |
| `muted` | `#6A6A66` | Window title text and bar controls; a band strip's grip mark (`cardBarGripMark`); a split's grip dots, its adjuster's and its split button's (`layoutAdjusterGripMark`) |
| `muted2` | `#8A8A85` | Secondary labels: `fn`, a menu header, an empty window's placeholder |
| `muted3` | `#A5A5A0` | Chevrons, a code pane's "modified" mark |
| `text2` | `#55554F` | Text on toggles that are off; a toolbar strip's glyph |
| `code` | `#3A3A36` | Source code text |
| `grip` | `#BDBDB8` | The resize grip's strokes |
| `disabledText` | `#B9B9B4` | Text of a disabled button |
| `accent` | `#2F5BEA` | Focused, selected and "on" ONLY — the text caret (the editing focus) and the selection outline included (the clock's second hand is the one exception: it is live) |
| `accentTint` | `#2F5BEA` at 12% | The fill of an "on" or selected control |
| `accentWash` | `#2F5BEA` at 20% | A place a release would put what the hand carries (the dock preview) |
| `danger` | `#C4321C` | Destructive actions and error states only (a spreadsheet's error value) |
| `scrollbar` | `rgba(30,30,28,0.35)` | The overlay scrollbar thumb |

## 3. Fonts

A text widget takes its font as a ROLE: `new StringWdgt text, fontRole: WorldWdgt.theme.fonts.windowTitle`
gives family, size and bold at once. An explicit `fontName` / `fontSize` / `bold` wins over the role's
member, so a caller can take a role and override one member. A text built without a role takes
`fonts.defaultText`. `StringWdgt` and everything built on it read the role; `LabelButtonWdgt` (its builder's role; a
`MagnetWdgt` builds its label in `code`), `MenuItemWdgt` (`menuRow` or `listRow`, by the panel that builds it; a `MemberRowWdgt` takes `memberName`, its kind tag `memberKindTag`) and `StringFieldWdgt`
forward it.

A text's INK is a role too: a text built without a colour holds none and paints in `defaultTextInk` (`ink`), read as
it paints each line and keyed into its back buffer, so a saved or duplicated text wears the world's ink. A builder
that gives its text an ink gives it the role of its surface as it builds it (a window title's `titleText`, a speech
bubble's `speechBubbleText`, the empty window's placeholder `framePlaceholderText`, `muted2`: a hint, not body text).

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
- A caret stands at a SLOT: a UTF-16 offset that falls between two characters as a person sees them (grapheme
  clusters; `TextSlots` is the one definition), so an emoji or a decomposed accent is stepped over, deleted, hit,
  selected (one plate), cropped and masked (one asterisk) whole. A slot's boundary is measured on the text as it
  SHOWS, so a hidden text's caret stands after the asterisks.
- Every number is a whole logical pixel, so dpr 2 doubles each exactly. The line height is part of the wrap and
  back-buffer cache keys.
- Four roles state a line height, at the draft's values: `document` 22, `code` 18, `desktopCaption` 16, `tooltip` 16.
- A text dressed as a document item (§5) stands its line boxes in its text area, inset from its box.

**Typed icon faces.** The text tools' B, I and `</>`, and the sheet tools' `.0` and `.00` (fewer / more decimals), are
TYPED from the atlases (`TypedFaceIconAppearance`; the draft's serif and mono faces), in their font roles, which are
stated at a tool cell's side: Times New Roman bold 20 and italic 20, Courier New 15, and Courier New bold 17 for the
decimals (`decimalsToolFace`, a step heavier so the dots read beside B and I). They paint in the widget's logical coordinates inside the standard paint scope (crisp on
SWCanvas only there: in a device-pixel body a typed glyph comes out half size at dpr 2). In a box of side s the size is
the role's × s / `toolThumbnailSize`, snapped to 0.5 and kept within the atlases' 9–96; they are centred across by
their advance and down by the draft's "line centred in a taller box" rule, `round((h − (A + D)) / 2) + A`. A face's
family names the literal family first and the generic last (`"Times New Roman", serif`): SWCanvas picks an atlas by the
generic word, so a bare literal would type Arial. Shown as a menu row's picture, a typed face is worn live by the
holder (`livePictureOn`, read off the face's declared `typesGlyphs`; the logo with its word declares it too), never
photographed, so it is retyped when its atlas arrives. A tool with words a glyph box cannot show leaves them out of
that picture: the row asks the copy it photographs to `prepareForMenuRowPicture`, and a speech bubble hides its text.

The families are the three the SWCanvas glyph atlases cover — **Arial** (sans), **Courier New** (mono,
through `StringWdgt.monoFontStack`), **Times** (serif) — at normal or bold, normal or italic, sizes
9–96. A design weight maps onto them: **600 → bold, 500 → regular**. There is no letter-spacing.
Both backends use the same families. On SWCanvas a size above 96 draws at 96, and a size under 9 (only a
shrink-to-fit text in a box too small for 9 px gets one: every role is larger) draws one rectangle per character,
measured by the 9 px metrics scaled down, so such a text is laid out for what is drawn.

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
  with no fill of its own, painting its own centred 1 px rule (`DividerWdgt`, `DividerAppearance`). A row of
  controls (`BandWdgt`: an inspector browser's trail, an inspector's header and chooser, a member list's toggles and cut-notice bands and its band of verbs (`ListVerbsBandWdgt`, a kind of band, §4.3), an object list's cut-notice band) is a band with no
  fill either: it paints its rule as a container paints its seams (`SeamRulesAppearance` over its `_seamRects`),
  `inspectorRuleWidth` thick INSIDE its height along its `ruleEdge` and under its pieces, so a control as tall as the
  band (the split button beside a column divider, 44 px tall in a 44 px header) stands over it.
- Overlapping two panes' borders so they coincide is rejected: double ownership, double paint under
  anti-aliasing, and it must be re-established at every resize.
- Resizing the split at a seam is a halo affordance: a target of at least 44 cannot hide inside a 1 px line. A
  split a person moves as part of a tool's use is no seam: a divider stands between the two panes as a cell of
  their container's division (an inspector browser's set of columns, and the browser itself between its strip of
  lists and its body below, §4.2).

### 4.2 The 44 rule binds CHROME
Every chrome target is at least 44×44 (`minimumTargetSize`): bar buttons, menu rows, toolbar cells, handles. A
smaller visible control sits in a row at least 44 tall. THE button and the toggle (§4.3) are such controls: never
narrower than 44, and the house's one control height, 36 (`buttonHeight`, `toggleHeight`), so the control meets 44
across by itself and the row it stands in meets it down (a footer band's 52, an inspector's header 44, a band of
toggles' 48, a prompt's row of buttons 44). A toolbar tool's PICTURE stands in the 32 mark box
(`toolMarkSize`) centred in its 44 cell, which stays the target (the tool cell, §4.3). Content widgets (spreadsheet cells, patch pins,
a slider inside content) keep their own sizes. A target never extends beyond the widget that owns it:
a target that must be big is drawn big. A content that a finger must work in is served by chrome around
it rather than by 44-tall content: a spreadsheet's FORMULA BAR is 44 tall (the field a cell is edited
in), and the sheet ZOOMS — it lays itself out again at its sizes times a level, crisp at any level,
while its formula bar, toolbar and window keep theirs. A job a mouse can do on a control a finger cannot work gets a
second control beside it that does the same job, at least 44 × 44 together with the control it stands against, and
both stand on screen at all times, since a device can have both a mouse and a touch screen — never one geometry per
pointer: an inspector browser's divider (`InspectorDividerWdgt`, `layoutAdjusterThickness` (12) thick) sizes the cell
standing just before it, a stated size, never a trade between the two cells beside it, and the split button at the left
end of the header of the inspector after it (`SplitGripWdgt`) is a TAB joined to it, `splitButtonWidth` (32) along the
divider's axis and a chrome target's 44 (`minimumTargetSize`) across it, so the piece the two make is 44 × 44 at the
header (12 + 32) and a
finger's drag anywhere on it, on the divider beside the tab as on the tab, sizes that same cell. Between two columns of
the browser's set the divider sizes the WIDTH of the column on its left, and the tab stands flush right of it, 32 wide
and 44 tall; between the set and the body below it the divider sizes the HEIGHT of the strip of lists above it, and the
tab is TURNED a quarter, 44 wide and 32 tall, flush under the divider, hanging from the top of the body's header. The
halo's split adjusters, which stand in no band, have no such button.

### 4.3 A bordered rounded rectangle means "press me"
Anything pressable has a border and rounded corners; anything that is not drops the border and changes
shape (the clock: a round face, no border). A disabled control keeps its shape and loses contrast: no
fill, a `chrome` outline, `disabledText` text — never a dashed outline or a grey fill. A disabled
button (`SimpleButtonWdgt.setEnabled false`) still catches a press, and does nothing with it. A disabled MENU
ROW, which has no border, keeps its shape and loses contrast the same way: on its usual rest fill, everything it
draws in one ink (§5, "Rows"), and its press caught and dropped. A SPLIT'S PIECE — a divider and the split button
joined to it as a tab (§5) — is chrome a person drags, not presses, and is flat: one grey plate with no border, its
grip dots saying what a drag on it does, and its hover and its press a tone step of the whole piece.

**The toggle** (`LabelledToggleWdgt`, a `SimpleButtonWdgt`) has a FIXED label and a look that says whether it
is on: off, no fill inside a `line` border with `text2` text (hovered `desk`, pressed `chrome` inside a `frame`
border, as the button); on, an `accentTint` fill inside an `accent` border with `accent` text, in every state. Its
state is its HOST's: a click dispatches its one action, and the host decides the new state and shows it on the
toggle (`setOn`); the toggle never flips itself. `toggleHeight` tall, its label plus `togglePaddingX` at each side
plus its border wide, never narrower than `minimumTargetSize`. Its hosts: a member list's filter (`MemberListWdgt`: Methods,
Fields, Inherited and, on any subject but a class's prototype, Own props only), an inspector's chooser (`InspectorWdgt`: a toggle per view its subject offers, Members first, then a widget's Children, or a class's Instances, where instances register, and Subclasses, on for the view shown; a press on the lit one has that view read its list again) and the error log's "Pause", on while the log is paused (`ErrorsLogViewerWdgt.paused`).

**The button** (`SimpleButtonWdgt`) sizes itself: `preferredExtent` is `buttonHeight` tall and its
label plus `buttonPaddingX` at each side plus its border wide (`primaryButtonPaddingX` for a primary
action), never narrower than `minimumTargetSize`. A one-line text face sits in a box one line tall,
`floor((h − lineHeight) / 2)` down. A face that is a drawn MARK — a picture naming the side of its glyph square
(`glyphSize`: a `MenuRowIndicatorWdgt`, a list's verb, below) — makes the button `buttonHeight` tall and, as every
button, never narrower than `minimumTargetSize`: `max(minimumTargetSize, buttonHeight)` by `buttonHeight`, 44 × 36, the
mark's square centred in it the same floor way (`SimpleButtonWdgt._faceIsAMark`), and the mark is inked as a text face is:
`buttonText` while the button is enabled, `buttonDisabledText` while it is not, in every pointer state. Its look is re-derived from its state at every transition: `paper`
with a `line` border at rest, `desk` hovered, `chrome` with a `frame` border pressed, text `ink`. A
window content that ends in buttons lays them in a **footer band** (`FooterBandLayout`): 52 tall
including its 1 px `chrome` top rule, which is the host's seam (§4.1); buttons at their own size,
`footerInset` from the edge and `footerGap` apart, a left group and a right group. A window's grip lies in
its grip strip, below the band, so the band keeps nothing clear for it. When both groups do not fit,
the right group follows the left one, and what runs past it is clipped (by the window, or by a container that clips
its own children: an inspector browser does, in a window or with none).

**A list's verbs** (`ListVerbsBandWdgt`, a band of controls, §4.1) are the band an inspector's member list ends in
while its subject's members are edited (`MemberRef.canEdit`: a widget, a Fizzygum class's prototype), at the footer
band's metrics: `footerBandHeight` (52) tall, its rule along its TOP, the line between it and the list above it;
`footerInset` in, one button per verb the list offers, `footerGap` between two, then a spring and `footerInset` again;
the buttons centred down it. The verbs stand in ONE order, add, duplicate, rename, remove. Each is THE button (above)
faced by a drawn mark (§4.6) in an `inspectorVerbMarkSize` (16) square, so 44 × 36, the mark 14 px in from its sides
and 10 from its top and bottom: the button meets the 44 rule across, and the 52 band meets it down (§4.2). Four
buttons 8 px apart make the band desire 12 + 4 × 44 + 3 × 8 + 1 + 12 = 225 (its spring desires 1), its least 224 (the
spring's least is 0). And since a mark alone does not say its verb, its TOOLTIP carries the words the list gives it
("Add…", "Duplicate…", "Rename…", "Remove": sentence case, "…" where a prompt follows, §4.9). A verb a list can never offer is ABSENT, leaving no gap, and a list that offers none
builds no band: a value's member list (a number's, a string's, a Point's, an Array's) and an object list (Children,
Instances, Subclasses). A verb that does not apply NOW is DISABLED, in the button's own disabled look, and catches a
press that does nothing: add always applies; duplicate, rename and remove apply while the chosen member is one the
subject itself holds, other than `constructor`. The list answers that (`MemberListWdgt.verbApplies`) and has its band
reflect it (`ListVerbsBandWdgt.reflectVerbs`) where the list's own state moves — its build and every re-filter, whose
fresh list chooses nothing; a row's choice; a reload — and where what its subject OWNS moves, at ONE seat: the tail
every member step ends in (`_notifyOfEdit`) tells every member list on the step's holder
(`MemberListWdgt.noteMembersMayHaveChanged`). So an add, a duplicate, a rename or a remove made through any list on
that subject, and a Save in the body, which can make an inherited member the subject's own, show in every list on it at
once. A change to the subject's members that is no member step shows at the list's next choice, which asks again: a
run of code in an editor (`Widget._runningAPersonsCode`), and the product's own writes (a menu's colour).

**The class button** (`InspectorWdgt.classButton`) is THE button (`SimpleButtonWdgt`, above) at the right end of an
inspector's header, where its subject is made by a class other than `Object` (an inspector on one member, and an
empty body, have none): `buttonHeight` (36) tall, centred down the 44 header (§4.2's smaller control in a row at least
44 tall), its face the name of the class the inspector's subject is made by (a class's superclass, for a class's
prototype), data as it reads (§4.9). It wears the button's look and nothing about it is ON: the class is a
place to go to, not a state the header is in. A press shows that class in the inspector after it
(`InspectorWdgt.chooseMyClass`).

**The trail** (`InspectorBrowserWdgt.trail`), an inspector browser's where-you-are band and its first cell, is a band
of buttons (`SimpleButtonWdgt`, above) at the footer band's metrics (`BandWdgt`, §4.1): `footerBandHeight` (52) tall, its rule along its
BOTTOM, the line between it and the set below it; `footerInset` in, one `SimpleButtonWdgt` per step of the browser's
sequence, in order, then a spring and `footerInset` again. Between two buttons stands the menu row's drawn submenu
chevron (`MenuRowIndicatorWdgt` drawing `ChevronRightIconAppearance`) in a square of `inspectorTrailChevronSize` (12),
in an ink of its own, `inspectorTrailChevron` (`muted3`), its INK, not its square, `footerGap` (8) clear of each button
(`ChevronRightIconAppearance.inkSpanX`: its ink spans [4, 9] of its 12-px square, so the gap before it is 4 and the gap after it 5); the band centres every piece down
itself and the ink is centred in its square, so the ink stands on the buttons' centre line. A step's words are derived
from how it was chosen, never stored: as the inspector before it names the choice made in it (`InspectorWdgt.nameOfMyChoice`:
"Class RectangleWdgt" for a class button's choice, and for a row of a list of objects that list's relation and the row's
label, "Child Rectangle 2", "Instance Rectangle", "Subclass BlinkerWdgt"), else by its own subject's name, in sentence
case where the words are ours ("Rectangle", "Point") and as it is where they are data ("color", "RectangleWdgt"), §4.9
(`InspectorWdgt.trailNameOfMySubject`). A press on a step brings the column it was chosen in whole into view (the first
step's own column) and the row chosen in that column into its list's view (`InspectorBrowserWdgt.revealTrailLevel`). A
trail longer than its browser is wide squeezes its pieces, as every band of the tool does where its window is too
narrow for it.

**The tool cell** (`GlassBoxBottomWdgt`, a toolbar's cell, holding one tool) is a pressable 44 square with no border. Its
state paints a PLATE `toolCellPlateInset` (3) inside it on every side (`ToolCellAppearance`: 38 × 38 in the 44 cell), so
the plate keeps clear of the border lines of a band as deep as its cells, while the cell's shape and the clip of its
children stay the whole square: at rest no fill at all (the band's `paper` shows), hovered `toolCellHoverFill` (`desk`),
pressed `toolCellPressedFill` (`chrome`), ACTIVE `toolCellActiveFill` (`desk`, the draft's active tool), rounded at
`toolCellCornerRadius` (6). Its children have two ROLES (G3, a target and its mark are separate dials): what a tap on it
reaches, its lid or a tool that takes its own taps (`thumbnailClickReceiver`), is the TARGET and fills the cell; the
tool's PICTURE is the MARK and stands in the MARK BOX, `toolMarkSize` (32) square and centred, which keeps it 6 px clear
of the band's border. A tool under a lid (a Template) is sized to the mark box, on its longer side where it locks a
ratio. A tool that is its own target keeps the whole cell and draws its face at the mark box's side when that face is a
PICTURE filling its box: it declares `drawsFaceInToolMarkBox: true`, and the cell writes it a `glyphSize` as it seats it
(the creator buttons; the paint tools, which seat their face widget in that side; the sheet's paint bucket and slider
node). A face drawn as a GLYPH for the whole cell, carrying its own white space, declares false and keeps its size (the
text and sheet tools' script A, B, I, `</>`, the align trio, the font-size pair and the decimals, and the Templates
face, on the text toolbar's tool and on the Super toolbar's creator alike), so a face has one size in every toolbar. The cell
reads that look as it paints, from the hand's answers about the widget a tap on it reaches (its lid, or its tool:
`pressesOn`, `restsOn`) and from its tool's `isActiveTool`, and repaints whenever a tool tells it something changed
(`noteItemStateChanged`: a tool's `notePointerStateChanged` for the pointer state, and from whatever decides the active state: the tool a paint tool's holder holds, the text tools' mirror of the edited
text), so no tool leaves a stale colour on it. The text tools MIRROR the edited text (the editor focus,
`world.editorFocusWdgt`, or the style it hands over: a spreadsheet hands over its selected cell's, `SheetCellStyle`):
B is active while it is bold, I while it is italic, `</>` while it is monospaced, an align tool
while it has that alignment. A text or sheet tool with NOTHING TO ACT ON is DIMMED. It has nothing to act on when no
subject offering its verb is handed over: within its window for a docked bar, anywhere for a floating one, and never by
content in view mode (`EditorContentPropertyChangerButtonWdgt.hasSomethingToActOn`). Its cell keeps the rest fill in every
pointer state (`GlassBoxBottomWdgt.holdsToolWithNothingToActOn`), and its glyph takes `toolbarGlyphDimmed`
(`disabledText`, the ink of a disabled button's label). Like a disabled button, it drops its hover and press look and
refuses its press (the font tool opens no menu). Creators, paint tools and Templates never dim. The focus has ONE write (`WorldWdgt._setEditorFocusNoSettle`), and a text's style setters
announce a change while it is the focus (`noteStyleChanged`); every toolbar hears both through its dataflow edge
world → toolbar, so it follows in the same cycle with no timer ([`toolbars.md`](toolbars.md) §7, the refresh). A hidden active tool ticks its row in the `»` menu, and a hidden dimmed tool's row is disabled (§5, "Rows"). It clips its tool to its rounded outline, so a press in a corner notch
falls through. Every glyph in a toolbar is `toolbarGlyph` (`ink`), a dimmed tool's `toolbarGlyphDimmed`; the overflow `»` is the drawn double chevron at
`toolOverflowGlyphSize` (16) on the same state plate. The text toolbar's faces are B, I and `</>` typed in their
faces' fonts, and the rest drawn as size-aware control glyphs on the » × − + weight (2 px in the 44 cell), ink only and
every part a fill, so the cell's state plate shows through them: the script A (font family), the align trio as four
ragged bars, long and short, with round ends (`RaggedLinesIconAppearance`, anchored left, centre or right), the font-size
pair as a drawn A with a small plus or minus (`LetterAWithSignIconAppearance`), and the snippets (Templates) face as a
folded page with a filled heart. The SHEET toolbar (`SheetToolbarWdgt`, the text toolbar plus the sheet's tools) adds the
fill tool's paint bucket in the same weight (`PaintBucketIconAppearance`: a filled elliptical rim, the walls and bottom
one line, a bail arching over it, a drop beside it), the typed decimals, and the slider-node face for "slider in cell".
The Super toolbar's entry for a Maker's toolbar wears that Maker's desktop icon in `toolbarGlyph` (the sheet grid, the
dashboards tiles, Draw's spray can).

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
(a rename; the tile keeps its look); the holder re-lays its plate as the caption's text changes. The SELECTED icon
— the one the editor focus selects (`WorldWdgt.isSelectedIcon`; a click on the tile selects it AND opens it, as do a
right-click, a finger hold and a drop; never while a caret is in its caption) — wears an `accent` ring
`desktopIconTileSelectedStrokeWidth` (2) wide inside the tile in place of the 1 px border
(`desktopIconTileSelectedStroke`, painted by `HighlightOutlineAppearance.paintRing`), an `accent` plate
(`desktopIconPlateSelectedFill`) and `paper` caption ink (`desktopIconCaptionSelectedText`: the caption holds no colour,
its holder answers its ink at paint, `inkForChildText`); its tile's fill stays its state's, and no generic selection
outline frames it (the icon's own look replaces it). The holder's
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
submenu chevron ›, an overflow », a tick ✓, the resize grip) — is an ICON: a drawn, size-aware icon,
never a character typed into a string. A character that is part of a label's own wording ("…" in
"Save world snapshot…", "—" in a title) is a GLYPH: it renders from a font atlas, and where an atlas
lacks it, it is ADDED to an atlas — the font's own for a typographic character, `BitmapTextInvariant`
for a font-independent symbol — never swapped for an icon. Fonts are not a vector format: no icon fonts.
On SWCanvas a character missing from every atlas paints a placeholder box; the atlases cover a
character at every family, size and density alike or not at all.

### 4.6 Icons are size-aware integer geometry
An icon computes integer device-pixel geometry from the size it actually paints at
(`SizeAwareIconAppearance`: `_paintSizeAware ctx, x0, y0, wDev, hDev`), so the non-anti-aliased
backend renders it crisply at every size. A widget with a `glyphSize` gets its icon painted as a
`glyphSize` square centred in its box: a chrome button sized to its whole target, a toolbar tool that is
its own target in a tool cell and whose face is a picture (the cell writes it the mark box's side, §4.3), and a
button's drawn MARK face (a `MenuRowIndicatorWdgt` the button centres at its square, §4.3). An appearance is named
for its SHAPE (`CrossIconAppearance`, `ChevronRightIconAppearance`, `GripIconAppearance`, …); the
button that wears it carries the MEANING (`CloseIconButtonWdgt`). The method — probe ladder, preview,
owner review — is the `convert-icon-size-aware` skill. SWCanvas has no `Path2D`: a design's SVG path is
hand-translated into drawing calls.

**A list's verb marks** (§4.3, "A list's verbs") are PLACEHOLDERS, the owner's final icons still to be drawn: the plus
(`PlusIconAppearance`) for add, and three drawn for the band, each named for its picture: two overlapping sheets
(`TwoSheetsIconAppearance`) for duplicate; a text cursor standing in a one-line field (`TextCursorIconAppearance`) for
rename, never a pencil, which means "edit" here; a lidded bin in outline (`BinOutlineIconAppearance`) for remove, not the
desktop's bin (`BinIconAppearance`), whose paper interiors would show as patches on the button's hover and pressed fills
and whose lines are the desktop family's unit, a hairline beside a control glyph. The three are control glyphs, INK ONLY
(the button's fill shows through), every part a rectangle FILL on ONE line, the control glyph's
(`SizeAwareIconAppearance._controlGlyphLine`: 2 px in the 16 px square, 4 at dpr 2, the plus's bar at that square),
with no round cap anywhere and no pixel painted twice; their proportions are units of a 16-unit grid, the ink 1 unit
clear of the square on every side, as the plus's is. The bin paints in its square's parity fit
(`SizeAwareIconAppearance._parityFitSide`), so it mirrors exactly about its vertical axis.

**The desktop icons are one family in the design's style** (Examples, Bin, How to save?, Fizzytiles, Draw's spray
can, Patch programming, Slides Maker, Generic panel, Dashboards, Super toolbar, Docs Maker, the Spreadsheet, the C-F
converter) and the composites that frame a filed or aliased widget (the object frame, the script frame, the generic
widget picture, the shortcut badge), and share its rules:
- **One line unit**, `SizeAwareIconAppearance._glyphLineUnit S` = one unit of the design's 44-unit grid, at least
  1 px: 1 px at the 40 px tile glyph, 2 px at dpr 2 (half the design's 2-unit stroke; the owner judged that heavy).
  Every wall of a shape is that one thickness, horizontal and vertical alike; a filled feature (a chart's bar) may be
  a whole multiple of it.
- **Paper interiors, no halo**: a shape is its ink fill, then the same shape inset by the line in `iconPaper`
  (`_usePaper`, which erases coverage on the shadow pass, so an icon's shadow is its ink). The
  tile is the ground, so no light envelope surrounds the art.
- **Slanted walls** are two parallel edges an integer step apart, the inner one moved along the axis nearest the
  edge's normal, so a slanted wall is one line per row and stays connected.
- **Small round features** (dots, magnets, keys) follow one size rule: hand-placed squares under 4 px, round dots
  from 4, rings only where the ring's hole survives.
- **Shared shapes**: Patch programming, Slides Maker, Generic panel, Dashboards and the Spreadsheet stand on ONE
  content card (`_contentCardMetrics` / `_contentCard`: the design's 34 × 24 motif at the family's line); the object
  and script frames on ONE page with a folded corner (`_pageMetrics` / `_page`), as tall as the glyph square and 35
  units wide.
- **A Maker wears its glyph bare; a DOCUMENT wears the page with that glyph inside** (`GenericObjectIconWdgt`): a
  saved document, a filed widget, an Examples door. The glyph fills the page's PICTURE square, `PAGE_PICTURE` (31) of
  the 44 units, centred: 28 px at the 40 px tile glyph, the size from which the Dashboards glyph draws its charts.
  The fold stays above that square. A door with art of its own (the C-F converter, How to save?) wears that instead.
  The shortcut badge (a paper box, an
  ink frame, a one-line paper knockout ring and a straight 45° arrow) takes its host glyph's line and sits at its
  `HOST_SHARE` (0.3) of the host's square, bottom left.
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
- A frame shows its CONTENT only inside the box it gives its content (its body between its title strip
  and its grip strip, less any docked band, the band's inset and the frame's margin;
  `FrameWdgt._clipThroughForChild`), and its chrome in place: a
  tilted content's ink, or a content that draws past its own box, is cut where it would cross the
  strips, which keep their look and their presses.
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
The accent says "selected", "on" or "the editing focus" (the caret) — nothing else. A selected or "on"
CONTROL uses the `accentTint` fill with an `accent` border and text, never a solid dark fill. A selected
LABEL reads like selected text: solid `accent` with `paper` ink (text selection; the selected desktop
icon's plate). A focused WINDOW is not an accent: it wears `chromeDark` (§5). `danger` marks destructive
actions and error states only.

### 4.9 Wording and case
- **Case is shown, never stored.** A text shows its words in a DISPLAY CASE (`StringWdgt.displayCase`: none, "upper"
  or "sentence"), applied in `transformTextOneToOne`, the one hook that measuring, fitting, wrapping, the back-buffer
  key and painting read, so a box that hugs its text hugs what shows. `text` keeps the stored words for every reader of
  them: a pinned menu carries its header's stored words into its window title, a prompt's title is built from its
  menu's (`CommandPanelWdgt.promptTitleAsking`), and `colloquialName` names saved files. The transform is one
  character for one (a character whose capital is longer, "ß", is kept), and a password shows no case.
- **A bar title's case is the frame's to decide** (`FrameWdgt._titleDisplayCase`), and the bar builds every title
  piece in it. A pop-up states what its title is, one of three (`MenuWdgt`'s `titleKind` option): a header that NAMES
  something (a widget's menu, the desktop's, a section, a chooser; the default) shows in capitals; a MESSAGE (an
  inform, an empty chooser's "no targets available", the bin's confirmation) reads as a sentence, as does every other
  title — a window's, a pinned or collapsed one's, a card's, a prompt's question — its first character a capital; a
  VALUE (a value's bubble, `Widget._informOfValue`: a text's "Show selection", a slider's "Show value") shows as it is,
  pinned too, since it is data: `"color"` keeps its quotes, `true` and `new Point 3, 4` their lower case. A thing's name
  as the thing itself shows it is data too, and takes the same kind: the one-row menu a user-mode right-click opens over
  what an inspector names ("Open in a new inspector", `Widget.buildContextMenu`) is titled by the words its row or
  button shows, a member's name, a class's, a step of the trail ("color", "RectangleWdgt", "Child Rectangle 2"), never
  re-cased.
- **Human names, never class names.** A widget's menu is headed by its `colloquialName()` ("RECTANGLE", "DESKTOP"); a
  chooser's header names what its rows offer ("NEW PARENT", "TARGET", "TARGET PROPERTY", "CONNECT", "BIND WITH").
  `colloquialName` answers lowercase words by contract (they go mid-sentence too); a proper name keeps its capitals; a
  name derived from a class that reads like a programmer's word is overridden where it shows ("text", "slider knob",
  "list"). Titles that carry a name put it after a dash, as stored: "Inspector — analog clock", "Console — Docs
  Maker"; an inspector on a class names its class as the data it is, "Inspector — RectangleWdgt".
- **A row, a button and a toggle are in sentence case** ("Duplicate", "Pick up", "Own props only", "OK"). A row whose
  label is a VALUE is capitalised where the row is built and the value stays as it is (`CommandPanelWdgt.rowLabelOfValue`:
  the dock sides, the wallpapers, the property chooser's pin names, an overflow row built from a tool's tooltip) — never
  inside `MenuItemWdgt`, whose label is a member's name in an inspector's member list and code in Fizzytiles. Data is
  never re-cased: font names, member names, class names, a value's bubble.
- **"…" (U+2026) ends a label exactly when its action needs more from you before it completes**: a prompt, a colour
  prompt, the file chooser, a download, a confirmation, or the resize handles ("Color…", "Save to file…",
  "Empty bin…", "Resize/move…"). A button whose face is a drawn mark says its words in its TOOLTIP, and the rule holds
  for those words as for a label: a list's "Add…", "Duplicate…" and "Rename…" open a prompt, its "Remove" removes at
  once (§4.3). A row that opens a submenu has none (its chevron says it: "Attach"), nor a row
  that opens a window ("Inspect", "Edit script"), nor "Delete all". ASCII "..." ends no label. `fg menusweep` proves the
  rule and sentence case at runtime (`ELLIPSIS_MISMATCH`, `SENTENCE_CASE`), on rows and on the buttons no menu walk
  reaches, a list's verb buttons by their tooltips.
- **A row that names a widget reads its human name** (`Widget.rowName`), told apart from its menu's other rows only
  where two would read alike (`CommandPanelWdgt.rowLabelsNaming`): first by a detail in straight quotes (a text by its
  start, a window by its title: 'Text "Hello"', 'Window "Docs Maker"'), then by a number ("Rectangle 2"). Never an
  instance number, never a class name. A wire row reads its target and pin, then its direction ("Slider · value ⇄").
- **Typed symbols that are wording** (a wire's ➜ / ⇄, the text menu's ← → ↑ ↓ ∸ ⍿ ☓ ⋯ pictograms, "°C ↔ °F") come
  from the font-independent symbols atlas (`BitmapTextInvariant`), appended to its set; they render at the text's size
  and density, never bold.

### 4.10 A window's PAGE keeps a gutter; a PANE runs flush
What a window holds is one of two kinds, and the content's class declares which.
- A **PANE** is a view whose edges are the window's lines: the inspector (an inspector browser), the
  folder and bin panes, the code areas, a plain panel or viewport as a window's whole content, the
  empty window's placeholder, the Super toolbar, and a document (`DocumentViewportWdgt`). It lies
  flush inside the window's body (`frameBodyMargin`, 0).
- A **PAGE** is a surface you work on: a canvas, a slide, a dashboard or a patch board
  (`StretchableWidgetContainerWdgt`), Fizzytiles' boards (`FridgeMagnetsWdgt`), a spreadsheet
  (`SimpleSpreadsheetWdgt`); each answers `wantsWindowPageGutter`. Its window keeps ONE gutter,
  `windowPageGutter` (8), on every side of it and between it and each docked band
  (`FrameWdgt._bodyMargin`, read at every measure and arrange, never copied). A band stands the larger
  of the body margin and `dockedBandInset` in from the body, so the gutter moves no band: band and page
  share one 8. A Stretchable page in a gutter paints its edge on all four sides — a framed sheet, as
  Draw's canvas draws its own border — because window body, gutter and page are all `paper`; a
  spreadsheet always does, over its own cells (`SheetAppearance`).
- **A pane that scrolls keeps its own margin.** A document keeps `documentItemSpacing` (8) as its
  viewport's plane margin (`ViewportWdgt.planeMargin`, written by `_writePlaneMargin`), windowed or bare
  alike: its paragraphs stand 8 inside its edges (as wide as its toolbar, 8 below it, in a window),
  its scroll indicator stands by the window's edge (§5, Scroll indicator), and what scrolls is cut at the margin's inner
  edge, never at the window's line (`viewports-and-planes.md`, the plane margin). The margin paints
  the document's own fill, so a coloured document is coloured to the window's lines. A caret brought
  into view keeps the spacing of context inside the margin.
- **Who paints a ring that must not scroll.** A page's **selection ring** lies OUTSIDE the page,
  `pageSelectionOutlineOffset` (2) out, `selectionOutlineWidth` thick (`pageSelectionOutlineReach` in
  all), in its window's gutter, under the grip; a document's page (its stack) gets the same ring in its
  viewport's margin, painted by the viewport, which is the box that stays while the page scrolls. A
  click on a page selects the child that covers it (a canvas's glass, a slide's panel, a document's
  stack), and so does a click in a document's margin (`ViewportWdgt.resolvesEditorSelectionToContent`);
  that child's ring is the page's. The world derives once per cycle who paints it, the nearest
  ancestor answering `hostsSelectionRingOf` (a window for its page, a viewport for its plane), and
  around which box (`hostedSelectionRingBox`, tracked; `noteHostedSelectionRingChanged`), and the
  selected child paints none. A plain viewport's plane, whose viewport keeps no margin, has its ring at
  the viewport's own box, closed on all four sides. A narrower gutter or margin than the ring's reach
  keeps the ring inside. Every other ring stays inside its widget (§5, Selection outline); a host's ring
  shares a column with a thin thumb where both lie (the thumb is not moved for it).
- A drop in a page's gutter, or in a document's margin, goes to the page by its own rules, moved inside
  its receiver (`dropReceiverForPointsOnMyBody`: the window's, the viewport's, a letterboxed Stretchable
  page's own margin); a drop on a document window's own body (its grip strip, the surround of its
  docked toolbar) goes to the page too, the window forwarding what its content's margin names. The
  dock offer is checked first. A press in the gutter or the margin moves the window; a finger's drag
  in an overflowing document's margin scrolls it.
- A highlight's form follows what it marks (`HighlighterWdgt`): a RING marks a thing that is there to see (the
  receiver a release reaches, one that declines it, the window a grip resizes, the selected widget); a WASH marks a
  place where nothing stands yet, where a release would put what the hand carries (the band a dock would make).
  The widget a hovered menu row names is washed: the ring on a thing is the selection ring's, and the right-clicked
  widget usually wears it.
- An overlay laid over a widget — a menu row's hover wash, the drag's ring around a target or one
  that declines the drop, the lock badge at its corner — frames what the widget presents to it
  (`boxPresentedToOverlays`: what shows of it, `clippedThroughBounds`; a document's plane box, not its margin).

## 5. The design on the widget tree
The design paints flat; Fizzygum paints a tree (parent, then children), so every pixel of the design has
exactly one owning widget:

| Design element | Owner |
|---|---|
| Window shadow, fill, 1 px frame | `FrameWdgt`'s body appearance (`BoxyAppearance`); the shadow is its `ShadowInfo` |
| Title bar fill and its rule | `FrameBarWdgt`'s `titlebarBackground`, its rule along the edge facing the frame's content (the band's own edge, §4.1) |
| Which side the bar takes | derived from the frame's RUN (`FrameWdgt._runAxis`), the axis it is long along: a host's slot gives its edge's length, expanded or collapsed; otherwise a payload that identifies itself while it shows (`identifiesItself`: a toolbar, whose tools are its identity) gives the frame's longer side, a square none; otherwise there is none. With no run the bar runs across the top (C15, where a title reads); expanded it runs ACROSS the run at its leading end (down the left of a wide toolbar window or a top band, across the top of a tall one or a side band); collapsed ALONG it (a top band's full-width strip, a side band's sliver). A collapsed free frame is held by nothing, so its bar is on top with its title. No knob. Decision record: `docs/archive/toolbar-grid-and-bar-run.md` |
| The bar's pieces | leading pieces (close, collapse) from the strip's start, trailing ones (the edit toggle) from its far end, the title centred between them; a piece the strip has no whole slot for gives way in the order edit toggle, collapse, close (`FrameBarWdgt.PIECE_DROP_ORDER`). A LONE piece alone on its strip centres (a docked band's collapse switch, a narrow window's close); anything more keeps its ends, title or not. A docked band offers its collapse piece only where collapsing gives room back: where it is thicker than its strip (a two-cell toolbox, a docked document), or while collapsed, the way back; a one-row toolbar band, as deep as its strip, offers none (`FrameWdgt._offersCollapse`); a window always offers it. A band's strip (a card's) that shows no piece and no title shows a GRIP MARK, the house's field of square dots (`Appearance._paintGripDots`: `gripDotSize` 2 on a `gripDotPitch` 6, here kept `barGripMarkInset` 12 in from the edges of its plate (the strip's background less its rule) on both axes, as many as the plate holds, centred; a strip too short for one dot shows none), painted by the strip's skin (`FrameStripAppearance`) in `cardBarGripMark` (`muted`), quieter than the strip's glyphs: the strip is the band's handle, and a press anywhere on it is the strip's |
| × / − in 44×44 targets | `CloseIconButtonWdgt`, `CollapseIconButtonWdgt` (in a `SwitchButtonWdgt`), children of `FrameBarWdgt` |
| Window title | `FrameBarWdgt`'s label `StringWdgt` (`fonts.windowTitle`; the focused window's in `fonts.focusedWindowTitle`, bold, every window's fit measured in it), its stored name shown as a sentence (§4.9). Shown on a horizontal bar, graded by fit (C13), and not while the payload shows and identifies itself (a toolbar window, which shows its title again collapsed) |
| Focused window | The frontmost top-level window (`WorldWdgt.isFocusedFrame`): `FrameWdgt._frameLook` answers the `focusedWindow*` roles — strip `chromeDark` with no rule, glyphs `chrome` lighting to `paper`, title `paper` bold, frame `chromeDark`, shadow 16 % (a tilted window's transform island casts it) |
| Edit-mode toggle | `EditIconButtonWdgt` + `EditModeToggleAppearance`, the strip's trailing piece, `barToggleBoxLength` (80) along the strip: a pill-shaped track with the eye at its leading end and the pencil at the other, and a knob under the current mode's icon. It lies along its box's longer side, left to right in a strip across the top, top to bottom in one down a side, by one along/across mapping (`EditModeToggleAppearance._inMyBox`) that never turns its glyphs. Inks from the frame's look: track `barToggleTrack` (`line`), knob `barToggleKnob` (`paper`), icon on the knob `barToggleKnobGlyph` (`ink`); on the focused window's strip `focusedWindowBarToggleTrack` (`code`) and `focusedWindowBarToggleKnob` (`desk`). The icon off the knob rests in the strip's glyph ink (`focusedWindowBarToggleGlyph`, `frame`, when focused) and takes the active glyph ink while hovered or pressed. A press anywhere flips the mode and the knob slides over `barToggleSlideMs` (160); a mode change from anywhere else lands at once. It is not the design's fixed-label TOGGLE (§4.8), because it names two modes rather than saying one thing is on. Decision record: `docs/archive/edit-mode-sliding-toggle.md` |
| Resize grip | `FrameGripWdgt` (a `HandleWdgt`, child of the frame, bottom-right, `frameGripInset` in from the content area) and `GripIconAppearance`, in `frameGripInk` at rest; its hit area is its whole `frameGripSize` square. While the pointer rests on it or a press on it stands, its strokes take `frameGripActiveInk`, the cursor is the resize cursor and the frame is outlined in `resizeTargetOutline`; a finger never rests, so it is shown this only while its press stands. A window in a window in view mode offers no grip (`FrameWdgt.offersAResizeHandle`: the nearest window's mode). On a collapsed frame it stands on the title bar, at the same place relative to the corner, while the bar has room for it beside its pieces (`FrameWdgt.shortestBarKeepingMyGrip`, 129 px for a window's close and collapse: they lead from the strip's start and the grip's reach is free after them), and takes nothing from them. There it wears the bar's glyph inks (`barGlyph`, `barGlyphActive`), the cursor is `ew-resize`, its drag sizes the bar's own width (`FrameWdgt.barsOwnWidth`: it does not change the width the window comes back at, and resizing the window does not change it) and stops at that narrowest bar, and a press that does not travel the grab threshold is a tap on the bar, which expands the frame. On an expanded frame a person's drag stops where its titled strip keeps every piece whole and its docked bars' chevrons stay usable (`FrameWdgt.smallestExtentKeepingMyControlsUsable`; code still sets any extent). A halo's handles are plain `HandleWdgt`s on a plate (below) |
| Grip strip | part of the frame's body (`FrameBodyAppearance`), `frameGripStripThickness` thick inside its border along the edge opposite the bar: its bottom, or its right beside a bar down its left (`FrameWdgt._gripStripSide`), so the grip keeps its corner either way. In `frameGripStripFill` whatever the frame's focus, with a `barRuleWidth` rule in `frameGripStripRule` along the edge facing the content. It exists exactly while the grip would show on an expanded frame (asking `HandleWdgt.wouldShow`; a collapsed frame has no body to keep it in), and the frame's body gives up that room (`_bodyEdgeBottom`, `_bodyEdgeRight`), so the payload's margin to it is the margin to the title strip's rule and no grip lies over a window's content or a nested window's grip. Being body, a press on it moves the window and a right-click on it is the window's; it offers no dock band (`_dockBandsBox`) |
| Halo handles | `HandleWdgt` + `HandleAppearance`: each handle a `handlePlateFill` (`paper`) plate over its whole `handleSize` (44) box at `handlePlateRadius` (6) inside a 1 px `handlePlateStroke` (`line`) border, `handlePlateHoverFill` (`desk`) hovered, `handlePlatePressFill` (`chrome`) inside `handlePlatePressStroke` (`frame`) pressed (pressed and hovered are two flags, so a release over the handle shows it hovered); its glyph `handleGlyph` (`ink`), drawn as fills through `SizeAwareIconAppearance.paintAsMarkInSquare`: move `FourWayArrowIconAppearance` and resize `DoubleArrowIconAppearance` / `VerticalDoubleArrowIconAppearance` at `handleArrowGlyphSize` (24), rotate `CurledArrowsSquareIconAppearance` (the four-swirlies square) at `handleRotateGlyphSize` (28), the corner `GripIconAppearance` at `handleCornerGlyphSize` (28); every type hits its whole box; the plate casts the shared desktop shadow (its silhouette, never the glyph's). A frame's grip opts out of that shadow |
| Drag feedback | Around a THING, `HighlighterWdgt`'s outline form (`HighlightOutlineAppearance`): a `dropOutlineWidth` (2) ring inside the box the target presents to an overlay (`boxPresentedToOverlays`: its `clippedThroughBounds`; a document presents its plane box, §4.10), `dropCandidateOutline` (`accent`) for a candidate, `dropReluctantOutline` (`line`) for a target that declines; its corners those the target shows (`Widget.cornerRadiiFollowingMyOutline`: its own rounded outline and its ancestors' rounded clips, concentric); its ring painted by `HighlightOutlineAppearance.paintRing`, shared with the selection outline. Over a PLACE, a window's dock offer, the fill form instead (`HighlightWashAppearance`, `HighlighterWdgt.landingAreaStyle`): the box of the band the release would make (`FrameWdgt.bandBoxIfDocked`: its place and its size once docked, never the strip the offer is made from) washed once in `dropLandingWash` (`accentWash`, translucent by its own alpha), its corners the host's where the band meets them, the host's own ring standing down; the dwell ring `dragArmRingFilled` (`accent`) segments over an opaque `dragArmRingEmpty` (`line`) track; the armed label `dragLabelText` (`ink`), the view-only badge `dragBadgeText` (`muted2`); the lift keeps `dragLift*` |
| Layout chrome | `LayoutChromeWdgt` (division adders, content drop slots, spacers — the "Edit layout" scaffold) + `LayoutChromeAppearance`: the halo's plate at today's sizes (`Appearance._paintPlate`, radius `layoutChromePlateRadius` clamped to the box: `layoutChromePlate*` roles — `paper` in a `line` border, `desk` hovered, `chrome` in `frame` pressed; a spacer shows no press), its glyph in `layoutChromeGlyph` (`ink`): an adder's `PlusIconAppearance` at `layoutAdderGlyphSize` (9) in a division strip and `layoutDropSlotGlyphSize` (14) in a drop slot, a spacer's double arrow at `layoutSpacerGlyphSize` (24) along its axis. A `LayoutChromeWdgt` takes its look from `createAppearance`, which a split's two controls override (next row) |
| A split's piece | A division stack's divider, its split adjuster (`StackElementsSizeAdjustingWdgt`: a halo's adjuster; and its kind `InspectorDividerWdgt`, an inspector browser's divider, across between two columns of its set or down between its set and its body below), and an inspector's split button (`SplitGripWdgt`), both `LayoutChromeWdgt`s wearing `SplitPieceAppearance`: ONE flat plate with no outline (`Appearance._paintPlate` with no stroke), `splitPieceFill` (`chrome`) at rest, `splitPieceHoverFill` (`chip`) while the pointer rests on either part of the piece, `splitPiecePressFill` (`line`) while either is pressed or dragged — a tone step of the WHOLE piece, both parts lit together. Its corners and its dots are what its widget declares (`_plateCornerRadii`, `_gripDotFieldOnMyPlate`), its dots the house's grip dots (`Appearance._paintGripDots`) in `layoutAdjusterGripMark` (`muted`). The ADJUSTER is `layoutAdjusterThickness` (12) across, square-ended, its dots as many as fit across (two), kept `layoutChromeGripDotsInset` (2) in from its edges, at most `layoutAdjusterGripDotsAlong` (4) along its long side, the field centred; a shorter adjuster shows fewer, a squeezed one a single column, and one too thin for a dot none. The dots are paint: every pixel of its box drags. The SPLIT BUTTON is a TAB on the divider before the inspector whose header it leads, along that divider's axis (`SplitGripWdgt.axis`, its one parameter): beside a column divider `splitButtonWidth` (32) wide and `minimumTargetSize` (44) tall, flush right of the divider; under the divider above a browser's body TURNED a quarter, 44 wide and 32 tall, flush under the divider, hanging from the top of the body's header (`crossAlignInABand`); so the piece the two make is 44 along the axis at the header (§4.2), with no line and no step between them: its corners against the divider square, its two free corners (beside, its right side's; turned, its bottom side's) rounded at `layoutChromePlateRadius`; its face a field of the adjuster's own dots, at most `splitButtonGripDots` (4) each way, centred along the axis on the WHOLE piece — from the divider's leading edge (its division box's thickness, a field, never the size it was laid out at) to the tab's far edge, so at these sizes it starts exactly at the tab's near edge and the tab paints all of it — and across the tab. A button standing anywhere else (taken out of its header) is alone: four rounded corners, the field centred on it. THE JOIN: the two parts hold each other (`LayoutChromeWdgt.joinedPiece`, never saved nor copied, its rule stated once there): introduced only by the reconcile of the inspector whose header the button leads (`InspectorWdgt._reconcileSplitGripNoSettle` → `noteJoinedBy`, which also joins them again in a copy or a restore), and parted on both sides by either part's going — the button's teardown (`SplitGripWdgt._destroyNoSettle` → `notePartedFrom`) and the divider's leaving the stack it divides, which the set or the browser hears (`InspectorRowWdgt._reactToChildRemoved`, `InspectorBrowserWdgt._reactToChildRemoved` → `noteLeftMyStack`) — so no reference of either outlives the other. Each part answers the other only while they hold each other and the button's inspector says that divider is the one it moves (`_myJoinedPiece`), so both agree: a button a person takes out of its header is painted alone. A widget repaints only itself, so each part tells the other when the hand's answers about it move (`noteMyPieceChanged`). A drag on either sizes the cell before the divider — the column on its left, or the strip of lists above it — (the divider's solve, which both handlers ask); a press on either is KEPT where it lands (`LayoutChromeWdgt.pressBegan`, for a piece that owns its drags), so the pane the set scrolls in never scrolls under the drag; while hovered or dragged, both show the resize cursor of their axis (`_resizeCursor`) |
| Slider | `SliderWdgt` (a content slider, a number prompt's) + `SliderButtonWdgt` (its thumb), both drawn by `CircleBoxyAppearance` as stadiums read at paint: the track an opaque borderless `sliderTrack` (`chrome`) groove unless the slider holds a colour of its own; the thumb in the button's look (§4.3), `sliderThumbFill` (`paper`) inside a 1 px `sliderThumbStroke` (`line`) wall (a filled stadium-border, concentric at the round ends), `sliderThumbHoverFill` (`desk`) hovered, `sliderThumbPressFill` (`chrome`) inside `sliderThumbPressStroke` (`frame`) pressed; a fill override the thumb holds for a state (`normalColor`, `highlightColor`, `pressColor`) is that state's fill. A viewport's scroll bars are the same class in an indicator presentation: their track `scrollIndicatorTrack`, their thumb `scrollIndicator*`, no border; a bar picked up off its viewport is a plain slider |
| Colour picker and palettes | `ColorPickerWdgt`'s background `colorPickerFill` (`paper`, read at paint while it holds no colour of its own); a palette's (`ColorPaletteWdgt`, `GrayPaletteWdgt`) choice marker (`PaletteAppearance`) a 1 px ring in `paletteMarkerOuter` (`ink`) just outside one in `paletteMarkerInner` (`paper`), legible over any hue; a choice that is not on the palette is said by two `paletteMarkerOuter` hairlines around a 2 px band of the choice framing the field. The gradients are content |
| Selection outline | `Widget._drawSelectionOverlay` around the item an op would act on (`WorldWdgt._widgetBeingEdited`): a `selectionOutlineWidth` (2) ring in `selectionOutline` (`accent`), wholly inside the selected widget's box (a page's and a plane's excepted: a window paints a page's in its gutter, a viewport its plane's in its margin or at its own box, §4.10), its corners `cornerRadiiFollowingMyOutline`, painted by the drop outline's `HighlightOutlineAppearance.paintRing` (its 1 px stroke half only over a body with a border: `outlineIsStroked`); never shown while a caret is in the widget or inside it — the caret says "focus" there — and never around a top-level window (focused, never selected: the one write of the editor focus refuses one, `WorldWdgt._setEditorFocusNoSettle`) or a desktop icon (it wears its own selected look, §4.3), nor around content in view mode (`Widget.sitsInViewModeContent`: no op may act there) |
| Text selection | `StringWdgt.drawSelection` (every text, so every `TextWdgt` and paragraph): per selected character, a `textSelectionFill` (`accent`) plate over its whole line box, the character re-typed on it in `textSelectionText` (`paper`), read at paint; the plate is opaque, because neighbouring characters' plates overlap by a pixel |
| Hover wash | `HighlighterWdgt`'s fill form (`HighlightWashAppearance`, `HighlighterWdgt.namedByARowStyle`, from `Widget.turnOnHighlight`: a menu row that stands for a widget — a hierarchy menu's, a chooser's — washes it while hovered; a wash on a thing, the one there is, since a ring there would double the selection ring): the box the target presents to an overlay (`boxPresentedToOverlays`: its `clippedThroughBounds`; a document presents its plane box) filled once in `hoverHighlightWash` (`accentTint`, translucent by its own alpha) at full widget alpha, its corners those the target shows (`cornerRadiiFollowingMyOutline`, as for the drop outline); no stroke, no shadow |
| An icon holder's empty slot | `SimpleDropletWdgt` + `SimpleDropletAppearance`: a placeholder, not a button: a borderless `dropletWellFill` (`desk`) well at `dropletWellRadius` (6) with a `PlusIconAppearance` in `dropletGlyph` (`muted3`) at `dropletGlyphSize` (half the desktop glyph) |
| Embedded toolbar with its title strip | a docked `FrameWdgt` (a card under an `EdgeDockLayoutSpec`) holding a toolbar; its bar runs vertically. The band stands `dockedBandInset` in from the host's body on its three outer sides (the host's body margin, when wider) and the host's body margin from the payload on the fourth (a page's gutter, §4.10; a pane's 0, a document keeping its own margin below the band). Several bands of one side stand side by side, the newest nearest the payload, as far apart as bands of different sides stand where they meet: the band inset past the body margin, plus the body margin (8 on a Maker; `FrameWdgt._bandBoxesAt`); its thickness is the toolbar's `dockThickness`, derived from the theme's grid dials at every measure (`EdgeDockLayoutSpec.thicknessGrantedTo`), at a depth counted in cells: the toolbar's own (one, the theme's `toolRows`; the paint toolbox two, so its band is 96 deep: its four tools two by two in a side column, one row of a two-row band across a top or bottom) or the depth it stood at as it arrived (`EdgeDockLayoutSpec.depthInCells`). The toolbar and its grid paint nothing (`SeamRulesAppearance`): the band's card is the one line around them. Its cells (44, least 6 apart) form a grid that fills the toolbar's box, in reading order, `toolAlongPadding` from the ends of the box's longer side and with no padding along the other, so a one-row strip is one cell deep, 44, and its band 46 with the card's two border lines: a strip's thickness (`FrameWdgt._barSpec`), so one-row bands of every kind line up on every side, and a collapsed one-row band, which is its strip, is as deep as the band it was. The grid runs along its band (the band's run axis) whatever its box's shape. A box one cell deep is a strip. While every cell fits they are PACKED from the start and the leftover lies past the last, so a tool keeps its place however long the strip grows; a box too small for every cell shows the prefix that fits and a trailing `»`, and only then is its leftover (always under one cell) shared space-between along each axis, putting the `»` at the far end. A floating toolbar wears a window's bar across its run ("Which side the bar takes") |
| Document paragraph items | `SimpleTextWdgt` paragraphs in `DocumentViewportWdgt`, a borderless `documentPageFill` page whose stack keeps `documentItemSpacing` between items (asked through the plane, `interElementGapOfPlane`) and from its viewport's edges, its viewport keeping that spacing as its plane margin (§4.10), windowed or bare, read at every arrange. Every paragraph a document builds comes from `getNormalParagraph`: `fonts.document` (15 px on 22 px lines; a title at its own size keeps that line height scaled with its em box) in `documentText`, on `editableItemFill` (= `item`); in view mode an item melts into the page it sits on (`blendInWithPanelColor`, both colours read live), and a background the user set stays. Every text standing on the page (a template excepted) wears the ITEM SHAPE, asked at every measure, paint and point mapping and never stored (`StringWdgt._itemShape` → its stack → `DocumentViewportWdgt.itemShapeOfTextOnPlane`): its fill rounded at `documentItemCornerRadius`, its text inset `documentItemHorizontalPadding` from the sides and `documentItemVerticalPadding` from top and bottom, so a one-line paragraph is 34 tall and wraps at its width less 20; a press in the padding picks the nearest slot of the nearest line, and the hit shape is the rounded fill. Off the page (dragged to the desk, in the hand) the same text is plain. A widget dropped into the stack goes before the first item whose middle is below the drop point |
| Menu container, header, rows, group rules | `MenuWdgt` (a transient `FrameWdgt`) → bar (header) → `PopUpRowsViewportWdgt` → `CommandPanelWdgt` → `MenuItemWdgt` rows + `DividerWdgt` |
| An inspector browser | `InspectorBrowserWdgt` (a `ClippingWdgt`, in a window or with none) paints the body under all its parts (`inspectorBodyFill`); top to bottom its trail (§4.3, "The trail"), its set's viewport and, with its body below (`bodyPlace`, the default), a divider and the body at its full width, the viewport then the STRIP OF LISTS above them (with the body beside, the body is the set's last column). The viewport (`InspectorRowViewportWdgt`) adds no look of its own (no border, no fill, a thin scroll bar while the set overflows), and its set (`InspectorRowWdgt`, that viewport's plane) paints nothing; the inspectors (`InspectorWdgt`) paint nothing, their views' panes wear the inspector's pane roles (`inspectorPaneFill`, `inspectorPaneStroke`: none), and a divider (layout chrome, above) stands between two columns and between the strip and a body below it. While nothing shown as one text is chosen the body is an EMPTY one, an inspector on no subject whose header reads "(nothing chosen)" over a view that paints nothing. A part of the tool standing anywhere else (an inspector picked out of its set, a view taken out of its inspector) paints that body itself, its box filled in `inspectorBodyFill` under its seam rules, and casts one box of shadow, its parts' silhouettes left out (`InspectorBodyAppearance`, which asks at paint whether its holder answers `laysTheInspectorBodyUnderItsParts`) |
| An inspector's bands | `BandWdgt`s, rows of controls at their own sizes centred down the band, each painting only its 1 px rule (`inspectorRuleWidth`) inside its height (`SeamRulesAppearance`, §4.1): a browser's trail (`footerBandHeight`, its rule at its bottom) holds a button per step and a chevron between two (§4.3); the header (`inspectorHeaderHeight`, its rule at its bottom) holds the split button while a divider stands before the inspector (beside a column divider, or turned under the divider above a body), the subject's name (`fonts.buttonLabel` in `inspectorHeaderTitle`, cropped with "…" where it runs long) and the class button (§4.3); the chooser band under it (`toggleBandHeight`, its rule at its bottom), only while the subject offers more than one view, holds a toggle per view; a member list's toggles band has its rule at its bottom, its cut-notice band and its band of verbs (§4.3) at their top, and an object list's cut-notice band too |
| A window content's row of buttons | its footer band (`FooterBandLayout`, the geometry); the rule is the host's seam, painted by its appearance (`SeamRulesAppearance` for a host with no look of its own); a member list's band of verbs is a band of its own (`ListVerbsBandWdgt`, a `BandWdgt`, above) at the footer's height, inset and gap, its buttons faced by drawn marks (§4.3) |
| Desktop icon tile, glyph and label plate | `WidgetHolderWithCaptionWdgt` and its appearance `DesktopIconAppearance` (the tile and the plate are paint; its hit shape and its silhouette are the two shapes); the glyph is its `icon` child in the glyph square, the caption its `label` `TextWdgt` on the plate (§4.3) |
| Spreadsheet grid | `SimpleSpreadsheetWdgt` (a PAGE, §4.10) and its children: the formula bar (`SheetFormulaBarWdgt` + `SheetFormulaBarAppearance`), the header cells (`SheetHeaderCellWdgt` + `SheetHeaderCellAppearance`) and the data cells (`CellWdgt` + `CellAppearance`); the sheet's own paint is its page edge, 1 px of `stretchablePageEdge` (`line`) on all four sides, over its children (`SheetAppearance`). At 100% a row is 36 tall, a column 104 wide, the number column 48, the letter row 36; the sheet's ZOOM (60–200%) multiplies those, the text and its 4 px inset, never a hairline. The formula bar, `spreadsheetFormulaBarHeight` (44) and unzoomed: the selected cell's address in `spreadsheetHeaderText`, its source in a text field's well (`textFieldFill`, `textFieldCornerRadius`), an error's message in `spreadsheetErrorText`, the zoom button ("100%") at its right end, all in `fonts.spreadsheetFormulaBar` (16); a 1 px `spreadsheetHeaderRule` under it. A header: `spreadsheetHeaderFill` (`desk`), its letter or number `fonts.spreadsheetHeader` in `spreadsheetHeaderText` (`muted2`), centred on its height; the line under the letter row and right of the number column `spreadsheetHeaderRule` (`line`), every other edge `spreadsheetGridline` (`chrome`), each a 1 px edge a cell or header strokes along its own top or left (`SimpleSpreadsheetWdgt.paintGridEdges`); none along the sheet's outer left (the page edge is the line) or under the formula bar (its rule is), nor where a neighbour's text spills over a cell; the selected cell a 2 px `spreadsheetSelectionRing` (`accent`) inside its edges; a cell's fill, when its format sets one, under its edges; a value `fonts.spreadsheetCell` (16) in `spreadsheetValueText` (`ink`), centred on its row, numbers at the cell's right and everything else at its left unless the format says otherwise, an error value in `spreadsheetErrorText` (`danger`). In VIEW mode (the sheet's own, its window's eye) it is a sheet to read and use: the headers are put away and the cells take their room (`showsHeaders`), a gridline is the fainter `spreadsheetGridlineViewing` (`item`), the first column's left edge and the first row's top edge are none (the page edge and the formula bar's rule are the lines there), and the formula bar's field loses its well, its source reading as plain text on the paper, as a document's item melts into its page; the selected cell keeps its ring, which says whose source the bar shows. Every colour is read at paint or build time, so a saved or duplicated sheet wears the current look |
| Plot | `GraphsPlotsChartsWdgt` and its examples: the area `plotBackgroundFill` (`paper`), the box `plotFrameStroke` (`line`, the crisp spelling), a `PlotWithAxesWdgt`'s surround `plotSurroundFill` (`paper`, read at paint), its axes' line, ticks and labels `plotAxisInk` / `plotAxisLabelText` (`muted2`, applied at every arrange), a 3D plot's ground grid `plotGroundGridInk` (`muted2`, read at paint, at the mesh's alpha); the series are content |
| A Maker's page | `StretchablePanelWdgt` (the Slides Maker's, the Dashboards Maker's, Generic panel's and Patch programming's page) through `StretchablePanelAppearance`: `stretchablePageFill` (`paper`), read at paint; a 1 px `stretchablePageEdge` (`line`) on all four sides while its container stands in a window's page gutter (§4.10), else only along a side where its container letterboxes it (the crystallized ratio), none along a side flush with it |
| Folder window | `FolderWindowWdgt`: its panel `folderPanelFill` (`paper`), read at paint; the panel and its viewport borderless (the window's frame and strip rule are the lines); its title "Folder — Examples" (§4.9) |
| Fizzytiles | `FridgeMagnetsWdgt`'s fridge, tiles bin and output pane on `paper` inside `line` borders (`fizzytiles*` roles, read at paint), the four captions `fonts.fizzytilesCaption` in `fizzytilesCaptionText` (`muted2`); the code pane `fonts.code` in `codeText` on `fizzytilesCodePaneFill`, no border; a MAGNET (`MagnetWdgt`, `MagnetAppearance`) the button's look derived at paint from its state (`magnetFill` `paper` inside a `magnetStroke` `line` border, `magnetHoverFill` `desk` hovered, `magnetPressFill` `chrome` inside `magnetPressStroke` `frame` pressed, rounded at `magnetCornerRadius` 6; hit shape and silhouette the rounded box), its label a code token in `fonts.code` and `magnetText` (`ink`) |
| Generic panel and viewport | `PanelWdgt` and `ViewportWdgt` hold no colour of their own and are painted in roles read at paint (`_surfaceFill`, `_surfaceStroke`): `panelFill` (`panel`) inside a 1 px `panelStroke` (`line`), and no border of their own as a window's whole content (`FrameWdgt.isMyContents`, asked at paint: `windowContentPanelStroke`, none — the frame's border and its strip's rule are that line). A viewport's default plane wears its viewport's pane look (`ViewportWdgt._paneFill`): its class's pane fill (`_defaultPaneFill`: a plain list's and a text area's `paper`, the stack sample's `panel`, a document's page), or the roles a builder dresses it in BY NAME (`wearPaneRoles`: an inspector's member list and member editor, a code area, a patch node's text box, the bin's pane, a folder window's viewport), which travel with the pane wherever it is taken. A bare `VerticalStackPanelWdgt` wears the panel look (`stackPanelFill`, `stackPanelStroke`). A colour set on one (`setColor`) wins over its role. |
| Plain buttons | a `ButtonWdgt` with no look of its own (a bare `ButtonWdgt` given an appearance, the demo's `SimpleRectangularButtonWdgt`): `plainButtonFill` (`paper`) at rest, `plainButtonHoverFill` (`desk`) hovered, `plainButtonPressFill` (`chrome`) pressed, read at paint from the hand's answers (`ButtonWdgt._fillForMyState`); the rectangular button's square border `rectangularButtonStroke` (`line`) |
| Icon buttons off a strip | an `IconButtonWdgt` no frame strip inks (the demo's close icon, a pointer's close button): its glyph `iconButtonGlyph` (`muted`) at rest, `iconButtonGlyphActive` (`ink`) hovered and pressed; a strip inks the glyphs it carries itself (§5's frame look) |
| The edit mark (`EditableMarkWdgt`), worn by a widget that names code to edit (`_memberToEdit`) | `UpperRightTriangleIconicButtonWdgt`: the triangle `editMarkFill` / `editMarkHoverFill` / `editMarkPressFill` (`paper` / `desk` / `chrome`) by state, its pencil `editMarkInk` (`ink`) |
| Canvas | a `CanvasWdgt`'s raster (Draw's canvas, a factory canvas) is laid on `canvasFill` (`paper`) as it is made, enlarged or cleared, unless a colour is set on the canvas |
| Header-line rule | `StringWdgt._drawHeaderUnderline` (a document's divider, a patch node's field labels, Fizzytiles' captions): a 1 px `headerLineRule` (`chrome`) through the middle of the line, broken 5 px either side of the text, read at paint and part of the text's back-buffer key |
| A code pane's modified mark | `ModifiedTextTriangleAnnotationWdgt` + `UpperRightTriangleAppearance`: the 10×10 top-left triangle in `codePaneModifiedMark` (`muted3`), read at paint, shown while the text differs from its reference |
| Speech bubble | `SpeechBubbleWdgt` + `BubblyAppearance`: `speechBubbleFill` (`plate`) inside a 1 px `speechBubbleStroke` (`line`), read at paint (`BoxyAppearance._fillColor` / `_borderColor` ask a widget holding no colour for its `_surfaceFill` / `_surfaceStroke`), radius 6, its tail at the bottom-left; its text `fonts.speechBubble` (12, italic, scaled to fit the bubble) in `speechBubbleText` (`ink`) |
| The error log's footer | Clear, the fixed-label "Pause" toggle (`LabelledToggleWdgt`, on while paused) and OK in its footer band (§4.3) |
| Clock | `AnalogClockWdgt` + `AnalogClockAppearance`: an opaque `clockFace` disc (no border) that is also its hit shape and its silhouette, four `clockMark` dots, hour and minute hands in `ink`, the second hand and the centre dot in `accent`; every width a whole number of device pixels of the face's parity (`pixelsForUnits`), so a hand is one width pointing any way; round caps from 4 px |

Menus, windows, cards and docked bands are ONE class, `FrameWdgt`; which skin a frame wears is derived
from its lifetime and its parentage ([`regularity-principles.md`](regularity-principles.md), "The frame
model"). **`FrameWdgt._frameLook()` is the one place a frame's look is decided**: a pure query answering
one record — the manifestation (menu, window, card), the body's appearance, fill, stroke and rounding,
the strip background's appearance, colours, rounding and rule, the title's ink, and the shadow
it casts at rest — from the frame's lifetime and parentage. The body (`_deriveAndSetBodyAppearance`), the strip (`FrameBarWdgt`) and the shadow (`addShadow`)
all READ it; none decides a look of its own. FOCUS enters there and nowhere else: the frontmost visible
top-level window (`FrameWdgt.isTopLevelWindow` — a persistent frame whose home is the desktop, seen
through a transform island; a pinned or grabbed menu among them) is the focused frame, and a persistent
frame the hand carries is focused for the whole carry. The world derives it ONCE per cycle from z-order,
just before the geometry settle (`WorldWdgt._updateFocusedFrameNoSettle`; queried as `isFocusedFrame`),
because the focused title is BOLD and a bolder title is a layout input; there is no stored focus flag.
The focused window wears a `chromeDark` strip with no rule, `chrome` glyphs that light to `paper` while
hovered or pressed, a `paper` bold title, a `chromeDark` frame and a 16 % shadow
(`focusedWindow*` roles); every other window wears the window roles. A focus change re-skins NARROWLY
(`FrameWdgt.noteFocusChanged`): the strip, the frame's stroke and the shadow cast at rest — never the
body's fill or rounding, so a colour set by hand survives a flip — and a carried frame is re-skinned too,
its shadow left to the hand. A window's title is FIT in the focused weight whether or not it is focused
(`titleFitBold`), so a flip never changes which characters it shows; a card's and a menu's title is fit
in its own weight. Collapsed and docked are not inputs: a collapsed frame wears its expanded look,
and a docked band is the card its parentage makes it; only the strip's corners follow the collapse and
the strip's axis, and its grip mark what the strip shows, set at every arrange (§4.7). The whole skin is applied on EVERY derivation, as one act
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
  names something and as a sentence when it is a message or a prompt's question (§4.9). A pop-up is at least as
  wide as its title (`CommandPanelWdgt.maxWidthOfMenuEntries` counts it, `FrameWdgt._titleEntryWidth`). Pinned,
  it is a window: it takes its rows' width, re-taken at the lifetime change itself (`FrameWdgt._setLifetimeNoSettle`;
  `fullCopy` for a copy born furniture), and its strip crops or hides a title that does not fit — so a menu's
  width is a function of its rows, its title and its lifetime, never of the lifetime it had at its last add.
- **Rows** (`MenuItemWdgt`): label 15 px `ink`, 10 px in from each side. A `desk` plate of radius 6
  over the whole row while hovered, `chrome` while pressed (`LabelButtonAppearance`), and no hairline.
  A DISABLED row (its enablement does not hold: `MenuItemWdgt.isDisabled`, read as it paints and as it is
  pressed) keeps its shape and loses contrast: its label, its picture (a raster as its silhouette, a typed face
  re-inked), its tick and its chevron all in `menuRowDisabledText` (`disabledText`), no hover or press plate, its
  rest fill, pinned grip, tooltip and wording kept. A tick stays, greyed: the state it reports still holds.
- **Groups:** a `DividerWdgt` band between groups, 9 px with its own centred `chrome` rule.
- **Entry field** (a prompt's, `StringFieldWdgt` + `StringFieldAppearance`): a borderless `textFieldFill` (`item`) well
  rounded at `textFieldCornerRadius` (6), read at paint; 18 tall, its text 5 px in and 2 px down, `fonts.prompt`; the
  whole box is the press target. A number prompt's slider below it is a content slider (§5's Slider row), 44 tall.
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

The row's label stays its plain wording.

**A plain list** (`ListWdgt` without `memberFactsQuery`) wears the draft's list look (§7.1), as the member list does: its rows
panel paints no box (`listRowsPanelFill`, clear, no stroke) and stacks its rows `listRowsPanelPadding` (4) in; each row
(`MenuItemWdgt` built `listRow`) is `listRowHeight` (42) tall and flush, its label `fonts.listRow` (15 px) in `listRowText`
(`ink`) `listRowSideInset` (8) in, on no fill; a `listRowHoverFill` (`desk`) plate `listRowPlateHeight` (40) tall at
`listRowPlateRadius` (6) from its top while hovered (a flag of its own, `_restPlateFill`: a list row's highlighted state is
its selection), a `listRowSelectedFill` (`accentTint`) plate while it is the list's selection or pressed, and no hairlines.
The rows panel opts out of the editor outline (`providesAmenitiesForEditing: false`): a selected row shows its plate only.

**Code panes** (a member editor's, the script window, the console, the error log)
are built in the code role: `fonts.code` (12 px mono), `codeText`, `codePanePadding` (12) — a `TextAreaWdgt`
forwards `fontRole` and `textColor` to its text. A text area's text paints no background of its own (`textAreaTextFill`, transparent): the pane shows behind it. A code area is dressed in the code pane's roles
(`wearPaneRoles`): a `codePaneFill` (`paper`) pane and no border (`codePaneStroke`): it is its window's content, so the
window's border, its strip's rule and its footer's rule are its lines (a bare `TextAreaWdgt` keeps the panel's `line`
border on its `textAreaFill`, `paper`). A member editor's code area, and its text's background, wear the inspector's pane
roles instead (`inspectorPaneFill`, `inspectorPaneStroke`: none), so the body of its inspector browser shows through. A patch node's text boxes (`PatchNodeWdgt._newTextBox`) take `fonts.code` and `codeText` at their own padding (5),
inside a 1 px `patchNodeTextBoxStroke` (`line`) border; a calculating node's field labels ("Formula", "Output") are
`fonts.buttonLabel` in `patchNodeFieldLabelText` (`muted2`). Its lines stand on the role's 18 px
line boxes (the draft's; on SWCanvas: baseline 12, caret rows 1–15 of each line).

**An inspector's member list** (`MemberListWdgt`) wears the member-row look: it builds its `ListWdgt` with
`memberFactsQuery`, and the list's rows panel builds `MemberRowWdgt`s (`CommandPanelWdgt._createMenuItem`). Each
row is `memberRowHeight` (42) tall and flush, as wide as the list less the panel's 4 px padding (no hug to the
widest name, no horizontal bar); the kind tag (`fn` for a function, else `var`, 10 px bold `muted2`, `accent`
while the row is selected) sits in an 18 px column at x 8, and the name (13 px mono, `ink` for an own member,
`muted` for an inherited one) at x 34 in a box that crops with "…". The selected row paints a 40 px `accentTint`
plate of radius 6 at its top; no row paints a hairline, and the panel opts out of the editor-selection frame
(`providesAmenitiesForEditing = false`), so a selected member shows only its plate. An inspector's **object list**
(`ObjectListWdgt`: Children, Instances, Subclasses) wears the same look, its facts an empty kind tag and never dimmed
(`objectRowFactsOf`), so a row is a name in `ink` with its tag column empty.

## 6. How a new widget picks its look

1. **Chrome or content?** Content (a shape the user draws, a plot series, a document's text) keeps its
   own colours and sizes. Chrome — anything that frames, controls or annotates content — takes its look
   from `Theme`.
2. **Colours:** read the role named for your surface (`WorldWdgt.theme.<role>`); if your surface has
   none, add one to `Theme`'s ROLES section, named for the surface, at the value it paints with.
   Never a colour literal in a chrome file (§1, the ratchet). Read it where the look is USED — at paint,
   at arrange, at a state change — never copied into the widget as it is built: a copied colour is
   serialized and pins the old look in every saved or duplicated widget. A surface that wears a role
   holds no colour of its own and answers `_surfaceFill` / `_surfaceStroke`, which its appearance asks
   (`RectangularAppearance`, `BoxyAppearance`, `CircleBoxyAppearance`); a colour set on it still wins.
   A state colour is read at paint from the hand's answers (`_fillForMyState`), never declared at class level (a
   class-level declaration cannot read `Theme`). A pane a builder dresses wears roles by NAME
   (`ViewportWdgt.wearPaneRoles`), so it keeps them wherever it is taken.
3. **Text:** `fontRole: WorldWdgt.theme.fonts.<role>`.
4. **Sizes:** chrome dimensions are `Theme` metrics; a chrome target is at least 44 (§4.2).
5. **Shape:** pressable ⇒ bordered and rounded (§4.3); per-corner radii where it sits inside a rounded
   host (§4.7).
6. **Symbols:** drawn size-aware icons, named for their shape (§4.5, §4.6).
7. **Lines between your panes:** seams you own (`_seamRects`, §4.1), not pane borders.
8. **Shadow:** nothing to do — an object on the desktop casts the shared shadow.
9. **In a window — a page or a pane?** A surface you work on is a PAGE: answer `wantsWindowPageGutter`,
   and keep no outer margin of your own that the window's gutter already gives you. A view whose edges
   are the window's lines is a PANE and answers nothing; a pane that scrolls and wants air round what
   it scrolls keeps it as its viewport's plane margin, as a document does (§4.10).
10. **Does your look depend on focus or selection?** Never store a "focused" or "selected" flag. A
    frame's focus reaches its look only through `_frameLook` (`world.isFocusedFrame`); a widget's
    selection is read at paint from the world's once-per-cycle caches (`world.isEditorSelected` for the
    generic ring, `world.isSelectedIcon` for a desktop icon's own look). A top-level window is focused,
    never selected; everything inside it, and a window nested as content, stays selectable.

**Reviewing a change to the look.** A change that moves chrome pixels is reviewed BEFORE any recapture
on the owner-review sample, one or more tests per surface the system dresses
([`../tooling/visual-review-sample.txt`](../tooling/visual-review-sample.txt), run as
`fg diffpage $(grep -v '^#' Fizzygum/docs/tooling/visual-review-sample.txt)` from `Fizzygum-all/`),
and in the live worlds (`index-sw.html` on SWCanvas, `index.html` on the native canvas). Every changed
pixel is classified before the references move; add a test to the sample when a change touches a
surface it does not show.

See also [`widget-authoring-guidelines.md`](widget-authoring-guidelines.md) §15 and
[`appearance-paint-convention.md`](appearance-paint-convention.md) (how an appearance paints).

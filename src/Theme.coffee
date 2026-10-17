# Theme -- the ONE place the system's LOOK is decided: its named colours, the colour each piece of
# chrome paints with, its font roles, its chrome metrics and its shadows. PreferencesAndSettings
# keeps BEHAVIOUR (input, timing, thresholds); anything that changes only what the world looks
# like lives here.
#
# A world builds its theme as it is constructed and reaches it as the static WorldWdgt.theme, a
# sibling of WorldWdgt.preferencesAndSettings. A snapshot never saves or restores it: a look is not
# user state, so a restored world wears the look of the page that loads it.
#
# Every value is assigned in the constructor, because a class-level default may not reference
# another class (the boot dependency scanner sees only declaration-level edges) and most values
# here are Colors. A reader copies a value where it needs it (a constructor taking its fill, a
# layout reading a metric); nothing holds the theme object itself, which is why it carries no
# serialization or duplication marker.

class Theme

  constructor: ->

    # ---- PALETTE ---------------------------------------------------------------------------
    # The design system's named colours, at their DRAFT values (the token table in
    # docs/architecture/visual-design-system.md). A palette colour paints nothing by itself:
    # the ROLES below point at palette colours surface by surface, as each surface adopts the
    # design, and until a role does so it keeps the value its surface paints with today.
    @ink = Color.create 0x1E, 0x1E, 0x1C
    @chromeDark = Color.create 0x4A, 0x4A, 0x46
    @chrome = Color.create 0xE2, 0xE2, 0xDE
    @line = Color.create 0xC9, 0xC9, 0xC4
    @frame = Color.create 0xB9, 0xB9, 0xB4
    @chip = Color.create 0xD2, 0xD2, 0xCD
    @desk = Color.create 0xEC, 0xEC, 0xE8
    @plate = Color.create 0xF4, 0xF4, 0xF1
    @item = Color.create 0xF0, 0xF0, 0xEC
    @panel = Color.create 0xFA, 0xFA, 0xF8
    @paper = Color.create 0xFF, 0xFF, 0xFF
    @muted = Color.create 0x6A, 0x6A, 0x66
    @muted2 = Color.create 0x8A, 0x8A, 0x85
    @muted3 = Color.create 0xA5, 0xA5, 0xA0
    @text2 = Color.create 0x55, 0x55, 0x4F
    @code = Color.create 0x3A, 0x3A, 0x36
    @grip = Color.create 0xBD, 0xBD, 0xB8
    @disabledText = Color.create 0xB9, 0xB9, 0xB4
    @accent = Color.create 0x2F, 0x5B, 0xEA
    # the accent at 12% (0x1F of 0xFF): the fill of an "on" or selected control
    @accentTint = Color.create 0x2F, 0x5B, 0xEA, 0x1F / 255
    @danger = Color.create 0xC4, 0x32, 0x1C
    @scrollbar = Color.create 30, 30, 28, 0.35

    # ---- ROLES -----------------------------------------------------------------------------
    # What each piece of chrome paints with. A role names ONE surface, so a surface can be
    # restyled without moving another: two surfaces that paint the same colour today still hold
    # two roles (the tooltip and the speech bubble share the menu row's fill and the menu's stroke
    # by value, never by name).

    # the pop-up (menu) header: the header box's fill, and the background of the title text
    # centred in it.
    @menuHeaderFill = Color.create 125, 125, 125
    # the pop-up header's title text.
    @menuHeaderText = Color.create 255, 255, 255
    # the menu box's stroke, and the stroke of the rows panel a menu or list stacks its rows in.
    @menuStroke = Color.create 186, 186, 186
    # the menu box's body: the fill a TRANSIENT frame wears (a menu pinned from it keeps it).
    @menuBodyFill = Color.create 238, 238, 238
    # the rows panel a menu or list stacks its rows in (CommandPanelWdgt).
    @rowsPanelFill = Color.create 238, 238, 238
    # a menu row's flat fill at rest, and the ink of its label.
    @menuRowFill = Color.create 250, 250, 250
    @menuRowText = Color.create 50, 50, 50
    # the grip bar a pinned menu's liftable row paints along its left edge.
    @menuRowGrip = Color.create 169, 169, 169
    # The hairline a row paints along its TOP edge when the row above it is another row (ruling
    # G5): paint, never layout, so rows stay flush and no dead zone opens between two targets.
    # Fainter than menuStroke, because a menu's own border is a boundary and this is only a rhythm
    # mark inside it.
    @menuRowSeparator = Color.create 225, 225, 225
    # the rule a menu draws between two groups of rows (DividerWdgt).
    @menuDivider = Color.create 230, 230, 230

    # the tooltip bubble's fill and stroke, and the ink of its text.
    @tooltipFill = Color.create 250, 250, 250
    @tooltipStroke = Color.create 186, 186, 186
    @tooltipText = Color.create 0, 0, 0
    # the speech bubble's (the placeable callout's) fill and stroke.
    @speechBubbleFill = Color.create 250, 250, 250
    @speechBubbleStroke = Color.create 186, 186, 186

    # a window's title strip on the desktop (an external frame) ...
    @windowBarFill = Color.create 125, 125, 125
    @windowBarStroke = Color.create 100, 100, 100
    # ... and nested in a real container (an internal frame: a card).
    @cardBarFill = Color.create 172, 172, 172
    @cardBarStroke = Color.create 150, 150, 150
    # the title text in a window's or a card's strip.
    @windowTitleText = Color.create 255, 255, 255
    # a window's (and a card's) body stroke and fill: what a frame born furniture is built with
    # (FrameWdgt._frameLook).
    @windowFrameStroke = Color.create 125, 125, 125
    @windowBodyFill = Color.create 248, 248, 248

    # the fill and stroke every PanelWdgt and ViewportWdgt starts with.
    @panelFill = Color.create 249, 249, 249
    @panelStroke = Color.create 198, 198, 198
    # the rule between two panes a container places 1 px apart (Widget._seamRects); draft §6.4.
    @seamRule = @chrome
    # a list's background (ListWdgt).
    @listFill = Color.create 255, 255, 255
    # the open bin's content pane: its viewport and the contents panel inside it.
    @binViewportFill = Color.create 255, 255, 255

    # the body of a text area (TextAreaWdgt), and of the mono text panel it configures into.
    @textAreaFill = Color.create 255, 255, 255
    # the editable code pane: a script, console or code prompt's editor body, and the inspector's
    # detail pane.
    @codePaneFill = Color.create 255, 255, 255
    # the background of a one-line text-entry field (StringFieldWdgt).
    @textFieldFill = Color.create 255, 255, 255
    # the text caret's fill.
    @caretFill = Color.create 0, 0, 0
    # a TextWdgt's text selection: the selected glyphs' ink and the highlight behind them.
    @textSelectionText = Color.create 255, 255, 255
    @textSelectionFill = Color.create 60, 60, 120
    # the "save" label of a code prompt and of the inspector while there is an edit to save ...
    @saveLabelEnabledText = Color.create 0, 0, 0
    # ... and while there is none.
    @saveLabelDisabledText = Color.create 200, 200, 200

    # a number prompt's slider: its track, and the base its thumb derives its hover and press
    # colours from.
    @promptSliderTrack = Color.create 225, 225, 225
    @promptSliderThumb = Color.create 60, 60, 60
    # a slider's (and a scroll indicator's) track when its builder names no colour.
    @scrollTrack = Color.create 0, 0, 0

    # a button's border (SimpleButtonWdgt, SimpleRectangularButtonWdgt) ...
    @buttonStroke = Color.create 196, 195, 196
    # ... and a simple button's fill.
    @buttonFill = Color.create 245, 244, 245

    # the resize/move handle's arrow art at rest: its ink and the shadow drawn under it ...
    @handleArtInk = Color.create 255, 255, 255
    @handleArtShadow = Color.create 150, 150, 150
    # ... and while the handle is highlighted.
    @handleArtHighlightedInk = Color.create 255, 255, 255
    @handleArtHighlightedShadow = Color.create 200, 200, 255

    # a world's own fill, under everything: what a world shows when createDesktop has not
    # furnished it.
    @worldFill = Color.create 205, 205, 205
    # the index page's desktop colour under the wallpaper pattern (createDesktop sets it).
    @desktopFill = Color.create 244, 243, 244
    # a desktop icon's caption: its text, and the dark outline stamped around its glyphs.
    @desktopCaptionText = Color.create 255, 255, 255
    @desktopCaptionHalo = Color.create 0, 0, 0

    # the dwell-to-arm charging ring: a filled segment (the pencil-yellow accent, as the drop
    # candidate's outline) and an empty one.
    @dragArmRingFilled = Color.create 248, 188, 58
    @dragArmRingEmpty = Color.create 180, 180, 180, 0.55
    # the outline around a receptive drop candidate (and a dock band) ...
    @dropCandidateOutline = Color.create 248, 188, 58
    # ... and around a view-mode target that declines the drop.
    @dropReluctantOutline = Color.create 140, 140, 140
    # the status label that follows the pointer through an armed drag, and the "view-only" badge.
    @dragLabelText = Color.create 40, 40, 40
    @dragBadgeText = Color.create 120, 120, 120
    # the wash laid over a highlighted widget (a hierarchy menu row lights up its widget this way);
    # the caller gives its alpha.
    @hoverHighlightWash = Color.create 0, 0, 255
    # the outline drawn over the widget an editor is focused on.
    @selectionOverlayStroke = Color.create 38, 166, 154

    # the layout-editing affordances (spacers, adders and droplets): their fill at rest and
    # hovered ...
    @layoutChromeFill = Color.create 0, 0, 0
    @layoutChromeFillHover = Color.create 100, 100, 100
    # ... the glyph they draw and the shadow under it ...
    @layoutChromeGlyphInk = Color.create 255, 255, 255
    @layoutChromeGlyphShadow = Color.create 200, 200, 255
    # ... and the round hint of a stack's size adjuster.
    @layoutAdjusterHint = Color.create 128, 128, 128

    # the glass plate behind a toolbar thumbnail (GlassBoxBottomWdgt): its fill and stroke.
    @toolCellPlateFill = Color.create 230, 230, 230
    @toolCellPlateStroke = Color.create 196, 195, 196
    # a paint tool's button: its border and the faint plate under its glyph.
    @paintToolButtonStroke = Color.create 0, 0, 0
    @paintToolButtonFill = Color.create 150, 150, 150
    # the pencil on the corner "edit code" mark.
    @editMarkInk = Color.create 0, 0, 0

    # the inspector's own body while it floats free (inside a window, the window paints it).
    @inspectorFill = Color.create 248, 248, 248
    # the inspector's hierarchy: the translucent panel behind it and the arrows linking its classes.
    @inspectorHierarchyFill = Color.create 255, 255, 255, 0.2
    @inspectorHierarchyArrow = Color.create 0, 0, 0
    # the inspector's member list when it marks ownership: an inherited member's text, and an
    # own member's.
    @inspectorInheritedMemberText = Color.create 0, 0, 180
    @inspectorOwnMemberText = Color.create 0, 180, 0

    # the analog clock: the ink its ticks and hands draw with, and its outer ring.
    @clockInk = Color.create 0, 0, 0
    @clockRing = Color.create 0x32, 0x5F, 0xA2

    # the background of an editable text item: a document's title and paragraphs, the stack and
    # document samples, the templates, the welcome and how-to-save texts, and the placeholder an
    # empty window shows.
    @editableItemFill = Color.create 240, 240, 240
    # the background the example plots clear their canvas to.
    @plotBackgroundFill = Color.create 240, 240, 240

    # the ink of a toolbar's icons (creator, format and paint-tool buttons, the overflow chevron at
    # rest) and the default colour of an IconWdgt.
    @iconInk = Color.create 37, 37, 37
    # the outline colour icon paint code strokes and fills with (IconAppearance._outlineColorString).
    # Readers take its string through Color.toString, which computes it once per Color and keeps it.
    @iconOutline = Color.create 244, 243, 244

    # ---- FONT ROLES ------------------------------------------------------------------------
    # Each role is {family, size, bold}, holding what its surface renders with. A surface hands its
    # whole role to the text it builds (StringWdgt's `fontRole` option, also taken by
    # LabelButtonWdgt and StringFieldWdgt), which renders with all three members; an explicit
    # fontName / fontSize / bold beside the role overrides that one member. Weights map onto the
    # bold flag: the draft's 600 is bold, 500 is regular.
    @fonts =
      # a menu row's label (and any LabelButtonWdgt's built without a role)
      menuRow: {family: "sans-serif", size: 17, bold: false}
      # a pop-up's header title
      menuHeader: {family: "sans-serif", size: 13, bold: false}
      # a window's title, in its strip
      windowTitle: {family: "Arial, sans-serif", size: 15, bold: false}
      # the small chrome labels: a text button's face, the save / save + close labels, the
      # inspector's headers and class buttons, a patch node's field labels, the video time labels
      buttonLabel: {family: "Arial, sans-serif", size: 12, bold: false}
      # every StringWdgt / TextWdgt built without a role
      defaultText: {family: "Arial, sans-serif", size: 13, bold: false}
      # a tooltip's text (set in italic by the tooltip itself)
      tooltip: {family: "sans-serif", size: 12, bold: false}
      # a speech bubble's text (set in italic by the bubble itself)
      speechBubble: {family: "Arial, sans-serif", size: 12, bold: false}
      # the entry field of a prompt (its family is also the family of any StringFieldWdgt built
      # without a role). The prompt family is a TARGET family (G3): its text scales with the menu
      # text.
      prompt: {family: "sans-serif", size: 14, bold: false}
      # a desktop icon's caption
      desktopCaption: {family: "Arial, sans-serif", size: 12, bold: false}

    # ---- METRICS ---------------------------------------------------------------------------
    # Chrome geometry (program ruling G2): the bar button's hit box, the bar's own padding, the
    # glyph inset within a bar button's box, the minimum height a menu/list row takes, the corner
    # rounding of a menu's header and body and of the two bubbles, a menu/list rows-panel's border,
    # and a toolbar grid's cell side / inter-cell gap / outer margin / row count. Each chrome layout
    # site reads the matching name here; no chrome dimension lives as a literal in a layout method.
    #   ONE geometry serves mouse and finger alike (program ruling G1), so every value is set
    # here, once, at construction: there is no per-device redraw to switch between, and no
    # boot-time styling pass rewriting a dozen of them on one kind of page.

    # the height of a window title's text box in its strip. A pop-up's strip reads its title
    # piece's own height instead, and this number stands in for it until that piece exists (a
    # frame derives its strip in its constructor).
    @titleBarTextHeight = 19

    # the resize handle is a TARGET (G3), and ruling T3 gives it the "glyph = box" shape: what
    # you can hit is exactly the grip you see, so there is one dial and no invisible band.
    @handleSize = 44
    # the FAT (hovered) width of a scroll indicator -- see scrollIndicatorThickness below for the
    # thin resting width.
    @scrollBarsThickness = 12

    # a frame bar's button (close / collapse / edit) is a barIconSize square; its glyph paints
    # at barGlyphSize centred within that square. Two dials, never one (G3): a touch target and
    # the mark inside it scale differently, so the bar strip is sized for the finger while the
    # ink stays the size the eye wants.
    @barIconSize = 44
    @barGlyphSize = 24
    # barPadding is the frame's own chrome padding: it sets the titlebar strip's height
    # (barIconSize + 2 * barPadding) and the frame body's margin around its content.
    @barPadding = 3

    # the MINIMUM height a menu or list row takes, and the floor under a pop-up's title strip
    # (a title is a tap-to-pin target, ruling C3). A row whose label is taller keeps its label's
    # height, and the label sits centred in whichever height wins. A row is a tap target, and so
    # are the prompt's Ok / Close buttons, which ARE menu rows (G5).
    @menuRowHeight = 44

    # the header box's own corner rounding.
    @menuHeaderCornerRadius = 4
    # the body rounding of a menu with a title strip (an untitled pop-up takes the boxy default,
    # and a flat look, PreferencesAndSettings.isFlat, takes none).
    @menuCornerRadius = 5
    # the tooltip bubble's rounding (when its opener names none), and the speech bubble's.
    @tooltipCornerRadius = 6
    @speechBubbleCornerRadius = 6
    # the border width a menu/list rows panel keeps around its flush-stacked rows.
    @menuRowsBorder = 2

    # a toolbar grid's thumbnail cell: side length, the gap between cells, and the margin
    # around the whole grid; toolRows is how many rows of cells a strip lays out before the
    # remainder goes behind the overflow chevron. A thumbnail is a target (G3), and a strip is
    # ONE row, as a tablet toolbar is.
    @toolThumbnailSize = 44
    @toolInternalPadding = 6
    @toolExternalPadding = 10
    @toolRows = 1
    # (a docked strip's own cross-axis extent is no constant: it DERIVES from the three dials
    # above -- ToolPanelWdgt.naturalGridCrossExtent, the same arithmetic that hugs a floating
    # toolbar around its cells.)

    # The overlay scroll INDICATOR's thin resting width (program ruling G4); a hovered indicator
    # fattens to scrollBarsThickness instead, which is why that dial is the FAT width. An
    # indicator rests THIN and untouchable for as long as its pane overflows, and is absent when
    # it does not: visibility is a derivation from overflow, on no clock at all.
    @scrollIndicatorThickness = 4

    # a prompt's input slider's CROSS axis, i.e. the thumb you drag: a TARGET (G3), like the
    # prompt text it sits under.
    @prompterSliderSize = 44

    # ---- SHADOWS ---------------------------------------------------------------------------
    # Each shadow is an offset (an integer-px Point, any direction: ShadowInfo) and an alpha.

    # the colour every shadow is cast in: the shadow pass fills a caster's silhouette with it.
    @shadowColor = Color.BLACK

    # the desktop shadow: every world child wears it (Widget.addShadow's default), and so does an
    # image taken with a forced shadow (Widget.fullImage).
    @desktopShadowOffset = new Point 4, 4
    @desktopShadowAlpha = 0.2
    # a transient pop-up's (a menu's, a prompt's) shadow.
    @popUpShadowOffset = new Point 5, 5
    @popUpShadowAlpha = 0.2
    # the lift a widget takes while the pointer carries it.
    @dragLiftShadowOffset = new Point 6, 6
    @dragLiftShadowAlpha = 0.1

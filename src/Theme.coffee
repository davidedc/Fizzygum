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
    # two roles (the speech bubble shares the list row's fill and the list rows panel's stroke by
    # value, never by name).

    # the pop-up (menu and prompt) header band: its fill, its title text, and the 1 px rule the
    # band paints as its own bottom edge (redesign plan §2, rule D: the band's own edge).
    @menuHeaderFill = @paper
    @menuHeaderText = @muted2
    @menuHeaderRule = @chrome
    # a pop-up's body -- a TRANSIENT frame, a menu or a prompt (pinned, it wears a window's body):
    # its 1 px border stroke and its fill (FrameWdgt._frameLook).
    @menuStroke = @frame
    @menuBodyFill = @paper
    # a plain LIST's rows panel (the CommandPanelWdgt a ListWdgt stacks its rows in): its fill and its
    # stroke. A pop-up's rows panel paints nothing: the pop-up's body is its box.
    @rowsPanelFill = Color.create 238, 238, 238
    @rowsPanelStroke = Color.create 186, 186, 186
    # a MEMBER list's rows panel: no fill and no stroke at all, so whatever the list stands on shows
    # around and between its rows.
    @memberRowsPanelFill = Color.TRANSPARENT
    # a MENU row (a MenuItemWdgt in a menu, and one lifted out of a pinned menu or duplicated
    # onto the desktop): its fill at rest -- the pop-up
    # body's own paper, so a row in a pop-up shows no box of its own and a standalone row keeps a
    # paper box -- and the ink of its label ...
    @menuRowFill = @paper
    @menuRowText = @ink
    # ... the PLATE it wears over its whole box while hovered, and while pressed (rounded at
    # menuRowPlateRadius; outside the plate's corners its rest fill shows) ...
    @menuRowHoverFill = @desk
    @menuRowPressFill = @chrome
    # ... the grip bar it paints along its left edge while a PINNED menu hands it out ...
    @menuRowGrip = @grip
    # ... and the ink of its two INDICATORS (MenuRowIndicatorWdgt), the same at rest, hovered and
    # pressed: the chevron at its right edge saying the row opens a submenu, and the tick in its
    # leading column saying the row's choice is the current one.
    @menuRowSubmenuChevron = @muted3
    @menuRowTick = @ink
    # the rule a pop-up's group divider paints across its band (DividerWdgt; redesign plan §2,
    # rule D: a band painting its own rule).
    @menuDivider = @chrome
    # a plain LIST row (a MenuItemWdgt in a ListWdgt's rows panel), in the flat look: its fill at
    # rest, while highlighted and while pressed (a selected row stays pressed), each over its whole
    # box, and the ink of its label ...
    @listRowFill = Color.create 250, 250, 250
    @listRowHighlightFill = Color.SILVER
    @listRowPressFill = Color.GRAY
    @listRowText = Color.create 50, 50, 50
    # ... and the hairline it paints along its TOP edge when the row above it is another row
    # (ruling G5): paint, never layout, so rows stay flush and no dead zone opens between two
    # targets. Fainter than rowsPanelStroke, because the panel's own border is a boundary and this
    # is only a rhythm mark inside it.
    @listRowSeparator = Color.create 225, 225, 225
    # a MEMBER row (MemberRowWdgt: a row of a member list, the Object Inspector's -- a kind tag, then
    # the member's name): its fill at rest, none, so whatever its list stands on shows; and the PLATE
    # it wears while it is its list's selection, and while pressed, the accent's translucent tint ...
    @memberRowFill = Color.TRANSPARENT
    @memberRowSelectedFill = @accentTint
    # ... the ink of its member's name, and of a DIMMED one's (a member its subject's own class does
    # not declare) ...
    @memberRowNameText = @ink
    @memberRowDimmedNameText = @muted
    # ... and the ink of its kind tag ("fn", "var"), at rest and while the row is selected.
    @memberRowTagText = @muted2
    @memberRowSelectedTagText = @accent
    # a LabelButtonWdgt built with no look of its own (a fizzytiles magnet): its fill at rest,
    # hovered and pressed, each over its whole box, and the ink of its label.
    @labelButtonFill = Color.create 250, 250, 250
    @labelButtonHighlightFill = Color.SILVER
    @labelButtonPressFill = Color.GRAY
    @labelButtonText = Color.create 50, 50, 50

    # a tooltip's PLATE: its fill (a plate carries no border, so it has no stroke) and the ink of
    # its text.
    @tooltipFill = @plate
    @tooltipText = @ink
    # the speech bubble's (the placeable callout's) fill and stroke.
    @speechBubbleFill = Color.create 250, 250, 250
    @speechBubbleStroke = Color.create 186, 186, 186

    # the fill of a window's title strip on the desktop (an external frame) and of a card's (nested
    # in a real container, a docked band included). A strip carries no stroke: the line it draws is
    # its rule, barRule.
    @windowBarFill = @chrome
    @cardBarFill = @chrome
    # the 1 px rule a window's or a card's strip draws along the edge that faces its frame's content
    # (redesign plan §2, rule D: the band's own edge -- unlike seamRule, the gap between two panes).
    @barRule = @line
    # the title text in a window's or a card's strip.
    @windowTitleText = @muted
    # the ink of the glyphs a strip's pieces draw (close, collapse / uncollapse, the pencil / eye)
    # at rest: in a window's strip, and in a card's (a docked band's included) ...
    @windowBarGlyph = @muted
    @cardBarGlyph = @text2
    # ... and the ink a strip glyph takes while it is hovered or pressed, in either strip (the
    # glyph recolours in place: no plate is drawn behind it).
    @barGlyphActive = @ink
    # a window's body (a persistent frame on the desktop, a pinned pop-up included): its 1 px
    # frame stroke and its fill (FrameWdgt._frameLook).
    @windowFrameStroke = @frame
    @windowBodyFill = @paper
    # a card's body (a persistent frame nested in a real container, a docked band included): its
    # 1 px border stroke and its fill (FrameWdgt._frameLook).
    @cardFrameStroke = @line
    @cardBodyFill = @paper

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
    # the editable code pane: a script's or a code prompt's editor body.
    @codePaneFill = Color.create 255, 255, 255
    # the ink of SOURCE CODE in a code pane -- the Object Inspector's, a script's, a code prompt's, a
    # console's and an error log's -- which also takes fonts.code and codePanePadding.
    @codeText = @code
    # the background of a one-line text-entry field (StringFieldWdgt).
    @textFieldFill = Color.create 255, 255, 255
    # the text caret's fill.
    @caretFill = Color.create 0, 0, 0
    # a TextWdgt's text selection: the selected glyphs' ink and the highlight behind them.
    @textSelectionText = Color.create 255, 255, 255
    @textSelectionFill = Color.create 60, 60, 120

    # a number prompt's slider: its track, and the base its thumb derives its hover and press
    # colours from.
    @promptSliderTrack = Color.create 225, 225, 225
    @promptSliderThumb = Color.create 60, 60, 60
    # a slider's track when its builder names no colour ...
    @sliderTrack = Color.create 0, 0, 0
    # ... and its thumb at rest, under a pointer and pressed, when its builder gives the thumb no
    # scheme of its own (SliderButtonWdgt.setColorScheme).
    @sliderThumb = Color.BLACK
    @sliderThumbHighlight = Color.create 110, 110, 110
    @sliderThumbPress = Color.create 100, 100, 100
    # a viewport's SCROLL INDICATOR -- the two bars a viewport builds and presents
    # (SliderWdgt.showAsScrollIndicator). Its track: the colour the viewport builds its bars in,
    # and the alpha a FAT indicator shows that track at (a thin one shows none) ...
    @scrollIndicatorTrack = @ink
    @scrollIndicatorTrackAlpha = 0.06
    # ... and its thumb: the scrollbar token at rest, thin or fat, and a darker ink while a fat one
    # is hovered and while it is pressed. Each carries its own alpha, which the thumb shows as it
    # is, never dimmed by a second one.
    @scrollIndicatorThumb = @scrollbar
    @scrollIndicatorThumbHighlight = Color.create 0x1E, 0x1E, 0x1C, 0.5
    @scrollIndicatorThumbPress = Color.create 0x1E, 0x1E, 0x1C, 0.6

    # a BUTTON (SimpleButtonWdgt; visual-design-system §4.3): its fill and 1 px border at rest ...
    @buttonFill = @paper
    @buttonStroke = @line
    # ... its fill while hovered (its border stays buttonStroke) ...
    @buttonHoverFill = @desk
    # ... its fill and its darker border while pressed ...
    @buttonPressFill = @chrome
    @buttonPressStroke = @frame
    # ... the ink of a text face, enabled ...
    @buttonText = @ink
    # ... and, DISABLED, in every state: no fill at all (whatever lies behind the button shows),
    # its border, and the ink of a text face.
    @buttonDisabledFill = Color.TRANSPARENT
    @buttonDisabledStroke = @chrome
    @buttonDisabledText = @disabledText
    # a TOGGLE (LabelledToggleWdgt; visual-design-system §4.3, §4.8), OFF: no fill at all (whatever
    # lies behind the toggle shows), its 1 px border and the ink of its label ...
    @toggleOffFill = Color.TRANSPARENT
    @toggleOffStroke = @line
    @toggleOffText = @text2
    # ... OFF and hovered, its fill (its border stays toggleOffStroke), and OFF and pressed, its fill
    # and its darker border ...
    @toggleOffHoverFill = @desk
    @toggleOffPressFill = @chrome
    @toggleOffPressStroke = @frame
    # ... and ON, in every state: the accent's translucent tint, which composites over whatever the
    # toggle stands on, inside an accent border, and the accent as its label's ink.
    @toggleOnFill = @accentTint
    @toggleOnStroke = @accent
    @toggleOnText = @accent
    # a CHIP (ChipWdgt; visual-design-system §4.3, §4.8), one of a row of alternatives -- a class of
    # the Object Inspector's breadcrumb. Any chip but the CURRENT one: no fill at all (whatever lies
    # behind the chip shows), its 1 px border and the ink of its label ...
    @chipFill = Color.TRANSPARENT
    @chipStroke = @chip
    @chipText = @text2
    # ... hovered, its fill (its border stays chipStroke), and pressed, its fill and its darker
    # border ...
    @chipHoverFill = @desk
    @chipPressFill = @chrome
    @chipPressStroke = @frame
    # ... and the CURRENT chip, in every state: the accent's translucent tint, which composites over
    # whatever the chip stands on, inside an accent border, and the accent as its label's ink.
    @chipCurrentFill = @accentTint
    @chipCurrentStroke = @accent
    @chipCurrentText = @accent
    # a RECTANGULAR button's border (SimpleRectangularButtonWdgt: the demo switch's buttons, and the
    # base of the paint tools, which paint their own).
    @rectangularButtonStroke = Color.create 196, 195, 196

    # a plain resize/move handle's art (a halo's handles, a naked inspector's resizer) at rest: its
    # ink and the shadow drawn under it ...
    @handleArtInk = Color.create 255, 255, 255
    @handleArtShadow = Color.create 150, 150, 150
    # ... and while the handle is highlighted.
    @handleArtHighlightedInk = Color.create 255, 255, 255
    @handleArtHighlightedShadow = Color.create 200, 200, 255
    # the ink of a frame's resize GRIP (FrameGripWdgt): its three strokes, at rest and under the
    # pointer alike -- the grip has no hover look.
    @frameGripInk = @grip

    # a world's own fill, under everything: the desk a world shows when createDesktop has not
    # furnished it (the test world).
    @worldFill = @desk
    # the index page's desktop colour, under its wallpaper (createDesktop sets it): the desk too.
    @desktopFill = @desk
    # a desktop icon's caption: its text, and the dark outline stamped around its glyphs.
    @desktopCaptionText = Color.create 255, 255, 255
    @desktopCaptionHalo = Color.create 0, 0, 0

    # the dwell-to-arm charging ring: a filled segment (the yellow accent, as the drop
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

    # the Object Inspector's BODY, which it paints itself, naked and windowed alike: under its bands
    # and panes, the draft's panel ...
    @inspectorBodyFill = @panel
    # ... and its two panes' fill (the member list and the code pane, viewports and planes alike, and
    # the background of the code pane's text): none, so the body and the inspector's seams show
    # through them.
    @inspectorPaneFill = Color.TRANSPARENT
    # the inspector's BREADCRUMB band (its class chips wear the chip roles, above): the ink of its
    # "Class" caption, of the drawn › separating two chips, and of its mixin-donor label ("from
    # <Name>Mixin", while a mixin-donated member is selected).
    @inspectorBreadcrumbCaption = @muted2
    @inspectorBreadcrumbSeparator = @muted3
    @inspectorDonorText = @muted2

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
    # LabelButtonWdgt, StringFieldWdgt and TextAreaWdgt), which renders with all three members; an explicit
    # fontName / fontSize / bold beside the role overrides that one member. Weights map onto the
    # bold flag: the draft's 600 is bold, 500 is regular.
    @fonts =
      # a menu row's label (a MenuItemWdgt in a menu or a prompt, or one standing on its own)
      menuRow: {family: "Arial, sans-serif", size: 15, bold: false}
      # a plain list row's label (a MenuItemWdgt in a ListWdgt)
      listRow: {family: "sans-serif", size: 17, bold: false}
      # a member row's name (MemberRowWdgt: a member list, the Object Inspector's), in mono ...
      memberName: {family: StringWdgt::monoFontStack, size: 13, bold: false}
      # ... and its kind tag ("fn", "var"), the draft's weight 600
      memberKindTag: {family: "Arial, sans-serif", size: 10, bold: true}
      # the label of a LabelButtonWdgt built without a role (a fizzytiles magnet)
      labelButton: {family: "sans-serif", size: 17, bold: false}
      # a pop-up's header title
      menuHeader: {family: "Arial, sans-serif", size: 11, bold: false}
      # a window's title, in its strip
      windowTitle: {family: "Arial, sans-serif", size: 13, bold: false}
      # the small chrome labels: a text button's face (a toggle's and a chip's included), the save /
      # save + close labels, the Object Inspector's breadcrumb caption and mixin-donor label, a patch
      # node's field labels, the video time labels
      buttonLabel: {family: "Arial, sans-serif", size: 12, bold: false}
      # every StringWdgt / TextWdgt built without a role
      defaultText: {family: "Arial, sans-serif", size: 13, bold: false}
      # a tooltip's text
      tooltip: {family: "Arial, sans-serif", size: 12, bold: false}
      # a speech bubble's text (set in italic by the bubble itself)
      speechBubble: {family: "Arial, sans-serif", size: 12, bold: false}
      # the entry field of a prompt (its family is also the family of any StringFieldWdgt built
      # without a role). The prompt family is a TARGET family (G3): its text scales with the menu
      # text.
      prompt: {family: "sans-serif", size: 14, bold: false}
      # a desktop icon's caption
      desktopCaption: {family: "Arial, sans-serif", size: 12, bold: false}
      # the text of a CODE PANE, in mono -- source code: the Object Inspector's code pane, a script's
      # and a code prompt's editor -- and of the mono text panels: a console's, an error log's and a
      # patch node's text boxes. Its lines stack at the pitch every text keeps, ceil(1.2 x size).
      code: {family: StringWdgt::monoFontStack, size: 12, bold: false}

    # ---- METRICS ---------------------------------------------------------------------------
    # Chrome geometry (program ruling G2): a handle's side, a frame grip's side and inset, the bar
    # button's hit box, a frame's border, its strip's
    # rule and its body margin, the glyphs inset within a bar button's box, a menu row's glyph
    # box, the minimum height a menu/list row takes, a menu row's and a list row's side inset and
    # icon gap, a menu row's plate rounding and its chevron's and tick's glyph squares and gaps, a
    # member row's height, selection plate and horizontal rhythm, a pop-up group divider's band, the
    # corner
    # rounding of a window's, a card's and a pop-up's body and of the speech bubble, a tooltip
    # plate's rounding, padding and line height, a pop-up's
    # content padding and its header's rule and title inset, a plain or member list rows-panel's
    # padding, a scroll
    # indicator's fat and thin widths and the thin one's edge inset, a toolbar grid's cell
    # side / inter-cell gap / outer margin / row count, a button's height, paddings and rounding,
    # a toggle's height, padding and rounding, a chip's height, padding and rounding,
    # the least side of a chrome target, a footer band's height, rule, inset, button gap and
    # grip clearance, and the Object Inspector's bands: its breadcrumb band's height, inset, gaps
    # and separator square, its toggles band's height, inset and gap, its list column's width and
    # its seams' width, and a code pane's padding. Each chrome
    # layout site reads the matching
    # name here; no chrome dimension lives as a literal in a layout method.
    #   ONE geometry serves mouse and finger alike (program ruling G1), so every value is set
    # here, once, at construction: there is no per-device redraw to switch between, and no
    # boot-time styling pass rewriting a dozen of them on one kind of page.

    # the height a frame's title text STANDS IN at until its title piece exists (a frame derives
    # its strip in its constructor, before the piece is built): the line height of the window
    # title's 13 px. A pop-up header stands in at it too: its band is floored at menuRowHeight, far
    # above either title's line. Once the piece exists, every strip reads the piece's own height
    # instead -- a window's centres its title by it.
    @titleBarTextHeight = 16

    # the side of a plain HANDLE (HandleWdgt: a halo's resize / move / rotate handles, a naked
    # inspector's resizer, a demo handle). A handle is a TARGET (G3), and ruling T3 gives its corner
    # resizer the "glyph = box" shape: what you can hit is exactly the striped triangle it draws, so
    # there is one dial and no invisible band. The same side is the side of a text's corner
    # triangle badges and the pen demo's arrow unit. A frame's own resizer is its grip, sized by
    # frameGripSize below, never by this; and a footer band keeps footerGripClearance free at its
    # right end, never this.
    @handleSize = 44
    # a frame's resize GRIP (FrameGripWdgt, the draft's three-stroke grip): the side of its square,
    # which is also its whole hit area, and how far in from the corner of the frame's CONTENT area
    # (inside its border) the square sits. Inset plus side is how far into that corner the grip
    # reaches, which a payload kept clear of it and a viewport's bars running out to it both leave
    # free (FrameGripWdgt.footprint).
    @frameGripSize = 36
    @frameGripInset = 3
    # the FAT (hovered) width of a scroll indicator -- see scrollIndicatorThickness below for the
    # thin resting width.
    @scrollBarsThickness = 12

    # a frame bar's button (close / collapse / edit) is a barIconSize square; its glyph paints
    # centred within that square at the side its kind names: barControlGlyphSize for the window
    # controls (the close cross, the collapse minus, the uncollapse plus), barActionGlyphSize for
    # the strip's trailing action (the pencil / eye). Two dials, never one (G3): a touch target and
    # the mark inside it scale differently, so the bar strip is sized for the finger while the
    # ink stays the size the eye wants.
    @barIconSize = 44
    @barControlGlyphSize = 14
    @barActionGlyphSize = 20
    # the glyph box a menu row shows its icon in (MenuItemWdgt), and so the box a picture taken
    # for a row is fitted into (InertIconHolderWdgt, the overflow chevron's tool miniatures).
    @menuRowGlyphSize = 24
    # the width of a frame's BORDER: the ring its 1 px outline occupies along its edges (the crisp
    # hairline BoxyAppearance strokes over the frame's content). The frame's strip, its payload and
    # its docked bands all lie INSIDE it, so it is also how far a strip's pieces and background sit
    # in from the frame's outer edge, and how far in a payload starts where no strip runs
    # (FrameWdgt._barSpec, FrameWdgt._chromePadding).
    @frameBorderWidth = 1
    # the width of the RULE a frame's strip draws along its content-facing edge, inside its own
    # thickness: a strip is the border it spans, its barIconSize targets, then this rule.
    @barRuleWidth = 1
    # the margin a frame's payload keeps INSIDE its body's edges -- the border's inner edge, the
    # strip's rule, a docked band -- which is also the gap between a docked band and the payload. At
    # zero the payload lies flush against every one of them.
    @frameBodyMargin = 0

    # the MINIMUM height a menu or plain list row takes, and the floor under a pop-up's title strip
    # (a title is a tap-to-pin target, ruling C3). A row whose label is taller keeps its label's
    # height, and the label sits centred in whichever height wins. A row is a tap target (G5). A
    # member row's height is its own, memberRowHeight.
    @menuRowHeight = 44
    # a MENU row's horizontal rhythm: the inset it keeps at each side (whatever it shows first --
    # its tick column, its icon's glyph box, or its label -- starts this far in, and whatever it
    # shows last -- its label, or its submenu chevron's ink -- ends this far short of its right
    # edge), and, in a row carrying an icon, the gap between the glyph box and the label ...
    @menuRowSideInset = 10
    @menuRowIconGap = 4
    # ... the rounding of the plate it wears while hovered or pressed (the draft's control
    # radius) ...
    @menuRowPlateRadius = 6
    # ... and its two INDICATORS (MenuItemWdgt). The submenu CHEVRON: the side of its glyph square
    # (the draft's 16 px ›), and the least gap between the end of the label and the start of the
    # chevron's ink. The INK, not the square, is what ends menuRowSideInset short of the row's right
    # edge, so the square overhangs into that inset. The TICK: the side of its glyph square, which
    # starts at the side inset in a leading column that every row of a ticking menu reserves, and
    # the gap between that square and the label. The tick's ink ends a pixel inside its square
    # (TickIconAppearance at 14 px: ink columns 1..12), so the gap the eye reads is one more than
    # this -- between the icon gap and the chevron gap.
    @menuRowChevronSize = 16
    @menuRowChevronGap = 8
    @menuRowTickSize = 14
    @menuRowTickGap = 6
    # a plain LIST row's two.
    @listRowSideInset = 4
    @listRowIconGap = 4
    # a MEMBER row (MemberRowWdgt): its height -- its list's row pitch too, since member rows stack
    # flush, no layout gap opening a dead zone between two targets (ruling G5) -- and the selection
    # PLATE drawn from its top: its height and its rounding (the draft's 40 px list row at radius 6;
    # the 2 px under it are the draft's gap between two rows) ...
    @memberRowHeight = 42
    @memberRowPlateHeight = 40
    @memberRowPlateRadius = 6
    # ... its horizontal rhythm: the inset at each of its sides (its kind tag starts this far in, its
    # name ends this far short of its right edge), the column its kind tag stands in, and the gap
    # between that column and its name ...
    @memberRowSideInset = 8
    @memberRowTagColumnWidth = 18
    @memberRowTagGap = 8
    # a pop-up's group DIVIDER (DividerWdgt): its band is this gap, its rule, then this gap again
    # -- the draft's group padding above and below a 1 px rule.
    @menuDividerGap = 4
    @menuDividerRuleWidth = 1

    # the body rounding of a pop-up, a menu or a prompt, titled or not (a flat look,
    # PreferencesAndSettings.isFlat, takes none): the radius of the outline it strokes over its
    # content and clips its children to.
    @menuCornerRadius = 10
    # the body rounding of a window, and of a card (a nested frame or a docked band): the radius
    # of the outline the frame strokes over its content and clips its children to.
    @windowCornerRadius = 8
    @cardCornerRadius = 6
    # a tooltip's PLATE (the draft's label plate): its rounding, and its padding at each side of
    # its contents and above and below them, each when its opener names none; and the height of
    # the slot each line of its text stands in (the draft's line-height) ...
    @tooltipCornerRadius = 8
    @tooltipHorizontalPadding = 7
    @tooltipVerticalPadding = 1
    @tooltipLineHeight = 16
    # ... and the speech bubble's rounding.
    @speechBubbleCornerRadius = 6
    # a pop-up's CONTENT BOX (a menu's or a prompt's): how far in from its border, and below its
    # header's rule, its rows panel lays its rows and editors out, on every side. The header band
    # spans that same content width, so it stops this far in from the border at both ends. The
    # sides and the top and bottom are ONE number because a rows panel's padding is one uniform
    # knob (VerticalStackPanelWdgt.padding).
    @menuContentPadding = 4
    # a pop-up header's own rule, the band's bottom edge: its thickness ...
    @menuHeaderRuleWidth = 1
    # ... and how far into the band the header's title text starts.
    @menuHeaderTitleInset = 10
    # the padding a plain LIST's rows panel keeps around its flush-stacked rows (a pop-up's rows
    # panel keeps menuContentPadding instead) ...
    @rowsPanelPadding = 2
    # ... and a MEMBER list's (the draft's 4 px list padding).
    @memberRowsPanelPadding = 4

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
    # how far in from its viewport's edge a THIN indicator lies: clear of the viewport's own
    # border, and of the border of a pop-up or a window around it. A fat indicator lies flush,
    # since its bar is the band the hover pass watches and every press aims into
    # (ViewportWdgt._indicatorEdgeInset).
    @scrollIndicatorEdgeInset = 2

    # a prompt's input slider's CROSS axis, i.e. the thumb you drag: a TARGET (G3), like the
    # prompt text it sits under.
    @prompterSliderSize = 44

    # a BUTTON (SimpleButtonWdgt) whose face is a line of text: the height it takes, its horizontal
    # padding at each side of the label (a primary action's is wider), and the rounding of its box.
    # Its width is the label, that padding at each side and its 1 px border at each side
    # (SimpleButtonWdgt.preferredExtent).
    @buttonHeight = 36
    @buttonPaddingX = 14
    @primaryButtonPaddingX = 18
    @buttonCornerRadius = 6
    # a TOGGLE (LabelledToggleWdgt): the height it takes, its horizontal padding at each side of its
    # label, and the rounding of its box. Its width is the label, that padding at each side and its
    # 1 px border at each side (LabelledToggleWdgt.preferredExtent).
    @toggleHeight = 36
    @togglePaddingX = 12
    @toggleCornerRadius = 6
    # a CHIP (ChipWdgt): the height it takes, its horizontal padding at each side of its label, and
    # the rounding of its box -- half its height, a full pill. Its width is the label, that padding at
    # each side and its 1 px border at each side (ChipWdgt.preferredExtent).
    @chipHeight = 32
    @chipPaddingX = 10
    @chipCornerRadius = 16
    # the least side of a chrome TARGET (the 44 rule, visual-design-system §4.2): a button, a toggle
    # or a chip is never narrower than this, and a row holding smaller controls is never shorter (a
    # prompt's row of buttons, PromptButtonsRowWdgt).
    @minimumTargetSize = 44

    # a FOOTER BAND, the row of buttons a window's content ends in (FooterBandLayout: a code
    # prompt's, a script's, a console's, an error log's, a bin's, an Object Inspector's): its
    # height, its top rule included, and that rule's thickness (a seam its host owns,
    # visual-design-system §4.1) ...
    @footerBandHeight = 52
    @footerRuleWidth = 1
    # ... how far in from the band's left edge its left group starts and from its right edge its
    # right group ends, and the gap between two buttons of a group (and between two buttons of a
    # prompt's row, PromptButtonsRowWdgt) ...
    @footerInset = 12
    @footerGap = 8
    # ... and how much more its right group keeps clear at the band's right end, for the frame's
    # resize grip in that corner.
    @footerGripClearance = 44

    # the OBJECT INSPECTOR's bands (InspectorWdgt._bandsIn; its footer band is a footer band, above):
    # the breadcrumb and the toggles band each end in a rule along their bottom, included in their
    # height, a seam the inspector owns (visual-design-system §4.1). The width of those two rules
    # and of the line between its list and its code pane ...
    @inspectorRuleWidth = 1
    # ... the BREADCRUMB band (InspectorWdgt._breadcrumbIn): its height while its chips take one row,
    # its rule included, the row's chips centred down the rest -- each further row of chips adds a
    # chip's height and breadcrumbGap to it; how far in from the band's left edge its "Class"
    # caption starts, which is also how far short of its right edge its chips and its donor label
    # end; the gap after the caption; the gap between a chip and the INK of the separator on either
    # side of it (the draft's "all 4 apart", the ink standing where the draft's › glyph advances),
    # which is also the gap between two rows of chips; the gap before the donor label; and the side
    # of a separator's glyph square, whose chevron is the size of the draft's 12 px › (its ink 4 px
    # wide, the glyph's advance) ...
    @breadcrumbBandHeight = 44
    @breadcrumbInset = 12
    @breadcrumbCaptionGap = 8
    @breadcrumbGap = 4
    @breadcrumbDonorGap = 8
    @breadcrumbSeparatorSize = 8
    # ... the TOGGLES band's height, how far in from its left edge its first toggle starts, and the
    # gap between two toggles ...
    @toggleBandHeight = 48
    @toggleBandInset = 12
    @toggleBandGap = 8
    # ... and the width of the body's member-list column (the draft's: a 230 row and 4 at each side),
    # which never takes more than half the inspector's width; the code pane takes the rest.
    @inspectorListColumnWidth = 238

    # a CODE PANE (a TextAreaWdgt in the code role, with fonts.code and codeText: the Object
    # Inspector's, a script's, a code prompt's, a console's, an error log's): how far in from the
    # pane's edges its text stands, on every side -- so the inspector's code starts this far right of
    # its list | code seam and this far below its body's top. A patch node's text boxes keep their
    # own.
    @codePanePadding = 12

    # ---- SHADOWS ---------------------------------------------------------------------------
    # Each shadow is an offset (an integer-px Point, any direction: ShadowInfo) and an alpha.

    # the colour every shadow is cast in: the shadow pass fills a caster's silhouette with it.
    @shadowColor = Color.BLACK

    # the desktop shadow: the ONE shadow every object standing on the desktop casts at rest --
    # a window, a menu, a prompt, a tooltip, an icon, the clock. Every world child wears it
    # (Widget.addShadow's default, and FrameWdgt._frameLook's for a frame of either lifetime), and
    # so does an image taken with a forced shadow (Widget.fullImage).
    @desktopShadowOffset = new Point 2, 2
    @desktopShadowAlpha = 0.12
    # the lift a widget takes while the pointer carries it: its own token, larger and fainter
    # than the desktop shadow, so a carried widget reads as picked up off the desk.
    @dragLiftShadowOffset = new Point 6, 6
    @dragLiftShadowAlpha = 0.1

# This is what typically people refer to as "icons", however that's not
# quite precise. An icon is just a graphic symbol, it doesn't have a caption per se.
# This widget has a caption instead. Also, since it can hold any widget, the
# final name is WidgetHolderWithCaptionWdgt.
#
# MY LOOK (docs/archive/redesign/UI-guidelines.md §5.1-5.3), every size a Theme desktop icon metric
# (each derived from its one knob, desktopIconTile, or fixed at the draft's value):
#   the TILE     a desktopIconTile square desktopIconPadding below my top, centred across my width,
#                painted by my appearance (DesktopIconAppearance) in my state's look: paper inside a
#                1 px line border at rest (_fillForMyState / _strokeForMyState; a desktop link,
#                DesktopLinkWdgt, also looks hovered and pressed)
#   the GLYPH    my icon child: the desktopIconGlyphSize square centred in the tile, inked
#                desktopIconGlyph when I am built
#   the PLATE    painted by my appearance desktopIconTilePlateGap below the tile, under my caption:
#                my caption's box outset by the plate's padding
#   the CAPTION  my label child, a TextWdgt in desktopCaptionText on the plate: one line hugs its
#                text, a longer caption wraps across my width less the plate's padding (so its plate
#                spans my width), desktopIconCaptionMaxLines lines at most, the rest ending in "…";
#                each line stands on the caption's own line box (its desktopCaption font role's)
# I lay all of it out again at EVERY arrange (_layOutOwnContents), from the theme of the page I am
# in, so the bounds a saved or copied icon carries for its children never pin a look. I am made at
# the standard extent; in a box of any other size nothing shrinks: every piece keeps its size and
# its place against my top and my horizontal centre. My appearance paints the tile and the plate
# only inside my box, and my shape stops at it; my glyph and caption children stand where the look
# puts them, inside my box or not.
#
# My SHAPE is the tile and the plate (my appearance's): a press or a drop elsewhere in my box reaches
# whatever lies behind me. A press on the tile -- the tile around my glyph, and on a desktop link the
# glyph itself -- does what my class's tile does (_activateMyTile: opens, launches, runs); a press on
# the plate is a press on my caption, which renames me. activated is where the two part.

class WidgetHolderWithCaptionWdgt extends Widget

  label: undefined
  # the caption text, taken by the constructor (@label above is the widget that draws it)
  labelContent: undefined
  # the held widget, taken by the constructor. Declared here rather than on the
  # desktop-link family below me, since DesktopLinkWdgt extends this class
  # and so inherits it along with its four descendants.
  icon: undefined

  # The ONE home for the standard desktop-icon extent — every launcher/shortcut
  # creation site sizes through this: the theme's desktop icon cell by the height
  # a two-line plate needs (Theme's desktopIcon metrics, every one derived from
  # its one knob, desktopIconTile), so every icon takes one row pitch whatever its
  # caption. My own layout places the tile, the glyph and the caption's plate in
  # it (_layOutOwnContents).
  @standardDesktopIconExtent: -> WorldWdgt.theme.desktopIconExtent

  constructor: (@labelContent, @icon) ->
    super()
    @appearance = @createAppearance()
    @_buildAndConnectChildren()

  # my tile and my plate (a method, not a class field, so the build's dependency-finder still sees
  # the `new DesktopIconAppearance` edge and orders the appearance before me)
  createAppearance: -> new DesktopIconAppearance @

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    theme = WorldWdgt.theme
    if @icon?
      # my glyph's one ink, which no hover or press of mine recolours (an empty holder's drop
      # placeholder below keeps its own look: it is a drop target, not a glyph)
      @icon.setColor theme.desktopIconGlyph
    else
      @icon = new SimpleDropletWdgt "icon"
    @_applyExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()
    @_addNoSettle @icon
    # the caption: a TextWdgt in the desktopCaption font role (its font and its line box), which it
    # keeps -- FLOAT never scales a short caption up to fill its box, and the CROP default
    # ellipsises what the most lines I give it cannot hold (editing an ellipsised caption hands off
    # to the pop-out editor, handOffToPopoutEditorIfOverflowing). Its box and its wrapping are my
    # layout's.
    @label = new TextWdgt @labelContent, fontRole: theme.fonts.desktopCaption
    @label.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.FLOAT
    @label.color = theme.desktopCaptionText
    @_addNoSettle @label, beingDropped: true
    @label.alignCenter()
    @label.isEditable = true
    # update layout
    @_invalidateLayout()

  # I am a desktop icon (an icon with a caption). isDesktopIcon replaces the
  # `instanceof WidgetHolderWithCaptionWdgt` tests that find/skip icons among desktop
  # children; participatesInIconGrid additionally drives the auto grid-positioning of
  # newly-created icons -- BinOpenerWdgt overrides it to false (it is an icon but the
  # desktop places it itself, not the grid). (type-test-elimination campaign)
  isDesktopIcon: ->
    true

  participatesInIconGrid: ->
    true


  # The generic "Color…" row (and the color pin) recolours my GLYPH: its ink is the one my icon
  # was built with, and no hover or press of mine touches it, so a colour picked here stays. My tile
  # and my plate wear the theme's.
  setColor: (aColor) ->
    @icon.setColor aColor

  # My TILE's look, which my appearance asks as it paints: a bare holder has no pointer states and
  # always shows the tile at rest (DesktopLinkWdgt answers from its hover and press state).
  _fillForMyState: ->
    WorldWdgt.theme.desktopIconTileFill

  _strokeForMyState: ->
    WorldWdgt.theme.desktopIconTileStroke

  # Did a press at `pos` (my plane) land on my PLATE -- its padding, or my caption on it -- while my
  # caption can be edited? Such a press is a press on my caption, a rename, never one on my tile.
  # With no position (a rig calling activated()) it is a press on the tile, and so it is while my
  # caption cannot be edited: then my caption's own activated hands the press straight back to me.
  _pressIsOnMyPlate: (pos) ->
    pos? and !!@label?.isEditable and !!@appearance?.plateContainsPoint?(pos)

  # THE ONE DECISION POINT of a click that reaches me -- on my own pixels (the tile, a desktop
  # link's glyph inside it, the plate's padding), escalated from a child, or an activated() a rig
  # sends -- and the one public entry for it. On my plate it is a press on my caption, which renames
  # me (a press on the caption's text area reaches the caption itself; one on the padding around it
  # is handed over here). Anywhere else it is a press on my tile, and what my tile does is
  # _activateMyTile's answer: my family's classes answer that, never this.
  activated: (pos, args...) ->
    if @_pressIsOnMyPlate pos
      @label.activated pos, args...
    else
      @_activateMyTile pos, args...

  # What a press on my TILE does. A bare holder's escalates, as any widget's press does; each class
  # of the desktop-link family answers its own (opens, launches, runs).
  _activateMyTile: (pos, args...) ->
    @escalateEvent "activated", pos, args...

  # MY SHADOW IS MY OWN SILHOUETTE ONLY: my tile and my plate, which my appearance fills on this
  # pass, never my children's. My glyph lies inside my tile and my caption on my plate, so their
  # silhouettes add nothing to the shape -- they only darken it twice where they fall, and under the
  # drag lift's offset a caption's descenders reach below the plate as darker marks. The pass keeps
  # the offset and alpha it is given (my desktop shadow at rest, the lift while I am carried, an
  # ancestor's when one casts me). As for an opaque clipping panel
  # (ClippingAtRectangularBoundsMixin), this holds while I am opaque: a translucent me lets my
  # children's coverage through.
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    if appliedShadow? and @alpha == 1
      @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    else
      super

  # A PARENT THAT SIZES ME BY WIDTH -- a vertical stack (a document's included,
  # VerticalStackPanelWdgt and VerticalStackLayoutSpec) and a window holding me as its content
  # (FrameWdgt) -- gets the standard height whatever the width: my look does not scale with my
  # width (the tile, the glyph and the plate are the knob's sizes, centred across it), so neither
  # does my height. My natural width is the standard one, and it is the extent I take on being
  # added to such a parent.
  widthWithoutSpacing: ->
    WidgetHolderWithCaptionWdgt.standardDesktopIconExtent().x

  _resizeToWithoutSpacing: ->
    @_applyExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()

  initialiseDefaultFrameContentLayoutSpec: ->
    super
    @_contentStackSpec.canSetHeightFreely = false

  _setWidthSizeHeightAccordingly: (newWidth) ->
    @_applyExtent new Point newWidth, WidgetHolderWithCaptionWdgt.standardDesktopIconExtent().y
    @_reLayout()
    @height()  # Path B: hand the resulting height back. See Widget._setWidthSizeHeightAccordingly.

  # §4.1 pure measure (sizing-model unification U3-B): the standard height for any width (mirrors
  # _setWidthSizeHeightAccordingly above). No mutation, no seam.
  preferredExtentForWidth: (availW) ->
    new Point availW, WidgetHolderWithCaptionWdgt.standardDesktopIconExtent().y

  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # MY TILE, in my plane (the coordinates of my own bounds): the desktopIconTile square
  # desktopIconPadding below my top, centred across my width (rounded down). My layout places my
  # glyph in it; my appearance paints it and hit-tests it.
  _tileRect: ->
    theme = WorldWdgt.theme
    side = theme.desktopIconTile
    left = @left() + Math.floor (@width() - side) / 2
    top = @top() + theme.desktopIconPadding
    new Rectangle left, top, left + side, top + side

  # MY PLATE, in my plane: my caption's box outset by the plate's padding, read from the caption
  # whenever it is asked, so it can never disagree with the text it stands under (my caption is my
  # child, in my plane). None while my caption is not my child (a holder mid-restore, or one whose
  # caption has been taken out of it).
  _plateRect: ->
    return undefined unless @label?.parent is @
    theme = WorldWdgt.theme
    @label.boundingBox().expandBy new Point theme.desktopIconPlateHorizontalPadding, theme.desktopIconPlateVerticalPadding

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->
    theme = WorldWdgt.theme

    # the glyph: the glyph square, centred in the tile (rounded down)
    tile = @_tileRect()
    if @icon?.parent is @
      glyphSize = theme.desktopIconGlyphSize
      glyphInset = Math.floor (tile.width() - glyphSize) / 2
      @icon._applyBounds (tile.topLeft().add new Point glyphInset, glyphInset), new Point glyphSize, glyphSize

    return unless @label?.parent is @
    # the caption's lines, measured with its own wrapper (getTextWrappingData, the measure
    # breakTextIntoLines delegates to, which reads no wrapping mode of the caption's) at the plate's
    # text width -- my width less the plate's padding at each side -- and at the size it paints at
    horizontalPadding = theme.desktopIconPlateHorizontalPadding
    textWidth = Math.max 1, @width() - 2 * horizontalPadding
    text = @label.transformTextOneToOne @label.text
    [lines, lineSlots, widestLine] = @label.getTextWrappingData @label.originallySetFontSize, textWidth, text, @label.getParagraphs text
    wraps = lines.length > 1
    lineCount = Math.max 1, Math.min lines.length, theme.desktopIconCaptionMaxLines
    # ONE line: a box exactly as wide as the line (the wrapper's widths are whole pixels), and no
    # wrapping at its own width -- the wrapper counts a trailing space after the last word, which a
    # box that hugs the line does not hold, so a wrapping caption would break its one line there.
    # MORE: wrapping at the text width they were measured at, in a box that wide, so the caption
    # shows exactly the lines measured here (CROP ends the last one it can hold in "…"). Either way
    # the box is as tall as those lines on the caption's own line box, at the size it paints at, so
    # the plate's lines and the caption's agree.
    @label.softWrap = wraps
    boxWidth = if wraps then textWidth else Math.max @label.getMinimumExtent().x, Math.min widestLine, textWidth
    boxHeight = lineCount * @label.linePitch @label.originallySetFontSize
    # the plate centred across my width (rounded down), the box inside it at the plate's padding
    plateLeft = @left() + Math.floor (@width() - (boxWidth + 2 * horizontalPadding)) / 2
    boxTop = tile.bottom() + theme.desktopIconTilePlateGap + theme.desktopIconPlateVerticalPadding
    @label._applyBounds (new Point plateLeft + horizontalPadding, boxTop), new Point boxWidth, boxHeight
    # fit the caption's text to its new box NOW rather than at its next paint: a rename reads that
    # fit right after the keystroke's settle, to decide whether the text still fits inline
    # (StringWdgt.handOffToPopoutEditorIfOverflowing)
    @label.reflowText()

  # My caption's text changed (a rename, keystroke by keystroke, or any other setText): my plate and
  # my caption's box follow its lines, so I lay myself out again -- through the phase valve, since a
  # wire can deliver text into the caption inside a layout pass.
  _reactToChildTextChanged: (child) ->
    return unless child is @label
    @_scheduleRelayoutRespectingPhase()

  # A RESTORED icon lays itself out again, at the next settle, from the theme of the page loading
  # it: the bounds its children were saved with belong to the page that saved it.
  _afterDeserialization: ->
    @_scheduleRelayoutRespectingPhase()

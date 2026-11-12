# A TOOL CELL: the square a toolbar's tool stands in (ToolPanelWdgt wraps every tool it is given in
# one), which is also the larger target a thumbnail is grabbed by. It holds the tool -- its ITEM, its
# first child -- and, over a tool that is there only to be dragged out (not actionableAsThumbnail),
# the LID a press lands on (GlassBoxTopWdgt).
#
# MY LOOK is my tool's state and nothing else, every value a Theme role or metric (the draft's tool
# button): a square rounded at toolCellCornerRadius with no border; no fill at rest, so the glyph
# stands alone on whatever the strip stands on; toolCellHoverFill while my tool is hovered,
# toolCellPressedFill while it is pressed, toolCellActiveFill while it is the ACTIVE tool (hovered or
# not; pressed shows pressed). The pointer state is the hand's answer about the widget a press on me
# reaches (thumbnailClickReceiver: the lid, or the tool itself), when that widget is a tool that
# lights its cell (lightsAToolCell); whether my tool is active is its own answer (isActiveTool, a
# capability: a tool that is never active answers nothing). The look is read from the two as I am
# painted (_fillForMyState), and repainted when I am told one moved (noteItemStateChanged): by the
# tool whose pointer state moved (every tool family and the lid say so as the hand tells them), and
# by whoever decides which tool is active (PaintToolbarWdgt for the armed paint tool,
# TextToolbarWdgt for the text tools, which mirror the edited text). No tool pushes a colour onto
# me, and I keep none, so no family can leave one behind.
#
# MY TOOL IS CUT TO MY OUTLINE: it lies flush in my square, so I paint my children inside my rounded
# outline, and a press in one of my corner notches reaches neither me nor my tool but whatever lies
# behind me (_roundedChildClipRadii: the rounded frame's mechanism, visual-design-system §4.7).
# Anywhere else in my square a press lands on my tool, at rest as much as hovered: a fill of no
# colour changes how I paint, never my shape.

class GlassBoxBottomWdgt extends BoxWdgt

  colloquialName: -> "tool cell"

  # my rounding is the tool cell's, from the theme, as I am built; my fill is read as I am painted
  constructor: ->
    super WorldWdgt.theme.toolCellCornerRadius

  # Role query (replaces the `aWdgt instanceof GlassBoxBottomWdgt` wrap-idempotency guard in
  # ToolPanelWdgt.add): "am I already a glass-box template wrapper?" -- true
  # here only, so a widget is never wrapped twice. Dispatched via ?() (nothing on Widget).
  # (type-test-elimination campaign)
  isGlassBoxWrapper: ->
    true

  # The one widget I wrap -- the tool this cell offers, which is what names the cell in a menu.
  # (GlassBoxTopWdgt's grab reads the same first child.)
  glassBoxItem: ->
    @children[0]

  # The widget a TAP on me actually reaches, which is therefore what any PROJECTION of this cell
  # -- a toolbar overflow menu's row -- must click: one dispatch contract for every tool family.
  # A tool that is not actionable as a thumbnail wears a LID (ToolPanelWdgt puts one there), and
  # then the lid is what the pointer lands on and the lid is what carries the click; a tool that
  # handles its own clicks wears none and catches its taps itself. It is also the widget whose
  # pointer state my look shows.
  thumbnailClickReceiver: ->
    (@firstChildSuchThat (eachChild) -> eachChild.isGlassBoxLid?()) ? @glassBoxItem()

  # ===== my look =====

  # MY TOOL'S STATE MOVED: the hand's answers about the widget a press on me reaches moved (that
  # widget's notePointerStateChanged tells me: CreatorWdgt, EditorContentPropertyChangerButtonWdgt,
  # CodeInjectingSimpleRectangularButtonWdgt), or my tool became or stopped being the active one (told
  # by whoever decides that: PaintToolbarWdgt for the armed paint tool, TextToolbarWdgt when the edited
  # text or its style moves). My look is read as I am painted, so I repaint, and I pass the news on, so
  # what shows my tool's state THROUGH me re-reads it: a toolbar overflow menu's row for my tool,
  # ticked by holdsActiveTool (OverflowChevronButtonWdgt). markNonValueChange: what moved is not a
  # value (I have none to deliver). A paint toolbar tells me from its arrange, so that news reaches a
  # row one cycle later (DataflowEngine's header: a layout station may announce a non-value change).
  noteItemStateChanged: ->
    @_changed()
    world.dataflow?.markNonValueChange @

  # Is my tool the ACTIVE one, by its own answer (isActiveTool, a capability: a tool that is never
  # active answers nothing)? Read by my look and by a menu row that reflects me
  # (MenuRowReflectionSpec.readerName).
  holdsActiveTool: ->
    @glassBoxItem()?.isActiveTool?() ? false

  # My fill for my tool's state now, which my BoxyAppearance reads as it paints me (and no border: I
  # answer no stroke).
  _fillForMyState: ->
    GlassBoxBottomWdgt.fillForToolState @thumbnailClickReceiver(), @holdsActiveTool()

  # THE TOOL CELL'S FILL for a tool whose pointer state `stateHolder` shows -- the hand's answers about
  # it (ActivePointerWdgt.pressesOn, restsOn), when it is a tool that lights a cell (lightsAToolCell:
  # every toolbar tool family, a cell's lid, the overflow chevron; an absent holder, or any other
  # widget -- a menu row standing in a cell shows its own hover --, reads as at rest) -- and which is or
  # is not the active tool: toolCellPressedFill while pressed, toolCellHoverFill while hovered, else
  # toolCellActiveFill while active, else toolCellFill. ONE answer for every wearer of the look: my
  # cells, and the toolbar's overflow chevron, which stands in no cell (OverflowChevronAppearance).
  @fillForToolState: (stateHolder, isActive) ->
    theme = WorldWdgt.theme
    if stateHolder?.lightsAToolCell?()
      return theme.toolCellPressedFill if world.hand.pressesOn stateHolder
      return theme.toolCellHoverFill if world.hand.restsOn stateHolder
    if isActive then theme.toolCellActiveFill else theme.toolCellFill

  # ===== my tool, cut to my outline =====

  # The per-corner radii [topLeft, topRight, bottomRight, bottomLeft] of the rounded outline my
  # children are cut to, or undefined when I have no rounding: my own outline's. My paint asks it
  # (below), and so does every descendant's pointer test (Widget.isPointerTargetAt, AM-I-UNCUT).
  _roundedChildClipRadii: ->
    radii = @appearance?.outlineCornerRadii?()
    return undefined unless radii? and Math.max(radii...) > 0
    radii

  # Widget's content paint -- my own fill, my children, the selection overlay -- with my children
  # painted inside my rounded outline (Widget._paintChildrenInsideMyRoundedOutline, the rounded
  # frame's own): they lie inside my square, so nothing of theirs is lost but what my notches cut.
  # Unrounded, exactly Widget's body. ⚠ LOCKSTEP with Widget's
  # _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: an edit to that body must be
  # mirrored here.
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    radii = @_roundedChildClipRadii()
    if !radii?
      @_paintChildrenOver aContext, clippingRectangle, appliedShadow
    else
      damagedPartOfMe = @boundingBox().intersect clippingRectangle
      unless damagedPartOfMe.isEmpty()
        @_paintChildrenInsideMyRoundedOutline aContext, damagedPartOfMe, appliedShadow, radii
    @_paintEditorSelectionOverlayIfSelected aContext, clippingRectangle, appliedShadow

  _reLayoutSelf: ->

    @_repaintAsOneUnit =>

      thumbnailSize = @width()

      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      for w in childrenNotHandlesNorCarets

        # a menu item is sized to its text; other contents become square thumbnails
        # (instead of `w instanceof MenuItemWdgt`; type-test-elimination campaign)
        if w.isTextSizedGlassBoxItem?()
          w._applyMoveTo @topLeft().add((new Point 0 ,(@height() - w.height())/2 ).round())
        else
          if w.idealRatioWidthToHeight?
            ratio = w.idealRatioWidthToHeight
            if ratio > 1
              # more wide than tall
              w._applyExtent new Point thumbnailSize, thumbnailSize / ratio
            else
              # more tall than wide
              w._applyExtent new Point thumbnailSize * ratio, thumbnailSize
          else
            w._applyExtent new Point thumbnailSize, thumbnailSize

          w._applyMoveTo @topLeft().add((new Point (thumbnailSize - w.width())/2 ,(thumbnailSize - w.height())/2 ).round())

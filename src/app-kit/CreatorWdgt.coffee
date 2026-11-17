# A CREATOR: a toolbar tool that makes a widget when clicked (createWidgetToBeHandled, my
# subclasses') and places it -- into the topmost window whose content takes a click-placed widget,
# else beside me on the desktop. A window in view mode takes none, and neither does a content that
# stamps what is dropped on it (a drawing): a click ends in the same kind of result a drop would, so
# it passes over both. The base of the creator buttons and of a tool cell's lid (GlassBoxTopWdgt).

class CreatorWdgt extends Widget

  # MY HOVER AND PRESS show on the tool cell I stand in, never on me: the cell reads the hand's answers
  # about me as it paints (GlassBoxBottomWdgt.fillForToolState asks this), and I tell it when they move.
  lightsAToolCell: ->
    true

  # The hand's answers about me may have moved (ActivePointerWdgt._tellPointerStateChanged): my glyph
  # keeps its one ink, so I tell the cell I stand in, which repaints over me. A parent that is no cell
  # answers nothing.
  notePointerStateChanged: ->
    @parent?.noteItemStateChanged?()


  activated: (ignored, ignored2, ignored3, ignored4, ignored5, ignored6, ignored7, partOfDoubleClick) ->
    if partOfDoubleClick
      return
    widgetToBePlaced = @createWidgetToBeHandled()
    # none made (a copy refused, and told): nothing to place
    return unless widgetToBePlaced?

    # TODO un-handled cases:
    #  - empty window with drop-in placeholder
    #  - window with panel
    #  - window with scrollpanel
    # find the topmost window whose content takes a smart-placed widget, then let that content
    # place it. acceptsSmartPlacedWidgets / smartPlace live on the content widgets (the citizens'
    # StretchableWidgetContainerWdgt payload, and a DocumentWdgt's DocumentViewportWdgt payload),
    # asked through ?(). A content takes none while its editing is off (a window in view mode), nor
    # when it stamps what is dropped on it (a drawing: StretchableCanvasWdgt.stampsDroppedWidgets),
    # so the search passes over such a window and goes on to the next one down.
    where = world.topmostChildSuchThat (w) ->
      # instead of `w instanceof FrameWdgt` (type-test-elimination campaign)
      w.isFrame?() and w.contents?.acceptsSmartPlacedWidgets?()

    if where?
      where.contents.smartPlace widgetToBePlaced, @
    else
      # the new widget is a WORLD child placed beside ME, and I live on a toolbar's
      # scrolled plane — emit my corner through the plane→screen map (identity when
      # unscrolled/untilted, rounded because screen-family values may be fractional
      # under tilt), never the raw plane-local @topRight() (paint-time scroll review F1).
      widgetToBePlaced._applyMoveTo (@localPointToScreen @topRight()).round().add new Point 20, -40
      widgetToBePlaced._moveWithin world
      world.add widgetToBePlaced

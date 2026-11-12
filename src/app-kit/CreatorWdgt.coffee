# A CREATOR: a toolbar tool that makes a widget when clicked (createWidgetToBeHandled, my
# subclasses') and places it -- into the topmost window that smart-places widgets, else beside me
# on the desktop. The base of the creator buttons and of a tool cell's lid (GlassBoxTopWdgt).

class CreatorWdgt extends Widget

  # my hover / press state shows on the tool cell I stand in, never on me (ParentStainerMixin). The
  # order matters: both mixins define _updateColor, and the later one's (ParentStainerMixin's) is mine.
  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name


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
    # find the topmost editing-enabled window whose contents knows how to
    # accept a smart-placed widget, then let that content widget place it.
    # The contents-type branching that used to be here is now polymorphic:
    # acceptsSmartPlacedWidgets / smartPlace live on the content widgets
    # (the citizens' StretchableWidgetContainerWdgt payload, and a
    # DocumentWdgt's DocumentViewportWdgt payload -- §5.B).
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

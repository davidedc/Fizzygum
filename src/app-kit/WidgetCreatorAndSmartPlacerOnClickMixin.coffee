WidgetCreatorAndSmartPlacerOnClickMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      mouseClickLeft: (ignored, ignored2, ignored3, ignored4, ignored5, ignored6, ignored7, partOfDoubleClick) ->
        if partOfDoubleClick
          return
        widgetToBePlaced = @createWidgetToBeHandled()

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

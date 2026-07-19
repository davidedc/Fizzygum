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
        # (StretchableEditableWdgt + subclasses, and a DocumentWdgt's
        # SimpleDocumentScrollPanelWdgt payload -- §5.B).
        where = world.topmostChildSuchThat (w) ->
          # was `w instanceof FrameWdgt` (type-test-elimination campaign)
          w.isFrame?() and w.contents?.acceptsSmartPlacedWidgets?()

        if where?
          where.contents.smartPlace widgetToBePlaced, @
        else
          widgetToBePlaced._applyMoveTo @topRight().add new Point 20,-40
          widgetToBePlaced._moveWithin world
          world.add widgetToBePlaced

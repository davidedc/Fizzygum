# REQUIRES globalFunctions


WidgetCreatorAndSmartPlacerOnClickMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      mouseClickLeft: ->
        widgetToBePlaced = @createWidgetToBeHandled()

        # TODO un-handled cases:
        #  - empty window with drop-in placeholder
        #  - window with panel
        #  - window with scrollpanel
        where = world.topmostChildSuchThat (w) ->
          (w instanceof WindowWdgt) and
          (w.contents?) and
          ((w.contents instanceof StretchableEditableWdgt) or
           (w.contents instanceof SimpleDocumentWdgt) or
           (w.contents instanceof PatchProgrammingWdgt) or
           (w.contents instanceof SimpleSlideWdgt)) and
          (w.contents.dragsDropsAndEditingEnabled)

        if where?
          if (where.contents instanceof StretchableEditableWdgt) or
           (where.contents instanceof PatchProgrammingWdgt) or
           (where.contents instanceof SimpleSlideWdgt)
            widgetToBePlaced.fullRawMoveTo where.contents.stretchableWidgetContainer.center().round().subtract widgetToBePlaced.extent().floorDivideBy 2
            where.contents.stretchableWidgetContainer.add widgetToBePlaced
            widgetToBePlaced.rememberFractionalSituationInHoldingPanel()
            where.contents.stretchableWidgetContainer.bringToForeground()
            @bringToForeground()
          else
            # this is in case of the simpleDocument
            where.contents.simpleDocumentScrollPanel.add widgetToBePlaced
            where.contents.simpleDocumentScrollPanel.scrollToBottom()
            where.contents.simpleDocumentScrollPanel.bringToForeground()
            @bringToForeground()
        else
          widgetToBePlaced.fullRawMoveTo @topRight().add new Point 20,-40
          widgetToBePlaced.fullRawMoveWithin world
          world.add widgetToBePlaced

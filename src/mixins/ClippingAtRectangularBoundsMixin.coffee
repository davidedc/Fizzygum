ClippingAtRectangularBoundsMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      clipsAtRectangularBounds: true

      # used for example:
      # - to determine which widgets you can attach a widget to
      # - for a SliderWdgt's "set target" so you can change properties of another Widget
      # - by the HandleWdgt when you attach it to some other widget
      # Note that this method has a slightly different
      # version in Widget (because it doesn't clip)
      plausibleTargetAndDestinationWidgets: (theWidget) ->
        # find if I intersect theWidget,
        # then check my children recursively
        # exclude me if I'm a child of theWidget
        # (cause it's usually odd to attach a Widget
        # to one of its subwidgets or for it to
        # control the properties of one of its subwidgets)
        result = []
        if @_isSelfPlausibleAttachTargetFor theWidget
          result = [@]

        # Since the PanelWdgt clips its children
        # at its boundary, hence we need
        # to check that we don't consider overlaps with
        # widgets contained in this Panel that are clipped and
        # hence *actually* not overlapping with theWidget.
        # So continue checking the children only if the
        # Panel itself actually overlaps.
        # SCREEN-plane boxes on both sides, like the shared predicate above: this panel can
        # itself be a resident of a scrolled pane / island, and theWidget likewise.
        if @screenBounds().isIntersecting theWidget.screenBounds()
          @children.forEach (child) ->
            result = result.concat child.plausibleTargetAndDestinationWidgets theWidget

        return result
      
      # here is the magic of a Frame: the recursion
      # stops and we can ignore the bounds of potentially
      # hundreds of widgets that might be in here.
      SLOWfullBounds: ->
        @bounds

      SLOWfullClippedBounds: ->
        if @isOrphan() or !@SLOWvisibleBasedOnIsVisibleProperty() or @SLOWisInCollapsedSubtree()
          result = Rectangle.EMPTY
        else
          result = @SLOWclippedThroughBounds()
        result

      # Panels clip any of their children
      # at their boundaries
      # so there is no need to do a deep
      # traversal to find the bounds.
      fullBounds: ->
        if @checkFullBoundsCache == WorldWdgt.geometryVersion
          if world.doubleCheckCachedMethodsResults
            if !@cachedFullBounds.equals @SLOWfullBounds()
              debugger
              alert "fullBounds is broken (cached)"
          return @cachedFullBounds

        result = @bounds

        if world.doubleCheckCachedMethodsResults
          if !result.equals @SLOWfullBounds()
            debugger
            alert "fullBounds is broken (uncached)"

        @checkFullBoundsCache = WorldWdgt.geometryVersion
        @cachedFullBounds = result

      fullClippedBounds: ->
        if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
          result = Rectangle.EMPTY
        else
          if @cachedFullClippedBounds?
            if @checkFullClippedBoundsCache == WorldWdgt.geometryVersion
              if world.doubleCheckCachedMethodsResults
                if !@cachedFullClippedBounds.equals @SLOWfullClippedBounds()
                  debugger
                  alert "fullClippedBounds is broken"
              return @cachedFullClippedBounds

          result = @clippedThroughBounds()

        if world.doubleCheckCachedMethodsResults
          if !result.equals @SLOWfullClippedBounds()
            debugger
            alert "fullClippedBounds is broken"

        @checkFullClippedBoundsCache = WorldWdgt.geometryVersion
        @cachedFullClippedBounds = result



      fullPaintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
        super

        # after all the contents are drawn,
        # draw the border of the Panel again.
        # This is because the border has to be drawn inside the Frame,
        # but the contents might paint over it. So, we need to
        # paint them AFTER the content has been painted.
        if !@preliminaryCheckNothingToDraw clippingRectangle, aContext
          if !appliedShadow?
            if !@paintStroke?
              debugger
            @paintStroke aContext, clippingRectangle
            # editor-focus SELECTION overlay LAST -- after my own border re-draw above, else that border
            # (drawn to survive the children painting over it) would in turn paint over my selection frame.
            # (Base Widget draws it at the tail of its content-paint; a clipping panel needs it here.)
            @_paintEditorSelectionOverlayIfSelected aContext, clippingRectangle, appliedShadow

      
      _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->

        # a PanelWdgt has the special property that all of its children
        # are actually inside its boundary.
        # This allows
        # us to avoid the further traversal of potentially
        # many many widgets if we see that the rectangle we
        # want to paint is outside its Panel.
        # If the rectangle we want to paint is inside the Panel
        # then we do have to continue traversing all the
        # children of the Frame.

        
        # the part to be redrawn could be outside the Panel entirely,
        # in which case we can stop going down the widgets inside the Panel
        # since the whole point of the Panel is to clip everything to a specific
        # rectangle. (note that you can't do the same trick with a
        # generic tree of widgets since the root widget doesn't
        # necessarily contain all the subwidgets in its boundaries like
        # the PanelWdgt does)
        # So, check which part of the Frame should be redrawn:
        damagedPartOfFrame = @boundingBox().intersect clippingRectangle
        
        if !damagedPartOfFrame.isEmpty()
        
          if aContext == world.worldCanvasContext
            @_recordDrawnAreaForNextDamageRects()

          # this draws the background of the Panel itself
          @paintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow

          @children.forEach (child) =>
            child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow

      _fullPaintIntoAreaOrBlitFromBackBufferJustShadow: (aContext, clippingRectangle, appliedShadow) ->
        # the culling rect moves OPPOSITE the paint (a pixel at P shows the shadow of
        # content at P − offset), as a VECTOR — any direction, any asymmetry.
        # Rectangle.translateBy takes ONE argument (Point or scalar): passing -x, -y
        # here would silently degrade the translate to a scalar of the x component.
        clippingRectangle = clippingRectangle.translateBy appliedShadow.offset.neg()

        if !@preliminaryCheckNothingToDraw clippingRectangle, aContext

          # the part to be redrawn could be outside the Panel entirely,
          # in which case we can stop going down the widgets inside the Panel
          # since the whole point of the Panel is to clip everything to a specific
          # rectangle.
          # So, check which part of the Frame should be redrawn:
          damagedPartOfFrame = @boundingBox().intersect clippingRectangle
          
          # if there is no damaged part in the Panel then do nothing
          if !damagedPartOfFrame.isEmpty()

            aContext.save()
            aContext.translate appliedShadow.offset.x * ceilPixelRatio, appliedShadow.offset.y * ceilPixelRatio
          
            # this draws the background of the Panel itself
            @paintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow

            # since the widget clips at its boundaries, then we know that all of
            # its children are inside. Hence, if the Panel is fully opaque, then
            # since we are just drawing the shadow, we can just
            # draw the shadow of the Panel itself and skip all of the children.
            if @alpha != 1
              @children.forEach (child) =>
                child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow

            aContext.restore()


      # PanelWdgt scrolling optimization:
      _applyMoveBy: (delta) ->
        @bounds = @bounds.translateBy delta
        @__breakMoveResizeCaches()
        @children.forEach (child) ->
          child.__commitMoveBy delta
        @_changed()

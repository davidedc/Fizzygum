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
        if @visibleBasedOnIsVisibleProperty() and
            !@isInCollapsedSubtree() and
            !theWidget.isAncestorOf(@) and
            @areBoundsIntersecting(theWidget) and
            !@anyParentPopUpMarkedForClosure()
          result = [@]

        # Since the PanelWdgt clips its children
        # at its boundary, hence we need
        # to check that we don't consider overlaps with
        # widgets contained in this Panel that are clipped and
        # hence *actually* not overlapping with theWidget.
        # So continue checking the children only if the
        # Panel itself actually overlaps.
        if @areBoundsIntersecting theWidget
          @children.forEach (child) ->
            result = result.concat child.plausibleTargetAndDestinationWidgets theWidget

        return result

      # do nothing if the call comes from a child
      # otherwise, if it comes from me (say, because the
      # Panel has been moved), then
      # do invalidate the cache as normal.
      invalidateFullBoundsCache: (widgetCalling) ->
        if widgetCalling == @
          super @

      invalidateFullClippedBoundsCache: (widgetCalling) ->
        if widgetCalling == @
          super @
      
      # here is the magic of a Frame: the recursion
      # stops and we can ignore the bounds of potentially
      # hundreds of widgets that might be in here.
      SLOWfullBounds: ->
        @bounds

      SLOWfullClippedBounds: ->
        if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
          result = Rectangle.EMPTY
        else
          result = @clippedThroughBounds()
        #if this != world and result.corner.x > 400 and result.corner.y > 100 and result.origin.x ==0 and result.origin.y ==0
        #  debugger
        result

      # Panels clip any of their children
      # at their boundaries
      # so there is no need to do a deep
      # traversal to find the bounds.
      fullBounds: ->
        if @cachedFullBounds?
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

        @cachedFullBounds = result

      fullClippedBounds: ->
        if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
          result = Rectangle.EMPTY
        else
          if @cachedFullClippedBounds?
            if @checkFullClippedBoundsCache == WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges + "-" + WorldWdgt.numberOfRawMovesAndResizes
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

        @checkFullClippedBoundsCache = WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges + "-" + WorldWdgt.numberOfRawMovesAndResizes
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

      
      fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->

        # a PanelWdgt has the special property that all of its children
        # are actually inside its boundary.
        # This allows
        # us to avoid the further traversal of potentially
        # many many widgets if we see that the rectangle we
        # want to paint is outside its Panel.
        # If the rectangle we want to paint is inside the Panel
        # then we do have to continue traversing all the
        # children of the Frame.

        # This is why as well it's good to use PanelWdgts whenever
        # it's clear that there is a "container" case. Think
        # for example that you could stick a small
        # RectangleWdgt (not a Frame) on the desktop and then
        # attach a thousand
        # CircleBoxWdgts on it.
        # Say that the circles are all inside the rectangle,
        # apart from four that are at the corners of the world.
        # that's a nightmare scenegraph
        # to *completely* traverse for *any* broken rectangle
        # anywhere on the screen.
        # The traversal is complete because a) Widgetic doesn't
        # assume that the rectangle clips its children and
        # b) the bounding rectangle (which currently is not
        # efficiently calculated anyways) is the whole screen.
        # So the children could be anywhere and need to be all
        # checked for damaged areas to repaint.
        # If the RectangleWdgt is made into a Panel, one can
        # avoid the traversal for any broken rectangle not
        # overlapping it.

        # Also note that in theory you could stop recursion on any
        # PanelWdgt completely covered by a large opaque widget
        # (or on any Widget which fullBounds are completely
        # covered, for that matter). You could
        # keep for example a list of the top n biggest opaque widgets
        # (say, Panels and rectangles)
        # and check that case while you traverse the list.
        # (see https://github.com/davidedc/Fizzygum/issues/149 )
        
        # the part to be redrawn could be outside the Panel entirely,
        # in which case we can stop going down the widgets inside the Panel
        # since the whole point of the Panel is to clip everything to a specific
        # rectangle. (note that you can't do the same trick with a
        # generic tree of widgets since the root widget doesn't
        # necessarily contain all the subwidgets in its boundaries like
        # the PanelWdgt does)
        # So, check which part of the Frame should be redrawn:
        dirtyPartOfFrame = @boundingBox().intersect clippingRectangle
        
        if !dirtyPartOfFrame.isEmpty()
        
          if aContext == world.worldCanvasContext
            @recordDrawnAreaForNextBrokenRects()

          # this draws the background of the Panel itself
          @paintIntoAreaOrBlitFromBackBuffer aContext, dirtyPartOfFrame, appliedShadow

          @children.forEach (child) =>
            child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, dirtyPartOfFrame, appliedShadow

      fullPaintIntoAreaOrBlitFromBackBufferJustShadow: (aContext, clippingRectangle, appliedShadow) ->
        clippingRectangle = clippingRectangle.translateBy -appliedShadow.offset.x, -appliedShadow.offset.y

        if !@preliminaryCheckNothingToDraw clippingRectangle, aContext

          # the part to be redrawn could be outside the Panel entirely,
          # in which case we can stop going down the widgets inside the Panel
          # since the whole point of the Panel is to clip everything to a specific
          # rectangle.
          # So, check which part of the Frame should be redrawn:
          dirtyPartOfFrame = @boundingBox().intersect clippingRectangle
          
          # if there is no dirty part in the Panel then do nothing
          if !dirtyPartOfFrame.isEmpty()

            aContext.save()
            aContext.translate appliedShadow.offset.x * ceilPixelRatio, appliedShadow.offset.y * ceilPixelRatio
          
            # this draws the background of the Panel itself
            @paintIntoAreaOrBlitFromBackBuffer aContext, dirtyPartOfFrame, appliedShadow

            # since the widget clips at its boundaries, then we know that all of
            # its children are inside. Hence, if the Panel is fully opaque, then
            # since we are just drawing the shadow, we can just
            # draw the shadow of the Panel itself and skip all of the children.
            if @alpha != 1
              @children.forEach (child) =>
                child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, dirtyPartOfFrame, appliedShadow

            aContext.restore()


      # PanelWdgt scrolling optimization:
      _applyMoveByAndNotify: (delta) ->
        #console.log "moving all widgets in the Panel"
        @bounds = @bounds.translateBy delta
        #console.log "move 1"
        @__breakMoveResizeCaches()
        @children.forEach (child) ->
          child.__commitMoveBy delta
        @changed()

# I clip my children at my bounds -- their paint and their pointer targeting -- so the
# recursion over my subtree stops at me: my full bounds are my bounds, a damage rect outside me
# skips my whole subtree, and my stroke and selection overlay paint AFTER my children, over
# anything that reaches my edge. The base of every widget that clips at its rectangle: the panel
# family, the viewport, the frame, the inspector, the spreadsheet grid, the vertical stack, and
# the clipping box demo. Each child of mine shows through the clip I answer for it
# (_clipThroughForChild): in place, unless I show it through a box or a plane of my own -- a
# viewport its plane, a window its content.

class ClippingWdgt extends Widget

  # I clip at my rectangle, and I am the only class that does: a widget answering true here IS a
  # ClippingWdgt. The clip-through walk relies on it -- it sends the first ancestor that answers true
  # (TreeNode.firstParentClippingAtBounds) my clipThroughForDescendant with no probe (Widget.clipThrough
  # and its uncached twin, TransformFrameWdgt._ancestorScreenClip and its twin) -- so no other class
  # declares it. (A save never writes it: it is never a widget's own field.)
  clipsAtRectangularBounds: true

  #: structure

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
    # SCREEN-plane boxes on both sides, like the shared predicate above: my mapped VISIBLE
    # box (a panel scrolled/clipped out of view prunes its whole subtree — none of its
    # children can be visible either), theWidget's full mapped box.
    if (@mapRectToScreen @clippedThroughBounds()).isIntersecting theWidget.screenBounds()
      @children.forEach (child) ->
        result = result.concat child.plausibleTargetAndDestinationWidgets theWidget

    return result

  #: geometry

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
        @_reportIfCachedDiverges "fullBounds", @cachedFullBounds, @SLOWfullBounds(), "cached"
      return @cachedFullBounds

    result = @bounds

    if world.doubleCheckCachedMethodsResults
      @_reportIfCachedDiverges "fullBounds", result, @SLOWfullBounds(), "uncached"

    @checkFullBoundsCache = WorldWdgt.geometryVersion
    @cachedFullBounds = result

  fullClippedBounds: ->
    if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
      result = Rectangle.EMPTY
    else
      if @cachedFullClippedBounds?
        if @checkFullClippedBoundsCache == WorldWdgt.geometryVersion
          if world.doubleCheckCachedMethodsResults
            @_reportIfCachedDiverges "fullClippedBounds", @cachedFullClippedBounds, @SLOWfullClippedBounds()
          return @cachedFullClippedBounds

      result = @clippedThroughBounds()

    if world.doubleCheckCachedMethodsResults
      @_reportIfCachedDiverges "fullClippedBounds", result, @SLOWfullClippedBounds()

    @checkFullClippedBoundsCache = WorldWdgt.geometryVersion
    @cachedFullClippedBounds = result

  # ===== the clip each of my children shows through =====

  # THE CLIP ONE OF MY CHILDREN SHOWS THROUGH, in that child's own plane. `clipSoFar` is the clip that
  # reaches me, in my plane. My children show in place, so theirs is that clip, the same object. A
  # container that shows a child through a box or a plane of its own answers for that child: a
  # viewport for its contents (its plane box, through its scroll translation), a window for its
  # content (the box it gives it). Asked of me only by myself: by the clip-through walk, per child edge,
  # through its public door (clipThroughForDescendant below), and by my children's paint
  # (Widget._paintChildrenOver), so the paint, every visible box, damage and the pointer read one answer.
  _clipThroughForChild: (clipSoFar, child) ->
    clipSoFar

  # THE CLIP `descendant` SHOWS THROUGH WHERE IT REACHES ME, as its first clipping ancestor: my own
  # clip-through, as I answer it for the child of mine `descendant` stands in. Widget.clipThrough asks
  # it, and so does a transform island for the clip above it (TransformFrameWdgt._ancestorScreenClip).
  # PUBLIC.
  clipThroughForDescendant: (descendant) ->
    @_clipThroughForChild @clipThrough(), @_myChildOnTheChainOf descendant

  # The uncached twin, which the SLOW oracles read (Widget.SLOWclipThrough, TransformFrameWdgt's
  # _SLOWancestorScreenClip): the same question over my uncached clip-through. PUBLIC.
  SLOWclipThroughForDescendant: (descendant) ->
    @_clipThroughForChild @SLOWclipThrough(), @_myChildOnTheChainOf descendant

  # The child of mine on `descendant`'s ancestor chain (`descendant` itself when it is my child): the
  # edge its clip-through crosses into my subtree. A widget that clips nothing can stand between
  # `descendant` and me, so the climb runs past it.
  _myChildOnTheChainOf: (descendant) ->
    child = descendant
    child = child.parent while child.parent? and child.parent isnt @
    child

  #: drawing

  # My children's paint, over the damaged part of me: inside my rounded outline while I cut my
  # children to one (_roundedChildClipRadii, a rounded frame's), else over that rectangle; either way
  # each child through the clip it shows through (Widget._paintChildrenOver). Both of my paint bodies
  # below paint my children here.
  _paintChildrenInsideMe: (aContext, damagedPartOfMe, appliedShadow) ->
    radii = @_roundedChildClipRadii?()
    if radii?
      @_paintChildrenInsideMyRoundedOutline aContext, damagedPartOfMe, appliedShadow, radii
    else
      @_paintChildrenOver aContext, damagedPartOfMe, appliedShadow


  fullPaintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    super

    # after all the contents are drawn,
    # draw the border of the Panel again.
    # This is because the border has to be drawn inside the Frame,
    # but the contents might paint over it. So, we need to
    # paint them AFTER the content has been painted.
    # The blame for a paint that throws is mine for them: super gave it back to my caller as it returned,
    # so I take it for my stroke and overlay, and give it back after (Widget.fullPaintIntoAreaOrBlitFromBackBuffer)
    blameBefore = world.paintingWidget
    world.paintingWidget = @
    if !@preliminaryCheckNothingToDraw clippingRectangle, aContext
      if !appliedShadow?
        if !@paintStroke?
          console.error "INVARIANT_VIOLATED: a clipping widget re-draws its border with no paintStroke"
        @paintStroke aContext, clippingRectangle
        # editor-focus SELECTION overlay LAST -- after my own border re-draw above, else that border
        # (drawn to survive the children painting over it) would in turn paint over my selection frame.
        # (Base Widget draws it at the tail of its content-paint; a clipping panel needs it here.)
        @_paintEditorSelectionOverlayIfSelected aContext, clippingRectangle, appliedShadow
    world.paintingWidget = blameBefore
    return


  # ⚠ LOCKSTEP: ViewportWdgt overrides BOTH this method and _fullPaintIntoAreaOrBlitFromBackBufferJustShadow
  # below with hand-copied bodies that paint the contents child inside the viewport's plane box and
  # through its scroll translation (a viewport that neither translates nor keeps a margin reaches
  # these bodies through `super`). What stays in step is every step but the children's: the cull to
  # my box, the drawn-area record, my own paint and, in the shadow pass, the offset cull, the
  # translate, the nothing-to-draw check and the opaque short-circuit -- an edit to one of those here
  # must be mirrored there. The children's step agrees in value, not in text: here it is
  # _paintChildrenInsideMe, there the viewport paints each child itself, its contents through the
  # translation and the clip it answers for them (_clipThroughForChild), the rest in place -- the same,
  # because a viewport cuts its children to no rounded outline and shows every child but its contents
  # in place. A viewport that ever answered _roundedChildClipRadii, or a crop for another child, would
  # have to paint that in its own bodies too.
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

      @_paintChildrenInsideMe aContext, damagedPartOfFrame, appliedShadow

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
        # A translucent one silhouettes its children as it paints them, under the shadow offset
        # this pass translates by (a rounded outline's clip follows it: it is traced under the
        # context's own matrix).
        if @alpha != 1
          @_paintChildrenInsideMe aContext, damagedPartOfFrame, appliedShadow

        aContext.restore()


  #: geometry

  # Fast whole-subtree translate for MOVING a clipping panel (a window drag, a
  # programmatic reposition): one bounds rewrite per node, no per-child re-layout.
  # NOT a scroll path: scrolling is a stored offset applied as a paint-time
  # translation (ViewportWdgt._writeScrollOffset) and never moves the plane.
  _applyMoveBy: (delta) ->
    @bounds = @bounds.translateBy delta
    @__breakMoveResizeCaches()
    @children.forEach (child) ->
      child.__commitMoveBy delta
    @_changed()

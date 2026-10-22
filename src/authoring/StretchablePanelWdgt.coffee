# this is made to go inside a StretchableWidgetContainerWdgt,
# it probably makes no sense on its own
#
# I am the PAGE of the Slides Maker, the Dashboards Maker, the Generic panel and Patch programming,
# and I wear the page's own look, read as I am painted (StretchablePanelAppearance): my fill is the
# stretchablePageFill role (_surfaceFill) until a colour is set on me, and my border is an edge on
# all four sides while my container stands in a window's page gutter, else only along the sides
# where my container letterboxes me (_insetEdgeRects).

class StretchablePanelWdgt extends PanelWdgt

  @augmentWith BubblesEditModeToCoordinatorMixin, @name

  # Like every panel I hold no colour of my own: my appearance reads my look from the theme as it
  # paints (my fill, _surfaceFill, and my edges, _insetEdgeRects -- it never asks the panel's
  # _surfaceStroke), so a page saved, loaded or duplicated wears the look of the world it is shown
  # in, and a colour set on me later is mine.
  constructor: ->
    super()
    @appearance = new StretchablePanelAppearance @

  # the fill I am painted with while I hold no colour of my own (RectangularAppearance._fillColor),
  # and the one a text sitting on me melts into in view mode (SimpleTextWdgt.blendInWithPanelColor)
  _surfaceFill: ->
    WorldWdgt.theme.stretchablePageFill

  # MY EDGES, as integer rectangles in my LOCAL logical coordinates, which my appearance fills in the
  # stretchablePageEdge role: the line that marks my sheet's extent (what a slide or a dashboard
  # presents) wherever nothing else marks it. While my container stands in a window's page gutter
  # (StretchableWidgetContainerWdgt.standsInWindowPageGutter), one along each of my four sides: the
  # window's body, its gutter and I are all paper, so a side without its edge would have no boundary
  # at all. Elsewhere -- bare on the desk, in a stack, in a window keeping no gutter -- one along
  # each side where I stand INSET from my container, none along a side flush with it: my container
  # letterboxes me once my ratio has crystallized (StretchableWidgetContainerWdgt._layOutOwnContents),
  # and there my edge is my own boundary against the room around me, while along a flush side what
  # lies past my container's edge (a window's frame, its strip's rule or a docked band, the desk) is
  # the boundary. Outside a container (where I make no sense) I draw none. Asked at every paint, of
  # my container and from where I stand in it (my situation: my top-left in its frame -- we share a
  # plane, I am its child) and the two extents, so it follows every re-lay and every re-parenting of
  # my container; the two vertical edges stop short of a horizontal one, so no pixel is filled
  # twice.
  _insetEdgeRects: ->
    container = @parent
    return [] unless container?.setRatio?
    w = @width()
    h = @height()
    if container.standsInWindowPageGutter?()
      edgeTop = edgeBottom = edgeLeft = edgeRight = true
    else
      offset = @situation().position
      edgeTop = offset.y > 0
      edgeBottom = offset.y + h < container.height()
      edgeLeft = offset.x > 0
      edgeRight = offset.x + w < container.width()
    sideTop = if edgeTop then 1 else 0
    sideBottom = if edgeBottom then h - 1 else h
    edges = []
    edges.push new Rectangle 0, 0, w, 1 if edgeTop
    edges.push new Rectangle 0, h - 1, w, h if edgeBottom
    edges.push new Rectangle 0, sideTop, 1, sideBottom if edgeLeft
    edges.push new Rectangle w - 1, sideTop, w, sideBottom if edgeRight
    edges

  # I re-lay my children from their proportional records (StretchLayoutSpecs, see
  # _reLayout below) -- my COMPLETE child rule, asked by the __add seed and the world's
  # drain stations (see Widget.consumesFractionalGeometryOf): layout-inert chrome
  # (handles / carets / highlighters) is never a reflow subject, exactly as my arrange's
  # childrenNotHandlesNorCarets excludes it.
  consumesFractionalGeometryOf: (child) ->
    !child.isLayoutInert?()

  _reactToChildRemoved: (child) ->
    super
    if @parent?.setRatio? and @parent.ratio?
      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      if childrenNotHandlesNorCarets.length == 0
        @parent.resetRatio()

  # no super: the notification hook is ?.-dispatched with no base implementation — the
  # scroll-holder relay lives on ScrolledPaneWdgt, a plane role a stretchable never plays
  _reactToChildAdded: (child) ->
    # only set ratio with the first added child
    # the following ones don't change it
    if @parent?.setRatio? and !@parent.ratio?
      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      if childrenNotHandlesNorCarets.length != 0
        @parent.setRatio @width() / @height()



  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    @_repaintAsOneUnit =>

      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      # The engine-standard GRANT-BOUNDS arrange (spec-unification arc, closing the founding
      # "antipattern" TODO): each consumed child is granted the integer box its
      # StretchLayoutSpec derives for my granted bounds, through the child's OWN
      # _reLayout(bounds) — the same shape StackLayoutEngine uses. ⚠⚠ The grant MUST keep
      # routing through base Widget._reLayout's PLAIN twins (_applyMoveTo / _applyExtent),
      # never Base twins — falsified both ways (auto-bookkeeping arc, measured): the island's
      # anchor-carrying _applyMoveTo override (Bug-G) is load-bearing for a tilted child, and
      # _applyExtent's schedule-valve gives a resized composite interior (wrapping text,
      # nested scroll) its deferred second re-lay. Base _reLayout provides exactly those on
      # the granted path — see the imposer comment in Widget._moveInDesktopToFractionalPosition.
      for w in childrenNotHandlesNorCarets
        # the SAME membership rule the __add seed and the world drains ask (D10): a
        # layout-inert overlay (highlighter) parked in me is not a reflow subject, and the
        # gated recorder below would refuse it a spec anyway — skip, don't undefined-deref
        continue unless @consumesFractionalGeometryOf w
        # Hardening (§5b): a child that somehow lacks its proportional record — a stale/foreign child,
        # or one added mid-pass before the world's fill drain could seed it — must NOT abort my WHOLE
        # relayout by dereferencing an undefined spec in the grant below (that TypeError is caught as
        # LAYOUT_ERROR and silently aborts the pass). Lazily derive it from the child's current place in
        # me, marked PROVISIONAL (D8): a pre-placement guess the fill drain re-derives once at
        # builder-final geometry — which is what retired the place-before-add builder rule.
        # (No-op when the record is already present — the common case.)
        w._rememberFractionalSituationInHoldingPanel true if !w.layoutSpec?.isStretchElement?()
        # the panel OWNS a spec-carrying child's frame: a pending desire against it is stale
        # by definition (user intent arrives through the post-flush re-record drain), and a
        # desire left to linger would fire at the child's next own settle — clear both.
        w.desiredPosition = undefined
        w.desiredExtent = undefined
        # layout-apply-sanctioned: this IS the arrange — grant the spec-derived integer box
        w._reLayout w.layoutSpec.grantedBoundsWithin newBoundsForThisLayout

      # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
      # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
      # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
      @_applyGrantedBounds newBoundsForThisLayout

    super
    @_markLayoutAsFixed()


  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addEditingLockMenuEntries menu, @childrenNotHandlesNorCarets()

  # canonical settle-wraps; the bubbling cores they dispatch to are injected by
  # BubblesEditModeToCoordinatorMixin
  enableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle triggeringWidget

  disableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle triggeringWidget

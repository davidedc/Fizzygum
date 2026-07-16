# This is what typically people refer to as "icons", however that's not
# quite precise. An icon is just a graphic symbol, it doesn't have a caption per se.
# This widget has a caption instead. Also, since it can hold any widget, the
# final name is WidgetHolderWithCaptionWdgt.

class WidgetHolderWithCaptionWdgt extends Widget

  label: nil

  constructor: (@labelContent, @icon) ->
    super()
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    if !@icon?
      @icon = new SimpleDropletWdgt "icon"
    @_applyExtent new Point 95, 95
    @_addNoSettle @icon
    @label = new StringWdgt @labelContent, WorldWdgt.preferencesAndSettings.shortcutsFontSize
    @label.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @label.color = Color.WHITE
    @label.hasDarkOutline = true
    @_addNoSettle @label, beingDropped: true
    @label.alignCenter()
    @label.alignMiddle()
    @label.isEditable = true
    # update layout
    @_invalidateLayout()

  # I am a desktop icon (an icon with a caption). isDesktopIcon replaces the
  # `instanceof WidgetHolderWithCaptionWdgt` tests that find/skip icons among desktop
  # children; participatesInIconGrid additionally drives the auto grid-positioning of
  # newly-created icons -- BasementOpenerWdgt overrides it to false (it is an icon but the
  # desktop places it itself, not the grid). (type-test-elimination campaign)
  isDesktopIcon: ->
    true

  participatesInIconGrid: ->
    true


  setColor: (theColor, ignored) ->
    @icon.setColor theColor

  widthWithoutSpacing: ->
    Math.min @width(), @height()

  _resizeToWithoutSpacing: ->
    @_applyExtent new Point @widthWithoutSpacing(), @widthWithoutSpacing()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  _setWidthSizeHeightAccordingly: (newWidth) ->
    @_resizeToWithoutSpacing()
    @_applyExtent new Point newWidth, newWidth
    @_reLayout()
    @height()  # Path B: hand the resulting height back. See Widget._setWidthSizeHeightAccordingly.

  # Self-protecting resize (INV-2): I am a composite whose icon + caption are placed by my
  # _reLayout, but I can be sized with the raw _applyExtent core (e.g. BasementOpenerWdgt's ctor
  # does `@_applyExtent new Point 75, 75` after super() built me at 95x95; Widget._createReferenceNoSettle
  # does the same to a document shortcut). A raw apply neither re-lays my children NOR invalidates
  # layout, so without this the icon slot + caption stay at 95-based geometry and overflow the 75x75
  # holder -- the 2026-07 oversized-Basement-icon regression. Same idiom + recursion-safety as
  # GenericCompositeIconWdgt._applyExtent (my sibling composite): _reLayout applies my bounds FIRST,
  # so its own _applyBounds->_applyExtent hits the equal-extent early-return below. The
  # _compositeChildrenBuilt guard skips the re-layout during construction (the `@_applyExtent 95x95`
  # in _buildAndConnectChildrenNoSettle runs BEFORE @label is built; the trailing _invalidateLayout
  # /settle lays the children out then).
  _applyExtent: (extent) ->
    if extent.equals @extent()
      return
    super
    if @_compositeChildrenBuilt()
      @_reLayout @bounds

  # both composite children (icon + caption) exist (see _applyExtent's guard note)
  _compositeChildrenBuilt: ->
    @icon? and @label?

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyBounds newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    height = @height()
    width = @width()

    squareDim = Math.min width, height

     # p0 is the origin, the origin being in the bottom-left corner
    p0 = @topLeft()

    # now the origin if on the left edge, in the middle height of the widget
    p0 = p0.add new Point width/2, height/2
    
    # now the origin is in the middle height of the widget,
    # on the left edge of the square inscribed in the widget
    p0 = p0.subtract new Point squareDim/2, squareDim/2

    @icon._applyExtent (new Point squareDim, squareDim*8/10).round()
    @icon._applyMoveTo p0.round()
    @label._applyExtent (new Point squareDim, squareDim*2/10).round()
    @label._applyMoveTo (p0.add new Point 0, squareDim*8/10).round()


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()


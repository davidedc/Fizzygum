# We need this because we need a panel that keeps its content
# all in the same relative positions and sizes when its
# resized, so you can drag and drop it inside stacks
# and resizable windows and it doesn't mangle the contents
# when it's resized. The way to achieve that is to
# have a container and a type of panel that works together
# to "crystallize" a specific width/height ratio as soon
# as there is one element dropped/added in the panel.
# So when the panel is empty, you can give it any shape you
# want, but as soon as there is one element, it sticks
# to the ratio it has.

class StretchableWidgetContainerWdgt extends Widget

  ratio: nil
  contents: nil

  constructor: (@contents) ->
    super new Point 300, 300
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    if !@contents?
      @contents = new StretchablePanelWdgt

    @_addNoSettle @contents

    @_applyExtent new Point 300, 300
    @contents._applyExtent new Point @width(), @height()
    @_invalidateLayout()

  # actually
  # ends up in the Panel inside it
  add: (aWdgt, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped) ->
    # annotation + handle both attach to the scroll frame directly (was their two instanceof)
    # (type-test-elimination campaign)
    if !@contents? or aWdgt.attachesToScrollFrameDirectly?()
      super
    else
      @contents.add aWdgt, position, layoutSpec, beingDropped

  setRatio: (@ratio) ->
    @layoutSpecDetails?.canSetHeightFreely = false

  resetRatio: ->
    if @ratio?
      @ratio = nil
      @layoutSpecDetails?.canSetHeightFreely = true
      @_invalidateLayout()


  colloquialName: ->
    "stretchable panel"

  initialiseDefaultFrameContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = !@ratio?


  widthWithoutSpacing: ->
    height = @height()
    width = @width()

    if @ratio?
      widthBasedOnHeight = height * @ratio
      heightBasedOnWidth = width / @ratio

      if widthBasedOnHeight <= width
        return widthBasedOnHeight

      else if heightBasedOnWidth <= height
        return width

    else
        return width

  _resizeToWithoutSpacing: ->
    if @ratio?
      @_applyExtent new Point @widthWithoutSpacing(), Math.round(@widthWithoutSpacing()/@ratio)

  _setWidthSizeHeightAccordingly: (newWidth) ->
    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents

    if childrenNotHandlesNorCarets.length != 0
      if !@ratio?
        @ratio = @width() / @height()
        @layoutSpecDetails?.canSetHeightFreely = false
      @_applyExtent new Point newWidth, Math.round(newWidth/@ratio)
    else
      @_applyExtent new Point newWidth, @height()
    @height()  # Path B: hand the resulting height back. See Widget._setWidthSizeHeightAccordingly.

  # §4.1 pure measure (sizing-model unification U3-B): mirrors _setWidthSizeHeightAccordingly
  # above -- ratio-locked while holding content, width-invariant when empty. When the sizing
  # hasn't lazily initialised @ratio yet, the SAME value is DERIVED locally with NO write --
  # a measure must not take the mutation's lazy-init side effect (@ratio + canSetHeightFreely).
  preferredExtentForWidth: (availW) ->
    if (@childrenNotHandlesNorCarets @contents).length != 0
      ratio = @ratio ? (@width() / @height())
      new Point availW, Math.round(availW / ratio)
    else
      new Point availW, @height()



  _reLayout: (newBoundsForThisLayout) ->



    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return


    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyBounds newBoundsForThisLayout


    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of this widget are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    height = @height()
    width = @width()

    if @ratio?
      widthBasedOnHeight = height * @ratio
      heightBasedOnWidth = width / @ratio

       # p0 is the origin, the origin being in the top-left corner
      p0 = @topLeft()

      if widthBasedOnHeight <= width
        p0 = p0.add new Point (width - widthBasedOnHeight) / 2 , 0
        newExtent = new Point widthBasedOnHeight, height

      else if heightBasedOnWidth <= height
        p0 = p0.add new Point 0 , (height - heightBasedOnWidth) / 2
        newExtent = new Point width, heightBasedOnWidth

      newBounds = (new Rectangle p0).setBoundsWidthAndHeight newExtent
      @contents._reLayout newBounds.round()

    else
      @contents._reLayout @bounds



    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()


  # same as simpledocumentscrollpanel, you can lock the contents.
  # worth factoring it out as a mixin?
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addEditingLockMenuEntries menu, @childrenNotHandlesNorCarets()

  # I coordinate drags/drops/editing for my StretchablePanelWdgt child, which delegates
  # its enable/disable up to me (it replaced `@parent instanceof
  # StretchableWidgetContainerWdgt` with this query). I am in turn an editable child of
  # a slide, so I bubble my own enable/disable up the same way. (type-test-elimination campaign)
  coordinatesDragsDropsAndEditingForChildren: ->
    true

  enableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle triggeringWidget

  _enableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @parent?.showEditModeInBar?()
    if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
      @parent._enableDragsDropsAndEditingNoSettle @
    else
      super @

  disableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle triggeringWidget

  _disableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.showViewModeInBar?()
    if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
      @parent._disableDragsDropsAndEditingNoSettle @
    else
      super @

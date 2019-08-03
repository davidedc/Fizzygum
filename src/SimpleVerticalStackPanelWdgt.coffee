# REQUIRES ClippingAtRectangularBoundsMixin


class SimpleVerticalStackPanelWdgt extends Widget

  # stacks don't necessarily enforce a width on contents
  # so the contents could stick out, so we clip at the bounds
  @augmentWith ClippingAtRectangularBoundsMixin, @name

  _acceptsDrops: true
  tight: true
  constrainContentWidth: true
  # used to avoid recursively re-entering the
  # adjustContentsBounds function
  _adjustingContentsBounds: false

  colloquialName: ->
    "stack"

  add: (aMorph, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped, unused, positionOnScreen) ->
    aMorph.rawResizeToWithoutSpacing()

    # find out WHERE to add the widget. Find the existing widget in the
    # stack that is at the same height, and put the new
    # widget after it

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    # The vertical stack just lays down
    # the children in the exact sibling order, so all we have to do
    # is to count up to the child at the same height, say it's
    # child "n", then are going to add the new widget in position
    # "n+1".
    # (conveniently, "add" supports an argument to insert a widget
    # in a specific order among the siblings.)
    positionNumberAmongSiblings = nil
    if (childrenNotHandlesNorCarets.length > 0) and (positionOnScreen instanceof Point)
      positionNumberAmongSiblings = 0
      for eachChild in childrenNotHandlesNorCarets
        positionNumberAmongSiblings++
        if eachChild.top() < positionOnScreen.y and eachChild.bottom() > positionOnScreen.y
          break

    if positionNumberAmongSiblings?
      super aMorph, positionNumberAmongSiblings, layoutSpec, beingDropped
    else
      super

  constructor: (extent, color, @padding, @constrainContentWidth = true) ->
    super()
    @appearance = new RectangularAppearance @
    @silentRawSetExtent(extent) if extent?
    @color = color if color?

  childRemoved: ->
    if @amIPanelOfScrollPanelWdgt()
      @parent.adjustContentsBounds()
      @parent.adjustScrollBars()
      return
    @adjustContentsBounds()

  reactToDropOf: ->
    if @amIPanelOfScrollPanelWdgt()
      @parent.adjustContentsBounds()
      @parent.adjustScrollBars()
      return
    @adjustContentsBounds()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  availableWidthForContents: ->
    @width() - 2 * @padding

  adjustContentsBounds: ->
    # avoid recursively re-entering this function
    if @_adjustingContentsBounds then return else @_adjustingContentsBounds = true
    @padding = 5

    stackHeight = 0
    verticalPadding = 0

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    childrenNotHandlesNorCarets.forEach (morph) =>
      if morph.layoutSpec != LayoutSpec.ATTACHEDAS_VERTICAL_STACK_ELEMENT
        morph.initialiseDefaultVerticalStackLayoutSpec()
        morph.layoutSpecDetails.rememberInitialDimensions morph, @
        morph.setLayoutSpec LayoutSpec.ATTACHEDAS_VERTICAL_STACK_ELEMENT

    childrenNotHandlesNorCarets.forEach (morph) =>
      verticalPadding += @padding

      if !@constrainContentWidth
        # if the stack doesn't contrain the positions of the
        # contents then it's much harder to right/left/center align
        # things, because for example imagine this case: you
        # remove an element from the stack. Now, something that was
        # centered ends up defining the new bounds of the Stack.
        # But hey, that shouldn't have happened because that element
        # was centered, so it could not possibly define the bounds...
        # So the determination of the bounds becomes rather more
        # complex, we are skipping that for the time being: if a stack
        # doesn't contrain the widths of the contents then everything in
        # it looks left-aligned
        leftPosition = @left() + @padding
      else
        recommendedElementWidth = morph.layoutSpecDetails.getWidthInStack()

        # this re-layouts each widget to fit the width.
        morph.rawSetWidthSizeHeightAccordingly recommendedElementWidth

        # the SimplePlainTextWdgt just needs this to be different from null
        # while the TextMorph actually uses this number
        if (morph instanceof TextMorph) or (morph instanceof SimplePlainTextWdgt)
          morph.maxTextWidth = recommendedElementWidth

        if morph.layoutSpecDetails.alignment == 'right'
          leftPosition = @left() + @width() - @padding - recommendedElementWidth
        else if morph.layoutSpecDetails.alignment == 'center'
          leftPosition = @left() + Math.floor (@width() - recommendedElementWidth) / 2
        else
          # we hope here that  morph.layoutSpecDetails.alignment == 'left'
          leftPosition = @left() + @padding


      morph.fullRawMoveTo new Point leftPosition, @top() + verticalPadding + stackHeight
      stackHeight += morph.height()

    newHeight = stackHeight + verticalPadding + @padding

    if !@tight or childrenNotHandlesNorCarets.length == 0
      newHeight = Math.max newHeight, @height()

    @rawSetHeight newHeight
    @_adjustingContentsBounds = false

  rawSetExtent: (aPoint) ->
    unless aPoint.eq @extent()
      #console.log "move 15"
      @breakNumberOfRawMovesAndResizesCaches()
      super aPoint
      @adjustContentsBounds()

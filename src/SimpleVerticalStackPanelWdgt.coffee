# SimpleVerticalStackPanelWdgt /////////////////////////////////////////////////////////


class SimpleVerticalStackPanelWdgt extends Morph

  _acceptsDrops: true
  tight: true

  add: (aMorph) ->
    aMorph.rawResizeToWithoutSpacing()
    super

  constructor: (extent, color, @padding) ->
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

  adjustContentsBounds: ->
    @padding = 5
    totalPadding = 2 * @padding

    stackHeight = 0
    verticalPadding = 0

    childrenNotHandlesNorCarets = @children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

    childrenNotHandlesNorCarets.forEach (morph) =>
      if morph.layoutSpec != LayoutSpec.ATTACHEDAS_VERTICAL_STACK_ELEMENT
        morph.layoutSpecDetails = new VerticalStackLayoutSpec morph, @
        morph.layoutSpec = LayoutSpec.ATTACHEDAS_VERTICAL_STACK_ELEMENT

    childrenNotHandlesNorCarets.forEach (morph) =>
      verticalPadding += @padding

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

  rawSetExtent: (aPoint) ->
    unless aPoint.eq @extent()
      #console.log "move 15"
      @breakNumberOfRawMovesAndResizesCaches()
      super aPoint
      @adjustContentsBounds()

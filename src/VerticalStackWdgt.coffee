# VerticalStackWdgt /////////////////////////////////////////////////////////


class VerticalStackWdgt extends Morph

  _acceptsDrops: true
  tight: true

  constructor: (extent, color, @padding) ->
    super()
    @appearance = new RectangularAppearance @
    @silentRawSetExtent(extent) if extent?
    @color = color if color?

  childRemoved: ->
    if @amIPanelOfScrollFrame()
      @parent.adjustContentsBounds()
      @parent.adjustScrollBars()
      return
    @adjustContentsBounds()

  reactToDropOf: ->
    if @amIPanelOfScrollFrame()
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
      verticalPadding += @padding
      # this re-layouts each widget to fit the width.
      morph.rawSetWidth @width() - 2 * @padding

      # the TextMorph2BridgeForWrappingText just needs this to be different from null
      # while the TextMorph actually uses this number
      if (morph instanceof TextMorph) or (morph instanceof TextMorph2BridgeForWrappingText)
        morph.maxTextWidth = @width() - totalPadding

      morph.fullRawMoveTo new Point @left() + @padding, @top() + verticalPadding + stackHeight
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

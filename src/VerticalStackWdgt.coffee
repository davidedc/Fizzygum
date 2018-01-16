# VerticalStackWdgt /////////////////////////////////////////////////////////


class VerticalStackWdgt extends Morph

  _acceptsDrops: true

  constructor: (extent, color, @padding) ->
    super()
    @appearance = new RectangularAppearance @
    @silentRawSetExtent(extent) if extent?
    @color = color if color?

  reactToDropOf: ->
    @adjustContentsBounds()

  adjustContentsBounds: ->
    @padding = 5
    debugger
    totalPadding = 2 * @padding

    stackHeight = 0
    verticalPadding = 0

    @children.forEach (morph) =>
      if (morph instanceof HandleMorph) or (morph instanceof CaretMorph)
        return
      verticalPadding += @padding
      # this re-layouts each widget to fit the width.
      morph.rawSetWidth @width() - 2 * @padding

      # the TextMorph2BridgeForWrappingText just needs this to be different from null
      # while the TextMorph actually uses this number
      if (morph instanceof TextMorph) or (morph instanceof TextMorph2BridgeForWrappingText)
        morph.maxTextWidth = @width() - totalPadding

      morph.fullRawMoveTo new Point @left() + @padding, @top() + verticalPadding + stackHeight
      stackHeight += morph.height()

    @rawSetHeight Math.max stackHeight + verticalPadding + @padding, @height()

  rawSetExtent: (aPoint) ->
    unless aPoint.eq @extent()
      #console.log "move 15"
      @breakNumberOfRawMovesAndResizesCaches()
      super aPoint
      @adjustContentsBounds()

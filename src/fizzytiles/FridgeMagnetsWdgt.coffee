# this file is excluded from the fizzygum homepage build
class FridgeMagnetsWdgt extends Widget

  # panes:
  fridge: nil
  codeOutput: nil
  magnetsBox: nil
  visualOutput: nil

  dragTheTilesHereHeader: nil
  tilesBinHeader: nil
  liveCodeLangOutputHeader: nil
  outputAnimationHeader: nil

  externalPadding: 0
  internalPadding: 5


  constructor: ->
    super new Point 400, 400
    @_buildAndConnectChildren()

  colloquialName: ->
    "Fizzytiles"
 
  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    #super

    # visual output
    @visualOutput = new FridgeMagnets3DCanvasWdgt
    @visualOutput.disableDrops()
    @_addNoSettle @visualOutput
    
    # source code output pane
    @codeOutput = new FizzytilesCodeWdgt "",nil,nil,nil,nil,nil,(Color.create 255, 250, 245), 1
    @codeOutput.fridgeMagnetsCanvas = @visualOutput
    @codeOutput.isEditable = true
    @codeOutput.enableSelecting()
    @codeOutput.togglefittingSpecWhenBoundsTooLarge()
    @_addNoSettle @codeOutput

    # fridge
    @fridge = new FridgeWdgt
    @fridge.fridgeMagnetsCanvas = @visualOutput
    @fridge.sourceCodeHolder = @codeOutput
    @_addNoSettle @fridge

    # magnets box
    @magnetsBox = new PanelWdgt
    @_addNoSettle @magnetsBox


    # sample magnets -------------------------------
    # the magnets are orphan members built here; label them through the non-settling _setLabelNoSettle core
    # (the public setLabel would re-enter the settle from this low-level build), like the @_addNoSettle adds above.
    @scale = new MagnetWdgt true, @
    @scale._setLabelNoSettle "scale"
    @scale.alignCenter()
    @magnetsBox.add @scale

    @rotate = new MagnetWdgt true, @
    @rotate._setLabelNoSettle "rotate"
    @rotate.alignCenter()
    @magnetsBox.add @rotate

    @box = new MagnetWdgt true, @
    @box._setLabelNoSettle "box"
    @box.alignCenter()
    @magnetsBox.add @box

    @move = new MagnetWdgt true, @
    @move._setLabelNoSettle "move"
    @move.alignCenter()
    @magnetsBox.add @move

    # ----------------------------------------------

    # headers --------------------------------------
    @dragTheTilesHereHeader = new StringWdgt "drag tiles here"
    @dragTheTilesHereHeader.toggleHeaderLine()
    @dragTheTilesHereHeader.alignCenter()
    @_addNoSettle @dragTheTilesHereHeader

    @tilesBinHeader = new StringWdgt "tiles bin"
    @tilesBinHeader.toggleHeaderLine()
    @tilesBinHeader.alignCenter()
    @_addNoSettle @tilesBinHeader

    @liveCodeLangOutputHeader = new StringWdgt "LiveCodeLang output"
    @liveCodeLangOutputHeader.toggleHeaderLine()
    @liveCodeLangOutputHeader.alignCenter()
    @_addNoSettle @liveCodeLangOutputHeader

    @outputAnimationHeader = new StringWdgt "output animation"
    @outputAnimationHeader.toggleHeaderLine()
    @outputAnimationHeader.alignCenter()
    @_addNoSettle @outputAnimationHeader
    # -----------------------------------------------

    @_invalidateLayout()

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my own bounds FIRST, so the children laid out below read the FINAL frame and
    # not the previous pass's (else they lag one cadence on resize -- see InspectorWdgt._reLayout /
    # FanoutWdgt._reLayout). The trailing super re-applies the same bounds, idempotently.
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


    eachPaneWidth = Math.floor( (@width() - 2*@externalPadding - 2 * @internalPadding) / 3)


    # fridge
    fridgeWidth = eachPaneWidth
    fridgeHeight = Math.floor((@height() - 2 * @externalPadding - 2 * 15 - 3 * @internalPadding)/2)

    magnetsBoxLeft = @left() + @externalPadding + eachPaneWidth + @internalPadding

    if @fridge.parent == @
      @fridge._applyMoveTo new Point magnetsBoxLeft, @top() + @externalPadding +  15 + @internalPadding
      @fridge._applyExtent new Point eachPaneWidth, fridgeHeight

    if @liveCodeLangOutputHeader.parent == @
      @liveCodeLangOutputHeader._applyMoveTo new Point magnetsBoxLeft, @fridge.bottom() + @internalPadding
      @liveCodeLangOutputHeader._applyExtent new Point eachPaneWidth, 15

    # codeOutput
    if @codeOutput.parent == @
      @codeOutput._applyMoveTo new Point magnetsBoxLeft, @liveCodeLangOutputHeader.bottom() + @internalPadding
      @codeOutput._applyExtent new Point fridgeWidth, fridgeHeight

    if @dragTheTilesHereHeader.parent == @
      @dragTheTilesHereHeader._applyMoveTo new Point magnetsBoxLeft, @top() + @externalPadding
      @dragTheTilesHereHeader._applyExtent new Point eachPaneWidth, 15

    if @tilesBinHeader.parent == @
      @tilesBinHeader._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tilesBinHeader._applyExtent new Point eachPaneWidth, 15

    # magnets box
    magnetsBoxHeight = @height() - 2 * @externalPadding - 15 - @internalPadding
    if @magnetsBox.parent == @
      @magnetsBox._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding +  15 + @internalPadding
      @magnetsBox._applyExtent new Point(eachPaneWidth, magnetsBoxHeight).round()

    # visual output
    visualOutputLeft = @codeOutput.right() + @internalPadding
    if @visualOutput.parent == @
      @visualOutput._applyMoveTo new Point visualOutputLeft, @top() + @externalPadding +  15 + @internalPadding
      @visualOutput._applyExtent new Point(eachPaneWidth, magnetsBoxHeight).round()

    if @outputAnimationHeader.parent == @
      @outputAnimationHeader._applyMoveTo new Point visualOutputLeft, @top() + @externalPadding
      @outputAnimationHeader._applyExtent new Point eachPaneWidth, 15


    # sample magnets -------------------------------
    if @scale.parent == @magnetsBox
      @scale._applyMoveTo new Point @magnetsBox.left() + @internalPadding, @magnetsBox.top() + @internalPadding

    if @rotate.parent == @magnetsBox
      @rotate._applyMoveTo new Point @magnetsBox.left() + @internalPadding, @scale.bottom() + @internalPadding

    if @box.parent == @magnetsBox
      @box._applyMoveTo new Point @magnetsBox.left() + @internalPadding, @rotate.bottom() + @internalPadding

    if @move.parent == @magnetsBox
      @move._applyMoveTo new Point @magnetsBox.left() + @internalPadding, @box.bottom() + @internalPadding

    # ----------------------------------------------


    world.maybeEnableTrackChanges()

    super
    @_markLayoutAsFixed()


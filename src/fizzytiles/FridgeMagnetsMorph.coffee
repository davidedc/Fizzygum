# this file is excluded from the fizzygum homepage build
class FridgeMagnetsMorph extends Widget

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
    @buildAndConnectChildren()

  colloquialName: ->   
    "Fizzytiles"
 
  buildAndConnectChildren: ->
    if Automator? and
     Automator.state != Automator.IDLE and
     Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    #super

    # visual output
    @visualOutput = new FridgeMagnetsCanvasMorph
    @visualOutput.disableDrops()
    @add @visualOutput
    
    # source code output pane
    @codeOutput = new FizzytilesCodeMorph "",nil,nil,nil,nil,nil,(Color.create 255, 250, 245), 1
    @codeOutput.fridgeMagnetsCanvas = @visualOutput
    @codeOutput.isEditable = true
    @codeOutput.enableSelecting()
    @codeOutput.togglefittingSpecWhenBoundsTooLarge()
    @add @codeOutput

    # fridge
    @fridge = new FridgeMorph
    @fridge.fridgeMagnetsCanvas = @visualOutput
    @fridge.sourceCodeHolder = @codeOutput
    @add @fridge

    # magnets box
    @magnetsBox = new PanelWdgt
    @add @magnetsBox


    # sample magnets -------------------------------
    @scale = new MagnetMorph true, @
    @scale.setLabel "scale"
    @scale.alignCenter()
    @magnetsBox.add @scale

    @rotate = new MagnetMorph true, @
    @rotate.setLabel "rotate"
    @rotate.alignCenter()
    @magnetsBox.add @rotate

    @box = new MagnetMorph true, @
    @box.setLabel "box"
    @box.alignCenter()
    @magnetsBox.add @box

    @move = new MagnetMorph true, @
    @move.setLabel "move"
    @move.alignCenter()
    @magnetsBox.add @move

    # ----------------------------------------------

    # headers --------------------------------------
    @dragTheTilesHereHeader = new StringMorph2 "drag tiles here"
    @dragTheTilesHereHeader.toggleHeaderLine()
    @dragTheTilesHereHeader.alignCenter()
    @add @dragTheTilesHereHeader

    @tilesBinHeader = new StringMorph2 "tiles bin"
    @tilesBinHeader.toggleHeaderLine()
    @tilesBinHeader.alignCenter()
    @add @tilesBinHeader

    @liveCodeLangOutputHeader = new StringMorph2 "LiveCodeLang output"
    @liveCodeLangOutputHeader.toggleHeaderLine()
    @liveCodeLangOutputHeader.alignCenter()
    @add @liveCodeLangOutputHeader

    @outputAnimationHeader = new StringMorph2 "output animation"
    @outputAnimationHeader.toggleHeaderLine()
    @outputAnimationHeader.alignCenter()
    @add @outputAnimationHeader
    # -----------------------------------------------

    @invalidateLayout()

  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts
    #  debugger

    if @isCollapsed()
      @layoutIsValid = true
      @notifyChildrenThatParentHasReLayouted()
      return

    super

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false


    eachPaneWidth = Math.floor( (@width() - 2*@externalPadding - 2 * @internalPadding) / 3) 


    # fridge
    fridgeWidth = eachPaneWidth
    fridgeHeight = Math.floor((@height() - 2 * @externalPadding - 2 * 15 - 3 * @internalPadding)/2)

    magnetsBoxLeft = @left() + @externalPadding + eachPaneWidth + @internalPadding

    if @fridge.parent == @
      @fridge.fullRawMoveTo new Point magnetsBoxLeft, @top() + @externalPadding +  15 + @internalPadding
      @fridge.rawSetExtent new Point eachPaneWidth, fridgeHeight

    if @liveCodeLangOutputHeader.parent == @
      @liveCodeLangOutputHeader.fullRawMoveTo new Point magnetsBoxLeft, @fridge.bottom() + @internalPadding
      @liveCodeLangOutputHeader.rawSetExtent new Point eachPaneWidth, 15

    # codeOutput
    if @codeOutput.parent == @
      @codeOutput.fullRawMoveTo new Point magnetsBoxLeft, @liveCodeLangOutputHeader.bottom() + @internalPadding
      @codeOutput.rawSetExtent new Point fridgeWidth, fridgeHeight

    if @dragTheTilesHereHeader.parent == @
      @dragTheTilesHereHeader.fullRawMoveTo new Point magnetsBoxLeft, @top() + @externalPadding
      @dragTheTilesHereHeader.rawSetExtent new Point eachPaneWidth, 15

    if @tilesBinHeader.parent == @
      @tilesBinHeader.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tilesBinHeader.rawSetExtent new Point eachPaneWidth, 15

    # magnets box
    magnetsBoxHeight = @height() - 2 * @externalPadding - 15 - @internalPadding
    if @magnetsBox.parent == @
      @magnetsBox.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding +  15 + @internalPadding
      @magnetsBox.rawSetExtent new Point(eachPaneWidth, magnetsBoxHeight).round()

    # visual output
    visualOutputLeft = @codeOutput.right() + @internalPadding
    if @visualOutput.parent == @
      @visualOutput.fullRawMoveTo new Point visualOutputLeft, @top() + @externalPadding +  15 + @internalPadding
      @visualOutput.rawSetExtent new Point(eachPaneWidth, magnetsBoxHeight).round()

    if @outputAnimationHeader.parent == @
      @outputAnimationHeader.fullRawMoveTo new Point visualOutputLeft, @top() + @externalPadding
      @outputAnimationHeader.rawSetExtent new Point eachPaneWidth, 15


    # sample magnets -------------------------------
    if @scale.parent == @magnetsBox
      @scale.fullRawMoveTo new Point @magnetsBox.left() + @internalPadding, @magnetsBox.top() + @internalPadding

    if @rotate.parent == @magnetsBox
      @rotate.fullRawMoveTo new Point @magnetsBox.left() + @internalPadding, @scale.bottom() + @internalPadding

    if @box.parent == @magnetsBox
      @box.fullRawMoveTo new Point @magnetsBox.left() + @internalPadding, @rotate.bottom() + @internalPadding

    if @move.parent == @magnetsBox
      @move.fullRawMoveTo new Point @magnetsBox.left() + @internalPadding, @box.bottom() + @internalPadding

    # ----------------------------------------------


    trackChanges.pop()
    if Automator? and
     Automator.state != Automator.IDLE and
     Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()



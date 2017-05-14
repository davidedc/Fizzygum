# FridgeMagnetsMorph //////////////////////////////////////////////////////

class FridgeMagnetsMorph extends BoxMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  # panes:
  fridge: null
  codeOutput: null
  magnetsBox: null
  visualOutput: null
  resizer: null

  constructor: (@target) ->
    super()
    # override inherited properties:
    @silentRawSetExtent new Point(WorldMorph.preferencesAndSettings.handleSize * 20,
      WorldMorph.preferencesAndSettings.handleSize * 20 * 2 / 3).round()
    @padding = if WorldMorph.preferencesAndSettings.isFlat then 1 else 5
    @color = new Color 60, 60, 60
    @buildAndConnectChildren()
  
  buildAndConnectChildren: ->
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # submorphs of the inspector. If they
    # have been peeled away, they still live
    #@fullDestroyChildren()

    # label
    @label = new TextMorph "Fridge magnets"
    @label.fontSize = WorldMorph.preferencesAndSettings.menuFontSize
    @label.isBold = true
    @label.color = new Color 255, 255, 255
    @add @label
    
    # source code output pane
    @codeOutput = new ScrollFrameMorph()
    @codeOutput.disableDrops()
    @codeOutput.contents.disableDrops()
    @codeOutput.isTextLineWrapping = true
    @codeOutput.color = new Color 255, 255, 255
    sourceCode = new TextMorph ""
    sourceCode.isEditable = true
    sourceCode.enableSelecting()
    sourceCode.setReceiver @target
    @codeOutput.setContents sourceCode, 2
    @add @codeOutput

    # fridge
    @fridge = new FridgeMorph()
    @fridge.sourceCodeHolder = @codeOutput
    @add @fridge

    # magnets box
    @magnetsBox = new FrameMorph()
    @add @magnetsBox

    # visual output
    @visualOutput = new FridgeMagnetsCanvasMorph()
    @visualOutput.disableDrops()
    @add @visualOutput

    # resizer
    @resizer = new HandleMorph @


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
    # ----------------------------------------------

    # update layout
    @layoutSubmorphs()

  
  layoutSubmorphs: (morphStartingTheChange = null) ->
    super morphStartingTheChange
    console.log "fixing the layout of the inspector"

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Morph. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false

    # label
    labelLeft = @left() + @padding
    labelTop = @top() + @padding
    labelRight = @right() - @padding
    labelWidth = labelRight - labelLeft
    if @label.parent == @
      @label.fullRawMoveTo new Point labelLeft, labelTop
      @label.rawSetWidth labelWidth
      if @label.height() > @height() - 50
        @silentRawSetHeight @label.height() + 50
        # TODO run the tests when commenting this out
        # because this one point to the Morph implementation
        # which is empty.
        @reLayout()
        
        @changed()
        @resizer.silentUpdateResizerHandlePosition()
    labelBottom = labelTop + @label.height() + 2

    classDiagrHeight = Math.floor(@height() / 2)
    eachPaneWidth = Math.floor(@width() / 3) - @padding


    ###
    fridge: null
    codeOutput: null
    magnetsBox: null
    visualOutput: null
    resizer: null
    ###


    # fridge
    fridgeWidth = eachPaneWidth
    b = @bottom() - (2 * @padding) - WorldMorph.preferencesAndSettings.handleSize
    fridgeHeight = b - labelBottom - classDiagrHeight
    fridgeBottom = labelBottom + fridgeHeight + classDiagrHeight
    fridgeLeft = @fridge.left()

    if @fridge.parent == @
      @fridge.fullRawMoveTo new Point labelLeft, labelBottom
      @fridge.rawSetExtent new Point eachPaneWidth, fridgeHeight

    # codeOutput
    if @codeOutput.parent == @
      @codeOutput.fullRawMoveTo new Point labelLeft, labelBottom + classDiagrHeight
      @codeOutput.rawSetExtent new Point fridgeWidth, fridgeHeight


    # magnets box
    magnetsBoxLeft = labelLeft + eachPaneWidth + @padding
    magnetsBoxWidth = eachPaneWidth
    magnetsBoxHeight = b - labelBottom
    detailRight = fridgeLeft + eachPaneWidth
    if @magnetsBox.parent == @
      @magnetsBox.fullRawMoveTo new Point magnetsBoxLeft, labelBottom
      @magnetsBox.rawSetExtent new Point(eachPaneWidth, magnetsBoxHeight).round()

    # visual output
    visualOutputLeft = labelLeft + eachPaneWidth + @padding + eachPaneWidth + @padding
    visualOutputWidth = eachPaneWidth
    visualOutputRight = visualOutputLeft + visualOutputWidth
    if @visualOutput.parent == @
      @visualOutput.fullRawMoveTo new Point visualOutputLeft, labelBottom
      @visualOutput.rawSetExtent new Point(eachPaneWidth, magnetsBoxHeight).round()

    # sample magnets -------------------------------
    if @scale.parent == @magnetsBox
      @scale.fullRawMoveTo new Point magnetsBoxLeft + 10, labelBottom + 10

    if @rotate.parent == @magnetsBox
      @rotate.fullRawMoveTo new Point magnetsBoxLeft + 10, labelBottom + 50

    if @box.parent == @magnetsBox
      @box.fullRawMoveTo new Point magnetsBoxLeft + 10, labelBottom + 80
    # ----------------------------------------------


    trackChanges.pop()
    @changed()
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()


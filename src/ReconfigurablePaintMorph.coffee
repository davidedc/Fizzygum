# ReconfigurablePaintMorph //////////////////////////////////////////////////////

class ReconfigurablePaintMorph extends BoxMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  mainCanvas: null
  overlayCanvas: null
  pencilToolButton: null
  brushToolButton: null
  radioButtonsHolderMorph: null

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
    @label = new TextMorph "Reconfigurable Paint"
    @label.fontSize = WorldMorph.preferencesAndSettings.menuFontSize
    @label.isBold = true
    @label.color = new Color 255, 255, 255
    @add @label
    

    # mainCanvas
    @mainCanvas = new CanvasMorph()
    @mainCanvas.disableDrops()
    @add @mainCanvas

    # overlayCanvas
    @overlayCanvas = new OverlayCanvasMorph()
    @overlayCanvas.underlyingCanvasMorph = @mainCanvas
    @overlayCanvas.disableDrops()
    @mainCanvas.add @overlayCanvas

    # if you clear the overlay to perfectly
    # transparent, then we need to set this flag
    # otherwise the pointer won't be reported
    # as moving inside the canvas.
    # If you give the overlay canvas even the smallest
    # tint then you don't need this flag.
    @overlayCanvas.noticesTransparentClick = true

    @overlayCanvas.injectCode "mouseMove", """
        (pos, mouseButton) ->
            context = @backBufferContext
            context.setTransform 1, 0, 0, 1, 0, 0
            context.clearRect 0, 0, @width(), @height()

            # give it a little bit of a tint so
            # you can see the canvas when you take it
            # apart from the paint tool.
            #context.fillStyle = new Color 0,255,0,0.5
            #context.fillRect 0, 0, @width(), @height()

            context.translate -@bounds.origin.x, -@bounds.origin.y
            context.translate pos.x, pos.y

            context.beginPath()
            context.lineWidth="2"

            if mouseButton == 'left'
                context.strokeStyle="red"

                contextMain = @underlyingCanvasMorph.backBufferContext
                contextMain.setTransform 1, 0, 0, 1, 0, 0
                contextMain.translate -@bounds.origin.x, -@bounds.origin.y
                contextMain.translate pos.x, pos.y

                contextMain.beginPath()
                contextMain.lineWidth="2"
                contextMain.rect(-5,-5,10,10)
                contextMain.stroke()
                @underlyingCanvasMorph.changed()

            else
                context.strokeStyle="green"
            context.rect(-5,-5,10,10)
            context.stroke()
            @changed()
        """


    @overlayCanvas.injectCode "mouseLeave", """
        # don't leave any trace behind then the pointer
        # moves out.
        (pos) ->
            context = @backBufferContext
            context.setTransform 1, 0, 0, 1, 0, 0
            context.clearRect 0, 0, @width(), @height()
            @changed()
    """


    # tools -------------------------------
    @radioButtonsHolderMorph = new RadioButtonsHolderMorph()
    @add @radioButtonsHolderMorph

    pencilButtonOff = new SimpleButtonMorph true, @, null, new IconMorph(new Point(200,200),null)
    pencilButtonOn = new SimpleButtonMorph true, @, null, new StringMorph2 "pencil on"
    @pencilToolButton = new ToggleButtonMorph pencilButtonOff, pencilButtonOn

    brushToolButtonOff = new SimpleButtonMorph true, @, null, new IconMorph(new Point(200,200),null)
    brushToolButtonOn = new SimpleButtonMorph true, @, null, new StringMorph2 "brush on"
    @brushToolButton = new ToggleButtonMorph brushToolButtonOff, brushToolButtonOn

    @radioButtonsHolderMorph.add @pencilToolButton
    @radioButtonsHolderMorph.add @brushToolButton
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
    labelBottom = labelTop + @label.height() + 2

    eachPaneWidth = Math.floor(@width() / 2) - @padding


    # mainCanvas
    mainCanvasWidth = eachPaneWidth
    b = @bottom() - (2 * @padding) - WorldMorph.preferencesAndSettings.handleSize
    mainCanvasHeight = b - labelBottom
    mainCanvasBottom = labelBottom + mainCanvasHeight
    mainCanvasLeft = @left() + eachPaneWidth

    if @mainCanvas.parent == @
      @mainCanvas.fullRawMoveTo new Point mainCanvasLeft, labelBottom
      @mainCanvas.rawSetExtent new Point eachPaneWidth, mainCanvasHeight

    # overlayCanvas
    overlayCanvasWidth = eachPaneWidth
    b = @bottom() - (2 * @padding) - WorldMorph.preferencesAndSettings.handleSize
    overlayCanvasHeight = b - labelBottom
    overlayCanvasBottom = labelBottom + overlayCanvasHeight
    overlayCanvasLeft = @left() + eachPaneWidth

    if @overlayCanvas.parent == @mainCanvas
      @overlayCanvas.fullRawMoveTo new Point overlayCanvasLeft, labelBottom
      @overlayCanvas.rawSetExtent new Point eachPaneWidth, overlayCanvasHeight

    # tools -------------------------------
    

    if @radioButtonsHolderMorph.parent == @
      @radioButtonsHolderMorph.fullRawMoveTo new Point @left(), labelBottom
      @radioButtonsHolderMorph.rawSetExtent new Point eachPaneWidth, overlayCanvasHeight

    if @pencilToolButton.parent == @radioButtonsHolderMorph
      @pencilToolButton.fullRawMoveTo new Point @left() + 10, labelBottom + 10
      @pencilToolButton.rawSetExtent new Point 100, 30

    if @brushToolButton.parent == @radioButtonsHolderMorph
      @brushToolButton.fullRawMoveTo new Point @left() + 10, labelBottom + 60
      @brushToolButton.rawSetExtent new Point 100, 30

    # ----------------------------------------------


    trackChanges.pop()
    @changed()
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()


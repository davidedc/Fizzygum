# ReconfigurablePaintMorph //////////////////////////////////////////////////////

class ReconfigurablePaintMorph extends DEPRECATEDWindowMorph

  mainCanvas: nil
  overlayCanvas: nil
  pencilToolButton: nil
  brushToolButton: nil
  toothpasteToolButton: nil
  eraserToolButton: nil
  radioButtonsHolderMorph: nil

  constructor: (@target) ->
    super "Fizzypaint"
    @pencilToolButton.select 1
  
  buildAndConnectChildren: ->
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    super

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


    @overlayCanvas.injectProperty "mouseLeave", """
        # don't leave any trace behind then the pointer
        # moves out.
        (pos) ->
            context = @backBufferContext
            context.setTransform 1, 0, 0, 1, 0, 0
            context.clearRect 0, 0, @width() * pixelRatio, @height() * pixelRatio
            @changed()
    """


    # tools -------------------------------

    # small hack on the tool - if we edit code when a tool
    # is pressed, then we push the code without needing
    # the user to press it manually again.
    isToolPressed = ->
        if @parent.buttonShown?
          if @parent.buttons[@parent.buttonShown] != @
            return true
          else
            return false
        return false


    modifyCodeToBeInjected = (unused,textMorph) ->
        @codeToBeInjected = textMorph.text
        if @isToolPressed()
            @injectCodeIntoTarget()

    @radioButtonsHolderMorph = new RadioButtonsHolderMorph()
    @add @radioButtonsHolderMorph

    pencilButtonOff = new CodeInjectingSimpleRectangularButtonMorph @overlayCanvas, new Pencil2IconMorph()
    pencilButtonOff.alpha = 0.1
    pencilButtonOff.isToolPressed = isToolPressed
    pencilButtonOff.modifyCodeToBeInjected = modifyCodeToBeInjected
    pencilButtonOff.codeToBeInjected = """
        mouseMove = (pos, mouseButton) ->
            if world.hand.floatDraggingSomething() then return
            context = @backBufferContext
            context.setTransform 1, 0, 0, 1, 0, 0
            context.clearRect 0, 0, @width() * pixelRatio, @height() * pixelRatio
            context.scale pixelRatio, pixelRatio

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
                contextMain = @underlyingCanvasMorph.backBufferContext
                contextMain.setTransform 1, 0, 0, 1, 0, 0
                contextMain.scale pixelRatio, pixelRatio
                contextMain.translate -@bounds.origin.x, -@bounds.origin.y
                contextMain.translate pos.x, pos.y

                contextMain.beginPath()
                contextMain.lineWidth="2"
                contextMain.fillStyle = "black"
                contextMain.rect(-2,-2,4,4)
                contextMain.fill()
                @underlyingCanvasMorph.changed()

            else
                context.strokeStyle="red"
                context.rect(-2,-2,4,4)
                context.stroke()
            @changed()
        """

    pencilButtonOn = new CodeInjectingSimpleRectangularButtonMorph @overlayCanvas, new Pencil2IconMorph new Color 255,255,255
    pencilButtonOn.alpha = 0.1
    pencilButtonOn.codeToBeInjected = "mouseMove = -> return"

    @pencilToolButton = new ToggleButtonMorph pencilButtonOff, pencilButtonOn




    brushToolButtonOff = new CodeInjectingSimpleRectangularButtonMorph @overlayCanvas, new BrushIconMorph()
    brushToolButtonOff.alpha = 0.1
    brushToolButtonOff.isToolPressed = isToolPressed
    brushToolButtonOff.modifyCodeToBeInjected = modifyCodeToBeInjected

    brushToolButtonOff.codeToBeInjected = """
        mouseMove = (pos, mouseButton) ->
            if world.hand.floatDraggingSomething() then return
            context = @backBufferContext
            context.setTransform 1, 0, 0, 1, 0, 0
            context.clearRect 0, 0, @width() * pixelRatio, @height() * pixelRatio
            context.scale pixelRatio, pixelRatio

            context.translate -@bounds.origin.x, -@bounds.origin.y
            context.translate pos.x, pos.y

            context.beginPath()
            context.lineWidth="2"

            if mouseButton == 'left'
                context.fillStyle = "red"

                contextMain = @underlyingCanvasMorph.backBufferContext
                contextMain.setTransform 1, 0, 0, 1, 0, 0
                contextMain.scale pixelRatio, pixelRatio
                contextMain.translate -@bounds.origin.x, -@bounds.origin.y
                contextMain.translate pos.x, pos.y
                contextMain.fillStyle = "black"

                # the brush is 16 x 16, so center it
                contextMain.translate -8, -8

                # for convenience, the brush has been
                # drawn first using 6x6 squares, so now
                # scale those back
                contextMain.scale 1/6, 1/6

                contextMain.beginPath()
                contextMain.rect 48, 0, 6, 6
                contextMain.rect 36, 6, 6, 6
                contextMain.rect 54, 6, 6, 6
                contextMain.rect 66, 6, 6, 6
                contextMain.rect 30, 12, 12, 6
                contextMain.rect 48, 12, 6, 6
                contextMain.rect 72, 12, 6, 6
                contextMain.rect 12, 18, 36, 6
                contextMain.rect 60, 18, 6, 6
                contextMain.rect 78, 18, 6, 6
                contextMain.rect 24, 24, 42, 6
                contextMain.rect 72, 24, 6, 6
                contextMain.rect 90, 24, 6, 6
                contextMain.rect 18, 30, 42, 6
                contextMain.rect 66, 30, 6, 6
                contextMain.rect 18, 36, 36, 6
                contextMain.rect 6, 36, 6, 6
                contextMain.rect 60, 36, 12, 6
                contextMain.rect 78, 36, 6, 6
                contextMain.rect 90, 36, 6, 6
                contextMain.rect 24, 42, 36, 6
                contextMain.rect 66, 42, 12, 6
                contextMain.rect 6, 48, 6, 6
                contextMain.rect 18, 48, 6, 6
                contextMain.rect 30, 48, 12, 6
                contextMain.rect 54, 48, 6, 6
                contextMain.rect 78, 48, 6, 6
                contextMain.rect 36, 54, 6, 12
                contextMain.rect 48, 54, 6, 6
                contextMain.rect 60, 54, 12, 6
                contextMain.rect 90, 54, 6, 6
                contextMain.rect 6, 60, 6, 6
                contextMain.rect 18, 60, 12, 6
                contextMain.rect 54, 60, 6, 12
                contextMain.rect 78, 60, 6, 6
                contextMain.rect 0, 66, 6, 6
                contextMain.rect 42, 66, 6, 12
                contextMain.rect 66, 66, 6, 6
                contextMain.rect 18, 72, 6, 6
                contextMain.rect 30, 72, 6, 6
                contextMain.rect 60, 78, 6, 6
                contextMain.rect 78, 78, 6, 6
                contextMain.rect 12, 84, 6, 6
                contextMain.rect 36, 84, 6, 6
                contextMain.rect 54, 84, 6, 6
                contextMain.rect 42, 90, 6, 6
                contextMain.rect 18, 6, 6, 6
                contextMain.rect 6, 24, 6, 6
                contextMain.rect 0, 42, 6, 6
                contextMain.fill()


                @underlyingCanvasMorph.changed()

            else
                context.strokeStyle="green"
            context.rect(-5,-5,10,10)
            context.stroke()
            @changed()
        """

    brushToolButtonOn = new CodeInjectingSimpleRectangularButtonMorph @overlayCanvas, new BrushIconMorph new Color 255,255,255
    brushToolButtonOn.alpha = 0.1
    brushToolButtonOn.codeToBeInjected = "mouseMove = -> return"
    @brushToolButton = new ToggleButtonMorph brushToolButtonOff, brushToolButtonOn


    toothpasteToolButtonOff = new CodeInjectingSimpleRectangularButtonMorph @overlayCanvas, new ToothpasteIconMorph()
    toothpasteToolButtonOff.alpha = 0.1
    toothpasteToolButtonOff.isToolPressed = isToolPressed
    toothpasteToolButtonOff.modifyCodeToBeInjected = modifyCodeToBeInjected

    toothpasteToolButtonOff.codeToBeInjected = """
        # Toothpaste graphics
        # original implementation by Ward Cunningham, from Tektronix Smalltalk
        # implementation of Smalltalk 80
        # on the Magnolia (1980-1983) and the Tek 4404 (1984)
        # "Draw spheres ala Ken Knowlton, Computer Graphics, v15 n4 p352."

        paintBrush = (contextMain) ->
            contextMain.save()
            # the brush is 16 x 16, so center it
            contextMain.translate -8, -8

            # for convenience, the brush has been
            # drawn first using 6x6 squares, so now
            # scale those back
            contextMain.scale 1/6, 1/6

            contextMain.beginPath()
            contextMain.rect 48, 0, 6, 6
            contextMain.rect 36, 6, 6, 6
            contextMain.rect 54, 6, 6, 6
            contextMain.rect 66, 6, 6, 6
            contextMain.rect 30, 12, 12, 6
            contextMain.rect 48, 12, 6, 6
            contextMain.rect 72, 12, 6, 6
            contextMain.rect 12, 18, 36, 6
            contextMain.rect 60, 18, 6, 6
            contextMain.rect 78, 18, 6, 6
            contextMain.rect 24, 24, 42, 6
            contextMain.rect 72, 24, 6, 6
            contextMain.rect 90, 24, 6, 6
            contextMain.rect 18, 30, 42, 6
            contextMain.rect 66, 30, 6, 6
            contextMain.rect 18, 36, 36, 6
            contextMain.rect 6, 36, 6, 6
            contextMain.rect 60, 36, 12, 6
            contextMain.rect 78, 36, 6, 6
            contextMain.rect 90, 36, 6, 6
            contextMain.rect 24, 42, 36, 6
            contextMain.rect 66, 42, 12, 6
            contextMain.rect 6, 48, 6, 6
            contextMain.rect 18, 48, 6, 6
            contextMain.rect 30, 48, 12, 6
            contextMain.rect 54, 48, 6, 6
            contextMain.rect 78, 48, 6, 6
            contextMain.rect 36, 54, 6, 12
            contextMain.rect 48, 54, 6, 6
            contextMain.rect 60, 54, 12, 6
            contextMain.rect 90, 54, 6, 6
            contextMain.rect 6, 60, 6, 6
            contextMain.rect 18, 60, 12, 6
            contextMain.rect 54, 60, 6, 12
            contextMain.rect 78, 60, 6, 6
            contextMain.rect 0, 66, 6, 6
            contextMain.rect 42, 66, 6, 12
            contextMain.rect 66, 66, 6, 6
            contextMain.rect 18, 72, 6, 6
            contextMain.rect 30, 72, 6, 6
            contextMain.rect 60, 78, 6, 6
            contextMain.rect 78, 78, 6, 6
            contextMain.rect 12, 84, 6, 6
            contextMain.rect 36, 84, 6, 6
            contextMain.rect 54, 84, 6, 6
            contextMain.rect 42, 90, 6, 6
            contextMain.rect 18, 6, 6, 6
            contextMain.rect 6, 24, 6, 6
            contextMain.rect 0, 42, 6, 6
            contextMain.fill()

            contextMain.restore()

        # you'd be tempted to initialise the queue
        # on mouseDown but it would be a bad idea
        # because the mouse could come "already-pressed"
        # from outside the canvas
        initialiseQueueIfNeeded = ->
            if !@queue?
                @queue = [0..24].map -> nil
            console.log "resetting the queue"

        mouseUpLeft = ->
            if world.hand.floatDraggingSomething() then return
            if @queue?
                console.log "draining the queue"
                contextMain = @underlyingCanvasMorph.backBufferContext
                contextMain.setTransform 1, 0, 0, 1, 0, 0
                contextMain.scale pixelRatio, pixelRatio
                contextMain.translate -@bounds.origin.x, -@bounds.origin.y
                
                until @queue.length == 0
                    console.log @queue.length + " more point left to drain"
                    previousPos = @queue[0]
                    @queue.shift()
                    if previousPos?
                        contextMain.save()
                        contextMain.translate previousPos.x, previousPos.y
                        contextMain.fillStyle = "white"
                        @paintBrush contextMain
                        contextMain.restore()
                delete @queue

        mouseMove = (pos, mouseButton) ->
            if world.hand.floatDraggingSomething() then return
            context = @backBufferContext
            context.setTransform 1, 0, 0, 1, 0, 0
            context.clearRect 0, 0, @width() * pixelRatio, @height() * pixelRatio
            context.scale pixelRatio, pixelRatio

            context.translate -@bounds.origin.x, -@bounds.origin.y
            context.translate pos.x, pos.y

            context.beginPath()
            context.lineWidth="2"

            if mouseButton == 'left'
                @initialiseQueueIfNeeded()
                @queue.push pos
                context.fillStyle = "red"

                contextMain = @underlyingCanvasMorph.backBufferContext
                contextMain.setTransform 1, 0, 0, 1, 0, 0
                contextMain.scale pixelRatio, pixelRatio
                contextMain.translate -@bounds.origin.x, -@bounds.origin.y

                
                contextMain.save()
                contextMain.translate pos.x, pos.y
                contextMain.fillStyle = "black"
                #@paintBrush contextMain
                contextMain.beginPath()
                contextMain.arc 0,0,9,0,2*Math.PI
                contextMain.fill()
                contextMain.restore()


                previousPos = @queue[0]
                @queue.shift()
                if previousPos?
                    contextMain.save()
                    contextMain.translate previousPos.x, previousPos.y
                    contextMain.fillStyle = "white"
                    @paintBrush contextMain
                    contextMain.restore()


                @underlyingCanvasMorph.changed()

            else
                context.strokeStyle="green"
            context.rect(-5,-5,10,10)
            context.stroke()
            @changed()
        """

    toothpasteToolButtonOn = new CodeInjectingSimpleRectangularButtonMorph @overlayCanvas, new ToothpasteIconMorph new Color 255,255,255
    toothpasteToolButtonOn.alpha = 0.1
    toothpasteToolButtonOn.codeToBeInjected = "mouseMove = -> return"
    @toothpasteToolButton = new ToggleButtonMorph toothpasteToolButtonOff, toothpasteToolButtonOn


    eraserToolButtonOff = new CodeInjectingSimpleRectangularButtonMorph @overlayCanvas, new EraserIconMorph()
    eraserToolButtonOff.alpha = 0.1
    eraserToolButtonOff.isToolPressed = isToolPressed
    eraserToolButtonOff.modifyCodeToBeInjected = modifyCodeToBeInjected

    eraserToolButtonOff.codeToBeInjected = """
        mouseMove = (pos, mouseButton) ->
            if world.hand.floatDraggingSomething() then return
            context = @backBufferContext
            context.setTransform 1, 0, 0, 1, 0, 0
            context.clearRect 0, 0, @width() * pixelRatio, @height() * pixelRatio
            context.scale pixelRatio, pixelRatio

            context.translate -@bounds.origin.x, -@bounds.origin.y
            context.translate pos.x, pos.y

            context.beginPath()
            context.lineWidth="2"

            if mouseButton == 'left'
                context.fillStyle = "red"

                contextMain = @underlyingCanvasMorph.backBufferContext
                contextMain.setTransform 1, 0, 0, 1, 0, 0
                contextMain.scale pixelRatio, pixelRatio
                contextMain.translate -@bounds.origin.x, -@bounds.origin.y
                contextMain.translate pos.x, pos.y

                contextMain.beginPath()
                contextMain.lineWidth="2"
                contextMain.fillStyle = new Color 255, 250, 245
                contextMain.rect(-5,-5,10,10)
                contextMain.fill()
                @underlyingCanvasMorph.changed()

            else
                context.strokeStyle="green"
            context.rect(-5,-5,10,10)
            context.stroke()
            @changed()
        """

    eraserToolButtonOn = new CodeInjectingSimpleRectangularButtonMorph @overlayCanvas, new EraserIconMorph new Color 255,255,255
    eraserToolButtonOn.alpha = 0.1
    eraserToolButtonOn.codeToBeInjected = "mouseMove = -> return"
    @eraserToolButton = new ToggleButtonMorph eraserToolButtonOff, eraserToolButtonOn


    pencilAnnotation = new EditableMarkMorph @pencilToolButton, pencilButtonOff, "editInjectableSource"
    brushAnnotation = new EditableMarkMorph @brushToolButton, brushToolButtonOff, "editInjectableSource"
    toothpasteAnnotation = new EditableMarkMorph @toothpasteToolButton, toothpasteToolButtonOff, "editInjectableSource"
    eraserAnnotation = new EditableMarkMorph @eraserToolButton, eraserToolButtonOff, "editInjectableSource"

    @radioButtonsHolderMorph.add @pencilToolButton
    @radioButtonsHolderMorph.add @brushToolButton
    @radioButtonsHolderMorph.add @toothpasteToolButton
    @radioButtonsHolderMorph.add @eraserToolButton
    # ----------------------------------------------

    @invalidateLayout()

  doLayout: (newBoundsForThisLayout) ->
    if !window.recalculatingLayouts
      debugger

    if @isCollapsed()
      @layoutIsValid = true
      @notifyChildrenThatParentHasReLayouted()
      return

    super

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
    labelBottom = labelTop + @label.height() + 2

    # tools -------------------------------

    toolButtonSize = new Point 93, 55
    eachPaneWidth = Math.floor(@width() - 3 * @padding - toolButtonSize.width())
    b = @bottom() - (2 * @padding) - WorldMorph.preferencesAndSettings.handleSize


    if @radioButtonsHolderMorph.parent == @
      @radioButtonsHolderMorph.fullRawMoveTo new Point @left() + @padding, labelBottom + @padding
      @radioButtonsHolderMorph.rawSetExtent new Point 2 * @padding + toolButtonSize.width(), b - (@label.bottom() + @padding)

    if @pencilToolButton.parent == @radioButtonsHolderMorph
      buttonBounds = new Rectangle new Point @radioButtonsHolderMorph.left() + @padding, labelBottom + 10
      buttonBounds = buttonBounds.setBoundsWidthAndHeight toolButtonSize
      @pencilToolButton.doLayout buttonBounds

    if @brushToolButton.parent == @radioButtonsHolderMorph
      buttonBounds = new Rectangle new Point @radioButtonsHolderMorph.left() + @padding, @pencilToolButton.bottom() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight toolButtonSize
      @brushToolButton.doLayout buttonBounds

    if @toothpasteToolButton.parent == @radioButtonsHolderMorph
      buttonBounds = new Rectangle new Point @radioButtonsHolderMorph.left() + @padding, @brushToolButton.bottom() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight toolButtonSize
      @toothpasteToolButton.doLayout buttonBounds

    if @eraserToolButton.parent == @radioButtonsHolderMorph
      buttonBounds = new Rectangle new Point @radioButtonsHolderMorph.left() + @padding, @toothpasteToolButton.bottom() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight toolButtonSize
      @eraserToolButton.doLayout buttonBounds 

    # mainCanvas --------------------------
    mainCanvasWidth = @width() - @radioButtonsHolderMorph.width() - 3*@padding
    b = @bottom() - (2 * @padding) - WorldMorph.preferencesAndSettings.handleSize
    mainCanvasHeight =  b - (@label.bottom() + @padding)
    mainCanvasBottom = labelBottom + mainCanvasHeight
    mainCanvasLeft = @radioButtonsHolderMorph.right() + @padding

    if @mainCanvas.parent == @
      @mainCanvas.fullRawMoveTo new Point mainCanvasLeft, labelBottom + @padding
      @mainCanvas.rawSetExtent new Point mainCanvasWidth, mainCanvasHeight

    # overlayCanvas ----------------------
    # has exact same size and position of the main canvas
    if @overlayCanvas.parent == @mainCanvas
      @overlayCanvas.fullRawMoveTo new Point mainCanvasLeft, labelBottom + @padding
      @overlayCanvas.rawSetExtent new Point mainCanvasWidth, mainCanvasHeight

    # ----------------------------------------------


    trackChanges.pop()
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()


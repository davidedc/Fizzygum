# The PAINT toolbar (Frame-model plan §5.D): the radio-tool palette that
# occupies an ImageWdgt's toolbar-slot (docked left), or floats like any
# toolbar. NOT a ToolbarWdgt subclass (owner decision D10): its items are
# stateful radio TOGGLES with editable-mark annotations, not drag-out creator
# thumbnails, so it keeps the proven RadioButtonsHolderWdgt construction and
# conforms to the frame slot's duck contract instead (dockSide / dockThickness /
# the collapse cores / _reLayout / excludedFromEditorFocusTracking).
#
# The tools inject their handler source into a painting overlay resolved at
# PRESS time (resolveInjectionTarget below) -- any paint toolbar can serve any
# image (owner decision D12: injection stays the arming mechanism in D-1; a
# world-level tool object is D-2's design space).

class PaintToolbarWdgt extends RadioButtonsHolderWdgt

  # the slot contract knobs (see ToolbarWdgt for their meaning). 103 =
  # 2 * internalPadding + button width 93 -- byte-what the retired in-content
  # tool column measured.
  dockSide: 'left'
  dockThickness: 103

  internalPadding: 5

  pencilToolButton: nil
  brushToolButton: nil
  toothpasteToolButton: nil
  eraserToolButton: nil
  highlightedToolIconColor: Color.create 245, 126, 0

  # whether the tools are armed on the resolved painting overlay. Born true:
  # ImageWdgt's payload is built with the pencil source injected (born
  # editing), and this toolbar is built showing pencil selected to match.
  _armed: true

  # disarming a selected tool injects this no-op (the same source the tools'
  # ON faces carry): view mode must not paint (§5.D D-i #4).
  @TOOL_OFF_SOURCE: "mouseMove = -> return"

  @PENCIL_TOOL_SOURCE: """
      mouseMove = (pos, mouseButton) ->
          if world.hand.isThisPointerDraggingSomething() then return
          context = @backBufferContext
          context.setTransform 1, 0, 0, 1, 0, 0
          context.clearRect 0, 0, @width() * ceilPixelRatio, @height() * ceilPixelRatio
          context.useLogicalPixelsUntilRestore()

          # give it a little bit of a tint so
          # you can see the canvas when you take it
          # apart from the paint tool.
          #context.fillStyle = (Color.create 0,255,0,0.5).toString()
          #context.fillRect 0, 0, @width(), @height()

          context.translate -@bounds.origin.x, -@bounds.origin.y
          context.translate pos.x, pos.y

          context.beginPath()
          context.lineWidth="2"

          if mouseButton == 'left'
              contextMain = @underlyingCanvasWdgt.getContextForPainting()
              contextMain.translate pos.x, pos.y

              contextMain.beginPath()
              contextMain.lineWidth="2"
              contextMain.fillStyle = Color.BLACK.toString()
              contextMain.rect(-2,-2,4,4)
              contextMain.fill()
              @underlyingCanvasWdgt.changed()

          else
              context.strokeStyle=Color.RED.toString()
              context.rect(-2,-2,4,4)
              context.stroke()
          @changed()
      """

  @BRUSH_TOOL_SOURCE: """
      mouseMove = (pos, mouseButton) ->
          if world.hand.isThisPointerDraggingSomething() then return
          context = @backBufferContext
          context.setTransform 1, 0, 0, 1, 0, 0
          context.clearRect 0, 0, @width() * ceilPixelRatio, @height() * ceilPixelRatio
          context.useLogicalPixelsUntilRestore()

          context.translate -@bounds.origin.x, -@bounds.origin.y
          context.translate pos.x, pos.y

          context.beginPath()
          context.lineWidth="2"

          if mouseButton == 'left'
              context.fillStyle = Color.RED.toString()

              contextMain = @underlyingCanvasWdgt.getContextForPainting()
              contextMain.translate pos.x, pos.y
              contextMain.fillStyle = Color.BLACK.toString()

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


              @underlyingCanvasWdgt.changed()

          else
              context.strokeStyle=Color.GREEN.toString()
          context.rect(-5,-5,10,10)
          context.stroke()
          @changed()
      """

  @TOOTHPASTE_TOOL_SOURCE: """
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

      mouseUpLeft = ->
          if world.hand.isThisPointerDraggingSomething() then return
          if @queue?
              # draining the queue
              contextMain = @underlyingCanvasWdgt.getContextForPainting()

              until @queue.length == 0
                  previousPos = @queue[0]
                  @queue.shift()
                  if previousPos?
                      contextMain.save()
                      contextMain.translate previousPos.x, previousPos.y
                      contextMain.fillStyle = Color.WHITE.toString()
                      @paintBrush contextMain
                      contextMain.restore()
              delete @queue

      mouseMove = (pos, mouseButton) ->
          if world.hand.isThisPointerDraggingSomething() then return
          context = @backBufferContext
          context.setTransform 1, 0, 0, 1, 0, 0
          context.clearRect 0, 0, @width() * ceilPixelRatio, @height() * ceilPixelRatio
          context.useLogicalPixelsUntilRestore()

          context.translate -@bounds.origin.x, -@bounds.origin.y
          context.translate pos.x, pos.y

          context.beginPath()
          context.lineWidth="2"

          if mouseButton == 'left'
              @initialiseQueueIfNeeded()
              @queue.push pos
              context.fillStyle = Color.RED.toString()

              contextMain = @underlyingCanvasWdgt.getContextForPainting()

              contextMain.save()
              contextMain.translate pos.x, pos.y
              contextMain.fillStyle = Color.BLACK.toString()
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
                  contextMain.fillStyle = Color.WHITE.toString()
                  @paintBrush contextMain
                  contextMain.restore()


              @underlyingCanvasWdgt.changed()

          else
              context.strokeStyle=Color.GREEN.toString()
          context.rect(-5,-5,10,10)
          context.stroke()
          @changed()
      """

  @ERASER_TOOL_SOURCE: """
      mouseMove = (pos, mouseButton) ->
          if world.hand.isThisPointerDraggingSomething() then return
          context = @backBufferContext
          context.setTransform 1, 0, 0, 1, 0, 0
          context.clearRect 0, 0, @width() * ceilPixelRatio, @height() * ceilPixelRatio
          context.useLogicalPixelsUntilRestore()

          context.translate -@bounds.origin.x, -@bounds.origin.y
          context.translate pos.x, pos.y

          context.beginPath()
          context.lineWidth="2"

          if mouseButton == 'left'
              context.fillStyle = Color.RED.toString()

              contextMain = @underlyingCanvasWdgt.getContextForPainting()
              contextMain.translate pos.x, pos.y

              contextMain.beginPath()
              contextMain.lineWidth="2"
              contextMain.fillStyle = Color.WHITE.toString()
              contextMain.rect(-5,-5,10,10)
              contextMain.fill()
              @underlyingCanvasWdgt.changed()

          else
              context.strokeStyle=Color.GREEN.toString()
          context.rect(-5,-5,10,10)
          context.stroke()
          @changed()
      """

  constructor: ->
    super()
    @_buildAndConnectChildren()

  # Clicking anywhere INSIDE the toolbar (buttons, their icon faces, the column
  # background, the edit-marks) must not steal the editor focus pointer from
  # the image being edited -- honored by ANCESTRY at the pointer's set sites
  # (ActivePointerWdgt._excludedFromEditorFocusTrackingByAncestry, §5.D: the top
  # widget at a tool click is the icon FACE, so a self-only check cannot cover
  # a subtree).
  excludedFromEditorFocusTracking: ->
    true

  # ===== press-time target resolution (§5.D D-ii 3, owner decision D11) =====
  # DOCKED: my parent is the frame whose content is the image -- act on THIS
  # image. FLOATING: my parent frame's content is me, so the frame's
  # paintingOverlay dispatch finds nothing -- fall to the FOCUSED widget.
  # Either leg resolves through the paintingOverlay() capability chain
  # (glass / canvas / container / frame); nil = nothing paintable, the press
  # is a visual-only radio flip (the text-toolbar no-op contract).
  resolveInjectionTarget: ->
    @parent?.paintingOverlay?() ? world.editorFocusWdgt?.paintingOverlay?()

  # ===== the frame's mode protocol (driven by FrameWdgt.showEdit/ViewModeInBar) =====
  # Transition-guarded on @_armed because the show*ModeInBar protocol is
  # idempotently re-driven (e.g. the edit-button recreate on window uncollapse
  # reflects the CURRENT mode) -- only a real mode TRANSITION may re-arm, or an
  # uncollapse would clobber a user-selected brush back to pencil.
  # ⚠ Neither hook may fire a button action: a toggle() escalation reaches
  # SwitchButtonWdgt's SELF-SETTLING mouseClickLeft inside the content's
  # enable/disable flush (the transitive-settle trap that forced the retired
  # editor's detach-then-teardown dance). Injection is settle-free and
  # setToggleState only flips the shown face.
  reactToEditModeInFrame: ->
    return if @_armed
    @_armed = true
    @resolveInjectionTarget()?.injectProperties PaintToolbarWdgt.PENCIL_TOOL_SOURCE
    for toggle in @_toolToggles()
      toggle.setToggleState (if toggle == @pencilToolButton then 1 else 0)
    return

  reactToViewModeInFrame: ->
    return if !@_armed
    @_armed = false
    @resolveInjectionTarget()?.injectProperties PaintToolbarWdgt.TOOL_OFF_SOURCE
    for toggle in @_toolToggles()
      toggle.setToggleState 0
    return

  _toolToggles: ->
    (each for each in [@pencilToolButton, @brushToolButton, @toothpasteToolButton, @eraserToolButton] when each?)

  isToolPressed: (buttonToCheckIfPressed) ->
    whichButtonIsSelected = @whichButtonSelected()
    if whichButtonIsSelected?
      if whichButtonIsSelected == buttonToCheckIfPressed.parent
        return true
      else
        return false
    return false

  # normally a button injects new code only when
  # is pressed, BUT here we make it so we inject new
  # code also if the tool is selected, without it to
  # be re-pressed. In order to do that, we
  # simply listen to a notification of new code being
  # available from a button, we check if it's selected
  # and in that case we tell the button to actually
  # inject the code.
  newCodeToInjectFromButton: (whichButtonHasNewCode) ->
    if @isToolPressed whichButtonHasNewCode
      whichButtonHasNewCode.injectCodeIntoTarget()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    pencilButtonOff = new CodeInjectingSimpleRectangularButtonWdgt @, new Pencil2IconWdgt
    pencilButtonOff.alpha = 0.1
    pencilButtonOff.sourceCodeToBeInjected = PaintToolbarWdgt.PENCIL_TOOL_SOURCE

    pencilButtonOn = new CodeInjectingSimpleRectangularButtonWdgt @, new Pencil2IconWdgt @highlightedToolIconColor
    pencilButtonOn.alpha = 0.1
    pencilButtonOn.sourceCodeToBeInjected = PaintToolbarWdgt.TOOL_OFF_SOURCE

    @pencilToolButton = new ToggleButtonWdgt pencilButtonOff, pencilButtonOn

    brushToolButtonOff = new CodeInjectingSimpleRectangularButtonWdgt @, new BrushIconWdgt
    brushToolButtonOff.alpha = 0.1
    brushToolButtonOff.sourceCodeToBeInjected = PaintToolbarWdgt.BRUSH_TOOL_SOURCE

    brushToolButtonOn = new CodeInjectingSimpleRectangularButtonWdgt @, new BrushIconWdgt @highlightedToolIconColor
    brushToolButtonOn.alpha = 0.1
    brushToolButtonOn.sourceCodeToBeInjected = PaintToolbarWdgt.TOOL_OFF_SOURCE

    @brushToolButton = new ToggleButtonWdgt brushToolButtonOff, brushToolButtonOn

    toothpasteToolButtonOff = new CodeInjectingSimpleRectangularButtonWdgt @, new ToothpasteIconWdgt
    toothpasteToolButtonOff.alpha = 0.1
    toothpasteToolButtonOff.sourceCodeToBeInjected = PaintToolbarWdgt.TOOTHPASTE_TOOL_SOURCE

    toothpasteToolButtonOn = new CodeInjectingSimpleRectangularButtonWdgt @, new ToothpasteIconWdgt @highlightedToolIconColor
    toothpasteToolButtonOn.alpha = 0.1
    toothpasteToolButtonOn.sourceCodeToBeInjected = PaintToolbarWdgt.TOOL_OFF_SOURCE

    @toothpasteToolButton = new ToggleButtonWdgt toothpasteToolButtonOff, toothpasteToolButtonOn

    eraserToolButtonOff = new CodeInjectingSimpleRectangularButtonWdgt @, new EraserIconWdgt
    eraserToolButtonOff.alpha = 0.1
    eraserToolButtonOff.sourceCodeToBeInjected = PaintToolbarWdgt.ERASER_TOOL_SOURCE

    eraserToolButtonOn = new CodeInjectingSimpleRectangularButtonWdgt @, new EraserIconWdgt @highlightedToolIconColor
    eraserToolButtonOn.alpha = 0.1
    eraserToolButtonOn.sourceCodeToBeInjected = PaintToolbarWdgt.TOOL_OFF_SOURCE

    @eraserToolButton = new ToggleButtonWdgt eraserToolButtonOff, eraserToolButtonOn

    # pencilAnnotation
    new EditableMarkWdgt @pencilToolButton, pencilButtonOff, "editInjectableSource"
    # brushAnnotation
    new EditableMarkWdgt @brushToolButton, brushToolButtonOff, "editInjectableSource"
    # toothpasteAnnotation
    new EditableMarkWdgt @toothpasteToolButton, toothpasteToolButtonOff, "editInjectableSource"
    # eraserAnnotation
    new EditableMarkWdgt @eraserToolButton, eraserToolButtonOff, "editInjectableSource"

    @_addNoSettle @pencilToolButton
    @_addNoSettle @brushToolButton
    @_addNoSettle @toothpasteToolButton
    @_addNoSettle @eraserToolButton

    # shown selected to match the born-armed payload (ImageWdgt injects the
    # pencil source at build) -- a DISPLAY write, no action fires, so there is
    # no settle to defer and no attach-last dance.
    @pencilToolButton.setToggleState 1
    @_invalidateLayout()

  # ===== the slot's synchronous chrome drive (the FrameBarWdgt pattern) =====

  _reLayoutChildren: ->
    @_positionAndResizeChildren()

  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()

  # Pinned false, NOT derived: defining _reLayout above would flip the derived
  # answer and mis-route its read sites -- the same pin the frame, the stack
  # and the bar carry.
  implementsDeferredLayout: ->
    false

  _positionAndResizeChildren: ->
    buttonSize = new Point 93, 55
    buttonTop = @top() + @internalPadding
    for button in @_toolToggles()
      if button.parent == @
        buttonBounds = new Rectangle new Point @left() + @internalPadding, buttonTop
        buttonBounds = buttonBounds.setBoundsWidthAndHeight buttonSize
        button._reLayout buttonBounds
        buttonTop = button.bottom() + @internalPadding
    return

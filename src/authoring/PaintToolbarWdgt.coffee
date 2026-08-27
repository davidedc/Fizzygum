# The PAINT palette (Frame-model plan §5.D): the tool strip that occupies an ImageWdgt's
# toolbar-slot (docked left), or floats like any toolbar. It is the PALETTE VARIANT of the ONE
# toolbar construction -- four commands (pencil / brush / toothpaste / eraser) in the shared tool
# grid, each cell holding a tool that carries its own injectable source and answers its own tap.
# What makes it a palette rather than a rack of drag-out thumbnails is SELECTION -- and the tool
# chosen is not MINE. It is the PERSON's: `world.user.armedDrawingTool` (User), because I am a
# destination-generic instrument that serves whichever image is in reach, so a hand holding a
# pencil holds it for every drawing at once. I am therefore a VIEW of that fact (my highlight
# derives from it, and I re-read it whenever it announces) and a CONTROLLER over it (a tap on one
# of my cells arms that tool on the user). See CommandSpec for the dispatch law both projections
# of a command obey.
#
# The tools inject their handler source into a painting overlay resolved when the selection moves
# (resolveInjectionTarget below) -- any paint toolbar can serve any image (owner decision D12:
# injection stays the arming mechanism in D-1; a world-level tool object is D-2's design space).
#
# Clicking anywhere in here -- a tool, its icon, an edit mark, the grid between them -- must not
# steal the editor focus pointer from the image being edited. ToolbarWdgt declares that exclusion
# for the whole strip, and it is honored by ANCESTRY at the pointer's set sites
# (ActivePointerWdgt._excludedFromEditorFocusTrackingByAncestry, §5.D: the top widget at a tool
# click is the icon FACE, so a self-only check could not cover the subtree).

class PaintToolbarWdgt extends ToolbarWdgt

  # my four commands. Each holds the source its command injects; my strip's depth is no constant of
  # mine at all -- ToolbarWdgt derives it from the grid's own cell metrics, like every other strip.
  pencilTool: undefined
  brushTool: undefined
  toothpasteTool: undefined
  eraserTool: undefined

  highlightedToolIconColor: Color.create 245, 126, 0

  # rolling buffer of recent pointer positions, built lazily on first use and drained
  # as the stroke is laid down. Declared undefined, never [] — the lazy build keys off
  # `if !@queue?`, and a prototype array would be shared by every instance.
  queue: undefined

  # whether MY frame is in edit mode, i.e. whether the person's tool reaches my painting surface
  # at all. Born true: a drawing is born editable, its payload built with the pencil source
  # already injected -- the same statement the User makes by being born holding a pencil.
  _armed: true

  # HOW A TOOL SOURCE IS SHAPED. A drawing surface is one of the few widgets with business on BOTH
  # pointer-move channels, so every tool below injects both and routes them into one body: a HOVER
  # move shows where the tool would land, and a PRESSED move carries the button as a fact — the
  # primary button lays paint down, any other previews exactly as a hover does. One body means the
  # two channels cannot drift, and it is the body a person opens when they edit the tool.
  #
  # what an unchosen palette injects: a no-op, because view mode must not paint, and neither must
  # a strip whose chosen tool was pressed a second time (§5.D D-i #4).
  @TOOL_OFF_SOURCE: "hoverMoved = -> return\npressMoved = -> return"

  @PENCIL_TOOL_SOURCE: """
      hoverMoved = (pos) ->
          @applyToolAt pos

      pressMoved = (pos, mouseButton) ->
          @applyToolAt pos, mouseButton

      applyToolAt = (pos, mouseButton) ->
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

          else
              context.strokeStyle=Color.RED.toString()
              context.rect(-2,-2,4,4)
              context.stroke()
          @_changed()
      """

  @BRUSH_TOOL_SOURCE: """
      hoverMoved = (pos) ->
          @applyToolAt pos

      pressMoved = (pos, mouseButton) ->
          @applyToolAt pos, mouseButton

      applyToolAt = (pos, mouseButton) ->
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

          else
              context.strokeStyle=Color.GREEN.toString()
          context.rect(-5,-5,10,10)
          context.stroke()
          @_changed()
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
              @queue = [0..24].map -> undefined

      pressEnded = ->
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

      hoverMoved = (pos) ->
          @applyToolAt pos

      pressMoved = (pos, mouseButton) ->
          @applyToolAt pos, mouseButton

      applyToolAt = (pos, mouseButton) ->
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

          else
              context.strokeStyle=Color.GREEN.toString()
          context.rect(-5,-5,10,10)
          context.stroke()
          @_changed()
      """

  @ERASER_TOOL_SOURCE: """
      hoverMoved = (pos) ->
          @applyToolAt pos

      pressMoved = (pos, mouseButton) ->
          @applyToolAt pos, mouseButton

      applyToolAt = (pos, mouseButton) ->
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

          else
              context.strokeStyle=Color.GREEN.toString()
          context.rect(-5,-5,10,10)
          context.stroke()
          @_changed()
      """

  # My four commands, in strip order. Each tool acts on its own press, so the grid wraps it bare --
  # no glass lid over it -- and a tap on the cell reaches the tool itself, which is what the
  # dispatch law asks of a cell (CommandSpec's header). The EDIT MARK rides the tool: the triangle
  # in the tool's own top-right corner opens that command's source for editing.
  _toolbarItems: ->
    @pencilTool = new CodeInjectingSimpleRectangularButtonWdgt @, new Pencil2IconWdgt, 'pencil'
    @brushTool = new CodeInjectingSimpleRectangularButtonWdgt @, new BrushIconWdgt, 'brush'
    @toothpasteTool = new CodeInjectingSimpleRectangularButtonWdgt @, new ToothpasteIconWdgt, 'toothpaste'
    @eraserTool = new CodeInjectingSimpleRectangularButtonWdgt @, new EraserIconWdgt, 'eraser'

    for tool in @_tools()
      tool.sourceCodeToBeInjected = PaintToolbarWdgt.sourceForToolKey tool.drawingToolKey
      new EditableMarkWdgt tool, tool, "editInjectableSource"

    @_tools()

  # WHAT A TOOL KEY MEANS, stated once and read twice: my cells take their editable copy from here
  # at build, and a drawing asks it what to be born painting (ImageWdgt._makeStartingPayload). The
  # person's hand speaks in KEYS (User.armedDrawingTool), so this is where a key becomes behaviour;
  # a key naming no tool of mine means nothing paints.
  @sourceForToolKey: (toolKey) ->
    switch toolKey
      when 'pencil' then PaintToolbarWdgt.PENCIL_TOOL_SOURCE
      when 'brush' then PaintToolbarWdgt.BRUSH_TOOL_SOURCE
      when 'toothpaste' then PaintToolbarWdgt.TOOTHPASTE_TOOL_SOURCE
      when 'eraser' then PaintToolbarWdgt.ERASER_TOOL_SOURCE
      else PaintToolbarWdgt.TOOL_OFF_SOURCE

  # ONE edge user -> me, waking me whenever the person's hand changes by ANY route: a tap on THIS
  # palette, a tap on the one docked in another drawing, a restored snapshot. firesOnAnyChange
  # because what I show is not the user's VALUE -- a person has no single value -- so
  # markNonValueChange has to reach me; I never read what is delivered, I re-read the user.
  # The reflecting menu row's own seam, one level up (MenuItemWdgt._subscribeToMyReflectedSource).
  #   Lifecycle needs nothing at MY end: Widget._destroyNoSettle calls removeAllEdgesOf, so a
  # destroyed palette drops itself out of the user's out-set as it dies.
  _buildAndConnectChildrenNoSettle: ->
    super
    @_subscribeToTheArmedDrawingTool()

  _subscribeToTheArmedDrawingTool: ->
    return unless world?.user?
    world.dataflow.addEdge world.user, @, action: "applyArmedDrawingTool", firesOnAnyChange: true
    return

  # A palette arriving any way OTHER than construction still has to watch the same hand: neither a
  # deserialized shell nor a duplicate runs a constructor, so each re-makes its one edge here.
  _afterDeserialization: ->
    @_subscribeToTheArmedDrawingTool()

  _reactToBeingCopied: ->
    @_subscribeToTheArmedDrawingTool()

  # ===== target resolution (§5.D D-ii 3, owner decision D11) =====
  # DOCKED: my parent is the band frame holding me, and a band answers with its HOST's surface --
  # act on THAT image, whether or not anything has been clicked yet. FLOATING: my frame is docked
  # in nothing and its content is me, so it answers undefined -- fall to the FOCUSED widget, which
  # is the only thing that says which image a loose palette is aimed at.
  # Either leg resolves through the paintingOverlay() capability chain
  # (glass / canvas / container / frame); undefined = nothing paintable, and arming is then a
  # visual-only change of which tool the strip shows chosen (the text-toolbar no-op contract).
  resolveInjectionTarget: ->
    @parent?.paintingOverlay?() ? world.editorFocusWdgt?.paintingOverlay?()

  # ===== the frame's mode protocol (driven by FrameWdgt.showEdit/ViewModeInBar) =====
  # @_armed records WHETHER MY FRAME IS IN EDIT MODE, which is my half of what gets injected into
  # my surface (the person's hand is the other half). Transition-guarded because the
  # show*ModeInBar protocol is idempotently re-driven (e.g. the edit-button recreate on window
  # uncollapse reflects the CURRENT mode): only a real mode TRANSITION re-injects.
  # ⚠ Neither hook may fire a button action OR a settling setter: they run inside the content's
  # enable/disable flush (the transitive-settle trap that forced the retired editor's
  # detach-then-teardown dance), where a self-settling public setter re-enters the flush guard.
  # Injection is settle-free, and so is the re-drive below.
  #   Neither hook touches the USER'S hand, and that is the point of the split: my frame's mode
  # says whether THIS drawing may be painted on, never what the person is holding. So a drawing
  # put in view mode stops taking paint while the pencil stays in hand for every other drawing,
  # and putting it back in edit mode re-arms whatever the person is holding by then.
  reactToEditModeInFrame: ->
    return if @_armed
    @_armed = true
    @_armSelectedTool()
    return

  reactToViewModeInFrame: ->
    return if !@_armed
    @_armed = false
    @_armSelectedTool()
    return

  # ===== the person's hand: I am its VIEW, and its CONTROLLER =====

  # A tap on a cell reaches the tool (the dispatch law) and the tool tells me, handing itself in
  # the dispatch's first slot -- the one thing the press knows that I do not. I turn it into the
  # person's KEY and state the result on the user. THE SECOND TAP'S MEANING IS MINE: tapping the
  # tool already in hand puts it DOWN, which is a fact about the GESTURE -- the model verb only
  # states what is held (User.armDrawingTool), so nothing that merely re-states a hand, a restored
  # snapshot included, can be mistaken for a second tap.
  #   No settle here: what the write produces is an ANNOUNCEMENT, and the cycle's dataflow drain
  # applies it -- to me and to every other palette -- inside its own.
  selectTool: (whichTool) ->
    tappedKey = whichTool.drawingToolKey
    world.user.armDrawingTool (if tappedKey is world.user.armedDrawingTool then undefined else tappedKey)

  # The user's hand moved. Re-read it: the highlight re-derives at my next arrange, and my own
  # surface gets whatever the hand now holds. Every open palette hears the same announcement,
  # which is what makes arming a pencil anywhere arm it everywhere.
  applyArmedDrawingTool: ->
    @_armSelectedTool()
    return

  # Put the armed tool's handlers on MY painting surface; an empty hand -- or a frame in view mode
  # -- means nothing paints here. undefined target = nothing paintable in reach, and the change is
  # then a visual-only one (the text-toolbar no-op contract).
  _armSelectedTool: ->
    @resolveInjectionTarget()?.injectProperties @_sourceOfSelectedTool()
    @_invalidateLayout()
    return

  # Each tool carries its own command's source. With an empty hand the surface gets the no-op, and
  # so it does while my frame is in view mode -- the mode is MINE, the hand is the person's.
  _sourceOfSelectedTool: ->
    return PaintToolbarWdgt.TOOL_OFF_SOURCE unless @_armed
    @_armedTool()?.sourceCodeToBeInjected ? PaintToolbarWdgt.TOOL_OFF_SOURCE

  # WHICH OF MY CELLS the person's hand names -- looked up FROM the key, never stored: my cells
  # come and go with me and the hand outlives them all.
  _armedTool: ->
    armedKey = world?.user?.armedDrawingTool
    return undefined unless armedKey?
    for each in @_tools()
      return each if each.drawingToolKey is armedKey
    undefined

  _tools: ->
    (each for each in [@pencilTool, @brushTool, @toothpasteTool, @eraserTool] when each?)

  # The highlight is a VIEW of the person's hand, re-derived at every arrange (the
  # _deriveRowSeparators idiom, ruling C5): the armed tool's icon wears the highlight colour and
  # every other wears the icon default. No cell stores "am I the armed one", so no cell can
  # disagree with the hand.
  _deriveToolHighlights: ->
    armedTool = @_armedTool()
    for tool in @_tools()
      tool.faceWidget.setColor (if tool is armedTool then @highlightedToolIconColor else WorldWdgt.preferencesAndSettings.iconDarkLineColor)
    return

  _reLayoutChildren: ->
    @_deriveToolHighlights()
    super

  # Unlike a normal button, which injects code only when pressed, the ARMED tool must pick up
  # newly edited source immediately, without being re-pressed: the tool notifies me of new code,
  # and I forward the injection only when it is the one in the person's hand.
  newCodeToInjectFromButton: (whichToolHasNewCode) ->
    if whichToolHasNewCode is @_armedTool()
      whichToolHasNewCode.injectCodeIntoTarget()

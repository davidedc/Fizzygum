# The PAINT palette (Frame-model plan §5.D): the tool strip that occupies an ImageWdgt's
# toolbar-slot (docked left), or floats like any toolbar. It is the PALETTE VARIANT of the ONE
# toolbar construction -- four commands (pencil / brush / toothpaste / eraser) in the shared tool
# grid, each cell holding a tool that answers its own tap. What makes it a palette rather than a rack
# of drag-out thumbnails is SELECTION -- and the tool chosen is not MINE. It is my HOLDER's: the
# window whose edge slot I occupy while I am docked (its FrameWdgt.armedDrawingTool), the person
# while I float (world.user.armedDrawingTool, User) -- the one question every toolbar answers, who I
# work for (ToolbarWdgt.hostWindow). Each of my tools asks it itself, so I am only where the tools
# stand: a tap on one sets that tool on the holder, and each cell shows whether its tool is the one
# the holder holds. See CommandSpec for the dispatch law both projections of a command obey.
#
# Nothing of mine reaches a drawing. A paint surface takes its tool up when it is USED
# (CanvasGlassTopWdgt.hoverMoved / pressMoved), from its own nearest holder, and reads what a tool key
# means from me (sourceForToolKey): the person's edit of that tool, else my stock source.
#
# Clicking anywhere in here -- a tool, its icon, an edit mark, the grid between them -- must not
# steal the editor focus pointer from the image being edited. ToolbarWdgt declares that exclusion
# for the whole strip, and it is honored by ANCESTRY at the pointer's set sites
# (ActivePointerWdgt._excludedFromEditorFocusTrackingByAncestry, §5.D: the top widget at a tool
# click is the icon FACE, so a self-only check could not cover the subtree).

class PaintToolbarWdgt extends ToolbarWdgt

  # my four commands. Each is named by its key (drawingToolKey); my strip's depth is no constant of
  # mine at all -- ToolbarWdgt derives it from the grid's own cell metrics, like every other strip.
  pencilTool: undefined
  brushTool: undefined
  toothpasteTool: undefined
  eraserTool: undefined

  # HOW A TOOL SOURCE IS SHAPED. A source is a blurb of `name = value` assignments the paint surface
  # carries as its own instance members while it holds that tool: `applyToolAt`, the one body a
  # person opens when they edit the tool, and any helpers it calls (the toothpaste's paintBrush, its
  # queue's initialiser and the pressEnded that drains it). The surface owns the two pointer-move
  # entries and routes both into applyToolAt (CanvasGlassTopWdgt.hoverMoved / pressMoved), with @
  # bound to the surface: a HOVER move shows where the tool would land, and a PRESSED move carries
  # the button as a fact -- the primary button lays paint down, any other previews exactly as a hover
  # does. So a source never assigns either entry (the save of a tool's code refuses one that does:
  # CanvasGlassTopWdgt.refuseToolCodeAssigningMyEntries), and "no tool" is simply no tool members.

  @PENCIL_TOOL_SOURCE: """
      applyToolAt = (pos, mouseButton) ->
          if world.hand.isThisPointerDraggingSomething() then return
          context = @backBuffer.canvasContext
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
      applyToolAt = (pos, mouseButton) ->
          if world.hand.isThisPointerDraggingSomething() then return
          context = @backBuffer.canvasContext
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

      applyToolAt = (pos, mouseButton) ->
          if world.hand.isThisPointerDraggingSomething() then return
          context = @backBuffer.canvasContext
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
      applyToolAt = (pos, mouseButton) ->
          if world.hand.isThisPointerDraggingSomething() then return
          context = @backBuffer.canvasContext
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
  #   Each face is built in the toolbar glyph ink, the ink of every toolbar's glyphs (a creator
  # button or a text tool takes it in its createAppearance), where an icon built without a colour
  # would take the plain icon ink (IconWdgt).
  _toolbarItems: ->
    glyphInk = WorldWdgt.theme.toolbarGlyph
    @pencilTool = new CodeInjectingSimpleRectangularButtonWdgt (new Pencil2IconWdgt glyphInk), 'pencil'
    @brushTool = new CodeInjectingSimpleRectangularButtonWdgt (new BrushIconWdgt glyphInk), 'brush'
    @toothpasteTool = new CodeInjectingSimpleRectangularButtonWdgt (new ToothpasteIconWdgt glyphInk), 'toothpaste'
    @eraserTool = new CodeInjectingSimpleRectangularButtonWdgt (new EraserIconWdgt glyphInk), 'eraser'

    for tool in @_tools()
      new EditableMarkWdgt tool, tool, "editInjectableSource"

    @_tools()

  # WHAT A TOOL KEY MEANS NOW: the person's edit of that tool (User.drawingToolOverrideFor: there is
  # ONE table of edited tool code, the person's, whichever cell's edit mark wrote it), else my stock
  # source. Holders speak in KEYS (User and FrameWdgt armedDrawingTool), so this is where a key
  # becomes behaviour, read at each use by the paint surface (CanvasGlassTopWdgt._sourceOfToolInReach)
  # and by a tool's edit mark, which opens the source it means now. A key naming no tool of mine
  # means nothing (undefined): nothing paints.
  @sourceForToolKey: (toolKey) ->
    world.user.drawingToolOverrideFor(toolKey) ? PaintToolbarWdgt.stockSourceForToolKey toolKey

  # THE STOCK TOOLS: what each key means while the person has not edited it. A key naming no tool of
  # mine answers undefined.
  @stockSourceForToolKey: (toolKey) ->
    switch toolKey
      when 'pencil' then PaintToolbarWdgt.PENCIL_TOOL_SOURCE
      when 'brush' then PaintToolbarWdgt.BRUSH_TOOL_SOURCE
      when 'toothpaste' then PaintToolbarWdgt.TOOTHPASTE_TOOL_SOURCE
      when 'eraser' then PaintToolbarWdgt.ERASER_TOOL_SOURCE
      else undefined

  # ONE edge user -> me, waking me whenever the person's hand changes by ANY route: a tap on a
  # floating palette, a palette leaving a window, a restored snapshot (and when the person edits a
  # tool's code, User.overrideDrawingTool, which moves no highlight). firesOnAnyChange because what
  # I show is not the user's VALUE -- a person has no single value -- so markNonValueChange has to
  # reach me; I never read what is delivered, my cells re-read their holder (noteToolHolderChanged).
  # While I am docked my holder is my host window, which tells me itself when its tool changes
  # (FrameWdgt.armDrawingTool), so then the hand's announcement only re-reads what has not moved.
  # The reflecting menu row's own seam, one level up (MenuItemWdgt._subscribeToMyReflectedSource).
  #   Lifecycle needs nothing at MY end: Widget._destroyNoSettle calls removeAllEdgesOf, so a
  # destroyed palette drops itself out of the user's out-set as it dies.
  _buildAndConnectChildrenNoSettle: ->
    super
    @_subscribeToTheArmedDrawingTool()

  _subscribeToTheArmedDrawingTool: ->
    return unless world?.user?
    world.dataflow.addEdge world.user, @, action: "noteToolHolderChanged", firesOnAnyChange: true
    return

  # A palette arriving any way OTHER than construction still has to watch the same hand: neither a
  # deserialized shell nor a duplicate runs a constructor, so each re-makes its one edge here.
  _afterDeserialization: ->
    super
    @_subscribeToTheArmedDrawingTool()

  _reactToBeingCopied: ->
    super
    @_subscribeToTheArmedDrawingTool()

  # my tools, in strip order
  _tools: ->
    (each for each in [@pencilTool, @brushTool, @toothpasteTool, @eraserTool] when each?)

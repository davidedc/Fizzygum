# this file is excluded from the fizzygum homepage build

# Fizzytiles' 3D output pane. Each frame it RUNS the LiveCodeLang program that
# the tiles (or the code editor) compiled to, and software-renders it through
# SW3D — the SWCanvas Core software-3D engine (DepthBuffer + Triangle3DOps) —
# with NO WebGL and NO twgl. A box tile draws a lit, z-buffered cube; scale /
# rotate / move nest transforms around it. The render fills an RGBA SWCanvas
# Surface, which is blitted onto this CanvasWdgt's physical-pixel back-buffer.
#
# Determinism: the animation clock is EVENT time under the Automator (so the
# suite's screenshots are a pure function of the event stream) and wall time
# when live. See @timeNowSeconds / DETERMINISM.md.
#
# "container"/"contained" scenario going on.

class FridgeMagnets3DCanvasWdgt extends CanvasWdgt

  # LCL compiler + the current/previous compiled program. The empty prototype
  # graphicsCode below is replaced per-instance by newGraphicsCode once tiles
  # or edited code compile.
  lclCodeCompiler: nil
  transforms: nil

  # SW3D runtime, all rebuilt lazily by @_ensureEngine / @_ensureRuntime (see
  # @serializationTransients): a duplicated or restored pane carries none of
  # these and rebuilds them on its next render.
  surface: nil
  depth: nil
  engine: nil
  imageData: nil
  meshCache: nil

  # current LCL draw state (plain [r,g,b])
  currentFillRGB: nil
  backgroundRGB: nil
  defaultFillRGB: [231, 76, 60]         # cubes-demo red
  defaultBackgroundRGB: [230, 230, 230] # light gray

  # Runtime scratch that must never be serialized (Surfaces, typed-array depth
  # buffers, the SW3D engine, cached meshes, the matrix stack, and the compiled
  # program Functions). Rebuilt on first render after restore/duplication.
  @serializationTransients: [
    "surface"
    "depth"
    "engine"
    "imageData"
    "meshCache"
    "transforms"
    "lclCodeCompiler"
    "graphicsCode"
    "oldGraphicsCode"
  ]

  oldGraphicsCode: ->

  graphicsCode: ->

  newGraphicsCode: (newCode) ->
    @_ensureRuntime()
    @oldGraphicsCode = @graphicsCode
    # Coffeescript v2 is used
    compilation = @lclCodeCompiler.compileCode newCode
    if compilation.program?
      @graphicsCode = compilation.program

  constructor: ->
    super
    @_ensureRuntime()
    world.steppingWdgts.add @

  # (re)build the non-serialized runtime helpers if this pane was just built,
  # restored, or duplicated.
  _ensureRuntime: ->
    @transforms ?= @_markTransient new LCLTransforms @
    @meshCache ?= @_markTransient {}
    @lclCodeCompiler ?= @_markTransient new LCLCodeCompiler
    @currentFillRGB ?= @defaultFillRGB
    @backgroundRGB ?= @defaultBackgroundRGB

  # The deep-copier (window duplication) and the file Serializer both DROP a
  # property whose value carries a rebuildDerivedValue method (same idiom canvas
  # contexts use), rather than trying to clone the Surface / typed-array / engine
  # and crashing. Stamp that no-op onto each runtime object so the clone gets nil
  # and rebuilds it lazily on its next render (@_ensureRuntime / @_ensureEngine).
  # Belt-and-suspenders with @serializationTransients, which also covers the
  # compiled-program Functions the Serializer can't emit.
  _transientRebuild: -> # intentionally empty — the widget rebuilds it lazily

  _markTransient: (obj) ->
    if obj? then obj.rebuildDerivedValue ?= @_transientRebuild
    obj

  step: ->
    @_renderScene()
    @_changed()

  # Animation clock: event time under the Automator (deterministic screenshots),
  # wall clock when live (smooth animation). Mirrors the multi-click event-time
  # precedent (WorldWdgt.timeOfEventBeingProcessed) — see DETERMINISM.md.
  timeNowSeconds: ->
    if Automator? and Automator.state != Automator.IDLE
      (WorldWdgt.timeOfEventBeingProcessed ? 0) / 1000
    else
      Date.now() / 1000

  # ---- SW3D lifecycle -------------------------------------------------------

  # Build (or rebuild on resize) the Surface / DepthBuffer / engine / ImageData
  # at the pane's PHYSICAL pixel size. Sized to the back-buffer's own dimensions
  # (already physical integers) so the putImageData blit maps 1:1.
  _ensureEngine: ->
    physW = @backBuffer.width
    physH = @backBuffer.height
    return if @surface? and @surface.width == physW and @surface.height == physH
    @surface = @_markTransient window.SWCanvas.Core.Surface physW, physH
    @depth = @_markTransient new window.SWCanvas.Core.DepthBuffer physW, physH
    # ImageData is a live view onto surface.data — re-create it whenever the
    # surface is rebuilt, never cache it across a resize.
    @imageData = @_markTransient new ImageData @surface.data, physW, physH
    @engine = @_markTransient window.SW3D.makeEngine window.SWCanvas, {width: physW, height: physH}
    # Camera fixed: a unit box at the origin is ~22% of the pane height with
    # SW3D's default focal (height * 1.1).
    @engine.setCamera [0, 0, -5], 0

  # SW3D bakes the face color into the mesh, so cache one mesh per
  # (primitive, fill-rgb). Tile scenes use a handful of colors at most.
  _meshFor: (kind) ->
    key = kind + ":" + @currentFillRGB.join(",")
    @meshCache[key] ?=
      if kind == "ball"
        window.SW3D.makeSphereMesh 0.5, 16, 10, @currentFillRGB
      else
        window.SW3D.makeBoxMesh 1, @currentFillRGB
    @meshCache[key]

  _renderScene: ->
    return unless @extent().x > 0 and @extent().y > 0
    @_ensureRuntime()
    if !@backBuffer? then @_createRefreshOrGetBackBuffer()
    @_ensureEngine()

    # Per-frame reset: fill state + a fresh matrix stack. backgroundRGB persists
    # across frames (the clear below uses it), so a `background` call this frame
    # takes effect on the next clear — the program re-runs every frame anyway.
    @currentFillRGB = @defaultFillRGB
    @transforms.resetMatrixStack()

    @surface.data32.fill @engine.packColor @backgroundRGB[0], @backgroundRGB[1], @backgroundRGB[2]
    @depth.clear()

    # Run the tiles' program with this = the widget, every command @-bound to a
    # method below. On a runtime error, roll back to the last good program
    # (same shape as the 2D reference widget).
    try
      @graphicsCode()
    catch error
      @graphicsCode = @oldGraphicsCode

    # Blit the physical RGBA surface onto the (physical) back-buffer: identity
    # transform for the raw pixels, then restore logical-pixel scaling. ALWAYS
    # leave the context with the correct pixel scaling.
    @backBufferContext.setTransform 1, 0, 0, 1, 0, 0
    @backBufferContext.putImageData @imageData, 0, 0
    @backBufferContext.useLogicalPixelsUntilRestore()

  # ---- LCL primitives -------------------------------------------------------

  box: (a, b, c, d) -> @_drawMesh "box", a, b, c, d
  ball: (a, b, c, d) -> @_drawMesh "ball", a, b, c, d

  # Draw one mesh with (worldMatrix x local-scale(a,b,c)) — the local scale is
  # NOT persisted into the matrix stack. Argument normalization matches the LCL
  # convention (missing sizes default; a trailing function is the block).
  _drawMesh: (kind, a, b, c, d) ->
    appendedFunction = undefined
    if typeof a isnt "number"
      if Utils.isFunction a then appendedFunction = a
      a = 1
      b = 1
      c = 1
    else if typeof b isnt "number"
      if Utils.isFunction b then appendedFunction = b
      b = a
      c = a
    else if typeof c isnt "number"
      if Utils.isFunction c then appendedFunction = c
      c = 1
    else if Utils.isFunction d
      appendedFunction = d

    if @surface? and @engine?
      mesh = @_meshFor kind
      # column-major m = worldMatrix . diag(a,b,c); split into SW3D's row-major
      # 3x3 linear part and the world-space translation.
      m = @transforms.scaleMatrix @transforms.worldMatrix, [a, b, c]
      linear9 = [m[0], m[4], m[8], m[1], m[5], m[9], m[2], m[6], m[10]]
      translation = [m[12], m[13], m[14]]
      @engine.drawMesh @surface, @depth, mesh, translation, linear9

    appendedFunction.apply @ if appendedFunction?
    # Return TRUTHY. When a primitive is a qualifying command's scoped block
    # (e.g. `rotate box` -> rotate(this.box)), LCLTransforms pops its matrix only
    # if the block returns non-null; a null/undefined return is the LCL "fake
    # function" signal (a conditional that drew nothing) which instead DISCARDS
    # the push so the transform PERSISTS. A real primitive always drew, so it
    # must return truthy — else `rotate box` would leak its rotation onto every
    # later shape (the second box in `rotate box` / `box` would rotate too).
    true

  # ---- transform commands: delegate to the matrix stack ---------------------
  # (LCLTransforms owns the appended-function block semantics; it applies each
  # block with this = the widget, so @box() etc. inside a block resolve here.)

  scale: -> @transforms.scale.apply @transforms, arguments
  rotate: -> @transforms.rotate.apply @transforms, arguments
  move: -> @transforms.move.apply @transforms, arguments
  pushMatrix: -> @transforms.pushMatrix()
  popMatrix: -> @transforms.popMatrix()
  resetMatrix: -> @transforms.resetMatrix()

  # ---- color / background ---------------------------------------------------

  fill: ->
    args = arguments
    a = args[0]
    newColor = nil
    if typeof a is "number" and typeof args[1] is "number" and typeof args[2] is "number"
      newColor = [a, args[1], args[2]]
    else if a? and a.r? and a.g? and a.b?
      newColor = [a.r, a.g, a.b]
    # A trailing function is the scoped block: the fill then applies ONLY inside
    # it (save the colour, set it, run the block, restore) — the colour analogue
    # of the matrix commands' push/pop. With no block the fill is global (it
    # persists to the following shapes). This scopes `fill red box` to the box.
    hasBlock = false
    for arg in args when Utils.isFunction arg
      hasBlock = true
    if hasBlock
      saved = @currentFillRGB
      @currentFillRGB = newColor if newColor?
      @_passBlock args
      @currentFillRGB = saved
    else
      @currentFillRGB = newColor if newColor?
    true

  background: ->
    a = arguments[0]
    if typeof a is "number" and typeof arguments[1] is "number" and typeof arguments[2] is "number"
      @backgroundRGB = [a, arguments[1], arguments[2]]
    else if a? and a.r? and a.g? and a.b?
      @backgroundRGB = [a.r, a.g, a.b]
    @_passBlock arguments

  # ---- run (port of LCLProgramRunner.run) -----------------------------------
  run: (functionToBeRun, chainedFunction) ->
    functionToBeRun.apply @ if Utils.isFunction functionToBeRun
    chainedFunction.apply @ if Utils.isFunction chainedFunction
    true

  # ---- v1 no-op commands ----------------------------------------------------
  # Every LCL command that the preprocessor @-binds must EXIST as a method here
  # or the compiled program throws. These are not implemented in v1 but still
  # run any appended-function block, so `command <newline> box` isn't swallowed.
  _passBlock: (args) ->
    for arg in args when Utils.isFunction arg
      arg.apply @
    # truthy for the same nested-closure reason as _drawMesh (so a no-op used as
    # `rotate line` scopes rather than leaks the transform)
    true

  # noOpLCLCommand (deferred): drawing styles / lighting / sound / server
  stroke: -> @_passBlock arguments
  noStroke: -> @_passBlock arguments
  noFill: -> @_passBlock arguments
  strokeSize: -> @_passBlock arguments
  lights: -> @_passBlock arguments
  noLights: -> @_passBlock arguments
  ambientLight: -> @_passBlock arguments
  pointLight: -> @_passBlock arguments
  ballDetail: -> @_passBlock arguments
  animationStyle: -> @_passBlock arguments
  colorMode: -> @_passBlock arguments
  simpleGradient: -> @_passBlock arguments
  bpm: -> @_passBlock arguments
  play: -> @_passBlock arguments
  connect: -> @_passBlock arguments
  # noOpLCLCommand (deferred primitives — no SW3D line/quad-strip yet)
  line: -> @_passBlock arguments
  rect: -> @_passBlock arguments
  peg: -> @_passBlock arguments

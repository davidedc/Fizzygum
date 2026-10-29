class CanvasGlassTopWdgt extends CanvasWdgt

  underlyingCanvasWdgt: undefined
  defaultRejectDrags: true

  # the TOOTHPASTE tool's rolling buffer of recent pointer positions: the tool's handlers
  # (PaintToolbarWdgt.TOOTHPASTE_TOOL_SOURCE) are injected onto me and run with @ bound to me, so
  # the buffer is mine. Built lazily on first use and drained as the stroke is laid down. Declared
  # undefined, never [] — the lazy build keys off `if !@queue?`, and a prototype array would be
  # shared by every instance.
  queue: undefined

  # what a person calls me: the surface a drawing is painted on
  colloquialName: -> "paint surface"

  # I clear myself to FULLY TRANSPARENT, so BackBufferMixin's per-pixel answer (which I would
  # otherwise inherit from CanvasWdgt) is "the pointer is never on me" — and hover would stop
  # registering the moment the paint surface is clean. My whole box takes the pointer instead:
  # that is what makes me the glass over the canvas. ⚠ It belongs HERE and not in whichever
  # client builds me (ImageWdgt today) — set from outside, a second client, or one dropped line,
  # silently gets a dead paint surface.
  catchesPointerAt: (aPoint) ->
    @boundsContainPoint aPoint

  # paintingOverlay() capability chain (§5.D): I AM the injection target --
  # the focused widget after a click on the paint surface is me -- and the
  # tools' handlers live on me, painting through @underlyingCanvasWdgt.
  isPaintingOverlay: ->
    true

  paintingOverlay: ->
    @

  # I lay no paper: my raster starts clear, so the canvas under me shows through me (CanvasWdgt
  # lays its role's paper when it holds no colour of its own; as glass, I answer none).
  _surfaceFill: ->
    undefined

  constructor: ->
    super
    # the overlay canvas is usually attached to a Canvas
    # which unfortunately is a Frame (it shouldn't, it should
    # just clip at its bounds via a mixin TODO ). So, usually
    # things inside a Panel can be dragged-out of it, so we have
    # to avoid that here
    @isLockingToPanels = true

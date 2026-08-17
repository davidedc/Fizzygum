# Base for the draggable colour palettes — a rectangle you drag across to pick
# a pixel colour, which is pushed to a target widget's colour property (or a
# chosen property). ColorPaletteWdgt paints an HSL field; GrayPaletteWdgt a
# black->white gradient.
#
# They are SIBLINGS here: a gray palette is-not-a colour palette, so the shared
# drag / target / menu plumbing + the back-buffer cache shell live on this base,
# and each subclass supplies only its fill (fillPaletteBuffer), its default size
# (defaultSize, if not the 80x50 default), and its colloquial name.

class PaletteWdgt extends Widget

  @augmentWith ControllerMixin
  @augmentWith BackBufferMixin

  target: undefined
  action: undefined
  argumentToAction: undefined
  choice: undefined

  # I drive colours. No principalPinLabel: the colour I export is @choice, which is not reachable
  # through any pin of mine (my own `color` pin is my chrome, as on every widget), so dataflowValue
  # answers it directly — see the note there.
  producesPinKind: "color"

  constructor: (@target, sizePoint) ->
    super()
    @__commitExtent sizePoint or @defaultSize()

  # subclass overrides this only if it wants a size other than the default
  defaultSize: -> new Point 80, 50

  initialiseDefaultFrameContentLayoutSpec: ->
    @_contentStackSpec = new FrameContentLayoutSpec FrameContentLayoutSpec.DONT_MIND , FrameContentLayoutSpec.DONT_MIND, 1

  detachesWhenDragged: ->
    false

  # no changes of position or extent should be performed in here. The cache
  # shell (key -> lookup -> allocate -> fill -> store) is shared; the subclass
  # paints the pixels via fillPaletteBuffer.
  _createRefreshOrGetBackBuffer: ->
    cacheKey =
      @constructor.name + "-" + @extent().toString()

    cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
    if cacheHit? then return cacheHit

    extent = @extent()
    backBuffer = HTMLCanvasElement.createOfPhysicalDimensions extent.scaleBy ceilPixelRatio
    backBufferContext = backBuffer.getContext "2d"
    backBufferContext.useLogicalPixelsUntilRestore()
    @choice = Color.BLACK
    @fillPaletteBuffer backBufferContext, extent

    cacheEntry = [backBuffer, backBufferContext]
    world.cacheForImmutableBackBuffers.set cacheKey, cacheEntry
    return cacheEntry

  nonFloatDragging: (nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall) ->
    # Affine transforms (§6 R4 audit tail): map the drag sample point into MY plane before reading the
    # pixel. getPixelColor does aPoint.toLocalCoordinatesOf @ and samples my OWN un-rotated backbuffer, so
    # it needs a point in my (virtual) plane; ActivePointerWdgt passes `pos` RAW (screen), so for a palette
    # inside a non-identity island the un-mapped sample reads the WRONG pixel (often out of the backbuffer ⇒
    # transparent). mouseDownLeft is fine (click dispatch plane-maps via _pointerPositionInPlaneOf); only the
    # nonFloatDragging pos was raw — the same 4A-2 gap the slider had. Map the whole screen sample point
    # (pos + the screen lookahead delta) through the inverse. Off any island screenPointToMyPlane is identity
    # ⇒ byte-identical (dormant).
    @choice = @getPixelColor @screenPointToMyPlane (pos.add (deltaDragFromPreviousCall or new Point 0, 0))
    @updateTarget()

  mouseDownLeft: (pos) ->
    @choice = @getPixelColor pos
    @updateTarget()

  # ONE pin: "a bang takes a value of any kind" is a property of the pin, so it is stated on the pin.
  pins: -> super().concat [ new PinSpec "bang!", "any", set: "bang" ]

  # the bang makes the node fire the current output value
  bang: (newvalue) ->
    if !@choice? then return
    # a bang is a FORCE-fire (spec §8): mark stale+forced so it propagates despite the equal-value cutoff.
    world.dataflow.markStale @, true
    return

  updateTarget: ->
    if !@target? then return

    if !@action?
      @action = "setColor"

    @_fireConnection @choice
    return

  # node protocol: a palette's fired value is its picked @choice colour. Widget.exportedValue doesn't
  # cover it — that reads my PRINCIPAL PIN, and @choice is not a pin: nothing can drive it (you pick a
  # colour by dragging across me), and a read-only pin would be a pin nobody can wire. So the node
  # protocol answers it directly, which is exactly the seam dataflowValue exists for.
  dataflowValue: -> @choice

  reactToTargetConnection: ->

  # palette menu:
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addTargetConnectionMenuEntries menu

  # openTargetSelector: -> taken from the ControllerMixin
  # openTargetPropertySelector: -> one shared method on Widget, driven by producesPinKind

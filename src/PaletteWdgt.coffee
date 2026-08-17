# Base for the draggable colour palettes — a rectangle you drag across to pick
# a pixel colour, which is pushed to a target widget's colour property (or a
# chosen property). ColorPaletteWdgt paints an HSL field; GrayPaletteWdgt a
# black->white gradient.
#
# They are SIBLINGS here: a gray palette is-not-a colour palette, so the shared
# drag / target / menu plumbing + the back-buffer cache shell live on this base,
# and each subclass supplies only its own MAP — the fill that draws it
# (fillPaletteBuffer) and the inverse that reads a colour back to a point on it
# (positionForColor) — plus its default size (defaultSize, if not the 80x50
# default) and its colloquial name.

class PaletteWdgt extends Widget

  @augmentWith ControllerMixin
  @augmentWith BackBufferMixin

  # The colour picked through me, and undefined until one IS — a real state, not a gap: `bang`
  # declines to fire without a choice, reactToTargetConnection deliberately fires nothing on
  # connect, and my appearance marks nothing.
  #   Deliberately NOT seeded with a colour, black included. A palette nobody has picked from has no
  # choice to report, so any seed makes one up — and since the choice is DRAWN, that is not a
  # harmless inaccuracy: the marker would assert a pick, at hue 0, that never happened. Seeding it
  # from the back-buffer path would be doubly wrong, that path running on a cache MISS only: the
  # first palette of a given size would start out differently from every later palette of that size.
  choice: undefined

  # what the "choose target property" menu filters a target's pins by, and the adjective in my
  # "set target" tooltip: I drive colours.
  producesPinKind: "color"

  # ONE operand, my size. A leading `target` parameter sat here until §P4 and was a textbook
  # POSITIONAL HOLE (docs/architecture/constructor-and-parameter-conventions.md R3): every caller that
  # wanted a size had to pass `undefined` through it — eleven of them in the test suite do — and the
  # one caller that passed a real target (ColorPickerWdgt) wired itself properly a line later anyway.
  # It could not carry an ACTION either, so a palette built that way was half-wired, which is why
  # updateTarget carried a "default the action to setColor" repair. Wiring is `wireTo`'s job.
  constructor: (sizePoint) ->
    super()
    @appearance = @createAppearance()
    @__commitExtent sizePoint or @defaultSize()

  # a method rather than a class field, so the build's dependency finder still sees the
  # `new PaletteAppearance` edge — and so a subclass whose map wants a different MARK (a 1-D strip
  # would read better with a bar than with a ring) can say so in one line.
  createAppearance: -> new PaletteAppearance @

  # BackBufferMixin's own paint would blit and stop, and I need the blit PLUS my choice marker on
  # top — so route back to the plain appearance delegation (this is Widget's body; the mixin's
  # member shadows it, and a class-body member out-ranks a mixin's). PaletteAppearance then
  # composes the two, calling blitBackBufferInto for the device-space half.
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    @appearance?.paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow

  # subclass overrides this only if it wants a size other than the default
  defaultSize: -> new Point 80, 50

  # WHERE a colour sits on me, or undefined if it is not on my surface at all.
  #
  # > A palette that can be driven declares the INVERSE of its own fillPaletteBuffer.
  #
  # That is the whole contract, and it is why this lives one method away from the fill it inverts:
  # the two state the same map twice, in opposite directions, and the only defence against them
  # disagreeing is that a reader can see both at once. A base palette declares no map, so nothing
  # is on it.
  #   The inverse is asked on every paint rather than cached alongside @choice, so a colour that
  # arrives from ANYWHERE — a drag across me, a snapshot, a duplicate, a wire — is marked by the
  # one path, and a picked position can never drift out of step with the picked colour.
  positionForColor: (aColor) ->
    undefined

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
    return unless @_rememberColorPickedAt @screenPointToMyPlane (pos.add (deltaDragFromPreviousCall or new Point 0, 0))
    @updateTarget()

  mouseDownLeft: (pos) ->
    return unless @_rememberColorPickedAt pos
    @updateTarget()

  # Half of a pick: read the pixel and become it, answering the colour adopted or undefined if none
  # was. The other half is the outward one, @updateTarget, which each gesture fires for itself —
  # this method deliberately stops at my own state so the two effects stay separable.
  #   ⚠ A DRAG TRAVELS, and a sample beyond my buffer reads back fully transparent. That is not a
  # colour anybody picked, so I keep the one I have rather than adopt "nothing" — which would push
  # transparent black to my target and, since the choice is drawn, park my marker in the corner
  # where every lightness-0 colour lives.
  #   The repaint IS mine to ask for: my buffer is immutable, so the marker is the only thing on
  # screen a pick moves.
  _rememberColorPickedAt: (pointInMyPlane) ->
    picked = @getPixelColor pointInMyPlane
    if picked.isFullyTransparent() then return undefined
    @choice = picked
    @_changed()
    return picked

  # TWO pins. "A bang takes a value of any kind" is a property of the pin, so it is stated on the
  # pin. My picked colour is the other, and it is a genuine two-way pair: getChoice and setChoice
  # read and write the SAME property. (My own `color` pin is my chrome, as on every widget — pairing
  # THAT with getChoice would be the lie PinSpec warns about, since a wire writing it would not
  # change what a reader reads.)
  #   Being driveable is what gives positionForColor its purpose: a colour arriving over this pin
  # owes me nothing, so it need not be one of my own pixels — and then I say so instead of pretending
  # (PaletteAppearance).
  pins: -> super().concat [
    new PinSpec "bang!", "any", set: "bang"
    new PinSpec "picked color", "color", set: "setChoice", get: "getChoice"
  ]
  principalPinLabel: "picked color"

  getChoice: ->
    @choice

  # A colour arriving from OUTSIDE me: a wire, a script, a restored snapshot. Deliberately does NOT
  # fire onward — a value delivered TO me is not a pick, and re-firing it would make me an echo. It
  # does repaint, my marker being the only visible trace my choice has.
  #   Both argument slots, as every pin setter must (the pin-setter contract in
  # docs/architecture/widget-authoring-guidelines.md): a wire puts the VALUE in slot 1, while the
  # menu/prompt dispatch puts the widget being configured there and the value-giving widget in
  # slot 2. Same shape as Widget.setColor, which this is the picked-colour twin of.
  setChoice: (aColorOrAWidgetGivingAColor, widgetGivingColor) ->
    if widgetGivingColor?.getColor?
      aColor = widgetGivingColor.getColor()
    else
      aColor = aColorOrAWidgetGivingAColor
    if !aColor? then return
    if @choice?.equals aColor then return
    @choice = aColor
    @_changed()
    return aColor

  # the bang makes the node fire the current output value
  bang: (newvalue) ->
    if !@choice? then return
    # a bang is a FORCE-fire (spec §8): mark stale+forced so it propagates despite the equal-value cutoff.
    world.dataflow.markStale @, true
    return

  # (no "default my action to setColor if it is unset" repair here: a WireSpec is constructed with
  # both its target and its action, so "wired, but to nothing in particular" is not a representable
  # state — §P4)
  updateTarget: ->
    @_fireConnection @choice
    return

  reactToTargetConnection: ->

  # palette menu:
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addTargetConnectionMenuEntries menu

  # openTargetSelector: -> taken from the ControllerMixin
  # openTargetPropertySelector: -> one shared method on Widget, driven by producesPinKind

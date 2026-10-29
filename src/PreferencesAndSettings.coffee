# World-wide preferences and settings ///////////////////////////////////

# The world-wide BEHAVIOUR settings: input (wheel, virtual keyboard, slider entry), timing
# (dwell-to-arm, press-and-hold) and thresholds (drag start, dock bands, title ellipsis). They
# belong to a world; each world may have different settings. What the world LOOKS like -- its
# colours, font roles and chrome metrics -- is decided by its Theme (WorldWdgt.theme), not here.

class PreferencesAndSettings

  # The ONE probe per PAGE. getMinimumFontHeight rasterises a glyph and reads the pixels back,
  # and that read's answer depends on how warm the SWCanvas glyph atlas is (DETERMINISM.md §3g):
  # a cold-atlas probe at boot and a warm re-probe later answer DIFFERENT numbers. So the probe
  # runs exactly once per page -- lazily (?=) at the first construction, which IS boot, on a cold
  # atlas -- and every PreferencesAndSettings built afterwards reads that boot measurement here
  # instead of measuring again.
  @probedMinimumFontHeight: undefined

  # I am a per-world singleton reached as the STATIC WorldWdgt.preferencesAndSettings: what makes me
  # ME is that one identity, not my field values. So anything that holds me KEEPS THE REFERENCE
  # through a deep copy — a copy carrying a clone would read and write settings no world renders
  # from, which is precisely what the same flag on Wallpaper exists to prevent.
  keptByReferenceOnDeepCopy: true

  # Serialization needs no new arm: WellKnownObjects already matches me BY IDENTITY against
  # WorldWdgt.preferencesAndSettings and re-binds on restore (its keyFor and resolve both carry
  # "preferences"). This marker states that key alongside the identity check, as Wallpaper does.
  wellKnownKey: "preferences"

  # the smallest font height this browser renders (the probe above): StringWdgt.fontHeight
  # floors the size it measures at it.
  minimumFontHeight: undefined

  # (a drag threshold: see its assignment in the constructor)
  dockBandDepth: undefined

  # The GRADED TITLE thresholds (ruling C13): a bar shows its full title when it fits, an
  # ellipsised one only while the visible prefix keeps at least this FRACTION of the characters
  # AND at least this MANY of them, and no title at all below either bar.
  barTitleEllipsisMinFraction: undefined
  barTitleEllipsisMinChars: undefined

  wheelScaleX: 1
  wheelScaleY: 1
  invertWheelX: true
  invertWheelY: true

  # Normalize raw wheel deltas: squelch the minor axis when the intention is clearly
  # one-axis (prevents too much diagonal movement), then apply the invertWheelX/Y
  # preferences. Returns the adjusted [x, y] pair; every `scrolledBy` implementor
  # (ViewportWdgt, SimpleSpreadsheetWdgt) routes its raw deltas through this.
  normalizedWheelDeltas: (x, y) ->
    if Math.abs(y) < Math.abs(x)
      y = 0
    if Math.abs(x) < Math.abs(y)
      x = 0
    if @invertWheelX
      x *= -1
    if @invertWheelY
      y *= -1
    [x, y]

  useSliderForInput: undefined
  useVirtualKeyboard: undefined
  isFlat: undefined
  grabDragThreshold: 7

  # Drag-embed dwell-to-arm (docs/specs/drag-embed-interaction-spec.md §6). A WINDOW payload embeds
  # into a receptive container only after the pointer LINGERS dwellToArmMs of ELAPSED EVENT-TIME within
  # the linger radius of its origin — and the linger radius REUSES grabDragThreshold (one notion of
  # "stationary", so no separate constant). dwellRingSteps = the quantised charging-ring segments
  # (presentation only; the arm decision is pure event-time).
  dwellToArmMs: 450
  dwellRingSteps: 5

  # Press-and-hold, the touch grammar's right-click (ruling I2). A TOUCH press that stays within
  # grabDragThreshold of its origin for pressAndHoldMs of ELAPSED EVENT-TIME opens the pressed
  # widget's context menu — the very consequence a right-click has — and from that moment the
  # stroke's drags mean what a mouse's would. The radius REUSES grabDragThreshold, exactly as the
  # dwell above does: one notion of "stationary" for the whole hand. A mouse or a pen never waits
  # (it arms at the press), so this dial is a finger's alone.
  pressAndHoldMs: 500

  # decimalFloatFiguresOfFontSizeGranularity would let StringWdgt's
  # searchLargestFittingFont step through sub-points of font size, trading
  # jumpiness ("1" was the sweet spot) for a costlier search -- but that method
  # unconditionally resets this field to 0 at the start of every call, so it is
  # currently pinned at integer granularity; adjusting it here has no effect
  # unless that reset is removed too.
  @decimalFloatFiguresOfFontSizeGranularity: 0

  constructor: ->
    @minimumFontHeight = PreferencesAndSettings.probedMinimumFontHeight ?= @getMinimumFontHeight() # browser settings

    # how deep a frame's edge DROP BANDS reach in from its body's edges: the strip in which
    # releasing a dragged frame docks it there instead of dropping it into the content. At least a
    # strip's thickness (the frame border it spans, its barIconSize targets and its rule: 46 --
    # FrameWdgt._barSpec), so a band is never thinner than the grip the drop produces.
    @dockBandDepth = 50

    # A title too cropped to read is worse than no title (ruling C13): keep the ellipsised form
    # only while it still carries 70% of the characters and at least 5 of them.
    @barTitleEllipsisMinFraction = 0.7
    @barTitleEllipsisMinChars = 5

    @wheelScaleX = 1
    @wheelScaleY = 1
    @invertWheelX = true
    @invertWheelY = true

    @useSliderForInput = false
    @useVirtualKeyboard = true
    @isFlat = false

  # answer the height of the smallest font renderable in pixels
  getMinimumFontHeight: ->
    str = "I"
    size = 50
    # go through the factory so the SWCanvas backend switch reaches this probe
    canvas = HTMLCanvasElement.createOfPhysicalDimensions new Point size, size
    ctx = canvas.getContext "2d", willReadFrequently: true
    # a THROWAWAY calibration rasterisation: its pixels never reach the screen, so the
    # SWCanvas cold-glyph recorder must not count its (possibly placeholder) draw
    # (SWCanvasElement-extensions' surgical atlas-warm attribution reads this flag)
    ctx.isFizzygumCalibrationProbe = true
    ctx.font = "1px serif"
    maxX = Math.ceil ctx.measureText(str).width
    ctx.fillStyle = Color.BLACK.toString()
    ctx.textBaseline = "bottom"
    ctx.fillText str, 0, size
    for y in [0...size]
      for x in [0...maxX]
        data = ctx.getImageData x, y, 1, 1
        return size - y + 1  if data.data[3] isnt 0
    0


# World-wide preferences and settings ///////////////////////////////////

# Contains all possible preferences and settings for a World.
# So it's World-wide values.
# It belongs to a world, each world may have different settings.

class PreferencesAndSettings

  @INPUT_MODE_MOUSE: 0
  @INPUT_MODE_TOUCH: 1

  # I am a per-world singleton reached as the STATIC WorldWdgt.preferencesAndSettings, and a menu row
  # holds me: the world menu's input-mode row TARGETS me (toggleInputMode) and SHOWS me (its
  # MenuRowReflectionSpec reads my currentInputMode). So a duplicated menu must KEEP THE REFERENCE —
  # without this the copy's row toggles a dead clone instead of the real settings, which is precisely
  # what the same flag on Wallpaper exists to prevent, and was measurably broken here until
  # 2026-08-17 (probe: Fizzygum-tests/.scratch/prefs-bag-duplication-probe.js).
  keptByReferenceOnDeepCopy: true

  # Serialization needs no new arm: WellKnownObjects already matches me BY IDENTITY against
  # WorldWdgt.preferencesAndSettings and re-binds on restore (its keyFor and resolve both carry
  # "preferences"). This marker states that key alongside the identity check, as Wallpaper does.
  wellKnownKey: "preferences"

  # all these properties can be modified
  # by the input mode.
  inputMode: undefined
  minimumFontHeight: undefined
  shortcutsFontSize: undefined
  menuFontName: undefined
  menuFontSize: undefined
  menuHeaderFontSize: undefined
  menuHeaderColor: undefined
  menuHeaderBold: undefined
  menuStrokeColor: undefined
  menuBackgroundColor: undefined
  menuButtonsLabelColor: undefined
  normalTextFontSize: undefined
  textInButtonsFontSize: undefined
  titleBarTextFontSize: undefined
  titleBarBoldText: undefined
  titleBarTextHeight: undefined
  bubbleHelpFontSize: undefined
  prompterFontName: undefined
  prompterFontSize: undefined
  prompterSliderSize: undefined
  handleSize: undefined
  scrollBarsThickness: undefined

  # (no outlineColor field: it is a local in setMouseInputMode -- nothing but the
  # outlineColorString shortcut below ever reads the Color object itself.)
  outlineColorString: undefined

  wheelScaleX: 1
  wheelScaleY: 1
  invertWheelX: true
  invertWheelY: true

  # Normalize raw wheel deltas: squelch the minor axis when the intention is clearly
  # one-axis (prevents too much diagonal movement), then apply the invertWheelX/Y
  # preferences. Returns the adjusted [x, y] pair; every wheel handler
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
  isTouchDevice: undefined
  rasterizeSVGs: undefined
  isFlat: undefined
  grabDragThreshold: 7

  # Drag-embed dwell-to-arm (docs/specs/drag-embed-interaction-spec.md §6). A WINDOW payload embeds
  # into a receptive container only after the pointer LINGERS dwellToArmMs of ELAPSED EVENT-TIME within
  # the linger radius of its origin — and the linger radius REUSES grabDragThreshold (one notion of
  # "stationary", so no separate constant). dwellRingSteps = the quantised charging-ring segments
  # (presentation only; the arm decision is pure event-time).
  dwellToArmMs: 450
  dwellRingSteps: 5

  # decimalFloatFiguresOfFontSizeGranularity would let StringWdgt's
  # searchLargestFittingFont step through sub-points of font size, trading
  # jumpiness ("1" was the sweet spot) for a costlier search -- but that method
  # unconditionally resets this field to 0 at the start of every call, so it is
  # currently pinned at integer granularity; adjusting it here has no effect
  # unless that reset is removed too.
  @decimalFloatFiguresOfFontSizeGranularity: 0

  constructor: ->
    @setMouseInputMode()

  toggleInputMode: ->
    if @inputMode == PreferencesAndSettings.INPUT_MODE_MOUSE
      @setTouchInputMode()
    else
      @setMouseInputMode()
    # ANNOUNCE it: every open menu row that SHOWS the input mode re-derives its wording from the
    # drain, wherever that row is (MenuRowReflectionSpec / MenuRowsPanelWdgt). Safe to mark myself
    # stale because I am a plain collaborator, not a Widget — a widget has ONE staleness signal
    # (Widget.dataflowValue is its exported value), so a widget announcing "one of my properties
    # changed" would also fire its dataflow WIRES. That is the gap P3 exists to close.
    world.dataflow.markStale @

  # ── dataflow node protocol ─────────────────────────────────────────────────────────────────
  # I am a NODE without being a Widget — the protocol is duck-typed (SecondsSource/FrameSource
  # prove it), which is what lets a menu row subscribe to my input mode.
  dataflowValue: -> @inputMode

  # what a reflecting menu row reads (MenuRowReflectionSpec.readerName)
  currentInputMode: -> @inputMode

  # Put the bag back the way the constructor left it (mouse mode). This bag is reached as the
  # STATIC WorldWdgt.preferencesAndSettings, so it outlives even a brand-new world: without this,
  # one "touch screen settings" click leaves every later SystemTest in the same headless page
  # rendering doubled menu/prompter fonts, sliders and scrollbars. Called from
  # WorldWdgt._resetWorldNoSettle -- the reset knowledge lives HERE, with the owner, like
  # UntitledNamingService.resetCounters.
  #
  # Self-guarded, so the ordinary teardown does no work at all, and minimumFontHeight is CARRIED
  # OVER rather than re-derived: it measures the BROWSER's smallest renderable glyph, not the
  # input mode, and setMouseInputMode re-probes it by rasterising a glyph and reading the pixels
  # back -- a read whose answer depends on how warm the SWCanvas glyph atlas is (DETERMINISM.md
  # §3g), so re-probing mid-run could hand the next test a different number than boot measured.
  resetToBootInputMode: ->
    return if @inputMode == PreferencesAndSettings.INPUT_MODE_MOUSE
    probedMinimumFontHeight = @minimumFontHeight
    @setMouseInputMode()
    @minimumFontHeight = probedMinimumFontHeight


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

  setMouseInputMode: ->
    @inputMode = PreferencesAndSettings.INPUT_MODE_MOUSE
    @minimumFontHeight = @getMinimumFontHeight() # browser settings
    @menuFontName = "sans-serif"
    @menuFontSize = 12 # 14
    @menuHeaderFontSize = 12 # 13
    @menuHeaderColor = Color.create 77,77,77 # Color.create 125, 125, 125
    @menuHeaderBold = true # false
    @menuStrokeColor = Color.create 210, 210, 210 # Color.create 186, 186, 186
    @menuBackgroundColor = Color.create 249, 249, 249 # Color.create 244, 244, 244
    @menuButtonsLabelColor = Color.BLACK # Color.create 50, 50, 50

    @externalWindowBarBackgroundColor = Color.create 125, 125, 125
    @externalWindowBarStrokeColor = Color.create 100,100,100
    @internalWindowBarBackgroundColor = Color.create 172, 172, 172
    @internalWindowBarStrokeColor = Color.create 150,150,150

    @normalTextFontSize = 12 # 13
    @textInButtonsFontSize = 12 # 13

    @titleBarTextFontSize = 12 # 13
    @titleBarTextHeight = 15 # 16
    @titleBarBoldText = true # false
    @bubbleHelpFontSize = 10 # 12
    @prompterFontName = "sans-serif"
    @prompterFontSize = 12
    @prompterSliderSize = 10

    @defaultPanelsBackgroundColor = Color.create 255, 250, 245
    @defaultPanelsStrokeColor = Color.create 100, 100, 100
    @editableItemBackgroundColor = Color.create 240, 240, 240

    outlineColor = Color.create 244,243,244
    # let's create this shortcut just because
    # we use this string so many times
    @outlineColorString = outlineColor.toString()

    @iconDarkLineColor = Color.BLACK

    @shortcutsFontSize = 12

    # handle and scrollbar should ideally be the
    # same size because they often show next to
    # each other
    @handleSize = 15
    @scrollBarsThickness = 10

    @wheelScaleX = 1
    @wheelScaleY = 1
    @invertWheelX = true
    @invertWheelY = true

    @useSliderForInput = false
    @useVirtualKeyboard = true
    @isTouchDevice = false # turned on by touch events, don't set
    @rasterizeSVGs = false
    @isFlat = false

  setTouchInputMode: ->
    @inputMode = PreferencesAndSettings.INPUT_MODE_TOUCH
    @minimumFontHeight = @getMinimumFontHeight()
    @menuFontName = "sans-serif"
    @menuFontSize = 24
    @bubbleHelpFontSize = 18
    @prompterFontName = "sans-serif"
    @prompterFontSize = 24
    @prompterSliderSize = 20

    # handle and scrollbar should ideally be the
    # same size because they often show next to
    # each other
    @handleSize = 26
    @scrollBarsThickness = 24

    @wheelScaleX = 1
    @wheelScaleY = 1
    @invertWheelX = true
    @invertWheelY = true

    @useSliderForInput = true
    @useVirtualKeyboard = true
    @isTouchDevice = false
    @rasterizeSVGs = false
    @isFlat = false


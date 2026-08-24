# World-wide preferences and settings ///////////////////////////////////

# Contains all possible preferences and settings for a World.
# So it's World-wide values.
# It belongs to a world, each world may have different settings.

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

  # the typography, colour and sizing settings the whole world renders from.
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

  # Chrome-geometry constants (program ruling G2): the bar button's hit box, the bar's own
  # padding, the glyph inset within a bar button's box, the minimum height a menu/list row
  # takes, a menu header's corner rounding, a menu/list rows-panel's border, and a toolbar grid's
  # cell side / inter-cell gap / outer margin / row count. Each chrome layout site reads the
  # matching name here; no chrome dimension lives as a literal in a layout method.
  barIconSize: undefined
  barPadding: undefined
  barGlyphSize: undefined
  menuRowHeight: undefined
  menuHeaderCornerRadius: undefined
  menuRowsBorder: undefined
  toolThumbnailSize: undefined
  toolInternalPadding: undefined
  toolExternalPadding: undefined
  toolRows: undefined
  toolbarDockThickness: undefined
  dockBandDepth: undefined

  # (no outlineColor field: it is a local in the constructor -- nothing but the
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

  # ONE geometry serves mouse and finger alike (program ruling G1), so every value below is set
  # here, once, at construction: there is no per-device redraw to switch between.
  constructor: ->
    @minimumFontHeight = PreferencesAndSettings.probedMinimumFontHeight ?= @getMinimumFontHeight() # browser settings
    @menuFontName = "sans-serif"
    @menuFontSize = 12 # 14
    @menuHeaderFontSize = 12 # 13
    @menuHeaderColor = Color.create 77,77,77 # Color.create 125, 125, 125
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

    # a frame bar's button (close / collapse / edit) is a barIconSize square; its glyph paints
    # inset by barGlyphSize within that square -- equal today, so the button's hit box and its
    # drawn glyph are the same size and no pixel moves. Kept as two preferences because a touch
    # target and its glyph are different dials (G3), even though the desk profile ties them.
    @barIconSize = 16
    @barGlyphSize = 16
    # barPadding is the frame's own chrome padding: it sets the titlebar strip's height
    # (barIconSize + 2 * barPadding) and the frame body's margin around its content.
    @barPadding = 5

    # the MINIMUM height a menu or list row takes, and the floor under a pop-up's title strip
    # (a title is a tap-to-pin target, ruling C3). A row whose label is taller keeps its label's
    # height, and the label sits centred in whichever height wins. At 0 the floor never binds and
    # a row is exactly its label.
    @menuRowHeight = 0

    # the header box's own corner rounding.
    @menuHeaderCornerRadius = 3
    # the border width a menu/list rows panel keeps around its flush-stacked rows.
    @menuRowsBorder = 2

    # a toolbar grid's thumbnail cell: side length, the gap between cells, and the margin
    # around the whole grid; toolRows is how many cells a docked strip's cross-axis fits.
    @toolThumbnailSize = 30
    @toolInternalPadding = 5
    @toolExternalPadding = 10
    @toolRows = 2
    # a docked ToolbarWdgt's own cross-axis extent -- an independent constant, not a formula
    # over the grid metrics above (ToolbarWdgt reads it directly for its base dockThickness).
    @toolbarDockThickness = 95
    # how deep a frame's edge DROP BANDS reach in from its body's edges: the strip in which
    # releasing a dragged frame docks it there instead of dropping it into the content. At least a
    # bar thickness (barIconSize + 2*barPadding = 26), so a band is never thinner than the grip
    # the drop produces.
    @dockBandDepth = 30

    @wheelScaleX = 1
    @wheelScaleY = 1
    @invertWheelX = true
    @invertWheelY = true

    @useSliderForInput = false
    @useVirtualKeyboard = true
    @isTouchDevice = false # turned on by touch events, don't set
    @rasterizeSVGs = false
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


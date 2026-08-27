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
  # takes, a menu header's corner rounding, a menu/list rows-panel's border, a toolbar grid's
  # cell side / inter-cell gap / outer margin / row count, and how deep a frame's drop bands
  # reach. Each chrome layout site reads the
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
  dockBandDepth: undefined

  # The overlay scroll INDICATOR's thin resting width (program ruling G4). A hovered indicator
  # fattens to scrollBarsThickness instead, which is why that dial is the FAT width.
  scrollIndicatorThickness: undefined

  # The hairline a row paints along its TOP edge when the row above it is another row (ruling G5):
  # paint, never layout, so rows stay flush and no dead zone opens between two targets.
  menuRowSeparatorColor: undefined

  # The GRADED TITLE thresholds (ruling C13): a bar shows its full title when it fits, an
  # ellipsised one only while the visible prefix keeps at least this FRACTION of the characters
  # AND at least this MANY of them, and no title at all below either bar.
  barTitleEllipsisMinFraction: undefined
  barTitleEllipsisMinChars: undefined

  # (no outlineColor field: it is a local in the constructor -- nothing but the
  # outlineColorString shortcut below ever reads the Color object itself.)
  outlineColorString: undefined

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

  # ONE geometry serves mouse and finger alike (program ruling G1), so every value below is set
  # here, once, at construction: there is no per-device redraw to switch between, and no
  # boot-time styling pass rewriting a dozen of them on one kind of page.
  constructor: ->
    @minimumFontHeight = PreferencesAndSettings.probedMinimumFontHeight ?= @getMinimumFontHeight() # browser settings
    @menuFontName = "sans-serif"
    @menuFontSize = 17
    @menuHeaderFontSize = 13
    @menuHeaderColor = Color.create 125, 125, 125
    @menuHeaderBold = false
    @menuStrokeColor = Color.create 186, 186, 186
    @menuBackgroundColor = Color.create 250, 250, 250
    @menuButtonsLabelColor = Color.create 50, 50, 50

    @externalWindowBarBackgroundColor = Color.create 125, 125, 125
    @externalWindowBarStrokeColor = Color.create 100,100,100
    @internalWindowBarBackgroundColor = Color.create 172, 172, 172
    @internalWindowBarStrokeColor = Color.create 150,150,150

    @normalTextFontSize = 13
    @textInButtonsFontSize = 12

    @titleBarTextFontSize = 15
    @titleBarTextHeight = 19
    @titleBarBoldText = false
    @bubbleHelpFontSize = 12
    @prompterFontName = "sans-serif"
    # the prompter family is a TARGET family (G3): its text scales with the menu text, and
    # prompterSliderSize is the input slider's CROSS axis, i.e. the thumb you drag.
    @prompterFontSize = 14
    @prompterSliderSize = 44

    @defaultPanelsBackgroundColor = Color.create 249, 249, 249
    @defaultPanelsStrokeColor = Color.create 198, 198, 198
    @editableItemBackgroundColor = Color.create 240, 240, 240

    outlineColor = Color.create 244,243,244
    # let's create this shortcut just because
    # we use this string so many times
    @outlineColorString = outlineColor.toString()

    @iconDarkLineColor = Color.create 37, 37, 37

    @shortcutsFontSize = 12

    # the resize handle is a TARGET (G3), and ruling T3 gives it the "glyph = box" shape: what
    # you can hit is exactly the grip you see, so there is one dial and no invisible band.
    @handleSize = 44
    # the FAT (hovered) width of a scroll indicator -- see scrollIndicatorThickness below for the
    # thin resting width.
    @scrollBarsThickness = 12

    # a frame bar's button (close / collapse / edit) is a barIconSize square; its glyph paints
    # at barGlyphSize centred within that square. Two dials, never one (G3): a touch target and
    # the mark inside it scale differently, so the bar strip is sized for the finger while the
    # ink stays the size the eye wants.
    @barIconSize = 44
    @barGlyphSize = 24
    # barPadding is the frame's own chrome padding: it sets the titlebar strip's height
    # (barIconSize + 2 * barPadding) and the frame body's margin around its content.
    @barPadding = 3

    # the MINIMUM height a menu or list row takes, and the floor under a pop-up's title strip
    # (a title is a tap-to-pin target, ruling C3). A row whose label is taller keeps its label's
    # height, and the label sits centred in whichever height wins. A row is a tap target, and so
    # are the prompt's Ok / Close buttons, which ARE menu rows (G5).
    @menuRowHeight = 44

    # the header box's own corner rounding.
    @menuHeaderCornerRadius = 4
    # the border width a menu/list rows panel keeps around its flush-stacked rows.
    @menuRowsBorder = 2

    # a toolbar grid's thumbnail cell: side length, the gap between cells, and the margin
    # around the whole grid; toolRows is how many rows of cells a strip lays out before the
    # remainder goes behind the overflow chevron. A thumbnail is a target (G3), and a strip is
    # ONE row, as a tablet toolbar is.
    @toolThumbnailSize = 44
    @toolInternalPadding = 6
    @toolExternalPadding = 10
    @toolRows = 1
    # (a docked strip's own cross-axis extent is no constant: it DERIVES from the three dials
    # above -- ToolPanelWdgt.naturalGridCrossExtent, the same arithmetic that hugs a floating
    # toolbar around its cells.)
    # how deep a frame's edge DROP BANDS reach in from its body's edges: the strip in which
    # releasing a dragged frame docks it there instead of dropping it into the content. At least a
    # bar thickness (barIconSize + 2*barPadding = 50), so a band is never thinner than the grip
    # the drop produces.
    @dockBandDepth = 50

    # A scroll indicator rests THIN and untouchable for as long as its pane overflows, and is
    # absent when it does not: visibility is a derivation from overflow, on no clock at all.
    @scrollIndicatorThickness = 4

    # the hairline between two adjacent rows: fainter than menuStrokeColor (186), because a menu's
    # own border is a boundary and this is only a rhythm mark inside it.
    @menuRowSeparatorColor = Color.create 225, 225, 225

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


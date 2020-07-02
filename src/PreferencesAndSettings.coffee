# World-wide preferences and settings ///////////////////////////////////

# Contains all possible preferences and settings for a World.
# So it's World-wide values.
# It belongs to a world, each world may have different settings.

class PreferencesAndSettings

  @augmentWith DeepCopierMixin

  @INPUT_MODE_MOUSE: 0
  @INPUT_MODE_TOUCH: 1

  # all these properties can be modified
  # by the input mode.
  inputMode: nil
  minimumFontHeight: nil
  shortcutsFontSize: nil
  menuFontName: nil
  menuFontSize: nil
  menuHeaderFontSize: nil
  menuHeaderColor: nil
  menuHeaderBold: nil
  menuStrokeColor: nil
  menuBackgroundColor: nil
  menuButtonsLabelColor: nil
  normalTextFontSize: nil
  textInButtonsFontSize: nil
  titleBarTextFontSize: nil
  titleBarBoldText: nil
  titleBarTextHeight: nil
  bubbleHelpFontSize: nil
  prompterFontName: nil
  prompterFontSize: nil
  prompterSliderSize: nil
  handleSize: nil
  scrollBarsThickness: nil

  outlineColor: nil
  outlineColorString: nil

  wheelScaleX: 1
  wheelScaleY: 1
  wheelScaleZ: 1
  invertWheelX: true
  invertWheelY: true
  invertWheelZ: true

  useSliderForInput: nil
  useVirtualKeyboard: nil
  isTouchDevice: nil
  rasterizeSVGs: nil
  isFlat: nil
  grabDragThreshold: 7

  # decimalFloatFiguresOfFontSizeGranularity allows you to go into sub-points
  # in the font size. This is so the resizing of the
  # text is less "jumpy".
  # "1" seems to be perfect in terms of jumpiness,
  # but obviously this routine gets quite a bit more
  # expensive.
  @decimalFloatFiguresOfFontSizeGranularity: 0

  constructor: ->
    @setMouseInputMode()

  toggleInputMode: ->
    if @inputMode == PreferencesAndSettings.INPUT_MODE_MOUSE
      @setTouchInputMode()
    else
      @setMouseInputMode()

  setMouseInputMode: ->
    @inputMode = PreferencesAndSettings.INPUT_MODE_MOUSE
    @minimumFontHeight = getMinimumFontHeight() # browser settings
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

    @outlineColor = Color.create 244,243,244
    # let's create this shortcut just because
    # we use this string so many times
    @outlineColorString = @outlineColor.toString()

    @iconDarkLineColor = Color.BLACK

    @shortcutsFontSize = 12

    # handle and scrollbar should ideally be the
    # same size because they often show next to
    # each other
    @handleSize = 15
    @scrollBarsThickness = 10

    @wheelScaleX = 1
    @wheelScaleY = 1
    @wheelScaleZ = 1
    @invertWheelX = true
    @invertWheelY = true
    @invertWheelZ = true

    @useSliderForInput = false
    @useVirtualKeyboard = true
    @isTouchDevice = false # turned on by touch events, don't set
    @rasterizeSVGs = false
    @isFlat = false

  setTouchInputMode: ->
    @inputMode = PreferencesAndSettings.INPUT_MODE_TOUCH
    @minimumFontHeight = getMinimumFontHeight()
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
    @wheelScaleZ = 1
    @invertWheelX = true
    @invertWheelY = true
    @invertWheelZ = true

    @useSliderForInput = true
    @useVirtualKeyboard = true
    @isTouchDevice = false
    @rasterizeSVGs = false
    @isFlat = false


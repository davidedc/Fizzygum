# World-wide preferences and settings ///////////////////////////////////

# Contains all possible preferences and settings for a World.
# So it's World-wide values.
# It belongs to a world, each world may have different settings.
# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

class PreferencesAndSettings
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith DeepCopierMixin

  @INPUT_MODE_MOUSE: 0
  @INPUT_MODE_TOUCH: 1

  useBlurredShadows: null
  
  # all these properties can be modified
  # by the input mode.
  inputMode: null
  minimumFontHeight: null
  globalFontFamily: null
  menuFontName: null
  menuFontSize: null
  bubbleHelpFontSize: null
  prompterFontName: null
  prompterFontSize: null
  prompterSliderSize: null
  handleSize: null
  scrollBarSize: null
  mouseScrollAmount: null
  useSliderForInput: null
  useVirtualKeyboard: null
  isTouchDevice: null
  rasterizeSVGs: null
  isFlat: null

  printoutsReactiveValuesCode: true

  constructor: ->
    @useBlurredShadows = getBlurredShadowSupport() # check for Chrome-bug
    @setMouseInputMode()
    console.log("constructing PreferencesAndSettings")

  toggleBlurredShadows: ->
    @useBlurredShadows = not @useBlurredShadows

  toggleInputMode: ->
    if @inputMode == PreferencesAndSettings.INPUT_MODE_MOUSE
      @setTouchInputMode()
    else
      @setMouseInputMode()

  setMouseInputMode: ->
    @inputMode = PreferencesAndSettings.INPUT_MODE_MOUSE
    @minimumFontHeight = getMinimumFontHeight() # browser settings
    @globalFontFamily = ""
    @menuFontName = "sans-serif"
    @menuFontSize = 12
    @bubbleHelpFontSize = 10
    @prompterFontName = "sans-serif"
    @prompterFontSize = 12
    @prompterSliderSize = 10
    @handleSize = 15
    @scrollBarSize = 10
    @mouseScrollAmount = 40
    @useSliderForInput = false
    @useVirtualKeyboard = true
    @isTouchDevice = false # turned on by touch events, don't set
    @rasterizeSVGs = false
    @isFlat = false

  setTouchInputMode: ->
    @inputMode = PreferencesAndSettings.INPUT_MODE_TOUCH
    @minimumFontHeight = getMinimumFontHeight()
    @globalFontFamily = ""
    @menuFontName = "sans-serif"
    @menuFontSize = 24
    @bubbleHelpFontSize = 18
    @prompterFontName = "sans-serif"
    @prompterFontSize = 24
    @prompterSliderSize = 20
    @handleSize = 26
    @scrollBarSize = 24
    @mouseScrollAmount = 40
    @useSliderForInput = true
    @useVirtualKeyboard = true
    @isTouchDevice = false
    @rasterizeSVGs = false
    @isFlat = false


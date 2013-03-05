# Global settings /////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

#global window, HTMLCanvasElement, getMinimumFontHeight, FileReader, Audio,
#FileList, getBlurredShadowSupport

modules = {} # keep track of additional loaded modules

useBlurredShadows = getBlurredShadowSupport() # check for Chrome-bug

standardSettings =
  minimumFontHeight: getMinimumFontHeight() # browser settings
  globalFontFamily: ""
  menuFontName: "sans-serif"
  menuFontSize: 12
  bubbleHelpFontSize: 10
  prompterFontName: "sans-serif"
  prompterFontSize: 12
  prompterSliderSize: 10
  handleSize: 15
  scrollBarSize: 12
  mouseScrollAmount: 40
  useSliderForInput: false
  useVirtualKeyboard: true
  rasterizeSVGs: false

touchScreenSettings =
  minimumFontHeight: standardSettings.minimumFontHeight
  globalFontFamily: ""
  menuFontName: "sans-serif"
  menuFontSize: 24
  bubbleHelpFontSize: 18
  prompterFontName: "sans-serif"
  prompterFontSize: 24
  prompterSliderSize: 20
  handleSize: 26
  scrollBarSize: 24
  mouseScrollAmount: 40
  useSliderForInput: true
  useVirtualKeyboard: true
  rasterizeSVGs: false


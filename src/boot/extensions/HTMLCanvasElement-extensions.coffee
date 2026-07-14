# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

HTMLCanvasElement::deepCopy = (objOriginalsClonedAlready, objectClones, allWidgetsInStructure) ->
  deepCopyWithIdentity @, objOriginalsClonedAlready, objectClones, =>
    # width and height here are not the widget's,
    # which would be in logical units and hence would need ceilPixelRatio
    # correction,
    # but in actual physical units i.e. the actual buffer size
    cloneOfMe = HTMLCanvasElement.createOfPhysicalDimensions new Point @width, @height

    ctx = cloneOfMe.getContext "2d"
    ctx.drawImage @, 0, 0
    cloneOfMe

# HTMLCanvasElement.createOfPhysicalDimensions takes physical size, i.e. actual buffer pixels.
# On non-retina displays, that's just the amount of logical pixels,
# which are used for all other measures of widgets.
# On retina displays, that's twice the amount of logical pixels.
# If the dimensions come from a canvas size, then those are
# already physical pixels.
# If the dimensions come form other measurements of the widgets,
# then those are in logical coordinates and need to be
# corrected with ceilPixelRatio before being passed here.
HTMLCanvasElement.createOfPhysicalDimensions = (extentPoint) ->
  extentPoint?.debugIfFloats()
  # answer a new empty instance of Canvas, don't display anywhere
  ext = extentPoint or
    x: 0
    y: 0
  # The single backend switch: when the SWCanvas flag is on, every off-screen
  # buffer (and the world render canvas) is an SWCanvasElement instead of a DOM
  # canvas. SWCanvas surfaces must be >= 1px (a 0x0 measurement canvas becomes
  # 1x1; measureText doesn't need area).
  if window.FIZZYGUM_USE_SWCANVAS and window.SWCanvas?
    return window.SWCanvas.createCanvas (Math.max 1, Math.ceil ext.x), (Math.max 1, Math.ceil ext.y)
  canvas = document.createElement "canvas"
  canvas.width = Math.ceil ext.x
  canvas.height = Math.ceil  ext.y
  canvas



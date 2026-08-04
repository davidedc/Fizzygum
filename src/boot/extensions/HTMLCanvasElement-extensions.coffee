# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

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

# Turn a canvas's pixels into a black silhouette IN PLACE: every visible pixel
# becomes black, per-pixel alpha (AA fringes, semi-transparent content) is kept.
# The one primitive behind the shadow-pass contract (Widget.coffee "How the
# shadow painting works"): a shadow is the caster's per-pixel COVERAGE, chroma
# always black. "source-in" is a canvas-wide composite op on both backends
# (SWCanvas has a fillRect fast path for it).
HTMLCanvasElement.blackenIntoSilhouetteInPlace = (canvas) ->
  ctx = canvas.getContext "2d"
  ctx.save()
  ctx.setTransform 1, 0, 0, 1, 0, 0
  ctx.globalCompositeOperation = "source-in"
  ctx.fillStyle = "black"
  ctx.fillRect 0, 0, canvas.width, canvas.height
  ctx.restore()

# A NEW canvas holding the black silhouette of `sourceCanvas` (which is left
# untouched) — for shadow passes that blit an existing buffer (island buffers,
# BackBufferMixin back buffers) rather than re-painting art.
HTMLCanvasElement.blackSilhouetteOf = (sourceCanvas) ->
  sil = HTMLCanvasElement.createOfPhysicalDimensions new Point sourceCanvas.width, sourceCanvas.height
  sil.getContext("2d").drawImage sourceCanvas, 0, 0
  HTMLCanvasElement.blackenIntoSilhouetteInPlace sil
  sil



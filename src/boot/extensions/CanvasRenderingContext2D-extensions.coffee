# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

CanvasRenderingContext2D::useLogicalPixelsUntilRestore = ->
  @scale ceilPixelRatio, ceilPixelRatio

CanvasRenderingContext2D::rebuildDerivedValue = (objectIBelongTo, myPropertyName) ->
  # here we need to re-generate a context from the COPY canvas
  # I can't think of an easy way to do this, just assume that the canvas
  # in in a property with name same as the context one, but without "Context"
  # e.g. "backBufferContext" -> belongs to canvas named: "backBuffer"
  objectIBelongTo[myPropertyName] = objectIBelongTo[myPropertyName.replace "Context", ""].getContext "2d"

# used to clip any subsequent drawing on the context
# to the dirty rectangle.
CanvasRenderingContext2D::clipToRectangle = (al,at,w,h) ->
  @beginPath()
  @moveTo Math.round(al), Math.round(at)
  @lineTo Math.round(al + w), Math.round(at)
  @lineTo Math.round(al + w), Math.round(at + h)
  @lineTo Math.round(al), Math.round(at + h)
  @lineTo Math.round(al), Math.round(at)
  @closePath()
  @clip()

# Direct rounded-rect painting, mirroring SWCanvas's non-standard direct-call API
# (fillRoundRect / strokeRoundRect) so widget code speaks ONE vocabulary on both
# backends: on SWCanvas these names reach its dedicated rounded-rect rasterizers
# (fast for solid colour + source-over + uniform scale; SWCanvas has no standard
# roundRect at all, and its path pipeline never fast-paths), while the native
# canvas gets these path-based polyfills over the standard roundRect(). The
# polyfills clobber the context's current default path (SWCanvas's originals
# don't touch it) — callers treat these as self-contained paint calls.
#
# The ONE crisp spelling, valid on both backends at every ceilPixelRatio (the
# stroke half relies on SWCanvas >= 131aaac, where the 1px stroke's corners
# share the edges' snapped pixel frame):
#   fill the widget box:              fillRoundRect 0, 0, w, h, r
#   1-logical-px ring just inside:    strokeRoundRect 0.5, 0.5, w - 1, h - 1, r
CanvasRenderingContext2D::fillRoundRect = (x, y, w, h, radius) ->
  @beginPath()
  @roundRect x, y, w, h, radius
  @fill()

CanvasRenderingContext2D::strokeRoundRect = (x, y, w, h, radius) ->
  @beginPath()
  @roundRect x, y, w, h, radius
  @stroke()

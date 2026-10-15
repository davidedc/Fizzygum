# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

CanvasRenderingContext2D::useLogicalPixelsUntilRestore = ->
  @scale ceilPixelRatio, ceilPixelRatio

CanvasRenderingContext2D::rebuildDerivedValue = (objectIBelongTo, myPropertyName) ->
  # re-generate a context from the copied canvas. Assumes the canvas lives in a
  # property named like this context property but without "Context"
  # e.g. "backBufferContext" -> belongs to canvas named: "backBuffer"
  objectIBelongTo[myPropertyName] = objectIBelongTo[myPropertyName.replace "Context", ""].getContext "2d"

# used to clip any subsequent drawing on the context
# to the damage rectangle.
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
# (the stroke is fast for solid colour + source-over + uniform scale; its path
# pipeline never fast-paths), while the native canvas gets these path-based
# polyfills over the standard roundRect(). The polyfills clobber the context's
# current default path (SWCanvas's originals don't touch it) — callers treat
# these as self-contained paint calls.
#
# `radii` reads the same on both backends — HTML5 roundRect()'s: one radius, or
# per-corner radii in CSS border-radius order [topLeft, topRight, bottomRight,
# bottomLeft], so `[r, r, 0, 0]` rounds only the top corners (a window title
# bar). On SWCanvas each corner of a per-corner rect is pixel-identical to the
# same corner of a uniformly rounded one.
#
# The ONE crisp spelling, valid on both backends at every ceilPixelRatio (the
# stroke half relies on SWCanvas >= 131aaac, where the 1px stroke's corners
# share the edges' snapped pixel frame):
#   fill the widget box:              fillRoundRect 0, 0, w, h, r
#   1-logical-px ring just inside:    strokeRoundRect 0.5, 0.5, w - 1, h - 1, r
CanvasRenderingContext2D::fillRoundRect = (x, y, w, h, radii) ->
  @beginPath()
  @roundRect x, y, w, h, radii
  @fill()

CanvasRenderingContext2D::strokeRoundRect = (x, y, w, h, radii) ->
  @beginPath()
  @roundRect x, y, w, h, radii
  @stroke()

# Stadium (capsule): the w×h box with its shorter axis fully rounded — two
# half-circle caps of radius min(w,h)/2 joined by a rectangular body, the
# orientation implied by the longer axis, so ONE call covers vertical and
# horizontal sliders. Both backends draw the same shape the same way: a
# roundRect path at the degenerate radius min(w,h)/2, which a pixel-center-
# sampling fill turns into a correct stadium — SWCanvas fills it through its
# generic path pipeline, the native polyfill through the standard roundRect.
# SWCanvas pins the contract (exact-box crisp fill, single-blend at any
# alpha, tier-0 clip, transforms) in its tests/core/053.
# Crisp spelling: fill the widget box = fillStadium 0, 0, w, h
CanvasRenderingContext2D::fillStadium = (x, y, w, h) ->
  @beginPath()
  @roundRect x, y, w, h, Math.min(w, h) / 2
  @fill()

# Direct circle stroke (annulus at the current lineWidth), mirroring
# SWCanvas's strokeCircle so ring-shaped chrome (window title-bar buttons)
# speaks the same vocabulary on both backends. On SWCanvas the thick-stroke
# path rasterizes the exact analytic annulus [r−lw/2, r+lw/2]; the native
# polyfill strokes the equivalent arc path.
CanvasRenderingContext2D::strokeCircle = (cx, cy, r) ->
  @beginPath()
  @arc cx, cy, r, 0, 2 * Math.PI
  @stroke()

# Direct circle fill. Crisp spelling: a circle inscribed in an s×s box at x,y
# is fillCircle x + s/2, y + s/2, s/2 — it covers exactly the box on SWCanvas.
# Uniform-scale contexts hit SWCanvas's direct renderer; a non-uniform
# transform is gated upstream onto the generic pipeline, which draws the
# correct ellipse — the same shape this polyfill's arc path produces natively.
CanvasRenderingContext2D::fillCircle = (cx, cy, r) ->
  @beginPath()
  @arc cx, cy, r, 0, 2 * Math.PI
  @fill()

# Direct single-segment line stroke, mirroring SWCanvas's strokeLine (its
# dedicated line rasterizer, hairline faintness rule included) so straight
# line work speaks the same vocabulary on both backends; the native polyfill
# strokes the equivalent two-point path.
CanvasRenderingContext2D::strokeLine = (x1, y1, x2, y2) ->
  @beginPath()
  @moveTo x1, y1
  @lineTo x2, y2
  @stroke()

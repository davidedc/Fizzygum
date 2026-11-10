# NativeValueKinds — the ONE home of native-type detection, SHARED by the two
# object-graph walkers (the Serializer here in src/serialization/ and the
# Duplicator in src/duplication/), so their taxonomies can never drift apart.
# The backend-sensitive kinds are duck-typed: the SWCanvas types have no stable
# globals to instanceof against, so canvases and gradients are recognised by
# their protocol instead.
class NativeValueKinds

  @isArray: (obj) ->
    Array.isArray obj

  @isMap: (obj) ->
    obj instanceof Map

  @isSet: (obj) ->
    obj instanceof Set

  @isDate: (obj) ->
    obj instanceof Date

  @isImage: (obj) ->
    window.HTMLImageElement? and obj instanceof HTMLImageElement

  # HTMLCanvasElement OR SWCanvasElement — duck-typed so it catches BOTH backends.
  @isCanvasLike: (obj) ->
    (typeof obj.getContext is "function") and (typeof obj.toDataURL is "function")

  # A canvas's 2D context, CanvasRenderingContext2D OR the SWCanvas one — duck-typed by the drawing
  # protocol both carry (the SWCanvas context holds no `.canvas` back to its canvas).
  @isCanvasContext: (obj) ->
    (typeof obj.fillRect is "function") and (typeof obj.getImageData is "function")

  # Is the value `holder[property]` DERIVED there -- one the holder rebuilds rather than carries, which
  # the Serializer leaves out and the Duplicator rebuilds on the copy (its rebuildDerivedValue)? A
  # value answering rebuildDerivedValue is, except a canvas context: that one is derived only BESIDE
  # the canvas it is drawn from, held as `<name>Context` next to that canvas `<name>` on the same
  # holder -- the place its rebuild reads the canvas from (CanvasRenderingContext2D
  # ::rebuildDerivedValue). "Drawn from" is asked of the canvas, since the SWCanvas context holds no
  # `.canvas`: a canvas keeps ONE 2D context on both backends, so its getContext "2d" is this very
  # one. Anywhere else (an inspector's subject, a cache's slot) a context is a page object like any
  # other: a save refuses it, a copy keeps it by reference (Duplicator._duplicate). The one answer
  # both walkers ask, so they cannot disagree about it.
  @isDerivedAt: (holder, property) ->
    value = holder[property]
    return false unless value? and typeof value is "object" and value.rebuildDerivedValue?
    return true unless NativeValueKinds.isCanvasContext value
    canvas = if property.endsWith "Context" then holder[property.replace "Context", ""]
    canvas? and NativeValueKinds.isCanvasLike(canvas) and canvas.getContext("2d") is value

  @isVideo: (obj) ->
    window.HTMLVideoElement? and obj instanceof HTMLVideoElement

  # CanvasGradient OR an SWCanvas gradient — duck-typed via the one method every
  # gradient carries.
  @isGradientLike: (obj) ->
    typeof obj.addColorStop is "function"

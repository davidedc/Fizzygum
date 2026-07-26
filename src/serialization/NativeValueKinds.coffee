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

  @isVideo: (obj) ->
    window.HTMLVideoElement? and obj instanceof HTMLVideoElement

  # CanvasGradient OR an SWCanvas gradient — duck-typed via the one method every
  # gradient carries.
  @isGradientLike: (obj) ->
    typeof obj.addColorStop is "function"

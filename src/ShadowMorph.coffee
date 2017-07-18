# ShadowMorph /////////////////////////////////////////////////////////

class ShadowMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  targetMorph: null
  offset: null
  alpha: 0
  color: null

  # alpha should be between zero (transparent)
  # and one (fully opaque)
  constructor: (@targetMorph, @offset = new Point(7, 7), @alpha = 0.2, @color = new Color(0, 0, 0)) ->
    # console.log "creating shadow morph"
    super()
    @bounds.debugIfFloats()
    @offset.debugIfFloats()

  reLayout: ->
    return

  fullPaintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle = @fullClippedBounds(), noShadow = false) ->
    return

  createRefreshOrGetBackBuffer: ->
    return

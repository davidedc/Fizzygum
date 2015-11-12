# ShadowMorph /////////////////////////////////////////////////////////
# REQUIRES BackingStoreMixin

class ShadowMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype
  @augmentWith BackingStoreMixin

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

  setLayoutBeforeUpdatingBackingStore: ->
    # console.log "shadow morph update rendering"
    super()
    fb = @targetMorph.boundsIncludingChildrenNoShadow()
    @silentSetExtent fb.extent().add(@targetMorph.shadowBlur * 2)
    if WorldMorph.preferencesAndSettings.useBlurredShadows and  !WorldMorph.preferencesAndSettings.isFlat
      @silentSetPosition fb.origin.add(@offset).subtract(@targetMorph.shadowBlur)
    else
      @silentSetPosition fb.origin.add(@offset)
    @bounds.debugIfFloats()
    @offset.debugIfFloats()

  isTransparentAt: (aPoint) ->
    @bounds.debugIfFloats()
    if @bounds.containsPoint(aPoint)
      return false  if @texture
      point = aPoint.subtract(@bounds.origin)
      context = @image.getContext("2d")
      data = context.getImageData(Math.floor(point.x)*pixelRatio, Math.floor(point.y)*pixelRatio, 1, 1)
      # check the 4th byte - the Alpha (RGBA)
      return data.data[3] is 0
    false

  # no changes of position or extent
  updateBackingStore: ->
    @bounds.debugIfFloats()
    if WorldMorph.preferencesAndSettings.useBlurredShadows and  !WorldMorph.preferencesAndSettings.isFlat
      @image = @targetMorph.shadowImage(@offset, @color, true)
    else
      @image = @targetMorph.shadowImage(@offset, @color, false)
    @bounds.debugIfFloats()
    @offset.debugIfFloats()


    
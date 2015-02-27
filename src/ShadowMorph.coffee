# ShadowMorph /////////////////////////////////////////////////////////

class ShadowMorph extends Morph
  targetMorph: null
  offset: null
  alpha: 0
  color: null

  constructor: (@targetMorph, offset, alpha, color) ->
    # console.log "creating shadow morph"
    super()
    @offset = offset or new Point(7, 7)
    @alpha = alpha or ((if (alpha is 0) then 0 else 0.2))
    @color = color or new Color(0, 0, 0)

  setLayoutBeforeUpdatingBackingStore: ->
    # console.log "shadow morph update rendering"
    fb = @targetMorph.boundsIncludingChildrenNoShadow()
    @silentSetExtent fb.extent().add(@targetMorph.shadowBlur * 2)
    if WorldMorph.preferencesAndSettings.useBlurredShadows and  !WorldMorph.preferencesAndSettings.isFlat
      @silentSetPosition fb.origin.add(@offset).subtract(@targetMorph.shadowBlur)
    else
      @silentSetPosition fb.origin.add(@offset)

  # no changes of position or extent
  updateBackingStore: ->
    if WorldMorph.preferencesAndSettings.useBlurredShadows and  !WorldMorph.preferencesAndSettings.isFlat
      @image = @targetMorph.shadowImageBlurred(@offset, @color)
    else
      @image = @targetMorph.shadowImage(@offset, @color)
  
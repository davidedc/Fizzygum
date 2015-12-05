# ShadowMorph /////////////////////////////////////////////////////////
# REQUIRES BackBufferMixin

class ShadowMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype
  @augmentWith BackBufferMixin

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
    # console.log "shadow morph update rendering"
    super()
    fb = @targetMorph.fullBoundsNoShadow()
    @silentSetExtent fb.extent().add(@targetMorph.shadowBlur * 2)
    if WorldMorph.preferencesAndSettings.useBlurredShadows and  !WorldMorph.preferencesAndSettings.isFlat
      @silentFullMoveTo fb.origin.add(@offset).subtract(@targetMorph.shadowBlur)
    else
      @silentFullMoveTo fb.origin.add(@offset)
    @bounds.debugIfFloats()
    @offset.debugIfFloats()
    @children.forEach (child) ->
      child.parentHasReLayouted()

  repaintBackBufferIfNeeded: ->
    if !@backBufferIsPotentiallyDirty then return
    @backBufferIsPotentiallyDirty = false

    if @backBufferValidityChecker?
      if @backBufferValidityChecker.extent == @extent().toString()
        return

    @bounds.debugIfFloats()
    if WorldMorph.preferencesAndSettings.useBlurredShadows and  !WorldMorph.preferencesAndSettings.isFlat
      @backBuffer = @targetMorph.shadowImage(@offset, @color, true)
    else
      @backBuffer = @targetMorph.shadowImage(@offset, @color, false)
    @backBufferContext =  @backBuffer.getContext("2d")
    @bounds.debugIfFloats()
    @offset.debugIfFloats()

    @backBufferValidityChecker = new BackBufferValidityChecker()
    @backBufferValidityChecker.extent = @extent().toString()

    
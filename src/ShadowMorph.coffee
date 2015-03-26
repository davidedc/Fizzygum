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

  setLayoutBeforeUpdatingBackingStore: ->
    # console.log "shadow morph update rendering"
    fb = @targetMorph.boundsIncludingChildrenNoShadow()
    @silentSetExtent fb.extent().add(@targetMorph.shadowBlur * 2)
    if WorldMorph.preferencesAndSettings.useBlurredShadows and  !WorldMorph.preferencesAndSettings.isFlat
      @silentSetPosition fb.origin.add(@offset).subtract(@targetMorph.shadowBlur)
    else
      @silentSetPosition fb.origin.add(@offset)

  isTransparentAt: (aPoint) ->
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
    if WorldMorph.preferencesAndSettings.useBlurredShadows and  !WorldMorph.preferencesAndSettings.isFlat
      @image = @targetMorph.shadowImageBlurred(@offset, @color)
    else
      @image = @targetMorph.shadowImage(@offset, @color)

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by recursivelyBlit, which
  # eventually invokes blit.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  blit: (aCanvas, clippingRectangle) ->
    return null  if @isMinimised or !@isVisible or !@image?
    area = clippingRectangle.intersect(@bounds).round()
    # test whether anything that we are going to be drawing
    # is visible (i.e. within the clippingRectangle)
    if area.isNotEmpty()
      delta = @position().neg()
      src = area.copy().translateBy(delta).round()
      context = aCanvas.getContext("2d")
      context.globalAlpha = @alpha
      sl = src.left() * pixelRatio
      st = src.top() * pixelRatio
      al = area.left() * pixelRatio
      at = area.top() * pixelRatio
      w = Math.min(src.width() * pixelRatio, @image.width - sl)
      h = Math.min(src.height() * pixelRatio, @image.height - st)
      return null  if w < 1 or h < 1

      context.drawImage @image,
        Math.round(sl),
        Math.round(st),
        Math.round(w),
        Math.round(h),
        Math.round(al),
        Math.round(at),
        Math.round(w),
        Math.round(h)

      if world.showRedraws
        randomR = Math.round(Math.random()*255)
        randomG = Math.round(Math.random()*255)
        randomB = Math.round(Math.random()*255)
        context.globalAlpha = 0.5
        context.fillStyle = "rgb("+randomR+","+randomG+","+randomB+")";
        context.fillRect(Math.round(al),Math.round(at),Math.round(w),Math.round(h));
    
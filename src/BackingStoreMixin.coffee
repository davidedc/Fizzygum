# //////////////////////////////////////////////////////////

# these comments below needed to figure out dependencies between classes
# REQUIRES globalFunctions

# some morphs (for example ColorPaletteMorph
# or SliderMorph) can control a target
# and they have the same function to attach
# targets. Not worth having this in the
# whole Morph hierarchy, so... ideal use
# of mixins here.

BackingStoreMixin =
  # klass properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: ->
    @addInstanceProperties
      silentUpdateBackingStore: ->
        # initialize my surface property
        @image = newCanvas(@extent().scaleBy pixelRatio)
        context = @image.getContext("2d")
        context.scale pixelRatio, pixelRatio
        context.fillStyle = @color.toString()
        context.fillRect 0, 0, @width(), @height()
        if @cachedTexture
          @drawCachedTexture()
        else @drawTexture @texture  if @texture

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

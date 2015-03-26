# BoxMorph ////////////////////////////////////////////////////////////

# I can have an optionally rounded border

class BoxMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  edge: null
  border: null

  constructor: (@edge = 4, border) ->
    @border = border or ((if (border is 0) then 0 else 2))
    super()

  isTransparentAt: (aPoint) ->
    # first quickly check if the point is even
    # within the bounding box
    if !@bounds.containsPoint aPoint
      return true
 
    thisMorphPosition = @position()
    radius = Math.max(@edge - @border, 0)
 
    relativePoint = new Point(aPoint.x - thisMorphPosition.x, aPoint.y - thisMorphPosition.y)

    # top left corner
    if relativePoint.x < radius and relativePoint.y < radius
      if relativePoint.distanceTo(new Point radius,radius) > radius
        return true

    # top right corner
    else if relativePoint.x > @width() - radius and relativePoint.y < radius
      if relativePoint.distanceTo(new Point @width() - radius,radius) > radius
        return true

    # bottom left corner
    else if relativePoint.x < radius and relativePoint.y > @height() - radius
      if relativePoint.distanceTo(new Point radius, @height() - radius) > radius
        return true

    # bottom right corner
    else if relativePoint.x > @width() - radius and relativePoint.y > @height() - radius
      if relativePoint.distanceTo(new Point @width() - radius, @height() - radius) > radius
        return true


    return false
  
  silentUpdateBackingStore: ->
    #console.log 'BoxMorph doing nothing with the backing store'

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by recursivelyBlit, which
  # eventually invokes blit.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  blit: (aCanvas, clippingRectangle) ->
    return null  if @isMinimised or !@isVisible
    area = clippingRectangle.intersect(@bounds).round()
    # test whether anything that we are going to be drawing
    # is visible (i.e. within the clippingRectangle)
    if area.isNotEmpty()
      delta = @position().neg()
      src = area.copy().translateBy(delta).round()
      context = aCanvas.getContext("2d")
      sl = src.left() * pixelRatio
      st = src.top() * pixelRatio
      al = area.left() * pixelRatio
      at = area.top() * pixelRatio
      w = Math.min(src.width() * pixelRatio, @width() * pixelRatio - sl)
      h = Math.min(src.height() * pixelRatio, @height() * pixelRatio - st)
      return null  if w < 1 or h < 1

      # initialize my surface property
      #@image = newCanvas(@extent().scaleBy pixelRatio)
      #context = @image.getContext("2d")
      #context.scale pixelRatio, pixelRatio

      context.save()

      # clip out the dirty rectangle as we are
      # going to paint the whole of the box
      context.beginPath()
      context.moveTo(Math.round(al), Math.round(at))
      context.lineTo(Math.round(al) + Math.round(w), Math.round(at))
      context.lineTo(Math.round(al) + Math.round(w), Math.round(at) + Math.round(h))
      context.lineTo(Math.round(al), Math.round(at) + Math.round(h))
      context.lineTo(Math.round(al), Math.round(at))
      context.closePath()
      context.clip()

      context.globalAlpha = @alpha

      context.scale pixelRatio, pixelRatio
      morphPosition = @position()
      context.translate morphPosition.x, morphPosition.y
      context.fillStyle = @color.toString()
      
      context.beginPath()
      @outlinePath context, Math.max(@edge - @border, 0), @border
      context.closePath()
      context.fill()

      context.restore()

      ###
      if world.showRedraws
        randomR = Math.round(Math.random()*255)
        randomG = Math.round(Math.random()*255)
        randomB = Math.round(Math.random()*255)

        context.save()
        context.globalAlpha = 0.5
        context.fillStyle = "rgb("+randomR+","+randomG+","+randomB+")";
        context.fillRect  Math.round(al),
            Math.round(at),
            Math.round(w),
            Math.round(h)
        context.restore()
      ###

  
  outlinePath: (context, radius, inset) ->
    offset = radius + inset
    w = @width()
    h = @height()
    # top left:
    context.arc offset, offset, radius, radians(-180), radians(-90), false
    # top right:
    context.arc w - offset, offset, radius, radians(-90), radians(-0), false
    # bottom right:
    context.arc w - offset, h - offset, radius, radians(0), radians(90), false
    # bottom left:
    context.arc offset, h - offset, radius, radians(90), radians(180), false

  cornerSizePopout: (menuItem)->
    @prompt menuItem.parent.title + "\ncorner\nsize:",
      @,
      "setCornerSize",
      @edge.toString(),
      null,
      0,
      100,
      true

  
  # BoxMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()

    menu.addItem "border width...", @, (->
      @prompt menu.title + "\nborder\nwidth:",
        @setBorderWidth,
        @border.toString(),
        null,
        0,
        100,
        true
    ), "set the border's\nline size"
    menu.addItem "corner size...", @, "cornerSizePopout", "set the corner's\nradius"
    menu
  
  setBorderWidth: (sizeOrMorphGivingSize) ->
    if sizeOrMorphGivingSize.getValue?
      size = sizeOrMorphGivingSize.getValue()
    else
      size = sizeOrMorphGivingSize

    # for context menu demo purposes
    if typeof size is "number"
      @border = Math.max(size, 0)
    else
      newSize = parseFloat(size)
      @border = Math.max(newSize, 0)  unless isNaN(newSize)
    @updateBackingStore()
    @changed()
  
  
  setCornerSize: (sizeOrMorphGivingSize, morphGivingSize) ->
    if morphGivingSize?.getValue?
      size = morphGivingSize.getValue()
    else
      size = sizeOrMorphGivingSize

    # for context menu demo purposes
    if typeof size is "number"
      @edge = Math.max(size, 0)
    else
      newSize = parseFloat(size)
      @edge = Math.max(newSize, 0)  unless isNaN(newSize)
    @updateBackingStore()
    @changed()
  
  colorSetters: ->
    # for context menu demo purposes
    ["color"]
  
  numericalSetters: ->
    # for context menu demo purposes
    list = super()
    list.push "setBorderWidth", "setCornerSize"
    list

# BoxMorph ////////////////////////////////////////////////////////////

# I can have an optionally rounded border

class BoxMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  cornerRadius: null

  constructor: (@cornerRadius = 4) ->
    super()

  isTransparentAt: (aPoint) ->
    # first quickly check if the point is even
    # within the bounding box
    if !@bounds.containsPoint aPoint
      return true
 
    thisMorphPosition = @position()
    radius = Math.max(@cornerRadius, 0)
 
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
      @outlinePath context, Math.max(@cornerRadius, 0)
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

  
  outlinePath: (context, radius) ->
    offset = radius
    w = @width()
    h = @height()
    # top left:
    context.arc offset, offset, radius, degreesToRadians(-180), degreesToRadians(-90), false
    # top right:
    context.arc w - offset, offset, radius, degreesToRadians(-90), degreesToRadians(-0), false
    # bottom right:
    context.arc w - offset, h - offset, radius, degreesToRadians(0), degreesToRadians(90), false
    # bottom left:
    context.arc offset, h - offset, radius, degreesToRadians(90), degreesToRadians(180), false

  cornerRadiusPopout: (menuItem)->
    @prompt menuItem.parent.title + "\ncorner\nradius:",
      @,
      "setCornerRadius",
      @cornerRadius.toString(),
      null,
      0,
      100,
      true

  insetPosition: ->
    return @position().add(@cornerRadius - Math.round(@cornerRadius/Math.sqrt(2)))

  insetSpaceExtent: ->
    return @extent().subtract(2*(@cornerRadius - Math.round(@cornerRadius/Math.sqrt(2))))

  extentBasedOnInsetExtent: (insetMorph) ->
    return insetMorph.extent().add(2*(@cornerRadius - Math.round(@cornerRadius/Math.sqrt(2))))

  # there is another method almost equal to this
  # todo refactor
  choiceOfMorphToBePicked: (ignored, morphPickingUp) ->
    # this is what happens when "each" is
    # selected: we attach the selected morph
    debugger
    morphPickingUp.addInset @
    @isfloatDraggable = false
    if @ instanceof ScrollFrameMorph
      @adjustContentsBounds()
      @adjustScrollBars()
    else
      # you expect Morphs attached
      # inside a FrameMorph
      # to be floatDraggable out of it
      # (as opposed to the content of a ScrollFrameMorph)
      @isfloatDraggable = false
  
  # there is another method almost equal to this
  # todo refactor
  pickInset: ->
    choices = world.plausibleTargetAndDestinationMorphs(@)

    # my direct parent might be in the
    # options which is silly, leave that one out
    choicesExcludingParent = []
    choices.forEach (each) =>
      if each != @parent
        choicesExcludingParent.push each

    if choicesExcludingParent.length > 0
      menu = new MenuMorph(false, @, true, true, "choose Morph to put as inset:")
      choicesExcludingParent.forEach (each) =>
        menu.addItem each.toString().slice(0, 50), true, each, "choiceOfMorphToBePicked"
    else
      # the ideal would be to not show the
      # "attach" menu entry at all but for the
      # time being it's quite costly to
      # find the eligible morphs to attach
      # to, so for now let's just calculate
      # this list if the user invokes the
      # command, and if there are no good
      # morphs then show some kind of message.
      menu = new MenuMorph(false, @, true, true, "no morphs to pick")
    menu.popUpAtHand(@firstContainerMenu())


  # BoxMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()

    menu.addItem "corner radius...", true, @, "cornerRadiusPopout", "set the corner's\nradius"
    menu.addItem "pick inset...", true, @, "pickInset", "put a morph as inset"
    menu
  
  
  setCornerRadius: (radiusOrMorphGivingRadius, morphGivingRadius) ->
    if morphGivingRadius?.getValue?
      radius = morphGivingRadius.getValue()
    else
      radius = radiusOrMorphGivingRadius

    # for context menu demo purposes
    if typeof radius is "number"
      @cornerRadius = Math.max(radius, 0)
    else
      newRadius = parseFloat(radius)
      @cornerRadius = Math.max(newRadius, 0)  unless isNaN(newRadius)
    @updateBackingStore()
    @layoutInset()
    @changed()
  
  colorSetters: ->
    # for context menu demo purposes
    ["color"]
  
  numericalSetters: ->
    # for context menu demo purposes
    list = super()
    list.push "setCornerRadius"
    list

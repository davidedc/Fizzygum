# HandleMorph ////////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

# I am a resize / move handle that can be attached to any Morph

class HandleMorph extends Morph
  constructor: (target, minX, minY, insetX, insetY, type) ->
    # if insetY is missing, it will be the same as insetX
    @init target, minX, minY, insetX, insetY, type

# HandleMorph instance creation:
HandleMorph::init = (target, minX, minY, insetX, insetY, type) ->
  size = MorphicPreferences.handleSize
  @target = target or null
  @minExtent = new Point(minX or 0, minY or 0)
  @inset = new Point(insetX or 0, insetY or insetX or 0)
  @type = type or "resize" # can also be 'move'
  super()
  @color = new Color(255, 255, 255)
  @isDraggable = false
  @noticesTransparentClick = true
  @setExtent new Point(size, size)


# HandleMorph drawing:
HandleMorph::drawNew = ->
  @normalImage = newCanvas(@extent())
  @highlightImage = newCanvas(@extent())
  @drawOnCanvas @normalImage, @color, new Color(100, 100, 100)
  @drawOnCanvas @highlightImage, new Color(100, 100, 255), new Color(255, 255, 255)
  @image = @normalImage
  if @target
    @setPosition @target.bottomRight().subtract(@extent().add(@inset))
    @target.add this
    @target.changed()

HandleMorph::drawOnCanvas = (aCanvas, color, shadowColor) ->
  context = aCanvas.getContext("2d")
  p1 = undefined
  p11 = undefined
  p2 = undefined
  p22 = undefined
  i = undefined
  context.lineWidth = 1
  context.lineCap = "round"
  context.strokeStyle = color.toString()
  if @type is "move"
    p1 = @bottomLeft().subtract(@position())
    p11 = p1.copy()
    p2 = @topRight().subtract(@position())
    p22 = p2.copy()
    i = 0
    while i <= @height()
      p11.y = p1.y - i
      p22.y = p2.y - i
      context.beginPath()
      context.moveTo p11.x, p11.y
      context.lineTo p22.x, p22.y
      context.closePath()
      context.stroke()
      i = i + 6
  p1 = @bottomLeft().subtract(@position())
  p11 = p1.copy()
  p2 = @topRight().subtract(@position())
  p22 = p2.copy()
  i = 0
  while i <= @width()
    p11.x = p1.x + i
    p22.x = p2.x + i
    context.beginPath()
    context.moveTo p11.x, p11.y
    context.lineTo p22.x, p22.y
    context.closePath()
    context.stroke()
    i = i + 6
  context.strokeStyle = shadowColor.toString()
  if @type is "move"
    p1 = @bottomLeft().subtract(@position())
    p11 = p1.copy()
    p2 = @topRight().subtract(@position())
    p22 = p2.copy()
    i = -2
    while i <= @height()
      p11.y = p1.y - i
      p22.y = p2.y - i
      context.beginPath()
      context.moveTo p11.x, p11.y
      context.lineTo p22.x, p22.y
      context.closePath()
      context.stroke()
      i = i + 6
  p1 = @bottomLeft().subtract(@position())
  p11 = p1.copy()
  p2 = @topRight().subtract(@position())
  p22 = p2.copy()
  i = 2
  while i <= @width()
    p11.x = p1.x + i
    p22.x = p2.x + i
    context.beginPath()
    context.moveTo p11.x, p11.y
    context.lineTo p22.x, p22.y
    context.closePath()
    context.stroke()
    i = i + 6


# HandleMorph stepping:
HandleMorph::step = null
HandleMorph::mouseDownLeft = (pos) ->
  world = @root()
  offset = pos.subtract(@bounds.origin)
  myself = this
  return null  unless @target
  @step = ->
    newPos = undefined
    newExt = undefined
    if world.hand.mouseButton
      newPos = world.hand.bounds.origin.copy().subtract(offset)
      if @type is "resize"
        newExt = newPos.add(myself.extent().add(myself.inset)).subtract(myself.target.bounds.origin)
        newExt = newExt.max(myself.minExtent)
        myself.target.setExtent newExt
        myself.setPosition myself.target.bottomRight().subtract(myself.extent().add(myself.inset))
      else # type === 'move'
        myself.target.setPosition newPos.subtract(@target.extent()).add(@extent())
    else
      @step = null
  
  unless @target.step
    @target.step = noOpFunction


# HandleMorph dragging and dropping:
HandleMorph::rootForGrab = ->
  this


# HandleMorph events:
HandleMorph::mouseEnter = ->
  @image = @highlightImage
  @changed()

HandleMorph::mouseLeave = ->
  @image = @normalImage
  @changed()


# HandleMorph duplicating:
HandleMorph::copyRecordingReferences = (dict) ->
  
  # inherited, see comment in Morph
  c = super dict
  c.target = (dict[@target])  if c.target and dict[@target]
  c


# HandleMorph menu:
HandleMorph::attach = ->
  choices = @overlappedMorphs()
  menu = new MenuMorph(this, "choose target:")
  myself = this
  choices.forEach (each) ->
    menu.addItem each.toString().slice(0, 50), ->
      myself.isDraggable = false
      myself.target = each
      myself.drawNew()
      myself.noticesTransparentClick = true
  
  
  menu.popUpAtHand @world()  if choices.length > 0

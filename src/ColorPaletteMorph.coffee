# ColorPaletteMorph ///////////////////////////////////////////////////

class ColorPaletteMorph extends Morph
  constructor: (target, sizePoint) ->
    @init target or null, sizePoint or new Point(80, 50)

# ColorPaletteMorph instance creation:
ColorPaletteMorph::init = (target, size) ->
  super()
  @target = target
  @targetSetter = "color"
  @silentSetExtent size
  @choice = null
  @drawNew()

ColorPaletteMorph::drawNew = ->
  context = undefined
  ext = undefined
  x = undefined
  y = undefined
  h = undefined
  l = undefined
  ext = @extent()
  @image = newCanvas(@extent())
  context = @image.getContext("2d")
  @choice = new Color()
  x = 0
  while x <= ext.x
    h = 360 * x / ext.x
    y = 0
    while y <= ext.y
      l = 100 - (y / ext.y * 100)
      context.fillStyle = "hsl(" + h + ",100%," + l + "%)"
      context.fillRect x, y, 1, 1
      y += 1
    x += 1

ColorPaletteMorph::mouseMove = (pos) ->
  @choice = @getPixelColor(pos)
  @updateTarget()

ColorPaletteMorph::mouseDownLeft = (pos) ->
  @choice = @getPixelColor(pos)
  @updateTarget()

ColorPaletteMorph::updateTarget = ->
  if @target instanceof Morph and @choice isnt null
    if @target[@targetSetter] instanceof Function
      @target[@targetSetter] @choice
    else
      @target[@targetSetter] = @choice
      @target.drawNew()
      @target.changed()


# ColorPaletteMorph duplicating:
ColorPaletteMorph::copyRecordingReferences = (dict) ->
  
  # inherited, see comment in Morph
  c = super dict
  c.target = (dict[@target])  if c.target and dict[@target]
  c


# ColorPaletteMorph menu:
ColorPaletteMorph::developersMenu = ->
  menu = super()
  menu.addLine()
  menu.addItem "set target", "setTarget", "choose another morph\nwhose color property\n will be" + " controlled by this one"
  menu

ColorPaletteMorph::setTarget = ->
  choices = @overlappedMorphs()
  menu = new MenuMorph(this, "choose target:")
  myself = this
  choices.push @world()
  choices.forEach (each) ->
    menu.addItem each.toString().slice(0, 50), ->
      myself.target = each
      myself.setTargetSetter()


  if choices.length is 1
    @target = choices[0]
    @setTargetSetter()
  else menu.popUpAtHand @world()  if choices.length > 0

ColorPaletteMorph::setTargetSetter = ->
  choices = @target.colorSetters()
  menu = new MenuMorph(this, "choose target property:")
  myself = this
  choices.forEach (each) ->
    menu.addItem each, ->
      myself.targetSetter = each


  if choices.length is 1
    @targetSetter = choices[0]
  else menu.popUpAtHand @world()  if choices.length > 0

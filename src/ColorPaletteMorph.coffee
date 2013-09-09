# ColorPaletteMorph ///////////////////////////////////////////////////

class ColorPaletteMorph extends Morph

  target: null
  targetSetter: "color"
  choice: null

  constructor: (@target = null, sizePoint) ->
    super()
    @silentSetExtent sizePoint or new Point(80, 50)
    @updateRendering()
  
  updateRendering: ->
    ext = @extent()
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    @choice = new Color()
    for x in [0..ext.x]
      h = 360 * x / ext.x
      y = 0
      for y in [0..ext.y]
        l = 100 - (y / ext.y * 100)
        # see link below for alternatives on how to set a single
        # pixel color.
        # You should really be using putImageData of the whole buffer
        # here anyways. But this is clearer.
        # http://stackoverflow.com/questions/4899799/whats-the-best-way-to-set-a-single-pixel-in-an-html5-canvas
        context.fillStyle = "hsl(" + h + ",100%," + l + "%)"
        context.fillRect x, y, 1, 1
  
  mouseMove: (pos) ->
    @choice = @getPixelColor(pos)
    @updateTarget()
  
  mouseDownLeft: (pos) ->
    @choice = @getPixelColor(pos)
    @updateTarget()
  
  updateTarget: ->
    if @target instanceof Morph and @choice isnt null
      if @target[@targetSetter] instanceof Function
        @target[@targetSetter] @choice
      else
        @target[@targetSetter] = @choice
        @target.updateRendering()
        @target.changed()
  
  
  # ColorPaletteMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.target = (dict[@target])  if c.target and dict[@target]
    c
  
  # ColorPaletteMorph menu:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "set target", "setTarget", "choose another morph\nwhose color property\n will be" + " controlled by this one"
    menu
  
  setTarget: ->
    choices = @overlappedMorphs()
    menu = new MenuMorph(@, "choose target:")
    choices.push @world()
    choices.forEach (each) =>
      menu.addItem each.toString().slice(0, 50), =>
        @target = each
        @setTargetSetter()
    if choices.length is 1
      @target = choices[0]
      @setTargetSetter()
    else menu.popUpAtHand @world()  if choices.length
  
  setTargetSetter: ->
    choices = @target.colorSetters()
    menu = new MenuMorph(@, "choose target property:")
    choices.forEach (each) =>
      menu.addItem each, =>
        @targetSetter = each
    if choices.length is 1
      @targetSetter = choices[0]
    else menu.popUpAtHand @world()  if choices.length

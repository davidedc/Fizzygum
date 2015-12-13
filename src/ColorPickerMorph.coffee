# ColorPickerMorph ///////////////////////////////////////////////////

class ColorPickerMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  # pattern: all the children should be declared here
  # the reason is that when you duplicate a morph
  # , the duplicated morph needs to have the handles
  # that will be duplicated. If you don't list them
  # here, then they need to be initialised in the
  # constructor. But actually they might not be
  # initialised in the constructor if a "lazy initialisation"
  # approach is taken. So it's good practice
  # to list them here so they can be duplicated either way.
  feedback: null
  choice: null
  colorPalette: null
  grayPalette: null

  constructor: (defaultColor) ->
    @choice = defaultColor or new Color(255, 255, 255)
    super()
    @color = new Color(255, 255, 255)
    @rawSetExtent new Point(80, 80)

  reLayout: ->
    super()
    @buildSubmorphs()
    @notifyChildrenThatParentHasReLayouted()

  buildSubmorphs: ->
    @fullDestroyChildren()
    @feedback = new RectangleMorph(new Point(20, 20), @choice)
    @colorPalette = new ColorPaletteMorph(@feedback, new Point(@width(), 50))
    @grayPalette = new GrayPaletteMorph(@feedback, new Point(@width(), 5))
    @colorPalette.fullRawMoveTo @position()
    @add @colorPalette
    @grayPalette.fullRawMoveTo @colorPalette.bottomLeft()
    @add @grayPalette
    x = (@grayPalette.left() + Math.floor((@grayPalette.width() - @feedback.width()) / 2))
    y = @grayPalette.bottom() + Math.floor((@bottom() - @grayPalette.bottom() - @feedback.height()) / 2)
    @feedback.fullRawMoveTo new Point(x, y)
    @add @feedback

  imBeingAddedTo: (newParentMorph) ->
  
  getColor: ->
    @feedback.color
  
  rootForGrab: ->
    @

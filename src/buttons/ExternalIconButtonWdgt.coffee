# sends a message to a target object when pressed.
# Takes the shape of an icon, and can also host
# a morph to be used as "face"
#
# You could achieve something similar by having
# an empty button containing an icon, but changing
# the color of a face belonging to a button is
# not yet supported.
# i.e. this is currently the simplest way to change the color
# of a non-rectangular button.

class ExternalIconButtonWdgt extends EmptyButtonMorph


  constructor: (@target) ->
    # can't set the parent as the target directly because this morph
    # might not have a parent yet.
    super true, @, 'actOnClick', new Widget()
    @color_hover = new Color 255,153,0
    @color_pressed = @color_hover
    @appearance = new ExternalIconAppearance @
    @toolTipMessage = "make this window droppable\ninto other documents"


  actOnClick: ->
    debugger
    if @parent?.parent?
      if (@parent.parent instanceof WindowWdgt)
        @parent.parent.makeInternal()


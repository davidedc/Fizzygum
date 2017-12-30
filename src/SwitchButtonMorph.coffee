# SwitchButtonMorph ////////////////////////////////////////////////////////


class SwitchButtonMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  buttons: nil
 
  # careful: Objects are shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color 192, 192, 192
  # see note above about Colors and shared objects
  pressColor: new Color 128, 128, 128
 
  closesUnpinnedMenus: true
  
  buttonShown: 0

  # overrides to superclass
  color: new Color 255, 255, 255

  constructor: (@buttons) ->

    # additional properties:

    super()

    #@color = new Color 255, 152, 152
    #@color = new Color 255, 255, 255
    for eachButton in @buttons
      @add eachButton
    @layoutSubmorphs()
  
  layoutSubmorphs: (morphStartingTheChange = nil) ->
    super()
  # so that when you duplicate a "selected" toggle
  # and you pick it up and you attach it somewhere else
  # it gets automatically unselected
  imBeingAddedTo: ->
    @resetSwitchButton()
    counter = 0
    for eachButton in @buttons
      if eachButton.parent == @
        eachButton.setBounds @bounds
        if counter % @buttons.length == @buttonShown
          eachButton.show()
        else
          eachButton.hide()
      counter++

  # TODO
  getTextDescription: ->

  

  mouseClickLeft: ->
    @buttonShown++
    @buttonShown = @buttonShown % @buttons.length

    @layoutSubmorphs()
    @escalateEvent "mouseClickLeft", @

  resetSwitchButton: ->
    @buttonShown = 0
    @layoutSubmorphs()

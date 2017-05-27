# RadioButtonsHolderMorph ////////////////////////////////////////////////////////


class RadioButtonsHolderMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  wantsButtonsToBehaveLikeRadioButtons: true

  constructor: ->
  	super()
  	@appearance = new RectangularAppearance @


  mouseClickLeft: (morphThatFired) ->
    for eachChild in @children
    	if eachChild != morphThatFired
    		eachChild.resetSwitchButton?()
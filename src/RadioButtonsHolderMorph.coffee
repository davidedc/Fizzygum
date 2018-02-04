# RadioButtonsHolderMorph ////////////////////////////////////////////////////////


class RadioButtonsHolderMorph extends Morph

  wantsButtonsToBehaveLikeRadioButtons: true
  allowsRadioButtonsToBeAllDisabled: true
  color: new Color 0,0,0,0.2

  constructor: ->
    super()
    @appearance = new RectangularAppearance @


  mouseClickLeft: (morphThatFired) ->
    for eachChild in @children
      if eachChild != morphThatFired
        eachChild.resetSwitchButton?()

  whichButtonSelected: ->
    for eachChild in @children
      if eachChild.isSelected()
        return eachChild
    return null

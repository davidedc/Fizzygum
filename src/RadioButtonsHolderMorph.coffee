class RadioButtonsHolderMorph extends Widget

  wantsButtonsToBehaveLikeRadioButtons: true
  allowsRadioButtonsToBeAllDisabled: true

  constructor: ->
    super()
    @appearance = new RectangularAppearance @
    @setColor new Color 230, 230, 230


  mouseClickLeft: (morphThatFired) ->
    for eachChild in @children
      if eachChild != morphThatFired
        eachChild.resetSwitchButton?()

  whichButtonSelected: ->
    @firstChildSuchThat (w) =>
      w.isSelected()

  unselectAll: ->
    if @allowsRadioButtonsToBeAllDisabled
      for eachChild in @children
        if eachChild.isSelected()
          eachChild.toggle()
    return null

class RadioButtonsHolderMorph extends Widget

  wantsButtonsToBehaveLikeRadioButtons: true
  allowsRadioButtonsToBeAllDisabled: true

  constructor: ->
    super()
    @appearance = new RectangularAppearance @
    @setColor new Color 230, 230, 230


  # TODO gross pattern break - usually mouseClickLeft has 9 params
  # none of which is a widget
  mouseClickLeft: (morphThatFired) ->
    for w in @children
      if w != morphThatFired
        w.resetSwitchButton?()

  whichButtonSelected: ->
    @firstChildSuchThat (w) =>
      w.isSelected()

  unselectAll: ->
    if @allowsRadioButtonsToBeAllDisabled
      for w in @children
        if w.isSelected()
          w.toggle()
    return null

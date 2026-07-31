class RadioButtonsHolderWdgt extends Widget

  wantsButtonsToBehaveLikeRadioButtons: true
  allowsRadioButtonsToBeAllDisabled: true

  constructor: ->
    super()
    @appearance = new RectangularAppearance @
    @setColor Color.create 230, 230, 230


  # TODO gross pattern break - usually mouseClickLeft has 9 params
  # none of which is a widget
  mouseClickLeft: (widgetThatFired) ->
    for w in @children
      if w != widgetThatFired
        w._resetSwitchButton?()

  whichButtonSelected: ->
    @firstChildSuchThat (w) =>
      w.isSelected()

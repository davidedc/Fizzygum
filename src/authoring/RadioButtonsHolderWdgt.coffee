class RadioButtonsHolderWdgt extends Widget

  wantsButtonsToBehaveLikeRadioButtons: true
  allowsRadioButtonsToBeAllDisabled: true

  constructor: ->
    super()
    @appearance = new RectangularAppearance @
    @setColor Color.create 230, 230, 230


  # A tool press means nothing above me, so the escalation stops here. It carries the pointer
  # POSITION in its first slot like every other mouseClickLeft — never the sender — so this
  # handler cannot tell WHICH of my switches fired and does not try: the switch names itself
  # through radioButtonWasSwitched below.
  mouseClickLeft: ->
    noOperation

  # ONE of my switches has just been switched BY A CLICK: the others go off, which is the whole of
  # what "radio" means here. Only the switch itself knows which one it is, so it tells me — a
  # handler reading the escalated click's first slot as the sender compares every child against a
  # Point, finds them all different, and turns the just-clicked one off along with the rest,
  # leaving the group with nothing selected at all.
  radioButtonWasSwitched: (whichOne) ->
    for w in @children
      w._resetSwitchButton?() unless w is whichOne

  whichButtonSelected: ->
    @firstChildSuchThat (w) =>
      w.isSelected()

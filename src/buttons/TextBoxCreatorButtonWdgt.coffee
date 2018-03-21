class TextBoxCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new TextIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "text box"

  createWidgetToBeHandled: ->
    switcheroo = new TextMorph2 "insert text here"
    switcheroo.isEditable = true
    switcheroo.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    switcheroo.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    switcheroo.alignMiddle()
    switcheroo.alignLeft()
    switcheroo.fullRawMoveTo @position()
    switcheroo.rawSetExtent new Point 150, 75
    return switcheroo

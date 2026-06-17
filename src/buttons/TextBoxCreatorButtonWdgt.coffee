class TextBoxCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "text box"

  createAppearance: -> new TextIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcheroo = new TextWdgt "insert text here"
    switcheroo.isEditable = true
    switcheroo.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    switcheroo.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    switcheroo.alignMiddle()
    switcheroo.alignLeft()
    switcheroo.fullRawMoveTo @position()
    switcheroo.rawSetExtent new Point 150, 75
    return switcheroo

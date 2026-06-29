class USAMapCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "USA map"

  createAppearance: -> new LittleUSAIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcheroo = new SimpleUSAMapIconWdgt
    switcheroo._applyExtentAndNotify new Point 230, 145
    switcheroo.setColor Color.create 183, 183, 183
    return switcheroo



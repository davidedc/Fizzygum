class WorldMapCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "world map"

  createAppearance: -> new LittleWorldIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcheroo = new SimpleWorldMapIconWdgt
    switcheroo._applyExtent new Point 240, 125
    switcheroo.setColor Color.create 183, 183, 183
    return switcheroo



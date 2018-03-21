class WorldMapCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new LittleWorldIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "world map"

  createWidgetToBeHandled: ->
    switcheroo = new SimpleWorldMapIconWdgt()
    switcheroo.rawSetExtent new Point 240, 125
    switcheroo.setColor new Color 183, 183, 183
    return switcheroo



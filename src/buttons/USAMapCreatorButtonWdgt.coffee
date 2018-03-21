class USAMapCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new LittleUSAIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "USA map"

  createWidgetToBeHandled: ->
    switcheroo = new SimpleUSAMapIconWdgt()
    switcheroo.rawSetExtent new Point 230, 145
    switcheroo.setColor new Color 183, 183, 183
    return switcheroo



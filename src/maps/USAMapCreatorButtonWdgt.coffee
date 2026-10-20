class USAMapCreatorButtonWdgt extends CreatorButtonWdgt

  # stated rather than derived: an acronym keeps its capitals
  colloquialName: -> "USA map creator button"

  toolTipMessage: "USA map"

  createAppearance: -> new LittleUSAIconAppearance @, WorldWdgt.theme.toolbarGlyph

  createWidgetToBeHandled: ->
    switcheroo = new SimpleUSAMapIconWdgt
    switcheroo._applyExtent new Point 230, 145
    switcheroo.setColor Color.create 183, 183, 183
    return switcheroo



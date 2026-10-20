class USAMapCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "USA map"

  createAppearance: -> new LittleUSAIconAppearance @, WorldWdgt.theme.toolbarGlyph

  createWidgetToBeHandled: ->
    switcheroo = new SimpleUSAMapIconWdgt
    switcheroo._applyExtent new Point 230, 145
    switcheroo.setColor Color.create 183, 183, 183
    return switcheroo



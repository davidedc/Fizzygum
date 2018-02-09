# MenuHeader ////////////////////////////////////////////////////////////


class MenuHeader extends BoxMorph

  text: nil

  constructor: (textContents) ->
    super 3
    @color = new Color 77,77,77

    @text = new TextMorph(
      textContents,
      @fontSize or WorldMorph.preferencesAndSettings.menuFontSize,
      WorldMorph.preferencesAndSettings.menuFontName,
      true,
      false,
      "center")
    @text.alignment = "center"
    @text.color = new Color 255, 255, 255
    @text.backgroundColor = @color.copy()

    @add @text
    @rawSetExtent @text.extent().add 2

  rawSetWidth: (theWidth) ->
    super
    @text.fullRawMoveTo @center().subtract @text.extent().floorDivideBy 2

  mouseClickLeft: ->
    super
    if @parent?
      @firstParentThatIsAPopUp()?.pinPopUp @

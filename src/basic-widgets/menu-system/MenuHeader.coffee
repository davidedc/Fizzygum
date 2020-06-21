class MenuHeader extends BoxMorph

  text: nil

  constructor: (textContents) ->
    super 3
    @color = WorldMorph.preferencesAndSettings.menuHeaderColor

    @text = new TextMorph(
      textContents,
      @fontSize or WorldMorph.preferencesAndSettings.menuHeaderFontSize,
      WorldMorph.preferencesAndSettings.menuFontName,
      WorldMorph.preferencesAndSettings.menuHeaderBold,
      false,
      "center")
    @text.alignment = "center"
    @text.color = new Color 255, 255, 255
    @text.backgroundColor = @color

    @add @text
    @rawSetExtent @text.extent().add 2

  rawSetWidth: (theWidth) ->
    super
    @text.fullRawMoveTo @center().subtract @text.extent().floorDivideBy 2

  mouseClickLeft: ->
    super
    if @parent?
      @firstParentThatIsAPopUp()?.pinPopUp @

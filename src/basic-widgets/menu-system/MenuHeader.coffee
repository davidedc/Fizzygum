class MenuHeader extends BoxWdgt

  text: nil

  constructor: (textContents) ->
    super 3
    @color = WorldMorph.preferencesAndSettings.menuHeaderColor

    @text = new TextWdgt(
      textContents,
      @fontSize or WorldMorph.preferencesAndSettings.menuHeaderFontSize,
      WorldMorph.preferencesAndSettings.menuFontName,
      WorldMorph.preferencesAndSettings.menuHeaderBold,
      false)
    @text.color = Color.WHITE
    @text.backgroundColor = @color
    @text.alignCenter()

    @add @text
    # the modern family does not self-size; make the label hug its text so the
    # header below can size itself to it (see sizeToTextAndDisableFitting).
    @text.sizeToTextAndDisableFitting()
    @rawSetExtent @text.extent().add 2

  rawSetWidth: (theWidth) ->
    super
    @text.fullRawMoveTo @center().subtract @text.extent().floorDivideBy 2

  mouseClickLeft: ->
    super
    if @parent?
      @firstParentThatIsAPopUp()?.pinPopUp @

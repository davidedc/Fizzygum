class MenuHeader extends BoxWdgt

  text: nil

  constructor: (textContents) ->
    super 3
    @color = WorldWdgt.preferencesAndSettings.menuHeaderColor

    @text = new TextWdgt(
      textContents,
      @fontSize or WorldWdgt.preferencesAndSettings.menuHeaderFontSize,
      WorldWdgt.preferencesAndSettings.menuFontName,
      WorldWdgt.preferencesAndSettings.menuHeaderBold,
      false)
    @text.color = Color.WHITE
    @text.backgroundColor = @color
    @text.alignCenter()

    @add @text
    # the modern family does not self-size; make the label hug its text so the
    # header below can size itself to it (see sizeToTextAndDisableFitting).
    @text.sizeToTextAndDisableFitting()
    @_applyExtentAndNotify @text.extent().add 2

  _applyWidthAndNotify: (theWidth) ->
    super
    @text._applyMoveToAndNotify @center().subtract @text.extent().floorDivideBy 2

  mouseClickLeft: ->
    super
    if @parent?
      @firstParentThatIsAPopUp()?.pinPopUp @

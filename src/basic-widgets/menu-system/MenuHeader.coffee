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

    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @_addNoSettle @text
    # the modern family does not self-size; make the label hug its text so the
    # header below can size itself to it. Use the NoSettle core (not the public
    # sizeToTextAndDisableFitting wrapper): the build's settle happens ONCE via
    # _buildAndConnectChildren, so a mid-core self-settle would be redundant (layering [G]).
    @text._sizeToTextAndDisableFittingNoSettle()
    @_applyExtent @text.extent().add 2

  _applyWidth: (theWidth) ->
    super
    # Integer placement (Layer A): @center() is fractional when my extent is odd, so round the centred text
    # position to commit an integer @bounds. docs/archive/fractional-widget-bounds-investigation-plan.md (Path 2).
    @text._applyMoveTo (@center().subtract @text.extent().floorDivideBy 2).round()

  mouseClickLeft: ->
    super
    if @parent?
      @firstParentThatIsAPopUp()?.pinPopUp @

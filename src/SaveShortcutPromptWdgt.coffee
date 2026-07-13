class SaveShortcutPromptWdgt extends MenuWdgt

  # bad hack to set the prompt to a
  # decent width
  # TODO this widget has to be re-made using
  # vertical stack layout anyways
  msg: " save as...         "

  tempPromptEntryField: nil

  constructor: (widgetOpeningThePopUp, @target, @defaultContents, @intendedWidth = 100, @wdgtWhereReferenceWillGo) ->

    if !@defaultContents
      @defaultContents = world.untitledNamingService.getNextUntitledShortcutName()

    # built BEFORE super on purpose: it is PASSED to super as the menu's environment-slot arg
    @tempPromptEntryField = new StringFieldWdgt(
      @defaultContents,
      150,
      WorldWdgt.preferencesAndSettings.prompterFontSize,
      WorldWdgt.preferencesAndSettings.prompterFontName,
      false,
      false,
      false
    )

    super widgetOpeningThePopUp, target: @target, title: @msg, environment: @tempPromptEntryField

    @_buildAndConnectChildren()

    @addMenuItem "Don't save", @target, "destroy"
    # "Cancel" here just dismisses this prompt, but the target
    # wdgt remains open
    @addMenuItem "Cancel", @, "close"
    @addMenuItem "Ok", @, "createReferenceAndClose"

    @_reLayoutSelf()
    @_applyWidth 150
    @tempPromptEntryField.text.edit()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @_addNoSettle @tempPromptEntryField
    # the old bare `@__add` ran the child's calculateAndUpdateExtent (StringFieldWdgt's measures
    # the text and applies width >= minTextWidth); _addNoSettle skips it, so run it explicitly.
    @tempPromptEntryField.calculateAndUpdateExtent()

  # (a vestigial `_reLayoutSelf: -> super(); @buildSubwidgets()` override with an EMPTY
  # buildSubwidgets hook was deleted 2026-07-12, exactly as in PromptWdgt — see the note there.)

  _reactToBeingAdded: (whereTo, beingDropped) ->
  
  createReferenceAndClose: ->
    @target.createReferenceAndClose @tempPromptEntryField.text.text, @wdgtWhereReferenceWillGo
    @close()
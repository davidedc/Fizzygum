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

    @tempPromptEntryField = new StringFieldWdgt(
      @defaultContents,
      150,
      WorldWdgt.preferencesAndSettings.prompterFontSize,
      WorldWdgt.preferencesAndSettings.prompterFontName,
      false,
      false,
      false
    )

    super widgetOpeningThePopUp, false, @target, true, true, @msg, @tempPromptEntryField

    @__add @tempPromptEntryField

    @addMenuItem "Don't save", true, @target, "destroy"
    # "Cancel" here just dismisses this prompt, but the target
    # wdgt remains open
    @addMenuItem "Cancel", true, @, "close"
    @addMenuItem "Ok", true, @, "createReferenceAndClose"

    @_reLayoutSelf()
    @_applyWidth 150
    @tempPromptEntryField.text.edit()

  _reLayoutSelf: ->
    super()
    @buildSubwidgets()

  buildSubwidgets: ->

  _reactToBeingAdded: (whereTo, beingDropped) ->
  
  createReferenceAndClose: ->
    @target.createReferenceAndClose @tempPromptEntryField.text.text, @wdgtWhereReferenceWillGo
    @close()
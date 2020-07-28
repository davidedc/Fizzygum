class SaveShortcutPromptWdgt extends MenuMorph

  # bad hack to set the prompt to a
  # decent width
  # TODO this widget has to be re-made using
  # vertical stack layout anyways
  msg: " save as...         "

  tempPromptEntryField: nil

  constructor: (morphOpeningThePopUp, @target, @defaultContents, @intendedWidth = 100, @wdgtWhereReferenceWillGo) ->
    
    if !@defaultContents
      @defaultContents = world.getNextUntitledShortcutName()

    @tempPromptEntryField = new StringFieldWdgt2(
      @defaultContents,
      150,
      WorldMorph.preferencesAndSettings.prompterFontSize,
      WorldMorph.preferencesAndSettings.prompterFontName,
      false,
      false,
      false
    )

    super morphOpeningThePopUp, false, @target, true, true, @msg, @tempPromptEntryField

    @silentAdd @tempPromptEntryField

    @addMenuItem "Don't save", true, @target, "destroy"
    # "Cancel" here just dismisses this prompt, but the target
    # wdgt remains open
    @addMenuItem "Cancel", true, @, "close"
    @addMenuItem "Ok", true, @, "createReferenceAndClose"

    @reLayout()
    @rawSetWidth 150
    @tempPromptEntryField.text.edit()

  reLayout: ->
    super()
    @buildSubmorphs()
    @notifyAllChildrenRecursivelyThatParentHasReLayouted()

  buildSubmorphs: ->

  iHaveBeenAddedTo: (whereTo, beingDropped) ->
  
  createReferenceAndClose: ->
    @target.createReferenceAndClose @tempPromptEntryField.text.text, @wdgtWhereReferenceWillGo
    @close()
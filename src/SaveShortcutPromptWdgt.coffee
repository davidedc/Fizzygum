# The "save as..." prompt: a text field for the shortcut name over a
# "Don't save" / "Cancel" / "Ok" button row. A member of the prompt family (it
# shares PromptWdgt's PopUpWdgt behaviour + composed titled rows-panel); it only
# swaps in its own three buttons (no leading divider) and edits the field at once.

class SaveShortcutPromptWdgt extends PromptWdgt

  # the trailing spaces pad the title so the prompt opens at a decent width.
  msg: " save as...         "

  wdgtWhereReferenceWillGo: undefined

  # No msg and no callback: the title is the class-level constant above, and there
  # is no caller action — Ok routes to my own createReferenceAndCloseFromMenu. Both are
  # simply absent from the options I forward, which is why the base reads msg
  # guarded (a bare assignment there would blank the constant).
  constructor: (widgetOpeningThePopUp, target, opts = {}) ->
    @wdgtWhereReferenceWillGo = opts.wdgtWhereReferenceWillGo
    defaultContents = opts.defaultContents
    if !defaultContents
      defaultContents = world.untitledNamingService.getNextUntitledShortcutName()
    super widgetOpeningThePopUp, target,
      defaultContents: defaultContents
      intendedWidth: opts.intendedWidth ? 100
    @_buildAndConnectChildren()
    # NO width poke here: my rows hug their widest row all by themselves, and that comes out
    # WIDER (154) than the 150 a poke would ask for — so setting it only to have the very next
    # arrange hug back over it bought nothing. Set minTextWidth on the entry field (below) if
    # this prompt ever needs to be wider; the hug then follows it, which is the mechanism the
    # rows panel already has rather than a value fighting it.
    @tempPromptEntryField.text.edit()

  _buildAndAddValueEditorInto: (panel) ->
    @tempPromptEntryField = new StringFieldWdgt @defaultContents,
      minTextWidth: 150
      fontSize: WorldWdgt.preferencesAndSettings.prompterFontSize
      fontStyle: WorldWdgt.preferencesAndSettings.prompterFontName
    panel._addNoSettle @tempPromptEntryField
    # _addNoSettle skips calculateAndUpdateExtent (which measures the text and
    # applies width >= minTextWidth); run it explicitly.
    @tempPromptEntryField.calculateAndUpdateExtent()

  # save-as has its own three buttons and no leading divider (unlike the base row).
  _addButtonsInto: (panel) ->
    panel.addMenuItem "Don't save", @target, "destroy"
    # "Cancel" here just dismisses this prompt, but the target wdgt remains open.
    panel.addMenuItem "Cancel", @, "close"
    panel.addMenuItem "Ok", @, "createReferenceAndCloseFromMenu"

  # THE MENU ADAPTER for my own Ok button: it takes the name the user typed and the place the
  # opener chose, so it has nothing to take from the dispatcher's four slots. The name is
  # deliberately NOT the family verb's — an arity-0 method called createReferenceAndClose would
  # SHADOW Widget.createReferenceAndClose on every instance of this class.
  createReferenceAndCloseFromMenu: ->
    @target.createReferenceAndClose @wdgtWhereReferenceWillGo, @_promptValue()
    @close()

# The "save as..." prompt: a text field for the shortcut name over a row of three buttons,
# [Don't save] [Cancel] [OK]. A member of the prompt family (it shares PromptWdgt's framed
# pop-up behaviour + composed rows panel, and its buttons row); it only swaps in its own three
# buttons (no leading divider) and edits the field at once.

class SaveShortcutPromptWdgt extends PromptWdgt

  # the trailing spaces pad the title so the prompt opens at a decent width.
  msg: " save as...         "

  wdgtWhereReferenceWillGo: undefined
  # my two buttons besides the OK I share with the family (PromptWdgt.okButton): Don't save
  # destroys the widget being closed, Cancel dismisses me and leaves it open.
  dontSaveButton: undefined
  cancelButton: undefined

  # No msg and no callback: the title is the class-level constant above, and there
  # is no caller action — OK routes to my own createReferenceAndCloseFromMenu. Both are
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
    @_buildPromptRows()
    # NO width poke here: my rows hug their widest row all by themselves -- my row of three
    # buttons, wider than the 150 a poke would ask for -- so setting it only to have the very
    # next arrange hug back over it would buy nothing. Set minTextWidth on the entry field
    # (below) if this prompt ever needs to be wider; the hug then follows it, which is the
    # mechanism the rows panel already has rather than a value fighting it.
    @tempPromptEntryField.text.edit()

  _buildAndAddValueEditorInto: (panel) ->
    @tempPromptEntryField = new StringFieldWdgt @defaultValue,
      minTextWidth: 150
      fontRole: WorldWdgt.theme.fonts.prompt
    panel._addNoSettle @tempPromptEntryField
    # _addNoSettle skips calculateAndUpdateExtent (which measures the text and
    # applies width >= minTextWidth); run it explicitly.
    @tempPromptEntryField.calculateAndUpdateExtent()

  # save-as has its own three buttons, OK the primary action, and no leading divider (unlike the
  # base's).
  _addButtonsInto: (panel) ->
    @dontSaveButton = new SimpleButtonWdgt @target, "destroy", face: "Don't save"
    # "Cancel" here just dismisses this prompt, but the target wdgt remains open.
    @cancelButton = new SimpleButtonWdgt @, "close", face: "Cancel"
    @okButton = new SimpleButtonWdgt @, "createReferenceAndCloseFromMenu", face: "OK", primary: true
    @_addButtonsRowInto panel, [@dontSaveButton, @cancelButton, @okButton]

  # THE MENU ADAPTER for my own OK button (the shape StringWdgt.setFontNameFromMenu describes: a
  # menu/button action is dispatched through ButtonWdgt's four slots): it takes the name the user
  # typed and the place the opener chose, so it has nothing to take from those slots. The name is
  # deliberately NOT the family verb's — an arity-0 method called createReferenceAndClose would
  # SHADOW Widget.createReferenceAndClose on every instance of this class.
  createReferenceAndCloseFromMenu: ->
    @target.createReferenceAndClose @wdgtWhereReferenceWillGo, @_promptValue()
    @close()

class CodePromptWdgt extends CodeAreaWdgt

  # the DISPATCH pair: on Save/OK I call @target[@callback].call @target, @_promptValue()
  # — ONE argument, the composed source text, the same value delivery every prompt makes
  # (the pin-setter contract, widget-authoring-guidelines.md §11).
  target: undefined
  callback: undefined

  defaultContents: ""

  cancelButton: undefined
  saveButton: undefined
  okButton: undefined

  # A prompt by role, not by descent (I am a CodeAreaWdgt, not a PromptWdgt), so I
  # have no widgetOpeningThePopUp operand — but I share the family's opts
  # vocabulary: callback, defaultContents.
  # ⚠ NOT msg: I build my own children and have no title bar to put one in, so the
  # `msg` the textPrompt door forwards has nowhere to land here and is not read.
  constructor: (target, opts = {}) ->
    @target = target
    @callback = opts.callback
    # guarded: absence must leave the class-level "" standing, which a bare
    # assignment would overwrite with undefined (R5).
    @defaultContents = opts.defaultContents if opts.defaultContents?
    super new Point 200,400
    @_buildAndConnectChildren()

  colloquialName: ->
    "Edit tool code"

  _buildAndConnectChildrenNoSettle: ->

    @_buildEditableCodeAreaNoSettle @defaultContents

    # buttons -------------------------------
    @cancelButton = new SimpleButtonWdgt @, "close", face: "Cancel"
    @_addNoSettle @cancelButton

    @saveButton = new SimpleButtonWdgt @, "deliverValue", face: "Save"
    @_addNoSettle @saveButton

    @okButton = new SimpleButtonWdgt @, "deliverValueAndClose", face: "OK", primary: true
    @_addNoSettle @okButton
    # ---------------------------------------

    # the save button is enabled exactly while the code differs from the text last delivered (or
    # opened with): the content check sets it now that it exists -- disabled, the code being
    # unmodified until edited.
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()

    @_invalidateLayout()

  textContentModified: ->
    @saveButton.setEnabled true

  textContentUnmodified: ->
    @saveButton.setEnabled false

  # My footer band holds everything at its RIGHT, the way a dialog's actions sit: cancel, save,
  # then ok, the primary action, nearest the corner.
  _footerRightButtons: ->
    [@cancelButton, @saveButton, @okButton]


  # my value is the composed source text. Same verb pair as PromptWdgt (a prompt by ROLE —
  # the isMenu? idiom): shared names for the shared delivery convention, no shared ancestry.
  _promptValue: ->
    @textWidget.text

  # The save adapter: deliver the value, then reset the modified-content tracking so the save
  # button re-disables until the text diverges again. It is NOT a menu action: nothing dispatches
  # it through ButtonWdgt's fixed 4-slot convention, so it carries no leading dispatcher slots and
  # no caller has to punch `undefined` past them (R3).
  deliverValue: ->
    @target[@callback].call @target, @_promptValue()
    @textWidget.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()

  deliverValueAndClose: ->
    @deliverValue()
    @close()


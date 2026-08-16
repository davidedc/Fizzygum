class CodePromptWdgt extends CodeAreaWdgt

  defaultContents: ""

  cancelButton: undefined
  saveButton: undefined
  okButton: undefined
  saveTextWdgt: undefined

  # A prompt by role, not by descent (I am a CodeAreaWdgt, not a PopUpWdgt), so I
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
    @cancelButton = new SimpleButtonWdgt @, "close", face: "cancel"
    @_addNoSettle @cancelButton

    
    @saveTextWdgt = new StringWdgt "save", fontSize: WorldWdgt.preferencesAndSettings.textInButtonsFontSize
    @saveTextWdgt.alignCenter()
    @saveButton = new SimpleButtonWdgt @, "informTarget", face: @saveTextWdgt
    @_addNoSettle @saveButton

    @okButton = new SimpleButtonWdgt @, "notifyTargetAndClose", face: "ok"
    @_addNoSettle @okButton
    # ---------------------------------------

    # now that we added the buttons there is a "save" button
    # to disable (because the reference text has not been
    # changed yet), so trigger the content check now
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()

    @_invalidateLayout()

  textContentModified: ->
    @saveTextWdgt.setColor Color.BLACK

  textContentUnmodified: ->
    @saveTextWdgt.setColor Color.create 200, 200, 200


  # The callback is invoked with what it actually needs. It is NOT a menu action: nothing
  # dispatches it through ButtonWdgt's fixed 4-slot convention, so it carries no leading
  # dataSource/widgetEnv slots and no caller has to punch `undefined` past them (R3).
  informTarget: ->
    @target[@callback].call @target, @textWidget
    @textWidget.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()

  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    # clamped at 0: a transient degenerate height must not invert the text
    # panel's rect (the ErrorsLogViewerWdgt construction-cascade fix, same family)
    textHeight = Math.max 0, @height() - 2 * @externalPadding - @internalPadding - 15
    textBottom = @top() + @externalPadding + textHeight

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyBounds (new Point @left() + @externalPadding, @top() + @externalPadding), new Point @width() - 2 * @externalPadding, textHeight


    # buttons -------------------------------


    # fractional /3 makes the second and third buttons' origins fractional --
    # round it here so all three land on integer pixels (the ConsoleWdgt /2
    # precedent; integer placement is enforced by the always-on bounds guard)
    eachButtonWidth = Math.round (@width() - 2 * @externalPadding - 3 * @internalPadding - WorldWdgt.preferencesAndSettings.handleSize) / 3

    if @cancelButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding + 0*(eachButtonWidth + @internalPadding), textBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight eachButtonWidth, 15
      @cancelButton._reLayout buttonBounds

    if @saveButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding + 1*(eachButtonWidth + @internalPadding), textBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight eachButtonWidth, 15
      @saveButton._reLayout buttonBounds

    if @okButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding + 2*(eachButtonWidth + @internalPadding), textBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight eachButtonWidth, 15
      @okButton._reLayout buttonBounds

    # ----------------------------------------------


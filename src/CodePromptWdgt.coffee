class CodePromptWdgt extends CodeAreaWdgt

  defaultContents: ""

  cancelButton: undefined
  saveButton: undefined
  okButton: undefined
  saveTextWdgt: undefined

  constructor: (@msg, @target, @callback, @defaultContents) ->
    super new Point 200,400
    @_buildAndConnectChildren()

  colloquialName: ->
    "Edit tool code"

  _buildAndConnectChildrenNoSettle: ->

    @_buildEditableCodeAreaNoSettle @defaultContents

    # buttons -------------------------------
    @cancelButton = new SimpleButtonWdgt true, @, "close", "cancel"
    @_addNoSettle @cancelButton

    
    @saveTextWdgt = new StringWdgt "save", fontSize: WorldWdgt.preferencesAndSettings.textInButtonsFontSize
    @saveTextWdgt.alignCenter()
    @saveButton = new SimpleButtonWdgt true, @, "informTarget", @saveTextWdgt
    @_addNoSettle @saveButton

    @okButton = new SimpleButtonWdgt true, @, "notifyTargetAndClose", "ok"
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


  informTarget: ->
    @target[@callback].call @target, undefined, @textWidget
    @textWidget.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my own bounds FIRST, so the children laid out below read the FINAL frame and
    # not the previous pass's (else they lag one cadence on resize -- see InspectorWdgt._reLayout /
    # FanoutWdgt._reLayout). The trailing super re-applies the same bounds, idempotently.
    @_applyGrantedBounds newBoundsForThisLayout

    @_repaintAsOneUnit =>

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

    super
    @_markLayoutAsFixed()


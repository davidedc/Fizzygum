class CodePromptWdgt extends CodeAreaWdgt

  defaultContents: ""

  cancelButton: nil
  saveButton: nil
  okButton: nil
  saveTextWdgt: nil

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

    
    @saveTextWdgt = new StringWdgt "save", WorldWdgt.preferencesAndSettings.textInButtonsFontSize
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
    @target[@callback].call @target, nil, @textWidget
    @textWidget.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my own bounds FIRST, so the children laid out below read the FINAL frame and
    # not the previous pass's (else they lag one cadence on resize -- see InspectorWdgt._reLayout /
    # FanoutWdgt._reLayout). The trailing super re-applies the same bounds, idempotently.
    @_applyGrantedBounds newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of this widget are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    textHeight = @height() - 2 * @externalPadding - @internalPadding - 15
    textBottom = @top() + @externalPadding + textHeight

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyBounds (new Point @left() + @externalPadding, @top() + @externalPadding), new Point @width() - 2 * @externalPadding, textHeight


    # buttons -------------------------------
    

    eachButtonWidth = (@width() - 2 * @externalPadding - 3 * @internalPadding - WorldWdgt.preferencesAndSettings.handleSize) / 3

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


    world.maybeEnableTrackChanges()
    @_fullChanged()

    super
    @_markLayoutAsFixed()


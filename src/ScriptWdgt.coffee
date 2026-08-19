# As usual in Widgetic widgets are visual interactable things, and
# this widget embodies a script.
#
# A script is
#   * an easy-to modify piece of code
#     (i.e. it opens in its own panel, where you can edit and run it)
#   * it's standalone, i.e. it's independent i.e.
#     it's code that doesn't belong to any other widget
#     (i.e.: if this code should belong to a widget, add it to a widget)
#   * it's probably temporary "glue" or "scaffolding" or "utility"
#     code that is not meant to be around for long (i.e.: this code,
#     if really useful, should really find its place in a proper class)
#
# When writing a script, consider the alternatives:
#   * a menu entry invoking a proper method from a widget
#   * a button invoking a proper method from a widget
#   * an iconic link on the desktop... invoking a proper method from a widget

class ScriptWdgt extends CodeAreaWdgt

  runItButton: undefined
  saveButton: undefined

  savedScript: undefined
  # the saved script COMPILED -- a derived Function (@savedScript is the truth),
  # never serialized: an own function property has no editable source and would
  # crash the serializer; doAll recompiles it on demand after a restore.
  @serializationTransients: ["functionFromCompiledCode"]
  functionFromCompiledCode: undefined

  constructor: (@savedScript = "") ->
    super new Point 200,400
    @_buildAndConnectChildren()


  representativeIcon: ->
    new ScriptIconWdgt

  # As window content I yield a SPECIAL desktop reference -- a script shortcut that runs the
  # script on double-click, not a plain window reference. FrameWdgt.createReference calls this
  # instead of testing `@contents instanceof ScriptWdgt`; other contents don't define it and
  # fall to the default reference. (type-test-elimination campaign)
  specialFrameReferenceShortcut: (window, referenceName) ->
    new ScriptShortcutWdgt window, referenceName

  closeFromContainerFrame: (containerWindow) ->
    if !world.anyReferenceOrWireIntoWdgt containerWindow
      prompt = new SaveShortcutPromptWdgt @, containerWindow
      prompt.popUpAtHand()
    else
      containerWindow.close()

  _buildAndConnectChildrenNoSettle: ->

    @_buildEditableCodeAreaNoSettle @savedScript

    # buttons -------------------------------
    @runItButton = new SimpleButtonWdgt @, "tryIt", face: "try it"
    @_addNoSettle @runItButton

    # local: @saveButton keeps it as its face widget, so a second copy on `this` was redundant state.
    saveTextWdgt = new StringWdgt "save + close", fontSize: WorldWdgt.preferencesAndSettings.textInButtonsFontSize
    saveTextWdgt.alignCenter()
    @saveButton = new SimpleButtonWdgt @, "saveScriptAndClose", face: saveTextWdgt
    @_addNoSettle @saveButton
    # ---------------------------------------

    # now that we added the buttons there is a "save" button
    # to disable (because the reference text has not been
    # changed yet), so trigger the content check now
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()

    @_invalidateLayout()

  saveScript: ->
    @savedScript = @textWidget.text
    compiled = compileFGCode @savedScript, true
    @functionFromCompiledCode = new Function compiled

    @textWidget.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()

  saveScriptAndClose: ->
    @saveScript()
    @closeFromContainerFrame @parent

  doAll: ->
    # transient (see above): recompile from the saved source after a restore
    if !@functionFromCompiledCode? and @savedScript
      @functionFromCompiledCode = new Function compileFGCode @savedScript, true
    @functionFromCompiledCode?.call world

  tryIt: ->
    world.evaluateString @textWidget.text

  textContentModified: ->

  textContentUnmodified: ->

  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    textHeight = @height() - 2 * @externalPadding - @internalPadding - 15
    textBottom = @top() + @externalPadding + textHeight
    textWidth = @width() - 2 * @externalPadding
    buttonsWidth = Math.round((textWidth - 2 * @internalPadding - WorldWdgt.preferencesAndSettings.handleSize)/2)

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyBounds (new Point @left() + @externalPadding, @top() + @externalPadding), new Point textWidth, textHeight


    # buttons -------------------------------


    if @runItButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding, textBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight buttonsWidth, 15
      @runItButton._reLayout buttonBounds

    if @saveButton.parent == @
      buttonBounds = new Rectangle new Point buttonBounds.right() + @internalPadding, textBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight buttonsWidth, 15
      @saveButton._reLayout buttonBounds


    # ----------------------------------------------


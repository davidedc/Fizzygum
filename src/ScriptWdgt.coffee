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

class ScriptWdgt extends Widget

  tempPromptEntryField: nil
  textWidget: nil

  runItButton: nil
  saveButton: nil

  savedScript: nil
  functionFromCompiledCode: nil

  # the external padding is the space between the edges
  # of the container and all of its internals. The reason
  # you often set this to zero is because windows already put
  # contents inside themselves with a little padding, so this
  # external padding is not needed. Useful to keep it
  # separate and know that it's working though.
  externalPadding: 0
  # the internal padding is the space between the internal
  # components. It doesn't necessarily need to be equal to the
  # external padding
  internalPadding: 5

  constructor: (@savedScript = "") ->
    super new Point 200,400
    @_buildAndConnectChildren()

  colloquialName: ->
    "script"

  representativeIcon: ->
    new ScriptIconWdgt

  # As window content I yield a SPECIAL desktop reference -- a script shortcut that runs the
  # script on double-click, not a plain window reference. FrameWdgt.createReference calls this
  # instead of testing `@contents instanceof ScriptWdgt`; other contents don't define it and
  # fall to the default reference. (type-test-elimination campaign)
  specialFrameReferenceShortcut: (window, referenceName) ->
    new IconicDesktopSystemScriptShortcutWdgt window, referenceName

  closeFromContainerFrame: (containerWindow) ->
    if !world.anyReferenceToWdgt containerWindow
      prompt = new SaveShortcutPromptWdgt @, containerWindow
      prompt.popUpAtHand()
    else
      containerWindow.close()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @tempPromptEntryField = new SimpleTextScrollPanelWdgt @savedScript, false, 5
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = Color.WHITE
    @tempPromptEntryField.addModifiedContentIndicator()

    # register this wdgt as one to be notified when the text
    # changes/unchanges from "reference" content
    # so we can enable/disable the "save" button
    @tempPromptEntryField.widgetToBeNotifiedOfTextModificationChange = @

    @textWidget = @tempPromptEntryField.textWdgt
    @textWidget.backgroundColor = Color.TRANSPARENT
    @textWidget._setFontNameNoSettle nil, nil, @textWidget.monoFontStack
    @textWidget.isEditable = true
    @textWidget.enableSelecting()

    @_addNoSettle @tempPromptEntryField

    # buttons -------------------------------
    @runItButton = new SimpleButtonWdgt true, @, "tryIt", "try it"
    @_addNoSettle @runItButton

    # local: @saveButton keeps it as its face widget, so a second copy on `this` was redundant state.
    saveTextWdgt = new StringWdgt "save + close", WorldWdgt.preferencesAndSettings.textInButtonsFontSize
    saveTextWdgt.alignCenter()
    @saveButton = new SimpleButtonWdgt true, @, "saveScriptAndClose", saveTextWdgt
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
    @functionFromCompiledCode?.call world

  tryIt: ->
    world.evaluateString @textWidget.text

  textContentModified: ->

  textContentUnmodified: ->

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my own bounds FIRST, so the children laid out below read the FINAL frame and
    # not the previous pass's (else they lag one cadence on resize -- see InspectorWdgt._reLayout /
    # FanoutWdgt._reLayout). The trailing super re-applies the same bounds, idempotently.
    @_applyBounds newBoundsForThisLayout

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
    textWidth = @width() - 2 * @externalPadding
    buttonsWidth = Math.round((textWidth - 2 * @internalPadding - WorldWdgt.preferencesAndSettings.handleSize)/2)

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField._applyExtent new Point textWidth, textHeight


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


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()


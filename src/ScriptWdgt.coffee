# As usual in Widgetic widgets are visual interactable things, and
# this widget embodies a script.
#
# A script is
#   * an easy-to modify piece of code
#     (i.e. it opens in its own panel, where you can edit and run it)
#   * it's standalone, i.e. it's independent i.e.
#     it's code that doesn't belong to any other widget
#     (i.e.: if this code should belong to a widget, add it to a widget)
#   * it's probably temporary "glue" or "scaffholding" or "utility"
#     code that is not meant to be around for long (i.e.: this code,
#     if really useful, should really find its place in a proper class)
#
# When writing a script, consider the alternatives:
#   * a menu entry invoking a proper method from a widget
#   * a button invoking a proper method from a widget
#   * an iconic link on the desktop... invoking a proper method from a widget

class ScriptWdgt extends Widget

  tempPromptEntryField: nil
  textMorph: nil

  runItButton: nil
  saveButton: nil
  saveTextWdgt: nil

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
    @buildAndConnectChildren()

  colloquialName: ->
    "script"

  representativeIcon: ->
    new ScriptIconWdgt

  closeFromContainerWindow: (containerWindow) ->
    if !world.anyReferenceToWdgt containerWindow
      prompt = new SaveShortcutPromptWdgt @, containerWindow
      prompt.popUpAtHand()
    else
      containerWindow.close()

  buildAndConnectChildren: ->
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @tempPromptEntryField = new SimplePlainTextScrollPanelWdgt @savedScript, false, 5
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = Color.WHITE
    @tempPromptEntryField.addModifiedContentIndicator()

    # register this wdgt as one to be notified when the text
    # changes/unchanges from "reference" content
    # so we can enable/disable the "save" button
    @tempPromptEntryField.widgetToBeNotifiedOfTextModificationChange = @

    @textMorph = @tempPromptEntryField.textWdgt
    @textMorph.backgroundColor = Color.TRANSPARENT
    @textMorph.setFontName nil, nil, @textMorph.monoFontStack
    @textMorph.isEditable = true
    @textMorph.enableSelecting()

    @add @tempPromptEntryField

    # buttons -------------------------------
    @runItButton = new SimpleButtonMorph true, @, "tryIt", "try it"
    @add @runItButton

    @saveTextWdgt = new StringMorph2 "save + close", WorldMorph.preferencesAndSettings.textInButtonsFontSize
    @saveTextWdgt.alignCenter()
    @saveButton = new SimpleButtonMorph true, @, "saveScriptAndClose", @saveTextWdgt
    @add @saveButton
    # ---------------------------------------

    # now that we added the buttons there is a "save" button
    # to disable (because the reference text has not been
    # changed yet), so trigger the content check now
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()

    @invalidateLayout()

  saveScript: ->
    @savedScript = @textMorph.text
    compiled = compileFGCode @savedScript, true
    @functionFromCompiledCode = new Function compiled

    @textMorph.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()

  saveScriptAndClose: ->
    @saveScript()
    @closeFromContainerWindow @parent

  doAll: ->
    @functionFromCompiledCode?.call world

  tryIt: ->
    world.evaluateString @textMorph.text

  textContentModified: ->

  textContentUnmodified: ->

  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    if @isCollapsed()
      @layoutIsValid = true
      return

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.trackChanges.push false

    textHeight = @height() - 2 * @externalPadding - @internalPadding - 15
    textBottom = @top() + @externalPadding + textHeight
    textWidth = @width() - 2 * @externalPadding
    buttonsWidth = Math.round((textWidth - 2 * @internalPadding - WorldMorph.preferencesAndSettings.handleSize)/2)

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField.rawSetExtent new Point textWidth, textHeight


    # buttons -------------------------------
    

    if @runItButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding, textBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight buttonsWidth, 15
      @runItButton.doLayout buttonBounds

    if @saveButton.parent == @
      buttonBounds = new Rectangle new Point buttonBounds.right() + @internalPadding, textBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight buttonsWidth, 15
      @saveButton.doLayout buttonBounds


    # ----------------------------------------------


    world.trackChanges.pop()
    @fullChanged()
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    super
    @layoutIsValid = true


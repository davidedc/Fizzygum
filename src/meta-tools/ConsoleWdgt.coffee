class ConsoleWdgt extends CodeAreaWdgt

  # the object typed code is evaluated AGAINST (the receiver of the compiled function)
  target: undefined

  runSelectionButton: undefined
  runAllButton: undefined

  functionFromCompiledCode: undefined

  constructor: (@target) ->
    super new Point 200,400
    @_buildAndConnectChildren()

  # my target's name follows the dash as it is: a proper name keeps its capitals ("Console — Docs
  # Maker"), a description stays in its lowercase words ("Console — rectangle")
  colloquialName: ->
    "Console — " + @target.colloquialName()

  _buildAndConnectChildrenNoSettle: ->

    @_buildMonoCodeAreaNoSettle ""

    # "do" buttons -------------------------------
    # NOTE that you can also "doAll" or "doSelection" via
    # the context menu entries in the text panel!
    @runSelectionButton = new SimpleButtonWdgt @, "doSelection", face: "Run selection"
    # editor chrome: "Run selection" reads the current text selection, so its
    # press must not steal the focus pointer or end the edit (§5.D D2a).
    @runSelectionButton.actsAsEditorChrome = true
    @_addNoSettle @runSelectionButton

    @runAllButton = new SimpleButtonWdgt @, "doAll", face: "Run all"
    @_addNoSettle @runAllButton
    # ---------------------------------------

    @_invalidateLayout()

  doSelection: ->
    savedScript = @textWidget.selection()
    compiled = compileFGCode savedScript, true
    functionFromCompiledCode = new Function compiled
    functionFromCompiledCode.call @target

  doAll: ->
    savedScript = @textWidget.text
    compiled = compileFGCode savedScript, true
    functionFromCompiledCode = new Function compiled
    functionFromCompiledCode.call @target

  # I contribute my own "run" entries to the context menu of the text I contain (run the
  # selection if any, then run all), targeting my doSelection/doAll. The text calls this
  # instead of reaching up three levels and testing `instanceof ConsoleWdgt`; a text not in a
  # console adds its own plain "Run contents" instead. (type-test-elimination campaign)
  addRunMenuEntriesForText: (menu, textWidget) ->
    if textWidget.currentlySelecting()
      menu.addMenuItem "Run selection", @, "doSelection"
    menu.addMenuItem "Run contents", @, "doAll"

  # My footer band holds both run buttons at its LEFT.
  _footerLeftButtons: ->
    [@runSelectionButton, @runAllButton]


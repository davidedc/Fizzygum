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
  # crash the serializer; doAll recompiles it on demand after a restore. A deep
  # copy SHARES it (the Duplicator passes functions through): safe, because it is
  # a closure-free `new Function` invoked with `.call world` -- a pure derivative
  # of the same script text both widgets hold; a re-save recompiles per-widget.
  @serializationTransients: ["functionFromCompiledCode"]
  functionFromCompiledCode: undefined

  constructor: (@savedScript = "") ->
    super new Point 200,400
    @_buildAndConnectChildren()


  representativeIcon: ->
    new ScriptIconWdgt

  # As window content I yield a SPECIAL desktop reference -- a script shortcut that runs the
  # script on double-click, not a plain window reference. FrameWdgt consults this (from its menu
  # createReference AND its _buildShortcutWidget core seam, so a FILED script window keeps its
  # script-ness) instead of testing `@contents instanceof ScriptWdgt`; other contents don't
  # define it and fall to the default reference. (type-test-elimination campaign)
  # opts.representsContents = the arrow-contract declaration (plan §4.4), threaded exactly as in
  # the base shortcut builder: a filing declares content, "create shortcut" stays an alias.
  specialFrameReferenceShortcut: (window, referenceName, opts = {}) ->
    new ScriptShortcutWdgt window, referenceName, representsContents: opts.representsContents

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

    @saveButton = new SimpleButtonWdgt @, "saveScriptAndClose", face: "save + close", primary: true
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

  # My footer band: "try it" at its LEFT; "save + close", the primary action, at its right.
  _footerLeftButtons: ->
    [@runItButton]

  _footerRightButtons: ->
    [@saveButton]


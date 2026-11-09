class ConsoleWdgt extends CodeAreaWdgt

  # the widget code typed in me runs AGAINST (codeReceiver)
  target: undefined

  runSelectionButton: undefined
  runAllButton: undefined

  constructor: (@target) ->
    super()
    @_buildAndConnectChildren()

  # my target's name follows the dash as it is: a proper name keeps its capitals ("Console — Docs
  # Maker"), a description stays in its lowercase words ("Console — rectangle")
  colloquialName: ->
    "Console — " + @target.colloquialName()

  _buildAndConnectChildrenNoSettle: ->

    @_buildMonoCodeAreaNoSettle ""

    # "run" buttons -------------------------------
    # each dispatches my text's own run verb, the one its run row ("Run selection", "Run contents")
    # dispatches, so a button and a row cannot disagree about what runs or against what (I name my
    # text's code receiver: codeReceiver)
    @runSelectionButton = new SimpleButtonWdgt target: @textWidget, action: "runSelection", face: "Run selection"
    # editor chrome: "Run selection" reads the current text selection, so its
    # press must not steal the focus pointer or end the edit (§5.D D2a).
    @runSelectionButton.actsAsEditorChrome = true
    @_addNoSettle @runSelectionButton

    @runAllButton = new SimpleButtonWdgt target: @textWidget, action: "runContents", face: "Run all"
    @_addNoSettle @runAllButton
    # ---------------------------------------

    @_invalidateLayout()

  # What code typed in my text runs against (TextWdgt._codeReceiver): my target.
  codeReceiver: ->
    @target

  # My footer band holds both run buttons at its LEFT.
  _footerLeftButtons: ->
    [@runSelectionButton, @runAllButton]


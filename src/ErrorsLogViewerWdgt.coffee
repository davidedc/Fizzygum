# to make this error log viewer come up, edit any code
# in the inspector so to get a compilation error
# (e.g. unmatched parens) and click "save"

class ErrorsLogViewerWdgt extends CodeAreaWdgt

  defaultContents: ""

  clearButton: undefined
  pauseToggle: undefined
  okButton: undefined

  paused: false

  # (Widget's constructor takes no arguments -- a birth extent passed to super
  # was silently discarded, so the console is born at Widget's default bounds
  # and gets its real size from the window that wraps it, createErrorConsole.)
  # ALL options, no operand: the error console is opened by the world with nothing to
  # configure. It carries no target/callback pair -- an error log reports, it does not commit a
  # value back to anyone, so my ok button closes (closeFromContainerFrame) and the
  # deliverValue path belongs to CodePromptWdgt alone.
  # defaultContents is read GUARDED so absence leaves the class-level "" standing: a bare
  # @param would overwrite it with undefined (R5).
  constructor: (opts = {}) ->
    @defaultContents = opts.defaultContents if opts.defaultContents?
    super()
    @_buildAndConnectChildren()

  colloquialName: ->
    "error log"

  closeFromContainerFrame: (containerWindow) ->
    @parent.hide()

  addText: (newLog) ->
    if @textWidget.text.length != 0
      existingLog = @textWidget.text
    else
      existingLog = ""

    @textWidget.setText existingLog + "\n\n-----------------------------------------\n\n" + newLog


  showUpWithError: (err) ->
    unless @paused
      toBeAddedToLog = ""

      if world.widgetsGivingErrorWhileRepainting.length != 0
        toBeAddedToLog += "Some widgets crashed while painting themselves and\n"
        toBeAddedToLog += "hence have been banned from re-painting themseves.\n"
        toBeAddedToLog += "Edit/save any source code to give them another chance.\n\n"

      toBeAddedToLog += err
      if err.stack?
        toBeAddedToLog += "\n\nStack:\n" + err.stack
      @addText toBeAddedToLog

    if !@parent.isVisible
      @parent.show()
      @parent.bringToForeground()


  _buildAndConnectChildrenNoSettle: ->

    @_buildMonoCodeAreaNoSettle @defaultContents

    # buttons -------------------------------
    @clearButton = new SimpleButtonWdgt @, "clearTextPane", face: "clear"
    @_addNoSettle @clearButton


    pauseButton = new SimpleButtonWdgt @, "pauseErrors", face: "pause"
    unpauseButton = new SimpleButtonWdgt @, "unpauseErrors", face: "un-pause"
    @pauseToggle = new ToggleButtonWdgt pauseButton, unpauseButton, if @paused then 1 else 0
    @_addNoSettle @pauseToggle

    @okButton = new SimpleButtonWdgt @, "closeFromContainerFrame", face: "ok"
    @_addNoSettle @okButton

    @_invalidateLayout()

  pauseErrors: ->
    @paused = true

  unpauseErrors: ->
    @paused = false

  clearTextPane: ->
    @textWidget.setText ""

  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    # clamped at 0: a transient degenerate height mid window-negotiation must not
    # invert the text panel's rect (a negative height here was half the console's
    # NON_INTEGER_GEOMETRY construction cascade)
    mainCanvasHeight = Math.max 0, @height() - 2 * @externalPadding - @internalPadding - WorldWdgt.preferencesAndSettings.handleSize
    mainCanvasBottom = @top() + @externalPadding + mainCanvasHeight

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyBounds (new Point @left() + @externalPadding, @top() + @externalPadding), new Point @width() - 2 * @externalPadding, mainCanvasHeight


    # buttons -------------------------------


    # fractional /3 makes the second and third buttons' origins (each = the
    # previous one's right edge plus the padding) fractional -- round it here so
    # all three land on integer pixels (the ConsoleWdgt /2 precedent; integer
    # placement is enforced by the always-on bounds guard)
    eachButtonWidth = Math.round (@width() - 2* @externalPadding - 3 * @internalPadding - WorldWdgt.preferencesAndSettings.handleSize) / 3

    if @clearButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding + 0*(eachButtonWidth + @internalPadding), mainCanvasBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight eachButtonWidth, 15
      @clearButton._reLayout buttonBounds

    if @pauseToggle.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding + 1*(eachButtonWidth + @internalPadding), mainCanvasBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight eachButtonWidth, 15
      @pauseToggle._reLayout buttonBounds

    if @okButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding + 2*(eachButtonWidth + @internalPadding), mainCanvasBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight eachButtonWidth, 15
      @okButton._reLayout buttonBounds

    # ----------------------------------------------


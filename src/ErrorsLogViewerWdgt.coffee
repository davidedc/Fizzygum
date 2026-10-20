# to make this error log viewer come up, edit any code
# in the inspector so to get a compilation error
# (e.g. unmatched parens) and click "Save"

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
  # value back to anyone, so my OK button just hides my window (hideLog) and the
  # deliverValue path belongs to CodePromptWdgt alone.
  # defaultContents is read GUARDED so absence leaves the class-level "" standing: a bare
  # @param would overwrite it with undefined (R5).
  constructor: (opts = {}) ->
    @defaultContents = opts.defaultContents if opts.defaultContents?
    super()
    @_buildAndConnectChildren()

  colloquialName: ->
    "error log"

  # HIDE, never close: destroying the error console swallows every later paint error in the
  # session (the teardown-shared-core lesson), so dismissing it by any route just hides its window.
  hideLog: ->
    @parent.hide()

  # the window-chrome close chain (FrameWdgt.close -> contents.closeFromContainerFrame frame)
  # routes to the same hide.
  closeFromContainerFrame: (containerWindow) ->
    @hideLog()

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
    @clearButton = new SimpleButtonWdgt @, "clearTextPane", face: "Clear"
    @_addNoSettle @clearButton


    pauseButton = new SimpleButtonWdgt @, "pauseErrors", face: "Pause"
    unpauseButton = new SimpleButtonWdgt @, "unpauseErrors", face: "Un-pause"
    @pauseToggle = new ToggleButtonWdgt pauseButton, unpauseButton, if @paused then 1 else 0
    @_addNoSettle @pauseToggle

    @okButton = new SimpleButtonWdgt @, "hideLog", face: "OK"
    @_addNoSettle @okButton

    @_invalidateLayout()

  pauseErrors: ->
    @paused = true

  unpauseErrors: ->
    @paused = false

  clearTextPane: ->
    @textWidget.setText ""

  # My footer band: clear and the pause toggle at its LEFT, ok at its right.
  _footerLeftButtons: ->
    [@clearButton, @pauseToggle]

  _footerRightButtons: ->
    [@okButton]

  # My pause toggle shows one of its two buttons at a time, in its own box, and has no size of
  # its own: in my footer band it takes the larger of its two buttons' preferred extents, so it
  # keeps its size when it flips between "Pause" and "Un-pause".
  _footerExtentOf: (button) ->
    return super button unless button is @pauseToggle
    width = 0
    height = 0
    for toggleButton in @pauseToggle.buttons
      extent = toggleButton.preferredExtent()
      width = Math.max width, extent.x
      height = Math.max height, extent.y
    new Point width, height


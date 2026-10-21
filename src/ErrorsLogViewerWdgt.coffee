# to make this error log viewer come up, edit any code
# in the inspector so to get a compilation error
# (e.g. unmatched parens) and click "Save"

class ErrorsLogViewerWdgt extends CodeAreaWdgt

  defaultContents: ""

  clearButton: undefined
  # my PAUSE toggle (LabelledToggleWdgt): the fixed label "Pause", ON exactly while I am paused.
  # Its state is mine: a click runs my togglePaused, which decides and shows it.
  pauseToggle: undefined
  okButton: undefined

  # Am I paused? While I am, showUpWithError logs nothing new (it still shows my window). It is
  # the one truth of my pause state, and my pause toggle shows it. togglePaused writes it, so a
  # paused log carries it as an own field, which a copy and a saved world keep beside the
  # toggle's own isOn.
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


    # my pause toggle: its fixed label, the one action that flips my paused field, and born
    # showing that field
    @pauseToggle = new LabelledToggleWdgt @, "togglePaused", face: "Pause", on: @paused
    @_addNoSettle @pauseToggle

    @okButton = new SimpleButtonWdgt @, "hideLog", face: "OK"
    @_addNoSettle @okButton

    @_invalidateLayout()

  # My pause toggle's action: pause me, or resume me, and show the new state on the toggle. The
  # toggle never flips itself, so after my build this is the one place either of the two changes,
  # and they cannot disagree. Only the toggle's look changes, never its size, so nothing re-lays.
  togglePaused: ->
    @paused = !@paused
    @pauseToggle.setOn @paused

  clearTextPane: ->
    @textWidget.setText ""

  # My footer band: clear and the pause toggle at its LEFT, ok at its right.
  _footerLeftButtons: ->
    [@clearButton, @pauseToggle]

  _footerRightButtons: ->
    [@okButton]


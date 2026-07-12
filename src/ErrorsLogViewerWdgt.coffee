# to make this error log viewer come up, edit any code
# in the inspector so to get a compilation error
# (e.g. unmatched parens) and click "save"

class ErrorsLogViewerWdgt extends Widget

  tempPromptEntryField: nil
  defaultContents: ""
  textWidget: nil

  clearButton: nil
  pauseToggle: nil
  okButton: nil

  externalPadding: 0
  internalPadding: 5

  paused: false

  constructor: (@msg, @target, @callback, @defaultContents) ->
    super new Point 200,400
    @_buildAndConnectChildren()

  colloquialName: ->
    "Error log"

  closeFromContainerWindow: (containerWindow) ->
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


  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @tempPromptEntryField = new SimplePlainTextScrollPanelWdgt @defaultContents, false, 5
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = Color.WHITE

    @textWidget = @tempPromptEntryField.textWdgt
    @textWidget.backgroundColor = Color.TRANSPARENT
    @textWidget._setFontNameNoSettle nil, nil, @textWidget.monoFontStack
    @textWidget.isEditable = true
    @textWidget.enableSelecting()

    @_addNoSettle @tempPromptEntryField

    # buttons -------------------------------
    @clearButton = new SimpleButtonWdgt true, @, "clearTextPane", "clear"
    @_addNoSettle @clearButton


    pauseButton = new SimpleButtonWdgt true, @, "pauseErrors", "pause"
    unpauseButton = new SimpleButtonWdgt true, @, "unpauseErrors", "un-pause"
    @pauseToggle = new ToggleButtonWdgt pauseButton, unpauseButton, if @paused then 1 else 0
    @_addNoSettle @pauseToggle

    @okButton = new SimpleButtonWdgt true, @, "closeFromContainerWindow", "ok"
    @_addNoSettle @okButton

    @_invalidateLayout()

  pauseErrors: ->
    @paused = true

  unpauseErrors: ->
    @paused = false

  clearTextPane: ->
    @textWidget.setText ""

  informTarget: ->
    @target[@callback].call @target, nil, @textWidget

  notifyTargetAndClose: ->
    @informTarget()
    @close()

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyBounds newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()


    mainCanvasHeight = @height() - 2 * @externalPadding - @internalPadding - WorldWdgt.preferencesAndSettings.handleSize
    mainCanvasBottom = @top() + @externalPadding + mainCanvasHeight

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField._applyExtent new Point @width() - 2 * @externalPadding, mainCanvasHeight


    # buttons -------------------------------
    

    eachButtonWidth = (@width() - 2* @externalPadding - 3 * @internalPadding - WorldWdgt.preferencesAndSettings.handleSize) / 3

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


    world.maybeEnableTrackChanges()


    super
    @_markLayoutAsFixed()


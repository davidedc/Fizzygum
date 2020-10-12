# to make this error log viewer come up, edit any code
# in the inspector so to get a compilation error
# (e.g. unmatched parens) and click "save"

class ErrorsLogViewerMorph extends Widget

  tempPromptEntryField: nil
  defaultContents: ""
  textMorph: nil

  clearButton: nil
  pauseToggle: nil
  okButton: nil

  externalPadding: 0
  internalPadding: 5

  paused: false

  constructor: (@msg, @target, @callback, @defaultContents) ->
    super new Point 200,400
    @buildAndConnectChildren()

  colloquialName: ->
    "Error log"

  closeFromContainerWindow: (containerWindow) ->
    @parent.hide()

  addText: (newLog) ->
    if @textMorph.text.length != 0
      existingLog = @textMorph.text
    else
      existingLog = ""

    @textMorph.setText existingLog + "\n\n-----------------------------------------\n\n" + newLog


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


  buildAndConnectChildren: ->
    if Automator? and
     Automator.state != Automator.IDLE and
     Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @tempPromptEntryField = new SimplePlainTextScrollPanelWdgt @defaultContents, false, 5
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = Color.WHITE

    @textMorph = @tempPromptEntryField.textWdgt
    @textMorph.backgroundColor = Color.TRANSPARENT
    @textMorph.setFontName nil, nil, @textMorph.monoFontStack
    @textMorph.isEditable = true
    @textMorph.enableSelecting()

    @add @tempPromptEntryField

    # buttons -------------------------------
    @clearButton = new SimpleButtonMorph true, @, "clearTextPane", "clear"
    @add @clearButton


    pauseButton = new SimpleButtonMorph true, @, "pauseErrors", "pause"
    unpauseButton = new SimpleButtonMorph true, @, "unpauseErrors", "un-pause"
    @pauseToggle = new ToggleButtonMorph pauseButton, unpauseButton, if @paused then 1 else 0
    @add @pauseToggle

    @okButton = new SimpleButtonMorph true, @, "closeFromContainerWindow", "ok"
    @add @okButton

    @invalidateLayout()

  pauseErrors: ->
    @paused = true

  unpauseErrors: ->
    @paused = false

  clearTextPane: ->
    @textMorph.setText ""

  informTarget: ->
    @target[@callback].call @target, nil, @textMorph

  notifyTargetAndClose: ->
    @informTarget()
    @close()

  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = nil
      else
        newBoundsForThisLayout = @extent()

      if @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = nil
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    if @isCollapsed()
      @layoutIsValid = true
      return

    @rawSetBounds newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()


    mainCanvasHeight = @height() - 2 * @externalPadding - @internalPadding - WorldMorph.preferencesAndSettings.handleSize
    mainCanvasBottom = @top() + @externalPadding + mainCanvasHeight

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField.rawSetExtent new Point @width() - 2 * @externalPadding, mainCanvasHeight


    # buttons -------------------------------
    

    eachButtonWidth = (@width() - 2* @externalPadding - 3 * @internalPadding - WorldMorph.preferencesAndSettings.handleSize) / 3

    if @clearButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding + 0*(eachButtonWidth + @internalPadding), mainCanvasBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight eachButtonWidth, 15
      @clearButton.doLayout buttonBounds

    if @pauseToggle.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding + 1*(eachButtonWidth + @internalPadding), mainCanvasBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight eachButtonWidth, 15
      @pauseToggle.doLayout buttonBounds

    if @okButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding + 2*(eachButtonWidth + @internalPadding), mainCanvasBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight eachButtonWidth, 15
      @okButton.doLayout buttonBounds

    # ----------------------------------------------


    world.maybeEnableTrackChanges()
    if Automator? and
     Automator.state != Automator.IDLE and
     Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()


    super
    @layoutIsValid = true


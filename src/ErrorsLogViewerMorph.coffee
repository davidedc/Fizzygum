# ErrorsLogViewerMorph ///////////////////////////////////////////////////
# REQUIRES SimplePlainTextScrollPanelWdgt
# REQUIRES SimpleButtonMorph
# REQUIRES ToggleButtonMorph

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
    debugger
    super new Point 200,400
    @buildAndConnectChildren()

  colloquialName: ->
    "Error log"

  closeFromContainerWindow: (containerWindow) ->
    @parent.hide()

  addText: (text) ->
    if @textMorph.text.length != 0
      newText = @textMorph.text + "\n"
    else
      newText = ""

    @textMorph.setText newText + text


  showUpWithError: (err) ->
    unless @paused
      @addText err

    if !@parent.isVisible
      @parent.show()
      @parent.bringToForegroud()


  buildAndConnectChildren: ->
    debugger
    if AutomatorRecorderAndPlayer? and
     AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and
     AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @tempPromptEntryField = new SimplePlainTextScrollPanelWdgt @defaultContents, false, 5
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = new Color 255, 255, 255

    @textMorph = @tempPromptEntryField.textWdgt
    @textMorph.backgroundColor = new Color 0,0,0,0
    @textMorph.setFontName nil, nil, @textMorph.monoFontStack
    @textMorph.isEditable = true
    @textMorph.enableSelecting()

    @add @tempPromptEntryField

    # buttons -------------------------------
    @clearButton = new SimpleButtonMorph true, @, "clearTextPane", (new StringMorph2 "clear").alignCenter()
    @add @clearButton


    pauseButton = new SimpleButtonMorph true, @, "pauseErrors", (new StringMorph2 "pause").alignCenter()
    unpauseButton = new SimpleButtonMorph true, @, "unpauseErrors", (new StringMorph2 "un-pause").alignCenter()
    @pauseToggle = new ToggleButtonMorph pauseButton, unpauseButton, if @paused then 1 else 0
    @add @pauseToggle

    @okButton = new SimpleButtonMorph true, @, "closeFromContainerWindow", (new StringMorph2 "ok").alignCenter()
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
    debugger
    if !window.recalculatingLayouts
      debugger

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
      @notifyChildrenThatParentHasReLayouted()
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
    trackChanges.push false


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


    trackChanges.pop()
    if AutomatorRecorderAndPlayer? and
     AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and
     AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()


    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()



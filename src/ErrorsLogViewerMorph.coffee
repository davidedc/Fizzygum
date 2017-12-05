# ErrorsLogViewerMorph ///////////////////////////////////////////////////

class ErrorsLogViewerMorph extends WindowMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  tempPromptEntryField: nil
  defaultContents: ""
  textMorph: nil

  clearButton: nil
  pauseToggle: nil
  okButton: nil

  paused: false

  constructor: (@msg, @target, @callback, @defaultContents) ->

    topLeftButton = new HideIconButtonMorph @
    super "Errors", topLeftButton

  addText: (text) ->
    if @textMorph.text.length != 0
      newText = @textMorph.text + "\n"
    else
      newText = ""

    @textMorph.setText newText + text


  popUpWithError: (err) ->
    unless @paused
      @addText err

    if !@isVisible
      @show()
      @bringToForegroud()


  buildAndConnectChildren: ->
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    super
    
    #@tempPromptEntryField = new TextMorph2 @defaultContents,nil,nil,nil,nil,nil,new Color(255, 255, 54), 0.5
    #@tempPromptEntryField.isEditable = true
    #@add @tempPromptEntryField


    @tempPromptEntryField = new ScrollFrameMorph()
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.isTextLineWrapping = true
    @tempPromptEntryField.color = new Color 255, 255, 255

    @textMorph = new TextMorph @defaultContents
    @textMorph.isEditable = true
    @textMorph.enableSelecting()

    @tempPromptEntryField.setContents @textMorph, 2
    @add @tempPromptEntryField

    # buttons -------------------------------
    @clearButton = new SimpleButtonMorph true, @, "clearTextPane", (new StringMorph2 "clear").alignCenter()
    @add @clearButton


    pauseButton = new SimpleButtonMorph true, @, "pauseErrors", (new StringMorph2 "pause").alignCenter()
    unpauseButton = new SimpleButtonMorph true, @, "unpauseErrors", (new StringMorph2 "un-pause").alignCenter()
    @pauseToggle = new ToggleButtonMorph pauseButton, unpauseButton, if @paused then 1 else 0
    @add @pauseToggle

    @okButton = new SimpleButtonMorph true, @, "hide", (new StringMorph2 "ok").alignCenter()
    @add @okButton



    @layoutSubmorphs()

  pauseErrors: ->
    @paused = true

  unpauseErrors: ->
    @paused = false

  clearTextPane: ->
    @textMorph.setText ""    

  informTarget: ->
    @target[@callback].call @target, nil, @textMorph

  informTargetAndDestroy: ->
    @informTarget()
    @fullDestroy()

  layoutSubmorphs: (morphStartingTheChange = nil) ->
    super morphStartingTheChange
    #console.log "fixing the layout of errors log viewer"

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Morph. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false

    # label
    labelLeft = @left() + @padding
    labelTop = @top() + @padding
    labelRight = @right() - @padding
    labelWidth = labelRight - labelLeft
    labelBottom = labelTop + @label.height() + 2

    eachPaneWidth = Math.floor(@width() / 2) - @padding


    mainCanvasWidth = eachPaneWidth
    b = @bottom() - (2 * @padding) - WorldMorph.preferencesAndSettings.handleSize
    mainCanvasHeight = b - labelBottom - Math.floor(@padding / 2)
    mainCanvasBottom = labelBottom + mainCanvasHeight + Math.floor(@padding / 2)
    mainCanvasLeft = @left() + eachPaneWidth

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField.fullRawMoveTo new Point labelLeft, labelBottom + Math.floor(@padding / 2)
      @tempPromptEntryField.rawSetExtent new Point @width() - 2 * @padding, mainCanvasHeight


    # buttons -------------------------------
    

    eachButtonWidth = (@width() - 5* @padding - WorldMorph.preferencesAndSettings.handleSize) / 3

    if @clearButton.parent == @
      @clearButton.fullRawMoveTo new Point @left() + @padding + 0*(eachButtonWidth + @padding), mainCanvasBottom + @padding
      @clearButton.rawSetExtent new Point eachButtonWidth, 15

    if @pauseToggle.parent == @
      @pauseToggle.fullRawMoveTo new Point @left() + @padding + 1*(eachButtonWidth + @padding), mainCanvasBottom + @padding
      @pauseToggle.rawSetExtent new Point eachButtonWidth, 15

    if @okButton.parent == @
      @okButton.fullRawMoveTo new Point @left() + @padding + 2*(eachButtonWidth + @padding), mainCanvasBottom + @padding
      @okButton.rawSetExtent new Point eachButtonWidth, 15

    # ----------------------------------------------


    trackChanges.pop()
    @changed()
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()


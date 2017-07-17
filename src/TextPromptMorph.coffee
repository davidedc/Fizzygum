# TextPromptMorph ///////////////////////////////////////////////////

class TextPromptMorph extends WindowMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  tempPromptEntryField: null
  defaultContents: ""
  textMorph: null

  cancelButton: null
  saveButton: null
  okButton: null

  constructor: (@msg, @target, @callback, @defaultContents) ->
    super "Edit tool code"

  buildAndConnectChildren: ->
    debugger
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # submorphs of the inspector. If they
    # have been peeled away, they still live
    #@fullDestroyChildrenButNotTheShadow()

    super
    
    #@tempPromptEntryField = new TextMorph2 @defaultContents,null,null,null,null,null,new Color(255, 255, 54), 0.5
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
    @cancelButton = new SimpleButtonMorph true, @, "fullDestroy", (new StringMorph2 "cancel").alignCenter()
    @add @cancelButton

    @saveButton = new SimpleButtonMorph true, @, "informTarget", (new StringMorph2 "save").alignCenter()
    @add @saveButton

    @okButton = new SimpleButtonMorph true, @, "informTargetAndDestroy", (new StringMorph2 "ok").alignCenter()
    @add @okButton



    @layoutSubmorphs()

  informTarget: ->
    debugger
    @target[@callback].call @target, null, @textMorph

  informTargetAndDestroy: ->
    @informTarget()
    @fullDestroy()

  layoutSubmorphs: (morphStartingTheChange = null) ->
    super morphStartingTheChange
    console.log "fixing the layout of the inspector"

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

    if @cancelButton.parent == @
      @cancelButton.fullRawMoveTo new Point @left() + @padding + 0*(eachButtonWidth + @padding), mainCanvasBottom + @padding
      @cancelButton.rawSetExtent new Point eachButtonWidth, 15

    if @saveButton.parent == @
      @saveButton.fullRawMoveTo new Point @left() + @padding + 1*(eachButtonWidth + @padding), mainCanvasBottom + @padding
      @saveButton.rawSetExtent new Point eachButtonWidth, 15

    if @okButton.parent == @
      @okButton.fullRawMoveTo new Point @left() + @padding + 2*(eachButtonWidth + @padding), mainCanvasBottom + @padding
      @okButton.rawSetExtent new Point eachButtonWidth, 15

    # ----------------------------------------------


    trackChanges.pop()
    @changed()
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()


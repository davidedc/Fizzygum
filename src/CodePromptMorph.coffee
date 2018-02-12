# CodePromptMorph ///////////////////////////////////////////////////

class CodePromptMorph extends DEPRECATEDWindowMorph

  tempPromptEntryField: nil
  defaultContents: ""
  textMorph: nil

  cancelButton: nil
  saveButton: nil
  okButton: nil

  constructor: (@msg, @target, @callback, @defaultContents) ->
    super "Edit tool code"

  buildAndConnectChildren: ->
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # submorphs of the inspector. If they
    # have been peeled away, they still live
    #@fullDestroyChildren()

    super
    
    #@tempPromptEntryField = new TextMorph2 @defaultContents,nil,nil,nil,nil,nil,new Color(255, 255, 54), 0.5
    #@tempPromptEntryField.isEditable = true
    #@add @tempPromptEntryField


    @tempPromptEntryField = new ScrollPanelWdgt()
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = new Color 255, 255, 255

    @textMorph = new SimplePlainTextWdgt @defaultContents
    @textMorph.setFontName nil, nil, @textMorph.monoFontStack     
    @textMorph.isEditable = true
    @textMorph.enableSelecting()

    @tempPromptEntryField.setContents @textMorph, 5
    @textMorph.softWrapOff()

    @add @tempPromptEntryField

    # buttons -------------------------------
    @cancelButton = new SimpleButtonMorph true, @, "close", (new StringMorph2 "cancel").alignCenter()
    @add @cancelButton

    @saveButton = new SimpleButtonMorph true, @, "informTarget", (new StringMorph2 "save").alignCenter()
    @add @saveButton

    @okButton = new SimpleButtonMorph true, @, "notifyTargetAndClose", (new StringMorph2 "ok").alignCenter()
    @add @okButton

    @invalidateLayout()

  informTarget: ->
    @target[@callback].call @target, nil, @textMorph

  notifyTargetAndClose: ->
    @informTarget()
    @close()

  doLayout: (newBoundsForThisLayout) ->
    if !window.recalculatingLayouts
      debugger

    if @isCollapsed()
      @layoutIsValid = true
      @notifyChildrenThatParentHasReLayouted()
      return

    super

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
      buttonBounds = new Rectangle new Point @left() + @padding + 0*(eachButtonWidth + @padding), mainCanvasBottom + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight eachButtonWidth, 15
      @cancelButton.doLayout buttonBounds 

    if @saveButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @padding + 1*(eachButtonWidth + @padding), mainCanvasBottom + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight eachButtonWidth, 15
      @saveButton.doLayout buttonBounds 

    if @okButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @padding + 2*(eachButtonWidth + @padding), mainCanvasBottom + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight eachButtonWidth, 15
      @okButton.doLayout buttonBounds 

    # ----------------------------------------------


    trackChanges.pop()
    @fullChanged()
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()


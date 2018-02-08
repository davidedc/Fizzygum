# StringFieldWdgt2 ////////////////////////////////////////////////////
# Like StringFieldMorph, but it uses the StringMorph2

# REQUIRES StringMorph2

class StringFieldWdgt2 extends PanelWdgt

  defaultContents: nil
  minTextWidth: nil
  fontSize: nil
  fontStyle: nil
  isBold: nil
  isItalic: nil
  isNumeric: nil
  text: nil
  isEditable: true

  constructor: (
      @defaultContents = "",
      @minTextWidth = 100,
      @fontSize = 12,
      @fontStyle = "sans-serif",
      @isBold = false,
      @isItalic = false,
      @isNumeric = false
      ) ->
    super()
    @color = new Color 255, 255, 255

  rawSetWidth: (newWidth)->
    super
    @text.rawSetWidth newWidth


  calculateAndUpdateExtent: ->
    txt = (if @text then @getValue() else @defaultContents)
    text = new StringMorph2 txt, @fontSize, @fontStyle, @isBold, @isItalic, false, @isNumeric
    text.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN   
    #console.log "text morph extent: " + text.text + " : " + text.extent()
    @rawSetWidth Math.max @minTextWidth, text.width()
    #console.log "string field morph extent: " + @extent()

  reLayout: ->
    super()
    txt = (if @text then @getValue() else @defaultContents)
    if !@text?
      @text = new StringMorph2(txt, @fontSize, @fontStyle, @isBold, @isItalic, false, @isNumeric)
      @text.isNumeric = @isNumeric # for whichever reason...
      @text.isEditable = @isEditable
      @text.enableSelecting() 
      @text.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
      @add @text
    @text.fullRawMoveTo @position().add new Point 5,2
    @silentRawSetExtent new Point @width(), 18
    @notifyChildrenThatParentHasReLayouted()

  
  getValue: ->
    @text.text
  
  mouseClickLeft: (pos)->
    @bringToForegroud()
    if @isEditable
      @text.edit()
    else
      @escalateEvent 'mouseClickLeft', pos
  
  
# StringFieldMorph ////////////////////////////////////////////////////
# a stringMorph that can "scroll" as the cursor moves along the text
# but note that there are no scrollbars, since the container
# is just a Panel not a ScrollPanel.

class StringFieldMorph extends PanelWdgt

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
    text = new StringMorph txt, @fontSize, @fontStyle, @isBold, @isItalic, @isNumeric
    #console.log "text morph extent: " + text.text + " : " + text.extent()
    @rawSetWidth Math.max @minTextWidth, text.width()
    console.log "string fleid morph extent: " + @extent()

  reLayout: ->
    super()
    txt = (if @text then @getValue() else @defaultContents)
    @text = nil
    @fullDestroyChildren()
    @text = new StringMorph(txt, @fontSize, @fontStyle, @isBold, @isItalic, @isNumeric)
    @text.isNumeric = @isNumeric # for whichever reason...
    @text.fullRawMoveTo @position()
    @text.isEditable = @isEditable
    @text.enableSelecting()    
    @silentRawSetExtent new Point Math.max(@width(), @minTextWidth), @text.height()
    @add @text
    @notifyChildrenThatParentHasReLayouted()

  
  getValue: ->
    @text.text
  
  mouseClickLeft: (pos)->
    @bringToForegroud()
    if @isEditable
      @text.edit()
    else
      @escalateEvent 'mouseClickLeft', pos
  
  
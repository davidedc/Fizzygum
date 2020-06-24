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
    @color = Color.WHITE

  rawSetWidth: (newWidth)->
    super
    @text.rawSetWidth newWidth


  calculateAndUpdateExtent: ->
    txt = (if @text then @getValue() else @defaultContents)
    text = new StringMorph txt, @fontSize, @fontStyle, @isBold, @isItalic, @isNumeric
    #console.log "text morph extent: " + text.text + " : " + text.extent()
    @rawSetWidth Math.max @minTextWidth, text.width()
    #console.log "string field morph extent: " + @extent()

  reLayout: ->
    super()
    txt = (if @text then @getValue() else @defaultContents)
    if !@text?
      @text = new StringMorph(txt, @fontSize, @fontStyle, @isBold, @isItalic, @isNumeric)
      @text.isNumeric = @isNumeric # for whichever reason...
      @text.isEditable = @isEditable
      @text.enableSelecting()    
      @add @text
    @text.fullRawMoveTo @position()
    @silentRawSetExtent new Point Math.max(@width(), @minTextWidth), @text.height()
    @notifyChildrenThatParentHasReLayouted()

  
  getValue: ->
    @text.text
  
  mouseClickLeft: (pos)->
    @bringToForeground()
    if @isEditable
      @text.edit()
    else
      @escalateEvent 'mouseClickLeft', pos
  
  
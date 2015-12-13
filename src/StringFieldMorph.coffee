# StringFieldMorph ////////////////////////////////////////////////////

class StringFieldMorph extends FrameMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  defaultContents: null
  minWidth: null
  fontSize: null
  fontStyle: null
  isBold: null
  isItalic: null
  isNumeric: null
  text: null
  isEditable: true

  constructor: (
      @defaultContents = "",
      @minWidth = 100,
      @fontSize = 12,
      @fontStyle = "sans-serif",
      @isBold = false,
      @isItalic = false,
      @isNumeric = false
      ) ->
    super()
    @color = new Color(255, 255, 255)

  rawSetWidth: (newWidth)->
    super(newWidth)
    @text.rawSetWidth(newWidth)


  calculateAndUpdateExtent: ->
    txt = (if @text then @getValue() else @defaultContents)
    text = new StringMorph(txt, @fontSize, @fontStyle, @isBold, @isItalic, @isNumeric)
    console.log "text morph extent: " + text.text + " : " + text.extent()
    @rawSetWidth(Math.max(@minWidth,text.width()))
    console.log "string fleid morph extent: " + @extent()

  reLayout: ->
    super()
    txt = (if @text then @getValue() else @defaultContents)
    @text = null
    @fullDestroyChildren()
    @text = new StringMorph(txt, @fontSize, @fontStyle, @isBold, @isItalic, @isNumeric)
    @text.isNumeric = @isNumeric # for whichever reason...
    @text.fullRawMoveTo @position()
    @text.isEditable = @isEditable
    @text.enableSelecting()    
    @silentRawSetExtent new Point(Math.max(@width(), @minWidth), @text.height())
    @add @text
    @notifyChildrenThatParentHasReLayouted()

  
  getValue: ->
    @text.text
  
  mouseClickLeft: (pos)->
    super()
    if @isEditable
      @text.edit()
    else
      @escalateEvent 'mouseClickLeft', pos
  
  
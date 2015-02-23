# StringFieldMorph ////////////////////////////////////////////////////

class StringFieldMorph extends FrameMorph

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
  
  updateBackingStore: ->
    txt = (if @text then @getValue() else @defaultContents)
    @text = null
    @destroyAll()
    #
    @children = []
    @text = new StringMorph(txt, @fontSize, @fontStyle, @isBold, @isItalic, @isNumeric)
    @text.isNumeric = @isNumeric # for whichever reason...
    @text.setPosition @bounds.origin.copy()
    @text.isEditable = @isEditable
    @text.isDraggable = false
    @text.enableSelecting()
    @silentSetExtent new Point(Math.max(@width(), @minWidth), @text.height())
    super()
    @add @text
  
  getValue: ->
    @text.text
  
  mouseClickLeft: (pos)->
    if @isEditable
      @text.edit()
    else
      @escalateEvent 'mouseClickLeft', pos
  
  
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
    @drawNew()
  
  drawNew: ->
    txt = (if @text then @string() else @defaultContents)
    @text = null
    @children.forEach (child) ->
      child.destroy()
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
  
  string: ->
    @text.text
  
  mouseClickLeft: ->
    @text.edit()  if @isEditable
  
  
  # StringFieldMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.text = (dict[@text])  if c.text and dict[@text]
    c

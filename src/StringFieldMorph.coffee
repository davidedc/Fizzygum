# StringFieldMorph ////////////////////////////////////////////////////

class StringFieldMorph extends FrameMorph
  constructor: (defaultContents, minWidth, fontSize, fontStyle, bold, italic, isNumeric) ->
    @init defaultContents or "", minWidth or 100, fontSize or 12, fontStyle or "sans-serif", bold or false, italic or false, isNumeric

StringFieldMorph::init = (defaultContents, minWidth, fontSize, fontStyle, bold, italic, isNumeric) ->
  @defaultContents = defaultContents
  @minWidth = minWidth
  @fontSize = fontSize
  @fontStyle = fontStyle
  @isBold = bold
  @isItalic = italic
  @isNumeric = isNumeric or false
  @text = null
  super()
  @color = new Color(255, 255, 255)
  @isEditable = true
  @acceptsDrops = false
  @drawNew()

StringFieldMorph::drawNew = ->
  txt = undefined
  txt = (if @text then @string() else @defaultContents)
  @text = null
  @children.forEach (child) ->
    child.destroy()
  
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

StringFieldMorph::string = ->
  @text.text

StringFieldMorph::mouseClickLeft = ->
  @text.edit()  if @isEditable


# StringFieldMorph duplicating:
StringFieldMorph::copyRecordingReferences = (dict) ->
  
  # inherited, see comment in Morph
  c = super dict
  c.text = (dict[@text])  if c.text and dict[@text]
  c

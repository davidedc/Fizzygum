# StringFieldMorph ////////////////////////////////////////////////////

class StringFieldMorph extends FrameMorph
  constructor: (defaultContents, minWidth, fontSize, fontStyle, bold, italic, isNumeric) ->
    @defaultContents = defaultContents or ""
    @minWidth = minWidth or 100
    @fontSize = fontSize or 12
    @fontStyle = fontStyle or "sans-serif"
    @isBold = bold or false
    @isItalic = italic or false
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

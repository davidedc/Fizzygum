# OldStyleTextMorph ///////////////////////////////////////////////////////////

# A multi-line, word-wrapping String
# OldStyleTextMorph is a compatibility layer that lets us use the new
# TextMorph2 as the old TextMorph.
#
# We do this because the old TextMorph can still do stuff that
# the TextMorph2 is not quite ready to do (i.e. old TextMorph could
# adjust its vertical size to fit its contents, which is what normal
# text editing looks like. TextMorph2 could also do that, but it can
# do that within a larger layout work that has not been done yet)
# but at the same time the underlying TextMorph2 can do a bunch
# more stuff and it's what is being worked on moving
# forward, hence this nasty but useful compatibility structure.

class OldStyleTextMorph extends TextMorph2

  oldStyleTextMorph: true

  constructor: (
   @text = "OldStyleTextMorph",
   @originallySetFontSize = 12,
   @fontName = @justArialFontStack,
   @isBold = false,
   @isItalic = false,
   #@isNumeric = false,
   @color = (new Color 0, 0, 0),
   @backgroundColor = nil,
   @backgroundTransparency = nil
   ) ->

    super
    @silentRawSetBounds new Rectangle 0,0,400,40
    @fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.FLOAT
    @fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    @reLayout()

  # This is also invoked for example when you take a slider
  # and set it to target this.
  setText: (theTextContent, stringFieldMorph) ->
    super
    @reLayout()

  setExtent: (aPoint) ->
    super
    @reLayout()

  reLayout: ->
    debugger
    super()
    [@wrappedLines,@wrappedLineSlots,@widthOfPossiblyCroppedText,@heightOfPossiblyCroppedText] =
      @breakTextIntoLines @text, @originallySetFontSize, @extent()
    height = @wrappedLines.length *  Math.ceil fontHeight @originallySetFontSize
    @silentRawSetExtent new Point @width(), height
    @changed()
    @parent.layoutChanged()  if @parent.layoutChanged  if @parent
    @notifyChildrenThatParentHasReLayouted()

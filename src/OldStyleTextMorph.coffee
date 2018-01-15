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
    @maxTextWidth = true
    @reLayout()

  addMorphSpecificMenuEntries: (morphOpeningTheMenu, menu) ->
    super
    menu.removeMenuItem "soft wrap"
    menu.removeMenuItem "soft wrap".tick()
    menu.removeMenuItem "soft wrap"

    menu.removeMenuItem "←☓→ don't expand to fill"
    menu.removeMenuItem "←→ expand to fill"
    menu.removeMenuItem "→← shrink to fit"
    menu.removeMenuItem "→⋯← crop to fit"

    menu.removeMenuItem "header line"
    menu.removeMenuItem "no header line"

    menu.removeMenuItem "↑ align top"
    menu.removeMenuItem "⍿ align middle"
    menu.removeMenuItem "↓ align bottom"

    if @amIDirectlyInsideScrollFrame()
      childrenNotCarets = @parent.children.filter (m) ->
        !(m instanceof CaretMorph)
      if childrenNotCarets.length == 1
        menu.addLine()
        if @parent.parent.isTextLineWrapping
          menu.addMenuItem "☒ soft wrap", true, @, "softWrapOff"
        else
          menu.addMenuItem "☐ soft wrap", true, @, "softWrapOn"

    menu.removeConsecutiveLines()


  softWrapOn: ->
    debugger

    @parent.parent.isTextLineWrapping = true
    @maxTextWidth = true

    @parent.fullRawMoveTo @parent.parent.position()
    @parent.rawSetExtent @parent.parent.extent()
    @refreshScrollFrameIfIamInIt()

  refreshScrollFrameIfIamInIt: ->
    if @amIDirectlyInsideScrollFrame()
      @parent.parent.adjustContentsBounds()
      @parent.parent.adjustScrollBars()

  softWrapOff: ->
    debugger

    @parent.parent.isTextLineWrapping = false
    @maxTextWidth = nil

    @reLayout()

    @refreshScrollFrameIfIamInIt()


  # This is also invoked for example when you take a slider
  # and set it to target this.
  setText: (theTextContent, stringFieldMorph) ->
    super
    @reLayout()
    @refreshScrollFrameIfIamInIt()

  toggleShowBlanks: ->
    super
    @reLayout()
    @refreshScrollFrameIfIamInIt()
  
  toggleWeight: ->
    super
    @reLayout()
    @refreshScrollFrameIfIamInIt()
  
  toggleItalic: ->
    super
    @reLayout()
    @refreshScrollFrameIfIamInIt()

  toggleIsPassword: ->
    super
    @reLayout()
    @refreshScrollFrameIfIamInIt()

  rawSetExtent: (aPoint) ->
    super
    @reLayout()

  setFontSize: (sizeOrMorphGivingSize, morphGivingSize) ->
    super
    @reLayout()
    @refreshScrollFrameIfIamInIt()

  setFontName: (ignored1, ignored2, theNewFontName) ->
    super
    @reLayout()
    @refreshScrollFrameIfIamInIt()

  reLayout: ->
    super()

    if @maxTextWidth? and @maxTextWidth != 0
      @softWrap = true
      [@wrappedLines,@wrappedLineSlots,@widthOfPossiblyCroppedText,@heightOfPossiblyCroppedText] =
        @breakTextIntoLines @text, @originallySetFontSize, @extent()
      width = @width()
    else
      @softWrap = false
      veryWideExtent = new Point 10000000, 10000000
      [@wrappedLines,@wrappedLineSlots,@widthOfPossiblyCroppedText,@heightOfPossiblyCroppedText] =
        @breakTextIntoLines @text, @originallySetFontSize, veryWideExtent
      width = @widthOfPossiblyCroppedText

    height = @wrappedLines.length *  Math.ceil fontHeight @originallySetFontSize
    @silentRawSetExtent new Point width, height

    @changed()
    @notifyChildrenThatParentHasReLayouted()


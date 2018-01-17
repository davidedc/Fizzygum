# TextMorph2BridgeForWrappingText ///////////////////////////////////////////////////////////

# A multi-line, word-wrapping string.
# TextMorph2BridgeForWrappingText is a compatibility layer that lets us use the new
# TextMorph2 with the current ScrollFrame and the current layout mechanism (which
# we'd want to change with a more generic one but it's a complex process).
#
# This Morph can do stuff that the TextMorph2 is not quite ready to do (i.e. can
# adjust its vertical size to fit its contents in the given width, which is what
# "normal" text editing looks like.
#
# TextMorph2 could also be used to do that, but it could do that within a larger
# layout rework that has not been done yet. Note that TextMorph2 can do a bunch more
# stuff (e.g. lets you edit in "centered" text, can fit the text to any given
# bound etc...)

class TextMorph2BridgeForWrappingText extends TextMorph2

  constructor: (
   @text = "TextMorph2BridgeForWrappingText",
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
    @refreshScrollFrameOrVerticalStackIfIamInIt()

  refreshScrollFrameOrVerticalStackIfIamInIt: ->
    if @amIDirectlyInsideScrollFrame()
      @parent.parent.adjustContentsBounds()
      @parent.parent.adjustScrollBars()
    if @parent instanceof VerticalStackWdgt
      @parent.adjustContentsBounds()

  softWrapOff: ->
    debugger

    @parent.parent.isTextLineWrapping = false
    @maxTextWidth = nil

    @reLayout()

    @refreshScrollFrameOrVerticalStackIfIamInIt()


  # This is also invoked for example when you take a slider
  # and set it to target this.
  setText: (theTextContent, stringFieldMorph) ->
    super
    @reLayout()
    @refreshScrollFrameOrVerticalStackIfIamInIt()

  toggleShowBlanks: ->
    super
    @reLayout()
    @refreshScrollFrameOrVerticalStackIfIamInIt()
  
  toggleWeight: ->
    super
    @reLayout()
    @refreshScrollFrameOrVerticalStackIfIamInIt()
  
  toggleItalic: ->
    super
    @reLayout()
    @refreshScrollFrameOrVerticalStackIfIamInIt()

  toggleIsPassword: ->
    super
    @reLayout()
    @refreshScrollFrameOrVerticalStackIfIamInIt()

  rawSetExtent: (aPoint) ->
    super
    @reLayout()

  setFontSize: (sizeOrMorphGivingSize, morphGivingSize) ->
    super
    @reLayout()
    @refreshScrollFrameOrVerticalStackIfIamInIt()

  setFontName: (ignored1, ignored2, theNewFontName) ->
    super
    @reLayout()
    @refreshScrollFrameOrVerticalStackIfIamInIt()

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


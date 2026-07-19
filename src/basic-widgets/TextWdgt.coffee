# A multi-line, word-wrapping String
#
# TODO Note that this class has problems with text that has multi-code characters, i.e. characters that for a cursor behave like a single character
# (i.e. the cursor moves around them with one single arrow key press) BUT that, unintuitively, have .length property > 1 (e.g. "ä".length is 2)
# this is because the code assumes that the .length property of a string is the number of characters in the string, which, as in the "ä"
# example, is not true.

class TextWdgt extends StringWdgt

  wrappedLines: []
  wrappedLineSlots: []
  softWrap: true

  backgroundColor: nil

  #additional properties for ad-hoc evaluation:
  receiver: nil
  heightOfPossiblyCroppedText: nil
  widthOfPossiblyCroppedText: nil

  constructor: (
   @text = "TextWdgt",
   @originallySetFontSize = WorldWdgt.preferencesAndSettings.normalTextFontSize,
   @fontName = @justArialFontStack,
   @isBold = false,
   @isItalic = false,
   @color,
   @backgroundColor = nil,
   @backgroundTransparency = nil
   ) ->

    super(
      @text,
      @originallySetFontSize,
      @fontName,
      @isBold,
      @isItalic,
      false, # isHeaderLine
      false, # isNumeric
      @color,
      @backgroundColor,
      @backgroundTransparency
      )
    # override inherited properties:
    @markedTextColor = Color.WHITE
    @markedBackgroundColor = Color.create 60, 60, 120
    @textPossiblyCroppedToFit = @transformTextOneToOne @text
    @noticesTransparentClick = true

    @fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.CROP
  

  # there are many factors beyond the font size that affect
  # the measuring, such as font style, but we only pass
  # the font size here because is the one we are going to
  # change when we do the binary search for trying to
  # see the largest fitting size.
  doesTextFitInExtent: (text = (@transformTextOneToOne @text), overrideFontSize) ->
    if text == ""
      return true
    doesItFit = @breakTextIntoLines text, overrideFontSize, @extent()
    return doesItFit

  getParagraphs: (text) ->
    cacheKey = text.hashCode()
    paragraphs = world.cacheForTextParagraphSplits.get cacheKey
    if paragraphs? then return paragraphs
    paragraphs = text.split "\n"
    world.cacheForTextParagraphSplits.set cacheKey, paragraphs
    paragraphs

  getWordsOfParagraph: (eachParagraph) ->
    cacheKey = eachParagraph.hashCode()
    wordsOfThisParagraph = world.cacheForParagraphsWordsSplits.get cacheKey
    if wordsOfThisParagraph? then return wordsOfThisParagraph
    wordsOfThisParagraph = eachParagraph.split " "
    wordsOfThisParagraph.push "\n"
    world.cacheForParagraphsWordsSplits.set cacheKey, wordsOfThisParagraph
    wordsOfThisParagraph

  replaceLastSpaceWithInvisibleCarriageReturn: (string) ->
    string = string.substr(0, string.length-1)
    string = string + @emptyCharacter

  getWrappingData: (overrideFontSize, maxTextWidth, eachParagraph, wordsOfThisParagraph) ->
    cacheKey = @buildCanvasFontProperty(overrideFontSize) + "-" + maxTextWidth + "-" + eachParagraph.hashCode()
    wrappingData = world.cacheForParagraphsWrappingData.get cacheKey


    if wrappingData? then return wrappingData
    wrappedLinesOfThisParagraph = []
    wrappedLineSlotsOfThisParagraph = []
    maxWrappedLineWidthOfThisParagraph = 0

    currentLine = ""
    slotsInParagraph = 0

    # currently unused because token-level wrapping
    # is commented-out, see below
    carryoverFromWrappingLine = ""

    for word in wordsOfThisParagraph

      # TOKEN-LEVEL WRAPPING (breaking a single too-long token) is not implemented:
      # wrapping a token can shrink/grow the line, changing whether it still needs
      # to wrap -- no fixed point in general. Only safe if the box is width-
      # constrained but not height-constrained.


      if word is "\n"
        # we reached the end of the line in the
        # original text, so push the line and the
        # slotsInParagraph count in the arrays
        currentLine = @replaceLastSpaceWithInvisibleCarriageReturn currentLine
        wrappedLinesOfThisParagraph.push currentLine
        wrappedLineSlotsOfThisParagraph.push slotsInParagraph
        maxWrappedLineWidthOfThisParagraph = Math.max maxWrappedLineWidthOfThisParagraph, Math.ceil @measureText overrideFontSize, currentLine
        currentLine = ""
      else
        if maxTextWidth > 0 # there is a width limit, we might have to wrap
          # there is a width limit, so we need
          # to check whether we overflowed it. So create
          # a prospective line and then check its width.
          lineForOverflowTest = currentLine + word + " "
          w = Math.ceil @measureText overrideFontSize, lineForOverflowTest
          if w > maxTextWidth
            # ok we just overflowed the available space,
            # so we need to push the line *without the last word*
            # and the corresponding "slotsInParagraph" number in the
            # respective arrays.
            # the new line is going to only contain the
            # word that has caused the overflow.

            currentLine = @replaceLastSpaceWithInvisibleCarriageReturn currentLine
            # if we don't do this test there is a strange behaviour
            # when one types a very long word
            if currentLine != @emptyCharacter
              wrappedLinesOfThisParagraph.push currentLine
              wrappedLineSlotsOfThisParagraph.push slotsInParagraph
              maxWrappedLineWidthOfThisParagraph = Math.max maxWrappedLineWidthOfThisParagraph, Math.ceil @measureText overrideFontSize, currentLine
            currentLine = word + " "
          else
            # no overflow happened, so just proceed as normal
            currentLine = lineForOverflowTest
        else # there is no width limit, we never have to wrap
          currentLine = currentLine + word + " "
        slotsInParagraph += word.length + 1

    # words of this paragraph have been scanned
    wrappingDataCacheEntry = [wrappedLinesOfThisParagraph,wrappedLineSlotsOfThisParagraph,maxWrappedLineWidthOfThisParagraph, slotsInParagraph]
    world.cacheForParagraphsWrappingData.set cacheKey, wrappingDataCacheEntry
    wrappingData = wrappingDataCacheEntry

  # there are many factors beyond the font size that affect
  # how the text wraps, such as font style, but we only pass
  # the font size here because is the one we are going to
  # change when we do the binary search for trying to
  # see the largest fitting size.
  getTextWrappingData: (overrideFontSize, maxTextWidth, text, paragraphs, justCheckIfItFitsInThisExtent) ->
    # FIT_BOX_TO_TEXT renders at the SET font size and grows the box to the text
    # (it never scales the font or crops to fit), so never take the fit-check
    # fast-path and always measure at @originallySetFontSize. The behaviour
    # follows the mode, not the subclass, so a bare contained TextWdgt gets it too.
    if @fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
      justCheckIfItFitsInThisExtent = null
      overrideFontSize = @originallySetFontSize

    cacheKey = @buildCanvasFontProperty(overrideFontSize) + "-" + maxTextWidth + "-" + text.hashCode() + "-" + justCheckIfItFitsInThisExtent
    textWrappingData = world.cacheForTextWrappingData.get cacheKey
    if textWrappingData? then return textWrappingData
    wrappedLinesOfWholeText = []
    wrappedLineSlotsOfWholeText = [0]
    maxWrappedLineWidthOfWholeText = 0
    cumulativeSlotAcrossText = 0
    previousCumulativeSlotAcrossText = 0

    for eachParagraph in paragraphs

      wordsOfThisParagraph = @getWordsOfParagraph eachParagraph



      ## LATER FOR ANOTHER TIME IS TO MAKE THE PAINTING ALSO FAST.
      ## You'd also love to cache the bitmap of each paragraph
      ## rather than keeping one huge bitmap.
      ## so this wouldn't be a BackBuffer anymore
      ## SO you need to REMOVE the mixin from this class.
      ## cause there would be a paint method and it would
      ## compose the
      ## it would be much better to handle AND in theory
      ## the single bitmaps per paragraph would be easy
      ## to cache and could be created
      ## only on demand if they ever get damaged.
      ## GET THE stringWidget2 to cache the actual bitmap that they
      ## generate so you can use that too from here, cause there
      ## might be a lot of reuse rather than re-painting the
      ## text all the times or even a paragraph.

      # takes the text, word by word, and re-flows
      # it according to the available width for the
      # text (if there is such limit).
      # The end result is an array of lines
      # called @wrappedLines, which contains the string for
      # each line (excluding the end of lines).
      # Also another array is created, called
      # @wrappedLineSlots, which memorises how many characters
      # of the text have been consumed up to each line
      #  example: original text: "Hello\nWorld"
      # then @wrappedLines[0] = "Hello" @wrappedLines[1] = "World"
      # and @wrappedLineSlots[0] = 6, @wrappedLineSlots[1] = 11
      # Note that this algorithm doesn't work in case
      # of single non-spaced words that are longer than
      # the allowed width.
      
      wrappingData = @getWrappingData overrideFontSize, maxTextWidth, eachParagraph, wordsOfThisParagraph

      # we either cache-hit wrappingData or we re-built it
      [wrappedLinesOfThisParagraph, wrappedLineSlotsOfThisParagraph, maxWrappedLineWidthOfThisParagraph, slotsInParagraph] = wrappingData

      previousCumulativeSlotAcrossText = cumulativeSlotAcrossText
      cumulativeSlotAcrossText += slotsInParagraph
      wrappedLinesOfWholeText = wrappedLinesOfWholeText.concat wrappedLinesOfThisParagraph
      advancedWrappedLineSlotsOfThisParagraph =  wrappedLineSlotsOfThisParagraph.map (i) -> i + previousCumulativeSlotAcrossText
      wrappedLineSlotsOfWholeText = wrappedLineSlotsOfWholeText.concat advancedWrappedLineSlotsOfThisParagraph
      maxWrappedLineWidthOfWholeText = Math.max maxWrappedLineWidthOfWholeText, maxWrappedLineWidthOfThisParagraph

      if justCheckIfItFitsInThisExtent?
        heightOfPossiblyCroppedText = (wrappedLineSlotsOfWholeText.length - 1) * Math.ceil(@fontHeight overrideFontSize)
        if heightOfPossiblyCroppedText > justCheckIfItFitsInThisExtent.y or maxWrappedLineWidthOfWholeText > justCheckIfItFitsInThisExtent.x
          world.cacheForTextWrappingData.set cacheKey, false
          return false



    if justCheckIfItFitsInThisExtent?
      world.cacheForTextWrappingData.set cacheKey, true
      return true
    heightOfPossiblyCroppedText = wrappedLinesOfWholeText.length * Math.ceil(@fontHeight overrideFontSize)
    textWrappingDataCacheEntry = [wrappedLinesOfWholeText, wrappedLineSlotsOfWholeText, maxWrappedLineWidthOfWholeText, heightOfPossiblyCroppedText]
    world.cacheForTextWrappingData.set cacheKey, textWrappingDataCacheEntry
    textWrappingData = textWrappingDataCacheEntry

  # there are many factors beyond the font size that affect
  # how the text is broken, such as font style, but we only pass
  # the font size here because is the one we are going to
  # change when we do the binary search for trying to
  # see the largest fitting size.
  breakTextIntoLines: (text = (@transformTextOneToOne @text), overrideFontSize, justCheckIfItFitsInThisExtent, widthOverride) ->

    # FIT_BOX_TO_TEXT always breaks the text at the SET font size (the box is what
    # grows; the font is never scaled).
    if @fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
      overrideFontSize = @originallySetFontSize

    # Easy, lazy way to get soft-wrapping.
    # TODO you can actually simplify lots of code in the
    # case of soft-wrapping as really there is a lot
    # less to measure and the wrapping becomes trivial.
    # Also testing if it fits in an extent can be made
    # really easy.
    if @softWrap
      # widthOverride lets the pure measure (preferredExtentForWidth, §4.1 proper-layouts)
      # wrap at an EXPLICIT available width instead of the applied @width(). Without it this
      # is the unchanged commit path: an undefined override falls through to @width().
      widgetWidth = widthOverride ? @width()
    else
      widgetWidth = Number.MAX_VALUE

    cacheKey = text.hashCode() + "-" + @buildCanvasFontProperty(overrideFontSize) + "-" + widgetWidth + "-" + justCheckIfItFitsInThisExtent
    textWrappingData = world.cacheForTextBreakingIntoLinesTopLevel.get cacheKey
    if textWrappingData? then return textWrappingData


    

    paragraphs = @getParagraphs text

    textWrappingData = @getTextWrappingData overrideFontSize, widgetWidth, text, paragraphs, justCheckIfItFitsInThisExtent


    world.cacheForTextBreakingIntoLinesTopLevel.set cacheKey, textWrappingData
    return textWrappingData

  # §4.1 PURE MEASURE (proper-layouts): the side-effect-free preferred extent of this
  # wrapping text -- round+min-extent clamp MUST mirror __commitExtent (byte-matches the
  # commit). Campaign history: docs/archive/proper-layouts-4.1-pure-measure-campaign-plan.md
  preferredExtentForWidth: (availW) ->
    # a non-growing text keeps its box (FIT_TEXT_TO_BOX scales/crops the text, it does not
    # size to it), so its preferred extent is simply its current extent.
    if @fittingSpec != FittingSpecText.FIT_BOX_TO_TEXT then return @extent()
    if @softWrap
      wrapW = Math.round availW
      minExtent = @getMinimumExtent()
      if minExtent? and wrapW < minExtent.x then wrapW = minExtent.x
      tuple = @breakTextIntoLines @text, @originallySetFontSize, @extent(), wrapW
      measuredWidth = wrapW
    else
      veryWideExtent = new Point 10000000, 10000000
      tuple = @breakTextIntoLines @text, @originallySetFontSize, veryWideExtent
      measuredWidth = tuple[2]   # the natural (un-wrapped) max line width
    measuredHeight = tuple[0].length * Math.ceil @fontHeight @originallySetFontSize
    return new Point measuredWidth, measuredHeight

  # Wrapping text is FILL-CLASS in a stack BY TYPE: its box tracks the column and the text
  # re-wraps to it -- that is what wrapping MEANS -- so a FIT_BOX_TO_TEXT text gets an
  # EXPLICIT grow 1 instead of the base add-time derivation (which would freeze a paragraph
  # dropped narrower than the column at its drop width, killing the re-wrap-on-resize
  # affordance -- asserted by macroStackPanelLooseWhenEmptyTightWhenFilled image_3). The
  # class-owned-explicit-grow pattern mirrors the fixed/aspect trio's grow 0 (IconWdgt /
  # SpreadsheetWdgt / AnalogClockWdgt). A FIT_TEXT_TO_BOX text keeps its box (see the
  # measure above), so it keeps the base derivation; so does a spec that already carries a
  # decided grow (a prior placement's derivation or a user's elasticity edit) -- the ?= only
  # fills UNDECIDED. (U1 -- sizing-model unification §9.5.)
  initialiseDefaultVerticalStackLayoutSpec: ->
    super
    if @fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
      @layoutSpecDetails.grow ?= 1

  # adjust the data models behind the text. E.g.
  # is it going to be shown as cropped? What size
  # is it going to be? How is the text broken down
  # into rows?
  # this method doesn't draw anything.
  reflowText: ->
    super
    [@wrappedLines,@wrappedLineSlots,@widthOfPossiblyCroppedText,@heightOfPossiblyCroppedText] =
      @breakTextIntoLines @textPossiblyCroppedToFit, @fittingFontSize


    return @heightOfPossiblyCroppedText

  # multi-line variant of the StringWdgt helper: size the box to the NATURAL,
  # un-soft-wrapped text — the widest hard-newline-separated line × the line
  # count (width = maxLineWidth, height = lines × fontHeight). softWrap is turned
  # OFF so the text never re-wraps to the container; the box just hugs the text.
  # See StringWdgt::sizeToTextAndDisableFitting for the full rationale — only the CORE is overridden
  # here; StringWdgt's public sizeToTextAndDisableFitting is the canonical settle-wrap and dispatches
  # straight to it.
  #
  # The multi-line box-hug, minus the settle. A chrome label (menu item / button caption -- a freefloating
  # TextWdgt at .label) is laid out by its container, which centres it in _reLayoutSelf (LabelButton /
  # MenuItem). On re-hug the container must re-layout, but it is NOT a scroll-panel/stack so the generic
  # _reFitContainer seam (gated on _reLayoutChildren) doesn't reach it and a freefloating child doesn't
  # climb. So invalidate the managing parent explicitly (gated out-of-pass -- inside a pass the container is
  # already re-laying out and _invalidateLayout would throw) and let the enclosing settle flush it.
  _sizeToTextAndDisableFittingNoSettle: ->
    @softWrap = false
    @fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.FLOAT
    @fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    # softWrap == false → breakTextIntoLines uses an unbounded width, so lines
    # split only on hard "\n" and maxLineWidth is the natural text width.
    [lines, lineSlots, naturalWidth, naturalHeight] =
      @breakTextIntoLines (@transformTextOneToOne @text), @originallySetFontSize
    widthOfText = Math.max naturalWidth, 1
    heightOfText = Math.max naturalHeight, (@fontHeight @originallySetFontSize)
    @__commitExtent new Point widthOfText, heightOfText
    @reflowText()
    @parent?._invalidateLayout() unless world?._recalculatingLayouts
    @  # return self so the public wrapper is chainable (macros do `(new TextWdgt …).sizeToTextAndDisableFitting()`)

  # FIT_BOX_TO_TEXT layout pass: resize our OWN extent to hug the text. This is
  # the contained-text engine — gated by the mode, so ANY TextWdgt used as window
  # / panel / scroll content (not just a SimpleTextWdgt) re-wraps +
  # auto-heights. It belongs in this LAYOUT pass, NOT in reflowText / the paint
  # path (_createRefreshOrGetBackBuffer must not change the extent — it only
  # recomputes the paint height).
  #   - softWrap ON  → HEIGHT_ADJUSTS_TO_WIDTH: keep the width (the container
  #     feeds it), wrap the text to it, the height follows the line count.
  #   - softWrap OFF → the box hugs the NATURAL (un-wrapped) text width — the
  #     "code view" / horizontal-scroll case (old maxTextWidth == 0).
  # The text is always broken at @originallySetFontSize (the box grows; the font
  # is never scaled — see the render-path FIT_BOX_TO_TEXT branches above).
  # FIT_TEXT_TO_BOX (the default) keeps its given box → this is a no-op for it.
  _reLayoutSelf: ->
    super()

    if @fittingSpec != FittingSpecText.FIT_BOX_TO_TEXT then return

    if @softWrap
      [@wrappedLines,@wrappedLineSlots,@widthOfPossiblyCroppedText,@heightOfPossiblyCroppedText] =
        @breakTextIntoLines @text, @originallySetFontSize, @extent()
      width = @width()
    else
      veryWideExtent = new Point 10000000, 10000000
      [@wrappedLines,@wrappedLineSlots,@widthOfPossiblyCroppedText,@heightOfPossiblyCroppedText] =
        @breakTextIntoLines @text, @originallySetFontSize, veryWideExtent
      width = @widthOfPossiblyCroppedText

    height = @wrappedLines.length *  Math.ceil @fontHeight @originallySetFontSize

    # fittingSpecBoxTightOrLoose is TIGHT here (no padding) and
    # fittingSpecBoxWhichDimensionAdjusts is HEIGHT_ADJUSTS_TO_WIDTH — the only
    # configuration any current caller uses (and what the defaults encode). A
    # LOOSE padding margin and the WIDTH_ADJUSTS_TO_HEIGHT variant are reserved:
    # they are stored + part of createBufferCacheKey so a future opt-in
    # re-renders, but their sizing is left for the first caller that needs them
    # (the padding amount is a look-and-decide per the FITTING MODEL design).
    @__commitExtent new Point width, height

    @changed()

  # a FIT_BOX_TO_TEXT widget re-wraps + re-heights to the new measure whenever its
  # extent is set by the layout (a container resize feeds it the width). Gated by
  # the mode, so it is a no-op for a normal free-floating (FIT_TEXT_TO_BOX)
  # TextWdgt.
  _applyExtent: (aPoint) ->
    super
    if @fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT then @_reLayoutSelf()

  createBufferCacheKey: ->
    return super() +  "-" + @softWrap

  # no changes of position or extent should be
  # performed in here
  _createRefreshOrGetBackBuffer: ->
    
    cacheKey = @createBufferCacheKey()

    cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
    if cacheHit?
      # we might have hit a previously cached
      # backBuffer but here we are interested in
      # knowing whether the buffer we are gonna paint
      # is the same as the one being shown now. If
      # not, then we mark the caret as broken.
      if @backBuffer != cacheHit[0]
        if world.caret?
          world.caret.changed()
      return cacheHit

    contentHeight = @reflowText()

    # FIT_BOX_TO_TEXT paints exactly lineCount × fontHeight tall at the SET font
    # size (the box was already grown to this by _reLayoutSelf; here we only recompute
    # the paint height, we do NOT resize — see the "no extent changes" note above).
    if @fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
      contentHeight = @wrappedLines.length *  Math.ceil @fontHeight @originallySetFontSize

    # if we are calculating a new buffer then
    # for sure we have to mark the caret as broken
    if world.caret?
      world.caret.changed()

    backBuffer = HTMLCanvasElement.createOfPhysicalDimensions()
    backBufferContext = backBuffer.getContext "2d"

    backBuffer.width = @width() * ceilPixelRatio
    backBuffer.height = @height() * ceilPixelRatio

    @_prepareTextBufferContext backBufferContext

    textVerticalPosition = @textVerticalPosition contentHeight

    # now draw the actual text
    backBufferContext.fillStyle = @color.toString()
    i = 0
    for line in @wrappedLines
      width = Math.ceil(@measureText nil, line)
      x = switch @horizontalAlignment
        when AlignmentSpecHorizontal.RIGHT
          @width() - width
        when AlignmentSpecHorizontal.CENTER
          (@width() - width) / 2
        else # 'left'
          0
      y = (i + 1) * Math.ceil @fontHeight @fittingFontSize
      i++

      # you'd think that we don't need to eliminate the invisible character
      # to draw the text, as it's supposed to be, well, invisible.
      # Unfortunately some fonts do draw it, so we indeed have to eliminate
      # it.
      backBufferContext.fillText (@eliminateInvisibleCharacter line), x, y + textVerticalPosition

      # header line
      # NB the same-named locals mean slightly different things here than in the
      # StringWdgt call site (one wrapped line vs the whole fitting line), so only
      # the drawing is shared — the geometry is computed here and passed in.
      if @isHeaderLine and @wrappedLines.length <= 1
        @_drawHeaderUnderline backBufferContext, (y + textVerticalPosition), (@fontHeight @fittingFontSize), x, width

    @drawSelection backBufferContext

    cacheEntry = [backBuffer, backBufferContext]
    world.cacheForImmutableBackBuffers.set cacheKey, cacheEntry
    return cacheEntry


  # text widget measuring ////

  # answer the logical position point of the given index ("slot")
  # i.e. the row and the column where a particular character is.
  slotRowAndColumn: (slot) ->


    @reflowText()
    idx = 0
    # Note that this solution scans all the characters
    # in all the rows up to the slot. This could be
    # done a lot quicker by stopping at the first row
    # such that @wrappedLineSlots[theRow] <= slot
    # You could even do a binary search if one really
    # wanted to, because the contents of @wrappedLineSlots are
    # in order, as they contain a cumulative count...
    for row in [0...@wrappedLines.length]
      idx = @wrappedLineSlots[row]
      for col in [0...@wrappedLines[row].length]
        return [row, col]  if idx is slot
        idx += 1
    [@wrappedLines.length - 1, @wrappedLines[@wrappedLines.length - 1].length - 1]
  
  # Answer the position (in pixels) of the given index ("slot")
  # where the caret should be placed.
  # This is in absolute world coordinates.
  # Accounts for horizontal alignment via textHorizontalPosition (unlike
  # StringWdgt.slotCoordinates, which is left-justified only).
  slotCoordinates: (slot) ->
    # PURE geometry (see StringWdgt.slotCoordinates): the overflow hand-off to the pop-out editor that used to
    # be a side effect here moved to an explicit event-time step (handOffToPopoutEditorIfOverflowing, from
    # CaretWdgt.insert), so this read has no side effect and is safe inside the flush / at paint.
    @reflowText()
    [slotRow, slotColumn] = @slotRowAndColumn slot

    lineWidth = @measureText nil, @wrappedLines[slotRow]
    xOffset = Math.ceil @measureText nil, (@wrappedLines[slotRow]).substring(0,slotColumn)
    yOffset = slotRow * Math.ceil @fontHeight @fittingFontSize

    textVerticalPosition = @textVerticalPosition @heightOfPossiblyCroppedText
    textHorizontalPosition = @textHorizontalPosition lineWidth

    x = @left() + xOffset + textHorizontalPosition
    y = @top() + yOffset + textVerticalPosition
    new Point x, y


  slotAtRow: (row, xPosition) ->

    if row > @wrappedLines.length
      return @textPossiblyCroppedToFit.length
    
    return @wrappedLineSlots[Math.max(row - 1, 0)] +
      @slotAtSingleLineString xPosition, @wrappedLines[row - 1]


  pointIsAboveFirstLine: (aPoint) ->
    textVerticalPosition = @textVerticalPosition @heightOfPossiblyCroppedText

    if aPoint.y - @top() < textVerticalPosition
      return 0

    return false
  
  # Returns the slot (index) closest to the given point
  # so the caret can be moved accordingly
  # Accounts for horizontal alignment (slotAtRow -> slotAtSingleLineString applies
  # the textHorizontalPosition offset), not left-justified-only.
  slotAt: (aPoint) ->

    if (isPointBeforeFirstLine = @pointIsAboveFirstLine aPoint) != false
      return isPointBeforeFirstLine

    textVerticalPosition = @textVerticalPosition @heightOfPossiblyCroppedText

    row = 0

    while aPoint.y - @top() > textVerticalPosition + row * Math.ceil @fontHeight @fittingFontSize
      row += 1
    row = Math.max row, 1

    return @slotAtRow row, aPoint.x

  
  upFrom: (slot) ->
    # answer the slot above the given one
    [slotRow, slotColumn] = @slotRowAndColumn slot
    if slotRow < 1
      return 0
    return @slotAtRow slotRow, (@slotCoordinates @caretHorizPositionForVertMovement).x
  
  downFrom: (slot) ->
    # answer the slot below the given one
    [slotRow, slotColumn] = @slotRowAndColumn slot
    if slotRow > @wrappedLines.length - 2
      return @textPossiblyCroppedToFit.length
    return @slotAtRow(slotRow+2, (@slotCoordinates @caretHorizPositionForVertMovement).x)
  
  startOfLine: (slot) ->
    # answer the first slot (index) of the line for the given slot
    @wrappedLineSlots[@slotRowAndColumn(slot).y]
  
  endOfLine: (slot) ->
    # answer the slot (index) indicating the EOL for the given slot
    @startOfLine(slot) + @wrappedLines[@slotRowAndColumn(slot).y].length - 1

  toggleSoftWrap: ->
    @softWrap = not @softWrap
    @changed()
    world.stopEditing()

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    if @softWrap
      menu.addMenuItem "soft wrap".tick(), @, "toggleSoftWrap"
    else
      menu.addMenuItem "soft wrap", @, "toggleSoftWrap"
    menu.addLine()

    # a console contributes its own run-menu entries (run selection / run all); a text not in a
    # console runs its own contents. Was a 3-level `instanceof ConsoleWdgt` reach-through.
    # (type-test-elimination campaign)
    console = @parent?.parent?.parent
    if console?.addRunMenuEntriesForText?
      console.addRunMenuEntriesForText menu, @
    else
      menu.addMenuItem "run contents", @, "doContents"
  
  setAlignmentToLeft: ->
    @alignment = "left"
    @changed()
  
  setAlignmentToRight: ->
    @alignment = "right"
    @changed()
  
  setAlignmentToCenter: ->
    @alignment = "center"
    @changed()
  
  # text widget evaluation. This menu is placed as the
  # "overridingContextMenu" in the Inspector panes, where
  # the text contents is executed against the target Widget
  evaluationMenu: ->
    menu = @buildHierarchyMenu()

    if @text.length > 0
      menu.prependLine()
      menu.prependMenuItem "select all", @, "selectAllAndEdit"
      menu.prependMenuItem "do all", @, "doAll"

    # only show the do it / show it / inspect it entries
    # if there is actually something selected.
    if @selection().replace(/^\s\s*/, '').replace(/\s\s*$/, '') != ''
      menu.prependLine()
      menu.prependMenuItem "inspect selection", @, "inspectSelection", toolTip: "evaluate the\nselected expression\nand inspect the result"
      menu.prependMenuItem "show selection", @, "showSelection", toolTip: "evaluate the\nselected expression\nand show the result"
      menu.prependMenuItem "do selection", @, "doSelection", toolTip: "evaluate the\nselected expression"
    menu

  # Multi-line text inserts a newline on Enter rather than accepting -- override of
  # StringWdgt.enterKeyAccepts, inherited by all TextWdgt subclasses. (type-test-elimination campaign)
  enterKeyAccepts: ->
    false

  # StringWdgt editing:
  edit: ->
    # when you edit a text widget, potentially
    # you need to change the alignment of the
    # text, because managing the caret with
    # alignments other than the top-left
    # ones is complex. So during editing
    # we might change the alignment, hence
    # ths method here with @changed()
    @changed()
    return super

  selectAllAndEdit: ->
    @edit()
    @selectAll()

  doAll: ->
    @receiver.evaluateString @text
   
  # this is set by the inspector. It tells the text widget
  # that any following doSelection/showSelection/inspectSelection
  # action needs to be done apropos a particular obj,
  # and also replaces the normal context menu with the evaluation Menu
  # because if you right click in these panes of the Inspector you
  # want to "run" code that has been typed
  setReceiver: (obj) ->
    @receiver = obj
    @overridingContextMenu = @evaluationMenu
  
  doSelection: ->
    @receiver.evaluateString @selection()
    @edit()

  doContents: ->
    if @receiver?
      @receiver.evaluateString @text
    else
      @evaluateString @text

  showSelection: ->
    result = @receiver.evaluateString @selection()
    if result? then @inform result
  
  inspectSelection: ->
    # evaluateString is a pimped-up eval in
    # the Widget class.
    result = @receiver.evaluateString @selection()
    if result? then @spawnInspector result

  # selects the whole line (if it's wrapped, just
  # what sits on the very line, not what wraps
  # above or under). Just like normal editors.
  mouseTripleClick: ->
    if @isEditable
      [row, column] = @slotRowAndColumn world.caret?.slot
      slotBeginOfLine = @slotAtRow row + 1, 0
      slotsInRow = @wrappedLineSlots[row + 1]
      @selectBetween slotBeginOfLine, slotsInRow
      world.caret?.gotoSlot slotsInRow




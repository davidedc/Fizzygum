# TextMorph2 ///////////////////////////////////////////////////////////

# these comments below needed to figure out dependencies between classes
# REQUIRES LRUCache

# A multi-line, word-wrapping String

class TextMorph2 extends StringMorph2
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  wrappedLines: []
  wrappedLineSlots: []
  maxWrappedLineWidth: 0
  #emptyCharacter: '^'

  backgroundColor: null

  #additional properties for ad-hoc evaluation:
  receiver: null

  constructor: (
    @text = (if text is "" then text else "TextMorph2"),
    @originallySetFontSize = 12,
    @fontName = @justArialFontStack,
    @isBold = false,
    @isItalic = false,
    #@isNumeric = false,
    @color = (new Color 0, 0, 0),
    @backgroundColor = null,
    @backgroundTransparency = null
    ) ->

      super(
        @text,
        @originallySetFontSize,
        @fontName,
        @isBold,
        @isItalic,
        false, # isNumeric
        @color,
        @backgroundColor,
        @backgroundTransparency
        )
      # override inherited properties:
      @markedTextColor = new Color 255, 255, 255
      @markedBackgoundColor = new Color 60, 60, 120
      @textPossiblyCroppedToFit = @transformTextOneToOne @text
      @noticesTransparentClick = true

      @fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
      @fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.CROP
  

  # notice the thick arrow here!
  # there are many factors beyond the font size that affect
  # the measuring, such as font style, but we only pass
  # the font size here because is the one we are going to
  # change when we do the binary search for trying to
  # see the largest fitting size.
  doesTextFitInExtent: (text = (@transformTextOneToOne @text), overrideFontSize) =>
    doesItFit = @breakTextIntoLines text, overrideFontSize, @extent()
    return doesItFit

  getParagraphs: (text) ->
    cacheKey = hashCode text
    paragraphs = world.cacheForTextParagraphSplits.get cacheKey
    if paragraphs? then return paragraphs
    paragraphs = text.split "\n"
    world.cacheForTextParagraphSplits.set cacheKey, paragraphs
    paragraphs

  getWordsOfParapraph: (eachParagraph) ->
    cacheKey = hashCode eachParagraph
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
    cacheKey = @buildCanvasFontProperty(overrideFontSize) + "-" + maxTextWidth + "-" + hashCode eachParagraph
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

      # TOKEN-LEVEL WRAPPING i.e.
      # handling a single token that is too long.
      # This works with the manual tests I've done so far
      # BUT it brought up a logical error, because the
      # following can happen: when the line waps,
      # it pushes down the lines. In doing so, the text
      # might resize. In doing so, the line doesn't need
      # to wrap anymore, and hence the text can embiggen,
      # and hence the line wraps...
      # In other words there is no fixed point in the font
      # size...
      # So this can be done only if the textbox is
      # constrained horizontally but not vertically...

      ###
      if !word.substr(0, word.length-1).contains(" ")
        console.log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        console.log "> no space word: " + word
        checkingLongerSingleWorld = Math.ceil @measureText overrideFontSize, word
        console.log "> length of: " + word + " : " + checkingLongerSingleWorld
        console.log "> maxTextWidth: " + maxTextWidth

        while checkingLongerSingleWorld > maxTextWidth
          console.log "> " + word + " is too long at overrideFontSize: " + overrideFontSize
          maxLengthNotOverflowing = 0
          for scanning in [0..word.length]
            subword = word.substring 0, scanning
            checkingLongerSingleWorld2 = Math.ceil @measureText overrideFontSize, subword
            console.log "> length at size " + overrideFontSize + " of subword: " + subword + " : " + checkingLongerSingleWorld2
            if checkingLongerSingleWorld2 > maxTextWidth
              maxLengthNotOverflowing = scanning - 1
              break
          console.log "> maxLengthNotOverflowing: " + maxLengthNotOverflowing
          if maxLengthNotOverflowing == 0
            word = word.substring 1, word.length
          else
            currentLineCanStayInLine = word.substring 0, maxLengthNotOverflowing
            carryoverFromWrappingLine = word.substring maxLengthNotOverflowing, word.length
            console.log "> part that is not overflowing: " + currentLineCanStayInLine
            console.log "> part that is overflowing: " + carryoverFromWrappingLine
            slotsInParagraph += currentLineCanStayInLine.length
            wrappedLinesOfThisParagraph.push currentLineCanStayInLine
            wrappedLineSlotsOfThisParagraph.push slotsInParagraph
            word = carryoverFromWrappingLine
          checkingLongerSingleWorld = Math.ceil @measureText overrideFontSize, word
      ###

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
    cacheKey = @buildCanvasFontProperty(overrideFontSize) + "-" + maxTextWidth + "-" + hashCode(text) + "-" + justCheckIfItFitsInThisExtent
    textWrappingData = world.cacheForTextWrappingData.get cacheKey
    if textWrappingData? then return textWrappingData
    wrappedLinesOfWholeText = []
    wrappedLineSlotsOfWholeText = [0]
    maxWrappedLineWidthOfWholeText = 0
    cumulativeSlotAcrossText = 0
    previousCumulativeSlotAcrossText = 0

    for eachParagraph in paragraphs

      wordsOfThisParagraph = @getWordsOfParapraph eachParagraph

      ## ////////////////////////////////////////////////////////////////

      ## You want this method to be FAST because it would be done
      ## a dozen times for each resize (while the painting is
      ## only done once!)
      ## you can have the words per paragraph, and cache all
      ## operations below by paragraph (and font size and width),
      ## the cache would return
      ## two arrays "linesHit" and "lineslotsHit" AND the
      ## "maxlinewidthHit" which you can
      ## concatenate to the "running" ones
      ## basically a) make two nested forach, outer by paragraph and
      ## inner by words.
      ## Then cache the hell out of each loop.

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
      ## GET THE stringMorph2 to cache the actual bitmap that they
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
      #alert "unadvanced wrappedLineSlotsOfThisParagraph: " + wrappedLineSlotsOfThisParagraph + " advanced: " + advancedWrappedLineSlotsOfThisParagraph
      wrappedLineSlotsOfWholeText = wrappedLineSlotsOfWholeText.concat advancedWrappedLineSlotsOfThisParagraph
      maxWrappedLineWidthOfWholeText = Math.max maxWrappedLineWidthOfWholeText, maxWrappedLineWidthOfThisParagraph

      if justCheckIfItFitsInThisExtent?
        heightOfText = (wrappedLineSlotsOfWholeText.length - 1) * Math.ceil(fontHeight overrideFontSize)
        #console.log "heightOfText: " + heightOfText + " justCheckIfItFitsInThisExtent: " + justCheckIfItFitsInThisExtent
        if heightOfText > justCheckIfItFitsInThisExtent.y or maxWrappedLineWidthOfWholeText > justCheckIfItFitsInThisExtent.x
          world.cacheForTextWrappingData.set cacheKey, false
          return false


    # here all paragraphs have been visited
    #alert "wrappedLineSlotsOfWholeText: " + wrappedLineSlotsOfWholeText

    if justCheckIfItFitsInThisExtent?
      world.cacheForTextWrappingData.set cacheKey, true
      return true
    textWrappingDataCacheEntry = [wrappedLinesOfWholeText, wrappedLineSlotsOfWholeText, maxWrappedLineWidthOfWholeText]
    world.cacheForTextWrappingData.set cacheKey, textWrappingDataCacheEntry
    textWrappingData = textWrappingDataCacheEntry

  # there are many factors beyond the font size that affect
  # how the text is broken, such as font style, but we only pass
  # the font size here because is the one we are going to
  # change when we do the binary search for trying to
  # see the largest fitting size.
  breakTextIntoLines: (text = (@transformTextOneToOne @text), overrideFontSize, justCheckIfItFitsInThisExtent) ->
    morphWidth = @width()

    cacheKey = hashCode(text) + "-" + @buildCanvasFontProperty(overrideFontSize) + "-" + morphWidth + "-" + justCheckIfItFitsInThisExtent
    textBreak = world.cacheForTextBreakingIntoLinesTopLevel.get cacheKey
    if textBreak? then return textBreak

    #console.log "breakTextIntoLines // " + " morphWidth: " + morphWidth + " overrideFontSize: " + overrideFontSize

    
    ## // this section only needs to be re-done when @text changes ////
    # put all the text in an array, word by word
    # >>> avoid to do this double-split, jus split by spacing and then
    # you'll find and remove the newline in the running code
    # below.
    # put all the text in an array, word by word

    paragraphs = @getParagraphs text

    textWrappingData = @getTextWrappingData overrideFontSize, morphWidth, text, paragraphs, justCheckIfItFitsInThisExtent


    if justCheckIfItFitsInThisExtent?
      textBreak = textWrappingData
    else
      [wrappedLines,wrappedLineSlots,maxWrappedLineWidth] = textWrappingData
      height = wrappedLines.length * Math.ceil(fontHeight overrideFontSize)
      textBreak = [textWrappingData, height, maxWrappedLineWidth]

    world.cacheForTextBreakingIntoLinesTopLevel.set cacheKey, textBreak
    return textBreak

  reflowText: ->
    tmp = @breakTextIntoLines @textPossiblyCroppedToFit, @fittingFontSize
    [@wrappedLines,@wrappedLineSlots,@maxWrappedLineWidth] = tmp[0]
    return tmp[1]

  # no changes of position or extent should be
  # performed in here
  createRefreshOrGetBackBuffer: ->

    verticalAlignment = @verticalAlignment
    horizontalAlignment = @horizontalAlignment

    # it's easier for the time being to use the
    # top-left alignment when editing the text,
    # so let's force that here.
    if world.caret?.target ?= @
      verticalAlignment = AlignmentSpecVertical.TOP
      horizontalAlignment = AlignmentSpecHorizontal.LEFT

    cacheKey = @createBufferCacheKey horizontalAlignment, verticalAlignment
    cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
    if cacheHit? then return cacheHit

    contentHeight = @reflowText()

    backBuffer = newCanvas()
    backBufferContext = backBuffer.getContext "2d"

    backBuffer.width = @width() * pixelRatio
    backBuffer.height = @height() * pixelRatio

    backBufferContext.scale pixelRatio, pixelRatio
    backBufferContext.font = @buildCanvasFontProperty()
    backBufferContext.textAlign = "left"
    backBufferContext.textBaseline = "bottom"

    # paint the background so we have a better sense of
    # where the text is fitting into.
    @paintRectangle \
      backBufferContext,
      0, 0, @width(), @height(),
      @backgroundColor,
      @backgroundTransparency,
      true # push and pop the context

    textVerticalPosition = switch verticalAlignment
      when AlignmentSpecVertical.TOP
        0
      when AlignmentSpecVertical.MIDDLE
        @height()/2 - contentHeight/2
      when AlignmentSpecVertical.BOTTOM
        @height() - contentHeight

    ###
    textHorizontalPosition = switch horizontalAlignment
      when AlignmentSpecHorizontal.LEFT
        0
      when AlignmentSpecHorizontal.CENTER
        @width()/2 - widthOfText/2
      when AlignmentSpecHorizontal.RIGHT
        @width() - widthOfText
    ###

    # now draw the actual text
    backBufferContext.fillStyle = @color.toString()
    i = 0
    for line in @wrappedLines
      width = Math.ceil(@measureText null, line)
      x = switch horizontalAlignment
        when AlignmentSpecHorizontal.RIGHT
          @width() - width
        when AlignmentSpecHorizontal.CENTER
          (@width() - width) / 2
        else # 'left'
          0
      y = (i + 1) * Math.ceil fontHeight @fittingFontSize
      i++

      # you'd think that we don't need to eliminate the invisible character
      # to draw the text, as it's supposed to be, well, invisible.
      # Unfortunately some fonts do draw it, so we indeed have to eliminate
      # it.
      backBufferContext.fillText (@eliminateInvisibleCharacter line), x, y + textVerticalPosition

    @drawSelection backBufferContext

    cacheEntry = [backBuffer, backBufferContext]
    world.cacheForImmutableBackBuffers.set cacheKey, cacheEntry
    return cacheEntry


  # TextMorph measuring ////

  # answer the logical position point of the given index ("slot")
  # i.e. the row and the column where a particular character is.
  slotRowAndColumn: (slot) ->
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
  # This function assumes that the text is left-justified.
  slotCoordinates: (slot) ->

    # this makes it so when you type and the string becomes too big
    # then the edit stops to be directly in the screen and the
    # popout for editing takes over.
    if (@transformTextOneToOne @text) != @textPossiblyCroppedToFit and @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.CROP
      world.stopEditing()
      @edit()
      return null

    [slotRow, slotColumn] = @slotRowAndColumn slot
    yOffset = slotRow * Math.ceil fontHeight @fittingFontSize
    xOffset = Math.ceil @measureText null, (@wrappedLines[slotRow]).substring(0,slotColumn)
    x = @left() + xOffset
    y = @top() + yOffset
    #alert "slotCoordinates slot:" + slot + " x,y: " + x + ", " + y
    new Point x, y


  slotAtRow: (row, xPosition) ->

    if row > @wrappedLines.length
      return @textPossiblyCroppedToFit.length

    
    return @wrappedLineSlots[Math.max(row - 1, 0)] +
      @slotAtSingleLineString xPosition, @wrappedLines[row - 1]

  
  # Returns the slot (index) closest to the given point
  # so the caret can be moved accordingly
  # This function assumes that the text is left-justified.
  slotAt: (aPoint) ->
    row = 0
    while aPoint.y - @top() > row * Math.ceil fontHeight @fittingFontSize
      row += 1
    row = Math.max row, 1

    return @slotAtRow row, aPoint.x

  
  upFrom: (slot) ->
    # answer the slot above the given one
    [slotRow, slotColumn] = @slotRowAndColumn slot
    if slotRow < 1
      return 0
    return @slotAtRow slotRow, @caretHorizPositionForVertMovement
    above = @wrappedLines[slotRow - 1]
    if above.length < slotColumn - 1
      return @wrappedLineSlots[slotRow - 1] + above.length
    @wrappedLineSlots[slotRow - 1] + slotColumn
  
  downFrom: (slot) ->
    # answer the slot below the given one
    [slotRow, slotColumn] = @slotRowAndColumn slot
    if slotRow > @wrappedLines.length - 2
      return @textPossiblyCroppedToFit.length
    return @slotAtRow(slotRow+2, @caretHorizPositionForVertMovement)
    below = @wrappedLines[slotRow + 1]
    if below.length < slotColumn - 1
      return @wrappedLineSlots[slotRow + 1] + below.length
    @wrappedLineSlots[slotRow + 1] + slotColumn
  
  startOfLine: (slot) ->
    # answer the first slot (index) of the line for the given slot
    @wrappedLineSlots[@slotRowAndColumn(slot).y]
  
  endOfLine: (slot) ->
    # answer the slot (index) indicating the EOL for the given slot
    @startOfLine(slot) + @wrappedLines[@slotRowAndColumn(slot).y].length - 1
  
  # TextMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "run contents", true, @, "doContents"
    menu
  
  setAlignmentToLeft: ->
    @alignment = "left"
    @reLayout()
    @changed()
  
  setAlignmentToRight: ->
    @alignment = "right"
    @reLayout()
    @changed()
  
  setAlignmentToCenter: ->
    @alignment = "center"
    @reLayout()
    @changed()  
  
  # TextMorph evaluation:
  evaluationMenu: ->
    menu = @hierarchyMenu()

    if @text.length > 0
      menu.prependLine()
      menu.prependItem "select all", true, @, "selectAllAndEdit"
      menu.prependItem "do all", true, @, "selectAllAndDoit"

    # only show the do it / show it / inspect it entries
    # if there is actually something selected.
    if @selection().replace(/^\s\s*/, '').replace(/\s\s*$/, '') != ''
      menu.prependLine()
      menu.prependItem "inspect selection", true, @, "inspectSelection", "evaluate the\nselected expression\nand inspect the result"
      menu.prependItem "show selection", true, @, "showSelection", "evaluate the\nselected expression\nand show the result"
      menu.prependItem "do selection", true, @, "doSelection", "evaluate the\nselected expression"
    menu

  # StringMorph2 editing:
  edit: ->
    # when you edit a TextMorph, potentially
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

  # TODO this can be done more
  # abstractly, bypassing the
  # actual selection and doSelection...
  selectAllAndDoit: ->
    @edit()
    @selectAll()
    @doSelection()
    @clearSelection()
   
  # this is set by the inspector. It tells the TextMorph
  # that any following doSelection/showSelection/inspectSelection action needs to be
  # done apropos a particular obj
  setReceiver: (obj) ->
    @receiver = obj
    @customContextMenu = @evaluationMenu
  
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
    # the Morph class.
    result = @receiver.evaluateString @selection()
    if result? then @spawnInspector result

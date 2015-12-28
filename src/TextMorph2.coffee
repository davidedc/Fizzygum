# TextMorph2 ///////////////////////////////////////////////////////////

# these comments below needed to figure out dependencies between classes
# REQUIRES BackBufferValidityChecker
# REQUIRES LRUCache

# A multi-line, word-wrapping String

class TextMorph2 extends StringMorph2
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  wrappedLines: []
  wrappedLineSlots: []
  maxWrappedLineWidth: 0

  backgroundColor: null

  #additional properties for ad-hoc evaluation:
  receiver: null

  constructor: (
    text = "",
    @originallySetFontSize = 12,
    @fontStyle = "sans-serif",
    @isBold = false,
    @isItalic = false,
    #@isNumeric = false,
    color,
    fontName,
    @backgroundColor = null,
    @backgroundTransparency = null
    ) ->

      super(
        text,
        @originallySetFontSize,
        @fontStyle,
        @isBold,
        @isItalic,
        false, # isNumeric
        color,
        fontName
        @backgroundColor,
        @backgroundTransparency
        )
      # override inherited properties:
      @markedTextColor = new Color(255, 255, 255)
      @markedBackgoundColor = new Color(60, 60, 120)
      @text = text or ((if text is "" then text else "TextMorph"))
      @textActuallyShown = @text
      @fontName = fontName or WorldMorph.preferencesAndSettings.globalFontFamily
      @color = new Color(0, 0, 0)
      @noticesTransparentClick = true

      @scaleAboveOriginallyAssignedFontSize = true
      @cropWritingWhenTooBig = true
  

  # notice the thick arrow here!
  doesTextFitInExtent: (text = @text, overrideFontSize) =>
    textSize = @breakTextIntoLines text, overrideFontSize
    thisFitsInto = new Point @width(), textSize[1]

    if thisFitsInto.le @extent()
      return true
    else
      return false

  breakTextIntoLines: (text = @text, overrideFontSize) ->
    ## remember to cache also here at the top level
    ## based on text, fontsize and width.

    maxTextWidth = @width()

    console.log "breakTextIntoLines // " + " maxTextWidth: " + maxTextWidth + " overrideFontSize: " + overrideFontSize

    
    ## // this section only needs to be re-done when @text changes ////
    # put all the text in an array, word by word
    # >>> avoid to do this double-split, jus split by spacing and then
    # you'll find and remove the newline in the running code
    # below.
    # put all the text in an array, word by word

    paragraphs = world.cacheForTextParagraphSplits.get hashCode(text)
    if !paragraphs?
      paragraphsCacheEntry = text.split("\n")
      world.cacheForTextParagraphSplits.set hashCode(text), paragraphsCacheEntry
      paragraphs = paragraphsCacheEntry

    cumulativeSlotAcrossText = 0
    previousCumulativeSlotAcrossText = 0

    textWrappingData = world.cacheForTextWrappingData.get hashCode(overrideFontSize + "-" + maxTextWidth + "-" + eachParagraph)
    if !textWrappingData?
      wrappedLinesOfWholeText = []
      wrappedLineSlotsOfWholeText = [0]
      maxWrappedLineWidthOfWholeText = 0

      for eachParagraph in paragraphs

        wordsOfThisParagraph = world.cacheForParagraphsWordsSplits.get hashCode eachParagraph
        if !wordsOfThisParagraph?
          wordsOfThisParagraphCacheEntry = eachParagraph.split(" ")
          wordsOfThisParagraphCacheEntry.push "\n"
          world.cacheForParagraphsWordsSplits.set hashCode(eachParagraph), wordsOfThisParagraphCacheEntry
          wordsOfThisParagraph = wordsOfThisParagraphCacheEntry


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
        
        wrappingData = world.cacheForParagraphsWrappingData.get hashCode(overrideFontSize + "-" + maxTextWidth + "-" + eachParagraph)

        if !wrappingData?
          wrappedLinesOfThisParagraph = []
          wrappedLineSlotsOfThisParagraph = []
          maxWrappedLineWidthOfThisParagraph = 0

          currentLine = ""
          slotsInParagraph = 0

          for word in wordsOfThisParagraph
            if word is "\n"
              # we reached the end of the line in the
              # original text, so push the line and the
              # slotsInParagraph count in the arrays
              wrappedLinesOfThisParagraph.push currentLine
              wrappedLineSlotsOfThisParagraph.push slotsInParagraph
              maxWrappedLineWidthOfThisParagraph = Math.max(maxWrappedLineWidthOfThisParagraph, Math.ceil(@measureText overrideFontSize, currentLine))
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
                  # so we need to push the old line and its
                  # "slotsInParagraph" number to the respective arrays.
                  # the new line is going to only contain the
                  # word that has caused the overflow.
                  wrappedLinesOfThisParagraph.push currentLine
                  wrappedLineSlotsOfThisParagraph.push slotsInParagraph
                  maxWrappedLineWidthOfThisParagraph = Math.max(maxWrappedLineWidthOfThisParagraph, Math.ceil(@measureText overrideFontSize, currentLine))
                  currentLine = word + " "
                else
                  # no overflow happened, so just proceed as normal
                  currentLine = lineForOverflowTest
              else # there is no width limit, we never have to wrap
                currentLine = currentLine + word + " "
              slotsInParagraph += word.length + 1

          # words of this paragraph have been scanned
          wrappingDataCacheEntry = [wrappedLinesOfThisParagraph,wrappedLineSlotsOfThisParagraph,maxWrappedLineWidthOfThisParagraph, slotsInParagraph]
          world.cacheForParagraphsWrappingData.set hashCode(overrideFontSize + "-" + maxTextWidth + "-" + eachParagraph), wrappingDataCacheEntry
          wrappingData = wrappingDataCacheEntry

        # we either cache-hit wrappingData or we re-built it
        [wrappedLinesOfThisParagraph, wrappedLineSlotsOfThisParagraph, maxWrappedLineWidthOfThisParagraph, slotsInParagraph] = wrappingData

        previousCumulativeSlotAcrossText = cumulativeSlotAcrossText
        cumulativeSlotAcrossText += slotsInParagraph
        wrappedLinesOfWholeText = wrappedLinesOfWholeText.concat wrappedLinesOfThisParagraph
        advancedWrappedLineSlotsOfThisParagraph =  wrappedLineSlotsOfThisParagraph.map (i) -> i + previousCumulativeSlotAcrossText
        #alert "unadvanced wrappedLineSlotsOfThisParagraph: " + wrappedLineSlotsOfThisParagraph + " advanced: " + advancedWrappedLineSlotsOfThisParagraph
        wrappedLineSlotsOfWholeText = wrappedLineSlotsOfWholeText.concat advancedWrappedLineSlotsOfThisParagraph
        maxWrappedLineWidthOfWholeText = Math.max maxWrappedLineWidthOfWholeText, maxWrappedLineWidthOfThisParagraph

        #cumulativeSlotAcrossText += wrappedLineSlotsOfThisParagraph.reduce (t, s) -> t + s

      # here all paragraphs have been visited
      #alert "wrappedLineSlotsOfWholeText: " + wrappedLineSlotsOfWholeText
      textWrappingDataCacheEntry = [wrappedLinesOfWholeText, wrappedLineSlotsOfWholeText, maxWrappedLineWidthOfWholeText]
      world.cacheForTextWrappingData.set hashCode(overrideFontSize + "-" + maxTextWidth + "-" + eachParagraph), textWrappingDataCacheEntry
      textWrappingData = textWrappingDataCacheEntry

    [wrappedLines,wrappedLineSlots,maxWrappedLineWidth] = textWrappingData
    height = wrappedLines.length * (Math.ceil(fontHeight(overrideFontSize)))
    return [textWrappingData, height]

  edit: ->
    world.edit @
    return true

  ###
  reLayout: ->
    super()
    @fittingFontSize = @fitToExtent()
    @fontsize = @fittingFontSize
    console.log "reLayout // fontSize: " + @fontSize + " fittingFontSize: " + @fittingFontSize

    #super()
    #@maxTextWidth = @width()
    #@breakTextIntoLines()

    @notifyChildrenThatParentHasReLayouted()
  ###

  reflowText: ->
    tmp = (@breakTextIntoLines @textActuallyShown, @fittingFontSize)
    [@wrappedLines,@wrappedLineSlots,@maxWrappedLineWidth] = tmp[0]
    return tmp[1]

  # no changes of position or extent
  repaintBackBufferIfNeeded: ->
    console.log "repaintBackBufferIfNeeded // fontSize: " + @originallySetFontSize + " fittingFontSize: " + @fittingFontSize
    if !@backBufferIsPotentiallyDirty then return
    @backBufferIsPotentiallyDirty = false

    if @backBufferValidityChecker?
      if @backBufferValidityChecker.extent == @extent().toString() and
      @backBufferValidityChecker.font == @font() and
      @backBufferValidityChecker.textActuallyShownHash == hashCode(@textActuallyShown) and
      @backBufferValidityChecker.backgroundColor == @backgroundColor?.toString() and
      @backBufferValidityChecker.color == @color.toString() and
      @backBufferValidityChecker.textHash == hashCode(@text) and
      @backBufferValidityChecker.startMark == @startMark and
      @backBufferValidityChecker.endMark == @endMark and
      @backBufferValidityChecker.markedBackgoundColor == @markedBackgoundColor.toString() and
      @backBufferValidityChecker.horizontalAlignment == @horizontalAlignment and
      @backBufferValidityChecker.verticalAlignment == @verticalAlignment and
      @backBufferValidityChecker.scaleAboveOriginallyAssignedFontSize == @scaleAboveOriginallyAssignedFontSize and
      @backBufferValidityChecker.cropWritingWhenTooBig == @cropWritingWhenTooBig
        return

    contentHeight = @reflowText()

    @backBuffer = newCanvas()
    @backBufferContext = @backBuffer.getContext("2d")
    @backBufferContext.font = @font()

    @backBuffer.width = @width() * pixelRatio
    @backBuffer.height = @height() * pixelRatio

    # changing the canvas size resets many of
    # the properties of the canvas, so we need to
    # re-initialise the font and alignments here
    @backBufferContext.scale pixelRatio, pixelRatio
    @backBufferContext.font = @font()
    @backBufferContext.textAlign = "left"
    @backBufferContext.textBaseline = "bottom"

    # paint the background so we have a better sense of
    # where the text is fitting into.
    if @backgroundColor?
      @backBufferContext.save()
      @backBufferContext.fillStyle = @backgroundColor.toString()
      if @backgroundTransparency?
        @backBufferContext.globalAlpha = @backgroundTransparency
      @backBufferContext.fillRect  0,0, @width() * pixelRatio, @height() * pixelRatio
      @backBufferContext.restore()


    if @verticalAlignment == AlignmentSpec.TOP
      textVerticalPosition = 0
    else if @verticalAlignment == AlignmentSpec.MIDDLE
      textVerticalPosition = @height()/2 - contentHeight/2
    else if @verticalAlignment == AlignmentSpec.BOTTOM
      textVerticalPosition = @height() - contentHeight

    ###
    if @horizontalAlignment == AlignmentSpec.LEFT
      textHorizontalPosition = 0
    else if @horizontalAlignment == AlignmentSpec.CENTER
      textHorizontalPosition = @width()/2 - widthOfText/2
    else if @horizontalAlignment == AlignmentSpec.RIGHT
      textHorizontalPosition = @width() - widthOfText
    ###

    # now draw the actual text
    @backBufferContext.fillStyle = @color.toString()
    i = 0
    for line in @wrappedLines
      width = Math.ceil(@measureText null, line)
      if @horizontalAlignment == AlignmentSpec.RIGHT
        x = @width() - width
      else if @horizontalAlignment == AlignmentSpec.CENTER
        x = (@width() - width) / 2
      else # 'left'
        x = 0
      y = (i + 1) * (Math.ceil(fontHeight(@fittingFontSize)))
      i++
      @backBufferContext.fillText line, x, y + textVerticalPosition

    # Draw the selection. This is done by re-drawing the
    # selected text, one character at the time, just with
    # a background rectangle.
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    for i in [start...stop]
      p = @slotCoordinates(i).subtract(@position())
      c = @textActuallyShown.charAt(i)
      @backBufferContext.fillStyle = @markedBackgoundColor.toString()
      @backBufferContext.fillRect p.x, p.y, Math.ceil(@measureText null, c) + 1, Math.ceil(fontHeight(@fittingFontSize))
      @backBufferContext.fillStyle = @markedTextColor.toString()
      @backBufferContext.fillText c, p.x, p.y + Math.ceil(fontHeight(@fittingFontSize))

    @backBufferValidityChecker = new BackBufferValidityChecker()
    @backBufferValidityChecker.extent = @extent().toString()
    @backBufferValidityChecker.font = @font()
    @backBufferValidityChecker.backgroundColor = @backgroundColor?.toString()
    @backBufferValidityChecker.color = @color.toString()
    @backBufferValidityChecker.textHash = hashCode(@text)
    @backBufferValidityChecker.textActuallyShownHash = hashCode(@textActuallyShown) and
    @backBufferValidityChecker.startMark = @startMark
    @backBufferValidityChecker.endMark = @endMark
    @backBufferValidityChecker.markedBackgoundColor = @markedBackgoundColor.toString()
    @backBufferValidityChecker.horizontalAlignment = @horizontalAlignment and
    @backBufferValidityChecker.verticalAlignment = @verticalAlignment and
    @backBufferValidityChecker.scaleAboveOriginallyAssignedFontSize = @scaleAboveOriginallyAssignedFontSize and
    @backBufferValidityChecker.cropWritingWhenTooBig = @cropWritingWhenTooBig


  
  ###
  rawSetExtent: (aPoint) ->
    @breakNumberOfRawMovesAndResizesCaches()
    @maxTextWidth = Math.max(aPoint.x, 0)
    @reLayout()
    @changed()
  ###

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
    [slotRow, slotColumn] = @slotRowAndColumn(slot)
    yOffset = slotRow * (Math.ceil(fontHeight(@fittingFontSize)))
    xOffset = Math.ceil @measureText null, (@wrappedLines[slotRow]).substring(0,slotColumn)
    x = @left() + xOffset
    y = @top() + yOffset
    #alert "slotCoordinates|| slot:" + slot + " x,y: " + x + ", " + y
    new Point(x, y)
  
  # Returns the slot (index) closest to the given point
  # so the caret can be moved accordingly
  # This function assumes that the text is left-justified.
  slotAt: (aPoint) ->
    charX = 0
    row = 0
    col = 0
    while aPoint.y - @top() > ((Math.ceil(fontHeight(@fittingFontSize))) * row)
      row += 1
    row = Math.max(row, 1)
    while aPoint.x - @left() > charX
      if col > @wrappedLines[row - 1].length - 1
        # if pointer is beyond the end of the line, the slot is at
        # the last character of the line.
        break
      charX += @measureText null, @wrappedLines[row - 1][col]
      col += 1
    returnedSlot = @wrappedLineSlots[Math.max(row - 1, 0)] + col - 1

    #[slotRow, slotColumn] = @slotRowAndColumn(returnedSlot)
    #alert "SLOTAT|| returnedSlot: " + returnedSlot + " row and column: " + slotRow + " " + slotColumn + " line start: " + (@wrappedLines[slotRow]).substring(0,slotColumn)

    returnedSlot
  
  upFrom: (slot) ->
    # answer the slot above the given one
    [slotRow, slotColumn] = @slotRowAndColumn(slot)
    return slot  if slotRow < 1
    above = @wrappedLines[slotRow - 1]
    return @wrappedLineSlots[slotRow - 1] + above.length  if above.length < slotColumn - 1
    @wrappedLineSlots[slotRow - 1] + slotColumn
  
  downFrom: (slot) ->
    # answer the slot below the given one
    [slotRow, slotColumn] = @slotRowAndColumn(slot)
    return slot  if slotRow > @wrappedLines.length - 2
    below = @wrappedLines[slotRow + 1]
    return @wrappedLineSlots[slotRow + 1] + below.length  if below.length < slotColumn - 1
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
    result = @receiver.evaluateString(@selection())
    if result? then @inform result
  
  inspectSelection: ->
    # evaluateString is a pimped-up eval in
    # the Morph class.
    result = @receiver.evaluateString(@selection())
    if result? then @spawnInspector result

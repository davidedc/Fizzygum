# TextMorph2 ///////////////////////////////////////////////////////////

# these comments below needed to figure out dependencies between classes
# REQUIRES BackBufferValidityChecker
# REQUIRES LRUCache

# A multi-line, word-wrapping String

class TextMorph2 extends StringMorph2
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  lines: []
  lineSlots: []
  alignment: null
  maxTextWidth: null
  maxLineWidth: 0
  backgroundColor: null

  #additional properties for ad-hoc evaluation:
  receiver: null

  constructor: (
    text, @fontSize = 12, @fontStyle = "sans-serif", @isBold = false,
    @isItalic = false, @alignment = "left", @maxTextWidth = 0, fontName, shadowOffset,
    @shadowColor = null
    ) ->

      super(text, @fontSize, @fontStyle, @isBold, @isItalic, null, shadowOffset, @shadowColor,null,fontName)
      # override inherited properties:
      @markedTextColor = new Color(255, 255, 255)
      @markedBackgoundColor = new Color(60, 60, 120)
      @text = text or ((if text is "" then text else "TextMorph"))
      @fontName = fontName or WorldMorph.preferencesAndSettings.globalFontFamily
      @shadowOffset = shadowOffset or new Point(0, 0)
      @color = new Color(0, 0, 0)
      @noticesTransparentClick = true
  
  breakTextIntoLines: ->
    ## remember to cache also here at the top level
    ## based on text, fontsize and width.

    currentLine = ""
    slot = 0
    
    ## // this section only needs to be re-done when @text changes ////
    # put all the text in an array, word by word
    # >>> avoid to do this double-split, jus split by spacing and then
    # you'll find and remove the newline in the running code
    # below.
    # put all the text in an array, word by word

    paragraphs = world.cacheForTextParagraphSplits.get hashCode(@text)
    if !paragraphs?
      paragraphsCacheEntry = @text.split("\n")
      world.cacheForTextParagraphSplits.set hashCode(@text), paragraphsCacheEntry
      paragraphs = paragraphsCacheEntry


    linesOfWholeText = []
    lineSlotsOfWholeText = [0]
    maxLineWidthOfWholeText = 0

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
      # called @lines, which contains the string for
      # each line (excluding the end of lines).
      # Also another array is created, called
      # @lineSlots, which memorises how many characters
      # of the text have been consumed up to each line
      #  example: original text: "Hello\nWorld"
      # then @lines[0] = "Hello" @lines[1] = "World"
      # and @lineSlots[0] = 6, @lineSlots[1] = 11
      # Note that this algorithm doesn't work in case
      # of single non-spaced words that are longer than
      # the allowed width.
      
      wrappingData = world.cacheForParagraphsWrappingData.get hashCode(@fontSize + "-" + @maxTextWidth + "-" + eachParagraph)

      if wrappingData?
        [linesOfThisParagraph, lineSlotsOfThisParagraph, maxLineWidthOfThisParagraph] = wrappingData
      else
        linesOfThisParagraph = []
        lineSlotsOfThisParagraph = []
        maxLineWidthOfThisParagraph = 0

        for word in wordsOfThisParagraph
          if word is "\n"
            # we reached the end of the line in the
            # original text, so push the line and the
            # slots count in the arrays
            linesOfThisParagraph.push currentLine
            lineSlotsOfThisParagraph.push slot
            maxLineWidthOfThisParagraph = Math.max(maxLineWidthOfThisParagraph, Math.ceil(@measureText null, currentLine))
            currentLine = ""
          else
            if @maxTextWidth > 0 # there is a width limit, we might have to wrap
              # there is a width limit, so we need
              # to check whether we overflowed it. So create
              # a prospective line and then check its width.
              lineForOverflowTest = currentLine + word + " "
              w = Math.ceil @measureText null, lineForOverflowTest
              if w > @maxTextWidth
                # ok we just overflowed the available space,
                # so we need to push the old line and its
                # "slot" number to the respective arrays.
                # the new line is going to only contain the
                # word that has caused the overflow.
                linesOfThisParagraph.push currentLine
                lineSlotsOfThisParagraph.push slot
                maxLineWidthOfThisParagraph = Math.max(maxLineWidthOfThisParagraph, Math.ceil(@measureText null, currentLine))
                currentLine = word + " "
              else
                # no overflow happened, so just proceed as normal
                currentLine = lineForOverflowTest
            else # there is no width limit, we never have to wrap
              currentLine = currentLine + word + " "
            slot += word.length + 1

        wrappingDataCacheEntry = [linesOfThisParagraph,lineSlotsOfThisParagraph,maxLineWidthOfThisParagraph]
        world.cacheForParagraphsWrappingData.set hashCode(@fontSize + "-" + @maxTextWidth + "-" + eachParagraph), wrappingDataCacheEntry
        wrappingData = wrappingDataCacheEntry

      linesOfWholeText = linesOfWholeText.concat linesOfThisParagraph
      lineSlotsOfWholeText = lineSlotsOfWholeText.concat lineSlotsOfThisParagraph
      maxLineWidthOfWholeText = Math.max maxLineWidthOfWholeText, maxLineWidthOfThisParagraph


    [@lines,@lineSlots,@maxLineWidth] = [linesOfWholeText, lineSlotsOfWholeText, maxLineWidthOfWholeText]


  reLayout: ->
    super()
    @breakTextIntoLines()

    shadowWidth = Math.abs(@shadowOffset.x)
    shadowHeight = Math.abs(@shadowOffset.y)
    height = @lines.length * (Math.ceil(fontHeight(@fontSize)) + shadowHeight)
    if @maxTextWidth is 0
      @silentRawSetExtent(new Point(@maxLineWidth + shadowWidth, height))
    else
      @silentRawSetExtent(new Point(@maxTextWidth + shadowWidth, height))
    if @parent?.layoutChanged
      @parent.layoutChanged()
    @notifyChildrenThatParentHasReLayouted()

  # no changes of position or extent
  repaintBackBufferIfNeeded: ->
    if !@backBufferIsPotentiallyDirty then return
    @backBufferIsPotentiallyDirty = false

    if @backBufferValidityChecker?
      if @backBufferValidityChecker.extent == @extent().toString() and
      @backBufferValidityChecker.font == @font() and
      @backBufferValidityChecker.textAlign == @alignment and
      @backBufferValidityChecker.backgroundColor == @backgroundColor?.toString() and
      @backBufferValidityChecker.color == @color.toString() and
      @backBufferValidityChecker.textHash == hashCode(@text) and
      @backBufferValidityChecker.startMark == @startMark and
      @backBufferValidityChecker.endMark == @endMark and
      @backBufferValidityChecker.markedBackgoundColor == @markedBackgoundColor.toString()
        return

    @backBuffer = newCanvas()
    @backBufferContext = @backBuffer.getContext("2d")
    @backBufferContext.font = @font()

    shadowWidth = Math.abs(@shadowOffset.x)
    shadowHeight = Math.abs(@shadowOffset.y)


    @backBuffer.width = @width() * pixelRatio
    @backBuffer.height = @height() * pixelRatio

    # changing the canvas size resets many of
    # the properties of the canvas, so we need to
    # re-initialise the font and alignments here
    @backBufferContext.scale pixelRatio, pixelRatio
    @backBufferContext.font = @font()
    @backBufferContext.textAlign = "left"
    @backBufferContext.textBaseline = "bottom"

    # fill the background, if desired
    if @backgroundColor
      @backBufferContext.fillStyle = @backgroundColor.toString()
      @backBufferContext.fillRect 0, 0, @width(), @height()

    # draw the shadow, if any
    if @shadowColor
      offx = Math.max(@shadowOffset.x, 0)
      offy = Math.max(@shadowOffset.y, 0)
      #console.log 'shadow x: ' + offx + " y: " + offy
      @backBufferContext.fillStyle = @shadowColor.toString()
      i = 0
      for line in @lines
        width = Math.ceil(@measureText null, line) + shadowWidth
        if @alignment is "right"
          x = @width() - width
        else if @alignment is "center"
          x = (@width() - width) / 2
        else # 'left'
          x = 0
        y = (i + 1) * (Math.ceil(fontHeight(@fontSize)) + shadowHeight) - shadowHeight
        i++
        @backBufferContext.fillText line, x + offx, y + offy

    # now draw the actual text
    offx = Math.abs(Math.min(@shadowOffset.x, 0))
    offy = Math.abs(Math.min(@shadowOffset.y, 0))
    #console.log 'maintext x: ' + offx + " y: " + offy
    @backBufferContext.fillStyle = @color.toString()
    i = 0
    for line in @lines
      width = Math.ceil(@measureText null, line) + shadowWidth
      if @alignment is "right"
        x = @width() - width
      else if @alignment is "center"
        x = (@width() - width) / 2
      else # 'left'
        x = 0
      y = (i + 1) * (Math.ceil(fontHeight(@fontSize)) + shadowHeight) - shadowHeight
      i++
      @backBufferContext.fillText line, x + offx, y + offy

    # Draw the selection. This is done by re-drawing the
    # selected text, one character at the time, just with
    # a background rectangle.
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    for i in [start...stop]
      p = @slotCoordinates(i).subtract(@position())
      c = @text.charAt(i)
      @backBufferContext.fillStyle = @markedBackgoundColor.toString()
      @backBufferContext.fillRect p.x, p.y, Math.ceil(@measureText null, c) + 1, Math.ceil(fontHeight(@fontSize))
      @backBufferContext.fillStyle = @markedTextColor.toString()
      @backBufferContext.fillText c, p.x, p.y + Math.ceil(fontHeight(@fontSize))

    @backBufferValidityChecker = new BackBufferValidityChecker()
    @backBufferValidityChecker.extent = @extent().toString()
    @backBufferValidityChecker.font = @font()
    @backBufferValidityChecker.textAlign = @alignment
    @backBufferValidityChecker.backgroundColor = @backgroundColor?.toString()
    @backBufferValidityChecker.color = @color.toString()
    @backBufferValidityChecker.textHash = hashCode(@text)
    @backBufferValidityChecker.startMark = @startMark
    @backBufferValidityChecker.endMark = @endMark
    @backBufferValidityChecker.markedBackgoundColor = @markedBackgoundColor.toString()


  
  rawSetExtent: (aPoint) ->
    @breakNumberOfRawMovesAndResizesCaches()
    @maxTextWidth = Math.max(aPoint.x, 0)
    @reLayout()
    @changed()
  
  # TextMorph measuring ////

  # answer the logical position point of the given index ("slot")
  # i.e. the row and the column where a particular character is.
  slotRowAndColumn: (slot) ->
    idx = 0
    # Note that this solution scans all the characters
    # in all the rows up to the slot. This could be
    # done a lot quicker by stopping at the first row
    # such that @lineSlots[theRow] <= slot
    # You could even do a binary search if one really
    # wanted to, because the contents of @lineSlots are
    # in order, as they contain a cumulative count...
    for row in [0...@lines.length]
      idx = @lineSlots[row]
      for col in [0...@lines[row].length]
        return [row, col]  if idx is slot
        idx += 1
    [@lines.length - 1, @lines[@lines.length - 1].length - 1]
  
  # Answer the position (in pixels) of the given index ("slot")
  # where the caret should be placed.
  # This is in absolute world coordinates.
  # This function assumes that the text is left-justified.
  slotCoordinates: (slot) ->
    [slotRow, slotColumn] = @slotRowAndColumn(slot)
    shadowHeight = Math.abs(@shadowOffset.y)
    yOffset = slotRow * (Math.ceil(fontHeight(@fontSize)) + shadowHeight)
    xOffset = Math.ceil @measureText null, (@lines[slotRow]).substring(0,slotColumn)
    x = @left() + xOffset
    y = @top() + yOffset
    new Point(x, y)
  
  # Returns the slot (index) closest to the given point
  # so the caret can be moved accordingly
  # This function assumes that the text is left-justified.
  slotAt: (aPoint) ->
    charX = 0
    row = 0
    col = 0
    shadowHeight = Math.abs(@shadowOffset.y)
    row += 1  while aPoint.y - @top() > ((Math.ceil(fontHeight(@fontSize)) + shadowHeight) * row)
    row = Math.max(row, 1)
    while aPoint.x - @left() > charX
      charX += Math.ceil @measureText null, @lines[row - 1][col]
      col += 1
    @lineSlots[Math.max(row - 1, 0)] + col - 1
  
  upFrom: (slot) ->
    # answer the slot above the given one
    [slotRow, slotColumn] = @slotRowAndColumn(slot)
    return slot  if slotRow < 1
    above = @lines[slotRow - 1]
    return @lineSlots[slotRow - 1] + above.length  if above.length < slotColumn - 1
    @lineSlots[slotRow - 1] + slotColumn
  
  downFrom: (slot) ->
    # answer the slot below the given one
    [slotRow, slotColumn] = @slotRowAndColumn(slot)
    return slot  if slotRow > @lines.length - 2
    below = @lines[slotRow + 1]
    return @lineSlots[slotRow + 1] + below.length  if below.length < slotColumn - 1
    @lineSlots[slotRow + 1] + slotColumn
  
  startOfLine: (slot) ->
    # answer the first slot (index) of the line for the given slot
    @lineSlots[@slotRowAndColumn(slot).y]
  
  endOfLine: (slot) ->
    # answer the slot (index) indicating the EOL for the given slot
    @startOfLine(slot) + @lines[@slotRowAndColumn(slot).y].length - 1
  
  # TextMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "align left", true, @, "setAlignmentToLeft"  if @alignment isnt "left"
    menu.addItem "align right", true, @, "setAlignmentToRight"  if @alignment isnt "right"
    menu.addItem "align center", true, @, "setAlignmentToCenter"  if @alignment isnt "center"
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

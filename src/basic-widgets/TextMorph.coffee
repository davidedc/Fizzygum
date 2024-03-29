# I am a multi-line, word-wrapping String
#
# TODO Note that this class has problems with text that has multi-code characters, i.e. characters that for a cursor behave like a single character
# (i.e. the cursor moves around them with one single arrow key press) BUT that, unintuitively, have .length property > 1 (e.g. "ä".length is 2)
# this is because the code assumes that the .length property of a string is the number of characters in the string, which, as in the "ä"
# example, is not true.

class TextMorph extends StringMorph

  words: []
  lines: []
  lineSlots: []
  alignment: nil
  maxTextWidth: nil
  maxLineWidth: 0
  backgroundColor: nil

  #additional properties for ad-hoc evaluation:
  receiver: nil

  constructor: (
   @text = "TextMorph",
   @fontSize = 12,
   @fontStyle = "sans-serif",
   @isBold = false,
   @isItalic = false,
   @alignment = "left",
   @maxTextWidth = 0,
   @fontName = "",
   @shadowOffset = (new Point 0, 0),
   @shadowColor = nil
   ) ->

    super \
      @text,
      @fontSize,
      @fontStyle,
      @isBold,
      @isItalic,
      nil,
      @shadowOffset,
      @shadowColor,
      nil,
      @fontName
    # override inherited properties:
    @markedTextColor = Color.WHITE
    @markedBackgroundColor = Color.create 60, 60, 120
    @color = Color.BLACK
    @noticesTransparentClick = true
  
  breakTextIntoLines: ->
    paragraphs = @text.split "\n"
    canvas = HTMLCanvasElement.createOfPhysicalDimensions()
    context = canvas.getContext "2d"
    context.useLogicalPixelsUntilRestore()
    currentLine = ""
    slot = 0
    context.font = @buildCanvasFontProperty()
    @maxLineWidth = 0
    @lines = []
    @lineSlots = [0]
    @words = []
    
    # put all the text in an array, word by word
    paragraphs.forEach (p) =>
      @words = @words.concat p.split " "
      @words.push "\n"

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
    @words.forEach (word) =>
      if word is "\n"
        # we reached the end of the line in the
        # original text, so push the line and the
        # slots count in the arrays
        @lines.push currentLine
        @lineSlots.push slot
        @maxLineWidth = Math.max @maxLineWidth, Math.ceil context.measureText(currentLine).width
        currentLine = ""
      else
        if @maxTextWidth > 0
          # there is a width limit, so we need
          # to check whether we overflowed it. So create
          # a prospective line and then check its width.
          lineForOverflowTest = currentLine + word + " "
          w = Math.ceil(context.measureText(lineForOverflowTest).width)
          if w > @maxTextWidth
            # ok we just overflowed the available space,
            # so we need to push the old line and its
            # "slot" number to the respective arrays.
            # the new line is going to only contain the
            # word that has caused the overflow.
            @lines.push currentLine
            @lineSlots.push slot
            @maxLineWidth = Math.max @maxLineWidth, Math.ceil context.measureText(currentLine).width
            currentLine = word + " "
          else
            # no overflow happened, so just proceed as normal
            currentLine = lineForOverflowTest
        else
          currentLine = currentLine + word + " "
        slot += word.length + 1
  

  reLayout: ->
    super()
    ANimage = HTMLCanvasElement.createOfPhysicalDimensions()
    context = ANimage.getContext "2d"
    context.font = @buildCanvasFontProperty()
    @breakTextIntoLines()

    shadowWidth = Math.abs @shadowOffset.x
    shadowHeight = Math.abs @shadowOffset.y
    height = @lines.length * (Math.ceil(@fontHeight @fontSize) + shadowHeight)
    if @maxTextWidth is 0
      @silentRawSetExtent new Point @maxLineWidth + shadowWidth, height
    else
      @silentRawSetExtent new Point @maxTextWidth + shadowWidth, height

  # no changes of position or extent should be
  # performed in here
  createRefreshOrGetBackBuffer: ->

    cacheKey =
      @extent().toString()  + "-" +
      @buildCanvasFontProperty()  + "-" +
      @alignment  + "-" +
      @backgroundColor?.toString()  + "-" +
      @color.toString()  + "-" +
      @text.hashCode()  + "-" +
      @startMark  + "-" +
      @endMark  + "-" +
      @markedBackgroundColor.toString()

    cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
    if cacheHit? then return cacheHit


    backBuffer = HTMLCanvasElement.createOfPhysicalDimensions()
    backBufferContext = backBuffer.getContext "2d"

    shadowWidth = Math.abs @shadowOffset.x
    shadowHeight = Math.abs @shadowOffset.y


    backBuffer.width = @width() * ceilPixelRatio
    backBuffer.height = @height() * ceilPixelRatio

    # changing the canvas size resets many of
    # the properties of the canvas, so we need to
    # re-initialise the font and alignments here
    backBufferContext.useLogicalPixelsUntilRestore()
    backBufferContext.font = @buildCanvasFontProperty()
    backBufferContext.textAlign = "left"
    backBufferContext.textBaseline = "bottom"

    # fill the background, if desired
    if @backgroundColor
      backBufferContext.fillStyle = @backgroundColor.toString()
      backBufferContext.fillRect 0, 0, @width(), @height()

    # draw the shadow, if any
    if @shadowColor
      offx = Math.max @shadowOffset.x, 0
      offy = Math.max @shadowOffset.y, 0
      #console.log 'shadow x: ' + offx + " y: " + offy
      backBufferContext.fillStyle = @shadowColor.toString()
      i = 0
      for line in @lines
        width = Math.ceil(backBufferContext.measureText(line).width) + shadowWidth
        x = switch @alignment
          when "right"
            @width() - width
          when "center"
            (@width() - width) / 2
          else # 'left'
            0
        y = (i + 1) * (Math.ceil(@fontHeight @fontSize) + shadowHeight) - shadowHeight
        i++
        backBufferContext.fillText line, x + offx, y + offy

    # now draw the actual text
    offx = Math.abs Math.min @shadowOffset.x, 0
    offy = Math.abs Math.min @shadowOffset.y, 0
    #console.log 'maintext x: ' + offx + " y: " + offy
    backBufferContext.fillStyle = @color.toString()
    i = 0
    for line in @lines
      width = Math.ceil(backBufferContext.measureText(line).width) + shadowWidth
      x = switch @alignment
        when "right"
          @width() - width
        when "center"
          (@width() - width) / 2
        else # 'left'
          0
      y = (i + 1) * (Math.ceil(@fontHeight @fontSize) + shadowHeight) - shadowHeight
      i++
      backBufferContext.fillText line, x + offx, y + offy

    # Draw the selection. This is done by re-drawing the
    # selected text, one character at the time, just with
    # a background rectangle.
    start = Math.min @startMark, @endMark
    stop = Math.max @startMark, @endMark
    for i in [start...stop]
      p = @slotCoordinates(i).subtract @position()
      c = @text.charAt i
      backBufferContext.fillStyle = @markedBackgroundColor.toString()
      backBufferContext.fillRect p.x, p.y, Math.ceil(backBufferContext.measureText(c).width) + 1, Math.ceil(@fontHeight @fontSize)
      backBufferContext.fillStyle = @markedTextColor.toString()
      backBufferContext.fillText c, p.x, p.y + Math.ceil @fontHeight @fontSize

    cacheEntry = [backBuffer, backBufferContext]
    world.cacheForImmutableBackBuffers.set cacheKey, cacheEntry
    return cacheEntry
  
  rawSetExtent: (aPoint) ->
    unless aPoint.equals @extent()
      #console.log "move 18"
      @breakNumberOfRawMovesAndResizesCaches()
      @maxTextWidth = Math.max aPoint.x, 0
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
    [slotRow, slotColumn] = @slotRowAndColumn slot
    shadowHeight = Math.abs @shadowOffset.y
    yOffset = slotRow * (Math.ceil(@fontHeight @fontSize) + shadowHeight)
    xOffset = Math.ceil @backBufferContext.measureText((@lines[slotRow]).substring(0,slotColumn)).width
    x = @left() + xOffset
    y = @top() + yOffset
    new Point x, y
  
  # Returns the slot (index) closest to the given point
  # so the caret can be moved accordingly
  # This function assumes that the text is left-justified.
  slotAt: (aPoint) ->
    charX = 0
    row = 0
    col = 0
    shadowHeight = Math.abs @shadowOffset.y
    row += 1  while aPoint.y - @top() > (Math.ceil(@fontHeight @fontSize) + shadowHeight) * row
    row = Math.max row, 1
    while aPoint.x - @left() > charX
      charX += Math.ceil @backBufferContext.measureText(@lines[row - 1][col]).width
      col += 1
    @lineSlots[Math.max(row - 1, 0)] + col - 1
  
  upFrom: (slot) ->
    # answer the slot above the given one
    [slotRow, slotColumn] = @slotRowAndColumn slot
    return slot  if slotRow < 1
    above = @lines[slotRow - 1]
    return @lineSlots[slotRow - 1] + above.length  if above.length < slotColumn - 1
    @lineSlots[slotRow - 1] + slotColumn
  
  downFrom: (slot) ->
    # answer the slot below the given one
    [slotRow, slotColumn] = @slotRowAndColumn slot
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
  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "align left", true, @, "setAlignmentToLeft"  if @alignment isnt "left"
    menu.addMenuItem "align right", true, @, "setAlignmentToRight"  if @alignment isnt "right"
    menu.addMenuItem "align center", true, @, "setAlignmentToCenter"  if @alignment isnt "center"
    menu.addMenuItem "run contents", true, @, "doContents"
  
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
    menu = @buildHierarchyMenu()

    if @text.length > 0
      menu.prependLine()
      menu.prependMenuItem "select all", true, @, "selectAllAndEdit"
      menu.prependMenuItem "do all", true, @, "doAll"

    # only show the do it / show it / inspect it entries
    # if there is actually something selected.
    if @selection().replace(/^\s\s*/, '').replace(/\s\s*$/, '') != ''
      menu.prependLine()
      menu.prependMenuItem "inspect selection", true, @, "inspectSelection", "evaluate the\nselected expression\nand inspect the result"
      menu.prependMenuItem "show selection", true, @, "showSelection", "evaluate the\nselected expression\nand show the result"
      menu.prependMenuItem "do selection", true, @, "doSelection", "evaluate the\nselected expression"
    menu

  selectAllAndEdit: ->
    @edit()
    @selectAll()

  # TODO this can be done more
  # abstractly, bypassing the
  # actual selection and doSelection...
  doAll: ->
    @edit()
    @selectAll()
    @doSelection()
    @clearSelection()

  # this is set by the inspector. It tells the TextMorph
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

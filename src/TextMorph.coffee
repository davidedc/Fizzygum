# TextMorph ///////////////////////////////////////////////////////////

# I am a multi-line, word-wrapping String

# Note that in the original Jens' Morphic.js version he
# has made this quasi-inheriting from StringMorph i.e. he is copying
# over manually the following methods like so:
#
#  TextMorph::font = StringMorph::font
#  TextMorph::edit = StringMorph::edit
#  TextMorph::selection = StringMorph::selection
#  TextMorph::selectionStartSlot = StringMorph::selectionStartSlot
#  TextMorph::clearSelection = StringMorph::clearSelection
#  TextMorph::deleteSelection = StringMorph::deleteSelection
#  TextMorph::selectAll = StringMorph::selectAll
#  TextMorph::mouseClickLeft = StringMorph::mouseClickLeft
#  TextMorph::enableSelecting = StringMorph::enableSelecting 
#  TextMorph::disableSelecting = StringMorph::disableSelecting
#  TextMorph::toggleIsDraggable = StringMorph::toggleIsDraggable
#  TextMorph::toggleWeight = StringMorph::toggleWeight
#  TextMorph::toggleItalic = StringMorph::toggleItalic
#  TextMorph::setSerif = StringMorph::setSerif
#  TextMorph::setSansSerif = StringMorph::setSansSerif
#  TextMorph::setText = StringMorph::setText
#  TextMorph::setFontSize = StringMorph::setFontSize
#  TextMorph::numericalSetters = StringMorph::numericalSetters


class TextMorph extends StringMorph

  words: []
  lines: []
  lineSlots: []
  alignment: null
  maxWidth: null
  maxLineWidth: 0
  backgroundColor: null

  #additional properties for ad-hoc evaluation:
  receiver: null

  constructor: (
    text, @fontSize = 12, @fontStyle = "sans-serif", @isBold = false,
    @isItalic = false, @alignment = "left", @maxWidth = 0, fontName, shadowOffset,
    @shadowColor = null
    ) ->
      super()
      # override inherited properites:
      @markedTextColor = new Color(255, 255, 255)
      @markedBackgoundColor = new Color(60, 60, 120)
      @text = text or ((if text is "" then text else "TextMorph"))
      @fontName = fontName or WorldMorph.MorphicPreferences.globalFontFamily
      @shadowOffset = shadowOffset or new Point(0, 0)
      @color = new Color(0, 0, 0)
      @noticesTransparentClick = true
      @updateRendering()
  
  breakTextIntoLines: ->
    paragraphs = @text.split("\n")
    canvas = newCanvas()
    context = canvas.getContext("2d")
    currentLine = ""
    slot = 0
    context.font = @font()
    @maxLineWidth = 0
    @lines = []
    @lineSlots = [0]
    @words = []
    
    # put all the text in an array, word by word
    paragraphs.forEach (p) =>
      @words = @words.concat(p.split(" "))
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
        @maxLineWidth = Math.max(@maxLineWidth, context.measureText(currentLine).width)
        currentLine = ""
      else
        if @maxWidth > 0
          # there is a width limit, so we need
          # to check whether we overflowed it. So create
          # a prospective line and then check its width.
          lineForOverflowTest = currentLine + word + " "
          w = context.measureText(lineForOverflowTest).width
          if w > @maxWidth
            # ok we just overflowed the available space,
            # so we need to push the old line and its
            # "slot" number to the respective arrays.
            # the new line is going to only contain the
            # word that has caused the overflow.
            @lines.push currentLine
            @lineSlots.push slot
            @maxLineWidth = Math.max(@maxLineWidth, context.measureText(currentLine).width)
            currentLine = word + " "
          else
            # no overflow happened, so just proceed as normal
            currentLine = lineForOverflowTest
        else
          currentLine = currentLine + word + " "
        slot += word.length + 1
  
  
  updateRendering: ->
    @image = newCanvas()
    context = @image.getContext("2d")
    context.font = @font()
    @breakTextIntoLines()

    # set my extent
    shadowWidth = Math.abs(@shadowOffset.x)
    shadowHeight = Math.abs(@shadowOffset.y)
    height = @lines.length * (fontHeight(@fontSize) + shadowHeight)
    if @maxWidth is 0
      @bounds = @bounds.origin.extent(new Point(@maxLineWidth + shadowWidth, height))
    else
      @bounds = @bounds.origin.extent(new Point(@maxWidth + shadowWidth, height))
    @image.width = @width()
    @image.height = @height()

    # changing the canvas size resets many of
    # the properties of the canvas, so we need to
    # re-initialise the font and alignments here
    context.font = @font()
    context.textAlign = "left"
    context.textBaseline = "bottom"

    # fill the background, if desired
    if @backgroundColor
      context.fillStyle = @backgroundColor.toString()
      context.fillRect 0, 0, @width(), @height()
    #
    # draw the shadow, if any
    if @shadowColor
      offx = Math.max(@shadowOffset.x, 0)
      offy = Math.max(@shadowOffset.y, 0)
      #console.log 'shadow x: ' + offx + " y: " + offy
      context.fillStyle = @shadowColor.toString()
      i = 0
      for line in @lines
        width = context.measureText(line).width + shadowWidth
        if @alignment is "right"
          x = @width() - width
        else if @alignment is "center"
          x = (@width() - width) / 2
        else # 'left'
          x = 0
        y = (i + 1) * (fontHeight(@fontSize) + shadowHeight) - shadowHeight
        i++
        context.fillText line, x + offx, y + offy
    #
    # now draw the actual text
    offx = Math.abs(Math.min(@shadowOffset.x, 0))
    offy = Math.abs(Math.min(@shadowOffset.y, 0))
    #console.log 'maintext x: ' + offx + " y: " + offy
    context.fillStyle = @color.toString()
    i = 0
    for line in @lines
      width = context.measureText(line).width + shadowWidth
      if @alignment is "right"
        x = @width() - width
      else if @alignment is "center"
        x = (@width() - width) / 2
      else # 'left'
        x = 0
      y = (i + 1) * (fontHeight(@fontSize) + shadowHeight) - shadowHeight
      i++
      context.fillText line, x + offx, y + offy

    # Draw the selection. This is done by re-drawing the
    # selected text, one character at the time, just with
    # a background rectangle.
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    for i in [start...stop]
      p = @slotCoordinates(i).subtract(@position())
      c = @text.charAt(i)
      context.fillStyle = @markedBackgoundColor.toString()
      context.fillRect p.x, p.y, context.measureText(c).width + 1, fontHeight(@fontSize)
      context.fillStyle = @markedTextColor.toString()
      context.fillText c, p.x, p.y + fontHeight(@fontSize)
    #
    # notify my parent of layout change
    @parent.layoutChanged()  if @parent.layoutChanged  if @parent
  
  setExtent: (aPoint) ->
    @maxWidth = Math.max(aPoint.x, 0)
    @changed()
    @updateRendering()
  
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
    context = @image.getContext("2d")
    shadowHeight = Math.abs(@shadowOffset.y)
    yOffset = slotRow * (fontHeight(@fontSize) + shadowHeight)
    xOffset = context.measureText((@lines[slotRow]).substring(0,slotColumn)).width
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
    context = @image.getContext("2d")
    row += 1  while aPoint.y - @top() > ((fontHeight(@fontSize) + shadowHeight) * row)
    row = Math.max(row, 1)
    while aPoint.x - @left() > charX
      charX += context.measureText(@lines[row - 1][col]).width
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
    menu.addItem "edit", "edit"
    menu.addItem "font size...", (->
      @prompt menu.title + "\nfont\nsize:",
        @setFontSize, @, @fontSize.toString(), null, 6, 100, true
    ), "set this Text's\nfont point size"
    menu.addItem "align left", "setAlignmentToLeft"  if @alignment isnt "left"
    menu.addItem "align right", "setAlignmentToRight"  if @alignment isnt "right"
    menu.addItem "align center", "setAlignmentToCenter"  if @alignment isnt "center"
    menu.addLine()
    menu.addItem "serif", "setSerif"  if @fontStyle isnt "serif"
    menu.addItem "sans-serif", "setSansSerif"  if @fontStyle isnt "sans-serif"
    if @isBold
      menu.addItem "normal weight", "toggleWeight"
    else
      menu.addItem "bold", "toggleWeight"
    if @isItalic
      menu.addItem "normal style", "toggleItalic"
    else
      menu.addItem "italic", "toggleItalic"
    menu
  
  setAlignmentToLeft: ->
    @alignment = "left"
    @updateRendering()
    @changed()
  
  setAlignmentToRight: ->
    @alignment = "right"
    @updateRendering()
    @changed()
  
  setAlignmentToCenter: ->
    @alignment = "center"
    @updateRendering()
    @changed()  
  
  # TextMorph evaluation:
  evaluationMenu: ->
    menu = @hierarchyMenu()
    menu.prependLine()
    menu.prependItem "select all", "selectAllAndEdit"
    menu.prependLine()
    menu.prependItem "inspect it", "inspectIt", "evaluate the\nselected expression\nand inspect the result"
    menu.prependItem "show it", "showIt", "evaluate the\nselected expression\nand show the result"
    menu.prependItem "do it", "doIt", "evaluate the\nselected expression"
    menu

  selectAllAndEdit: ->
    @edit()
    @selectAll()
   
  setReceiver: (obj) ->
    @receiver = obj
    @customContextMenu = @evaluationMenu
  
  doIt: ->
    @receiver.evaluateString @selection()
    @edit()
  
  showIt: ->
    result = @receiver.evaluateString(@selection())
    if result? then @inform result
  
  inspectIt: ->
    # evaluateString is a pimped-up eval in
    # the Morph class.
    result = @receiver.evaluateString(@selection())
    if result? then @spawnInspector result

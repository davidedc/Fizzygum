# StringMorph /////////////////////////////////////////////////////////

# I am a single line of text

class StringMorph extends Morph
  constructor: (text, fontSize, fontStyle, bold, italic, isNumeric, shadowOffset, shadowColor, color, fontName) ->
    # additional properties:
    @text = text or ((if (text is "") then "" else "StringMorph"))
    @fontSize = fontSize or 12
    @fontName = fontName or MorphicPreferences.globalFontFamily
    @fontStyle = fontStyle or "sans-serif"
    @isBold = bold or false
    @isItalic = italic or false
    @isEditable = false
    @isNumeric = isNumeric or false
    @shadowOffset = shadowOffset or new Point(0, 0)
    @shadowColor = shadowColor or null
    @isShowingBlanks = false
    @blanksColor = new Color(180, 140, 140)
    #
    # additional properties for text-editing:
    @currentlySelecting = false
    @startMark = 0
    @endMark = 0
    @markedTextColor = new Color(255, 255, 255)
    @markedBackgoundColor = new Color(60, 60, 120)
    #
    # initialize inherited properties:
    super()
    #
    # override inherited properites:
    @color = color or new Color(0, 0, 0)
    @noticesTransparentClick = true
    @drawNew()

StringMorph::toString = ->
  # e.g. 'a StringMorph("Hello World")'
  "a " + (@constructor.name or @constructor.toString().split(" ")[1].split("(")[0]) + "(\"" + @text.slice(0, 30) + "...\")"

StringMorph::font = ->
  # answer a font string, e.g. 'bold italic 12px sans-serif'
  font = ""
  font = font + "bold "  if @isBold
  font = font + "italic "  if @isItalic
  font + @fontSize + "px " + ((if @fontName then @fontName + ", " else "")) + @fontStyle

StringMorph::drawNew = ->
  context = undefined
  width = undefined
  start = undefined
  stop = undefined
  i = undefined
  p = undefined
  c = undefined
  x = undefined
  y = undefined
  #
  # initialize my surface property
  @image = newCanvas()
  context = @image.getContext("2d")
  context.font = @font()
  #
  # set my extent
  width = Math.max(context.measureText(@text).width + Math.abs(@shadowOffset.x), 1)
  @bounds.corner = @bounds.origin.add(new Point(width, fontHeight(@fontSize) + Math.abs(@shadowOffset.y)))
  @image.width = width
  @image.height = @height()
  #
  # prepare context for drawing text
  context.font = @font()
  context.textAlign = "left"
  context.textBaseline = "bottom"
  #
  # first draw the shadow, if any
  if @shadowColor
    x = Math.max(@shadowOffset.x, 0)
    y = Math.max(@shadowOffset.y, 0)
    context.fillStyle = @shadowColor.toString()
    context.fillText @text, x, fontHeight(@fontSize) + y
  #
  # now draw the actual text
  x = Math.abs(Math.min(@shadowOffset.x, 0))
  y = Math.abs(Math.min(@shadowOffset.y, 0))
  context.fillStyle = @color.toString()
  if @isShowingBlanks
    @renderWithBlanks context, x, fontHeight(@fontSize) + y
  else
    context.fillText @text, x, fontHeight(@fontSize) + y
  #
  # draw the selection
  start = Math.min(@startMark, @endMark)
  stop = Math.max(@startMark, @endMark)
  i = start
  while i < stop
    p = @slotPosition(i).subtract(@position())
    c = @text.charAt(i)
    context.fillStyle = @markedBackgoundColor.toString()
    context.fillRect p.x, p.y, context.measureText(c).width + 1 + x, fontHeight(@fontSize) + y
    context.fillStyle = @markedTextColor.toString()
    context.fillText c, p.x + x, fontHeight(@fontSize) + y
    i += 1
  #
  # notify my parent of layout change
  @parent.fixLayout()  if @parent.fixLayout  if @parent

StringMorph::renderWithBlanks = (context, startX, y) ->
  # create the blank form
  drawBlank = ->
    context.drawImage blank, Math.round(x), 0
    x += space
  space = context.measureText(" ").width
  blank = newCanvas(new Point(space, @height()))
  ctx = blank.getContext("2d")
  words = @text.split(" ")
  x = startX or 0
  isFirst = true
  ctx.fillStyle = @blanksColor.toString()
  ctx.arc space / 2, blank.height / 2, space / 2, radians(0), radians(360)
  ctx.fill()
  #
  # render my text inserting blanks
  words.forEach (word) ->
    drawBlank()  unless isFirst
    isFirst = false
    if word isnt ""
      context.fillText word, x, y
      x += context.measureText(word).width


# StringMorph mesuring:
StringMorph::slotPosition = (slot) ->
  # answer the position point of the given index ("slot")
  # where the cursor should be placed
  dest = Math.min(Math.max(slot, 0), @text.length)
  context = @image.getContext("2d")
  xOffset = undefined
  x = undefined
  y = undefined
  idx = undefined
  xOffset = 0
  idx = 0
  while idx < dest
    xOffset += context.measureText(@text[idx]).width
    idx += 1
  @pos = dest
  x = @left() + xOffset
  y = @top()
  new Point(x, y)

StringMorph::slotAt = (aPoint) ->
  # answer the slot (index) closest to the given point
  # so the cursor can be moved accordingly
  idx = 0
  charX = 0
  context = @image.getContext("2d")
  while aPoint.x - @left() > charX
    charX += context.measureText(@text[idx]).width
    idx += 1
    return idx  if (context.measureText(@text).width - (context.measureText(@text[idx - 1]).width / 2)) < (aPoint.x - @left())  if idx is @text.length
  idx - 1

StringMorph::upFrom = (slot) ->
  # answer the slot above the given one
  slot

StringMorph::downFrom = (slot) ->
  # answer the slot below the given one
  slot

StringMorph::startOfLine = ->
  # answer the first slot (index) of the line for the given slot
  0

StringMorph::endOfLine = ->
  # answer the slot (index) indicating the EOL for the given slot
  @text.length

# StringMorph menus:
StringMorph::developersMenu = ->
  menu = super()
  menu.addLine()
  menu.addItem "edit", "edit"
  menu.addItem "font size...", (->
    @prompt menu.title + "\nfont\nsize:", @setFontSize, @, @fontSize.toString(), null, 6, 500, true
  ), "set this String's\nfont point size"
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
  if @isShowingBlanks
    menu.addItem "hide blanks", "toggleShowBlanks"
  else
    menu.addItem "show blanks", "toggleShowBlanks"
  menu

StringMorph::toggleIsDraggable = ->
  # for context menu demo purposes
  @isDraggable = not @isDraggable
  if @isDraggable
    @disableSelecting()
  else
    @enableSelecting()

StringMorph::toggleShowBlanks = ->
  @isShowingBlanks = not @isShowingBlanks
  @changed()
  @drawNew()
  @changed()

StringMorph::toggleWeight = ->
  @isBold = not @isBold
  @changed()
  @drawNew()
  @changed()

StringMorph::toggleItalic = ->
  @isItalic = not @isItalic
  @changed()
  @drawNew()
  @changed()

StringMorph::setSerif = ->
  @fontStyle = "serif"
  @changed()
  @drawNew()
  @changed()

StringMorph::setSansSerif = ->
  @fontStyle = "sans-serif"
  @changed()
  @drawNew()
  @changed()

StringMorph::setFontSize = (size) ->
  # for context menu demo purposes
  newSize = undefined
  if typeof size is "number"
    @fontSize = Math.round(Math.min(Math.max(size, 4), 500))
  else
    newSize = parseFloat(size)
    @fontSize = Math.round(Math.min(Math.max(newSize, 4), 500))  unless isNaN(newSize)
  @changed()
  @drawNew()
  @changed()

StringMorph::setText = (size) ->
  # for context menu demo purposes
  @text = Math.round(size).toString()
  @changed()
  @drawNew()
  @changed()

StringMorph::numericalSetters = ->
  # for context menu demo purposes
  ["setLeft", "setTop", "setAlphaScaled", "setFontSize", "setText"]


# StringMorph editing:
StringMorph::edit = ->
  @root().edit @

StringMorph::selection = ->
  start = undefined
  stop = undefined
  start = Math.min(@startMark, @endMark)
  stop = Math.max(@startMark, @endMark)
  @text.slice start, stop

StringMorph::selectionStartSlot = ->
  Math.min @startMark, @endMark

StringMorph::clearSelection = ->
  @currentlySelecting = false
  @startMark = 0
  @endMark = 0
  @drawNew()
  @changed()

StringMorph::deleteSelection = ->
  start = undefined
  stop = undefined
  text = undefined
  text = @text
  start = Math.min(@startMark, @endMark)
  stop = Math.max(@startMark, @endMark)
  @text = text.slice(0, start) + text.slice(stop)
  @changed()
  @clearSelection()

StringMorph::selectAll = ->
  if @mouseDownLeft # make sure selecting is enabled
    @startMark = 0
    @endMark = @text.length
    @drawNew()
    @changed()

StringMorph::mouseClickLeft = (pos) ->
  if @isEditable
    @edit()  unless @currentlySelecting
    @root().cursor.gotoPos pos
    @currentlySelecting = false
  else
    @escalateEvent "mouseClickLeft", pos

StringMorph::enableSelecting = ->
  @mouseDownLeft = (pos) ->
    @clearSelection()
    if @isEditable and (not @isDraggable)
      @edit()
      @root().cursor.gotoPos pos
      @startMark = @slotAt(pos)
      @endMark = @startMark
      @currentlySelecting = true
  
  @mouseMove = (pos) ->
    if @isEditable and @currentlySelecting and (not @isDraggable)
      newMark = @slotAt(pos)
      if newMark isnt @endMark
        @endMark = newMark
        @drawNew()
        @changed()

StringMorph::disableSelecting = ->
  delete @mouseDownLeft
  delete @mouseMove

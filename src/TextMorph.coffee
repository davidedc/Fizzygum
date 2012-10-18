# TextMorph ///////////////////////////////////////////////////////////

# I am a multi-line, word-wrapping String

class TextMorph extends Morph
  constructor: (text, fontSize, fontStyle, bold, italic, alignment, width, fontName, shadowOffset, shadowColor) ->
    @init text, fontSize, fontStyle, bold, italic, alignment, width, fontName, shadowOffset, shadowColor


# TextMorph instance creation:
TextMorph::init = (text, fontSize, fontStyle, bold, italic, alignment, width, fontName, shadowOffset, shadowColor) ->
  
  # additional properties:
  @text = text or ((if text is "" then text else "TextMorph"))
  @words = []
  @lines = []
  @lineSlots = []
  @fontSize = fontSize or 12
  @fontName = fontName or MorphicPreferences.globalFontFamily
  @fontStyle = fontStyle or "sans-serif"
  @isBold = bold or false
  @isItalic = italic or false
  @alignment = alignment or "left"
  @shadowOffset = shadowOffset or new Point(0, 0)
  @shadowColor = shadowColor or null
  @maxWidth = width or 0
  @maxLineWidth = 0
  @backgroundColor = null
  @isEditable = false
  
  #additional properties for ad-hoc evaluation:
  @receiver = null
  
  # additional properties for text-editing:
  @currentlySelecting = false
  @startMark = 0
  @endMark = 0
  @markedTextColor = new Color(255, 255, 255)
  @markedBackgoundColor = new Color(60, 60, 120)
  
  # initialize inherited properties:
  super()
  
  # override inherited properites:
  @color = new Color(0, 0, 0)
  @noticesTransparentClick = true
  @drawNew()

TextMorph::toString = ->
  
  # e.g. 'a TextMorph("Hello World")'
  "a TextMorph" + "(\"" + @text.slice(0, 30) + "...\")"

TextMorph::font = ->
  
  # answer a font string, e.g. 'bold italic 12px sans-serif'
  font = ""
  font = font + "bold "  if @isBold
  font = font + "italic "  if @isItalic
  font + @fontSize + "px " + ((if @fontName then @fontName + ", " else "")) + @fontStyle

TextMorph::parse = ->
  myself = this
  paragraphs = @text.split("\n")
  canvas = newCanvas()
  context = canvas.getContext("2d")
  oldline = ""
  newline = undefined
  w = undefined
  slot = 0
  context.font = @font()
  @maxLineWidth = 0
  @lines = []
  @lineSlots = [0]
  @words = []
  paragraphs.forEach (p) ->
    myself.words = myself.words.concat(p.split(" "))
    myself.words.push "\n"

  @words.forEach (word) ->
    if word is "\n"
      myself.lines.push oldline
      myself.lineSlots.push slot
      myself.maxLineWidth = Math.max(myself.maxLineWidth, context.measureText(oldline).width)
      oldline = ""
    else
      if myself.maxWidth > 0
        newline = oldline + word + " "
        w = context.measureText(newline).width
        if w > myself.maxWidth
          myself.lines.push oldline
          myself.lineSlots.push slot
          myself.maxLineWidth = Math.max(myself.maxLineWidth, context.measureText(oldline).width)
          oldline = word + " "
        else
          oldline = newline
      else
        oldline = oldline + word + " "
      slot += word.length + 1


TextMorph::drawNew = ->
  context = undefined
  height = undefined
  i = undefined
  line = undefined
  width = undefined
  shadowHeight = undefined
  shadowWidth = undefined
  offx = undefined
  offy = undefined
  x = undefined
  y = undefined
  start = undefined
  stop = undefined
  p = undefined
  c = undefined
  @image = newCanvas()
  context = @image.getContext("2d")
  context.font = @font()
  @parse()
  
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
  
  # prepare context for drawing text
  context = @image.getContext("2d")
  context.font = @font()
  context.textAlign = "left"
  context.textBaseline = "bottom"
  
  # fill the background, if desired
  if @backgroundColor
    context.fillStyle = @backgroundColor.toString()
    context.fillRect 0, 0, @width(), @height()
  
  # draw the shadow, if any
  if @shadowColor
    offx = Math.max(@shadowOffset.x, 0)
    offy = Math.max(@shadowOffset.y, 0)
    context.fillStyle = @shadowColor.toString()
    i = 0
    while i < @lines.length
      line = @lines[i]
      width = context.measureText(line).width + shadowWidth
      if @alignment is "right"
        x = @width() - width
      else if @alignment is "center"
        x = (@width() - width) / 2
      else # 'left'
        x = 0
      y = (i + 1) * (fontHeight(@fontSize) + shadowHeight) - shadowHeight
      context.fillText line, x + offx, y + offy
      i = i + 1
  
  # now draw the actual text
  offx = Math.abs(Math.min(@shadowOffset.x, 0))
  offy = Math.abs(Math.min(@shadowOffset.y, 0))
  context.fillStyle = @color.toString()
  i = 0
  while i < @lines.length
    line = @lines[i]
    width = context.measureText(line).width + shadowWidth
    if @alignment is "right"
      x = @width() - width
    else if @alignment is "center"
      x = (@width() - width) / 2
    else # 'left'
      x = 0
    y = (i + 1) * (fontHeight(@fontSize) + shadowHeight) - shadowHeight
    context.fillText line, x + offx, y + offy
    i = i + 1
  
  # draw the selection
  start = Math.min(@startMark, @endMark)
  stop = Math.max(@startMark, @endMark)
  i = start
  while i < stop
    p = @slotPosition(i).subtract(@position())
    c = @text.charAt(i)
    context.fillStyle = @markedBackgoundColor.toString()
    context.fillRect p.x, p.y, context.measureText(c).width + 1, fontHeight(@fontSize)
    context.fillStyle = @markedTextColor.toString()
    context.fillText c, p.x, p.y + fontHeight(@fontSize)
    i += 1
  
  # notify my parent of layout change
  @parent.layoutChanged()  if @parent.layoutChanged  if @parent

TextMorph::setExtent = (aPoint) ->
  @maxWidth = Math.max(aPoint.x, 0)
  @changed()
  @drawNew()


# TextMorph mesuring:
TextMorph::columnRow = (slot) ->
  
  # answer the logical position point of the given index ("slot")
  row = undefined
  col = undefined
  idx = 0
  row = 0
  while row < @lines.length
    idx = @lineSlots[row]
    col = 0
    while col < @lines[row].length
      return new Point(col, row)  if idx is slot
      idx += 1
      col += 1
    row += 1
  
  # return new Point(0, 0);
  new Point(@lines[@lines.length - 1].length - 1, @lines.length - 1)

TextMorph::slotPosition = (slot) ->
  
  # answer the physical position point of the given index ("slot")
  # where the cursor should be placed
  colRow = @columnRow(slot)
  context = @image.getContext("2d")
  shadowHeight = Math.abs(@shadowOffset.y)
  xOffset = 0
  yOffset = undefined
  x = undefined
  y = undefined
  idx = undefined
  yOffset = colRow.y * (fontHeight(@fontSize) + shadowHeight)
  idx = 0
  while idx < colRow.x
    xOffset += context.measureText(@lines[colRow.y][idx]).width
    idx += 1
  x = @left() + xOffset
  y = @top() + yOffset
  new Point(x, y)

TextMorph::slotAt = (aPoint) ->
  
  # answer the slot (index) closest to the given point
  # so the cursor can be moved accordingly
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

TextMorph::upFrom = (slot) ->
  
  # answer the slot above the given one
  above = undefined
  colRow = @columnRow(slot)
  return slot  if colRow.y < 1
  above = @lines[colRow.y - 1]
  return @lineSlots[colRow.y - 1] + above.length  if above.length < colRow.x - 1
  @lineSlots[colRow.y - 1] + colRow.x

TextMorph::downFrom = (slot) ->
  
  # answer the slot below the given one
  below = undefined
  colRow = @columnRow(slot)
  return slot  if colRow.y > @lines.length - 2
  below = @lines[colRow.y + 1]
  return @lineSlots[colRow.y + 1] + below.length  if below.length < colRow.x - 1
  @lineSlots[colRow.y + 1] + colRow.x

TextMorph::startOfLine = (slot) ->
  
  # answer the first slot (index) of the line for the given slot
  @lineSlots[@columnRow(slot).y]

TextMorph::endOfLine = (slot) ->
  
  # answer the slot (index) indicating the EOL for the given slot
  @startOfLine(slot) + @lines[@columnRow(slot).y].length - 1


# TextMorph editing:
TextMorph::edit = ->
  @root().edit this

TextMorph::selection = ->
  start = undefined
  stop = undefined
  start = Math.min(@startMark, @endMark)
  stop = Math.max(@startMark, @endMark)
  @text.slice start, stop

TextMorph::selectionStartSlot = ->
  Math.min @startMark, @endMark

TextMorph::clearSelection = ->
  @currentlySelecting = false
  @startMark = 0
  @endMark = 0
  @drawNew()
  @changed()

TextMorph::deleteSelection = ->
  start = undefined
  stop = undefined
  text = undefined
  text = @text
  start = Math.min(@startMark, @endMark)
  stop = Math.max(@startMark, @endMark)
  @text = text.slice(0, start) + text.slice(stop)
  @changed()
  @clearSelection()

TextMorph::selectAll = ->
  @startMark = 0
  @endMark = @text.length
  @drawNew()
  @changed()

TextMorph::selectAllAndEdit = ->
  @edit()
  @selectAll()

TextMorph::mouseClickLeft = (pos) ->
  if @isEditable
    @edit()  unless @currentlySelecting
    @root().cursor.gotoPos pos
    @currentlySelecting = false
  else
    @escalateEvent "mouseClickLeft", pos

TextMorph::enableSelecting = ->
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

TextMorph::disableSelecting = ->
  delete @mouseDownLeft

  delete @mouseMove


# TextMorph menus:
TextMorph::developersMenu = ->
  menu = super()
  menu.addLine()
  menu.addItem "edit", "edit"
  menu.addItem "font size...", (->
    @prompt menu.title + "\nfont\nsize:", @setFontSize, this, @fontSize.toString(), null, 6, 100, true
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

TextMorph::toggleIsDraggable = ->
  
  # for context menu demo purposes
  @isDraggable = not @isDraggable
  if @isDraggable
    @disableSelecting()
  else
    @enableSelecting()

TextMorph::setAlignmentToLeft = ->
  @alignment = "left"
  @drawNew()
  @changed()

TextMorph::setAlignmentToRight = ->
  @alignment = "right"
  @drawNew()
  @changed()

TextMorph::setAlignmentToCenter = ->
  @alignment = "center"
  @drawNew()
  @changed()

TextMorph::toggleWeight = ->
  @isBold = not @isBold
  @changed()
  @drawNew()
  @changed()

TextMorph::toggleItalic = ->
  @isItalic = not @isItalic
  @changed()
  @drawNew()
  @changed()

TextMorph::setSerif = ->
  @fontStyle = "serif"
  @changed()
  @drawNew()
  @changed()

TextMorph::setSansSerif = ->
  @fontStyle = "sans-serif"
  @changed()
  @drawNew()
  @changed()

TextMorph::setText = (size) ->
  
  # for context menu demo purposes
  @text = Math.round(size).toString()
  @changed()
  @drawNew()
  @changed()

TextMorph::setFontSize = (size) ->
  
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

TextMorph::numericalSetters = ->
  
  # for context menu demo purposes
  ["setLeft", "setTop", "setAlphaScaled", "setFontSize", "setText"]


# TextMorph evaluation:
TextMorph::evaluationMenu = ->
  menu = new MenuMorph(this, null)
  menu.addItem "do it", "doIt", "evaluate the\nselected expression"
  menu.addItem "show it", "showIt", "evaluate the\nselected expression\nand show the result"
  menu.addItem "inspect it", "inspectIt", "evaluate the\nselected expression\nand inspect the result"
  menu.addLine()
  menu.addItem "select all", "selectAllAndEdit"
  menu

TextMorph::setReceiver = (obj) ->
  @receiver = obj
  @customContextMenu = @evaluationMenu()

TextMorph::doIt = ->
  @receiver.evaluateString @selection()
  @edit()

TextMorph::showIt = ->
  result = @receiver.evaluateString(@selection())
  @inform result  if result isnt null

TextMorph::inspectIt = ->
  result = @receiver.evaluateString(@selection())
  world = @world()
  inspector = undefined
  if result isnt null
    inspector = new InspectorMorph(result)
    inspector.setPosition world.hand.position()
    inspector.keepWithin world
    world.add inspector
    inspector.changed()

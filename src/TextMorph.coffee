# TextMorph ///////////////////////////////////////////////////////////

# I am a multi-line, word-wrapping String

# Jens has made this quasi-inheriting from StringMorph i.e. he is copying
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

  toString: ->
    # e.g. 'a TextMorph("Hello World")'
    "a TextMorph" + "(\"" + @text.slice(0, 30) + "...\")"
  
  
  parse: ->
    paragraphs = @text.split("\n")
    canvas = newCanvas()
    context = canvas.getContext("2d")
    oldline = ""
    slot = 0
    context.font = @font()
    @maxLineWidth = 0
    @lines = []
    @lineSlots = [0]
    @words = []
    paragraphs.forEach (p) =>
      @words = @words.concat(p.split(" "))
      @words.push "\n"
    #
    @words.forEach (word) =>
      if word is "\n"
        @lines.push oldline
        @lineSlots.push slot
        @maxLineWidth = Math.max(@maxLineWidth, context.measureText(oldline).width)
        oldline = ""
      else
        if @maxWidth > 0
          newline = oldline + word + " "
          w = context.measureText(newline).width
          if w > @maxWidth
            @lines.push oldline
            @lineSlots.push slot
            @maxLineWidth = Math.max(@maxLineWidth, context.measureText(oldline).width)
            oldline = word + " "
          else
            oldline = newline
        else
          oldline = oldline + word + " "
        slot += word.length + 1
  
  
  updateRendering: ->
    @image = newCanvas()
    context = @image.getContext("2d")
    context.font = @font()
    @parse()
    #
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
    #
    # prepare context for drawing text
    context = @image.getContext("2d")
    context.font = @font()
    context.textAlign = "left"
    context.textBaseline = "bottom"
    #
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
    #
    # draw the selection
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    for i in [start...stop]
      p = @slotPosition(i).subtract(@position())
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
  
  # TextMorph mesuring:
  columnRow: (slot) ->
    # answer the logical position point of the given index ("slot")
    idx = 0
    for row in [0...@lines.length]
      idx = @lineSlots[row]
      for col in [0...@lines[row].length]
        return new Point(col, row)  if idx is slot
        idx += 1
    #
    # return new Point(0, 0);
    new Point(@lines[@lines.length - 1].length - 1, @lines.length - 1)
  
  slotPosition: (slot) ->
    # answer the physical position point of the given index ("slot")
    # where the caret should be placed
    colRow = @columnRow(slot)
    context = @image.getContext("2d")
    shadowHeight = Math.abs(@shadowOffset.y)
    xOffset = 0
    yOffset = colRow.y * (fontHeight(@fontSize) + shadowHeight)
    for idx in [0...colRow.x]
      xOffset += context.measureText(@lines[colRow.y][idx]).width
    x = @left() + xOffset
    y = @top() + yOffset
    new Point(x, y)
  
  slotAt: (aPoint) ->
    # answer the slot (index) closest to the given point
    # so the caret can be moved accordingly
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
    colRow = @columnRow(slot)
    return slot  if colRow.y < 1
    above = @lines[colRow.y - 1]
    return @lineSlots[colRow.y - 1] + above.length  if above.length < colRow.x - 1
    @lineSlots[colRow.y - 1] + colRow.x
  
  downFrom: (slot) ->
    # answer the slot below the given one
    colRow = @columnRow(slot)
    return slot  if colRow.y > @lines.length - 2
    below = @lines[colRow.y + 1]
    return @lineSlots[colRow.y + 1] + below.length  if below.length < colRow.x - 1
    @lineSlots[colRow.y + 1] + colRow.x
  
  startOfLine: (slot) ->
    # answer the first slot (index) of the line for the given slot
    @lineSlots[@columnRow(slot).y]
  
  endOfLine: (slot) ->
    # answer the slot (index) indicating the EOL for the given slot
    @startOfLine(slot) + @lines[@columnRow(slot).y].length - 1
  
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
    menu = new MenuMorph(@, null)
    menu.addItem "do it", "doIt", "evaluate the\nselected expression"
    menu.addItem "show it", "showIt", "evaluate the\nselected expression\nand show the result"
    menu.addItem "inspect it", "inspectIt", "evaluate the\nselected expression\nand inspect the result"
    menu.addLine()
    menu.addItem "select all", "selectAllAndEdit"
    menu

  selectAllAndEdit: ->
    @edit()
    @selectAll()
   
  setReceiver: (obj) ->
    @receiver = obj
    @customContextMenu = @evaluationMenu()
  
  doIt: ->
    @receiver.evaluateString @selection()
    @edit()
  
  showIt: ->
    result = @receiver.evaluateString(@selection())
    if result? then @inform result
  
  inspectIt: ->
    result = @receiver.evaluateString(@selection())
    world = @world()
    if result?
      inspector = new InspectorMorph(result)
      inspector.setPosition world.hand.position()
      inspector.keepWithin world
      world.add inspector
      inspector.changed()

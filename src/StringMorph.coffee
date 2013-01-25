# StringMorph /////////////////////////////////////////////////////////

# I am a single line of text

class StringMorph extends Morph

  text: null
  fontSize: null
  fontName: null
  fontStyle: null
  isBold: null
  isItalic: null
  isEditable: false
  isNumeric: null
  shadowOffset: null
  shadowColor: null
  isShowingBlanks: false
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  blanksColor: new Color(180, 140, 140)
  #
  # Properties for text-editing
  currentlySelecting: false
  startMark: 0
  endMark: 0
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  markedTextColor: new Color(255, 255, 255)
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  markedBackgoundColor: new Color(60, 60, 120)

  constructor: (
      text,
      @fontSize = 12,
      @fontStyle = "sans-serif",
      @isBold = false,
      @isItalic = false,
      @isNumeric = false,
      shadowOffset,
      @shadowColor,
      color,
      fontName
      ) ->
    # additional properties:
    @text = text or ((if (text is "") then "" else "StringMorph"))
    @fontName = fontName or WorldMorph.MorphicPreferences.globalFontFamily
    @shadowOffset = shadowOffset or new Point(0, 0)
    #
    super()
    #
    # override inherited properites:
    @color = color or new Color(0, 0, 0)
    @noticesTransparentClick = true
    @drawNew()
  
  toString: ->
    # e.g. 'a StringMorph("Hello World")'
    "a " + (@constructor.name or @constructor.toString().split(" ")[1].split("(")[0]) + "(\"" + @text.slice(0, 30) + "...\")"
  
  font: ->
    # answer a font string, e.g. 'bold italic 12px sans-serif'
    font = ""
    font = font + "bold "  if @isBold
    font = font + "italic "  if @isItalic
    font + @fontSize + "px " + ((if @fontName then @fontName + ", " else "")) + @fontStyle
  
  drawNew: ->
    # initialize my surface property
    @image = newCanvas()
    context = @image.getContext("2d")
    context.font = @font()
    #
    # set my extent
    width = Math.max(context.measureText(@text).width + Math.abs(@shadowOffset.x), 1)
    @bounds.corner = @bounds.origin.add(new Point(
      width, fontHeight(@fontSize) + Math.abs(@shadowOffset.y)))
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
      context.fillRect p.x, p.y, context.measureText(c).width + 1 + x,
        fontHeight(@fontSize) + y
      context.fillStyle = @markedTextColor.toString()
      context.fillText c, p.x + x, fontHeight(@fontSize) + y
      i += 1
    #
    # notify my parent of layout change
    @parent.fixLayout()  if @parent.fixLayout  if @parent
  
  renderWithBlanks: (context, startX, y) ->
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
  slotPosition: (slot) ->
    # answer the position point of the given index ("slot")
    # where the cursor should be placed
    dest = Math.min(Math.max(slot, 0), @text.length)
    context = @image.getContext("2d")
    xOffset = 0
    idx = 0
    while idx < dest
      xOffset += context.measureText(@text[idx]).width
      idx += 1
    @pos = dest
    x = @left() + xOffset
    y = @top()
    new Point(x, y)
  
  slotAt: (aPoint) ->
    # answer the slot (index) closest to the given point
    # so the cursor can be moved accordingly
    idx = 0
    charX = 0
    context = @image.getContext("2d")
    while aPoint.x - @left() > charX
      charX += context.measureText(@text[idx]).width
      idx += 1
      if idx is @text.length
        if (context.measureText(@text).width - (context.measureText(@text[idx - 1]).width / 2)) < (aPoint.x - @left())  
          return idx
    idx - 1
  
  upFrom: (slot) ->
    # answer the slot above the given one
    slot
  
  downFrom: (slot) ->
    # answer the slot below the given one
    slot
  
  startOfLine: ->
    # answer the first slot (index) of the line for the given slot
    0
  
  endOfLine: ->
    # answer the slot (index) indicating the EOL for the given slot
    @text.length

  rawHeight: ->  
    # answer my corrected fontSize
    @height() / 1.2
    
  # StringMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "edit", "edit"
    menu.addItem "font size...", (->
      @prompt menu.title + "\nfont\nsize:",
        @setFontSize, @, @fontSize.toString(), null, 6, 500, true
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
  
  toggleIsDraggable: ->
    # for context menu demo purposes
    @isDraggable = not @isDraggable
    if @isDraggable
      @disableSelecting()
    else
      @enableSelecting()
  
  toggleShowBlanks: ->
    @isShowingBlanks = not @isShowingBlanks
    @changed()
    @drawNew()
    @changed()
  
  toggleWeight: ->
    @isBold = not @isBold
    @changed()
    @drawNew()
    @changed()
  
  toggleItalic: ->
    @isItalic = not @isItalic
    @changed()
    @drawNew()
    @changed()
  
  setSerif: ->
    @fontStyle = "serif"
    @changed()
    @drawNew()
    @changed()
  
  setSansSerif: ->
    @fontStyle = "sans-serif"
    @changed()
    @drawNew()
    @changed()
  
  setFontSize: (size) ->
    # for context menu demo purposes
    if typeof size is "number"
      @fontSize = Math.round(Math.min(Math.max(size, 4), 500))
    else
      newSize = parseFloat(size)
      @fontSize = Math.round(Math.min(Math.max(newSize, 4), 500))  unless isNaN(newSize)
    @changed()
    @drawNew()
    @changed()
  
  setText: (size) ->
    # for context menu demo purposes
    @text = Math.round(size).toString()
    @changed()
    @drawNew()
    @changed()
  
  numericalSetters: ->
    # for context menu demo purposes
    ["setLeft", "setTop", "setAlphaScaled", "setFontSize", "setText"]
  
  
  # StringMorph editing:
  edit: ->
    @root().edit @
  
  selection: ->
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    @text.slice start, stop
  
  selectionStartSlot: ->
    Math.min @startMark, @endMark
  
  clearSelection: ->
    @currentlySelecting = false
    @startMark = 0
    @endMark = 0
    @drawNew()
    @changed()
  
  deleteSelection: ->
    text = @text
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    @text = text.slice(0, start) + text.slice(stop)
    @changed()
    @clearSelection()
  
  selectAll: ->
    if @mouseDownLeft # make sure selecting is enabled
      @startMark = 0
      @endMark = @text.length
      @drawNew()
      @changed()
  
  mouseClickLeft: (pos) ->
    if @isEditable
      @edit()  unless @currentlySelecting
      @root().cursor.gotoPos pos
      @currentlySelecting = false
    else
      @escalateEvent "mouseClickLeft", pos
  
  enableSelecting: ->
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
  
  disableSelecting: ->
    delete @mouseDownLeft
    delete @mouseMove

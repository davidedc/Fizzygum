# StringMorph /////////////////////////////////////////////////////////

# A StringMorph is a single line of text. It can only be left-aligned.
# REQUIRES WorldMorph

class StringMorph extends Morph

  text: null
  fontSize: null
  fontName: null
  fontStyle: null
  isBold: null
  isItalic: null
  isEditable: false
  isNumeric: null
  isPassword: false
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
  isScrollable: true
  currentlySelecting: false
  startMark: null
  endMark: null
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
    @fontName = fontName or WorldMorph.preferencesAndSettings.globalFontFamily
    @shadowOffset = shadowOffset or new Point(0, 0)
    #
    super()
    #
    # override inherited properites:
    @color = color or new Color(0, 0, 0)
    @noticesTransparentClick = true
  
  toString: ->
    # e.g. 'a StringMorph("Hello World")'
    firstPart = super()
    if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.IDLE and SystemTestsRecorderAndPlayer.hidingOfMorphsContentExtractInLabels
      return firstPart
    else
      return firstPart + " (\"" + @text.slice(0, 30) + "...\")"
  
  password: (letter, length) ->
    ans = ""
    for i in [0...length]
      ans += letter
    ans

  font: ->
    # answer a font string, e.g. 'bold italic 12px sans-serif'
    font = ""
    font = font + "bold "  if @isBold
    font = font + "italic "  if @isItalic
    font + @fontSize + "px " + ((if @fontName then @fontName + ", " else "")) + @fontStyle
  
  updateRendering: ->
    text = (if @isPassword then @password("*", @text.length) else @text)
    # initialize my surface property
    @image = newCanvas()
    context = @image.getContext("2d")
    context.font = @font()
    context.textAlign = "left"
    context.textBaseline = "bottom"

    # set my extent based on the size of the text
    width = Math.max(context.measureText(text).width + Math.abs(@shadowOffset.x), 1)
    @bounds.corner = @bounds.origin.add(new Point(
      width, fontHeight(@fontSize) + Math.abs(@shadowOffset.y)))
    @image.width = width
    @image.height = @height()

    # changing the canvas size resets many of
    # the properties of the canvas, so we need to
    # re-initialise the font and alignments here
    context.font = @font()
    context.textAlign = "left"
    context.textBaseline = "bottom"

    # first draw the shadow, if any
    if @shadowColor
      x = Math.max(@shadowOffset.x, 0)
      y = Math.max(@shadowOffset.y, 0)
      context.fillStyle = @shadowColor.toString()
      context.fillText text, x, fontHeight(@fontSize) + y
    #
    # now draw the actual text
    x = Math.abs(Math.min(@shadowOffset.x, 0))
    y = Math.abs(Math.min(@shadowOffset.y, 0))
    context.fillStyle = @color.toString()
    if @isShowingBlanks
      @renderWithBlanks context, x, fontHeight(@fontSize) + y
    else
      context.fillText text, x, fontHeight(@fontSize) + y
    #
    # draw the selection
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    for i in [start...stop]
      p = @slotCoordinates(i).subtract(@position())
      c = text.charAt(i)
      context.fillStyle = @markedBackgoundColor.toString()
      context.fillRect p.x, p.y, context.measureText(c).width + 1 + x,
        fontHeight(@fontSize) + y
      context.fillStyle = @markedTextColor.toString()
      context.fillText c, p.x + x, fontHeight(@fontSize) + y
    #
    # notify my parent of layout change
    # @parent.layoutSubmorphs()  if @parent.layoutSubmorphs  if @parent
  
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
  slotCoordinates: (slot) ->
    # answer the position point of the given index ("slot")
    # where the caret should be placed
    text = (if @isPassword then @password("*", @text.length) else @text)
    dest = Math.min(Math.max(slot, 0), text.length)
    context = @image.getContext("2d")
    xOffset = context.measureText(text.substring(0,dest)).width
    @pos = dest
    x = @left() + xOffset
    y = @top()
    new Point(x, y)
  
  slotAt: (aPoint) ->
    # answer the slot (index) closest to the given point
    # so the caret can be moved accordingly
    text = (if @isPassword then @password("*", @text.length) else @text)
    idx = 0
    charX = 0
    context = @image.getContext("2d")
    while aPoint.x - @left() > charX
      charX += context.measureText(text[idx]).width
      idx += 1
      if idx is text.length
        if (context.measureText(text).width - (context.measureText(text[idx - 1]).width / 2)) < (aPoint.x - @left())  
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
    menu.addItem "edit", (->@edit())
    menu.addItem "font size...", (->
      @prompt menu.title + "\nfont\nsize:",
        @setFontSize, @fontSize.toString(), null, 6, 500, true
    ), "set this String's\nfont point size"
    menu.addItem "serif", (->@setSerif())  if @fontStyle isnt "serif"
    menu.addItem "sans-serif", (->@setSansSerif())  if @fontStyle isnt "sans-serif"

    if @isBold
      menu.addItem "normal weight", (->@toggleWeight())
    else
      menu.addItem "bold", (->@toggleWeight())

    if @isItalic
      menu.addItem "normal style", (->@toggleItalic())
    else
      menu.addItem "italic", (->@toggleItalic())

    if @isShowingBlanks
      menu.addItem "hide blanks", (->@toggleShowBlanks())
    else
      menu.addItem "show blanks", (->@toggleShowBlanks())

    if @isPassword
      menu.addItem "show characters", (->@toggleIsPassword())
    else
      menu.addItem "hide characters", (->@toggleIsPassword())

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
    @updateRendering()
    @changed()
  
  toggleWeight: ->
    @isBold = not @isBold
    @changed()
    @updateRendering()
    @changed()
  
  toggleItalic: ->
    @isItalic = not @isItalic
    @changed()
    @updateRendering()
    @changed()
  
  toggleIsPassword: ->
    @isPassword = not @isPassword
    @changed()
    @updateRendering()
    @changed()
  
  setSerif: ->
    @fontStyle = "serif"
    @changed()
    @updateRendering()
    @changed()
  
  setSansSerif: ->
    @fontStyle = "sans-serif"
    @changed()
    @updateRendering()
    @changed()
  
  setFontSize: (sizeOrMorphGivingSize) ->
    if sizeOrMorphGivingSize.getValue?
      size = sizeOrMorphGivingSize.getValue()
    else
      size = sizeOrMorphGivingSize

    # for context menu demo purposes
    if typeof size is "number"
      @fontSize = Math.round(Math.min(Math.max(size, 4), 500))
    else
      newSize = parseFloat(size)
      @fontSize = Math.round(Math.min(Math.max(newSize, 4), 500))  unless isNaN(newSize)
    @changed()
    @updateRendering()
    @changed()
  
  setText: (size) ->
    # for context menu demo purposes
    @text = Math.round(size).toString()
    @changed()
    @updateRendering()
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
    @startMark = null
    @endMark = null
    @changed()
    @updateRendering()
    @changed()
  
  deleteSelection: ->
    text = @text
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    @text = text.slice(0, start) + text.slice(stop)
    @changed()
    @clearSelection()
  
  selectAll: ->
    @startMark = 0
    @endMark = @text.length
    @updateRendering()
    @changed()

  mouseDownLeft: (pos) ->
    if @isEditable
      @clearSelection()
    else
      @escalateEvent "mouseDownLeft", pos

  # Every time the user clicks on the text, a new edit()
  # is triggered, which creates a new caret.
  mouseClickLeft: (pos) ->
    caret = @root().caret;
    if @isEditable
      @edit()  unless @currentlySelecting
      if caret then caret.gotoPos pos
      @root().caret.gotoPos pos
      @currentlySelecting = true
    else
      @escalateEvent "mouseClickLeft", pos
  
  #mouseDoubleClick: ->
  #  alert "mouseDoubleClick!"

  enableSelecting: ->
    @mouseDownLeft = (pos) ->
      @clearSelection()
      if @isEditable and (not @isDraggable)
        @edit()
        @root().caret.gotoPos pos
        @startMark = @slotAt(pos)
        @endMark = @startMark
        @currentlySelecting = true
    
    @mouseMove = (pos) ->
      if @isEditable and @currentlySelecting and (not @isDraggable)
        newMark = @slotAt(pos)
        if newMark isnt @endMark
          @endMark = newMark
          @updateRendering()
          @changed()
  
  disableSelecting: ->
    # re-establish the original definition of the method
    @mouseDownLeft = StringMorph::mouseDownLeft
    delete @mouseMove

# StringMorph /////////////////////////////////////////////////////////

# A StringMorph is a single line of text. It can only be left-aligned.
# REQUIRES WorldMorph
# REQUIRES BackingStoreMixin

class StringMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith BackingStoreMixin

  text: ""
  fontSize: null
  fontName: null
  fontStyle: null
  isBold: null
  isItalic: null
  isEditable: false
  isNumeric: null
  isPassword: false
  isShowingBlanks: false
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  blanksColor: new Color(180, 140, 140)

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
      text = "",
      @fontSize = 12,
      @fontStyle = "sans-serif",
      @isBold = false,
      @isItalic = false,
      @isNumeric = false,
      color,
      fontName
      ) ->
    # additional properties:
    @text = text or ((if (text is "") then "" else "StringMorph"))
    @fontName = fontName or WorldMorph.preferencesAndSettings.globalFontFamily

    super()

    # override inherited properties:
    @color = color or new Color(0, 0, 0)
    @noticesTransparentClick = true

  
  toString: ->
    # e.g. 'a StringMorph("Hello World")'
    firstPart = super()
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.hidingOfMorphsContentExtractInLabels
      return firstPart
    else
      return firstPart + " (\"" + @text.slice(0, 30) + "...\")"

  getTextDescription: ->
    if @textDescription?
      return @textDescription + " (adhoc description of string)"
    textWithoutLocationOrInstanceNo = @text.replace(/\[\d*@\d*[ ]*\|[ ]*\d*@\d*\]/,"")
    textWithoutLocationOrInstanceNo = textWithoutLocationOrInstanceNo.replace(/#\d*/,"")
    return textWithoutLocationOrInstanceNo.slice(0, 30) + " (content of string)"
  
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

  calculateExtentBasedOnText: ->
    text = (if @isPassword then @password("*", @text.length) else @text)
    # initialize my surface property
    measuringCanvas = newCanvas()
    measuringCanvasContext = measuringCanvas.getContext("2d")
    measuringCanvasContext.scale pixelRatio, pixelRatio
    measuringCanvasContext.font = @font()
    measuringCanvasContext.textAlign = "left"
    measuringCanvasContext.textBaseline = "bottom"

    # set my extent based on the size of the text
    return Math.ceil(Math.max(measuringCanvasContext.measureText(text).width, 1))

  setLayoutBeforeUpdatingBackingStore: ->
    super()
    width = @calculateExtentBasedOnText()
    @bounds.corner = @bounds.origin.add(new Point(
      width, fontHeight(@fontSize)))
  
  # no changes of position or extent
  updateBackingStore: ->
    text = (if @isPassword then @password("*", @text.length) else @text)
    # initialize my surface property
    width = @calculateExtentBasedOnText()
    @backBuffer = newCanvas (new Point width, @height()).scaleBy pixelRatio
    @backBufferContext = @backBuffer.getContext("2d")

    # changing the canvas size resets many of
    # the properties of the canvas, so we need to
    # re-initialise the font and alignments here
    @backBufferContext.scale pixelRatio, pixelRatio
    @backBufferContext.font = @font()
    @backBufferContext.textAlign = "left"
    @backBufferContext.textBaseline = "bottom"

    @backBufferContext.fillStyle = @color.toString()
    if @isShowingBlanks
      @renderWithBlanks @backBufferContext, 0, fontHeight(@fontSize)
    else
      @backBufferContext.fillText text, 0, fontHeight(@fontSize)

    # draw the selection
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    for i in [start...stop]
      p = @slotCoordinates(i).subtract(@position())
      c = text.charAt(i)
      @backBufferContext.fillStyle = @markedBackgoundColor.toString()
      @backBufferContext.fillRect p.x, p.y, Math.ceil(@backBufferContext.measureText(c).width) + 1,
        fontHeight(@fontSize)
      @backBufferContext.fillStyle = @markedTextColor.toString()
      @backBufferContext.fillText c, p.x, fontHeight(@fontSize)

    # notify my parent of layout change
    # @parent.layoutSubmorphs()  if @parent.layoutSubmorphs  if @parent
  
  renderWithBlanks: (context, startX, y) ->
    # create the blank form
    drawBlank = ->
      context.drawImage blank, Math.round(x), 0
      x += space
    space = Math.ceil(context.measureText(" ").width)
    blank = newCanvas(new Point(space, @height()).scaleBy pixelRatio)
    ctx = blank.getContext("2d")
    words = @text.split(" ")
    x = startX or 0
    isFirst = true
    ctx.fillStyle = @blanksColor.toString()
    ctx.arc space / 2, blank.height / 2, space / 2, degreesToRadians(0), degreesToRadians(360)
    ctx.fill()

    # render my text inserting blanks
    words.forEach (word) ->
      drawBlank()  unless isFirst
      isFirst = false
      if word isnt ""
        context.fillText word, x, y
        x += Math.ceil(context.measureText(word).width)
  
  
  # StringMorph measuring:
  slotCoordinates: (slot) ->
    # answer the position point of the given index ("slot")
    # where the caret should be placed
    text = (if @isPassword then @password("*", @text.length) else @text)
    dest = Math.min(Math.max(slot, 0), text.length)
    xOffset = Math.ceil(@backBufferContext.measureText(text.substring(0,dest)).width)
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

    while aPoint.x - @left() > charX
      charX += Math.ceil(@backBufferContext.measureText(text[idx]).width)
      idx += 1
      if idx is text.length
        if (Math.ceil(@backBufferContext.measureText(text).width) - (Math.ceil(@backBufferContext.measureText(text[idx - 1]).width) / 2)) < (aPoint.x - @left())  
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
    
  fontSizePopup: (menuItem)->
    @prompt menuItem.parent.title + "\nfont\nsize:",
      @,
      "setFontSize",
      @fontSize.toString(),
      null, 6, 500, true

  # StringMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "edit", true, @, "edit"
    menu.addItem "font size...", true, @, "fontSizePopup", "set this String's\nfont point size"
    menu.addItem "serif", true, @, "setSerif"  if @fontStyle isnt "serif"
    menu.addItem "sans-serif", true, @, "setSansSerif"  if @fontStyle isnt "sans-serif"

    if @isBold
      menu.addItem "normal weight", true, @, "toggleWeight"
    else
      menu.addItem "bold", true, @, "toggleWeight"

    if @isItalic
      menu.addItem "normal style", true, @, "toggleItalic"
    else
      menu.addItem "italic", true, @, "toggleItalic"

    if @isShowingBlanks
      menu.addItem "hide blanks", true, @, "toggleShowBlanks"
    else
      menu.addItem "show blanks", true, @, "toggleShowBlanks"

    if @isPassword
      menu.addItem "show characters", true, @, "toggleIsPassword"
    else
      menu.addItem "hide characters", true, @, "toggleIsPassword"

    menu
  
  toggleIsfloatDraggable: ->
    # for context menu demo purposes
    @isfloatDraggable = not @isfloatDraggable
    if @isfloatDraggable
      @disableSelecting()
    else
      @enableSelecting()
  
  toggleShowBlanks: ->
    @isShowingBlanks = not @isShowingBlanks
    @changed()
    @setLayoutBeforeUpdatingBackingStore()
    @updateBackingStore()
    @changed()
  
  toggleWeight: ->
    @isBold = not @isBold
    @changed()
    @setLayoutBeforeUpdatingBackingStore()
    @updateBackingStore()
    @changed()
  
  toggleItalic: ->
    @isItalic = not @isItalic
    @changed()
    @setLayoutBeforeUpdatingBackingStore()
    @updateBackingStore()
    @changed()
  
  toggleIsPassword: ->
    @isPassword = not @isPassword
    @changed()
    @setLayoutBeforeUpdatingBackingStore()
    @updateBackingStore()
    @changed()
  
  setSerif: ->
    @fontStyle = "serif"
    @changed()
    @setLayoutBeforeUpdatingBackingStore()
    @updateBackingStore()
    @changed()
  
  setSansSerif: ->
    @fontStyle = "sans-serif"
    @changed()
    @setLayoutBeforeUpdatingBackingStore()
    @updateBackingStore()
    @changed()
  
  setFontSize: (sizeOrMorphGivingSize, morphGivingSize) ->
    if morphGivingSize?.getValue?
      size = morphGivingSize.getValue()
    else
      size = sizeOrMorphGivingSize

    # for context menu demo purposes
    if typeof size is "number"
      @fontSize = Math.round(Math.min(Math.max(size, 4), 500))
    else
      newSize = parseFloat(size)
      @fontSize = Math.round(Math.min(Math.max(newSize, 4), 500))  unless isNaN(newSize)
    @changed()
    @setLayoutBeforeUpdatingBackingStore()
    @updateBackingStore()
    @changed()
  
  setText: (size) ->
    # for context menu demo purposes
    @text = Math.round(size).toString()
    @changed()
    @setLayoutBeforeUpdatingBackingStore()
    @updateBackingStore()
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
    @updateBackingStore()
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
    @updateBackingStore()
    @changed()

  mouseDownLeft: (pos) ->
    if @isEditable
      @clearSelection()
    else
      @escalateEvent "mouseDownLeft", pos

  # Every time the user clicks on the text, a new edit()
  # is triggered, which creates a new caret.
  mouseClickLeft: (pos) ->
    super()
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
      if @isEditable and (not @isfloatDraggable)
        @edit()
        @root().caret.gotoPos pos
        @startMark = @slotAt(pos)
        @endMark = @startMark
        @currentlySelecting = true
    
    @mouseMove = (pos) ->
      if @isEditable and @currentlySelecting and (not @isfloatDraggable)
        newMark = @slotAt(pos)
        if newMark isnt @endMark
          @endMark = newMark
          @updateBackingStore()
          @changed()
  
  disableSelecting: ->
    # re-establish the original definition of the method
    @mouseDownLeft = StringMorph::mouseDownLeft
    delete @mouseMove


  
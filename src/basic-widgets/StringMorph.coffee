# A StringMorph is a single line of text. It can only be left-aligned.

class StringMorph extends Widget

  @augmentWith BackBufferMixin

  text: ""
  fontSize: nil
  fontName: nil
  fontStyle: nil
  isBold: nil
  isItalic: nil
  isEditable: false
  isNumeric: nil
  isPassword: false
  isShowingBlanks: false

  blanksColor: new Color 180, 140, 140

  # Properties for text-editing
  isScrollable: true
  currentlySelecting: false
  startMark: nil
  endMark: nil
  # see note above about Colors and shared objects
  markedTextColor: Color.WHITE
  # see note above about Colors and shared objects
  markedBackgoundColor: new Color 60, 60, 120

  constructor: (
      @text = (if text is "" then "" else "StringMorph"),
      @fontSize = 12,
      @fontStyle = "sans-serif",
      @isBold = false,
      @isItalic = false,
      @isNumeric = false,
      @color = Color.BLACK,
      @fontName = ""
      ) ->

    super()

    # override inherited properties:
    @noticesTransparentClick = true

  setText: (theTextContent, stringFieldMorph, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @connectionsCalculationToken = connectionsCalculationToken
    if stringFieldMorph?
      theTextContent = stringFieldMorph.text.text
    theTextContent = theTextContent + ""
    if @text != theTextContent
      @text = theTextContent
      @reLayout()
      
      @changed()

  actualFontSizeUsedInRendering: ->
    @fontSize
  
  toString: ->
    # e.g. 'a StringMorph("Hello World")'
    firstPart = super()
    if Automator? and Automator.state != Automator.IDLE and Automator.hidingOfMorphsContentExtractInLabels
      return firstPart
    else
      return firstPart + " (\"" + @text.slice(0, 30).replace(/(?:\r\n|\r|\n)/g, '↵') + "...\")"

  getTextDescription: ->
    if @textDescription?
      return @textDescription + " (adhoc description of string)"
    textWithoutLocationOrInstanceNo = @text.replace /#\d*/, ""
    return textWithoutLocationOrInstanceNo.slice(0, 30) + " (content of string)"
  
  password: (letter, length) ->
    ans = ""
    for i in [0...length]
      ans += letter
    ans

  buildCanvasFontProperty: ->
    # answer a font string, e.g. 'bold italic 12px sans-serif'
    font = ""
    font = font + "bold "  if @isBold
    font = font + "italic "  if @isItalic
    font + @fontSize + "px " + ((if @fontName then @fontName + ", " else "")) + @fontStyle


  widthOfText: (text = @text)->
    text = (if @isPassword then @password("*", text.length) else text)
    world.canvasContextForTextMeasurements.font = @buildCanvasFontProperty()
    return Math.ceil Math.max world.canvasContextForTextMeasurements.measureText(text).width, 1

  reLayout: ->
    super()
    width = @widthOfText @text
    @silentRawSetExtent new Point width, fontHeight @fontSize
    @notifyChildrenThatParentHasReLayouted()

  reflowText: ->
    @reLayout()
  
  # no changes of position or extent should be
  # performed in here
  createRefreshOrGetBackBuffer: ->

    cacheKey =
      @extent().toString()  + "-" +
      @isPassword  + "-" +
      @isShowingBlanks  + "-" +
      @buildCanvasFontProperty()  + "-" +
      @alignment  + "-" +
      @color.toString()  + "-" +
      hashCode(@text)  + "-" +
      @startMark  + "-" +
      @endMark  + "-" +
      @markedBackgoundColor.toString()

    cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
    if cacheHit? then return cacheHit

    text = (if @isPassword then @password("*", @text.length) else @text)
    # initialize my surface property
    width = @widthOfText @text
    backBuffer = newCanvas (new Point width, @height()).scaleBy ceilPixelRatio
    backBufferContext = backBuffer.getContext "2d"

    backBufferContext.useLogicalPixelsUntilRestore()
    backBufferContext.font = @buildCanvasFontProperty()
    backBufferContext.textAlign = "left"
    backBufferContext.textBaseline = "bottom"

    backBufferContext.fillStyle = @color.toString()
    if @isShowingBlanks
      @renderWithBlanks backBufferContext, 0, fontHeight @fontSize
    else
      backBufferContext.fillText text, 0, fontHeight @fontSize

    # draw the selection
    start = Math.min @startMark, @endMark
    stop = Math.max @startMark, @endMark
    for i in [start...stop]
      p = @slotCoordinates(i).subtract @position()
      c = text.charAt(i)
      backBufferContext.fillStyle = @markedBackgoundColor.toString()
      backBufferContext.fillRect p.x, p.y, Math.ceil(backBufferContext.measureText(c).width) + 1,
        fontHeight @fontSize
      backBufferContext.fillStyle = @markedTextColor.toString()
      backBufferContext.fillText c, p.x, fontHeight @fontSize

    cacheEntry = [backBuffer, backBufferContext]
    world.cacheForImmutableBackBuffers.set cacheKey, cacheEntry
    return cacheEntry
  
  renderWithBlanks: (context, x = 0, y) ->
    # create the blank form
    drawBlank = ->
      context.drawImage blank, Math.round(x), 0
      x += space
    space = Math.ceil context.measureText(" ").width
    blank = newCanvas new Point(space, @height()).scaleBy ceilPixelRatio
    ctx = blank.getContext "2d"
    words = @text.split " "
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
        x += Math.ceil context.measureText(word).width
  
  
  # StringMorph measuring:
  slotCoordinates: (slot) ->
    # answer the position point of the given index ("slot")
    # where the caret should be placed
    text = (if @isPassword then @password("*", @text.length) else @text)

    # let's be defensive and check that the
    # slot is in the right interval
    checkedSlot = Math.min Math.max(slot, 0), text.length
    if slot != checkedSlot
      alert "something wrong - slot is out of range"
    slot = checkedSlot

    xOffset = Math.ceil @widthOfText text.substring 0, slot
    x = @left() + xOffset
    y = @top()
    new Point x, y
  
  slotAt: (aPoint) ->
    # answer the slot (index) closest to the given point
    # so the caret can be moved accordingly
    text = (if @isPassword then @password("*", @text.length) else @text)
    idx = 0
    charX = 0

    while aPoint.x - @left() > charX
      charX += Math.ceil @widthOfText text[idx]
      idx += 1
      if idx is text.length
        if (Math.ceil(@widthOfText(text)) - (Math.ceil(@widthOfText(text[idx-1])) / 2)) < (aPoint.x - @left())  
          return idx
    idx - 1
  
  upFrom: (slot) ->
    @startOfLine()
  
  downFrom: (slot) ->
    @endOfLine()

  startOfLine: ->
    # answer the first slot (index) of the line for the given slot
    0
  
  endOfLine: ->
    # answer the slot (index) indicating the EOL for the given slot
    @text.length
    
  fontSizePopup: (menuItem)->
    @prompt menuItem.parent.title + "\nfont\nsize:",
      @,
      "setFontSize",
      @fontSize.toString(),
      nil, 6, 500, true

  # StringMorph menus:
  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "edit", true, @, "edit"
    menu.addMenuItem "font size...", true, @, "fontSizePopup", "set this String's\nfont point size"
    menu.addMenuItem "serif", true, @, "setSerif"  if @fontStyle isnt "serif"
    menu.addMenuItem "sans-serif", true, @, "setSansSerif"  if @fontStyle isnt "sans-serif"

    if @isBold
      menu.addMenuItem "normal weight", true, @, "toggleWeight"
    else
      menu.addMenuItem "bold", true, @, "toggleWeight"

    if @isItalic
      menu.addMenuItem "normal style", true, @, "toggleItalic"
    else
      menu.addMenuItem "italic", true, @, "toggleItalic"

    if @isShowingBlanks
      menu.addMenuItem "hide blanks", true, @, "toggleShowBlanks"
    else
      menu.addMenuItem "show blanks", true, @, "toggleShowBlanks"

    if @isPassword
      menu.addMenuItem "show characters", true, @, "toggleIsPassword"
    else
      menu.addMenuItem "hide characters", true, @, "toggleIsPassword"

  toggleShowBlanks: ->
    @isShowingBlanks = not @isShowingBlanks
    @reLayout()
    
    @changed()
  
  toggleWeight: ->
    @isBold = not @isBold
    @reLayout()
    
    @changed()
  
  toggleItalic: ->
    @isItalic = not @isItalic
    @reLayout()
    
    @changed()
  
  toggleIsPassword: ->
    @isPassword = not @isPassword
    @reLayout()
    
    @changed()
  
  setSerif: ->
    @fontStyle = "serif"
    @reLayout()
    
    @changed()
  
  setSansSerif: ->
    @fontStyle = "sans-serif"
    @reLayout()
    
    @changed()
  
  setFontSize: (sizeOrMorphGivingSize, morphGivingSize) ->
    if morphGivingSize?.getValue?
      size = morphGivingSize.getValue()
    else
      size = sizeOrMorphGivingSize

    if typeof size is "number"
      @fontSize = Math.round(Math.min(Math.max(size, 4), 500))
    else
      newSize = parseFloat size
      @fontSize = Math.round Math.min Math.max(newSize, 4), 500  unless isNaN newSize
    @reLayout()
    
    @changed()
  
  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "alpha 0-100", "font size", "text"
    functionNamesStrings.push "setAlphaScaled", "setFontSize", "setText"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings
  
  # StringMorph editing:
  edit: ->
    world.edit @

  selection: ->
    start = Math.min @startMark, @endMark
    stop = Math.max @startMark, @endMark
    @text.slice start, stop
  
  firstSelectedSlot: ->
    if !@startMark? or !@endMark?
      return nil
    return Math.min @startMark, @endMark

  lastSelectedSlot: ->
    if !@startMark? or !@endMark?
      return nil
    return Math.max @startMark, @endMark

  clearSelection: ->
    @currentlySelecting = false
    @startMark = nil
    @endMark = nil
    
    @changed()

  setEndMark: (slot) ->
    @endMark = slot
    @changed()
  
  selectBetween: (start, end) ->
    @startMark = Math.min start, end
    @endMark = Math.max start, end
    @changed()  

  deleteSelection: ->
    text = @text
    start = Math.min @startMark, @endMark
    stop = Math.max @startMark, @endMark
    @text = text.slice(0, start) + text.slice(stop)
    
    @changed()
    @clearSelection()
  
  selectAll: ->
    @startMark = 0
    @endMark = @text.length
    
    @changed()

  # Every time the user clicks on the text, a new edit()
  # is triggered, which creates a new caret.
  mouseClickLeft: (pos) ->
    @bringToForeground()
    caret = world.caret
    if @isEditable
      @edit()  unless @currentlySelecting
      if caret then caret.gotoPos pos
      world.caret.gotoPos pos
      @currentlySelecting = true
    else
      @escalateEvent "mouseClickLeft", pos
  
  enableSelecting: ->
    @mouseDownLeft = (pos) ->
      @clearSelection()
      if @isEditable and !@grabsToParentWhenDragged()
        @edit()
        world.caret.gotoPos pos
        @startMark = @slotAt pos
        @endMark = @startMark
        @currentlySelecting = true
    
    @mouseMove = (pos) ->
      if @isEditable and @currentlySelecting
        newMark = @slotAt pos
        if newMark isnt @endMark
          @endMark = newMark
          
          @changed()
      else
        @disableSelecting()
  
  disableSelecting: ->
    # re-establish the original definition of the method
    @clearSelection()
    @mouseDownLeft = StringMorph::mouseDownLeft
    delete @mouseMove


  
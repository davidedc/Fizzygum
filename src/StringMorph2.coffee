# StringMorph2 /////////////////////////////////////////////////////////

# It's a SINGLE line of text, i.e.
# it doesn't represent line breaks as multiple lines.
# It's useful when you mean an "enter" from the user to mean
# "accept the changes", and to represent things that are
# necessarily on one line and one line only such as
# numbers, booleans, method names, file names, colors etc.
# If there is a chance that the text might span more
# than one line (e.g. most button actions) then do
# use a TextMorph instead.
# It's like StringMorph BUT it fits any given size, so to
# behave well in layouts.

# REQUIRES WorldMorph
# REQUIRES BackBufferMixin
# REQUIRES AlignmentSpec
# REQUIRES LRUCache
# REQUIRES FittingSpecTextInSmallerBounds
# REQUIRES FittingSpecTextInLargerBounds

class StringMorph2 extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith BackBufferMixin

  text: ""
  textActuallyShown: ""

  fittingFontSize: null
  originallySetFontSize: null

  fontName: null
  fontStyle: null
  isBold: null
  isItalic: null
  isEditable: false
  # if "isNumeric", it rejects all inputs
  # other than numbers and "-" and "."
  isNumeric: null
  isPassword: false
  isShowingBlanks: false
  # careful: Objects are shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  blanksColor: new Color 180, 140, 140

  # Used for when the cursor movement causes the
  # text to scroll, so that the caret is in-view when
  # used, say, on a text in a scrollMorph.
  isScrollable: true
  startMark: null
  endMark: null
  # see note above about Colors and shared objects
  markedTextColor: new Color 255, 255, 255
  # see note above about Colors and shared objects
  markedBackgoundColor: new Color 60, 60, 120

  horizontalAlignment: AlignmentSpec.LEFT
  verticalAlignment: AlignmentSpec.TOP

  fittingSpecWhenBoundsTooLarge: FittingSpecTextInLargerBounds.FLOAT
  fittingSpecWhenBoundsTooSmall: FittingSpecTextInSmallerBounds.CROP

  caretHorizPositionForVertMovement: null

  constructor: (
      @text = (if text is "" then "" else "StringMorph2"),
      @originallySetFontSize = 12,
      @fontStyle = "sans-serif",
      @isBold = false,
      @isItalic = false,
      @isNumeric = false,
      @color = (new Color 0, 0, 0),
      @fontName = (WorldMorph.preferencesAndSettings.globalFontFamily),
      @backgroundColor = null,
      @backgroundTransparency = null
      ) ->
    # additional properties:
    @textActuallyShown = @text

    super()

    # override inherited properties:
    @noticesTransparentClick = true

  # the actual font size used might be
  # different than the one specified originally
  # because this morph has to be able to fit
  # any extent by shrinking.
  actualFontSizeUsedInRendering: ->
    @fittingFontSize

  setHorizontalAlignment: (newAlignment) ->
    if @horizontalAlignment != newAlignment
      world.stopEditing()
      @horizontalAlignment = newAlignment
      @reLayout()
      @backBufferIsPotentiallyDirty = true
      @changed()

  setVerticalAlignment: (newAlignment) ->
    if @verticalAlignment != newAlignment
      world.stopEditing()
      @verticalAlignment = newAlignment
      @reLayout()
      @backBufferIsPotentiallyDirty = true
      @changed()

  alignLeft: ->
    @setHorizontalAlignment AlignmentSpec.LEFT
  alignCenter: ->
    @setHorizontalAlignment AlignmentSpec.CENTER
  alignRight: ->
    @setHorizontalAlignment AlignmentSpec.RIGHT
  alignTop: ->
    @setVerticalAlignment AlignmentSpec.TOP
  alignMiddle: ->
    @setVerticalAlignment AlignmentSpec.MIDDLE
  alignBottom: ->
    @setVerticalAlignment AlignmentSpec.BOTTOM
  
  toString: ->
    # e.g. 'a StringMorph2("Hello World")'
    firstPart = super()
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and
    AutomatorRecorderAndPlayer.hidingOfMorphsContentExtractInLabels
      return firstPart
    else
      return firstPart + " (\"" + @text.slice(0, 30) + "...\")"

  # used to identify morphs in macros/tests.
  # identifying morphs this way resists more
  # to tampering such as adding/removing morphs and
  # changing their locations.
  getTextDescription: ->
    if @textDescription?
      return @textDescription + " (adhoc description of string)"
    textWithoutLocationOrInstanceNo = @text.replace /\[\d*@\d*[ ]*\|[ ]*\d*@\d*\]/, ""
    textWithoutLocationOrInstanceNo = textWithoutLocationOrInstanceNo.replace /#\d*/, ""
    return textWithoutLocationOrInstanceNo.slice(0, 30) + " (content of string)"
  
  password: (letter, length) ->
    # there is an alternative to this, using an idiom
    # http://stackoverflow.com/a/19892144
    # but it's clearer this way
    ans = ""
    for i in [0...length]
      ans += letter
    ans

  buildCanvasFontProperty: (overrideFontSize = @fittingFontSize) ->
    # answer a font string, e.g. 'bold italic 12px sans-serif'
    font = ""
    font = font + "bold "  if @isBold
    font = font + "italic "  if @isItalic
    font + overrideFontSize + "px " + ((if @fontName then @fontName + ", " else "")) + @fontStyle

  # does a binary search to see which font size
  # we need to apply to the text to fit to the
  # current extent.
  # If this gets slow: some optimisations can be done,
  # for example trying to make a couple of preliminary guesses
  # assuming that the user is just resizing something slightly,
  # which means that the font size is gonna change only slightly
  # from the current one, so you can try to narrow the bracket
  # a lot at the very start.
  searchLargestFittingFont: (fittingTestFunction, textToFit) ->
    # decimalFloatFiguresOfFontSizeGranularity allows you to go into sub-points
    # in the font size. This is so the resizing of the
    # text is less "jumpy".
    # "1" seems to be perfect in terms of jumpiness,
    # but obviously this routine gets quite a bit more
    # expensive.
    PreferencesAndSettings.decimalFloatFiguresOfFontSizeGranularity = 0

    start = 0    # minimum font size that we are gonna examine
    stop  = Math.round 200 * Math.pow 10, PreferencesAndSettings.decimalFloatFiguresOfFontSizeGranularity  # maximum font size that we are gonna examine
    
    if !fittingTestFunction textToFit, start
       return -1

    if fittingTestFunction textToFit, stop
       return stop / Math.pow 10, PreferencesAndSettings.decimalFloatFiguresOfFontSizeGranularity

    # since we round the pivot to the floor, we
    # always end up start and pivot coinciding
    while start != (pivot = Math.floor (start + stop) / 2)

      itFitsAtPivot = fittingTestFunction textToFit, pivot / Math.pow 10, PreferencesAndSettings.decimalFloatFiguresOfFontSizeGranularity

      if itFitsAtPivot
        # bring forward the start since there are still
        # zeroes at the pivot
        start = pivot
      else
        # bring backwards the stop since there is already
        # a one at the pivot
        stop = pivot

    start / Math.pow 10, PreferencesAndSettings.decimalFloatFiguresOfFontSizeGranularity

  generateTextWithEllipsis: (startingText) ->
    if startingText != ""
      return startingText + "…"
    return ""

  # see comment above for "searchLargestFittingFont" for some
  # ideas on how to optimise this further.
  searchLongestFittingText: (fittingTestFunction, textToFit) ->
    start = 0    # minimum string length that we are gonna examine
    stop  = @generateTextWithEllipsis(@text).length
    
    if fittingTestFunction(@text, @originallySetFontSize)
       return @text

    # since we round the pivot to the floor, we
    # always end up start and pivot coinciding
    while start != (pivot = Math.floor (start + stop) / 2)

      textAtPivot = @generateTextWithEllipsis @text.substring 0, pivot
      itFitsAtPivot = fittingTestFunction textAtPivot, @originallySetFontSize
      #console.log "  what fits: " + textAtPivot + " fits: " + valueAtPivot

      if itFitsAtPivot
        # bring forward the start since there are still
        # zeroes at the pivot
        start = pivot
      else
        # bring backwards the stop since there is already
        # a one at the pivot
        stop = pivot

    fittingText = @generateTextWithEllipsis @text.substring 0, start
    #console.log "what fits: " + fittingText
    if start == 0
      if fittingTestFunction "…", @originallySetFontSize
        return "…"
      else
        return ""
    else
      return fittingText

  synchroniseTextAndActualText: ->

    if @doesTextFitInExtent @text, @originallySetFontSize
      @textActuallyShown = @text
      #console.log "@textActuallyShown = @text 1"
    else
      if @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.SCALEDOWN
        @textActuallyShown = @text
        #console.log "@textActuallyShown = @text 2"


  # there are many factors beyond the font size that affect
  # the measuring, such as font style, but we only pass
  # the font size here because is the one we are going to
  # change when we do the binary search for trying to
  # see the largest fitting size.
  measureText: (overrideFontSize = @fittingFontSize, text) ->
    cacheKey =  @buildCanvasFontProperty(overrideFontSize) + "-" + hashCode text
    cacheHit = world.cacheForTextMeasurements.get cacheKey
    if cacheHit? then return cacheHit
    world.canvasContextForTextMeasurements.font = @buildCanvasFontProperty overrideFontSize
    cacheEntry = world.canvasContextForTextMeasurements.measureText(text).width
    world.cacheForTextMeasurements.set cacheKey, cacheEntry
    #if cacheHit?
    #  if cacheHit != cacheEntry
    #    alert "problem with cache on: " + overrideFontSize + "-" + text + " hit is: " + cacheHit + " should be: " + cacheEntry
    return cacheEntry

  # notice the thick arrow here!
  # there are many factors beyond the font size that affect
  # the measuring, such as font style, but we only pass
  # the font size here because is the one we are going to
  # change when we do the binary search for trying to
  # see the largest fitting size.
  doesTextFitInExtent: (text = @text, overrideFontSize) =>
    text = (if @isPassword then @password("*", text.length) else text)

    extentOccupiedByText = new Point Math.ceil(@measureText overrideFontSize, text), fontHeight(overrideFontSize)

    return extentOccupiedByText.le @extent()

  fitToExtent: ->
    # this if is just to check if the text fits in the
    # current extent. If it does, we either leave the size
    # as is or we try to
    # make the font size bigger if that's the policy.
    # If it doesn't fit, then we either crop it or make the
    # font smaller.
    if @doesTextFitInExtent @text, @originallySetFontSize
      @textActuallyShown = @text
      #console.log "@textActuallyShown = @text 3"
      if @fittingSpecWhenBoundsTooLarge == FittingSpecTextInLargerBounds.SCALEUP
        largestFittingFontSize = @searchLargestFittingFont @doesTextFitInExtent, @text
        return largestFittingFontSize
      else
        return @originallySetFontSize
    else
      if @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.CROP
        @textActuallyShown = @searchLongestFittingText @doesTextFitInExtent, @text
        return @originallySetFontSize
      else
        @textActuallyShown = @text
        #console.log "@textActuallyShown = @text 4"
        largestFittingFontSize = @searchLargestFittingFont @doesTextFitInExtent, @text
        return largestFittingFontSize

  widthOfText: (text, overrideFontSize) ->
    text = (if @isPassword then @password("*", text.length) else text)
    return @measureText overrideFontSize, text

  reLayout: ->
    super()
    @fittingFontSize = @fitToExtent()
    #console.log "reLayout // fittingFontSize: " + @fittingFontSize

  repaintBackBufferIfNeeded: ->

    if !@backBufferIsPotentiallyDirty then return
    @backBufferIsPotentiallyDirty = false

    if @backBufferValidityChecker?
      if @backBufferValidityChecker.extent == @extent().toString() and
      @backBufferValidityChecker.isPassword == @isPassword and
      @backBufferValidityChecker.isShowingBlanks == @isShowingBlanks and
      @backBufferValidityChecker.canvasFontProperty == @buildCanvasFontProperty() and
      @backBufferValidityChecker.color == @color.toString() and
      @backBufferValidityChecker.textHash == hashCode(@text) and
      @backBufferValidityChecker.textActuallyShownHash == hashCode(@textActuallyShown) and
      @backBufferValidityChecker.startMark == @startMark and
      @backBufferValidityChecker.endMark == @endMark and
      @backBufferValidityChecker.markedBackgoundColor == @markedBackgoundColor.toString() and
      @backBufferValidityChecker.horizontalAlignment == @horizontalAlignment and
      @backBufferValidityChecker.verticalAlignment == @verticalAlignment and
      @backBufferValidityChecker.fittingSpecWhenBoundsTooLarge == @fittingSpecWhenBoundsTooLarge and
      @backBufferValidityChecker.fittingSpecWhenBoundsTooSmall == @fittingSpecWhenBoundsTooSmall
        return

    @synchroniseTextAndActualText()
    text = (if @isPassword then @password("*", @textActuallyShown.length) else @textActuallyShown)
    # Initialize my surface property.
    # If don't have to paint the background then the surface is just as
    # big as the text - which is likely to be smaller than the whole morph
    # (because it needs to fit in both height and width, it's likely that
    # it's gonna be smaller in one of the two dimensions).
    # If, on the other hand, we have to paint the background then the surface is
    # as big as the whole morph,
    # so potentially we could be wasting some space as the string might
    # be really small so to fit, say, the width, while a lot of height of
    # the morph could be "wasted" in memory.
    # This could be optimised but it's unclear if it's worth it.
    widthOfText = @widthOfText @textActuallyShown
    if @backgroundColor? or
    @verticalAlignment != AlignmentSpec.TOP or
    @horizontalAlignment != AlignmentSpec.LEFT or
    @fittingSpecWhenBoundsTooLarge == FittingSpecTextInLargerBounds.FLOAT
      width = @width()
      height = @height()
    else
      width = widthOfText
      height = fontHeight @fittingFontSize
    @backBuffer = newCanvas (new Point width, height).scaleBy pixelRatio

    @backBufferContext = @backBuffer.getContext "2d"

    @backBufferContext.scale pixelRatio, pixelRatio
    @backBufferContext.font = @buildCanvasFontProperty()
    @backBufferContext.textAlign = "left"
    @backBufferContext.textBaseline = "bottom"

    # paint the background so we have a better sense of
    # where the text is fitting into.
    if @backgroundColor?
      @backBufferContext.save()
      @backBufferContext.fillStyle = @backgroundColor.toString()
      if @backgroundTransparency?
        @backBufferContext.globalAlpha = @backgroundTransparency
      @backBufferContext.fillRect  0,0, width * pixelRatio, height * pixelRatio
      @backBufferContext.restore()

    if @verticalAlignment == AlignmentSpec.TOP
      textVerticalPosition = fontHeight @fittingFontSize
    else if @verticalAlignment == AlignmentSpec.MIDDLE
      textVerticalPosition = @height()/2 + fontHeight(@fittingFontSize)/2
    else if @verticalAlignment == AlignmentSpec.BOTTOM
      textVerticalPosition = @height()

    if @horizontalAlignment == AlignmentSpec.LEFT
      textHorizontalPosition = 0
    else if @horizontalAlignment == AlignmentSpec.CENTER
      textHorizontalPosition = @width()/2 - widthOfText/2
    else if @horizontalAlignment == AlignmentSpec.RIGHT
      textHorizontalPosition = @width() - widthOfText


    @backBufferContext.fillStyle = @color.toString()
    @backBufferContext.fillText text, textHorizontalPosition, textVerticalPosition

    # draw the selection
    start = Math.min @startMark, @endMark
    stop = Math.max @startMark, @endMark
    for i in [start...stop]
      p = @slotCoordinates(i).subtract @position()
      if p?
        c = text.charAt(i)
        @backBufferContext.fillStyle = @markedBackgoundColor.toString()
        
        @backBufferContext.fillRect p.x, textVerticalPosition - fontHeight(@fittingFontSize), Math.ceil((@measureText @fittingFontSize, c)) + 1,
          fontHeight(@fittingFontSize)
        @backBufferContext.fillStyle = @markedTextColor.toString()
        @backBufferContext.fillText c, p.x, textVerticalPosition

    if world.caret?
      world.caret.updateCaretDimension()

    @backBufferValidityChecker = new BackBufferValidityChecker()
    @backBufferValidityChecker.extent = @extent().toString()
    @backBufferValidityChecker.isPassword = @isPassword
    @backBufferValidityChecker.isShowingBlanks = @isShowingBlanks
    @backBufferValidityChecker.canvasFontProperty = @buildCanvasFontProperty()
    @backBufferValidityChecker.color = @color.toString()
    @backBufferValidityChecker.textHash = hashCode @text
    @backBufferValidityChecker.textActuallyShownHash = hashCode @textActuallyShown
    @backBufferValidityChecker.startMark = @startMark
    @backBufferValidityChecker.endMark = @endMark
    @backBufferValidityChecker.markedBackgoundColor = @markedBackgoundColor.toString()
    @backBufferValidityChecker.horizontalAlignment = @horizontalAlignment
    @backBufferValidityChecker.verticalAlignment = @verticalAlignment
    @backBufferValidityChecker.fittingSpecWhenBoundsTooLarge = @fittingSpecWhenBoundsTooLarge
    @backBufferValidityChecker.fittingSpecWhenBoundsTooSmall = @fittingSpecWhenBoundsTooSmall
    # notify my parent of layout change
    # @parent.layoutSubmorphs()  if @parent.layoutSubmorphs  if @parent
    
  
  # StringMorph2 measuring:
  slotCoordinates: (slot) ->
    
    # this makes it so when you type and the string becomes too big
    # then the edit stops to be directly in the screen and the
    # popout for editing takes over.
    if @text != @textActuallyShown and @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.CROP
      world.stopEditing()
      @edit()
      return null

    # answer the position point of the given index ("slot")
    # where the caret should be placed
    text = (if @isPassword then @password("*", @textActuallyShown.length) else @textActuallyShown)
    dest = Math.min Math.max(slot, 0), text.length

    xOffset = Math.ceil @widthOfText text.substring 0, dest
    @pos = dest
    x = @left() + xOffset
    y = @top()

    widthOfText = @widthOfText @textActuallyShown
    if @verticalAlignment == AlignmentSpec.TOP
      textVerticalPosition = fontHeight @fittingFontSize
    else if @verticalAlignment == AlignmentSpec.MIDDLE
      textVerticalPosition = @height()/2 + fontHeight(@fittingFontSize)/2
    else if @verticalAlignment == AlignmentSpec.BOTTOM
      textVerticalPosition = @height()

    if @horizontalAlignment == AlignmentSpec.LEFT
      textHorizontalPosition = 0
    else if @horizontalAlignment == AlignmentSpec.CENTER
      textHorizontalPosition = @width()/2 - widthOfText/2
    else if @horizontalAlignment == AlignmentSpec.RIGHT
      textHorizontalPosition = @width() - widthOfText

    x += textHorizontalPosition
    y += textVerticalPosition - fontHeight @fittingFontSize

    new Point x, y

  slotAtReduced: (xPosition, text) ->

    widthOfText = @widthOfText text

    if @horizontalAlignment == AlignmentSpec.LEFT
      textHorizontalPosition = 0
    else if @horizontalAlignment == AlignmentSpec.CENTER
      textHorizontalPosition = @width()/2 - widthOfText/2
    else if @horizontalAlignment == AlignmentSpec.RIGHT
      textHorizontalPosition = @width() - widthOfText

    xPosition = xPosition - textHorizontalPosition
    if xPosition - @left() >= widthOfText
      if text[text.length - 1] == '\u2063'
        return text.length - 1
      else
        return text.length

    # answer the slot (index) closest to the given point
    # so the caret can be moved accordingly
    idx = 0
    charX = 0

    # This code to pick the correct slot works but it's
    # way too convoluted, as I arrived to this
    # tweaking it by trial and error rather than by smarts.
    # TODO Probably need a little patience to rewrite, I got
    # other parts to move on to now.
    while true
      if charX > xPosition - @left()
        console.log "xPosition - @left(): " + (xPosition - @left()) + " charXMinusOne " + charXMinusOne + "  charX " + charX 
        console.log "Math.abs(xPosition - @left() - charXMinusOne) " + Math.abs(xPosition - @left() - charXMinusOne) + "  Math.abs(xPosition - @left() - charX) " + Math.abs(xPosition - @left() - charX) 
        if Math.abs(xPosition - @left() - charXMinusOne) < Math.abs(xPosition - @left() - charX)
          return idx - 1
        break

      if charX?
        charXMinusOne = charX
      else
        charXMinusOne = 0

      charX += @widthOfText text[idx]

      idx += 1
      if idx is text.length
        if ((@widthOfText(text)) - ((@widthOfText(text[idx-1])) / 2)) < (xPosition - @left())  
          return idx
    idx
  
  slotAt: (aPoint) ->

    if @verticalAlignment == AlignmentSpec.TOP
      textVerticalPosition = fontHeight @fittingFontSize
    else if @verticalAlignment == AlignmentSpec.MIDDLE
      textVerticalPosition = @height()/2 + fontHeight(@fittingFontSize)/2
    else if @verticalAlignment == AlignmentSpec.BOTTOM
      textVerticalPosition = @height()

    text = (if @isPassword then @password("*", @textActuallyShown.length) else @textActuallyShown)

    # if pointer is below the line, the slot is at
    # the last character.
    if (aPoint.y - textVerticalPosition) - @top() > Math.ceil fontHeight @fittingFontSize
      return text.length

    return @slotAtReduced aPoint.x, text
  
  upFrom: (slot) ->
    @startOfLine()
  
  downFrom: (slot) ->
    @endOfLine()
  
  startOfLine: ->
    # answer the first slot (index) of the line for the given slot
    0
  
  endOfLine: ->
    # answer the slot (index) indicating the EOL for the given slot
    @textActuallyShown.length

  fontSizePopup: (menuItem)->
    @prompt menuItem.parent.title + "\nfont\nsize:",
      @,
      "setFontSize",
      @originallySetFontSize.toString(),
      null, 6, 500, true

  editPopup: (menuItem)->
    if menuItem?
      title = menuItem.parent.title + "\nedit:"
    else
      title = "edit:"

    @prompt title,
      @,
      "setContent",
      @text,
      null, 6, null, true


  # StringMorph2 menus:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "edit...", true, @, "editPopup", "set this String's\ncontent"
    menu.addItem "font size...", true, @, "fontSizePopup", "set this String's\nfont point size"

    if @fontStyle is "serif"
      menu.addItem "sans-serif", true, @, "setSansSerif"  if @fontStyle isnt "sans-serif"
    else
      menu.addItem "serif", true, @, "setSerif" 

    if @isBold
      menu.addItem "normal weight", true, @, "toggleWeight"
    else
      menu.addItem "bold", true, @, "toggleWeight"

    if @isItalic
      menu.addItem "non-italic", true, @, "toggleItalic"
    else
      menu.addItem "italic", true, @, "toggleItalic"

    if @isPassword
      menu.addItem "show characters", true, @, "toggleIsPassword"
    else
      menu.addItem "hide characters", true, @, "toggleIsPassword"

    menu.addLine()
    if @horizontalAlignment != AlignmentSpec.LEFT
      menu.addItem "← align left", true, @, "alignLeft"
    if @horizontalAlignment != AlignmentSpec.CENTER
      menu.addItem "∸ align center", true, @, "alignCenter"
    if @horizontalAlignment != AlignmentSpec.RIGHT
      menu.addItem "→ align right", true, @, "alignRight"

    menu.addLine()
    if @verticalAlignment != AlignmentSpec.TOP
      menu.addItem "↑ align top", true, @, "alignTop"
    if @verticalAlignment != AlignmentSpec.MIDDLE
      menu.addItem "⍿ align middle", true, @, "alignMiddle"
    if @verticalAlignment != AlignmentSpec.BOTTOM
      menu.addItem "↓ align bottom", true, @, "alignBottom"

    menu.addLine()

    if @fittingSpecWhenBoundsTooLarge == FittingSpecTextInLargerBounds.SCALEUP
      menu.addItem "←☓→ don't expand to fill", true, @, "togglefittingSpecWhenBoundsTooLarge"
    else
      menu.addItem "←→ expand to fill", true, @, "togglefittingSpecWhenBoundsTooLarge"

    if @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.CROP
      menu.addItem "→← shrink to fit", true, @, "togglefittingSpecWhenBoundsTooSmall"
    else
      menu.addItem "→⋯← crop to fit", true, @, "togglefittingSpecWhenBoundsTooSmall"

    menu

  togglefittingSpecWhenBoundsTooSmall: ->
    @fittingSpecWhenBoundsTooSmall = not @fittingSpecWhenBoundsTooSmall
    @synchroniseTextAndActualText()
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()
    world.stopEditing()

  togglefittingSpecWhenBoundsTooLarge: ->
    world.stopEditing()
    @fittingSpecWhenBoundsTooLarge = not @fittingSpecWhenBoundsTooLarge
    @synchroniseTextAndActualText()
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()

  toggleIsfloatDraggable: ->
  #  # for context menu demo purposes
  #  @isfloatDraggable = not @isfloatDraggable
  #  if @isfloatDraggable
  #    @disableSelecting()
  #  else
  #    @enableSelecting()
  
  toggleShowBlanks: ->
    @isShowingBlanks = not @isShowingBlanks
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()
  
  toggleWeight: ->
    @isBold = not @isBold
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()
  
  toggleItalic: ->
    @isItalic = not @isItalic
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()
  
  toggleIsPassword: ->
    @isPassword = not @isPassword
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()
  
  setSerif: ->
    @fontStyle = "serif"
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()
  
  setSansSerif: ->
    @fontStyle = "sans-serif"
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()

  reflowText: ->

  setContent: (theTextContent,a) ->
    if a?
      theTextContent = a.text.text


    @text = theTextContent
    if @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.SCALEDOWN or
    @doesTextFitInExtent @text, @originallySetFontSize
      console.log "texts synched at font size: " + @fittingFontSize
      @textActuallyShown = @text
      #console.log "@textActuallyShown = @text 5"
    else
      console.log "texts non-synched"
    @reLayout()
    @reflowText()
    @backBufferIsPotentiallyDirty = true
    @changed()
  
  setFontSize: (sizeOrMorphGivingSize, morphGivingSize) ->
    if morphGivingSize?.getValue?
      size = morphGivingSize.getValue()
    else
      size = sizeOrMorphGivingSize

    # for context menu demo purposes
    if typeof size is "number"
      @originallySetFontSize = Math.round Math.min Math.max(size, 4), 500
    else
      newSize = parseFloat size
      @originallySetFontSize = Math.round Math.min Math.max(newSize, 4), 500  unless isNaN newSize
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()
  
  # TODO this is invoked when for example you take a slider
  # and set it to target a TextMorph.
  # this is rather strange but I see why in case
  # of a Number you might want to show this in a more
  # compact form. This would have to be handled
  # in a different way though, "setText"'s obvious
  # meaning is very different from this...
  setText: (size) ->
    alert "this is strange"
    # for context menu demo purposes
    @text = Math.round(size).toString()
    @textActuallyShown = @text
    #console.log "@textActuallyShown = @text 6"
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()
  
  numericalSetters: ->
    # for context menu demo purposes
    ["fullRawMoveLeftSideTo", "fullRawMoveTopSideTo", "setAlphaScaled", "setFontSize", "setText"]
  
  
  # StringMorph2 editing:
  edit: ->
    if @textActuallyShown == @text
      world.edit @

      # when you edit a TextMorph, potentially
      # you need to change the alignment of the
      # text, because managing the caret with
      # alignments other than the top-left
      # ones is complex. So during editing
      # we might change the alignment, hence
      # these two lines to repaint things.
      @backBufferIsPotentiallyDirty = true
      @changed()

      return true
    else
      @editPopup()
      return null

  selection: ->
    start = Math.min @startMark, @endMark
    stop = Math.max @startMark, @endMark
    @textActuallyShown.slice start, stop
  
  selectionStartSlot: ->
    if !@startMark? or !@endMark?
      return null
    return Math.min @startMark, @endMark

  selectionEndSlot: ->
    if !@startMark? or !@endMark?
      return null
    return Math.max @startMark, @endMark

  currentlySelecting: ->
    if !@startMark? and !@endMark?
     return false
    return true
  
  clearSelection: ->
    @startMark = null
    @endMark = null
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()
  
  deleteSelection: ->
    text = @text
    start = Math.min @startMark, @endMark
    stop = Math.max @startMark, @endMark
    @text = text.slice(0, start) + text.slice(stop)
    @textActuallyShown = @text
    #console.log "@textActuallyShown = @text 6"
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()
    @clearSelection()
    @reflowText()

  selectAll: ->
    @startMark = 0
    @endMark = @textActuallyShown.length
    @backBufferIsPotentiallyDirty = true
    @changed()

  # used when shift-clicking somewhere when there is
  # no selection ongoing
  startSelectionUpToSlot: (previousCaretSlot, slotToExtendTo) ->
    @startMark = previousCaretSlot
    @endMark = slotToExtendTo
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()

  # used when shift-clicking somewhere when there is
  # already a selection ongoing
  extendSelectionUpToSlot: (slotToExtendTo) ->
    @endMark = slotToExtendTo
    @reLayout()
    @backBufferIsPotentiallyDirty = true
    @changed()

  # Every time the user clicks on the text, a new edit()
  # is triggered, which creates a new caret.
  mouseClickLeft: (pos, ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey) ->
    @bringToForegroud()
    world.caret?.bringToForegroud()
    if @isEditable
      # doesn't matter what we set editResult to initially,
      # just not undefined or null cause that's
      # going to be significant
      editResult = true
      previousCaretSlot = world.caret?.slot
      if !@currentlySelecting()
        editResult = @edit()
      slotUserClickedOn = @slotAt pos

      if shiftKey
        if @currentlySelecting()
          @extendSelectionUpToSlot slotUserClickedOn
        else
          if previousCaretSlot?
            @startSelectionUpToSlot previousCaretSlot, slotUserClickedOn
      else
        @clearSelection()

      if editResult?
        world.caret.gotoSlot slotUserClickedOn
        world.caret.show()
        @caretHorizPositionForVertMovement = world.caret.left()

    else
      @escalateEvent "mouseClickLeft", pos
  
  enableSelecting: ->
    @mouseDownLeft = (pos) ->
      @clearSelection()
      if @isEditable and !@isFloatDraggable()
        @edit()
        world.caret.gotoPos pos
        @startMark = @slotAt pos
        @endMark = @startMark
    
    @mouseMove = (pos) ->
      if @isEditable and @currentlySelecting()
        newMark = @slotAt pos
        if newMark isnt @endMark
          @endMark = newMark
          
          @changed()
      else
        @disableSelecting()
  
  disableSelecting: ->
    # re-establish the original definition of the method
    @clearSelection()
    @mouseDownLeft = StringMorph2::mouseDownLeft
    delete @mouseMove


  
# It's a SINGLE line of text, i.e.
# it doesn't represent line breaks as multiple lines
# and there is no concept of soft-wrapping.
# It's useful when you mean an "enter" from the user to mean
# "accept the changes", and to represent things that are
# necessarily on one line and one line only such as
# numbers, booleans, method and property names, file names,
# colors, passwords etc.
# If there is a chance that the text might span more
# than one line (e.g. most button captions) then do
# use a TextMorph instead.
# It's like StringMorph BUT it fits any given size, so to
# behave well in layouts.
#
# REQUIRES WorldMorph
# REQUIRES BackBufferMixin
# REQUIRES ControllerMixin
# REQUIRES AlignmentSpecHorizontal
# REQUIRES AlignmentSpecVertical
# REQUIRES LRUCache
# REQUIRES FittingSpecTextInSmallerBounds
# REQUIRES FittingSpecTextInLargerBounds
# REQUIRES TextEditingState

class StringMorph2 extends Widget

  @augmentWith BackBufferMixin
  @augmentWith ControllerMixin

  # clear unadulterated text
  text: ""
  # the text as it actually shows.
  # It might have undergone transformations
  # and cropping.
  textPossiblyCroppedToFit: ""

  fittingFontSize: nil
  originallySetFontSize: nil

  fontName: nil
  isBold: nil
  isItalic: nil
  # TODO there is no API to toggle this properly yet,
  # TODO?? ...and there is no menu entry for this
  # TODO???? ...should we let users pick any color?
  hasDarkOutline: false
  isHeaderLine: nil
  isEditable: false
  # if "isNumeric", it rejects all inputs
  # other than numbers and "-" and "."
  isNumeric: nil
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
  # used, say, on a text in a ScrollPanelWdgt.
  isScrollable: true

  # startMark and endMark contain the slot of the
  # slot first selected IN TIME, not "in space".
  # i.e. startMark might be higher than endMark if
  # text had been selected starting from the
  # right and "going left"
  startMark: nil
  endMark: nil

  # see note above about Colors and shared objects
  markedTextColor: new Color 255, 255, 255
  # see note above about Colors and shared objects
  markedBackgoundColor: new Color 60, 60, 120

  horizontalAlignment: AlignmentSpecHorizontal.LEFT
  verticalAlignment: AlignmentSpecVertical.TOP

  fittingSpecWhenBoundsTooLarge: FittingSpecTextInLargerBounds.FLOAT
  fittingSpecWhenBoundsTooSmall: FittingSpecTextInSmallerBounds.CROP

  caretHorizPositionForVertMovement: nil

  emptyCharacter: '\u2063'

  # Since we let the browser paint the text, we can't guarantee that
  # a specific font will be available to the user.
  # So we do what web designers do: we allow for a few families of
  # very simialar fonts (at least in style in not in shape),
  # each specifying a list of fallbacks that
  # are chosen to be similar and, collectively, widely available.
  # On top of that we also add a justArialFontStack, since Arial
  # is actually available on all devices, it's useful for testing
  # to have a font that is supposed to be identical across all
  # devices.
  # These stacks have been taken from
  # http://www.sitepoint.com/eight-definitive-font-stacks/
  justArialFontStack: 'Arial, sans-serif'
  timesFontStack: 'Cambria, "Hoefler Text", Utopia, "Liberation Serif", "Nimbus Roman No9 L Regular", Times, "Times New Roman", serif'
  georgiaFontStack: 'Constantia, "Lucida Bright", Lucidabright, "Lucida Serif", Lucida, "DejaVu Serif", "Bitstream Vera Serif", "Liberation Serif", Georgia, serif'
  garamoFontStack: '"Palatino Linotype", Palatino, Palladio, "URW Palladio L", "Book Antiqua", Baskerville, "Bookman Old Style", "Bitstream Charter", "Nimbus Roman No9 L", Garamond, "Apple Garamond", "ITC Garamond Narrow", "New Century Schoolbook", "Century Schoolbook", "Century Schoolbook L", Georgia, serif'
  helveFontStack: 'Frutiger, "Frutiger Linotype", Univers, Calibri, "Gill Sans", "Gill Sans MT", "Myriad Pro", Myriad, "DejaVu Sans Condensed", "Liberation Sans", "Nimbus Sans L", Tahoma, Geneva, "Helvetica Neue", Helvetica, Arial, sans-serif'
  verdaFontStack: 'Corbel, "Lucida Grande", "Lucida Sans Unicode", "Lucida Sans", "DejaVu Sans", "Bitstream Vera Sans", "Liberation Sans", Verdana, "Verdana Ref", sans-serif'
  trebuFontStack: '"Segoe UI", Candara, "Bitstream Vera Sans", "DejaVu Sans", "Bitstream Vera Sans", "Trebuchet MS", Verdana, "Verdana Ref", sans-serif'
  heavyFontStack: 'Impact, Haettenschweiler, "Franklin Gothic Bold", Charcoal, "Helvetica Inserat", "Bitstream Vera Sans Bold", "Arial Black", sans-serif'
  monoFontStack: 'Consolas, "Andale Mono WT", "Andale Mono", "Lucida Console", "Lucida Sans Typewriter", "DejaVu Sans Mono", "Bitstream Vera Sans Mono", "Liberation Mono", "Nimbus Mono L", Monaco, "Courier New", Courier, monospace'

  hashOfTextConsideredAsReference: nil
  widgetToBeNotifiedOfTextModificationChange: nil

  undoHistory: nil
  redoHistory: nil

  constructor: (
      @text = (if text is "" then "" else "StringMorph2"),
      @originallySetFontSize = WorldMorph.preferencesAndSettings.normalTextFontSize,
      @fontName = @justArialFontStack,
      @isBold = false,
      @isItalic = false,
      @isHeaderLine = false,
      @isNumeric = false,
      @color = (new Color 37, 37, 37),
      backgroundColor,
      backgroundTransparency
      ) ->
    # additional properties:
    @textPossiblyCroppedToFit = @transformTextOneToOne @text

    # properties that override existing ones only when passed
    @backgroundColor = backgroundColor if backgroundColor?
    @backgroundTransparency = backgroundTransparency if backgroundTransparency?      

    @undoHistory = []
    @redoHistory = []

    super()

    # override inherited properties:
    @noticesTransparentClick = true
    @changed()

  # the actual font size used might be
  # different than the one specified originally
  # because this morph has to be able to fit
  # any extent by shrinking.
  actualFontSizeUsedInRendering: ->
    @reflowText()
    @fittingFontSize

  pushUndoState: (slot, justFirstClickToPositionCursor) ->

    # Little definition here: a "positional" change
    # are pairs of states that only differ for the
    # position.

    # Since we push a:
    #                  position, text
    #
    # pair for each insert (see comment in "insert" for why)
    # we want to actually forget the "trivial" positional
    # changes when the user is just typing, so discard the
    # positional changes of one
    if @undoHistory.length > 0
      lastUndoState = @undoHistory[@undoHistory.length - 1]
      if lastUndoState.selectionStart == @startMark and
       lastUndoState.selectionEnd == @endMark and
       lastUndoState.textContent == @text and
       Math.abs(slot - lastUndoState.cursorPos) <= 1
        return

    # when the user clicks around, we never want to
    # store three consecutive non-trivial positional
    # changes. We just want two: the initial and the last
    # one. So check the last two pushes, and if they are
    # positional then we discard the second one, then we are going
    # to add the new one after this check.
    # All this is because it's much *much* more natural
    # for the user to undo up to the position BEFORE an
    # edit. If you don't save that position before the
    # edit, you jump directly to the end of the edit before,
    # it's actually quite puzzling.
    # It's nominally "functional" to only jump to text changes,
    # but it's quite unnatural, it's not how undos work
    # in real editors.
    if @undoHistory.length > 1
      lastUndoState = @undoHistory[@undoHistory.length - 1]
      beforeLastUndoState = @undoHistory[@undoHistory.length - 2]
      if beforeLastUndoState.selectionStart == lastUndoState.selectionStart == @startMark and
       beforeLastUndoState.selectionEnd == lastUndoState.selectionEnd == @endMark and
       beforeLastUndoState.textContent == lastUndoState.textContent == @text
        @undoHistory.pop()


    @redoHistory = []

    @undoHistory.push new TextEditingState @startMark, @endMark, slot, @text, justFirstClickToPositionCursor

  popRedoState: (slot) ->
    poppedElement = @redoHistory.pop()
    if poppedElement?
      @undoHistory.push poppedElement
    return poppedElement

  popUndoState: ->
    poppedElement = @undoHistory.pop()
    if poppedElement?
      @redoHistory.push poppedElement
    return poppedElement

  setHorizontalAlignment: (newAlignment) ->
    if @horizontalAlignment != newAlignment
      @horizontalAlignment = newAlignment
      @changed()

  setVerticalAlignment: (newAlignment) ->
    if @verticalAlignment != newAlignment
      @verticalAlignment = newAlignment
      @changed()

  alignLeft: ->
    @setHorizontalAlignment AlignmentSpecHorizontal.LEFT
    @
  alignCenter: ->
    @setHorizontalAlignment AlignmentSpecHorizontal.CENTER
    @
  alignRight: ->
    @setHorizontalAlignment AlignmentSpecHorizontal.RIGHT
    @
  alignTop: ->
    @setVerticalAlignment AlignmentSpecVertical.TOP
    @
  alignMiddle: ->
    @setVerticalAlignment AlignmentSpecVertical.MIDDLE
    @
  alignBottom: ->
    @setVerticalAlignment AlignmentSpecVertical.BOTTOM
    @
  
  toString: ->
    # e.g. 'a StringMorph2("Hello World")'
    firstPart = super()
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and
    AutomatorRecorderAndPlayer.hidingOfMorphsContentExtractInLabels
      return firstPart
    else
      return firstPart + " (\"" + @text.slice(0, 30).replace(/(?:\r\n|\r|\n)/g, '↵') + "...\")"

  # used to identify morphs in macros/tests.
  # identifying morphs this way resists more
  # to tampering such as adding/removing morphs and
  # changing their locations.
  getTextDescription: ->
    if @textDescription?
      return @textDescription + " (adhoc description of string)"
    textWithoutLocationOrInstanceNo = @text.replace /#\d*/, ""
    return textWithoutLocationOrInstanceNo.slice(0, 30) + " (content of string)"
  
  obfuscateAsPassword: (letter, length) ->
    # there is an alternative to this, using an idiom
    # http://stackoverflow.com/a/19892144
    # but it's clearer this way
    ans = ""
    for i in [0...length]
      ans += letter
    ans

  buildCanvasFontProperty: (overrideFontSize = @fittingFontSize) ->
    # answer a font string, e.g. 'bold italic 12px Arial'
    font = ""
    font = font + "bold "  if @isBold
    font = font + "italic "  if @isItalic
    font + overrideFontSize + "px " + @fontName

  # does a binary search to see which font size
  # we need to apply to the text to fit to the
  # current extent.
  # If this gets slow: some optimisations can be done,
  # for example trying to make a couple of preliminary guesses
  # assuming that the user is just resizing something slightly,
  # which means that the font size is gonna change only slightly
  # from the current one, so you can try to narrow the bracket
  # a lot at the very start.
  searchLargestFittingFont: (textToFit) ->

    # decimalFloatFiguresOfFontSizeGranularity allows you to go into sub-points
    # in the font size. This is so the resizing of the
    # text is less "jumpy".
    # "1" seems to be perfect in terms of jumpiness,
    # but obviously this routine gets quite a bit more
    # expensive.
    PreferencesAndSettings.decimalFloatFiguresOfFontSizeGranularity = 0

    # minimum font size that we are gonna examine
    start = 0
    # maximum font size that we are gonna examine
    stop  = Math.round 200 * Math.pow 10,
            PreferencesAndSettings.decimalFloatFiguresOfFontSizeGranularity
    
    if !@doesTextFitInExtent textToFit, start
      return -1


    if @doesTextFitInExtent textToFit, stop
      return stop / Math.pow 10, PreferencesAndSettings.decimalFloatFiguresOfFontSizeGranularity

    # since we round the pivot to the floor, we
    # always end up start and pivot coinciding
    while start != (pivot = Math.floor (start + stop) / 2)

      itFitsAtPivot = @doesTextFitInExtent textToFit, pivot / Math.pow 10, PreferencesAndSettings.decimalFloatFiguresOfFontSizeGranularity

      if itFitsAtPivot
        # bring forward the start since there are still
        # zeroes at the pivot
        start = pivot
      else
        # bring backwards the stop since there is already
        # a one at the pivot
        stop = pivot

    return start / Math.pow 10, PreferencesAndSettings.decimalFloatFiguresOfFontSizeGranularity

  generateTextWithEllipsis: (startingText) ->
    if startingText != ""
      return startingText + "…"
    return ""

  # what we are tyring to do here is to fit the text into
  # a boundary that potentially is too small. We are not going
  # to fit it by changing the font size, rather we are fitting
  # it by cropping it.
  # Note that the text could be set to wrap, so we also have
  # to take that into account when measuring if it fits.
  #
  # Note that the resulting text might contain more than one
  # crop, because several lines might be extending beyond the
  # width of the boundary.
  #
  # See comment above for "searchLargestFittingFont" for some
  # ideas on how to optimise this further.
  searchLongestFittingTextByMultiCroppingIt: (textToFit) ->
    textToFit = @transformTextOneToOne @text

    # check if it fits as is, maybe we don't
    # need to do any cropping.
    if @doesTextFitInExtent(textToFit, @originallySetFontSize)
       return textToFit


    # split textToFit into lines i.e. into paragraphs
    splitText = textToFit.split /\n/
    
    fittingText = ""

    for i in [0...splitText.length]

      eachParagraph  = splitText[i]
      fittingText += eachParagraph
      
      # also add the newline, except if it's
      # the last element of the array, in which
      # case there is no newline after it.
      if i != splitText.length - 1
        fittingText += "\n"

      #console.log "searchLongestFittingTextByMultiCroppingIt trying to fit one more paragraph:"
      #console.log "   " + eachParagraph
      #console.log " overal blurb we are fitting: " + fittingText

      # add each new line of textToFit to the existing blurb to be tested
      # (if we are done with adding lines of textToFit, then we have our
      # successful blurb)

      if !@doesTextFitInExtent(fittingText, @originallySetFontSize)

        start = 0    # minimum string length that we are gonna examine
        stop  = fittingText.length

        # since we round the pivot to the floor, we
        # always end up start and pivot coinciding
        while start != (pivot = Math.floor (start + stop) / 2)

          #console.log "start/stop/pivot: " + start + " / " + stop + " / " + pivot

          textAtPivot = fittingText.substring 0, pivot
          itFitsAtPivot = @doesTextFitInExtent textAtPivot, @originallySetFontSize
          #console.log "  what fits: " + textAtPivot + " fits: " + valueAtPivot

          if itFitsAtPivot
            #console.log "fits at pivot of " + pivot + " : start = pivot now"
            # bring forward the start since there are still
            # zeroes at the pivot
            start = pivot
          else
            #console.log "doesn't fit at pivot of " + pivot + " : start = pivot now"
            # bring backwards the stop since there is already
            # a one at the pivot
            stop = pivot

        #replace the blurb we just tested with the piece of it that actually
        # fits, and that might have a crop in it.
        if start != fittingText.length

          # todo you should count the newlines
          paragraphBeforeWithNewLineHasBeenCropped = false
          if fittingText.substr(fittingText.length - 1) == "\n"
            paragraphBeforeWithNewLineHasBeenCropped = true

          reducing = 0
          while (start - reducing > 0) and !@doesTextFitInExtent(
              @generateTextWithEllipsis(
                fittingText.substring(0, start - reducing)
                ),
              @originallySetFontSize
              )
            reducing++

          if (start - reducing == 0)
            if @doesTextFitInExtent "…", @originallySetFontSize
              fittingText = "…"
            else
              fittingText = ""
          else
            fittingText = @generateTextWithEllipsis(fittingText.substring 0, start - reducing)

          if paragraphBeforeWithNewLineHasBeenCropped
            if !@doesTextFitInExtent fittingText + "\n", @originallySetFontSize
              console.log "break 1"
              break
            else
              fittingText += "\n"

          if !@doesTextFitInExtent fittingText, @originallySetFontSize
            alert "something wrong, this really should have fit: >" + fittingText + "<"
            debugger
            @doesTextFitInExtent fittingText, @originallySetFontSize

      #console.log "what fits: " + fittingText

      # if there is no more space
      # for even a single line with the smallest character, then it means
      # that just there is no more vertical space, this is really the
      # end, then exit the loop, we have the biggest
      # possible blurb that we can fit.
      #if i != splitText.length - 1
      #  if !@doesTextFitInExtent fittingText + "\n", @originallySetFontSize
      #    console.log "break 2"
      #    break

    # we either found the fitting blurb or we are in the
    # degenerate case where almost nothing fits

    # check degenerate case where (almost) nothing fits
    if fittingText.length == 0
      if @doesTextFitInExtent "…", @originallySetFontSize
        fittingText = "…"
      else
        fittingText = ""

    #console.log "_________fittingText: " + fittingText


    return fittingText


  synchroniseTextAndActualText: ->
    textToFit = @transformTextOneToOne @text
    if @doesTextFitInExtent textToFit, @originallySetFontSize
      @textPossiblyCroppedToFit = textToFit
      #console.log "@textPossiblyCroppedToFit = textToFit 1"
    else
      if @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.SCALEDOWN
        @textPossiblyCroppedToFit = textToFit
        #console.log "@textPossiblyCroppedToFit = textToFit 2"

  eliminateInvisibleCharacter: (string) ->
    string.replace @emptyCharacter, ''

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
    # you'd think that we don't need to eliminate the invisible character
    # to measure the text, as it's supposed to be of zero length.
    # Unfortunately some fonts do draw it, so we indeed have to eliminate
    # it.
    cacheEntry = world.canvasContextForTextMeasurements.measureText(@eliminateInvisibleCharacter text).width
    world.cacheForTextMeasurements.set cacheKey, cacheEntry
    #if cacheHit?
    #  if cacheHit != cacheEntry
    #    alert "problem with cache on: " + overrideFontSize + "-" + text + " hit is: " + cacheHit + " should be: " + cacheEntry
    return cacheEntry

  visualisedText: ->
    return @textPossiblyCroppedToFit

  # this should be a 1-1 transformation.
  # for example substitute any letter with "*" for passwords
  # or turn everything to uppercase
  transformTextOneToOne: (theText) ->
    return (if @isPassword then @obfuscateAsPassword("*", theText.length) else theText)

  # there are many factors beyond the font size that affect
  # the measuring, such as font style, but we only pass
  # the font size here because is the one we are going to
  # change when we do the binary search for trying to
  # see the largest fitting size.
  doesTextFitInExtent: (text = (@transformTextOneToOne @text), overrideFontSize) ->
    if !@measureText?
      debugger
    if text == ""
      return true
    extentOccupiedByText = new Point Math.ceil(@measureText overrideFontSize, text), fontHeight(overrideFontSize)

    return extentOccupiedByText.le @extent()

  fitToExtent: ->
    # this if is just to check if the text fits in the
    # current extent. If it does, we either leave the size
    # as is or we try to
    # make the font size bigger if that's the policy.
    # If it doesn't fit, then we either crop it or make the
    # font smaller.
    
    #if !window.globCounter? then window.globCounter = 0
    #window.globCounter++
    #console.log "fitting to extent " + window.globCounter

    textToFit = @transformTextOneToOne @text

    if @doesTextFitInExtent textToFit, @originallySetFontSize
      @textPossiblyCroppedToFit = textToFit
      #console.log "@textPossiblyCroppedToFit = textToFit 3"
      if @fittingSpecWhenBoundsTooLarge == FittingSpecTextInLargerBounds.SCALEUP
        largestFittingFontSize = @searchLargestFittingFont textToFit
        return largestFittingFontSize
      else
        return @originallySetFontSize
    else
      if @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.CROP
        @textPossiblyCroppedToFit = @searchLongestFittingTextByMultiCroppingIt textToFit
        return @originallySetFontSize
      else
        @textPossiblyCroppedToFit = textToFit
        #console.log "@textPossiblyCroppedToFit = textToFit 4"
        largestFittingFontSize = @searchLargestFittingFont textToFit
        return largestFittingFontSize

  calculateTextWidth: (text, overrideFontSize) ->
    return @measureText overrideFontSize, text

  setFittingFontSize: (theValue) ->
    if @fittingFontSize != theValue
      @fittingFontSize = theValue
      @changed()

  createBufferCacheKey: ->
    @extent().toString() + "-" +
    @isPassword  + "-" +
    @isShowingBlanks  + "-" +
    @originallySetFontSize + "-" +
    @buildCanvasFontProperty() + "-" +
    @hasDarkOutline + "-" +
    @isHeaderLine + "-" +
    @color.toString()  + "-" +
    (if @backgroundColor? then @backgroundColor.toString() else "transp") + "-" +
    (if @backgroundTransparency? then @backgroundTransparency.toString() else "transp") + "-" +
    hashCode(@text)  + "-" +
    hashCode(@textPossiblyCroppedToFit)  + "-" +
    @startMark  + "-" +
    @endMark  + "-" +
    @markedBackgoundColor.toString()  + "-" +
    @horizontalAlignment  + "-" +
    @verticalAlignment  + "-" +
    @fittingSpecWhenBoundsTooLarge  + "-" +
    @fittingSpecWhenBoundsTooSmall

  textVerticalPosition: (heightOfText) -> 
    switch @verticalAlignment
      when AlignmentSpecVertical.TOP
        0
      when AlignmentSpecVertical.MIDDLE
        (@height() - heightOfText)/2
      when AlignmentSpecVertical.BOTTOM
        @height() - heightOfText

  textHorizontalPosition: (widthOfText) ->
    switch @horizontalAlignment
      when AlignmentSpecHorizontal.LEFT
        0
      when AlignmentSpecHorizontal.CENTER
        @width()/2 - widthOfText/2
      when AlignmentSpecHorizontal.RIGHT
        @width() - widthOfText


  # no changes of position or extent should be
  # performed in here
  createRefreshOrGetBackBuffer: ->

    cacheKey = @createBufferCacheKey @horizontalAlignment, @verticalAlignment
    cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
    if cacheHit?
      # we might have hit a previously cached
      # backBuffer but here we are interested in
      # knowing whether the buffer we are gonna paint
      # is the same as the one being shown now. If
      # not, then we mark the caret as broken.
      if @backBuffer != cacheHit[0]
        if world.caret?
          world.caret.changed()      
      return cacheHit

    @reflowText()

    # if we are calculating a new buffer then
    # for sure we have to mark the caret as broken
    if world.caret?
      world.caret.changed()      

    text = @textPossiblyCroppedToFit
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
    widthOfText = @calculateTextWidth text
    heightOfText = fontHeight @fittingFontSize
    if @backgroundColor? or
     @verticalAlignment != AlignmentSpecVertical.TOP or
     @horizontalAlignment != AlignmentSpecHorizontal.LEFT or
     @fittingSpecWhenBoundsTooLarge == FittingSpecTextInLargerBounds.FLOAT
      width = @width()
      height = @height()
    else
      width = widthOfText
      height = heightOfText

    backBuffer = newCanvas (new Point width, height).scaleBy pixelRatio

    backBufferContext = backBuffer.getContext "2d"

    backBufferContext.scale pixelRatio, pixelRatio
    backBufferContext.font = @buildCanvasFontProperty()
    backBufferContext.textAlign = "left"
    backBufferContext.textBaseline = "bottom"

    # paint the background so we have a better sense of
    # where the text is fitting into.
    # paintRectangle here is passed logical pixels
    # rather than actual pixels, contrary to how it's used
    # most other places. This is because it's inside
    # the scope of the "scale pixelRatio, pixelRatio".
    if @backgroundColor
      backBufferContext.save()
      backBufferContext.fillStyle = @backgroundColor.toString()
      backBufferContext.globalAlpha = @backgroundTransparency
      backBufferContext.fillRect  0,
          0,
          Math.round(@width()),
          Math.round(@height())
      backBufferContext.restore()


    textVerticalPosition = @textVerticalPosition(fontHeight @fittingFontSize) + fontHeight(@fittingFontSize)
    textHorizontalPosition = @textHorizontalPosition widthOfText

    if @hasDarkOutline
      backBufferContext.fillStyle = "black"
      backBufferContext.fillText text, textHorizontalPosition+0, textVerticalPosition+0
      backBufferContext.fillText text, textHorizontalPosition+1.5, textVerticalPosition+0
      backBufferContext.fillText text, textHorizontalPosition-1.5, textVerticalPosition+0
      backBufferContext.fillText text, textHorizontalPosition+0, textVerticalPosition+1.5
      backBufferContext.fillText text, textHorizontalPosition+1.5, textVerticalPosition+1.5
      backBufferContext.fillText text, textHorizontalPosition-1.5, textVerticalPosition+1.5
      backBufferContext.fillText text, textHorizontalPosition+0, textVerticalPosition-1.5
      backBufferContext.fillText text, textHorizontalPosition+1.5, textVerticalPosition-1.5
      backBufferContext.fillText text, textHorizontalPosition-1.5, textVerticalPosition-1.5

    backBufferContext.fillStyle = @color.toString()
    backBufferContext.fillText text, textHorizontalPosition, textVerticalPosition

    # header line
    if @isHeaderLine
      backBufferContext.strokeStyle = new Color 198, 198, 198
      backBufferContext.beginPath()
      backBufferContext.moveTo 0, textVerticalPosition - heightOfText / 2
      backBufferContext.lineTo textHorizontalPosition - 5, textVerticalPosition - heightOfText / 2
      backBufferContext.moveTo textHorizontalPosition + widthOfText + 5, textVerticalPosition - heightOfText / 2
      backBufferContext.lineTo @width(), textVerticalPosition - heightOfText / 2
      backBufferContext.stroke()




    @drawSelection backBufferContext

    cacheEntry = [backBuffer, backBufferContext]
    world.cacheForImmutableBackBuffers.set cacheKey, cacheEntry
    return cacheEntry

  # Draw the selection. This is done by re-drawing the
  # selected text, one character at the time, just with
  # a background rectangle.
  #
  # TODO would really benefit from some batching, it's often the
  # case that entire lines can be done in one shot instead of doing
  # them char by char. It's not just the painting that is slow, it's
  # also the slot coordinates calculations that become quite taxing done
  # this way. I profiled this, just see how highlighting gets slower
  # and slower as selection gets longer.
  #
  drawSelection: (backBufferContext) ->
    startSlot = @firstSelectedSlot()
    endSlot = @lastSelectedSlot()
    for i in [startSlot...endSlot]
      p = @slotCoordinates(i).subtract @position()
      c = @textPossiblyCroppedToFit.charAt(i)
      backBufferContext.fillStyle = @markedBackgoundColor.toString()
      backBufferContext.fillRect p.x, p.y, Math.ceil(@measureText nil, c) + 1, Math.ceil fontHeight @fittingFontSize
      backBufferContext.fillStyle = @markedTextColor.toString()
      backBufferContext.fillText c, p.x, p.y + Math.ceil fontHeight @fittingFontSize
    
  
  # StringMorph2 measuring:
  slotCoordinates: (slot) ->
    
    # this makes it so when you type and the string becomes too big
    # then the edit stops to be directly in the screen and the
    # popout for editing takes over.
    if (@transformTextOneToOne @text) != @textPossiblyCroppedToFit and @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.CROP
      world.stopEditing()
      @edit()
      return nil

    # answer the position point of the given index ("slot")
    # where the caret should be placed
    text = @text

    # let's be defensive and check that the
    # slot is in the right interval
    checkedSlot = Math.min Math.max(slot, 0), text.length
    if slot != checkedSlot
      alert "something wrong - slot is out of range"
    slot = checkedSlot

    xOffset = Math.ceil @calculateTextWidth text.substring 0, slot
    x = @left() + xOffset
    y = @top()

    widthOfText = @calculateTextWidth text

    textVerticalPosition = @textVerticalPosition fontHeight @fittingFontSize
    textHorizontalPosition = @textHorizontalPosition widthOfText

    x += textHorizontalPosition
    y += textVerticalPosition

    new Point x, y

  slotAtSingleLineString: (xPosition, text) ->

    widthOfText = @calculateTextWidth text
    textHorizontalPosition = @textHorizontalPosition widthOfText

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
        #console.log "xPosition - @left(): " + (xPosition - @left()) + " charXMinusOne " + charXMinusOne + "  charX " + charX 
        #console.log "Math.abs(xPosition - @left() - charXMinusOne) " + Math.abs(xPosition - @left() - charXMinusOne) + "  Math.abs(xPosition - @left() - charX) " + Math.abs(xPosition - @left() - charX) 
        if Math.abs(xPosition - @left() - charXMinusOne) < Math.abs(xPosition - @left() - charX)
          return idx - 1
        break

      if charX?
        charXMinusOne = charX
      else
        charXMinusOne = 0

      charX += @calculateTextWidth text[idx]

      idx += 1
      if idx is text.length
        if ((@calculateTextWidth(text)) - ((@calculateTextWidth(text[idx-1])) / 2)) < (xPosition - @left())  
          return idx
    idx

  pointIsAboveFirstLine: (aPoint) ->
    textVerticalPosition = @textVerticalPosition fontHeight @fittingFontSize

    if aPoint.y - @top() < textVerticalPosition
      return 0

    return false

  pointIsUnderLastLine: (aPoint) ->
    textVerticalPosition = @textVerticalPosition(fontHeight @fittingFontSize) + fontHeight(@fittingFontSize)

    # if pointer is below the line, the slot is at
    # the last character.
    if (aPoint.y - textVerticalPosition) - @top() > Math.ceil fontHeight @fittingFontSize
      return @textPossiblyCroppedToFit.length

    return false
  
  slotAt: (aPoint) ->
    if (isPointBeforeFirstLine = @pointIsAboveFirstLine aPoint) != false
      return isPointBeforeFirstLine

    if (isPointUnderLastLine = @pointIsUnderLastLine aPoint) != false
      return isPointUnderLastLine

    return @slotAtSingleLineString aPoint.x, @textPossiblyCroppedToFit
  
  upFrom: (slot) ->
    @startOfLine()
  
  downFrom: (slot) ->
    @endOfLine()
  
  startOfLine: ->
    # answer the first slot (index) of the line for the given slot
    0
  
  endOfLine: ->
    # answer the slot (index) indicating the EOL for the given slot
    @textPossiblyCroppedToFit.length

  fontSizePopup: (menuItem)->
    @prompt menuItem.parent.title + "\nfont\nsize:",
      @,
      "setFontSize",
      @originallySetFontSize.toString(),
      nil, 6, 500, true

  editPopup: (menuItem)->
    if menuItem?
      title = menuItem.parent.title + "\nedit:"
    else
      title = "edit:"

    @prompt title,
      @,
      "setText",
      @text,
      nil, 6, nil, true

  setFontName: (menuItem, ignored2, theNewFontName) ->
    if @fontName != theNewFontName
      @fontName = theNewFontName
      @changed()

      if menuItem?.parent? and (menuItem.parent instanceof MenuMorph)
        @updateFontsMenuEntriesTicks menuItem.parent


  fontsMenu: (a,targetMorph)->
    menu = new MenuMorph @, false, targetMorph, true, true, "Fonts"

    menu.addMenuItem untick + "Arial", true, @, "setFontName", nil, nil, nil, nil, nil, @justArialFontStack
    menu.addMenuItem untick + "Times", true, @, "setFontName", nil, nil, nil, nil, nil, @timesFontStack
    menu.addMenuItem untick + "Georgia", true, @, "setFontName", nil, nil, nil, nil, nil, @georgiaFontStack
    menu.addMenuItem untick + "Garamo", true, @, "setFontName", nil, nil, nil, nil, nil, @garamoFontStack
    menu.addMenuItem untick + "Helve", true, @, "setFontName", nil, nil, nil, nil, nil, @helveFontStack
    menu.addMenuItem untick + "Verda", true, @, "setFontName", nil, nil, nil, nil, nil, @verdaFontStack
    menu.addMenuItem untick + "Treby", true, @, "setFontName", nil, nil, nil, nil, nil, @trebuFontStack
    menu.addMenuItem untick + "Heavy", true, @, "setFontName", nil, nil, nil, nil, nil, @heavyFontStack
    menu.addMenuItem untick + "Mono", true, @, "setFontName", nil, nil, nil, nil, nil, @monoFontStack

    @updateFontsMenuEntriesTicks menu

    menu.popUpAtHand()

  # cheap way to keep menu consistency when pinned
  # note that there is no consistency in case
  # there are multiple copies of this menu changing
  # the property, since there is no real subscription
  # of a menu to react to property change coming
  # from other menus or other means (e.g. API)...
  updateFontsMenuEntriesTicks: (menu) ->
    justArialFontStackTick = timesFontStackTick = georgiaFontStackTick =
    garamoFontStackTick = helveFontStackTick = verdaFontStackTick =
    trebuFontStackTick = heavyFontStackTick = monoFontStackTick = untick


    switch @fontName
      when @justArialFontStack
        justArialFontStackTick = tick
      when @timesFontStack
        timesFontStackTick = tick
      when @georgiaFontStack
        georgiaFontStackTick = tick
      when @garamoFontStack
        garamoFontStackTick = tick
      when @helveFontStack
        helveFontStackTick = tick
      when @verdaFontStack
        verdaFontStackTick = tick
      when @trebuFontStack
        trebuFontStackTick = tick
      when @heavyFontStack
        heavyFontStackTick = tick
      when @monoFontStack
        monoFontStackTick = tick

    menu.children[1].label.setText justArialFontStackTick + "Arial"
    menu.children[2].label.setText timesFontStackTick + "Times"
    menu.children[3].label.setText georgiaFontStackTick + "Georgia"
    menu.children[4].label.setText garamoFontStackTick + "Garamo"
    menu.children[5].label.setText helveFontStackTick + "Helve"
    menu.children[6].label.setText verdaFontStackTick + "Verda"
    menu.children[7].label.setText trebuFontStackTick + "Treby"
    menu.children[8].label.setText heavyFontStackTick + "Heavy"
    menu.children[9].label.setText monoFontStackTick + "Mono"


  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "edit...", true, @, "editPopup", "set this String's\ncontent"
    menu.addMenuItem "font size...", true, @, "fontSizePopup", "set this String's\nfont point size"

    menu.addMenuItem "font ➜", false, @, "fontsMenu", "pick a font"

    if @isBold
      menu.addMenuItem "normal weight", true, @, "toggleWeight"
    else
      menu.addMenuItem "bold", true, @, "toggleWeight"

    if @isItalic
      menu.addMenuItem "non-italic", true, @, "toggleItalic"
    else
      menu.addMenuItem "italic", true, @, "toggleItalic"

    if @isHeaderLine
      menu.addMenuItem "no header line", true, @, "toggleHeaderLine"
    else
      menu.addMenuItem "header line", true, @, "toggleHeaderLine"


    if @isPassword
      menu.addMenuItem "show characters", true, @, "toggleIsPassword"
    else
      menu.addMenuItem "hide characters", true, @, "toggleIsPassword"

    menu.addLine()
    if @horizontalAlignment != AlignmentSpecHorizontal.LEFT
      menu.addMenuItem "← align left", true, @, "alignLeft"
    if @horizontalAlignment != AlignmentSpecHorizontal.CENTER
      menu.addMenuItem "∸ align center", true, @, "alignCenter"
    if @horizontalAlignment != AlignmentSpecHorizontal.RIGHT
      menu.addMenuItem "→ align right", true, @, "alignRight"

    menu.addLine()
    if @verticalAlignment != AlignmentSpecVertical.TOP
      menu.addMenuItem "↑ align top", true, @, "alignTop"
    if @verticalAlignment != AlignmentSpecVertical.MIDDLE
      menu.addMenuItem "⍿ align middle", true, @, "alignMiddle"
    if @verticalAlignment != AlignmentSpecVertical.BOTTOM
      menu.addMenuItem "↓ align bottom", true, @, "alignBottom"

    menu.addLine()

    if @fittingSpecWhenBoundsTooLarge == FittingSpecTextInLargerBounds.SCALEUP
      menu.addMenuItem "←☓→ don't expand to fill", true, @, "togglefittingSpecWhenBoundsTooLarge"
    else
      menu.addMenuItem "←→ expand to fill", true, @, "togglefittingSpecWhenBoundsTooLarge"

    if @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.CROP
      menu.addMenuItem "→← shrink to fit", true, @, "togglefittingSpecWhenBoundsTooSmall"
    else
      menu.addMenuItem "→⋯← crop to fit", true, @, "togglefittingSpecWhenBoundsTooSmall"

    if world.isIndexPage
      menu.addLine()
      menu.addMenuItem "set target", true, @, "openTargetSelector", "select another morph\nwhose numerical property\nwill be " + "controlled by this one"


  togglefittingSpecWhenBoundsTooSmall: ->
    @fittingSpecWhenBoundsTooSmall = not @fittingSpecWhenBoundsTooSmall
    @changed()
    world.stopEditing()

  togglefittingSpecWhenBoundsTooLarge: ->
    world.stopEditing()
    @fittingSpecWhenBoundsTooLarge = not @fittingSpecWhenBoundsTooLarge
    @changed()

  
  toggleShowBlanks: ->
    @isShowingBlanks = not @isShowingBlanks
    @changed()
  
  toggleWeight: ->
    @isBold = not @isBold
    @changed()
  
  toggleItalic: ->
    @isItalic = not @isItalic
    @changed()

  toggleHeaderLine: ->
    @isHeaderLine = not @isHeaderLine
    @changed()
  
  toggleIsPassword: ->
    world.stopEditing()
    @isPassword = not @isPassword
    @changed()

  changed: ->
    super
    if world.caret?
      world.caret.changed()
  
  # adjust the data models behind the text. E.g.
  # is it going to be shown as cropped? What size
  # is it going to be? How is the text broken down
  # into rows?
  # this method doesn't draw anything.
  reflowText: ->
    @synchroniseTextAndActualText()
    @setFittingFontSize @fitToExtent()

  # This is also invoked for example when you take a slider
  # and set it to target this.
  setText: (theTextContent, stringFieldMorph, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = getRandomInt -20000, 20000 else @connectionsCalculationToken = connectionsCalculationToken
    if stringFieldMorph?
      # in this case, the stringFieldMorph has a
      # StringMorph in "text". The StringMorph has the
      # "text" inside it.
      theTextContent = stringFieldMorph.text.text

    theNewText = theTextContent + ""
    if @text != theNewText
      # other morphs might send something like a
      # number or a color so let's make sure we
      # convert to a string.
      @clearSelection()
      @text = theNewText
      @checkIfTextContentWasModifiedFromTextAtStart()
      @synchroniseTextAndActualText()
      @changed()

    @updateTarget()

  considerCurrentTextAsReferenceText: ->
    @hashOfTextConsideredAsReference = hashCode @text

  checkIfTextContentWasModifiedFromTextAtStart: ->
    if @widgetToBeNotifiedOfTextModificationChange?
      if @hashOfTextConsideredAsReference == hashCode @text
        @widgetToBeNotifiedOfTextModificationChange.textContentUnmodified?()
      else
        @widgetToBeNotifiedOfTextModificationChange.textContentModified?()
  
  setFontSize: (sizeOrMorphGivingSize, morphGivingSize) ->
    if morphGivingSize?.getValue?
      size = morphGivingSize.getValue()
    else
      size = sizeOrMorphGivingSize

    if typeof size is "number"
      newSize = Math.round Math.min Math.max(size, 4), 500
    else
      newSize = parseFloat size
      newSize = Math.round Math.min Math.max(newSize, 4), 500  unless isNaN newSize

    if newSize != @originallySetFontSize
      @originallySetFontSize = newSize
      @changed()
  
  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    debugger
    [menuEntriesStrings, functionNamesStrings] = theTarget.stringSetters()
    menu = new MenuMorph @, false, @, true, true, "choose target property:"
    for i in [0...menuEntriesStrings.length]
      menu.addMenuItem menuEntriesStrings[i], true, @, "setTargetAndActionWithOnesPickedFromMenu", nil, nil, nil, nil, nil, theTarget, functionNamesStrings[i]
    if menuEntriesStrings.length == 0
      menu = new MenuMorph @, false, @, true, true, "no target properties available"
    menu.popUpAtHand()
  
  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "alpha 0-100", "font size", "text"
    functionNamesStrings.push "setAlphaScaled", "setFontSize", "setText"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings
  
  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!", "text"
    functionNamesStrings.push "bang", "setText"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  updateTarget: ->
    if @action and @action != ""
      @target[@action].call @target, @text, nil, @connectionsCalculationToken
    return

  reactToTargetConnection: ->
    @updateTarget()

  
  # StringMorph2 editing:
  edit: ->
    if @textPossiblyCroppedToFit == @transformTextOneToOne @text
      world.edit @
      return true
    else
      @editPopup()
      return nil

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

  currentlySelecting: ->
    if !@startMark? and !@endMark?
     return false
    return true
  
  clearSelection: ->
    if !@startMark? and !@endMark?
      return
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
    start = Math.min @startMark, @endMark
    stop = Math.max @startMark, @endMark
    @setText @text.slice(0, start) + @text.slice(stop)

  selectAll: ->
    @startMark = 0
    @endMark = @textPossiblyCroppedToFit.length    
    @changed()

  # used when shift-clicking somewhere when there is
  # no selection ongoing
  startSelectionUpToSlot: (previousCaretSlot, slotToExtendTo) ->
    @startMark = previousCaretSlot
    @endMark = slotToExtendTo
    @changed()

  # used when shift-clicking somewhere when there is
  # already a selection ongoing
  extendSelectionUpToSlot: (slotToExtendTo) ->
    @endMark = slotToExtendTo
    @changed()

  mouseDoubleClick: ->
    if @isEditable
      previousCaretSlot = world.caret?.slot

      extendRight = 0
      while previousCaretSlot + extendRight < @text.length
        if !@text[previousCaretSlot + extendRight].isLetter()
          break
        extendRight++

      extendLeft = 0
      while previousCaretSlot + extendLeft - 1 >= 0
        if !@text[previousCaretSlot + extendLeft - 1].isLetter()
          break
        extendLeft--

      @selectBetween (previousCaretSlot + extendLeft), (previousCaretSlot + extendRight)
      world.caret?.gotoSlot (previousCaretSlot + extendRight)

  mouseTripleClick: ->
    if @isEditable
      @selectAll()
      world.caret?.gotoSlot @text.length


  # Every time the user clicks on the text, a new edit()
  # is triggered, which creates a new caret.
  mouseClickLeft: (pos, ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey) ->
    @bringToForeground()
    world.caret?.bringToForeground()
    if @isEditable
      # doesn't matter what we set editResult to initially,
      # just not undefined or nil cause that's
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
        world.caret.gotoSlot slotUserClickedOn, true
        world.caret.show()
        @caretHorizPositionForVertMovement = world.caret.slot

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


  
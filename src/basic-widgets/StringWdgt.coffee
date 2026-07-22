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
# use a text widget instead.
# It fits any given size (see the FITTING MODEL comment below), so it
# behaves well in layouts.
#
# TODO Note that this class has problems with text that has multi-code characters, i.e. characters that for a cursor behave like a single character
# (i.e. the cursor moves around them with one single arrow key press) BUT that, unintuitively, have .length property > 1 (e.g. "ä".length is 2)
# this is because the code assumes that the .length property of a string is the number of characters in the string, which, as in the "ä"
# example, is not true.

class StringWdgt extends Widget

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

  blanksColor: Color.create 180, 140, 140

  # Used for when the cursor movement causes the
  # text to scroll, so that the caret is in-view when
  # used, say, on a text in a ScrollPanelWdgt.
  isScrollable: true

  # When true, the box re-sizes itself to its text on every setText ("box hugs
  # text" behaviour). Set by sizeToTextAndDisableFitting; OFF by default so a
  # generic StringWdgt in a layout still fits its text into its FIXED box (the
  # modern model). See sizeToTextAndDisableFitting for why the chrome labels
  # need this.
  autoSizeBoxToText: false

  # startMark and endMark contain the slot of the
  # slot first selected IN TIME, not "in space".
  # i.e. startMark might be higher than endMark if
  # text had been selected starting from the
  # right and "going left"
  startMark: nil
  endMark: nil

  markedTextColor: Color.WHITE
  markedBackgroundColor: Color.create 60, 60, 120

  horizontalAlignment: AlignmentSpecHorizontal.LEFT
  verticalAlignment: AlignmentSpecVertical.TOP

  # ===========================================================================
  # FITTING MODEL — the two complementary fitting modes (the `fittingSpec` axis).
  #
  # MODE 1, FIT_TEXT_TO_BOX (the DEFAULT): the box extent is FIXED (set by the
  # layout / the user) and the TEXT is fitted INTO it — the two specs below decide
  # how (they only ever change @textPossiblyCroppedToFit and @fittingFontSize,
  # NEVER @extent()):
  #   - fittingSpecWhenBoundsTooLarge: FLOAT (keep the set font size, the text
  #     floats per horizontal/verticalAlignment) | SCALEUP (grow the font via
  #     searchLargestFittingFont to fill the box).
  #   - fittingSpecWhenBoundsTooSmall: CROP (ellipsise via
  #     searchLongestFittingTextByMultiCroppingIt, keep the font) | SCALEDOWN
  #     (shrink the font so the whole text fits).
  # Both are consumed only in fitToExtent(), called from reflowText().
  #
  # MODE 2, FIT_BOX_TO_TEXT (opt-in): the COMPLEMENTARY mode — the widget resizes
  # its OWN extent to hug its text, at the SET font size (the font is NEVER scaled:
  # reflowText short-circuits fitToExtent for this mode and renders at
  # @originallySetFontSize — without that, SCALEUP's searchLargestFittingFont would
  # blow the font up, since the render leaks force every fit-measure to the set
  # size). The box-to-text SIZING lives in TextWdgt::_reLayoutSelf — a LAYOUT pass, NOT
  # the paint path (_createRefreshOrGetBackBuffer must never change @extent()):
  #   - softWrap ON  → HEIGHT_ADJUSTS_TO_WIDTH: keep the width (the container feeds
  #     it), wrap the text to it, the height follows the line count.
  #   - softWrap OFF → the box hugs the natural, un-wrapped text width (the
  #     "code view" / horizontal-scroll case).
  # This is what makes a SimpleTextWdgt — and now ANY TextWdgt used as window
  # / panel / scroll content — re-wrap and auto-grow/shrink its height. Two
  # sub-axes refine it (both stored + part of createBufferCacheKey):
  #   - fittingSpecBoxTightOrLoose: TIGHT (no padding — the only configuration any
  #     caller uses) | LOOSE (a padding margin — reserved, not yet built out).
  #   - fittingSpecBoxWhichDimensionAdjusts: HEIGHT_ADJUSTS_TO_WIDTH (the contained
  #     default) | WIDTH_ADJUSTS_TO_HEIGHT (reserved). The single-line "box hugs
  #     text in BOTH dims" case is the chrome-label path,
  #     StringWdgt#sizeToTextAndDisableFitting (flagged by autoSizeBoxToText).
  #
  # The mode is driven off reflowText()/_reLayoutSelf(), NOT a menu and NOT a
  # type-check: the window / panel / scroll layout sites opt their text content in
  # by setting `fittingSpec` (they RESPECT the mode rather than impose it, so the
  # empty-window placeholder text — a FIT_TEXT_TO_BOX TextWdgt — is left alone),
  # and a FIT_BOX_TO_TEXT widget re-flows its box then invalidates its container
  # (_reflowContainedTextThenInvalidateLayout, below) so the surrounding layout follows.
  #
  # Keep FIT_BOX_TO_TEXT implemented HERE (where the SWCanvas font cap,
  # ControllerMixin and undo/redo already live); do NOT re-introduce a menu-only
  # version whose toggle items are no-op handlers that don't actually resize the
  # widget — that approach was tried and is a dead end.
  # ===========================================================================
  fittingSpecWhenBoundsTooLarge: FittingSpecTextInLargerBounds.FLOAT
  fittingSpecWhenBoundsTooSmall: FittingSpecTextInSmallerBounds.CROP

  # The top-level fitting MODE + its two FIT_BOX_TO_TEXT sub-axes (see the three
  # FittingSpecText* classes and the FITTING MODEL comment above). Defaults =
  # today's behaviour for every free-floating widget: FIT_TEXT_TO_BOX, so the
  # widget never resizes itself and the two fittingSpecWhenBounds* axes above are
  # what act. A contained TextWdgt opts into FIT_BOX_TO_TEXT (set by the window /
  # panel / scroll layout sites, and by SimpleTextWdgt's ctor) to re-wrap +
  # auto-height instead. The sub-axes are honoured by the FIT_BOX_TO_TEXT sizing
  # in TextWdgt::_reLayoutSelf and are part of createBufferCacheKey so a mode/sub-axis
  # change re-renders the cached back-buffer.
  fittingSpec: FittingSpecText.FIT_TEXT_TO_BOX
  # FIT_BOX_TO_TEXT sub-axes (honoured by TextWdgt::_reLayoutSelf, keyed into the
  # buffer-cache key). Each had two values but only one ever shipped, so they are
  # inlined here as raw booleans rather than carrying a single-valued spec class.
  # Re-introduce a named axis only if a second value ships.
  #   TIGHT box: false = the box is exactly the text extent, no padding.
  #     (was FittingSpecTextBoxFittingTextTightOrLoose.TIGHT; LOOSE=true never shipped.)
  fittingSpecBoxTightOrLoose: false
  #   HEIGHT_ADJUSTS_TO_WIDTH: true = width is given, height follows the wrapped lines.
  #     (was FittingSpecTextBoxFittingTextWhichDimensionAdjusts.HEIGHT_ADJUSTS_TO_WIDTH;
  #      WIDTH_ADJUSTS_TO_HEIGHT=false never shipped.)
  fittingSpecBoxWhichDimensionAdjusts: true

  caretHorizPositionForVertMovement: nil

  emptyCharacter: '\u2063'

  # Since we let the browser paint the text, we can't guarantee that
  # a specific font will be available to the user.
  # So we do what web designers do: we allow for a few families of
  # very similar fonts (at least in style if not in shape),
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
      @text = (if text is "" then "" else "StringWdgt"),
      @originallySetFontSize = WorldWdgt.preferencesAndSettings.normalTextFontSize,
      @fontName = @justArialFontStack,
      @isBold = false,
      @isItalic = false,
      @isHeaderLine = false,
      @isNumeric = false,
      @color = (Color.create 37, 37, 37),
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
    @_changed()

  # This font height comes out thin: tall characters such as ⎲█ƒ⎳À⎷ ⎸⎹ get cut.
  fontHeight: (fontSize) ->
    minHeight = Math.max fontSize, WorldWdgt.preferencesAndSettings.minimumFontHeight
    Math.ceil minHeight * 1.2 # assuming 1/5 font size for ascenders

  # the actual font size used might be
  # different than the one specified originally
  # because this widget has to be able to fit
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

    # We never want three consecutive positional-only undo states -- just the
    # initial and the last. Check the last two pushes: if both are purely
    # positional (same selection/text as each other and @), discard the
    # second one before adding the new one below. This makes undo land on the
    # position BEFORE an edit rather than jumping to the end of the prior one.
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

  # Caret-editing-session state (undoHistory, caretHorizPositionForVertMovement) lives here so the
  # caret asks rather than pokes; history: docs/archive/oo-smells-refactoring-backlog.md (Phase 7a).

  # The caret remembers the column it should land on during vertical (up/down) movement, so a
  # short line passed over on the way doesn't lose the original horizontal position. Read by
  # TextWdgt.upFrom / downFrom; set by the caret on horizontal moves and by mouseClickLeft below.
  rememberCaretColumn: (slot) ->
    @caretHorizPositionForVertMovement = slot

  # When a caret first attaches via a positioning click, the only undo entry is that click, which
  # we discard so the user's first real edit becomes the first undo step (CaretWdgt's constructor).
  clearUndoHistoryIfOnlyFirstClickPositioning: ->
    if @undoHistory?.length == 1
      onlyUndo = @undoHistory[@undoHistory.length - 1]
      if onlyUndo.isJustFirstClickToPositionCursor
        @undoHistory = []

  setHorizontalAlignment: (newAlignment) ->
    if @horizontalAlignment != newAlignment
      @horizontalAlignment = newAlignment
      @_changed()

  setVerticalAlignment: (newAlignment) ->
    if @verticalAlignment != newAlignment
      @verticalAlignment = newAlignment
      @_changed()

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
    # e.g. 'a StringWdgt("Hello World")'
    firstPart = super()
    if Automator? and Automator.state != Automator.IDLE and
    Automator.hidingOfWidgetsContentExtractInLabels
      return firstPart
    else
      return firstPart + " (\"" + @text.slice(0, 30).replace(/(?:\r\n|\r|\n)/g, '↵') + "...\")"

  # used to identify widgets in macros/tests.
  # identifying widgets this way resists more
  # to tampering such as adding/removing widgets and
  # changing their locations.
  getTextDescription: ->
    if @textDescription?
      return @textDescription + " (adhoc description of string)"
    textWithoutLocationOrInstanceNo = @text.replace /#\d*/, ""
    return textWithoutLocationOrInstanceNo.slice(0, 30) + " (content of string)"
  
  # »>> this part is excluded from the fizzygum homepage build
  obfuscateAsPassword: (letter, length) ->
    # there is an alternative to this, using an idiom
    # http://stackoverflow.com/a/19892144
    # but it's clearer this way
    ans = ""
    for i in [0...length]
      ans += letter
    ans
  # this part is excluded from the fizzygum homepage build <<«

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
    # maximum font size that we are gonna examine. Normally 200, but under a
    # backend that can only render up to a fixed size (SWCanvas clamps to its
    # largest shipped atlas), cap the search there: a larger size would render
    # no bigger, yet would still inflate fontHeight() — which is pure arithmetic
    # on the requested size and is NOT clamped — so the caret/line height
    # (derived from @fittingFontSize) would balloon while the glyphs stay capped.
    # Capping the search keeps @fittingFontSize == the size actually painted.
    maxExaminedFontSize = 200
    if window.FIZZYGUM_USE_SWCANVAS and window.SWCANVAS_MAX_FONT_SIZE?
      maxExaminedFontSize = Math.min maxExaminedFontSize, window.SWCANVAS_MAX_FONT_SIZE
    stop  = Math.round maxExaminedFontSize * Math.pow 10,
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


      # add each new line of textToFit to the existing blurb to be tested
      # (if we are done with adding lines of textToFit, then we have our
      # successful blurb)

      if !@doesTextFitInExtent(fittingText, @originallySetFontSize)

        start = 0    # minimum string length that we are gonna examine
        stop  = fittingText.length

        # since we round the pivot to the floor, we
        # always end up start and pivot coinciding
        while start != (pivot = Math.floor (start + stop) / 2)


          textAtPivot = fittingText.substring 0, pivot
          itFitsAtPivot = @doesTextFitInExtent textAtPivot, @originallySetFontSize

          if itFitsAtPivot
            # bring forward the start since there are still
            # zeroes at the pivot
            start = pivot
          else
            # bring backwards the stop since there is already
            # a one at the pivot
            stop = pivot

        #replace the blurb we just tested with the piece of it that actually
        # fits, and that might have a crop in it.
        if start != fittingText.length

          # TODO you should count the newlines
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
              break
            else
              fittingText += "\n"

          if !@doesTextFitInExtent fittingText, @originallySetFontSize
            alert "something wrong, this really should have fit: >" + fittingText + "<"
            debugger
            @doesTextFitInExtent fittingText, @originallySetFontSize



    # we either found the fitting blurb or we are in the
    # degenerate case where almost nothing fits

    # check degenerate case where (almost) nothing fits
    if fittingText.length == 0
      if @doesTextFitInExtent "…", @originallySetFontSize
        fittingText = "…"
      else
        fittingText = ""



    return fittingText


  _synchroniseTextAndActualText: ->
    textToFit = @transformTextOneToOne @text
    if @doesTextFitInExtent textToFit, @originallySetFontSize
      @textPossiblyCroppedToFit = textToFit
    else
      if @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.SCALEDOWN
        @textPossiblyCroppedToFit = textToFit

  eliminateInvisibleCharacter: (string) ->
    string.replace @emptyCharacter, ''

  # there are many factors beyond the font size that affect
  # the measuring, such as font style, but we only pass
  # the font size here because is the one we are going to
  # change when we do the binary search for trying to
  # see the largest fitting size.
  measureText: (overrideFontSize = @fittingFontSize, text) ->
    cacheKey =  @buildCanvasFontProperty(overrideFontSize) + "-" + text.hashCode()
    cacheHit = world.cacheForTextMeasurements.get cacheKey
    if cacheHit? then return cacheHit
    world.canvasContextForTextMeasurements.font = @buildCanvasFontProperty overrideFontSize
    # you'd think that we don't need to eliminate the invisible character
    # to measure the text, as it's supposed to be of zero length.
    # Unfortunately some fonts do draw it, so we indeed have to eliminate
    # it.
    cacheEntry = world.canvasContextForTextMeasurements.measureText(@eliminateInvisibleCharacter text).width
    world.cacheForTextMeasurements.set cacheKey, cacheEntry
    return cacheEntry

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
  # hasDarkOutline halo: the offset black glyph copies extend up to 1.5px
  # (plus AA spill) beyond the glyph ink on every side. This margin is reserved
  # in fitting (doesTextFitInExtent), in the text position (textHorizontal/
  # VerticalPosition — shared by paint AND caret/selection math, so both shift
  # together), in the tight text-sized buffer and in the box-hugs-text measure,
  # so the halo never clips at the buffer edge or at the widget bounds (the
  # back buffer blits clipped to the widget box).
  _outlineHaloMargin: ->
    if @hasDarkOutline then 2 else 0

  doesTextFitInExtent: (text = (@transformTextOneToOne @text), overrideFontSize) ->
    if !@measureText?
      debugger
    if text == ""
      return true
    extentOccupiedByText = new Point Math.ceil(@measureText overrideFontSize, text), @fontHeight(overrideFontSize)

    # reserve the halo margin HORIZONTALLY only: measured width is the glyphs'
    # actual advance (ink reaches it), but fontHeight is the full em box, whose
    # internal leading already keeps glyph ink at least a halo's width away from
    # the top/bottom edges. Reserving it vertically too would make a short box
    # (the 15px icon-label band) reject its set font outright — and CROP can
    # only shorten text, never height, so the label would crop away to nothing.
    haloMargin = @_outlineHaloMargin()
    return extentOccupiedByText.le @extent().subtract new Point 2*haloMargin, 0

  fitToExtent: ->
    # this if is just to check if the text fits in the
    # current extent. If it does, we either leave the size
    # as is or we try to
    # make the font size bigger if that's the policy.
    # If it doesn't fit, then we either crop it or make the
    # font smaller.
    

    textToFit = @transformTextOneToOne @text

    if @doesTextFitInExtent textToFit, @originallySetFontSize
      @textPossiblyCroppedToFit = textToFit
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
        largestFittingFontSize = @searchLargestFittingFont textToFit
        return largestFittingFontSize

  calculateTextWidth: (text, overrideFontSize) ->
    return @measureText overrideFontSize, text

  _setFittingFontSize: (theValue) ->
    if @fittingFontSize != theValue
      @fittingFontSize = theValue
      @_changed()

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
    @text.hashCode()  + "-" +
    @textPossiblyCroppedToFit.hashCode()  + "-" +
    @startMark  + "-" +
    @endMark  + "-" +
    @markedBackgroundColor.toString()  + "-" +
    @horizontalAlignment  + "-" +
    @verticalAlignment  + "-" +
    @fittingSpecWhenBoundsTooLarge  + "-" +
    @fittingSpecWhenBoundsTooSmall  + "-" +
    @fittingSpec  + "-" +
    @fittingSpecBoxTightOrLoose  + "-" +
    @fittingSpecBoxWhichDimensionAdjusts

  # TOP/LEFT inset by the halo margin; CENTER needs no explicit inset because
  # fitting reserves 2×margin horizontally, so the centring slack is ≥ margin;
  # MIDDLE relies on the em box's internal leading (see doesTextFitInExtent).
  textVerticalPosition: (heightOfText) ->
    switch @verticalAlignment
      when AlignmentSpecVertical.TOP
        @_outlineHaloMargin()
      when AlignmentSpecVertical.MIDDLE
        (@height() - heightOfText)/2
      when AlignmentSpecVertical.BOTTOM
        @height() - heightOfText - @_outlineHaloMargin()

  textHorizontalPosition: (widthOfText) ->
    switch @horizontalAlignment
      when AlignmentSpecHorizontal.LEFT
        @_outlineHaloMargin()
      when AlignmentSpecHorizontal.CENTER
        @width()/2 - widthOfText/2
      when AlignmentSpecHorizontal.RIGHT
        @width() - widthOfText - @_outlineHaloMargin()


  # Draw ONE complete line of text at (x, y): when hasDarkOutline, first stamp
  # the black halo copies, then the line itself in @color. This is the ONE home
  # of the outline — StringWdgt's single-line paint and TextWdgt's
  # wrapped-lines loop both draw every line through here.
  #
  # The halo is TWO 8-neighbourhood rings of black copies (plus the centre
  # one): the ±1.5 ring gives the halo its reach under native AA; the ±1 ring
  # is made of exact integer translates, which SWCanvas's round-to-integer
  # glyph placement preserves symmetrically, guaranteeing every white pixel
  # a contour there too — ±1.5 alone rounds lopsided under SWCanvas
  # (JS round-half-up: +1.5 → +2 but -1.5 → -1), which speckled the halo.
  _drawTextLine: (backBufferContext, line, x, y) ->
    if @hasDarkOutline
      backBufferContext.fillStyle = Color.BLACK.toString()
      backBufferContext.fillText line, x+0, y+0
      for r in [1, 1.5]
        backBufferContext.fillText line, x+r, y+0
        backBufferContext.fillText line, x-r, y+0
        backBufferContext.fillText line, x+0, y+r
        backBufferContext.fillText line, x+r, y+r
        backBufferContext.fillText line, x-r, y+r
        backBufferContext.fillText line, x+0, y-r
        backBufferContext.fillText line, x+r, y-r
        backBufferContext.fillText line, x-r, y-r
    backBufferContext.fillStyle = @color.toString()
    backBufferContext.fillText line, x, y

  # Shared by StringWdgt and TextWdgt (which extends StringWdgt): set the text
  # font/alignment on the freshly-created back-buffer context and, if a background
  # colour is set, fill it. Operates entirely within the caller's
  # useLogicalPixelsUntilRestore() scope. Kept byte-identical across both sites.
  _prepareTextBufferContext: (backBufferContext) ->
    backBufferContext.useLogicalPixelsUntilRestore()
    backBufferContext.font = @buildCanvasFontProperty()
    backBufferContext.textAlign = "left"
    backBufferContext.textBaseline = "bottom"

    # paint the background so we have a better sense of
    # where the text is fitting into.
    # This fillRect is passed logical pixels rather than actual pixels
    # (contrary to most direct canvas calls elsewhere in the codebase).
    # This is because it's inside the scope of the
    # "useLogicalPixelsUntilRestore()".
    if @backgroundColor
      backBufferContext.save()
      backBufferContext.fillStyle = @backgroundColor.toString()
      backBufferContext.globalAlpha = @backgroundTransparency
      backBufferContext.fillRect  0,
          0,
          Math.round(@width()),
          Math.round(@height())
      backBufferContext.restore()


  # Shared by StringWdgt and TextWdgt: draw the "header line" — two horizontal
  # rule segments flanking the text. The four geometry values are passed in
  # because the same-named locals mean slightly different things at each call
  # site (single fitting line here vs one wrapped line in TextWdgt), so only the
  # drawing itself is factored out (honouring the TODO in TextWdgt._createRefreshOrGetBackBuffer).
  _drawHeaderUnderline: (backBufferContext, textVerticalPosition, heightOfText, textHorizontalPosition, widthOfText) ->
    backBufferContext.strokeStyle = (Color.create 198, 198, 198).toString()
    backBufferContext.beginPath()
    backBufferContext.moveTo 0, textVerticalPosition - heightOfText / 2
    backBufferContext.lineTo textHorizontalPosition - 5, textVerticalPosition - heightOfText / 2
    backBufferContext.moveTo textHorizontalPosition + widthOfText + 5, textVerticalPosition - heightOfText / 2
    backBufferContext.lineTo @width(), textVerticalPosition - heightOfText / 2
    backBufferContext.stroke()


  # no changes of position or extent should be
  # performed in here
  _createRefreshOrGetBackBuffer: ->

    cacheKey = @createBufferCacheKey @horizontalAlignment, @verticalAlignment
    cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
    if cacheHit?
      # we might have hit a previously cached
      # backBuffer but here we are interested in
      # knowing whether the buffer we are gonna paint
      # is the same as the one being shown now. If
      # not, then we mark the caret as broken.
      if @backBuffer != cacheHit[0]
        world.caret?.noteTextChanged()
      return cacheHit

    # public-call-sanctioned: reflowText is macro-called public text API (see _sizeToTextAndDisableFittingNoSettle).
    @reflowText()

    # if we are calculating a new buffer then
    # for sure the caret has to be notified
    world.caret?.noteTextChanged()

    text = @textPossiblyCroppedToFit
    # Initialize my surface property.
    # If don't have to paint the background then the surface is just as
    # big as the text - which is likely to be smaller than the whole widget
    # (because it needs to fit in both height and width, it's likely that
    # it's gonna be smaller in one of the two dimensions).
    # If, on the other hand, we have to paint the background then the surface is
    # as big as the whole widget,
    # so potentially we could be wasting some space as the string might
    # be really small so to fit, say, the width, while a lot of height of
    # the widget could be "wasted" in memory.
    widthOfText = @calculateTextWidth text
    heightOfText = @fontHeight @fittingFontSize
    if @backgroundColor? or
     @verticalAlignment != AlignmentSpecVertical.TOP or
     @horizontalAlignment != AlignmentSpecHorizontal.LEFT or
     @fittingSpecWhenBoundsTooLarge == FittingSpecTextInLargerBounds.FLOAT
      width = @width()
      height = @height()
    else
      width = widthOfText + 2 * @_outlineHaloMargin()
      height = heightOfText + 2 * @_outlineHaloMargin()

    backBuffer = HTMLCanvasElement.createOfPhysicalDimensions (new Point width, height).scaleBy ceilPixelRatio

    backBufferContext = backBuffer.getContext "2d"

    @_prepareTextBufferContext backBufferContext


    textVerticalPosition = @textVerticalPosition(@fontHeight @fittingFontSize) + @fontHeight(@fittingFontSize)
    textHorizontalPosition = @textHorizontalPosition widthOfText

    # NB: no SHADOW is baked into this buffer. hasDarkOutline (honoured inside
    # _drawTextLine) is an OUTLINE (offset black glyph copies, for legibility
    # against busy backgrounds), NOT a shadow. A text widget's shadow is the
    # unified widget drop-shadow (see Widget.coffee "How the shadow painting
    # works" + addShadow); a per-glyph shadowOffset/shadowColor route is
    # deliberately not used here.
    @_drawTextLine backBufferContext, text, textHorizontalPosition, textVerticalPosition

    # header line
    if @isHeaderLine
      @_drawHeaderUnderline backBufferContext, textVerticalPosition, heightOfText, textHorizontalPosition, widthOfText




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
      backBufferContext.fillStyle = @markedBackgroundColor.toString()
      backBufferContext.fillRect p.x, p.y, Math.ceil(@measureText nil, c) + 1, Math.ceil @fontHeight @fittingFontSize
      backBufferContext.fillStyle = @markedTextColor.toString()
      backBufferContext.fillText c, p.x, p.y + Math.ceil @fontHeight @fittingFontSize
    
  
  # StringWdgt measuring:
  slotCoordinates: (slot) ->
    # PURE geometry: the position point of the given index ("slot") -- no side effects.
    # (used to fire one here; moved to handOffToPopoutEditorIfOverflowing -- see docs/archive/layout-system-architecture-assessment.md.)

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

    textVerticalPosition = @textVerticalPosition @fontHeight @fittingFontSize
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
        if Math.abs(xPosition - @left() - charXMinusOne) < Math.abs(xPosition - @left() - charX)
          return idx - 1
        break

      charXMinusOne = charX
      charX += @calculateTextWidth text[idx]

      idx += 1
      if idx is text.length
        if ((@calculateTextWidth(text)) - ((@calculateTextWidth(text[idx-1])) / 2)) < (xPosition - @left())
          return idx
    idx

  pointIsAboveFirstLine: (aPoint) ->
    textVerticalPosition = @textVerticalPosition @fontHeight @fittingFontSize

    if aPoint.y - @top() < textVerticalPosition
      return 0

    return false

  pointIsUnderLastLine: (aPoint) ->
    textVerticalPosition = @textVerticalPosition(@fontHeight @fittingFontSize) + @fontHeight(@fittingFontSize)

    # if pointer is below the line, the slot is at
    # the last character.
    if (aPoint.y - textVerticalPosition) - @top() > Math.ceil @fontHeight @fittingFontSize
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

  # SELF-SETTLES via the single @_settleLayoutsAfter, like the other text setters. From a font menu it
  # ALSO re-ticks the sibling menu items, but updateFontsMenuEntriesTicks does that through the
  # NON-settling label core (menu.rowsPanel.children[i].label._setTextNoSettle), so it does NOT nest another
  # settling setter -- the menu items' re-fit rides this single settle (or popUpAtHand's, when the menu
  # is still being built on the hand).
  setFontName: (menuItem, ignored2, theNewFontName) ->
    @_settleLayoutsAfter => @_setFontNameNoSettle menuItem, ignored2, theNewFontName

  # The NON-settling core of setFontName -- used by low-level builders that configure a contained text
  # widget while assembling it (e.g. InspectorWdgt's detail pane, inside its own rebuild settle). The public
  # setFontName self-settles over this; low-level code reaches the core directly (cores call cores).
  _setFontNameNoSettle: (menuItem, ignored2, theNewFontName) ->
    if @fontName != theNewFontName
      @fontName = theNewFontName
      @_changed()

      # was `menuItem.parent instanceof MenuWdgt` (type-test-elimination campaign)
      if menuItem?.parent? and menuItem.parent.isMenu?()
        @updateFontsMenuEntriesTicks menuItem.parent
    @_reflowContainedTextThenInvalidateLayout()


  fontsMenu: (a,targetWidget)->
    menu = new MenuWdgt @, target: targetWidget, title: "Fonts"

    menu.addMenuItem untick + "Arial", @, "setFontName", arg1: @justArialFontStack
    menu.addMenuItem untick + "Times", @, "setFontName", arg1: @timesFontStack
    menu.addMenuItem untick + "Georgia", @, "setFontName", arg1: @georgiaFontStack
    menu.addMenuItem untick + "Garamo", @, "setFontName", arg1: @garamoFontStack
    menu.addMenuItem untick + "Helve", @, "setFontName", arg1: @helveFontStack
    menu.addMenuItem untick + "Verda", @, "setFontName", arg1: @verdaFontStack
    menu.addMenuItem untick + "Treby", @, "setFontName", arg1: @trebuFontStack
    menu.addMenuItem untick + "Heavy", @, "setFontName", arg1: @heavyFontStack
    menu.addMenuItem untick + "Mono", @, "setFontName", arg1: @monoFontStack

    @updateFontsMenuEntriesTicks menu

    menu.popUpAtHand()

  # [ fontStackPropertyName, menuLabel ] rows in fonts-menu order (menu.rowsPanel.children[1..9]);
  # drives updateFontsMenuEntriesTicks below. Kept a simple literal for the fragment-compile
  # gate. NB the index-7 label "Treby" intentionally differs from its trebuFontStack prop name.
  @FONT_STACK_MENU_ENTRIES: [
    [ "justArialFontStack", "Arial"   ]
    [ "timesFontStack",     "Times"   ]
    [ "georgiaFontStack",   "Georgia" ]
    [ "garamoFontStack",    "Garamo"  ]
    [ "helveFontStack",     "Helve"   ]
    [ "verdaFontStack",     "Verda"   ]
    [ "trebuFontStack",     "Treby"   ]
    [ "heavyFontStack",     "Heavy"   ]
    [ "monoFontStack",      "Mono"    ]
  ]

  # cheap way to keep menu consistency when pinned
  # note that there is no consistency in case
  # there are multiple copies of this menu changing
  # the property, since there is no real subscription
  # of a menu to react to property change coming
  # from other menus or other means (e.g. API)...
  updateFontsMenuEntriesTicks: (menu) ->
    # tick the single entry whose font stack equals the current @fontName, untick the rest.
    # the rows live in the menu's rowsPanel now (index 0 is the title header, 1..9 the font
    # items) -- the same order the menu's own children had before it composed the panel.
    rows = menu.rowsPanel.children
    for [ fontStackProperty, menuLabel ], i in StringWdgt.FONT_STACK_MENU_ENTRIES
      tickMark = if @fontName == @[fontStackProperty] then tick else untick
      rows[i + 1].label._setTextNoSettle tickMark + menuLabel


  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "edit...", @, "editPopup", toolTip: "set this String's\ncontent"
    menu.addMenuItem "font size...", @, "fontSizePopup", toolTip: "set this String's\nfont point size"

    menu.addMenuItem "font ➜", @, "fontsMenu", closesUnpinnedPopUps: false, toolTip: "pick a font"

    if @isBold
      menu.addMenuItem "normal weight", @, "toggleWeight"
    else
      menu.addMenuItem "bold", @, "toggleWeight"

    if @isItalic
      menu.addMenuItem "non-italic", @, "toggleItalic"
    else
      menu.addMenuItem "italic", @, "toggleItalic"

    if @isHeaderLine
      menu.addMenuItem "no header line", @, "toggleHeaderLine"
    else
      menu.addMenuItem "header line", @, "toggleHeaderLine"


    if @isPassword
      menu.addMenuItem "show characters", @, "toggleIsPassword"
    else
      menu.addMenuItem "hide characters", @, "toggleIsPassword"

    menu.addLine()
    if @horizontalAlignment != AlignmentSpecHorizontal.LEFT
      menu.addMenuItem "← align left", @, "alignLeft"
    if @horizontalAlignment != AlignmentSpecHorizontal.CENTER
      menu.addMenuItem "∸ align center", @, "alignCenter"
    if @horizontalAlignment != AlignmentSpecHorizontal.RIGHT
      menu.addMenuItem "→ align right", @, "alignRight"

    menu.addLine()
    if @verticalAlignment != AlignmentSpecVertical.TOP
      menu.addMenuItem "↑ align top", @, "alignTop"
    if @verticalAlignment != AlignmentSpecVertical.MIDDLE
      menu.addMenuItem "⍿ align middle", @, "alignMiddle"
    if @verticalAlignment != AlignmentSpecVertical.BOTTOM
      menu.addMenuItem "↓ align bottom", @, "alignBottom"

    menu.addLine()

    if @fittingSpecWhenBoundsTooLarge == FittingSpecTextInLargerBounds.SCALEUP
      menu.addMenuItem "←☓→ don't expand to fill", @, "togglefittingSpecWhenBoundsTooLarge"
    else
      menu.addMenuItem "←→ expand to fill", @, "togglefittingSpecWhenBoundsTooLarge"

    if @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.CROP
      menu.addMenuItem "→← shrink to fit", @, "togglefittingSpecWhenBoundsTooSmall"
    else
      menu.addMenuItem "→⋯← crop to fit", @, "togglefittingSpecWhenBoundsTooSmall"

    if world.isIndexPage
      menu.addLine()
      if world.isIndexPage
        menu.addMenuItem "connect to ➜", @, "openTargetSelector", toolTip: "connect to\nanother widget"
      else
        menu.addMenuItem "set target", @, "openTargetSelector", toolTip: ("choose another widget\nwhose numerical property\n will be" + " controlled by this one")
    @addFiresPerEventMenuEntry menu


  togglefittingSpecWhenBoundsTooSmall: ->
    @fittingSpecWhenBoundsTooSmall = not @fittingSpecWhenBoundsTooSmall
    @_changed()
    world.stopEditing()

  togglefittingSpecWhenBoundsTooLarge: ->
    world.stopEditing()
    @fittingSpecWhenBoundsTooLarge = not @fittingSpecWhenBoundsTooLarge
    @_changed()

  
  toggleShowBlanks: ->
    @_settleLayoutsAfter =>
      @isShowingBlanks = not @isShowingBlanks
      @_changed()
      @_reflowContainedTextThenInvalidateLayout()

  toggleWeight: ->
    @_settleLayoutsAfter =>
      @isBold = not @isBold
      @_changed()
      @_reflowContainedTextThenInvalidateLayout()

  toggleItalic: ->
    @_settleLayoutsAfter =>
      @isItalic = not @isItalic
      @_changed()
      @_reflowContainedTextThenInvalidateLayout()

  toggleHeaderLine: ->
    @isHeaderLine = not @isHeaderLine
    @_changed()
  
  toggleIsPassword: ->
    world.stopEditing()
    @_settleLayoutsAfter =>
      @isPassword = not @isPassword
      @_changed()
      @_reflowContainedTextThenInvalidateLayout()

  _changed: ->
    super
    world.caret?.noteTextChanged()
  
  # adjust the data models behind the text. E.g.
  # is it going to be shown as cropped? What size
  # is it going to be? How is the text broken down
  # into rows?
  # this method doesn't draw anything.
  reflowText: ->
    @_synchroniseTextAndActualText()
    # FIT_BOX_TO_TEXT sizes the BOX to the text at the SET font size (see
    # TextWdgt::_reLayoutSelf), so the font must NOT be scaled — render at
    # @originallySetFontSize. We must skip fitToExtent here because its
    # scale-up/scale-down search is broken FOR this mode: the FIT_BOX_TO_TEXT
    # render leaks force every fit-measurement to @originallySetFontSize, so
    # searchLargestFittingFont sees "every candidate size fits" and returns the
    # MAXIMUM (a giant font). SimpleTextWdgt sidesteps this because its ctor
    # pins fittingSpecWhenBoundsTooLarge = FLOAT (no scale-up search); a bare
    # TextWdgt defaults to SCALEUP, so the mode itself must force the set size.
    if @fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
      @_setFittingFontSize @originallySetFontSize
    else
      @_setFittingFontSize @fitToExtent()

  # Make "the BOX sizes itself to the TEXT" behaviour for chrome labels (menu
  # items, menu headers, tooltips, plain buttons). The default model does the
  # OPPOSITE — it fits the TEXT into a FIXED box and never resizes its own extent
  # (see the FITTING MODEL comment above) — so a freshly-built label is the 50×40
  # Widget default, not the width of its text. Chrome layout reads @label.extent()
  # right after construction to size its container, so each such label must
  # instead make its OWN extent track the text. This helper does that:
  #   - pin fittingSpecWhenBoundsTooLarge = FLOAT  → never grow the font;
  #   - pin fittingSpecWhenBoundsTooSmall = SCALEDOWN → never ellipsise the text
  #     and never pop the "edit:" PromptWdgt (that is gated on == CROP, see
  #     handOffToPopoutEditorIfOverflowing) and, since the box ends up == the text, never shrink it;
  #   - measure the text at its set font size and resize the box to it.
  # With box == text the "bounds too small" branch is unreachable, so neither
  # cropping, the edit-prompt, nor any font scaling ever fires — i.e. it draws
  # the text at its exact set size.
  # (TextWdgt overrides this with a multi-line, soft-wrap-off variant.)
  # PUBLIC self-settling entry for STANDALONE callers (a tick toggle on an open menu, a header/tooltip
  # build on an orphan). The IN-PASS / IN-SETTLE callers -- _createLabel (driven by _reLayoutSelf),
  # _setTextNoSettle, _setFontSizeNoSettle -- call _sizeToTextAndDisableFittingNoSettle DIRECTLY, because a single
  # self-settle reached mid-pass/mid-settle re-enters the flush guard and THROWS. That throw is the wanted
  # discipline (it surfaces a mis-routed caller); an absorbing batch settler would silently swallow it.
  # Returns @ (the core ends with @) so callers can chain -- several macros do
  # `s = (new StringWdgt ...).sizeToTextAndDisableFitting()` then `world.add s`.
  sizeToTextAndDisableFitting: ->
    @_settleLayoutsAfter => @_sizeToTextAndDisableFittingNoSettle()

  # The box-hug, minus the settle. Remembers the box-hugs-text mode (autoSizeBoxToText) so a later setText
  # (editing a button label in place) keeps the box tracking the text instead of cramming the new text into
  # the stale box. A chrome label is a freefloating child laid out by its managing container (button/menu
  # centres it in _reLayoutSelf); the generic _reFitContainer seam can't reach a non-scroll/stack container
  # and a freefloating child doesn't climb, so invalidate the managing parent explicitly (gated out-of-pass
  # -- _invalidateLayout THROWS during a pass) and let the enclosing settle flush it.
  _sizeToTextAndDisableFittingNoSettle: ->
    @autoSizeBoxToText = true
    @fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.FLOAT
    @fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    measuredWidth = @calculateTextWidth (@transformTextOneToOne @text), @originallySetFontSize
    widthOfText = Math.max (Math.ceil measuredWidth), 1
    heightOfText = @fontHeight @originallySetFontSize
    haloMargin = @_outlineHaloMargin()
    @__commitExtent new Point widthOfText + 2*haloMargin, heightOfText + 2*haloMargin
    # public-call-sanctioned: reflowText is public text API — macros call it directly
    # (macroBoxTransparencyAndColorChanging), so it stays public; consciously reused by this core.
    @reflowText()
    @parent?._invalidateLayout() unless world?._recalculatingLayouts
    @  # return self so the public wrapper is chainable (macros do `(new StringWdgt …).sizeToTextAndDisableFitting()`)

  # ── Contained-text (FIT_BOX_TO_TEXT) edit: the re-fit core ───────────────────
  # The NON-settling re-fit behind the seven text-property setters (setText / setFontSize
  # / setFontName / toggleShowBlanks / toggleWeight / toggleItalic / toggleIsPassword).
  # A FIT_BOX_TO_TEXT widget re-flows its box to the new text measure (_reLayoutSelf)
  # and, ONLY if the box actually changed size, invalidates its tracking container so it
  # re-fits (@parent._invalidateLayout, the uniform dirty-tree climb). An edit that leaves the
  # measure unchanged needs no redundant up-then-down container re-fit. For a bare StringWdgt the
  # base Widget::_reLayoutSelf is empty (box-to-text sizing lives in
  # TextWdgt::_reLayoutSelf), so the gated body is a no-op.
  _reflowContainedTextThenInvalidateLayout: ->
    return unless @fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
    extentBefore = @extent()
    @_reLayoutSelf()
    @parent?._invalidateLayout() unless @extent().equals extentBefore   # (property sub-seam deletion) invalidate the container BARE (no freefloating trigger)

  # The NON-settling core of setText: apply a text change IN PLACE -- re-hug the box if this
  # is a box-hugs-text chrome label, notify any connection target, and re-fit if contained-text
  # -- WITHOUT settling layouts. The public setText wraps this in its single self-settler; callers
  # that must set text WITHOUT opening a settle -- because they run INSIDE another settle or a
  # LAYOUT PASS -- call this directly ("cores call cores"): structural re-titles (FrameWdgt.
  # _addNoSettle / _setEmptyWindowLabelNoSettle), layout code (AxisWdgt._reLayout's tick labels),
  # menu re-ticking (updateFontsMenuEntriesTicks), per-frame updates (the video time labels). The
  # change rides the enclosing settle / the frame's recalculateLayouts. The stringFieldWidget
  # decoding is setText-specific and stays in setText (these callers pass plain text, so the core
  # needs none).
  _setTextNoSettle: (theTextContent) ->
    theNewText = theTextContent + ""
    if @text != theNewText
      # other widgets might send something like a
      # number or a color so let's make sure we
      # convert to a string.
      # public-call-sanctioned: clearSelection is the public text-selection API (driven
      # cross-object by the caret machinery) — settle-free, consciously reused by this core.
      @clearSelection()
      @text = theNewText
      @checkIfTextContentWasModifiedFromTextAtStart()
      @_synchroniseTextAndActualText()
      # chrome labels (menu items, button captions, …) keep their box hugging the
      # text on every edit; without this the new text would be crammed/scaled into
      # the box sized to the OLD text. Generic StringWdgts leave the flag off and
      # keep their fixed box.
      if @autoSizeBoxToText
        # _setTextNoSettle always runs inside an enclosing settle → the NoSettle core (the public
        # self-settling wrapper would re-enter the flush guard and throw).
        @_sizeToTextAndDisableFittingNoSettle()
      @_changed()
    @updateTarget()
    @_reflowContainedTextThenInvalidateLayout()

  # This is also invoked for example when you take a slider
  # and set it to target this.
  #
  # SELF-SETTLES via the single @_settleLayoutsAfter -- the ordinary self-settling-setter convention.
  # It is thin-wrap-exempt only because it does arg-decoding FIRST (the stringFieldWidget unwrap), so it
  # is not the BARE canonical wrap. Single is SAFE here because the one
  # flow that used to reach setText MID-PASS -- a window RE-TITLING its label from inside an add's settle
  # -- now calls @_setTextNoSettle DIRECTLY (see FrameWdgt._addNoSettle), so NO flow reaches setText
  # under a layout pass anymore (VERIFIED: full suite green with the single settler). The single settler's
  # flow-violation throw stays as the NET: if some future caller (e.g. a connection's updateTarget
  # dynamically dispatching to setText) reaches it mid-pass, it SURFACES the violation rather than
  # silently deferring it.
  # thin-wrap-exempt: decodes the stringFieldWidget arg before the single-settle delegate.
  setText: (theTextContent, stringFieldWidget) ->
    if stringFieldWidget?
      # in this case, the stringFieldWidget has a
      # string widget in "text". The string widget has the
      # "text" inside it.
      theTextContent = stringFieldWidget.text.text
    @_settleLayoutsAfter =>
      @_setTextNoSettle theTextContent

  # The reactive-CONNECTOR entrypoint for setText (the connection lane -- see Widget.
  # _settleLayoutsAfterOrJoinEnclosingPass and check-layering [P]). IDENTICAL to the public setText -- same
  # stringFieldWidget decode -- EXCEPT it JOINS an already-open layout pass instead of opening a nested settle
  # (which the public setText's _settleLayoutsAfter would reject mid-pass). The engine's edge apply
  # (DataflowEngine._applyWireValue) routes wired "setText" deliveries here; direct/API callers keep using the
  # public setText.
  _setTextConnector: (theTextContent, stringFieldWidget) ->
    if stringFieldWidget?
      theTextContent = stringFieldWidget.text.text
    @_settleLayoutsAfterOrJoinEnclosingPass =>
      @_setTextNoSettle theTextContent

  considerCurrentTextAsReferenceText: ->
    @hashOfTextConsideredAsReference = @text.hashCode()

  checkIfTextContentWasModifiedFromTextAtStart: ->
    if @widgetToBeNotifiedOfTextModificationChange?
      if @hashOfTextConsideredAsReference == @text.hashCode()
        @widgetToBeNotifiedOfTextModificationChange.textContentUnmodified?()
      else
        @widgetToBeNotifiedOfTextModificationChange.textContentModified?()
  
  _setFontSizeNoSettle: (sizeOrWidgetGivingSize, widgetGivingSize) ->
    if widgetGivingSize?.getValue?
      size = widgetGivingSize.getValue()
    else
      size = sizeOrWidgetGivingSize

    if typeof size is "number"
      newSize = Math.round Math.min Math.max(size, 4), 500
    else
      newSize = parseFloat size
      newSize = Math.round Math.min Math.max(newSize, 4), 500  unless isNaN newSize

    if newSize != @originallySetFontSize
      @originallySetFontSize = newSize
      # a box-hugs-text widget (e.g. a chrome label) must track its text size on a
      # font change too; otherwise the bigger/smaller font would just be fitted
      # into the box sized for the old font.
      if @autoSizeBoxToText
        # this core always runs in-settle (the public setFontSize / _setFontSizeConnector each wrap it) → the NoSettle sibling.
        @_sizeToTextAndDisableFittingNoSettle()
      @_changed()
    @_reflowContainedTextThenInvalidateLayout()

  setFontSize: (sizeOrWidgetGivingSize, widgetGivingSize) ->
    @_settleLayoutsAfter => @_setFontSizeNoSettle sizeOrWidgetGivingSize, widgetGivingSize

  # The reactive-CONNECTOR entrypoint for setFontSize (see _setTextConnector above / check-layering [P]).
  # setFontSize is a SINK -- it never calls updateTarget, so a circuit cannot cycle through it.
  _setFontSizeConnector: (sizeOrWidgetGivingSize, widgetGivingSize) ->
    @_settleLayoutsAfterOrJoinEnclosingPass =>
      @_setFontSizeNoSettle sizeOrWidgetGivingSize, widgetGivingSize

  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    @_popUpTargetPropertyMenu theTarget, theTarget.stringSetters()
  
  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, ["alpha 0-100", "font size", "text"], ["setAlphaScaled", "setFontSize", "setText"]
  
  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, ["bang!", "text"], ["bang", "setText"]

  updateTarget: ->
    @_fireConnection @text
    return

  reactToTargetConnection: ->
    @updateTarget()

  
  # On Enter, a single-line StringWdgt commits (accept); subclasses override this to
  # false so multi-line/derived text inserts a newline instead. The caret keys off
  # this rather than an exact class-name check. (type-test-elimination campaign)
  enterKeyAccepts: ->
    true

  # I am an editable text entry field -- used by Widget.allEntryFields for Tab navigation.
  # True for the whole StringWdgt family (replaces an `instanceof StringWdgt`). (type-test-elimination campaign)
  isTextEntryField: ->
    true

  # StringWdgt editing:
  # thin-wrap-exempt: edit BRANCHES (inline world.edit when the text fits, else editPopup) and returns a fit
  # flag -- not the bare @_settleLayoutsAfter => @_editNoSettle wrap. Its NoSettle sibling _editNoSettle below
  # mirrors the branch, routing the inline case to world._editNoSettle (the drain-safe caret core).
  edit: ->
    if @textPossiblyCroppedToFit == @transformTextOneToOne @text
      world.edit @
      return true
    else
      @editPopup()
      return nil

  # The NoSettle sibling of edit, for a caller already inside a layout flush/pass -- a dataflow connection sink
  # delivering into a prompt slider's editable field (PromptWdgt._takeSliderValueConnector). Routes the
  # inline-edit case to world._editNoSettle (the non-settling caret core, joining the enclosing settle); the
  # overflow branch hands off to editPopup exactly as edit does (not reached for a short prompt value, which
  # fits inline).
  _editNoSettle: ->
    if @textPossiblyCroppedToFit == @transformTextOneToOne @text
      world._editNoSettle @
      return true
    else
      @editPopup()
      return nil

  # When inline editing and the just-grown text no longer fits a CROP-overflow field, abandon inline
  # editing and hand off to the pop-out editor (stopEditing tears down the inline caret; edit() then
  # routes to editPopup() because the text no longer fits). Returns true if it handed off. PURE
  # PREDICATE, OFF the layout flush: called from CaretWdgt.insert (the only place editing can GROW
  # the text) right after setText, at event time -- edit() on an already-overflowing field goes
  # straight to editPopup(), so insert is the only way to exceed CROP inline. History (why this
  # moved off slotCoordinates): see docs/archive/layout-system-architecture-assessment.md.
  handOffToPopoutEditorIfOverflowing: ->
    return false unless @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.CROP
    return false if @textPossiblyCroppedToFit == @transformTextOneToOne @text
    world.stopEditing()
    @edit()
    return true

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
    @_changed()

  _setEndMark: (slot) ->
    @endMark = slot
    @_changed()
  
  selectBetween: (start, end) ->
    @startMark = Math.min start, end
    @endMark = Math.max start, end
    @_changed()
  
  deleteSelection: ->
    start = Math.min @startMark, @endMark
    stop = Math.max @startMark, @endMark
    @setText @text.slice(0, start) + @text.slice(stop)

  selectAll: ->
    @startMark = 0
    @endMark = @textPossiblyCroppedToFit.length
    @_changed()

  # used when shift-clicking somewhere when there is
  # no selection ongoing
  startSelectionUpToSlot: (previousCaretSlot, slotToExtendTo) ->
    @startMark = previousCaretSlot
    @endMark = slotToExtendTo
    @_changed()

  # used when shift-clicking somewhere when there is
  # already a selection ongoing
  extendSelectionUpToSlot: (slotToExtendTo) ->
    @endMark = slotToExtendTo
    @_changed()

  # Caret-driven selection (shift + arrow / Home / End): anchor a fresh selection at slot if none
  # is ongoing, otherwise move the moving end to slot. Distinct from the shift-CLICK pair above
  # (startSelectionUpToSlot / extendSelectionUpToSlot, which carry the click's previous caret slot)
  # -- this one grows the selection to wherever the caret just moved. Used to be done inside
  # CaretWdgt.updateSelection by reading @target.startMark / @target.endMark directly. (Phase 7a)
  anchorOrExtendSelectionTo: (slot) ->
    if (!@endMark?) and (!@startMark?)
      @selectBetween slot, slot
    else if @endMark isnt slot
      @_setEndMark slot

  # Collapse a zero-width selection (the two marks met) back to no selection. Used to be done in
  # CaretWdgt.clearSelectionIfStartAndEndMeet by reading the marks directly. (Phase 7a)
  clearSelectionIfCollapsed: ->
    if @startMark == @endMark
      @clearSelection()

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
  mouseClickLeft: (pos, arg2, arg3, arg4, shiftKey, arg6, arg7, arg8, arg9) ->
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
        @rememberCaretColumn world.caret.slot

    else
      @escalateEvent "mouseClickLeft", pos, arg2, arg3, arg4, shiftKey, arg6, arg7, arg8, arg9
  
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
          @_changed()
      else
        @_disableSelecting()
  
  _disableSelecting: ->
    # public-call-sanctioned: clearSelection is the public text-selection API (see _setTextNoSettle).
    # re-establish the original definition of the method
    @clearSelection()
    @mouseDownLeft = StringWdgt::mouseDownLeft
    delete @mouseMove


  
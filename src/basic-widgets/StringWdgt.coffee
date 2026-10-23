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

  # CLICKING TEXT MEANS CLICKING THE LINE, not the strokes — so my whole box takes the pointer,
  # un-shadowing BackBufferMixin's per-pixel probe (a class-body member out-ranks a mixin's).
  # This is not a nicety: 97% of a string's box is ink-free (measured on a 50×40 StringWdgt —
  # 1946 of 2000 px), so per-pixel hit-testing would make text clickable only between the
  # letters' own strokes, and dropping this would silently do exactly that.
  #   Dressed as an ITEM (THE ITEM SHAPE, below) my box is a rounded block, pressed as a whole, and
  # it takes the pointer where its fill is: a logical pixel is mine iff its centre lies inside the
  # rounded outline (BoxyAppearance.roundedBoxContainsPixelCentreOf, the one rounded hit test), so a
  # corner's notch lets a press through to the page under it, as every rounded box's does.
  catchesPointerAt: (aPoint) ->
    cornerRadius = @_itemShape()?.cornerRadius
    return @boundsContainPoint aPoint unless cornerRadius?
    (@boundsContainPoint aPoint) and BoxyAppearance.roundedBoxContainsPixelCentreOf (aPoint.subtract @position()), @width(), @height(), [cornerRadius, cornerRadius, cornerRadius, cornerRadius]

  # a line of text is "text" to a person ("string" is a programmer's word); my subclasses inherit
  # it, so one that is something more than a text names itself
  colloquialName: ->
    "text"

  # I drive text, and the text I export is my `text` pin (see `pins`, below).
  # ⚠ "string", not "numerical": the target-property menu I open offers my target's STRING pins,
  # because a text widget drives text. SimpleTextWdgt's set-target tooltip said "numerical" — the
  # other, disagreeing half of what is now this one declaration.
  producesPinKind: "string"
  principalPinLabel: "text"

  # clear unadulterated text
  text: ""
  # the text as it actually shows.
  # It might have undergone transformations
  # and cropping.
  textPossiblyCroppedToFit: ""

  fittingFontSize: undefined
  originallySetFontSize: undefined

  # MY LINE BOX's height (see linePitch) and the font size it is stated at. Undefined = unset: my
  # lines stack at the font's em box. A font role may carry it as its `lineHeight` member, stated
  # at the role's size; an explicit `lineHeight` option is stated at the size I am set in, and so
  # is a line height given no stated size.
  lineHeight: undefined
  lineHeightStatedAtFontSize: undefined

  # MY INK: no colour of my own until one is given to me (the `color` option, setColor) --
  # declared here over Widget's content default. While I hold none I paint in the ink my parent
  # gives me, or else the theme's defaultTextInk (_textInk), read as I paint each line
  # (_drawTextLine) and in my buffer's key, so a text saved, loaded or duplicated without a colour
  # of its own wears the ink of the world it is shown in.
  color: undefined

  fontName: undefined
  isBold: undefined
  # THE WEIGHT MY FIT IS MEASURED IN, where isBold is the weight I draw in: every fit decision of
  # mine -- whether I show whole, how much of me a crop keeps (numberOfCharactersThatFit), the size
  # a scaling fit picks -- measures me in it (doesTextFitInExtent). Undefined measures me in the
  # weight I draw in, as every text is but a frame's title: a window's title is measured in the
  # weight it wears when its window is FOCUSED (FrameWdgt._frameLook's titleFitBold), so a focus
  # flip, which changes the weight it draws in, never changes which characters it shows. My
  # single-line fit reads it; a TextWdgt fits through its wrap, in the weight it draws in.
  fitBold: undefined
  isItalic: undefined
  isHeaderLine: undefined
  isEditable: false
  # may the user drag-select my text? (see enableSelecting). A serializable MODE
  # consumed by the prototype pressBegan/hoverMoved/pressMoved handlers -- NOT a pair of
  # instance-assigned handler functions, which selection long was: an own function
  # property has no editable source, so any selecting-enabled text in a snapshot's
  # graph (every document, text panel, patch-programming pane...) crashed
  # serializeWorldSnapshot.
  isSelectable: false
  # if "isNumeric", it rejects all inputs
  # other than numbers and "-" and "."
  isNumeric: undefined
  isPassword: false
  # HOW MY TEXT SHOWS, as a case over the words I store: undefined shows them as they are, "upper"
  # every character in capitals, "sentence" the first character in capitals and the rest as they
  # are. A DISPLAY case, never written into `text`: every reader of `text` reads the stored words,
  # while every measure, fit, wrap, paint and back-buffer key of mine reads the shown form through
  # transformTextOneToOne, so a box that hugs me hugs what shows. A password shows no case.
  displayCase: undefined

  # Used for when the cursor movement causes the
  # text to scroll, so that the caret is in-view when
  # used, say, on a text in a ViewportWdgt.
  isScrollable: true

  # When true, the box re-sizes itself to its text on every setText ("box hugs
  # text" behaviour). Set by sizeToTextAndDisableFitting; OFF by default so a
  # generic StringWdgt in a layout still fits its text into its FIXED box (the
  # modern model). See sizeToTextAndDisableFitting for why the chrome labels
  # need this.
  autoSizeBoxToText: false

  # When true, this widget NEVER hands its edit off to the pop-out "edit:" prompt: entering
  # an edit stays inline even when the text is already ellipsised (edit/_editNoSettle skip
  # their CROP branch), and GROWING past the box mid-edit keeps the inline caret
  # (handOffToPopoutEditorIfOverflowing declines) — the display simply stays ellipsised,
  # with the caret clamping at the box edge. For editors that live INSIDE a fixed-geometry
  # host whose commit semantics a pop-out would bypass (the spreadsheet cell editor: Enter
  # must commit to the CELL, a prompt window has no such wiring). A plain boolean, so a
  # mid-edit snapshot carries it harmlessly.
  alwaysEditsInline: false

  # startMark and endMark contain the slot of the
  # slot first selected IN TIME, not "in space".
  # i.e. startMark might be higher than endMark if
  # text had been selected starting from the
  # right and "going left"
  startMark: undefined
  endMark: undefined

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
  # sub-axes refine it (both part of createBufferCacheKey):
  #   - TIGHT or LOOSE: the box is exactly the text's extent (tight), or that extent
  #     plus a padding margin (loose: where the text lives dresses it as an ITEM, as a
  #     document dresses its text items). Not stored: asked of the text's container at
  #     every measure, paint and point mapping (THE ITEM SHAPE, below).
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
  # The FIT_BOX_TO_TEXT sub-axis that is stored (honoured by TextWdgt::_reLayoutSelf, keyed into
  # the buffer-cache key). It had two values but only one ever shipped, so it is inlined here as a
  # raw boolean rather than carrying a single-valued spec class. Re-introduce a named axis only if
  # a second value ships. (The tight-or-loose sub-axis is derived, never stored: THE ITEM SHAPE.)
  #   HEIGHT_ADJUSTS_TO_WIDTH: true = width is given, height follows the wrapped lines.
  #     (was FittingSpecTextBoxFittingTextWhichDimensionAdjusts.HEIGHT_ADJUSTS_TO_WIDTH;
  #      WIDTH_ADJUSTS_TO_HEIGHT=false never shipped.)
  fittingSpecBoxWhichDimensionAdjusts: true

  caretHorizPositionForVertMovement: undefined

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

  hashOfTextConsideredAsReference: undefined
  widgetToBeNotifiedOfTextModificationChange: undefined

  undoHistory: undefined
  redoHistory: undefined

  # The text is the identity — what this widget SHOWS, and the one argument every caller
  # passes. Everything else, font SIZE included, is an independently-optional knob and rides
  # `opts` (docs/architecture/constructor-and-parameter-conventions.md).
  #
  # Size is an option and not a second positional because the hole test (R3) says so: measured
  # across the family's construction sites, only ~28% pass a size, while ~50 would have had to
  # pass `undefined` THROUGH it to reach a colour. The tuple that would justify a positional
  # pair does not exist here — a size is just the most popular of nine knobs.
  #
  # NONE of these is a `@param`: a `@param` assigns its field unconditionally, which is the
  # trap this class's own backgroundColor guard was written to dodge (§3.2 of
  # widget-authoring-guidelines.md). Reading options in the body puts the guard in plain sight.
  #
  # `?` and not a parameter default, so an explicit "" survives as a real value while an
  # omitted argument still gets "StringWdgt".
  #
  # The FONT comes as a ROLE: `fontRole` is one of WorldWdgt.theme.fonts' {family, size, bold}
  # objects, and gives all three at once. An explicit fontName / fontSize / bold still wins over
  # the role's member, so a caller can take a role and override one member of it. A text built
  # without a role takes the defaultText role. The role is read here and not kept: I hold the
  # three values I render with. A role may also state a line height (`lineHeight`, at the role's
  # size), and so may an explicit `lineHeight` option (at the size I am set in): I hold it with
  # the size it is stated at, and only when one is given, so a text without one keeps the class's
  # unset default. A role may also carry `italic`, which an explicit `italic` overrides. A
  # `fitBold` gives the weight my fit is measured in (fitBold, above), and only when passed, so a
  # text given none is measured in the weight it draws in.
  constructor: (text, opts = {}) ->
    @text = text ? "StringWdgt"
    fontRole = opts.fontRole ? WorldWdgt.theme.fonts.defaultText
    @originallySetFontSize = opts.fontSize ? fontRole.size
    @fontName = opts.fontName ? fontRole.family
    @isBold = opts.bold ? fontRole.bold
    @fitBold = !!opts.fitBold if opts.fitBold?
    if opts.lineHeight?
      @lineHeight = opts.lineHeight
      @lineHeightStatedAtFontSize = @originallySetFontSize
    else if fontRole.lineHeight?
      @lineHeight = fontRole.lineHeight
      @lineHeightStatedAtFontSize = fontRole.size
    @isItalic = opts.italic ? fontRole.italic ? false
    @isHeaderLine = opts.headerLine ? false
    @isNumeric = opts.numeric ? false
    # only when passed, so a text given no ink keeps the class's: none, and paints in the theme's
    # default text ink
    @color = opts.color if opts.color?
    # only when passed, so a text without a case keeps the class's: my shown text is computed from
    # it on the next line, so it is set before anything measures me
    @displayCase = opts.displayCase if opts.displayCase?

    # additional properties:
    @textPossiblyCroppedToFit = @transformTextOneToOne @text

    # properties that override existing ones only when passed
    @backgroundColor = opts.backgroundColor if opts.backgroundColor?
    @backgroundTransparency = opts.backgroundTransparency if opts.backgroundTransparency?

    @undoHistory = []
    @redoHistory = []

    super()

    @_changed()

  # This font height comes out thin: tall characters such as ⎲█ƒ⎳À⎷ ⎸⎹ get cut.
  fontHeight: (fontSize) ->
    minHeight = Math.max fontSize, WorldWdgt.preferencesAndSettings.minimumFontHeight
    Math.ceil minHeight * 1.2 # assuming 1/5 font size for ascenders

  # ── THE LINE BOX ───────────────────────────────────────────────────────────────────────────
  # Each line of my text stands in a LINE BOX, and the queries below are its ONE home: how tall
  # the box is (linePitch: my lines stack at it), where the baseline sits in it (_baselineInLine),
  # where a caret stands in it (caretBoxInLine, caretTopLeftAt) and how paint spells that baseline
  # (_lineInkTextBaseline, _lineInkOffset). Wrapping heights and fit checks, measuring, box sizing,
  # paint, selection, slotCoordinates / slotAt, the caret and the macro toolkit's text aim all read
  # them, so a click, the caret, the selection and the ink agree on where every line is.
  #   My `lineHeight` picks the branch:
  #   - UNSET (undefined): the box is the font's em box, fontHeight tall (ceil(1.2 x size)), and a
  #     line is drawn with textBaseline "bottom" at the box's bottom, which puts its baseline the
  #     font's descent above that bottom.
  #   - SET: the box is my lineHeight, scaled with the font's em box (fontHeight) from the size it
  #     is stated at to the size in use, and the baseline sits where an explicit line height puts
  #     it: the half-leading above the font box rounds down, floor((pitch - (A + D)) / 2) + A, with
  #     A and D the font box's ascent and descent rounded to whole pixels. A line is drawn
  #     "alphabetic" at that baseline.
  #   Every number is a whole LOGICAL pixel, so dpr 2 doubles each one exactly.

  # How tall each of my lines is at `fontSize`: the pitch my lines stack at. Unset, the em box
  # (fontHeight). Set, my lineHeight scaled with the font's em box (fontHeight) from the size it is
  # stated at to `fontSize`, and rounded: an enlarged text keeps its proportions, at the stated size
  # the pitch IS the line height, and a line height at least its em box stays at least the em box
  # at every size, below the smallest renderable font too, where fontHeight holds steady. A line
  # height given no stated size is stated at the size I am set in. A fitted text (SCALEUP /
  # SCALEDOWN) passes its fitted size, as every row computation does.
  linePitch: (fontSize) ->
    if @lineHeight?
      statedAtFontSize = @lineHeightStatedAtFontSize ? @originallySetFontSize
      Math.round @lineHeight * (@fontHeight fontSize) / (@fontHeight statedAtFontSize)
    else
      Math.ceil @fontHeight fontSize

  # Where the baseline sits in a line box at `fontSize`, below the box's top. Unset, the font
  # box's descent above the box's bottom (where "bottom" at that bottom draws it); set, the
  # explicit-line-height rule above.
  _baselineInLine: (fontSize) ->
    [ascent, descent] = @_fontBoxAscentAndDescent fontSize
    if @lineHeight?
      Math.floor((@linePitch(fontSize) - (ascent + descent)) / 2) + ascent
    else
      @fontHeight(fontSize) - descent

  # The font box's ascent and descent at `fontSize`, each rounded to a whole pixel: [A, D], in the
  # font I paint with.
  _fontBoxAscentAndDescent: (fontSize) ->
    StringWdgt.fontBoxAscentAndDescentOf @buildCanvasFontProperty fontSize

  # THE FONT BOX of a canvas font string ("bold 20px Arial"): its ascent and descent, each rounded to
  # a whole pixel, [A, D]. Measured on the widgets' shared measuring context about the ALPHABETIC
  # baseline -- a canvas reports these relative to its textBaseline, and that context keeps its own
  # for every other measure -- and cached per font, like measureText. My line box reads it at the font
  # I paint with, and so does a line of text centred in a box by its font box elsewhere (a typed
  # icon face, TypedFaceIconAppearance), so one measure and one cache serve both.
  @fontBoxAscentAndDescentOf: (font) ->
    cacheKey = "fontBox-" + font
    cacheHit = world.cacheForTextMeasurements.get cacheKey
    if cacheHit? then return cacheHit
    context = world.canvasContextForTextMeasurements
    context.font = font
    textBaselineToRestore = context.textBaseline
    context.textBaseline = "alphabetic"
    metrics = context.measureText "Hg"
    context.textBaseline = textBaselineToRestore
    cacheEntry = [(Math.round metrics.fontBoundingBoxAscent), (Math.round metrics.fontBoundingBoxDescent)]
    world.cacheForTextMeasurements.set cacheKey, cacheEntry
    cacheEntry

  # Where a caret stands in a line box at `fontSize`: the font's em box, fontHeight tall, ending at
  # the font box's bottom (the baseline plus the descent). Unset, that is the whole line box. The
  # box spans no width: how wide a caret is, its caret decides.
  caretBoxInLine: (fontSize) ->
    emBoxHeight = @fontHeight fontSize
    if @lineHeight?
      top = @_baselineInLine(fontSize) + @_fontBoxAscentAndDescent(fontSize)[1] - emBoxHeight
    else
      top = 0
    new Rectangle 0, top, 0, top + emBoxHeight

  # WHERE A CARET STANDS at `slot`, in my plane, as far as my line box decides it: the slot's boundary
  # on its line (slotCoordinates, which answers the top of the slot's LINE box) moved down to the caret
  # box's top in that line, read at the size my slot geometry uses. How far right of that boundary a
  # caret draws itself is its own look (CaretWdgt._myTopLeftAtSlot, the theme's caretGap), so this and
  # slotCoordinates both keep the boundary itself.
  caretTopLeftAt: (slot) ->
    lineTopLeft = @slotCoordinates slot
    lineTopLeft.add new Point 0, (@caretBoxInLine @fittingFontSize).top()

  # How paint spells a line's baseline: the textBaseline my back buffer draws with, and the y below
  # a line box's top that each line is handed to fillText at. Unset, "bottom" at the box's bottom;
  # set, "alphabetic" at the baseline itself, so a font whose box descent is not a whole pixel
  # cannot move it.
  _lineInkTextBaseline: ->
    if @lineHeight? then "alphabetic" else "bottom"

  _lineInkOffset: (fontSize) ->
    if @lineHeight? then @_baselineInLine fontSize else @linePitch fontSize

  # What my line box adds to the key of a cache that keeps a pitch-derived value (a wrap's height
  # and fit verdict, a back buffer): nothing while my lineHeight is unset, so an unset text keys
  # its entries exactly as a text with no line box does; the line height and the size it is stated
  # at once it is set, so two texts that differ only in their line box never share an entry.
  _lineBoxCacheKeySuffix: ->
    if @lineHeight? then "-lineHeight" + @lineHeight + "@" + (@lineHeightStatedAtFontSize ? @originallySetFontSize) else ""

  # ── THE ITEM SHAPE ─────────────────────────────────────────────────────────────────────────
  # Where I live can dress me as an ITEM: a block filled rounded at its corners, my text standing in
  # from its edges -- as a document dresses the texts on its page (DocumentViewportWdgt
  # .itemShapeOfTextOnPlane, asked through its stack). It is my box's LOOSE fit (the FITTING MODEL,
  # above): a box that hugs my text (FIT_BOX_TO_TEXT) is my text's own extent, tight, or that extent
  # plus the item's inset at each side, loose; a box of any other fit is never loose. A TEMPLATE (a
  # widget a drag copies instead of moving, as the templates window shows its building blocks) is a
  # picture of an item, not an item, and wears none; the copy a drag takes is an item wherever it
  # lands. I ASK for the shape at every measure, paint and point mapping and keep nothing of it, so a
  # text dragged out of a document is a plain text again, one dropped back in an item again (each
  # re-parenting re-lays me: Widget._reactToBeingAdded), and a text saved, loaded or duplicated
  # wears what its new place gives it.
  #   The inset moves every query that places my text, consistently: where my text starts
  # (textVerticalPosition / textHorizontalPosition, which paint, slotCoordinates, slotAt, the caret
  # and the selection all read), the width it wraps at (TextWdgt.breakTextIntoLines), my box's size
  # (TextWdgt._reLayoutSelf and preferredExtentForWidth, the box hugs), whether my text fits
  # (doesTextFitInExtent), where a point picks a slot (_pointTakenOutOfPadding) and where a header
  # line runs (_drawHeaderUnderline); the rounding shapes my fill (_prepareTextBufferContext), my
  # hit shape (catchesPointerAt) and the corners a ring or a wash laid over me follows
  # (_outlineCornerRadii). Wearing no shape, my inset is Point.ZERO and my fill square, and
  # each of those answers exactly what it answers for a text that was never dressed.

  # My item shape -- {cornerRadius, inset}: my fill's rounding, and how far my text stands in from my
  # box (inset.x from each side, inset.y from the top and the bottom) -- or undefined, wearing none.
  _itemShape: ->
    return undefined unless @fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT and !@isTemplate
    @parent?.itemShapeOfContainedText?()

  _textInset: ->
    @_itemShape()?.inset ? Point.ZERO

  # the part of my box my text stands in, in my plane: my box less my inset (my box itself when I
  # wear no shape)
  _textArea: ->
    @boundingBox().insetBy @_textInset()

  # WHERE A POINT PICKS A SLOT: a point in my padding (inside my box, around my text area) is taken to
  # the nearest point of my text area, so a press there picks the nearest slot of the nearest line --
  # in the top padding, the first line's slot under it; beside a line, that line's nearer end. Any
  # other point is its own: one outside my box keeps its above / below / beside answers, and with no
  # inset my text area is my box, so every point is.
  _pointTakenOutOfPadding: (aPoint) ->
    return aPoint if @_textInset().isZero() or !@boundsContainPoint aPoint
    area = @_textArea()
    new Point (Math.min (Math.max aPoint.x, area.left()), area.right()),
      (Math.min (Math.max aPoint.y, area.top()), area.bottom())

  # What my item shape adds to my back buffer's cache key: nothing while I wear none; its rounding and
  # inset once I do, so a dressed text and an otherwise identical plain one never share a buffer.
  _itemShapeCacheKeySuffix: ->
    shape = @_itemShape()
    if shape? then "-item" + shape.cornerRadius + "-" + shape.inset.x + "x" + shape.inset.y else ""

  # The corners of the rounded body I paint myself (Widget._outlineCornerRadii): dressed as an item,
  # my fill's rounding at each corner; else whatever my appearance answers. A ring or a wash laid over
  # me reads them (Widget.cornerRadiiFollowingMyOutline: the selection outline around a selected
  # paragraph, the drop outline, the hover wash), so it follows the item's corners. Nothing clips to
  # them.
  _outlineCornerRadii: ->
    cornerRadius = @_itemShape()?.cornerRadius
    return super() unless cornerRadius?
    [cornerRadius, cornerRadius, cornerRadius, cornerRadius]

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
  # TextWdgt.upFrom / downFrom; set by the caret on horizontal moves and by activated below.
  rememberCaretColumn: (slot) ->
    @caretHorizPositionForVertMovement = slot

  # When a caret first attaches via a positioning click, the only undo entry is that click, which
  # we discard so the user's first real edit becomes the first undo step (CaretWdgt's constructor).
  clearUndoHistoryIfOnlyFirstClickPositioning: ->
    if @undoHistory?.length == 1
      onlyUndo = @undoHistory[@undoHistory.length - 1]
      if onlyUndo.isJustFirstClickToPositionCursor
        @undoHistory = []

  # My weight, slant, font and alignment are MY STYLE, which a text toolbar's tools mirror while I am
  # the text being edited (TextToolbarWdgt): each of my setters for them tells the world it moved
  # (WorldWdgt.noteStyleChanged), and the world announces it if I am its editor focus.
  setHorizontalAlignment: (newAlignment) ->
    if @horizontalAlignment != newAlignment
      @horizontalAlignment = newAlignment
      @_changed()
      world.noteStyleChanged @

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
  
  # What tells me from another text on a row that names me (Widget.distinguishedRowName): the text
  # I SHOW — in my display case, a password as its asterisks — whose start the row quotes.
  _rowNameDistinction: ->
    @transformTextOneToOne @text

  # My DEBUG representation (Widget.toString) with an extract of my text: 'a StringWdgt#3
  # ("Hello↵World...")'. A row that NAMES me reads my rowName instead. While the test harness plays,
  # the extract is hidden (hidingOfWidgetsContentExtractInLabels), like the instance number.
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
  
  obfuscateAsPassword: (letter, length) ->
    # there is an alternative to this, using an idiom
    # http://stackoverflow.com/a/19892144
    # but it's clearer this way
    ans = ""
    for i in [0...length]
      ans += letter
    ans

  # in the weight I draw in, or in `bold` when given (my fit measures in fitBold)
  buildCanvasFontProperty: (overrideFontSize = @fittingFontSize, bold = @isBold) ->
    # answer a font string, e.g. 'bold italic 12px Arial'
    font = ""
    font = font + "bold "  if bold
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

  # HOW MUCH OF ME SURVIVES THE CROP into the box I hold right now: the number of characters I
  # would actually draw, the ellipsis itself not counted, measured in the weight my fit is measured
  # in (fitBold). A pure query -- it measures, it changes nothing -- asked by a caller that has to
  # decide whether a cropped text is still worth drawing at all: a frame bar grades its title on it
  # (ruling C13), because a title cropped to "W…" names nothing and is worse than no title.
  numberOfCharactersThatFit: ->
    (@searchLongestFittingTextByMultiCroppingIt().replace "…", "").length

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
  # see the largest fitting size. The weight is mine unless `bold` is given: my fit passes the
  # weight it is measured in (doesTextFitInExtent).
  measureText: (text, overrideFontSize = @fittingFontSize, bold = @isBold) ->
    cacheKey =  @buildCanvasFontProperty(overrideFontSize, bold) + "-" + text.hashCode()
    cacheHit = world.cacheForTextMeasurements.get cacheKey
    if cacheHit? then return cacheHit
    world.canvasContextForTextMeasurements.font = @buildCanvasFontProperty overrideFontSize, bold
    # you'd think that we don't need to eliminate the invisible character
    # to measure the text, as it's supposed to be of zero length.
    # Unfortunately some fonts do draw it, so we indeed have to eliminate
    # it.
    cacheEntry = world.canvasContextForTextMeasurements.measureText(@eliminateInvisibleCharacter text).width
    world.cacheForTextMeasurements.set cacheKey, cacheEntry
    return cacheEntry

  # My text as it SHOWS. This must be a 1-1 transformation: the shown text is exactly as long as
  # the stored one, so a slot in one is the same slot in the other. A password shows one "*" per
  # character and no case (an asterisk has none); any other text shows in my display case.
  transformTextOneToOne: (theText) ->
    return @obfuscateAsPassword("*", theText.length) if @isPassword
    StringWdgt.inDisplayCase theText, @displayCase

  # A text in a DISPLAY CASE, one character for one: "upper" capitalises every character,
  # "sentence" the first one only, and no case leaves the text as it is. A character whose capital
  # is longer than itself ("ß" capitalises to "SS") is kept as it is, so the result is always
  # exactly as long as the text (transformTextOneToOne's contract).
  @inDisplayCase: (theText, displayCase) ->
    capitalOf = (character) ->
      capital = character.toUpperCase()
      if capital.length is 1 then capital else character
    switch displayCase
      when "upper"
        (capitalOf character for character in theText).join ""
      when "sentence"
        if theText.length is 0 then theText else (capitalOf theText[0]) + theText.slice 1
      else
        theText

  # The NON-settling core of a display-case change: what shows follows at once (and a box that hugs
  # my text re-hugs it), while the stored text is untouched. Called inside an enclosing settle, like
  # _setTextNoSettle: a frame re-asserts its title's case as it re-titles it
  # (FrameWdgt._retitleNoSettle).
  _setDisplayCaseNoSettle: (aDisplayCase) ->
    return if @displayCase is aDisplayCase
    @displayCase = aDisplayCase
    @_synchroniseTextAndActualText()
    @_sizeToTextAndDisableFittingNoSettle() if @autoSizeBoxToText
    @_changed()
    @_reflowContainedTextThenInvalidateLayout()

  # there are many factors beyond the font size that affect
  # the measuring, such as font style, but we only pass
  # the font size here because is the one we are going to
  # change when we do the binary search for trying to
  # see the largest fitting size.
  # The text fits when it fits my text area (my box less my item inset), measured in the weight my
  # fit is measured in (fitBold; the weight I draw in while it is undefined).
  doesTextFitInExtent: (text = (@transformTextOneToOne @text), overrideFontSize) ->
    if !@measureText?
      debugger
    if text == ""
      return true
    extentOccupiedByText = new Point Math.ceil(@measureText text, overrideFontSize, @fitBold ? @isBold), @linePitch(overrideFontSize)
    return extentOccupiedByText.le @_textArea().extent()

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
    return @measureText text, overrideFontSize

  _setFittingFontSize: (theValue) ->
    if @fittingFontSize != theValue
      @fittingFontSize = theValue
      @_changed()

  # The key of my back buffer: everything its pixels are a function of. My selection is its two
  # marks and the theme's two selection roles, my header line's ink is the headerLineRule role, and
  # my text's ink is my own colour or, while I hold none, my parent's answer or the defaultTextInk
  # role (_textInk; drawSelection, _drawHeaderUnderline and _drawTextLine read them as they paint,
  # as _backgroundFill reads a role I wear), so a changed selection, a changed role, or a parent's
  # changed answer re-renders me.
  #   My crop (textPossiblyCroppedToFit) is decided by the reflow a MISS runs, after this key is
  # taken, so the key names the weight my fit is measured in itself, while it differs from the
  # weight I draw in (the canvas font names that one): a text whose fit weight moves re-renders,
  # and two texts that differ only in it never share a buffer. While the two agree it adds nothing,
  # so such a text keys its buffer exactly as a text with no fit weight of its own.
  createBufferCacheKey: ->
    theme = WorldWdgt.theme
    @extent().toString() + "-" +
    @isPassword  + "-" +
    @displayCase  + "-" +
    @originallySetFontSize + "-" +
    @buildCanvasFontProperty() + "-" +
    @isHeaderLine + "-" +
    theme.headerLineRule.toString()  + "-" +
    @_textInk().toString()  + "-" +
    (@_backgroundFill()?.toString() ? "transp") + "-" +
    (if @backgroundTransparency? then @backgroundTransparency.toString() else "transp") + "-" +
    @text.hashCode()  + "-" +
    @textPossiblyCroppedToFit.hashCode()  + "-" +
    @startMark  + "-" +
    @endMark  + "-" +
    theme.textSelectionFill.toString()  + "-" +
    theme.textSelectionText.toString()  + "-" +
    @horizontalAlignment  + "-" +
    @verticalAlignment  + "-" +
    @fittingSpecWhenBoundsTooLarge  + "-" +
    @fittingSpecWhenBoundsTooSmall  + "-" +
    @fittingSpec  + "-" +
    @fittingSpecBoxWhichDimensionAdjusts +
    (if @fitBold? and @fitBold isnt !!@isBold then "-fitBold" + @fitBold else "") +
    @_lineBoxCacheKeySuffix() +
    @_itemShapeCacheKeySuffix()

  # Where my text starts inside my box, along each axis: flush with the side of my text area it is
  # aligned to (my box less my item inset, THE ITEM SHAPE), or centred. The paint and the caret /
  # selection math (slotCoordinates, slotAt) both read these, so the caret always sits on the text
  # it edits.
  textVerticalPosition: (heightOfText) ->
    inset = @_textInset().y
    switch @verticalAlignment
      when AlignmentSpecVertical.TOP
        inset
      when AlignmentSpecVertical.MIDDLE
        (@height() - heightOfText)/2
      when AlignmentSpecVertical.BOTTOM
        @height() - inset - heightOfText

  textHorizontalPosition: (widthOfText) ->
    inset = @_textInset().x
    switch @horizontalAlignment
      when AlignmentSpecHorizontal.LEFT
        inset
      when AlignmentSpecHorizontal.CENTER
        @width()/2 - widthOfText/2
      when AlignmentSpecHorizontal.RIGHT
        @width() - inset - widthOfText


  # Draw ONE complete line of text at (x, y) in my ink (_textInk, a key of my buffer too). StringWdgt's
  # single-line paint and TextWdgt's wrapped-lines loop both draw every line through here.
  _drawTextLine: (backBufferContext, line, x, y) ->
    backBufferContext.fillStyle = @_textInk().toString()
    backBufferContext.fillText line, x, y

  # MY INK, the ONE answer my line paint and my buffer's key both read: my own colour; while I hold
  # none, the ink my PARENT answers for me (its inkForChildText, a soft hook asked through ?(): a
  # desktop icon answers it for its caption, by whether it is the selected icon); else the theme's
  # defaultTextInk. The hook is the parent's, not mine, because the text that needs it is a plain
  # text with no class of its own to answer one (an icon's caption is a TextWdgt), and the ink is a
  # fact about its holder -- whether it is selected -- that only the holder knows; read here, at
  # paint, it lets a selection change re-render the text through its key and leaves no ink copied
  # into a text a save or a copy would carry.
  _textInk: ->
    @color ? @parent?.inkForChildText?(@) ? WorldWdgt.theme.defaultTextInk

  # The fill behind my text: my backgroundColor -- or, for a text that holds none of its own because
  # it wears a theme role until one is set on it, the role it answers (its _surfaceBackgroundFill, a
  # soft hook no plain text defines: Fizzytiles' code pane), read here as my buffer is keyed, sized
  # and filled, so a saved or duplicated text wears the look of the world it is painted in.
  _backgroundFill: ->
    @backgroundColor ? @_surfaceBackgroundFill?()

  # Shared by StringWdgt and TextWdgt (which extends StringWdgt): set the text
  # font/alignment on the freshly-created back-buffer context and, if a background
  # colour is set, fill it. Operates entirely within the caller's
  # useLogicalPixelsUntilRestore() scope. Kept byte-identical across both sites.
  _prepareTextBufferContext: (backBufferContext) ->
    backBufferContext.useLogicalPixelsUntilRestore()
    backBufferContext.font = @buildCanvasFontProperty()
    backBufferContext.textAlign = "left"
    backBufferContext.textBaseline = @_lineInkTextBaseline()

    # paint the background so we have a better sense of
    # where the text is fitting into.
    # This fillRect is passed logical pixels rather than actual pixels
    # (contrary to most direct canvas calls elsewhere in the codebase).
    # This is because it's inside the scope of the
    # "useLogicalPixelsUntilRestore()".
    # An ABSENT backgroundTransparency means fully opaque (Widget's class-level default
    # is 1) — never hand the canvas an undefined. `ctx.globalAlpha = undefined` is an invalid
    # assignment that HTML5 says to IGNORE, but SWCanvas stores it raw, and some engine
    # builds then composite the fill at NaN coverage: the specified backgroundColor
    # silently paints NOTHING, with no error anywhere. Belt-and-braces since the two
    # constructors that used to leave the field undefined were fixed (TextWdgt/SimpleTextWdgt),
    # because the failure mode is invisible rather than loud.
    # Dressed as an item (THE ITEM SHAPE) the fill is the item's rounded block, its corners left
    # clear in the buffer, so the page under it shows there; otherwise it is the whole square box.
    background = @_backgroundFill()
    if background
      backBufferContext.save()
      backBufferContext.fillStyle = background.toString()
      backBufferContext.globalAlpha = @backgroundTransparency ? 1
      cornerRadius = @_itemShape()?.cornerRadius
      if cornerRadius?
        backBufferContext.fillRoundRect 0, 0, Math.round(@width()), Math.round(@height()), cornerRadius
      else
        backBufferContext.fillRect  0,
            0,
            Math.round(@width()),
            Math.round(@height())
      backBufferContext.restore()


  # Shared by StringWdgt and TextWdgt: draw the "header line" — two horizontal
  # rule segments flanking the text, through the middle of the line box (its bottom less half its
  # pitch). The geometry values are passed in because each call site computes them its own way
  # (single fitting line here vs one wrapped line in TextWdgt), so only the
  # drawing itself is factored out (honouring the TODO in TextWdgt._createRefreshOrGetBackBuffer).
  # The rule runs across my text area (my box less my item inset: the whole box when I wear no
  # shape), broken 5 px either side of the text, and a segment with no length left in that span
  # (text at or near an end of it) is not drawn: there it could only cover pixels outside the span.
  # Its ink is the headerLineRule role, read here (and in my buffer's key).
  _drawHeaderUnderline: (backBufferContext, lineBottom, pitch, textHorizontalPosition, widthOfText) ->
    spanLeft = @_textInset().x
    spanRight = @width() - spanLeft
    backBufferContext.strokeStyle = WorldWdgt.theme.headerLineRule.toString()
    backBufferContext.beginPath()
    if textHorizontalPosition - 5 > spanLeft
      backBufferContext.moveTo spanLeft, lineBottom - pitch / 2
      backBufferContext.lineTo textHorizontalPosition - 5, lineBottom - pitch / 2
    if textHorizontalPosition + widthOfText + 5 < spanRight
      backBufferContext.moveTo textHorizontalPosition + widthOfText + 5, lineBottom - pitch / 2
      backBufferContext.lineTo spanRight, lineBottom - pitch / 2
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
      # not, then we mark the caret as damaged.
      if @backBuffer != cacheHit[0]
        world.caret?.noteTextChanged()
      return cacheHit

    # public-call-sanctioned: reflowText is macro-called public text API (see _sizeToTextAndDisableFittingInMyParentsArrangeNoSettle).
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
    # Text standing inset (an item, THE ITEM SHAPE) is not at the surface's
    # top-left either, so it takes the whole widget too.
    widthOfText = @calculateTextWidth text
    heightOfText = @linePitch @fittingFontSize
    if @_backgroundFill()? or
     @verticalAlignment != AlignmentSpecVertical.TOP or
     @horizontalAlignment != AlignmentSpecHorizontal.LEFT or
     @fittingSpecWhenBoundsTooLarge == FittingSpecTextInLargerBounds.FLOAT or
     !@_textInset().isZero()
      width = @width()
      height = @height()
    else
      width = widthOfText
      height = heightOfText

    backBuffer = HTMLCanvasElement.createOfPhysicalDimensions (new Point width, height).scaleBy ceilPixelRatio

    backBufferContext = backBuffer.getContext "2d"

    @_prepareTextBufferContext backBufferContext


    # my one line's box, placed by my vertical alignment, and the y its text is drawn at in it
    lineTop = @textVerticalPosition heightOfText
    textVerticalPosition = lineTop + @_lineInkOffset @fittingFontSize
    textHorizontalPosition = @textHorizontalPosition widthOfText

    # NB: no SHADOW is baked into this buffer. A text widget's shadow is the
    # unified widget drop-shadow (see Widget.coffee "How the shadow painting
    # works" + addShadow); a per-glyph shadowOffset/shadowColor route is
    # deliberately not used here.
    @_drawTextLine backBufferContext, text, textHorizontalPosition, textVerticalPosition

    # header line
    if @isHeaderLine
      @_drawHeaderUnderline backBufferContext, lineTop + heightOfText, heightOfText, textHorizontalPosition, widthOfText




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
  # Each selected character's plate spans its whole line box (slotCoordinates answers the box's
  # top), so a selection over several lines has no gaps between them.
  #   The look is the theme's, read here as I paint (so a saved or duplicated text wears the look of
  # the world it is painted in): the plate textSelectionFill, the character on it textSelectionText
  # -- a solid accent plate with paper text. The plate must stay OPAQUE: each one is a pixel wider
  # than its character's advance, so neighbouring plates overlap, and a translucent plate would show
  # every overlap as a darker seam.
  drawSelection: (backBufferContext) ->
    startSlot = @firstSelectedSlot()
    endSlot = @lastSelectedSlot()
    plateFill = WorldWdgt.theme.textSelectionFill.toString()
    characterInk = WorldWdgt.theme.textSelectionText.toString()
    for i in [startSlot...endSlot]
      p = @slotCoordinates(i).subtract @position()
      c = @textPossiblyCroppedToFit.charAt(i)
      backBufferContext.fillStyle = plateFill
      backBufferContext.fillRect p.x, p.y, Math.ceil(@measureText c) + 1, @linePitch @fittingFontSize
      backBufferContext.fillStyle = characterInk
      backBufferContext.fillText c, p.x, p.y + @_lineInkOffset @fittingFontSize
    
  
  # StringWdgt measuring:
  slotCoordinates: (slot) ->
    # PURE geometry: the position point of the given index ("slot") -- no side effects.
    # (used to fire one here; moved to handOffToPopoutEditorIfOverflowing -- see docs/archive/layout-system-architecture-assessment.md.)

    # answer the position point of the given index ("slot"): its boundary, at the top of my line
    # box (caretTopLeftAt moves it down to the caret box's top; a caret stands just right of it)
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

    textVerticalPosition = @textVerticalPosition @linePitch @fittingFontSize
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
    textVerticalPosition = @textVerticalPosition @linePitch @fittingFontSize

    if aPoint.y - @top() < textVerticalPosition
      return 0

    return false

  pointIsUnderLastLine: (aPoint) ->
    textVerticalPosition = @textVerticalPosition(@linePitch @fittingFontSize) + @linePitch(@fittingFontSize)

    # if pointer is below the line, the slot is at
    # the last character.
    if (aPoint.y - textVerticalPosition) - @top() > @linePitch @fittingFontSize
      return @textPossiblyCroppedToFit.length

    return false

  # a point in my padding picks from the nearest point of my text area (_pointTakenOutOfPadding)
  slotAt: (aPoint) ->
    aPoint = @_pointTakenOutOfPadding aPoint
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

  fontSizePopout: (menuItem)->
    @prompt menuItem.parent.promptTitleAsking("font\nsize:"), @, "setFontSize",
      defaultContents: @originallySetFontSize.toString()
      floorNum: 6
      ceilingNum: 500
      isRounded: true

  editPopout: (menuItem)->
    if menuItem?
      title = menuItem.parent.promptTitleAsking "edit:"
    else
      title = "edit:"

    @prompt title, @, "setText",
      defaultContents: @text
      floorNum: 6
      isRounded: true

  # SELF-SETTLES via the single @_settleLayoutsAfter, like the other text setters.
  setFontName: (theNewFontName) ->
    @_settleLayoutsAfter => @_setFontNameNoSettle theNewFontName

  # The NON-settling core of setFontName. The public setFontName self-settles over this; low-level code
  # that changes a text's font inside a settle it already holds reaches the core directly (cores call
  # cores). A text that is BUILT in a font takes it as a role at construction instead (`fontRole`).
  _setFontNameNoSettle: (theNewFontName) ->
    if @fontName != theNewFontName
      @fontName = theNewFontName
      @_changed()
      # ANNOUNCE it, so every open fonts menu re-ticks — this one, another copy, or one left open
      # while a script changed the font. markNonValueChange rather than markStale: my font is not my
      # VALUE (my value is my text), and saying otherwise would re-deliver my text along my wire.
      world.dataflow.markNonValueChange @
      world.noteStyleChanged @   # ... and my font is my style (see setHorizontalAlignment)
    @_reflowContainedTextThenInvalidateLayout()

  # THE MENU ADAPTER. A menu/button action is dispatched as
  #   target[action].call target, theButton, subject, arg1, arg2   (ButtonWdgt)
  # so the picked font necessarily rides slot 3 and the menu item arrives in slot 1. That fixed
  # foreign convention is the only reason for the ignored slots — code setting a font wants the
  # plain setFontName above, because passing `undefined, undefined` to reach past a dispatcher's
  # slots is the hole R3 names (docs/architecture/constructor-and-parameter-conventions.md).
  setFontNameFromMenu: (ignored, ignored2, theNewFontName) ->
    @setFontName theNewFontName

  # what a reflecting menu row reads to decide whether it is the ticked one
  # (MenuRowReflectionSpec.readerName)
  currentFontName: -> @fontName

  # my font stacks in menu order, paired with the label each shows — a list, so the menu is built by
  # iterating it instead of nine hand-numbered call sites plus a parallel index table.
  # NB the "Treby" label intentionally differs from its trebuFontStack property name.
  _fontStackMenuEntries: ->
    [
      [ @justArialFontStack, "Arial"   ]
      [ @timesFontStack,     "Times"   ]
      [ @georgiaFontStack,   "Georgia" ]
      [ @garamoFontStack,    "Garamo"  ]
      [ @helveFontStack,     "Helve"   ]
      [ @verdaFontStack,     "Verda"   ]
      [ @trebuFontStack,     "Treby"   ]
      [ @heavyFontStack,     "Heavy"   ]
      [ @monoFontStack,      "Mono"    ]
    ]

  fontsMenu: (ignored,targetWidget)->
    menu = new MenuWdgt @, target: targetWidget, title: "Fonts"

    # Each row DECLARES that it shows my current font; it is born with the right tick and re-derives
    # it whenever I announce a change, here and in every other open copy of this menu. Nothing
    # indexes rows[1..9] any more — that hand-numbering broke the day anyone added a divider, and it
    # could only ever fix up the ONE menu whose item had just been clicked.
    for [ fontStack, menuLabel ] in @_fontStackMenuEntries()
      menu.addMenuItem menuLabel, @, "setFontNameFromMenu",
        arg1: fontStack
        reflection: MenuRowReflectionSpec.tickWhen @, "currentFontName", fontStack, menuLabel

    menu.popUpAtHand()


  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "Edit…", @, "editPopout", toolTip: "set this String's\ncontent"
    menu.addMenuItem "Font size…", @, "fontSizePopout", toolTip: "set this String's\nfont point size"

    menu.addMenuItem "Font", @, "fontsMenu", closesUnpinnedPopUps: false, opensSubmenu: true, toolTip: "pick a font"

    if @isBold
      menu.addMenuItem "Normal weight", @, "toggleWeight"
    else
      menu.addMenuItem "Bold", @, "toggleWeight"

    if @isItalic
      menu.addMenuItem "Non-italic", @, "toggleItalic"
    else
      menu.addMenuItem "Italic", @, "toggleItalic"

    if @isHeaderLine
      menu.addMenuItem "No header line", @, "toggleHeaderLine"
    else
      menu.addMenuItem "Header line", @, "toggleHeaderLine"


    if @isPassword
      menu.addMenuItem "Show characters", @, "toggleIsPassword"
    else
      menu.addMenuItem "Hide characters", @, "toggleIsPassword"

    menu.addLine()
    if @horizontalAlignment != AlignmentSpecHorizontal.LEFT
      menu.addMenuItem "← Align left", @, "alignLeft"
    if @horizontalAlignment != AlignmentSpecHorizontal.CENTER
      menu.addMenuItem "∸ Align center", @, "alignCenter"
    if @horizontalAlignment != AlignmentSpecHorizontal.RIGHT
      menu.addMenuItem "→ Align right", @, "alignRight"

    menu.addLine()
    if @verticalAlignment != AlignmentSpecVertical.TOP
      menu.addMenuItem "↑ Align top", @, "alignTop"
    if @verticalAlignment != AlignmentSpecVertical.MIDDLE
      menu.addMenuItem "⍿ Align middle", @, "alignMiddle"
    if @verticalAlignment != AlignmentSpecVertical.BOTTOM
      menu.addMenuItem "↓ Align bottom", @, "alignBottom"

    menu.addLine()

    if @fittingSpecWhenBoundsTooLarge == FittingSpecTextInLargerBounds.SCALEUP
      menu.addMenuItem "←☓→ Don't expand to fill", @, "togglefittingSpecWhenBoundsTooLarge"
    else
      menu.addMenuItem "←→ Expand to fill", @, "togglefittingSpecWhenBoundsTooLarge"

    if @fittingSpecWhenBoundsTooSmall == FittingSpecTextInSmallerBounds.CROP
      menu.addMenuItem "→← Shrink to fit", @, "togglefittingSpecWhenBoundsTooSmall"
    else
      menu.addMenuItem "→⋯← Crop to fit", @, "togglefittingSpecWhenBoundsTooSmall"

    # Deliberately NOT routed through ControllerMixin._addTargetConnectionMenuEntries: I offer the
    # connect item on the index page ONLY, which is the whole reason I build this block by hand.
    # The wire rows below are unguarded on purpose — a connection I hold is worth showing and cutting
    # wherever I am, even where I offer no way to make a new one.
    if world.isIndexPage
      menu.addLine()
      # ONE row for the gestures, as the shared block does it: the submenu behind it offers "Connect
      # to" and — when something can actually be bound to — "Bind ⇄". Grouping is what keeps a
      # second gesture from costing every controller's menu a second row.
      menu.addMenuItem "Connect", @, "openConnectionGestureMenu", opensSubmenu: true, toolTip: "connect to\nanother widget"
    @_addWireMenuEntries menu


  togglefittingSpecWhenBoundsTooSmall: ->
    @fittingSpecWhenBoundsTooSmall = not @fittingSpecWhenBoundsTooSmall
    @_changed()
    world.stopEditing()

  togglefittingSpecWhenBoundsTooLarge: ->
    world.stopEditing()
    @fittingSpecWhenBoundsTooLarge = not @fittingSpecWhenBoundsTooLarge
    @_changed()


  # weight and slant are my style: see setHorizontalAlignment for who mirrors it. The toggle flips
  # the weight I draw in; the weight my fit is measured in (fitBold) stays what it is.
  toggleWeight: ->
    @_settleLayoutsAfter =>
      @_setBoldNoSettle (not @isBold), @fitBold
      world.noteStyleChanged @

  # The NON-settling core of a weight change: my two weights set -- `bold` the one I draw in,
  # `fitBold` the one my fit is measured in (fitBold; undefined measures me in `bold`) -- my repaint
  # (my canvas font and, while it differs from it, my fit's weight are keys of my back buffer) and
  # my contained-text re-fit. Code that sets a text's weights inside a settle or a pass it already
  # holds reaches it directly (cores call cores): a frame's title takes the weights its frame's look
  # names (FrameBarWdgt._setTitleWeightNoSettle). The two weights I already have are a no-op, and a
  # fit weight is written only when it moves, so a text that never had one keeps the class's.
  # Answers whether either weight moved: a caller whose layout reads my measure re-arranges only
  # then.
  _setBoldNoSettle: (bold, fitBold) ->
    bold = !!bold
    fitBold = !!fitBold if fitBold?
    return false if !!@isBold is bold and @fitBold is fitBold
    @isBold = bold
    @fitBold = fitBold unless @fitBold is fitBold
    @_changed()
    @_reflowContainedTextThenInvalidateLayout()
    true

  toggleItalic: ->
    @_settleLayoutsAfter =>
      @isItalic = not @isItalic
      @_changed()
      world.noteStyleChanged @
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
  # (TextWdgt overrides the hug with a multi-line, soft-wrap-off variant.)
  # PUBLIC self-settling entry for STANDALONE callers (a tick toggle on an open menu, a header/tooltip
  # build on an orphan). The IN-SETTLE callers -- _setTextNoSettle, _setFontSizeNoSettle, the chrome
  # builders -- call _sizeToTextAndDisableFittingNoSettle DIRECTLY, and a label button's _createLabel the
  # hug-only variant below, because a single self-settle reached mid-pass/mid-settle re-enters the flush
  # guard and THROWS. That throw is the wanted discipline (it surfaces a mis-routed caller); an absorbing
  # batch settler would silently swallow it.
  # Returns @ (the core ends with @) so callers can chain -- several macros do
  # `s = (new StringWdgt ...).sizeToTextAndDisableFitting()` then `world.add s`.
  sizeToTextAndDisableFitting: ->
    @_settleLayoutsAfter => @_sizeToTextAndDisableFittingNoSettle()

  # The box-hug, minus the settle: hug my box to my text, then tell my managing parent. A chrome label is a
  # freefloating child laid out by its managing container (button/menu centres it in _reLayoutSelf); the
  # generic _reFitContainer seam can't reach a non-scroll/stack container and a freefloating child doesn't
  # climb, so schedule the managing parent's re-lay explicitly, through the phase-valve
  # (_scheduleRelayoutRespectingPhase): off-pass it invalidates the parent and the enclosing settle flushes
  # it; in-pass, where a climbing _invalidateLayout throws, it enqueues just the parent, which the walk
  # re-lays in this same flush -- nothing else promises that an arrange of the parent follows. This is the
  # hug for every caller but one (the variant below names it); TextWdgt overrides only the hug, so this one
  # tail serves both classes.
  _sizeToTextAndDisableFittingNoSettle: ->
    @_sizeToTextAndDisableFittingInMyParentsArrangeNoSettle()
    @parent?._scheduleRelayoutRespectingPhase()
    @  # return self so the public wrapper is chainable (macros do `(new StringWdgt …).sizeToTextAndDisableFitting()`)

  # The box-hug ALONE, telling my parent nothing -- for the one caller that IS my parent's arrange and
  # places me next: my parent building me in its own _reLayoutSelf (LabelButtonWdgt._createLabel,
  # MenuItemWdgt._createLabel), which reads my extent right after to centre or place me and, as a menu row,
  # to size itself. Remembers the box-hugs-text mode (autoSizeBoxToText) so a later setText (editing a
  # button label in place) keeps the box tracking the text instead of cramming the new text into the stale
  # box. The box is the text's extent plus my item inset at each side (none when I wear no item shape).
  #   ⚠ THE CONSTRAINT: call this only from inside my parent's own arrange, with my parent placing me
  # after -- that arrange is what makes the missing schedule safe; every other caller takes the core above.
  # The core is wrong there, not merely redundant: once my parent's _reLayout has marked it fixed
  # (LabelButtonWdgt._reLayout runs the base arrange, which does, and only then _reLayoutSelf ->
  # _createLabel), the in-pass enqueue leaves my parent invalid and the walk re-lays it a SECOND time in
  # that flush -- a depth-0 re-visit, which the standing revisit gate (Fizzygum-tests/scripts/
  # revisit-gate.js, baseline EMPTY) fails on.
  _sizeToTextAndDisableFittingInMyParentsArrangeNoSettle: ->
    @autoSizeBoxToText = true
    @fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.FLOAT
    @fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    measuredWidth = @calculateTextWidth (@transformTextOneToOne @text), @originallySetFontSize
    widthOfText = Math.max (Math.ceil measuredWidth), 1
    heightOfText = @linePitch @originallySetFontSize
    inset = @_textInset()
    @__commitExtent new Point widthOfText + 2 * inset.x, heightOfText + 2 * inset.y
    # public-call-sanctioned: reflowText is public text API — macros call it directly
    # (macroBoxTransparencyAndColorChanging), so it stays public; consciously reused by this hug.
    @reflowText()

  # ── Contained-text (FIT_BOX_TO_TEXT) edit: the re-fit core ───────────────────
  # The NON-settling re-fit behind the six text-property setters (setText / setFontSize
  # / setFontName / toggleWeight / toggleItalic / toggleIsPassword).
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
  # menu re-ticking (MenuItemWdgt._applyRowReflectionNoSettle), per-frame updates (the video time labels). The
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
      # a parent that lays itself out from my text is told it changed (a desktop icon sizes its
      # caption's plate from the caption's lines: WidgetHolderWithCaptionWdgt); every other parent
      # has no such reaction
      @parent?._reactToChildTextChanged? @
    @updateTarget()
    @_reflowContainedTextThenInvalidateLayout()

  # This is also invoked for example when you take a slider
  # and set it to target this.
  #
  # SELF-SETTLES via the single @_settleLayoutsAfter -- the ordinary self-settling-setter convention.
  # Single is SAFE here because the one
  # flow that used to reach setText MID-PASS -- a window RE-TITLING its label from inside an add's settle
  # -- now calls @_setTextNoSettle DIRECTLY (see FrameWdgt._addNoSettle), so NO flow reaches setText
  # under a layout pass anymore (VERIFIED: full suite green with the single settler). The single settler's
  # flow-violation throw stays as the NET: if some future caller (e.g. a connection's updateTarget
  # dynamically dispatching to setText) reaches it mid-pass, it SURFACES the violation rather than
  # silently deferring it.
  setText: (theTextContent) ->
    @_settleLayoutsAfter => @_setTextNoSettle theTextContent

  # The reactive-CONNECTOR entrypoint for setText (the connection lane -- see Widget.
  # _settleLayoutsAfterOrJoinEnclosingPass and check-layering [P]). IDENTICAL to the public setText
  # EXCEPT it JOINS an already-open layout pass instead of opening a nested settle
  # (which the public setText's _settleLayoutsAfter would reject mid-pass). The engine's edge apply
  # (DataflowEngine._applyWireValue) routes wired "setText" deliveries here; direct/API callers keep using the
  # public setText.
  _setTextConnector: (theTextContent) ->
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
  
  _setFontSizeNoSettle: (size) ->
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

  setFontSize: (size) ->
    @_settleLayoutsAfter => @_setFontSizeNoSettle size

  # The reactive-CONNECTOR entrypoint for setFontSize (see _setTextConnector above / check-layering [P]).
  # setFontSize is a SINK -- it never calls updateTarget, so a circuit cannot cycle through it.
  _setFontSizeConnector: (size) ->
    @_settleLayoutsAfterOrJoinEnclosingPass =>
      @_setFontSizeNoSettle size

  # My `text` pin's reader, and so what exportedValue answers (`text` is my principal pin).
  # ⚠ It did not exist before: the exported-value chain ended by reading the FIELD `@text` directly,
  # which is why the two classes where `@text` holds a child WIDGET rather than a string exported a
  # widget (see Widget.exportedValue). setText's reader twin is now spelled out, so a pin can promise
  # it and the reverse edge can dispatch it.
  getText: -> @text

  # `text` accepts a number's string spelling as readily as a string, hence the two kinds.
  #   ⚠ NOT declared here: `bang!`. `bang` is implemented on SimpleTextWdgt, so declaring the pin on
  # THIS class would offer a plain StringWdgt/TextWdgt a target property that dispatches to nothing
  # (`consumer[action]?.call` swallows the miss silently). A pin belongs to the class that has the verb.
  # `text` ANNOUNCES, and it is the funnel that earns the word: every post-construction write goes
  # through `setText` — the caret's edits included — and `setText` raises `updateTarget`, which
  # announces whether or not I drive anything.
  pins: -> super().concat [
    new PinSpec "text",      ["string", "numerical"],  set: "setText", get: "getText", announces: true
    new PinSpec "font size", "numerical",              set: "setFontSize"
  ]

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
  # thin-wrap-exempt: edit BRANCHES (inline world.edit when the text fits, else editPopout) and returns a fit
  # flag -- not the bare @_settleLayoutsAfter => @_editNoSettle wrap. Its NoSettle sibling _editNoSettle below
  # mirrors the branch, routing the inline case to world._editNoSettle (the drain-safe caret core).
  edit: ->
    if @alwaysEditsInline or @textPossiblyCroppedToFit == @transformTextOneToOne @text
      world.edit @
      return true
    else
      @editPopout()
      return undefined

  # The NoSettle sibling of edit, for a caller already inside a layout flush/pass -- a dataflow connection sink
  # delivering into a prompt slider's editable field (PromptWdgt._takeSliderValueConnector). Routes the
  # inline-edit case to world._editNoSettle (the non-settling caret core, joining the enclosing settle); the
  # overflow branch hands off to editPopout exactly as edit does (not reached for a short prompt value, which
  # fits inline).
  _editNoSettle: ->
    if @alwaysEditsInline or @textPossiblyCroppedToFit == @transformTextOneToOne @text
      world._editNoSettle @
      return true
    else
      @editPopout()
      return undefined

  # When inline editing and the just-grown text no longer fits a CROP-overflow field, abandon inline
  # editing and hand off to the pop-out editor (stopEditing tears down the inline caret; edit() then
  # routes to editPopout() because the text no longer fits). Returns true if it handed off. PURE
  # PREDICATE, OFF the layout flush: called from CaretWdgt.insert (the only place editing can GROW
  # the text) right after setText, at event time -- edit() on an already-overflowing field goes
  # straight to editPopout(), so insert is the only way to exceed CROP inline. History (why this
  # moved off slotCoordinates): see docs/archive/layout-system-architecture-assessment.md.
  handOffToPopoutEditorIfOverflowing: ->
    return false if @alwaysEditsInline
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
      return undefined
    return Math.min @startMark, @endMark

  lastSelectedSlot: ->
    if !@startMark? or !@endMark?
      return undefined
    return Math.max @startMark, @endMark

  currentlySelecting: ->
    if !@startMark? and !@endMark?
     return false
    return true
  
  clearSelection: ->
    if !@startMark? and !@endMark?
      return
    @startMark = undefined
    @endMark = undefined
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

  # An EDITABLE string word-selects around the caret; a non-editable one escalates (the
  # same else-escalate activated has always had), so a double-click on a passive label
  # reaches the first ancestor that wants it — e.g. a spreadsheet cell's scalar-text child
  # escalating to the CellWdgt, which starts a caret edit at the clicked slot.
  doubleActivated: (pos) ->
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
    else
      @escalateEvent "doubleActivated", pos

  tripleActivated: ->
    if @isEditable
      @selectAll()
      world.caret?.gotoSlot @text.length


  # Every time the user clicks on the text, a new edit()
  # is triggered, which creates a new caret.
  activated: (pos, arg2, arg3, arg4, shiftKey, arg6, arg7, arg8, arg9) ->
    @bringToForeground()
    world.caret?.bringToForeground()
    if @isEditable
      # doesn't matter what we set editResult to initially,
      # just not undefined or undefined cause that's
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
      @escalateEvent "activated", pos, arg2, arg3, arg4, shiftKey, arg6, arg7, arg8, arg9
  
  enableSelecting: ->
    @isSelectable = true

  pressBegan: (pos) ->
    if !@isSelectable
      super pos
      return
    @clearSelection()
    if @isEditable and !@grabsToParentWhenDragged()
      @edit()
      world.caret.gotoPos pos
      @startMark = @slotAt pos
      @endMark = @startMark

  # I TAKE BOTH MOVE CHANNELS, for the two halves of one rule, so both reach the one step below.
  # Dragging across my glyphs with the button down EXTENDS the selection — that is the pressed half.
  # The other half is that enableSelecting arms a gesture with an expiry: the first move that is not
  # extending a live selection ends selecting for good, and a BARE pointer crossing me is exactly
  # such a move.
  #   ⚠ The hover half is load-bearing, not decoration: while selecting stands, pressBegan opens the
  # edit itself, and for text too long to edit inline that is the pop-out editor rather than an
  # inline caret (measured — macroFingerTapEditSummonsVirtualKeyboard).
  hoverMoved: (pos) ->
    @_stepSelectionAt pos

  pressMoved: (pos) ->
    @_stepSelectionAt pos

  # When not selectable this must stay equivalent to HAVING NO move handler at all:
  # each dispatch site (ActivePointerWdgt) is a bare optional call with no
  # else-branch, so the no-op return is byte-identical to the event going
  # undelivered.
  _stepSelectionAt: (pos) ->
    if !@isSelectable
      return
    if @isEditable and @currentlySelecting()
      newMark = @slotAt pos
      if newMark isnt @endMark
        @endMark = newMark
        @_changed()
    else
      @_disableSelecting()

  _disableSelecting: ->
    # public-call-sanctioned: clearSelection is the public text-selection API (see _setTextNoSettle).
    @clearSelection()
    @isSelectable = false


  
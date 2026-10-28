class LayoutSpacerWdgt extends LayoutChromeWdgt

  constructor: (spacerWeight = 1) ->
    super()
    @setMinAndMaxBoundsAndSpreadability (new Point 0,0) , (new Point 1,1), spacerWeight * DivisionStackLayoutSpec.SPREADABILITY_SPACERS
    @minimumExtent = new Point 0,0

  # A spacer is a leaf, so these end the test harness's sweep of a subtree (WidgetTestSupport's
  # Widget versions recurse into children) rather than call up into it: a build without the
  # harness has no Widget version to call.
  makeSpacersTransparent: ->
    if !@thisSpacerIsTransparent
      @thisSpacerIsTransparent = true
      @_changed()

  makeSpacersOpaque: ->
    if @thisSpacerIsTransparent
      @thisSpacerIsTransparent = false
      @_changed()

  # MY GLYPH (LayoutChromeWdgt._glyphOnMyPlate): the double arrow along my division's axis -- across
  # (DoubleArrowIconAppearance) in a row, down (VerticalDoubleArrowIconAppearance) in a column, and
  # across on my own -- in layoutChromeGlyph at layoutSpacerGlyphSize, centred on my plate, which
  # shows the room I take is spare space that stretches. My plate and its hover are my base's
  # (LayoutChromeWdgt, LayoutChromeAppearance); a transparent spacer (makeSpacersTransparent above)
  # paints neither.
  _glyphOnMyPlate: ->
    theme = WorldWdgt.theme
    ink = theme.layoutChromeGlyph
    glyph = if (@layoutSpec?.axis ? 'x') is 'y'
      new VerticalDoubleArrowIconAppearance @, ink
    else
      new DoubleArrowIconAppearance @, ink
    [glyph, theme.layoutSpacerGlyphSize]

  # a press on me acts on nothing, so my plate shows none (the hover stays)
  _showsPressOnMyPlate: -> false

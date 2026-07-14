# The scrollable palette of slide-authoring tools, shared by SimpleSlideWdgt (the Slides
# Maker's own tool column) and SlidesToolbarCreatorButtonWdgt (the toolbar button that pops
# the same palette in a window). Both used to build this identical ~25-widget list inline;
# it now lives here once, as a `new SlidesToolPanelWdgt` at each site.
#
# Children are built in the _buildAndConnectChildrenNoSettle core reached via the settling
# _buildAndConnectChildren wrapper (the ScrollPanelWdgt / check-constructors-build.js contract:
# a constructor must not @add its own children inline). Constructed standalone (an orphan at
# each call site), the wrapper's settle defers, so the batch is added NoSettle and the caller
# settles once on attach — as before. The batched _addManyNoSettle is deliberate: an earlier
# measurement found it ~2x faster (avg ~5.4 ms vs ~10 ms) and lower-variance than adding the
# widgets one at a time.

class SlidesToolPanelWdgt extends ScrollPanelWdgt

  constructor: ->
    super new ToolPanelWdgt
    @_buildAndConnectChildren()

  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @_addManyNoSettle [
      new TextBoxCreatorButtonWdgt
      new ExternalLinkCreatorButtonWdgt
      new VideoPlayCreatorButtonWdgt

      new WorldMapCreatorButtonWdgt
      new USAMapCreatorButtonWdgt

      new RectangleWdgt

      new MapPinIconWdgt

      new SpeechBubbleWdgt

      new DestroyIconWdgt
      new ScratchAreaIconWdgt
      new FloraIconWdgt
      new ScooterIconWdgt
      new HeartIconWdgt

      new FizzygumLogoIconWdgt
      new FizzygumLogoWithTextIconWdgt
      new VaporwaveBackgroundIconWdgt
      new VaporwaveSunIconWdgt

      new ArrowNIconWdgt
      new ArrowSIconWdgt
      new ArrowWIconWdgt
      new ArrowEIconWdgt
      new ArrowNWIconWdgt
      new ArrowNEIconWdgt
      new ArrowSWIconWdgt
      new ArrowSEIconWdgt
    ]

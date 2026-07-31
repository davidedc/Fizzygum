# The slide-authoring palette, shared by SlideWdgt (the Slides Maker's docked
# toolbar) and SlidesToolbarCreatorButtonWdgt (the button that pops the
# same palette in a window) -- one `new SlidesToolbarWdgt` at each site. The
# extraction precedent the whole ToolbarWdgt family follows: construction,
# batching and the born-locked rule all live on the ToolbarWdgt base.

class SlidesToolbarWdgt extends ToolbarWdgt

  # The two map tools belong to the LAZY 'maps' part -- see DashboardsToolbarWdgt for why the LIST
  # is filtered rather than each use guarded (order).
  _toolbarItems: ->
    items = [
      new TextBoxCreatorButtonWdgt
      new ExternalLinkCreatorButtonWdgt
      new VideoPlayCreatorButtonWdgt

      (new WorldMapCreatorButtonWdgt if WorldMapCreatorButtonWdgt?)
      (new USAMapCreatorButtonWdgt   if USAMapCreatorButtonWdgt?)

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
    (eachItem for eachItem in items when eachItem?)

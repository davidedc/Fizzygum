# The slide-authoring palette, shared by SlideWdgt (the Slides Maker's docked
# toolbar) and SlidesToolbarCreatorButtonWdgt (the button that pops the
# same palette in a window) -- one `new SlidesToolbarWdgt` at each site. The
# extraction precedent the whole ToolbarWdgt family follows: construction,
# batching and the born-locked rule all live on the ToolbarWdgt base.

class SlidesToolbarWdgt extends ToolbarWdgt

  _toolbarItems: -> [
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

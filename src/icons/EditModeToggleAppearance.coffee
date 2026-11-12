# The look of a frame strip's edit-mode toggle (EditIconButtonWdgt): a pill-shaped track, the eye and
# the pencil at its two ends, and a knob sliding underneath them. The icon on the knob names the mode
# the window is in. The other one takes the strip's active glyph ink while I am hovered or pressed,
# like every strip glyph, since it is what a press would switch to.
#
# I lie along my box's LONGER side: left to right in a strip across a frame's top, top to bottom in a
# strip down its side, with the eye at the leading end either way. One drawing serves both: it is
# written in my track's own two directions, ALONG and ACROSS, and one mapping (_inMyBox) turns those into
# my box's x and y. The glyphs are placed by that mapping and never turned, so the eye and the pencil
# stand upright whichever way I run. A strip hands me my box (FrameBarWdgt._layOutPieceInSlot: my
# length along it, one slot across it), so my direction is the strip's without my asking which.
#
# My inks are my frame's look (FrameWdgt._frameLook), read here at paint: a focus flip re-inks the
# strip's glyph pieces (FrameBarWdgt._inkGlyphButtons), which repaints me too. My metrics are the
# theme's barToggle* dials, lengths along me and thicknesses across me. What a pointer hits is my
# widget's whole box, as for every icon button.

class EditModeToggleAppearance extends IconAppearance

  # IconAppearance scales its one glyph into the box; I lay out several parts in the box instead,
  # in widget-local logical pixels (the paint convention), and scale each glyph myself.
  _paintColoredIcon: (aContext, al, at, w, h) ->
    look = @widget.parent?.frame?._frameLook()
    return unless look?
    aContext.save()
    aContext.clipToRectangle al, at, w, h
    aContext.globalAlpha = @widget.alpha
    aContext.useLogicalPixelsUntilRestore()
    widgetPosition = @widget.position()
    aContext.translate widgetPosition.x, widgetPosition.y
    @_paintToggle aContext, look
    aContext.restore()

  _paintToggle: (ctx, look) ->
    theme = WorldWdgt.theme
    trackLength = theme.barToggleTrackLength
    trackThickness = theme.barToggleTrackThickness
    inset = theme.barToggleKnobInset
    knobLength = theme.barToggleKnobLength
    knobThickness = trackThickness - 2 * inset
    travel = trackLength - 2 * inset - knobLength
    myLength = Math.max @widget.width(), @widget.height()
    myThickness = Math.min @widget.width(), @widget.height()
    trackStart = Math.round (myLength - trackLength) / 2
    trackSide = Math.round (myThickness - trackThickness) / 2
    position = @widget.knobPosition()

    track = @_inMyBox trackStart, trackSide, trackLength, trackThickness
    ctx.fillStyle = look.barToggleTrack.toString()
    ctx.fillRoundRect track.left(), track.top(), track.width(), track.height(), trackThickness / 2
    knob = @_inMyBox trackStart + inset + Math.round(position * travel), trackSide + inset, knobLength, knobThickness
    ctx.fillStyle = look.barToggleKnob.toString()
    ctx.fillRoundRect knob.left(), knob.top(), knob.width(), knob.height(), knobThickness / 2

    # An icon is on the knob from the moment the knob is nearer to it than to the other end, so a
    # slide hands the inks over at its midpoint. The one off the knob takes the active ink while my
    # widget shows itself hovered or pressed (ButtonWdgt._shownState, asked of the hand).
    offKnobInk = if @widget._shownState() is "atRest" then look.barToggleGlyph else look.barGlyphActive
    eyeOnKnob = position < 0.5
    eyeAlong = trackStart + inset + knobLength / 2
    centreAcross = trackSide + trackThickness / 2
    eye = @_inMyBox eyeAlong, centreAcross, 0, 0
    pencil = @_inMyBox eyeAlong + travel, centreAcross, 0, 0
    @_paintGlyph ctx, (new EyeIconAppearance @widget, if eyeOnKnob then look.barToggleKnobGlyph else offKnobInk), eye.left(), eye.top()
    @_paintGlyph ctx, (new PencilIconAppearance @widget, if eyeOnKnob then offKnobInk else look.barToggleKnobGlyph), pencil.left(), pencil.top()

  # A box given in my track's own directions -- `along` and `length` along me, `across` and
  # `thickness` across me -- as a rectangle in my box: the identity while I lie wide, the two swapped
  # while I stand tall. The ONE place my direction is decided, so the drawing above never asks.
  _inMyBox: (along, across, length, thickness) ->
    if @widget.height() > @widget.width()
      new Rectangle across, along, across + thickness, along + length
    else
      new Rectangle along, across, along + length, across + thickness

  _paintGlyph: (ctx, glyph, centreX, centreY) ->
    side = @widget.glyphSize
    ctx.save()
    ctx.translate Math.round(centreX - side / 2), Math.round(centreY - side / 2)
    ctx.scale side / glyph.specificationSize.width(), side / glyph.specificationSize.height()
    glyph.paintFunction ctx
    ctx.restore()

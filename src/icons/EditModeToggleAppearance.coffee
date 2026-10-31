# The look of a frame strip's edit-mode toggle (EditIconButtonWdgt): a pill-shaped track, the eye and
# the pencil at its two ends, and a knob sliding underneath them. The icon on the knob names the mode
# the window is in. The other one takes the strip's active glyph ink while I am hovered or pressed,
# like every strip glyph, since it is what a press would switch to.
#
# My inks are my frame's look (FrameWdgt._frameLook), read here at paint: a focus flip re-inks the
# strip's glyph pieces (FrameBarWdgt._inkGlyphButtons), which repaints me too. My metrics are the
# theme's barToggle* dials. What a pointer hits is my widget's whole box, as for every icon button.

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
    trackWidth = theme.barToggleTrackWidth
    trackHeight = theme.barToggleTrackHeight
    inset = theme.barToggleKnobInset
    knobWidth = theme.barToggleKnobWidth
    knobHeight = trackHeight - 2 * inset
    travel = trackWidth - 2 * inset - knobWidth
    trackX = Math.round (@widget.width() - trackWidth) / 2
    trackY = Math.round (@widget.height() - trackHeight) / 2
    position = @widget.knobPosition()

    ctx.fillStyle = look.barToggleTrack.toString()
    ctx.fillRoundRect trackX, trackY, trackWidth, trackHeight, trackHeight / 2
    ctx.fillStyle = look.barToggleKnob.toString()
    ctx.fillRoundRect trackX + inset + Math.round(position * travel), trackY + inset, knobWidth, knobHeight, knobHeight / 2

    # An icon is on the knob from the moment the knob is nearer to it than to the other end, so a
    # slide hands the inks over at its midpoint.
    offKnobInk = if @widget.state is @widget.STATE_NORMAL then look.barToggleGlyph else look.barGlyphActive
    eyeOnKnob = position < 0.5
    eyeX = trackX + inset + knobWidth / 2
    centreY = trackY + trackHeight / 2
    @_paintGlyph ctx, (new EyeIconAppearance @widget, if eyeOnKnob then look.barToggleKnobGlyph else offKnobInk), eyeX, centreY
    @_paintGlyph ctx, (new PencilIconAppearance @widget, if eyeOnKnob then offKnobInk else look.barToggleKnobGlyph), eyeX + travel, centreY

  _paintGlyph: (ctx, glyph, centreX, centreY) ->
    side = @widget.glyphSize
    ctx.save()
    ctx.translate Math.round(centreX - side / 2), Math.round(centreY - side / 2)
    ctx.scale side / glyph.specificationSize.width(), side / glyph.specificationSize.height()
    glyph.paintFunction ctx
    ctx.restore()

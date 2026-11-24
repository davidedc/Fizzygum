# The background of a frame's STRIP (FrameBarWdgt's titlebarBackground): the rounded box of
# BoxyAppearance, plus the GRIP MARK, a field of square dots centred in the strip, whenever the strip
# shows no piece and no title and its frame's look gives the mark an ink -- a band's strip, a band being
# a card: a docked band no thicker than its strip offers no collapse piece (FrameWdgt._offersCollapse),
# and a bare strip reads as a grey square, not as the band's handle. A window's look names no ink, so a
# window strip narrowed below its one piece shows nothing at all. It is
# paint, not a control: a press anywhere on the strip, on a dot or between them, is the strip's, and
# nothing new sits in the tree for a copy, a save or the world inventory to meet.
#   Two fields of the instance, kept apart the way a strip's rule is (BoxyAppearance.ruledEdge): WHETHER
# the mark shows is the strip's SHAPE, which its arrange decides (FrameBarWdgt.gripMarkShows, copied here
# by FrameBarWdgt._shapeTitlebarBackground), and its INK is its frame's LOOK (barGripMark, set by
# FrameBarWdgt._skinTitlebarBackgroundTo; a look naming none shows no mark). Where the dots stand is
# mine: on my PLATE, my box less my edge rule, at the theme's dot size, pitch and inset
# (barGripMarkDotSize, barGripMarkPitch, barGripMarkInset), in whole logical pixels.
class FrameStripAppearance extends BoxyAppearance

  showsGripMark: false
  gripMarkInk: undefined

  # The mark is ART, so it takes its geometry from my widget's box and paints the whole field; the
  # open scope has already clipped it to the damage box, which places nothing.
  _paintBandOverMyFill: (ctx, localDamageBox) ->
    return unless @showsGripMark and @gripMarkInk?
    theme = WorldWdgt.theme
    size = theme.barGripMarkDotSize
    plate = @_plateRect()
    columns = @_dotStartsAlong plate.left(), plate.width()
    rows = @_dotStartsAlong plate.top(), plate.height()
    ctx.fillStyle = @gripMarkInk.toString()
    for x in columns
      for y in rows
        @_fillLocalRectSnappedToDevicePixels ctx, new Rectangle x, y, x + size, y + size
    return

  # My PLATE, widget-local: my box less the rule along my edge, where I paint one (_edgeRuleRect).
  _plateRect: ->
    w = @widget.width()
    h = @widget.height()
    rule = @_edgeRuleRect()
    return new Rectangle 0, 0, w, h unless rule?
    switch @ruledEdge
      when "top" then new Rectangle 0, rule.bottom(), w, h
      when "right" then new Rectangle 0, 0, rule.left(), h
      when "bottom" then new Rectangle 0, 0, w, rule.top()
      when "left" then new Rectangle rule.right(), 0, w, h

  # Where my dots start along one axis of my plate, which starts at `plateStart` and runs `length`: as
  # many dots as fit the inset in from both ends, a pitch apart, the field they make centred on the
  # plate; none where not even one fits. Integers throughout, so every dot is whole device pixels.
  _dotStartsAlong: (plateStart, length) ->
    theme = WorldWdgt.theme
    size = theme.barGripMarkDotSize
    pitch = theme.barGripMarkPitch
    count = Math.max 0, Math.floor((length - 2 * theme.barGripMarkInset - size) / pitch) + 1
    field = (count - 1) * pitch + size
    start = plateStart + Math.floor (length - field) / 2
    (start + i * pitch for i in [0...count])

# The body of a window or a card: the rounded box of BoxyAppearance, plus the GRIP STRIP along the
# edge opposite its bar -- its bottom, or its right beside a bar down its left -- whenever its frame's
# grip would show (FrameWdgt._gripStripRect, _gripStripSide). The strip is part of
# the frame's own body and not a child widget, so a press on it, a drop on it and a right-click on it
# are all the ones its frame's body already answers, and nothing new sits in the tree for a copy, a
# save or the world inventory to meet.
#   The strip stands inside the frame's border and rounds the two corners it shares with the frame's
# outline to the frame's rounding less that border, so its curve runs inside the border's, as the title
# strip's does (FrameBarWdgt._shapeTitlebarBackground). Its rule runs along the edge facing the frame's
# content: its top, or its left. That rule's two corners are square, and its ends reach the frame's border.
class FrameBodyAppearance extends BoxyAppearance

  _paintBandOverMyFill: (ctx, localDamageBox) ->
    strip = @widget._gripStripRect()
    return unless strip?
    theme = WorldWdgt.theme
    radius = Math.max 0, Math.round(@getCornerRadius()) - theme.frameBorderWidth
    down = @widget._gripStripSide() is "right"
    ctx.fillStyle = theme.frameGripStripFill.toString()
    ctx.fillRoundRect strip.left(), strip.top(), strip.width(), strip.height(), (if down then [0, radius, radius, 0] else [0, 0, radius, radius])
    rule = if down
      new Rectangle strip.left(), strip.top(), strip.left() + theme.barRuleWidth, strip.bottom()
    else
      new Rectangle strip.left(), strip.top(), strip.right(), strip.top() + theme.barRuleWidth
    toBePainted = rule.intersect localDamageBox
    return unless toBePainted.isNotEmpty()
    ctx.fillStyle = theme.frameGripStripRule.toString()
    @_fillLocalRectSnappedToDevicePixels ctx, toBePainted

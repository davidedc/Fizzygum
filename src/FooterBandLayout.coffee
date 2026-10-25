# FooterBandLayout

# The FOOTER BAND -- the row of buttons a window's content ends in -- as ONE geometry, class-side
# only, never instantiated. Its hosts (CodeAreaWdgt's family: the code prompt, the script window,
# the console and the error log; and BinWdgt) each place their pane above the band and ask me for
# the rest. The numbers are the draft's (docs/archive/redesign/desktop-canvas.html, the inspector's
# footer), all of them Theme metrics.
#
# In a host's box, the band is its bottom footerBandHeight:
#   - its top row is a footerRuleWidth RULE across the whole width. It is a SEAM the host owns
#     (visual-design-system §4.1): the pane above ends where the rule starts and the buttons start
#     below it, so the rule lies in a gap between siblings and nothing paints over it. The host
#     answers it from _seamRects (ruleIn) and its appearance paints it;
#   - below the rule, every button at its own extent -- a button sizes itself (preferredExtent),
#     and the band never shrinks or wraps one -- centred down the rest of the band, floored;
#   - a LEFT group from footerInset in, footerGap apart, and a RIGHT group footerGap apart whose
#     right edge lies footerInset + footerGripClearance short of the box's right edge: the band's
#     right end is kept clear for the frame's resize grip in that corner;
#   - when the box is too narrow for both, the right group starts footerGap after the left group
#     ends (footerInset in, when there is no left group) instead of overlapping it, and whatever
#     then runs past the box is clipped by the window.
# Every answer is a pure function of the box and the buttons' extents, in integers, so arranging
# again at the same box moves nothing (the arrange-idempotence oracle,
# Fizzygum-tests/scripts/staleness-census.js).
class FooterBandLayout

  # The y my band starts at in `box` (a Rectangle, in whatever coordinates the caller works in):
  # the row my rule lies on, and so where the pane above me ends.
  @topIn: (box) ->
    box.bottom() - WorldWdgt.theme.footerBandHeight

  # My rule in `box`: footerRuleWidth tall at my top, across the whole box. A host answers it from
  # its _seamRects, handing me its LOCAL box (origin 0,0).
  @ruleIn: (box) ->
    top = @topIn box
    new Rectangle box.left(), top, box.right(), top + WorldWdgt.theme.footerRuleWidth

  # PURE: the bounds of every button in `box`, from the extents (Points) of the left group's
  # buttons and of the right group's, each list in order, left to right. Answers
  # {left, right}: the two groups' bounds (Rectangles), in the same orders.
  @buttonBoundsIn: (box, leftExtents, rightExtents) ->
    theme = WorldWdgt.theme
    rowTop = @topIn(box) + theme.footerRuleWidth
    rowHeight = theme.footerBandHeight - theme.footerRuleWidth
    boundsAt = (x, extent) ->
      y = rowTop + Math.floor (rowHeight - extent.y) / 2
      new Rectangle x, y, x + extent.x, y + extent.y

    left = []
    x = box.left() + theme.footerInset
    for extent in leftExtents
      left.push boundsAt x, extent
      x += extent.x + theme.footerGap
    # x is now the least x the right group may start at: footerGap past the left group's end, or
    # footerInset in when there is no left group

    rightWidth = 0
    rightWidth += extent.x for extent in rightExtents
    rightWidth += theme.footerGap * (rightExtents.length - 1) if rightExtents.length > 0
    x = Math.max x, box.right() - theme.footerInset - theme.footerGripClearance - rightWidth
    right = []
    for extent in rightExtents
      right.push boundsAt x, extent
      x += extent.x + theme.footerGap

    left: left, right: right

  # Lay `host`'s footer buttons out across its current bounds: leftButtons and rightButtons, each
  # in order, left to right. Only a button that is the HOST'S CHILD takes part: one taken out of
  # it is not the host's to place, and the others close up. Each takes its own preferredExtent.
  # An in-pass placement, hence the `_` tier: a host calls it from its own arrange, after applying its
  # own bounds, and nothing outside a layout pass may.
  @_arrange: (host, leftButtons, rightButtons) ->
    left = (button for button in leftButtons when button?.parent is host)
    right = (button for button in rightButtons when button?.parent is host)
    bounds = @buttonBoundsIn host.bounds, (button.preferredExtent() for button in left), (button.preferredExtent() for button in right)
    for button, i in left
      button._reLayout bounds.left[i]
    for button, i in right
      button._reLayout bounds.right[i]
    return

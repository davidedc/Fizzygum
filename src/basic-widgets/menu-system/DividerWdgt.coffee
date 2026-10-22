# The band between two GROUPS of rows in a menu or a prompt (and in any row-stack that mints one
# via CommandPanelWdgt.createLine). It is a first-class type so removeConsecutiveLines can identify
# dividers via the isDivider role query rather than by `instanceof RectangleWdgt` — the latter
# mistakes ANY stray RectangleWdgt in a menu for a divider.
#
# The look (redesign plan §2, rule D: a band whose look is its own rule): a band menuDividerGap +
# menuDividerRuleWidth + menuDividerGap tall with NO fill of its own, so the pop-up's body shows
# through it, painting one menuDivider rule centred down it (DividerAppearance). The rows panel
# hands every child the full content width, so the rule spans it. The band is the theme's, never a
# caller's: every group boundary reads the same. Its minimum extent is 5x1 (a divider relaxes the
# default minimum, as SliderWdgt does). Note the explicit `super()` (empty parens):
# RectangleWdgt's constructor is (extent, color), and a divider is built extent-less and sized via
# _applyHeight below.


class DividerWdgt extends RectangleWdgt

  constructor: ->
    super()
    @_setMinimumExtent new Point 5,1
    theme = WorldWdgt.theme
    # my colour is my rule's ink: the band itself paints nothing
    @color = theme.menuDivider
    @appearance = new DividerAppearance @
    @_applyHeight 2 * theme.menuDividerGap + theme.menuDividerRuleWidth


  # Role query for removeConsecutiveLines' "is this row a divider?" test, dispatched
  # via ?() so non-divider rows (which do not answer it) read falsy -- a duck-typed
  # role query in place of an `instanceof DividerWdgt` chain (type-test elimination).
  isDivider: ->
    true

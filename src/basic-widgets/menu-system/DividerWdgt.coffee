# The band between two GROUPS of rows in a menu or a prompt (and in any row-stack that mints one
# via CommandPanelWdgt.createLine). A class of its own, so a row-stack tells a group boundary from
# any other row by asking it (separatesRowGroups), and a RectangleWdgt in a menu is never taken for one.
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


  # I separate two groups of rows: a boundary standing right after another bounds an empty group (its
  # rows were removed once the menu was built), so it goes (CommandPanelWdgt.removeConsecutiveLines,
  # which asks every row; only a boundary answers).
  separatesRowGroups: ->
    true

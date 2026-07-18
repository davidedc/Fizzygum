# A thin horizontal divider line separating groups of rows in a menu (and any
# row-stack that mints one via MenuWdgt.createLine). It is a first-class type so
# removeConsecutiveLines can identify dividers by `instanceof DividerWdgt` rather
# than by `instanceof RectangleWdgt` — the latter mistakes ANY stray
# RectangleWdgt in a menu for a divider.
#
# The look: a 230-grey box, minimum extent 5x1, sized to height + 2. Note the
# explicit `super()` (empty parens): RectangleWdgt's constructor is (extent,
# color), so `super height` would set the extent instead — a divider is built
# extent-less and sized via _applyHeight below.


class DividerWdgt extends RectangleWdgt

  constructor: (height = 1) ->
    super()
    @_setMinimumExtent new Point 5,1
    @color = Color.create 230,230,230
    @_applyHeight height + 2

  colloquialName: ->
    "divider"

  # Role query for removeConsecutiveLines' "is this row a divider?" test, dispatched
  # via ?() so non-divider rows (which do not answer it) read falsy -- a duck-typed
  # role query in place of an `instanceof DividerWdgt` chain (type-test elimination).
  isDivider: ->
    true

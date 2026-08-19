# The scroll frame a pop-up keeps its rows in — ALWAYS, not only when they overflow
# (PopUpWdgt._buildRowsViewportNoSettle explains why it is unconditional).
#
# It is what makes a pop-up bigger than the world REACHABLE: `popUp`'s `_moveWithin world`
# clamps a POSITION and can do nothing about a FIT, so without this the overflow is simply
# drawn past the edge where nothing can click it. Bounded to the world and scrolled, the
# overflow is reachable instead of lost.
#
# The composition is the one ListWdgt uses: a ViewportWdgt keeping its own plain content
# pane, with the pop-up's MenuRowsPanelWdgt placed INSIDE that pane. ⛔ The rows panel must
# NOT be my `contents` directly: ViewportWdgt._positionAndResizeChildren constrains a
# contained VerticalStackPanelWdgt's width to the viewport, while
# MenuRowsPanelWdgt._positionAndResizeChildren hugs its width back to its widest row — the
# two fight and recalculateLayouts raises RECALC_NONCONVERGENCE. A menu OWNS its width, so
# it can never be the width-constrained contents of anything.
#
# Like my pane (PopUpRowsPaneWdgt), everything I have to say is a per-class declaration a
# plain scroll panel gets wrong — see that class for the hit-testing one, which is the
# subtle member of the set.

class PopUpRowsViewportWdgt extends ViewportWdgt

  constructor: ->
    # my pane, not the plain PanelWdgt the base would build: the pane carries the chrome
    # declarations, and a plain panel's answers are wrong on every one of them.
    super new PopUpRowsPaneWdgt()
    # the base takes its own paint values from its contents; a pop-up's body is drawn by the
    # rows panel alone, so neither I nor my pane paint anything.
    @alpha = 0

  # See PopUpRowsPaneWdgt: `alpha = 0` stops me PAINTING, and this stops me CATCHING. My rows
  # panel is opaque where the menu body is, so rows still take their own clicks; everywhere
  # else the hit falls through me as it falls through the pop-up.
  isTransparentAt: (aPoint) ->
    true

  providesAmenitiesForEditing: undefined

  # a pop-up's REACHABILITY depends on scrolling (that is this class's whole
  # reason to exist), and I am transparent chrome no menu opens on anyway
  # (see ViewportWdgt.offersScrollPolicyToggle)
  offersScrollPolicyToggle: false

  # drag me and you mean the pop-up (see the pane)
  isLockingToPanels: true

  _acceptsDrops: false

  hiddenFromHierarchyMenu: ->
    true

  colloquialName: ->
    "menu rows viewport"

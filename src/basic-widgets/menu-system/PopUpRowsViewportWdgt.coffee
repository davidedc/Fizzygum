# The rows viewport a pop-up keeps its rows in — ALWAYS, not only when they overflow
# (PopUpWdgt._buildRowsViewportNoSettle explains why it is unconditional).
#
# It is what makes a pop-up bigger than the world REACHABLE: `popUp`'s `_moveWithin world`
# clamps a POSITION and can do nothing about a FIT, so without this the overflow is simply
# drawn past the edge where nothing can click it. Bounded to the world and scrolled, the
# overflow is reachable instead of lost.
#
# My contents plane IS the pop-up's MenuRowsPanelWdgt, directly — no intermediate pane.
# That is legal for that self-sizing panel because its hug is also a pure measure I commit
# VERBATIM (its scrolledContentMeasure + scrolledContentMeasureIsMyFrame declarations), so
# its arrange and my frame commit write byte-the-same box in every state; the two-writer
# oscillation that used a middle pane to keep the writers apart is dissolved at the root
# (falsification history + the dissolution record: PopUpWdgt._buildRowsViewportNoSettle).
#
# Everything I have to say is a per-class DECLARATION a plain viewport gets wrong: a
# pop-up's innards are CHROME — not an editing surface, not a drop target, not loose
# content, and (the one that is easy to miss) not a HIT TARGET.

class PopUpRowsViewportWdgt extends ViewportWdgt

  constructor: (rowsPanel) ->
    super rowsPanel
    # ⚠ pinned AFTER super: _buildViewportChromeNoSettle mimics the contents' alpha (the
    # panel paints the menu body at 1), and an alpha-1 viewport would paint its RECTANGULAR
    # appearance behind the menu's rounded corners.
    @alpha = 0

  # My plane's direct children are the pop-up's OWN rows and header, not loose scrollable
  # content, so the loose-content policies (drag-scroll-vs-detach, caret follow, the
  # soft-wrap menu row, container re-fit climbs) must not treat them as content — same
  # opt-out, same reason as ListWdgt. Without this, dragging a menu by its HEADER tears the
  # header out of the panel instead of moving the menu (measured, the dissolution's Phase-0
  # suite run: the header relocates as a bare strip and the body re-hugs headerless).
  contentsPanelHoldsLooseContent: ->
    false

  # My contents is a hug-sizing stack whose measure answers its full self-box — commit the
  # content frame from that pure measure (the VerticalStackViewportWdgt pattern), never from
  # the applied-bounds read-back branch.
  isContentSizing: ->
    true

  # The membership-change absorb: the rows panel's direct parent is ME, so the stack's
  # _reactToChildRemoved ask lands here — and I am not the widget a lost row resizes: I am
  # sized by the pop-up from the panel's hug. PopUpWdgt._reLayOutAfterContainedPanelChange
  # does the whole job (re-lay the rows panel, re-fit me, re-take the pop-up's own extent),
  # so the question goes there, and its answer — was it absorbed — is the one the stack is
  # waiting for. Without this a row leaving a LIVE menu leaves the pop-up drawn at its old
  # height, with a blank strip where the row was.
  _reLayOutAfterContainedPanelChange: ->
    @firstParentThatIsAPopUp()._reLayOutAfterContainedPanelChange?() ? false

  # ⚠ `alpha = 0` is about PAINTING, not hit-testing: the pointer asks `catchesPointerAt`,
  # and a RectangularAppearance widget answers opaque for ANY point inside its tight box
  # before consulting any transparency field. So without this, a viewport spanning the
  # pop-up's whole rect catches every click that ought to fall THROUGH the pop-up's rounded
  # corners to whatever is behind. My rows panel is opaque where the menu body is, so rows
  # still take their own clicks; everywhere else the hit falls through me as it falls
  # through the pop-up (mirrors MenuWdgt/PromptWdgt, the other transparent overlays).
  isTransparentAt: (aPoint) ->
    true

  # I am structure, not an editing surface. ViewportWdgt says `true`, and the editor
  # SELECTION walk (WorldWdgt._widgetBeingEdited) climbs to the first ancestor with an
  # OPINION. `undefined` = no opinion, so the walk passes through me.
  providesAmenitiesForEditing: undefined

  # a pop-up's REACHABILITY depends on scrolling (that is this class's whole
  # reason to exist), and I am transparent chrome no menu opens on anyway
  # (see ViewportWdgt.offersScrollPolicyToggle)
  offersScrollPolicyToggle: false

  # drag me and you mean the pop-up: my plane holds a pop-up's body, not loose content
  # someone may pull out of me (Widget.grabsToParentWhenDragged)
  isLockingToPanels: true

  _acceptsDrops: false

  # I am an implementation detail of a pop-up, so stay OUT of the ancestor
  # hierarchy-disambiguation menu, exactly as MenuRowsPanelWdgt does.
  hiddenFromHierarchyMenu: ->
    true

  colloquialName: ->
    "menu rows viewport"

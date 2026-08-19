# The content pane inside a pop-up's rows scroll frame (PopUpRowsViewportWdgt) — the
# plain panel a ViewportWdgt scrolls, holding one child: the pop-up's MenuRowsPanelWdgt.
#
# It exists as a class rather than a configured PanelWdgt because everything it has to say
# is a per-class DECLARATION that a plain panel gets wrong. A pop-up's innards are CHROME:
# they are not an editing surface, not a drop target, not draggable out, and — the one that
# is easy to miss — not a HIT TARGET.
#
# ⚠ `alpha = 0` is about PAINTING, not hit-testing. The question the pointer puts is
# `catchesPointerAt`; the members below are how I answer it. An appearance-less widget is
# opaque by an explicit `? false` (Widget.isTransparentAt), and a PanelWdgt is worse than
# appearance-less: RectangularAppearance.isTransparentAt returns false for ANY point inside
# the tight bounding box, before it looks at anything — no transparency field reaches that
# branch (`backgroundTransparency` only decides the padding halo OUTSIDE the tight box, and
# `alpha` is never consulted at all). So a panel spanning a pop-up's whole rect catches every
# click that ought to fall THROUGH the pop-up's rounded corners to whatever is behind, and no
# amount of turning it invisible changes that — which is exactly what MenuWdgt.isTransparentAt
# exists to prevent, and whose absence that class's own comment records: "a submenu popped
# over a parent menu stopped the parent's item from staying hover-highlighted".

class PopUpRowsPaneWdgt extends ScrolledPaneWdgt

  # I paint nothing — the rows panel inside me draws the pop-up's whole visible body (box,
  # header, rows). My frame reads this off me at build (ViewportWdgt takes its own paint
  # values from its contents), so declaring it here settles both of us.
  alpha: 0

  # I draw nothing and I catch nothing: the rows panel inside me is opaque where the menu
  # body is, so it takes every click meant for a row, and everywhere else the hit falls
  # through me exactly as it falls through the pop-up I am inside. Mirrors
  # MenuWdgt/PromptWdgt, the two other transparent overlays that declare this per class.
  isTransparentAt: (aPoint) ->
    true

  # I am structure, not an editing surface. PanelWdgt says `true`, and the editor SELECTION
  # walk (WorldWdgt._widgetBeingEdited, the D21 selected-item branch) climbs to the first
  # ancestor with an OPINION — so inheriting that answer frames every clicked menu row as a
  # selected item inside an editor. `undefined` = no opinion, which is what the rows panel
  # and the pop-up both answer, so the walk passes through me to the world and frames nothing.
  providesAmenitiesForEditing: undefined

  # Drag me and you mean the pop-up: my child is a pop-up's body, not loose content someone
  # may pull out of me (Widget.grabsToParentWhenDragged). Without this, dragging a menu by
  # its header TEARS the rows out and leaves the pop-up standing empty.
  isLockingToPanels: true

  _acceptsDrops: false

  # The membership-change absorb query, forwarded. SimpleVerticalStackPanelWdgt._reactToChildRemoved
  # puts it to its DIRECT parent, which is me — and I am not the widget a lost row resizes: I am
  # sized by my frame and the frame by the pop-up. PopUpWdgt._reLayOutAfterContainedPanelChange does
  # the whole job (re-lay the rows panel, re-fit the frame, re-take the pop-up's own extent), so the
  # question goes there, and its answer — was it absorbed — is the one the stack is waiting for.
  #   Without this a row leaving a LIVE menu leaves the pop-up drawn at its old height, with a blank
  # strip where the row was. Nothing showed it before rows could be dragged out: every
  # removeMenuItem call in the tree runs inside an addWidgetSpecificMenuEntries override, while the
  # menu is still being composed and before it has popped up.
  _reLayOutAfterContainedPanelChange: ->
    @firstParentThatIsAPopUp()._reLayOutAfterContainedPanelChange?() ? false

  # I am an implementation detail of a pop-up, so stay OUT of the ancestor
  # hierarchy-disambiguation menu, exactly as MenuRowsPanelWdgt does.
  hiddenFromHierarchyMenu: ->
    true

  colloquialName: ->
    "menu rows pane"

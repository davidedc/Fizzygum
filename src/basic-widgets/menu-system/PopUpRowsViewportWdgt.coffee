# The rows viewport a pop-up frame keeps its rows in — ALWAYS, not only when they overflow.
# There is no over-tall case and no ordinary case, just the one structure that fits either. A
# conditional viewport would buy a few widgets per menu at the price of a THRESHOLD, and a
# threshold is a state transition somebody has to get right: a menu composed short and grown
# later (addMenuItem on an open menu) would have to restructure itself mid-life, in the middle
# of the very membership change that provoked it. With the viewport always present there is
# nothing to cross — a menu that fits simply has nothing to scroll, and ViewportWdgt hides a bar
# with nothing to show.
#
# I am my frame's @contents, and my MEASURE is what SIZES it: my rows' natural extent, bounded
# by the world MINUS my frame's own chrome, on BOTH axes. That bound is the whole mechanism —
# whatever does not fit becomes scrollable instead of unreachable — and it is both axes because
# the defect is not about height: a pop-up wider than the world loses its right-hand columns
# exactly as one taller than it loses its bottom rows, and popUp's `_moveWithin world` clamps a
# POSITION and can do nothing about a FIT. It is world MINUS CHROME because the thing that must
# fit is the FRAME (viewport + strip), not me: capped at the bare world extent, the frame
# overflows by exactly its chrome and its own _assertFitsInTheWorld fires.
#
# My contents plane IS the pop-up's CommandPanelWdgt, directly — no intermediate pane.
# That is legal for that self-sizing panel because its hug is also a pure measure I commit
# VERBATIM (its scrolledContentMeasure + scrolledContentMeasureIsMyFrame declarations), so
# its arrange and my frame commit write byte-the-same box in every state; the two-writer
# oscillation that used a middle pane to keep the writers apart is dissolved at the root
# (falsification history: docs/archive/menu-sandwich-dissolution-plan.md, Phase 0).
#
# Everything I have to say is a per-class DECLARATION a plain viewport gets wrong: a
# pop-up's innards are CHROME — not an editing surface, not a drop target, not loose
# content, and (the one that is easy to miss) not a HIT TARGET.

class PopUpRowsViewportWdgt extends ViewportWdgt

  constructor: (rowsPanel) ->
    super rowsPanel
    # ⚠ pinned AFTER super: _buildViewportChromeNoSettle mimics the contents' alpha, and an
    # alpha-1 viewport would paint its RECTANGULAR appearance behind the menu's rounded corners.
    @alpha = 0

  # My plane's direct children are the pop-up's OWN rows, not loose scrollable content, so the
  # loose-content policies (drag-scroll-vs-detach, caret follow, the soft-wrap menu row,
  # container re-fit climbs) must not treat them as content — same opt-out, same reason as
  # ListWdgt. Without this, dragging a menu tears a row out of the panel instead of moving the
  # menu (measured, the dissolution's Phase-0 suite run).
  contentsPanelHoldsLooseContent: ->
    false

  # My contents is a hug-sizing stack whose measure answers its full self-box — commit the
  # content frame from that pure measure (the VerticalStackViewportWdgt pattern), never from
  # the applied-bounds read-back branch.
  isContentSizing: ->
    true

  # As my frame's content I keep the size I have and I do not set my height freely: a pop-up IS
  # its rows, so the rows dictate the frame's extent rather than the other way round. Grow 0 —
  # nothing stretches me.
  initialiseDefaultFrameContentLayoutSpec: ->
    @_contentStackSpec = new FrameContentLayoutSpec FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW , FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW, 0
    @_contentStackSpec.canSetHeightFreely = false

  # THE PURE MEASURE MY FRAME SIZES ITSELF FROM (see the class comment): my rows' hug, capped
  # to the world less my frame's own chrome, on both axes. Width-independent — my rows hug
  # themselves — so the width hint is not consulted.
  preferredExtentForWidth: (ignored_availW) ->
    hug = @contents.preferredExtentForWidth undefined
    frame = @enclosingFrame()
    chromeWidth = 0
    chromeHeight = 0
    if frame?.isFrame?() and @_contentStackSpec?
      chromeWidth = frame._chromeWidth()
      chromeHeight = frame._chromeHeight @_contentStackSpec
    new Point (Math.min hug.x, world.width() - chromeWidth),
              (Math.min hug.y, world.height() - chromeHeight)

  # The no-input sibling: my druthers ARE my measure (nothing about it varies with an offered
  # width), and the frame's first-placement negotiation asks through this one.
  preferredExtent: ->
    @preferredExtentForWidth undefined

  # THE MEMBERSHIP-CHANGE ABSORB, and the one place a pop-up re-takes its size. The rows panel's
  # direct parent is ME, so the stack's _reactToChildRemoved ask lands here — and I am not the
  # widget a lost row resizes: what has to change is the FRAME. So I do the whole job — re-lay
  # the rows, re-fit myself to my capped measure, hand my frame the extent that implies, and
  # re-arm its first-placement one-shot so the next arrange re-negotiates at the new hug — and
  # answer "absorbed", which is what the stack is waiting for. Without this a row leaving a LIVE
  # menu leaves the frame drawn at its old height, with a blank strip where the row was: the
  # frame's own re-fit path keeps the width its first placement latched (measured, spike S1).
  #   The frame is reached through the pop-up climb, which STOPS AT IT (FrameWdgt
  # .enclosingFrame); outside a frame there is nothing to absorb into.
  _reLayOutAfterContainedPanelChange: ->
    frame = @enclosingFrame()
    return false unless frame?.isFrame?() and @_contentStackSpec?
    @contents._reLayoutChildren()
    measure = @preferredExtentForWidth undefined
    @_applyExtentBase measure
    @_reLayoutChildren()
    frame._applyExtentBase new Point (measure.x + frame._chromeWidth()),
                                     (measure.y + (frame._chromeHeight @_contentStackSpec))
    @_contentStackSpec.desiredWidth = undefined
    frame._invalidateLayout() unless world?._recalculatingLayouts
    true

  # ⚠ `alpha = 0` is about PAINTING, not hit-testing: my RectangularAppearance is SHAPED over my
  # whole tight box whatever my alpha, because alpha changes how a shape is painted and never
  # where it is. So without this, a viewport spanning the pop-up's whole body would catch every
  # click that ought to fall THROUGH the frame's rounded corners to whatever is behind. My rows
  # panel is shaped where the menu body is, so rows still take their own clicks; everywhere else
  # the hit falls through me to my frame, and through the frame's own shape beyond it.
  #   ⓘ I am the one widget that overrides this while carrying an appearance that would answer:
  # my shape genuinely is that rect, and what I am declaring here is a ROLE — invisible chrome,
  # never a pointer target — which is a widget's business, not a shape's.
  catchesPointerAt: (aPoint) ->
    false

  # I am structure, not an editing surface. ViewportWdgt says `true`, and the editor
  # SELECTION walk (WorldWdgt._widgetBeingEdited) climbs to the first ancestor with an
  # OPINION. `undefined` = no opinion, so the walk passes through me.
  providesAmenitiesForEditing: undefined

  # a pop-up's REACHABILITY depends on scrolling (that is this class's whole
  # reason to exist), and I am transparent chrome no menu opens on anyway
  # (see ViewportWdgt.offersScrollPolicyToggle)
  offersScrollPolicyToggle: false

  # My rows panel keeps the menu border itself and my box IS its box, so a frame holding me adds no
  # body margin of its own -- a second margin would only double the first. The capability query a
  # frame asks its payload for its chrome margin (FrameWdgt._chromePadding); a payload without an
  # opinion takes the margin preference.
  keepsItsOwnChromeMargin: ->
    true

  # drag me and you mean the pop-up: my plane holds a pop-up's body, not loose content
  # someone may pull out of me (Widget.grabsToParentWhenDragged)
  isLockingToPanels: true

  _acceptsDrops: false

  # I am an implementation detail of a pop-up, so stay OUT of the ancestor
  # hierarchy-disambiguation menu, exactly as CommandPanelWdgt does.
  hiddenFromHierarchyMenu: ->
    true

  colloquialName: ->
    "menu rows viewport"

  # The pop-up frame my rows belong to (see CommandPanelWdgt._holdingPopUp): my parent, because
  # I am its content. A plain viewport does not answer this at all, which is how a list's rows
  # panel learns it is in no pop-up.
  holdingPopUp: ->
    @parent

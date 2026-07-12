# A TransformFrameWdgt that TRACKS its single content child's SIZE — a "hugging" island whose slot
# (@bounds) follows the wrapped widget's bounds. This is a CAPABILITY VARIANT of the base island, the
# same shape as WindowWdgt / SimpleVerticalStackPanelWdgt / ScrollPanelWdgt each being a size-tracking
# container: in this layout architecture the tracking-container capability is a CLASS, never a per-widget
# flag (a freefloating child's _invalidateLayout climbs THROUGH to its parent iff the parent DEFINES
# _reLayoutChildren — Widget:4039 — and that check is method existence, i.e. class identity).
#
# The base TransformFrameWdgt is a FIXED figure and deliberately does NOT define _reLayoutChildren, so a
# coupled explicit island living inside a stack keeps the freefloating-skip and stays byte-identical
# (Phases 1–3). This subclass DOES define it, so the settle loop's ordered up-edge
# (_reFitMyTrackingContainerAfterSettle) re-fits it after its content settles (docs/layout-system-
# architecture-assessment.md §6.1 rule 4). The property sugar (Widget._materializeSugarIslandNoSettle)
# materialises THIS class, so a rotated/scaled widget's slot GROWS with the widget instead of the buffer
# clipping at the frozen footprint (affine transforms — rough edge R3, docs/affine-transforms-plan.md §6,
# the deferred 4A-2 item (b)).
#
# @_materializedBySugar stays the ORTHOGONAL auto-remove-at-identity gate (inherited): a future
# explicitly-authored hugging island would be this class with the flag false. colloquialName is inherited
# ("transform frame"), so hierarchy/menu labels are unchanged — only constructor.name differs.

class TrackingTransformFrameWdgt extends TransformFrameWdgt

  # Canonical tracking-container shape (Stack/ScrollPanel): super places me, then _reLayoutChildren
  # re-fits my slot to the just-settled content. implementsDeferredLayout is pinned false so defining
  # _reLayout does not flip the (@_reLayout != Widget::_reLayout) classification — the SAME reason
  # SimpleVerticalStackPanelWdgt / ScrollPanelWdgt pin it — keeping subWidgetsMergedFullBounds and the
  # resize classification exactly as the base fixed-figure island's.
  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()

  implementsDeferredLayout: ->
    false

  # Re-fit my slot to my single content child's bounds. The up-edge enqueues me only AFTER the content
  # has fully settled, so content.bounds is final — a ONE-PASS idempotent arrange (rule 2/3): slot ←
  # child bounds is naturally idempotent, uses NO public setter and NO _invalidateLayout (FLOWRULE forbids
  # scheduling layout mid-pass), and does not climb. A hugging island is 'slot' claimsSpace (the paint-
  # only firewall), so the slot change needs no parent reflow; _refreshIslandBuffer rebuilds the buffer
  # from @bounds every composite, so it grows to the new slot and the content no longer clips. Setting
  # @bounds directly is the established island slot-set idiom (wrapContent / _materializeSugarIslandNoSettle
  # both do it) — _applyExtent would no-op here (the fixed-figure _applyExtentBase override early-returns).
  # The cache-break + fullChanged mirror what a transform change does. (The original R3 "Option A" —
  # let an asymmetric grow re-centre the figure via the nil slot-centre anchor — was superseded by the
  # §7.5 Bug-D anchor-stability rule below: persisting content must stay screen-still across a re-fit.)
  _reLayoutChildren: ->
    content = @childrenNotHandlesNorCarets()?[0]
    return if !content?
    newSlot = new Rectangle content.left(), content.top(), content.right(), content.bottom()
    return if newSlot.equals @bounds
    # Bug-D fix (anchor stability): a nil anchor means "slot centre", so an
    # EXTENT change moves the anchor and rigidly translates every persisting screen
    # point by (I - sR)delta (collapse: the title bar visibly jumps). Pin the anchor at
    # its current absolute point across extent changes; translate a pinned anchor on
    # pure moves; un-pin when it coincides with the centre again (canonical minimal form).
    if !@transformSpec.isIdentity()
      if newSlot.extent().equals @bounds.extent()
        if @transformSpec.anchor?
          @transformSpec.anchor = @transformSpec.anchor.add newSlot.topLeft().subtract @bounds.topLeft()
      else
        @transformSpec.anchor = @transformSpec._anchorFor @bounds
    @bounds = newSlot
    if @transformSpec.anchor? and @transformSpec.anchor.equals newSlot.center()
      @transformSpec.anchor = nil
    @__breakMoveResizeCaches()
    @_lastClaimedExtent = nil
    @fullChanged()

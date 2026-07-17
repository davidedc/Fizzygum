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
  #
  # (up-edge endgame V1-c, docs/upedge-endgame-plan.md §9) SYNC-SETTLE a PENDING content before the
  # re-hug — the landed window→stack P2 shape (WindowWdgt._positionAndResizeChildren): parent-before-
  # child order walks ME before my free-floating content, so without this the re-hug no-ops on the
  # content's STALE bounds and the content's own later settle re-arms me through the settle-time
  # up-edge — a wasted visit + a second one, per drop/resize gesture. Settling the content HERE is
  # the SAME _reLayout() the settle loop would run on its own turn one round later, with identical
  # inputs (I hand my content nothing — it consumes only its own pending state), so it is
  # byte-identical; the re-hug then reads FINAL bounds in my one visit. Deliberately NOT gated on
  # implementsDeferredLayout (unlike the window's Path B, which uses it to mean "already settled
  # through another channel" — I drive no sizing protocol, and a deferred-classified content like
  # StretchableWidgetContainerWdgt needs this exactly as a leaf does) and NOT gated on transform
  # state (this extends the TRACKING capability, which hugs at identity too — the authored explicit
  # island; the §5a DORMANT GUARANTEE governs the transparency overrides below, not this). The
  # _reLayoutMayResizeOwnWidth exclusion is kept verbatim (the §6 early-settle width caution).
  _reLayout: (newBoundsForThisLayout) ->
    super
    content = @_soleContent()
    if content? and !content.layoutIsValid and !content._reLayoutMayResizeOwnWidth?()
      content._reLayout()
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
  # arrangeDriven distinguishes the TWO re-fit regimes on an EXTENT change (follow-up F1,
  # docs/…-layout-transparency-plan.md §9): a CONTENT-driven re-fit (bare call — the settle-loop
  # up-edge, my own _reLayout) keeps the Bug-D pin so a user handle-resizing the wrapped widget
  # sees persisting screen points stay still; an ARRANGE-driven re-fit (true — forwarded from my
  # §5a _applyExtent / _setWidthSizeHeightAccordingly under a laying-out parent) NILs the anchor,
  # because the parent's fractional model OWNS placement (§5c records SLOT-box fractions) and a
  # pinned anchor inherited from an earlier user gesture decouples the render from the slot the
  # model is placing — telescoping d = A − c by extΔ/2 each frame, rendering the content offset
  # by (I − sR)(A − c) (probe leg E: 14.7px drift). Nil-ing re-glues the render to the slot and
  # converges. See §9.3/§9.4 for the algebra and why nil (not Bug-G normalize) is the locked choice.
  _reLayoutChildren: (arrangeDriven = false) ->
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
      else   # extent changed
        if arrangeDriven
          @transformSpec.anchor = nil                                 # arrange owns placement: render GLUED to the slot (F1)
        else
          @transformSpec.anchor = @transformSpec._anchorFor @bounds    # content-driven: Bug-D pin, unchanged
    @bounds = newSlot
    if @transformSpec.anchor? and @transformSpec.anchor.equals newSlot.center()
      @transformSpec.anchor = nil
    @__breakMoveResizeCaches()
    @_lastClaimedExtent = nil
    @fullChanged()

  # ---------------------------------------------------------------------------
  # LAYOUT TRANSPARENCY — the FOURTH member of the sugar-island transparency family (hit /
  # interaction / reparent / LAYOUT), docs/drop-into-rotated-container-layout-transparency-plan.md §5.
  # The invisible sugar/compensating island is plumbing, so a PARENT-DRIVEN sizing protocol must
  # pass THROUGH to my sole content — otherwise the base island's §4.9 FIXED-FIGURE policy blocks it
  # (TransformFrameWdgt._applyExtentBase early-returns; preferredExtentForWidth reports the frozen
  # claimed extent), and a widget dropped into / rotated inside a StretchablePanelWdgt or a vertical
  # stack never stretches or width-fits on a container resize. I forward extent / width-size / measure
  # to my content; the existing CONTENT→SLOT tracking re-fit (_reLayoutChildren above, incl. the Bug-D
  # anchor-pinning) then re-hugs the slot, so I settle AT the requested extent. The content's own
  # subtree is re-laid-out by its OWN polymorphic _applyExtent override (StretchablePanel / Stack /
  # ScrollPanel / TextWdgt all override it), which content._applyExtent dispatches to — so no explicit
  # content._reLayout() forward is needed.
  #
  # DORMANT GUARANTEE: IDENTITY (or EMPTY, no content) ⇒ super on every override, byte-identical to the
  # base island — no non-transformed / empty island is touched. Scope is THIS class only (the sugar/
  # compensating wrappers); the base fixed-figure TransformFrameWdgt keeps §4.9 unchanged, so an
  # authored explicit island in a stack stays a fixed figure (SystemTest_macroExplicitIslandFixed-
  # VsTrackingResize pins that distinction — it drives the CONTENT→SLOT direction, unaffected here).
  # ---------------------------------------------------------------------------
  _soleContent: ->
    @childrenNotHandlesNorCarets()?[0]

  # Parent arrange sizes ME → size my content, then re-hug the slot to it. I override the POLYMORPHIC
  # _applyExtent (like StretchablePanel / Stack / ScrollPanel / TextWdgt add their re-fit here), NOT the
  # bypass twin _applyExtentBase — a _apply*Base must bypass the override, never route the apply back
  # through the polymorphic _applyExtent (layering rule [K]); and the arrange sizes a tracking island
  # (a _reLayoutChildren? child) only through _applyExtent / _setWidthSizeHeightAccordingly, never a
  # direct _applyExtentBase (that path is for LEAF children). The `aPoint.equals @extent()` guard is the
  # SAME one Widget._applyExtentBase uses, and is LOAD-BEARING: my own _reLayout (super ⇒ Widget._reLayout
  # ⇒ _applyExtent) re-applies my CURRENT slot extent every settle pass, and because the slot is
  # invariantly content-coincident that extent equals my content's — so without the guard a content-first
  # growth (the authored-tracking case) would re-forward the STALE pre-re-hug slot extent onto the
  # just-grown content and shrink it back. A genuine parent resize passes a DIFFERENT extent, so it still
  # forwards. (When aPoint == @extent(), content._applyExtent would no-op anyway; the guard just also
  # keeps _reLayout's spurious self-apply inert.)
  _applyExtent: (aPoint) ->
    content = @_soleContent()
    return super aPoint if @transformSpec.isIdentity() or !content?
    return if aPoint.equals @extent()
    content._applyExtent aPoint
    @_reLayoutChildren true    # ARRANGE-driven re-fit: nil the anchor so the render stays glued to the slot (F1)

  # Path B (the width→height container protocol a vertical stack drives its tracking-container children
  # through, SimpleVerticalStackPanelWdgt._positionAndResizeChildren): size my content to the width by
  # ITS OWN width→height policy (text wrap / clock square / ratio) and HAND BACK the resulting height —
  # in my plane that IS my slot height after the re-hug (the slot being content-coincident), = the
  # content height. EVERY _setWidthSizeHeightAccordingly override must return its height (the historical
  # break point, Widget.coffee §720-727). Only the stack arrange calls this — never my own _reLayout —
  # so no stale-extent guard is needed.
  _setWidthSizeHeightAccordingly: (newWidth) ->
    content = @_soleContent()
    return super newWidth if @transformSpec.isIdentity() or !content?
    resultingHeight = content._setWidthSizeHeightAccordingly newWidth
    @_reLayoutChildren true    # ARRANGE-driven re-fit: nil the anchor so the render stays glued to the slot (F1)
    resultingHeight

  # Keep MEASURE and ARRANGE coherent: report what my content would take at the offered width (the
  # arrange sizes it exactly so, via _setWidthSizeHeightAccordingly above). Bypassing the base's
  # @_lastClaimedExtent reflow memo is safe — it is read only by _reflowIfClaimChangedNoSettle, gated on
  # claimsSpace != 'slot', and every sugar/compensating island is 'slot' (the paint-only firewall).
  preferredExtentForWidth: (availW) ->
    content = @_soleContent()
    return super availW if @transformSpec.isIdentity() or !content?
    content.preferredExtentForWidth availW

  # The stack min-clamps a child's measured extent to its getMinimumExtent (SimpleVerticalStackPanelWdgt.
  # _childMeasuredExtentInStack); forward my content's minimum so measure and arrange clamp to the SAME
  # value (the arrange applies through content._applyExtent, whose __commitExtent clamps to the content's
  # own min). Dormant at identity/empty (super ⇒ @minimumExtent). My OWN __commitExtent reads the
  # @minimumExtent FIELD directly (Widget.coffee:2103), not this getter, so overriding it here does not
  # perturb my own slot commits.
  getMinimumExtent: ->
    content = @_soleContent()
    return super() if @transformSpec.isIdentity() or !content?
    content.getMinimumExtent()

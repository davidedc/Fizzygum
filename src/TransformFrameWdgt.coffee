# TransformFrameWdgt — the "island" that makes a widget subtree rotatable / scalable.
#
# Part of the affine-transforms feature (see docs/affine-transforms-plan.md, esp.
# §4.1, §4.2, §4.4, §4.11). It is the Squeak/CSS-compositor primitive: an invisible
# clipping frame that owns ONE content subtree and a TransformSpec. It rasterizes
# its content UN-transformed into a back buffer and composites that buffer through
# the transform (§4.2). Everything inside it uses ordinary absolute Fizzygum
# coordinates as if the island were untransformed (the "virtual plane"); the
# transform is applied only at composite time.
#
# COMPOSITE (plan §4.2) has three paths, picked by the spec:
#  - identity  → stock invisible-clipping-panel blit (byte-identical to the bare children).
#  - pure scale (rotation 0, scale ≠ 1) → the "scale-only fast path": an unequal-src/dst
#    drawImage (axis-aligned, no setTransform, no ctx.clip; the damage clip is a plain rect
#    intersection of the dst rect).
#  - rotation (Phase 2) → render-straight-then-warp: set the context transform to
#    (device × island matrix) and drawImage the buffer onto the slot box, under a MANDATORY
#    real path clip to (damage ∩ screen footprint) — a transformed drawImage cannot express
#    the broken-rect clip via src/dst rects, and a spill would paint over un-repainted front
#    content (z-order corruption, §4.2). For a non-zero angle the matrix trig comes from the
#    deterministic DetTrig port (cross-engine-identical, Phase 0a); SWCanvas samples nearest-
#    neighbour (Phase 0f, accepted for v1).
#
# WHY it extends PanelWdgt: PanelWdgt already augments ClippingAtRectangularBounds-
# Mixin, giving us a clipping frame whose bounds-recursion terminates at itself
# (fullBounds/fullClippedBounds → its own bounds) and whose children are clipped to
# its box. The island's own @bounds is the SLOT BOX (integer, axis-aligned,
# absolute — unchanged Fizzygum geometry) that layout sees. We make the frame
# itself invisible (@appearance = nil ⇒ both background and stroke paint no-op) so
# an IDENTITY island is byte-for-byte just its children painted normally (the
# identity-island pixel-identity gate).
#
# DORMANT GUARANTEE: when a spec is identity, EVERY override here falls back to the
# stock PanelWdgt/Widget behaviour (super), so an identity island is a plain
# invisible clipping panel and the whole feature adds zero behaviour on any hot
# path when no non-identity island exists.

class TransformFrameWdgt extends PanelWdgt

  transformSpec: nil
  # Phase 3 (§4.9): last claimed extent reported to the parent layout, for reflow-on-change
  # detection. nil for a 'slot' island (the default — never reflows).
  _lastClaimedExtent: nil
  # Phase 4C (§6): true when this island was MATERIALIZED by the Widget-level property sugar
  # (widget.setRotationDegrees / setScaleFactor). Only a sugar-materialized island is auto-REMOVED
  # when its spec returns to identity (an explicitly-authored island stays, merely dormant). Serializes
  # as a plain boolean so a saved-then-reloaded sugar island stays sugar-removable.
  _materializedBySugar: false

  constructor: (contentWidget = nil, transformSpec = nil) ->
    super()   # PanelWdgt ctor (sets appearance/color/stroke) — we blank them below
    @transformSpec = transformSpec ? new TransformSpec()
    # invisible frame: no background, no stroke, no chrome of its own.
    @appearance = nil
    @color = nil
    @strokeColor = nil
    # Phase 1: islands refuse to be drop targets (plan §4.6 scope cut).
    @_acceptsDrops = false
    # The island is invisible PLUMBING and never claims a pointer hit itself — its
    # CONTENT provides the clickable surface (the descent tests children first, then
    # self). isTransparentAt → true + noticesTransparentClick false ⇒ the hit-test
    # predicate never selects the island; a click on empty content falls through to
    # what's behind, a click on opaque content lands on the content widget (§4.6).
    @noticesTransparentClick = false
    if contentWidget?
      @wrapContent contentWidget

  colloquialName: ->
    "transform frame"

  # never a hit target itself (see the ctor note): the descent still recurses into
  # the content subtree, whose widgets ARE hit-tested (with the plane-mapped point).
  isTransparentAt: (aPoint) ->
    true

  # Wrap an existing widget: the slot box becomes the widget's current bounds (the
  # untransformed footprint), and the widget becomes the island's single free-
  # floating child, keeping its absolute position (virtual ≡ screen at identity).
  wrapContent: (contentWidget) ->
    @bounds = new Rectangle contentWidget.left(), contentWidget.top(), contentWidget.right(), contentWidget.bottom()
    @add contentWidget
    @

  # ---------------------------------------------------------------------------
  # the transform spec + its mutation (invalidation mirrors a move: §6 step 2).
  # Each public mutator is the canonical self-settling wrapper (@_settleLayoutsAfter
  # => the _<name>NoSettle core) — the SAME public tier moveTo/setExtent use. The
  # settle is where a coupled island's reflow (_invalidateLayout, reached bare inside
  # the core) is resolved; for a 'slot' island the core invalidates NOTHING, so the
  # settle is a genuine no-op and Phase-1/2 rendering is byte-identical.
  # ---------------------------------------------------------------------------
  setScale: (s) ->
    @_settleLayoutsAfter => @_setScaleNoSettle s

  _setScaleNoSettle: (s) ->
    return if !(s > 0) or s == @transformSpec.scale
    @transformSpec.scale = s   # set the canonical scalar directly (guarded above)
    @_transformChangedNoSettle()

  # Phase 2: rotate the island by `deg` degrees about its anchor (default the slot centre).
  # A transform change damages the screen (old ∪ new footprint) but never dirties the buffer
  # (§4.5 invariant).
  setRotation: (deg) ->
    @_settleLayoutsAfter => @_setRotationNoSettle deg

  _setRotationNoSettle: (deg) ->
    return if deg == @transformSpec.rotationDegrees
    @transformSpec.rotationDegrees = deg   # set the canonical scalar directly
    @_transformChangedNoSettle()

  # Phase 3: change the layout-coupling mode (plan §4.9). Entering/leaving a coupled mode
  # ('footprint'/'sweep') changes the claimed extent, so it reflows the parent's layout —
  # through the SAME entry a resize uses (_invalidateLayout), settled by the wrapper above.
  setClaimsSpace: (mode) ->
    @_settleLayoutsAfter => @_setClaimsSpaceNoSettle mode

  _setClaimsSpaceNoSettle: (mode) ->
    return if mode == @transformSpec.claimsSpace
    @transformSpec.claimsSpace = mode   # set the canonical scalar directly
    @_lastClaimedExtent = nil
    @__breakMoveResizeCaches()
    @fullChanged()
    @_invalidateLayout()

  # The immediate (no-settle) transform-change core: invalidates the version-keyed bounds caches
  # exactly as a move does (__breakMoveResizeCaches bumps WorldWdgt.geometryVersion), queues the
  # new footprint via fullChanged() (the OLD footprint is the last-painted snapshot the flesh-out
  # lane reads as the "source" rect), and — for a coupled island — invalidates the parent's layout.
  _transformChangedNoSettle: ->
    @__breakMoveResizeCaches()
    @fullChanged()
    @_reflowIfClaimChangedNoSettle()

  # ---------------------------------------------------------------------------
  # layout coupling (plan §4.9). A NON-IDENTITY island is a FIXED FIGURE for its
  # parent's layout: it reports its CLAIMED box (slot box for 'slot'; footprint
  # AABB / sweep square for the coupled modes) as a fixed extent, is never
  # stretched, and offsets its slot box within the claimed box. An IDENTITY island
  # falls through to super — byte-identically the bare wrapped widget, incl. in a
  # stack (dormant guarantee). No Phase-1/2 test puts an island in a stack, so this
  # changes nothing existing. Only the REFLOW-on-transform-change is further gated on
  # claimsSpace != 'slot' — the paint-only Lively firewall.
  # ---------------------------------------------------------------------------
  _claimsFixedFigure: ->
    !@transformSpec.isIdentity()

  # 'slot' NEVER reflows (paint-only firewall). A coupled island reflows its parent — through the
  # resize entry (_invalidateLayout) — but ONLY when the claimed extent actually changed. Correct
  # by construction: 'footprint' reflows on angle/scale (its AABB changes); 'sweep' reflows on
  # scale/extent but NOT rotation (its circumscribed square is rotation-invariant).
  # 'slot' NEVER reflows (paint-only firewall) — it invalidates nothing, so the enclosing
  # wrapper's settle is a no-op and Phase-1/2 rendering is byte-identical. A coupled island
  # invalidates the parent's layout (bare — the public wrapper's _settleLayoutsAfter settles it)
  # but ONLY when the claimed extent actually changed: 'footprint' reflows on angle/scale (its
  # AABB changes), 'sweep' reflows on scale/extent but NOT rotation (its square is rotation-
  # invariant). Correct by construction — no need to know what changed.
  _reflowIfClaimChangedNoSettle: ->
    return if @transformSpec.claimsSpace == "slot"
    newClaim = @transformSpec.claimedExtentFor @bounds
    return if @_lastClaimedExtent? and newClaim.equals @_lastClaimedExtent
    @_lastClaimedExtent = newClaim
    @_invalidateLayout()

  # what we report to the parent's arrange: a non-identity island claims a FIXED figure size (the
  # slot box / footprint AABB / sweep square, §4.9), independent of the offered width — measured,
  # not stretched. An identity island measures normally (super).
  #
  # PURE-MEASURE EXEMPTION (deliberate): this writes @_lastClaimedExtent, which the pure-measure
  # campaign would normally forbid in a preferredExtentFor* method. It is load-bearing here:
  # @_lastClaimedExtent is the reflow-detection memo (see _reflowIfClaimChangedNoSettle), and it must
  # track the claim across BOTH a transform change AND a plain slot-box RESIZE. The transform path
  # updates it itself; a slot resize does NOT go through that path — its only contact with the claim is
  # this measure. So the memo lives here by necessity. It is idempotent (same @bounds ⇒ same value) and
  # observed only by this widget's own reflow gate, so it introduces no cross-widget measure impurity.
  preferredExtentForWidth: (availW) ->
    return super availW if !@_claimsFixedFigure()
    @_lastClaimedExtent = @transformSpec.claimedExtentFor @bounds
    @_lastClaimedExtent

  # the parent's arrange sizes leaf children to their reported (claimed) extent; a non-identity
  # island IGNORES that so @bounds stays the SLOT box (Phases 1-2 build the buffer + composite
  # from it — the slot box is fixed by wrapContent, never stretched). Identity islands size normally.
  _applyExtentBase: (aPoint) ->
    return if @_claimsFixedFigure()
    super aPoint

  # the parent's arrange hands us the top-left of our CLAIMED box; commit the SLOT box at
  # claimedOrigin + slotOffset so the slot sits correctly inside the reserved footprint/sweep
  # region (§4.9; the offset is ZERO for 'slot', whose claimed box IS the slot box). Only the
  # arrange-leaf placement comes through _applyMoveToBase; a drag/direct move comes through
  # _applyMoveTo/moveTo and is NOT offset. Identity islands place directly.
  _applyMoveToBase: (aPoint) ->
    if @_claimsFixedFigure()
      aPoint = aPoint.add @transformSpec.slotOffsetWithinClaim(@bounds)
    super aPoint

  # ---------------------------------------------------------------------------
  # compositing (plan §4.2)
  # ---------------------------------------------------------------------------
  # We intercept at the content-recursion point (…ContentPotentiallyAsShadow), which
  # the base fullPaintIntoAreaOrBlitFromBackBuffer calls for both the normal pass
  # and the "paint as shadow" pass — so honouring appliedShadow here covers both.
  fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    if @transformSpec.isIdentity()
      # stock invisible-clipping-panel behaviour: children painted, clipped to the
      # slot box, no chrome (appearance is nil). Byte-identical to the children alone.
      return super aContext, clippingRectangle, appliedShadow
    @_compositeIslandBuffer aContext, clippingRectangle, appliedShadow

  # The island is TRANSPARENT (appearance nil), so it must cast its CONTENT's shadow,
  # not a box silhouette. PanelWdgt/ClippingAtRectangularBoundsMixin's JustShadow
  # takes an opaque-panel shortcut (paint the box silhouette; skip children when
  # alpha==1) — wrong here (there is no box to silhouette). Revert to the BASE Widget
  # behaviour: translate to the shadow offset and paint the CONTENT as shadow, which
  # routes through …ContentPotentiallyAsShadow above — so identity casts the children's
  # shadow (⇒ an identity island is pixel-identical to the bare wrapped widget, which
  # as a world child would itself cast that shadow) and a non-identity island casts a
  # correctly SCALED content shadow for free (plan §4.8).
  fullPaintIntoAreaOrBlitFromBackBufferJustShadow: (aContext, clippingRectangle, appliedShadow) ->
    clippingRectangle = clippingRectangle.translateBy -appliedShadow.offset.x, -appliedShadow.offset.y
    if !@preliminaryCheckNothingToDraw clippingRectangle, aContext
      aContext.save()
      aContext.translate appliedShadow.offset.x * ceilPixelRatio, appliedShadow.offset.y * ceilPixelRatio
      @fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow aContext, clippingRectangle, appliedShadow
      aContext.restore()

  # (re)build the island buffer: the content subtree rasterised UN-transformed at
  # device resolution, exactly as Widget#…RenderCanvas does for a subtree snapshot
  # (translate the buffer context by -slotOrigin×ceilPixelRatio, then paint the
  # children into it). PHASE 1: rebuilt on every composite — correctness-first; the
  # content-version-keyed cache + buffer-dirty accumulation (plan §4.4/§4.5) is a
  # later optimisation and is not needed for correctness.
  _refreshIslandBuffer: ->
    slot = @bounds
    physExtent = slot.extent().scaleBy ceilPixelRatio
    return nil if physExtent.x < 1 or physExtent.y < 1
    buffer = HTMLCanvasElement.createOfPhysicalDimensions physExtent
    bctx = buffer.getContext "2d"
    bctx.translate -slot.origin.x * ceilPixelRatio, -slot.origin.y * ceilPixelRatio
    # paint the content subtree into the buffer, un-transformed, clipped to the slot
    # box. No appliedShadow here: shadow faintness is applied at composite time.
    # While the subtree paints, flag the world so descendants record their (virtual)
    # last-painted bounds (§4.5) — save/restore for nested islands.
    prevIslandBuffer = world.paintingIntoIslandBuffer
    world.paintingIntoIslandBuffer = @
    @children.forEach (child) =>
      child.fullPaintIntoAreaOrBlitFromBackBuffer bctx, slot, nil
    world.paintingIntoIslandBuffer = prevIslandBuffer
    buffer

  # Dispatch the non-identity composite (identity is handled by the caller). A pure uniform
  # scale takes the axis-aligned fast path; any rotation takes the general warp path (§4.2).
  _compositeIslandBuffer: (aContext, clippingRectangle, appliedShadow) ->
    buffer = @_refreshIslandBuffer()
    return if !buffer?
    if @transformSpec.rotationDegrees % 360 == 0
      @_compositeScaleOnly aContext, clippingRectangle, appliedShadow, buffer
    else
      @_compositeTransformed aContext, clippingRectangle, appliedShadow, buffer

  # §4.2 scale-only fast path: a uniform scale needs no setTransform — an unequal
  # src/dst drawImage suffices, every mapped rect stays axis-aligned, and the damage
  # clip is a plain rect intersection of the dst rect (no ctx.clip()).
  _compositeScaleOnly: (aContext, clippingRectangle, appliedShadow, buffer) ->
    slot = @bounds
    s = @transformSpec.scale
    A = @transformSpec._anchorFor slot

    # exact on-screen destination rect (logical) = slot scaled by s about anchor A
    dstLeft  = A.x + s * (slot.left()   - A.x)
    dstTop   = A.y + s * (slot.top()    - A.y)
    dstRight = A.x + s * (slot.right()  - A.x)
    dstBot   = A.y + s * (slot.bottom() - A.y)
    dstRect  = new Rectangle dstLeft, dstTop, dstRight, dstBot

    visibleDst = dstRect.intersect clippingRectangle
    return if visibleDst.isEmpty()

    # map the visible dst sub-rect back to buffer-local (logical) coords: 0..slotW,
    # 0..slotH. Dividing by s inverts the scale.
    srcLeftL = (visibleDst.left() - dstLeft) / s
    srcTopL  = (visibleDst.top()  - dstTop)  / s
    srcWL    = visibleDst.width()  / s
    srcHL    = visibleDst.height() / s

    cpr = ceilPixelRatio
    sx = Math.round srcLeftL * cpr
    sy = Math.round srcTopL * cpr
    sw = Math.round srcWL * cpr
    sh = Math.round srcHL * cpr
    # Clamp the SOURCE sub-rect into the buffer. Float rounding at a partial clip edge
    # (e.g. the shadow pass' offset clip, or a scroll-frame overhang) can push it a
    # pixel past the buffer edge, and SWCanvas' drawImage THROWS on an out-of-bounds
    # source rect (native silently clips) — which, un-caught, banned the island from
    # repainting and made the frame nondeterministic. Mirror BackBufferMixin.calculate-
    # KeyValues' Math.min clamp; the dst keeps its extent, so at most a sub-pixel edge
    # strip is stretched — imperceptible and, crucially, deterministic.
    if sx < 0 then sw += sx ; sx = 0
    if sy < 0 then sh += sy ; sy = 0
    sw = Math.min sw, buffer.width - sx
    sh = Math.min sh, buffer.height - sy
    return if sw < 1 or sh < 1
    aContext.save()
    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha
    # Round the four device EDGES and derive extent from them (dr-dl, db-dt), NOT round(width)
    # independently. If one cycle splits this island's damage into adjacent strips, strip A's right
    # edge round(boundary*cpr) then equals strip B's left edge round(boundary*cpr) — gapless by
    # construction. round(l)+round(w) could disagree with round(r) by 1px on a NON-INTEGER dst edge
    # (a fractional scale/anchor), leaving a stale or doubled column at the seam. For an integer scale
    # (all current refs) the edges are already integer, so this is byte-identical.
    dl = Math.round visibleDst.left() * cpr
    dt = Math.round visibleDst.top() * cpr
    dr = Math.round visibleDst.right() * cpr
    db = Math.round visibleDst.bottom() * cpr
    aContext.drawImage buffer, sx, sy, sw, sh, dl, dt, dr - dl, db - dt
    aContext.restore()

  # §4.2 general warp path (Phase 2 — rotation, and rotation+scale): render-straight-then-warp.
  # The buffer holds the content un-transformed at device resolution; we set the context
  # transform to (device × island matrix) and drawImage the buffer onto the SLOT BOX in that
  # user space, so the rasteriser warps it in one pass (seam-free — §4.2 step 3). Because a
  # transformed drawImage cannot express the broken-rect clip via src/dst rects, a REAL path
  # clip to (damage ∩ screen footprint) is MANDATORY (§4.2): the warped quad would otherwise
  # spill outside the damage rect and paint over front content not being repainted this cycle
  # (z-order corruption). We COMPOSE onto the incoming CTM (`transform`, not `setTransform`) so
  # the unified shadow pass' pre-applied offset translate is honoured — a warped faint copy at
  # the shadow offset IS the correctly rotated shadow (§4.8), no quad-silhouette special case.
  # On the normal pass the incoming CTM is identity, so this equals setTransform. SWCanvas
  # samples nearest-neighbour (Phase 0f, accepted). v1 warps the WHOLE buffer under the clip
  # (correctness-first, like _refreshIslandBuffer); the §4.2 sub-rect optimisation is banked.
  _compositeTransformed: (aContext, clippingRectangle, appliedShadow, buffer) ->
    slot = @bounds
    footprint = @_screenFootprintForDamage()          # rotated slot-box AABB (logical, padded)
    visibleDst = footprint.intersect clippingRectangle
    return if visibleDst.isEmpty()
    m = @transformSpec.matrixForSlot slot             # virtual-logical → screen-logical
    cpr = ceilPixelRatio
    aContext.save()
    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha
    # clip in the INCOMING coordinate space (device pixels — identity CTM on the normal pass,
    # the shadow-offset translate on the shadow pass) BEFORE the warp, so the clip is the actual
    # on-screen damage region and the warp transform below does not move it.
    aContext.clipToRectangle visibleDst.left() * cpr, visibleDst.top() * cpr, visibleDst.width() * cpr, visibleDst.height() * cpr
    # CTM ← (incoming CTM) · (device-scale · island matrix): maps virtual-logical slot coords → device.
    aContext.transform cpr * m.a, cpr * m.b, cpr * m.c, cpr * m.d, cpr * m.e, cpr * m.f
    aContext.drawImage buffer, 0, 0, buffer.width, buffer.height, slot.left(), slot.top(), slot.width(), slot.height()
    aContext.restore()

  # ---------------------------------------------------------------------------
  # the island's TWO FACES for clipping / bounds (plan §4.11)
  #  - to DESCENDANTS (clipThrough consumed via firstParentClippingAtBounds):
  #    the SLOT BOX only — a plane-pure clip terminal (ancestor SCREEN clips do not
  #    commute with the transform, so they are deliberately NOT intersected in here;
  #    they are applied to inner damage AFTER mapping, in the flesh-out hook).
  #  - to the OUTER WORLD (clippedThroughBounds / fullClippedBounds — what the parent
  #    merges, what flesh-out reads when the island itself is queued, what the
  #    hit-test AABB pre-filter sees): the SCREEN FOOTPRINT = mapRect(slot box) ∩ the
  #    ancestor screen clip chain. Larger than the slot box when scaled up
  #    ("ink overflow").
  # fullClippedBounds / SLOWfullClippedBounds are inherited from
  # ClippingAtRectangularBoundsMixin and delegate to clippedThroughBounds /
  # SLOWclippedThroughBounds, so overriding those two (+ clipThrough) is sufficient.
  # SLOW-oracle twins are overridden IN LOCKSTEP (doubleCheckCachedMethodsResults gate).
  # ---------------------------------------------------------------------------

  # screen footprint of the slot box under the current spec (padded integer AABB).
  _screenFootprintForDamage: ->
    @transformSpec.mapRect @bounds, @bounds

  _ancestorScreenClip: ->
    fp = @firstParentClippingAtBounds()
    fp = world if !fp?
    fp.clipThrough()

  _SLOWancestorScreenClip: ->
    fp = @SLOWfirstParentClippingAtBounds()
    fp = world if !fp?
    fp.SLOWclipThrough()

  # child-facing clip terminal: the slot box only (plane-pure).
  clipThrough: ->
    return super() if @transformSpec.isIdentity()
    if @checkClipThroughCache == WorldWdgt.geometryVersion
      result = @cachedClipThrough
    else if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
      @checkClipThroughCache = WorldWdgt.geometryVersion
      @cachedClipThrough = Rectangle.EMPTY
      result = @cachedClipThrough
    else
      @checkClipThroughCache = WorldWdgt.geometryVersion
      @cachedClipThrough = @boundingBox()   # slot box, virtual — NO ancestor intersect
      result = @cachedClipThrough
    if world.doubleCheckCachedMethodsResults
      if !result.equals @SLOWclipThrough()
        debugger
        alert "clipThrough is broken (island)"
    return result

  SLOWclipThrough: ->
    return super() if @transformSpec.isIdentity()
    if @isOrphan() or !@SLOWvisibleBasedOnIsVisibleProperty() or @SLOWisInCollapsedSubtree()
      return Rectangle.EMPTY
    @boundingBox()

  # world-facing damage rect: screen footprint ∩ ancestor screen clips.
  clippedThroughBounds: ->
    return super() if @transformSpec.isIdentity()
    if @checkClippedThroughBoundsCache == WorldWdgt.geometryVersion
      result = @cachedClippedThroughBounds
    else if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
      @checkClippedThroughBoundsCache = WorldWdgt.geometryVersion
      @cachedClippedThroughBounds = Rectangle.EMPTY
      result = @cachedClippedThroughBounds
    else
      @checkClippedThroughBoundsCache = WorldWdgt.geometryVersion
      @cachedClippedThroughBounds = @_screenFootprintForDamage().intersect @_ancestorScreenClip()
      result = @cachedClippedThroughBounds
    if world.doubleCheckCachedMethodsResults
      if !result.equals @SLOWclippedThroughBounds()
        debugger
        alert "clippedThroughBounds is broken (island)"
    return result

  SLOWclippedThroughBounds: ->
    return super() if @transformSpec.isIdentity()
    if @isOrphan() or !@SLOWvisibleBasedOnIsVisibleProperty() or @SLOWisInCollapsedSubtree()
      return Rectangle.EMPTY
    @_screenFootprintForDamage().intersect @_SLOWancestorScreenClip()

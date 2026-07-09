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
# PHASE 1 SCOPE (scale-only, plan §6): rotation is locked to 0 by TransformSpec, so
# the composite is a pure uniform scale — done with an unequal-src/dst drawImage
# (axis-aligned, no setTransform, no ctx.clip — that is the §4.2 "scale-only fast
# path"). Phase 2 adds the setTransform + path-clip rotation composite.
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
  # the transform spec + its mutation (invalidation mirrors a move: §6 step 2)
  # ---------------------------------------------------------------------------
  setScale: (s) ->
    return if !(s > 0) or s == @transformSpec.scale
    @transformSpec.setScale s
    @_transformChanged()

  # A transform change damages the SCREEN (old footprint ∪ new footprint) but never
  # dirties the buffer (buffer content depends only on virtual content — plan §4.5
  # invariant). It invalidates the version-keyed bounds caches exactly as a move
  # does (__breakMoveResizeCaches bumps WorldWdgt.geometryVersion) and queues the
  # new footprint via fullChanged(); the OLD footprint is the last-painted snapshot
  # the flesh-out lane already reads as the "source" rect.
  _transformChanged: ->
    @__breakMoveResizeCaches()
    @fullChanged()

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

  # §4.2 scale-only fast path: a uniform scale needs no setTransform — an unequal
  # src/dst drawImage suffices, every mapped rect stays axis-aligned, and the damage
  # clip is a plain rect intersection of the dst rect (no ctx.clip()).
  _compositeIslandBuffer: (aContext, clippingRectangle, appliedShadow) ->
    buffer = @_refreshIslandBuffer()
    return if !buffer?

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
    aContext.drawImage buffer,
      sx, sy, sw, sh,
      Math.round(visibleDst.left() * cpr),
      Math.round(visibleDst.top() * cpr),
      Math.round(visibleDst.width() * cpr),
      Math.round(visibleDst.height() * cpr)
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

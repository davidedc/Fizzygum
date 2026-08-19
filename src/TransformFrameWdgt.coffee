# TransformFrameWdgt — the "island" that makes a widget subtree rotatable/scalable: an
# invisible clipping frame (extends PanelWdgt for its ClippingAtRectangularBoundsMixin
# terminal) that owns ONE content subtree + a TransformSpec, rasterizing content
# UN-transformed into a back buffer and compositing it through the transform at paint time.
# DORMANT GUARANTEE: at identity every override here falls back to stock super, so an
# identity island is byte-for-byte its bare children (referenced elsewhere in this file as
# "dormant guarantee"). Mental model + composite dispatch: docs/architecture/transforms.md §1, §8.

class TransformFrameWdgt extends PanelWdgt

  # I am a structural transform WRAPPER around ONE content subtree, never editor content myself: when a
  # MOVE of a tilted widget makes ME world.editorFocusWdgt, the editor-focus selection must frame my
  # CONTENT (which draws its frame WARPED inside my island buffer), not ME (my own @bounds are un-rotated,
  # so framing me draws an axis-aligned box that ignores the tilt). WorldWdgt._widgetBeingEdited resolves
  # through this to my content. Capability, not an `instanceof` type-test (type-test-elimination convention).
  resolvesEditorSelectionToContent: -> true

  transformSpec: undefined
  # Phase 3 (§4.9): last claimed extent reported to the parent layout, for reflow-on-change
  # detection. undefined for a 'slot' island (paint-only, never reflows) -- 'footprint' is the
  # default since the D1 flip (claimsSpace arc, 2026-07-17; TransformSpec.claimsSpace).
  _lastClaimedExtent: undefined
  # D2 scroll reachability (claimsSpace arc): last claimed ∪ ink box handed to an enclosing
  # viewport, for refit-on-change detection — the REACHABILITY twin of _lastClaimedExtent
  # (claim → sibling layout; union → scroll extent: two questions, two memos, two edges).
  _lastScrollOverflowBox: undefined
  # Phase 4C (§6): true when this island was MATERIALIZED by the Widget-level property sugar
  # (widget.setRotationDegrees / setScaleFactor). Only a sugar-materialized island is auto-REMOVED
  # when its spec returns to identity (an explicitly-authored island stays, merely dormant). Serializes
  # as a plain boolean so a saved-then-reloaded sugar island stays sugar-removable.
  _materializedBySugar: false

  # §4.4 island buffer cache: the fields below are DERIVED render state (never truth) ->
  # serializationTransients below; a deepCopy drops them (see _reactToBeingCopied). Mechanism +
  # rebuild/reuse/damage-rect policy: docs/architecture/transforms.md §8.1.
  _islandBuffer: undefined                 # the kept content canvas (physical pixels), or undefined
  _islandBufferSlotExtent: undefined       # Point: the slot extent the buffer was built at (the realloc key)
  _islandBufferDamageRects: undefined        # undefined (clean) | Array<Rectangle> (coalesced disjoint, VIRTUAL coords) | "all"
  _islandBufferGeneration: -1        # WorldWdgt.immutableBackBufferGeneration the buffer was built at
                                     # (async glyph-atlas warmup invalidation; -1 ⇒ never built)
  _islandShadowSilhouette: undefined       # black-silhouette twin of _islandBuffer for the shadow pass, or undefined
  # Per-island opt-out of the cache. Public + macro-readable (no `_`). Serialises as a plain boolean
  # (like _materializedBySugar) so a saved island keeps its policy; the GLOBAL kill-switch is the class
  # property WorldWdgt.islandBufferCacheEnabled.
  cachesBuffer: true

  # §4.4 rect-list damage coalescing: cost-ceiling tunables for the coalesced disjoint damage-rect list
  # (docs/archive/island-buffer-cache-rectlist-plan.md; mechanism: docs/architecture/transforms.md §8.1).
  @ISLAND_DAMAGE_MAX_RECTS: 8
  @ISLAND_DAMAGE_AREA_FRACTION: 0.75

  # Serialization: _lastClaimedExtent and _lastScrollOverflowBox are pure reflow/refit memos
  # (re-derived on the next preferredExtentForWidth / _reFitViewportIfReachChangedNoSettle), NOT
  # truth -- skip them so a restored island carries no stale memo. The _islandBuffer* fields are
  # DERIVED render state (a canvas + its cache keys) that a restored island rebuilds on first
  # composite -- never persist a canvas. transformSpec (the only real serialized state) round-trips
  # structurally as scalars, and _materializedBySugar / cachesBuffer as plain booleans. Merged up the
  # chain by Serializer.transientsForClass -- this ADDS to Widget's list.
  @serializationTransients: [
    "_lastClaimedExtent"
    "_lastScrollOverflowBox"
    "_islandBuffer"
    "_islandBufferSlotExtent"
    "_islandBufferDamageRects"
    "_islandBufferGeneration"
    "_islandShadowSilhouette"
  ]

  constructor: (contentWidget, transformSpec) ->
    super()   # PanelWdgt ctor (sets appearance/color/stroke) — we blank them below
    @transformSpec = transformSpec ? new TransformSpec()
    # invisible frame: no background, no stroke, no chrome of its own.
    @appearance = undefined
    @color = undefined
    @strokeColor = undefined
    # The invisible frame itself never accepts drops — permanent design, not just the Phase-1
    # §4.6 scope cut it began as: 4D confirmed no flip is needed (a drop-accepting CONTENT
    # container inside the island resolves as the dropTargetFor climb target; when the climb
    # reaches the frame — the sole-content sugar-figure case — it continues up the parent
    # chain past it, like any other non-accepting widget).
    @_acceptsDrops = false
    # The island is invisible PLUMBING and never claims a pointer hit itself — i.e.
    # catchesPointerAt is false everywhere on me; its CONTENT provides the clickable
    # surface. The two members below are how that answer is composed. See
    # docs/architecture/transforms.md §7.
    @noticesTransparentClick = false
    if contentWidget?
      @wrapContent contentWidget

  # LENS (§5.4 family): my name is my content's — a window bar / inspector title / console
  # title naming me should name the DISPLAYED thing, not the invisible plumbing. An empty
  # authored island falls back to its own name (dev-facing hierarchy/menus stay CLASS-named
  # regardless — they never ask colloquialName).
  colloquialName: ->
    @_soleContent()?.colloquialName() ? "transform frame"

  # LENS timing twin of the materialize's spec pre-seed: the ONE consumer that CAPTURES my
  # name — a FrameWdgt titles its bar at mount — asks while the materialize still holds me
  # EMPTY (the homing order), so when my content arrives, nudge a labeling parent to
  # re-derive. Intent-named public note on the receiver (the noteWallpaperChanged idiom);
  # runs inside the add's settle, so the receiver uses its non-settling label core.
  # no super: the notification hook is ?.-dispatched with no base implementation — the
  # scroll-holder relay lives on ScrolledPaneWdgt, a plane role an island never plays
  _reactToChildAdded: (aWdgt) ->
    @parent?.noteContentsNameMayHaveChanged?() unless aWdgt.isLayoutInert?()

  # Phase 4B-universal (§6): an EXPLICIT island drives the halo rotation protocol against its OWN spec
  # (not the Widget base, which would wrap the island in ANOTHER sugar island). screenAnchor honours an
  # explicit anchor; rotationHalo_apply drives the self-settling setRotation (see its note below).
  rotationHalo_screenAnchor: ->
    @screenAnchor()

  rotationHalo_currentDegrees: ->
    @transformSpec.rotationDegrees

  # Self-settling (like the plain-widget sugar path), NOT the deferred setter: the halo protocol is a
  # polymorphic dispatch, not a per-event stream handler, so it must not textually call a *DeferredSettle
  # (check-layering rule [O] — the allowlist is for the actual stream, nonFloatDragging). Since the D1
  # default flip (claimsSpace arc, 2026-07-17) a sugar island claims 'footprint', so a halo drag
  # inside a tracking container reflows the siblings PER DRAG EVENT (each settle re-reserves the
  # rotated AABB) — the owner-accepted D1 implication; a 'slot' island's per-drag settle stays a no-op.
  rotationHalo_apply: (deg) ->
    @setRotation deg

  # never a hit target itself (see the ctor note): the descent still recurses into
  # the content subtree, whose widgets ARE hit-tested (with the plane-mapped point).
  isTransparentAt: (aPoint) ->
    true

  # Bug-E fix (interaction transparency): PanelWdgt.mouseClickLeft raises on
  # click (bringToForeground) -- a behavior the WRAPPED content never had (FrameWdgt's
  # click is escalate-only). The invisible wrapper must not add interaction behavior of
  # its own: revert to the Widget-base escalate-only click, so a click inside the island
  # behaves exactly as it would untransformed (e.g. a save-as prompt spawned by the close
  # button is NOT buried by a post-spawn raise of the island).
  mouseClickLeft: (pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    @escalateEvent "mouseClickLeft", pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

  # Wrap an existing widget: the slot box becomes the widget's current bounds (the
  # untransformed footprint), and the widget becomes the island's single free-
  # floating child, keeping its absolute position (virtual ≡ screen at identity).
  wrapContent: (contentWidget) ->
    @bounds = new Rectangle contentWidget.left(), contentWidget.top(), contentWidget.right(), contentWidget.bottom()
    @add contentWidget
    @

  # my single wrapped content subtree (handles/carets are chrome, never content)
  _soleContent: ->
    @childrenNotHandlesNorCarets()?[0]

  # ---------------------------------------------------------------------------
  # The LENS declarations: an island's content-stack preferences ARE its content's knob.
  # The content-stack spec holds preferences about the DISPLAYED thing's nature ("empty
  # vertical space around a clock is meaningless", "this paragraph centers") — and the
  # island displays exactly that thing, transformed; it has no content-nature of its own.
  # Same doctrine as isTransparentAt / the escalate-only click /
  # resolvesEditorSelectionToContent: the invisible wrapper adds no behavior of its own.
  # Creation DELEGATES to the content's own class-specific initialiser (a clock content
  # yields clock defaults) and the OBJECT is SHARED — identity-mapped by both graph
  # engines (kept-spec fold E1-M4), so edits made through the island hit the one knob the
  # content resumes on unwrap, and unwrap needs no hand-off. Delegation re-runs off the
  # CURRENT sole content at every (re)initialisation, so a content change cannot leave a
  # stale borrowed knob; an EMPTY authored island falls back to its own base defaults.
  # The mount/adoption seams then operate on the shared object exactly as for any veteran
  # knob (role flip, un-latch, captureInitialPlacement re-binding .element to ME while I
  # am the armed carrier).
  # ---------------------------------------------------------------------------
  initialiseDefaultFrameContentLayoutSpec: ->
    content = @_soleContent()
    return super() if !content?
    # mirror the mount seam's own guard: only create fresh on the content when it has no
    # frame-content-capable knob — a veteran knob's explicit edits stay alive
    content.initialiseDefaultFrameContentLayoutSpec() unless content._contentStackSpec?.isFrameContentSpec?()
    @_contentStackSpec = content._contentStackSpec

  initialiseDefaultVerticalStackLayoutSpec: ->
    content = @_soleContent()
    return super() if !content?
    # the content's own initialiser carries the keep-a-capable-knob guard
    content.initialiseDefaultVerticalStackLayoutSpec()
    @_contentStackSpec = content._contentStackSpec

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
    @transformSpec = @transformSpec.withScale s   # replace the immutable spec (guarded above)
    @_transformChangedNoSettle()

  # Phase 2: rotate the island by `deg` degrees about its anchor (default the slot centre).
  # A transform change damages the screen (old ∪ new footprint) but never dirties the buffer
  # (§4.5 invariant).
  setRotation: (deg) ->
    @_settleLayoutsAfter => @_setRotationNoSettle deg

  _setRotationNoSettle: (deg) ->
    return if deg == @transformSpec.rotationDegrees
    @transformSpec = @transformSpec.withRotationDegrees deg   # replace the immutable spec
    @_transformChangedNoSettle()


  # Phase 3: change the layout-coupling mode (plan §4.9). Entering/leaving a coupled mode
  # ('footprint'/'sweep') changes the claimed extent, so it reflows the parent's layout —
  # through the SAME entry a resize uses (_invalidateLayout), settled by the wrapper above.
  setClaimsSpace: (mode) ->
    @_settleLayoutsAfter => @_setClaimsSpaceNoSettle mode

  _setClaimsSpaceNoSettle: (mode) ->
    return if mode == @transformSpec.claimsSpace
    @transformSpec = @transformSpec.withClaimsSpace mode   # replace the immutable spec
    @_lastClaimedExtent = undefined
    @__breakMoveResizeCaches()
    @_fullChanged()
    @_invalidateLayout()
    @_reFitViewportIfReachChangedNoSettle()

  # The immediate (no-settle) transform-change core: invalidates the version-keyed bounds caches
  # exactly as a move does (__breakMoveResizeCaches bumps WorldWdgt.geometryVersion), queues the
  # new footprint via _fullChanged() (the OLD footprint is the last-painted snapshot the flesh-out
  # lane reads as the "source" rect), and — for a coupled island — invalidates the parent's layout.
  _transformChangedNoSettle: ->
    # §4.5 invariant (buffer cache): a transform change damages the SCREEN (old ∪ new footprint),
    # NEVER the buffer -- buffer content depends only on VIRTUAL content, the matrix affects only
    # compositing. So we deliberately do NOT deposit a buffer-damage rect here. The one exception is
    # hygiene: if the spec just returned to IDENTITY, the identity composite path bypasses the buffer
    # entirely, so drop it (else a window-sized canvas would linger on a de-tilted explicit island).
    @_dropIslandBufferIfIdentity()
    @__breakMoveResizeCaches()
    @_fullChanged()
    @_reflowIfClaimChangedNoSettle()
    @_reFitViewportIfReachChangedNoSettle()

  # §3.6 lifecycle: release the cached buffer when the island is identity (the identity path never
  # reads it) or on any teardown. Cheap; keeps a de-tilted explicit island from pinning a big canvas.
  _dropIslandBufferIfIdentity: ->
    return if !@transformSpec.isIdentity()
    @_dropIslandBuffer()

  _dropIslandBuffer: ->
    @_islandBuffer = undefined
    @_islandBufferSlotExtent = undefined
    @_islandBufferDamageRects = undefined
    @_islandBufferGeneration = -1
    @_islandShadowSilhouette = undefined

  # deepCopy safety (§3.1): the buffer fields are DERIVED render state. HTMLCanvasElement::deepCopy
  # clones the canvas into the copy (a DISTINCT canvas -- no sharing), but a copied island must not
  # silently reuse a snapshot (the fizzytiles rebuildDerivedValue lesson: transients alone don't
  # guarantee copy-coherence). Drop them on the CLONE so it rebuilds from its own content on first
  # composite. Runs after the Duplicator's content-clone pass, so it eagerly frees the clone.
  _reactToBeingCopied: ->
    @_dropIslandBuffer()

  # ---------------------------------------------------------------------------
  # layout coupling (plan §4.9): a non-identity island is a FIXED FIGURE for its parent's
  # layout (claimed box, never stretched); reflow-on-transform-change is gated on
  # claimsSpace != 'slot' (paint-only Lively firewall). Mechanism: docs/architecture/transforms.md §5.1.
  # ---------------------------------------------------------------------------
  _claimsFixedFigure: ->
    !@transformSpec.isIdentity()

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

  # D2 scroll reachability (claimsSpace arc plan §4.1/F2): the REACHABILITY twin of the claim
  # reflow above — when my claimed ∪ ink box changed, ask the enclosing NON-content-sizing
  # viewport to re-fit its content frame, so my rotated ink stays reachable by scrolling in
  # EVERY mode including 'slot' (whose claim never changes). Deliberately NOT the climbing
  # _invalidateLayout: a free-floating child's climb DROPS at the frame's non-tracking @contents
  # PanelWdgt (Widget._invalidateLayout's freefloating gate). _reFitContainer is the sanctioned
  # phase-valved intent verb of the drop/remove/scatter seams, and the @parent.parent hop is the
  # SAME folder-frame hop the settle-time up-edge uses (_reFitMyTrackingContainerAfterSettle) —
  # it self-gates on _reLayoutChildren?, a no-op everywhere else. 'sweep' never fires on pure
  # rotation (union = rotation-invariant square ∪ nested ink hull — see
  # TransformSpec.scrollOverflowBoxFor), so a spinning sweep island keeps a perfectly still
  # scrollbar. A stale memo (after a plain move — the move paths deliberately don't maintain it)
  # can only FALSE-FIRE, never false-skip; the extra re-fit is idempotent recorded intent.
  _reFitViewportIfReachChangedNoSettle: ->
    newBox = if @transformSpec.isIdentity() then @bounds else @transformSpec.scrollOverflowBoxFor @bounds
    return if @_lastScrollOverflowBox? and newBox.equals @_lastScrollOverflowBox
    @_lastScrollOverflowBox = newBox
    @_reFitContainer @parent.parent if @_amIDirectlyInsideNonTextWrappingViewport()

  # D2 (claimsSpace arc plan §4.1): my contribution to an enclosing viewport's content
  # extent — claimed box ∪ ink hull in the PARENT plane (integer; deliberately neither the
  # layout-box family, which stays the slot box, nor the screen family, which is
  # fractional/global — docs/archive/affine-geometry-api-plan.md). Per-class capability (`?()` dispatch,
  # NO Widget base default — type-test-elimination convention); the ONE consumer is
  # Widget.subWidgetsMergedFullBounds' merge walk. undefined at identity, so the walk's stock
  # fullBounds merge runs and an untransformed island stays byte-identical (dormant guarantee).
  scrollOverflowBoundsInParentPlane: ->
    return undefined if @transformSpec.isIdentity()
    @transformSpec.scrollOverflowBoxFor @bounds

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

  # §7.5 Bug F (reparent-transparency, MOVE level): a PINNED anchor (transformSpec.anchor non-undefined, set by
  # the Bug-D asymmetric-extent-change rule) is stored as an ABSOLUTE point in the island's plane, so it
  # must RIDE a rigid translation of the island — else the figure renders about a STALE anchor and its
  # content swings by (sR − I)·delta on a plain drag (probe-verified: a 40° figure dragged by (40,30) moved
  # its centre by (11,49), i.e. R(40°)·(40,30)). An UNDEFINED anchor derives from the slot centre and rides for
  # free; the tracking re-fit translates a pinned anchor only on CONTENT-relative moves (it sets @bounds
  # directly, bypassing these primitives), so these overrides cover exactly the DIRECT-move paths it
  # early-returns on — the THREE distinct primitives that rigidly translate this island's bounds (each
  # fires for a different move kind, never two for one move): _applyMoveBy (I am the mover — a drag or the
  # 4D-2a / Bug-F pick-out re-home; ClippingAtRectangularBoundsMixin's move-and-notify path, which bypasses
  # _applyMoveByBase), _applyMoveByBase (I am arrange-placed as a leaf — the base path), and __commitMoveBy
  # (I am moved as a child of a moving ancestor). Restoring the fixed-point property also makes the pick-out
  # re-home's numeric delta correct under a pinned anchor. Dormant off pinned anchors (the entire pre-Bug-D
  # population — undefined anchor ⇒ the guard skips).
  _applyMoveBy: (delta) ->
    super delta
    @transformSpec = @transformSpec.withAnchor @transformSpec.anchor.add delta if @transformSpec?.anchor? and !delta.isZero()

  _applyMoveByBase: (delta) ->
    moved = super delta
    @transformSpec = @transformSpec.withAnchor @transformSpec.anchor.add delta if moved and @transformSpec?.anchor?
    moved

  __commitMoveBy: (delta) ->
    super delta
    @transformSpec = @transformSpec.withAnchor @transformSpec.anchor.add delta if @transformSpec?.anchor? and !delta.isZero()

  # §7.5 Bug G (reparent-transparency, PICK-UP NORMALIZATION): re-express a PINNED anchor
  # (Bug-D anchor-stability, set by a tracked resize) as the equivalent ABSENT-anchor similitude before
  # this figure travels across planes. An (anchor A, slot B) similitude renders identically to
  # (anchor undefined, whole figure translated by t = (I − sR)(A − centre)) — the Bug-D compensation algebra,
  # inverted, computed by TransformSpec._nilAnchorEquivalentTranslation (the spec owns its own
  # algebra). Every hand-carry apply-site assumes the pivot IS the slot centre (the 2b-i relative
  # re-spec, the 4D-1 slot-centre placement, the Bug-F pick re-home): true only for an ABSENT anchor, so the
  # pick-up seam normalizes once and they all stay in their simple exact math. ORDER MATTERS: CLEAR the
  # anchor FIRST (`withAnchor undefined`) — the move-level anchor-ride overrides above would otherwise drag
  # A along with the compensating translate and void the algebra. Integer rounding of t ⇒ ≤1px, acceptable
  # at a grab (a new state). No-op for an absent anchor (every un-resized figure) and at identity (anchor is inert).
  _normalizePinnedAnchorNoSettle: ->
    return if !@transformSpec?.anchor? or @transformSpec.isIdentity()
    t = @transformSpec._nilAnchorEquivalentTranslation @bounds   # read t while the anchor is still pinned
    @transformSpec = @transformSpec.withAnchor undefined
    @_applyMoveBy t.round()

  # ---------------------------------------------------------------------------
  # compositing (plan §4.2)
  # ---------------------------------------------------------------------------
  # We intercept at the content-recursion point (…ContentPotentiallyAsShadow), which
  # the base fullPaintIntoAreaOrBlitFromBackBuffer calls for both the normal pass
  # and the "paint as shadow" pass — so honouring appliedShadow here covers both.
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    if @transformSpec.isIdentity()
      # stock invisible-clipping-panel behaviour: children painted, clipped to the
      # slot box, no chrome (appearance is undefined). Byte-identical to the children alone.
      return super aContext, clippingRectangle, appliedShadow
    @_compositeIslandBuffer aContext, clippingRectangle, appliedShadow

  # The island is TRANSPARENT (appearance undefined), so it must cast its CONTENT's shadow,
  # not a box silhouette. PanelWdgt/ClippingAtRectangularBoundsMixin's JustShadow
  # takes an opaque-panel shortcut (paint the box silhouette; skip children when
  # alpha==1) — wrong here (there is no box to silhouette). Revert to the BASE Widget
  # behaviour: translate to the shadow offset and paint the CONTENT as shadow, which
  # routes through …ContentPotentiallyAsShadow above — so identity casts the children's
  # shadow (⇒ an identity island is pixel-identical to the bare wrapped widget, which
  # as a world child would itself cast that shadow) and a non-identity island casts a
  # correctly SCALED content shadow for free (plan §4.8).
  _fullPaintIntoAreaOrBlitFromBackBufferJustShadow: (aContext, clippingRectangle, appliedShadow) ->
    # Explicit GRANDPARENT delegation to the base Widget shadow-paint (was a byte-for-byte inline copy of it,
    # kept in sync by hand): `super` can't reach it — it binds to PanelWdgt/ClippingAtRectangularBoundsMixin's
    # opaque-box override. The @…ContentPotentiallyAsShadow call inside Widget's body still dispatches on `@`
    # to THIS class's override, so the routing (and pixels) are identical.
    Widget::_fullPaintIntoAreaOrBlitFromBackBufferJustShadow.call @, aContext, clippingRectangle, appliedShadow

  # the cache is live only when BOTH the global kill-switch and this island's opt-in are on.
  _islandBufferCacheActive: ->
    WorldWdgt.islandBufferCacheEnabled and @cachesBuffer

  # §3.2 invalidation: record a content-damage region (VIRTUAL coords, THIS island's plane) to be
  # re-rasterised at the next composite. v2 keeps a COALESCED DISJOINT rect-LIST (rects that touch are
  # merged), so a frame damaging several far-apart regions rebuilds only those instead of one bounding
  # box that spans them (docs/archive/island-buffer-cache-rectlist-plan.md §3.2). The "all" sentinel forces a
  # full rebuild and is sticky. Called ONLY from the §4.5 damage lanes (Widget.mapRectToScreen's
  # destination deposit + the flesh-out source lane) — never from a spec change (the §4.5 invariant: a
  # transform change damages the screen, not the buffer). Coverage invariant (§3.0): the list's union
  # only ever GROWS, so it always ⊇ every deposited grown rect ⇒ the partial rebuild stays byte-identical
  # to a full rebuild for any coalesce policy.
  _depositIslandBufferDamageRect: (aRect) ->
    return if !@_islandBufferCacheActive()
    return if @_islandBufferDamageRects == "all"
    return if !aRect? or aRect.isEmpty()
    # The incoming rect is SHADOW-INCLUSIVE in this buffer's plane: both damage lanes grow it by
    # the depositing child's paintedShadowReach in the child's own plane before it reaches here
    # (destination via mapRectToScreen's pre-grown input, source via the shadow-inclusive stash of
    # _recordDrawnAreaForNextDamageRects), so an oversized shadow's band is covered exactly. The
    # fixed grow below is the AA-fringe/margin floor (AA touches a 1px fringe; without margin the
    # old fringe ghosts under the partial rebuild — the byte-identity gate would catch it).
    # Clamped to the slot in _refreshIslandBuffer. Kept virtual (this island's plane) — the
    # composite maps it to screen.
    damage = aRect.expandBy(1).growBy world.damageRectMargin
    if !@_islandBufferDamageRects?
      @_islandBufferDamageRects = [damage]
      return
    # Fold every rect `damage` touches into it, keeping the rest disjoint. Repeat to a fixpoint: a merge
    # grows `damage` and may make it touch a rect that was clear before. isIntersecting is edge-inclusive
    # so adjacent rects coalesce too. Then apply the cost-ceiling collapse (_coalesceDamageList).
    remainder = @_islandBufferDamageRects
    loop
      touching = (r for r in remainder when damage.isIntersecting r)
      break if touching.length == 0
      remainder = (r for r in remainder when not damage.isIntersecting r)
      damage = touching.reduce ((acc, r) -> acc.merge r), damage
    remainder.push damage
    @_islandBufferDamageRects = @_coalesceDamageList remainder

  # Cost ceiling for the rect-list (§3.4): a disjoint list in, the list to store out. NEVER shrinks
  # coverage — only trades separate rects for their single bounding box, so byte-identity is preserved.
  # Collapses to the bounding box when the rect-list is disabled (the A/B baseline = v1 policy), when the
  # list grows past MAX_RECTS (N clipped subtree walks would cost more than one bbox walk), or when the
  # rects already cover AREA_FRACTION of their bounding box (one bbox walk is then as cheap).
  _coalesceDamageList: (list) ->
    return [@_boundingBoxOfRects list] if !WorldWdgt.damageRectListEnabled
    bbox = @_boundingBoxOfRects list
    return [bbox] if list.length > TransformFrameWdgt.ISLAND_DAMAGE_MAX_RECTS
    totalArea = list.reduce ((a, r) -> a + r.area()), 0
    return [bbox] if totalArea >= TransformFrameWdgt.ISLAND_DAMAGE_AREA_FRACTION * bbox.area()
    list

  _boundingBoxOfRects: (list) ->
    list.reduce ((acc, r) -> acc.merge r), list[0]

  # (re)build / reuse the island buffer: the content subtree rasterised UN-transformed at device
  # resolution, exactly as Widget#…RenderCanvas does for a subtree snapshot. §4.4 cache:
  #  - cache OFF  -> a fresh throwaway buffer every composite (byte-identical to the pre-cache code).
  #  - no buffer / slot EXTENT changed (realloc) -> full rebuild into a NEW canvas.
  #  - damaged     -> partial rebuild: clear + clipped repaint of the damage sub-rect (or the whole
  #                   slot for the "all" sentinel), INTO the kept canvas.
  #  - clean       -> reuse as-is (the transform-animation fast path: ZERO rasterisation). Each
  #                   damaged frame composites the island twice (shadow pass, then normal pass); the
  #                   first refresh clears the recorded damage so the second reuses — no special-casing.
  # A pure slot MOVE keeps the buffer: content and origin move together and the per-refresh ctx
  # translate uses the CURRENT origin, so the cached pixels stay valid (§3.2).
  _refreshIslandBuffer: ->
    slot = @bounds
    physExtent = slot.extent().scaleBy ceilPixelRatio
    return undefined if physExtent.x < 1 or physExtent.y < 1

    if !@_islandBufferCacheActive()
      return @_rasterizeIslandContent slot, physExtent, undefined

    # A full rebuild is forced by: no buffer yet; a slot EXTENT change (realloc); OR a stale
    # text-back-buffer epoch -- the one non-event async glyph-atlas invalidation the cache needs
    # (native never loads an atlas, so this never fires there). See docs/architecture/transforms.md §8.1.
    slotExtent = slot.extent()
    if !@_islandBuffer? or !(@_islandBufferSlotExtent? and @_islandBufferSlotExtent.equals slotExtent) or @_islandBufferGeneration != WorldWdgt.immutableBackBufferGeneration
      @_islandBuffer = @_rasterizeIslandContent slot, physExtent, undefined
      @_islandBufferSlotExtent = slotExtent
      @_islandBufferGeneration = WorldWdgt.immutableBackBufferGeneration
    else if @_islandBufferDamageRects?
      # "all" -> one whole-slot rebuild; otherwise clear+HARD-clip+repaint EACH disjoint damage rect (each
      # reuses the same per-rect path that is already byte-identical to a full rebuild). N is capped by
      # _coalesceDamageList so this never costs more than one bbox walk.
      if @_islandBufferDamageRects == "all"
        @_rasterizeIslandContent slot, physExtent, slot
      else
        for damageRect in @_islandBufferDamageRects
          clip = damageRect.intersect slot
          @_rasterizeIslandContent slot, physExtent, clip if clip.isNotEmpty()
    # else: clean -> reuse @_islandBuffer as-is.
    @_islandBufferDamageRects = undefined
    @_islandBuffer

  # Rasterise the content subtree into the buffer, UN-transformed at device resolution. clip undefined =>
  # a FULL build into a FRESH canvas (returned); a sub-rect => a PARTIAL rebuild INTO the kept canvas
  # (@_islandBuffer), clearing the region first — the island background is TRANSPARENT, so an
  # un-cleared region would ghost the old pixels under alpha. The buffer context is a SINGLETON per
  # canvas (getContext returns the same object), so save/restore is MANDATORY on the reused path to
  # keep the -slotOrigin translate from accumulating across composites. While the subtree paints, the
  # world is flagged so descendants record their (virtual) last-painted bounds (§4.5) — save/restore
  # for nested islands.
  _rasterizeIslandContent: (slot, physExtent, clip) ->
    # every change to the buffer's pixels funnels through here, so this is the one
    # invalidation point the shadow-silhouette twin needs.
    @_islandShadowSilhouette = undefined
    if clip?
      buffer = @_islandBuffer
      clipRect = clip
    else
      buffer = HTMLCanvasElement.createOfPhysicalDimensions physExtent
      clipRect = slot
    bctx = buffer.getContext "2d"
    bctx.save()
    bctx.translate -slot.origin.x * ceilPixelRatio, -slot.origin.y * ceilPixelRatio
    if clip?
      # clear the damage region to transparent before repaint (device px; the translate above is
      # already applied, so this is the VIRTUAL rect × ceilPixelRatio). No appliedShadow here —
      # shadow faintness is applied at composite time.
      bctx.clearRect clipRect.left() * ceilPixelRatio, clipRect.top() * ceilPixelRatio, clipRect.width() * ceilPixelRatio, clipRect.height() * ceilPixelRatio
      # HARD-clip the repaint to the cleared region. The clippingRectangle arg below is only a CULLING
      # hint — a child's SHADOW (painted via a ctx translate) or an over-hanging blit can escape it and
      # paint OUTSIDE the cleared region, over the still-valid old pixels there → a doubled (alpha-
      # accumulated) shadow. A real ctx clip guarantees the partial rebuild touches ONLY the cleared
      # rect, so it is byte-identical to a full rebuild there and leaves the rest of the buffer intact.
      bctx.clipToRectangle clipRect.left() * ceilPixelRatio, clipRect.top() * ceilPixelRatio, clipRect.width() * ceilPixelRatio, clipRect.height() * ceilPixelRatio
    prevIslandBuffer = world.paintingIntoIslandBuffer
    world.paintingIntoIslandBuffer = @
    try
      @children.forEach (child) =>
        child.fullPaintIntoAreaOrBlitFromBackBuffer bctx, clipRect, undefined
    finally
      # restore in `finally`: a throwing child paint propagates to _repaintDamagedRects's per-rect
      # catch, and a skipped restore would leave the world flag stuck on this island (every
      # later ordinary paint would stash spurious buffer-damage deposits against it via
      # Widget._recordDrawnAreaForNextDamageRects) and the buffer ctx clipped
      world.paintingIntoIslandBuffer = prevIslandBuffer
      bctx.restore()
    buffer

  # Dispatch the non-identity composite (identity is handled by the caller). A pure uniform
  # scale takes the axis-aligned fast path; any rotation takes the general warp path (§4.2).
  _compositeIslandBuffer: (aContext, clippingRectangle, appliedShadow) ->
    buffer = @_refreshIslandBuffer()
    return if !buffer?
    # The shadow pass must composite a BLACK SILHOUETTE of the content — the same thing the
    # recursive shadow paint produces widget-by-widget (every appearance swaps its fill to
    # Color.BLACK). Compositing the buffer's own colours at shadow alpha would cast a faint
    # COPY instead, which over a light background LIGHTENS where a shadow must darken (the
    # tilted-window faint-shadow bug).
    buffer = @_shadowSilhouetteOfIslandBuffer buffer if appliedShadow?
    if @transformSpec.rotationDegrees % 360 == 0
      @_compositeScaleOnly aContext, clippingRectangle, appliedShadow, buffer
    else
      @_compositeTransformed aContext, clippingRectangle, appliedShadow, buffer

  # The buffer's alpha channel with every visible pixel black ("source-in" fill), so
  # per-pixel coverage — AA fringes, semi-transparent content — carries into the shadow
  # exactly as the recursive shadow paint would. Cached: every buffer-pixel change funnels
  # through _rasterizeIslandContent, which clears it, so it rebuilds at most once per content
  # change and never on a pure transform change. The composite's globalAlpha then applies
  # the shadow's faintness, exactly as on the normal pass.
  _shadowSilhouetteOfIslandBuffer: (buffer) ->
    if !@_islandShadowSilhouette?
      @_islandShadowSilhouette = HTMLCanvasElement.blackSilhouetteOf buffer
    @_islandShadowSilhouette

  # §4.2 scale-only fast path: a uniform scale needs no setTransform — the whole buffer
  # is drawn through the ONE slot→dst mapping under a rect clip to the damage region,
  # every mapped rect stays axis-aligned. The clip (not a src sub-rect) is what confines
  # the draw: SWCanvas samples scaled draws BILINEAR, and a per-strip src sub-rect would
  # give each damage strip its own rounded mapping — a half-texel phase shift per strip —
  # and starve edge taps (outside the sub-rect samples transparent), so an incremental
  # composite would visibly diverge from a full one at every strip seam. One continuous
  # mapping + clip makes strips byte-identical to the full composite BY CONSTRUCTION
  # (the rotation path's proven shape; SWCanvas' rect clip clamps the iterated pixels,
  # so this costs the same inner-loop work as the old sub-rect spelling).
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

    cpr = ceilPixelRatio
    aContext.save()
    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha
    # INTEGER-scale zooms stay NEAREST-NEIGHBOR by explicit opt-out (owner D2a,
    # scale-smoothing arc): an integer axis-aligned upscale is pure pixel
    # duplication — crisp and information-preserving — and both backends honor
    # the standard flag, so native and SWCanvas agree at every scale: integer
    # crisp, non-integer smooth. Restored by the restore() below. (Rotated
    # composites — 90°-multiples included — keep the smoothing sampler: the
    # spec matrix carries ~1e-16 trig residues at quadrant angles, and NN's
    # floor through a residue-skewed inverse picks wrong texels; the bilinear
    # zero-fraction path absorbs residues instead. See docs/BACKLOG.md.)
    aContext.imageSmoothingEnabled = false if s == Math.round s
    # Round the four clip EDGES and derive extents from them (dr-dl, db-dt), NOT
    # round(width) independently: if one cycle splits this island's damage into adjacent
    # strips, strip A's right edge round(boundary*cpr) equals strip B's left edge —
    # gapless partition by construction. The clip is in the INCOMING coordinate space
    # (identity on the normal pass, the shadow-offset translate on the shadow pass),
    # exactly like the rotation path's damage clip.
    dl = Math.round visibleDst.left() * cpr
    dt = Math.round visibleDst.top() * cpr
    dr = Math.round visibleDst.right() * cpr
    db = Math.round visibleDst.bottom() * cpr
    aContext.clipToRectangle dl, dt, dr - dl, db - dt
    aContext.drawImage buffer, 0, 0, buffer.width, buffer.height,
      dstLeft * cpr, dstTop * cpr, (dstRight - dstLeft) * cpr, (dstBot - dstTop) * cpr
    aContext.restore()

  # §4.2 general warp path (Phase 2 — rotation, and rotation+scale): render-straight-then-warp,
  # composing onto the incoming CTM (transform, not setTransform) so the shadow pass' offset
  # translate warps correctly for free. A REAL path clip to (damage ∩ screen footprint) is
  # MANDATORY — a transformed drawImage can't express the damage-rect clip via src/dst rects, and
  # a spill would paint over un-repainted front content (z-order corruption). Full mechanism,
  # nearest-neighbour sampling, and the whole-buffer-warp v1 trade-off:
  # docs/architecture/transforms.md §8, §9.
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
  # the island's TWO FACES for clipping/bounds (plan §4.11); mechanism: docs/architecture/transforms.md §4.
  # fullClippedBounds / SLOWfullClippedBounds are inherited from ClippingAtRectangularBoundsMixin and
  # delegate to clippedThroughBounds / SLOWclippedThroughBounds, so overriding those two (+ clipThrough)
  # is sufficient. SLOW-oracle twins are overridden IN LOCKSTEP (doubleCheckCachedMethodsResults gate).
  # ---------------------------------------------------------------------------

  # screen footprint of the slot box under the current spec (padded integer AABB).
  _screenFootprintForDamage: ->
    @transformSpec.mapRect @bounds, @bounds

  # Phase 4B (§6): the SCREEN position of the rotation anchor. The anchor is a FIXED POINT of the
  # island's OWN transform (matrixForSlot maps A→A), so it is constant as the island spins — a stable
  # pivot for the rotate handle. localPointToScreen applies any ANCESTOR islands' transforms (none for
  # a top-level island ⇒ the anchor returns unchanged); it deliberately does NOT re-apply my own.
  screenAnchor: ->
    @localPointToScreen @transformSpec._anchorFor(@bounds)

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

# TransformSpec — the canonical (scalar) description of a widget's affine transform.
#
# Part of the affine-transforms feature (see docs/plans/affine-transforms-plan.md). A
# TransformSpec belongs to a TransformFrameWdgt ("island") and describes a
# SIMILITUDE: uniform scale + rotation about an anchor point, applied when the
# island composites its buffered content onto the screen.
#
# DESIGN (plan §1.2 D3, §4.1, §4.3):
#  - The SCALARS are canonical and exact: rotationDegrees, scale, anchor,
#    claimsSpace. The 3x2 matrix is DERIVED on demand and NEVER stored as truth
#    (extracting angle/scale back out of a matrix is what forced Lively's
#    epsilon-hacks — we never do it). Because the matrix is cheap (~10 flops) and
#    derived, there is no cached-matrix / rebuildDerivedValue bookkeeping to get
#    wrong for deepCopy (plan §4.10): only the scalars serialize.
#  - Determinism: for a non-zero angle the matrix trig MUST come from the shared
#    deterministic (fdlibm) port `DetTrig` (plan §0-R 0b) — the SAME sin/cos the
#    build installs over Math.* before SWCanvas renders — or rotated references
#    would differ across JS engines (verified byte-identical cross-engine in Phase
#    0a). Rotation is LIVE (Phase 2); the rotation==0 fast path still returns
#    cos=1/sin=0 directly with no trig call, so a pure scale or identity spec has no
#    trig dependency.
#
# Canvas-2D matrix convention (a,b,c,d,e,f): x' = a·x + c·y + e ; y' = b·x + d·y + f.

class TransformSpec

  @augmentWith DeepCopierMixin

  # ---- canonical scalars (the ONLY serialized state) ----
  rotationDegrees: 0        # float, canonical (Phase 2: live)
  scale: 1                  # float > 0
  anchor: nil               # nil => centre of the slot box; else a Point in slot-box coords
  # layout coupling (plan §4.9): 'footprint' (THE DEFAULT — owner decision D1, 2026-07-17,
  # docs/archive/claimsspace-footprint-default-and-scroll-reachability-plan.md) / 'slot' (paint-only) /
  # 'sweep'. Defaults serve the DOCUMENT author: a rotated image in a document must not overlap
  # the text below it; expert authors who need paint-only rotation ('slot') or a spin-stable
  # reserve ('sweep') set the mode themselves. ('slot' was the default through Phase 3 — the
  # "paint-only Lively firewall" — inverted into an opt-in by D1.) All three modes live since
  # Phase 3 (see _claimedBoxFor below + TransformFrameWdgt.setClaimsSpace).
  claimsSpace: "footprint"

  constructor: (@rotationDegrees = 0, @scale = 1, @anchor = nil, @claimsSpace = "footprint") ->
    # Phase 2: rotation is live — for a non-zero angle the matrix trig comes from the shared
    # deterministic DetTrig port (see _cosSin), so rotated composites are cross-engine identical.
    if @scale <= 0
      @scale = 1

  # exact identity test on the CANONICAL scalars (plan §4.3) — this is why scalars,
  # not the matrix, are the source of truth: `== 0` / `== 1` are exact here.
  isIdentity: ->
    (@rotationDegrees % 360 == 0) and (@scale == 1)

  # The canonical scalars (scale / rotationDegrees / claimsSpace) are mutated DIRECTLY by
  # TransformFrameWdgt's guarded _set*NoSettle cores (a thin setter here would collide, by name,
  # with the widget's self-settling public wrappers and false-trip the layering gate). The anchor
  # is mutated directly too, by its owning island's lifecycle seams only (the Bug-D pin/un-pin in
  # TrackingTransformFrameWdgt._reLayoutChildren, the Bug-F move-level anchor-rides, the Bug-G
  # pick-up normalization) — no setter exists by design.

  # ---- layout coupling (plan §4.9) — the extent this island CLAIMS from its parent's ----
  #      layout, and where the slot box sits inside that claimed box.
  #
  # The claimed BOX in the slot box's own coordinate frame (before layout moves it):
  #  'slot'      → the slot box itself (paint-only; parent reserves nothing extra).
  #  'footprint' → the corner-mapped integer AABB of the transformed slot box (§4.3) — changes
  #                with angle/scale, so the parent reflows on a transform change.
  #  'sweep'     → the anchor-aware circumscribed square (§4.3) — depends on scale/extent/anchor
  #                but NOT on angle, so a spinning figure reflows once then stays put.
  _claimedBoxFor: (slotBounds) ->
    switch @claimsSpace
      when "footprint" then @mapRect slotBounds, slotBounds
      when "sweep"     then @_sweepSquareFor slotBounds
      else slotBounds

  # the claimed EXTENT (Point) the parent layout reserves.
  claimedExtentFor: (slotBounds) ->
    @_claimedBoxFor(slotBounds).extent()

  # offset from the claimed box's top-left to the slot box's top-left. Translation-invariant
  # (depends only on slot EXTENT + θ + s + anchor — the similitude AABB moves with the slot box),
  # so there is NO position→extent feedback. When layout places the claimed box at P, the slot box
  # commits to P + slotOffset (plan §4.9: claimed box = extent AND offset).
  slotOffsetWithinClaim: (slotBounds) ->
    slotBounds.topLeft().subtract @_claimedBoxFor(slotBounds).topLeft()

  # D2 scroll reachability (docs/archive/claimsspace-footprint-default-and-scroll-reachability-plan.md):
  # the box a scroll frame must make reachable = claimed box ∪ the ink's integer hull, in the
  # slot box's own (parent-plane) coordinates. LAYOUT and REACHABILITY answer different
  # questions ('slot' claims nothing from siblings yet its rotated ink must still be
  # scrollable-to), so this deliberately does NOT reuse _claimedBoxFor alone. The ink term is
  # the UNPADDED exact mapped AABB floor/ceil'd — NOT mapRect's damage-padded twin: exact
  # corners lie within the sweep circle, so their hull nests inside the sweep square at EVERY
  # angle (spin-stable extent, sweep's whole promise), while the damage pad would poke 1px past
  # it at corner-aligned angles. Reachability tracks GEOMETRIC ink (CSS scrollable overflow
  # draws the same line); the <1px AA bleed stays a damage-path concern. BOTH terms are
  # load-bearing: under 'slot' the claim (= slot box) never contains the rotated ink (the
  # reported basement defect), and ink alone would drop the claim ('slot' still occupies its
  # slot; 'sweep' reserves its square — at 90° a mapped AABB contains neither). For
  # 'footprint' the claim ⊇ ink hull, so the union degenerates to the claim.
  scrollOverflowBoxFor: (slotBounds) ->
    ink = @mapRectExact slotBounds, slotBounds
    inkHull = new Rectangle (Math.floor ink.left()), (Math.floor ink.top()), (Math.ceil ink.right()), (Math.ceil ink.bottom())
    @_claimedBoxFor(slotBounds).merge inkHull

  # circumscribed square for 'sweep' (§4.3): radius r = max over slot-box corners of the SCALED
  # distance to the anchor; the integer AABB of the circle of radius r centred on the anchor.
  # Rotation-invariant by construction (a rotation about the anchor preserves each corner's
  # distance to it). Math.sqrt is IEEE-correctly-rounded ⇒ cross-engine deterministic (unlike trig).
  _sweepSquareFor: (slotBounds) ->
    A = @_anchorFor slotBounds
    r = 0
    for x in [slotBounds.left(), slotBounds.right()]
      for y in [slotBounds.top(), slotBounds.bottom()]
        d = Math.sqrt((x - A.x) * (x - A.x) + (y - A.y) * (y - A.y)) * @scale
        r = d if d > r
    new Rectangle (Math.floor(A.x - r)), (Math.floor(A.y - r)), (Math.ceil(A.x + r)), (Math.ceil(A.y + r))

  # cos/sin of the rotation. The rotation==0 fast path returns exact [1,0] with no trig
  # call (so identity / pure-scale specs have no trig dependency); a non-zero angle goes
  # through the deterministic DetTrig port (cross-engine-identical — the live Phase-2 path).
  _cosSin: ->
    deg = @rotationDegrees
    return [1, 0] if deg % 360 == 0
    theta = deg * Math.PI / 180   # Math.PI is IEEE-exact across engines
    [DetTrig.cos(theta), DetTrig.sin(theta)]

  _anchorFor: (slotBounds) ->
    return slotBounds.center() if !@anchor?
    # anchor is stored in slot-box coordinates: it is an absolute point in the
    # island's plane (the slot box IS the plane at identity), so use it directly.
    @anchor

  # §7.5 Bug G backing math: the translation that re-expresses a PINNED-anchor similitude as its
  # rendering-identical NIL-anchor (slot-centre) form — t = (I − sR)(A − centre), the Bug-D
  # compensation algebra inverted. A plane-local vector (anchor and slot both live in the island's
  # own plane, hence no `screen` in the name). Caller contract (TransformFrameWdgt.
  # _normalizePinnedAnchorNoSettle): read t while the anchor is still PINNED, then nil the anchor,
  # THEN translate — the ordering lives at the caller, this method only computes.
  _nilAnchorEquivalentTranslation: (slotBounds) ->
    [c, s] = @_cosSin()
    sc = @scale
    A = @anchor
    ctr = slotBounds.center()
    ex = A.x - ctr.x
    ey = A.y - ctr.y
    new Point (ex - sc * (c * ex - s * ey)), (ey - sc * (s * ex + c * ey))

  # The forward matrix that maps slot-box (virtual) coordinates to the island's
  # PARENT plane (plan §4.3):  p' = A + s·Rot(θ)·(p − A).
  # Returns {a,b,c,d,e,f}. Works in whatever units slotBounds/anchor are in
  # (the island composites in device pixels; damage/hit map in logical pixels —
  # both feed a slot box + anchor in matching units).
  matrixForSlot: (slotBounds) ->
    [c, s] = @_cosSin()
    sc = @scale
    a = sc * c
    b = sc * s
    cc = -sc * s
    d = sc * c
    A = @_anchorFor slotBounds
    e = A.x - sc * (c * A.x - s * A.y)
    f = A.y - sc * (s * A.x + c * A.y)
    { a: a, b: b, c: cc, d: d, e: e, f: f }

  # inverse of matrixForSlot (§4.3: p = A + (1/s)·Rot(−θ)·(p'−A)) — maps a
  # screen/parent-plane point back into the slot (virtual) plane, for hit-testing
  # (§4.6). cos(−θ)=cos θ, sin(−θ)=−sin θ.
  inverseMatrixForSlot: (slotBounds) ->
    [c, s] = @_cosSin()
    inv = 1 / @scale
    A = @_anchorFor slotBounds
    a = inv * c
    cc = inv * s
    b = -inv * s
    d = inv * c
    e = A.x - inv * (c * A.x + s * A.y)
    f = A.y - inv * (-s * A.x + c * A.y)
    { a: a, b: b, c: cc, d: d, e: e, f: f }

  _applyMatrixToPoint: (m, p) ->
    new Point m.a * p.x + m.c * p.y + m.e, m.b * p.x + m.d * p.y + m.f

  inverseMapPoint: (p, slotBounds) ->
    @_applyMatrixToPoint @inverseMatrixForSlot(slotBounds), p

  # Forward point map (the exact inverse of inverseMapPoint): a slot/virtual-plane point up
  # to the island's PARENT plane. First caller: Widget::localPointToScreen, which a macro uses
  # to click an island-inner widget at the on-screen pixel its virtual point maps to.
  mapPoint: (p, slotBounds) ->
    @_applyMatrixToPoint @matrixForSlot(slotBounds), p

  # (There is deliberately NO inverseMapRect / inverseMapVector / compose: all three were PROVEN
  # unneeded during 4D — point-map both endpoints and subtract for deltas; match one point for
  # placement. Do not add them without a real consumer — geometry-api plan §1.3 deferred list.)

  # Map a Rectangle through `m` and return the integer, axis-aligned AABB of the
  # 4 transformed corners: floor the mins, ceil the maxes, then pad by 1px (AA
  # coverage bleeds < 1px past the geometric edge). Safe to feed into the existing
  # broken-rect machinery unchanged (plan §4.3). For a pure uniform scale (Phase 1)
  # the pre-image stays axis-aligned so this is exact-ish; padding is conservative.
  _mapRectWithMatrix: (m, r) ->
    xs = [r.left(), r.right(), r.left(),  r.right()]
    ys = [r.top(),  r.top(),   r.bottom(), r.bottom()]
    minX = Infinity ; minY = Infinity ; maxX = -Infinity ; maxY = -Infinity
    for i in [0...4]
      px = m.a * xs[i] + m.c * ys[i] + m.e
      py = m.b * xs[i] + m.d * ys[i] + m.f
      minX = px if px < minX
      maxX = px if px > maxX
      minY = py if py < minY
      maxY = py if py > maxY
    new Rectangle (Math.floor(minX) - 1), (Math.floor(minY) - 1), (Math.ceil(maxX) + 1), (Math.ceil(maxY) + 1)

  mapRect: (r, slotBounds) ->
    @_mapRectWithMatrix @matrixForSlot(slotBounds), r

  # The EXACT, unpadded twin of _mapRectWithMatrix: the raw float min/max of the 4
  # transformed corners with NO floor/ceil and NO +1px pad. This is the SCREEN-family
  # backing store (docs/archive/affine-geometry-api-plan.md §3.1) — a screen-plane AABB is an
  # exact, possibly-FRACTIONAL query result; it must NEVER be fed to layout / moveTo
  # (which are integer, own-plane). Kept as a PARALLEL method rather than a shared
  # helper so mapRect's proven damage path (whose padding correctness is load-bearing,
  # plan §4.5) stays byte-untouched. First caller: Widget::screenBounds.
  _mapRectExactWithMatrix: (m, r) ->
    xs = [r.left(), r.right(), r.left(),  r.right()]
    ys = [r.top(),  r.top(),   r.bottom(), r.bottom()]
    minX = Infinity ; minY = Infinity ; maxX = -Infinity ; maxY = -Infinity
    for i in [0...4]
      px = m.a * xs[i] + m.c * ys[i] + m.e
      py = m.b * xs[i] + m.d * ys[i] + m.f
      minX = px if px < minX
      maxX = px if px > maxX
      minY = py if py < minY
      maxY = py if py > maxY
    new Rectangle minX, minY, maxX, maxY

  mapRectExact: (r, slotBounds) ->
    @_mapRectExactWithMatrix @matrixForSlot(slotBounds), r

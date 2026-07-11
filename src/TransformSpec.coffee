# TransformSpec — the canonical (scalar) description of a widget's affine transform.
#
# Part of the affine-transforms feature (see docs/affine-transforms-plan.md). A
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
  # layout coupling (plan §4.9). Only 'slot' (paint-only) is wired through Phase 2;
  # 'footprint' / 'sweep' land in Phase 3.
  claimsSpace: "slot"

  constructor: (@rotationDegrees = 0, @scale = 1, @anchor = nil, @claimsSpace = "slot") ->
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
  # setter lands in Phase 4 with its first caller.

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

  # cos/sin of the rotation. Rotation==0 fast path (Phase 1: always) returns exact
  # [1,0] with no trig call; the deterministic branch is ready for Phase 2.
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

  # (inverseMapRect lands with its first caller in Phase 2/4.)

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
  # backing store (docs/affine-geometry-api-plan.md §3.1) — a screen-plane AABB is an
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

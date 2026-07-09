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

  # ---- setters (scale + rotation mutable through Phase 2; anchor setter lands in
  #      Phase 4 — re-introduced with its first caller). ----
  setScale: (s) ->
    @scale = s if s > 0
    @

  # Phase 2: rotation is live. Any angle is valid; a non-zero angle makes the matrix
  # depend on DetTrig (see _cosSin). First caller: TransformFrameWdgt::setRotation.
  setRotationDegrees: (deg) ->
    @rotationDegrees = deg
    @

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

# CornerInternalLayoutSpec

# The per-child spec for a corner/edge-internal attachment: a child placed by base
# Widget._reLayout's corner pass against its parent's CURRENT frame (resize/move/rotate
# handles, the pencil triangle badges, the modified-text triangle, the desktop furniture —
# bin opener / clock). Carries WHICH of the five anchors the child takes plus the anchor's
# geometry parameters.
#
# Sizing is OPTIONAL. A spec that declares a size has the corner pass size the child square,
# to  round( min(parentW, parentH) * proportionOfParent + fixedSize )
# — PROPORTIONAL (handle badges scaling with the parent: proportion > 0, fixedSize 0) or
# FIXED (the resize/move handles: proportion 0, fixedSize = handleSize). A spec that
# declares NO size (both terms zero) never sizes its carrier: the anchor formulas place the
# child by its OWN per-axis extent (the furniture knobs — the carrier's extent is its own
# business, and need not be square).
# `inset` backs the anchor off the parent's edge (a handle respecting its target's padding —
# HandleWdgt re-derives it in _reactToBeingAdded once the real target is known).
#
# `inset` is constructed at runtime, never as a class-level default: a class-level
# `new Point` here would need a boot-order edge the dependency scanner cannot promise
# (docs/architecture/immutable-value-classes.md §3) — the constructor guarantees it, so the
# corner pass needs no nil-inset backfill.
class CornerInternalLayoutSpec extends LayoutSpec

  # 'topLeft' | 'topRight' | 'bottomRight' | 'rightMiddle' | 'bottomMiddle'
  anchor: nil

  proportionOfParent: 0
  fixedSize: 0
  inset: nil

  constructor: (@anchor, @proportionOfParent = 0, @fixedSize = 0, inset = nil) ->
    super()
    @inset = inset ? new Point 0, 0

  # Capability query (duck-typed at the call sites): am I a corner/edge-internal attachment?
  isCornerInternal: ->
    true

# EdgeDockLayoutSpec

# The sixth member of the per-child LayoutSpec family: the spec a DOCKED frame carries — the
# host's statement that this child lives against one of its four edges, as a band spanning that
# edge (program ruling C12). Docking is a PLACEMENT, not a kind of widget: the very same frame
# that sits in a slot floats on the desktop the moment it is dragged out, because leaving the
# slot is exactly dropping this spec.
#
# `side` is which edge I take — 'top' | 'left' | 'right' | 'bottom', at most one docked frame per
# edge. What the band grants my PAYLOAD across the edge (the band adds its own chrome on top of it,
# so the payload gets the extent it asked for) is `thicknessGrantedTo`: the payload's own
# `dockThickness` when it declares one (a toolbar's, derived from the theme's grid dials and asked
# at every measure, so nothing about it is recorded), else `thickness`, the payload's cross extent
# as it arrived. Either way it is a PURE number the host's chrome measures read (never a laid-out
# extent), which is why the arrival extent is recorded here rather than measured off the band each
# pass.
# `engaged` is the HOST's mode switch: a host showing its content in view mode disengages every
# dock, which takes the band's layout contribution to zero — visibility then FOLLOWS the spec,
# never the other way round (visibility is never a layout input).
#
# I OWN my carrier's placement (the family default): the host places the band, so a docked frame
# is not free-floating, and everything that turns on that predicate follows for free — no close
# piece and no resize handle (ruling C6: a host that owns placement owns membership, and you
# leave by dragging out), and a bar laid out for the band's shape (ruling C13).
#
# I name no host type. Any container whose arrange drives its slots can hold docked frames; today
# FrameWdgt is the one that does.
class EdgeDockLayoutSpec extends LayoutSpec

  # 'top' | 'left' | 'right' | 'bottom'
  side: undefined

  # the payload's cross extent as it arrived (width for left/right, height for top/bottom), which
  # the band grants a payload that declares no dockThickness of its own; undefined for one that does
  thickness: undefined

  # the host's mode switch: a disengaged dock takes no layout space
  engaged: true

  constructor: (@side, @thickness) ->
    super()

  # What the band grants `payload` ACROSS the edge: the thickness it declares for itself, asked
  # now, or else the cross extent recorded when it arrived.
  thicknessGrantedTo: (payload) ->
    payload?.dockThickness?() ? @thickness

  # Capability query (duck-typed at the call sites): am I an edge dock?
  isEdgeDock: ->
    true

# LayoutSpec

# The abstract base of the per-child layout-spec family — the objects a child carries to
# describe HOW it participates in its container's layout:
#
#   DivisionStackLayoutSpec    siblings jointly DIVIDE the container's main axis
#                              (min/desired/max three-regime distribution)
#   VerticalStackLayoutSpec    an element of a content stack — cross-axis FIT
#                              (desiredWidth + grow + alignment), main axis hugs content
#   FrameContentLayoutSpec     window content (a VerticalStackLayoutSpec subclass with
#                              starting-size sentinels and the height-freedom flag)
#   CornerInternalLayoutSpec   placed against the parent's frame at one of five
#                              corner/edge anchors (handles, triangle badges)
#   StretchLayoutSpec          the child's proportional placement RECORD in a
#                              fractional-consuming holder (stretch panel / desktop) —
#                              the one FOLLOWER spec (ownsPlacement false, see below)
#
# The family contract:
# - a spec lives ON THE CHILD, never in a container-side map — the child carries its own
#   attachment contract (and the spec serializes/duplicates with it for free).
# - `Widget.layoutSpec` holds the child's ACTIVE spec; FREE-FLOATING means NO SPEC OWNS
#   the child's placement — `layoutSpec` undefined, or a follower spec whose `ownsPlacement()`
#   is false (the layouting system then leaves the widget alone between the holder's own
#   re-lays) — which is what `isFreeFloating()` asks.
# - which strategy places a child is answered by duck-typed capability queries on its spec
#   (`isDivisionElement?()`, `isCornerInternal?()`, `isStackElementActive?()`,
#   `isFrameContentActive?()`, `isStretchElement?()`, …), never by a type test.
# - LIFECYCLE is exactly TWO kinds. A spec is either a carrier-owned KNOB — an object the
#   widget owns for its whole life, holding underivable per-class/user preferences, doubling
#   as the attachment value, armed into the slot at attachment (`Widget._divisionBox`,
#   `HandleWdgt.cornerSpec`, and the content-stack spec `Widget._contentStackSpec`, whose
#   placement values are re-captured at each adoption/mount) — or a per-attachment RECORD,
#   derived at entry and discarded at detachment (`StretchLayoutSpec`). Container-side reads
#   of a child's content-stack spec go SLOT-FIRST through `Widget.contentStackSpec()` — on a
#   sugar island the spec rides only the slot (the `layoutSpec:` add-arg; the knob never
#   leaves the wrapped content).
class LayoutSpec

  # The family's AUTHORITY contract: does the arrange place the child FROM this spec, so
  # that user intent must edit the SPEC through its knobs (division boxes, alignment
  # setters — move a stack child by hand and the next arrange snaps it back)? True for
  # every placing spec. StretchLayoutSpec — FOLLOWER memory that trails the child's own
  # geometry via the record moments — answers false, which is what keeps its carrier
  # free-floating (user-movable, non-climbing) despite carrying a spec: see
  # Widget.isFreeFloating.
  ownsPlacement: ->
    true

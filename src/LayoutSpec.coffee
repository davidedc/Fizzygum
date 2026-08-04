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
#
# The family contract:
# - a spec lives ON THE CHILD, never in a container-side map — the child carries its own
#   attachment contract (and the spec serializes/duplicates with it for free).
# - `Widget.layoutSpec` holds the child's ACTIVE spec; FREE-FLOATING is the ABSENCE of a
#   spec (`layoutSpec` nil — the layouting system leaves the widget alone), which is why
#   `isFreeFloating()` is a nil check.
# - which strategy places a child is answered by duck-typed capability queries on its spec
#   (`isDivisionElement?()`, `isCornerInternal?()`, `isStackElementActive?()`,
#   `isFrameContentActive?()`, …), never by a type test.
# - LIFECYCLE is per class: a division box is a per-widget KNOB kept for the widget's whole
#   life (`Widget._divisionBox`); a content-stack spec is captured per PLACEMENT, kept
#   across detachment (`Widget._stackElementSpec`) and re-armed on content remount.
class LayoutSpec

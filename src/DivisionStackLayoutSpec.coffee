# DivisionStackLayoutSpec

# The per-child spec for a DIVISION stack element: siblings that jointly divide their
# container's main axis, each bringing a three-point constraint box (min / desired / max)
# to base Widget._reLayout's three-regime distribution (under-min shrink / desired-margin
# grow / max-margin fill).
#
# LIFECYCLE — a per-widget KNOB, not per-placement state (contrast VerticalStackLayoutSpec,
# which captures at each placement): built on demand — by a box setter
# (setMinAndMaxBoundsAndSpreadability / setMaxDim) — and kept for the widget's whole life,
# so a divider-tuned cell dragged out of its stack and dropped back in keeps its box. The
# widget retains it as @_divisionBox (Widget._ensureDivisionBox() materializes it).
#
# A widget with no private box reads through the shared @defaults() instance, so a plain
# widget costs no allocation. The defaults are the box every widget is born with: desired
# (30,30), min (30,30), max (330,330) = desired + SPREADABILITY_MEDIUM of the desired.
class DivisionStackLayoutSpec extends LayoutSpec

  minWidth: 30
  minHeight: 30
  desiredWidth: 30
  desiredHeight: 30
  maxWidth: 330
  maxHeight: 330

  # WHICH of the container's axes my row divides: 'x' = a horizontal row dividing width
  # (the cross axis stretches to the container's height), 'y' = a vertical division stack
  # dividing height (cross stretches to width). Set at attach (`divisionBox('y')`); the
  # engine reads it off the children (mixed axes under one parent: first child wins,
  # loudly — see Widget._divisionChildrenAxis).
  axis: 'x'

  # CROSS-AXIS placement of my cell: 'stretch' (the default — fill the container's whole
  # cross extent, the classic row/toolbar look) or 'start' | 'center' | 'end', where the
  # cell takes its own cross-axis DESIRED extent (recursively derived for a nested
  # container) and sits at the chosen edge/middle of the band.
  crossAlign: 'stretch'

  constructor: ->
    super()
    return nil

  # The shared read-only instance backing every widget without a private box (see the class
  # comment). Built lazily at first use rather than as a class-level instance, so boot pays
  # nothing. Readers must not write it — writers go through Widget._ensureDivisionBox(),
  # which materializes a private box.
  @defaults: ->
    @_defaults ?= new DivisionStackLayoutSpec

  # Capability query (duck-typed at the call sites): am I a division-stack attachment?
  isDivisionElement: ->
    true

  # Spreadability sugar: a preset distance between desired and max —
  # setMinAndMaxBoundsAndSpreadability computes max = desired + spreadability·desired/100.
  @SPREADABILITY_HANDLES: 1
  @SPREADABILITY_NONE: 10
  @SPREADABILITY_MEDIUM: 1000
  @SPREADABILITY_SPACERS: 100000000

# The three numbers a slider needs BESIDES its value: where its scale starts and stops, and how
# much of that scale its thumb covers. A widget a slider is BOUND to answers one of these for the
# pin the slider drives (`sliderRangeForPin`), so a bound slider can derive its thumb geometry from
# the property itself rather than from a hand-delivered tuple.
#
# ⚠ The value is deliberately NOT here. A bound slider reads it through the pin's own reader
# (PinSpec.getterName), which is the vocabulary the pin protocol already has; only the scale needed
# a home. So the reverse edge carries no payload at all — it wakes the slider, and the slider pulls
# both halves. See docs/plans/connector-ubiquity-and-reflection-plan.md §P8.
#
# IMMUTABLE (docs/architecture/immutable-value-classes.md): the fields are never written after
# construction, and a different scale means a new instance. It is a transient — derived on demand,
# never stored on a widget, so nothing serializes or duplicates it. (Hence no `equals`: the equality
# a value class usually needs is the dataflow cutoff's, and this never rides an edge as a value.)
#
# ⚠ `stop` must be strictly greater than `start`. A slider's `unitSize` divides by the range, so a
# degenerate one yields NaN thumb geometry (SliderButtonWdgt._reLayoutSelf → __commitExtent, which
# the NON_FINITE_GEOMETRY guard would then report). A widget with nothing to scroll along an axis
# answers `undefined` instead of a zero-width range.

class SliderRange

  start: undefined
  stop: undefined
  size: undefined

  constructor: (@start, @stop, @size) ->

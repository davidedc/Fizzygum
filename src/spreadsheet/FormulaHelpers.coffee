# FormulaHelpers — the optional free-function veneer over the value-class method algebra (dataflow
# spec §9.5). A formula can write `mix A1, B1` instead of `A1.mixed 0.5, B1`; the helper just
# delegates to the value class's own method, so the algebra has ONE home (the value classes) and the
# veneer is pure sugar. Stateless — exposed as class ("static") methods; nothing to instantiate or
# serialize.
#
# HOW A HELPER BECOMES AVAILABLE TO FORMULAS: FormulaCompiler.scanBoundNames iterates
# `for own name of FormulaHelpers` and binds every helper whose name appears as a bare identifier in
# the source; SheetCellRecord._resolveBoundName resolves that name to `FormulaHelpers[name]` (the
# function itself), passed as a bound parameter. So adding a static method here — and nothing else —
# makes it callable from every cell. Keep this class to helper methods ONLY (each own enumerable
# property is treated as a bindable helper name).

class FormulaHelpers

  # mix A, B[, proportion] — blend two colours (or any value class answering `mixed`). `proportion`
  # is A's weight (defaults to an even 0.5 blend); delegates to A.mixed so the actual algebra stays
  # on the value class (spec §9.5).
  @mix: (a, b, proportion = 0.5) ->
    a.mixed proportion, b

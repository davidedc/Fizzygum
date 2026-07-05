# SheetError — a failed computation IS the cell's value (spec docs/specs/dataflow-engine-spec.md
# §9.6: "errors are values"). A cell holding a SheetError is SETTLED — the dataflow drain moves
# on (it never spins on a throwing node), the grid paints the error badge, and references receive
# and PROPAGATE the error value (a formula reading an errored cell yields that same error,
# short-circuit — wired in Phase 2c).
#
# Kinds (grown across Phase 2):
#   "SYNTAX"  the source did not compile (FormulaCompiler.commit)          — 2b
#   "ERR"     the formula threw at recompute (SheetCellRecord.dataflowNoteError) — 2c
#   "LOOP"    the commit would close a reference cycle (spec §7)           — 2c
#
# A plain class (NOT extends Error — same reasoning as SerializationError: avoid a phantom boot
# dependency and keep it a trivial value). Immutable in spirit (see the purity law, spec §9.5):
# operations never mutate it; propagation passes the SAME instance along.

class SheetError

  constructor: (@kind, @message = "") ->

  # what the grid paints and what toString-based presenters show: a terse badge like "#SYNTAX".
  # The full message rides in @message (surfaced in a tooltip / the error console later).
  toString: -> "#" + @kind

# SecondsSource — a world-level dataflow TIME SOURCE (spec docs/specs/dataflow-engine-spec.md §6).
#
# NOT a Widget and NOT serialized: a plain singleton the DataflowEngine constructs LAZILY on the
# first `seconds` subscription (world.dataflow.secondsSource()) and keeps for the world's life. It
# is a PURE dataflow source — it has dataflowValue (its current pulled value) but NO
# dataflowRecompute — so the drain treats it as ALWAYS-CHANGED and simply pulls its value onto the
# cells that depend on it (DataflowEngine._processNode).
#
# ── WHY A SOURCE, NOT A "VOLATILE CELL" ──────────────────────────────────────────────────────
# There is no volatile-cell concept (NOMENCLATURE). A "ticking" cell is an ORDINARY node with an
# edge FROM this source. Formulas NEVER read the wall clock; the binding `seconds` (§9.2) is an
# edge to this source, and all time enters HERE — one mockable object — which is what keeps
# rendering a pure function of the event stream (spec §10 determinism).
#
# ── ITS PRIVATE TRANSDUCER IS THE STEPPING LOOP ──────────────────────────────────────────────
# While it has subscriber edges (a `seconds` cell) it registers in world.steppingWdgts at fps:1,
# and its step() does exactly ONE thing: markStale itself. So about once per second the drain
# re-runs every dependent cell, each PULLING the current value. NOTIFICATIONS CARRY NO VALUE. The
# engine's addEdge/removeEdgesInto keep @subscriberCount and call subscriberCountChanged as cells
# subscribe/unsubscribe, so the per-second tick EXISTS ONLY WHILE something needs it: entering the
# first `seconds` cell makes the ticker exist; deleting the last one makes it cease (spec §6).
#
# synchronisedStepping (fps:1, like AnalogClockWdgt): the stepping loop's synchronised branch fires
# on the wall-clock second boundary WITHOUT reading a per-member lastTime — which the non-
# synchronised branch leaves uninitialised (NaN → never fires) for a member added mid-run.
#
# ── PULLED SHAPE: A NUMBER (decided Phase 5) ─────────────────────────────────────────────────
# dataflowValue returns epoch seconds — Math.floor(dateOfCurrentCycleStart.getTime() / 1000) — NOT
# the raw Date, because formula arithmetic (`seconds - startSeconds`) and the engine's equal-value
# cutoff (_valuesEqual) both want a scalar: two consecutive cycles in the SAME wall second pull the
# SAME integer, so the cutoff stops propagation until the second actually ticks. The value is pulled
# from the world's ONE-timestamp-per-cycle (WorldWdgt.dateOfCurrentCycleStart, set in
# updateTimeReferences, live throughout the drain), so every cell in a batch sees the SAME instant.
class SecondsSource

  # fps:1 → the stepping loop calls step() about once per second; synchronised to the wall-clock
  # second boundary (WorldWdgt.runChildrensStepFunction), so no per-member lastTime is needed.
  fps: 1
  synchronisedStepping: true

  constructor: ->
    @subscriberCount = 0

  # The engine calls this from addEdge / removeEdgesInto as this source gains or loses subscriber
  # cells. Register in the stepping loop while depended-upon, deregister at zero — the source ticks
  # ONLY while something needs it (spec §6). Idempotent Set add/delete, so repeated same-count calls
  # are harmless.
  subscriberCountChanged: (n) ->
    @subscriberCount = n
    if n > 0 then world?.steppingWdgts.add this else world?.steppingWdgts.delete this
    return

  # The stepping loop calls this ~once/second while subscribed. Mark SELF stale so the next drain
  # re-runs the dependent cells; the value is PULLED at recompute (dataflowValue), never pushed here.
  step: ->
    world?.dataflow?.markStale this
    return

  # Pulled by the drain (this is a pure source: no dataflowRecompute, so _processNode reads this) and
  # by a `seconds` cell's SheetCellRecord._resolveBoundName. dateOfCurrentCycleStart is the one
  # timestamp per cycle (nil'd only at cycle END, so it is always set during the drain); the
  # dateOfPreviousCycleStart fallback keeps a value should this ever be pulled off-cycle — NEVER a
  # fresh `new Date`, which would break the one-instant-per-batch / determinism contract.
  dataflowValue: ->
    date = WorldWdgt.dateOfCurrentCycleStart ? WorldWdgt.dateOfPreviousCycleStart
    return 0 unless date?
    Math.floor date.getTime() / 1000

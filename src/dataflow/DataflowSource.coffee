# DataflowSource — the shared base of the world-level dataflow TIME SOURCES (spec
# docs/specs/dataflow-engine-spec.md §6): SecondsSource (per wall-clock second) and FrameSource
# (per frame). Both are plain, non-serialized singletons the DataflowEngine builds LAZILY on the
# first subscription, and both are PURE sources (they have dataflowValue, no dataflowRecompute).
# They share the subscriber-count bookkeeping and the stepping-loop registration VERBATIM — that
# common machinery lives here; each subclass carries only its own cadence (`fps` /
# `synchronisedStepping`) and its pulled value (`dataflowValue`). See each subclass's header for the
# per-source cadence and value detail.
#
# NOT a Widget and NOT serialized: nothing the engine holds is serialized (the sources are rebuilt
# lazily), so this base is a pure OO factoring with no bearing on the serialized surface.
class DataflowSource

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

  # The stepping loop calls this each tick while subscribed. Mark SELF stale so the next drain
  # re-runs the dependent cells; the value is PULLED at recompute (dataflowValue), never pushed here.
  step: ->
    world?.dataflow?.markStale this
    return

# FrameSource — a world-level dataflow TIME SOURCE (spec docs/specs/dataflow-engine-spec.md §6),
# the per-FRAME sibling of SecondsSource. Same shape (a plain, non-serialized singleton the
# DataflowEngine builds lazily on the first `frame` subscription; a PURE source — dataflowValue,
# no dataflowRecompute), differing only in cadence and pulled value.
#
# ── CADENCE: EVERY CYCLE ─────────────────────────────────────────────────────────────────────
# fps:0 means the stepping loop's "run as fast as possible" branch fires step() EVERY doOneCycle
# (WorldWdgt._runChildrensStepFunction) — no lastTime / synchronised bookkeeping is consulted for a
# non-positive fps. step() marks SELF stale, so while a `frame` cell exists the drain runs every
# frame and re-runs the frame-dependent subgraph. This is per-frame by design (spec §9.7); the
# drain's empty-pool early return is simply not taken while such a cell lives, and deleting the last
# `frame` cell drops the subscriber count to 0 → the source deregisters and the every-frame tick
# ceases to exist (spec §6).
#
# ── PERF PROVISO (spec §9.7) ─────────────────────────────────────────────────────────────────
# A per-frame cell that only changes painted text costs a `changed()` on the grid region, NEVER a
# re-layout (fixed cell geometry): SheetCellRecord._cacheValue calls sheetWidget.changed(), and a
# scalar value takes the socket-disposing text branch — no _invalidateLayout on the tick path. Cost
# is linear in the affected subgraph (the engine instruments lastDrainRecomputeCount).
#
# ── PULLED SHAPE: A NUMBER — WorldWdgt.frameCount ────────────────────────────────────────────
# frameCount is incremented at cycle END (WorldWdgt.doOneCycle, AFTER the drain and paint), so a
# `frame` formula pulled during the drain sees the count of cycles COMPLETED BEFORE this one — a
# non-negative integer that increases by exactly 1 each frame and is stable across a whole batch.
# (Both time sources bind a scalar so the equal-value cutoff and formula arithmetic behave; unlike
# `seconds`, a distinct `frame` value every cycle means no cutoff and the subgraph recomputes each
# frame — the point of a per-frame cell.)
class FrameSource extends DataflowSource

  # fps:0 → step() runs every cycle (the "as fast as possible" stepping branch); no synchronised /
  # lastTime bookkeeping applies to a non-positive fps.
  fps: 0

  # subscriberCountChanged / step / constructor are shared verbatim with SecondsSource — see the
  # DataflowSource base.

  # Pulled by the drain (pure source) and by a `frame` cell's SheetCellRecord._resolveBoundName:
  # the running frame counter (see the header for which frame a formula therefore sees).
  dataflowValue: ->
    WorldWdgt.frameCount

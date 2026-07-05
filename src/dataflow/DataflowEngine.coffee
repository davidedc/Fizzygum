# DataflowEngine — the world's ONE calculation engine (spec: docs/specs/dataflow-engine-spec.md).
#
# It is a plain delegated collaborator, NOT a Widget: the world HAS-A one, reachable as
# `world.dataflow` (the MacroToolkit / WidgetFactory pattern, per the mixin phase-out). It
# ships in every build (a product feature — no homepage exclusion), so WorldWdgt constructs
# it UNGUARDED, unlike the dev-only widgetFactory.
#
# ── CORE MODEL ──────────────────────────────────────────────────────────────────────────
# One engine serves two clients that both reduce to "nodes and edges":
#   • patch-programming circuits (widgets wired by connections), and
#   • the spreadsheet (cells wired by named references).
# An EDGE means "when this changes, that must react". NOTIFICATIONS CARRY NO VALUES — a
# source only marks a node STALE; values are PULLED from the nodes at recompute time. This
# makes pooling lossless (ten markings collapse to one; the pull reads the latest value) and
# per-cycle batching merge-free.
#
# ── NODE PROTOCOL (duck-typed; THIS HEADER IS THE CONTRACT DOC) ──────────────────────────
# A node is any object the engine holds by identity. It MAY implement:
#   • dataflowRecompute() -> newValue   a COMPUTING node's thunk (a cell's formula, a calc
#                                       patch node). Absence = a pure source or sink.
#   • dataflowValue()      -> value     the current value, PULLED by consumers and by the
#                                       equal-value cutoff for nodes that are NOT computing
#                                       nodes (Phase 6b maps a widget's to exportedValue()).
#   • dataflowApply(value)              a SINK application hook — apply a value onto a plain
#                                       property. Cells (Phase 2/3) and wire edge-records
#                                       (Phase 6) provide concrete implementations; it MUST
#                                       route via the target's `_<action>Connector` lane or a
#                                       bare mutator, never a public self-settling setter.
#   • dataflowNoteError(error) -> value optional: turn a mid-recompute throw into the node's
#                                       own error VALUE (a sheet cell -> a SheetError), so the
#                                       drain cannot spin on it (spec §5/§9.6).
# A node with neither dataflowRecompute nor dataflowValue is treated as ALWAYS-CHANGED — the
# conservative default for a source. Equality for the cutoff: `_valuesEqual` (a.equals?(b)
# when the value defines it, else identity) — so immutable value classes (Color) cut off by
# value and everything else by reference.
#
# ── THE TWO VERBS (mirrors layout's _invalidateLayout / __markForRelayout) ───────────────
#   • markStale(node, forced)   the public, policy-aware verb sources call. During a drain it
#                               DEMOTES to the bare pool atom (re-entrancy is legitimate, spec
#                               §5); the per-event `firesPerEvent` mini-pass lane lands in
#                               Phase 6b. Until then everything pools.
#   • __poolStale(node, forced) the bare atom: push into the stale pool, nothing else.
# `forced` (spec §8's bang / force-fire) propagates DESPITE the equal-value cutoff.
#
# ── THE DRAIN (recalculateDataflow — runs once per cycle in doOneCycle) ──────────────────
# Empty-pool early-return first (the dark-phase hot path). Otherwise, drain-until-quiet: each
# PASS snapshots the pool (insertion order = event order, deterministic), computes the stale
# set's downstream closure over the index, orders it (Kahn + one-lap-from-entry remainder,
# see _orderTopologically), and walks it ONCE. A node is recomputed/applied only if it is a
# seed OR a producer of it CHANGED this pass — this dynamic pruning IS the equal-value cutoff.
# `visited` covers sink application too, so a ring walks exactly one lap and stops where the
# change entered (spec §7). The engine opens ONE layout settle per pass (spec §4.2 item 5):
# every `_<action>Connector` sink JOINS it, so the pass settles once; residual dirt lands in
# the recalculateLayouts that immediately follows the drain. A generous pass-count cap turns a
# genuinely divergent side-effect loop into a loud DATAFLOW_NONCONVERGENCE rather than a
# frozen frame. Measured peaks (recorded in Phase 7): 1 pass typical, 2 for sink-onto-source.
#
# ── WHAT THE ENGINE MUST NOT DO ─────────────────────────────────────────────────────────
# Never call a public self-settling setter, never call _invalidateLayout, never fire a
# connection's settling entrypoint. Dataflow settles VALUES; layout settles GEOMETRY; the
# coupling is one-way (dataflow may dirty layout; layout must never mark dataflow stale).
#
# ── THE INDEX IS DERIVED AND DISPOSABLE ─────────────────────────────────────────────────
# Edges live LOCALLY on the widgets (a wire's @target/@action) and in formula text (a cell's
# references); the engine keeps only a derived forward+reverse adjacency index, rebuilt by the
# clients on load/copy/wire-change/formula-commit. So NONE of the engine's Maps/Sets/WeakMap
# are serialized — a duplicated or restored wired structure needs no engine fix-up; the client
# re-declares its edges. The engine is a world singleton, encoded symbolically as {"$wk":
# "dataflow"} and re-bound on restore (WellKnownObjects — both keyFor AND resolve arms). See
# docs/serialization-duplication-reference.md.
class DataflowEngine

  # world.dataflow is a per-world singleton; a duplicated structure that points at it must KEEP
  # THE REFERENCE, not clone the engine (DeepCopierMixin honours this flag, as it does for the
  # widgetFactory). The index it holds is disposable and client-rebuilt anyway.
  keptByReferenceOnDeepCopy: true

  # Serialization: encoded as {"$wk":"dataflow"} and re-bound to the destination world's engine
  # on restore. Needs BOTH the keyFor identity check AND the resolve switch arm in
  # WellKnownObjects (keyFor alone saves fine but the load then dies on the unknown key).
  wellKnownKey: "dataflow"

  # A never-fire cap: a divergent side-effect loop becomes a loud, attributed error instead of a
  # frozen frame. Generous — measured peaks are 1–2 passes (spec §5).
  dataflowPassesSanityLimit: 1000

  constructor: ->
    # forward adjacency: producer node -> Set of edge records {consumer, action, firesPerEvent, cold}
    @edgesFrom = new Map
    # reverse adjacency: consumer node -> Set of producer nodes
    @edgesTo = new Map
    # the stale pool: insertion-ordered, which IS event order — the drain's determinism leans on it
    @stalePool = new Set
    @forcedPool = new Set
    # node -> last recomputed/observed value. WEAK so a dead node's value is never pinned; the edge
    # Maps are strong, hence the explicit removeAllEdgesOf node-death API below.
    @lastValues = new WeakMap
    @_recalculatingDataflow = false
    # the node the engine is currently applying an edge INTO (6b): its own onward-fire tail re-marks it —
    # the ECHO — which markStale then drops (spec §1.13). nil outside _processNode.
    @_applyingNode = nil
    # instrumentation (spec §10 measured-convergence posture)
    @lastDrainPassCount = 0
    @maxObservedPassCount = 0
    @lastDrainRecomputeCount = 0
    # errors stashed mid-drain, reported to the console OUTSIDE the drain (layout's pattern)
    @_errorsToReport = []
    # time sources (spec §6), constructed LAZILY on first subscription (secondsSource/frameSource).
    # World-level singletons the sheet's `seconds`/`frame` edges point at; never serialized (the
    # engine itself is a $wk singleton whose own-props the serializer never walks).
    @_secondsSource = nil
    @_frameSource   = nil

  # ── EDGE INDEX (derived, disposable; clients re-declare — the engine never serializes it) ──

  # Declare "producer changing must react consumer". opts: {action, firesPerEvent, cold}. The
  # record shape carries firesPerEvent/cold/action from day one though only Phase 6 reads them.
  addEdge: (producer, consumer, opts = {}) ->
    outSet = @edgesFrom.get producer
    unless outSet?
      outSet = new Set
      @edgesFrom.set producer, outSet
    outSet.add
      consumer: consumer
      action: (opts.action ? nil)
      firesPerEvent: (opts.firesPerEvent ? false)
      cold: (opts.cold ? false)
    inSet = @edgesTo.get consumer
    unless inSet?
      inSet = new Set
      @edgesTo.set consumer, inSet
    inSet.add producer
    # a time SOURCE gaining a subscriber registers itself in the stepping loop (spec §6); a plain
    # producer (a cell) has no subscriberCountChanged, so this is a cheap no-op for it.
    @_notifySubscriberCount producer
    return

  # Remove every edge whose CONSUMER is this node (a cell re-commit drops its old references
  # before declaring new ones).
  removeEdgesInto: (consumer) ->
    producers = @edgesTo.get consumer
    return unless producers?
    producers.forEach (producer) =>
      outSet = @edgesFrom.get producer
      if outSet?
        outSet.forEach (rec) -> outSet.delete rec if rec.consumer is consumer
        @edgesFrom.delete producer if outSet.size is 0
      # a time SOURCE losing its last subscriber deregisters from the stepping loop (spec §6). Runs
      # per affected producer, after the removal, so the reported count is current. removeAllEdgesOf
      # routes a dying node's incoming edges through here too, so a deleted `seconds`/`frame` cell
      # correctly decrements its source.
      @_notifySubscriberCount producer
    @edgesTo.delete consumer
    return

  # Remove every edge whose PRODUCER is this node — the inverse of removeEdgesInto. A re-wired controller
  # (ControllerMixin.setTargetAndActionWithOnesPickedFromMenu pointing @target somewhere new) drops its single
  # old out-edge before declaring the new one, so a stale edge is never left behind as a ghost (6b).
  removeOutgoingEdgesOf: (producer) ->
    outSet = @edgesFrom.get producer
    return unless outSet?
    outSet.forEach (rec) =>
      inSet = @edgesTo.get rec.consumer
      if inSet?
        inSet.delete producer
        @edgesTo.delete rec.consumer if inSet.size is 0
    @edgesFrom.delete producer
    # producer just lost all its subscribers; a time source would deregister here (a plain controller no-ops).
    @_notifySubscriberCount producer
    return

  # The node-death entry: remove this node as BOTH producer and consumer, and forget any pooled
  # staleness / cached value for it. A dead node left in the index is a leak AND a ghost
  # recompute. Callers: cell delete/re-commit (2c), socket unmount (4), un-wiring + fullDestroy
  # (6b).
  removeAllEdgesOf: (node) ->
    outSet = @edgesFrom.get node
    if outSet?
      outSet.forEach (rec) =>
        inSet = @edgesTo.get rec.consumer
        if inSet?
          inSet.delete node
          @edgesTo.delete rec.consumer if inSet.size is 0
      @edgesFrom.delete node
    @removeEdgesInto node
    @stalePool.delete node
    @forcedPool.delete node
    @lastValues.delete node
    return

  # Would adding edge producer->consumer close a directed cycle? True iff consumer already
  # reaches producer over existing edges (or the trivial self-reference producer is consumer —
  # `A1` inside A1). Sheets call this at formula commit to reject a loop (spec §7).
  wouldCloseCycle: (producer, consumer) ->
    return true if producer is consumer
    seen = new Set
    stack = [consumer]
    while stack.length > 0
      n = stack.pop()
      continue if seen.has n
      seen.add n
      return true if n is producer
      outSet = @edgesFrom.get n
      outSet?.forEach (rec) -> stack.push rec.consumer
    false

  # ── TIME SOURCES (spec §6) — lazily-built world singletons ───────────────────────────────
  # A time source is a pure dataflow SOURCE (dataflowValue, no dataflowRecompute) that ticks itself
  # stale via the stepping loop while — and only while — a cell depends on it. Built on first
  # subscription and kept for the world's life; the sheet's `seconds`/`frame` bindings are edges
  # into these (FormulaCompiler.commit). Never serialized (this engine is a $wk singleton; its
  # own-props are never walked — see the class header).

  secondsSource: -> @_secondsSource ?= new SecondsSource

  frameSource:   -> @_frameSource   ?= new FrameSource

  # Tell a producer its current subscriber count IF it cares (a time source registers/deregisters
  # in the stepping loop on the 0↔positive crossing). Count = its out-edge records = its subscriber
  # cells (each subscribes at most once — boundNames dedup + removeEdgesInto-before-re-add on
  # recommit). A plain producer has no subscriberCountChanged, so this returns immediately for it.
  _notifySubscriberCount: (producer) ->
    return unless producer?.subscriberCountChanged?
    producer.subscriberCountChanged (@edgesFrom.get(producer)?.size ? 0)
    return

  # ── VALUE PULL + EQUALITY (spec §3) ──────────────────────────────────────────────────────

  # A node's current value: its own reader if it has one, else the last value the drain stored.
  pullValue: (node) -> node.dataflowValue?() ? @lastValues.get node

  _valuesEqual: (a, b) -> if a?.equals? then a.equals b else a is b

  # ── THE TWO MARKING VERBS (spec §3, §5) ──────────────────────────────────────────────────

  __poolStale: (node, forced = false) ->
    @stalePool.add node
    @forcedPool.add node if forced
    return

  markStale: (node, forced = false) ->
    # Dual-mode. During a drain ALL marking demotes to the bare pool atom (demote-not-throw, spec §5) —
    # EXCEPT the ECHO (spec §1.13, NOMENCLATURE "echo"): while the engine is APPLYING an edge into a node,
    # that node's own unconditional onward-fire tail (a ported controller's updateTarget) re-marks the very
    # node being applied. That is redundant — the engine already owns that node's downstream traversal — so
    # it is DROPPED, which keeps a driven circuit at ONE pass (no pooled echo to drain next pass). Any OTHER
    # mid-drain marking (a genuine sink-onto-source, a formula side effect) still pools. The suppression is
    # gated on the wires switch so the switch-OFF spreadsheet drain is byte-identical (its cells never
    # re-mark the applying node; only ported wires emit the echo).
    #   The per-event mini-pass lane (firesPerEvent=true, spec §4) is DEFERRED in 6b: the flag rides the edge
    # record (addEdge opts) but delivery POOLS for now — the two lanes are screen-indistinguishable (§4), no
    # test exercises per-event DELIVERY (6a only asserts the flag flips), and a truly synchronous scoped
    # mini-pass fights the drain's per-pass settle-open (spec §13 open: per-event downstream scoping).
    return if world.dataflowWiresEnabled and @_recalculatingDataflow and (node is @_applyingNode) and not forced
    @__poolStale node, forced
    return

  # ── THE ONCE-PER-CYCLE DRAIN (spec §4.1 / §4.2 / §5) ─────────────────────────────────────

  recalculateDataflow: ->
    return if @stalePool.size is 0    # dark-phase hot path — MUST stay first
    if @_recalculatingDataflow
      throw new Error "Fizzygum: re-entrant recalculateDataflow() — a dataflow drain was reached from within a drain. Mid-drain staleness must POOL (markStale demotes to __poolStale), never re-enter the drain."
    @_recalculatingDataflow = true
    @lastDrainRecomputeCount = 0
    passCount = 0
    try
      while @stalePool.size > 0
        passCount += 1
        if passCount > @dataflowPassesSanityLimit
          stillStale = @_describeStalePool()
          throw new Error "Fizzygum: DATAFLOW_NONCONVERGENCE — the dataflow drain did not settle after #{@dataflowPassesSanityLimit} passes (a divergent side-effect loop). Still stale: #{stillStale}"
        @_drainOnePass()
    finally
      @_recalculatingDataflow = false
      @lastDrainPassCount = passCount
      @maxObservedPassCount = Math.max @maxObservedPassCount, passCount
    @_reportStashedErrors()    # OUTSIDE the drain — building an error console may itself settle
    return

  _drainOnePass: ->
    # Snapshot the seeds (insertion order = event order) and CLEAR the pools, so any NEW
    # staleness raised during this pass accumulates for the NEXT one (drain-until-quiet).
    seeds = Array.from @stalePool
    forcedSet = new Set @forcedPool
    @stalePool.clear()
    @forcedPool.clear()
    closure = @_computeDownstreamClosure seeds
    ordered = @_orderTopologically closure, seeds
    snapshotSet = new Set seeds
    # ONE settle around the whole pass (spec §4.2 item 5 / §1.14): every _<action>Connector
    # sink application JOINS this window (world._inLayoutMutation), so the pass settles ONCE;
    # changed()-only sinks add nothing to it. Wrapping the recompute here also makes a
    # geometry-mutating recompute throw (the purity law, spec §9.5) instead of misbehaving.
    world._settleLayoutsAfter => @_walkOrderedPass ordered, snapshotSet, forcedSet
    return

  _walkOrderedPass: (ordered, snapshotSet, forcedSet) ->
    visited = new Set
    changed = new Set     # nodes whose value ACTUALLY changed this pass — drives downstream pruning
    for node in ordered
      continue if visited.has node
      continue unless snapshotSet.has(node) or @_hasChangedProducer node, changed
      visited.add node
      @_processNode node, changed, forcedSet
    return

  _hasChangedProducer: (node, changed) ->
    producers = @edgesTo.get node
    return false unless producers?
    found = false
    producers.forEach (p) -> found = true if changed.has p
    found

  # 6b — apply each incoming WIRE edge (a producer→consumer edge carrying an ACTION) whose producer CHANGED
  # this pass: push the producer's pulled value onto the consumer via the action, routed through the target's
  # _<action>Connector lane if it defines one, else the public action — the SAME routing
  # ControllerMixin._fireConnection uses, so the non-settling connector lane (§1.5/§1.14) is preserved and
  # joins the pass settle. Sheet reference edges carry no action and are skipped, so the spreadsheet client is
  # untouched. Called only while world.dataflowWiresEnabled (the only time wire edges carry an action).
  _applyIncomingWireEdges: (consumer, changed) ->
    producers = @edgesTo.get consumer
    return unless producers?
    producers.forEach (producer) =>
      return unless changed.has producer
      rec = @_wireEdgeRecord producer, consumer
      return unless rec?.action?
      @_applyWireValue consumer, rec.action, @pullValue(producer)
    return

  _wireEdgeRecord: (producer, consumer) ->
    outSet = @edgesFrom.get producer
    return nil unless outSet?
    found = nil
    outSet.forEach (rec) -> found = rec if rec.consumer is consumer
    found

  _applyWireValue: (consumer, action, value) ->
    connectorName = "_#{action}Connector"
    actionToCall = if consumer[connectorName]? then connectorName else action
    consumer[actionToCall]?.call consumer, value
    return

  _processNode: (node, changed, forcedSet) ->
    # @_applyingNode names the node the engine is applying INTO, so its own onward-fire tail (a ported
    # controller's updateTarget → markStale @) is recognised as the echo and dropped (see markStale).
    @_applyingNode = node
    try
      # 6b — CIRCUIT EDGES: before recomputing/reading this node, APPLY each incoming WIRE edge whose
      # producer changed this pass, pushing the producer's pulled value onto this node via the wire's action
      # (routed through the target's _<action>Connector lane, exactly as _fireConnection would). Sheet
      # reference edges carry no action, so they are skipped — the spreadsheet client is unaffected.
      @_applyIncomingWireEdges node, changed if world.dataflowWiresEnabled
      newVal = nil
      if node.dataflowRecompute?
        oldVal = @lastValues.get node
        try
          newVal = node.dataflowRecompute()
        catch error
          newVal = @_noteRecomputeError node, error, oldVal
        @lastValues.set node, newVal
        @lastDrainRecomputeCount += 1
        # equal-value cutoff: a recomputed value equal to the old one marks nothing downstream
        # (force-fire, spec §8, is exempt).
        if forcedSet.has(node) or not @_valuesEqual oldVal, newVal
          changed.add node
      else
        newVal = @pullValue node
        if world.dataflowWiresEnabled and @edgesTo.get(node)?.size > 0
          # 6b widget SINK (a node reached via wire edges): equal-value cutoff on the APPLIED value — read
          # its value after the incoming applies and traverse onward only if it changed (spec §8). Alongside
          # the visit-once rule this walks a driven ring exactly one lap and stops a DAG limb early.
          if forcedSet.has(node) or not @_valuesEqual (@lastValues.get node), newVal
            changed.add node
          @lastValues.set node, newVal
        else
          # pure source / seed (a time source, an untargeted seed): no incoming edge to cut off on, so
          # conservatively always-changed — the pre-6b behaviour, preserved byte-identical when the switch
          # is OFF (no widget is ever a node then, so only sources reach here).
          changed.add node
      # sink application hook — a node applying its OWN value (a cell → its socket/presenter); routes via
      # the node's _<action>Connector lane and joins the pass settle opened by _drainOnePass.
      node.dataflowApply?(newVal)
    finally
      @_applyingNode = nil
    return

  _noteRecomputeError: (node, error, oldVal) ->
    # Force-resolve so the drain cannot spin on a throwing node (spec §5/§9.6). If the node turns
    # the throw into its own error VALUE, use it; else keep the old value. Detail goes to the
    # console OUTSIDE the drain.
    @_errorsToReport.push {node: node, error: error}
    (node.dataflowNoteError?(error)) ? oldVal

  _reportStashedErrors: ->
    return if @_errorsToReport.length is 0
    stashed = @_errorsToReport
    @_errorsToReport = []
    stashed.forEach (each) ->
      console.error "DATAFLOW_ERROR: a dataflowRecompute() threw: " + (each.error?.stack ? each.error)
    return

  # ── GRAPH HELPERS ────────────────────────────────────────────────────────────────────────

  _computeDownstreamClosure: (seeds) ->
    closure = new Set
    queue = seeds.slice()
    while queue.length > 0
      n = queue.shift()
      continue if closure.has n
      closure.add n
      outSet = @edgesFrom.get n
      outSet?.forEach (rec) -> queue.push rec.consumer
    closure

  _orderTopologically: (closure, seeds) ->
    # Kahn over the closure subgraph orders every DAG-reachable node correctly — a diamond's
    # bottom recomputes ONCE, after both parents. Nodes Kahn cannot place (a strongly-connected
    # component and everything downstream of one — their in-degree never reaches 0) are appended
    # by a breadth-first walk from the seeds (event order), which walks a ring exactly one lap
    # from the entry (spec §7). Visit-once + the equal-value cutoff make the drain CONVERGE
    # regardless of order; this ordering only minimises passes. A diamond BELOW a cycle may cost
    # one extra (cutoff-terminated) pass — accepted; full Tarjan SCC condensation (spec §4.2) is
    # a future optimisation, unnecessary while the only cyclic client (patch circuits, Phase 6)
    # is small and the acyclic client (sheets) rejects cycles at commit.
    inDeg = new Map
    closure.forEach (n) -> inDeg.set n, 0
    closure.forEach (n) =>
      outSet = @edgesFrom.get n
      outSet?.forEach (rec) ->
        inDeg.set rec.consumer, inDeg.get(rec.consumer) + 1 if closure.has rec.consumer
    ordered = []
    orderedSet = new Set
    queue = []
    closure.forEach (n) -> queue.push n if inDeg.get(n) is 0
    while queue.length > 0
      n = queue.shift()
      continue if orderedSet.has n
      ordered.push n
      orderedSet.add n
      outSet = @edgesFrom.get n
      outSet?.forEach (rec) =>
        if closure.has rec.consumer
          d = inDeg.get(rec.consumer) - 1
          inDeg.set rec.consumer, d
          queue.push rec.consumer if d is 0
    if ordered.length < closure.size
      # SCC members + their downstream: append in one-lap-from-entry (BFS from seeds) order
      bfs = seeds.slice()
      seen = new Set
      while bfs.length > 0
        n = bfs.shift()
        continue if seen.has n
        seen.add n
        if closure.has(n) and not orderedSet.has(n)
          ordered.push n
          orderedSet.add n
        outSet = @edgesFrom.get n
        outSet?.forEach (rec) -> bfs.push rec.consumer
      # any closure node unreachable from the seeds (shouldn't happen — closure IS seed-downstream)
      closure.forEach (n) =>
        unless orderedSet.has n
          ordered.push n
          orderedSet.add n
    ordered

  _describeStalePool: ->
    names = []
    @stalePool.forEach (n) -> names.push (n?.address ? n?.constructor?.name ? "node")
    names.join ", "

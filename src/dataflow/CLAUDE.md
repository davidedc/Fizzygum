# CLAUDE.md — src/dataflow/

The **dataflow / calculation engine**: ONE engine serving two clients — patch-programming
circuits (widgets wired by connections) and the spreadsheet (cells wired by named
references). Normative design: **[`../../docs/specs/dataflow-engine-spec.md`](../../docs/specs/dataflow-engine-spec.md)**;
naming: **[`../../NOMENCLATURE.md`](../../NOMENCLATURE.md)** (dataflow table); cold-executable
build order: **[`../../docs/plans/dataflow-engine-implementation-plan.md`](../../docs/plans/dataflow-engine-implementation-plan.md)**.
This file is the operating summary — the `DataflowEngine.coffee` class header carries the full
node-protocol contract.

## ⛔ Packaging: this directory is CORE, deliberately — do not make it a part

It looks like an app slice (it sits next to `src/spreadsheet/`, which IS a lazy part), and it is
not one. **Owner decision, 2026-07-30**, with the enumeration behind it in
`../../docs/archive/core-app-slices-partition-plan.md` §4 Phase 3: dataflow is the **wiring
substrate**, not an app. `ControllerWdgt`'s wire verbs (`wireTo` / `trackTarget` /
`declareWireTo`) are how a controller (any `ControllerWdgt`) wires itself to any other widget — each mirroring its list into the
engine through `DataflowEngine.ensureWireEdges` — and `WorldWdgt.doOneCycle` drains it EVERY cycle.
`ControllerWdgt` alone reaches `world.dataflow` UNGUARDED at more than a dozen sites; the
few optional-chained reaches are the spreadsheet's, the teardown's and some chrome's. Its absence would therefore be a boot-time throw
or a dead wire, never a reduction: wires would never fire, sliders would stop driving their targets,
patch nodes would go dead. That is broken rather than reduced, which fails the rule that a part's
absence must be a NO-OP at every call site
(`../../docs/architecture/build-and-packaging.md` §2) — the test for whether something can be a
part at all. The same judgment keeps `src/meta` out.

⇒ Each of the spreadsheet's two lazy-part doors (`SpreadsheetApp`, `SampleSheetApp`) names ONE
part in its `requiredParts`, awaited inside `launch`. The parts' `requires` lists are the opposite
case — what a part is MADE OF, ingested before its classes exist — and none reaches dataflow, which
is core.

## What's here

- `DataflowEngine.coffee` — the engine. A plain delegated collaborator (NOT a Widget), reached
  as `world.dataflow` (the MacroToolkit / WidgetFactory pattern). Ships in every build (a
  product feature, and core in every profile — see the packaging note above), so WorldWdgt
  constructs it UNGUARDED.
- `DataflowSource.coffee` — the shared base of the time sources: the subscriber-count field, the
  `subscriberCountChanged` stepping-loop registration (add while depended-upon, delete at zero)
  and the `step -> markStale this` tick. Each subclass carries only its cadence and its pulled
  value.
- `SecondsSource.coffee` / `FrameSource.coffee` — the two **time sources** (spec §6). Plain
  non-serialized singletons the engine builds LAZILY (`world.dataflow.secondsSource()` /
  `.frameSource()`) on the first `seconds` / `frame` subscription, each a **pure dataflow source**
  (has `dataflowValue`, no `dataflowRecompute`) — so they tick **only while a cell depends on
  them** (see below). Cadence: `fps:1` synchronised / `fps:0`. The pulled value is a NUMBER:
  `seconds` = epoch seconds from `WorldWdgt.dateOfCurrentCycleStart`; `frame` =
  `WorldWdgt.frameCount`.

(The spreadsheet client lives in `../spreadsheet/`.)

## Time sources & the subscriber count (spec §6)

A "ticking" cell is an ORDINARY node with an edge FROM a time source — there is no volatile-cell
concept (NOMENCLATURE). The engine keeps each source ticking **only while something needs it**:
`addEdge` / `removeEdgesInto` call `_notifySubscriberCount(producer)`, which — for a producer that
implements `subscriberCountChanged` (a time source does; a cell does not) — reports its current
out-edge count. The source registers in the stepping loop on the `0 → positive` crossing and
deregisters on `positive → 0`. So entering the first `seconds` cell makes the per-second ticker
exist; clearing the last one makes it cease. `removeAllEdgesOf` routes a dying node's incoming
edges through `removeEdgesInto`, so deleting a `seconds` cell decrements its source too.

## Connections client (spec §8)

The patch-programming circuits (widgets wired by a controller's wire list — `@wires`, one
`WireSpec` each, via `ControllerWdgt`) are the engine's SECOND client. A wire IS a dataflow edge,
and engine delivery is the only path:

- **Edges derive from the wire list.** `DataflowEngine.ensureWireEdges` reconciles a controller's
  whole list into `addEdge producer → wire.target wire.edgeOpts()` (re-wiring first
  `_removeOutgoingWireEdgesOf`, which spares `firesOnAnyChange` records). The wire verbs call it
  eagerly and `_fireConnection` lazily (a no-op mid-drain), so a wire declares its edge however it
  was established — the "Connect to" menu path or direct construction in code (a `ViewportWdgt`
  scrollbar's `@hBar.trackTarget @, "setScrollX"`, the prompt slider's `slider.declareWireTo @,
  "takeSliderValue"`).
- **A wire carries no value; the drain PULLS it.** `_fireConnection` is `ensureWireEdges` +
  `_ensureTrackingEdges` + `markStale @` for a wired controller, and a bare `markNonValueChange @`
  for an unwired one. `_processNode` → `_applyIncomingWireEdges` pushes each changed producer's
  value onto the consumer via the wire action, routed through the target's `_<action>Connector`
  lane, which joins the pass settle. A widget SINK then takes the equal-value cutoff on its pulled
  `dataflowValue` (`Widget.dataflowValue -> @exportedValue()`, which resolves through the widget's
  declared principal pin — the palette's reads `@choice` that way; patch nodes and the fanout
  family override outright, → `@output` / `@inputValue`); a pure source stays always-changed. Neither applies to a
  node seeded only by `markNonValueChange` into which no producer reacted this pass: sink or source, it has not
  changed, so its wires deliver nothing and the engine records no value for it (`DataflowEngine._readValueChanged`),
  until its next visit that reads its value (a fire, a delivery into it, a re-read of what it tracks), which then
  delivers it; a computing node still recomputes.
- **The echo is dropped.** A controller's `updateTarget` tail re-marking the node the engine is
  applying is dropped via `@_applyingNode`, so a driven ring is ONE pass. The engine's visit-once
  + equal-value cutoff terminate a cascade: there are no connection tokens, and no trailing token
  argument on a connection setter.
- **Calc-style patch nodes** carry `dataflowRecompute` on their shared base (`PatchNodeWdgt` — run
  the node's computation over the stored inputs → `@output`), and their `updateTarget` is
  unconditionally `markStale`.
- **An action a wire can reach must be drain-safe.** The prompt slider's action reaches `edit()`
  (public and self-settling, illegal mid-drain-flush), so it is a `public / _NoSettle / _Connector`
  trio that JOINS the drain settle (`NumberPromptWdgt.takeSliderValue`, over
  `WorldWdgt._editNoSettle` and `StringWdgt._editNoSettle`).
- **`firesPerEvent` is a per-wire delivery policy that no delivery reads yet.** Default `false` =
  **pooled** (one drain per cycle using final values); `true` = **per-event** (a synchronous
  mini-pass inside each event, spec §4), which is DEFERRED: the flag rides the edge record's opts
  and delivery always pools (screen-indistinguishable, spec §13). It lives on the wire record —
  `WireSpec.firesPerEvent`, surfaced as `edgeOpts()` and `isFiringPerEvent()` — as a PROTOTYPE
  default, so an untoggled wire carries no own property and serializes as target + action alone.
  The "Fires per event" row (ticked while the policy is on — a drawn tick, the label stays plain)
  flips it, in the menu the shared connection menu's row for EACH live wire opens
  (`ControllerWdgt._addTargetConnectionMenuEntries` → `openWireMenu` → `toggleFiresPerEventOfWire`,
  which flips the flag on the wire its row names by its (target, action) identity and announces
  the CONTROLLER with `markNonValueChange`: the rows tick by asking the controller,
  `isWireFiringPerEvent`).
- Sheet reference edges (no `action`) are skipped by wire delivery. Node death is under "Rules
  for engine code".

A controller drives as many targets as it has `WireSpec` records, and there is deliberately no
`@target`/`@action` shim to read them through. The steps that brought the circuits onto the
engine are the plan's Phase 6.

## The model in one breath

An **edge** means "when this changes, that must react". **Notifications carry no values** —
a source only marks a node **stale**; values are **pulled** from nodes at recompute time. The
engine keeps only a **derived, disposable** forward+reverse index (`@edgesFrom` / `@edgesTo`);
edges live locally on the widgets (a controller's `@wires`, one `WireSpec` each) and in formula text (a cell's
references), so a duplicated or restored wired structure needs no engine fix-up — the client
re-declares its edges. ⚠ For a copied or restored SUBTREE that happens as it joins the world:
`Widget._addNoSettle` re-declares every tracking control's reverse edges across the whole subtree,
because only the add ROOT hears `_reactToBeingAdded` (without that, a scrollbar nested in a duplicated
or loaded viewport does not follow its content until a drag fires it). Nothing the engine holds is ever serialized.

## Node protocol (duck-typed)

A node is any object held by identity. It MAY implement:

| member | role |
|---|---|
| `dataflowRecompute() -> value` | a COMPUTING node's thunk (a cell's formula, a calc patch node). Absence = a pure source/sink. |
| `dataflowValue() -> value` | current value, pulled by consumers and by the cutoff for non-computing nodes (a widget's `exportedValue()`). |
| `dataflowApply(value)` | a RESERVED sink hook — no node implements it today; wire delivery goes through the engine's own `_applyWireValue` instead. If ever implemented it must route via the target's `_<action>Connector` lane or a bare mutator, NEVER a public self-settling setter. |
| `dataflowNoteError(error) -> value` | optional: turn a mid-recompute throw into the node's own error VALUE (a cell → a `SheetError`). |

A node with neither `dataflowRecompute` nor `dataflowValue` is treated as **always-changed**
(the safe default for a source), unless it was seeded only by `markNonValueChange`. Equality for the equal-value cutoff is `_valuesEqual`
(`a.equals?(b)` when defined, else identity).

`User` (`world.users`, core) is a live non-widget node on this seam beside `DataflowSource`: it
holds no `dataflowRecompute`, only `markNonValueChange`s when `armedDrawingTool` or its edits of the paint
tools (`drawingToolOverrides`) change. Every toolbar holds one `firesOnAnyChange` edge to it and one to the world
(which announces the editor focus, its style and the mode holding it): on either announcement its cells re-derive
their looks and it re-announces itself (`ToolbarWdgt.noteToolStatesChanged`), so a toolbar mixing tool kinds keeps
every look current. A window holding a tool of its own (`FrameWdgt.armDrawingTool`) is no dataflow node: it tells
the toolbars it wears directly.

## The two verbs, and the drain

- **`markStale(node, forced)`** — the public, policy-aware verb sources call (demotes to the
  bare pool atom during a drain). It means **"my VALUE changed"**. The `firesPerEvent` per-event
  LANE is DEFERRED — delivery always POOLS regardless of the per-wire flag;
  see "Connections client" above and `docs/measurements/dataflow-measurements.md`.
- **`markNonValueChange(node)`** — its sibling: *a property that is NOT my value changed* (a
  text's font, its soft wrap, a wire's delivery policy). A node has ONE value, so saying this
  with `markStale` would re-deliver the unchanged principal value along every wire — inert for
  an ordinary value pin, a **cascading force-fire** for a `bang` pin. It wakes only the out-edges
  (of a non-computing node; a computing one still recomputes and fires if its output moved)
  declared **`firesOnAnyChange`** ("my consumer RE-READS the producer rather than receiving its
  value"), which is what a reflected menu row is, and what a scrollbar tracking its panel is; and
  it is **dark** unless such an edge exists. Spec §3a; connector plan §P3, §P8.
  ⚠ It deliberately carries **no echo rule**, unlike `markStale`. `markStale` drops a re-mark of the
  node the engine is applying into because the engine already owns that node's value-downstream
  walk; a non-value announcement wakes a DIFFERENT edge set, which the engine is NOT walking for a
  node it reached as a wire CONSUMER — so the same guard would DELETE the announcement rather than
  deduplicate it (measured: a scroll panel driven by one bar never telling its other bars).
  ⭐ **These two verbs are the engine's two PRODUCTION GRANULARITIES, and each has its own kind of
  two-way relationship** — which is why binding needed no new edge kind (connector plan §P2). At NODE
  granularity (`markStale`, a wire, the value HANDED over) a bind is simply two wires, one each way;
  at PIN granularity (`markNonValueChange`, `firesOnAnyChange`, the consumer RE-READS) it is a tracking
  wire (`trackTarget`). ⇒ Because a wire delivers the producer's PRINCIPAL value, a two-wire bind is
  necessarily **principal ⇄ principal**; binding one widget's value to some OTHER property of another
  is the second shape, not the first. A pin-aware `pullValue` sibling would be a value edge at pin
  granularity — the thing this split exists to keep apart — so it is not wanted and was not added.
- **`__poolStale(node, forced)`** — the bare atom: push into the stale pool, nothing else.
- **`recalculateDataflow()`** — the once-per-cycle drain, called from `WorldWdgt.doOneCycle` right
  after `_runChildrensStepFunction` and before `recalculateLayouts` (two more bookkeeping drains —
  the storage sorter and the fractional seeds — sit between it and the geometry settle).
  **Dataflow settles VALUES, layout settles GEOMETRY**; the coupling is one-way FOR VALUES (dataflow
  may dirty layout; layout must never `markStale`). ⚠ A layout station MAY announce a NON-value
  change — see `markNonValueChange` above; it marks no value and pulls nothing, so it cannot
  re-enter the value settle, and its only cost is cadence. Empty-pool early-return keeps it
  dark-cheap. Otherwise drain-until-quiet: each pass snapshots the pool (insertion order =
  event order), computes the downstream closure, orders it (`_orderTopologically`: Kahn +
  one-lap-from-entry remainder, a ring entered at its value-change seeds before any non-value
  announcement — on a ring the entry decides the RESULT, not just the pass count: spec §7,
  `../../../Fizzygum-tests/DETERMINISM.md` §3j; and a ring takes ONE EDIT per pass — a later edit on a ring
  that already has one waits, untouched, for the next pass of the same drain and is a barrier meanwhile
  (`_editsHeldForALaterPass`), so co-batched edits end exactly where separate cycles would; a new wire's
  on-connect offer, made inside `duringWireConnection`, is not an edit), and walks it once — a node runs only if it is a seed or a
  producer of it changed this pass (dynamic pruning = the equal-value cutoff); `visited` covers
  sink application, so a ring walks exactly one lap. The engine opens ONE layout settle per
  pass (`world._settleLayoutsAfter`); every `_<action>Connector` sink JOINS it.
  `DATAFLOW_NONCONVERGENCE` (a generous pass-count cap) turns a divergent loop into a loud
  error, not a frozen frame.

## Rules for engine code

- Never call a public self-settling setter, `_invalidateLayout`, or a connection's settling
  entrypoint. Sinks route via `_<action>Connector` / bare mutators only.
- **Node death is TWO verbs, in order** (`Widget._destroyNoSettle` calls both):
  `severWiresIntoDyingNode` first — every producer the reverse index knows un-wires the dying
  target, because a wire record left on a LIVING controller's `@wires` would be faithfully
  re-declared by the next derivation and the drain would deliver into the corpse — then
  `removeAllEdgesOf`, which drops the node from BOTH adjacency maps and the pools (a dead node
  left in the index is a leak AND a ghost recompute). The index is derived lazily, so sever alone
  is partial; `ControllerWdgt._pruneWiresOntoDestroyedTargets` (fire-time) is the same
  invariant's other chokepoint: no wire record outlives its target.
- **A producer's out-edges are not all wires.** It owns as many WIRES as it has `WireSpec` records
  (connector plan §P4) plus any number of edges from consumers that merely re-read it, so a re-wire
  clears the wires only (`_removeOutgoingWireEdgesOf`) — clearing everything would silently
  unsubscribe an open menu. `ensureWireEdges` mirrors the whole list, which is why removing a record
  and reconciling IS the un-wire: the edge stops being derivable.
- **A (producer, consumer) pair can carry SEVERAL records** — two wires onto two pins of one target,
  or a wire alongside a `firesOnAnyChange` subscription. ⚠ `@edgesTo` maps consumer → a Set of
  PRODUCERS, so it collapses the pair however many records join them: anything that must see all of
  them walks the forward set (`_edgeRecords`), never the reverse index. Reading one record per pair
  delivers one wire and silently drops the rest.
- NOMENCLATURE: no `settle` / `invalidate` / `dirty` / `coalesced` / `announce` / `volatile` in
  dataflow identifiers; "source" stays qualified ("dataflow source", "time source").

## Verifying (from the umbrella `fg`)

- Inner loop: `fg presuite`. The drain is
  dark-cheap when nothing is stale (empty-pool early return), so a cycle that touches no
  cell/wire is unaffected; measured convergence is in `docs/measurements/dataflow-measurements.md`.
- The world holds a well-known singleton (`world.dataflow`), so run the serialization legs
  (`npm run test:serialization` + `:file`) whenever the serialized surface changes.

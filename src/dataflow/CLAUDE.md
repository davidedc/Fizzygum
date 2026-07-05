# CLAUDE.md — src/dataflow/

The **dataflow / calculation engine**: ONE engine serving two clients — patch-programming
circuits (widgets wired by connections) and the spreadsheet (cells wired by named
references). Normative design: **[`../../docs/specs/dataflow-engine-spec.md`](../../docs/specs/dataflow-engine-spec.md)**;
naming: **[`../../NOMENCLATURE.md`](../../NOMENCLATURE.md)** (dataflow table); cold-executable
build order: **[`../../docs/dataflow-engine-implementation-plan.md`](../../docs/dataflow-engine-implementation-plan.md)**.
This file is the operating summary — the `DataflowEngine.coffee` class header carries the full
node-protocol contract.

## What's here

- `DataflowEngine.coffee` — the engine. A plain delegated collaborator (NOT a Widget), reached
  as `world.dataflow` (the MacroToolkit / WidgetFactory pattern). Ships in every build (a
  product feature — no homepage exclusion), so WorldWdgt constructs it UNGUARDED.
- `SecondsSource.coffee` / `FrameSource.coffee` — the two **time sources** (spec §6). Plain
  non-serialized singletons the engine builds LAZILY (`world.dataflow.secondsSource()` /
  `.frameSource()`) on the first `seconds` / `frame` subscription. Each is a **pure dataflow
  source** (has `dataflowValue`, no `dataflowRecompute`) that registers in `world.steppingWdgts`
  (`fps:1` synchronised / `fps:0`) and marks ITSELF stale each tick — **only while a cell depends
  on it** (see below). The pulled value is a NUMBER: `seconds` = epoch seconds from
  `WorldWdgt.dateOfCurrentCycleStart`; `frame` = `WorldWdgt.frameCount`.

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

## Connections client — patch-programming migration (spec §8, plan Phase 6)

The patch-programming circuits (widgets wired by `@target`/`@action` via `ControllerMixin`) are the
engine's SECOND client, ported by a strangler. Landed so far:

- **6a — `firesPerEvent` (DARK).** A per-wire delivery policy now lives on `ControllerMixin`
  (`firesPerEvent`, default `false` = **pooled**: one drain per cycle using final values; `true` =
  **per-event**: a synchronous mini-pass inside each event, spec §4). It is flipped by the shared
  "✓ fires per event" connection-menu toggle (`addFiresPerEventMenuEntry` → `toggleFiresPerEvent`,
  offered by every controller — SliderWdgt, StringWdgt, the patch nodes, … — once a target is
  wired). Declared as a PROTOTYPE default, so an untoggled wire carries no own property and
  serializes exactly as before (the `@target`/`@action` own-only-when-set idiom). 6a is DARK:
  **nothing reads the flag yet** — legacy `_fireConnection` delivery still runs, pixels unchanged.
  Phase 6b's engine delivery (behind `world.dataflowWiresEnabled`) reads it when it declares the
  edge, letting the policy ride the edge record's opts.

- **6b — engine delivery behind `world.dataflowWiresEnabled` (default OFF).** When ON, a wire IS a
  dataflow edge: `ControllerMixin.setTargetAndActionWithOnesPickedFromMenu` declares `addEdge producer →
  target {action, firesPerEvent}` (re-wiring first `removeOutgoingEdgesOf`), and `_fireConnection` becomes
  `markStale @` (a wire carries no value; the drain PULLS `dataflowValue`). **Edges are applied BY THE
  ENGINE**: `_processNode` → `_applyIncomingWireEdges` pushes each changed producer's value onto the consumer
  via the wire action, routed through the target's `_<action>Connector` lane (same routing `_fireConnection`
  used, joins the pass settle). A widget SINK then takes the equal-value cutoff on its pulled `dataflowValue`
  (`Widget.dataflowValue -> @exportedValue()`; patch nodes override → `@output`, palette → `@choice`, fanout
  → `@inputValue`); a pure source stays always-changed. The **echo** (a ported controller's `updateTarget`
  tail re-marking the node the engine is applying) is DROPPED via `@_applyingNode` — so a driven ring is ONE
  pass. The 3 calc-style patch nodes gain `dataflowRecompute` (run the formula over stored inputs → `@output`)
  and DELETE their `allConnectedInputsAreFresh` freshness gate (the §8 deadlock) on the ON path. Node death
  (`Widget._destroyNoSettle`) → `removeAllEdgesOf @`. Sheet reference edges (no `action`) are skipped, so the
  spreadsheet is untouched. Everything is switch-gated → switch-OFF is byte-identical legacy. The `firesPerEvent`
  PER-EVENT synchronous mini-pass is DEFERRED (the flag rides the edge record; delivery pools — screen-
  indistinguishable, spec §13). Acceptance: the °C↔°F ring is frame-identical ON≡OFF both directions, 1 pass,
  entry never re-applied, capstone 0 with the switch ON. NEXT (6c) flips the default and reconciles the
  connection-driving macros; 6d deletes the `connectionsCalculationToken` machinery.

## The model in one breath

An **edge** means "when this changes, that must react". **Notifications carry no values** —
a source only marks a node **stale**; values are **pulled** from nodes at recompute time. The
engine keeps only a **derived, disposable** forward+reverse index (`@edgesFrom` / `@edgesTo`);
edges live locally on the widgets (a wire's `@target`/`@action`) and in formula text (a cell's
references), so a duplicated or restored wired structure needs no engine fix-up — the client
re-declares its edges. Nothing the engine holds is ever serialized.

## Node protocol (duck-typed)

A node is any object held by identity. It MAY implement:

| member | role |
|---|---|
| `dataflowRecompute() -> value` | a COMPUTING node's thunk (a cell's formula, a calc patch node). Absence = a pure source/sink. |
| `dataflowValue() -> value` | current value, pulled by consumers and by the cutoff for non-computing nodes (Phase 6b → a widget's `exportedValue()`). |
| `dataflowApply(value)` | a SINK hook — apply a value onto a plain property, routing via the target's `_<action>Connector` lane or a bare mutator, NEVER a public self-settling setter. |
| `dataflowNoteError(error) -> value` | optional: turn a mid-recompute throw into the node's own error VALUE (a cell → a `SheetError`). |

A node with neither `dataflowRecompute` nor `dataflowValue` is treated as **always-changed**
(the safe default for a source). Equality for the equal-value cutoff is `_valuesEqual`
(`a.equals?(b)` when defined, else identity).

## The two verbs, and the drain

- **`markStale(node, forced)`** — the public, policy-aware verb sources call (demotes to the
  bare pool atom during a drain; the `firesPerEvent` per-event LANE lands in Phase 6b — the
  per-wire property itself landed in 6a, see "Connections client" above).
- **`__poolStale(node, forced)`** — the bare atom: push into the stale pool, nothing else.
- **`recalculateDataflow()`** — the once-per-cycle drain, called from `WorldWdgt.doOneCycle`
  BETWEEN `runChildrensStepFunction` and `recalculateLayouts`. **Two parallel drain stations:
  dataflow settles VALUES, layout settles GEOMETRY**; the coupling is one-way (dataflow may
  dirty layout; layout must never mark dataflow stale). Empty-pool early-return keeps it
  dark-cheap. Otherwise drain-until-quiet: each pass snapshots the pool (insertion order =
  event order), computes the downstream closure, orders it (`_orderTopologically`: Kahn +
  one-lap-from-entry remainder), and walks it once — a node runs only if it is a seed or a
  producer of it changed this pass (dynamic pruning = the equal-value cutoff); `visited` covers
  sink application, so a ring walks exactly one lap. The engine opens ONE layout settle per
  pass (`world._settleLayoutsAfter`); every `_<action>Connector` sink JOINS it.
  `DATAFLOW_NONCONVERGENCE` (a generous pass-count cap) turns a divergent loop into a loud
  error, not a frozen frame.

## Rules for engine code

- Never call a public self-settling setter, `_invalidateLayout`, or a connection's settling
  entrypoint. Sinks route via `_<action>Connector` / bare mutators only.
- Every death path (`removeAllEdgesOf`) drops the node from BOTH adjacency maps and the pools —
  a dead node left in the index is a leak AND a ghost recompute.
- NOMENCLATURE: no `settle` / `invalidate` / `dirty` / `coalesced` / `announce` / `volatile` in
  dataflow identifiers; "source" stays qualified ("dataflow source", "time source").

## Verifying (from the umbrella `fg`)

- Inner loop: `fg build` (0 violations / `done!!!`) + `fg suite` (dpr1, headless). While the
  engine is dark (Phase 1), the suite is unaffected — the drain early-returns every cycle.
- The world grew a well-known singleton, so run the serialization legs
  (`npm run test:serialization` + `:file`) whenever the serialized surface changes.

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

(Time sources `SecondsSource` / `FrameSource` arrive in Phase 5; the spreadsheet client lives
in `../spreadsheet/`.)

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
  bare pool atom during a drain; the `firesPerEvent` per-event lane lands in Phase 6b).
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

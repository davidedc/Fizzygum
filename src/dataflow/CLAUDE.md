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
substrate**, not an app. `ControllerMixin`'s wire verbs (`wireTo` / `trackTarget` /
`declareWireTo`) are how ANY widget wires itself to any other — each mirroring its list into the
engine through `DataflowEngine.ensureWireEdges` — and `WorldWdgt.doOneCycle` drains it EVERY cycle.
`ControllerMixin` alone reaches `world.dataflow` UNGUARDED at 13 sites; only the six
spreadsheet/teardown reaches are optional-chained. Its absence would therefore be a boot-time throw
or a dead wire, never a reduction: wires would never fire, sliders would stop driving their targets,
patch nodes would go dead. That is broken rather than reduced, which fails the rule that a part's
absence must be a NO-OP at every call site
(`../../docs/architecture/build-and-packaging.md` §2) — the test for whether something can be a
part at all. The same judgment keeps `src/meta` out.

⇒ The spreadsheet's lazy-part door names ONE part in its `requiredParts` (`SpreadsheetApp`),
awaited inside `launch`. Its parts.json `requires: ["app-kit"]` is the opposite case — what the
door is MADE OF, ingested before the class exists — and neither reaches dataflow, which is core.

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

## Connections client — patch-programming migration (spec §8, plan Phase 6)

The patch-programming circuits (widgets wired by a controller's wire list — `@wires`, one
`WireSpec` each, via `ControllerMixin`) are the engine's SECOND client, ported by a strangler.
Landed so far:

- **6a — `firesPerEvent` (DARK).** A per-wire delivery policy: default `false` = **pooled** (one
  drain per cycle using final values); `true` = **per-event** (a synchronous mini-pass inside each
  event, spec §4). It lives on the wire record — `WireSpec.firesPerEvent`, surfaced as `edgeOpts()`
  and `isFiringPerEvent()` — as a PROTOTYPE default, so an untoggled wire carries no own property
  and serializes as target + action alone (the own-only-when-set idiom, one level down from where
  the loose `@target`/`@action` fields used to keep it). It is flipped by the "✓ fires per event"
  row the shared connection menu grows for EACH live wire
  (`ControllerMixin._addTargetConnectionMenuEntries` → `toggleFiresPerEventOfWire`, which flips the
  flag on the WIRE and announces it with `markNonValueChange`), offered by every controller —
  SliderWdgt, StringWdgt, the patch nodes, … — once a target is wired. 6a is DARK: **nothing reads
  the flag yet** — legacy `_fireConnection` delivery still runs, pixels unchanged. Phase 6b's
  engine delivery (behind `world.dataflowWiresEnabled`) reads it when it declares the edge, letting
  the policy ride the edge record's opts.

- **6b — engine delivery behind `world.dataflowWiresEnabled` (default OFF).** When ON, a wire IS a
  dataflow edge: `ControllerMixin`'s wire verbs declare `addEdge producer → wire.target
  wire.edgeOpts()` through `ensureWireEdges`, which reconciles the whole list (re-wiring first
  `_removeOutgoingWireEdgesOf`, which spares `firesOnAnyChange` records), and `_fireConnection` becomes
  `markStale @` (a wire carries no value; the drain PULLS `dataflowValue`). **Edges are applied BY THE
  ENGINE**: `_processNode` → `_applyIncomingWireEdges` pushes each changed producer's value onto the consumer
  via the wire action, routed through the target's `_<action>Connector` lane (same routing `_fireConnection`
  used, joins the pass settle). A widget SINK then takes the equal-value cutoff on its pulled `dataflowValue`
  (`Widget.dataflowValue -> @exportedValue()`, which resolves through the widget's declared principal pin —
  the palette's reads `@choice` that way; patch nodes and the fanout family override outright, → `@output` /
  `@inputValue`); a pure source stays always-changed. The **echo** (a ported controller's `updateTarget`
  tail re-marking the node the engine is applying) is DROPPED via `@_applyingNode` — so a driven ring is ONE
  pass. The calc-style patch nodes gain `dataflowRecompute` on their shared base (`PatchNodeWdgt` — run the
  node's computation over the stored inputs → `@output`)
  and DELETE their `allConnectedInputsAreFresh` freshness gate (the §8 deadlock) on the ON path. Node death
  (`Widget._destroyNoSettle`) → `removeAllEdgesOf @`. Sheet reference edges (no `action`) are skipped, so the
  spreadsheet is untouched. Everything is switch-gated → switch-OFF is byte-identical legacy. The `firesPerEvent`
  PER-EVENT synchronous mini-pass is DEFERRED (the flag rides the edge record; delivery pools — screen-
  indistinguishable, spec §13). Acceptance: the °C↔°F ring is frame-identical ON≡OFF both directions, 1 pass,
  entry never re-applied, capstone 0 with the switch ON.

- **6c — default ON + reconciliation.** `world.dataflowWiresEnabled` now DEFAULTS ON, so the whole suite
  runs engine delivery. Flipping it exposed that 6b declared the edge ONLY in the connect-to-➜ menu path,
  so wires set up by DIRECT construction in code (a `ScrollPanelWdgt` scrollbar —
  `@hBar.trackTarget @, "setScrollX"` — and the prompt slider — `slider.declareWireTo @,
  "takeSliderValue"`) had no edge and delivered nothing. Fix: **`DataflowEngine.ensureWireEdges`** — the
  total realisation of spec §8 "edges derive from the wire list" — called eagerly by the wire verbs
  AND lazily by `_fireConnection` (no-op mid-drain), so every
  wire declares its edge however established; engine-delivered scroll is frame-identical to legacy. The
  prompt slider's action reaches `edit()` (public/self-settling, illegal mid-drain-flush), so it was made
  drain-safe with the standard `_*NoSettle` lattice: `WorldWdgt.edit`/`_editNoSettle` share a body via a
  teardown/add strategy thunk (`edit` keeps its exact self-settling behaviour), `StringWdgt._editNoSettle`,
  and `NumberPromptWdgt`'s action `takeSliderValue` (renamed off the reserved `reactTo*` notification prefix) as
  a `public / _NoSettle / _Connector` trio that JOINS the drain settle. Kept the switch as a 1-release
  kill-switch; 6d (below) deletes it + the token machinery. 11 benign inspector recaptures (`_editNoSettle`
  on the inspected `StringWdgt`).

- **6d — token retirement + switch removal (the strangler's last step).** The A/B switch
  (`world.dataflowWiresEnabled`) and the legacy `connectionsCalculationToken` cascade-termination
  machinery are DELETED — engine delivery is now the ONLY path. Gone: `Widget._acceptsConnectionToken`
  (the per-value cycle-guard), `WorldWdgt.makeNewConnectionsCalculationToken`, the `connectionsCalculationToken`
  prototype default + the per-input token fields on the patch nodes, and the trailing token args on every
  connection setter (`setValue` / `setText` / `setColor` / `setInput1..4` / `bang` / …). `_fireConnection` is
  now `ensureWireEdges` + `_ensureTrackingEdges` + `markStale @` for a wired controller, and a bare
  `markNonValueChange @` for an unwired one; the calc/diff/regex nodes' `updateTarget` is
  unconditionally `markStale` (the legacy `allConnectedInputsAreFresh` freshness gate — the spec-§8 deadlock —
  is gone, with it the per-input `updateTarget(token,…)` threading). Behaviour-invariant: with the switch
  already ON since 6c, every live token was already `undefined` (the `Widget.connectionsCalculationToken: 0`
  default made the guard always mint-and-accept, never reject), so deleting it changes no delivery frame — the
  engine's visit-once + equal-value cutoff provide cascade termination (spec §8 "tokens retire last"). The only
  screenshot movement is BENIGN inspector member-list shifts (a deleted inspected member = one fewer row, the
  6c-class recapture).

⇒ Those four steps are the strangler's LEDGER, stated in today's vocabulary: the ONE `@target` /
`@action` pair each of them actually manipulated became a LIST of `WireSpec` records at connector
§P4, so a controller now drives as many targets as it is wired to and there is deliberately no
`@target`/`@action` shim to read them through. "The model in one breath" and "Rules for engine code"
below are the as-built form.

## The model in one breath

An **edge** means "when this changes, that must react". **Notifications carry no values** —
a source only marks a node **stale**; values are **pulled** from nodes at recompute time. The
engine keeps only a **derived, disposable** forward+reverse index (`@edgesFrom` / `@edgesTo`);
edges live locally on the widgets (a controller's `@wires`, one `WireSpec` each) and in formula text (a cell's
references), so a duplicated or restored wired structure needs no engine fix-up — the client
re-declares its edges. Nothing the engine holds is ever serialized.

## Node protocol (duck-typed)

A node is any object held by identity. It MAY implement:

| member | role |
|---|---|
| `dataflowRecompute() -> value` | a COMPUTING node's thunk (a cell's formula, a calc patch node). Absence = a pure source/sink. |
| `dataflowValue() -> value` | current value, pulled by consumers and by the cutoff for non-computing nodes (Phase 6b → a widget's `exportedValue()`). |
| `dataflowApply(value)` | a RESERVED sink hook — no node implements it today; wire delivery goes through the engine's own `_applyWireValue` instead. If ever implemented it must route via the target's `_<action>Connector` lane or a bare mutator, NEVER a public self-settling setter. |
| `dataflowNoteError(error) -> value` | optional: turn a mid-recompute throw into the node's own error VALUE (a cell → a `SheetError`). |

A node with neither `dataflowRecompute` nor `dataflowValue` is treated as **always-changed**
(the safe default for a source). Equality for the equal-value cutoff is `_valuesEqual`
(`a.equals?(b)` when defined, else identity).

## The two verbs, and the drain

- **`markStale(node, forced)`** — the public, policy-aware verb sources call (demotes to the
  bare pool atom during a drain). It means **"my VALUE changed"**. The `firesPerEvent` per-event
  LANE is still DEFERRED — delivery always POOLS regardless of the per-wire flag (which landed
  dark in 6a); see "Connections client" above and `docs/measurements/dataflow-measurements.md`.
- **`markNonValueChange(node)`** — its sibling: *a property that is NOT my value changed* (a
  text's font, its soft wrap, a wire's delivery policy). A node has ONE value, so saying this
  with `markStale` would re-deliver the unchanged principal value along every wire — inert for
  an ordinary value pin, a **cascading force-fire** for a `bang` pin. It wakes only the out-edges
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

- Inner loop: `fg build` (0 violations / `done!!!`) + `fg suite` (dpr1, headless). The drain is
  dark-cheap when nothing is stale (empty-pool early return), so a cycle that touches no
  cell/wire is unaffected; measured convergence is in `docs/measurements/dataflow-measurements.md`.
- The world holds a well-known singleton (`world.dataflow`), so run the serialization legs
  (`npm run test:serialization` + `:file`) whenever the serialized surface changes.

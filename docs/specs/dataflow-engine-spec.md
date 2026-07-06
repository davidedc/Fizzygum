# Dataflow engine & spreadsheet — design spec

**Status:** **IMPLEMENTED** (Phases 0–7, 2026-07-06; + the Phase 8 view follow-on "widgetise the grid").
The design shipped; the `docs/dataflow-engine-implementation-plan.md` status ledger + its per-phase
"Landed" receipts are the build record, and `docs/dataflow-measurements.md` carries the measured
drain-convergence numbers (typical 1 pass, peak 2 for a sink-onto-source chain). Phase 8 is a
VIEW-only refactor — the engine/model/value-protocol/serialization design below is untouched by it.
**Vocabulary:** `NOMENCLATURE.md` (root) is normative for every term used here; the layout-side renames
it depended on landed in `docs/coalesced-nomenclature-rename-plan.md`.

**Deviations decided during execution** (each recorded in its phase's commit message):
- **2a** — direct-paint viewport, no `ScrollPanelWdgt` yet; fixed-size window content (elasticity 0) for a
  one-cycle settle (determinism).
- **2b** — a buffer-driven overlay editor, NO caret (deterministic Enter-commits / Escape-cancels; the
  framework provides no accept/cancel handlers, and a live caret blinks under a screenshot).
- **3** — the value-class algebra lives as METHODS on the value classes (`Color.mixed` / `lighter` /
  `darker`); `FormulaHelpers` is a thin free-function veneer.
- **4** — `CellSocketWdgt` + RETAIN-AND-REMOUNT: a widget-VALUED cell keeps its live widget across
  recompute / save / scroll, never destroy-rebuild (§13).
- **5** — `seconds` / `frame` pull a NUMBER, not a `Date`, so the equal-value cutoff is a scalar compare.
- **6a** — `firesPerEvent` landed DARK (stored + menu-toggled; nothing read it yet).
- **6b** — engine delivery behind an A/B switch (`world.dataflowWiresEnabled`, default OFF); the ECHO (a
  ported controller's onward-fire tail re-marking the node being applied) is suppressed via `@_applyingNode`
  ⇒ a driven ring is 1 pass (measured — `docs/dataflow-measurements.md`).
- **6c** — `DataflowEngine.ensureWireEdge` makes "edges derive from `@target`/`@action`" TOTAL (covers wires
  set by DIRECT assignment — scrollbars, the prompt slider — not only menu-wired ones); the prompt slider's
  `edit()` action was made drain-safe via the standard `_*NoSettle` lattice (`WorldWdgt.edit`/`_editNoSettle`;
  `PromptWdgt.reactToSliderAction`→`takeSliderValue`, off the reserved `reactTo*` prefix).
- **6d** — the connection token machinery (`_acceptsConnectionToken` / `connectionsCalculationToken` /
  `makeNewConnectionsCalculationToken`) AND the A/B switch are DELETED; engine delivery is the ONLY path. The
  visit-once + equal-value cutoff provide the cascade termination the token used to.
- **8 (view follow-on)** — "widgetise the grid" REVERSES §9.1's "no widget-per-cell": every VISIBLE cell is
  now a real `CellWdgt` (the Phase-4 `CellSocketWdgt` generalised — it also paints the scalar text the sheet
  used to). This does NOT reintroduce widget virtualisation: widget count is bounded by the VIEWPORT, not the
  sparse model (an off-screen cell is a live node with no widget). Data cells only (headers/gridlines stay
  painted chrome). Byte-identical — the whole suite + serialization legs stayed green with no reference change.
- **STILL DEFERRED** — the `firesPerEvent` PER-EVENT synchronous mini-pass (§4 / §13): the per-wire flag rides
  the edge record, but delivery POOLS regardless (the two are screen-indistinguishable; §13 open point).
  `true` is stored against the day the scoped mini-pass lands.

This spec defines ONE dataflow engine that serves two clients: the existing
**patch-programming** circuits (widgets wired by connections) and the upcoming
**spreadsheet** app (cells wired by named references). It records what was decided; §12
lists the alternatives that were considered only briefly, and §13 the points deliberately
left open.

---

## 1. Core model

**An edge means: "when this changes, that must react."** Circuits declare edges by drawing a
wire; sheets declare them by naming a cell in a formula. Same fact, two gestures — so one
engine sees only nodes and edges.

Node roles:
- **dataflow source** — anything that can change independently of formulas, and that
  *transduces its private phenomenon into staleness markings*: an input-driven widget (a
  slider transduces mouse movement), a time source (transduces the passage of time, §6), an
  edited cell (transduces keystrokes).
- **computing node** — a node with a recompute thunk: a cell with a formula, a calculating
  patch node.
- **sink** — an application of a value onto a plain widget property (`setText`, `setColor`).
  A sink can simultaneously be a source with its own outgoing edges (e.g. a slider driven by
  the batch that also drives others) — this is expected, not an anomaly (§5).

## 2. Edges live locally; the engine owns only a derived index

- A **wire** is stored on the widget that owns it (today's `@target`/`@action` from
  `ControllerMixin` — this storage survives).
- A **reference** is stored in the formula text of the cell (discovered by identifier scan,
  §9.2).
- The engine keeps a **derived, disposable index** of all edges (forward + reverse
  adjacency), rebuilt on load, on copy, on wire creation/removal, on formula commit.

**Rationale (decisive):** widget-stored references already survive both structure-copy
mechanisms for free — duplication (`DeepCopierMixin` remaps in-structure object references
and keeps external ones) and serialization (`src/serialization/` encodes in-structure
references as `{"$r": n}` and world-singleton references as well-known keys `{"$wk": …}` —
see `docs/serialization-duplication-reference.md`). A centrally-owned edge list would break
every duplication/save of a wired structure. Corollary: duplicating a circuit or a sheet
needs no engine fix-up at all; the engine re-reads and re-indexes. This mirrors the existing
house pattern of deriving load-order by scanning class sources
(`dependencies-finding.coffee`).

The engine itself is a plain delegated collaborator, `world.dataflow` (`DataflowEngine`),
`keptByReferenceOnDeepCopy: true` plus a `wellKnownKey` for the serializer — the
`MacroToolkit`/`WidgetFactory` pattern, per the mixin phase-out.

## 3. The two verbs, and what travels

Mirroring layout's `_invalidateLayout` / `__markForRelayout` split:

- **`markStale`** — the public, policy-aware verb sources call. Self-routing (dual-mode):
  during a dataflow drain it demotes to the bare atom; outside a drain it either runs a
  per-event mini-pass (if reached via a `firesPerEvent` wire, §4) or pools.
- **`__poolStale`** — the bare atom: push the node into the **stale pool**, nothing else.

**Notifications carry no values.** Values are **pulled** from the nodes at recompute time.
This is load-bearing three times over: pooling is lossless (ten markings of one source
collapse to one; the pull reads the latest value), per-cycle batching needs no merge logic,
and multi-source events need no token/freshness protocol.

## 4. Delivery: two lanes, one pass algorithm

Per-wire policy **`firesPerEvent`** (default `false`), set from the wire's menu:

- **Pooled (default):** `markStale` adds to the stale pool. Once per cycle, the drain
  station runs (§4.1). Ten drag events + a tick in one frame ⇒ one recompute batch, using
  final values.
- **Per-event (`firesPerEvent: true`):** `markStale` runs a synchronous **mini-pass**
  inside the event, scoped to that wire's downstream, applying sinks within the event's own
  in-place settle. This preserves legacy connection call-stack shape and serves genuinely
  event-hungry consumers (counters, bang-driven patches). Mixed fan-out is per-wire: one
  slider can feed a per-event counter and a pooled label, each with its own semantics.

On screen the lanes are indistinguishable (paint happens once per cycle); per-event buys
side-effects-per-event and read-your-writes within a frame, at N× the evaluation cost.

### 4.1 The drain station in `doOneCycle`

```
playQueuedEvents            ← per-event mini-passes run in here, inside their events
runChildrensStepFunction    ← stepping: time sources mark themselves stale
recalculateDataflow         ← NEW: drain the stale pool (this spec)
recalculateLayouts          ← layout's end-of-cycle flush
hand hover re-sync          ← reads SETTLED geometry (moved after the flush, 2026-07-04)
updateBroken                ← paint
```

- **After stepping**, so this frame's ticks join this frame's batch.
- **Before `recalculateLayouts`**, so sink applications feed this frame's settle and paint
  (running after layouts would reintroduce the one-cadence-lag bug class).
- Nothing else sits between the two drains: since the hover re-sync moved after the
  end-of-cycle flush (hover-resync-after-flush, 2026-07-04), it reads the settled fixed
  point that paint reads — which now automatically includes dataflow-driven geometry
  changes, with no dataflow-specific handling needed.

### 4.2 One recompute pass

1. Take the stale set; compute its downstream closure via the index.
2. Order it topologically (strongly-connected components condensed; within an SCC,
   propagate from the entry node, §7).
3. Recompute each affected node **at most once per pass**, pulling current input values.
4. **Equal-value cutoff:** a recomputed value that `equals` the old one marks nothing
   further stale. (Force-fire exempts this, §8.)
5. Apply sinks via the **connector lane** (`_<action>Connector` variants) or bare
   mutators — never the public self-settling setters. Settle mechanics (verified
   2026-07-05): a connector JOINS an enclosing settle but OPENS one when it is a
   cascade's first hop (`_settleLayoutsAfterOrJoinEnclosingPass`; check-layering's
   settle-tier whitelist) — so the engine opens ONE settle around each pass's
   interleaved recompute+apply and every connector application joins it: the same
   first-hop-owns-the-settle shape today's event cascades use, transplanted to the
   drain. Pure repaint sinks (`changed()`-only) need no settle; residual layout dirt
   still lands in the `recalculateLayouts` that follows.

## 5. Re-entrancy during the drain

New staleness *while draining* is legitimate and expected — sink-onto-source coupling,
presenter lifecycle hooks, and (uniquely here) **user formula side effects**, which create
edges the index cannot see. Policy, adapted from the layout system's discipline:

- **Demote, don't throw:** during a drain, ALL marking — including via `firesPerEvent`
  wires — degrades to `__poolStale`. One drain at a time; `recalculateDataflow` re-entered
  throws (guard flag `_recalculatingDataflow`).
- **Drain until quiet:** if the pool is non-empty after a pass, run another pass (fresh
  visit-once set). The equal-value cutoff makes convergent feedback stop naturally.
- **`DATAFLOW_NONCONVERGENCE`:** a never-fire pass-count assert (generous cap, measured
  expectations documented: 1 pass typical, 2 for sink-onto-source chains) converts a
  genuinely divergent side-effect loop into a loud, attributed error instead of a frozen
  frame loop.
- **Throwing formulas:** a formula that throws mid-pass has its cell **force-resolved to an
  error value** (§9.6) so the drain cannot spin on it; the exception detail is stashed and
  reported on the error console outside the drain (the layout catch's pattern, upgraded:
  spreadsheets can show the error as a value instead of hiding the offender).
- **One-way coupling:** dataflow may generate layout dirt; layout code must never generate
  dataflow staleness — that direction keeps a hard throw (arranges are engine-owned and
  sworn non-notifying).

Convergence is a *verified property of the constraint set* (pure recomputes §9.5,
equal-value cutoff, visit-once, per-client cycle policy) — not a structural guarantee;
hence the assert stays and pass counts are instrumented from day one.

## 6. Time sources (no "volatile" concept)

`SecondsSource` and `FrameSource` are world-level dataflow sources whose private transducer
is the stepping loop: they register in `world.steppingWdgts` (at `fps: 1` / `fps: 0`) **only
while they have subscriber edges**, and their `step()` does exactly one thing: `markStale`.
Formulas never read the wall clock; the bindings `seconds` / `frame` (§9.2) are edges to
these sources, and their values are pulled from the world's one-timestamp-per-cycle
(`WorldWdgt.dateOfCurrentCycleStart`) and `WorldWdgt.frameCount`. Consequences: every cell
in a batch sees the same instant; tests mock/scribble one object; deleting the last
`frame` formula makes the 60 Hz ticker cease to exist.

A clock *widget* in a cell is the same thing with a face: a time source that also paints.

## 7. Cycles: detect centrally, decide per client

The index knows the whole graph, so loop detection is engine machinery; the policy is the
client's:

- **Circuits:** loops allowed — the visit-once-per-pass rule walks a ring exactly one lap
  from the node where the change entered and stops where it began (the °C↔°F converter is
  the acceptance test; it must keep its current behavior).
- **Sheets:** a formula commit whose edges would close a loop is **rejected at commit**;
  the cell gets a `#LOOP` error value. (A per-sheet capped-iteration mode can be layered on
  the same SCC machinery later.)

## 8. Client: patch programming (migration)

- Edges derive from `@target`/`@action`; the connect-to-➜ menus and wire storage are
  unchanged. `firesPerEvent` is a new per-wire property with a menu toggle.
- The multi-input freshness gate (`allConnectedInputsAreFresh`) is **replaced** by
  any-input-marks-stale + pull-the-rest — this fixes the standing deadlock where a node with
  two independently-sourced inputs never fires. If a store-without-firing inlet is ever
  needed, it becomes an explicit **cold edge** attribute (updates the stored input, doesn't
  mark stale) — strictly more expressive than the gate.
- **`bang`** becomes a **force-fire** marking (stale-with-force: propagates despite the
  equal-value cutoff). `reactToTargetConnection` becomes "mark stale+forced on edge
  creation".
- **Tokens retire last.** Strangler order: (1) engine lands serving the spreadsheet;
  (2) patch programming ports as the second client (edge-deriver over `@target`/`@action`,
  sinks via the connector lane), with connection setters accepting-and-ignoring the token
  argument during transition; (3) `_acceptsConnectionToken` and the token threading are
  deleted. If (2) stalls, the honest boundary remains: two engines, connections at the
  sheet's edge. **LANDED (Phase 6, 2026-07-06):** (1) = Phase 1, (2) = Phases 6a–6c behind a
  kill-switch, (3) = Phase 6d — the two engines are now ONE; `connectionsCalculationToken` and
  `world.dataflowWiresEnabled` are gone from the tree (0 matches).
- Expected test impact: final frames identical for DAG circuits and for the ring (visit-once
  emulates token termination); intermediate frames may shift ⇒ possibly a few SystemTest
  screenshot recaptures, per the usual rules.

## 9. Client: spreadsheet

### 9.1 Shell and grid
- App shell: `IconicDesktopSystemWindowedApp` subclass + a content `*Wdgt` in a
  `WindowWdgt` (the `DegreesConverterApp` shape).
- Columns lettered, rows numbered. **Sparse model**: a dictionary keyed `"A1"`; a cell
  record holds `{source, kind-of-entry metadata}` plus derived state
  `{compiledFn, value, presenter}` (derived state is rebuildable, never serialized —
  same philosophy as the engine index).
- **Painted chrome, widgetized contents** *(as originally designed; SUPERSEDED by Phase 8 — see next
  bullet)*: the sheet widget's appearance paints gridlines, headers, and plain text/number values
  directly; a live child widget (the **socket**) exists only for cells that hold/present rich widgets
  or are currently selected/being edited. This sidesteps the framework's lack of widget virtualization
  (paint is already clipped; layout and memory stay bounded). Hosted in a `ScrollPanelWdgt`.
- **Widgetized viewport over painted chrome** *(Phase 8, the shipped form)*: the sheet paints only the
  chrome (gridlines, headers, selection); every VISIBLE cell is a real `CellWdgt` child that renders
  its own value (painted scalar text, or a hosted value-widget / presenter). Widget count is bounded by
  the VIEWPORT, not the sparse model (an off-screen cell is a live node with NO widget; scroll
  materialises/recycles the viewport's cells) — so this is NOT open-ended widget virtualization, just
  the standard bounded-viewport trick. The `CellWdgt` is the Phase-4 socket generalised to every cell.
- Layout discipline: the `StretchablePanelWdgt` pattern — immediate `_apply*` mutators
  inside `_reLayout`, bulk child moves inside `disableTrackChanges()` …
  `maybeEnableTrackChanges()` + one `fullChanged()`.
- **No structural row/column insertion/deletion in v1** (named references break under it;
  reference-rewriting is a known scope sink, deliberately deferred).

### 9.2 Formula language: everything is CoffeeScript
A cell's content IS CoffeeScript source ("Alternative B" — chosen). `42` is a number,
`"total"` a string, `A1 * 2` a formula, `new Color 255, 0, 0` a Color, `new SliderWdgt` a
widget. No marker syntax.

- **Commit** compiles once via `compileFGCode`; the compiled function is cached (recomputes
  never re-compile). A source that doesn't compile yields a syntax error value (§9.6).
- **Identifier scan** (the house regex-scan idiom) binds, as function parameters:
  cell-shaped names (`A1`, `B2` — these also become the cell's edges), known
  `FormulaHelpers` names, and the time bindings `seconds` / `frame` (edges to the time
  sources, §6). One scan discovers dependencies, helper bindings, and tick subscriptions.
- Formulas evaluate with full world access, no sandbox — consistent with the framework;
  side effects are legal and handled by §5.

### 9.3 Values, exported values, and references
- A reference yields the referenced cell's **value**.
- If that value is a **Widget**, the reference yields the widget's **exported value**
  instead: `Widget.exportedValue()` — the unified reader over today's duck-typed cluster
  (`getColor()` ?? `getValue()` ?? `@text`). A widget exporting nothing yields itself.
  The cluster is thinner than the shorthand reads (verified 2026-07-05): only
  `ColorPickerWdgt` defines `getColor`, only `StringFieldWdgt` defines `getValue`;
  `SliderWdgt` holds a bare `@value` property — such widgets gain the missing reader
  (`getValue: -> @value`) when they join the protocol (plan Phase 4), keeping
  `exportedValue` one uniform chain.
- The cell **socket** is the two-way boundary adapter: it mounts the presenter/widget, and
  it is the connection target that interactive widget-sources (slider, picker, clock) fire
  into — each firing is a `markStale` on the cell.

### 9.4 Presentation: classify → present
Fallback chain, evaluated per recompute (so a cell's type may change freely):
1. value is a Widget → **it presents itself** (mounted live in the socket);
2. value answers **`cellPresenter()`** → use the returned widget (knowledge lives on the
   value's class — live-editable via the meta system; e.g. `Color.cellPresenter` returns a
   `RectangleWdgt` with `setColor`);
3. otherwise → text presenter of `toString()`.

The presenter is **one-way glass**: downstream never sees it. Editing a cell swaps the
presenter for the source text (the patch node's formula/output split, collapsed into one
cell).

### 9.5 Operations: the algebra is the value classes' method set
- Operations on values are **methods of the value classes** (`Color.mixed` — promoted from
  its currently-unused status; `lighter`/`darker` as new Color methods) — automatically
  exposed to formulas, discoverable, and **live-extensible** (a method injected via the
  class inspector is available to the next recompute, since formulas compile from source).
- An optional **`FormulaHelpers`** veneer provides free-function style (`mix A1, B1`),
  bound by the identifier scan; helpers delegate to methods.
- An **"operate ➜" menu** on a cell enumerates the value class's methods via the meta
  system (mirror of the `colorSetters`/`numericalSetters` introspection menus) and writes
  formula text into a new cell.
- **Purity law (normative):** operations used in formulas return new values and never
  mutate the receiver. `Color` is now officially immutable-and-cached (`Color.create` LRU
  shares instances; deep copy returns the same object; serialization emits a compact record
  restored through `create`) — mutation would corrupt colors world-wide. New value classes
  joining the algebra follow the same immutable pattern (with a compact serialized form per
  `docs/serialization-duplication-reference.md`). Enforced by convention first; defensive
  `deepCopy` on handoff is the documented fallback if it ever proves fragile.

### 9.6 Errors are values
A failed computation (`#SYNTAX`, `#ERR` + message, `#LOOP`) *is* the cell's value: the cell
is settled (the drain moves on), the presenter shows the error badge, references receive
and propagate error values. Stack-trace detail goes to the error console outside the drain.

### 9.7 Ticking cells: performance provisos
Per-second cells are trivially cheap. Per-frame (`frame`) cells are supported with three
normative constraints: (1) compiled-formula caching (§9.2); (2) **ticks repaint, never
re-layout** — fixed cell geometry, `changed()` not `_invalidateLayout`; (3) cost is linear
in the affected subgraph — instrument it, and on overrun skip to the next frame (the
stepping loop's existing skip-don't-catch-up stance).

## 10. Determinism & testing

- Rendering stays a pure function of the event stream: all time enters through time
  sources (mockable, macro-scriptable); formulas cannot read wall clock; batches see one
  timestamp.
- Frame-driven cells are excluded from pixel assertions unless the macro drives synthetic
  ticks.
- Instrumentation from day one: recompute-pass counts per drain with documented expected
  peaks, in the spirit of the layout system's measured-convergence posture.

## 11. Implementation order

Detailed, cold-executable plan with phase ledger:
**`docs/dataflow-engine-implementation-plan.md`**.

1. ~~Nomenclature plan executes~~ — done (the `*DeferredSettle` rename landed).
2. Engine core + spreadsheet v1 (sparse grid, CS formulas, Color as the first non-scalar
   value, classify→present, errors-as-values) — plan Phases 1–3.
3. Interactive-widget cells + time sources — plan Phases 4–5.
4. Patch-programming port (strangler, §8), token retirement — plan Phase 6.

## 12. Alternatives considered (brief)

- **Pure push (extend the token cascade):** rejected — the all-inputs-fresh gate deadlocks
  on independently-sourced inputs, and fixing it requires per-event reachability, i.e. a
  central graph anyway; unordered firing also glitches diamonds.
- **Pure pull (demand-driven, recompute-on-display):** rejected — re-adds push at both
  boundaries (widget sources in, sink connections out), and lazy evaluation at paint time
  conflicts with the determinism contract.
- **Centrally-owned edges:** rejected — breaks deep-copy/serialization of wired structures
  (§2).
- **Formula marker (`=` prefix / structural cell kinds):** everything-is-CoffeeScript
  chosen; `=`-prefix may return later as pure *entry sugar*, and structural
  `{kind, source}` storage remains compatible with it.
- **Sheet self-stepping for "volatile" cells:** rejected in favor of time sources — the
  sheet never polls; sources always tell (§6).
- **Defer-mid-drain staleness to next frame:** rejected — paints an inconsistent world
  (one-cadence lag).
- **Per-sheet engine instances:** one world-level engine chosen (the sheet-as-dataflow-hub
  story: wires may cross the sheet boundary in both directions); per-sheet partitioning
  remains a possible internal optimization.

## 13. Open questions (decide at implementation time)

- ~~Placement of the drain relative to the hand's enter/leave re-check~~ — resolved
  upstream: the hover re-sync now runs after `recalculateLayouts` (§4.1), so the drain
  slots directly between stepping and the layout flush.
- Range syntax (`FormulaHelpers` functions vs a light preprocessor — the fizzytiles
  `LCLCodePreprocessor` is precedent) and aggregate operations.
- Per-event mini-pass downstream scoping fine print (per-wire vs per-source).
- Presenter lifecycle: reuse-and-update vs rebuild per recompute (matters for interactive
  presenters keeping state).
- Ergonomics of plain-label entry under strict CoffeeScript (quoting labels), and whether
  `=`-entry sugar ships in v1.
- Whether any patch idiom actually needs cold edges (§8) before building them.
- Read-your-writes for scripts/macros reading cells mid-cycle (settle-on-read vs accept
  cycle granularity).
- Node identity naming for copied sheets/cells in the engine index.
- Widget-valued cells across save/load: the serialized tree carries the MOUNTED widget
  (the socket's child), while recommit-on-load rebuilds cell values from source — a naive
  recompute would REPLACE the restored widget with a fresh instance, discarding its
  runtime state (a moved slider's position). Re-mount the restored widget vs
  recompute-and-replace: plan Phase 4 decides and documents.

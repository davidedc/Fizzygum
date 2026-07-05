# Dataflow engine & spreadsheet — implementation plan (cold-executable)

Implements `docs/specs/dataflow-engine-spec.md` (normative design; read it FIRST) using the
vocabulary of `NOMENCLATURE.md` (normative naming; read it SECOND). This plan assumes no
other context. Its prerequisite — the coalesced-nomenclature rename
(`docs/coalesced-nomenclature-rename-plan.md`) — is **executed**: the deferred-settle family
is now `*DeferredSettle` / `world.deferredSettlingEnabled`; the only surviving "coalesc"
strings in `src`/`buildSystem` are 4 references to the historical doc *filename*
`docs/coalescing-measurement.md` (legitimate; leave them).

**Read the status ledger below before doing anything: execute the FIRST phase whose box is
unchecked, then update the ledger in the same commit that completes the phase.**

## Status ledger

- [x] Phase 0 — pre-flight verification
- [x] Phase 1 — engine core, dark (no callers)
- [x] Phase 2a — spreadsheet shell: window, painted grid, selection
- [x] Phase 2b — cell model, literal/CoffeeScript evaluation, editing
- [x] Phase 2c — references, recompute, errors-as-values
- [x] Phase 3 — value protocol & presenters (Color first)
- [ ] Phase 4 — widget-valued cells & sockets
- [ ] Phase 5 — time sources (`seconds` / `frame`)
- [ ] Phase 6a — `firesPerEvent` wire property + menu toggle
- [ ] Phase 6b — patch-programming port behind A/B switch (default OFF)
- [ ] Phase 6c — A/B default ON, suite reconciliation
- [ ] Phase 6d — token retirement
- [ ] Phase 7 — docs closeout

Each phase = one or more commits, independently green and revertable. Do not start a phase
with the previous one unverified.

---

## §0 Environment, verification tiers, baseline

Identical to the rename plan's §0, restated: prerequisites `coffee`, `terser`, `node`,
`python3` (global). Tiers:

- **Full** (`../Fizzygum-tests` exists): verify with `./build_and_test.sh` (~1 min,
  headless, parallel). New behavior additionally needs NEW SystemTests (§4 rule 5) — authored in
  the sibling repo per `src/macros/CLAUDE.md` and `src/macros/MACRO-PATTERNS.md`.
- **Repo-only**: verify with `./build_it_please.sh --notests` (auto-creates
  `../Fizzygum-builds`; runs the syntax, layering, and dead-method gates). Phases whose
  deliverable is *behavior* (2a onward) should preferably run in the full tier; if executed
  repo-only, state in the commit message that suite + new-test authoring are pending.

**Verification cadence (full tier; referenced by every phase):**

- **Inner loop (every commit):** `./build_and_test.sh` — dpr 1, Chrome, headless parallel
  (~1 min); the build gates run inside it.
- **Phase-close battery (mandatory at the end of Phases 2c, 4, 5, 6c, 6d; recommended at
  1 and 3):** dpr 1 suite + dpr 2 (`cd ../Fizzygum-tests && node scripts/run-all-headless.js
  --dpr=2`) + WebKit cross-engine (`npm run test:webkit`) + apps smoke
  (`node scripts/smoke-apps-headless.js`). (The owner's umbrella `fg gauntlet` wrapper —
  local workspace tooling, not committed — bundles exactly this battery plus the audits.)
- **Serialization legs — whenever the serialized surface changes** (Phases 1, 2b/2c, 3, 4):
  `npm run test:serialization` + `npm run test:serialization:file` (the characterization
  rig — `scripts/serialization-roundtrip-headless.js` builds a fixture battery, round-trips
  it, and checks an EXPECTATIONS table; phases that add serializable state EXTEND that
  battery, see per-phase notes).
- **Recapture rule:** every screenshot recapture is verified on the WebKit leg too — a
  recapture can BAKE IN an error frame, after which the Chrome legs pass vacuously; only
  the cross-engine leg surfaces it (crash pixels diverge V8/JSC). Lesson learned the hard
  way: `fizzygum-recapture-masks-crash-webkit-safeguard`.
- **Test naming/authoring:** every new SystemTest is macro-driven and named
  `SystemTest_macro<CamelCase>` — the suite's ONLY style (verified 2026-07-05: 168/168
  existing tests). Author per `src/macros/CLAUDE.md` + `src/macros/MACRO-PATTERNS.md`.

**Baseline before any edit** (also = Phase 0, see below). Ignore git's harmless
`.gitattributes` warning.

## §1 Verified tree facts this plan relies on

Re-derive each before relying on it; commands given. *(facts 1–9 verified 2026-07-04 and
re-verified 2026-07-05; facts 10–18 verified/added in the 2026-07-05 pre-implementation
review, with file:line receipts)*

1. **`build.py` does NOT walk `src/` recursively.** It globs an explicit directory list
   (`buildSystem/build.py` ~lines 191–226, `filenames = sorted(... glob("src/<dir>/*.coffee"))`).
   → Every new directory (`src/dataflow`, `src/spreadsheet`) needs its own glob line
   (model: the `src/serialization` line, including its placement comment). The syntax gate
   consumes `build.py --list-shippable`, so a class missing from the glob list fails at
   *runtime dependency resolution*, not at the gate — add the glob line in the SAME commit
   that creates the directory.
2. **Class conventions:** one class per file; **filename must equal the class name**; no
   imports (all globals); `nil` not `null`/`undefined`; load order is auto-discovered by
   `src/boot/dependencies-finding.coffee` regex-scanning for the literal forms
   `extends X`, `@augmentWith X`, `new X` — always reference classes with those literal
   forms.
3. **Collaborator construction site:** `WorldWdgt` constructor ~line 389
   (`@macroToolkit = new MacroToolkit`, `@widgetFactory = new WidgetFactory`). `world.dataflow`
   is constructed here. Find with `grep -n "new WidgetFactory" src/WorldWdgt.coffee`.
4. **`doOneCycle` station order** (grep `doOneCycle: ->` in `src/WorldWdgt.coffee`):
   `updateTimeReferences → …error consoles… → macro steps → playQueuedEvents → automator
   replay → runOtherTasksStepFunction → progressFramePacedActions →
   runChildrensStepFunction → recalculateLayouts →
   hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges → pinouting/highlighting →
   updateBroken`. The drain inserts between `runChildrensStepFunction` and
   `recalculateLayouts` (spec §4.1).
5. **The ONE connection dispatch:** `ControllerMixin._fireConnection`
   (`src/mixins/ControllerMixin.coffee`) routes to a target's `_<action>Connector` variant
   when defined (the non-settling lane that joins an enclosing pass), else the public
   action. Sink application (spec §4.2 item 5) uses this lane.
6. **Stepping contract** (`WorldWdgt.runChildrensStepFunction`): membership is
   `world.steppingWdgts` (a Set: `.add @` / `.delete @`); per-member `fps` (`0` = every
   cycle, `1` = per second), optional `synchronisedStepping`; member must define `step()`.
   Model: `src/apps/AnalogClockWdgt.coffee` constructor.
7. **Serialization/duplication:** per-class protocol documented in
   `docs/serialization-duplication-reference.md`; world singletons re-bind via
   `WellKnownObjects` (`{"$wk": key}`) — the general fallback reads a `wellKnownKey`
   class marker (see `src/serialization/WellKnownObjects.coffee` header). Derived values
   use the `rebuildDerivedValue` convention (skipped by the copier, rebuilt after).
8. **Runtime CS evaluation:** `compileFGCode(src, bare)` (defined in
   `src/boot/loading-and-compiling-coffeescript-sources.coffee`); `Widget.evaluateString`
   is `eval` of compiled code in the widget's scope. Patch-node precedent for user
   formulas: `CalculatingPatchNodeWdgt.recalculateOutput`.
9. **Time references:** `WorldWdgt.dateOfCurrentCycleStart` (one timestamp per cycle,
   set in `updateTimeReferences`), `WorldWdgt.frameCount` (incremented at cycle end).
10. **Gates that always run** in `build_it_please.sh`: syntax
    (`check-coffee-syntax.js`), layering (`check-layering.js`), dead-method
    (`check-dead-methods.js`). The dead-method gate's escape hatch is
    `buildSystem/dead-method-allowlist.txt` (its header documents the mechanism); it
    harvests every identifier token — string-dispatched names and literal property
    accesses included — so `dataflowRecompute`/`dataflowValue`/`dataflowApply` invoked as
    `node.dataflowRecompute?()` at engine call sites ARE seen and will not false-positive.
    Reach for the allowlist only for a genuinely never-literally-named method (do NOT
    weaken the gate).
11. **Legacy connection machinery** (to be subsumed in Phase 6): `@target`/`@action`
    wiring via `setTargetAndActionWithOnesPickedFromMenu`; token guard
    `Widget._acceptsConnectionToken` (Widget.coffee ~1759; 38 grep matches) — it REJECTS a
    seen token BEFORE storing the value, so a come-back-around delivery is discarded
    entirely and the ring's entry node is never re-applied; token threading
    `connectionsCalculationToken` ≈146 matching lines across 19 src files (the true 6d
    sweep size); patch-node freshness gate `CalculatingPatchNodeWdgt.updateTarget`
    (~84–125: compares each connected input's token slot against the incoming token — two
    INDEPENDENTLY-sourced inputs can never match, so the spec-§8 deadlock is verified
    fact, not conjecture).
12. **`WellKnownObjects` has TWO tables** (`src/serialization/WellKnownObjects.coffee`):
    `keyFor` (identity checks + the `wellKnownKey` marker fallback) AND the `resolve`
    switch (key → live object). A new well-known singleton needs BOTH arms — `keyFor`
    alone saves fine, but the load then dies on an unknown key.
13. **Cascade propagation today is node-local:** every controller's setter core ends in an
    UNCONDITIONAL `updateTarget()` tail (e.g. `StringWdgt._setTextNoSettle` ~1258 runs it
    even when the text did not change); tokens are the only termination. Under the engine
    this tail becomes `markStale` and re-marks the very node being applied — the **echo**
    (NOMENCLATURE, dataflow table); Phase 6b must suppress or absorb it.
14. **The connector lane opens a settle at first hop:**
    `_settleLayoutsAfterOrJoinEnclosingPass` joins an enclosing pass but OPENS a settle
    when there is none (ControllerMixin header ~37–48; `check-layering.js`
    RECALC_WHITELIST). The drain therefore opens ONE settle per pass around its apply work
    (Phase 1 drain, step 5) — sinks never run off-settle (the end-of-cycle capstone audit
    exists to flag exactly that).
15. **`SliderWdgt` has no `getValue`** — its value is the bare `@value` property
    (SliderWdgt ~18). The `exportedValue` cluster is thinner than the spec shorthand:
    `getColor` = ColorPickerWdgt only, `getValue` = StringFieldWdgt only. Phase 4 adds
    `SliderWdgt.getValue: -> @value` or the slider-in-a-cell acceptance test cannot work.
16. **The serializer THROWS on undeclared unserializable state** (`Serializer.coffee`
    ~229/~322, e.g. a function-valued property): `SheetCellRecord`'s
    `@serializationTransients: ["compiledFn", …]` is mandatory for saving to work at all,
    not hygiene. Protocol reference: `docs/serialization-duplication-reference.md`.
17. **Keyboard input path:** receivers register in `world.keyboardEventsReceivers` (a
    Set; the caret's add/delete at WorldWdgt ~2330/~2378 is the model) and implement
    `processKeyDown key, code, shiftKey, ctrlKey, altKey, metaKey`
    (`src/events-input/KeydownInputEvent.coffee`). Never a DOM listener.
18. **Macro-side instrumentation asserting is established:** `MacroToolkit.evaluateString`
    (~194) runs arbitrary CS mid-macro (`SystemTest_macroEvaluateString` is the suite
    precedent) and the `MacroToolkit.assert*` verbs show the failure plumbing — a macro
    step that reads `world.dataflow.lastDrainRecomputeCount` and throws on mismatch is a
    real, supported test shape.

## §2 Deliverables map

| Phase | New files | Modified files |
|---|---|---|
| 1 | `src/dataflow/DataflowEngine.coffee`, `src/dataflow/CLAUDE.md` | `WorldWdgt.coffee` (ctor + doOneCycle), `WellKnownObjects.coffee` (keyFor AND resolve), `buildSystem/build.py`, `docs/serialization-duplication-reference.md` (well-known row) |
| 2 | `src/spreadsheet/SpreadsheetApp.coffee`, `SpreadsheetWdgt.coffee`, `SheetModel.coffee`, `SheetCellRecord.coffee`, `SheetError.coffee`, `FormulaCompiler.coffee`, `FormulaHelpers.coffee`, icon widget, `src/spreadsheet/CLAUDE.md` | `build.py`, `WorldWdgt.coffee` (launcher), `MenusHelper.coffee` (menu entry) |
| 3 | — | `Widget.coffee` (`exportedValue`), `Color.coffee` (`cellPresenter`, `lighter`, `darker`; promote `mixed`), `SpreadsheetWdgt`/presenter chain |
| 4 | (maybe) `CellSocketWdgt.coffee` | `SpreadsheetWdgt`, `SheetCellRecord`, `SliderWdgt.coffee` (`getValue`, §1.15) |
| 5 | `src/dataflow/SecondsSource.coffee`, `FrameSource.coffee` | `FormulaCompiler` (bindings), `DataflowEngine` (subscription-count hooks), `../Fizzygum-tests/DETERMINISM.md` (time-source rule) |
| 6 | — | `ControllerMixin.coffee`, `Widget.coffee`, `CalculatingPatchNodeWdgt.coffee` + patch family (incl. `DiffingPatchNodeWdgt`, `RegexSubstitutionPatchNodeWdgt`, `FanoutWdgt`/`FanoutPinWdgt`), wire menus; later: deletion sweep of token plumbing + `NOMENCLATURE.md` (legacy rows → historical) |
| 7 | `docs/dataflow-measurements.md` (or a spec section) | root `CLAUDE.md`, spec status header, completeness pass over `src/dataflow/CLAUDE.md` + `src/spreadsheet/CLAUDE.md` (seeded in 1/2a), tests-repo `CLAUDE.md` |

Tests-repo deliverables (full tier) are listed per phase below: new `SystemTest_macro*`
suites, serialization-rig fixtures + EXPECTATIONS rows (2c/3/4), the `DETERMINISM.md`
update (5), and the 6c recapture set.

---

## §3 Phases

### Phase 0 — pre-flight

1. `git pull`; run baseline verification for your tier; confirm green BEFORE any edit.
2. Re-verify §1 facts (each has a grep). If any fact has drifted, STOP, update this plan's
   §1 in its own commit, then proceed.
3. Confirm rename state: `grep -rin coalesc src buildSystem` → only
   `docs/coalescing-measurement.md` filename references (4 at last count).

**Verified 2026-07-05 (cold execution session), no drift:** baseline green — `fg build`
0 violations / `done!!!`; dpr1 suite 168/168, 0 failed. All 18 §1 facts re-verified against
the tree; every line receipt still holds (facts 11/16/17/18 line-exact; the connection-token
counts are still **146 lines / 19 files** and **38** exactly). Two grep gotchas recorded so a
re-run does not misread them: (a) fact 15 — an anchored `^  getColor:` / `^  getValue:` grep
confirms `getColor` is defined ONLY in `ColorPickerWdgt` and `getValue` ONLY in
`StringFieldWdgt`; the loose `getColor:` hit in `Appearance.coffee` is a substring
false-positive inside `ownColorInsteadOfWidgetColor:` (Appearance is a standalone drawing
delegate, not a Widget), and SliderWdgt's six `getValue` hits are inbound duck-typed calls
(`x.getValue?()`), not a definition — so Phase 4 must still add `SliderWdgt.getValue: -> @value`.
(b) `Widget`/`StringWdgt`/`SliderWdgt` live under `src/basic-widgets/`, `ColorPickerWdgt` at
top-level `src/` — grep by class name, not an assumed path. Non-material line shifts (within
the `~` the facts already carry): fact 3 `widgetFactory` is at WorldWdgt:398 (macroToolkit at
389); fact 15 SliderWdgt `@value = 50` first appears at ~31 (plan said ~18). Rename state:
exactly 4 `coalesc` matches in `src`, all `docs/coalescing-measurement.md` filename refs
(`WorldWdgt` 89, `StackElementsSizeAdjustingWdgt` 75/84, `Widget` 3893) — none in `buildSystem`.

### Phase 1 — engine core, dark

**Goal:** `DataflowEngine` exists, is constructed, its drain station runs every cycle — and
nothing uses it. Zero behavior change; the drain early-returns on an empty stale pool.

**`src/dataflow/DataflowEngine.coffee`** (plain class, NOT a Widget; the
`MacroToolkit`/`WidgetFactory` collaborator pattern):

- Class markers: `keptByReferenceOnDeepCopy: true`; `wellKnownKey: "dataflow"`. Also add
  the identity check to `WellKnownObjects.keyFor` primary list (`return "dataflow" if obj is
  world?.dataflow`) — mirrors `widgetFactory` — AND the `resolve` switch arm
  (`when "dataflow" then world?.dataflow`): §1.12 — `keyFor` alone saves fine but the
  load then dies on the unknown key.
- **State:** `@edgesFrom` (Map: producer → Set of edge records `{consumer, firesPerEvent,
  cold}` — `firesPerEvent`/`cold` unused until Phases 6/never, present in the record shape
  from day one; the record is also where a wire's `action` rides in Phase 6b), `@edgesTo`
  (reverse Map), `@stalePool` (Set — insertion-ordered, which is event order: the drain's
  determinism leans on this), `@forcedPool` (Set), `@_recalculatingDataflow` (guard),
  `@lastValues` (**WeakMap**: node → last recomputed value — weak so a dead node's value is
  never pinned; the edge Maps are strong, hence the explicit node-death API below),
  instrumentation counters (`@lastDrainPassCount`, `@maxObservedPassCount`,
  `@lastDrainRecomputeCount`).
- **Edge API:** `addEdge(producer, consumer, opts)`, `removeEdgesInto(consumer)`,
  `removeAllEdgesOf(node)` (the node-death entry — callers: 2c cell delete/re-commit, 4
  socket unmount, 6b un-wiring + a `fullDestroy` hook on connection-bearing widgets; a
  dead node left in the index is both a leak and a ghost recompute),
  `wouldCloseCycle(producer, consumer)` (DFS over `@edgesFrom`; `wouldCloseCycle(n, n)`
  answers true — the self-reference `A1` inside A1 is the trivial case). The index is
  derived and disposable (spec §2): clients re-declare edges; the engine never serializes
  any of this state (all Maps/Sets are runtime-only — give them the
  `rebuildDerivedValue`-style treatment or rebuild on wake, per
  `docs/serialization-duplication-reference.md`).
- **Node protocol (duck-typed, documented in the class header — the header IS the
  contract doc):** a node may implement `dataflowRecompute()` → new value (computing
  node; absence = pure source/sink), `dataflowValue()` → current value (the pull/cutoff
  reader for nodes that are NOT computing nodes — Phase 6b maps it to `exportedValue()`;
  a node with neither is treated as always-changed, the conservative default for
  sources), and `dataflowApply(value)` (sink application hook; Phase 2's cells and Phase
  6's wire edge-records provide concrete implementations). Equality for the equal-value
  cutoff: `_valuesEqual: (a, b) -> if a?.equals? then a.equals b else a is b`.
- **Verbs (spec §3, §5):**
  - `__poolStale: (node, forced = false)` — bare atom: add to pools, nothing else.
  - `markStale: (node, forced = false)` — dual-mode: if `@_recalculatingDataflow` then
    `__poolStale` (demote-not-throw); else `__poolStale` (per-event lane arrives in
    Phase 6b; until then everything pools).
- **Drain (spec §4.1/§4.2/§5):** `recalculateDataflow()`:
  1. `return if @stalePool.size is 0` — the dark-phase hot path; keep it first.
  2. Re-entrancy guard: throw if `@_recalculatingDataflow` (mirror the
     `recalculateLayouts` guard's message style).
  3. Loop (drain-until-quiet): snapshot + clear pools; compute the downstream closure via
     the index; order it. Ordering precision (the one spot where a hand-wave breeds a
     bug): Kahn over the closure's subgraph leaves unordered not just cycle members but
     ALSO everything DOWNSTREAM of a cycle (their in-degrees never reach 0) — so either
     run a proper SCC condensation (Tarjan, ~30 lines; Kahn over the condensation; within
     an SCC, BFS from the pass's entry node — one lap, spec §7) or accept the simpler
     Kahn-then-BFS-remainder ordering and DOCUMENT that a diamond below a cycle may cost
     one extra (cutoff-terminated) pass. Multiple entries in one batch: BFS from the
     entries in stale-pool insertion order (= event order, §"State") keeps the drain
     deterministic (spec §10).
  4. Walk the ordered closure with a per-pass `visited` set and a `changed` set seeded
     with the snapshot's nodes. Recompute/apply a node ONLY IF it is in the snapshot or
     has a producer in `changed` — this dynamic pruning IS the equal-value cutoff
     (without it every pass recomputes the entire closure). Recompute at most once per
     pass; a recomputed value that `_valuesEqual`s the old one (and is not forced) does
     NOT enter `changed`. `visited` covers SINK APPLICATION too: a node already visited
     this pass is not re-applied — this reproduces the token guard's
     discard-on-come-back-around semantics (§1.11) and is what stops a ring at exactly
     one lap.
  5. Apply-phase settle (§1.14): the engine opens ONE settle around each pass's
     interleaved recompute+apply (world-level `_settleLayoutsAfter`; if `check-layering`
     objects to the cross-object call, add a sanctioned wrapper on `WorldWdgt` and record
     the deviation) which every `_<action>Connector` application then joins;
     `changed()`-only sinks are settle-free. Wrap each node's recompute in try/catch: on
     throw, record the error AS the node's value if the node supports it
     (`dataflowNoteError?`), never leave it stale, stash the exception for the error
     console outside the drain (model: layout's `layoutErrorsToReport`).
  6. Pass-count cap: `dataflowPassesSanityLimit = 1000`, throw
     `DATAFLOW_NONCONVERGENCE` with the offending nodes' identities in the message.
     Expected measured peaks: 1 pass typical, 2 with sink-onto-source chains (and, if 6b
     ships the pool-the-echo fallback instead of echo suppression, 2 as the circuit
     norm) — record actuals in Phase 7.
- **What the engine must NOT do:** call any public self-settling setter; call
  `_invalidateLayout`; fire a connection's settling entrypoint. Sinks route via the
  `_<action>Connector` lane or bare mutators (§1.5), joining the pass's apply-phase settle
  (step 5); anything a sink pools bare still settles in the `recalculateLayouts` that
  immediately follows the drain.

**`WorldWdgt` changes:** construct `@dataflow = new DataflowEngine` beside
`@widgetFactory`; insert `@dataflow.recalculateDataflow()` between
`@runChildrensStepFunction()` and `@recalculateLayouts()` in `doOneCycle`, with a comment
naming the two-drain contract (dataflow settles values; layout settles geometry; one-way
coupling — cite spec §4.1/§5).

**`build.py`:** add `src/dataflow` glob line (place before the serialization line, comment
in the established style: shipped feature, not homepage-excluded).

**Docs (same commit):** seed `src/dataflow/CLAUDE.md` — collaborator pattern, node
protocol, drain contract, the two-drain sentence, pointer to the spec (subsystem-depth
docs are created WITH the subsystem, not in Phase 7; Phase 7 only closes them out). Add
the engine's row to the well-known-objects section of
`docs/serialization-duplication-reference.md`. The `DataflowEngine` class header carries
the node-protocol contract in full.

**Verification:** tier verification (dark ⇒ zero pixel diffs, zero recaptures), plus the
serialization legs (§0 cadence — the world grew a well-known singleton). Then the
console exercise — open the built world, paste into a ScriptWdgt or the console (dev menu):

```coffee
a = {name: "a"}
b = {name: "b", dataflowRecompute: -> world.dataflow.pullValue(a) + 1}
# adapt to the final pull API; assert:
world.dataflow.addEdge a, b
world.dataflow.markStale a
world.dataflow.recalculateDataflow()
# expect: lastDrainPassCount is 1, lastDrainRecomputeCount is 1
```

(Adjust to the real API you built; the point is a documented, repeatable by-hand smoke of
pool→drain→once semantics before any real client exists. If `pullValue` ends up not being
an engine method — e.g. nodes read inputs directly — update this snippet in this plan.
OPTIONAL: productize this smoke as `SystemTest_macroDataflowEngineSmoke` — a no-pixel
macro driving the same calls via the toolkit's `evaluateString`, throwing on a wrong
counter (§1.18). If skipped, Phase 2c's instrumentation asserts subsume it — record the
choice in the ledger either way.)

**Landed 2026-07-05 (this session) — all green.** `src/dataflow/DataflowEngine.coffee`
(+ `src/dataflow/CLAUDE.md`), `WorldWdgt` (ctor `@dataflow = new DataflowEngine` beside
`@widgetFactory`, unguarded since it ships; drain call in `doOneCycle` between
`runChildrensStepFunction` and `recalculateLayouts`), `WellKnownObjects` (both arms),
`build.py` glob, serialization-reference well-known row. Decisions/deviations recorded here
per rules 7/8:
- **Ordering** = Kahn + one-lap-from-entry BFS remainder (the plan's simpler sanctioned
  option, NOT full Tarjan SCC condensation). Visit-once + the equal-value cutoff converge
  regardless of order; a diamond below a cycle may cost one extra cutoff-terminated pass.
  Documented in the class header. Tarjan remains a future optimisation for Phase 6.
- **Settle call is gate-clean** — `recalculateDataflow`/`_drainOnePass` calling
  `world._settleLayoutsAfter` did NOT trip `check-layering` (`recalculateDataflow` is not
  low-level by name; `_drainOnePass` has no guard-return-before-settle), so NO WorldWdgt
  settle-wrapper was needed (the plan's fallback was not exercised).
- **Smoke test AUTHORED, not skipped** — `SystemTest_macroDataflowEngineSmoke` (sibling
  repo) drives the engine DIRECTLY from the macro scope (simpler than nested
  `evaluateString`; `world.dataflow` is reachable there) and asserts pool→drain→once by
  throwing. Authored (rather than allowlisting) because 3 dark public-API methods
  (`addEdge`/`removeAllEdgesOf`/`wouldCloseCycle`) had no in-`src` callers yet and the
  dead-method gate flags them; the gate harvests tokens from `tests/**/*.js`, so the test's
  macro source references them (plan §1.10; allowlist avoided). Its capture run at dpr1+dpr2
  IS the Phase 1 behavioural verification (the assertions passed). A 4th flag,
  `_describeStalePool`, was a gate false-positive (used only inside a `"…#{…}…"`
  interpolation that the gate's `stripComment` truncates at the first `#`) — fixed by
  assigning to a local before the throw.
- **Verification:** `fg gauntlet` green — dpr1/dpr2/webkit suite **169/169** (168
  dark-unaffected + the new smoke), apps smoke, tiernaming/settle/capstone runtime gates;
  both serialization legs green (round-trip rig 21+31 checks, FILE 7 checks — the engine
  index is never serialized and no widget references `@dataflow` yet, so the world
  envelope is untouched). Smoke references cross-engine-verified on the webkit leg.

### Phase 2 — spreadsheet v1 (first client)

New `src/spreadsheet/` directory (+ `build.py` glob line, same commit). All widgets follow
the layout discipline: immediate `_apply*` mutators inside `_reLayout`, bulk moves inside
`world.disableTrackChanges()` … `world.maybeEnableTrackChanges()` + one `fullChanged()`
(model: `StretchablePanelWdgt._reLayout`). Seed `src/spreadsheet/CLAUDE.md` in the 2a
commit (shell + painted-grid model + socket philosophy) and grow it in 2b/2c/4 — subsystem
docs are a per-phase deliverable, not a Phase 7 chore.

**2a — shell, painted grid, selection.**
- `SpreadsheetApp extends IconicDesktopSystemWindowedApp` (`title: "Spreadsheet"`,
  `slot: nil` — multiple sheets allowed; `buildIcon`; `buildWindow` wraps a
  `SpreadsheetWdgt` in a `WindowWdgt` — model: `DegreesConverterApp.buildWindow`).
  Register a launcher at the WorldWdgt boot site (grep `createOpener` there) and/or a
  `MenusHelper` entry (grep `"Simple doc launcher"` for the pattern).
- `SpreadsheetWdgt extends Widget` hosting a `ScrollPanelWdgt` whose contents is the grid
  pane. The grid pane paints EVERYTHING itself in
  `paintIntoAreaOrBlitFromBackBuffer` (model: `AnalogClockWdgt`'s custom paint): gridlines,
  lettered column headers / numbered row headers (headers may be a separate non-scrolling
  chrome layer — decide during 2a; simplest v1: headers painted by `SpreadsheetWdgt` itself
  outside the scroll frame), the selection rectangle, and (from 2b) cell value text.
  Fixed default column width / row height; column resize is NOT in v1.
- Selection: `mouseClickLeft` → cell coordinate math → repaint via `changed()`. Keyboard
  arrows move selection — the standard path (§1.17): register in
  `world.keyboardEventsReceivers` (add on focus/selection, delete on blur — the caret's
  add/delete at WorldWdgt ~2330/~2378 is the model) and implement `processKeyDown`;
  never a DOM listener.
- **SystemTests to author (sibling repo, full tier; naming per §0):**
  `SystemTest_macroSpreadsheetOpenGrid` (launch, screenshot),
  `SystemTest_macroSpreadsheetSelection` (click cells, arrows, screenshot).
- Determinism: nothing time-based exists yet; keep it that way (no `Date.now`, no
  wall-clock — spec §10).

**Landed 2026-07-05 (this session) — all green.** `src/spreadsheet/SpreadsheetApp.coffee`
+ `SpreadsheetWdgt.coffee` + `src/spreadsheet/CLAUDE.md`; `build.py` glob; `WorldWdgt`
launcher registration. Decisions/deviations recorded per rules 7/8:
- **DIRECT-PAINT, no `ScrollPanelWdgt` in v1** (the spec §9.1 hosts the grid in one). The
  grid is a fixed viewport that fits the window; scroll is deferred until the model exceeds
  it. The paint + hit-test math transplant into a scroll-child unchanged; sockets (2b/4) are
  unaffected. Revisit when a sheet needs more cells than fit.
- **Fixed-size window content** (`initialiseDefaultWindowContentLayoutSpec` elasticity 0 +
  `preferredExtentForWidth`/`_setWidthSizeHeightAccordingly` = grid size — the AnalogClockWdgt
  pattern). This was the DETERMINISM fix: a stretchable content converges over several cycles,
  so a screenshot right after `launch()` (before the multi-cycle settle) is a pre-settle frame
  that varies run-to-run — the first OpenGrid capture caught one. Fixed-size settles in ONE
  cycle → the capture is the fixed point. (`takeScreenshot` already gates on
  `waitForScreenshotReady`/warm-repaint, but that does NOT wait for layout convergence.)
- **Text = 12px Arial**, left-aligned (SWCanvas ships Arial/Times/Courier atlases only —
  `SWCanvasElement-extensions.coffee`; 12px Arial is the deterministic band). Centering needs
  `measureText` — a later polish.
- **Placeholder icon** (`GenericShortcutIconWdgt`+`TypewriterIconWdgt`); custom `SpreadsheetIconWdgt`
  deferred. **Launcher in the examples folder** (not the desktop) so it doesn't shift the
  desktop icon grid (mass recapture); tests open via `launch()`. MenusHelper entry deferred.
- **Keyboard focus-on-click**: `mouseClickLeft` reads `world.hand.position()` for cell
  hit-testing and registers the sheet in `world.keyboardEventsReceivers`; `processKeyDown`
  moves the single-cell selection on `ArrowLeft/Right/Up/Down` (key-based, CaretWdgt
  convention); deregistered in `destroy`. Multi-sheet focus refinement deferred.
- **Verification:** `fg gauntlet` green — dpr1/dpr2/webkit suite **171/171** (168 + Phase-1
  smoke + `SpreadsheetOpenGrid` + `SpreadsheetSelection`), apps smoke, tiernaming/settle/
  capstone gates; both serialization legs green (no new serialized surface in 2a). Both new
  tests captured SWCanvas dpr1+dpr2 and webkit-verified; the rendered grids were eyeballed
  (OpenGrid = full 6×14 grid + A1 selected; Selection = D4 after click C3 + Right + Down).
  NOTE: a brand-new test needs a FULL `fg build` (regenerates `testsManifest`) before
  `fg recapture` finds it — a bare recapture right after authoring reports "did not select
  exactly one SystemTest".

**2b — cell model, evaluation, editing.**
- `SheetModel` (plain class): sparse Map keyed `"A1"`; owns `SheetCellRecord`s; address
  helpers (`colToLetters`/`lettersToCol`).
- `SheetCellRecord` (plain class): persistent `{@sheet, @address, @source}`; derived
  `{@compiledFn, @value, @errorFlag}` — derived fields rebuilt, never serialized:
  declare them in `@serializationTransients` (MANDATORY, §1.16 — the serializer THROWS
  on an undeclared function-valued property; per-class protocol in
  `docs/serialization-duplication-reference.md`; the SHEET serializes: model + sources +
  geometry; on load/duplicate, recommit every cell to rebuild derived state and
  re-declare edges).
- `FormulaCompiler` (plain class): `commit(cellRecord, newSource)` →
  (1) strip CS comments and string literals from a scan copy;
  (2) scan identifiers: cell refs (`/(?<![\w$.])[A-Z]{1,2}(?:[1-9][0-9]{0,3})(?![\w$])/`,
  NOT preceded by `.` so `foo.A1` is a property access, not a ref — JS lookbehind is fine
  on every engine the suite runs: current Chrome/Puppeteer, Playwright WebKit; production
  Safari ≥16.4), helper names (`FormulaHelpers` own-property names), later
  `seconds`/`frame`;
  (3) build the wrapper source
  `"(#{boundNames.join ','}) ->\n#{indented user source}"`, compile ONCE via
  `compileFGCode` (bare — NB it THROWS a rich Error on a parse failure, boot file ~88:
  the catch around it IS the `#SYNTAX` path), eval to get `@compiledFn`;
  (4) on compile failure: `@value = new SheetError "SYNTAX", message` (see 2c), no edges.
  Everything-is-CoffeeScript (spec §9.2): `42`, `"total"`, `A1 * 2` are all just source.
  Evaluation calls `@compiledFn.apply sheetScope, boundValues` — decide and document
  `sheetScope` (`@` inside formulas): the `SpreadsheetWdgt`. Full world access, no sandbox.
- Editing v1: selected cell + typing → an overlay editor mounted at the cell's rect (a
  `StringWdgt`-based single-line editor; Enter commits, Escape cancels; commit path =
  `FormulaCompiler.commit` + `world.dataflow.markStale cellRecord`). Multi-line editing
  via the cell's menu → `CodePromptWdgt` (existing modal code editor). The overlay editor
  is the ONLY live child widget in v1 — everything else stays painted.
- **SystemTests:** `SystemTest_macroSpreadsheetLiteralEntry` (type `42`, `"hello"` — note
  the CS quoting requirement is BY DESIGN, spec §9.2/§13),
  `SystemTest_macroSpreadsheetEditCancel`. Typing in macros is established (keyboard
  patterns in `src/macros/MACRO-PATTERNS.md`).

**Landed 2026-07-05 (this session) — all green.** New `src/spreadsheet/SheetModel.coffee`,
`SheetCellRecord.coffee`, `FormulaCompiler.coffee`, `SheetError.coffee`; `SpreadsheetWdgt`
extended (model, value painting, editing); `src/spreadsheet/CLAUDE.md` grown. `build.py` needed
NO change (the 2a `src/spreadsheet/*.coffee` glob auto-ships new files). Decisions/deviations per
rules 7/8:
- **Evaluation routes THROUGH the engine** (the spreadsheet is now the engine's FIRST live
  client): commit = `FormulaCompiler.commit` (compile once) + `world.dataflow.markStale cell`;
  the drain calls `SheetCellRecord.dataflowRecompute` → `@compiledFn.apply sheetScope, boundValues`
  → caches `@value` → repaints, in the SAME `doOneCycle` as the Enter event. `sheetScope` (`@` in
  a formula) = the `SpreadsheetWdgt` (full world access, no sandbox).
- **Buffer-driven overlay editor, NO caret** — DEVIATION from "reuse the caret / StringWdgt.edit".
  The framework has NO built-in Enter-commits/Escape-reverts (no `accept`/`cancel` handlers exist
  in the tree — only `CaretWdgt` escalates them, to nobody; text live-updates as you type), and a
  live caret is a keyboard receiver that BLINKS (non-deterministic under a screenshot). So the
  sheet stays the SOLE keyboard receiver in both modes and drives its own edit BUFFER (append /
  Backspace / Enter-commits / Escape-cancels), mirrored into a live overlay `StringWdgt` (the
  socket precursor). Exact, deterministic commit/cancel; no receiver juggling. Rich editing stays
  the deferred `CodePromptWdgt` path.
- **Layering discipline:** the mount/teardown of the overlay mutates the tree, so the ONE settle
  is opened at the PUBLIC event entries (`processKeyDown`/`mouseClickLeft`, like `world.edit`) and
  every edit-lifecycle helper is a `*NoSettle` core (`_addNoSettle`/`_setTextNoSettle`/
  `_fullDestroyNoSettle`/`_apply*`). The first pass FAILED `check-layering.js` [G]/[A] (low-level
  `_x` calling self-settling wrappers) — restructured to this; green.
- **`SheetCellRecord.@serializationTransients = ["compiledFn","boundNames","value","errorFlag"]`**
  (mandatory, §1.16 — the serializer THROWS on an undeclared function-valued own-prop; the
  transients check runs BEFORE that). DeepCopier copies a function prop by reference (harmless;
  overwritten by the 2c recommit-on-copy). `SpreadsheetWdgt` also declares the transient editing
  fields.
- **`SheetError` created in 2b** (minimal — the `#SYNTAX` path needs it); 2c grows `#ERR`/`#LOOP`
  + propagation. **`FormulaHelpers` deferred to Phase 3** (only useful once value-class ops exist,
  spec §9.5); the compiler's helper-scan is guarded `if FormulaHelpers?` so it lights up then.
- **References READ but are not yet REACTIVE:** `dataflowRecompute` resolves cell-ref bound names
  from the model (so a ref evaluates), but the reactive EDGE (`addEdge` at commit, so a ref
  re-runs when its target changes) + cycle rejection + error propagation are Phase 2c. No 2b test
  exercises a reference (literals only), so this is not a visible half-feature.
- **Verification:** `fg build` 0-violations (syntax/layering/dead-methods/stinks/thin-wraps green;
  21 new methods, 0 new dead); headless boot-smoke green (native + SWCanvas). Two new tests
  authored + captured SWCanvas dpr1+dpr2, re-verify matched (deterministic); rendered grids
  eyeballed (LiteralEntry = `42` in A1 + `hello` in B2; EditCancel = A1 reverted to `7`, not
  `999`). `fg gauntlet` (dpr1/dpr2/webkit 173 + apps + tiernaming/settle/capstone) + both
  serialization legs green — see the ledger.

**2c — references, recompute, errors.**
- Cells become dataflow nodes: `SheetCellRecord.dataflowRecompute()` pulls referenced
  cells' values (via the sheet model; a reference to a widget-valued cell applies the
  exported-value rule from Phase 4 — until then, values are plain), runs `@compiledFn`,
  returns the new value. Commit re-declares edges: `engine.removeEdgesInto cell;
  engine.addEdge refCell, cell for each ref` — but FIRST
  `engine.wouldCloseCycle(...)` for each new edge: on a would-be cycle, reject the commit
  with `@value = new SheetError "LOOP"` and declare NO edges (spec §7). (Checking each
  new edge against the pre-commit graph suffices: every new edge points INTO the
  committed cell, so any new cycle must run cell→…→refCell over existing edges.)
  Deleting a cell (committing empty source) calls `engine.removeAllEdgesOf cellRecord`
  (Phase 1 node-death API); what downstream references then see (`nil` vs an `#ERR`) —
  decide and document in `src/spreadsheet/CLAUDE.md`.
- `SheetError` (plain class, `src/spreadsheet/`): `{@kind, @message}`; `toString ->
  "#" + @kind`; propagates: `dataflowRecompute` of a cell whose input is a `SheetError`
  returns that error (short-circuit before calling the formula). Painted distinctly
  (badge/red text).
- Formula runtime throw → catch inside the cell's `dataflowRecompute`, return
  `new SheetError "ERR", err.message` (this doubles as the engine-level
  force-resolve of spec §5 — the cell always yields a value).
- **SystemTests:** `SystemTest_macroSpreadsheetRefsRecalc` (A1=3, B1=`A1 * 2`,
  C1=`A1 + B1`; edit A1→5; assert 10/15 — the diamond, computed once: also assert via
  `world.dataflow.lastDrainRecomputeCount` in an `evaluateString` macro step that throws
  on mismatch, §1.18), `SystemTest_macroSpreadsheetLoopRejected`,
  `SystemTest_macroSpreadsheetErrorPropagation`.
- **Round-trip & duplication coverage (this phase creates the serialized surface):**
  extend the serialization rig's fixture battery + EXPECTATIONS table
  (`../Fizzygum-tests/scripts/serialization-roundtrip-headless.js`) with a sheet fixture —
  literals + a formula chain + an error cell; the restore path exercises the §5 rebuild
  strategy (recommit all, mark all stale, one drain). Author
  `SystemTest_macroSpreadsheetDuplicate`: duplicate a sheet window (the standard duplicate
  gesture), edit the ORIGINAL's A1, assert the copy is unaffected AND the copy's own
  recompute works — spec §2's no-engine-fix-up corollary, actually exercised, not assumed.
  Run both serialization legs (§0).
- **Phase-close:** run the §0 battery — 2c closes the first user-visible feature set.

**Landed 2026-07-05 (this session) — all green.** Modified `FormulaCompiler` (edge declaration +
cycle rejection), `SheetCellRecord` (error propagation + `dataflowNoteError`), `SpreadsheetWdgt`
(recommit hooks, single-focus, node-death on destroy), `SheetError`/`SheetModel`/`SheetCellRecord`
(deep-copy participation); new `src/boot/extensions/Map-extensions.coffee` (+ `build_it_please.sh`
cat line); `src/spreadsheet/CLAUDE.md` grown. Decisions/deviations per rules 7/8:
- **Reactive edges live in `FormulaCompiler.commit`** (so "commit" = compile + wire, and the
  recommit-on-load/copy rebuilds both in one call): every path first `removeEdgesInto cell` (drop
  old deps), then a successful compile runs the **cycle check** per ref (`wouldCloseCycle refCell,
  cell` against the pre-commit graph) BEFORE any `addEdge`; a cycle ⇒ `@value = #LOOP`,
  `@compiledFn = nil`, NO edges (spec §7). Syntax fail ⇒ `#SYNTAX`, no edges.
- **Errors are values (spec §9.6):** `dataflowRecompute` short-circuits to the input's SheetError
  BEFORE running the formula (propagation); a formula THROW is caught by the engine →
  `dataflowNoteError` returns a `#ERR` (force-resolve, spec §5). Both painted in the error colour.
- **Deletion (blank commit) = clear value + `removeEdgesInto`, KEEP the node** so downstream refs
  reactively see `nil`; full `removeAllEdgesOf` is reserved for node DEATH (sheet `destroy`, added
  this phase — a destroyed sheet drops all its cells' edges — and Phase 6 un-wiring). Documented in
  `src/spreadsheet/CLAUDE.md`.
- **Duplication (spec §2, no-engine-fix-up):** `SpreadsheetWdgt._reactToBeingCopied` (deep-copy)
  and `_afterDeserialization` (restore) both call `recommitAllCells` (recommit all → mark all
  stale → one drain), so a copied/restored sheet re-declares its OWN edges — the engine index is
  never serialized/copied (`keptByReferenceOnDeepCopy`). This needed the plain data classes to be
  deep-copyable: `SheetModel`/`SheetCellRecord` `@augmentWith DeepCopierMixin`, `SheetError`
  `keptByReferenceOnDeepCopy` (immutable), and a NEW general `Map::deepCopy`/`Set::deepCopy`
  (parallel to `Array::deepCopy`; the serializer already handled `$Map`/`$Set`).
- **Single-sheet keyboard focus** (a fix the Duplicate test surfaced, not conjecture): the copier's
  `alignCopiedWidgetToKeyboardEventsReceiversSet` puts a duplicated sheet in the receivers set too,
  so typing hit BOTH sheets (the copy committed a stray literal). `_takeKeyboardFocus` now removes
  other `SpreadsheetWdgt`s from the receivers set first. (2a's "multi-sheet focus deferred" — this
  is the minimal single-focus the multi-sheet case needs.)
- **SystemTests (all captured SWCanvas dpr1+dpr2, webkit-verified, eyeballed):**
  `SpreadsheetRefsRecalc` (diamond 5/10/15, `lastDrainRecomputeCount == 3` via the NEW toolkit verb
  `assertValuesEqual`), `SpreadsheetLoopRejected` (`#LOOP`), `SpreadsheetErrorPropagation`
  (`#ERR`→`#ERR`), `SpreadsheetDuplicate` (original 5/10 vs independent copy 3/6 + value
  assertions). Serialization rig grew a `sheet` fixture + `spreadsheet.roundtrip.rebuild` check
  (literals + formula chain + error cell; restore rebuilds `3|6|9|#ERR`).
- **Verification:** `fg build` 0-violations + boot-smoke green; a headless probe proved deep-copy
  independence directly (copy stays 3/6 after editing the original to 5); `fg gauntlet` (dpr1/dpr2/
  webkit + apps + gates) + both serialization legs green — see the ledger.

### Phase 3 — value protocol & presenters (Color first)

- `Widget.exportedValue: -> @getColor?() ? @getValue?() ? @text` (spec §9.3) — on
  `Widget`, with a header comment naming it the unified reader over the duck-typed cluster.
- `Color`: promote `mixed` (remove its homepage-exclusion markers `# »>> … <<«` — they mark
  build-stripped code; `mixed` becomes shipped). While promoting (verified 2026-07-05):
  its body builds `new @constructor(...)` — switch to `@constructor.create(...)` (keeps
  the immutable-and-cached invariant), and its comment says "ignore alpha" while the code
  MIXES alpha — decide the intended alpha semantics and make comment+code agree. Add
  `lighter: (amount = 0.5) -> @mixed 1 - amount, Color.WHITE` and `darker` (via
  `Color.BLACK`; both constants exist — `Color.create` statics at Color ~22/~147); add
  `cellPresenter: -> s = new RectangleWdgt; s.setColor @; s` — respect Color's official
  immutability (never mutate; see the class's own deep-copy comment).
- Presenter chain in the sheet (spec §9.4), evaluated per recompute:
  widget → itself; `value.cellPresenter?()` → returned widget mounted in the cell's rect;
  else painted `toString()` text (NO widget — painting stays the default). Presenter
  lifecycle decision (spec §13, decide now): if the value's class is unchanged, REUSE the
  mounted presenter and update it (e.g. `setColor`); on class change, dispose and rebuild.
- `FormulaHelpers` v1: `mix: (a, b, p = 0.5) -> a.mixed p, b` — one helper to prove the
  binding path; the algebra otherwise = value-class methods (spec §9.5).
- The "operate ➜" cell menu (meta-introspection listing of the value class's methods) is
  OPTIONAL scope — implement only if time allows; record either way in the ledger commit.
- **SystemTests:** `SystemTest_macroSpreadsheetColorCell` (`new Color 255, 0, 0` → swatch;
  B1 = `A1.lighter()` → lighter swatch; edit A1 → both change). Extend the rig's sheet
  fixture with a color cell (the compact-form round-trip through `create` is already the
  documented Color behavior — now exercised through a sheet) and run the serialization
  legs (§0).

**Landed 2026-07-05 (this session) — all green.** Modified `Widget.coffee` (`exportedValue`),
`Color.coffee` (promoted `mixed` + `lighter`/`darker`/`cellPresenter`), `SpreadsheetWdgt` (the
classify→present chain), `SheetCellRecord._cacheValue` (the reconcile trigger); new
`src/spreadsheet/FormulaHelpers.coffee` (auto-shipped by the 2a `src/spreadsheet/*` glob — no
`build.py` change); `src/spreadsheet/CLAUDE.md` grown. Decisions/deviations per rules 7/8:
- **`Widget.exportedValue: -> @getColor?() ? @getValue?() ? @text`** — defined now (spec §9.3); its
  CONSUMER (a reference to a widget-valued cell) lands with widget-valued cells in Phase 4, so it is
  exercised DIRECTLY in the ColorCell test (a bare `StringWdgt`'s `@text` arm) to satisfy the
  dead-method gate — the Phase-1 precedent of driving dark public API from a macro rather than
  allowlisting. §1.15 honoured: no `SliderWdgt.getValue` added here (that is Phase 4).
- **`Color.mixed` promoted + alpha semantics decided.** Removed the `# »>> … <<«` homepage-exclusion
  markers (it now ships — it backs lighter/darker + `mix`); switched its body from `new
  @constructor(...)` to `@constructor.create(...)` (keeps the immutable-and-cached invariant). The
  old comment said "ignore alpha" while the code MIXED it — **decided: blend ALL FOUR channels** (a
  plain lerp, no special-casing; moot for the opaque colours spreadsheets use) and made comment+code
  agree. Added `lighter`/`darker` (mix toward `Color.WHITE`/`BLACK`) and `cellPresenter` (a
  `RectangleWdgt` swatch via `setColor` — immutability respected).
- **Classify→present (spec §9.4), REBUILD-on-change lifecycle (spec §13 decided).** `_cacheValue`
  calls `_reconcileCellPresenterNoSettle` per recompute (INSIDE the drain's settle, so NoSettle
  cores): a value answering `cellPresenter()` mounts that widget in the cell's rect (branch 2), else
  painted text (branch 3, the value-paint loop skips a presented cell); branch 1 (value IS a Widget)
  is Phase 4. Lifecycle = dispose + fresh `cellPresenter()` on value change (keeps the sheet
  value-class-agnostic — no per-class update protocol), with a churn-skip on an unchanged value.
- **Presenter serialization deviation (recorded; Phase 4 cleans it).** Presenters are DERIVED and
  their `@_cellPresenters`/`@_presentedValues` indexes are transient, but a presenter widget still
  rides a whole-world snapshot AS a tree child. `recommitAllCells` now first sweeps every derived
  child (`_disposeAllCellPresentersNoSettle` — the sheet's only children are the editor + presenters)
  and the drain rebuilds them, so restore/duplicate stay exact (no orphan/double swatch). Phase 4's
  socket makes presenters properly non-serialized. No new serialization CODE/handlers (RectangleWdgt
  + Color already serialize) — the deliverables-map "no new serialized surface" holds in that sense.
- **`FormulaHelpers.mix` (spec §9.5)** — `@mix: (a, b, p = 0.5) -> a.mixed p, b`; static methods are
  bound by the compiler's existing `for own name of FormulaHelpers` scan. (A static is also exempt
  from the dead-method gate's instance-method header regex — no reference needed.)
- **"operate ➜" cell menu: DEFERRED** (the plan marked it optional). Meta-introspection UI, not part
  of the value protocol; recorded here as not-done. Can land any later phase.
- **SystemTests (captured SWCanvas dpr1+dpr2, webkit-verified via the gauntlet, eyeballed):**
  `SpreadsheetColorCell` — A1=`new Color 255,0,0` (swatch), B1=`A1.lighter()`, C1=`A1.darker()`,
  D1=`mix A1, B1` (four red-family swatches, image_1); `exportedValue` `@text`-arm assertion; edit
  A1→blue recolours the whole chain reactively (image_2). Serialization rig's `sheet` fixture grew a
  `D1` Color cell (`spreadsheet.roundtrip.rebuild` now `3|6|9|rgb(255,0,0)|#ERR`) + a new
  `spreadsheet.roundtrip.colorPresenter` check (exactly one presenter/child on both orig and restore
  — proves the sweep, no orphan/double).
- **One benign inspector recapture** (owner rule `byte-identical-not-sacred-for-benign-inspector-
  recapture`): `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly` image_2/image_3.
  `Widget.exportedValue` grows every widget's inherited-member list by one row, and this is the ONE
  inspector test that SHOWS inherited members + scrolls through them, so the list's scroll/thumb
  geometry shifted sub-visibly. Behavior verified unchanged (LEFT rect still fades to alpha 0.25,
  RIGHT copy to 0.6 — each inspector drives its own target; image_1 unchanged) before recapturing;
  webkit-verified. NOT a code contortion — the method belongs on `Widget` (spec §9.3).
- **Verification:** `fg build` 0-violations (syntax/layering/dead-methods/stinks/thin-wraps) +
  boot clean (no Color→RectangleWdgt load-order issue); both serialization legs green (23 native +
  33 SWCanvas incl. the two new checks; 7 file); `fg gauntlet` (dpr1/dpr2/webkit + apps + gates) —
  see the ledger.

### Phase 4 — widget-valued cells & sockets

- A formula yielding a Widget mounts it live in the cell (presenter chain branch 1);
  the mount point is the **socket** (either a thin `CellSocketWdgt` or direct child
  management in the grid pane — decide by whichever keeps `_reLayout` simplest).
  Unmounting de-registers the socket wiring; a dying cell calls `removeAllEdgesOf`
  (Phase 1 node-death API).
- References to a widget-valued cell yield `widget.exportedValue()`; a widget with no
  export yields the widget itself (spec §9.3). Add `SliderWdgt.getValue: -> @value`
  (§1.15) with a one-line header comment naming it the exported-value reader — without it
  `exportedValue` falls through to the export-nothing branch and the acceptance test
  below cannot work.
- Interactivity in: wire the mounted widget's connection at the socket
  (`widget.setTargetAndActionWithOnesPickedFromMenu nil, nil, socketAdapter, "cellInput"`
  — hard-wired at mount, signature verified (first two args ignored); the adapter's
  `cellInput` marks the cell stale and accepts-and-ignores the token argument; pooled
  lane, so a drag = per-frame recompute of dependents, spec Scenario A). Drag-and-DROP of
  desktop widgets into cells is OUT of scope for this phase (record as deferred).
- **Save/load semantics for widget-valued cells (decide + document now; spec §13):** the
  serialized tree carries the MOUNTED widget (the socket's child), while the §5 rebuild
  strategy (recommit-all-then-drain) would recompute the formula and REPLACE it with a
  fresh instance, discarding runtime state (a moved slider's position). Recommended v1:
  on load, if the restored socket already holds a widget of the class the recompute
  would produce, KEEP the restored widget; on class mismatch, rebuild. Document the
  decision in `src/spreadsheet/CLAUDE.md`.
- **SystemTests:** `SystemTest_macroSpreadsheetSliderCell` (macro drags the slider;
  dependent cell updates; deterministic — input events only). Extend the rig's sheet
  fixture with a slider-valued cell pinning the save/load decision (drag, save, load,
  assert the position survived — or the documented alternative); run the serialization
  legs (§0).
- **Phase-close:** run the §0 battery.

### Phase 5 — time sources

- `src/dataflow/SecondsSource.coffee`, `FrameSource.coffee`: plain classes; singletons
  constructed lazily by the engine (or world) on first subscription;
  `subscriberCount` maintained by the engine's `addEdge`/`removeEdgesInto` (engine calls
  `source.subscriberCountChanged n` — registering in `world.steppingWdgts` (`fps: 1` /
  `fps: 0`, `step: -> world.dataflow.markStale @`) while n>0, deregistering at 0).
- Values pulled at recompute: `SecondsSource` → `WorldWdgt.dateOfCurrentCycleStart`
  (a `Date`, set at cycle start in `updateTimeReferences`, nil'd at cycle end — verified);
  `FrameSource` → `WorldWdgt.frameCount` (incremented at cycle END — verified; document
  which frame a `frame` formula therefore sees). Decide the pulled value SHAPE now:
  `seconds` binds a NUMBER (e.g. epoch seconds, `Math.floor(date.getTime() / 1000)`),
  not the raw `Date` — formula arithmetic and `_valuesEqual` both want a scalar; document
  in `src/spreadsheet/CLAUDE.md` + the engine header. Formulas NEVER call `Date`
  (spec §6/§10); the scanner bindings `seconds` / `frame` become edges to the sources
  plus bound parameters carrying the pulled values.
- Perf discipline (spec §9.7): a tick that only changes painted text = `changed()` on the
  grid pane region; NO `_invalidateLayout` on the tick path — assert this by reading the
  code path, and measure: with one `seconds` cell, `lastDrainRecomputeCount` per second
  must equal the dependent count.
- **Testing & determinism:** time-driven cells are EXCLUDED from pixel assertions unless
  the macro drives ticks: for tests, set the source's value injection via macro
  (`world.dataflow` exposing a test hook is acceptable if guarded `if Automator?` so
  `--homepage` strips it — established precedent, e.g. `StretchablePanelWdgt` ~82).
  Author `SystemTest_macroSpreadsheetSecondsCell` only if the macro-driven tick hook is
  built; otherwise verify by hand and record that in the ledger.
- **Docs (same commit):** add the time-source rule to `../Fizzygum-tests/DETERMINISM.md`
  (all time enters through mockable sources; formulas cannot read the wall clock;
  frame-driven cells excluded from pixel refs unless the macro drives synthetic ticks) —
  it is the doc every test author reads, so the rule must live there, not only in the spec.
- **Phase-close:** run the §0 battery.

### Phase 6 — patch-programming port (strangler; spec §8)

**6a — `firesPerEvent` on wires.** Property + menu toggle on connection-bearing widgets
(default `false`). No engine involvement yet: legacy delivery still runs. Dark for pixels.

**6b — engine delivery behind an A/B switch.** `world.dataflowWiresEnabled` (default
`false`; model: `world.deferredSettlingEnabled` A/B, WorldWdgt ~91). When ON:
- `setTargetAndActionWithOnesPickedFromMenu` additionally declares an engine edge —
  producer widget → target widget, with the wire's `action` (+ `firesPerEvent`) riding
  the EDGE RECORD's opts and `dataflowApply` defined edge-level (its body reuses the
  existing `_fireConnection` routing verbatim, so the `_<action>Connector` lane is
  preserved). Nodes stay widgets; do NOT model sinks as separate graph NODES — closure
  traversal must flow THROUGH ring intermediates (text widgets, sliders), and it does so
  by reading the consumer widget's value after each application. Un-wiring removes the
  edge.
- `Widget.dataflowValue: -> @exportedValue()` — the cutoff/pull reader for widget nodes
  (Phase 1 node protocol): after applying an edge into a widget, the engine reads its
  value and traverses onward only if it changed.
- Controllers' update paths call `world.dataflow.markStale @` instead of
  `@_fireConnection`.
- **The echo (§1.13):** during engine application, the applied setter's legacy
  `updateTarget` tail (unconditional — it runs even on a no-change set) now calls
  `markStale` on the very node being applied. Suppress it: `markStale n` while the
  engine is applying `n` is a no-op — the engine already owns that node's downstream
  traversal. Any OTHER mid-drain marking still pools (spec §5's legitimate re-entrancy).
  Fallback if suppression proves fiddly: let the echo pool and let the next pass die on
  the equal-value cutoff — correct, but makes 2 passes the circuit norm; whichever
  ships, record it here and put the measured pass counts in Phase 7's numbers.
- `firesPerEvent` wires: `markStale` outside a drain runs the synchronous mini-pass
  scoped to that wire (spec §4).
- `bang` → `markStale @, true` (forced). `reactToTargetConnection` → mark stale+forced on
  edge creation. Nuance (verified): today `bang` fires the CACHED output WITHOUT
  recomputing (`updateTarget`'s `fireBecauseBang` path); the engine's forced marking
  recomputes then propagates — identical for pure formulas, and a side-effecting formula
  runs once more per bang. Acceptable; note it in the commit message.
- `CalculatingPatchNodeWdgt`: implement `dataflowRecompute` (pull all connected inputs,
  run the user formula); DELETE the per-input freshness gate — under the A/B OFF path keep
  legacy behavior intact (guard the changes on the switch; the class carries both paths
  during 6b only). Port the whole patch FAMILY deliberately, not just this class:
  `DiffingPatchNodeWdgt` (its `fireBecauseOneHotInputHasBeenUpdated` hot-input mode IS
  any-input-marks-stale — it collapses into the engine default),
  `RegexSubstitutionPatchNodeWdgt`, `FanoutWdgt`/`FanoutPinWdgt`.
- Widget death: `fullDestroy` of a connection-bearing widget calls
  `world.dataflow.removeAllEdgesOf @` (Phase 1 node-death API — leak + ghost recompute
  otherwise).
- **Acceptance:** with the switch ON by hand: the °C↔°F converter behaves identically
  (bidirectional, terminates — the SIX-node ring slider1→cText→calc1→fText→slider2→calc2
  walks once per event and the entry is never re-applied, §1.11); the full suite passes
  with the switch OFF (default). The end-of-cycle capstone audit must stay at 0 with the
  switch ON (the drain's apply-settle discipline, §1.14, is exactly what it polices).

**6c — default ON.** Flip the default; run the full suite; expect final-frame equality for
DAG circuits and the ring. The known reconciliation set (grep the suite for
connection-driving macros to complete it): `SystemTest_macroDegreesConverterFourWayDrive`
(THE ring acceptance), `SystemTest_macroSliderTextSliderPatchCycle`,
`SystemTest_macroSliderTextTwoWayPatchCycle`, `SystemTest_macroSlidersControlTextWidget`,
plus whatever patch-programming/fanout tests the grep surfaces. Intermediate-frame
differences may force screenshot recaptures — follow the established recapture procedure
in the tests repo; list every recaptured test in the commit message with a one-line
cause, and verify EVERY recapture on the WebKit leg (§0 recapture rule — a recapture can
bake in an error frame that Chrome then vacuously accepts). Run the full §0 phase-close
battery. Keep the switch for one release as a kill-switch.

**6d — token retirement.** Delete `_acceptsConnectionToken`, the
`connectionsCalculationToken` fields and threading (≈146 matching lines across 19 src
files — grep `connectionsCalculationToken`; §1.11), `makeNewConnectionsCalculationToken`
(WorldWdgt ~486), and the per-input token fields in patch nodes; simplify every
connection setter's signature; remove the 6b legacy guards and the A/B switch. Docs in
the same sweep: the `ControllerMixin` header and the `Widget._acceptsConnectionToken`
block comment currently TEACH token semantics — rewrite/delete them with the code; sweep
the tests-repo docs (`MACRO-PATTERNS.md`, tests-repo `CLAUDE.md`) for token vocabulary;
update `NOMENCLATURE.md`: mark the legacy connection domain rows as historical. This is
the largest mechanical sweep — the full §0 phase-close battery is mandatory.

### Phase 7 — docs closeout

(The subsystem docs were SEEDED in Phases 1/2a and grown per phase — rule 8 below. This
phase is the completeness pass, not the first write.)

- Root `CLAUDE.md`: add the dataflow/spreadsheet subsystem to the architecture section
  (two-drain sentence; pointer to spec + `src/dataflow/CLAUDE.md`); grep the repo's docs
  and CLAUDE.mds for doOneCycle station enumerations and add the drain where one is
  normative.
- Completeness pass over `src/dataflow/CLAUDE.md` and `src/spreadsheet/CLAUDE.md`: a cold
  session must be able to operate the subsystem from them alone (node protocol, drain
  contract, formula compiler behavior, presenter chain, widget-valued-cell save/load
  semantics, cell-deletion semantics).
- Record measured instrumentation (suite-wide peak pass counts — including the 6b echo
  decision's numbers — and typical drain sizes) in the spec or a small
  `docs/dataflow-measurements.md`, in the spirit of layout's measured-convergence posture.
- Tests-repo closeout: update the tests-repo `CLAUDE.md` suite description (count grew;
  a spreadsheet area exists) and verify `DETERMINISM.md` (Phase 5) still matches what
  shipped.
- Update the spec header: status → implemented; list any deviations decided during
  execution (each deviation must have been recorded in its phase's commit message).

---

## §4 Cross-cutting rules (every phase)

1. **Naming:** every new identifier passes `NOMENCLATURE.md`. In particular: no "settle",
   "invalidate", "dirty", "coalesced", "announce", "volatile" in dataflow code; "source"
   qualified.
2. **Dependency finder:** reference classes only via literal `new X` / `extends X` /
   `@augmentWith X` (§1.2). A dynamically-constructed class name breaks load order.
3. **Homepage build:** engine + spreadsheet ship (no whole-file exclusion). Test-only
   hooks guarded `if Automator?` or marked with the established exclusion comments.
4. **Layout discipline:** widget code follows wrapper+core (`_settleLayoutsAfter` /
   `*NoSettle`) and bounds-first `_reLayout`; the lint gates enforce most of it — never
   bypass with `--noSyntaxCheck`.
5. **Testing:** each behavior phase lands with its SystemTests authored in
   `../Fizzygum-tests` (full tier), following `src/macros/CLAUDE.md` + MACRO-PATTERNS
   (macros are the only authoring path), named `SystemTest_macro<CamelCase>` (§0). The
   §0 verification cadence governs which battery runs when: inner loop per commit,
   phase-close battery at 2c/4/5/6c/6d, serialization legs whenever the serialized
   surface changes, WebKit verification on every recapture. Respect
   `../Fizzygum-tests/DETERMINISM.md` — especially for Phases 4–6 (input recognition)
   and 5 (time).
6. **Commits:** conventional style (`feat(dataflow): …`, `feat(spreadsheet): …`,
   `refactor(connections): …`); each states its verification tier and updates the ledger.
7. **When reality diverges from this plan** (an API doesn't fit, a gate complains, a fact
   in §1 has drifted): stop, decide, record the deviation IN THIS PLAN (edit the relevant
   section) in the same commit — this document must stay executable for the next cold
   session.
8. **Docs are a phase deliverable, not a closeout chore:** every phase updates, in the
   same commit: the touched class headers, the subsystem `CLAUDE.md`s (seeded in 1/2a),
   `NOMENCLATURE.md` on any new term of art, `docs/serialization-duplication-reference.md`
   when the serialized surface changes (1, 2b, 4), and `../Fizzygum-tests/DETERMINISM.md`
   when a determinism rule changes (5). Phase 7 is a completeness pass over docs that
   already exist.

## §5 Risks & rollback

- **doOneCycle overhead (Phase 1):** the empty-pool early return keeps the dark engine at
  one Set-size check per cycle. Measure nothing; just keep it first in the method.
- **Formula ref-scan false positives** (e.g. `A1` inside a regex literal): strings and
  comments are stripped before scanning; regex literals are rare in formulas — accepted
  v1 limitation, documented in `src/spreadsheet/CLAUDE.md`.
- **Serialization of sheets:** derived-state rebuild on load must recommit cells in
  dependency-safe order — simplest: commit all sources with edge-declaration deferred,
  then mark ALL cells stale and let one drain compute values (order-independent by
  construction). If a saved sheet contains a `#LOOP`, the reject-at-commit check must
  tolerate re-loading it (reject again, same error value).
- **Suite recaptures (6c)** are expected and bounded; every recapture is listed,
  justified, and WebKit-verified (§0 recapture rule — a recapture can freeze an error
  frame into the references, after which the Chrome legs pass vacuously).
- **Engine-index leaks / ghost nodes:** a destroyed widget or deleted cell left in
  `@edgesFrom`/`@edgesTo` is a memory leak AND a ghost recompute. Mitigations are
  structural: `@lastValues` is a WeakMap (Phase 1), and every death path calls
  `removeAllEdgesOf` (2c cell delete, 4 socket unmount, 6b `fullDestroy` hook).
- **Widget-valued cells across save/load:** naive recommit-on-load discards restored
  widget state — Phase 4 decides the semantics and pins it with a rig fixture.
- **Rollback:** Phases 1–5 are additive (revert = delete the feature commits). 6b/6c ride
  the A/B switch (kill-switch rollback without revert). 6d is the only
  hard-to-revert sweep — hence last, and only after 6c has soaked.

## §6 Definition of done (overall)

- [ ] Ledger fully checked; every phase's verification tier recorded.
- [ ] Full-tier run green; new SystemTests exist for phases 2a–4 (and 5 if the tick hook
      was built); recaptures (if any) listed in 6c's commit and WebKit-verified.
- [ ] §0 phase-close battery green at 2c, 4, 5, 6c, 6d; serialization rig green with the
      sheet / color-cell / widget-cell fixtures and their EXPECTATIONS rows.
- [ ] `world.dataflow` drains dark-cheap (empty-pool early return first).
- [ ] Token machinery deleted (6d); `grep -rn connectionsCalculationToken src` → 0.
- [ ] In-phase docs (rule 8) landed as they went: subsystem CLAUDE.mds,
      serialization reference, DETERMINISM.md; Phase 7 completeness pass done.
- [ ] Docs closeout (Phase 7) landed; spec marked implemented with deviations.
- [ ] `NOMENCLATURE.md` consistent with the shipped names.

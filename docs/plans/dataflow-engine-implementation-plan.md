# Dataflow engine & spreadsheet — implementation plan (cold-executable)

Implements `docs/specs/dataflow-engine-spec.md` (normative design; read it FIRST) using the
vocabulary of `NOMENCLATURE.md` (normative naming; read it SECOND). This plan assumes no
other context. Its prerequisite — the coalesced-nomenclature rename
(`docs/archive/coalesced-nomenclature-rename-plan.md`) — is **executed**: the deferred-settle family
is now `*DeferredSettle` / `world.deferredSettlingEnabled`; the only surviving "coalesc"
strings in `src`/`buildSystem` are 4 references to the historical doc *filename*
`docs/tooling/coalescing-measurement.md` (legitimate; leave them).

**Read the status ledger below before doing anything: execute the FIRST phase whose box is
unchecked, then update the ledger in the same commit that completes the phase. (Exception:
the `F*` boxes under "Optional follow-ons" are NOT scheduled work — they are fleshed-out
options, and one is started only when the owner explicitly names it.)**

## Status ledger

- [x] Phase 0 — pre-flight verification
- [x] Phase 1 — engine core, dark (no callers)
- [x] Phase 2a — spreadsheet shell: window, painted grid, selection
- [x] Phase 2b — cell model, literal/CoffeeScript evaluation, editing
- [x] Phase 2c — references, recompute, errors-as-values
- [x] Phase 3 — value protocol & presenters (Color first)
- [x] Phase 4 — widget-valued cells & sockets
- [x] Phase 5 — time sources (`seconds` / `frame`)
- [x] Phase 6a — `firesPerEvent` wire property + menu toggle
- [x] Phase 6b — patch-programming port behind A/B switch (default OFF)
- [x] Phase 6c — A/B default ON, suite reconciliation
- [x] Phase 6d — token retirement
- [x] Phase 7 — docs closeout
- [x] Phase 8 — widgetise the grid (one CellWdgt per VISIBLE cell; viewport-bounded) — follow-on

**Optional follow-ons** (F1–F4 fleshed out in §3-F 2026-07-06, every anchor re-verified +
corrected 2026-07-17 at tree `61080871`; F5 fleshed out with pixel receipts 2026-07-17;
sequencing owner-ratified 2026-07-17: **F5(+F2) → F1 → F4 → F3**, perf C2 retired into F5):

- [x] F5 — headers-as-widgets + cell-owned grid chrome; the sheet paints NOTHING — **LANDED
      2026-07-17** (see the F5 section's landing log; gauntlet 11/11, revisits baseline still
      EMPTY, census green, both serialization legs green, 11-test ring recapture
      webkit-verified)
- [x] F2 — selection border + overlay editor fully into the `CellWdgt` (view
      self-containment) — executed inside F5's landing (F5 evidence B made it mandatory)
- [x] F1 — scroll: logical sheet > viewport; wheel + keyboard scroll; viewport
      materialise/recycle — **LANDED 2026-07-17** (see the F1 section's landing log; origin-0
      byte-identity held — ZERO recaptures; 3 new SystemTests dpr1+dpr2, suite 253; 3 new
      scrolled-round-trip rig rows, both serialization legs green; close gauntlet 11/11 in
      396s — dpr1/dpr2/webkit 253/253, REVISITS baseline still EMPTY, census 0/1528, refs
      1570 consistent with one serial-retry load-flake on the refs leg)
- [x] F4 — drag-and-drop desktop widgets into cells (widget-entry cells) — **LANDED
      2026-07-17** (see the F4 section's landing banner: the drag-out re-host trap, the NEW
      `wantsDetachOfChild` seam, the latent F5 cell-draggability hole closed; 2 new
      SystemTests dpr1+dpr2, suite 255; 2 new rig rows, both serialization legs green; close
      gauntlet 11/11 in 275s — dpr1/dpr2/webkit 255/255, REVISITS baseline still EMPTY,
      census 0/1528, zero recaptures of existing references)
- [ ] F3 — the "operate ➜" cell menu (value-class method introspection → formula in a nearby
      cell) — independent, any time
- [x] F6 — resizable viewport with PARTIAL EDGE CELLS (window resize shows more of the
      logical sheet) — **LANDED 2026-07-17, same day as authoring** (see the F6 section's
      landing banner: the flip is a DELETION — base Widget protocol + default spec were
      already the fill-content protocol; `_reLayout` arrange seam per the
      StretchableWidgetContainerWdgt precedent; sheet-level clip mixin; the 452×336 pin;
      the origin-clamped visible-counts landing deviation; presuite 255/255 with ZERO
      reference changes = the decision-3 hard gate; 1 new SystemTest dpr1+dpr2 with the
      exact-corner round trip byte-identical BY HASH, suite 256; 2 new rig rows; close
      gauntlet numbers in the banner)

Each phase = one or more commits, independently green and revertable. Do not start a phase
with the previous one unverified. **Phase 8 is a planned follow-on** (owner direction 2026-07-05):
the spreadsheet's END STATE is full composability — every cell is a real widget — but the
DATAFLOW arc (Phases 1–7) ships first on the current "painted chrome + sockets" rendering, then
Phase 8 refactors ONLY the rendering. See the Phase 8 section for why this is a stepping stone,
not throwaway, and the Phase 4 socket note for the decision that seeds it.

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
   `docs/architecture/serialization-duplication-reference.md`; world singletons re-bind via
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
    not hygiene. Protocol reference: `docs/architecture/serialization-duplication-reference.md`.
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
| 1 | `src/dataflow/DataflowEngine.coffee`, `src/dataflow/CLAUDE.md` | `WorldWdgt.coffee` (ctor + doOneCycle), `WellKnownObjects.coffee` (keyFor AND resolve), `buildSystem/build.py`, `docs/architecture/serialization-duplication-reference.md` (well-known row) |
| 2 | `src/spreadsheet/SpreadsheetApp.coffee`, `SpreadsheetWdgt.coffee`, `SheetModel.coffee`, `SheetCellRecord.coffee`, `SheetError.coffee`, `FormulaCompiler.coffee`, `FormulaHelpers.coffee`, icon widget, `src/spreadsheet/CLAUDE.md` | `build.py`, `WorldWdgt.coffee` (launcher), `MenusHelper.coffee` (menu entry) |
| 3 | — | `Widget.coffee` (`exportedValue`), `Color.coffee` (`cellPresenter`, `lighter`, `darker`; promote `mixed`), `SpreadsheetWdgt`/presenter chain |
| 4 | (maybe) `CellSocketWdgt.coffee` | `SpreadsheetWdgt`, `SheetCellRecord`, `SliderWdgt.coffee` (`getValue`, §1.15) |
| 5 | `src/dataflow/SecondsSource.coffee`, `FrameSource.coffee` | `FormulaCompiler` (bindings), `DataflowEngine` (subscription-count hooks), `../Fizzygum-tests/DETERMINISM.md` (time-source rule) |
| 6 | — | `ControllerMixin.coffee`, `Widget.coffee`, `CalculatingPatchNodeWdgt.coffee` + patch family (incl. `DiffingPatchNodeWdgt`, `RegexSubstitutionPatchNodeWdgt`, `FanoutWdgt`/`FanoutPinWdgt`), wire menus; later: deletion sweep of token plumbing + `NOMENCLATURE.md` (legacy rows → historical) |
| 7 | `docs/measurements/dataflow-measurements.md` (or a spec section) | root `CLAUDE.md`, spec status header, completeness pass over `src/dataflow/CLAUDE.md` + `src/spreadsheet/CLAUDE.md` (seeded in 1/2a), tests-repo `CLAUDE.md` |

Tests-repo deliverables (full tier) are listed per phase below: new `SystemTest_macro*`
suites, serialization-rig fixtures + EXPECTATIONS rows (2c/3/4), the `DETERMINISM.md`
update (5), and the 6c recapture set. (The optional follow-ons F1–F4 carry their own
touch-lists + test inventories inline in §3-F.)

---

## §3 Phases

### Phase 0 — pre-flight

1. `git pull`; run baseline verification for your tier; confirm green BEFORE any edit.
2. Re-verify §1 facts (each has a grep). If any fact has drifted, STOP, update this plan's
   §1 in its own commit, then proceed.
3. Confirm rename state: `grep -rin coalesc src buildSystem` → only
   `docs/tooling/coalescing-measurement.md` filename references (4 at last count).

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
exactly 4 `coalesc` matches in `src`, all `docs/tooling/coalescing-measurement.md` filename refs
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
  `docs/architecture/serialization-duplication-reference.md`).
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
     `_changed()`-only sinks are settle-free. Wrap each node's recompute in try/catch: on
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
`docs/architecture/serialization-duplication-reference.md`. The `DataflowEngine` class header carries
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
`world.disableTrackChanges()` … `world.maybeEnableTrackChanges()` + one `_fullChanged()`
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
- Selection: `mouseClickLeft` → cell coordinate math → repaint via `_changed()`. Keyboard
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
  `docs/architecture/serialization-duplication-reference.md`; the SHEET serializes: model + sources +
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
  of the value protocol; recorded here as not-done. Fleshed out as follow-on **F3 (§3-F)**.
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
  the mount point is the **socket**. **Decision (owner direction 2026-07-05): build a REAL
  `CellSocketWdgt` widget, not ad-hoc direct child management** — even though direct management
  might keep `_reLayout` marginally simpler now, the `CellSocketWdgt` is the SEED of Phase 8's
  per-cell `CellWdgt` (widgetise the grid). Design it so it is trivially generalisable from
  "one socket per RICH cell" to "one socket per VISIBLE cell": it holds a cell's rect, renders
  the record's scalar value OR hosts a value/presenter widget, and owns the interaction wiring.
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
  decision in `src/spreadsheet/CLAUDE.md`. **Design this as one "retain-and-remount" rule**
  (a value-widget is MODEL state, retained by the record; the view mounts/unmounts the
  instance, never destroy-and-rebuilds it): Phase 8's scroll-virtualisation reuses exactly this
  rule when a widget-valued cell leaves/re-enters the viewport, so save/load and scroll are one
  problem, not two.
- **SystemTests:** `SystemTest_macroSpreadsheetSliderCell` (macro drags the slider;
  dependent cell updates; deterministic — input events only). Extend the rig's sheet
  fixture with a slider-valued cell pinning the save/load decision (drag, save, load,
  assert the position survived — or the documented alternative); run the serialization
  legs (§0).
- **Phase-close:** run the §0 battery.

**Landed 2026-07-05 (this session) — all green.**
- **`CellSocketWdgt.coffee` NEW** — the real socket (owner decision, seed of Phase 8): a
  transparent (`@color = nil`) freefloating child at the cell rect that HOSTS the cell's
  value/presenter widget (`hostNoSettle` / `_unhostNoSettle`), wires an interactive value-widget
  (`wireValueWidget`), and is the connection target (`cellInput` → the sheet's
  `_markCellStaleFromSocketNoSettle`). Serializes `@address` + `@hostedWidget` (a ref to its child,
  so a slider's dragged position rides the tree); `_sheetWidget` + `presentedValue` transient. Both
  branch-2 presenters AND branch-1 value-widgets now mount in sockets (unified), replacing Phase 3's
  direct-child presenter maps.
- **Retain-and-remount = the phase's spine (spec §13, RECOMMENDED option taken, NOT the
  recompute-and-replace alternative).** `SpreadsheetWdgt._reconcileCellSocketNoSettle` (renamed from
  `_reconcileCellPresenterNoSettle`, now RETURNS the value to cache) RETAINS an existing hosted widget
  of the same class, discarding the freshly-constructed throwaway. This is required for the LIVE case
  (a drag marks the cell stale → recompute must not reset the widget being dragged), the SAVE/LOAD case
  (a restored slider is kept, its dragged position survives), and Phase 8 scroll — one rule. Restore
  path: `recommitAllCells` → `_reindexCellSocketsNoSettle` (rebuild address→socket index from the
  restored socket children, destroy strays) → recompute retains value-widgets / rebuilds presenters —
  replaces Phase 3's `_disposeAllCellPresentersNoSettle` sweep (which would have destroyed the widget
  state). A headless probe (13/13) verified mount / exported-ref / drag→propagation / live-retain
  (identity stable) / save-load-retain (value 77 survived) / restored-widget re-drag BEFORE the macro.
- **Exported value = `Widget.exportedValue`'s first live consumer.** `SheetCellRecord.exportedCellValue`
  (widget → `exportedValue()`, else self) is what a reference yields (`SheetModel.exportedValueAt` at
  the read site) AND what `dataflowRecompute`/`dataflowValue` return for the engine cutoff — because a
  `Widget` has no `.equals`, so an identity cutoff would stop a dragged slider from propagating.
  `SliderWdgt.getValue: -> @value` added (§1.15). `SpreadsheetWdgt.hostedWidgetAt` is the PUBLIC
  accessor (a macro's `._cellSockets` reach tripped layering gate [D] — added the public API instead).
- **Interactivity IN wired per Scenario A** (`setTargetAndActionWithOnesPickedFromMenu nil, nil, socket,
  "cellInput"`; signature verified — first two args ignored, no `_cellInputConnector` so it routes to
  the plain public `cellInput` = no settle). The wire fires once at mount (`reactToTargetConnection`),
  costing one extra pooled pass — accepted. Drag-and-DROP of desktop widgets into cells DEFERRED —
  fleshed out as follow-on **F4 (§3-F)**.
- **Serialized surface changed → both serialization legs run + green.** Rig `sheet` fixture grew F1 =
  a slider cell; new `spreadsheet.roundtrip.sockets` (2 rich cells = 2 sockets, round-trips) +
  `spreadsheet.roundtrip.sliderRetain` (drag→77, save, load, assert 77 survived) checks; old
  `colorPresenter` renamed `sockets`. Legs: 24 native + 34 SWCanvas + 7 file, all green.
- **Verification:** `fg build` 0 violations; new `SystemTest_macroSpreadsheetSliderCell` captured +
  verified dpr1 + dpr2 + eyeballed (slider mounts at 30 → drag → thumb right, B1 = 94); `fg gauntlet`
  **179 dpr1/dpr2/webkit + apps + tiernaming/settle/capstone all PASS** (webkit-verified the new test
  cross-engine); `fg homepage` BOOT OK (`SliderWdgt.getValue` ships). **NO benign inspector recapture**
  (nothing added to the base `Widget` this phase — the readers landed on `SliderWdgt`/`SheetCellRecord`).
- **v1 limitations (documented in `src/spreadsheet/CLAUDE.md`):** (a) sockets are freefloating,
  positioned at mount — a sheet that MOVES after mounting rich cells leaves them behind (shared with
  Phase-3 presenters; Phase 8's laid-out cells retire it); (b) the retain check re-constructs a
  throwaway widget per recompute to read its class — a minor cost. The interim Phase-3 presenter-
  serialization deviation is now CLEANED (sockets + reconcile-on-restore replace the sweep).

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
- Perf discipline (spec §9.7): a tick that only changes painted text = `_changed()` on the
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

**Landed 2026-07-05 (this session) — all green.**
- **`SecondsSource.coffee` / `FrameSource.coffee` NEW** — the two time sources (spec §6): plain
  non-Widget, non-serialized world singletons the engine builds LAZILY (`world.dataflow.secondsSource()`
  / `.frameSource()`) on the first `seconds`/`frame` subscription. Each is a PURE dataflow source
  (`dataflowValue`, no `dataflowRecompute` → the drain treats it as always-changed and pulls its value).
  `SecondsSource` = `fps:1` + `synchronisedStepping` (the trap-free stepping mode — the non-synchronised
  branch leaves a mid-run member's `lastTime` uninitialised → NaN → never fires); `FrameSource` = `fps:0`
  (the every-cycle branch). `step()` does exactly one thing: `markStale` SELF.
- **Subscriber-count lifecycle = the phase's novel machinery.** `DataflowEngine.addEdge`/`removeEdgesInto`
  now call NEW `_notifySubscriberCount(producer)` → `producer.subscriberCountChanged?(outEdgeCount)`. A
  time source registers in `world.steppingWdgts` on the `0→positive` crossing and deregisters on
  `positive→0`, so the per-second/per-frame tick EXISTS ONLY WHILE a cell depends on it (entering the first
  `seconds` cell makes the ticker exist; clearing the last one makes it cease — spec §6). `removeAllEdgesOf`
  routes a dying node's incoming edges through `removeEdgesInto`, so deleting a `seconds` cell decrements
  its source. A plain producer (a cell) has no `subscriberCountChanged` = a cheap no-op.
- **Bindings wired.** `FormulaCompiler.@timeBindingNames = ["seconds","frame"]`; `scanBoundNames`
  boundary-guards them (so `secondsElapsed`/`foo.frame` don't match); `commit` declares the edge
  `secondsSource()`/`frameSource()` → cell (NO cycle check — a source has no inputs). `SheetCellRecord.
  _resolveBoundName` resolves each to the source's current `dataflowValue()` — the Phase-2c stub retired.
- **Pulled SHAPE decided = a NUMBER** (source headers + `src/spreadsheet/CLAUDE.md`): `seconds` = epoch
  seconds `Math.floor(WorldWdgt.dateOfCurrentCycleStart.getTime()/1000)` (verified live throughout the
  drain, nil'd only at cycle end; `dateOfPreviousCycleStart` fallback, never a fresh `new Date`); `frame` =
  `WorldWdgt.frameCount` (verified incremented at cycle END → a `frame` formula sees the count of cycles
  COMPLETED before this one). A scalar so formula arithmetic and the engine's `_valuesEqual` cutoff both
  behave — two cycles in the same wall second pull the same integer, so the cutoff stops propagation until
  the second ticks. Formulas NEVER read the wall clock (spec §6/§10).
- **Perf (spec §9.7) — ticks repaint, never re-layout.** Asserted by reading the path: a tick recompute
  goes `SheetCellRecord._cacheValue` → `_changed()` + the socket reconcile; a scalar takes the text branch
  (no widget, no `_invalidateLayout`). Cost is linear in the subgraph (`lastDrainRecomputeCount`). A `frame`
  cell defeats the drain's empty-pool early return every cycle BY DESIGN (it IS per-frame).
- **Serialization: surface UNCHANGED, verified.** `steppingWdgts` is serialized PER-WIDGET (a marker on
  each serialized widget — `Serializer.coffee:262` / `Deserializer.coffee:113`); a non-widget source
  reached only via the `$wk` engine is never encoded, and on restore `recommitAllCells` re-declares the
  `seconds`/`frame` edge → re-subscribes. Both legs green (24 native + 34 SWCanvas + 7 file); NO rig change
  — a `seconds` cell's value is wall-clock, so it must not join the value-equality rig.
- **Verification:** `fg build` 0 violations; a headless object-graph probe (23/23: binding = integer epoch
  / frame counter, edges, subscriber count 1→2→1→0 with `steppingWdgts` tracking, deregister-at-0,
  singleton reuse, forced-tick propagation) verified the graph BEFORE the macro; new
  `SystemTest_macroSpreadsheetSecondsCell` (displays time COMPARISONS — `seconds > 1e9`/`frame >= 0`, always
  true — so the reference is byte-exact while the instant is not; numeric + subscriber-lifecycle facts proven
  by `assertValuesEqual`) captured + verified dpr1 + dpr2 + webkit-verified + eyeballed (a row of `true`);
  `fg gauntlet` **180 dpr1/dpr2/webkit + apps + tiernaming/settle/capstone all PASS** (capstone flaked ONCE
  as a 22-min dropped-shard hang at `--shards=6` — the memory-noted capstone churn flake; a fresh isolated
  capstone re-run = 180/180, careless=0); `fg homepage` BOOT OK (the sources + engine ship in homepage).
  **NO inspector recapture** (the sources are plain classes and the readers landed on the engine/compiler/
  cell — nothing added to the base `Widget`).
- **Testing rule landed (same commit):** `../Fizzygum-tests/DETERMINISM.md` §3d — all time enters through
  mockable sources; a formula must not read the wall clock; frame/second-driven cells are excluded from
  pixel refs unless the macro drives ticks (display an invariant comparison or inject a fixed value).

### Phase 6 — patch-programming port (strangler; spec §8)

**6a — `firesPerEvent` on wires.** Property + menu toggle on connection-bearing widgets
(default `false`). No engine involvement yet: legacy delivery still runs. Dark for pixels.

**Landed 2026-07-05 (this session) — all green.** Modified `src/mixins/ControllerMixin.coffee`
(the single connection-bearing base — every wiring widget `@augmentWith`s it) + 8 controller menus.
- **`ControllerMixin` gains three members.** `firesPerEvent: false` (per-wire delivery policy —
  `false` = POOLED: one drain per cycle using final values; `true` = PER-EVENT: a synchronous
  mini-pass inside each event, spec §4); `toggleFiresPerEvent` (a plain boolean flip — no layout, no
  tree mutation, hence no settle, so `check-layering`-clean); and the shared
  `addFiresPerEventMenuEntry(menu)` helper.
- **`firesPerEvent` is a PROTOTYPE default, not a per-instance assignment** (`addInstanceProperties`
  sets `@::firesPerEvent = false`). The serializer walks `for own` (`Serializer.coffee:245`), so an
  untoggled wire carries NO own `firesPerEvent` and serializes byte-for-byte as before — the same
  own-only-when-set idiom as `@target`/`@action` (SliderWdgt ~13). Only a user who TOGGLES a wire
  writes an own property that then serializes (correct: a saved per-event wire keeps its policy).
- **The toggle rides the existing connection menu.** The 8 controllers that render "connect to ➜" /
  "set target" (`SliderWdgt`, `StringWdgt`, `SimpleTextWdgt`, `PaletteWdgt`, and the four patch
  nodes `CalculatingPatchNodeWdgt` / `DiffingPatchNodeWdgt` / `RegexSubstitutionPatchNodeWdgt` /
  `FanoutPinWdgt`) each call `@addFiresPerEventMenuEntry menu` right after that block — one shared
  helper, no duplicated toggle logic. Shown ONLY once a target is wired (`return unless @target?` —
  `firesPerEvent` is a property OF a wire); a leading ✓ reflects state via `String::tick` (matched in
  tests by the "fires per event" substring).
- **DARK, like Phase 1: nothing READS the flag yet.** Legacy `_fireConnection` delivery still runs
  unchanged. Phase 6b's engine delivery (behind `world.dataflowWiresEnabled`) reads it when it
  declares the edge, letting the policy ride the edge record's opts. NOMENCLATURE already had the
  terms (`firesPerEvent` line 64, `fire` line 99); `src/dataflow/CLAUDE.md` grew a "Connections
  client — patch-programming migration" section.
- **11 BENIGN inspector recaptures (revised the "no new pixel refs" expectation).** The 3 new members
  (plus the two `_class_injected_in` companions `addInstanceProperties` adds for the two methods)
  appear as new rows in every CONTROLLER's inspected property list. `StringWdgt` is the canonical
  inspected fixture, so every inspector test that inspects a controller shifts by ~5 rows — a member-
  list growth (the byte-identical-not-sacred case): `macroDuplicatedInspectorsCloseIndependently`,
  `macroInspectorRejectsDrops`, `macroInspectorResizingOKEvenWhenTakenApart`,
  `macroInspectorScrollbarUnplugged`, `macroMovingSlidersSidewaysDoesntCauseContentToMoveSideways`,
  `macroMultilineTextInputScrollsWell`, `macroPickingUpPartsFromInspector`,
  `macroResizingPristineInspector`, `macroSimpleDocumentHandlesOldInspector`,
  `macroWrappingTextFieldResizesOK` recaptured (pixel-only; verified deterministic + eyeballed).
  **One test, `macroAddEditSaveRenameRemoveProperty`, also needed a test-logic fix** (NOT a source
  change): its `selectInspectorRow` scrolls the vBar by a fraction of `elements.length`, so the +5
  members landed the target row at the viewport clip edge and the centre click silently missed —
  cascading to a rename-with-no-selection crash. Made the select robust (VERIFY `list.selected` took;
  retry with a larger top margin — tolerant of any list length); the add→save→rename→remove round-trip
  completes and was eyeballed correct at dpr1+dpr2.
- **Verification:** `fg build` 0 violations (`toggleFiresPerEvent` seen via the `addMenuItem`
  string-dispatch, `addFiresPerEventMenuEntry` via its 8 call sites — dead-method gate satisfied by
  real use, NOT the allowlist); new `SystemTest_macroConnectionFiresPerEventToggle` (wires two sliders,
  drives the REAL menu toggle — right-clicking the LOWER track at [0.5,0.85] because at value 50 the
  thumb covers the centre — and asserts `firesPerEvent` false→true→false by value; 3/3 PASS) captured +
  verified dpr1 + dpr2 + eyeballed (two inert sliders — the toggle is pixel-dark); the 11 inspector
  recaptures above; `fg gauntlet` **181 dpr1/dpr2/webkit + apps + tiernaming/settle/capstone all PASS**;
  both serialization legs green (surface UNCHANGED — no fixture toggles a wire); `fg homepage` BOOT OK.

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

**Landed 2026-07-05 (this session) — all green.** The patch-programming circuits are now the engine's
SECOND client, behind `world.dataflowWiresEnabled` (default OFF). 12 source files; the switch-OFF path is
byte-identical (every change is gated), so the whole suite runs legacy and stays green while 6b lands.
- **The switch** — `WorldWdgt.dataflowWiresEnabled: false` (PROTOTYPE default beside `deferredSettlingEnabled`,
  ~92; own-only-when-set → serialized surface unchanged, no fixture ever writes it).
- **The core is EDGE application in the engine, not a per-node hook.** When ON, `_processNode` (guarded)
  first calls NEW `_applyIncomingWireEdges`: for each incoming wire edge whose producer CHANGED this pass, it
  pushes `pullValue(producer)` onto the consumer via the wire's action, routed through the target's
  `_<action>Connector` lane if present else the public action (NEW `_applyWireValue`/`_wireEdgeRecord` — the
  SAME routing `_fireConnection` used, so the non-settling connector lane §1.5/§1.14 is preserved and joins the
  pass settle). Sheet reference edges carry no `action` and are skipped → the spreadsheet client is untouched.
  A widget SINK (a node with incoming edges) then takes an equal-value CUTOFF on its pulled value (NEW else-branch,
  switch-gated); a pure source (time source / seed, no incoming edges) stays always-changed = pre-6b behaviour.
- **The echo (§1.13) is SUPPRESSED, not pooled** → a driven circuit is ONE pass. `@_applyingNode` (set around
  `_processNode`) names the node being applied into; `markStale @` on that node while applying it is dropped
  (gated on the switch, so switch-OFF `markStale` is byte-identical). Measured: the 6-node °C↔°F ring drains in
  **1 pass / 2 recomputes** per event (probe below), both drag directions.
- **`Widget.dataflowValue: -> @exportedValue()`** (the pull/cutoff reader). Overridden where exportedValue
  wouldn't carry the fired value: `CalculatingPatchNodeWdgt`/`DiffingPatchNodeWdgt`/`RegexSubstitutionPatchNodeWdgt`
  → `@output`; `PaletteWdgt` → `@choice`; `FanoutWdgt`/`FanoutPinWdgt` → `@inputValue`.
- **ControllerMixin** — `_fireConnection` switch-gates to `world.dataflow.markStale @` (a wire carries NO value;
  the drain pulls; every controller's `updateTarget` = `@_fireConnection <val>` becomes a markStale with NO
  per-controller change). `setTargetAndActionWithOnesPickedFromMenu` additionally declares the edge
  (`removeOutgoingEdgesOf @` — NEW inverse of removeEdgesInto, for re-wiring — then `addEdge @, @target,
  {action, firesPerEvent}`), then the UNCHANGED `@reactToTargetConnection?()` drives each controller's exact
  on-connect fire via the gated `_fireConnection`.
- **Patch family** (behind the switch, both paths carried during 6b): the 3 calc-style nodes switch-gate
  `updateTarget → markStale @, (fireBecauseBang is true)` (DELETES the `allConnectedInputsAreFresh` freshness
  gate = the §8 deadlock) + gain `dataflowRecompute: -> @recalculateOutput(); @output`. `setInput1..4` are
  UNCHANGED (no-token `_acceptsConnectionToken` mints+accepts; stores `@inputN`; the `updateTarget→markStale`
  is echo-suppressed while the engine applies the input). `bang` is force-fire: patch nodes free (updateTarget's
  `fireBecauseBang`), plain controllers (Slider/SimpleText/Palette/FanoutPin) switch-gate `bang → markStale
  @, true`. FanoutWdgt (homepage-excluded) re-fans to its pins as before; the pins carry the out-edges.
- **Node death** — `Widget._destroyNoSettle` → `world.dataflow?.removeAllEdgesOf @` (switch-gated), so a
  destroyed connection-bearing widget drops its edges (leak + ghost recompute otherwise). Cells already did this.
- **DEVIATIONS (rule 7).** (a) The `firesPerEvent` PER-EVENT synchronous mini-pass is DEFERRED: the flag rides
  the edge record (`addEdge` opts, so it IS read/plumbed) but delivery POOLS for now — the two lanes are
  screen-indistinguishable (§4), no test exercises per-event DELIVERY (6a only asserts the flag flips), and a
  truly synchronous scoped mini-pass fights the drain's per-pass settle-open (spec §13 open: per-event
  downstream scoping). Recorded in `markStale`'s header. (b) `reactToTargetConnection` is LEFT UNCHANGED (plan
  said forced-on-creation); instead the gated `_fireConnection` makes it a NON-forced markStale, which PRESERVES
  each controller's exact on-connect semantics — PaletteWdgt's empty override fires nothing on connect (a blanket
  forced mark would spuriously fire it), Example3DPlot recomputes its plot — and non-forced still fires the ring
  init (initial values differ). Both deviations are strictly safer and unexercised-otherwise.
- **Acceptance verified (headless probes, throwaway):** the °C↔°F ring built with the switch ON is FRAME-IDENTICAL
  to the same ring switch-OFF (legacy) at every observed frame, BOTH drag directions (drag °C entry to 70 → 158°F
  ring; drag °F entry to 212 → 100°C ring); 1 pass; the entry node is never re-applied; switch-OFF shows the
  engine drain empty (pass 0) = truly legacy. A second probe with `auditUndeclaredEndOfCycle` ON drove the ring
  both ways + a rounding-plateau drag with **0 UNDECLARED-EOC** (capstone stays 0 with the switch ON, §1.14).
- **11 → 2 BENIGN inspector recaptures.** `Widget.dataflowValue` adds one inherited-member row (like Phase 3's
  `exportedValue`) → `macroDuplicatedInspectorDrivesCopiedTargetOnly` (its inherited-member list + thumb geometry
  shift, behaviour verified unchanged — left rect still fades to 0.25, right solid). `macroInspectorResizingOK
  EvenWhenTakenApart` renders `ControllerMixin._fireConnection`'s SOURCE in a method-browser frame, which the 6b
  edit changed → recaptured. Both eyeballed (proper inspectors, no crash) + webkit-verified via the gauntlet.
  [[byte-identical-not-sacred-for-benign-inspector-recapture]]. NO code contortion.
- **Verification:** `fg build` 0 violations (no new dead methods — `dataflowValue`/`dataflowRecompute`/
  `removeOutgoingEdgesOf` all have live callers; the switch is a property); `fg gauntlet` dpr1/dpr2/webkit 181 +
  apps + tiernaming/settle/capstone all PASS after the 2 recaptures; both serialization legs green (surface
  UNCHANGED — switch never set, no wire toggled); `fg homepage` BOOT OK (ControllerMixin + Calculating patch node
  + sliders ship; Diffing/Regex/Fanout are homepage-excluded).

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

**Landed 2026-07-06 (this session) — all green.** The A/B default is flipped ON
(`WorldWdgt.dataflowWiresEnabled: true`, ~102), so the whole suite runs ENGINE delivery.
Flipping it exposed that 6b declared the edge ONLY for wires made through the connect-to-➜
MENU; two classes of wire that bypass the menu broke, so 6c is **flip + two real engine-path
fixes + benign recaptures**, not the "flip + recapture" scoped above (deviation, rule 7).
- **Fix 1 — direct-assignment wires had no edge (`ensureWireEdge`).** A scrollbar
  (`ScrollPanelWdgt` `@hBar`/`@vBar`) and the prompt slider set `@target`/`@action` DIRECTLY,
  never through `setTargetAndActionWithOnesPickedFromMenu` (the ONLY 6b `addEdge` site), so
  under the switch they `markStale`d a producer with NO out-edge and the drain delivered
  nothing — **scroll silently broke** (12 tests, byte-identical dpr1/dpr2/webkit = a behavioural
  break, not a frame shift). Fix: new idempotent `DataflowEngine.ensureWireEdge` — the TOTAL
  realisation of spec §8 "edges DERIVE from `@target`/`@action`" — called BOTH eagerly
  (`setTargetAndActionWith…`) AND lazily (`ControllerMixin._fireConnection`), so every wire
  declares its edge however established; no-op mid-drain (`@_recalculatingDataflow`) so it never
  mutates the index the drain walks; on a mismatch it drops the single old out-edge and
  re-declares. `adjustContentsBasedOnHBar` is settle-safe (bare `_applyMoveTo` +
  `_positionAndResizeChildren`), so engine-delivered scroll is FRAME-IDENTICAL to legacy — **9
  scrollbar/inspector-scroll tests restored byte-identical, no recapture** (final-frame equality).
- **Fix 2 — the prompt slider's interactive action wasn't drain-safe (the `_*NoSettle`
  lattice).** `PromptWdgt`'s slider action ends in `text.edit()`; `edit()`/`stopEditing` are
  public/self-settling and a mid-flush call throws the flow-rule (`Widget:824`, documented at
  `StringWdgt:1393`), so under the engine it ran inside the drain flush → 2 tests threw. Fix
  (owner-directed = the standard NoSettle lattice, NOT `firesPerEvent`, NOT off-the-wire): keep
  the slider a normal engine wire, make its action drain-safe via a connector lane that JOINS the
  drain settle + NoSettle cores. `WorldWdgt`: `edit` + new `_editNoSettle` share ONE body via a
  teardown/add STRATEGY THUNK `_editTearingAndAddingCaretWith` (the `_stopEditingTearingCaretDownWith`
  pattern) — `edit` keeps its EXACT self-settling behaviour (public `add`/`fullDestroy`); `_editNoSettle`
  routes it through `_addNoSettle`/`_fullDestroyNoSettle`. `StringWdgt`: new `_editNoSettle` sibling.
  `PromptWdgt`: `reactToSliderAction` RENAMED → `takeSliderValue` (the `reactTo*` prefix is reserved
  for tree-notification hooks, layering rule [L]) as a canonical trio `takeSliderValue` (public
  `@_settleLayoutsAfter` wrap) + `_takeSliderValueNoSettle` (core: `_setTextNoSettle` +
  `text._editNoSettle`) + `_takeSliderValueConnector` (`@_settleLayoutsAfterOrJoinEnclosingPass` → same
  core; computed-dispatch → dead-method-allowlisted like `_setFontSizeConnector`). **`SliderWdgt`
  UNTOUCHED.** BoxTransparencyAndColorChanging + PopoverStaysOpenWhenSliderDraggedOut pass with
  legacy-identical frames.
- **11 BENIGN inspector recaptures.** `_editNoSettle` on the heavily-inspected `StringWdgt` adds one
  `methods:` row → every test inspecting a text widget's member list shifts (confirmed benign by 3
  frame dumps — proper Object Inspectors, `_editNoSettle` the only new row, no crash):
  AddEditSaveRenameRemoveProperty, DuplicatedInspectorsCloseIndependently, InspectorRejectsDrops,
  InspectorResizingOKEvenWhenTakenApart (also re-renders `_fireConnection`'s edited source),
  InspectorScrollbarUnplugged, MovingSlidersSidewaysDoesntCauseContentToMoveSideways,
  MultilineTextInputScrollsWell, PickingUpPartsFromInspector, ResizingPristineInspector,
  SimpleDocumentHandlesOldInspector, WrappingTextFieldResizesOK. NO code contortion (calling
  `world._editNoSettle` directly to dodge them was rejected: it drops `edit()`'s fit→inline /
  overflow→popup dispatch).
- **Verification:** `fg build` 0 violations; `fg gauntlet` dpr1/dpr2/webkit **181/0** + apps +
  tiernaming/settle/**capstone (careless pushes=0)** all PASS (the whole suite runs engine delivery,
  the drain's apply-settle discipline stays clean §1.14); `fg homepage` BOOT OK; both serialization
  legs green (24 native + 34 SWCanvas + 7 file; surface UNCHANGED — the switch is a prototype default,
  no fixture toggles a wire). Fizzygum 7 files (WorldWdgt, ControllerMixin, DataflowEngine, StringWdgt,
  PromptWdgt, StringFieldWdgt comment, dead-method-allowlist); Fizzygum-tests 11 benign recaptures.

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

**Landed 2026-07-06 (this session) — all green, behaviour-invariant.** The token machinery and the A/B
switch are DELETED; engine delivery is the ONLY path. `rg -n connectionsCalculationToken src` → 0,
`rg -n dataflowWiresEnabled src` → 0. (25 `.coffee` + 2 docs; the sweep was ~148 matching lines, not the
plan's estimated ~146 across 19 files — the true count was 21 files.)
- **Deleted:** `Widget._acceptsConnectionToken` + the `Widget.connectionsCalculationToken: 0` prototype
  default; `WorldWdgt.makeNewConnectionsCalculationToken` + `lastUsedConnectionsCalculationToken`; the per-input
  `input1..4connectionsCalculationToken` fields on the calc/diff/regex nodes; the trailing
  `(connectionsCalculationToken, superCall)` args on EVERY connection setter (Widget setColor/setBackgroundColor,
  StringWdgt setText/_setTextConnector, SliderWdgt setValue/bang, the patch nodes' setInput1..4/bang, Fanout/
  FanoutPin setInput, Example3DPlot setParameter, Panel/ScrollPanel/the two stainer mixins/GlassBoxTop/
  WidgetHolder setColor, CellSocket cellInput) + the token args their super/child calls threaded + the vestigial
  trailing nils at the CaretWdgt/SliderWdgt call sites.
- **Switch removed:** `world.dataflowWiresEnabled` + every `if world.dataflowWiresEnabled` branch.
  `_fireConnection` keeps only the engine body (`ensureWireEdge` + `markStale @`); each patch node's
  `updateTarget` keeps only `markStale` and DROPS the whole legacy `allConnectedInputsAreFresh` FRESHNESS GATE
  (the spec-§8 two-independent-inputs deadlock) with its per-input token threading and the collapsed Diffing
  "hot input" mode; `markStale`'s echo-suppression, `_applyIncomingWireEdges`, `_processNode`'s sink cutoff, and
  `Widget._destroyNoSettle`'s edge-drop lose their switch guards.
- **Why behaviour-invariant (VERIFIED, not assumed):** with the switch ON since 6c, the ONLY site threading a
  stored token into a setter was `_fireConnection`'s legacy tail — dead behind the ON-branch's early return. So
  every live setter call already passed `connectionsCalculationToken = undefined`, and `_acceptsConnectionToken
  (undefined,…)` could never reject (the `:0` prototype default made undefined ≠ stored, thereafter ≠ any minted
  number) — it always minted-and-accepted. Deleting it ⇒ every setter runs unconditionally = the same. The
  engine's visit-once + equal-value cutoff terminate a cascade (spec §8). The stainer mixins' internal colour
  cascade was already token-free in EFFECT (direct calls thread undefined, so each hop minted its OWN token — no
  shared token ever broke a cycle; the equal-value cutoff + the tree's acyclicity are what terminate it).
- **Screenshots: ONLY 2 BENIGN inspector recaptures** (the 6c class — a deleted inspected member / an edited
  rendered method source, NOT a delivery change; this REFINES the bullet's "expect NO pixel changes / a recapture
  = a BUG", which holds for the DELIVERY path, not for inspector member/source render):
  `macroDuplicatedInspectorDrivesCopiedTargetOnly` (the inherited-props view lost the `_acceptsConnectionToken`
  row — the copied target is still driven to a DISTINCT colour/alpha 0.25 vs 0.6, frame-dump confirmed) +
  `macroInspectorResizingOKEvenWhenTakenApart` (re-renders `_fireConnection`'s now-detokenized source). NO
  delivery frame changed. Both dpr1+dpr2 recaptured, frame-dump eyeballed, WebKit-verified by the gauntlet.
- **Docs swept:** `NOMENCLATURE.md` (token/cascade rows RETIRED, `_fireConnection`/wire/target/action rows
  clarified as surviving); `MACRO-PATTERNS.md` (the 2-node slider↔text loop terminates by the engine's
  visit-once, not a re-seen token); `src/dataflow/CLAUDE.md` (a 6d bullet records the end-state); `ControllerMixin`
  `_fireConnection` header (the `_<action>Connector` routing lives in the engine's `_applyWireValue` now); this
  ledger + the §6 checkbox. Tests-repo docs carried NO token vocabulary (verified) → no change there.
- **Verification:** `fg build` 0 violations (dead-methods 0 new — no method orphaned by the deletion); `fg
  gauntlet` dpr1/dpr2/webkit **181/0** + apps + tiernaming/settle/**capstone (careless pushes=0)** all PASS; `fg
  homepage` BOOT OK; both serialization legs green (24 native + 34 SWCanvas + 7 file — surface UNCHANGED, the
  round-trip is behavioural). Fizzygum 27 files; Fizzygum-tests 2 benign recaptures.

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
  `docs/measurements/dataflow-measurements.md`, in the spirit of layout's measured-convergence posture.
- Tests-repo closeout: update the tests-repo `CLAUDE.md` suite description (count grew;
  a spreadsheet area exists) and verify `DETERMINISM.md` (Phase 5) still matches what
  shipped.
- Update the spec header: status → implemented; list any deviations decided during
  execution (each deviation must have been recorded in its phase's commit message).

**Landed 2026-07-06 (this session) — DOCS ONLY, the ARC's completion pass. THE DATAFLOW ARC (Phases 0–7)
IS COMPLETE.**
- **Spec** (`docs/specs/dataflow-engine-spec.md`): header → **status IMPLEMENTED** + a full DEVIATIONS list
  (2a direct-paint/fixed-window · 2b buffer-overlay-editor-no-caret · 3 value-class algebra · 4 CellSocket +
  retain-and-remount · 5 time sources = NUMBERs · 6a firesPerEvent DARK · 6b engine-delivery-behind-switch +
  echo-suppression · 6c ensureWireEdge + edit-NoSettle lattice · 6d token/switch deletion · **STILL-DEFERRED**
  firesPerEvent per-event mini-pass). §8 "Tokens retire last" got a LANDED note (the 3-step strangler = Phase 1
  / 6a–6c / 6d).
- **Root `Fizzygum/CLAUDE.md`**: a new Architecture bullet — the **TWO-DRAIN** station sentence
  (`recalculateDataflow` [values] between `runChildrensStepFunction` and `recalculateLayouts` [geometry];
  one-way coupling) + pointers to spec / `src/dataflow` / `src/spreadsheet` / measurements. Suite count 160→181.
  (The only OTHER `doOneCycle` station enumeration is `src/dataflow/CLAUDE.md`, already correct; `src/macros/
  CLAUDE.md`'s mention is the macro-pump context, not a normative station list.)
- **NEW `docs/measurements/dataflow-measurements.md`** — MEASURED drain convergence (fresh, `--speed=fastest` dpr1, a
  `PRELUDE_JS` probe on `recalculateDataflow`): **typical 1 pass** (every driven ring, DAG circuit, reference
  chain, presenter, time cell); **peak 2** (`macroSpreadsheetSliderCell` — a widget-VALUED cell = sink-onto-source,
  exactly the plan's §1 prediction); recomputes/drain 1–4; bound = `dataflowPassesSanityLimit` 1000. Records the
  three live counters + the re-measure recipe.
- **Completeness pass**: `src/dataflow/CLAUDE.md` — fixed the stale "firesPerEvent per-event LANE lands in Phase
  6b" (it's still DEFERRED) + the "engine is dark (Phase 1)" Verifying note (no longer dark). `src/spreadsheet/
  CLAUDE.md` reviewed cold-operable, no edit. **Tests-repo**: `CLAUDE.md` suite description 160→181 + a spreadsheet
  /dataflow area note; `DETERMINISM.md` verified (its §3d dataflow-time-sources section already matches shipped).
- **Verification:** `fg build` 0 violations (this phase edited NO `.coffee` — docs only). No §0 battery, no
  recaptures (nothing rendered changed). Fizzygum docs-only files; Fizzygum-tests `CLAUDE.md` only.
- **Follow-on:** Phase 8 (below) remains the deliberately-separate PLANNED end-state.

### Phase 8 — widgetise the grid (one CellWdgt per VISIBLE cell) — planned follow-on

**Goal (owner direction 2026-07-05):** the spreadsheet's end state is full Fizzygum
composability — every cell the user sees is a REAL widget (inspectable, live-editable,
drag-target), not painted chrome. This phase refactors ONLY the rendering/interaction layer of
the sheet; it is scheduled AFTER the dataflow arc (1–7) ships and is fully tested, so it runs
against a green suite as a safety net.

**Why this is a stepping stone, not a rewrite.** The switch touches only the VIEW. Everything
below it is unchanged: the dataflow engine, `SheetModel`/`SheetCellRecord` (the model + node
protocol), `FormulaCompiler`, `SheetError`/`FormulaHelpers`, the value protocol
(`exportedValue`, `Color.cellPresenter`, classify→present *logic*), and all serialization /
recommit-on-load. The dataflow layer operates on RECORDS, never widgets, so correctness is
independent of what is materialised (see below). Concretely, what changes: `SpreadsheetWdgt`'s
custom paint (`_paintGrid`), the centralized hit-test (`_cellAtLocal`), and the single overlay
editor are replaced by a grid of `CellWdgt`s (each = the Phase-4 `CellSocketWdgt` generalised to
every visible cell) in a table/stack layout; `SheetCellRecord` stays the model/node and the
`CellWdgt` becomes its view (Phase-3's push-reconcile inverts to the CellWdgt PULLING from its
record on materialise + on change-while-visible — standard MVC).

**Materialise the VIEWPORT, not the model (the key insight — dissolves the "no widget
virtualisation" objection the spec raised).** "Widget per cell" ≠ "materialise every cell":
- The MODEL (`SheetModel`, sparse) covers the whole sheet; **widgets exist only for the cells
  currently ON SCREEN.** So live-widget count is bounded by the viewport, never by sheet size.
- An OFF-screen cell is still a live dataflow node: the drain recomputes its `record.value`
  with no widget present. Scrolling it IN materialises a `CellWdgt` that READS the current
  value (instantly correct, no catch-up); scrolling OUT recycles the widget; the
  record/node/edges persist untouched.
- **For v1 this is FREE:** the viewport is fixed and small (the whole 6×14 grid is on screen),
  so "visible set" = "all cells" and there is NO recycle-on-scroll logic to write yet — you
  materialise the fixed grid once. The materialise/recycle-on-scroll machinery is purely
  additive, landing with scroll + large models (and it is the standard bounded-viewport trick,
  not open-ended virtualisation).

**The one subtlety — widget-VALUED cells hold state.** Distinguish the CellWdgt (the cell's
VIEW — recyclable, materialise/destroy freely) from a widget that IS a cell's value (a user's
`new SliderWdgt` — its position is MODEL state). A value-widget must be RETAINED by the record
and unmounted/remounted as its cell leaves/re-enters the viewport — never destroy-and-rebuilt.
This is the SAME retain-and-remount rule Phase 4 defines for save/load (spec §13), so the two
share one mechanism.

**Scope / cost:** a rendering + interaction refactor. Behavioural SystemTest assertions (values,
recompute counts, reference propagation) carry over unchanged; the grid's PIXELS change (widget
backgrounds/borders/spacing), so most spreadsheet screenshots recapture — routine, webkit-verified,
listed in the commit. Scroll + a real grid layout (the deferred `ScrollPanelWdgt`, 2a) may land
here or in a sub-phase — fleshed out as follow-on **F1 (§3-F)**. Update `src/spreadsheet/CLAUDE.md`
(the design north star flips from "painted chrome, widgetized contents" to "widgetized viewport
over a sparse model") and root `CLAUDE.md`. Full §0 phase-close battery.

**Landed** ✅ (committed Fizzygum + tests lockstep — and long since pushed; the "NOT pushed"
this box originally recorded was its as-landed state. SHAs in the memory note + git log,
this plan edit riding the Fizzygum commit). NEW `CellWdgt.coffee`
= the Phase-4 `CellSocketWdgt` RENAMED + GENERALISED to every visible cell: it keeps the host/wire/
`cellInput` two-way boundary and ADDS scalar-text paint (branch 3, `showScalarNoSettle` +
`paintIntoAreaOrBlitFromBackBuffer` at the same cell-local offsets the sheet's old value loop used) +
the 2px host inset (moved off the sheet). `SpreadsheetWdgt`: `_buildGridNoSettle` materialises the fixed
6×14 grid in the constructor (freefloating + absolute from `@position()` → float-follows the sheet; the
DegreesConverterApp orphan-construction idiom); the value-paint loop is DELETED (`_paintGrid` paints only
chrome now); `_reconcileCellSocketNoSettle`→`_reconcileCellNoSettle` routes into the always-present cell
(no create/dispose dance); `_cellSockets`→`_cells`, `_reindexCellSocketsNoSettle`→`_reindexCellsNoSettle`
(adopts restored/copied cells; calls the now-idempotent `_buildGridNoSettle` to fill any gap),
`_markCellStaleFromSocketNoSettle`→`_markCellStaleFromHostedWidgetNoSettle`; NEW `_isCellBeingEdited`
(the editing cell suppresses its own text so the overlay editor is the sole thing shown). **Deserialize/
duplicate SKIP the constructor (`Object.create`), so the snapshot's cells ride the tree and are adopted —
never a double grid.** `SheetModel.colRowFor` (the old value loop's only caller) → dead-method-allowlisted
as symmetric address-algebra API (inverse of `addressFor`). **Scope = data cells only** (owner-confirmed
2026-07-06); headers/gridlines/selection stay PAINTED chrome; selection + the overlay editor stay
sheet-driven (clicks on a cell escalate to the sheet's `mouseClickLeft`). **DEVIATION from the "expect
recaptures" plan: BYTE-IDENTICAL** — preserving the exact paint offsets + host inset made the widgetised
grid render pixel-for-pixel as the painted grid, so the WHOLE suite (dpr1/dpr2/webkit **181/0**) + both
serialization legs stayed green with ZERO reference changes. The architecture changed; the pixels did
not. Serialization rig's `spreadsheet.roundtrip.sockets`→`.grid` now witnesses the full grid (84 cells ==
children, both ways; D1/F1 host, A1 doesn't). Moving selection-border + the editor FULLY into the
`CellWdgt` (my earlier 8.2/8.3) is a deliberate OPTIONAL follow-on — it would force recaptures for
marginal gain, so v1 stops at the byte-identical widgetisation. Gauntlet dpr1/dpr2/webkit 181/0 + apps +
tiernaming/settle/capstone (careless=0); `fg homepage` BOOT OK; serialization same-page + file legs green.
No new SystemTest (byte-identical, no new user-facing interaction; the rig's `grid` check + the existing
SliderCell/ColorCell/Duplicate tests witness the widgetisation). The deferred follow-ons named
here are now fleshed out in §3-F: scroll/viewport-recycle = **F1**, selection-border + editor
into the cell (the 8.2/8.3 deferral) = **F2**.

---

## §3-F Optional follow-ons (F5+F2 ✅ + F1 ✅ + F4 ✅ + F6 ✅ LANDED 2026-07-17; only F3 remains, cold-executable)

The four items Phases 2a/3/4/8 recorded as optional/deferred, promoted here to executable
sub-phase specs so a cold session can pick one up without re-deriving — plus F5
(headers-as-widgets + cell-owned chrome), owner-directed and fleshed out with pixel
receipts on 2026-07-17. **Owner-ratified sequencing (2026-07-17): F5 (with F2 folded in) →
F1 → F4 → F3; perf item C2 is retired into F5.** Ground rules for all of them:

- **Each F-item = one mini-phase** under the §0 cadence (inner loop per commit; the FULL
  phase-close battery + BOTH serialization legs at its close — every one of them touches the
  serialized surface or the rendered grid) and the §4 rules (naming through NOMENCLATURE,
  gates, docs-in-the-same-commit, deviations recorded here). **Since 2026-07-17 the gauntlet
  also enforces two standing layout gates** any F-work must keep green: `fg revisits` (the
  settle-engine re-visit baseline is EMPTY — every widget visited AT MOST ONCE per flush,
  suite-wide; ANY re-visit anywhere = regression) and `fg census` (arrange idempotence). The
  NoSettle-core discipline specced below is exactly what complies — public entries open ONE
  settle (`_settleLayoutsAfter`, Widget ~835), cores never settle.
- **Re-verify every anchor before relying on it** (the Phase-0 discipline). The original
  2026-07-06 receipts (tree `996f5d45`) predated the drag-embed arc, which has since
  COMPLETED (pushed 2026-07-13); **every anchor below was re-verified 2026-07-17 (tree
  `61080871`) and corrected inline where it had drifted** — among the drift: Widget grew to
  ~5100 lines, several methods gained `_` prefixes in the public/private call-separation arc
  (`078d67d4`), and `ScrollPanelWdgt`/`ActivePointerWdgt` moved under the drag-embed arc.
  They will drift again — grep the named symbol.
- **Sequencing (owner-ratified 2026-07-17): F5 FIRST, with F2 executing inside F5's commit
  series** (F5's evidence B makes the ring move mandatory for determinism, and F2's recapture
  budget is the one pixel change); **then F1** (its header paint-offset design is superseded
  by F5's header widgets — the F1 section notes this inline); **then F4** (unblocked — the
  drag-embed arc is complete, receipts re-verified post-arc; landing it after F1 touches the
  `_reconcileCellNoSettle` branch-1 seam once); **F3 independent, any time.** Perf item C2
  (`docs/archive/interactive-render-perf-A-C-plan.md` §3.2) is RETIRED INTO F5.
- The arc's §6 Definition-of-done is CLOSED and stays closed — each F-item carries its own
  done-when list; the ledger's F-boxes track them.

### F1 — scroll: logical sheet > viewport; wheel + keyboard; viewport materialise/recycle

> **2026-07-17: F1 now runs AFTER F5** (owner-ratified sequencing). Under F5 the header text
> lives in header WIDGETS, so the `_paintGrid` header-offset bullets below are superseded:
> the reconcile offsets/recycles the header widgets instead (column headers horizontally,
> row headers vertically, frozen against the other axis; they are direct sheet children,
> outside the cells container, so the container's scroll clip never touches them). The rest
> of this section — origin state, reconcile, hit-test mapping, wheel, editing, restore —
> stands as written.

> **✅ LANDED 2026-07-17 (same day, post-F5). As specced, with these as-built deviations —**
> - **The cell/chrome split:** instead of "make `_buildGridNoSettle` viewport-relative and
>   share it", it SPLIT: `_buildChromeNoSettle` (panel + slot-keyed headers + re-home of
>   indexed cells into a fresh panel) and `_reconcileViewportNoSettle` (ALL cell
>   materialisation — the constructor now calls the pair, so construction, scroll and restore
>   are one code path). Headers' "recycle" degenerated to RELABEL-IN-PLACE: cell-quantized
>   scroll means header widgets never move — `_labelText` derives from origin + slot at paint
>   time; `@index` is the SLOT.
> - **⚠⚠ The exemption predicate needed a RESTORE disjunct.** At `_reindexCellsNoSettle` time
>   the record's derived `@value` is still nil (a serialization transient — recommit + drain
>   run AFTER the reconcile), so the specced "record's value IS the hosted widget" test alone
>   would DESTROY every adopted hidden rich cell — losing exactly the state F1 promises to
>   keep. Shipped predicate: `hostedWidget? and record? and (record.value is hostedWidget or
>   not record.value?)` — safe because a snapshot only carries off-viewport cells for
>   widget-valued records (the invariant at save time), and a live empty-valued cell never
>   hosts (blank-commit reconciles the widget away in its own drain, before any scroll event).
> - **The invariant holds continuously, not just at origin changes:** a recompute that turns a
>   HIDDEN cell's value non-widget recycles it on the spot inside `_reconcileCellNoSettle`;
>   the branch-1 no-cell mount births the hidden cell at its NOTIONAL off-screen slot rect
>   (integer; `__hide` keeps it out of fullBounds/paint/hit-testing — verified against
>   `preliminaryCheckNothingToDraw` + the `fullBounds` visibility filter).
> - **`_startEditNoSettle` scroll-follows FIRST**: after a wheel the selection can sit
>   off-viewport with NO CellWdgt; Enter/F2/type-to-edit jump the view back to the active
>   cell (Excel behaviour) so the overlay editor always has a visible cell to mount on.
> - **Wheel** is per-axis at-limit escalation exactly like `ScrollPanelWdgt` (one escalate
>   call), keeps its destroy-temporary-handles opening move, and quantizes
>   `max(1, round(|delta|·wheelScale/cellSize))` whole cells post-inversion.
> - **Test case-law:** rows 1–14 are IN view at origin 0 — the RichCellRetain dependent had
>   to live at A20 (slot 0,7 at origin 12), not A13 (the first authoring's 40-px diff); park
>   the pointer (corner header) before every byte-compared screenshot (click-then-park).
> **Verification:** origin-0 byte-identity HELD — presuite 250/250 dpr1, ZERO recaptures;
> 3 new SystemTests (ScrollWheel / ScrollKeyboardFollow / ScrollRichCellRetain, each ending
> in an in-test `assertScreenshotsIdentical` round-trip proof) captured dpr1+dpr2 → suite
> 253; 3 new scrolled-round-trip rig rows (origin / hiddenRetain / cellCensus) green on BOTH
> serialization legs; close gauntlet 11/11 GREEN (396s — dpr1/dpr2/webkit 253/253, paint,
> tiernaming, settle, capstone, REVISITS baseline still EMPTY, census 0/1528, refs 1570
> consistent; the refs leg needed its serial retry — the documented load-flake, not a hash
> mismatch).

**Goal.** The sheet's LOGICAL grid becomes larger than the viewport (v1 bounds: 26 columns
A–Z × 100 rows — constants, still far under the address grammar's ZZ9999 ceiling); the user
scrolls by wheel and by keyboard scroll-follow; the viewport materialises/recycles `CellWdgt`s
so live-widget count stays viewport-bounded — the Phase-8 promise ("an off-screen cell is a
live node with no widget") made real. **Byte-identity constraint: at view origin (0,0) the
sheet renders pixel-for-pixel as today** — zero recaptures expected; all new pixels live in
new tests.

**Design (decided).**
- **Sheet-owned view origin, NOT a `ScrollPanelWdgt`** (extends the 2a direct-paint deviation;
  spec §9.1's scroll-panel hosting stays superseded). Why: (a) frozen headers — headers must
  not scroll, but a scroll panel scrolls its whole contents, so headers would need a second
  chrome layer + clip coordination; (b) the origin-(0,0) byte-identity above — a scroll panel
  brings scrollbar chrome that recaptures every spreadsheet screenshot; (c) the sheet wants
  CELL-QUANTIZED scrolling (whole rows/cols), which `scrollY`'s pixel model doesn't give.
  `ScrollPanelWdgt` integration + painted scroll-position indicators stay BANKED (revisit if
  the sheet ever needs pixel-smooth scroll or draggable thumbs).
- **State:** `viewOriginCol: 0` / `viewOriginRow: 0` as PROTOTYPE defaults (the 6a
  own-only-when-set idiom: an unscrolled sheet serializes byte-for-byte as before, and a
  pre-F1 snapshot deserializes to origin 0 through the prototype since deserialize skips the
  constructor). They are DOCUMENT state (a saved scrolled sheet restores scrolled) — do NOT
  add them to `@serializationTransients` (SpreadsheetWdgt ~52). New constants `sheetCols: 26`,
  `sheetRows: 100`; `numCols`/`numRows` (~59–60) keep meaning the VIEWPORT — document that in
  the geometry-constants comment.
- **The viewport reconcile (the materialise/recycle):** every origin change runs a new
  `_reconcileViewportNoSettle`:
  1. every visible address (origin … origin+viewport) has a `CellWdgt` positioned at the
     viewport rect of (address − origin) — create missing ones via the `_buildGridNoSettle`
     idiom (~129; make it viewport-relative and share it), then route the record's CURRENT
     value in via `_reconcileCellNoSettle` (~429) — an off-screen record kept recomputing, so
     a scrolled-in cell is instantly correct, no catch-up;
  2. a cell leaving the viewport: if it hosts a WIRED value-widget (branch 1 — the record's
     value IS that widget), it is EXEMPT from recycling — `__hide()` it in place (Widget
     ~2814; repaint-level, no layout settle, callable from NoSettle cores). Its hosted widget
     must keep riding the tree: that is what makes save/load of an OFF-screen widget-valued
     cell keep its runtime state — the §13 retain-and-remount rule extended to scroll, exactly
     as Phase 8 promised. Everything else (scalar / presenter / empty) `_fullDestroyNoSettle`s
     — a presenter is DERIVED and rebuilds from the record on re-entry (spec §9.4);
  3. a hidden rich cell re-entering: `show()` + reposition + reconcile.
  **Invariant (assert in the class header):** exactly one VISIBLE `CellWdgt` per on-screen
  address + exactly one HIDDEN `CellWdgt` per off-screen widget-VALUED cell + nothing else;
  `@_cells` indexes both (delete recycled entries).
  *(Alternative considered and rejected: re-BIND a fixed pool of 84 `CellWdgt`s to new
  addresses — a re-bound cell would have to detach its hosted value-widget from the tree,
  losing off-screen widget state on save. Create/destroy is bounded by the viewport per scroll
  step; a reuse pool remains a later optimisation that doesn't change semantics.)*
- **Branch-1 reconcile with NO cell widget** (the off-viewport guard at ~432): when the value
  is a WIDGET and no `CellWdgt` exists (a formula committed to an off-screen cell yields
  `new SliderWdgt`), CREATE a hidden one right there and host into it — otherwise the widget
  mounts nowhere and is lost on save (the guard's current early-return becomes the
  scalar/presenter path only).
- **Paint:** `_paintGrid` (~168) offsets header text by the origin (`colToLetters(viewOriginCol
  + col)`, row numbers `viewOriginRow + row + 1`) and draws the selection stroke only when the
  selection is inside the viewport, at `(selected − origin)`. At origin 0 every offset is the
  identity — the byte-identity constraint verified by the existing references.
- **Hit-test / selection:** `_cellAtLocal` (~255) keeps returning VIEWPORT coords;
  `mouseClickLeft` maps to sheet-space (`origin + viewport coords`). `@selectedCol/Row` are
  sheet-space (at origin 0 that is what they already are). Arrows
  (`_processKeyWhileSelectingNoSettle` ~303) clamp to `sheetCols`/`sheetRows` and then
  SCROLL-FOLLOW: if the selection left the viewport, shift the origin minimally to re-include
  it + reconcile + `_changed()`.
- **Wheel:** implement `wheel:` on the sheet (`ActivePointerWdgt.processWheel` ~942 routes to
  the first wheel-implementing widget on the climb from the cursor hit — `CellWdgt` must NOT
  implement it; model `ScrollPanelWdgt.wheel` ~836). Quantize to WHOLE rows/cols from the
  event delta via `WorldWdgt.preferencesAndSettings.wheelScaleY` (defined
  `PreferencesAndSettings.coffee:44`, value 1; sole consumer `ScrollPanelWdgt` ~886 — heed the
  `invertWheelY` pref applied just above it, ~859). Sign convention (verified 2026-07-17):
  POSITIVE deltaY scrolls content DOWN (`scrollY` ~592 does `newY = ct + steps` on
  `@contents.top()`; also documented on `MacroToolkit.wheelOn_InputEvents`) — still re-confirm
  at implementation. A wheel event is a PUBLIC entry: wrap in `_settleLayoutsAfter` (the
  `mouseClickLeft` shape). Implement the at-limit `escalateEvent 'wheel'` chain from day one
  (the ~883/~892 idiom), so a sheet inside a future scroll panel doesn't swallow its wheel.
- **Editing:** an in-progress edit COMMITS before any scroll (wheel or scroll-follow) — the
  click-away-commits precedent (~245) — so the overlay editor never has to move mid-edit;
  `_editCol/_editRow` stay sheet-space and `_isCellBeingEdited` (~472) is address-based
  already.
- **Restore:** `_reindexCellsNoSettle` (~509) adopts whatever cells rode the snapshot (visible
  + hidden rich), then runs `_reconcileViewportNoSettle` for the RESTORED origin instead of the
  bare `_buildGridNoSettle` — the invariant is re-established whatever mix the snapshot
  carried.

**Touch-list.** `src/spreadsheet/SpreadsheetWdgt.coffee` (constants + origin defaults; header
comment; `_buildGridNoSettle` → viewport-relative; new `_reconcileViewportNoSettle` +
`_scrollByNoSettle` + scroll-follow; `_paintGrid` offsets; `mouseClickLeft` mapping; `wheel`;
`_reindexCellsNoSettle`; `_reconcileCellNoSettle` branch-1 no-cell case), `CellWdgt` untouched
structurally (hide/show ride the Widget family). Docs, same commits: `src/spreadsheet/CLAUDE.md`
(the north-star scroll paragraph flips from future to present; the viewport invariant; the
commit-before-scroll rule) and NOMENCLATURE's spreadsheet table registers **viewport / view
origin** and **materialise / recycle** as terms of art (§4 rule 8).

**Tests.** `SystemTest_macroSpreadsheetScrollWheel` (commit values beyond the viewport, wheel
down: headers shift, the far value shows; wheel back: byte-exact original),
`SystemTest_macroSpreadsheetScrollKeyboardFollow` (arrow past the viewport edge → origin
follows; assert origin+selection via `evaluateString`),
`SystemTest_macroSpreadsheetScrollRichCellRetain` (slider in A1 dragged to a value → scroll it
out → assert `hostedWidgetAt` survives hidden + a dependent ref still reads it → scroll back:
same identity, same value). Rig: extend the sheet fixture to save SCROLLED with an off-viewport
widget-valued cell — EXPECTATIONS rows for (a) origin round-trips, (b) the off-screen widget's
state survives (the hidden-cell path), (c) the cell-count invariant (visible + hidden-rich,
both ways). Wheel synthesis: use the first-class L2 verb `MacroToolkit.wheelOn_InputEvents`
(`src/macros/MacroToolkit.coffee` ~544, added with the drag-embed arc) — it positions the
pointer with a queued move, then queues a real `WheelInputEvent`; positive deltaY scrolls
content DOWN; follow with `yield "waitNoInputsOngoing"`.

**Done when:** origin-0 references all pass UNCHANGED (zero recaptures); the three new tests +
rig rows green dpr1/dpr2/webkit; both serialization legs green; invariant documented; ledger
F1 checked.

**Risks / deferred.** Scrollbar/indicator chrome (banked with the ScrollPanelWdgt option);
column resize still out of scope; the wheel-sign and wheelScale conventions are VERIFY items;
`processWheel`'s climb means a hosted value-widget that ever implements `wheel` would swallow
the sheet's scroll over that cell — accepted (same as any nested scroll surface; the escalate
chain is the general answer).

### F2 — selection border + overlay editor fully into the `CellWdgt`

> **2026-07-17: F2 EXECUTES INSIDE F5's commit series** — F5's evidence B shows the ring
> cannot stay sheet-drawn once cells stroke their own edges (the ring's 2px bands half-cover
> the edge pixels; child edges painting after the sheet flip the blends, 91 px at dpr1), so
> the inside-ring move below is mandatory there, not optional. This section remains the spec
> for that part; its recapture budget is F5's one pixel change. The ledger checks F2 with F5.

**Goal.** Complete the Phase-8 view story: a `CellWdgt` renders ALL of its cell's view state —
its selection ring and its overlay editor, not just its value. OWNERSHIP does not move: the
sheet keeps the model, the single-cell selection state, and the whole keyboard/buffer editing
machinery (sole-receiver doctrine, 2b) — only RENDERING and MOUNTING move into the cell.

**Why (recorded honestly — this is cosmetic-architectural).** (a) Under F1 the ring and the
editor ride their cell through scrolls for free, instead of via sheet-paint offset math and the
commit-before-scroll rule for the editor; (b) inspecting a cell shows its complete view state;
(c) F4's drop-candidate highlight and the selection compose on the same widget. Phase 8
deferred it because it forces recaptures for that marginal gain — the budget is now explicit
below. Schedule with F1 (right after, same battery) or fold into F1's commit series.

**Design (decided).**
- **Selection ring.** The sheet's `_paintGrid` DROPS its selection stroke (~226–231); the cell
  strokes its own ring in `paintIntoAreaOrBlitFromBackBuffer` (CellWdgt ~85) when the sheet
  says so — new PUBLIC query `SpreadsheetWdgt.isSelectedAddress (address)` (a col/row compare;
  cells never reach into `@selectedCol/Row` directly). **Pixel decision, made now:** the
  sheet-drawn stroke (`strokeRect sx+1.5, sy+1.5, w−2, h−2`, lineWidth 2) SPILLS half a pixel
  past the cell's right/bottom edges (the stroke band runs to `x+w+0.5`), which the cell's own
  clip would crop — do NOT chase byte-identity by out-clipping tricks; draw the ring fully
  inside (`strokeRect 2, 2, w−4, h−4` cell-local, lineWidth 2 → band [1,3]) and RECAPTURE the
  spreadsheet reference set (every `SystemTest_macroSpreadsheet*` shows a selection — the
  whole family, 11 tests as of 2026-07-17; each webkit-verified per §0). Z-order stays effectively
  unchanged: today the ring (sheet's own paint) renders below every cell's content; a
  cell-drawn ring still renders below that cell's hosted child and doesn't overlap its text
  (text starts at x 4). VERIFY the analysis by frame-dump comparison at dpr1+dpr2 BEFORE
  recapturing (no-conclusions-before-evidence).
- **Editor into the cell.** `_mountEditorNoSettle` (~364) delegates to the editing cell — new
  `CellWdgt` members `_mountEditorNoSettle(bufferText)` / `_updateEditorTextNoSettle` /
  `_teardownEditorNoSettle`, holding the `StringWdgt` as `@_editorWdgt` (a CHILD of the cell,
  same absolute rect as today so no pixel change from the move itself). The sheet keeps
  `@_editing/@_editBuffer/@_editCol/@_editRow` + `processKeyDown`; `_isCellBeingEdited` (~472)
  RETIRES — the cell suppresses its own scalar paint when `@_editorWdgt?`.
- **Restore hygiene:** a snapshot can be taken MID-EDIT; today `_reindexCellsNoSettle` destroys
  stray non-cell children of the SHEET (~516–521) — the stray editor is now a CELL child, so
  the cell's restore path drops any child that is neither its `hostedWidget` nor re-adopted
  (add `_editorWdgt` to `CellWdgt.@serializationTransients` ~42, and a one-line sweep in the
  re-index adoption loop).

**Touch-list.** `SpreadsheetWdgt` (`_paintGrid` selection block removed; `isSelectedAddress`
new; editor lifecycle delegating; `_isCellBeingEdited` deleted), `CellWdgt` (ring paint +
editor mount/update/teardown + transients + stray-editor sweep), `src/spreadsheet/CLAUDE.md`
(the Phase-8 "selection + editing stay sheet-driven (v1)" paragraph rewritten to the new
split: sheet owns state, cell renders it).

**Tests.** No new behavior ⇒ no new SystemTest; extend `SystemTest_macroSpreadsheetSelection`
with an `isSelectedAddress` assertion (`evaluateString`). Rig: one new EXPECTATIONS row — a
MID-EDIT snapshot restores to a settled, non-editing sheet with no stray editor child (extend
the fixture to snapshot while editing). The recapture list above, each webkit-verified.

**Done when:** the recaptured set is listed + webkit-verified; suite + both legs green; the
mid-edit rig row green; ledger F2 checked.

### F3 — the "operate ➜" cell menu (spec §9.5, deferred in Phase 3)

**Goal.** Right-click a cell whose value has an operation algebra → an "operate ➜" submenu
lists the value class's zero-required-arg methods; picking one writes `<addr>.<method>()` as
the formula of a nearby empty cell, commits it, and selects it. The algebra stays METHODS on
the value classes (spec §9.5); the menu is introspection + text generation only.

**Design (decided).**
- **Entry point:** `CellWdgt.addWidgetSpecificMenuEntries (widgetOpeningThePopUp, menu)` — the
  standard hook (Widget ~4098, reached via `mouseClickRight` Widget ~328 → the hand's
  `openContextMenuAtPointer` `ActivePointerWdgt` ~129 → `buildContextMenu` ~3906 →
  `buildWidgetContextMenu` ~4107; right-clicking a cell already opens the CELL's own context
  menu, since Phase 8 made cells real widgets). The entry appears only when the cell's record
  value is OPERABLE (below); it opens a submenu of method names (menu-building model: the 6a
  controller menus + `ControllerMixin.openTargetSelector`'s `MenuWdgt` construction, incl. its
  addMenuItem extra-argument idiom at ControllerMixin ~24 for passing the method name to the
  action).
- **Which methods (the meta question, decided): REFLECT, filter, allow a curation override.**
  Enumerate `Object.getOwnPropertyNames(value.constructor.prototype)` filtered to: functions;
  not `_`-prefixed; `fn.length is 0` (CoffeeScript default-args don't count toward `length`,
  so `lighter`/`darker` qualify while `mixed(p, other)` is excluded — zero-required-arg methods
  are exactly the ones callable without inventing arguments); and not in a small structural
  DENYLIST kept in ONE place with a header comment (`constructor`, `toString`, `equals`,
  `cellPresenter`, `getEmptyObjectOfSameTypeAsThisOne`, the serialization/copy protocol names —
  seed it by READING Color's prototype and tune until the Color list is exactly the algebra:
  expect `lighter`, `darker`. Verified 2026-07-17: with exactly that denylist, reflection over
  Color's prototype yields `lighter` + `darker` and NOTHING else — `bluerBy`,
  `channelDistanceTo`, `mixed` all take required args). A class-side `@operateMenuNames` static array WINS when defined
  — the curation escape hatch for a future noisy value class. Reflection (not curation) is the
  default because it honours spec §9.5's live-extensibility: a method injected via the class
  inspector appears on the next right-click with no registration.
- **Operable:** `value?` and not a `SheetError` and not a `Widget` and `typeof value is
  "object"` — primitives (numbers/strings) are deliberately excluded in v1 (their prototypes
  are all-native noise); record that in the CLAUDE.md.
- **Target cell:** the first EMPTY cell scanning RIGHT from the operand in its row (within the
  logical bounds — F1's `sheetCols` if landed, else `numCols`), else the first empty scanning
  DOWN the operand's column; if none, an `inform` no-op message (the `SliderWdgt.showValue`
  idiom, ~211: `@inform @value` — note it is the Widget-inherited `@inform`, not
  `world.inform`). Add the scan as `SheetModel.firstEmptyAddressAfter` (address algebra belongs to the
  model). Then exactly the editor's commit path: `FormulaCompiler.commit target, text` +
  `world.dataflow.markStale target` + select the target + `_changed()`.
- **Settle discipline:** the action mutates no geometry (commit + markStale + selection are
  paint-level; the drain owns any recompute settle) — expect NO settle wrapper; if
  check-layering disagrees, follow its guidance and record the deviation.
- **Errors are values:** a written formula that turns out wrong at runtime yields `#ERR` in the
  target cell — no extra validation machinery (spec §9.6 does the work).

**Touch-list.** `CellWdgt` (`addWidgetSpecificMenuEntries`, the submenu builder, the
`operateWriteFormula` action, the denylist constant), `SheetModel`
(`firstEmptyAddressAfter`), docs: `src/spreadsheet/CLAUDE.md` §9.5 section grows the menu
story; the spec's §9.5 gets a "landed (F3)" note at close.

**Tests.** `SystemTest_macroSpreadsheetOperateMenu` — A1 = `new Color 255, 0, 0`; right-click
A1's cell (the 6a toggle test is the drive-a-real-context-menu precedent), operate ➜ lighter;
assert B1's source is `"A1.lighter()"` (`evaluateString`) + the two-swatch screenshot; then
edit A1 → B1 recolours (reactivity through a menu-written formula). Recaptures: none expected
— no existing test right-clicks a cell (verified by grep 2026-07-17; re-verify at
implementation). Serialization legs:
run them (cheap) though the persistent surface should be unchanged.

**Done when:** the Color menu lists exactly the algebra; the new test green dpr1/dpr2/webkit;
no recaptures (or each justified); ledger F3 checked.

**Risks.** Reflection noise on future value classes (mitigated: filter + denylist +
`@operateMenuNames` override); the `addMenuItem` extra-arg convention must be re-verified at
the call site; multi-argument operations (`mixed`) stay OUT of the menu by construction — a
future argument-prompting flow is banked, not specced.

### F4 — drag-and-drop desktop widgets into cells (widget-entry cells)

> **✅ LANDED 2026-07-17 (same day as F1). As specced, with these as-built findings —**
> - **The adopt/re-host decision:** `hostNoSettle` tolerates the already-a-child dropped
>   widget as-is (`_addNoSettle`'s `__add` is a safe remove-then-append self-re-add) — no
>   thin adapter needed; the drop hook calls it directly.
> - **⚠⚠ The drag-out RE-HOST trap:** clearing `widgetEntry` alone is NOT enough — the
>   record's cached `@value` is still the grabbed widget, and the next recompute's
>   no-compiledFn route (`_cacheValue @value`) would take the branch-1 reconcile and RE-HOST
>   the widget right off the hand. The grab hook clears the cached value through the normal
>   blank-commit path (`FormulaCompiler.commit record, ""`).
> - **⚠⚠ The "grabbability of a wired slider" risk was MIS-FRAMED — no payload of ANY class
>   was grabbable out of a cell:** `Widget.grabsToParentWhenDragged`'s generic
>   solid-with-parent branch (parent = a plain Widget) climbs the grab to the window, so the
>   fallback "drag-out still serves other payloads" was falsified. Landed a NEW parent-side
>   opt-in seam: **`wantsDetachOfChild(aWdgt)`** (the `wantsDropOfChild`-style query family),
>   consulted by that branch; only `CellWdgt` defines it — true exactly for its
>   `hostedWidget` (editor + other children stay solid) — inert everywhere else. The slider
>   IS grabbable by its track with the seam in place (its thumb stays a value gesture).
> - **A LATENT F5 HOLE found + closed by the same investigation:** moving the cells into the
>   `SheetCellsPanelWdgt` had silently made every CELL float-draggable out of the grid
>   (panel children are loose under the default `isLockingToPanels` false; pre-F5
>   sheet-parented cells were solid). `CellWdgt.isLockingToPanels: true` — grid chrome is
>   never rippable; a prototype default, nothing serializes.
> - Un-wiring on drag-out is a bare `@target`/`@action` field-clear (no un-wire idiom exists
>   in ControllerMixin — verified) + the public `world.dataflow.removeAllEdgesOf` (equivalent
>   for a value-widget: no incoming edges); the REPLACE path needs no explicit un-wiring —
>   `Widget._destroyNoSettle` already drops a destroyed widget's engine edges.
> - The [D] macro lint bans `_applyMoveTo` in macro fixtures — position via
>   `world.add widget, position` (the rig's form).
> **Verification:** presuite — all 253 pre-existing tests green with ZERO reference changes
> (the seam + the lock are invisible; no existing macro drops onto a sheet); 2 new
> SystemTests (DropWidgetIntoCell / DragWidgetOutOfCell) captured dpr1+dpr2 → suite 255;
> 2 new rig rows (`spreadsheet.roundtrip.widgetEntry` incl. wiring + dragged value;
> `spreadsheet.duplicate.widgetEntryIndependence`) green on BOTH serialization legs; close
> gauntlet 11/11 GREEN in 275s (dpr1/dpr2/webkit 255/255, apps, paint, tiernaming, settle,
> capstone, refs, REVISITS baseline still EMPTY, census 0/1528).

**Goal.** The spec-§9.1 cell record's "kind-of-entry metadata" finally materialises: a cell's
content can be ENTERED by dropping a desktop widget into it, not only by typing a formula that
CONSTRUCTS one. The dropped widget becomes the cell's value — hosted, wired, referenced through
`exportedValue` — and survives save/load/duplicate. Grabbing it back out empties the cell. This
was deferred at Phase 4 ("Drag-and-DROP of desktop widgets into cells DEFERRED").

**Hard sequencing constraint — SATISFIED: the drag-embed arc COMPLETED (pushed 2026-07-13)**
(`docs/archive/drag-embed-implementation-plan.md`; its Phase 3 flipped the release rules and Phases
3–6 churned `ActivePointerWdgt` + the drop-driving tests — the receipts below were
re-verified POST-arc, 2026-07-17, and the hook-chain shape survived unchanged). F4 needs NO
dwell machinery of its own: cells accept only PLAIN payloads, the instant-accept class
(drag-embed spec §4, the owner-approved payload-class rule; the plain-payload else-branch in
`drop` ~442–450 resolves the target with no dwell) — and post-arc, cells inherit the
candidate-highlight visuals during drags for free (any `wantsDropOfChild`-true widget is a
"willing" candidate — spec §4 tier table).

**Design (decided).**
- **Accept gate:** `CellWdgt.wantsDropOfChild: (aWdgt) -> not aWdgt.requiresDeliberateEmbedding()`
  — accepts plain payloads, refuses window payloads (the capability landed on the Widget base
  with drag-embed Phase 2 — `requiresDeliberateEmbedding` base-false at Widget ~3717, base
  `wantsDropOfChild` at ~3703; a 68×20 cell is no place for a window). An override,
  not `enableDrops()` — the boolean flag can't discriminate payloads. The hand's climb
  (`dropTargetFor`, `ActivePointerWdgt` ~172) then resolves the CELL as the innermost acceptor
  — note the climb passes the payload's `_dropPolicyProxy()`, which answers
  `requiresDeliberateEmbedding` by the payload's real class. Ancestor-drops can't
  occur (the carried widget rides the hand, outside the tree).
- **Adoption:** `CellWdgt._reactToChildDropped: (droppedWdgt, activePointerWdgt) ->` — the
  drop's single-settle recipient hook (`ActivePointerWdgt.drop` ~394–538:
  `_beforeChildDropped` ~464 → `add` ~498 → `_settleLayoutsAfter =>
  _reactToChildDropped / _reactToBeingDropped` ~536–538; the block comment ~528–535 REQUIRES
  overrides to work through NoSettle cores — cores-call-cores). Body:
  re-host through the existing lane — the dropped widget is ALREADY a child post-`add`, so
  either make `hostNoSettle` (~112) tolerate an already-child widget or add a thin
  `_adoptDroppedWidgetNoSettle` that skips the re-add; decide at implementation, record which.
  Then `wireValueWidget droppedWdgt` (~134), then the MODEL update:
  `record = @_sheetWidget.model.getOrCreateCellAt @address`, then
  `FormulaCompiler.commit record, ""` (clears any old formula's compiledFn AND drops its
  edges through the normal path), then `record.widgetEntry = droppedWdgt` +
  `world.dataflow.markStale record`.
- **Model — the entry-kind field:** `SheetCellRecord` gains PERSISTENT `widgetEntry: nil`
  (prototype default, own-only-when-set — the 6a idiom; NOT in `@serializationTransients` ~44).
  It serializes as an in-structure `$r` reference to the widget, which rides the tree as the
  cell's hosted child; `DeepCopierMixin` remaps it to the copy — both copy mechanisms free,
  spec §2's rationale working again. Semantics:
  - `dataflowRecompute` (~56): `return @_cacheValue @widgetEntry if @widgetEntry?` FIRST — a
    widget-entry cell has no formula; the branch-1 reconcile RETAINS the mounted instance
    (identity match), refs flow through `exportedCellValue` (~81) unchanged.
  - **Entry lifecycle is owned by the GESTURES, never by `FormulaCompiler.commit`** (which
    stays pure source machinery and does not read or write `widgetEntry`). Set by: the drop
    (above; it also clears `@source`). Cleared by: a USER edit-commit on the cell — the
    sheet's `_commitEditNoSettle` clears the entry (typed content of ANY kind, including
    blank, replaces the dropped widget, which is destroyed with the unhost, exactly like a
    formula-widget class change today; alternative considered: eject to the world instead of
    destroying — rejected for v1 scope, record in `src/spreadsheet/CLAUDE.md` beside the
    delete semantics) — and by the drag-OUT below. The restore path (`_recommitAllCells` →
    `commit(cell, cell.source)`; renamed `recommitAllCells`→`_recommitAllCells` in the
    call-separation arc) therefore PRESERVES the entry with no special-casing: a
    blank source compiles to nothing, declares no edges, and the recompute's entry-first
    branch re-presents the restored widget.
- **Drag-OUT (the symmetric gesture):** `CellWdgt._reactToChildGrabbed: (grabbedWdgt) ->` (runs
  inside the grab's settle — invoked at `ActivePointerWdgt` ~382, inside `grab:` ~304): when
  `grabbedWdgt is @hostedWidget` AND
  the record's `widgetEntry` is that widget — clear both, un-wire (clear the widget's
  `@target`/`@action` + drop its wire edge: the 6b outgoing-edge removal is now
  ENGINE-PRIVATE — `_removeOutgoingEdgesOf`, `_`-prefixed in the call-separation arc — so from
  outside the engine use the public node-death API `world.dataflow.removeAllEdgesOf widget`,
  equivalent here since a value-widget has no incoming edges; VERIFY whether
  a bare target-clear idiom already exists, grep before inventing), `markStale record` →
  dependents see `nil` next drain. The widget rides the hand and lands wherever dropped.
  Guard on `widgetEntry` identity: grabbing a PRESENTER swatch out (possible today, pre-F4)
  keeps its current behavior (the next reconcile rebuilds the presenter — derived state).
- **Formula-made widget cells are untouched:** a `new SliderWdgt` formula cell keeps its
  Phase-4 semantics (source persists, widget retained by class match). The two kinds coexist;
  `widgetEntry` wins at recompute because it is checked first.

**Touch-list.** `CellWdgt` (`wantsDropOfChild`, `_reactToChildDropped`,
`_reactToChildGrabbed`, the adopt/re-host decision), `SheetCellRecord` (`widgetEntry` default +
recompute branch + header PERSISTENT/DERIVED table update), `FormulaCompiler` (entry-clearing
+ entry-preserving commit paths), `src/spreadsheet/CLAUDE.md` (entry kinds: formula vs
widget-entry; drag-out; the replace-destroys decision), NOMENCLATURE spreadsheet table:
register **widget entry** (§4 rule 8); spec §9.1 gets a "kind-of-entry landed (F4)" note at
close.

**Tests.** `SystemTest_macroSpreadsheetDropWidgetIntoCell` — build a desktop `SliderWdgt` via
`evaluateString`, macro-drag it onto B2 (plain payload → instant accept; post-drag-embed the
mid-drag candidate highlight simply bakes into the references); assert `hostedWidgetAt "B2"`
is it, then C2 = `B2 * 2` reacts to dragging the slider IN the cell.
`SystemTest_macroSpreadsheetDragWidgetOutOfCell` — grab it back out; assert the cell is empty
and the dependent went `nil`-driven (assert the exact painted result). Rig: EXPECTATIONS rows
— a widget-entry cell round-trips (entry + dragged position + wiring), and duplicate-sheet
independence holds for it (drag the original's slider; the copy's value stays). Serialization
legs MANDATORY (persistent surface changed). Recaptures: none expected — no existing macro
drops onto a sheet (verified by grep 2026-07-17; re-verify at implementation).

**Done when:** drop-in + drag-out + round-trip + duplicate-independence all green
dpr1/dpr2/webkit; both legs green; entry-kind docs landed; ledger F4 checked.

**Risks.** The `hostNoSettle` already-a-child subtlety (decided at implementation, recorded);
grabbability of a WIRED slider out of a cell is unverified (its thumb-drag is a value gesture,
not a grab — if the slider body proves ungrabbable in practice, drag-out still serves other
payloads and a cell-menu "eject" affordance is the banked fallback; record findings). The
drag-embed arc closed WITHOUT changing the drop-hook signatures (re-verified 2026-07-17:
`_beforeChildDropped` / `_reactToChildDropped` / `_reactToBeingDropped` /
`_reactToChildGrabbed` all keep the shapes used above).

### F5 — headers become widgets; the grid chrome migrates into the cells (+ F2 folded in)

**Status: ✅ LANDED 2026-07-17, same day as the flesh-out (F2 executed inside it — both
ledger boxes checked together). Landing log: NEW `SheetHeaderCellWdgt` +
`SheetCellsPanelWdgt`, `CellWdgt` edges+ring+editor, `SpreadsheetWdgt` paint DELETED +
chrome build/re-index + editor delegation + PUBLIC `isSelectedAddress`/`paintGridEdges`.
Verified pre-recapture: the ENTIRE pixel diff vs the old references was 332 px, all inside
the selected cell A1's rect (the budgeted F2 ring change; bbox-checked) — headers,
gridlines, text byte-identical as receipts A/C predicted. One design claim FALSIFIED at
implementation (the backgrounds bullet below, corrected in place): the cells panel is
TRANSPARENT, not filled. Close gates: `fg gauntlet` 11/11 in 276s (dpr1+dpr2+webkit 250/250
— every recaptured frame webkit-verified — apps, paint, tiernaming/settle/capstone, refs,
REVISITS baseline still EMPTY, census); both serialization legs green over the updated rig
(F5 chrome census + the NEW `spreadsheet.roundtrip.midEditClean` row); the 11-test
`macroSpreadsheet*` family recaptured dpr1+dpr2 (the ring); `fg diffpage` review page
generated pre-recapture. Docs landed in the same commits: `src/spreadsheet/CLAUDE.md`,
NOMENCLATURE (header cell / cells panel / edge ownership / crossing rule), spec §9.1
(F5 = the shipped form). Pixel evidence below: three SWCanvas probes + a ground-truth read
of the real `macroSpreadsheetOpenGrid` dpr1 reference (methodology + numbers inline; probe
scripts were session scratch — `Fizzygum-tests/.scratch/f5-*.js`, gitignored, trivially
re-derivable from the geometry stated here).**

**The direction (owner, 2026-07-17).** Anything selectable/clickable should be a Widget. The
column-header cells (one day: click to select the whole column) and the row-number header
cells (select the row) should therefore become widgets, exactly as the data cells did in
Phase 8. And once they are, the gridline chrome is painted by the cell widgets themselves
(each drawing its own edges), leaving the sheet's own paint EMPTY — the sheet becomes a pure
container + model owner; every visible thing is a widget. The cells attach into a dedicated
container subclass; residual border drawing, if any, is that container's job, live-stroked,
never back-buffered. This is the Phase-8 flip taken to its end state; Phase 8's "data cells
only" scope note anticipated it ("headers-as-widgets would be a purely additive later step"
— `src/spreadsheet/CLAUDE.md`).

**Pixel evidence (2026-07-17, all against the exact `_paintGrid` geometry: headerColWidth 34,
headerRowHeight 20, colWidth 68, rowHeight 20, 6×14, gw 442, gh 300).**
- **(A) Segmentation is byte-identical — with ONE ordering rule.** A 442×300 SWCanvas replica
  of today's paint (full-length gridlines + the 4 darker border/separator lines, drawn in
  today's order) vs the F5 form (every widget — corner, 6 column headers, 14 row headers,
  84 data cells — stroking only its OWN top+left edge segments): **BYTE-IDENTICAL at dpr1 and
  dpr2**, but ONLY when each widget strokes its grid-coloured edge BEFORE its dark edge. A
  naive left-then-top order diverged at 26 px (dpr1): the crossing pixels of the dark
  verticals (x 0.5 / 34.5) with grid horizontals — today's paint draws ALL gridlines first
  and the darker lines LAST, so dark wins every crossing. **THE CROSSING RULE: per widget,
  grid-coloured edges first, dark edges last.** (In-world ground truth: local (0,40) and
  (34,40) are rgb(150,150,150) in the real reference.)
- **(B) The selection ring forces the F2 fold.** Same replica with the selected-A1 ring:
  today (lines, then ring) vs F5-without-F2 (sheet paints ring, then the child cells stroke
  their edges on top) differs at **91 px dpr1 / 348 px dpr2** — the ring's 2px bands
  half-cover the edge pixel rows/columns, and opaque child edges then replace the blend.
  F5 without moving the ring is NOT byte-identical, and the moved ring is exactly F2's
  already-budgeted inside-ring (`strokeRect 2, 2, w−4, h−4` cell-local — band [1,3), which
  touches NO edge pixel, so draw order becomes irrelevant and the pixels are stable). Hence:
  **F2's ring + editor move execute inside F5's commit series; the F2 section above is the
  spec for that part, including its ~11-test recapture budget.**
- **(C) There is NO visible right/bottom outer border today.** The `col <= numCols` /
  `row <= numRows` stroke loops draw their LAST line at gw+0.5 / gh+0.5, which rasterises
  into pixel column gw / row gh — one past the widget's last own pixel — and the sheet's
  own-bounds clip crops it entirely (probe: fully clipped; ground truth: the reference's
  last column/row contain line colours ONLY at crossings, and cols 440–442 / rows 298–300
  sample as backdrop). **The container therefore paints NOTHING in v1** — byte-identity
  demands it. The owner's "cheap two live strokes" is the mechanism held in reserve IF a
  visible right/bottom border is ever wanted (a deliberate, recaptured pixel change).
- **Backgrounds — the flesh-out's first reading was FALSIFIED at implementation
  (2026-07-17, same day).** The flesh-out read "cell interiors are rgb(248)" as "the sheet
  paints `@backgroundColor` (a Widget default of 248)". WRONG: `Widget.backgroundColor`
  defaults to **nil** (Widget ~107), so the old paint's background rect was a NO-OP — the
  sheet's data region has ALWAYS been transparent, and the 248 in the reference is the
  WINDOW's content backdrop showing through. (The wrong reading shipped briefly as
  `panel.color = @backgroundColor` = nil, which `RectangularAppearance` cannot render —
  `color.toString()` threw on every repaint, the error console popped in every spreadsheet
  test, and its own layout tripped the NON_INTEGER_GEOMETRY gate; the whole family failed
  loudly.) Correct model: the cells panel is TRANSPARENT (nil `@appearance` — the CellWdgt
  idiom; that also kills the inherited inset stroke), the backdrop keeps showing through the
  data region, and the ONLY fill any widget paints is the header cells' 236 strip fill
  (which WAS sheet-painted). Verified: post-fix, the full diff vs the old reference is 332 px,
  ALL inside the selected cell A1's rect — the budgeted ring change and nothing else.

**Design (decided; receipts above).**
- **Two new classes**, both in `src/spreadsheet/` (already globbed by `build.py` — no
  manifest change):
  - **`SheetHeaderCellWdgt`** — one class for all 21 header cells, `kind` ∈ column / row /
    corner (+ its 0-based index). Paints: its 236 fill, its top+left edges (crossing rule),
    and its label — `model.colToLetters(index)` / `"" + (index + 1)` / blank — in
    `headerTextColor`, 12px Arial, at local `(4, height − 6)`: exactly today's header-text
    offsets and exactly the `CellWdgt` scalar-paint precedent (Phase 8 proved this text move
    is byte-exact). Text back-buffering is NOT added in v1 — the label paints live like
    `CellWdgt` scalars do; the perf follow-up (below) is measurement-driven.
  - **`SheetCellsPanelWdgt extends PanelWdgt`** (owner direction: a subclass of the
    container class; `PanelWdgt` is the canonical container and its
    `ClippingAtRectangularBoundsMixin` clipping is exactly what F1's scroll viewport wants,
    dormant until then). It spans the DATA region (34,20)–(442,300) sheet-local and hosts
    the 84 `CellWdgt`s. It is TRANSPARENT — nil `@appearance`, the CellWdgt idiom — because
    the sheet never painted a data background (see the falsified-backgrounds receipt above):
    the backdrop under the sheet keeps showing through, and the nil appearance also kills
    the inherited inset stroke that would have overdrawn the cells' edge pixels. v1
    neutralisations, each verified at implementation: `mouseClickLeft` ESCALATES (PanelWdgt's
    own would `bringToForeground` and stop, swallowing the click before the sheet's selection
    handler — verified in source), `wantsDropOfChild -> false` (cells tile it completely, but
    be explicit — F4 targets CELLS), `childrenCanLockToMe -> false` (cells must not gain the
    lock-to-panel menu toggle they lacked when sheet-parented), editing amenities off
    (`providesAmenitiesForEditing: false`). It paints NO residual border (receipt C: none is
    visible today); the owner's cheap-live-strokes slot stays reserved for the day a visible
    right/bottom border is wanted.
- **Edge ownership:** every widget — data cells, header cells, corner — strokes its own TOP
  and LEFT edges, spanning exactly its own width/height. Colour: left edge DARK
  (`headerBorderColor`) iff its boundary sits at sheet-local x ∈ {0, headerColWidth}, top
  edge DARK iff y ∈ {0, headerRowHeight}, else `gridlineColor`. **Crossing rule (receipt A):
  the grid-coloured edge is stroked BEFORE the dark edge, per widget.** Nobody strokes
  right/bottom.
- **`CellWdgt` paint restructure:** no fill (stays transparent — the backdrop under the
  sheet shows through, as it always did), stroke edges ALWAYS (before the hosted-widget /
  no-scalar early-returns), then the F2 ring when `@_sheetWidget.isSelectedAddress @address`
  (inside form, `strokeRect 2, 2, w−4, h−4`, lineWidth 2 — the ONE recaptured pixel change),
  then scalar text as today. Hosted widgets/presenters unchanged (children paint above).
- **F2 executes here** (the F2 section above is the spec for this part): the ring as above
  (the sheet's selection block dies with `_paintGrid` itself; new PUBLIC
  `SpreadsheetWdgt.isSelectedAddress`), the editor mount/update/teardown move to `CellWdgt`
  (`@_editorWdgt`, serialization transient + re-index sweep), `_isCellBeingEdited` retires.
- **Sheet paint goes EMPTY:** `_paintGrid` DELETED; the sheet's
  `paintIntoAreaOrBlitFromBackBuffer` override is deleted too and `@color`/background set so
  the base paints nothing (the tiling children ARE the pixels — the CanvasGlassTopWdgt nil
  idiom; decide the exact nil-vs-empty-override form at implementation and record it here).
  Geometry constants stay on the sheet (the single authority); `_buildGridNoSettle` grows to
  build container + headers + cells (idempotent, address/kind-keyed, the same
  skip-if-present discipline).
- **Serialization/restore:** the container + header widgets ride snapshots as ordinary
  children. `_reindexCellsNoSettle` adopts `CellWdgt`s (walking through the container),
  DESTROYS all derived chrome (headers, corner, container — after re-homing the cells) and
  rebuilds it via `_buildGridNoSettle`: ONE path serves pre-F5 snapshots (no chrome present)
  and post-F5 snapshots (chrome present, rebuilt) with no double-grid. Both serialization
  legs MANDATORY; the rig's `sheet` fixture EXPECTATIONS rows update (children census:
  84 cells → 84 cells-in-container + 21 headers + 1 container).
- **Header SELECTION semantics stay OUT of scope** — F5 lands clickable, inspectable header
  widgets with today's behaviour (clicks escalate to the sheet exactly as cell clicks do);
  column/row selection is its own later spec (it touches editing, refs, and paint).
- **Perf follow-up (measurement-driven, NOT in v1):** if `prof-interactive.js --sw --text`
  still shows the header labels hot after F5, give `SheetHeaderCellWdgt` (and optionally
  `CellWdgt` scalars) the `TextWdgt`-style immutable text cache. STROKES stay live always
  (owner 2026-07-17): cheap, memory-free, no FP-CTM risk.
- **NOMENCLATURE registrations (§4 rule 8):** header cell / cells panel / edge ownership
  (top+left) / the crossing rule. Docs in the same commits: `src/spreadsheet/CLAUDE.md`
  (north star becomes "the sheet paints NOTHING; every visible thing is a widget"; the
  Phase-8 "data cells only" scope note superseded by F5), spec §9.1 note.

**Interactions.**
- **F1:** its `_paintGrid` header-offset design is SUPERSEDED — post-F5, F1 scroll-offsets
  the header WIDGETS through the viewport reconcile (column headers recycle horizontally,
  row headers vertically, each frozen against the other axis; keep headers DIRECT sheet
  children, OUTSIDE the cells container, precisely so the container's future scroll clip
  never clips the frozen headers). F1's cell materialise/recycle is untouched.
- **C2 (perf plan §3.2): RETIRED INTO F5** — receipt C removed the last sheet-drawn layer a
  chrome buffer could cache; the text hot-spot lands in header widgets (cache = the perf
  follow-up above). Recorded in the perf plan's §3.2 ⚠⚠ box + §4 ledger.
- **Widget count:** +21 header widgets + 1 container — viewport-bounded, trivial next to
  the 84 cells.

**Touch-list.** `SpreadsheetWdgt` (paint override + `_paintGrid` deleted;
`isSelectedAddress` new; `_buildGridNoSettle` builds chrome; `_reindexCellsNoSettle` chrome
rebuild + editor sweep; editor lifecycle delegates to the cell; `_isCellBeingEdited`
deleted), `CellWdgt` (edges + ring + editor members + transients), NEW `SheetHeaderCellWdgt`,
NEW `SheetCellsPanelWdgt`, `src/spreadsheet/CLAUDE.md`, NOMENCLATURE, spec §9.1 note; tests
repo: the ring recaptures + rig EXPECTATIONS + the assertion extension below.

**Tests.** No new pixels EXCEPT the budgeted F2 ring recapture (the
`SystemTest_macroSpreadsheet*` family — 11 tests as of 2026-07-17, each webkit-verified per
§0). Extend `SystemTest_macroSpreadsheetSelection` with `evaluateString` assertions:
`isSelectedAddress` truth, a header-widget census (21 `SheetHeaderCellWdgt`s), and the
container hosting exactly 84 cells. Rig: the F2 mid-edit-snapshot row + the updated
children-census rows. Both serialization legs. `fg revisits` (the chrome builds through
NoSettle cores in the constructor — the DegreesConverter orphan idiom — so the EMPTY
baseline must hold) + `fg census` green.

**Done when:** gauntlet green with ONLY the 11 ring recaptures (webkit-verified, listed in
the commit); revisit baseline still EMPTY; census green; both serialization legs + updated
rig rows green; docs + NOMENCLATURE landed; ledger F5 AND F2 checked together.

**Risks.** `PanelWdgt` baggage (drops / editing amenities / click interception / appearance
chrome) — neutralised by the v1 overrides above, each VERIFIED at implementation (the
appearance question resolved itself: nil appearance, since the panel is transparent).
Restore of PRE-F5 snapshots (no chrome in the tree) and POST-F5 snapshots (chrome present)
must both land in the destroy-derived-then-rebuild path — the rig proves both. Inspector
member-list churn is a non-risk (no existing test inspects the sheet or a cell — verified
2026-07-17).

### F6 — resizable viewport: window resize shows more of the sheet (partial edge cells)

> **AUTHORED 2026-07-17 (post-F4), no code. Owner-ratified decisions (2026-07-17), baked in
> below: (1) PARTIAL EDGE CELLS — the last visible column/row may be partially visible,
> clipped; (2) when the window grows past the whole logical grid, BACKDROP shows beyond the
> last column/row (no max-size cap); (3) the DEFAULT open size stays exactly today's —
> the default-size render must stay byte-identical, zero recaptures; (4) the logical sheet
> stays `sheetCols`×`sheetRows` = 26×100.**

> **✅ LANDED 2026-07-17 (same day as authoring). As specced, with these as-built findings —**
>
> - **V1 resolved: the layout-spec "flip" is a DELETION.** The default
>   `WindowContentLayoutSpec` is already grow 1 + `canSetHeightFreely` true, and the BASE
>   Widget protocol is exactly the fill-content protocol (`_setWidthSizeHeightAccordingly` =
>   apply width + hand height back; `preferredExtent` = applied extent, which feeds the
>   first-placement hug with the sheet's default extent). The sheet's three overrides died
>   (`initialiseDefaultWindowContentLayoutSpec` / `preferredExtentForWidth` /
>   `_setWidthSizeHeightAccordingly`, with `_gridWidth/_gridHeight`); no new sizing code.
> - **V2 resolved: the seam is a `_reLayout` override** (bounds-first `_applyGrantedBounds`, then
>   `_buildChromeNoSettle` + `_reconcileViewportNoSettle` re-derive everything from the
>   just-applied frame, then `super`) — the `StretchableWidgetContainerWdgt` precedent. NOT
>   `_positionAndResizeChildren`: that is a stack-family dispatch (via `_reLayoutChildren`)
>   the plain-Widget `_reLayout` never calls. Reached through `_applyExtent`'s schedule-valve
>   in the same flush the window grants the extent; absolute placement of every child from
>   the sheet's frame subsumes float-follow on the arrange path.
> - **V3 resolved: the sheet augments `ClippingAtRectangularBoundsMixin`** (the PanelWdgt
>   form) — a bare `clipsAtRectangularBounds` flag clips only GEOMETRY (hit-tests / dirty
>   rects); the PIXEL crop lives in the mixin's paint traversal. Byte-identity at the default
>   size proven by the whole suite, not argued.
> - **V4 resolved: the pin is `SpreadsheetApp` passing 452×336** — and the old passed 334 was
>   DEAD: the pre-F6 fixed content dictated window height, overwriting 334 to 336 on every
>   arrange, so the on-screen window was ALWAYS 452×336. With fill content the passed extent
>   becomes authoritative: 336 − 36 chrome = 300, 452 − 2×5 padding = 442 — exactly the 6×14
>   grid, pixel-for-pixel.
> - **LANDING DEVIATION — the origin clamp on the visible counts** (`_visibleCols/Rows` =
>   partial clamped to `sheetCols/Rows − viewOrigin`): at the max origin with residual
>   pixels (partial == full + 1 there) the specced bare-partial derivation would
>   materialise/label a column PAST the sheet edge. Consumers: the header build/trim, the
>   materialise loops, the hit-test (pass-1 membership is unaffected — an indexed address is
>   in-sheet by construction). Corollary: header VALIDITY is origin-dependent near the sheet
>   edge, so `_scrollByNoSettle` re-runs the idempotent chrome ensure/trim (a no-op at the
>   default size, where the counts are origin-invariant).
> - The sheet gains `minimumExtent` = headers + one cell (102×40, derived from the
>   constants; an OWN field — the Widget ctor's own 5,5 would shadow a prototype default). A
>   pre-F6 snapshot restores its saved 5,5: harmless, the derivations' `Math.max 1` floor
>   degrades gracefully.
> - **Test-authoring case-law** (also in the new test's provenance): the harness world
>   canvas is 960×440 and the app opens the window with its bottom edge 14px above the
>   world's bottom — growing from there pushes the resizer OFF-CANVAS, where the world clip
>   makes it unhittable (empty `clippedThroughBounds`) and the drag silently no-ops. The
>   test repositions the window to 20,10 (plain no-dwell title-bar drag) before growing.
>   The recapture STUCK-STATE canary fires on this test BY DESIGN (4 shots, 3 distinct
>   frames — image_1 == image_4 IS the round-trip proof), same as the F1 wheel test.
>
> **Verification:** presuite 255/255 dpr1 with ZERO reference changes (the decision-3 hard
> gate — the spec flip + clip mixin + arrange seam + V4 pin are pixel-invisible at the
> default size); `SystemTest_macroSpreadsheetResizeViewport` captured dpr1+dpr2 and
> verify-matched, with the exact-corner round trip byte-identical BY HASH (image_1 and
> image_4 share the same dataHash at BOTH densities) — suite 256; rig rows
> `spreadsheet.roundtrip.resizedViewport` + `.resizedViewportEdge` green on BOTH
> serialization legs, values exactly as designed (dims 10x17/9x16, census 170+1 restored at
> origin 0,5; max-wheel clamp 84 with 160+1 — the origin-clamped bound at work), and `.grid`
> re-grounded through the derivations; close gauntlet 11/11 GREEN in 290s, no retries —
> dpr1/dpr2/webkit 256/256 (the webkit leg green over the new refs = the recapture canary's
> confirmation), zero geometry violations, paint 0 offenders, REVISITS baseline still EMPTY
> (the new arranger is settle-clean, at most one visit per flush), census 0 movers / 1623
> targets (the arranger is arrange-twice idempotent), refs consistent.

**The UX oddity this fixes (owner, 2026-07-17, with screenshot).** Resizing the sheet's
window today: height is CLAMPED, and extra width shows empty backdrop right of the grid —
because the sheet declares itself FIXED-size window content
(`initialiseDefaultWindowContentLayoutSpec` sets `canSetHeightFreely = false`, `grow = 0`;
`preferredExtentForWidth` / `_setWidthSizeHeightAccordingly` always answer the fixed
`_gridWidth()`×`_gridHeight()` — the AnalogClockWdgt pattern, chosen in Phase 2a for
one-cycle settle determinism, pre-scroll). The expectation is a real spreadsheet's: a bigger
window shows MORE of the sheet. F1 made this cheap: the viewport reconcile
(`_reconcileViewportNoSettle`) already materialises/recycles cells for an arbitrary viewport
rectangle parameterized by ORIGIN — F6 parameterizes it by SIZE too.

**Baseline (tree `93ffa63b`, F4 close — grep every symbol before relying on it, they
drift).** `SpreadsheetWdgt`: geometry constants `headerColWidth 34 / headerRowHeight 20 /
colWidth 68 / rowHeight 20 / numCols 6 / numRows 14 / sheetCols 26 / sheetRows 100`;
`viewOriginCol/Row` prototype-default 0 (document state); `_buildChromeNoSettle` (panel +
slot-keyed headers "kind:index", idempotent); `_materialiseCellNoSettle(address, slotCol,
slotRow)`; `_reconcileViewportNoSettle` (pass 1 place/hide/recycle indexed cells, pass 2
materialise+route missing visible addresses; the hidden-rich-cell exemption with the
restore-nil disjunct); `_scrollByNoSettle` clamps to `sheetCols−numCols` /
`sheetRows−numRows`; `_scrollToShowSelectionNoSettle` (minimal include);
`_startEditNoSettle` scroll-follows first; `wheel` (per-axis at-limit escalation against the
same clamps); `_cellAtLocal` (viewport coords, bounds-checked against
`_gridWidth()/_gridHeight()`); `_cellRectLocal(slotCol, slotRow)`. `SheetCellsPanelWdgt`
clips at bounds (PanelWdgt's ClippingAtRectangularBoundsMixin) but currently never crops;
headers are DIRECT sheet children, OUTSIDE the panel (frozen); every grid widget paints its
own top+left edges (crossing rule) and each widget's own paint clips to its OWN rect. The
default grid is exact: 442×300 content = 34+6·68 × 20+14·20 (no residual pixels).

**Design (decided).**
- **The viewport becomes DERIVED from the sheet's applied extent — never stored.** Retire
  the `numCols`/`numRows` prototype constants (a constant that lies is worse than a method)
  in favour of TWO derivation pairs, and route every current consumer to the right one:
  - `_viewportColsPartial: -> Math.max 1, Math.min @sheetCols, Math.ceil((@width() - @headerColWidth) / @colWidth)`
    (and `_viewportRowsPartial` likewise with height/rowHeight) — CEIL: a partially-visible
    column/row counts as on-screen. Consumers: viewport MEMBERSHIP (reconcile pass 1's
    slot-range test + pass 2's materialise loops) and the header-chrome build/trim.
  - `_viewportColsFull: -> Math.max 1, Math.min @sheetCols, Math.floor((@width() - @headerColWidth) / @colWidth)`
    (and `_viewportRowsFull`) — FLOOR: consumers are the SCROLL CLAMPS
    (`_scrollByNoSettle`: max origin = `sheetCols − _viewportColsFull()`), the `wheel`
    at-limit conditions (same expressions), and `_scrollToShowSelectionNoSettle`'s
    right/bottom-edge conditions (the selection must end up FULLY visible — this is also
    what makes `_startEditNoSettle`'s follow put the overlay editor on a fully-visible
    cell, never a clipped one). At the max origin every remaining column is fully visible
    and residual pixels show backdrop — decision (2) falls out for free, at ANY size.
  - At the default size ceil == floor == 6/14 exactly (no residual pixels — see Baseline),
    so every derivation answers today's constants and decision (3) holds structurally.
  - PURITY: the derivations read APPLIED geometry (`@width()/@height()`) — legal at their
    call sites (reconcile/clamps run inside settles AFTER the extent is committed;
    cf. the pure-measure rule "reading applied geometry is allowed when nothing just
    mutated it"). They must NOT be called from `preferredExtentForWidth` (pure measure).
  - `_gridWidth()/_gridHeight()` retire too — `_cellAtLocal` bounds-checks against
    `@width()/@height()`; a click on a PARTIAL cell selects it (v1: NO auto-scroll on
    click — arrows/edit follow, clicks don't; record any deviation here).
- **Layout-spec flip:** `canSetHeightFreely = true`, `grow = 1` (fill-class content) in
  `initialiseDefaultWindowContentLayoutSpec`; `getMinimumExtent` = headers + one cell
  (102×40). `preferredExtentForWidth` and `_setWidthSizeHeightAccordingly` change to the
  fill-content protocol — **V1-verify: read 1–2 EXISTING grow-1, free-height window
  contents and mirror their exact preferred/min/width-grant shape** (candidates: whatever
  `docs/layout-*` names as fill-class; TextWdgt is the fill-class-by-type precedent from
  the sizing-model arc). Respect the sizing-model rules (§9.7-Q B2+D: the container owns a
  container-owned window's width from birth; grow derivation at capture) — land THROUGH
  them, not around them.
- **The resize seam (V2-verify — the highest-risk integration point):** when the window
  grants the sheet a new extent, the sheet must re-derive: panel extent/position, header
  set (build missing slots / destroy surplus — extend `_buildChromeNoSettle` with a TRIM
  pass over `@_headerCells`, same idempotent keying), and the cell viewport
  (`_reconcileViewportNoSettle` — already size-agnostic once its loops read the partial
  derivations). WHERE this runs: the sheet grows a children-arranging layout tier
  (`_positionAndResizeChildren` or `_reLayoutSelf` — decide by READING `Widget._reLayout`'s
  structure + one existing container that derives child geometry from its own bounds, and
  record which; bounds-first discipline: own bounds are applied BEFORE children — the
  inspector-doLayout case-law). It must be IDEMPOTENT (the `fg census` arrange-twice gate),
  visited at most once per flush (`fg revisits` EMPTY baseline), all `_apply*`/NoSettle
  cores, and must preserve the move-follow behaviour the freefloating children get today
  (deriving every child position from `@position()` inside the arranger subsumes
  float-follow — verify a window DRAG still carries the grid, byte-identically).
- **Clipping (V3-verify):** partial cells stick past the panel's right/bottom edge and the
  panel clip crops them — the F5 "standing guard" finally load-bearing. But partial-column
  HEADERS are direct sheet children, OUTSIDE the panel, and would paint past the sheet's
  edge unclipped. Give the SHEET `clipsAtRectangularBounds` (one clip for everything)
  — V3 verifies: (a) byte-identity at the default size (the clip crops nothing when
  everything fits — but a clipping widget changes clippedThroughBounds/broken-rect/shadow
  paths, so PROVE it with the full suite, not by argument; note `firstParentOwningMyShadow`
  stops at clipping widgets — grid children carry no shadows, verify nothing else in the
  window does); (b) the clipped-partial look at a non-quantized size (eyeball via
  `fg diffpage` or the new test's reference).
- **Default window size pinning (V4-verify):** with grow-1 content the default window
  extent must still yield EXACTLY today's 442×300 content so the initial render is
  byte-identical. Find where the launched window's default size comes from today
  (`SpreadsheetApp.buildWindow` → `world.openWindowWith` sizing off the content's preferred
  extent) and pin it explicitly if the flip changes it. The HARD gate for decisions (3):
  the entire existing 255-test suite passes UNCHANGED — zero recaptures.
- **What does NOT change:** the reconcile core + the viewport invariant + the
  hidden-rich-cell exemption (membership just reads the partial derivations); wheel and
  keyboard semantics; serialization — NOTHING new serializes (the viewport derives from
  bounds, which are already document state; a pre-F6 snapshot's fixed bounds restore to a
  6×14 viewport through the same derivations); `sheetCols/sheetRows` and `viewOriginCol/
  Row` untouched.

**Touch-list.** `SpreadsheetWdgt` (spec flip + min extent; the four derivations + constant
retirement; chrome trim; the resize/children-arrange seam; clamp/follow/at-limit/hit-test
consumer routing; clip flag), `SheetCellsPanelWdgt` (comment: clip now load-bearing),
`SpreadsheetApp` (default-size pin if V4 needs it), `src/spreadsheet/CLAUDE.md` (the F1
section's "fixed viewport" language + the panel bullet + a new F6 paragraph), NOMENCLATURE
(register **partial edge cell**; amend **viewport / view origin** to "derived from extent"
— §4 rule 8, at land time), spec §9.1 note; tests repo: the new test(s) + rig rows below.

**Tests.** `SystemTest_macroSpreadsheetResizeViewport`: open at default (screenshot =
byte-identical baseline vs a fresh sheet — proves (3) in-test), drag the window resizer out
by a NON-cell-multiple delta (`dragWindowResizerTo_InputEvents` — the window-chrome verb)
→ assert more cells/headers via the derivations (`evaluateString`), screenshot the partial
edge column/row look; wheel-scroll in the enlarged state (clamps use full-counts — assert
max-origin backdrop); resize back to the exact original corner → `assertScreenshotsIdentical`
with the baseline (integer placement makes the round-trip exact). Consider a second test or
a step for a RICH cell partially visible (a slider clipped mid-body). Park the pointer
(corner header) before every byte-compared shot; expect resize-path dpr2 sensitivity (the
divider-drag sub-pixel case-law) — if dpr2 flakes, quantize the DRAG destination, never the
framework. Rig EXPECTATIONS rows: (a) a RESIZED sheet round-trips (apply a bigger extent +
settle, serialize/deserialize → derivations answer the bigger viewport, census invariant
holds, origin preserved); (b) pre-F6-shaped snapshot (default bounds) restores to 6×14.
Both serialization legs MANDATORY (restore paths change even though the serialized surface
doesn't).

**Done when:** the whole pre-F6 suite green with ZERO recaptures (the default-size identity
— decisions 3); new test(s) + rig rows green dpr1/dpr2/webkit; both legs green; `fg
revisits` baseline still EMPTY + `fg census` green (the new arranger is settle-clean and
idempotent); docs + NOMENCLATURE landed; ledger F6 checked.

**Risks.** The children-arrange seam vs float-follow (V2 — read before writing); the
fill-content protocol purity (V1 — `preferredExtentForWidth` must stay pure, never read
applied geometry); the sheet-level clip's side effects (V3 — prove byte-identity, don't
argue it); default-size pinning (V4); dpr2 resize determinism (case-law above); window
min-extent machinery vs `getMinimumExtent` (verify the consumer). Sequencing: independent
of F3; touches the same `SpreadsheetWdgt` surface as everything else — do not run
concurrently with another spreadsheet arc.

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
   `NOMENCLATURE.md` on any new term of art, `docs/architecture/serialization-duplication-reference.md`
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

- [x] Ledger fully checked; every phase's verification tier recorded. (Arc = Phases 0–7 all
      checked; Phase 8 "widgetise the grid" is the deliberately-separate PLANNED FOLLOW-ON.)
- [x] Full-tier run green; new SystemTests exist for phases 2a–4 (and 5 — the tick hook was
      built, `macroSpreadsheetSecondsCell`); recaptures listed in 6c's + 6d's commits and WebKit-verified.
- [x] §0 phase-close battery green at 2c, 4, 5, 6c, 6d; serialization rig green with the
      sheet / color-cell / widget-cell fixtures and their EXPECTATIONS rows.
- [x] `world.dataflow` drains dark-cheap (empty-pool early return first) — measured typical 1
      pass, peak 2 (`docs/measurements/dataflow-measurements.md`).
- [x] Token machinery deleted (6d); `grep -rn connectionsCalculationToken src` → 0.
- [x] In-phase docs (rule 8) landed as they went: subsystem CLAUDE.mds,
      serialization reference, DETERMINISM.md; Phase 7 completeness pass done.
- [x] Docs closeout (Phase 7) landed; spec marked implemented with deviations.
- [x] `NOMENCLATURE.md` consistent with the shipped names.

# Wire-vocabulary extensions — per-event delivery, cold edges, buffer payloads

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
**Status: AUTHORED 2026-07-24, NOT STARTED. Owner-gated — execute only on owner
instruction, one work item at a time.**

**Mandate:** land the missing wire semantics **as designed, completely** — the deferred
per-event delivery lane, the banked cold-edge attribute, and an honest buffer payload
type — rather than accreting per-app workarounds (bespoke callbacks, node-local event
queues, mutable-blob pins) that each new event-driven or media widget would otherwise
invent. Where an extension is *refused* (audio-rate signals on wires), record the
refusal as a law so it stays refused for a reason, not by omission.

---

## §0 Orientation

Fizzygum is a CoffeeScript live-GUI framework ("web operating system" on one canvas,
Morphic lineage; umbrella workspace `Fizzygum-all/` with sibling repos `Fizzygum/`
source, `Fizzygum-tests/` SystemTests, `Fizzygum-builds/` output; build/test via the
umbrella `fg` wrapper). Widgets are wired to each other by **connections** (a
controller's `@target`/`@action`) and by spreadsheet formulas; both are clients of ONE
dataflow engine, `world.dataflow` (`src/dataflow/DataflowEngine.coffee`), whose
normative contract is **`docs/specs/dataflow-engine-spec.md`** (read §1–§8 + §13 before
any work item; the engine file's class header is the node-protocol contract). The
engine landed 2026-07-06 (implementation record:
`docs/plans/dataflow-engine-implementation-plan.md`) and patch-programming wires were
fully ported onto it (Phases 6a–6d: the legacy token machinery is DELETED — engine
delivery is the only path).

**Why this plan exists now.** `docs/architecture/app-fit-criteria.md` (facet 9,
"wire vocabulary fit") grades candidate apps by whether their inter-part traffic fits
today's wires. The most attractive candidates (step sequencers, counters, instrument
widgets, envelope/waveform editors — the facet's worked examples) need exactly three
things today's wires *almost* provide: **count-preserving event delivery** (a bang per
event, not per cycle), **structured events** (set several fields, then fire once), and
**buffer-valued pins** (a wavetable/sample as a payload). All three have reserved slots
in the engine design; none is live. This plan is the gap-closer.

**The critical reframe** (do not lose this): extending the wire vocabulary is NOT a new
type system. The expensive axis is **edge semantics**, and the engine already reserves
the needed semantics — `bang` = force-fire (landed), `firesPerEvent` = per-event
mini-pass (flag landed, delivery deferred), `cold` = store-without-firing (attribute
carried, never read). Payload types are the cheap axis (one more setter table). The
work is *landing reserved designs*, not inventing machinery.

## §0.5 Cold-execution protocol

1. Read this doc top to bottom. Then read `docs/specs/dataflow-engine-spec.md` §3, §4
   (both lanes + §4.1/§4.2), §5, §8, §13, and the class-header comment of
   `src/dataflow/DataflowEngine.coffee`. Skim `src/dataflow/CLAUDE.md` ("Connections
   client" section) for the 6a–6d landing history.
2. Re-verify §1 below against current code (`grep` the quoted symbols; line numbers
   drift — the method name + quoted code is authoritative).
3. Execute ONE work item (§4) at a time, in its own session, gates per §7. W1, W2, W3
   are independent; do not interleave.
4. Before W1, resolve the D1–D5 design decisions (§4.W1) — they are the §13 "open
   fine print"; record each decision IN THIS DOC as you go.
5. Never edit `src/` mid-suite; verification commands are §7's, run via the umbrella
   `fg` wrapper with absolute paths.

## §1 Current state (verified against src 2026-07-24)

- **Payloads = three setter tables.** `Widget.colorSetters` / `stringSetters` /
  `numericalSetters` (+ the `allSetters` union) — `src/basic-widgets/Widget.coffee`
  (~4555–4590) — populate the connect-to-➜ target-chooser menus. Subclasses chain via
  `super` and `_appendSettersAndDedup` (see `PatchNodeWdgt.stringSetters`).
- **Edge records already carry the policy fields.** `DataflowEngine.addEdge` stores
  `{consumer, action, firesPerEvent, cold}` (constructor comment ~:88, `addEdge`
  ~:118–127). `cold` defaults false and **has zero readers**. `ensureWireEdge` makes
  edge derivation from `@target`/`@action` total (menu wires eagerly, direct-assignment
  wires lazily on first fire).
- **Delivery pools; notifications carry no values.** `markStale(node, forced)` →
  `__poolStale` → `@stalePool`/`@forcedPool` (both `Set`s — so N markings of one node
  in one cycle collapse to ONE entry). The once-per-cycle drain
  (`recalculateDataflow`, called from `WorldWdgt.doOneCycle` between
  `_runChildrensStepFunction` and `recalculateLayouts`; event handlers run earlier in
  `_playQueuedEvents`, ~WorldWdgt:1847–1867) snapshots the pool, computes the
  downstream closure, orders it (Kahn + one-lap-from-entry), walks it once with the
  equal-value cutoff, and opens **one layout settle per pass**
  (`_drainOnePass` → `world._settleLayoutsAfter`, spec §4.2 item 5).
- **`bang` = force-fire, landed.** `FanoutPinWdgt.bang` → `world.dataflow.markStale @,
  true`; `PatchNodeWdgt.bang` → `updateTarget true` → same. `forced` rides
  `@forcedPool` and exempts the node from the equal-value cutoff in `_processNode`
  (`forcedSet.has(node) or not @_valuesEqual …`). **But the pools are Sets: two bangs
  in one cycle = one forced fire.** Count-preserving delivery does not exist today.
- **`firesPerEvent` = landed DARK.** Per-wire prototype-default `false` on
  `ControllerMixin` (~:71–95) with the shared "fires per event" menu toggle
  (`addFiresPerEventMenuEntry`/`toggleFiresPerEvent`); the flag rides the edge record.
  The deferral note lives in `DataflowEngine.markStale` (~:271–274): delivery POOLS
  regardless because (a) the two lanes are screen-indistinguishable (paint is once per
  cycle), (b) no test exercises per-event delivery, (c) a synchronous scoped mini-pass
  fights the drain's per-pass settle-open — spec §13's open point: "per-event
  mini-pass downstream scoping fine print (per-wire vs per-source)".
- **Echo suppression exists and matters here.** While the engine applies an edge into
  a node (`@_applyingNode`), that node's own onward-fire tail re-marking itself is
  dropped (spec §1.13) — a driven ring drains in one pass. Any mini-pass must preserve
  this.
- **The cold-inlet idiom half-exists node-side, vestigially.**
  `DiffingPatchNodeWdgt._inputSetterMenuEntries` exposes paired plain/`Hot` setters
  (`setInput1`/`setInput1Hot` …) — but since 6b replaced the freshness gate with
  any-input-marks-stale, ALL of them call `@updateTarget()` (mark stale): the pairs
  are behaviourally identical today. Riders for W2: `DiffingPatchNodeWdgt.setInput2`
  assigns `@input1` (a real, pre-existing bug); the `setInput*IsConnected` prototype
  flags on all three patch nodes are **written** (by
  `ControllerMixin.setTargetAndActionWithOnesPickedFromMenu`) **but read nowhere** —
  their reader was the deleted freshness gate.
- **Value equality suits immutable payloads already.** `_valuesEqual: (a, b) -> if
  a?.equals? then a.equals b else a is b` — identity for anything without `.equals`.
- **The serializer has no typed-array arm.** `grep Float32Array|Uint8ClampedArray|
  ArrayBuffer src/serialization/` = 0 hits (2026-07-24). Buffer payload serialization
  is genuinely unbuilt.
- **Generation-stamp precedent for coarse invalidation of big pixel state:**
  `WorldWdgt.immutableBackBufferGeneration` consumed by
  `TransformFrameWdgt._islandBufferGeneration` (~:39, :443–446).

## §2 Why it is shaped this way

Pooling + pull is deliberate and load-bearing for VALUES (spec §3): ten drag events
collapse to one recompute reading the final value — lossless for current-value
semantics, merge-free, deterministic (pool insertion order = event order). The
per-event lane was speced alongside it (§4) precisely because pooling is *lossy for
event counts*, then deferred because nothing shipped needed counts and the
settle-scoping question was honestly open. `cold` was banked under §13's "whether any
patch idiom actually needs cold edges before building them" — no customer existed.
This plan's candidates (counters, sequencers, note-on-style structured events) are
those customers arriving.

## §3 The distilled argument

- **Events are the one missing semantic for a whole app class.** Everything else those
  apps need (pins, dataflow, duplication, determinism) already works. A bang that
  coalesces is fine for "refresh"; it is wrong for "count", "step", "trigger note".
- **The engine's own design already answers the hard parts.** Synchronous mini-pass ⇒
  no queue, no in-flight state across a cycle boundary ⇒ nothing new to serialize and
  determinism stays a pure function of the event stream. Discovery already exists
  (`bang!` rides the setter tables). Cold edges are speced as "strictly more
  expressive than the gate" (§8).
- **Structured events need no record payload.** The Pure-Data idiom — set cold inlets,
  then one hot bang — composes cold edges + per-event bangs into atomic multi-field
  events (a note-on: cold `pitch`, cold `velocity`, hot `bang`), entirely within the
  scalar payload vocabulary.
- **Buffers-as-documents are current values, not events.** A wavetable/sample/envelope
  wants latest-wins semantics; identity equality is correct once buffers are
  replace-don't-mutate. Only *deadline* traffic (live audio quanta) breaks the model,
  and that stays below the floor by law (W4).

## §4 Work items

### W1 — land `firesPerEvent` per-event mini-pass delivery (the core item)

**Goal:** `markStale` reached via a `firesPerEvent: true` wire outside a drain runs a
synchronous, scoped mini-pass inside the event, delivering per event (count-preserving,
ordered); pooled wires are byte-identical to today.

**Design decisions to resolve first (record answers here):**
- **D1 — scoping:** per-wire (traverse only the marked producer's `firesPerEvent`
  out-edges' downstream) vs per-source (full downstream closure of the producer).
  Spec §4 says "scoped to that wire's downstream"; mixed fan-out (one per-event edge,
  one pooled edge from the same producer) must deliver per-event on the first and
  pool the second — argues per-wire.
- **D2 — settle:** the mini-pass runs during `_playQueuedEvents`, inside an input
  event's own dispatch. Reuse `_drainOnePass`'s shape: one
  `world._settleLayoutsAfter` (which JOINS an enclosing settle if the event handler
  opened one — `_settleLayoutsAfterOrJoinEnclosingPass` semantics) around the scoped
  walk. This is the §13 "fights the per-pass settle-open" knot: the answer must keep
  rule [E] (no phase-valve in immediate mutators) intact.
- **D3 — pool hygiene / no double delivery:** after a mini-pass, the seed and
  mini-pass-delivered nodes must not ALSO fire in the cycle drain. For values the
  equal-value cutoff absorbs the re-fire, but a FORCED (bang) marking would re-fire at
  the drain — the mini-pass must consume the seed's forced/pooled marking for the
  per-event lane while leaving pooled-lane co-edges pooled.
- **D4 — re-entrancy:** a mini-pass IS a drain in miniature; set
  `@_recalculatingDataflow` during it so nested markings demote to the pool
  (drain-until-quiet then happens at cycle end), preserving the "never re-enter"
  invariant and the echo suppression via `@_applyingNode`.
- **D5 — cost/determinism posture:** per-event is N× evaluation by design (user opts
  in per wire); all timing derives from event time (`world.dateOfCurrentCycleStart` /
  event timestamps), never wall-clock — DETERMINISM.md binds.

**Acceptance vehicle:** an event-hungry consumer. Build the minimal
`CounterPatchNodeWdgt` (spec §4 names counters as the motivating client): output = a
count, incremented per delivered `bang`. Macro tests: (t1) source bangs 3× in one
cycle → pooled wire counter reads 1, per-event wire counter reads 3; (t2) the °C↔°F
ring stays 1-pass and frame-identical (regression); (t3) mixed fan-out per D1.

### W2 — cold edges + the structured-event idiom (first customer decides the design)

**Goal:** a per-wire `cold` attribute (menu toggle beside "fires per event") meaning
*store the delivered value on the consumer without marking it stale*; the consumer
fires only when a hot edge (typically a per-event `bang`) arrives — the cold-then-hot
idiom = atomic multi-field events (note-on: cold pitch, cold velocity, hot bang).

**Engine sketch (decide at implementation):** the natural shape is: a producer's
change still *applies* its cold out-edges' values (store via the action's
`_<action>Connector`/bare-mutator routing, exactly `_applyWireValue`) but cold edges
are excluded from downstream-closure traversal, so the consumer neither recomputes nor
propagates. Options for WHEN the store happens: (a) eagerly during the producer's
`_processNode` (walk its cold out-edges after `changed`), or (b) treat cold edges as
closure-terminal but still apply-on-changed-producer in `_applyIncomingWireEdges`
(requires the consumer to be visited — it isn't, absent a hot path — so (a) is likely
right). Verify against spec §8's "cold edge: updates the stored input, doesn't mark
stale".

**Riders (do in the same item):** fix `DiffingPatchNodeWdgt.setInput2`'s `@input1`
assignment bug; retire the written-never-read `setInput*IsConnected` flags (writer:
`ControllerMixin.setTargetAndActionWithOnesPickedFromMenu` guard — keep the guard, it
no-ops without the field, delete the prototype fields) and rationalize the now-
redundant plain/`Hot` setter pairs once `cold` is a wire attribute (the per-NODE
hot/cold vocabulary dissolves into the per-WIRE attribute; check menu-label screenshot
impact — connect-to-➜ menus appear in patch tests).

### W3 — buffer payloads as current values

**Goal:** a buffer (wavetable / sample / envelope / image-strip) can ride a wire as an
ordinary current value.

- **Value contract:** a `BufferValue` handle wrapping the typed array, IMMUTABLE by
  law — publishing a change means publishing a NEW handle (replace-don't-mutate), so
  `_valuesEqual`'s identity arm is already a correct cutoff. For producers backed by
  an in-place-mutated store (a paint surface), the handle carries a `generation` and
  defines `equals` as (backing identity, generation) — the
  `immutableBackBufferGeneration` precedent. Never deep-compare samples.
- **Discovery:** a fourth setter table `bufferSetters()` on `Widget`, chained exactly
  like the existing three (and joined into `allSetters`); target-chooser menu offers
  it only to controllers that produce buffers.
- **Spikes before committing the design:**
  - **S1 serialization:** the serializer has NO typed-array arm today. Decide encoding
    (base64 chunk vs array) + size posture; wire both serialization rigs
    (`serialization-roundtrip-headless.js` / `-file-`) with a buffer-carrying fixture.
    Big assets may alternatively serialize as a re-derivable source reference with the
    buffer a rebuild-on-load transient (`docs/architecture/serialization-duplication-reference.md`
    — the `rebuildDerivedValue` pattern).
  - **S2 duplication policy:** default = the handle deep-copies with the group
    (correct for independent copies); a deliberately-SHARED asset class instead sets
    `keptByReferenceOnDeepCopy: true` (existing mechanism — `Wallpaper`,
    `WidgetFactory`, the engine itself). Owner picks the default.

### W4 — the deadline law (a recorded refusal, not code)

Continuous signals with a hard deadline (live audio quanta ≈ 2.9 ms at 44.1 kHz vs the
~16 ms, deliberately non-realtime world cycle) **never ride wires**. The sample pump
lives below the native floor (WebAudio graph, schedule-ahead); wires above carry
buffer VALUES (W3), control scalars, and bangs (W1). Offline/chunked pipelines (no
deadline) reduce to W3 buffer values per cycle — allowed. **Landing:** when W1–W3
land (or the first audio widget arrives, whichever first), this law goes into the
spec/architecture docs as durable residue per the docs filing rules; until then this
plan is its home. Do not build signal-rate wire scheduling; if genuinely wanted one
day it is its own arc (an AudioWorklet-side graph mirrored from widget wiring), not a
stretch of this one.

## §5 Sequencing and gates

W1, W2, W3 are mutually independent; any order. The full structured-event idiom
(count-preserving note-on) needs W1+W2 both. W4 is a standing constraint on all of
them. Each work item: own session, own commit(s), owner sign-off before starting the
next. Owner gate on the whole plan: not started until owner says so.

## §6 Central risks

- **Double delivery (D3)** — the mini-pass and the cycle drain both firing a banged
  node. The forced-marking consumption rule must be exact; t1/t2 in W1 gate it.
- **Settle interplay (D2)** — a mini-pass opening a settle inside an event handler
  that already has one. Must JOIN (the `_<action>Connector` lane's existing
  discipline), never nest a second flush; capstone/settle gauntlet legs gate it.
- **Determinism under load** — per-event delivery multiplies work inside heavy cycles;
  all consumers must derive state from event data/time only (DETERMINISM.md's
  bug-class). The dpr2 + webkit gauntlet legs are the oracle.
- **Menu/screenshot churn (W2 riders)** — setter-menu entries appear in patch-node
  connect menus; label changes ⇒ recaptures. Enumerate with `fg diffpage` before
  recapturing (`fg recapture --auto` after a FRESH build).
- **Serializer scope creep (W3 S1)** — typed-array support touches the serialization
  reference doc + both rigs; keep it a spike with its own verdict before landing.

## §7 Verification protocol (per work item)

1. `/Users/davidedellacasa/code/Fizzygum-all/fg build` — 0 violations, `done!!!`.
2. `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` — inner loop while
   iterating (~3.5 min).
3. New/changed macro tests authored per `Fizzygum-tests` conventions
   (`/author-macro-test`); W1's t1–t3 are mandatory, not optional.
4. `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet` at each landing —
   all legs; the serialization leg is non-negotiable for W3 (and for W2 if patch-node
   prototype fields change).
5. Long runs: launch in background with a log + verdict file; never foreground-poll.

## §8 Rejected alternatives — do not re-attempt

- **Queued / cross-cycle event delivery (mailboxes, deferred event queues):** breaks
  the no-in-flight-state property that makes serialization and duplication trivially
  correct, and re-imports the merge/ordering problems pooling was designed to avoid.
  The synchronous mini-pass is the designed shape (spec §4); stay on it.
- **A record/struct payload type for events:** unnecessary — cold-then-hot composes
  structured events from scalar pins (spec §8 calls cold edges "strictly more
  expressive than the gate"); a record type would need its own setter family, menu UI,
  equality, and serialization for zero added expressiveness here.
- **Audio-rate signal wires above the floor:** the world cycle is frame-paced and
  deliberately not hard-real-time (DETERMINISM.md heavy-cycle case law); W4 is the
  law. PD/Max make the same message-vs-signal split.
- **Resurrecting token/freshness machinery for event ordering:** deleted in Phase 6d
  (`connectionsCalculationToken`, `allConnectedInputsAreFresh` — the §8 deadlock);
  visit-once + cutoff + (new) per-event scoping own termination/ordering.
- **Mutable buffer payloads with deep equality:** deep compares don't scale and
  in-place mutation is invisible to the engine; immutable handle + identity/generation
  instead (W3).

## §9 References

- `docs/specs/dataflow-engine-spec.md` — §3 verbs/values, §4 two lanes + drain
  placement, §5 re-entrancy, §8 patch client (bang, cold edges), §13 open questions.
- `src/dataflow/DataflowEngine.coffee` (class header + `markStale` deferral note),
  `src/dataflow/CLAUDE.md` (6a–6d landing record), `src/mixins/ControllerMixin.coffee`
  (`firesPerEvent` block), `src/patch-programming/*` (bang, setter tables, W2 riders).
- `docs/architecture/app-fit-criteria.md` facet 9 — the demand side (which apps this
  unlocks) and the payload-vs-edge-semantics framing.
- `docs/architecture/serialization-duplication-reference.md` — W3's S1/S2.
- `docs/plans/dataflow-engine-implementation-plan.md` + 
  `docs/measurements/dataflow-measurements.md` — build record + convergence numbers.
- `../Fizzygum-tests/DETERMINISM.md` — binding for W1/W3 consumers.
- `docs/BACKLOG.md` — this plan's items live under its section.

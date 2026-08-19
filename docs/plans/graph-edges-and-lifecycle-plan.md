# The widget graph — three edge kinds, one lifecycle

**Written to be executed COLD by an LLM/engineer with ZERO prior context. The §5 owner decisions
are RATIFIED (2026-08-18); §4.2 LANDED the same day (see its "As landed" block). What remains is
§4.3 — the whole-graph collector, the second wave (G3: own session).**

**STATUS: AUTHORED 2026-07-18; §4.1 (the `@target` → `referencedWidget` rename) LANDED 2026-08-16
via the sibling [`connector-ubiquity-and-reflection-plan.md`](../archive/connector-ubiquity-and-reflection-plan.md)'s
P9 (that plan's P9 section carries the full receipt — it also renamed the inspector's overload to
`inspectedObject`). REVISED TO EXECUTABLE SHAPE 2026-08-18: every §2 claim re-verified against src,
and the connector arc's re-homed **§P10(b) (command-edge indexing) now lives HERE, as §4.2(b) /
decision G4** — the archived connector plan's open question 8 says it "is answered there or
nowhere", and it is now answered (G4, no index; landed with §4.2). §4.3 remains unstarted.**
Anchor on **symbol names** (all verified 2026-08-18); line numbers drift — grep the quoted symbol
fresh before trusting any location. Self-contained.

Part of one program with [`onion-widget-composition-plan.md`](../archive/onion-widget-composition-plan.md),
[`container-regularization-plan.md`](../archive/container-regularization-plan.md) (closed + archived),
[`creation-and-templates-plan.md`](creation-and-templates-plan.md), and
[`reference-widgets-plan.md`](reference-widgets-plan.md). **This arc supersedes the referent-link rename +
garbage-collection sections of the reference plan** (it does them properly, at the graph level). North star:
orthogonalisation, de-byzantination, regularity.

**Mandate.** Eliminate the underlying irregularity — three edge mechanisms with no common vocabulary
and a lifecycle question answered differently (or not at all) per edge kind — rather than bolting a
fourth mechanism beside them. §4.2 introduces no new state and no new serialization; §4.3 changes
the classifier's *coverage*, not its station or its filing semantics (unless G6/G7 decide otherwise).

---

## 0. Cold-execution protocol

1. Read this whole doc. Do not touch code before §5's decisions carry owner answers.
2. Re-verify §2 against src (grep every quoted symbol; ~15 min). If anything drifted, fix §2 first.
3. Execute §4.2 (with the G4/G5 answers) as one arc: protocol + contributors + the §4.3-independent
   consumers, gated per §8. Commit point only after `fg gauntlet`.
4. §4.3 is a SECOND arc (G3): do not start it in the same session that lands §4.2.
5. Standing rules: never edit `Fizzygum-builds/`; `fg` by absolute path; present commit messages and
   wait for owner OK.

---

## 1. The idea

Widgets are wired to each other by **three kinds of edge**, and today they are three unrelated mechanisms.
Make them one **first-class, named, queryable edge model** — and widget **lifecycle / garbage collection
falls out as a single reachability question** over the union of the three.

| Edge | Meaning | Direction/semantics |
|---|---|---|
| **containment** | "is inside" | the widget tree; a parent owns its children |
| **target / action** | information flows *down* to another widget | dataflow (`@wires`, a list of `WireSpec`) / button commands (`ButtonWdgt.@target` + `@action`) |
| **reference** | "points at, brings up" — carries **no** information | a shortcut/minimised/folder pointing at its referent |

Within target/action, two sub-kinds with different plumbing: a **flow** edge (a `WireSpec` — indexed
in the engine, traversed by the drain, delivers values) and a **command** edge (a button's
`@target`/`@action` — dispatched only on click, indexed nowhere, delivers nothing on its own). The
command sub-kind is what the connector arc's §P10(b) re-homed here.

The 2016 *Reference morphs* note stated the payoff exactly: *"the way we determine which morphs can be
destroyed depends on the combination of three types of links: reference, target, children."* A widget is
**destroyable exactly when it is unreachable via containment ∪ target ∪ reference** from the roots. One
reachability walk, three edge sets.

The naming discipline that makes it legible: a **reference is not a target.** A *target* sends information
down (dataflow/commands); a *reference* just points. `@target` used to be **overloaded** to mean both — §4.1
gave the reference edge its own field, **`referencedWidget`** (landed; see the status line).

---

## 2. Current-state truth (every bullet re-verified against src 2026-08-18)

Three separate, non-uniform mechanisms; reachability is computed, but only over one of them:

- **containment** — `TreeNode.children` / `.parent` (`src/basic-data-structures/TreeNode.coffee`);
  the tree `Widget` sits in. A widget with no owner is never drawn.
- **flow (target/action, indexed)** — `ControllerMixin` holds `@wires`, an ordered list of `WireSpec`
  records ("I drive `action` on `target`", plus per-wire policy; `action` is a **string method
  name**). The engine index (`DataflowEngine.@edgesFrom`: producer → Set of
  `{consumer, action, firesPerEvent, cold, firesOnAnyChange}` records, plus the reverse `@edgesTo`)
  is **derived, never serialized**, and mirrored from the wire lists by
  `world.dataflow.ensureWireEdges` — called both eagerly (`ControllerMixin._addWire`) and lazily
  (`_fireConnection`, so a directly-constructed wire declares its edge on first fire). ⚠ The index
  also carries **`firesOnAnyChange` re-reading subscriptions** (a fonts menu tracking a text, a
  scrollbar tracking its panel) that are consumer-declared, **not in any `@wires` list**, and spared
  by the wire-reconciler — an "edge in the index" is NOT the same population as "a declared wire".
- **command (target/action, unindexed)** — `ButtonWdgt.@target` + `@action` (+ `@doubleClickAction`,
  `@subjectOfAction`), dispatched as `@target[@action]` in `trigger`. ⚠ Three facts that shape G4:
  `@target` is a bare constructor-assigned field with **no write funnel** (menu machinery fills
  `subjectOfAction` after construction; nothing routes `@target` writes through a setter); buttons
  are **mass-created and mass-destroyed** with every menu open/close; and **nothing anywhere queries
  "which buttons command X"** today.
- **reference** — `IconicDesktopSystemShortcutWdgt` (+ the Document/Folder/Script shortcut
  subclasses) holds its referent in **`referencedWidget`** and registers in the world-level Set
  **`world.widgetsReferencingOtherWidgets`** (a class-level field on `WorldWdgt`); `bringUpTarget()`
  re-summons the referent (⚠ the method name still says "Target" — pre-§4.1 residue; renaming it is
  a cross-repo grep per the P9 lesson, optional). Tracker hygiene is by **destroy-hook
  self-removal** (`IconicDesktopSystemShortcutWdgt._destroyNoSettle` deletes itself and calls
  `world.noteStorageMembershipMayHaveChanged()`), NOT by any teardown clear —
  `WorldWdgt._teardownWorldStructureNoSettle` never touches the Set; it relies on
  `fullDestroyChildren()` + `binWdgt/shelfWdgt.empty()` (both of which fullDestroy residents)
  cascading through that hook. `BinOpenerWdgt` and the demo `PointerWdgt` point at widgets
  **deliberately outside** the tracker (documented in each).
- **Reachability — partial, reference-only, filing-only:** `StorageSorter` (`src/StorageSorter.coffee`)
  is a `doOneCycle` drain station (`drainPendingSort`, between the dataflow drain and the layout
  flush; marked pending by `world.noteStorageMembershipMayHaveChanged()` at chokepoints; dark-cheap
  when nothing is pending). Its `_runClassifier` is precisely this, not a root-down tree walk:
  - pass 1: a tracker member that is an orphan (`isOrphan()`: root is neither world nor hand) and
    NOT in storage (`isInStorage()`: not under `binWdgt`/`shelfWdgt`) is unreachable — mark visited,
    it confers nothing.
  - pass 2: every other not-in-storage tracker member is attached, hence reachable **by
    implication of attachment** — seed: `referencedWidget.markItAndItsParentsAsReachable` (marks
    UP the parent chain with a fresh `world.incrementalGcSessionId`, stopping at the storage-container
    boundary).
  - furniture: `Serializer.WORLD_APP_SLOTS` (5 world fields) + `world.simpleEditorTemplates` are
    marked — off-tree singletons reachable through world fields, not the tracker.
  - pass 3 fixpoint: a storage-resting tracker member whose ancestors became reachable
    (`isInStorageButReachable`) relays reachability to ITS referent; iterate until no new member.
  The drain then re-files each top-level storage resident between `world.binWdgt` (lost) and
  `world.shelfWdgt` (reachable). **Wires and command edges are invisible to it** — it iterates the
  reference tracker only. Nothing is ever *destroyed* by it, only re-filed. The always-on
  `_auditStorageNoSettle` (`STORAGE_INVARIANT` console tokens, gated by the headless runners + the
  `fg gauntlet` `storage` leg) polices the filing invariant at drain exit and at resetWorld's end.
- **The lifecycle question is ALSO answered per-widget, ad hoc, reference-only:**
  `world.anyReferenceToWdgt` (a linear scan of the tracker) gates close/destroy decisions in THREE
  call sites — `ScriptWdgt`, `FolderWindowWdgt`, `FrameWdgt` (twice) — "if nothing references me,
  really destroy; else park". A wire or a button commanding those widgets does not count today.

**Gaps** (each verified live): the three edges have no common vocabulary or enumeration; reachability
is storage-local and reference-only (a bin resident TARGETED BY A LIVE WIRE files as lost while
still being driven; a closing `FrameWdgt` asks only about references); the serialization posture
differs per edge and is nowhere stated as a policy (children structural; wires serialized as
`@wires` with the index derived; `referencedWidget` serialized plus tracker membership via the
serializer's `"referenceTracker"` extra, restored by the `Deserializer`; button `@target` serialized
as an ordinary property reference). ⚠ One verified-open lifecycle raggedness to settle in §4.3:
`Widget._destroyNoSettle` removes the DYING node's engine edges (`world.dataflow?.removeAllEdgesOf @`),
but **nothing prunes a living controller's `@wires` record whose target died** — the next
`ensureWireEdges` on that producer re-declares an edge onto the destroyed widget (consequence
untested; needs a spike, not an assumption).

---

## 3. Architecture we MUST respect

- **Serialization posture per edge is load-bearing.** Containment is serialized structurally; the
  dataflow index is **derived, never serialized** (rebuilt eagerly/lazily from `@wires`); the
  reference edge is a serialized field + the `"referenceTracker"` membership extra. §4.2 must add
  NO new serialized state — the edge protocol is a *read* of what already persists. See
  `docs/architecture/serialization-duplication-reference.md`.
- **Determinism.** Under the Automator the clock is **event time**, never wall-clock; anything that
  runs per-cycle must be a pure function of the edge sets (`Fizzygum-tests/DETERMINISM.md`). The
  existing once-per-cycle eager drain is proven deterministic; *"incrementally across frames"* (the
  2016 note's wish) is a determinism risk to take only deliberately (G7).
- **⚠ World-level edge state is test-sensitive — the top risk class of this arc.**
  `world.widgetsReferencingOtherWidgets` stays honest through destroy hooks, not teardown clears;
  the bin and shelf survive `ResetWorld` by design and have prior gate-false-positive case-law
  (`docs/archive/upedge-endgame-plan.md`); an un-cleared world-level Set is the classic
  "passes-alone-but-mis-renders-in-suite" leak (memory: *resetWorld state leak between tests*; the
  `RESETWORLD_INCOMPLETE` ratchet fingerprints world state values). **Every new world-level
  collection this arc is tempted to add must instead be derived or walked** — that temptation is
  rejected twice below (G4, §4.3 registry).
- **The dataflow engine already models a graph** — the flow edge keeps `world.dataflow` as its ONE
  index (G2: don't fork a second value-edge store). Its design: `docs/specs/dataflow-engine-spec.md`.
- **Naming/tiers** as in the program (`*Wdgt`, `_`/`__`, `*NoSettle`, composed protocols via
  `super`-chains like `pins()`).

---

## 4. Proposals

### 4.1 Give the reference edge its own field: `@target` → `referencedWidget`. ✅ **LANDED 2026-08-16**
On `IconicDesktopSystemShortcutWdgt` (+ subclasses) rename the referent link from the overloaded `@target`
to **`referencedWidget`**, leaving `@target` to mean information-flow only. Landed as the sibling connector
plan's P9 (which disambiguated all four `@target` meanings in one sweep, `inspectedObject` for the
inspector's) — `IconicDesktopSystemShortcutWdgt.coffee` now declares `referencedWidget` and constructs from
it. Nothing of 4.1 is left to do.

### 4.2 Name the three edges as one vocabulary. *Consolidation — v1.* ✅ **LANDED 2026-08-18.**

As landed: `Widget.graphEdgesOut` (base, `[]`, beside the pins protocol) + three contributors —
`ControllerMixin` (wires → flow; the mixin-DSL `super()` resolves through `Mixin._equivalentforSuper`
to the injected class's superclass, so the chain composes), `ButtonWdgt` (command — gated by the
CAPABILITY probe `@target?.graphEdgesOut?`, not `instanceof`: exactly the receivers that answer the
protocol are graph citizens, and a dispatch receiver may be any object), and
`IconicDesktopSystemShortcutWdgt` (reference — guarded for the deserialization shell). The
`target:`-field sweep (14 declarations) confirms the contributor set: `WireSpec.target` rides the
flow contributor; the rest are ephemeral chrome pointers (HandleWdgt, PromptWdgt/CodePromptWdgt,
CaretWdgt, ListWdgt, MenuItemSpec/MenuRowsPanelWdgt, ConsoleWdgt) or documented-outside cases
(BinOpenerWdgt, the launcher — WORLD_APP_SLOTS furniture — and the demo PointerWdgt), deliberately
not edges. Probe: `Fizzygum-tests/.scratch/graph-edges-probe.js` (10 assertions incl. the G5
subscription exclusion and the capability gate — all green); guideline § "Declaring a graph edge".

**(a) The edge-enumeration protocol.** One composed, queryable protocol on `Widget`, mirroring the
`pins()` composition precedent (a subclass/mixin contributes via `super`):

```coffee
# Widget — the non-containment edges I hold OUT of myself: [{kind, to}], kind one of
# 'flow' | 'command' | 'reference'. Containment is deliberately not enumerated here —
# the tree is its own, richer API (children/parent), and every consumer of this
# protocol treats the subtree specially anyway.
graphEdgesOut: -> []

# ControllerMixin — my declared wires (the serialized truth), NOT the derived engine
# records: the index also carries consumer-declared firesOnAnyChange subscriptions
# that are nobody's declared relationship (G5).
graphEdgesOut: -> super.concat ({kind: 'flow', to: w.target} for w in (@wires ? []))

# ButtonWdgt — my command edge, when I have one (G4: enumerated lazily, indexed nowhere).
graphEdgesOut: -> if @target? then super.concat [{kind: 'command', to: @target}] else super

# IconicDesktopSystemShortcutWdgt — my reference edge.
graphEdgesOut: -> super.concat [{kind: 'reference', to: @referencedWidget}]
```

Derived, allocation-per-call, zero new state, zero serialization change, zero behaviour change.
(Exact record shape and whether `action`/wire policy ride along are executor's choice; the kind tag
and the `to` widget are the contract.) `SwitchButtonWdgt`/other `@target`-carrying button subclasses
inherit `ButtonWdgt`'s contributor; a grep for other bare `target:` declarations
(`grep -rn "^  target: undefined" src/`) closes the sweep.

**(b) Command edges — the re-homed connector §P10(b).** The archived connector plan's question 8:
*"index button `@target`s in `world.dataflow` as non-traversed command edges, or leave the button
edge unindexed until the unified collector arc actually needs it?"* **Recommendation: do NOT index
— the (a) protocol IS the command edge's realisation** (decision G4). Grounds, each verified in §2:
an eager index needs a write funnel `ButtonWdgt.@target` does not have; buttons churn with every
menu open/close, so the index would be the busiest and least interesting edge population in the
world; a standing index is exactly the world-level-collection risk class §3 bans; no consumer of a
reverse command query exists; and §4.3's walk needs only forward enumeration from reachable
widgets, which (a) provides. G2's "one graph index, not two" is honoured trivially: there is no
second index. If a reverse query ("which buttons command X?") ever earns a consumer, THAT arc adds
the index behind the same protocol without touching callers.

**(c) §4.3-independent consumers, same arc** (small, prove the protocol pays before the collector
lands): re-express `world.anyReferenceToWdgt`'s scan in edge terms is NOT worth it (the tracker is
the right index for that query — leave it); the real (c) deliverable is documentation + the
`graphEdgesOut` protocol under test: a headless probe asserting each contributor's records against
a constructed fixture (wire + button + shortcut), and a `widget-authoring-guidelines.md` §-entry
("declaring an edge kind" = contribute to `graphEdgesOut`). No behaviour change anywhere in 4.2.

### 4.3 One reachability collector over the union. *The payoff — second wave (G3).*

Generalize `StorageSorter._runClassifier` from "reference tracker only" to **containment ∪ flow ∪
command ∪ reference**, keeping its station, its session-id marking, and its filing semantics:

- **Roots (as they truly are today, §2):** attachment to world/hand (implicit), plus the
  `Serializer.WORLD_APP_SLOTS` + `world.simpleEditorTemplates` furniture. Not "desktop" as a
  separate root — the desktop is in the world tree.
- **The generalized mark:** where pass 2/3 today follow only `referencedWidget`, the collector
  follows every `graphEdgesOut` record of every widget in a reachable SUBTREE (the current
  classifier's up-the-parents marking, `markItAndItsParentsAsReachable`, stays exactly as is — an
  edge INTO a nested widget makes the containing storage resident shelf-worthy).
- **Enumeration source:** pass 2's seed set can no longer be "iterate the tracker" — wires and
  buttons have no registry. The collector **walks the world tree + hand + furniture subtrees
  collecting edges** on each drain. Rejected alternative: a world-level registry of edge-holding
  widgets — that is the §3 top-risk state class, and the walk is O(world tree) only on drains that
  actually fire (membership-change chokepoints), which the bin/shelf arc already showed is rare.
  If measurement ever says otherwise, the registry can be reconsidered WITH its teardown story.
- **Filing, not destroying (G6).** The 2016 note's "destroyable" predates the bin: today the bin IS
  the user-visible graveyard, rescue included, and `fg storage` gates its invariant. The collector
  keeps re-filing between bin and shelf; destruction remains a user act (emptying the bin) or a
  future retention policy — out of scope here.
- **Eager, not incremental (G7).** Keep the once-per-cycle drain; bounded-chunk cross-frame marking
  buys nothing measurable today and buys real determinism risk. Record the note's wish as satisfied
  by the *station* (work happens off the hot path, once per cycle, dark-cheap when idle).
- **Settle the §2 dead-target-wire raggedness** here, with a spike first: reproduce (destroy a
  wire's target, fire the producer, observe `ensureWireEdges`/the drain), then decide whether the
  fix is pruning `@wires` in the target's destroy path (mirroring the tracker's destroy-hook
  pattern) or a liveness guard at delivery. Whatever lands, `anyReferenceToWdgt`'s three close-path
  call sites should be re-examined against the unified model (does a live wire/command into a
  closing frame now argue "park, don't destroy"? — an owner semantics question, flagged G8).

### 4.4 (bank) Reference-counting is NOT the mechanism.
Record the note's ruling so no one re-adds it: reference-counting the reference edges is **not** used
(reachability over the three-edge union is the truth); back-links from referent → reference exist only when
a UI needs them (e.g. an icon must update), never for GC.

---

## 5. Owner decisions

**RATIFIED 2026-08-18 (owner), all as recommended.** G8's final form: split by edge kind — a live
**wire** into a closing widget argues *park, don't destroy* (user-authored, serialized state); a
**command** edge does not (button chrome is ephemeral, and the closing gesture's own button targets
the widget, so "any command edge into me?" is self-referentially true at close time and can never
gate anything). Concretely: `anyReferenceToWdgt` at the three close sites generalizes to "any
reference *or wire* keeping me alive" when §4.3 is worked.

| # | Decision | Recommendation |
|---|---|---|
| G1 | Scope for v1 | **4.2 only** (protocol + contributors + probe + docs; 4.1 already landed). 4.3 is the second wave. |
| G2 | Reuse the dataflow index for the flow edge? | **Yes** — `world.dataflow` stays the ONE value-edge index; `graphEdgesOut` *reads* `@wires`, forking nothing. |
| G3 | Whole-graph GC vs keep storage-local | Whole-graph is the goal (4.3), but it's the riskiest piece (test-state, determinism) — gate hard, land after 4.2, own session. |
| G4 | **(was connector §P10(b))** Command edges: eager `world.dataflow` index vs lazy enumeration | **Lazy** — the §4.2(a) protocol is the command edge; no funnel exists for `@target` writes, menus would churn the index, no reverse-query consumer exists, and §4.3 needs only forward enumeration. Index later IF a consumer appears. |
| G5 | Which flow edges confer liveness | **Declared `@wires` only** — the serialized truth. Derived `firesOnAnyChange` subscriptions are ephemeral UI tracking and must not keep anything alive. |
| G6 | Collector files or destroys | **Files** (bin ⇄ shelf), exactly as today — the bin is the user-visible graveyard; destruction stays a user act. |
| G7 | Eager cycle-drain vs incremental-across-frames | **Eager** — keep the proven deterministic station; record the 2016 note's "incremental" wish as superseded by the drain design. |
| G8 | Do flow/command edges into a closing widget argue "park, don't destroy" (the `anyReferenceToWdgt` sites)? | Genuine product-semantics call — **owner decides during 4.3**; no recommendation. |

## 6. Risks & non-goals
- **Test-state leaks are the top risk** (world-level Sets surviving `ResetWorld`); both proposals are
  shaped to add zero world-level state — hold that line.
- **GC determinism** — event-time, pure over the edge sets, once per cycle.
- **Non-goals:** replacing the dataflow engine (reuse it); the reference-widget *UI* (reference plan);
  duplication semantics (touched in the reference plan, informed by this edge model); dead-target
  wire delivery semantics beyond the §4.3 spike.

## 7. Rejected alternatives (do not re-attempt)
- **Eager command-edge index in `world.dataflow`** — rejected under G4 above (no funnel, menu churn,
  no consumer, risk class). Revisit ONLY with a named reverse-query consumer in hand.
- **A world-level registry of wire/edge-holding widgets** for §4.3's enumeration — rejected: the §3
  top-risk state class; the drain-time tree walk is the sound shape at today's scale.
- **Reference counting** — §4.4, the 2016 note's own ruling.
- **P10(a) (routing `ButtonWdgt.trigger` through the dataflow drain)** — NOT this plan and already a
  recorded refusal (`docs/BACKLOG.md`): pools destroy click counts; commands aren't pins.

## 8. Verification protocol
- §4.2 is behaviour-neutral: `fg presuite` while iterating; `fg gauntlet` at the commit point
  (expect zero recaptures; any pixel diff means 4.2 leaked behaviour and is a bug in the arc).
- The 4.2(c) probe: a `Fizzygum-tests/.scratch/` headless fixture asserting `graphEdgesOut` records
  for a wired controller, a button, and a shortcut (promote to a permanent gate only if the owner
  wants it).
- §4.3: `fg gauntlet` with special attention to the `storage` leg (the from-scratch
  storage-reclassification invariant) and the `serialization` leg; plus a new SystemTest or headless
  probe for the newly-covered case (a wire into a bin resident re-files it to the shelf).

## 9. Cross-links
- Supersedes: reference-plan referent-link rename + GC (see [`reference-widgets-plan.md`](reference-widgets-plan.md)).
- Absorbs: connector §P10(b) — [`../archive/connector-ubiquity-and-reflection-plan.md`](../archive/connector-ubiquity-and-reflection-plan.md)
  §8 question 8 (re-homed 2026-08-18) and its BACKLOG line.
- Program siblings: [`onion-widget-composition-plan.md`](../archive/onion-widget-composition-plan.md),
  [`creation-and-templates-plan.md`](creation-and-templates-plan.md),
  [`container-regularization-plan.md`](../archive/container-regularization-plan.md) (closed + archived).
- Architecture: `docs/architecture/serialization-duplication-reference.md`,
  `docs/specs/dataflow-engine-spec.md`; determinism: `Fizzygum-tests/DETERMINISM.md`;
  case-law: `docs/archive/upedge-endgame-plan.md`,
  [`../archive/bin-shelf-eager-sorting-plan.md`](../archive/bin-shelf-eager-sorting-plan.md) (the
  classifier + drain station this plan generalizes).

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

One closed item relocated VERBATIM from `docs/BACKLOG.md` on 2026-08-18, so that file can go
back to being an index of OPEN work only (`docs/README.md` filing rule 2). This plan is still
ACTIVE: §4.2–§4.4 remain open and stay listed in `docs/BACKLOG.md`. The landing belongs with
§4.1, which already carries its own ✅ LANDED stamp.

- [x] §4.1: reference link `@target` → `referencedWidget` — DONE 2026-08-16 by connector §P9 (`34adb216`), 21 sites + 2 cross-file readers; the dataflow and dispatch meanings KEEP the name.
- [x] P10(b) (ex-connector, absorbed here as decision G4): index button `@target`s as non-traversed COMMAND edges — **ANSWERED + LANDED 2026-08-18 with §4.2**: no index; the command edge is enumerated lazily by `ButtonWdgt.graphEdgesOut` behind the capability probe `@target?.graphEdgesOut?`. An eager `world.dataflow` index is a recorded rejected alternative (§7): no `@target` write funnel exists, menu chrome would churn it, and no reverse-query consumer exists — revisit only with a named consumer in hand. ⇒ §4.3 (the whole-graph collector, G3: own session) is the next unstarted step.

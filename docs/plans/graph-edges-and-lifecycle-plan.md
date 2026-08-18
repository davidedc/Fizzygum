# The widget graph — three edge kinds, one lifecycle

**STATUS: AUTHORED 2026-07-18 — §4.1 (the `@target` → `referencedWidget` rename) LANDED 2026-08-16,
executed as part of the sibling [`connector-ubiquity-and-reflection-plan.md`](connector-ubiquity-and-reflection-plan.md)'s
P9 (that plan's P9 section carries the full receipt — it also renamed the inspector's overload to
`inspectedObject`). §4.2 (one edge vocabulary) and §4.3 (whole-graph collector) remain design-stage,
exploratory, owner-gated.**
Anchor on **symbol names** (verified 2026-07-18); line numbers drift. Self-contained.

Part of one program with [`onion-widget-composition-plan.md`](onion-widget-composition-plan.md),
[`container-regularization-plan.md`](../archive/container-regularization-plan.md) (closed + archived),
[`creation-and-templates-plan.md`](creation-and-templates-plan.md), and
[`reference-widgets-plan.md`](reference-widgets-plan.md). **This arc supersedes the referent-link rename +
garbage-collection sections of the reference plan** (it does them properly, at the graph level). North star:
orthogonalisation, de-byzantination, regularity.

---

## 1. The idea

Widgets are wired to each other by **three kinds of edge**, and today they are three unrelated mechanisms.
Make them one **first-class, named, serialized edge model** — and widget **lifecycle / garbage collection
falls out as a single reachability question** over the union of the three.

| Edge | Meaning | Direction/semantics |
|---|---|---|
| **containment** | "is inside" | the widget tree; a parent owns its children |
| **target / action** | information flows *down* to another widget | dataflow (`@wires`, a list of `WireSpec`) / button actions (`@target`, `@action`) |
| **reference** | "points at, brings up" — carries **no** information | a shortcut/minimised/folder pointing at its referent |

The 2016 *Reference morphs* note stated the payoff exactly: *"the way we determine which morphs can be
destroyed depends on the combination of three types of links: reference, target, children."* A widget is
**destroyable exactly when it is unreachable via containment ∪ target ∪ reference** from the roots (world,
hand, desktop, the persistent areas). One reachability walk, three edge sets.

The naming discipline that makes it legible: a **reference is not a target.** A *target* sends information
down (dataflow/actions); a *reference* just points. `@target` used to be **overloaded** to mean both — §4.1
gave the reference edge its own field, **`referencedWidget`** (landed; see the status line).

---

## 2. Current-state truth (verified 2026-07-18; reference + storage bullets re-verified 2026-08-18)

Three separate, non-uniform mechanisms; reachability is computed, but only over one of them:

- **containment** — `TreeNode.children` (`basic-data-structures/TreeNode.coffee`); the tree `Widget` sits in.
  A widget with no owner is never drawn.
- **target / action** — `ControllerMixin.@wires`, a list of `WireSpec` records ("I drive `action` on
  `target`", plus that wire's policy), mirrored into engine edges by `world.dataflow.ensureWireEdges`;
  `ButtonWdgt.@target` + `@action` (button dispatch, `@action` is a **string method name**). The dataflow
  engine (`world.dataflow`, `src/dataflow/`) maintains a forward/reverse edge index that is **derived and
  never serialized**.
- **reference** — `IconicDesktopSystemShortcutWdgt` (+ Document/Folder/Script subclasses) holds its referent
  in **`referencedWidget`** (its own field since §4.1 landed) and is registered in the world-level `Set`
  **`world.widgetsReferencingOtherWidgets`**; `bringUpTarget()` re-summons it.
- **Reachability — partial, one-area:** `StorageSorter` (`StorageSorter.coffee`) runs an **eager**
  reachability classifier — `_runClassifier` marks from the desktop/hand/app slots with a fresh gc session
  id, and the drain then files each storage resident into the bin (lost) or the shelf (reachable). It is
  not a general, whole-graph collector, and it reasons over references only (not a unified 3-edge
  reachability); nothing is ever *destroyed* by it, only re-filed.

**Gaps:** the three edges have no common vocabulary; reachability is storage-local and reference-only, and
it sorts rather than collects; the serialization posture differs per edge (children serialized structurally;
dataflow index derived; reference edge ad-hoc).

---

## 3. Architecture we MUST respect

- **Serialization posture per edge is load-bearing.** Containment is serialized structurally; the dataflow
  forward/reverse index is **derived, never serialized** (rebuilt on load); the reference edge must declare
  its `@serializationTransients` posture explicitly (is the edge stored, or re-derived?). Mirror the current
  shortcut's referent serialization. See `docs/architecture/serialization-duplication-reference.md`.
- **GC must be deterministic + incremental.** The note wants GC *"incrementally across frames."* Under the
  Automator the clock is **event time**, never wall-clock; a cross-frame collector must be a pure function
  of the three edge sets and make progress in bounded chunks (`Fizzygum-tests/DETERMINISM.md`).
- **⚠ World-level edge state is test-sensitive.** `world.widgetsReferencingOtherWidgets` is a world-level
  `Set`; the bin and shelf **survive `ResetWorld`** and have prior gate-false-positive case-law
  (`docs/archive/upedge-endgame-plan.md`); an un-cleared world-level Set is the classic
  "passes-alone-but-mis-renders-in-suite" leak (memory: *resetWorld state leak between tests*). Keep
  teardown/`resetWorld` honest for any new edge index.
- **The dataflow engine already models a graph** (`world.dataflow`, `src/dataflow/`) — the target/action
  edge should *reuse* its edge-index machinery, not fork a second one. Its design:
  `docs/specs/dataflow-engine-spec.md`.
- **Naming/tiers** as in the program (`*Wdgt`, `_`/`__`, etc.).

---

## 4. Proposals

### 4.1 Give the reference edge its own field: `@target` → `referencedWidget`. ✅ **LANDED 2026-08-16**
On `IconicDesktopSystemShortcutWdgt` (+ subclasses) rename the referent link from the overloaded `@target`
to **`referencedWidget`**, leaving `@target` to mean information-flow only. Touches serialization (the
referent edge) and `widgetsReferencingOtherWidgets`; verify a serialization round-trip. Removes a real
reading hazard (reference vs dataflow target). Pixels identical.

Landed as the sibling connector plan's P9 (which disambiguated all four `@target` meanings in one sweep,
`inspectedObject` for the inspector's) — `IconicDesktopSystemShortcutWdgt.coffee` now declares
`referencedWidget` and constructs from it. Nothing of 4.1 is left to do.

### 4.2 Name the three edges as one vocabulary. *Consolidation.*
Introduce a small, uniform edge vocabulary — each edge kind a named, queryable relation with a consistent
add/remove/enumerate API and a declared serialization posture:
- `children` (containment) — already structural;
- `target`/`action` (information-flow) — via the dataflow index;
- `referencedWidget` / the `widgetsReferencingOtherWidgets` index (reference).
No behaviour change — this is naming + a thin common accessor so the GC walk (4.3) can enumerate all three
uniformly. Keep the dataflow index as the single home of the target edges (don't fork it).

### 4.3 One reachability collector over the union. *The payoff.*
Generalize `StorageSorter._runClassifier` into a **whole-graph incremental collector**: mark from the roots
(world, hand, desktop, persistent areas) across **containment ∪ target ∪ reference**; a widget unreachable
via all three is destroyable. Run it **incrementally across frames**, event-time-deterministic, in bounded
chunks. This subsumes the storage-local reference-only classification and gives one lifecycle story for
closed widgets, minimised references, dataflow-wired nodes, and folder contents alike. ⚠ The classifier is
today **eager** (marked at chokepoints, drained once per world cycle in `doOneCycle`) and it only *files*
residents between bin and shelf — going incremental-across-frames and going destructive are both real
changes to it, not settings.

### 4.4 (bank) Reference-counting is NOT the mechanism.
Record the note's ruling so no one re-adds it: reference-counting the reference edges is **not** used
(reachability over the three-edge union is the truth); back-links from referent → reference exist only when
a UI needs them (e.g. an icon must update), never for GC.

---

## 5. Owner decisions
| # | Decision | Recommendation |
|---|---|---|
| G1 | Scope for v1 | **4.1 + 4.2** (rename the reference edge, name the vocabulary) — concrete, low-risk. 4.1 has since landed on its own (via the connector plan's P9), so v1 is now just 4.2. 4.3 (unified collector) is the second wave. |
| G2 | Reuse the dataflow index for the target edge? | **Yes** — one graph index, not two. |
| G3 | Whole-graph GC vs keep storage-local | Whole-graph is the goal (4.3), but it's the riskiest piece (test-state, determinism) — gate hard, land after 4.2. |

## 6. Risks & non-goals
- **Test-state leaks are the top risk** (world-level Sets surviving `ResetWorld`); teardown must stay honest.
- **GC determinism** — event-time, pure over the three edge sets, bounded per frame.
- **Non-goals:** replacing the dataflow engine (reuse it); the reference-widget *UI* (reference plan);
  duplication semantics (touched in the reference plan §, informed by this edge model).

## 7. Cross-links
- Supersedes: reference-plan referent-link rename + GC (see [`reference-widgets-plan.md`](reference-widgets-plan.md)).
- Program siblings: [`onion-widget-composition-plan.md`](onion-widget-composition-plan.md),
  [`creation-and-templates-plan.md`](creation-and-templates-plan.md),
  [`container-regularization-plan.md`](../archive/container-regularization-plan.md) (closed + archived).
- Architecture: `docs/architecture/serialization-duplication-reference.md`,
  `docs/specs/dataflow-engine-spec.md`; determinism: `Fizzygum-tests/DETERMINISM.md`;
  case-law: `docs/archive/upedge-endgame-plan.md`.
```

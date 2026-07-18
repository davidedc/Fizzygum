# The widget graph — three edge kinds, one lifecycle

**STATUS: AUTHORED 2026-07-18 — design-stage, exploratory. NO code written yet. Owner-gated execution.**
Anchor on **symbol names** (verified 2026-07-18); line numbers drift. Self-contained.

Part of one program with [`onion-widget-composition-plan.md`](onion-widget-composition-plan.md),
[`container-regularization-plan.md`](container-regularization-plan.md),
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
| **target / action** | information flows *down* to another widget | dataflow / button actions (`@target`, `@action`) |
| **reference** | "points at, brings up" — carries **no** information | a shortcut/minimised/folder pointing at its referent |

The 2016 *Reference morphs* note stated the payoff exactly: *"the way we determine which morphs can be
destroyed depends on the combination of three types of links: reference, target, children."* A widget is
**destroyable exactly when it is unreachable via containment ∪ target ∪ reference** from the roots (world,
hand, desktop, the persistent areas). One reachability walk, three edge sets.

The naming discipline that makes it legible: a **reference is not a target.** A *target* sends information
down (dataflow/actions); a *reference* just points. Today `@target` is **overloaded** to mean both — so the
reference edge gets its own field, **`referencedWidget`**.

---

## 2. Current-state truth (verified 2026-07-18)

Three separate, non-uniform mechanisms; GC exists but only over one of them:

- **containment** — `TreeNode.children` (`basic-data-structures/TreeNode.coffee`); the tree `Widget` sits in.
  A widget with no owner is never drawn.
- **target / action** — `ControllerMixin.@target` + `@action` (dataflow/reactive wiring); `ButtonWdgt.@target`
  + `@action` (button dispatch, `@action` is a **string method name**). The dataflow engine (`world.dataflow`,
  `src/dataflow/`) maintains a forward/reverse edge index that is **derived and never serialized**.
- **reference** — `IconicDesktopSystemShortcutWdgt` (+ Document/Folder/Script subclasses) holds its referent
  in the **overloaded `@target`** and is registered in the world-level `Set`
  **`world.widgetsReferencingOtherWidgets`**; `bringUpTarget()` re-summons it.
- **GC — partial, one-area:** `BasementWdgt.doGC` (`BasementWdgt.coffee`) runs an **incremental** garbage
  collector marking which *basement* items are still reachable via references. It is not a general,
  whole-graph collector, and it reasons over references only (not a unified 3-edge reachability).

**Gaps:** the three edges have no common vocabulary; `referencedWidget` doesn't exist (the reference edge
rides `@target`); reachability/GC is basement-local and reference-only; the serialization posture differs
per edge (children serialized structurally; dataflow index derived; reference edge ad-hoc).

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
  `Set`; the Basement **survives `ResetWorld`** and has prior gate-false-positive case-law
  (`docs/archive/upedge-endgame-plan.md`); an un-cleared world-level Set is the classic
  "passes-alone-but-mis-renders-in-suite" leak (memory: *resetWorld state leak between tests*). Keep
  teardown/`resetWorld` honest for any new edge index.
- **The dataflow engine already models a graph** (`world.dataflow`, `src/dataflow/`) — the target/action
  edge should *reuse* its edge-index machinery, not fork a second one. Its design:
  `docs/specs/dataflow-engine-spec.md`.
- **Naming/tiers** as in the program (`*Wdgt`, `_`/`__`, etc.).

---

## 4. Proposals

### 4.1 Give the reference edge its own field: `@target` → `referencedWidget`. *Concrete, do first.*
On `IconicDesktopSystemShortcutWdgt` (+ subclasses) rename the referent link from the overloaded `@target`
to **`referencedWidget`**, leaving `@target` to mean information-flow only. Touches serialization (the
referent edge) and `widgetsReferencingOtherWidgets`; verify a serialization round-trip. Removes a real
reading hazard (reference vs dataflow target). Pixels identical.

### 4.2 Name the three edges as one vocabulary. *Consolidation.*
Introduce a small, uniform edge vocabulary — each edge kind a named, queryable relation with a consistent
add/remove/enumerate API and a declared serialization posture:
- `children` (containment) — already structural;
- `target`/`action` (information-flow) — via the dataflow index;
- `referencedWidget` / the `widgetsReferencingOtherWidgets` index (reference).
No behaviour change — this is naming + a thin common accessor so the GC walk (4.3) can enumerate all three
uniformly. Keep the dataflow index as the single home of the target edges (don't fork it).

### 4.3 One reachability collector over the union. *The payoff.*
Generalize `BasementWdgt.doGC` into a **whole-graph incremental collector**: mark from the roots (world,
hand, desktop, persistent areas) across **containment ∪ target ∪ reference**; a widget unreachable via all
three is destroyable. Run it **incrementally across frames**, event-time-deterministic, in bounded chunks.
This subsumes the basement-local reference-only GC and gives one lifecycle story for closed widgets,
minimised references, dataflow-wired nodes, and folder contents alike.

### 4.4 (bank) Reference-counting is NOT the mechanism.
Record the note's ruling so no one re-adds it: reference-counting the reference edges is **not** used
(reachability over the three-edge union is the truth); back-links from referent → reference exist only when
a UI needs them (e.g. an icon must update), never for GC.

---

## 5. Owner decisions
| # | Decision | Recommendation |
|---|---|---|
| G1 | Scope for v1 | **4.1 + 4.2** (rename the reference edge, name the vocabulary) — concrete, low-risk. 4.3 (unified collector) is the second wave. |
| G2 | Reuse the dataflow index for the target edge? | **Yes** — one graph index, not two. |
| G3 | Whole-graph GC vs keep basement-local | Whole-graph is the goal (4.3), but it's the riskiest piece (test-state, determinism) — gate hard, land after 4.1/4.2. |

## 6. Risks & non-goals
- **Test-state leaks are the top risk** (world-level Sets surviving `ResetWorld`); teardown must stay honest.
- **GC determinism** — event-time, pure over the three edge sets, bounded per frame.
- **Non-goals:** replacing the dataflow engine (reuse it); the reference-widget *UI* (reference plan);
  duplication semantics (touched in the reference plan §, informed by this edge model).

## 7. Cross-links
- Supersedes: reference-plan referent-link rename + GC (see [`reference-widgets-plan.md`](reference-widgets-plan.md)).
- Program siblings: [`onion-widget-composition-plan.md`](onion-widget-composition-plan.md),
  [`creation-and-templates-plan.md`](creation-and-templates-plan.md),
  [`container-regularization-plan.md`](container-regularization-plan.md).
- Architecture: `docs/architecture/serialization-duplication-reference.md`,
  `docs/specs/dataflow-engine-spec.md`; determinism: `Fizzygum-tests/DETERMINISM.md`;
  case-law: `docs/archive/upedge-endgame-plan.md`.
```

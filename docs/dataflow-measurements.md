# Dataflow drain — measured convergence

**Question it answers:** how many **passes** does the once-per-cycle dataflow drain
(`DataflowEngine.recalculateDataflow`, spec §4.1/§5) actually take to settle, and how big is a
drain? The drain is *drain-until-quiet* — it repeats passes while the stale pool is non-empty —
so the honest question is not "does it terminate" (it does; see the bound below) but "how many
passes in practice." In the spirit of layout's `coalescing-measurement.md`: **measure, don't guess.**

This is a **performance / shape** characterisation, never a correctness one: the suite is
byte-deterministic and the engine's visit-once + equal-value cutoff guarantee termination. The
numbers below say the drain is *cheap and shallow* in every shipped circuit.

## The bound (design)

- **Convergence is bounded:** `DataflowEngine.dataflowPassesSanityLimit = 1000`. A drain that
  exceeds it throws `DATAFLOW_NONCONVERGENCE` (a genuine divergent side-effect loop → a loud
  error, never a frozen frame). This is a backstop set far above any real drain, not a target.
- **Why a driven RING is one pass, not two:** a ported controller's `updateTarget` tail re-marks
  the very node the engine is applying (the *echo*, NOMENCLATURE / spec §1.13). `markStale`
  DROPS that echo while `@_applyingNode` is set, so a driven ring walks exactly ONE lap. Without
  the echo suppression the ring would pool one stale node per lap and take a 2nd pass — the
  suppression is what buys the 1-pass result measured below.

## The instrument (built in)

`DataflowEngine` keeps three counters — read them live from any booted world
(`world.dataflow.…`):

| counter | meaning |
|---|---|
| `lastDrainPassCount` | passes the most recent drain took (0 if the pool was empty — the dark-cheap early return) |
| `maxObservedPassCount` | running max of `lastDrainPassCount` this world session |
| `lastDrainRecomputeCount` | node `dataflowRecompute()`s in the most recent drain (its work size) |

**Re-measure suite-wide** with a `PRELUDE_JS` probe that logs each non-empty drain (the pattern
of `coalescing-measurement.md`) — the throwaway used to produce the table below is
`Fizzygum-tests` `PRELUDE_JS` wrapping `recalculateDataflow` to log
`passes=lastDrainPassCount recomputes=lastDrainRecomputeCount`, run per test at `--speed=fastest`
(the suite's stress condition — many events drained per cycle):

```sh
cd Fizzygum-tests
env PRELUDE_JS=<probe>.js node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1 --speed=fastest \
  | grep 'DFMEAS drain'
```

## Measured (2026-07-06, `--speed=fastest`, dpr 1)

Both clients — patch-programming circuits AND the spreadsheet — over the representative driven /
reference / widget-valued tests:

| test | client | passes | recomputes/drain |
|---|---|--:|--:|
| `macroDegreesConverterFourWayDrive` (the °C↔°F **ring**) | connections | **1** | 2 |
| `macroSliderTextTwoWayPatchCycle` / `…SliderPatchCycle` / `macroSlidersControlTextWidget` | connections | **1** | ≤2 |
| `macroDataflowEngineSmoke` | engine (direct) | **1** | ≤2 |
| `macroSpreadsheetRefsRecalc` (a reference chain) | spreadsheet | **1** | 3 |
| `macroSpreadsheetColorCell` (classify→present) | spreadsheet | **1** | 4 |
| `macroSpreadsheetErrorPropagation` / `…LoopRejected` / `…LiteralEntry` / `…SecondsCell` | spreadsheet | **1** | 1 |
| **`macroSpreadsheetSliderCell`** (a widget-VALUED cell — a slider dragged in a cell) | spreadsheet | **2** | 2 |

**Verdict:**
- **Typical = 1 pass.** Every DAG circuit, every driven ring, every reference chain, and every
  presenter/time cell settles in a single pass — the closure is walked once (visit-once) and the
  equal-value cutoff prunes the rest.
- **Peak = 2 passes**, and only for a **sink-onto-source** chain: a widget-VALUED cell whose own
  hosted widget (a slider) fires back into it (`cellInput` → `markStale` the cell → recompute
  retains the widget). The producer and the node it drives are the same identity across the hop,
  so the settle needs one extra lap. This is exactly the "1 pass typical, 2 with sink-onto-source
  chains" the plan predicted (implementation-plan §1) — now measured, not conjectured.
- **Drain size (recomputes) stays tiny** — 1–4 nodes across every test — because a drain only
  recomputes the *downstream closure of what changed this event*, not the sheet/circuit.

No shipped circuit approaches the 1000-pass bound; the drain is O(affected-subgraph) per cycle.

# Coalescing measurement harness

**Question it answers:** for a gesture/stream that mutates layout per input event (a drag, a wheel-scroll, a
key-repeat), is it worth *coalescing* its mutations onto the **one** end-of-cycle layout flush (the
`_<name>NoSettle`-core path) instead of letting each public mutation **self-settle**? The entire value of
coalescing is `(mutations-per-frame − 1)` flushes saved per `doOneCycle`. If a gesture only ever produces ~1
mutation per frame, coalescing saves nothing and the call should just use the public self-settling setter
(simpler, and it keeps "public methods self-settle" honest). If it produces many per frame, coalescing is
warranted and wants an explicit, auditable home (a `_`-private, stream-handler-restricted `*Coalesced` entrypoint
— see check-layering rule [O] — / a `world.coalescing => …` scope) rather than feature code reaching into a
private `_<name>NoSettle` core.

This is a **performance** question, never a correctness one: the suite is byte-deterministic and render happens
once per frame *after* all events, so coalesced-vs-self-settle is byte-identical — only the flush count per
frame differs. Measure, don't guess.

## The harness (`Fizzygum-tests/scripts/coalescing-measure/`)

- `coalescing-measure-prelude.js` — injected via `PRELUDE_JS`. Logs, tagged with `WorldWdgt.frameCount`:
  `CMEAS MOVE` (a `processMouseMove`), `CMEAS MUT m=<name>` (a watched per-event mutation), and `CMEAS FLUSH
  qlen=<n> inMut=<bool>` (a `recalculateLayouts` — `inMut=true` is a `_settleLayoutsAfter` self-settle,
  `inMut=false` is the doOneCycle end-of-cycle flush). Pure observation. Default watched mutation is
  `_setMaxDimNoSettle`; edit the `watch` default (or the small fallback) to point at the core your gesture uses.
- `aggregate.js` — turns the log into a per-frame table + the verdict (mutations/frame distribution, the
  flushes coalescing saves, and the queue length per flush as a settle-cost proxy).

### Run it on one test, at two speeds

```sh
cd Fizzygum-tests
# fastest = how the headless SUITE drains events (many per cycle); normal = closer to real-time pacing.
for SP in fastest normal; do
  env PRELUDE_JS=$PWD/scripts/coalescing-measure/coalescing-measure-prelude.js LOG_FILE=/tmp/cmeas-$SP.log \
    node scripts/run-macro-test-headless.js SystemTest_<the-test> --dpr=1 --speed=$SP >/dev/null
  node scripts/coalescing-measure/aggregate.js /tmp/cmeas-$SP.log
done
```

**Interpreting the verdict.** Read **muts/frame at `normal`** as the real-usage rate (fastest *crams* the whole
gesture into 1–2 cycles, so it over-states the rate — it's the suite's stress condition, not real usage). Then:
`max ≈ 1` → coalescing saves ~0 → **use the public self-settling setter**. `max ≫ 1` → coalescing is warranted;
how much it matters scales with the **queue length per flush** (a 3-widget settle is cheap; a 300-widget one is
not), so weigh muts/frame × qlen.

## Case study — the stack-divider drag (`macroStackDividerReproportionsCells`, 2026-06-26)

Watched `_setMaxDimNoSettle` (the core `StackElementsSizeAdjustingWdgt.nonFloatDragging` calls after the
`Widget.setMaxDim` self-settle convert):

| speed | gesture frames | muts/frame min/med/max | moves/frame avg | qlen/flush | flushes WITH / WITHOUT coalescing |
|---|--:|--:|--:|--:|--:|
| fastest | 2 | 96 / 96 / **622** | 111 | 3 | **2** / 718 |
| normal | 37 | 4 / **16** / 56 | 6 | 3 | **37** / 718 |

**Verdict: coalescing is warranted here.** Even at `normal`, the drag produces a **median 16 (up to 56)**
mutations per frame — each move fires ~3 `setMaxDim` (left cell + right cell + a revert) and ~6 moves drain per
cycle — so coalescing collapses ~16 settles/frame into 1. Without it, a drag would run 16–56 `recalculateLayouts`
per frame; cheap here (qlen 3 ≈ ms-scale) but it scales linearly with stack size. So this is a "design the
coalescing strategy" case (an explicit `_setMaxDimCoalesced` — `_`-private, restricted to this drag handler by
check-layering [O] — / `world.coalescing => …` that *declares* the coalescing so the end-of-cycle settle can
tell intentional-coalesced from a careless leak), **not** a "just use the public `setMaxDim`" case.

Side note the harness surfaced: ~half of those 718 mutations are **set-then-reverted within the same frame**
(`nonFloatDragging`'s `if prev != newone` revert) — a separate efficiency question from coalescing.

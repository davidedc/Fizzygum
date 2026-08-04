# Budgeted source-compile scheduler — measured behavior (2026-08-04)

Measured on the owner's machine at the landing of `SourceCompileScheduler`
(`docs/plans/budgeted-source-compile-scheduler-plan.md`), replacing the one-class-per-turn ingest
pacing. Probes: `../Fizzygum-tests/.scratch/compile-scheduler-boot-probe.js` and
`compile-scheduler-lazy-probe.js` (gitignored scratch; recreate from the plan if needed).

## Dev compile-at-boot (`index.html`, native, dev profile — 260 eager classes)

| pacing | world-ready |
|---|---|
| one class per `setTimeout(1)` turn (2026-07-31 measurement) | 3219 ms — ⚠ NOT apples-to-apples: measured at 452 eager sources, before the boot-cost/app-kit arcs made ~190 of them lazy |
| scheduler, 40 ms pump chunks (rejected — see below) | 743 ms |
| scheduler, 10 ms pump chunks (SHIPPED) | 946 ms |

The mechanism of the win is the elimination of one timer turn per class (~450 then, 260 now, each
costing ~1–4 ms of clamped wait) plus batching; the exact old-vs-new delta on today's class count
was not isolated (would need a pre-change worktree build).

## SW harness page (`worldWithSystemTestHarness.html`, all 506 classes eager)

Alone: 1204 ms world-ready, all 506 processed, zero errors (40 ms chunks; presuite green covers the
10 ms configuration).

## Lazy-part ingest behind a running world (dev `index.html`)

| part | classes | drains (≈frames) | old pacing would take | max drain |
|---|---|---|---|---|
| `fizzytiles` | 19 | 4–5 | 19 frames | 27–35 ms |
| `spreadsheet` | 12 | 2 | 12 frames | 12.8 ms |

The 27–35 ms fizzytiles tail is the **irreducible single-class floor**, not scheduler overshoot:
`LCLCodePreprocessor.coffee` is 1887 lines ≈ 28 ms compiled fragmented, and the ≥1-per-drain rule
(owner-locked) admits it whole — exactly as the old one-per-frame pacing did. Worst case is one
dropped frame during a load burst.

## Estimator calibration

The EWMA converges to ~0.014–0.018 ms/line (compile-and-execute) on this box — the 0.06 prior
derived from the 2026-07-31 measurement is ~4× conservative, because that measurement's per-source
attribution included per-turn timer overhead. Conservative priors err safe (fewer classes admitted
per frame until calibrated); left as is.

## ⚠ Parallel-load case law: why the pump chunk is 10 ms, not 40

With `NO_WORLD_CHUNK_MS: 40`, the presuite's parallel wave (8 dpr1 suite shards ∥ 5 paint shards)
COLLAPSED twice, reproducibly: all 8 suite pages died simultaneously mid-run ("lost the page",
"Session closed"), all 5 paint pages hit "world never booted" with 180 s protocol timeouts — while
EITHER leg alone passed, and every page was healthy and sub-second solo. A booting page that holds
its core in 40 ms uninterruptible blocks starves Chrome's protocol deadlines once ~13 dense pages
compete for the machine; Chrome closes targets and the runners cascade. At 10 ms chunks (the old
per-class yield granularity, still batching ~10+ classes per turn at the measured ~0.7 ms/class)
the same wave is green in normal times: `dpr1:PASS(58s) paint:PASS(87s)`.

Rule worth keeping: **on a page that shares a loaded machine with sibling test pages, synchronous
work chunks between yields must stay ~10 ms** — batching wins must come from fewer timer turns, not
longer uninterruptible blocks.

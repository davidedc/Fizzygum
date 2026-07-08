# Raw results of the 2026-07-07 profiling campaign

These are the small durable artifacts of the campaign digested in
[`../../runtime-performance-optimization-plan.md`](../../runtime-performance-optimization-plan.md);
they let a future re-run be diffed against this baseline without re-deriving anything.
The multi-MB `.cpuprofile` files are NOT kept (regenerable via `../run-campaign.sh`;
each `*.report.txt` / `*.groups.txt` here is its full digest). Load a regenerated
`.cpuprofile` into Chrome DevTools → Performance → Load profile to explore interactively.

## Environment

- Date: 2026-07-07. Machine: Apple M4 Max, 16 cores, macOS (Darwin 24.6.0).
- Puppeteer 22.15.0 (Chrome for Testing 127.0.6533.88, headless 'new'), viewport 1100×800 dsf1.
- Build under test: `Fizzygum-builds/latest` of 2026-07-07 12:25 — framework `6f6c834e`
  (+ then-uncommitted WorldWdgt edit), SWCanvas vendored per `vendor/swcanvas.pin`
  (repo HEAD `f463993`). Full 190-test suite, `?sw=1&speed=fastest&intro=0`.
- Every run finished `failed=0` (190/190).

## Files

| File | Run | What it is |
|---|---|---|
| `cnt-sw1-dpr1.counters.json` | counters, min build, dpr1, 341s | full-suite canvas workload (clip classification, draw-by-clip-kind, volumes) |
| `cnt-sw1-dpr2.counters.json` | counters, min build, dpr2, 442s | ditto @dpr2 (NOTE: cumulative `areas` sums drift @dpr2 — trust point-classified stats) |
| `prof-sw1-dpr1.report.txt` | profile, shadow build, dpr1, 374s | bucket + top-45 self/total digest (busy 128.0s) |
| `prof-sw1-dpr1.groups.txt` | ditto | SWCanvas subsystem split |
| `prof-sw1-dpr2.report.txt` | profile, shadow build, dpr2, 479s | digest (busy 292.3s; SHA-256 24.7% busy) |
| `prof-sw1-dpr2.groups.txt` | ditto | subsystem split |
| `prof-boot.report.txt` | boot profile (`--profile-boot`), 1 test | boot/compile-phase digest |
| `prof-framework.report.txt` | profile, NOLOG build (`--save-sources`), dpr1, 343s | post-S1 digest with `Class.method` names (busy 86.1s) |
| `prof-framework.groups.txt` | ditto | subsystem split post-S1 |
| `*.meta.json` (10) | every run incl. the four A/B legs | wall timings, boot ms, per-test progress timestamps, final verdicts, exact URL/flags |

## Headline wall-clock ledger (from the `ab*`/`cnt*` metas)

| Run | Wall |
|---|---|
| A/B dpr1: shadow baseline (log present) | 374s |
| A/B dpr1: shadow-nolog | **343s (−8.3%)** |
| A/B dpr2: shadow baseline | 478s |
| A/B dpr2: shadow-nolog | **442s (−7.5%)** |

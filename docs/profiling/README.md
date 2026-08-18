# Fizzygum profiling harness

Node/Puppeteer tooling that measures where the running Fizzygum world actually spends CPU,
by driving the built SystemTest harness headless. It produced every number in
[`../plans/runtime-performance-optimization-plan.md`](../plans/runtime-performance-optimization-plan.md)
(campaign of 2026-07-07). It is read-only with respect to all three repos: it never edits
source and never touches `Fizzygum-builds/` (the unminified "shadow build" lives under `/tmp`
and symlinks the real build's assets).

Requires: a FULL normal build (`cd Fizzygum && ./build_it_please.sh`) and Puppeteer
(`cd Fizzygum-tests && npm i`). Run everything from this directory.

## The pieces

- **`prof-run.js`** — boots `worldWithSystemTestHarness.html` headless, selects tests
  (`--tests=all` or a comma list), runs them, and captures per run:
  - `--profile`: a V8 CPU sampling profile via CDP (`<out>.cpuprofile`) plus a
    scriptId→class map for the eval'd meta-compiled classes (`<out>.scripts.json`;
    add `--save-sources` to embed each eval'd source so prof-aggregate can name
    methods, not just classes). By default profiling starts AFTER boot; pass
    `--profile-boot` to profile the boot/compile phase instead.
  - `--counters`: canvas-workload counters via `prof-instrument.js` (`<out>.counters.json`).
  - always: `<out>.meta.json` (wall timings, per-test progress timestamps, final verdicts).
  - key flags: `--build=<dir>` `--dpr=1|2` `--sample-us=300` `--timeout-mins=30`.
- **`prof-instrument.js`** — page-side wrapper installed before any page script. Counts —
  without changing any pixels — every clip()/save()/draw call on BOTH the native
  CanvasRenderingContext2D prototype and SWCanvas's compat context (trapped when
  `window.SWCanvas` is assigned). Classifies each clip() (axis-aligned integer rect?
  under rotation? nested? bbox/surface ratio) and partitions draw calls by effective
  clip kind (none / rect-only / mask). This implements the observation asked for by the
  SWCanvas repo's `plans/clipping-optimization.md` §8. Caveat: the transform tracker
  does not see `canvas.width=` resets, so long-run 'areas' sums can drift at dpr2 —
  trust the point-classified stats (clip kinds, counts) and dpr1 areas.
- **`prof-aggregate.js <prefix> --segments=<shadow>/segments.json`** — digests a
  `.cpuprofile` into bucket totals (SWCanvas / framework classes / harness / compiler /
  gc / idle), top-N by self time and by stack-attributed total time. Idle-excluded
  "busy" percentages are the numbers to compare across runs (the suite is vsync-paced).
- **`prof-groups.js <prefix> <segments.json>`** — sums self time over named SWCanvas
  subsystem groups (drawImage pipeline, clip-mask build/read, span fill, blend+color, …).
- **`prof-attribute.js <file.cpuprofile> --fn=<name>`** — attributes ONE named function's
  self time by caller chain (immediate caller / nearest framework call site / engine-entry
  route, e.g. "via drawTextFromAtlas"), using `segments.json` for the engine/framework
  boundary. Use a shadow-build profile. Built for the §5B O4 blit attribution
  (`../measurements/drawimage-blit-attribution-2026-07-24.md`), generic over any function.
- **`mk-shadow-build.sh [outdir]`** — assembles the unminified shadow build (real function
  names in profiles). The minified real build is preferred for counters/wall-clock;
  the shadow build for profiles.
- **`mk-nolog-build.js [srcdir] [dstdir]`** — clone of the shadow build with the SWCanvas
  `drawImage` debug `console.log` stripped; used for the S1 A/B measurement.
- **`run-campaign.sh [workdir]`** — the WHOLE 2026-07-07 campaign in one command
  (phases A–F: counters, serial CPU profiles at dpr1+dpr2, boot profile, S1 A/B at both
  densities, post-S1 method-level profile), including the aggregation step. ~55 min.
  Re-run this after landing an optimization and diff its outputs against
  [`results-2026-07-07/`](results-2026-07-07/INDEX.md) — the preserved raw record
  (counters JSONs, profile digests, per-run metas, environment, wall-clock ledger).
- **`prof-interactive.js`** — profiles **FELT interactive cost on a BUSY desktop**, which
  `prof-run.js` (suite-driven) is structurally blind to: the suite runs with the default
  wallpaper and no window churn, so it never exercises a window drag over a crowded screen.
  This boots the **plain world** (`index.html`, not the test harness), OPENS ALL 14 desktop
  apps to load up the screen (~21 windows), then scripts two interactions and times each
  `doOneCycle` (= one repaint frame): **drag** (float-drags the topmost window along a
  screen-spanning path via real `page.mouse` events) and **draw** (a pen stroke in
  FizzyPaint). It runs once per `--wallpaper` so **plain-vs-dots is a controlled A/B**
  (confirms the W1/W2 pattern fix in-situ and isolates any wallpaper-independent cost).
  Deterministic: fixed paths, no `Math.random`/`Date`. rAF drives the world loop headless
  (~60/s), so real mouse events + a `doOneCycle` timing wrapper give faithful frame costs.
  - **⚠ Backend:** the backend is baked into the entry PAGE at build time. `index.html` is
    the production world on the browser's NATIVE canvas; the owner runs SWCanvas. **Pass
    `--sw`** (which boots `index-sw.html`) or you profile the wrong (native) backend. See
    `docs/profiling` note + the memory `fizzygum-runtime-backend-swcanvas`.
  - **Flags:** `--wallpaper=plain|dots` (omit → runs both + prints the A/B) · `--sw` (boot
    `index-sw.html`) · `--build=<dir>` (default `../../../Fizzygum-builds/latest`; for NAMED SWCanvas
    frames point it at a shadow build — see below) · `--drag-frames=N` (140) · `--draw-frames=N`
    (80) · `--profile` (CDP V8 `.cpuprofile` per `<out>.<wallpaper>.<phase>.cpuprofile`) ·
    `--out=<prefix>` · `--cwc` (instrument SWCanvas canvas-wide compositing: call count,
    pixels iterated, op histogram, trigger stacks) · `--text` (instrument text: BitmapText
    render count + most-repeated strings + `TextWdgt` back-buffer hit/rebuild tally).
  - **Named SWCanvas frames:** the minified build shows SWCanvas as `(anon)`. For a named
    breakdown, `bash mk-shadow-build.sh <dir>`, add a shadow `index.html`
    (`sed 's|js/fizzygum-boot-sw-min.js|profile-boot.js|' <latest>/index-sw.html > <dir>/index-sw.html`),
    then `--build=<dir> --profile`. Fizzygum framework methods keep real names either way
    (meta-compiled at boot); the shadow build inflates absolute ms ~3× so read **percentages**.
  - **Parse a `.cpuprofile` for top self-time** (inline; nodes[] + samples[] + timeDeltas[]):
    sum `timeDeltas[i]` per `nodes` entry keyed by `callFrame.functionName` (+`url`), sort desc.
  - **Known limitation:** the `draw` phase depends on FizzyPaint being open (opened by
    `openAllApps`); if not found it prints `(skipping draw)` and reports `drag` only.
  - Example (the 2026-07-08 wallpaper investigation): `node prof-interactive.js --sw` →
    busy-drag dots-vs-plain A/B; `--sw --cwc --wallpaper=plain` → found canvas-wide
    compositing = colored-glyph `source-in` tinting (the analog-clock face re-render).

## prof-run.js flag reference

`--build=<dir>` harness dir (default `../../../Fizzygum-builds/latest`) ·
`--dpr=1|2` · `--speed=fastest` · `--tests=all|name[,name…]` (`SystemTest_` prefix optional) ·
`--out=<prefix>` · `--counters` · `--profile` · `--sample-us=300` (500 for the longer dpr2
runs keeps the profile file sane) · `--profile-boot` (profile navigation→ready instead of
the run) · `--save-sources` (embed eval'd class sources in `<out>.scripts.json` so
prof-aggregate names `Class.method` instead of `[class X]`; ~5MB) · `--timeout-mins=30`
(stall abort). Env: `FIZZYGUM_KEEP_STALE_BROWSERS=1` skips the startup pkill of headless
test browsers (REQUIRED on every run launched while another is still running).

## Typical session (single measurements by hand)

```bash
cd Fizzygum/docs/profiling
bash mk-shadow-build.sh /tmp/fizzygum-profiling/shadow-build

# workload counters on the real build (full suite, sw dpr1):
node prof-run.js --dpr=1 --tests=all --counters --out=/tmp/fizzygum-profiling/cnt-sw1-dpr1

# CPU profile on the shadow build (start AFTER boot; 300µs sampling):
node prof-run.js --build=/tmp/fizzygum-profiling/shadow-build --dpr=1 --tests=all \
  --profile --out=/tmp/fizzygum-profiling/prof-sw1-dpr1
node prof-aggregate.js /tmp/fizzygum-profiling/prof-sw1-dpr1 \
  --segments=/tmp/fizzygum-profiling/shadow-build/segments.json --top=40
node prof-groups.js /tmp/fizzygum-profiling/prof-sw1-dpr1 /tmp/fizzygum-profiling/shadow-build/segments.json
```

Notes / gotchas learned during the campaign:
- **Instruments rot when src renames land.** The 2026-07-24 O4 session found `prof-interactive.js`
  silently broken four ways (3× `instanceof WindowWdgt` post-FrameWdgt-rename, `world.changed()`
  post-privatization, a `--text` wrap on the deleted public `createRefreshOrGetBackBuffer` name,
  and the draw phase picking the "… info" window). A dead wrap reports zeros that read as
  "nothing happening" — smoke-check each enabled instrument reports non-zero before trusting it.
- Run profile runs SERIALLY (CPU contention distorts sampling); counter runs may overlap
  (`FIZZYGUM_KEEP_STALE_BROWSERS=1` on all but the first, or they pkill each other's browser).
- `prof-run.js` has NO backend axis: it drives `worldWithSystemTestHarness.html`, which IS the
  SWCanvas page. (Nothing is lost — the native backend never ran a headless suite anyway: the
  first test never completed, because the references/settle gates are SWCanvas-oriented.)
  Framework-vs-SWCanvas split comes from bucketing that profile instead.
- dpr1 suite wall time is FRAME-COUNT bound (~57fps): judge optimizations by busy-CPU delta,
  or run the A/B at dpr2 (CPU-bound; wall responds ~1:1).
- All instrumented/profiled runs must still pass the WHOLE suite (`failed: 0`, every test
  run) — that's the proof the instrumentation (or an A/B build change) is pixel-transparent.

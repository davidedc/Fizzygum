# Deferred-layout: OVERVIEW — the overall aim, where we are, the next step

**Read this first.** This is the entry point for the whole deferred-layout effort. It states the aim, the
current state (shipped + learned), the paths, and the next step. The detailed per-area docs are linked in
the Doc map (§6); each is self-contained too. Last updated 2026-06-20.

master: **Fizzygum `7ee0b871`** / **Fizzygum-tests `544166856`** — all green (165/165 dpr1+dpr2+WebKit,
smoke-apps 12/12, lint A–E 0). (C1 + the in-pass **deferred re-queue** shipped; next = the twin + lint — see §5.)

---

## 1. The overall aim

**Turn EVERY synchronous re-layout into a DEFERRED re-layout.** A deferred re-layout settles at exactly one
of two points, never mid-handler or mid-raw-setter:

- **at the end of a geometry-changing PUBLIC method** — the self-settling flush (`mutateGeometryThenSettle`);
  *modulo batching*, where a batch of mutations settles once at the end (`settleLayoutsOnceAfter`); or
- **at the end of `doOneCycle`** — the `recalculateLayouts → doLayout` pass, which runs before paint.

The payoff: one predictable settle model, no scattered synchronous re-fits, and no handler forced to read
back raw geometry.

## 2. The model + the ROOT blocker

- **The deferred mechanism already EXISTS.** Public setters (`setExtent`/`setWidth`/`setHeight`/`setBounds`/
  `fullMoveTo`/`add`) record intent (`@desiredExtent`/`@desiredPosition`) + `invalidateLayout()`, settled the
  SAME cycle by `recalculateLayouts → doLayout` before paint (`WorldWdgt.doOneCycle`). Deferral is
  within-frame — no cross-frame lag.
- **The ROOT blocker is READ-BACK.** The geometry accessors (`position/extent/width/height/left/top/center/
  boundingBox/…`) read the APPLIED `@bounds` only. So any code that reads a widget's geometry **between a
  deferred set and the settle** sees the STALE applied value, and is therefore *forced* to use the immediate
  `raw*` API + synchronous re-fits. **Every remaining synchronous re-layout is a symptom of this one root.**

## 3. Where we are

### Shipped (all on master)
| What | commit |
|---|---|
| Self-settling public geometry API (`mutateGeometryThenSettle`) | `817c2ce4` |
| **The 16 read-back construction macros** converted to the deferred API (rode the self-settling-API ship — this is why they pass today; it was NOT Path A that fixed them) | tests `a256ccfe6` |
| Phase 1/2 — `_reFitToContents` re-fit chokepoint + lint A/B/C/D | `ad2000cc` |
| Phase 3a — `add`/`addRaw` public & self-settling | `b8165920` |
| Phase 3b — scroll/stack/window content re-fit on the `doLayout` cycle | `00cea256` / `6c7060e5` |
| **Flow rule (#17)** — raw/silent/fullRaw setters must only MUTATE, never SCHEDULE layout (migrated + runtime throw guard + lint [E]) | `c45113ac` / `b89c9141` |
| **#18** — `createErrorConsole` freeze-amplifier fixed; `invalidateLayout` guard log→throw | `4c78c9cb` |
| **C0** — the inline re-fit triggers consolidated into one seam `Widget._reFitContainerAfterRawGeometryChange` | `c8bb8a87` |
| **Slider Path-B de-read-back** — `SliderWdgt.updateValue` derives the value from the clamped button position | `89ee825f` |

### Learned (the walls — all recorded in the path docs)
- **C1** (blanket "defer the seam outside-recalc") is **UNSOUND** — broke the clock's cross-widget read-back (`ef6fbe07`).
- **C2/C3** (in-pass convergence / remove the seam) are **blocked while read-back persists**: the DRIVE case
  converts but shares the seam arm with the clock, and the REACT (scroll) arm stays synchronous → C3
  unachievable, no enforcement payoff. **The seam (C0) is the stable INTERMEDIATE.** (`ceff7616`)
- **Blanket pending-aware accessors DIVERGED** (16→18 failures): the same accessor serves both
  "where it's heading" (pending) and "where it is now" (applied) readers — one accessor can't be both.

**The insight tying it together:** the symptom (synchronous re-fits / the seam) cannot be removed until the
ROOT (read-back) is fixed. That fix is **Path A**.

## 4. The paths

- **Path A — pending-aware READS — FALSIFIED for the container path (2026-06-20), do NOT pursue.** The idea
  (opt-in `effective*` reads; convert the container content-sizing path to read pending geometry) was built and
  tested: it is not merely non-byte-safe but **incorrect** — `_adjustContentsBounds` bakes its size via a
  non-invalidating `silentRawSetBounds`, so reading pending bakes a mid-settle transient (over-sized the scroll
  content by 43px; slack +43 vs the applied read's 0). The synchronous re-fit/convergence is **load-bearing**
  precisely because it re-reads APPLIED geometry after children settle. Reverted to docs-only.
  → **`deferred-layout-path-a-design.md` §11** (the instrumented finding).
- **Path B — per-site de-read-back — THE NEXT STEP** (constraint-entangled handlers: slider [DONE `89ee825f`],
  then the clock-square / window-fit resize handlers, then scrollbar / grab-anchor / window-collapse). Each
  derives/hands its value forward instead of reading the moved geometry back. This is the ONLY surviving enabler
  for deferring the seam (Path A can't substitute — a fixed-point re-fit must read applied, not pending).
  → **`softwrap-deferred-layout-conversion-plan.md`** §1/§2/§6a/§6b (C1 UNSOUND ⇒ #20 gated on Path B).
- **The inline re-fit trigger arc (C0–C3)** — the synchronous container re-fit seam. **C0 + C1 done; the in-pass
  cascade arm is now DEFERRED via the RE-QUEUE (shipped 2026-06-21).** Naive no-op removal was a wall (probe broke 7
  tests); the re-queue (enqueue the container into the until-loop) converges byte-identically. Remaining: the twin +
  lint [E], then transport. → **`deferred-layout-c2-execution-plan.md`** (RESULT + SHIPPED) + `softwrap…` §6b.1.
- **Transport (deferred drags)** — the hand/grab case; cadence-sensitive (needs the torture soak); a separate
  later pass. The deferred clamp `fullMoveWithin` already exists. → **path-a-design.md** §9 step 5.

## 5. STATE — Path B + C1 + the in-pass DEFERRED RE-QUEUE shipped; next = the twin + lint, then transport (see the C1 note below)

Path A is falsified (§4); the seam can only be deferred once no content widget / container re-fit reads geometry
back synchronously. So the next step is **Path B per-site de-read-back**, continuing from the slider pilot
(§6a, `89ee825f`).

1. **De-read-back the content-sizing chokepoint — SHIPPED (`fa0d7961`).** `rawSetWidthSizeHeightAccordingly` HANDS
   its resulting height forward (returns it; the clock its square side, the ratio widgets their ratio'd height); the
   container re-fits that *mutate-then-read-back* — `WindowWdgt._adjustContentsBounds` (`desiredHeight = @contents.height()`
   after the sizing) — now use the RETURN value instead (base Widget + 8 overrides). Byte-identical (the return is the
   height read at the source, immediately after the synchronous mutation). This is the slider pattern generalised to
   the square/ratio constraint handlers. (`SimpleVerticalStackPanelWdgt`'s `stackHeight += widget.height()` left as a
   parallel byte-safe follow-up — not needed for the seam.)
2. **Then the remaining read-back handlers** one at a time (scrollbar, grab-anchor/ratio, window-collapse).
3. **Verify:** full suite 165/165 dpr1/dpr2/WebKit + smoke-apps, ZERO recaptures; **plus the torture soak** — this
   is the cadence-sensitive clock/window clamp class. Oracle: `macroWindowWithAClockInAWindowConstructionTwo`,
   `macroClockInWindowKeepsSquareOnResize`, `macroDocumentScrollsMixedTextAndClocks`.

**Why this unlocks the whole aim:** once a content widget can resize without a synchronous geometry read-back, C1
(defer the seam outside a pass → invalidate the container → re-fit on the cycle) becomes SOUND, C2 makes the
REACT-case `_reFitToContents` a true in-pass fixed point, and C3 deletes the inline seam (+ tightens lint [E]) →
every container re-fit then happens only inside `recalculateLayouts` (end of `doOneCycle`) or a public-method
flush = the all-deferred end state.

**C1 SHIPPED (2026-06-20) — the seam now DEFERS primary changes; the cross-widget cascade stays synchronous.**
The naive "defer the seam outside a pass" broke the nested-window clock resize
(`macroWindowWithAClockInAWindowConstructionTwo` 4-6 went huge) because it deferred the seam MID-cascade — the
clock↔inner-window↔outer-window clamp needs the seam's synchronous *iteration*, which a single deferred pass loses.
**Fix: a world counter `world._reFittingContents`** (bumped around each container `_reFitToContents`) marks "inside
a re-fit cascade". The seam now has three states — inside `recalculateLayouts` → synchronous; inside a cascade
(`_reFittingContents > 0`) → synchronous (= the C0 behaviour, so it still converges); a **PRIMARY change outside
both → DEFER** (`invalidate` → next cycle). So primary geometry changes defer to the cycle (real progress) while
cascades stay synchronous (byte-identical AND the nested clock converges). Verified byte-identical: suite 165/165
dpr1+dpr2+WebKit, smoke-apps 12/12, the clock/DRIVE/REACT oracle all green. **This is C1 done.** A feasibility probe
(2026-06-20) stubbing the seam's in-pass re-fire to a **no-op** broke 7 SystemTests across all three families (5
scroll/REACT, 2 stack/window) — so the in-pass re-fire is load-bearing: the freefloating-content→container re-fit
notification has no clean deferred home (a freefloating child's invalidate doesn't climb; the `recalculateLayouts`
walk-up stops at freefloating widgets, WorldWdgt:924-927; `invalidateLayout` throws mid-pass). The scroll/REACT arm
broke INDEPENDENTLY of the clock, so a clock-only "one-shot constraint solve" could never enable C3. **BUT the wall
is the NAIVE no-op removal, not in-pass convergence itself — and the fix WORKS: the DEFERRED RE-QUEUE is SHIPPED
(2026-06-21).** The seam's in-pass synchronous re-fit now enqueues the affected container into the `recalculateLayouts`
until-loop (`layoutIsValid=false` + push; no throw, no climb; skips a container mid-`_adjustContentsBounds`) so the
relayout runs in the loop, not in the mutator = the aim. All 7 probe tests pass; 165/165 dpr1+dpr2+WebKit, smoke-apps
OK, byte-identical (zero recapture). The twin `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` got the same in-pass
re-queue (2026-06-21; soak 6 runs 0 flaky). **Remaining toward all-deferred = the ~40 residuals mapped in
`deferred-layout-residuals-audit.md`** (scroll-input, drag/drop, menu, collapse, content-edit, Slider/LabelButton,
the `rawSetExtent`→`reLayout` root), then lint [E]. Full design + verification:
`deferred-layout-c2-execution-plan.md` (RESULT + SHIPPED).

## 6. Doc map
- **`deferred-layout-OVERVIEW.md`** — THIS doc (entry point: aim, state, paths, next step).
- **`deferred-layout-c2-execution-plan.md`** — the C2 arc: the DAG model of the clock/window cascade, the
  feasibility-probe finding (naive removal is a wall), and the SHIPPED deferred re-queue (seam + twin in-pass).
- **`deferred-layout-residuals-audit.md`** — the full inventory (2026-06-21) of the ~40 synchronous relayouts still
  at non-flush points (scroll-input, drag/drop, menu, collapse, content-edit, Slider/LabelButton, and the structural
  `rawSetExtent`→`reLayout` root) — the map of the remaining campaign toward all-deferred, with a suggested order.
- **`deferred-layout-path-a-design.md`** — Path A (the next step): why blanket pending-aware accessors fail, the
  per-reader design, the pending-vs-applied reader audit, sequencing, acceptance/canary tests, the helper.
- **`softwrap-deferred-layout-conversion-plan.md`** — the originating case (soft-wrap) + the "model is
  intermediate" finding + the Path A/B taxonomy + the inline-trigger arc (§6b/§6b.1: C0–C3 + the verify-first
  & DRIVE-case findings) + the slider pilot (§6a, done).
- **`deferred-layout-slice2-completion-plan.md`** — state after Phase 3b + the flow rule (#17) + #18; the full
  gauntlet commands (historical "primary state" doc, now superseded as entry point by THIS overview).
- **`deferred-layout-refit-and-add-design.md`** — the Phase-1 design-of-record / phase map.
- **`deferred-layout-16-macro-breakages.md`** — the 16-macro breakage catalogue + root-cause map (Path A's
  acceptance set).

## 7. Commands + gotchas (self-contained)
- **Build:** `cd Fizzygum && ./build_it_please.sh` (runs the lint; expect `0 violations (A/B/C/D/E)`).
  `--keepTestsDirectoryAsIs` while iterating; full build needed before running the suite (recopies tests).
- **Suite:** `cd Fizzygum-tests && pkill -9 -f "Chrome for Testing|chrome-headless|puppeteer|webkit"; node
  scripts/run-all-headless.js --shards=5` (dpr1); `--dpr=2`; `--browser=webkit`. Single test:
  `node scripts/run-macro-test-headless.js SystemTest_<name>` (`PRELUDE_JS=…`/`LOG_FILE=…` for instrumentation).
- **App-launch gate (mandatory for any layout change):** `node scripts/smoke-apps-headless.js`.
- **Soak (cadence-sensitive changes only, e.g. transport):** `caffeinate -i node scripts/torture-headless.js
  --dprs=2 --speeds=fastest --shards=8 --minutes=20`.
- **Recapture (sanctioned benign shifts):** `node scripts/capture-macro-test-references.js SystemTest_<name>
  --clean --dprs=1,2` (full flow).
- **Gotchas:** separate `cd` per repo (chaining build+test across repos → MODULE_NOT_FOUND); no `timeout` in
  this shell (use `perl -e 'alarm N; exec @ARGV' node …`); pkill zombie browsers before every suite run; commit
  via `git commit -F <file>` (never backticks/`$()` in `-m`); **ask before commit/push**.
- **Key code:** accessors read `@bounds` (`src/basic-widgets/Widget.coffee`); `invalidateLayout` (~:3701; throws
  during recalc — the flow-rule guard); the seam `_reFitContainerAfterRawGeometryChange` (~:1607);
  `recalculateLayouts`/`_recalculateLayoutsCore` (`src/WorldWdgt.coffee` ~:850); container re-fit
  `_adjustContentsBounds`/`_reFitToContents` (`ScrollPanelWdgt`/`SimpleVerticalStackPanelWdgt`/`WindowWdgt`).

# A specified widget background that silently never painted — find the mechanism

> ## ✅ EXECUTED IN FULL — 2026-08-13. Root cause found, fixed, regression-tested.
>
> **Root cause (Fizzygum, not the rasterizer).** `TextWdgt` and `SimpleTextWdgt` declared
> `@backgroundColor = nil, @backgroundTransparency = nil` as constructor **`@`-parameters**. A
> CoffeeScript `@param` in a signature compiles to an **unconditional** `this.x = x`, so every
> construction wrote `nil` over `Widget`'s class-level default `backgroundTransparency: 1`
> (`Widget.coffee:124`) — and `StringWdgt`'s own *"properties that override existing ones only
> when passed"* guard (`StringWdgt.coffee:216-217`) could not undo a field that had already been
> written. That `nil` reached
> `backBufferContext.globalAlpha = @backgroundTransparency` in
> `StringWdgt::_prepareTextBufferContext` as **`globalAlpha = undefined`** — an invalid canvas
> assignment which HTML5 says to IGNORE, but which SWCanvas stores raw and some engine builds
> then composite at NaN coverage. The `fillRect` ran with the correct `fillStyle` and the correct
> 400×34 extent and **painted nothing**, raising no error anywhere.
>
> **The decisive measurement** (instrumenting the fill site itself): immediately after the
> `fillRect`, the buffer read `0,0,0,0` at three sampled points, while a **control** fill at an
> explicit `globalAlpha = 1` on the same context painted `230,230,130,255`. That isolates the
> alpha, not any rasterization difference. 28 fills were silently dropped in that one test.
>
> **⚠ BOTH of §0's "critical reframes" were WRONG, and each cost time — recorded so the next
> reader does not inherit them:**
> 1. **REFRAME 2 is FALSIFIED.** The mechanism is NOT indirect. It is `fillRect`'s **own**
>    direct arm — exactly the entry point the missing paint uses. Measured across engine
>    builds: `globalAlpha = undefined` + `fillRect` paints nothing at `45dffae`, and paints
>    correctly from **B1 `8f11434`** (which removed `fillRect`'s direct arms) onward.
> 2. **The bisect in §2.2 was MISATTRIBUTED**, and the cause is a build artifact: at B1
>    `8f11434` **`dist/swcanvas.min.js` was STALE**. Its `build-info` names commit `f3e6ac9`
>    (11:01:18) while its own unminified `dist/swcanvas.js` names `45dffae` (11:11:52). The
>    browser loads the **minified** bundle, so it was still running pre-Phase-A code at B1; B2
>    `838b9f7` merely re-synced the two. Bisecting a vendored engine **through the browser** is
>    bisecting the minified artifact — verify `swcanvas.min.build-info.js`, not just the SHA.
>    (Same trap, third sighting — cf. the D2 scale-path arc's "stale min = phantom all-green".)
>
> **Fix.** `TextWdgt` + `SimpleTextWdgt` now take `backgroundColor`/`backgroundTransparency` as
> **plain** parameters and forward them, letting `StringWdgt`'s existing guard assign them only
> when passed. `_prepareTextBufferContext` additionally coerces an absent transparency to `1`
> rather than handing the canvas a nil, because this failure mode is invisible rather than loud.
>
> **Proof the fix is the cure, not the engine:** with the buggy pre-B2 engine still vendored, the
> fix alone restored the band — 11839 px at the reference's exact bbox (400×34 @ 230,150), vs
> **zero** such pixels before. (The residual few-px delta there is the old engine's known
> hairline/alpha convention difference, and it disappears on the pinned engine.)
>
> **Regression test:** `SystemTest_macroSpecifiedBackgroundActuallyPaints` — deliberately
> **assertion-only** (no screenshots, so no reference images and no dpr axis). Verified to FAIL
> on the pre-fix tree (`found: undefined` on both field assertions). ⭐ Its *pixel* assertion
> **passed** on the pre-fix tree, because the currently pinned engine tolerates an undefined
> alpha — empirical proof that a screenshot test alone could NOT have caught this, and the
> reason the guard asserts the FIELD.
>
> **Follow-ups — CLOSED the same day (2026-08-13), owner-directed.**
> - **The upstream half is fixed.** SWCanvas `e1d8c4a`: `globalAlpha` is no longer a plain public
>   field but a **validated accessor pair**, in the same style as `lineWidth` — an infinite / NaN /
>   out-of-range assignment is IGNORED and the previous alpha stands, per HTML5. This removes the
>   half of the mechanism that made the failure SILENT: a bad alpha can no longer zero a fill.
>   SWCanvas test `070-globalalpha-invalid-assignment-ignored` pins it (invalid ignored in BOTH the
>   readback and the painted pixels; the boundaries 0 and 1 still apply; `globalAlpha` 0 still draws
>   nothing, proving it was not "fixed" by clamping; save/restore round-trips), and was verified to
>   FAIL without the fix. Vendored into Fizzygum with the pin bumped.
> - **The remaining Fizzygum readers are handled.** `Appearance.coffee`'s
>   `backgroundTransparencyNormalPass` policy and `AnalogClockAppearance` both assigned
>   `@widget.backgroundTransparency` straight to `globalAlpha`; both now coerce with `? 1`.
>   ⚠ **Correction to this banner's first draft:** the other three sites —
>   `RectangularAppearance`, `SimpleImageWdgt`, `VideoPlayerCanvasWdgt` — do NOT skip a background
>   fill. They use the field in **`isTransparentAt` (hit-testing)**, and their
>   `backgroundTransparency?` existence check was **vacuous, not buggy**: `nil > 0` is already
>   false, so the outcome never differed. With the field now an invariant, that dead check is
>   collapsed into the meaningful `> 0` test.

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-13, immediately after the SWCanvas one-rect-fill campaign closed
(SWCanvas `main` `16e4ed9`, Fizzygum `fb087298`, Fizzygum-tests `10af6a144` — all pushed).
Every `file:line` below was grepped fresh at those SHAs; **lines DRIFT — the quoted code and
method names are authoritative, re-grep before trusting a number.**

**MANDATE.** Find and ELIMINATE the mechanism by which a widget's explicitly-specified
`backgroundColor` was never painted, so the class cannot recur. This is not a survey: the
deliverable is a root cause with a regression test, and either a fix or a written, evidenced
decision that the current behaviour is correct. A workaround that merely makes the symptom
go away in these two tests is an explicit FAILURE of this plan.

---

## §0 Orientation

**Fizzygum** is a CoffeeScript GUI framework rendering a whole windowed desktop onto one
HTML5 canvas. Its software rasterizer, **SWCanvas**, is vendored by pin
(`Fizzygum/vendor/swcanvas.pin`). 293 SystemTests compare canvas screenshots byte-exactly
against committed references. Umbrella layout and commands: `Fizzygum-all/CLAUDE.md`; run
everything through the `fg` wrapper with an absolute path
(`/Users/davidedellacasa/code/Fizzygum-all/fg …` — cwd is a trap).

**Where this came from.** The one-rect-fill campaign
(`"/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas"/plans/one-rect-fill-pipeline-and-fill-arm-removal.md`,
banner `✅ EXECUTED IN FULL`) removed all four parity FILL fast paths from SWCanvas, so
rect/roundRect/stadium fills take one generic pipeline. It moved 165 Fizzygum references,
all classified and owner-eyeballed. 163 of them were two honest convention classes
(boundary hairlines; ±1 alpha composition). **Two were not**, and they are why this plan
exists:

- `SystemTest_macroSliderTextSliderPatchCycle`
- `SystemTest_macroSliderTextTwoWayPatchCycle`

In their OLD references, a `SimpleTextWdgt` shows **hollow glyphs on bare desktop grey**
(`205,205,205`). In the NEW ones it shows **solid glyphs on a yellow band** — exactly the
`230,230,130` its macro specifies. The owner confirmed the new render is correct and the
references were re-baselined. **So the symptom is FIXED. What is unknown is WHY**, and a
specified fill that silently does not paint is a class that can hide anywhere.

### ⚠ CRITICAL REFRAME 1 — the bug is INVISIBLE in the current tree. You must go back to see it.

The references now encode the CORRECT render, and the shipped engine paints it. Running the
suite today shows nothing. **To reproduce, vendor a pre-B2 SWCanvas** (§3 Step 1). Expect
those two tests to FAIL against today's references while you do — that failure IS the
reproduction, not a regression you introduced.

### ⚠ CRITICAL REFRAME 2 — the missing paint and the trigger are DIFFERENT ENTRY POINTS. Do not hunt for a rasterization difference.

The paint that goes missing is a **`fillRect` into a back buffer**
(`Fizzygum/src/basic-widgets/StringWdgt.coffee:746-753`):

```coffee
if @backgroundColor
  backBufferContext.save()
  backBufferContext.fillStyle = @backgroundColor.toString()
  backBufferContext.globalAlpha = @backgroundTransparency
  backBufferContext.fillRect 0, 0, Math.round(@width()), Math.round(@height())
  backBufferContext.restore()
```

The commit that flips the behaviour is **B2, which removed the `fillRoundRect` direct fill
ladder** — a different entry point. Bisected precisely (§2.2): Phase A and B1 (which removed
`fillRect`'s OWN direct arms!) both leave the bug in place; B2 removes it. A change to
`fillRoundRect` dispatch cannot directly alter what a `fillRect` draws, so **the mechanism is
INDIRECT** — something in Fizzygum is conditioned on rendering output or timing, not on the
fill call itself. Five direct-rasterization explanations were probed and falsified (§4);
re-running them is wasted effort.

---

## §1 Architecture you need (verified at the SHAs above)

### 1.1 How a StringWdgt background is supposed to reach the screen

1. `StringWdgt::_createRefreshOrGetBackBuffer` (`StringWdgt.coffee:773`) builds — or reuses —
   the widget's rendered bitmap. **Back buffers are globally cached and shared**:

   ```coffee
   cacheKey = @createBufferCacheKey @horizontalAlignment, @verticalAlignment
   cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
   if cacheHit? then … return cacheHit
   ```

2. `StringWdgt::createBufferCacheKey` (`StringWdgt.coffee:656`) composes ~22 fields, and
   **it DOES include the background** — verified, do not assume otherwise:

   ```coffee
   @extent().toString() + "-" + … + @color.toString() + "-" +
   (if @backgroundColor? then @backgroundColor.toString() else "transp") + "-" +
   (if @backgroundTransparency? then @backgroundTransparency.toString() else "transp") + …
   ```

   So a naive "two widgets collide on one cache entry and the background is lost" is already
   ruled out by construction: change the background and you change the key. `TextWdgt` has
   its own override at `TextWdgt.coffee:414` — check BOTH (`SimpleTextWdgt extends TextWdgt
   extends StringWdgt`).

3. Painting blits that buffer. Widgets do not repaint continuously — they repaint when
   marked dirty and their damage is flushed.

### 1.2 Invalidation is PRIVATE by design

`Widget::_changed` (`Widget.coffee:3170`) and `Widget::_fullChanged` (`Widget.coffee:3212`)
are underscore-private, and the codebase has a standing rule — **no public repaint verb**
(umbrella memory `cross-invalidation-audit-and-gate`, and there is a gate enforcing it). The
macro that builds the fixture assigns the field directly:

```coffee
backgroundColor = Color.create 230, 230, 130
```

**A plain field assignment runs no setter and marks nothing dirty.** That is the first thing
to look at (§3 H1) — but note it is not sufficient on its own to explain the bug, because
any LATER repaint recomputes the cache key (which includes the colour), misses, and rebuilds
with the yellow. So the real question is: *what decides whether that widget repaints at all
during the test, and why is that decision sensitive to the rasterizer?*

### 1.3 The plausible engine→Fizzygum coupling: damage

Fizzygum repaints damaged rectangles. If changed pixel output produces different damage
rects, a DIFFERENT set of widgets gets repainted. That is the only cheap, general mechanism
by which a rasterization change can decide whether some widget rebuilds its buffer. Related
machinery worth knowing before you start (each has an umbrella memory note):
`WorldWdgt.immutableBackBufferGeneration` (`WorldWdgt.coffee:223`) and the island buffer
cache (`TransformFrameWdgt.coffee:498-501`); the occlusion/coverage-claim code in
`Widget.coffee:~2730-2755` (a widget can claim to COVER a region, letting painting behind it
be skipped — a wrong claim silently loses paint); and the screenshot gate, which deliberately
does NOT force a repaint before capturing (umbrella memory
`broken-rect-staleness-invisible-to-screenshots`), so a stale buffer is photographed exactly
as it stands.

---

## §2 Evidence already in hand — do not re-derive

### 2.1 The pixels

| | band pixel | glyphs |
|---|---|---|
| OLD reference | `205,205,205` (bare desktop) | hollow outline |
| NEW render | `230,230,130` (exactly as specified) | solid |

Both differ in FILLS only, and both belong to the same widget. The macro specifies
`Color.create 230, 230, 130`; the new render matches it exactly. Deterministic across runs
(3/3), all 4 images of each test, at dpr 1 and dpr 2.

### 2.2 The bisect (SWCanvas commits, all on `main`)

| SWCanvas commit | what it removed | that test |
|---|---|---|
| `45dffae` Phase A | `Rasterizer._fillAxisAlignedRect` | **passes** (bug present, matches old ref) |
| `8f11434` B1 | `fillRect`'s AA + rotated direct arms | **passes** (bug present) |
| `838b9f7` B2 | `fillRoundRect`'s direct fill ladder | **fails** (bug GONE — background appears) |

Re-run this bisect only if you doubt it; it cost ~6 min via §3 Step 1's vendor loop.

---

## §3 The work

### Step 0 — orient (5 min, no changes)

`/Users/davidedellacasa/code/Fizzygum-all/fg status`. Expect all repos clean. Read this plan
and §4 before touching anything.

### Step 1 — REPRODUCE by vendoring the pre-B2 engine (~5 min)

The vendored bundles are gitignored; only `vendor/swcanvas.pin` is tracked, so this is a
local, fully reversible swap.

```bash
SWC="/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas"
VEN="/Users/davidedellacasa/code/Fizzygum-all/Fizzygum/vendor/swcanvas"
git -C "$SWC" show 8f11434:dist/swcanvas.js     > "$VEN/swcanvas.js"      # B1 = bug PRESENT
git -C "$SWC" show 8f11434:dist/swcanvas.min.js > "$VEN/swcanvas.min.js"
/Users/davidedellacasa/code/Fizzygum-all/fg build
/Users/davidedellacasa/code/Fizzygum-all/fg test SystemTest_macroSliderTextSliderPatchCycle
```

**PROVE the swap is live before believing any result** (absence alone is also what a broken
build looks like — use a PAIR): `StadiumOps` must be PRESENT in
`Fizzygum-builds/latest/js/fizzygum-boot-sw-min.js` on a pre-B3 engine, and `RectOpsAA` must
also be present (the positive control that the grep works and a real bundle is embedded).

Expect: the test FAILS against today's references, and
`fg diffpage SystemTest_macroSliderTextSliderPatchCycle` shows the yellow band MISSING in the
"now" column. That is the reproduction. **Restore with**
`git -C .../Fizzygum checkout -- vendor/` is NOT enough (bundles are ignored) — re-vendor
properly: `cd Fizzygum && ./scripts/vendor-swcanvas.sh --source "$SWC"` then `fg build`.

### Step 2 — instrument the widget, do not guess (the core of this plan)

With the bug reproduced, answer these in order. Each is a direct observation, not a theory:

1. **Is `_createRefreshOrGetBackBuffer` called for that widget at all after the macro sets
   `backgroundColor`?** Log calls with the computed `cacheKey`. If it is never called, the
   widget is blitting a stale buffer → jump to H1. If it IS called, log whether it took the
   `cacheHit` branch and what the key contained (does the key show the yellow or `transp`?).
2. **What is `@width()`/`@height()` at buffer-build time?** The fill is
   `fillRect 0, 0, Math.round(@width()), Math.round(@height())` — a zero/NaN dimension paints
   nothing while everything else about the widget looks right.
3. **What is `@backgroundTransparency`?** (default `1`, `Widget.coffee:124`.) The fill runs at
   `globalAlpha = @backgroundTransparency`; a small value paints nearly nothing.
4. **Then flip to the post-B2 engine and diff the SAME log.** The difference between the two
   logs IS the mechanism. This is the highest-value single experiment in this plan — a
   before/after of Fizzygum's own decisions, not of pixels.

Instrumentation notes: the harness page is `worldWithSystemTestHarness.html`; a `console.log`
in `.coffee` needs `fg build`. Prefer logging into a global array and reading it at the end.

### Step 3 — test the ranked hypotheses

**H1 — a directly-assigned `backgroundColor` never marks the widget dirty, so it keeps
blitting a buffer built before the colour existed.** Evidence for: invalidation is private by
design (§1.2) and the macro assigns the raw field; the OLD render is exactly "the widget as
it was BEFORE the colour was set". Evidence needed: Step 2.1's answer. Decisive test: in a
scratch copy of the macro, set `backgroundColor` BEFORE the widget is first painted (or force
a relayout after) and see whether the yellow appears on the PRE-B2 engine. If yes, H1 holds
and the real defect is that a stale buffer is photographable at all.
⚠ If H1 holds, the fix is NOT "make the macro poke a private method". Candidates: make
`backgroundColor` a proper setter that invalidates; or have the buffer-cache lookup notice
its key has changed. Weigh against the no-public-repaint-verb rule.

**H2 — damage/coverage: the widget IS repainted in one engine and not the other because the
changed pixels change the damage rects** (§1.3). Decisive test: log the damage rectangles
per flush around that widget on both engines and diff. If H2 holds, the defect is that
correctness depends on an unrelated widget's pixels, and the coverage-claim code
(`Widget.coffee:~2730`) is the place to look — especially whether some widget CLAIMS coverage
it does not paint.

**H3 — the island/immutable-buffer generation counter** (`WorldWdgt.immutableBackBufferGeneration`,
`TransformFrameWdgt.coffee:498`). These tests place widgets over a rotated/transform frame in
the sibling suite; a generation mismatch reuses a stale island buffer. Decisive test: log the
generation and the `_islandBufferGeneration` at capture time on both engines.

**H4 — the macro's own ordering.** These two tests share a provenance note about a
`SimpleTextWdgt` needing `maxTextWidth=true` to stay wide. If the widget is resized after its
buffer is built, `@extent()` changes the cache key and a rebuild should follow — verify it
does. This is the cheapest to eliminate; do it early.

### Step 4 — land the outcome

Whatever the mechanism, the deliverable is: a root cause stated in one paragraph; a fix (or a
written decision that today's behaviour is correct, with evidence); and **a regression test
that fails without the fix**. A pixel test alone is not enough here — the whole failure class
is "a paint silently did not happen", so prefer a structural assertion (e.g. the widget's
buffer cache key at capture time reflects the specified background). If the answer is H1, the
umbrella memory note `resetworld-state-leak-between-tests` records the house pattern: prove a
guard FAILS on a planted field before trusting it.

---

## §4 Rejected / already falsified — DO NOT RE-ATTEMPT

All five were probed on 2026-08-13 against BOTH engines (old = pinned `ad1a703`, new = the
post-removal dist), in Node, with the dispatch difference proven live:

| Hypothesis | How it was killed |
|---|---|
| `fillRoundRect` THROWS on off-surface geometry (paint aborted, error swallowed) | 0 of 16 off/partial-surface calls threw, on either engine |
| The direct arm silently drops the fill (unclipped) | Swept w/h/radius/CTM grid: **no** combo where direct painted 0 while generic painted; worst ratio 0.81 on tiny corners |
| The direct arm drops the fill UNDER A CLIP | Swept tier-0 rect clips AND bitmask clips: 0 combos where direct painted <50% of generic |
| `fillStyle`/`strokeStyle`/`globalAlpha` side effects differ (the "converted paint's side effects are contract" class) | Identical before/after on both engines; a subsequent ambient-style paint produced identical pixels |
| The call clobbers the current default path | Path built, `fillRoundRect` called, path filled — correct pixels on both engines |

Also ruled out: **swallowed page errors** (no error in any run log, either engine) and
**nondeterminism** (3/3 identical runs; the gate's own single-process re-verify agreed).

Do not "just recapture" these two tests to make something go away — they have already been
recaptured to the CORRECT render. The open question is the mechanism.

---

## §5 Verification protocol

- Build after every `.coffee` change: `fg build` (PASS = 0 violations).
- Inner loop: `fg presuite` (~2 min). Commit point: `fg gauntlet` (~5 min, 14 legs incl.
  WebKit). Both via the absolute `fg` path.
- Any pixel divergence gets eyeballed via `fg diffpage <test…> --dprs=1,2` BEFORE any
  recapture, and any recapture goes through `fg recapture --auto` (gated; prints
  COMPLETE / INCOMPLETE / INCONCLUSIVE — treat INCONCLUSIVE as "measured nothing", never as
  a pass).
- ⚠ Leave the vendored engine back on the pin when you finish:
  `cd Fizzygum && ./scripts/vendor-swcanvas.sh --source "$SWC" && fg build`, then confirm
  `fg suite` is green.

## §6 References

- `SWCanvas/plans/one-rect-fill-pipeline-and-fill-arm-removal.md` — the parent campaign; its
  EXECUTION STATUS box holds the Phase C findings and the falsification list in full.
- `SWCanvas/DIRECT-RENDERING-SUMMARY.MD` §9 entries 15–16 — what was removed and why.
- `Fizzygum-tests/DETERMINISM.md` — read before calling anything a flake.
- Umbrella memory: `swcanvas-one-rect-fill-plan`, `broken-rect-staleness-invisible-to-screenshots`,
  `cross-invalidation-audit-and-gate`, `island-buffer-cache-landed`, `occlusion-culling-landed`,
  `recapture-tool-false-green-defects`.

## Start-prompt for the executing session

> Execute `Fizzygum/docs/plans/dropped-background-fill-investigation.md` cold, from the
> `/Users/davidedellacasa/code/Fizzygum-all` umbrella. Read it in full first — §0's two
> critical reframes are load-bearing: the bug is INVISIBLE in the current tree (you must
> vendor the pre-B2 SWCanvas `8f11434` to reproduce it), and the missing paint is a
> `fillRect` while the trigger commit changed `fillRoundRect`, so the mechanism is INDIRECT —
> five direct-rasterization explanations are already falsified in §4, do not re-run them.
> Work Step 1 (reproduce, injection-proven), then Step 2 (instrument the widget and diff the
> SAME log across the two engines — that diff is the mechanism), then the ranked hypotheses.
> Deliverable: a root cause plus a regression test that fails without the fix. House rules:
> build before every test run; never commit/push without presenting first; any pixel
> divergence gets eyeballed before it is committed; restore the vendored engine to the pin
> when you finish.

Run this in a FRESH session — it needs a clean context and its own time budget.

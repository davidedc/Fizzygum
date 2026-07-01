# Plan — make the caret scroll-follow SINGLE-PASS (eliminate the 372 residual settle re-visits)

**Status: ✅ DONE 2026-07-01 (§4.1 + §4.2 both shipped, in ONE change to `CaretWdgt.coffee`). Suite-wide caret
scroll-follow re-visits 372 → 0 (measured dpr2). Byte-exact: gauntlet dpr1/dpr2/webkit 165/165 + apps/tiernaming/
settle, 0 inspector recaptures; danger-config torture pending/clean.** Everything below is the (now-executed) plan,
kept for the record. **Line numbers drift: grep the named symbol.**

> ## RESULT (2026-07-01)
> The FIRST TASK (model why `cart` resets to 0) resolved to: **`Point.floor()` clamps y (and x) to `≥0`
> (`Math.max(Math.floor(y),0)`).** When the content is scrolled up, a slot above the world origin has a NEGATIVE
> absolute y; clamping the caret to 0 there made `scrollCaretIntoView` (which scrolls by `ft − caretWidget.top()`)
> advance only ONE viewport-step (`ft`) per pass, so a far caret crawled to its mark over `distance/ft` passes.
> The `else if bottom > fb` (down) branch uses positive coords, so it was already one-shot — matching §2's note.
>
> **Two byte-exact single-pass properties, both in `CaretWdgt`:**
> - **§4.1 (un-clamped placement).** `_oneScrollCaretIntoViewPassNoSettle` places the caret with
>   `new Point (Math.floor pos.x), (Math.floor pos.y)` instead of `pos.floor()` — integer-floored but WITHOUT the
>   clamp-to-≥0. The caret's real (possibly negative, off-viewport, harmlessly clipped) position lets
>   `scrollCaretIntoView` compute the FULL scroll delta in ONE call. `scrollCaretIntoView` itself is UNTOUCHED.
> - **§4.2 (converge on the CONTAINERS, not the caret).** `_reLayout`'s stable check now tests whether the scroll
>   container (`@parent`) and the target text (`@target`) moved this pass — NOT whether the caret itself moved. The
>   caret's reposition to its slot is an exact, idempotent one-shot, so a pass that ONLY repositioned the caret is
>   already at the fixed point and needs no confirming re-visit. **This removed the dominant re-visit** (the "verify"
>   pass every time the caret advances a slot: `macroWrappingTextFieldResizesOK` alone was 350 of the 372).
>
> **Measured (instrument-and-LOOK via `./fg suite`, reverted): the 372 re-visits localised to `macroWrappingText
> FieldResizesOK` (350) + `macroMultilineTextInputScrollsWell` (6) + a long tail. §4.1 alone: 372→370 (the up-scroll
> case is rare). §4.1+§4.2: 372→0.** §4.3 (internal loop) was NOT needed.

> ⚠ **This edits DETERMINISM-CRITICAL caret code.** The SystemTest suite asserts byte-exact SWCanvas pixels; the caret's
> scroll-follow converges to an EXACT pixel fixed point that many tests screenshot. Any change that lands 1px off breaks
> the suite. Treat the bar accordingly: byte-exact dpr1/dpr2/webkit + determinism torture, or it does not ship. This is
> a PURITY refinement (fewer settle passes), NOT a correctness fix — the current behaviour is correct. **If it can't be
> made byte-exact with reasonable effort, LEAVE IT: the residual is benign** (bounded, deterministic, and the settle
> loop's iteration cap is now a never-fire assert).

---

## §0 — Orientation (what Fizzygum is)

**Fizzygum** is a CoffeeScript GUI framework — a "web operating system" (windows, desktop, drag-and-drop, live in-system
editing) rendered on a single HTML5 `<canvas>`, descended from Morphic.js. ~470 `.coffee` classes in `Fizzygum/src/`;
every class is a global compiled in-browser (no `require`/`import`); `nil` == `undefined`; one class per file, filename
== class name. The umbrella `/Users/davidedellacasa/code/Fizzygum-all/` is NOT a git repo; it holds three sibling repos:
- **`Fizzygum/`** — framework source (edit here) + build script + the layering lint (`buildSystem/check-layering.js`).
- **`Fizzygum-tests/`** — 165 macro SystemTests (drive the live world, compare SWCanvas SHA-256 screenshots
  **byte-exactly**) + harness + audit gates.
- **`Fizzygum-builds/`** — generated build output (never hand-edit).

Commands run via the path-correct `fg` wrapper **from the umbrella root**: `./fg build` · `./fg suite` (165 tests, dpr1,
~1.3 min) · `./fg gauntlet` (build + dpr1 + dpr2 + WebKit + apps + tiernaming + settle gates) · `./fg test <name>`.
A PreToolUse guard hook BLOCKS a wrong-cwd `Fizzygum-tests/` script run or a piped build — use `./fg` from the umbrella
root, and write gate output to a file then read it (do not pipe the build into a filter).

---

## §1 — Why this now (the arc that led here)

The "proper-layouts" arc drove the layout engine toward "measure → arrange → dirty-tree", deleting the notify-by-mutation
re-fit seam (property + geometry, both halves — Fizzygum `c637ffb1`/`65401c36`/`c7d0a616`). **Stage 6** (Fizzygum
`d1e52506`, 2026-07-01) then:
- retired the layout CONVERGENCE cap: `recalcIterationsCap` → `layoutIterationsSanityLimit`, a never-fire loud-THROW
  assertion (the silent bail-and-continue suppression is DELETED);
- assessed the 3 world phase flags (`_recalculatingLayouts`/`_inLayoutMutation`/`_batchingLayoutSettling`) as
  re-entrancy/batching guards that STAY (not convergence devices);
- pruned wasted convergence: a **NO-OP EARLY RETURN** in `WorldWdgt._recalculateLayoutsBody` (skip the settle-time
  container re-fit `_reFitMyTrackingContainerAfterSettle` when the just-settled chain-top's frame is unchanged) cut
  suite-wide peak settle re-visits **10 → 2**.

**The measured residual convergence after Stage 6** (instrumented full suite, dpr2, then reverted): **372 `CaretWdgt`
re-visits** (frame unchanged — the up-edge correctly does NOT fire; the caret re-enqueues ITSELF) **+ 8 `WindowWdgt`
re-visits** (the genuine container size-negotiation = a separate §4.2 pure-measure wall, NOT this plan). The caret
re-visits DOMINATE. The owner chose to attack them.

**This plan's goal:** make the caret's scroll-follow reach its fixed point WITHOUT the settle loop re-visiting the caret
~2–N times per scroll — i.e. the settle loop visits the caret ONCE. Ideally by computing the final scroll offset
directly (analytic single-pass), byte-exact.

---

## §2 — What the caret scroll-follow IS + the measured mechanism (LOOK, don't infer)

**The caret's `_reLayout` IS the scroll-follow.** The caret is `isLayoutInert` (overlay chrome, excluded from container
content-bounds) + childless, so it has no normal layout work — its `_reLayout` override is the whole step. Grep these:

- **`CaretWdgt._reLayout`** (`src/basic-widgets/CaretWdgt.coffee`, grep `_reLayout:`). Captures the caret + its parent
  position, runs ONE pass (`_oneScrollCaretIntoViewPassNoSettle`), then marks itself layout-fixed ONLY IF nothing moved:
  ```coffee
  _reLayout: ->
    beforeT = @top() ; beforeL = @left()
    beforeParentT = @parent?.top() ; beforeParentL = @parent?.left()
    @_oneScrollCaretIntoViewPassNoSettle()
    stable = @top() == beforeT and @left() == beforeL and @parent?.top() == beforeParentT and @parent?.left() == beforeParentL
    if stable then @markLayoutAsFixed()
    # else: stay layoutIsValid==false -> re-processed by the settle loop after the panel settles
  ```
  So convergence is detected as "a pass that moved nothing", and the caret rides the settle loop's until-loop to its
  fixed point. **This is DELIBERATE**: `gotoSlot`/`_gotoSlotNoSettle` + `_reLayout` comments state repeatedly "no
  hand-rolled convergence loop … iterates via the until-loop". (So a hand-rolled internal loop is OFF-DESIGN — see §4.)

- **`CaretWdgt._oneScrollCaretIntoViewPassNoSettle`** (grep it). ONE pass:
  1. `pos = @target.slotCoordinates @slot` — the slot's absolute coordinates in the text (`@target`).
  2. HORIZONTAL clamp — moves `@target` fully so `pos.x` lands within `[@parent.left()+viewPadding, @parent.right()-viewPadding]`.
     **This branch is ALREADY single-pass / direct** (it moves `@target` the full amount). Not the problem.
  3. `@_applyMoveToAndNotify pos.floor()` — places the caret at `pos` (floored).
  4. `@parent.parent.scrollCaretIntoView @` if inside a `ScrollPanelWdgt` and `@target.isScrollable` — the VERTICAL
     scroll-into-view. **This is where the multi-pass convergence lives.**

- **`ScrollPanelWdgt.scrollCaretIntoView(caretWidget)`** (`src/basic-widgets/ScrollPanelWdgt.coffee`, grep it):
  ```coffee
  ft = @top() + @padding ; fb = @bottom() - @padding ; fl = ... ; fr = ...
  @_positionAndResizeChildren()                       # <-- (line "730") RE-FIT: this RESETS the baseline (see below)
  marginAroundCaret = @padding (+ @extraPadding?)
  if caretWidget.top() < ft
    newT = @contents.top() + ft - caretWidget.top()
    @contents._moveTopSideTo newT + marginAroundCaret
    caretWidget._moveTopSideTo ft
  else if caretWidget.bottom() > fb ...              # symmetric
  if caretWidget.left() < fl ... else if caretWidget.right() > fr ...   # horizontal (usually already handled by step 2)
  @_positionAndResizeChildren()                       # <-- (line "750") re-fit + clamp (keepContentsInScrollPanelWdgt)
  @_reLayoutScrollbars()
  ```
- **`ScrollPanelWdgt.keepContentsInScrollPanelWdgt`** (grep it) — a boundary clamp (snaps `@contents` back if scrolled
  past the viewport edges), called inside `_positionAndResizeChildren`.

**MEASURED trajectory (instrument-and-LOOK, test `SystemTest_macroScrollPanelCaretBroughtIntoViewWhenMoved`, slot 3),
traces reverted:** the content top crawls to its fixed point in FIXED `+70px` steps, ~3–4 passes:
```
SCIV cart=0 ft=70 contT -140 -> -70    CARETPASS pT -70->0  stable=false
SCIV cart=0 ft=70 contT  -70 ->   0    CARETPASS pT  0->70  stable=false
SCIV cart=0 ft=70 contT    0 ->  70    (stable next pass)
SCIV cart=70 ft=70 contT  70 ->  70    CARETPASS pT 70->70  stable=true
```
**The crux:** `cart` (the caret's top at the START of `scrollCaretIntoView`, i.e. AFTER the line-730 `_positionAndResizeChildren`)
is **0 on every non-final pass**. So the move is always `newT = contents.top + (ft − cart) = contents.top + 70` — exactly
one `ft`-sized step. It is NOT the full delta. The number of passes SCALES WITH SCROLL DISTANCE (`distance / step`). This
is a COUPLED convergence: the caret is re-placed at `slotCoordinates` each pass (step 3) AND the line-730 re-fit resets
the baseline, so each `scrollCaretIntoView` only nets one step. **A single call does NOT bring a far-off caret into view.**

⚠ The exact reason `cart` resets to 0 each pass was NOT fully modelled (it involves how `slotCoordinates` re-derives
after `@contents`/`@target` move, plus the line-730 re-fit/clamp). **FIRST TASK of any execution: fully model this**
(instrument `slotCoordinates` return + the caret placement in `_oneScrollCaretIntoViewPassNoSettle` + `caretWidget.top()`
before/after the line-730 re-fit). You cannot write a byte-exact one-shot without knowing precisely why `cart` resets.

---

## §3 — The proven toolkit (how to work this)

1. **Instrument-and-LOOK via the SUITE (not the single-test runner).** `console.error` from page code is DROPPED by
   `run-macro-test-headless.js` but SURFACED by `run-all-headless.js` (`./fg suite`) with a `[shard N] SystemTest_<name>:`
   prefix. So: add `console.error "TAG ..."` lines in the caret/scroll code, `./fg build`, `./fg suite > out.txt 2>&1`,
   then `grep "<TestName>: TAG" out.txt`. (The traces in §2 used tags `CARETPASS` / `SCIV` / `OSCIVP`.) Revert traces
   with `git checkout <file>` when done.
2. **Reverse-probe.** Gate a candidate change behind a runtime flag or just make it and run the suite; the break-list is
   the signal. Re-measure the residual re-visit count with a per-flush `Set` of processed chain-tops (the Stage-6
   technique): declare `__seen = new Set()` at the top of `WorldWdgt._recalculateLayoutsBody`'s loop, and log when a
   widget is re-processed. Target: caret re-visits → 0 (or ≤ the 8 window ones).
3. **Pixel forensics.** `scratch/forensics.py <obtained.png> <ref.png>` classifies a mismatch (spatial shift vs colour
   vs an extra region). Dump a divergent image with `node scripts/run-macro-test-headless.js SystemTest_<name>
   --dump-failures` (writes to `.scratch/<test>/dpr<N>/`), then crop + Read the diff region.
4. **Benign inspector recapture.** Inspector tests render Widget method SOURCE + member lists; editing a method body
   shifts the rendered source. That is BENIGN — recapture with `node scripts/capture-macro-test-references.js <name>
   --dprs=1,2` (PRE-AUTHORISED), do not chase. (Editing `_reLayout`/`scrollCaretIntoView` bodies may recapture an
   inspector test that renders their source.)
5. **Byte-exact gate + the RIGHT verifier (§5).** Determinism is timing-sensitive; a caret/scroll change is a
   convergence change and MUST pass the torture, not just the gauntlet.

---

## §4 — Approaches (ordered; NONE is yet attempted on the current tree)

### §4.1 — ANALYTIC single-pass (the owner's requested approach; the target)
Make `scrollCaretIntoView` bring the caret FULLY into view in ONE call, so the caret's `_reLayout` finds it in view and
marks fixed with no (or one) settle re-visit. Because the current move is `ft − cart` with `cart` reset to 0, the fix is
to compute the scroll from a STABLE quantity — the slot's CONTENT-RELATIVE position (fixed regardless of scroll) — not
from the post-re-fit `caretWidget.top()`. Sketch:
- The slot's content-relative y = `@target.slotCoordinates(@slot).y − @contents.top()` (fixed as `@contents` scrolls).
- The final `@contents.top()` that places the slot at `ft` (with margin) = `ft + margin − slotRelY`, clamped by
  `keepContentsInScrollPanelWdgt`'s bounds. Apply THAT directly.
- Then convergence detection in `_reLayout` may need to change from "nothing moved" to "the caret is in view" so the
  correcting pass can mark fixed immediately (else you still pay one verify re-visit).
**Hazards (why this is hard + determinism-critical):** (a) the current fixed point is produced with per-step `pos.floor()`
+ the keepContents clamp + the line-730 re-fit; a one-shot must land on the EXACT same pixel or the byte-exact suite
breaks. (b) `slotCoordinates` may itself depend on the applied scroll (re-derives per pass — model it first, §2). (c)
the horizontal branch + the `else if bottom > fb` branch must stay byte-identical. **Build it incrementally: first make
the VERTICAL move one-shot while keeping the "nothing moved" stability check (should reduce passes from N to 2 — one
move + one verify — byte-exact); measure; THEN attack the verify pass separately.**

### §4.2 — Convergence-detection only (cheap partial win, try FIRST)
Leave the per-pass move as-is but let `_reLayout` mark fixed on the pass that brings the caret into view (a direct
"is the caret within [ft,fb]×[fl,fr]?" predicate) instead of "nothing moved this pass". If the per-pass move already
reaches the fixed point in the common case, this removes the trailing VERIFY re-visit (the dominant `chg=false` caret
re-visits) without touching the scroll math. Lower risk than §4.1. Measure how many re-visits it removes; if the move is
multi-step (far scroll), this alone won't fully single-pass it, but it may remove most of the 372.

### §4.3 — Internal bounded loop (byte-exact but OFF-DESIGN — only with explicit owner OK)
Loop `_oneScrollCaretIntoViewPassNoSettle` to its fixed point INSIDE `_reLayout`, then mark fixed. Byte-exact by
construction (same ops, same order; nothing else runs between the caret's settle-loop re-visits — its passes enqueue
nothing and it stays last in the work-list). It makes the settle loop visit the caret ONCE. **BUT it REVERSES the
architecture's deliberate "no hand-rolled convergence loop" choice** (documented in `gotoSlot`/`_reLayout`), and it
RELOCATES rather than eliminates the iteration (same total work). The owner's mandate frowns on "relocating" convergence.
Needs a defensive bound (the settle loop's sanity limit no longer backstops an internal loop). **Do NOT ship without
explicit owner approval** — offer it only as the safe fallback if §4.1/§4.2 can't be made byte-exact.

---

## §5 — Verification protocol (every step)
- `./fg build` (0 violations) · `./fg suite` (dpr1 165/165; dump + LOOK on any pixel fail) · `./fg gauntlet`
  (dpr1/dpr2/webkit 165/165 + apps + tiernaming + settle gates).
- **Determinism torture (REQUIRED — a caret/scroll change is convergence-sensitive).** `torture-headless.js` DEADLOCKS
  when spawned in-session (unread-stdout pipe-buffer). Use a manual danger-config loop instead: repeated
  `node scripts/run-all-headless.js --shards=S --dpr=D --speed=SP` over the configs `dpr2-fastest-s8`, `dpr2-fast-s8`,
  `dpr1-fastest-s8`, `dpr2-fastest-s4` (× a few rounds), grepping each run's output for `RECALC_NONCONVERGENCE` (must be
  ABSENT) and `failed: [1-9]` (must be 0). A ready pattern is in the Stage-6 session's `scratchpad/torture-manual.sh`.
- Kill orphan `Chrome for Testing` before each run (`pkill -9 -f "Chrome for Testing"`).
- Benign inspector recaptures are PRE-AUTHORISED; anything else must be byte-exact.
- **Never commit/push without explicit owner approval** — present a summary + proposed message and wait. Commit via
  `git commit -F <file>` (the Bash tool runs bash; backticks/`$()` in `-m` get command-substituted).

Tests that EXERCISE the caret scroll-follow (run these single, and watch in the suite): `macroScrollPanelCaretBroughtIntoViewWhenMoved`,
`macroDocumentCaretBroughtIntoViewWhenMoved`, `macroMultilineTextInputScrollsWell`, `macroEditingStringInScrollablePanelCaretAlwaysVisible`,
`macroCaretResizesOKOnUndo`, `macroCaretArrowKeyNavigation`. The dominant re-visit contributors (pre-fix) were
`macroWrappingTextFieldResizesOK` and `macroMultilineTextInputScrollsWell`.

---

## §6 — References
- **`docs/proper-layouts-geometry-seam-removal-plan.md`** §5 Stage 6 — the arc that produced the current state (cap →
  assert; no-op early-return; the residual measurement). READ its Stage 6 section first.
- **Memory `fizzygum-next-work-backlog`** — the Stage 6 result + the residual breakdown (372 caret + 8 window) + this
  plan pointer.
- **Memory `fizzygum-deferred-layout-plan`** — the prior "family 5" probe found the caret scroll-follow LOAD-BEARING
  when DEFERRED (deferring past the settle pass broke 7 scroll-follow tests). This plan is a DIFFERENT approach
  (single-pass / analytic, not deferral) — but heed why deferral failed: `scrollCaretIntoView` mutates contents geometry
  that must settle in-cycle.
- **`Fizzygum-tests/DETERMINISM.md`** — the byte-exact contract + the diagnosis playbook. READ before touching
  caret/scroll/`_reLayout` code.
- **Anchors (grep the symbol):** `CaretWdgt._reLayout` / `_oneScrollCaretIntoViewPassNoSettle` / `_requestScrollFollow` /
  `_settleScrollFollow` / `gotoSlot` / `_gotoSlotNoSettle` (all `src/basic-widgets/CaretWdgt.coffee`);
  `ScrollPanelWdgt.scrollCaretIntoView` / `keepContentsInScrollPanelWdgt` / `_positionAndResizeChildren`
  (`src/basic-widgets/ScrollPanelWdgt.coffee`); `WorldWdgt._recalculateLayoutsBody` (the settle loop + the no-op
  early-return + `layoutIterationsSanityLimit`).

---

## §7 — Honest expectation
The residual is BENIGN and this is DETERMINISM-CRITICAL caret code. Expect §4.2 (convergence-detection) to be the
tractable partial win and §4.1 (analytic one-shot) to be the hard, byte-exact-risky part. §4.3 (internal loop) is the
guaranteed-byte-exact fallback but is off-design and needs owner sign-off. **Bank any byte-exact reduction; if the last
passes resist byte-exactness, stop and leave them — the cap is a never-fire assert, so a bounded caret convergence costs
only a few settle iterations, nothing user-visible.** Do NOT force a determinism-breaking change to hit "zero".

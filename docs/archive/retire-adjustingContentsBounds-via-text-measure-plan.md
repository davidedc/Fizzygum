> **ARCHIVED — COMPLETE (2026-07-17 restructure).** VERDICT 2026-06-28: keystone FALSIFIED, leave the flag; flag later deleted anyway by a different fix
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Plan — retire the `@_adjustingContentsBounds` loop-breaker flag by giving wrapping text a pure measure

> ## ⛔ VERDICT (2026-06-28 — execution attempted, then reverted): KEYSTONE FALSIFIED → LEAVE THE FLAG
>
> **UPDATE (later same day): the FLAG itself was subsequently made correctness-unnecessary — but NOT by this plan's
> measure.** proper-layouts Phase C found the perpetual driver was a redundant priming `@contents.rawSetHeight` (a height
> WOBBLE), and DELETING that one line (not measuring it) made the arrange a fixed point; the reverse-disable gate then
> passes. So this doc's verdict — "a pure text-height *measure* cannot retire the flag" — stays TRUE and the §4 measure
> fix stays falsified; what changed is that the flag's *job* was dissolved by deletion, not measurement.
> `measureWrappedHeight` was reverted. See `proper-layouts-eliminate-suppression-booleans-plan.md` §5 Phase C/D and
> memory `fizzygum-adjustingcontentsbounds-flag`.
>
> The plan's facts were verified against the source and four targeted probes were run (a build + the 4 §3 tripwire
> tests, with `_reFitContainer`'s flag-check disabled and the in-pass enqueue atom `_markForRelayoutNoClimb`
> instrumented to capture the perpetual re-enqueue's call stack; iteration cap temporarily lowered to 12 so the
> console didn't flood). **The plan's keystone — "the flag exists to support a text-HEIGHT read-back, so a pure
> `measureWrappedHeight` dissolves its job" — is FALSE.** Corrected mechanism, with evidence:
>
> 1. **The flag suppresses a SEAM fired by a container's own in-pass mutation of its CONTENTS' geometry — not a
>    height read.** Every raw geometry setter fires the bottom-up re-fit seam `_reFitContainerAfterRawGeometryChange
>    → _reFitContainer(container)`. **This includes the "silent" setters:** `silentRawSetExtent` (`Widget.coffee`
>    ~:1609–1642) *ends with* `@_reFitContainerAfterRawGeometryChange()`, and `rawSetExtent` (~:1563) just delegates
>    to it + `@changed()` + `@_reLayoutSelf()`. So "silent" means *no repaint / no self-relayout*, **NOT** *no re-fit
>    notification*. **No setter avoids the seam — only the flag suppresses it.** (`_reFitContainer` returns early on
>    `container._adjustingContentsBounds`.)
> 2. **The proven perpetual re-enqueue is the container POSITIONING its contents, not measuring their height.** With
>    the flag-check disabled, the stack capture showed the SOLE re-enqueue site is
>    `ScrollPanelWdgt._positionAndResizeChildren → @contents.silentRawSetBounds(newBounds)` (~:399) → seam →
>    `_reFitContainer(scrollPanel)`. The merged-bounds `newBounds` is anchored on `@contents.left()/top()` (~:384),
>    which `keepContentsInScrollPanelWdgt` (~:409, `fullRawMoveBy`) repositions each pass — so the contents bounds
>    **oscillate**, the pass is genuinely non-idempotent, and the seam re-fires forever. This IS the owner's
>    "bidirectional notifications that trigger each other," but the cycle runs through **position**, not a
>    text-height read-back.
> 3. **`measureWrappedHeight` is real and byte-exact-by-construction** (`TextWdgt.getTextWrappingData` is pure —
>    writes only the memo cache, returns `[lines,slots,maxW,height]`; its `height = lines·ceil(fontHeight)` is the
>    SAME formula `_reLayoutSelf` ~:424 commits) — but it targets the *innocent* `widget.height()` READ, which is NOT
>    the seam source, so **it cannot retire this flag.** Two probes confirmed empirically: (a) wrapping at the final
>    viewport width `@width()` instead of the lagging `@contents.width()` (idempotent-width), and (b) making the
>    priming height-set `@contents.rawSetHeight`→`silentRawSetHeight`, EACH still left 3 of the 4 tripwires in
>    `RECALC_NONCONVERGENCE` — because the line-399 positioning seam is untouched by either.
>
> **Why the flag is the right abstraction.** A container that arranges its contents top-down MUST mutate their
> geometry mid-pass; every such mutation fires the self-referential seam; the flag is the clean, central "I am
> mid-pass — ignore my own re-fit notifications." Eliminating it is NOT a scoped "retire a boolean": it needs the
> FULL §4.1 measure+arrange rewrite AND making contents-positioning a per-axis DAG (§4.2) so a re-enqueued pass
> converges idempotently — the assessment's "big change," high reversal-density (cf. the soft-wrap §5 minefield).
> **LEAVE THE FLAG *in isolation*** — it is sound and load-bearing, and a *naive* measure cannot retire it. But the
> goal is NOT to accommodate it: the successor is **complete elimination via "proper layouts"** — the canonical
> roadmap **`proper-layouts-eliminate-suppression-booleans-plan.md`** (measure → non-notifying arrange → dirty-tree;
> Phases A–F), whose Phase D/E actually DELETE this flag. (NB the §4.3 "move the phase booleans into a
> `world.layoutEngine` object" idea is explicitly REJECTED there as *burying the boolean deeper*, not deleting it.)
>
> `measureWrappedHeight` (§4.1 `preferredExtentForWidth`) looked like a byte-safe down-payment, but it did NOT survive:
> proper-layouts Phase C found it only ever fed a TRANSIENT priming `@contents.rawSetHeight` (overwritten by the scroll
> arrange's own merged-bounds commit, read by nothing in between), so it removed no captured read-back, and it was
> **REVERTED** (the build's dead-method gate forced deleting the now-orphaned method). What actually made the flag's job
> moot was DELETING that priming write — the "height wobble" — not measuring it. **The probes in THIS doc were reverted;
> so was `measureWrappedHeight`; only the vertical-stack hand-forward landed.** The plan below is RETAINED as the
> investigation record: its §0–§3 (orientation + the original disable-probe) remain accurate; its **§4 fix and §6 staging
> rest on the falsified keystone — do NOT execute them to retire the flag** (follow the proper-layouts roadmap).

**Status: SUPERSEDED by the verdict above (keystone falsified 2026-06-28). Originally written to be executed COLD.**
**Line numbers drift: grep the named symbol, never trust a line number in this doc.**

**One-line goal.** `@_adjustingContentsBounds` is a per-container boolean that suppresses a layout notification which
would otherwise re-enqueue a container *while it is mid its own layout pass* — a loop-breaker for a bidirectional
(invalidate-up / re-layout-down) notification cycle. A disable-probe (this plan, §3) **proved it is correctness-critical,
not an optimization** — and that the genuine non-convergence it prevents is **localized almost entirely to ONE widget,
`SimplePlainTextScrollPanelWdgt` (wrapping text in a scroll panel)**. The cycle is: *the container sizes the text to a
width → the text re-wraps → its height changes → the container re-fits → resizes the text → …*, mediated by **committing
the wrap and reading the applied height back**. **Break that cycle by giving wrapping text a side-effect-free
`measureWrappedHeight(width)` so the container sums a MEASURED height instead of mutate-and-read-back — then the flag's
one real job disappears and it can be removed (staged-probe-confirmed).**

**This is a determinism-sensitive architecture change, the bounded 80/20 of the architecture assessment's §4.1.** It is
NOT a quick edit (byte-exact text measurement must reproduce wrap geometry without committing it, and clear the soak).
If the measure cannot be made byte-exact with reasonable effort, **leave the flag** — it is sound, documented, and
load-bearing today; the only thing lost is one loop-breaker boolean.

---

## §0 — Orientation + why this now

**Fizzygum** is a CoffeeScript GUI framework — a "web operating system" (windows, desktop, drag-and-drop, live
in-system editing) rendered on a single HTML5 `<canvas>`, descended from Morphic.js. ~470 `.coffee` classes in
`Fizzygum/src/`; every class is a global compiled in-browser (no `require`/`import`); `nil` == `undefined`; one class
per file, filename == class name. The umbrella `/Users/davidedellacasa/code/Fizzygum-all/` is NOT a git repo; it holds
three sibling git repos that must stay siblings:
- **`Fizzygum/`** — framework source (edit here) + the build script + the layering lint (`buildSystem/check-layering.js`).
- **`Fizzygum-tests/`** — 165 macro SystemTests (drive the live world, compare SWCanvas SHA-256 screenshots
  **byte-exactly**) + the test harness + the audit gates + the torture harness.
- **`Fizzygum-builds/`** — generated build output (never hand-edit).

Commands run via the path-correct `fg` wrapper **from the umbrella root** `/Users/davidedellacasa/code/Fizzygum-all/`:
`./fg build` · `./fg suite` (165 tests, dpr1, ~1.3 min) · `./fg gauntlet` (build + dpr1 + dpr2 + WebKit + 12 apps) ·
`./fg test <name>` · `./fg recapture <name>`. (The `fg` wrapper is local workspace tooling, not committed.)

**Why this now.** The owner asked, of the `@_adjustingContentsBounds` guard: *"how to get rid if you can of that nasty
Boolean guard … instead of an ordered top-to-bottom or bottom-to-top scan, you have notifications that go in both
directions and sometimes trigger each other, so you prevent infinite loops via those flags, which is bad."* The
diagnosis is correct. The owner's own **`Fizzygum/docs/archive/layout-system-architecture-assessment.md`** independently reaches
it (§2.3/§2.4/§2.6) and proposes the fix (§4.1). This plan is the **scoped, evidence-driven execution** of that §4.1,
narrowed by a disable-probe (§3) to the one place the flag is actually load-bearing.

---

## §1 — What the flag is and does (the real code)

`@_adjustingContentsBounds` lives on the three self-sizing container classes that have a `_positionAndResizeChildren`,
and is checked in the shared re-fit seam. Grep `_adjustingContentsBounds`:
- `SimpleVerticalStackPanelWdgt.coffee` — `_adjustingContentsBounds: false` (field); set true at the top of
  `_positionAndResizeChildren` (`if @_adjustingContentsBounds then return else @_adjustingContentsBounds = true`),
  cleared at the bottom.
- `WindowWdgt.coffee` — same shape in its `_positionAndResizeChildren`.
- `ScrollPanelWdgt.coffee` — same shape in its `_positionAndResizeChildren`, PLUS a nested-safe save/restore
  (`outer = @_adjustingContentsBounds; @_adjustingContentsBounds = true; … ; @_adjustingContentsBounds = outer`) around
  another method.
- `Widget.coffee` — `_reFitContainer` checks it: **`return if container._adjustingContentsBounds`** (grep
  `_reFitContainer:`). This is the cross-method suppression that the probe (§3) disabled.

It has TWO jobs, both facets of the same thing — *"this container is mid-pass; don't re-trigger it"*:
1. **Re-entrancy guard** — the `if … then return` at the top of each `_positionAndResizeChildren` (don't synchronously
   re-enter the pass).
2. **Cross-method suppression** — `_reFitContainer` skips enqueuing a container that is mid-pass (the part the probe
   disabled; the part that prevents the non-convergence).

---

## §2 — The mechanism (why the notification fires at all): mutate-then-read-back

This is the root cause, from the architecture assessment **§2.4** (read it):

Every geometry accessor (`width()`, `height()`, …) reads the **applied** `@bounds`. There is no pure "what size would
this be" query. So a container that sizes itself to its content cannot *measure* the content — it **mutates the child
and reads the result back**. The vertical stack does exactly this (`SimpleVerticalStackPanelWdgt._positionAndResizeChildren`):
```coffee
widget.rawSetWidthSizeHeightAccordingly recommendedElementWidth   # mutate child (synchronously _reLayout's it)
stackHeight += widget.height()                                    # read the applied result back
```
`rawSetWidthSizeHeightAccordingly` (grep it in `Widget.coffee`) does `@rawSetWidth newWidth` then (for a deferred-layout
child) `@_reLayout()` — and `rawSetWidth`/`rawSetExtent` fire the **bottom-up re-fit seam**
`_reFitContainerAfterRawGeometryChange → _reFitContainer(@parent)` (grep both in `Widget.coffee`). The seam's own
comment says it: *"raw setters run during layout passes."* So:

> the top-down pass mutates a child → the child's raw setter fires a bottom-up notification targeting **the very
> container running the pass** → `@_adjustingContentsBounds` swallows it. Without the swallow, the container re-enqueues
> itself, the until-loop re-runs its pass, it resizes the child again, which re-enqueues it again → **iterate forever**.

The settle engine is "invalidate **up**, re-layout **down**, iterate to a fixed point" (assessment §2.3). The flag +
the `recalcIterationsCap = 100000` freeze-backstop + the mid-pass `FLOWRULE_VIOLATION` throw are the three termination
crutches (§2.6). **The flag is a symptom of the read-back, not an independent wart.**

**The asymmetry that makes this fixable (assessment §2.5 — the crux):** the framework already has TWO sizing models.
**Horizontal stacks** use a clean **measure → arrange**: a pure bottom-up `getRecursiveMinDim/DesiredDim/MaxDim`
(grep in `Widget.coffee`) with NO mutate-read-back and NO flag. **Vertical / window / scroll / wrapping-text** use the
imperative read-back fixpoint that needs the flag. *"The framework already contains a clean measure engine — it just
isn't used on the side that hurts."* This plan extends the measure idea to the side that hurts — specifically **text
wrapping**, which §3 proves is where the genuine cycle lives.

---

## §3 — THE DECISIVE PROBE (already run 2026-06-28 — this is the evidence that scoped the plan)

A disable-probe was run to settle the central question: **is the flag correctness (prevents non-convergence) or just
optimization (avoids redundant passes)?** Method: comment out the single cross-method suppression
`return if container._adjustingContentsBounds` in `Widget._reFitContainer`, rebuild, run the full dpr1 suite. The
`recalcIterationsCap` backstop makes this SAFE — non-convergence bails loudly as `RECALC_NONCONVERGENCE` instead of
freezing.

**Result — the flag is CORRECTNESS-critical, and the breakage is LOCALIZED:**
- **`RECALC_NONCONVERGENCE` fired** (100000-iteration freeze-backstop) in **`macroWrappingTextFieldResizesOK`** and
  **`macroWrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved`** — both naming the same culprit widget:
  **`SimplePlainTextScrollPanelWdgt spec=100000`**.
- **2 further pixel-mismatch failures** in the same family (a *different fixed point* reached, not non-convergence):
  **`macroSimplePlainTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent`** and
  **`macroWrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo`**.
- **161 of 165 tests were completely UNAFFECTED.** Only the 4 wrapping-text-scroll-panel tests above broke.

**Interpretation:** the genuine non-convergence cycle is **text wrapping in a scroll panel** — width ⇄ height coupling
mediated by committing the wrap and reading the height back. The plain min/desired/max containers (horizontal stacks,
non-wrapping content, windows without auto-height wrapping content) **do not need the flag to terminate** — they didn't
diverge without it. So the flag is load-bearing in ONE place, and the 4 tests above are the **tripwire set** for the fix.

*(The probe was reverted; the repo is unchanged. To reproduce: comment out that one line, `./fg build`, then
`cd Fizzygum-tests && node scripts/run-all-headless.js --shards=4 --dpr=1` and grep the output for
`RECALC_NONCONVERGENCE`.)*

---

## §4 — The fix: a pure `measureWrappedHeight(width)` for text (assessment §4.1, scoped to wrapping text)

**Keystone discovery — the measure kernel almost already exists.** `TextWdgt.breakTextIntoLines(text, fontSize,
justCheckIfItFitsInThisExtent)` (grep it) ALREADY computes the wrapped layout for a width and **returns the tuple**
`[wrappedLines, wrappedLineSlots, width, height]`. `reflowText` / `_reLayoutSelf` call it and ASSIGN the tuple to
instance fields + commit the box geometry — the COMMIT is in the callers, not in `breakTextIntoLines`. So a pure measure
is within reach. **The one coupling to break:** when `@softWrap`, `breakTextIntoLines` reads the width from `@width()`
(the applied `@bounds`) rather than taking it as a parameter (grep `widgetWidth = @width()` inside it). That read is the
read-back. (It also memoizes into `world.cacheForTextBreakingIntoLinesTopLevel`, keyed by text+font+width+fitFlag — a
benign cache, not geometry; safe to populate from a measure.)

**The change, in three layers:**
1. **Parameterize the wrap by an explicit width.** Add `measureWrappedHeight(availWidth) -> heightPx` (and/or a
   `{w,h}` extent) on `TextWdgt` (and `SimplePlainTextWdgt`) that calls the wrap math with `availWidth` passed in
   explicitly — NOT reading `@width()` — and **writes no instance state and no `@bounds`** (returns the height; the
   memo cache is fine). The cleanest path is to thread an optional `widthOverride` through `breakTextIntoLines` so
   `widgetWidth = widthOverride ? @width()` and have `measureWrappedHeight` pass it; the existing committing callers
   keep reading `@width()`. **Verify (the byte-exact tripwire): the measured height at width W must EQUAL the height the
   current commit path produces after being sized to W** — same wrap, same rounding (`Math.ceil … measureText`).
2. **Have the wrapping container consume the MEASURE instead of mutate-and-read-back.** In the container's
   `_positionAndResizeChildren` (the vertical-stack path for FIT_BOX_TO_TEXT children, and the
   `SimplePlainTextScrollPanelWdgt` path), replace `rawSetWidthSizeHeightAccordingly(W)` + `widget.height()` read-back
   with: `h = widget.measureWrappedHeight(W)`; use `h` to lay out / size the container; set the child's geometry ONCE,
   afterwards, with the final width AND the measured height (a single commit, no read-back loop). The container's own
   size is now a **pure function of measured children**, so the synchronous apply-then-see-it is gone.
3. **Remove `@_adjustingContentsBounds`.** Once the wrapping container no longer mutates the child mid-measure, the
   bottom-up seam is no longer fired *at* the container during its own pass, so the cross-method suppression has nothing
   to suppress. Delete the field, the `if … then return` re-entrancy guards, the `_reFitContainer` check, and the
   ScrollPanel save/restore. **Confirm with the §3 probe in reverse** (the 4 tripwire tests must now converge + match
   WITHOUT the flag).

**Honest caveats (carry these):**
- **Aspect-locked nested content is a TRUE cycle** (square clock in a window-in-window: width depends on height depends
  on width). Measure does NOT remove it — it is irreducible in any single-pass system. It is ALREADY cycle-broken by
  giving aspect content `elasticity 0` (assessment §2.5 / OVERVIEW §5). Leave that fix in place; do not try to measure
  through it.
- **`breakTextIntoLines` reads `@width()` only when `@softWrap`** — the non-wrap path uses `Number.MAX_VALUE` (natural
  width). Make sure the measure handles both modes (a non-soft-wrap text measures at its natural width, unaffected by
  `availWidth`).
- **The memo cache key includes width** — measuring at candidate widths populates it; that is fine (it is keyed, so the
  committing path hits the same entry). Just confirm no cache-key collision between "measure" and "commit" calls.
- **Staged, not big-bang** — §6.

---

## §5 — Decisive first steps (before writing the container change)

1. **Confirm `breakTextIntoLines` is pure** (no `@bounds` write, no seam fire, no instance-field write other than the
   memo cache). Grep its body for `@bounds`, `rawSet`, `silentRaw`, `_reFitContainer`, `_invalidateLayout`, `@wrapped`.
   If it writes instance state, the measure must call a refactored pure core. (Today the writes appear to live in
   `reflowText` / `_reLayoutSelf`, the callers — verify.)
2. **Build the measure and prove byte-exactness in isolation FIRST.** Add `measureWrappedHeight(W)`, then in a throwaway
   probe assert, for the 4 §3 tripwire tests, that `measureWrappedHeight(W)` equals the height the commit path yields
   when sized to `W` (instrument both, compare, route the trace via
   `SystemTestsControlPanelUpdater?.addMessageToSystemTestsConsole "…"` — Puppeteer drops early-frame `console.log`
   under flood; the DOM div is read synchronously at test end). If they ever differ, STOP — the measure is not faithful
   and the whole plan rests on it.
3. **Map every read-back site** the container change must replace: grep `rawSetWidthSizeHeightAccordingly` and
   `.height()` reads inside the three `_positionAndResizeChildren`, and inside `SimplePlainTextScrollPanelWdgt`'s sizing.

---

## §6 — Staged execution (each stage is independently soak-verified; STOP if a stage can't be made byte-exact)

- **Stage A — measure primitive (no behaviour change).** Add `measureWrappedHeight` (+ parameterized
  `breakTextIntoLines`). The committing callers still read `@width()`. Build + full suite must stay **165/165
  byte-identical** (nothing consumes the measure yet). Prove §5.2 byte-exactness.
- **Stage B — consume the measure in the wrapping container.** Replace mutate-and-read-back with measure-then-single-
  commit, ONE container at a time, starting with `SimplePlainTextScrollPanelWdgt` (the §3 culprit). After each: build +
  gauntlet + **dpr2 torture** + the 4 tripwire tests. Expect byte-identical; if a deliberate pixel change appears, it
  needs owner approval before recapture.
- **Stage C — remove the flag.** Delete `@_adjustingContentsBounds` (all sites). Re-run the §3 probe logic as a positive
  test: the 4 tripwire tests + full suite must converge (no `RECALC_NONCONVERGENCE`) and match. If they don't, a
  read-back path was missed — go back to Stage B, do not paper over it by reinstating the flag silently.
- **Stage D (optional, assessment §4.2) — make convergence structural.** Once read-back is gone, the dependency graph
  on the wrap axis is a DAG; consider a `check-layering.js` rule that forbids a width↔height coupling on the same widget
  (turns the empirical convergence into a build-enforced one; `recalcIterationsCap` downgrades to a never-fire assert).
  Defer unless the owner wants it.

---

## §7 — Verification protocol (MANDATORY — convergence-critical)

Run the FULL set for any stage that consumes the measure or removes the flag. `fg` runs from any cwd.
1. `./fg build` — 0 violations, 0 warnings.
2. `./fg suite` — dpr1 **165/165**. On a pixel failure, dump + LOOK (don't recapture blindly):
   `cd …/Fizzygum-tests && node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1 --dump-failures=.scratch/x`,
   then Read the dumped `.png` vs the committed reference.
3. `./fg gauntlet` — dpr1 / dpr2 / WebKit **165/165** + apps 12/12.
4. **dpr2 torture — THE GOLD GATE, and the decisive one for THIS change:** `cd …/Fizzygum-tests &&
   node scripts/torture-headless.js --dprs=2 --speeds=fastest --shards=4 --minutes=10 --out=.scratch/torture-measure`
   → REPORT.md "No nondeterminism observed", failures dir empty, **and grep the run for `RECALC_NONCONVERGENCE`
   (must be ABSENT)** — this is the single most important signal: the flag you removed existed to prevent exactly this.
   GOTCHA: `pkill -9 -f "Chrome for Testing"` before torture; rebuild first (stale-build canary).
5. **Targeted tripwire run** (fast inner loop while iterating Stage B/C): run the 4 §3 tests explicitly —
   `for t in macroWrappingTextFieldResizesOK macroWrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved
   macroSimplePlainTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent
   macroWrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo; do
   node scripts/run-macro-test-headless.js SystemTest_$t --dpr=1; done` — and grep each for `RECALC_NONCONVERGENCE`.
6. **End-of-cycle capstone gate** (`bash scripts/end-of-cycle-audit/run-capstone-gate.sh ; echo "EXIT $status"`) and
   **paint-read-only gate** (`bash scripts/paint-readonly-audit/run-paint-readonly-gate.sh ; echo "EXIT $status"`) stay
   0. **DO NOT pipe a gate whose exit code you need into `tail`/`grep`** — the pipe masks the script's real exit code
   (learned the hard way). Dump to a file, echo `$status`, then read the file.
7. **20-minute determinism soak** before declaring done (the campaign standard for a convergence change): the torture
   at a longer `--minutes`, or repeated gauntlets.

**Determinism contract:** render/layout/input must be a pure function of the EVENT STREAM + final geometry — never
wall-clock / frame-count / intermediate-pass. Full contract + convergence bug-class case law:
`Fizzygum-tests/DETERMINISM.md`. **Recapture:** a byte-exact change needs none; a deliberate pixel change needs owner
approval first. A benign inspector member-list shift is the one pre-authorized recapture class (unlikely here — this
adds a measure method on TextWdgt, which an inspected text widget WOULD show, so a recapture of a text-inspector test is
possible; dump + look).

---

## §8 — Owner principles + workflow (honour these)

- **Measure, don't mutate-and-read-back.** The whole point is a side-effect-free measure; if a "measure" touches
  `@bounds` or fires the seam it has failed. Keep the applied accessors untouched (this is explicitly NOT the falsified
  "Path A — pending-aware accessors"; see assessment §4.1 + OVERVIEW §6).
- **Staged + soak each stage.** This is convergence-critical core; never big-bang it. STOP and leave the flag if the
  measure can't be made byte-exact (the status quo is sound).
- **Don't reinstate the flag to mask a missed read-back.** If Stage C diverges, a read-back path remains — find it.
- **Clean/elegant code is the standing priority** over avoiding a benign inspector recapture (just recapture; never
  contort code to dodge it).
- **Review-driven; run straight through then present ONE end-of-arc review.** ASK before each commit AND push — present
  the diff + proposed message, wait for explicit approval. Use `git commit -F <file>` — NEVER backticks / `$()` in
  `git commit -m` (the Bash tool runs bash semantics and command-substitutes them, corrupting the message). Verify with
  `git log -1 --format=%B`. End every commit message with:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Push each repo from its OWN dir.
- **Shell gotchas:** the Bash tool runs FISH; cwd may reset (use `cd /abs/… && …`; `$status` not `$?`). A PreToolUse
  guard BLOCKS a command that `cd`s into a non-`Fizzygum-tests` dir then runs a `Fizzygum-tests/scripts` node script —
  run those FROM `Fizzygum-tests` or via `fg`. Kill orphan `Chrome for Testing` before any suite/torture/audit.
- **Do NOT hand-edit `Fizzygum-builds/`** — rebuild. Scope every search (`Fizzygum-builds/latest` is ~1.3 GB).

---

## §9 — Anchors & references (grep the symbol; numbers drift)

- **The flag (what you're retiring):** `SimpleVerticalStackPanelWdgt.coffee` / `WindowWdgt.coffee` /
  `ScrollPanelWdgt.coffee` — `_adjustingContentsBounds` + their `_positionAndResizeChildren`. `Widget.coffee` —
  `_reFitContainer` (the `return if container._adjustingContentsBounds` check), `_reFitContainerAfterRawGeometryChange`
  (the bottom-up seam), `rawSetWidthSizeHeightAccordingly` (the mutate-then-`_reLayout` read-back primitive),
  `_markForRelayoutNoClimb` (the bare enqueue the seam uses in-pass), `_recalculateLayoutsBody` (the until-loop +
  `recalcIterationsCap` → `RECALC_NONCONVERGENCE`).
- **The text-wrap measure kernel (what you're building on):** `TextWdgt.coffee` — `breakTextIntoLines` (computes +
  RETURNS the wrapped tuple; reads `@width()` when `@softWrap` — the coupling to parameterize), `reflowText`,
  `_reLayoutSelf` (the COMMIT — assigns the tuple + sets box geometry), `softWrap`, `FittingSpecText.FIT_BOX_TO_TEXT`.
  `SimplePlainTextWdgt.coffee` — the FIT_BOX_TO_TEXT wrapping text widget (`setSoftWrap`/`softWrapOn`/`softWrapOff`).
  `SimplePlainTextScrollPanelWdgt.coffee` — **the §3 culprit**; the wrapping-text scroll panel whose sizing drives the
  cycle. `world.cacheForTextBreakingIntoLinesTopLevel` — the wrap memo cache.
- **The clean model to generalize from:** `Widget.coffee` — `getRecursiveMinDim` / `getRecursiveDesiredDim` /
  `getRecursiveMaxDim` (the horizontal-stack pure measure; assessment §2.5). `VerticalStackLayoutSpec.coffee` —
  `getWidthInStack` (the proportional `width = wEl + elasticity·(availW·wEl/wStk − wEl)` that creates the cyclic
  coupling).
- **The probe (the evidence):** §3 above. Tripwire tests: `macroWrappingTextFieldResizesOK`,
  `macroWrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved`,
  `macroSimplePlainTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent`,
  `macroWrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo`.
- **The authoritative architecture analysis (READ FIRST):** `Fizzygum/docs/archive/layout-system-architecture-assessment.md` —
  §2.3 (invalidate-up / re-layout-down fixpoint), **§2.4 (the read-back root constraint)**, **§2.5 (two sizing
  philosophies — the measure engine the codebase already trusts)**, §2.6 (convergence is empirical, rests on this flag),
  **§4.1 (add a pure measure protocol — this plan IS its scoped execution)**, §4.2 (make convergence structural). Its
  "Do not revisit (already falsified)" list — Path A (pending-aware accessors), reformulating the proportion fraction,
  routing ScrollPanel.add through the batch tier — must NOT be re-attempted.
- **The deferred-layout context:** `Fizzygum/docs/archive/deferred-layout-OVERVIEW.md` (the render/layout separation, §5/§6/§11).
  `Fizzygum-tests/DETERMINISM.md` (byte-exact contract + convergence bug-class case law + diagnosis playbook).
  Memory `fizzygum-deferred-layout-plan` (the campaign that built the in-pass-enqueue / off-pass-invalidate seam),
  `fizzygum-layering-naming-tiers` (the lint tiers [A]–[H] a §4.2 rule would join),
  `fizzygum-paint-readonly-caret-resync` (the in-pass-enqueue atom `_markForRelayoutNoClimb`, unified `282ea492`).
  `Fizzygum/CLAUDE.md` + `Fizzygum-tests/CLAUDE.md` (build/test specifics).

---

**One honest caveat (carry into the new session):** the §3 probe proves the flag is correctness-critical and localizes
the cycle to wrapping text, but it does NOT prove the measure can be made byte-exact — §5.2 is exactly the step that
turns that into ground truth, and it is the load-bearing risk (CSS, Flutter, WPF all special-case text measurement for
a reason). If `measureWrappedHeight(W)` cannot reproduce the committed wrap byte-for-byte with reasonable effort,
**leave the flag** — it is a sound, documented loop-breaker, and the cost of keeping it is one boolean and a known,
defensible empirical-convergence position (assessment §2.6), not a bug.

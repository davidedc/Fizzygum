> **ARCHIVED — COMPLETE (2026-07-17 restructure).** DONE per project ledger; doc itself carries no landed banner (still reads PLAN ONLY, written 2026-06-27)
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Plan — make `doOneCycle` PAINT read-only: move the caret's paint-time re-sync out of the paint pass

**Status: PLAN ONLY. Written 2026-06-27 to be executed COLD by an LLM/engineer with ZERO prior context.** Everything
needed — the architecture, the exact offending path with file:line, why it is load-bearing, why it is latent today, the
fix options with their risks, the investigation steps, the verification protocol, the references — is embedded inline or
one named-doc hop away. **Lines drift: grep the named symbol, never trust a line number.**

**One-line goal.** Today `WorldWdgt.doOneCycle` PAINTS *after* it flushes layout, but the **caret re-syncs its position
during the paint pass** (`CaretWdgt.justBeforeBeingPainted`), and that re-sync can **mutate + schedule layout while
painting**. The owner's architectural invariant is: *a cycle PROCESSES EVENTS (fixing layouts step-by-step, except
coalesced) → FIXES COALESCED layouts → PAINTS, with **no layout work at paint**.* Make paint genuinely read-only by
moving the caret re-sync's layout effect *before* the paint, without regressing the (load-bearing) scroll-follow.

---

## §0 — Orientation + why this now

**Fizzygum** = a CoffeeScript GUI on one HTML5 `<canvas>` (~470 `.coffee` classes in `Fizzygum/src/`; every class a
global, compiled in-browser, no imports; `nil` == `undefined`; one class per file = its class name). Umbrella
`/Users/davidedellacasa/code/Fizzygum-all/` (NOT a git repo) holds three sibling repos: **`Fizzygum/`** (source — edit
here), **`Fizzygum-tests/`** (165 macro SystemTests; drive the live world, compare SWCanvas SHA-256 screenshots
**byte-exactly**), **`Fizzygum-builds/`** (generated; never edit). Commands run via the path-correct `fg` wrapper from
the umbrella root: `./fg build` · `./fg suite` (165 tests, dpr1, ~1.3 min) · `./fg gauntlet` (build + dpr1 + dpr2 +
WebKit + 12 apps) · `./fg recapture <name>`.

**Why this now — the immediately-prior arc (just completed 2026-06-27).** The **end-of-cycle layout-flush drawdown
campaign** drove the per-frame "careless" layout-flush set to ZERO and shipped a self-tested hard-fail capstone gate
(`Fizzygum-tests/scripts/end-of-cycle-audit/run-capstone-gate.sh`; runs the suite with `WorldWdgt.auditUndeclaredEnd
OfCycle` on and exits non-zero on any off-settle layout push). Commits: **Fizzygum `778a7db5`** ("End-of-cycle drawdown:
drive the production-careless set to ZERO + ship the capstone") · **Fizzygum-tests `97df08fba`**. During that arc the
owner flagged the **paint-time caret re-sync** as the explicit NEXT item ("paint-time next"), to be tackled as its own
arc — this plan. Full prior history: `docs/archive/end-of-cycle-flush-inventory.md` (its **2026-06-27 ✅ CAMPAIGN COMPLETE
banner** is the summary) + memory `fizzygum-end-of-cycle-flush-drawdown`.

**The owner's exact words (verbatim, 2026-06-27), which define the target invariant:**
> "It shouldn't happen that way anyways. Doonecycle should process events, fixing layouts step by step except coalesced,
> then fix coalesced layouts, then paint."

So: **PAINT must be read-only.** No geometry mutation, no layout scheduling, during the paint pass.

---

## §1 — The architecture: the cycle, the flush, the paint

The engine runs **`WorldWdgt.doOneCycle`** (`src/WorldWdgt.coffee`, grep `doOneCycle:`) once per frame. Its order
(current, with the load-bearing line markers — grep the symbols, numbers drift; as of writing ~1312-1347):

1. `@playQueuedEvents()` — **PROCESS EVENTS.** Each input event runs its handlers; a public geometry/structural mutator
   self-settles here (the "fix layouts step-by-step" the owner means). The single self-settle tier is
   `Widget._settleLayoutsAfter` (sets `world._inLayoutMutation=true`, runs a non-settling core, flushes
   `recalculateLayouts()` once; THROWS `FLOWRULE_VIOLATION` if a public setter is reached on an attached widget
   mid-flush — forcing internal code onto `_<name>NoSettle` cores + raw setters).
2. step functions, hand mouse-enter/leave re-check.
3. `window.recalculatingLayouts = true`; **`@recalculateLayouts()`** (grep `recalculateLayouts:`); `window.recalculating
   Layouts = false`. — **THE END-OF-CYCLE FLUSH.** Drains `world.widgetsThatMaybeChangedLayout` to a fixed point. This is
   where deferred / declared-coalesced layout gets fixed (the owner's "fix coalesced layouts"). `world._recalculating
   Layouts` is true only INSIDE this.
4. `addPinoutingWidgets`, `addHighlightingWidgets`.
5. **`@updateBroken()`** (grep `updateBroken:`) — **THE PAINT.** The broken-rectangles (dirty-region) repaint loop: each
   dirty widget is painted via its pluggable `*Appearance` object (and/or its `BackBufferMixin` offscreen cache).
6. `WorldWdgt.frameCount++`.

So the structural order is already **events → flush → paint**. The DEFECT is that step 5 (paint) is NOT read-only: the
caret schedules/mutates layout from inside it (next section).

**The layout SEAM the caret trips** (`src/basic-widgets/Widget.coffee`, grep these):
- `_reFitContainerAfterRawGeometryChange` — on any RAW geometry change of a widget, re-fits the container(s) tracking it
  (`_reFitContainer @parent`, plus `@parent.parent` if directly inside a non-text-wrapping scroll panel). **Returns early
  for `@isLayoutInert?()`** (overlay chrome — carets/handles — excluded from container content-bounds).
- `_reFitContainer (container=@)` — the phase dispatcher: INSIDE a pass (`world._recalculatingLayouts`) it enqueues the
  container; OUTSIDE a pass it `_invalidateLayout()`s it (deferring to the NEXT cycle's flush). Skips
  `if container._adjustingContentsBounds`.

The paint pass runs OUTSIDE any flush (`_recalculatingLayouts` is false at step 5), so a seam trip during paint takes the
`_invalidateLayout()` branch → **schedules layout for the NEXT cycle**.

---

## §2 — The exact defect: the caret re-syncs (and mutates/schedules layout) DURING paint

**`CaretWdgt`** (`src/basic-widgets/CaretWdgt.coffee`) is the blinking text-editing caret. It is overlay chrome:
`isLayoutInert: -> true` (grep it) — so the caret's OWN raw moves do NOT trip the seam. It is repainted very frequently
(it blinks), so its paint hook fires most frames.

**The paint hook chain** (grep the symbols):
- `CaretWdgt.justBeforeBeingPainted: -> @adjustAccordingToTargetText()`.
- `CaretWdgt.adjustAccordingToTargetText: -> @updateDimension(); @_gotoSlotNoSettle @slot`.
- `justBeforeBeingPainted` is invoked **from the paint pass**, by the Appearance/back-buffer renderers (grep
  `justBeforeBeingPainted` across src):
  - `DesktopAppearance.coffee` (grep `justBeforeBeingPainted`)
  - `basic-widgets/RectangularAppearance.coffee` (two call sites)
  - `mixins/BackBufferMixin.coffee` (the offscreen-cache render path)

So during `updateBroken()` (paint), each repaint of the caret runs `adjustAccordingToTargetText → _gotoSlotNoSettle`.

**What `_gotoSlotNoSettle` does** (grep `_gotoSlotNoSettle:` in CaretWdgt) — the layout-relevant parts:
1. `@updateDimension()` — re-sizes the caret to the target font height via `@rawSetExtent` (the caret is isLayoutInert →
   no seam → inert). Not the problem.
2. The **`if @parent and @target.isScrollable` block**: when the caret's slot coordinate is outside the viewport, it
   **horizontally scrolls `@target` (the text widget) via `@target.fullRawMoveLeftSideTo/RightSideTo`**. `@target` is
   NOT isLayoutInert → this raw move **TRIPS the seam** (`_reFitContainerAfterRawGeometryChange → _reFitContainer
   @parent`) → off-pass during paint → **`_invalidateLayout()` → schedules layout for the next cycle.** *(This is the
   "layout scheduled during paint" the owner objects to.)*
3. `@show()` + `@fullRawMoveTo pos.floor()` — moves the caret itself (isLayoutInert → inert).
4. The **`if @_amIDirectlyInsideScrollPanelWdgt() and @target.isScrollable`** branch: `@parent.parent.scrollCaretIntoView
   @` (grep `scrollCaretIntoView:` in `ScrollPanelWdgt.coffee`). `scrollCaretIntoView` raw-moves `@contents` AND ends
   with **synchronous** `@_positionAndResizeChildren() + @_reLayoutScrollbars()` (a `# layout-apply-sanctioned` apply).
   *(This is a synchronous GEOMETRY MUTATION during paint — also not read-only, even though it doesn't defer.)*

**So the paint-time re-sync violates "paint read-only" in BOTH ways:** it can *schedule* layout (2: the `@target`-scroll
seam trip → next-cycle `_invalidateLayout`) and it *synchronously mutates* geometry (4: `scrollCaretIntoView`'s contents
move + `_positionAndResizeChildren`/`_reLayoutScrollbars`). The whole "scroll the caret/text into view" effect is the
violation, not just one line.

---

## §3 — Two hard facts that constrain the fix: it is LATENT but LOAD-BEARING

**(a) LATENT today — the capstone gate is clean.** Across all 165 SystemTests, the paint-time re-sync produces **zero**
careless records (the just-shipped capstone gate passes, 0/165). Reason: by the time the caret is painted, the EVENT that
moved it already positioned + scroll-followed it (caret navigation now self-settles per keystroke — the drawdown arc's
CaretWdgt convert: `goLeft/goRight` are self-settling public wrappers over `_go*NoSettle` cores; `goUp/goDown/goHome/
goEnd` self-settle via `gotoSlot`; the click/undo paths use the self-settling `gotoSlot`). So at paint, `_gotoSlotNoSettle
@slot` finds the caret already in view → its `if @parent and @target.isScrollable` test is false → no scroll → no seam
trip. **The defect is the CODE PATH, not a current failure.** It fires only when the target geometry changes between
event-time and paint-time WITHOUT a caret event re-syncing it (e.g. a container resize that reflows the text, a
programmatic `setText`, an animation). NB: should any such case ever start firing, **the capstone gate WILL catch it** (a
paint-time off-settle push surfaces at the next cycle's flush) — so this arc is "close a latent architectural hole +
guarantee paint is read-only", not "fix a red test".

**(b) LOAD-BEARING — you cannot simply delete the paint-time re-sync.** Two prior disable-probes prove the scroll-follow
that runs through this path is necessary:
- The end-of-cycle drawdown ENDGAME (memory `fizzygum-end-of-cycle-flush-drawdown`): *"a disable-probe no-oping
  `justBeforeBeingPainted` broke **5 caret/scroll tests** = LOAD-BEARING."*
- The DEFERRED-LAYOUT campaign family-5 probe (memory `fizzygum-deferred-layout-plan`, "Family 5 (soft-wrap) PROBED &
  rejected 2026-06-21"): deferring the caret-follow past the settle pass and relying on the existing paint-time `gotoSlot`
  left **7 tests red** (scroll-follow tripwires). ROOT CAUSE recorded there: *"gotoSlot's scrollCaretIntoView mutates
  contents geometry that must settle IN-CYCLE; deferring past the settle pass can't re-settle it, and a byte-exact alt
  needs the isLayoutInert caret to join the settle loop (FREEZE-CLASS RISK)."*

So the scroll-follow's *effect* must be preserved; only its *timing* (paint → earlier) may change. And the "obvious" move
— making the caret join the layout settle loop — is exactly what the deferred-layout campaign flagged as **freeze-class
risk** (the caret is `isLayoutInert`/excluded from content-bounds; pulling it into the `recalculateLayouts` until-loop
risks non-convergence). Treat that as the central hazard.

---

## §4 — The fix options (with trade-offs + risk; investigate before choosing)

The goal: the caret/text is correctly scroll-followed and positioned **by the end of step 3 (the flush)**, so the
paint-time re-sync becomes a verified no-op (or is removed), and paint is read-only. Candidate approaches, roughly
increasing in ambition/risk:

**Option A — eager re-sync at every target-geometry-change source (push the work to events/settle).** Find every path
that changes the target's geometry without repositioning the caret (container resize, programmatic `setText`, reflow,
animation) and make each scroll-follow the caret IN ITS OWN self-settling event/settle. Then the paint-time re-sync is
always a no-op and can be guarded/removed. *Pro:* keeps the caret out of the settle loop (no freeze risk). *Con:* must
enumerate ALL such sources (risk of missing one → a latent gap returns); the catch-all paint hook exists precisely
because that enumeration is hard.

**Option B — relocate the re-sync to just before the flush.** Call `adjustAccordingToTargetText` from `doOneCycle`
*before* `recalculateLayouts` (step 3), so its scroll-follow's seam trip enqueues INTO the flush (in-pass branch) and
settles in-cycle; paint then finds everything settled. *Risk:* the re-sync needs the target's FINAL geometry; pre-flush
the target may not be settled yet, so the caret could follow a stale position and need a second pass. Investigate
ordering carefully; may need to run it INSIDE the flush loop (→ Option C).

**Option C — the caret joins the settle pass (the family-5 refactor).** Make the caret a participant in
`recalculateLayouts` so that when its target/container re-fits, the caret re-positions + scroll-follows as part of the
same convergent flush. *This is the principled end state* and what the deferred-layout campaign identified — but it
carries the **freeze-class risk** (an isLayoutInert widget entering the until-loop must be proven convergent). High
ambition; do only with a strong convergence argument + heavy torture.

**Option D — make the paint-time re-sync layout-FREE (read-only-ize it in place).** Split `adjustAccordingToTargetText`
so the paint-time call only updates the caret's OWN inert visual (position/size to wherever the text currently is) and
NEVER scrolls `@target` / calls `scrollCaretIntoView`. The scroll-follow then must be guaranteed by A/B/C upstream.
*Pro:* directly enforces paint-read-only at the hook. *Con:* only correct if the upstream guarantee (A/B/C) holds; alone
it reintroduces the 5/7-test breakage.

**Likely shape: D as the enforcement (paint hook becomes inert) + A and/or B as the guarantee (the scroll-follow happens
earlier).** But this is an INVESTIGATION — do §6 before committing to a shape.

---

## §5 — The render/layout boundary (the broader principle this serves)

This is one instance of a general invariant the codebase is moving toward: **render (paint) must be a pure read of
settled geometry; it must not schedule or mutate layout.** The deferred-layout OVERVIEW (`docs/archive/deferred-layout-OVERVIEW.md`)
and `docs/archive/layout-system-architecture-assessment.md` (§2.7, the flush/coalescing model) are the canonical homes. The
end-of-cycle inventory (`docs/archive/end-of-cycle-flush-inventory.md` §11) already flagged a *sibling* curiosity — a freefloating
widget invalidated from inside `fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow` — as "paint triggering
layout scheduling, crossing the render/layout boundary… the spot to look if the separation is ever tightened." **This arc
IS that tightening, for the caret.** If you fix the caret cleanly, re-check that §11 paint-time freefloating re-fit too
(it may be the same shape and fixable the same way, or a second mini-target).

---

## §6 — The method: investigate, then fix, then PROVE paint is read-only

**(1) Reproduce the paint-time scroll-follow firing.** It is latent in the suite, so first construct a scenario where it
DOES fire (caret out of view at paint without an event re-syncing it). Candidates: resize a scroll-panel/window
containing an editing caret; programmatic `setText` on an editing target; an animated/auto-scrolling container. Write a
throwaway probe prelude (`PRELUDE_JS`, see below) that logs when `_gotoSlotNoSettle`'s `@target.fullRawMove*` actually
runs (i.e. the caret needed scrolling) AND whether `world._recalculatingLayouts` is false (== during paint). Confirm the
seam trip + the off-pass `_invalidateLayout`. This pins the REAL trigger sources (drives Option A's enumeration).

**(2) Re-run the load-bearing disable-probes to re-confirm the constraint** (don't trust this doc — verify): no-op
`CaretWdgt.justBeforeBeingPainted` (or just its `_gotoSlotNoSettle` call), `./fg build`, `./fg suite`. Expect ~5 caret/
scroll tests RED (e.g. the scroll-follow tests). That set is your regression tripwire for any fix.

**(3) The stack-probe technique (from the drawdown arc — reuse it).** The committed `Fizzygum-tests/scripts/end-of-cycle-
audit/eoc-production-probe.js` (PRELUDE_JS) logs the UNFILTERED enqueue stack for every off-settle layout push using the
production gate. Run it on your repro scenario:
`cd /abs/Fizzygum-tests && env PRELUDE_JS=$PWD/scripts/end-of-cycle-audit/eoc-production-probe.js LOG_FILE=/tmp/x.log node
scripts/run-macro-test-headless.js SystemTest_<repro> --dpr=1`, then grep `EOCSTACK`. (The audit's own `shortSig` LIES —
it filters `eval` frames, and every in-browser-compiled method is an eval frame — so always read the unfiltered stack.)

**(4) The disable-probe technique (convert-vs-eliminate-vs-relocate decision).** No-op a candidate re-fit, rebuild, run
the suite: byte-identical ⇒ that re-fit was wasted (eliminate/relocate is safe); tests red ⇒ load-bearing (must preserve
the effect, only move its timing). ~10 min, decisive.

**(5) Build the fix (A/B/C/D per §4), then ENFORCE paint-read-only.** After the re-sync's effect is moved before paint,
add a guard that PROVES paint schedules no layout: e.g. set a `world._painting` flag around `updateBroken()` and make
`Widget._invalidateLayout` (and/or the seam `_reFitContainer`) THROW/record if reached while `_painting` (mirrors the
existing `world._recalculatingLayouts` flag + the `FLOWRULE_VIOLATION` throw). Self-test it (plant a paint-time
invalidate → confirm it fires → revert). This makes "paint is read-only" a CHECKED invariant, not a convention — and is
the natural capstone for THIS arc (cf. the drawdown arc's `run-capstone-gate.sh`).

---

## §7 — Verification protocol (mandatory; determinism-sensitive)

Caret / scroll / paint are ALL determinism-sensitive (byte-exact, dpr2-under-load-sensitive). Do the FULL set for ANY
change. The `fg` wrapper runs from any cwd.
1. `./fg build` — 0 violations (lints [A]–[H] + dead-method + thin-wrap gates).
2. `./fg suite` — dpr1 **165/165**. On a pixel failure, dump + LOOK (don't recapture blindly): `cd /abs/Fizzygum-tests &&
   node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1 --dump-failures=.scratch/x`, then Read the `.png` vs
   the committed reference under `tests/SystemTest_<name>/automation-assets/**/SWCanvas/ceilPixRatio_1/`. A real render
   change ⇒ make it byte-identical (don't recapture); only a benign inspector member-list shift ⇒ `./fg recapture <name>`.
3. `./fg gauntlet` — dpr1/dpr2/WebKit **165/165** + **apps 12/12** (run the apps leg explicitly for any caret/scroll/
   paint change — `./fg apps`).
4. **dpr2 torture** (the gold gate for paint/settle-timing): `cd /abs/Fizzygum-tests && node scripts/torture-headless.js
   --dprs=2 --speeds=fastest --shards=4 --minutes=10 --out=.scratch/torture-paint` → REPORT.md clean (failures dir empty).
5. **Re-run the end-of-cycle CAPSTONE gate** (it must STAY 0): `cd /abs/Fizzygum-tests && bash scripts/end-of-cycle-audit/
   run-capstone-gate.sh` → "✓ CAPSTONE GATE PASSED". (Your fix must not introduce a new careless push, and ideally your
   new paint-read-only guard from §6(5) passes too.)

**Determinism contract:** render/layout/input must be a pure function of the EVENT STREAM + final geometry — never of
wall-clock / frame-count / intermediate-pass. A green dpr1 suite is NOT sufficient for a paint/settle-timing change;
finish with gauntlet + torture. Full case-law: `Fizzygum-tests/DETERMINISM.md`.

---

## §8 — Owner principles + workflow (honour these)

- **Coalescing is ONLY for genuine high-frequency streams (~50/frame — mouse drag/scroll).** Caret typing is NOT such a
  stream → it self-settles per keystroke, it does NOT coalesce. (A prior attempt to declare-coalesce the caret was wrong
  and corrected.) Do not reach for `setMaxDimCoalesced`/`_coalescedDeclare` for the caret.
- **No new settle tier; no rough flag-toggling.** Prefer fixes at the ROOT and self-guards that mirror existing patterns
  (e.g. the `_adjustingContentsBounds` save/restore self-guard; the `world._recalculatingLayouts` flag). The owner
  rejected a 3rd `_settleLayoutsAfter` variant and `try/finally` flag toggles in the prior arc.
- **Clean/elegant code is the standing priority** over avoiding a benign inspector member-list recapture (just recapture
  — adding/renaming a Widget-family method shifts the inspector's alphabetical list; that is benign).
- **Review-driven.** Present a clear plan + the disable-probe/repro evidence before a big refactor (Option C especially).
  **ASK before each commit AND push** — present the diff + proposed message, wait for explicit approval. `git commit -F
  <file>` (never backticks/`$()` in `-m`). End every commit message with:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **Shell gotchas:** the Bash tool runs FISH; cwd may reset between calls (use `cd /abs/... && …` single-line). A
  multi-line command whose first line is `cd …Fizzygum-tests` running a node script is BLOCKED by a guard — run such
  SINGLE-LINE or via `fg`. Kill orphan `Chrome for Testing` before a suite/audit (`pkill -9 -f "Chrome for Testing"`).
  Never chain `./fg build && ./fg suite` under a tight (≤2 min) tool timeout (looks like a hang). `git push` each repo
  from its OWN dir.

---

## §9 — Anchors & references (grep the symbol; numbers drift)

- **The offending path:** `src/basic-widgets/CaretWdgt.coffee` — `justBeforeBeingPainted`, `adjustAccordingToTargetText`,
  `updateDimension`, `_gotoSlotNoSettle` (the `if @parent and @target.isScrollable` scroll block + the
  `@_amIDirectlyInsideScrollPanelWdgt` → `scrollCaretIntoView` branch), `gotoSlot` (the self-settling public wrapper +
  its doc comment, which already names this paint-time path as the known smell), `isLayoutInert`.
- **The paint callers:** `DesktopAppearance.coffee`, `basic-widgets/RectangularAppearance.coffee`,
  `mixins/BackBufferMixin.coffee` (grep `justBeforeBeingPainted`).
- **The cycle + paint:** `src/WorldWdgt.coffee` — `doOneCycle` (events → `recalculateLayouts` flush → `updateBroken`
  paint), `recalculateLayouts`, `updateBroken`, the `window.recalculatingLayouts` flag.
- **The seam + scroll-follow:** `src/basic-widgets/Widget.coffee` — `_reFitContainerAfterRawGeometryChange` (the
  `isLayoutInert` early-return), `_reFitContainer` (the in-pass-enqueue vs off-pass-invalidate dispatch + the
  `_adjustingContentsBounds` skip). `src/basic-widgets/ScrollPanelWdgt.coffee` — `scrollCaretIntoView` (the synchronous
  `_positionAndResizeChildren` + `_reLayoutScrollbars`).
- **The just-shipped capstone (keep it at 0; reuse its tooling):** `Fizzygum-tests/scripts/end-of-cycle-audit/` —
  `run-capstone-gate.sh` (the gate), `eoc-capstone-prelude.js` (flips `auditUndeclaredEndOfCycle`), `eoc-production-probe.js`
  (per-test unfiltered-stack diagnostic). Prior arc commits: Fizzygum `778a7db5` / Fizzygum-tests `97df08fba`.
- **Companion docs:** `docs/archive/end-of-cycle-flush-inventory.md` (§11 = the sibling paint-time freefloating re-fit; the
  CAMPAIGN-COMPLETE banner). `docs/archive/layout-system-architecture-assessment.md` §2.7 (flush + coalescing model).
  `docs/archive/deferred-layout-OVERVIEW.md` (the render/layout separation + family-5). `Fizzygum-tests/DETERMINISM.md` (byte-exact
  contract + the paint/settle bug-class case-law).
- **Memory:** `fizzygum-end-of-cycle-flush-drawdown` (the just-completed arc + this as NEXT), `fizzygum-deferred-layout-plan`
  (the family-5 "caret joins the settle pass" probe + freeze-class risk), `fizzygum-layering-naming-tiers` (the [A]–[H]
  lint tiers + the `_NoSettle` convention).

> **ARCHIVED — PARKED (2026-07-17 restructure).** PARKED — plan authored 2026-06-27, never executed; premise pre-dates the occlusion/perf arcs, re-validate before reviving.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Plan — skip layout-invalidations for CLOSED-BASEMENT (dormant) widgets via a cheap cached flag

**Status: PLAN ONLY (proposal). Written 2026-06-27 to be executed COLD by an LLM/engineer with ZERO prior context.**
Everything needed — background, the exact problem, the model, the failed blanket attempt, the proven precedent, the
design, the dangerous failure mode, the safer alternative, a step-by-step, and the verification gates — is embedded
inline or one named-doc hop away. **Line numbers drift: grep the named symbol, never trust a line number.**

> ### ⚠ READ FIRST — this is OPTIONAL cleanliness/perf, NOT a correctness or capstone need.
> The end-of-cycle careless **capstone gate is already GREEN at zero** without this change (orphan pushes are excluded
> by design — see §2/§4). This plan only (a) drives the *broader prelude-level* basement diagnostic record to 0 too,
> and (b) saves a tiny amount of wasted dormant re-layout work. It also **re-opens the orphan-skip area that once broke
> 63 tests** (§4) and introduces a **stale-flag correctness hazard** (§5c). So weigh it against the **safer
> seam-by-seam alternative in §6** before building. Do not treat this as "must ship."

---

## §0 — One-line goal

A widget sitting in the **closed (off-world) basement** is dormant: never painted, and re-laid-out top-down when the
basement is re-opened. Its layout-invalidations are therefore wasted. **Skip them** — but do it with a **cheap cached
per-widget flag** checked in `Widget._invalidateLayout`, NOT a per-call ancestor-walk (`isOrphan()`/`isInBasement()`
are O(depth)), and NOT a blanket orphan-skip (that broke 63 tests — §4). The common case (a live, non-basement widget,
~all invalidates) must cost **one boolean read**.

---

## §1 — Cold context: the end-of-cycle-flush-drawdown campaign

**Fizzygum** = a CoffeeScript GUI on one HTML5 `<canvas>` (~470 `.coffee` classes in `Fizzygum/src/`; every class a
global, compiled in-browser, no imports; `nil` == `undefined`; one class per file = its class name). Umbrella
`/Users/davidedellacasa/code/Fizzygum-all/` (not a repo) holds three sibling repos: **`Fizzygum/`** (source — edit
here), **`Fizzygum-tests/`** (165 macro SystemTests; drive the live world, compare SWCanvas SHA-256 screenshots
**byte-exactly**), **`Fizzygum-builds/`** (generated; never edit).

**The layout model (the 5 lines you need).** A widget tree is re-laid-out by draining `world.widgetsThatMaybeChanged
Layout` once per frame in `WorldWdgt.doOneCycle` — the **end-of-cycle flush** (`recalculateLayouts` →
`_recalculateLayoutsBody`). A public geometry mutator **self-settles**: it wraps its core in the single tier
`Widget._settleLayoutsAfter` (sets `world._inLayoutMutation`, runs a non-settling core, flushes once). Internal/raw
mutators (`raw*`/`silent*`/`fullRaw*`) MUST NOT schedule/flush layout (the **FLOWRULE** — enforced by a runtime throw
in `_invalidateLayout` and the build lint `buildSystem/check-layering.js`). A layout push that reaches the end-of-cycle
flush *without* having self-settled is a **"careless"** survivor — the campaign drove these to zero and added a
**hard-fail capstone gate**. Full model: `docs/archive/layout-system-architecture-assessment.md` §2.7.

**The careless AUDIT + capstone (the binding definition).** `WorldWdgt.auditUndeclaredEndOfCycle` (DEBUG flag,
default OFF) records every "careless" push; the capstone gate runs the suite with it on and **fails if any appears**.
The gate is `Fizzygum-tests/scripts/end-of-cycle-audit/run-capstone-gate.sh` (+ `eoc-capstone-prelude.js`,
`eoc-production-probe.js`). It is **currently at zero**. Companion docs: `docs/archive/end-of-cycle-flush-inventory.md` (the
audit history), `docs/archive/end-of-cycle-flush-drawdown-plan.md` (playbooks/patterns), `docs/end-of-cycle-flush-final-records
-plan.md` (the final-records arc).

---

## §2 — Orphans, the basement, and what "careless" excludes (the model for THIS plan)

**`isOrphan()`** (`src/basic-data-structures/TreeNode.coffee`, grep `isOrphan:`) walks a widget up to its **root** and
returns true iff that root is **neither `world` nor `world.hand`**:
```coffee
isOrphan: -> root = @root(); return false if root == world or root == world.hand; return true
```
So an orphan is off-world: under construction, momentarily detached, OR **in the basement**.

**The basement** (`src/BasementWdgt.coffee`) is a revivable off-world recycle-bin, the singleton `world.basementWdgt`.
It holds "lost" widgets in `world.basementWdgt.scrollPanel.contents`. It has **two states**:
- **CLOSED** — not attached to the world (`world.basementWdgt.isOrphan() == true`). Its whole subtree is off-world and
  **never painted**. This is the *dormant* state this plan targets.
- **OPEN** — `BasementOpenerWdgt.mouseClickLeft` wraps it in a `WindowWdgt` and `world.add`s it (grep
  `mouseClickLeft` in `src/BasementOpenerWdgt.coffee`: `windowedBasementWdgt = new WindowWdgt nil, nil, @target;
  world.add windowedBasementWdgt`). Now its root is `world` (`isOrphan() == false`) and it IS painted/live.

**The careless gate excludes orphans by design** (`Widget._invalidateLayout`, grep `auditUndeclaredEndOfCycle`):
```coffee
if @layoutIsValid
  world.widgetsThatMaybeChangedLayout.push @                       # the push (ALWAYS happens)
  if world.auditUndeclaredEndOfCycle and world._coalescedDeclarationDepth == 0 \
     and not world._inLayoutMutation and not @isOrphan()           # ← orphan EXCLUDED from the careless tally
    (world._undeclaredEndOfCyclePushes ?= []).push @constructor?.name
@layoutIsValid = false
```
Crucial distinction: **the audit's `!isOrphan()` is *classification* (don't COUNT this as a leak), not *suppression*
(it does NOT stop the push or the layout).** The basement push still happens, gets drained at the next flush (laid out
*dormantly*, off-world — `_reLayout` has no orphan early-out and ends in `markLayoutAsFixed`), and is superseded by the
**top-down re-layout when the basement is re-opened** (`world.add` self-settles the whole subtree). **This plan changes
that to actual suppression for the closed-basement subset only.**

---

## §3 — The exact residual this targets

One test keeps a single **prelude-level** basement record: **`macroStringWdgtInlineTypingRefitsUnderFittingModes`**
(`Fizzygum-tests/tests/SystemTest_macroStringWdgtInlineTypingRefitsUnderFittingModes/`). It is a closed pop-up
**re-homing its widget into the closed basement**:
```
  Widget.close → Widget._closeNoSettle → world.basementWdgt._addLostWidgetNoSettle(@)
               → basement.scrollPanel.contents._addInPseudoRandomPositionNoSettle(@)
               → adding to a container schedules a re-fit of basement.scrollPanel (root == BasementWdgt → ORPHAN)
               → push onto world.widgetsThatMaybeChangedLayout   ◄── the record
```
It reaches the basement scroll panel from **several seams** (so a single-seam fix doesn't fully zero it): the
`childRemoved` removal hook (already handled — §4), the raw-geometry re-fit seam
`Widget._reFitContainerAfterRawGeometryChange`, the basement show/hide filter (`BasementWdgt.hideUsedWidgets` /
`showAllWidgets` calling `w.hide()`/`w.show()`), and the `_addNoSettle` itself. **The production/capstone audit already
excludes ALL of these (orphan) → the gate is 0.** This plan additionally makes the *prelude* read 0 and stops the
wasted dormant re-fits — that's its entire payoff.

---

## §4 — Why NOT a blanket orphan-skip, and the precedent that IS safe

**The blanket attempt — FAILED, do NOT repeat.** Putting `return if @isOrphan()` at the top of the shared
`Widget._invalidateLayout` was tried and **REVERTED — it broke 63 tests across all engines.** Reason: orphan
invalidates are *generally load-bearing*. **Every widget is parent-less (hence an orphan) while it is being
constructed**, and its layout must still be computed; and the flush legitimately lays out **detached-but-live**
widgets (e.g. the momentarily-off-world float-dragged widget in `macroDetachedWidgetStaysFloatDraggable`). A blanket
skip silently drops all of that. **So generic-orphan ≠ skippable. Only the CLOSED-BASEMENT subset is dormant.**

**The proven-safe precedent — `PanelWdgt.childRemoved`** (grep `childRemoved:` in `src/basic-widgets/PanelWdgt.coffee`).
The 2026-06-26 fix already skips one basement re-fit using a **NARROW SEAM + generic orphan** shape:
```coffee
childRemoved: (child) ->
  return unless @parent?
  # ... re-fit @parent ONLY when this container is part of the LIVE layout; a removal inside a DETACHED subtree
  # (root neither world nor hand) re-fits nothing observable ... SAFE specifically at this REMOVAL seam (the only
  # detached case is the never-painted basement); a blanket orphan-skip in _invalidateLayout instead breaks
  # construction/detached-live layout ...
```
This plan is the **inverse trade**: a **BROAD seam (all of `_invalidateLayout`) + a NARROW widget (closed-basement
only, via a flag)**. Both narrow the danger; this one needs the flag to stay correct across re-parenting (§5c).

---

## §5 — THE DESIGN: a cached `_inBasement` flag, gated by `basement.isOrphan()`

### §5a — the invariant + the check

A widget is **dormant** iff `(it is inside the basement subtree) AND (the basement is closed/off-world)`. Decouple
the two halves so the per-widget part is O(1):

- **`@_inBasement`** — a per-widget boolean, default `false`, that **caches membership** ("`world.basementWdgt` is me
  or one of my ancestors"). Changes ONLY when the widget is re-parented into/out of the basement subtree (§5b). Does
  NOT change when the basement opens/closes (membership is stable across that).
- **`world.basementWdgt.isOrphan()`** — the **open/closed half**. Cheap: the basement is ~0–2 hops from a root
  (CLOSED: its own root, 0 hops; OPEN: basement → window → world, 2 hops). Evaluated only AFTER `@_inBasement` is true,
  so live non-basement widgets never reach it. (If even that is too much, maintain a `BasementWdgt._isOffWorld` boolean
  toggled at the open/close seams in §5b and read it instead — but measure first; the short-circuit likely makes it
  moot.)

**The check** goes in `Widget._invalidateLayout` (grep `_invalidateLayout:`), mirroring the existing
`return if triggeringChild?.isFreeFloating()` early-return that is already there — a dormant invalidate is a silent
no-op exactly like a freefloating one:
```coffee
_invalidateLayout: (triggeringChild = nil) ->
  return if triggeringChild?.isFreeFloating()                       # existing
  return if @_inBasement and world?.basementWdgt?.isOrphan()        # ← NEW: closed-basement dormant skip
  # ... existing FLOWRULE throw, push, audit hook, @layoutIsValid = false, climb ...
```
Place it **after** the freefloating return and **before** the `_recalculatingLayouts` FLOWRULE throw (a dormant
widget's invalidate must be a no-op even if reached mid-pass, same as freefloating). Returning here (before
`@layoutIsValid = false`) is correct: the dormant widget stays `layoutIsValid == true` and is re-laid-out top-down on
re-open anyway. **Common-case cost: one boolean read (`@_inBasement == false`).**

### §5b — maintaining `@_inBasement` (only THREE places)

Because **`_addNoSettle` and `removeFromTree` are the only re-parent primitives**, membership is maintained at just
those, plus a pin on the basement root:

1. **`BasementWdgt` pins it true.** Add `_inBasement: true` as a prototype default on `class BasementWdgt`
   (`src/BasementWdgt.coffee`) — the basement IS the root of its own subtree, regardless of where it is attached
   (it gets re-parented into a `WindowWdgt` when opened, but must STILL be "the basement"). So it must NOT inherit from
   a new parent. (Equivalently: special-case it in the inheritance below so it never gets cleared.)

2. **`_addNoSettle` inherits + propagates on CHANGE only.** In `Widget._addNoSettle` (grep `_addNoSettle:`), after the
   child's `@parent` is set to the new parent, set the child's membership from the new parent and propagate to its
   subtree **only when the value actually changes** (so same-context adds — ~all adds — are a single compare):
   ```coffee
   newInBasement = @_inBasement or @ == world?.basementWdgt     # children of the basement ARE in it
   aWdgt._setInBasementRecursively(newInBasement) if aWdgt._inBasement != newInBasement and not (aWdgt instanceof BasementWdgt)
   ```
   `_setInBasementRecursively(v)` sets `@_inBasement = v` and recurses over `@children` (a new helper on `Widget`/
   `TreeNode`). This makes ENTER (close re-home + `BasementOpenerWdgt._reactToDropOfNoSettle` drop-in, both route
   through `_addInPseudoRandomPositionNoSettle → _addNoSettle`) and LEAVE (a lost widget grabbed/restored out → a
   normal `_addNoSettle` to world/hand) both fall out of this one hook.

3. **`removeFromTree` clears it.** In `Widget.removeFromTree` (grep `removeFromTree:`) the widget is detached with no
   new parent — it becomes a *generic* orphan (construction/detach kind), NOT a basement member. Clear:
   `@_setInBasementRecursively(false) if @_inBasement and not (this is the basement itself)`. **This is the seam most
   easily forgotten — and forgetting it is the §5c hazard.** (Note: a re-parent that goes `removeFromTree` then
   `_addNoSettle` is covered by both; a direct `_addNoSettle` re-parent is covered by #2.)

### §5c — ⚠ THE DANGEROUS FAILURE MODE (this is why the flag is riskier than it looks)

A **stale `_inBasement == true` on a widget that is actually LIVE** is a **silent correctness bug**: its
`_invalidateLayout` early-returns, so **its layout never updates** (frozen geometry, stale render) — strictly worse
than today's harmless deferral. The `basement.isOrphan()` guard narrows the blast radius (a stale-true widget is only
wrongly skipped while the basement happens to be CLOSED), but does not remove it. Mitigations the implementer MUST
honour:
- **Maintain at the primitives (`_addNoSettle`/`removeFromTree`), never ad-hoc**, so every re-parent path is covered.
- **Never set/clear `_inBasement` from feature code** — only the three places in §5b.
- **Verify with the determinism gates (§8), especially the apps + torture** — a frozen live widget shows as a pixel
  diff. A green full gauntlet + a clean torture soak is the evidence that no live widget got wrongly frozen.
- If unsure, prefer §6.

---

## §6 — The SAFER alternative (compare before building the flag)

**Extend the `childRemoved` precedent to the other basement seams** — keep the proven **narrow-seam + generic-orphan**
shape, no flag, no new per-widget state, no hot-path read on the common path:
- Add `return if @isOrphan()` (or reuse the container's existing context) at the *specific* seams that still produce
  the basement record: the raw-geometry re-fit `Widget._reFitContainerAfterRawGeometryChange` (grep it) when the
  container is detached, and the show/hide filter (`BasementWdgt.hideUsedWidgets`/`showAllWidgets` →
  `w.hide()`/`w.show()`).
- **Pros:** each skip is a local, provably-safe seam exactly like `childRemoved`; no flag-staleness hazard; the
  `isOrphan()` walk is paid only at those rare seams, not on every invalidate. **Cons:** doesn't generalize — each new
  basement seam needs its own skip; and `_reFitContainerAfterRawGeometryChange` is a hot-ish seam, so guard it
  precisely (only when detached).

**Recommendation:** the flag (§5) is the more *general* mechanism but carries the staleness hazard and re-opens the
orphan area; §6 is *incremental and safe* but seam-local. Given the payoff is only prelude-tidiness + tiny perf (the
capstone is already 0), **§6 is the lower-risk way to get the same prelude-zero**, and the flag is justified only if a
broader "dormant subtree" notion is wanted for other reasons. Decide explicitly and record the choice.

---

## §7 — Step-by-step (if building the flag, §5)

1. Add `_inBasement: false` prototype default on `Widget` (grep a nearby boolean default like `layoutIsValid` for the
   spot), and `_inBasement: true` on `BasementWdgt`.
2. Add `_setInBasementRecursively(v)` to `Widget` (set `@_inBasement = v`; recurse `@children`).
3. Wire the two maintenance hooks in `_addNoSettle` and `removeFromTree` (§5b), each guarded by the
   `!= newValue` short-circuit and the `not BasementWdgt` exception.
4. Add the early-return in `_invalidateLayout` (§5a).
5. Sanity self-check while iterating: with the capstone prelude on, the
   `macroStringWdgtInlineTypingRefitsUnderFittingModes` record should drop to 0; nothing else should change.
6. **Watch the build lints:** `check-layering.js` (the FLOWRULE/[A]–[H] gates) and the thin-wrap/dead-method gates run
   in `./fg build`; a new helper or default must keep them at "0 violations".

**Commands** (the `fg` wrapper is path-correct from ANY cwd; the umbrella is `/Users/davidedellacasa/code/Fizzygum-all`):
- `cd /Users/davidedellacasa/code/Fizzygum-all && ./fg build` — build + all lint gates.
- `./fg suite` — 165 tests dpr1 (~1.3 min, the byte-identity gate).
- `./fg gauntlet` — build + dpr1 + dpr2 + WebKit + **apps** (12 desktop-app boot-smoke). The full determinism gate.
- `./fg recapture <name>` — only for a *benign* inspector member-list shift.
- **Capstone gate:** `cd /abs/Fizzygum-tests && bash scripts/end-of-cycle-audit/run-capstone-gate.sh` (~1.5 min;
  exit 0 = zero careless, exit 1 = regression). **This must stay PASS.**
- **Stack diagnosis** when a record appears: `cd /abs/Fizzygum-tests && PRELUDE_JS=$PWD/scripts/end-of-cycle-audit/
  eoc-production-probe.js LOG_FILE=/tmp/x.log node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1`, then
  grep `EOCSTACK`.

---

## §8 — Verification protocol (MANDATORY — this is layout/determinism-sensitive)

A skipped invalidate is a settle-timing change, so do the FULL set; a *frozen live widget* (the §5c hazard) surfaces as
a pixel diff at dpr2/apps:
1. `./fg build` — **0 violations**.
2. `./fg suite` — dpr1 **165/165** (byte-identical). Don't recapture blindly: dump (`run-macro-test-headless.js
   --dump-failures=.scratch/x`) and Read the `.png` vs the committed reference; a real render change ⇒ fix to
   byte-identical, only a benign inspector member-list shift ⇒ recapture.
3. `./fg gauntlet` — dpr1/dpr2/WebKit **165/165** + **apps 12/12**. The apps lock/recycle widgets heavily, so they are
   the real test that no live widget got wrongly frozen.
4. **dpr2 torture** (the determinism soak): `cd /abs/Fizzygum-tests && node scripts/torture-headless.js --dprs=2
   --speeds=fastest --shards=4 --minutes=10 --out=.scratch/torture-basement` → REPORT.md clean (empty failures dir).
5. **Capstone gate** (`run-capstone-gate.sh`): must read `✓ … zero careless … 165 tests` (exit 0). Optionally confirm
   the targeted prelude record is gone via the broader audit loop `scripts/end-of-cycle-audit/run-audit-loop.sh`.

**Determinism contract:** render/layout must be a pure function of the EVENT STREAM + final geometry, never of
frame-count/intermediate-pass. A green dpr1 suite is NOT sufficient; finish with gauntlet + torture.
(`Fizzygum-tests/DETERMINISM.md`.)

---

## §9 — Symbol/file map (grep the symbol; line numbers drift)

- `src/basic-widgets/Widget.coffee`: `_invalidateLayout` (the early-returns + push + audit hook + climb) ·
  `_addNoSettle` · `removeFromTree` · `_closeNoSettle` (the basement re-home: `world.basementWdgt._addLostWidgetNoSettle
  @`) · `_settleLayoutsAfter` (orphan early-return precedent) · `_reFitContainerAfterRawGeometryChange` (a §3 seam).
- `src/basic-widgets/PanelWdgt.coffee`: `childRemoved` (the proven narrow-seam orphan-skip precedent — §4).
- `src/basic-data-structures/TreeNode.coffee`: `isOrphan` · `isDirectlyInBasement` (O(1), direct only) · `isInBasement`
  (O(depth) walk — why the flag exists) · `root`.
- `src/BasementWdgt.coffee`: `scrollPanel` · `_addLostWidgetNoSettle` (ENTER) · `closeFromContainerWindow`
  (`removeFromTree` → CLOSE) · `hideUsedWidgets`/`showAllWidgets` (the show/hide-filter seam) · `doGC`.
- `src/BasementOpenerWdgt.coffee`: `mouseClickLeft` (OPEN: `world.add windowedBasementWdgt`) · `_reactToDropOfNoSettle`
  (drop-in ENTER).
- `src/WorldWdgt.coffee`: `recalculateLayouts` / `_recalculateLayoutsBody` (the flush) · `auditUndeclaredEndOfCycle` /
  `_undeclaredEndOfCyclePushes` (the careless tally) · `widgetsThatMaybeChangedLayout`.
- Capstone harness: `Fizzygum-tests/scripts/end-of-cycle-audit/run-capstone-gate.sh` · `eoc-capstone-prelude.js` ·
  `eoc-production-probe.js` · `run-audit-loop.sh` · `layout-audit-prelude.js`.

## §10 — Companion docs (concepts + history)

- `docs/archive/layout-system-architecture-assessment.md` **§2.7** — the flush model, the three faults + discriminator, the
  coalescing/`*Coalesced` API.
- `docs/archive/end-of-cycle-flush-inventory.md` — the by-action audit history (incl. the 2026-06-26 `childRemoved` banner =
  the precedent in §4, and the basement-orphan reasoning).
- `docs/archive/end-of-cycle-flush-drawdown-plan.md` — worked playbooks, code patterns, the verification protocol, the tricks
  (disable-probe / stack-probe / narrowest-guard).
- `docs/archive/end-of-cycle-flush-final-records-plan.md` — the arc that reached zero + shipped the capstone gate this targets.
- Memory `fizzygum-end-of-cycle-flush-drawdown` (campaign running state).

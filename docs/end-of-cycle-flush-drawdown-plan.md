# Plan — drive down the END-OF-CYCLE layout-flush inventory

**Status: PLAN ONLY. Written to be executed COLD by an LLM/engineer with zero prior context.** Embeds the
background, the proven `Widget.destroy` playbook, the tooling, commands, code snippets, and gotchas. Read §0 → §3
before touching code.

**Thesis:** each item still landing on the per-frame end-of-cycle layout flush is, on first approximation, a sign of
a **public API method that mutates layout-relevant state but does NOT self-settle** (it defers to end-of-cycle, or
relies on an *unrelated* later event to settle for it). We already proved this on the biggest contributor
(`Widget.destroy`): cutting its wasted work dropped total end-of-cycle traffic by **−55%** (1244 → 564 records) and
revealed two public methods that should have self-settled and didn't. A **second pass (this session)** made the
teardown public methods THEMSELVES self-settle (`close`/`destroy`/`fullDestroy`, like `add`), dropping the total a
further **−44%** (564 → 320) and revealing the old "230 hover" row was mostly menu-cleanup `close()`. This plan
repeats that, contributor by contributor, down the inventory.

---

## 0. Cold-start orientation (workspace, build, test)

Umbrella `/Users/davidedellacasa/code/Fizzygum-all/` (not a repo) holds 3 sibling git repos: **`Fizzygum/`**
(CoffeeScript GUI-framework source, edit here), **`Fizzygum-tests/`** (165 macro SystemTests; drive the live world,
compare canvas screenshots byte-exactly), **`Fizzygum-builds/`** (generated; never edit). One class per file,
filename == class name. `nil` == `undefined`. Every class is a global compiled in-browser; no imports.

**Commands** (`fg` wrapper at the umbrella root works from any cwd):
- `/Users/davidedellacasa/code/Fizzygum-all/fg build` · `fg suite` (dpr1, 165/165, ~1.3min) · `fg gauntlet`
  (build+dpr1+dpr2+WebKit+apps) · `fg test SystemTest_<name>`.
- Torture: `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/torture-headless.js
  --dprs=2 --speeds=fastest --shards=8 --minutes=18` → `.scratch/torture/REPORT.md`.
- Bash cwd resets between calls (use absolute paths / `fg`); foreground `sleep` is blocked; a guard blocks
  `cd …/Fizzygum && … node …/Fizzygum-tests/…` chains (use `fg` or single-line `cd /abs/Fizzygum-tests && node …`).
  **Ask before committing** (review-driven).

---

## 1. The layout engine + the end-of-cycle flush (internalize this)

Deferred invalidate-then-settle engine. `Widget.invalidateLayout()` (`src/basic-widgets/Widget.coffee` ~:3749)
pushes the widget onto `world.widgetsThatMaybeChangedLayout` and climbs to the parent (unless freefloating). The
settle `WorldWdgt.recalculateLayouts()` (`src/WorldWdgt.coffee` ~:853) drains the queue, calling each dirty
widget's `_reLayout()`. **Three settle sites:** (1) **end-of-cycle**, once/frame, `WorldWdgt.doOneCycle` ~:1288 —
**the queue this plan drains**; (2) `mutateGeometryThenSettle` ~:748 (public setter self-settles before returning);
(3) `settleLayoutsOnceAfter` ~:795 (batch → one settle). **Three mutation tiers:** public self-settling
(`setExtent`/`add` via tier 2/3) · deferred (bare `invalidateLayout` → end-of-cycle) · raw/silent
(`silentRawSetExtent`/`fullRawMoveBy` — schedule nothing, used inside passes). `LayoutSpec.ATTACHEDAS_FREEFLOATING
== 100000` = positioned absolutely, NOT laid out by parent.

**What lands at end-of-cycle = the SUBJECT.** A widget's invalidation survives to the end-of-cycle flush iff no
tier-2/3 (self-settling) flush drained the queue between the invalidation and `doOneCycle`. So an end-of-cycle
survivor is, by definition, a mutation that **did not self-settle**. The classification question for each: *should
it have?*

---

## 2. The classification rubric (per contributor)

1. **CONTINUOUS / high-frequency** (pointer hover, momentum scroll, per-frame step animation, a drag move stream)?
   → **LEAVE.** One settle/frame is correct batching; self-settling each event would multiply per-frame settle
   count for no benefit and risk determinism. Allowlist it.
2. **Raw/silent synchronous-apply mislabelled** (it applies layout on the spot, never enqueues)? → out of scope.
3. **DISCRETE one-shot state change** (a menu pick, a button/toggle, collapse, a content edit, a property setter,
   a re-parent) that defers OR relies on an unrelated event to settle? → **CONVERT CANDIDATE.** Find the public
   method; make it self-settle. This is the `Widget.destroy` pattern.
4. **Construction / boot**? → expected; the orphan/batch guards handle it. (The audit showed **0** boot survivors —
   construction self-settles already.)

---

## 3. The proven playbook — the `Widget.destroy` case study (your template)

**What it was:** `destroy` (and `removeFromTree`/`_addCore`) unconditionally did `@parent?.invalidateLayout()`.
Destroying a **freefloating** widget (tooltip/menu/window — most teardown) thus dirtied its parent (usually the
world), which re-laid-out and **changed nothing** (a freefloating child doesn't participate in parent layout). That
wasted re-layout was the #1 end-of-cycle contributor (≈505/1244 records).

**The fix (two complementary moves):**
1. **Stop the wasted invalidation** — freefloating-skip:
   `@parent?.invalidateLayout() unless @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING` (at destroy ~:519,
   removeFromTree ~:2081, _addCore old-parent ~:2412 keyed on the OLD spec). Result: `destroy` 505 → 16 (−97%).
   *(A follow-on plan, `freefloating-invalidation-skip-centralization-plan.md`, centralizes this guard.)*
2. **Make the dependent public methods self-settle** — removing the wasted invalidation EXPOSED two public methods
   that had been re-fitting their container only as an accidental side-effect of teardown:
   - `TextWdgt`/`StringWdgt.sizeToTextAndDisableFitting` (chrome-label re-hug, called by `setText` on edit) — was a
     silent raw resize; the button re-centred only because the caret's `fullDestroy` on stop-editing dirtied the
     parent. Fixed to self-settle (snippet in §5).
   - `LabelButtonWdgt.setLabel` — relied on the old label's destroy dirtying the button. Fixed to self-settle.

**The verification** (all passed): `fg gauntlet` (dpr1/dpr2/WebKit/apps 165/165) + an 18-min torture soak +
re-running the end-of-cycle audit (−55% total, neutrality 165/165 intact). Full record:
`end-of-cycle-flush-inventory.md` §5b, `end-of-cycle-self-settle-conversion-plan.md`.

**The general loop for each contributor:** (a) find the public method behind it; (b) classify (rubric §2); (c) if
convert: make it self-settle (§5); (d) if it relied on an unrelated event, that reliance is the bug — fix the
public method, not the symptom; (e) verify (§6); (f) re-run the audit and confirm the contributor shrank without
new ones appearing.

---

## 4. The audit tooling — regenerate the inventory

The committed harness (the behaviour-neutral, inspector-invisible prelude + the serial per-test loop + the
by-action aggregator), the exact **build → run-serial → aggregate → before/after-diff** recipe, the **neutrality
gate** (`165 PASS inst=YES`, `0 inst=NO`), and how to **attribute a new contributor** (add it to the prelude's
`tagClass(...)` block) all live in ONE place: **`end-of-cycle-audit-tooling.md`** (tooling committed at
`Fizzygum-tests/scripts/end-of-cycle-audit/`; ~25 min serial). Run it **before** starting (to refresh the §7 by-action
targets) and **after each convert** (to confirm the contributor shrank and no new one appeared).

---

## 5. Self-settle code patterns (copy these)

```coffee
# (A) A content/resize mutation that MAY run inside a layout pass (e.g. called from _reLayoutSelf during
#     construction) AND from interactions. settleLayoutsOnceAfter flushes standalone / DEFERS gracefully in a
#     pass (no throw); the parent-invalidate is gated out-of-pass (invalidateLayout THROWS during a pass).
someResizeOrEdit: ->
  @settleLayoutsOnceAfter =>
    … existing raw mutation (silentRawSetExtent / reflow / …) …
    @parent?.invalidateLayout() unless world?._recalculatingLayouts   # re-fit my managing container

# (B) A single discrete public mutation (never called mid-pass). mutateGeometryThenSettle self-settles before
#     returning; it THROWS if reached during a flush/pass (a feature -- surfaces hidden mid-pass callers).
someDiscreteAction: ->
  @mutateGeometryThenSettle =>
    … structural/geometry change …
    @invalidateLayout()

# (C) Freefloating-skip (stop a wasted parent re-fit when a freefloating child leaves/changes):
@parent?.invalidateLayout() unless @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING
```

**Which tier:** content-edit / resize that the layout pass also calls → (A). A one-shot public action (menu pick,
collapse, re-parent) → (B). Removing/destroying/re-parenting a freefloating child → (C). The existing seam
`_reFitContainerAfterRawGeometryChange` re-fits the container but **only if it has `_reLayoutChildren`** (scroll
panel / vertical stack / window) — it does NOT reach a button/menu that lays out a freefloating child via
`_reLayoutSelf`; for those, invalidate the parent directly as in (A).

---

## 6. Verification protocol (mandatory; determinism-sensitive)

Per convert (small, verifiable increments — NEVER convert many at once):
1. `fg build` (syntax + layering lint).
2. `fg suite` (dpr1 165/165). On a PIXEL failure, dump + look:
   `cd /abs/Fizzygum-tests && node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1 --dump-failures=.scratch/x`,
   then `Read` the obtained `.png` vs the committed reference under
   `tests/SystemTest_<name>/automation-assets/**/SWCanvas/ceilPixRatio_1/`. A real regression = the self-settle
   changed the result (the public method's effect now happens at a different time) → fix the method, don't
   recapture blindly. A *correct-but-different* result (rare) → recapture via
   `node scripts/capture-macro-test-references.js <name> --dprs=1,2` (run the FULL flow).
3. `fg gauntlet` (dpr1/dpr2/WebKit/apps).
4. **Torture soak** `--dprs=2 --speeds=fastest --shards=8 --minutes=18` — the gold gate for settle-timing changes.
5. Re-run the audit (§4); confirm the contributor shrank and NO new contributor appeared; neutrality 165/165.

**Determinism contract:** render/layout/input must be a pure function of the event stream + final geometry — never
of timers, frame counts, or intermediate passes (`Fizzygum-tests/DETERMINISM.md`). Self-settling changes WHEN/HOW
MANY settles run per frame — exactly the risk; gauntlet+torture proves safety.

---

## 7. The current inventory — starting targets (after the teardown self-settle: 320 records)

By-action (interaction-frame records; from the post-teardown-self-settle audit). Re-run §4 to refresh before starting.

| action / origin | recs | first-pass classification (verify with the data) |
|---|--:|---|
| **(untagged) event-dispatch residual** (genuine hover/scroll) | 19 | **LEAVE** — continuous. This row was **230**; the teardown self-settle revealed the bulk was menu-cleanup `close()` re-fitting a ScrollPanel (same `Set.forEach < playQueuedEvents` sig as hover, so mislabelled here) — now self-settled, leaving the true hover/scroll residual. |
| **`TextWdgt.reLayoutAndRefreshContainerIfContainedText`** (contained-text edit re-fit) | 118 | **PRIME CONVERT CANDIDATE** (now the biggest residual) — the contained-text-edit seam. Mirror of the `sizeToTextAndDisableFitting` fix: a text edit should self-settle its container. |
| `*.reactToDropOf` / `reactToGrabOf` / `childRemoved` (drag/drop, several classes) | ~75 | **LEAVE** — drag gesture events; the deferred-layout campaign deliberately defers these. |
| `SwitchButtonWdgt.mouseClickLeft` (window collapse toggle) | 32 | discrete click → **investigate** (entangled with collapse). |
| `Widget.collapse` / `unCollapse` | 18+18 | discrete; the container re-fit (`WindowWdgt.childUnCollapsed`) is already synchronous/sanctioned. **Investigate** whether the self-invalidate should self-settle. |
| `Widget.destroy` / `close` / `fullDestroy` (teardown) | **0** | **CONVERTED this session** — even genuine non-freefloating teardown now self-settles (consistent-on-return, like `add`): `destroy` via `mutateGeometryThenSettle`, `close`/`fullDestroy` batched via `settleLayoutsOnceAfter`. The earlier "LEAVE" was overridden. |
| `WindowWdgt.childCollapsed` / `childUnCollapsed` | 4+4 | collapse reactions; sanctioned-synchronous. **Investigate**. |
| `(untagged) during-paint` (freefloating re-fit from `fullPaintInto…`) | 14 | curiosity — layout invalidation reached from the PAINT pass. Low volume; flag, likely leave. |
| `(untagged) macro-driver` (test fixture-build macros) | 14 | out of scope (test construction, not product). |
| `Widget.setMaxDim` (stack-divider drag) | 4 | continuous-ish (divider drag) → likely LEAVE. |
| **`VerticalStackLayoutSpec.setAlignment*` / `setWidthOfElementWhenAdded`** | 6 (3 actions) | **CONVERT CANDIDATE** — discrete layout-spec menu picks (the survey's textbook case); rare but clean. |
| `SimplePlainTextWdgt.setSoftWrap` | 3 | family-5 soft-wrap, deliberately left synchronous-adjacent → likely LEAVE. |
| `Widget.newParentChoice` (re-parent menu) | 1 | discrete menu → **CONVERT CANDIDATE** (or allowlist). |

**Recommended order (biggest leverage / cleanest first):**
1. **`reLayoutAndRefreshContainerIfContainedText` (124)** — the largest convertible; directly analogous to the
   already-proven `sizeToTextAndDisableFitting` self-settle. Likely the next big −%.
2. **`VerticalStackLayoutSpec` setters (6) + `newParentChoice` (1)** — small, discrete, textbook; quick wins to
   validate the pattern end-to-end on menu actions.
3. **collapse / switch (≈70)** — entangled (the container side is already synchronous); investigate whether the
   self-invalidate is a real gap or correct batching before converting.
4. Confirm the **LEAVE** set (hover/scroll 19, drag ~71, paint 13, setMaxDim 6, softwrap 1) is
   genuinely continuous/correct — these become the **allowlist** for the eventual "warn on un-allowlisted
   end-of-cycle layout" gate (survey §9: a build-lint extension of `buildSystem/check-layering.js` with an
   `# end-of-cycle-sanctioned: <why>` marker, mirroring the existing `# layout-apply-sanctioned` lint `[F]`).

---

## 8. Tips, tricks & gotchas (learned the hard way in the `destroy` arc)

- **Find which CLASS actually runs the method before editing.** A chrome label looked like a `StringWdgt` but was a
  `TextWdgt` (`MenuItemWdgt extends LabelButtonWdgt`, its label `= new TextWdgt`). Two fixes landed on the wrong
  override and changed nothing. Always `grep -rn 'theMethod:' --include='*.coffee'` for all overrides.
- **A "fix" that changes NOTHING (byte-identical render) means you edited a code path the test doesn't hit.** Dump
  the failure `.png` and check the `dataHash` actually changed.
- **The re-fit seam (`_reFitContainer`) gates on `container._reLayoutChildren?`** — only scroll-panel/vertical-stack/
  window containers. It will NOT re-fit a button/menu that lays out a freefloating child via `_reLayoutSelf`. For
  those, invalidate the parent directly (pattern A).
- **`mutateGeometryThenSettle` THROWS during a pass/flush; `settleLayoutsOnceAfter` DEFERS gracefully.** For
  anything that might run inside a layout pass (content/resize called from `_reLayoutSelf`), use
  `settleLayoutsOnceAfter` + an out-of-pass-gated `invalidateLayout`.
- **Anchor a `settleLayoutsOnceAfter`/`mutateGeometryThenSettle` on a SURVIVOR, not a widget being destroyed** — the
  orphan-guard at the tail skips the flush if the receiver became detached.
- **Instrument the container's layout method to diff with/without the change** — logging `_reLayoutSelf`'s
  `(center, childWidth, computedPosition)` pinned the bug instantly (the broken run was *missing* re-centre calls).
  Strip all `console.log`/instrumentation before verifying (`grep -rn 'console.log' src` for strays).
- **Run from the right repo / use `fg`.** Multi-line `cd …Fizzygum-tests\n…node…` trips the guard; single-line
  `cd /abs/Fizzygum-tests && node …` or `fg`.
- **dpr1 first (fast, deterministic); dpr2/WebKit via the gauntlet; torture for timing.** A green dpr1 suite is NOT
  sufficient for a settle-timing change — always finish with gauntlet + torture.
- **Benign inspector recapture is fine** (the owner does not care) — but a chrome-render regression (a mis-centred
  label) is a REAL bug; tell them apart by looking at the pixels.

## 9. File:line map (lines drift — grep the name)

`src/basic-widgets/Widget.coffee`: `invalidateLayout` ~:3749 · `destroy` ~:500 · `removeFromTree` ~:2080 ·
`_addCore` ~:2403 · `mutateGeometryThenSettle` ~:748 · `settleLayoutsOnceAfter` ~:795 · `_reFitContainer` ~:1642 ·
`_reFitContainerAfterRawGeometryChange` ~:1619. `src/WorldWdgt.coffee`: `recalculateLayouts` ~:853 · end-of-cycle
flush ~:1288 · the hover diff is `ActivePointerWdgt.coffee` `mouseOverList`/`mouseOverNew.forEach`. Content-edit:
`src/basic-widgets/TextWdgt.coffee` `reLayoutAndRefreshContainerIfContainedText` + `sizeToTextAndDisableFitting`
(already converted) · `src/VerticalStackLayoutSpec.coffee` `setAlignmentTo*`/`setElasticity`/
`setWidthOfElementWhenAdded` (each ends in `@element._refreshScrollPanelWdgtOrVerticalStackIfIamInIt()`). Smell-gate
precedent: `Fizzygum/buildSystem/check-layering.js` (lint `[F]`, `# layout-apply-sanctioned` markers). Survey docs:
`Fizzygum/docs/end-of-cycle-flush-inventory.md`, `end-of-cycle-catalog.md`, `end-of-cycle-self-settle-conversion-plan.md`.

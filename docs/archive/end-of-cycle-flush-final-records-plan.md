> **ARCHIVED — COMPLETE (2026-07-17 restructure).** Final stretch, 5 records to 0; campaign closed 2026-06-27 per inventory banner.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Plan — the end-of-cycle drawdown FINAL STRETCH: drive the last 5 careless records to ZERO, then ship the capstone

**Status: PLAN ONLY. Written 2026-06-27 to be executed COLD by an LLM/engineer with ZERO prior context.** Everything
needed — current state, what already shipped this session, the proven fix-patterns, the remaining work as ordered TODO
items, an important probe wrinkle, the verification protocol, the workflow — is embedded inline or one named-doc hop
away. **Lines drift: grep the named symbol, never trust a line number.**

**One-line goal.** The per-frame end-of-cycle layout flush is down to a **careless set of 5 records / 4 mechanisms**.
Drive that set to **ZERO** — each remaining record CONVERTED, ELIMINATED, or (if a genuine irreducible seam)
DECLARED-COALESCED — then ship the campaign's **capstone**: flip `WorldWdgt.auditUndeclaredEndOfCycle` from log-only to
a **FAILING gate** so nothing new can ever reach the flush undeclared.

---

## §0 — Current state (DONE; do NOT redo)

- **Repos / latest pushed commits (all on `master`):**
  - **`Fizzygum` @ `7e45f4e9`** ("End-of-cycle: drop wasted scroll-construction / scrollbar-layout re-fits"). Confirm:
    `git -C /Users/davidedellacasa/code/Fizzygum-all/Fizzygum log --oneline -1`.
  - **`Fizzygum-tests` @ `a88104fd0`** ("Macros: size text via the public API on an attached widget").
- **The careless set is 5 records / 4 mechanisms** (2026-06-27 full-suite dpr1 audit). Trajectory this campaign:
  `1244 → 564 → 320 → 278 → 253 → 140 → 80 → 73 → 38 → 36 → 18 → 12 → 9 → 5`. The number is **run-to-run noisy by a
  few records** — read "a mechanism → 0" as the signal, not the exact total (Trick T10). The 5 records reproduce
  stably across audit runs (the determineGrabs ×2 reproduced on a re-run).
- **What shipped THIS SESSION** (each a CONVERT / ELIMINATE / lint step, all byte-identical, all gauntlet + torture green):
  - **`Fizzygum 2d9c6c73` — HandleWdgt-as-normal-widget (handle-construction group, 6 records → 0).** The handle no
    longer attaches ITSELF in its constructor. New general Widget hook **`Widget.defaultLayoutSpecWhenAddedTo
    (destination)`** (base = `LayoutSpec.ATTACHEDAS_FREEFLOATING`, wired as the default `layoutSpec` arg of `add` /
    `_addNoSettle`); `HandleWdgt` overrides it to corner-attach to a real destination and free-float on the world/hand.
    So `someWidget.add handle` self-settles (placed by its own flush). `@target` + the padding-aware inset moved into
    `HandleWdgt.iHaveBeenAddedTo` (keyed off `@isFreeFloating()`). The 3 builders (Window/Inspector/Basement) attach the
    resizer via explicit-spec `_addNoSettle @resizer, nil, @resizer.defaultLayoutSpecWhenAddedTo(@)` and record
    `@resizer` AFTER the add. One benign inspector recapture. **NO new settle tier** (an `_settleLayoutsAfterIfOutermost`
    probe was REJECTED by the owner — the root cause was the constructor side-effect, not a missing tier).
  - **`Fizzygum 961ec63d` + `Fizzygum-tests a88104fd0` — lint hard-ban + macro rewrites (buildOverflow group, 3 → 0).**
    `buildSystem/check-layering.js`: `isLowLevel` now includes `fullRaw*`; rule **[D]** tightened from "`_private` only"
    to a **HARD ban** (no escape) on `raw*`/`silent*`/`fullRaw*`/`_private` in macros, scope extended to the shared
    macro VERBS in `src/macros/MacroToolkit.coffee` (the `Macro.fromString """..."""` heredoc bodies ONLY — the L1/L2
    toolkit methods around them are framework). Rewrote the 4 offending fixtures to the PUBLIC attach-first API:
    `buildOverflowingScrollPanelWithText_Macro` (MacroToolkit) + 3 measure-and-size test macros
    (`macroTextRelayoutsCorrectlyOnResize`, `macroBoxTransparencyAndColorChanging`,
    `macroBareTextWidgetDropShadowRestAndDrag`).
  - **`Fizzygum 7e45f4e9` — scroll factory + scrollbar self-guard (factory ×1 + scrollbar ×3 → 0).**
    `ScrollPanelWdgt._reLayoutScrollbars` SELF-GUARDS via save/restore of `@_adjustingContentsBounds`;
    `MenusHelper.createSimpleVerticalStackScrollPanelWdgt` sizes via public `setExtent`/`fullMoveTo` on the attached panel.
- **Earlier-campaign shipped work** (context; do not redo): teardown, contained-text API path, caret/handle wasted
  re-fit, drag/DROP+GRAB gestures, collapse/unCollapse, `PanelWdgt.childRemoved`, the `*Coalesced` declared-coalescing
  infrastructure, `setMaxDim`/`CaretWdgt.gotoSlot`/`InspectorWdgt` converts, the `f4626843` `_reFitContainer`
  guard-hoist, the `e575a776` VerticalStackLayoutSpec/SimplePlainTextWdgt converts. Full history:
  `docs/archive/end-of-cycle-flush-inventory.md` (its 2026-06-27 banner + the "Current numbers" line are UP TO DATE — read them).

---

## §1 — THE OWNER'S MANDATE (front and centre, reaffirmed 2026-06-27)

> **Drive the careless set to ZERO. "Push to literal zero."** Every remaining record gets CONVERTED, ELIMINATED, or —
> where it is a genuine irreducible seam — DECLARED-COALESCED so it is no longer *careless*. Do NOT leave/exempt.
> Then ship the capstone (the audit-fail gate).

**Owner-stated principles that constrain the fixes (learned this session — honour them):**
- **Macros use ONLY the public widget API** — never `raw*`/`silent*`/`fullRaw*`/`_private`. This is now LINT-ENFORCED
  (rule [D], hard ban). For the construction "measure-and-size" pattern, **ATTACH the widget FIRST** (to its end
  destination, or the desktop) and use the public setters — an attached `setWidth` self-settles, so the text wraps in
  place and its height is then readable. (If a public geometry method genuinely cannot work on an orphan, it should
  THROW on an orphan rather than invite a raw workaround — a possible future framework change, not yet needed.)
- **No new settle tier, no rough flag-toggling.** The owner rejected (a) a 3rd `_settleLayoutsAfter` variant, and (b) a
  `try/finally` flag-toggle. Prefer fixes at the ROOT (the handle became a normal widget) and self-guards that mirror
  existing patterns (the scrollbar guard mirrors `_positionAndResizeChildren`'s own `@_adjustingContentsBounds` self-guard).
- **Clean/elegant code is the standing priority** over avoiding a benign inspector member-list recapture (just recapture).
- **Review-driven, per-mechanism commits.** Commit + push each mechanism as it is fixed + verified (owner chose this
  pacing 2026-06-27). **ASK before each commit/push** — present a summary + proposed message, wait for explicit approval.

---

## §2 — Orientation + the model in one breath

**Fizzygum** = a CoffeeScript GUI on one HTML5 `<canvas>` (~470 `.coffee` classes in `Fizzygum/src/`; every class a
global, compiled in-browser, no imports; `nil` == `undefined`; one class per file = its class name). Umbrella
`/Users/davidedellacasa/code/Fizzygum-all/` (not a repo) holds three sibling repos: **`Fizzygum/`** (source — edit
here), **`Fizzygum-tests/`** (165 macro SystemTests; drive the live world, compare SWCanvas SHA-256 screenshots
**byte-exactly**), **`Fizzygum-builds/`** (generated; never edit).

**The model in 5 lines (full version: `docs/archive/layout-system-architecture-assessment.md` §2.7).** The engine drains
`world.widgetsThatMaybeChangedLayout` once per frame in `WorldWdgt.doOneCycle` (the "end-of-cycle flush"), enforcing
**one flush per OUTERMOST public mutation**: a public mutator self-settles via the SINGLE tier `_settleLayoutsAfter`
(set `world._inLayoutMutation`, run a non-settling core, flush `recalculateLayouts()` once; it THROWS if a public setter
is reached on an *attached* widget mid-flush, forcing internal code onto `_<name>NoSettle` cores + raw setters). An
end-of-cycle **survivor** is a layout invalidate that did NOT self-settle — one of **three faults**: **CONVERT** (a
discrete public mutator leaking → wrap in `_settleLayoutsAfter` over a non-settling core), **ELIMINATE** (wasted work
that changes nothing → stop scheduling it), **COALESCE** (a genuine per-event STREAM / irreducible seam → DECLARE it via
a `*Coalesced` public entrypoint so the audit knows the batching is intentional). The `*Coalesced` surface today is one
member — `Widget.setMaxDimCoalesced` — and `world.coalescingEnabled` (default ON) is the A/B switch.

**The deferred-layout SEAM (central to the remaining records).** `Widget._reFitContainerAfterRawGeometryChange`
(`src/basic-widgets/Widget.coffee`, grep the name) is THE mechanism that, on any RAW geometry change of a widget,
schedules a deferred re-fit of the container(s) that track it (`_reFitContainer @parent` + `@parent.parent` if directly
inside a non-text-wrapping scroll panel). `_reFitContainer` (grep it) is the phase dispatcher: in a pass it enqueues the
container; off a pass it `_invalidateLayout()`s it; and it **SKIPS `return if container._adjustingContentsBounds`** (a
container mid its OWN `_positionAndResizeChildren`/`_reLayoutScrollbars` is driving the child top-down and already
accounts for it). The seam is §11's "determinism-exempt path" and `return if @isLayoutInert?()` exempts overlay chrome
(carets, handles — NOT scrollbars, which ARE in the panel's fullBounds). Most remaining records are this seam firing
off-settle because a RAW setter was called outside a layout pass on an attached widget.

**Commands** (the `fg` wrapper is path-correct from ANY cwd):
- `cd /Users/davidedellacasa/code/Fizzygum-all && ./fg build` — full build + all lint gates ([A]–[H], [D] now hard-bans
  low-level in macros).
- `./fg suite` — 165 tests, dpr1, ~1.3 min (the fast byte-identical gate).
- `./fg gauntlet` — build + dpr1 + dpr2 + WebKit + **apps** (12 desktop-app boot-smoke). The full determinism gate.
- `./fg apps` — just the app-smoke leg (run explicitly for window/scroll/handle changes — Trick T7).
- `./fg recapture <name>` — recapture references (only for a *benign* inspector member-list shift — T11).
- **dpr2 torture** (the determinism soak): single-line —
  `cd /abs/Fizzygum-tests && node scripts/torture-headless.js --dprs=2 --speeds=fastest --shards=4 --minutes=10 --out=.scratch/torture-<name>`
  → REPORT.md (empty failures dir = clean; an "infrastructure hiccup" is an incomplete shard, NOT a flake; `shards=8`
  thrashes — use 4).
- **End-of-cycle audit** (~1.5 min sharded): `cd /abs/Fizzygum-tests && bash scripts/end-of-cycle-audit/run-audit-loop.sh`
  → `scripts/.scratch/audit/_SUMMARY.md` (neutrality must read `installed OK: 165/165`).

---

## §3 — STEP 1: confirm the careless set (start here)

Regenerate ground truth (single-line `cd`s; T13):
```sh
pkill -9 -f "Chrome for Testing"
cd /Users/davidedellacasa/code/Fizzygum-all && ./fg build >/dev/null 2>&1
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && bash scripts/end-of-cycle-audit/run-audit-loop.sh
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && sed -n '1,60p' scripts/.scratch/audit/_SUMMARY.md
```
Expect **5 records across 4 tests** (the §4 table). `installed OK: 165/165` is mandatory (neutrality).

---

## §4 — The remaining CARELESS set — the ordered TODO (5 records / 4 mechanisms)

> The mechanisms below are **best-current-understanding, NOT pinned** — the audit's by-action *name* has repeatedly
> lied (it filters `eval` frames). For EACH: **stack-probe FIRST** to pin the real enqueue (§5a), THEN classify and
> resolve. Smallest/cleanest first is fine — they are independent. **READ §6 (the probe wrinkle) BEFORE probing.**

| # | test (ctor × action) | recs | best-guess mechanism | likely fix (VERIFY) |
|---|---|--:|---|---|
| 1 | **`macroEditingStringInScrollablePanelCaretAlwaysVisible`** — `ScrollPanelWdgt`, `Object.playQueuedEvents < e` | 1 | a caret-edit scroll-panel re-fit survivor (the bulk caret path was eliminated long ago via the `isLayoutInert` raw-move skip; this is a residual edit seam) | probe → likely ELIMINATE (wasted re-fit); disable-probe to confirm byte-identical |
| 2 | **`macroResizingScrollFrameThenImmediatelyScrollingTheHandlesDontStickToScrollPanelContent`** — `SimpleDocumentScrollPanelWdgt`, macro-driver | 1 | the last scroll-frame-resize seam (a raw resize/move of scroll content or frame tripping `_reFitContainerAfterRawGeometryChange` off-settle) | probe → if a macro raw-setter on an attached widget, fix the macro to attach-first/public (like §0's macro rewrites); if a product path, ELIMINATE/CONVERT |
| 3 | **`macroStackDividerReproportionsCells`** — `RectangleWdgt` ×2, tagged `ActivePointerWdgt.determineGrabs` | 2 | the stack-divider GRAB setup leaks 2 cell (`RectangleWdgt`) records; the per-move drag stream already coalesces via `setMaxDimCoalesced` (declared) | probe → convert/eliminate the grab-setup invalidate, OR fold it into the divider's existing `_coalescedDeclare` window. **NB: did NOT show in a hand-rolled origin probe — see §6.** |
| 4 | **`macroStringWdgtInlineTypingRefitsUnderFittingModes`** — `ScrollPanelWdgt`, `Set.forEach < playQueuedEvents` | 1 | the documented **irreducible** off-world-basement re-home: a pop-up-close lost-widget re-home into the never-painted basement scroll panel, reached from construction-path seams (`_addNoSettle`, raw-move, basement show/hide-filter) that CANNOT be safely orphan-skipped (a blanket `return if @isOrphan()` in `_invalidateLayout` broke 63 tests — T3) | **DECLARE it** (bring the basement-re-home seam under `_coalescedDeclare`), if re-confirmed irreducible. **JUDGEMENT CALL — flag for the owner** (a construction-path declaration is unusual). Resolve LAST. |

**Reframed scope (owner).** Tagged "macro-driver" records are NOT automatically out of scope: drive them to zero
**where the survivor traces to a PRODUCT code path** (a real `add`/raw-mutator any app would also hit). If the
stack-probe shows a genuine product leak, CONVERT/ELIMINATE; if it's a macro raw-setter on an attached widget, FIX THE
MACRO to attach-first + public (the lint [D] should already be flagging it at build — if the build is green, the macro
isn't using a banned setter, so the seam is product-side). If it's purely test scaffolding with no product analog, note
that explicitly in the inventory.

---

## §5 — The method, per record (classify → localize → resolve → verify)

**(a) LOCALIZE with the stack-probe** — the only reliable localizer (the audit `sig` lies: its `shortSig` truncates +
filters `eval` frames, and every in-browser-compiled Fizzygum method IS an eval frame). **BUT see §6** — a hand-rolled
probe that only wraps `_invalidateLayout` and gates on `isOrigin` (depth-0) MISSED the determineGrabs records this
session. The ROBUST approach: instrument the audit's OWN prelude (`scripts/end-of-cycle-audit/layout-audit-prelude.js`),
which provably catches every record the audit reports — add an UNFILTERED `new Error().stack` log at its
`_invalidateLayout` wrap (and/or at the `_reFitContainer` push), gated to the test under probe. Run:
```sh
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests
PRELUDE_JS=$PWD/scripts/end-of-cycle-audit/layout-audit-prelude.js LOG_FILE=/tmp/eoc.log \
  node scripts/run-macro-test-headless.js SystemTest_<the-test> --dpr=1
```
**Reason from the stack, not the tag.**

**(b) CLASSIFY** with the discriminator + the disable-probe. Of the pinned stack ask: *"is a public API mutator on it,
returning unsettled?"* → CONVERT. *Raw/internal move of a widget that can't affect what it dirties* → ELIMINATE. *Raw
event stream / irreducible construction seam* → COALESCE (declare). Decide convert-vs-eliminate EMPIRICALLY with the
**disable-probe**: no-op the deferred re-fit, `./fg build`, `./fg suite` → **byte-identical ⇒ wasted ⇒ ELIMINATE**;
**failures ⇒ load-bearing ⇒ CONVERT**.

**(c) RESOLVE — the PROVEN PATTERNS this session (reuse these):**
- **Macro raw-setter on an attached widget** (records that trace to a `*_automationCommands.js` macro or a MacroToolkit
  verb): rewrite to **attach-first + public** — `world.add w; w.setExtent …; w.setWidth …; w.fullMoveTo …` instead of
  `w.rawSetExtent`/`silentRawSetWidth`/`fullRawMoveTo` after add. Worked for `buildOverflowingScrollPanelWithText_Macro`
  + 3 measure-and-size macros (`961ec63d`/`a88104fd0`). Lint [D] enforces it; a green build means no macro is using a
  banned setter, so any *remaining* seam record is PRODUCT-side.
- **Product construction code doing `world.add X; X.rawSet*`** (e.g. a factory): use public setters on the attached
  widget (`MenusHelper.createSimpleVerticalStackScrollPanelWdgt`, `7e45f4e9`). [D] does NOT cover product code, so the
  audit (not the lint) is what flags these.
- **A container's own chrome-layout tripping the seam to re-fit itself** (the scrollbar case): make the layout method
  SELF-GUARD with **save/restore** of `@_adjustingContentsBounds` (NOT try/finally, NOT a wrapper in the caller) —
  mirrors `_positionAndResizeChildren`. `ScrollPanelWdgt._reLayoutScrollbars` (`7e45f4e9`). Per-instance, so nested
  containers are independent (verified: nested-scroll tests byte-identical at dpr2, 0 records).
- **A constructor with a layout side-effect** (the handle case): dissolve at the root — make it a normal widget the
  caller adds; a destination-aware default spec (`defaultLayoutSpecWhenAddedTo`) keeps call sites clean (`2d9c6c73`).
- **CONVERT** (a discrete public mutator leaking): wrap its body `@_settleLayoutsAfter => @_<name>NoSettle()` over a
  non-settling core; route callees to their `_NoSettle` cores (cores-call-cores; the single tier THROWS otherwise).
- **ELIMINATE**: stop scheduling the wasted re-fit with the NARROWEST provably-byte-identical guard. **Do NOT push a
  skip down to a shared primitive** without checking the construction path (T3, the 63-test lesson).
- **COALESCE / DECLARE**: wrap the stream/irreducible core through `_coalescedDeclare` behind a `*Coalesced` public
  entrypoint (pattern: `Widget.setMaxDimCoalesced`). For an irreducible construction-path record (#4), the declaration
  is the disposal — flag it for the owner.

**(d) VERIFY** — the full §7 gate, per resolution. Commit + push each mechanism after it is green (ASK first).

---

## §6 — ⚠ THE PROBE WRINKLE (read before §5a)

This session a hand-rolled probe (`/tmp/scratch`: wrap `Widget.prototype._invalidateLayout`, gate on
`isOrigin (depth===0) ∧ layoutIsValid ∧ !_inLayoutMutation ∧ _coalescedDeclarationDepth===0 ∧ !isOrphan()`) caught
**ZERO** records for `macroStackDividerReproportionsCells`, even though the audit stably reports its **2 RectangleWdgt
determineGrabs records**. Unreconciled. Hypotheses for the next session to test (read the code, don't guess):
- The records may be **climbed** (depth > 0), not origins — the audit's "origin records" come from
  `aggregate-layout-audit.js` reading the prelude's snapshot of `world.widgetsThatMaybeChangedLayout` at
  `recalculateLayouts`, filtered to `isOrigin` enqueueMap entries; reconcile what "origin" means there vs. a hand probe.
- They may enter the queue via **`_reFitContainer`'s direct push** (`world.widgetsThatMaybeChangedLayout.push container`)
  rather than `_invalidateLayout` — a hand probe wrapping only `_invalidateLayout` would miss those. Wrap `_reFitContainer`
  too.
- **ACTION: instrument the audit's OWN prelude** (`scripts/end-of-cycle-audit/layout-audit-prelude.js`) — it provably
  catches every record the audit reports. Add the stack log there. Don't fight a hand-rolled probe.
- First **read** `scripts/end-of-cycle-audit/aggregate-layout-audit.js` + `layout-audit-prelude.js` end-to-end to learn
  EXACTLY how a "record" is defined and attributed; that resolves the wrinkle and tells you where to log the stack.

---

## §7 — Verification protocol (mandatory; determinism-sensitive)

String-edit / scroll / paint / caret / handle / drag / grab are ALL determinism-sensitive — do the FULL set for ANY
code change. The `fg` wrapper runs from any cwd:
1. `./fg build` — **0 violations** (lints [A]–[H] + dead-method + thin-wrap gates; [D] now hard-bans low-level in macros).
2. `./fg suite` — dpr1 **165/165**. On a pixel failure, dump + look (don't recapture blindly): `cd /abs/Fizzygum-tests
   && node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1 --dump-failures=.scratch/x`, then Read the
   `.png` vs the committed reference under `tests/SystemTest_<name>/automation-assets/**/SWCanvas/ceilPixRatio_1/`. A
   real fixture-render change ⇒ make it byte-identical (do NOT recapture); only a benign inspector member-list shift ⇒
   recapture (T11).
3. `./fg gauntlet` — dpr1/dpr2/WebKit **165/165** + **apps 12/12** (confirm the apps leg ACTUALLY ran — T7).
4. **dpr2 torture** (single-line; the gold gate for settle-timing changes):
   `cd /abs/Fizzygum-tests && node scripts/torture-headless.js --dprs=2 --speeds=fastest --shards=4 --minutes=10 --out=.scratch/torture-<name>`
   → REPORT.md clean (failures dir empty; an "infrastructure hiccup" is NOT a flake).
5. **Re-audit** (`bash scripts/end-of-cycle-audit/run-audit-loop.sh`): the resolved mechanism → 0 (or → declared), NO
   new mechanism appeared, neutrality `installed OK: 165/165`.

**Determinism contract:** render/layout/input must be a pure function of the EVENT STREAM + final geometry — never of
wall-clock/frame-count/intermediate-pass. A green dpr1 suite is NOT sufficient for a settle-timing change; finish with
gauntlet + torture. (`Fizzygum-tests/DETERMINISM.md`.)

---

## §8 — THE CAPSTONE: flip `auditUndeclaredEndOfCycle` from LOG to FAIL (after §4 is empty)

**What it is.** `WorldWdgt.auditUndeclaredEndOfCycle` (DEBUG, default off) already records every careless push
(`_invalidateLayout` hook → `world._undeclaredEndOfCyclePushes`) and logs them at the flush (`recalculateLayouts` →
`UNDECLARED-EOC frame=N total=M :: Ctor xK`). The capstone turns that LOG into a **FAILING gate**: a CI/test run with
the flag on that **fails if any `UNDECLARED-EOC` record appears across the whole suite**. That makes "nothing reaches
the flush undeclared" a regression tripwire.

**Anchors** (grep — numbers drift). `src/WorldWdgt.coffee`: `coalescingEnabled` · `_coalescedDeclarationDepth` ·
`auditUndeclaredEndOfCycle` · `_undeclaredEndOfCyclePushes` (all near each other) · the `UNDECLARED-EOC` log in
`recalculateLayouts`. `src/basic-widgets/Widget.coffee`: the careless-audit hook inside `_invalidateLayout` (grep
`auditUndeclaredEndOfCycle`).

**This SUPERSEDES the old `# end-of-cycle-sanctioned` allowlist-lint idea** (a static "what reaches the flush" lint is a
call-graph question that's intractable to make exhaustive — the same reason `check-layering`'s transitive `*NoSettle`
closure [G] was prototyped and REJECTED). `auditUndeclaredEndOfCycle` already computes the EXACT runtime set, and
`_coalescedDeclare` encodes "this one is intentional," so the gate is just "the careless set must be empty" — sound by
construction, riding the existing audit harness (~1.5 min). Say so in the inventory when you land it.

**⚠ NOISE CONSIDERATION (decide with evidence).** The audit is **run-to-run noisy by a few records** (T10). A naive
"fail if total > 0" gate could be FLAKY. Before flipping: re-run the audit several times on a zero state to confirm it
is reliably zero (no intermittent record). If a record is genuinely intermittent, it must be eliminated/declared too —
the capstone cannot ship while any careless record, even an occasional one, survives. Self-test the gate (Trick T15:
plant a careless push → confirm it fails loudly → revert).

**Shape options (decide with evidence):** (i) a dedicated headless run with the flag on that exits non-zero if any
`UNDECLARED-EOC` line is emitted; or (ii) extend `run-all-headless.js`'s audit hook so the sharded audit itself fails
when the careless total > 0. Wire it as a build/CI step.

---

## §9 — THE TRICKS (carried forward; everything the campaign learned the hard way)

**Probing & classification**
- **T1 — The stack-probe is the only reliable localizer; the audit `sig` LIES** (eval-frame filtering). Use the audit's
  OWN prelude as the probe base (§6), unfiltered `new Error().stack`. **Reason from the stack, NOT the by-action name.**
- **T2 — The disable-probe decides convert-vs-eliminate in ~10 min.** No-op the re-fit, run the suite: byte-identical →
  eliminate; tests fail → convert. Its verdict is GLOBAL — a "load-bearing" hook can still have a specific eliminable leak.
- **T3 — Surgical eliminates: narrowest guard, byte-identical. NEVER generalize a skip to a shared primitive** —
  `return if @isOrphan()` in `_invalidateLayout` broke 63 tests (construction makes every widget an orphan).
- **T10 — The audit is sharded + faithful (~1.5 min) but run-to-run noisy by a few records.** "A mechanism → 0" is the
  signal, not the exact total. Neutrality `installed OK: 165/165` is mandatory. (This noise directly shapes the capstone — §8.)

**Owner-preference patterns (this session)**
- **TA — Fix at the ROOT, not with a patch.** A constructor with a layout side-effect → make it a normal widget the
  caller adds (handle). The owner rejects new settle tiers and rough flag-toggles. Prefer self-guards that mirror an
  existing pattern.
- **TB — Macros use ONLY the public API; attach-first for measure-and-size.** Lint [D] hard-bans `raw/silent/fullRaw/_`
  in macros (test macros + MacroToolkit verb heredocs). Rewrite to `world.add w; w.setWidth W; …`.
- **TC — `_adjustingContentsBounds` is the seam-skip signal** ("I'm laying out my contents, don't re-fit me",
  honoured by `_reFitContainer`). Extend it to a container's own chrome-layout via a SAVE/RESTORE self-guard
  (per-instance ⇒ nesting-safe). Do NOT mark scrollbars `isLayoutInert` — unlike handles/carets they ARE in the panel's
  `fullBounds` (`Widget.coffee`, grep the `isLayoutInert` exclusion comment ~"mangle how the Panel inside ScrollPanel"),
  so excluding them shrinks the painted/hit-test bounds.

**Build / test / determinism**
- **T6 — Never chain `./fg build && ./fg suite` under a tight (≤2 min) tool timeout** — build (~1 min) + suite (~1.3
  min) looks like a hang. Separate tool calls.
- **T7 — `./fg gauntlet` piped through `| rg | tail` can SIGPIPE-kill and silently skip the apps leg.** Redirect to a
  file (`> log 2>&1`) or run `./fg apps` EXPLICITLY (12/12) for any window/scroll/handle/grab change.
- **T8 — Determinism is byte-exact and dpr2-under-load-sensitive.** Green dpr1 is NOT enough for a settle-timing change:
  finish with `gauntlet` (dpr2/WebKit) + a dpr2 **torture** soak.
- **T11 — Benign inspector member-list recapture is fine** (owner does NOT care): adding/renaming a Widget-family method
  shifts the inspector's alphabetical member list (it enumerates `for property of @target`) → `./fg recapture <name>`,
  don't contort the code. A chrome/text RENDER change is a real bug — distinguish by looking at the dumped `.png` pixels.
  (Hit this session: the 2 new Widget methods shifted `macroDuplicatedInspectorDrivesCopiedTargetOnly`.)
- **T12 — Changing a method's RETURN VALUE can break test MACROS that chain off it.** Grep BOTH repos' `.js` for the
  method in expression/chain position; a core that's chained must end with `@`.

**Shell / hygiene**
- **T13 — The Bash tool runs FISH + a PreToolUse guard; cwd resets between calls** (always `cd /abs/... && …`
  single-line). **The guard BLOCKS a multi-line command whose first line is `cd …Fizzygum-tests` running a node
  script** — run such SINGLE-LINE or via `fg`. macOS has no `timeout` cmd; **BSD `sed` has no `\b`**. Kill orphan
  `Chrome for Testing` before a suite/audit (`pkill -9 -f "Chrome for Testing"`); never the user's Chrome. **`git push`
  twice in one command runs from the same cwd — push each repo from its own dir** (a recurring slip this session).
- **T14 — New plan/doc files are UNTRACKED** and silently excluded from a `git add <listed files>` commit — fold into
  the arc's commit or commit standalone; re-confirm `git status` shows nothing `??`. (NOTE: this very plan, plus the
  pre-existing `docs/archive/end-of-cycle-flush-drawdown-plan.md` / `docs/archive/layout-system-architecture-assessment.md` mods and the
  untracked `docs/archive/end-of-cycle-flush-endgame-plan.md`, are uncommitted — ask the owner what to do with them.)
- **T15 — Self-test any new/changed gate** (plant a violation → confirm the build/CI aborts loudly → revert). The [D]
  hard-ban was self-tested this session (it failed on 11 violations, passed after the rewrites). Lint edits under
  `buildSystem/*.js` are pure tooling (not compiled into the world) — can't change a screenshot.
- **T16 — Commit-message hygiene:** `git commit -F <file>` (NEVER backticks / `$()` in `-m` — fish/bash substitutes them
  and silently drops that span). End every message: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
  The `.gitattributes:2 is not a valid attribute name` warning on every git call is pre-existing noise — ignore it.

---

## §10 — Workflow & recording

- **Review-driven, per-mechanism (owner, 2026-06-27):** commit + push each mechanism once it is fully green (gauntlet
  incl. apps + torture + re-audit). **ASK before each commit AND push** — present the diff + proposed message, wait for
  explicit approval. Present each as a clean unit (note which repo(s) it spans).
- Per resolution: flip the relevant row + new total + a dated banner in `docs/archive/end-of-cycle-flush-inventory.md`, and
  update memory `fizzygum-end-of-cycle-flush-drawdown` (state + remaining lines). Bundle the inventory update WITH the
  code commit (it is the record OF the change).
- After the capstone ships, update memory + the inventory to mark the campaign COMPLETE, and note the capstone gate's
  location + how to run it.

---

## Appendix — anchors & companion docs (grep the symbol; numbers drift)

- **This session's shipped code (read these to see the proven patterns in situ):**
  - `src/HandleWdgt.coffee` (`defaultLayoutSpecWhenAddedTo`, `iHaveBeenAddedTo`, the constructor) +
    `src/basic-widgets/Widget.coffee` (`defaultLayoutSpecWhenAddedTo` base, `add`/`_addNoSettle` defaults,
    `addAndTrackHandle`).
  - `src/macros/MacroToolkit.coffee` (`buildOverflowingScrollPanelWithText_Macro` — the attach-first rewrite).
  - `src/basic-widgets/ScrollPanelWdgt.coffee` (`_reLayoutScrollbars` self-guard) +
    `src/basic-widgets/menu-system/MenusHelper.coffee` (`createSimpleVerticalStackScrollPanelWdgt`).
  - `buildSystem/check-layering.js` (`isLowLevel`, `MACRO_FORBIDDEN_CALL`, `MACRO_VERBS_FILE`, `checkMacroFile`'s
    `heredocOnly`, the [D] comment block).
- **Seam + settle machinery** — `src/basic-widgets/Widget.coffee`: `_settleLayoutsAfter` (single tier) ·
  `_invalidateLayout` (the FLOWRULE throw + the careless-audit hook) · `_reFitContainer` (the `_adjustingContentsBounds`
  guard) · `_reFitContainerAfterRawGeometryChange` (the `isLayoutInert` skip). `src/WorldWdgt.coffee`:
  `recalculateLayouts` · the end-of-cycle flush in `doOneCycle`.
- **Coalescing API + audit** — `src/basic-widgets/Widget.coffee`: `setMaxDim` · `setMaxDimCoalesced` · `_coalescedDeclare`
  · `_setMaxDimNoSettle`. `src/WorldWdgt.coffee`: `coalescingEnabled` · `_coalescedDeclarationDepth` ·
  `auditUndeclaredEndOfCycle` · `_undeclaredEndOfCyclePushes` · the `UNDECLARED-EOC` log.
- **Probe tooling** — `Fizzygum-tests/scripts/end-of-cycle-audit/`: `layout-audit-prelude.js` (the install pattern +
  WeakMap state — USE THIS as the probe base, §6), `run-audit-loop.sh`, `aggregate-layout-audit.js` (read it to resolve
  the §6 wrinkle).
- **Up-to-date companion docs:**
  - `docs/archive/end-of-cycle-flush-inventory.md` — the full by-action AUDIT HISTORY + verdicts; its **2026-06-27 banner** +
    "Current numbers" line (5 records) are CURRENT.
  - `docs/archive/layout-system-architecture-assessment.md` **§2.7** — the CONCEPTS: flush model, the three faults + discriminator,
    the coalescing model + `*Coalesced` API.
  - `docs/tooling/coalescing-measurement.md` — the measurement HARNESS + the divider-drag case study (the verdict rule).
  - `docs/archive/end-of-cycle-flush-drawdown-plan.md` — the worked PLAYBOOKS, code PATTERNS, file map.
  - `docs/archive/end-of-cycle-flush-endgame-plan.md` — the PRIOR endgame plan (covered groups 1–5; groups 1+2 are now SHIPPED
    per §0; this plan supersedes it for the remaining records + capstone).
  - Memory `fizzygum-end-of-cycle-flush-drawdown` (running state) + `fizzygum-layering-naming-tiers` (the [A]–[H] tiers).

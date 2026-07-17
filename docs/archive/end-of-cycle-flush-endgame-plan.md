> **ARCHIVED — COMPLETE (2026-07-17 restructure).** Ordered TODO to zero the ~18-record careless set; superseded by final-records-plan.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Plan — the end-of-cycle drawdown ENDGAME: drive the CARELESS set to ZERO, then the audit-fail capstone

**Status: PLAN ONLY. Written 2026-06-26 to be executed COLD by an LLM/engineer with ZERO prior context.** Everything
needed — current state, the owner's mandate, a recap of the model, the remaining work as ordered TODO items, the proven
probe-techniques, the verification protocol, the hard-won tricks, the workflow — is embedded inline or one named-doc
hop away. **Lines drift: grep the named symbol, never trust a line number.**

**One-line goal.** The discrete public-mutation converts and the wasted-work eliminates are done; the per-frame
end-of-cycle layout flush is down to a **careless set of ~18 records / 8 groups**. Drive that careless set to **ZERO**
— each remaining record CONVERTED, ELIMINATED, or (if a genuine measured stream / an irreducible seam) DECLARED-COALESCED
— then ship the campaign's **capstone**: flip `WorldWdgt.auditUndeclaredEndOfCycle` from log-only to a **FAILING gate** so
nothing new can ever reach the flush undeclared.

---

## §0 — Current state (DONE; do NOT redo)

- **Repo: `Fizzygum` master @ `f4626843`** ("Hoist the `_adjustingContentsBounds` guard in `_reFitContainer` to the
  off-settle arm"). Confirm: `git -C /Users/davidedellacasa/code/Fizzygum-all/Fizzygum log --oneline -1`.
- **The careless set is ~18 records / 8 groups (interaction frames ~17)**, master `f4626843`. Trajectory of the
  end-of-cycle survivor count: `1244 → 564 → 320 → 278 → 253 → 140 → 80 → 73 → 38 → 36 → 18`. The number is **run-to-run
  noisy by a few records** — read "a group → 0" as the signal, not the exact total (Trick T10).
- **What shipped this campaign** (each a CONVERT / ELIMINATE / new-infrastructure step, all byte-identical, all
  gauntlet + torture green):
  - The whole **`*Coalesced` + declared-coalescing infrastructure**: `Widget.setMaxDimCoalesced` (the first and only
    `*Coalesced` public member), `Widget._coalescedDeclare` / `world._coalescedDeclarationDepth`, the
    `world.coalescingEnabled` A/B switch, the `world.auditUndeclaredEndOfCycle` "careless" audit + its `UNDECLARED-EOC`
    reporting in `recalculateLayouts`, and the measurement **harness** (`docs/tooling/coalescing-measurement.md`).
  - The owner's **converts**: `Widget.setMaxDim` (public self-settle, with `setMaxDimCoalesced` as the *Coalesced API the
    stack-divider drag uses), `CaretWdgt.gotoSlot` (public wrapper + `_gotoSlotNoSettle`), the `InspectorWdgt` rebuild,
    and the `setMinAndMaxBoundsAndSpreadability` construction-relayout **ELIMINATE** (orphan-skip at the sizing-then-add
    seam).
  - `e575a776`: `VerticalStackLayoutSpec` align/elasticity/base-width + `SimplePlainTextWdgt.setSoftWrap` **converts**
    (public wrapper + `_<name>NoSettle` cores), plus a new `check-layering` rule **[H]** (a NON-FATAL warning: a settle
    wrapper with a guard `return` BEFORE its `_settleLayoutsAfter` — push that guard into the core; `# early-return-
    sanctioned: <why>` exempts).
  - `f4626843`: **ELIMINATE** — hoisted `return if container._adjustingContentsBounds` in `Widget._reFitContainer` ABOVE
    the in-pass/off-settle branch, so the synchronous off-settle arm ALSO skips re-fitting a container that is mid its
    own `_positionAndResizeChildren`. This removed the macro-driver `add → _reLayoutChildren` pushes AND the entire
    during-paint caret family (`scrollCaretIntoView → _positionAndResizeChildren → child-resize seam`) — the same
    redundancy. Audit **36 → 18**.
- **Earlier-campaign shipped work** (context; do not redo): teardown (`destroy`/`close`/`fullDestroy`), the
  contained-text API path, the caret/handle wasted re-fit (eliminate), the drag/DROP + GRAB gestures, collapse/unCollapse
  + `SwitchButtonWdgt.mouseClickLeft`, and `PanelWdgt.childRemoved` (eliminated by skipping the re-fit when the container
  is a detached/orphan subtree). Full history: `docs/archive/end-of-cycle-flush-inventory.md`.

---

## §1 — THE OWNER'S MANDATE (front and centre)

> **Drive the careless set to ZERO. Every remaining record gets CONVERTED or ELIMINATED — or, where it is a genuine
> measured per-event STREAM or a truly irreducible seam, DECLARED-COALESCED so it is no longer *careless*. Do NOT
> exempt. "I want them to go away."**

"Careless" = an off-settle layout push on an ATTACHED widget made OUTSIDE a `*Coalesced` declaration — exactly what
`auditUndeclaredEndOfCycle` reports. The mandate is to empty that set. Note the crucial distinction the new model buys:
**declaring** a stream/irreducible record via `_coalescedDeclare` (a `*Coalesced`-style entrypoint) takes it OUT of the
careless set legitimately — it is an *intention-revealing declaration the audit understands*, NOT an allowlist exemption.
So "drive to zero" is reachable even for a record that genuinely cannot be converted or eliminated: declare it.

The capstone (§6) then locks zero-careless in as a gate. The OLD endgame-plan proposed a `# end-of-cycle-sanctioned`
allowlist LINT as the capstone — **that is SUPERSEDED**; the capstone is now the `auditUndeclaredEndOfCycle` audit-fail
flip (§6 says why).

---

## §2 — Orientation + the model in one breath

**Fizzygum** = a CoffeeScript GUI on one HTML5 `<canvas>` (~470 `.coffee` classes in `Fizzygum/src/`; every class a
global, compiled in-browser, no imports; `nil` == `undefined`; one class per file = its class name). Umbrella
`/Users/davidedellacasa/code/Fizzygum-all/` (not a repo) holds three sibling repos: **`Fizzygum/`** (source — edit
here), **`Fizzygum-tests/`** (165 macro SystemTests; drive the live world, compare SWCanvas SHA-256 screenshots
**byte-exactly**), **`Fizzygum-builds/`** (generated; never edit).

**The model in 4 lines (full version: `layout-system-architecture-assessment.md` §2.7).** The engine drains
`world.widgetsThatMaybeChangedLayout` once per frame in `WorldWdgt.doOneCycle` (the "end-of-cycle flush"), enforcing
**one flush per OUTERMOST public mutation**: a public mutator self-settles via the SINGLE tier `_settleLayoutsAfter`
(set `world._inLayoutMutation`, run the core, flush `recalculateLayouts()` once; THROWS if a public setter is reached
on an *attached* widget mid-flush, forcing internal code onto `_<name>NoSettle` cores + raw setters). An end-of-cycle
**survivor** is a layout invalidate that did NOT self-settle — one of **three faults**: **CONVERT** (a discrete public
mutator leaking → wrap in `_settleLayoutsAfter` over a non-settling core), **ELIMINATE** (wasted work that changes
nothing → stop scheduling it), **COALESCE** (a genuine per-event STREAM → DECLARE it via a `*Coalesced` public
entrypoint so the audit knows the batching is intentional). The `*Coalesced` surface today is one member —
`Widget.setMaxDimCoalesced` — and `world.coalescingEnabled` (default ON) is the A/B switch to MEASURE whether a stream
warrants coalescing (`docs/tooling/coalescing-measurement.md`: max≈1 → don't bother; max≫1 → coalesce).

**Commands** (the `fg` wrapper is path-correct from ANY cwd):
- `cd /Users/davidedellacasa/code/Fizzygum-all && ./fg build` — full build + all lint gates ([A]–[H]).
- `./fg suite` — 165 tests, dpr1, ~1.3 min (the fast byte-identical gate).
- `./fg gauntlet` — build + dpr1 + dpr2 + WebKit + **apps** (12 desktop-app boot-smoke). The full determinism gate.
- `./fg apps` — just the app-smoke leg (run explicitly for window/scroll-touching changes — Trick T7).
- `./fg recapture <name>` — recapture references for a test (use only for a *benign* inspector member-list shift — T11).
- **dpr2 torture** (the determinism soak): single-line —
  `cd /abs/Fizzygum-tests && node scripts/torture-headless.js --dprs=2 --speeds=fastest --shards=4 --minutes=10 --out=.scratch/torture-<name>`
  → REPORT.md (empty = clean; `shards=8` thrashes — use 4).
- **End-of-cycle audit** (~1.5 min sharded): `cd /abs/Fizzygum-tests && bash scripts/end-of-cycle-audit/run-audit-loop.sh`
  → `scripts/.scratch/audit/_SUMMARY.md` (neutrality must read `installed OK: 165/165`).

---

## §3 — STEP 1: confirm the careless set (optional — numbers are from `f4626843`)

The §0 numbers are the `f4626843` audit; you do NOT need to re-run it to begin (start from the §4 TODO and stack-probe
each group). If you want fresh ground truth or are resuming on a later master, regenerate it (single-line `cd`s; T13):
```sh
pkill -9 -f "Chrome for Testing"
cd /Users/davidedellacasa/code/Fizzygum-all && ./fg build >/dev/null 2>&1
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && bash scripts/end-of-cycle-audit/run-audit-loop.sh
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && sed -n '1,80p' scripts/.scratch/audit/_SUMMARY.md
```
Expect ~18 careless records across the 8 groups in §4 (plus the orphan/construction noise the audit already excludes).

---

## §4 — The remaining CARELESS set — the ordered TODO (~18 records / 8 groups)

> The mechanisms below are **best-current-understanding, NOT pinned** — the audit's by-action *name* has repeatedly
> lied (it filters `eval` frames). For EACH group: **stack-probe FIRST** to pin the real enqueue (§5a), THEN classify
> and resolve. Smallest/cleanest first is fine — the groups are independent.

| # | group (ctor × test) | recs | best-guess mechanism | likely fix (VERIFY) |
|---|---|--:|---|---|
| 1 | **Handle construction** — `RectangleWdgt` ×5 + `SimpleButtonWdgt` ×1 (the layout/resize tests) | 6 | `new HandleWdgt → makeHandleSolidWithParentWidget → @target._addNoSettle` invalidates the resized `@target`, climbing to world | ELIMINATE (inert chrome can't change @target's fit) **or** CONVERT the materialize sites — probe |
| 2 | **Residual macro-driver content-build** — `SimpleDocumentScrollPanelWdgt` ×4 + `ScrollPanelWdgt` (via `buildOverflowingScrollPanelWithText_Macro`) ×3 + `SimpleVerticalStackScrollPanelWdgt` ×1 | 8 | a `theTest_InputEvents_Macro` add path NOT caught by the `f4626843` guard-hoist (a DIFFERENT add path than the `_adjustingContentsBounds`-guarded ones) | classify per the product path it traces to — probe |
| 3 | **Divider `determineGrabs`** — `RectangleWdgt` ×2 (`macroStackDividerReproportionsCells`) | 2 | the `ActivePointerWdgt.determineGrabs` path still leaks 2 on the divider drag (which already coalesces via `setMaxDimCoalesced`) | probe — convert/eliminate, or fold into the drag's declaration |
| 4 | **Caret / edit** — `ScrollPanelWdgt` `playQueuedEvents` ×1 (`macroEditingStringInScrollablePanelCaretAlwaysVisible`) | 1 | one caret-edit scroll-panel re-fit survivor (the bulk caret path was eliminated §5c-history; this is a residual seam) | probe — likely ELIMINATE |
| 5 | **Irreducible** — `ScrollPanelWdgt` `Set.forEach < playQueuedEvents` ×1 (`macroStringWdgtInlineTypingRefitsUnderFittingModes`) | 1 | the documented `childRemoved` off-world-basement re-home; the basement is also hit by construction-path seams that can't be orphan-skipped | DECLARE it (mandate-compliant disposal), if re-confirmed irreducible |

### Group 1 — Handle construction (6 records)

**Mechanism (read the code).** `new HandleWdgt(target, …)` → `makeHandleSolidWithParentWidget` (`src/HandleWdgt.coffee`
~:260) corner-attaches the handle with `@target._addNoSettle @, nil, LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_*` (~:272),
which invalidates the **resized widget `@target`**; that invalidate climbs to the world and rides the end-of-cycle flush.
The attach is **deliberately non-settling** (the `~:263-269` comment): a handle is `isLayoutInert: -> true` (~:45) overlay
chrome, so going through a public `add()` here would BOTH force a needless flush AND re-enter + throw if a builder
attaches a handle inside its own settle. The handle is also added to its holder via the PUBLIC self-settling
`world.temporaryHandlesAndLayoutAdjusters.add new HandleWdgt(…)` at the **materialize** sites (`src/basic-widgets/
Widget.coffee` ~:3044-3070, hover-materialize) — that holder-add settles fine; the survivor is the **`@target`** invalidate.

**The open question (decide by probe — the owner does NOT want this exempted):**
- **ELIMINATE candidate:** the handle is `isLayoutInert`, EXCLUDED from `@target`'s content-bounds (cf.
  `TreeNode.childrenNotHandlesNorCarets`, and the existing `_reFitContainerAfterRawGeometryChange` `return if
  @isLayoutInert?()` skip at ~:1670). If attaching inert chrome cannot change `@target`'s content layout, the `@target`
  invalidate is WASTED → skip it when the added child is `isLayoutInert` (mirroring the raw-move-side skip already in
  place). Disable-probe: no-op that invalidate, `./fg build`, `./fg suite` → byte-identical ⇒ eliminate.
- **CONVERT candidate:** if the disable-probe FAILS (a real re-fit is needed when the handle materializes), then the
  handle-MATERIALIZE call sites (the `~:3044-3070` `add`s) must self-settle around the whole materialize so the @target
  re-fit lands on return — convert the materialize, keeping `_addNoSettle` for the inner attach.

**Method:** stack-probe one resize/layout test that produces the `RectangleWdgt`/`SimpleButtonWdgt` records (§5a) to
confirm the enqueue is the `@target._addNoSettle` climb; then disable-probe to pick eliminate vs convert; resolve; verify
(§7). HONEST: the exact enqueue + the eliminate-vs-convert verdict need the fresh probes — do not assume.

### Group 2 — Residual macro-driver content-build (8 records)

**Mechanism (needs a fresh stack-probe).** `theTest_InputEvents_Macro` builds scroll-panel fixtures mid-test; some of
those `add` paths were caught by the `f4626843` guard-hoist (they went through `_positionAndResizeChildren` with
`_adjustingContentsBounds` set, so the hoisted `_reFitContainer` guard now skips them) — but these 8 reach the flush via
a **DIFFERENT add path** that does not pass through that guard. Pin which with the stack-probe.

**Reframed scope (owner).** Although tagged "macro-driver," these are NOT automatically out of scope: drive them to zero
**where the survivor traces to a PRODUCT code path** (a real `add` / container re-fit any app would also hit — the
harness merely triggers it). If the stack-probe shows a genuine product-side leak, CONVERT or ELIMINATE it like any
other; if it is purely test-harness scaffolding with no product analog, note that explicitly in the inventory.

**Method:** stack-probe each of the three ctors' tests (§5a) to pin the add path; classify per the discriminator;
resolve; verify. HONEST: the add path is unknown until probed.

### Group 3 — Divider `determineGrabs` (2 records, `macroStackDividerReproportionsCells`)

**Mechanism.** The divider DRAG already coalesces its `setMaxDim` stream via `setMaxDimCoalesced` (declared, excluded
from careless). These 2 survivors are a SEPARATE seam on the same gesture — the `ActivePointerWdgt.determineGrabs` path
(grab setup) still leaks 2.

**Method:** stack-probe `macroStackDividerReproportionsCells`, filtering for the `RectangleWdgt` records, to see what
`determineGrabs` enqueues off-settle. If it's a discrete grab-setup invalidate → convert (self-settle the grab setup) or
eliminate (if redundant); if it's actually part of the per-move drag stream → fold it into the divider's declaration
(wrap that path through `_coalescedDeclare` too). Probe decides.

### Group 4 — Caret / edit (1 record, `macroEditingStringInScrollablePanelCaretAlwaysVisible`)

**Mechanism.** A `ScrollPanelWdgt` re-fit during caret editing, surviving from `playQueuedEvents`. The bulk per-keystroke
caret path was already ELIMINATED (the `isLayoutInert` raw-move skip, inventory §5c); this is a residual on a different
edit seam.

**Method:** stack-probe the test; most likely a wasted re-fit (ELIMINATE, narrowest guard) — but confirm with the
disable-probe (byte-identical ⇒ eliminate; fails ⇒ a small convert).

### Group 5 — Irreducible (1 record, `macroStringWdgtInlineTypingRefitsUnderFittingModes`)

**Mechanism.** The documented `childRemoved` off-world-basement coalesce: a pop-up-close lost-widget re-home into the
never-painted basement scroll panel. The `childRemoved` ACTION itself was eliminated (orphan-skip at the removal seam),
but THIS test's basement is ALSO invalidated by construction-path `_addNoSettle` / raw-move / basement show/hide-filter
seams that **cannot be safely orphan-skipped** (they share the construction invalidate path — a blanket
`return if @isOrphan()` in `_invalidateLayout` broke 63 tests; see Trick T3). So it is irreducible AT THE SEAM.

**Method + disposal.** Re-confirm irreducibility with the stack-probe (does the survivor still trace to the
basement-re-home, and does any narrow guard stay byte-identical?). If irreducible, the **mandate-compliant disposal is to
DECLARE it**, not exempt it: bring the basement-re-home seam under `_coalescedDeclare` (a `*Coalesced`-style entrypoint or
an explicit declaration window at that re-home call) so the audit no longer counts it careless. **JUDGEMENT CALL — flag
for the owner:** a *construction-path* declaration is unusual (declaration windows so far wrap interaction streams, not
construction); confirm the owner wants this declared rather than left as the one documented-irreducible record. Either
way it is the LAST group — resolve groups 1-4 first.

---

## §5 — The method, per group (classify → localize → resolve → verify)

Full playbooks + worked case studies: `docs/archive/end-of-cycle-flush-drawdown-plan.md` §3–§3d (the `destroy`, single-settle,
wasted-work, and gesture-convert case studies) and §5 (copy-paste code patterns). Recap:

**(a) LOCALIZE with the stack-probe** — the only reliable localizer (the audit `sig` lies: its `shortSig` truncates to
~3 frames AND filters `eval` frames, and every in-browser-compiled Fizzygum method IS an eval frame, so it collapses to a
useless `Object.playQueuedEvents < e`). Inject a throwaway `PRELUDE_JS` on ONE test that produces the record, patching
`_invalidateLayout` to `console.log('EOC_STACK ' + new Error().stack)` UNFILTERED, gated on `!world._inLayoutMutation`
(= a genuine off-settle survivor, not an in-settle enqueue a public setter is about to drain). Mirror the install pattern
(rAF-poll until classes exist, WeakMap state, no globals) in `scripts/end-of-cycle-audit/layout-audit-prelude.js`:
```sh
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests
PRELUDE_JS=$PWD/scripts/probe.js LOG_FILE=/tmp/eoc.log node scripts/run-macro-test-headless.js SystemTest_<the-test> --dpr=1
rg -A14 EOC_STACK /tmp/eoc.log | head -50
```
The unfiltered stack names the EXACT method enqueuing off-settle. **Reason from the stack, not the tag.**

**(b) CLASSIFY** with the discriminator + the disable-probe. Ask of the pinned stack: *"is a public API mutator on it,
returning unsettled?"* → CONVERT. *Raw/internal move of a widget that can't affect what it dirties* → ELIMINATE. *Raw
event stream straight from `playQueuedEvents`* → COALESCE (declare). Decide convert-vs-eliminate EMPIRICALLY with the
**disable-probe**: no-op the deferred re-fit, `./fg build`, `./fg suite` → **byte-identical ⇒ wasted ⇒ ELIMINATE**;
**failures ⇒ load-bearing ⇒ CONVERT**. (Caveat T2/T3: a *global* disable verdict can be coarser than the real fix — a
"load-bearing" hook can still have a *specific* eliminable leak on a detached subtree; re-read the stack.)

**(c) RESOLVE:**
- **CONVERT:** wrap the discrete public mutator's body `@_settleLayoutsAfter => @_<name>NoSettle()` over a non-settling
  core; route anything it calls that self-settles (`add`/`close`/`destroy`/text setters) to that callee's `_NoSettle`
  core (cores-call-cores; the single tier THROWS otherwise). `check-layering` [A]/[G] catch most slips at build (green
  build necessary, not sufficient).
- **ELIMINATE:** stop scheduling the wasted re-fit with the NARROWEST provably-byte-identical guard (e.g. the caret
  `return if @isLayoutInert?()`, the childRemoved skip-if-detached). **Do NOT push the skip down to a shared primitive**
  without checking the construction path (T3, the 63-test lesson).
- **COALESCE / DECLARE:** wrap the stream's core through `_coalescedDeclare` behind a `*Coalesced` public entrypoint
  (pattern: `setMaxDimCoalesced`) — but FIRST measure it's worth it (`docs/tooling/coalescing-measurement.md`: max≈1 → just use
  the plain self-settling setter; max≫1 → declare). For an irreducible construction-path record (group 5), the
  declaration is the disposal even without a stream-rate argument — flag it for the owner (§4 group 5).

**(d) VERIFY** — the full §7 gate, per resolution.

---

## §6 — THE CAPSTONE: flip `auditUndeclaredEndOfCycle` from LOG to FAIL

Once §4's careless set is empty (every record converted, eliminated, or declared-coalesced), lock it in.

**What it is.** `WorldWdgt.auditUndeclaredEndOfCycle` (DEBUG, default off) already records every careless push
(`_invalidateLayout` hook → `world._undeclaredEndOfCyclePushes`) and logs them at the flush (`recalculateLayouts` →
`UNDECLARED-EOC frame=N total=M :: Ctor xK`). The capstone turns that LOG into a **FAILING gate**: a CI/test run with the
flag on that **fails if any `UNDECLARED-EOC` record appears across the whole suite** (equivalently: assert
`world._undeclaredEndOfCyclePushes` is empty at every end-of-cycle flush). That makes "nothing reaches the flush
undeclared" a regression tripwire — any NEW off-settle, attached, undeclared push fails the build/CI.

**This SUPERSEDES the old `# end-of-cycle-sanctioned` allowlist lint** (the prior endgame-plan §5 / the inventory §8
proposal). Say so explicitly in the inventory when you land it. Why the audit-fail flip wins:
- A purely-static "what reaches the flush" lint is a call-graph/dynamic question that is intractable to make exhaustive —
  the same reason `check-layering`'s transitive `*NoSettle` closure (rule [G]) was prototyped and REJECTED (name-based
  reachability balloons; it can't model the orphan guard). An allowlist-marker lint would inherit that unsoundness.
- `auditUndeclaredEndOfCycle` already computes the EXACT runtime set (off-settle ∧ attached ∧ undeclared), and the
  `_coalescedDeclare` mechanism already encodes "this one is intentional." So the gate is just "the careless set must be
  empty" — sound by construction, and it rides the existing audit harness (~1.5 min).

**Shape options (decide with evidence when you get there):** (i) a dedicated headless run with the flag on that exits
non-zero if any `UNDECLARED-EOC` line is emitted; or (ii) extend `run-all-headless.js`'s audit hook so the sharded audit
itself fails when the careless total > 0. Either is the pragmatic, sound capstone. Wire it as a build/CI step and
self-test it (plant a careless push → confirm it fails → revert; Trick T15).

---

## §7 — Verification protocol (mandatory; determinism-sensitive)

String-edit / scroll / paint / caret / handle / drag are all determinism-sensitive — do the FULL set for ANY code
change. The `fg` wrapper runs from any cwd:
1. `./fg build` — **0 violations** (runs lints [A]–[H] + dead-method + thin-wrap gates, which actively catch convert
   mistakes: a split that orphans the old public wrapper trips the dead-method gate → delete the wrapper, keep the core).
2. `./fg suite` — dpr1 **165/165** (the fast byte-identical gate). On a pixel failure, dump + look (don't recapture
   blindly): `cd /abs/Fizzygum-tests && node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1
   --dump-failures=.scratch/x`, then Read the `.png` vs the committed reference under
   `tests/SystemTest_<name>/automation-assets/**/SWCanvas/ceilPixRatio_1/`.
3. `./fg gauntlet` — dpr1/dpr2/WebKit **165/165** + **apps 12/12** (confirm the apps leg ACTUALLY ran — T7).
4. **dpr2 torture** (single-line; the gold gate for settle-timing changes):
   `cd /abs/Fizzygum-tests && node scripts/torture-headless.js --dprs=2 --speeds=fastest --shards=4 --minutes=10 --out=.scratch/torture-<name>`
   → REPORT.md clean (empty = clean).
5. **Re-audit** (`bash scripts/end-of-cycle-audit/run-audit-loop.sh`): the resolved group → 0 (or → declared), NO new
   group appeared, neutrality `installed OK: 165/165`.

**Determinism contract:** render/layout/input must be a pure function of the EVENT STREAM + final geometry — never of
wall-clock/frame-count/intermediate-pass. A green dpr1 suite is NOT sufficient for a settle-timing change; finish with
gauntlet + torture. (`Fizzygum-tests/DETERMINISM.md`.)

---

## §8 — THE TRICKS (carried forward — everything the campaign learned the hard way)

**Probing & classification**
- **T1 — The stack-probe is the only reliable localizer; the audit `sig` LIES** (eval-frame filtering). Unfiltered
  `new Error().stack`, gated `!world._inLayoutMutation`. **Reason from the stack, NOT the by-action name** — the tag
  conflated the contained-text *API* path (convert) with the *caret* path (eliminate), and tagged the childRemoved leak
  as string-edit when it was a basement re-home.
- **T2 — The disable-probe decides convert-vs-eliminate in ~10 min.** No-op the re-fit, run the suite: byte-identical →
  eliminate; tests fail → convert. But its verdict is GLOBAL — a "load-bearing" hook can still have a specific eliminable
  leak (childRemoved). Localize with T1 first.
- **T3 — Surgical eliminates: narrowest guard, byte-identical. NEVER generalize a skip to a shared primitive** —
  `return if @isOrphan()` in `_invalidateLayout` broke 63 tests (construction makes every widget an orphan;
  orphan-invalidates are load-bearing).
- **T4 — Careless → CONVERT/ELIMINATE; a genuine stream/irreducible → DECLARE-COALESCE; NEVER exempt.** (Reframed from the
  old "LEAVE must be earned": every standing LEAVE this campaign ever assigned — drop, grab, teardown, collapse,
  contained-text, childRemoved — was overturned to convert/eliminate. "LEAVE/allowlist" is not a disposal in the current
  model; the owner's mandate is zero careless. A proven stream gets a `*Coalesced` declaration, not an allowlist entry.)
- **T5 — "Convert but via batch, single is too much churn" deserves the same skepticism as a circular LEAVE.** SCOPE the
  public-wrapper / `_NoSettle`-core splits first (most cores exist); single (`_settleLayoutsAfter`, THROWS on a stray
  nested public setter) is the goal, batch (`_settleLayoutsAfterBatch`, absorbs silently) the rare fallback.

**Build / test / determinism**
- **T6 — Never chain `./fg build && ./fg suite` under a tight (≤2 min) tool timeout.** Build (~1 min) + a 5-shard suite
  (~1.3 min) exceeds it and LOOKS like a hang — a session reverted a good convert over exactly this. Confirm a real hang
  by running the suite ALONE (8 shards, <1 min) first. Build and suite in SEPARATE tool calls.
- **T7 — `./fg gauntlet` piped through `| rg | tail` can SIGPIPE-kill and silently skip the apps leg** (pipestatus
  `141 137 0`). For any window/scroll/collapse/handle-touching change, run `./fg apps` EXPLICITLY (12/12).
- **T8 — Determinism is byte-exact and dpr2-under-load-sensitive.** A green dpr1 suite is NOT enough for a settle-timing
  change: finish with `gauntlet` (dpr2/WebKit) + a dpr2 **torture** soak.
- **T9 — The stale-build guard refuses to test a build older than source** (the `⚠ STALE` canary). To diagnose a build
  without rebuilding (e.g. after reverting source to compare), `FIZZYGUM_ALLOW_STALE_BUILD=1 node …`.
- **T10 — The audit is sharded + faithful (~1.5 min) but run-to-run noisy by a few records.** "A group → 0" is the
  signal, not the exact total. Neutrality `installed OK: 165/165` is mandatory.
- **T11 — Benign inspector member-list recapture is fine** (the owner does NOT care): adding/renaming a Widget-family
  method shifts the inspector's alphabetical member list → `./fg recapture <name>`, don't contort the code. A
  chrome/text RENDER change is a real bug — distinguish by looking at the dumped `.png` pixels.
- **T12 — Changing a method's RETURN VALUE can break test MACROS that chain off it** (cost a whole session on
  sizeToText: dropping `return @` → `world.add(undefined)` → stackless `undefined.isAncestorOf`). Grep BOTH repos' `.js`
  for the method in expression/chain position; a core that's chained must end with `@`.

**Shell / hygiene**
- **T13 — The Bash tool runs FISH + a PreToolUse guard.** cwd resets between calls (always `cd /abs/... && …`
  single-line). **The guard BLOCKS a multi-line command whose first line is `cd …Fizzygum-tests` running a node
  script** — run such commands SINGLE-LINE (`cd /abs/Fizzygum-tests && node …`) or via `fg`. `for x in $VAR` does NOT
  word-split in fish (use `bash -c '…'`); macOS has no `timeout` cmd; **BSD `sed` has no `\b`** (use `s/name/_name/g` on a
  unique token + grep to verify). Kill orphan `Chrome for Testing` before a suite/audit; never the user's Chrome.
- **T14 — New plan/doc files are UNTRACKED** and silently excluded from a `git add <listed files>` commit — fold them
  into the arc's commit (`git add -A`) or commit standalone; re-confirm `git status` shows nothing `??`.
- **T15 — Self-test any new/changed gate** (plant a violation → confirm the build/CI aborts loudly → revert) — a gate
  that can't fail is worthless. Lint/gate edits under `buildSystem/*.js` are pure tooling (not compiled into the world),
  so they can't change a screenshot — suite/gauntlet only needed if you ALSO move/rename source.

---

## §9 — Workflow & recording

- **Review-driven (owner's operative middle-ground):** commit LOCALLY when an arc is fully green (gauntlet incl. apps +
  torture + re-audit); **hold the push for the owner's batch glance.** Present each arc's diff + proposed message.
  **Ask before committing/pushing.**
- Commit with `git commit -F <file>` (NEVER backticks / `$()` in `-m` — fish/bash substitutes them and silently drops
  that span). End every message: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Verify a
  multi-paragraph message with `git log -1 --format=%B`.
- Per resolution: flip the row + new total + dated banner in `docs/archive/end-of-cycle-flush-inventory.md`, and update memory
  `fizzygum-end-of-cycle-flush-drawdown` (state + remaining lines). Bundle the inventory/doc update WITH the code commit
  (it is the record OF the change) unless the owner asks to split.

---

## Appendix — anchors & companion docs (grep the symbol; numbers drift)

- **Coalescing API + audit** — `src/basic-widgets/Widget.coffee`: `setMaxDim` ~:3916 · `setMaxDimCoalesced` ~:3931 ·
  `_coalescedDeclare` ~:3941 · `_setMaxDimNoSettle` ~:3949 · the careless-audit hook in `_invalidateLayout` ~:3877 ·
  `setMinAndMaxBoundsAndSpreadability` (the construction ELIMINATE) ~:3886. `src/WorldWdgt.coffee`: `coalescingEnabled`
  ~:90 · `_coalescedDeclarationDepth` / `auditUndeclaredEndOfCycle` / `_undeclaredEndOfCyclePushes` ~:97-99 · the
  `UNDECLARED-EOC` log in `recalculateLayouts` ~:888.
- **Settle machinery** — `Widget.coffee`: `_settleLayoutsAfter` (single tier) ~:792 · `_settleLayoutsAfterBatch` (batch) ·
  `_invalidateLayout` (the FLOWRULE throw) ~:3868 · `_reFitContainer` (the `f4626843` guard-hoist) · `_reFitContainerAfter
  RawGeometryChange` (the `isLayoutInert` skip) ~:1670. `src/WorldWdgt.coffee`: `recalculateLayouts` ~:887 · end-of-cycle
  flush in `doOneCycle`.
- **Group anchors** — `src/HandleWdgt.coffee`: `makeHandleSolidWithParentWidget` ~:260 · `@target._addNoSettle` ~:272 ·
  `isLayoutInert` ~:45. `Widget.coffee` hover-materialize `world.temporaryHandlesAndLayoutAdjusters.add new HandleWdgt`
  ~:3044-3070. Tests: `macroStackDividerReproportionsCells` (divider), `macroEditingStringInScrollablePanelCaretAlways
  Visible` (caret), `macroStringWdgtInlineTypingRefitsUnderFittingModes` (irreducible).
- **Probe tooling to mirror** — `Fizzygum-tests/scripts/end-of-cycle-audit/layout-audit-prelude.js` (install pattern,
  WeakMap state) + `run-audit-loop.sh` / `aggregate-layout-audit.js`.
- **Up-to-date companion docs:**
  - `docs/archive/layout-system-architecture-assessment.md` **§2.7** — the CONCEPTS: flush model, the three faults +
    discriminator, the detection toolkit, and the coalescing model + `*Coalesced` API (canonical, post-move).
  - `docs/tooling/coalescing-measurement.md` — the measurement HARNESS + the divider-drag case study (the verdict rule).
  - `docs/archive/end-of-cycle-flush-drawdown-plan.md` — the worked PLAYBOOKS (§3–§3d), code PATTERNS (§5), VERIFICATION (§6),
    TIPS (§8), file map (§9). (§1/§2 there now point into §2.7.)
  - `docs/archive/end-of-cycle-flush-inventory.md` — the full by-action AUDIT HISTORY + verdicts.
  - Memory `fizzygum-end-of-cycle-flush-drawdown` (running state) + `fizzygum-layering-naming-tiers` (the [A]–[H] tiers).

# Plan — drive down the END-OF-CYCLE layout-flush inventory

**Status: PLAN ONLY. Written to be executed COLD by an LLM/engineer with zero prior context.** Embeds the
background, the proven `Widget.destroy` playbook, the tooling, commands, code snippets, and gotchas. Read §0 → §3
before touching code.

> **2026-06-26 — the CONCEPTS moved out; this is now the PLAYBOOK half.** The conceptual material — the
> end-of-cycle flush model, the CATEGORY rubric (the three faults + the discriminator + macro-driver/orphan/
> irreducible), the DETECTION toolkit (stack-probe / disable-probe / sharded audit / the `auditUndeclaredEndOfCycle`
> "careless" set), and the NEW **coalescing** model + the `*Coalesced` public API (`setMaxDimCoalesced`) — now live in
> **`layout-system-architecture-assessment.md` §2.7** (the canonical, current home). This doc keeps the worked
> case-study **playbooks** (§3–§3d), the **code patterns** (§5), the **verification protocol** (§6), and the
> **tips/gotchas** (§8); **§1 and §2 below are now pointers into §2.7.** For the live remaining-work TODO + current
> numbers, see **`end-of-cycle-flush-endgame-plan.md`**.

**Thesis (refined 2026-06-25):** an empty end-of-cycle queue is the ideal steady state, so each item still landing on
the per-frame flush is a *smell* — but of one of **THREE distinct faults, each with a different fix**, and naming
which one is the whole job:

1. **CONVERT** — a discrete **public API mutator that fails to self-settle** (it defers, or leans on an *unrelated*
   later event to settle for it). A public mutator must leave the world layout-consistent **on return**; one that
   doesn't is a contract breach. Fix: make it self-settle (§3b).
2. **ELIMINATE** — **wasted work**: a mutation that schedules a re-fit which *changes nothing* — a freefloating
   child's teardown re-fitting the world, or a layout-inert caret/handle re-fitting its container. Fix: stop
   scheduling it (§3, §3c).
3. **LEAVE / COALESCE** — genuinely **continuous internal machinery** (pointer hover, a drag/typing stream of raw
   moves) that no programmatic caller is awaiting; one coalesced settle/frame is the *correct* batching. *(Refined in
   the current model — `layout-system-architecture-assessment.md` §2.7: a proven stream is **COALESCE** — DECLARE it
   via a `*Coalesced` public entrypoint, e.g. `setMaxDimCoalesced`, so the audit knows the batching is intentional —
   not merely "allowlist it". The campaign capstone is the `auditUndeclaredEndOfCycle` audit-fail flip, NOT the older
   `# end-of-cycle-sanctioned` lint.)*
   **The RAREST verdict, and the hardest to earn** — every "LEAVE" this campaign assigned has so far been wrong (§2
   prior; the owner retracted them all 2026-06-25). Reach for it only with PROOF of a raw event stream, never as a
   default for something that merely looks frequent.

**The discriminator** (learned the hard way this session — §3c): pin the *actual* enqueue stack and ask **"is a public
API mutator on it, returning unsettled?"** Yes → CONVERT. No, and the enqueuing raw/internal move belongs to a widget
that *cannot affect* the container it dirties → ELIMINATE. It's the raw event stream itself → LEAVE. Reasoning from
the by-action *name* is not enough: this session both **converted** the contained-text *API* path (a real
public-mutator leak) and **eliminated** the visually-identical contained-text *caret* path (wasted raw-mover work) —
opposite fixes the action label alone would have conflated.

We first proved the ELIMINATE + CONVERT pair on the biggest contributor
(`Widget.destroy`): cutting its wasted work dropped total end-of-cycle traffic by **−55%** (1244 → 564 records) and
revealed two public methods that should have self-settled and didn't. A **second pass (this session)** made the
teardown public methods THEMSELVES self-settle (`close`/`destroy`/`fullDestroy`, like `add`), dropping the total a
further **−44%** (564 → 320) and revealing the old "230 hover" row was mostly menu-cleanup `close()`. **STATUS
2026-06-24: the 5 settle-tier "stinks" are all DONE** — `buildAndConnectChildren` + `fullDestroy`/`close`/`collapse`/
`unCollapse` now self-settle via the single-mutation `mutateGeometryThenSettle` (flush-NEUTRAL; the later 320 → 278
drop came from the deferred-layout campaign, not these flips). This plan
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

> **→ Moved to `layout-system-architecture-assessment.md` §2.7** (and §2.2 / §2.3 for the per-frame settle spine).
> The flush model, the *one-flush-per-outermost-public-mutation* invariant + the `_settleLayoutsAfter` throw that
> enforces it (and the recursion/hang it prevents), the three settle sites, the three mutation tiers, the batch +
> orphan riders, and the definition of an end-of-cycle survivor now live there as the canonical conceptual reference.
> Internalize §2.7 before touching code; the rest of THIS doc is the operational playbook that acts on it.

---

## 2. The classification rubric (per contributor)

> **→ Moved to `layout-system-architecture-assessment.md` §2.7.** The rubric — the **three faults** (CONVERT /
> ELIMINATE / COALESCE), the **discriminator** ("is a public API mutator on the actual enqueue stack, returning
> unsettled?" → CONVERT; a raw move of a widget that can't affect what it dirties → ELIMINATE; a raw event stream from
> `playQueuedEvents` → COALESCE), and the recognized non-fault categories (macro-driver / orphan-construction /
> irreducible) — is documented there.
>
> Two hard-won campaign *priors* this section used to carry, kept here because they shape every classification (and are
> echoed in the endgame plan's TRICKS):
> - **LEAVE/COALESCE is the rarest, hardest-EARNED verdict.** Every standing "LEAVE" this campaign ever assigned (drop,
>   grab, teardown, collapse, contained-text, childRemoved) was overturned to convert/eliminate. So a careless survivor
>   is convert/eliminate, and a *genuine* stream is **COALESCE** (declare it via a `*Coalesced` entrypoint) — **never
>   "exempt"/allowlist** (the owner's zero-careless mandate; see `end-of-cycle-flush-endgame-plan.md`). Earn it only with
>   PROOF of a raw event stream, never because something "looks continuous."
> - **Distrust "convert-but-via-batch, single is too much churn."** SCOPE the public-wrapper / `_<name>NoSettle`-core
>   splits before believing it — most cores already exist. Single (`_settleLayoutsAfter`, which THROWS on a stray nested
>   public setter, surfacing the cores-call-cores violation) is the goal; batch (`_settleLayoutsAfterBatch`, which
>   absorbs it silently) is the rare fallback, used only when a recipient genuinely can't be cored (an open-ended
>   dynamically-nested set) — and SAY why in a breadcrumb. (The §3d drop landed as batch first on a "the window chrome
>   rebuild can't go single" belief; scoping the 13 recipients showed 5 reroutes + 3 splits — single worked,
>   byte-identical.)

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

## 3b. The SINGLE-settle conversion playbook (the text-setter case study, 2026-06-24)

> **Settle-tier names drifted.** The current code uses **`_settleLayoutsAfter`** (the SINGLE tier — was
> `mutateGeometryThenSettle`) and **`_settleLayoutsAfterBatch`** (the BATCH tier — was `settleLayoutsOnceAfter`).
> Both self-settle; the **batch** absorbs a nested settle / defers under a pass, the **single** THROWS the
> flow-violation if reached mid-pass. Translate the §5/§7 snippets accordingly until they are refreshed.

§3 drives a contributor's WASTED work to zero. This **complementary** technique takes a public API that
self-settles via the **BATCH** tier and converts it to the **SINGLE** tier — *single by default* — so each logical
mutation flushes once, INLINE, and leaves the end-of-cycle queue entirely (an end-of-cycle survivor is by
definition a mutation that didn't self-settle, §1; a batch setter reached mid-pass DEFERS to end-of-cycle and shows
up in the inventory — single moves that flush inline). The single tier's throw-on-mid-pass *surfaces* the exact
callers that were keeping the contributor on the queue.

**The loop (this is the technique the owner asked to document):**
1. **Flip the public API to single** — `@_settleLayoutsAfterBatch =>` → `@_settleLayoutsAfter =>` (or extract a
   non-settling `_xNoSettle` core and wrap it single).
2. **Run the FULL gate and SEE WHAT BREAKS — not just the dpr1 suite.** A batch→single flip only throws when the
   setter is reached UNDER another settle / a layout pass, which the dpr1 suite may not exercise. The **app smoke**
   (`node scripts/smoke-apps-headless.js`) and teardown/`resetWorld` paths often do. The break is either a STALL
   (an uncaught throw mid-macro freezes the test → its shard hangs) or a console
   `LAYOUT_ERROR: a _reLayout() threw during recalculateLayouts: … a public geometry setter was reached during a
   layout flush/pass`.
3. **Read the STACK of the throw — it names the offending caller.** `at Object.eval [as setText] at window.X.eval
   [as _reLayout]` ⇒ `X._reLayout` (layout code) reached `setText` mid-pass. The error text *is* the rule ("internal
   layout code must use the raw/silent setters, not the public deferred API").
4. **Find every mid-pass caller** — what CALLS the now-single setter from inside a settle / a layout pass:
   a LAYOUT method (`_reLayout` / `_positionAndResizeChildren` / a per-frame `step()`); a STRUCTURAL core
   mid-build/teardown (a `_addNoSettle` re-titling a label); a NESTED public setter (one single setter calling
   another — `setFontName` re-ticking sibling menu items via `menu.label.setText`); or DYNAMIC dispatch (a
   connection's `updateTarget → @target[@action]`, an eval'd app document) — a static lint can't see these, so the
   runtime throw is the only catch.
5. **Change each mid-pass call to the NON-settling core** (`@x.setText …` → `@x._setTextNoSettle …`). The mutation
   still happens; the ENCLOSING settle (the add / teardown / frame `recalculateLayouts`) flushes it — "cores call
   cores." Byte-identical (same flush point) AND it fixes a real latent flow-violation.
6. **If a setter genuinely NESTS another settling setter** and you can't route the nested one to a core (it's a
   public API in its own right), the OUTER setter is a legitimate **batch** case — leave it batch, document why.
   `sizeToTextAndDisableFitting` stays batch for exactly this: the single setters call it (autoSize re-hug) and it
   ABSORBS under their settle.
7. **Lock it in with a lint.** Extend `buildSystem/check-layering.js` rule [A] to forbid low-level / layout code
   from calling the now-single setters (the guard that catches the violation at BUILD time, not at app-smoke
   runtime). EXCLUDE any setter you deliberately left batch (it is *allowed* to be reached mid-pass).
8. **Verify** (§6): build (incl. the new lint) → gauntlet → torture → re-audit.

**Worked result (this session):** all 7 `StringWdgt` text setters (`setText` / `setFontSize` / `setFontName` /
`toggle{ShowBlanks,Weight,Italic,IsPassword}`) went single. Mid-pass callers found + routed to `_setTextNoSettle`:
the window re-title (`WindowWdgt._addNoSettle` / `_setEmptyWindowLabelNoSettle`), `AxisWdgt._reLayout`'s tick labels,
the font-menu re-ticking, and the video per-frame time labels. `sizeToTextAndDisableFitting` stayed batch.
`check-layering [A]` now forbids low-level code calling the single text setters. Gauntlet 165/165 + torture clean.
(Two non-obvious snags that ate the most time, both surfaced by step 2: a `resetWorld` teardown HANG that was
actually a missed method-rename caller — *not* a settle issue — and an inspector test whose member-count-sensitive
scroll navigation broke when `StringWdgt` gained the `_setTextNoSettle` member; a stall that vanishes when a test
runs ALONE is almost always the PRECEDING test's teardown, so reproduce it with two tests back-to-back.)

---

## 3c. The WASTED-WORK elimination playbook + the stack probe (the caret case study, 2026-06-25)

§3 (destroy) and §3b (single-settle) both make a real mutation *settle*. This third move is the opposite: a survivor
that should neither settle nor defer because the work itself is **redundant** — the *scheduling* is the bug. Don't
convert it; delete it.

**When it applies.** A mutation dirties a container whose layout **cannot depend on** the thing that changed:
- a **freefloating** child's add/remove/resize (the `destroy` lever, §3/§5b — the world doesn't lay out freefloating
  children); or
- a **layout-inert** widget's raw move/resize — overlay chrome (`isLayoutInert`: the text caret, resize handles),
  excluded from every container's content-bounds (`TreeNode.childrenNotHandlesNorCarets`, `WindowWdgt.add`), so its
  geometry can't change the container's fit (§5c).
Re-fitting the container in these cases re-runs `_reLayout` and **changes nothing**. Tell it apart from a CONVERT by
the Thesis discriminator: no public mutator is leaking — the enqueue is a raw/internal move.

**The technique that made it diagnosable — the UNFILTERED STACK PROBE.** The audit's `sig` is useless here: its
`shortSig` truncates to 3 frames *and filters out `eval` frames* — and every in-browser-compiled Fizzygum method is
an `eval` frame — so it collapses to a misleading `Object.playQueuedEvents < e` and hides the real chain. To see the
truth, inject a throwaway probe prelude (the same `PRELUDE_JS` hook the audit uses, on ONE test:
`PRELUDE_JS=<probe> LOG_FILE=<out> node scripts/run-macro-test-headless.js <test>`) that, on the enqueue of the target
ctor, dumps `new Error().stack` UNFILTERED, **gated on `!world._inLayoutMutation`** so you log only the genuine
end-of-cycle survivors — not the enqueues a public setter is about to drain. One run names the exact line. Counting
the `_inLayoutMutation==true` enqueues *separately* is the proof that the public mutators in the flow ARE settling
correctly (so the survivor must be something else). For the caret it printed:
`_invalidateLayout ← _reFitContainer ← _reFitContainerAfterRawGeometryChange ← fullRawMoveBy ← CaretWdgt.gotoSlot ←
goRight ← insert ← processKeyDown` — no public mutator, just the caret moving itself.

**The fix shape.** Guard the *scheduling seam*, not the call sites: an early-return for the non-participating widget,
in one greppable home — `_reFitContainerAfterRawGeometryChange` does `return if @isLayoutInert?()`; the
freefloating-skip does `unless triggeringChild?.isFreeFloating()`. Verify with the full §6 gate: the removed re-fit
must be **byte-identical** (it was redundant) AND **determinism-clean** (it changed *when/whether* a settle ran).

**Result (caret, 2026-06-25):** −113 records (**253 → 140, −45%**) — bigger than the 84 caret records alone, because
the same `isLayoutInert` guard also caught the resize-**handle** move re-fits that shared the untagged hover bucket.
The mis-label warning (this was the by-action table's "prime convert candidate") and the full record:
`end-of-cycle-flush-inventory.md` §5c.

---

## 3d. The discrete-GESTURE convert via single-over-cores (the drag/drop case study, 2026-06-25)

§3b converts a public API SETTER to single; this converts a discrete GESTURE (a drop) that defers its recipient
re-fit. Distinct enough to record (and it's the template for the `reactToGrabOf` / `childRemoved` next):

**A "the other campaign deferred it" verdict is NOT a classification.** The drag/drop row sat at LEAVE because the
deferred-layout campaign deliberately made it defer — but that campaign PUSHES re-fits onto the cycle, the opposite of
the drawdown. Re-classify from scratch: a drop is a discrete re-parent gesture (§2 rule 3), a convert candidate.

**Disable-the-mechanism distinguishes convert from eliminate.** Before converting, no-op the deferred re-fit and run
its tests. The caret's (§3c) vanished byte-identically → wasted → eliminate. The drop's failed 6 tests → necessary →
convert. Same ~10-min probe, opposite verdict — run it, don't guess.

**Settle the gesture's TAIL, not the whole gesture; mind read-order.** The gesture often does `add` (public,
self-settles) THEN hooks that re-fit / change spec. Keep `add`'s settle and wrap only the TAIL (`_reactToDropOf` +
`_justDropped`) — a later hook may READ the settled geometry `add` produced (`_justDropped`'s `constrainToRatio` reads
`@width()`/`@height()`); absorbing `add`'s settle feeds it stale geometry.

**Wrap the tail in SINGLE over a bundle of NON-settling cores — resist the batch reflex.** A gesture tail dispatches to
an OPEN-ENDED set of recipient hooks (13 `_reactToDropOf` overrides here) that legitimately do structural work: rebuild
window chrome, `fullDestroy`, re-home via `add`, create-a-reference-and-`close`, recompile tiles. The lazy reflex is
`_settleLayoutsAfterBatch`, which ABSORBS those nested public self-settlers — it WORKS, but it silently tolerates a
public setter reached mid-flush. Don't settle for it: route each recipient through its NON-settling CORE
(`buildAndConnectChildren`→`_buildAndConnectChildrenNoSettle`, `fullDestroy`→`_fullDestroyNoSettle`, `add`→`_addNoSettle`),
and SPLIT any coreless recipient into the standard public-wrapper / `_xNoSettle` pair (mirrors `add`/`_addNoSettle` —
keep the public wrapper for the non-gesture callers, menus/prompts, byte-identical; only the in-gesture hook calls the
core). Then wrap the tail in SINGLE (`_settleLayoutsAfter`). `buildAndConnectChildren` is ALREADY this shape (a single
settle over 8 `_addNoSettle`s) — the precedent; "a single can't nest a multi-add builder" is FALSE, the builder just
has to call the core it already owns. Single THROWS if a future recipient sneaks in a public setter (cores-call-cores
enforced at runtime); batch hides it. (History: this landed as batch first — ce5e78b7 — when the window rebuild looked
like a single-blocker; the follow-up created the missing cores and went single.)

**Gotchas the build gates catch for free.** Deleting a recipient's last settling caller can orphan a public wrapper →
the dead-method gate flags it (delete the wrapper, keep the core, e.g. `PanelWdgt.addInPseudoRandomPosition`). A
`_xNoSettle` twin that is a sibling-closer, NOT a wrapper/core (a per-item self-settling closer vs a batch NoSettle
closer), trips the thin-wrap gate → mark the public one `# thin-wrap-exempt: <reason>`. `setExtent`→`rawSetExtent`
inside a core is byte-identical when the widget is freshly added freefloating.

**Renaming a hook private (`_`) makes lint [A] police its GEOMETRY setters** — route those to raw twins
(`setBounds`→`silentRawSetBounds`). A cores-only hook also needs EVERY caller to provide the settle: the live drop does;
a dead / homepage-excluded caller (the animated return-to-origin `slideBackTo`) gets an explicit `_settleLayoutsAfter`
wrap so the invariant holds everywhere. Full record + verification: `end-of-cycle-flush-inventory.md` §5d.

---

## 4. The audit tooling — regenerate the inventory

> *(The detection **concepts** — the sharded audit, the `auditUndeclaredEndOfCycle` "careless" set, the stack-probe
> and the disable-probe — are described in `layout-system-architecture-assessment.md` §2.7. This section is the
> operational recipe for re-running the audit.)*

The committed harness (the behaviour-neutral, inspector-invisible prelude + the SHARDED audit loop + the by-action
aggregator), the exact **build → run → aggregate → before/after-diff** recipe, the **neutrality gate** (`installed OK:
165/165`; the sharded runner `failed: 0`), and how to **attribute a new contributor** (add it to the prelude's
`tagClass(...)` block) all live in ONE place: **`end-of-cycle-audit-tooling.md`** (tooling committed at
`Fizzygum-tests/scripts/end-of-cycle-audit/`). **~1.5 min now (was ~20):** 2026-06-25 the per-test loop (one cold
browser PER test, 165 boots — the whole cost) was replaced by the suite's one-browser-per-shard model —
`run-all-headless.js` gained an opt-in `AUDIT_PRELUDE`/`AUDIT_DIR` hook that injects the prelude per shard and segments
its `LAYOUTAUDIT` stream into the same per-test logs (the prelude resets its boot/interaction boundary + emits
`LAYOUTAUDIT_TESTSTART` per test, so totals + classification match the per-test loop — cross-checked byte-for-byte). Run
it **before** starting (refresh the §7 targets) and **after each convert** (confirm the contributor shrank, no new one
appeared) — now cheap enough to run freely.

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

# (D) The public-wrapper / _xNoSettle-core SPLIT — for a PUBLIC method whose in-gesture caller (a drop/grab
#     recipient hook, running inside the gesture's single settle) needs it NON-settling, while its top-level
#     callers (menus, prompts, double-clicks) keep self-settling. Mirrors add/_addNoSettle. The wrapper stays
#     byte-identical for the top-level callers; only the hook calls the core. Inside the core, public setters
#     become their non-settling twins: structural -> _addNoSettle / _fullDestroyNoSettle / _closeNoSettle /
#     buildAndConnectChildren -> _buildAndConnectChildrenNoSettle; geometry -> rawSetExtent / silentRawSetBounds
#     (byte-identical to the deferred desired-extent path when the widget is freshly added freefloating).
somePublicAction: (args...) ->            # top-level callers — UNCHANGED behaviour
  @_settleLayoutsAfter => @_someActionNoSettle args...
_someActionNoSettle: (args...) ->         # the in-gesture recipient hook calls THIS, never the wrapper
  … the complete action via NON-settling cores only …
```

**Which tier:** content-edit / resize that the layout pass also calls → (A). A one-shot public action (menu pick,
collapse, re-parent) → (B). Removing/destroying/re-parenting a freefloating child → (C). A public method a gesture
recipient must call non-settling while menus/prompts still self-settle → split it (D). The existing seam
`_reFitContainerAfterRawGeometryChange` re-fits the container but **only if it has `_reLayoutChildren`** (scroll
panel / vertical stack / window) — it does NOT reach a button/menu that lays out a freefloating child via
`_reLayoutSelf`; for those, invalidate the parent directly as in (A).

---

## 6. Verification protocol (mandatory; determinism-sensitive)

Per convert (small, verifiable increments — NEVER convert many at once):
1. `fg build` — more than syntax now: it runs the layering lint [A–F] **and** the dead-method + thin-wrap gates, which
   actively catch convert mistakes. A split that orphans the old public wrapper (its last settling caller went
   cores-only) trips the dead-method gate → delete the wrapper, keep the core. A sibling `_xNoSettle` twin that is NOT a
   canonical wrapper/core (a self-settling-per-item closer vs a NoSettle batch closer) trips the thin-wrap gate → mark
   the public one `# thin-wrap-exempt: <reason>`. Both happened this session (§3d).
2. `fg suite` (dpr1 165/165). On a PIXEL failure, dump + look:
   `cd /abs/Fizzygum-tests && node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1 --dump-failures=.scratch/x`,
   then `Read` the obtained `.png` vs the committed reference under
   `tests/SystemTest_<name>/automation-assets/**/SWCanvas/ceilPixRatio_1/`. A real regression = the self-settle
   changed the result (the public method's effect now happens at a different time) → fix the method, don't
   recapture blindly. A *correct-but-different* result (rare) → recapture via
   `node scripts/capture-macro-test-references.js <name> --dprs=1,2` (run the FULL flow).
3. `fg gauntlet` (dpr1/dpr2/WebKit/apps).
4. **Torture soak** `--dprs=2 --speeds=fastest --shards=8 --minutes=18` — the gold gate for settle-timing changes (drop
   to `--shards=4` if 8 thrashes the box; it still rotates the cadence axes — the drop convert soaked clean at s4).
5. Re-run the audit (§4); confirm the contributor shrank and NO new contributor appeared; neutrality 165/165.

**Determinism contract:** render/layout/input must be a pure function of the event stream + final geometry — never
of timers, frame counts, or intermediate passes (`Fizzygum-tests/DETERMINISM.md`). Self-settling changes WHEN/HOW
MANY settles run per frame — exactly the risk; gauntlet+torture proves safety.

**Three considerations this session added:**
- **Probe BEFORE you convert.** The disable-the-mechanism probe (§2 rule 3, §3c) decides convert-vs-eliminate in
  ~10 min — it stops you self-settling work that should simply be deleted (the caret looked like a convert; it was an
  eliminate).
- **The FULL gate is what picks BATCH vs SINGLE.** A single self-settle that nests a multi-add builder
  (`buildAndConnectChildren`) or another public setter crashes/throws mid-build — and that surfaces only under the
  **app-smoke + window/teardown paths**, never the dpr1 suite (this session: single crashed 16 window-drop tests that
  dpr1 passed). Try single, read the crash, fall back to batch with the reason documented.
- **A fix that RENAMES an inspected method shifts the inspector's member list.** Renaming a Widget-base hook
  (`justDropped`→`_justDropped`) reorders the alphabetical list (the `_` group sorts first) → an inspector test
  recaptures benignly. Confirm by the pixels (only the member rows move), recapture, don't contort the name.

---

## 7. The current inventory (2026-06-25 audit, post GRAB-convert: **73** records / 64 frames / 14 groups; trajectory 1244 → 564 → 320 → 278 → 253 → 140 → 80 → 73)

> **⚠ STALE — this §7 snapshot is the 2026-06-25 / 73-record state, kept for the CONVERT HISTORY + trajectory only.**
> Since then the `*Coalesced` API + the `setMaxDim`/`CaretWdgt.gotoSlot`/`InspectorWdgt` converts, the
> `setMinAndMaxBoundsAndSpreadability` construction ELIMINATE, the `VerticalStackLayoutSpec` + `SimplePlainTextWdgt.set
> SoftWrap` converts, and the `f4626843` `_reFitContainer` guard-hoist ELIMINATE drove the **careless** set to
> **~18 records / 8 groups** (master `f4626843`). For the CURRENT records, verdicts, and the ordered remaining-work
> TODO use **`end-of-cycle-flush-endgame-plan.md`**; for the full by-action audit history use
> **`end-of-cycle-flush-inventory.md`**. Regenerate ground truth any time with the §4 audit recipe.

> Update (2026-06-25, later same day): the **sizeToText flip** (StringWdgt/TextWdgt `sizeToTextAndDisableFitting`, the
> last two `_settleLayoutsAfterBatch` call-sites → single-over-cores via the wrapper/core split, §8) is
> **byte-identical**, so the end-of-cycle count is unchanged — but `_settleLayoutsAfterBatch` now has **zero callers**
> (retained as an allowlisted performance primitive). Every discrete public mutation in the codebase is now
> single-tier; the batch tier is dormant-but-available. 11 benign inspector recaptures (the 2 new `_NoSettle` methods
> add a row to inspected StringWdgt/TextWdgt member lists).

**UPDATE 2026-06-25 (this arc + a tooling fix):** all 7 StringWdgt text setters now SINGLE-self-settle, so the
contained-text **API path left end-of-cycle** — the old **120-record `reLayoutAndRefreshContainerIfContainedText`
row is GONE (0)**. The surviving contained-text traffic is the **caret-editing path only** (`SimplePlainTextScroll
PanelWdgt` re-fitting per keystroke during `playQueuedEvents`, **~84 records**, rolled up under the hover row by the
shared sig) — which was then **ELIMINATED as wasted work, not converted** (§3c/§5c: the caret is `isLayoutInert`
overlay chrome whose raw move can't change container fit), dropping the total **253 → 140 (−45%)** and collapsing the
hover row 117 → 9. TOOLING: the prior audit captured 0 origins (the prelude patched
the renamed `invalidateLayout`→`_invalidateLayout`); fixed 2026-06-25, so this is the first valid post-rename audit.
Full refreshed by-action table + verdicts: `end-of-cycle-flush-inventory.md` §4. (Settle-tier renames since this
plan's §5: `mutateGeometryThenSettle`→`_settleLayoutsAfter`, `settleLayoutsOnceAfter`→`_settleLayoutsAfterBatch`.)

By-action (CONVERT HISTORY — kept for the trajectory). **⚠ SUPERSEDED for current records + verdicts by `end-of-cycle-flush-inventory.md` §4** (re-audited 2026-06-25 via the sharded loop: 73 records; ALL former "LEAVE" verdicts RETRACTED to "OPEN — re-probe" per the owner — see the §2 prior). The "likely leave" notes below are first-pass and are now OPEN.

| action / origin | recs | first-pass classification (verify with the data) |
|---|--:|---|
| **(untagged) event-dispatch residual** (genuine hover/scroll) | 19 | **OPEN — re-probe** (hypothesis: continuous hover/scroll — VERIFY, §2 prior). This row was **230**; the teardown self-settle revealed the bulk was menu-cleanup `close()` re-fitting a ScrollPanel (same `Set.forEach < playQueuedEvents` sig as hover, so mislabelled here) — now self-settled, leaving the true hover/scroll residual. |
| **contained-text edit re-fit** (API path `StringWdgt._reFitContainedTextNoSettle`; caret path via the raw seam) | **0** | **DONE** — the API path now self-settles single (§3b, 120→0); the per-keystroke CARET path was ELIMINATED-as-wasted (§3c/§5c). Contained-text no longer reaches end-of-cycle. |
| `*._reactToDropOf` (drag/DROP) | **0** (was ~62) | **CONVERTED 2026-06-25** — the drop self-settles (`ActivePointerWdgt.drop` wraps `_reactToDropOf`+`_justDropped` in ONE single settle over non-settling cores); the old "LEAVE — the campaign defers these" was circular (§3d / inventory §5d). |
| `*.reactToGrabOf` (drag/GRAB) | **0** (was 7) | **CONVERTED 2026-06-25** — the grab self-settles (`ActivePointerWdgt.grab` wraps the recipient `_reactToGrabOfNoSettle` in ONE single settle over non-settling cores); the symmetric twin of the drop (§3d / inventory §5e). Audit total 80 → 73. |
| `PanelWdgt.childRemoved` (tree removal) | 2 | **CONVERT candidate (SEPARATE from the grab)** — a child removed from a scroll panel mid string-edit re-fits the container off-settle; a different mechanism (not a grab gesture), next target. |
| `SwitchButtonWdgt.mouseClickLeft` (window collapse toggle) | 32 | discrete click → **investigate** (entangled with collapse). |
| `Widget.collapse` / `unCollapse` | **0** | **DONE 2026-06-24** — flipped to `mutateGeometryThenSettle`; gone from end-of-cycle (collapse-hook `destroy` + bar-button re-`add` use cores). |
| `Widget.destroy` / `close` / `fullDestroy` (teardown) | **0** | **CONVERTED** — even genuine non-freefloating teardown self-settles (consistent-on-return, like `add`): ALL via `mutateGeometryThenSettle` (`close`/`fullDestroy` flipped off the batching tier 2026-06-24; bulk loops `fullDestroyChildren`/`closeChildren` use cores). The earlier "LEAVE" was overridden. |
| `WindowWdgt.childCollapsed` / `childUnCollapsed` | **0** | **DONE 2026-06-24** — folded into collapse's single settle. |
| `(untagged) during-paint` (freefloating re-fit from `fullPaintInto…`) | 14 | curiosity — layout invalidation reached from the PAINT pass. Low volume; flag — **OPEN — re-probe**. |
| `(untagged) macro-driver` (test fixture-build macros) | 14 | out of scope (test construction, not product). |
| `Widget.setMaxDim` (stack-divider drag) | 4 | continuous-ish (divider drag) → **OPEN — re-probe** (is it a discrete `setMaxDim` public mutator? §2 prior). |
| **`VerticalStackLayoutSpec.setAlignment*` / `setWidthOfElementWhenAdded`** | 6 (3 actions) | **CONVERT CANDIDATE** — discrete layout-spec menu picks (the survey's textbook case); rare but clean. |
| `SimplePlainTextWdgt.setSoftWrap` | 3 | family-5 soft-wrap, left synchronous-adjacent by a prior decision → **OPEN — re-probe** that decision. |
| `Widget.newParentChoice` (re-parent menu) | 1 | discrete menu → **CONVERT CANDIDATE** (or allowlist). |

**Recommended order (biggest leverage / cleanest first; current as of the post-grab 73-record audit):**
1. ~~contained-text edit~~ **DONE** (§3b/§3c, 120→0). ~~drag/DROP~~ **DONE** (§3d). ~~GRAB~~ **DONE** (§5e, 80→73).
2. **`childRemoved` (2, string-edit path)** — a discrete tree-removal whose container re-fit defers; find the off-settle
   path and disable-probe convert-vs-eliminate (§5e). Small + clean.
3. **`SwitchButtonWdgt.mouseClickLeft` (32 — the BIGGEST residual, window-collapse)** — entangled with collapse (the
   container side is already synchronous); investigate whether the self-invalidate is a real convert or correct batching.
4. **`VerticalStackLayoutSpec` setters (2) + `newParentChoice`** — small, discrete, textbook menu-pick converts.
5. **Re-probe the rest** (hover/scroll 9, during-paint 7, `setMaxDim` 6, soft-wrap 1) — now **OPEN — re-probe**, NOT a
   presumed LEAVE set (§2 prior + inventory §4 banner). Each must be PROVEN a raw event stream before it earns an
   allowlist place; ONLY then build the "warn on un-allowlisted end-of-cycle layout" gate (§9: a `check-layering.js`
   extension with an `# end-of-cycle-sanctioned: <why>` marker, mirroring the existing `# layout-apply-sanctioned` `[F]`).

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
- **Renaming a method to `_`-private subjects it to lint [A]** (low-level code must not call public *geometry*
  setters). Route geometry calls to raw twins (`setBounds`→`silentRawSetBounds`); route STRUCTURAL calls
  (`add`/`fullDestroy`/`buildAndConnectChildren`) to their NON-settling cores too when the hook runs inside a single
  settle (the drop went single-over-cores — §3d). lint [A] polices only GEOMETRY setters, so a stray structural public
  call won't fail the BUILD — the single tier's runtime THROW catches it (which is exactly why single, not batch, is the
  goal: it surfaces the violation; batch silently absorbs it).
- **The `NoSettle` suffix marks a NON-SETTLING REGION (twin-optional), not "the core of a public/core pair"** (owner-
  decided 2026-06-25). A gesture/lifecycle recipient hook that runs INSIDE a caller-supplied settle and must not re-enter
  the flush is named `_<hook>NoSettle` even with NO public `<hook>` wrapper: `_reactToGrabOfNoSettle` (this session)
  joined `_reactToDropOfNoSettle` / `_justDroppedNoSettle` (harmonized from the drop's `_`-prefixed hooks). The thin-wrap
  gate SKIPS a twinless `*NoSettle` (`check-thin-wraps.js:57` — no public base to constrain), so none needs a `# thin-wrap-
  exempt`; check-layering's call-graph rule still enforces the core reaches no public setter. BOUNDARY (keep the signal
  strong): suffix ONLY hooks where "does this settle?" is a real question — NOT the raw/silent primitives (already named
  for their tier) nor `childRemoved`/`childAdded` (a public tree-lifecycle family). Payoff = a ratchet that LANDED as
  check-layering rule **[G]** (2026-06-25, lint-ratchet plan Phase 1): a low-level method must not call a structural
  self-settling wrapper (the `_settleLayoutsAfter` callers — destroy/close/fullDestroy/…). It is the DIRECT form only:
  the TRANSITIVE `*NoSettle` closure (runtime `FLOWRULE_VIOLATION` → build-time) was prototyped and REJECTED as
  intractable — a name-based reachability fixpoint engulfs the raw setters / `*NoSettle` cores themselves (~500–710
  false hits, because `constructor`→`buildAndConnectChildren`→`add` is a universal hub), and the `add`/`Point#add` name
  collision is unresolvable without type inference; `add` and collapse/unCollapse are therefore excluded from [G] too
  (the runtime throw stays their backstop). The formal low-level tiers (`isLowLevel` ⊃ `isImmediateMutator`) live in
  `check-layering.js`; memory [[fizzygum-layering-naming-tiers]].
- **The symmetric-twin convert: a gesture and its mirror share a shape — and the second is cheaper.** Drop and grab are
  twins (`ActivePointerWdgt.drop`/`grab`): each re-homes via a self-settling `@add`, then calls a recipient re-fit hook
  that DEFERRED. Convert by wrapping the hook in ONE `_settleLayoutsAfter` AFTER add's settle. The grab needed NO batch
  intermediate — the drop's earlier core-routing had already made every shared recipient non-settling. So when doing the
  SECOND of a twin pair, check whether the first already paid the core-routing cost (it usually has) → go straight to
  single. CAVEAT: a name-shared row in the by-action audit (here "reactToGrabOf / childRemoved") can lump DISTINCT
  mechanisms — the grab convert zeroed `reactToGrabOf` but `childRemoved` (a string-edit removal, not a grab) survived;
  split the row and verify each mechanism with the audit, don't assume the twin convert covers both.
- **macOS BSD `sed` has no `\b`** — a `s/\bname\b/_name/g` rename silently no-ops. Use plain `s/name/_name/g` for a
  unique identifier (a CamelCase neighbour like `holderWindowJustDropped` won't match lowercase `justDropped`), then
  `grep` to verify 0 un-prefixed remain.
- **Changing a method's RETURN VALUE can break test MACROS that chain off it — grep the `.js`, not just `src`** (cost
  a whole session, the sizeToText split). The wrapper/core split dropped the method's `return @` (to keep the wrapper
  a canonical thin-wrap); every `src` caller ignored the return, but ~14 macros do `s = (new StringWdgt …).sizeToText
  AndDisableFitting(); world.add s` → `world.add(undefined)` → a **stackless** `undefined.isAncestorOf` crash far from
  the change, in `_addNoSettle`. The behaviour was byte-identical the whole time — only the return value moved. FIX:
  the core ends with `@`. SUSPECT THIS the moment a "byte-identical" refactor crashes in `add`/`_addNoSettle`, and grep
  BOTH repos' `.js` for the method in EXPRESSION/chain position. (Memory: [[macro-test-relocation-gotchas]] 1b.)
- **Splitting a pattern-(A) method (reached BOTH standalone and in-pass/in-settle) into wrapper/core works iff every
  call-site is *statically* one or the other** — then no caller needs to know its context at runtime. sizeToText (the
  last batch site) split cleanly: in-pass/in-settle callers (createLabel, `_setTextNoSettle`, setFontSize) → the
  `_xNoSettle` core; standalone callers (tick-toggle, orphan header/tooltip build) → the single wrapper. **Decide the
  routing with instrumentation, not analysis:** a throwaway probe logging every *attached-mid-settle* wrapper call (and
  every *standalone* core call) reports empirically which reroute is needed — far faster and surer than reasoning out
  each caller's pass-context. The build's `stinks` gate also actively forbids `_settleLayoutsAfterBatch => @_xNoSettle`
  (a pure core wants single), so it pushes you toward the right tier.

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

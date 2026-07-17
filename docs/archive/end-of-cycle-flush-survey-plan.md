> **ARCHIVED — COMPLETE (2026-07-17 restructure).** HISTORICAL original design plan; survey executed, superseded by inventory + drawdown docs.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Survey plan — what reaches the END-OF-CYCLE layout flush, and should it?

> **⚠ HISTORICAL — this is the ORIGINAL design plan.** The survey was executed and a first conversion shipped
> (−55%). For results read `end-of-cycle-flush-inventory.md`; for the now-committed audit harness + how to run it
> read **`end-of-cycle-audit-tooling.md`** (the `scripts/.scratch/…` paths in the code samples below predate the
> promotion to `Fizzygum-tests/scripts/end-of-cycle-audit/`). Follow-on work: `end-of-cycle-flush-drawdown-plan.md`,
> `end-of-cycle-self-settle-conversion-plan.md`, `freefloating-invalidation-skip-centralization-plan.md`.

**Status: PLAN ONLY. Produces a survey/report, NOT code changes.** This document is written to be executed
**cold by an LLM with zero prior context.** It embeds all the background, exact mechanism, file:line anchors,
prior decisions, and gotchas you need. Read §0 first, then work top to bottom.

**Owner's framing (verbatim intent).** "I was really wondering what is left to do in the final end-of-cycle
flush, because for many things there *should* be a public API that attends to that. E.g. wheel-scroll
adjustments *should* be a scroll API that settles; collapse likewise. Make an inventory of those end-of-cycle
flushes, understand *why* they are not already settled and *whether they should be* (likely by exposing/using a
public self-settling API), and *ideally* reach a point where any layout still pending at end-of-cycle is a
**smell** that emits a warning. One possible approach is instrumented tests, but maybe that's not best."

**This plan's job:** design that survey rigorously and decide whether the "warn on end-of-cycle layout"
end-state is achievable (and at what definition). It does **not** perform the survey or change code.

---

## 0. Read these first (orientation)

You are in an umbrella workspace `Fizzygum-all/` holding three sibling git repos (the umbrella is NOT a repo):
`Fizzygum/` (CoffeeScript framework source — the only place behaviour is edited), `Fizzygum-tests/` (the
160-test SystemTest suite + headless harness), `Fizzygum-builds/` (generated build output — never hand-edit).

Read, in order:
1. `Fizzygum/docs/archive/deferred-layout-OVERVIEW.md` — canonical record of the layout engine + the "deferred-layout"
   campaign that produced it. **Authoritative on any conflict.**
2. `Fizzygum/docs/archive/layout-system-architecture-assessment.md` — the architectural assessment this survey extends
   (esp. its §2.2 "flush model" and §2.3 "settle engine"). Much of §2 below is condensed from it.
3. `Fizzygum-tests/DETERMINISM.md` — the byte-exact-pixel contract. **You must not perturb it** (see §6.7).
4. `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md` — build/test commands and conventions.

**Hard constraints for this work:**
- **Other sessions may be editing `Fizzygum/src` concurrently.** Do all instrumentation **without editing
  shipped framework source** — runtime monkeypatching via an injected prelude (§6) + **new** files only.
  Adding new files under `Fizzygum-tests/scripts/` does not conflict with source edits.
- **Survey, not surgery.** The output is a report + (optionally) a follow-on conversion plan. Converting code
  and adding the warning is a *separate* arc, scoped in §9 but not executed here.
- `nil` means `undefined` (a Fizzygum global). The Bash cwd resets to the umbrella between calls — always
  `cd /abs/path` and use absolute paths. There is no `timeout` in this shell — use
  `perl -e 'alarm N; exec @ARGV' …`. `pkill -9 -f "Chrome for Testing|chrome-headless|puppeteer|webkit"` before
  every headless run. **Ask before any commit/push** (review-driven project).

---

## 1. What & why, in one paragraph

Per frame, `WorldWdgt.doOneCycle` runs one engine-scheduled layout settle at its end (`recalculateLayouts()`,
`src/WorldWdgt.coffee` ~:1291). That end-of-cycle flush drains `world.widgetsThatMaybeChangedLayout` — the
global queue of widgets whose layout was invalidated during the frame but **not** settled earlier. The owner's
hypothesis is that most of what lands there represents *discrete* state changes that *should* have gone through
a **self-settling public API** (and thus settled immediately, like `setExtent`/`add` do), leaving the
end-of-cycle flush ideally empty in steady state — so a non-empty one becomes a regression *smell*. The survey
must (a) inventory what actually reaches end-of-cycle across the exercised suite, (b) attribute each item to the
code that enqueued it, (c) classify each as "should self-settle" vs "legitimately end-of-cycle," and (d) decide
whether a warning end-state is achievable and how to define it.

---

## 2. Background you must internalize before surveying

### 2.1 The three flush sites (where `recalculateLayouts()` runs)

`recalculateLayouts()` (`src/WorldWdgt.coffee` ~:856 → `_recalculateLayoutsCore` ~:869, the
`until widgetsThatMaybeChangedLayout.length == 0` drain loop ~:878) is invoked from exactly three places:

| # | Site | Cardinality | Drains |
|---|---|---|---|
| 1 | `WorldWdgt.doOneCycle` ~:1291 (**end of cycle**) | 1 / frame | **the survey's subject** |
| 2 | `Widget.mutateGeometryThenSettle` ~:783 (self-settling public setter) | 1 / public geometry mutation | drains the WHOLE queue early |
| 3 | `Widget.settleLayoutsOnceAfter` ~:808 (batch) | 1 / batch | drains the WHOLE queue early |

A drain (sites 2 or 3) empties the **entire** queue, not just the triggering widget. **Key timing fact:** a
widget's invalidation survives to the end-of-cycle flush **iff no site-2/site-3 flush runs between that
invalidation and `WorldWdgt:1291`.** So end-of-cycle survivors = invalidations that happened *after the frame's
last public-setter/batch flush* (or all of them, if none ran that frame). This is why a purely static "who calls
`invalidateLayout`" list is insufficient — survivorship depends on **runtime ordering** (§4).

### 2.2 How a widget enters the queue

`Widget.invalidateLayout` (`src/Widget.coffee` ~:3756): if currently `layoutIsValid`, push onto
`world.widgetsThatMaybeChangedLayout`, set `layoutIsValid = false`, then **climb**: call
`@parent.invalidateLayout()` unless this widget is `ATTACHEDAS_FREEFLOATING` or has no parent (~:3773). So one
invalidation typically enqueues a whole **ancestor chain**. It **throws** if reached while
`world._recalculatingLayouts` is true (~:3768) — a mid-pass invalidate is a flow-rule violation. The other
entry path is the re-fit "seam" `Widget._reFitContainer` (~:1642): its **out-of-pass arm** calls
`container.invalidateLayout()`; its **in-pass arm** pushes the container directly (legal mid-pass). The seam is
fed by `_reFitContainerAfterRawGeometryChange` (~:1619, from the raw mutators `silentRawSetExtent`/`fullRawMoveBy`),
`_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` (~:1606, from layout-spec property setters / collapse /
content-edit), the drag/drop gesture handlers (`reactToDropOf`/`reactToGrabOf`/`childRemoved`), and the
`newParentChoice*` menu actions.

### 2.3 There are THREE ways layout actually gets done — the survey is about exactly ONE

Do not conflate these:

1. **Public-API self-settle** — `setExtent`/`setWidth`/`setHeight`/`setBounds`/`fullMoveTo`/`add`/`addRaw`
   route through `mutateGeometryThenSettle`, which flushes (site 2) before returning. *Already settles; never
   reaches end-of-cycle.*
2. **End-of-cycle drain (category 2 — THE SUBJECT)** — a direct `invalidateLayout()` or an out-of-pass seam
   enqueue that no site-2/3 flush drains before `WorldWdgt:1291`.
3. **Synchronous direct apply** — raw/silent/fullRaw setters that *apply* layout immediately
   (`rawSetWidthSizeHeightAccordingly` ~:706 calls `@_reLayout()` at ~:711; `ScrollPanelWdgt.wheel` ~:737 calls
   `_positionAndResizeChildren`/`_reLayoutScrollbars` directly). *Never touches the queue; settles by applying
   on the spot.* OVERVIEW §11 calls these the TERMINAL-RAW-APPLY and SCROLL-INPUT-APPLY buckets.

> **Implication for the owner's examples.** *Collapse* is a strong category-2 candidate (a discrete button
> action that invalidates). But *wheel scroll* is largely **category 3** — it applies synchronously and is
> deliberately "leave synchronous" (OVERVIEW §5 family 1, the highest-determinism-risk path). So scroll may be a
> small or zero end-of-cycle contributor. **Treat both as hypotheses to verify, not givens** — the survey's
> first job is to find out which category each example actually falls in.

### 2.4 Prior decisions you must respect (do not "rediscover" or undo)

From `deferred-layout-OVERVIEW.md`:
- **Families 1 (scroll-input), 6 (Slider), 7 (LabelButton) are intentionally LEFT SYNCHRONOUS** (category 3).
  Family 1 especially is determinism-risky and is *not* a freefloating-child→container notification, so the
  deferred machinery doesn't apply.
- **Soft-wrap (family 5) is left synchronous** (a same-cycle caret read blocks deferral). Category 3.
- **The deferral campaign already converted** the raw-mutator seams, drag/drop, collapse-adjacent, and
  `newParentChoice*` re-fits to *defer* via `_reFitContainer` — meaning those deliberately land at end-of-cycle
  when dispatched outside a pass. **That is current intended behaviour; the survey must judge whether it is also
  the *desired* steady-state behaviour, not assume it's a bug.**
- **Path A (pending-aware accessors) is FALSIFIED** (OVERVIEW §6). The stack-proportion `wEl/wStk` fraction is
  **irreducibly load-bearing** (OVERVIEW §5). Routing `ScrollPanelWdgt.add` through `settleLayoutsOnceAfter` was
  **probed and rejected** (OVERVIEW §11 PROOF 2). Do not propose any of these.
- **Precedent for a "smell" gate already exists:** build-time lint **[F]** (`buildSystem/check-layering.js`)
  flags off-settle container applies unless they carry a conscious `# layout-apply-sanctioned: <why>` marker.
  The end-state warning (§9) should be modelled on this allowlist-with-markers philosophy.

---

## 3. The questions the survey must answer

- **Q1 — Inventory.** Across the exercised suite, what widgets are in `widgetsThatMaybeChangedLayout` at the
  moment of the end-of-cycle flush (`WorldWdgt:1291`)? Distribution of queue size per frame; which frames are
  non-empty; boot vs steady-state interaction.
- **Q2 — Attribution.** For each end-of-cycle survivor (origin, not climbed-in ancestor), which code path
  enqueued it? (method + class + the discrete-vs-continuous nature of its trigger.)
- **Q3 — Why not already settled?** For each origin class, *why* didn't it self-settle — is there no public API
  for that action, does it use raw setters by design, is it a continuous gesture, a step-function animation, a
  structural change, boot?
- **Q4 — Should it self-settle?** Apply the §8 rubric: convert to public-API/self-settling, or legitimately
  leave at end-of-cycle.
- **Q5 — The legitimate residual.** What is the (hopefully small, enumerable) set that *should* remain
  end-of-cycle? This becomes the allowlist.
- **Q6 — End-state feasibility.** Given Q5, is "warn when anything outside the allowlist reaches end-of-cycle"
  achievable, and as a runtime assert, a build lint, or both? (Answer the owner's "am I naive?" — §9.)

---

## 4. Recommended methodology — HYBRID (static catalog → runtime audit → cross-reference → classify)

Neither pure approach suffices:
- **Pure static** (enumerate `invalidateLayout` callers) gives completeness but *cannot* tell survivorship — by
  §2.1 that depends on runtime flush ordering. It would over-report (paths that always get drained early) and
  mis-rank.
- **Pure runtime** gives ground-truth survivors + frequency + attribution, but only for *exercised* paths —
  test-coverage gaps become blind spots.

So: **Phase S** (static) builds the complete catalog of *possible* enqueue origins with an a-priori
classification; **Phase R** (runtime audit) measures which actually survive to end-of-cycle, how often, and
attributes them; **Phase X** cross-references (every runtime survivor must map to a Phase-S catalog entry;
catalog entries never hit by any test are flagged for targeted exercise or manual reasoning); **Phase C**
classifies and recommends. Run phases in order; S and the Phase-R *scaffolding* can be built in parallel.

---

## 5. Phase S — static enumeration (the complete catalog of enqueue origins)

Goal: a table of every code path that can put a widget on the queue *without* an accompanying self-settle.

Commands (run from `Fizzygum/src`; lines drift — names are authoritative, re-grep):

```sh
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum/src
# 1. every direct invalidateLayout() caller
grep -rn 'invalidateLayout' . | grep -v 'invalidateLayout: ->'
# 2. every feeder of the out-of-pass seam
grep -rn '_reFitContainer\b\|_reFitContainerAfterRawGeometryChange\|_refreshScrollPanelWdgtOrVerticalStackIfIamInIt' .
# 3. the raw mutators that feed the seam (so you can trace their callers)
grep -rn 'silentRawSetExtent\|fullRawMoveBy\|fullRawMoveTo\b' .
# 4. the discrete layout-spec property setters (prime "should self-settle" suspects — see §8)
grep -rn '_refreshScrollPanelWdgtOrVerticalStackIfIamInIt' . VerticalStackLayoutSpec.coffee
# 5. collapse / adders / constraint setters
grep -rn 'invalidateLayout' . | grep -iE 'collaps|inflat|adder|setMaxDim|setMin|spreadab'
```

For each hit, classify a-priori into one of:
- **(A) inside a public self-settling setter** → self-drains; *not* a category-2 source. Exclude.
- **(B) inside a raw/silent/fullRaw mutator** → reaches end-of-cycle only when the mutator runs outside a
  site-2/3 flush (e.g. drag moves, step animations). Continuous/low-level. Note the *callers*.
- **(C) direct feature-code caller** (menu action, button handler, edit, collapse, property setter) → the prime
  "should it self-settle?" candidates. Record the triggering user/programmatic action and whether it is
  *discrete* (one-shot) or *continuous* (gesture/stream).
- **(D) construction / live-edit / factory** → typically orphan at call time (no flush; settles when added) or
  dev-only. Note but low priority.

Output: `end-of-cycle-catalog.md` — a table `origin method | class | feeds queue via | trigger | discrete? |
a-priori bucket | has public-API equivalent today?`.

---

## 6. Phase R — runtime audit (ground truth, frequency, attribution)

### 6.1 Instrumentation vector (verified — no shipped-source edits)

`Fizzygum-tests/scripts/run-macro-test-headless.js` (~:224) injects an env-pointed JS prelude into the page
**before its own scripts run**, via `page.addInitScript(PRELUDE_JS_contents + …)`, and (~:250) `LOG_FILE`
writes the **full page console** to disk for grepping. `page.onConsole` captures everything. So the audit is:
**a PRELUDE_JS file that monkeypatches the layout engine at runtime to `console.log` audit records**, captured
via `LOG_FILE`, then parsed by a new aggregation script. **Zero edits to `Fizzygum/src`; only new files.**

> Confirm before relying on it: re-read `run-macro-test-headless.js` around the `PRELUDE_JS`/`LOG_FILE`/
> `addInitScript`/`onConsole` lines, and `scripts/lib/headless-driver.js` + `scripts/macro-page-lib.js` for the
> boot/ready sequence (you need to know when classes exist — see §6.4). Check whether `run-all-headless.js`
> threads `PRELUDE_JS` to each shard; if not, drive the audit by **looping `run-macro-test-headless.js` over all
> ~160 test names** (guaranteed to support the prelude) or add a small **new** runner. Slower is fine for a
> one-off survey.

### 6.2 What each audit record captures

At the end-of-cycle flush, for each **origin** survivor (not climbed-in ancestors):
`{ frame: WorldWdgt.frameCount, qLen: queue.length, ctor: widget.constructor.name, spec: widget.layoutSpec,
   originTag, enqueueStackSig }`.
- `originTag` — set by targeted wrappers on the Phase-S category-C/B suspects (cheap, precise).
- `enqueueStackSig` — a short normalized stack signature, captured **only** for survivors lacking an
  `originTag` (the catch-all for paths Phase S missed; rare → cheap). Distinguish **origin** (immediate caller
  of `invalidateLayout` is *not* `invalidateLayout`) from **climbed** (immediate caller *is* `invalidateLayout`,
  the self-recursion at `Widget:3774`) and report origins only.

### 6.3 The patch (prelude pseudocode — adapt to real symbols)

```js
// LAYOUTAUDIT prelude — pure observation; no geometry/queue mutation; behaviour-neutral (verify §6.7).
(function installWhenReady(){
  if (!(window.Widget && window.WorldWdgt && window.world)) { /* see §6.4 for the install hook */ return retry(); }
  const W = window.Widget.prototype, WW = window.WorldWdgt.prototype;

  // (a) record the TRIGGERING enqueue per widget (only when it flips valid->invalid, i.e. the real push).
  const origInvalidate = W.invalidateLayout;
  W.invalidateLayout = function () {
    const wasValid = this.layoutIsValid;
    const inPass = window.world && window.world._recalculatingLayouts;     // these will NOT survive (throws anyway)
    if (wasValid && !inPass) {
      const e = new Error();                                               // cheap-mode: skip; see §6.8
      this.__auditEnqueue = { stackSig: normalizeStack(e.stack), tag: window.__auditTag /* set by targeted wrappers */ };
    }
    return origInvalidate.apply(this, arguments);
  };

  // (b) snapshot the queue at the END-OF-CYCLE flush, BEFORE it drains.
  const origCycle = WW.doOneCycle;
  WW.doOneCycle = function () {
    // run everything up to the end-of-cycle flush by temporarily wrapping recalculateLayouts for THIS call:
    const origRecalc = this.recalculateLayouts;
    let snapped = false;
    this.recalculateLayouts = function () {
      if (!snapped && !this._inLayoutMutation) {        // the end-of-cycle call (not a mid-frame site-2/3 flush)
        snapped = true;
        const q = this.widgetsThatMaybeChangedLayout;
        for (const wdgt of q) {
          const a = wdgt.__auditEnqueue || {};
          if (isOrigin(a.stackSig)) console.log('LAYOUTAUDIT ' + JSON.stringify(
            { frame: window.WorldWdgt.frameCount, qLen: q.length, ctor: wdgt.constructor.name,
              spec: wdgt.layoutSpec, tag: a.tag || null, sig: a.stackSig || null }));
        }
      }
      return origRecalc.apply(this, arguments);
    };
    try { return origCycle.apply(this, arguments); } finally { this.recalculateLayouts = origRecalc; }
  };
})();
```

Notes: distinguishing "the end-of-cycle recalc" from mid-frame site-2/3 flushes — the end-of-cycle call at
`WorldWdgt:1291` runs with `_inLayoutMutation === false` (site 2 sets it true around its flush; site 3 likewise
~:806), so gating on `!this._inLayoutMutation` isolates the engine call. **Verify this guard empirically**
(count how many snapshots you take per frame; it must be ≤1). Targeted `originTag`s: wrap each Phase-S
category-B/C method to set `window.__auditTag = '<Class.method>'` around its body so its invalidations are
attributed without a stack.

### 6.4 Install timing

`addInitScript` runs **before** the page's own scripts, but `Widget`/`WorldWdgt`/`world` are defined later
(compiled in-browser at boot). So the prelude must install **after** classes exist but **before** the test
driver sends commands. Options, most robust first: (i) an `Object.defineProperty(window, 'world', {set…})` trap
that patches on first assignment of the world singleton; (ii) poll via `requestAnimationFrame` until
`window.Widget && window.world`, patch once, stop (rAF is fine — it's observation *setup*, not layout, and you
verify pixel-identicality in §6.7); (iii) hook a known boot-ready function found in `macro-page-lib.js`.

### 6.5 Runner commands (dpr1 — deterministic, not load-sensitive)

```sh
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests
pkill -9 -f "Chrome for Testing|chrome-headless|puppeteer|webkit"; sleep 1
# per-test loop (guaranteed PRELUDE_JS support); collect one LOG_FILE per test:
for t in $(node scripts/lib/list-test-names.js 2>/dev/null || echo "<enumerate SystemTest_* names>"); do
  PRELUDE_JS=/abs/.scratch/layout-audit-prelude.js LOG_FILE=/abs/.scratch/audit/$t.log \
    perl -e 'alarm 180; exec @ARGV' node scripts/run-macro-test-headless.js "$t" --dpr=1
done
# then aggregate (new script):
node scripts/.scratch/aggregate-layout-audit.js /abs/.scratch/audit/   # -> end-of-cycle-runtime.json + .md
```

Also run `node scripts/smoke-apps-headless.js` with the same prelude (apps exercise paths the suite doesn't —
e.g. real menu/collapse/drag on the 12 desktop apps). The suite has **no app coverage**, so this matters.

### 6.6 Aggregation (new script `aggregate-layout-audit.js`)

Parse all `LAYOUTAUDIT ` console lines; group origins by `(ctor, spec, tag||sig)`; report: count, #tests it
appears in, which tests, per-frame qLen distribution, and **boot vs interaction** split (mark frames before the
first test-driven event as boot — get the boundary from the harness/macro start; or heuristically drop the
first K frames and confirm the tail is stable). The headline number: **how many *interaction* frames have a
non-empty end-of-cycle queue, and what origins dominate them.**

### 6.7 Determinism / safety verification (MANDATORY)

The prelude is pure observation, but prove it: run the **full suite at dpr1 with the prelude installed** and
confirm **165/165 still pass, pixel-identical** (`cd Fizzygum-tests && perl -e 'alarm 600; exec @ARGV' node
scripts/run-all-headless.js --shards=5` — if shards can't take the prelude, the per-test loop's pass/fail is
enough). If any test changes pixels, the instrumentation is *not* neutral — fix it (most likely a stray
mutation or a timing-dependent install) before trusting any data. Do the audit at **dpr1 only**; dpr2 is
load-sensitive and stack-capture perturbs load — use dpr2/torture *only* later as a secondary check that the
*classification* (not the raw counts) holds.

### 6.8 Cost control (cheap-first)

`new Error().stack` on hot `invalidateLayout` is expensive. Two passes: **R1 (cheap)** — no stack capture; rely
only on `originTag` (targeted wrappers) + `(ctor, spec)`; this answers Q1 + most of Q2 fast. **R2 (stacks)** —
only if R1 leaves unattributed survivors (origins with no tag), enable `enqueueStackSig` for the catch-all.
Most surveys won't need R2.

---

## 7. Phase X — coverage cross-reference & gap-filling

- Every Phase-R survivor origin must map to a Phase-S catalog entry. A survivor with no catalog entry means
  Phase S missed a dynamic/duck-typed path — add it.
- Catalog entries (Phase S) **never seen** in Phase R = unexercised. For each: either author/extend a macro
  test that exercises it (see `Fizzygum-tests/CLAUDE.md` + the `/author-macro-test` skill), drive it manually in
  a browser build, or reason about it from source and mark the conclusion "by inspection."
- Explicitly list the coverage gaps in the report — **silent truncation reads as "covered everything" when it
  didn't.**

---

## 8. Phase C — classification rubric & recommendations

For each end-of-cycle origin, decide with this tree:

1. **Is the trigger a CONTINUOUS / high-frequency process** (float-drag move stream, momentum scroll, a
   per-frame step-function animation)? → **LEAVE end-of-cycle.** Self-settling each event would multiply the
   per-frame settle count (assessment §2.2) for no benefit; one settle per frame is *correct* batching. Add to
   the allowlist.
2. **Is it a category-3 synchronous apply** mislabelled (scroll-input, slider, soft-wrap)? → not a category-2
   item; remove from scope. (Confirm it truly never enqueues.)
3. **Is it boot / orphan construction**? → expected; either ignore (warm-up) or ensure it uses
   `settleLayoutsOnceAfter` batching. Allowlist boot.
4. **Is it a DISCRETE one-shot state change** (collapse/uncollapse, a layout-spec property change —
   align/elasticity/base-width via `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt`, an adder toggle, a
   constraint edit, a menu "attach")? → **CANDIDATE TO CONVERT** to a public, self-settling API. Record: does a
   public method exist that it should call instead, or must one be introduced? What is the smallest change
   (wrap the action's body in `mutateGeometryThenSettle`/`settleLayoutsOnceAfter`, or route it through an
   existing public setter)?

A-priori **hypotheses to test** (NOT conclusions — the data decides):
- *Layout-spec property menu actions* (`VerticalStackLayoutSpec.setAlignmentTo*`/`setElasticity`/
  `setWidthOfElementWhenAdded`, each ending in `@element._refreshScrollPanelWdgtOrVerticalStackIfIamInIt()`) are
  the **strongest convert-to-self-settle candidates** — discrete menu picks currently relying on end-of-cycle.
- *Collapse/uncollapse* — likely a discrete candidate; but note `WindowWdgt.childUnCollapsed`'s
  `reInflating`-coupled re-fit is currently "left synchronous" (OVERVIEW §5) — check the interaction.
- *Wheel scroll* — likely category 3 (already synchronous), so probably **not** an end-of-cycle item despite the
  owner's example. Confirm and report either way.
- *Drag grab/drop re-fits* — discrete events but dispatched post-`add`; the campaign deliberately defers them.
  Decide whether "discrete but deferred-to-end-of-cycle" is acceptable or should self-settle.

Output: the inventory table + per-origin recommendation (convert / leave+allowlist / out-of-scope) + the
proposed allowlist (Q5).

---

## 9. The ideal end-state: is "warn on end-of-cycle layout" naive? (and the feasible target)

**Short answer: not naive, but "end-of-cycle must be empty" is the wrong target; "everything at end-of-cycle is
*allowlisted*" is the right one.** Reasoning to validate with the data:

- Some end-of-cycle work is **correct by design**: continuous gestures and per-frame step animations *should*
  batch to one settle per frame (self-settling each event is wasteful and inflates per-frame cost). So a literal
  "empty end-of-cycle queue" invariant is unachievable without regressing performance/determinism.
- The achievable, valuable invariant mirrors the existing **lint [F]** philosophy: **every end-of-cycle origin
  must be on a known allowlist (continuous gesture / step animation / boot); anything else is a smell and
  warns.** That turns "we converted the discrete leaks" into an *enforced, regression-proof* state.

Define the target on a spectrum; recommend which rung to aim for based on Q5's size:
- **Rung 0 (this survey):** the inventory + classification + allowlist.
- **Rung 1 (follow-on arc):** convert the clear discrete candidates (e.g. the layout-spec property actions,
  collapse) to public-API self-settling. Each conversion verified by the full gauntlet (dpr1/dpr2/WebKit suite +
  app smoke + torture soak — OVERVIEW §7).
- **Rung 2 (the warning):** add the smell gate. Two complementary forms:
  - **Runtime warning** — at `WorldWdgt:1291`, before the flush, if the queue contains an origin whose
    `originTag`/class is **not** allowlisted, `console.warn` (dev/test builds only; gated like the existing
    `# … excluded from the fizzygum homepage build` regions so `--homepage` strips it). Cheap, exercised by the
    suite. **This is essentially the Phase-R instrumentation, promoted into a permanent guarded check** — note
    that for the owner.
  - **Build lint** — extend `buildSystem/check-layering.js` with a rule that any *new* discrete-action method
    enqueuing layout (direct `invalidateLayout` / seam) must either self-settle or carry an
    `# end-of-cycle-sanctioned: <why>` marker (mirror lint [F]'s sanctioned-marker pattern). Static, no runtime,
    regression-proof.

**Honest caveats to flag for the owner:** (i) the runtime warning is only as good as test coverage — pair it
with the lint; (ii) the allowlist must be *narrow and justified* or the warning becomes noise; (iii) each Rung-1
conversion is determinism-sensitive (a discrete action that currently relies on end-of-cycle batching might,
when made to self-settle, change the *number/order* of settles in a frame — verify byte-exactness, esp. dpr2
under load). Rung 1 and Rung 2 are **out of scope for this survey** — scope them as a follow-on plan once Q5 is
known.

---

## 10. Deliverables of the survey

1. `Fizzygum/docs/archive/end-of-cycle-flush-inventory.md` — the report: Q1–Q6 answered, the inventory table
   (origin | class | feeds-via | trigger | discrete? | frequency | tests-hit | category | recommendation), the
   proposed allowlist, the coverage gaps, and the end-state recommendation (which rung, which warning form).
2. New survey tooling under `Fizzygum-tests/scripts/.scratch/` (or similar **new** dir): the audit prelude, the
   aggregation script, the per-test runner loop. Additive only.
3. (Optional) `Fizzygum/docs/archive/end-of-cycle-self-settle-conversion-plan.md` — a follow-on plan for Rungs 1–2, only
   if the survey shows it's worth it. Do **not** execute it here.

The survey changes **no shipped framework behaviour**.

---

## 11. Trust checks (does the survey's data deserve belief?)

- **Pixel-neutrality:** instrumented suite passes 165/165 at dpr1, identical to a clean run (§6.7). If not, data
  is suspect.
- **Containment:** every Phase-R survivor maps to a Phase-S catalog entry (§7). Unmapped ⇒ Phase S incomplete.
- **Snapshot sanity:** the end-of-cycle snapshot fires **≤1×/frame** (§6.3 guard). Count it.
- **Hand-verify one case:** pick one origin (e.g. a layout-spec property change), drive it in a single test with
  `PRELUDE_JS` + `LOG_FILE`, and confirm by reading source that the attribution is correct.
- **Boot excluded:** confirm the headline metric is on *interaction* frames, not warm-up.

---

## 12. Gotchas & project constraints (learned the hard way)

- **Build freshness is gated.** Every headless runner calls `assert-build-fresh.js` and refuses to run (exit 2)
  if any `src/**/*.coffee` is newer than the build stamp. If other sessions edit source mid-survey, your audit
  build goes stale — rebuild (`cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum && ./build_it_please.sh`)
  and re-run. Heed the "⚠ STALE" canary. Override only with `FIZZYGUM_ALLOW_STALE_BUILD=1` and only if you
  understand why.
- **Separate `cd` per repo** (build in `Fizzygum/`, run in `Fizzygum-tests/`); chaining them in one `&&` runs
  the node script from the wrong dir → `MODULE_NOT_FOUND`. Use absolute paths.
- **No `timeout`** in this shell → `perl -e 'alarm N; exec @ARGV' node …`. **pkill zombie browsers** before
  every run. **No backticks/`$()`** in a double-quoted `git commit -m` (the Bash tool command-substitutes them);
  anyway, **ask before committing.**
- **Never edit `Fizzygum-builds/**`** (regenerated each build). Edit only `Fizzygum/src/**/*.coffee` — and for
  THIS survey, ideally edit nothing in `src` at all (prelude + new files only).
- **`nil` is `undefined`.** **Line numbers here are approximate — `grep` the method name.**

---

## 13. Code map (verified against source; lines approximate)

- **Flush sites:** `WorldWdgt.doOneCycle` `src/WorldWdgt.coffee` ~:1266 (end-of-cycle `recalculateLayouts()`
  ~:1291; `playQueuedEvents` whole-queue drain ~:1190) · `recalculateLayouts` ~:856 / `_recalculateLayoutsCore`
  ~:869 (drain loop ~:878; non-convergence cap `100000` ~:875).
- **Self-settle / batch:** `Widget.mutateGeometryThenSettle` `src/basic-widgets/Widget.coffee` ~:748 (flush
  ~:783; `_inLayoutMutation` set ~:780; orphan guard ~:771; batch guard ~:778) · `settleLayoutsOnceAfter` ~:795
  (flush ~:808; `_inLayoutMutation` ~:806).
- **Queue entry:** `invalidateLayout` ~:3756 (mid-pass throw ~:3768; push ~:3771; climb ~:3773–3774) ·
  `_reFitContainer` ~:1642 (out-of-pass `invalidateLayout` arm; in-pass push arm) ·
  `_reFitContainerAfterRawGeometryChange` ~:1619 · `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` ~:1606.
- **Category-3 (synchronous apply — confirm they DON'T enqueue):** `rawSetWidthSizeHeightAccordingly` ~:706
  (applies `_reLayout` ~:711) · `ScrollPanelWdgt.wheel` `src/basic-widgets/ScrollPanelWdgt.coffee` ~:737.
- **Prime discrete candidates:** `VerticalStackLayoutSpec` `src/VerticalStackLayoutSpec.coffee`
  `setAlignmentToLeft/Right/Center` ~:55–68, `setElasticity` ~:80, `setWidthOfElementWhenAdded` ~:103 (all end
  in `@element._refreshScrollPanelWdgtOrVerticalStackIfIamInIt()`) · collapse/`childUnCollapsed`
  (`src/WindowWdgt.coffee`) · `showAdders`/`removeAdders` (`Widget.coffee` ~:4162/4171) · `setMaxDim`/
  `setMinAndMaxBoundsAndSpreadability` (`Widget.coffee` ~:3791/3777).
- **Continuous / step (likely legitimate residual):** float-drag moves via `fullRawMoveTo` + the seam;
  `runChildrensStepFunction` `src/WorldWdgt.coffee` ~:1288 (step animations, e.g. `BouncerWdgt`); drag/drop
  `reactToDropOf`/`reactToGrabOf`/`childRemoved` (ScrollPanelWdgt/PanelWdgt/SimpleVerticalStackPanelWdgt).
- **Harness instrumentation:** `Fizzygum-tests/scripts/run-macro-test-headless.js` (`PRELUDE_JS` →
  `page.addInitScript` ~:224; `LOG_FILE` ~:250; `page.onConsole` ~:242) · `scripts/lib/headless-driver.js` ·
  `scripts/macro-page-lib.js` · `scripts/run-all-headless.js` · `scripts/smoke-apps-headless.js` ·
  `scripts/lib/assert-build-fresh.js`.
- **Precedent for the smell gate:** `Fizzygum/buildSystem/check-layering.js` (lint [F] +
  `# layout-apply-sanctioned` markers).
```

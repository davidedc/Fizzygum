# Examination plan — settle-tier follow-ups (post orphan-settledness)

> **Self-contained / runnable cold.** Workspace root: the **umbrella** dir holding the `Fizzygum/`,
> `Fizzygum-builds/`, `Fizzygum-tests/` siblings (not itself a git repo). Edit the `Fizzygum/` sibling.
> HEAD when written: **`ce21dcf7`** (master, pushed) — the orphan-settledness Phase 1+2 commit that closes
> this campaign and is the precondition for everything below. Build/test from the umbrella via `./fg`
> (`fg build` · `fg suite [--dpr=2|--browser=webkit|--speed=normal|--shards=N]` · `fg gauntlet` · `fg apps`).

## What just shipped (the precondition)

Commit `ce21dcf7` "layout: orphans + constructors settle synchronously (orphan-settledness Phase 1+2)":
- **Engine** (`src/basic-widgets/Widget.coffee`): `_settleLayoutsAfter` now FLUSHES a not-in-flush orphan
  (was: skipped) — an in-flush orphan still defers; `_settleLayoutsAfterBatch` dropped the `isOrphan` term;
  `_collapseNoSettle`/`_unCollapseNoSettle` got the phase-valve (in-pass → no-climb `__markForRelayout`,
  off-pass → `_invalidateLayout`).
- **Sweep**: ~17 constructors → `buildAndConnectChildren` thin wrapper + `_buildAndConnectChildrenNoSettle`
  core (`@add`→`@_addNoSettle`, member `.setFontName`→`._setFontNameNoSettle`), so `new Foo()` settles ONCE
  at construction end. `WindowWdgt` trailing extent → `setExtent`. `LabelButtonWdgt.setLabel` → wrapper +
  `_setLabelNoSettle` core.
- The static gates live in `Fizzygum/buildSystem/`: **`check-layering.js`** (rules A–M, incl. [G] structural
  wrappers, [H] thin-wrap warning, [F] off-settle apply), **`check-thin-wraps.js`** (every `_<name>NoSettle`
  with a public `<name>` twin must be the canonical wrap), **`check-dead-methods.js`** (+
  `dead-method-allowlist.txt`). Runtime audits: tier-naming, notification-settle, end-of-cycle careless-push
  (capstone), paint-readonly. The `./fg gauntlet` runs the suite + tier-naming + settle gates; the capstone +
  paint gates run via `Fizzygum-tests/scripts/{end-of-cycle-audit,paint-readonly-audit}/run-*-gate.sh`.

---

## Topic 1 — ✅ RESOLVED (2026-07-01): NOT a determinism bug — a false stall-timeout

> **The suite is byte-clean at `speed=normal` too.** The "flake" was `Fizzygum-tests/scripts/run-all-headless.js`'s
> per-test stall watchdog (+ segment cap) keyed off the BETWEEN-TESTS index (`indexOfSystemTestBeingPlayed`)
> against a wall-clock threshold (`--test-stall-secs`, default 30 s): a single test that legitimately runs longer
> than 30 s at normal speed (or under multi-shard load) freezes the index and is marked "failed" — a false
> timeout, NOT a pixel divergence. `macroDemoMenuCatalogueParade` is a 60 s test (`testDuration: 60000`), so it
> ALWAYS tripped it at normal; `macroPaddingAreaIsPartOfWidget` (16 s) only under 2-shard load. **Proof:** with a
> generous watchdog the suite is **165/165 at normal, 1-shard AND 2-shard** (0 STALLED, 0 mismatches) —
> deterministic, references speed-invariant exactly as the contract says. **FIX:** the watchdog now keys off
> `WorldWdgt.frameCount` (world still cycling = progressing) and the segment cap off index-frozen time; a
> slow-but-running test isn't flagged, a true hang (cycle stops) still is. Verified 165/165 at normal with DEFAULT
> flags. (Byproduct: a benign `world.steppingWdgts` cross-test leak — carets/clocks survive `resetWorld`,
> render-guarded by `Automator.animationsPacingControl` — noted for a future cleanup.) Full write-up:
> `Fizzygum-tests/DETERMINISM.md` §2b. **The examination notes below are the (now-superseded) pre-diagnosis record.**

**The finding (this session).** The SystemTest suite is **byte-clean at `speed=fastest`** (how the suite
normally runs): `./fg gauntlet` = dpr1 + dpr2 + webkit 165/165 + apps + tier-naming + settle gates, plus the
capstone (0 careless pushes) and paint-readonly (0 paint-time schedules) gates, all green. But the
**determinism torture** (which rotates `dprs=1,2 × speeds=normal,fast,fastest × shards=2`) intermittently
flags, at the **`speed=normal` / 2-shard** config:
- `SystemTest_macroDemoMenuCatalogueParade` and `SystemTest_macroPaddingAreaIsPartOfWidget` (consistently),
- `SystemTest_macroMenuPinnedInScrollPanel` and `SystemTest_macroSoftWrapping` (seen once on baseline run 1).

**Attribution = PRE-EXISTING, not the campaign.** A controlled baseline comparison (stash `ce21dcf7`'s working
changes → build **pre-campaign HEAD `8bf7f204`** → run `node scripts/run-all-headless.js --speed=normal
--dpr=1 --shards=2`) reproduced the SAME tests flaking on **pre-campaign code** (baseline run 1 flagged
macroDemoMenuCatalogueParade + macroPaddingAreaIsPartOfWidget + 2 more, and stalled 0/2 shards). So the
campaign did NOT introduce it; it is a latent `speed=normal`/load-dependent divergence.

**Why it matters.** References are SPEED-INVARIANT by contract (the macro drives the world by the event
STREAM; speed only changes cycles-between-events). A speed-dependent divergence = some layout/render/input
code depends on frame/cycle count or wall-clock, not the event stream — the canonical Fizzygum nondeterminism
bug class. It is real even though the default `fastest` suite hides it.

**Examination approach.**
- Read `Fizzygum-tests/DETERMINISM.md` (the contract + the recurring bug-class with worked case law + the
  diagnosis playbook: deterministic heavy-cycle repro, pixel-delta forensics, disable-the-mechanism proof).
- Reproduce reliably: loop `--speed=normal --dpr=1 --shards=2` (the torture lives at
  `Fizzygum-tests/scripts/torture-headless.js`; use a FRESH `--out=DIR` so it doesn't resume a stale build's
  tallies — that footgun bit this session). The `recatch` does 40 isolated retries; these flakes did NOT
  reproduce in isolation → they need full-suite parallel load.
- The 2 stubborn tests: `macroDemoMenuCatalogueParade` = builds the WHOLE demo catalogue (construction-heavy,
  has animation/scroll signals); `macroPaddingAreaIsPartOfWidget` = 5 sliders dragged onto a RectangleWdgt
  (37 slide ops). Look for a frame-count / wall-clock dependence in menu construction-paint, slider-drag, or
  soft-wrap caret-follow under starved cycles. Evidence dir from this session:
  `Fizzygum-tests/.scratch/torture-fresh-path1/` (note: it stalled; `runs.ndjson` is the source of truth).
- Scope decision for the owner: is `speed=normal` a config we commit to keeping deterministic, or is the
  contract "the suite (fastest) is the gate, torture is a hunter"? That framing decides priority.

---

## Topic 2 — let the linter "forgive" a wrapper/core twin kept for SYMMETRY

**Concrete case (this session).** `LabelButtonWdgt.setLabel` was split into the public `setLabel` wrapper +
`_setLabelNoSettle` core so FridgeMagnets' construction could label its orphan magnets via the core. That left
the public `setLabel` with **no in-tree caller** → `check-dead-methods.js` failed → we hand-added `setLabel`
to `dead-method-allowlist.txt` (documented as intentional public API). The reverse also occurs: a live public
`<name>` whose `_<name>NoSettle` core is the only real body.

**What the owner wants.** The dead-method gate should UNDERSTAND the wrapper/core relationship: if a
`_<name>NoSettle` core is LIVE and its public `<name>` twin is dead (or vice-versa), treat the dead twin as
**intentionally retained for symmetry** rather than forcing a manual allowlist entry — "it would appreciate
that some are kept for symmetry."

**Examination approach.**
- `check-dead-methods.js` (+ the 51-entry `dead-method-allowlist.txt`) and `check-thin-wraps.js` are the
  relevant gates. thin-wraps already PAIRS `<name>` ↔ `_<name>NoSettle`; teach dead-methods the same pairing:
  a method is not "dead" if its settle-twin is live (configurable: only when the live side is the core, to
  avoid blessing genuinely-dead public API).
- Decide the policy precisely: do we keep a dead public wrapper whenever its core is live (symmetry/API), or
  only when annotated? Avoid re-blessing real dead code. Then remove the manual `setLabel` allowlist entry as
  the proof-of-concept.
- Cross-check: does any current allowlist entry exist ONLY because of this missing pairing? (overlaps Topic 5.)

---

## Topic 3 — audit: EVERY non-settling private fn should be named `*NoSettle`

**The owner's worry.** "All the private functions that don't settle should be named `*NoSettle` … many
intermediate functions might escape linking or dynamic checks if we don't do this." The risk: a privately-named
non-settling helper that is NOT recognizable as a non-settling core slips past the wrapper/core-shaped checks.

**Current naming reality (facts).** `check-layering.js` `isLowLevel(name)` = `^raw[A-Z]` OR `^_` OR
`NoSettle$`. So ALL `_`-prefixed methods ARE already low-level and ARE checked by [A]/[G]/[E]/[I] regardless of
the `NoSettle` suffix — so they do not escape the *static* call-graph rules. The non-settling private surface
today is several NAMED families, not one: `*NoSettle` cores · the immediate-mutator 2×2
(`_apply*AndNotify`/`_commit*AndNotify`/`__commit*`) + convenience movers (`_move*`/`_set*`/`_resize*`) ·
notification callbacks (`_reactTo*`/`_before*`, settle-neutral by rule [J]) · `__` leaves · plain `_` queries.

**Examination approach.**
- Enumerate `_`-prefixed methods that are NOT already in a recognized non-settling family and ask, per method:
  does it settle? If not, SHOULD it carry `NoSettle` (is it a core of a public settler), or is it genuinely a
  query/callback/immediate-mutator that has its OWN correct name? The honest answer is probably "not a blanket
  rename" — the immediate-mutators + callbacks are deliberately named otherwise — so the real deliverable is
  to CONFIRM there is no *non-settling core of a public settling wrapper* that is mis-named (those, and only
  those, must be `*NoSettle` so thin-wraps + [G] can pair them).
- Then decide whether to add a lint that FLAGS a private method which (a) is reached only as the body of a
  public settling wrapper but (b) is not named `*NoSettle` — closing the specific escape the owner fears.
- Tie-in with the dynamic audits: confirm the runtime tier-naming/settle audits key off behaviour, not the
  name, so a mis-named core is still caught at runtime (belt-and-suspenders).

---

## Topic 4 — constructor self-settling: ✅ EXECUTED (2026-06-30) — all constructors settle

> **✅ DONE (Part 2; HELD pending review/commit).** All 13 inline-building constructors converted: each calls the
> settling wrapper `@_buildAndConnectChildren()` (or `@_buildScrollFrame()` for the ScrollPanelWdgt base); building
> lives in `_buildAndConnectChildrenNoSettle`. New build gate `buildSystem/check-constructors-build.js` (wired into
> `build_it_please.sh`) forbids inline child-building in a `constructor:` body — 0 violations. GREEN: gauntlet
> dpr1/dpr2/webkit 165/165 + apps + tier + settle + capstone (0 careless) + paint (0); byte-identical, zero recaptures.
>
> **KEY FINDING — THE ARGUMENT refined (not falsified).** The "nested construction is ALREADY solved" reasoning below
> was right that the in-flush+orphan AUTO-DEFER neutralizes the runtime LEAK — but it MISSED rule **[J]**'s
> notification-settle gate, which forbids a callback from *calling* the settle tier at all (not merely from flushing).
> The window chrome buttons (Edit/External/Internal IconButtonWdgt→ButtonWdgt + SwitchButtonWdgt) are built inside
> `WindowWdgt._reactToChildDropped`, so their now-settling ctors call `_settleLayoutsAfter` there → **8 gate violations
> despite byte-identical pixels.** RESOLUTION (owner-directed "two sets"): the two sets already exist — the auto-defer's
> FLUSH (top-level) + DEFER (in-flush) branches; the ctor calls ONE wrapper that routes by context. The runtime prelude
> `Fizzygum-tests/scripts/notification-settle-audit/notification-settle-prelude.js` was refined to PERMIT an
> ORPHAN-receiver `_settleLayoutsAfter` in a callback (it provably auto-defers); an ATTACHED-receiver settle and any
> `recalculateLayouts` stay violations → the gate is now PRECISE, not weaker. ScrollPanelWdgt needed a DISTINCT
> `_buildScrollFrame` name: ListWdgt overrides `_buildAndConnectChildren` for its CONTENTS, and CoffeeScript binds a
> subclass's ctor params (`@elements`) only AFTER `super()`, so a virtual `_buildAndConnectChildren` call from the base
> ctor would read them nil. Full result: `docs/all-constructors-settle-plan.md`. **The design notes below are kept as
> the execution record.**

**DECISION (owner, this session).** Make construction self-settling **uniform + explicit + lint-enforced** —
option **(B) author-fired**, NOT engine auto-injection. Rationale: the visible wrapper matches how every other
settle in the codebase reads. The engine-auto path (meta-inject a most-derived-guarded settle via
`Class.coffee`'s compile-time ctor-rewrite — the same seam that already injects `_addInstancesTracker`'s
`this.registerThisInstance?()` before each ctor's `return`; guard with `this.constructor is <ThisClass>` so only
the most-derived ctor fires) was assessed **FEASIBLE** but **REJECTED**: its only prize over (B) is deleting the
~19 thin wrappers, bought at a ~470-class blast radius + a hidden engine-side settle trigger. (B) keeps
construction visible at near-zero risk; the lint supplies the one thing explicit-mode lacks — the can't-forget
guarantee. (So the examination's "no clean post-subclass-construct hook" worry was wrong — the meta seam exists
— but we're not using it.)

**Contract LOCKED: synchronous.** `new Foo()` returns with its own + sub-widget geometry settled (orphan
readable on the very next line) — the existing orphan-settledness contract. Deferred/microtask/at-add-only were
considered and rejected (async reintroduces the timing-nondeterminism the campaign removed; and some code reads
an orphan's geometry *before* adding it, so construct-time settle is genuinely required).

**Naming DECIDED: rename `buildAndConnectChildren` → `_buildAndConnectChildren`** (private; core name
`_buildAndConnectChildrenNoSettle` unchanged). It is internal — its only callers are constructors
(`resetToDefaultContents` goes straight to the core), so by the `_ = internal` convention it is mis-tiered as
public today (the campaign made it public only to fit the thin-wrap lint's public-`X`/private-`_XNoSettle`
shape). `_buildAndConnectChildren` pairs cleanly with the core (just drop the `NoSettle` suffix).
`_afterConstruction` was REJECTED — it breaks the pairing (forces a vague `_afterConstructionNoSettle` core) and
names *when* not *what*. End state: a `_X`(settles)/`_XNoSettle`(doesn't) pair, both private.

**Nested construction is ALREADY solved — no new mechanism.** A ctor reached inside a NoSettle method does NOT
"avoid" settling: it calls `_buildAndConnectChildren` unconditionally, and `_settleLayoutsAfter`
(`Widget.coffee:825-826`) takes the in-flush+orphan DEFER branch (`return coreThunk() if @isOrphan()`) because
the enclosing core already set `world._inLayoutMutation`. The SAME uniform wrapper FLUSHES top-level (not in a
flush) and DEFERS nested (in-flush+orphan), with zero context logic in the ctor — exactly the property that
makes the uniform convention safe. (In-flush on an ATTACHED widget THROWS; the `isOrphan()` check is what
distinguishes legit nested construction from an illegal re-entrant public setter.)

**Execution = a mini-cycle (when we reach it):**
1. *Fix usage:* sweep for ctors that build a child subtree INLINE (direct `@add`/`@_addNoSettle` of children in
   `constructor:`) without routing through the wrapper; convert them. Also the audit of whether the convention
   is universal.
2. *API:* rename `buildAndConnectChildren` → `_buildAndConnectChildren` across the ~19 (core unchanged); confirm
   the shape.
3. *Checks:* (a) generalize `check-thin-wraps.js` to accept `_X`↔`_XNoSettle` (it currently pairs only public
   `X`↔`_XNoSettle`); (b) NEW can't-forget lint — a ctor that builds children must centralize that in
   `_buildAndConnectChildrenNoSettle` and call `_buildAndConnectChildren`, never inline-add children in the ctor
   body (exact heuristic = a planning detail).

**Costs:** one-line thin-wrap lint generalization; ~1 benign inspector recapture (the rename); full gauntlet to
verify (behaviour-neutral — same wrapper, renamed). Blast radius: NONE (unlike the rejected auto path).

---

## Topic 5 — re-review ALL allowlists / sanctions / exceptions for sanitization

**Inventory (this session's audit, post-`ce21dcf7`).** Conscious-exception markers + allowlists:
- `# nosettle-sanctioned` [G]: **0** (the FridgeMagnets one was replaced by the real `_setLabelNoSettle` core).
- `# layout-apply-sanctioned` [F]: **16** (WindowWdgt 2, ScrollPanelWdgt ~10 scroll-input/content-endpoint,
  ClassInspectorWdgt 1, InspectorWdgt 1, WidgetFactory 1) — deferred-layout campaign's determinism-exempt
  families.
- `# early-return-sanctioned` [H]: **1** (CaretWdgt — a "follow pending?" predicate).
- `# thin-wrap-exempt`: **10** (WorldWdgt 3, VerticalStackLayoutSpec 5, StringWdgt 1, CaretWdgt 1).
- `dead-method-allowlist.txt`: **51 baseline + `setLabel`** (the baseline is explicitly "seeded to
  triage/delete later").
- Lint hardcoded allowlists in `check-layering.js`: `RECALC_WHITELIST` (3), `WRAPPER_EXCLUDED` (1: `add`),
  `FRAGMENT_ALLOWLIST` (3: raw-pixel). Structural, minimal.

**What the owner wants.** "We have a fairly more strict static linter and dynamic checks and we did MANY
changes so far, so I expect some of those … to be sanitizable." I.e. re-test each exemption against TODAY's
code: the thing it exempted may be gone/fixed, so the marker (or allowlist line) can be deleted.

**Examination approach.**
- The 51-entry `dead-method-allowlist.txt` is the biggest target and explicitly a triage baseline: for each
  name, `grep` the whole tree (src + `Fizzygum-tests/tests` + harness, incl. computed-name dispatch as quoted
  strings) — if a real caller now exists, delete the line; if it is truly dead and not intentional API,
  DELETE THE METHOD. (Pairs with Topic 2: some entries may be wrapper/core-symmetry, not deletable.)
- For each `# layout-apply-sanctioned` / `# thin-wrap-exempt` / `# early-return-sanctioned`: read the method,
  re-derive whether the exemption still holds. The deferred-layout campaign's [F] scroll-input family is
  likely irreducible; the construction-time / WidgetFactory ones may now be coverable by the orphan-settledness
  changes (construction now settles), so re-test those first.
- Each removal must keep `./fg gauntlet` + capstone + paint gates green; a removed exemption that re-introduces
  a violation tells you it is load-bearing — restore + document why.

---

## ⏩ RESUME HERE (cold start)

**Sequence (owner, 2026-06-30): 5+2 → 4 → [3, 1 remain].** ✅ DONE: **Topic 5 + Topic 2** (sanitized allowlist +
symmetry-aware dead-methods gate, `f35d7021`); **Topic 4 rename** (`buildAndConnectChildren` → private `_…`, `a51d9d57`);
**Topic 4 part 2** (all constructors settle — see the banner above; HELD pending review/commit). **STILL OPEN:
Topic 3** (every non-settling private fn named `*NoSettle` — the naming-coverage audit, never started) and **Topic 1**
(determinism `speed=normal`/parallel-load flake, PRE-EXISTING — the highest-rigor separate track; start by reading
`Fizzygum-tests/DETERMINISM.md` and reproducing with a FRESH torture `--out`). All gates green at `speed=fastest`.

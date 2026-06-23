# Plan — consolidate `ATTACHEDAS_FREEFLOATING` layout handling

**Status: PLAN ONLY. Written to be executed COLD by an LLM/engineer with zero prior context.** It embeds all the
background, file:line anchors, code patterns, commands, and gotchas you need. Read §0 → §3 before touching code.

**Deliverables, in THREE stages at increasing risk — keep each a SEPARATE commit; do NOT bundle the byte-identical
rename with the behavioural hot-path change:**
- **Stage 0 — `isFreeFloating()` predicate (cosmetic, byte-identical).** Introduce `Widget.isFreeFloating: -> @layoutSpec
  == LayoutSpec.ATTACHEDAS_FREEFLOATING` and replace ALL ~16 scattered inline `@layoutSpec == ATTACHEDAS_FREEFLOATING`
  / `!= …` checks with `@isFreeFloating()` / `not @isFreeFloating()` (and `child.isFreeFloating()` where a child is
  checked). One definition of the concept; greppable; self-documenting. Verify: `fg build` + `fg suite` (dpr1, 165/165).
  Zero behaviour change. **Do this FIRST** — it makes Stage 1 read cleanly and is independently mergeable.
- **Stage 1 — centralize the invalidation-skip into `invalidateLayout`'s param (behavioural; §3).** The substance of
  this plan: an optional `triggeringChild` argument, subsuming the climb-guard + the 5 teardown/move checks. Touches
  the HOT climb path → verify with the FULL gauntlet + an 18-min torture soak (§6), and re-run the end-of-cycle
  audit (it may reveal public methods that should self-settle — §5).
- **Stage 2 — (OPTIONAL, separate investigation) the setter-ownership-gate axis.** `setBounds`/`setExtent`/`setWidth`/
  `setHeight`/`fullMoveTo` gate on `… != ATTACHEDAS_FREEFLOATING` for a DIFFERENT rule ("is my geometry mine to set,
  or my parent's?"). Stage 0 makes them read `not @isFreeFloating()` (cosmetic). Whether to centralize their LOGIC
  further is its own analysis (§3.1) — note it, don't force it into this arc.

---

## 0. Cold-start orientation (workspace, build, test)

You are in an umbrella workspace `/Users/davidedellacasa/code/Fizzygum-all/` (NOT a git repo) holding three sibling
**git repos** that must stay siblings:
- **`Fizzygum/`** — the CoffeeScript GUI framework **source** (~470 `.coffee` in `src/`). The ONLY place you edit
  behaviour. It renders a windowed "web OS" on one HTML5 canvas; descends from Morphic.js.
- **`Fizzygum-tests/`** — the **SystemTest suite** (165 high-level "macro" tests) + headless harness. The tests
  drive the live world and compare canvas screenshots **pixel-by-pixel** (byte-exact SHA-256 on the SWCanvas
  software backend).
- **`Fizzygum-builds/`** — generated build output (never hand-edit).

**Conventions:** one class per file, filename == class name. `nil` means `undefined` (a global). Reference another
class just by naming it. No `require`/imports — every class is a global compiled in-browser at boot.

**Commands** (an `fg` wrapper at the umbrella root is path-correct from any cwd and is the reliable path):
- `/Users/davidedellacasa/code/Fizzygum-all/fg build` — build (runs a CoffeeScript syntax gate + a layering lint
  `[F]`; fails loudly).
- `fg suite` — full suite headless, dpr1, ~1.3 min, 165/165 expected.
- `fg gauntlet` — build + dpr1 + dpr2 + WebKit + app-smoke (the cross-engine/density regression gate).
- `fg test SystemTest_<name>` — one test headless (any cwd).
- Torture soak (determinism hunter): `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node
  scripts/torture-headless.js --dprs=2 --speeds=fastest --shards=8 --minutes=18` — loops the suite at the
  documented flake regime (dpr2·fastest·8-shard), reports to `.scratch/torture/REPORT.md`.
- Shell gotchas: the Bash cwd resets between calls — use absolute paths or the `fg` wrapper. Foreground `sleep` is
  blocked. A PreToolUse guard blocks a `cd …/Fizzygum && … node …/Fizzygum-tests/script` chain — use `fg` or a
  single-line `cd /abs/Fizzygum-tests && node …`. **Ask before committing** (review-driven project).

---

## 1. The layout engine in one page (you must internalize this)

Widgets form a tree (`TreeNode → Widget → PanelWdgt → … → WorldWdgt`, the global `window.world`). Layout is a
deferred, invalidate-then-settle engine:

- **`Widget.invalidateLayout()`** (`src/basic-widgets/Widget.coffee` ~:3749): marks the widget's layout invalid
  and pushes it onto the global queue `world.widgetsThatMaybeChangedLayout`, then **CLIMBS**: calls
  `@parent.invalidateLayout()` — **unless the widget is `ATTACHEDAS_FREEFLOATING` or has no parent** (~:3766). It
  THROWS if reached while a layout pass is running (`world._recalculatingLayouts`).
- **The settle** drains the queue: `WorldWdgt.recalculateLayouts()` (`src/WorldWdgt.coffee` ~:853) →
  `_recalculateLayoutsCore` loops `until widgetsThatMaybeChangedLayout.length == 0`, calling each dirty widget's
  `_reLayout()`.
- **Three places run the settle:** (1) **end-of-cycle**, once/frame, at `WorldWdgt.doOneCycle` ~:1288 — the
  survey's subject; (2) `Widget.mutateGeometryThenSettle` ~:748 (a public geometry setter self-settles before
  returning); (3) `Widget.settleLayoutsOnceAfter` ~:795 (batch N mutations → one settle). Sites 2 & 3 set
  `world._inLayoutMutation = true` around their flush; the end-of-cycle call does not.
- **Three tiers of mutation:**
  - **Public self-settling** — `setExtent`/`add`/… route through `mutateGeometryThenSettle` → consistent on return.
  - **Deferred** — a bare `invalidateLayout()` that no early flush drains → lands at the **end-of-cycle** flush.
  - **Raw/silent** — `silentRawSetExtent`/`fullRawMoveBy`/… mutate geometry but schedule **nothing** (used inside
    layout passes, where scheduling would re-enter and throw).

**`LayoutSpec.ATTACHEDAS_FREEFLOATING == 100000`** (`src/LayoutSpec.coffee`): a freefloating child is positioned
absolutely and is **NOT laid out by its parent** (menus, tooltips, free-dragged windows, chrome labels in
buttons). Non-freefloating children (stack elements, scroll-panel content) ARE laid out by their parent.

---

## 2. The pattern this plan is about (and why it's pervasive)

**Rule:** when a child's presence or geometry changes in a parent, the parent must re-layout — **UNLESS the child
is freefloating** (its add/remove/resize can't change the parent's layout). This rule already lives in SEVERAL
places, written out by hand each time:

| Site | Code | What it guards |
|---|---|---|
| `invalidateLayout` climb (~:3766) | `@parent.invalidateLayout() unless @layoutSpec == ATTACHEDAS_FREEFLOATING and @parent?` | a freefloating widget's own invalidation doesn't climb |
| `_addCore` NEW-container (~:2425) | `@invalidateLayout() if layoutSpec != ATTACHEDAS_FREEFLOATING` | adding a freefloating child doesn't dirty the new container |
| `_addCore` OLD-parent (~:2412) | `aWdgt.parent?.invalidateLayout() unless aWdgt.layoutSpec == FREEFLOATING` *(added in the prior arc)* | re-parenting a freefloating child away doesn't dirty the old parent |
| `destroy` (~:519) | `@parent?.invalidateLayout() unless @layoutSpec == FREEFLOATING` *(added in the prior arc)* | destroying a freefloating child doesn't dirty the parent |
| `removeFromTree` (~:2081) | `@parent?.invalidateLayout() unless @layoutSpec == FREEFLOATING` *(added in the prior arc)* | removing a freefloating child doesn't dirty the parent |

**Prior arc context (what just happened, why this plan exists):** an "end-of-cycle layout-flush survey" found that
`Widget.destroy` was the #1 contributor to the per-frame end-of-cycle flush (≈505 of ≈1244 records) — and it was
almost entirely **wasted freefloating teardown** (tooltips/menus/windows being destroyed unconditionally invalidated
their parent, usually the world, which then re-laid-out and changed nothing). Adding the freefloating-skip to
`destroy`/`removeFromTree`/`_addCore` cut that to 16 (−97%) and total end-of-cycle traffic by −55%, **with the full
gauntlet (dpr1/dpr2/WebKit/apps) staying 165/165**. See `end-of-cycle-flush-inventory.md` §5b and
`end-of-cycle-self-settle-conversion-plan.md` for the full record.

**The owner's hypothesis (this plan):** the guard is so pervasive it should be **baked into one place — an optional
`triggeringChild` parameter on `invalidateLayout` itself** (which also subsumes the existing climb-guard) — rather
than copy-pasted at every removal/move/change site — and, crucially, doing so will **surface more public API
methods that should self-settle but don't** (the prior arc found two — see §5).

---

## 3. The design — an OPTIONAL `triggeringChild` parameter on `invalidateLayout` (NO new method)

Do **not** add a new layout method. Instead pass the triggering child to `invalidateLayout` and check it once, at
the top — which also UNIFIES the existing climb-guard (the same freefloating rule, already there for the self-climb
case). `invalidateLayout` currently takes no args and has **72 no-arg call sites**, so an optional param is fully
backward-compatible.

```coffee
invalidateLayout: (triggeringChild = nil) ->
  # A freefloating child's change can't affect its parent's layout (positioned absolutely, not laid
  # out by the parent). THE single home of that rule -- the climb and every teardown/move site pass
  # the child whose change triggered this. (No child = a direct self-invalidate from feature code.)
  return if triggeringChild?.isFreeFloating()        # isFreeFloating() introduced in Stage 0
  if world?._recalculatingLayouts then throw …            # unchanged flow-rule tripwire
  if @layoutIsValid then world.widgetsThatMaybeChangedLayout.push @
  @layoutIsValid = false
  @parent?.invalidateLayout(@)        # climb: pass SELF -- short-circuited above if I'm freefloating
```

The climb `@parent?.invalidateLayout(@)` REPLACES today's `if @layoutSpec != ATTACHEDAS_FREEFLOATING and @parent?
then @parent.invalidateLayout()` (~:3766). Every other "invalidate-parent-because-a-child-changed" site becomes the
SAME shape:
- `destroy` / `removeFromTree`: `@parent?.invalidateLayout(@)` (was `@parent?.invalidateLayout() unless @layoutSpec == …`).
- `_addCore` old-parent: `previousParent?.invalidateLayout(aWdgt)` (reads `aWdgt`'s CURRENT/old spec — correct,
  since it runs BEFORE `setLayoutSpec`).
- `_addCore` new-container: `@invalidateLayout(aWdgt)` AFTER `setLayoutSpec` (so `aWdgt.layoutSpec` is the NEW spec).

**Why it's equivalent to today (a pure refactor):** the climb still pushes the widget itself, then tells its parent
"a child (me) changed", which the param short-circuits iff that child is freefloating — identical to the climb-guard.
The 3 teardown sites already ship the inline `unless … FREEFLOATING` guard; moving it into the param is byte-identical.

**Critical ordering:** the `return` goes BEFORE the `_recalculatingLayouts` throw — a freefloating teardown is a
*silent no-op* today (the `unless` guard means `invalidateLayout` isn't even called), so it must not start throwing
if it happens mid-pass.

**Staging:** (1) add the param-check + convert the 3 teardown sites — byte-identical to shipped; verify. (2) Unify
the climb (`@parent?.invalidateLayout(@)`) + the `_addCore` new-container case — equivalent; verify (this touches
the HOT climb path → gauntlet + torture, not just dpr1). (3) Then §4/§5: find OTHER unconditional parent-invalidates
that should pass a child (and thus skip for freefloating), and for each behaviour change, find the public method
that should self-settle.

**Note on the audit prelude:** it wraps `invalidateLayout` via `origInv.apply(this, arguments)`, so the new param
passes through untouched — re-run the audit (§6) unchanged.

### 3.1 SCOPE BOUNDARY — the OTHER `ATTACHEDAS_FREEFLOATING` axes this plan must NOT fold in

A full census of `ATTACHEDAS_FREEFLOATING` checks in `src` (29 usages) shows this plan's axis is exactly **5**
(climb-guard + `destroy`/`removeFromTree`/`_addCore` old & new). Three other groups check the same constant for
**different** reasons — do NOT route them through the param:

1. **Public geometry-setter OWNERSHIP gates (5)** — `setBounds` (~:819), `setExtent` (~:1549), `setWidth` (~:1673),
   `setHeight` (~:1709), `fullMoveTo` (~:1330) each `… if @layoutSpec != ATTACHEDAS_FREEFLOATING then return`. This
   is the **dual** rule — *"is my geometry mine to set, or does my parent's layout own it?"* — not *"do I dirty my
   parent."* Separate centralization candidate (a `@isFreeFloating()` helper for the 5 inline checks); out of scope
   here.
2. **The settle engine's walk-up (1)** — `WorldWdgt._recalculateLayoutsCore` (~:915) `break`s the re-layout walk-up
   AT a freefloating widget (it's a layout ROOT, laid out independently). This is the **structural DUAL** of the
   climb-skip: invalidation must not climb PAST freefloating, and re-layout must not walk PAST it. **INVARIANT: if
   you ever change the climb-skip's semantics, change this in lockstep.** This plan keeps the climb byte-identical,
   so it stays consistent — but verify the two never drift.
3. **Feature-specific checks (≈5) + defaults (≈13)** — `HandleWdgt.updateVisibility`, `InspectorWdgt.setLayoutSpec`,
   `LayoutElementAdderOrDropletWdgt`, `showResizeAndMoveHandlesAndLayoutAdjusters` (handles only on freefloating),
   `WindowWdgt.recursivelyAttachedAsFreeFloating`; and `layoutSpec = ATTACHEDAS_FREEFLOATING` as the default arg of
   every `add*`/`_addCore` + the `Widget.layoutSpec` default + `prepareToBeGrabbed`. None are layout-propagation;
   leave alone.

Re-run the census before starting: `grep -rn 'ATTACHEDAS_FREEFLOATING' src --include='*.coffee' | grep -v 'ATTACHEDAS_FREEFLOATING:'`.

---

## 4. Find every "invalidate-parent-because-child-changed" site

```sh
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum/src
# direct parent invalidations (the prime candidates to route through invalidateLayout(child))
grep -rn 'parent?\.invalidateLayout()\|parent\.invalidateLayout()\|\.parent?\.invalidateLayout' . --include='*.coffee'
# child-removal / membership hooks that may dirty the parent
grep -rn 'childRemoved\|removeChild\|reactToGrabOf\|reactToDropOf\|childBeingDestroyed\|childBeingClosed' . --include='*.coffee'
# the existing re-fit seam (already freefloating-aware via a DIFFERENT gate -- see the gotcha below)
grep -rn '_reFitContainer\b\|_reFitContainerAfterRawGeometryChange\|_refreshScrollPanelWdgtOrVerticalStackIfIamInIt' . --include='*.coffee'
```
For each hit, decide: is the parent being dirtied *because a child changed*? If yes → route through
`<parent>.invalidateLayout(child)` (pass the departed/changed child). If it's the widget dirtying ITSELF → pass
nothing / leave the self-climb to `@parent?.invalidateLayout(@)`.

**Gotcha — the existing seam is a DIFFERENT freefloating mechanism.** `_reFitContainer(container)` (~:1642) is the
"freefloating CONTENT tells its CONTAINER to re-fit" seam, used by `silentRawSetExtent`/drag. It gates on
`return unless container?._reLayoutChildren?` — i.e. it only re-fits **scroll-panel / vertical-stack / window**
containers (the three classes defining `_reLayoutChildren`). It does **NOT** reach a plain container that lays out a
freefloating child via `_reLayoutSelf` (a `LabelButton`/`MenuItem` centring its label). Do not assume the seam and
the teardown-skip are the same axis — they are complementary. (This gotcha cost real time in the prior arc.)

---

## 5. The expected fallout — public methods that should self-settle (the payoff)

When you make the freefloating-skip consistent, some code that *relied on a freefloating child's
add/remove/resize accidentally dirtying the parent* will stop getting that free re-layout. **That reliance is a
latent bug**: the public action should have self-settled in the first place. The prior arc hit exactly this twice:

1. **`TextWdgt` / `StringWdgt.sizeToTextAndDisableFitting`** (the chrome-label re-hug, called by `setText` on every
   edit) used a **silent** setter and re-fit the button **only** because the caret's `fullDestroy` on stop-editing
   happened to dirty the parent. Fix: make it self-settle —
   ```coffee
   @settleLayoutsOnceAfter =>
     … existing raw resize …
     @parent?.invalidateLayout() unless world?._recalculatingLayouts   # re-fit my managing container, gated out-of-pass
   ```
2. **`LabelButtonWdgt.setLabel`** relied on the OLD label's destroy dirtying the button. Fix: wrap in
   `mutateGeometryThenSettle` and `@invalidateLayout()` explicitly.

**The template for each fallout:** identify the public/interaction method whose visible effect depended on the
accidental dirtying; make it self-settle through the public tier (`settleLayoutsOnceAfter` for content/resize that
may run inside a pass — it flushes standalone and defers gracefully in a pass; `mutateGeometryThenSettle` for a
single discrete public mutation), invalidating the managing container **explicitly** (gated `unless
world._recalculatingLayouts` so it doesn't throw inside a layout pass). Then it's consistent-on-return and no
longer depends on teardown timing.

**Diagnosis tip (how to find the fallout fast):** instrument the suspected container's layout method to print the
inputs, run the failing test, and compare the trace with/without the skip. Worked example — a `LabelButton`
mis-centred its label; adding `console.log` of `(center, labelWidth, computedLeft)` to its `_reLayoutSelf` showed
the broken run was simply **missing** the post-resize re-centre calls that the baseline had. Also: **confirm which
CLASS actually runs the method** — `button.label` was a `TextWdgt` (MenuItem's label), not the `StringWdgt` first
patched; `grep -rn 'methodName:' --include='*.coffee'` to find all overrides before editing.

---

## 6. Verification protocol (mandatory; this is determinism-sensitive)

After EACH increment (the param-check + a batch of routed sites + any self-settle fixes):
1. `fg build` (syntax gate + layering lint must pass).
2. `fg suite` (dpr1, 165/165). If a test fails on PIXELS, dump + look:
   `cd /abs/Fizzygum-tests && node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1 --dump-failures=.scratch/x`
   then `Read` the obtained `.png` vs the committed reference under
   `tests/SystemTest_<name>/automation-assets/**/SWCanvas/ceilPixRatio_1/`. Distinguish a **real regression** (the
   self-settle fallout — fix the public method) from a benign change.
3. `fg gauntlet` (dpr1/dpr2/WebKit/apps) — the broad change must hold across engines/densities. A new
   freefloating-managing container that breaks ONLY here is the §5 fallout; fix its public method.
4. **Torture soak** (the gold gate — settle TIMING changes diverge at dpr2 under load):
   `node scripts/torture-headless.js --dprs=2 --speeds=fastest --shards=8 --minutes=18`; review
   `.scratch/torture/REPORT.md` (empty failures = clean).
5. **Re-run the end-of-cycle audit** (proves the win + that nothing new appears): tooling + recipe in
   **`end-of-cycle-audit-tooling.md`**. Stage 1 (and any §5 self-settle fixes) **changes the inventory** — expect
   the parent-invalidate-from-teardown groups to shrink, neutrality (165/165 prelude-installed) intact. **After it,
   update `end-of-cycle-flush-inventory.md` with the new numbers** (this plan is a direct continuation of that
   inventory's drawdown).

**Determinism contract (do not break it):** render/layout/input must be a pure function of the event stream + final
geometry — never of wall-clock timers, frame counts, or intermediate passes. See `Fizzygum-tests/DETERMINISM.md`.
Changing WHEN/HOW-MANY settles happen per frame is exactly the risk; the gauntlet+torture is how you prove safety.

---

## 7. Risks, scope, and rollback

- **Risk: a container that genuinely DOES read its freefloating children's geometry** (an aggregate/shrink-wrap
  container) would be under-invalidated by the skip. The prior arc's `LabelButton` was one such (it centres a
  freefloating label); the fix was to make the label's resize self-settle, not to abandon the skip. Find these via
  the gauntlet/torture; each is a §5 self-settle fix, not a reason to revert.
- **Scope control:** add the param-check + convert the already-shipped 3 teardown sites first (pure refactor,
  byte-identical), verify,
  THEN widen to newly-found sites in small batches, verifying after each. Don't convert everything at once.
- **Rollback:** every site is a one-line change; revert the `invalidateLayout(child)` call to the inline guard (or drop the guard
  entirely to restore pre-arc behaviour). `git diff`/`git checkout -- src/basic-widgets/Widget.coffee`.
- **Inspector recapture:** adding a method to `Widget` is inspector-SAFE (zero screenshot recapture). The owner does
  NOT care about benign inspector member-list recaptures — recapture and move on; never contort code to avoid one.

## 8. File:line map (lines drift — grep the name)

`src/basic-widgets/Widget.coffee`: `invalidateLayout` ~:3749 (climb-guard ~:3766) · `destroy` ~:500 (parent
invalidate ~:519) · `removeFromTree` ~:2080 · `_addCore` ~:2403 (old-parent invalidate ~:2412, new-container
~:2425) · `mutateGeometryThenSettle` ~:748 · `settleLayoutsOnceAfter` ~:795 · `_reFitContainer` ~:1642 (the
`_reLayoutChildren?` gate). `src/WorldWdgt.coffee`: `recalculateLayouts` ~:853 · end-of-cycle flush in `doOneCycle`
~:1288. `src/LayoutSpec.coffee`: `ATTACHEDAS_FREEFLOATING: 100000`. Chrome-label fallout examples:
`src/basic-widgets/TextWdgt.coffee` + `src/basic-widgets/StringWdgt.coffee` `sizeToTextAndDisableFitting` ·
`src/LabelButtonWdgt.coffee` `setLabel` + `_reLayoutSelf` (centres a freefloating label; `MenuItemWdgt extends
LabelButtonWdgt` and its label is a `TextWdgt`).

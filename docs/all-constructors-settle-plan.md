# All-constructors-settle — the bonification loop on the ~27 deferring constructors (Topic 4 part 2)

> **Self-contained / runnable cold.** Workspace root = the **umbrella** dir holding the `Fizzygum/`,
> `Fizzygum-builds/`, `Fizzygum-tests/` siblings (not itself a git repo). Edit the `Fizzygum/` sibling.
> Build/test from the umbrella via `./fg`: `fg build` · `fg suite [--dpr=2|--browser=webkit]` · `fg gauntlet`
> (build+dpr1+dpr2+webkit+apps+tier+settle) · `fg apps`. Settle-tier dynamic gates run via
> `Fizzygum-tests/scripts/{end-of-cycle-audit/run-capstone-gate.sh,paint-readonly-audit/run-paint-readonly-gate.sh}`.
> **HEAD when written: `a51d9d57`** (master, pushed). `nil` == undefined. Never hand-edit `Fizzygum-builds/`.
> Scope greps to `Fizzygum/src` (the build dir is ~1.3 GB).

## ✅ RESULT — DONE (2026-06-30), pending review/commit
**All 13 inline-building constructors converted; every constructor now settles** (calls
`@_buildAndConnectChildren()`, or `@_buildScrollFrame()` for the ScrollPanelWdgt base). No constructor
builds children inline. New build gate `buildSystem/check-constructors-build.js` (wired into
`build_it_please.sh`) forbids `@add`/`@_addNoSettle`/`@addMany` in a `constructor:` body — 0 violations.
Verified GREEN: gauntlet dpr1/dpr2/webkit 165/165 + apps + tier-naming + settle + capstone (0 careless
pushes) + paint-readonly (0 paint schedules); **byte-identical, zero recaptures.**

**Classes (13):** GenericObjectIconWdgt, GenericShortcutIconWdgt, FanoutWdgt, MenuHeader, PlotWithAxesWdgt,
PointerWdgt, SimplePlainTextPanelWdgt, StretchableWidgetContainerWdgt, SwitchButtonWdgt,
UpperRightTriangleIconicButtonWdgt, WidgetHolderWithCaptionWdgt, ButtonWdgt, ScrollPanelWdgt. The
ButtonWdgt/SwitchButtonWdgt defer-rationale comments were replaced with the auto-defer rationale.
ScrollPanelWdgt uses a DISTINCT `_buildScrollFrame` name (not the leaf `_buildAndConnectChildren`) so the
base ctor does NOT dispatch into ListWdgt's overridden contents-core during `super()` — CoffeeScript binds a
subclass's ctor params (`@elements`) only AFTER `super()`, so a virtual call there would read them nil.

**COMPLETION NOTE (2026-07-12).** The gate's original `BUILD` regex (`/@_?add…/`) could not match `@__add`
(double underscore), so FOUR constructors that built children through the `__add` structural leaf passed
invisibly: MenuWdgt, PromptWdgt, SaveShortcutPromptWdgt, SliderWdgt. When the regex was widened
(`/@_{0,2}add…/`, simplification follow-ons) they got factual `# constructor-build-exempt:` markers; the
dedicated conversion arc `docs/menu-slider-ctor-conversion-plan.md` then CONVERTED all four (byte-identical,
zero recaptures) — exemption count is back to ZERO. MenuWdgt mirrors the ScrollPanelWdgt precedent with its
own distinct pair (`_buildMenuLabel`/`_buildMenuLabelNoSettle`) because its prompt subclasses build children.

### THE ARGUMENT — refined (the one real obstacle + its resolution)
THE ARGUMENT (below) was right that the in-flush+orphan AUTO-DEFER neutralizes the old "a settle leaks into a
settle-neutral callback" fear — **at runtime**. But it MISSED a second, independent constraint: **rule [J]'s
notification-settle gate forbids a callback from CALLING the settle tier at all** (not just from flushing).
The window chrome buttons (EditIconButtonWdgt/ExternalIconButtonWdgt/InternalIconButtonWdgt → ButtonWdgt,
and SwitchButtonWdgt) are built inside `WindowWdgt._reactToChildDropped`, so their now-settling ctors call
`_settleLayoutsAfter` there → 8 gate violations (byte-identical pixels, but a [J] breach).

**RESOLUTION (owner-directed "two sets"):** the two sets already exist — the auto-defer's FLUSH branch
(top-level) and DEFER branch (in-flush). The constructor calls ONE wrapper that routes by context; the gate
just couldn't SEE the distinction. Refined the runtime prelude
`Fizzygum-tests/scripts/notification-settle-audit/notification-settle-prelude.js` to PERMIT an
ORPHAN-receiver `_settleLayoutsAfter` in a callback (it provably auto-defers — the gate's old "would
re-enter/throw" premise is false for orphans); an ATTACHED-receiver settle and any `recalculateLayouts` stay
violations. The gate is now PRECISE, not weaker; no per-construction suppression boolean (the rejected
alternative). THE ARGUMENT thus holds once the gate matches the runtime contract.

## Lineage (what shipped, in order — all on master, pushed)
- **`ce21dcf7`** — orphan-settledness Phase 1+2: `new Foo()` settles synchronously. Introduced the `_settleLayoutsAfter`
  engine + the `buildAndConnectChildren` wrapper / `_buildAndConnectChildrenNoSettle` core pattern, and **the
  in-flush+orphan AUTO-DEFER** (the linchpin of the argument below).
- **`f35d7021`** — settle-tier follow-ups Topics 2+5 (symmetry-aware dead-methods gate; deleted 40 dead methods).
- **`a51d9d57`** — **Topic 4 rename (THIS plan's precondition):** `buildAndConnectChildren` → `_buildAndConnectChildren`
  (private) across all 22 classes; reduced the 3 core-less builders (ListWdgt via the `@contents._addNoSettle`
  redirect; ToolTipWdgt via `_destroyNoSettle`/`_addNoSettle`/`_sizeToTextAndDisableFittingNoSettle`;
  ClassInspectorWdgt overrides the `_buildAndConnectChildrenNoSettle` CORE via `_setTextNoSettle`). `check-thin-wraps.js`
  now pairs a core with a private `_<name>` twin too. Byte-identical (gauntlet dpr1/dpr2/webkit + apps + tier + settle
  + capstone + paint, **zero recaptures**). So **every construction builder is now a uniform private thin-wrapper-over-core.**

## The activity
Make **ALL constructors settle.** ~27 constructors today build children **INLINE** (`@_addNoSettle …` then
`@_invalidateLayout()` — deliberately NOT settling; "defer-to-attach"). Drive each through the bonification loop so it
becomes the uniform pattern: **the ctor calls `@_buildAndConnectChildren()`** (the settling wrapper) and its child-building
lives in `_buildAndConnectChildrenNoSettle`. End state = **ONE contract: every constructor calls the wrapper; the
settle-tier decides flush (top-level) vs defer (in-flush).** No inline-build exceptions. Then add the **can't-forget lint**
(forbid `@add`/`@_addNoSettle` building directly in a `constructor:` body) to lock it in.

This is the genuine "first-class construction" end-state — NOT the cosmetic rename (already shipped). The owner pushed for
it explicitly: *"why can't we just say all constructors must settle?"*, against past attempts that failed for lack of the
full fix-usage→api→impl→lint→dynamic-check loop.

## ⭐ THE ARGUMENT — why this is possible NOW, though it was effectively impossible before

The ~27 deferring ctors state ONE reason. Verbatim, from **ButtonWdgt.coffee** (constructor):
> *"A constructor builds an ORPHAN, so add the face through the NON-settling core: the public @add self-settles, and a
> settle in a constructor leaks into ANY callback that builds a button — e.g. WindowWdgt._reactToChildDropped's chrome
> rebuild (_buildAndConnectChildrenNoSettle -> new \*IconButtonWdgt), which must stay settle-neutral. The layout is
> scheduled (deferred, below) and applied when the button is later attached and its parent settles."*

**Why that reason no longer bites — the orphan-settledness AUTO-DEFER.** Find `_settleLayoutsAfter:` in
`src/basic-widgets/Widget.coffee` (~line 800; line may have shifted with the Topic-5 deletions — match by content):
```coffee
if world._inLayoutMutation or world._recalculatingLayouts
  return coreThunk() if @isOrphan()    # in-flush + orphan → DEFER (run the core, do NOT flush)
  throw new Error "...public geometry setter reached during a layout flush..."   # in-flush + ATTACHED → flow violation
```
A constructor that calls the settling wrapper `@_buildAndConnectChildren()`, when invoked **inside a callback** — which
runs **in-flush** (`world._inLayoutMutation` true; layering rule **[J]**: the gesture/structural dispatcher owns the one
`_settleLayoutsAfter`, so callbacks like `_reactTo*` are settle-neutral) — builds an ORPHAN → hits `return coreThunk()` →
**auto-defers.** It does NOT leak a settle into the callback. So calling the wrapper gives:
- **top-level** `new Foo()` (not in-flush) → flushes → settles its orphan layout;
- **in-flush** (inside a callback) → auto-defers → settles when attached.

That is the **same outcome** as today's manual `@_addNoSettle + @_invalidateLayout` for the callback case. The manual
deferral is **largely redundant** with the auto-defer — it only additionally suppresses the (harmless, if orphan-safe)
top-level orphan settle.

**Why it was impossible / kept failing before — and the TWO things that changed:**
1. **The auto-defer did not exist** before orphan-settledness (`ce21dcf7`). Without it, a settling constructor invoked in
   a callback would actually FLUSH → a settle during a settle-neutral callback → a real flow violation → reverted. **The
   ButtonWdgt comment's fear was TRUE then. It is false now.**
2. **Past attempts flipped USAGE before fixing the IMPLEMENTATION.** Flipping a ctor to settle without first making its
   `_reLayout` orphan-safe → the top-level orphan settle reads a parent that isn't there → crash (the campaign hit exactly
   this on `SimpleDocumentWdgt`/`DegreesConverterApp` reading `nil.parent`) → reverted. The cure is the bonification-loop
   DISCIPLINE: **fix impl (orphan-safe layout) FIRST, then flip usage, then lint** — which past attempts skipped.

**Proof the method works now — ListWdgt (this session).** ListWdgt was declared **IRREDUCIBLE** in the orphan-settledness
campaign (its `@add`→`@_addNoSettle` broke ~19 InspectorWdgt property-pane tests, was reverted, and a code comment
enshrined "needs no conversion"). THIS session it reduced **byte-identical in ~20 min** — because we fixed the impl path
FIRST (the custom ScrollPanel `add` redirect's non-settling twin is `@contents._addNoSettle` with the explicit
`ATTACHEDAS_FREEFLOATING` layoutSpec the public redirect passes — NOT the base `@_addNoSettle` the campaign had tried),
THEN flipped usage. Same loop, same tooling, applies to the 27.

**Conclusion:** deferral was never a fundamental exception. It reduces to ONE prerequisite — **the top-level orphan settle
must be VALID (orphan-safe `_reLayout`)** — which is a per-widget implementation fix, and **the suite crashes instantly
when it isn't met, so it's self-checking.** The tooling that makes this tractable (the auto-defer; the `_…NoSettle` cores;
the layering/thin-wrap/settle/paint gates) only exists now.

## The per-widget loop (apply to each of the ~27, incrementally)
1. **impl** — ensure the widget's `_reLayout`/layout is **orphan-safe** (won't crash settling as a parentless orphan).
   The suite is the oracle: flip, run `./fg suite`, fix any `nil.parent`-style crash before moving on.
2. **usage** — move the inline `@_addNoSettle …` (and any trailing `@_invalidateLayout()`) OUT of `constructor:` and into
   `_buildAndConnectChildrenNoSettle`; the ctor calls `@_buildAndConnectChildren()`. If the class has no wrapper yet, add
   the canonical one: `_buildAndConnectChildren: -> @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()`.
3. **api** — nothing to add: the auto-defer handles in-flush, the flush handles top-level.
4. **check** — `./fg suite` per widget (byte-identical = success). After ALL are converted, write the **can't-forget lint**
   (new `buildSystem/check-*.js`, mirror `check-thin-wraps.js`/`check-dead-methods.js`): a `constructor:` body must not
   contain `@add`/`@_addNoSettle`/`@addMany` child-building — it belongs in `_buildAndConnectChildrenNoSettle`. Should be
   0 violations once the 27 are converted; wire it into `build_it_please.sh`.

**Work ONE at a time and verify each like ListWdgt.** Do NOT flip all 27 then test — you won't know which broke. Batch
commits by a few converted widgets; gauntlet before each commit.

## The work-list (REGENERATE precise line numbers — the prior audit used cumulative NR, so its line numbers were wrong)
Re-run with `FNR` for correct per-file lines and the FULL set (the prior run was `head`-truncated at ~40 lines):
```bash
cd Fizzygum && awk '
  /^  [A-Za-z_][A-Za-z0-9_]*:/ { inctor = ($0 ~ /^  constructor:/) }
  inctor && /@_?add(Many)?(NoSettle)?[ (]/ && !/buildAndConnectChildren/ { print FILENAME":"FNR":  "$0 }
' $(rg -l "" src -g "*.coffee")
```
Files seen in the (truncated) audit, ~27 sites: `SimplePlainTextPanelWdgt`, `WidgetHolderWithCaptionWdgt` (×2),
`SwitchButtonWdgt`, `ButtonWdgt`, `graphs-plots-charts/PlotWithAxesWdgt` (plot/vertAxis/horizAxis),
`basic-widgets/PointerWdgt` (×3 lmContent), `patch-programming/FanoutWdgt` (×4 pins), `StretchableWidgetContainerWdgt`,
`basic-widgets/ScrollPanelWdgt` (contents/hBar/vBar), `basic-widgets/menu-system/MenuHeader`,
`icons/GenericShortcutIconWdgt` (×2), `buttons/UpperRightTriangleIconicButtonWdgt`, `icons/GenericObjectIconWdgt` (×2),
**+ the tail was cut off — regenerate for the complete list.**

**Classify each BEFORE flipping:**
- (a) Does it already settle at the end, or genuinely defer (`@_invalidateLayout()` as the last layout act)? Both convert
  the same way; the deferring ones are the ones whose contract actually changes.
- (b) Is it a **BASE class with many subclasses** (`ScrollPanelWdgt` — large blast radius; flip carefully and run the full
  `./fg gauntlet`, not just `suite`) or a leaf?
- (c) Does its layout read parent context (the orphan-safety risk)?

## Honest caveats — where it could still bite (so we don't repeat the past failure)
- **Orphan-safety is per-widget and real.** Some `_reLayout`s WILL crash settling as an orphan (the campaign fixed
  several). Each is a small impl fix, but **verify — don't assume.** The suite catches it instantly.
- **Confirm the callback path is genuinely in-flush.** The auto-defer only fires if `world._inLayoutMutation` is true when
  the button is built. Rule [J] says callbacks run inside the dispatcher's `_settleLayoutsAfter`, so they should be — but
  verify by flipping ONE button (e.g. `ButtonWdgt`) and watching the **capstone + paint gates**, which catch a leaked
  settle (a careless-push / paint-time schedule), not just a screenshot diff. A pure screenshot diff = a layout change; a
  gate failure = a real settle leak.
- **A ctor may have a SECOND reason to defer** beyond the callback fear (e.g. genuine intrinsic-layout-needs-parent). The
  byte-identical suite is the arbiter — if flipping changes a screenshot, understand WHY before forcing it.
- **Micro-perf:** a top-level-built-then-immediately-attached widget settles once extra (orphan layout, re-settled on
  attach). Negligible (common case is in-flush → auto-defer), but note it if a heavy-rebuild test slows.

## Verify / gate commands
- Per widget (fast inner loop): `./fg suite` (dpr1, ~1 min; byte-identical = success).
- Full: `./fg gauntlet` (build + dpr1 + dpr2 + webkit + apps + tier-naming + settle).
- **The gates that catch a settle LEAK (the real risk here):**
  `cd Fizzygum-tests && bash scripts/end-of-cycle-audit/run-capstone-gate.sh && bash scripts/paint-readonly-audit/run-paint-readonly-gate.sh`
- Commit/push only after an end-of-arc review (review-driven project; never commit autonomously).

## Key references
- **Auto-defer:** `_settleLayoutsAfter:` in `src/basic-widgets/Widget.coffee` (~800) — branch `return coreThunk() if @isOrphan()`.
- **Canonical wrapper/core template:** `src/SpeechBubbleWdgt.coffee` (`_buildAndConnectChildren` → `_buildAndConnectChildrenNoSettle`).
- **This-session reduction templates (the loop, worked):** `src/ListWdgt.coffee` (custom-add redirect), `src/ToolTipWdgt.coffee`
  (NoSettle cores), `src/meta/ClassInspectorWdgt.coffee` (core override).
- **Deferral rationale being retired:** `src/ButtonWdgt.coffee` + `src/SwitchButtonWdgt.coffee` constructors.
- **Lints:** `buildSystem/check-layering.js` (rules [A]/[G]/[J]; [G] discovers settling wrappers structurally),
  `buildSystem/check-thin-wraps.js` (now pairs public `<name>` OR private `_<name>` with `_<name>NoSettle`).
- Plans this descends from: `docs/orphan-settledness-plan.md`, `docs/settle-tier-followups-examination-plan.md` (§Topic 4 banked design).

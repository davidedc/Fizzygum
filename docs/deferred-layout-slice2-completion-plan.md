# Deferred-layout migration — state after Phase 3b + next steps

**Self-contained. Last updated 2026-06-20. Read top-to-bottom and you can continue cold.**
Companion / design-of-record: `deferred-layout-refit-and-add-design.md` (the phase map + rationale).
Determinism contract: `Fizzygum-tests/DETERMINISM.md`. Originating case: `softwrap-deferred-layout-conversion-plan.md`.

---

## 0. TL;DR

The deferred-layout migration moves geometry/structural mutation onto a **self-settling public API** and the
content re-fit onto the **`recalculateLayouts`/`doLayout` cycle**. **Everything through Phase 3b is DONE and
pushed to master.** The capstone (Phase 3b Slice 2 — stack/window re-fit on the cycle) shipped, briefly froze
9/12 desktop apps, and was fixed by a clean architectural rule — **a low-level geometry mutator (`raw*`/`silent*`/
`fullRaw*`) must only MUTATE geometry, never SCHEDULE a (re-)layout.** That rule is now migrated, runtime-guarded,
and build-time-lint-enforced. The remaining work is small follow-ups (Section 7), recommended next = **#18**.

---

## 1. What's SHIPPED (all on master)

| Phase | What | Fizzygum commit | tests commit |
|---|---|---|---|
| self-settling public geometry API | `setExtent`/`setWidth`/`setHeight`/`setBounds`/`fullMoveTo` self-flush via `mutateGeometryThenSettle` | `817c2ce4` | `a256ccfe6` |
| Step 1 | macros stop calling scroll-panel re-fit methods | (in 817c2ce4 era) | `271511906` |
| Phase 1 / 2 | design pass; `_reFitToContents` chokepoint + privatize re-fit machinery to `_`; lint rules A/B/C/D | `ad2000cc` | `48cb05fd9` |
| Phase 3a | `add`/`addRaw` public + self-settling over private `_addCore`; `isOrphan()` flush-skip | `b8165920` | `585b295d3` |
| Phase 3b Slice 1 | `ScrollPanelWdgt.doLayout` (+ `implementsDeferredLayout: -> false`); silent content sizing → fixed point | `00cea256` | — |
| Phase 3b Slice 2 | `SimpleVerticalStackPanelWdgt`/`WindowWdgt` get `doLayout` + `implementsDeferredLayout: -> false` (re-fit on the cycle) | `6c7060e5` | `46a0acd0f` (1 benign inspector recapture) |
| **Slice 2 app-freeze FIX** | the flow rule — removed `@invalidateLayout()` from all raw setters | **`c45113ac`** | — |
| **flow-rule lint + cleanup** | `check-layering.js` rule [E]; deleted 6 vestigial `rawSetExtent: -> super` overrides | **`b89c9141`** | — |

**Phase 3b is COMPLETE.** Net effect: top-level callers (macros, apps, event handlers) never call a layout/re-fit
method; a public mutation leaves a consistent world by itself; scroll/stack/window content re-fit runs on the cycle.

---

## 2. The FLOW RULE (the load-bearing principle — Phase 3b Slice 2's real fix)

**A low-level immediate geometry mutator (`raw*` / `silent*` / `fullRaw*`) must only MUTATE geometry, never
SCHEDULE a (re-)layout** (`invalidateLayout`, and by extension the re-fit triggers `childGeometryChanged` /
`_reFitToContents` / `recalculateLayouts` / public setters). Three tiers:

| Tier | Methods | Job | May schedule layout? |
|---|---|---|---|
| **Public** | `setExtent`/`setWidth`/`setHeight`/`setBounds`/`fullMoveTo`/`add`/`addRaw` | record `@desired*` → `invalidateLayout` → flush (`recalculateLayouts`) | **YES — only here** |
| **Layout machinery** | `doLayout` / `_adjustContentsBounds` / `recalculateLayouts` | APPLY a computed layout, using tier-3 primitives | no |
| **Low-level** | `raw*` / `silent*` / `fullRaw*` | mutate geometry NOW, quietly | **NO** |

**Why it matters (the bug it prevents):** the layout machinery (tier 2) applies a child's geometry via raw setters
(tier 3). If a raw setter ALSO schedules layout (tier 1 `invalidateLayout`), the child's invalidate **climbs back**
to re-dirty the container **during the container's own `doLayout`**, so `recalculateLayouts`'s until-loop never
converges → freeze. That is exactly what hung 9/12 desktop apps after Slice 2 (e.g. `DashboardsApp.windowOpened →
createNextTo → add`: a freefloating `SimpleVerticalStackPanelWdgt` inside a `SimpleDocumentScrollPanelWdgt`, queue
grew unbounded). The owner's framing: *`rawSetExtent` is used to FIX a layout, so it must not also BREAK one.*

### 2a. The migration (commit `c45113ac`) — what changed in the source
Removed `@invalidateLayout()` from every raw setter that had it (~17 sites, all verified by the lint):
- **6 `rawSetExtent` overrides** were just `super; @invalidateLayout()` — deleted entirely in `b89c9141`
  (`SimpleLinkWdgt`, `ToolPanelWdgt`, `ColorPickerWdgt`, `FanoutWdgt`, `AxisWdgt`, `PlotWithAxesWdgt`); calls now
  go straight to the base `rawSetExtent`.
- **`rawResizeToWithoutSpacing`** (`WidgetHolderWithCaptionWdgt`, `StretchableWidgetContainerWdgt`,
  `GenericShortcutIconWdgt`, `GenericObjectIconWdgt`) → mutate-only.
- **`rawSetWidthSizeHeightAccordingly`** (base `Widget` + the icon/caption overrides) → now APPLIES the re-fit with
  a **synchronous `@doLayout()`** instead of scheduling it. (`StretchableWidgetContainerWdgt` already applied via its
  own `rawSetExtent: -> super; @doLayout @bounds`.) The base is now simply:
  ```coffee
  rawSetWidthSizeHeightAccordingly: (newWidth) ->
    @rawSetWidth newWidth
    if @implementsDeferredLayout()
      @doLayout()        # APPLY now (raw = immediate); never @invalidateLayout()
  ```

### 2b. Runtime backstop (`Widget.invalidateLayout`, ~src/basic-widgets/Widget.coffee:3699)
```coffee
invalidateLayout: ->
  # FLOW-RULE ASSERTION + BACKSTOP — see the big comment in-source.
  if world?._recalculatingLayouts
    unless world.__loggedInvalidateViolation
      world.__loggedInvalidateViolation = true
      console.error "FLOWRULE_VIOLATION: invalidateLayout during a layout pass by " + (@constructor?.name) + " ..."
    return                # no-op so the pass still converges
  if @layoutIsValid
    world.widgetsThatMaybeChangedLayout.push @
  @layoutIsValid = false
  if @layoutSpec != LayoutSpec.ATTACHEDAS_FREEFLOATING and @parent?
    @parent.invalidateLayout()
```
After the migration this NEVER fires (verified). It exists so a future regression is **visible** (the log fails the
apps-smoke gate, which treats `console.error` as failure) instead of re-freezing. `world._recalculatingLayouts` is
set across the whole `recalculateLayouts` until-loop (`WorldWdgt.coffee` ~:857).

### 2c. Build-time enforcement (`buildSystem/check-layering.js` rule [E], commit `b89c9141`)
```js
const INVALIDATE_CALL = /[@.]\s*invalidateLayout\b/;
const isImmediateMutator = (name) => /^(raw[A-Z]|silent|fullRaw)/.test(name);   // narrower than isLowLevel
// in checkFile: if (isImmediateMutator(method) && invalidate) violations.push("[E] ...");
```
Rule [E] is intentionally **narrower than `isLowLevel`** (which also matches `_private`/`*Core`/`*Layout`): a
`_private`/`*Core`/`*Layout` method legitimately drives layout and may invalidate other widgets, so it is NOT
covered. The lint runs in `build_it_please.sh`; success prints `0 violations (A/B/C/D/E)`. Negative-tested.

---

## 3. How to verify (the gauntlet) — exact commands

Run each from the repo it belongs to (separate `cd` per repo). **ALWAYS `pkill` zombie browsers first.**
```sh
# build (runs the CoffeeScript syntax gate + the A/B/C/D/E layering lint)
cd Fizzygum && ./build_it_please.sh            # full build (recopies tests); --keepTestsDirectoryAsIs to skip test copy
node ./buildSystem/check-layering.js           # run the lint alone (fast)

# the screenshot suite (byte-exact SWCanvas) — pkill first, every time
cd Fizzygum-tests
pkill -9 -f "Chrome for Testing|chrome-headless|puppeteer|webkit"
node scripts/run-all-headless.js --shards=5                 # dpr1   (~1.3 min)
node scripts/run-all-headless.js --shards=5 --dpr=2         # dpr2   (~1.7 min)
node scripts/run-all-headless.js --shards=5 --browser=webkit  # WebKit cross-engine

# THE APP-LAUNCH GATE — the suite does NOT cover app launch; this is the only guard
node scripts/smoke-apps-headless.js            # launches all 12 desktop apps; fails on any console.error

# determinism soak (mandated for layout-cycle changes) — prefix caffeinate on macOS
caffeinate -i node scripts/torture-headless.js --dprs=2 --speeds=fastest --shards=8 --minutes=25

# --homepage production boot check — 3 EXPLICIT cd steps (chaining build+smoke in one && runs smoke from the wrong dir)
cd Fizzygum && ./build_it_please.sh --homepage
cd Fizzygum-tests && node scripts/smoke-boot-headless.js --native-only
cd Fizzygum && ./build_it_please.sh            # restore the normal test build
```
**Last full-gauntlet result (at `b89c9141`):** lint A/B/C/D/E 0; suite 165/165 dpr1 + dpr2 + WebKit; smoke-apps
12/12; torture 20× dpr2-fastest-s8 (~3,300 execs) 0 flaky; `--homepage` boot OK; zero `FLOWRULE_VIOLATION`.

---

## 4. Gotchas / lessons (durable)

- **The screenshot suite has NO app-launch coverage.** Apps are built/laid-out only when a human clicks a launcher;
  `scripts/smoke-apps-headless.js` is the ONLY automated guard. **Run it for ANY layout-cycle change.** (This is how
  the Slice-2 freeze slipped past a 165/165 suite.)
- **No `timeout(1)` in this shell** — use `perl -e 'alarm N; exec @ARGV' node …` to bound a headless run.
- **`pkill -9 -f "Chrome for Testing|chrome-headless|puppeteer|webkit"` before every suite/app run** — zombie Chromes
  accrue and starve the box, causing spurious stalls.
- **The runners buffer page console until completion** — a hung test prints nothing; a freeze is the symptom. If you
  ever freeze, it's a masked `doLayout` throw (see #18).
- **`createErrorConsole` is a freeze-amplifier (task #18, not yet fixed):** when a `doLayout` throws inside
  `recalculateLayouts`, the catch builds the error console via PUBLIC setters → re-entrancy throw → never recovers →
  freeze that MASKS the primary error. To diagnose a freeze, temporarily replace the recalc catch
  (`WorldWdgt.coffee` ~:910) with `console.error err.stack; throw err`, and/or add a counter guard in
  `_recalculateLayoutsCore`'s `until` loop that throws after ~8000 iters with the offending widget's class/spec.
- **Recapture gotcha:** `capture-macro-test-references.js --clean --dprs=1,2 SystemTest_<name>` writes new refs AND
  deletes stale ones; run its FULL flow (no `--no-build`).
- **Separate `cd` per repo** (build in `Fizzygum/`, run/smoke in `Fizzygum-tests/`). Commit messages via
  `git commit -F <file>` — never backticks/`$()` in `-m` (the Bash tool command-substitutes them).

---

## 5. Key files & sites (reference)

- **Flow rule:** `Widget.invalidateLayout` (~`src/basic-widgets/Widget.coffee:3699`); `Widget.rawSetWidthSizeHeightAccordingly`
  (~:698); base `rawSetExtent`/`silentRawSetExtent`/`rawSetWidth` (~:1514/:1560/:1604).
- **Lint:** `buildSystem/check-layering.js` (rules A/B/C in `checkFile`, D in `checkMacroFile`, E = `isImmediateMutator`).
- **Slice-2 doLayout:** `SimpleVerticalStackPanelWdgt.coffee` (`doLayout`, `_adjustContentsBounds`, `implementsDeferredLayout: -> false`);
  `WindowWdgt.coffee` extends it (`_adjustContentsBounds`, `buildAndConnectChildren` batched via `settleLayoutsOnceAfter`).
- **`world._recalculatingLayouts`** set/reset in `WorldWdgt.recalculateLayouts` (~:850-861); the until-loop is
  `_recalculateLayoutsCore` (~:863).
- **createErrorConsole** `WorldWdgt.coffee:426`; recovery callers ~:912/:1185/:1204/:1335.

---

## 6. NEXT STEPS (ordered; recommended next = the createErrorConsole fix)

1. **#18 — fix the `createErrorConsole` freeze-amplifier, THEN upgrade the guard to a throw (RECOMMENDED NEXT).**
   - Part 1: make `createErrorConsole` (`WorldWdgt.coffee:426`) build its `WindowWdgt`/contents with **raw** setters
     (or defer construction outside the flush) so it can't re-enter `recalculateLayouts`. Then a `doLayout` error
     surfaces as a real error, not a freeze. Verify: deliberately throw in a `doLayout`, confirm a clean error +
     visible error console (not a hang).
   - Part 2 (after Part 1): in `Widget.invalidateLayout`, change the `world._recalculatingLayouts` branch from
     log+no-op to a **hard `throw`** — the flow rule becomes a fail-fast invariant (like the existing re-entrancy
     throws). Safe ONLY once Part 1 lands. Re-run the gauntlet (incl. smoke-apps).
2. **Extend the flow rule to the other re-fit triggers (small).** `silentRawSetExtent` still calls
   `@parent?.childGeometryChanged?()` (a re-fit trigger from a SILENT method — same smell). Audit whether it can be
   dropped/moved to the public tier; if so, extend rule [E] to also forbid `childGeometryChanged`/`_reFitToContents`
   from immediate mutators. Gate with smoke-apps + soak.
3. **#15 — end-of-plan rule-D tightening.** Give the construction-time raw/silent read-back idiom + `reLayout()`
   public self-settling alternatives, then extend lint rule D (`MACRO_FORBIDDEN_CALL`) to forbid
   `raw*`/`silent*`/`fullRaw*`/`/Layout$/` in macro sources too.
4. **#16 — base-declared polymorphic conversion of the duck-typed hooks** (`childGeometryChanged` /
   `reLayOutAfterContainedPanelChange` / `reactToDropOf` / `childAdded` …): owner-deferred to plan-end. Adding a
   base method is inspector-SAFE (zero recapture); deleting an inspector-visible Widget method recaptures the one
   inspector test (`macroDuplicatedInspectorDrivesCopiedTargetOnly`).

Each step: build (lint) → dpr1 suite → **smoke-apps** → (for behavioural/determinism changes) dpr2 + WebKit + soak +
`--homepage`. Ask before commit/push; commit Fizzygum + tests separately.

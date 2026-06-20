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
and build-time-lint-enforced. **Task #18 — fixing the `createErrorConsole` freeze-amplifier and turning the
flow-rule guard into a fail-fast `throw` — is now also shipped (see §1).** The remaining work is small
follow-ups (§6); recommended next = the `childGeometryChanged` flow-rule extension.

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
| **#18 freeze-amplifier fix + guard→throw** | `createErrorConsole` recovery deferred outside the flush; recalc catch made non-flushing + convergent (+ iteration backstop); `invalidateLayout` guard log+no-op → hard `throw` | **`4c78c9cb`** | — |

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

### 2b. Runtime invariant — fail fast (`Widget.invalidateLayout`, ~src/basic-widgets/Widget.coffee:3701)
```coffee
invalidateLayout: ->
  # FLOW-RULE INVARIANT (fail fast) — see the big comment in-source.
  if world?._recalculatingLayouts
    throw new Error "FLOWRULE_VIOLATION: invalidateLayout() during a layout pass by " + (@constructor?.name) + " ..."
  if @layoutIsValid
    world.widgetsThatMaybeChangedLayout.push @
  @layoutIsValid = false
  if @layoutSpec != LayoutSpec.ATTACHEDAS_FREEFLOATING and @parent?
    @parent.invalidateLayout()
```
After the migration this NEVER fires (verified). The `throw` is **safe** (not a re-freeze risk) because of the #18
work below: a violation throws out of the offending `doLayout`, is caught by the recalc catch — which is now
**strictly non-flushing** — reported via the layout-error path, and the world keeps running. It is the runtime
tripwire for anything that slips past the build-time lint (rule [E]) — e.g. a dynamic/duck-typed call the lint can't
see. `world._recalculatingLayouts` is set across the whole `recalculateLayouts` until-loop (`WorldWdgt.coffee` ~:857).

### 2d. The #18 freeze-amplifier fix (`WorldWdgt.coffee`)
A `doLayout` that threw DURING the `recalculateLayouts` flush used to **freeze** the world and mask the real error:
the recalc catch (`_recalculateLayoutsCore`, ~:926) built the error console via **public, self-flushing** setters →
re-entered `recalculateLayouts` → threw the re-entrancy guard BEFORE `@errorConsole` was assigned; and because the
throwing `doLayout` never reached its trailing `markLayoutAsFixed()`, the until-loop never converged. Fixed by
splitting recovery across the flush boundary:
- **Inside the flush (the catch):** do ONLY the minimum, *non-flushing/non-invalidating* work — `markLayoutAsFixed()`
  + `silentHide()` the offender (so the loop converges and the offender is banned from paint) and push the error to a
  new `@layoutErrorsToReport` queue. Nothing here can flush or invalidate, so the §2b `throw` can never escape it.
- **Next cycle, outside the flush (`showLayoutErrorsFromPreviousCycle`, called first in `doOneCycle`):** drain the
  queue — `softResetWorld()` (its `hand.drop → add` may flush; safe here), build the console (public setters; safe),
  show each error in-world AND emit a loud `console.error` (so CI / the smoke-apps gate still catch a genuinely broken
  app — which no longer freezes). Mirrors the existing repaint-error deferral (`errorsWhileRepainting`).
- **Defensive backstop:** a `recalcIterationsCap` (100000) in the until-loop bails loudly (`RECALC_NONCONVERGENCE`)
  instead of hanging if convergence ever fails. Never fires in normal operation.

Verified by a deliberate-throw headless probe: a `doLayout` that throws mid-flush → world keeps cycling, error
surfaced in-world + as one `console.error`, queue converges, no re-entrancy/backstop; and `invalidateLayout`
during a pass now throws `FLOWRULE_VIOLATION`.

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
- **Layout errors no longer freeze the world (task #18, FIXED).** A `doLayout` that throws during the
  `recalculateLayouts` flush is now caught, the offender settled+banned, and the error reported next cycle OUTSIDE
  the flush — both in-world AND as a loud `console.error` (`LAYOUT_ERROR: …`). So a broken app surfaces a real error
  (caught by the smoke-apps gate) instead of hanging. If you ever DO see a hang, look for `RECALC_NONCONVERGENCE`
  (the defensive iteration backstop) — it names the offending widget's class/spec.
- **Recapture gotcha:** `capture-macro-test-references.js --clean --dprs=1,2 SystemTest_<name>` writes new refs AND
  deletes stale ones; run its FULL flow (no `--no-build`).
- **Separate `cd` per repo** (build in `Fizzygum/`, run/smoke in `Fizzygum-tests/`). Commit messages via
  `git commit -F <file>` — never backticks/`$()` in `-m` (the Bash tool command-substitutes them).

---

## 5. Key files & sites (reference)

- **Flow rule:** `Widget.invalidateLayout` (~`src/basic-widgets/Widget.coffee:3701`, now a fail-fast `throw` during recalc); `Widget.rawSetWidthSizeHeightAccordingly`
  (~:698); base `rawSetExtent`/`silentRawSetExtent`/`rawSetWidth` (~:1514/:1560/:1604).
- **Lint:** `buildSystem/check-layering.js` (rules A/B/C in `checkFile`, D in `checkMacroFile`, E = `isImmediateMutator`).
- **Slice-2 doLayout:** `SimpleVerticalStackPanelWdgt.coffee` (`doLayout`, `_adjustContentsBounds`, `implementsDeferredLayout: -> false`);
  `WindowWdgt.coffee` extends it (`_adjustContentsBounds`, `buildAndConnectChildren` batched via `settleLayoutsOnceAfter`).
- **`world._recalculatingLayouts`** set/reset in `WorldWdgt.recalculateLayouts` (~:850-861); the until-loop is
  `_recalculateLayoutsCore` (~:863).
- **createErrorConsole** `WorldWdgt.coffee:426`; recovery callers ~:912/:1185/:1204/:1335.
- **#18 sites:** the now-non-flushing recalc catch in `_recalculateLayoutsCore` (~:926); the `@layoutErrorsToReport`
  queue field (~:206); the drain `showLayoutErrorsFromPreviousCycle` (~:1234), called first in `doOneCycle` (~:1270);
  the `recalcIterationsCap` backstop at the top of the `_recalculateLayoutsCore` until-loop (~:871).

---

## 6. NEXT STEPS (ordered; recommended next = the `childGeometryChanged` flow-rule extension)

1. **Extend the flow rule to the other re-fit triggers (small, RECOMMENDED NEXT).** `silentRawSetExtent` still calls
   `@parent?.childGeometryChanged?()` — a re-fit trigger fired from a SILENT (immediate) method, the same smell the
   flow rule forbids. Audit whether it can be dropped/moved to the public tier; if so, extend lint rule [E] to also
   forbid `childGeometryChanged`/`_reFitToContents` from immediate mutators (`isImmediateMutator`). Gate with
   smoke-apps + soak.
2. **#15 — end-of-plan rule-D tightening.** Give the construction-time raw/silent read-back idiom + `reLayout()`
   public self-settling alternatives, then extend lint rule D (`MACRO_FORBIDDEN_CALL`) to forbid
   `raw*`/`silent*`/`fullRaw*`/`/Layout$/` in macro sources too.
3. **#16 — base-declared polymorphic conversion of the duck-typed hooks** (`childGeometryChanged` /
   `reLayOutAfterContainedPanelChange` / `reactToDropOf` / `childAdded` …): owner-deferred to plan-end. Adding a
   base method is inspector-SAFE (zero recapture); deleting an inspector-visible Widget method recaptures the one
   inspector test (`macroDuplicatedInspectorDrivesCopiedTargetOnly`).

**DONE since this plan was first written:** #18 — the `createErrorConsole` freeze-amplifier fix + the guard→`throw`
upgrade (see §1, §2b, §2d). Verified via a deliberate-throw probe + the full gauntlet.

Each step: build (lint) → dpr1 suite → **smoke-apps** → (for behavioural/determinism changes) dpr2 + WebKit + soak +
`--homepage`. Ask before commit/push; commit Fizzygum + tests separately.

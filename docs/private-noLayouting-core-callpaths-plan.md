# Plan — give every public layout-settling method a private NoLayouting core, and route the private teardown/build chains through cores (no re-entry into the public settle tier)

**Status: PLAN ONLY. Written to be executed COLD by an LLM/engineer with zero prior context.** It embeds the
background, the engine model, every call chain with file:line + signatures, the concrete edits, the subtleties, and
the verification. Read §0 → §3 before touching code. **Do Plan 2 (the settle-tier rename) AFTER this plan.**

**EXECUTION STATUS (2026-06-23 — chains 1 & 2 DONE; only the optional §5 private→public-settle lint + Plan 2 remain):**
- **Step 0 — ONE core, not two.** Instead of the `_addCore`/`_addRawCore` split this plan proposed, `_addCore` itself
  was made the full "add minus settle" (shadow + structural + fractional folded in); `add`/`addRaw` are thin wrappers.
  Byte-identical (the construction adders pass fresh non-world children, so the shadow step is a no-op). The
  now-redundant dead `addRaw` + `fullRawMoveCenterTo` were deleted.
- **Chain 1 (close → basement) DONE & byte-identical.** `addInPseudoRandomPosition` → wrapper +
  `_addInPseudoRandomPositionCore` (→ `@_addCore`); `addLostWidget` → `_addLostWidgetCore`; `_closeCore` recurses
  `@parent._closeCore()`.
- **`_fullDestroyCore` made a PURE core** — recurses `@children[0]._fullDestroyCore()` + `@_destroyCore()` instead of
  public `fullDestroy`/`destroy`, so it is safe to call directly even under `_inLayoutMutation`. Byte-identical.
- **`collapse`/`unCollapse` made self-settling** (public API) via `settleLayoutsOnceAfter` + `_collapseCore`/
  `_unCollapseCore` (batching tier — they reach nested `destroy`/`add` through the window collapse hooks).
  Determinism-verified (gauntlet + torture).
- **Chain 2 (window rebuild) chrome `@add → @_addCore` — DONE 2026-06-23 (was the deferred follow-up; the stink it
  carried is now cleared).** Split `add` → `add`/`_addCore` on `SimpleVerticalStackPanelWdgt` + `WindowWdgt` (mirroring
  the base `Widget` pair), so `WindowWdgt._addCore` folds in the content bookkeeping
  (`contentNeverSetInPlaceYet`/title/`@contents`/spec-init) that the bare base `_addCore` skipped — THAT was the
  `@stack`-undefined break: the content's tag stayed stale, so on a later re-fit the order-independent init recreated
  its `WindowContentLayoutSpec` and dropped the wired `@stack`. Converted all 7 chrome adds; flipped
  `buildAndConnectChildren` to the single-mutation `mutateGeometryThenSettle`; routed `resetToDefaultContents` through
  `@_buildAndConnectChildrenCore` so the child-lifecycle-hook rebuild path never re-enters the public self-settler.
  **Root enabler (a real engine fix):** the chrome icon-button CONSTRUCTORS build their innards via public `add` on an
  ORPHAN, which THREW under `_inLayoutMutation` because `mutateGeometryThenSettle` checked the flow-violation throw
  BEFORE the orphan exemption. Reordered so the orphan guard precedes the throw — orphans aren't in the live tree, so a
  setter on one can't corrupt a flush and must DEFER, not throw (this also retires the old `destroy` "not reachable"
  caveat). Verified dpr1/dpr2/WebKit/apps 165/165 + 18-min torture + end-of-cycle audit.
- **STINK tracker** (`buildSystem/check-stinks.js`, NON-BLOCKING build report): now **4** `settleLayoutsOnceAfter =>
  @_xxxCore()` sites (close / fullDestroy / collapse / unCollapse) — `buildAndConnectChildren` flipped to
  `mutateGeometryThenSettle` 2026-06-23 (above), so it left the list (5 → 4). Each remaining site flips once its core
  is pure. A dead-method lint (`check-dead-methods.js`, 53-method baseline) was also added.

---

## 0. Cold-start orientation (workspace, build, test)

Umbrella `/Users/davidedellacasa/code/Fizzygum-all/` (NOT a git repo) holds 3 sibling **git repos** that must stay
siblings: **`Fizzygum/`** (CoffeeScript GUI-framework source — edit here; ~470 `.coffee` in `src/`),
**`Fizzygum-tests/`** (165 macro SystemTests that drive the live world and compare canvas screenshots byte-exactly),
**`Fizzygum-builds/`** (generated; never edit). One class per file, filename == class name. `nil` == `undefined`.
Every class is a global compiled in-browser; **no `require`/imports** — reference a class by naming it.

**Commands** (the `fg` wrapper at the umbrella root is path-correct from any cwd):
- `/Users/davidedellacasa/code/Fizzygum-all/fg build` — build (runs a CoffeeScript syntax gate + the layering lint
  `buildSystem/check-layering.js`; fails loudly).
- `fg suite` — full suite headless, dpr1, ~1.3 min, 165/165 expected.
- `fg gauntlet` — build + dpr1 + dpr2 + WebKit + app-smoke.
- `fg test SystemTest_<name>` — one test headless. Recapture refs: `fg recapture <name>` (dpr1+dpr2).
- Torture: `cd /abs/Fizzygum-tests && node scripts/torture-headless.js --dprs=2 --speeds=fastest --shards=8 --minutes=18`.
- Shell: Bash cwd may reset between calls (use absolute paths / `fg`); foreground `sleep` is blocked; a PreToolUse
  guard blocks `cd …/Fizzygum && … node …/Fizzygum-tests/…` chains (use `fg` or a single-line `cd /abs/Fizzygum-tests && node …`).
  **Ask before committing** (review-driven project).

---

## 1. The layout-settle tier in one page (you MUST internalize this)

Layout is a **deferred invalidate-then-settle** engine. A mutation marks widgets dirty; a *settle* drains the dirty
queue and re-lays-out. There are **three settle tiers** plus the raw/silent escape hatch — all on `Widget`
(`src/basic-widgets/Widget.coffee`):

- **`mutateGeometryThenSettle(coreThunk)`** (~:780) — the **SINGLE-mutation** public self-settling tier. Runs the
  thunk, then `world.recalculateLayouts()` once, so the layout is consistent on return. **It THROWS** if reached
  while `world._inLayoutMutation` or `world._recalculatingLayouts` is already set (a public setter reached mid-flush
  = a flow-soundness violation). Guards in order: `unless world?` → run thunk; **throw** if `_inLayoutMutation ||
  _recalculatingLayouts`; `if @isOrphan()` → run thunk (no flush); `if world._batchingLayoutSettling` → run thunk
  (DEFER into the outer batch); else set `_inLayoutMutation`, run thunk, `recalculateLayouts()`.
- **`settleLayoutsOnceAfter(thunk)`** (~:827) — the **BATCHED** tier (N mutations → one settle). Sets
  `world._batchingLayoutSettling` for the thunk's duration (so nested `mutateGeometryThenSettle` calls DEFER instead
  of throwing — guard 4 above), then flushes once at the end `unless @isOrphan() or _inLayoutMutation or
  _recalculatingLayouts`. **It does NOT throw** — it is the tier that legitimately permits nested public setters.
- **`invalidateLayout(triggeringChild = nil)`** (~:3789) — marks `@` dirty + climbs to the parent. The low-level
  schedule primitive. Throws if reached during a `_recalculatingLayouts` pass.
- **Raw/silent setters** (`silentRawSetExtent`, `fullRawMoveBy`, `rawSetExtent`, `fullRawMoveTo`, …) — mutate
  geometry but **schedule nothing**. Used inside layout passes where scheduling would re-enter and throw.

**The convention (the whole point of this plan):** a PUBLIC method (`add`, `setExtent`, `destroy`, `close`,
`fullDestroy`, `buildAndConnectChildren`, …) wraps its work in `mutateGeometryThenSettle`/`settleLayoutsOnceAfter`
and delegates the actual work to a **private `_xxxCore`** body. The `_xxxCore` is the **NoLayouting** version (it does
NOT settle). The rule this plan enforces: **a private/Core method (or any body running inside a settle wrap) must
call only OTHER private/Core methods or raw setters — never a PUBLIC settling method.** Calling up into the public
tier re-enters the settle machinery (best case it harmlessly defers via the batch flag; worst case it THROWS).

---

## 2. The problem — two private chains currently call UP into the public `add`

This session (the "teardown self-settle" arc) made `close`/`destroy`/`fullDestroy` self-settle by wrapping each in a
settle tier with a `_xxxCore` body. That exposed TWO private chains whose `_Core` bodies reach the **public `add()`**,
which re-enters `mutateGeometryThenSettle`:

**Chain 1 — `close` re-homes to the basement via public `add`:**
```
close (Widget.coffee:475)                        ← public; wraps (@parent ? @).settleLayoutsOnceAfter => @_closeCore()
 └─ _closeCore (Widget.coffee:482)               ← PRIVATE
     └─ world.basementWdgt.addLostWidget @        ← BasementWdgt.coffee:134 (no wrap, no core)
         └─ @scrollPanel.contents.addInPseudoRandomPosition w   ← PanelWdgt.coffee:113 (no wrap, no core)
             └─ @add aWdgt                        ← PanelWdgt.coffee:121 — PUBLIC add → @mutateGeometryThenSettle
```
Today this does NOT throw only because the OUTER `close` uses the BATCHING `settleLayoutsOnceAfter` (so the inner
`add`'s `mutateGeometryThenSettle` sees `_batchingLayoutSettling` and defers). It is a latent hazard and an
architectural smell (a private body reaching a public setter). `_closeCore` ALSO calls public `@parent.close()`
(Widget.coffee:488 — the window-content→parent-window recursion).

**Chain 2 — `destroy` of a window's contents rebuilds the window via public `add` → THROWS:**
```
windowContents.destroy (Widget.coffee:507)       ← public; wraps @mutateGeometryThenSettle => @_destroyCore()  [sets _inLayoutMutation]
 └─ _destroyCore (Widget.coffee:518)             ← PRIVATE
     └─ @parent?.childBeingDestroyed? @           ← Widget.coffee:520 (hook; defined ONLY on WindowWdgt)
         └─ WindowWdgt.childBeingDestroyed         ← WindowWdgt.coffee:245: if child == @contents then @resetToDefaultContents()
             └─ resetToDefaultContents             ← WindowWdgt.coffee:297 (no wrap)
                 └─ @buildAndConnectChildren()      ← WindowWdgt.coffee:360: @settleLayoutsOnceAfter => @_buildAndConnectChildrenCore()
                     └─ _buildAndConnectChildrenCore ← WindowWdgt.coffee:363
                         └─ @add @label, …          ← WindowWdgt.coffee:351,381,387,394,400,414,433 — PUBLIC add ×7
                             └─ add → mutateGeometryThenSettle (:2400) → THROW "public geometry setter reached during a layout flush"
```
This THROWS because `_inLayoutMutation` is still set from the top `destroy`'s `mutateGeometryThenSettle`, and the
`add`'s `mutateGeometryThenSettle` hits the throw-guard *before* it can see the inner `settleLayoutsOnceAfter`'s
batch flag. (It is not hit by the test suite today — window contents are normally torn down via the **batched**
`fullDestroy`, where the batch flag is set so the inner `add` defers — see the caveat comment at Widget.coffee:512-515.
But it is a real latent throw and the smell the owner wants eliminated.)

**The owner's target shapes** (private chains call only private cores / `_addCore`):
```
close → settleLayoutsOnceAfter → _closeCore → _addLostWidgetCore → _addInPseudoRandomPositionCore → _addCore
destroy → mutateGeometryThenSettle → _destroyCore → _childBeingDestroyed → _resetToDefaultContents
          → _buildAndConnectChildren → _buildAndConnectChildrenCore → _addCore
```

---

## 3. The design — a private NoLayouting core that is EXACTLY the public method minus the settle

**The invariant this plan establishes:** every public settling method is a thin `<settle-tier> => @_xxxCore(...)`,
and the `_xxxCore` contains the **COMPLETE body — every side effect, layout-related or not.** The public wrapper does
nothing but pick the settle tier. Then a private chain can call `_xxxCore` and get faithful, complete semantics, the
*only* difference being "no settle" (the outer batch/core settles once). `close`/`destroy`/`fullDestroy`/
`buildAndConnectChildren` already satisfy this (their thunk is a single `@_xxxCore()` call). **`add` does NOT — and
that is the one subtlety the rerouting must get right.**

**`add` today (Widget.coffee:2399):** `@mutateGeometryThenSettle =>` then, INLINE in the thunk: (1) shadow management
(`unless aWdgt.skipsAddShadowManagement?()`: if `@ == world` → `aWdgt.addShadow()` + cancel scheduled tooltips; else
`aWdgt.removeShadow()`); (2) `@_addCore(...)`; (3) `aWdgt.rememberFractionalPositionInHoldingPanel()` if `@ == world`;
(4) return `aWdgt`. So **`_addCore` (Widget.coffee:2437) is a strict SUBSET of add's body** — only the structural
middle. The shadow + fractional work is NOT layouting; it is part of "add". `_addCore` is minimal because it is
SHARED by `addRaw` (`:2423`, deliberately shadow-less — "raw") and by **~9 construction / layout-pass adders** that
build a widget's own innards (verified callers: `addAsSiblingAfterMe`/`BeforeMe` Widget.coffee:2379/2383, the two
adder sites :4210/:4228, `ScrollPanelWdgt` :40/:55/:60, `LabelButtonWdgt.createLabel` :83, `StringFieldWdgt.createText`
:65, `MenuItemWdgt.createLabel` :59).

**The fix — make the core EXACTLY add-minus-settle (the owner's call):**
1. Rename today's minimal `_addCore` → **`_addRawCore`** (the raw structural core).
2. New **`_addCore`** = shadow-management + `@_addRawCore(...)` + fractional + `aWdgt` — i.e. add's WHOLE thunk body,
   minus the settle.
3. `add` becomes the thin `@mutateGeometryThenSettle => @_addCore(...)`; `addRaw` becomes `@mutateGeometryThenSettle
   => @_addRawCore(...)`.
4. Repoint the ~9 direct minimal-core callers (listed above) to **`@_addRawCore`**. This is **byte-identical**: each
   adds a freshly-created child to a NON-world parent, where the moved shadow code reduces to `removeShadow()` on a
   shadow-less widget (a no-op) and the fractional step is skipped (`@ != world`).
5. **The private teardown chains then reroute `@add` → `@_addCore`** (the full add-minus-settle): faithful shadow +
   fractional, NO per-call decision, and **byte-identical to today** — today's `@add` under the outer
   `settleLayoutsOnceAfter` batch already DEFERS its settle, so it already ran shadow + core + fractional with no
   flush, which is exactly what the new `@_addCore` does.

This both eliminates the re-entry (the core never settles) AND keeps shadow/fractional faithful — the "does shadow
matter here?" question disappears. (`skipsAddShadowManagement` opt-outs — `HighlighterWdgt`, `CaretWdgt` — sit inside
the shadow block, so they ride along unchanged.)

---

## 4. The concrete work (small, verifiable increments — verify after EACH)

**0. The `_addCore` split (§3) — do this FIRST**, on its own commit: rename the minimal `_addCore` → `_addRawCore`;
add the new full `_addCore` (shadow + `@_addRawCore` + fractional + return `aWdgt`); make `add`/`addRaw` the thin
settle-wraps; repoint the ~9 direct callers (§3) to `@_addRawCore`. `fg build` + `fg suite` must be **byte-identical**
(165/165, zero recapture) BEFORE you start rerouting the chains onto `@_addCore`. (Also update the lint — see §5: rule
[A] keys off the `Core$` name, so `_addRawCore` stays covered; if the new rule names `_addCore`, it must allow the
NEW `_addCore` to call `_addRawCore`.)

### 4a. Chain 1 — `close` → basement add
1. **`PanelWdgt.addInPseudoRandomPosition` (PanelWdgt.coffee:113)** → split into a public wrapper + a NoLayouting
   core. Body today: `@add aWdgt` then `aWdgt.fullRawMoveTo position` (raw — fine). New:
   - `addInPseudoRandomPosition: (aWdgt) -> @mutateGeometryThenSettle => @_addInPseudoRandomPositionCore aWdgt`
     (public, for any external caller — grep callers first; if the ONLY caller is `addLostWidget`, you may skip the
     public wrapper and keep only the core).
   - `_addInPseudoRandomPositionCore: (aWdgt) ->` = the current body but `@add aWdgt` → **`@_addCore aWdgt`** (the
     full add-minus-settle from §3 — it carries shadow + fractional, so no per-call decision), keeping
     `aWdgt.fullRawMoveTo position`.
2. **`BasementWdgt.addLostWidget` (BasementWdgt.coffee:134)** → `addLostWidget: (w) ->
   @scrollPanel.contents._addInPseudoRandomPositionCore w` (call the core, not the public). (Grep callers of
   `addLostWidget` — Widget.coffee:494 in `_closeCore` is the one we care about; it's already private context.)
3. **`Widget._closeCore` (Widget.coffee:482)** → change the two public calls:
   - `@parent.close()` (488) → **`@parent._closeCore()`** (the recursion stays inside the private chain; the outer
     `close`'s `settleLayoutsOnceAfter` provides the single settle). Note: `close` returns early here (`return`); keep
     that control flow.
   - the `addLostWidget` call is unchanged (it now routes through the core via step 2).

### 4b. Chain 2 — `destroy`/teardown → window rebuild
4. **`WindowWdgt._buildAndConnectChildrenCore` (WindowWdgt.coffee:363)** → change ALL `@add …` (lines 351, 381, 387,
   394, 400, 414, 433, plus the `createAndAdd*` helpers it calls) to **`@_addCore …`** (the full add-minus-settle from
   §3 — shadow + fractional carried). This makes the core fully private. The PUBLIC `buildAndConnectChildren` (`:360`, `settleLayoutsOnceAfter =>
   _buildAndConnectChildrenCore`) is unchanged and still used by the WindowWdgt constructor (where the window is
   orphan, so the settle no-ops anyway).
5. **`WindowWdgt.resetToDefaultContents` (WindowWdgt.coffee:297)** → make it private `_resetToDefaultContents` and
   have it call `@_buildAndConnectChildrenCore()` directly (not the public `@buildAndConnectChildren()`), keeping the
   `@rawSetExtent` (raw — fine). (Owner's diagram shows an intermediate `_buildAndConnectChildren`; you can either
   call the core directly OR add a thin private `_buildAndConnectChildren` that calls the core — calling the core
   directly is simpler and equivalent.)
6. **`WindowWdgt.childBeingDestroyed`/`childBeingPickedUp`/`childBeingClosed` (WindowWdgt.coffee:245/249/253)** →
   rename to **`_childBeingDestroyed`/`_childBeingPickedUp`/`_childBeingClosed`** (these are private teardown hooks,
   fired from `_destroyCore`/`_closeCore`), and update their bodies to call `@_resetToDefaultContents()`. Then update
   the CALLERS in `Widget._destroyCore`/`_closeCore` (the `@parent?.childBeingDestroyed? @` etc.) to the new private
   names. **Grep every caller** of these 3 hook names across `src` first (`grep -rn 'childBeingDestroyed\|childBeingPickedUp\|childBeingClosed'`).
7. **`WindowWdgt.childBeingCollapsed` (WindowWdgt.coffee:257)** calls public `@editButton.destroy()` /
   `@internalExternalSwitchButton.destroy()` (lines 263, 266). Reroute to `@editButton._destroyCore()` etc. (private),
   and rename the hook `_childBeingCollapsed` for consistency (grep callers).

### 4c. The non-chain re-entry hazards (fix or explicitly leave, with a note)
- **`ToolPanelWdgt.addMany` (ToolPanelWdgt.coffee:9)** and **`ScrollPanelWdgt.addMany` (ScrollPanelWdgt.coffee:214)**
  loop public `@add`. They are not on the teardown chains but are the same smell. Give each a NoLayouting core +
  batch wrap (or confirm they're never reached mid-flush and leave with a `# end-of-cycle/flow-sanctioned` note).
- **`LabelButtonWdgt.setLabel` (LabelButtonWdgt.coffee:111)** wraps `mutateGeometryThenSettle` and calls public
  `@label.fullDestroy()` (113). `fullDestroy` opens its OWN `settleLayoutsOnceAfter` (sets the batch flag), so the
  nested `destroy`'s `mutateGeometryThenSettle` DEFERS — no throw. Note it but it is not a live hazard.
- **`Widget._fullDestroyCore` (Widget.coffee:590)** calls public `fullDestroy`/`destroy` (597-598) in its recursion;
  both defer via the batch flag (by design). Leave (it's correct batching) — but the static lint (§5) will flag it,
  so it needs the sanction marker OR the lint must special-case the recursion.

---

## 5. The static lint — catch a private/Core method calling a public settling method

The build lint **`buildSystem/check-layering.js`** already has the machinery (a per-line regex scanner that tracks
the enclosing 2-space method and classifies it by NAME). **Rule [A]** (lines ~170-173) already fires when an
`isLowLevel` method (name `^raw[A-Z]` / `^silent` / `^_` / `Core$` / `Layout$`) calls one of the 5 `PUBLIC_SETTERS`
(`setExtent/fullMoveTo/setBounds/setWidth/setHeight`) or `recalculateLayouts`. **What it does NOT catch yet:** an
`_`/`Core` method calling **`add`/`addRaw`** (not in `PUBLIC_SETTERS`) or the settle wrappers
**`mutateGeometryThenSettle`/`settleLayoutsOnceAfter`**.

**Extend the lint:** add a regex (e.g. `SETTLE_OR_ADD_CALL = /[@.]\s*(add|addRaw|mutateGeometryThenSettle|settleLayoutsOnceAfter)\b(?!\?)/`)
and, inside the existing `isLowLevel(method)` branch (where [A] lives), push a `[G]` violation when a low-level/Core
method matches it. Provide the SAME `# layout-apply-sanctioned`-style escape marker (define a new
`# settle-reentry-sanctioned: <why>` marker, mirroring the existing per-method marker mechanism at line ~165) for the
legitimately-deferring cases (`_fullDestroyCore`'s recursive `fullDestroy`/`destroy`). Run `fg build` — it should
flag exactly the hazards in §2/§4 until they're rerouted, then pass clean. **This lint is the durable guarantee** the
owner asked for ("find a way to statically catch these situations … especially add()").

---

## 6. Verification protocol (mandatory; determinism-sensitive)

After EACH increment (a chain or a single core reroute):
1. `fg build` (syntax gate + the layering lint, incl. the new rule).
2. `fg suite` (dpr1, 165/165). The likely-affected test is the standalone-window-content-destroy path and any
   menu-close/basement test. On a PIXEL failure, dump + `Read` the `.png` vs the committed reference under
   `tests/SystemTest_<name>/automation-assets/**/SWCanvas/ceilPixRatio_1/` — a real regression in the §4-step-0 split
   means a repointed `_addRawCore` caller was NOT adding a fresh non-world child (so the moved shadow/fractional was
   not a no-op for it — §3); investigate that caller, don't recapture blindly.
3. `fg gauntlet` (dpr1/dpr2/WebKit/apps) — the shadow decision must hold across engines/densities.
4. **Torture** `--dprs=2 --speeds=fastest --shards=8 --minutes=18` — settle-timing gate.
5. **Re-run the end-of-cycle audit** (`end-of-cycle-audit-tooling.md`); confirm the inventory is unchanged (this arc
   is a pure call-routing refactor — it must NOT change which widgets reach end-of-cycle).

**Determinism contract:** render/layout/input must be a pure function of the event stream + final geometry — never
of timers/frame-counts/intermediate passes (`Fizzygum-tests/DETERMINISM.md`).

---

## 7. Risks, subtleties, scope

- **The `_addCore`/`_addRawCore` split (§3, §4-step-0) is the main mechanical care-point — but it is designed to be
  byte-identical** (the ~9 repointed callers add fresh non-world children, so the moved shadow code is a no-op
  `removeShadow` + the fractional step is skipped). Verify it ALONE (its own commit) before rerouting the chains. A
  pixel diff there = a repointed caller that wasn't a fresh-non-world add; investigate it, don't blanket-revert. Once
  the split lands, the chain reroutes to `@_addCore` carry shadow/fractional faithfully with no per-call decision.
- **Inspector recapture:** renaming `childBeingDestroyed`→`_childBeingDestroyed` etc. and adding cores changes the
  member list the live `InspectorWdgt` shows, so `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly`
  recaptures (benign — the owner does not care). Its macro was made robust to method-list growth this session (it
  centres `alpha` in the list pane), so it should still drive the rects correctly; recapture dpr1+dpr2 if it shifts.
- **Owner notes carried forward:** (a) once the private chains use cores, `buildAndConnectChildren`'s
  `settleLayoutsOnceAfter` wrap may become unnecessary in the teardown path — the owner said *"settleLayoutsOnceAfter
  should in theory never happen — but let's wait for that"*: do NOT remove it in this arc, just note it. (b) Where a
  public method still wraps an ANONYMOUS inline body (no named core) — `setBounds`, `fullMoveTo`, `setExtent`,
  `setWidth`, `setHeight`, `add`, `setLabel`, the two `sizeToTextAndDisableFitting` — **extract a `_xxxCore`** so the
  pattern is uniform (these don't currently re-enter, but the owner wants the Core versions to exist). (c) *"Core"
  really means "NoLayouting"* — that rename is **Plan 2 / a later session**, not here.
- **Rollback:** every reroute is a one-line `@add → @_addCore` / `@x.public() → @x._core()` change; `git diff` /
  `git checkout -- <file>`.

## 8. File:line map (lines drift — grep the name)
`src/basic-widgets/Widget.coffee`: `mutateGeometryThenSettle` ~:780 · `settleLayoutsOnceAfter` ~:827 ·
`invalidateLayout` ~:3789 · `close`/`_closeCore` ~:475/:482 · `destroy`/`_destroyCore` ~:507/:518 ·
`fullDestroy`/`_fullDestroyCore` ~:588/:590 · `add`/`addRaw`/`_addCore` ~:2400/:2424/:2437.
`src/BasementWdgt.coffee`: `addLostWidget` ~:134. `src/basic-widgets/PanelWdgt.coffee`: `addInPseudoRandomPosition`
~:113 · `childRemoved` ~:90. `src/WindowWdgt.coffee`: `childBeingDestroyed`/`childBeingPickedUp`/`childBeingClosed`/
`childBeingCollapsed` ~:245/:249/:253/:257 · `resetToDefaultContents` ~:297 · `buildAndConnectChildren`/
`_buildAndConnectChildrenCore` ~:360/:363 (the `@add` calls ~:351,381,387,394,400,414,433).
`buildSystem/check-layering.js`: rule [A] ~:170 · `isLowLevel` ~:54 · `PUBLIC_SETTERS` ~:40 · the marker mechanism ~:160-165.

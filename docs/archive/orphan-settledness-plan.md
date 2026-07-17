> **ARCHIVED — COMPLETE (2026-07-17 restructure).** EXECUTION STATUS COMPLETE 2026-06-30; Phase 1+2 done+committed, extended by all-constructors-settle-plan
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Plan — close the I2-on-orphans settledness gap

> **Self-contained / runnable cold.** Everything needed to execute this without prior context is inline:
> the framework primer (§0), why the engine is shaped this way (§2), the verbatim current code (§3), the
> exact before→after for both phases (§4/§5), the precise verification commands (§7), and a file:line
> touch-list (§9). Workspace root: the **umbrella** dir holding the `Fizzygum/`, `Fizzygum-builds/`,
> `Fizzygum-tests/` siblings (not itself a git repo). The git repo to edit is the `Fizzygum/` sibling.
> Current HEAD when written: `d2c90cc3` (master).
>
> **Delivered in two phases, in order.** Phase 1 (core — orphan public calls settle) then Phase 2
> (constructors return settled). **Phase 2 depends on Phase 1**: a constructor's `_settleLayoutsAfter`
> wrap only settles *because* Phase 1 makes the orphan guard settle; without Phase 1 the wrap is silently
> swallowed (exactly what defeats `WindowWdgt.buildAndConnectChildren` today). Phase 1 is independently
> shippable and is itself the I2-gap closure; Phase 2 extends the guarantee to `new Foo()`.

---

## ✅ EXECUTION STATUS — COMPLETE (2026-06-30)

**Done + committed.** Phase 1 (orphan public calls settle) + Phase 2 (constructor sweep — `new Foo()` returns
settled) are implemented, lint-clean, and verified. Engine: `_settleLayoutsAfter`/`_settleLayoutsAfterBatch`
orphan-guard + `_collapseNoSettle`/`_unCollapseNoSettle` phase-valve. Crash fixes (`./fg apps` FAIL→PASS):
`SimpleDocumentWdgt.buildAndConnectChildren` (settled while `simpleDocumentScrollPanel` was nil),
`DegreesConverterApp.buildWindow` (orphan adds → `_addNoSettle`), and the `_unCollapseNoSettle` twin. Sweep:
16 widgets → `buildAndConnectChildren` wrapper + `_buildAndConnectChildrenNoSettle` core (`@add`→`@_addNoSettle`,
`.setFontName`→`._setFontNameNoSettle`); `WindowWdgt` trailing extent → `setExtent`; `LabelButtonWdgt.setLabel`
→ wrapper + `_setLabelNoSettle` core (public wrapper dead-method-allowlisted). NOT converted: `ListWdgt`
(ScrollPanelWdgt custom `add`; already settled-after-new), `ToolTipWdgt` (`openAt` caller), scroll-panel family.
**KEY LESSON:** `@add`→`@_addNoSettle` is byte-identical ONLY for the standard `Widget.add`; a custom-`add`
base (ScrollPanelWdgt) breaks it (caught + reverted on ListWdgt). Verified green at `speed=fastest`: gauntlet
(dpr1+dpr2+webkit 165/165 + apps + tier-naming + settle gates), capstone (0 careless pushes), paint-readonly
(0 paint-time schedules). KNOWN-SEPARATE: a `speed=normal`/parallel-load flake in `macroDemoMenuCatalogueParade`
+ `macroPaddingAreaIsPartOfWidget` is **pre-existing** (reproduced on pre-campaign HEAD), tracked separately.

**FOLLOW-ON (2026-06-30) — all constructors settle.** This plan's Phase-2 sweep settled the ~16 content-sizing
constructors; the follow-on **Topic 4 part 2** (`docs/archive/all-constructors-settle-plan.md`) extended it to EVERY
inline-building constructor (13 more) under one contract + a can't-forget build gate
(`buildSystem/check-constructors-build.js`). It also REFINED this plan's framing in two places: (1) §2's "constructors
do NOT settle; they build via cores" is **superseded** — constructors now DO settle, via the wrapper, which AUTO-DEFERS
in-flush (the §6 residual exception is exactly the branch that makes callback-time construction safe); (2) the rule-[J]
notification-settle gate was made aware of that auto-defer — it now PERMITS an orphan-receiver `_settleLayoutsAfter`
in a callback (it provably defers), so only an attached-receiver settle / `recalculateLayouts` stays a violation.

> The detailed RESUME-HERE plan that produced this is kept below as the execution record.

### (original RESUME-HERE plan — now executed)

**Where we are.** Phase 1 (the orphan-guard change) is implemented + suite-verified; a latent collapse bug is
fixed; the construction-settle-free + settled-after-`new` sweep (the bulk) is **designed + pattern-validated but
NOT yet executed** across the ~22 widgets. NOTHING is committed. The tree is **not green** (app-smoke fails) until
the sweep lands.

**In the working tree (UNCOMMITTED; persists on disk; `src/basic-widgets/Widget.coffee` only):**
- **Orphan-guard change** — `_settleLayoutsAfter` (~:803): the standalone `if @isOrphan(): return coreThunk()`
  early-out was REMOVED and folded into the in-flush check (`if _inLayoutMutation or _recalculatingLayouts: return
  coreThunk() if @isOrphan(); throw …`). So a NON-in-flush orphan now falls through to the flush (settles); an
  IN-flush orphan still defers. Plus `_settleLayoutsAfterBatch` (~:867): dropped the `@isOrphan() or` term. **Suite
  green dpr1/dpr2/webkit 165/165 + tier-naming + settle gates green with this alone.**
- **Collapse phase-valve fix** — `_collapseNoSettle` (~:2170): `@_invalidateLayout()` →
  `if world?._recalculatingLayouts then @__markForRelayout() else @_invalidateLayout()`. (Layout passes collapse
  chrome by width; the FIRST such collapse now happens mid-construction-settle, so the schedule must be in-pass-safe.
  Genuine latent-bug fix — keep.)

**The ONLY remaining failure: app-smoke.** `new WindowWdgt` / app-window content settle MID-construction on
half-wired widgets → `TypeError reading 'parent'/'0'` (and previously `_collapseNoSettle` FLOWRULE, now fixed). The
sweep below fixes it. **Oracle = `./fg apps` (must go FAIL → PASS).**

**THE SWEEP — construction settle-free + settled-after-`new` (~22 widgets). CONFIRMED per-widget pattern:**
```coffee
constructor: ->
  super(...)
  … field setup …
  @_buildAndConnectChildren()                       # ctor calls the PRIVATE wrapper, settle-LAST
_buildAndConnectChildren: ->                         # private self-settling WRAPPER
  @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()
_buildAndConnectChildrenNoSettle: ->                 # private NON-settling core
  @_addNoSettle child1                               # every public @add -> @_addNoSettle (forced by lint [G])
  …
```
**Hard-won rules (do NOT deviate — each was a failed attempt this session):**
1. **NEVER inline `@_settleLayoutsAfter` in a constructor body** — it makes the static lint classify `constructor`
   itself as a self-settling wrapper and then flag every `new X()` in every `_*NoSettle` core (9 lint-[G]
   violations from ONE widget). Route the settle through the NAMED wrapper; `constructor` calling a wrapper is fine
   (it's not low-level). The lint discovers wrappers as DIRECT `_settleLayoutsAfter` callers (no transitive).
2. **Renaming the build to a `_*` (low-level) name FORCES `@add`→`@_addNoSettle`** (lint [G] forbids low-level code
   from calling the public structural `@add`). Unavoidable — the build genuinely becomes a non-settling core.
3. **Nested children built via bare `new ChildWdgt()` inside a core are auto-non-settling** — the child's own settle
   DEFERS in-flush (the parent wrapper set `_inLayoutMutation`). This IS the implicit "newNoSettle"; no explicit
   mechanism needed (an explicit `Widget.newNoSettle()` was discussed + DEFERRED as optional hardening). This is why
   the existing `WindowWdgt._buildAndConnectChildrenNoSettle` (bare `new EditIconButtonWdgt`) passes the lint today.
4. **The settle must be the LAST construction act** — trailing layout-affecting setup un-settles it. WindowWdgt:
   the `@_applyExtentAndNotify new Point 300,300` (~:119) and the `@disableDrops()`/`@label.setText` title block
   (~:107-117) must move INSIDE the wrapper, before the flush. Non-layout field sets after the settle are fine.

**The ~22 widgets (constructor-time `buildAndConnectChildren` callers):**
- **2 already have a `_buildAndConnectChildrenNoSettle` core:** `WindowWdgt` (wrapper ~:436 → make private + fold
  trailing label/extent inside; ctor ~:105). `InspectorWdgt` (core ~:154; ctor ~:128 — BUT its show*/hide*/
  addProperty/renameProperty/removeProperty rebuild methods (~:70-105/200/208/213/214/278/637/654/669) are
  POST-construction and must KEEP settling → they call the wrapper, do NOT convert them).
- **~18 plain (build via public `@add`, NO core yet):** AxisWdgt:15, VideoPlayerWithRecommendationsWdgt:70,
  VideoControlsPaneWdgt:24, VideoPlayerWdgt:39, SimpleDocumentWdgt:72, ListWdgt:56, RegexSubstitutionPatchNodeWdgt:186,
  SimpleLinkWdgt:34, CalculatingPatchNodeWdgt:176, DiffingPatchNodeWdgt:176, CodePromptWdgt, SpeechBubbleWdgt,
  ErrorsLogViewerWdgt, ConsoleWdgt, BasementWdgt, FridgeMagnetsWdgt, ScriptWdgt, StretchableEditableWdgt.
- **KEEP public/settling (NOT constructors — do NOT convert):** `ToolTipWdgt.openAt:58`; the InspectorWdgt rebuild
  methods above.
- **App content that also crashed (not via `buildAndConnectChildren`):** `SimpleDocumentScrollPanelWdgt`
  (ctor → `setContents` → public `add` → settle), `ReconfigurablePaintInfoWdgt`, `DegreesConverter` content — same
  principle (make their ctor build settle-free + settle-last); inspect when `./fg apps` still flags them.

**[H] nuance to confirm at build:** a PRIVATE `_buildAndConnectChildren` self-settling wrapper may trip lint [H]
(non-fatal warning: "self-settling wrappers should be thin public"). If so: sanction it, OR use ONE shared
`Widget._settleAfterConstruction: -> @_settleLayoutsAfter => nil` that each ctor calls LAST (after building via cores)
— same lint-safety (ctor calls a named method, not `_settleLayoutsAfter` directly).

**Verification:** `./fg apps` FAIL→PASS first; then full `./fg gauntlet` (build + dpr1 + dpr2 + webkit + apps) + the
capstone gate (`Fizzygum-tests/scripts/end-of-cycle-audit/run-capstone-gate.sh`) + paint-readonly gate + a 20-min
`cd Fizzygum-tests && caffeinate -i npm run torture -- --minutes=20`. Then summarize + ask the owner before commit.

**DO NOT re-attempt:** the naive "convert constructor-time public `@buildAndConnectChildren()` →
`@_buildAndConnectChildrenNoSettle()`" — most widgets have NO such core (it's a per-widget method, not a base), so it
calls a non-existent method (tried + reverted this session). The wrapper+core+ctor pattern above is the correct shape.

---

## §0 — Orientation for a cold reader (skip if you know the engine)

**Fizzygum** is a CoffeeScript GUI framework — a "web operating system" (windows, desktop, drag-and-drop)
rendered on a single HTML5 `<canvas>`, descended from Morphic.js. Widgets form a tree
(`TreeNode → Widget → PanelWdgt → … → WorldWdgt`); the global singleton is `window.world`. `nil` means
`undefined`. One class per file; filename = class name. Source is `Fizzygum/src/**/*.coffee`; the main
class is `src/basic-widgets/Widget.coffee`. **Never edit `../Fizzygum-builds/`** (generated).

**The layout engine (what you must know for this plan):**
- Layout is a **work-list / dirty-set settle that iterates to a fixed point** (like browser reflow), NOT
  a structured two-pass measure→arrange. `Widget._invalidateLayout` marks a widget dirty, pushes it onto
  the global queue `world.widgetsThatMaybeChangedLayout`, and **climbs to `@parent`** (stopping at a
  freefloating boundary or `parent == nil`). `world.recalculateLayouts()` is the **flush**: it drains the
  queue, walking each dirty node up to its topmost-dirty ancestor and calling `_reLayout()` top-down until
  the queue is empty.
- **"Settled" = the queue is drained and every widget's applied `@bounds` is correct.** Geometry accessors
  (`width()`, `height()`, `position()`) read the **applied** `@bounds` — there is *no* "where is this
  heading" query, and getters must stay **pure** (no settle-on-read: the "pending-aware accessor" idea,
  "Path A", was tried and falsified).
- **Three flush sites only:** (1) end of `WorldWdgt.doOneCycle` every frame; (2) `Widget._settleLayoutsAfter`
  — runs after every **public geometry/structural mutation** and flushes *before returning* (this is the
  "self-settling tier", the subject of this plan); (3) `Widget._settleLayoutsAfterBatch` — a batch that
  coalesces N mutations into one flush (**dormant — 0 live callers**).
- **Immediate (geometry) mutators** = the low-level setters internal layout uses (`_apply*AndNotify`,
  `_commit*AndNotify`, `__*` leaves, `_move*`/`_set*`/`_resize*`). They mutate `@bounds` but must **never
  schedule** layout (a runtime `FLOWRULE_VIOLATION` throw + the build-time lint `check-layering.js` rules
  [A]–[M] enforce this). The public deferred API (`setExtent`, `moveTo`, `add`, …) is the only tier that
  schedules/flushes. The `*NoSettle` suffix marks a **non-settling core** of a public self-settling wrapper.
- **Orphan** = a widget whose root is neither `world` nor `world.hand`: `TreeNode.isOrphan` (`src/basic-data-
  structures/TreeNode.coffee` ~:158) = `root = @root(); return root != world and root != world.hand`. This
  is exactly: a widget **under construction**, **closed into the off-world basement**, or **manually
  detached**. A widget being **float-dragged on the hand is NOT an orphan** (root = `world.hand`), so it
  already self-settles. Orphans are **never painted to the world canvas** (`Widget.preliminaryCheckNothing-
  ToDraw` ~:1984 returns "nothing to draw" for an orphan on the world context).
- **Determinism:** SystemTests assert **byte-identical** canvas pixels, so layout must be a pure function of
  the event stream + final geometry, independent of iteration/frame count or wall-clock. This is why every
  layout change must clear the determinism soak.
- **The two hard-fail gates this plan must keep green:**
  - **End-of-cycle capstone** (`Fizzygum-tests/scripts/end-of-cycle-audit/run-capstone-gate.sh`): runs the
    whole suite with a runtime audit on and FAILS if any **careless** push is recorded — a push made
    OFF-settle (`!world._inLayoutMutation`), on an ATTACHED widget (`!isOrphan`), OUTSIDE a coalescing
    declaration. (Orphan pushes are excluded by design — relevant here.)
  - **Paint-read-only** (`Fizzygum-tests/scripts/paint-readonly-audit/run-paint-readonly-gate.sh`): FAILS if
    any widget schedules layout during the paint pass.

---

## §1 — The goal and the gap (Context)

**The goal — one unconditional invariant.** Fizzygum's layout should satisfy: *after any public API call on
a widget, that widget's own subtree has correct ("settled") geometry, and the world is correct.* This
removes the need for a caller to ever reason "is layout settled on this line?" — the pesky, error-prone
settle-tracking the owner wants gone.

**What already holds (no change needed).** For an **attached** widget, `_settleLayoutsAfter` (§3) runs the
mutator core then `recalculateLayouts()` **before returning** — the whole world is settled on return. The
hand-detached (float-drag), collapsed (`collapse`/`unCollapse` self-settle), and hidden (`hide`/`show` are
paint-only and layout-neutral) cases are likewise already settled. Read as *"after a public call the
**world** is settled,"* the invariant is already universal (an orphan call can't dirty the world).

**The one gap (I2-on-orphans).** The single exception is the **orphan**. The orphan branch in
`_settleLayoutsAfter` (~:816, `if @isOrphan() then return coreThunk()`) runs the core but **skips the
flush**, so the orphan's *own* subtree is **not settled synchronously** on its own public call. It is still
queued (the flush loop `WorldWdgt._recalculateLayoutsBody` ~:948 has **no** orphan early-out) and gets laid
out at the **next** flush (next attached mutation, the end-of-cycle `doOneCycle`, or on attach). So the gap
is purely **synchrony**: the footgun is the *synchronous* "build/mutate an orphan, then query its geometry
in the same handler" path, which reads stale geometry.

**Intended outcome.** Make the invariant unconditional ("after any public call, the receiver is settled"),
no "*unless orphan" asterisk. An orphan's settled geometry is its **intrinsic / parentless** form — sized to
content, at its current origin (≈0,0) — which re-settles to its in-context form on attach (proportional
widgets size to their container). This is the same intrinsic-vs-applied distinction the framework's pure
`preferredExtentForWidth` measure already embodies, so the architecture is unusually ready for it.

---

## §2 — Prior-arc history (why the code is shaped this way)

- **The deferred-layout campaign** built the **self-settling tier** (`_settleLayoutsAfter`, formerly
  `mutateGeometryThenSettle`) so every public mutation leaves the world consistent on return, and added the
  **orphan guard** so construction (which builds detached subtrees, often *inside* another mutation's
  settle) defers instead of throwing or crashing.
- **Commit `08bbb29d`** ("constructors build orphans settle-free") swept ~12 constructors so they add
  children via the **non-settling `_addNoSettle` core** rather than the public self-settling `add()` — a
  public `add` in a constructor that runs inside a callback (e.g. a window rebuilding chrome on drop) would
  re-enter the enclosing flush ("settle-in-callback" leak). **This established the discipline this plan
  relies on: constructors do not settle; they build via cores.**
- **The orphan/construction model** (assessment doc §2.7): "modify off-world, settle on attach." Excluding
  orphans from the careless-push audit is **classification, not suppression** — the push is still made and
  still laid out; it just isn't *counted* as careless and doesn't self-flush. *Defer ≠ skip.*
- **The "63-test" lesson (critical, and why it does NOT apply here):** a blanket `return if @isOrphan()`
  added atop `_invalidateLayout` once broke 63 tests across engines, because it **suppressed the orphan's
  invalidation QUEUEING** — construction orphans and the detached-but-live float-dragged widget
  (`macroDetachedWidgetStaysFloatDraggable`) have load-bearing invalidates that were then lost. **This plan
  does the OPPOSITE: it keeps queueing and *adds* a synchronous flush. Orthogonal failure mode.**
- **The naming campaign** (through `c5ae7697`) retired the "raw/silent/fullRaw setter" noun for "immediate
  (geometry) mutator" and renamed the low-level family to `_apply*AndNotify` / `_commit*AndNotify` / `__*` /
  `_move*` / `_set*`. (One stale "raw/silent setters" string survives in the `_settleLayoutsAfter` throw —
  optional tidy in Phase 1, §4.)

---

## §3 — Current behavior (verbatim, the code you will edit)

`src/basic-widgets/Widget.coffee`, current `_settleLayoutsAfter` (~:803) — note the orphan branch returns
WITHOUT flushing:

```coffee
  _settleLayoutsAfter: (coreThunk) ->
    unless world?                                   # early bootstrap: nothing to flush to yet
      return coreThunk()
    if @isOrphan()                                  # ← THE GAP: orphan runs core, SKIPS the flush
      return coreThunk()
    if world._inLayoutMutation or world._recalculatingLayouts
      throw new Error "Fizzygum: a public geometry setter was reached during a layout flush/pass -- internal layout code (_reLayout / _reLayoutSelf / ...) must use the raw/silent setters, not the public deferred API (see buildSystem/check-layering.js)."
    if world._batchingLayoutSettling               # inside a batch: defer to the batch's one flush
      return coreThunk()
    world._inLayoutMutation = true
    try
      result = coreThunk()
      world.recalculateLayouts()                    # THE FLUSH (attached widgets only, today)
      return result
    finally
      world._inLayoutMutation = false
```

Current `_settleLayoutsAfterBatch` (~:857) — **dormant (0 live callers)**; its end-of-batch flush also skips
orphans (`unless @isOrphan() or …`):

```coffee
  _settleLayoutsAfterBatch: (thunk) ->
    unless world? then return thunk()
    if world._batchingLayoutSettling then return thunk()   # nested batch absorbed by outer
    world._batchingLayoutSettling = true
    try
      result = thunk()
    finally
      world._batchingLayoutSettling = false
    unless @isOrphan() or world._inLayoutMutation or world._recalculatingLayouts   # ← skips orphans too
      world._inLayoutMutation = true
      try
        world.recalculateLayouts()
      finally
        world._inLayoutMutation = false
    result
```

The template Phase 2 will replicate — `WindowWdgt.buildAndConnectChildren` (`src/WindowWdgt.coffee` ~:436),
the one existing "build then settle once" shape, currently **defeated by the orphan guard during
construction** and activated by Phase 1:

```coffee
  buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()
```

---

## §4 — Phase 1: orphan public calls settle synchronously

Restructure `_settleLayoutsAfter` so the orphan branch **settles** instead of skipping — gated on not
already being inside a flush. Target:

```coffee
  _settleLayoutsAfter: (coreThunk) ->
    unless world?
      return coreThunk()
    # IN A FLUSH/PASS already?  orphan → DEFER (the one principled, framework-internal exception:
    #   construction nested inside a live flush, e.g. a drop-rebuild — it settles when the enclosing
    #   operation's flush completes);  attached → THROW (flow violation, unchanged).
    if world._inLayoutMutation or world._recalculatingLayouts
      return coreThunk() if @isOrphan()
      throw new Error "Fizzygum: a public geometry setter was reached during a layout flush/pass -- internal layout code (_reLayout / _reLayoutSelf / ...) must use the immediate (geometry) mutators, not the public deferred API (see buildSystem/check-layering.js)."
    if world._batchingLayoutSettling
      return coreThunk()
    # NOT in a flush: settle now — for ATTACHED widgets (as before) AND for ORPHANS (new). The flush lays
    # out the orphan's own queued subtree (an orphan's _invalidateLayout can't climb into the world).
    world._inLayoutMutation = true
    try
      result = coreThunk()
      world.recalculateLayouts()
      return result
    finally
      world._inLayoutMutation = false
```

What changed vs §3: the standalone `if @isOrphan(): return coreThunk()` early-out is **removed**; the
in-flush check now runs first and only the **orphan-in-a-flush** case defers. (Optional in-passing tidy: the
throw string's "raw/silent setters" → "immediate (geometry) mutators", per the naming campaign.)

**Symmetric, forward-looking change to the dormant batch tier** `_settleLayoutsAfterBatch` (~:867): drop the
`@isOrphan()` term from the end-of-batch gate so an orphan batch settles once at batch end when not in a
flush:
```coffee
    unless world._inLayoutMutation or world._recalculatingLayouts    # was: unless @isOrphan() or ...
```
(0 live callers — consistency only; keeps the two tiers aligned if the batch is ever revived.)

**Key properties.**
- **Reuses the exact existing flush** — no new settle machinery. The orphan's queued invalidations are its
  own subtree, so when the world is already settled (the normal case) the flush lays out *only* the orphan.
- **The in-flush deferral is the single, user-invisible exception** (§6). Any top-level `new`/public call
  settles synchronously; only framework construction nested in a live pass defers.
- **Re-entrancy preserved.** The orphan-in-a-flush defer keeps an orphan public call from re-entering an
  active `recalculateLayouts` (which would hit the FLOWRULE throw) — exactly what the current orphan guard
  protects for the drop-rebuild path.

**Blast radius (what Phase 1 ACTIVATES).** Every `_settleLayoutsAfter` call that *currently no-ops on an
orphan* becomes a real settle (when not in a flush). The notable pre-existing one is
`WindowWdgt.buildAndConnectChildren`, called at window construction (`WindowWdgt` ~:105): today swallowed,
after Phase 1 it settles the window's chrome mid-construction — **the top probe target** (§8 Risk 2). The
other activations are post-construction public mutations on detached / basement orphans (the intended wins).

---

## §5 — Phase 2: `new Foo()` returns settled (constructor sweep; depends on Phase 1)

**Why a sweep is needed.** There is **no universal post-construction hook**: the base `Widget` constructor
(~:347–367) runs `super()` *first* (so it can't settle after a subclass builds), and sets a default
`0,0,50,40` box so every widget has *some* geometry immediately. Post-`08bbb29d` constructors build via
non-settling cores (`_addNoSettle`, `_commitExtentAndNotify`) and call **no** public setters. Because getters
must stay pure (no settle-on-read), a widget can only be settled-on-`new` by an **explicit
end-of-construction settle** — which Phase 1 makes effective.

**The migration (per target constructor):** extract the construction body into a non-settling
`@_build…NoSettle()` core, and end the constructor with `@_settleLayoutsAfter => @_build…NoSettle()` — the
`WindowWdgt.buildAndConnectChildren` template, in the spirit of `08bbb29d`. Concretely, for a content-sizing
widget that builds children inline (shape of `src/ButtonWdgt.coffee` ~:36):

```coffee
# BEFORE
constructor: (args…) ->
  super()
  …field setup…
  @_addNoSettle @faceWidget          # builds children via cores — but never settles → orphan stays unsettled

# AFTER
constructor: (args…) ->
  super()
  …field setup…
  @_settleLayoutsAfter => @_buildContentNoSettle()   # settles the orphan subtree at construction end (Phase 1)

_buildContentNoSettle: ->
  @_addNoSettle @faceWidget          # the extracted non-settling core; ALSO the path used in-flush
```

**Rules.**
- **The settle must be the constructor's LAST act.** A trailing non-settling core set after it (e.g.
  `WindowWdgt`'s `@_applyExtentAndNotify new Point 300,300` at ~:119, *after* `buildAndConnectChildren` at
  ~:105) would leave the widget unsettled again — fold such trailing sets into the pre-settle core.
- **Only widgets whose laid-out result differs from their constructor field-sets need the wrap** —
  content-sizing text/labels, stacks, windows, containers. **Skip fixed-size widgets.** Identify the set in
  a Phase-2 scoping pass (expect ~40–50 of ~240 constructors). Heuristic: a constructor that builds children
  or whose extent depends on content is a candidate; one that only sets fixed fields is not.
- **In-flush construction stays on the cores.** The rebuild-on-drop paths already call `_build…NoSettle`
  directly (not the public wrapper), so Phase 1's defer-when-in-flush branch leaves them unchanged.

**Sequencing:** incremental, individually-soaked batches (like `08bbb29d`), not one mega-commit. Reject the
"lazy constructor (do nothing until first method)" extreme — it relocates the uncertainty and reintroduces
the laziness-tracking the owner wants gone.

---

## §6 — The one residual exception (and the future path to remove it)

Phase 1 keeps a single deferral: an orphan public call reached **inside an active flush** (framework
construction during a rebuild-on-drop) defers rather than re-entering `recalculateLayouts`. This is
**user-invisible** — any top-level `new`/public call settles synchronously; only framework-internal
construction nested in a live pass defers, settling when that pass completes. Making *even that* synchronous
would require the settle engine to run a **scoped settle on the disjoint orphan subtree** independent of the
global flush/queue/flag (an ordered-downwalk-flavored change) — a larger, separate undertaking, noted here as
the future path to a truly exception-free engine, **not in scope for these phases.**

**Update (2026-06-30):** the all-constructors-settle follow-on (`docs/archive/all-constructors-settle-plan.md`) makes this
deferral **load-bearing** rather than merely tolerated: now that every constructor calls its settling wrapper, a widget
built inside a settle-neutral callback (the window chrome buttons via `WindowWdgt._reactToChildDropped`) relies on this
exact in-flush+orphan branch to DEFER instead of leaking a settle. The rule-[J] notification-settle gate was
correspondingly taught that an orphan-receiver settle in a callback IS this safe defer (not a violation). So "remove the
exception" is no longer purely an improvement — it is the mechanism that lets callback-time construction settle
uniformly with no per-construction flag.

---

## §7 — Verification (exact commands; each phase independently green before advancing)

All commands run from the umbrella root (the dir holding `Fizzygum/` + `Fizzygum-tests/`). The `./fg` wrapper is
path-correct from there and gates on real exit codes. (Prereqs are global: `coffee`, `terser`, `python3`;
Puppeteer once via `cd Fizzygum-tests && npm i`; WebKit once via `npx playwright install webkit`.)

**Phase 1 — probe first, behind a throwaway flag.** Implement the change gated on a temporary
`world._orphanSettleEnabled` (default ON = new behavior) so you can A/B it (flip OFF → confirm the baseline
still passes; ON → test the change). Then:

1. **Gauntlet** (build + suite dpr1 + dpr2 + webkit + the 12 apps, tallied):
   `./fg gauntlet`
   (or piecewise: `./fg build` ; `./fg suite` ; `./fg suite --dpr=2` ; `./fg suite --browser=webkit` ; `./fg apps`)
2. **Both hard-fail gates stay green** (run against the fresh build):
   `bash Fizzygum-tests/scripts/end-of-cycle-audit/run-capstone-gate.sh`   (exit 0 = 0 careless pushes)
   `bash Fizzygum-tests/scripts/paint-readonly-audit/run-paint-readonly-gate.sh`
   The capstone should stay green by construction — this change *reduces* deferred pushes, never adds careless ones.
3. **Determinism soak (the proof), ~20 min** — rotates dpr/speed/shards, refuses a stale build:
   `cd Fizzygum-tests && caffeinate -i npm run torture -- --minutes=20`   (review: `cat .scratch/torture/REPORT.md`)
   Expected SAFE: orphans aren't painted to the world canvas (`preliminaryCheckNothingToDraw` ~:1984) and the
   settle is convergent, so intermediate orphan geometry cannot reach the asserted pixels.
4. **Targeted micro-test:** build a content-sizing widget as an orphan, do one public mutation, assert it
   reports content-fitted geometry **synchronously** (the I2 win). On green, **delete the flag** and inline
   the behavior; re-run the gauntlet once more.

**Phase 2 — per batch:** `./fg gauntlet` + both gates + a focused `caffeinate -i npm run torture -- --minutes=20`
after each batch; plus a micro-test asserting content-fitted geometry directly on `new Foo()` before any
public call or attach. **Construction-cost check:** count settles during a heavy build (a window with N
children) to confirm no O(N²) regression — internal multi-builds must stay on non-settling cores (the
`buildAndConnectChildren` wrap settles **once**, at the end).

> Recapture note: a benign Object-Inspector member-list shift can occur if a method is added to an
> inspected class; if an inspector test diffs, recapture it (`./fg recapture <name>`) — do not contort code.
> Commit/push only after an end-of-arc review and explicit owner approval (review-driven project).

---

## §8 — Risks (validated — overall LOW)

1. **63-test regression — does NOT apply.** That was a blanket `return if @isOrphan()` in `_invalidateLayout`
   which *suppressed orphan queueing*. This change keeps queueing and *adds* a synchronous flush —
   orthogonal failure mode (§2).
2. **Half-wired settle during construction (the top probe target).** Phase 1 activates
   `WindowWdgt.buildAndConnectChildren`'s settle mid-construction (`WindowWdgt` ~:105). Confirm the window's
   `@stack`/layoutSpec is wired by then (it extends `SimpleVerticalStackPanelWdgt`, set in `super`, so likely
   yes) and that no re-fit reads an unset spec — the orphan guard's comment (~:831) warns of a
   `getWidthInStack`-on-unset-`@stack` crash. If any constructor settles a half-wired widget, the fix is
   local: settle **last**, or keep that mid-build step on a core. The in-flush deferral already protects the
   framework rebuild-on-drop paths (they use `_buildAndConnectChildrenNoSettle`).
3. **Basement orphan settle — safe/cheap.** Basement widgets are fully built (re-home complete) and never
   painted; a public setter on one now settles its (invisible) subtree. No half-wired risk; cost is the
   detached subtree only. (Secondary probe: confirm nothing calls a public setter on basement contents in a
   hot path.)
4. **Re-entrancy — preserved** by the orphan-in-a-flush defer branch (§4).

---

## §9 — File:line touch-list

**Phase 1 (small, surgical):**
- `Fizzygum/src/basic-widgets/Widget.coffee`
  - `_settleLayoutsAfter` ~:803 — remove the standalone `if @isOrphan(): return coreThunk()` (~:816);
    move the orphan-defer into the in-flush check (~:826). Optional: update the throw string's
    "raw/silent setters" → "immediate (geometry) mutators".
  - `_settleLayoutsAfterBatch` ~:857 — drop the `@isOrphan() or` term from the end-of-batch gate (~:867).
- Temporary probe flag on `WorldWdgt` (`Fizzygum/src/WorldWdgt.coffee`, alongside the other layout flags
  ~:88–123) — removed before commit.

**Phase 2 (incremental sweep, ~40–50 constructors):** the pattern, applied per target widget:
- `Fizzygum/src/WindowWdgt.coffee` ~:436 — already the template (verify it settles correctly once activated;
  fold the trailing extent-set at ~:119 into the pre-settle core).
- Representative candidates to evaluate (build children / content-sized): `src/ButtonWdgt.coffee`,
  `src/basic-widgets/StringWdgt.coffee`, `src/basic-widgets/TextWdgt.coffee`,
  `src/SimpleVerticalStackPanelWdgt.coffee`, and the info-widgets / panel families. The exact set is
  produced by the Phase-2 scoping pass (identify constructors whose laid-out result differs from their
  constructor field-sets; skip fixed-size widgets).
- Reference / reuse (do not reinvent): `WindowWdgt.buildAndConnectChildren` /
  `_buildAndConnectChildrenNoSettle` (the template), `Widget._addNoSettle` and the immediate-mutator cores
  `_commitExtentAndNotify` / `_applyExtentAndNotify` (constructor building blocks), `commit 08bbb29d` (the
  prior constructor-core extraction to mirror).

**Do not touch:** `../Fizzygum-builds/**` (generated); the flush loop `WorldWdgt._recalculateLayoutsBody`
(already orphan-agnostic — relied upon, not changed); the in-flush rebuild-on-drop paths (already on cores).

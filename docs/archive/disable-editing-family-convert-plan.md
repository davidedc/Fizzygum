> **ARCHIVED — COMPLETE (2026-07-17 restructure).** All 8 phases COMPLETE (Phase 8 owner review/commit was the only gate remaining at time of writing).
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# disable/enable-editing family CONVERT — self-settling wrapper+core plan

**STATUS BOX (running status, updated per phase):**
- **Phase 1 (capstone-gate hardening) ✅ COMPLETE** (tests repo, uncommitted — held for end-of-arc). Added the `suite_rc`
  embedded-suite gate to `run-capstone-gate.sh` (was echoed, never gated — the two-time 2026-07-04 hole). Self-tested:
  a pure window-color pixel-break (0 careless pushes — the exact case the old gate passed) now trips the NEW block
  (exit 1, "embedded suite run failed", per-test detail lines printed). Fixed a self-introduced count bug (the tee'd
  `$SUITE_LOG` sat inside `$AUDIT` and inflated the `*.log` counters → moved it out; now `logs=167/167`). Clean baseline
  GREEN (167/167, 0 careless).
- **Drift found vs plan (re-grep, 2026-07-04):** (a) **thin-wraps gate wants the ONE-LINER** `@_settleLayoutsAfter =>
  @_xNoSettle args` (check-thin-wraps.js `rest.length===1`) — the plan §3 / prior memory said "multi-line required" but
  that is STALE; the current gate FAILS multi-line. Using the one-liner (matches the `collapse` precedent). (b)
  `createToolsPanel` has **4** StretchableEditableWdgt subclass overrides (Patch/Dashboards/SimpleSlide + **Reconfigurable
  PaintWdgt**), not 3. (c) `addMany` IS a discovered wrapper (ToolPanelWdgt) → routing needs proper `_addManyNoSettle`
  cores (a `_addNoSettle` loop mis-targets ScrollPanelWdgt's `@contents`); those cores SCHEDULE (`@_invalidateLayout`),
  NOT apply. (d) `createToolsPanel`'s 4 callers are all cores → renaming to `_createToolsPanelNoSettle` with NO public
  wrapper (thin-wraps skips a core with no twin). (e) **stopEditing lint blind-spot** (literal, non-transitive wrapper
  discovery misses `stopEditing`, which self-settles only via `caret.fullDestroy()`) — BANKED as end-of-arc backlog, not
  fixed here.
- **Phase 2 (disable-side convert, 7 classes) ✅ COMPLETE** (Fizzygum, uncommitted). All 7 `disableDragsDropsAndEditing`
  split into one-liner wrapper + `_disableDragsDropsAndEditingNoSettle` core; cascades routed core→core; `@toolsPanel.destroy()`
  → `_destroyNoSettle()` (StretchableEditable/SimpleDocument); base `world.stopEditing()` → `world._stopEditingNoSettle()`;
  tails kept in cores. Build clean (layering 0 violations, thin-wraps OK, dead-methods 0-new). Witnessed path
  `macroDegreesConverterFourWayDrive` byte-exact; capstone gate careless=**0** suite-wide. **ONE benign divergence:**
  `macroDuplicatedInspectorDrivesCopiedTargetOnly` img2/3 — the inspected RectangleWdgt's member list gained the inherited
  `_disableDragsDropsAndEditingNoSettle`, shifting the Properties-list scroll ~½ row (deterministic, diff 100% inside the
  member list; owner eyeballed the ref|live|diff composites 2026-07-04, confirmed benign). **Recapture DEFERRED to Phase 5**
  (Phase 3 adds `_enableDragsDropsAndEditingNoSettle` to Widget → same list shifts again; recapture once, webkit-verified).
- **Phase 3 (enable-side convert + createToolsPanel cores) ✅ COMPLETE** (Fizzygum, uncommitted). All 7 `enableDragsDrops
  AndEditing` split (wrapper + core, cascades core→core). `createToolsPanel` → `_createToolsPanelNoSettle` on 6 classes (no
  public wrapper — all callers are cores); routed `@add`→`_addNoSettle`, `@toolsPanel.disable`→core, `@toolsPanel.addMany`→
  new `_addManyNoSettle` cores (ToolPanelWdgt loops `_addNoSettle`; ScrollPanelWdgt forwards `@contents._addManyNoSettle` +
  SCHEDULEs, public `addMany` marked `# thin-wrap-exempt` as a synchronous endpoint). SimpleDocument's 10 orphan
  `@toolsPanel.add` LEFT public (glassbox-wrapping; orphan-safe). **ReconfigurablePaint toggle balloon** (owner chose
  "Full + witness test"): `@pencilToolButton.toggle()` reaches a settle via synchronous escalation → SwitchButtonWdgt's
  self-settling `mouseClickLeft`; FIXED by the sibling-shape reorder (attach `@toolsPanel` LAST, so the toggle's radio-click
  runs on an orphan-ROOT subtree → the switch's settle defers; radio logic reads no attachment geometry + stops at the
  holder — both owner-confirmed). Build clean (layering 0 violations / 39 wrappers, thin-wraps OK, dead-methods 0-new; the
  lone `[H]` is pre-existing `loadWorldSnapshot`, out of scope). Capstone: careless=**0** suite-wide (enable+disable); only
  the deferred inspector recapture fails. ReconfigurablePaint has NO existing test → **Phase 7 witness test** verifies it.
- **Phase 4 (comment/doc sweep) ✅ COMPLETE.** Updated: StretchableEditableWdgt `_buildAndConnectChildren` comment;
  DegreesConverterApp "must precede world.add" → DISSOLVED; hover-resync §6 latent-tail + gate-weakness marked ✅ RESOLVED
  (pointer, history kept); layout-system-architecture-assessment.md one bracketed follow-up pointer. Historical audit docs
  (end-of-cycle-flush-inventory/catalog, etc.) LEFT AS-IS per owner steer (don't rewrite point-in-time history).
- **Phase 5 (verification battery) ✅ COMPLETE.** `fg gauntlet` byte-exact dpr1/dpr2/webkit (168 tests) + apps +
  tiernaming + settle; hardened capstone careless=**0** over a passing suite; paint-readonly 0 paint-time schedules;
  dpr2/fastest/shards=8 torture deterministic (2 clean rounds; one 7/8 shard-drop was infra, failed:0). The single benign
  inspector recapture (`macroDuplicatedInspectorDrivesCopiedTargetOnly`, member list +2 inherited `_*NoSettle`) done
  dpr1+2, webkit-verified, owner-eyeballed before/after.
- **Phase 6 (capstone → `fg gauntlet`) ✅ COMPLETE.** Added the `capstone:end-of-cycle-audit/run-capstone-gate.sh` leg to
  the umbrella `fg` gauntlet gate loop (alongside tiernaming + settle). Validated end-to-end by the final gauntlet run.
- **Phase 7 (witness test) ✅ COMPLETE — and it EARNED ITS KEEP.** `SystemTest_macroDrawingsMakerReEnableEditing` (the
  first ReconfigurablePaint test ever) open→disable→re-enable **caught a real, deterministic DISABLE-path throw the convert
  had introduced**: `@toolsPanel.unselectAll?()` fires a synthetic `w.toggle()` → SwitchButtonWdgt self-settling
  `mouseClickLeft` → threw mid-flush (unwitnessed by every existing test; Patch/Dashboards/SimpleSlide's ScrollPanel
  toolsPanel has no `unselectAll`). Fixed by **detach-then-teardown** (`removeFromTree` the attached toolsPanel BEFORE
  unselectAll → its root is orphan → the settle defers; un-inject still lands on the attached overlayCanvas). Test asserts
  `image_0 == image_2` (disable→re-enable pixel-IDEMPOTENT). Refs captured dpr1+2, webkit-verified.
- **Phase 8:** end-of-arc review + owner-gated commits (pending).
- **⚠ BACKLOG — transitive-settle lint blind spot (TWO instances now).** `check-layering` discovers settling wrappers
  LITERALLY + NON-transitively (a method whose OWN body calls `@_settleLayoutsAfter`). Two family cores call methods that
  settle only TRANSITIVELY, so an own-body grep passes them but they throw at runtime in-flush on an attached receiver:
  (1) `world.stopEditing()` (settles via `caret.fullDestroy()`); (2) `@toolsPanel.unselectAll?()` (settles via
  `w.toggle()` → `mouseClickLeft`). Both were caught by runtime/witness, not the lint. A transitive closure was already
  assessed + REJECTED as intractable (check-layering.js [G] comment). Left as a documented boundary; the runtime
  guard + witness tests are the backstop. (Not fixing the lint here — owner-directed.)

## §0 What this is

Convert the `disableDragsDropsAndEditing` / `enableDragsDropsAndEditing` **family** (7 classes) to the
codebase's standard **self-settling wrapper + `_*NoSettle` core** idiom, eliminating the last known family
of public mutators that leave bare deferred `@_invalidateLayout()` pushes. End state: **call-site ordering
vs `world.add` stops mattering** (today it is delicate — see §1), every entry point self-settles once, the
end-of-cycle capstone gate stays green *by construction*, and the gate itself is hardened (it currently
ignores embedded test failures) and wired into the standard gauntlet.

This plan is **fully self-contained**: all context, verified code facts, and history are embedded. No other
conversation context exists.

- Repo layout: `Fizzygum-all/` (umbrella, NOT a git repo) holds sibling git repos `Fizzygum/` (source),
  `Fizzygum-tests/` (SystemTests + gates), `Fizzygum-builds/` (generated — never edit). The `./fg` wrapper
  at the umbrella root is LOCAL tooling (committed to no repo).
- Baseline: `Fizzygum` master `c9720d45` (2026-07-04), `Fizzygum-tests` master `77740a781`, both clean.
  **All `file:line` refs below were verified at that baseline. Method names are authoritative; line numbers
  drift — re-grep before every edit.** Other doc-plans are in flight in this repo (a coalesced-rename plan,
  a dataflow spec) — if names like `*Coalesced` look different from this plan's quotes, re-grep and adapt;
  the disable/enable family is untouched by those.

## §1 Background — why this family is fiddly, and what happened on 2026-07-04

**The system invariant** (canonical: `docs/archive/layout-system-architecture-assessment.md` §2.2/§2.7): every
public mutator **self-settles** — it wraps a non-settling core in `_settleLayoutsAfter`, which runs one
`recalculateLayouts()` on return. Construction is exempt *automatically*: a wrapper reached on an ORPHAN
defers in-flush and flushes at top level (orphan-settledness), so "build off-world, settle on attach" needs
no care from the caller. Consequence: **for a converted method, calling it before or after `world.add` are
BOTH legal.** Nobody thinks about ordering — except for this family.

**This family is a fossil.** Its members predate that convention: they are public mutators that neither
self-settle nor have cores; several end with a bare `@_invalidateLayout()` (the pre-drawdown "schedule a
re-fit, let the end-of-cycle flush drain it" idiom). For that shape, the only legal call site is on an
orphan — hence the delicate "disable must come BEFORE `world.add`" rule that motivated this plan. The
end-of-cycle drawdown campaign (2026-06, `end-of-cycle-flush-drawdown-plan.md`) hunted exactly this pattern
but its audit is RUNTIME-only: the one member it *witnessed* (`ScrollPanelWdgt`'s) had a **redundant** push
→ ELIMINATE'd (tombstone comment at `ScrollPanelWdgt.coffee` ~:875), and no convert lattice was ever built.
The other members sat latent, unwitnessed by any test.

**The 2026-07-04 history (the hover-resync session — full record: `docs/archive/hover-resync-after-flush-plan.md`
§6 and its STATUS BOX):**
- Running the capstone gate (NOT part of `fg gauntlet`) surfaced 2 careless pushes on
  `SystemTest_macroDegreesConverterFourWayDrive` — proven pre-existing (identical with the day's other
  change reverted). Root: `StretchableEditableWdgt.disableDragsDropsAndEditing` ends in a bare
  `@_invalidateLayout()`; witnessed because `DegreesConverterApp.buildWindow` called it AFTER `world.add`.
- **ELIMINATE falsified**: deleting the push (per the ScrollPanelWdgt precedent) diverged the converter
  test's suite run (not image-verified — the pivot happened before a dump) ⇒ the re-fit is load-bearing.
- **Inline whole-body wrap falsified**: wrapping the existing body in `_settleLayoutsAfter` CRASHED —
  `UNCAUGHT ERROR: a public geometry setter was reached during a layout flush/pass` — because the body
  calls `@toolsPanel.destroy()`, itself a self-settling wrapper ⇒ guaranteed nested-settle throw. **This is
  a falsification of the SHAPE, not of converting**: the proper idiom (wrapper + core, with the body's
  internal self-settling calls routed to THEIR cores) was never attempted.
- **What landed** (`c9720d45`): a call-site reorder — `DegreesConverterApp.buildWindow` now disables BEFORE
  `world.add` (orphan push, gate-excluded by classification), byte-identical. Correct but fragile: the
  ordering constraint survives as a comment ("Keep this BEFORE world.add"), and the family keeps latent
  careless tails on every unwitnessed path. THIS plan is the proper fix.

**Why a proper convert should be pixel-neutral (expectation, to be verified, never asserted):** paint runs
once per frame after all events, so settle-now vs ride-the-EOC-flush is byte-identical when the mutation
*sequence* is preserved (the engine's own coalescing-measurement argument). The one verified pixel
divergence (the ELIMINATE) removed the re-fit entirely — a different thing. Cores-calling-cores preserves
sequence; the wrapper only adds a flush at the tail.

## §2 Verified inventory (2026-07-04 @ `c9720d45` — re-grep everything)

### 2a. The 7 family members and their shapes

| Class (file) | disable | enable | body shape |
|---|---|---|---|
| `Widget` (`basic-widgets/Widget.coffee` ~:3483 / ~:3453) | flags + `disableDrops()` + per-child `lockToPanels()` / `blendInWithPanelColor?()` / `isEditable=false` + `world.stopEditing()` when caret targets a child; NO tail push | mirror (unlock/contrast/`enableDrops`); NO tail push | the leaf "local work" both climbs bottom out in (`super @`) |
| `ScrollPanelWdgt` (~:865/:855) | flags + `disableDrops` + descend `@contents.disable… @`; push already ELIMINATE'd (tombstone ~:875) | mirror | descend-to-contents |
| `SimpleVerticalStackScrollPanelWdgt` (:55/:45) | climb `@parent.disable… @` iff `@parent.coordinatesDragsDropsAndEditingForChildren?()` and parent ≠ triggeringWidget, else `super @` | mirror | climb-or-super |
| `StretchablePanelWdgt` (:114/:104) | climb-or-super (same shape) | mirror | climb-or-super |
| `StretchableWidgetContainerWdgt` (:201/:191) | climb-or-super (same shape) | mirror | climb-or-super |
| `StretchableEditableWdgt` (:163/:126) | `makePencilClear` + flag + `@toolsPanel.unselectAll?()` + **`@toolsPanel.destroy()`** + descend `@stretchableWidgetContainer.disable… @` + **bare `@_invalidateLayout()` tail (:174)** | `makePencilYellow` + flag + **`@createToolsPanel()`** + descend | the culprit class; `createToolsPanel` is EMPTY here (:48), overridden by subclasses |
| `SimpleDocumentWdgt` (`apps/` :146/:137) | `makePencilClear` + **`@toolsPanel.destroy()`** + flag + descend `@simpleDocumentScrollPanel.disable… @` + **bare `@_invalidateLayout()` tail (:154)** | flag + **`@createToolsPanel()`** + descend | second culprit |

### 2b. ALL bare-tail `@_invalidateLayout()` pushes in the family (the careless set)

1. `StretchableEditableWdgt.disableDragsDropsAndEditing` **:174** (the witnessed one)
2. `SimpleDocumentWdgt.disableDragsDropsAndEditing` **:154**
3. `SimpleDocumentWdgt.createToolsPanel` **:123** tail (enable path: builds toolbar with public
   `@toolsPanel.add …` ×10, `@add @toolsPanel`, then `@toolsPanel.disableDragsDropsAndEditing()` — note:
   called AFTER the add, i.e. on an attached toolsPanel — then flag + bare push)
4. `PatchProgrammingWdgt.createToolsPanel` **:26** tail (`apps/PatchProgrammingWdgt.coffee` :10 — public
   `@toolsPanel.addMany […]`, `@toolsPanel.disableDragsDropsAndEditing()` on the still-orphan toolsPanel,
   `@add @toolsPanel`, flag, bare push)
5. `DashboardsWdgt.createToolsPanel` **:44** tail (`apps/DashboardsWdgt.coffee` :10 — same shape as 4)

(1)–(2) fire carelessly on any attached off-settle disable; (3)–(5) fire carelessly on any attached
off-settle **enable** (the edit-button toggle). All are unwitnessed by tests today except (1)'s
DegreesConverter site, now reordered to orphan time.

### 2c. Entry points (who calls the family)

- **Interactive (attached, off-settle — the paths that NEED self-settling):**
  `editButtonPressedFromWindowBar` on `StretchableEditableWdgt` :109, `SimpleDocumentWdgt` :125,
  `PanelWdgt` :182 (base-Widget verbs — already push-free); the "disable editing" menu item
  (`SimpleVerticalStackScrollPanelWdgt` :36).
- **Construction (orphan at call time — need NO change; wrapper flushes-or-defers automatically):** ~20
  sites — the `*ToolbarCreatorButtonWdgt`s, `info-widgets/*` and `apps/*` `simpleDocument.disable…()` /
  `toolsPanel.disable…()` calls, `SimpleSlideWdgt` :93, `SampleDashboardApp` :120, `SampleSlideApp`
  :49/:73, and `DegreesConverterApp` :~100 (disable-before-add since `c9720d45`).
- **Intra-family:** the climb/descend cascade of §2a, plus `createToolsPanel`'s
  `@toolsPanel.disableDragsDropsAndEditing()` calls (item 3 is on an ATTACHED receiver).
- Executor MUST re-run this census (`grep -rn 'able(DragsDropsAndEditing' src/ --include='*.coffee'`) and
  classify any NEW caller before editing.

### 2d. Plumbing that already exists (verified — this is what makes the convert mechanical)

- `Widget.destroy` = wrapper over **`_destroyNoSettle`** (`Widget.coffee` :523/:525) — comment explicitly
  blesses in-settle core use. Routes the crash-causing `toolsPanel.destroy()`.
- `world.stopEditing` = wrapper over **`_stopEditingNoSettle`** (`WorldWdgt.coffee`, grep it) — routes the
  base-Widget body's caret teardown (`caret.fullDestroy()` → `_fullDestroyNoSettle` inside the core lane).
- **`_addNoSettle`** exists (the all-constructors-settle campaign); check for an `addMany` core
  (`_addManyNoSettle`) — if absent, loop `_addNoSettle` in the core.
- `disableDrops` / `enableDrops` / `lockToPanels` / `unlockFromPanels` = pure flag-setters (verified
  bodies) — settle-neutral, usable in cores as-is. `makePencil*` / `blendInWithPanelColor` /
  `contrastOutFromPanelColor` are appearance-layer — verify (expect `@changed()`-only); same for
  `toolsPanel.unselectAll?()`.
- **Lint auto-discovery:** `check-layering.js` rule [G] **discovers** settling wrappers by scanning for
  `@_settleLayoutsAfter` in method bodies (`discoverSettlingWrappers`, ~:426) — converting the family
  auto-registers the new wrappers; NO manual list edit. Low-level code calling the new wrappers gets
  auto-flagged (that's the discipline working). The thin-wrap gate requires the **MULTI-LINE** wrap form
  (`@_settleLayoutsAfter =>` newline-indented core call — a one-liner parses as empty body and FAILS).
  Guards live in CORES, not before the settle (rule [H]; `# early-return-sanctioned` where needed — see
  `_collapseNoSettle` for the worked precedent of exactly this conversion shape).

### 2e. The capstone gate's two weaknesses (verified in `run-capstone-gate.sh`)

`Fizzygum-tests/scripts/end-of-cycle-audit/run-capstone-gate.sh` captures the suite runner's exit code into
`suite_rc` and *echoes* it (:45) but **never gates on it** — its only exits are coverage-gap (:51) and
careless-count (:64). Bitten twice on 2026-07-04: exit 0 over a pixel-diverging test AND over a crashing
test. Second hole: the gate is not part of `fg gauntlet` (the gate loop at `fg` :80 runs only
`tiernaming` + `settle`), which is why the family's careless push sat latent for a day after the converter
test landed.

## §3 Target design

**Every family member gets the standard split** (disable AND enable; shown for one, all 7 identical in
shape — climb/descend calls route CORE→CORE):

```coffee
# public: self-settles once (any entry point, attached or orphan — ordering vs world.add no longer matters)
disableDragsDropsAndEditing: (triggeringWidget) ->
  @_settleLayoutsAfter =>
    @_disableDragsDropsAndEditingNoSettle triggeringWidget

_disableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
  if !triggeringWidget? then triggeringWidget = @      # arg default + idempotency guard live in the CORE
  return if !@dragsDropsAndEditingEnabled              # early-return-sanctioned: idempotency predicate
  … body as today, with these routings:
  @toolsPanel._destroyNoSettle()                       #   (was @toolsPanel.destroy() — the crash source)
  world._stopEditingNoSettle()                         #   (base Widget body; was world.stopEditing())
  @stretchableWidgetContainer._disableDragsDropsAndEditingNoSettle @   # cascade: core→core
  @_invalidateLayout()                                 #   tails STAY — drained by the wrapper's settle
```

- `createToolsPanel` (3 subclass overrides + `SimpleDocumentWdgt`'s) becomes wrapper +
  `_createToolsPanelNoSettle` core: internal `add`/`addMany` → `_addNoSettle` (loop if no addMany core);
  the `@toolsPanel.disableDragsDropsAndEditing()` calls → `…NoSettle()`; tail pushes stay in cores. The
  construction call sites (`_buildAndConnectChildrenNoSettle` :188 calls `@createToolsPanel()`) switch to
  the core. `createNewStretchablePanel` (called from `_reactToChildPickedUp`, a settle-neutral callback —
  rule [J]) — check whether it needs the same split; its `@add` self-settles today post-construction.
- Existing comments to update: `StretchableEditableWdgt` ~:176 ("The core's
  createNewStretchablePanel/createToolsPanel add to ORPHANS…") — the deferral story changes;
  `DegreesConverterApp` ~:94–99 — the "Keep this BEFORE world.add" constraint DISSOLVES (rewrite the
  comment: ordering now free; keep the current order, it's fine); `hover-resync-after-flush-plan.md` §6
  "next-fixer prescription" — mark superseded by this plan.
- **Do NOT reorder any call site** as part of this arc (behaviour-neutrality: sequences preserved, only
  tail-settles added).

**Fallback (pre-authorized):** if the ENABLE side balloons (createToolsPanel core-routing surprises),
split: land disable-side alone (Phases 2 → 5) and file enable as a follow-up in this doc's STATUS BOX.
Never ship a half-converted single method.

## §4 Phases

Owner workflow (standing): run phases straight through, verifying per phase; ONE end-of-arc review; **never
commit/push without presenting summary + message and getting explicit approval**; upfront ETA + ~5-min
status on long ops. Two hard lessons from 2026-07-04, binding here: **(a) no conclusion goes into a comment
or doc before its verification has actually run** (bitten twice that day); **(b) after two falsified fix
shapes, STOP and get evidence** (probe/dump) before a third.

### Phase 1 — harden the capstone gate + baseline it (tests repo, ~20 min)

1. In `run-capstone-gate.sh`, after the coverage gate: fail on embedded suite failures —
   `if [ "$suite_rc" -ne 0 ]; then echo "✗ CAPSTONE GATE FAILED — embedded suite run failed (exit=$suite_rc) …"; exit 1; fi`
   (and surface any per-test FAIL lines from the logs in the message).
2. Self-test the hardening: plant a deliberate test-breaking change, confirm gate exits 1 with the new
   message, revert. (The gate's own careless-detection self-test recipe is in the script's header.)
3. Run the hardened gate on the CLEAN baseline: must be GREEN (post-`c9720d45` state: 0 careless pushes,
   suite passing). Commit candidate #1 (tests repo) — hold for end-of-arc.

### Phase 2 — disable-side convert (~1–2 h)

Wrapper+core split on all 7 members' `disableDragsDropsAndEditing` per §3, cascade core→core, the two
routings (`_destroyNoSettle`, `_stopEditingNoSettle`), tails kept in cores. `./fg build` after (expect
[G] to auto-discover the new wrappers; fix any [A]–[R] complaint it raises — the lint IS the checklist).
Quick probe: run `SystemTest_macroDegreesConverterFourWayDrive` standalone (byte-identity signal) + the
hardened capstone gate.

### Phase 3 — enable-side convert incl. createToolsPanel cores (~1–2 h)

Same split for `enableDragsDropsAndEditing` ×7 and `createToolsPanel` (wrapper + core; `_addNoSettle`
routing; the attached `toolsPanel.disableDragsDropsAndEditing()` call in `SimpleDocumentWdgt.
createToolsPanel` routes to the core). Build + capstone again.

### Phase 4 — comment/doc sweep (~20 min)

The three comment updates listed in §3, plus: `docs/archive/layout-system-architecture-assessment.md` needs NO
structural change (the family becomes ordinary §2.2 citizens), but if it names this family anywhere as an
exception, fix it (grep `disableDragsDropsAndEditing` in docs/).

### Phase 5 — verification battery (~30–45 min; announce ETA, status every ~5 min)

`pkill -f "Chrome for Testing"` before each suite run. In order:
1. `./fg gauntlet` — expect **byte-exact, zero diffs** (the §1 pixel-neutrality argument, now tested).
2. Hardened capstone gate — GREEN (0 careless + suite pass) — this is the arc's headline proof.
3. Paint-readonly gate (`scripts/paint-readonly-audit/run-paint-readonly-gate.sh`) — unchanged, cheap.
4. Determinism torture, 2 rounds of the hunter config:
   `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/run-all-headless.js --dpr=2 --speed=fastest --shards=8`
   — pass = exit 0, all shards, failed:0, no `RECALC_NONCONVERGENCE`.
- **Failure rubric:** a test failing with ZERO failed screenshots = uncaught error (crash/stall) — expect a
  nested-settle throw from a caller the census missed; get the stack (run standalone with `LOG_FILE`), route
  that caller to the core, re-run. A PIXEL diff → STOP; dump images
  (`node scripts/run-macro-test-headless.js SystemTest_<name> --dump-failures`), show the owner
  before/after — **no recapture without owner eyeball**, and any approved recapture must be re-verified
  under `--browser=webkit` (a recapture bakes in whatever the frame shows; only the webkit leg surfaces a
  baked-in crash).

### Phase 6 — wire the capstone gate into `fg gauntlet` (umbrella-local, ~10 min)

In `/Users/davidedellacasa/code/Fizzygum-all/fg`, gauntlet branch (~:80): add
`"capstone:end-of-cycle-audit/run-capstone-gate.sh"` to the gate loop alongside `tiernaming` and `settle`.
NOTE: `fg` is LOCAL workspace tooling — this edit is committed to NO repo (the umbrella is not a git repo).
Verify with a full `./fg gauntlet` (now includes the capstone leg; ~+2 min).

### Phase 7 (OPTIONAL — ask the owner before doing it) — witness test

A macro test toggling `editButtonPressedFromWindowBar` on a `PatchProgrammingWdgt` (or `SimpleDocumentWdgt`)
window — the interactive path that stayed unwitnessed for a month. Author per the `/author-macro-test`
skill in `Fizzygum-tests` (framework helpers: `Fizzygum/src/macros/CLAUDE.md`); new references captured
dpr1+2 + webkit-verified. Tests-repo commit.

### Phase 8 — end-of-arc review + commits (owner-gated)

Full diff re-read; present summary + verification evidence + proposed messages, then WAIT. Commits:
`Fizzygum` (the convert + comments + this plan's STATUS BOX + hover-plan §6 pointer), `Fizzygum-tests`
(gate hardening; + witness test if Phase 7 ran). Message files via `git commit -F` (backticks/`$()` in
`-m` get command-substituted — never). Push only when told.

## §5 Quick reference

- `fg` (from `/Users/davidedellacasa/code/Fizzygum-all`): `./fg build` · `./fg suite [--dpr=2|--browser=webkit]` ·
  `./fg gauntlet` · `./fg test <name>` · `./fg recapture <name>`. Raw runner flags: `--shards=N` (default 8),
  `--dpr=N`, `--speed=normal|fast|fastest`, `--browser=chrome|webkit`. Always `cd` with absolute paths per
  repo if not using `fg` (a bare build from the umbrella tests a STALE artifact; a build+test chained in one
  `&&` hits MODULE_NOT_FOUND; a PreToolUse guard blocks some wrong-cwd forms — and misparses multi-line
  `cd` commands, so keep commands single-line).
- Probes: enqueue-stack `PRELUDE_JS=scripts/end-of-cycle-audit/eoc-production-probe.js LOG_FILE=<path> node
  scripts/run-macro-test-headless.js SystemTest_<name>` (from `Fizzygum-tests`); image dump
  `--dump-failures`.
- Prereqs (installed): global `coffee`/`terser`/`python3`; Puppeteer in `Fizzygum-tests` (`npm i`);
  playwright webkit. `nil` means `undefined`. Never edit `Fizzygum-builds/**`.

## §6 Risks & falsification protocol

- **Highest-probability failure:** a nested-settle throw from a family caller the census missed (an
  in-settle attached call that used to silently defer). That's the invariant WORKING — the fix is routing
  that caller to the core, not weakening the wrapper. The Phase 5 rubric localizes it in minutes.
- **Pixel divergence** anywhere = STOP + owner eyeball (§Phase 5 rubric). Do not iterate shapes past two
  falsifications; bring evidence to the owner instead (2026-07-04 lesson).
- **Scope guard:** no call-site reorders, no renames, no touching the `*Coalesced` family or the dataflow
  plans in flight. If disable lands but enable fights back, take the §3 fallback and record it here.
- If the whole convert is somehow falsified (e.g. an irreducible ordering dependency surfaces), REVERT
  fully, record the evidence in this STATUS BOX, and leave `c9720d45`'s call-site reorder as the resting
  point — it is correct, just fragile.

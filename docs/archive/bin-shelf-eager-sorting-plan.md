# Bin/Shelf split with eager sorting

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Status: AUTHORED 2026-07-22, owner-approved direction (owner chose the "shelf" name and
asked for eager sorting: "Can we sort stuff out right away?").

> **STATUS 2026-07-23 — ALL FIVE PHASES IMPLEMENTED (as-built record; see the arc's
> commit for the diff).** Phase 0 spike: the storage-aware re-derivation held on the
> FIRST shape — 33 checks, closed ≡ open ≡ re-closed incl. chains; premise confirmed
> (today's classifier closed-bin breaks exactly the chained case). As-built deviations,
> all gate-forced or guard-discovered:
> - **Methods land WITH their callers** (dead-method + call-separation build gates):
>   `isInShelf` never materialized (`isInStorage` walks both containers directly),
>   `isDirectlyInShelf` was born in Phase 3 (its first cross-object caller:
>   `bringUpTarget`), and `TreeNode.isInBin`/`isInBinButReachable` are DELETED
>   (callerless once `doGC` folded into the sorter).
> - The classifier + drain live on the **`StorageSorter` collaborator**
>   (`world.storageSorter`, the `@dataflow` pattern); the classifier is private
>   (`_runClassifier`) — outside the drain, placement is read via the containers'
>   `holds()`. `BinWdgt.doGC` is gone.
> - **Two additional chokepoints beyond §1's list**: the bin's child-add relay AND a new
>   symmetric child-REMOVED relay (`PanelWdgt._reactToChildRemoved` now notifies the
>   scroll-holder BEFORE its orphan guards) — they cover drops into / pickups out of the
>   OPEN bin window, which the plan's event list missed.
> - **Tier A immediately caught two real defects** (§4 Phase 2's "born guarded" clause
>   earned its keep within minutes): (1) `IconicDesktopSystemShortcutWdgt.destroy` was
>   BYPASSED by every bulk destroy — core chains (`_fullDestroyNoSettle`) never call the
>   public wrapper — so bulk-destroyed shortcuts had leaked in the tracker for years;
>   the bookkeeping moved to a `_destroyNoSettle` override. (2) The drain's own bin
>   arrivals echoed through the child-add relay into a mid-drain re-mark + (transitional)
>   reclassification that overwrote the marks the drain was reading; fixed with the
>   sorter's `@_draining` echo-suppression (the dataflow no-re-entry rule).
> - Fixed en passant: `BinWdgt.empty` was homepage-excluded while the homepage-shipping
>   snapshot teardown calls it (a latent "open from file…" crash in `--homepage` builds);
>   `_resetWorldNoSettle` (not just the snapshot teardown) also empties the shelf.
> - Phase 5's prelude hooks **`resetWorld` ENTRY** (= the finished test's end state,
>   pre-teardown); a shard's LAST test is audited by Tier A only (no following reset) —
>   the census's end-of-battery sweep covers a battery end explicitly.
> Verification: probes green (spike 33; oracle probe rewritten, 23 checks incl.
> re-reference lifts bin→shelf and Empty-bin spares the shelf); both rigs green
> (`R.shelfCount` added); presuite paint PASS + dpr1 264/265 — the single failure is the
> known benign inspector member-list churn (recaptured via the gated recapture); Tier B
> full-suite profile EMPTY (zero moves, zero residue). `fg storage` wired (umbrella-local)
> → the gauntlet is 13 legs.

**Mandate:** eliminate the store/view entanglement at the root. Today the bin container
physically holds BOTH lost items and parked (referenced, revivable) items, and the view
hides the parked ones — visibility filters, `show()` companions on every revival path, and
a visibility-aware scroll fit all exist only to paper over that. The end state: **two
containers with a standing invariant — everything on the SHELF is reachable, everything in
the BIN is lost, at all times** — maintained eagerly at the reachability-changing events,
not lazily at bin-open. No view-time classification, no hidden residents, no half-measures.

Line numbers below were verified 2026-07-22 and WILL drift — the quoted method names and
code snippets are authoritative; re-grep before trusting any `file:line`.

---

## §0 Orientation

Fizzygum (repo `Fizzygum/`, CoffeeScript, one class per file, no module system, built by
`./build_it_please.sh` into `../Fizzygum-builds/latest`) is a canvas "web OS". Verification
runs through the umbrella `fg` wrapper (`/Users/davidedellacasa/code/Fizzygum-all/fg`).
Read the root and `Fizzygum/CLAUDE.md` first.

**Immediately-prior arcs (2026-07-22, all pushed):**
- Basement → Bin conversion (`docs/archive/basement-to-bin-plan.md`, Fizzygum `d744139e`,
  Fizzygum-tests `4c5e2787f`): unpinned pop-ups destroy on dismissal; `doGC` marks
  world-slot furniture reachable; permanent lost-only view + confirmed Empty bin; full
  Bin rename; TrashcanIconWdgt deleted.
- Bin follow-up fixes (Fizzygum `57a7eaf4`): BinWdgt fills its window
  (`FrameContentLayoutSpec DONT_MIND`), `subWidgetsMergedFullBounds` skips invisible
  children (honest scrollbars), `ScrollPanelWdgt.setContents` destroys scaffold instead of
  binning it.

**The smell this plan removes** (owner-articulated): parked "disk" items live INSIDE the
bin container as hidden residents, and everything gets lumped into the bin at close time,
only sorted out when the bin is opened. The scrollbar fix above is honest about it: it is
"hide the junk better" — a symptom patch over the store/view conflation.

**Critical reframe (don't bury this):** reachability does not change spontaneously. It
changes at a SMALL set of events, and they all funnel through chokepoints we own: (a) a
figure is closed (enters storage), (b) a reference registers into / unregisters from
`world.widgetsReferencingOtherWidgets` (exactly 3 mutation sites, all in
`IconicDesktopSystemShortcutWdgt`), (c) a world slot field is written (app launch /
snapshot teardown). Hook those events to mark a pending re-sort, drain it ONCE per world
cycle (the dataflow-station precedent), and the invariant holds continuously — the user
sees a deleted shortcut's document appear in the bin the same cycle, without opening
anything.

**The one real piece of engineering risk:** `BinWdgt.doGC` currently carries the
precondition "the BinWdgt is on the desktop" — its pass 1 discards ORPHAN references as
unreachable, and a reference resting inside a CLOSED (off-tree) bin has root == the bin
widget, so `isOrphan()` is true and pass 1 wrongly swallows it; only the bin being
windowed (in-tree) makes its residents non-orphan. Eager sorting runs with everything
closed, so pass 1 must become STORAGE-AWARE (see Phase 0). Nice side effect: this retires
a pre-existing wart — `_reactToChildAddedInScrollPanel` already runs `doGC` with the bin
closed today and silently misclassifies chained references until the next open.

---

## §0.5 Cold-execution protocol

1. Read this doc top to bottom. Then, in the live tree: `src/BinWdgt.coffee` (all of it),
   `src/IconicDesktopSystemShortcutWdgt.coffee`, `TreeNode.isOrphan` /
   `isInBin` / `isDirectlyInBin` / `isInBinButReachable` / `markItAndItsParentsAsReachable`
   (`src/basic-data-structures/TreeNode.coffee`), `Widget._closeNoSettle` /
   `_createReferenceAndCloseNoSettle` / `createReference` (`src/basic-widgets/Widget.coffee`),
   `FrameWdgt._saveOrAskThenCloseCitizen`, `PanelWdgt.makeFolder`,
   `WorldWdgt.doOneCycle` (the station sequence) + `_teardownForSnapshotLoadNoSettle` +
   `_resetWorldNoSettle` + `anyReferenceToWdgt`, `Serializer.serializeWorld` (roots +
   `section.bin`) + `WellKnownObjects`, and `src/boot/globalFunctions.coffee` (`startWorld`,
   `world.binWdgt = new BinWdgt`).
2. Re-verify every §1 claim by grep before coding — this doc's line refs are 2026-07-22.
3. Execute phases IN ORDER. **Phase 0 is a gating spike**: if the off-screen classification
   re-derivation does not hold up, STOP and report to the owner before writing any product
   code.
4. Gate every phase with §7's commands. Never edit src mid-suite. Long runs via
   `run_in_background: true`; never foreground-poll.
5. Ask before any commit/push (standing owner preference). One end-of-arc review at the
   end, not per-phase.

---

## §1 Exact current state (all verified 2026-07-22, post-`57a7eaf4`)

### The reference tracker — the eager-event chokepoints

- `world.widgetsReferencingOtherWidgets` (WorldWdgt:346, a prototype-level `new Set`).
  EXACTLY THREE mutation sites, all in `src/IconicDesktopSystemShortcutWdgt.coffee`:
  - ctor (`world.widgetsReferencingOtherWidgets.add @`, line ~32) — NB the shortcut is
    registered BEFORE it is attached anywhere (an orphan at this instant; its attach
    follows in the same gesture/batch). THIS is why per-event immediate sorting is wrong
    and the drain must be end-of-cycle (§4 Phase 2).
  - `destroy` (`...delete @`, line ~50) — fires from any destroy path incl. Empty bin and
    bulk teardowns (`fullDestroyChildren` recursion), so the hook MUST be cheap
    (mark-pending only).
  - `alignCopiedWidgetToReferenceTracker` (`...add cloneOfMe`, line ~53) — the duplication
    path.
  - (Deserializer pass: `when "referenceTracker" then ...add shell` — restore-time
    re-registration; serializer writes the marker `m.push "referenceTracker"`.)
- A reference SEED today = a non-orphan tracker member (`isOrphan()`: root is neither
  world nor hand — note a HAND-HELD shortcut still seeds, correct for mid-drag). A
  tracker member resting in storage is a potential RELAY, resolved by doGC's pass-3
  fixpoint (`isInBinButReachable`).
- `world.anyReferenceToWdgt w` (WorldWdgt:~2923): DIRECT-reference linear scan (no
  chains); used by the close triage.

### The close paths (what files things into storage)

- `Widget._closeNoSettle`: frame-content forwards to its frame; otherwise
  `world.binWdgt._addLostWidgetNoSettle @_enclosingIslandFigure()` (re-homes the FIGURE;
  else "There is no\nbin to go in!"). This is the ONE generic entry into storage.
- `PopUpWdgt._closeNoSettle` (Basement→Bin Phase 1): pinned → super (ordinary close);
  unpinned → destroyed outright. Untouched by this plan.
- `FrameWdgt._saveOrAskThenCloseCitizen` (~line 376): unchanged+unreferenced →
  `fullDestroy`; changed+unreferenced → `SaveShortcutPromptWdgt`; referenced → `close()`.
  (`_closeFromFrameBarWhenSaveOrAsk` base: content decides via `closeFromContainerFrame`;
  FolderWindowWdgt has its own variant.)
- `Widget._createReferenceAndCloseNoSettle` = `_createReferenceNoSettle` then
  `_closeNoSettle` — the save-on-close path: the reference exists BEFORE the close lands.
- `PanelWdgt.makeFolder` (line ~48, also the BOOT "Examples" folder via
  `WorldWdgt.createDesktop` line ~648): `new FolderWindowWdgt`; `newFolderWindow.close()`
  (→ bin, UNREFERENCED at this instant); `createReference name, @` (→ registers). Under
  eager sorting this files to bin then re-sorts to shelf within the same cycle — a
  built-in stress test of the event model.

### doGC as of `57a7eaf4` (BinWdgt.coffee)

- pass 1: for each tracker member, `if isOrphan()` → mark visited (discard). **Carries the
  on-screen precondition** (comment at ~line 60): with the bin off-tree its residents ARE
  orphans, so chains through bin-resident references break when the bin is closed.
- pass 2: unvisited AND `!isInBin()` → seed: `target.markItAndItsParentsAsReachable`.
- furniture marking (Basement→Bin Phase 2): `Serializer.WORLD_APP_SLOTS`
  (`degreesConverterWindow`, `howToSaveDocWindow`, `sampleDashboardWindow`,
  `sampleSlideWindow`, `sampleDocWindow`) + `world.simpleEditorTemplates`, marked BEFORE
  the fixpoint so references inside furniture relay.
- pass 3 fixpoint: unvisited members with `isInBinButReachable` → relay.
- `markItAndItsParentsAsReachable` climbs parents, STOPS climbing at
  `isDirectlyInBasement`-style boundary (`isDirectlyInBin`: `@parent?.parent?.parent ==
  world.binWdgt` — the contents-panel sandwich), so marking a resident never marks the bin
  itself.
- ONE caller of `doGC` besides `emptyBin`: `refreshLostOnlyView`.

### The lazy view machinery (what Phase 3 deletes)

- `BinWdgt.refreshLostOnlyView`: doGC → hide reachable residents / show lost ones →
  `@_reFitContainer @scrollPanel`. Called from `BinOpenerWdgt.mouseClickLeft` (on-open
  refresh) and `_reactToChildAddedInScrollPanel` (on child add, via
  `PanelWdgt._reactToChildAdded`).
- The three revival-path un-hides (needed only because parked residents are hidden):
  `IconicDesktopSystemShortcutWdgt.bringUpTarget` (`@target.show()` + `whatToBringUp.show()`),
  `IconicDesktopSystemWindowedApp.launch` (`figure.show()`),
  `TemplatesButtonWdgt.mouseClickLeft` (`world.simpleEditorTemplates.show()`).
- `Widget.subWidgetsMergedFullBounds` skips `!isVisible` children (57a7eaf4; single caller:
  `ScrollPanelWdgt._positionAndResizeChildren`'s non-content-sizing fit). After this plan
  nothing in the bin is hidden, so the skip stops being load-bearing — KEEP it (correct
  scroll semantics generally, already suite-verified) but note it in the commit.
- `BinWdgt.emptyBin`: one doGC → destroy the lost set. Post-plan: every bin resident is
  lost by invariant, so it simplifies to destroying ALL residents (keep the single-doGC
  refresh guard only if the pending-sort has not drained yet — simplest: drain the pending
  sort first, then `fullDestroyChildren` on the contents. `empty()` (test-only,
  homepage-excluded) is unaffected.)

### Storage residents & revival (who rests where after the split)

- Referenced documents/folders (save-on-close, `makeFolder`) → SHELF.
- Closed singleton app windows (world slots) + parked `simpleEditorTemplates` → SHELF
  (reachable via world fields — the doGC furniture marking).
- The boot "Examples" `FolderWindowWdgt` → SHELF (referenced by its desktop shortcut).
- Truly lost items (closed without reference; orphaned by shortcut deletion) → BIN,
  all visible.
- Revival is already container-agnostic: `bringUpTarget` / `launch` /
  `TemplatesButtonWdgt` all just `world.add` the figure out of wherever it rests. Their
  `holds`-style checks change: `world.binWdgt.holds` → a storage-level query (§4 Phase 3).
  `TemplatesButtonWdgt.mouseClickLeft` gates on `world.binWdgt.holds world.simpleEditorTemplates`
  — becomes the shelf check.

### Serialization surface

- `Serializer.serializeWorld` roots: desktop children (transient popups + ephemerals
  filtered), `theWorld.binWdgt`, each non-nil `WORLD_APP_SLOTS` window (may be
  orphaned-but-revivable), `world.simpleEditorTemplates`. `section.bin = ref(...)`;
  per-widget membership markers include `"referenceTracker"` and `"openPopUp"`.
- `WellKnownObjects`: lazy, resolves against the live world; key `"bin"` for
  `world.binWdgt`. INDEX ⚖ case law: **any out-of-subtree pointer not a well-known
  singleton = a path-carrying error at serialize time** — i.e. everything resting in
  storage MUST be under a root; the shelf must therefore be a root + a well-known key
  (`"shelf"`), exactly parallel to the bin.
- `WorldWdgt.loadWorldSnapshot` step 6: `restoredBin = resolve section.bin;
  @binWdgt = restoredBin if restoredBin?` — the shelf needs the twin swap-in.
- `_teardownForSnapshotLoadNoSettle`: `fullDestroyChildren` + `binWdgt?.empty()` + nil the
  slots + templates. The tracker is NOT cleared explicitly — it self-empties via
  `IconicDesktopSystemShortcutWdgt.destroy`. Teardown must also empty the shelf, and the
  eager hooks must be no-op-safe during teardown (mark-pending is fine; the drain runs
  after the world is rebuilt).
- Rigs (a gauntlet leg): `scripts/serialization-roundtrip-headless.js` (80 checks;
  `R.binCount` counts bin contents children; `world.samePage.statePreserved` compares
  before/after same-session) + `serialization-file-roundtrip-headless.js` (7 checks).
  Post-split, parked items move OUT of `section.bin` into `section.shelf` — the rig gains
  an `R.shelfCount` and its counts must be re-derived (before/after same-session stays
  count-neutral per container).

### Test exposure

- 3 SystemTests reference the bin, all via `world.binWdgt.holds` after closing app/tilted
  windows: `SystemTest_macroTiltedWindowKeepsRotationThroughCloseReopen`,
  `SystemTest_macroExplicitIslandTravelsWholeThroughCloseReopen`
  (+ comment-only `SystemTest_macroClosingRotatedIslandChildClearsFootprint`).
  **These CHANGE under this plan**: a closed app window is referenced furniture → rests on
  the SHELF once the sort drains. The asserts run right after `close()` within the same
  macro — whether they see bin (pre-drain) or shelf (post-drain) depends on cycle timing,
  so REWRITE them against the STORAGE query (or shelf explicitly, after a settle) — do not
  leave them timing-sensitive. Patch both repos in the same arc.
- The scratch probe `Fizzygum-tests/.scratch/bin-oracle-probe.js` (19 checks, gitignored)
  is the functional harness for this surface — Phase 4 rewrites it for the split (see §7).
- The harness world builds no desktop icons; the bin/shelf windows are never screenshotted
  → expected screenshot churn: zero for Phases 0–3.

### Existing dynamic-check machinery (what §4's guards build on — all verified 2026-07-22)

- **Console-token fail-gate**: `Widget._assertBoundsWellFormed` `console.error`s
  `NON_INTEGER_GEOMETRY` / `NON_FINITE_GEOMETRY`; BOTH headless runners scan console
  errors for a hard-coded token list and fail the test/suite on a hit —
  `scripts/run-macro-test-headless.js` ~line 343 and `scripts/run-all-headless.js`
  ~line 185 (tokens: `NON_FINITE_GEOMETRY`, `NON_INTEGER_GEOMETRY`,
  `DOWNWALK_UNREACHABLE_CHAINTOP`). Adding a token = one line in EACH runner. A guard
  emitting a token therefore gets enforced across EVERY suite-running leg (dpr1, dpr2,
  webkit, apps, revisits, capstone…) for free.
- **Dedicated-leg pattern** (`fg revisits` = the template): a committed runner script
  (`scripts/revisit-gate.js`) runs the full suite with an injected audit prelude
  (`scripts/audit-preludes/revisit-prelude.js`) that flips an off-by-default WorldWdgt
  flag, collects a per-test profile, and asserts it against a committed baseline that is
  EMPTY — so ANY hit anywhere is a regression. The `fg` leg wiring (case entry + parallel
  wave membership + verdict headline grep) lives in the UMBRELLA-LOCAL `fg` script, which
  is NOT committed to any repo — the runner script and prelude ARE committed
  (Fizzygum-tests). Keep that split straight when landing Phase 5.
- One-shot oracles that could also carry a storage assert: `scripts/staleness-census.js`
  (boots production, opens the bin + an app battery — a natural place for a final
  invariant sweep).

### The world cycle (where the drain goes)

- `WorldWdgt.doOneCycle` runs ordered drain stations; precedent: `recalculateDataflow`
  sits BETWEEN `runChildrensStepFunction` and `recalculateLayouts` (one-way coupling:
  dataflow may dirty layout, never the reverse). The storage sort is the same shape: it
  may move widgets (dirtying layout of an OPEN bin window at most) → its station belongs
  BEFORE `recalculateLayouts`, alongside/after dataflow. Re-verify the exact station list
  in `doOneCycle` before wiring (grep `recalculateDataflow`).

---

## §2 Why it is shaped this way

Morphic's close-was-a-soft-delete warehoused everything in one basement; the Basement→Bin
arc made the TRASH the user-facing identity but kept the single container, expressing
"parked" as hidden-in-place — the minimal diff from the warehouse model, and the source of
every view/store patch since (hide/show, show() companions, visibility-aware scroll fit).
The FolderPanelWdgt header always described the DISK as "a network of pointers to stuff
that rests" — the resting place being the user-facing bin was an accident of history, not
a design.

---

## §3 The distilled argument

- Classification is already lazy and cheap (`doGC` runs on every bin child-add today).
  Eager sorting does not abandon that elegance — it keeps the SAME classifier and changes
  only (a) WHEN it runs (at reachability events, coalesced per cycle) and (b) WHAT its
  output is (placement between two containers instead of visibility).
- The standing invariant (shelf = reachable, bin = lost) deletes more code than it adds:
  the whole lazy view machinery, the three revival un-hides, and the timing question
  "when was this last classified?" disappear. Empty bin is safe BY CONSTRUCTION.
- The user-visible semantics get strictly more honest: delete a shortcut → its document
  appears in the bin now; save a doc on close → nothing about the bin changes, ever.
- The events are few and already funnel through single-file chokepoints (§1); the
  end-of-cycle drain absorbs both the ctor-before-attach ordering and bulk-teardown
  storms in one mechanism.

---

## §4 Phases

### Phase 0 — GATING SPIKE: off-screen classification (the doGC re-derivation)

Re-derive `doGC` so it is correct with ALL storage off-tree (nothing windowed):

- pass 1 (the change): discard a tracker member only if it is an orphan AND NOT resting in
  storage — `isOrphan() and !isInStorage()` where `isInStorage` = parent-walk hits the
  bin OR the shelf (generalize `TreeNode.isInBin` to check both containers; keep the
  per-container variants too — `holds` needs them).
- pass 2 seeds: unvisited AND not-in-storage members (root is world or hand).
- furniture marking: unchanged.
- pass 3 fixpoint: unvisited members with `isInStorageButReachable` (the generalized
  `isInBinButReachable` — same climb, boundary = either container's contents panel).
- The "BinWdgt is on the desktop" precondition comment is DELETED — the classifier is now
  total. `emptyBin`'s precondition note is deleted with it.

**Spike deliverable (before any product code):** a `.scratch` probe that, on the CURRENT
single-container build, runs the re-derived classifier with the bin CLOSED and asserts it
matches what today's classifier says with the bin OPEN, across: a chained reference
(shortcut-in-parked-folder → doc), a lost item, parked furniture, and the boot Examples
folder. If any case diverges in a way the re-derivation cannot explain, STOP — report to
the owner (stop-after-two-falsifications rule applies to fix shapes here).

**Gate:** the spike probe green; no product diff yet.

### Phase 1 — the Shelf exists

- `src/ShelfWdgt.coffee`: minimal off-tree container — same skeleton as BinWdgt's storage
  half (a BoxWdgt holding a ScrollPanelWdgt is MORE than needed; a bare `PanelWdgt`
  subclass with an `_addRestingWidgetNoSettle` + `holds` + `empty()` is enough — it is
  never viewed. Decide at implementation against what serialization/`holds`/island
  re-homing require; DO NOT give it an opener, an icon, a window path, or any view).
- Boot: `world.shelfWdgt = new ShelfWdgt` next to the bin in `startWorld`
  (`src/boot/globalFunctions.coffee` ~361).
- Serialization: `roots.push theWorld.shelfWdgt`; `section.shelf = ref(...)`;
  `WellKnownObjects` key `"shelf"`; `loadWorldSnapshot` swap-in twin;
  `_teardownForSnapshotLoadNoSettle` adds `@shelfWdgt?.empty()`.
- `TreeNode`: `isInShelf`/`isDirectlyInShelf` twins + the generalized `isInStorage`/
  `isInStorageButReachable` from Phase 0.

**Gate:** `fg presuite` + both rigs (shelf serializes empty; counts unchanged).

### Phase 2 — the eager sort engine

- Land the Phase-0 classifier in `doGC` (now callable any time). Consider moving
  `doGC` + the sorter OFF BinWdgt to a small coordinator (`world.storageSorter` or
  world-level methods) — the classifier no longer belongs to the bin view. Owner's
  standing preference: pick the right home on merits, don't let churn decide.
- `world.noteStorageMembershipMayHaveChanged()` (public, intent-named): sets a pending
  flag. Hook it at: the 3 tracker mutation sites, `Widget._closeNoSettle`'s storage
  filing, `IconicDesktopSystemWindowedApp.launch` (slot write), teardown/restore
  completion. Hooks are mark-only — O(1), safe in bulk destroy loops.
- The drain station in `doOneCycle` (before `recalculateLayouts`, after dataflow —
  re-verify the station order at implementation): if pending → run the classifier once,
  then MOVE misplaced residents (bin→shelf for reachable, shelf→bin for lost; re-home as
  FIGURES via the existing island-aware idiom; bin arrivals through
  `_addLostWidgetNoSettle`'s scatter, shelf arrivals at origin — never viewed), inside one
  settle batch. Clear the flag.
  - Deserialize/teardown guard: the flag may be set mid-restore; the drain only runs from
    `doOneCycle`, which resumes after the world is consistent — verify no station runs
    mid-`loadWorldSnapshot`.
- Close filing stays DUMB (everything to the bin container first) — the same-cycle drain
  sorts it. EXCEPTION worth taking: `_createReferenceAndCloseNoSettle` may file straight
  to the shelf (the reference demonstrably exists), halving the common save-close churn —
  but only if it keeps `_closeNoSettle`'s frame-forwarding and island-figure semantics
  intact (it delegates to `_closeNoSettle` today; the clean cut is a parameter or a
  sibling core, NOT a copy).
- **The engine is born guarded — the always-on invariant guard (Tier A) lands in this
  same phase:** a world-level audit (e.g. `world._auditStorageNoSettle()`, homepage-safe,
  O(residents + tracker)) that runs at DRAIN EXIT and at the test-teardown/ResetWorld
  seam, checking:
  1. placement matches classification — every shelf resident marked reachable, every bin
     resident not, verified against the gcSessionId marks the drain JUST computed (no
     second classification);
  2. no `destroyed` widget parented in either container (the drain must also skip them
     defensively — §5.3);
  3. no dual residency (a widget's figure parented in both containers is structurally
     impossible via parent pointers — assert it anyway, it is one Set walk);
  4. tracker hygiene: no `destroyed` member left in `widgetsReferencingOtherWidgets`
     (catches unregister leaks — e.g. shortcuts inside orphaned-but-revivable app
     windows destroyed without their destroy() hook running);
  5. the pending flag is CLEAR at drain exit.
  On any violation it `console.error`s a single greppable token line —
  `STORAGE_INVARIANT <which-check> <ClassName>` — and the token `STORAGE_INVARIANT` is
  added to BOTH runners' fail-gate token lists (run-macro-test-headless.js +
  run-all-headless.js, §1) in the same commit. From that moment every suite-running
  gauntlet leg enforces the invariant on all 265 tests at zero extra wall-clock.

**Gate:** `fg presuite` (now invariant-enforcing via the token); probe (extended per §7)
proving: delete a desktop shortcut → document MOVES to the bin within one cycle, bin
closed throughout; `makeFolder` boot sequence ends with the folder on the SHELF;
save-close doc → shelf; close-unsaved → bin.

### Phase 3 — the bin view goes dumb (deletions)

- Delete: `refreshLostOnlyView` (hide/show + `_reFitContainer` call),
  `_reactToChildAddedInScrollPanel`, the opener's refresh call, and the three revival
  un-hides (`bringUpTarget`'s two `show()`s + comment, `launch`'s `figure.show()`,
  `TemplatesButtonWdgt`'s `show()`), and any `isVisible` bookkeeping on storage residents
  (residents are ALWAYS visible in their container).
- `emptyBin`: drain-if-pending, then destroy all contents children (all lost by
  invariant). Confirm menu unchanged.
- `holds`-check swaps: `TemplatesButtonWdgt` + any `world.binWdgt.holds` site that means
  "is it parked" → shelf/storage query. `BinWdgt.holds` keeps meaning "in the BIN".
- `InfoDocs` bin copy: re-read it against the new truth (likely already true; "items you
  close without saving a link to also land in here" remains correct user-visibly since
  the sort drains before the next paint).
- Comment/doc sweep: `FolderPanelWdgt` header ("rests in the bin" → the shelf),
  `docs/architecture/serialization-duplication-reference.md` (roots list + storage
  story), BinWdgt/TreeNode comments.

**Gate:** `fg presuite` + rigs + full probe; then `fg gauntlet` as the phase-1–3 commit
point.

### Phase 4 — tests, rigs, probe

- Rewrite the 2 close/reopen SystemTests' storage asserts (§1) against the post-drain
  state deterministically (settle, then assert shelf residency + island wrap intact);
  update the comment-only third. Screenshots expected unchanged (value-assert tests) —
  if any churn appears, eyeball then `fg recapture --auto` on a FRESH build (standing ⚠⚠).
- Rig: add `R.shelfCount`; re-derive the affected checks (`world.samePage.statePreserved`
  count comparisons, any comment naming the bin as the resting place).
- Promote the probe's split-era checks (see §7) and keep it in `.scratch/`.

**Gate:** full `fg gauntlet` green.

### Phase 5 — the deep audit: a dedicated `fg storage` gauntlet leg (Tier B)

The Tier A guard (Phase 2) checks each drain's OWN result cheaply. The deep audit
re-derives everything from scratch per test — catching what Tier A structurally cannot:
classification INSTABILITY (a classifier whose second run disagrees with its first) and
end-of-test residue in tests where no drain happened to fire late.

- `scripts/audit-preludes/storage-audit-prelude.js` (committed, Fizzygum-tests): flips an
  off-by-default WorldWdgt audit flag (the revisit-prelude idiom). With the flag on, at
  each test's END (the same seam revisit counting uses):
  1. force-drain if the pending flag is set;
  2. run the classifier ONCE MORE from scratch and assert it produces ZERO moves — the
     fixpoint/idempotence check (Tier A reuses the drain's marks, so only this catches a
     classifier that disagrees with itself);
  3. re-assert Tier A's checks 2–4 (destroyed residents, dual residency, tracker
     hygiene);
  4. record any violation into a per-test profile.
- `scripts/storage-invariant-gate.js` (committed): runs the FULL suite with the prelude
  injected (shards param, same shape as `revisit-gate.js`) and asserts the collected
  profile is EMPTY — no committed baseline file needed unless a legitimate standing
  exception ever appears (it should not; if one does, that is a design conversation, not
  a baseline entry).
- `fg` wiring (UMBRELLA-LOCAL, uncommitted — §1): a `storage)` leg case + membership in
  the gauntlet's parallel wave B + a verdict headline grep. Wall-clock: one more
  full-suite run (~2 min) absorbed by the parallel wave.
- Also extend `scripts/staleness-census.js` with one final storage-invariant sweep after
  its window battery (it already opens the bin; one page, ~free).

**Gate:** `fg storage` green standalone, then full `fg gauntlet` (now 13 legs) green =
arc close. One end-of-arc review, then commit (ask first).

---

## §5 Central risks

1. **The classifier re-derivation (Phase 0).** Chains through off-tree containers are
   exactly what the old precondition dodged. The spike gates everything; its
   equivalence-vs-open-bin check is the falsifier. Two failed re-derivation shapes =
   wrong model, stop and re-frame with the owner.
2. **Drain-station side effects.** Moving residents while the bin window is OPEN dirties
   real layout — the drain must run inside its own settle batch at the station, and the
   station must precede `recalculateLayouts` (dataflow precedent). Watch the settle/
   capstone/revisits gauntlet legs — they are the sharpest observers of a new station.
3. **Bulk teardown storms.** `fullDestroyChildren` fires the destroy-hook per shortcut;
   mark-only hooks make this O(1) each, and the drain runs once after. Verify resetWorld/
   snapshot-teardown leave the flag in a state that cannot resurrect destroyed widgets
   (the drain must skip `destroyed` residents defensively).
4. **Timing-sensitive asserts.** Anything (tests, rigs, probes) that asserts residency
   immediately after a close sees pre-drain state. The plan's answer is "assert after a
   settle/cycle, against the invariant" — never bake pre-drain snapshots into references.
5. **Serialization mid-sort.** A snapshot taken with the flag pending must still be
   correct: both containers are roots, so an unsorted resident serializes wherever it
   rests and re-sorts on the next cycle after load. Assert this in the rig rather than
   forcing a drain pre-serialize (simpler, and honest).
6. **Guard false-positives under teardown.** The Tier A audit fires at the ResetWorld
   seam too — mid-teardown worlds are legitimately inconsistent, so the audit must run
   AFTER teardown completes (or be suspended during it), and the `STORAGE_INVARIANT`
   token must never be emittable from a half-torn world, or every test in the suite
   fails at once. Mirror how the bounds guard stays quiet during the same windows
   (verify its idiom at implementation).

---

## §6 Rejected alternatives (do not re-attempt without new evidence)

- **Lazy sort-at-bin-open** (this plan's own first draft): mechanically fine, but keeps
  the lump-then-sort smell and the "when was this last classified?" timing question —
  owner-rejected 2026-07-22 ("still a smell... Can we sort stuff out right away?").
- **Single container + visibility filter** (the shipped Basement→Bin state): every view/
  store patch it forced is catalogued in §0 — that inventory IS the falsification.
- **No shelf container: parked payloads rest as orphans, the disk = the reference graph.**
  Ideologically purest, but requires a parked-items registry (new state), serializer
  roots walked off the tracker (the out-of-subtree-pointer error class), and
  leak-proofing when references die (an unreachable orphan is invisible to everything).
  More mechanism than the container, not less.
- **Per-event immediate (non-coalesced) sorting.** Falsified by the ctor-before-attach
  ordering (§1: a shortcut registers while still orphan — sorting at that instant
  misclassifies its target) and by bulk-teardown storms (O(events) full classifications).
  The cycle-drain is the fix, not a compromise.

---

## §7 Verification protocol

- Inner loop per phase: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (~3.5 min,
  backgrounded).
- Both rigs directly (fast, sharpest for storage):
  `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/serialization-roundtrip-headless.js`
  then `node scripts/serialization-file-roundtrip-headless.js` (FRESH build).
- The functional probe (`Fizzygum-tests/.scratch/bin-oracle-probe.js`, rewrite in place):
  boot → Examples folder on SHELF, bin EMPTY (truly empty now — no hidden residents);
  close-unsaved → bin, visible; save-close → shelf, bin untouched (scrollbars never move);
  DELETE the doc's desktop shortcut → doc in the BIN within one cycle, bin never opened;
  re-create a reference (drop into folder) → back to shelf; app window close/relaunch
  cycle through the shelf with island wrap intact; Empty bin destroys bin-only, shelf
  intact; confirm menu pops + dismissal destroys it.
- Dynamic invariants: from Phase 2 on, EVERY suite leg enforces the `STORAGE_INVARIANT`
  console token (Tier A — placement-vs-classification, destroyed residents, dual
  residency, tracker hygiene, flag cleared). From Phase 5: the dedicated deep-audit leg
  (`fg storage` → `node scripts/storage-invariant-gate.js`, full suite + per-test
  force-drain + from-scratch reclassify + zero-moves fixpoint assert, empty-profile
  gate), plus the census's end-of-battery invariant sweep.
- Phase-close / commit points: `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet`
  (backgrounded; read `/tmp/fg-gauntlet.verdict`; 13 legs once Phase 5 lands). Watch
  settle/capstone/revisits for the new station; `PASS-serial-only` on a leg = load-flake
  (verify standalone), not code.
- Recaptures only via `fg recapture --auto` on a FRESH build; expected: none.

---

## §8 References

- `docs/archive/basement-to-bin-plan.md` — the predecessor arc (as-built status box incl.
  owner decisions); its §6 "physically split the roles" rejection is SUPERSEDED by this
  plan (the rejection assumed eager bookkeeping; the cycle-drain dissolves that
  objection).
- `docs/architecture/serialization-duplication-reference.md` — roots/WK-keys mechanics
  (must be updated in Phase 3).
- INDEX ⚖: out-of-subtree pointer error class (serializer); island-figure re-homing
  (close must move FIGURES).
- Memory notes: `basement-to-bin-arc` (incl. the bugfix round + case law),
  `no-serialization-compat-obligations` (reshape freely, no shims),
  `ask-before-commit-push`, `owner-workflow-long-arcs`,
  `stop-iterating-fix-shapes-after-two-falsifications` (Phase 0's stop rule).
- Comment rubric: umbrella `.claude/comment-rubric.md` (present-tense only).

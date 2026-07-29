# `_resetWorldNoSettle` completeness audit — make the world teardown PROVABLY total

**COMPLETE — audit EXECUTED 2026-07-29** (Fizzygum `master` @ `bd4448c0`, Fizzygum-tests @
`4c2e8922f`, suite = 268). The audit ran in full: 26 rows inventoried and decided, **14 further
leaks found and fixed**, and the Phase 4 structural guard delivered and proved to FAIL on a planted
leak. Gates green with **zero reference churn**: `fg gauntlet` 13/13 legs PASS in parallel,
`fg homepage` OK, and the `--shards=1` detector 268/268. **The execution record is §7.5 — read that
for the inventory, the decisions and the case law; §1–§6 below are the original 2026-07-28 plan,
kept verbatim as the brief.** Line numbers WILL drift — method/field names are authoritative.

⚖ Headline: reactive patching had left **an order of magnitude more holes than the two caught
instances implied**. The worst were not the ones anyone had noticed — a desktop grid cursor that
moves later tests' icons, the world's own extent, and a dangling error console that silently
swallows every later paint error in the page.

**MANDATE.** *Eliminate the bug class*, not the next instance of it. The goal is a teardown that is
**provably complete** — every piece of world-level mutable state either reset, or documented in-place
as deliberately surviving with the reason. A plan that just adds one more `.clear()` has failed. The
deliverable is (a) a complete inventory, (b) each item decided, (c) ideally a **structural guard** so
the next added field cannot silently reopen the hole.

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework rendered on one HTML5 canvas; three sibling repos
(`Fizzygum` source, `Fizzygum-tests` suite + harness, `Fizzygum-builds` generated output). Read the
root `CLAUDE.md`, then `Fizzygum-tests/CLAUDE.md`, then **`Fizzygum-tests/DETERMINISM.md` §2d and
§3h** — §2d names this bug class and §3h is the worked example that triggered this plan.

Use the `fg` wrapper (`/Users/davidedellacasa/code/Fizzygum-all/fg`) for every build/test invocation
— absolute path, never `./fg`.

### Why this plan exists now

`WorldWdgt.resetWorld` is what the SystemTest harness runs between tests. All 268 tests share ONE
browser page per shard, so **anything `resetWorld` forgets leaks into the next test in that page.**

The teardown has grown **reactively** — each entry added only after a leak was caught in the field:

| date | leaked state | how it surfaced |
|---|---|---|
| 2026-07-10 | `widgetsToBeHighlighted` + the 5 sibling highlight/pinout Sets | a test mis-rendered mid-suite; dead refs to destroyed targets |
| 2026-07-28 | `UntitledNamingService` counters | `macroSaveAsPromptAboveTiltedWindow` failed 100% at `--shards=1`; a default name rendered `Untitled 2` instead of `Untitled` |

Two instances of one shape, found by accident, years apart in effort. The method's own comment
already states the intent — *"resetWorld must reset ALL world state"* — so the invariant is agreed;
what is missing is any evidence it HOLDS.

### Critical reframes — do not re-derive these

- **R1: this bug class is INVISIBLE to the standing gates.** `fg gauntlet` runs its suites at 4
  shards and `fg suite` at 8; **nothing in the routine loop runs 1 shard.** A leak only bites when
  the consuming predecessor shares a page with the victim, so a fully deterministic failure can sit
  on `master` indefinitely. The 2026-07-28 one was found only because `torture-headless.js` rotates
  `--shards`. ⛔ **Owner decision 2026-07-28: do NOT propose adding an s1 gate — too expensive
  (~6 min serial).** Use `--shards=1` as an *investigation* tool inside this audit only.
- **R2: "it passes at 4/8 shards" proves nothing here.** Shard count is a **predecessor-set** axis,
  not a load axis: at s1 all 268 tests share one page; at s8 a test sees ~33 predecessors.
- **R3: `run-sequence-headless.js` is NOT a valid oracle for this class.** It replays a named subset
  in one page — exactly the right *shape* — but it starts the run from a Node round-trip, whereas the
  suite runner starts it at boot via `?startupActions`, and the 2026-07-28 leak **did not reproduce
  under it even with all 268 tests in manifest order.** A green from an instrument you have not seen
  reproduce the failure is not evidence of absence. This cost real time; see the WITHDRAWN corollary
  in `DETERMINISM.md` §2d. **Verify your repro tool reproduces a KNOWN leak before trusting it.**
- **R4: `fullDestroyChildren` is not enough, and that is the whole point.** It destroys the widget
  TREE (and zeroes per-class id counters). Every leak so far was world-level state held *outside* the
  tree — Sets of refs, a counter object, a bare field — which the tree teardown cannot reach.

---

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — confirm clean trees, note the suite count.
2. Read this doc fully, then `DETERMINISM.md` §2d + §3h.
3. **Do Phase 1 (inventory) completely before touching any code.** The value of this audit is the
   inventory; a partial one recreates exactly the reactive patching this plan exists to end.
4. Phase 2 decides each item; Phase 3 implements; Phase 4 tries for a structural guard.
5. Gates per §5 at the end of every phase.
6. **Never commit or push without explicit owner approval** (standing rule).
7. Budget: Phase 1 is reading, not runs. Phases 3–4 need `fg build` (~1.5 min) plus a `--shards=1`
   suite run (~6 min) plus `fg gauntlet` (~5 min) per verification round.

---

## §1 The mechanism as it stands today

Four methods matter, all in `Fizzygum/src/WorldWdgt.coffee` (grep the names; ~`:2464`–`:2560` and
~`:2718` today):

- **`resetWorld`** — the public entry the harness calls between tests. Two self-settling steps:
  `@_softResetWorld()` then `@_settleLayoutsAfter => @_resetWorldNoSettle()`, then a
  `@storageSorter._auditStorageNoSettle()` structural audit. **Homepage-stripped** (test/dev tooling),
  which is why product-safety is not a constraint on what it may reset.
- **`_softResetWorld`** — INPUT-side reset, deliberately outside the settle (its `@hand.drop()`
  re-parents and self-flushes): `hand.drop()`, `hand.mouseOverList.clear()`,
  `hand.nonFloatDraggedWdgt = nil`, `wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.clear()`,
  `editorFocusWdgt = nil`.
- **`_resetWorldNoSettle`** — the WORLD-side reset. Today: `@_changed()`, `fullDestroyChildren()`,
  the 6 highlight/pinout Sets, `untitledNamingService.resetCounters()`, `_editorSelectedWidget = nil`,
  `binWdgt.empty()`, `shelfWdgt.empty()`, `setColor` back to the default grey, wallpaper back to
  `pattern1`, and `scrollTop = 0`.
- **`_teardownForSnapshotLoadNoSettle`** — the product-safe twin used by `loadWorldSnapshot`.

### ⚠ A concrete asymmetry, already found (verify, then decide)

`_teardownForSnapshotLoadNoSettle` clears **two things `_resetWorldNoSettle` does not**:

```coffee
@[slot] = nil for slot in Serializer.WORLD_APP_SLOTS   # 5 app-slot windows
@simpleEditorTemplates = nil
```

`Serializer.WORLD_APP_SLOTS` = `degreesConverterWindow`, `howToSaveDocWindow`,
`sampleDashboardWindow`, `sampleSlideWindow`, `sampleDocWindow` (`src/serialization/Serializer.coffee`
~`:20`). Measured while authoring: `degreesConverterWindow` appears **0 times** in `WorldWdgt.coffee`
and `simpleEditorTemplates` only twice (the snapshot teardown + one other site) — so nothing in
`_resetWorldNoSettle` nils them.

Those windows ARE world children, so `fullDestroyChildren` destroys the WIDGETS — but the world's
*slot references* would then point at destroyed widgets. **That is precisely the dangling-ref shape
of both known leaks.** ⚠ Do NOT treat this as a confirmed bug: a destroy hook may already nil them.
**Verify first** (Phase 1 step 4), then decide.

---

## §2 THE ORACLE — why this audit is tractable at all

Naively, "enumerate all world-level mutable state" is unbounded. It is not, because the codebase
already contains an independent enumeration of exactly that: **`Serializer.serializeWorldSnapshot`'s
explicit world section** (`src/serialization/Serializer.coffee`, the `section = {}` block, ~`:125`).
Someone already decided, field by field, what constitutes the world's own state worth persisting:

`children` · `desktopColor` · `alpha` · `isDevMode` · `wallpaperPatternName` ·
`numberOfIconsOnDesktop` · `infoDoc*` flags (every own property whose name starts `infoDoc`) ·
`untitledNamingCounters` · `appSlots` (the 5 `WORLD_APP_SLOTS`) · `simpleEditorTemplates` · `bin` ·
`shelf` · `preferences` (the **static** `WorldWdgt.preferencesAndSettings`) · `idCounters` ·
`sourceEdits` (`sourceEditsRegistry`).

**Diffing that list against `_resetWorldNoSettle` is the single highest-value step in this plan.**
Two independently-maintained enumerations of "the world's own state" that disagree = each
disagreement is either a leak or a deliberate exception that deserves a comment.

The serializer list is a **floor, not a ceiling** — it omits state that is ephemeral-by-design and so
never persisted (the highlight/pinout Sets are NOT in it, yet were a real leak). Phase 1 therefore
also sweeps the class directly.

---

## §3 Phases

### Phase 1 — INVENTORY (read-only; do this completely first)

1. **Serializer diff.** Walk the world section field by field; for each, grep whether
   `_resetWorldNoSettle` (or `_softResetWorld`, or `fullDestroyChildren`) resets it. Record
   `reset / not reset / N-A` with the evidence. Explicit candidates flagged while authoring:
   `numberOfIconsOnDesktop`, the `infoDoc*` flags, `WORLD_APP_SLOTS`, `simpleEditorTemplates`,
   `WorldWdgt.preferencesAndSettings`, `sourceEditsRegistry`, `isDevMode`, `alpha`.
2. **Direct class sweep.** In `WorldWdgt.coffee`, list every instance field declared in the class body
   and every `@`-assignment in the constructor; classify each: *derived//rebuilt*, *reset by an
   existing path*, or **candidate**. Pay special attention to `Set`/`Map`/`Array`/plain-object fields
   and to delegated collaborator objects (`untitledNamingService`, `storageSorter`, `macroToolkit`,
   `sourceEditsRegistry`, `dataflow`, `wallpaper`) — a collaborator's *internal* counters are exactly
   what the 2026-07-28 leak was, and the class sweep will not see them. Recurse one level into each.
3. **Class-level (static) state.** `WorldWdgt.preferencesAndSettings`,
   `WorldWdgt.immutableBackBufferGeneration`, `WorldWdgt.frameCount`,
   `WorldWdgt.dirtyRectListEnabled`, `WorldWdgt.islandBufferCacheEnabled`, and any other `@foo:` at
   class scope. Statics survive everything by construction — decide each deliberately.
4. **Resolve the §1 asymmetry.** Determine empirically whether app slots / `simpleEditorTemplates`
   dangle after `resetWorld`. Cheapest probe: in the built harness page, run one test that opens an
   app-slot window, `resetWorld`, then read the slot — `world.degreesConverterWindow?.destroyed`. A
   truthy-but-destroyed ref is the leak.

**Deliverable:** a table in this doc — field · owner · reset-by · verdict · evidence.

### Phase 2 — DECIDE each item

Every inventory row gets one of:
- **RESET** — add to `_resetWorldNoSettle` (or the collaborator's own `resetX()`, called from there —
  the `UntitledNamingService.resetCounters()` shape, which keeps the knowledge with the owner).
- **DELIBERATELY SURVIVES** — with a one-line in-code comment saying WHY (e.g. `frameCount` is a
  monotonic clock the stall watchdog depends on; zeroing it would break the watchdog).
- **N/A** — rebuilt/derived every cycle; note where.

⚠ Bias toward RESET for anything that can reach a RENDER. The bar: *could a test's pixels differ
because an earlier test ran?* If yes, reset it.

### Phase 3 — IMPLEMENT

Small, reviewable commits. Each RESET carries a comment naming what would leak (match the existing
in-place style — the highlight-Set and Untitled-counter comments are the template). Prefer
`collaborator.resetX()` over poking a collaborator's fields from the world.

### Phase 4 — THE STRUCTURAL GUARD (the part that ends the bug class)

Phases 1–3 fix today's holes; only this stops tomorrow's. Explore, in rough order of preference:

1. **A post-reset assertion**, in the spirit of the existing `storageSorter._auditStorageNoSettle()`
   already called at the end of `resetWorld`: after teardown, assert the world matches a
   pristine-world fingerprint (children empty, the known Sets empty, counters zero, no dangling
   destroyed refs in declared slots). Runs only in the harness, so it costs nothing in production.
2. **A declarative manifest** — e.g. a class-level list of "world state fields and how each resets",
   with the teardown driven from it, so adding a field without classifying it is a visible omission.
3. **A build-time or test-time lint** cross-checking the serializer's world section against the reset
   path, mechanising §2's oracle so the two enumerations cannot silently drift apart.

If none proves practical, say so here with the reason — a documented "no guard, and why" is a valid
outcome; silently skipping Phase 4 is not.

---

## §4 Central risks

- **Over-resetting breaks product behaviour.** `resetWorld` is homepage-stripped so *it* is safe, but
  a collaborator's new `resetX()` is shared code — keep the reset method dumb and call it only from
  the teardown.
- **`preferencesAndSettings` is STATIC and serialized.** Resetting it may be correct for tests and
  wrong for `loadWorldSnapshot`, which restores it. Treat the two teardown paths separately; do not
  unify them without checking the snapshot round-trip (`fg gauntlet`'s `serialization` leg).
- **Reference churn is a RED FLAG here, not an outcome.** A correct fix makes tests independent of
  history; committed references were captured from a pristine world, so they should still pass. **If
  a reference "needs recapture", you have changed pristine-world behaviour — stop and diagnose.**
- **Phase 4 option 1 can be over-strict** and fail on legitimately-surviving state; build its
  allow-list from the Phase 2 "deliberately survives" rows.

---

## §5 Verification protocol

```
/Users/davidedellacasa/code/Fizzygum-all/fg status          # orientation, every phase
/Users/davidedellacasa/code/Fizzygum-all/fg build           # after any src edit
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests
node scripts/run-all-headless.js --shards=1 --dpr=1 --speed=fastest   # ~6 min — THE detector
/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet        # the standing gate (13 legs)
/Users/davidedellacasa/code/Fizzygum-all/fg homepage        # production-tree gate, to close
```

- **`--shards=1` is the detector for this bug class** (R1/R2) — it is an audit tool, not a new gate.
- **Zero reference churn is the expectation.** Any suite diff is a regression to diagnose (§4).
- Long ops: launch ONCE with the Bash tool's `run_in_background: true`, redirect to a log, and wait
  for the task notification. Never hand-roll a foreground poll loop (the guard hook blocks them).
  ⚠ While a long op runs, `fg`, `src/**` and `tests/**` are READ-ONLY — editing `src` mid-gauntlet
  trips the stale-build guard and invalidates the whole run (cost a run on 2026-07-28).

**Exit criteria:** every inventory row decided and either fixed or commented; Phase 4 delivered or
explicitly declined with a reason; gates green with zero reference churn. Then `git mv` this doc to
`docs/archive/`, stamp it, and add an `archive/INDEX.md` line.

---

## §6 Rejected / do-not-re-attempt

1. **Adding a `--shards=1` gate to `fg gauntlet`.** ⛔ Owner-declined 2026-07-28: ~6 min serial, too
   expensive. Residual coverage is `torture-headless.js`, which rotates `--shards=1,2,4,8`.
2. **Using `run-sequence-headless.js` as the oracle** — R3: it did not reproduce the 2026-07-28 leak
   even with all 268 tests in manifest order.
3. **Waiting for the next leak to surface and patching it.** That is the status quo this plan exists
   to end (2 instances, both found by accident).
4. **Recapturing references** to make a post-fix failure go away — §4.

---

## §7 References

- **`Fizzygum-tests/DETERMINISM.md` §2d** (the bug class + the WITHDRAWN SaveAs corollary) and
  **§3h** (the 2026-07-28 worked example, root cause and fix).
- `Fizzygum/docs/archive/suite-nondeterminism-flakes-plan.md` §2.7 — how flake C was found and solved,
  including the falsified-mid-investigation step and the s1 blind-spot finding.
- `Fizzygum/src/serialization/Serializer.coffee` — the world section (§2's oracle) and
  `WORLD_APP_SLOTS`.
- Memory: `resetworld-state-leak-between-tests` (the 2026-07-10 case),
  `suite-nondeterminism-flakes-arc` (the 2026-07-28 case).

## §7.5 EXECUTION RECORD — audit run 2026-07-29

Executed against Fizzygum `master` @ `bd4448c0`, Fizzygum-tests @ `4c2e8922f`, suite = 268.
Phase 1 was done read-only and in full before any code changed, as §0.5 requires.

### The instrument (and its R3 validation)

A direct state observer, `Fizzygum-tests/.scratch/resetworld-audit-probe.js` (scratch, gitignored):
for each mutation, in its own fresh harness page — fingerprint the pristine world, apply the
mutation, `resetWorld()`, fingerprint again, diff. This is a *state* observer, not a suite-replay
tool, so R3's objection to `run-sequence-headless.js` does not apply to it.

**R3 discipline honoured — the instrument was proved to detect BOTH known leaks before its silence
was trusted anywhere.** Neutralising the 2026-07-28 fix in-page (`resetCounters = ->`) made it
report `untitledNamingService.howManyUntitledShortcuts 0 → 1`; neutralising the 2026-07-10
highlight-set clears made it report all three highlight structures. A negative control (same
mutation, fixes intact) and a no-mutation baseline both came back CLEAN.

One instrument artefact to know about: a field declared on the PROTOTYPE and first *assigned* by
the teardown shows as `(absent) → nil`. That is own-ness changing, not value — the shipped guard
compares values read through the chain, so it does not have this artefact.

### Inventory + decisions

Every row was decided. **CONFIRMED** = the probe observed it surviving a real teardown.

| # | state | owner | verdict | evidence / reason |
|---|---|---|---|---|
| 1 | world **extent** + `automaticallyAdjustToFillEntireBrowserAlsoOnResize` | world | **RESET** | CONFIRMED `960x440 → 1024x768`. `stretchWorldToFillEntirePage` ("fit whole page", dev menu) latches both. Worst row found: every later test in the page renders at the wrong size. Restore is guarded on a real mismatch ⇒ no-op normally |
| 2 | `numberOfIconsOnDesktop` | world (proto default on `IconicDesktopSystemPanelWdgt`) | **RESET** | CONFIRMED `0 → 1` after one `makeFolder()`. It is the desktop grid cursor, so the next test's first icon moves a whole cell. A pure GEOMETRY leak — strictly worse than the 2026-07-28 name leak |
| 3 | `infoDoc_*_created` flags | world (own booleans, `InfoDocs.REGISTRY`) | **RESET** | CONFIRMED. One-shot guards: `createNextTo` early-returns, so a later test's app launch silently builds NO info doc |
| 4 | `WORLD_APP_SLOTS` (5) + `simpleEditorTemplates` | world | **RESET** | CONFIRMED dangling `…:DESTROYED`. §1's suspected asymmetry is REAL. `StorageSorter` marks both unconditionally each sort. Now matches `_teardownForSnapshotLoadNoSettle` |
| 5 | `isDevMode` | world | **RESET** | CONFIRMED `true → false`. Decides which context menu every widget builds. Pristine is boot's `true` (set in `globalFunctions.startWorld`), not the ctor's `false` |
| 6 | `WorldWdgt.preferencesAndSettings` (**static**) | `PreferencesAndSettings` | **RESET** (owner-side) | CONFIRMED: "touch screen settings" doubles menu/prompter fonts, sliders, scrollbars — and being static it outlives even a new world. New `resetToBootInputMode()`, self-guarded. NOT called from the snapshot teardown (§4: `loadWorldSnapshot` restores this bag) |
| 7 | `errorConsole` | world | **RESET** | CONFIRMED dangling `FrameWdgt:DESTROYED`. Worse than a dead ref: the reporter only builds one `if !@errorConsole?`, so every later paint error in the page reports into a dead widget — silently swallowing what the runners' fail-gate exists to catch |
| 8 | `wdgtsWithOngoingScrollMomentum` | world | **RESET** | CONFIRMED `Set(0) → Set(1)`. A panel destroyed mid-glide is never removed ⇒ `anyScrollMomentumOngoing()` true FOREVER ⇒ the macro pump's `waitNoInputsOngoing` never settles and later tests **STALL** rather than fail |
| 9 | `toolTipsList`, `openPopUps`, `freshlyCreatedPopUps`, `popUpsMarkedForClosure` | world | **RESET** | CONFIRMED. Same shape as the 2026-07-10 highlight sets: world-level, so `fullDestroyChildren` cannot reach them, and `Widget._destroyNoSettle` does not unregister from them (its standing TODO names exactly this gap). `PopUpWdgt` removes itself in the PUBLIC `destroy()`, which bulk teardown never calls — the 2026-07-23 shortcut bug verbatim |
| 10 | `temporaryHandlesAndLayoutAdjusters` | world | **RESET** | CONFIRMED `Set(0) → Set(5)` dead handles |
| 11 | `hierarchyOfClickedWdgts` / `…Menus` | world | **RESET** | Cleared per *click*, not per test ⇒ a test ending mid-gesture leaks |
| 12 | `lastEditedText` | world | **RESET** | CONFIRMED dangling `StringWdgt:DESTROYED` |
| 13 | `widgetsGivingErrorWhileRepainting` | world | **RESET** | Pushed to, never cleared anywhere — accumulated dead widgets for the life of the page |
| 14 | `trackChanges` stack | world | **RESET** | CONFIRMED `Array(1) → Array(2)`. Left unbalanced, every later test records NO broken rectangles — i.e. paints nothing |
| 15 | highlight/pinout sets, untitled counters, `_editorSelectedWidget`, bin/shelf, colour, wallpaper | world | already RESET | the pre-existing teardown; re-verified still correct |
| 16 | `wdgtsDetectingClickOutside…`, `editorFocusWdgt`, `hand.mouseOverList`, `hand.nonFloatDraggedWdgt` | world/hand | N/A | `_softResetWorld` |
| 17 | `steppingWdgts`, `keyboardEventsReceivers`, `widgetsReferencingOtherWidgets`, dataflow edges | world | N/A | `Widget._destroyNoSettle` unregisters; shortcuts do it in the CORE (2026-07-23 fix) |
| 18 | `dragEmbed*Declared` / `*Wdgt` (6) | world | N/A | **probed, not assumed**: `_softResetWorld`'s `hand.drop()` reaches `_endDragEmbedInteraction`, and the reconciler then destroys+nils the overlays. Came back clean even when left declared |
| 19 | per-class id counters | globals | N/A | `fullDestroyChildren` zeroes them |
| 20 | `broken`, `widgetsWithMaybeChanged*Bounds`, `errorsWhileRepainting`, `layoutErrorsToReport`, `healingRectanglesPhase`, `_inLayoutMutation`, … | world | N/A | per-cycle transients, re-established every `doOneCycle` |
| 21 | `frameCount`, `structure/visibility/geometryVersion`, `immutableBackBufferGeneration`, `incrementalGcSessionId`, `ongoingUrlActionNumber`, `dateOf*CycleStart` | **static/monotonic** | **SURVIVES** | monotonic BY DESIGN — zeroing them makes STALE caches look VALID, a worse bug than the one being guarded. The stall watchdog reads `frameCount` |
| 22 | `occlusionCullingEnabled`, `islandBufferCacheEnabled`, `dirtyRectListEnabled`, `deferredSettlingEnabled`, `showRedraws`, `audit*` | static/world | **SURVIVES** | measurement instruments a human/profiler sets for a WHOLE run; resetting per test would silently defeat the instrument. The one macro that flips them restores them itself and asserts the default |
| 23 | LRU text caches | world | **SURVIVES** | content-keyed memoisation, correct across worlds; clearing only costs time |
| 24 | `lastSerializationString` | world | **SURVIVES** | deliberate cross-test carrier (its own declaration says so) |
| 25 | `sourceEditsRegistry.records` | collaborator | **SURVIVES** | its records MIRROR live prototype edits, which a world teardown cannot undo. Clearing the log while the edited class survives would make the log LIE (and a snapshot embeds it). Convention stands: a test that edits a class restores it in its macro tail |
| 26 | `otherTasksToBeRunOnStep` | world | N/A (dead) | iterated once, never written — a dead field. Left alone (out of scope); noted here |

### One nondeterminism found and headed off

Restoring the prefs bag by re-running `setMouseInputMode()` re-derived `minimumFontHeight`, which
is a *glyph-rasterising pixel probe* — its answer depends on how warm the SWCanvas glyph atlas is
(DETERMINISM.md §3g/§3i), and the probe duly measured `9 → 10`. So `resetToBootInputMode` CARRIES
OVER the probed value instead of re-deriving it: that number measures the BROWSER, not the input
mode. Re-probing at a teardown could hand the next test a different number than boot measured.

### Phase 4 — the structural guard (delivered)

`WorldWdgt._auditWorldResetCompletenessNoSettle`, called at the end of `resetWorld` beside the
existing `storageSorter._auditStorageNoSettle()` — plan option 1, merged with option 2's spirit.

It fingerprints the world's own mutable state at the end of the FIRST teardown (which the harness
runs on a virgin world, since `resetWorld` is each test's first command) and re-checks it at the
end of every later teardown, emitting one greppable `RESETWORLD_INCOMPLETE` line per difference —
gated by both headless runners exactly like `NON_INTEGER_GEOMETRY` / `STORAGE_INVARIANT`.

The field universe is built so **both** ways a leak can appear are covered without anyone having to
remember to declare anything:
- a field ASSIGNED on the world (`@foo = x`) becomes an OWN property → swept directly;
- a class-body-declared CONTAINER mutated in place (`toolTipsList.add …`) stays on the prototype →
  the prototype chain is walked too, keeping every non-function, non-primitive (a primitive up
  there cannot be mutated in place; assigning to it creates an own property, already covered).

`WorldWdgt._worldStateAuditExemptions` is the allow-list, built from the SURVIVES rows above, each
with its reason in the comment. **That is what converts this from a fix into a ratchet:** a newly
added world field that nothing resets fails loudly the first time any test dirties it, and the only
way to silence it is to reset it or to name it an exception with a reason.

Two refinements the first suite run forced, both worth keeping:
- **Compare VALUES, never own-ness.** The first cut swept own properties plus prototype containers,
  so a prototype-declared field the teardown merely ASSIGNS (`@dragEmbedLabelDeclared = nil`) read as
  `(absent) → nil` and fired 1469 times on a green suite. Every field is now read as its EFFECTIVE
  value through the prototype chain. Own-ness is not state; the value is.
- **Derived caches are exempt BY RULE, not by name.** The geometry caches are declared in strict
  `cachedFoo` / `checkFooCache` pairs (Widget, TreeNode) and legitimately differ between teardowns,
  so `_isDerivedCacheFieldName` exempts the shape — which stays correct as new caches are added,
  where a hand-kept name list would rot.
- **⚠ The guard is LOAD-SENSITIVE for per-frame fields, and only the PARALLEL gauntlet showed it.**
  The world is a widget, so the sweep also sees Widget-level per-frame damage bookkeeping
  (`paintBoundsMaybeChanged`, `fullPaintBoundsMaybeChanged`, …). A teardown is *not* a frame
  boundary, so what it observes in those is simply where in the cycle it landed — identical across
  a quiet dpr1 suite, an s1 run and a serial gauntlet, but NOT under parallel load, where the
  `settle` and `storage` legs warned in-wave and passed serially. They are exempt now, cross-checked
  against the codebase's own independent enumeration of per-frame state (`Widget.serializationTransients`
  — every exempted name appears there). **Lesson: a state-fingerprint guard must be validated under
  the parallel gate, not only under the quiet inner loop; the quiet run cannot show this class.**

**The ratchet was proved to FAIL, not just to be silent** (a guard that has never fired is not
evidence of anything). Planting one leaking field — `@_leakCanaryTEMPORARY` bumped in `doOneCycle`,
i.e. a FIELD, not a no-op — made the suite emit 272 token lines naming the field with its pristine
and post-teardown values, and the runners duly failed 188 tests with an actionable message. The
canary was then removed and the suite went green and silent again.

### DELIBERATELY NOT DONE — the product-side twin (needs an owner call)

The audit was scoped to `_resetWorldNoSettle`, the TEST teardown, exactly as §0/§4 frame it. But
several of the dangling-ref rows above apply just as much to `_teardownForSnapshotLoadNoSettle`,
the product-safe twin `loadWorldSnapshot` uses — and there they are **product** bugs, not test
leaks, because `fullDestroyChildren` destroys the widgets there too:

- `errorConsole` — after a snapshot load the slot points at a destroyed console, so every later
  paint error in that session reports into a dead widget (the reporter only builds one
  `if !@errorConsole?`). Errors would silently vanish for a real user.
- `wdgtsWithOngoingScrollMomentum` — a panel gliding when the user loads a snapshot leaves a dead
  ref, and `anyScrollMomentumOngoing()` then answers true for the rest of the session.
- `toolTipsList` / `openPopUps` / `freshlyCreatedPopUps` / `popUpsMarkedForClosure` /
  `temporaryHandlesAndLayoutAdjusters` / `lastEditedText` — dead refs surviving a load.
- `numberOfIconsOnDesktop` — restored only `if section.numberOfIconsOnDesktop?`, so loading a
  snapshot that lacks it leaves the pre-load grid cursor in place.

**Not changed here on purpose:** §4 warns that over-resetting breaks product behaviour, that the two
teardown paths must be treated separately, and this one ships in `--homepage` and is covered by the
serialization rigs rather than by the suite. It is a small, well-evidenced follow-up arc — worth
doing, but it is a product-behaviour change and wants its own owner sign-off and a serialization
round-trip verification, not a silent ride-along on a test-infrastructure audit.

## §8 Provenance

Authored 2026-07-28 immediately after flake C (`UntitledNamingService` counters surviving
`resetWorld`) was root-caused and fixed — the second instance of this shape in three weeks. The
candidate list in §1/§3 and the §2 oracle were found while authoring, by reading the three teardown
paths and the serializer's world section against each other.

**Executed 2026-07-29** — see §7.5. The plan's §2 oracle (diffing the serializer's world section
against the teardown) did earn its billing: it directly produced the app-slot, `simpleEditorTemplates`,
`numberOfIconsOnDesktop`, `infoDoc*`, `isDevMode` and preferences rows. But it was a floor, not a
ceiling, exactly as §2 warned — the direct class sweep and the collaborator recursion found the rest,
including the two worst (`errorConsole` and `wdgtsWithOngoingScrollMomentum`), neither of which is
serialized and so neither of which the oracle could ever have named.

This doc closes the arc; the durable residue is `Fizzygum-tests/DETERMINISM.md` §2d (the bug class
and its ratchet), the in-code comments on `_resetWorldNoSettle` /
`_auditWorldResetCompletenessNoSettle` / `_worldStateAuditExemptions`, and the `Fizzygum/CLAUDE.md`
Testing entry for the new gate. The one deliberate carry-forward is the product-side twin (§7.5's
"DELIBERATELY NOT DONE"), tracked in `docs/BACKLOG.md`.

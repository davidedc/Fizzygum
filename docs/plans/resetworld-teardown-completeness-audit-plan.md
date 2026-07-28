# `_resetWorldNoSettle` completeness audit — make the world teardown PROVABLY total

**PLAN ONLY — AUTHORED 2026-07-28. Written to be executed COLD by an LLM/engineer with ZERO prior
context.** No audit has been run yet; everything below is preparation plus the candidate list found
while authoring. Every fact was verified against the working trees on 2026-07-28 (Fizzygum `master`
@ `a06f138c`, Fizzygum-tests `master` @ `3e9b9e83b`, suite = 268 SystemTests). **Line numbers WILL
drift — the quoted method/field names are authoritative; re-grep before trusting any `file:line`.**

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
- `Fizzygum/docs/plans/suite-nondeterminism-flakes-plan.md` §2.7 — how flake C was found and solved,
  including the falsified-mid-investigation step and the s1 blind-spot finding.
- `Fizzygum/src/serialization/Serializer.coffee` — the world section (§2's oracle) and
  `WORLD_APP_SLOTS`.
- Memory: `resetworld-state-leak-between-tests` (the 2026-07-10 case),
  `suite-nondeterminism-flakes-arc` (the 2026-07-28 case).

## §8 Provenance

Authored 2026-07-28 immediately after flake C (`UntitledNamingService` counters surviving
`resetWorld`) was root-caused and fixed — the second instance of this shape in three weeks. The
candidate list in §1/§3 and the §2 oracle were found while authoring, by reading the three teardown
paths and the serializer's world section against each other. **No audit has been executed.**

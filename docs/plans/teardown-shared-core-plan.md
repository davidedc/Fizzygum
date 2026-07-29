# Teardown shared core — ONE structural teardown, two callers

**PLAN ONLY — AUTHORED 2026-07-29. Written to be executed COLD by an LLM/engineer with ZERO prior
context.** No code has been written for this plan. Every fact below was verified against the working
trees on 2026-07-29 (Fizzygum `master` @ `ce674fa8`, Fizzygum-tests `master` @ `4a38fe8b7`, suite =
268 SystemTests, build FRESH, `fg gauntlet` green). **Line numbers WILL drift — the quoted
method/field names are authoritative; re-grep before trusting any `file:line`.**

**MANDATE.** *Eliminate the divergence class*, not the current divergence. Fizzygum has TWO world
teardowns that must agree about one thing — "drop every reference to what was just destroyed" — and
nothing makes them agree. They have already drifted twice, in both directions, and the drift is
invisible until it bites. The deliverable is ONE shared core that both callers invoke, so the
question "did the other teardown get this too?" stops being askable. A plan that only copies today's
missing lines into the second method has failed: it re-creates the exact hand-synchronisation this
plan exists to end.

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework rendered on one HTML5 canvas; three sibling repos
(`Fizzygum` source, `Fizzygum-tests` suite + harness, `Fizzygum-builds` generated output). Read the
root `CLAUDE.md`, then `Fizzygum/CLAUDE.md`. Use the `fg` wrapper
(`/Users/davidedellacasa/code/Fizzygum-all/fg`) for every build/test invocation — absolute path,
never `./fg`.

### Why this plan exists now

Its immediate predecessor is **`archive/resetworld-teardown-completeness-audit-plan.md`
(COMPLETE 2026-07-29, Fizzygum `46a0e604`)**. That audit took the TEST teardown
(`WorldWdgt._resetWorldNoSettle`) and made it provably complete: 26 rows inventoried and decided,
**14 leaks found and fixed**, plus a structural guard (`_auditWorldResetCompletenessNoSettle` →
the `RESETWORLD_INCOMPLETE` token, gated by both headless runners).

**The clue that started that audit was an asymmetry between the two teardowns** — the snapshot one
nil'd two things the test one didn't. That direction is now fixed. **This plan closes the reverse
direction, and then removes the ability to have a direction at all.**

### Critical reframes — do not re-derive these

- **R1: this is NOT "copy the audit's 14 fixes into the other method".** Most of the 14 are
  *pristine-restoration* (reset the desktop to grey, restore the harness canvas size) which the
  snapshot loader must NOT inherit — it restores those from the file. Only the *dangling-reference*
  half is common. Getting that boundary right IS the work; §4 decides it row by row.
- **R2: "the two teardowns differ because product vs test" is mostly FALSE, and believing it is what
  kept them apart.** Verified 2026-07-29: the snapshot teardown's omissions are overwhelmingly
  *redundancy* ("the loader sets colour/wallpaper itself a moment later"), not principle. The one
  structural reason there are two methods is that `_resetWorldNoSettle` is homepage-STRIPPED, so
  production cannot call it *whatever it contains*. That reason survives a shared core untouched —
  the core lives in shipping code and both callers reach it.
- **R3: two of the "borderline" rows are REAL PRODUCT BUGS, and one is not the one you'd guess.**
  Measured against the loader (§4): `infoDocFlags` restore is **additive-only**, so a flag set before
  a snapshot load survives it forever; and `trackChanges` is not serialized at all. Meanwhile
  `numberOfIconsOnDesktop`, `isDevMode`, `alpha` and the untitled counters are all restored
  unconditionally and are therefore **NOT** leaks on the snapshot path. Do not assume — §4 has the
  per-row evidence.
- **R4: arc 3 is NEXT and relocates this machinery to the tests repo.** Doing this plan FIRST
  shrinks what arc 3 must move and makes the move safer. Arc 3's own inventory line for this code is
  already badly stale. See §6 — read it before sequencing anything.

---

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — confirm clean trees, build FRESH, 268 tests.
2. Read this doc fully, then **`archive/resetworld-teardown-completeness-audit-plan.md` §7.5** (the
   inventory this plan splits) and **`Fizzygum-tests/DETERMINISM.md` §2d** (the bug class).
3. Do §3's verification spike (§5 Phase 0) BEFORE moving any code — it converts §4's table from
   "argued" to "measured", and it is ~20 minutes.
4. Phases run in order; gates per §8 at the end of EVERY phase.
5. **Never commit or push without explicit owner approval** (standing rule).
6. Budget: `fg build` ~1.5 min, `fg gauntlet` ~5 min, the two serialization rigs ~1 min each.
   Whole plan is comfortably one session.

---

## §1 The mechanism as it stands today

All in `Fizzygum/src/WorldWdgt.coffee` (grep the names; line numbers as of `ce674fa8`):

| symbol | line | ships in `--homepage`? |
|---|---|---|
| `_softResetWorld` | `:2480` | **yes** |
| `resetWorld` | `:2498` | no — inside `»>>` markers `:2489`–`:2790` |
| `_resetWorldNoSettle` | `:2513` | no |
| the completeness guard (`_worldStateAuditExemptions` `:2681`, `_summariseWorldStateValueNoSettle` `:2720`, `_isDerivedCacheFieldName` `:2740`, `_fingerprintWorldStateNoSettle` `:2754`, `_auditWorldResetCompletenessNoSettle` `:2775`) | `:2681`–`:2790` | no |
| `fullDestroyChildren` | `:2801` | **yes** |
| `loadWorldSnapshot` | `:2879` | **yes** |
| `_teardownForSnapshotLoadNoSettle` | `:2966` | **yes** |

**Sizes (measured):** `_resetWorldNoSettle` is **42 code lines** (168 including its comments);
`_teardownForSnapshotLoadNoSettle` is **5 code lines**:

```coffee
_teardownForSnapshotLoadNoSettle: ->
  @fullDestroyChildren()
  @binWdgt?.empty()
  @shelfWdgt?.empty()
  @[slot] = nil for slot in Serializer.WORLD_APP_SLOTS
  @simpleEditorTemplates = nil
```

Both are called inside exactly one `@_settleLayoutsAfter =>` wrap by their public entry
(`resetWorld` `:2498`; `loadWorldSnapshot` step 1, `:2889`), so **the shared core is a NoSettle-tier
core** and must stay one: no self-settling public setter may move into it (see §7).

`fullDestroyChildren` runs in BOTH. That is the whole reason the dangling-ref half is common: it
destroys the widget TREE and zeroes every per-class `lastBuiltInstanceNumericID`, but it cannot reach
world-level state held *outside* the tree — so every world field still pointing at a destroyed widget
dangles identically on both paths.

## §2 Why it is shaped this way

`_teardownForSnapshotLoadNoSettle` was written as the *product-safe twin* when whole-world snapshots
landed. Its in-code comment states the intent exactly: *"mirrors `_resetWorldNoSettle` but
product-safe: no `@_changed`/`scrollTop`/`setColor` — the loader re-establishes those."*

That framing is accurate but incomplete, and the incompleteness is the bug. "Product-safe" correctly
excluded the *pristine-look* half. It never said anything about the *dangling-reference* half — which
is not a product-vs-test question at all. So when the test teardown grew a new dangling-ref clear
(2026-07-10, 2026-07-28, and ×14 on 2026-07-29), nothing suggested the twin needed it too, and
nothing detects the omission.

## §3 The distilled argument

1. **The two methods share an obligation neither one owns.** `fullDestroyChildren()` creates dangling
   references; whoever calls it must drop them. Both call it. Neither method's name or comment says
   "and I am responsible for the dangling refs", so the responsibility keeps getting satisfied on one
   path and forgotten on the other.
2. **The drift is real, bidirectional, and historically demonstrated.** 2026-07-28: the snapshot twin
   had two nils the test path lacked. 2026-07-29: the test path gained fourteen the twin lacks. Two
   drifts in two days, in opposite directions, is not bad luck — it is an unowned invariant.
3. **The ratchet does not cover the product path.** The 2026-07-29 guard fires only from `resetWorld`.
   A shared core is what extends that hard-won coverage to `loadWorldSnapshot` **for free**: exercising
   the core through the suite necessarily exercises what the loader calls.
4. **It shrinks arc 3.** Arc 3 must relocate the test teardown to the tests repo verbatim. Every line
   that becomes shared, shipping core is a line arc 3 no longer has to move (§6).
5. **Why now, not later:** arc 3 is the next arc and touches exactly this code. Doing it after arc 3
   means refactoring across a repo boundary instead of within one file.

## §4 THE CLASSIFICATION — decided, with evidence

The contract that decides every row:

> **The shared core's job is: after `fullDestroyChildren()`, the world holds NO reference to anything
> that was just destroyed, and no bookkeeping that assumed it still exists.**
> Restoring what the world should LOOK like afterwards is the CALLER's job — pristine grey for the
> test path, the file's contents for the loader.

### Rows that MOVE INTO the shared core `_teardownWorldStructureNoSettle`

Every one is a reference to (or a collection of) widgets `fullDestroyChildren` just destroyed:

| row | why shared |
|---|---|
| `fullDestroyChildren()` | the destruction itself; both already call it |
| `binWdgt?.empty()`, `shelfWdgt?.empty()` | off-tree storage containers; both already call these |
| the 5 `Serializer.WORLD_APP_SLOTS` + `simpleEditorTemplates` | already in BOTH after the audit — folding them in removes the first duplication |
| the 6 highlight/pinout sets | dead refs to destroyed targets AND destroyed overlay widgets |
| `errorConsole`, `lastEditedText`, `_editorSelectedWidget` | bare refs to destroyed widgets |
| `toolTipsList`, `openPopUps`, `freshlyCreatedPopUps`, `popUpsMarkedForClosure`, `hierarchyOfClickedWdgts`, `hierarchyOfClickedMenus`, `temporaryHandlesAndLayoutAdjusters`, `wdgtsWithOngoingScrollMomentum` | collections of destroyed widgets |
| `widgetsGivingErrorWhileRepainting = []` | list of destroyed widgets; never cleared anywhere else |
| **`trackChanges = [true]`** | **REAL (mild) product leak — see below** |
| **the `infoDoc*` flags** | **REAL product leak — see below** |

**`trackChanges` — evidence.** It is a stack (`disableTrackChanges` pushes `false`,
`maybeEnableTrackChanges` pops). It is **not serialized** (grep `Serializer.coffee`: no
`trackChanges`) and **not restored** by `loadWorldSnapshot`. So a stack left unbalanced when the user
loads a snapshot stays unbalanced, and `Widget._changed()` reads
`world.trackChanges[world.trackChanges.length - 1]` — a `false` top means damage stops being recorded
and the world stops repainting. Low likelihood, catastrophic effect, one line to remove.

**`infoDoc*` flags — evidence, and this one is a certain live bug.** The serializer captures every
own `infoDoc*` property (`Serializer.coffee` `:135`); the loader applies them with
`@[name] = val for own name, val of (section.infoDocFlags or {})` (`WorldWdgt.coffee` `:2919`) —
**additive only. It never deletes a flag the live world has that the snapshot lacks.** So: create the
Dashboards Maker info doc, then load a snapshot saved before it existed → the flag survives →
`InfoDocs.createNextTo` early-returns forever and that info doc can never be created again in the
loaded world. Clearing them in the shared core fixes this exactly: teardown empties, loader fills.

### Rows that STAY test-only in `_resetWorldNoSettle`

| row | why it stays |
|---|---|
| `@_changed()` | pure repaint; the loader ends with `@_fullChanged()` twice (immediately + after async asset decode) |
| `setColor` grey, wallpaper → `pattern1` | the *pristine look*. The loader restores both from the snapshot (step 8). Also: both are **self-settling public** ops, sanctioned by an explicit comment in the test path only — moving them into a shared NoSettle core would need re-sanctioning for no benefit (§7) |
| the world EXTENT + `automaticallyAdjustToFillEntireBrowserAlsoOnResize` (via `_bootExtent`) | restores the 960×440 **harness** resolution; `_sizeCanvasToTestScreenResolution` is itself homepage-stripped |
| `document.body.scrollTop = 0` | harness ergonomics — its own comment says *"so we can see the test results while tests are running"*. On a product load it would yank the user's page scroll |
| `untitledNamingService.resetCounters()`, `numberOfIconsOnDesktop = 0`, `isDevMode = true`, `preferencesAndSettings.resetToBootInputMode()` | **verified NOT leaks on the snapshot path** — the loader restores all four unconditionally (`section.untitledNamingCounters` is always written as an object literal; `section.isDevMode` unconditionally, and `false?` is true in CoffeeScript so it always restores; `numberOfIconsOnDesktop` likewise, prototype default `0` and `0?` is true; `preferences` restores the whole bag). Moving them buys nothing measurable and each is a product-behaviour change needing rig re-verification. `resetToBootInputMode` is additionally homepage-STRIPPED, so sharing it would mean un-stripping product code for no demonstrated gain |

⚠ **The last row is the one to re-check if this plan is executed after any change to `loadWorldSnapshot`.**
Its "not a leak" status depends entirely on the loader restoring those four unconditionally. If a
future edit makes any of them conditional, that row becomes a leak and moves into the shared core.
The Phase 0 spike (§5) pins this empirically so the executor does not have to trust this paragraph.

### Considered and NOT chosen

A **fuller contract** — "the shared core clears ALL previous-world state including the four scalars
above" — is cleaner to state and would be defensible. Rejected for this arc because it converts four
verified-harmless rows into product-behaviour changes, tripling the blast radius for zero measured
defect. Revisit only if the Phase 0 spike shows one of them actually leaking.

## §5 Phases

### Phase 0 — the spike (do this FIRST; read-only + throwaway)

Prove §4's product-leak claims and its "not a leak" claims empirically, so the split rests on
measurement rather than on reading the loader. Write a throwaway probe under
`Fizzygum-tests/.scratch/` (gitignored — ⚠ NOT the session scratchpad: Node resolves `require()`
from the SCRIPT's directory, so a scratchpad copy dies with `MODULE_NOT_FOUND`). Model it on
`.scratch/resetworld-audit-probe.js` from the predecessor arc, which already boots
`worldWithSystemTestHarness.html` and diffs a world fingerprint.

For each of: `infoDoc_dashboardsMaker_created`, `trackChanges`, `numberOfIconsOnDesktop`,
`isDevMode`, the untitled counters, `errorConsole`, `wdgtsWithOngoingScrollMomentum` —
dirty it, `world.saveWorldSnapshotToFile`-equivalent (build the envelope via
`Serializer.serializeWorld world`), then `world.loadWorldSnapshot(envelope, skipConfirm: true)`,
then read the field back. **Expected:** the `infoDoc` flag and `trackChanges` survive (leaks);
the four scalars come back as the snapshot's values (not leaks); `errorConsole` and the momentum set
hold destroyed/dead refs. Record the actual results in this doc before proceeding — **if the spike
contradicts §4, re-decide §4 rather than pushing on.**

### Phase 1 — extract the shared core (behaviour-preserving for the TEST path)

Add `_teardownWorldStructureNoSettle` in the SHIPPING part of `WorldWdgt.coffee` (outside the `»>>`
markers — put it next to `_teardownForSnapshotLoadNoSettle`), containing exactly the §4 "shared"
rows. Have `_resetWorldNoSettle` call it and keep only its test-only remainder. **Do not touch
`_teardownForSnapshotLoadNoSettle` yet.** Gate: full §8. This phase must be zero-churn and
zero-behaviour-change — the test path runs the same statements in the same order.

⚠ Preserve statement ORDER within the core exactly as `_resetWorldNoSettle` has it today
(`fullDestroyChildren` first). The audit's comments explain several orderings; carry the comments
with the lines — they are the arc's durable residue and must not be summarised away.

### Phase 2 — point the snapshot teardown at the core (the product change)

Replace `_teardownForSnapshotLoadNoSettle`'s body with a call to the shared core. Its five current
lines are all in the core, so the diff is a deletion plus one call. **This is the phase that changes
shipped behaviour** — it fixes the `infoDoc`/`trackChanges` leaks and drops the dangling refs.
Gate: full §8 **including both serialization rigs**, which is the real gate here.

Decide while here whether `_teardownForSnapshotLoadNoSettle` still earns its own name: if it becomes
a pure one-line alias, prefer deleting it and having `loadWorldSnapshot` call the core directly
(the codebase's `thin-wrap` gate has opinions about pointless wrappers — run it and follow it).

### Phase 3 — lock it so it cannot drift again

The point of the arc. At minimum, a rig check in
`Fizzygum-tests/scripts/serialization-roundtrip-headless.js` in the style of the existing
**pop-up snapshot hygiene** gate (`:1124`, `inPageWorldPopUpSnapshot`, results pushed as
`{name, desirable, detail}`): after a `loadWorldSnapshot`, assert that **no world slot holds a
destroyed widget** and the known collections are empty — i.e. the loader's teardown really did drop
everything. Drive it through the real load path, not by poking fields.

Consider also extending the existing `RESETWORLD_INCOMPLETE` guard to the load path. ⚠ It cannot be
reused as-is: it compares against a *pristine* fingerprint, and a snapshot load deliberately installs
new state, so the check would have to run BETWEEN the core and the restore. If that proves awkward,
the rig check above is sufficient — say so here with the reason rather than leaving it implied.

## §6 Arc 3 interaction — READ BEFORE SEQUENCING

`docs/plans/build-arc-3-world-harmonization-plan.md` is the NEXT arc. Its Phase 4 relocates
`resetWorld`/`_resetWorldNoSettle` to the tests repo as **verbatim moves only**, installed onto the
prototype from a new `Automator-and-test-harness-src/WorldTestSupport.coffee`.

- **Do this plan BEFORE arc 3.** Every row that becomes shared, shipping core is a row arc 3 does not
  move. Arc 3's job shrinks to the genuinely test-only remainder, and "verbatim move" gets safer
  because the moved code is smaller and no longer carries product obligations.
- **Arc 3's inventory line for this code is STALE and must be corrected by whoever runs it.** It
  records `` `:2469` (~66 l) resetWorld/_resetWorldNoSettle ``. As of `ce674fa8` the homepage-stripped
  block is **`:2489`–`:2790` — 302 lines**, because the 2026-07-29 audit added ~14 resets and the
  ~110-line completeness guard. Arc 3 must move the guard too (`_worldStateAuditExemptions`,
  `_summariseWorldStateValueNoSettle`, `_isDerivedCacheFieldName`, `_fingerprintWorldStateNoSettle`,
  `_auditWorldResetCompletenessNoSettle`) — it is test-only tooling and belongs with the harness.
- **A relocated test teardown calling a shipping core is the RIGHT direction** (harness code calling
  core methods is the normal dependency), so the shared core does not obstruct the move. Verify the
  reverse never appears: shipping code must never call anything that lives in the tests repo.
- After this plan lands, **update arc 3's §-inventory line** with the new span and the reduced move
  list. Leaving it stale is how the next executor mis-scopes Phase 4.

## §7 Central risks

- **The core must stay NoSettle-tier.** Both callers already wrap it in `_settleLayoutsAfter`. Do not
  move `setColor`/`setPattern` (self-settling public ops) into it: the test path calls them under an
  explicit `public-call-sanctioned` comment, and the loader deliberately calls them OUTSIDE its settle
  wrap (step 8). Mixing tiers here is how the flow-violation throw gets reintroduced.
- **Phase 2 changes shipped behaviour.** The serialization rigs are the gate, not the screenshot
  suite. `fg gauntlet`'s `serialization` leg runs BOTH rigs — do not treat a green suite as
  sufficient for Phase 2.
- **Reference churn is a RED FLAG, not an outcome.** The test path's behaviour must not change at
  all. If a screenshot "needs recapture", Phase 1 was not behaviour-preserving — stop and diagnose.
  (Standing case law: `dont-let-recapture-churn-dictate-design`, and the predecessor arc landed
  14 fixes with ZERO churn.)
- **Do not summarise the audit's comments away while moving lines.** Those comments name what would
  leak and why; they are the reason the next person does not re-open the hole. Carry them verbatim.
- **`_softResetWorld` is NOT part of this.** It is the INPUT-side reset (hand drop, mouse-over list,
  click-outside set), it already ships, and its `hand.drop()` self-flushes so it must stay outside
  any settle. Leave it alone.

## §8 Verification protocol

```
/Users/davidedellacasa/code/Fizzygum-all/fg status          # orientation, every phase
/Users/davidedellacasa/code/Fizzygum-all/fg build           # after any src edit
/Users/davidedellacasa/code/Fizzygum-all/fg presuite        # inner loop, ~3.5 min
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests
npm run test:serialization                                  # rig 1 — THE Phase 2 gate
npm run test:serialization:file                             # rig 2
/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet        # standing gate, 13 legs, ~5 min
/Users/davidedellacasa/code/Fizzygum-all/fg homepage        # production tree — Phase 2 ships
```

- **Zero reference churn is the expectation** for every phase.
- `RESETWORLD_INCOMPLETE` must stay silent throughout (`grep -c` the leg logs); it firing means the
  extraction dropped a reset.
- Long ops: launch ONCE with the Bash tool's `run_in_background: true`, redirect to a log, wait for
  the task notification. Never hand-roll a foreground poll loop (the guard hook blocks them).
  ⚠ While a long op runs, `fg`, `src/**` and `tests/**` are READ-ONLY.
- **Exit criteria:** one shared core; both callers on it; the two product leaks fixed and proven
  fixed by a rig check; arc 3's inventory line corrected; gates green with zero churn. Then
  `git mv` this doc to `docs/archive/`, stamp it, add an `archive/INDEX.md` line.

## §9 Rejected / do-not-re-attempt

1. **Copying the audit's 14 fixes into `_teardownForSnapshotLoadNoSettle`.** That is the status quo
   mechanism (hand-synchronised twins) which has already drifted twice in two days. It also would
   import the pristine-restoration rows, which are wrong for the loader.
2. **Unifying the two teardowns completely** (one method, a `forTests` boolean). Rejected: the flag
   would gate ~8 statements, and `_resetWorldNoSettle` is homepage-stripped while the core must ship —
   a single method cannot be both. §4's split is the seam the strip boundary already forces.
3. **Moving `setColor`/wallpaper into the shared core.** §7 — tier violation, and the loader
   deliberately calls them outside its settle wrap.
4. **Moving the four verified-harmless scalars into the core** (§4 "Considered and NOT chosen") —
   unless Phase 0 shows one of them actually leaking.
5. **Reusing `_auditWorldResetCompletenessNoSettle` unchanged on the load path** — it asserts a
   *pristine* world, which a snapshot load is not. §5 Phase 3.

## §10 References

- **`archive/resetworld-teardown-completeness-audit-plan.md`** — the predecessor arc; §7.5 is the
  full 26-row inventory this plan splits, and its "DELIBERATELY NOT DONE" section is this plan's seed.
- **`plans/build-arc-3-world-harmonization-plan.md`** — the next arc; §6 above is binding on it.
- `Fizzygum-tests/DETERMINISM.md` §2d — the bug class + the `RESETWORLD_INCOMPLETE` ratchet.
- `docs/architecture/serialization-duplication-reference.md` §11 — the whole-world snapshot format.
- `Fizzygum/src/serialization/Serializer.coffee` — `WORLD_APP_SLOTS` (`:20`), the world section (`:126`).
- Memory: `resetworld-state-leak-between-tests` (this bug class, ratcheted),
  `settle-tier-teardown-flip` (the passes-alone-but-STALLS-in-suite signature of a teardown whose
  tier/order drifted — the Phase 1 extraction's failure mode),
  `no-serialization-compat-obligations` (there are no saved documents to stay compatible with —
  relevant to Phase 2, which changes what a load leaves behind).

## §11 Provenance

Authored 2026-07-29, immediately after the teardown-completeness audit closed, in answer to the
owner's question "why would resetting colour/wallpaper first be *wrong*?" — the honest answer was
that it mostly would not be, which exposed that the two teardowns diverge much less on principle than
their shapes suggest, and therefore that a shared core is available. The §4 evidence (which rows are
real product leaks and which are not) was measured against the loader and serializer while authoring;
Phase 0 exists to confirm it empirically before any code moves.

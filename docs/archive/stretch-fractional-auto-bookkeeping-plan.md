> **ARCHIVED — COMPLETE (executed 2026-08-05, same day as authoring; P0→P4 single session).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Stretch-panel fractional bookkeeping becomes FRAMEWORK-OWNED — the caller-remember protocol is deleted

**STATUS: ✅ EXECUTED IN FULL — 2026-08-05, same day as authoring, single session (P0→P4).
The mechanism that landed is SHARPER than §4's first draft, corrected three times by
measurement (the §8 ledger is the authoritative record): the deferred seed is FILL-ONLY
(existing bookkeeping — builder's, drop's, island-transferred — is authoritative; overwriting
churned 7 tests), the imposers stay on the polymorphic plain twins (F3 falsified BOTH ways:
extent needs the schedule-valve's second re-lay, position needs the island's anchor-carrying
override), and the F6 RE-RECORD family (drop / duplicate / file-load / re-home / spawnNextTo /
uncollapse / NEW: handle-release) is the named exception the fill-only law requires. 33 of 41
manual call sites DELETED; the Widget TODO retired. FOUND+FIXED product bug: a handle-resize
of a stretch child snapped back on the next reflow (nothing re-recorded) — fixed via
`world.pendingFractionalReRecords` drained post-flush, fed by `HandleWdgt.mouseUpLeft`. TWO
new SystemTests pin the fraction VALUES (suite 278→280), both proven non-vacuous. Gates:
gauntlet 14/14 (264s) + homepage; 15 benign inspector recaptures (seeded fields visible in
lists), gated COMPLETE.**

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-05; every citation verified against Fizzygum `e7dd9b42` / Fizzygum-tests
`bd1fa4af0` (both pushed, 278 SystemTests, gauntlet 14/14 green). ⚠ Line numbers drift — the
quoted method/class names are authoritative; re-grep before trusting a line.

**MANDATE.** Completely ELIMINATE the "caller must remember" protocol for fractional layout
bookkeeping: after this arc, NO call site anywhere may need to call
`_rememberFractionalSituationInHoldingPanel()` for ordinary placement — the framework records
the bookkeeping itself at the right structural moments, the ~30 hand-written builder calls are
DELETED (not wrapped, not relocated), and the `Widget` TODO that asks for exactly this is
retired. New behavior is pinned by NEW resize-reflow SystemTests (owner-directed: the plan must
provide the tests, because a wrong-but-stable fraction is INVISIBLE to every existing gate —
see §3).

---

## §0 Orientation

**Fizzygum** — CoffeeScript canvas GUI framework, ~505 classes, no modules; build/test via the
`fg` wrapper from the umbrella root (`fg build` / `fg presuite` ~2 min / `fg gauntlet` ~5 min —
launched ONCE in background with a log, wait for the task notification; never edit src/tests
while a run is live). Read `Fizzygum/CLAUDE.md` + `Fizzygum-tests/CLAUDE.md` first.

**Where this plan comes from.** The layout program of 2026-06/08 unified almost everything:
per-child `layoutSpec` objects (nil = free-floating) for stacks/divisions/frames, the ordered
down-walk, the census oracle (which since 2026-08-05 certifies the AS-BUILT tree too —
`docs/archive/census-as-built-extension-plan.md`). The one per-child layout mechanism still
OUTSIDE all of that is the stretchable panel's fractional bookkeeping: three plain fields on the
child (`positionFractionalInHoldingPanel` `[fx,fy]`, `extentFractionalInHoldingPanel` `[fx,fy]`,
`wasPositionedSlightlyOutsidePanel`), written by a method every placement site must remember to
call. `Widget._rememberFractionalSituationInHoldingPanel` carries the founding TODO verbatim:

> TODO this is used a lot, where I suspect all we need to do is to do this automatically ALSO
> when a widget is added/moved to a new parent. I don't dare to do this now because I don't
> have enough tests in the new environment to check for bad implications.

That blocker ("not enough tests") is stale: the suite is 278 byte-exact tests, the census
certifies as-built trees, and this plan ADDS the reflow tests the TODO wished for.

**CRITICAL REFRAME (read before choosing a fix shape).** The naive hook points are all wrong,
and two of them are wrong for doctrine-level reasons this repo has already paid to learn:
1. **Record inside the raw apply funnel (`_applyMoveBy`/`_applyExtent`/…) — FORBIDDEN.** The
   immediate mutators are deliberately PURE GEOMETRY since the notify-by-mutation seam was
   deleted (2026-07-01; see the `_applyMoveBy` comment block in `Widget`). A bookkeeping write
   in the funnel is that seam reborn. It also drifts: the stretch arrange itself imposes
   geometry through the plain twins, so imposition → integer round → re-derive would corrupt
   fractions a little on every holder resize.
2. **Record at add time only — INSUFFICIENT.** Many real sites place AFTER adding (the
   sample-slide `mapPin`; `BinOpenerWdgt` adds the bin window then `_applyBounds`; the
   app-launch re-home moves after `world.add`). A seed captured at the add would pin
   pre-placement geometry.
3. **The correct shape is a DEFERRED SEED**: reparenting into a fractional-consuming holder
   *requests* bookkeeping; the derivation runs once, later, at a sanctioned engine point after
   the current JS turn's builder code has finished placing things — "last write wins", which is
   exactly the semantics the 40 manual calls implement by hand today (every one of them is
   place-then-remember-LAST).

## §1 Current state (verified 2026-08-05 at `e7dd9b42` — all counts re-counted)

**The three fields** (declared `Widget.coffee` ~:333) ride the CHILD, not the holder. They are
plain instance fields — serialized by the normal walk (zero mentions under `src/serialization/`,
i.e. no exclusion), duplicated by the normal deepCopy walk.

**Writers** — `Widget._rememberFractionalSituationInHoldingPanel` (~:2160) = position + extent +
outside-flag, all derived from `_enclosingIslandFigure()` vs `fig.parent` (the figure resolution
makes it island-safe; no-op when orphan: `return if !fig.parent?` in each half).

**Consumers — exactly TWO, and they consume differently:**
- `StretchablePanelWdgt._reLayout` (~:52-67): for every non-handle child, imposes BOTH position
  and extent fractions (`_moveInStretchablePanelToFractionalPosition` +
  `_setExtentToFractionalExtentInPaneUserHasSet`, `Widget` ~:2075/:2085), then re-lays the
  child. Line ~:58 carries the §5b SELF-HEAL: a child with missing fields gets them lazily
  derived from its current place ("self-healing; byte-identical when the data is already
  present"). ⚠ The heal is a crash guard, not a default: it can pin PRE-PLACEMENT geometry if
  an arrange runs between add and the builder's later move (the add's own settle does exactly
  that).
- `WorldWdgt._reLayoutDesktop` (~:1922-1952), on world/browser resize: POSITION-only.
  Bin-opener + clock use fractions only `if userMovedThisFromComputedPosition` (a separate flag
  set in `BinOpenerWdgt._reactToBeingDropped` when dropped on the world); every other non-icon
  child (`!child.isDesktopIcon?()`) gets `_moveInDesktopToFractionalPosition()` if it HAS
  fractions, and `_moveWithin @` unless `wasPositionedSlightlyOutsidePanel`. Note the
  desktop applier deliberately skips NEGATIVE fractional components (its comment: a widget
  hanging off the left edge must not slide right as the browser shrinks).

**The appliers use the PLAIN twins today** (`@_applyMoveTo` / `@_applyExtent`) even though they
are arrange-owned geometry — see §4 F3.

**Call-site inventory: 41 total** (grep `_rememberFractionalSituationInHoldingPanel` with BOTH
spellings — 40 plain `()` calls plus FileLoading's `?()` — comment lines excluded; P0 verified
2026-08-05). Classified:

*Framework lifecycle (KEEP or absorb into the new mechanism — 6):*
1. `Widget._reactToBeingDropped` ~:3816 — the gesture default (drop records). KEEP (or absorb, §4 F5).
2. `Widget.duplicateMenuAction` ~:3439 — world.add + offset move + remember. Absorbable.
3. `StretchablePanelWdgt._reLayout` ~:58 — the §5b heal. KEEP (interim values between add and seed).
4. `serialization/FileLoading` ~:57 — load: world.add + optional move + remember (note the `?.`). Absorbable.
5. `FrameWdgt` ~:678 (uncollapse re-fit) — re-records own extent fractions after uncollapse
   restores the extent. A GEOMETRY-CHANGE re-record, not a placement record — see §4 F7.
6. `StretchableWidgetContainerWdgt.smartPlace` ~:121 — moves THEN adds (orphan move, remember
   no-ops pre-add… verify: it moves, adds, then remembers — the remember is post-add). Deletable
   once the seed lands (place-before-add order is already seed-correct).

*Manual placement-protocol sites (DELETE — the arc's target, 35):*
- `SampleDashboardApp` ×15, `DegreesConverterApp` ×8, `SampleSlideApp` ×5,
  `IconicDesktopSystemWindowedApp.launch` ×1 (the bring-up re-home),
  `IconicDesktopSystemShortcutWdgt` ×1 (spawnNextTo), `BinOpenerWdgt` ×2 (windowed bin /
  spawnNextTo), `WindowsToolbarCreatorButtonWdgt` ×1, `HowToSaveMessageApp` ×1, `InfoDocs` ×1.
- ⚠ SOME of these are DEAD calls: the sample-slide `usaMap`/`mapPin` record against the SCROLL
  panel's contents `PanelWdgt` — a holder NEITHER consumer reads. P0 verifies and the deletion
  commit says so per site.
- ⚠ Order-of-operations per site varies: SampleDashboard/mapCaption/wikiLink/slide-window place
  BEFORE add (seed-at-add would already be right); mapPin/BinOpener/app-launch place AFTER add
  (these are why the seed is DEFERRED). P0 re-verifies each.

**The island transfer** — `Widget._moveHoldingPanelBookkeepingTo` (~:1658) moves the three
fields (+ `_stackElementSpec`) content↔island across sugar materialize/dematerialize, because
the holder's `_reLayout` reads them off the child it iterates. Any new mechanism must keep this
working (the seed operates on the FIGURE via `_enclosingIslandFigure()`, same as the recorder).

**Adjacent mechanisms NOT in scope** (they go with the big arc,
`docs/archive/stretch-layout-spec-unification-plan.md`): `layoutSpec` objects,
`_stackElementSpec`, folding the three fields into a `LayoutSpec` subclass.

**Existing test cover:** `macroDropIntoRotatedStretchablePanelStretchesOnResize` and
`macroRotateChildInsideStretchablePanelThenResize` pin the DROP path's reflow.
`macroSampleDashboardPlots` / `macroDegreesConverterFourWayDrive` /
`macroSampleSlideEditViewToggle` open the programmatic flows but (P0 to confirm) do NOT resize
the containers — so today NO test pins programmatic-add reflow, which is why the manual calls
could rot silently (and why some are dead).

## §2 Why it is shaped this way

The fractional mechanism predates the layout program (Morphic heritage): "remember where you
were put, proportionally" was bolted onto each app builder as apps were written, and the drop
hook made the GESTURE path automatic years later. The §5b heal was added during the frame-model
B closeout as a crash guard (a foreign child aborted the whole relayout pass as LAYOUT_ERROR).
Nobody designed "caller must remember" — it accreted, one app at a time, which is exactly why
the TODO sits unresolved on the recorder.

## §3 The distilled argument

The manual idiom's semantics is uniform across all 34 sites: *place, then record LAST — the
last write wins*. A deferred seed (request at reparent, derive once at the next engine
checkpoint after builder code ran) implements the same semantics centrally, without touching
the purified mutators and without per-site knowledge. The census CANNOT gate this (a wrong
fraction is a wrong-but-STABLE state — the truth re-lay moves nothing; only a holder RESIZE
reveals it), so the arc's oracle is the NEW reflow tests plus the byte-exactness of the
existing suite (all current flows must produce byte-identical fractions, since the seed derives
the same values from the same final geometry the manual calls read today). Now is the right
time: the suite is 278, the census as-built extension just landed the habit of proving gates
non-vacuous, and the big-arc spec-family fold (companion plan) wants this protocol gone first.

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — expect Fizzygum at/past `e7dd9b42`,
   tests at/past `bd1fa4af0`, both clean, 278 SystemTests. Build FRESH or run
   `/Users/davidedellacasa/code/Fizzygum-all/fg build`.
2. Read this plan in full; read `Widget.coffee` regions: the recorder + TODO (~:2140-2170), the
   appliers (~:2055-2090), `_applyMoveBy`/`_applyMoveByBase` comment block (~:2000-2035),
   `_applyExtent` comment block (~:2255-2300), `_moveHoldingPanelBookkeepingTo` (~:1650-1670),
   `_reactToBeingDropped` (~:3814); `StretchablePanelWdgt._reLayout` in full;
   `WorldWdgt._reLayoutDesktop` (~:1922-1952). Grep every §1 count fresh.
3. Execute phases in order (P0 → P4). Per batch: `fg presuite` (background + log + verdict);
   phase close: `fg gauntlet` (caffeinate). ⚠ Never edit src/tests while a run is live. Two
   falsified fix shapes on one problem = stop and re-frame (memory:
   `stop-iterating-fix-shapes-after-two-falsifications`).
4. Ad-hoc Node probes go under `Fizzygum-tests/.scratch/` (never the session scratchpad — Node
   resolves `require` from the script's dir).
5. Commits: present messages at the end (`git commit -F <file>`), never commit/push without the
   owner's word.

## §4 Fix shape

**F1 — the holder capability.** `Widget.consumesFractionalChildGeometry: -> false`; overridden
`true` on `StretchablePanelWdgt` and `WorldWdgt`. (Class-level query, the type-test-elimination
idiom — no instanceof at call sites.)

**F2 — the deferred seed (the core).** In the ONE parenting funnel (`Widget.__add`, the core
above `TreeNode._addChild` — P0 verified there is no second funnel, and that builders add via
`_addNoSettle`, so the hook must sit at the core, not the public add): if the new parent
`consumesFractionalChildGeometry()` and the child participates (see exclusions), enqueue the
child in the world-level `world.pendingFractionalBookkeepingSeeds` Set. The drain runs once
per cycle as a drain station in `doOneCycle` (with dataflow/storage, before
`recalculateLayouts`). Drain = for each pending widget still figure-parented in a consuming
holder and not destroyed: `_rememberFractionalSituationInHoldingPanel()` — **FILL-ONLY: only
when the FIGURE's bookkeeping is missing, NEVER overwriting existing values** (P1 measured
the overwriting form churning 7 tests — see the ledger: existing values may be a builder's
deliberate record, a drop's, or values the island wrap TRANSFERRED via
`_moveHoldingPanelBookkeepingTo` where the island's box differs from the figure the values
came from; and a re-derive over an integer imposition drifts fractions each round). This is
the StretchablePanelWdgt heal's exact contract promoted to a better moment; the arrange-time
heal stays as the belt for arranges that run before the drain.
- *Exclusions:* the hand (`ActivePointerWdgt`), carets, handles, temporary overlays — mirror
  the exclusion the census sweep and `_reLayoutDesktop` already encode (`isDesktopIcon?()` is
  NOT excluded from seeding — icons on the desktop grid don't consume fractions but seeding is
  harmless; P1 decides the minimal exclusion set and documents it at the enqueue site).
- *Behavior note (flag for the owner in the close-out):* menus/pop-ups added to the world will
  now carry fractions and hence REFLOW proportionally on browser resize (today they only do if
  they were ever dropped). Likely desirable; if not, exclude pop-ups explicitly.
- ⚠⚠ *Teardown:* the pending set is world-level mutable state — it MUST be cleared in
  `WorldWdgt._teardownWorldStructureNoSettle`, or the `RESETWORLD_INCOMPLETE` ratchet fails the
  suite (that ratchet is exactly for this class of forgotten field).

**F3 — ~~drift-proof the imposers via Base twins~~ DROPPED, FALSIFIED BOTH WAYS (P1 measured;
do not re-attempt).** The imposers MUST stay on the polymorphic plain twins: (a) EXTENT — the
plain `_applyExtent`'s schedule-valve gives a resized composite child the deferred second
re-lay its interior (wrapping text, nested scroll) needs to converge; on `_applyExtentBase`,
stretch/scroll/text tests churned. (b) POSITION — a `TransformFrameWdgt` island OVERRIDES
`_applyMoveTo` to ride its pinned anchor along (Bug-G); `_applyMoveToBase` bypasses that and
strands the anchor, rendering a tilted stretch child offset
(`macroRotateChildInsideStretchablePanelThenResize`). Imposition is arrange-driven but its
TARGETS are arbitrary figures — the polymorphic dispatch is load-bearing. The drift concern
F3 existed for died with F2's fill-only correction (no path re-derives over an imposition
anymore). The falsification is pinned in the imposers' comment block in `Widget`.

**F4 — delete the 34 manual sites**, batch-wise (examples first, then app-kit/authoring, then
BinOpener/Shortcut/FileLoading/duplicateMenuAction), each batch presuite-gated byte-green.
Dead calls (non-consuming holders) get deleted with the commit message naming them dead.

**F5 — absorb the gesture/lifecycle records.** `_reactToBeingDropped`'s remember, FileLoading's,
and `duplicateMenuAction`'s become redundant once the seed covers reparent —
BUT only IF the drop path's reparent goes through `_addNoSettle` (it does — drops call the
public `add`; P0 re-verifies) and the seed's drain timing is not observably later than the
drop-time record (fractions are only read at holder resize, so it is not). Delete them in the
LAST batch, each with its own presuite, so any surprise is attributable.

**F6 — the RE-RECORD family (geometry changed while resting; the fill-only seed deliberately
does not cover these).** Members: (a) `FrameWdgt` uncollapse (~:678) — refreshes extent
fractions after uncollapse restores the extent; (b) `IconicDesktopSystemWindowedApp.launch`'s
bring-up re-home — the window already HAS fractions from its previous desktop life, and the
re-home moves it, so its remember is a REAL re-record the fill-only drain must not replace
(⚠ discovered when the overwrite→fill correction landed: this site leaves the deletable set);
(c) possibly handle-release, per the P0 gap probe. KEEP these as explicit calls with upgraded
comments naming the family — or, if (c) lands, one named endpoint all three call. Do not
invent machinery beyond what these callers need. The mandate stands for PLACEMENT records;
re-records after later geometry changes are this named, commented exception.

**F7 — the handle-resize gap (probe, then decide).** Hypothesis: resizing a stretch-panel child
via its RESIZE HANDLE never re-records extent fractions (the handle is the dropped widget, not
the target), so the next panel resize snaps the child back to its pre-handle-resize proportions
— a live product bug the manual protocol never covered. P0.4 probes it in the real world page.
If real: fix at the handle-release endpoint (`HandleWdgt`'s release path calls the target's
re-record), pin with a SystemTest (P3), and note it as the arc's found-bug. If not real
(something else re-records), document where.

## §5 Central risks

- **Pixel-neutrality of the deletion batches.** The seed must derive byte-identical fractions
  to the manual calls for every existing flow: same geometry, same `_enclosingIslandFigure`
  resolution, same rounding. Any suite churn in P2/P4 is a WRONG FIX (the §6 protocol forbids
  recapturing over it; investigate instead).
- **Seed-vs-heal interleave.** Between add and drain, the heal may pin interim values and the
  arrange may impose them (moving a just-added child before the builder's later placement runs
  — but that is exactly today's behavior for the add-then-place sites, whose manual remember
  then overwrites; the drain replicates that overwrite). The invariant to keep: by the first
  PAINT after the builder turn, fractions == derive(final builder geometry).
- **World-audit ratchet** (F2's teardown note).
- **Order-of-operations discovery:** any site P0 finds where the manual call runs BEFORE final
  placement (none known) breaks the "last write wins ⇒ drain equivalent" argument for that site
  — handle it explicitly, don't average over it.
- **The heal-beats-drain hole (documented limitation, zero live instances — P1 analysis).**
  A builder that adds into a STRETCH PANEL and only then places would get heal-pinned
  pre-placement fractions the fill-only drain respects (the heal runs in the add's settle;
  the world side has no arrange-time heal, so world sites are immune — the drain fills them
  post-placement). Every existing stretch-panel site places BEFORE adding, so no live
  instance. Rule for new code (goes in the recorder's comment at P2): *place before add* when
  building into a stretch panel — or call the recorder explicitly after late placement (the
  F6 family). The spec-family fold (companion plan) should design provenance properly
  (a spec created at add can carry provisional-ness).

## §6 Phases and verification

**P0 — probe + inventory lock (no src changes).**
1. Re-grep the 40 sites; per site record: holder class, consuming?, place-before-add or after,
   what the call is FOR (placement/geometry-change/dead). Deliverable: the table in §8.
2. Verify `_addNoSettle`→`_addChild` is the single parenting funnel (grep `_addChild`
   callers; grep `.parent =` assignments outside TreeNode).
3. Verify the three imposers have no callers outside the two consumers' arranges.
4. Runtime probe (`Fizzygum-tests/.scratch/probe-stretch-fractional-gaps.js`, crib the boot
   from `.scratch/probe-census-asbuilt-movers.js`): build SampleDashboardApp; (a) confirm
   fractions after build == manual-call values; (b) simulate handle-resize of a child
   (drive the real handle path), then resize the slide window — does the child snap back?
   (F7); (c) delete-one-manual-call simulation: monkey-void the remember, rebuild flow, resize
   window, measure where the child lands (quantifies what silent rot looks like, and proves
   the new tests can catch it — the prove-the-gate-fails discipline).
5. Confirm which flows lack resize coverage (grep the four §1 tests' macros for setExtent).

**P1 — mechanism.** F1 + F2 + F3 (+ teardown clearing). Gates: `fg presuite` byte-green
(mechanism alone must change nothing — the manual calls still run and overwrite);
`node scripts/staleness-census.js` green; then ONE deletion done as a spike (a
SampleDashboardApp call) + presuite byte-green proves the seed replaces it exactly.

**P2 — drawdown.** F4 batches, then F5, then F6/F7 per their decisions. `fg presuite` per
batch, byte-green each. The recorder's TODO comment is rewritten to describe the seed (the
method stays — it IS the derivation the seed calls).

**P3 — the NEW tests (owner-directed; use the tests repo's `/author-macro-test` skill).**
1. `SystemTest_macroStretchPanelProgrammaticChildrenReflowOnResize` — open SampleDashboardApp
   via its real launcher, resize the dashboard window narrow + wide, screenshot each: pins
   programmatic-add fractional reflow end-to-end (the thing NO test pins today).
2. If P0.4b confirmed the handle gap + F7 fixed it: a handle-resize-then-container-resize test
   pinning the re-record.
3. Capture refs at dpr 1+2 (`fg recapture <names>` is for EXISTING tests; new tests use
   `node scripts/capture-macro-test-references.js <name> --dprs=1,2`), verify with
   `node scripts/run-macro-test-headless.js`, then prove each test NON-VACUOUS: re-void the
   seed (or re-plant the deleted manual-call rot from P0.4c), run the test, watch it FAIL,
   restore. ⚠ harness world is 960×440 — size the fixture windows so resize targets stay
   on-canvas (memory: off-canvas resizer is UNHITTABLE).
4. `fg presuite` then full `fg gauntlet` (caffeinate) at phase close; `fg homepage` (core
   `Widget`/`WorldWdgt` touched).

**P4 — close.** Plan → `docs/archive/` + stamp + INDEX line; BACKLOG line closed; the companion
big-arc plan's §1 updated to say the protocol is gone; memory note; ONE end-of-arc review;
commit messages presented (`git commit -F`), never commit/push without the owner's word.

## §7 Rejected / do-not-re-attempt

- **Refresh inside the raw apply funnel** — re-introduces the deleted notify-by-mutation seam
  into mutators the whole 2026-06/07 program purified, and rounding round-trips corrupt
  fractions on every resize. (§0 reframe point 1.)
- **Record at add time synchronously** — pins pre-placement geometry at every add-then-place
  site. (§0 reframe point 2.)
- **Re-derive at arrange entry ("always heal")** — circular: the arrange must APPLY stored
  fractions to new holder bounds; deriving from current position at entry destroys the reflow
  it exists to implement.
- **Reorder all builders to place-before-add and seed synchronously** — leaves the protocol
  alive (now as an ordering convention nobody checks), churns 34 sites for no structural gain.
- **Allowlist/keep the manual calls "for safety"** — the mandate is elimination; a kept call
  masks a seed bug the suite would otherwise catch.

## §8 References + execution ledger

`docs/archive/stretch-layout-spec-unification-plan.md` (the companion big arc — this plan is its
ground-clearing) · `docs/archive/census-as-built-extension-plan.md` (the as-built oracle + the
prove-the-gate-fails discipline) · `docs/archive/proper-layouts-4.2-structural-arrange-plan.md`
(the arrange-uses-Base-twins doctrine) · `docs/architecture/layout.md` (the rulebook) · memory:
`proper-layouts-elimination-goal` (the filter: pave the way to deletion),
`resetworld-state-leak-between-tests` (the teardown ratchet), `ask-before-commit-push`.

### Execution ledger (append per phase; empty at authoring)

#### P0 — DONE 2026-08-05 (probe: `Fizzygum-tests/.scratch/probe-stretch-fractional-gaps.js`, kept)
- **Inventory locked at 41 sites** (§1 counts corrected: 40 plain + FileLoading's `?()`).
  Orders verified per site: place-BEFORE-add — SampleDashboard ×15 (`_applyBounds` →
  `container.add` → remember), DegreesConverter ×8 (⚠ adds via `container._addNoSettle`, NOT
  the public add — the seed must hook the `__add` core), SampleSlide window/mapCaption/wikiLink,
  HowToSaveMessageApp, `StretchableWidgetContainerWdgt.smartPlace` (move → add → remember).
  Place-AFTER-add — SampleSlide mapPin, `IconicDesktopSystemWindowedApp.launch` (world.add →
  move → moveWithin → remember), BinOpenerWdgt:39 (world.add → `_applyBounds` → remember),
  WindowsToolbarCreatorButtonWdgt (createNextTo → move → remember), InfoDocs
  (`_moveToSideOf` → remember), Shortcut/BinOpener:44 (spawnNextTo → remember),
  FileLoading (world.add → optional move → remember), duplicateMenuAction (world.add → offset
  move → remember). NO site records before final placement — "last write wins" holds at all 41.
- **DEAD calls confirmed: SampleSlideApp `usaMap` + `mapPin`** — their holder is the NYC
  scroll panel's contents `PanelWdgt`, which NEITHER consumer reads. (Corroborating rot:
  `sampleBarPlot` in the same builder never got a remember call at all.)
- **Funnel verified SINGLE:** the only non-nil `.parent =` assignment in src is
  `TreeNode._addChild` (:69), whose only Widget-side caller is `Widget.__add` (~:3402) — the
  seed's hook point (covers public add, `_addNoSettle`, and every reparent).
- **Imposer callers verified:** exactly the two consumers' arranges (WorldWdgt ×3 position-only,
  StretchablePanelWdgt ×2) — F3's Base-twin conversion is closed-world.
- **Handle path verified:** `HandleWdgt` drives `@target._setExtentDeferredSettle` (:190); NO
  re-record anywhere in the handle machinery.
- **Runtime probe results (SampleDashboardApp, 15 stretch children):**
  - SANITY: stored fractions == geometry-derived for ALL 15 (tolerance 0.005) — the seed's
    derivation reproduces the manual protocol exactly.
  - **GAP A CONFIRMED — live product bug:** handle-style resize applied 162×162 → 222×202
    (deferred verb drained by real frames), fractions stayed stale (0.2759/0.3597); the next
    window resize snapped the child to 189×189 == the stale-fraction-implied extent. A user's
    handle-resize of a stretch-panel child does not survive the next container resize. → F7 fix
    is IN scope; P3 test 2 pins it.
  - GAP B CONFIRMED: an un-recorded +50px move reverted to the stale-fraction position
    (406→370 == implied 370) on the next resize — the rot class the new tests must catch
    (and the non-vacuity plant for P3).
- **Existing-test resize coverage confirmed absent:** neither `macroSampleDashboardPlots` nor
  `macroDegreesConverterFourWayDrive` contains a single setExtent/resize; only the drop-path
  test resizes. P3 test 1 fills exactly this hole.

#### P1 — in progress 2026-08-05 (two measured corrections, both now encoded in F2/F3)
- Mechanism landed: `consumesFractionalChildGeometry` (Widget false / WorldWdgt +
  StretchablePanelWdgt true), seed enqueue at the tail of `Widget.__add` (excludes
  layout-inert chrome + the hand), `world.pendingFractionalBookkeepingSeeds` drained as a
  doOneCycle drain station before `recalculateLayouts`, cleared in
  `_teardownWorldStructureNoSettle`.
- **Correction 1 (measured, presuite run 2 → 3):** the extent imposer must STAY on the plain
  `_applyExtent` — on the Base twin its schedule-valve loss left stretch children's interiors
  (wrapping text / nested scroll) one convergence pass short;
  `macroDropIntoRotatedStretchablePanelStretchesOnResize` churned and recovered on revert.
  The two POSITION imposers stay on `_applyMoveToBase` (drift-proofing, arrange-owned).
- **Correction 2 (measured, presuite run 3 → 4):** the drain must be FILL-ONLY, never
  overwrite. The overwriting drain churned `macroSampleSlideEditViewToggle` and others
  (re-derive over transferred island bookkeeping / over integer impositions).
  Consequence: `IconicDesktopSystemWindowedApp.launch`'s remember is a REAL re-record
  (window already carries fractions from its previous desktop life) → moved from the
  deletable set into the F6 re-record family. Sample slide recovered in run 4.
- **Correction 3 (measured, presuite run 4 → 5):** the POSITION imposers must also stay on
  the plain `_applyMoveTo` — the island's anchor-carrying override (Bug-G) is load-bearing
  for imposition; on the Base twin the tilted stretch child rendered offset
  (`macroRotateChildInsideStretchablePanelThenResize`, still red in run 4, the ~15px shift
  eyeballed in the run-3 diffpage). F3 therefore DROPPED entirely (both axes falsified, and
  fill-only removed its motivation); imposers byte-identical to pre-arc, falsification
  pinned in the `Widget` imposer comment block.
- P1 CLOSED: deletion spike green (presuite run 6); census green both sweeps — target counts
  drifted +6/+6 vs pre-arc, RESOLVED by A/B (HEAD build vs arc build, apps-battery class
  histograms IDENTICAL at 787/787): the +6 is the census EXTRAS' world-inspector listing the
  three new WorldWdgt members (3 rows × 2 widgets each) — the same benign inspector class.

#### P2 — DONE 2026-08-05 (presuite green per batch)
- Batch 1 (28 deletions, presuite GREEN): SampleDashboardApp ×14 (+1 in the P1 spike),
  DegreesConverterApp ×8, SampleSlideApp ×5 (incl. the two DEAD scroll-contents calls) —
  all place-before-add, replaced by the arrange-time heal/drain byte-exactly.
- Batch 2 (5 deletions + 7 F6 comments + the recorder TODO rewrite): deleted
  BinOpenerWdgt:39 (fresh windowed bin), HowToSaveMessageApp, InfoDocs.createNextTo,
  WindowsToolbarCreatorButtonWdgt, StretchableWidgetContainerWdgt.smartPlace. KEPT with
  RE-RECORD family comments: Widget._reactToBeingDropped, Widget.duplicateMenuAction,
  FileLoading, IconicDesktopSystemWindowedApp.launch re-home, IconicDesktopSystemShortcut
  spawnNextTo, BinOpenerWdgt spawnNextTo branch, FrameWdgt uncollapse. ⚠ F5 (absorbing the
  lifecycle records) is FALSIFIED under fill-only semantics — every lifecycle record
  re-places a bookkeeping-CARRYING widget (deep-copied / serialized / stored / prior-life
  fields), which the fill-only drain respects, so all are re-records and STAY.
- Caller census: 41 → 9 (7 F6 re-records + the heal + the drain's own call). The recorder's
  founding TODO is REWRITTEN to the new contract (framework-owned placement records; the
  re-record family; the place-before-add stretch rule).

#### P3 — DONE 2026-08-05 (suite 278 → 280)
- **Test 1 `macroStretchPanelChildrenReflowOnResize`** (3 images, dpr 1+2): the sample
  dashboard's 15 programmatically-added children reflow proportionally at 480×400 and
  900×420 (the ratio-preserving container letterboxes at wide sizes — a free second
  imposition size). Stable ×2 per dpr. NON-VACUOUS: a planted stale fraction fails all
  three images. ⚠ Finding: a HALF-plant self-heals — the stretch arrange's heal re-derives
  BOTH fields when EITHER is missing, so a plant must set both (robustness property,
  catalogued in MACRO-PATTERNS).
- **F7 LANDED — the found-bug fix**: `world.pendingFractionalReRecords` (teardown-cleared)
  drained AFTER `recalculateLayouts` (the handle's writes are deferred-settle, so only
  post-flush geometry is the gesture's outcome; the drain OVERWRITES — user intent), fed by
  `HandleWdgt.mouseUpLeft` enqueueing its target. Covers resize/move/rotate handle gestures
  on stretch children AND desktop widgets (the move-handle world flavor was the same gap).
- **Test 2 `macroStretchChildHandleResizeSurvivesReflow`** (2 images, dpr 1+2): a REAL
  resizer drag on the scatter-plot child, then the window widened — the user's enlarged
  share survives the reflow. NON-VACUOUS: voiding the mouseUpLeft enqueue fails it (the
  snap-back). Stable both dprs; visualisations generated for both tests.
- MACRO-PATTERNS.md gained the stretch-reflow entry (fixture idiom, off-canvas-resizer
  sanction, child-window location, the half-plant gotcha).
- Phase close: caffeinated `fg gauntlet` — **14/14 GREEN, 264s, 280 tests** (dpr1 112s / dpr2
  117s / webkit 128s / apps 90s / parts 45s / paint 99s / tiernaming 118s / settle 118s /
  capstone 119s / refs 29s / revisits 118s / census 9s / serialization 53s / storage 118s):
  the revisit baseline holds (the post-flush re-record drain adds no settle re-visits), both
  serialization rigs pass with the two new world Sets + seeded fields, webkit reuses the new
  refs. `fg homepage` result in P4.

#### P4 — close (2026-08-05)
- `fg homepage` at arc close (core `Widget`/`WorldWdgt`/`HandleWdgt` touched) — EXIT=0 OK
  (production boot + whole-world snapshot round-trip clean, dev build restored). Plan
  archived + INDEX + BACKLOG + memory + end-of-arc review; commits presented for the
  owner's word. — the SEEDED FIELDS honestly appearing in inspected
  widgets' own-props lists (`extentFractionalInHoldingPan…` visible in the BoxWdgt and
  boot-clock inspectors; a DROPPED widget already showed these fields before this arc, so
  the seed makes programmatic adds CONSISTENT with drops) plus the resulting row shifts and
  scrollbar-thumb geometry (8-16px bboxes). No structural/layout diff anywhere. All 15
  recaptured via the gated `fg recapture` (owner's standing benign-inspector-recapture
  rule), result recorded below.

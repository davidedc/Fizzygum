# Stretch layout joins the LayoutSpec family — one per-child layout-state home, grant-bounds arrange

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-05; §1 re-verified same day against the LANDED prerequisite state (Fizzygum
`cfb1b22e` / Fizzygum-tests `cd6e638ff`). ⚠ Line numbers drift — quoted method/class names are
authoritative; re-grep before trusting a line.
✅ **Prerequisite MET:** the companion arc
`docs/archive/stretch-fractional-auto-bookkeeping-plan.md` (framework-owned fractional
bookkeeping, caller-remember protocol deleted, handle-release re-record, two reflow
SystemTests) EXECUTED + PUSHED 2026-08-05 — this plan's §1 describes its as-landed state, and
its §8 ledger + the `archive/INDEX.md` case law are REQUIRED reading (three of its findings
are hard design inputs here: the fill-only law, the two imposer falsifications, the
heal-provenance hole). **Phase 0 here is a DESIGN phase with an OWNER GATE** — do not write
production code before the owner approves the §4 design decisions.

**MANDATE.** ONE home for per-child layout state: the `LayoutSpec` family. The stretchable
panel's three loose fields become a `StretchLayoutSpec`; the panel's `_reLayout` sheds its
self-confessed antipattern (raw-setting children) for the grant-bounds shape every other engine
uses; the island bookkeeping transfer collapses into "the spec rides the child". Not a veneer
over the fields — the fields are DELETED.

---

## §0 Orientation

**Fizzygum** — CoffeeScript canvas GUI framework; build/test via the `fg` wrapper (`fg build`,
`fg presuite` ~2 min, `fg gauntlet` ~5 min; background + log + verdict; never edit src/tests
mid-run). Read `Fizzygum/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md`, and
`docs/architecture/layout.md` (the rulebook) first.

**Why this plan exists.** The 2026-08 layout-spec-family unification
(`docs/archive/layout-spec-family-plan.md` + follow-ups) gave stacks, divisions, frame content
and corner-internal chrome ONE vocabulary: a per-child `layoutSpec` object; `nil` = free-
floating (`Widget.isFreeFloating: -> !@layoutSpec?`); specs ride add/reparent/wrap/unwrap and
SURVIVE detachment (⚖⚖). The stretchable panel — the layout of the slide/dashboard/generic-panel
authoring surfaces — stayed OUTSIDE it, on a mechanism that predates the program. TODAY there
are THREE parallel per-child layout-state mechanisms:
1. `layoutSpec` objects (the family — `LayoutSpec` base; `VerticalStackLayoutSpec`,
   `DivisionStackLayoutSpec`, `FrameContentLayoutSpec`, `CornerInternalLayoutSpec`).
2. `_stackElementSpec` — the stack's kept per-element spec object (present in ~24 files).
3. The stretch/fractional trio on the child: `positionFractionalInHoldingPanel`,
   `extentFractionalInHoldingPanel`, `wasPositionedSlightlyOutsidePanel` (+ the desktop's
   sibling flag `userMovedThisFromComputedPosition` on bin-opener/clock).

Evidence the split costs real complexity: `Widget._moveHoldingPanelBookkeepingTo` exists ONLY
to hand-carry mechanisms 2+3 across sugar-island materialize/dematerialize (its comment
documents the LAYOUT_ERROR and proportional-tracking bugs that forced it); and
`StretchablePanelWdgt._reLayout` opens with this standing confession:

> TODO antipattern - in _reLayout you should never set raw position and extent like this
> directly on the children (except in the base Widget implementation) because the children
> might have their own layouts inside of them, so you have to call _reLayout on them in some
> form. the bad news here is that _reLayout cannot take in input a fractional position yet

**CRITICAL REFRAME.** This is not "wrap the fields in an object". The payoff is structural:
(a) ONE questioning surface — `isFreeFloating`/spec-type queries replace field-presence checks;
(b) the island transfer and duplication/serialization special-casing DISSOLVE (a spec is one
value that rides the child through every existing spec pathway); (c) the stretch arrange
becomes a normal grant-bounds engine, closing its antipattern TODO and making
"_reLayout takes a fractional position" a non-question (the SPEC carries the fraction; the
arrange grants integer bounds derived from it).

## §1 Current state (verified 2026-08-05 at `e7dd9b42`)

- **The family:** `LayoutSpec.coffee` base + the four subclasses above. Specs are assigned via
  `Widget._setLayoutSpec` (~:752); `_addNoSettle` accepts `layoutSpec:` and carries it on
  reparent (~:1652 comment: "The index + the layoutSpec ENUM already ride with the reparent").
  Specs serialize with the child (the detachment-survival ⚖⚖ from the unification arc).
- **The stretch mechanism (AS LANDED by the companion arc, `cfb1b22e`):** three plain fields
  on the child (declared `Widget.coffee` ~:333); writer
  `_rememberFractionalSituationInHoldingPanel` (its comment IS the contract doc: framework-
  owned placement records, the RE-RECORD family, the place-before-add stretch rule); appliers
  `_moveInDesktopToFractionalPosition` / `_moveInStretchablePanelToFractionalPosition` /
  `_setExtentToFractionalExtentInPaneUserHasSet` (⚠ on the polymorphic PLAIN twins, with a
  comment block pinning WHY — see the D6 constraints below; note the desktop applier's
  deliberate negative-component skip); consumers `StretchablePanelWdgt._reLayout` (with the
  §5b heal) and `WorldWdgt._reLayoutDesktop` (position-only,
  `userMovedThisFromComputedPosition`-gated for bin-opener/clock). WRITE PATHS, all
  framework-owned: (a) the FILL-ONLY seed — `Widget.__add` enqueues into
  `world.pendingFractionalBookkeepingSeeds` when the parent
  `consumesFractionalChildGeometry()` (true: WorldWdgt + StretchablePanelWdgt; excludes
  layout-inert chrome + the hand), drained at a `doOneCycle` station BEFORE
  `recalculateLayouts`, deriving ONLY when the figure's bookkeeping is missing; (b) the
  RE-RECORD drain — `HandleWdgt.mouseUpLeft` enqueues its target into
  `world.pendingFractionalReRecords`, drained AFTER `recalculateLayouts` (deferred-settle
  writes must land first), OVERWRITING (user intent); (c) the seven explicit F6 re-record
  sites (drop, duplicate, file-load, app re-home, spawnNextTo-of-stored, BinOpener
  spawnNextTo, FrameWdgt uncollapse), each comment-tagged. Both Sets are cleared in
  `_teardownWorldStructureNoSettle`. The manual placement protocol is GONE (41 → 9 recorder
  callers).
- **The companion arc's tests are this plan's inherited pixel gates:**
  `macroStretchPanelChildrenReflowOnResize` (fraction VALUES at two window sizes) and
  `macroStretchChildHandleResizeSurvivesReflow` (the handle-release re-record) — both proven
  non-vacuous; the fold must keep them byte-green (or consciously re-baseline under a
  D-decision). ⚠ A stable-but-wrong fraction is INVISIBLE to the census — these two tests
  are the only value-oracles.
- **The transfer:** `_moveHoldingPanelBookkeepingTo` (~:1658) moves fields 2+3, nils the
  source (single-owner rule — its comment explains the double-reference hazard on fullCopy).
- **The stretch arrange:** iterates `childrenNotHandlesNorCarets`, heals missing bookkeeping,
  imposes position+extent from fractions, then `w.desiredPosition = nil; w.desiredExtent = nil;
  w._reLayout()` per child — the raw-set-then-relayout the TODO confesses. Also disables
  broken-rect tracking around the loop (`world.disableTrackChanges()`) and applies its own
  granted bounds BEFORE the loop's dependents (the bounds-first gate,
  `buildSystem/check-relayout-bounds-first.js`).
- **Serialization:** the three fields are plain and serialize by the normal walk (no mention
  under `src/serialization/`); spec objects serialize as values. NO compat obligations (owner
  standing rule, memory `no-serialization-compat-obligations`) — old snapshots may be migrated
  or invalidated, Right Thing > compat.

## §2 Why it is shaped this way

The fractional fields are Morphic-era; the spec family arrived 2026-08. Nothing ever unified
them because the stretch panel worked and the program's front lines were elsewhere (stacks,
divisions, docks). `_stackElementSpec` predates the family's `layoutSpec` too — the stack
engine keeps its own per-element object for proportional tracking. The split is historical
strata, not design.

## §3 The distilled argument

Every cost this plan removes is already documented in the code as a scar: the transfer method
exists because the fields do NOT ride the child the way specs do; the heal exists because
field-presence is optional in a way a typed spec is not; the arrange antipattern exists because
fractions live outside the granted-bounds vocabulary. Folding the mechanism into the family
deletes the scars' reasons. Doing it AFTER the companion arc means the fold touches one
framework-owned seeding point instead of 40 call sites — the fold's diff is confined to the
holder, the spec class, and the Widget plumbing.

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — Fizzygum/tests clean and at/past the
   companion arc's close (check its archive stamp; if the companion arc has NOT landed, STOP —
   execute it first).
2. Read this plan; read `docs/archive/stretch-fractional-auto-bookkeeping-plan.md`'s §8
   ledger IN FULL (its P0 site table, its three measured corrections, and its P3 findings are
   this plan's ground truth) + its `archive/INDEX.md` entry; read `StretchablePanelWdgt` in
   full, `LayoutSpec.coffee` + one consumer engine (`StackLayoutEngine` usage in
   `SimpleVerticalStackPanelWdgt`) for the family's idiom, and the §1-listed `Widget` regions
   (especially the imposers' falsification comment block and the recorder's contract comment).
3. Phase 0 produces a design note IN THIS FILE (§4 decisions filled in) and STOPS for owner
   review. Only after owner approval: P1-P4, `fg presuite` per batch, `fg gauntlet` +
   `fg homepage` at phase closes, census green throughout.
4. Commits: present messages (`git commit -F`); never commit/push without the owner's word.

## §4 Phase 0 — design decisions (owner-gated; fill in, then STOP for review)

D1. **`StretchLayoutSpec` contents:** position fraction pair, extent fraction pair,
    outside-panel flag. Does `userMovedThisFromComputedPosition` (desktop bin-opener/clock)
    fold in, or stay a widget field (it is a desktop-policy bit, not stretch state)?
    Recommendation: stays out — it gates WHETHER fractions apply, it is not fractional state.
    Bonus a single spec value buys for free: the companion arc's half-plant asymmetry
    dissolves (one object = position+extent atomic — the heal's derive-both-when-either-
    missing dance and the plant-both testing gotcha both stop existing).
D2. **Does the WORLD adopt the spec too?** The desktop consumes position-only with its own
    negative-component rule. Options: (a) world children carry `StretchLayoutSpec` and
    `_reLayoutDesktop` reads it (one mechanism, two consumers — recommended); (b) desktop
    keeps fields (two mechanisms remain — rejected by the mandate unless (a) hits a real
    blocker in the spike).
D3. **`_stackElementSpec`:** fold into the family in THIS arc, or explicit non-goal?
    Recommendation: explicit non-goal here (its own arc) — but the plan's close must file the
    BACKLOG line so the third mechanism is not forgotten.
D4. **Free-floating semantics:** children of a stretch panel currently read as free-floating
    (`!layoutSpec?`). Giving them a spec flips `isFreeFloating` — audit its read sites
    (resize-handle visibility per `_setLayoutSpec`'s comment, editor behaviors) and decide:
    is a stretch child "free-floating with proportional memory" (spec subclass overrides the
    relevant queries) or a first-class laid-out child? This is the highest-risk decision —
    enumerate every `isFreeFloating`/`layoutSpec?` read site in the design note.
D5. **Serialization/migration:** delete the three fields from serialized state; loader maps
    old-snapshot fields → a spec on load, or old snapshots are declared stale (owner rule
    permits either; pick the cheaper).
D6. **The arrange conversion:** the grant-bounds shape — the panel computes each child's
    integer target bounds from its spec + the granted panel bounds, then grants via the
    engine-standard path (`_reLayout(newBounds)` per child, desired-funnel semantics), deleting
    the raw-set + nil-desired + bare-`_reLayout()` triplet and (test) the
    `world.disableTrackChanges()` bracket's continued necessity.
    ⚠⚠ TWO HARD CONSTRAINTS from the companion arc's measured falsifications (do not
    rediscover them the expensive way): whatever path grants the child its bounds must
    (i) ride a `TransformFrameWdgt` island's anchor-carrying `_applyMoveTo` override
    (Bug-G) — a Base-twin/override-bypassing grant strands the pinned anchor and offsets
    tilted children (`macroRotateChildInsideStretchablePanelThenResize` is the tripwire) —
    and (ii) preserve the interior-convergence second re-lay that `_applyExtent`'s
    schedule-valve provides today — wrapping-text / nested-scroll interiors converge one
    pass late without it (`macroDropIntoRotatedStretchablePanelStretchesOnResize` +
    text/scroll tests are the tripwires). A grant through the desired-funnel may satisfy
    both natively — VERIFY each explicitly in the P2 spike, don't assume.
D8. **Spec provenance — close the heal hole structurally (from the companion arc's §5).**
    Today a builder that adds into a stretch panel and only then places gets heal-pinned
    pre-placement fractions the fill-only drain respects (zero live instances; guarded only
    by the place-before-add comment rule). A spec CREATED at add can carry provisional-ness
    (heal-derived vs recorded), letting the drain overwrite provisional specs only — the
    convention hole becomes a type distinction. Decide the encoding (a flag on the spec vs
    two creation paths) and whether the two world Sets
    (`pendingFractionalBookkeepingSeeds` / `pendingFractionalReRecords`) merge into one
    provenance-aware queue.
D7. **Rounding encoding — consider EDGE-based fractions (owner-raised 2026-08-05).** The
    current model rounds position and extent INDEPENDENTLY per child, so a child's right
    edge is `round(posFrac×w) + round(extFrac×w)` — two children that abutted exactly at
    record time can develop a ±1px seam/overlap at other panel sizes (deterministic; the
    padded sample layouts never show it, but it is a real expressiveness limit of the
    two-independent-fractions encoding). A `StretchLayoutSpec` could instead record EDGE
    fractions (left/right/top/bottom) and derive extents from rounded edges — abutting
    edges then round identically at every size and seams become impossible. Decide with D1;
    note the companion arc's fill-only law (a fraction, however encoded, is recorded once
    and never re-derived from imposed integers) carries over unchanged.

## §5 Phases (post-approval)

P1 — `StretchLayoutSpec` class + Widget plumbing: BOTH drains (the fill-only seed station and
     the post-flush re-record drain) create/replace a spec instead of writing fields, per the
     D8 provenance decision; the seven F6 sites keep calling the recorder (its INTERNALS
     change, their calls are the stable API); consumers read the spec; fields become derived
     shims for ONE commit, then are DELETED same-phase (no long-lived dual state). Transfer
     method `_moveHoldingPanelBookkeepingTo` shrinks to `_stackElementSpec` only (D3) or dies
     (if D3 folds too). Census + presuite byte-green expected throughout — EXCEPT the
     predictable inspector wave: deleting the three own-fields (and showing a `layoutSpec`
     instead) will churn the inspector-family tests exactly as their APPEARANCE did in the
     companion arc (15 tests, diffpage-verify then the benign-inspector recapture rule).
P2 — the arrange conversion (D6). Gates: presuite, census (as-built + post-resize), the
     `revisits` gate (a conversion that changes settle cadence shows up there), capstone leg.
P3 — desktop adoption per D2; serialization per D5 (run BOTH serialization rigs +
     `fg homepage`'s production snapshot round-trip).
P4 — tests + docs + close: the two inherited value-oracles
     (`macroStretchPanelChildrenReflowOnResize`, `macroStretchChildHandleResizeSurvivesReflow`)
     must end the arc green; ADD a detachment-survival test in the family's style (detach a
     stretch child, re-add, proportions survive — mirroring the unification arc's ⚖⚖); update
     `docs/architecture/layout.md`'s spec-family section; archive + INDEX + BACKLOG (+ D3's
     new line) + memory; end-of-arc review; commits presented.

## §6 Verification protocol

`fg presuite` per batch; `fg gauntlet` (caffeinate) per phase close; `fg census` free anytime;
BOTH serialization rigs + `fg homepage` on any serialization-touching batch (P1/P3); expected
suite churn ZERO except where a D-decision consciously changes behavior (each such change gets
its own diffpage + eyeball + owner-visible note BEFORE recapture). New/changed tests captured
at dpr 1+2 and proven non-vacuous (void the spec application, watch the test fail, restore).

## §7 Rejected / do-not-re-attempt

- **A spec veneer over kept fields** — burying, not eliminating (the elimination-goal filter).
- **Folding the fractional trio into `_stackElementSpec`** — wrong direction: grows mechanism
  2 instead of shrinking to mechanism 1.
- **Doing this BEFORE the caller-remember protocol is deleted** — the fold would have to touch
  all 40 manual sites AND the mechanism; the companion arc reduces that surface to one seam.
- **Skipping the D4 audit** — `isFreeFloating` gates handle visibility and editor affordances;
  flipping it blind is the plan's known way to ship a subtle UX regression.
- **Granting/imposing through override-bypassing Base twins** — falsified TWICE in the
  companion arc (2026-08-05, measured): `_applyMoveToBase` strands a transform island's
  pinned anchor (tilted children render offset), and `_applyExtentBase` loses the
  schedule-valve's second re-lay (wrapping/scroll interiors converge one pass late). The
  polymorphic dispatch is load-bearing when the geometry's TARGETS are arbitrary figures —
  see the imposers' comment block in `Widget` and D6's constraints.
- **Overwrite-on-derive anywhere in the fold** — the fill-only law is not a drain
  implementation detail, it is the model: a fraction (however encoded) is recorded at intent
  moments and never re-derived from imposed integers (rounding drift + island-box mismatch,
  both measured). D8's provenance is the only sanctioned overwrite gate.

## §8 References + execution ledger

`docs/archive/stretch-fractional-auto-bookkeeping-plan.md` (companion, prerequisite — LANDED;
its §8 ledger + INDEX entry are required reading) ·
`docs/archive/layout-spec-family-plan.md` + `docs/archive/layout-spec-family-followups-plan.md`
(the family's design + case law) · `docs/architecture/layout.md` ·
`docs/archive/census-as-built-extension-plan.md` (the as-built oracle) ·
`src/macros/MACRO-PATTERNS.md` "Stretch-panel fractional reflow" entry (the testing idiom) ·
memory: `stretch-fractional-auto-bookkeeping-arc` (the companion's case law),
`proper-layouts-elimination-goal`, `no-serialization-compat-obligations`,
`layout-spec-family-plan-authored` (⚖⚖ specs survive detachment), `ask-before-commit-push`.

### Execution ledger (append per phase; empty at authoring)

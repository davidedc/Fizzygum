> **ARCHIVED — COMPLETE (executed 2026-08-06; P0 design owner-reviewed 08-05/06, P1–P4 single session).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Stretch layout joins the LayoutSpec family — one per-child layout-state home, grant-bounds arrange

**STATUS: COMPLETE — executed 2026-08-06 (P0 design 08-05/06 with owner review; P1–P4 single
session). Final gate: fg gauntlet 14/14 GREEN (266s, suite 281); census 0-movers both sweeps;
revisits baseline exact; both serialization rigs + fg homepage production round-trip green.
Residuals filed in docs/BACKLOG.md: the D3 kept-slot fold and the D10 desktop corner-spec
dissolution. Execution ledger in §8.**

**Originally PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
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
(`docs/archive/layout-spec-family-unification-plan.md` + follow-ups) gave stacks, divisions, frame content
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

**DESIGN NOTE authored 2026-08-05 (Phase 0, at Fizzygum `de339bb1` / tests `cd6e638ff`) —
every mechanism fact below re-verified in src that day; quoted line numbers are from that
state. The eight decisions form ONE package: D7's edge encoding is D1's field layout, D4's
query redefinition is what makes D2's world adoption safe, D8's provenance rides D1's
object. AWAITING OWNER REVIEW — no production code written.**

D1. **`StretchLayoutSpec` contents:** position fraction pair, extent fraction pair,
    outside-panel flag. Does `userMovedThisFromComputedPosition` (desktop bin-opener/clock)
    fold in, or stay a widget field (it is a desktop-policy bit, not stretch state)?
    Recommendation: stays out — it gates WHETHER fractions apply, it is not fractional state.
    Bonus a single spec value buys for free: the companion arc's half-plant asymmetry
    dissolves (one object = position+extent atomic — the heal's derive-both-when-either-
    missing dance and the plant-both testing gotcha both stop existing).

    ⇒ **DECIDED: one mutable spec object — family member #5 — holding FOUR EDGE fractions
    (per D7), the outside-panel flag, and the D8 provenance bit;
    `userMovedThisFromComputedPosition` STAYS OUT; lifecycle is ACTIVE-ONLY (no new kept
    slot).**
    - Fields: `leftFraction` / `topFraction` / `rightFraction` / `bottomFraction` (of the
      holder's bounds), `wasPositionedSlightlyOutsidePanel` (part of the placement record —
      the desktop's clamp gates read it at the same moments it is recorded), `provisional`
      (D8). Capabilities: `isStretchElement?()` (arrange/consumer membership) plus the D4
      authority answer (`ownsPlacement: -> false` — the base `LayoutSpec` declares `true`);
      it answers NONE of the four existing family queries
      (`isDivisionElement?` / `isCornerInternal?` / `isStackElementActive?` /
      `isFrameContentActive?`), so it is inert at every §2-category site of the D4 audit.
    - `userMovedThisFromComputedPosition` stays a widget field: it is a lifecycle policy
      bit — set by EVERY grab (`Widget._beforeBeingGrabbed` ~:4554) — gating WHETHER the
      desktop applies fractions to bin-opener/clock. It is not fractional state, and folding
      it in would put a bit on every spec that exactly two desktop widgets read.
    - Lifecycle (the load-bearing choice): the spec is CREATED at value-record moments (the
      seed drain, the seven F6 recorder calls, the re-record drain, the §5b heal) and armed
      as the ACTIVE `layoutSpec` via `_setLayoutSpec`; it is nil'd by grab
      (`_beforeBeingGrabbed` ~:4556) and by any reparent (`_addNoSettle` ~:3348 resolves
      `opts.layoutSpec ? defaultLayoutSpecWhenAddedTo(...)` — base nil — and ~:3381 sets it
      unconditionally), and re-entry into a consuming holder derives a FRESH record via the
      existing seed. NO kept slot: the family law is per-CLASS lifecycle (INDEX: "division
      box = per-widget knob; content-stack spec = per-placement, kept"), and the stretch
      spec's class lifecycle is per-ATTACHMENT — its values are derivable placement memory
      with no user-edited knobs (the stack spec's kept slot exists to preserve UNDERIVABLE
      user edits), and fractions are PARENT-relative, so keeping them across a reparent is
      exactly what produces today's stale-fraction carryover (next point).
    - ⚠ CONSCIOUS BEHAVIOR CHANGE (owner-visible): today the trio fields survive every
      reparent uncleared, so a child programmatically moved panel-A → panel-B carries A's
      fractions and SNAPS to A's proportions on B's next resize (the fill-only drain
      respects them; no F6 fires on a bare add). Under the fold the reparent nils the spec
      and the seed derives fresh at the child's placed position in B — the child stays where
      the builder put it. Drop / duplicate / load / re-home paths are unchanged (their F6
      re-records already overwrite).
    - Confirmed bonus: the spec exists whole or not at all — the heal's
      derive-both-when-either-missing dance and MACRO-PATTERNS' plant-both gotcha both stop
      existing.
    - P4's detachment-survival test pins the resulting contract: detach + re-add at
      unchanged geometry re-derives EQUAL proportions (same-size imposition is
      pixel-identical; ONE fresh derivation at a reparent is an intent-moment record, not
      the banned repeated re-derive), and the ISLAND wrap carries the spec OBJECT itself
      (the `layoutSpec:` add-arg pathway, D4 audit §2) — the true object-carriage story the
      old transfer method existed for.
D2. **Does the WORLD adopt the spec too?** The desktop consumes position-only with its own
    negative-component rule. Options: (a) world children carry `StretchLayoutSpec` and
    `_reLayoutDesktop` reads it (one mechanism, two consumers — recommended); (b) desktop
    keeps fields (two mechanisms remain — rejected by the mandate unless (a) hits a real
    blocker in the spike).

    ⇒ **DECIDED: (a) — the world adopts the spec; one mechanism, two consumers.**
    - `_reLayoutDesktop` + `_moveInDesktopToFractionalPosition` read the spec, POSITION-only
      (left/top edges; the deliberate negative-component skip carries over verbatim as a
      negative-EDGE skip; right/bottom edges are stored-but-unread on the desktop, exactly
      as the extent fields are today). The three `wasPositionedSlightlyOutsidePanel` clamp
      gates (WorldWdgt ~:1991/:2003/:2015) read it off the spec.
    - What makes (a) SAFE is D4's query redefinition: every desktop child (all windows, all
      non-icon chrome) acquires a spec, and `isFreeFloating` stays behavior-identical for
      the whole population by construction. Without D4's shape, (a) would flip the five
      geometry-setter gates and the handle visibility across the entire desktop — the two
      decisions are one package.
    - DELETE the synchronous world-add half-record (`_addNoSettle`'s tail, ~:3400:
      `if @ == world then aWdgt._rememberFractionalPositionInHoldingPanel()`): today it
      half-plants POSITION so the drain's either-missing condition completes the pair at
      builder-final geometry — that is what makes world-side place-AFTER-add work. An ATOMIC
      spec cannot represent a half-record, and the seed drain alone IS the last-write-wins
      record. P1 spike must confirm no same-turn reader needs a world child's fractions
      between the add and the next cycle's drain (the only consumer, `_reLayoutDesktop`,
      runs on browser resize — cross-turn).
    - Expected churn: the predictable inspector/census own-prop wave only (the companion
      arc's benign class — one spec object replaces three fields in own-prop listings).
D3. **`_stackElementSpec`:** fold into the family in THIS arc, or explicit non-goal?
    Recommendation: explicit non-goal here (its own arc) — but the plan's close must file the
    BACKLOG line so the third mechanism is not forgotten.

    ⇒ **DECIDED: explicit NON-GOAL, per the recommendation.** `_stackElementSpec` (and the
    sibling kept knob `_divisionBox`) stay as-is; `_moveHoldingPanelBookkeepingTo` shrinks
    to its `_stackElementSpec` line only (P1). The close files the BACKLOG line: "third
    per-child layout-state mechanism — fold the kept-slot idiom (`_stackElementSpec` /
    `_divisionBox`) into one spec-lifecycle story; own arc; see
    stretch-layout-spec-unification §4 D3."
D4. **Free-floating semantics:** children of a stretch panel currently read as free-floating
    (`!layoutSpec?`). Giving them a spec flips `isFreeFloating` — audit its read sites
    (resize-handle visibility per `_setLayoutSpec`'s comment, editor behaviors) and decide:
    is a stretch child "free-floating with proportional memory" (spec subclass overrides the
    relevant queries) or a first-class laid-out child? This is the highest-risk decision —
    enumerate every `isFreeFloating`/`layoutSpec?` read site in the design note.

    ⇒ **DECIDED (spelling refined with the owner, 2026-08-06): "free-floating with
    proportional memory" — redefine the ONE query, never the sites; the spec family states
    its AUTHORITY DIRECTION explicitly.** The family base gains
    `LayoutSpec.ownsPlacement: -> true` (the arrange places the child FROM the spec;
    gestures must edit the SPEC through its knobs — true of division/stack/frame-content/
    corner specs), and `StretchLayoutSpec` overrides it `-> false` (a FOLLOWER: derived
    memory that trails the child's geometry via the record family; the container reads it
    only at its own re-lay; the child stays user-movable). Then
    `Widget.isFreeFloating: -> !@layoutSpec? or !@layoutSpec.ownsPlacement()` — "free-
    floating = nobody owns my placement", a sentence true today (no spec ⇒ nobody) and
    after the fold (follower spec ⇒ still nobody). A plain base-defaulted method, not a
    dangling `?()` only one class defines: the `?()` convention's point is banning
    `instanceof`, and putting the contract on the family base is what makes the fifth
    member's difference legible. NOTE on who specifies a spec (owner question, answered
    from src): the spec OBJECT always lives on and belongs to the CHILD (it holds the
    child's own participation values), while the KIND armed follows from the attachment
    context — `add()`'s default asks the child parameterized by the destination (~:3332),
    the stack ADOPTS on entry (`SimpleVerticalStackPanelWdgt:267-273`), `FrameWdgt:1005`
    re-inits content specs. The stretch spec follows the same shape: child-owned values
    (recorder methods on the child), context-triggered arming (the consuming holder's
    seed). `isFreeFloating` therefore still reads ONLY child-local state — my field, my
    spec's class-level answer — never the parent. Every read site enumerated
    below then keeps today's behavior BY CONSTRUCTION — and the audit shows today's
    behavior is the WANTED behavior for stretch/desktop children at every single site
    (users move/resize them, handles show, the panel arranges only on its own re-lay).
    The doctrine comments update with the arming (`LayoutSpec.coffee` :18-20 and
    `Widget.layoutSpec`'s declaration ~:293): free-floating = no spec owns my placement
    between arranges; a spec may be follower MEMORY.
    **Rejected:** first-class laid-out child — it would require re-deciding all sixteen
    sites individually, and not ONE of them wants the flipped branch: the flip's five
    hard-gate no-ops and the handle hide are precisely the predicted UX regression, and the
    flipped invalidation climb adds `FLOWRULE_VIOLATION` exposure from the arrange's
    in-pass child re-lays.

    **The read-site audit (full sweep of both repos, 2026-08-05). Category 1 —
    `isFreeFloating` call sites (16 src + 1 test harness); "preserved" = behavior identical
    under the redefinition:**
    | Site | Gates | Under the flip (rejected) | Under the redefinition |
    |---|---|---|---|
    | `Widget:995` `_setBoundsNoSettle` | public setBounds | silent no-op on stretch children | preserved |
    | `Widget:2120` `_moveToNoSettle` | public moves (drag-move, dematerialize re-place :1712/:1723) | children unmovable — the single biggest cliff | preserved |
    | `Widget:2326` `_setExtentNoSettle` | public resizes + the :2343 remember hook | handle-resize dead | preserved |
    | `Widget:2515` `_setWidthNoSettle` | public setWidth | no-op | preserved |
    | `Widget:2554` `_setHeightNoSettle` | public setHeight | no-op | preserved |
    | `Widget:3961` `_showResizeAndMoveHandles…` | halo shape | falls to the division-adjuster branch → NO affordances at all | preserved (full halo) |
    | `Widget:4817` `_invalidateLayout` (triggeringChild) | THE freefloating-skip: child mutations don't climb into the panel | every child mutation re-arranges the panel; in-pass exposure to the `FLOWRULE_VIOLATION` throw (:4849) | preserved (no climb) |
    | `Widget:4834` `_invalidateLayout` (inert no-climb) | caret/handle bare enqueue | inert chrome would climb if it ever carried a spec | preserved (chrome is never seeded — excluded at `__add`) |
    | `FrameWdgt:177` `_firstPlacementContentWidth` | window hug vs stack-spec width | a stretch-hosted WINDOW would mis-measure via a stack spec the panel never captures | preserved |
    | `FrameWdgt:191` `preferredExtent` | mirror of :177 | same mis-measure | preserved |
    | `FrameWdgt:455` `recursivelyAttachedAsFreeFloating` | knock-ons at :196/:220/:813/:1028/:1047 | windows in panels stop reading as recursively free | preserved |
    | `FrameWdgt:555` `_reLayoutMayResizeOwnWidth` | early-settle eligibility | settle-cadence change | preserved |
    | `FrameWdgt:1017` `_positionAndResizeChildren` | first-placement hug suppression | windows stop self-sizing to content | preserved |
    | `HandleWdgt:107` `_reactToBeingAdded` | handle target adoption | (handles keep their own spec) | preserved |
    | `HandleWdgt:119` `updateVisibility` | **handles show iff parent free-floating** (fired from `_setLayoutSpec`'s tail on every arming) | all grips HIDE on stretch children — the second cliff | preserved (arming is visibility-neutral) |
    | `InspectorWdgt:140` `_setLayoutSpec` override | inspector background | inspector in a panel loses its background | preserved |
    | `LayoutElementAdderOrDropletWdgt:93` | droplet self-wrap on click | stops self-wrapping | preserved |
    | tests: `paint-readonly-prelude.js:45` | mirrors :4817 in the paint audit | stretch children's paint-time invalidates become audit violations | preserved (calls the redefined method) |
    ⚠ The five FrameWdgt sites are the audit's least-obvious exposure: the dashboard's
    stretch children ARE FrameWdgt windows, so a naive flip would have changed window
    measuring/hugging INSIDE panels, not just handles.

    **Category 2 — all other `layoutSpec` reads: zero `instanceof` anywhere; every family
    dispatch is a duck-typed capability query, so a `StretchLayoutSpec` answering only its
    own queries is inert at every one of them.** The consequential ones, verified: base
    `_reLayout`'s dispatch head (`Widget:5092` corner, `:5117` division via
    `_divisionChildrenAxis` `:5019` — a stretch spec answers neither, so a stretch child's
    own `_reLayout(granted)` behaves exactly as today's bare `_reLayout()`); the engine
    membership loops (`StackLayoutEngine:93/:108`, `Widget:4980`, `:5137`, `:5228`); the
    spec menu chain (`Widget:4270-4282` — falls through, no spec submenu, correct); the
    divider's `.axis` reads (`StackElementsSizeAdjustingWdgt:70/:74/:77/:100/:160`); the
    stack ADOPTION overwrite (`SimpleVerticalStackPanelWdgt:267-273` — would clobber a
    live stretch spec, but under D1 a reparent into a stack has ALREADY nil'd it, so the
    adoption never sees one); FrameWdgt content-spec guard (`FrameWdgt:1005` — same
    reasoning); the ISLAND carry (`Widget:1678` materialize captures `@layoutSpec`, `:1708`
    dematerialize hands it back — THE pathway that replaces the fractional third of
    `_moveHoldingPanelBookkeepingTo`); two diagnostic strings (`WorldWdgt:1159/:1257`);
    tests-repo hard derefs that expect stack/division specs
    (`macroSimpleDocumentCanAddIndentedParagraph`, `macroDivisionCellMenuEditsSpec`,
    `macroCenteredWidgetStaysCenteredWhenAlone`) — all target stack/division children that
    can never carry a stretch spec. Test-harness diagnostics (`eoc-production-probe.js:23`,
    `layout-audit-prelude.js:137`) log the spec — display-only.
    **Prose that goes stale with the fold (P4 doc sweep):** `MACRO-PATTERNS.md` :397/:1382
    (plant-both recipe)/:1450/:1529, the layouts-and-{visibility,collapsing} test intents
    ("distribution loops filter children by layoutSpec only"), `LayoutSpec.coffee`'s
    header, the `_setLayoutSpec`/`_addNoSettle` comment blocks naming the trio.
D5. **Serialization/migration:** delete the three fields from serialized state; loader maps
    old-snapshot fields → a spec on load, or old snapshots are declared stale (owner rule
    permits either; pick the cheaper).

    ⇒ **DECIDED: generic-walk serialization (zero registration), spec class in CORE, NO
    migration shim — old snapshots are declared stale, and in practice they mostly
    self-heal.**
    - Verified: the serializer keys any non-widget object by `record.class =
      constructor.name` and the deserializer resolves `window[record.class]`
      (`Serializer` ~:367-372 / `Deserializer` ~:188) — a new global class serializes and
      duplicates for free. None of the trio is in `serializationTransients` today (⚠
      `extentFractionalInHoldingPanel` has no prototype default — own-property only), so
      the spec replaces them 1:1 in snapshots.
    - `StretchLayoutSpec.coffee` lives in src root beside the family — CORE: under D2,
      world children carry it in EVERY profile's snapshots, so the homepage production
      round-trip requires it eager; `extends LayoutSpec` is a declaration-level edge the
      dependency scanner sees.
    - Old snapshots: no compat obligation (standing owner rule). Their trio own-props
      deserialize as inert residue nothing reads, and `FileLoading`'s F6 re-record (~:60)
      records a fresh spec for the loaded root at load; whether to also strip the residue
      in an `_afterDeserialization` (the type-test-elimination precedent) is decided in P3
      from rig evidence, not now.
    - Gates as per §6: BOTH rigs + `fg homepage`'s snapshot round-trip on P1 and P3.
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

    ⇒ **DECIDED: grant integer bounds through each child's own `_reLayout(bounds)` — the
    engine-standard shape — with the explicit desire-clear KEPT; both hard constraints are
    satisfied structurally by the base grant path (the P2 spike still proves each against
    its tripwire).**
    - New arrange body, replacing the impose-triplet per child:
      heal-if-spec-missing (→ provisional, D8); `w.desiredPosition = nil;
      w.desiredExtent = nil`; `w._reLayout spec.grantedBoundsWithin newBoundsForThisLayout`.
      `grantedBoundsWithin` is a PURE function on the spec: a Rectangle from the four
      ROUNDED edges — integer by construction (round-at-the-producer), abutment-stable
      (D7), no read-backs (layout.md rulebook-compliant: inputs are spec fields, never
      laid-out pixels).
    - Constraint (i), island anchor — WHY it holds natively: the granted origin flows
      through base `Widget._reLayout` ~:5077 `@_applyMoveTo` — the PLAIN twin — so the
      island's anchor-ride fires (`TransformFrameWdgt._applyMoveBy` :310), and NO
      claimed-box offset is added (the Base twin `_applyMoveToBase` :291 adds
      `slotOffsetWithinClaim`, and the fractions encode the SLOT box — that offset is the
      mechanical content of the companion arc's Correction 3). A sugar island child takes
      exactly this route: `TrackingTransformFrameWdgt._reLayout` :43 supers INTO the base
      path. Tripwire stays `macroRotateChildInsideStretchablePanelThenResize`.
    - Constraint (ii), schedule-valve — WHY it holds natively: the granted extent flows
      through the POLYMORPHIC `_applyExtent` on BOTH shapes — base `_reLayout` ~:5090
      directly, and composite `_reLayout` overrides via `_applyGrantedBounds` ~:900 (whose
      extent line calls the polymorphic `_applyExtent`) — so the valve's deferred second
      re-lay (`_applyExtent` :2311-2312) for wrapping-text/nested-scroll interiors is
      preserved, as is the island's own `_applyExtent` forward-to-content override.
      Tripwires stay `macroDropIntoRotatedStretchablePanelStretchesOnResize` + text/scroll.
    - The DESIRE-CLEAR stays (two lines): the panel OWNS a spec-carrying child's frame, so
      a pending desire against it is stale by definition — user intent arrives through the
      post-flush re-record drain (the F7 architecture). Letting desires linger past a
      granted re-lay would fire them at the child's NEXT settle: a nondeterminism seed the
      current nil-ing already prevents.
    - Composite children (the dashboard population IS FrameWdgt windows): a granted
      `_reLayout` arranges the interior against the granted frame in the SAME pass, where
      today's shape raw-imposes then re-lays at current geometry — expected pixel-identical,
      and any settle-cadence delta is exactly what the P2 gates watch (`revisits`,
      capstone, census as-built + post-resize).
    - `world.disableTrackChanges()` bracket: A/B in the P2 spike; it is a paint-cost
      optimization — KEEP unless measured droppable; removal is not a goal of this arc.
    - The panel-side imposer pair (`_moveInStretchablePanelToFractionalPosition` /
      `_setExtentToFractionalExtentInPaneUserHasSet`) dies into the grant;
      `_moveInDesktopToFractionalPosition` survives re-sourced from the spec (the desktop
      imposes position-only — no grant, no child re-lay, as today). ⚠ The imposers'
      falsification comment block (Widget ~:2069) does NOT die with them: it moves to the
      grant seam (`grantedBoundsWithin` / the panel arrange), pinning WHY the grant must
      keep routing through the plain twins.
    - The founding antipattern TODO and its "cannot take a fractional position" clause die:
      the SPEC carries the fraction, `_reLayout` takes integer granted bounds — the
      non-question the §0 reframe promised.
D8. **Spec provenance — close the heal hole structurally (from the companion arc's §5).**
    Today a builder that adds into a stretch panel and only then places gets heal-pinned
    pre-placement fractions the fill-only drain respects (zero live instances; guarded only
    by the place-before-add comment rule). A spec CREATED at add can carry provisional-ness
    (heal-derived vs recorded), letting the drain overwrite provisional specs only — the
    convention hole becomes a type distinction. Decide the encoding (a flag on the spec vs
    two creation paths) and whether the two world Sets
    (`pendingFractionalBookkeepingSeeds` / `pendingFractionalReRecords`) merge into one
    provenance-aware queue.

    ⇒ **DECIDED: a `provisional` flag ON THE SPEC; the two world Sets stay separate.**
    - Creators and their provenance: the §5b heal → `provisional: true` (an emergency
      pre-placement guess made mid-arrange); the seed drain, the re-record drain, and the
      recorder (the seven F6 calls plus the two synchronous handle-remember hooks,
      `Widget` ~:2137/:2343) → recorded (`provisional: false`, clearing the flag on
      update). The spec is NOT created at add time (no valueless spec state; the seed-Set
      entry IS the "record pending" marker; `defaultLayoutSpecWhenAddedTo` stays
      untouched).
    - The seed drain's fill condition becomes `!spec? or spec.provisional`: the heal hole
      closes STRUCTURALLY. The classic sequence — add (enqueue) → builder's self-settle →
      arrange heals at pre-placement geometry (provisional) → builder places → next cycle's
      drain re-derives ONCE at builder-final geometry → recorded — lands exactly where the
      manual protocol did, and the fill-only overwrite ban keeps holding for every RECORDED
      spec (no repeated re-derive, no drift; island-TRANSFERRED and deep-copied specs are
      recorded, so the drain respects them as today). The place-before-add builder RULE
      thereby retires (the recorder's contract comment updates in P1); panel-side and
      world-side builders get identical semantics.
    - The Sets do NOT merge: they are two different MOMENTS, both measured into place by
      the companion arc — pre-layout fill (the arrange needs fractions before it imposes)
      vs post-flush overwrite (only post-flush geometry is a gesture's outcome). A merged
      provenance-aware queue would re-open both timing decisions to save nothing. Teardown
      clearing of both stays.
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

    ⇒ **DECIDED: YES — EDGE fractions, adopted WITH D1 so a second encoding migration
    never ships.**
    - The spec stores left/top/right/bottom fractions of the holder's bounds; extents are
      DERIVED from independently ROUNDED edges (`grantedBoundsWithin`). Two children
      recorded abutting share the same real edge fraction, so they round identically at
      EVERY panel size — seams/overlaps become unrepresentable. This is the same
      round-the-BOUNDARY idiom `StackLayoutEngine`'s placement loop already uses
      (:101-131: carry the exact edge, round each boundary once, adjacent children share
      it).
    - The fill-only law carries verbatim: edges are recorded at intent moments and never
      re-derived from imposed integers — D8's provisional gate is the only sanctioned
      overwrite.
    - The desktop consumer imposes left/top edges only (the negative-component skip becomes
      a negative-edge skip, same semantics and same comment rationale); right/bottom edges
      are stored-but-unread there, as the extent fields are today.
    - Expected churn: an imposed extent may shift ±1px wherever
      `round(R·W) − round(L·W) ≠ round((R−L)·W)`; the padded sample layouts may well show
      ZERO visible delta (this item's own observation), but ANY pixel delta goes through
      §6's diffpage + eyeball + owner-visible note BEFORE recapture, and the two inherited
      value-oracles' fixtures/plants move to the edge recipe in P4 (MACRO-PATTERNS'
      "Stretch-panel fractional reflow" entry updates with them).

D9. **(added in owner review, 2026-08-06) The two synchronous handle-remember hooks are
    DELETED — records happen at exactly two moments (the seed drain + the re-record
    family).** `_moveToNoSettle` ~:2137 and `_setExtentNoSettle` ~:2343 record per
    drag-step at PRE-flush geometry — the staleness class F7's post-flush re-record drain
    was built to fix; since F7, release overwrites whatever they wrote. Delete both hooks
    and, with them, `HandleWdgt.changeShouldRememberFractionalGeometry` (their only gate)
    and the two half-recorders `_rememberFractionalPositionInHoldingPanel` /
    `_rememberFractionalExtentInHoldingPanel` (whose only remaining callers are these
    hooks and the D2-deleted world-add half-record — the full-situation recorder becomes
    the single record entry). Spike-gated in P1: if the suite (esp. the two value-oracles
    and the handle tests) shows a live reader of mid-gesture records, restore and record
    the falsification in the ledger.

D10. **(added in owner review, 2026-08-06) Consumption membership becomes ONE child-aware
    query per consumer.** `consumesFractionalChildGeometry()` (holder-level, 3 call
    sites) is REPLACED by `consumesFractionalGeometryOf(child)` — base `false`; WorldWdgt
    `!child.isLayoutInert?() and child != @hand and !child.isDesktopIcon?()`;
    StretchablePanelWdgt `!child.isLayoutInert?()`. The `__add` seed, both drains, and
    the consumers ask the SAME query, so the seed's exclusions and the arranges' read
    exclusions can no longer drift — and desktop icons stop being seeded records nothing
    reads (today they carry dead fractional fields; `_reLayoutDesktop`'s
    `isDesktopIcon?()` skip becomes part of the one rule).
    **FOLLOW-ON FILED AT CLOSE (beside D3's BACKLOG line):** dissolve
    `_reLayoutDesktop`'s bin-opener/clock special-casing — the two `instanceof` searches
    + `userMovedThisFromComputedPosition` encode an ad-hoc "corner-anchored until the
    user intervenes" strategy that wants to be spec-kind dispatch (an anchor-only corner
    spec until grabbed; stretch spec after drop). Needs its own design beat:
    `CornerInternalLayoutSpec` as-is SIZES its carrier square (handles/badges), which the
    bin opener must not inherit.

## §5 Phases (post-approval)

P1 — `StretchLayoutSpec` class + Widget plumbing: BOTH drains (the fill-only seed station and
     the post-flush re-record drain) create/replace a spec instead of writing fields, per the
     D8 provenance decision; the seven F6 sites keep calling the recorder (its INTERNALS
     change, their calls are the stable API); consumers read the spec; fields become derived
     shims for ONE commit, then are DELETED same-phase (no long-lived dual state). Transfer
     method `_moveHoldingPanelBookkeepingTo` shrinks to `_stackElementSpec` only (D3) or dies
     (if D3 folds too). PLUS the owner-review additions: D9's deletions (the two synchronous
     hooks, `changeShouldRememberFractionalGeometry`, the two half-recorders — spike-gated)
     and D10's `consumesFractionalGeometryOf(child)` replacing the holder-level query at the
     seed and both drains. Census + presuite byte-green expected throughout — EXCEPT the
     predictable inspector wave: deleting the three own-fields (and showing a `layoutSpec`
     instead) will churn the inspector-family tests exactly as their APPEARANCE did in the
     companion arc (15 tests, diffpage-verify then the benign-inspector recapture rule) —
     and the possible D7 ±1px extent deltas (diffpage + eyeball + ledger note before any
     recapture).
P2 — the arrange conversion (D6). Gates: presuite, census (as-built + post-resize), the
     `revisits` gate (a conversion that changes settle cadence shows up there), capstone leg.
P3 — desktop adoption per D2; serialization per D5 (run BOTH serialization rigs +
     `fg homepage`'s production snapshot round-trip).
P4 — tests + docs + close: the two inherited value-oracles
     (`macroStretchPanelChildrenReflowOnResize`, `macroStretchChildHandleResizeSurvivesReflow`)
     must end the arc green; ADD a detachment-survival test in the family's style (detach a
     stretch child, re-add, proportions survive — mirroring the unification arc's ⚖⚖); update
     `docs/architecture/layout.md`'s spec-family section; archive + INDEX + BACKLOG (+ D3's
     new line + D10's desktop corner-spec follow-on line) + memory; end-of-arc review;
     commits presented.

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
`docs/archive/layout-spec-family-unification-plan.md` + `docs/archive/layout-spec-family-followups-plan.md`
(the family's design + case law) · `docs/architecture/layout.md` ·
`docs/archive/census-as-built-extension-plan.md` (the as-built oracle) ·
`src/macros/MACRO-PATTERNS.md` "Stretch-panel fractional reflow" entry (the testing idiom) ·
memory: `stretch-fractional-auto-bookkeeping-arc` (the companion's case law),
`proper-layouts-elimination-goal`, `no-serialization-compat-obligations`,
`layout-spec-family-plan-authored` (⚖⚖ specs survive detachment), `ask-before-commit-push`.

### Execution ledger (append per phase; empty at authoring)

#### P0 — design note authored 2026-08-05; OWNER REVIEW PENDING (no production code)
- All eight §4 decisions filled in as one package: D1 atomic edge-fraction spec,
  active-only lifecycle, `userMoved…` stays out / D2 world adopts (plus deleting the
  world-add half-record at `Widget` ~:3400) / D3 non-goal + BACKLOG line / D4 redefine
  `isFreeFloating` via a spec capability, full read-site audit enumerated / D5 core class,
  generic serialization, no migration shim / D6 grant via each child's own
  `_reLayout(bounds)`, desire-clear kept, imposer falsification pin relocated / D8
  `provisional` flag, the two Sets stay / D7 edge encoding from day one.
- Read-site audit (Category 1/2 in D4): 16 src `isFreeFloating` sites + the tests-repo
  paint-audit mirror, ~25 family `layoutSpec` sites, zero `instanceof` on the family
  anywhere. Risk concentrates entirely in the `isFreeFloating` gates (five setter no-ops,
  handle visibility, invalidation climb + FLOWRULE exposure, five FrameWdgt window-measure
  branches) — all neutralized by the single-query redefinition.
- Key mechanism facts verified in src at `de339bb1`: base `_reLayout`'s granted path
  routes origin→`_applyMoveTo` (plain twin, no claim offset) and extent→polymorphic
  `_applyExtent` (schedule-valve) — both D6 constraints hold on the base path;
  `TrackingTransformFrameWdgt._reLayout` supers into it; `_applyGrantedBounds` calls the
  polymorphic `_applyExtent` (composite path valve intact); serializer/deserializer are
  constructor-name generic (no registration for a new spec class); `_addNoSettle` ~:3348
  re-resolves `layoutSpec` on every reparent (base default nil — the D1 lifecycle hinge);
  the world-add half-record ~:3400 exists to be completed by the drain's either-missing
  condition, which an atomic spec makes unrepresentable (hence its deletion under D2).
- Conscious behavior changes for the owner to weigh (both flagged inline): (1) D1 —
  programmatic cross-panel reparents re-derive instead of imposing the old panel's stale
  fractions; (2) D7 — possible ±1px extent deltas at some panel sizes (diffpage-gated
  before any recapture).
- STOPPED at the §4 owner gate per §0.5; P1-P4 untouched.
- 2026-08-06 owner-review refinement: the D4 capability re-spelled as the family-base
  authority contract `LayoutSpec.ownsPlacement() -> true` / `StretchLayoutSpec -> false`
  (`isFreeFloating: -> !@layoutSpec? or !@layoutSpec.ownsPlacement()`), replacing the
  negative one-off `leavesChildFreeFloating?()`; child-vs-parent spec-provenance question
  answered in D4 (child-owned object, context-triggered arming — the stack-adoption shape).
- 2026-08-06 owner APPROVED §4 including two scope additions from the review dialogue —
  D9 (delete the stale synchronous handle-remember hooks + their gate capability + the
  half-recorders; spike-gated) and D10 (child-aware `consumesFractionalGeometryOf(child)`;
  desktop icons stop being seeded; the bin/clock corner-spec dissolution filed as a named
  follow-on at close). EXECUTION STARTED (P1).

#### P1 — executed 2026-08-06 (one merged batch; recapture gate in flight at writing)
- ⚖ The planned 1a (inert spec layer) / 1b (swap) split was REJECTED BY THE DEAD-METHOD
  GATE — `StretchLayoutSpec`'s methods may only land WITH their callers (the family's own
  "capability predicate lands with its callers" case law, now enforced structurally). One
  merged batch instead.
- ⚠⚠ REAL BUG caught by the first suite run (2 extra test failures + a paint-leg shard
  stall): the recorder now ARMS an active spec, so firing it unconditionally from the F6
  drop/uncollapse sites planted stretch specs on children of NON-consuming containers
  (stacks/documents) — `macroCenteredWidgetStaysCenteredWhenAlone`'s
  `layoutSpec.setAlignmentToCenter()` hit a stretch spec → TypeError → the
  zero-screenshots shard stall. The OLD field-writes were inert on any parent; an armed
  spec is not. FIX: the recorder itself gates on
  `fig.parent.consumesFractionalGeometryOf(fig)` — one gate, every caller correct
  (recorded as a ⚠ comment on the recorder).
- Landed: StretchLayoutSpec (edge fractions + outside flag + provisional; recordFor /
  grantedBoundsWithin), LayoutSpec.ownsPlacement contract + isFreeFloating redefinition,
  recorder→spec (provenance param), both drains provisional-aware via
  consumesFractionalGeometryOf, imposers spec-reading (plain twins untouched),
  _reLayoutDesktop spec-reading + membership query, panel heal → provisional, trio
  prototype fields DELETED, half-recorders + positionFractionalInWidget /
  extentFractionalInWidget / positionPixelsInWidget DELETED, D9 deletions (sync hooks,
  changeShouldRememberFractionalGeometry, the whole widgetStartingTheChange param family —
  HandleWdgt was the only 2nd-arg caller), world-add half-record DELETED (D2),
  _moveHoldingPanelBookkeepingTo → _moveKeptStackSpecTo (stack spec only).
- Suite after fix: paint leg PASS in parallel; dpr1 280 tests, 22 failed, 0 geometry
  violations, 0 errors — ALL triaged into the two §4-predicted classes via fg diffpage +
  fg classify + eyeball: 16 inspector-carrying tests (own-props row wave + thumb
  geometry, incl. MovingSliders/MultilineText/PlotUncollapse/WrappingText which all show
  inspectors) and 6 stretch-family tests (D7 1px class: DegreesConverter's 21px-wide
  abutment strip at the panel boundary, the shared-fixture 366x241 plot-interior 1px
  shift across 3 dashboard tests, RotateChild's 1px silhouette edge — explicitly NOT the
  ~15px Bug-G anchor signature). fg recapture --auto launched (gated; verdict pending).
- ⚠ PROCESS lesson (cost ~20 min): never launch an fg run while the previous wrapper is
  ALIVE — the overlapped runs shared the verdict file (clobbered stamp disarmed a
  hang-guard) and the log fd (interleaved/null-padded log). Wait for exit or TaskStop +
  fg killz first.
- P1 close: `fg recapture --auto` ✅ COMPLETE — the 22 triaged tests recaptured at dpr
  1+2, full suite GREEN at both densities.

#### P2 — arrange conversion, executed 2026-08-06 (all gates green)
- `StretchablePanelWdgt._reLayout` → the engine-standard grant: per consumed child,
  heal-if-missing (provisional) → desire-clear → `w._reLayout
  w.layoutSpec.grantedBoundsWithin(newBounds)`. The founding antipattern TODO and the
  panel-side imposer pair (`_moveInStretchablePanelToFractionalPosition` /
  `_setExtentToFractionalExtentInPaneUserHasSet`) are DELETED; the falsification pin
  moved onto the surviving desktop imposer + the grant comment (both point at base
  `_reLayout`'s plain-twin routing as what sanctions the shape).
- HARDENING found while converting: the arrange loop now applies the D10 membership rule
  (`continue unless @consumesFractionalGeometryOf w`) — P1's gated recorder had opened a
  latent nil-deref for a layout-inert overlay (highlighter) parked in the panel: the heal
  would be refused a spec, then the grant would deref nil. The membership rule at the
  read site closes it (and completes D10: seed + drains + BOTH consumers ask one rule).
- `world.disableTrackChanges()` bracket KEPT (paint-cost optimization, still valid under
  the grant); droppability deliberately not measured — removal is not a goal (D6).
- Gates: presuite — the conversion was PIXEL-IDENTICAL across all 280 tests except ONE
  inspector test whose members-list geometry shifted from the two DELETED prototype
  methods (the known prototype-member inspector class; diffpage + eyeball confirmed,
  gated recapture ✅ COMPLETE); both tripwires
  (macroRotateChildInsideStretchablePanelThenResize,
  macroDropIntoRotatedStretchablePanelStretchesOnResize) GREEN on the granted path —
  constraints (i) island anchor and (ii) schedule-valve hold natively, as designed.
  `fg census` OK — 0 movers in both sweeps (as-built 1626 / post-resize 1729). `fg
  revisits` OK — profile matches the baseline exactly (zero new settle re-visits from
  the conversion). Capstone leg rides the P4 gauntlet.

#### P3 — desktop + serialization, closed 2026-08-06 (all green first run)
- The D2 desktop conversion itself had landed in P1 (deleting the fields forced both
  consumers over at once); P3 was the EVIDENCE phase: BOTH serialization rigs OK
  (roundtrip rig incl. pop-up snapshot-hygiene + teardown-hygiene; file-roundtrip rig),
  and `fg homepage` OK — the PRODUCTION tree (pre-compiled image) boots clean and
  survives the whole-world snapshot round-trip WITH StretchLayoutSpec objects on its
  desktop children (55224-byte snapshot, 11 desktop children preserved) — the one gate
  that could catch a production build missing the spec class.
- D5 residue decision (was deferred to rig evidence): NO `_afterDeserialization` strip,
  no migration/compat code of any kind — the rigs' fresh snapshots round-trip clean and
  old snapshots are simply stale per the standing owner rule (they also largely
  self-heal via FileLoading's F6 re-record on load).

#### P4 — close, 2026-08-06
- NEW TEST `macroStretchChildDetachReaddKeepsProportions` (suite 280 → 281; 3 images,
  dpr 1+2): nine in-macro value asserts pin the per-attachment lifecycle end-to-end
  (recorded seed → nil on detach → fresh RECORDED spec via the heal→fill-drain provenance
  path on re-add → all four edge fractions EXACTLY equal at unchanged geometry → new
  object identity), then two reflow screenshots prove the survived proportions drive
  imposition. Proven NON-VACUOUS twice: planted wrong edge fractions fail both reflow
  images; a flipped assert expectation fails at the assert. ⚠ Authoring gotcha hit and
  catalogued: `firstChildSuchThat` scans DIRECT children only — the panel is nested at
  `win.contents.contents`; use the MACRO-PATTERNS `topWdgtSuchThat` locator idiom (the
  first capture attempt shard-erred on exactly this).
- Docs: `docs/architecture/layout.md` §4.2 — family doctrine rewritten (ownsPlacement
  authority contract, the follower entry, the free-floating redefinition, the D1 §4
  invalidation-rule wording); `src/macros/MACRO-PATTERNS.md` stretch-reflow entry
  updated (spec-based plant recipe, the third test, the locator gotcha);
  `docs/BACKLOG.md` gained the D3 kept-slot line + the D10 desktop corner-spec
  follow-on line.
- Final gate: fg gauntlet 2026-08-06 — **14/14 GREEN, 266s, 281 tests, no serial
  retries** (dpr1 112s / dpr2 117s / webkit 130s / apps 89s / parts 48s / paint 99s /
  tiernaming 118s / settle 118s / capstone 119s / refs 25s / revisits 118s / census 10s /
  serialization 54s / storage 118s). Arc CLOSED; plan archived same day.

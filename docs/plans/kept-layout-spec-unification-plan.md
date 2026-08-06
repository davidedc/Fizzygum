# Kept layout specs join the one lifecycle — dormant/armed specs, the last hand-carry dies

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-06; §1 verified same day against Fizzygum `bb1a5621` / Fizzygum-tests
`fce35ef3f` (the stretch-layout-spec-unification arc's close — its landed state is this plan's
starting point). ⚠ Line numbers drift — quoted method/class names are authoritative; re-grep
before trusting a line.
✅ **Prerequisite MET:** `docs/archive/stretch-layout-spec-unification-plan.md` EXECUTED + PUSHED
2026-08-06 — the ACTIVE per-child tier is unified (five spec classes, `ownsPlacement()`
authority contract, per-attachment stretch lifecycle), and the island transfer already shrank
to a single line (`Widget._moveKeptStackSpecTo`). Its §8 ledger + `archive/INDEX.md` entry are
REQUIRED reading (the armed-spec-is-not-an-inert-field lesson, the query-redefinition method,
the dead-method-gate batching law). **Phase 0 here is a DESIGN + MEASUREMENT phase with an
OWNER GATE** — no production code before the owner approves the §4 decisions.

**MANDATE.** ONE lifecycle story for every per-child layout spec. Today the family has three
(whole-life knob / per-placement-kept / per-attachment) implemented through TWO shadow fields
(`Widget._stackElementSpec`, `Widget._divisionBox`) that double-reference the active spec while
armed, ONE remaining island hand-carry (`_moveKeptStackSpecTo`), and ~14 container-side reads
that reach past the active tier into the kept field. The fold ELIMINATES the shadow-field
mechanism — the kept fields are DELETED or re-classified, not wrapped (the elimination-goal
filter; a veneer is the named §7 rejection).

---

## §0 Orientation

**Fizzygum** — CoffeeScript canvas GUI framework; ~470 classes, no modules, all globals; build
+ test via the `fg` wrapper from ANY cwd (`fg build` · `fg presuite` ~2 min inner loop ·
`fg gauntlet` ~5 min full gate · `fg census` · `fg revisits` · `fg recapture <t>|--auto` gated
recapture · `fg diffpage <t>` + `fg classify` for churn triage · `fg killz`). Long ops: launch
ONCE with the Bash tool's `run_in_background` + a log redirect, wait for the completion
notification, peek `/tmp/fg-<cmd>.verdict` sparingly; NEVER launch an fg run while the previous
wrapper is alive (shared verdict file + log fd — measured cost ~20 min, stretch arc ledger).
Read first: `Fizzygum/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md`, `docs/architecture/layout.md`
(the rulebook — §4.2 is the spec-family section this plan extends).

**Why this plan exists now.** The 2026-08 spec-family program unified the ACTIVE tier: HOW a
child participates in its container's layout is one `Widget.layoutSpec` object (five classes;
free-floating = no spec OWNS placement, via `LayoutSpec.ownsPlacement()`). But the family's
KEPT tier — what survives detachment so user edits and class knobs outlive a placement — is
still pre-unification machinery: two shadow prototype fields holding the same objects the
active tier arms, moved by hand across sugar-island wraps, read directly by `FrameWdgt`'s
sizing negotiation, with lifecycle rules that exist only as per-class prose in
`LayoutSpec.coffee`'s header.

**CRITICAL REFRAME.** The family ALREADY half-contains the concept this plan completes:
`VerticalStackLayoutSpec.attachedAsFrameContent` is a ROLE bit that flips one kept object
between "window content" and "stack element" — the `is*Active()` queries dispatch on it. What
the family lacks is ARMED-ness: "is this spec currently governing its carrier's placement, or
is it dormant memory riding along?". Today armed-ness is encoded structurally (kept field ==
active field, two references to one object), which is exactly why the shadow fields, the
hand-carry, and the double-reference fullCopy hazard exist. Make dormancy a first-class state
of the ONE spec slot and the shadow tier dissolves.

## §1 Current state (verified 2026-08-06 at `bb1a5621`)

**The kept-tier inventory (re-grep before trusting counts):**
- `_stackElementSpec`: **102 references across 24 src files, ZERO in Fizzygum-tests** (no
  macro or harness reads it — but it IS visible in inspector own-prop listings, so deleting
  or renaming it churns the inspector test family; the stretch arc's benign-wave precedent).
- `_divisionBox`: **22 references across 4 src files** (`Widget`, `LayoutSpec` header,
  `DivisionStackLayoutSpec` doc, `authoring/LayoutElementAdderOrDropletWdgt`).
- The one hand-carry: `Widget._moveKeptStackSpecTo` (~:1645) — two lines (move + nil, single-
  owner rule against fullCopy double-reference), called ONLY from
  `_materializeSugarIslandNoSettle` / `_dematerializeSugarIslandIfIdentityNoSettle`; the
  ACTIVE spec already rides those reparents via `_addNoSettle`'s `layoutSpec:` arg.

**Who writes `_stackElementSpec`:**
- The two Widget initialisers: `initialiseDefaultFrameContentLayoutSpec` (~:336; binds
  `.element` immediately — the U2 pre-capture measure fallback in `getWidthInStack` derives
  from the element's natural width, so the back-ref must exist BEFORE the first arrange) and
  `initialiseDefaultVerticalStackLayoutSpec` (~:343; guarded
  `unless @_stackElementSpec?.isContentStackCapable?()` so an existing capable object —
  including a FrameContentLayoutSpec moved from a window into a stack — is KEPT, preserving
  explicit edits).
- ~20 leaf-class OVERRIDES of those initialisers (IconWdgt, AnalogClockWdgt, SliderWdgt,
  BinWdgt, MenuWdgt, TextWdgt, SimpleTextWdgt, PaletteWdgt, the app/info windows, …): each
  calls the base shape then sets its class knobs (`grow = 0`, `canSetHeightFreely = false`,
  `resizerCanOverlapContents`, starting-size sentinels). These are per-class DEFAULT
  constructors of the child's own preferences — the bulk of the 102 references.
- The stack ADOPTION: `SimpleVerticalStackPanelWdgt._positionAndResizeChildren` ~:267-273 —
  `unless widget.layoutSpec?.isStackElementActive?()` → `initialiseDefaultVerticalStack…()` →
  `_setLayoutSpec widget._stackElementSpec` (mid-pass arming is the established idiom).
- The frame-content mount: `FrameWdgt._addNoSettle` ~:601-612 — init unless
  `isFrameContentSpec?()`, set `attachedAsFrameContent = true`, `desiredWidth = nil` unless a
  same-content chrome-rebuild remount, then `super … layoutSpec: aWdgt._stackElementSpec`.

**Who reads `_stackElementSpec` directly (bypassing the active tier):** `FrameWdgt` ×14
(~:151/:180/:189/:205 measure+negotiation incl. `getWidthInStack`; :263/:273 role check +
desiredWidth clear; :451 `canSetHeightFreely` gate; :555 the early-settle predicate
`isFreeFloating() and !@contents?._stackElementSpec?.desiredWidth?`; :787 the float-home
chrome-height math; :988 own-content knob); `KeepsRatioWhenInVerticalStackMixin`;
`StretchableWidgetContainerWdgt`; a few builders touching knobs post-init.

**The role-bit precedent:** `VerticalStackLayoutSpec.attachedAsFrameContent: false` /
`FrameContentLayoutSpec.attachedAsFrameContent: true`; `isStackElementActive: ->
!@attachedAsFrameContent`, `isFrameContentActive: -> @attachedAsFrameContent`;
`captureInitialPlacement: (@element, @stack) ->` on both. So "Active" in those names already
means ROLE, not armed-ness; armed-ness is the field-identity convention.

**`_divisionBox`:** declared `Widget:~303`; created lazily by `_ensureDivisionBox`; armed via
the public door `divisionBox(axis)` (~:4720) as `holder.add w, nil, w.divisionBox('y')` and by
the adder reconciler (`newAdder._setLayoutSpec newAdder._divisionBox`, ~:5250); its knobs are
written by `setMinAndMaxBoundsAndSpreadability` (~:4873) and the divider drag (max trade). Doc
contract (`LayoutSpec.coffee` header + layout.md §4.2): a per-widget KNOB kept for the
widget's whole life — a divider-tuned cell dragged out and back keeps its box. It is NOT
moved by the island hand-carry (never was).

**Lifecycle events today:** `_beforeBeingGrabbed` (~:4556) nils the ACTIVE spec only — kept
fields survive any grab/reparent; `_addNoSettle` re-resolves the active spec on every reparent
(`opts.layoutSpec ? aWdgt.defaultLayoutSpecWhenAddedTo(@)`, base nil); the layout-scaffold
reconcilers insert spec-less and arm via `_setLayoutSpec` mid-pass, and detach the spec before
`_fullDestroyNoSettle` (FLOWRULE-safe idiom, layout.md §4.2); the STRETCH spec (fifth member)
has NO kept slot at all — per-attachment, re-derived at entry (its values carry no user
edits).

**COEXISTENCE (the open measurement):** `_divisionBox` and `_stackElementSpec` are separate
fields, so one widget CAN carry both (a division cell whose box was divider-tuned, later
adopted by a content stack, later returned to a division). Whether any live flow or test
exercises both-at-once is UNMEASURED — it is P0's first deliverable, and the §4 E1 decision
hinges on it.

## §2 Why it is shaped this way

The kept fields predate the family: `_stackElementSpec` carried the stack's per-element state
before `layoutSpec` existed (the unification arc translated the old tag+details split
faithfully rather than redesigning lifecycle); `_divisionBox` began as loose min/desired/max
fields on the widget and was object-ified in the same arc. The double-reference-while-armed
shape was the cheapest faithful translation, and the island hand-carry was built (affine §7.5)
because kept fields do not ride `_addNoSettle`'s spec argument. Nothing ever revisited the
lifecycle as a whole because each piece worked — the split is strata, not design.

## §3 The distilled argument

Every cost is already visible as a scar: the hand-carry exists because kept state does not
ride the child the way the active spec does; the fullCopy single-owner rule exists because two
fields reference one object; FrameWdgt reads the shadow field because the active field may be
nil while detached — i.e. because DORMANT state has no home; and the three lifecycle stories
live in a header comment because the code cannot express them. The stretch arc proved the
method that retires this class of debt: put the distinction ON the spec (authority →
`ownsPlacement()`; provenance → `provisional`), redefine the ONE query instead of the N sites,
and let the `layoutSpec:` add-arg carry the object. Armed-ness is the last such distinction
still encoded structurally. Doing this NOW is cheap for the same reason the stretch fold was:
the active tier is freshly uniform, the hand-carry is already one line, and the family's
capability vocabulary (`is*Active()`, role bits) is in place to absorb the state.

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — Fizzygum clean at/past `bb1a5621`,
   Fizzygum-tests at/past `fce35ef3f`, 281 SystemTests, last gauntlet green. If not, STOP and
   re-orient (the stretch arc must be landed).
2. Read this plan in full; then `docs/architecture/layout.md` §§3-4 (rulebook + spec family);
   then `docs/archive/stretch-layout-spec-unification-plan.md` §4 (the decided design — this
   plan's method template) + its §8 ledger and `archive/INDEX.md` entry (case law); then, in
   src: `LayoutSpec.coffee` + `VerticalStackLayoutSpec.coffee` + `FrameContentLayoutSpec.coffee`
   + `DivisionStackLayoutSpec.coffee` in full; `SimpleVerticalStackPanelWdgt`'s adoption +
   arrange; `FrameWdgt`'s content-mount `_addNoSettle` override and the 14 `_stackElementSpec`
   sites; `Widget`'s regions: the two initialisers, `_moveKeptStackSpecTo` + the island
   materialize/dematerialize pair, `_beforeBeingGrabbed`, `_addNoSettle`'s spec resolution,
   `divisionBox`/`_ensureDivisionBox`/`setMinAndMaxBoundsAndSpreadability`.
3. P0 produces the §4 decisions (E1-E7 filled in with the P0 measurements attached) IN THIS
   FILE and STOPS for owner review. Only after approval: P1-P3 with `fg presuite` per batch,
   `fg gauntlet` at phase closes, census green throughout.
4. Commits: present messages (`git commit -F <file>`); never commit/push without the owner's
   word.

## §4 Phase 0 — design decisions (owner-gated; fill in with P0 evidence, then STOP)

E1. **The fold shape.** Candidates:
    (C) **One slot + dormancy** — DELETE both kept fields; the spec object stays in
        `Widget.layoutSpec` across detachment, marked DORMANT; adoption/mount ARM it
        (recommended if E1-M says coexistence is not load-bearing).
    (D) **Narrow fold** — `_stackElementSpec` folds per (C); `_divisionBox` is RE-CLASSIFIED
        as what its contract already says it is — a whole-life sizing KNOB of the widget
        (like `minimumExtent`), not a kept spec: it stays a field, possibly renamed, armed
        into the slot exactly as today. Choose if coexistence IS load-bearing (a widget must
        hold a dormant stack spec AND its division box simultaneously) or if (C)'s slot
        contention proves ugly in the spike.
    (A) **Merge the two kept fields into one** — REJECT unless P0 falsifies the coexistence
        model entirely; it conflates a whole-life knob with per-placement memory and buries
        the mechanism instead of eliminating it.
    P0 MEASUREMENTS this decision needs: (E1-M1) does any builder/flow/test put a
    divider-tuned division box AND a stack spec on one widget across its life (grep +
    runtime probe: division cell → drag into document stack → back); (E1-M2) enumerate every
    `_stackElementSpec` site into writer/reader/knob-override classes with counts (start from
    §1's inventory); (E1-M3) A/B the dormant-slot spike on the FrameWdgt mount path (the
    hairiest consumer) before committing to (C).
E2. **Dormancy encoding + the free-floating contract.** A dormant spec must NOT own its
    carrier's placement. Candidates: an `armed` boolean on `LayoutSpec` consulted by
    `ownsPlacement()` (state-aware authority: `@armed and <class answer>`), vs dormant specs
    living in a separate single field (rejected — that re-creates the shadow tier), vs
    armed-ness derived from context (`@parent` consistency checks — rejected: derivation at
    every read is the antithesis of the family's synchronously-maintained-fields rule).
    Recommendation: the `armed` flag, set/cleared ONLY by `_setLayoutSpec`-tier plumbing
    (arming) and the detach paths (disarming) — mirror how `provisional` landed. MUST hold:
    `isFreeFloating` stays behavior-identical for every existing population (the stretch
    arc's D4 audit table is the checklist — re-verify the 16 sites against dormancy);
    `_setLayoutSpec`'s handle-visibility tail fires correctly on arm/disarm; the
    `isStackElementActive`/`isFrameContentActive` role queries must now ALSO answer false
    when dormant (today field-identity implied it — the stack adoption guard depends on it).
E3. **Grab/reparent semantics — the keep policy goes per-class ON the spec.**
    `_beforeBeingGrabbed` and `_addNoSettle`'s re-resolution currently nil the active spec;
    under the fold they DISARM instead, and whether the object survives detachment is the
    spec's own declaration (`keptAcrossDetachment()`: stack/frame-content/division true —
    they hold user edits or whole-life knobs; stretch false — derivable, per-attachment, its
    lifecycle is UNCHANGED by this arc). ⚠ The `opts.layoutSpec ?` resolution seam is the
    CoffeeScript-defaults nil-sentinel trap (followups-arc case law): an explicit-nil arg and
    an absent arg are indistinguishable — decide the resolution order (explicit arg > the
    widget's own dormant spec re-armed by the destination's adoption > class default) and
    verify the island wrap still gets the CONTENT's spec onto the ISLAND (E4).
E4. **The island hand-carry dies — verify, don't assume.** Under (C)/(D) the spec object
    rides `_addNoSettle`'s `layoutSpec:` arg on materialize/dematerialize exactly as the
    active spec does today, so `_moveKeptStackSpecTo` is DELETED. MUST verify in the spike:
    the content INSIDE the island must not read as stack-active (its spec is on the island —
    single object, single carrier; check `_childWidthInStack`'s proportional tracking against
    the historical failure the hand-carry's comment documents), and fullCopy of a wrapped
    figure must not double-reference (the single-owner rule the MOVE existed for — under one
    slot this holds by construction, but PROVE it with the duplication rig/test).
E5. **FrameWdgt's 14 direct kept reads become tier-honest.** Measure/negotiation reads
    (`getWidthInStack`, `canSetHeightFreely`, `desiredWidth`, the :787 chrome math, :555
    early-settle predicate) read the child's spec through ONE accessor that answers for
    armed-or-dormant (they are questions about the child's PREFERENCES, valid in both
    states); the mount path (~:601-612) becomes the arming idiom. ⚠ The U2 pre-capture
    fallback must survive: `.element` binds at initialisation, before the first arrange.
    ⚠⚠ Do NOT touch the hug/grow semantics while re-plumbing — hug-suppression is falsified
    ×3 (sizing-model arc); this arc changes WHERE state lives, never WHAT the negotiation
    answers.
E6. **The ~20 leaf-class initialiser overrides stay.** They are per-class constructors of the
    child's own default preferences — reshaping them is churn without elimination (the
    mandate targets the shadow-field mechanism, not the knob declarations). Only their BASE
    pair in Widget changes (writing the slot instead of the shadow field).
E7. **Serialization + churn expectations.** The kept fields serialize today; under the fold
    the one slot serializes (dormant specs included — they carry user edits, that is the
    point). NO migration/compat code (standing owner rule); old snapshots are stale.
    Expected suite churn: the inspector own-prop wave ONLY (`_stackElementSpec` rows
    disappear/`layoutSpec` rows change + prototype-member deletions shift member lists —
    both pre-sanctioned benign classes, diffpage-verify then `fg recapture`). The pixel
    oracles that must stay byte-green: the division family
    (`macroDivisionCellMenuEditsSpec` — VALUE asserts on the spec's knobs,
    `macroLayoutBasicProportions`, the border-skeleton test), the stack family
    (`macroCenteredWidgetStaysCenteredWhenAlone`,
    `macroSimpleDocumentCanAddIndentedParagraph` — both hard-deref `layoutSpec` methods),
    window sizing (`macroWindowsNestedCollapsingUncollapsing`, uncollapse/float tests), and
    the stretch trio (untouched by this arc, so ANY churn there is a regression).

## §5 Phases (post-approval)

P0 — the measurements (E1-M1..M3) + the §4 decisions filled in + the FrameWdgt spike; STOP
     for owner review. No production code.
P1 — the mechanism: `armed` (+ `keptAcrossDetachment()`) on the family base; `_setLayoutSpec`
     tier arms/disarms; `_beforeBeingGrabbed` + `_addNoSettle` resolution per E3; the two
     Widget initialisers write the slot; `_moveKeptStackSpecTo` DELETED (E4 verifications in
     the same batch — the dead-method gate requires capability+callers together, stretch-arc
     law); shadow fields become derived shims for AT MOST one presuite cycle, then are
     DELETED same-phase (no long-lived dual state).
P2 — the consumers: stack adoption + FrameWdgt mount/measure per E5; the adder reconciler +
     `divisionBox` door per E1's chosen shape; scaffold insert/teardown idiom re-verified
     (mid-pass FLOWRULE discipline unchanged).
P3 — tests + docs + close: run BOTH serialization rigs + `fg homepage`; ADD a lifecycle test
     in the detach/re-add value-assert style (`macroStretchChildDetachReaddKeepsProportions`
     is the template): stack element with an explicit alignment edit → detach → re-add →
     the SAME spec object re-arms with the edit intact (the ⚖⚖ survival law, now asserted on
     object identity + knob value, proven non-vacuous by a plant); update layout.md §4.2
     (lifecycle paragraph + the kept-slot mentions) and `LayoutSpec.coffee`'s header;
     BACKLOG line closed; archive + INDEX + memory; end-of-arc review; commits presented.

## §6 Verification protocol

`fg presuite` per batch; `fg gauntlet` at P1/P2/P3 closes; `fg census` free anytime (the
arrange-idempotence oracle — but note it cannot see lifecycle state, only geometry); BOTH
serialization rigs + `fg homepage` on any batch touching serialization-visible state (P1 and
P3 at minimum — dormant specs on desktop/window children WILL appear in production
snapshots); `fg revisits` at P2 (adoption-path changes can shift settle cadence). Expected
churn ZERO except E7's two benign classes — each recapture preceded by `fg diffpage` +
eyeball + a ledger note. New/changed tests captured at dpr 1+2 and proven non-vacuous
(plant, watch it fail, restore — both a value plant and a flipped assert, the stretch-arc
template).

## §7 Rejected / do-not-re-attempt

- **A veneer over kept fields** (accessors wrapping `_stackElementSpec` in place) — burying,
  not eliminating; the same filter that shaped the stretch arc.
- **Deriving armed-ness at read time** (parent-pointer consistency checks) — the family rule
  is synchronously-maintained fields, never read-back derivation.
- **Landing the capability before its callers** — the dead-method gate rejects it
  structurally (measured, stretch arc P1a).
- **Touching hug/grow semantics while re-plumbing FrameWdgt** — hug-suppression is falsified
  ×3 (`docs/archive/sizing-model-unification-plan.md`); this arc relocates state only.
- **Treating an armed spec like an inert field** — the stretch arc's central lesson: arming
  has behavioral edges (handle visibility, adoption guards, isFreeFloating); every
  arm/disarm site change needs the D4-style read-site check, not optimism.
- **Merging `_divisionBox` into the stack spec object** — rejected in the stretch arc's §7
  already (wrong direction) and re-rejected here as shape (A) unless P0 falsifies
  coexistence outright.

## §8 References + execution ledger

`docs/archive/stretch-layout-spec-unification-plan.md` (method template + case law) ·
`docs/archive/layout-spec-family-unification-plan.md` + `-followups-plan.md` (the family's
birth + the nil-sentinel trap) · `docs/architecture/layout.md` §4.2 ·
`docs/archive/sizing-model-unification-plan.md` (hug-suppression falsifications) ·
`src/macros/MACRO-PATTERNS.md` (the detach/re-add test template entry) · memory:
`stretch-layout-spec-unification-arc`, `layout-spec-family-plan-authored`,
`proper-layouts-elimination-goal`, `no-serialization-compat-obligations`,
`ask-before-commit-push`, `byte-identical-not-sacred-for-benign-inspector-recapture`.

### Execution ledger (append per phase; empty at authoring)

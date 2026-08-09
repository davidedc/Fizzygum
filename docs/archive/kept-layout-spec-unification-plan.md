> **ARCHIVED — COMPLETE (executed 2026-08-06, single session; P0 in TWO ROUNDS — the round-1 slot-with-dormancy package superseded mid-review).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Kept layout specs join the one lifecycle — the knob model, the last hand-carry dies

**STATUS: EXECUTED IN FULL + CLOSED 2026-08-06** (P0 in two rounds — the round-1
slot-with-dormancy package superseded by the owner-ratified KNOB MODEL — then P1/P2/P3 in
one session; final gauntlet 14/14 green at 282 tests). Archived verbatim; the CURRENT
state lives in `docs/architecture/layout.md` §4.2 (the two-kind lifecycle taxonomy) and
`src/LayoutSpec.coffee`'s header; the phase-by-phase evidence is the §8 ledger.

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

**CRITICAL REFRAME (authoring-time hypothesis — P0 verdict below).** The family ALREADY
half-contains the concept this plan completes:
`VerticalStackLayoutSpec.attachedAsFrameContent` is a ROLE bit that flips one kept object
between "window content" and "stack element" — the `is*Active()` queries dispatch on it. What
the family lacks is ARMED-ness: "is this spec currently governing its carrier's placement, or
is it dormant memory riding along?". Today armed-ness is encoded structurally (kept field ==
active field, two references to one object), which is exactly why the shadow fields, the
hand-carry, and the double-reference fullCopy hazard exist. Make dormancy a first-class state
of the ONE spec slot and the shadow tier dissolves.

**P0 VERDICT on the reframe (2026-08-06): the diagnosis overreached, and the fold landed
on the OPPOSITE frame.** Measurement showed the structural encoding is not the root cause:
the hand-carry existed because container READS bypassed the active tier (fixable by one
slot-first accessor alone), the fullCopy hazard was cross-widget only and is vestigial (both
graph engines identity-map, E1-M4), and slot-homed dormancy CREATES a contention (armed
stretch record vs dormant memory, E1-M1 probe B) that today's two-tier reality never has.
The decided frame is **attachment ≠ preferences**: the slot stays purely the current
attachment, and kept preferences are carrier-owned whole-life KNOBS — the
`cornerSpec`/`_divisionBox` idiom the family already sanctions, extended to its third and
last member. Armed-ness stays structural, and that is now a feature, not the bug. §4 has
the full evidence chain.

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

**P0 VERDICT on this argument (2026-08-06): the scars are real; the attribution was half
wrong.** Measurement traced each scar to its actual cause: the hand-carry and the FrameWdgt
bypass reads both trace to READS going to the kept field instead of the active tier (one
slot-first accessor retires both), and the fullCopy single-owner rule guards a hazard the
modern graph engines don't have (E1-M4). "Dormant state has no home" was the one
mis-attribution — it HAS a home (the carrier-owned field), and giving it the slot instead
CREATES a contention (E1-M1 probe B). The decided fix is therefore the knob model (§4 E1),
not slot-homed dormancy.

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

**DESIGN NOTE authored 2026-08-06, REVISED same day after owner direction (Phase 0, at
Fizzygum `0293fb64` / tests `fce35ef3f`, 281 SystemTests, last gauntlet 14/14 green).
P0 ran in two rounds. Round 1 executed the three planned measurements and produced a
slot-with-dormancy package (`armed` flag + dormant state + a parked-memory rule). Round
2 — the owner's direction question ("the path that is clean and uniform, unencumbered by
legacy, vestigial cruft and backward compatibility") — exposed that package's parking
rule as behavior-preservation machinery, and a fourth measurement (E1-M4, the
cross-widget sharing probe) removed the single-owner constraint that was the last
argument for slot-homed memory. The FINAL package is the KNOB MODEL: attachment ≠
preferences — the slot (`layoutSpec`) stays purely the current attachment with today's
exact semantics, and BOTH kept tiers are re-classified as carrier-owned whole-life knob
fields (the `cornerSpec`/`_divisionBox` idiom the family already sanctions), read
slot-first through one accessor; the island hand-carry dies because the knob never
leaves its owner. ZERO new lifecycle states, no changes to
`_setLayoutSpec`/`_beforeBeingGrabbed`/`_addNoSettle`. Probes preserved at
`Fizzygum-tests/.scratch/kept-spec-coexistence-probe.js` (19 checks),
`.scratch/kept-spec-spike-rearm-probe.js` (11 checks, spike-only) and
`.scratch/kept-spec-sharing-probe.js` (11 checks); the round-1 spike was 4 src files,
presuite-verified, then FULLY REVERTED (tree clean at `0293fb64`, rebuilt).
OWNER-RATIFIED direction 2026-08-06 ("update the plan"); execution start still gated on
the owner's word per §0.5. No production code written.**

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

    ⇒ **DECIDED: (D) GENERALIZED TO BOTH KEPT TIERS — the knob model.** E1-M1 falsified
    pure (C) (and not on the pair the plan predicted); a first-round completion (parking
    rule, see §7) was then rejected on the owner's clean/uniform/no-backcompat criterion;
    E1-M4 removed the single-owner constraint that was the last argument for slot-homed
    memory. The decided shape:
    - **The slot (`Widget.layoutSpec`) is purely the CURRENT ATTACHMENT** — nil when
      free-floating, today's exact semantics. No armed flag, no dormant state, no
      parking, no capability-gating; `_setLayoutSpec`, `_beforeBeingGrabbed`,
      `_addNoSettle` and `isFreeFloating` are all UNTOUCHED.
    - **Underivable preferences are carrier-owned whole-life KNOB fields** — the idiom
      `HandleWdgt.cornerSpec` (`:42`, armed via the add-arg default `:52`) and
      `_divisionBox` already are. `_stackElementSpec` is RE-CLASSIFIED as the third knob
      (alignment/grow/base-width and the FCLS sentinels are widget properties like
      `minimumExtent`, not attachment state) and renamed `_contentStackSpec` in its own
      later batch (§5 P2) — the field/accessor pair `_contentStackSpec`/
      `contentStackSpec()` mirrors the existing `_divisionBox`/`divisionBox()` pair.
    - **The family's lifecycle taxonomy collapses to exactly TWO kinds, one sentence
      each:** a carrier-owned KNOB (division box, corner spec, content-stack
      preferences — armed into the slot at attachment, resting in its field otherwise)
      vs a per-attachment RECORD (stretch — derived at entry, discarded at exit). The
      three per-class prose stories in `LayoutSpec.coffee`'s header become this one
      statement.
    - **`_moveKeptStackSpecTo` dies with ZERO replacement plumbing**: the armed spec
      rides the `layoutSpec:` add-arg to the island exactly as today, and the knob never
      leaves its owner — the island's slot and the content's field share ONE object
      while wrapped, which E1-M4 proves both graph engines handle (identity-mapped,
      round-trips as shared). Requires E5's slot-first reads in the SAME batch (a
      field-read on the island is the founding bug the hand-carry papered over).
    - **The stretch contention never arises**: a follower record (slot) and a
      preference knob (field) were never competing for the same home — the round-1
      contention was an artifact of trying to slot-home kept memory.
    - Every measured E1-M1 flow is preserved BY CONSTRUCTION, not by compatibility
      code: the ⚖⚖ survival law is product doctrine, and "preferences are whole-life
      knobs" is its natural implementation.
    - (A) stays REJECTED. What remains of the "shadow tier" after the fold: the
      same-widget double-reference while armed (slot == field) — which is not residue
      but the family's sanctioned knob idiom, now uniform across all three knobs
      (corner, division, content-stack).
    - **E1-M1 (runtime probe, 19/19 checks green on `0293fb64`).** The plan's named pair
      (division knob × stack spec) IS real and IS preserved today: a cell whose box was
      tuned through the divider's write path (`setMaxDim` → `maxWidth` 199) carried that
      SAME box object through a document-stack sojourn (adoption planted + armed a stack
      spec beside it) and re-armed it intact on return (probe A1–A7); the alignment-edited
      stack spec survived the division sojourn in the kept field and re-armed with the
      edit on stack re-entry. BUT no test and no src builder ever exercises the pair
      (tests repo: ZERO refs to either field; the ~10 division tests never touch a
      stack/window on the same widget) — it is reachable-but-unpinned. The pair that IS
      load-bearing and COMMON is **stretch × dormant stack spec** (probe B1–B4): every
      desktop sojourn of an ex-stack element arms a `StretchLayoutSpec` in the slot while
      the kept spec rides the field dormant, and the ⚖⚖ survival-law round-trip (document
      → desktop → document, alignment edit intact, SAME object re-armed) depends on both
      existing at once. **One slot cannot hold the armed follower record AND the dormant
      kept memory — pure (C) is falsified by measurement.** Under the knob model the
      contention dissolves (record in the slot, knob in its field) and all 19 checks are
      preserved by construction. The island carriage was also measured (probe C1–C4,
      D1–D4): the ACTIVE spec rides `_addNoSettle`'s `layoutSpec:` arg while the kept
      field rides `_moveKeptStackSpecTo` — under the knob model only the FIRST carriage
      remains (the knob stays on the content; the island answers reads from its slot,
      E5).
    - **E1-M2 (the categorized census — 102 refs / 24 src files / 0 tests-repo refs,
      re-verified at `0293fb64`; sums to 102):**
      | class | refs | sites | fate |
      |---|---|---|---|
      | W1 Widget base pair + declaration | 6 | `Widget:302` decl; `:337/:341` frame-content init; `:346/:350/:352` stack init | mechanism-untouched (the field IS the knob's home); P2 rename only |
      | W2 the island hand-carry | 2 | `Widget:1648/:1649` | DELETED in P1 (E4, same batch as the E5 re-route) |
      | W3 leaf default-knob constructors | 20 | 14 classes: PaletteWdgt:29 · SimpleTextScrollPanelWdgt:66 · FrameContentsPlaceholderText:14 · MenuWdgt:105-106 · SliderWdgt:79-80,110-111 · IconWdgt:22,26 · SimpleTextWdgt:59 · GenericCompositeIconWdgt:33 · AnalogClockWdgt:35,44 · WidgetHolderWithCaptionWdgt:76 · TextWdgt:323 · SimpleVerticalStackPanelWdgt:147 · FrameWdgt:988 · **BinWdgt:26 (ctor-time — a knob planted at birth, before any attachment: the knob concept is already latent in src)** | mechanism-untouched (E6); P2 rename only |
      | W4 adoption/arming writers | 11 | stack adoption SVSP:271-273 (3) · FrameWdgt mount :601/:604/:611/:612 (4) · arrange re-arm :1007 (1) · ctor veteran un-latch :263/:273 (2) · capture :1034 (1) | ALREADY the arming idiom — mechanism-untouched; P2 rename only |
      | W5 container-side measure/negotiation readers | 18 | FrameWdgt :151/:180/:189/:205/:451/:555/:787/:1013/:1017/:1038/:1040/:1044/:1051 (13) · SVSP :170/:173/:175 (3) · StretchableWidgetContainerWdgt :159/:180 (2) | P1: re-route through E5's slot-first accessor (the ONE mechanism change) |
      | W6 post-init knob toggles | 17 | KeepsRatioWhenInVerticalStackMixin :46-47/:62-63 (4) · StretchableWidgetContainerWdgt :56-57/:62/:94-95/:102-103/:167-168 (9) · Example3DPlotWdgt :88/:90/:108-109 (4) | field writes are CORRECT (the field is the home) — mechanism-untouched; P2 rename only |
      | W7 builder knob edits via the spec's public setters | 25 | InfoDocs (12) · WelcomeMessageInfoWdgt (6) · HowToSaveMessageApp (3) · TemplatesWindowWdgt (3) · SimpleDocumentScrollPanelWdgt:53 (1) | mechanism-untouched; P2 rename only |
      | W8 comments/doc refs | 3 | LayoutSpec:30 · SimpleTextWdgt:17 · InfoDocs:156 (commented-out) | P3 doc sweep |
    - **E1-M3 (the FrameWdgt dormant-slot spike — executed, presuite-verified, REVERTED).**
      Minimal 4-file spike: `armed: true` prototype default + `ownsPlacement -> @armed` on
      the base; armed-gated `isStackElementActive`/`isFrameContentActive`; `_setLayoutSpec`
      re-shaped (nil = "no active attachment, kept occupant disarms and STAYS"; setting
      arms; identity guard compares armed-ness so a same-object re-arm does not
      early-return). Mechanics probe 11/11 green: grab-disarm-keep leaves the SAME object
      in the slot disarmed; dormant ⇒ `isFreeFloating()` true; dormant role queries answer
      false (the menu gate / adoption guard / arrange guard are all capability-dispatched,
      so the dormant population is invisible to them BY CONSTRUCTION); re-adoption re-arms
      the SAME object through the fixed guard; the window mount cycle re-latches U2
      correctly (desiredWidth re-captured 120 → 290 across a cross-window remount).
      **Full `fg presuite` on the spike build: 281/281 PASS, 0 geometry violations, paint
      audit 0 offenders — the dormant-slot mechanics are SUITE-INVISIBLE (byte-identical),
      including every window-sizing and hug negotiation** (§7's relocate-not-change
      constraint measured, not assumed). VERDICT under the final package: the spike's
      mechanics belong to the superseded round-1 shape (no armed flag ships), but its
      evidence stands — the mount path tolerates state relocation byte-identically, and
      the capability-dispatch surfaces (menu gate / adoption guard / arrange guard) are
      the complete behavioral seam list for anything touching this path.
    - **E1-M4 (the cross-widget sharing probe — the round-2 measurement that decided the
      final shape; `Fizzygum-tests/.scratch/kept-spec-sharing-probe.js`, 11/11 green on
      `0293fb64`, ZERO src changes — in-page synthesis only).** Both graph engines
      identity-map EVERY object: the Duplicator's `clonesByOriginal` ("the one place
      cycle/sharing bookkeeping lives") and the Serializer's `slotOf` table ("identity;
      cycle/sharing safe" — the reference doc states shared substructure round-trips as
      shared). Proven live: (A) today's same-widget sharing (stack element, slot==field)
      fullCopies to ONE new shared object, independent of the original, edits intact;
      (B) same for an armed division cell (maxWidth 177 preserved); (C) the SYNTHESIZED
      knob-model island shape — one spec object referenced from TWO widgets
      (content.field === island.slot === island.field) — fullCopies to ONE new object
      shared identically across all three refs; (D) a whole-world snapshot round-trip
      with that shape live restores it as ONE shared object with values intact.
      **The hand-carry's single-owner MOVE rationale is vestigial: the hazard it guards
      against does not exist in the modern engines.**
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

    ⇒ **DISSOLVED by the knob model — no dormancy state ships.** Armed-ness stays what
    it is today: STRUCTURAL (the slot references the knob object while attached; the
    slot is nil — or a follower — otherwise). A round-1 decision here chose an `armed`
    flag + gated role queries + arm/disarm plumbing (spike-proven viable, E1-M3); the
    owner's clean/uniform criterion rejected the whole state machine as machinery whose
    only purpose was letting kept memory live in the slot — which the knob model makes
    unnecessary. What SURVIVES from this item's analysis: the capability-dispatch
    inventory (adoption guard `SVSP:267`, arrange guard `FrameWdgt:1005`, spec-menu gate
    `Widget:4219-4238`) — the complete seam list any future lifecycle change must
    re-audit — and the confirmation that `isFreeFloating`, the role queries, and the
    handle-visibility tail need NO change at all under the final shape.
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

    ⇒ **DISSOLVED by the knob model — grab/reparent semantics are UNTOUCHED.**
    `_beforeBeingGrabbed` keeps nilling the slot; `_addNoSettle`'s resolution keeps
    today's spelling; the knob fields survive detachment exactly as `_divisionBox` and
    `cornerSpec` do today — that IS the keep policy, expressed structurally
    (field-homed = kept; slot-only = per-attachment) instead of by a
    `keptAcrossDetachment()` declaration, which is therefore not needed. The
    nil-sentinel ⚠ dissolves with it: nil-vs-absent both leave the knobs untouched, as
    today. A round-1 decision here introduced disarm-keep semantics plus a PARKING rule
    (`parkedKeptSpec` on the displacing spec) to preserve the E1-M1 flows under
    slot-homed memory — REJECTED by the owner's criterion as pure
    behavior-preservation machinery and moved to §7 with its analysis; the rejected-
    alternatives analysis (skip-stretch-for-dormant-carriers = ghost-principle smell;
    second Widget field = shadow tier + hand-carry survives; follower-inversion =
    indirection at every stretch site) carries over as §7 case law.
    **Conscious behavior change: NONE anywhere** — all 19 E1-M1 probe checks are
    preserved by construction because nothing about attachment lifecycle changes at all.
E4. **The island hand-carry dies — verify, don't assume.** Under (C)/(D) the spec object
    rides `_addNoSettle`'s `layoutSpec:` arg on materialize/dematerialize exactly as the
    active spec does today, so `_moveKeptStackSpecTo` is DELETED. MUST verify in the spike:
    the content INSIDE the island must not read as stack-active (its spec is on the island —
    single object, single carrier; check `_childWidthInStack`'s proportional tracking against
    the historical failure the hand-carry's comment documents), and fullCopy of a wrapped
    figure must not double-reference (the single-owner rule the MOVE existed for — under one
    slot this holds by construction, but PROVE it with the duplication rig/test).

    ⇒ **DECIDED: `_moveKeptStackSpecTo` is DELETED with ZERO replacement plumbing — the
    knob never leaves its owner.** The island wrap keeps doing exactly what it does
    today for the ACTIVE spec (the `layoutSpec:` add-arg, `Widget:1676/:1692`); the
    kept knob simply STAYS in the content's field. While wrapped, one spec object is
    referenced from two widgets (content's field + island's slot) — MEASURED SAFE in
    both graph engines (E1-M4: identity-mapped, fullCopy and snapshot round-trip
    preserve the sharing; the single-owner MOVE rationale is vestigial). Sharing is
    also the CORRECT semantics: a knob edit made through the island's menu while
    wrapped hits the one object the content resumes on unwrap.
    - ⚠⚠ The deletion MUST land in the SAME batch as E5's slot-first re-route: with the
      hand-carry gone, a field-read on the island answers nil and
      `_childWidthInStack` falls back to raw available width — the exact founding
      failure the hand-carry's comment documents. Slot-first reads close it structurally
      (the island's slot HAS the armed spec, riding the arg).
    - P1 acceptance: the coexistence probe's C/D sections re-run green (island
      materialize/dematerialize round-trips, both populations), plus the sharing probe's
      C/D sections (fullCopy + snapshot round-trip of a wrapped figure).
E5. **FrameWdgt's 14 direct kept reads become tier-honest.** Measure/negotiation reads
    (`getWidthInStack`, `canSetHeightFreely`, `desiredWidth`, the :787 chrome math, :555
    early-settle predicate) read the child's spec through ONE accessor that answers for
    armed-or-dormant (they are questions about the child's PREFERENCES, valid in both
    states); the mount path (~:601-612) becomes the arming idiom. ⚠ The U2 pre-capture
    fallback must survive: `.element` binds at initialisation, before the first arrange.
    ⚠⚠ Do NOT touch the hug/grow semantics while re-plumbing — hug-suppression is falsified
    ×3 (sizing-model arc); this arc changes WHERE state lives, never WHAT the negotiation
    answers.

    ⇒ **DECIDED: ONE accessor, SLOT-FIRST — `contentStackSpec()`, mirroring the existing
    `_divisionBox`/`divisionBox()` field/method pair:** answer the slot occupant if it
    `isContentStackCapable?()`, else the knob field, else nil.
    - Slot-first is REQUIRED, not style: while attached, slot and field are the same
      object (either order works); on the ISLAND only the slot has the spec — field-first
      re-opens the founding bug the hand-carry papered over (E4 ⚠⚠). This is also the
      tier-honest direction: ask the current attachment first.
    - Consumers re-routed in P1: exactly the census's W5 reads (FrameWdgt ×13 — including
      the :555 early-settle predicate, the :787 float chrome math and the ctor veteran
      un-latch at :263/:273, which probe a widget whose CURRENT attachment may be an
      island or a dead window — the stack's `_childWidthInStack`/`_childLeftInStack` trio,
      StretchableWidgetContainerWdgt ×2). W6 toggles and W7 builder edits keep writing
      the FIELD — it is the knob's home and always current (same object while armed).
      The `?.`-guard shape of today's reads carries over verbatim — a never-adopted child
      answers nil exactly as today, so the measures stay TOTAL.
    - The mount path (W4) is ALREADY the arming idiom and is untouched; the U2 latch
      mechanics are untouched — and were spike-proven tolerant end-to-end regardless
      (capture latched 120, cross-window remount re-latched 290, E1-M3).
    - The hug/grow constraint (§7) binds P1's re-route: the accessor answers the SAME
      object today's field-read answers at every existing site, so the negotiation's
      inputs are unchanged by construction; the E1-M3 presuite already measured the
      whole window-sizing family byte-identical under a strictly larger perturbation.
E6. **The ~20 leaf-class initialiser overrides stay.** They are per-class constructors of the
    child's own default preferences — reshaping them is churn without elimination (the
    mandate targets the shadow-field mechanism, not the knob declarations). Only their BASE
    pair in Widget changes (writing the slot instead of the shadow field).

    ⇒ **CONFIRMED — and under the knob model they are MECHANISM-UNTOUCHED: 14 classes /
    20 refs (the E1-M2 W3 row is the authoritative list), changed only by P2's rename.**
    Two shapes exist and both survive as-is: super-then-tweak-knobs (IconWdgt,
    AnalogClockWdgt, …) and replace-the-whole-object (PaletteWdgt, MenuWdgt, SliderWdgt,
    …) — the field they write IS the knob's home. BinWdgt's ctor-time plant is already
    the knob model in miniature: a preference object planted at birth, before any
    attachment exists.
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

    ⇒ **REVISED under the knob model — the serialization story is UNCHANGED FROM TODAY
    in P1, and only the RENAME (P2) touches snapshot shape.** Verified: none of
    `layoutSpec` / `_stackElementSpec` / `_divisionBox` is in
    `Widget.serializationTransients`; all serialize through the generic
    constructor-name walk (stretch-arc D5 precedent), and E1-M4's section D proves the
    wrapped-figure sharing shape round-trips as ONE object. NO migration/compat code
    (standing rule): after P2, snapshots carry `_contentStackSpec` and old snapshots
    are stale.
    - Expected churn, refined by measurement: **P1 (mechanism) — near-zero pixels.**
      The E1-M3 presuite showed byte-identical under a strictly larger perturbation;
      P1's only prototype-member deltas are `_moveKeptStackSpecTo` deleted +
      `contentStackSpec` added on Widget — the stretch arc's P2 precedent (ONE
      members-list inspector test churned for exactly this class of change).
      **P2 (rename) — the benign inspector own-prop wave** (`_stackElementSpec` rows
      become `_contentStackSpec` rows across every inspector-showing test), diffpage +
      eyeball + gated `fg recapture`, pre-sanctioned. The pixel oracles that must stay
      byte-green throughout are unchanged from the original list above, and under the
      knob model the stretch trio + division family are structurally untouched (any
      churn there is a regression, full stop).
    - Both serialization rigs + `fg homepage`'s production snapshot round-trip run at
      P1, P2 and P3 per §6 (P2 changes the serialized field name — the rigs and the
      production round-trip are what prove the rename is complete).

## §5 Phases (post-approval)

P0 — DONE (two rounds, 2026-08-06): the measurements (E1-M1..M4) + the §4 decisions +
     the FrameWdgt spike (reverted); owner ratified the knob-model direction same day.
     Execution start still awaits the owner's explicit word.
P1 — the mechanism, ONE batch (E4 ⚠⚠ binds them together): the `contentStackSpec()`
     slot-first accessor on Widget + re-route exactly the 18 W5 reads through it +
     DELETE `_moveKeptStackSpecTo` and its two call lines (`Widget:1675/:1691`) + the
     hand-carry comment block's WHY moves onto the accessor (slot-first is what closes
     the founding `_childWidthInStack` fallback bug). Nothing else changes — no
     lifecycle, no initialisers, no adoption/mount, no `_setLayoutSpec`. Acceptance:
     BOTH P0 probes re-run green (19/19 + 11/11 — the island C/D sections are the
     hand-carry's replacement oracle), `fg presuite`, both serialization rigs +
     `fg homepage`, `fg revisits` (read-path re-route must not shift settle cadence).
P2 — the rename, mechanical: `_stackElementSpec` → `_contentStackSpec` across the ~99
     non-comment refs / 24 files (the census is the checklist; the accessor's name
     already matches). Expect E7's benign inspector own-prop wave — `fg diffpage` +
     eyeball + gated `fg recapture`; rigs + `fg homepage` re-run (the serialized field
     name changes; old snapshots stale per the standing rule).
P3 — tests + docs + close: ADD the lifecycle test in the detach/re-add value-assert
     style (`macroStretchChildDetachReaddKeepsProportions` is the template): stack
     element with an explicit alignment edit → detach → DESKTOP sojourn (the measured
     flagship flow — a stretch record arms and the knob coexists) → re-add → the SAME
     spec object re-arms with the edit intact (the ⚖⚖ survival law asserted on object
     identity + knob value, proven non-vacuous by a plant AND a flipped assert); update
     `docs/architecture/layout.md` §4.2 (the two-kind lifecycle taxonomy — carrier-owned
     KNOB vs per-attachment RECORD — replacing the three per-class prose stories, and
     the kept-slot mentions) and `LayoutSpec.coffee`'s header; sweep the W8 comment refs
     + any transforms-doc mention of the hand-carry; BACKLOG line closed; archive +
     INDEX + memory; end-of-arc review; commits presented.

## §6 Verification protocol

`fg presuite` per batch; `fg gauntlet` at P1/P2/P3 closes; `fg census` free anytime (the
arrange-idempotence oracle — but note it cannot see lifecycle state, only geometry); BOTH
serialization rigs + `fg homepage` on P1, P2 AND P3 (P1 makes a wrapped figure's spec
shared cross-widget in snapshots — E1-M4's proven-safe shape; P2 renames the serialized
field); `fg revisits` at P1 (the read re-route must not shift settle cadence). The two P0
probes are standing acceptance oracles for P1 (they pin the island round-trips and every
coexistence flow). Expected churn ZERO except E7's two benign classes — each recapture
preceded by `fg diffpage` + eyeball + a ledger note. New/changed tests captured at dpr
1+2 and proven non-vacuous (plant, watch it fail, restore — both a value plant and a
flipped assert, the stretch-arc template).

## §7 Rejected / do-not-re-attempt

- **A veneer over kept fields** (accessors wrapping `_stackElementSpec` in place while the
  hand-carry, the bypass reads and the false "kept spec awaiting re-arming" story all
  survive) — burying, not eliminating; the same filter that shaped the stretch arc. NB the
  DECIDED knob model is not this: it deletes the hand-carry, makes every container read
  tier-honest (slot-first), and re-classifies the field into the family's sanctioned
  carrier-owned-knob idiom — the accessor is the tier-honest read, not a wrapper hiding
  the old mechanism.
- **The slot-with-dormancy package (P0 round 1: `armed` flag + dormant state + the
  `parkedKeptSpec` parking rule)** — REJECTED on the owner's clean/uniform/no-backcompat
  criterion (2026-08-06), despite being spike-proven suite-invisible (E1-M3). Three new
  lifecycle concepts whose only purpose was letting kept memory live in the slot; the
  parking rule in particular was pure behavior-preservation machinery for a contention
  (armed follower vs dormant memory, E1-M1 probe B) that the knob model makes
  unrepresentable. Do not re-attempt slot-homed kept memory without new evidence that
  the knob model failed. The round-1 alternatives analysis carries over as case law:
  skip-the-stretch-record for memory carriers = desktop tracking dependent on widget
  HISTORY (ghost-principle smell) and forks `consumesFractionalGeometryOf`; a second
  Widget field for dormant memory = the shadow tier reborn + the hand-carry survives;
  the follower-inversion (dormant owner in the slot, stretch record hanging off it) =
  indirection at every stretch consumer site.
- **Pure supersession** (a new arming simply discards kept memory, no knob field) —
  violates the ⚖⚖ survival law (owner doctrine, layout-spec-family arc) and makes the
  outcome depend on the route: a hand-held round-trip would keep edits while a
  desktop-parked round-trip lost them — the exact inconsistency a uniform model exists
  to prevent.
- **Deriving armed-ness at read time** (parent-pointer consistency checks) — the family rule
  is synchronously-maintained fields, never read-back derivation. (Same filter rejects
  island READ-DELEGATION — "the island answers kept-spec queries from its content" — the
  knob model instead keeps the armed spec ON the island via the add-arg, as today.)
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

#### P0 — measurements + design note, 2026-08-06; OWNER REVIEW PENDING (no production code)
- At Fizzygum `0293fb64` / tests `fce35ef3f` (281 tests; morning gauntlet 14/14 green).
  §0.5 protocol followed in full (plan, layout.md §§3-4, the archived stretch plan §4+§8
  + INDEX entry, all listed src regions).
- **E1-M1** (`Fizzygum-tests/.scratch/kept-spec-coexistence-probe.js`, 19/19 green):
  division×stack coexistence real + preserved today but UNPINNED by any test/builder;
  the LOAD-BEARING pair is **stretch×dormant-stack** (every desktop sojourn of an
  ex-stack element) — **pure shape (C) falsified by measurement**; both island carriages
  (arg + hand-carry) measured.
- **E1-M2**: the 102-ref census categorized into 8 classes (W1-W8, table in E1), sums
  exactly; tests repo confirmed ZERO refs; `_divisionBox` 22 refs / 4 files confirmed;
  BinWdgt's ctor-time dormant-from-birth plant flagged as latent-dormancy evidence.
- **E1-M3**: minimal 4-file spike (armed default-true + gated role queries + re-shaped
  `_setLayoutSpec`) — mechanics probe 11/11
  (`.scratch/kept-spec-spike-rearm-probe.js`: disarm-keep, dormant-is-free, dormant role
  queries false, same-object re-arm, mount-cycle U2 re-latch), then **full presuite
  PASS: 281/281, 0 geometry violations, paint 0 offenders — suite-invisible**. Spike
  REVERTED (git checkout of the 4 files, verified clean, tree rebuilt); probes kept in
  `.scratch/`.
- All seven §4 decisions filled in as one package: E1 (D)+(C)+parking / E2 armed flag,
  resting default false, role queries gated / E3 disarm-keep + explicit arming sites +
  **the parking rule (the one NEW mechanism — flagged for owner ratification)** / E4
  hand-carry DELETED via as-is arg carriage / E5 the one accessor / E6 census-confirmed
  / E7 serialization + churn refined (all churn concentrates in P1's deletion wave).
- Conscious behavior changes: NONE for any measured flow (all 19 probe checks preserved
  by construction; the probes become P1's acceptance oracle).
- STOPPED at the §4 owner gate per §0.5; P1-P3 untouched.

#### P0-b — owner direction review + the package re-decided, 2026-08-06 (same session)
- Owner direction question: "on the basis of wanting clean and uniform code/flow,
  unencumbered by legacy code, vestigial cruft and backward compatibility, what's the
  path forward?" — which exposed the round-1 package's parking rule as
  behavior-preservation machinery (its ONLY purpose was surviving a contention created
  by slot-homing kept memory).
- **E1-M4 executed** (`.scratch/kept-spec-sharing-probe.js`, 11/11 green, zero src
  changes): both graph engines identity-map every object — the Duplicator's
  `clonesByOriginal` and the Serializer's `slotOf` table; the synthesized knob-model
  island shape (one spec object referenced from two widgets) fullCopies AND
  snapshot-round-trips as one shared object with values intact. The hand-carry's
  single-owner MOVE rationale is vestigial — the last argument for slot-homed memory
  fell.
- §4 REWRITTEN to the **knob model**: E1 = (D) generalized to both kept tiers
  (attachment ≠ preferences; slot = current attachment, today's semantics untouched;
  `_stackElementSpec` re-classified as the third carrier-owned knob, renamed
  `_contentStackSpec` in P2); E2/E3 DISSOLVED (no armed flag, no dormancy, no parking —
  their seam inventories kept as case law); E4 = hand-carry deleted with zero
  replacement plumbing (E1-M4); E5 = the slot-first accessor, same batch as the
  deletion (⚠⚠ field-first re-opens the founding bug); E6 = leaf initialisers now fully
  mechanism-untouched; E7 = serialization unchanged until the P2 rename. §0 reframe
  stamped with its P0 verdict (the diagnosis overreached — the decided frame is the
  opposite one); §5 phases recut (P1 mechanism / P2 rename / P3 test+docs+close); §7
  gained the round-1 package + pure-supersession + island-delegation rejections.
- Owner RATIFIED the direction same day ("update the plan"). Execution start (P1) still
  awaits the owner's explicit word per §0.5.

#### P1 — the mechanism batch, executed 2026-08-06 (owner go: "start"; ALL GATES GREEN)
- Landed in ONE batch per E4 ⚠⚠: `Widget.contentStackSpec()` (slot-first accessor, doctrine
  comment carries the retired hand-carry's WHY) + the read re-route + `_moveKeptStackSpecTo`
  DELETED with both call lines (`Widget:1675/:1691`). Census fate CORRECTION found while
  executing: the two `StretchableWidgetContainerWdgt` W5 rows (:159/:180) are SELF-reads of
  the widget's own knob — the field is the home there, so they correctly stay field-based;
  the true re-route set is 16 (FrameWdgt ×13 + the stack's `_childWidthInStack`/
  `_childLeftInStack` trio).
- Probes re-run green with the knob-model contract asserted: coexistence 19/19 (island
  sections now pin: knob STAYS on the content, the spec rides the island's SLOT, the
  accessor finds it) and sharing 11/11 (the cross-widget island shape is now the NATURAL
  state — C0's synthesis line removed — and fullCopies + snapshot-round-trips as one
  shared object).
- ⚠⚠ FOUND + FIXED (owner-directed mid-run): the ONE presuite failure was the E7-predicted
  test (`macroDuplicatedInspectorDrivesCopiedTargetOnly`) but the mechanism was subtler
  than pixel churn — the member shift (`_moveKeptStackSpecTo` sorts before `alpha`,
  `contentStackSpec` after: alpha's index −1) exposed a HARNESS ROBUSTNESS BUG: the
  toolkit's scroll verb drags the scrollbar handle, quantized to scrollbar pixels, so the
  alpha row landed EDGE-CLIPPED at the pane top; the test's fixed-offset click
  (`row.topLeft + 2px`) hit the clipped sliver, selected nothing, and the save no-opped —
  neither rectangle faded. FIX per owner direction ("fix the way the transparency field is
  found/set; the rects area must be equal to the original"): the click Y is CLAMPED into
  the pane's visible box — in the test's local subroutine AND the toolkit's generic
  `clickOnListItemFromTopInspector_InputEvents` — byte-identical whenever the row is fully
  visible (zero delta for every passing test). Verified before recapture: image_1 PASS,
  the img2/img3 deltas confined to the member-list rows (dpr1 rows 289-385), the RECT
  areas byte-equal to the original references (the owner's acceptance).
- Gates: `fg recapture SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly` ✅
  COMPLETE (2 images × dpr1+2 recaptured; full suite GREEN at both densities — exactly the
  E7-predicted ONE-test inspector wave, nothing else churned); `fg gauntlet` **14/14
  GREEN, 264s, no serial retries** (dpr1 112s / dpr2 117s / webkit 130s / apps 90s /
  parts 46s / paint 99s / tiernaming 118s / settle 118s / capstone 118s / refs 28s /
  revisits 118s — settle cadence UNCHANGED by the re-route / census 8s / serialization
  55s — both rigs with the island sharing shape live / storage 118s); `fg homepage` OK
  (production pre-compiled tree boots + whole-world snapshot round-trip clean).

#### P2 — the rename, executed 2026-08-06 (ALL GATES GREEN; churn = ZERO, beating E7's prediction)
- `_stackElementSpec` → `_contentStackSpec`: mechanical token sweep, 24 files / 85 refs
  (= 102 − 16 re-routed − 2 deleted + 1 accessor). Corruption gate: in the 21 files P1
  had not touched, the diff contains ZERO non-token lines; old-name refs 0, new-name 85.
- Gates: presuite **281/281 PASS, zero failures** — the E7-predicted inspector own-prop
  wave did NOT materialize: the rename is length-neutral (17→17 chars) and no captured
  inspector window displays the `_`-prefixed own-prop block, so the row rename and its
  re-sort are outside every reference crop. BOTH serialization rigs OK (59 + 7 checks —
  snapshots now carry `_contentStackSpec`; old snapshots stale per the standing no-compat
  rule); `fg homepage` OK (production tree + snapshot round-trip on the renamed field).

#### P3 — lifecycle test + docs + close, executed 2026-08-06
- NEW TEST `macroContentStackKnobSurvivesDetachReadd` (suite 281 → 282; 3 images,
  dpr 1+2): nine in-macro value asserts pin the knob lifecycle end-to-end — adoption arms
  the knob (slot == field, stack-active) → alignment edited to center via the spec's own
  public setter → detach nils the slot synchronously → the DESKTOP sojourn arms a stretch
  RECORD in the slot while the knob rides its field with the edit intact (the P0-measured
  flagship coexistence flow) → re-add re-arms the SAME OBJECT (identity assert), edit
  intact — then image_2 proves the surviving edit drives the arrange, and is
  BYTE-IDENTICAL to image_0 (same dataHash: the round trip restores the exact
  arrangement). Proven NON-VACUOUS twice: a planted `setAlignmentToLeft()` before the
  final screenshot fails image_2; a flipped identity-assert expectation fails at the
  assert.
- Docs: `docs/architecture/layout.md` §4.2 — the two-kind LIFECYCLE taxonomy paragraph
  (knob vs record, the slot-first accessor doctrine, the island sharing contract)
  replaces the per-class prose; the VSLS lifecycle entry re-written knob-first; the
  stretch entry's "kept slot" wording updated. `LayoutSpec.coffee` header — the LIFECYCLE
  bullet rewritten to the two-kind statement. `docs/BACKLOG.md` D3 line CLOSED (the D10
  desktop corner-spec follow-on line stays open, untouched by this arc).
  `transforms.md`'s "hand-carry" mention verified UNRELATED (the pinned-anchor pipeline).
- Census fate note for the record: W7's 25 builder knob edits and W6's toggles were
  field-direct all along and stayed so — under the knob model the field IS the home, so
  only reads that must see an island's riding spec route through the accessor.

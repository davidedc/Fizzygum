> **ARCHIVED — COMPLETE (2026-07-17 restructure).** Closed + pushed 2026-07-17; gauntlet 11/11 green. ONE open item = owner G2 halo feel-check, post-push.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# claimsSpace: footprint-by-default + scroll reachability — plan (authored 2026-07-17)

Self-contained, cold-startable. Everything an executor needs is embedded; file:line anchors were
verified 2026-07-17 @ `61080871` — **re-grep symbols at arc start, lines drift**. Companion design
history: `docs/plans/affine-transforms-plan.md` (esp. §4.9 mode table :537, §4.10 serialization :577,
§4.11 two faces :587, the Phase 3 execution log :930). Conventions that bind this arc:
capability-first dispatch (`docs/archive/type-test-elimination-plan.md`, campaign complete — new queries are
per-class `?()` capabilities, never type tests), integer placement law
(`docs/architecture/integer-pixel-placement-and-sizing.md`), the two-vocabulary law
(`docs/archive/affine-geometry-api-plan.md`).

## 1. The owner decisions this arc implements (2026-07-17, recorded verbatim in intent)

- **D1 — `'footprint'` becomes the DEFAULT `claimsSpace`.** Rationale: defaults must serve the
  document author, not the widget-class author. Documents are stacks; a rotated image in a document
  overlapping the text below it is end-user-visible weirdness with no discoverable cause. The tax
  moves to expert authors: a spinner class that must not churn layout sets `'sweep'` (or `'slot'`)
  itself — "people who need the other settings have to know enough to set them". The owner accepted
  the implication map with eyes open: rotation inside tracking containers becomes a live layout
  event (halo drags reflow siblings per move — see the S3 feel-check gate), animations need a
  hand-set mode, and the Phase 3 "firewall" promise (default rotation is layout-inert) inverts into
  an opt-in.
- **D2 — scroll extent tracks reachability in ALL modes, including `'slot'`.** Principle: sibling
  layout and scrolling answer different questions. Layout is a negotiation between siblings ("how
  much space do you take from the others?" — `'slot'` answers "none"). Scrolling is reachability of
  ink ("can the user bring every painted pixel into view?") — ink that can never be scrolled to is
  lost content. CSS draws exactly this line (transforms never move siblings, yet scrollable
  overflow includes the transformed box). **The rule: a widget's contribution to a scroll panel's
  content extent = its claimed box ∪ its visible ink footprint.** Mode-by-mode this does the right
  thing: `'slot'` → ink wins → scrollbars appear as soon as anything pokes out; `'footprint'` →
  claim IS the ink AABB; `'sweep'` → the swept square ⊇ ink at every angle → scroll extent is
  SPIN-STABLE (no scrollbar flicker), which is sweep's whole promise. Accepted artifact: a `'slot'`
  widget spinning near a scroll edge pulses the extent with the angle (browsers behave the same;
  the cure is `'sweep'`).
- **D3 — unchanged: "shrink-to-fit" stays FORBIDDEN** (affine plan §4.9 :547 — the cyclic
  constraint / LivelyKernel breakage; never derive the untransformed extent from a transformed
  constraint).
- **Considered and superseded**: CSS-like-scroll WITHOUT the default flip (was "piece (b)"; D1+D2
  subsume it); keeping `'slot'` default with footprint as opt-in (rejected — the mainstream case
  must be correct without a hand-set line).

## 2. The observed defect that started this (keep as the acceptance picture)

Owner report + screenshot (basement window, 2026-07-17): a tilted island (folder window) inside the
basement's scroll panel pokes out of the viewport with NO vertical scrollbar; only when dragged far
enough do scrollbars appear. Diagnosis (verified in source): the basement is the scroll panel's
NON-content-sizing branch — `ScrollPanelWdgt._positionAndResizeChildren`'s else-arm reads
`subBounds = @contents.subWidgetsMergedFullBounds()?.ceil()` — and that walk
(`Widget.coffee:1149`) merges each child's `fullBounds()`. A `TransformFrameWdgt` island does NOT
override `fullBounds` (it is a clipping panel; own comment at `TransformFrameWdgt.coffee:26`), so
it contributes its **untransformed slot box**; the rotated overhang is §4.11 "ink overflow" —
painted, damage-tracked, hit-testable, claiming no space. Scrollbars therefore key off the SLOT box
crossing the viewport (at 45° the corners overhang ~20% of the side before that happens). D2 makes
this reachable-by-scrolling in every mode.

## 3. Verified current-state census (2026-07-17 @ `61080871`)

- `src/TransformSpec.coffee` — `:35` prototype `claimsSpace: "slot"`; `:37` constructor
  `(@rotationDegrees = 0, @scale = 1, @anchor = nil, @claimsSpace = "slot")`. Machinery already
  present (Phase 3, commits FZ `707f9720` / tests `0d720b550`, both ON ORIGIN): `_claimedBoxFor` /
  `claimedExtentFor` (slot box | corner-mapped integer AABB | anchor-aware circumscribed square),
  `slotOffsetWithinClaim` (translation-invariant claim placement), `_sweepSquareFor`
  (radius = max scaled corner distance from the anchor; deterministic).
- `src/TransformFrameWdgt.coffee` — `setClaimsSpace :183` (self-settling; reflows once on mode
  change); `_reflowIfClaimChangedNoSettle :248` (reflow ONLY when the claimed extent changed — so
  footprint reflows on angle/scale, sweep on scale/extent but NOT rotation, slot never);
  `preferredExtentForWidth :266` reports the claimed extent (this is what STACKS consult — the
  measure path); `_applyExtentBase` no-op (`@bounds` stays the SLOT box — the two-vocabulary law);
  `_applyMoveToBase` offsets by `slotOffsetWithinClaim`; `clippedThroughBounds :660` = the §4.11
  OUTER face (mapped screen footprint ∩ ancestor clips) with its SLOW twin at `:678`; `fullBounds`
  NOT overridden (⇒ slot box; this is why the scroll walk misses the ink); `:76` — deserialization
  already skips a stale `_lastClaimedExtent` (derived, not truth).
- `src/basic-widgets/Widget.coffee:1149` `subWidgetsMergedFullBounds` — THE ONE NAMED STATE-READ
  (D4 / sizing-unification U3-A; the comment block :1140-1148 says "single consumer:
  ScrollPanelWdgt's non-content-sizing branch" and carries a lint note that any new caller must
  justify itself) — seeds `@children[0].bounds`, merges `child.fullBounds()` for non-inert
  non-deferred children, `child.bounds` for deferred-layout children.
- `src/basic-widgets/ScrollPanelWdgt.coffee` — the consumer (else-arm of
  `_positionAndResizeChildren`, post-ε ~:457-459) + the merge-commit
  `newBounds = subBounds.expandBy(padding).merge @boundingBox()?.ceil()`; scrollbar visibility
  derives from contents frame vs viewport (`_reLayoutScrollbars`).
- Serialization: affine plan §4.10 — TransformSpec serializes the SCALARS incl. `claimsSpace`; it
  is a constructor-assigned own property and the Serializer stores own enumerables
  (`Serializer.coffee:251` `for own name of obj`) ⇒ **old documents carry an explicit `"slot"` and
  are unaffected by a default flip**. MUST-VERIFY at V0 (see gates) — do not take this on faith.
- Tests: suite = 250. Phase 3 macros: `macroTransformFrameFootprintReflow` (the FIREWALL — asserts
  the OLD default: rotating a 'slot' plot in a stack does NOT move the footer below — plus the
  explicit-footprint coupling + the 90° integer transpose) and `macroTransformFrameSweepReserve`
  ('sweep' reserves once; spinning to 40°/80° does not reflow). Both live in `Fizzygum-tests`.
- Dormancy guarantee to preserve: an IDENTITY island's claimed box == slot box in every mode ⇒ the
  default flip is a no-op for everything untransformed. The identity-bypass gate (islands fall
  through to stock behaviour when `isIdentity()`) must stay intact.

## 4. Design

### 4.1 S1 — scroll reachability (D2; independent of the flip, fixes §2 on its own)

New per-class capability on `TransformFrameWdgt` (capability-first convention — dispatched via
`?()`, NO Widget base default), consulted by the merge walk:

- Name candidate: `scrollOverflowBoundsInParentPlane()` (executor may improve it; it is a
  PARENT-PLANE derived quantity — mind the two-vocabulary law's naming: it is not screen-family,
  and it must not masquerade as the layout-box family).
- Value: `claimedBox(currentMode) ∪ inkFootprintBox`, both positioned in the parent plane via the
  existing `slotOffsetWithinClaim` machinery, where `inkFootprintBox` = the footprint-mode box (the
  corner-mapped integer AABB of the slot box — `TransformSpec._claimedBoxFor 'footprint'`
  positioned about the same anchor). NB the union is REQUIRED, not decorative: at 90° a wide-short
  slot's mapped AABB (tall-narrow) does NOT contain the slot box, and for `'sweep'` the claim ⊇ ink
  gives spin-stability. Integer law: the pieces are already integer AABBs; keep the union `.ceil()`
  discipline of the caller.
- Wire-up: in `Widget.subWidgetsMergedFullBounds` (`:1149`), the child contribution becomes
  `child.scrollOverflowBoundsInParentPlane?() ? <current expression>`. Only the island answers;
  every other widget is byte-identical. Also decide the SEED: `@children[0].bounds` — if the first
  child is an island, seed with its contribution too (a one-line asymmetry that would otherwise
  clip the union on single-child panels).
- Blast radius: `subWidgetsMergedFullBounds`'s single consumer is the non-content-sizing scroll
  branch (its own comment; re-verify with grep at arc start — the lint note there means any OTHER
  caller that has appeared since must be reasoned about explicitly). The D4/U3-A "named state-read"
  classification is unchanged (still a read of stable applied geometry + a pure derived box).
- NOT touched: `fullBounds` itself (many consumers — damage, flesh-out, paint; changing its
  semantics island-wide is a different, bigger arc and unnecessary here), the content-sizing
  branches (stack/text scroll frames size from measures; an island as DIRECT content of a scroll
  frame is not a live construct — re-verify at arc start), occlusion/hit-test paths (§4.11 already
  correct via `clippedThroughBounds`).

### 4.2 S2 — the default flip (D1)

- `TransformSpec.coffee`: prototype field `:35` and constructor default `:37` → `"footprint"`.
  Nothing else changes: `setClaimsSpace`/`_reflowIfClaimChangedNoSettle` already reflow-on-change,
  stacks already consult `preferredExtentForWidth` (claim-aware), serialization already carries the
  scalar explicitly.
- **Rotator census rides this step** (see S3): every in-tree construction/mutation of rotation must
  be classified BEFORE the flip lands, so nothing in-tree starts churning layout by surprise. Grep
  starting set (re-run cold): `setRotation`, `_setRotationNoSettle`, `rotationHalo_apply`,
  `new TransformFrameWdgt`, `TrackingTransformFrameWdgt` (hugging islands — verify what claim mode
  means for a tracking island whose slot box follows its content), LCL/Fizzytiles rotate paths
  (expected NOT islands — SW3D renders internally — verify), demo/menu actions that tilt things.
  Continuous rotators get an explicit `'sweep'` (or `'slot'`) IN THEIR CLASS; one-shot aesthetic
  tilts get the new default.

### 4.3 What is deliberately NOT built

- No container-level "freeze" veto (§4.9 banked — unchanged by this arc).
- No shrink-to-fit (D3 / FORBIDDEN).
- No change to `'slot'`/`'sweep'` semantics for SIBLING layout — only scroll reachability (D2).
- No CSS-like always-ink rule for sibling layout anywhere.

## 5. Staging + gates (fg discipline as always: presuite per step, full gauntlet at close;
   byte-exactness is the oracle wherever behaviour is not deliberately changed)

- **V0 (no behaviour change)** — re-grep every anchor in §3; VERIFY the serialization claim (probe:
  serialize a default-spec island pre-flip, confirm the JSON carries `claimsSpace:"slot"`
  explicitly; confirm the Deserializer restores stored scalars over class defaults — cf. the
  `_afterDeserialization` old-doc case law from the ε arc, `SimplePlainTextPanelWdgt`); run the
  rotator census; confirm `subWidgetsMergedFullBounds`'s consumer set is still exactly one.
  **OWNER GATE G1** on: the census classification, the union-rule semantics (esp. the seed
  asymmetry), the capability name.
- **S1** (scroll reachability) — implement §4.1 + tests T1/T3 (below). Expected: byte-identical
  for every test WITHOUT a transformed island in a scroll panel (the capability answers only on
  islands; identity islands return slot box ⇒ union degenerates to today's box — assert this
  dormancy explicitly). Commit point.
- **S2** (default flip + rotator census fixes + suite re-point) — implement §4.2; re-point the
  firewall macro (it must now SET `'slot'` explicitly for its stillness half — the macro's
  assertion inventory stays, the setup line changes); add T2/T4. Recaptures expected ONLY in tests
  that put a transformed island inside a tracking container and relied on the old default —
  enumerate and justify each (dump+LOOK before recapturing, per standing practice). Commit point.
- **S3 — the HALO FEEL-CHECK (OWNER GATE G2, owner-driven, manual)** — with S1+S2 green: owner
  drives the rotation halo on (a) a desktop island, (b) an island in a document/stack, (c) an
  island in a scroll panel. Watch for: siblings shuffling live (expected now — is it acceptable in
  feel?), the rotated widget "walking" under the pointer as its claim re-places it (the Bug D/G
  anchor-stability territory — if the drag feels squirrelly this becomes a follow-up design item,
  NOT a silent accept), scrollbar pulse under `'slot'` spin (accepted per D2). Outcome recorded in
  this doc; a bad feel outcome does NOT revert the arc — it opens a targeted follow-up (e.g.
  halo-drag defers reflow to release), owner's call.
- **S4 close** — doc updates (§7), full 11-leg `fg gauntlet`, end-of-arc review, commit/push only
  with owner approval. Stop-rule: 2 falsified implementation shapes on one step ⇒ stop and
  re-frame with the owner (don't iterate a third shape).

## 6. Testing (the arc's acceptance set)

- **T1 (the §2 acceptance picture)** — a `'slot'` island in a **plain, freshly constructed
  free-floating `ScrollPanelWdgt`** (owner directive 2026-07-17: do NOT test against the basement —
  it is complected with unrelated behaviours: off-tree, survives `resetWorld` (the up-edge arc's
  uniqueIDString-collision case law), lost-items filter, close/re-home machinery; the basement was
  the REPORT vehicle only). Rotate the island so ink exits the viewport → the scrollbar APPEARS and
  scrolling reaches all ink; rotate back → extent shrinks. Macro-style value-asserts on the
  contents frame extent + screenshot.
- **T2 (D1 mainstream case)** — a rotated image/widget in a document (SimpleDocumentWdgt / a
  vertical stack) with NO explicit mode: text below does NOT overlap — the stack reserves the
  rotated AABB. Include the 90° exact-transpose assert (integer-exact, cf. the Phase 3 macro).
- **T3 (sweep spin-stability under D2)** — a `'sweep'` island in a scroll panel: extent identical
  across scripted angles (footer/scrollbar steady) — the union rule must NOT leak angle-dependence
  through the ink term.
- **T4 (old-doc compat)** — a serialized fixture captured BEFORE the flip (or a probe-constructed
  equivalent) deserializes with `claimsSpace == 'slot'` and today's behaviour. This is the D1
  safety property, test-pinned.
- **Re-pointed**: `macroTransformFrameFootprintReflow` (explicit `'slot'` for the stillness half;
  the footprint-coupling half may drop its now-redundant explicit set — keep the assert inventory
  identical). `macroTransformFrameSweepReserve` unchanged (sweep is explicit already).
- **Suite-wide**: per-step `fg presuite` (byte-exact expected outside the enumerated deliberate
  changes); close = full `fg gauntlet` (11 legs — dpr1/dpr2/webkit catch AA/trig drift in the
  mapped AABBs; settle/capstone/revisits catch any new reflow loop — a footprint reflow is
  frame-delta-gated by `_reflowIfClaimChangedNoSettle`, so the revisits EMPTY baseline must hold);
  `NON_INTEGER_GEOMETRY` stays green (union boxes ceil'd). Determinism note: the mapped AABBs come
  from the same deterministic trig the damage path already uses byte-exactly cross-engine.

## 7. Documentation updates (part of the arc, not optional)

- `docs/plans/affine-transforms-plan.md` §4.9: move the "(default)" marker to `'footprint'`; add the D2
  reachability rule (claimed ∪ ink, all modes) as a fourth table note; record D1/D2 as owner
  decisions of 2026-07-17 with the layout-vs-reachability principle; keep the old "CSS semantics"
  slot-default rationale as dated history (it explains Phase 1–3 test design). §4.10: add the
  old-docs-pinned note (verified at V0).
- `src/basic-widgets/Widget.coffee` `subWidgetsMergedFullBounds` comment block (:1140-1148): the
  "single consumer" + lint note stays; add the island capability line + a D2 breadcrumb.
- `docs/archive/layout-system-architecture-assessment.md`: wherever the D4/U3-A named state-read is
  described, add the one-line D2 note (the read now unions the island's reachability box — still a
  read of stable applied geometry + a pure derived box, classification unchanged).
- `docs/archive/affine-geometry-api-plan.md`: add the new parent-plane query to whichever family table
  lists derived quantities (it is neither layout-box nor screen-family; say so explicitly).
- `Fizzygum/CLAUDE.md`: no change expected (it doesn't mention claimsSpace) — verify at close.
- This doc: fill the execution log + the G2 feel-check outcome.

## 8. Risks / gotchas (embedded so a cold executor doesn't rediscover them)

- **The seed asymmetry** in `subWidgetsMergedFullBounds` (`@children[0].bounds`) — see §4.1; a
  single-island panel is the test for it.
- **90° does not nest**: the mapped AABB does not contain the slot box in general — the union is
  load-bearing (see §4.1); a "footprint-box-only" shape is a known-wrong simplification.
- **TrackingTransformFrameWdgt** (the hugging island): its slot box follows its content; verify
  claim-mode interaction explicitly in the census (it inherits `colloquialName`; check what else).
- **Old docs**: safe ONLY because the scalar serializes explicitly — the V0 probe is mandatory, and
  the ε case law (`Serializer stores own enumerables`, nearest-first surprises,
  `_afterDeserialization` normalization pattern) is the reference if the probe falsifies.
- **Do NOT override `fullBounds`** on the island to "simplify" S1 — its other consumers (damage,
  flesh-out) are calibrated to the slot box + §4.11's outer face; that shape is a falsifier trap.
- **SLOW twins**: only needed if the implementation touches the cached clip/bounds family
  (`clipThrough`/`clippedThroughBounds`/`fullClippedBounds`) — the S1 shape above does not; if the
  executor's shape drifts into that family, override SLOW twins IN LOCKSTEP (standing lesson).
- **Never edit src mid-suite**; fg by absolute path; long ops once in background; probes in
  `Fizzygum-tests/.scratch/`; `git commit -F`; ask before commit/push. Stop-rule per §5.

## 9. Execution log (fill as the arc runs)

### V0 — verify pass (2026-07-17, tree @ `a1fa2c49`, build FRESH, gauntlet 11/11 green pre-arc)

**Anchors re-verified — §3 all HOLD** (lines current @ `a1fa2c49`): TransformSpec `:35/:37`
defaults + machinery `:64/:71/:78/:85`; TransformFrameWdgt `setClaimsSpace :183`,
`_reflowIfClaimChangedNoSettle :248` (**'slot' early-return `:249`**), `preferredExtentForWidth
:266`, `_applyExtentBase :274`, `_applyMoveToBase :283`, `clippedThroughBounds :660`/SLOW `:678`;
`Widget.subWidgetsMergedFullBounds :1149` (seed `:1152`); consumer set still EXACTLY ONE real call
site (`ScrollPanelWdgt.coffee:464`, the non-content-sizing else-arm — every other grep hit is a
comment or test intent-text). NEW since authoring: the sibling walk
`subWidgetsMergedPreferredBounds` (`Widget.coffee:1180`, seeded identically) serves the
content-sizing branches (`ScrollPanelWdgt:457/:460`) — S1's walk change touches ONLY the
fullBounds walk, but the sibling's existence is now recorded. `isContentSizing` (`:147`) =
`@isTextLineWrapping` ⇒ a plain fresh free-floating ScrollPanelWdgt takes the SAME
non-content-sizing branch as the basement — the T1 vehicle exercises the defective path. ✓

**Serialization probe (MANDATORY) — RAN, ALL 9 PREDICTIONS CONFIRMED**
(`Fizzygum-tests/.scratch/claimsspace-serialization-probe.js`, headless against the live build):
- (A) a default-mode explicit island's JSON carries `"claimsSpace":"slot"` EXPLICITLY (own prop).
- (B) deserializing that JSON with `TransformSpec.prototype.claimsSpace` flipped to `"footprint"`
  restores the STORED `"slot"` (Deserializer = `Object.create` shell + stored-field assign,
  `Deserializer :183/:191`) ⇒ **post-Phase-3 docs are SAFE under the flip**.
- (C) **PRE-PHASE-3 HAZARD CONFIRMED**: a record with NO `claimsSpace` key (a doc saved before
  Phase 3 added the scalar) restores through the PROTOTYPE ⇒ under the flipped default an old
  rotated island silently becomes `'footprint'`. Cure (G1 item): island-level
  `_afterDeserialization` (hook already run for every Widget shell, `Deserializer:115`; islands
  don't define it yet) normalizes a keyless spec to explicit `'slot'` — detectable via
  `hasOwnProperty(spec,'claimsSpace') == false`. T4 pins it.
- (D) a SUGAR island round-trips STRUCTURALLY (class `TrackingTransformFrameWdgt` + explicit
  `"slot"` + `_materializedBySugar` all in the JSON) — "scalar serialization" means the SPEC's
  scalars, not a dematerialize-to-content encoding.

**Rotator census — COMPLETE.** In-tree island construction/rotation sites (the whole set):
1. `Widget._materializeSugarIslandNoSettle :1587` — 4C property sugar (halo `rotationHalo_apply`
   ← `HandleWdgt:341`, + `setRotationDegrees`/`setScaleFactor`). `TrackingTransformFrameWdgt`,
   **rides the default** (no explicit mode).
2. `Widget._pickOutRotatedFigureNoSettle :1726` — 4D-2a pick-out onto the hand. Same class,
   rides the default; after a drop it persists as a sugar figure.
3. `Widget._reExpressFigureForPlaneOfNoSettle :1823-1830` — Bug-F COMPENSATING wrapper (bare
   payload dropped into a tilted plane keeps its on-hand look). Same class, rides the default.
4. Explicit authored islands: NO production construction site (tests/macros/user code only).
5. LCL/Fizzytiles: NOT islands (rotation is SW3D-internal — `LCLTransforms` matrix stack). ✓
6. No production menu/demo rotate actions exist. ✓
Three comments bake the 'slot'-default assumption and must be updated by S2:
`TrackingTransformFrameWdgt :56` + `:160`, `TransformFrameWdgt :126`.

**NEW DESIGN FINDING F1 — the tracking island BYPASSES the claim machinery (S2 blocker as
planned).** The layout-transparency family (drop-into-rotated-container arc, 2026-07-13):
`TrackingTransformFrameWdgt.preferredExtentForWidth :161` / `_applyExtent :136` /
`_setWidthSizeHeightAccordingly :150` / `getMinimumExtent :172` all forward to the CONTENT
whenever non-identity+content — the base's claim-reporting measure is never consulted. Since ALL
THREE production materialization sites make THIS class, **flipping the TransformSpec default alone
does NOT deliver D1's mainstream case** (a halo-rotated image in a document is a sugar =
tracking island). Candidate S2 shape (G1 approval): gate the transparency family on the EFFECTIVE
mode — `'slot'` (or identity/empty) ⇒ today's transparent forward, byte-identical; coupled modes
⇒ fall through to the base fixed-figure protocol (measure = claimed extent of the current slot
box; content not stretched — the base protocol already avoids the grow-feedback loop by ignoring
the offered width). The re-hug `_reLayoutChildren :74-98` must additionally propagate a
claim-change on slot re-hug for a COUPLED tracking island (today it only nils
`_lastClaimedExtent`, comment asserts 'slot'); the settle loop's frame-change-gated ordered
up-edge may already cover it (slot DOES change on re-hug) — VERIFY during S2.

**NEW DESIGN FINDING F2 — the scroll-extent INVALIDATION gap (S1 has a second half).** A
transform change on a `'slot'` island invalidates NO layout (`:249`), and even a coupled island's
`_invalidateLayout` climb DROPS at `@contents` (`Widget._invalidateLayout :4634-4650`: a
free-floating triggeringChild returns unless the parent defines `_reLayoutChildren`; plain
`PanelWdgt` doesn't) — so even `'footprint'` never re-fits the enclosing scroll frame today, and
the D2 walk fix alone is INERT until something else re-arranges the panel (T1's "rotate →
scrollbar appears" would fail). Candidate S1 shape (G1 approval): a SEPARATE union-box memo
("did my claimed ∪ ink box change?") checked from `_transformChangedNoSettle` /
`_setClaimsSpaceNoSettle`; on change, request the enclosing scroll frame's re-fit through the
established capability-guarded verb (the `PanelWdgt._reFitContainer` pattern — the same seam the
§9-N2 basement-scatter fix used). Mode-by-mode: 'slot'/'footprint' fire on angle/scale change;
'sweep' NEVER fires on pure rotation (union = sweep square, rotation-invariant) — D2
spin-stability by construction. Memo must be separate from `_lastClaimedExtent` (measure-path).

**G1 gate — CLOSED 2026-07-17, all verdicts in:**
- **Arc shape APPROVED**: F1 = mode-gate the tracking island's four transparency overrides
  (`'slot'`/identity/empty ⇒ today's transparent forward, byte-identical; coupled ⇒ `super` ⇒ the
  base fixed-figure protocol). Re-hug claim propagation needs NO new wiring — the engine's
  per-child frame-delta watch + `myFrameChanged` up-edge (`WorldWdgt:1265-1270` →
  `_reFitMyTrackingContainerAfterSettle :2332`, which already has the `@parent.parent`
  folder-frame hop `:2335`) covers a slot change. F2 = a SECOND memo `_lastScrollOverflowBox`
  (separate from `_lastClaimedExtent`) + on change `@_reFitContainer @parent.parent if
  @_amIDirectlyInsideNonTextWrappingScrollPanelWdgt()` from the transform-change cores — the
  sanctioned §9-N2-style intent verb; two memos = D2's layout-vs-reachability split in code;
  sweep spin-stability structural (union rotation-invariant ⇒ memo never fires on pure rotation).
  Union rule + seed treatment as planned.
- **Island modes APPROVED**: sugar + pick-out islands FOLLOW the new `'footprint'` default (they
  are D1's mainstream case); the Bug-F COMPENSATING wrapper gets explicit `'slot'` at its
  construction site (`Widget._reExpressFigureForPlaneOfNoSettle`) — semantic call: invisible
  look-correction plumbing must not claim space.
- **Capability name APPROVED**: `scrollOverflowBoundsInParentPlane()` (CSS "scrollable overflow").
- **Old-docs item DISSOLVED by owner input** (2026-07-17): the owner has NO saved serialized
  widgets to keep compatible — NO `_afterDeserialization` normalization is built, **T4 is
  DROPPED** from §6, keyless pre-Phase-3 records simply follow the new default. Also restated:
  test churn must never dictate design — enumerate + LOOK at recaptures, but The Right Thing wins.

### S1 — scroll reachability (2026-07-17) — LANDED

Code (all under the G1-approved shape):
- `TransformSpec.scrollOverflowBoxFor(slotBounds)` — claimed box ∪ the ink's INTEGER HULL. The
  ink term is `mapRectExact` floor/ceil'd, deliberately NOT the damage-padded `mapRect`: the
  padded box pokes 1px past the sweep square at corner-aligned angles and would leak
  angle-dependence into sweep's extent (a 1px scrollbar pulse); the unpadded hull nests inside
  the sweep square at EVERY angle. Reachability tracks geometric ink (the CSS line); the <1px AA
  bleed stays a damage concern.
- `TransformFrameWdgt.scrollOverflowBoundsInParentPlane()` — the capability; nil at identity
  (walk falls through to stock ⇒ dormant). `_lastScrollOverflowBox` memo (+ serializationTransients
  entry) + `_reFitScrollFrameIfReachChangedNoSettle` — called from `_transformChangedNoSettle`
  and `_setClaimsSpaceNoSettle`; fires `@_reFitContainer @parent.parent` behind the existing
  `_amIDirectlyInsideNonTextWrappingScrollPanelWdgt` predicate (orphan-safe). A stale memo
  (plain moves don't maintain it) can only FALSE-FIRE (idempotent intent), never false-skip.
- `TrackingTransformFrameWdgt._reLayoutChildren` nils the new memo next to `_lastClaimedExtent`
  (the re-hug's scroll re-fit rides the engine's frame-change up-edge; pure bookkeeping mid-pass).
- `Widget.subWidgetsMergedFullBounds` — per-child contribution =
  `child.scrollOverflowBoundsInParentPlane?() ? <stock deferred/fullBounds expression>`; the SEED
  takes the same capability answer (a coupled island's union does not contain its pixel-less
  virtual slot box, which must not inflate the frame). Comment block updated in place.

Evidence:
- presuite after the src change, BEFORE the new tests: 257/257 byte-exact dpr1 + paint audit 0
  offenders — the dormancy guarantee proven empirically (no existing test has a transformed
  island in a scroll panel).
- **T1 `SystemTest_macroTransformFrameSlotScrollReachability`** (the §2 acceptance picture, on a
  PLAIN fresh free-floating ScrollPanelWdgt per the owner directive; island pins 'slot'
  explicitly so it survives the S2 flip): upright = no bars → setRotation 60 ⇒ vBar rule ON
  (value-assert) + scrollbar visibly appears → setRotation 0 ⇒ rule OFF + **image_3 byte-identical
  to image_1, asserted in-run** (clean appear/disappear round-trip; same dataHash at dpr1 AND
  dpr2) → re-tilt + wheel ⇒ the previously-cut-off ink corner scrolled into view. Captured
  dpr1+2, verify PASS ×8, references LOOKED at.
- **T3 `SystemTest_macroTransformFrameSweepScrollSpinStable`**: 'sweep' island (pinned
  explicitly) whose ~166px swept square overflows the 150px viewport ⇒ vBar ON from construction;
  spins 30→75→120 with content frame width AND height exactly unchanged (integer value-asserts);
  scrollbar visually identical across the two shots. Captured dpr1+2, verify PASS ×4, LOOKED at.
- Visualisation pages generated for both. Suite = 259.
- S1-boundary presuite (259 tests incl. T1/T3): GREEN, byte-exact + paint audit clean.

### S2 — the default flip (2026-07-17) — LANDED

Code:
- `TransformSpec` `:35/:37` → `"footprint"` (prototype + constructor default), comment records
  D1 + the old rationale as dated history.
- `TrackingTransformFrameWdgt` — the four transparency overrides MODE-GATED: `'slot'` (or
  identity/empty) ⇒ the transparent forward (byte-identical to before); coupled ⇒ the base
  fixed-figure protocol. `_applyExtent`/`getMinimumExtent`/`preferredExtentForWidth` coupled
  arms are plain `super`; `_setWidthSizeHeightAccordingly`'s coupled arm returns
  `claimedExtentFor(@bounds).y` — the stack advances its cursor by the RETURNED height for
  container-classified children, and the base `_applyMoveToBase` parks the slot at
  claimedOrigin + slotOffset. Header + re-hug comments updated (the re-hug's parent re-fit
  rides the engine's frame-change up-edge in every mode — no new wiring).
- `Widget._reExpressFigureForPlaneOfNoSettle` — the Bug-F COMPENSATING wrapper pins explicit
  `'slot'` (owner decision: invisible look-correction plumbing never claims space); the 4C
  sugar + 4D-2a pick-out islands FOLLOW the default (the mainstream case).
- `TransformFrameWdgt.rotationHalo_apply` comment updated (per-drag reflow inside tracking
  containers = the accepted D1 implication).

Blast radius (enumerated by presuite, 259 tests): **exactly 2 failures, both deterministic
(identical parallel + serial), both = tests whose SUBJECT is the old 'slot'-default semantics**
— everything else byte-identical including tilted windows, sugar sibling-order, tilted-stack
drops, spreadsheet tilted click, internal/external skins, all desktop islands:
- `macroTransformFrameSweepReserve` — its 'slot' BASELINE half rode the default ⇒ ctor now pins
  `'slot'`; assert inventory + references unchanged.
- `macroRotateChildInsideStretchablePanelThenResize` — its subject is the 5b fractional-
  bookkeeping ride whose observable is the 'slot'-transparent stretch ⇒ the macro pins the
  sugar island to `'slot'` right after materialization; assert inventory + references
  unchanged. (Under the new default a rotated child in a stretchable panel is a FIXED FIGURE
  the panel never stretches — G2 feel-check material, by design.)
- `macroTransformFrameFootprintReflow` re-pointed as planned (stillness half pins 'slot');
  passed the presuite unchanged.
- ZERO recaptures anywhere.

**T2 `SystemTest_macroTransformFrameFootprintDefaultSugarInStack`** (the D1 acceptance):
document + PIC + footer, `pic.setRotationDegrees 40` with NO mode set anywhere ⇒ the sugar
island reads 'footprint' (value-assert) and the footer drops below the rotated AABB
(value-assert + shot); 90° ⇒ claimed extent == slot transposed within the 1px pad
(value-assert + shot, an exact upright transpose on LOOK); back to 0 ⇒ sugar DEMATERIALIZES
(parent is the stack again, value-assert), footer back at its original top, **image_4
byte-identical to image_1 asserted in-run** (same dataHash at dpr1 AND dpr2). Captured dpr1+2,
verify PASS ×8, references LOOKED at, visualisation generated. Suite = 260.

Docs (S4, done alongside): affine plan §4.9 default moved + D1/D2 owner-decision notes + §4.1
and §10.8 default mentions + §4.10 old-doc note (keyless records follow the current default —
owner-accepted, no shim); assessment's D4/U3-A note gains the D2 line; geometry-API doc gains
the parent-plane-derived family member; Fizzygum CLAUDE.md verified — no claimsSpace mention,
no change (as predicted).

**Gauntlet finding (close run #1): the CAPSTONE gate caught an undeclared off-settle push.**
10/11 legs green (all pixels byte-exact everywhere incl. webkit; revisits EMPTY holds; census
clean; settle/refs legs = parallel load-flakes, serial PASS). capstone: 4 careless end-of-cycle
pushes by TrackingTransformFrameWdgt in the 3 drop-into-tilted-plane tests
(macroDropKeepsHandOrientation ×2, macroTransformFrameCrossPlaneDropKeepsRelative,
macroTransformFrameDropBackUnwraps). Mechanism: the Bug-F PICK-half ancestor-fold
(`_resolvePickOutFigureNoSettle`'s `_setRotationNoSettle`/`_setScaleNoSettle`) and the DROP-half
re-spec (`_reExpressFigureForPlaneOfNoSettle`) now hit `_reflowIfClaimChangedNoSettle →
_invalidateLayout` on the 'footprint'-default sugar figures, OUTSIDE any settle declaration —
the pre-flip 'slot' early-return had made these seams audit-silent. Both seams' comments always
stated the settle contract ("rides the caller's own grab settle" / "the drop's target.add
carries the settle") — the fix makes it machine-checked: `_deferredSettleDeclare` windows at
the TWO seam calls (`Widget._resolvePickUpFigure` step 1, `ActivePointerWdgt.drop :462`), the
same idiom the `_moveTo`/`_setExtent`/`_setMaxDim` deferred cores use. No behaviour change —
the declaration only marks the already-carried pushes intentional.

### Arc close — gauntlet + status (2026-07-17)

- **Close gauntlet (run #2, after the capstone fix): 11/11 GREEN in 262s, every leg first-try**
  — dpr1(121s) dpr2(126s) webkit(116s) apps(70s) paint(100s) tiernaming(115s) settle(115s)
  capstone(116s) refs(18s) revisits(115s — the EMPTY baseline HOLDS) census(8s). Suite = 260
  (T1/T2/T3 added; T4 dropped by owner input), ZERO recaptures, 3 macros re-pointed with
  explicit 'slot' pins.
- MACRO-PATTERNS.md gained the claimsSpace-mode fixture entry (pin non-default modes; test the
  default's reach via the bare sugar; the D2 scroll fixture + spin-stability idioms).
- **PENDING: G2 — the owner-driven halo FEEL-CHECK** (plan §5 S3): desktop island / island in a
  document / island in a scroll panel; watching for live sibling shuffle feel, claim-re-place
  "walking" under the pointer (Bug D/G territory ⇒ follow-up item, never silent accept), 'slot'
  scroll-edge pulse (accepted per D2). A bad feel outcome does NOT revert the arc — targeted
  follow-up, owner's call. Also G2-adjacent by design: under the new default a rotated child in
  a stretchable panel is a FIXED FIGURE (no stretch on container resize) — surfaced by the S2
  test re-point, worth a deliberate feel on the same pass.
- **PENDING: owner review + commit approval** (nothing committed; both repos carry the arc's
  changes uncommitted).

### Owner correction at review (2026-07-17): dictating containers are NOT mode-gated

Presenting "a rotated child in a stretchable panel is now a fixed figure (no stretch)" as
by-design was WRONG — the owner ruled: **that is not the contract of a stretchable panel with
its contents.** The corrected model, now in code:
- `claimsSpace` governs **space NEGOTIATION** (measure-based flow containers that ASK — the
  stack protocol trio `preferredExtentForWidth` / `_setWidthSizeHeightAccordingly` /
  `getMinimumExtent`, which keep the S2 mode gate) **and scroll REACHABILITY** (D2).
- It never opts a child out of a **DICTATING container's** sizing: `_applyExtent` (the
  stretchable panel's fractional model, window content sizing) stays TRANSPARENT in every mode
  — the un-gated revert restores the pre-S2 forward verbatim, with the split documented at the
  MODE GATE header + the method.
- `macroRotateChildInsideStretchablePanelThenResize`'s 'slot' pin REVERTED — it runs UNPINNED
  under the 'footprint' default and now also proves the default does not opt a rotated child
  out of the panel's contract. Net S2 macro re-points: 2 (footprintReflow + sweepReserve, both
  legitimately 'slot'-semantics subjects).
- **Post-correction gauntlet: 11/11 GREEN in 265s, every leg first-try** (dpr1 114s / dpr2
  119s / webkit 116s / apps 67s / paint 107s / tiernaming 125s / settle 125s / capstone 125s /
  refs 19s / revisits 125s — EMPTY baseline holds / census 8s). The unpinned stretchable test
  passes byte-identical to its committed references (the un-gated forward is the pre-S2 code
  restored verbatim).

### Committed (2026-07-17, owner-approved)

Owner approved commit+push at review (2026-07-17), with **G2 (the halo feel-check) to follow
post-push** — per §5, a bad feel outcome opens a targeted follow-up, never a revert. Final S4
doc pass rode the commit: assessment §2.5 gains the ASKING-vs-DICTATING containers datum
(claimsSpace gates space negotiation + scroll reachability only) and rulebook rule 4 gains the
climb-drops-at-non-tracking-intermediate case law + the `_reFitContainer` hop as the sanctioned
alternative.

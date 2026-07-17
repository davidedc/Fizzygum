# claimsSpace: footprint-by-default + scroll reachability — plan (authored 2026-07-17)

Self-contained, cold-startable. Everything an executor needs is embedded; file:line anchors were
verified 2026-07-17 @ `61080871` — **re-grep symbols at arc start, lines drift**. Companion design
history: `docs/affine-transforms-plan.md` (esp. §4.9 mode table :537, §4.10 serialization :577,
§4.11 two faces :587, the Phase 3 execution log :930). Conventions that bind this arc:
capability-first dispatch (`docs/type-test-elimination-plan.md`, campaign complete — new queries are
per-class `?()` capabilities, never type tests), integer placement law
(`docs/integer-pixel-placement-and-sizing.md`), the two-vocabulary law
(`docs/affine-geometry-api-plan.md`).

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

- `docs/affine-transforms-plan.md` §4.9: move the "(default)" marker to `'footprint'`; add the D2
  reachability rule (claimed ∪ ink, all modes) as a fourth table note; record D1/D2 as owner
  decisions of 2026-07-17 with the layout-vs-reachability principle; keep the old "CSS semantics"
  slot-default rationale as dated history (it explains Phase 1–3 test design). §4.10: add the
  old-docs-pinned note (verified at V0).
- `src/basic-widgets/Widget.coffee` `subWidgetsMergedFullBounds` comment block (:1140-1148): the
  "single consumer" + lint note stays; add the island capability line + a D2 breadcrumb.
- `docs/layout-system-architecture-assessment.md`: wherever the D4/U3-A named state-read is
  described, add the one-line D2 note (the read now unions the island's reachability box — still a
  read of stable applied geometry + a pure derived box, classification unchanged).
- `docs/affine-geometry-api-plan.md`: add the new parent-plane query to whichever family table
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

- (empty — arc not started)

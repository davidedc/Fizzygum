> **ARCHIVED — COMPLETE (2026-07-17 restructure).** LANDED 2026-07-11 (Phase 5); gauntlet across 3 engines + homepage green, one benign recapture.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Public geometry API under transforms — the two-vocabulary contract + the missing methods

**STATUS: ✅ LANDED 2026-07-11 (Phase 5, first banked item). Everything in §3 shipped — `TransformSpec::
mapRectExact`, the five `Widget` methods (`screenBounds`/`rotationDegrees`/`scaleFactor`/`accumulated-
RotationDegrees`/`accumulatedScaleFactor`/`isVisuallyTransformed`), the §3.5 first-caller refactors
(pick-out + drop-re-express now call `accumulated*()`; `rotationHalo_currentDegrees` aliases
`rotationDegrees()`; `rotationHalo_screenAnchor` routes through the true/pinned anchor), and the docs
(§3.6). New value-assert macro `SystemTest_macroGeometryApiTwoVocabularies` (no screenshots) covers the
law both sides + accumulation + the predicate matrix + the pinned-anchor case. Gates: `fg build` green
(dead-methods 1500 scanned / 0 new, thin-wraps/stinks OK, test .js syntax OK), the macro PASSES at dpr1,
and the full `fg gauntlet` (dpr1/dpr2/webkit + apps/paint/tiernaming/settle/capstone) + `fg homepage`
green — the ONLY reference delta the sanctioned benign inspector member-list recapture (6 new Widget
methods shift the Properties list). Owner EXCLUSION (§1.3, honoured): no inspector change of any kind.
The original authored/approved text is preserved below.**

**ORIGINAL STATUS (authored 2026-07-11, owner-approved same day, scope decisions final, incl. one explicit
EXCLUSION — see §1.3). Owner-gated: executed as its own gate-green unit AFTER the affine-transforms arc's
in-flight units (§7.5 Bugs D+E → 4D-2b stage 2b-ii → 4E close-out). The standing "commit + continue while
all gates pass" grant applied; never push without owner approval.**

This document is self-contained and executable cold: it embeds the contract, the motivating
evidence, the current-state facts (verified 2026-07-11 — line numbers WILL have drifted, every
anchor is paired with a symbol; grep the symbol, scoped to `src/`, never the workspace root), the
exact API specs, the refactors that provide first callers, the macro plan, and the gates.

---

## §1 The contract (this section is the deliverable's normative text)

### 1.1 The two-vocabulary law

A widget's geometry API is split into exactly two families, distinguishable BY NAME alone:

- **LAYOUT-BOX family** (the existing names): `width()/height()/extent()/bounds/boundingBox()/
  position()/center()/left()/top()/right()/bottom()/…` — **plane-local, untransformed, integer**.
  Inside a `TransformFrameWdgt` ("island") these are virtual-plane values; outside, screen values —
  in both cases they are the widget's OWN-plane layout box, and **transforms never affect them**.
  This is not a limitation to fix: it is the load-bearing invariant of the island architecture
  (`docs/plans/affine-transforms-plan.md` §4.1 "virtual plane") — layout, settle, arrange, and content
  code operate on these and must keep working unchanged under any transform.
- **SCREEN family** (small, explicit): every name contains `screen` — today
  `localPointToScreen(p)` / `screenPointToMyPlane(p)`, plus the additions in §3. These return
  **post-transform screen-plane values, possibly fractional**.
- **Parent-plane derived (one member, claimsSpace arc D2 2026-07-17):**
  `TransformFrameWdgt.scrollOverflowBoundsInParentPlane()` — the island's claimed box ∪ its ink
  hull, INTEGER and expressed in the PARENT plane. Deliberately in NEITHER family above: it is
  not plane-local layout-box geometry (it reflects the transform) and not screen-family (no
  ancestor-plane composition, never fractional). Sole consumer: the scroll frame's merge walk
  (`Widget.subWidgetsMergedFullBounds`).

**THE LAW: no method without "screen" in its name ever returns transformed geometry; no method
with "screen" in its name ever returns plane-local geometry.** (Third axis, unchanged: logical vs
physical pixels — the screen family returns LOGICAL screen coordinates; `ceilPixelRatio` stays a
paint-boundary concern.)

Precedent (for reviewers, not to relitigate): CSS `offsetWidth`/`clientWidth` are transform-blind
while `getBoundingClientRect()` is the transformed AABB; Core Animation's `bounds.size` is
untransformed while `frame` is documented undefined under a transform; Flutter's `size` is
untransformed with `localToGlobal()` for mapping. The owner's 2015 design notes sketched the same
split ("width + height + bounding box in respect to the parent; chain up to obtain measures
against the world").

### 1.2 The documented exception (internal, not public API)

The island's two-faces overrides — `TransformFrameWdgt.clippedThroughBounds()` /
`fullClippedBounds()` returning the SCREEN footprint ∩ ancestor clips — are framework-internal
damage/hit-lane machinery (`docs/plans/affine-transforms-plan.md` §4.11) and predate this law. They are
NOT to be used as a screen-bounds proxy by feature code; `screenBounds()` (§3.1) exists precisely
so nobody reaches for them.

### 1.3 Owner scope decisions (final)

- APPROVED: everything in §3 (screen-AABB query, own + accumulated transform getters, public
  transformed-predicate, the DRY refactors, docs).
- **EXCLUDED by owner (do NOT implement): "inspector honesty"** — no derived `screenBounds` row or
  any other inspector UI change. Record only; a future owner-initiated item.
- DEFERRED (not in this unit, add only with a real consumer): `moveToScreenPoint()`-style
  screen-space movers; `screenQuad()` (exact 4-corner polygon); `fullScreenBounds()` (subtree);
  `inverseMapVector`/`inverseMapRect`/`TransformSpec.compose` (PROVEN unneeded — see the affine
  plan's 4E deferred-methods identity note; do not re-add "for tidiness").

### 1.4 Why now — two internal trip-ups prove the gap

Both of these were bugs caused by the missing vocabulary, found during the affine arc:
1. 4D-1's drop placement assumed `payload.center()` is the payload's visual centre — broken once
   §7.5 Bug D introduced PINNED anchors (fix: map the centre; recorded in the Bug D "4D INTERPLAY"
   note in `docs/plans/affine-transforms-plan.md`).
2. `Widget.rotationHalo_screenAnchor` was `@localPointToScreen @center()` — also stale under
   pinned anchors (the true pivot is `_anchorFor`, not the centre). Flagged in the Bug D/E unit;
   see §5 step 0 (it may already be fixed by the time this plan runs).

---

## §2 Current-state facts (verified 2026-07-11; grep symbols, expect line drift)

- Layout-box family reads `@bounds` (absolute in the widget's own plane, integer):
  `src/basic-widgets/Widget.coffee` — `bounds:` (~:59), accessors `left/top/…` (~:669-694),
  `boundingBox: -> @bounds`, `position: -> @bounds.origin`.
- Screen family today: `Widget::localPointToScreen` (walks `@parent` chain, applies each
  non-identity island's FORWARD `transformSpec.mapPoint`, innermost→outermost; returns the SAME
  object off-island ⇒ byte-identical dormant) and `Widget::screenPointToMyPlane` (the inverse,
  outermost-first `inverseMapPoint`). Both near `Widget.coffee:~1246-1318`. Damage-lane sibling:
  `Widget::mapRectToScreen` — maps a rect AND intersects the outermost island's
  `clippedThroughBounds()` (ancestor clips) — that clip intersection is CORRECT for damage and
  WRONG for a public footprint query (§3.1 must not reuse it as-is).
- Transform getters today: NONE public. `Widget.rotationHalo_currentDegrees` (~:1360) =
  `@_enclosingSugarIsland()?.transformSpec.rotationDegrees ? 0` — consumer-named, halo-internal.
  Setters `setRotationDegrees`/`setScaleFactor` (4C sugar) are public.
- Predicates: `Widget::_enclosingNonIdentityIsland` (~:1329) / `_isInsideNonIdentityIsland`
  (~:1320) — private (`_`-prefixed ⇒ macros cannot call them, layering rule [D]).
- The Σ-degrees/∏-scales accumulation walk is INLINED in ≥2 places:
  `Widget::_pickOutRotatedFigureNoSettle` (~:1496 — `sStar`/`degStar` loop, normalization
  `((degStar % 360) + 360) % 360`) and the 4D-2b-i drop-time plane accumulation (grep the drop
  path / `_reExpressFigure` in `src/ActivePointerWdgt.coffee` + `Widget.coffee` — landed after
  this plan's last full read; find it, don't assume its shape).
- `TransformSpec` (`src/TransformSpec.coffee`): scalars canonical; `mapPoint`/`inverseMapPoint`;
  `mapRect` returns the **integer, floor/ceil'd, +1px-PADDED** AABB (damage semantics —
  `_mapRectWithMatrix` ~:157-168); `_anchorFor(slotBounds)` (nil anchor ⇒ slot centre; §7.5 Bug D
  made PINNED (non-nil) anchors a real population — everything must route through `_anchorFor`,
  never assume centre).
- Name-collision greps (2026-07-11, re-run at execution): `screenBounds`, `accumulatedRotation*`,
  `accumulatedScale*` — zero hits; `\.rotationDegrees\b` property reads exist ONLY on
  TransformSpec instances (`transformSpec.`/`spec.`); `scaleFactor` appears only in the 4C
  setters. All proposed names are free.
- Codebase constraints that shape this unit: the **dead-methods gate** (build-time) rejects
  methods with no callers — every new method lands WITH its first caller in the same commit; the
  **layering textual scanner** false-trips on name collisions between a member's setters and
  self-settling wrappers (Phase-3 lesson — getters are reads, expected safe, but re-check the
  build gates); **adding Widget methods shifts the inspector member-list macro**
  (`macroDuplicatedInspectorDrivesCopiedTargetOnly` image_2/3) — a benign, pre-authorized
  recapture; batch ALL Widget additions in ONE commit to pay it once; **CoffeeScript `%%` is
  BANNED** (runtime ReferenceError) — use the `((x % 360) + 360) % 360` idiom exactly as pick-out
  does; **macros may not read `_`-prefixed members** — the new API is deliberately macro-callable.

---

## §3 The API (exact specs)

### 3.1 `Widget::screenBounds()` → Rectangle

The screen-plane axis-aligned bounding box of my layout box under all ancestor transforms.

- Semantics: start `r = @boundingBox()`; walk `@parent` chain; for each ancestor
  `TransformFrameWdgt` with a non-identity spec, `r = <exact AABB of the 4 corners of r mapped
  through island.transformSpec.matrixForSlot(island.bounds)>`; innermost→outermost (same walk
  order as `localPointToScreen`). **NO ancestor-clip intersection** (that is `mapRectToScreen`'s
  damage-lane job, §2) and **NO padding/rounding** — this is an exact, possibly-FRACTIONAL
  Rectangle (document at the method: screen-family values are fractional; NEVER feed them to
  layout/`moveTo`).
- Identity fast path: no non-identity ancestor island ⇒ return `@boundingBox()` (the same object,
  matching `boundingBox`'s own convention and `localPointToScreen`'s zero-alloc dormancy).
- Requires a new exact-AABB rect map on TransformSpec: `TransformSpec::mapRectExact(r, slotBounds)`
  — identical to `_mapRectWithMatrix` minus the `Math.floor(minX)-1` / `Math.ceil(maxX)+1`
  padding (return the raw float min/max corners). First caller: `screenBounds()`. Do NOT change
  `mapRect` (damage depends on its padding).
- For an untransformed widget: `screenBounds() == boundingBox()` — assert in the macro.
- For the ISLAND itself: its own `bounds` (slot box) is parent-plane geometry; `screenBounds()` on
  an island maps through its ANCESTORS only (the walk starts at `@parent`) — correct: an island's
  own transform applies to its CONTENT, not to its slot box.

### 3.2 `Widget::rotationDegrees()` → number, `Widget::scaleFactor()` → number

The widget's OWN sugar transform — getter symmetry with the 4C setters
`setRotationDegrees`/`setScaleFactor` (they read what the setters wrote):
`@_enclosingSugarIsland()?.transformSpec.rotationDegrees ? 0` and
`…?.transformSpec.scale ? 1`. Returns 0/1 for a bare widget, and for a widget that is island
CONTENT of an EXPLICIT (non-sugar) island (the sugar getters mirror the sugar setters' scope —
document this at the method).

### 3.3 `Widget::accumulatedRotationDegrees()` → number, `Widget::accumulatedScaleFactor()` → number

The TOTAL visual transform of my rendering: Σ `rotationDegrees` (normalized
`((x % 360) + 360) % 360`) and ∏ `scale` over ALL ancestor non-identity islands (sugar AND
explicit) — exactly the linear part of the accumulated similitude
(`docs/plans/affine-transforms-plan.md` 4D-2a key finding: scalar rotations commute; no matrices).
Spec = the existing `_pickOutRotatedFigureNoSettle` walk, extracted verbatim.

### 3.4 `Widget::isVisuallyTransformed()` → boolean

Public, macro-callable predicate: true iff at least one STRICT ancestor island has a non-identity
spec — i.e. "my layout-box geometry does not coincide with my screen appearance". For an island
itself: false (its slot box IS plane geometry — its content is what transforms). Implementation:
delegate to `_enclosingNonIdentityIsland()?` (keep the private one; the public method is the
blessed name).

### 3.5 Refactors — the first callers (dead-methods gate) + DRY

1. `_pickOutRotatedFigureNoSettle`: replace the inline `sStar`/`degStar` loop with
   `@accumulatedScaleFactor()` / `@accumulatedRotationDegrees()` (byte-equivalent math — the
   normalization moves inside the getter).
2. The 4D-2b-i drop-time PLANE accumulation (grep it, §2): replace its inline Σ/∏ over the
   TARGET's ancestors with `target.accumulatedRotationDegrees()` / `target.accumulatedScaleFactor()`.
   (Verify the 2b-i code accumulates over the same population — ancestor non-identity islands of
   the drop target — before swapping; if it differs, STOP and record why instead of forcing it.)
3. `rotationHalo_currentDegrees`: becomes a one-line alias of `rotationDegrees()` (keep the
   `rotationHalo_*` name — it is the documented halo-consumer family).
4. `rotationHalo_screenAnchor`: IF not already fixed by the Bug D/E unit (§5 step 0 checks),
   re-route through the true anchor: the enclosing sugar island's
   `transformSpec._anchorFor(island.bounds)` mapped via `island.localPointToScreen(...)` (the
   anchor is the island-map's fixed point, so mapping through the island itself is unnecessary —
   `localPointToScreen` starting at `island.parent` is exactly right). Fall back to the current
   centre-based value only for the bare-widget (no island) case.
5. `screenBounds()`'s own first non-test caller: prefer re-routing an existing internal
   screen-footprint consumer if one is trivially equivalent (candidate: the 4B halo/handle
   PLACEMENT math if it computes a mapped footprint; check) — otherwise the macros are the
   callers, which the dead-methods gate accepts only if it scans test code too: **verify how the
   gate counts callers BEFORE relying on macro-only callers** (grep `buildSystem/` for the
   dead-methods scan scope; if it is src-only, wire `screenBounds()` into
   `rotationHalo_screenAnchor`'s bare-widget fallback or another genuine consumer, and say so in
   the commit message).

### 3.6 Documentation deliverables (same commit)

- `docs/plans/affine-transforms-plan.md`: add a short **§4.13 "Public geometry API contract"** that
  states the law in two sentences and POINTS HERE (this doc stays canonical). Append a line to
  the §7 banked list marking this plan as the API unit (or flip it to LANDED when done).
- `Fizzygum/CLAUDE.md`: ONE line next to the integer-placement convention: widgets are placed and
  sized in integer pixels **in their own plane**; screen-family queries
  (`screenBounds`/`localPointToScreen`/…) are derived, post-transform, possibly fractional — see
  `docs/archive/affine-geometry-api-plan.md`.
- Method-level doc comments on every §3 method restating their family membership (the comment IS
  the contract's enforcement surface until a lint exists — a naming lint is NOT in scope).

---

## §4 Macro plan (value-assert; the API is deliberately macro-callable — no `_` reads)

One new macro, `SystemTest_macroGeometryApiTwoVocabularies` (plus reuse of an existing fixture
style: a box in a rotated island, a NESTED island pair, and a sugar-tilted window):

1. **Law, layout side:** wrap a 100×80 box via `setRotationDegrees 30` (+ a `setScaleFactor 2`
   variant) → assert `width()`/`height()`/`bounds` are UNCHANGED by the transform (100/80), before
   and after.
2. **Law, screen side:** `screenBounds()` equals (within ε=0.001) the AABB of the 4 corners of
   `boundingBox()` each mapped via `localPointToScreen` — an INDEPENDENT cross-check of the same
   quantity through the other public method.
3. **Untransformed identity:** for a bare widget, `screenBounds()` equals `boundingBox()` exactly.
4. **Accumulation (nested):** build island-in-island (explicit 20° wrapping content that is
   sugar-tilted 15°, or the 4D nested fixture idiom) → inner content's
   `accumulatedRotationDegrees() == 35`, `accumulatedScaleFactor()` == the product; its
   `rotationDegrees()` (own sugar) reports only its own 15.
5. **Predicate matrix:** `isVisuallyTransformed()` — bare: false; island content: true; the
   island itself: false; nested content: true; after de-tilt to identity (sugar dissolves): false.
6. **Pinned-anchor case (ties to §7.5 Bug D):** tilt a window, collapse it (pins the anchor) →
   `screenBounds()` still equals the corner-mapped cross-check (2.), and the halo screen anchor
   equals the mapped pinned anchor, NOT the mapped centre.
7. Screenshot(s) only where they add signal (the rotated fixtures already have reference
   coverage elsewhere; this macro is primarily value-assert — keep it reference-light).

Refactor safety nets (no new tests needed): pick-out and 2b-i behavior is already pinned by
`macroTransformFramePickOutStaysRotated`, the 2b-i drop-back macros, and the halo macros — the
§3.5 refactors must leave ALL of them byte-identical (they are pure-equivalent rewrites).

---

## §5 Execution steps (ordered; one unit, one commit, gate-green)

0. **Pre-flight:** confirm the affine arc units this plan is sequenced AFTER are landed (top
   banner of `docs/plans/affine-transforms-plan.md`); re-run the §2 collision greps; check whether
   `rotationHalo_screenAnchor` was already anchor-fixed by the Bug D/E unit; locate the 2b-i
   plane-accumulation code; determine the dead-methods gate's scan scope (§3.5.5).
1. `TransformSpec::mapRectExact` (+ its doc comment: exact/unpadded, screen-family backing store).
2. The five `Widget` methods (§3.1–3.4) with contract doc comments.
3. The §3.5 refactors.
4. `./fg build` — all build gates (syntax, layering, dead-methods, thin-wraps) green.
5. The §4 macro via `/author-macro-test`; run it single first
   (`node scripts/run-macro-test-headless.js SystemTest_macroGeometryApiTwoVocabularies --dpr=1`).
6. Docs (§3.6).
7. `./fg gauntlet` (dpr1/dpr2/webkit + apps/paint/tiernaming/settle/capstone, in the BACKGROUND)
   + `./fg homepage`. Expected reference deltas: EXACTLY ONE — the inspector member-list
   recapture (pre-authorized benign; dpr1+2, then re-run the WebKit leg — recapture gotcha).
   Any OTHER reference change means a refactor was not pure — find and fix, do not recapture.
8. ONE commit (source + tests + docs) under the standing grant; update the affine plan banner +
   the memory topic file (`affine-transforms-plan-authored.md`) with the landing note. Do NOT push.

**Done-criteria:** gauntlet green ×3 engines + homepage; the law documented in three places
(this doc normative, affine-plan §4.13 pointer, CLAUDE.md one-liner); zero inline Σ/∏ walks left
(`grep -n "sStar\|degStar" src/` returns nothing); `rotationHalo_screenAnchor` anchor-correct;
the new macro green at dpr1+2+webkit.

---

## §6 Anti-scope (record, do not do)

- NO inspector changes of any kind (owner exclusion, §1.3).
- NO screen-space movers, NO `screenQuad`, NO `fullScreenBounds`, NO vector/rect inverse maps, NO
  `TransformSpec.compose` (§1.3 deferred list — each needs a real consumer and its own decision).
- NO naming lint for the law in this unit (comment-level enforcement only; a `check-layering`-style
  rule is a possible future follow-on — bank it in the affine plan §7 if desired).
- NO renaming of the island's internal two-faces methods (§1.2 — documented exception, not a wart
  to fix).

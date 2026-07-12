# Layering & method-naming convention — the `_`/`__` tier scheme + the geometry-apply 2×2 + the notification grid

**What this is.** The durable reference for Fizzygum's layout/structure method-naming convention: the `_`/`__` tier
scheme and the two method families that ride it — the **geometry-APPLY 2×2** (how a widget applies geometry to
*itself*) and the **NOTIFICATION grid** (how widgets tell *each other* a structural/geometric event happened) — plus
how the convention is enforced **statically** (the `check-layering.js` rules) and **at runtime** (two off-by-default
audit gates). Both families ride one tier scheme (§1) and one enforcement pattern (§4–§5).

**What this is NOT.** It is not the build-gate *mechanics* — for how the line scanner works, the full rule list
[A]–[O] (the flow-soundness rules [A]–[H] as well as the naming rules), the markers, and how to extend/debug the gate,
see **`docs/lint-and-static-checks.md`** (that doc owns the gate; this one owns the convention the naming rules
enforce). It is not the runtime layout architecture either — for the flush model and the convergence invariant see
`docs/layout-system-architecture-assessment.md`.

> **The principle.** Tier/privacy is signalled ONE way (underscore depth), each behavioural axis is spelled ONE way,
> and **the name encodes the behaviour** — so the gate can enforce the lattice by checking callee NAMES, without type
> inference. `raw`/`silent`/`full` never appear in geometry names (`raw*` survives only as the pixel accessors).

---

## 1. The tier scheme — underscore depth

- **`name`** — public API, user-meaningful. No leaked internals (`full`/`raw`/`silent` never appear).
- **`_name`** — internal apply / orchestrator: calls other internals, has side effects, may schedule/settle.
- **`__name`** — **leaf primitive**: a true bottom that **triggers no downstream orchestration** (rule **[I]**). Via
  `@`-self it must NOT call the re-fit seam (`_reFitContainer*` / the `_announce*` announce-up), a react step
  (`changed` / `fullChanged` / `_reLayoutSelf` / `_reLayoutChildren` / `_reLayoutScrollbars` / `_reLayout`), a
  schedule/settle verb (`_invalidateLayout` / `recalculateLayouts` / `_settleLayoutsAfter*`), or any public setter. It
  MAY read fields, call pure accessors, do Point/Rectangle/Array math, recurse into other `__`, and do cache hygiene +
  counter bumps. This is a **DENYLIST** of orchestration verbs (deliberately NOT "calls only `__`" — a line scanner
  can't type the receiver of `aPoint.round()` / `@children.forEach`, and a genuine leaf legitimately reads a
  polymorphic accessor and clears a cache); it is `@`-self-scoped.

Tier depth strictly INCREASES down a call chain — e.g. `setExtent` (public) → `_settleLayoutsAfter` (`_`) →
`_applyExtent` (`_`) → `__commitExtent` (`__`) — which is the readable-depth goal. **Tier follows behaviour:**
the tier of a method is determined by what it does (leaf vs orchestrator vs public), never by a `raw`/`silent`/`full`
fragment.

---

## 2. Family 1 — the geometry-apply 2×2 (REACT × DISPATCH)

### 2.1 Why a 2×2
An immediate geometry **apply** that REACTS is split by **two independent booleans**:
- **REACT** — `changed()` repaint + `_reLayoutSelf()` (extent) / children-translate (move). `commit<Geom>` = no react,
  `apply<Geom>` = react.
- **DISPATCH** — is this the **polymorphic** entry (the override dispatch point a subclass specializes), or the
  override-**BYPASS** base the top-down arrange uses to place a child WITHOUT re-entering its subclass apply-override?
  Bare `_apply<Geom>` = polymorphic; `_apply<Geom>Base` = bypass.

The lattice's *third* boolean — **NOTIFY** (fire the up-notify seam so a size-tracking container re-fits) — is **GONE**:
the seam was deleted 2026-07-01 (the settle loop now re-fits containers after their content settles) and its
`…AndNotify` suffix was renamed away 2026-07-02 (Tier B — see the note below). **Only the leaf** (no react) is `__`;
any corner that REACTS is `_`, because `changed`/`_reLayout*` are orchestration a `__` may not trigger.

### 2.2 The corners

| corner (REACT / DISPATCH) | extent / bounds / width / height | move |
|---|---|---|
| **leaf** (`__`, no react) | `__commitExtent` · `__commitWidth` · `__commitHeight` | `__commitMoveBy` · `__commitMoveTo` |
| **silent commit** (`_`, no react) | `_commitBounds`¹ | *(n/a — a move always repaints)* |
| **apply — polymorphic** (`_`, reacts, DISPATCH point) | `_applyExtent` · `_applyBounds` · `_applyWidth` · `_applyHeight` | `_applyMoveBy` · `_applyMoveTo` |
| **apply — bypass** (`_`, reacts, override-BYPASS base) | `_applyExtentBase` | `_applyMoveByBase` · `_applyMoveToBase` |
| **public** | `setExtent` · `setBounds` · `setWidth` · `setHeight` | `moveTo` · `moveWithin` |

Only extent / moveBy / moveTo carry a `*Base` bypass twin — those are the corners with live subclass overrides the
top-down arrange must skip (extent: the stretchables / stack / scroll / text / slider / list; move: the clipping mixin
+ float-drag). Bounds / width / height are polymorphic-only (no override to bypass). (`moveWithin` is a public
CONVENIENCE that delegates to the one-settle `moveTo`, so it is deliberately NOT in the gate's `PUBLIC_SETTERS` —
listing it would false-trip rule [C] on its `moveWithin → moveTo` call.)

> **Tier B — the `*AndNotify` rename + MEANING SWAP (2026-07-02).** With the NOTIFY seam deleted (2026-07-01) the
> `…AndNotify` suffix asserted a mechanism that no longer existed, on the most-called API in the layout system. The
> polymorphic full mutators **dropped** it (`_applyExtentAndNotify` → **`_applyExtent`**; likewise
> moveTo / moveBy / bounds / width / height), and the override-bypass base twins **took** a `Base` suffix (bare
> `_applyExtent` / `_applyMoveBy` / `_applyMoveTo` → **`_applyExtentBase` / `_applyMoveByBase` / `_applyMoveToBase`**).
> **⚠ MEANING SWAPPED:** the bare names `_applyExtent` / `_applyMoveBy` / `_applyMoveTo` *previously* named the **bypass**
> corner and *now* name the **polymorphic** form — a git-history or pre-2026-07-02 doc/memory hit reading `_applyExtent`
> silently means the OTHER (now-`*Base`) method. (The `_commit*AndNotify` corners had already collapsed 2026-07-01:
> `_commitExtentAndNotify` → the `__commitExtent` leaf; `_commitBoundsAndNotify` + the silent bounds twin → one
> **`_commitBounds`** — ¹ a silent origin+extent commit, leaf-like but single-`_` because it composes the extent leaf.)
> The *move* twins did **NOT** collapse: polymorphic `_applyMoveBy` is the dispatch point for the
> ClippingAtRectangularBoundsMixin / ActivePointerWdgt move overrides (they repaint via `@changed`, not `@fullChanged`),
> whereas `_applyMoveByBase` is the uniform base translate the arrange needs for leaf children — a genuine dispatch
> distinction, not a redundant twin. See `layout-optimizations-and-oo-cleanup-plan.md` §3.

### 2.3 Core vs convenience
Scheme ② names the four CORNER PRIMITIVES. The many *convenience/composite* movers and setters that merely delegate to
a corner just drop any prefix and become plain `_<verb>` (no `Base` suffix — they delegate to the polymorphic corner and
inherit its behaviour): the movers `_moveLeftSideTo` · `_moveRightSideTo` · `_moveTopSideTo` · `_moveBottomSideTo` · `_moveToSideOf`
· `_moveFullCenterTo` · `_moveWithin` · `_moveInDesktopToFractionalPosition` ·
`_moveInStretchablePanelToFractionalPosition`; the setters/resizer `_setWidthSizeHeightAccordingly` ·
`_setExtentToFractionalExtentInPaneUserHasSet` · `_resizeToWithoutSpacing`.

### 2.4 The `__` leaf atom set
Each is a true bottom (satisfies §1 / rule [I]):
- the geometry leaves `__commitExtent` (reads `@minimumExtent` inline), `__commitWidth` / `__commitHeight`,
  `__commitMoveBy` / `__commitMoveTo`;
- the cache atom `__breakMoveResizeCaches` (cache hygiene only — `@invalidateFull{,Clipped}BoundsCache` + the
  `WorldWdgt` move/resize counter bump; NOT orchestration, and those bounds caches are LIVE — do not delete them);
- the relayout-enqueue atom `__markForRelayout` (the no-climb enqueue);
- the structural leaves `__hide`, `__addShadow`, `__add` — the no-side-effect cores their public siblings
  (`hide` / `addShadow` / `add`) wrap with a `fullChanged()` repaint; the depth chain is e.g. `add → _addNoSettle → __add`.

### 2.5 The settle tier (orthogonal)
`_settleLayoutsAfter` (single-mutation flush) is the SETTLE axis — the mechanism the `*NoSettle` cores are named
against — not a geometry-apply primitive, so the 2×2 does not touch it. It stays **`_`** (an internal orchestrator:
it drives `recalculateLayouts` + the `_recalculatingLayouts` re-entrancy token; never `__`, never public). `*NoSettle`
marks the *property* "nothing downstream settles" and is twin-optional (a structural core can carry it with no public
twin, e.g. `_addInPseudoRandomPositionNoSettle`). *(The `_settleLayoutsAfterBatch` nested-absorbing tier was deleted
2026-07-01 — zero callers; reintroduce from git history if ever needed.)*

**The TWO sanctioned settle-thunk shapes** (what may legitimately sit inside a `_settleLayoutsAfter` thunk —
rationale recorded 2026-07-12 during the public/private call-separation arc, answering "why isn't the thunk
always a `*NoSettle` core?"):
1. **The public wrapper** — `foo: -> @_settleLayoutsAfter => @_fooNoSettle args`: a public mutation verb over its
   OWN core; `check-thin-wraps.js` enforces this exact pairing whenever a `_<name>NoSettle` twin exists.
2. **The dispatcher around a notification hook** — `@_settleLayoutsAfter => counterparty?._reactTo<Event>? @`:
   a gesture/lifecycle DISPATCHER settling around a §3 callback. The hook is settle-neutral **by rule [J]**
   (deliberately NOT `NoSettle`-suffixed — §3.2), so it plays the same role as a core inside the thunk; there is
   no self-core to name because the callee is the counterparty's polymorphic hook. Confined to the re-parent
   gestures — `ActivePointerWdgt.grab`/`.drop` (trailing `_reactToChildGrabbed`/drop re-fits) and `Widget.pickUp`
   (`_reactToChildPickedUp`) — where the body is an inherent SEQUENCE of settles (grab hand-rolls its own), so a
   `_<name>NoSettle` restructure is impossible without re-entering the flush guard. Fenced from three sides:
   [J] (static), the notification-settle runtime audit (dynamic), and rule [T] (a subject that double-settles
   on `@`-self). Anything not matching either shape is a smell — see `check-layering.js` [T] and
   `check-call-separation.js` [S].

**Sibling on the SETTLE axis — the reactive-connector lane** (`connection-cascade-settle-fix-plan.md`,
2026-07-03): `_settleLayoutsAfterOrJoinEnclosingPass` is `_settleLayoutsAfter` minus the MUTATION-WINDOW throw —
reached inside an enclosing settle's mutation window (`world._inLayoutMutation`) it JOINS it (runs the
`_<name>NoSettle` core in it) rather than throwing; reached from inside the flush walk itself
(`world._recalculatingLayouts`) it KEEPS the strict lane's orphan-defer + throw. It backs a dedicated
`_<name>Connector` entrypoint (e.g. `_setTextConnector`) — the reactive-connection twin of the public setter,
carrying the same `connectionsCalculationToken` cycle-guard — which a connection cascade dispatches to via
`ControllerMixin._fireConnection` (a per-call `_<action>Connector`-or-`@action` name resolution), so a wired circuit
settles ONCE (the first connector opens the one settle; every later wired hop joins it). (Complement: a node's DIRECT
self-render — a reactive text-write that is NOT dynamic dispatch, e.g. a patch node's `recalculateOutput` writing its
own result box — ALSO goes through the connector `_setTextConnector`, not the bare core: a cascade does not always
carry an open settle, so the connector correctly OPENS one when none is open and JOINS when one is — byte-faithful to
the old direct `setText` render minus the throw.) Opt-in per entrypoint and gated to `_<name>Connector` callers by
check-layering rule **[P]** (§4); the plain `_settleLayoutsAfter` stays the *throwing* lane for general/internal code.

### 2.6 The container re-fit — the settle-time up-edge (seam DELETED 2026-07-01)
A size-tracking container (a window fitting its stack, a scroll frame fitting its content) must re-fit when the
content it tracks changes size. This *was* a notify-by-mutation **seam** — the content's mutator announced up to the
container mid-arrange — and it was **DELETED 2026-07-01** (the endgame's "proven irreducible" verdict was
over-general). It is replaced by a **settle-time up-edge** in the settle loop: after the loop `_reLayout`s a
chain-top, it calls `_reFitMyTrackingContainerAfterSettle`, which — *iff the chain-top's frame actually changed* —
re-fits the container through the **retained** `_reFitContainer(container)` phase-valve → in-pass `__markForRelayout`
/ off-pass `_invalidateLayout` → container `_reLayoutChildren`. Because the container reads the chain-top's *final*,
just-settled geometry (not a half-applied mid-arrange value), it re-fits correctly in one visit — a bounded O(depth)
up-walk, no per-mutation notification (§2.3; assessment §4.1). The layout-**property** dependency (a freefloating
child's stack align / elasticity / base-width) instead flows through the **uniform dirty-tree**: `_invalidateLayout`
climbs THROUGH a freefloating boundary off-pass when the parent is a size-tracking container.

The two announce-up verbs are **deleted** and are now BANNED as DEFs by rule **[N]** (do not revive them):
`_announceGeometryChangeToContainer` (geometry) and `_announceLayoutPropertyChangeToContainer` (a layout property).
One verb of the family was **renamed** in the Tier B sweep (2026-07-02):
- `_reflowContainedTextThenAnnounce` → **`_reflowContainedTextThenInvalidateLayout`** — self-reflow contained text, then
  invalidate. **Still live** (`StringWdgt` + ~7 sites); its old "Announce" tail named the deleted seam, so the rider
  renamed it to the dirty-tree-climb verb it actually ends in (`layout-optimizations-and-oo-cleanup-plan.md` §3).

The valve `_reFitContainer` and the react-down `_reLayoutChildren` are the apply side (§2.2 / the `_reLayout*`
layout-method family) — retained, now driven by the up-edge rather than by the mutators.

### 2.7 PaintBounds — the repaint dirty-region vocabulary
The broken-rectangles repaint loop uses a **`PaintBounds`** vocabulary (`paintBoundsMaybeChanged` /
`hasMaybeChangedPaintBounds` / the `Full` variants / `widgetsWithMaybeChangedPaintBounds`). This keeps three formerly
collision-named "dirty" subsystems self-evident:
- **PaintBounds** — repaint dirty-regions (this vocabulary);
- **Layout** — the layout-invalidation queue (`layoutIsValid` / `widgetsThatMaybeChangedLayout`) — distinct, left as-is;
- **GeometryChange** — the container re-fit up-edge (§2.6).

---

## 3. Family 2 — the notification grid `(perspective × phase)` over canonical events

How widgets tell *each other* that a structural/geometric EVENT happened (drag/drop/grab/pickup, add/remove/close/
destroy/collapse/uncollapse, z-order, copy, the geometry seam). The behaviour is uniform — a single **dispatcher owns
exactly one `_settleLayoutsAfter`**, the callbacks being settle-neutral cores inside it (the gestures hand-roll the
settle in `ActivePointerWdgt.grab`/`.drop`; the structural ops wrap it in a public `verb()` over a `_verbNoSettle()`
core). So this family is pure naming + a settle-discipline (rule [J]).

### 3.1 The decomposition
Every notification is `(event × perspective × phase)`:
- **EVENT** — `Added` · `Removed` · `Grabbed` · `PickedUp` · `Dropped` · `Closed` · `Destroyed` · `Collapsed` ·
  `UnCollapsed` · `MovedToFront` · `Copied` · `GeometryChange`. (An event may be qualified — e.g.
  `AddedInScrollPanel`, `DroppedIntoFolder`.)
- **PERSPECTIVE** — **self** (the widget the event happens to) · **container** (a parent, about its child) · a
  **third party** (a holder window, about a widget it hosts).
- **PHASE** — **gate** (pre-event predicate) · **pre** (before-hook) · **post** (after-hook).

### 3.2 The grid
`(perspective)(phase)` over a canonical PascalCase `<Event>`, fully derivable:

| | SELF (`Being`) | CONTAINER (`Child`) |
|---|---|---|
| **gate** — pure bool, **public**, positive | `wantsToBe<Event>ed()` | `wants<Event>OfChild(child)` |
| **pre-hook** — `_`, settle-neutral | `_beforeBeing<Event>ed(counterparty)` | `_beforeChild<Event>ed(child)` |
| **post-hook** — `_`, settle-neutral | `_reactToBeing<Event>ed(counterparty)` | `_reactToChild<Event>ed(child)` |

Plus the **third-perspective** hooks `_reactToHolderWindow<Event>(…)` (a widget reacting to its holder window's event).

Rules:
- **Tier = `_`** for every hook (an internal override protocol); **gates are public + pure + positive** (queried by
  the dispatcher, no side effects).
- **No `NoSettle` on a callback** — it is a settle-neutral core by definition; the DISPATCHER owns the one settle
  (rule [J]). (`NoSettle` stays reserved for the public-setter cores of §2.5.)
- **Argument convention:** a self-hook receives the COUNTERPARTY (the other container); a container-hook receives the
  CHILD.
- **Optional dispatch** (`?` soak) is the norm — sparse overrides; most events have no base def. A hook with no
  implementor is dead weight (fill the ⌀ gaps on demand, not pre-emptively).
- **Pairing is visible:** `_reactToBeingDropped` ↔ `_reactToChildDropped`.

### 3.3 Boundaries
- **grab ≠ pickUp.** The grab/pickUp family is EXCLUSIVELY the **float-drag** case: the widget DETACHES off its parent
  into the hand (gated by `detachesWhenDragged()`). A **non-float drag** (sliders, resize handles) leaves the widget IN
  PLACE and uses the SEPARATE `nonFloatDragging` / `endOfNonFloatDrag` family, firing NONE of these notifications — so
  dragging a slider is NOT a pickup. `grab` (mouse) and `pickUp` (programmatic) are two entry points to "detach into
  hand" whose hook sets OVERLAP, not coincide, so they stay DISTINCT events (merging them is a behaviour change, not a
  rename).
- **Capability predicates stay as-is** — `imposesRatioConstraintOnDroppedChildren` /
  `releasesRatioConstraintOnGrabbedChildren`, `isDesktopShortcut` / `isShortcutTo` are capability *queries*, not phase
  hooks, so they are outside the grid.

---

## 4. Static enforcement — `check-layering.js`

The convention is unusually enforceable because the name encodes the behaviour, so most checks reduce to
NAME-CONSISTENCY of the call graph (no type inference). These are the **naming** rules; the full rule list, the tier
predicates, the markers, and the gate mechanics live in `docs/lint-and-static-checks.md`.

| Rule | Checks |
|---|---|
| **[I]** `__` leaf no-orchestration (HARD-FAIL) | inside a `__` method, an `@`-self call to the re-fit seam (`_reFitContainer*`/`_announce*`), a react step (`_reLayout*`/`changed`/`fullChanged`), a schedule/settle (`_invalidateLayout`/`recalculateLayouts`/`_settleLayoutsAfter*`), or a public setter → FAIL. A DENYLIST (§1), `@`-self-scoped; the runtime audit (§5) covers dynamic dispatch. |
| **[J]** callback settle-neutrality (HARD-FAIL) | a `_reactTo*`/`_before*` hook calling `_settleLayoutsAfter` in its OWN body → FAIL (the dispatcher owns the one settle). *(Textual rule; a constructor reached via dynamic dispatch FROM a callback is the runtime audit's concern, §5.2 — which now PERMITS the orphan-construction case, since it auto-defers.)* |
| **[K]** apply-2×2 name-consistency (HARD-FAIL) | the surviving statically-sound NEGATIVE (post-Tier-B, REACT × DISPATCH): a `_apply*Base` override-bypass twin must not fire the container re-fit seam nor DISPATCH to its polymorphic `_apply*` sibling (routing an arrange apply back through the override it exists to bypass); a `_commit*AndNotify` notify-only corner must not react (`changed`/`_reLayout*`). The old POSITIVE "every `*AndNotify` reaches the seam" is RETIRED with the seam (it was the runtime audit's job — §5). *(The anti-seam half is VACUOUS — the `_announce*` seam and the `_commit*AndNotify` corner were deleted 2026-07-01 — kept only as belt-and-braces beside rule [N]. Tier B (2026-07-02) renamed `_apply*AndNotify` → the bare polymorphic `_apply*` and re-derived this row under the truthful names; `AndNotify` now joins the [M] retired-fragment ban, §3.)* |
| **[L]** callback-shape (HARD-FAIL) | at each def, a `_reactTo*`/`_before*` name MUST match `_(reactTo\|before)(Being\|Child\|HolderWindow)<Event>` and carry no `NoSettle`; the legacy fragments (`childX` / `justBeen` / `iHaveBeen` / `aboutTo` / `prepareTo`) are banned outright. |
| **[M]** retired-fragment ban (HARD-FAIL) | a method DEF named with a retired geometry/structural prefix — `raw[A-Z]…` / `^silent[A-Z]` / `^fullRaw` → FAIL, unconditionally in src (the raw-PIXEL accessors `rawPixelInfo` / `rawPixelHash` / `rawRGBA` live in the tests-repo harness, which the gate never scans — the old allowlist for them never matched anything and was removed). `full[A-Z]` is NOT banned — `full*` remains a legitimate SUBTREE-AWARE vocabulary (`fullChanged` / `fullBounds` / `fullPaintInto` / …). |
| **[N]** seam-verb DEF ban (HARD-FAIL) | a method DEF named `_announce…ToContainer` (`/^_announce\w*ToContainer$/`) → FAIL — the notify-by-mutation re-fit seam was deleted 2026-07-01 (§2.6) and replaced by the settle-time up-edge, so this bans reviving the retired announce-up verbs on the DEF side (the CALL side is already covered by the [I]/[K] denylists). Analogous to [M]'s retired-fragment ban. |
| **[O]** `*Coalesced` caller allowlist (HARD-FAIL) | a `*Coalesced` entrypoint (`_setMaxDimCoalesced` / `_setExtentCoalesced` / `_moveToCoalesced` / `_setWidthCoalesced` / `_setHeightCoalesced`) DEFERS its layout SETTLE to the ONE end-of-cycle flush (the field write is synchronous; only the flush is deferred) — byte-identical, hence sound, ONLY for a per-event STREAM handler (drag/scroll/key burst) that never reads back the SETTLED layout mid-cycle. So a `[@.]…Coalesced` CALL from a method whose name is NOT in `COALESCED_CALLER_ALLOWLIST` (seeded `{nonFloatDragging}` — both `HandleWdgt` and `StackElementsSizeAdjustingWdgt` name their drag handler that) → FAIL; a discrete/programmatic caller must use the self-settling setter. These entrypoints are `_`-private for the same reason (only stream handlers may reach them). The `_coalescedDeclarationDepth`/`auditUndeclaredEndOfCycle` machinery enforces the CONVERSE (end-of-cycle mutations are *declared*), so this closes the caller side it does not cover. (Tier C, 2026-07-02.) |
| **[P]** connector-join caller (HARD-FAIL) | a `[@.]_settleLayoutsAfterOrJoinEnclosingPass` CALL from a method whose name does NOT end `Connector` → FAIL. That primitive is the reactive-connection settle lane (§2.5): reached mid-pass it JOINS the open layout pass instead of throwing — sound ONLY for a dedicated `_<name>Connector` entrypoint carrying the `connectionsCalculationToken` cycle-guard (so a wired reactive circuit — the °C↔°F converter, `src/apps/DegreesConverterApp.coffee` — settles once). Any other caller must use the self-settling `_settleLayoutsAfter` (which *surfaces* the flow violation) or a `_<name>NoSettle` core. Modelled on [O]; self-test by planting `@_settleLayoutsAfterOrJoinEnclosingPass => …` in a non-`Connector` method. |

The convention is also why the flow rules work: because every immediate geometry mutator is recognizably low-level
(`_`/`__`-prefixed or `*NoSettle`) and named in the apply 2×2, rules **[A]** (low-level must not reach the public
self-flushing layer) and **[E]** (an immediate mutator must MUTATE, never SCHEDULE) have no blind spot. See
`docs/lint-and-static-checks.md` §2/§4 for `isLowLevel` / `isImmediateMutator` and rules [A]–[H].

**DOC-only (un-mechanizable — stated, not enforced):** that public names are genuinely "user-meaningful"; whether a
method is genuinely a leaf vs should be split (rule [I] enforces the call-graph property, not design intent); the
core-vs-convenience choice; which ⌀ notification gaps are worth filling.

---

## 5. Runtime enforcement — the two audit gates

The static name-consistency catches mislabels a scanner can see; RUNTIME verifies the name matches what the body
ACTUALLY does (the ground truth — indirect/dynamic-dispatch paths the scanner can't follow). Each audit mirrors the
established pattern (`auditUndeclaredEndOfCycle` / `auditPaintTimeLayoutScheduling`): an off-by-default `WorldWdgt` flag
that a gate prelude flips on, instrumentation installed once at boot behind the flag (a wrap, not a hot-path branch),
run over the WHOLE suite by a standalone `run-*-gate.sh` — siblings of `run-capstone-gate.sh` /
`run-paint-readonly-gate.sh`, and wired into `fg gauntlet`.

### 5.1 `auditTierAndApplyNaming` — the apply 2×2 (runtime twin of [I]/[K])
`Fizzygum-tests/scripts/tier-naming-audit/` (prelude + `run-tier-naming-gate.sh`). It wraps every apply-2×2 corner +
the seam (`_announce*`) + the react steps across all classes, and:
- **HARD-fails the unconditional NEGATIVES** (sound): a `__commit*` leaf that fired the seam or a react step in its own
  scope (not a true bottom); a `_apply*Base` bypass twin that fired the seam (it reacts only — seam-dead post-2026-07-01,
  so the live catch is the leaf's react-half). These catch a dynamic-dispatch override the scanner can't follow.
- **Reports the [K] POSITIVE as INFORMATIONAL** (does NOT fail; RETIRED with the seam — now vacuously 0-reached): how many `_apply*` corners were observed reaching
  the seam (transitively). A runtime observation CANNOT soundly distinguish a mislabeled corner from one whose
  seam-firing path simply was not exercised (a move corner only announces when the move changes the container's
  layout) — so "never reached" is a REVIEW HINT, not a failure.

### 5.2 `auditNotificationSettleNeutrality` — the callbacks (runtime twin of [J])
`Fizzygum-tests/scripts/notification-settle-audit/` (prelude + `run-notification-settle-gate.sh`). It wraps every
`_reactTo*`/`_before*` callback + the settle tiers across the suite and HARD-fails a callback that OPENS A FLUSH — an
ATTACHED-receiver `_settleLayoutsAfter` (it would throw) or any `recalculateLayouts`. It catches an INDIRECT leak the
static [J] cannot see (a callback → some method → an attached settle). **It PERMITS an ORPHAN-receiver
`_settleLayoutsAfter` reached in a callback** (the all-constructors-settle campaign, 2026-06-30): that is a constructor
settling its OWN orphan — e.g. the chrome buttons `WindowWdgt._reactToChildDropped → _buildAndConnectChildrenNoSettle →
new …IconButtonWdgt`, whose ctor calls the settling `@_buildAndConnectChildren()`. Such a call provably takes the
in-flush+orphan auto-defer branch (`return coreThunk() if @isOrphan()`) — it records the change, never flushes/recurses
— so flagging it was a false positive (the gate's old premise "a nested settle in a callback would re-enter/throw" is
false for an orphan). The discipline is unchanged — a callback still must not OPEN A FLUSH; an orphan construction
simply doesn't. *(Superseded earlier model: a constructor was required to reach `@_addNoSettle` directly and NOT settle;
it now settles via the wrapper, which auto-defers here. See `docs/all-constructors-settle-plan.md`.)*

Both gates are self-tested (plant a violation, confirm the gate throws) and run green; both require their prelude to
have installed on every test (a coverage gap fails the gate, so a silent miss can't mask a violation).

---

## 6. Scope & non-goals
- **SAFE under method renames:** the dependency-finder (scans `extends`/`@augmentWith`/`new`, not method names) and
  serialization (`DeepCopierMixin` copies data, not method names) are unaffected.
- **Naming + tier-reclassification only — no behaviour change.** Pixels stay identical except inspector member lists
  (method names show in the Object Inspector, so a rename of an inspected class's own method forces a benign reference
  recapture).
- **grab/pickUp stay DISTINCT** (§3.3) — a true unification is a separate, behaviour-verified change.
- **NON-GOAL:** the non-float-drag family (`nonFloatDragging` / `endOfNonFloatDrag`) — already consistent, a separate
  concern, left alone.
- **Out of scope:** the repaint-cache data-FIELD naming (a separate data-field convention, distinct from these METHOD
  families); and the layout-invalidation queue's `Layout` vocabulary (`layoutIsValid` / `widgetsThatMaybeChangedLayout`)
  — already distinct from PaintBounds, a future `needsLayout`/`hasDirtyDescendant` rename is a separate item.

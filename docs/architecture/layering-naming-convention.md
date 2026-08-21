# Layering & method-naming convention — the `_`/`__` tier scheme + the geometry-apply 2×2 + the notification grid

**What this is.** The durable reference for Fizzygum's layout/structure method-naming convention: the `_`/`__` tier
scheme and the two method families that ride it — the **geometry-APPLY 2×2** (how a widget applies geometry to
*itself*) and the **NOTIFICATION grid** (how widgets tell *each other* a structural/geometric event happened) — plus
how the convention is enforced **statically** (the `check-layering.js` rules) and **at runtime** (two off-by-default
audit gates). Both families ride one tier scheme (§1) and one enforcement pattern (§4–§5).

**What this is NOT.** It is not the build-gate *mechanics* — for how the line scanner works, the full rule list
[A]–[R] plus [T] (the flow-soundness rules [A]–[H] as well as the naming rules), the markers, and how to extend/debug the gate,
see **`docs/architecture/lint-and-static-checks.md`** (that doc owns the gate; this one owns the convention the naming rules
enforce). It is not the runtime layout architecture either — for the flush model and the convergence invariant see
`docs/archive/layout-system-architecture-assessment.md`.

> **The principle.** Tier/privacy is signalled ONE way (underscore depth), each behavioural axis is spelled ONE way,
> and **the name encodes the behaviour** — so the gate can enforce the lattice by checking callee NAMES, without type
> inference. `raw`/`silent`/`full` never appear in geometry names (`raw*` survives only as the pixel accessors).

---

## 1. The tier scheme — underscore depth

- **`name`** — public API, user-meaningful. No leaked internals (`full`/`raw`/`silent` never appear).
- **`_name`** — internal apply / orchestrator: calls other internals, has side effects, may schedule/settle.
- **`__name`** — **leaf primitive**: a true bottom that **triggers no downstream orchestration** (rule **[I]**). Via
  `@`-self it must NOT call the re-fit seam (`_reFitContainer*` / the `_announce*` announce-up), a react step
  (`_changed` / `_fullChanged` / `_reLayoutSelf` / `_reLayoutChildren` / `_reLayoutScrollbars` / `_reLayout` — the
  repaint half of that arm is enforced at RUNTIME only, see rule [I] in §4), a
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
- **REACT** — `_changed()` repaint + `_reLayoutSelf()` (extent) / children-translate (move). `commit<Geom>` = no react,
  `apply<Geom>` = react.
- **DISPATCH** — is this the **polymorphic** entry (the override dispatch point a subclass specializes), or the
  override-**BYPASS** base the top-down arrange uses to place a child WITHOUT re-entering its subclass apply-override?
  Bare `_apply<Geom>` = polymorphic; `_apply<Geom>Base` = bypass.

The lattice's *third* boolean — **NOTIFY** (fire the up-notify seam so a size-tracking container re-fits) — is **GONE**:
the seam is deleted (the settle loop re-fits containers after their content settles) and its `…AndNotify` suffix was
renamed away with it (Tier B — see the note below). **Only the leaf** (no react) is `__`;
any corner that REACTS is `_`, because `_changed`/`_reLayout*` are orchestration a `__` may not trigger.

### 2.2 The corners

| corner (REACT / DISPATCH) | extent / bounds / width / height | move |
|---|---|---|
| **leaf** (`__`, no react) | `__commitExtent` · `__commitWidth` · `__commitHeight` | `__commitMoveBy` · `__commitMoveTo` |
| **silent commit** (`_`, no react) | `_commitBounds`¹ | *(n/a — a move always repaints)* |
| **apply — polymorphic** (`_`, reacts, DISPATCH point) | `_applyExtent` · `_applyBounds` · `_applyGrantedBounds` · `_applyWidth` · `_applyHeight` | `_applyMoveBy` · `_applyMoveTo` |
| **apply — bypass** (`_`, reacts, override-BYPASS base) | `_applyExtentBase` | `_applyMoveByBase` · `_applyMoveToBase` |
| **public** | `setExtent` · `setBounds` · `setWidth` · `setHeight` | `moveTo` · `moveWithin` |

Only extent / moveBy / moveTo carry a `*Base` bypass twin — the corners the top-down arrange must be able to place a
child through WITHOUT re-entering a subclass apply (extent overrides: the tracking-transform island / scroll / text /
list; moveBy overrides: the transform island + the clipping mixin; moveTo has no polymorphic override today, but its
`*Base` twin is itself overridden by the transform island to ride its pinned anchor).
Bounds / width / height are polymorphic-only (no override to bypass). The bounds corner has two
apply forms: `_applyBounds` — `setBounds`'s twin, a subtree-FOLLOWING place+size one-shot for the ubiquitous
`_applyMoveTo p; _applyExtent e` idiom — and `_applyGrantedBounds`, the arrange engine's frame-commit whose
translate deliberately does NOT carry children (the widget re-places them from the new frame right after). (`moveWithin` is a public
CONVENIENCE that delegates to the one-settle `moveTo`, so it is deliberately NOT in the gate's `PUBLIC_SETTERS` —
listing it would false-trip rule [C] on its `moveWithin → moveTo` call.)

> **⚠ MEANING SWAPPED — the one date worth carrying, because it is what you need to read old material.** The bare
> names `_applyExtent` / `_applyMoveBy` / `_applyMoveTo` *previously* named the **bypass** corner and *now* name the
> **polymorphic** form: the polymorphic mutators **dropped** an `…AndNotify` suffix that asserted the deleted seam, and
> the override-bypass twins **took** the `Base` suffix. So a git-history or pre-2026-07-02 doc/memory hit reading
> `_applyExtent` silently means the OTHER (now-`*Base`) method.
> ¹ The `_commit*AndNotify` corners collapsed with the seam: `_commitExtentAndNotify` → the `__commitExtent` leaf;
> `_commitBoundsAndNotify` + the silent bounds twin → one **`_commitBounds`**, a silent origin+extent commit, leaf-like
> but single-`_` because it composes the extent leaf. The *move* twins did **NOT** collapse: polymorphic `_applyMoveBy`
> is the dispatch point for the ClippingAtRectangularBoundsMixin / TransformFrameWdgt move overrides (the clipping one
> repaints via `@_changed`, not `@_fullChanged`; the island rides its pinned anchor), whereas `_applyMoveByBase` is the
> uniform base translate the arrange needs for leaf children — a genuine dispatch distinction, not a redundant twin.

### 2.3 Core vs convenience
Scheme ② names the four CORNER PRIMITIVES. The many *convenience/composite* movers and setters that merely delegate to
a corner just drop any prefix and become plain `_<verb>` (no `Base` suffix — they delegate to the polymorphic corner and
inherit its behaviour): the movers `_moveLeftSideTo` · `_moveRightSideTo` · `_moveTopSideTo` · `_moveBottomSideTo` · `_moveToSideOf`
· `_moveFullCenterTo` · `_moveWithin` · `_moveInDesktopToFractionalPosition` (the desktop imposes position only —
the stretchable panel's own two imposers died with `StretchLayoutSpec`, which grants whole boxes through the child's
`_reLayout` instead); the setters/resizer `_setWidthSizeHeightAccordingly` · `_resizeToWithoutSpacing`.

### 2.4 The `__` leaf atom set
Each is a true bottom (satisfies §1 / rule [I]):
- the geometry leaves `__commitExtent` (reads `@minimumExtent` inline), `__commitWidth` / `__commitHeight`,
  `__commitMoveBy` / `__commitMoveTo`;
- the cache atom `__breakMoveResizeCaches` (cache hygiene only — one `WorldWdgt.geometryVersion` bump, which expires
  every version-keyed bounds cache at once, under the load-bearing empty-hand carve-out; NOT orchestration, and those
  bounds caches are LIVE — do not delete them);
- the relayout-enqueue atom `__markForRelayout` (the no-climb enqueue);
- the structural leaves `__hide`, `__addShadow`, `__add` — the no-side-effect cores their public siblings wrap:
  `addShadow` adds a `_fullChanged()` repaint, `hide` a `_fullChangedIncludingShadowOwner()`, and `add` a SETTLE
  rather than a repaint (its repaint lives in the core), which is why its depth chain has three levels:
  `add → _addNoSettle → __add`.

### 2.5 The settle tier (orthogonal)
`_settleLayoutsAfter` (single-mutation flush) is the SETTLE axis — the mechanism the `*NoSettle` cores are named
against — not a geometry-apply primitive, so the 2×2 does not touch it. It stays **`_`** (an internal orchestrator:
it drives `recalculateLayouts` + the `_recalculatingLayouts` re-entrancy token; never `__`, never public). `*NoSettle`
marks the *property* "nothing downstream settles" and is twin-optional (a structural core can carry it with no public
twin, e.g. `_addInPseudoRandomPositionNoSettle`). *(The `_settleLayoutsAfterBatch` nested-absorbing tier is deleted —
zero callers; reintroduce from git history if ever needed.)*

**The TWO sanctioned settle-thunk shapes** (what may legitimately sit inside a `_settleLayoutsAfter` thunk,
answering "why isn't the thunk always a `*NoSettle` core?"):
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

**Sibling on the SETTLE axis — the reactive-connector lane.**
`_settleLayoutsAfterOrJoinEnclosingPass` is `_settleLayoutsAfter` minus the MUTATION-WINDOW throw —
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

### 2.6 The container re-fit — the settle-time up-edge (the notify-by-mutation seam is DELETED)
A size-tracking container (a window fitting its stack, a scroll frame fitting its content) must re-fit when the
content it tracks changes size. This *was* a notify-by-mutation **seam** — the content's mutator announced up to the
container mid-arrange — and it is **DELETED** (the endgame's "proven irreducible" verdict was
over-general). It is replaced by a **settle-time up-edge** in the settle loop: after the loop `_reLayout`s a
walk-visited node (EVERY such node, since the ordered down-walk — assessment §2.3), it calls
`_reFitMyTrackingContainerAfterSettle`, which — *iff that node's frame actually changed* —
re-fits the container through the **retained** `_reFitContainer(container)` phase-valve → in-pass `__markForRelayout`
/ off-pass `_invalidateLayout` → container `_reLayoutChildren`. Because the container reads the node's *final*,
just-settled geometry (not a half-applied mid-arrange value), it re-fits correctly in one visit — a bounded O(depth)
up-walk, no per-mutation notification (§2.3; assessment §4.1). The layout-**property** dependency (a freefloating
child's stack align / elasticity / base-width) instead flows through the **uniform dirty-tree**: `_invalidateLayout`
climbs THROUGH a freefloating boundary off-pass when the parent is a size-tracking container.

The two announce-up verbs are **deleted** and are now BANNED as DEFs by rule **[N]** (do not revive them):
`_announceGeometryChangeToContainer` (geometry) and `_announceLayoutPropertyChangeToContainer` (a layout property).
One verb of the family was **renamed** rather than deleted in the Tier B sweep:
- `_reflowContainedTextThenAnnounce` → **`_reflowContainedTextThenInvalidateLayout`** — self-reflow contained text, then
  invalidate. **Still live** (`StringWdgt` + a handful of sites); its old "Announce" tail named the deleted seam, so the
  rider renamed it to the dirty-tree-climb verb it actually ends in.

The valve `_reFitContainer` and the react-down `_reLayoutChildren` are the apply side (§2.2 / the `_reLayout*`
layout-method family) — retained, now driven by the up-edge rather than by the mutators.

### 2.7 PaintBounds — the paint-extent tracking vocabulary
The vocabulary law is settled: **pixels say *damage*, layout says *dirty*** (the law itself lives in
`docs/architecture/appearance-paint-convention.md`). **`PaintBounds`** is a third, legitimately distinct thing — a
widget's own *painted extent tracking*: the per-widget "my painted extent may have moved" flags
(`paintBoundsMaybeChanged` / `hasMaybeChangedPaintBounds` / the `Full` variants /
`widgetsWithMaybeChangedPaintBounds`) that the flesh-out consumes when it derives the frame's damage rectangles. It
is not a second spelling of either half of the law, and it does not name the damage rect list itself. Its one
near-neighbour is the layout-invalidation queue on the *dirty* side, which stays distinct: `layoutIsValid` /
`widgetsThatMaybeChangedLayout`.

---

## 3. Family 2 — the notification grid `(perspective × phase)` over canonical events

How widgets tell *each other* that a structural/geometric EVENT happened (drag/drop/grab/pickup, add/remove/close/
destroy/collapse/uncollapse, z-order, copy). The container re-fit is deliberately NOT in this family — it is the
settle-time up-edge (§2.6), a valve call from the settle loop, not a notification. The behaviour is uniform — a single **dispatcher owns
exactly one `_settleLayoutsAfter`**, the callbacks being settle-neutral cores inside it (the gestures hand-roll the
settle in `ActivePointerWdgt.grab`/`.drop`; the structural ops wrap it in a public `verb()` over a `_verbNoSettle()`
core). So this family is pure naming + a settle-discipline (rule [J]).

### 3.1 The decomposition
Every notification is `(event × perspective × phase)`:
- **EVENT** — `Added` · `Removed` · `Grabbed` · `PickedUp` · `Dropped` · `Closed` · `Destroyed` · `Collapsed` ·
  `UnCollapsed` · `MovedToFront` · `Copied`. (An event may be qualified — e.g.
  `AddedInScrollPanel`, `DroppedIntoFolder`.)
- **PERSPECTIVE** — **self** (the widget the event happens to) · **container** (a parent, about its child) · a
  **third party** (a holder window, about a widget it hosts).
- **PHASE** — **gate** (pre-event predicate) · **pre** (before-hook) · **post** (after-hook).

### 3.2 The grid
`(perspective)(phase)` over a canonical PascalCase `<Event>`, fully derivable:

| | SELF (`Being`) | CONTAINER (`Child`) |
|---|---|---|
| **gate** — pure bool, **public**, positive | `wantsToBe<Event>()` | `wants<Verb>OfChild(child)` |
| **pre-hook** — `_`, settle-neutral | `_beforeBeing<Event>(counterparty)` | `_beforeChild<Event>(child)` |
| **post-hook** — `_`, settle-neutral | `_reactToBeing<Event>(counterparty)` | `_reactToChild<Event>(child)` |

Plus the **third-perspective** hooks `_reactToHolderFrame<Event>(…)` (a widget reacting to its holder window's event).

Rules:
- **`<Event>` is already the past participle** (`Dropped`, `PickedUp`, `MovedToFront`) — the hooks append nothing.
  The one exception is the CONTAINER gate, which reads as a question about an incoming action and so takes the bare
  verb: `wantsDropOfChild` / `wantsDetachOfChild`.
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
predicates, the markers, and the gate mechanics live in `docs/architecture/lint-and-static-checks.md`.

| Rule | Checks |
|---|---|
| **[I]** `__` leaf no-orchestration (HARD-FAIL) | inside a `__` method, an `@`-self call to the re-fit seam (`_reFitContainer*`/`_announce*`), a react step (`_reLayout*`/`_changed`/`_fullChanged`), a schedule/settle (`_invalidateLayout`/`recalculateLayouts`/`_settleLayoutsAfter*`), or a public setter → FAIL. A DENYLIST (§1), `@`-self-scoped; the runtime audit (§5) covers dynamic dispatch. *(⚠ the repaint half of this arm is currently carried by the RUNTIME audit alone — §5.1 — because the scanner's alternation spells the two verbs without their leading underscore and so predates the `_changed`/`_fullChanged` privatisation.)* |
| **[J]** callback settle-neutrality (HARD-FAIL) | a `_reactTo*`/`_before*` hook calling `_settleLayoutsAfter` in its OWN body → FAIL (the dispatcher owns the one settle). *(Textual rule; a constructor reached via dynamic dispatch FROM a callback is the runtime audit's concern, §5.2 — which now PERMITS the orphan-construction case, since it auto-defers.)* |
| **[K]** apply-2×2 name-consistency (HARD-FAIL) | the surviving statically-sound NEGATIVE (post-Tier-B, REACT × DISPATCH): a `_apply*Base` override-bypass twin must not fire the container re-fit seam nor DISPATCH to its polymorphic `_apply*` sibling (routing an arrange apply back through the override it exists to bypass); a `_commit*AndNotify` notify-only corner must not react (`_changed`/`_reLayout*`). The old POSITIVE "every `*AndNotify` reaches the seam" is RETIRED with the seam (it was the runtime audit's job — §5). *(The anti-seam half is VACUOUS — the `_announce*` seam and the `_commit*AndNotify` corner are both deleted — kept only as belt-and-braces beside rule [N]. The Tier B sweep renamed `_apply*AndNotify` → the bare polymorphic `_apply*` and re-derived this row under the truthful names; `AndNotify` now joins the [M] retired-fragment ban, §3.)* |
| **[L]** callback-shape (HARD-FAIL) | at each def, a `_reactTo*`/`_before*` name MUST match `_(reactTo\|before)(Being\|Child\|HolderFrame)<Event>` and carry no `NoSettle`; the legacy fragments (`childX` / `justBeen` / `iHaveBeen` / `aboutTo` / `prepareTo`) are banned outright. |
| **[M]** retired-fragment ban (HARD-FAIL) | a method DEF named with a retired geometry/structural prefix — `raw[A-Z]…` / `^silent[A-Z]` / `^fullRaw` → FAIL, unconditionally in src (the raw-PIXEL accessors `rawPixelInfo` / `rawPixelHash` / `rawRGBA` live in the tests-repo harness, which the gate never scans — the old allowlist for them never matched anything and was removed). `full[A-Z]` is NOT banned — `full*` remains a legitimate SUBTREE-AWARE vocabulary (`fullBounds` / `_fullChanged` / `fullPaintIntoAreaOrBlitFromBackBuffer` / …). |
| **[N]** seam-verb DEF ban (HARD-FAIL) | a method DEF named `_announce…ToContainer` (`/^_announce\w*ToContainer$/`) → FAIL — the notify-by-mutation re-fit seam is deleted (§2.6) and replaced by the settle-time up-edge, so this bans reviving the retired announce-up verbs on the DEF side (the CALL side is already covered by the [I]/[K] denylists). Analogous to [M]'s retired-fragment ban. |
| **[O]** `*DeferredSettle` caller allowlist (HARD-FAIL) | a `*DeferredSettle` entrypoint (`_setMaxDimDeferredSettle` / `_setExtentDeferredSettle` / `_moveToDeferredSettle` / `_setWidthDeferredSettle` / `_setHeightDeferredSettle`) DEFERS its layout SETTLE to the ONE end-of-cycle flush (the field write is synchronous; only the flush is deferred) — byte-identical, hence sound, ONLY for a per-event STREAM handler (drag/scroll/key burst) that never reads back the SETTLED layout mid-cycle. So a `[@.]…DeferredSettle` CALL from a method whose name is NOT in `DEFERRED_SETTLE_CALLER_ALLOWLIST` (seeded `{nonFloatDragging}` — both `HandleWdgt` and `StackElementsSizeAdjustingWdgt` name their drag handler that) → FAIL; a discrete/programmatic caller must use the self-settling setter. These entrypoints are `_`-private for the same reason (only stream handlers may reach them). The `_deferredSettleDeclarationDepth`/`auditUndeclaredEndOfCycle` machinery enforces the CONVERSE (end-of-cycle mutations are *declared*), so this closes the caller side it does not cover. |
| **[P]** connector-join caller (HARD-FAIL) | a `[@.]_settleLayoutsAfterOrJoinEnclosingPass` CALL from a method whose name does NOT end `Connector` → FAIL. That primitive is the reactive-connection settle lane (§2.5): reached mid-pass it JOINS the open layout pass instead of throwing — sound ONLY for a dedicated `_<name>Connector` entrypoint carrying the `connectionsCalculationToken` cycle-guard (so a wired reactive circuit — the °C↔°F converter, `src/examples/degrees-converter/DegreesConverterApp.coffee` — settles once). Any other caller must use the self-settling `_settleLayoutsAfter` (which *surfaces* the flow violation) or a `_<name>NoSettle` core. Modelled on [O]; self-test by planting `@_settleLayoutsAfterOrJoinEnclosingPass => …` in a non-`Connector` method. |
| **[Q]** connector-CALLER (HARD-FAIL) | a hard-coded `[@.]_<name>Connector` CALL from a method not in `CONNECTOR_CALLER_ALLOWLIST` (seeded `{recalculateOutput}`) → FAIL. A connector entrypoint JOINS an open pass instead of throwing, so textually reaching one is a way to smuggle "a setText that never throws" past the flow guard; the ONLY legitimate textual caller is a patch node rendering its OWN output mid-cascade. The reactive dispatch (`ControllerMixin._fireConnection`) resolves the name at RUNTIME and is invisible to the scanner either way. The direct sibling of [P]: [P] guards the join PRIMITIVE, [Q] the entrypoints built on it. |

The convention is also why the flow rules work: because every immediate geometry mutator is recognizably low-level
(`_`/`__`-prefixed or `*NoSettle`) and named in the apply 2×2, rules **[A]** (low-level must not reach the public
self-flushing layer) and **[E]** (an immediate mutator must MUTATE, never SCHEDULE) have no blind spot. See
`docs/architecture/lint-and-static-checks.md` §2/§4 for `isLowLevel` / `isImmediateMutator` and rules [A]–[H].

**DOC-only (un-mechanizable — stated, not enforced):** that public names are genuinely "user-meaningful"; whether a
method is genuinely a leaf vs should be split (rule [I] enforces the call-graph property, not design intent); the
core-vs-convenience choice; which ⌀ notification gaps are worth filling.

---

## 5. Runtime enforcement — the two audit gates

The static name-consistency catches mislabels a scanner can see; RUNTIME verifies the name matches what the body
ACTUALLY does (the ground truth — indirect/dynamic-dispatch paths the scanner can't follow). Each audit is a PRELUDE
that wraps prototypes once, before the page's own scripts run, and a standalone `run-*-gate.sh` that plays the WHOLE
suite under it and reads what the wrappers logged — siblings of `run-capstone-gate.sh` / `run-paint-readonly-gate.sh`,
and wired into `fg gauntlet`.
⚠ **These two gates carry no `WorldWdgt` flag, and that is the design rather than an omission.** They once mirrored the
`auditUndeclaredEndOfCycle` pattern — an off-by-default flag a prelude flips on, with the recording behind it — but the
observation moved entirely into the prelude's own wrappers, which never consult a flag. The two vestigial flags were
deleted once measurement showed nothing read them. `auditUndeclaredEndOfCycle` (capstone) is the pattern's one live
member: there the RECORDING really does sit in product code behind the flag.

### 5.1 tier-naming — the apply 2×2 (runtime twin of [I]/[K])
`Fizzygum-tests/scripts/tier-naming-audit/` (prelude + `run-tier-naming-gate.sh`). It wraps every apply-2×2 corner +
the seam (`_announce*`) + the react steps across all classes, and:
- **HARD-fails the unconditional NEGATIVES** (sound): a `__commit*` leaf that fired the seam or a react step in its own
  scope (not a true bottom); a `_apply*Base` bypass twin that fired the seam (it reacts only — and the seam is dead,
  so the live catch is the leaf's react-half). These catch a dynamic-dispatch override the scanner can't follow.
- **Reports the [K] POSITIVE as INFORMATIONAL** (does NOT fail; RETIRED with the seam — now vacuously 0-reached): how many `_apply*` corners were observed reaching
  the seam (transitively). A runtime observation CANNOT soundly distinguish a mislabeled corner from one whose
  seam-firing path simply was not exercised (a move corner only announces when the move changes the container's
  layout) — so "never reached" is a REVIEW HINT, not a failure.

### 5.2 notification-settle — the callbacks (runtime twin of [J])
`Fizzygum-tests/scripts/notification-settle-audit/` (prelude + `run-notification-settle-gate.sh`). It wraps every
`_reactTo*`/`_before*` callback + the settle tiers across the suite and HARD-fails a callback that OPENS A FLUSH — an
ATTACHED-receiver `_settleLayoutsAfter` (it would throw) or any `recalculateLayouts`. It catches an INDIRECT leak the
static [J] cannot see (a callback → some method → an attached settle). **It PERMITS an ORPHAN-receiver
`_settleLayoutsAfter` reached in a callback** (the all-constructors-settle campaign): that is a constructor
settling its OWN orphan — e.g. the chrome buttons `FrameWdgt._reactToChildDropped → _buildAndConnectChildrenNoSettle →
new …IconButtonWdgt`, whose ctor calls the settling `@_buildAndConnectChildren()`. Such a call provably takes the
in-flush+orphan auto-defer branch (`return coreThunk() if @isOrphan()`) — it records the change, never flushes/recurses
— so flagging it was a false positive (the gate's old premise "a nested settle in a callback would re-enter/throw" is
false for an orphan). The discipline is unchanged — a callback still must not OPEN A FLUSH; an orphan construction
simply doesn't. *(Superseded earlier model: a constructor was required to reach `@_addNoSettle` directly and NOT settle;
it now settles via the wrapper, which auto-defers here. See `docs/archive/all-constructors-settle-plan.md`.)*

Both gates are self-tested (plant a violation, confirm the gate throws) and run green; both require their prelude to
have installed on every test (a coverage gap fails the gate, so a silent miss can't mask a violation).

---

## 6. Container roles — deliberately NOT one mega-container

The same "the name encodes the role" principle governs the CONTAINER classes, and it settles a standing
proposal. The 2017 ZombieKernel "V2" diagram (row **F** of the container-regularization scorecard,
`docs/archive/container-regularization-plan.md` §3.7) floated **one general container that becomes a
window / pinnable-window** via a mode flag. Fizzygum deliberately does **NOT** merge them — the roles are
kept distinct, each named for what it is:

- **`PanelWdgt`** — the general **clipping container** (the `ClippingAtRectangularBoundsMixin` home; 12 subclasses).
  No transient/pin behaviour, no chrome.
- **`PopUpWdgt`** — `extends Widget`: **transient / pin / drop-shadow** and nothing else. After the container arc
  (§5.2/§5.3 of the plan) this is the SINGLE shared home of pop-up behaviour: `MenuWdgt` and `PromptWdgt` (with its
  per-value-type subclasses) each **compose** a `MenuRowsPanelWdgt` for their rows and **extend**
  `PopUpWdgt` for their menu-ness, instead of re-implementing pop-up / pin / close.
- **`FrameWdgt`** — `extends Widget`: **chrome / identity**, holding a clipping panel for its content; its
  internal-vs-external skin is DERIVED from parentage (the drag-embed arc), so "becomes a window when embedded" is
  already automatic — there is no mode flag and no manual switch.
- **`StretchableWidgetContainerWdgt`** — the stretchable-panel role's chrome; the fractional-consuming container
  itself is its `StretchablePanelWdgt` child.

A single mode-flagged mega-container would re-introduce exactly the per-mode special-casing this whole arc
REMOVED (the byzantine `isListContents` flag was that same anti-pattern one level down — a container role
smuggled in as a boolean). The regularity win is **naming the relationship between the container roles**, not
collapsing them into one flag-driven class. (Re-open only on an explicit owner request → a separate design
spike, flagged not dropped.)

---

## 7. Scope & non-goals
- **SAFE under method renames:** the dependency-finder (scans `extends`/`@augmentWith`/`new`, not method names) and
  the serialization/duplication engines (the `Serializer`/`Deserializer` pair and the `Duplicator` copy data, not
  method names) are unaffected.
- **Naming + tier-reclassification only — no behaviour change.** Pixels stay identical except inspector member lists
  (method names show in the Object Inspector, so a rename of an inspected class's own method forces a benign reference
  recapture).
- **grab/pickUp stay DISTINCT** (§3.3) — a true unification is a separate, behaviour-verified change.
- **NON-GOAL:** the non-float-drag family (`nonFloatDragging` / `endOfNonFloatDrag`) — already consistent, a separate
  concern, left alone.
- **Out of scope:** the repaint-cache data-FIELD naming (a separate data-field convention, distinct from these METHOD
  families); and the layout-invalidation queue's `Layout` vocabulary (`layoutIsValid` / `widgetsThatMaybeChangedLayout`)
  — already distinct from PaintBounds, a future `needsLayout`/`hasDirtyDescendant` rename is a separate item.

---

## History & case law

Present-tense truth lives above; the sequencing — which tier renamed what, in which order, and which alternatives
were falsified — is in the archived plans, indexed in `docs/archive/INDEX.md`:

- **`layout-system-architecture-assessment.md`** — the canonical long-form description of the runtime the convention
  serves: the flush model, the convergence invariant, and the verified code map.
- **`layout-optimizations-and-oo-cleanup-plan.md`** — the tier sweep this convention came out of, in order: the
  NOTIFY seam's deletion, then **Tier B** (the `*AndNotify` rename and the ⚠ MEANING SWAP of §2.2, plus the
  `_reflowContainedTextThenAnnounce` rename of §2.6), **Tier C** (the deferred-settle caller allowlist, rule [O]),
  and **Tier I** (the userland-public-API rule [R], `MenusHelper` as the standard-user exemplar).
- **`connection-cascade-settle-fix-plan.md`** — the reactive-connector settle lane (§2.5) and the two rules that
  fence it, [P] (the join primitive) and [Q] (the connector entrypoints); ⚖ rejected: relaxing the general flow
  guard, or dispatching the cascade to the raw core.
- **`all-constructors-settle-plan.md`** — why the notification-settle audit PERMITS an orphan-receiver
  `_settleLayoutsAfter` reached from a callback (§5.2), superseding the model that required a constructor to reach
  `@_addNoSettle` directly.
- **`public-private-call-separation-plan.md`** — the rationale behind the TWO sanctioned settle-thunk shapes (§2.5),
  answering "why isn't the thunk always a `*NoSettle` core?"; the arc also fixed this convention's own churn cost
  (a rename of an inspected class's method forces a benign reference recapture).
- **`container-regularization-plan.md`** — the scorecard whose row F floated the one mode-flagged mega-container
  §6 declines; ⚖ the regularity win is naming the relationship between container roles, not collapsing them.

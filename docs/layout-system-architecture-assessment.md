#  Layout system — architecture assessment

**What this is.** An outside-in architectural review of Fizzygum's layout engine: what it actually does,
whether it is *byzantine* or merely *highly unusual* relative to the field, and where its architecture/flow
could be improved. It is a companion to `deferred-layout-OVERVIEW.md` (which is the canonical record of the
deferral *campaign*); this doc steps back and assesses the *engine* the campaign produced.

**State assessed.** Fizzygum master `c5ae7697` (HEAD as this revision was written, 2026-06-30). The *substantive*
engine state is still that of `95a131b2`: the seventeen commits since are a **naming/terminology campaign** (layering
§6 + notifications §9.7 — the immediate-mutator and callback families renamed, the lint set extended) plus two
behaviour-preserving fixes, none of which touch the algorithm — they are caught up in the **fourth re-grounding wave**
below, and every method name in this doc is now the post-campaign one. The lineage matters
because three successive layout campaigns plus a caret/paint coda shaped this engine in turn: it was first
**written 2026-06-22** against the *deferred-layout* campaign's capstone (`a7463bbc`), with the `_reLayout*`
method-family naming; §2.7 — the *end-of-cycle-flush drawdown* campaign's categories, detection toolkit, and
coalescing API — was **appended 2026-06-26** at master `f4626843`, mid-campaign; that campaign reached its end-state
at **`778a7db5`** (2026-06-27) — the **careless** survivor set driven to zero and a hard-fail **gate** (its own
*capstone*, not to be confused with the deferred-layout capstone above) shipped to hold it there; a **caret/paint
coda** then played out across four same-day commits (`a424cdb4` → `282ea492`): the caret's scroll-follow was relocated
out of paint behind a sibling **paint-read-only gate** (`a424cdb4`), **folded into the end-of-cycle flush** as the
caret's own `_reLayout` (`d60a0710`, *Option C*), **pinned to settle in-place** during its own event rather than ride
the flush (`20586db1`), and finally **unified with the general layout-enqueue primitive** — the caret schedules
through the one `_invalidateLayout` verb via an inert-receiver branch (`282ea492`) — ending as a normal fixed-point
participant with no `doOneCycle` special-case (§2.1); and most recently the *proper-layouts* campaign — the
longest-running, spanning 2026-06-28 → 2026-06-29 under a standing "**delete** the layout-suppression/convergence
mechanisms, don't relocate them" mandate — which moved through three arcs and then a falsified endgame. **(i)** It
**deleted the `@_adjustingContentsBounds` suppression boolean outright** (`3a1fb165` → `b52a0d6f` → `a5e89d1b`) by
first making the wrapping-text arrange a fixed point (Phase C: delete the height wobble), then deleting the
cross-method seam suppression (Phase D), then the field + its per-arrange re-entrancy guards (Phase E). **(ii)** It
then **built the missing pure *measure*** the assessment had flagged as the highest-leverage change (§4.1): a
side-effect-free `preferredExtentForWidth` on every width→height widget + a base default, consumed in the scroll
panel's content-frame sizing (`a07f534a` → `85d0c186`). **(iii)** It then landed the **non-notifying single-pass
*arrange*** (§4.2 Objective A — the stack and scroll arranges apply their *own* geometry through twins that no longer
fire the re-fit seam at themselves), driving the end-of-cycle **capstone** from 18 careless pushes back to **0 —
green** (`cf37fa3a` → `c8098e6d`). The campaign then probed the *endgame* — deleting the re-fit **seam** itself — and
**closed it as proven-infeasible** (`838ff6e9`, "arc closed"): with the suppression/convergence *waste* gone, the seam
survives carrying only a legitimate, effectively-irreducible multi-widget notification edge (§2.3, §2.6, §4.1). Two
`oo-smells` commits close the campaign window: `467644a5` decoupled the caret from text selection/undo state
(layout-orthogonal — §2.1), and `95a131b2` deleted four dead inspector-visible `Widget` methods. A subsequent
**naming/terminology campaign** (`06578419` → `c5ae7697`, current HEAD) then renamed the low-level geometry family
without changing it — retiring the "raw / silent / fullRaw setter" category-noun for **"immediate (geometry)
mutator"** and giving its members consistent `_apply*AndNotify` / `_commit*AndNotify` / `_move*` / `_set*` / `__*`
names — and extended the build-time layering lint from rules [A]–[H] to [A]–[M]; it is the fourth-wave subject below
and leaves every §2–§5 finding intact. §2.7 folds in the
end-of-cycle campaign's conceptual core — the enqueue-vs-snapshot definition of "careless," the orphan-exclusion
lifecycle it rests on, and the convert implementation hazard that separates a flush-count fix from a correctness one.

**This doc has been re-grounded in four waves; the first three brought it to `95a131b2`, the fourth (this revision)
to `c5ae7697`.** The first wave (the prior re-grounding, to
`282ea492`) caught up renames that had silently drifted since the 2026-06-22 writing: the public-setter tier
`mutateGeometryThenSettle → _settleLayoutsAfter` / `settleLayoutsOnceAfter → _settleLayoutsAfterBatch`, the settle
engine's loop body `_recalculateLayoutsCore → _recalculateLayoutsBody`, and the `invalidateLayout` seam's added
underscore — *all* already in place by the `f4626843` append yet never back-propagated, while `addRaw` was deleted
outright — and corrected the facts that moved with them: the batch tier is now **dormant** (no live callers —
everything self-settles through `_settleLayoutsAfter`), `setMaxDim`/`collapse` were **converted** from end-of-cycle
riders to self-settling mutators, and the caret scroll-follow is **folded into the flush, settled in-place, and
unified onto the one `_invalidateLayout` enqueue verb** (it is now the caret's own `_reLayout`, scheduled via
`_invalidateLayout`'s inert-receiver branch and drained during the caret's event — never the end-of-cycle flush)
while paint stays read-only behind the gate (§2.1). The second wave (this re-grounding, to `a5e89d1b`) folds in the
three *proper-layouts* commits since `282ea492`: they **deleted the `@_adjustingContentsBounds` suppression boolean**
(field + all three per-arrange re-entrancy guards + the cross-method seam check), so every prose reference that
treated it as a *live* mechanism is corrected to describe it as **deleted**, with the notify-by-mutation *seam* it
used to gate left standing (§2.3, §2.6, §4.1, §5). Those three commits drifted the big-file line numbers again — the
`Widget.coffee` 3900–4400 band by ~24 lines — so the appendix (§5) was re-read against `a5e89d1b` accordingly. The
third wave (this re-grounding, to `95a131b2`) folds in the **ten commits since `a5e89d1b`** — the rest of the
*proper-layouts* campaign plus two `oo-smells` commits — and carries the most *substance*, because it catches up work
the prior revision could only call **deferred**: the pure **measure** (§4.1) and the non-notifying single-pass
**arrange** (§4.2 Objective A) both **landed**, so every place that framed them as future work now reports them done;
the end-of-cycle **capstone** is **green again** (the campaign drove it 18 → 10 → 0), so §2.7's "intentionally red — 18
pushes / 10 tests" is corrected to its current **zero**; and the seam-deletion **endgame was attempted and proven
infeasible** (`838ff6e9`), so §4.1/§2.6's "deleting the seam is the real remaining work" is corrected to "**arc
closed** — the seam stays as a legitimate irreducible edge, the convergence *waste* already gone." Line numbers were
re-read against `95a131b2`: the §4.1/§4.2 commits grew `Widget.coffee` (the non-notifying-arrange twins, the measure)
and `ScrollPanelWdgt.coffee`, then `95a131b2`'s dead-method deletion pulled the `Widget.coffee` 1900+/3100+/3800+
bands back up ~47 lines, so the appendix (§5) numbers were current as of `95a131b2`.

**The fourth wave (this revision, to `c5ae7697`) is the largest *renaming* catch-up yet — and the smallest in
*substance*: it touches no algorithm.** The seventeen commits since `95a131b2` are a **naming/terminology campaign**
(build-system "layering §6" + "notifications §9.7") plus two behaviour-preserving fixes, and they comprehensively
renamed the low-level geometry family the doc had called the *"raw / silent / fullRaw setters."* That category-noun is
**retired** (`c5ae7697`) for **"immediate (geometry) mutator"**, and the members got a consistent, intent-revealing
lattice: the notifying setters `rawSet*` / `fullRawMove*` → **`_apply*AndNotify`** (and the notify-only `silentRaw*` →
**`_commit*AndNotify`**); the §4.2 *non-notifying* arrange twins `_arrangeApply*` → the bare **`_apply*`** (so the name
now *says* "applies without notifying"); the shared bottoms → **`__*` leaves** (`_setExtentBoundsNoNotify` →
`__commitExtent`, `_markForRelayoutNoClimb` → `__markForRelayout`); the synchronous read-back setter
`rawSetWidthSizeHeightAccordingly` → `_setWidthSizeHeightAccordingly`; the public movers `fullMoveTo` / `fullMoveWithin`
→ `moveTo` / `moveWithin`; and the re-fit **seam** verbs `_reFitContainerAfterRawGeometryChange` →
**`_announceGeometryChangeToContainer`** and `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` →
`_announceLayoutPropertyChangeToContainer` (the phase-dispatch primitive `_reFitContainer` keeps its name). The
drag/drop/structural **callbacks** were swept too (`childRemoved` / `reactToDropOf` / `reactToGrabOf` / `justDropped` →
`_reactToChildRemoved` / `_reactToChildDropped` / `_reactToChildGrabbed` / `_reactToBeingDropped`). Every prose and
appendix reference below now uses the post-campaign name, with the pre-campaign name noted (née …) where it aids
`grep`-ing older commits. The campaign also **extended the build-time layering lint from rules [A]–[H] to [A]–[M]**
(the additive `[I]` `__`-leaf-purity, `[J]` callback-settle-neutrality, `[K]` apply-2×2 name-consistency, `[L]`
callback-name convention, `[M]` retired-fragment ban; `[H]` is a non-fatal warning) and added **two off-by-default
runtime audit flags** (`auditTierAndApplyNaming`, `auditNotificationSettleNeutrality` — the dynamic-dispatch twins of
`[K]`/`[J]`), so §3's "lints A–H" reads "A–M" and §2.7's detection toolkit gains two siblings. Two
*behaviour-preserving* fixes ride along, and both **sharpen** a §2 finding rather than overturn it: `08bbb29d` swept
twelve constructors' child-adds from the self-settling public `@add` to `_addNoSettle` (a "settle-in-callback" leak —
§2.7's orphan/construction note now states the sharper rule it implies), and `5f923847`/`dd3a5510` cleaned a
*misapplied* `NoSettle` suffix off the drop/grab callbacks (which **corrects** §2.2: `reactToDropOf` was never a
self-settling mutator — the drop *dispatcher* owns the one settle; it is now the settle-neutral `_reactToChildDropped`,
guarded by lint `[J]`). Line numbers were re-read against `c5ae7697`: only `WorldWdgt.coffee` drifted materially (~+15,
from the new audit fields), the `Widget.coffee` apply/seam band (1300–1800) is *unchanged*, its coalescing/measure band
(3800–4200) moved ~+6, and the small files did not move — so the appendix (§5) numbers are current as of this HEAD.

**Update (2026-06-30), post-`c5ae7697`:** three further settle-tier waves landed and §2.2/§2.7 below were updated for
them. (1) **orphan-settledness** (`ce21dcf7`): a *top-level* orphan public call now FLUSHES its own subtree, so
`new Foo()` returns settled (only an orphan call reached *inside* a live flush still defers — `Widget.coffee`
`_settleLayoutsAfter` ~:816). (2) **settle-tier follow-ups** (`f35d7021`): a symmetry-aware dead-methods gate + 40 dead
methods deleted. (3) **all constructors settle** (`docs/all-constructors-settle-plan.md`, HELD): every inline-building
constructor routes through the settling wrapper `_buildAndConnectChildren()` / `_buildScrollFrame()` over its
`_buildAndConnectChildrenNoSettle` core, locked in by a new build gate `buildSystem/check-constructors-build.js`; the
rule-[J] notification-settle runtime gate was made aware of the orphan-construction auto-defer (it now permits an
orphan-receiver settle reached in a callback). Numbers below predate these waves by a few commits — re-grep.

> **Line numbers are approximate — the METHOD NAME is authoritative; `grep` it.** (Same convention as the
> OVERVIEW; every shipped edit shifts lines — the two big files `Widget.coffee` and `WorldWdgt.coffee` drifted
> ~40–190 lines since the 2026-06-22 writing, and the ten commits since `a5e89d1b` — the §4.1 measure, the §4.2
> non-notifying-arrange twins, then `95a131b2`'s dead-method deletion — shifted the `Widget.coffee` and
> `ScrollPanelWdgt.coffee` bands; the fourth-wave naming campaign then *renamed* much of the family with only minor
> line drift, so any older inline name reads off even where its number does not.) Every file:line below was re-read
> against `c5ae7697` source while writing this revision; the small stable files (`VerticalStackLayoutSpec`,
> `LayoutSpec`) did not move. The engine is under active parallel development (the caret/paint coda alone took four
> commits — `a424cdb4` → `d60a0710` → `20586db1` → `282ea492` — the proper-layouts campaign then
> ten more through `95a131b2`: boolean deletion (`3a1fb165` → `a5e89d1b`), §4.1 measure (`a07f534a` → `85d0c186`),
> §4.2 Objective-A arrange (`cf37fa3a` → `c8098e6d`), seam-arc closure (`838ff6e9`), two `oo-smells` commits
> (`467644a5` / `95a131b2`); and a seventeen-commit naming/terminology campaign through `c5ae7697`
> (`06578419` → … → `c5ae7697`)), so treat every number as "as of `c5ae7697`" and re-grep against current HEAD.

---

## 1. Verdict in one paragraph

The layout engine is **not byzantine** — it is a deliberately *unusual* one. Mainstream retained-mode toolkits
(WPF, Flutter, Android, Qt, CSS block/flex) run a structured **two-pass `measure` → `arrange`**: one bottom-up
sizing pass, one top-down positioning pass, both O(n), guaranteed to terminate. Fizzygum instead runs a
**work-list / dirty-set settle that iterates to a fixed point** — the same family as **browser reflow +
invalidation**, **constraint solvers** (Cassowary / Auto Layout), and **spreadsheet/reactive recalculation**.
That is exotic for a GUI toolkit but it is a *recognized* pattern, and most of its complexity is **essential**,
given three hard constraints the design genuinely faces (§3). The genuinely *accidental* complexity is narrow,
and the change the first revisions called the highest-leverage one available — adding the **pure measure pass** the
engine lacked, to retire the **synchronous mutate-then-read-back** content sizing — has since been **built and
consumed** (§4.1, generalizing the clean measure the framework already ran on one of its own code paths, §2.5) and
paired with a **non-notifying single-pass arrange** (§4.2 Objective A) that drove the end-of-cycle careless-push count
to zero. The lasting lesson of that work is what it could *not* do: attempting to delete the residual re-fit **seam**
proved it is not removable waste but a genuine constraint — a multi-widget size↔position notification effectively
irreducible short of re-architecting the settle loop (§2.6, §4.1). So accidental complexity is now paid down with
lints, a determinism soak, and two hard-fail gates; what remains is essential.

---

## 2. What the system actually does

### 2.1 The per-frame spine

`WorldWdgt.doOneCycle` (`src/WorldWdgt.coffee` ~:1350) runs, in order:

```
updateTimeReferences                       (~:1351)
show errors from previous cycle            (~:1353–1354 — incl. layout errors deferred out of the settle loop)
playQueuedEvents()                         (~:1360 — dispatch input)
replayTestCommands / step functions        (~:1364–1372 — animation, stepping widgets)
recalculateLayouts()                       (~:1375 — the engine's end-of-cycle settle)
add pinout/highlight overlays              (~:1390–1392)
updateBroken()                             (~:1395 — paint dirty rectangles)
```

So layout is wedged between input/stepping and paint — and the *intended* invariant is sharper than the listing looks:
**paint reads layout but never *schedules* it** (events fix layout step-by-step, the end-of-cycle settle drains the
rest, then `updateBroken` paints an already-settled world). The caret's **scroll-follow** — "bring the caret into
view," which genuinely *mutates* layout (it moves `@target`/`@contents`) — is the place that exercised this boundary,
and its turbulent same-day arc (2026-06-27, four commits) is instructive. It began *inside* paint (a leak — a
keystroke that scrolled the text scheduled layout from within `updateBroken`); `a424cdb4` **relocated** it to a
dedicated post-flush `doOneCycle` step (a *third* settling mechanism, hand-iterated to a fixed point, alongside
per-event self-settle and the flush); `d60a0710` (*Option C*) **dissolved** that special case by **folding the follow
into the flush itself**; `20586db1` **pinned its draining in-place** (below); and `282ea492` **unified the enqueue
primitive** so the caret schedules through the same `_invalidateLayout` verb as everything else. There is now **no
caret step in `doOneCycle`**. Instead, a caret *move* calls `CaretWdgt._requestScrollFollow` (~:212) — now simply
`@_invalidateLayout()`. The unification recognized that `_invalidateLayout` (~:3898) can take the caret directly: a
**free-floating + inert** receiver (`@isFreeFloating() and @isLayoutInert?()`, ~:3915) hits an **inert-receiver
branch** that pushes via the shared bare-push atom `__markForRelayout` (née `_markForRelayoutNoClimb`, ~:3894) and returns *before* the climb,
the flow-rule throw, and the careless-push audit. Those three don't fire, but they aren't *silenced*: they're
**structurally inapplicable** to an overlay with no parent layout to climb and no ancestor it can re-dirty, so they
simply *pass*. (Gated on **both** predicates, so no content widget — whose container genuinely needs the climb — can
slip onto the no-climb path. Earlier in the coda the caret open-coded that bare push and deliberately *bypassed*
`_invalidateLayout`; the unification folded the two enqueue primitives into one verb plus one atom — the atom now
shared with `_reFitContainer`'s in-pass arm, §2.3.) The caret's `_reLayout` (~:223) then **is** the
scroll-follow: it runs one `_oneScrollCaretIntoViewPassNoSettle` pass (~:257) that re-enqueues the scroll panel
*ahead* of the caret and stays `layoutIsValid == false`, so the until-loop re-runs it after the panel settles —
converging to a fixed point with no hand-rolled loop. The caret is thus a textbook instance of the §2.3 iteration
(freefloating content ↔ its container), not a bespoke mechanism. Folding it in required one purity fix: the
overflow→pop-out-editor hand-off that used to fire from *inside* `slotCoordinates` (a coordinate *read* mutating
state) was hoisted to an explicit event-time step, `StringWdgt.handOffToPopoutEditorIfOverflowing` (~:1401), called
from `CaretWdgt.insert`. (A later `oo-smells` pass — `467644a5`, 2026-06-29 — relocated four *other* caret↔text
reach-ins onto `StringWdgt` the same way — selection anchoring, the remembered caret column, the undo-history reset —
but it is layout-orthogonal: it touches none of the scroll-follow / `_reLayout` / enqueue machinery described here.)

A final tightening (`20586db1`) pins *when* that convergence drains: **in-place, during the caret's own event — never
on the end-of-cycle flush.** A discrete move (click / arrow / Home / End) already self-settled through `gotoSlot` /
`goLeft` / `goRight`; a *typing / delete / paste* advance uses the non-settling `_go*NoSettle` core (so the caret
advance rides the surrounding `setText`'s order, §2.7), which had left the follow to drain *inconsistently* on the
end-of-cycle coalesced flush — where it was the lone entry (q=1). `CaretWdgt._settleScrollFollow` (~:246) —
`return if @layoutIsValid`, else an *empty-core* `@_settleLayoutsAfter => nil` (the enqueue and the inline pass
already ran in the advance; this just drains them) — now runs at the tail of the three caret editing handlers
(`processKeyDown` ~:61, `processCut` ~:133, `processPaste` ~:143) to converge the follow then and there. So the caret
self-settles in-place like every other discrete mutation; the end-of-cycle flush stays only a backstop it no longer
reaches.

What stays at paint is only the **inert** re-sync — `justBeforeBeingPainted → adjustAccordingToTargetText` (~:50/~:45
= re-size to font height + re-place on the current slot). Because the caret is `isLayoutInert` and the re-fit seam
`_announceGeometryChangeToContainer` (née `_reFitContainerAfterRawGeometryChange`) returns early for inert movers
(`Widget.coffee` ~:1719 skip), this re-sync
schedules **no** layout. And the invariant is *checked*: `a424cdb4` promoted the default-off DEBUG audit
`auditPaintTimeLayoutScheduling` (`WorldWdgt.coffee` ~:107) into a **hard-fail gate** —
`run-paint-readonly-gate.sh` + `paint-readonly-prelude.js` (`Fizzygum-tests`) run the whole macro suite with it on and
exit non-zero if *any* widget schedules layout mid-paint. It is the exact sibling of the end-of-cycle capstone gate
(§2.7), one boundary over: that gate enforces "no careless deferral *into* the settle"; this one enforces "no layout
scheduled *during* paint." Net: `doOneCycle` is now purely **process events → fix coalesced layouts → paint**, with no
caret special-case — the events→settle→paint boundary is not merely clean but **checked**, and the caret folds into
the *one* flush rather than adding a settling mechanism of its own.

### 2.2 The flush model — how often layout actually settles

> **Common misreading (worth stating because it is the natural one): "there is one layout flush per frame."
> That is false.** There is one *engine-scheduled* flush per frame; the *total* is generally several.

`recalculateLayouts()` (`WorldWdgt.coffee` ~:911) is invoked from **exactly three** sites — though one of them is
currently dormant:

| # | Site | When | Cardinality |
|---|---|---|---|
| 1 | `WorldWdgt.coffee` ~:1375 (end of `doOneCycle`) | every frame, by the engine | **1 / frame** |
| 2 | `Widget._settleLayoutsAfter` flush ~:838 | every **public geometry/structural mutation** | **1 / mutation** |
| 3 | `Widget._settleLayoutsAfterBatch` flush ~:870 | a **batch** — *0 live callers today* | 1 / batch (dormant) |

The self-settling public API routes through `_settleLayoutsAfter` and therefore **self-settles** — each entry point
records the desired change and then runs a full `recalculateLayouts()` *before returning*. Five are pure-geometry
setters — `setBounds` ~:875, `moveTo` (née `fullMoveTo`) ~:1412, `setExtent` ~:1623, `setWidth` ~:1777, `setHeight`
~:1813 — joined
by the structural `add` ~:2506. *(An earlier revision counted "7" and listed an `addRaw` alongside them; that method
no longer exists in the tree — there is no raw/immediate public add to enumerate.)* The **same** wrapper also backs a growing family of
**structural** self-settling mutators — `close`, `destroy`, `fullDestroy`, `collapse`/`unCollapse`,
`createReference`, `showResizeAndMoveHandlesAndLayoutAdjusters`, `setMaxDim`,
`buildAndConnectChildren`, … — each shaped `@_settleLayoutsAfter => @_<name>NoSettle(…)`, so a tree/lock/menu change
that re-fits layouts also settles exactly once. *(An earlier revision listed `reactToDropOf` here; the fourth wave's
`5f923847`/`dd3a5510` corrected that — a **drop** is settled **once by the drop *dispatcher*** (`ActivePointerWdgt.drop`),
and the per-container drop **callback** is the settle-neutral `_reactToChildDropped`, not a self-settling mutator; lint
`[J]` now forbids such a callback from opening its own settle.)* For an *orphan* (attached to neither world nor hand — `_settleLayoutsAfter` ~:816) the flush is **deferred only when the
orphan call is itself reached inside a live flush/pass** (`return coreThunk() if @isOrphan()`): the orphan-settledness
change (`ce21dcf7`) made a *top-level* orphan call FLUSH its own subtree, so `new Foo()` now returns settled (and the
all-constructors-settle follow-on routes every constructor through that wrapper). A flush is also **coalesced** inside a
`_settleLayoutsAfterBatch` batch (~:833). Nested public setters reached on an *attached* widget do **not** stack
flushes — they *throw* (the flow-violation guard, ~:826).

So the honest formula is:

> **flushes / frame  =  (self-settling public mutations executed this frame)  +  (top-level batches)  +  1**
> &nbsp;&nbsp;&nbsp;&nbsp;— minus mutations skipped for orphans, minus those coalesced inside a batch.

(The *(top-level batches)* term is **currently zero** — `_settleLayoutsAfterBatch` has no live callers today, see
below — so in practice the formula reduces to *(self-settling public mutations) + 1*.)

**Evidence this is by design, not incidental:**

- The code documents sequential per-call flushing in so many words (`Widget.coffee` ~:798): *"Calling several
  public setters in SEQUENCE is fine — each completes, flushing once, before the next begins."*
- A frame dispatches its **whole** event backlog, not one event: `playQueuedEvents` (`WorldWdgt.coffee` ~:1269)
  loops `for event in @inputEventsQueue` (~:1274) and returns only at a *future-timed* event (~:1281). Under load —
  the dpr2 heavy-frame case the determinism docs warn about — many events are drained in one frame.
- A concrete per-event flush: the resize handle's drag handler `HandleWdgt.nonFloatDragging`
  (`src/HandleWdgt.coffee` ~:252) calls `@target.setExtent` / `moveTo` / `setWidth` / `setHeight` — each a
  self-settling flush. A resize gesture emits a *stream* of these; several landing in one heavy frame ⇒ one
  flush *per drag event*, plus the end-of-cycle flush.

**Why two settle points exist (and why the end-of-cycle one is load-bearing, not a redundant safety net).**
The two flush kinds drain two different populations of dirtiness:

- **Per-call flushes (site 2)** settle mutations made through the **public deferred API** so an event handler
  always observes a *consistent world between calls* — the entire reason for the self-settling tier (no caller
  ever has to "yield and wait for layout").
- **The end-of-cycle flush (site 1)** drains everything that invalidated layout *without* going through that
  API and so never self-flushed: **immediate-mutator** geometry changes (float-drag moves, `wheel` scroll adjustments,
  step-function animations) that enqueue via the seam's out-of-pass `_invalidateLayout` arm — and the
  determinism-exempt *in-pass* enqueue arm of the same seam (§2.3) — plus any remaining direct `_invalidateLayout()`
  callers in feature code. Without this flush those changes would reach paint unsettled. *(A subtlety the
  end-of-cycle campaign turned into its central theme: a public mutator that **defers** to this flush instead of
  self-settling is a "careless" leak, and many once did. `setMaxDim` and `collapse` — listed here as direct
  `invalidateLayout()` callers in earlier revisions — were both since **converted** to self-settle through
  `_settleLayoutsAfter` (their cores still call `_invalidateLayout`, but a public wrapper now flushes around it).
  §2.7 is the full account; its bottom line is that the **careless** subset of this site-1 population has been
  driven to **zero**, leaving only legitimate riders — declared-coalesced streams, orphan/construction deferrals,
  and the in-pass re-fit seam.)*

`_settleLayoutsAfterBatch` (`Widget.coffee` ~:857) exists *because* per-call flushing is O(mutations): a multi-add
builder would otherwise do N full settles, so a batch can collapse them to one. **It has zero live callers today,
however.** The design direction is to do everything through the single-mutation `_settleLayoutsAfter` tier, and the
former batch users (the drag/drop gesture, `sizeToTextAndDisableFitting`, and `WindowWdgt`'s child build — now the
public `buildAndConnectChildren` ~:436 over the non-settling `_buildAndConnectChildrenNoSettle` ~:439) were each
re-expressed as a *single* settle over non-settling cores. So site 3 is a **retained but dormant** primitive: the
`_batchingLayoutSettling` flag and its guard in `_settleLayoutsAfter` (~:833) stay wired so it works as-is if a
future multi-add bundle wants one O(1) flush, but the live flush population today is sites 1 and 2 only.

**Consequence.** A heavy frame's final layout is the **composition of several full settle passes, in event
order**. This is sound only because each settle is a pure function of geometry-at-that-instant and converges to
the same fixed point regardless of iteration count — but it makes per-frame cost `flushes × cost-per-settle`,
and it is a real reason determinism is hard: the *sequence* of settles within a frame (and the event-draining
order driving it) must be deterministic, not just each settle in isolation.

**The normative invariant under the formula: one flush per *outermost* public mutation — and the throw is what
enforces it.** The formula above is descriptive; the *design rule* it realizes is sharper, and it is what makes a
layout system this stateful safe to keep extending. A public entry point's single tier (`_settleLayoutsAfter`, née
`mutateGeometryThenSettle`) sets `world._inLayoutMutation = true`, runs the mutation core, then runs
`recalculateLayouts()` **exactly once**. Its flow guard (~:826) THROWS the moment a
public setter is reached on an *attached* widget while `_inLayoutMutation` (or `_recalculatingLayouts`) is already
true — so once you are inside an entry point's settle, **no nested public call can open a second settle.** Internal
code is thereby *forced* onto the non-settling `_<name>NoSettle` cores and the immediate (geometry) mutators, which schedule nothing.
Net: **the outermost attached public mutation owns the single flush; everything underneath rides it.** (Sequential,
non-nested public calls each get their own one flush — they don't interleave, so that's fine; it is *nesting* that is
forbidden.)

**The throw is the enforcement, not a convention.** Clean layering here is a *checked* invariant, not a guideline the
authors hope to honour: **two** runtime tripwires guard it from opposite sides — `_settleLayoutsAfter`'s
flow-violation throw (a plain, explicitly worded `Error` ~:826, when a *public* setter is reached on an attached
widget during a flush/pass) and `_invalidateLayout`'s `FLOWRULE_VIOLATION` throw (~:3929, when an *immediate (geometry)
mutator* tries to schedule layout mid-pass — this is the throw that actually carries that label, and the fourth wave
reworded its message to name "an immediate geometry mutator" in place of the retired "raw/silent/fullRaw setter") —
**plus** the build-time layering lint (`buildSystem/check-layering.js`, now rules **[A]–[M]**: rules [A]/[E] catch the
name-recognized internal methods directly — [E] forbids an immediate mutator from calling `_invalidateLayout` — and [G]
forbids low-level code from calling a *structural* self-settling
wrapper — destroy / close / fullDestroy / createReference / …) together make "public self-settles once; low-level code
never schedules layout" a property the build and the runtime *verify*. ("Low-level" and "immediate mutator" here ≝
whatever `check-layering.js`'s `isLowLevel()` / `isImmediateMutator()` predicates match — those predicates are the
single source of truth for the tiers, and this prose must not drift from them.) That is precisely what stops this class of stateful
layout fix from getting out of control: a new caller that re-enters the settle machinery fails LOUDLY (a flow
violation surfaced at test/build time) instead of silently corrupting an in-progress flush.

**The motivation is a real recursion/hang, not theoretical purity.** `_invalidateLayout` throws specifically when
reached during `_recalculatingLayouts` because of a documented app-freeze: a container resizing its children climbed
an `invalidate` back into itself *mid-pass*, so the convergence loop (§2.3) never terminated. Forbidding *any*
re-scheduling of layout from inside the pass is what guarantees that loop converges. And the `catch` around
`recalculateLayouts` is non-flushing — it defers recovery outside the flush — so even when the tripwire fires you get
a loud error, never a hang. Poor layering in this engine does not merely look untidy; it risks a non-terminating
settle, which is *why* the discipline is enforced rather than recommended.

Two caveats keep the mental model exact:
- **"One flush" = one *convergent* flush, not one layout calculation.** `recalculateLayouts()` internally walks/loops
  until layouts reach a fixed point (§2.3); "one flush" means one *bounded convergence operation* per entry point. It
  is bounded *because* nothing inside it can inject a new public mutation — the throw is what makes the bound hold.
- **The batch tier is the deliberate — but currently dormant — exception.** `_settleLayoutsAfterBatch` (née
  `settleLayoutsOnceAfter`) ABSORBS nested settles to coalesce a genuine bundle (a multi-add builder) into one flush,
  so the fully general invariant is **"one flush per outermost public mutation, whether single or batch."** As §2.2
  noted, no code reaches for it today — everything is single-`_settleLayoutsAfter` — so this is the *defined*
  exception, not a *live* one. The orphan guard adds a third case:
  construction of a *detached* subtree settles **zero** times until it is added — so building innards is flush-free by
  construction. (The end-of-cycle drawdown campaign — `end-of-cycle-flush-drawdown-plan.md` — brought every remaining
  flow into this invariant: re-probing the cavalier "LEAVE" verdicts found flow after flow quietly outside it, and the
  campaign has now driven the *careless* end-of-cycle set to **zero**, guarded by a hard-fail gate (§2.7). §2.7 develops
  the categories, the detection toolkit, and the coalescing API it produced.)

### 2.3 The settle engine: invalidate **up**, re-layout **down**, iterate to a fixed point

The flush primitive `recalculateLayouts` (`WorldWdgt.coffee` ~:911) is a thin re-entrancy guard that wraps
`_recalculateLayoutsBody` (~:939) — and *that* body is the whole engine:

```
until widgetsThatMaybeChangedLayout is empty:           (~:948)
   pop valid widgets off the tail
   take a dirty widget; walk UP parents while the parent is also dirty   (~:987)
       (stop at a valid parent, or at a freefloating boundary  ~:988)    → "top of a broken chain"
   tryThisWidget._reLayout()       (~:997 — lays out that subtree top-down, marking each node valid)
```

Two facts make this a *fixed-point* loop, not a fixed *number* of passes:

1. **Invalidation climbs up; layout flows down.** `_invalidateLayout` (`Widget.coffee` ~:3898) pushes the
   widget + marks it invalid (via the shared `__markForRelayout` atom ~:3894), then recurses to `@parent`
   (~:3952) — short-circuiting iff the triggering child is freefloating (the single freefloating-skip now lives in
   one place, the param guard ~:3906) — so one deep change
   enqueues the whole ancestor chain, and the loop then does a single top-down `_reLayout` from the topmost
   dirty ancestor. **In the common case a localized change is "climb up once, lay out down once" — effectively
   one top-down arrange.** `_reLayout` ends in `markLayoutAsFixed()` (~:4377), popping the node.
2. **A `_reLayout` can re-dirty something *outside* the subtree it just settled**, via the re-fit seam
   `_reFitContainer` (`Widget.coffee` ~:1755), whose in-pass arm *enqueues* a container mid-pass — legally: this
   enqueue uses the shared no-climb atom `__markForRelayout` (~:1758), which neither throws nor climbs to
   ancestors (the full `_invalidateLayout` does both, for a content widget); it just pushes the one
   directly-affected container. This is the only thing that produces genuine iteration — and §4.2 Objective A
   *narrowed* it. It used to have two sources: a container re-enqueuing **itself** during its own arrange (its
   just-applied geometry firing the seam straight back at it — "Intent-2"), and a container re-fit triggered by an
   **external** change to its freefloating content ("Intent-1"). The non-notifying arrange (§4.2, below) removed the
   first — the stack and scroll arranges now apply their *own* geometry through twins that don't fire the seam, so a
   settled container no longer re-dirties itself. What remains is the genuine cross-widget convergence: the clock →
   inner-window → outer-window cascade (the window arrange is *not* yet non-notifying — §4.2 Stage 2 was deferred) and
   the scroll panel's content-frame ↔ scroll-position coupling, each re-enqueuing *other* containers, so the loop
   runs another `_reLayout`, and again, **until the queue drains.** *(Option C — `d60a0710`,
   §2.1 — added a second live instance of exactly this shape: the text caret's `_reLayout` **is** a scroll-follow —
   it scrolls its panel, the seam re-enqueues that panel ahead of the still-dirty caret, and the loop re-runs the
   caret after the panel settles. The caret reaches the loop through `_invalidateLayout`'s inert-receiver branch — the
   *same* `__markForRelayout` atom (§2.1; unified in `282ea492`) — not the seam, but it iterates by the very
   same re-dirty-each-other mechanism.)*

> **So the right mental model:** one *up-then-down* per localized change; degenerating into true
> *up/down/up/down* fixed-point iteration only across **container boundaries that re-dirty each other**
> (freefloating content ↔ its container). The iteration is concentrated in a small, specific part of behavior.

Termination is guarded by a hard `recalcIterationsCap = 100000` freeze-backstop (~:945); by each container arrange
now being an idempotent **fixed point** — so a container the seam re-enqueues *while it is mid its own*
`_positionAndResizeChildren` re-runs once and converges, rather than looping (the proper-layouts campaign deleted the
old per-container `@_adjustingContentsBounds` re-entrancy/suppression boolean precisely because Phase C made the
arrange idempotent and Phase E removed the last synchronous self-re-entry, §2.6/§4.1; §4.2 Objective A then made the
arrange *non-notifying*, so it no longer re-enqueues itself even to confirm); and by the rule that `_invalidateLayout`
**throws** `FLOWRULE_VIOLATION` if reached mid-pass (~:3929) so an immediate mutator can never re-dirty the pass it is running
inside. The cap itself **stays**: retiring it was the goal of the seam-deletion endgame, which closed as infeasible
(§4.1), so the genuine cross-widget convergence — bounded, but real — still iterates beneath it.

### 2.4 The root constraint: accessors read *applied* geometry → mutate-then-read-back

Every geometry accessor (`width()`, `height()`, `position()`, …) reads the *applied* `@bounds`. There is no
way to ask "where is this heading." So a container that must size itself to its content cannot *measure* the
content — it **mutates the child and reads the result back**. The vertical stack does exactly this for its
tracking-container children (`SimpleVerticalStackPanelWdgt.coffee` ~:266, ~:301):

```coffee
elementHeight = widget._setWidthSizeHeightAccordingly recommendedElementWidth   # mutate child (synchronously _reLayout's it), capturing its applied height (~:266)
…
stackHeight += elementHeight ? widget.height()                                    # consume that handed-forward height — no second read-back (~:301)
```

**This read-back is the cause of most of the engine's complexity.** It forces the child's `_reLayout` to run
*synchronously, now* (so `height()` is fresh), which is why the immediate (geometry) mutators apply layout immediately
(`_setWidthSizeHeightAccordingly`, née `rawSetWidthSizeHeightAccordingly`, ~:750 calls `@_reLayout()` at ~:755 and *returns the height* as the
"Path-B de-read-back" workaround — and this stack now **consumes** that returned value at ~:301 instead of
re-reading `widget.height()` [proper-layouts Phase B, landed with Phase C, 2026-06-28]. §4.1 then went further for
*leaf* children: they are sized by the pure `preferredExtentForWidth` measure with no mutation at all (~:268–270), so
the mutate-then-read-at-the-source now survives only for *tracking-container* children (~:266) — a leaf can be measured
without applying it; a container child still cannot, §4.1/§2.5), why `_invalidateLayout` must
throw mid-pass, and why the cross-container notifications had to be synchronous before the deferral campaign
converted them to the enqueue-mid-pass seam.

### 2.5 Two sizing philosophies coexist (the most important structural finding)

This is not spelled out in the campaign docs, but it is the crux for any future architecture work:

| | **Horizontal stacks** | **Vertical stacks / window content / scroll content** |
|---|---|---|
| Sizing model | **min / desired / max**, computed **bottom-up** by recursion: `getRecursiveMinDim/DesiredDim/MaxDim` (`Widget.coffee` ~:4062–4161) — memoization is *scaffolded* (`@minDimCache`/`@desiredDimCache`/`@maxDimCache` are written) but the cache **reads are commented out** ("TBD the exact shape of …"), so each query currently re-walks the subtree | **proportional**: child width = f(*current* container width), `getWidthInStack` (`VerticalStackLayoutSpec.coffee` ~:31) |
| How a container learns content size | a **pure measure** (no mutation) | a **pure measure** too, for content-sizing content, since §4.1 (`preferredExtentForWidth`); but still **mutate-then-read-back** at the source (`_setWidthSizeHeightAccordingly`) and for non-content-sizing folder/toolbar frames (§2.4) |
| Arrange | 3-case distribution in base `_reLayout` (`Widget.coffee` ~:4286–4374): under-min shrink / desired-margin grow / max-margin grow | sum the handed-forward / measured heights (`_positionAndResizeChildren`) |

The horizontal path is **a textbook constraint box layout** (essentially flexbox with min/preferred/max + grow
factors) with a clean measure/arrange separation. The vertical/window/scroll path *was* the imperative, read-back,
fixed-point path — and the §4.1 campaign acted on exactly the observation that drove this finding: *the framework
already contained a clean measure engine, just not on the side that hurts.* It has since **generalized that engine to
the hurting side** — a side-effect-free `preferredExtentForWidth` now lives on text, the vertical stack, windows, and
aspect content (plus a base default), and the scroll panel sizes its content frame from it (via
`subWidgetsMergedPreferredBounds`) instead of mutating its children and reading their bounds back (§4.1). What did
**not** dissolve is the deeper split: the proportional model below still couples size and width cyclically, and one
applied read-back survives where it is load-bearing — the non-content-sizing folder/toolbar frame still merges
children's *applied* bounds (`subWidgetsMergedFullBounds`, §4.1/§4.4). That residual is precisely why a measure pass
*alone* did not let the re-fit seam be deleted (§4.1).

The proportional model is what creates the cyclic coupling: `getWidthInStack`
(`width = wEl + elasticity·(availW·wEl/wStk − wEl)`, capped at `availW`) makes child width a *continuous
function of container width*, and container size depends back on children. When that loops through an
aspect-locked widget (a square clock in a window-in-window), width depends on height depends on width — a
genuine cycle. The capstone's fix — give aspect content `elasticity 0` so the converged-width term multiplies
out (OVERVIEW §5) — is exactly right: it **breaks the cycle** rather than iterating through it.

### 2.6 Convergence is empirical and capped, not structural

Termination today rests on: each `_reLayout` ending in `markLayoutAsFixed`; each container arrange being an
idempotent fixed point (the property Phase C established, which is what let the proper-layouts campaign **delete**
the `@_adjustingContentsBounds` re-entrancy/suppression boolean that had previously masked the non-convergence —
§4.1); manual cycle-breaking (the `elasticity 0` fix); a 20-minute determinism torture soak; and the
`recalcIterationsCap = 100000` backstop that exists to convert a hypothetical non-convergence into a loud bail
instead of a freeze (~:945). That is a defensible engineering position — but it means convergence is a *verified
property of the current constraint set*, not a *guaranteed property of the algorithm*. **Deleting that boolean did
not make convergence structural** — it removed a *crutch* (a runtime suppression that hid wasted passes), not the
*cause*. What happened *next* sharpened the picture. §4.2 Objective A then made the arrange **non-notifying**, which
*did* make one half structural — a container no longer re-enqueues its own just-applied geometry — and that is what
drove the end-of-cycle careless count to zero (§2.7). But the notify-by-mutation seam still drives genuine multi-pass
iteration for the *other* half: the cross-widget convergence — a freefloating content's in-pass geometry change must
re-fit its size-tracking container in a *later* settle visit, above all in the scroll panels (content-frame ↔
scroll-position coupling via `keepContents`). The campaign then **attempted to delete the seam outright and proved it
cannot be** (§4.1): every removal path — non-notifying conversion, a synchronous in-arrange fixpoint, an off-pass
dirty-tree climb, an ordered content-first pre-settle, an analytic position↔frame decoupling — was falsified, because
the arrange is *already* single-pass-correct and the seam's surviving role is **multi-widget notification, not
single-container convergence**. So convergence remains **empirical and capped** for that one irreducible edge — by a
now-*proven-necessary* design, not deferred work and not a crutch: the waste is gone (§4.2 Objective A); what iterates
beneath `recalcIterationsCap` is real coupling.

### 2.7 The end-of-cycle flush: what survives it, the categories, and coalescing

§2.2 established *that* the end-of-cycle flush (site 1, run once per frame by the engine in `doOneCycle`) drains
everything that invalidated layout *without* self-settling through the public API. This section steps in one level
closer and assesses *what* legitimately rides that flush versus what is a leak — the vocabulary the **end-of-cycle
drawdown campaign** settled on, how a survivor is detected, and the one intentional-batching mechanism
(**coalescing**) the engine now exposes as public API. It is the conceptual companion to the campaign's operational
docs: `end-of-cycle-flush-drawdown-plan.md` (the worked playbooks + patterns + verification), `end-of-cycle-flush-
inventory.md` (the by-action audit history), `coalescing-measurement.md` (the measurement harness), and
`end-of-cycle-flush-endgame-plan.md` (the campaign's endgame record — its target reached, the careless set at zero).

**An end-of-cycle survivor, precisely.** A widget's `_invalidateLayout` push survives to the end-of-cycle flush iff
*no* self-settling flush (site 2 per-mutation, or site 3 batch) drained the queue between that push and `doOneCycle`'s
`recalculateLayouts()`. So a survivor is, by construction, *a layout invalidation that did not self-settle.* Under the
one-flush-per-outermost-public-mutation invariant (§2.2), an **empty** end-of-cycle queue (of the *careless* kind — see
next) is the *ideal* steady state, and the end-of-cycle campaign drove it there: **interaction-frame careless records
1244 → 0**, contributor by contributor, with a hard-fail gate shipped to hold zero (the capstone, below). *(That zero
was the state at the end-of-cycle campaign's end, `778a7db5`. The later proper-layouts campaign then deliberately took
the gate **red again — 18 pushes across 10 tests** (`a5e89d1b`) — by deleting the `@_adjustingContentsBounds`
suppression that had been hiding them. Those 18 are a category the end-of-cycle taxonomy never had to name precisely
because the boolean kept them invisible: **convergence re-enqueues** — a container re-fitting its own `@contents`
across passes — not careless leaks. They were removable by none of CONVERT / ELIMINATE / COALESCE — only by making the
arrange itself stop firing the seam at the container, which the campaign's own §4.2 Objective A (the non-notifying
arrange) then did: the gate went **18 → 10** (Stage 1, the stack) **→ 0** (Stage 3, the scroll), and is **green again
as of `95a131b2`** — and **still green at `c5ae7697`**, the fourth-wave naming campaign and its two behaviour-preserving
fixes having left it untouched. See the capstone discussion below and §4.1/§4.2.)*

**Two ways to count a survivor — and only one is the binding definition.** "Survivor" can be measured by *snapshot* or
by *enqueue*, and the campaign learned (the hard way) to trust the second:

- **By snapshot** — walk `widgetsThatMaybeChangedLayout` *at* the flush and report what's still queued (what the
  sharded audit's prelude does). Simple, but it **misses** a careless push that some *later, same-frame* self-settle
  happened to drain before the snapshot, and it **counts** orphan / coalesced pushes that aren't careless at all.
- **By enqueue** — record a push *the moment it is made* if it is off-settle, attached, and undeclared, regardless of
  what later drains it (what `auditUndeclaredEndOfCycle`, and therefore the gate, does). This is binding, because **the
  contract is broken at the mutation, not at the flush**: a public method that schedules layout off-settle is careless
  even if an unrelated later event cleans up after it. The enqueue measure is strictly more faithful — it catches the
  drained-but-careless pushes the snapshot can't see (and counts the whole climb, not just the origin) — and it is also
  **stable run-to-run** where the snapshot is noisy: it keys off the deterministic mutation (*was a push made
  off-settle?* — a property of the code path, the same for every run of a given test) rather than the wall-clock-
  sensitive *distribution of work across frames* the snapshot samples. That stability is what lets the enqueue measure
  back a **hard-fail** gate (the capstone, below); the noisy snapshot could only ever be advisory.

The distinction is not academic. A suite-wide *enqueue* audit (the binding one) surfaced two careless menu-action paths
— `Widget.newParentChoice` and `disableDragsDropsAndEditing` — that the *snapshot* audit had always reported "clean,"
because in each case a later same-frame settle drained the push before the snapshot. Both were genuine off-settle
pushes, invisible until the count was taken at the source — and, tellingly, they were *different faults*:
`newParentChoice`'s deferred container re-fit is load-bearing (it is the *only* re-fit when the attached widget takes
`add`'s no-re-fit `super` path) → **CONVERT** (self-settle it); `disableDragsDropsAndEditing`'s re-fit was **wasted**
(locking changes appearance and drop-handling, not the panel's settled geometry) → **ELIMINATE** (the disable-probe
story under "Detecting a survivor"). One discovery mechanism, both fault kinds; the discriminator below tells them apart.

**The three faults (the classification rubric).** A survivor is one of three things, each demanding a *different* fix —
and naming which is the whole job:

| Fault | What it is | The fix |
|---|---|---|
| **CONVERT** | a discrete **public API mutator** that failed to self-settle (it defers, or leans on an *unrelated* later event to settle for it). A public mutator must leave the world layout-consistent *on return*; one that doesn't is a contract breach. | wrap its body `@_settleLayoutsAfter => @_<name>NoSettle(…)` — a thin public settle-wrapper over a non-settling core; its high-frequency *internal* callers use the core, so a gesture stream still rides one flush |
| **ELIMINATE** | **wasted work** — a re-fit that changes nothing: a freefloating child's teardown re-fitting the world; a layout-inert caret/handle re-fitting its container; a container re-fit scheduled while the container is mid its own `_positionAndResizeChildren`; a relayout during construction on an orphan | stop scheduling it — the *narrowest* provably-byte-identical guard |
| **COALESCE** | a genuine **per-input-event STREAM** (drag-move, wheel, key-repeat) where N mutations land in one frame; deferring them onto the one end-of-cycle flush saves (N−1) flushes/frame | **DECLARE** it via a `*Coalesced` public entrypoint (below). NOT a leak — an intentional, *measured*, *declared* batching |

**The discriminator.** Pin the *actual* enqueue stack (see "Detecting a survivor") and ask: **"is a public API mutator
on it, returning unsettled?"** Yes → CONVERT. No, and the immediate-mutator / internal move that enqueued belongs to a widget that
*cannot affect* the container it dirtied → ELIMINATE. It is a raw event stream draining straight from
`playQueuedEvents` → COALESCE. Reasoning from the by-action *name* is not enough: the campaign both **converted** the
contained-text *API* path (a real public-mutator leak) and **eliminated** the visually-identical contained-text *caret*
path (wasted layout-inert-mover work) — opposite fixes the action label alone would have conflated.

**A CONVERT's sharp edge: the non-settling core is not optional for *internal* callers — and it is a *correctness*
constraint, not a flush-count one.** Making the public method self-settle is half the fix; routing its internal callers
to the `_<name>NoSettle` core is the other half, and the reason is subtler than "save a flush." A public mutator called
mid-sequence by another operation, if it self-settles, runs a full `recalculateLayouts()` *then and there* — which
flushes whatever else that operation had pending **early**, re-ordering work the original left deferred. The caret-nav
convert is the worked case: `goRight`/`goLeft` are pressed as keystrokes (must self-settle) but are *also* called inside
`insert`/`deleteLeft` to advance the caret past a just-typed character; converting them globally flushed the text re-fit
*before* the trailing `updateDimension`/`escalateEvent`, silently changing the rendered result
(`macroStringWdgtInlineTypingRefitsUnderFittingModes`). So the wrapper+core split is load-bearing: public `goRight`
self-settles, `_goRightNoSettle` does not, and the internal advance calls the core so it rides the surrounding
`setText`'s flush *in the original order*. The lint ([A]/[E]) catches a low-level method that schedules layout; it does
**not** catch a *public* method invoked from an internal sequence — that hazard is the author's to see, and the tell is
"this public mutator is also called by other product code, not just by an event handler."

**Two further categories sit alongside the faults** — not themselves leaks to fix, but you must recognize each so you
don't chase it:
- **macro-driver** — the SystemTest harness (`theTest_InputEvents_Macro`) building fixtures mid-test. Long treated as
  "out of scope" because it is test code, not product — but the current direction is to drive these to zero too *where
  they trace to a product code path* (a real `add` / re-fit the harness merely triggers, which any app would also hit).
- **orphan / construction** — an off-world widget (root is neither `world` nor `world.hand` — `isOrphan`,
  `TreeNode.coffee` ~:158) legitimately defers. This is *not* a carve-out for a special case; it is the engine's
  foundational lifecycle. An orphan has no live container to lay out against, so its *authoritative* layout is
  unavoidably the top-down pass run when it is (re-)attached through a self-settling `add` — and *every* widget is an
  orphan while its subtree is being built, so "modify off-world, settle on attach" is how construction itself works.
  *(A sharper corollary, now in its mature form after the all-constructors-settle campaign
  (`docs/all-constructors-settle-plan.md`, 2026-06-30): EVERY constructor builds its children in a non-settling core
  `_buildAndConnectChildrenNoSettle` (via `@_addNoSettle`, never the public self-settling `add`) and reaches it through
  the settling wrapper `@_buildAndConnectChildren()` (or `@_buildScrollFrame()` for the ScrollPanelWdgt base). That ONE
  wrapper routes by context — a top-level `new Foo()` FLUSHES (orphan-settledness: returns settled), while a constructor
  reached **inside an enclosing callback/settle** (e.g. a window rebuilding its chrome on drop,
  `WindowWdgt._reactToChildDropped → _buildAndConnectChildrenNoSettle → new …IconButtonWdgt`) AUTO-DEFERS via the
  in-flush+orphan branch, so no settle leaks into the settle-neutral callback. The earlier `08bbb29d` form of this
  corollary — "a constructor must NOT settle; sweep its `@add`→`@_addNoSettle`" — is thus superseded: the build moved into
  the core (a build gate `buildSystem/check-constructors-build.js` forbids inline child-building in a `constructor:`
  body), and the rule-[J] notification-settle gate was taught that the orphan-receiver settle reached in a callback IS
  this safe auto-defer, not a leak.)*
  Two points the campaign had to get exactly right:
  - **The exclusion is *classification*, not *suppression*.** The audit hook's `!@isOrphan()` only decides not to
    *count* an orphan push as careless; the push is still made, still queued, and still laid out — dormantly, against
    off-world geometry — at the next flush (the settle loop §2.3 has **no** orphan early-out, so the widget is popped,
    not left lingering across frames). It is not "a public mutator that forgot to settle"; it is "lay me out when I'm
    actually in the world." Suppressing the *work* is a different, dangerous thing: a blanket `return if @isOrphan()`
    atop `_invalidateLayout` was tried and reverted — it broke 63 tests, because construction orphans and the
    detached-but-live float-dragged widget (`macroDetachedWidgetStaysFloatDraggable`) have load-bearing invalidates.
    **Defer ≠ skip; classify ≠ suppress.**
  - **The basement re-home is the canonical instance — and it needs *no* declaration.** Closing a pop-up re-homes its
    lost widget into the never-painted off-world basement (`Widget._closeNoSettle → basementWdgt._addLostWidgetNoSettle`,
    root `BasementWdgt`); that panel is then re-fit by several seams (the `_addNoSettle`, the immediate-move re-fit, the
    show/hide filter), all orphan, all excluded, all superseded top-down when `BasementOpenerWdgt` wraps the basement in
    a window and `world.add`s it. (This **supersedes** an earlier "*irreducible* → *declare* it" framing: a detached-
    subtree record is an orphan, so the enqueue gate already excludes it by construction — `_coalescedDeclare` is
    neither needed nor appropriate. The `PanelWdgt._reactToChildRemoved` (née `childRemoved`) orphan-skip was an ELIMINATE
    at *one* such seam; the residual from the other seams is simply orphan, not a leak to dispose of.)

**Why this rubric exists at all — and where it goes.** The interesting architectural point is that this whole
classification *only exists because* the engine is the deferred work-list settle of §2.3, not a structured
measure→arrange. In a two-pass toolkit there is no "did this settle?" question — arrange always runs once, top-down.
Here, *because* invalidation is decoupled from layout (climb-up / relayout-down), every mutation site faces a real
choice — settle now, ride the flush, or it's wasted — and the campaign's value is making that choice *checked* rather
than ad-hoc, which is exactly what keeps a system this stateful safe to keep extending. The §4.1 keystone (a pure
measure pass) was expected to dissolve much of it, and *partly did*: the scroll panel that now **measures** its
children no longer mutates-then-reads-back to size its content frame, so fewer sites schedule layout — and the §4.2
non-notifying arrange then removed the arrange's own self-re-enqueues entirely (the capstone-zero result). But the
rubric did **not** shrink to the genuine event streams alone, because the cross-widget notification **seam proved
irreducible** (§4.1): its in-pass re-enqueue remains a legitimate, by-design category sitting alongside them.

#### Detecting a survivor

Four tools, in increasing precision:

- **The sharded audit** (`scripts/end-of-cycle-audit/run-audit-loop.sh` → `scripts/.scratch/audit/_SUMMARY.md`,
  ~1.5 min): runs the whole 165-test suite headless with a behaviour-neutral, inspector-invisible prelude, counts
  end-of-cycle survivors per frame, and attributes each to a by-action *group*. It is **run-to-run noisy by a few
  records** (the metric counts how layout work is *distributed across frames*, which is wall-clock-sensitive) — so read
  it as order-of-magnitude and treat "a row → 0" as the signal. Recipe + neutrality gate (`installed OK: 165/165`):
  `end-of-cycle-audit-tooling.md`.
- **`WorldWdgt.auditUndeclaredEndOfCycle`** (a DEBUG flag, default off) — the in-engine, *enqueue-time* audit (it
  records at the mutation, the binding definition above), and now the basis of the campaign's **shipped gate**. Its hook
  in `Widget._invalidateLayout` records the ctor of every push that is OFF-settle (`!world._inLayoutMutation`), ATTACHED
  (`!@isOrphan()`), and UN-declared (`world._coalescedDeclarationDepth == 0`) into `world._undeclaredEndOfCyclePushes`;
  `WorldWdgt.recalculateLayouts` logs them at the flush as `UNDECLARED-EOC frame=N total=M :: Ctor xK`. Those three
  conjuncts (on a `layoutIsValid` push) *are* the definition of "careless"; orphan and declared-coalesced pushes drop
  out by construction, so what it reports is exactly the convert/eliminate target. **The capstone**
  (`scripts/end-of-cycle-audit/run-capstone-gate.sh` + `eoc-capstone-prelude.js`) turns this log into a hard FAIL: it
  runs the whole suite with the flag on and exits non-zero on any `UNDECLARED-EOC` record (and it self-tests — plant a
  careless push, confirm it fails, revert). **Red at `a5e89d1b`, green again at `95a131b2` — and the trajectory is the
  lesson:** the proper-layouts Phase D deletion of the `@_adjustingContentsBounds` suppression re-exposed
  scroll/list/stack pushes the boolean had swallowed, taking the gate to **18 pushes / 10 tests**. They are
  *convergence re-enqueues* (a container re-fitting its own `@contents` across passes), not leaks — so the discriminator
  below routes them to none of CONVERT / ELIMINATE / COALESCE; they green only when the arrange stops firing the seam at
  the container, which §4.2 Objective A (the non-notifying arrange) then did: **18 → 10** (Stage 1, the stack) **→ 0**
  (Stage 3, the scroll). The lesson is that the gate's mechanical definition of "careless" (off-settle + attached +
  undeclared) **over-counts at exactly this boundary**: it cannot by itself tell a leak from a load-bearing convergence
  re-enqueue, which is why those 18 were cleared by the *structural* non-notifying arrange (§4.2) — not chased as a
  CONVERT/ELIMINATE/COALESCE gate-greening fix — and why the *further* deletion of the residual seam was then probed and
  proven infeasible (§4.1), leaving the gate honestly at zero. This **supersedes** the once-planned static `# end-of-cycle-sanctioned`
  allowlist-lint, which was the wrong tool: "what reaches the flush" is a call-graph question intractable to make
  exhaustive (the same reason `check-layering`'s transitive-`*NoSettle` closure was rejected), whereas
  `auditUndeclaredEndOfCycle` computes the *exact runtime* set and `_coalescedDeclare` encodes intent — so the gate is
  just "the careless set must be empty," sound by construction, riding the existing ~1.5-min sharded harness.
- **The stack-probe** — the only reliable *localizer*. The audit's `sig` lies: its `shortSig` truncates to ~3 frames
  AND filters `eval` frames — and since Fizzygum compiles every class in-browser, *every framework method is an `eval`
  frame* — so it collapses to a useless `Object.playQueuedEvents < e` that hides the real chain. Instead inject a
  throwaway `PRELUDE_JS` that patches `_invalidateLayout` to `console.log(new Error().stack)` UNFILTERED, gated on
  `!world._inLayoutMutation` (so you log only genuine off-settle survivors, not the in-settle enqueues a public setter
  is about to drain). One run names the exact origin line. **Reason from the stack, never the by-action tag** — the tag
  has repeatedly lied.
- **The disable-probe** — the convert-vs-eliminate decider. No-op the suspected-redundant re-fit, build, run the suite:
  byte-identical ⇒ it was wasted ⇒ ELIMINATE; tests fail ⇒ load-bearing ⇒ CONVERT. ~10 minutes, opposite verdicts. **It does more than classify — it can *dissolve* a CONVERT you were
  dreading.** `disableDragsDropsAndEditing` *presented* as a daunting convert (a public lock-menu mutator, polymorphic across 7
  classes with a parent↔contents cascade and ~30 mostly-construction callers) — and not even a *safe* one, because
  making a public method self-settle while it is reached on an *attached* widget mid-`world.add` trips the
  `FLOWRULE_VIOLATION` throw §2.2 leans on. The probe sidestepped all of it: no-oping its single `@_invalidateLayout()`
  was byte-identical across the full gauntlet (the 12 panel-locking apps included), proving the re-fit redundant — a
  **one-line ELIMINATE**, no convert at all. The lesson generalizes: a leak that *presents* as a public-mutator convert
  but has many internal / construction callers is exactly where to disable-probe *first* — the cheap probe routinely
  turns a multi-class convert into a deleted line.
  (Caveat: a *global* disable-probe verdict can be coarser than the real fix — a "load-bearing" hook can still have a
  *specific* eliminable leak on a detached / non-contributing subtree, so localize with the stack-probe first. And never
  generalize an eliminate skip down to a shared primitive without checking the construction path: a blanket
  `return if @isOrphan()` in `_invalidateLayout` once broke 63 tests, because every widget is an orphan *while being
  constructed* and those invalidates are load-bearing.)

#### Coalescing: the `*Coalesced` public API

The COALESCE fault is the one that is *not* a bug, and the engine gives it a first-class, auditable home rather than
letting feature code reach into a private `_<name>NoSettle` core. The surface today is a **single member** —
`Widget.setMaxDimCoalesced` (the stack-divider drag uses it) — but it establishes the pattern for every future
per-event-stream mutation.

**Why a declared surface at all.** A stream's mutations *want* to ride the one end-of-cycle flush (that is the whole
point: N muts/frame → 1 flush), which looks **identical at the invalidate site** to a careless public method that forgot
to self-settle. Without a declaration the audit cannot tell intentional batching from a leak. `setMaxDimCoalesced` makes
the intent EXPLICIT and PUBLIC: it declares "this is a deliberately-coalesced per-event-stream mutation; its flush is
*supposed* to ride the cycle." It is intention-revealing, and any caller (including programmatic ones) may use it — the
private `_setMaxDimNoSettle` core stays internal-only.

**Mechanism** — three small pieces on `world` (`Widget.coffee` ~:3985–4018, `WorldWdgt.coffee` ~:88–99):
- `setMaxDimCoalesced(x)` = `if world.coalescingEnabled then @_coalescedDeclare => @_setMaxDimNoSettle x else @setMaxDim x`.
  So coalescing-ON runs the non-settling core inside a declaration window; coalescing-OFF falls back to the plain
  self-settling `setMaxDim`.
- `_coalescedDeclare(coreThunk)` runs the core inside a **declaration window**: `world._coalescedDeclarationDepth += 1`
  around the thunk (try/finally). While depth > 0, the off-settle invalidates the core schedules are marked INTENTIONAL,
  so `auditUndeclaredEndOfCycle` does *not* flag them careless. Every future `*Coalesced` entrypoint wraps its core
  through here; it is nestable and returns the core's value.
- `world.coalescingEnabled` (default ON) is the **A/B switch**: ON coalesces via the core; OFF self-settles every call
  (the plain `setMaxDim`). Flip it at runtime to MEASURE whether coalescing is warranted for a given stream. Default
  ON ⇒ byte-identical to calling the `_NoSettle` core directly, so the API is behaviour-neutral until you choose to
  measure.

So three tiers coexist for one logical mutation: the bare public `setMaxDim` **self-settles** (one discrete mutation,
one flush); `setMaxDimCoalesced` **declares-and-rides** (a stream: one flush/frame for N muts); the `_setMaxDimNoSettle`
core is **internal-only** and feature code must not reach into it directly. `_coalescedDeclare` is for a **genuine
stream** and nothing else — it is *not* a disposal-of-last-resort for "this record won't convert or eliminate." When a
survivor resists CONVERT and ELIMINATE and is *not* a high-rate stream, the lesson the campaign learned is to re-check
whether it is actually an **orphan** before reaching for a declaration: the once-"irreducible" basement re-home turned
out to be exactly that (root `BasementWdgt`), already excluded by the enqueue gate, needing no `_coalescedDeclare` at
all. Declaring a low-rate non-stream just to silence the audit would be the very leak-wearing-a-declaration the gate
exists to prevent.

**Measuring whether to coalesce.** Whether a stream *earns* a `*Coalesced` entrypoint is a performance question, never a
correctness one — render happens once per frame *after* all events, so coalesced-vs-self-settle is byte-identical; only
the flush count per frame differs. The harness in `coalescing-measurement.md` measures mutations-per-frame for a gesture
at two speeds; the verdict rule: **max ≈ 1 → coalescing saves nothing → use the plain self-settling setter**; **max ≫ 1
→ coalescing is warranted** (and how much it matters scales with the settle's queue length — a 3-widget settle is cheap,
a 300-widget one is not, so weigh muts/frame × qlen). Read the **normal**-speed rate as real usage (headless `fastest`
crams the whole gesture into 1–2 cycles and over-states it). The divider drag measured a median **16 (up to 56)**
muts/frame at normal speed → coalescing warranted; that worked case study is in the harness doc.

The contrast that fixes the intuition: caret **typing/navigation** *looks* stream-shaped (one move per keystroke) but
runs nowhere near that rate — a few keystrokes per frame, not tens — so it does **not** coalesce; it self-settles per
keystroke (a discrete public mutation — the CONVERT above, with the wrapper+core care its internal callers demand).
Coalescing is for the ~50/frame mouse-driven gestures (drag, wheel), not for key input. Mis-declaring a low-rate path
as coalesced doesn't *save* anything — it just hides a careless leak behind a declaration, which is why "is this
actually a stream?" is a measured question (§ the harness), never an eyeball one.

---

## 3. Is it byzantine, or highly unusual?

Two different questions; the answers differ.

### Axis 1 — unusual relative to the field? **Yes, but with clear pedigree.**

| System | Sizing | Termination |
|---|---|---|
| WPF / Flutter / Android / Qt / CSS block-flex | two-pass **measure → arrange**, one bottom-up + one top-down | structural, O(n), no iteration |
| **Fizzygum** | **work-list dirty-set settle**, invalidate-up + relayout-down, **iterate to fixpoint** | empirical, capped (§2.6) |
| Browser layout (reflow + invalidation) | dirty-propagate + reflow | can re-run; *forced synchronous layout / layout thrashing* is the pathology |
| Constraint solvers (Cassowary / Auto Layout) | solve a *system* | solver convergence |
| Spreadsheet / reactive recalculation | dirty cells, propagate | until stable |

The closest analog is **browser layout**, and the match is striking: the browser pathology of *"read
`offsetHeight` after a write forces a synchronous reflow"* is **exactly Fizzygum's root constraint** (§2.4 —
accessors read applied geometry, so a read forces a synchronous settle). The deferred-layout campaign is the
same remedy the web ecosystem reaches for: batch mutations, defer to a flush, stop interleaving read-and-mutate.

### Axis 2 — *byzantine* (gratuitously, confusingly complex)? **No.**

Most of the complexity is **essential**, forced by three constraints the design genuinely has:

1. a **retained widget tree drawn on an immediate-mode `<canvas>`** with applied-geometry-only accessors (the
   Morphic.js heritage);
2. a **proportional + content-sized model with real cycles** (aspect-locked nesting);
3. **byte-exact determinism** — SystemTests assert pixel-identical canvases, so layout must be a pure function
   of *event stream + final geometry*, independent of iteration count, frame count, or wall-clock
   (`Fizzygum-tests/DETERMINISM.md`). Deferral matters *precisely because* intermediate passes must not leak
   into pixels.

And the *accidental* complexity is visibly **under disciplined reduction**: the deferral campaign collapsed the
synchronous special-cases into one deferred seam, unified three near-duplicate dispatch shapes into the single
`_reFitContainer`, folded three open-coded layout-enqueue pushes into one shared atom (`__markForRelayout`, né
`_markForRelayoutNoClimb`, behind the single `_invalidateLayout` scheduling verb — `282ea492`, §2.1), and gated the
invariant with build-time lints (since grown from A–H to **A–M**, §2.2) plus the determinism soak; and the proper-layouts campaign then **deleted** one of the suppression
booleans outright — the per-container `@_adjustingContentsBounds` (field + every guard + the cross-method seam check,
`a5e89d1b`, §2.6) — rather than relocating or renaming it, under a standing mandate to *eliminate* such booleans, not
live with them more comfortably; and it then went further, **building the pure measure** the engine had lacked and
**making the arrange non-notifying** (§4.1 / §4.2 Objective A), which drove the end-of-cycle careless count to zero —
before establishing, by *attempting* the re-fit seam's deletion and failing, that the one iteration that remains is
essential coupling rather than waste (§2.6); and a final naming campaign (the fourth wave) retired the confusing
"raw / silent / fullRaw setter" category-noun for the intent-revealing **immediate-mutator** lattice (`_apply*AndNotify`
notifies the container, bare `_apply*` does not) and grew the layering lint to [A]–[M] — the names now *say* what each
method does. That is the opposite of byzantine — it is a system whose owner is paying
down historical `fixLayout` debt with proofs, including a proof of where the paydown *stops*.

**The parts that *do* read byzantine — the fair targets:**

- **Behavior keyed off scattered global phase booleans** on `world` (`_recalculatingLayouts`,
  `_inLayoutMutation`, `_batchingLayoutSettling`): the legal operation (throw / enqueue / invalidate / apply)
  depends on *which phase you are in*, and that knowledge is spread across `Widget` and `WorldWdgt`.
- **Mutate-then-read-back** (§2.4) and the **two coexisting sizing philosophies** (§2.5) — *substantially narrowed*
  since: §4.1 generalized the pure measure to the read-back side and the scroll panel now consumes it, leaving one
  load-bearing applied read-back (the folder/toolbar frame).
- **Convergence is empirical, not structural** (§2.6) — and now *proven* to stay that way for one irreducible
  cross-widget edge, after the seam-deletion endgame closed as infeasible (§4.1).
- (Of the three, only the first — the scattered phase booleans — is still an *unaddressed* target; it is what §4.3
  proposes to encapsulate.)

---

## 4. Improvement directions

Ranked by leverage. The three approaches the campaign already **falsified** are *not* re-proposed and are
listed as "do not revisit" at the end. Each suggestion is determinism-sensitive and must clear the soak.

### 4.1 The pure *measure* protocol that killed the read-back — **the #1 lever; built + consumed, seam endgame closed**

This was the assessment's top recommendation, and the proper-layouts campaign **executed it** (2026-06-28 → -29). The
prescription was a side-effect-free `preferredExtentForWidth(availW) → {w, h}` that **never touches `@bounds`** —
generalizing what `getRecursive*Dim` already is for horizontal stacks (§2.5) to text (compute wrapped height for a
width *without committing the wrap*) and to the vertical/window/scroll path, so `_positionAndResizeChildren` sums
*measured* heights instead of mutating each child and reading `height()` back. That measure now **exists** on text,
the vertical stack, windows, and aspect content (plus a base `Widget` default), and the scroll panel **consumes** it
for its content frame. The rest of this entry records why it was the keystone, exactly what landed, and the hard limit
the work then hit — the seam deletion that was *attempted and proven infeasible*.

Why it is the keystone:
- It **dissolves the root constraint locally** without overloading the applied accessors.
- A container's size becomes a **pure function of children's measures**, so the synchronous "apply-then-see-it"
  is no longer needed — which is what forces immediate `_reLayout`, the mid-pass throw, and the Path-B
  "hand the height forward" plumbing.
- It **unifies the two sizing philosophies** onto the one the codebase already trusts, and (§2.2) makes
  repeated per-frame settles far cheaper, since a pure measure is much lighter than a mutate-read-back arrange.

**This is explicitly *not* Path A** (the falsified dead end, OVERVIEW §6). Path A failed because it made the
*same* accessor serve both "applied" and "pending" readers (canvas buffers, inspector, dirty-rects vs. layout).
A *separate, pure* measure query has no such conflict; the applied accessors are untouched.

**Status (2026-06-29 — plans `proper-layouts-eliminate-suppression-booleans` / `-4.1-pure-measure-campaign` /
`-4.2-structural-arrange` / `-4.4-ordered-downwalk`).** This direction was carried to its limit across four arcs. The
first — though not the way it was first scoped — retired the spearhead suppression boolean it was built around:
`@_adjustingContentsBounds` is now **gone**. (A text-scoped pure measure, `TextWdgt.measureWrappedHeight`, was built
then REVERTED first: it only fed a TRANSIENT priming height-write that the scroll arrange's own merged-bounds commit
immediately overwrote, so it never removed a load-bearing read-back.) What landed for the boolean, in three byte-safe
steps:

- **Phase C** deleted that priming write — the `@contents._applyHeightAndNotify` (née `rawSetHeight`) "height wobble" that, by disagreeing with the
  commit by ~`totalPadding`, re-fired the re-fit seam every pass and was the PERPETUAL driver of non-convergence (NOT
  a position cycle, as first thought — the position clamp self-settles once the wobble is gone). Deleting it makes the
  wrapping-text arrange a **fixed point**, so the flag became correctness-*unnecessary* (proven: the 4 tripwires
  converge + byte-match with the suppression disabled).
- **Phase D** then **deleted** the flag's cross-method seam suppression (the `return if container._adjustingContentsBounds`
  in `_reFitContainer`, plus the coupled scrollbar-layout save/restore) directly. The ~1.6× redundant-pass cost a bare
  deletion was feared to incur **did not materialize** — it was a pre-Phase-C wobble artifact; with the arrange a fixed
  point, a container re-enqueued mid-arrange re-runs once and that pass no-ops.
- **Phase E** (narrow) **deleted the `@_adjustingContentsBounds` field itself** + all three per-arrange re-entrancy
  guards, by giving each container arrange a *non-re-applying* self-resize (`_resizeOwnWidthSkippingChildRelayout/Height`,
  née `_applyOwnArrangedWidth/Height` → base `Widget::_applyExtentAndNotify`, which fires the up-notification seam but
  skips the override's `_reLayoutChildren`), removing
  the last synchronous self-re-entry the guard caught. Byte-identical by construction. **The boolean is now 100% gone.**

So the spearhead boolean fell *cheaply* — and that freed the campaign to pursue this entry's actual prescription, the
**general pure measure**, which then landed in two further arcs:

- **§4.1 — the general measure (built + consumed; `a07f534a` → `85d0c186`).** A side-effect-free
  `preferredExtentForWidth` was built bottom-up on every width→height widget — text, the vertical stack, windows,
  aspect content — plus a base `Widget` default, and a recursive children-union `subWidgetsMergedPreferredBounds`. The
  scroll panel's `_positionAndResizeChildren` now sizes its content frame from that measure (for content-sizing
  content) **instead of** mutating its children and reading their merged bounds back. (One applied read-back survives,
  load-bearing: the non-content-sizing folder/toolbar frame still merges children's *applied* bounds, §2.5.) All
  byte-identical, soak-gated.
- **§4.2 Objective A — the non-notifying arrange (the capstone-greener; `cf37fa3a` → `c8098e6d`).** The measure alone
  does not delete the seam: the arrange's *final commit* still fired it. So the stack and scroll arranges were switched
  to apply their own geometry through **non-notifying twins** (`_applyExtent` / `_applyMoveBy` /
  `_applyBounds`, née `_arrangeApply*` = the immediate mutators minus the seam fire — the bare `_apply*` name now *says* "applies without notifying"), so arrange output no longer re-triggers layout at the
  container itself. This removed the Intent-2 self-re-enqueues — the end-of-cycle capstone went **18 → 10** (Stage 1,
  the stack) **→ 0** (Stage 3, the scroll); it is **green** (§2.7).

That cleared the *waste*. The remaining question was the assessment's #1-and-biggest: delete the **seam itself**
(`_reFitContainer` / `_announceGeometryChangeToContainer`, née `_reFitContainerAfterRawGeometryChange`) and retire the empirical fixpoint. The campaign **probed
that endgame and closed it as proven-infeasible** (`838ff6e9`, "arc closed"). The decisive finding: with the
non-notifying arrange in place, the scroll arrange is *already single-pass-correct* — the seam's surviving role is
**not** single-container convergence (the arrange is idempotent; there is nothing left to converge inside one visit)
but a **multi-widget notification**: a freefloating content's geometry, *scheduled* off-pass but *applied* in-pass by
its own `_reLayout`, must re-fit its size-tracking container in a *later* settle visit (the content-frame ↔
scroll-position coupling via `keepContents`; instrumented as 341 in-pass vs 5 off-pass seam fires on the canonical
`NoSpuriousScrollbars` test). Every removal path was falsified — non-notifying conversion (done, doesn't suffice); a
synchronous in-arrange fixpoint (the arrange is already idempotent, so iterating it is a no-op); an off-pass
dirty-tree climb / two-flag invalidation (it fires at *scheduling* time, before the content's geometry is applied —
and the FLOWRULE forbids `_invalidateLayout` mid-pass, so an after-application notification cannot be delivered that
way); an ordered content-first pre-settle (the box position is driven by `keepContents`, not by a pending descendant
relayout); and an analytic position↔frame decoupling (its upper bound *is* that synchronous fixpoint, hence a no-op).
The reverse-probe (seam no-op) still breaks exactly **10** scroll/window/stack tests — the job-B work-list —
confirming the seam carries load-bearing notification, not waste. So the **seam stays**, a legitimate and
effectively-irreducible dependency edge, and with it `recalcIterationsCap` and the bounded empirical convergence
(§2.6).

The honest bottom line: the *waste* the assessment flagged — the read-back's self-convergence and the suppression
boolean — is **gone**; the *root coupling* a measure was hoped to dissolve turned out, on contact, to be two things,
only one of which is removable in this architecture. Deleting the seam would require re-architecting the settle loop so
a freefloating content's geometry application is itself part of its container's ordered visit — a true topological
down-walk — a far larger undertaking than this arc, and not justified given the capstone-green resting point.
Companions: the staged records (`proper-layouts-4.1-pure-measure-campaign-plan.md`, `…-4.2-structural-arrange-plan.md`,
and `…-4.4-ordered-downwalk-plan.md` §8 — the binding closure), why a naive text measure can't do it
(`retire-adjustingContentsBounds-via-text-measure-plan.md`), and the convergence-arc feasibility memo (memory
`fizzygum-convergence-arc-feasibility`).

**Honest caveat (revised by the outcome).** Byte-exact text measurement *did* reproduce wrap geometry without
committing it (Stage 0: 4022 measure-vs-commit differentials, 0 mismatches), and every landed step cleared the soak —
so the measure half was **not** the limiting risk it was feared to be. The limit was elsewhere, and sharper than
expected: measure + non-notifying-arrange handles content *sizing* cleanly, but it does **not** dissolve the
**cross-widget notification** edge (a freefloating content applied in-pass must re-fit its container in a later visit),
nor the genuine **width↔height cycle** of aspect-locked nested content — that one is irreducible in any single-pass
system (it is why CSS needs special `aspect-ratio` rules and Flutter forbids unbounded-both-axes), and is already
cycle-broken by `elasticity 0`. So the end-state is *not* the once-hoped "the fixpoint iteration becomes unnecessary in
principle"; it is: **the iteration's *waste* is gone; its *essential* core — one notification edge plus the handful of
true cycles — stays, bounded and capped.**

### 4.2 Make convergence *structural*, not empirical — **Objective A landed; the DAG-lint half was falsified**

This had two halves, and only one survived contact. **Objective A — the non-notifying single-pass arrange — LANDED**
(`cf37fa3a` → `c8098e6d`, §4.1 Status): the stack and scroll arranges apply their own geometry through twins that do
not fire the re-fit seam, so a container's *own* arrange is now a single idempotent pass rather than a self-re-enqueuing
fixpoint. That made one edge structural and drove the capstone to zero (§2.7). The intended **second half — a per-axis
DAG lint** — was *not* built: the idea was to classify each layout dependency edge by axis and direction ("width flows
down", proportional, vs "size flows up", content-sized) and add a lint (in the spirit of `check-layering.js` rules
[A]–[M]) flagging any new edge that couples both directions on the same axis of the same widget, on the theory that a
per-axis DAG would let a single measure+arrange terminate with zero iteration and let `recalcIterationsCap` downgrade
to a should-never-fire assert. **That theory was falsified for the system as a whole** (§4.1 Status): the
content→container notification is genuinely bidirectional in a way no per-widget lint dissolves — a freefloating
content's in-pass geometry must re-fit its container in a *later* visit — so the graph is *not* a per-axis DAG, the cap
stays load-bearing, and §2.6's empirical invariant could be made structural only for the arrange's *self*-iteration
(Objective A), not for the whole settle. A both-direction-edge lint would still be a reasonable *hygiene guard* against
introducing new coupling, but it is no longer a route to zero iteration — a guard, not the convergence proof it was
sketched as.

### 4.3 Encapsulate the engine state behind one owner object

Move `widgetsThatMaybeChangedLayout` + the three phase booleans + the `_reFitContainer` dispatch into a single
`world.layoutEngine` with an explicit phase enum (`IDLE | MUTATING | SETTLING | BATCHING`) and one documented
table of "legal operations per phase." Cohesion, not algorithm change — but it directly targets the part that
*reads* byzantine (§3), because the "throw vs enqueue vs invalidate vs apply" rule is currently reconstructed
from booleans scattered across two classes. (Bonus: an engine *object*'s methods are not `Widget` members, so
this sidesteps the inspector-recapture cost of adding methods to base `Widget`.)

### 4.4 Split dirtiness into two flags

Replace single `layoutIsValid` + climb-and-enqueue-the-whole-chain with the standard browser/React pair:
**`needsLayout` (this node)** and **`hasDirtyDescendant` (a child needs layout)**. `_invalidateLayout` then sets
one bit on the node and flips `hasDirtyDescendant` up the chain (O(depth) marking but O(1) *enqueues* — only
roots-with-dirty-descendants go on the work-list), and the loop walks *down* from those roots. It also makes the
"freefloating child laid out twice" sub-optimality (§4.5) disappear naturally. Determinism-sensitive.

**Worth doing for cleanliness — but proven *not* a path to the seam.** §4.4 is the *efficiency/cleanliness* layer:
O(1) enqueues, and it makes the "freefloating child laid out twice" sub-optimality (§4.5) disappear. But the
convergence-arc endgame (§4.1 Status) tested the two-flag's invalidation-time propagation *directly* as a seam
replacement and **falsified it**: an off-pass dirty-tree climb fires at *scheduling* time, before the freefloating
content's geometry is applied, whereas the seam's load-bearing notification is *in-pass, after* application (and the
FLOWRULE forbids re-invalidating mid-pass) — so the two-flag cannot deliver the after-application re-fit the seam does.
The capstone, meanwhile, had already been greened by the non-notifying arrange (§4.2 Objective A), not by any
dirty-tracking change. So §4.4 stands on its own efficiency/cleanliness merits, but it neither deletes the seam nor was
needed to green the capstone, and the seam-deletion endgame that would have consumed it is **closed** (§4.1). (Staged
in `proper-layouts-4.4-ordered-downwalk-plan.md`, whose §8 records the closure.)

### 4.5 Quick win — the freefloating walk-up TODO (`WorldWdgt.coffee` ~:985–997)

The code itself flags that the walk-up stops at the *first valid* parent rather than the *topmost invalid* one,
so a freefloating child can be laid out twice (first with a stale parent size). Stopping at the
last-invalid-on-the-way-up is a small, local fix that removes redundant double-layout. Optimization, not
correctness; soak it (anything in this loop is cadence-sensitive).

### 4.6 Minor — flush-count hygiene in multi-mutation handlers

Following from §2.2: a handler that performs several geometry mutations does one full settle *each*. Where a
gesture changes both extent and position, prefer the compound `setBounds` (one flush) over `setExtent` +
`moveTo` (two) — or, if a multi-mutation bundle recurs often enough to matter, revive the **dormant**
`_settleLayoutsAfterBatch` tier (§2.2) for it rather than self-settling each call. Pure micro-optimization, but it
is the productive corollary of the corrected flush model and costs nothing.

### Do **not** revisit (already falsified — see the OVERVIEW)

- **Path A — pending-aware accessors** (OVERVIEW §6): one accessor cannot serve both pending- and applied-needers.
- **Reformulating the proportion fraction** (OVERVIEW §5): the stored `wEl/wStk` fraction is irreducibly
  load-bearing (base-width menu, `DONT_MIND` fill, per-instance text); three reformulations were falsified.
- **Routing `ScrollPanelWdgt.add`/`addMany`/`showResize…` through the batch tier** (`_settleLayoutsAfterBatch`,
  née `settleLayoutsOnceAfter`; OVERVIEW §11 PROOF 2): probed 2026-06-22 and rejected — it deterministically
  diverged nested-scroll content/thumb geometry at dpr1 for zero gain. (A breadcrumb survives at
  `ScrollPanelWdgt.coffee` ~:212.)
- **Deleting the re-fit seam** by any of — non-notifying conversion *alone*, a synchronous in-arrange fixpoint, an
  off-pass dirty-tree / two-flag climb, an ordered content-first pre-settle, or an analytic position↔frame decoupling
  (the seam-deletion endgame, §4.1 Status; closed `838ff6e9`, binding record
  `proper-layouts-4.4-ordered-downwalk-plan.md` §8): **all falsified** — the seam's surviving role is a multi-widget
  *after-application* notification, irreducible short of re-architecting the settle loop into a topological ordered
  down-walk. The capstone is already green without it (§2.7); leave the seam.

---

## 5. Appendix — verified code map

All re-read against `c5ae7697` source while writing this revision (names authoritative — *post-naming-campaign*, with
the pre-campaign name in `(né …)` where it aids `grep`; lines approximate).
**Paths:** `Widget.coffee`, `StringWdgt.coffee`, `TextWdgt.coffee`, `CaretWdgt.coffee`, `ScrollPanelWdgt.coffee`
live under `src/basic-widgets/`; `TreeNode.coffee` is under `src/basic-data-structures/`; `WorldWdgt`, `WindowWdgt`,
`HandleWdgt`, `SimpleVerticalStackPanelWdgt`, `VerticalStackLayoutSpec`, `LayoutSpec` are directly under `src/`;
`AnalogClockWdgt` under `src/apps/`, `KeepsRatioWhenInVerticalStackMixin` under `src/mixins/`.

- **Per-frame cycle:** `WorldWdgt.doOneCycle` ~:1350 · `playQueuedEvents` ~:1269 (whole-queue drain ~:1274,
  future-event return ~:1281) · `updateBroken` paint call ~:1395 (def ~:1027). *(No caret step in `doOneCycle`: the scroll-follow folds
  into the flush as the caret's `_reLayout` and settles in-place during the caret's event — see the caret row.)*
  Paint-time caret work is the inert `CaretWdgt.justBeforeBeingPainted → adjustAccordingToTargetText` (~:50/~:45;
  `isLayoutInert` ~:33).
- **Caret scroll-follow (folds into the flush — `d60a0710`; drained in-place — `20586db1`; enqueue unified —
  `282ea492`; caret↔text-state decoupled — `467644a5`, layout-orthogonal):** `CaretWdgt._requestScrollFollow` ~:212
  (now just `@_invalidateLayout()` → its inert-receiver branch) · `_reLayout` ~:223 (the scroll-follow itself; stays
  dirty and re-runs through the until-loop until caret + panel settle) · `_oneScrollCaretIntoViewPassNoSettle` ~:257
  (one pass) · `_settleScrollFollow` ~:246 (empty-core `@_settleLayoutsAfter => nil`, drained at the tail of
  `processKeyDown` ~:61 / `processCut` ~:133 / `processPaste` ~:143, so a typing/delete/paste follow settles in-place —
  never on the EOC flush) · purity hoist `StringWdgt.handOffToPopoutEditorIfOverflowing` ~:1401 (overflow→pop-out,
  called from `CaretWdgt.insert` ~:399 — removes the mutation that used to fire inside `slotCoordinates`).
- **Settle engine:** `recalculateLayouts` (guard wrapper) ~:911 (re-entrancy throw ~:932) · `_recalculateLayoutsBody`
  (loop) ~:939 (until-loop ~:948; cap `100000` ~:945; walk-up ~:987; freefloating stop ~:988; `_reLayout` call
  ~:997; non-flushing catch ~:998).
- **Self-settling public API:** `_settleLayoutsAfter` (née `mutateGeometryThenSettle`) `Widget.coffee` ~:803
  (flush ~:838; flow-violation throw ~:826; orphan guard ~:816; batch guard ~:833) · `_settleLayoutsAfterBatch`
  (née `settleLayoutsOnceAfter`) ~:857 (flush ~:870 — **0 live callers; dormant**). Pure-geometry setters (5, each an
  inline `@_settleLayoutsAfter` thunk): `setBounds` ~:875, `moveTo` (née `fullMoveTo`) ~:1412, `setExtent` ~:1623, `setWidth` ~:1777,
  `setHeight` ~:1813; structural `add` ~:2506 (→ a `_addNoSettle` core). (`addRaw` — listed as a 7th mutator in earlier
  revisions — does not exist.)
- **Enqueue primitives (unified — `282ea492`):** `__markForRelayout` (née `_markForRelayoutNoClimb`) ~:3894 — the shared bare-push atom (push +
  mark invalid, *no* climb), used by `_invalidateLayout`, `_reFitContainer`'s in-pass arm, and the caret ·
  `_invalidateLayout` ~:3898 (freefloating-skip param guard ~:3906; **inert-receiver branch**
  `@isFreeFloating() and @isLayoutInert?()` → atom + return ~:3915; `FLOWRULE_VIOLATION` mid-pass throw ~:3929;
  careless-push audit ~:3944; bare push ~:3948; climb ~:3952).
- **Non-notifying arrange twins (§4.2 Objective A — `cf37fa3a` / `c8098e6d`; each = an immediate mutator minus the seam
  fire; the fourth wave renamed `_arrangeApply*` → the bare `_apply*`):**
  `__commitExtent` (née `_setExtentBoundsNoNotify`) ~:1657 (the shared bounds-set `__` leaf, also used by the notifying
  `_commitExtentAndNotify`, née `silentRawSetExtent`, ~:1649) ·
  `_applyExtent` ~:1674 · `_applyBounds` ~:1686 · `_applyMoveBy` ~:1319 / `_applyMoveTo`
  ~:1328 (twins of `_applyMoveByAndNotify`, née `fullRawMoveBy`, ~:1311). The arrange applies its own geometry through these, so it no longer fires
  the seam at the container itself (the Intent-2 self-re-enqueue that the capstone counted).
- **Re-fit seam (STAYS — proven irreducible, §4.1; its `@_adjustingContentsBounds` suppression was deleted in
  proper-layouts Phase D; the fourth wave renamed its announce verbs):** `_announceGeometryChangeToContainer`
  (née `_reFitContainerAfterRawGeometryChange`) ~:1711 (`isLayoutInert` skip ~:1719), fired by the
  *notifying* `_commitExtentAndNotify` ~:1649 + `_applyMoveByAndNotify` ~:1311 (the arrange twins above deliberately do not fire
  it) · `_reFitContainer` ~:1755 (in-pass → `__markForRelayout` ~:1758; off-pass → `_invalidateLayout` ~:1760) ·
  `_announceLayoutPropertyChangeToContainer` (née `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt`) ~:1700.
- **Apply bodies:** base `Widget._reLayout` ~:4212 (`markLayoutAsFixed` call ~:4377 — followed by a corner-layouted
  child re-layout loop ~:4381; `markLayoutAsFixed` def ~:4209; horizontal-stack 3-case distribution ~:4286–4374) ·
  `_setWidthSizeHeightAccordingly` (née `rawSetWidthSizeHeightAccordingly`) ~:750 (synchronous `_reLayout` ~:755 when `implementsDeferredLayout()`, returns
  height ~:756) · `getRecursiveDesiredDim` ~:4062 / `getRecursiveMinDim` ~:4093 / `getRecursiveMaxDim` ~:4130 (cache
  writes live, cache reads commented out).
- **§4.1 pure measure (built `a07f534a` → `20b37277`; consumed `85d0c186`):** `Widget.preferredExtentForWidth` base
  default ~:766, overridden by `TextWdgt` ~:360, `SimpleVerticalStackPanelWdgt` ~:142, `WindowWdgt` ~:55,
  `AnalogClockWdgt` ~:50, `KeepsRatioWhenInVerticalStackMixin` ~:16 · the children-union
  `Widget.subWidgetsMergedPreferredBounds` ~:1169 (stack override ~:172) — the pure twin of the applied-bounds
  `subWidgetsMergedFullBounds` ~:1138.
- **Coalescing / end-of-cycle audit:** `setMaxDim` (self-settling wrapper) ~:3985 · `setMaxDimCoalesced` ~:4000 (the
  only `*Coalesced` member; the stack-divider drag `StackElementsSizeAdjustingWdgt.nonFloatDragging` uses it, ~:89) ·
  `_coalescedDeclare` ~:4010 · `_setMaxDimNoSettle` core ~:4018; on `WorldWdgt`: `coalescingEnabled` ~:90,
  `_coalescedDeclarationDepth` ~:97, `auditUndeclaredEndOfCycle` ~:98, `_undeclaredEndOfCyclePushes` ~:99,
  `auditPaintTimeLayoutScheduling` ~:107, and the fourth wave's two new DEBUG audit flags `auditTierAndApplyNaming`
  ~:117 / `auditNotificationSettleNeutrality` ~:123 (off-by-default runtime twins of static lints [K]/[J]); the
  enqueue-time record in `_invalidateLayout` ~:3944, the
  `UNDECLARED-EOC` log in `recalculateLayouts` ~:923. `TreeNode.isOrphan` ~:158. **Hard-fail gates**
  (`Fizzygum-tests/scripts`): end-of-cycle `end-of-cycle-audit/run-capstone-gate.sh` (+ `eoc-capstone-prelude.js` —
  **green / 0 as of `c5ae7697`**); paint-read-only `paint-readonly-audit/run-paint-readonly-gate.sh` (+
  `paint-readonly-prelude.js`).
- **Containers:** `SimpleVerticalStackPanelWdgt._positionAndResizeChildren` ~:212 (container-child read-back /
  hand-forward ~:266, leaf-child pure measure + non-notifying apply ~:269, height consumed ~:301; self-resize via
  `_resizeOwnWidthSkippingChildRelayout` / `_resizeOwnHeightSkippingChildRelayout` (née `_applyOwnArrangedWidth/Height`)
  ~:125/~:129, the latter used ~:314 — the per-arrange
  `@_adjustingContentsBounds` re-entrancy guard that used to sit atop this method was DELETED in proper-layouts Phase E,
  §4.1) · `VerticalStackLayoutSpec.getWidthInStack` ~:31 (elasticity field ~:12) · `ScrollPanelWdgt._reLayout` ~:302 /
  `_reLayoutChildren` ~:288 / `_positionAndResizeChildren` ~:332 (pure-measure content frame
  `subWidgetsMergedPreferredBounds` ~:386/~:388, non-content-sizing fallback `subWidgetsMergedFullBounds` ~:390,
  non-notifying frame commit `_applyBounds` ~:437, `keepContentsInScrollPanelWdgt` clamp via `_applyMoveBy`
  ~:454–460, `_reLayoutScrollbars` ~:116 via `_applyExtent` / `_applyMoveTo` ~:165/170/186/191,
  `parentWillSizeMe` content-arrange flag ~:347) / public content endpoints `add` ~:206 · `addMany` ~:229 ·
  `_showResizeAndMoveHandlesAndLayoutAdjustersNoSettle` core ~:237 (public `showResizeAndMoveHandlesAndLayoutAdjusters`
  wrapper inherited from `Widget` ~:3111) · `WindowWdgt.buildAndConnectChildren` ~:436 / `_buildAndConnectChildrenNoSettle`
  ~:439 (single settle, not a batch) / `_positionAndResizeChildren` ~:527 / `preferredExtentForWidth` ~:55.
- **Build-time layering lint:** `buildSystem/check-layering.js` — rules **[A]–[M]** (predicates `isLowLevel` ~:91,
  `isImmediateMutator` ~:141; the summary prints `A/B/C/D/E/F/G/I/J/K/L/M`, with [H] a non-fatal *warning*); [E]
  forbids an immediate mutator from scheduling layout, [G] forbids low-level code from calling a *structural*
  self-settling wrapper, and the fourth wave's additive **[I]** `__`-leaf purity / **[J]** callback settle-neutrality /
  **[K]** apply-2×2 name-consistency / **[L]** callback-name convention / **[M]** retired-fragment ban (the terminology
  lock that bans the old `silent*`/`raw*`/`fullRaw` method prefixes).
- **Vocabulary:** `LayoutSpec.coffee` (`ATTACHEDAS_FREEFLOATING`, `…_VERTICAL_STACK_ELEMENT`,
  `…_WINDOW_CONTENT`, `…_STACK_HORIZONTAL_*`, `…_CORNER_INTERNAL_*`).
- **Concrete multi-flush source:** `HandleWdgt.nonFloatDragging` `src/HandleWdgt.coffee` ~:252
  (`setExtent` ~:261 / `moveTo` ~:263 / `setWidth` ~:266 / `setHeight` ~:269).

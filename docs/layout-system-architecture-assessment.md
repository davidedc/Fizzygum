#  Layout system — architecture assessment

**What this is.** The **canonical** description of Fizzygum's layout engine — what it does, why it is shaped the way
it is, and **how to work with it**: §6 is the rulebook for introducing a new layout (the invariants a new widget/
container must honour, and the static + dynamic checks that enforce them). It began as an outside-in *architecture
assessment* and has now **absorbed the former `deferred-layout-OVERVIEW.md`** (the deferral campaign's entry-point): the
verification gauntlet, the gotchas, and the maximal SCHEDULE/APPLY invariant + lint `[F]` all live here now (§6), and
that doc is retired to a one-line pointer.

**State assessed.** Fizzygum master **`c2aec3bf`** (HEAD, 2026-07-01). **This revision overturns the previous one's
central conclusion.** At `c5ae7697` (2026-06-30) the doc reported the re-fit **seam** as *irreducible* and its deletion
as *proven-infeasible* ("arc closed", `838ff6e9`). On **2026-07-01 the seam was deleted** — via a mechanism that was
*not* on the falsified list: a **settle-time up-edge** in the settle loop. After each chain-top settles, the loop re-fits
its size-tracking container from the just-settled, *final* geometry (`Widget._reFitMyTrackingContainerAfterSettle`,
dispatching through the kept `_reFitContainer`), so the container reads settled — not half-applied — content and re-fits
in one visit. This **replaced** the notify-by-mutation seam (`_announceGeometryChangeToContainer` /
`_announceLayoutPropertyChangeToContainer` — both now deleted; the immediate mutators fire nothing). The property half
went first (off-pass, through the uniform dirty-tree — a freefloating child's `_invalidateLayout` climbs THROUGH a
freefloating boundary off-pass when the parent is a size-tracking container); the geometry half followed (in-pass, via
the up-edge). See §2.3 / §4.1 for the mechanism and why the earlier "infeasible" verdict missed it.

With the seam gone, the rest fell in sequence (all 2026-07-01): **Stage 6** retired the convergence cap
(`recalcIterationsCap` → a never-fire loud-throw assert `layoutIterationsSanityLimit`) and added a no-op early-return
(skip the up-edge when the chain-top's frame is unchanged), cutting peak per-flush re-visits 10 → 2; the **caret
scroll-follow** was made single-pass (suite-wide re-visits 372 → 0 — root cause: `Point.floor` clamping to ≥0 capped
the scroll); the **window content-negotiation** stack re-visits were eliminated (9 → 3, the window settling non-deferred
stack content synchronously in its own arrange); the last **3 window re-visits** (nested-window first-placement) were
chased and proven irreducible; and the dead `_batchingLayoutSettling` batch primitive was deleted. **So the engine is
now: pure `measure` → non-notifying `arrange` → settle-time up-edge → bounded, near-single-pass convergence under a
never-fire assert.** §2–§5 are updated throughout; the pre-`c5ae7697` re-grounding changelog (four waves) is dropped as
git-recoverable meta.

**Lineage (why the engine looks like this).** Five campaigns shaped it in turn, each visible in the sections it
authored: **deferred-layout** (public setters self-settle; the until-loop settle engine — §2.2/§2.3); **end-of-cycle
drawdown** (the careless-push taxonomy + a hard-fail capstone gate — §2.7); a **caret/paint coda** (the caret folded
into the flush as its own `_reLayout`, paint kept read-only behind a gate — §2.1); **proper-layouts** (delete the
suppression/convergence booleans: `@_adjustingContentsBounds` gone, the pure `preferredExtentForWidth` measure built,
the non-notifying arrange landed — §4.1/§4.2); and the **2026-07-01 seam deletion + Stage 6 + caret/window single-pass**
above. A **naming campaign** across the way renamed the low-level geometry family to the intent-revealing lattice
(`_apply*AndNotify` notifies, bare `_apply*` does not, `_commit*AndNotify`, `__*`-leaves) and grew the build-time
layering lint to rules **[A]–[M]**; every method name below is post-campaign, with the pre-campaign name in `(né …)`
where it aids `grep`.

> **Line numbers are approximate — the METHOD NAME is authoritative; `grep` it.** Every shipped edit shifts lines; the
> two big files (`Widget.coffee`, `WorldWdgt.coffee`) drift by tens of lines per campaign, so re-read against current
> HEAD. Older git revisions / sibling memories use pre-naming-campaign names (`rawSet*` / `silentRaw*` / `fullRaw*` /
> `mutateGeometryThenSettle` / `_reFitContainerAfterRawGeometryChange`) — the appendix (§5) gives the née … map.

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
to zero. The earlier revision's lasting caveat — that the residual re-fit **seam** was *irreducible* — was then
**overturned (2026-07-01)**: the seam was **deleted** and replaced by a **settle-time up-edge** in the settle loop
(re-fit each size-tracking container from its content's *final* geometry, once, after the content settles — §2.3/§4.1),
which let the convergence cap retire to a **never-fire assert** (Stage 6). What remains beneath that assert is a small,
bounded, *proven*-irreducible residual — nested-window first-placement re-visits (a container cannot measure an
unplaced child) and the aspect-locked width↔height cycles (cycle-broken by `elasticity 0`). So accidental complexity is
now paid down with lints, a determinism soak, and hard-fail gates; what remains is essential.

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

`recalculateLayouts()` (`WorldWdgt.coffee` ~:911) is invoked from **exactly two** sites (a former third — a
bundle-coalescing batch tier `_settleLayoutsAfterBatch` — was **deleted 2026-07-01** as dead code, §4.6):

| # | Site | When | Cardinality |
|---|---|---|---|
| 1 | `WorldWdgt.coffee` ~:1375 (end of `doOneCycle`) | every frame, by the engine | **1 / frame** |
| 2 | `Widget._settleLayoutsAfter` flush ~:838 | every **public geometry/structural mutation** | **1 / mutation** |

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
all-constructors-settle follow-on routes every constructor through that wrapper). Nested public setters reached on an
*attached* widget do **not** stack flushes — they *throw* (the flow-violation guard, ~:826).

So the honest formula is:

> **flushes / frame  =  (self-settling public mutations executed this frame)  +  (top-level batches)  +  1**
> &nbsp;&nbsp;&nbsp;&nbsp;— minus mutations skipped for orphans, minus those coalesced inside a batch.

(The *(top-level batches)* term is **gone** — the batch tier was deleted 2026-07-01 (§4.6) — so the formula is just
*(self-settling public mutations executed this frame) + 1*, minus mutations skipped for orphans.)

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

There used to be a third tier, `_settleLayoutsAfterBatch`, *because* per-call flushing is O(mutations): a multi-add
builder would otherwise do N full settles, so a batch could collapse them to one. It reached **zero live callers** — the
former batch users (the drag/drop gesture, `sizeToTextAndDisableFitting`, and `WindowWdgt`'s child build — now the
public `buildAndConnectChildren` ~:436 over the non-settling `_buildAndConnectChildrenNoSettle` ~:439) were each
re-expressed as a *single* settle over non-settling cores — and was **deleted 2026-07-01** (together with its
`_batchingLayoutSettling` flag and guard). So the live flush population is sites 1 and 2 only; if a future multi-add
bundle wants one O(1) flush, reintroduce a batch settler from git history then (§4.6), and for per-input-event streams
use the `*Coalesced` API (§2.7).

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
- **The orphan guard is the standing exception.** Construction of a *detached* subtree settles **zero** times until it
  is added — so building innards is flush-free by construction, and the general invariant is simply **"one flush per
  outermost public mutation."** (The bundle-coalescing batch tier that once qualified this — "…whether single or batch"
  — was deleted 2026-07-01, §4.6.) (The end-of-cycle drawdown campaign — `end-of-cycle-flush-drawdown-plan.md` — brought every remaining
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
2. **A `_reLayout` can re-dirty something *outside* the subtree it just settled** — via the **settle-time up-edge**
   (this is what *replaced* the notify-by-mutation seam, deleted 2026-07-01). After the loop `_reLayout`s a chain-top,
   it calls `_reFitMyTrackingContainerAfterSettle` (`Widget.coffee` ~:1635) — which, *iff the chain-top's frame
   actually changed* (Stage 6's no-op early-return), re-fits its size-tracking container via `_reFitContainer` (~:1716)
   by *enqueuing* it into the work-list (the shared no-climb atom `__markForRelayout`, which neither throws nor climbs
   to ancestors — the full `_invalidateLayout` does both, for a content widget). Because the container reads the
   chain-top's *final*, just-settled geometry (not a half-applied mid-arrange value, as the old mutator seam did), it
   re-fits correctly **in one visit** — a bounded O(depth) up-walk, no per-mutation notification. This is the only
   thing that produces genuine iteration, and §4.2 Objective A + Stage 6 narrowed it to almost nothing: the arrange
   applies its own geometry through **non-notifying twins** (so a settled container never re-dirties *itself* — the old
   "Intent-2" self-re-enqueue), and the no-op early-return skips the up-edge on an unchanged frame. What remains is the
   genuine cross-widget re-fit — a container fitting to content whose size *genuinely changed* (a window to its stack,
   a scroll frame to its content) — which re-visits that *other* container once, **until the queue drains.** *(The
   caret's `_reLayout` is a second instance: it scroll-follows its panel, the panel re-enqueues ahead of the
   still-dirty caret, and the loop re-runs the caret after the panel settles — §2.1; since 2026-07-01 this reaches its
   fixed point in a single pass, §4.1.)*

> **So the right mental model:** one *up-then-down* per localized change; degenerating into true
> *up/down/up/down* fixed-point iteration only across **container boundaries that re-dirty each other**
> (freefloating content ↔ its container). The iteration is concentrated in a small, specific part of behavior.

Termination is guarded by: each `_reLayout` ending in `markLayoutAsFixed`; each container arrange being an idempotent
**fixed point** (the proper-layouts campaign deleted the old per-container `@_adjustingContentsBounds`
re-entrancy/suppression boolean precisely because Phase C made the arrange idempotent and Phase E removed the last
synchronous self-re-entry — §2.6/§4.1; §4.2 Objective A then made the arrange *non-notifying*, so it no longer
re-enqueues itself even to confirm); and the rule that `_invalidateLayout` **throws** `FLOWRULE_VIOLATION` if reached
mid-pass (~:3929), so an immediate mutator can never re-dirty the pass it is running inside. What used to be the
`recalcIterationsCap = 100000` freeze-*backstop* is now, since **Stage 6** (2026-07-01), a **never-fire loud-throw
assert** `layoutIterationsSanityLimit` (~:944): the seam deletion + the no-op early-return drove peak per-flush
re-visits to a handful (measured), so the loop demonstrably drains; the assert exists only to convert a *hypothetical*
non-terminating cycle into a loud throw rather than a frozen tab — not to bound a real convergence budget (§2.6). The
old cap **silently** bailed (log + abandon the work-list + ship broken layout); Stage 6 replaced that suppression with
the loud throw.

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

**This read-back *was* the cause of most of the engine's complexity** (largely dissolved since — see below and §4.1).
It forces the child's `_reLayout` to run
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
out (the deferred-layout capstone record) — is exactly right: it **breaks the cycle** rather than iterating through it.

### 2.6 Convergence is bounded and near-single-pass — the cap is a never-fire assert

The previous revision titled this section *"empirical and capped, not structural"* and argued the notify-by-mutation
seam made it irreducibly so. **The 2026-07-01 seam deletion changed that.** Termination now rests on: each `_reLayout`
ending in `markLayoutAsFixed`; each container arrange being an idempotent fixed point (Phase C — which let the campaign
delete the `@_adjustingContentsBounds` re-entrancy boolean, §4.1) *and* non-notifying (§4.2 Objective A — a settled
container never re-enqueues *itself*); the **settle-time up-edge** that replaced the seam (§2.3 — a container re-fits
*once*, from its content's final geometry, after the content settles); manual cycle-breaking for the genuine
width↔height cycles (`elasticity 0`); and a determinism torture soak. The empirical `recalcIterationsCap` is retired to
a **never-fire assert** `layoutIterationsSanityLimit` (Stage 6, §2.3).

What iterates beneath that assert is now tiny and *characterized*. A per-flush re-visit counter (instrumented +
reverted) put the suite-wide residual at three sources, two since eliminated: the **caret scroll-follow** (372
re-visits → **0**, §4.1); the **window→content re-fit over stack content** (6 → **0** — the window now settles its
non-deferred stack content synchronously in its own arrange, so it fits in one pass); and **3** genuine survivors —
nested-window **first-placement** re-visits. Those 3 are irreducible for a concrete reason: an outer window laid out
before its inner window's content has been *first-placed* cannot measure the inner window
(`WindowWdgt.preferredExtentForWidth` returns a stale extent while `contentNeverSetInPlaceYet` — the inner specs are
uninitialised, and measuring would divide-by-zero to NaN), so it must place, then re-fit. They are one-time
construction costs, not steady-state waste; three removal routes were falsified (can't measure ahead; can't settle
early byte-exactly; can't reorder — a content-before-container climb-block breaks 9 load-bearing tests, §4.1).

So convergence is now **bounded and near-single-pass**: the *waste* is gone, and the handful of real re-visits
(nested-window first-placement + the aspect-locked cycles) are proven essential — the assert never fires. It is no
longer "empirical-and-capped" in the old sense. It is still, honestly, a *verified* property of the current constraint
set rather than a *structural* guarantee of a single topological pass; making it the latter would need the ordered
down-walk §4.4 sketches — a far larger re-architecture, not currently justified given the near-single-pass resting
point.

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
*no* self-settling flush (site 2, per-mutation) drained the queue between that push and `doOneCycle`'s
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

- **Behavior keyed off scattered global phase booleans** on `world` (`_recalculatingLayouts`, `_inLayoutMutation` —
  down from three, since `_batchingLayoutSettling` was deleted 2026-07-01 with the batch tier): the legal operation
  (throw / enqueue / invalidate / apply) depends on *which phase you are in*, and that knowledge is spread across
  `Widget` and `WorldWdgt`. (This is what §4.3 proposes to encapsulate — though the owner has ruled that "bury it in a
  `layoutEngine` object" is not the goal; see §4.3.)
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

### 4.1 The pure *measure* + the seam deletion — **DONE: measure built, arrange non-notifying, seam DELETED (2026-07-01), cap retired**

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

**This is explicitly *not* Path A** (the falsified dead end, `deferred-layout-path-a-design.md`). Path A failed because it made the
*same* accessor serve both "applied" and "pending" readers (canvas buffers, inspector, dirty-rects vs. layout).
A *separate, pure* measure query has no such conflict; the applied accessors are untouched.

**Status (2026-06-29 — plans `proper-layouts-eliminate-suppression-booleans` / `-4.1-pure-measure-campaign` /
`-4.2-structural-arrange` / `-4.4-ordered-downwalk`).** This direction was carried to its limit across four arcs. The
first — though not the way it was first scoped — retired the spearhead suppression boolean it was built around:
`@_adjustingContentsBounds` is now **gone**. (A text-scoped pure measure, `TextWdgt.measureWrappedHeight`, was built
then REVERTED first: it only fed a TRANSIENT priming height-write that the scroll arrange's own merged-bounds commit
immediately overwrote, so it never removed a load-bearing read-back.) What landed for the boolean, in three byte-safe
steps:

- **Phase C** deleted that priming write — the `@contents._applyHeight` (née `rawSetHeight`) "height wobble" that, by disagreeing with the
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
  née `_applyOwnArrangedWidth/Height` → base `Widget::_applyExtent`, which fires the up-notification seam but
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
  to apply their own geometry through **non-notifying twins** (`_applyExtentBase` / `_applyMoveByBase`, née `_arrangeApply*`, +
  the silent bounds commit since folded into `_commitBounds` — the immediate mutators minus the seam fire — the bare
  `_apply*`/`_commit*` name now *says* "applies without notifying"), so arrange output no longer re-triggers layout at the
  container itself. This removed the Intent-2 self-re-enqueues — the end-of-cycle capstone went **18 → 10** (Stage 1,
  the stack) **→ 0** (Stage 3, the scroll); it is **green** (§2.7).

That cleared the *waste*, and the previous revision stopped there — it had **probed deleting the seam itself and
closed the endgame as proven-infeasible** (`838ff6e9`, "arc closed"). Every removal path it tried kept the
notify-by-mutation *shape* (a container notified mid-arrange, by its content's own mutator), and that shape genuinely
cannot deliver an *after-application* re-fit within the FLOWRULE: an off-pass dirty-tree climb fires at scheduling
time, before the content's geometry is applied; a synchronous in-arrange fixpoint is a no-op (the arrange is already
idempotent); an ordered content-first pre-settle misses the `keepContents`-driven position. The reverse-probe (seam
no-op, nothing replacing it) broke exactly **10** scroll/window/stack tests.

**2026-07-01 deleted the seam anyway — by changing the shape.** The crack was a mechanism *not* on that falsified
list: a **settle-time up-edge**. Rather than the content's mutator notifying the container mid-arrange, the **settle
loop** re-fits each chain-top's size-tracking container *after* that chain-top has fully settled
(`_reFitMyTrackingContainerAfterSettle`, §2.3), so the container reads *final* — not half-applied — content geometry
and re-fits correctly in one visit. The **property** half went first (off-pass: a freefloating child's
`_invalidateLayout` now climbs THROUGH a freefloating boundary off-pass when the parent is a size-tracking container —
the uniform dirty-tree replacing `_announceLayoutPropertyChangeToContainer`); the **geometry** half followed (in-pass,
via the up-edge, replacing `_announceGeometryChangeToContainer`). Both announce-verbs are **deleted**; the immediate
mutators are now pure geometry. Reverse-probe (seam methods gone, up-edge in) = **165/165 byte-exact** dpr1/dpr2/webkit,
danger torture clean, `RECALC_NONCONVERGENCE` absent. The endgame's error was treating the notification as necessarily
*mutation-driven*: the settle loop can drive it *structurally*. (The scroll content-frame ↔ scroll-position
`keepContents` coupling the endgame called irreducible re-fits fine under the up-edge — the loop re-fits the panel once
its content settles.) **Stage 6** then retired the cap to a never-fire assert (§2.3/§2.6), and the residual per-flush
re-visits were driven down: the caret to single-pass (below), the window→stack-content to single-pass, leaving 3
proven-irreducible nested-window first-placement re-visits.

So the honest bottom line is now the *opposite* of the previous revision's: not only is the *waste* gone (the read-back
self-convergence, the suppression boolean, the arrange's self-re-enqueue), **the notification edge itself is gone**,
restructured into the settle loop. What remains is a small proven-irreducible residual — nested-window first-placement
(a container cannot measure an unplaced child, §2.6) and the aspect-locked width↔height cycle (irreducible in any
single-pass system — CSS needs `aspect-ratio` rules, Flutter forbids unbounded-both-axes — cycle-broken here by
`elasticity 0`).

**Caret scroll-follow single-pass (`7370c25a`).** The dominant residual after Stage 6 was the caret — 372 re-visits/
suite, the scroll-follow advancing partway per pass. Root cause: `Point.floor` clamps to ≥0 (`Math.max(⌊v⌋, 0)`); a
slot scrolled above the world origin has negative absolute y, so clamping the caret to 0 capped
`ScrollPanelWdgt.scrollCaretIntoView` at one viewport-step/pass and a far caret crawled. Fix (byte-exact, 3 lines in
`CaretWdgt`): place the caret at its *true* un-clamped slot position (so the scroll one-shots the full delta), and
detect convergence on the *containers* (`@parent`/`@target` moved?) rather than the caret's own idempotent reposition
(dropping the redundant per-slot verify). **372 → 0.** Two non-silent backstops documented at the site: a wrong caret
position fails the byte-exact suite; a real cycle throws `RECALC_NONCONVERGENCE`.

Companions: the staged records (`proper-layouts-geometry-seam-removal-plan.md`, `-4.1-pure-measure-campaign-plan.md`,
`-4.2-structural-arrange-plan.md`; `-4.4-ordered-downwalk-plan.md` §8 was the *pre-deletion* "infeasible" verdict,
**superseded** by the up-edge), `caret-scroll-follow-single-pass-plan.md`, and `window-content-negotiation-residual-plan.md`
(the 3 nested re-visits, banked).

### 4.2 Make convergence *structural*, not empirical — **Objective A landed; the DAG-lint half was falsified**

This had two halves, and only one survived contact. **Objective A — the non-notifying single-pass arrange — LANDED**
(`cf37fa3a` → `c8098e6d`, §4.1 Status): the stack and scroll arranges apply their own geometry through twins that do
not fire the re-fit seam, so a container's *own* arrange is now a single idempotent pass rather than a self-re-enqueuing
fixpoint. That made one edge structural and drove the capstone to zero (§2.7). The intended **second half — a per-axis
DAG lint** — was *not* built: the idea was to classify each layout dependency edge by axis and direction ("width flows
down", proportional, vs "size flows up", content-sized) and add a lint (in the spirit of `check-layering.js` rules
[A]–[M]) flagging any new edge that couples both directions on the same axis of the same widget, on the theory that a
per-axis DAG would let a single measure+arrange terminate with zero iteration and let `recalcIterationsCap` downgrade
to a should-never-fire assert. **That theory was falsified as a *convergence proof*** (the content→container notification is genuinely bidirectional
in a way no per-widget lint dissolves) — but the practical outcome it chased, near-zero iteration, was then reached by
a *different* route: the **settle-time up-edge deleted the seam** (§4.1) and Stage 6 retired the cap to a **never-fire
assert** (§2.3), so the graph does not need to be a provable per-axis DAG for the loop to demonstrably drain. A
both-direction-edge lint remains a worthwhile **hygiene guard** against a *new* layout re-introducing bidirectional
coupling on one axis of one widget, but its *sound, per-axis* form is **not expressible** in the `check-layering.js`
line-scanner — the signal is cross-method/cross-class data-flow ("width flows down" vs "size flows up" on one axis), not
the local textual pattern every rule `[A]`–`[N]` keys off — and it is a guard, not the structural single-pass *proof* it
was sketched as (that would need the ordered down-walk, §4.4). **What was built instead (Opt-4, 2026-07-01)** is the
narrow, sound slice that *is* expressible: lint **rule `[N]`** bans re-*defining* the deleted `_announce*ToContainer`
seam verbs, locking out a copy-from-git revival of the exact removed shape (the CALL side was already covered by rules
`[I]`/`[K]`; `[N]` closes the DEF side). See §6.3.

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

**A remaining *optimization* — no longer a seam prerequisite (the seam is already deleted).** §4.4 is the
efficiency/cleanliness layer: O(1) enqueues, and it makes the "freefloating child laid out twice" sub-optimality (§4.5)
disappear. The convergence-arc endgame once tested the two-flag's invalidation-time propagation as a *seam replacement*
and falsified it (an off-pass climb fires at scheduling time, before the content's geometry is applied) — but the seam
was ultimately deleted by the **settle-time up-edge** instead (§4.1), which is post-application and needs no two-flag.
So §4.4 no longer has a seam to enable; it stands purely on its own merits — a cleaner, cheaper settle loop (walk
*down* from dirty roots instead of pop-tail + walk-up), byte-identical, determinism-gated. **It is the leading item in
the optimizations plan** (`docs/layout-optimizations-and-oo-cleanup-plan.md`). Staged in
`proper-layouts-4.4-ordered-downwalk-plan.md`, whose §8 is the (now-superseded) pre-deletion closure.

### 4.5 Quick win — the freefloating walk-up TODO (`WorldWdgt.coffee` ~:985–997)

The code itself flags that the walk-up stops at the *first valid* parent rather than the *topmost invalid* one,
so a freefloating child can be laid out twice (first with a stale parent size). Stopping at the
last-invalid-on-the-way-up is a small, local fix that removes redundant double-layout. Optimization, not
correctness; soak it (anything in this loop is cadence-sensitive).

### 4.6 Minor — flush-count hygiene in multi-mutation handlers

Following from §2.2: a handler that performs several geometry mutations does one full settle *each*. Where a
gesture changes both extent and position, prefer the compound `setBounds` (one flush) over `setExtent` +
`moveTo` (two). *(The old batch tier `_settleLayoutsAfterBatch` — a bundle-coalescing settler — was **deleted
2026-07-01** as dead code (0 callers); if a multi-mutation bundle ever recurs often enough to matter, reintroduce a
batch settler then, from git history, rather than keeping a dormant one. For per-input-event streams use the
`*Coalesced` API instead, §2.7.)* Pure micro-optimization, the productive corollary of the corrected flush model.

### Do **not** revisit (already falsified)

- **Path A — pending-aware accessors** (`deferred-layout-path-a-design.md`): one accessor cannot serve both pending- and applied-needers.
- **Reformulating the proportion fraction** (the deferred-layout capstone record): the stored `wEl/wStk` fraction is irreducibly
  load-bearing (base-width menu, `DONT_MIND` fill, per-instance text); three reformulations were falsified.
- **Deferring `ScrollPanelWdgt.add`/`addMany`/`showResize…`** (once probed via the — now deleted — batch tier;
  breadcrumb at `ScrollPanelWdgt.coffee` ~:212): probed 2026-06-22 and rejected — it deterministically diverged
  nested-scroll content/thumb geometry at dpr1 for zero gain. These endpoints stay **synchronous** applies: the dominant
  caller is orphan construction, which has no same-cycle settle to ride.
- **Re-deleting the re-fit seam via the *mutation-driven* paths** — non-notifying conversion *alone*, a synchronous
  in-arrange fixpoint, an off-pass dirty-tree / two-flag climb, an ordered content-first pre-settle, an analytic
  position↔frame decoupling. Each was falsified in the pre-deletion endgame (`838ff6e9`,
  `proper-layouts-4.4-ordered-downwalk-plan.md` §8) because each kept the notify-**by-mutation** *shape*. **The seam is
  already deleted** (2026-07-01) — by the *structural* settle-time up-edge (§4.1), a different shape entirely — so there
  is nothing left to remove. Do not reintroduce a mutation-driven container notification; the up-edge is the design.
- **Re-fighting the 3 nested-window first-placement re-visits** (§2.6/§4.1): proven irreducible three ways (can't
  measure an unplaced child, can't settle early byte-exactly, can't reorder). Banked in
  `window-content-negotiation-residual-plan.md`.

---

## 5. Appendix — verified code map

Names authoritative — *post-naming-campaign*, with the pre-campaign name in `(né …)` where it aids `grep`; lines
approximate. **⚠ The 2026-07-01 seam deletion + Stage 6 + batch deletion shifted the `Widget.coffee` 1200–1800 and
3800–4200 bands and `WorldWdgt.coffee` 900–1000 — re-grep every symbol; the *semantic* entries below (seam, up-edge,
cap, batch) are corrected to the current tree, but their line numbers pre-date these commits.**
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
  (loop) ~:939 (until-loop; **never-fire assert** `layoutIterationsSanityLimit = 100000` + `RECALC_NONCONVERGENCE`
  throw — Stage 6, ex-`recalcIterationsCap`; walk-up; freefloating stop; `_reLayout` call; **settle-time up-edge**
  `_reFitMyTrackingContainerAfterSettle` after each chain-top settles, gated on the Stage-6 no-op early-return
  `if myFrameChanged`; non-flushing catch).
- **Settle-time up-edge (replaced the deleted seam, 2026-07-01):** `Widget._reFitMyTrackingContainerAfterSettle`
  ~:1635 (`@_reFitContainer @parent.parent` if inside a non-text-wrapping scroll panel, then `@_reFitContainer @parent`)
  · `_reFitContainer` ~:1716 (kept — the phase-dispatch primitive; gated on `container._reLayoutChildren?`; in-pass →
  `__markForRelayout`, off-pass → `_invalidateLayout`). The immediate mutators (`__commitExtent` /
  `_applyMoveBy`) are now **pure geometry** — they fire no seam. The deleted announce-verbs
  `_announceGeometryChangeToContainer` / `_announceLayoutPropertyChangeToContainer` survive only in explanatory
  comments.
- **Self-settling public API:** `_settleLayoutsAfter` (née `mutateGeometryThenSettle`) `Widget.coffee` ~:803 (flush;
  flow-violation throw; orphan guard). *(The batch tier `_settleLayoutsAfterBatch` + the `_batchingLayoutSettling` guard
  were deleted 2026-07-01, §4.6 — no batch tier remains.)* Pure-geometry setters (5, each an inline `@_settleLayoutsAfter`
  thunk): `setBounds`, `moveTo` (née `fullMoveTo`), `setExtent`, `setWidth`, `setHeight`; structural `add` (→ a
  `_addNoSettle` core).
- **Enqueue primitives (unified — `282ea492`):** `__markForRelayout` (née `_markForRelayoutNoClimb`) ~:3894 — the shared bare-push atom (push +
  mark invalid, *no* climb), used by `_invalidateLayout`, `_reFitContainer`'s in-pass arm, and the caret ·
  `_invalidateLayout` ~:3898 (freefloating-skip param guard ~:3906; **inert-receiver branch**
  `@isFreeFloating() and @isLayoutInert?()` → atom + return ~:3915; `FLOWRULE_VIOLATION` mid-pass throw ~:3929;
  careless-push audit ~:3944; bare push ~:3948; climb ~:3952).
- **Non-notifying arrange twins (§4.2 Objective A — `cf37fa3a` / `c8098e6d`; each = an immediate mutator minus the seam
  fire; the fourth wave renamed `_arrangeApply*` → the bare `_apply*`, then Tier B renamed that bare form → `_apply*Base` — see the MEANING-SWAP note below):**
  `__commitExtent` (née `_setExtentBoundsNoNotify`) — the shared bounds-set `__` leaf (**2026-07-01 twin-collapse:** the
  pure pass-through `_commitExtentAndNotify`, née `silentRawSetExtent`, folded INTO this leaf; its ~20 callers reach it
  directly) · `_applyExtentBase` · `_commitBounds` (**2026-07-01:** the ex-`_applyBounds` silent bounds twin + the
  ex-`_commitBoundsAndNotify` folded into one) · `_applyMoveByBase` / `_applyMoveToBase` (twins of `_applyMoveBy`, née
  `fullRawMoveBy` — **NOT collapsible:** the polymorphic `_apply*` (ex-`*AndNotify`) is the ClippingMixin / ActivePointerWdgt
  override dispatch point, the `*Base` twin is the uniform base translate). The arrange applies its own geometry through
  these, so it no longer fires the seam at the container itself (the Intent-2 self-re-enqueue that the capstone counted).

  > **⚠ MEANING SWAPPED (Tier B, 2026-07-02, `layout-optimizations-and-oo-cleanup-plan.md` §3).** The `_apply*AndNotify`
  > polymorphic corners **dropped** the suffix → the bare `_apply*` (`_applyExtentAndNotify` → `_applyExtent`; likewise
  > moveTo / moveBy / bounds / width / height), and the override-bypass twins **took** a `Base` suffix (bare `_applyExtent`
  > / `_applyMoveBy` / `_applyMoveTo` → `_applyExtentBase` / `_applyMoveByBase` / `_applyMoveToBase`). So the bare names
  > `_applyExtent` / `_applyMoveBy` / `_applyMoveTo` NOW mean the **polymorphic** corner, whereas in git history / older
  > memories / any pre-2026-07-02 doc they meant the **bypass** twin — a genuine meaning swap, not a plain `(née …)`
  > rename. The `…AndNotify` suffix is retired and BANNED as a def by lint rule [M]. (This appendix's own body has been
  > updated to the post-swap names throughout: bare `_apply*` = polymorphic dispatch point, `_apply*Base` = bypass.)
- **Re-fit seam — DELETED 2026-07-01 (replaced by the settle-time up-edge above).** The notify-by-mutation
  announce-verbs `_announceGeometryChangeToContainer` (née `_reFitContainerAfterRawGeometryChange`) and
  `_announceLayoutPropertyChangeToContainer` (née `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt`) are **gone** (their
  `@_adjustingContentsBounds` suppression was already deleted in proper-layouts Phase D); they survive only in
  explanatory comments. `_reFitContainer` is **retained** and is now driven by the up-edge, not by the mutators. The
  immediate mutators (`__commitExtent`, `_applyMoveBy`) and the non-notifying arrange
  twins are all pure geometry now — none fires a seam.
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
  non-notifying frame commit `_commitBounds` ~:437, `keepContentsInScrollPanelWdgt` clamp via `_applyMoveByBase`
  ~:454–460, `_reLayoutScrollbars` ~:116 via `_applyExtentBase` / `_applyMoveToBase` ~:165/170/186/191,
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

---

## 6. Introducing a new layout — the rulebook (what to honour, what to check)

This section is the practical companion to §2–§4: the invariants a new widget / container / layout spec must honour to
fit the engine, and the static + dynamic checks that enforce them. It absorbs the former `deferred-layout-OVERVIEW.md`
(the gauntlet, the gotchas, the maximal SCHEDULE/APPLY invariant + lint `[F]`). **The overarching principle: layout is
a pure function of the event stream + final geometry — `measure` (no side effects) then `arrange` (apply once), with a
settle-time up-edge doing any container re-fit. Everything below is a corollary.**

### 6.1 The rules (in priority order)

1. **NEVER introduce a read-back.** A container must *never* mutate a child and read the child's geometry back to size
   itself. Give the child a side-effect-free **`preferredExtentForWidth(availW) → Point`** (§4.1) — "what extent would
   I take at this width, without touching `@bounds`" — and *measure* it. Every width→height widget overrides it
   (`TextWdgt`, `SimpleVerticalStackPanelWdgt`, `WindowWdgt`, `AnalogClockWdgt`, `KeepsRatioWhenInVerticalStackMixin`);
   the base default returns current height (width-invariant). A container measures its subtree via
   `subWidgetsMergedPreferredBounds`. *The one sanctioned read-back that survives* is the non-content-sizing
   folder/toolbar frame merging children's **applied** bounds (`subWidgetsMergedFullBounds`, §2.5) — do not add a
   second. If you find yourself calling `_setWidthSizeHeightAccordingly` and then reading `.height()` back, you are
   re-introducing the root constraint — hand the height *forward* from the sizing call instead (the "Path-B"
   convention; every override returns its resulting height).

2. **Keep it to ONE pass.** A container fits its content in a *single* settle visit. You get this for free if you obey
   the tiers (rule 3): the **settle-time up-edge** (`_reFitMyTrackingContainerAfterSettle`, §2.3) re-fits a
   size-tracking container *after* its content settles, reading final geometry, once. **Do NOT add a mutation-driven
   container notification** — the notify-by-mutation seam was deleted in 2026-07-01 precisely so nothing re-dirties a
   container mid-arrange (§4.1). A **second** pass is legitimate *only* for the two proven-irreducible cases: (a)
   nested-window **first-placement** (a container cannot measure a child whose content has never been placed —
   `contentNeverSetInPlaceYet`, §2.6), and (b) an **aspect-locked width↔height cycle**, which you must break with
   `elasticity 0` (rule 5), not iterate through. If your new layout needs a third reason to re-visit, that is a design
   smell — stop and reconsider (or bring it to the ordered-down-walk discussion, §4.4).

3. **Obey the tiers — the FLOWRULE is enforced, not advisory.** Three tiers, and mixing them throws (§2.2):
   - **Public setters self-settle.** Shape a public geometry/structural mutator as `@_settleLayoutsAfter =>
     @_<name>NoSettle(…)` — a thin wrapper over a non-settling core. The wrapper runs `recalculateLayouts()` once on
     return; the core does not. *Internal* callers (other product code, gesture streams) call the **core**, never the
     public wrapper — else you flush mid-sequence and re-order deferred work (§2.7, the caret-nav worked case). This
     wrapper+core split is a *correctness* constraint, not just a flush-count one.
   - **Immediate (geometry) mutators only mutate.** The `_apply*AndNotify` / `_commit*AndNotify` / bare `_apply*` /
     `__*`-leaf family sets `@bounds` and nothing else — it must **never** call `_invalidateLayout` (rule [E]) or a
     structural self-settling wrapper (rule [G]). Inside an *arrange* (`_reLayoutChildren`), apply your own geometry
     through the **non-notifying** bare `_apply*` twins (not `_apply*AndNotify`), so the arrange does not re-enqueue
     itself (§4.2 Objective A).
   - **Off-settle code records intent, never applies.** Schedule via `_invalidateLayout()` (climbs to the parent;
     short-circuits for a freefloating child) or `@desired*` + a public flush — never a synchronous `_reLayout` from an
     event handler. `_invalidateLayout` **throws `FLOWRULE_VIOLATION`** if reached mid-pass; that throw is the tripwire
     that keeps the settle loop terminating (§2.2).

4. **Freefloating content climbs nothing; a size-tracking container gets the up-edge automatically.** A freefloating
   child (`ATTACHEDAS_FREEFLOATING`) does not invalidate its parent — the walk-up stops at it. If your container tracks
   its content's size, define **`_reLayoutChildren`** (that is the marker `_reFitContainer` gates on): the settle loop
   then re-fits you after your content settles. Off-pass, a freefloating child's `_invalidateLayout` climbs THROUGH the
   freefloating boundary to a `_reLayoutChildren` parent (the uniform dirty-tree that replaced the property seam, §4.1).
   You do not — and must not — wire a manual notification.

5. **Break real width↔height cycles with `elasticity 0`.** Aspect-locked content (a square clock, a ratio-keeper) whose
   width depends on height depends on width is a genuine cycle. `getWidthInStack`'s proportional term multiplies out at
   `elasticity 0` (`getWidthInStack = min(wEl, availW)`), making the content convergence-independent without touching
   the proportion model (§2.5). Do *not* try to iterate the cycle to a fixpoint.

6. **Adding a method to base `Widget` is inspector-safe; deleting one recaptures the inspector test.** A new capability
   on `Widget` costs zero recaptures. *Deleting* an inspector-visible `Widget` method shifts the member list and
   recaptures `macroDuplicatedInspectorDrivesCopiedTargetOnly` (benign, pre-authorised — recapture dpr1+2). Prefer a
   **capability query** (a `foo?()` the answering subclass defines) over an `instanceof`/`isWindow`-style type test
   (the type-test-elimination campaign removed those).

### 6.2 The maximal SCHEDULE/APPLY invariant (what "correct" means, precisely) — lint `[F]`

> Off-settle code may request layout only by **recording intent** (`_invalidateLayout`, or `@desired*`-then-flush). A
> layout **APPLY** (`_reLayout` / `_reLayoutSelf` / `_reLayoutChildren` / `_positionAndResizeChildren` /
> `_reLayoutScrollbars` / `recalculateLayouts`) runs synchronously **only** at: (a) the settle loop; (b) a public flush
> (`_settleLayoutsAfter`); (c) a terminal immediate-mutator self-apply (irreducible — a raw setter runs during a pass,
> where `_invalidateLayout` would throw, and the pass reads its result back in-pass); (d) the settle-time up-edge
> (already under `_recalculatingLayouts`); or (e) a documented determinism-exempt family (scroll-input / Slider /
> LabelButton / soft-wrap / collapse-`reInflating`).

This is **build-gated by lint `[F]`** (`buildSystem/check-layering.js`): a non-low-level, non-immediate-mutator method
that calls a container APPLY must DEFER or carry a conscious `# layout-apply-sanctioned: <why>` marker. Cases (a)/(b)/(c)
are exempt via the `isLowLevel`/`isImmediateMutator` predicates; (d)/(e) carry markers. When you add a new container
arrange, expect to either route its callers through the settle tiers or annotate the terminal apply with the marker and
a one-line reason.

### 6.3 The static checks (build-time — run by `./fg build` / `build_it_please.sh`)

The build **fails** on any of these; read the failing rule's message, it names the offending method.

- **`check-layering.js` — rules `[A]`–`[N]`** (the layering lint). The load-bearing ones for new layout code: `[A]`/`[E]`
  an immediate mutator must not schedule layout; `[B]` only `doOneCycle`/`_settleLayoutsAfter` may call
  `recalculateLayouts`; `[C]` a public setter must not call another public setter; `[F]` the SCHEDULE/APPLY invariant
  above; `[G]` low-level code must not call a structural self-settling wrapper; `[I]`–`[N]` the naming lattice (`__`-leaf
  purity, callback settle-neutrality, apply/notify name-consistency, callback-name convention, retired-fragment ban, and
  `[N]` the retired notify-by-mutation container seam `_announce*ToContainer` must not be re-defined — the settle-time
  up-edge replaced it, §4.1/§4.2). The predicates `isLowLevel` / `isImmediateMutator` are the single source of truth for
  the tiers — do not describe a tier in a way that drifts from them.
- **`check-dead-methods.js`** — dead-method ratchet + `dead-method-allowlist.txt`. Deleting a method drops the count;
  a *new* dead method fails unless allowlisted (prefer deleting it).
- **`check-stinks.js`** — smell ratchet (baseline counts). Currently empty (its one rule retired with
  `_settleLayoutsAfterBatch`); add a `{id, baseline, why, re}` to ratchet a new smell.
- **`check-constructors-build.js`** — every constructor must build its children through the settling wrapper
  `_buildAndConnectChildren()` over a `_buildAndConnectChildrenNoSettle` core (no inline child-building in a
  `constructor:` body), so `new Foo()` returns settled (orphan-settledness, §2.7).
- **tier-naming gate** — no leaf/arrange naming leaks (part of `./fg gauntlet`).

### 6.4 The dynamic checks (run-time)

- **`./fg gauntlet`** (from the umbrella root) — the standard gate: build + suite at **dpr1 / dpr2 / webkit** (165/165
  byte-exact) + apps smoke + tiernaming + notification-settle gate. Any layout change must pass this.
- **The danger-config determinism torture** — **mandatory for any *convergence* change** (anything touching the settle
  loop / `_reLayout` / an arrange / `_invalidateLayout` / the up-edge). `torture-headless.js` deadlocks in-session, so
  run the manual loop over the danger configs `dpr2-fastest-s8`, `dpr2-fast-s8`, `dpr1-fastest-s8`, `dpr2-fastest-s4`
  (a few rounds): pass = `RECALC_NONCONVERGENCE` **absent** + 0 test-fails. dpr2-under-load is where a bad
  synchronous→deferred *timing* change surfaces (heavy frames starve timers, drain many events/frame).
- **The two boundary gates** (siblings of the suite): the **end-of-cycle capstone** (`run-capstone-gate.sh` — no
  careless off-settle push survives to the flush, §2.7) and the **paint-readonly gate** (`run-paint-readonly-gate.sh` —
  paint schedules no layout, §2.1). Both self-test and hard-fail.
- **The re-visit detector** (for measuring convergence) — a throwaway `__seen = new Set()` reset each
  `_recalculateLayoutsBody` call, logging when a widget is processed a 2nd+ time in one flush. This is how the caret
  (372) and window (9) re-visits were measured; it is the tool for confirming a new layout is single-pass. Related
  off-by-default audits: `auditUndeclaredEndOfCycle` (enqueue-time careless-push audit) and
  `auditPaintTimeLayoutScheduling` (paint-time layout-schedule audit).

### 6.5 The gauntlet — self-contained commands

Prefer the **`./fg`** wrapper from the umbrella root (`Fizzygum-all/`) — it is cwd-correct from anywhere, kills zombie
browsers, and gates on real exit codes:

```sh
./fg build            # build + all static gates (expect "0 violations" + "done!!!")
./fg suite            # full suite, dpr1 (add nothing; it's the default)
./fg gauntlet         # build + dpr1 + dpr2 + webkit + apps + tiernaming + settle  (the standard gate)
./fg test <name>      # one macro test
./fg recapture <name> # recapture a benign inspector/reference shift
```

Raw forms (when not using `./fg`; **paths absolute** — the Bash cwd resets to the umbrella between calls, so a bare
`./build_it_please.sh` silently tests a STALE build):

```sh
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum && ./build_it_please.sh   # --keepTestsDirectoryAsIs while iterating
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/run-all-headless.js --shards=5   # --dpr=2 / --browser=webkit
# single test + instrument: LOG_FILE=<path> node scripts/run-macro-test-headless.js SystemTest_<name> [--dump-failures]
# recapture: node scripts/capture-macro-test-references.js <name> --dprs=1,2
```

A wrong layout conversion fails **deterministically at dpr1** (stale geometry → red every run); a synchronous→deferred
*timing* regression surfaces as a **dpr2-under-load flake** — that is what the torture hunts. Read
`../Fizzygum-tests/DETERMINISM.md` before touching the render/layout/input loop.

### 6.6 Gotchas (learned the hard way)

- **Stale builds are structurally guarded** — the runners refuse to run against a build older than `src/` (exit 2);
  override with `FIZZYGUM_ALLOW_STALE_BUILD=1`. Still prefer `./fg` or an absolute `cd … && ./build_it_please.sh`.
- **Separate `cd` per repo** — chaining a `Fizzygum/` build with a `Fizzygum-tests/` node script in one `&&` runs the
  script from the wrong dir (`MODULE_NOT_FOUND`). The PreToolUse guard blocks the wrong-cwd form; use `./fg`.
- **`pkill -f "Chrome for Testing"`** before every suite/torture run (zombies starve the box → infra hiccups /
  shard disconnects, which read as failures but aren't).
- **Commit via `git commit -F <file>`** — never backticks / `$()` in `-m` (the Bash tool runs bash and
  command-substitutes them). **Ask before commit/push** (review-driven project).
- **`nil` means `undefined`.** Edit only `src/**/*.coffee`; never `../Fizzygum-builds/**` (regenerated each build).

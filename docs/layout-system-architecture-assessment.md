#  Layout system — architecture assessment

**What this is.** An outside-in architectural review of Fizzygum's layout engine: what it actually does,
whether it is *byzantine* or merely *highly unusual* relative to the field, and where its architecture/flow
could be improved. It is a companion to `deferred-layout-OVERVIEW.md` (which is the canonical record of the
deferral *campaign*); this doc steps back and assesses the *engine* the campaign produced.

**State assessed.** Fizzygum master at/after the deferred-layout capstone (`a7463bbc`), with the
`_reLayout*` method-family naming. Written 2026-06-22. *(§2.7 — the end-of-cycle flush's categories,
detection toolkit, and the coalescing API — was appended 2026-06-26 at master `f4626843`, folding in the
conceptual core of the end-of-cycle-flush drawdown campaign; the live remaining-work plan is
`end-of-cycle-flush-endgame-plan.md`.)*

> **Line numbers are approximate — the METHOD NAME is authoritative; `grep` it.** (Same convention as the
> OVERVIEW; every shipped edit shifts lines.) Every file:line below was read against source while writing this.

---

## 1. Verdict in one paragraph

The layout engine is **not byzantine** — it is a deliberately *unusual* one. Mainstream retained-mode toolkits
(WPF, Flutter, Android, Qt, CSS block/flex) run a structured **two-pass `measure` → `arrange`**: one bottom-up
sizing pass, one top-down positioning pass, both O(n), guaranteed to terminate. Fizzygum instead runs a
**work-list / dirty-set settle that iterates to a fixed point** — the same family as **browser reflow +
invalidation**, **constraint solvers** (Cassowary / Auto Layout), and **spreadsheet/reactive recalculation**.
That is exotic for a GUI toolkit but it is a *recognized* pattern, and most of its complexity is **essential**,
given three hard constraints the design genuinely faces (§3). The genuinely *accidental* complexity is narrow
and is already being paid down with lints + a determinism soak. The single most consequential oddity is the
**absence of a pure measure pass**, replaced by **synchronous mutate-then-read-back** for content sizing — and
the framework already contains the clean alternative on one of its own code paths (§2.5). Closing that gap is
the highest-leverage architectural change available (§4.1).

---

## 2. What the system actually does

### 2.1 The per-frame spine

`WorldWdgt.doOneCycle` (`src/WorldWdgt.coffee` ~:1266) runs, in order:

```
updateTimeReferences
show errors from previous cycle           (incl. layout errors deferred out of the settle loop)
playQueuedEvents()                         (~:1276 — dispatch input)
replayTestCommands / step functions        (~:1280–1288 — animation, stepping widgets)
recalculateLayouts()                       (~:1291 — the engine's end-of-cycle settle)
add pinout/highlight overlays
updateBroken()                             (~:1299 — paint dirty rectangles)
```

So layout is wedged between input/stepping and paint.

### 2.2 The flush model — how often layout actually settles

> **Common misreading (worth stating because it is the natural one): "there is one layout flush per frame."
> That is false.** There is one *engine-scheduled* flush per frame; the *total* is generally several.

`recalculateLayouts()` (`WorldWdgt.coffee` ~:856) is invoked from **exactly three** sites:

| # | Site | When | Cardinality |
|---|---|---|---|
| 1 | `WorldWdgt.coffee` ~:1291 (end of `doOneCycle`) | every frame, by the engine | **1 / frame** |
| 2 | `Widget.mutateGeometryThenSettle` ~:783 | every **public geometry mutation** | **1 / mutation** |
| 3 | `Widget.settleLayoutsOnceAfter` ~:808 | every **batch** | 1 / batch |

The 7 public mutators all route through `mutateGeometryThenSettle` and therefore **self-settle** — they record
the desired change and then run a full `recalculateLayouts()` *before returning*:
`setBounds` ~:813, `fullMoveTo` ~:1324, `setExtent` ~:1543, `setWidth` ~:1667, `setHeight` ~:1703,
`add` ~:2375, `addRaw` ~:2397. The flush is **skipped** when the target is an *orphan* (attached to neither
world nor hand — `mutateGeometryThenSettle` ~:771) and **coalesced** when inside a `settleLayoutsOnceAfter`
batch (~:778). Nested public setters do **not** stack flushes — they *throw* (the re-entrancy guard, ~:759).

So the honest formula is:

> **flushes / frame  =  (self-settling public mutations executed this frame)  +  (top-level batches)  +  1**
> &nbsp;&nbsp;&nbsp;&nbsp;— minus mutations skipped for orphans, minus those coalesced inside a batch.

**Evidence this is by design, not incidental:**

- The code documents sequential per-call flushing in so many words (`Widget.coffee` ~:743): *"Calling several
  public setters in SEQUENCE is fine — each completes, flushing once, before the next begins."*
- A frame dispatches its **whole** event backlog, not one event: `playQueuedEvents` (`WorldWdgt.coffee` ~:1190)
  loops `for event in @inputEventsQueue` and returns only at a *future-timed* event (~:1197). Under load —
  the dpr2 heavy-frame case the determinism docs warn about — many events are drained in one frame.
- A concrete per-event flush: the resize handle's drag handler `HandleWdgt.nonFloatDragging`
  (`src/HandleWdgt.coffee` ~:218) calls `@target.setExtent` / `fullMoveTo` / `setWidth` / `setHeight` — each a
  self-settling flush. A resize gesture emits a *stream* of these; several landing in one heavy frame ⇒ one
  flush *per drag event*, plus the end-of-cycle flush.

**Why two settle points exist (and why the end-of-cycle one is load-bearing, not a redundant safety net).**
The two flush kinds drain two different populations of dirtiness:

- **Per-call flushes (site 2)** settle mutations made through the **public deferred API** so an event handler
  always observes a *consistent world between calls* — the entire reason for the self-settling tier (no caller
  ever has to "yield and wait for layout").
- **The end-of-cycle flush (site 1)** drains everything that invalidated layout *without* going through that
  API and so never self-flushed: raw/silent/fullRaw mutations (float-drag moves, `wheel` scroll adjustments,
  step-function animations) that enqueue via the seam's out-of-pass `invalidateLayout` arm, plus direct
  `invalidateLayout()` callers (`setMaxDim` ~:3804, `showAdders`/`removeAdders`, collapse, …). Without this
  flush those changes would reach paint unsettled.

`settleLayoutsOnceAfter` (`Widget.coffee` ~:795) exists *because* per-call flushing is O(mutations): a
multi-add builder would otherwise do N full settles, so the batch collapses them to one
(`WindowWdgt._buildAndConnectChildren` ~:334 is the live caller).

**Consequence.** A heavy frame's final layout is the **composition of several full settle passes, in event
order**. This is sound only because each settle is a pure function of geometry-at-that-instant and converges to
the same fixed point regardless of iteration count — but it makes per-frame cost `flushes × cost-per-settle`,
and it is a real reason determinism is hard: the *sequence* of settles within a frame (and the event-draining
order driving it) must be deterministic, not just each settle in isolation.

**The normative invariant under the formula: one flush per *outermost* public mutation — and the throw is what
enforces it.** The formula above is descriptive; the *design rule* it realizes is sharper, and it is what makes a
layout system this stateful safe to keep extending. A public entry point's single tier (`_settleLayoutsAfter`, née
`mutateGeometryThenSettle`) sets `world._inLayoutMutation = true`, runs the mutation core, then runs
`recalculateLayouts()` **exactly once**. Its re-entrancy guard (~:759) THROWS (`FLOWRULE_VIOLATION`) the moment a
public setter is reached on an *attached* widget while `_inLayoutMutation` (or `_recalculatingLayouts`) is already
true — so once you are inside an entry point's settle, **no nested public call can open a second settle.** Internal
code is thereby *forced* onto the non-settling `_xNoSettle` cores and the raw/silent setters, which schedule nothing.
Net: **the outermost attached public mutation owns the single flush; everything underneath rides it.** (Sequential,
non-nested public calls each get their own one flush — they don't interleave, so that's fine; it is *nesting* that is
forbidden.)

**The throw is the enforcement, not a convention.** Clean layering here is a *checked* invariant, not a guideline the
authors hope to honour: the runtime tripwire (`FLOWRULE_VIOLATION`, raised by both `_settleLayoutsAfter` and
`_invalidateLayout`) **plus** the build-time layering lint (`buildSystem/check-layering.js`: rules [A]/[E] catch the
name-recognized internal methods directly, and [G] forbids low-level code from calling a *structural* self-settling
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
- **The batch tier is the deliberate exception.** `_settleLayoutsAfterBatch` (née `settleLayoutsOnceAfter`) ABSORBS
  nested settles to coalesce a genuine bundle (a multi-add builder) into one flush, so the fully general invariant is
  **"one flush per outermost public mutation, whether single or batch."** The orphan guard adds a third case:
  construction of a *detached* subtree settles **zero** times until it is added — so building innards is flush-free by
  construction. (The end-of-cycle drawdown campaign — `end-of-cycle-flush-drawdown-plan.md` — is the ongoing work of
  bringing every remaining flow into this invariant; re-probing several "LEAVE" verdicts found flows quietly outside
  it. §2.7 develops the categories, the detection toolkit, and the coalescing API that campaign produced.)

### 2.3 The settle engine: invalidate **up**, re-layout **down**, iterate to a fixed point

`_recalculateLayoutsCore` (`WorldWdgt.coffee` ~:869) is the whole engine:

```
until widgetsThatMaybeChangedLayout is empty:           (~:878)
   pop valid widgets off the tail
   take a dirty widget; walk UP parents while the parent is also dirty   (~:917)
       (stop at a valid parent, or at a freefloating boundary  ~:918)    → "top of a broken chain"
   tryThisWidget._reLayout()       (~:927 — lays out that subtree top-down, marking each node valid)
```

Two facts make this a *fixed-point* loop, not a fixed *number* of passes:

1. **Invalidation climbs up; layout flows down.** `invalidateLayout` (`Widget.coffee` ~:3756) pushes the
   widget, marks it invalid, then recurses to `@parent` (unless freefloating, ~:3773) — so one deep change
   enqueues the whole ancestor chain, and the loop then does a single top-down `_reLayout` from the topmost
   dirty ancestor. **In the common case a localized change is "climb up once, lay out down once" — effectively
   one top-down arrange.** `_reLayout` ends in `markLayoutAsFixed()` (~:4150), popping the node.
2. **A `_reLayout` can re-dirty something *outside* the subtree it just settled**, via the re-fit seam
   `_reFitContainer` (`Widget.coffee` ~:1642), whose in-pass arm *enqueues* a container mid-pass. This is the
   only thing that produces genuine iteration: the clock → inner-window → outer-window cascade re-enqueues
   containers, so the loop runs another `_reLayout`, and again, **until the queue drains.**

> **So the right mental model:** one *up-then-down* per localized change; degenerating into true
> *up/down/up/down* fixed-point iteration only across **container boundaries that re-dirty each other**
> (freefloating content ↔ its container). The iteration is concentrated in a small, specific part of behavior.

Termination is guarded by a hard `recalcIterationsCap = 100000` freeze-backstop (~:875), a per-container
re-entrancy guard `_adjustingContentsBounds` (e.g. `SimpleVerticalStackPanelWdgt._positionAndResizeChildren`
~:102), and the rule that `invalidateLayout` **throws** if reached mid-pass (~:3768) so a raw setter can never
re-dirty the pass it is running inside.

### 2.4 The root constraint: accessors read *applied* geometry → mutate-then-read-back

Every geometry accessor (`width()`, `height()`, `position()`, …) reads the *applied* `@bounds`. There is no
way to ask "where is this heading." So a container that must size itself to its content cannot *measure* the
content — it **mutates the child and reads the result back**. The vertical stack does exactly this
(`SimpleVerticalStackPanelWdgt.coffee` ~:139, ~:158):

```coffee
widget.rawSetWidthSizeHeightAccordingly recommendedElementWidth   # mutate child (synchronously _reLayout's it)
stackHeight += widget.height()                                    # read the applied result back
```

**This read-back is the cause of most of the engine's complexity.** It forces the child's `_reLayout` to run
*synchronously, now* (so `height()` is fresh), which is why low-level setters apply layout immediately
(`rawSetWidthSizeHeightAccordingly` ~:706 calls `@_reLayout()` at ~:711 and *returns the height* as the
"Path-B de-read-back" workaround), why `invalidateLayout` must throw mid-pass, and why the cross-container
notifications had to be synchronous before the deferral campaign converted them to the enqueue-mid-pass seam.

### 2.5 Two sizing philosophies coexist (the most important structural finding)

This is not spelled out in the campaign docs, but it is the crux for any future architecture work:

| | **Horizontal stacks** | **Vertical stacks / window content / scroll content** |
|---|---|---|
| Sizing model | **min / desired / max**, computed **bottom-up** and cached: `getRecursiveMinDim/DesiredDim/MaxDim` (`Widget.coffee` ~:3835–3930) | **proportional**: child width = f(*current* container width), `getWidthInStack` (`VerticalStackLayoutSpec.coffee` ~:31) |
| How a container learns content size | a **pure measure** (no mutation) | **mutate the child, read `@bounds` back** (§2.4) |
| Arrange | 3-case distribution in base `_reLayout` (`Widget.coffee` ~:4059–4147): under-min shrink / desired-margin grow / max-margin grow | sum the read-back heights (`_positionAndResizeChildren`) |

The horizontal path is **a textbook constraint box layout** (essentially flexbox with min/preferred/max + grow
factors) with a clean measure/arrange separation. The vertical/window/scroll path is the imperative,
read-back, fixed-point path. *The framework already contains a clean measure engine — it just isn't used on
the side that hurts.*

The proportional model is what creates the cyclic coupling: `getWidthInStack`
(`width = wEl + elasticity·(availW·wEl/wStk − wEl)`, capped at `availW`) makes child width a *continuous
function of container width*, and container size depends back on children. When that loops through an
aspect-locked widget (a square clock in a window-in-window), width depends on height depends on width — a
genuine cycle. The capstone's fix — give aspect content `elasticity 0` so the converged-width term multiplies
out (OVERVIEW §5) — is exactly right: it **breaks the cycle** rather than iterating through it.

### 2.6 Convergence is empirical and capped, not structural

Termination today rests on: each `_reLayout` ending in `markLayoutAsFixed`; the `_adjustingContentsBounds`
re-entrancy guard; manual cycle-breaking (the `elasticity 0` fix); a 20-minute determinism torture soak; and
the `recalcIterationsCap = 100000` backstop that exists to convert a hypothetical non-convergence into a loud
bail instead of a freeze (~:880). That is a defensible engineering position — but it means convergence is a
*verified property of the current constraint set*, not a *guaranteed property of the algorithm*.

### 2.7 The end-of-cycle flush: what survives it, the categories, and coalescing

§2.2 established *that* the end-of-cycle flush (site 1, run once per frame by the engine in `doOneCycle`) drains
everything that invalidated layout *without* self-settling through the public API. This section steps in one level
closer and assesses *what* legitimately rides that flush versus what is a leak — the vocabulary the **end-of-cycle
drawdown campaign** settled on, how a survivor is detected, and the one intentional-batching mechanism
(**coalescing**) the engine now exposes as public API. It is the conceptual companion to the campaign's operational
docs: `end-of-cycle-flush-drawdown-plan.md` (the worked playbooks + patterns + verification), `end-of-cycle-flush-
inventory.md` (the by-action audit history), `coalescing-measurement.md` (the measurement harness), and
`end-of-cycle-flush-endgame-plan.md` (the live remaining-work plan and current numbers).

**An end-of-cycle survivor, precisely.** A widget's `_invalidateLayout` push survives to the end-of-cycle flush iff
*no* self-settling flush (site 2 per-mutation, or site 3 batch) drained the queue between that push and `doOneCycle`'s
`recalculateLayouts()`. So a survivor is, by construction, *a layout invalidation that did not self-settle.* Under the
one-flush-per-outermost-public-mutation invariant (§2.2), an **empty** end-of-cycle queue is the *ideal* steady state —
so every survivor is worth a question: should it have settled, and if it legitimately should not, *why* is it here?
The campaign has driven the interaction-frame survivor count from **1244 → ~18 records** answering exactly that,
contributor by contributor.

**The three faults (the classification rubric).** A survivor is one of three things, each demanding a *different* fix —
and naming which is the whole job:

| Fault | What it is | The fix |
|---|---|---|
| **CONVERT** | a discrete **public API mutator** that failed to self-settle (it defers, or leans on an *unrelated* later event to settle for it). A public mutator must leave the world layout-consistent *on return*; one that doesn't is a contract breach. | wrap its body `@_settleLayoutsAfter => @_<name>NoSettle(…)` — a thin public settle-wrapper over a non-settling core; its high-frequency *internal* callers use the core, so a gesture stream still rides one flush |
| **ELIMINATE** | **wasted work** — a re-fit that changes nothing: a freefloating child's teardown re-fitting the world; a layout-inert caret/handle re-fitting its container; a container re-fit scheduled while the container is mid its own `_positionAndResizeChildren`; a relayout during construction on an orphan | stop scheduling it — the *narrowest* provably-byte-identical guard |
| **COALESCE** | a genuine **per-input-event STREAM** (drag-move, wheel, key-repeat) where N mutations land in one frame; deferring them onto the one end-of-cycle flush saves (N−1) flushes/frame | **DECLARE** it via a `*Coalesced` public entrypoint (below). NOT a leak — an intentional, *measured*, *declared* batching |

**The discriminator.** Pin the *actual* enqueue stack (see "Detecting a survivor") and ask: **"is a public API mutator
on it, returning unsettled?"** Yes → CONVERT. No, and the raw/internal move that enqueued belongs to a widget that
*cannot affect* the container it dirtied → ELIMINATE. It is a raw event stream draining straight from
`playQueuedEvents` → COALESCE. Reasoning from the by-action *name* is not enough: the campaign both **converted** the
contained-text *API* path (a real public-mutator leak) and **eliminated** the visually-identical contained-text *caret*
path (wasted layout-inert-mover work) — opposite fixes the action label alone would have conflated.

**Three further categories sit alongside the faults** — not themselves leaks to fix, but you must recognize each so you
don't chase it:
- **macro-driver** — the SystemTest harness (`theTest_InputEvents_Macro`) building fixtures mid-test. Long treated as
  "out of scope" because it is test code, not product — but the current direction is to drive these to zero too *where
  they trace to a product code path* (a real `add` / re-fit the harness merely triggers, which any app would also hit).
- **orphan / construction** — an off-world, under-construction widget legitimately defers and settles when it is
  attached (the orphan guard, §2.2). EXCLUDED from the careless set by construction; the audit hook below skips it.
- **irreducible** — a coalesced detached-subtree record that cannot be skipped *at its seam* because it shares the
  construction invalidate path. The documented case is `PanelWdgt.childRemoved`'s off-world basement re-home (a pop-up
  close re-homing a lost widget into the never-painted basement, which is also invalidated by construction-path
  `_addNoSettle` / raw-move / filter seams that can't be safely orphan-skipped). One such record is known and expected;
  the mandate-compliant disposal is to *declare* it (below), not to exempt it.

**Why this rubric exists at all — and where it goes.** The interesting architectural point is that this whole
classification *only exists because* the engine is the deferred work-list settle of §2.3, not a structured
measure→arrange. In a two-pass toolkit there is no "did this settle?" question — arrange always runs once, top-down.
Here, *because* invalidation is decoupled from layout (climb-up / relayout-down), every mutation site faces a real
choice — settle now, ride the flush, or it's wasted — and the campaign's value is making that choice *checked* rather
than ad-hoc, which is exactly what keeps a system this stateful safe to keep extending. The keystone change in §4.1 (a
pure measure pass) would dissolve much of it: a container that *measures* its children never mutates-then-reads-back, so
far fewer sites schedule layout at all, and the residual rubric shrinks to the genuine event streams.

#### Detecting a survivor

Four tools, in increasing precision:

- **The sharded audit** (`scripts/end-of-cycle-audit/run-audit-loop.sh` → `scripts/.scratch/audit/_SUMMARY.md`,
  ~1.5 min): runs the whole 165-test suite headless with a behaviour-neutral, inspector-invisible prelude, counts
  end-of-cycle survivors per frame, and attributes each to a by-action *group*. It is **run-to-run noisy by a few
  records** (the metric counts how layout work is *distributed across frames*, which is wall-clock-sensitive) — so read
  it as order-of-magnitude and treat "a row → 0" as the signal. Recipe + neutrality gate (`installed OK: 165/165`):
  `end-of-cycle-audit-tooling.md`.
- **`WorldWdgt.auditUndeclaredEndOfCycle`** (a DEBUG flag, default off) — the in-engine version of the audit, and the
  basis of the campaign's eventual *gate*. Its hook in `Widget._invalidateLayout` records the ctor of every push that is
  OFF-settle (`!world._inLayoutMutation`), ATTACHED (`!@isOrphan()`), and UN-declared (`world._coalescedDeclarationDepth
  == 0`) into `world._undeclaredEndOfCyclePushes`; `WorldWdgt.recalculateLayouts` then logs them at the end-of-cycle
  flush as `UNDECLARED-EOC frame=N total=M :: Ctor xK`. This is precisely **the "careless" set** — the set a future
  gate will reject. Orphan pushes and declared-coalesced pushes are excluded by construction, so what it reports is
  exactly the convert/eliminate target.
- **The stack-probe** — the only reliable *localizer*. The audit's `sig` lies: its `shortSig` truncates to ~3 frames
  AND filters `eval` frames — and since Fizzygum compiles every class in-browser, *every framework method is an `eval`
  frame* — so it collapses to a useless `Object.playQueuedEvents < e` that hides the real chain. Instead inject a
  throwaway `PRELUDE_JS` that patches `_invalidateLayout` to `console.log(new Error().stack)` UNFILTERED, gated on
  `!world._inLayoutMutation` (so you log only genuine off-settle survivors, not the in-settle enqueues a public setter
  is about to drain). One run names the exact origin line. **Reason from the stack, never the by-action tag** — the tag
  has repeatedly lied.
- **The disable-probe** — the convert-vs-eliminate decider. No-op the suspected-redundant re-fit, build, run the suite:
  byte-identical ⇒ it was wasted ⇒ ELIMINATE; tests fail ⇒ load-bearing ⇒ CONVERT. ~10 minutes, opposite verdicts.
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

**Mechanism** — three small pieces on `world` (`Widget.coffee` ~:3910–3947, `WorldWdgt.coffee` ~:84–99):
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
core is **internal-only** and feature code must not reach into it directly. This is also the disposal route for an
*irreducible* survivor: if a record genuinely cannot be converted or eliminated at its seam, the mandate-compliant move
is to bring it under `_coalescedDeclare` (declare it) so it leaves the careless set — a **declaration**, not an
allowlist exemption.

**Measuring whether to coalesce.** Whether a stream *earns* a `*Coalesced` entrypoint is a performance question, never a
correctness one — render happens once per frame *after* all events, so coalesced-vs-self-settle is byte-identical; only
the flush count per frame differs. The harness in `coalescing-measurement.md` measures mutations-per-frame for a gesture
at two speeds; the verdict rule: **max ≈ 1 → coalescing saves nothing → use the plain self-settling setter**; **max ≫ 1
→ coalescing is warranted** (and how much it matters scales with the settle's queue length — a 3-widget settle is cheap,
a 300-widget one is not, so weigh muts/frame × qlen). Read the **normal**-speed rate as real usage (headless `fastest`
crams the whole gesture into 1–2 cycles and over-states it). The divider drag measured a median **16 (up to 56)**
muts/frame at normal speed → coalescing warranted; that worked case study is in the harness doc.

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
`_reFitContainer`, and gated the invariant with build-time lints A–F plus the determinism soak. That is the
opposite of byzantine — it is a system whose owner is paying down historical `fixLayout` debt with proofs.

**The parts that *do* read byzantine — the fair targets:**

- **Behavior keyed off scattered global phase booleans** on `world` (`_recalculatingLayouts`,
  `_inLayoutMutation`, `_batchingLayoutSettling`): the legal operation (throw / enqueue / invalidate / apply)
  depends on *which phase you are in*, and that knowledge is spread across `Widget` and `WorldWdgt`.
- **Mutate-then-read-back** (§2.4) and the **two coexisting sizing philosophies** (§2.5).
- **Convergence is empirical, not structural** (§2.6).

---

## 4. Improvement directions

Ranked by leverage. The three approaches the campaign already **falsified** are *not* re-proposed and are
listed as "do not revisit" at the end. Each suggestion is determinism-sensitive and must clear the soak.

### 4.1 Add a pure *measure* protocol to kill the read-back — **highest leverage; attacks the root**

Introduce a side-effect-free `preferredExtentForWidth(availW) → {w, h}` that **never touches `@bounds`** — i.e.
generalize what `getRecursive*Dim` already is for horizontal stacks (§2.5) to text (compute wrapped height for
a width *without committing the wrap*) and to the vertical/window/scroll path. Then `_positionAndResizeChildren`
sums *measured* heights instead of mutating each child and reading `height()` back.

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

**Honest caveat.** This is the big change: byte-exact text measurement must reproduce wrap geometry without
committing it, and every result must clear the soak. And measure alone does **not** remove the genuine
width↔height cycle of aspect-locked nested content — that is irreducible in any single-pass system (it is why
CSS needs special `aspect-ratio` rules and Flutter forbids unbounded-both-axes). The `elasticity 0` fix already
breaks that cycle correctly, so the end-state is: *measure+arrange handles everything except the handful of true
cycles, which stay explicitly cycle-broken — and the fixpoint iteration becomes unnecessary in principle.*

### 4.2 Make convergence *structural*, not empirical (falls out of 4.1)

Once 4.1 removes read-back coupling, classify each layout dependency edge by axis and direction — "width flows
down" (proportional) vs "size flows up" (content-sized) — and add a lint (in the spirit of `check-layering.js`
rules A–F) that flags any new edge coupling both directions on the same axis of the same widget. If the graph
is a per-axis DAG, a single measure+arrange terminates with zero iteration, and `recalcIterationsCap` downgrades
from a *recovery path* to a *should-never-fire assert*. This converts §2.6's empirical invariant into a
build-enforced one — the same move already made for the flow rule.

### 4.3 Encapsulate the engine state behind one owner object

Move `widgetsThatMaybeChangedLayout` + the three phase booleans + the `_reFitContainer` dispatch into a single
`world.layoutEngine` with an explicit phase enum (`IDLE | MUTATING | SETTLING | BATCHING`) and one documented
table of "legal operations per phase." Cohesion, not algorithm change — but it directly targets the part that
*reads* byzantine (§3), because the "throw vs enqueue vs invalidate vs apply" rule is currently reconstructed
from booleans scattered across two classes. (Bonus: an engine *object*'s methods are not `Widget` members, so
this sidesteps the inspector-recapture cost of adding methods to base `Widget`.)

### 4.4 Split dirtiness into two flags

Replace single `layoutIsValid` + climb-and-enqueue-the-whole-chain with the standard browser/React pair:
**`needsLayout` (this node)** and **`hasDirtyDescendant` (a child needs layout)**. `invalidateLayout` then sets
one bit on the node and flips `hasDirtyDescendant` up the chain (O(depth) marking but O(1) *enqueues* — only
roots-with-dirty-descendants go on the work-list), and the loop walks *down* from those roots. It also makes the
"freefloating child laid out twice" sub-optimality (§4.5) disappear naturally. Determinism-sensitive.

### 4.5 Quick win — the freefloating walk-up TODO (`WorldWdgt.coffee` ~:900–915)

The code itself flags that the walk-up stops at the *first valid* parent rather than the *topmost invalid* one,
so a freefloating child can be laid out twice (first with a stale parent size). Stopping at the
last-invalid-on-the-way-up is a small, local fix that removes redundant double-layout. Optimization, not
correctness; soak it (anything in this loop is cadence-sensitive).

### 4.6 Minor — flush-count hygiene in multi-mutation handlers

Following from §2.2: a handler that performs several geometry mutations does one full settle *each*. Where a
gesture changes both extent and position, prefer the compound `setBounds` (one flush) over `setExtent` +
`fullMoveTo` (two), or wrap the sequence in `settleLayoutsOnceAfter`. Pure micro-optimization, but it is the
productive corollary of the corrected flush model and costs nothing.

### Do **not** revisit (already falsified — see the OVERVIEW)

- **Path A — pending-aware accessors** (OVERVIEW §6): one accessor cannot serve both pending- and applied-needers.
- **Reformulating the proportion fraction** (OVERVIEW §5): the stored `wEl/wStk` fraction is irreducibly
  load-bearing (base-width menu, `DONT_MIND` fill, per-instance text); three reformulations were falsified.
- **Routing `ScrollPanelWdgt.add`/`addMany`/`showResize…` through `settleLayoutsOnceAfter`** (OVERVIEW §11
  PROOF 2): probed 2026-06-22 and rejected — it deterministically diverged nested-scroll content/thumb geometry
  at dpr1 for zero gain.

---

## 5. Appendix — verified code map

All read against source while writing this (names authoritative; lines approximate).

- **Per-frame cycle:** `WorldWdgt.doOneCycle` ~:1266 · `playQueuedEvents` ~:1185 (whole-queue drain ~:1190,
  future-event return ~:1197).
- **Settle engine:** `recalculateLayouts` ~:856 (re-entrancy throw ~:861) · `_recalculateLayoutsCore` ~:869
  (until-loop ~:878; cap `100000` ~:875; walk-up ~:917; freefloating stop ~:918; `_reLayout` call ~:927;
  non-flushing catch ~:938).
- **Self-settling public API:** `mutateGeometryThenSettle` `Widget.coffee` ~:748 (flush ~:783; re-entrancy
  throw ~:759; orphan guard ~:771; batch guard ~:778) · `settleLayoutsOnceAfter` ~:795 (flush ~:808). The 7
  mutators: `setBounds` ~:813, `fullMoveTo` ~:1324, `setExtent` ~:1543, `setWidth` ~:1667, `setHeight` ~:1703,
  `add` ~:2375, `addRaw` ~:2397.
- **Invalidation / re-fit:** `invalidateLayout` ~:3756 (mid-pass throw ~:3768; climb ~:3773) ·
  `_reFitContainer` ~:1642 · `_reFitContainerAfterRawGeometryChange` ~:1619 ·
  `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` ~:1606.
- **Apply bodies:** base `Widget._reLayout` ~:3985 (`markLayoutAsFixed` ~:4150; horizontal-stack 3-case
  distribution ~:4059–4147) · `rawSetWidthSizeHeightAccordingly` ~:706 (synchronous `_reLayout` ~:711, returns
  height) · `getRecursive{Desired,Min,Max}Dim` ~:3835–3930.
- **Containers:** `SimpleVerticalStackPanelWdgt._positionAndResizeChildren` ~:100 (read-back ~:139/~:158;
  `_adjustingContentsBounds` guard ~:102) · `VerticalStackLayoutSpec.getWidthInStack` ~:31 (elasticity field
  ~:12) · `ScrollPanelWdgt._reLayout` ~:282 / `_positionAndResizeChildren` ~:312 / public-endpoint applies
  `add`·`addMany`·`showResize…` ~:196/~:202/~:207 · `WindowWdgt._positionAndResizeChildren` ~:418 /
  `_buildAndConnectChildren` batch ~:334.
- **Vocabulary:** `LayoutSpec.coffee` (`ATTACHEDAS_FREEFLOATING`, `…_VERTICAL_STACK_ELEMENT`,
  `…_WINDOW_CONTENT`, `…_STACK_HORIZONTAL_*`, `…_CORNER_INTERNAL_*`).
- **Concrete multi-flush source:** `HandleWdgt.nonFloatDragging` `src/HandleWdgt.coffee` ~:218
  (`setExtent` ~:227 / `fullMoveTo` ~:229 / `setWidth` ~:232 / `setHeight` ~:235).

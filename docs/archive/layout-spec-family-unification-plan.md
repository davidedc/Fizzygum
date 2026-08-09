> **ARCHIVED — COMPLETE (authored + executed 2026-08-04, one session).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Layout spec-family unification — one per-child spec object family, shared axis-parameterized engines, scaffolds as product

**STATUS: ✅ EXECUTED IN FULL, 2026-08-04 — authored, fact-checked and executed the same day, in one
session. All six phases landed; every phase gate green (final: full gauntlet 14/14 legs at 274 tests +
`fg homepage`). The §11 execution ledger is the authoritative record, including the deviations-with-reasons
(the stash lifecycle, the role bit, the [D]-forced public `divisionBox()`, the whenAllLoaded gallery wrap)
and the owner's §8 decisions (chrome → lazy `authoring`; both extras taken). Present-tense residue:
`docs/architecture/layout.md` §4.2.**

*(the original plan header follows, kept verbatim)*

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-04 against Fizzygum HEAD of that date; every `file:line` below was verified that day.
⚠ Line numbers drift — the quoted method/class names are authoritative; re-grep before trusting a line.

**Owner directives for this arc (2026-08-04, verbatim intent):** ignore test churn / recapture cost; no
backwards compatibility — delete legacy code (no saved worlds of importance, cf. memory
`no-serialization-compat-obligations`); Do The Right Thing — clean / elegant / uniform. Dive deep, be meticulous.

**MANDATE.** Complete elimination of the split layout-configuration story — the `LayoutSpec` integer-enum
grab-bag, the six loose per-widget constraint fields, the three ad-hoc corner fields — replaced by ONE
per-child spec-object family with polymorphic dispatch, ONE axis-parameterized division engine (which is what
makes split panes and border layouts fall out by composition), and the drag-drop layout scaffolds promoted
from dev-tools toy to product surface. NOT in scope: burying the enum under nicer names, keeping the enum
"for compatibility", or adding a parallel mechanism next to the old ones. The old encodings are DELETED.

---

## §0 Orientation

**Fizzygum** is a CoffeeScript GUI framework ("web OS" on one `<canvas>`, Morphic-descended). ~470 classes,
one per file, no module system, all globals; build via `fg build`, tests are 269 pixel-exact SystemTests
(`fg presuite` / `fg gauntlet`). Read `Fizzygum/CLAUDE.md` and **`docs/architecture/layout.md` in full**
before touching anything — the layout doc's §8 rulebook and §7 zero-invariants are the contract every phase
below must keep.

**Where the layout system stands (all of this landed and pushed in June–July 2026):**
- The settle engine is done: three settle tiers (public self-settling wrappers over `*NoSettle` cores;
  immediate mutators that only mutate; off-settle intent via `_invalidateLayout`), ordered root-down walk,
  settle-time up-edge, all suppression booleans deleted, enforced by build lints + runtime throws
  (`layout.md` §2–§3).
- The sizing FORMULA is unified: one constraint-box law
  `width = round(min(availW, desired + grow·(availW−desired)))` on the vertical side
  (`VerticalStackLayoutSpec`), a min/desired/max 3-regime division on the horizontal side, pure
  `preferredExtentForWidth` measures everywhere, zero re-visit and zero census baselines
  (`docs/archive/sizing-model-unification-plan.md`).
- What was **never** unified is the *configuration story*: HOW a child's layout participation is
  represented. That is this arc.

**The critical reframe (do not lose this):** the two stack engines are not competitors — they are
**complementary halves that never overlapped**. The horizontal engine is a *main-axis division* law (how do
siblings split the row's width: min/desired/max, 3 regimes) with NO cross-axis story (children are simply
stretched to the container's full height — the enum constant literally says
`VERTICALALIGNMENTS_UNDEFINED`). The vertical engine is a *cross-axis fit* law (how wide is each element
within the column: desired+grow+alignment) with NO main-axis division (heights hug content; nothing
distributes available height among siblings). A border layout / split pane needs main-axis division **on the
vertical axis** — which neither engine offers today, but the horizontal engine's law provides as soon as it
is axis-parameterized. That single generalization, plus a vertical twin of the existing divider widget, is
the entire capability gap between today's system and Swing-style N/W-C-E/S layouts built by pure widget
composition.

**Why specs on the CHILD (and not Swing's parent-side manager):** it already is the house style. Six of the
seven existing mechanisms store the constraint on the added child; there is no `container.constraintsFor(child)`
map anywhere. The modern analogue is CSS flexbox / WPF attached properties: parent declares the strategy,
child carries its own grow/align/size wishes. This arc completes that shape rather than importing a foreign one.

---

## §0.5 Cold-execution protocol

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status` (orientation: repo SHAs, build freshness, verdicts).
2. Read `docs/architecture/layout.md` (369 lines) in full. Then this plan in full. Then skim
   `docs/archive/sizing-model-unification-plan.md` §9 (the D2-def capture semantics you must preserve verbatim).
3. Re-run the §1 census commands and diff against the tables here; if counts moved, update this plan's §1
   before proceeding (the tree may have drifted since authoring).
4. Execute phases **in order** (P0 → P6). Each phase names its gate; a sub-batch inside P1/P2 is not done
   until `fg presuite` is green with the stated byte-identity expectation. Close each phase with the stated
   gauntlet/gate set. Long runs: launch in background with a log + verdict file, never foreground-poll
   (`CLAUDE.md` shell discipline). ⚠ Never edit src while a suite/gauntlet is running (memory:
   `never-edit-a-running-bash-script`).
5. **Byte-identity is the falsification instrument in P1/P2.** Those phases are pure refactor: ANY pixel
   diff there is a bug in the refactor — fix it, never recapture (the owner's "ignore recapture churn"
   applies to the new-capability phases P3–P5 and to inspector-member-list churn only). Cf. memories
   `no-conclusions-before-evidence`, `byte-identical-not-sacred-for-benign-inspector-recapture`.
6. Two failed fix shapes for the same failure = wrong model — stop and re-frame (memory
   `stop-iterating-fix-shapes-after-two-falsifications`).
7. Commits: per owner standing prefs (`ask-before-commit-push`, `owner-workflow-long-arcs`) — run phases
   straight through with gates, ONE end-of-arc review, present commit message(s) and wait; do not push
   without an explicit OK. Use `git commit -F <file>` (backticks corrupt `-m`).
8. Close with the `/close-arc` ritual (docs woven via `/docs-sync`, memory updated, plan → `archive/` + INDEX).

---

## §1 Current state — the seven mechanisms (verified 2026-08-04)

Census commands (re-run from `/Users/davidedellacasa/code/Fizzygum-all/Fizzygum/src`):

```
rg -n "ATTACHEDAS_" --no-heading | awk -F: '{print $1}' | sort | uniq -c | sort -rn
rg -l "layoutSpecDetails"
rg -n "layoutSpec_cornerInternal|SPREADABILITY|FractionalInHoldingPanel" --no-heading
rg -n "\b(minWidth|minHeight|maxWidth|maxHeight|desiredWidth|desiredHeight)\b" --no-heading
```

| # | Mechanism | Stored on | Covers | Key sites |
|---|---|---|---|---|
| M1 | `layoutSpec` — integer enum tag, 9 `ATTACHEDAS_*` constants | child (`Widget::layoutSpec`, default `ATTACHEDAS_FREEFLOATING`, `Widget.coffee:293`) | universal routing | `LayoutSpec.coffee`; ~140 refs in 20 src files (biggest: `dev-tools/WidgetFactory` 51, `Widget` 27, `FrameWdgt` 8, `HandleWdgt` 6) |
| M2 | `layoutSpecDetails` — the ONE real spec object: `VerticalStackLayoutSpec` (`desiredWidth`/`grow`/`alignment`) + subclass `FrameContentLayoutSpec` (starting-size sentinels `THIS_ONE_I_HAVE_NOW`/`DONT_MIND`, `canSetHeightFreely`, `resizerCanOverlapContents`) | child (`Widget.coffee:294`) | vertical stacks + frame content ONLY | installed lazily by the arrange (`SimpleVerticalStackPanelWdgt._positionAndResizeChildren:233-237`, `FrameWdgt._positionAndResizeChildren:874-876`); 103 refs in 25 files; user-editable at runtime (spec's own `vertStackMenu`, `AlignButtonWdgt`) |
| M3 | six loose fields `minWidth/desiredWidth/maxWidth` + height twins | child — **stamped on EVERY instance** by `Widget`'s constructor (`Widget.coffee:390`: `setMinAndMaxBoundsAndSpreadability (30,30),(30,30)` → 30/30/330 both axes; the class-level defaults at `:4691-4697` are shadowed) | the horizontal stack's division box | consumed ONLY via `get(Recursive)(Min\|Desired\|Max)Dim` (`:4873-4923`) → the 3-regime solver (`_reLayout:5039-5120`) + the divider's closed-form solve; height halves consumed nowhere (comment `:4885-4890`) |
| M4 | `layoutSpec_cornerInternal_{proportionOfParent,fixedSize,inset}` | child, per-instance | handles + corner badges | set by `HandleWdgt:49-51,109`, `UpperRightTriangle*`, `ModifiedTextTriangleAnnotationWdgt`; read by the corner pass `Widget._reLayout:4999-5024` — incl. the boot-order hack `:5010-5013` (`inset` can't default at class level because `new Point` there would need the dep scanner to see it) |
| M5 | `positionFractionalInHoldingPanel` / `extentFractionalInHoldingPanel` | child | DICTATING fractional placement | `StretchablePanelWdgt._reLayout:52-67`; ALSO the world's own resize re-place (`WorldWdgt:1950`, recorded at `Widget._addNoSettle:3374-3375`) |
| M6 | container ctor flags (`padding`, `constrainContentWidth`, `tight`, `dockSide`, `laysIconsHorizontallyInGrid`) | parent | ~5 containers | fine as-is — container hooks are the parent's legitimate half |
| M7 | ~29 fully hand-coded per-class `_reLayout` overrides | code | bespoke chrome (Inspector worst) | legitimately bespoke; NOT a migration target |

**Dispatch today:** base `Widget._reLayout` (`:4968-5126`) is an if/else on the child's enum: corner pass /
horizontal 3-regime division (with the `addOrRemoveAdders()` scaffold hook at `:5028`) / free-floating by
omission; `_reLayoutCornerInternalChildren` tail. The vertical engine lives separately in
`SimpleVerticalStackPanelWdgt` with clean container hooks (`availableWidthForContents`, `interElementGap`,
`_childWidthInStack`/`_childLeftInStack`/`_childMeasuredExtentInStack`) shared by the three walkers
(arrange + two pure measures). `FrameWdgt` extends it for content negotiation (the §9.7-Q owner-decided
first-placement rule at `:884-903`).

**The enum's own file admits the mess:** `LayoutSpec.coffee:12-15` (FREEFLOATING conflates two meanings) and
`:42-46` (the four `SPREADABILITY_*` scalars "should go in a separate constants class" — they are not enum
members, they are sugar consumed only by `setMinAndMaxBoundsAndSpreadability:4794`, which computes
`max = desired + spreadability·desired/100` and stores NO spreadability field). `Widget.coffee:4986-4988`:
"bad kludge here … we'll probably have split Widgets for the new layouts mechanism".

**Layout-editing chrome (the scaffold family), `LayoutChromeWdgt` base:**
- `StackElementsSizeAdjustingWdgt` (src root = `core` part) — THE divider. Sibling widget between two
  horizontal cells; drags via a **closed-form absolute solve** (`delta = (T − parent.left() − A)·M/E − B`)
  that reads only min/desired/max FIELDS (never laid-out pixels — stale-`@left()` trap documented in the
  method comment `:44-58`), trades `maxWidth` +δ/−δ conserving the sums; clamped to the feasible interval;
  applies via `_setMaxDimDeferredSettle`. Horizontal-only (`col-resize`, `.x` reads). Auto-inserted by the
  halo (`Widget._showResizeAndMoveHandlesAndLayoutAdjustersNoSettle`, ~`:3897`).
- `LayoutElementAdderOrDropletWdgt` + `LayoutSpacerWdgt` (`src/dev-tools` = `dev-tools` part, **absent from
  production**) — the `+` drop-slot placeholders auto-maintained between stack cells by
  `addOrRemoveAdders`/`_insertAddersSuchThat` (`Widget.coffee:5149-5211`, each site guarded
  `return unless LayoutElementAdderOrDropletWdgt?`), and the spring. The droplet's `mouseClickLeft`
  (`:85-100`) **manufactures a container around itself** when free-floating — the "drop a seed, a layout
  grows" gesture. Drop → `_reactToChildDropped` inserts the payload as its own sibling and self-destructs.
  Reachable today only from `demos/DemoMenus:706-707` ("show adders"/"remove adders").
- Insertion-by-drop-point exists WITHOUT scaffolding on: `SimpleVerticalStackPanelWdgt._addNoSettle:42-57`
  (index from drop Y) and `ToolPanelWdgt` via `PanelWdgt._findDropSlot` (right-half rule) — no visual slot
  affordance in either.

**Serialization:** `layoutSpec` (int) and `layoutSpecDetails` (object, with `element`/`stack` widget
back-refs) both serialize today — neither is in `Widget.@serializationTransients` (`Widget.coffee:35-72`);
the serializer walks non-widget in-structure objects generically
(`docs/architecture/serialization-duplication-reference.md` §4). New spec classes inherit this for free.

**Docs/backlog hooks this arc touches:** `docs/BACKLOG.md` "§5.C follow-ons: `right`/`bottom` dock arranges"
(frame dock — explicit NON-goal here, see §5 P5) and the banked arc-4 item "move the four
adder-touching `Widget` members out of core onto dev-tools" — **superseded in the opposite direction** by P4
(the scaffold becomes product; the members stay, the guards die). `macros/MACRO-PATTERNS.md` documents the
h-stack test recipe against the OLD API (`LayoutSpec.ATTACHEDAS_…`, `setMinAndMaxBoundsAndSpreadability`) —
P1d must update it and sweep the tests repo.

---

## §2 Why it is shaped this way

Morphic ancestry: free-floating is the absence of layout; any widget may be a container; children carry
their own attachment (the design intent comment at `Widget.coffee:4658-4688` says exactly this, including
"special Adjusting Widgets … go and programmatically modify the layout spec properties of the content" —
i.e. the divider doctrine was the intent all along). The horizontal engine was written early INTO base
`Widget` with loose fields; the vertical engine came later as a class with a real spec object; frame content
subclassed that; corners predate both. Each is internally sound — the June–July campaigns cleaned the
ENGINE (tiers, purity, up-edge, formula) but deliberately deferred the configuration story:
`sizing-model-unification-plan` U4/D1 closed "storage stays split by design (widget fields h-side, spec
object v-side) … ownership (per-widget knob vs per-placement state), and no reader spans the two"
(assessment §2.5 close). That ruling was "not warranted", not "falsified" — and the warrant has changed:
the owner now wants the spec family AS a uniform product surface, and the missing capability (vertical
division) forces the h-side law to become reusable anyway.

**How this plan honours the §2.5 ownership point instead of steamrolling it:** the family unifies the
*container* (every constraint is an object on the child, one base class, one dispatch), while each spec
class keeps its own *lifecycle*: the division box stays a per-widget KNOB (created eagerly by its setters,
NEVER re-armed on re-parent — a cell dragged out of a stack and back keeps its divider-edited `max`), the
content-stack spec stays per-placement STATE (captured at placement, re-armed on content remount —
`FrameWdgt._addNoSettle:583` `isSameContentRemount` exception included). Same shape, honest semantics.

---

## §3 The distilled argument

1. **The enum is a type test in disguise.** Every `@layoutSpec == LayoutSpec.ATTACHEDAS_*` comparison is a
   hand-rolled dispatch on a closed set. Replacing it with spec-object capability predicates is the same
   move the type-test-elimination campaign made everywhere else, and it strictly REDUCES the stink-ratchet
   count (two `instanceof` spec checks die: `Widget.coffee:336`, `FrameWdgt.coffee:874`).
2. **Three of the seven mechanisms are the same mechanism wearing different clothes** (M2 spec object, M3
   loose fields, M4 ad-hoc fields). One family, three classes, everything gains the spec object's proven
   perks for free: serialization, per-child runtime menus, duck-typed dispatch, no boot-order field hacks.
3. **Axis parameterization is the cheapest possible route to border/split layouts.** The division law, the
   divider's closed-form solve, and the adder scaffold are all already written and battle-tested — they are
   just hard-wired to `.x`/`.width()`. No new engine, no constraint solver, no Swing import: N/W-C-E/S =
   a vertical division stack containing a horizontal division stack, with dividers at the seams. Bespoke
   5-region engines and runtime constraint solvers are exactly what the proper-layouts doctrine forbids
   (assessment §4 do-not-revisit: no mutation-driven notification; the up-edge is the design).
4. **The scaffold is the direct-manipulation payoff and it is 90% built** — droplets, seed-a-container,
   drop-index computation, halo-inserted dividers all exist; they are just axis-limited, invisible in
   production, and reachable only from a dev menu.

---

## §4 Target architecture

### 4.1 The spec family (one class per file, all in `src/` root, `core` part)

```
LayoutSpec                        # ABSTRACT BASE (file re-purposed: constants deleted, family base born)
├── DivisionStackLayoutSpec       # per-child {minMain, desiredMain, maxMain (+ cross pair)}, axis-aware
│                                 # = today's M3 fields + SPREADABILITY sugar, per-widget-knob lifecycle
├── VerticalStackLayoutSpec       # KEPT, body verbatim (desiredWidth/grow/alignment, D2-def capture,
│   │                             # re-derives at placement) — re-based onto LayoutSpec
│   └── FrameContentLayoutSpec    # KEPT, body verbatim (sentinels, canSetHeightFreely, remount re-arm)
└── CornerInternalLayoutSpec      # {anchor: 'topLeft'|'topRight'|'bottomRight'|'rightMiddle'|'bottomMiddle',
                                  #  proportionOfParent, fixedSize, inset (Point, runtime-built —
                                  #  kills the Widget.coffee:5010 boot hack)}
```

- **`Widget::layoutSpec: nil`, and `nil MEANS free-floating.`** No `FreeFloatingSpec` singleton: FF carries
  zero per-child state (the desired-geometry channel below owns what looks like state), "free-floating is
  the absence of layout" is the documented doctrine, and a class-level singleton default would trip the
  boot dependency scanner (only declaration-level `new X` edges are seen — the ShadowInfo boot-hang case,
  `docs/architecture/immutable-value-classes.md` §3). `isFreeFloating: -> !@layoutSpec?`.
- `layoutSpecDetails` is DELETED as a name: the object moves into `@layoutSpec` itself. The enum int and
  every `ATTACHEDAS_*` constant are DELETED.
- Capability predicates on the spec classes (duck-typed `?()`, per the rulebook's "prefer a capability
  query"): `isDivisionElement()` + `axis()` (`'x'`|`'y'`), `isContentStackElement()`,
  `isFrameContentSpec()` (exists), `isCornerInternal()`. Base `LayoutSpec` hoists the shared
  settle-on-`@element` helper pattern (the thin-wrap-exempt `@element._settleLayoutsAfter` idiom +
  `_invalidateLayout` climb) and the `addWidgetSpecificMenuEntries` hook.
- `add(aWdgt, position, layoutSpec)` / `defaultLayoutSpecWhenAddedTo(destination)` keep their signatures but
  the `layoutSpec` value is now a spec object or nil (`HandleWdgt.defaultLayoutSpecWhenAddedTo:58-70`
  returns a fresh `CornerInternalLayoutSpec` per corner type). `_setLayoutSpec` keeps its
  handle-visibility hook.
- **The desired-geometry channel stays on the Widget and is NOT part of the family:** `desiredExtent`,
  `desiredPosition`, `positionFractionalInHoldingPanel`, `extentFractionalInHoldingPanel`,
  `userMovedThisFromComputedPosition`, `minimumExtent`. These are imposed/deferred geometry bookkeeping (the
  DICTATING side + the settle engine's intent channel), consumed by StretchablePanel and the world resize —
  orthogonal to the attachment contract. Classifying them out is a decision, recorded here; M5 is thereby
  resolved-by-classification, not migrated.

### 4.2 The engines

- **`StackLayoutEngine`** (new class, `src/` root, class-side methods only, no instances): the division
  solver (3 regimes + shared placement loop + overflow guard, moved VERBATIM from
  `Widget._reLayout:5026-5120`) and the recursive box walker (from `_getRecursiveStackDim:4895-4923`),
  **axis-parameterized** via a dim-accessor table (main/cross: `width()/height()`, `left()/top()`,
  `Point.x/y`, main-sum/cross-max). Runtime calls only — no declaration-level cross-class references (dep
  scanner sees none; all classes are loaded before any world runs).
- Base `Widget._reLayout` becomes: apply own bounds (unchanged head incl. the FIT_BOX_TO_TEXT branch — see
  §5 P2a note) → corner pass via `CornerInternalLayoutSpec` children → if division children exist,
  `StackLayoutEngine.arrange(@, axis)` (adders hook stays inside the engine) → mark fixed → corner tail.
  Mixed-axis division children under one parent = a loud `console.error` + first-axis-wins (gate-visible,
  never a throw mid-pass).
- The vertical CONTENT engine stays where it is (`SimpleVerticalStackPanelWdgt` + its container hooks +
  three walkers + `FrameWdgt`'s negotiation) — it is already clean, and its D2-def/§9.7-Q semantics are
  owner-decided case law. It changes only its spec SHELL (reads `@layoutSpec` instead of
  `@layoutSpecDetails`, predicate instead of enum compare).
- **The divider becomes axis-aware**: `StackElementsSizeAdjustingWdgt` gains `@axis` (from the sibling
  specs it sits between), reads `getDesiredDim()/getMaxDim()` through the same accessor table, sets
  `col-resize`/`row-resize` accordingly. The closed form is axis-symmetric by inspection (it reads fields
  and `parent.left()`→`parent.top()`; P0-S2 confirms no other x-assumption). The halo auto-insertion scans
  siblings by predicate+axis.

### 4.3 Scaffolds as product

Adders/droplets/spacer move to `src/` root (`core` part — pending P0-S3 byte measurement + owner OK), the
`return unless LayoutElementAdderOrDropletWdgt?` guards die, `addOrRemoveAdders` generalizes to both axes
and to the content stack (droplets between vertical elements too), the droplet seed becomes axis-choosing,
and "edit layout" (show/hide adders) surfaces in the product context menu of stack containers (owner-gated
wording). Border layout ships as a TEMPLATE: a factory assembling
`vertical-division [N, horizontal-division [W, C, E], S]` with dividers at the seams and droplets in the
empty regions — pure composition, no new engine.

---

## §5 Phases

Every phase: work from `Fizzygum/src`, build+test via `fg` (never hand-chained), background long runs.
"Byte-identical" = full dpr1 suite green with ZERO reference recaptures needed.

### P0 — Spikes & measurements (no product code; ~half a day)

- **S0 census re-verify:** run the §1 commands; reconcile counts with this plan.
- **S1 serialization baseline + probe:** `fg build`, run both serialization rigs (they ride
  `fg gauntlet`'s wave B; standalone: `Fizzygum-tests/scripts/serialization-roundtrip-headless.js` then
  `serialization-file-roundtrip-headless.js`) on HEAD → green baseline. Write a throwaway probe under
  `Fizzygum-tests/.scratch/` (NOT the session scratchpad — module resolution) asserting a
  `VerticalStackLayoutSpec` instance round-trips through world-snapshot save/load with `element`/`stack`
  re-bound. Expected: already true; the probe is the evidence the new classes inherit it.
- **S2 axis math check (paper + probe):** walk `StackLayoutEngine`'s three regimes and the divider solve
  substituting the accessor table; list every `.x`/`.width()`/`left()` read in
  `Widget._reLayout:5026-5120` + `StackElementsSizeAdjustingWdgt.nonFloatDragging` and its table entry.
  Deliverable: the table, embedded in P2's commit message.
- **S3 chrome promotion byte cost:** measure `LayoutSpacerWdgt` + `LayoutElementAdderOrDropletWdgt` source
  bytes; build `--profile homepage` before/after a trial move to `src/` root; report the
  `js/pre-compiled.js` delta to the owner with the recommendation (expected: ~2-4 KB, recommend core).
  ⚠ probe production by building the profile directly; `fg homepage` restores the dev build afterwards
  (memory: `budgeted-source-compile-scheduler-arc`).
- **S4 tests-repo impact census:**
  `rg -n "LayoutSpec\.|setMinAndMaxBoundsAndSpreadability|layoutSpecDetails" /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests --no-heading`
  — size the P1d mechanical sweep (macros build h-stacks via the old API; MACRO-PATTERNS.md documents it).

**Gate:** S1 rigs green; S2 table complete; S3 number in hand; owner pinged on the S3 decision (async, does
not block P1–P2).

### P1 — The spec family + storage migration + enum deletion (pure refactor; BYTE-IDENTICAL throughout)

Sub-batches, each `fg build` + `fg presuite` gated:

- **P1a `CornerInternalLayoutSpec`.** New class. Carriers (`HandleWdgt`, `UpperRightTriangleWdgt`,
  `UpperRightTriangleIconicButtonWdgt`, `ModifiedTextTriangleAnnotationWdgt`) construct it where they set
  the three fields today; it lands in `layoutSpecDetails` (interim home until P1d); the corner pass
  (`Widget._reLayout:4999-5024` + `_reLayoutCornerInternalChildren`) reads the spec; the five enum corner
  constants become the spec's `anchor` string (enum tag kept in lockstep during this batch); the
  `:5010-5013` inset boot hack dies (inset always constructed at runtime). The three
  `layoutSpec_cornerInternal_*` field names are deleted repo-wide.
- **P1b `DivisionStackLayoutSpec`.** New class carrying the six box values
  (`minMain/desiredMain/maxMain` + cross — see naming note below); created eagerly by
  `setMinAndMaxBoundsAndSpreadability` / `setMaxDim` family (public names KEPT; `SPREADABILITY_*`
  constants move onto this class) and lazily at first division-attach with the ctor-equivalent defaults
  (30/30/330 — preserving today's every-instance stamp semantics); `Widget`'s constructor stamp (`:390`),
  the six Widget fields (`:4691-4697`), and their class-level ghosts are DELETED.
  `get(Recursive)(Min|Desired|Max)Dim` become spec-backed (signatures kept — the divider and solver read
  through them). Lifecycle: per-widget knob, NEVER re-armed on re-parent (dragging a divider-tuned cell out
  and back preserves its box). **Naming note:** keep the accessors returning `Point`s (x=width, y=height)
  exactly as today — do NOT rename to main/cross in this phase; the axis reinterpretation happens in P2
  where the accessor table exists to make it honest.
  ⚠ Inspector member-list tests churn when Widget loses fields — benign-recapture (owner-sanctioned).
- **P1c re-base the vertical side.** `VerticalStackLayoutSpec` + `FrameContentLayoutSpec` get
  `extends LayoutSpec`… — but LayoutSpec is still the constants bag until P1d, so this batch actually
  lands the new ABSTRACT BASE under the interim name `LayoutSpecBase`, all four family classes extending
  it, hoisting the shared settle-on-element idiom + menu hook. Bodies of capture/derivation/setters remain
  VERBATIM (D2-def: grow derived at capture wide⇒1/narrow⇒0, explicit grow wins, over-wide clamp forces 1;
  `FrameContentLayoutSpec.DONT_MIND` fill; remount re-arm with `isSameContentRemount`; §9.7-Q window rule
  untouched in `FrameWdgt`).
- **P1d the flip (the big sweep).** Delete every `ATTACHEDAS_*` constant and comparison (~140 refs, 20
  files — `WidgetFactory` 51, `Widget` 27, `FrameWdgt` 8, `HandleWdgt` 6, rest in §1's census): routing
  becomes predicates on the spec object; `layoutSpecDetails` → `layoutSpec` (103 refs);
  `isFreeFloating: -> !@layoutSpec?`; `add`/`_addNoSettle`/`addAsSibling*`/`defaultLayoutSpecWhenAddedTo`
  carry spec objects or nil; `_setLayoutSpec` reshaped; the interim `LayoutSpecBase` is renamed
  `LayoutSpec` into the re-purposed `LayoutSpec.coffee` (both file-level TODOs thereby resolved by
  deletion); `_getRecursiveStackDim`/`countOfChildrenInHorizontalStackLayout`/adder scans/divider sibling
  scans go predicate-based. Sweep `src/macros/MACRO-PATTERNS.md` + the tests repo (S4 list) — macro
  fixtures build stacks via the new API. ⚠ Do the sweep with the Edit tool, never `perl -pi` (memory:
  de-indentation trap).

**Phase gate:** `fg gauntlet` (all legs incl. webkit, revisits, census, serialization rigs, parts) — suite
byte-identical except the known inspector-member recaptures; `fg homepage` green (production boots, snapshot
round-trip — the only gate that catches production-tree field references).

### P2 — Engine extraction + axis parameterization (pure refactor; BYTE-IDENTICAL)

- **P2a extract `StackLayoutEngine`.** Move the division solver + placement loop + recursive walker out of
  `Widget` verbatim; `Widget._reLayout` becomes the thin dispatch of §4.2. The `addOrRemoveAdders` hook
  moves with the engine. NOTE the FIT_BOX_TO_TEXT branch (`:4986-4997`) stays in `Widget._reLayout`'s
  self-sizing head (it is per-widget self-fit, not stack logic; the "split Widgets" TODO comment dies, the
  branch is now just the text self-fit step — reword the comment honestly).
- **P2b parameterize.** Introduce the axis accessor table (S2 deliverable); solver + walker + placement
  loop read through it; horizontal callers pass `'x'`. PROVE byte-identity (the whole point of doing this
  before any new capability exists).
- **P2c divider axis-awareness.** `@axis` derived from flanking specs; solve + clamp + cursor through the
  table; halo insertion predicate+axis-based. Still only horizontal instances exist in the tree ⇒
  byte-identical.

**Phase gate:** `fg gauntlet` byte-identical; `fg census`/`fg revisits` at their zero/empty baselines
(idempotence and no new up-edges are exactly what an engine extraction can silently break).

### P3 — Vertical division + vertical divider (NEW capability; new tests; recaptures owner-pre-authorized)

- Enable `axis: 'y'` division: children carrying y-axis `DivisionStackLayoutSpec`s divide the parent's
  HEIGHT by the same 3-regime law (the previously-inert height halves of the box become the y-axis main
  dims — they were "kept correct anyway" per `Widget.coffee:4885-4890`, so the data is already sound).
  Cross-axis behaviour mirrors today's horizontal: children stretched to full container width.
- Vertical divider instances between y-division siblings (`row-resize`), halo auto-insertion on the y axis.
- **New macro tests** (authored via `/author-macro-test` conventions): vertical divider follows pointer
  exactly (value-assert vs the LIVE hand — mirror `macroStackDividerFollowsPointerExactly`, incl. the
  collapsed-neighbour clamp case); a v-division split pane reproportions; nested division (border skeleton)
  arranges idempotently.
- Rulebook compliance walk (layout.md §8 items 1–5) written into the phase notes: pure measures for
  division containers on the y axis (`preferredExtentForWidth` of a y-division parent = its granted extent
  — division containers are granted-size, not content-hug; confirm against census).

**Phase gate:** `fg gauntlet` green (existing tests byte-identical — vertical division is opt-in, nothing
in the existing tree carries y-specs); new tests captured dpr1+dpr2 via `fg recapture`; `fg census` zero
movers including the new fixtures.

### P4 — Scaffolds as product (NEW capability)

- Move `LayoutSpacerWdgt` + `LayoutElementAdderOrDropletWdgt` to `src/` root per the S3/owner decision;
  delete every `return unless LayoutElementAdderOrDropletWdgt?` guard; update `parts.json` (dev-tools
  keeps only what remains); run `fg parts` gate + `fg homepage`. Close the superseded BACKLOG banked item
  (arc-4 §5.4 "move the four members out of core") with an owner-decided annotation pointing here.
- Axis-aware adders: droplets between y-division siblings; droplet seed gesture chooses axis (owner-gated
  UX: default click = horizontal as today; the vertical entry via the context menu or a modifier — decide
  with the owner at this phase's head).
- Content-stack scaffolding: `showAdders` on a `SimpleVerticalStackPanelWdgt` inserts droplets between
  elements (the drop must route through the stack's existing index-from-drop-Y add, replacing the silent
  index computation with a visible slot when editing).
- Product entry: "edit layout / done editing" context-menu entries on stack containers (wording
  owner-gated; menu-label changes are pixel-asserted — expect menu-test recaptures, pre-authorized).
- New macro tests: drop-into-droplet inserts at the slot (both axes); seed-grows-a-container; adders
  appear/disappear via the menu.

**Phase gate:** `fg gauntlet` + `fg homepage` (chrome now ships — the production snapshot round-trip must
still pass); new tests captured.

### P5 — Border-layout template + polish (NEW capability)

- A factory (home: `WidgetFactory` for dev, plus an owner-gated product creation entry) assembling the
  border skeleton: outer y-division stack [N cell (desired=fixed, grow via max), center h-division
  [W, C, E], S cell], dividers at each seam, droplets in empty regions, center cell max-heavy so it takes
  the spare space. It is JUST composition — if any step needs a new engine feature, stop and re-frame
  (that is the design's falsification bell).
- OPTIONAL (owner call at phase head): cross-axis alignment for division cells
  (top/middle/bottom | left/center/right instead of hardwired stretch) — default stays stretch ⇒
  byte-identical for existing content; resolves the `VERTICALALIGNMENTS_UNDEFINED` epitaph properly.
- **Explicit NON-goals, recorded:** absorbing `FrameWdgt`'s dock slot / title bar / resizer into composed
  scaffolds (the frame's arrange is owner-sanctioned bespoke chrome; the BACKLOG right/bottom-dock line
  stays open and independent — though P1 may in passing fix the `FrameWdgt:1004-1008` resizer TODO by
  giving the resizer a `CornerInternalLayoutSpec`, ONLY if it proves byte-identical trivially, else skip);
  a horizontal CONTENT stack (no consumer — YAGNI); grid/table specs (ToolPanel/IconicDesktop stay
  bespoke).

**Phase gate:** `fg gauntlet`; new template test(s) captured; a manual owner feel-check of the border
scaffold in the running world (screenshot or live session).

### P6 — Docs, gates, close

- `docs/architecture/layout.md`: §4 gains the spec-family table + nil-means-FF + lifecycle-per-class;
  §2.4/§8 rulebook items updated (a new layout = a new spec class + engine reuse); §5/§7 untouched.
- `docs/architecture/layering-naming-convention.md` (spec setters' settle-on-element exemption is now
  base-class doctrine), `lint-and-static-checks.md` if any lint predicate was touched,
  `serialization-duplication-reference.md` (spec family note), `MACRO-PATTERNS.md` (already swept in P1d —
  verify), `BACKLOG.md` reconciliation (two lines named in §1), assessment addendum block (a
  "⇄ CONFIGURATION UNIFIED (2026-…)" block under §2.5, same style as the existing campaign-closed block).
- Stink ratchet: confirm `instanceof` count went DOWN; dead-code gate; `fg cc` glance at the new engine.
- `/close-arc`: final full gauntlet + homepage, memory file, this plan → `docs/archive/` + INDEX line,
  ONE end-of-arc review, commit messages presented for owner approval.

---

## §6 Central risks

- **The P1d sweep is wide (≈250 touchpoints).** Mitigation: it is the LAST sub-batch of P1, everything
  before it lands byte-identical with the enum still in lockstep; the sweep itself is mechanical
  (predicate-for-comparison) and gated by the full gauntlet + homepage. The syntax gate catches parse slips
  at build time.
- **Engine extraction silently changing settle behaviour** (idempotence, up-edges, adder timing inside the
  arrange). Instruments: `fg census` and `fg revisits` are exactly the detectors, both at hard zero/empty
  baselines; run them per phase, not just at close.
- **Spec-object lifecycle vs duplication/serialization:** the Duplicator deep-copies specs per widget and
  re-maps `element`/`stack` refs (proven for M2 today; S1 re-proves). The division spec's eager creation in
  setters must not resurrect the construction-invalidate that `setMinAndMaxBoundsAndSpreadability:4804-4815`
  deliberately skips for orphans — keep the orphan-skip in the new setter path verbatim.
- **Boot order:** no class-level default may construct or reference another class
  (`layoutSpec: nil` only; specs built at runtime). The ShadowInfo boot-hang is the case law.
- **The divider math under axis swap:** the trap is documented in the widget itself (absolute-not-
  incremental; fields-not-pixels). The y twin must copy the SHAPE, not re-derive it; the new value-assert
  macro test is the guard. A fuzz/`--dpr=2` pass is NOT needed for the math (it reads fields), but the new
  tests ride the normal dpr2 gauntlet leg.
- **Do not let P1 drift into behaviour change.** If a byte diff appears and the "fix" is tempting as a
  recapture — stop: refactor phases recapture NOTHING except the named inspector-member churn.

---

## §7 Rejected alternatives / do-not-re-attempt

- **Parent-side constraint maps (Swing `LayoutManager` + constraints-at-add):** against the verified
  child-side idiom (6/7 mechanisms), worse for serialization (constraints detached from the serialized
  child), and no consumer needs it.
- **A runtime constraint solver / mutate-and-converge engine:** forbidden by the proper-layouts doctrine and
  the assessment §4 falsified list (mutation-driven container notification, in-arrange fixpoints — all
  falsified in the pre-deletion endgame; the settle-time up-edge IS the design).
- **Keeping the enum alongside the objects ("compat"):** the archetypal bury-it-deeper; the owner's
  standing filter (memory `proper-layouts-elimination-goal`) rejects steps whose payoff is cohabitation.
- **A `FreeFloatingSpec` canonical singleton:** boot-order hazard + carries zero state; `nil` is the honest
  encoding (revisit only if FF ever grows real per-child spec state).
- **A bespoke 5-region border engine:** duplicates the division law; composition delivers it with dividers
  and drop-scaffolds inherited for free.
- **Renaming `VerticalStackLayoutSpec`→`ContentStackLayoutSpec` / building a horizontal content stack:**
  premature abstraction, no consumer.
- **Re-opening D2-def capture semantics, the §9.7-Q window rule, hug-suppression, or shrink-to-fit:** all
  owner-decided / multiply-falsified (`sizing-model-unification-plan` §6/§9; assessment §4). The family
  RE-HOUSES these semantics; it does not re-litigate them.

---

## §8 Owner decision points (collect asynchronously; only (a) blocks its phase)

a. **P4 chrome home:** core (recommended, pending S3 bytes) vs the lazy `authoring` part (would need
   `ensureLoaded` seams at the menu entries — a guard would swallow clicks).
b. **P4 scaffold UX:** context-menu wording/placement for "edit layout"; droplet seed axis gesture.
c. **P5 border template delivery:** dev-menu only vs product creation entry; and whether the optional
   cross-axis alignment lands in this arc.
d. **P1-adjacent cleanup:** take the FrameWdgt resizer corner-spec TODO now (only if trivially
   byte-identical) or leave it banked.

---

## §9 Verification protocol (the exact commands)

Per sub-batch: `/Users/davidedellacasa/code/Fizzygum-all/fg build` then
`/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (background, log + verdict file, wait for the task
notification). Per phase close: `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet` (parallel; covers
dpr1/dpr2/webkit suites, apps, paint audit, tiernaming/settle/capstone/revisits gates, refs, census,
serialization rigs, parts). After any parts/profile change additionally
`/Users/davidedellacasa/code/Fizzygum-all/fg homepage`. Recaptures (P3–P5 only):
`fg recapture <names…>` then the run's own COMPLETE verdict, or `fg recapture --auto`. Single-test debug:
`fg test <name>`. State-leak repro if a new test misbehaves only in-suite: `fg run-sequence <names…>`.

---

## §10 References

- `docs/architecture/layout.md` — the contract this plan extends (§4 sizing, §7 zero-invariants, §8 rulebook).
- `docs/archive/layout-system-architecture-assessment.md` — §2.5 (the storage-split ruling this plan
  supersedes-with-new-warrant), §4 "Do not revisit".
- `docs/archive/sizing-model-unification-plan.md` — D2-def capture semantics, §9.7-Q, U-series records.
- `src/StackElementsSizeAdjustingWdgt.coffee` — the divider doctrine + closed form (the comment block IS
  the documentation).
- `docs/architecture/serialization-duplication-reference.md` §4/§5 — reference policy + transients.
- `docs/architecture/build-and-packaging.md` + `buildSystem/parts.json` — parts, guards vs laziness.
- `docs/specs/drag-embed-interaction-spec.md` — drop candidate/dwell rules the scaffolds compose with.
- Memory notes: `proper-layouts-elimination-goal`, `divider-drag-exact-tracking`,
  `sizing-model-unification-plan`, `no-serialization-compat-obligations`, `ask-before-commit-push`,
  `owner-workflow-long-arcs`, `stop-iterating-fix-shapes-after-two-falsifications`.

---

## §11 Execution ledger (append per phase; empty at authoring)

*(status boxes per phase: date, commits, gate results, deviations, falsifications)*

### P0 — DONE 2026-08-04 (same session as authoring)
- Baseline: Fizzygum `62a11244` / tests `d900dab9f`, full gauntlet PASS 15:10 (all 14 legs — this banks
  the S1 rig baseline), 271 SystemTests.
- **S3 measured: promoting adder+spacer to core costs 5,436 bytes on `js/pre-compiled.js`
  (675,887 → 681,323, +0.8%); both trial homepage builds exited 0.** Recommendation: core.
- S4: 76 old-API lines across ~37 test files + 2 audit preludes (biggest: the 6 layout/divider macro
  tests) — the P1d tests sweep is mechanical.
- S1 note (honest gap): the roundtrip rig was not individually audited for stack-spec scenarios; the
  operative instruments for spec serialization are the suite's duplication tests + `fg homepage`'s
  snapshot round-trip + the rigs in the gauntlet, all green at baseline and required green at every gate.
- S2: axis accessor table — main/cross for 'x'→'y': `width()↔height()`, `left()↔top()`,
  `right()↔bottom()`, `Point.x↔.y`; walker sums MAIN, maxes CROSS (axis = the axis of MY division
  children); placement loop rounds MAIN boundaries, cross = granted bounds; divider: grip/pointer
  `.x↔.y`, `parent.left()↔parent.top()`, cursor `col-resize↔row-resize`. No other x-assumption found
  in the solver or the divider solve.

### P1 — in progress 2026-08-04
- **P1a landed:** `CornerInternalLayoutSpec` (geometry only; anchor stays enum-routed until P1d);
  carriers converted (HandleWdgt ctor + `_reactToBeingAdded` inset re-derive, UpperRightTriangleWdgt,
  ModifiedTextTriangleAnnotationWdgt, UpperRightTriangleIconicButtonWdgt's pencil icon); corner pass
  reads the spec; the `Widget.coffee` nil-inset boot hack DELETED (the spec ctor builds inset at
  runtime). Zero `layoutSpec_cornerInternal` field refs remain. ⚠ dead-method gate: capability
  predicates may only land WITH their callers — `isCornerInternal` deferred to P1d (first failure mode
  of the arc, benign).
- **P1a gate: GREEN 15:31 — 271/271, zero recaptures (byte-identical).** Two build-gate trips en
  route, both fixed properly (dead-method: a capability predicate may only land WITH its callers —
  `isCornerInternal` deferred to P1d; comment-narration ratchet: reworded).
- **P1b landed:** `DivisionStackLayoutSpec` (box values on the spec; shared lazy `@defaults()`
  instance backing widgets without a private box — zero allocation for plain widgets); `Widget`'s
  six box fields + the every-instance constructor stamp DELETED; `_ensureDivisionBox()` /
  `_divisionBoxOrDefaults()`; `setMinAndMaxBoundsAndSpreadability` / `_setMaxDimNoSettle` write the
  box; the dim readers + recursive walkers read it. Call-separation gate trip: the accessor must be
  `_`-tier until external callers exist (P1d may promote via public-api-allowlist — macros/demos
  are end-user scripting). SPREADABILITY constants stay on `LayoutSpec` until P1d (tests reference
  them at runtime — S4). **Gate 15:42: 270/271 — the single diff is macroDuplicatedInspector…
  (member-list window shift: −6 fields/+2 methods on Widget's prototype), verified by eyeball via
  `fg diffpage`; carried known-red until ONE recapture after P1d.**
- **P1d design refinement (decided during P1a, supersedes §4.1's letter, keeps its spirit):** specs
  must SURVIVE DETACHMENT — today a stack element grabbed out (tag → FF) keeps its
  `layoutSpecDetails`, so explicit grow/alignment edits survive grab-out-and-drop-back (the
  `initialiseDefaultVerticalStackLayoutSpec` keep-guard), and the division box fields persist across
  re-parenting. Therefore the flip is: `@layoutSpec` = the ACTIVE attachment spec or nil (= FF), plus
  per-family stashes the widget retains: `_divisionBox` (the division knob; same object is active when
  division-attached) and the content-stack spec stashed on detach; a corner carrier (HandleWdgt) holds
  its own spec field. The two `instanceof` keep-guards convert to capability queries (ratchet −2).
- **P1c landed (gate 15:53: only the known-red inspector test):** family base as interim
  `LayoutSpecBase`, all four spec classes re-based (ctors gained `super()` — CS2 derived-class rule).
- **P1d landed — gate 16:51: 270/271 with the ONLY diff being the SAME known-red inspector test
  (recaptured next, gated).** Three build-gate trips en route, each a real find: [S]/[U] made
  `divisionBox()` earn its public place and sent `addOrRemoveAdders` to `_`-tier — whereupon rule
  [G] exposed a PRE-EXISTING violation its public name had been hiding (the arrange destroying
  stale adders via self-settling `fullDestroy()`; now the `_fullDestroyNoSettle` core). [U]-query
  baseline tightened 132→131. Refinements settled during execution, recorded here as the durable
  design:
  - Storage: `@layoutSpec` = ACTIVE spec object or nil (nil MEANS free-floating; `isFreeFloating()`
    is a nil check); `@_stackElementSpec` = the persistent VSLS/FCLS (written ONLY by the two
    `initialiseDefault*` inits — the VSLS init keeps via `isContentStackCapable?()`, the FCLS init
    replaces); `@_divisionBox` = the division knob; `HandleWdgt.cornerSpec` / triangle `@cornerSpec`.
  - The `layoutSpecDetails` NAME is gone (≈100 sites → `_stackElementSpec` for persistent data reads,
    `@layoutSpec` where the ACTIVE spec is meant: the corner pass, the menu gate, AlignButtonWdgt).
  - Roles WITHOUT a type test: `attachedAsFrameContent` flag on the VSLS family (FCLS default true),
    flipped by the two adopters — needed because the SAME kept FCLS object can be adopted by a stack
    (`isStackElementActive` / `isFrameContentActive` read it). The FrameWdgt mount (`_addNoSettle`)
    ensures the FCLS (same keep-guard as before), sets the flag, re-arms unless
    `isSameContentRemount`, and passes the spec as the add's layoutSpec; the arrange guard becomes
    `!isFrameContentActive?()` — truth-table-matched to the old tag+instanceof pair.
  - `CornerInternalLayoutSpec` gained `anchor` as its FIRST ctor arg ('topLeft'…'bottomMiddle');
    `HandleWdgt._anchorForType()` maps the handle type once at construction.
  - **Macro rule [D] (hard ban on `_`-calls in macros) forced the public door**: `divisionBox()`
    public on Widget + `public-api-allowlist.txt` entry — macros/demos build rows via
    `holder.add w, nil, w.divisionBox()`; private internals call the `_ensureDivisionBox` core.
    Macros poke spec setters through the public `layoutSpec` field (`heart.layoutSpec.
    setAlignmentToCenter()`).
  - Tests sweep: 6 macro fixtures' adds + 4 SPREADABILITY refs + 2 spec pokes + 1 prelude; macro
    teaching comments + MACRO-PATTERNS.md recipes updated; metadata PROSE (intent/provenance) left
    as historical record (precedent: pre-U4 names live there untouched).
  - Latent bug found (NOT fixed here, banked for P4): `showAdders`/`addOrRemoveAdders`' empty-
    container branch passed its layout spec as a third POSITIONAL arg to two-arg `_addNoSettle`,
    so that first adder lands free-floating; translated faithfully (spec args dropped).
  - `LayoutSpec.coffee` is now the family's abstract base (both its old TODOs resolved by deletion);
    `SPREADABILITY_*` live on `DivisionStackLayoutSpec`.
- **P1 CLOSED 2026-08-04 17:04: recapture COMPLETE (the one inspector test, dpr1+2, gated verify
  green) → FULL GAUNTLET GREEN, all 14 legs** — dpr1/dpr2/webkit suites, apps, parts, paint,
  tiernaming/settle/capstone, refs, revisits (EMPTY baseline held), census (zero movers),
  serialization (both rigs), storage. `fg homepage` GREEN at close (production boots from the
  pre-compiled image; the whole-world snapshot round-trips with spec objects in `@layoutSpec`).
  Total churn for the whole phase: ONE benign inspector member-list recapture.

### P2 — CLOSED 2026-08-04 17:15
- `StackLayoutEngine` (class-side, src root/core): the three-regime solve + shared placement loop
  moved out of `Widget._reLayout`, AXIS-PARAMETERIZED from birth (identical arithmetic for 'x' —
  a local `mainOf` accessor closure + per-axis Rectangle composition; the FIT_BOX_TO_TEXT text
  self-fit stays in Widget's own head). Gate: presuite GREEN FIRST TRY, 271/271 byte-identical;
  full gauntlet green (revisits/census at baselines — the extraction-sensitive legs). The
  divider's axis work deliberately folded into P3 (specs gain `axis` there).

### P3 — in progress 2026-08-04
- src landed: `DivisionStackLayoutSpec.axis` ('x' default, set via the public `divisionBox('y')`);
  `Widget._divisionChildrenAxis()` REPLACES `countOfChildrenInHorizontalStackLayout` (self-only;
  mixed axes under one parent = loud console.error, first child wins); `_getRecursiveStackDim`
  axis-aware (sums the children's division axis, maxes the cross — the previously-inert height
  halves of the box are now the 'y' main dims, exactly as §5 P3 predicted); the divider
  (`StackElementsSizeAdjustingWdgt`) axis-keyed off its own spec (transposed closed form,
  maxHeight traded, `row-resize` cursor); halo insertion + adders propagate the axis.
- src-only gate: 270/271 — the one diff is the same inspector member-list churn (predicate swap
  on Widget's prototype), diffpage-verified benign again.
- **`macroStackDividerFollowsPointerExactlyVertical` (value-assert, 0 refs): PASSED FIRST RUN —
  all beats exact against the live hand, including the past-bound re-sync.** The transposed
  closed form is 0px-exact.
- **`macroVerticalDivisionBorderSkeleton` (3 screenshots): the composition claim in pixels** —
  N/W-C-E/S border by composition (y-division of [N, x-row [W|C|E], S] + dividers at the seams);
  captured dpr1, eyeballed: fixed bands hold thickness through a 320×340→420×260 resize while
  Center absorbs both axes; the upper vertical divider drag grows North live. Gated recapture
  (both tests, dpr1+2) + gauntlet at close.
- **P3 CLOSED 2026-08-04 17:44: recapture COMPLETE (dpr1+2) → FULL GAUNTLET GREEN, all 14 legs,
  suite now 273 tests** (the two new ones ride dpr1/dpr2/webkit permanently).

### P4+P5 — in progress 2026-08-04 (owner decisions collected via AskUserQuestion)
- **§8 decisions:** (a) chrome home = the LAZY `authoring` part (owner picked over the recommended
  core — zero eager bytes); (b) scaffold UX = context-menu entries; (c) border template = dev
  factory only; (d) BOTH extras in: cross-axis alignment + the resizer corner-spec TODO.
- **Chrome moved** `src/dev-tools/` → `src/authoring/` (git mv). Part-edges gate walked the seam
  properly: for an EAGER part referencing a LAZY one, `requires` is DISCOUNTED — the AWAIT is the
  protection (the dev-tools parts.json comment says exactly this). So `setupTestScreen1`'s whole
  gallery body now runs inside `world.parts.whenAllLoaded ["authoring"], =>` (the INLINE FAST PATH
  keeps it synchronous under the all-eager harness page, which the layout macros rely on — the
  first wrapper attempt as a `_`-tier body method tripped rule [A]: the body drives public
  setters, so it is public-tier and stays inline); `createNewLayoutElementAdderOrDropletWdgt`
  awaits likewise. DemoMenus needs NOTHING: `demos requires [authoring]` is an ORDERING statement,
  so when the demo menu exists the chrome is loaded.
- **Product UX:** "edit layout" / "done editing layout" on any division container's context menu
  (`addWidgetSpecificMenuEntries`, gated on `_divisionChildrenAxis()?`); `Widget.editLayout` is
  the ensureLoaded('authoring') seam (an existence guard would swallow the click); "done" reuses
  `removeAdders`. The `showAdders` empty-container latent bug FIXED: the seed adder now joins the
  division layout with the requested axis (it used to land free-floating via dead positional args).
- **Resizer corner-spec TODO (extra d2): the conversion was a pure DELETION** — the resizer was
  already corner-attached (its add passes `defaultLayoutSpecWhenAddedTo`), so FrameWdgt:1013's
  `__commitMoveTo` was a redundant re-commit of exactly what the corner pass computes (inset =
  padding via `_reactToBeingAdded`). Deleted; byte-identical across every window screenshot.
- **Cross-axis alignment (extra d1):** `DivisionStackLayoutSpec.crossAlign` —
  'stretch' (default, byte-identical) | 'start' | 'center' | 'end'; the engine places the cell at
  its recursive cross-axis DESIRED extent with a floored centring offset. Resolves what the old
  enum name (`…VERTICALALIGNMENTS_UNDEFINED`) promised and never had. New test
  `macroDivisionCrossAlignment` (2 screenshots) pins it, incl. band-growth tracking.
- **P5 border factory:** `WidgetFactory.createBorderLayoutScaffold` (core classes only — droplets
  arrive via "edit layout") + a "border layout scaffold" demo-menu entry.
- Gate history: part-edges trip → whenAllLoaded shape; [A] trip → inline body; P4 suite 272/273
  (inspector churn only — Widget gained `editLayout`); ⚠ one capture-instability scare on the
  alignment test resolved as the STALE-BUILD window (the P5 edits postdated the build the capture
  ran on; fresh build passes repeatedly) — the dpr1+dpr2+webkit gauntlet legs are the real sampler.
- The demo-menu "border layout scaffold" entry churned the three submenu-navigation tests
  (menu one row taller — `fg classify` called all four diffs BENIGN?row, eyeball-confirmed the new
  row); gated recapture COMPLETE.
- **P4+P5 CLOSED 2026-08-04 19:00: FULL GAUNTLET GREEN, all 14 legs, 274 tests** (crossAlign test
  riding permanently; parts leg green with the relocated chrome).

### P6 — docs + close, 2026-08-04
- `docs/architecture/layout.md` §4.2 REWRITTEN as the spec-family reference (+ §8 item 4 nil-FF);
  BACKLOG: the arc-4 banked adder-members line closed as superseded-in-the-opposite-direction;
  assessment §2.5 gained the "⇄ CONFIGURATION UNIFIED" closure block; MACRO-PATTERNS swept in P1d.
- Ratchets tightened and locked: instanceof-type-test 93→88; [U]-query 132→131 (both with dated
  reasons in their gate files).
- Final gates: gauntlet 14/14 (19:00) + `fg homepage` at close. Plan moved to `docs/archive/` +
  INDEX line; memory updated. Commits proposed to the owner (never auto-committed).

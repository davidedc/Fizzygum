# Decoupling Widget from subclass identity — a true-polymorphism plan

A dedicated, case-by-case plan to stop `Widget` (and the other God classes) from
**deciding behaviour by interrogating subclass identity**. It is the detailed execution of
the *true-polymorphism* part of Phase 5 in `oo-smells-refactoring-backlog.md`, and it is meant
to be executable cold — it embeds the history, the established facts, the patterns, the worked
exemplar, and the per-cluster catalogue with `file:line`s.

---

## Why this, why now (history)

Phase 5 of the OO backlog is "decouple `Widget` from its ~25 subclasses." The first attempts
mechanically swapped `instanceof X` → `x.isX?()` **predicates**. The owner's verdict (2026-06-17):
that is *still bad* — a type-test in a nicer coat. The real smell is that `Widget`, a God Class,
**makes decisions from subclass identity at all**. `if @x.isScrollPanel?()` is only cosmetically
better than `if @x instanceof ScrollPanelWdgt`; both mean "the base knows its leaves."

So the predicate sweep (a "5c" attempt over ~18 Widget sites) was **reverted**, and this plan
replaces it: fix each check *completely* by moving the behaviour to the type that owns it, so
`Widget` stops asking.

**Relationship to Phase 6 (God-Class split):** `Widget` interrogates identity *because* it holds
responsibilities (layout coordination, scroll coordination, menu building) that belong on the
leaves/collaborators. Many of these checks **dissolve** when those responsibilities move out
(Phase 6). This plan and Phase 6 are the same work seen from two ends: do the tractable
polymorphic moves here; for the ones that only resolve cleanly under the split, this doc says so.

---

## Established facts (don't re-learn these)

- **Adding methods to common base classes is inspector-safe — zero recapture.** Probe (2026-06-17):
  adding an *uncalled* `isPanel: -> true` to `PanelWdgt` gave **165/165**. So there is **no
  per-step recapture tax** for introducing hook methods, as long as the conversion is
  behaviour-faithful. (The earlier worry — that methods on `Panel`/`World`/etc. would recapture the
  inspector "inherited: on" pane — was disproven by that probe.)
- **A faithful conversion ⇒ zero recapture.** The byte-exact SystemTest suite is the oracle.
- **Predicates are a dead end here.** The reverted 5c sweep (instanceof → `?.isX?()` predicates over
  ~18 Widget sites) both (a) failed the owner's design bar and (b) shipped a real behaviour
  regression (37 window/scroll/resize/inspector tests). **Do NOT reintroduce the predicate sweep.**
- **5a/5b are kept** (committed): 5a moved the smart-placer behaviour onto the content widgets (true
  polymorphism); 5b removed `Widget`/`TreeNode`'s *compile-time naming* of `WindowWdgt`/`HandleWdgt`/
  `CaretWdgt` via `isWindow?()`/`isLayoutDecoration?()`. 5b's two are queries (the "somewhat better"
  category) — fine as an interim, optionally upgradable to behaviour-moves later (see Cluster D).

---

## The patterns (prefer 1 and 2; 3 only when behaviour genuinely cannot move)

1. **Notify-hook (dominant).** Replace `if @parent instanceof X then @parent.doThing()` with an
   unconditional `@parent?.someEvent?(args)`. The container types that care implement `someEvent`
   (and do their thing); everyone else simply doesn't have it (the `?()` soak is a no-op). The child
   **stops knowing container types**. ← the exemplar.
2. **Override-hook.** Replace `if @ instanceof X then @doXSpecificThing()` with `Widget` calling a
   `@hook()` that is a base no-op and `X` overrides. `Widget` stops branching on itself.
3. **Capability query (fallback, rare).** `x.canFoo?()` ONLY where the behaviour can't move — e.g.
   *filtering* chrome out of a child-iteration (a property of the iteration, not pushable into the
   widget). Still better than `instanceof`, but reach for 1/2 first.

**Faithfulness rule.** Each conversion must fire for *exactly* the same set of objects as the
original `instanceof`. Mind inheritance: a hook on a base is inherited by subclasses, mirroring
`instanceof`'s is-a reach (e.g. `childGeometryChanged` on `SimpleVerticalStackPanelWdgt` is inherited
by `WindowWdgt`, matching `instanceof SimpleVerticalStackPanelWdgt` being true for windows). Do NOT
"improve" the set — broadening/narrowing which objects react is a *separate* behaviour decision, out
of scope. Expect **zero recapture**; treat any red test as a bug and localize it.

---

## Verify recipe (per step; from `Fizzygum/`)

`./build_and_test.sh` (dpr1) → `cd ../Fizzygum-tests && node scripts/run-all-headless.js --dpr=2`
→ `… --browser=webkit` → the `--homepage` boot leg as a 3-step cd sequence. Zero recapture
expected. A red test localizes via the runner's failing-name list (printed inline per FAIL and
aggregated at the end) + `node scripts/run-macro-test-headless.js SystemTest_<name> --dump-failures`.
(dpr-2 "SUITE FAILED" with **no** `failed tests (N)` line = a shard *disconnect*, infra — re-run.)

---

## Exemplar (DONE 2026-06-17 — the template)

- **Cluster:** `Widget`'s three `if @parent instanceof SimpleVerticalStackPanelWdgt then
  @parent.adjustContentsBounds()` (in the move-by-delta and `refreshScrollPanelWdgtOrVerticalStack…`
  paths).
- **Fix:** `childGeometryChanged: -> @adjustContentsBounds()` on `SimpleVerticalStackPanelWdgt`
  (inherited by `WindowWdgt`); the three sites become `@parent?.childGeometryChanged?()`.
- **Result:** 165/165 Chrome dpr1+dpr2 + WebKit, **zero recapture**. `Widget` no longer names the
  subclass there; the stack owns its reaction. This is the shape every cluster below should take.

---

## Catalogue of remaining `Widget` identity-checks (by cluster)

Re-grep `rg -n 'instanceof' src/basic-widgets/Widget.coffee` for the live list; sites drift. Current
clusters (after 5a/5b + the exemplar):

- **A — layout/scroll notification (continue the exemplar).** The notification of "my geometry
  changed, container please re-lay-out" is inconsistent across the tree: `PanelWdgt` already
  duck-types `@parent.adjustContentsBounds?()` (reactToDropOf/childRemoved/addInPseudoRandomPosition/
  reactToGrabOf), `SimpleVerticalStackPanelWdgt`/`ListWdgt` gate on `amIPanelOfScrollPanelWdgt()`, and
  `Widget` used `instanceof` (now the exemplar's `childGeometryChanged`). **Unify** these onto the
  notify-hook family (`childGeometryChanged` / a sibling for the scroll-bar case). Faithful per call
  site. *Highest value, most mechanical now that the hook exists.*
- **B — scroll-panel structural self/parent queries.** `amIDirectlyInsideScrollPanelWdgt`
  (`Widget:~2581`), `amIPanelOfScrollPanelWdgt` (`~2590`), `amIDirectlyInsideNonTextWrappingScrollPanelWdgt`
  — each `instanceof Panel/VStack/ScrollPanel/List`. These ASK "where am I in the scroll structure"
  to decide reactions. Deeper fix: the scroll panel owns/declares the relationship, or the content
  asks via a protocol method; several callers may collapse into Cluster A's notify-hook. **Study —
  medium/hard.**
- **C — self-is-scroll-panel.** `Widget:~3607,~3616` `if @ instanceof ScrollPanelWdgt then
  @adjustContentsBounds(); @adjustScrollBars()` (in the attach-selected-widget paths) →
  **override-hook**: a base no-op `afterAttaching…()` that `ScrollPanelWdgt` overrides.
- **D — WindowWdgt (polish on 5b).** `Widget:480` (content-close closes its window) and `:3477`
  (close-vs-delete menu label) already use `isWindow?()` (5b). Optional upgrade to behaviour-moves
  (e.g. `:3477` → an `addDestroyMenuItem(menu)` overridden by `WindowWdgt`). Low priority.
- **E — lock-to-panels.** `Widget:~2522-2535` `if @parent instanceof World/Panel then return
  @isLockingToPanels`. The parent could answer "do I host locking children", or the locking decision
  moves to the parent. **Study — medium.**
- **F — hierarchy-menu filter.** `Widget:~2958-2960` compound (`SVStack`+`SVStackScrollPanel` /
  `Panel`+`ScrollPanel` / `ScrollPanel`+`FolderWindow`) deciding which widgets are hidden as internal
  scaffolding in the hierarchy menu → a `hiddenAsInternalScaffolding?()` capability on the relevant
  types, or **defer to Phase 6** (it is really about the menu builder's knowledge of internals).
- **G — content/role checks (Widget-names-leaf, non-structural).** `:3830-3831` (`String`/
  `SimplePlainText` "is this text"), `:4410-4458` (`LayoutElementAdderOrDropletWdgt` ×5), `:1963`
  (`IconicDesktopSystemShortcutWdgt`), `:608/1248/1441` (`HandleWdgt` exclusion/initiator), `:2206`
  (`Highlighter`/`Caret` exclusion), `:2216` (`ToolTipWdgt`). Each → a polymorphic method or
  behaviour-move on those types; the pure *exclusion/filter* ones (608/2206) may legitimately stay
  capability-queries (pattern 3).
- **Leave alone (legitimate):** `:269` `@layoutSpecDetails instanceof VerticalStackLayoutSpec` (a
  LayoutSpec value type, different hierarchy); the value-coercion `instanceof` in `Point`/`Rectangle`/
  `Color`; serialization `.className` round-trips; reflection/test-harness class lookups.

**Suggested sequence:** A (finish notification unification) → C (override-hook, mechanical) → E →
B → G → D-polish → F. F and parts of B/E may be folded into Phase 6 rather than done standalone.
One cluster per step; verify (full recipe) and commit per cluster, like 5a/5b/exemplar.

---

## Process notes

- **One cluster per step**, faithful, verified by the full recipe, committed individually (the
  `5a/5b/exemplar` cadence). Update this doc's catalogue as clusters close.
- **No predicates for the structural clusters** — move behaviour (patterns 1/2). Pattern 3 only for
  genuine filters, and call it out when used.
- **Commit messages: plain identifiers, no backticks** (the Bash tool command-substitutes backticks
  in `-m`; see memory `bash-tool-backticks-corrupt-commit-msgs`).
- **The fragmenter** rejects a method placed *before* a class-level `@augmentWith` directive, and a
  one-line `constructor: -> super …`; keep new methods in the methods region (after `@augmentWith`/
  fields) and constructors multi-line.

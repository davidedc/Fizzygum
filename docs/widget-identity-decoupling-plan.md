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
- **DELETING an inspector-visible `Widget` method DOES force a (localized, expected) recapture** —
  the asymmetric counterpart to the above. Confirmed in Cluster A (2026-06-17): removing the
  now-dead `amIPanelOfScrollPanelWdgt` flipped exactly ONE test,
  `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly`, whose macro opens an Object Inspector
  whose "methods" pane lists Widget's methods alphabetically — "no screenshots like this one". The
  pixel delta was verified (live-vs-committed PNG) to be *only* that one method's row vanishing (the
  list shifts up by one); no behaviour change. So: ADD = free; DELETE-of-an-inspector-visible-method
  = a one-test recapture you must regenerate
  (`node scripts/capture-macro-test-references.js <name> --clean --dprs=1,2`) and then re-verify the
  full recipe. This is exactly the cost behind Phase 0's "dead Widget-method removal needs a
  recapture"; do such deletions deliberately, isolate them, and confirm the diff before regenerating.
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

- **A — layout/scroll notification — DONE 2026-06-17.** Study finding that *corrects the original
  premise:* the notification idioms are NOT one notification and must NOT be merged into a single
  hook. `PanelWdgt`'s duck-typed `@parent.adjustContentsBounds?()` fires for parent ∈ {ScrollPanel,
  List, SVStack, Window} (anything that defines the method), whereas `SimpleVerticalStackPanelWdgt`'s
  `amIPanelOfScrollPanelWdgt()` fires for {ScrollPanel} **minus** {List}; they differ on List parents
  AND on SVStack/Window parents, so a shared hook would be unfaithful. Also: only
  `SimpleVerticalStackPanelWdgt` used `amIPanelOfScrollPanelWdgt` — NOT `ListWdgt`, as the original
  note guessed. **What shipped:** a new `_reLayOutAfterContainedPanelChange` notify-hook on
  `ScrollPanelWdgt` (does the `adjustContentsBounds()`+`adjustScrollBars()` pair, returns `true` =
  "I absorbed it"), with a `ListWdgt` opt-out override (returns `nil`) — faithfully reproducing
  `instanceof ScrollPanelWdgt and not instanceof ListWdgt`. Kept deliberately SEPARATE from
  `reactToDropOf`/`reactToGrabOf` because `ListWdgt` inherits those and must keep adjusting on its own
  drops while opting OUT of the contained-panel notification (folding the hook into them would
  silently stop a list adjusting — unfaithful). `SimpleVerticalStackPanelWdgt`'s two
  `amIPanelOfScrollPanelWdgt()` sites became `return if @parent?._reLayOutAfterContainedPanelChange?()`
  then self-adjust (inherited by `WindowWdgt`, incl. via its `reactToDropOf` `super`). With its only
  callers gone, `amIPanelOfScrollPanelWdgt` was **deleted** from `Widget` (owner call: accept the
  recapture); that caused the single inspector recapture in Established facts — regenerated +
  re-verified. `PanelWdgt`'s 4 duck-typed sites were left AS-IS (already decoupled; routing them
  through the hook would be unfaithful per the List/SVStack-parent finding); `Widget`'s grandparent
  block stays in Cluster B. 165/165 Chrome dpr1+dpr2 + WebKit + `--homepage`.
- **B — scroll-panel structural self/parent queries.** `amIPanelOfScrollPanelWdgt` is GONE (deleted
  in Cluster A). Remaining: `amIDirectlyInsideScrollPanelWdgt` (`Widget:~2579`) and
  `amIDirectlyInsideNonTextWrappingScrollPanelWdgt` (`~2593`, defined via the former) — each
  `instanceof Panel/VStack/ScrollPanel/List`. Both gate `Widget`'s Group-1 grandparent block
  (`@parent.parent.adjustContentsBounds()`+`@parent.parent.adjustScrollBars()` in `fullRawMoveBy`
  ~1142, the rawSetExtent path ~1477, and `refreshScrollPanelWdgtOrVerticalStackIfIamInIt` ~1484 —
  the first two use the NonTextWrapping variant, the third the plain one, so their firing sets differ
  and can't be collapsed naively). These ASK "where am I in the scroll structure". Deeper fix: the
  grandparent scroll panel owns the relationship via a protocol method (the pair could become a
  `descendantGeometryChanged` notify-hook on `ScrollPanelWdgt`, but the text-wrapping distinction
  must be preserved). The pair itself is now named once as
  `ScrollPanelWdgt.refitContentsAndScrollBars` (extracted in Cluster C) — reuse it when this cluster
  lands. **Study — medium/hard; entangled with Phase 6.**
- **C — self-is-scroll-panel — DONE 2026-06-17.** `Widget`'s two `if @ instanceof ScrollPanelWdgt
  then @adjustContentsBounds(); @adjustScrollBars()` (the `newParentChoice` /
  `newParentChoiceWithHorizLayout` attach-selected-widget paths, ~3601/~3610) became
  `@refitContentsAndScrollBars?()`. Extracted the pair into a new
  `ScrollPanelWdgt.refitContentsAndScrollBars` (inherited by `ListWdgt` and all scroll-panel
  subclasses, NO opt-out) and dispatched via `?()` so **nothing lands on `Widget`** (zero recapture
  — this is why an override-hook with a base no-op on `Widget`, which WOULD recapture the inspector,
  was avoided). Faithfulness note that *forced a separate method* (NOT reusing Cluster A's
  `_reLayOutAfterContainedPanelChange`): here `instanceof ScrollPanelWdgt` INCLUDES `ListWdgt`, whereas
  Cluster A EXCLUDED it — so Cluster C must hit a hook `ListWdgt` does NOT opt out of.
  `_reLayOutAfterContainedPanelChange` now delegates to `refitContentsAndScrollBars`. 165/165 Chrome
  dpr1+dpr2 + WebKit + `--homepage`.
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

**Suggested sequence:** ~~A~~ **DONE** → ~~C~~ **DONE**. **Remaining clusters E, B, F, G, D are now
FOLDED INTO Phase 6** (owner decision 2026-06-17): after A/C, no clean behaviour-moves remain — E/B/F
are scroll-structure topology that *dissolves* under the God-class split, and G are leaf-role filters
convertible only to pattern-3 capability-queries (the "renamed type-test" we avoid). The clean
true-polymorphism wins (5a/5b/exemplar/A/C) are THIS endeavour's deliverable; the remainder is tracked,
with a per-check dissolution map, in **`god-class-decomposition-plan.md`**. One cluster per step;
verify (full recipe) and commit per cluster, like 5a/5b/exemplar.

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

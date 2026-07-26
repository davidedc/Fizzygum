# Mixins — mechanism, inventory, and the keep-vs-remove position

> Written 2026-07-03 (three-agent sweep: per-mixin inventory, docs/git-history record,
> tooling-coupling map), refreshed and re-verified against `src/` 2026-07-24; the five
> misfiled mixins were folded into standard-OO homes 2026-07-26 (§4). This doc is
> BOTH the evergreen reference for how the mixin mechanism works and the standing
> position on keeping vs. removing it, with the evidence embedded (self-contained per
> `docs/README.md`). The inventory table is dated; re-verify counts before relying on
> them in a future arc.

## 1. The standing position

**Keep the mechanism.** Mixins are the codebase's answer to a real gap — CoffeeScript is
single-inheritance, and a handful of behaviours must be *injected into* classes on
unrelated branches of the hierarchy, overriding framework hooks (`setColor`, `add`,
`mouseDownLeft`, the paint/geometry protocol) — something a delegated collaborator
structurally cannot do without a forwarding stub per hook per consumer.

The refined policy (supersedes a literal reading of the "mixins are being phased out"
line in `CLAUDE.md` — see §6):

- **No new mixin for a liftable responsibility.** A cohesive responsibility that can be
  *delegated out* becomes a plain collaborator class (the `MacroToolkit` pattern:
  `world.macroToolkit`, `Wallpaper`, `WidgetFactory`, `UntitledNamingService`,
  `Serializer`/`Deserializer`).
- **A mixin remains the right tool** when a behaviour must be *injected into* several
  classes that share no usable base, especially when it overrides framework hooks.
  (This is the `docs/archive/god-class-decomposition-plan.md` carve-out, and it is what
  practice has consistently done — §6.)
- **Single-consumer / single-subtree mixins are misfiled** — fold them into the consumer
  or a shared base (executed 2026-07-26 for all five then-misfiled ones, §4).
- **A full-removal campaign is explicitly rejected** — the arithmetic in §5 and §7: it
  would trade the one-line `@augmentWith` declarations (31 consumer files) for ~100+ forwarding stubs or
  hierarchy surgery across the paint/input/clipping/copy subsystems (the most
  determinism-critical, screenshot-baked code), to delete ~350 lines of stable machinery
  whose worst failure mode (the regex `super` rewriter) survives in `Class.coffee`
  regardless.

## 2. How the mechanism works

A mixin is a plain object literal in `src/mixins/<Name>Mixin.coffee` whose
`onceAddedClassProperties` hook injects members into a consuming class:

```coffee
SomethingMixin =
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,
      someMethod: (args) ->
        super args        # see the super caveats below
```

A class opts in with a single class-body line: `@augmentWith SomethingMixin`.

- **Injection** — `Object::augmentWith` copies class-side keys onto the constructor and
  fires `onceAddedClassProperties`; `Object::addInstanceProperties` writes each member
  onto the consumer's prototype (`src/boot/extensions/Object-extensions.coffee`). The two
  hook names in `MixedClassKeywords` (`src/boot/globalFunctions.coffee`) are skipped.
- **`super` is emulated, not real.** A mixin method belongs to no class at compile time,
  so `Mixin._equivalentforSuper` (`src/meta/Mixin.coffee`) regex-rewrites `super` into
  `window[@[arguments.callee.name + '_class_injected_in']].__super__[...]`, resolved via
  a `<methodName>_class_injected_in` companion property that `addInstanceProperties`
  writes next to every injected function. Constraints that follow:
  - only the bare `super` (forwards all arguments) and `super arg, …` forms are
    rewritten; `super()` / `super(args)` are open TODOs (`Mixin.coffee`) — the class-side
    rewriter (`Class._equivalentforSuper`) supports all four;
  - `arguments.callee` pins the compiled output to sloppy mode;
  - the rewrite rules are order-sensitive text substitutions — a bare `super` with a
    trailing inline comment silently dropped all arguments until hardened on 2026-07-02
    (`cbb90457`, the "thin vertical slice" defect). The same hazard class exists for
    classes too; it is a cost of fragment-wise compilation, only partly a mixin cost.
  - default parameter values don't survive the mixin field parser (the workaround is
    manual `if !param?` defaulting in the method body).
- **Override semantics: the class body wins.** The boot emitter outputs the
  `augmentWith(...)` calls BEFORE the class's own prototype assignments
  (`Class.coffee` `for eachAugmentation in @augmentedWith`, ~:349), so a class-body
  method with the same name as a mixin method shadows it. This is deliberate and now
  gate-visible: `census-hierarchy-duplication.js` reports `SHADOWS-MIXIN`, and the
  case law is recorded in `docs/architecture/lint-and-static-checks.md` (a "redundant"
  class-body default that actually exists to override its mixin — deleting it would have
  turned the desktop icons near-white). (`Color`'s long-standing shadow of the
  then-`DeepCopierMixin`'s shell method became an ordinary per-class hook when that mixin
  was converted to the `Duplicator` engine — §5-C.)
- **Load order** — `@augmentWith X` is one of the literal forms
  `src/boot/dependencies-finding.coffee` regex-scans (`REQUIRES_MIXIN`), creating the
  "mixin defined before its consumer" edge. Keep the literal form so the finder sees it.
- **Two different "is this file a mixin" detectors coexist**: `buildSystem/build.py`
  keys off `^\w+Mixin\s*=` while the boot loader keys off
  `/^  onceAddedClassProperties:/m` (`loading-and-compiling-coffeescript-sources.coffee`).
  They agree today; nothing enforces that they keep agreeing (proposed gate, §8).
- **Meta-system status: first-class for inspection since 2026-07-03.** The parsed
  `Mixin` instances register in `Mixin.allMixines` (create pass only — the build-time
  syntax gate's parse-only pass never registers), and
  `InspectorWdgt._mixinSourceForMember` consults each class's `augmentedWith` list to
  show a mixin method's REAL CoffeeScript source in the inspector (Tier H5, `b05f8d1e`;
  crash guard `14014e44` — the prototype-walk used to throw on mixin methods under JSC).
  Live-EDITING a mixin (round-trip source editing, as classes support via
  `nonStaticPropertiesSources`) is still not wired — view is first-class, edit is not.
- **Build/boot cost** — mixin sources ship as escaped text and are batched identically
  to classes; in the `--homepage` precompiled image the compile/eval/super-rewrite is
  baked in and only the cheap regex field-split runs per boot. Negligible either way.
- **Tooling that understands the mixin DSL** (the recurring tax, but paid and working):
  the syntax gate drives every mixin through the real `Mixin` class
  (`check-coffee-syntax.js`); `check-layering.js` attributes methods defined inside
  `onceAddedClassProperties` blocks; `census-public-private-calls.js` builds the
  whole-system class model INCLUDING `@augmentWith` resolution order, which the
  hierarchy-duplication census reuses for `SHADOWS-MIXIN`.

## 3. Inventory (verified 2026-07-26; 7 mixins, 642 L, 31 consumer files)

| Mixin | L | Consumers (files) | Branch topology | fake-`super`? |
|---|---|---|---|---|
| `ClippingAtRectangularBoundsMixin` | 220 | 5 — `PanelWdgt` (base of the panel subtree), `ClippingBoxWdgt`, `SimpleVerticalStackPanelWdgt`, `FrameWdgt`, `SimpleSpreadsheetWdgt` | base class + unrelated branches | yes |
| `ControllerMixin` | 112 | 7 — `SliderWdgt`, `StringWdgt`, `SimpleTextWdgt`, `PaletteWdgt`, `FanoutWdgt`, `FanoutPinWdgt`, `PatchNodeWdgt` (base for 3 node classes) | 2 subsystems, ≥4 branches | no |
| `HighlightableMixin` | 54 | 9 — `ButtonWdgt`, `CreatorButtonWdgt`, `GlassBoxTopWdgt`, `SimpleDropletWdgt`, `BinOpenerWdgt`, 2 desktop-link classes, 2 icon-button classes | ≥4 branches | yes |
| `BackBufferMixin` | 137 | 3 — `CanvasWdgt`, `StringWdgt`, `PaletteWdgt` | unrelated branches | no |
| `KeepsRatioWhenInVerticalStackMixin` | 75 | 3 — `GraphsPlotsChartsWdgt`, `PlotWithAxesWdgt`, `IconWdgt` | unrelated leaves | no |
| `WidgetCreatorAndSmartPlacerOnClickMixin` | 33 | 2 — `CreatorButtonWdgt`, `GlassBoxTopWdgt` | unrelated leaves | no |
| `ParentStainerMixin` | 11 | 2 — `CreatorButtonWdgt`, `EditorContentPropertyChangerButtonWdgt` | unrelated leaves | yes |

(`ContainerMixin` — dead since birth, "TEMPORARY. JUST STARTED IT." — was deleted
2026-07 in the accidental-complexity batch `3267b0dd`. The five misfiled mixins were
folded into standard-OO homes 2026-07-26 — see §4 — and `DeepCopierMixin` was converted
to the `Duplicator` engine (`src/duplication/`) the same day, completing for duplication
the engine inversion serialization got in July — see §5-C. `Mixin.allMixines` — formerly
dead scaffolding — became load-bearing for the inspector in Tier H5.)

## 4. Which of these are GENUINE multiple inheritance

The test: consumers on unrelated branches AND behaviour that overrides framework hooks.

- **Genuine (the keep-core — all 7 current mixins):** `ControllerMixin` (the wire/dataflow client protocol across basic widgets and
  patch-programming — and the home the dataflow engine deliberately built on),
  `HighlightableMixin` (input-hook state machine across ≥4 branches),
  `BackBufferMixin` (paint-path override; load-bearing for the unified shadow mechanism
  — the blit at α is WHY a transparent text widget's shadow is its glyphs),
  `ClippingAtRectangularBoundsMixin` (overrides the geometry protocol — `fullBounds`,
  cache-invalidation super-chains; the `ClippingBoxWdgt` diamond: `BoxWdgt` painting +
  panel clipping), `KeepsRatioWhenInVerticalStackMixin`,
  `WidgetCreatorAndSmartPlacerOnClickMixin`, `ParentStainerMixin` (barely — 2 unrelated
  leaves each).
- **Misfiled (single consumer / single subtree / config bag) — all five folded into
  standard-OO homes 2026-07-26**, motivated by inspectability (a mixed-in member's
  source is view-only in the inspector, and it is unclear whether to edit the donor or
  the receiver; a class member is fully first-class). Where each went:
  - `GridPositioningOfAddedShortcutsMixin` + `KeepIconicDesktopSystemLinksBackMixin`
    (both exactly {`FolderPanelWdgt`,`WorldWdgt`}) → the shared base
    `IconicDesktopSystemPanelWdgt extends PanelWdgt` (both consumers now extend it).
    `WorldWdgt`'s former SHADOWS-MIXIN grid-field overrides are now ordinary base-class
    shadowing; the deliberate no-super replacement of `PanelWdgt._reactToChildAdded`
    (suppressing the scroll-panel-holder relay) is preserved and commented in place.
  - `CreateShortcutOfDroppedItemsMixin` (single consumer) → folded into
    `FolderPanelWdgt`; its fake `super` became a real class-side one.
  - `ChildrenStainerMixin` (sibling leaves) → `setColor` folded into the pair's shared
    base `GenericCompositeIconWdgt` (the base the frame-model era had already created).
  - `CornerInternalHaloMixin` (config bag) → deleted outright: both consumers' ctors
    already assign the `layoutSpec_cornerInternal_*` fields, and `isLockingToPanels:
    false` duplicates the `Widget` prototype default — every injected value was shadowed
    or redundant.

## 5. Could standard OO cover even the genuine cases? Yes — at these prices

None of the five is *impossible* without mixins; Morphic ancestors used delegation
patterns for the same needs, and Fizzygum already has the seam (`*Appearance` strategy
objects on the paint path). Three shapes, with costs:

- **A — forwarding stubs** (host HAS-A collaborator; every overridden hook becomes a
  hand-written stub: `mouseDownLeft: -> @highlighter.onMouseDown(); super`). Always
  works. Genuine advantages: the stub gets REAL CoffeeScript `super` (the
  `arguments.callee` rewriter drops out), and the collaborator is a plain class — fully
  first-class everywhere. Cost is arithmetic: `HighlightableMixin` alone = 9 consumers
  × ~5 hooks ≈ 45 stubs replacing 9 one-liners; `ControllerMixin` ≈ 20+ stubs plus
  retargeting the by-name menu dispatch; cohesion degrades from one file to one file
  plus N scattered stub blocks.
- **B — base-class extension points** (the base hook consults an optional strategy:
  `@highlighter?.onMouseDown()`; consumers just instantiate the collaborator — zero
  stubs). Clean Strategy; precedent exists (Appearance). Frictions: adds a field + call
  site per hook to `Widget` (against the shrink-Widget doctrine), and for
  Highlightable/BackBuffer/Clipping those hooks are the input/paint/geometry hot paths
  — the most determinism-critical code, where restructuring means screenshot-level
  re-verification for zero functional gain.
- **C — invert to an external engine** (visitor). Right where the "mixin" is really one
  algorithm plus per-class hooks. **Executed twice**: for serialization in July 2026 (the
  `doSerialize` half of the then-`DeepCopierMixin` became the plain
  `Serializer`/`Deserializer` classes, `src/serialization/`), and for duplication on
  2026-07-26 — the remaining walker became the `Duplicator` engine
  (`src/duplication/Duplicator.coffee`): one instance per copy run owns the identity
  bookkeeping, the per-class hooks (`getEmptyObjectOfSameTypeAsThisOne`,
  `rebuildDerivedValue`, `keptByReferenceOnDeepCopy`, `_reactToBeingCopied`) stay on the
  classes, and the native-type detection both engines share lives in `NativeValueKinds`.
  Byte-identical: full gauntlet, zero recaptures — see
  `docs/architecture/serialization-duplication-reference.md`.

State migration (mixin fields like `@target`/`@action` serialize as widget own-props)
and by-name dispatch (menus invoke `openTargetSelector` on the widget) are the two
recurring conversion costs regardless of shape.

## 6. The written record vs. executed practice

- `CLAUDE.md`/`AGENTS.md` long said "Mixins are being **phased out** in favour of
  plain-OO delegation"; both were reworded 2026-07-26 to the §1 policy. The archived
  `god-class-decomposition-plan.md` states the real, narrower rule:
  delegation for what can be *delegated out*; mixins "remain available where a behaviour
  must be *injected into* the widget."
- **In ~9.5 years of history, no mixin was ever converted to delegation.** One was
  deleted (dead `ContainerMixin`, 2026-07). The delegation direction produced NEW
  collaborators (`MacroToolkit` → `Wallpaper` → `WidgetFactory` → `UntitledNamingService`
  → `Serializer`/`Deserializer`) — it never dismantled a mixin. The 2026-07-26 fold of
  the five misfiled ones (§4) is the first conversion, and it went to *inheritance
  homes* (fold into consumer / shared base), not delegation — consistent with the §1
  policy, which reserves delegation for liftable responsibilities.
- **New code keeps choosing mixins** (all July 2026): the spreadsheet subsystem
  (`SimpleSpreadsheetWdgt` → Clipping; `SheetModel`/`SheetCellRecord` → the then-DeepCopier),
  the frame model (`FrameWdgt` → Clipping), transforms (`TransformSpec` → the then-DeepCopier),
  the patch-programming dedup (`PatchNodeWdgt` base → Controller). The dataflow-engine
  campaign made `ControllerMixin` the cohesive home of the whole wire-client protocol
  (`_fireConnection`, `firesPerEvent`, the shared connect-menu block) — and the dedup
  arcs moved shared menu code INTO it. `docs/plans/creation-and-templates-plan.md`
  builds `FactoryWdgt` on the `Duplicator`.
- Meanwhile the platform *invested in* mixins rather than removing them: inspector
  source recovery (Tier H5), the `SHADOWS-MIXIN` census, mixin-DSL awareness in
  `check-layering`, the hardened super-rewriter, and the retired connection-token
  machinery simplifying the stainer mixins to clean 2-line overrides.

Practice, tooling, and new subsystems all treat mixins as a permanent, first-class
mechanism with a narrow remit. The `CLAUDE.md` phase-out sentence should be reworded to
the §1 policy (proposed, §8).

## 7. The tradeoff ledger (why the position is "keep")

Costs of keeping (all real, all now bounded):
- the emulated `super` (weaker than the class form; `arguments.callee`; regex rewriter —
  one silent-miscompile incident, since hardened; the class-side twin keeps most of this
  risk alive even in a mixin-free world);
- the mixin-DSL tax on every new static gate (paid for all current gates; the census
  class model now makes it reusable);
- implicit override semantics (mitigated: `SHADOWS-MIXIN` census + recorded case law);
- two unsynchronized mixin detectors (open, cheap to gate);
- live-editing of mixin source still not wired (view-only first-class).

Costs of removing (why it loses):
- the four biggest genuine-MI mixins (Clipping/Controller/Highlightable/BackBuffer) need
  stub forests (≈100+ methods) or new `Widget`
  extension points on the paint/input/geometry hot paths — determinism-critical,
  behaviour-neutral churn of exactly the kind this project's case law banks rather than
  executes;
- both escape hatches violate standing doctrine (shrink `Widget`; capability methods on
  the answering subclass, never a base default);
- ~350 L of machinery deleted, ~642 L of behaviour merely relocated, net LOC likely UP;
- no active campaign is blocked by mixins (verified across all plan docs, twice —
  2026-07-03 and 2026-07-24);
- the July evolution demonstrates the healthy equilibrium: delegate what delegates
  (serializer), inject what injects (dataflow client protocol), delete what's dead
  (`ContainerMixin`).

## 8. Proposed follow-ups (NOT scheduled; adopt via `BACKLOG.md` if picked up)

(Items 1 and 2 of the original list — reword the `CLAUDE.md`/`AGENTS.md` "phased out"
sentence, fold the misfiled mixins — were executed 2026-07-26; see §4 and §6.)

1. **Gate the detector pair**: assert `build.py`'s and the boot loader's mixin
   detectors classify every shipped file identically.
2. Optional, larger: wire mixin source EDITING in the inspector (H5 did view) — the
   remaining first-class-ness gap, and the standing inspectability complaint against
   the mechanism; `super()`/`super(args)` support or a syntax-gate error in mixin
   bodies.

## Related docs

- `docs/architecture/serialization-duplication-reference.md` — the Duplicator traversal
  contract; the serializer split.
- `docs/architecture/lint-and-static-checks.md` — the mixin-aware gates and censuses;
  the SHADOWS-MIXIN case law.
- `docs/archive/god-class-decomposition-plan.md` — the delegation precedent and the
  injected-vs-delegated carve-out.
- `docs/archive/connection-cascade-settle-fix-plan.md` — how `_fireConnection` came to
  live in `ControllerMixin`.
- `src/macros/CLAUDE.md` — the `MacroToolkit` delegation exemplar.

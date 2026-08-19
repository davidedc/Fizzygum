# Mixins — mechanism, inventory, and the keep-vs-remove position

> Verified against `src/` 2026-08-16. This doc is BOTH the evergreen reference for how the
> mixin mechanism works and the standing position on keeping vs. removing it, with the
> evidence embedded (self-contained per `docs/README.md`). The inventory table carries its
> own verification date; re-verify counts before relying on them in a future arc.

## 1. The standing position

**Keep the mechanism.** Mixins are the codebase's answer to a real gap — CoffeeScript is
single-inheritance, and a handful of behaviours must be *injected into* classes on
unrelated branches of the hierarchy, overriding framework hooks (`setColor`, `add`,
`mouseDownLeft`, the paint/geometry protocol) — something a delegated collaborator
structurally cannot do without a forwarding stub per hook per consumer.

The policy:

- **No new mixin for a liftable responsibility.** A cohesive responsibility that can be
  *delegated out* becomes a plain collaborator class (the `MacroToolkit` pattern:
  `world.macroToolkit`, `Wallpaper`, `WidgetFactory`, `UntitledNamingService`,
  `Serializer`/`Deserializer`).
- **A mixin remains the right tool** when a behaviour must be *injected into* several
  classes that share no usable base, especially when it overrides framework hooks.
  (This is the `docs/archive/god-class-decomposition-plan.md` carve-out, and it is what
  practice has consistently done — §6.)
- **Single-consumer / single-subtree mixins are misfiled** — fold them into the consumer
  or a shared base (§4).
- **A full-removal campaign is explicitly rejected** — the arithmetic in §5 and §7: it
  would trade the one-line `@augmentWith` declarations (the consumer count in §3) for ~100+ forwarding stubs or
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
  - all four super forms are rewritten — `super()`, bare `super` (forwards all
    arguments), `super(args)`, `super arg, …` — mirroring the class-side rewriter
    (`Class._equivalentforSuper`), with the same load-bearing rule order;
  - `arguments.callee` pins the compiled output to sloppy mode;
  - the rewrite rules are order-sensitive text substitutions, and the order is
    load-bearing — the known trap is a bare `super` carrying a trailing inline comment,
    which a mis-ordered rule set silently strips of all arguments. The same hazard class
    exists for classes too; it is a cost of fragment-wise compilation, only partly a mixin cost.
  - default parameter values don't survive the mixin field parser (the workaround is
    manual `if !param?` defaulting in the method body).
  - ⛔ **one mixin, one level per inheritance chain — enforced at boot.** A mixin's members
    are compiled ONCE into shared function objects, so injecting the same mixin into a class
    AND one of its ancestors puts the *same function* at two prototype levels, and the
    instance-resolved `_class_injected_in` marker makes the ancestor-level `super` call
    re-resolve to itself: any super-calling member recurses forever. This was latent for
    years (no doubly-injected member called `super`) and surfaced 2026-08-19 when
    `graphEdgesOut` — a `super`-composed protocol — reached `SimpleTextWdgt`, which
    re-augmented `ControllerMixin` over base `StringWdgt`'s injection. The redundant
    augment is removed and `addInstanceProperties` (`src/boot/extensions/Object-extensions.coffee`)
    now throws on injection of an already-inherited mixin function, so the mistake fails the
    boot loudly instead of looping at first call.
- **Override semantics: the class body wins.** The boot emitter outputs the
  `augmentWith(...)` calls BEFORE the class's own prototype assignments
  (`Class.coffee` `for eachAugmentation in @augmentedWith`, ~:386), so a class-body
  method with the same name as a mixin method shadows it. This is deliberate and now
  gate-visible: `census-hierarchy-duplication.js` reports `SHADOWS-MIXIN`, and the
  case law is recorded in `docs/architecture/lint-and-static-checks.md` (a "redundant"
  class-body default that actually exists to override its mixin — deleting it would have
  turned the desktop icons near-white).
- **Load order** — `@augmentWith X` is one of the literal forms
  `src/boot/dependencies-finding.coffee` regex-scans (`REQUIRES_MIXIN`), creating the
  "mixin defined before its consumer" edge. Keep the literal form so the finder sees it.
- **Two different "is this file a mixin" detectors coexist**: `buildSystem/build.py`
  keys off `^\w+Mixin\s*=` while the boot loader keys off
  `/^  onceAddedClassProperties:/m` (`loading-and-compiling-coffeescript-sources.coffee`).
  They agree today; nothing enforces that they keep agreeing (proposed gate, §8).
- **Meta-system status: first-class for inspection AND editing.** The parsed
  `Mixin` instances register in `Mixin.allMixines` (create pass only — the build-time
  syntax gate's parse-only pass never registers), and
  `InspectorWdgt._mixinProvidingMember` consults each class's `augmentedWith` list to
  show a mixin method's REAL CoffeeScript source in the inspector. The same attribution
  routes a CLASS-inspector save to the
  DONOR: `Mixin.applyMemberEdit` updates the recorded source, recompiles the member (the
  mixin super rewrite; the function's `.name` is restored so the fake-super companion
  lookup keeps working) and re-injects it into every consumer class recorded at
  `augmentWith` time — skipping consumers whose class body shadows the member AND
  consumers whose prototype carries a live class-scope override (`<name>_source`), so
  the boot-order override rule keeps holding for overrides born at edit time too. Edits
  log as scope-`"mixin"` records in `world.sourceEditsRegistry` and replay on world
  restore (the reference doc §12). The attribution covers methods AND fields: a
  donated method attributes through the function-branch chain walk (both inspector
  types), and a donated FIELD attributes in the CLASS inspector via
  `ClassInspectorWdgt._sourceForFieldMember` — prototype-level truth, shown in boot
  order of authority (live `<name>_source` override, class-body source, mixin donor's
  source) — while an OBJECT inspector keeps showing the instance's VALUE (per-instance
  state is its own truth). Both live-edit twins (`Mixin.applyMemberEdit` /
  `Class.applyMemberEdit`) compile through a bare global-assignment eval — never
  `Widget.evaluateString` against a prototype: its relayout/repaint tail treats the
  receiver as a WIDGET and stamps widget-lifecycle fields onto the prototype as own
  properties, polluting every later member listing of the class. The full editing
  vocabulary on top of that core:
  - **"override in this class"** (`ClassInspectorWdgt.overrideInThisClass`): a second
    save destination shown while a mixin-donated instance member (method or field) is
    selected — keeps the edited source as a live override on THAT class's prototype
    only (via `Class.applyMemberEdit`, the class twin, which super-rewrites exactly as
    the boot emit does and keeps `<name>_source` for EVERY member kind — the view's
    attribution key and the donor-edit shadow guard), after which donor edits skip the
    class;
  - a **"from `<Name>Mixin`" donor label** (`InspectorWdgt.mixinDonorLabel`) appears in
    the hierarchy row of BOTH inspector types while a mixin-donated member is selected;
  - **add/remove**: the class inspector's `add…` popout gains a destination step
    (class or any of its mixins — a mixin add is `applyMemberEdit` with a new name)
    when the class declares augmentations, and `remove` on a mixin-donated member
    routes to `Mixin.removeMember` (deletes member + fake-super companion from every
    non-shadowing consumer; logged as a `deleted: true` registry record);
  - **class-side statics**: the Mixin constructor parses the literal's 2-space keys
    into `staticPropertiesSources` (DSL hooks excluded); the inspector attributes and
    shows a donated static's source, and saves route to `Mixin.applyStaticEdit`
    (re-copies onto every consumer CONSTRUCTOR, shadow-guarded by the consumer's own
    class-side statics; registry records carry `static: true`).
- **Build/boot cost** — mixin sources ship as escaped text and are batched identically
  to classes; in the **`homepage` profile's** precompiled image the compile/eval/super-rewrite
  is baked in and only the cheap regex field-split runs per boot. Negligible either way.
- **Tooling that understands the mixin DSL** (the recurring tax, but paid and working):
  the syntax gate drives every mixin through the real `Mixin` class
  (`check-coffee-syntax.js`); `check-layering.js` attributes methods defined inside
  `onceAddedClassProperties` blocks; `census-public-private-calls.js` builds the
  whole-system class model INCLUDING `@augmentWith` resolution order, which the
  hierarchy-duplication census reuses for `SHADOWS-MIXIN`.

## 3. Inventory (verified 2026-08-18; 8 mixins, 1091 L, 33 consumer slots across 27 files)

Six live in `src/mixins/`; `ParentStainerMixin` and `WidgetCreatorAndSmartPlacerOnClickMixin` live
in `src/app-kit/`, beside the creator-button family that is their only consumer group. The 33 is the
sum of the per-mixin consumer counts below, spread over 27 distinct files: `CreatorButtonWdgt` takes
three, and `PaletteWdgt`, `StringWdgt`, `GlassBoxTopWdgt` and
`EditorContentPropertyChangerButtonWdgt` take two each.

| Mixin | L | Consumers (files) | Branch topology | fake-`super`? |
|---|---|---|---|---|
| `ClippingAtRectangularBoundsMixin` | 195 | 5 — `PanelWdgt` (base of the panel subtree), `ClippingBoxWdgt`, `SimpleVerticalStackPanelWdgt`, `FrameWdgt`, `SimpleSpreadsheetWdgt` | base class + unrelated branches | yes |
| `ControllerMixin` | 516 | 7 — `SliderWdgt`, `StringWdgt` (whence `TextWdgt`/`SimpleTextWdgt` inherit it — SimpleTextWdgt's own augment was the double-injection the boot guard now forbids), `PaletteWdgt`, `ColorPickerWdgt`, `FanoutWdgt`, `FanoutPinWdgt`, `PatchNodeWdgt` (base for 3 node classes) | 2 subsystems, ≥4 branches | yes — `graphEdgesOut` (super-composed, graph-edges §4.2) |
| `HighlightableMixin` | 54 | 7 — `ButtonWdgt`, `CreatorButtonWdgt`, `GlassBoxTopWdgt`, `SimpleDropletWdgt`, `DesktopLinkWdgt` (base of the 3-subclass desktop-link family: bin opener, shortcuts, app launchers), 2 icon-button classes | ≥4 branches | yes |
| `BackBufferMixin` | 162 | 3 — `CanvasWdgt`, `StringWdgt`, `PaletteWdgt` | unrelated branches | no |
| `KeepsRatioWhenInVerticalStackMixin` | 69 | 3 — `GraphsPlotsChartsWdgt`, `PlotWithAxesWdgt`, `IconWdgt`. Deliberate NON-consumers: `Example3DPlotWdgt` and `StretchableWidgetContainerWdgt` carry pinned-`@ratio` VARIANTS of this protocol (field-based, super-fallback) — see their in-file comments; do not "convert" them | unrelated leaves | no |
| `BubblesEditModeToCoordinatorMixin` | 51 | 3 — `SimpleVerticalStackViewportWdgt`, `StretchablePanelWdgt`, `StretchableWidgetContainerWdgt` (injects only the `_enable/_disableDragsDropsAndEditingNoSettle` cores; the public settle-wraps stay on the consumers/`ViewportWdgt`) | unrelated branches (Viewport / Panel / Widget) | yes |
| `WidgetCreatorAndSmartPlacerOnClickMixin` | 33 | 2 — `CreatorButtonWdgt`, `GlassBoxTopWdgt` | unrelated leaves | no |
| `ParentStainerMixin` | 11 | 2 — `CreatorButtonWdgt`, `EditorContentPropertyChangerButtonWdgt` | unrelated leaves | yes |

(The count excludes three that no longer exist as mixins: dead `ContainerMixin`, deleted;
the five misfiled ones, folded into standard-OO homes — §4; and `DeepCopierMixin`, inverted
into the `Duplicator` engine (`src/duplication/`) — §5-C. `Mixin.allMixines` is load-bearing
for the inspector.)

## 4. Which of these are GENUINE multiple inheritance

The test: consumers on unrelated branches AND behaviour that overrides framework hooks.

- **Genuine (the keep-core — all 8 current mixins):** `ControllerMixin` (the wire/dataflow client protocol across basic widgets and
  patch-programming — and the home the dataflow engine deliberately built on),
  `HighlightableMixin` (input-hook state machine across ≥4 branches),
  `BackBufferMixin` (paint-path override; load-bearing for the unified shadow mechanism
  — the blit at α is WHY a transparent text widget's shadow is its glyphs),
  `ClippingAtRectangularBoundsMixin` (overrides the geometry protocol — `fullBounds`,
  cache-invalidation super-chains; the `ClippingBoxWdgt` diamond: `BoxWdgt` painting +
  panel clipping), `BubblesEditModeToCoordinatorMixin` (the edit-mode-toggle cores
  bubbling to a coordinating parent, across Viewport/Panel/Widget branches),
  `KeepsRatioWhenInVerticalStackMixin`,
  `WidgetCreatorAndSmartPlacerOnClickMixin`, `ParentStainerMixin` (barely — 2 unrelated
  leaves each).
- **Misfiled (single consumer / single subtree / config bag) — all five now live in
  standard-OO homes**, motivated by inspectability (a mixed-in member's
  source is view-only in the inspector, and it is unclear whether to edit the donor or
  the receiver; a class member is fully first-class). Where each went:
  - `GridPositioningOfAddedShortcutsMixin` + `KeepIconicDesktopSystemLinksBackMixin`
    (both exactly {`FolderPanelWdgt`,`WorldWdgt`}) → the shared base
    `IconGridPanelWdgt extends PanelWdgt` (both consumers now extend it).
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
  algorithm plus per-class hooks. **Both halves of the old copy walker went this way**:
  serialization is the plain `Serializer`/`Deserializer` pair (`src/serialization/`), and
  duplication is the `Duplicator` engine
  (`src/duplication/Duplicator.coffee`): one instance per copy run owns the identity
  bookkeeping, the per-class hooks (`getEmptyObjectOfSameTypeAsThisOne`,
  `rebuildDerivedValue`, `keptByReferenceOnDeepCopy`, `_reactToBeingCopied`) stay on the
  classes, and the native-type detection both engines share lives in `NativeValueKinds`.
  Byte-identical: full gauntlet, zero recaptures — see
  `docs/architecture/serialization-duplication-reference.md`.

State migration (mixin fields like `@wires` serialize as widget own-props)
and by-name dispatch (menus invoke `openTargetSelector` on the widget) are the two
recurring conversion costs regardless of shape.

## 6. What practice actually shows

- The narrow rule (`god-class-decomposition-plan.md`, archived): delegation for what can be
  *delegated out*; mixins "remain available where a behaviour must be *injected into* the widget."
- **The delegation direction produces NEW collaborators, it does not dismantle mixins.**
  `MacroToolkit`, `Wallpaper`, `WidgetFactory`, `UntitledNamingService`,
  `Serializer`/`Deserializer` all arrived that way. The one fold of misfiled mixins (§4) went to
  *inheritance homes* — fold into consumer / shared base — not to delegation, which the §1
  policy reserves for liftable responsibilities.
- **New subsystems keep choosing mixins**: the spreadsheet (`SimpleSpreadsheetWdgt` → Clipping;
  `SheetModel`/`SheetCellRecord` → Duplicator), the frame model (`FrameWdgt` → Clipping),
  transforms (`TransformSpec` → Duplicator), the patch-programming base (`PatchNodeWdgt` →
  Controller). `ControllerMixin` is the cohesive home of the whole wire-client protocol
  (`_fireConnection`, `firesPerEvent`, the shared connect-menu block); shared menu code lives
  INSIDE it. `docs/plans/creation-and-templates-plan.md` builds `FactoryWdgt` on the `Duplicator`.
- The platform *invests in* mixins rather than removing them: inspector source recovery
  (Tier H5), the `SHADOWS-MIXIN` census, mixin-DSL awareness in `check-layering`, the hardened
  super-rewriter, and stainer mixins reduced to clean 2-line overrides.

Practice, tooling, and new subsystems all treat mixins as a permanent, first-class
mechanism with a narrow remit — which is the §1 policy.

## 7. The tradeoff ledger (why the position is "keep")

Costs of keeping (all real, all now bounded):
- the emulated `super` (weaker than the class form; `arguments.callee`; regex rewriter —
  one guarded silent-miscompile hazard; the class-side twin keeps most of this
  risk alive even in a mixin-free world);
- the mixin-DSL tax on every new static gate (paid for all current gates; the census
  class model now makes it reusable);
- implicit override semantics (mitigated: `SHADOWS-MIXIN` census + recorded case law);
- two unsynchronized mixin detectors (open, cheap to gate).

Costs of removing (why it loses):
- the four biggest genuine-MI mixins (Clipping/Controller/Highlightable/BackBuffer) need
  stub forests (≈100+ methods) or new `Widget`
  extension points on the paint/input/geometry hot paths — determinism-critical,
  behaviour-neutral churn of exactly the kind this project's case law banks rather than
  executes;
- both escape hatches violate standing doctrine (shrink `Widget`; capability methods on
  the answering subclass, never a base default);
- ~350 L of machinery deleted, and §3's whole line total merely relocated, net LOC likely UP;
- no active campaign is blocked by mixins (verified across all plan docs);
- the equilibrium is healthy on its own terms: delegate what delegates
  (serializer), inject what injects (dataflow client protocol), delete what's dead.

## 8. Proposed follow-ups (NOT scheduled; adopt via `BACKLOG.md` if picked up)

1. **Gate the detector pair**: assert `build.py`'s and the boot loader's mixin
   detectors classify every shipped file identically.

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

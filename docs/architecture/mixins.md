# Mixins — mechanism, inventory, and the keep-vs-remove position

> Verified against `src/` 2026-08-16. This doc is BOTH the evergreen reference for how the
> mixin mechanism works and the standing position on keeping vs. removing it, with the
> evidence embedded (self-contained per `docs/README.md`). The inventory table carries its
> own verification date; re-verify counts before relying on them in a future arc.

## 1. The standing position

> ⚠ **Under review.** The owner's direction is to remove the mechanism:
> `docs/plans/mixin-removal-plan.md` holds the plan and the evidence against this section's
> premises and §5/§7's arithmetic. §2 (how the mechanism works) stands until that plan executes.

**Keep the mechanism.** Mixins are the codebase's answer to a real gap — CoffeeScript is
single-inheritance, and a handful of behaviours must be *injected into* classes on
unrelated branches of the hierarchy, overriding framework hooks (`setColor`, `add`,
`pressBegan`, the paint/geometry protocol) — something a delegated collaborator
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
  whose most delicate part, the `super` rewrite, is the one every class goes through
  (`Class.rewriteSuperCalls`) and would stay regardless.

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
  so `Mixin._rewriteSuperCalls` (`src/meta/Mixin.coffee`) spells each `super` out as a call
  through `window[@[arguments.callee.name + '_class_injected_in']].__super__[...]`, resolved via
  a `<methodName>_class_injected_in` companion property that `addInstanceProperties`
  writes next to every injected function. The rewrite is the class side's own
  (`Class.rewriteSuperCalls`, `src/meta/Class.coffee`), handed that target: it reads which
  `super`s there are, and what call each makes, from CoffeeScript's lexer tokens, so a `super`
  inside a string or a comment is left alone and the form is the call the parser sees. Constraints
  that follow:
  - every super CALL is rewritten — `super()`, bare `super` (forwards all arguments),
    `super(args)`, `super arg, …`; a `super` an accessor or a soak continues (`super.x`,
    `super?()`) is left as written, and the compiler refuses it;
  - `arguments.callee` pins the compiled output to sloppy mode;
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
  `Mixin` instances register in `Mixin.allMixines` (`Mixin.register`, from the one boot step
  that ingests the page's sources, on both its paths: compiled to create, or parsed beside the
  code a pre-compiled image already runs; a Mixin made only to parse — the build-time syntax
  gate's, `Mixin.bootMemberSources` — never registers), and `Mixin.donorOf` consults a
  class's `augmentedWith` list for the mixin that defines a member, so the inspector
  shows a mixin member's REAL CoffeeScript source. A mixin's members are recorded from
  its literal's 6-space keys; one written at any other indentation would still be
  injected but recorded nowhere, and the boot reports it (`MIXIN_MEMBER_UNRECORDED`, a
  gate token: `Mixin._reportMembersWithoutSource` runs the literal's
  `onceAddedClassProperties` against a stand-in that collects the names it is handed).
  - **One store per meta-object, kept CURRENT.** A `Class` and a `Mixin` each keep the
    source of every instance member they define in `nonStaticPropertiesSources`: an
    edit writes it, a removal deletes it (`Class.applyMemberEdit` / `removeMember`,
    `Mixin.applyMemberEdit` / `removeMember`). A consumer's prototype holds its class's
    member where the class defines one, else the member of its LAST augmentation that
    defines it (`Mixin.donorOf` — two of a class's mixins can define the same member, as
    `HighlightableMixin` and `ParentStainerMixin` both define `_updateColor`), else
    nothing. Boot order made it so (`augmentWith` runs before the class-body
    assignments, and each `augmentWith` injects over the one before it), and ONE
    question keeps it so: a mixin edit or removal reaches a consumer only where that
    mixin is the consumer's donor and its class does not define the member
    (`Mixin._isTheDonorTo`), which covers the class body and every override born since;
    a removal hands each consumer what boot order gives it without the removed member
    (a class's: the donor's CURRENT member; a mixin's: the earlier donor's, else none),
    compiled before anything changes. A class made AFTER an edit of one of its mixins —
    a lazy part's, or one made at run time — was augmented from the mixin's literal,
    compiled at boot, so once its prototype is whole it takes, for each member a store
    of its mixins has away from boot, what that same rule gives it from the stores, where
    that differs from what the augmentation left (`Class._takeMixinMembersFromTheStores`,
    on the pass that creates it, all or nothing; the one store-vs-boot comparison is
    `Class.membersAwayFrom`). The live members are thereby a function of the stores, which
    is why replaying the recorded edits reproduces them (the reference doc §12).
    `parts-lazy-load-headless.js` (`LAZY_CONSUMER_TAKES_MIXIN_EDITS`) holds it for a lazy
    part on the dev `index.html` (the one page where a part loads after the boot), and
    `fg homepage`'s production smoke for a class made at run time on the pre-compiled tree. `<name>_source` means one thing only: a widget's own injected method's
    source (`Widget.injectProperty`); no class or mixin edit writes one onto a prototype.
  - Both live-edit twins compile through a bare global-assignment eval and write the
    result onto the prototype — nothing runs with a prototype as `this`, since code run
    against one stamps whatever fields it sets onto it as own properties, polluting every
    later member listing of the class. The mixin twin restores the recompiled function's
    `.name`, so the fake-super companion lookup keeps working.
  - **A meta-object or a meta-verb EDITS; the person's GESTURE TELLS and RECORDS.** This one
    rule holds for every live edit, of a class or of one widget:
    - The edit verbs tell no one and record nothing: `Class.applyMemberEdit` /
      `removeMember`, `Mixin.applyMemberEdit` / `removeMember`, and a widget's
      `injectProperty`, `addOwnProperty`, `renameOwnProperty`, `removeOwnProperty` and
      `evaluateString`. The product calls the widget verbs as plumbing too — a patch node
      compiles its formula with `evaluateString` on every recompute, a paint tool injects
      its handlers, a load re-injects each `{"$src"}` — where nothing a person did is there
      to show, and a gesture can be several edits (a rename is an edit plus a removal).
    - The class inspector's gestures record each edit (each step — one per scope ×
      operation: `_editClassMember`, `_removeClassMember`, `_editMixinMember`,
      `_removeMixinMember` — makes the meta-object's edit AND its
      `world.sourceEditsRegistry` record) and end in ONE `WorldWdgt.noteCodeChanged`, as a
      snapshot load does once it has returned the page to boot and replayed a file's class
      and mixin edits.
    - The object inspector's Save, Add, Rename and Remove end in their subject's ONE
      `Widget.sourceChanged`, and its Save of a function records the instance edit
      (`InspectorWdgt.applyPropertyEdit`). A text's run rows (a console's buttons and a
      script window's "Try it" run through them) end in their receiver's `sourceChanged`;
      a run edits state, not code, and records nothing.
  - **What a code edit refreshes.** `noteCodeChanged` is code changed under EVERY widget:
    every cache built by running code — the six text caches and the immutable back
    buffers, each keyed by CONTENT and never by the code that filled it — is dropped, and
    every live widget but the world, off-tree ones included, runs `Widget._codeChangedNoSettle` (its
    `_reLayoutSelf` heal, its layout invalidated, its style noted) in one settle. The whole
    world, because an edit's readers are not the edited class's instances: a menu row
    re-fits its label's measured lines, a stack reads its children's layout specs, and any
    widget may paint with a value class or an appearance. `sourceChanged` is that step on
    one widget plus its subtree's repaint. So what layout and paint DERIVE from code shows
    the edit on the next frame; what code already STORED — a colour a state change
    computed into a field — shows it only at its next trigger, exactly as in a fresh build:
    an edit changes code, not state. A widget holding code of its OWN adds a hash of that
    code to the keys of the shared caches that read it, keyed by what it shows — a text's back
    buffer, wrap and line breaks, a palette's back buffer (`Widget._ownCodeKeySuffix`, set by
    `sourceChanged`'s core and saved and copied as a plain field) — so it never shares an
    entry with a twin running other code, and a re-edit of its own code never meets the
    entries of the code it replaced. Pinned by `SystemTest_macroClassEditShowsOnTheNextFrame` (each edit's shot
    against a rebuild from scratch), `SystemTest_macroPaletteBufferKeyNamesItsOwnCode` (a
    palette's key) and `SystemTest_macroInspectorEditTellsOnce` (who is told, how often, and
    what is recorded).
  - Both refuse `constructor` (`Class.refuseTheConstructor`): a prototype's
    `constructor` IS its class, what every `.constructor.name` read answers.
  - The attribution covers methods AND fields: a donated method attributes through
    the function-branch chain walk (both inspector types), and a donated FIELD
    attributes in the CLASS inspector via `ClassInspectorWdgt._sourceForFieldMember` —
    prototype-level truth, shown in boot order of authority (the class's own current
    source, then the mixin donor's) — while an OBJECT inspector keeps showing the
    instance's VALUE (per-instance state is its own truth).

  The editing vocabulary on top of that core:
  - **Save** of a mixin-donated member edits the DONOR: `Mixin.applyMemberEdit`
    recompiles the member (the mixin super rewrite) and injects it into every consumer
    class recorded at `augmentWith` time that holds the member from it;
  - **"Override in this class"** (`ClassInspectorWdgt.overrideInThisClass`): a second
    save destination shown while a mixin-donated instance member (method or field) is
    selected — keeps the edited source as an override on THAT class only (via
    `Class.applyMemberEdit`, which writes the class's store), after which donor edits
    skip the class;
  - a **"from `<Name>Mixin`" donor label** (`InspectorWdgt.mixinDonorLabel`) appears in
    the breadcrumb band, right after the class chips, of BOTH inspector types while a mixin-donated
    member is selected;
  - **add/remove**: the class inspector's "Add…" popout gains a destination step
    (class or any of its mixins — an add is an edit to `"undefined"`, on either)
    when the class declares augmentations. "Remove" on a mixin-donated member
    routes to `Mixin.removeMember` (each consumer that held it from that mixin falls
    back to an earlier donor's member, else loses it with its fake-super companion);
    "Remove" on a class's own member is `Class.removeMember`, which gives back the
    donor mixin's CURRENT member when there is one (`Mixin.compiledCurrentMember`,
    `Mixin.injectInto`) — boot order, as if the class had never defined it;
  - **rename** is an edit under the new name plus a removal of the old, so the member
    is RECOMPILED and its `super` follows the new name; a donated member is renamed on
    its donor, for every consumer. A member with no recorded source has nothing to
    recompile, and its rename is refused with a message;
  - **what is offered**: "Rename…" and "Remove" are enabled, in both inspector types, only
    for a member the inspector's subject OWNS (a donated member is its consumer
    prototype's own) and never for `constructor`, whose code is shown read-only
    (`InspectorWdgt._selectedMemberCanBeRenamedOrRemoved`, asked by the actions too); and a
    member's companions — `<m>_class_injected_in`, an injected method's `<m>_source` —
    are not listed (`InspectorWdgt._isACompanion`): they follow their member through its
    edits;
  - **class-side statics are outside it**: the class inspector lists a class's
    PROTOTYPE members, and a static lives on the constructor, so no static — a class's
    or a mixin's — is edited. (An object inspector opened on a constructor itself, by
    double-clicking a `constructor` row, does list its statics, read-only: a constructor
    answers no edit protocol.) A mixin's class-side keys (the literal's 2-space ones,
    minus `MixedClassKeywords`) are copied onto each consumer constructor by
    `augmentWith` and their source is not parsed. ⚠ Editing a static would have to
    reach every SUBCLASS as well: `extend` gives each subclass its own copy of every
    static of its parent as the subclass is defined, so re-copying onto the declaring
    class (or a mixin's consumers) alone leaves the subclasses on the old value.
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
| `ClippingAtRectangularBoundsMixin` | 195 | 6 — `PanelWdgt` (base of the panel subtree), `ClippingBoxWdgt`, `VerticalStackPanelWdgt`, `FrameWdgt`, `SimpleSpreadsheetWdgt`, `InspectorWdgt` (clips its bands' overflowing controls, naked or windowed) | base class + unrelated branches | yes |
| `ControllerMixin` | 516 | 7 — `SliderWdgt`, `StringWdgt` (whence `TextWdgt`/`SimpleTextWdgt` inherit it — SimpleTextWdgt's own augment was the double-injection the boot guard now forbids), `PaletteWdgt`, `ColorPickerWdgt`, `FanoutWdgt`, `FanoutPinWdgt`, `PatchNodeWdgt` (base for 3 node classes) | 2 subsystems, ≥4 branches | yes — `graphEdgesOut` (super-composed, graph-edges §4.2) |
| `HighlightableMixin` | 54 | 6 — `ButtonWdgt`, `CreatorButtonWdgt`, `GlassBoxTopWdgt`, `DesktopLinkWdgt` (base of the 3-subclass desktop-link family: bin opener, shortcuts, app launchers), 2 icon-button classes | ≥4 branches | yes |
| `BackBufferMixin` | 162 | 3 — `CanvasWdgt`, `StringWdgt`, `PaletteWdgt` | unrelated branches | no |
| `KeepsRatioWhenInVerticalStackMixin` | 69 | 3 — `GraphsPlotsChartsWdgt`, `PlotWithAxesWdgt`, `IconWdgt`. Deliberate NON-consumers: `Example3DPlotWdgt` and `StretchableWidgetContainerWdgt` carry pinned-`@ratio` VARIANTS of this protocol (field-based, super-fallback) — see their in-file comments; do not "convert" them | unrelated leaves | no |
| `BubblesEditModeToCoordinatorMixin` | 51 | 3 — `VerticalStackViewportWdgt`, `StretchablePanelWdgt`, `StretchableWidgetContainerWdgt` (injects only the `_enable/_disableDragsDropsAndEditingNoSettle` cores; the public settle-wraps stay on the consumers/`ViewportWdgt`) | unrelated branches (Viewport / Panel / Widget) | yes |
| `WidgetCreatorAndSmartPlacerOnClickMixin` | 33 | 2 — `CreatorButtonWdgt`, `GlassBoxTopWdgt` | unrelated leaves | no |
| `ParentStainerMixin` |       28 | 4 — `CreatorButtonWdgt`, `EditorContentPropertyChangerButtonWdgt`, `GlassBoxTopWdgt` (a thumbnail's lid), `CodeInjectingSimpleRectangularButtonWdgt` (a paint tool): a toolbar tool tells the tool cell it stands in that its pointer state changed (`GlassBoxBottomWdgt.noteItemStateChanged`), and the cell derives its own look | unrelated leaves | no |

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
  `WidgetCreatorAndSmartPlacerOnClickMixin` (barely — 2 unrelated leaves), `ParentStainerMixin`
  (4 unrelated leaves: the toolbar tools).
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
  hand-written stub: `pressBegan: -> @highlighter.onMouseDown(); super`). Always
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

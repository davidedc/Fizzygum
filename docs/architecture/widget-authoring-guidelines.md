# Widget authoring guidelines — how to write a widget class

**What this is.** The house rules for writing a `*Wdgt` class: one section per decision a widget
author actually faces, each stating the rule, the reason, the sanctioned exception, and what enforces
it. It is the prescriptive companion to
[`widget-citizenship.md`](widget-citizenship.md) (what the system may *assume* of a widget) and to
[`../measurements/widget-practices-survey-2026-08-14.md`](../measurements/widget-practices-survey-2026-08-14.md)
(what the 270 existing widgets actually do, facet by facet, with counts).

**What this is NOT.** It is not the mechanics of the subsystems it points at. The settle engine, the
sizing model and the layout-spec family are [`layout.md`](layout.md); the `_`/`__` tier scheme and the
notification grid are [`layering-naming-convention.md`](layering-naming-convention.md); the paint
scope is [`appearance-paint-convention.md`](appearance-paint-convention.md); the graph engines are
[`serialization-duplication-reference.md`](serialization-duplication-reference.md); every gate named
below is described in [`lint-and-static-checks.md`](lint-and-static-checks.md). Read those for *how it
works*; read this for *what to write*.

**How to use it.** §17 is a checklist and §18 is a skeleton to copy. The sections in between are the
reasoning. A rule marked **[gated]** fails the build if broken; a rule marked **[convention]** is held
by nothing but this doc and review, so it is the one you have to remember.

---

## 1. First ask whether the class should exist

**Compose before you chisel.** A new capability starts as an arrangement of existing widgets —
a panel holding a text and two buttons, wired through pins — and becomes a class only for what
composition genuinely cannot express. Even then the class is *made of* existing pieces, and its parts
are designed to be reusable outside it ([`design-principles.md`](design-principles.md), "Composition
over chiselling").

Two questions settle most cases:

- **Could this be assembled by hand from existing widgets?** If yes, the class you want is probably a
  small builder (a `WidgetFactory` entry, a creator button, a template) rather than a new subclass.
- **Can it be taken apart again?** A widget that only works inside the assembly it was born in fails
  citizenship point 5. Its useful half belongs in its own class.

For a whole application rather than a widget, grade it first against
[`app-fit-criteria.md`](app-fit-criteria.md).

**Do not add to `Widget`.** The base carries 228 public methods and is the tree's one god class.
Behaviour that varies by type goes on the type that varies (§14); a shared default may land on a
*narrow family base* where one exists, never on `Widget`.

---

## 2. Naming and file shape

- **One class per file, filename identical to the class name.** [structural — `build.py` keys the
  `SourceVault` entry by the file's basename, so a mismatch ships source text under the wrong name]
- **New widget classes end in `Wdgt`.** [convention]
- **Reserve `Simple*` for the frame model's naked-capability tier** — data plus a self-mutation API,
  no chrome, embeddable anywhere ([`regularity-principles.md`](regularity-principles.md)). For "a
  basic variant of X", find a word that names the variant instead: the prefix already carries a
  meaning and a second one makes both unreadable. [convention]
- **Name for the role, not the mechanism.** `LayoutChromeWdgt`, `WidgetHolderWithCaptionWdgt` and
  `DragChargingRingWdgt` each say what the thing *is* in the world.
- **Reference other classes by bare identifier** (`extends X`, `@augmentWith X`, `new X`) so the boot
  dependency finder sees the edge. There is no import system; a class named any other way loads in the
  wrong order.

**Open the file with a header comment saying what the class is and, if it heads a family, what a
subclass supplies.** [convention] The best headers in the tree are instructions, not descriptions —
`IconButtonWdgt` lists the four members a subclass fills in; `ToolbarWdgt` explains why one
construction serves both the floating and the docked home. That is the standard to aim at.

---

## 3. Construction

### 3.1 Prefer an options object once the knobs outnumber the essentials

**[convention]** Positional parameters are right for a short, naturally ordered tuple that a *user*
might type — a spreadsheet cell accepts CoffeeScript, so `new SliderWdgt 0, 100, 30, 10` is a formula
someone writes. They are wrong for a bag of flags: a caller who wants only the last one has to count
holes, and two groups of callers wanting disjoint tails cannot be served by any single order.

The rule of thumb `SliderWdgt` sets, and the one to follow:

```coffee
# POSITIONAL for the ordered tuple that is the widget's identity;
# an OPTIONS object for everything else.
constructor: (@start = 1, @stop = 100, @value = 50, @size = 10, opts = {}) ->
  @color = opts.color ? Color.BLACK
  @smallestValueIsAtBottomEnd = opts.smallestValueIsAtBottomEnd ? false
  super()
```

The same shape is already the norm one level up in the API: `add aWdgt, position, layoutSpec,
beingDropped` funnels into `_addNoSettle aWdgt, opts`, and `addMenuItem label, target, action, opts`
serves 326 call sites with named knobs.

### 3.2 A `@param` overwrites the class-level default — take the parameter plainly and assign it guarded

**[convention, and the sharpest trap in the codebase]** `constructor: (@backgroundColor) ->` compiles
to an unconditional `this.backgroundColor = backgroundColor`, so constructing with no argument writes
`undefined` over a prototype default of `1` — with or without a default on the parameter. No later
"only when passed" guard can undo a field that has already been written, and the resulting `undefined`
can reach a canvas property, where HTML5 says to ignore an invalid value: a specified colour then
paints nothing, silently, with no error anywhere
([`../archive/dropped-background-fill-investigation.md`](../archive/dropped-background-fill-investigation.md)).

When a parameter's *absence* must mean "keep the class default", write:

```coffee
constructor: (backgroundColor) ->
  super()
  @backgroundColor = backgroundColor if backgroundColor?
```

Do not introduce a parallel shadow field (`iconToolTipMessage` → `@toolTipMessage`) to dodge a
parameter you control: fix the parameter.

### 3.3 Call `super` first unless something in the base needs a value

**[convention]** Two reasons justify work before `super()`: a field something on the base's own
construction path reads (`HandleWdgt` seeds a default `@inset` that its corner spec then consumes),
and option-object unpacking standing in for the parameters an all-positional signature would have
bound at the same moment (`SliderWdgt`'s `opts.color` / `opts.smallestValueIsAtBottomEnd`). Everything
else — appearance, colours, sizing, registrations, child building — goes after.

⚠ CoffeeScript binds a *subclass's* constructor parameters only **after** `super()`. A base
constructor that calls a virtual method therefore sees the subclass's parameters unbound — which is
why `ScrollPanelWdgt` builds through a distinctly-named `_buildScrollFrame`, `MenuRowsPanelWdgt`
through `_buildMenuLabel`, and `PromptWdgt` leaves `@_buildAndConnectChildren()` to each subclass's
own constructor.

### 3.4 Build children in `_buildAndConnectChildrenNoSettle`, reached through the canonical wrapper

**[gated — `check-constructors-build.js`]** A constructor must not `@add` / `@_addNoSettle` /
`@__add` its own children inline. Write exactly this pair:

```coffee
constructor: ->
  super()
  @_buildAndConnectChildren()

# build via the NoSettle core, settle ONCE at the end
# (orphan-settledness: `new X()` returns settled).
_buildAndConnectChildren: ->
  @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

_buildAndConnectChildrenNoSettle: ->
  @thing = new ThingWdgt
  @_addNoSettle @thing
```

The wrapper's one-line body is not decoration: the settle tier **flushes** a top-level `new X()` and
**auto-defers** one constructed inside another mutation's flush, so the same code is correct in both
contexts. Use the canonical names — an ad-hoc alias hides the child-building from the gate. Give a
distinct name only for the `super()`-dispatch reason in §3.3, and say so in a comment.

### 3.5 `new X()` returns a settled widget

**[convention, backed by the settle tiers]** A constructor's last act leaves nothing pending. If the
class sizes itself to a design extent, that write is the final statement and goes through the
**public** setter so the settle actually happens:

```coffee
  # settled-after-new: SETTLE the default extent as the constructor's last act.
  @setExtent new Point 300, 300
```

Keep such a default *out* of the shared build core when that core is also reached by a rebuild path —
a rebuild must not reset a user-resized widget.

### 3.6 Choosing the geometry verb inside a constructor

**[convention]** Three are legitimate, and the choice follows what the widget has at that moment:

| verb | use when |
|---|---|
| `@__commitExtent` | the widget has no content to re-lay and nothing to repaint (it is not attached yet) — a plain design size |
| `@_applyExtent` | the write must re-lay the widget's own content or mark it changed |
| `@setExtent` | it is the constructor's final act and the widget must return settled (§3.5) |

Prefer the quietest verb that is correct: a leaf commit in a constructor is cheaper and cannot
re-enter anything.

---

## 4. State and fields

### 4.1 Declare every instance field at class level

**[convention, load-bearing for three engines]** The duplicator walks **own enumerable properties**
and restores into `Object.create(prototype)`; serialization drives off name strings; the inspector
lists what it can see. A field that only ever appears as `@foo = …` inside a lazily-run method is
invisible to all three until that method has run.

```coffee
class ColorPickerWdgt extends Widget

  # pattern: declare every child field here (not only set in the constructor) so
  # the Duplicator's walk picks it up even under lazy initialisation.
  feedback: undefined
  choice: undefined
  colorPalette: undefined
  grayPalette: undefined
```

This applies to constructor `@param` fields too. Adding a property to a class whose instances a
SystemTest inspects shifts that test's member list, which is a benign recapture — budget it, do not
skip the declaration for it.

### 4.2 Declare what must not be serialized, and how it comes back

**[convention; caught only by the production snapshot round-trip]** Anything derived — a compiled
function, a canvas context, a back-reference, a per-frame cache — goes in `@serializationTransients`,
and the class recomputes it. Post-restore and post-duplicate fixups have named hooks:
`_reactToBeingCopied` (duplication) and `_afterDeserialization` (restore). The constructor is
**never** re-run on a clone or a restored shell.

An undeclared derived field is not a warning — it makes every snapshot containing the widget fail to
save.

### 4.3 A mode is a field, not an installed function

**[convention]** Never install own function properties on an instance to record a mode (`@mouseDownLeft
= -> …` inside an `enable*` call). A mode a widget can be in is a serializable **field** consumed by
prototype methods. `injectProperty` remains the sanctioned path for user-authored instance methods —
it stores the `<name>_source` sibling that serializes.

---

## 5. Appearance

**Painting lives in a pluggable `*Appearance`; the widget keeps identity.** [convention] Put the
*choice* of appearance in an overridable factory method, and let the constructor assign its result:

```coffee
  constructor: ->
    super()
    @appearance = @createAppearance()

  # a method, not a class field, so the build's dependency-finder still sees the
  # `new <X>Appearance` edge and orders the appearance before the widget.
  createAppearance: -> new FooAppearance @
```

Three payoffs. The dependency edge stays visible to the boot loader. A subclass reskins by overriding
one line — 67 icon classes are nothing but `colloquialName` + `createAppearance`, and the base
constructor needs no knowledge of them. And a widget that legitimately swaps skins at runtime — a
frame flipping rectangular/boxy by parentage, an edit button flipping pencil/eye by mode — does so
without changing class.

Naming a `*Appearance` class directly in the constructor (`@appearance = new FooAppearance @`) is the
older shape and still correct for a leaf that nothing subclasses; it simply forecloses the override
point, so prefer the factory whenever the class might head a family.

Inside the appearance, paint the widget's own pixels in widget-local **logical** coordinates through
the ctx matrix, inside `Appearance._paintInLocalScope`. Device-space business belongs to the preamble
([`appearance-paint-convention.md`](appearance-paint-convention.md)).

**Hit-testing follows the shape.** If the widget's silhouette is the appearance's business, implement
`isTransparentAt` on the appearance; implement it on the widget only when the answer depends on widget
state the appearance does not hold.

---

## 6. Layout

Read [`layout.md`](layout.md) before overriding anything here. The rules a widget author needs:

### 6.1 Define `_reLayoutChildren` if — and only if — you track your content's size

**[convention, and the engine's marker]** `_reLayoutChildren` is the chokepoint that says *"I am a
size-tracking container"*. The settle engine's re-fit machinery is a no-op on a widget without it, and
a stack arrange sizes such a widget through `_setWidthSizeHeightAccordingly` and expects the innards
to follow in the same write. Put the child arrange *there*, and let `_reLayout` compose it:

```coffee
_reLayoutChildren: ->
  @thing._applyBounds @position().add(new Point 5, 2), new Point 300, 18

_reLayout: (newBoundsForThisLayout) ->
  super
  @_reLayoutChildren()
```

### 6.2 Apply your own bounds before reading your own geometry

**[gated — `check-relayout-bounds-first.js`]** A `_reLayout` override that places children must commit
its own frame first; positioning from a frame the trailing `super` has not applied yet lags the
children one cadence. The prologue for a non-container override:

```coffee
_reLayout: (newBoundsForThisLayout) ->
  newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout
  if @_handleCollapsedStateShouldWeReturn() then return
  @_applyGrantedBounds newBoundsForThisLayout      # my frame FIRST
  @_layOutMyContents()                             # ← the only part that varies
  super
  @_markLayoutAsFixed()
```

Everything except the middle line is boilerplate. If your class heads a family, factor the middle into
a named hook, as `PatchNodeWdgt._layOutNodeContents` does, and let subclasses fill that in rather than
recopying the prologue.

The container shape in §6.1 satisfies the same rule the other way round: `super` applies the frame
before `@_reLayoutChildren()` reads it. Use that shape whenever it fits — it is shorter and there is
nothing to keep in step with the base.

### 6.3 Measure purely; never read applied geometry back to decide a size

**[convention]** No accessor reports where geometry is heading — `width()`, `bounds` and friends read
the *applied* box. A widget whose height depends on its width implements the side-effect-free
`preferredExtentForWidth(availW) -> Point`, and a container that must size a child then know its
height takes the value **handed forward** by `_setWidthSizeHeightAccordingly` rather than reading it
off the child.

### 6.4 State your layout preferences in the spec initialisers

**[convention]** Per-class layout wishes belong in `initialiseDefaultFrameContentLayoutSpec` /
`initialiseDefaultVerticalStackLayoutSpec`, not in ad-hoc resize code. A size-stable window content
declares `grow = 0` and `canSetHeightFreely = false` there (the clock, `IconWdgt`); a filling one
leaves `grow` at 1.

### 6.5 Place and size in integer pixels

**[gated — `Widget._assertBoundsWellFormed`, wired into the headless fail-gate]** Round at every
producer that computes a fractional target. Fractional *desired* geometry is kept on the side;
internal *content* rendering (vector icons, charts) is legitimately fractional. Under a transform
island, the `screen*` family is derived and may be fractional — the layout-box family stays
plane-local and integer ([`integer-pixel-placement-and-sizing.md`](integer-pixel-placement-and-sizing.md),
[`transforms.md`](transforms.md)).

---

## 7. Method naming and the settle tiers

**[gated — `check-layering.js` [A]–[T], `check-thin-wraps.js`, `check-call-separation.js`]** The
prefix *is* the contract ([`layering-naming-convention.md`](layering-naming-convention.md)):

- **`name`** — public, user-meaningful, self-settling. No `full`/`raw`/`silent` in the name.
- **`_name`** — internal orchestrator; may schedule or settle.
- **`__name`** — leaf primitive: triggers no orchestration at all.

Three habits keep a new widget on the right side of all of it:

1. **A public mutator that needs a settle is a one-line wrap over its own core.** Guards go *inside*
   the core, not before the settle.
   ```coffee
   foo: -> @_settleLayoutsAfter => @_fooNoSettle args
   ```
2. **Anything running inside a layout pass, a constructor, a notification callback or a teardown chain
   calls cores** (`@_addNoSettle`, `@_setTextNoSettle`, `@_fullDestroyNoSettle`), never public
   setters. A public call from there re-enters the flush guard and throws.
3. **A notification hook is settle-neutral.** `_reactTo…` / `_before…` never open a settle — the
   dispatcher owns the one settle — and their names follow
   `_(reactTo|before)(Being|Child|HolderFrame)<Event>` exactly.

Do not open a public method that only you call: a method reached only by `@`-self calls belongs on the
`_` tier.

---

## 8. Invalidation

**[gated — `check-invalidation-receivers.js`]** A widget invalidates **only itself**. `_changed()` and
`_fullChanged()` are private and there is deliberately no general-purpose public repaint verb.

If A's action affects B, then **B marks itself changed inside the method A invoked on it** — which
means the method needs an intent-revealing public name on B (`world.noteWallpaperChanged()`,
`world.caret.noteTextChanged()`). The singletons are not exempt.

Reach for `@_changed()` (self only) by default; `@_fullChanged()` (self + subtree) is the expensive
answer and the tree uses it five times less often. When a sequence of writes would otherwise emit a
storm of marks, wrap it in `@_repaintAsOneUnit => …`, which restores the suppression depth and fires
the covering repaint in a `finally`.

One redundancy worth knowing, so you do not add dead weight: broken rects are fleshed out at the
end-of-cycle flush from the *recorded* paint-time bounds and the *current* bounds, so a single
`_fullChanged()` anywhere in the cycle already covers every same-cycle geometry mutation. A trailing
mark after `add` + `setExtent` adds nothing.

---

## 9. Input

- **Consume the `pos` parameter the dispatcher hands you.** [gated —
  `check-raw-pointer-reads.js`] It is already mapped into your plane. Reading
  `world.hand.position()` inside a handler is correct off an island and wrong the moment the widget is
  tilted — a bug class that is invisible until someone rotates something.
- **Escalate what is not yours.** `@escalateEvent "mouseDownLeft", pos` passes the event to the parent
  rather than swallowing it. A handler that conditionally acts should escalate on the other branch.
- **Get hover/press feedback from `HighlightableMixin`** (`color_normal` / `color_hover` /
  `color_pressed`) instead of colouring by hand in `mouseEnter`/`mouseLeave`.
- **Chrome opts out of editor focus.** A widget that is manipulation chrome rather than content —
  handles, frame-bar buttons, toolbars, creator buttons — answers
  `excludedFromEditorFocusTracking: -> true`, so clicking it neither steals the editor-focus pointer
  nor draws the selection overlay around the chrome.
- **No wall-clock, no timers, no randomness** in render/layout/input code: the suite asserts byte-exact
  pixels and those diverge under parallel load. The cycle and step machinery are the sanctioned clock
  (`../../Fizzygum-tests/DETERMINISM.md`).

---

## 10. Menus and self-description

- **Add your entries in `addWidgetSpecificMenuEntries`, and call `super` first.** [convention]
  Dropping `super` silently removes the base's layout-editing entries from your widget.
- **`addMenuItem label, target, action, opts`** — `action` is a **string method name on `target`**.
  A function closure fails obscurely (`@target[<function>]` coerces to an undefined key) and
  `ButtonWdgt.trigger` throws on it in any build carrying the harness. The fourth slot is the options
  object (`toolTip:`, `arg1:`, `representsAWidget:`, …), never a bare tooltip string.
- **`@prompt msg, target, "methodName", defaultContents, width, floorNum, ceilingNum, isRounded`** —
  pass the target and the method *name*, not a bound method value.
- **Define `colloquialName`.** [convention] It is what the product shows: window titles, inspector and
  console titles, the drag-embed hint, the shortcut auto-namer. A widget without one is labelled
  *"generic widget"* to the user.
- **Define `representativeIcon`** when the widget can be referenced from the desktop — a shortcut needs
  a picture.
- **Set `toolTipMessage`** for anything whose purpose is not obvious from its face.

---

## 11. Pins and wiring

**Prefer connector endpoints over bespoke callbacks.** [convention] Only pins are discoverable,
rewireable and serializable by the generic machinery, and a wire *is* a dataflow edge
([`../specs/dataflow-engine-spec.md`](../specs/dataflow-engine-spec.md)).

**To be driven by others**, list the properties in `numericalSetters` / `stringSetters` /
`colorSetters`, always appending to `super`'s lists:

```coffee
numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
  [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
  @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings,
    ["value", "start"], ["setValue", "setStart"]
```

**To drive others**, `@augmentWith ControllerMixin`, keep `@target`/`@action`, fire through
`@_fireConnection value`, and append the shared connect block with
`@_addTargetConnectionMenuEntries menu, "numerical"`.

### The pin-setter contract

A pin setter is reached along two paths that put the value in **different argument slots**: a wire
delivers the raw value in slot 1 (`consumer[action] value`), while a menu, prompt or button delivers
the value-giving *widget* in slot 2 (`@target[@action].call @target, dataSource, widgetEnv, …`). A
setter that handles only one of them works only from one half of the system. Write both, plus the
guard and the return:

```coffee
setFoo: (fooOrWidgetGivingFoo, widgetGivingFoo) ->
  foo = widgetGivingFoo?.getValue?() ? fooOrWidgetGivingFoo?.getValue?() ? fooOrWidgetGivingFoo
  foo = parseFloat foo  unless typeof foo is "number"
  return  if isNaN foo
  foo = Math.min Math.max(foo, @fooFloor), @fooCeiling      # clamp to the property's own range
  return @foo  if @foo is foo                               # idempotence: a wired circuit must settle
  @foo = foo
  @_changed()
  return foo
```

The **idempotence guard is not an optimisation** — it is what stops a wired circuit from re-firing on
an unchanged value. The **return** is what lets a caller chain off the coerced result.

**Export a value** if the widget is meaningful as a spreadsheet cell's content: `getValue` (or
`dataflowValue` for a computed one) joins it to the value protocol.

---

## 12. Stepping

**Subscribe yourself to `world.steppingWdgts` and implement `step`; never own a timer.**
[convention] Stepping survives duplication and serialization with the widget
(`alignCopiedWidgetToSteppingStructures` carries membership; `Widget._destroyNoSettle` drops it), which
a `setTimeout` does not.

Set `@fps` to the slowest rate that looks right, and `@synchronisedStepping = true` when the tick
should align to wall-clock boundaries rather than to construction time (a clock's second hand).

**Prefer demand-driven subscription** — join when there is something to animate, leave when there is
not, as `DataflowSource`, `ScrollPanelWdgt`'s momentum and `SimpleImageWdgt` do. A permanent
constructor-time subscription is acceptable for a widget that genuinely always animates, and costs a
slot in the once-per-cycle walk otherwise.

---

## 13. Lifecycle and teardown

**Override the `_destroyNoSettle` core, not the public `destroy` wrapper.** [convention] Bulk teardown
(`fullDestroyChildren`, `closeChildren`, `_fullDestroyNoSettle`) recurses **cores**, so cleanup hung on
the public wrapper is skipped exactly when a whole subtree goes away — the case that matters most.

What a widget cleans up itself: anything it put in a world-level registry that the base does not know
about (a reference tracker, an open-pop-up set, an app slot). What it does not: `steppingWdgts`,
`keyboardEventsReceivers`, `wdgtsDetectingClickOutsideMeOrAnyOfMeChildren` and its dataflow edges —
`Widget._destroyNoSettle` already drops all of those.

---

## 14. Type tests

**A type test that drives a branch is missed polymorphism.** [ratcheted — the
`instanceof-type-test` stink] Ranked best to worst; take the highest that fits, faithfully:

1. **Move the behaviour, so the branch disappears.** Acting on another object: replace
   `if x instanceof Foo then x.bar()` with an unconditional `x.bar?()`. Branching on self: have the
   base call `@hook?()` and implement `hook` on the subclass.
2. **A capability query named for the CAPABILITY, not the class.** `isLayoutInert`,
   `attachesToScrollFrameDirectly`, `sliderTrackPressJumpsButton`, `hostsContentStackDropSlots`.
   Never `isScrollPanel` — a type-named predicate is only cosmetically better than the type test.
3. **Singleton identity** — `@parent == world`, `m != world.caret` — for "is it *the* unique X".
4. **Leave it**, with a comment saying why, when there is genuinely no behaviour to move.

**Placement:** the query lives on the **answering subclass** and is dispatched with `x.method?()`.
Do not add a `-> false` default on `Widget`.

**Faithfulness:** a conversion must fire for exactly the original test's object set — mind
inheritance. Any red test after such a swap is a faithfulness bug, not a rendering change.

---

## 15. Colours and preferences

**[convention]** Take a colour from `WorldWdgt.preferencesAndSettings` when it is a *system* colour
(menu background, icon line colour, outline, button label) — that object is the per-world theming
surface. Use an interned `Color.*` constant for a true primitive. Reserve `Color.create r, g, b` for a
colour that genuinely belongs to this one widget, and never write a `'#RRGGBB'` string where a `Color`
belongs.

Value classes are **immutable**: never write a field of a `Point` / `Rectangle` / `Color` /
`ShadowInfo` / `TransformSpec` after construction — operations return new instances, `this`, or a
canonical constant ([`immutable-value-classes.md`](immutable-value-classes.md)).

---

## 16. Inheritance, mixins, collaborators

**[policy — [`mixins.md`](mixins.md)]** Pick by direction:

| you need | use |
|---|---|
| behaviour **injected into** classes on unrelated branches, overriding framework hooks | a **mixin** (`@augmentWith FooMixin, @name` — the trailing `@name` is cosmetic, since `Class.coffee` re-emits the call with the consumer class name either way; write it for the majority form) |
| a cohesive responsibility that can be **delegated out** | a plain **collaborator** class (`world.macroToolkit`, `Wallpaper`, `WidgetFactory`) |
| a specialization of one family | a **subclass** |

No new mixin for a liftable responsibility, and no mixin with a single consumer or a single subtree —
that folds into the consumer or a shared base.

**A base class in another part** is reachable only under a `requires` edge; a lazily-loaded class is
reachable only by awaiting it. Ask the right question of `world.parts`:
`isAvailable` for "did this build ship it" (menu-item visibility), `whenAllLoaded` when the part
*constitutes* the result, `whenOptionalPartsLoaded` when it merely *enriches* it. `if SomeClass?` is
right for inclusion and wrong for laziness — it silently swallows the user's click
([`build-and-packaging.md`](build-and-packaging.md)).

---

## 17. Checklist for a new widget

**Identity**
- [ ] `Foo Wdgt` name; file named for the class; header comment saying what it is
- [ ] `colloquialName`; `representativeIcon` if it can be referenced; `toolTipMessage` if its face is not self-explanatory

**Construction**
- [ ] Essentials positional, knobs in `opts`
- [ ] No `@param` shadowing a class-level default — guarded assignment instead
- [ ] `super` first, unless §3.3 applies
- [ ] Children built in `_buildAndConnectChildrenNoSettle` via the canonical wrapper
- [ ] `new Foo()` returns settled

**State**
- [ ] Every instance field declared at class level
- [ ] Derived state in `@serializationTransients`, rebuilt in `_afterDeserialization` / `_reactToBeingCopied`
- [ ] No installed function properties as mode

**Presentation**
- [ ] `createAppearance` factory; paint in local logical coordinates
- [ ] Integer placement and sizing
- [ ] Self-invalidation only; `_changed` before `_fullChanged`; `_repaintAsOneUnit` around a burst

**Layout**
- [ ] `_reLayoutChildren` if and only if it tracks its content's size
- [ ] `_reLayout` applies own bounds before reading own geometry
- [ ] `preferredExtentForWidth` if height depends on width
- [ ] Layout wishes in the spec initialisers

**Behaviour**
- [ ] Public mutators are thin wraps over `*NoSettle` cores; callbacks stay settle-neutral
- [ ] Handlers use the `pos` parameter and escalate what is not theirs
- [ ] `addWidgetSpecificMenuEntries` calls `super`; menu actions are string method names
- [ ] Pins declared; setters honour both argument paths, guard on equality, return the value
- [ ] Stepping via `world.steppingWdgts`, at the slowest workable `fps`
- [ ] Cleanup in `_destroyNoSettle`

**Citizenship** ([`widget-citizenship.md`](widget-citizenship.md))
- [ ] Duplicating it yields an independent working copy
- [ ] It can be taken apart and its parts reused elsewhere
- [ ] Its editing chrome is a separate citizen, not baked in

**Verify**
- [ ] `./build_it_please.sh` — every gate green
- [ ] `./build_and_test.sh` — the SystemTest suite; recapture only what the change genuinely moves

---

## 18. Skeleton

```coffee
# A FooWdgt shows a bar whose length tracks a level, and drives any numerical pin
# of a chosen target. A subclass supplies createAppearance (its skin).

class FooWdgt extends Widget

  @augmentWith ControllerMixin, @name

  # every instance field declared here, so the Duplicator, the serializer and the
  # inspector see it even before the lazy initialisation that fills it in --
  # and so these class-body values are the real defaults
  target: undefined
  action: undefined
  level: 0
  caption: "foo"
  bar: undefined

  # POSITIONAL for the identity tuple, an OPTIONS object for the knobs. Both are
  # taken PLAIN and assigned guarded: a `@level` parameter would overwrite the
  # class-body default above with `undefined` whenever it is omitted (§3.2).
  constructor: (level, opts = {}) ->
    super()
    @level   = level          if level?
    @caption = opts.caption   if opts.caption?
    @appearance = @createAppearance()
    @__commitExtent new Point 120, 24        # quiet design size; nothing to re-lay yet
    @_buildAndConnectChildren()

  createAppearance: -> new FooAppearance @

  colloquialName: -> "foo"

  # build via the NoSettle core, settle ONCE at the end
  # (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @bar = new RectangleWdgt new Point(10, 10), Color.BLACK
    @_addNoSettle @bar

  # I track my content's size, so I own this chokepoint; the engine drives it.
  _reLayoutChildren: ->
    return unless @bar?
    @bar._applyBounds @position().add(new Point 2, 2), new Point (@width() - 4), (@height() - 4)

  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()

  # pure measure: no mutation, no read-back
  preferredExtentForWidth: (availW) ->
    new Point availW, 24

  # ---- pins ----------------------------------------------------------------

  getValue: -> @level

  setLevel: (levelOrWidgetGivingLevel, widgetGivingLevel) ->
    level = widgetGivingLevel?.getValue?() ? levelOrWidgetGivingLevel?.getValue?() ? levelOrWidgetGivingLevel
    level = parseFloat level  unless typeof level is "number"
    return  if isNaN level
    return @level  if @level is level
    @level = level
    @updateTarget()
    @_changed()
    return level

  updateTarget: ->
    @_fireConnection @level
    return

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, ["level"], ["setLevel"]

  # ---- input + menu --------------------------------------------------------

  mouseClickLeft: (pos) ->
    if @bar.boundsContainPoint pos
      @setLevel @level + 1
    else
      @escalateEvent "mouseClickLeft", pos

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "reset", @, "resetLevel", toolTip: "set the level\nback to zero"
    @_addTargetConnectionMenuEntries menu, "numerical"

  resetLevel: ->
    @setLevel 0
```

---

## 19. Deviating on purpose

Every rule above has cases it does not fit, and the codebase is full of good deviations. What
separates a deviation from a scar is that the deviation **says why, in the code, where the next reader
will be**: `SliderWdgt` argues its mixed constructor shape, `FrameWdgt` argues its trailing public
`setExtent`, `ScrollPanelWdgt` argues its differently-named builder, `PanelWdgt` argues the one place
that tests a class. A gated rule additionally has a marker for this
(`# layout-apply-sanctioned:`, `# nosettle-sanctioned:`, `# cross-invalidation-sanctioned:`,
`# constructor-build-exempt:`, …) — each takes a reason, and the reason is the point.

Two things a deviation may not do: state history instead of the surviving constraint (a comment says
what *is*), and quietly widen a gate's exemption count without a line in the plan or backlog that owns
the debt.

---

## See also

- [`widget-citizenship.md`](widget-citizenship.md) — the contract; [`design-principles.md`](design-principles.md) — why the contract is shaped this way; [`app-fit-criteria.md`](app-fit-criteria.md) — whether an idea belongs here at all.
- [`regularity-principles.md`](regularity-principles.md) — separate the fused axes; the name encodes the role.
- [`layering-naming-convention.md`](layering-naming-convention.md) · [`layout.md`](layout.md) · [`transforms.md`](transforms.md) · [`appearance-paint-convention.md`](appearance-paint-convention.md) · [`integer-pixel-placement-and-sizing.md`](integer-pixel-placement-and-sizing.md) — the mechanics.
- [`serialization-duplication-reference.md`](serialization-duplication-reference.md) · [`immutable-value-classes.md`](immutable-value-classes.md) · [`mixins.md`](mixins.md) · [`build-and-packaging.md`](build-and-packaging.md).
- [`lint-and-static-checks.md`](lint-and-static-checks.md) — every gate cited above.
- [`../measurements/widget-practices-survey-2026-08-14.md`](../measurements/widget-practices-survey-2026-08-14.md) — how the existing 270 widgets score against these rules.

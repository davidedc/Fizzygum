# Constructor and parameter conventions — the positional head and the options tail

**The law, once.** A parameter list fuses two different things: what the object **IS** (the
irreducible operands, without which the call is meaningless) and how it is **CONFIGURED**
(independently-optional knobs that all have sensible defaults). Separate them. The identity
operands stay **positional**; the configuration rides a single trailing **options object**.

```coffee
constructor: (@start = 1, @stop = 100, @value = 50, @size = 10, opts = {}) ->
  @color = opts.color ? Color.BLACK
  @smallestValueIsAtBottomEnd = opts.smallestValueIsAtBottomEnd ? false
```

That is `SliderWdgt` (`src/basic-widgets/SliderWdgt.coffee:50`), the reference exemplar. The
four numbers are a natural ordered tuple *and* a user-facing spelling; the two trailing knobs
are flags that were previously reachable only by punching holes through the numbers.

This is the [regularity law](regularity-principles.md) applied to argument lists — separate the
fused axes, and let the *calling convention* encode which axis a parameter serves. A reader at
a call site can tell identity from configuration without opening the callee.

**Scope.** This governs *every* class, not only widgets — value classes, input events and spec
objects are all covered, and §3 is mostly about them. The widget-author's short form of the
same rule is §3.1 of
[`widget-authoring-guidelines.md`](widget-authoring-guidelines.md), which points here; that doc
also owns the surrounding construction rules (the `_buildAndConnectChildren` pair, settle-once,
the geometry verb to use in a constructor) that this one deliberately does not repeat.

---

## 1. Why not one object for everything

A pure keyword-argument style (everything named, Smalltalk-like) reads beautifully and is
tempting. It is rejected as the universal rule for three reasons, in descending order of force:

1. **It is wrong for tuples.** `new Point x: 3, y: 4` is worse than `new Point 3, 4`, not
   better. Where the operands have a canonical, memorable order, naming them is noise that
   makes the common case longer without making it clearer.
2. **It would break user-facing spellings.** A spreadsheet cell accepts typed CoffeeScript
   (`FormulaCompiler`), so `new SliderWdgt 0, 100, 30, 10` is a *formula a user types*, and the
   documented idiom in `src/macros/MACRO-PATTERNS.md`. These spellings are a published surface.
3. **It allocates.** Every call mints a second short-lived object. Irrelevant next to what a
   widget constructor already does (it allocates the widget, its appearance, usually children);
   **not** irrelevant for value classes minted per-frame — `new Point` alone has **~960** call
   sites in `src/`.

So the shape is a hybrid, and §3 draws the boundary conservatively: where the allocation
argument has any force at all, the class is exempt outright.

## 2. The rules

### R1 — The positional head is the required, ordered operands. Cap: 4.

A positional parameter must pass **all** of these:

- the **typical** caller passes it (not just an unusual one);
- it has a **canonical position** in an order a reader can predict (a tuple, or an
  established convention like `addMenuItem`'s `label, target, action`);
- it is **not** a bare `true`/`false` at most call sites.

Four is the hard cap, and four is already generous — 137 of the 144 constructors in `src/`
take four or fewer. If a fifth operand is genuinely required and genuinely ordered, that is a
strong hint the class is doing two jobs; look there before widening the head.

### R2 — The options tail carries everything else.

One trailing parameter, spelled `opts = {}`, read guarded:

```coffee
@ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = opts.closesUnpinnedPopUps ? true
@title = opts.title
```

`?` (not `||`, not `?=`) so an explicit `undefined` — and a stray `null` from a foreign
caller — both read as absence, and so `false` and `0` survive as real values.

### R3 — The hole test. This is the decisive rule.

> **If any call site must pass `undefined` to reach a later argument, the parameter list is
> wrong.**

A hole is not a style blemish; it is *proof* that the skipped parameter is configuration
rather than identity, and that no single order can serve every caller. `SliderWdgt` is the
worked case: 6 sites wanted only the trailing flag, 2 only the colour — **disjoint** tails, so
no reordering could ever have fixed it. That is the signature of a parameter that belongs in
the options object.

⚠⚠ **Not every `undefined` argument is a hole — some are the VALUE.** A parameter whose absence
*means* something ("no shadow", "leave the rotation unchanged") is an operand like any other, and
writing `undefined` for it is supplying it, not skipping it. ⚠ But that meaning is NOT the test —
the second and third rows below are parameters whose absence is genuinely meaningful *and* holes all
the same. What separates them is the callers:

> **A `undefined` is a hole iff some OTHER call site of the same callee OMITS that position's
> trailing tail** — i.e. this caller writes `undefined` only because the list gives it no shorter
> way to reach a later argument.

The build applies this mechanically (§5): a call with an `undefined` before a present argument is a
hole iff another call of the same callee REACHES LESS FAR — passes fewer arguments, a trailing
`undefined` written out counting as omitted, since it means exactly what omitting it means — and the
gate prints that other call, the WITNESS, beside it.

Three worked cases:

| site | verdict | why |
|---|---|---|
| `Appearance._paintInLocalScope aContext, clip, undefined, bodyFn` | **value** | every caller passes all 4 arguments — `bodyFn` is a required trailing block, so there is no shorter form to punch past. The `undefined` is an `appliedShadow` that is genuinely absent |
| `_applyTransformSugarNoSettle undefined, s` | **HOLE**, though it reads like a value | a two-slot partial update whose two callers each want the OTHER slot (`deg, undefined` and `undefined, s`). "No order removes it" is precisely the SliderWdgt signature above — disjoint tails — so the slots are options: `_applyTransformSugarNoSettle rotation: deg` / `scale: s` |
| `_insertAddersSuchThat scan, insert, undefined, isMember` | **HOLE** | the other caller stops at arity 3, omitting `isMember` — so this one is filling a slot purely to reach past it. Two callers, disjoint tails, textbook |

The distinction matters in both directions: converting a value costs a real signature and buys
nothing, and dismissing a hole as "well, `undefined` is meaningful there" is how a tail survives a
sweep. Read the *other* call sites, not the parameter's documentation.

⚠ **The remedy is not always an options object.** For a class that is otherwise exempt (§3), a
hole means *reorder* — move the commonly-passed operand up. `TransformSpec` is the worked case:
an immutable value class (E1), so it stays positional however long the list gets, and five sites
were writing `new TransformSpec relDeg, 1 / sPlane, undefined, "slot"` to skip `anchor`. The
diagnosis was that `anchor` is **never** supplied at construction — every anchor arrives later
through `withAnchor` — while `claimsSpace` regularly is. Swapping the two
(`(rotationDegrees, scale, claimsSpace, anchor)`) removed every hole without an options bag.
Read the hole as a diagnosis, then pick the treatment.

⚠⚠ **Once there is a tail, every *optional* operand is a hole — so the head is what EVERY
caller supplies, not what reads best in a signature.** Trailing arguments can be omitted
freely; operands *before* an `opts = {}` cannot, because reaching the tail means filling
them. This is what decides a head across a family, and it is stricter than R1's "the typical
caller passes it": one member that legitimately has nothing to put in a slot is enough.
`PromptWdgt` is the worked case — `msg` and `callback` read like operands and three of its four
descendants pass both, but `SaveShortcutPromptWdgt` has a class-level title and no caller
action at all, so a `(widgetOpeningThePopUp, msg, target, callback, opts)` head forces it to
write `super widgetOpeningThePopUp, undefined, target, undefined, opts`. The head is therefore
`(widgetOpeningThePopUp, target, opts = {})`, and the omitted operands become option keys.

⭐ **A DOOR may keep the natural spelling.** The constraint above binds the constructor, whose
callers include every subclass `super`; it does not bind a convenience method with its own,
narrower caller set. `Widget.prompt` stays `(msg, target, callback, opts = {})` because no
caller of *it* skips any of the three — and the door is then the single place that translates
into the constructor's bag (`Object.assign {}, opts, msg: msg, callback: callback`). Keep the
key SPELLINGS identical across the seam: a forwarded options bag cannot survive one field
under two names, because the receiver never reads the alias.

⭐⭐ **A MENU/TRIGGER ADAPTER IS NOT THE VERB — and wiring a menu item straight to a verb taxes
every override of it.** `ButtonWdgt` dispatches a fixed four-slot convention
(`@target[@action].call @target, theButton, subject, arg1, arg2`), so an item carrying no arguments
still arrives with *widgets* in the leading slots. A verb wired directly to a menu has to defend
itself — and since a bare `super` forwards the raw `arguments` rather than the parameters that
defence just rebound, **every override needs its own copy of it**. `createReference` is the worked
case: one menu item put the same `if referenceName? and typeof(referenceName) != "string"` sniff
into the `Widget` core *and* both overrides — three copies of a runtime type test whose only job was
to undo the dispatcher — and the sniff also pinned the parameter order, so the two drop recipients
kept punching `undefined` through to reach the place they cared about. One line of indirection fixes
all of it: a `…FromMenu` / `…MenuAction` adapter (the shape `PanelWdgt.makeFolderFromMenu` and
`StringWdgt.setFontNameFromMenu` already use) translating the click into the call the verb actually
wants — for a menu, usually the NO-argument call. The three sniffs then delete and the verb is free
to take the parameters it should have had. ⚠ It applies in reverse too: never give an adapter the
verb's own name — an arity-0 `createReferenceAndClose` menu action on a prompt class SHADOWS
`Widget.createReferenceAndClose` on every instance of that class.

⭐⭐ **AND THE SLOTS ARE NOT WHAT THEY LOOK LIKE: slot 2 is the ENCLOSING PANEL's target,
unconditionally — not the row's own.** `CommandPanelWdgt._createMenuItem` builds every row with
`subject: @target`: slot 1 of a menu dispatch is always the button that fired (`ButtonWdgt` passes
itself), slot 2 is always the subject the *enclosing panel* was built about, with no special case
left for a "which panel" fork. So a verb taking its SUBJECT from slot 2 —
`MenusHelper.popUpDevToolsMenu`, and every pin setter (see `widget-authoring-guidelines.md`, "The
pin-setter contract") — is right exactly when the menu it sits in was built `target: <that subject>`
(Widget's own "Dev" row is the pattern), and reads something else whenever it wasn't. A row therefore
cannot be copied into another menu without first checking what THAT panel's target is. ⚠ A row wired
to a **different** receiver than the panel does not opt out of this — the receiver comes from the
row, the two leading dispatch arguments still come from the panel.

### R4 — Option keys are the caller's vocabulary, not the field's name.

An option key is named for what the **caller** means, and may be much shorter than the field
it lands in. This is established practice, not a liberty:

| Option key | Field it sets |
|---|---|
| `opts.closesUnpinnedPopUps` | `ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked` |
| `opts.toolTip` | `toolTipMessage` |
| `opts.arg1` / `opts.arg2` | `argumentToAction1` / `argumentToAction2` |

The long field name states the mechanism to a maintainer; the short key states the intent to a
caller. Both are right in their own place. Keep a key's spelling identical across every class
that offers it — the `add` / `_addNoSettle` family shares one vocabulary (`atIndex` / `layoutSpec`
/ `beingDropped` / `notContent` / `positionOnScreen`) across all seven overrides, and that
consistency is what makes the option nameable without checking the receiver.

⭐ **A key can be the bug, so pick the one that makes a wrong argument look wrong.** That family's
index key names a slot reaching `@children.splice`, and under the vaguer name `position` two callers
read it as a screen position and wrote `world.add slider, new Point 760, 240` — `Number(Point)` is
NaN, so `splice` takes index 0 and the placement is dropped in silence. `atIndex` is a name nobody
hands a `Point`. (Case history: `archive/constructor-parameter-conformance-plan.md` §7b.)

### R5 — A `@param` in the signature is a hazard; options are read in the body.

A CoffeeScript `@param` **assigns the field unconditionally**, with or without a default, so it
shadows the class-level default with `undefined` when the argument is omitted (the full law and
its two case-law incidents are in the root `CLAUDE.md`). Options are immune by construction —
they are read in the body, where the guard is visible:

```coffee
@backgroundColor = backgroundColor if backgroundColor?   # plain param, guarded
@color = opts.color ? Color.BLACK                        # option, guarded
```

Converting a `@param` to an option therefore *fixes* this hazard as a side effect. Converting
in the other direction re-arms it.

### R6 — Assign options where the old positional parameters were assigned.

`@param`s are assigned before the `super` call. An option read must land in the same place to
preserve the order the all-`@param` form compiled to — a field a superclass constructor reads
must be set before `super()`, not after. `SliderWdgt` reads both its options above `super()`
for exactly this reason.

⚠ *Before*, not after, because Fizzygum does not run ES class syntax. `src/meta/Class.coffee`
compiles each constructor as a standalone fragment and rewrites `super` into a plain
`__super__.constructor` call, so the compiler never sees a *derived* constructor and emits the
`@param` assignments at the top of the function as it would anywhere else. Under real
`class X extends Y`, ES forbids touching `this` before `super()` and CoffeeScript moves those
assignments *below* the call — the opposite order, and a base constructor calling a virtual
method would then see the subclass's parameters unbound. Reason about this codebase from the
fragmented emit, never from what `coffee -bcp` prints for a whole file (which mostly refuses to
compile these files at all).

### R7 — A base-class signature change ripples through every `super`. Convert a family atomically.

`super` calls in subclasses pass the **old** positional signature and must change with the
base, in one commit. Half a converted family is a broken build at best and a silently
mis-bound field at worst. The button family (`ButtonWdgt` → `LabelButtonWdgt` →
`MenuItemWdgt`/`MagnetWdgt`, plus `SimpleButtonWdgt`/`SimpleRectangularButtonWdgt`/
`SimpleRasterImageButtonWdgt`) is one unit; so is the text family.

⚠ A **bare** `super` forwards `arguments` — what the CALLER passed — not this constructor's
defaulted parameters. `Class.coffee`'s `_equivalentforSuper` rewrites it to
`__super__.constructor.apply(this, arguments)`, and the `@param` assignments sit **above** that
call (§R6), so the base then re-defaults every slot the caller omitted **straight over the
subclass's own defaults**. A subclass that states defaults and forwards bare therefore states
them to no effect: `SimpleTextWdgt` declared 12pt and `Color.BLACK` and shipped
the default text size (now `Theme`'s `fonts.defaultText`) and a 37,37,37 ink (now `Theme`'s `defaultTextInk`, read as the text paints) for years. Make the call explicit when the signature
changes shape — and check, when you do, whether the defaults it was hiding were ever real.

### R8 — Don't invent a second options shape where a spec class already exists.

If a class already accepts a named spec object, extend **that** rather than adding a parallel
`opts` vocabulary next to it. Two ways to say the same thing is the cost this convention exists
to avoid.

### R9 — When the bag outlives the call, promote it to a spec class.

An `opts` literal is consumed immediately and discarded. When the same bundle is **passed
around, stored, or built by one party and consumed by another**, it has become a value in its
own right and gets a named class — `CommandSpec`, `TransformSpec`, the layout-spec family. A
spec class is documented, has defaults in one place, and can be type-checked by eye at the call
site.

Note the corollary, visible in `CommandSpec`'s own header: the menu-level context (font,
environment — the same for every row) is supplied by the owning `MenuWdgt`, *not* carried on
the per-row spec. A spec holds what varies per instance; what is constant across instances
belongs to the owner.

---

## 3. Exemptions — where positional is right and an options object is wrong

These are not grudging carve-outs; they are cases where the hybrid rule's *own* reasoning says
positional wins. A class in this list keeps a positional signature however long it is, and the
hole test (R3) is answered by reordering, not by an options bag.

| # | Exempt | Why | Evidence |
|---|---|---|---|
| E1 | **Value / geometry tuples** — `Point`, `Rectangle`, `Color` | canonical order; an options object would double the allocation on the hottest construction path in the system | ~960 `new Point`, 95 `new Rectangle` in `src/` |
| E2 | **Per-frame construction** generally | same allocation argument, wherever it actually applies | — |
| E3 | **Records mirroring a foreign API** — the `events-input/` family | fields and their order come from the DOM event, not from us; the *named* entry point is the `fromBrowserEvent` static factory, and every runtime site uses it | 5 classes, 7–11 params (two more in the family are already ≤4 on their own); `WorldWdgt`'s DOM handlers all go through the factory |
| E4 | **Published user-facing spellings** | a spreadsheet formula is typed by a user; changing the spelling breaks saved documents | `new SliderWdgt 0, 100, 30, 10` via `FormulaCompiler` |
| E5 | **Arity ≤ 3, all required** | nothing to separate | 129 of 144 constructors |

**E3 is the pattern worth generalising**: when a long positional list is unavoidable, give it a
**named static factory** and make that the door. `Color.create r, g, b, a` is the same move —
the constructor exists, but `Color.create` is what the codebase calls (**1** `new Color` site
against the factory's many), because the factory also interns. A factory names the *intent*
where the constructor could only name the *fields*.

---

## 4. The decision procedure

For each parameter, in order:

1. Is the class exempt (§3)? → keep positional; fix holes by reordering. **Done.**
2. Do **all** typical callers pass it, in a predictable position, and is it not a bare boolean?
   → positional head (cap 4).
3. Otherwise → `opts`, keyed by caller intent (R4), read `opts.key ? default` (R2).
4. Does any call site still need a hole? → go back to 2; you got one wrong.
5. Is the bag passed around or stored rather than consumed? → spec class (R9).

**Smell shortlist** — any one of these means the list is mis-shaped: a bare `true`/`false` as
the *first* argument; three or more consecutive `undefined`s; a trailing comment per argument
to make the call readable at all; two call-site groups that want disjoint tails.

## 5. What is enforced

**`buildSystem/check-call-arguments.js` enforces three rules on every build, over every call site in
BOTH repos, at an exact zero** — Fizzygum's `src/`, the tests repo's harness, every macro source, the
`MacroToolkit` heredocs (the standard macro verbs, code in strings) and the tests repo's scripts. It
reads them with real parsers (`buildSystem/lib/call-sites.js`): every class as the browser's
meta-compiler splits it into member fragments and rewrites its `super`s, parsed by the browser's own
CoffeeScript; the scripts with acorn. So an implicit object `face: x, toolTip: y` is ONE argument, a
nested paren-less call is one argument of the outer call, and a string's contents are never a call.
There is no baseline and no sanction marker: a call the gate misjudges is reshaped.

- **`HOLE`** — R3's callers test, applied mechanically: each hole is printed with its WITNESS. An
  `undefined` every caller writes is judged a value (`--values` lists them — the
  `@assertValuesEqual "…", undefined, x` of the macros among them).
- **`EXTRA_ARGUMENT`** — a call passes more arguments than any definition it can reach declares: an
  argument no parameter receives. Dead (a size handed to a constructor that takes none), or
  mis-bound: a positional handed past an `(opts = {})` head, or a spelling that compiles to something
  its author did not write. A call is judged only where its TARGET is certainly among the
  definitions it reaches: what runs where it runs (page code, a macro program, a script module, each
  seeing its own), a bare call resolved lexically, a `new` of the one class its name means there, a
  send whose receiver is `@`/`this` or `X.` of a class whose whole chain the reader read (never an
  `Array` or an `EventEmitter` above it); the declared count is the widest of them. Matching by name
  alone would read `Math.max a, b, c` against `Point::max`: a foreign API's definitions are invisible.
- **`POSITIONAL_INTO_OPTIONS`** — an argument of a kind the parse shows is no options object (`@`, a
  literal, an array, a function, a `new`) lands in a parameter defaulting to `{}`, and is silently
  taken AS the options object: `new SimpleButtonWdgt @` after the head became `(opts = {})`.

⚠ **Spellings that compile to something else.** CoffeeScript's paren-less calls take whatever follows
as arguments, so a line written as a SIBLING can be parsed as an argument. Each of these compiles
without error and mis-binds:
- an array (or any list) element written `f "a",` with the next element on the next line —
  `[ f "a",⏎ f "b" ]` is ONE element, `f("a", f("b"))`: boot's first batch of script loads, spelled so,
  awaited only its first file and started compiling before the CoffeeScript library was in.
  `EXTRA_ARGUMENT` catches it when `f`'s parameters are known; give each element its own parentheses;
- `X a: 1, b: 2,` followed by indented keys — TWO objects, `X({a, b}, {c})`; `EXTRA_ARGUMENT` catches it
  against an `(opts = {})` head;
- `super` alone on a line followed by indented keys — the meta-compiler's rewrite makes it a forwarding
  `super` whose RESULT is then called with the keys, `….constructor.apply(this, arguments)({a: 1})`.
Check a new spelling with `buildSystem/compile-fragment.js` before trusting it.

What it cannot judge, by construction (its header holds the full list): a callee no code in either
repo defines (`JSON.stringify`); a dynamic `new (classNamed name)`; the this-arg of `.call` / `.apply`
/ `.bind`; code inside a string other than the heredocs (a spreadsheet formula); a call of unknown
arity (a spread, a forwarding bare `super`), which is never a witness and never judged for arity. For
the two arity rules besides: a send to a receiver the parse cannot see (`frame.m a`), or in a class
with a foreign ancestor (`extends Array`); a callee some code also binds or assigns as a VALUE
(`canvas.width = …` leaves every `@width()` unjudged); a callee taking any number (a splat,
`arguments`); a method no code defines as a member or field (assembled at run time); a script's bare
call of a name its module neither binds nor imports; `new @constructor` (it may build a subclass); and
a lone VARIABLE handed to an options slot (`new X target`) — so
after converting a head to options, list the family's sites with `census-call-arity.js` (`<Class…>`
for its `new`s, `--super=` for its supers, `--call=` for a method — the gate's own table, with each
site's real argument count): every site of an `(opts)` head passes one object.

⚠ **Why the gate reads the tests repo.** Connector §P4 deleted `PaletteWdgt`'s leading `target`
parameter — a hole with ELEVEN live call sites, every one of them in a macro source, so a check of
`src/` alone read clean throughout. A test, a macro verb and a rig are callers like any other.

Everything else here is convention, checked by review. The cap in R1, the vocabulary in R4 and
the atomicity in R7 are not expressible as a text scan.

## 6. Changing a constructor is safe for serialization and duplication

Both `Deserializer` and the duplicator instantiate through **`Object.create`** — the
constructor is **never run** (`src/serialization/Deserializer.coffee:192`,
`src/duplication/Duplicator.coffee:168`). So a signature change, including a reorder, cannot break a
saved snapshot or a duplicate. **Only explicit `new X(...)` and `super` sites matter.**

⚠ Grep for all of them, in both repos: `new X`, `super`, `@method` self-calls (a
`.method`-anchored search misses these), and the sibling `Fizzygum-tests` repo — which carries
its own construction sites, including CoffeeScript inside **spreadsheet formula strings** and
plain JS `new SliderWdgt(0, 100, 40, 10)` in the rigs.

## 7. Current conformance

**Both repos are conformant, constructors and methods alike.** Every constructor takes ≤4 operands or
is named exempt under §3, and `check-call-arguments.js` holds every call site of both repos at zero
holes, zero extra arguments and zero positionals into options (§5). The per-family measurements, the four heads that measurement overruled, and the
phase-by-phase record are in
[`../archive/constructor-parameter-conformance-plan.md`](../archive/constructor-parameter-conformance-plan.md);
the gate's own arcs — the parser, the mechanized callers test, the button family's head — in
[`../archive/argument-holes-both-repos-plan.md`](../archive/argument-holes-both-repos-plan.md),
and the two arity rules in [`../archive/call-arguments-gate-plan.md`](../archive/call-arguments-gate-plan.md).

⚠⚠ **The last tail found was one layer BELOW the verbs already converted, and that is the lesson.**
`add` was converted while `__add` / `_addChild` beneath it kept the same misleading parameter name
*and* two holes of their own; the menu-adapter *definitions* were converted while two sites
hand-rolling the same dispatcher with an explicit `.call` stayed invisible to a signature sweep; and
`createReference` was reached only by following `createReferenceAndClose` down to the core they
share. **A public verb delegates to a private core, which delegates again — convert the chain, not
the face**, and sweep by the FAMILY name rather than the one method that showed up in the count.

Landed conversions, in order: the `addMenuItem`/`prependMenuItem` family, the `MenuWdgt` and
`FrameWdgt` constructors, and the four `_addNoSettle` overrides
([`../archive/accidental-complexity-reduction-plan.md`](../archive/accidental-complexity-reduction-plan.md) P5);
then `SliderWdgt`, `CommandSpec`, the text family (`StringWdgt` / `TextWdgt` / `SimpleTextWdgt`,
all three to `(text, opts = {})`), the button family, the prompt family
(`(widgetOpeningThePopUp, target, opts = {})`), the stragglers, the **method** families, the
polymorphic **`add`** family — 7 overrides of inconsistent arity (4, 5 and 6 slots) collapsed to one
`(aWdgt, opts = {})` — and finally the tail the gate could not see: `Appearance._paintInLocalScope`
(whose two "options" turned out to be class-level declarations), the `createReference` family
(reordered behind a new menu adapter), `cleanupMenuWdgts`, `fullImage`, `_insertAddersSuchThat` and
the meta-compiler's own `Class.findUpTo`; the button family's own head — `(target, action, opts)` →
ONE options object with `target:` and `action:` keys (a face-only button, a toggle's two faces and the
rigs' fixtures had to write `undefined, undefined` to reach the options); and
`_applyTransformSugarNoSettle`'s keyed partial update (R3's table).

⭐ **The convention is not constructor-specific, and the method phases are the proof.** Of the 51
holes originally counted, 25 were ordinary **method** calls, and the last three phases were all
method families. They kept finding the same shape: a method whose extra slots exist for a
*dispatcher* (`ButtonWdgt`'s fixed 4-slot menu convention) or for a *sibling class* (`add`'s
`notContent` / `positionOnScreen`, read by one receiver each), with everyone else punching
`undefined` through to reach past them. The options tail is what lets one call address a whole
polymorphic family: a receiver that does not read a key simply ignores it.

⭐ **A hole is a symptom; read it as a diagnosis and the real defect is usually elsewhere.** Chasing
these last few turned up, at the bottom of them: a dead-and-broken callback nothing could reach
(`ErrorsLogViewerWdgt.informTarget`), two spreadsheet fixtures whose slider was never placed because
a `Point` coerced to index 0, a parameter that padded a convention its method was never part of, a
runtime type-test triplicated across a class and both its overrides, a dead field
(`CodePromptWdgt.@msg`), and a dead parameter (`cleanupMenuWdgts`'s `expectedClick`, which appeared
only in its own signature). The mis-shaped list is the visible end of something that was never
looked at.

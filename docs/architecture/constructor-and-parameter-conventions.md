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
   **not** irrelevant for value classes minted per-frame — `new Point` alone has **941** call
   sites in `src/`.

So the shape is a hybrid, and §3 draws the boundary conservatively: where the allocation
argument has any force at all, the class is exempt outright.

## 2. The rules

### R1 — The positional head is the required, ordered operands. Cap: 4.

A positional parameter must pass **all** of these:

- the **typical** caller passes it (not just an unusual one);
- it has a **canonical position** in an order a reader can predict (a tuple, or an
  established convention like `target, action`);
- it is **not** a bare `true`/`false` at most call sites.

Four is the hard cap, and four is already generous — 117 of the 139 constructors in `src/`
take four or fewer. If a fifth operand is genuinely required and genuinely ordered, that is a
strong hint the class is doing two jobs; look there before widening the head.

### R2 — The options tail carries everything else.

One trailing parameter, spelled `opts = {}`, read guarded:

```coffee
@killThisPopUpIfClickOutsideDescendants = opts.killOutside ? true
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

⚠ **The remedy is not always an options object.** For a ≤4-parameter class that is otherwise
exempt (§3), a hole means *reorder* — put the commonly-passed operand first. `TransformSpec`
(`src/basic-widgets/Widget.coffee:1857`: `new TransformSpec relDeg, 1 / sPlane, undefined,
"slot"`) is an immutable value class with one hole; it wants its parameters reordered, not an
options bag. Read the hole as a diagnosis, then pick the treatment.

### R4 — Option keys are the caller's vocabulary, not the field's name.

An option key is named for what the **caller** means, and may be much shorter than the field
it lands in. This is established practice, not a liberty:

| Option key | Field it sets |
|---|---|
| `opts.killOutside` | `@killThisPopUpIfClickOutsideDescendants` |
| `opts.closesUnpinnedPopUps` | `ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked` |
| `opts.toolTip` | `toolTipMessage` |
| `opts.arg1` / `opts.arg2` | `argumentToAction1` / `argumentToAction2` |

The long field name states the mechanism to a maintainer; the short key states the intent to a
caller. Both are right in their own place. Keep a key's spelling identical across every class
that offers it — the `_addNoSettle` family shares one vocabulary (`position` / `layoutSpec` /
`beingDropped` / `notContent` / `positionOnScreen`) across four overrides, and that consistency
is what makes the option nameable without checking the receiver.

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
`normalTextFontSize` and `Color(37,37,37)` for years. Make the call explicit when the signature
changes shape — and check, when you do, whether the defaults it was hiding were ever real.

### R8 — Don't invent a second options shape where a spec class already exists.

If a class already accepts a named spec object, extend **that** rather than adding a parallel
`opts` vocabulary next to it. Two ways to say the same thing is the cost this convention exists
to avoid.

### R9 — When the bag outlives the call, promote it to a spec class.

An `opts` literal is consumed immediately and discarded. When the same bundle is **passed
around, stored, or built by one party and consumed by another**, it has become a value in its
own right and gets a named class — `MenuItemSpec`, `TransformSpec`, the layout-spec family. A
spec class is documented, has defaults in one place, and can be type-checked by eye at the call
site.

Note the corollary, visible in `MenuItemSpec`'s own header: the menu-level context (font,
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
| E1 | **Value / geometry tuples** — `Point`, `Rectangle`, `Color` | canonical order; an options object would double the allocation on the hottest construction path in the system | 941 `new Point`, 94 `new Rectangle` in `src/` |
| E2 | **Per-frame construction** generally | same allocation argument, wherever it actually applies | — |
| E3 | **Records mirroring a foreign API** — the `events-input/` family | fields and their order come from the DOM event, not from us; the *named* entry point is the `fromBrowserEvent` static factory, and every runtime site uses it | 7 classes, 8–11 params; `WorldWdgt:2129-2263` all go through the factory |
| E4 | **Published user-facing spellings** | a spreadsheet formula is typed by a user; changing the spelling breaks saved documents | `new SliderWdgt 0, 100, 30, 10` via `FormulaCompiler` |
| E5 | **Arity ≤ 3, all required** | nothing to separate | 107 of 139 constructors |

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

The hole test is mechanically checkable and is ratcheted by the `positional-hole` stink in
`buildSystem/check-stinks.js` (see [`lint-and-static-checks.md`](lint-and-static-checks.md)):
≥2 consecutive bare `undefined` arguments on a non-comment line. It is a **ratchet** —
exceeding the baseline fails the build; dropping below it is a prompt to tighten. The target is
0.

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

139 constructors in `src/`; 117 take ≤4 parameters and are already conformant or exempt. The
22 at ≥5 are inventoried, with a per-family conversion order, in
[`../plans/constructor-parameter-conformance-plan.md`](../plans/constructor-parameter-conformance-plan.md).
Landed conversions to date: the `addMenuItem`/`prependMenuItem` family, the `MenuWdgt` and
`FrameWdgt` constructors, the four `_addNoSettle` overrides
([`../archive/accidental-complexity-reduction-plan.md`](../archive/accidental-complexity-reduction-plan.md) P5),
and `SliderWdgt`.

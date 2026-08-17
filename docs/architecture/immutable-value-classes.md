# Immutable value classes

Fizzygum's value classes follow Joshua Bloch's *Effective Java* treatment: minimize mutability,
share canonical instances, provide static factories where interning pays. This doc is the policy,
the inventory, and the engine contracts. (History: `docs/archive/` — the immutability +
canonical-instances arc.)

## 1. The policy

A value class is **"new on change"**: every field is set at construction and never written again;
every derivation returns another (possibly shared) instance. The full policy essay lives at the
top of `src/basic-data-structures/Rectangle.coffee` — the canonical statement, including the
aliasing licence (a derived Rectangle may point at the old `origin`/`corner` Points, because
those can never change).

Consequences, all load-bearing:

- **No defensive copying anywhere.** Neither `Point` nor `Rectangle` has a `copy()` at all;
  caches (`Widget.cachedFullBounds`, clip-through caches, …) hand out their stored instances
  uncopied; accessors alias (`topLeft()`/`position()`/`bottomRight()` return the actual
  sub-Points).
- **Comparison is content, never identity.** `equals` everywhere; `Color.equals` adds an
  identity fast path. Nothing in src or tests may rely on two logically-equal values being
  distinct instances, or on two calls returning the same instance.
- **Enforcement is by convention + the byte-exact suite** — `# IMMUTABLE` headers, this doc,
  and the fact that a violation shows up as pixel drift or state corruption under the 270+
  SystemTests. Deliberately NO `Object.freeze` (in non-strict mode a write to a frozen object
  no-ops silently, so a dev-only freeze would make dev and prod BEHAVE DIFFERENTLY on a
  violation) and no grep-gate (plain `{x,y}` literals — e.g. `WorldWdgt.getCanvasPosition`'s
  deliberately-mutable result — are idiomatic and indistinguishable to grep).

## 2. The shortcut rule (canonical instances)

When an operation's result would be **value-identical** to an existing instance, the operation
returns that instance instead of allocating:

- **`this`** — e.g. `round()`/`floor()`/`ceil()`/`spread()` on already-integral geometry (the
  common case under the integer-placement policy), `add 0`, `scaleBy 1`, `insetBy 0`,
  `merge` with a contained rectangle, the TransformSpec withers when the value is unchanged.
- **A canonical constant** — `Point.ZERO` (from `multiplyBy 0`), `Rectangle.EMPTY` (from
  `intersect` misses, `zeroIfNegative`, `scaleBy 0`), the `Color` named constants,
  `ShadowInfo.NO_SHADOW`.

**The bar: exact `===` equality of every coordinate with what the allocation would have
produced.** Two consequences decided once, here:

- A `-0`-for-`+0` swap is accepted (`-0 === 0`; the codebase's own `equals` uses `is`;
  nothing distinguishes them; pixels cannot differ).
- NaN/Infinity inputs must FALL THROUGH to the allocating path: `x * 0` is NaN for non-finite
  `x`, hence the `Number.isFinite` guards on the ×0 shortcuts; comparison-based guards
  (`min`/`max`/`merge`/`abs`) are naturally NaN-safe because comparisons with NaN are false.

Also: a shortcut must not add work to the hottest common path — e.g. Rectangle's all-numbers
constructor branch deliberately has NO zero-check.

Type-dispatch inside guards is **duck-typed, not `instanceof`** (`delta.isZero?()`,
`scale.x is 1`) — the `instanceof-type-test` stink ratchet locks the type-test count.

## 3. Canonical constants and how they initialize

| Constant | Built by |
|---|---|
| `Point.ZERO` | deferred static |
| `Rectangle.EMPTY` | deferred static |
| `Color.ALICEBLUE` … `Color.TRANSPARENT` (137 lines) | deferred statics via `Color.createConstant` |
| `ShadowInfo.NO_SHADOW` (what `ShadowInfo.noShadow()` returns) | lazy memo on first `noShadow()` call |

The **deferred-static mechanism** (`src/meta/Class.coffee`, `getSourceOfAllProperties`): a
class-level value whose source matches `new <OwnClass> …` or `<OwnClass>.create*(…)` is
initialised right AFTER the class exists instead of during its definition. Two spelling rules:
the `new <OwnClass>` form must use **space-call style** (`new Point 0, 0` — a paren directly
after the class name defeats the regex), and factory names must start with `create`
(the regex is `\.create\w*`).

⚠ **A class-level constant must not reference ANOTHER class** unless a load-order edge
guarantees that class is already loaded — and the boot dependency scanner
(`src/boot/dependencies-finding.coffee`, `CONSTRUCTION_IN_CLASS_DECLARATION`) only sees
`new X` edges in **class-declaration-level initializers** (never constructor defaults or
method bodies). This is why `ShadowInfo.NO_SHADOW` is a lazy memo inside `noShadow()`
rather than a class-level `new ShadowInfo Point.ZERO, 0`: ShadowInfo's only Point mentions
are scanner-invisible, so on the interactive dev page ShadowInfo can class-eval before
Point exists (it did — a boot hang caught by the smoke). Self-references are always safe
(the deferral runs right after the class's own definition).

**`Color` interning is two-tier:** `Color.create` consults the permanent table
(`Color._permanent`, seeded by `createConstant` — never evicted) and then the LRU
(`Color._cache`, 300 slots, 24h TTL). So a named constant stays THE canonical instance for the
whole session, while ad-hoc colors dedupe best-effort. Derivations (`mixed`, `lighter`,
`darker`, `bluerBy`) all route through `create` — never bare `new`, which would bypass the
dedupe.

## 4. The engine contracts (serialization / duplication)

- **Duplication**: immutable values declare `keptByReferenceOnDeepCopy: true`
  (`Point`, `Rectangle`, `ShadowInfo`, `TransformSpec`, `SheetError`) — the Duplicator keeps
  the reference, no content walk (`Duplicator._cloneContentInto`). The check is FIELD-level:
  a value sitting inside a plain Array still deep-copies (harmless — just not shared).
  `Color` predates the flag
  and uses the shell hook `getEmptyObjectOfSameTypeAsThisOne: -> @` instead. ⚠ That shell hook
  is only safe for classes whose own properties are ALL primitives: the content-clone pass
  still walks own props, so on a Rectangle it would write cloned sub-Points onto the shared
  instance. For any new immutable, prefer `keptByReferenceOnDeepCopy`.
- **Serialization**: sharing round-trips as sharing (the object table is identity-keyed), but
  a canonical constant restores as a shared-but-fresh instance — fine, since nothing compares
  by identity; the next geometry op re-canonicalizes (e.g. `zeroIfNegative` hands back
  `Rectangle.EMPTY`). `Color` alone is serializer-special-cased (`{class:"Color", rgba:[…]}`,
  restored through `Color.create`, so color dedupe DOES survive a round trip). ⚠ If another
  value class ever gets a `TAG_BUILDERS` entry returning an interned instance, it MUST declare
  the explicit `populate: ->` no-op — omitting it drops to `assignProps`, which would write
  props onto the shared canonical instance process-wide. The Serializer does NOT read
  `keptByReferenceOnDeepCopy` (its symbolic-singleton concept is `wellKnownKey` /
  `WellKnownObjects` — for per-world rebindable singletons, NOT for value classes; never give
  a value class a `wellKnownKey`).

## 5. Inventory

**Fully immutable, with constants/shortcuts:** `Point`, `Rectangle`, `Color`, `ShadowInfo`,
`TransformSpec` (replaced whole via its `with*` withers — see
`docs/architecture/transforms.md` §2).

**Immutable by declaration (no shortcut machinery — small or cold):** `Point3D` (every op
returns a fresh instance), `TextEditingState` (undo snapshot), `MenuItemSpec` (SHALLOWLY
immutable — its `target`/`action` fields reference live widgets), `PinSpec` (SHALLOWLY
immutable — inert strings, but they are METHOD NAMES resolved late against a live widget),
`SliderRange` (a TRANSIENT: derived on demand by `sliderRangeForPin`, applied, and dropped —
never stored, so nothing serializes or duplicates it, and it deliberately has no `equals`
because the equality a value class usually needs is the dataflow cutoff's and this never rides
an edge as a value), `SheetError`
(spec §9.5 purity law), `Macro` (with one sanctioned lazy memo, `_linkedCode` — same pattern
as `Color._derived_String`), `Grid3D`/`PlaneGrid3D` (index arrays are built before
construction), the `InputEvent` family (events are values; `WheelInputEvent.fromBrowserEvent`
writes on the RAW browser event before construction, which is outside the value; 
`MousemoveInputEvent`'s constructor reads `world` — impure construction, immutable after).

**Deliberately mutable (do not "fix"):** `VerticalStackLayoutSpec` / `FrameContentLayoutSpec`
(working layout state, written by design), `WireSpec` (a controller's connection — the SAME
attachment-spec shape as the layout family, serialized with its widget and carrying knobs: its
`firesPerEvent` is flipped in place by the wire's own menu row. ⚠ It follows that a wire is never
SHARED between controllers — a duplicated controller deep-copies its records, or toggling one copy's
policy would reach the other's), `MultiClickRecognizer` (its header mandates
per-instance mutable state), `PreferencesAndSettings`, all containers
(`LRUCache`, `DoubleLinkedList`, `TreeNode`, `InputEventsQueue`).

> **ARCHIVED — COMPLETE (2026-08-04).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Immutability completion + canonical-instance shortcuts

**STATUS: COMPLETE — CLOSED 2026-08-04.** All phases §4.1–§4.6 executed and gated: 5×
`fg presuite` (271/271, zero churn each), boot smoke both pages, BOTH serialization rigs,
full `fg gauntlet` (14 legs incl. dpr2/webkit/revisits/census/serialization/storage, all
PASS, zero recaptures), `fg homepage` (production boot + snapshot round-trip PASS).
Durable residue: `docs/architecture/immutable-value-classes.md`. The execution ledger
below records the two mid-arc findings (stink-ratchet guard reshape; the
scanner-invisible-edge boot hang and its rule).

Authored 2026-08-02. Every `file:line` below was verified against src on that date — line numbers
DRIFT; the quoted method name / code snippet is authoritative. Grep it fresh before trusting a line.

**EXECUTION STATUS (2026-08-04):**
- §4.1 mutation sites — DONE, presuite PASS (271/271, 0 geometry violations, zero churn)
- §4.2 copy() deleted + Rectangle warts — DONE, presuite PASS (zero churn)
- §4.3 constants + shortcuts — DONE, presuite PASS (zero churn). Note: the first guard shape
  (`instanceof Point` in the Rectangle zero-delta guards) tripped the `instanceof-type-test`
  stink ratchet (+6 over its 93 baseline) — fixed the smell, not the baseline: duck-typed
  `delta.isZero?()` / `scale.x is 1` guards instead. Class.coffee regex extension landed clean.
- §4.4 TransformSpec withers — DONE, presuite PASS (zero churn; transforms.md updated, incl.
  retiring its stale `TransformSpec @augmentWith DeepCopierMixin` claim)
- §4.5 share-on-copy — presuite PASS, but the serialization rigs then caught a REAL boot bug
  from §4.3: `ShadowInfo.@NO_SHADOW: new ShadowInfo Point.ZERO, 0` needs Point at
  ShadowInfo's class-eval, and the boot dependency scanner
  (`dependencies-finding.coffee` `CONSTRUCTION_IN_CLASS_DECLARATION`) only sees `new X`
  edges in class-declaration-level initializers — ShadowInfo's Point mentions (ctor
  default `new Point(7,7)`) are invisible, so the interactive dev page class-evaled
  ShadowInfo before Point → ReferenceError → boot hang. The SUITE page masked it (different
  compile order), the boot smoke named it exactly. FIX: `NO_SHADOW` became a lazy memo
  inside `noShadow()` (`@NO_SHADOW ?= new ShadowInfo new Point(0, 0), 0`) — no class-eval
  cross-class reference at all. RULE (now in the architecture doc §3): a class-level
  constant may reference ITSELF (deferral covers it) but never another class without a
  scanner-visible edge. After the fix: boot smoke PASS (both pages), BOTH serialization
  rigs PASS (59-check round-trip incl. teardown hygiene + 7-check file round-trip) —
  §4.5 CLOSED.
- §4.6 declarations + docs — DONE (headers on Point3D/TextEditingState/MenuItemSpec/
  Grid3D/PlaneGrid3D/the 7 InputEvent classes; Macro memo sanctioned; new
  docs/architecture/immutable-value-classes.md; serialization-duplication-reference.md
  §keptByReferenceOnDeepCopy corrected — the flag never drove $wk encoding; transforms.md
  §2 immutability entry). Close gates: gauntlet + homepage — running.

**Mandate:** complete the transformation — make the immutability invariant TRUE (eliminate every
violation), then exploit it (canonical constants, allocation-free shortcuts, share-on-copy). Not a
survey; not a partial hardening.

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework ("web OS" on one canvas), ~470 one-class-per-file sources
in `src/`, no modules — every class is a global. Build/test via the umbrella `fg` wrapper
(`/Users/davidedellacasa/code/Fizzygum-all/fg`): `fg presuite` = build + dpr1 suite + paint audit
(~2 min, the inner loop); `fg gauntlet` = the full parallel gate (~5 min, close of arc). The
269-test SystemTest suite compares canvas screenshots **byte-exactly** — that suite is this arc's
behavioral gate.

Years ago the owner, following Joshua Bloch's *Effective Java* (minimize mutability, static
factories, cache canonical instances), made the three core value classes "new on change":
`Point`, `Rectangle`, `Color` (all in `src/basic-data-structures/`). The treatment is UNEVEN:
Color got the full Bloch kit (interning factory, 149 cached constants, engine integration);
Rectangle got one constant (`@EMPTY`); Point — the most-constructed class in the codebase
(924 `new Point` sites) — got nothing. And six call sites still mutate Points in place.

This arc (owner-requested 2026-08-02): **(a)** extend immutability to every class that qualifies,
**(b)** add Bloch shortcuts — e.g. multiplying by zero returns THE canonical zero instance;
no-op derivations return `@`.

**Critical reframe:** the shortcuts are the *reward*; the *enabler* is making the invariant
actually true first. A shortcut that hands a shared canonical instance to a caller is only safe
when NO caller ever mutates a received value object. Six sites violate that today. Phase order is
therefore load-bearing: eliminate violations → delete the mutation escape hatch (`copy()`) →
only then intern and shortcut.

**Owner decisions (asked and answered 2026-08-02 — do not re-litigate):**
1. Enforcement = **comments + docs only** (Color-style `# IMMUTABLE` headers; the byte-exact suite
   is the behavioral gate). No `Object.freeze` (non-strict writes no-op silently → dev/prod
   divergence), no grep-gate (plain `{x,y}` literals make it false-positive-prone).
2. **Delete `copy()`** from Point and Rectangle (convert all callers; Bloch-pure).
3. **Convert TransformSpec to immutable** (withers + replace-on-change; supersedes its documented
   direct-mutation policy).
4. Duplicator sharing: **Point AND Rectangle** get `keptByReferenceOnDeepCopy: true`.

---

## §0.5 Cold-execution protocol

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status` (orient: repos, dirty counts, build
   freshness). ⚠ The Fizzygum working tree may already carry UNRELATED uncommitted arcs
   (as of 2026-08-02: app-kit lazy-part work, folder-population). Do not mix them into this arc's
   commit; keep a mental (or `git add -p`) separation for the end-of-arc commit conversation.
2. Read §1–§3 of this doc, then execute phases §4.1 → §4.6 IN ORDER (the order is a safety
   argument, see §0 reframe). Re-grep every line reference before editing.
3. Gate after each phase: `fg presuite` (from any cwd; it is path-correct). Expectation everywhere:
   **zero test failures, zero pixel churn, zero reference recaptures**. A pixel diff means a
   shortcut broke the `===` bar (§5) — fix the code. NEVER recapture a reference for this arc.
4. After §4.5 additionally run both serialization rigs (see §6) — they gate the `$r`-sharing shape
   change directly; don't wait for the gauntlet to find out.
5. Close: `fg gauntlet` (background, log-redirected, wait for the task notification — no polling)
   + one `fg homepage` run. Then the `/close-arc` ritual: archive this doc to `docs/archive/` with
   a status stamp + `archive/INDEX.md` line, land the durable residue in
   `docs/architecture/immutable-value-classes.md` (§4.6), propose commit message(s), **wait for
   owner approval — never commit/push autonomously**.
6. Long ops: launch via Bash `run_in_background: true` with output redirected to a log; peek with
   `cat /tmp/fg-<cmd>.verdict`. Use the Edit tool for .coffee edits (never `perl -pi` — it
   de-indents CoffeeScript). Absolute paths everywhere; the shell cwd is not trustworthy.

---

## §1 Current state (verified 2026-08-02)

### 1.1 The three core value classes

| Class | File (lines) | State |
|---|---|---|
| `Color` | `basic-data-structures/Color.coffee` (266) | **The reference implementation.** `# IMMUTABLE` header line 1; private `_r/_g/_b/_a`; interning static factory `@create` (:185–195) over `@_cache: new LRUCache 300, 1000*60*60*24` (:161); 149 constants `@ALICEBLUE…@TRANSPARENT` built via `Color.create`; duplication hook `getEmptyObjectOfSameTypeAsThisOne: -> @` (:265); serializer special-case (§1.4). Two defects: `bluerBy` (:197) uses bare `new @constructor` — the ONE derivation op bypassing the cache; and the LRU **evicts/expires**, so after ~300 distinct colors `Color.create 0,0,0` stops returning `Color.BLACK` by identity (harmless today — nothing compares by identity — but it makes "THE canonical instance" a non-guarantee). |
| `Rectangle` | `basic-data-structures/Rectangle.coffee` (288) | Immutable in effect. Header essay states the "new on change" policy incl. the aliasing licence (":17-20 — sub-Points may be shared because they never change") and "you never need copy()". `@EMPTY: new Rectangle` (:40), returned by `intersect` (:212) and `zeroIfNegative` (:221); 14 consumer sites incl. `Widget.coffee:377` (`@bounds = Rectangle.EMPTY` in the Widget constructor). All `.origin=`/`.corner=` writes are INTERNAL, on just-created locals inside its own factory methods (insetBy/expandBy/growBy/rightHalf/intersect/merge/setBoundsWidthAndHeight). Warts: dead-and-buggy ctor branch `left instanceof Rectangle` (:59-61) reads `top.origin` (`top` is the SECOND arg — undefined there; no call site passes a Rectangle, verified by grep); `merge` (:233) writes `a.corner.max aRect.corner` where it means `b.corner` (behavior-identical today since `b === aRect` whenever that line is reached, but wrong on its face); `bottomRight` (:107) returns `@corner.copy()` while sibling `topLeft`/`position` alias `@origin` directly. |
| `Point` | `basic-data-structures/Point.coffee` (178) | Immutable in practice — every derivation op returns `new @constructor …` — but **no constants, no factory, no statics at all**, public unprefixed `x`/`y`, and six external violation sites (§1.2). 924 `new Point` occurrences in src (55% with literal args; top literal: `new Point 100, 100` ×139 across the 78 `*IconAppearance` prototype fields). Ops: `add subtract multiplyBy floorDivideBy max min round abs neg floor ceil toLocalCoordinatesOf distanceAngle corner rectangle extent`; `scaleBy`/`translateBy` delegate to `multiplyBy`/`add`. `floor` (:57) CLAMPS to ≥ 0. `isZero` (:20) takes an unused `aPoint` param. |

### 1.2 The six in-place Point mutation sites (the complete list; nothing mutates a Rectangle or Color)

1–2. `src/HandleAppearance.coffee:117,119` — resize-handle stripe loop: `bottomLeftSweep.x = bottomLeft.x + i` / `topRightSweep.y = topRight.y + i` on Points obtained via `.copy()` (:110-111). The sweep Points exist only to feed `context.moveTo/lineTo` scalars.
3–5. `src/basic-widgets/CaretWdgt.coffee:290,294,296` — `pos.x = right`, `pos.x = left`, `pos.x += right - @target.right()` on the fresh Point from `@target.slotCoordinates @slot` (producers end in `new Point x, y`: `StringWdgt` / `TextWdgt`).
6. `src/graphs-plots-charts/Example3DPlotWdgt.coffee:226` — `newPoint.y -= squareDim * 1/6` on the 2-D Point returned by `Point3D::project`.

Also shallow-immutability gaps: `Grid3D`/`PlaneGrid3D` (`src/graphs-plots-charts/`, 7-line twins) have their `vertexIndexes` array pushed into from outside AFTER construction (`Example3DPlotWdgt.coffee:156-171`).

### 1.3 The complete `copy()` inventory (all receivers are Point/Rectangle)

src — 8 sites: `ActivePointerWdgt.coffee:1095` (`@previousNonFloatDraggingPos = pos.copy()`; `pos`
is a fresh mapped Point per event and is never mutated → alias suffices) ·
`HandleAppearance.coffee:110,111` (rewritten away in §4.1) · `Widget.coffee:996`
(`newPos = aRectangle.origin.copy()` stored into `@desiredPosition`, never mutated → alias) ·
`Rectangle.coffee:77` (`@copy()` inside `setBoundsWidthAndHeight`) · `Rectangle.coffee:107,187,200`
(`bottomRight`/`rightHalf`/`growBy` internals).
Harness — 1 site: `Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee:247`
(`@_applyExtent @_bootExtent.copy()`; `_applyExtent` funnels to `__commitExtent`, which REPLACES
bounds — alias suffices; harness `.coffee` changes need a rebuild).

### 1.4 Engine constraints (serializer / deserializer / duplicator) — verified

- **Serialization preserves instance sharing** (identity `Map` `slotOf`, `Serializer.coffee:223`;
  two holders of one Point emit one record + two `{$r:n}` refs) but NOT identity with module-level
  constants (Point/Rectangle restore via the generic `Object.create` + prop-write path —
  `Deserializer.coffee` `instantiate`). This already happens today: `Rectangle.EMPTY` round-trips
  as a shared-but-fresh instance and nothing cares (no identity comparisons exist — §1.5).
- **Color is the only value class with a serializer special-case**: `Serializer.coffee` ~:356 emits
  `{class:"Color", rgba:[…]}` with NO `props` key, and the Deserializer `TAG_BUILDERS` entry
  restores via `Color.create` **plus an explicit `populate: -> ` no-op**. ⚠ TRAP: a TAG_BUILDERS
  entry that returns an interned instance WITHOUT the `populate` no-op falls through to
  `assignProps`, which would write props onto the shared canonical instance — process-wide
  corruption. (No serializer interning is planned for Point/Rectangle — §7.3 — but record the trap.)
- **The Serializer never consults `keptByReferenceOnDeepCopy`** (grep-verified 2026-08-02): its
  only special-cases are `WellKnownObjects.keyFor` (`$wk` symbolic keys for per-world singletons,
  re-bound on restore), `instanceof Color`, and `instanceof Widget`. So §4.5's flag change affects
  DUPLICATION ONLY — snapshot encoding of Points/Rectangles is untouched. ⚠ Related but distinct:
  `Wallpaper.coffee` (:26-31) calls `wellKnownKey`/WellKnownObjects "the eventual replacement for
  keptByReferenceOnDeepCopy" — that migration is about per-world SINGLETONS (identity-matched
  against e.g. `world.wallpaper`). It does NOT apply to value classes: a Point is one of thousands
  of by-value instances, not a rebindable singleton. Do not give Point/Rectangle a `wellKnownKey`.
- **No backward-compat obligations** (owner standing direction, restated 2026-08-02): no existing
  serialized worlds need to remain loadable — this is a private project with no snapshot corpus.
  If a serialization-visible cleanup is the Right Thing mid-arc, do it; never contort for format
  stability.
- **Duplicator** (`src/duplication/Duplicator.coffee`): two per-class hooks.
  `getEmptyObjectOfSameTypeAsThisOne` (consulted in `_shellFor`, :167) returns `@` as the shell —
  but `_cloneContentInto` still WALKS own props, so it is **only safe for all-primitive classes**
  (Color). For Rectangle it would write cloned sub-Points onto the shared instance. ⛔ Do not use
  it for Rectangle. `keptByReferenceOnDeepCopy` (checked per FIELD VALUE in `_cloneContentInto`,
  :192-197) keeps the reference with **no content walk** — safe for any immutable. Existing users:
  `Wallpaper`, `DataflowEngine`, `SheetError`, `IconicDesktopSystemWindowedApp`, `WidgetFactory`.
- **Nothing in src or tests compares value objects by identity** (grep-verified): every comparison
  is `.equals` content comparison (`Color.equals` has an identity FAST PATH `@==aColor or …` —
  interning makes it faster, never different). No Map/Set/indexOf keyed by a value object.
  Returned-shared-instances is already the established pattern: every bounds cache
  (`Widget.cachedFullBounds` etc.) hands out its stored Rectangle uncopied and stores
  `Rectangle.EMPTY` directly.
- **`Widget.@bounds` is always REPLACED, never written through** (12 `@bounds =` sites; zero
  `.bounds.origin =` writes) — the precondition for share-on-copy (§4.5).

### 1.5 The deferred-static mechanism (how a constant can say `new <OwnClass>`)

`src/meta/Class.coffee` :415 (verbatim, load-bearing for §4.3):

```coffee
if ((new RegExp("\\s*new\\s*" + @name + "(\\s|$)")).test fieldValue) or
   ((new RegExp("\\s*" + @name + "\\.create(\\s|\\()")).test fieldValue)
```

A static whose source matches is deferred until after the class exists (`Rectangle.EMPTY` and all
149 Color constants rely on this). Consequences: **(a)** `@ZERO: new Point 0, 0` works as-is
(space-call style — the first regex requires whitespace after the class name; `new Point(0,0)`
paren-style would NOT match); **(b)** `Color.createConstant …` does NOT match the second regex
(it requires `.create` + whitespace-or-paren) — §4.3's Color item includes the one-line regex
extension.

### 1.6 New-immutability candidates (ranked, verified)

| Candidate | Evidence | Action |
|---|---|---|
| `ShadowInfo` (`src/ShadowInfo.coffee`, 13 lines) | zero mutation sites anywhere; static factory `@noShadow` returns a FRESH instance each call; 3 construction sites | full treatment (§4.3) |
| `TransformSpec` (`src/TransformSpec.coffee`, 232 lines) | deliberately mutable — 11 external writes, all in 2 widget classes (§4.4 lists them); every method already pure | CONVERT (owner decision 3, §4.4) |
| `Point3D` (`src/graphs-plots-charts/Point3D.coffee`, 43) | already copy-on-change; zero own violations (site 6 of §1.2 mutates its 2-D output) | declare (§4.6) |
| `TextEditingState` (10 lines) | pure ctor-assign undo snapshot; 1 construction (`StringWdgt.coffee:278`); zero mutations | declare (§4.6) |
| `MenuItemSpec` (35 lines) | pure parameter object, zero mutations — but holds live widget refs (`target`) | declare SHALLOWLY immutable (§4.6) |
| `SheetError` | already declared + `keptByReferenceOnDeepCopy: true` | nothing to do |
| `Macro` | already `# IMMUTABLE`; one lazy memo `_linkedCode` (:125) — same pattern as Color's `_derived_String` | sanction the memo in a comment (§4.6) |
| `Grid3D`/`PlaneGrid3D` | fields never reassigned; array pushed post-ctor | build array before ctor (§4.1.4) |
| InputEvent family (`src/events-input/`, 7 base/shape classes) | effectively immutable; the `deltaX/deltaY =` writes in `WheelInputEvent.coffee:24-25` hit the RAW BROWSER EVENT before construction (benign); `MousemoveInputEvent`'s ctor reads global `world` (impure construction, still immutable after) | declare (§4.6) |

NOT candidates (verified, with reasons — do not revisit): `VerticalStackLayoutSpec` /
`FrameContentLayoutSpec` (mutated by design, ~19 external writes), `MultiClickRecognizer` (its own
header mandates mutability), `PreferencesAndSettings` (config singleton), all containers
(`LRUCache`, `DoubleLinkedList`, `TreeNode`, `InputEventsQueue`), `LayoutSpec`/`AlignmentSpec*`/
`FittingSpec*` (never instantiated — static namespaces), services/registries.

---

## §2 Why it's shaped this way

The "new on change" policy came in with the Morphic-descended geometry rewrite; the Rectangle
header essay (:1-33) is its charter, including the aliasing licence and the warning that in-place
mutation "poisons" the approach. Color got the full Bloch treatment later (static factory + LRU +
constants + engine hooks) because colors are few, highly repeated, and equality-compared in hot
paint paths. Point never got constants because nothing forced the issue: the six mutation sites
predate the policy's enforcement ambitions, `copy()` survived as their enabler, and with no
canonical instances in circulation, mutating a locally-constructed Point was harmless in practice.
TransformSpec (affine arc, 2026-07) chose direct mutation deliberately — a `set*` setter would
collide by NAME with the widget-side self-settling wrappers and false-trip the public/private
layering gate (its :50-55 comment) — a naming constraint, not an argument against immutability;
withers (`with*`) sidestep it entirely.

---

## §3 The distilled argument

1. **The invariant is 6 sites away from true.** All six mutate locally-owned fresh Points; each
   rewrite is mechanical and behavior-identical. After that, immutability is a fact, not a habit.
2. **Once true, sharing is free.** Nothing compares by identity, serialization round-trips sharing,
   `keptByReferenceOnDeepCopy` exists and has five users, every bounds cache already hands out
   shared instances. The engines were built for this; only the value classes lag.
3. **The shortcuts are then pure wins** — `bounds.round()` on already-integer bounds (the common
   case: integer-placement is enforced project-wide by the `NON_INTEGER_GEOMETRY` gate) currently
   allocates 1 Rectangle + 2 Points for nothing, hundreds of times per cycle; `merge` inside
   fullBounds accumulation usually returns the parent's own rect. Returning `@` costs a few integer
   checks.
4. **Honesty about perf:** Point/Rectangle allocation has NEVER appeared in a profile
   (`docs/profiling/results-2026-07-07/`: framework busy-share is paint recursion/hashing/
   hit-testing; GC is attributed to SWCanvas per-pixel objects). This arc's justification is design
   integrity (Bloch), API safety (no mutation escape hatches), and free allocation reduction —
   NOT a measured bottleneck. The gate is correspondingly strict: zero pixel churn.
5. **Why not before:** the mutation sites made every sharing idea latently unsafe, and the
   in-place-optimization alternative was already rejected by the Rectangle charter itself.

---

## §4 Fix shape (execute in order)

### §4.1 Phase 1 — make the invariant true (eliminate all §1.2 sites)

1. `HandleAppearance.coffee` stripe loop: delete `bottomLeftSweep`/`topRightSweep` and their
   `.copy()`s entirely — the loop only needs scalars:
   `context.moveTo bottomLeft.x + i, bottomLeft.y` / `context.lineTo topRight.x, topRight.y + i`.
   (Read the loop first; keep the sweep-direction comments.)
2. `CaretWdgt.coffee` (3 sites): rebind the local instead of writing through:
   `pos = new Point right, pos.y` · `pos = new Point left, pos.y` ·
   `pos = new Point pos.x + (right - @target.right()), pos.y`. Control flow is sequential
   reassignment of a local — semantics identical.
3. `Example3DPlotWdgt.coffee:226`: `newPoint = new Point newPoint.x, newPoint.y - squareDim * 1/6`
   (or bind the projection to a temp first).
4. `Example3DPlotWdgt.coffee:151-171`: build the `vertexIndexes` arrays into plain locals FIRST,
   then `new Grid3D 21, 21, theArray` / `new PlaneGrid3D 21, 21, theArray`. (Unifying the two
   twin classes is OUT of scope.)

Gate: `fg presuite`.

### §4.2 Phase 2 — delete `copy()`; fix the Rectangle warts

1. Convert the §1.3 sites: `ActivePointerWdgt.coffee:1095` → `= pos` · `Widget.coffee:996` →
   `newPos = aRectangle.origin` · `WorldTestSupport.coffee:247` → `@_applyExtent @_bootExtent`
   (harness → rebuild needed) · Rectangle internals: `bottomRight` → `@corner`; `rightHalf` →
   `result.corner = @corner`; `growBy` → `result.origin = @origin`; `setBoundsWidthAndHeight` →
   build `new @constructor` from `@origin` + computed corner, no `@copy()`.
2. Delete `Point::copy` and `Rectangle::copy`. Re-grep `\.copy()` AND `@copy()` across src +
   `Fizzygum-tests/Automator-and-test-harness-src` + `Fizzygum-tests/tests` afterwards; only
   non-geometry receivers may remain.
3. Fix the dead ctor branch (`Rectangle.coffee:59-61`): `@origin = left.origin;
   @corner = left.corner` (correct-by-aliasing; no live caller, verified — keep it correct anyway).
4. Fix `merge`'s `aRect.corner` → `b.corner` (:233). Drop `isZero`'s unused param
   (`Point.coffee:20`).

Gate: `fg presuite`.

### §4.3 Phase 3 — canonical constants + shortcuts

**The `===` bar (see §5) governs every shortcut. Shortcuts must not add work to the plain numeric
constructor path.** Use `@constructor.ZERO` / `@constructor.EMPTY` (existing idiom, `intersect`
:212; no subclasses of the trio exist).

**Point** (`basic-data-structures/Point.coffee`):
- `@ZERO: new Point 0, 0` — space-call style (§1.5a).
- `add`/`subtract`: `other is 0`, or `other instanceof Point and other.x is 0 and other.y is 0`
  → return `@`.
- `multiplyBy`: scalar `1` / Point `(1,1)` → `@`; scalar `0` / zero-Point → `@constructor.ZERO`
  **only if `Number.isFinite(@x) and Number.isFinite(@y)`** (NaN·0 = NaN must take the old path).
- `round`/`ceil`: `Number.isInteger(@x) and Number.isInteger(@y)` → `@`.
- `floor`: integers AND both `>= 0` (it clamps) → `@`.
- `abs`: `@x >= 0 and @y >= 0` → `@`.
- `min`/`max`: return `@` (or `aPoint`) when one dominates componentwise; NaN fails the
  comparisons → falls through to allocation, correct.
- `scaleBy`/`translateBy` inherit via delegation — no edits.
- `Rectangle.coffee:58` (single-Point ctor branch): `@corner = new Point 0, 0` → `Point.ZERO`
  (Point loads — deferred statics included — before Rectangle; the `new Point` dependency edge
  guarantees it). ⛔ Do NOT add a zero-check branch to the all-numbers ctor path (cost on the
  hottest path for a rare hit).

**Rectangle** (`basic-data-structures/Rectangle.coffee`):
- `round`/`floor`/`ceil`/`spread`: return `@` when both Points are already fixed
  (`Number.isInteger` ×4; `floor`/`spread`'s floor-half additionally `>= 0`). Highest-value
  shortcut in the arc (§3.3).
- `translateBy`/`insetBy`/`expandBy`/`growBy`: zero delta (scalar `0` or zero-Point) → `@`.
- `scaleBy`: `1` → `@`; `0` → `@constructor.EMPTY` only if all 4 components pass
  `Number.isFinite`.
- `merge`: before allocating, `return a if a.containsRectangle b` / `return b if
  b.containsRectangle a`.
- Header: update the essay — keep "new on change", add the shortcut policy + `===` bar, DELETE the
  now-false "you never need to copy()" paragraph, replace the in-place-optimization paragraph
  (:25-33) with a pointer to the canonical-instances doc (§4.6).

**Color** (`basic-data-structures/Color.coffee`):
- `bluerBy` (:197): `@constructor.create @_r, @_g, @_b + howMuchMoreBlue, @_a` — same values,
  now cached/canonical.
- Make the 149 named constants PERMANENTLY canonical (today they live in the evictable LRU, §1.1):
  add `@createConstant: (r,g,b,a) ->` that stores into a permanent plain map
  (`@_permanent ?= {}`, same `"r,g,b,a"` key) AND the LRU, `@create` consults `@_permanent` before
  the LRU; switch the constant definitions to `Color.createConstant …`. **Prerequisite:** extend
  the `Class.coffee` :415 regex so the deferral also matches it — minimal change:
  `"\\.create(\\s|\\()"` → `"\\.create\\w*(\\s|\\()"` (§1.5b). The meta change is gated by the
  build syntax gate + boot smoke + full suite. If this regex touch proves uglier than expected,
  DROP the createConstant item (record in residue) — it is a nice-to-have, not a dependency of
  anything else.

**ShadowInfo** (`src/ShadowInfo.coffee`):
- `# IMMUTABLE` header · `@NO_SHADOW: new ShadowInfo new Point(0, 0), 0` (deferred-static;
  `new ShadowInfo ` space-call matches the first regex) · `@noShadow: -> @NO_SHADOW` (3 call
  sites unchanged) · `keptByReferenceOnDeepCopy: true`.

Gate: `fg presuite`.

### §4.4 Phase 4 — TransformSpec → immutable

Fields: `rotationDegrees`, `scale`, `anchor` (nil ⇒ slot-centre; else an immutable Point),
`claimsSpace` (string). Ctor normalizes `scale <= 0` → 1. All methods already pure.

1. Add withers (NOT `set*` — the name-collision/layering-gate rationale in its :50-55 comment
   stays true): `withRotationDegrees`, `withScale`, `withAnchor`, `withClaimsSpace`, each
   `new @constructor …` routing through the ctor (preserves the scale normalization; CoffeeScript
   defaults fire on null/undefined, so `withAnchor nil` passes through cleanly). Bloch touch:
   `return @ if newValue is currentValue` at the top of each.
2. Convert the 11 write sites to replacement (`@transformSpec = @transformSpec.withScale s`):
   `TransformFrameWdgt.coffee:143` (scale) `:154` (rotationDegrees) `:166` (claimsSpace)
   `:309,:313,:318` (anchor-ride adds) `:334` (anchor → nil);
   `TrackingTransformFrameWdgt.coffee:90` (anchor add) `:93,:98` (anchor → nil)
   `:95` (`withAnchor @transformSpec._anchorFor @bounds`). Preserve each guarded
   `_set*NoSettle` core's semantics exactly — only the write changes shape.
3. Before converting, grep `transformSpec` consumers for anything holding/comparing the INSTANCE
   across a set (expected: none — the island buffer cache keys off geometry generation; `:224`
   reads `.claimsSpace`, read-only).
4. Rewrite the :50-55 mutation-policy comment → `# IMMUTABLE` + wither doc (keep the naming
   rationale). Add `keptByReferenceOnDeepCopy: true`. Serialization: generic props path, only the
   scalars serialize — unaffected by instance replacement.
5. Update `docs/architecture/transforms.md` where it describes the direct-mutation policy.

Gate: `fg presuite` (the macroTransformFrame* SystemTests exercise all 11 sites).

### §4.5 Phase 5 — share-on-copy

- Add `keptByReferenceOnDeepCopy: true` to `Point` and `Rectangle` prototypes. ⛔ NOT
  `getEmptyObjectOfSameTypeAsThisOne` for Rectangle (§1.4 — content walk would mutate the shared
  instance). Duplication/snapshots then share geometry with originals — safe because bounds are
  always replaced (§1.4) and Phase 1 removed every in-place write.
- Broaden the Duplicator comment at `_cloneContentInto` (:192-196, currently "world-level
  singleton") to cover immutable value classes (SheetError precedent).
- Gate: `fg presuite` PLUS both serialization rigs NOW (§6) — this phase changes the `$r`-sharing
  shape of snapshots.

### §4.6 Phase 6 — declarations + docs (docs are a deliverable)

- `# IMMUTABLE` headers: `Point`, `Rectangle` (in the §4.3 header rewrite), `Point3D`,
  `TextEditingState`, `MenuItemSpec` (say SHALLOWLY immutable — holds live widget refs),
  `Grid3D`/`PlaneGrid3D`, the 7 InputEvent base/shape classes (note the two benign oddities from
  §1.6). `Macro`: one line sanctioning the `_linkedCode` lazy memo (Color `_derived_String`
  pattern).
- New `docs/architecture/immutable-value-classes.md` (present tense, no dates): the policy; the
  full immutable-class inventory; the `===` shortcut bar incl. the accepted `-0` note and NaN
  guards; the canonical-constant inventory (`Point.ZERO`, `Rectangle.EMPTY`, `Color.*` +
  permanence, `ShadowInfo.NO_SHADOW`); the two engine traps (§1.4: TAG_BUILDERS needs the
  `populate` no-op; `getEmptyObjectOfSameTypeAsThisOne` only for all-primitive classes — prefer
  `keptByReferenceOnDeepCopy`); enforcement stance (convention + byte-exact suite; deliberately no
  freeze, no gate — with the reasons from §0 decision 1).
- Touch `docs/architecture/serialization-duplication-reference.md` (new `keptByReferenceOnDeepCopy`
  users: Point, Rectangle, ShadowInfo, TransformSpec).

---

## §5 The equality bar + central risks

**Bar: every shortcut's result must be `===`-identical componentwise to what the old code
returned.** Consequences, decided up front:
- `-0` is accepted as `+0` (`-0 === 0` is true; the codebase's own `equals` uses `is`; nothing
  distinguishes them; pixels cannot differ). E.g. `abs()` returning `@` keeps a `-0`; `multiplyBy
  0` returning `ZERO` turns a would-be `-0` into `+0`. Both sides of the bar.
- NaN/Infinity must FALL THROUGH to the old allocation path — hence the `Number.isFinite` guards
  on the ×0 shortcuts and the naturally-NaN-safe comparison guards elsewhere.

Central risks:
1. A shortcut violating the bar → caught by the byte-exact suite. Fix the code, never recapture.
2. A missed mutation site → corrupts a shared instance downstream. Mitigation: §1.2/§1.3 are
   exhaustive grep-verified inventories; re-run the greps (`\.(x|y|origin|corner)\s*[+\-*/]?=`
   scoped to Point/Rectangle receivers) after Phase 2.
3. The `Class.coffee` regex edit (§4.3 Color) touches the meta system → gated by the build syntax
   gate, boot smoke, and the full suite; it is also DROPPABLE.
4. TransformSpec conversion subtly changing settle behavior → the guarded cores' logic is
   untouched (only the write shape changes); macroTransformFrame* tests gate.
5. Share-on-copy changing snapshot structure → serialization rigs gate (run at §4.5, not just at
   close).

---

## §6 Verification protocol

- Per phase: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (~2 min; build + dpr1 suite +
  paint audit). Zero failures, zero churn expected at every step.
- After §4.5 and at close, both serialization rigs (also run as the gauntlet's `serialization`
  leg): from `Fizzygum-tests/`, `node scripts/serialization-roundtrip-headless.js` then
  `node scripts/serialization-file-roundtrip-headless.js`.
- Close: `fg gauntlet` (background + log + task notification; covers dpr1/dpr2/webkit suites,
  apps, paint audit, revisits/census, serialization, parts) AND one `fg homepage` (the production
  snapshot round-trip is the only gate loading a snapshot on a production tree — relevant to
  §4.5). A leg failing in-wave retries once serially; `[shard N] did not start within 90s` is the
  boot-storm infra flake, not a code bug.
- **Never recapture a reference for this arc.** Any pixel diff is a bug in the change.

---

## §7 Rejected alternatives (do not re-attempt)

1. **In-place mutation for perf** — rejected by the Rectangle charter itself (:25-33: "poisons"
   the policy) and by the absence of any measured allocation cost (§3.4).
2. **`Object.freeze` enforcement** (owner-rejected 2026-08-02): non-strict-mode writes no-op
   SILENTLY, so a dev-only freeze makes dev and prod BEHAVE DIFFERENTLY on a violation; prod-wide
   freeze adds ctor cost on ~924 sites for no measured need.
3. **Serializer interning for Point/Rectangle** (Color-style TAG_BUILDERS): unnecessary — identity
   sharing already round-trips as sharing; constants degrade gracefully to shared-but-fresh
   instances; nothing compares by identity. Would also drag in the `populate`-no-op trap (§1.4)
   for zero benefit. Revisit only if snapshot SIZE ever becomes a goal.
4. **`getEmptyObjectOfSameTypeAsThisOne` on Rectangle** — structurally unsafe (§1.4); use
   `keptByReferenceOnDeepCopy`.
5. **`set*`-named setters on TransformSpec** — name-collides with widget self-settling wrappers
   and false-trips the layering gate (its own :50-55 comment); withers avoid this by construction.
6. **A zero-check in Rectangle's all-numbers ctor branch** — adds cost to the hottest construction
   path for a rare hit (§4.3 ⛔).
7. **Immutabilizing `VerticalStackLayoutSpec`/`FrameContentLayoutSpec`** — mutated by design at
   ~19 external sites; they are working layout state, not values (§1.6).

## §8 References

- `docs/architecture/serialization-duplication-reference.md` — engine contracts touched by §4.5.
- `docs/architecture/transforms.md` — TransformSpec context for §4.4.
- `docs/architecture/integer-pixel-placement-and-sizing.md` — why already-integer bounds are the
  common case (§3.3).
- `docs/profiling/results-2026-07-07/prof-framework.report.txt` — the no-measured-need evidence.
- Owner working preferences (memory): ask before commit/push; run straight through with gates,
  ONE end-of-arc review; comments/docs are a deliverable; plans self-contained.

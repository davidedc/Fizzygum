# World-inventory instruments — Arc A of the object-lifetime program

**STATUS: EXECUTED IN FULL + ARCHIVED 2026-08-20.** All phases done; closing `fg gauntlet`
GREEN 16/16 (dpr1 + dpr2 + webkit legs all ran the inventory gate live — the both-engines
requirement verified); zero recaptures across the whole arc. §5.1/§5.2 are the execution
ledger (spike numbers, the gate's find rounds, both D5 prove-it-fails plants). Living truth:
`../architecture/world-lifetime-and-inventory.md`.
Phase 1 (spikes) DONE — §5.1. Phase 2 (D2 roots extraction + D4/D6 portholes) DONE. Phase 3+4
(D1 `WorldInventory` + D6 declarations + D3 wiring incl. per-kind line budgets +
`gate-tokens.js` unification + the `run-sequence` gate-relay repair) DONE; the full dpr1 suite
runs with the gate live at every teardown and ZERO findings. Phase 5 DONE: both D5 plants
proved the gate fails (plant 1: `WORLD_INVENTORY_ESCAPED RectangleWdgt#2 held at
WorldWdgt._d5PlantSet.<setEntry>` — the retainer path names the planted static; plant 2:
`WORLD_INVENTORY_ZOMBIE ... at <registry>` + `instances.*` drift; both plants removed after
their proof runs); docs D7 live (`architecture/world-lifetime-and-inventory.md` + the two
pointer updates + BACKLOG lines). **The gate's find ledger — every one invisible to every
prior gate — is in §5.1/§5.2's round notes: seven product repairs (frame mid-teardown rebuild,
frame off-tree spare, hand gesture bookkeeping, prompt measurer widget, spreadsheet
retain-throwaway, corpse-layout drain guard, and the UNBOUNDED-LRU DoubleLinkedList
corruption affecting all eight caches) plus four test-side orphan repairs and one
tooling repair (run-sequence's swallowed console).**

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-20. All `file:line` refs verified against that day's heads (Fizzygum `051c35e2` + the
Phase-0 working-tree fixes, tests `8992d2c51`); **line numbers drift — the method/symbol name is the
authoritative anchor, re-grep it before trusting a number.**

**Mandate.** Make invisible retained state *measurable, identified, and gated* — not "add another
field-reset". This arc builds the instruments; Arc C (below) uses them to eliminate the underlying
problem by reconstruction. Within this arc the standard is still elimination-shaped: one inventory
engine as a first-class concept with declared exemptions, not a pile of ad-hoc counters.

---

## §0 Orientation

**Framework context.** Fizzygum is a CoffeeScript GUI framework rendered on one canvas; no module
system — every class is a global on `window`; ~510 sources compile in-browser at boot (or ship
precompiled). The SystemTest suite (the sibling `Fizzygum-tests` repo; `fg status` prints the live
count) runs all tests in ONE page per shard, with `world.resetWorld()` as every test's first command.

**The program this plan belongs to.** A three-arc program decided 2026-08-20 with the owner:

- **Arc A (THIS PLAN)** — in-band accounting instruments: a live-object inventory with a post-boot
  baseline, an identity-level escaped/zombie widget diff, gated in the suite on BOTH engines.
- **Arc B** — Chrome-only VM-truth riders: forced GC + `page.metrics()` heap-slope gate,
  `queryObjects` cross-check against the in-band registry, a `FinalizationRegistry` oracle, and a
  heap-snapshot forensic script. Separate plan, to be authored after Arc A lands.
- **Arc C** — the Right Thing reset: the **two-lifetimes doctrine** (PAGE lifetime: code, font
  atlases, interned immutables, probed font metrics; WORLD lifetime: everything else, dying with the
  world), `resetWorld` becomes *destroy + `new WorldWdgt`*, and the reset invariant collapses to
  "WeakRef to the old world + forced GC ⇒ collected". Separate plan; sized by what Arcs A/B find.

**Critical reframe (do not lose this):** today's reset is a *cleanup pass over a reused world
object*, and its guard (`RESETWORLD_INCOMPLETE`) fingerprints only the world's OWN fields — class
statics, collaborator internals, module-scope state, and the DOM are structurally invisible to it.
Arc A's inventory is the conformance instrument for the future two-lifetimes doctrine: everything
alive after a teardown must be either (a) part of the post-boot baseline, (b) a declared
page-lifetime store, or (c) a bug.

**Phase-0 precondition.** Three repairs were made in the same session that authored this plan and
are assumed landed (verify with `git -C <abs>/Fizzygum log --oneline -3`, else re-apply):
`ToolTipWdgt` pending-timeout self-removal on fire; dead `Class.allClasses` deleted; the
`@superclass`→`@superClass` fix in `Class.coffee` that makes `Class.subClasses` actually populate.

## §0.5 Cold-execution protocol

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status` (NEVER `./fg`; absolute path always).
   Expect all repos clean or explainably dirty, build FRESH or rebuild.
2. Read this plan fully. Re-grep every symbol you are about to touch (§1 lists them).
3. Execute phases IN ORDER (§6). Phases 1 is scratch-only; 2–5 touch src/harness and each ends at a
   named gate. Iterate with `fg presuite`; close the arc with `fg gauntlet`.
4. Long ops: launch ONCE in background redirecting to a log; peek `/tmp/fg-<cmd>.verdict` at a
   ~5-min cadence. Never pipe a gating fg call through `tail`/`grep`. A running op OWNS src/tests —
   edit only docs/memory while one runs.
5. Ad-hoc Node probes go under `Fizzygum-tests/.scratch/` (gitignored) — NOT the session scratchpad
   (`require()` resolves from the script's dir; scratchpad probes die with MODULE_NOT_FOUND).
6. Owner rules: never commit/push autonomously — propose message(s) and wait. No conclusions before
   evidence (never write "passes"/"zero drift" before the run). Plans/docs stay present-tense.

## §1 Current state (the machinery this plan builds on) — verified 2026-08-20

**The reset.** `WorldWdgt.resetWorld` lives HARNESS-side
(`Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee`, grafted onto the core
prototype at boot): `_softResetWorld()` → settle-wrapped `_resetWorldNoSettle()` (pristine-look
restore, calls the shipping core `WorldWdgt._teardownWorldStructureNoSettle`, `WorldWdgt.coffee`
~:2687) → `storageSorter._auditStorageNoSettle()` → `_auditWorldResetCompletenessNoSettle()`.
The world OBJECT is reused; no teardown resets the seven `world.cacheFor*` LRU caches
(`WorldWdgt.coffee` ~:575–581), the SWCanvas font-atlas store, or any class-level static.

**The existing ratchet** (`WorldTestSupport.coffee`): `_fingerprintWorldStateNoSettle` (~:380)
sweeps own props + the whole prototype chain reading EFFECTIVE values;
`_summariseWorldStateValueNoSettle` (~:346) coarsens to `Set(n)`/`Map(n)`/`Array(n)`/
`<Class>:live|DESTROYED`/`object:<Ctor>`; `_isDerivedCacheFieldName` (~:366) exempts the strict
`cachedFoo`/`checkFooCache` shapes BY RULE; `WorldWdgt._worldStateAuditExemptions` (~:303, installed
via `@staticMembersToInstall`) is the named-with-reason allowlist; first teardown = the pristine
baseline; drift emits `RESETWORLD_INCOMPLETE`, gated by both runners. **Its blind spots are this
arc's target: statics, collaborator internals (`"ClassName:live"` hides all growth), module-scope
state, DOM, and identity (it counts, it cannot name a leaked widget).**

**The per-class instance registry (the strongest existing primitive).** `src/meta/Class.coffee`
(~:440) stamps `window.<Class>.instances = new Set` on every class; `Widget.registerThisInstance`
(`src/basic-widgets/Widget.coffee` ~:447) adds each widget to its WHOLE superclass chain's Sets;
`unregisterThisInstance` (~:458) is called only from `_destroyNoSettle` (~:693). So
**`Widget.instances` is a complete live registry of every non-destroyed widget** — nothing reads it
for accounting today. Non-Widget classes carry permanently empty `instances` Sets (only Widget
implements registration) — that emptiness is the class-enumeration marker we use.
Also: `@instancesCounter` (~:24, never reset, lifetime allocations) vs
`@lastBuiltInstanceNumericID` (~:28, zeroed per class by `WorldWdgt.fullDestroyChildren`'s
`Object.keys(window)` suffix sweep, `WorldWdgt.coffee` ~:2438).

**The liveness walk** (`WorldWdgt.coffee` ~:3087–3140): `anyReferenceOrWireIntoWdgt` =
`_livenessEdgesIntoWdgt(w).length > 0`; `_livenessEdgesIntoWdgt` builds roots
(`[@, @hand]` + non-null `Serializer.WORLD_APP_SLOTS` slots + `@simpleEditorTemplates` + bin
viewport contents children + shelf children) and recurses `_collectLivenessEdgesIntoWdgtWithin`
over CONTAINMENT (`children`) + declared `graphEdgesOut()` edges (`flow`/`reference` count,
`command` doesn't). `_severLivenessEdgesIntoWdgtNoSettle` consumes the same enumeration — the
one-enumeration principle (commit `466ba9a6`) this plan extends to the inventory.

**Walker prior art.** `Serializer._buildObjectTable` (`src/serialization/Serializer.coffee` ~:249):
identity-`Map` cycle handling, arbitrary `for own` props, per-class `serializationTransients` skip
protocol, `NativeValueKinds` duck-typing (canvas-like works on BOTH backends) — but it THROWS on
unknown constructors and deliberately never walks the world's own props (~:106 comment: canvases,
contexts, listener closures). `Duplicator._cloneContentInto` (`src/duplication/Duplicator.coffee`
~:182) has the matching cache-skip regexes (`/^cached[A-Z]/`, `/^check[A-Z].*Cache$/`,
`childrenBoundsUpdatedAt`, `/^_islandBufferSource/`). The inventory walker BORROWS these rules but
is a new, count-only, never-throwing engine.

**Module-scope state that needs accessors** (`src/boot/extensions/SWCanvasElement-extensions.coffee`
~:79–99): `swCanvasAtlasRequested`, `swCanvasMissingAtlases` (never cleared),
`swCanvasColdGlyphWidgets`, `swCanvasPoisonedCacheKeys` (hold LIVE WIDGET REFS between a cold glyph
draw and the atlas refresh; drained in `doRefresh`). Font atlases: vendored
`AtlasDataStore` private static Map (`vendor/swcanvas/swcanvas.js` ~:3524) — `clear()` exists,
nothing calls it; entries are decoded ImageData; page-lifetime BY DESIGN (the teardown's
`resetToBootInputMode` deliberately carries the atlas-warmth-dependent `minimumFontHeight` probe).

**Harness rails** (`Fizzygum-tests/scripts/`): the gate-token list is DUPLICATED verbatim in
`run-all-headless.js` (~:195) and `run-macro-test-headless.js` (~:358) — eight `t.includes(...)`
tokens (`NON_FINITE_GEOMETRY` … `CACHED_DERIVATION_DIVERGED`). `AUDIT_PRELUDE`/`AUDIT_DIR`
env-injected preludes and the `storage-audit-prelude.js` resetWorld-wrap show the per-test seam
pattern; `run-paint-audit.js` shows the accumulate-in-page/read-once pattern. There is ZERO
CDP/heap/memory measurement anywhere (Arc B's territory). WebKit (`--browser=webkit`) shares 100%
of runner code ⇒ everything in THIS arc must be plain in-page JS.

## §2 Why it is shaped this way

The ratchet (2026-07-29, `docs/archive/resetworld-teardown-completeness-audit-plan.md`) was built to
kill a specific recurring bug class — world-field state leaking between same-page tests — after
reactive patching left 14 undiscovered holes. It deliberately stayed SHALLOW (a per-teardown own-props
sweep) because its first deep-ish cut fired 1469 times on a green suite (own-ness vs effective-value
lesson). Nobody has ever needed to count objects: leaks surfaced only when they broke determinism.
The owner now wants the general capability — "put the world back to just-after-boot, and develop
accounting techniques usable at any time" — which the ratchet's shape cannot grow into (it is
world-field-keyed by construction).

## §3 The distilled argument

- The **registry already exists** (`Widget.instances`); the **walker knowledge already exists**
  (Serializer/Duplicator skip rules, `NativeValueKinds`); the **seam and gate rails already exist**
  (resetWorld tail, console tokens). Arc A is 90% assembly of proven parts — the new engineering is
  the report vocabulary, the exemption model, and the prove-it-fails discipline.
- Identity beats counts: "escaped widget `TextWdgt#14`, zombie `MenuWdgt#3` retained at
  `world.hand.mouseOverList`" is actionable; "widget count +2" is not.
- Both-engines coverage matters (the webkit gauntlet leg would silently skip any CDP approach), so
  the in-band tier must stand alone; Arc B only ADDS the closure-visibility the VM alone has.
- Do it before Arc C: reconstruction needs an instrument that can certify "a reset world ≡ a booted
  world" — that instrument is this inventory diffing against its boot baseline.

## §4 Deliverables (design decided; executor implements, does not re-litigate)

### D1 — `WorldInventory`, the engine
New class `src/dev-tools/WorldInventory.coffee` (part `dev-tools` — present on the harness page,
which presets `FIZZYGUM_EAGER_ALL_PARTS`; lazily loadable in dev; NOT in the `homepage` profile —
acceptable for an instrument, Arc C may promote it). **Name is deliberate: NOT "census"** — `fg
census` is the existing arrange-idempotence leg; reusing the word would make gauntlet output
ambiguous.

A plain collaborator (no widget). API:

```coffee
class WorldInventory
  # walks the reachable object graph and returns a REPORT: a flat {dimensionKey: number} map
  # plus identity lists. Read-only walk: never calls methods, never touches pixels.
  takeInventory: ->
  # stores the current report as the baseline (harness calls this at the FIRST teardown)
  snapshotBaseline: ->
  # diffs a fresh report against the baseline -> [{key, baseline, now}] after exemptions
  diffAgainstBaseline: ->
```

**Roots:** `world`; every class object found by the marker sweep
(`Object.keys(window)` where `typeof window[k] is 'function' and window[k].instances instanceof
Set`) — sweeping each class's OWN static props; the D4 accessors; `window.menusHelper`;
`window.demoMenus`. `SourceVault` is counted (entry count) but not walked. DOM is counted (D1
dimensions), never walked. ⚠ The `extend` boot helper copies parent statics onto subclasses
(`boot/globalFunctions.coffee`, grep `extend`), so a naive static sweep double-counts inherited
copies — sweep `Object.getOwnPropertyNames(ctor)` but attribute a static to the class only if
`ctor.hasOwnProperty(name)` AND the value differs from the superclass's same-named own value, or
simpler: record per-class regardless and let the DIFF absorb it (baseline has the same copies; a
LEAK still shows as a delta on every class it's copied to). Decide in S1 by looking at the noise;
the diff-absorbs-it route is the default.

**Traversal rules** (each is a lesson already paid for):
- identity `Set` of visited objects; recurse own ENUMERABLE data props (`for own`), **skip accessor
  properties** (check `Object.getOwnPropertyDescriptor(obj, name).get` — a getter may have side
  effects; derived anyway), try/catch every read.
- functions are counted (`objects.Function`) but never walked; skip the serializer's known transient
  names via `Serializer.transientsForClass` where the object is a recognized class instance, plus
  the Duplicator's cache-shape regexes for everything.
- classify with `NativeValueKinds`-style duck tests; canvas-like ⇒ count + `width*height` pixels,
  never `getContext`/`toDataURL`; unknown constructor ⇒ tally under `objects.<ctorName>` and WALK it
  (count-only walkers don't throw — that is the whole point).
- Map/Set: iterate keys AND values (the `widgetsToBeHighlighted` Map-keyed-by-widget lesson).
- **typed arrays are LEAVES** (S1's decisive finding): `ArrayBuffer.isView(v)` or `ArrayBuffer` ⇒
  `typedArrays.count`/`typedArrays.bytes`, never enumerate — `Object.keys` on the world canvas's
  pixel buffer alone yields 1.69M index keys and multiplies the walk cost ~40×.

**Report dimensions** (stable keys; keep the vocabulary SMALL):
`objects.<Ctor>` counts · `containers.arrayElements`/`.setEntries`/`.mapEntries` totals ·
`canvases.count`/`canvases.pixels` · `strings.count`/`strings.chars` · `typedArrays.count`/`.bytes` ·
`dom.headScripts`/`dom.bodyChildren` · `instances.<Class>` (= `instances.size`) ·
`statics.<Class>.<field>` (size of each own static Set/Map/Array; numbers too — the monotonic
counters gate via their D6 policy) · `world.<field>` (size of each of the world's own container
fields, incl. the `cacheFor*` LRUs — needed so the D6 `bounded <cap>` policy has a row to check) ·
plus identity lists: `escapedWidgets` (in `Widget.instances`, not `destroyed`, NOT reached by the
containment walk from the D2 roots) and `retainedZombies` (`destroyed: true` but reached by the
property walk — report the PATH; carry path strings during the walk, keep only offenders').
⚠ Gating tiers (S1/S2's noise verdict): the identity lists, `instances.*`, per-store size rows
checked against D6 policy, and `dom.*` GATE; the bulk aggregates (`objects.*`, `strings.*`,
`canvases.*`, `containers.*`, `typedArrays.*`) are REPORT-ONLY — every bounded-cache admission
moves them, so gating them would be the 1469-storm again.

### D2 — one shared roots enumeration
Extract `_livenessEdgesIntoWdgt`'s root-building (`WorldWdgt.coffee` ~:3096–3103) into a public
`WorldWdgt.graphLivenessRoots()` consumed by: the liveness query/sever pair AND the inventory's
containment reachability. One enumeration ⇒ trash logic and leak accounting structurally cannot
disagree about what a root is. (Do NOT try to unify with `StorageSorter._runClassifier`'s phases in
this arc — file a BACKLOG line instead.)

### D3 — harness wiring + gate
- `WorldTestSupport.resetWorld` grows one line after the existing audit:
  `@_auditWorldInventoryNoSettle()` — a new method in `WorldTestSupport.coffee` beside the ratchet:
  first call `snapshotBaseline()`, later calls emit ONE
  `console.error "WORLD_INVENTORY_DRIFT <key> baseline=<v> now=<v> -- <remedy hint>"` line per
  surviving diff row, and one `WORLD_INVENTORY_ESCAPED <uniqueIDString>` /
  `WORLD_INVENTORY_ZOMBIE <uniqueIDString> at <path>` per identity offender. Guard the whole method
  with `return unless WorldInventory?`.
- **Unify the duplicated token list**: new `Fizzygum-tests/scripts/lib/gate-tokens.js` exporting the
  array; `run-all-headless.js` + `run-macro-test-headless.js` consume it; add the two new tokens.
  Grep `smoke-boot-headless.js` for the same list before assuming it has one.
- Frequency: every teardown, unless S1 measures the walk > ~200 ms — then every Nth + the shard's
  last teardown, with the N recorded here.

### D4 — accessors for module-scope state
In `SWCanvasElement-extensions.coffee`, export ONE read-only accessor (e.g.
`window.swCanvasTextStateForAudit = -> {atlasRequested: …, missingAtlases: …, coldGlyphWidgets: …,
poisonedCacheKeys: …}`) so the inventory can reach the module vars. Do NOT restructure ownership
here — that is Arc C's job; this is a porthole, and it must be added to the report dimensions.

### D5 — prove the gate FAILS (mandatory, per standing case law)
Two planted defects, run against the full suite, BOTH must fail it; then remove the plants:
1. a static `Set` on some class retaining one widget a test created (⇒ `statics.*` drift + an
   `escapedWidgets` entry);
2. comment out `unregisterThisInstance` in `_destroyNoSettle` (⇒ `instances.*` drift + zombies).
Silence before this proof is NOT evidence (the audit-guard lesson: a first cut once fired 1469
times; the opposite failure — a guard that can never fire — is just as likely).

### D6 — the page-lifetime declarations (seed of Arc C's manifest)
A declared table in `WorldInventory` naming every store ALLOWED to differ from baseline, each with a
reason and a growth policy the diff enforces (`stable` | `bounded <cap>` | `monotonic-ok`):
the seven `world.cacheFor*` LRUs (bounded by their own caps), `Color._cache` (bounded 300), the
`Object::hashCode` closure cache (bounded 16384 — needs its own tiny accessor, same shape as D4),
`swCanvasAtlasRequested`/atlas count (monotonic-ok), `SourceVault` entry count (grows only on
lazy-part load), `instancesCounter` per class (monotonic-ok by design). Everything NOT declared must
be `stable` across teardowns. Reuse the `cached*`/`check*Cache` SHAPE rule rather than listing those.

### D7 — docs + program bookkeeping
New `docs/architecture/world-lifetime-and-inventory.md`: the two-lifetimes doctrine (stated as
DIRECTION, with Arc C as the enforcement arc), what the inventory measures, the exemption model, how
to read a `WORLD_INVENTORY_*` failure. Update `docs/architecture/lint-and-static-checks.md`'s
runtime-gates section and `Fizzygum/CLAUDE.md`'s ratchet paragraph (one sentence each — the
inventory gate exists and where its doc lives). BACKLOG lines: StorageSorter-roots unification
(D2); the `hasProp`/`indexOf`/`slice` window leakage; `fullDestroyChildren` mutating `Automator.*`
statics; Arc B and Arc C pointers.

## §5 Spikes (Phase 1 — scratch only, no src edits) — EXECUTED 2026-08-20, results below

- **S1 — cost + noise.** `Fizzygum-tests/.scratch/inventory-spike.js`: puppeteer-boot the built
  harness page, `page.evaluate` a minimal inline walker (the D1 rules), print: wall time, visited
  count, report size, and the report at three moments (post-boot, after opening/closing an app, after
  a manual `world.resetWorld()`). Deliverables: the ms number that decides D3 frequency, and the
  first exemption list (which dimensions legitimately move — expect: atlas/LRU growth, per-cycle
  transients like `swCanvasColdGlyphWidgets`, damage bookkeeping).
- **S2 — identity ground truth.** In the same probe: diff `Widget.instances` against the containment
  walk from `graphLivenessRoots()`-equivalent roots on a VIRGIN world. Expected zero escaped; every
  discrepancy is either a legitimate off-tree citizen to add to the roots/exemptions (caret?
  templates? tooltip in flight?) — enumerate them here in the plan when found — or a real pre-existing
  leak (jackpot: file/fix separately, do not silently exempt).
- **S3 — walker safety.** Assert the walk is side-effect-free: run it twice back-to-back plus once
  mid-frame; the world must render identically after (screenshot equality on the probe page) and the
  second walk's report must equal the first's.

### §5.1 Spike results (probes: `.scratch/inventory-spike.js`, `-forensics.js`, `-walk-profile.js`, `-bigobjects.js`)

**S1 — cost: 2–6 ms per full walk** (1.5k visited on a pristine world, 6.3k after app activity;
marginal cost ~0.02 ms/object; the class/static sweep over 497 classes / 5.7k statics is 1–5 ms).
⚠ ONE rule makes this possible: **typed arrays are LEAVES** — `Object.keys` on a typed array yields
every INDEX as a key (the world canvas's `Uint8ClampedArray` alone is 1.69M keys = 2.1M descriptor
reads = ~170 ms, 96% of an unguarded walk). Classify `ArrayBuffer.isView(v)` / `ArrayBuffer` as
`typedArrays.count`/`typedArrays.bytes`, never enumerate. **D3 frequency decision: every teardown,
full walk, metaobject recursion INCLUDED** (recursing `Class`/`Mixin` instances adds ~2k visits at
negligible cost) — the every-Nth relief valve is unnecessary.

**S2 — identity: ground truth achieved, plus a real leak found.**
- The inventory's containment roots are the liveness roots **PLUS `world.binWdgt` and
  `world.shelfWdgt` themselves** — the liveness walk excludes those two on purpose (bin residency
  must not count as an inbound edge), but they and their chrome (viewport, scrollbars, label —
  10 widgets) are accounted-for citizens to the inventory. With those two added: pristine world =
  **0 escaped, 0 registry zombies** — exact agreement between `Widget.instances` and containment.
  ⇒ D2's `graphLivenessRoots()` stays as-is for the liveness pair; `WorldInventory` consumes it
  and appends the two off-tree containers.
- **JACKPOT (real product leak, fires on EVERY frame-window close) — TWO layers, both repaired
  2026-08-20 (the arc's precondition for the Phase-4 zero-drift gate):**
  1. *Mid-teardown rebuild:* `Widget._fullDestroyNoSettle` destroys children first, then self; when
     the cascade reaches a frame's `@contents`, the child's `_destroyNoSettle` fires
     `@parent._beforeChildDestroyed` → `FrameWdgt._resetToDefaultContents`, which re-titles the bar
     ("empty internal window" `StringWdgt`s) on the already-destroyed, already-detached
     `FrameBarWdgt` — outside the `until @children.length == 0` loop's reach. The
     `_beingFullDestroyed` flag ALREADY existed for exactly this teardown window (the framed
     citizens guard their `_resetToDefaultContents` with it against a non-terminating
     rebuild-destroy loop) but the base hook never consulted it. Repair:
     `FrameWdgt._beforeChildDestroyed` returns early under the flag (the citizens' own guards stay
     — they defend the non-termination case at their layer); the legitimate path — contents
     destroyed out from under a LIVING frame — keeps rebuilding.
  2. *The off-tree spare:* every `FrameWdgt` constructor builds `@defaultContents = new
     FrameContentsPlaceholderText` even when real contents are supplied; the spare then lives
     UNMOUNTED (not a child) for the frame's whole life, so no destroy cascade ever reaches it and
     `Widget.instances` pins it forever — one leaked placeholder per frame constructed-with-contents.
     Repair: `FrameWdgt._fullDestroyNoSettle` destroys the spare after `super` when it is not
     already destroyed (a MOUNTED spare died as a child in the loop).
  Verified by re-running the spike against the repaired build: live instances 12 → (app open,
  widget create/destroy) → 12 after teardown, **0 escaped, 0 registry zombies**, every
  `instances.*` drift row gone (57 remaining drift keys = exactly the two exempt families).
- Bonus confirmation of the marker-sweep rider: `FrameContentsPlaceholderText.lastBuiltInstanceNumericID`
  is never zeroed by `fullDestroyChildren`'s suffix sweep — the class name does not end in `Wdgt`.
- The reporter must read `@instanceNumericID` passively (assigned at construction by
  `assignUniqueID`); never call anything that could allocate.

**S3 — safety: all green.** Two synchronous back-to-back walks return identical reports; screenshots
are byte-stable across walks, including one run from inside a `requestAnimationFrame` callback
interleaved with the world's own loop; zero page console errors during all probe runs.

### §5.2 Live-gate probe results (`.scratch/inventory-live-gate-probe.js`, the real class through the real seam)

The wired gate, on the built harness page: baseline taken at the first teardown; clean app
activity + teardown ⇒ **zero** `WORLD_INVENTORY_*` lines; a planted static-`Set` retainer ⇒
4 drift lines + the exact `WORLD_INVENTORY_ESCAPED RectangleWdgt#1`; unplanting ⇒ silence
returns; the real `takeInventory` costs ~6 ms. Two further retention classes surfaced and were
resolved on the way to that silence:
- **Teardown-seam paint-queue zombies (REPAIRED in core):** `world.widgetsWithMaybeChangedPaintBounds`
  / `...FullPaintBounds` (per-cycle damage queues, drained only by the NEXT `_repaintDamagedRects`)
  still held every widget `fullDestroyChildren` had just destroyed — ~16 dead refs at the audit
  seam, hidden from the ratchet by its own per-cycle-transient exemption. The teardown core now
  drops the DEAD entries (a filter, not a clear — a blanket clear would erase the world's own
  whole-screen damage mark, posted by the reset caller before the teardown runs, and the reset
  would repaint nothing).
- **Cold-glyph window (DECLARED, not walked):** `swCanvasColdGlyphWidgets` transiently holds a
  widget a teardown just destroyed (until the atlas-warm refresh drains the list wholesale; its
  consumer `noteColdGlyphRegionsWarm` already skips destroyed/detached entries — verified, no
  latent bug). The inventory counts both cold-window stores but does not walk them, and declares
  them per-refresh transients. Module-state ownership stays an Arc C question, per D4's remit.

**Suite-scale noise verdict — the gate peeled the onion in rounds (each run dies at its first
find and reveals the next):**
- *Round 1:* exactly ONE undeclared store across 306 tests — `statics.WorldWdgt.timeOfEventBeingProcessed`,
  the current-event time register (a world STATIC, hence ratchet-invisible: precisely this
  instrument's target blind spot). Repaired in the teardown core: back to the declared
  "no event being processed" `undefined` (consumers read it during event processing or during a
  live gesture the teardown kills; the next world's synthetic event clock may even rewind).
- *Round 2:* the HAND's gesture bookkeeping — `world.hand.wdgtToGrab`, `.mouseDownWdgt`, and the
  armed `doubleClick`/`tripleClick` records all retained DESTROYED widgets across the seam (the
  hand outlives the teardown; with the event clock rewinding, a stale armed record could even
  recognize a multi-click across worlds). Repaired as ONE verb owning the family —
  `ActivePointerWdgt._forgetGestureBookkeepingNoSettle` (grab/press/drag-embed refs, linger trio,
  mouseOverList, both recognizers) — called from the shared teardown core, so the snapshot-load
  path (which never runs `_softResetWorld`) is covered too. Plus two declarations:
  `WorldWdgt.immutableBackBufferGeneration` (generation counter, monotonic-ok) and
  `statics.Automator.state` — the latter pushed onto `pageLifetimeStores` FROM THE HARNESS seam,
  because the shipping instrument must not name harness classes (the part-edges gate rightly
  refused the dev-tools → harness edge, even inside a regex literal).
- *Round 3 — the prompt-measurer leak (REPAIRED):* every prompt shown leaked one live,
  parentless `StringWdgt` — `StringFieldWdgt.calculateAndUpdateExtent` builds a throwaway
  MEASURING StringWdgt to derive natural width and drops it, and the instances registry pins it
  forever (`escapedWidgets` with retainer `<unreached-by-property-walk>` = the registry is the
  only holder; the escaped-path enhancement that reports each escape's retainer landed with this
  round). Repair: the measurer is destroyed after the read. Three suite tests were each leaking
  1–2 of these per run (inspector add/rename prompts, color/transparency prompts).
- *Round 3b — the paint-queue filter had to be the teardown's LAST act:* destroying the bin/shelf
  residents (`binWdgt.empty()`, at the teardown's end) RE-MARKS the damage queues — a dying
  widget posts damage so its pixels get erased — so the dead-entry filter moved after them
  (found via a closed-to-bin rotated-island window re-zombifying the queue).
- *Round 4 — 🏆 the LRU corruption (REPAIRED, affects ALL EIGHT caches):* `statics.Color._cache`
  read 508–543 against its capacity of 300. `DoubleLinkedList.insertBeginning` never cleared the
  node's own `pre`/`next`, so `moveToHead` (every cache `get`) left a stale back-pointer; the
  next removal of that node rewires the wrong neighbor, `tailNode` ends up naming an
  already-evicted key, eviction silently no-ops, and — the size check being exact equality —
  the cache grows UNBOUNDED (measured: capacity 20 → size 4999 under set/get churn; fixed:
  exactly 20). Every LRU in the system (the seven `world.cacheFor*` + `Color._cache`) was
  unbounded under real usage — a memory leak in every long-running production session.
- *Round 6/7 — test-side orphans (macros REPAIRED):* `macroSpecifiedBackgroundActuallyPaints`
  and `macroSpreadsheetColorCell` (assertion-probe widgets never mounted → now destroyed),
  `macroHiddenShadowChildLeavesNoBand` (`removeFromTree` is the behaviour under test; the live
  orphan is now destroyed after the final assertion), `macroSavedDocumentShortcutIcon` (the
  fixture used the ALIAS verb on a never-mounted DocumentWdgt — 48 widgets leaked; the real
  save flow shelves its referent — the fixture doc is now destroyed after the last screenshot).
- *Round 9 — the corpse-layout drain (REPAIRED in core):* the settle flush between the teardown
  and the audits drained a layout queue still holding teardown-destroyed widgets — laying out
  corpses, whose `_reLayout` re-marks paint damage on them and re-zombifies the paint queues
  AFTER the teardown's filter. `recalculateLayouts`' sweep now drops destroyed entries (they
  have no layout to settle). Found via a cadence-dependent single zombie whose token line the
  condensed presuite log hid — the full line lives in `/tmp/fg-<leg>.log`, and the runner's
  end-summary label "GEOMETRY-VIOLATION (non-finite/non-integer)" is a legacy misnomer that
  covers EVERY gate token.
- *Round 5 — two more escape mechanisms (REPAIRED):* (a) the spreadsheet's retain-and-remount
  reconcile (`SimpleSpreadsheetWdgt._reconcileCellNoSettle` branch 1) "discarded" each recompute's
  just-constructed throwaway widget by dropping the reference — one full slider assembly leaked
  PER RECOMPUTE of a widget-valued cell (46 widgets in one test); the throwaway is now destroyed.
  (b) a TEST-side pattern: assertion-probe widgets a macro constructs but never mounts
  (`macroSpecifiedBackgroundActuallyPaints`) are unreachable to the teardown — probes must
  `fullDestroy()` themselves; the macro now does.
- ⚠ *Attribution semantics:* a `WORLD_INVENTORY_*` line fires during a test's OPENING reset, so
  the runner attributes it to the test being loaded — the LEAKER is the PREVIOUS test on that
  shard page (same semantics as the ratchet). Reproduce in isolation before believing the name —
  and reproduce with a tool that can SEE: `run-sequence-headless.js` swallowed console errors
  entirely until this arc taught it the shared gate-token relay (it now fails on any token,
  which its state-leak-reproduction contract always implied).
The two-tier gating model (identity + declared stores gate, bulk aggregates report-only) held at
suite scale with zero false positives, and the instrument's finds to date — three distinct leak
mechanisms plus an unbounded-cache defect nothing else could see — are its own proof of value.

**Exemption seed** (teardown-to-teardown diff with app activity in between: 63 drifting keys,
`.scratch/inventory-drift-B-to-D.json`), in three families:
1. **Monotonic-by-design counters** (declare `monotonic-ok` per D6): every
   `statics.<Class>.instancesCounter` / `.lastBuiltInstanceNumericID`, and
   `WorldWdgt.frameCount`/`geometryVersion`/`structureVersion`/`visibilityVersion`.
2. **Bounded-store fallout:** the seven `world.cacheFor*` LRUs (caps 10–1000; measured filling to
   15–144 entries) retain back buffers of DESTROYED widgets and drive **all** the bulk aggregate
   drift — `objects.*` (+17 SWCanvas context stacks: `Surface`/`Rasterizer`/`StateStack`/…, +3.4k
   plain Objects), `canvases.*`, `strings.*`, `containers.*`, `typedArrays.*`, interned-`Color`
   count. ⇒ **Design consequence for D1/D3: bulk aggregates (`objects.*`, `strings.*`,
   `canvases.*`, `containers.*`, `typedArrays.*`) are REPORT-ONLY diagnostics, never gated** — the
   gate's teeth are the identity lists (escaped/zombies), `instances.<Class>`, per-store sizes
   (`statics.<Class>.<field>` and a new `world.<field>` container-size dimension covering the
   `cacheFor*` LRUs) checked against their D6 policy, and `dom.*`.
3. **The real leak** (family 2 of S2 above): `instances.*` rows + escaped identities — vanish once
   the repair lands; the Phase-4 zero-drift gate depends on it.

## §6 Execution order and gates

| Phase | Work | Gate |
|---|---|---|
| 1 | S1–S3 spikes | numbers + exemption seed recorded IN THIS DOC (§5) |
| 2 | D2 roots extraction + D4/D6 accessor portholes | `fg presuite` |
| 3 | D1 `WorldInventory` + D6 declarations | `fg presuite` + re-run S1 probe against the real class |
| 4 | D3 wiring + token-list unification | full `cd Fizzygum && ./build_and_test.sh` with ZERO drift (exemptions added ONLY with written reasons) |
| 5 | D5 prove-it-fails, then docs D7 | `fg gauntlet`; then the close-arc ritual (memory + docs + proposed commits, owner approval) |

Keep `RESETWORLD_INCOMPLETE` untouched — Arc C decides its fate. Commit checkpoints per the owner's
standing grant: commit-and-continue while gates pass is NOT granted here by default — propose
messages and wait (Phase-0 of this program already has a pending commit; coordinate with it).

## §7 Central risks

- **False-positive storm** (the 1469 lesson): mitigated by S1-first, count-summaries not identities
  for bulk dimensions, shape-rule exemptions, and per-cycle-transient discovery before wiring.
- **Walk cost on the gauntlet's dpr2/webkit legs** (heavier pages): S1 measures on dpr1; multiply
  by ~2 mentally; the D3 frequency knob is the relief valve.
- **Getter side effects / paint-state mutation**: excluded by the skip-accessors rule + S3 proof.
- **Report-key instability across engines** (ctor names differ for host objects): keep host-object
  classification duck-typed (`canvas-like`, `image-like`), never `constructor.name`, for anything
  not a Fizzygum class. Cross-engine parity is exactly what the webkit suite leg then verifies.
- **The harness page is not the production page**: the inventory baseline is per-page by
  construction (same convention as the ratchet); never compare across pages.

## §8 Rejected alternatives (do not re-attempt blind)

- **CDP-based per-test accounting** — no per-test callback exists runner-side (only a 1 Hz poll);
  Chrome-only, so the webkit leg goes blind. Deferred to Arc B as riders, by design.
- **Extending the Serializer walker in place** — its contract is THROW on the unknown and skip the
  world; a count-only mode would fork every guard in it. Borrow its knowledge, keep engines separate.
- **Widening `_fingerprintWorldStateNoSettle` instead of a new engine** — it is world-field-keyed by
  construction; statics/identity/paths do not fit its key space. It stays as-is beside the inventory.
- **Page reload per test as the "true reset"** — ~3.2 s compile-at-boot per shard page ×
  full-suite scale, and cold caches change screenshot timing (`DETERMINISM.md`); rejected.
- **`WeakRef`/`FinalizationRegistry` in this arc** — meaningless without forced GC; that is Arc B.

## §9 References

- Memory: `resetworld-state-leak-between-tests`, `teardown-shared-core-arc`,
  `no-conclusions-before-evidence`, `plans-must-be-fully-self-contained`.
- Docs: `docs/archive/resetworld-teardown-completeness-audit-plan.md` (the ratchet's case law),
  `docs/archive/teardown-shared-core-plan.md`, `docs/architecture/lint-and-static-checks.md`,
  `docs/architecture/serialization-duplication-reference.md`, `Fizzygum-tests/DETERMINISM.md`.
- Code anchors (re-grep, don't trust lines): `_auditWorldResetCompletenessNoSettle`,
  `_fingerprintWorldStateNoSettle`, `_worldStateAuditExemptions`, `registerThisInstance`,
  `unregisterThisInstance`, `_livenessEdgesIntoWdgt`, `graphEdgesOut`, `_buildObjectTable`,
  `_cloneContentInto`, `swCanvasColdGlyphWidgets`, `gate-tokens` (D3, to be created).

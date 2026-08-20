# World reset by reconstruction — Arc C of the object-lifetime program

**STATUS: PLAN AUTHORED 2026-08-20; Phases 1 AND 2 EXECUTED same day.**
Phase 1 (spikes, results in §5): verdict GO — S1: reconstruction +0.4–0.7 % suite
wall-clock; corpse cycle-tail paint-inert by measured mechanism; old-world
collectibility blocked SOLELY by the prototype-shared arrays (ablation-proven); warm
`minimumFontHeight` re-probe flips 9→10. S3: per-test cache cold-start is
reference-preserving and FREE (307/0/0 twice, injection proven 1:1).
Phase 2 (all EIGHT pre-repairs, each individually `fg presuite`-gated green, most with
their own acceptance probe): D-P2a per-instance containers (identity probe: all OWN,
prototype undefined; `otherTasksToBeRunOnStep` retired) · D-P2b probe memo (boot value
9 memoized, zero re-probes) · D-P2c teardown hygiene (probe: tooltip timers defused,
cold-glyph corpse dropped with live control kept, poisoned-key latch re-keys onto a
fresh cache via the recurrent installer) · D-P2d `PartsRegistry.ingestedParts` (probe:
`authoring`+`app-kit` recorded, control `fizzytiles` untouched, fresh registry reads
truth; in-flight-load residual NAMED for Phase 3 in §4) · D-P2e detach verb shipped
(23=23 add/remove symmetry verified) · D-P2f door guards + Automator-toggle hook +
helper-globals contract (BACKLOG lines closed; helpers proven LOAD-BEARING) ·
D-P2g named constructors (513/513 byte-verified emit; node + browser heap-snapshot
proofs: widgets named, `world` className correct; `heap-forensics --selftest` green;
`fg homepage` green — the precompiled image carries the names) · D-P2h Automator
page-lifetime (`Automator.current`; constructor chain proven idempotent).
Phase-closing 18-leg gauntlet 2026-08-20: **GREEN 18/18, 7m27s** (dpr1/dpr2/webkit
suites 307/0/0 · apps · parts · menusweep · pinsweep · graph:PASS-serial-only — the
known in-wave load-flake shape, machine at loadavg 23.7 · paint · tiernaming · settle ·
capstone · refs · revisits · census · serialization · storage · vmtruth:PASS(92s)).
NEXT: Phase 3 (the seam + the flip, ONE commit) → 4 (gates + doctrine) → 5 (promotion).
Owner checkpoint stands before the Phase 3 flip commit.

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-20 against heads Fizzygum `ffec2ab8` / Fizzygum-tests `e0b00702f`;
**line numbers drift — the method/symbol name is the authoritative anchor, re-grep it
before trusting a number.**

**Mandate.** Eliminate the underlying problem, not the symptoms: today's world reset is a
*cleanup pass over a reused world object*, and the whole apparatus policing it — the
`RESETWORLD_INCOMPLETE` field ratchet, the `WORLD_INVENTORY_*` audits, the teardown-core
contract — exists because a cleaned world can only ever be *audited* toward pristine.
This arc makes reset a CONSTRUCTION: destroy the old world, build a new `WorldWdgt`, and
the reset invariant collapses to one question a machine can ask — **"is the old world
collectible?"** (a `WeakRef` to the replaced world + forced GC ⇒ collected). State that
should survive a reset survives because it structurally lives OFF the world (the PAGE
lifetime), never because a cleanup pass remembered to spare it.

---

## §0 Orientation

**Framework context.** Fizzygum is a CoffeeScript GUI framework rendered on one canvas; no
module system — every class is a global on `window`; ~510 sources compile in-browser at
boot (or ship precompiled). The SystemTest suite (sibling `Fizzygum-tests` repo; 307 tests
today, `fg status` prints the live count) runs all tests in ONE page per shard,
`world.resetWorld()` being every test's first command — so the suite performs ~300 world
resets per run and asserts byte-exact pixels after each.

**The program this plan closes** (decided 2026-08-20 with the owner; stated in full in
`../archive/world-inventory-instruments-plan.md` §0):

- **Arc A (DONE, archived)** — the in-band `WorldInventory` gate at every suite teardown,
  both engines: identity-level escaped/zombie diffs, declared page-lifetime stores,
  statics/DOM/module-state drift. Seven product leak mechanisms found and repaired,
  including the unbounded-LRU corruption of all eight caches.
- **Arc B (DONE, archived)** — the Chrome-only VM-truth tier: `fg vmtruth` (forced-GC
  WeakRef collectibility oracle + post-GC heap-floor gate + INVALID-on-unmeasured),
  `heap-forensics.js` (four lenses incl. snapshot retainer paths), and the door-callback
  law with its destroy-mid-load race gate. **Arc B's WeakRef+forced-GC machinery IS the
  acceptance instrument this arc gates with**, hardened against 307 tests.
- **Arc C (THIS PLAN)** — reset-by-reconstruction: the two-lifetimes doctrine becomes
  construction instead of audit.

**The two-lifetimes doctrine** (living truth: `../architecture/world-lifetime-and-inventory.md`
§1): every piece of page state belongs to exactly one of two lifetimes — PAGE (the code,
font atlases + probed metrics, interned immutables, pure memo caches, lifetime counters)
or WORLD (everything else; dies with the world). Today the doctrine is enforced by AUDIT
(Arc A's inventory + the field ratchet); this arc enforces it BY CONSTRUCTION. One
doctrine amendment this arc makes (owner-visible): the `world.cacheFor*` memo LRUs —
§1's own example of page-lifetime state — become WORLD-lifetime (they die and refill;
§4 D2 prices this and S1 measures it), because re-homing them off-world buys nothing but
warmth and costs a structural exception.

**Critical reframe (do not lose this).** After this arc, "did reset forget a field?" is no
longer a question anyone asks — a fresh world cannot inherit a stale field. The bug class
that produced §2d/§3h of `Fizzygum-tests/DETERMINISM.md` (a world-level Set/Map/counter
the teardown forgot, mis-rendering a LATER test — found by hand for years, then ratcheted)
is not *guarded better*; it is **structurally impossible**. What replaces it is a smaller,
machine-checkable surface: (a) the old world must be collectible (the WeakRef invariant —
anything still pinning it is a named, forensically-traceable bug), and (b) the declared
page-lifetime stores must actually live off-world (a one-time structural fact, not a
per-field per-reset discipline).

**The second reframe, from this plan's research: today's "world fields" are not all
per-world.** The meta-system emits class-body field declarations as ONE-TIME prototype
assignments (`meta/Class.coffee`, `_addFieldsAndMethods`: `"window." + @name +
".prototype." + fieldName + " = " + fieldDeclaration`), so the world's ~23 mutable
Set/Map/Array containers (`steppingWdgts`, `openPopUps`, `toolTipsList`, the damage
queues, …) are **shared between any two WorldWdgt instances** — a second world would
inherit the first world's very Set objects. Invisible with one world per page (the current
regime), load-bearing the moment reconstruction exists. Fixing this (D-P2a) is a
precondition of the flip, and a real product repair in its own right.

## §0.5 Cold-execution protocol

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status` (NEVER `./fg`; absolute path
   always). Expect all repos clean or explainably dirty, build FRESH or rebuild.
2. Read this plan fully, then the doctrine doc
   (`../architecture/world-lifetime-and-inventory.md`) in full. Re-grep every symbol you
   are about to touch (§1 lists them).
3. Execute phases IN ORDER (§6). Phase 1 is scratch-only; later phases touch src/harness
   and each ends at a named gate. Iterate with `fg presuite`; close phase boundaries and
   the arc with `fg gauntlet` (18 legs; `vmtruth` is the wave-C leg this arc extends).
4. Long ops: launch ONCE in background redirecting to a log; peek `/tmp/fg-<cmd>.verdict`
   at a ~5-min cadence. Never pipe a gating fg call through `tail`/`grep`. A running op
   OWNS src/tests — edit only docs/memory while one runs.
5. Ad-hoc Node probes go under `Fizzygum-tests/.scratch/` (gitignored) — NOT the session
   scratchpad (`require()` resolves from the script's dir).
6. Owner rules: never commit/push autonomously — propose message(s) and wait. No
   conclusions before evidence. Plans/docs stay present-tense. Stop after two falsified
   fix shapes — re-frame instead of iterating.

## §1 Current state (the machinery this plan reshapes) — verified 2026-08-20

Four research sweeps (reset seam · construction/boot · pinning census · page-lifetime
manifest) produced this section; every load-bearing claim below was independently
re-verified against source the same day.

### §1.1 The reset as-built: a harness method over a shipping core

- **`resetWorld` does not exist in `Fizzygum/src`.** It is installed onto
  `WorldWdgt.prototype` at boot by `WorldTestSupport.installOnto WorldWdgt`
  (`src/boot/globalFunctions.coffee`, `startWorld`, existence-guarded — so it ships with
  the `harness` part only). Definition:
  `Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee`:
  ```coffee
  resetWorld: ->
    @_softResetWorld()
    @_settleLayoutsAfter => @_resetWorldNoSettle()
    @storageSorter._auditStorageNoSettle()
    @_auditWorldResetCompletenessNoSettle()
    @_auditWorldInventoryNoSettle()
  ```
- The structural half is the SHIPPING core `WorldWdgt._teardownWorldStructureNoSettle`
  (contract: *"after fullDestroyChildren(), the world holds NO reference to anything that
  was just destroyed, and no bookkeeping that assumed it still exists"*), shared with
  `loadWorldSnapshot`, which calls it directly and never calls `resetWorld`. The harness
  half (`_resetWorldNoSettle`) restores the PRISTINE LOOK: whole-screen damage mark,
  Untitled counters, `numberOfIconsOnDesktop = 0`, `isDevMode = true`,
  `resetToBootInputMode()`, the 960×440 harness extent (guarded `!@isIndexPage`), colour
  `205,205,205`, wallpaper `pattern1`, page scroll zero.
- `WorldWdgt.fullDestroyChildren` (product) zeroes every class's
  `lastBuiltInstanceNumericID` via `allClassFunctions()` — **skipping WorldWdgt**
  (`continue if eachClassFunction is WorldWdgt # the live world keeps its own id`, an
  explicit world-is-never-recreated assumption) — and writes three `Automator.*` statics
  behind `if Automator?` (shipping code mutating a harness class; BACKLOG'd, absorbed
  here as D-P2f).
- Callers of `resetWorld`: exactly one live path —
  `AutomatorEventCommandResetWorld.executeEventCommand: -> world.resetWorld()`, every
  test's FIRST command (307/307), dispatched by `AutomatorPlayer.replayTestCommands`,
  which itself runs **inside `WorldWdgt.doOneCycle`** — so the reset executes mid-cycle,
  and everything after it in that same cycle runs on the same receiver. Plus
  `heap-forensics.js`'s revealing teardown. Nothing in product src calls it.
- The three audits at the seam: Tier-A storage (`STORAGE_INVARIANT`), the field ratchet
  (`RESETWORLD_INCOMPLETE`: first-teardown fingerprint stored in the world field
  `@_pristineWorldFingerprint`, effective-value shallow read of own + prototype chain,
  exemptions in `WorldWdgt._worldStateAuditExemptions` carried by
  `WorldTestSupport.@staticMembersToInstall`), and the inventory audit
  (`WORLD_INVENTORY_*`, baseline in the world field `@_worldInventoryForAudit`, one
  harness-owned declaration pushed onto the static `WorldInventory.pageLifetimeStores`
  on first run). **Both baselines live ON the world instance** — under naive
  reconstruction every reset re-takes a "first" baseline and both gates go silently
  blind, plus the push duplicates.

### §1.2 Construction and boot as-built

- **One `new WorldWdgt` site in the workspace**: `startWorld`
  (`boot/globalFunctions.coffee`) — `new WorldWdgt worldCanvas,
  !(window.location.href.includes "worldWithSystemTestHarness")`. `worldCanvas` is a page
  global from `src/index.html` (`document.getElementById('world')`); the canvas element
  is authored in HTML, never created in JS. Constructor signature:
  `constructor: (@worldCanvas, @automaticallyAdjustToFillEntireBrowserAlsoOnResize = true) ->`.
- The constructor, in order: `window.world = @` (the ONLY write to that global in the
  framework) · `@isIndexPage` from the URL · **`WorldWdgt.preferencesAndSettings = new
  PreferencesAndSettings`** (a CLASS STATIC re-pointed per construction; its constructor
  runs `setMouseInputMode` → `@minimumFontHeight = @getMinimumFontHeight()`, the
  pixel-probe — see §1.4) · `super()` (registers the world itself in
  `WorldWdgt/…/Widget.instances` via the meta-injected `registerThisInstance()`; bumps
  the id statics) · `@wallpaper`/`@appearance = new DesktopAppearance @` · `@hand = new
  ActivePointerWdgt` (a PARENTLESS widget — never reached by `fullDestroyChildren`) ·
  `@keyboardEventsReceivers`/`@temporaryHandlesAndLayoutAdjusters = new Set` (the ONLY
  two collections the constructor re-instantiates) · canvas sizing
  (`stretchWorldToFillEntirePage()` or `_sizeCanvasToTestScreenResolution()` — the
  latter is harness-installed, which is why `installOnto` must precede construction) ·
  `@initEventListeners()` · `@automator = new Automator` (guarded) · `@macroToolkit`? ·
  `@untitledNamingService` · `@sourceEditsRegistry` · `@widgetFactory`? · `@pinouts`? ·
  `@parts = new PartsRegistry` · `@dataflow = new DataflowEngine` · `@storageSorter =
  new StorageSorter` · render canvas + text-measurement canvas + the 7 `LRUCache`s ·
  `@inputEventsQueue` · `@_bootExtent = @extent()` · `@_changed()`.
- Boot work OUTSIDE the constructor that a ready world depends on (`startWorld` tail):
  `world.isDevMode = true`, the RAF pump (`animloop = -> world.doOneCycle();
  window.requestAnimationFrame animloop` — **resolves the `world` global every frame,
  captures nothing**; byte-confirmed in the shipped bundle), `new
  SystemTestsControlPanelUpdater`?, `window.menusHelper`/`window.demoMenus`,
  `world.removeSpinnerAndFakeDesktop()` (unguarded DOM removal — crashes if called
  twice), **`world.binWdgt = new BinWdgt` / `world.shelfWdgt = new ShelfWdgt`** (world
  fields assigned by BOOT, read by `graphLivenessRoots` and the inventory), and
  `world.createDesktop()` (index page only; nothing EVER rebuilds a desktop after a
  reset today — a bare product reset leaves a destroyed desktop and a shifted colour,
  i.e. the product currently has NO working true reset).
- Collaborator back-references: **none** — no collaborator stores a `@world`
  (`grep "@world\s*=\|@world:"` over src: zero hits); all resolve the bare global at
  call time. The one explicit back-pointer is `@appearance = new DesktopAppearance @`.
  Widgets reach the world via `TreeNode.root()`'s `@cachedRoot` (versioned against
  `WorldWdgt.structureVersion`), not a stored world field.

### §1.3 The pinning surface (what could keep an old world alive or misbehaving)

Ranked; each is addressed by a named deliverable in §4.

1. **The 23 prototype-shared mutable containers** (§0's second reframe; 15 Sets/Maps + 8
   arrays; verified: only 2 collections are constructor-built; `otherTasksToBeRunOnStep`
   has zero reassignment sites anywhere). → D-P2a.
2. **20 DOM listener closures capture the world instance** (`=>` over `@`, pushing into
   the captured `@inputEventsQueue`) across THREE targets — `@worldCanvas` (14),
   `document.body` (3: cut/copy/paste), `window` (4: scroll/dragover/drop/resize) — all
   installed by `initEventListeners` from the constructor; **product has NO
   removeEventListener at all** (zero hits in src). The only detach verb is
   harness-installed `removeEventListeners` (WorldTestSupport), called per test by
   `AutomatorPlayer.startTestPlaying` and re-armed by `world.initEventListeners()` when
   playback ends. `document.body` and `window` outlive any swap. → D-P2e.
3. **The world itself is registered in the `instances` Sets** of its whole class chain
   (meta-injected), and NOTHING ever destroys a world — `WorldWdgt` has no
   destroy override; `Widget.unregisterThisInstance` is the only remover. An undestroyed
   replaced world is a permanent registry pin (and exactly what the vmtruth oracle
   exists to catch). → D3.
4. **`Widget._destroyNoSettle` reads the GLOBAL `world`** (deletes from
   `world.keyboardEventsReceivers` etc.) — old-world widgets destroyed AFTER the swap
   would mutate the NEW world. Ordering law: tear the old world down fully BEFORE
   constructing the new one (construction is what moves `window.world`). → D3.
5. **The mid-cycle hazard**: `resetWorld` executes inside the old world's `doOneCycle`;
   after reconstruction returns, the REMAINDER of that cycle (dataflow, layout, repaint,
   the blit to the SHARED DOM canvas) still runs with `@` = the old, dissolved world. →
   D3's `_dissolved` guard; S1 measures the actual tail behaviour first.
6. **Module/page state wrapping world-owned objects**: the SWCanvas poisoned-key
   recorder's one-shot module latch instance-wraps `world.cacheForImmutableBackBuffers`
   (`swCanvasInstallPoisonedKeyRecorderOn` never resets → the new world's cache is never
   instrumented, silently); the cold-glyph module arrays hold live widget refs between
   a cold draw and the atlas refresh. → D-P2c.
7. **Harness/instrument assumptions of one-world-per-page**: the gate preludes arm
   `world.audit*` flags on the CAPTURED instance once per page
   (`tier-naming-prelude.js` `world.auditTierAndApplyNaming = true`;
   `notification-settle-prelude.js` `world.auditNotificationSettleNeutrality = true` +
   `world.doubleCheckCachedMethodsResults = true`; capstone + paint-readonly likewise —
   the cache-oracle prelude states the assumption verbatim: *"resetWorld resets state on
   the SAME world object"*); `paint-readonly-prelude.js` additionally holds a CAPTURED
   `world` in a permanent closure. All world-seam preludes hook
   `WorldWdgt.prototype.resetWorld` — the seam name must survive. → D4a/D-P3c.
8. **`world.automator` is constructor-built** — a fresh Automator per world would
   destroy the live run state (test index, results, failure images) of the driver
   currently executing the reset. The Automator triple holds NO world field (all global
   reads); its async tails (screenshot SHA digests, `script.onload` chains,
   `nextStartupAction`) transiently pin the world they were created on. → D-P2h.
9. **Pending timers/tails capturing widgets**: `ToolTipWdgt.@ongoingTimeouts` (cancel
   verb exists, never called from teardown); two UNGUARDED door-law tails found by the
   census — `VideoPlayerWithRecommendationsWdgt` ctor (`.then (result) => …
   world.steppingWdgts.add @`) and `FileLoading.coffee` (`result.whenReady?.then? ->
   widget._fullChanged?()`) — plus `loadWorldSnapshot`'s three world-capturing tails.
   → D-P2c / D-P2f.
10. **`PartsRegistry` is per-world with no page-level record of loaded parts** — a new
    world re-derives `@_state` from eagerness alone, so an already-fetched lazy part
    reads `NOT_LOADED` and a re-ask re-fetches its batch. → D-P2d.
11. **Boot-only steps that would break or be missed on reconstruction**:
    `removeSpinnerAndFakeDesktop` (crashes on 2nd call), bin/shelf assignment,
    `createDesktop`, `isDevMode = true` — the post-constructor half of "a ready world"
    exists only inline in `startWorld`. → D2.
12. Cleared as safe by the census: the RAF pump (global read), all boot-file `world`
    references, all Automator/Player/Loader world reads, every runner `page.evaluate`,
    `menusHelper`/`demoMenus` (no fields), `WellKnownObjects` (lazy by design; its
    `@_appSingletons` static is documented stateless — watch item only),
    `Color`/`Point`/`Rectangle` interns, the hashCode memo, the SWCanvas atlas stores
    (the single most expensive page asset survives a swap for free).

### §1.4 The page-lifetime manifest vs the world instance

Of the 12 declared `WorldInventory.pageLifetimeStores` entries, **10 live off-world and
survive reconstruction naturally** (class statics: `Color._cache`, the id counters, the
`WorldWdgt.frameCount/…Version/…Generation` statics — load-bearing that these DON'T
restart, since geometry caches stamp them; module scope: the hashCode memo, the four
SWCanvas text stores; window: `SourceVault`; DOM: head scripts). **Two live ON the world
and die**: the 7 `cacheFor*` LRUs and the per-cycle damage queues (the latter correctly).
The doctrine-named items outside the table: SWCanvas glyph atlases + metrics bundles —
private statics inside the vendored bundle, **survive for free**;
**`minimumFontHeight` does NOT** — it lives in the prefs bag the constructor re-creates,
and re-probing is (a) ~1400 `getImageData` calls and (b) explicitly ruled unsafe mid-run
by `resetToBootInputMode`'s own comment (the answer depends on atlas warmth,
DETERMINISM.md §3g). `Automator.state` is harness-declared page-lifetime; the
`hasProp/indexOf/slice` window leakage is boot-owned page residue (BACKLOG).

## §2 Why it is shaped this way

The reused-world reset is not an oversight; it is the historically cheap path. The world
was born a singleton created once at boot; when the test harness needed per-test
isolation, "clean the world we have" required no changes to boot, no listener rebinding,
no thought about which state was page-scoped — every cost the alternative carries
up-front. The price surfaced slowly, as a bug CLASS: every world-level field added by any
feature became a per-reset obligation nothing enforced. Two decades of Morphic-descended
convention (the world IS the page) reinforced the shape — visible today in the
meta-system's prototype-shared containers (harmless only while exactly one world ever
exists), the constructor's unremovable listeners, and `createDesktop` being boot-only.
The ratchet (2026-07-29) and the inventory (Arc A) made the obligation loud — 14 leaks
in the first audit, seven mechanisms in Arc A's rounds — but they police the model rather
than fix it: each is a growing exemption/declaration table maintained by hand, and the
model still requires every future field to be remembered at the seam. Reconstruction
inverts the default: forgetting is now safe (the field dies with the world), and only
page-lifetime PROMOTION is an explicit act.

## §3 The distilled argument

1. **The invariant becomes machine-checkable.** "Reset is complete" is today an
   open-ended conjunction over every field anyone ever adds (ratchet + inventory +
   audits, each with an exemption table). "The old world is collectible" is ONE question,
   already instrumented (Arc B's oracle: the old world leaves the registry at its
   destroy, gets a WeakRef, and the existing sweep asserts collectibility with identity
   attribution) — and every failure names its retainer via `heap-forensics.js`.
2. **The bug class dies, not the bug count.** §2d/§3h of DETERMINISM.md, the 14-leak
   audit, Arc A's seven mechanisms — all instances of "a cleanup pass forgot". A fresh
   world cannot inherit `numberOfIconsOnDesktop`, a stale `untitledNamingService` count,
   a dangling `errorConsole`, or a nonzero damage-suppression depth.
3. **The product gains a capability it does not have.** Today a bare product reset is
   BROKEN (desktop destroyed, never rebuilt; §1.2). The reconstruction core ships, so
   `resetWorld` becomes a real product verb — the owner's origin request ("a TRUE reset")
   — with the harness riding it through a hook instead of owning it.
4. **The timing is now, because the instruments exist.** Before Arcs A+B this arc was
   unverifiable: nothing could prove the old world dead (closure pins are invisible
   in-band) and nothing could attribute a failure. The vmtruth machinery was hardened
   against 307 tests specifically so this arc could gate on it.
5. **The alternative is permanent audit growth.** Every future world field costs a
   ratchet/inventory decision forever. Reconstruction pays a one-time re-homing cost for
   the (small, already-enumerated) page-lifetime set, then makes the default safe.

## §4 Deliverables (design decided; executor implements, does not re-litigate)

Phase-2 deliverables (D-P2a…D-P2h) are INDEPENDENT pre-repairs, each safe and gateable
on the CURRENT one-world regime — they land one by one, each behind `fg presuite` and a
phase-closing gauntlet. Phase-3 deliverables (D1–D3 + D-P3c) are the seam and the flip —
the flip itself is ONE commit. Phase 4 is gates + doctrine; Phase 5 is promotion.

### D-P2a — per-world containers (kill the prototype sharing)

Move all 23 mutable containers from class-body declarations to constructor-built
per-instance fields on `WorldWdgt` (the 15 Sets/Maps incl. `steppingWdgts`,
`openPopUps`, `toolTipsList`, `widgetsToBeHighlighted` family, `hierarchyOfClicked*`,
`popUpsMarkedForClosure`/`freshlyCreatedPopUps`, `wdgtsWithOngoingScrollMomentum`,
`pendingFractional*`, `widgetsReferencingOtherWidgets`,
`wdgtsDetectingClickOutsideMeOrAnyOfMeChildren` + the 8 arrays incl.
`otherTasksToBeRunOnStep`, `errorsWhileRepainting`, the four layout/damage queues).
Keep the class-body declarations as `undefined` (the house field-declaration idiom) so
the inspector still lists them. Per S2's executed verdict (§5): **build all 23
immediately after `window.world = @` and BEFORE `super()`** — legal (the meta-system
emits plain functions, and both this constructor and `ActivePointerWdgt`'s already
assign fields pre-super), and it makes "the containers exist from the first statement"
unconditional; the constructor provably touches five of them via
`stretchWorldToFillEntirePage`/`setBounds`/`_changed` (S2's stranded-entry proof).
Companion edits from S2's checklist: rewrite `_fingerprintWorldStateNoSettle`'s
now-false "stays on the prototype" comment; expect the inventory's own-only `world.*`
sweep to gain 23 size rows (declare growth policies for any that legitimately move, or
fix what fires); keep `serialization-roundtrip-headless.js`'s `COLLECTIONS` roster in
step; and RETIRE `otherTasksToBeRunOnStep` in the same pass (zero producers anywhere in
scope — verified twice — it is a dead extension point iterated every cycle). ⚠
`DataflowSource.coffee`'s `world?.steppingWdgts.add` soaks the wrong noun and
`Serializer`/`Deserializer`'s `world.steppingWdgts?.add` would silently swallow a
mis-ordered construction — pre-super placement makes both moot, do not "fix" the soaks
instead. Acceptance: full gauntlet green; `grep` proves no mutable initializer remains
at WorldWdgt class body; a re-run of S2's identity probe shows all containers OWN with
`prototype value === undefined` (the `keyboardEventsReceivers` contrast shape).

### D-P2b — hoist the `minimumFontHeight` probe to page lifetime

The probe result becomes a lazily-probed CLASS-LEVEL memo (e.g.
`PreferencesAndSettings.probedMinimumFontHeight ?= @_probeMinimumFontHeight()`), taken
once per page at first construction — which is BOOT, on a COLD atlas, and that is
load-bearing: S1 measured the warm re-probe FLIPPING the value (boot 9 → warm 10 on the
SWCanvas page), so the memo is not an optimization but the determinism fix — later
constructions read the memo and NEVER re-probe. `resetToBootInputMode`'s carry-over
dance dissolves (keep the method; its minimumFontHeight half becomes moot and its
comment updates to point at the memo). Declare the new static in `pageLifetimeStores`
if the inventory sees it. Acceptance: gauntlet green; a probe-count instrument
(scratch) shows exactly ONE probe per page under repeated construction, and the memo'd
value equals the boot value (9 on the harness page today).

### D-P2c — pending-capture hygiene at the teardown core

(a) `_teardownWorldStructureNoSettle` calls `ToolTipWdgt.cancelAllScheduledToolTips()`
(the verb exists; today nothing teardown-side calls it). (b) The SWCanvas poisoned-key
recorder re-keys its latch off the CACHE INSTANCE it wrapped (re-install when
`window.world?.cacheForImmutableBackBuffers` is not the wrapped one), so a future world
gets instrumented — the module boolean becomes a per-cache marker. (c) The cold-glyph
module arrays: teardown-time entries referencing destroyed widgets are already skipped
by the drain's consumer; ADD a teardown-core filter dropping destroyed entries at the
seam (same shape as the damage-queue filter, and it removes a transient corpse pin the
vmtruth grace currently absorbs). Acceptance: gauntlet green; a scratch probe plants a
pending tooltip + a cold-glyph entry at teardown and shows both severed.

### D-P2d — page-level record of loaded parts

`PartsRegistry` derives `@_state` from eagerness PLUS a page-level "already ingested"
record (`PartsRegistry.ingestedParts`, a class static Set; record on COMPLETED ingest
only — eagerness is re-derivable and a load-start record would read LOADED forever
after a failed load). A reconstructed world then reads an already-fetched lazy part as
LOADED — no re-fetch, no re-ingest. Acceptance: gauntlet green (the `parts` leg
exercises the lazy rigs); a scratch probe on `index.html` loads a part, swaps nothing
(current regime), and asserts the record; the destroy-mid-load race gate stays green.
⚠ NAMED RESIDUAL for Phase 3 (found during this unit): a part-load IN FLIGHT when the
world is replaced is NOT covered by the completion-only record — the fresh registry's
`@_promises` is per-instance, so a re-ask would re-start the load and double-enqueue
the same names (`SourceCompileScheduler.enqueueJob` does not dedupe; `new Class src`
twice on a live class). Pre-existing and narrow, but the reconstruction seam (D1/D3)
must either drain/adopt in-flight part loads at the reset boundary or add a page-level
in-flight promise map — decide there, not here.

### D-P2e — the listener detach verb ships

Move `removeEventListeners` from `WorldTestSupport` into `WorldWdgt` (product), exactly
as-is (its three-target law and comment travel). The harness keeps calling it
(`AutomatorPlayer.startTestPlaying`); `initEventListeners`/`removeEventListeners` become
the product attach/detach pair the reconstruction seam needs. NOT wired into any product
path yet in this deliverable. Acceptance: gauntlet green; `check-part-edges` and the
dead-methods gate clean (the harness caller keeps the method live).

### D-P2f — door-law and ownership riders

(a) Guard the two unguarded tails found by the census per the door-callback law:
`VideoPlayerWithRecommendationsWdgt`'s constructor tail (`return if @destroyed` before
`_parseVideosIndex`/`steppingWdgts.add`) and `FileLoading`'s
`result.whenReady?.then? -> widget._fullChanged?()` (guard on `widget.destroyed`).
(b) Re-home the three `Automator.*` static writes out of `fullDestroyChildren` (product)
into the harness reset path (`_afterWorldReset` hook once D1 lands, or
`_resetWorldNoSettle` pre-D1) — closes the BACKLOG line "shipping-shaped code writing a
harness class's state". (c) The `hasProp/indexOf/slice` window leakage: scope them into
the compile closure if the emitted code allows; if the emitted code genuinely references
them as globals, keep them and CLOSE the BACKLOG line with that finding written where it
belongs (`boot/loading-and-compiling-coffeescript-sources.coffee` comment). Acceptance:
gauntlet green; for (a) a scratch destroy-mid-pending probe on each tail.

### D-P2g — the named-constructor rider (BACKLOG, filed `ffec2ab8`)

`Class`'s eval'd source emits a NAMED constructor function so V8's parse-time metadata
names every widget — heap-snapshot nodes and DevTools become readable-by-name, upgrading
`heap-forensics.js` from id-mapping to name-guided (keep the id-mapping path; names are
a convenience, identity stays the contract). Touches the meta-system + the precompile
path: its own gauntlet pass + `fg homepage` (the precompiled image must carry the named
form). Acceptance: gauntlet + homepage green; `heap-forensics.js --selftest` green; a
snapshot probe shows a widget node named by class.

### D-P2h — the Automator becomes page-lifetime

The harness driver survives world replacement: `Automator` gains a class-level singleton
seam (e.g. `Automator.current ?= new Automator` — the WorldWdgt constructor line becomes
`@automator = Automator.current` behind the existing guard, or an equivalent explicit
page-singleton; executor picks the spelling that keeps `world.automator` working
verbatim, since ~everything reads it through the world field). Player/loader state
(test index, results, failure images, screenshot bookkeeping) thereby survives
reconstruction. `SystemTestsControlPanelUpdater` and `menusHelper`/`demoMenus` are
already page-level. Acceptance: gauntlet green (the whole suite IS the test — every
runner drives `world.automator` across 307 resets).

### D1 — `resetWorld` becomes the shipping reconstruction orchestrator

`WorldWdgt.resetWorld` moves INTO product (`src/WorldWdgt.coffee`) with the
reconstruction body; `WorldTestSupport` STOPS installing a `resetWorld` (killing the
twins risk) and instead installs the audit hook the product method calls:

```coffee
# product (shape, not final code):
resetWorld: ->
  @_softResetWorld()
  @_settleLayoutsAfter => @_teardownWorldStructureNoSettle()
  @_dissolveWorldNoSettle()              # D3: detach listeners, destroy hand, unregister self
  newWorld = new WorldWdgt @worldCanvas, @automaticallyAdjustToFillEntireBrowserAlsoOnResize
  finishWorldSetup newWorld              # D2: the shared post-constructor half
  newWorld._afterWorldReset?()           # harness graft: audits ride here
  newWorld
```

The prototype seam every prelude wraps (`WorldWdgt.prototype.resetWorld`) is preserved
by NAME and by semantics (called on the old world, returns having replaced
`window.world`); `AutomatorEventCommandResetWorld` is unchanged. The harness's
`_afterWorldReset` carries the three audits (storage Tier A, the reframed ratchet, the
inventory audit) plus the pristine-look residue that remains meaningful (the 960×440
extent guard IF the constructor path doesn't already produce it — executor verifies it
does; `isDevMode = true` moves into `finishWorldSetup` since boot sets it for every
page). `_resetWorldNoSettle` and its pristine-look block are DELETED (absorbed:
colour/wallpaper/counters/flags are constructor state now). ⚠ The `id` question is
DECIDED: `_dissolveWorldNoSettle` zeroes `WorldWdgt.lastBuiltInstanceNumericID` (the
dying world no longer "keeps its own id" — delete the exemption line in
`fullDestroyChildren`), so every reconstructed world is `WorldWdgt#1` and world identity
is run-history-free (the §3h determinism shape, applied to the world itself).

### D2 — `finishWorldSetup`: ONE definition of "a ready world"

Extract `startWorld`'s post-constructor block into one shipping function (boot file,
beside `startWorld`): `isDevMode = true` (boot's value on every page today) ·
`binWdgt`/`shelfWdgt` construction · `createDesktop()` when `isIndexPage` ·
(spinner removal STAYS boot-only — it is about the loading page, not the world; give it
an idempotence guard anyway). Boot calls it; `resetWorld` calls it. One core, two
callers — the teardown-shared-core doctrine applied to construction. Acceptance
(with D1/D3): boot behaves identically on all three pages (smoke + suite + homepage).

### D3 — `_dissolveWorldNoSettle`: the old world dies properly

The missing half of the swap, on the OLD world, after the teardown core: (a)
`@removeEventListeners()` (D-P2e's verb) — `document.body`/`window`/canvas all clean;
(b) `@hand._destroyNoSettle()`-equivalent (the parentless hand must leave the registry)
and destruction/unregistration of any other parentless world-owned widget chrome
(executor enumerates: bin/shelf are world FIELDS holding widgets built by boot — they
are torn down as part of dissolution and rebuilt by `finishWorldSetup`; verify their
`empty()` vs destroy semantics); (c) `@unregisterThisInstance()` — the world leaves
every `instances` Set (this is the line that arms the vmtruth oracle for free); (d) the
id-zeroing decided in D1; (e) the `_dissolved` guard, NARROWED per S1's measured mechanism: the corpse's
cycle-tail is ALREADY paint-inert (damage marks route through the global `world`, so
post-swap the corpse cannot blit — measured, three modes, zero rects) — the guard is
therefore NOT a paint fix. What it must actually do: (i) a dissolved world must not
DELIVER marks into the live world — one `return if @_dissolved` at the damage/layout
mark funnels (`_changed`/`_fullChanged`/`_invalidateLayout` route via the global; the
corpse marking after the swap injects its dead self into the NEW world's per-cycle
lists — transient today, but a corpse reference in a live list is exactly what the
inventory calls a zombie); (ii) optionally skip the corpse's ~13 no-op stations
(`doOneCycle` early-out) — hygiene, not correctness; implement (i) always, (ii) only
if trivially clean. ⚠ Ordering law (from §1.3-4): dissolution completes BEFORE
`new WorldWdgt` runs — `Widget._destroyNoSettle`'s global-world reads must still see the
old world while old widgets die.

### D-P3c — instruments survive the flip (same commit as D1–D3)

(a) The two audit baselines move off the world instance to the harness page scope
(module-level in `WorldTestSupport`'s install closure or statics carried by
`staticMembersToInstall` — executor picks; the duplicate `pageLifetimeStores` push is
keyed off the same page-scope latch). (b) The `RESETWORLD_INCOMPLETE` ratchet is
REFRAMED, not deleted: with a page-scope baseline it now asserts **construction
determinism** — every reconstructed world must fingerprint identically to the first
(a constructor reading drifted page state fails loudly). Rename/retire is an
end-of-arc owner decision (§6). (c) The gate preludes' `world.audit*` arming moves to
`WorldWdgt.prototype` defaults (`WWp.auditTierAndApplyNaming = true` etc. — every
world inherits them; the preludes already patch prototypes, this is the same idiom),
and `paint-readonly-prelude.js`'s captured `world` becomes a call-time
`window.world` read. (d) `heap-forensics.js` and the vm-truth/storage preludes are
re-read against the new seam (they wrap by name and resolve receivers at call time —
expected no-op, but VERIFY, do not assume: run `fg vmtruth` + `fg storage` +
`heap-forensics --selftest` explicitly at the flip gate). (e) `WorldInventory`'s
`world.cacheFor*` declaration and the `lastBuiltInstanceNumericID` reason string update
to the new regime.

### D4 — the acceptance gate: the world-collectibility rider

Extend `vm-truth-prelude.js`/`vm-truth-gate.js`: at each reset the prelude additionally
asserts `window.world !== theWorldTheResetRanOn` and tracks the replaced world's WeakRef
in the existing sweep (it already will, via `unregisterThisInstance` — the rider makes
the WORLD finding a distinct, louder verdict line: `LAYOUTAUDIT VMTRUTH
uncollectedWorld:WorldWdgt#1 destroyedDuring:<test>`), and the gate reports
`uncollectedWorlds` as its own failure class (a pinned world is transitively everything).
Heap-floor budget unchanged (96 MB) unless S1's measured reconstruction profile forces a
conscious bump (owner-visible if so). Acceptance: `fg vmtruth` green on the flipped
suite; the D5 world-pin plant fails it.

### D5 — prove the gates FAIL (mandatory, per standing case law)

Three plants, each proven then removed: (1) **world pin** — a scratch prelude stashes a
strong ref to the old world at reset (module var); `fg vmtruth` must FAIL with the
`uncollectedWorld` verdict naming it, while the suite stays green. (2) **construction
drift** — plant a page-state read into a scratch-patched constructor (e.g. a counter
that increments per construction and lands in a world field); the reframed ratchet must
fire `RESETWORLD_INCOMPLETE` on the second reset. (3) **audit-arming regression** — with
the prototype-default arming (D-P3c), un-arm one flag on a fresh world mid-page in a
scratch run; the corresponding gate leg must lose its positive-coverage line (proving
the arming is load-bearing and its loss is visible, not silent).

### D6 — WorldInventory production promotion (Phase 5, separable)

Move `WorldInventory.coffee` out of `src/dev-tools/` into a core-owned directory (the
census verified: core has ZERO code references to it — comments only — and both
portholes live in the boot bundle of every profile, so promotion is a file move + parts
bookkeeping, no untangling; `dev-tools`' `requires` list stays behind with the factory).
The audit CALLER stays harness-side. This gives the production tree the accounting the
owner asked for ("usable at any time") — reachable from the console on any build.
Acceptance: gauntlet + `fg homepage` green (homepage now carries the class);
`check-shippable-coverage`/`check-part-edges` clean.

### D7 — docs + program bookkeeping

`architecture/world-lifetime-and-inventory.md` §1 rewritten (enforcement by
construction; the LRU doctrine amendment; the ratchet's reframe), §6 extended with the
world rider; `Fizzygum/CLAUDE.md` Testing section's teardown paragraphs updated;
`Fizzygum-tests/DETERMINISM.md` §2d/§3h gain a "since Arc C" note; `docs/BACKLOG.md`
program section closed out (module-state lines, the named-constructor line);
`archive/INDEX.md` entry at the close ritual; this plan `git mv`'d to `archive/` with
the STATUS box as ledger.

## §5 Spikes (Phase 1 — scratch only, no src/scripts edits)

- **S1 — the swap prototype + cost + collectibility** — **EXECUTED 2026-08-20: GO.**
  Probes `.scratch/s1*-probe.js` (14 files incl. a heapsnapshot parser); dev build,
  Arc B's Chrome dose, harness page + `index.html`. Results:
  - **(a) COST — GO with margin.** Median per reset: today's full `resetWorld` 6.6 ms
    (of which `_auditWorldInventoryNoSettle` 4.95 ms, the ratchet 0.75 ms, the CORE only
    0.6 ms); the hand-rolled reconstruction sequence 1.55–2.35 ms. Apples-to-apples
    (audits excluded on both sides): **+0.95…+1.75 ms/test = +0.37…+0.67 % of the 78 s
    dpr1 suite** (NO-GO line was ~10 %). Raw headline: reconstruction is ~5 ms/test
    CHEAPER than today's audited reset. `index.html` product-shaped reset incl.
    `createDesktop`: 3.5 ms median. Zero console errors across 44 resets + settle
    frames; three real SystemTests PASS on a reconstructed world with IDENTICAL
    screenshot dataHashes.
  - **(b) MID-CYCLE TAIL — benign, mechanism named.** After an in-cycle swap the corpse
    finishes its remaining ~13 stations (all 0 ms, no throw) and **cannot blit**:
    measured 0 damage rects / 0 blits in three modes (even with a live child and no
    teardown), because `Widget._changed`/`_fullChanged`/layout-dirty push into the
    GLOBAL `world` — the instant `window.world` moves, every mark in the page routes to
    the NEW world and the corpse's own arrays stay empty. `new WorldWdgt` clears the
    visible canvas synchronously (blank until the new world's first paint — invisible
    to the suite, which screenshots settled frames). Flip side (the one real channel):
    a corpse that marks damage DELIVERS ITS DEAD SELF into the live world's per-cycle
    lists (transient — drained next cycle — but see D3's narrowed guard). Nothing pumps
    the corpse afterwards (0 `doOneCycle` calls in 500 ms).
  - **(c) COLLECTIBILITY — NO today; sole retainer ablation-PROVEN.** The replaced
    world survives every sweep, retained EXCLUSIVELY by the three prototype-shared
    arrays S2 found (`widgetsWithMaybeChangedPaintBounds`,
    `widgetsThatMaybeChangedLayout`, `_widgetsFlaggedHasDirtyDescendant` — snapshot
    path: `Window → world → __proto__ → widgetsWithMaybeChangedPaintBounds → [0] = old
    world`). Ablation A (remove those 3 entries) → COLLECTED next sweep; ablation B
    (hand registries only) → still alive; exhaustive shallow scrub found exactly 6
    memberships total (3 prototype arrays + the old hand's 3 registry entries — the
    hand holds NO world reference and pins only itself). The detached listeners are NOT
    pins (the detach verb is a proven sever). **Accumulation: +1 701 KB post-GC heap
    per swap, permanent (×300 ≈ 510 MB vs the 96 MB vmtruth floor; `resetWorld` control
    +26 KB)** — so D-P2a is a hard PREREQUISITE of the flip, with proof, and D3 must
    destroy the old hand explicitly.
  - **(d) PROBE — cheap but determinism-live.** `new PreferencesAndSettings()` median
    0.35 ms (cost is a non-issue). ⚠ **The warm re-probe FLIPS the value: boot
    (cold SWCanvas atlas) measures `minimumFontHeight` 9; every warm re-probe answers
    10** (stable ×22; native page: 2, stable) — so the FIRST reconstruction would shift
    a text-metric input for the rest of the page (`StringWdgt.fontHeight` consumes it;
    no source declares fontSize < 10 and the three sampled tests were pixel-identical,
    so live-but-unproven pixel risk). D-P2b's memo therefore captures the BOOT-cold
    value once and reconstruction NEVER re-probes — the `resetToBootInputMode`
    carry-over semantics made structural.
  - Brief correction recorded: on the DEV build `index.html` also carries the
    harness-installed members (`installOnto` is page-independent; part inclusion is
    what gates it) — product-tree claims hold for `homepage`/`lean` profiles only.
- **S2 — the shared-container blast radius** — **EXECUTED 2026-08-20**, results:
  - **Sharing PROVEN empirically for 18 of 23** (identity probe on the booted harness
    page: `WorldWdgt.prototype[name] === world[name]` true for all 15 Sets/Maps +
    `otherTasksToBeRunOnStep`, `widgetsGivingErrorWhileRepainting`,
    `layoutErrorsToReport`). The other 5 arrays are own AT REST only because a runtime
    `= []` reassignment fires in the ordinary cycle — they are STILL shared during the
    window between construction and that first reassignment.
  - ⭐ **Three `WorldWdgt.prototype` arrays permanently strand a `WorldWdgt#1` ref**
    (`widgetsWithMaybeChangedPaintBounds`, `widgetsThatMaybeChangedLayout`,
    `_widgetsFlaggedHasDirtyDescendant`) — pushed DURING the world's own constructor,
    before the first reassignment made the field own; unreachable by every own-property
    sweep forever. Benign in magnitude (the immortal singleton), decisive as proof that
    the constructor writes containers (via `stretchWorldToFillEntirePage`/`setBounds`/
    `_changed`) — hence D-P2a's pre-`super()` placement.
  - **Zero prototype-level or class-level readers** of any of the 23; **zero
    `extends WorldWdgt`** anywhere (both re-verified independently). The serializer
    never walks the world's own props (its own comment: the world is deliberately not a
    table record), so making the 23 own exposes nothing; four containers participate as
    MEMBERSHIP marks (`stepping`/`keyboardReceiver`/`referenceTracker`/`openPopUp`),
    a path already proven against the target shape by `keyboardEventsReceivers`.
  - **`otherTasksToBeRunOnStep` has ZERO producers** — declaration + one consumer loop
    and nothing else in either repo (re-verified): retire it in D-P2a.
  - Site list (per-container files/counts, the flagged wrong-noun soaks, the
    `COLLECTIONS` roster, the fingerprint-comment staleness) lives in the S2 report;
    probes: `.scratch/s2-world-container-identity-probe.js`,
    `.scratch/s2-stranded-prototype-entries-probe.js`.
- **S3 — per-test cache cold-start at suite scale** — **EXECUTED 2026-08-20: CLEAN,
  twice.** Prelude `.scratch/s3-cache-cold-prelude.js` (post-reset `LRUCache.reset()` on
  all 7 world caches — `reset()` is the constructor's own emptying step, so a reset
  cache IS a fresh one), injected via the `AUDIT_PRELUDE`+`AUDIT_ECHO=1` rail, proof
  1:1 — 307 clears / 307 tests on all 8 shards, ~97.6k entries destroyed per run
  (largest single clear 2,782). Two independent control/treated pairs: **307/0/0 in all
  four runs, and treated reproducibly FASTER (68 s vs 72 s, both pairs)** — per-test
  cache death is reference-preserving and costs nothing (plausibly a small win from
  dropped back-buffer canvas pressure; cause not chased). No warmth dependency exists
  in the suite. Scope limits recorded: dpr1/Chrome/8-shard only; cache death only (not
  the full reform); atlas + `Color._cache` + class statics correctly untouched (they
  survive a real reconstruction too).

## §6 Execution order and gates

| Phase | Content | Gate |
|---|---|---|
| 1 | S1–S3 (scratch only) | numbers recorded in §5; S1 GO/NO-GO |
| 2 | D-P2a … D-P2h, landed INDIVIDUALLY (each is one-world-safe) | `fg presuite` per unit; ONE gauntlet closing the phase (all eight in) |
| 3 | D1+D2+D3+D-P3c — the flip, ONE commit | full `fg gauntlet` + `fg homepage` + explicit `fg vmtruth`/`fg storage`/`heap-forensics --selftest`; owner checkpoint before commit |
| 4 | D4 (world rider) + D5 (three plants proven, removed) | `fg gauntlet`; plant evidence recorded here |
| 5 | D6 (promotion) + D7 (docs/bookkeeping) + close ritual | `fg gauntlet` + `fg homepage`; owner decisions: ratchet rename/retire, BACKLOG closures |

Session-hop points: after Phase 2 (natural checkpoint — everything landed is
independently valuable), and after Phase 3 (the flip). Each phase's units carry enough
context in §4 to be delegated/briefed standalone; the flip (Phase 3) should be executed
by ONE session/agent end-to-end, never split.

## §7 Central risks

1. **Determinism is THE risk** (`Fizzygum-tests/DETERMINISM.md` §1–§3). The suite asserts
   raw-pixel SHA-256 equality after each of ~300 resets/run, cross-engine, at dpr 1
   and 2, under parallel load. Reconstruction touches the per-test starting state AND
   the per-test cost profile:
   - *Pixel identity:* the reconstructed world must render byte-identically to today's
     cleaned world at every test start — same extent, colour, wallpaper, counters, ids
     (D1 makes the world `#1` each time; a fresh `untitledNamingService` says
     `Untitled`, which is what the references already assert). Any pixel delta is a
     defect in the reconstruction, never a recapture (§3h's precedent).
   - *Warmth:* per-test cache cold-start (S3) and the `minimumFontHeight` probe (D-P2b)
     are the two known warmth couplings; both are dealt with BEFORE the flip.
   - *Cost cadence:* a heavier reset shifts cycle timing; the contract says settled
     pixels are cadence-independent, but §2's class-(B) latents surface under exactly
     such shifts. S1's budget check gates the GO; any new flake post-flip is a real
     latent bug (torture tool + playbook), not an Arc C revert trigger by itself.
2. **The mid-cycle swap** (§1.3-5): `resetWorld` runs inside the old world's
   `doOneCycle`; the corpse's cycle-tail must provably no-op (S1 evidence → D3 guard).
   The shared DOM canvas makes a stale blit the visible failure mode.
3. **The flip must be COMPLETE in one commit** — a page where some bindings hold the old
   world and some the new is worse than either pure state. §1.3 is the sever list; D5's
   world-pin plant is the proof the net catches what the list missed.
4. **Instrument blindness is the silent failure mode**: baselines re-taken per world,
   preludes armed on a dead instance, seams renamed — each gate would go green by
   measuring NOTHING. D-P3c + D5(3) exist precisely for this; the fuzz/vmtruth
   INVALID-is-not-a-pass doctrine applies to every leg at the flip gate.
5. **The harness drives the world it is replacing** — the Automator re-home (D-P2h) must
   land BEFORE the flip, and in-flight async tails (screenshot digests) mean the swap
   only ever happens at the reset seam, where the player is between tests.
6. **Production parity**: the reconstruction core ships; `loadWorldSnapshot` keeps
   calling the teardown core directly (unchanged), and `fg homepage`'s round-trip is the
   only gate that sees the production tree — it is mandatory at the flip gate.

## §8 Rejected alternatives (do not re-attempt blind)

- **Keep hardening the cleanup pass.** The ratchet + inventory + audits already do; §2
  explains why that is permanent policing of a model whose default is unsafe. Rejected
  as the program's premise (owner direction, 2026-08-20, Arc A plan §0).
- **A permanent dual-mode reset (flag: reconstruct vs clean).** Two reset paths = the
  hand-synchronised-twins failure mode the teardown-shared-core arc closed (twins
  drifted twice in two days, leaking product bugs). One path ships. (Scratch preludes
  during the arc are harness-side and die before it closes.)
- **An iframe-per-test / page-reload-per-test suite.** Isolation without touching the
  product — but it abandons the product goal (the owner wants a true reset as a product
  capability), costs a boot per test, and leaves `resetWorld` broken.
- **Re-homing the 7 `cacheFor*` LRUs off-world to preserve warmth.** Rejected pending
  S3 evidence: warmth is not a correctness input (the determinism contract already
  forbids it mattering), and an off-world text-cache keyed store is a standing exemption
  the doctrine would carry forever. Revisit ONLY if S3 shows an unacceptable wall-clock
  delta — then as a conscious owner decision, not a default.
- **Routing DOM listeners through `window.world` instead of detach/attach.** Superficially
  cheaper than D-P2e + D3(a), but it leaves 20 permanently-attached closures whose
  correctness depends on a global read INSIDE event dispatch, keeps the old world's
  `@inputEventsQueue` reachable from live listeners until swap, and forfeits the
  symmetric attach/detach pair the harness already exercises per test. The detach verb
  exists and is proven; ship it.
- **A `FinalizationRegistry`-based world-death oracle.** Already rejected in Arc B (§8
  there): WeakRef-deref-after-forced-GC is the same oracle made synchronous.

## §9 References

- `../architecture/world-lifetime-and-inventory.md` — the doctrine + both gates (§1, §6).
- `../architecture/lint-and-static-checks.md` — the 26 build gates D-P2a/D-P2e must stay
  clean against.
- `../archive/world-inventory-instruments-plan.md` — Arc A: program statement (§0), the
  in-band instrument, the find ledger (§5.1/§5.2).
- `../archive/world-vm-truth-riders-plan.md` — Arc B: the oracle machinery + every
  measured mechanism number (§5); the door-callback law (D6).
- `../archive/teardown-shared-core-plan.md` — ONE core, two callers; the twins case law
  D2 re-applies to construction.
- `../archive/resetworld-teardown-completeness-audit-plan.md` — the 14-leak audit that
  produced the ratchet this arc reframes.
- `Fizzygum-tests/DETERMINISM.md` — the contract; §2d/§3h are this arc's motivating case
  law; §3g is D-P2b/S3's territory.
- `docs/BACKLOG.md` § object-lifetime program — the remit lines this plan absorbs.

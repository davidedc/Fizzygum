# World reset by reconstruction — Arc C of the object-lifetime program

**STATUS: ARC CLOSED 2026-08-21 — all five phases executed and pushed.** This box is the ledger.
Plan authored 2026-08-20 (phases 1+2 same day); phases 3, 4 and 5 on 2026-08-21.
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
**Phase 3 — THE FLIP — EXECUTED + PUSHED 2026-08-21** (Fizzygum `21c638d7` / tests `43d503c3b`):
`resetWorld` ships as destroy + `new WorldWdgt` + swap. Suite 307/307 byte-identical, `fg homepage`
green, gauntlet 17/18, ZERO recaptures. The one red leg (`vmtruth`) is D4a/D4b.
**Phase 4 — EXECUTED + PUSHED 2026-08-21.** D4a CLOSED (the retainer was the test loader's
never-released `<script>` onload chain). D4b: the residue that remained is NOT A LEAK — it has no
retaining heap edge, so the gate was rebuilt to ask REACHABILITY in two tiers and the grace period
was DELETED (Fizzygum `054e7580` + `9f53e38c`, tests `98f38a592` + `8b89c9be2`; gauntlet 18/18
TWICE, `fg homepage` twice, zero recaptures). D4c fixed. D4 CLOSED. D5: all four plants proven and
removed, both repos clean after — and plant (3) returned a FINDING instead of a confirmation, D5c.
**Phase 5 — EXECUTED + PUSHED 2026-08-21.** D6: `WorldInventory` promoted into core as a pure
`git mv` with ZERO `parts.json` change (`core` already claims `src/`), the harness's now-dead
existence guard removed, `fg homepage` green with production carrying the class. D7: every doc still
arguing the pre-flip reset repaired rather than annotated — `DETERMINISM.md` §2d (heading included)
and §3h, `Fizzygum/CLAUDE.md`'s two teardown bullets, this doctrine's §1, `heapsnapshot.js`'s stale
anonymity note. Then D5c's two decisions taken (above), and A7 fixed with a gate proven non-vacuous.
⛔ ONE ITEM DELIBERATELY NOT TAKEN AT THE CLOSE, and it was the owner's call: the
`RESETWORLD_INCOMPLETE` rename/retire (§6). The ratchet asserts construction determinism but still
carried the reset-era name in its method AND its token; that is a focused cross-repo sweep, not an
end-of-arc tail. **TAKEN AND CLOSED 2026-08-21 as a RENAME** (`WORLD_CONSTRUCTION_DRIFT` /
`_auditWorldConstructionDeterminismNoSettle` / `_firstWorldFingerprint`) — the ledger, including
what the blast radius filed here got wrong in both directions, is the `docs/BACKLOG.md` DONE line.
⚠ §6 and the plan body below keep the old spellings: they are the verbatim record of what was true
when written, and the token they name is the one this plan shipped.

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
`window.world`); `AutomatorEventCommandResetWorld` is unchanged.
`_resetWorldNoSettle` and its pristine-look block are DELETED — every item in it is
constructor state now (colour, wallpaper, `numberOfIconsOnDesktop`'s class default, a
fresh `untitledNamingService`, a fresh prefs bag, and the 960×440 extent, which the
constructor re-establishes through `_sizeCanvasToTestScreenResolution` on the harness
page) — and `PreferencesAndSettings.resetToBootInputMode` dies with it, its only caller:
"put the bag back the way the constructor left it" IS construction here. `isDevMode =
true` moves into `finishWorldSetup`, since boot sets it for every page.

**TWO harness hooks, not one** (decided at execution, correcting this section's earlier
single-hook shape): `_beforeWorldDissolveNoSettle?()` fires on the OLD world after the
teardown and carries the **storage Tier A audit**, because that audit asks whether the
finished test left residue the teardown could not reach — a question about THAT world,
and vacuous asked of a freshly-built one (it would have audited an empty world and passed
for ever). `_afterWorldResetNoSettle?()` fires on the NEW world after `finishWorldSetup`
and carries the reframed ratchet + the inventory audit + the harness's page-scroll
ergonomic + a re-application of `removeEventListeners` while a test is playing (see the
determinism note in D3). The teardown core keeps being gated on the old world, which
matters because `loadWorldSnapshot` still calls it.

`resetWorld` answers `undefined` on purpose: the new world is `window.world`, and
answering it instead would make every `page.evaluate(-> world.resetWorld())` — the shape
`heap-forensics.js` already uses — serialise a cyclic widget graph over CDP.

⚠ The `id` question is DECIDED, and its PLACEMENT was corrected at execution:
`_dissolveWorldNoSettle` zeroes `WorldWdgt.lastBuiltInstanceNumericID`, so every
reconstructed world is `WorldWdgt#1` and world identity is run-history-free (the §3h
determinism shape applied to the world itself) — but the `continue if eachClassFunction
is WorldWdgt` line in `fullDestroyChildren` **STAYS**. Deleting it (the original text
here) would break the OTHER caller of that sweep: `loadWorldSnapshot` tears down without
building a successor, so it would leave the counter at 0 under a live `WorldWdgt#1`, and
nothing could repair it — `Serializer.collectIdCounters` skips `WorldWdgt`, so a snapshot
carries no counter to restore. Zeroing belongs where a world is actually REPLACED.

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

Three things this deliverable gained at execution, each from a hazard the spikes could not
have seen (S1 measured a corpse tail whose hand was still alive):
- **(ii) is REQUIRED, not optional, and it is a `doOneCycle` seam rather than an early-out
  at the top.** The corpse's remaining stations include
  `@hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges()`, and (b) has
  just destroyed the hand. The guard is `return @_closeCycleBookkeepingNoSettle … if
  @_dissolved` at BOTH stations from which a reset can run — after `_playQueuedEvents`
  (a menu action) and after `replayTestCommands` (every SystemTest's first command) —
  with the per-PAGE cycle tail (the compile-budget drain, `frameCount++`, the cycle-date
  hand-off) extracted into `_closeCycleBookkeepingNoSettle` so a reset landing mid-cycle
  does not make the page's frame clock skip a beat.
- **A determinism repair, not a leak repair.** `AutomatorPlayer.startTestPlaying` calls
  `world.removeEventListeners()` at the start of every test so a macro's synthetic events
  are the ONLY input; a reconstructed world re-attaches all 20 in its constructor,
  mid-test. `_afterWorldResetNoSettle` re-applies the detach while `Automator.state is
  Automator.PLAYING`. Missing this would not leak — it would let a real browser event
  into a running test, which is the DETERMINISM.md contract, not the lifetime one.
- **`finishWorldSetup` must NOT carry `startWorld`'s page-scoped block.** `installOnto`
  copies statics BY VALUE and two of them are the page-lifetime audit baselines (D-P3c),
  so re-running it would silently re-arm both gates' "first teardown" branch; re-running
  the `animloop` line would start a second permanent `doOneCycle` pump; and
  `removeSpinnerAndFakeDesktop` dereferences a `null` on a second call (it gains an
  idempotence soak regardless, since it is about the loading page, not the world).

### D-P3c — instruments survive the flip (its own commit, landed BEFORE the flip)

**Executed as a separate, independently-gated commit** rather than inside the flip: every
edit below is bit-for-bit equivalent on a one-world page (a prototype write and an
instance write have the same effective value at every read; a page-scoped baseline and a
world-scoped one have the same lifetime when there is one world), so it lands and is
gated while the old semantics still hold, and the flip commit stays the flip. The census
behind it found the arming hazard is SIX instruments, not four — the five gate preludes
(`tier-naming`, `notification-settle` ×2 flags, `paint-readonly`, `eoc-capstone`,
`cache-oracle`) plus the hand-run `eoc-production-probe` — and that `paint-readonly` is
the only one that also holds a CAPTURED world inside a permanently-installed wrapper
(`world.healingRectanglesPhase` in the `_invalidateLayout` wrap), which would have frozen
its predicate at a dead world's paint phase. ⚠ The two baselines are carried onto
`WorldWdgt` by `@staticMembersToInstall`, which copies BY VALUE at boot — so nothing may
ever re-run `installOnto` per world (see D3's third execution note).

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

### D4a — CLOSED: the retainer was the test loader's never-released `<script>` onload chain

**The answer, from a heap-snapshot retainer path:**
```
Window -> BitmapText -> _fontLoader -> FontLoaderBase -> _metricsScriptElement
  -> HTMLScriptElement -> HTMLScriptElement -> HTMLScriptElement   (the head-script chain)
  -> EventListener -> V8EventHandlerNonNull
  -> closure --context:andThen--> "selectTheTestsBasedOnTags"
  -> closure --context:andThen--> closure
  -> system / Context --context:this--> WorldWdgt
```
`AutomatorLoader.loadTestMetadata` appends one `<script>` per test to `document.head` and never
releases its `onload`. The element is page-lifetime by design (`WorldInventory`'s `dom.headScripts`
row declares exactly that), so every one-shot handler keeps its closure — and the closure captures
`andThen`, the after-selection callback chain, which on the `?startupActions` path ends in
`WorldTestSupport.nextStartupAction`'s own `=>`, capturing the WORLD it was created on. ~300 head
scripts therefore pinned one dissolved world, and with it every widget that world had owned — which
is why the same run reported ~2700 uncollected WIDGETS alongside it. **Both fixed:** the handler
releases itself (`script.onload = null`, the sanctioned foreign-API spelling), and the startup
callback became a plain function reading the `world` global at call time instead of capturing `@`.
⇒ `fg vmtruth`: **OK — every destroyed widget collectible, heap floor flat, 307 buckets, 8 pages.**

### D4b — the RESIDUE is not a leak: it has no retainer, and the measurements that establish it

**The finding.** What is left after the head-script fix is NONDETERMINISTIC AROUND ZERO — 0–2 events
per 307-test run, some runs clean — and every event is the SAME object set: `BinWdgt#1` plus exactly
its chrome (`ViewportWdgt#1`, `ScrolledPaneWdgt#1`, `SliderWdgt#1/#2`, `SliderButtonWdgt#1/#2`,
`StringWdgt#1`, `SimpleButtonWdgt#1`), usually with `WorldWdgt#1` alongside. It is held for a bounded
number of resets (1 bucket in one run, ~8 consecutive in another, ages 2–3 typically) and then
RELEASES ON ITS OWN. It never accumulates and the heap floor stays flat throughout.

**⭐ IT HAS NO RETAINING HEAP EDGE. Measured three independent times**, with a probe that stops the
page in the same turn as the detection (`WorldWdgt.prototype.doOneCycle` becomes a no-op, so no JS
can run to release anything) and only then takes a heap snapshot and walks the retainer path. A V8
snapshot serialises only REACHABLE objects, and a frozen page cannot drop an edge — so "no path at
snapshot time" means there was no path at detection time either. Rig:
`Fizzygum-tests/.scratch/frozen-retainer-probe.js`.
⚠ **And the instrument proves itself**: it plants a destroyed widget in an ordinary strong global and
requires its own BFS to name that path in the same run. The control PASSES (`Window --property:__plant-->
SimpleButtonWdgt`) while every genuine suspect comes back with no path — including while `__stuck`
holds both, so the holder-exclusion is not what is suppressing the answer. Without that control,
"no path found" would be unfalsified instrument output rather than evidence.
⚠ A planted run cannot also MEASURE, and the first one silently did not: the first destroyed
`SimpleButtonWdgt` on this page IS the bin's "Empty bin" button, whose `@target` is the bin, so the
plant pinned the very set under measurement and every suspect duly "had a retainer" — the plant's.
Evidence therefore comes from two populations: unplanted runs measure, planted runs validate.

**Why the corpses survive a forced GC at all — and what the one-teardown grace is actually buying.**
An A/B over the sweep POSITION (`.scratch/survival-curve-probe.js`, which histograms every corpse at
every sweep by age instead of waiting for the rare tail event) settles it:

| sweep runs from | corpses alive at age 1 | age ≥2 (what the gate REPORTS) |
|---|---|---|
| inline, inside `resetWorld`/`doOneCycle`/rAF (as shipped) | 20781 | 0 that run |
| a fresh macrotask (`setTimeout 0`) | 40 | 20 |

⇒ the live frames of the world cycle are what keep ~68 corpses per sweep alive through the immediate
double GC — a ~500× effect, and exactly what `world-lifetime-and-inventory.md` §6 already says the
grace exists for. ⛔ A refinement of that model — "stale pointers in stack memory below the current
frame, which is why some persist for several sweeps" — was TESTED AND FALSIFIED: recursing 1500
frames deep to overwrite that memory before each GC left the count *identically* 20781. It is live
frames, not stale slots. Do not re-run the scrubber.

**⛔ Models tried and falsified for this residue (do not re-run):**
1. *Another unreleased one-shot async handler, the family of the head-script fix.* A full sweep of
   both repos found NO page-lifetime harness slot holding a widget or a world at all — every `world`
   reference in `Automator-and-test-harness-src` is a bare global read at call time. The three fixed
   `AutomatorLoader` sites are verified still fixed. `AutomatorPlayer.createImageFromImageData`'s
   `img.onload`/`onerror` pair is genuinely unreleased but captures no widget, never enters the DOM,
   and never runs during a suite — tidy-up, not a retainer.
2. *The sweep's own stack position.* Deferring collapses the age-1 noise but leaves the residue
   standing (table above), and the frozen-snapshot result holds in both arms.
3. *The cold-glyph store's ordering defect.* `swCanvasColdGlyphWidgets` is a page-lifetime STRONG
   array of widgets whose teardown filter runs at the end of `_teardownWorldStructureNoSettle` —
   one destroy-phase too early, since `_dissolveWorldNoSettle` kills hand/bin/shelf/world after it
   (see D4c). It predicts this residue exactly. Asked in the detection turn itself, via the module's
   own `window.swCanvasTextStateForAudit()` porthole, the array is **EMPTY**. REFUTED on its own
   prediction. (The ordering defect is still real — D4c — it just is not retaining anything today.)
4. *Widening the grace.* Already falsified upstream: worlds given a third teardown of grace were
   still reported, across FOUR buckets. The prelude carries that negative result at the test itself.

⇒ **Reading: the residue is a GC-timing artifact at the sweep seam, not a product leak.** The objects
are unreachable when the gate reports them; the forced `gc(); gc()` simply has not reclaimed them
yet, and a later sweep does.

**⭐ WHY THE SET WAS ALWAYS THE BIN'S SUBTREE — measured, and it is now fixed (D5b).** The set was
never a coincidence of which objects the collector happened to miss: it is ONE CONNECTED GARBAGE
CLUSTER. `_dissolveWorldNoSettle` nulls `@binWdgt`/`@shelfWdgt`/`@hand`, but the world's per-cycle
WIDGET COLLECTIONS still named them — destruction RE-MARKS a dying widget (it posts damage so its
pixels get erased, and its layout queue entry likewise), and those collections were last filtered by
the shared teardown core, which runs a whole destroy-phase EARLIER. So a dissolved world reached its
bin's whole chrome through `widgetsWithMaybeChangedFullPaintBounds` / `widgetsThatMaybeChangedLayout`,
and world-plus-bin-subtree lived or died together. The HAND and the SHELF are absent for the reason
their own classes give: neither is ever painted, so destroying them posts no damage and they never
enter a queue — they are single unconnected corpses, collected independently.
Proved by the D5 plant: a closure over ONE world reported **8 retained worlds and 72 retained
widgets**, every widget reached ONLY through one of those queues; with every widget collection reset
at dissolution the same plant reports **8 worlds and 0 widgets**. ⇒ a retained world is now ONE
finding instead of ten, and the green suite's tier-1 suspect count fell from 20/50/30 to 7.
⚠ The fix resets ALL EIGHT of the world's widget collections, not the two that showed up in a
retainer path: the paint queues and then the layout queue were each found this way in turn, and
enumerating "the ones that bite" is how the next one is missed.

⇒ **The fix is instrument-side, and it is not a wider tolerance** — it is the opposite. The sound
oracle for "is this retained?" is REACHABILITY, not "did the collector get to it?", so the gate now
asks that question and the tolerance becomes unnecessary rather than merely bigger. **The grace
period is DELETED.** Tier 1 (the prelude) reports a SUSPECT at the first sweep after a widget's
destroying reset and PINS it so a snapshot can still address it; tier 2 (`run-all-headless.js` under
`AUDIT_RETAINER_CONFIRM=1`) takes one heap snapshot per shard at shard end, marks forward from the
GC root with the pin arrays subtracted, and the gate fails only on a suspect that is still reachable
— printing its retainer path. Landed with the sweep moved OFF the world cycle (the measured
20781→40 position). Details: `world-lifetime-and-inventory.md` §6.
⭐ **The nondeterminism did not disappear; it moved to where it belongs.** Three consecutive
`fg vmtruth` runs on the landed tree raise 20 / 50 / 30 tier-1 suspects — the garbage genuinely does
vary run to run — and all three clear every one and report OK. The VERDICT is now deterministic
while the suspect count stays an informational counter, which is the honest shape: the gate no
longer pretends the variation is not there, it just no longer mistakes it for a leak.
⚠ Two implementation facts worth keeping, both measured rather than reasoned:
- **Subtract the pin BY NODE, and subtract it entirely — do not merely refuse to traverse it.** A JS
  array reaches its elements through an `(object elements)` backing-store node, so walling only the
  array leaks straight through the store and every suspect comes back retained by the instrument's
  own pin. A backing store belongs to exactly one object, so dropping the owner drops the store.
- **The confirmation proves itself** (`.scratch/reachability-selftest.js`, plain node, no browser):
  a synthetic snapshot in which one target is reachable ONLY through the pin must read UNRETAINED
  and one also reachable by an ordinary property edge must read RETAINED with that edge named —
  plus the control that the first target IS reachable when the pin is not subtracted, without which
  the test would pass vacuously.

### D4c — a live ordering defect the hunt turned up (worth fixing on its own merits)

`_teardownWorldStructureNoSettle` ends with two filters that drop references to what was just
destroyed — the cold-glyph store (`WorldWdgt.coffee:3063`) and the per-cycle damage queues — and
both carry comments stating they must be the teardown's LAST act, after every destroy. That was
true when the teardown WAS the last destroy phase. `resetWorld` now runs a FOURTH:

```
@_settleLayoutsAfter => @_teardownWorldStructureNoSettle()   # both filters run HERE
@_beforeWorldDissolveNoSettle?()
@_dissolveWorldNoSettle()                                    # hand, bin, shelf, WORLD die HERE
```

so those four are still `destroyed == false` when the filters pass over them and survive both. The
cold-glyph array happens to be empty at that moment today, so nothing is retained — but the
invariant each comment states was no longer held by the code, and the next thing to record a widget
there would have retained it.
**FIXED:** `_dissolveWorldNoSettle` runs `window.swCanvasDropDestroyedColdGlyphEntriesForTeardown?()`
as its own last act, once the hand, the two containers and the world are actually corpses (the filter
keys on `destroyed`, which is only true for them there). It is idempotent — it rebuilds the array
from a predicate — so both calls stand, and neither is redundant: the core's pass covers the tree
and is the ONLY one `loadWorldSnapshot` gets, since that path keeps its world and never dissolves.
Both call sites now say which phase they cover.
**And the same defect, in the world's OWN collections (D5b, fixed here too).** The reasoning that
"the damage queues are world-instance fields, so on the reset path they die with the world" is true
about RETENTION and false about the seam contract: dissolution promises, in its own comment, to
"hold no reference to what was just destroyed", and it was holding the hand, the containers and the
whole bin subtree in eight per-cycle widget collections that the core had filtered a destroy-phase
too early. It costs real signal — see D4b: it inflated a one-world leak into a ten-object report.
Dissolution now resets all eight to their empty shapes.
⚠ On the `loadWorldSnapshot` path nothing changes: that path keeps its world and never dissolves, so
the core's single pass is still the last act after every destroy it makes.

⭐⭐⭐ **PRE-EXISTING, and only reconstruction could expose it.** Those closures always pinned the
boot world; before this arc no world was ever destroyed or unregistered, so nothing ever asked. It
is the Arc B door-callback law's own shape — a one-shot async callback outliving its subject — at
the one seam Arc B could not see.

⚠⚠ **THE HUNT'S LESSON, worth more than the fix: an instrument that does not reproduce a finding
may be MISREPORTING ITS OWN CONDITIONS.** Five configurations read CLEAN — `heap-forensics`
`--boot-only` / one test / three tests, and a purpose-built probe at 40, 60 and 307 tests, with the
real prelude injected and the real Chrome flags — while `vm-truth-gate.js -- --shards=1` reproduced
every single time. The difference was never the page, the prelude, the flags, the test count, the
console listener or parallel load: it was HOW THE TESTS WERE STARTED. Every clean configuration
called `selectTestsFromTagsOrTestNames(names)` from CDP with **no callback**, so nothing captured a
world; the runner drives `?startupActions=`, which passes the world-capturing callback. A probe
that drives the subject differently from the thing it is modelling is not a smaller version of it.
⛔ Also do not let a probe answer with ITSELF: pinning the survivor to snapshot it made this probe a
retainer, and the first path it printed was its own array — reached by an `internal:<slot>`
PropertyCell edge that no edge-NAME filter can catch. Exclude the holder by heap NODE id.
The rig is kept at `Fizzygum-tests/.scratch/world-retainer-probe.js`.

### D4a (historical) — how the finding read before it was closed

Measured on the flipped tree (full gauntlet, `vmtruth` leg): **17 of 18 legs green; `vmtruth`
FAILS**, and the failure is sharply bounded. What it says, and what it does not:

- **Almost every reconstructed world is collected**: across ~300 resets per page the oracle
  reports ONE stuck world per shard page (rarely two), not one per reset.
- ⚠ **WHICH world sticks is NONDETERMINISTIC** — and this is the finding's most diagnostic
  property, so it is recorded before any explanation. Run 1's seven `destroyedDuring:` values were
  each shard's FIRST test, which reads as "the boot world is pinned"; run 2 of the same leg on the
  same build named nine scattered mid-run tests instead (report counts 380 / 330 / 10, i.e. stuck
  from early, middle and late in the run). A structural retention would name the same code path
  every time. ⛔ Do not repeat the mistake this correction records: ONE run of this leg is not
  enough to characterise it.
- **It does not accumulate.** `0 heap-floor failure(s)` over the whole suite: the pin is one
  world, not one per reset. (Contrast S1's pre-repair measurement, +1.7 MB *per swap*.)
- **The retained set is that world plus its BIN subtree** (`BinWdgt`, `ViewportWdgt`,
  `ScrolledPaneWdgt`, two `SliderWdgt` + two `SliderButtonWdgt`, `StringWdgt`,
  `SimpleButtonWdgt`) — the hand and the shelf are NOT retained, which is the discriminating
  detail any explanation has to account for.
- **It is newly VISIBLE, not necessarily newly created.** Before this arc no world was ever
  destroyed or unregistered, so nothing ever asked whether something held the boot world.

⚠ **The forensic tool does not reproduce it**, which is itself the most informative fact:
`heap-forensics.js --boot-only --snapshot`, `--test=<the first test>` and `--tests=<first three>`
all report CLEAN (`uncollected 0`, `VM corpses 0`) on the same tree — so from a CLEAN stack the
boot world IS collectible. Both tools force GC identically (`window.gc(); window.gc()`), so
collector thoroughness is not the difference. The difference that remains is WHERE the sweep runs:
`heap-forensics` sweeps from its own `page.evaluate` turn, while the gate's prelude sweeps INSIDE
`resetWorld`, inside `doOneCycle`, inside the rAF callback.
**Sharpest characterisation (3 runs): EXACTLY ONE stuck world per shard page, every run.** Run 3
(8 shards) named exactly 8 distinct worlds — one per page — and 7 of its 8 blamed tests match run
2's, so the shape is reproducible even though the identity is not fixed. Heap floors across that
run: +3.7 / +10.2 / −7.8 MB against a 96 MB limit. "Exactly one arbitrary world per page, never
accumulating" is the shape of a SINGLE-SLOT retainer, and any candidate explanation has to produce
that shape.

⛔ **THREE MODELS TRIED, ALL FALSIFIED — do not re-run these experiments:**
1. *"It is the BOOT world"* (run 1 named every shard's first test). Falsified by run 2, which named
   scattered mid-run tests. Run 1 ran under the gauntlet's 6-shard split, runs 2–3 standalone at 8.
2. *"It is the gate's SWEEP POSITION — a stale stack slot conservatively scanned"* (the sweep runs
   inside `resetWorld`, inside `doOneCycle`, with the dissolved world in live frames; and
   `heap-forensics` sweeping from a clean `page.evaluate` turn reproduces ZERO). **Tested directly:
   the sweep was deferred off the cycle (`setTimeout 0`, `batch` still advancing per reset) and the
   result did not move — same ~2990 findings, same one-world-per-page.** The deferral is reverted;
   the negative result is recorded at `sweepAfterTeardown`'s own comment so it is not re-tried.
3. *"A cold-glyph module entry pins a widget, and its `cachedRoot` pins the world"* — fits the shape
   and the retained set (a bin's `StringWdgt` plus its parent/children chain), but
   `swCanvasDropDestroyedColdGlyphEntriesForTeardown` runs at EVERY teardown, so such an entry
   cannot survive the next reset. Not excluded as a contributor; insufficient as the mechanism.

⇒ **What the next session needs is an INSTRUMENT, not another hypothesis.** No existing tool
reproduces it: `heap-forensics` is clean at 1–3 tests, and the gate that sees it cannot name a
retainer. The decisive rig is the two rails married — run the suite under the vm-truth prelude, and
when a world is still uncollected two batches on, take a heap snapshot IN THAT PAGE and walk the
retainer path (`context:<var>` edges name the exact closure variable). That is one focused probe,
and it answers the question outright instead of narrowing it.

**Owner decision at the checkpoint**, since this is the arc's own acceptance gate: land the flip
with the finding characterised and D4 owing the sweep-position fix, or hold the commit until the
rider is built and the leg is green.

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

**CLOSED 2026-08-21 — both halves met.** Green: `fg vmtruth` OK repeatedly on the landed tree
(and as gauntlet leg 18/18). Fails on the plant: D5(1) above, `FAILED — 8 RETAINED WORLD(s)`,
one per shard page, the ⭐ REPLACED-WORLD line naming the holder in its retainer path. The rider
shipped in a different shape than this section anticipated — the world finding is distinguished by
an `isWorld=true` flag on the tier-2 retainer label rather than by a distinct tier-1 token, because
the gate's verdict now comes from REACHABILITY (D4b), not from the collectibility proxy this
section was written against. The budget was not bumped.

### D5 — prove the gates FAIL (mandatory, per standing case law)

**Evidence in hand before the plants are written** (first suite run of the flipped tree): the
reframed ratchet fired 245 times, on ONE field — `lastTime` — with `failed: 0` beside it, i.e.
every one of the 307 tests rendered byte-identically on a reconstructed world while the ratchet
loudly reported a construction-time difference. That is the answer to §7's risk 4 for this gate:
it is diffing, not stuck in its "first teardown" branch. The finding itself is legitimate and now
exempted with its reason — `Widget`'s constructor seeds `@lastTime = Date.now()` and the world is
a widget, so two worlds built at two instants always differ there; on the world the field is inert
(`lastTime` is per-member stepping bookkeeping, read only for `steppingWdgts` members, and the
world never joins its own set). ⭐ It is the ONE exemption reconstruction itself creates: under a
reset that REUSED the world object the field was written once at boot and never moved again, so it
never had to be named. D5(2)'s plant is still owed — this proves the gate is ARMED, not that it
fails on a planted drift.

**ALL FOUR PLANTS EXECUTED AND REMOVED 2026-08-21; both repos verified clean afterwards
(`git status --porcelain` empty).** Every plant lives in an injected PRELUDE or a runner's
`addInitScript`, never in `src/` — the preludes are read from the tests repo at runtime and the
stale-build guard only hashes `.coffee`, so none of these needed a build.

(0) **Closure retention** (the fourth plant, discharged first because it was also the instrument
for D4b): a closure over ONE world ⇒ `fg vmtruth` FAILS, path names `--context:plantedWorld-->`.
Its measured payoff is recorded in D4b: 8 worlds + 72 collateral widgets before the widget-collection
fix, 8 worlds + 0 after.

(1) **World pin** — `vm-truth-prelude.js` holds the first replaced world of each page in a plain
`window.__d5PlantedWorld`. ⇒ **`fg vmtruth` exit 1**, `FAILED — 8 RETAINED WORLD(s), 0 retained
widget(s), 0 heap-floor failure(s)`, one per shard page (the single-slot shape D4a called for), each
carrying the ⭐ REPLACED-WORLD line and the path
`synthetic "" --shortcut:2--> object "Window / file://" --property:__d5PlantedWorld--> object
"WorldWdgt" @id=155937`. The suite stayed green throughout (`failed 0` at every progress line), which
is the other half of the acceptance. ⇒ **D4's rider is proven armed**, through a `property` edge —
plant (0) had proven it through a `context` edge, so the two together cover both edge kinds.
⭐ Two free readings: `0 retained widget(s)` re-confirms the D4b/D5b collateral fix by a different
route than the one that found it, and the node reads `object "WorldWdgt"` rather than `object ""` —
D-P2g's named constructors, end-to-end, which is what makes `heap-forensics.js`'s "instances are
anonymous" note stale (D7).
⚠ Three ways this plant could have proved the wrong thing, all avoided deliberately: hung off a
`WorldInventory` walk root it would have failed the SUITE (the gate then exits on "the suite itself
FAILED" and never reaches its retention verdict); emitting a novel `LAYOUTAUDIT VMTRUTH` line it
would have failed as an unrecognised token (prelude/gate disagreement, not retention); pinning one
world PER RESET rather than per page it would also have tripped the heap floor, and which gate bit
would have been unreadable.

(2) **Construction drift** — a `PRELUDE_JS` pre-hook on `_afterWorldResetNoSettle` writes
`this.__d5ConstructionSerial = ++n`, so every constructed world fingerprints differently. Run through
`run-sequence-headless.js` (3 tests, ONE page — the ratchet needs ≥2 diffed worlds, and this is
seconds rather than a suite). ⇒ **exit 1**, twice:
`RESETWORLD_INCOMPLETE __d5ConstructionSerial firstWorld=1 thisWorld=2` and `…thisWorld=3` —
matching the predicted arithmetic exactly (the boot world is never fingerprinted, world #2 takes the
baseline, world #3 onward is diffed).
⭐ **With its negative control**: the same plant writing a CONSTANT fires nothing (exit 0, zero
tokens, `failed: none`). So the ratchet compares VALUES, not presence, and the fire came from the
drift rather than from the field's mere appearance. Without that arm, a plant that merely ADDED a
field would have looked like the same success.

(3) **Audit-arming regression — EXECUTED, and it returned a FINDING rather than a confirmation.**
See D5c: the deliverable's premise ("the corresponding gate leg must lose its positive-coverage
line") is false for the whole `world.audit*` family, because no such line exists. The intent behind
it — §7 risk 4, an instrument silently disarmed by a reset must be VISIBLE — was proven instead on
the one leg that does carry a real coverage ratchet, `fg paint`: disabling only the per-test audit
tick once the world has been reconstructed (deliberately NOT nuking `world.macroToolkit`, the tick's
real per-world dependency, which would have broken every macro-driven test and made the gate fail
from broken tests rather than a coverage hole) gives
`✗ PAINT-TRUTHFULNESS GATE FAILED: checked 0 != expected 307 — a shard dropped tests (coverage
hole)`, exit 1, with `audit on : true` proving the page-global half survived. That is risk 4
defended, loudly and specifically.

### D5c — FINDING: the `world.audit*` family has no arming tripwire, and two of its flags are DEAD

D5(3) set out to prove that losing an instrument's arming is visible. It is not — and the way it is
not comes in two separable parts, both measured rather than argued.

**(a) A lost flag turns a red gate green, with its coverage line intact.** Measured on `capstone`,
the leg whose flag (`auditUndeclaredEndOfCycle`) is the one genuinely load-bearing member of the
family (it gates the recording at `Widget._invalidateLayout`). The experiment separates the VIOLATION
from its RECORDING exactly as the product does — a careless push happens once per test regardless,
and only the recording sits behind the flag:

| arm | flag on reconstructed worlds | violations that occurred | `careless pushes` | verdict |
|---|---|---|---|---|
| A | armed (as shipped) | 307 | **307** | ✗ FAILED, exit 1 |
| B | lost (instance write shadows the prototype default) | **307** (logged per test) | **0** | **✓ PASSED, exit 0** |

Both arms report `prelude installed=307/307`. ⇒ **307 real violations, a green gate, and a coverage
line that never wavered.** The gate's only "coverage" number is a prelude-INSTALL count, and it is
computed from a synthetic header string `run-all-headless.js` writes itself — so it is blind to the
flag by construction. The same shape holds for `tiernaming`, `settle`, `storage` and `revisits`
(none has a non-zero-expectation assertion); `fg paint` and `fg vmtruth` are the only legs in the
tree that can currently fail for having measured nothing.
⚠ An intermediate arm B read `6`, not `0`, and the 6 were an ARTEFACT of the plant firing on each
shard's boot world where the flag was still armed — the refinement was to the plant, not to the
model. Recorded because "98 % of the signal disappeared" would have been a weaker and slightly
dishonest way to state a result that is actually total.

**(b) `auditTierAndApplyNaming` and `auditNotificationSettleNeutrality` are read by NOTHING.**
Grep-verified across `Fizzygum/src` + the harness src + `scripts/` + `tests/`: each appears only at
its `WorldWdgt` declaration, its prelude arming line, a log line that merely echoes its own value,
a shell-gate header comment, and `_worldStateAuditExemptions`. Nothing branches on either. Both
gates take all their observations from the preludes' own prototype wrappers
(`tier-naming-prelude`'s `wrapCorner`/`wrapMarker`, `notification-settle-prelude`'s
`wrapCallback`/`wrapSettle`), which never consult the flag. So arming them is a no-op in both
directions, and the two shell headers asserting the gate "flips on `WorldWdgt.<flag>`" are false.
⭐ This is a D-P3c residue worth naming: that unit carefully moved arming to prototype defaults for
SIX instruments, and for two of them the work was moot because the flag does nothing. A third,
`auditPaintTimeLayoutScheduling`, is live product code but its own gate re-implements the predicate
rather than reading it.

**Disposition — BOTH TAKEN 2026-08-21, owner-approved.**

**(i) The two dead flags are DELETED**, with their arming lines, the log lines that echoed them,
their `_worldStateAuditExemptions` entries, and the two shell headers that claimed each gate "flips
on" its flag. ⭐ The blast radius was wider than the finding recorded: `layering-naming-convention.md`
§5.1/§5.2 were TITLED after the flags and its §5 preamble taught the flag as the mechanism, and
`lint-and-static-checks.md` identified both gates by flag — the docs were propagating the false
model, which is the real cost of a vestigial name. All now describe the wrapping, and `WorldWdgt`
carries the rule in place of the fields: any flag in this family needs a READER first.
⚠ `doubleCheckCachedMethodsResults` and `auditPaintTimeLayoutScheduling` STAY — the first has 17+
product readers; the second is live product code even though its own gate re-implements the predicate.

**(ii) The capstone gate now has a real positive-coverage assertion, and it is proven both ways.**
The prelude emits one `LAYOUTAUDIT capstone-armed` line per test, read off THE WORLD THE CYCLE IS
RUNNING ON, and `run-capstone-gate.sh` requires that count to equal the per-test log count —
symmetric with `run-paint-audit.js`'s `checked == expectedTotal`. Measured:

| arm | `flag armed` | `careless pushes` | verdict |
|---|---|---|---|
| as shipped | **307/307** | 0 | ✓ PASSED |
| arming lost on reconstructed worlds | **6/307** | 0 | **✗ FAILED — "the audit measured nothing there"** |

⇒ the configuration that previously reported `✓ CAPSTONE GATE PASSED` on 307 real careless pushes
now fails, naming the blindness. Both arms still print `prelude installed=307/307`, which is the
point: that number is synthesised per test by the runner and can never see an unarmed flag. (The 6
are each shard's boot world, before its first reset.)
⚠ The other legs sharing the shape — `tiernaming`, `settle`, `storage`, `revisits` — are NOT fixed
here. Two of them no longer have a flag to lose at all (i); the remaining question is whether a
leg with no non-zero-expectation assertion of any kind should acquire one, which is a design
question about those gates rather than a residue of this arc.

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

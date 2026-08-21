# World lifetime and the inventory instrument

How Fizzygum accounts for what is alive on a page, and the doctrine that accounting serves.
Companion code: `src/WorldInventory.coffee` (the instrument),
`Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee`
(`_auditWorldInventoryNoSettle`, the gate seam), `WorldWdgt.graphLivenessRoots` (the shared
root enumeration). Program plan: `docs/archive/world-inventory-instruments-plan.md` (Arc A of
three; Arcs B and C are future arcs, described there).

## 1. The two-lifetimes doctrine, enforced by construction

Every piece of state on a Fizzygum page belongs to exactly one of two lifetimes:

- **PAGE lifetime** — state that legitimately survives any world reset: the code itself
  (classes, the `SourceVault`), the font atlases and the metrics probed off them
  (`minimumFontHeight`), interned immutables (`Color._permanent`), memo caches that are pure
  functions of their keys (the `world.cacheFor*` LRUs, the `Object::hashCode` memo), and
  lifetime counters (`instancesCounter`).
- **WORLD lifetime** — everything else: widgets, their bookkeeping, collaborator state, app
  slots, DOM side effects. It dies with the world.

**`resetWorld` ENFORCES the split by construction.** It destroys the old world
(`_dissolveWorldNoSettle`), builds a replacement (`new WorldWdgt` + `finishWorldSetup`) and swaps
`window.world`. So world-lifetime state does not have to be *remembered* into oblivion by a cleanup
pass — it dies with the object that owned it, and state survives a reset only when it structurally
lives somewhere else. The doctrine stopped being a convention that an audit polices and became a
property of the machinery.

⚠ **That does not retire the inventory, it re-aims it.** Two things construction cannot decide:
- **Did the old world actually die?** Reconstruction is only enforcement if nothing still holds the
  corpse — one retained world holds its entire object graph. That is §6's question, and it is asked
  as REACHABILITY, not as collectibility (see §6: the proxy has false positives by construction).
- **Is page-lifetime state behaving like page-lifetime state?** Everything OFF the world — class
  statics, collaborator and module state, caches, the DOM — crosses every reset untouched, and an
  unbounded or accreting store there is a leak no reconstruction can fix. That is the walk below:
  **everything alive after a teardown must be (a) part of the post-boot baseline, (b) a declared
  page-lifetime store, or (c) a bug.**

⭐ **The LRU amendment, and why it belongs in the doctrine rather than in a bug list.** A memo cache
that is a pure function of its keys is legitimately page-lifetime — but *legitimately page-lifetime*
is a claim about correctness, not about size. All eight of this page's LRUs (the seven
`world.cacheFor*` plus `Color._cache`) were unbounded in every long session because a single
back-pointer bug made eviction a permanent no-op, and no lifetime rule would ever have caught it:
each cache was doing exactly what its lifetime entitled it to do. ⇒ a page-lifetime store must
declare a BOUND as well as a reason, and the inventory reports the bulk aggregates so an unbounded
one is visible even while it stays "correct".

## 2. What the inventory measures

`WorldInventory.takeInventory()` walks the reachable object graph — read-only,
side-effect-free, ~6 ms — from these roots: the world, every class object (found by the
`instances`-Set marker every class carries, never a name-suffix scan) with its own statics,
the module-state portholes (`swCanvasTextStateForAudit`, `stringHashCacheForAudit`),
`menusHelper`, `demoMenus`. It returns:

- a flat report of **dimensions**: `objects.<Ctor>` counts, container totals
  (`containers.*`), `canvases.count/pixels`, `strings.count/chars`, `typedArrays.count/bytes`
  (typed arrays are LEAVES — enumerating one visits every index), `dom.*`,
  `instances.<Class>` (the live-registry sizes), `statics.<Class>.<field>` and
  `world.<field>` store sizes, `sourceVault.entries`, `classes.count`;
- two **identity lists**: `escapedWidgets` — widgets in `Widget.instances`, not destroyed,
  yet unreachable by containment from `graphLivenessRoots()` + the bin/shelf containers
  (such a widget left the tree without being destroyed, and the registry pins it forever) —
  and `retainedZombies` — destroyed widgets still held somewhere, each named with the
  property path of its retainer.

The identity lists are the instrument's point: "escaped `TextWdgt#14`" is actionable where
"widget count +2" is not.

## 3. The gate and its exemption model

The harness calls `_auditWorldInventoryNoSettle` at the end of every `resetWorld`, beside
the world-field ratchet (`WORLD_CONSTRUCTION_DRIFT`) and covering exactly that ratchet's blind
spots: class statics, collaborator internals, module state, the DOM, and identity. The first
reset takes the baseline; every later one diffs against it and emits, per offence, one of
three console-error tokens the headless runners fail a test on (the shared list:
`Fizzygum-tests/scripts/lib/gate-tokens.js`):

- `WORLD_INVENTORY_DRIFT <key> baseline=<v> now=<v>` — an undeclared store moved;
- `WORLD_INVENTORY_ESCAPED <Class>#<id>` — a live widget became unreachable;
- `WORLD_INVENTORY_ZOMBIE <Class>#<id> at <path>` — a destroyed widget is still retained.

Two tiers keep the gate storm-proof (the ratchet's first deep cut once fired 1469 times on a
green suite):

- **Gated dimensions** — `instances.*`, `statics.*`, `world.*`, `dom.*`, `swCanvasText.*`,
  `hashCode.*`, `sourceVault.*`, `classes.*` — each checked against
  `WorldInventory.pageLifetimeStores`, the declared-exemption table. A declaration names a
  store by regex and states its policy WITH its reason: `bounded` (free below a stated cap;
  a self-capping store like an LRU states no cap — the store is its own enforcement) or
  `monotonic-ok` (free-running by design). Everything undeclared must be STABLE.
- **Report-only dimensions** — the bulk aggregates (`objects.*`, `strings.*`, `canvases.*`,
  `containers.*`, `typedArrays.*`): every bounded-cache admission moves them, so they inform
  forensics but never gate.

## 4. How to read a failure

- ⚠ **Attribution:** a `WORLD_INVENTORY_*` line fires during a test's OPENING `resetWorld`, so
  the runner attributes it to the test being loaded — the LEAKER is the PREVIOUS test on that
  shard page (the same semantics as `WORLD_CONSTRUCTION_DRIFT`). Reproduce in isolation
  (`run-sequence-headless.js [predecessor, victim]`) before believing the attributed name.
- `WORLD_INVENTORY_ESCAPED`: some code removed a widget from the tree without destroying it
  (the classic shape: chrome rebuilt during a destroy cascade, or a spare/off-tree
  collaborator widget nothing tears down). Find the creation site, make the owner destroy
  it. Never "fix" by exempting — identity offences have no exemption row.
- `WORLD_INVENTORY_ZOMBIE ... at <path>`: the path names the retainer — clear that
  reference where the teardown contract says it should die (usually
  `WorldWdgt._teardownWorldStructureNoSettle`, the shipping core).
- `WORLD_INVENTORY_DRIFT statics.<C>.<f>` / `world.<f>`: a store grew across a teardown.
  Either the teardown forgot to reset it (fix it there), or it is genuinely page-lifetime —
  then declare it in `WorldInventory.pageLifetimeStores` with its reason and the tightest
  honest policy.
- `WORLD_INVENTORY_DRIFT dom.*`: something appends DOM per test (`dom.headScripts` is
  declared monotonic-ok — the test loader's per-test script tags are page-lifetime residue
  by current design).

## 5. Boundaries and relatives

- The world-field ratchet (`WORLD_CONSTRUCTION_DRIFT`) stands beside the inventory: it
  reads EFFECTIVE world-field values shallowly (own + prototype chain) and catches value
  flips the size-oriented inventory does not; the inventory catches everything outside the
  world's own fields. They overlap on world container sizes, harmlessly.
- The inventory's containment roots are `graphLivenessRoots()` — the ONE enumeration shared
  with the trash-liveness query/sever pair — PLUS the bin/shelf containers themselves:
  residency must not read as an inbound liveness edge, but the containers' chrome is
  accounted-for citizenry.
- Per-cycle and per-refresh transients are handled at the honest layer: the teardown core
  drops just-destroyed widgets from the per-cycle damage queues at the seam (a filter, not a
  clear — the world's own whole-screen damage mark must survive), while the SWCanvas
  cold-glyph window stores are counted but not walked and are declared per-refresh
  transients (their drain's consumer skips destroyed entries).
- Both engines run the same gate: the instrument is plain in-page JS, so the WebKit suite
  leg exercises it identically. The VM-truth tier below is Chrome-only by nature and ADDS
  closure-visibility rather than replacing any of this.

## 6. The VM-truth tier (Arc B): the closures the walk cannot see

The inventory walks PROPERTIES — it deliberately counts functions and never walks them, so
a widget pinned by a closure, listener, or promise reaction is invisible to it BY DESIGN.
The VM-truth tier asks V8 instead. Chrome-only by nature (forced GC, `queryObjects`, heap
snapshots are V8/CDP rails); the webkit leg keeps cross-engine coverage via the in-band
gate above. Program plan: `docs/archive/world-vm-truth-riders-plan.md` (its §5 carries the
measured numbers).

**The gate** — `Fizzygum-tests/scripts/vm-truth-gate.js` (the `fg vmtruth` gauntlet leg):
runs the full suite with `scripts/audit-preludes/vm-truth-prelude.js` injected and Chrome
launched with `--js-flags=--expose-gc --enable-precise-memory-info` (both flags are the
dose: without the second, `performance.memory` is quantized and the floor gate is blind).
The prelude records a `WeakRef` for every widget at `unregisterThisInstance` (the moment it
leaves the live registry and is supposed to be garbage) and, at each `resetWorld` — after
the teardown and the in-band audits — forces a double GC and asserts, with THREE verdicts:

- **RETENTION, in two tiers — because the cheap question and the true question are not the
  same question.** *Tier 1* (in the page, at every `resetWorld`) forces the double GC and
  collects every widget still alive at the FIRST sweep after the reset that destroyed it,
  emitting `LAYOUTAUDIT VMTRUTH suspect:<Class>#<id> destroyedDuring:<test>`. Those are
  **SUSPECTS, not findings**: "the collector has not got to it yet" and "something is
  holding it" are indistinguishable from inside the page, so tier 1 declares nothing and
  **pins** each suspect where a heap snapshot can still address it. *Tier 2* (in the
  runner, `AUDIT_RETAINER_CONFIRM=1`) takes one snapshot per shard at shard end and marks
  forward from the GC root **with the pin arrays subtracted by NODE** — never by edge name,
  because an array reaches its elements through a backing store whose edges are numeric
  slots, and dropping the array's own node is what drops the store with it. A suspect still
  marked is genuinely retained; the gate fails and **prints its retainer path**, where a
  `context:<var>` hop names the closure variable holding it.
  ⚠ **There is NO grace period and NO exemption table, and the absence of the grace is the
  design rather than an oversight.** A tolerance was there only to absorb tier 1's false
  positives; reachability has no noise to absorb — an object is retained or it is not,
  there are no ages and no buckets. Measured, three ways, before the tiers existed: the
  objects the old proxy reported had **no retaining heap edge at all** — unreachable
  garbage the forced GC had not reclaimed yet — which is precisely the false-positive class
  a grace period can only ever hide, never remove.
  ⚠ **The sweep runs OFF the world cycle** (a `setTimeout 0` macrotask), and that position
  is measured: run inline — inside `resetWorld`/`doOneCycle`/the rAF callback — V8's
  conservative stack scanning treats the live frames above it as roots and the forced GC
  cannot reclaim what they mention, leaving **20781** corpses alive one sweep later across a
  307-sweep run, against **40** from the deferred position.
  Attribution: a suspect is raised during the INCOMING test's opening reset, so the leaker
  is the PREVIOUS test on that shard page (same semantics as every reset-seam gate); the
  last test of a shard is never swept (same stated hole as the storage prelude).
- **Heap floor** — one post-GC `usedJSHeapSize` sample per teardown
  (`LAYOUTAUDIT VMHEAP`); per page, `min(last 10) − min(samples 3..15)` must stay ≤ 96 MB
  (green-suite worst: +44 MB — the heap legitimately balloons and deflates with test
  composition, so only the FLOOR is a leak signal; endpoint statistics are noise).
- **INVALID (exit 2)** — the run measured NOTHING and must never read as a pass: a test
  bucket with no heap sample (prelude not installed, or no `window.gc`), no reset ever
  observed to REPLACE the world, or — the tier-2 case — **a suspect tier 1 raised that
  tier 2 never answered**, whether because the confirmation broke on a shard or because it
  never ran at all. A suspect nobody asked the snapshot about is not a suspect that came
  back clean.

**The forensic tool** — `Fizzygum-tests/scripts/heap-forensics.js`
(`--test=<name>` / `--tests=A,B` / `--boot-only`, `--snapshot` for retainer paths): four
lenses over the world a test leaves behind — the in-band anatomy (escaped widgets with
parent chains), the WeakRef collectibility sweep, the `Runtime.queryObjects` registry
cross-check (VM-alive ∖ `Widget.instances` = retained corpses; the reverse would be a
registration hole), and heap-snapshot retainer paths whose `context:<var>` edges name the
exact closure variable holding a corpse. Two mechanism facts it encodes (measured): widget
instances are ANONYMOUS in heap snapshots (the meta-system's eval-built constructors leave
V8 no reliable inferred name — suspects are mapped by `HeapProfiler.getHeapObjectId`,
never by node name), and heap object ids are assigned lazily (the snapshot must be taken
FIRST or every id answers "0"). `--selftest` plants a closure-held destroyed widget and
requires itself to find it end-to-end while the in-band gate stays silent on it — run it
after touching the tool.

**The door-callback law this tier enforced into the code** (found by the Arc B probe): a
lazy-part door callback that acts ON A WIDGET must open with a destroyed-check — the wait
is exactly when the subject can die, and acting anyway silently mounts fresh chrome on a
corpse the destroy cascade can never reach (measured on `index.html`: `editLayout` +
destroy-mid-load left a permanent escaped widget pinning its corpse parent, with zero
errors). The guards live at each funnel-callback head (`Widget.editLayout`,
`spawnInspector`/`createConsole`, `ExamplesFolderWindowWdgt.whenReadyToBeBroughtUp`,
`WorldWdgt.popUpDemoTestMenu`); the runtime gate is the destroy-mid-load race in
`Fizzygum-tests/scripts/parts-lazy-load-headless.js` (the `parts` leg).

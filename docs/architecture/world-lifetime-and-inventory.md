# World lifetime and the inventory instrument

How Fizzygum accounts for what is alive on a page, and the doctrine that accounting serves.
Companion code: `src/dev-tools/WorldInventory.coffee` (the instrument),
`Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee`
(`_auditWorldInventoryNoSettle`, the gate seam), `WorldWdgt.graphLivenessRoots` (the shared
root enumeration). Program plan: `docs/archive/world-inventory-instruments-plan.md` (Arc A of
three; Arcs B and C are future arcs, described there).

## 1. The two-lifetimes doctrine (direction, not yet enforcement)

Every piece of state on a Fizzygum page belongs to exactly one of two lifetimes:

- **PAGE lifetime** — state that legitimately survives any world reset: the code itself
  (classes, the `SourceVault`), the font atlases and the metrics probed off them
  (`minimumFontHeight`), interned immutables (`Color._permanent`), memo caches that are pure
  functions of their keys (the `world.cacheFor*` LRUs, the `Object::hashCode` memo), and
  lifetime counters (`instancesCounter`).
- **WORLD lifetime** — everything else: widgets, their bookkeeping, collaborator state, app
  slots, DOM side effects. It dies with the world.

Today's `resetWorld` is a *cleanup pass over a reused world object*, so the doctrine is
enforced by AUDIT rather than by construction. Arc C of the program is the enforcement arc:
reset becomes *destroy + `new WorldWdgt`*, and the whole question collapses to "is the old
world collectible" (a `WeakRef` + forced GC check). Until then, the inventory below is the
conformance instrument: **everything alive after a teardown must be (a) part of the
post-boot baseline, (b) a declared page-lifetime store, or (c) a bug.**

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
the world-field ratchet (`RESETWORLD_INCOMPLETE`) and covering exactly that ratchet's blind
spots: class statics, collaborator internals, module state, the DOM, and identity. The first
teardown takes the baseline; every later one diffs against it and emits, per offence, one of
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
  shard page (the same semantics as `RESETWORLD_INCOMPLETE`). Reproduce in isolation
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

- The world-field ratchet (`RESETWORLD_INCOMPLETE`) stays as-is beside the inventory: it
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
  leg exercises it identically. VM-truth riders (forced GC, heap slope, `queryObjects`
  cross-checks) are Arc B, Chrome-only by nature, and ADD closure-visibility rather than
  replacing any of this.

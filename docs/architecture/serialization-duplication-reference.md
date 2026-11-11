# Serialization / Deserialization / Duplication — the reference

**This is the ONE home for all serialization, deserialization, and duplication
documentation.** The format spec, the traversal contract the two walkers share, the
per-class protocol, the per-type handlers, and the `file://` capability map all live
here. CLAUDE.md files only LINK here (per owner direction, 2026-07-04) — never copy this
content into a CLAUDE.md.

Companion: `docs/archive/serialization-deserialization-plan.md` is the phased execution plan
(current-state survey, spike-verified defect catalog, design rationale, exit gates,
owner-resolved decisions, landed-status). This reference is the *durable* description of
how the machinery works; the plan is the *build order*.

> **All of it ships.** The widget round-trip is wired end to end — `Widget.serialize` →
> `Serializer.serializeWidget` (the §3 envelope), `Widget.deserialize` / `world.deserialize`
> → `Deserializer.deserialize` — and duplication lives in the `Duplicator` engine
> (`src/duplication/`); restored widgets are byte-identical to the originals (same-page AND
> cross-session). So do file save/load over `file://` (§10 — `Widget.saveToFile` / `FileSaving`,
> the `WorldWdgt` drop handler / `FileLoading`, `*.fzw.json` routed on `kind`), the whole-world
> snapshot (§11 — `WorldWdgt.serializeWorldSnapshot` / `loadWorldSnapshot`,
> `Serializer.serializeWorld`, `WellKnownObjects.resolveApp`, `FileLoading`'s `kind:"world"`
> branch; pixel-identical desktop round-trip same-page + cross-session at dpr 1/2), and
> source-edit capture (§12 — `SourceEditsRegistry` at `world.sourceEditsRegistry`, recorded by
> the inspectors' gestures — `InspectorWdgt.applyPropertyEdit` and the class inspector's edit
> steps — embedded in and replayed from the world snapshot). The phase ledger that tracked its construction is history — it
> lives in the companion plan above, with the decisions it resolved.
>
> NB: every shipping `src/` directory must be claimed by exactly one **part** in
> `buildSystem/parts.json` (`src/serialization` and `src/duplication` both sit in `core`). A
> new subdirectory no part claims does not silently vanish — `buildSystem/check-shippable-coverage.js`
> FAILS the build.

---

## 1. Two walkers, one body of knowledge

Fizzygum has two object-graph walkers over the same graph shapes:

- **Duplication — the `Duplicator` engine (`src/duplication/Duplicator.coffee`),
  load-bearing.** `Widget.fullCopy` → `new Duplicator(allWidgetsInStructure)
  .duplicate @`. One engine instance per copy run carries the original→clone identity
  map; it clones a widget subtree into live sibling widgets, and the SystemTest suite
  bakes its exact pixels in. The walk lives in ONE home rather than being spread across
  per-native-prototype `::deepCopy` extensions.
- **Serialization — the `Serializer`/`Deserializer` pair (`src/serialization/`)**: a
  separate, side-effect-free record builder (it must not keep live pointers).

The design decision (plan §4.6) is to **split the walkers but share the knowledge**: the
duplication walker keeps its entangled clone-as-you-traverse behaviour (the SystemTests
depend on it); the serializer is a separate, side-effect-free record builder. What they
share — and what this doc is the single source of truth for — is the per-class *knowledge*:

- the **traversal contract** (own-properties, the cycle/shared-object table, the
  external-widget test against `allWidgetsInStructure`) — §2 below;
- `@serializationTransients` (fields to skip) and the well-known singletons (`WellKnownObjects`) —
  §5, §4;
- the `rebuildDerivedValue(s)` derived-value protocol — §5;
- the native-type handlers' logic (Array/Date/Canvas, and the element kinds neither walker carries) — §6 — and the
  native-type DETECTION itself, factored into the one shared
  `NativeValueKinds` (`src/serialization/NativeValueKinds.coffee`) both engines consult.

Keeping this in one doc is what stops the two walkers from drifting silently.

---

## 2. The traversal contract (shared)

`src/duplication/Duplicator.coffee` walks an object graph cycle-safely:

- Each non-primitive encountered gets one **table slot**; a re-encounter emits a back
  reference (duplication: the memoized clone; serialization: a reference token). This is
  what makes shared substructure and cycles round-trip uniformly — e.g. an array shared
  between two properties is copied once and referenced twice.
- **`own` enumerable properties only** are walked (`Duplicator._cloneContentInto`). Inherited
  prototype methods/fields are not copied — the shell is created with
  `Object.create(Class.prototype)` so they come from the prototype.
- A property whose value is **DERIVED where it stands** (`NativeValueKinds.isDerivedAt`, the one
  predicate both walkers ask: a value answering **`rebuildDerivedValue`**, where its holder rebuilds
  it — a canvas 2D context beside the canvas it is drawn from, any other in a field its holder's class
  declares in `@serializationTransients` — §5) is skipped by BOTH walkers. Only
  DUPLICATION regenerates it (`Duplicator._rebuildDerivedValues` asks the ORIGINAL's value to
  rebuild onto the clone). SERIALIZATION drops it and does not restore it — the field comes back
  `undefined`, so a derived value a restored widget still needs is rebuilt by that class (lazily,
  or in its `_afterDeserialization`). Canvas 2D contexts define `rebuildDerivedValue` on their
  prototype (they rebuild from their sibling canvas, `<name>Context` beside `<name>`) — and a
  rebuilt context is fresh and UNSCALED, so a primitive that draws through a context it holds
  lays the pixel ratio again itself (`CanvasWdgt.drawLine`); a class may also STAMP a no-op one
  onto a runtime-only object it keeps in a field it declares transient, to keep it out of both walks
  there (§5). Such a value anywhere else is a page object: a save refuses it, a copy keeps it by
  reference (`Duplicator._duplicate`).
- A property whose value is flagged **`keptByReferenceOnDeepCopy`** is kept by reference
  on duplication. Two kinds of class declare it: world-level shared singletons
  (`Wallpaper`, `WidgetFactory`, `WindowedApp`, `DataflowEngine`,
  `PreferencesAndSettings`) —
  which the serializer *independently* encodes as well-known `{"$wk"}` refs (§4, matched
  by identity, not by this flag) — and immutable value classes (`Point`, `Rectangle`,
  `ShadowInfo`, `TransformSpec`, `SheetError`), which serialize as ordinary values
  (sharing round-trips via the identity-keyed object table). See
  `docs/architecture/immutable-value-classes.md` §4.
- A class's own **prototype** belongs to the PAGE, not to the copy or the file: both walkers
  recognise one (boot's `isAClassPrototype`, built on `classNamed`) before any other reading of
  it. Duplication shares it; serialization names it by its class (§4a). Asked first because a
  Widget-branch prototype is `instanceof Widget`, so the external-widget rule below would read it
  as a widget, and a non-widget one would be copied into an object posing as its class's prototype.
  (A class FUNCTION rides a copy uncopied, as every function does but a widget's injected method,
  which the copy compiles afresh — §5's Functions — and a save names it by its class too.) A class inspector's subject is one, whichever door opened it (a `__super__` row, Inspect
  selection, a breadcrumb chip).
- A `Widget` NOT in the **in-structure set** is **external**: duplication keeps the live
  reference (so a duplicate can stay wired to an outside widget); serialization cannot
  keep a live pointer, so this is where the well-known / error policy applies (§4). That is
  why an owner keeps no widget OFF its tree: such a widget is external to both walkers, so a
  copy would SHARE it with the original (and destroy it with whichever dies first) while a
  save refuses it. A frame's empty-state placeholder exists only while it is mounted
  (`FrameWdgt.defaultContents`; `widget-authoring-guidelines.md`).
- **A root's `parent` is the one external widget neither walker keeps.** Serialization writes
  `null` for a detach-root's parent (§4, rule 3) and duplication sets the clone's `parent` to
  `undefined` (`Duplicator._cloneContentInto`), so a copy comes back DETACHED, an orphan until
  its caller places it. Kept, it would point at a parent that does not hold it: the copy would
  answer `isOrphan()` false and `root()` the world, so resizing or destroying it would push layout
  into the original's tree, and code reading where it came from would read the original's place.
  A caller that carries a fresh copy away states where the pick-up starts instead
  (`ActivePointerWdgt.grab`'s `origin`: a template's copy starts where the template stands).
  Every `parent` the Duplicator writes is a structural link made outside `TreeNode._addChild`, so
  it is announced as `_addChild` announces one (`WorldWdgt.noteStructureChange`): a tree derivation
  cached while the walk links its widgets (`root()`, which caches on every ancestor it climbs) would
  otherwise be read again, stale, once the copy is whole (the settle leg's
  `CACHED_DERIVATION_DIVERGED` rider catches exactly that). The per-widget hooks
  (`alignCopiedWidgetTo*`, `_reactToBeingCopied`) run once the WHOLE copy is built — every widget
  linked, before the caller places the copy — in the order the walk finished the objects (a child
  before its parent), and each shell joins its classes' instance sets only then too (the
  Duplicator's Note 3), so a copy refused part-way leaves no half-built widget registered or
  aligned anywhere.
- **The in-structure set is the ARROW-CONTRACT closure, one computation for both walkers**
  (`Widget.allWidgetsInStructureForCopy`, reference-widgets plan §4.4): the root's subtree
  PLUS, through every in-structure icon that presents as content
  (`ShortcutWdgt.representsContents`), the referent's whole figure, recursively
  (visited-set fixpoint — folder-in-folder filings make cycles constructible). An ARROW'D
  shortcut's referent stays external — a copy shares it, and a save of it errors (no
  cross-file identity; BACKLOG). The contributed referent figures are placed by policy:
  `fullCopy` files each fresh copy to the SHELF
  (`Widget._fileCopiedReferentFiguresToShelfNoSettle`, via `Duplicator.cloneOf`);
  serialization encodes each as a **detached embedded second root** (parent `null`, like
  the envelope root — `_buildObjectTable`'s `detachRoots`) and the restore homes it to the
  shelf in `ShortcutWdgt._afterDeserialization` (attached-in-truth guarded, so a
  world-snapshot restore — where the shelf is itself a serialized root — is a no-op).
- `instanceNumericID` is never copied (clones get fresh identity — §7).

The constructor is **never re-run** on a clone/restored shell (`Object.create` of the
prototype). Classes needing post-construction fixup use hooks (`_reactToBeingCopied` on
duplication; `_afterDeserialization` on restore).

---

## 3. Envelope format

The serializer replaces the old JSON-lines-with-comments format with a single versioned
JSON document. One table entry per non-primitive (so sharing/cycles keep working):

```jsonc
{
  "format": "fizzygum",
  "formatVersion": 1,
  "kind": "widget",                  // or "world" (the whole-world snapshot, §11)
  "savedAt": "…",                    // informational
  "build": "…",                      // build stamp, informational
  "root": 0,                         // index into objects
  "objects": [
    { "class": "FrameWdgt", "iid": 1, "memberships": [],
      "props": { "labelContent": "my window", "parent": null,
                 "children": {"$r": 3}, "color": {"$r": 7} } },
    { "class": "$Array",  "items": [ {"$r": 4}, {"$r": 5} ] },
    { "class": "Color",   "rgba": [248, 248, 248, 1] },
    { "class": "$Date",   "ms": 1783122262571 },
    { "class": "$Canvas", "w": 300, "h": 200, "pr": 1, "data": "data:image/png;base64,…" },
    { "class": "$Object", "props": { … } },
    { "class": "$Map",    "entries": [ [k, v], … ] },
    { "class": "$Set",    "items": [ … ] }
  ],
  "world": { … }                     // kind:"world" only (§11)
}
```

- **References are structured values, never in-band strings** — this is what fixes the old
  format's silent corruption of any user string starting with `$`. The reference
  forms (§4) are `{"$r":n}`, `{"$wk":key}` — a well-known object, or a class or a class's
  prototype named by its class (§4a) — `{"$src":coffee}` — a widget's injected method, only
  ever a property of that widget's record — `{"$num":text}` — a number JSON cannot write as itself (below) —
  (plus `{"$ext":id}`, the token
  the tolerant `onExternalPointer:"record"` mode emits — resolvable by unique-id on restore,
  but no shipped caller selects that mode). A plain JSON object as a *value* is always a table
  slot (`$Object`), so a `props` value is unambiguously one of the reference forms by
  construction; plain user strings need no escaping. A load refuses up front any other object where a
  reference goes (§11), so no form a build does not know is ever read as undefined in silence.
- **A number is written as itself unless JSON cannot write it as itself**: `JSON.stringify` writes NaN and ±Infinity
  as `null` and -0 as `0`, so those four ride as `{"$num": "NaN" | "Infinity" | "-Infinity" | "-0"}` — wherever a
  record holds a number that can be any number: a reference, a `$Date`'s `ms` (an invalid date's is NaN), a `Color`'s
  `rgba` (the integers the format keeps — an `iid`, a `$Canvas`'s size and ratio — are integers by construction).
  `Serializer.NUMBERS_JSON_CANNOT_WRITE` is the one list; `Serializer.numberRef` writes by it and
  `Deserializer.numberFrom` reads by it. A load refuses up front (`_envelopeShapeProblem`) a `{"$num"}` naming any
  other text, and a `$Date` time or `Color` component that is no number (a `Color` keeps four); a save never
  writes one: a colour's components are normalized in one place (`Color._channel` and `Color._alpha`, which the
  constructor and `create` before it keys both read), a colour written into after it was made is refused by the save
  (`Serializer._colorComponentsProblem`), and a `$Date`'s time is read through `Date`'s own `getTime`, so it never
  writes what the load refuses. `Color.create` keeps no -0 (its
  cache key reads -0 and 0 as one colour), so a save's bytes do not depend on which spelling minted a colour first.
- **Native types carry `$`-prefixed class tags** (`$Array`/`$Date`/`$Canvas`/`$Object`/
  `$Map`/`$Set`). User class names are CoffeeScript identifiers and can
  never collide with a `$`-prefixed tag.
- `Color` keeps a compact `rgba` form, restored through the `Color.create` factory so
  immutable-color dedupe is preserved.
- `iid` records the original `instanceNumericID` (informational for `kind:"widget"`;
  restored for `kind:"world"`). `memberships` records world-set membership at save time
  (§5), as markers from ONE table both directions read, `Serializer.WORLD_SET_MEMBERSHIPS`
  (marker → world Set field, each with its verdict on what the re-registered machinery reads); a
  marker outside it makes the envelope malformed, refused up front (`_envelopeShapeProblem`) —
  so before a world load's teardown — rather than dropped by the restore.
- Output is **deterministic** given identical world state (the serializer touches no ID
  counters — §7). A `prettyPrint` option indents for humans/diffs.

---

## 4. Reference policy

At serialize time each encountered object is classified, in order:

0. **A class, or a class's own prototype** → `{"$wk": "class:<Name>"}` /
   `{"$wk": "prototype:<Name>"}` (§4a), asked before every reading below — a class function would
   otherwise meet the function policy (§5) and a Widget-branch prototype the widget rules.
1. **In-structure** (a widget in the arrow-contract closure — §2, or any non-widget
   reached by the walk) → table slot, `{"$r": n}`.
2. **Well-known** → `{"$wk": key}`, via `WellKnownObjects` (§4a).
3. **A detach-root's `parent`** → `null` — the envelope root plus any embedded referent
   figures the closure contributed (duplication's twin: a copy's roots come back detached, §2).
   Deserialization returns the root *detached* (the
   caller — menu action / drop handler / snapshot loader — decides where to attach it);
   an embedded referent figure restores detached too and is homed to the shelf by
   `ShortcutWdgt._afterDeserialization` (§2). One shape is refused up front: an icon saved
   from INSIDE the container it presents (`buildEnvelope`'s ancestor guard) — the file
   would have to embed its own root's ancestor as a detached sibling.
4. **Anything else** → **`SerializationError`** (§8) carrying the root, the full property
   path to the offending reference, a description of the offender, and remediation hints.
   An options bag `onExternalPointer: "throw" (widget default) | "capture" (world default) |
   "nullify" | "record"` supports tolerant callers. `"capture"` pulls the off-tree widget into
   the table as its own record — this is what the world snapshot uses (§11), and why a settled
   snapshot contains no `{"$ext"}` at all. `"record"` emits `{"$ext": id}` for same-world
   re-linking (resolved by unique-id on restore) and `"nullify"` writes `null`; neither has a
   shipped caller today.

Function-valued own properties are handled by the function policy (§5), not this
classification — except a CLASS, which step 0 names by its class before the function policy is
asked. Transient fields (§5) never reach classification at all.

### 4a. WellKnownObjects

`src/serialization/WellKnownObjects.coffee` is a two-way symbolic registry for the
singletons present in every world: `world`, `hand`, `wallpaper`, `widgetFactory`,
`dataflow` (the `DataflowEngine` — a shipped product collaborator; its edge index is
derived/disposable and never serialized), `bin`, `shelf`, `preferences`, and
`app:<ClassName>` per windowed-app singleton.

- `WellKnownObjects.keyFor(obj)` → symbolic key or `undefined`.
- `WellKnownObjects.resolve(key)` → the live object in the **current** world, or `undefined`
  when that singleton is absent (a world with no wallpaper yet). A key that names a CLASS — an
  `app:` key, a class key (below) — naming a class this page lacks THROWS, in the words
  `Deserializer.instantiate` uses for a record of such a class (`SerializationError.forMissingClass`),
  and both file doors refuse such a file before anything is built (§9). So does a key no build
  writes — `Deserializer._envelopeShapeProblem` refuses a file carrying one up front
  (`WellKnownObjects.isKnownKey` over `Deserializer.wellKnownKeysIn`, which reads a key only where the format puts a
  reference — a record's references, never a props container, whose own keys are property names; an `app:` or class key with no
  name after its prefix is one).

**It is lazy, not snapshotted.** Keys resolve against the live `world` on demand rather
than from a boot-time map. This is boot-order-safe (bin/apps are built after the
world) and — crucially — correct for cross-session restore: a key binds to the *new*
session's singletons, not to a stale map. The per-world singletons are matched by identity
against the live world, through ONE table (`WellKnownObjects._liveSingletons`: `world`, `hand`,
`wallpaper`, `widgetFactory`, `dataflow`, `bin`, `shelf`, `preferences`) that `keyFor` matches by
identity and `resolve` looks keys up in, so those classes declare no marker. The class marker
`wellKnownKey` remains only for the family the table cannot list because its key carries a name:
`WindowedApp`'s `"app:" + @constructor.name`. A marker the table does not know is refused at save,
and a key no build writes is refused at load (an envelope shape problem, before a world load's
teardown).
`WellKnownObjects.resolveApp(className)` completes the `app:` branch: it resolves the name through
boot's `classNamed` (a key is a name read out of a file, so one naming a native global or an inherited
property of `window` is no class, and throws like any class this page lacks — never `new`-ed), refuses a
class that is not an app (`WellKnownObjects.isAppClass`: a class whose instances a save writes as that very key,
through their `wellKnownKey` — a load accepts exactly what a save writes, and core names no app-kit class;
the file doors refuse such a key up front, `Deserializer.whyItCanNeverBeRestored`, so `app:WorldWdgt` never
runs a constructor that makes itself `window.world`; a launcher's lazy click asks the same of the app name
it carries, `AppLauncherWdgt`), `new`s the named app — a `WindowedApp` subclass, or the stateless base itself —
and MEMOIZES one instance per class
(`@_appSingletons`), which is safe because such an app is a stateless config holder — its one
window lives in the world's app-window registry (`world.appWindows`, keyed by class name), not on the app (§11).

**The class keys.** A class, and its own prototype, belong to the PAGE rather than to the
world: every page holding the class has them. A widget pointing at one (a class inspector's
subject is a class's prototype, which a `__super__` row and Inspect selection open in it too; an
object inspector can be opened on a class function) writes `"class:<Name>"` / `"prototype:<Name>"`, and the load
binds the key through `classNamed` to the LOADING page's class, with the file's class-scope edits
replayed onto it first (§12). A record of the prototype's members
would restore as a fake instance, and its methods have no source a file can carry.
- `WellKnownObjects.classKeyFor` answers the two keys, and `keyFor` asks it FIRST, before the
  singleton table and the `wellKnownKey` marker: a marker that is a METHOD is read through the
  prototype chain, so a `WindowedApp` subclass's prototype would otherwise answer its `app:` key
  and load as the app's singleton.
- A KEY THAT NAMES A CLASS MUST RESOLVE. A class key or an `app:` key naming a class the loading
  page cannot provide is REFUSED, never left undefined: the widget holding it would have nothing to
  show, edit or launch (an eager launcher whose app is undefined throws on its first click).
  `WellKnownObjects.resolve` throws in `Deserializer.instantiate`'s words, and
  `Deserializer.whyItCanNeverBeRestored` refuses such a file at either door before anything is
  built, reading its names from `Deserializer.classNamesIn` — the ONE list of the classes a file needs,
  record classes and both kinds of key, which the lazy-part pre-load reads too (§9), so a class a
  lazy part provides is loaded before the restore rather than refused.
- A BUILT-IN class's prototype (a number's `Number`) is not a Fizzygum class, has no key, and is
  refused like any other unrecognized value. So an inspector's breadcrumb chips hold class NAMES,
  never the links.

The link is symbolic and reconstructable — it preserves identity, which a bare opaque
`"$EXTERNAL"` marker cannot.

---

## 5. How a class declares what NOT to serialize

The routine way to keep a field out of a saved file is a class-body declaration, additive and
inherited (merged up the chain like the codebase's other class-body conventions):

```coffee
class Widget extends TreeNode
  @serializationTransients: ["lastTime", "backBuffer", …]  # skipped at serialize
```

DERIVED STATE needs no declaration: the serializer also skips every field `Widget.isDerivedStateField`
names — the version-keyed cache pairs (`cached<X>` + `check<X>Cache`), `childrenBoundsUpdatedAt` and the
island source-lane stash `_islandBufferSource*` — the ONE rule the Duplicator (never copies one) and
`WorldInventory` (never counts retention through one) read too, so a new cache is covered by being
NAMED like one.

- **The reader** is `Serializer.transientsForClass(klass)` — a Set over boot's
  `classStaticListMergedUpTheChain klass, "serializationTransients"` (`src/boot/globalFunctions.coffee`),
  THE one merge of a class-level list declaration up the class chain. **A
  subclass declares its OWN fields and nothing else**: the merge is the rule, so re-stating an
  ancestor's entry is duplication, and a subclass can never drop one.
  ⚠ **The chain to walk is `__super__`, not `Object.getPrototypeOf`** (boot's `superclassOf`). This
  tree does not use ES class inheritance: `extend` (`src/boot/globalFunctions.coffee`) COPIES the
  parent's statics onto the child and links them only through `child.__super__ = parent.prototype`.
  That copy-down is why a subclass declaring NOTHING inherits the list correctly, and why a
  subclass's OWN list would REPLACE everything above it under a prototype-chain walk (the chain shows
  no parent there, so such a walk returns the one declaration it can see), and why the merge reads
  each class by `hasOwnProperty` and walks on past it. Silent by construction: it fires only on the
  classes that declare, and only on fields those instances happen to own. The rig check that holds
  the merge is `transients.inheritedMergedNotReplaced` in
  `../Fizzygum-tests/scripts/serialization-roundtrip-headless.js` — it serializes a self-declaring
  class and asserts an INHERITED transient is absent from the record.
- **A raster that is CONTENT, not a render cache, rides the save under a name of its own.** The
  back buffer is a `Widget` transient — on almost every widget it is a cache the next paint
  re-derives — and a subclass can never drop an inherited transient. A plain `CanvasWdgt`'s raster
  stops being a cache the moment something draws on it (`drawLine`, `clear`): from then on it is the
  only copy of the drawing. So `CanvasWdgt` also holds that same canvas object as `drawnRaster` (not
  transient: one `$Canvas` record, the object table being identity-keyed), set only by those two
  draws, so a canvas nothing has drawn on — and every subclass whose raster IS a cache — costs a file
  nothing; a restored canvas takes it back as its back buffer at its first paint. FizzyPaint's
  `StretchableCanvasWdgt` keeps its painting in a separate content field
  (`behindTheScenesBackBuffer`) and rebuilds that painting's context in `_afterDeserialization`. The
  record states the pixel ratio its physical pixels were made at, and the restore resamples a record
  made at another ratio to the loading page's (§6), so a drawing — and a FizzyPaint painting, whose
  paint tools lay the page's ratio on it — comes back at its own logical size and takes the next
  stroke where a fresh one would. Rig checks: `canvas.drawnRasterRoundtrip`,
  `world.drawnCanvasSurvives`, `canvas.duplicateDrawsAtPixelRatio`, `stretchable.paintableAfterRestore`,
  `canvas.crossRatio.2to1`/`.1to2` (through the file door), `stretchable.crossRatio.2to1`/`.1to2`,
  `canvas.crossRatio.2to1to2KeepsPlace`, `pinnedMenu.crossRatioIcons.2to1`/`.1to2` (three SWCanvas
  pages pinned to ratios 2, 1, 2 whatever the run's `--dpr`) (`serialization-roundtrip-headless.js`)
  and `file.drawnCanvasPixels` (`serialization-file-roundtrip-headless.js`).
- **A widget keeps no memo of its back buffer.** The back buffer is a `Widget` transient, so a field
  recording what was painted INTO it — the size an image was last painted at, a background already laid —
  rides a save that the raster it describes does not, and the restored widget meets a fresh, unpainted raster
  beside a memo claiming the paint is done, and skips it. Ask the raster instead:
  `CanvasWdgt._createRefreshOrGetBackBuffer` hands over a NEW raster exactly when there was none (built,
  restored) or the size changed, so a widget whose raster is a cache paints on a new one (`SimpleImageWdgt`
  compares its back buffer before and after `super`) — or paints unconditionally where that is cheap
  (`VideoPlayerCanvasWdgt` lays its black letterbox under every frame). The gate is
  `buildSystem/check-back-buffer-memos.js` (`lint-and-static-checks.md` §3): every field a back-buffer
  builder writes is a transient of the class chain or is declared `# saved-content:` (today only
  `CanvasWdgt.drawnRaster`); it reads every part, the flag-gated `video-player` included, and is blind to a
  memo written outside the builder's reach (an onload closure).
- **An element the page loads is a page fact, derived from its holder's own path.** An image or a video
  is what THIS page fetched from a path; a record of it could only say where the saving page found it (an
  absolute `file://` path, a `blob:` URL that dies with its session), which is nowhere the loading page
  need be. So no file carries one and no copy shares one: the holder keeps the path in a field (the truth:
  `SimpleImageWdgt.imagePath`, `VideoPlayerCanvasWdgt.videoPath`), declares the element (and any flag about
  its load, `imageLoaded`) in `@serializationTransients`, and re-makes the element from the path — with its
  load handlers — after a restore (`_afterDeserialization`) and after a copy (`_reactToBeingCopied`). The
  Serializer has no element encoder and REFUSES an element in a field that is not a declared transient,
  with a remediation stating this rule; the Duplicator leaves such a field `undefined` for the holder's
  hook (§6). A restore that re-makes an element completes when it has arrived: a hook that starts a load
  answers its promise and `whenReady` awaits it (§9) — a hook reporting no load must not end on an
  expression that yields a thenable (CoffeeScript returns the last one). A video made again plays from its
  beginning. The gate is `buildSystem/check-page-loaded-elements.js` (`lint-and-static-checks.md` §3):
  every field a class assigns an element (`new Image`/`new Audio`/`document.createElement` of an img,
  video or audio) is a transient of the class chain, and the chain defines both hooks; an element made
  into no field says why with `# page-element-not-held: <reason>` (today only the Deserializer's
  `$Canvas` decoder image). It reads every part, the flag-gated `video-player` included.
- **A live canvas object a class caches in a field is a transient.** A gradient, a pattern or a
  canvas a paint builds lazily (`if !@colorGradient?`) has no file encoder; declare the field and let
  the paint rebuild it after a restore. The rig's `world.everyAppSnapshot.*` checks open every app
  the desktop offers, paint it, and save the world, refusing a save that throws or that carries a
  record of a browser-native class — which is what an undeclared cache produces on the two backends.
  ⚠ They see only what an app's FIRST paint reaches: a tool below a toolbar's fold builds no render
  state to trip on.
- **Derived values** keep the `rebuildDerivedValue` protocol (canvas 2D contexts, and the
  runtime objects a class stamps with a no-op rebuild): both walkers SKIP a value DERIVED where
  it stands, and only duplication rebuilds it on the copy; after a restore its holder rebuilds
  it, lazily, as a fresh widget builds it (or in its class's `_afterDeserialization`). Whether a
  value is derived is asked of its PLACE, in one predicate both walkers share
  (`NativeValueKinds.isDerivedAt`): where its holder rebuilds it — a canvas context beside the
  canvas it is drawn from, held as `<name>Context` next to that canvas `<name>` on the same holder
  (where its rebuild reads the canvas from — the SWCanvas context holds no `.canvas` to ask); a
  stamped runtime object in a field its holder's class declares in `@serializationTransients` (a 3D
  pane's runtime, `FridgeMagnets3DCanvasWdgt._keepTransient`, which names the field it fills and
  reports one where the value is not derived — `TRANSIENT_FIELD_UNDECLARED`, a gate token: kept there,
  the object would be shared by every copy). Anywhere else such a value is a page
  object like any other: a save refuses it (`SerializationError`, one remedy for every kind), a copy
  keeps it by reference — an inspector on one (a world inspector's `worldCanvasContext` row, a 3D
  pane's `transforms` row double-clicked) duplicates inspecting the same value and refuses a save
  until it is closed. The rig's `inspector.onACanvasContext*`, `inspector.onAPaneRuntimeValue*` and
  `paneRuntime.derivedInThePanesOwnFields` hold it.
  - ⚠ **The two mechanisms do NOT cover each other** (2026-07-08 SW3D-port incident, ~1 h):
    `@serializationTransients` SKIPS a field for the FILE Serializer only. The in-memory
    **Duplicator** never skips a field for being declared there — it reads the declaration only
    through `NativeValueKinds.isDerivedAt`, to place a stamped value (below) — and its coverage
    comes from seven mechanisms of its own:
    a NAME-convention skip in `_cloneContentInto` (the version-keyed cache pairs
    `cached*`/`check*Cache` plus `childrenBoundsUpdatedAt`, and the island source-lane
    `_islandBufferSource*` pair), the `rebuildDerivedValue` skip-and-rebuild of a value derived
    where it stands (`NativeValueKinds.isDerivedAt`), `keptByReferenceOnDeepCopy`, a value
    answering `rebuildDerivedValue` standing anywhere but where its holder rebuilds it kept by
    reference (`_duplicate`), the
    `alignCopiedWidgetTo*` world-set aligners, a widget's injected method compiled afresh on the copy
    (`_compileInjectedMethods`), and the per-class `_reactToBeingCopied` hook. A property covered by none of these gets
    deep-copied — and a runtime-only object there is REFUSED by the Duplicator's closed set, as the
    save's refuses it: the walkers' one refusal (`SerializationError`, direction "copy": "Cannot copy: a
    value of an unrecognized type (…) cannot be copied", with `SerializationError.UNRECOGNIZED_TYPE_REMEDY`,
    the remedy both walkers give, which a class author meets by making the value one its holder
    rebuilds — the Fix below), which `Widget.fullCopy` tells the person; the copy is built WHOLE before
    any of it reaches the world (the Duplicator's Note 3), so a refusal leaves no half-built widget
    registered or aligned (its shells did take fresh IDs). ⚠ A BUFFER there is not refused:
    it is data, copied silently (`_copyBuffer`), so a view onto a runtime object's buffer kept in an
    undeclared field leaves the copy holding a private copy of the original's bytes, which the copy's
    own rebuilt runtime never sees. **Fix: stamp a
    no-op `rebuildDerivedValue` on the runtime-only object itself AND list its field in
    `@serializationTransients`**: the stamp marks a value its holder rebuilds, the declaration
    names the field where it does, and the two together make it derived THERE (skipped by the
    copy and the save); the stamp alone makes it a page object everywhere (kept by reference by
    a copy, refused by a save), the declaration alone covers only the save.
  - **Declaring a new transient therefore means deciding BOTH sides.** For the serializer:
    list it. For the Duplicator: pick the coverage — skip / rebuild / align / share / or
    field-copy WITH a stated reason it is safe on a clone; every current family carries
    that verdict as a comment at its declaration. Two rules of thumb from walking all of
    them: a per-frame field consumed by the flush must be either provably flush-cleared
    (`hasDirtyDescendant`, the damage-rect indices) or Duplicator-dropped (the island
    source-lane stash); and a field a constructor seeds must be COPIED or re-seeded
    lazily, because clones and restored shells never run the constructor (`lastTime`: the
    serializer drops it and the "stepping" membership marker still re-registers the
    restored widget, so the stepping loop re-seeds it on first sight — without that, a
    snapshot-restored throttled stepper never stepped again).
- **Functions**: for an own function-valued property `foo` —
  - if `foo` holds a CLASS → `{"$wk": "class:<Name>"}`, named by its class (§4 step 0, §4a), asked
    before everything below;
  - else if the owner's class takes injected methods (a widget's, `Serializer.classTakesInjectedMethods`)
    and the function has a kept source (a user-injected method: `injectProperty` keeps the
    CoffeeScript WITH the function it compiles — a weak store keyed by the function, read
    through `Widget.keptSourceOf` — and only for a function it MAKES, a txt that IS one function
    literal (`Widget.spellsAFunctionLiteral`, read off the lexer's tokens); a txt naming one, `@f`,
    keeps nothing, so the function it names keeps the source it has, or none; and a txt with a
    statement after its function is stored by no door — an object's, a code blurb's, a class's or a
    mixin's member edit refuses it like a compile error, `Widget.refuseCodeAfterAFunction` — since
    every load and copy compiling it back would run that statement again) → serialize
    `{"$src": <source>}`; restore recompiles it with `injectProperty` on the owning widget. A COPY
    does the same, asking the same test (`Duplicator._compileInjectedMethods`): each injected method
    a widget's own field holds — a `@serializationTransients` one too, which the save drops and a copy
    keeps — is compiled afresh on the copy, so a fat arrow (`=> @x`), bound to the widget that
    compiled it, binds the copy instead of running on the original. The member is named by key in
    the program that injects it (`Widget.propertyAssignmentSource`), so a renamed member whose name
    is no identifier (`my method`) compiles too.
    The source is the FUNCTION's, never a field beside it, so it describes the function the
    field holds now: a function a run assigned (`@foo = -> …`) keeps none and is refused below,
    and a class keeps its members' sources on its meta-object (§12). That
    is the one place a save writes a `{"$src"}`, so a file holding one anywhere else is refused
    up front (§9).
  - else if `foo` is in the class's transients → dropped; the class recomputes it (e.g.
    patch nodes recompute `functionFromCompiledCode` from their text; a viewport's gesture scroll
    step, `_scrollStep`, simply stops, which is correct for a settled restore — its class `step` runs
    it, so a drag-scroll never leaves a `step` of the viewport's own, and one saved mid-gesture leaves
    the stepping set its `stepping` membership restored it into, in its `_afterDeserialization`).
  - else → `SerializationError` with the property path (never a silent drop). No text restores such a
    function faithfully — a closure over a run's locals, a native, a class member's body — so this is
    where a function a person's RUN left in state (`@f = -> 42`, `Widget.evaluateString`) ends: the
    refusal names the widget holding it, and its remedy names the person's gestures first — for a
    function held directly in a widget's field, an object inspector's Remove, or its Save as
    CoffeeScript, which keeps the source and rides as `{"$src"}`; for one held deeper (in an array,
    a Map, a Set or a plain object), the Remove of the field that follows the last widget its path
    names — then the class's (`@serializationTransients`, for a field its own code sets). A
    function in a slot has no property name, and is "a function" at its path. The rig's
    `world.saveRefusal.*` hold the three.

**The declarations whose REASON is not obvious from the field name:**

| Class | Transients | Why |
|---|---|---|
| `Widget` (caches) | `lastTime`; the render caches `backBuffer`/`backBufferContext` and their shadow-silhouette twins; the flush-scoped `hasDirtyDescendant`; the damage-rect bookkeeping. NOT listed, because skipped by NAME (`Widget.isDerivedStateField`): every geometry/identity cache pair (`cachedFullBounds`, `cachedRoot`, … each with its `check…Cache` twin), `childrenBoundsUpdatedAt`, the island-buffer source lane `_islandBufferSource*` | frame timing + derived caches, all re-derived on demand after restore. ⚠ An identity cache is the one whose absence bites: `root()` itself never reads `cachedRoot` stale (it checks `structureVersion`) but a walker reads the raw field, so a stale pointer drags destroyed subtrees — and their unserializable handler functions — into capture-mode world snapshots |
| `Widget` (damage bookkeeping) | `paintBoundsMaybeChanged`, `fullPaintBoundsMaybeChanged`, `clippedBoundsWhenLastPainted`, `fullClippedBoundsWhenLastPainted`, `srcDamageRectIndex`, `dstDamageRectIndex` | per-frame damage-rect bookkeeping, each field paired with never-serialized world-level flush state (the `widgetsWithMaybeChanged(Full)PaintBounds` work-lists / the flesh-out). A restored `true` dedupe flag has no matching work-list entry, so `_changed()`/`_fullChanged()` would be permanently suppressed on the restored widget — the 2026-07-22 bug: a snapshot saved from a menu click baked the triggering click's `bringToForeground` → `_fullChanged()` mark into the menu's record, and the restored menu left repaint artifacts when moved |
| `FrameWdgt` | `isPopUpMarkedForClosure` | pairs with the `world.popUpsMarkedForClosure` set; the triggering menu-item click marks its menu for closure before the action runs. It sat on `Widget` while the merge was broken (the base was the only place a declaration was safe); with the merge fixed it is declared by the class that owns and reads it |
| `SimpleImageWdgt` | `img`, `imageLoaded` | the loaded `Image` and whether it has arrived are facts about THIS page: `_afterDeserialization` and `_reactToBeingCopied` reload `imagePath`, the one saved part of the picture (a carried `true` would draw an undecoded image: a throw under SWCanvas, nothing natively — and a copy whose load the original started never repaints) |
| `VideoPlayerCanvasWdgt` | `video` | the `<video>` element is a page fact made from `videoPath`; `_afterDeserialization` and `_reactToBeingCopied` make their own, which plays from its beginning |
| `DesktopAppearance` | `pattern`, `currentPattern` | `pattern` is a `CanvasPattern` (the first thing a whole-world serialize crashed on); both re-derive from `world.wallpaper.patternName` |
| `CalculatingPatchNodeWdgt` | `functionFromCompiledCode` | the user formula COMPILED; `recalculateOutput` re-derives it from the (serialized) formula text on every recompute. Was long documented here as the canonical example yet never actually declared — every snapshot containing a patch-programming window crashed until 2026-07-23 |
| `ScriptWdgt` | `functionFromCompiledCode` | the saved script COMPILED (`@savedScript` is the truth); `doAll` recompiles it on demand after a restore |
| the gradient icon appearances (`ColorPalettePatchProgrammingIconAppearance`, `GrayscalePalettePatchProgrammingIconAppearance`, `VaporwaveBackgroundIconAppearance`, `VaporwaveSunIconAppearance`) | their cached gradient | a canvas gradient their paint builds lazily and rebuilds when absent; undeclared, a world snapshot saved with Patch Programming open throws "a value of an unrecognized type (LinearGradient)" under SWCanvas, and the closed-set guard refuses the `CanvasGradient` under native |

The declarations are the inventory — `grep -rn "@serializationTransients" src/` lists every
class that carries one, and the table above keeps only the rows a reader could not
have guessed. `WorldWdgt` deliberately has none: its transient surface is never visited,
because the world is not a table record (§11).

**`FrameWdgt.lifetime`** rides a snapshot as an ordinary serialized field — it carries no
transient declaration of its own. A `'persistent'` frame (window furniture, or a pinned
pop-up) is just another prop; a `'transient'` frame (an open menu/prompt) never reaches the
object table at all, because it never reaches a snapshot's ROOTS in the first place —
`Serializer.serializeWorld`'s children filter drops it via `isTransientPopUp?()`, the
serializer's own query onto the `lifetime` state (§11). Its `world.openPopUps` membership
does not ride the field either: membership is captured as an `"openPopUp"` marker in
`memberships` (§3) and restored by the deserializer's world-set-membership pass. `fullCopy`
writes `lifetime = 'persistent'` directly rather than going through the `setLifetime` entry
point — a copy is born furniture (nobody is mid-gesture with a duplicate), and the direct
write means the clone never spends a moment wearing its original's transient skin before the
copy call re-derives the persistent one — and re-takes the width that lifetime calls for (a pinned
pop-up takes its rows' width; a pop-up's title counts only while it is a pop-up). The rig pins it:
`pinnedMenu.longTitleWidthIsItsOwn`, `pinnedPrompt.longTitleWidthIsItsOwn` and
`pinnedMenu.sameRatioMatchesFresh` (and `.longTitle`) in `serialization-roundtrip-headless.js`.

**Instance-assigned handler functions are BANNED as a state idiom** (2026-07-23): a mode a
widget can be in must be a serializable FIELD consumed by prototype methods, never a pair
of own function properties installed by an `enable*` call. The one historical case —
`StringWdgt.enableSelecting`'s own `pressBegan`/`pressMoved` closures, which crashed
every snapshot containing a document, text panel, or patch-programming pane — is now the
serializable `isSelectable` flag. (`injectProperty` remains the sanctioned path for
USER-authored instance methods: the function it compiles keeps its source, which serializes as
`{"$src": …}`.)

---

## 6. Per-type handlers

Native / special types the walkers special-case (duplication: the `Duplicator`'s
`_copy*` handlers; serialization: the `$`-tagged record encoders — both recognising
types through the shared `NativeValueKinds`, which duck-types the canvas kind so the
SWCanvas variant is caught too; its gradient and buffer predicates are duplication-only — see
those rows — and its element predicates, `isImage`/`isVideo`, decide a refusal's remediation
in the one walker and a field left `undefined` in the other). A value that rebuilds itself
(`NativeValueKinds.rebuildsItself`: a canvas context, a 3D pane's stamped runtime — a plain `{}` included) is
asked about before any handler: where its holder rebuilds it, it is derived (§5); anywhere else a copy keeps it
by reference and a save refuses it. A BUFFER (`NativeValueKinds.isBuffer`: an ArrayBuffer, or a view onto one — a
typed array, a DataView) is data with a copy handler, `Duplicator._copyBuffer`: an ArrayBuffer byte for byte, a view
rebuilt over the copy of its buffer at the same offset and length, the buffer going through the identity bookkeeping so
views that share one buffer share one in the copy (the rig's `inspector.onABuffer*` and
`duplicate.buffersSharingOneStayShared`); the Serializer has no arm for one, so its closed set refuses it. Anything
else that reaches neither a handler nor a plain object literal must be an
instance of a class boot's `classNamed` answers for — the CLOSED SET, one rule shared by the two
walkers (`Serializer`'s guard and `Duplicator._copyFizzygumObject`'s): an instance of a
browser-native class with no handler (a `DOMRect`, a `CanvasGradient`) is refused, because a save
could not restore it and a copy would hold an object that throws on use:

| Type | Serialize record | Notes |
|---|---|---|
| `Array` | `$Array` `items` | element-wise; own table slot; can be shared between properties |
| `Date` | `$Date` `ms` | the tagged record is what keeps it restorable — a raw `Date` stringifies to a bare ISO string and cannot be deserialized back; an invalid date's `ms` is `{"$num":"NaN"}` (§3), so it restores invalid, not as the epoch |
| `Image` | *(no encoder)* | an element the page loads (§5): the SERIALIZER refuses it in any field that is not a declared transient, with the element remediation; DUPLICATION leaves the field `undefined` and the holder's `_reactToBeingCopied` re-makes it from its path |
| `HTMLCanvasElement` | `$Canvas` `w`/`h`/`pr`/`data`(dataURL) | SWCanvas decode is async → `whenReady`; factory yields the SWCanvas variant when `FIZZYGUM_USE_SWCANVAS`. The data is PHYSICAL pixels made at the saving page's `ceilPixelRatio`, which rides as `pr`. Every canvas that rides a save is its widget's logical size × that ratio (a drawn canvas's `drawnRaster`, FizzyPaint's `behindTheScenesBackBuffer`, a pinned menu row's `InertIconHolderWdgt.raster`), so at another ratio the builder makes the canvas at `w·cpr/pr × h·cpr/pr` and draws the decoded image into it: smoothing on when it shrinks (at 2 → 1 a box of four pixels), off when it enlarges (pixel replication — so 1 → 2 → 1 gives back the very pixels it started from, and no edge pixel is left part-transparent, which a smoothed SWCanvas enlargement does); 2 → 1 → 2 is lossy. Equal ratios take the unscaled draw, byte for byte, and a record without `pr` is taken at the loading page's ratio. The resample happens at the DECODE, never in the adopting widget: the canvas exists at its final size before its pixels arrive, and the file door attaches the widget before the decode lands — an adopter that copied a canvas still waiting for its pixels into a resized raster would lose the drawing outright under SWCanvas. The decode draws at the IDENTITY transform under save/restore: it lands after the restore has handed the canvas to its widget, and a canvas has one context, which that widget may already have scaled (its `_afterDeserialization`, its first paint); the save/restore keeps the smoothing setting off that context too. A resample is not what drawing at the new ratio would give, pixel for pixel — a cross-ratio restore has no reference to match. SWCanvas's `toDataURL` is its own deterministic encoder (per-row PNG filters + fixed-Huffman deflate, alpha kept): identical pixels give identical bytes on every engine, at ~1.2× the browser's own size on a drawn canvas |
| `HTMLVideoElement` | *(no encoder)* | the same as `Image`: refused by a save, left `undefined` by a copy, re-made by its holder |
| `CanvasGradient` | *(no encoder)* | DUPLICATION clones it as `undefined` (`Duplicator._copyGradient`, via `NativeValueKinds.isGradientLike` — its one caller) and consumers rebuild. The SERIALIZER has no gradient branch: a gradient in an own property raises the unrecognized-type `SerializationError` under both backends (under native the closed-set guard refuses it: `classNamed` answers no class for a browser-native one). Keep gradients out of serialized own properties, or declare the property transient (§5). |
| plain `{}` / `Map` / `Set` | `$Object` / `$Map` / `$Set` | each has its own encoder; without one the walker throws |
| `ArrayBuffer` / typed array / `DataView` | *(no encoder)* | DUPLICATION copies it as data (`Duplicator._copyBuffer`, via `NativeValueKinds.isBuffer`): an ArrayBuffer byte for byte, a view rebuilt over the copy of its buffer at its offset and length, the buffer through the identity bookkeeping (views sharing one share one in the copy; a view copies its whole buffer). The SERIALIZER has no arm for one: its closed set refuses it |
| `Color` | `Color` `rgba` | restored through `Color.create` (immutable dedupe); a save refuses a colour whose component is not a number — one written into after it was made (`Serializer._colorComponentsProblem`) |

---

## 7. Identity across modes

Per-class static counters (`Widget.instancesCounter`, `Widget.lastBuiltInstanceNumericID`)
and per-class `instances` Sets; `assignUniqueID` stamps `instanceNumericID`; IDs are
session-local (creation-order dependent, reset by `WorldWdgt.fullDestroyChildren`).

- **Duplication / `kind:"widget"` restore** assign **fresh** IDs (a restored widget coexists
  with live widgets — collisions must be impossible). A saved `#n` differing from the
  restored `#n` is accepted (owner decision, plan §8.5).
- **The serializer is side-effect-free** — it builds records directly, creating no
  shells, so it advances no counters and leaks no phantom `instances` entries; output is
  deterministic. `iid` in each record carries the original's ID.
- **`kind:"world"` restore** restores `iid` and the per-class counters into a
  freshly-reset (empty) ID space.

---

## 8. Errors & UX

`src/serialization/SerializationError.coffee` — a plain class (not `extends Error`, to
avoid a phantom boot dependency) carrying `name`, human `message`, and the structured
`rootDescription` / `path` / `offender` / `remediation` fields, plus a best-effort
`.stack` and a multi-line `toString()`. One class serves both directions, so it also carries a
`direction` — `"save"` (the default: the Serializer's throws) or `"load"` (the Deserializer's: a file
this build cannot restore) — and `toString()` opens with words that say which one failed: "Cannot
load this file: …" for a load, "Cannot serialize: …" for a save. Menu/file actions catch it and
`world.inform` that rendering; headless rigs assert on the structured fields (the rig's
`world.loadGuard.fileDropInformsOnLoadError` also asserts the load wording). A save's `path` is the
full property path from the root, and names each widget as the walk enters it
(`Serializer._pathEntering`): `the world → .children[3] (RectangleWdgt#12) → .f`, a desktop child by
its index in the snapshot's `children`, so a person can find the widget the refusal is about.

---

## 9. Deserializer

`src/serialization/Deserializer.coffee`, five passes: (1) instantiate shells /
native-type factories; (2) populate & link, resolving `$r`/`$wk`/`$ext`/`$num` at any
nesting depth and setting each `$src` property aside; (3) identity & registration
(`registerThisInstance`); (4) fixups (compile each `$src` with its widget's `injectProperty`,
decode async assets into one `whenReady` promise,
re-register `memberships`, per-class `_afterDeserialization` hook — whose answer, when it is a
thenable (an element load the hook started), `whenReady` awaits too); (5) deliver a detached
`{ widget, whenReady }` for the caller to attach, with `resolve` — the one reader of the
reference forms, which the world loader resolves its section's references with. `Widget.deserialize` /
`world.deserialize` become thin delegates.

A record's class becomes a builder or a class only through OWN lookups: `Deserializer._tagBuilderFor`
for the `$`-tags and boot's `classNamed` for a class — never `window[name]`. A record class is a name
read out of a file, and a plain lookup answers it wrongly three ways: it finds INHERITED properties
(`constructor`, `toString`, `__proto__`), runs the browser's ACCESSORS (`location`), and finds every
NATIVE global (`Object`, `Array`) — each of which would pass the world loader's pre-teardown refusal
and then throw, or build a non-Fizzygum shell, after the desktop is gone. A record class neither lookup
answers fails as a load `SerializationError` (§8), from a widget file as from a world file, and so does
an `app:` or class key naming one (§4a). The three nets share one message,
`SerializationError.forMissingClass`, and it is true: a class a LAZY part of this build provides is
"…which this page has not loaded", and only one no part provides "…which this build does not have" — the
refusal's own words.
(The file doors never reach the net with a lazy class, since they load its part first; a synchronous
caller — `Widget.deserialize`, a direct `Deserializer.deserialize` — can.) The rig's
`world.loadGuard.notAClassRefused.*`, `widgetFileNotAClassIsALoadError`, `appKeyNotAClassRefused`
and `idCountersRestoreOnlyClasses` hold it; `boot.classNamedIsTheOneDefinition` holds the predicate.

**What a file needs is loaded before anything is built, at both file doors.** Restoring a file
needs every class it names to be defined, and on a `sources: "lazy"` build some files need the
reflective layer too. `Deserializer.loadWhatItNeeds envelope` answers `undefined` when everything is
resident — every build the suite runs, so there the restore goes on inline — and otherwise a promise
for the next thing, for the door to RE-ENTER its load on, one thing per trip:
1. the LAZY PARTS owning the classes `Deserializer.classNamesIn` lists (record classes that are no
   native-type tag, `app:` keys, class keys — the same list the refusal reads, so a class no part can
   provide is refused before any fetch; what a part's arrival can still refuse is a method's source on
   one of its classes, or an `app:` key naming one of them that is not an app, judged on the re-entry),
   and the parts owning the code a world file's class- and mixin-scope source edits name
   (`SourceEditsRegistry.namesOfTheCodeEditedIn` — a class's name, a mixin's source name `<Name>Mixin`):
   an edit of a lazy part's code rides a file that holds none of that part's widgets, and the replay
   (§12) edits only what is there. An edit whose code no part provides refuses nothing — the restore does
   not need it — and is counted by the load's notice instead (§11). A part an edit alone needs that fails to load
   fails the load, as one a widget needs does;
2. then the reflective layer, when `Deserializer._needsTheReflectiveLayer` says the file needs it: it
   is absent but can load, and the file carries class- or mixin-scope source edits (§12) or holds a
   widget whose class declares `readsClassMemberMaps` — `InspectorWdgt`, which shows and edits a
   member's recorded source, and before the layer would show compiled JS. That declaration is read off
   the resident class, which is why it is asked on the trip after the parts.
A failed load rejects with a load `SerializationError` naming what did not arrive, which the file door
reports (§10). `parts-snapshot-load-headless.js` holds the parts half on the dev `index.html`
(`WIDGET_FILE_LOADS_ITS_PARTS`, `WIDGET_FILE_REFUSED_UP_FRONT`, `FILE_DOOR_REPORTS_A_FAILED_PART`,
beside the world door's sections); the production boot smoke (`fg homepage`) holds the layer half on a
`sources: "lazy"` tree.

A `{"$src"}` stands only as a property of a widget's record, since the load compiles it with that
widget's `injectProperty` and a save writes no other (§5; both sides ask `Serializer.classTakesInjectedMethods`).
One in a tag record (an `$Array` or `$Set` item, a `$Map` entry, an `$Object` property, any `TAG_BUILDERS`
record) makes a malformed table (`Deserializer._envelopeShapeProblem`). One among the properties of a
record of a class that cannot inject a method is refused by
`_functionSourceOnANonWidget`, which judges only the classes resident when it is asked: the world loader
asks it through `whyItCanNeverBeRestored` before its teardown, again on re-entering with a lazy part's
classes loaded, and `deserialize` asks it before pass 1, so a refused widget file leaves no shell
registered. The rig's `world.loadGuard.strayFunctionSourceRefused` and
`widgetFileStrayFunctionSourceRefused` hold both; on the save's side, `serialize2.runReplacedMethodIsRefused`
holds that a `{"$src"}` is written only for the function a widget's field holds now, and
`serialize2.keptSourceFollowsItsFunction` that a renamed member carries its source to its new name.

---

## 10. File save/load over `file://`

`FileSaving.coffee` (`Blob` → `URL.createObjectURL` → synthetic `<a download>` → revoke;
Safari `data:` fallback) and `FileLoading.coffee` (drag-drop via `WorldWdgt`'s drop
handler + a hidden `<input type=file>`; envelope-sniff router on the `kind` field). Single
extension `*.fzw.json` for both widget and world files (owner decision, plan §8.3);
routing is on `kind`, never the filename. Both doors take the same guards before anything is built,
from the same functions: the refusal of a file this build can never restore
(`Deserializer.whyItCanNeverBeRestored`, naming every class it lacks), then what the file needs, loaded
(`Deserializer.loadWhatItNeeds`, §9), re-entering once it arrives. The widget door's "before anything
changes" is before the first shell (`FileLoading._loadWidgetEnvelope`), the world door's before its
teardown (§11). Both restore through `FileLoading._reportingSerializationErrors`, so a
`SerializationError` from a widget file OR a world load is one `inform`, never an uncaught error in
the reader's callback (anything else is a bug and propagates) — and that holds for a load's
ASYNCHRONOUS half too: a load that waits answers a promise (`loadEnvelopeString` returns it), and
its rejection is reported the same way, whether a part the file needs did not load or a re-entered
load failed. **Ships in every profile** — `src/serialization` is
`core`-part code and file save/load is a product feature (`buildSystem/parts.json`).
`file://` capability map: works — Blob
download, `input type=file`, drag-drop + FileReader, `data:` URLs, script-tag injection;
does NOT work — `fetch`/XHR of local files.

---

## 11. Whole-world snapshot (`kind:"world"`)

`WorldWdgt.serializeWorldSnapshot` / `loadWorldSnapshot` (both PRODUCT — `core`-part code, so
every profile ships them).
Save downloads `world.fzw.json` ("Save world snapshot…" world menu); load routes through the
`kind` field (the drop handler / "Open from file…").

**The world is DELIBERATELY NOT a table record.** Serializing the world *widget's* own props
would drag in ~50 transient fields (the render/measure canvases + contexts, seven LRUCaches,
the input-event queue, the hand, the caret, the damage-rect trackers, a dozen event-listener
CLOSURES, `@appearance`'s `CanvasPattern`) — the walker crashes on the first, exactly defect
D8. So the world's genuine state goes into an explicit, greppable **`world` envelope section**,
and only the SNAPSHOT ROOTS are walked into the object table. This is why the world needs no
`@serializationTransients` at all — its transient surface is simply never visited.

**Snapshot roots** (a settled world — the hand-held transient and the caret are dropped by
construction; EPHEMERAL overlays and open TRANSIENT pop-ups/menus (`isTransientPopUp?()`,
§5) are world children, so the
children filter drops them explicitly — the very menu whose item triggers the save is still
attached, and already marked for closure, while the save runs; PERSISTENT pop-ups are desktop
furniture and stay): the desktop `world.children`, the off-tree `world.binWdgt` and
`world.shelfWdgt` subtrees (the two STORAGE containers — the eager storage sort keeps the
shelf holding the reachable residents and the bin the lost ones, `StorageSorter`; a snapshot
taken with a sort still pending is legitimate — each resident serializes wherever it rests
and re-sorts on the first cycle after load; a CLOSED window rests in the bin, `Widget._closeNoSettle`,
so it is saved and restored like an open one), each registered app window (`world.appWindows`,
the windows of the apps that open ONE window, the Docs Maker's templates window among them
(`TemplatesApp`) — may be orphaned-but-revivable). `widgetSet` = the union of their subtrees; the
world itself is excluded (a pointer *to* it becomes `{"$wk":"world"}`).

**`onExternalPointer: "capture"`** (world default, vs `"throw"` for widgets): an off-tree
widget reached only via a property — e.g. the widget a demo `PointerWdgt` stands in for, its
`target` — is pulled into the table as its own record, so "everything reachable is
in-structure" holds and no world state is silently dropped. Self-policing: a genuinely
unserializable value still raises the rich `SerializationError`.

**The `world` envelope section** (outside `objects`, plain and greppable): `children`
(`[{$r}…]`), `desktopColor` (`{$r}`), `alpha`, `isDevMode`, `wallpaperPatternName`,
`infoDocFlags` (the `world.infoDoc_*_created` own booleans — named in one place, `WorldWdgt.infoDocFlagName` /
`isInfoDocFlagName`, which InfoDocs, the save, the load's vetting and the teardown all ask),
`untitledNamingCounters`, `users` (`world.users` — each `User`'s `armedDrawingTool` KEY,
captured by name like the naming service since a `User` is a plain delegated collaborator,
not a tree object), `appWindows` (`{AppClassName:{$r}}`),
`bin` (`{$r}`), `shelf` (`{$r}`), `preferences` (a FORCED data record — `refFor` would give the
`{"$wk":"preferences"}` symbolic link, but the section needs the actual values, restored onto
the static `WorldWdgt.preferencesAndSettings`), `idCounters` (per-class
`lastBuiltInstanceNumericID`, `WorldWdgt`/zeros skipped), and `sourceEdits` (§12).

**Restore** — `loadWorldSnapshot(envelope, {skipConfirm})` — a PUBLIC orchestrator (like
`resetWorld`), so its `setColor`/`_settleLayoutsAfter` calls are the sanctioned public path:
1. **Everything that can stop the load happens before anything changes**, because step 2 destroys
   the desktop and a load that fails after it leaves the user an empty one. In order:
   - **The format check** (`format` + `kind:"world"`) — not a snapshot: one `inform`, stop.
   - **The refusal of a file this build can NEVER restore** — `Deserializer.whyItCanNeverBeRestored`
     (a pure read of the envelope) names the reason: a `formatVersion` newer than
     `Serializer.FORMAT_VERSION`, a malformed object table (no `objects` array; a record naming no class, or
     whose own fields are not the shape a save writes — each tag states its own in `TAG_BUILDERS`' `shapeProblem`,
     a `$Date`'s time and a `Color`'s components numbers among them, and a class record's `props` is an object, its
     `iid` a whole number; a second record of one widget class with one `iid` (no save writes one: a world load
     would restore two widgets sharing a `uniqueIDString`); in a world file, with a section or without, a widget
     record's `iid` above its class's count in the section's `idCounters`, absent meaning 0 (an id a widget of
     that class built after the load would take again) — both `iid` rules judging a widget class this page has,
     so a name it lacks keeps its own refusal; a membership marker naming no world set; a reference no save writes
     (`Deserializer._refProblem`: a scalar, or exactly one form — `$r` an index into the table, `$wk`/`$ext` a
     string, `$src` one function literal's source and nothing after it, `$num` a known text); a `{"$src"}` in a tag
     record), a malformed world section
     (`Deserializer._worldSectionProblem`: every field the section writes — its children and app windows `{"$r"}`s
     to widgets' records, the bin a `BinWdgt`'s, the shelf a `ShelfWdgt`'s, the preferences the
     `PreferencesAndSettings` record, the desktop colour a `Color`'s; its plain fields of their type; an info-doc flag
     only under an `infoDoc_…` name (`WorldWdgt.isInfoDocFlagName`); the source-edit list record by record, as `SourceEditsRegistry.isARecord` reads
     one, and no record's code a function with a statement after it, which every load replaying it would run),
     a widget file carrying a world section (no widget save writes one; its source edits would be fetched for
     and never replayed), a widget file's `root` not a widget's record, `memberships` that are no list or stand on a record that is
     no widget's, a `{"$src"}` on a record of a class that cannot
     inject a method (§9), or a class the file names — a record's class, an `app:` key's, a class
     key's (`Deserializer.classNamesIn`, a record's only when it is no tag — an own-property `TAG_BUILDERS` lookup)
     and no class boot's `classNamed` answers, and that this artifact can never provide
     (`world.parts.canEverProvideClass` — resident, or owned by a part this build ships, so a class
     a LAZY part provides is not a reason), or an `app:` key naming a class that is not an app
     (`WellKnownObjects.isAppClass`, §4a). One `inform` ("…Your desktop has been left as it
     was."), stop. It mirrors exactly the throws a restore would hit — `Deserializer.deserialize`
     raises its envelope-level ones through the same two helpers (`_envelopeShapeProblem`,
     `_functionSourceOnANonWidget`), and `@instantiate` and `WellKnownObjects.resolveApp` keep their
     throws as the net for every other caller — and it precedes the confirm (a fact about the FILE:
     nobody is asked to replace their desktop with a file that cannot load) and the parts fetch (a
     file refused anyway costs no fetch). Four reasons wait for a lazy part, since they are asked of a
     class it provides: whether that class can take a method's source, whether an `app:` key naming
     it names an app, and its records' two `iid` rules — judged once the part has loaded, when the loader re-enters, after the
     confirm and the part's fetch and still before the teardown, so that file too leaves the desktop
     as it was.
   - **The confirm** (a file/menu load warns it replaces the desktop AND can run code — §4.12; the
     rig / a macro pass `skipConfirm`).
   - **Pre-load what the file needs** — `Deserializer.loadWhatItNeeds` (§9, the step the widget door
     takes too), one bail-out-then-re-enter per thing: the LAZY PARTS owning the classes
     `Deserializer.classNamesIn` lists and the code its class- and mixin-scope source edits name
     (`SourceEditsRegistry.namesOfTheCodeEditedIn`), then the reflective layer when the file carries class- or
     mixin-scope source edits or holds an inspector (`readsClassMemberMaps`). It sits after the confirm
     so the user is asked exactly once (the re-entry passes `skipConfirm` for that reason and no
     other). A part that fails to load rejects with a load `SerializationError`, the desktop as it was,
     and the file door reports it (§10). A build that can NEVER load the layer (`sources: "none"`) does
     not wait for it: its replay applies none of the file's class-level edits, and the load's notice
     says how many.
   The load's ONE notice (composed where the counts are known, §12, and said once the rest has loaded, with
   "everything else in the file loaded normally" — or, if the restore throws, before its error and without that
   promise) tells the user what the return to
   boot and the replays did NOT do, each counted where it happens: the class-level records the replays
   did not apply (`classLevelRecordCount` − the replays' applied count — all of them on a `sources:
   "none"` build, and elsewhere each whose class or mixin this build lacks once every part that could
   hold one has loaded, or whose source this build does not compile); and the members this page had
   edited that are STILL its edited versions after the replay — each the return to boot could not give
   back (`returnThePageToBootSources` answers them, `unreturned`, with the source each was left
   running) and no replayed record has since replaced, nor the file's last record of that member already
   describes (the registry's `pageMembersStillRunning`). Each of those is also RECORDED in the loaded world's
   registry (`recordMembersStillRunning`, the record the page's own edit would have been), so a save of the
   loaded world carries the code it runs. A build with no meta-system has
   no page edits to return, so there the second count is always 0.
2. **Structural teardown** — `_teardownWorldStructureNoSettle`, the SHARED shipping core this and
   `resetWorld` both call (the reset then dissolves its world and constructs a new one; a load keeps
   its world). Its contract: after
   `fullDestroyChildren`, the world holds no reference to anything just destroyed, and no
   bookkeeping that assumed it still exists — the tree; the widget the hand is CARRYING (picked up
   or mid float-drag: it belongs to the outgoing world and the file does not contain it, so it is
   destroyed, never dropped onto the restored desktop — `ActivePointerWdgt._discardCarriedWidgetNoSettle`,
   with the hand's drag-embed record cleared by the verb a release uses); the two storage
   containers `binWdgt`/`shelfWdgt`, DESTROYED WHOLE and let go of (they are snapshot roots that
   neither caller keeps, so emptying them would leak the shells on every load — and they die
   before the core's paint-queue filter, since a dying widget re-marks damage); the app-window registry,
   the highlight tracking structures, `errorConsole` /
   `lastEditedText` / `_editorSelectedWidget`, the tooltip / pop-up / clicked-hierarchy / handle /
   paint-error collections, the `_damageSuppressionDepth` counter, and the
   one-shot `infoDoc_*` flags. Restoring what the world should LOOK like afterwards is the
   CALLER's job, which is what steps 3-5 below are. `fullDestroyChildren` also zeroes every per-class
   `lastBuiltInstanceNumericID`, giving the clean id space the restored iids need.
   ⚠ The `infoDoc_*` clear is load-bearing for step 4: that restore is **additive only**, so a flag
   the live world has and the file lacks can only be removed here. The rig gate is
   `world.teardownHygiene.*` in `Fizzygum-tests/scripts/serialization-roundtrip-headless.js` —
   including `loadLeavesNoOrphanedWidgets`, which requires the in-band inventory's escaped and
   zombie lists (`WorldInventory.takeInventory`) to be EMPTY after the load and after it settles, so
   any widget a load forgets to destroy shows, and requires that no frame of the restored world keeps
   a placeholder it does not show — refusing to pass unless some frame holds real contents, so that
   rule cannot go unjudged; and
   `handCargoDestroyed` / `handDragEmbedStateCleared`. The refusals are `world.loadGuard.*`.
   ⚠ From the teardown to step 4 the world has NO storage; the loader's `try/finally` guarantees
   a bin and a shelf whatever happens in between (a file carrying none, or a restore that throws),
   because the end-of-cycle storage drain needs both.
3. Restore `idCounters` **before** deserializing (so `assignUniqueID` — for a record that
   carries no `iid`, and for every widget built after the load — continues past the restored
   high-water marks; each key is resolved through `classNamed`, so one naming no class writes onto
   nothing), then `Deserializer.deserialize` (`kind:"world"` preserves each `iid`;
   returns `shells` so the loader resolves the `world` section's `{$r}` refs).
4. Restore the static `preferences` bag; apply the scalars (isDevMode/alpha/infoDoc/naming/
   icon-count) to the LIVE world; **install** the restored (self-contained, off-tree)
   `binWdgt` and `shelfWdgt` (the teardown destroyed the previous pair) so every `{$r}` pointer
   at them (the bin opener's target, …) stays consistent; re-bind the app windows into `world.appWindows` (orphaned-but-revivable — not
   re-attached to the desktop). Restore completion marks the storage sort pending
   (`noteStorageMembershipMayHaveChanged`), so a mid-pending snapshot re-sorts on the first
   cycle.
5. Attach the desktop children in ONE settle batch via the base `_addNoSettle` (the grid mixin
   overrides only `add`, so `_addNoSettle` does NOT re-place them — restored positions are
   preserved), **passing each child's deserialized `layoutSpec` through** — the snapshot's
   attachment state is authoritative: without the explicit arg the add resolves
   `defaultLayoutSpecWhenAddedTo` (undefined) over the restored slot, disarming the desktop
   furniture's corner knobs and downgrading every stretch record to a seed-drain geometry
   re-derive (the fraction drift the record law forbids); then `setColor` +
   `wallpaper.setPattern` (sequential self-settling public ops); await `whenReady`; repaint.
   Never a raw layout core (DETERMINISM.md risk 4).

`WellKnownObjects.resolveApp(className)` returns a **memoized fresh app singleton** — an
`WindowedApp` subclass is a stateless config holder (its one window lives in
`world.appWindows`, not on the app), so a fresh instance is behaviourally identical and safe to
`new` during a restore. `world.serialize()` is a **guided `SerializationError`** pointing at
`serializeWorldSnapshot`.

The round-trip is proven PIXEL-IDENTICAL same-page AND cross-session (fresh page), at dpr 1 and
dpr 2, for the default desktop (clock region masked — its hands track wall-clock time) and a
populated/customized desktop (added window + moved icon + recoloured desktop + changed
wallpaper): `serialization-roundtrip-headless.js`'s world leg.

---

## 12. Source-edit capture

`SourceEditsRegistry.coffee` at `world.sourceEditsRegistry` (constructed in the WorldWdgt
ctor; a PRODUCT collaborator in the `core` part, so every profile ships it). It logs in-world SOURCE edits so a
whole-world snapshot can carry and replay them. Record: `{scope, className|mixinName,
uniqueID?, propertyName, source?, deleted?}` — plain JSON, embedded verbatim in `world.sourceEdits` (§11).

Three scopes, each recorded by the person's GESTURE that makes it, never by the edit verb the
gesture drives (`mixins.md` §2 — a meta-object or a meta-verb edits; the gesture tells and records) — and,
once, by a world load: a member of the page it could not return to boot that the loaded world still runs is
recorded as that member's edit would have been (`recordMembersStillRunning`, §11):

- **instance** — the object inspector's Save (`InspectorWdgt.applyPropertyEdit`) records
  `recordInstanceEdit(widget, name, txt)` when the value it saves is a function.
  `Widget.injectProperty` itself records nothing: the product injects its own handlers through it
  (an `ImageWdgt`'s overlay, a paint tool's switch) and a load re-injects each `{"$src"}` through
  it, none of them an edit a person made. Instance edits ALSO ride serialization on their own: the
  injected function keeps its source → `{"$src"}` → re-injected on restore (§5). The registry
  adds auditability.
- **class** — the class inspector's class edit step (`ClassInspectorWdgt._editClassMember`)
  edits through `Class.applyMemberEdit` and records `recordClassEdit(prototype, name, txt)` (its
  `@inspectedObject` is the class prototype — the link of the inspected object's own prototype
  chain whose constructor bears the chip's name, `InspectorWdgt._classChainLinks`), for EVERY
  member kind, methods and fields alike; its class removal step (`_removeClassMember`) removes
  through `Class.removeMember` and records `recordClassMemberRemoval(prototype, name)`, a
  `deleted: true` record. This is the ESSENTIAL case: a prototype edit mutates the live class
  but leaves no other serializable trace (§2.7).
- **mixin** — when the selected member's source comes from a mixin (and the class does not
  define the member itself), the inspector's gestures route to the DONOR —
  `Mixin.applyMemberEdit` recompiles the member (mixin super rewrite, function name restored
  for the fake-super companion lookup) and injects it into every consumer class that does
  not define it — and its mixin steps record `recordMixinEdit(mixinName, name, txt)` /
  `recordMixinMemberRemoval(mixinName, name)` (`deleted: true`, replayed via
  `Mixin.removeMember`). Like a class edit, a mixin edit leaves no other serializable trace.

In both of the last two scopes an ADD is an edit whose source is `"undefined"`, and a RENAME is
two records — an edit under the new name, then a removal of the old — so a renamed member is
recompiled under its new name on replay as it was live. Each step makes the edit AND its record
(`ClassInspectorWdgt`, one step per scope × operation), so no gesture of the class inspector
changes a prototype unrecorded. And no other inspector changes one at all: every door that hands
an inspector an arbitrary value opens a class's prototype in its class inspector
(`InspectorWdgt.inspectorClassFor`: the member row's double-click, `Widget.spawnInspector`), and an
object inspector that holds one anyway (built by code, or from a file) is read-only — a prototype
answers the instance edit protocol only through inheritance (`InspectorWdgt._subjectIsEditable`), and
its edit gestures ask that too, since a restored inspector keeps the buttons its file holds.
The class inspector edits the prototype of ANY Fizzygum class, a value class's included. Replay is EXACT because the live state is a function of two stores: each `Class`
and each `Mixin` keeps the CURRENT source of every member it defines (an edit writes it, a
removal deletes it), and a consumer's prototype holds its class's member where the class
defines one, else the donor mixin's (a class removal gives the donor's current member back,
`Class.removeMember`), else nothing (`docs/architecture/mixins.md`, meta-system status).
Replay walks each scope's records in order, so remove-then-re-add lands in its final state.

**Restore** (`loadWorldSnapshot`): the records reproduce the file's members FROM BOOT, so the load
first returns the page to boot (`SourceEditsRegistry.returnThePageToBootSources`): every mixin, then
every class, gives each member whose source differs from the one its source text at boot gives
(`Mixin` / `Class` `bootMemberSources`, the vault's text parsed as the constructor parsed it) that one
back, through its own `applyMemberEdit` / `removeMember` — so a member the page added goes, one it
removed comes back, and the loaded world is the file's, never the file's edits laid over the page's
own. What the page edited is read from the STORES against the vault, not from a registry: a world's
registry lists the edits made under it, while the prototypes are the page's. A class or mixin the
vault holds no text for (one made at run time) has no boot and is left as it is. A member whose boot
source fails to apply is logged and left, and the return answers it among the ones it LEFT, with the
source it was left running. The load's confirm
names how many members it would return (`membersAwayFromBootCount`). Then the registry is rebuilt from
`world.sourceEdits` (`SourceEditsRegistry.fromRecords`) and its **mixin- then class-scope edits are replayed
BEFORE deserialization** (`replayMixinEdits` then `replayClassEdits` — mixin first, the
boot-order analogy: `augmentWith` runs before class-body assignments, so a class-scope edit
of the same member keeps winning), so a shell (`Object.create(prototype)`) already sees the
edited methods; an edit that no longer compiles is logged, not fatal. The return answers how many
members it returned and which it left; each replay answers how many records it applied; and when any
member returned or any record applied, the load tells the world its code changed
(`WorldWdgt.noteCodeChanged`, the class inspector's own notification): a load KEEPS its world, and
with it every cache the old code filled — measured lines, line breaks, immutable back buffers,
each keyed by content — so a page that already showed the edited class's widgets would otherwise
re-show the old code's look, one file making two worlds. The return to boot and both replays are
gated on `SourceEditsRegistry.canReplaySourceEdits()` — class- and mixin-scope replay drives the
META-SYSTEM (`Class.applyMemberEdit` / `removeMember`, `Mixin.allMixines`), and `Class`/`Mixin` arrive only from
the class source directory (with the reflective layer, which the load fetches first wherever it can come —
§9 — or alone ahead of a lazy part). An artifact built `sources: "none"` therefore cannot replay them at all,
and says so once (the class-level records the replay did not apply → one `inform`) rather than dropping the user's
class edits silently — as does a build that lacks the class or mixin an edit names (the load first
brings in every lazy part that holds an edited class or mixin, §9). Instance-scope edits
ride the normal `{"$src"}` path on their own widget — those still load on such a build, since
they need only the compiler every profile ships. The rebuilt registry — the file's records, then each page
member the load could not return that the loaded world still runs as the page edited it
(`pageMembersStillRunning`: not one the file's own last record already describes) — is installed after
deserialize, with the rest of the world. A file/menu load confirms first, warning that a
snapshot can execute code (§4.12 of the plan). Proven fresh-session by
`serialization-roundtrip-headless.js`'s source-edit leg (`sourceEdits.*`): an `injectProperty`
method edit, and the class inspector's add, save, rename and remove of a class's own member, of
a body member never edited (its rename recompiled so `super` follows it), of an override of a
donated member, and the rename of a donated member, each hold in a fresh page exactly as the
editing page left them; and a page that already showed a text before loading a file carrying a
class edit of it shows exactly what the fresh page shows (`sourceEdits.warmLoadEqualsColdLoad`).
A page's own edits — a class member edited, added and removed, a donor's member edited, a file's member
re-edited — leave exactly the file's members away from boot when the file loads onto it
(`sourceEdits.loadOverPageEditsIsTheFilesWorld`), the confirm names how many members the load returns
(`sourceEdits.loadConfirmNamesTheEditsItReturns`), and a file carrying no records leaves the page at
boot (`sourceEdits.loadReturnsThePageToBoot`). On a pre-compiled tree, where the meta-system parses
sources beside code already running, `fg homepage`'s production smoke holds the parse of every mixin a
class augments with and a donated member's return to its donor.

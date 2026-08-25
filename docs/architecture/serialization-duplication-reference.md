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
> source-edit capture (§12 — `SourceEditsRegistry` at `world.sourceEditsRegistry`, hooked at
> `Widget.injectProperty` + `ClassInspectorWdgt.applyPropertyEdit`, embedded in and replayed
> from the world snapshot). The phase ledger that tracked its construction is history — it
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
- `@serializationTransients` (fields to skip) and `wellKnownKey` (symbolic singletons) —
  §5, §4; both consulted by duplication too;
- the `rebuildDerivedValue(s)` derived-value protocol — §5;
- the native-type handlers' logic (Array/Date/Image/Canvas/Video) — §6 — and the
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
- A property whose value has a **`rebuildDerivedValue`** method is a *derived* value and is
  skipped by BOTH walkers. Only DUPLICATION regenerates it (`Duplicator._rebuildDerivedValues`
  asks the ORIGINAL's value to rebuild onto the clone). SERIALIZATION drops it and does not
  restore it — the field comes back `undefined`, so a derived value a restored widget still
  needs must be rebuilt in that class's `_afterDeserialization`. Canvas 2D contexts define
  `rebuildDerivedValue` on their prototype (they rebuild from their sibling canvas by naming
  convention); a class may also STAMP a no-op one onto a runtime-only object to keep it out of
  both walks (§5).
- A property whose value is flagged **`keptByReferenceOnDeepCopy`** is kept by reference
  on duplication. Two kinds of class declare it: world-level shared singletons
  (`Wallpaper`, `WidgetFactory`, `WindowedApp`, `DataflowEngine`,
  `PreferencesAndSettings`) —
  which the serializer *independently* encodes as well-known `{"$wk"}` refs (§4, matched
  by identity, not by this flag) — and immutable value classes (`Point`, `Rectangle`,
  `ShadowInfo`, `TransformSpec`, `SheetError`), which serialize as ordinary values
  (sharing round-trips via the identity-keyed object table). See
  `docs/architecture/immutable-value-classes.md` §4.
- A `Widget` NOT in the **in-structure set** is **external**: duplication keeps the live
  reference (so a duplicate can stay wired to an outside widget); serialization cannot
  keep a live pointer, so this is where the well-known / error policy applies (§4).
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
    { "class": "$Canvas", "w": 300, "h": 200, "data": "data:image/png;base64,…" },
    { "class": "$Image",  "src": "data:…" },
    { "class": "$Video",  "src": "…", "autoplay": false, "currentTime": 0 },
    { "class": "$Object", "props": { … } },
    { "class": "$Map",    "entries": [ [k, v], … ] },
    { "class": "$Set",    "items": [ … ] }
  ],
  "world": { … }                     // kind:"world" only (§11)
}
```

- **References are structured values, never in-band strings** — this is what fixes the old
  format's silent corruption of any user string starting with `$`. The three reference
  forms (§4) are `{"$r":n}`, `{"$wk":key}`, `{"$src":coffee}` (plus `{"$ext":id}`, the token
  the tolerant `onExternalPointer:"record"` mode emits — resolvable by unique-id on restore,
  but no shipped caller selects that mode). A plain JSON object as a *value* is always a table
  slot (`$Object`), so a `props` value is unambiguously one of the reference forms by
  construction; plain user strings need no escaping.
- **Native types carry `$`-prefixed class tags** (`$Array`/`$Date`/`$Canvas`/`$Image`/
  `$Video`/`$Object`/`$Map`/`$Set`). User class names are CoffeeScript identifiers and can
  never collide with a `$`-prefixed tag.
- `Color` keeps a compact `rgba` form, restored through the `Color.create` factory so
  immutable-color dedupe is preserved.
- `iid` records the original `instanceNumericID` (informational for `kind:"widget"`;
  restored for `kind:"world"`). `memberships` records world-set membership at save time
  (§5).
- Output is **deterministic** given identical world state (the serializer touches no ID
  counters — §7). A `prettyPrint` option indents for humans/diffs.

---

## 4. Reference policy

At serialize time each encountered object is classified, in order:

1. **In-structure** (a widget in the arrow-contract closure — §2, or any non-widget
   reached by the walk) → table slot, `{"$r": n}`.
2. **Well-known** → `{"$wk": key}`, via `WellKnownObjects` (§4a).
3. **A detach-root's `parent`** → `null` — the envelope root plus any embedded referent
   figures the closure contributed. Deserialization returns the root *detached* (the
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
classification. Transient fields (§5) never reach classification at all.

### 4a. WellKnownObjects

`src/serialization/WellKnownObjects.coffee` is a two-way symbolic registry for the
singletons present in every world: `world`, `hand`, `wallpaper`, `widgetFactory`,
`dataflow` (the `DataflowEngine` — a shipped product collaborator; its edge index is
derived/disposable and never serialized), `bin`, `shelf`, `preferences`, and
`app:<ClassName>` per windowed-app singleton.

- `WellKnownObjects.keyFor(obj)` → symbolic key or `undefined`.
- `WellKnownObjects.resolve(key)` → the live object in the **current** world, or `undefined`
  (an unknown key is the deserializer's cue to raise a rich error).

**It is lazy, not snapshotted.** Keys resolve against the live `world` on demand rather
than from a boot-time map. This is boot-order-safe (bin/apps are built after the
world) and — crucially — correct for cross-session restore: a key binds to the *new*
session's singletons, not to a stale map. The per-world singletons are matched by identity
against the live world in `keyFor`; the `wellKnownKey` marker on the collaborator classes
(`Wallpaper` → `"wallpaper"`, `WidgetFactory` → `"widgetFactory"`, `DataflowEngine` →
`"dataflow"`, `PreferencesAndSettings` → `"preferences"`, `WindowedApp` →
`"app:" + @constructor.name`) is the general fallback
and documents intent (it is the eventual replacement for `keptByReferenceOnDeepCopy`).
`WellKnownObjects.resolveApp(className)` completes the `app:` branch: it `new`s the named
`WindowedApp` subclass and MEMOIZES one instance per class
(`@_appSingletons`), which is safe because such an app is a stateless config holder — its one
window lives on `world[@slot]`, not on the app (§11).

The link is symbolic and reconstructable — it preserves identity, which a bare opaque
`"$EXTERNAL"` marker cannot.

---

## 5. How a class declares what NOT to serialize

The routine way to keep a field out of a saved file is a class-body declaration, additive and
inherited (merged up the chain like the codebase's other class-body conventions):

```coffee
class Widget extends TreeNode
  @serializationTransients: ["lastTime", "cachedFullBounds", …]  # skipped at serialize
```

- **The reader** is `Serializer.transientsForClass(klass)` — walks the class chain, unioning each
  class's own `@serializationTransients` into one Set of names to skip. **A subclass declares its
  OWN fields and nothing else**: the merge is the rule, so re-stating an ancestor's entry is
  duplication, and a subclass can never drop one.
  ⚠ **The chain to walk is `__super__`, not `Object.getPrototypeOf`.** This tree does not use ES
  class inheritance: `extend` (`src/boot/globalFunctions.coffee`) COPIES the parent's statics onto
  the child and links them only through `child.__super__ = parent.prototype`. That copy-down is why
  a subclass declaring NOTHING inherits the list correctly, and why a subclass's OWN list would
  REPLACE everything above it under a prototype-chain walk (the chain shows no parent there, so
  such a walk returns the one declaration it can see — the trap the `__super__` walk below
  exists to avoid). Silent by construction: it fires only on
  the classes that declare, and only on fields those instances happen to own. `FrameWdgt` declaring
  a list during the frame-lifetime plan's P3 is what surfaced it; the merge landed as its tail item
  T16, and the frame's `isPopUpMarkedForClosure` moved back onto `FrameWdgt` where it belongs.
  Verified by grep (`grep -rn "@serializationTransients" src`), ten classes carry their own
  declaration today besides `Widget` itself: `FrameWdgt`, `ScriptWdgt`, `TransformFrameWdgt`,
  `DesktopAppearance`, `SheetHeaderCellWdgt`, `SimpleSpreadsheetWdgt`, `SheetCellRecord`,
  `CellWdgt`, `CalculatingPatchNodeWdgt`, `FridgeMagnets3DCanvasWdgt`. The rig check that holds the
  merge is in `../Fizzygum-tests/scripts/serialization-roundtrip-headless.js` — it serializes a
  self-declaring class and asserts an INHERITED transient is absent from the record.
- **Derived values** keep the existing `rebuildDerivedValue` protocol (canvas 2D
  contexts): both walkers SKIP them, and only duplication rebuilds. The deserializer does
  NOT — its pass-4(b) branch reads a `record.derived` list the serializer has never emitted,
  so it is dead code. Rebuild what a restored widget needs in that class's
  `_afterDeserialization`.
  - ⚠ **The two mechanisms do NOT cover each other** (2026-07-08 SW3D-port incident, ~1 h):
    `@serializationTransients` is read by the FILE Serializer ONLY. The in-memory
    **Duplicator** never consults it — its coverage comes from five mechanisms of its own:
    a NAME-convention skip in `_cloneContentInto` (the version-keyed cache pairs
    `cached*`/`check*Cache` plus `childrenBoundsUpdatedAt`, and the island source-lane
    `_islandBufferSource*` pair), the VALUE-carried `rebuildDerivedValue` skip-and-rebuild,
    `keptByReferenceOnDeepCopy`, the `alignCopiedWidgetTo*` world-set aligners, and the
    per-class `_reactToBeingCopied` hook. A property covered by none of these gets
    deep-copied — and a runtime-only object there crashes the copy on the Duplicator's
    closed-set guard ("cannot duplicate a value of unrecognized type"). **Fix: stamp a
    no-op `rebuildDerivedValue` on the runtime-only object itself** (that both skips the
    copy and marks it derived); listing it in `@serializationTransients` as well is
    correct but not sufficient.
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
  - if a `foo_source` sibling exists (a user-injected method) → serialize `{"$src":
    <source>}` and let `foo_source` ride as a normal string; restore recompiles via the
    existing `injectProperty`/`evaluateString` path.
  - else if `foo` is in the class's transients → dropped; the class recomputes it (e.g.
    patch nodes recompute `functionFromCompiledCode` from their text; scroll-momentum
    `@step` closures simply stop, which is correct for a settled restore).
  - else → `SerializationError` with the property path (never a silent drop).

**The declarations whose REASON is not obvious from the field name:**

| Class | Transients | Why |
|---|---|---|
| `Widget` (caches) | `lastTime`; the render caches `backBuffer`/`backBufferContext` and their shadow-silhouette twins; the `WorldWdgt.geometryVersion`-keyed geometry caches (`cachedFullBounds`, `cachedFullClippedBounds`, `cachedVisibleBasedOnIsVisibleProperty`, `cachedClippedThroughBounds`, `cachedClipThrough`, `cachedIsInCollapsedSubtree` — each with its `check…Cache` twin — plus `childrenBoundsUpdatedAt`); the `root()` cache `cachedRoot`/`checkRootCache`; the island-buffer source lane `_islandBufferSourceIsland`/`_islandBufferSourceVirtualRect`; the flush-scoped `hasDirtyDescendant` | frame timing + derived caches, all re-derived on demand after restore. ⚠ `cachedRoot` is the one whose absence bit: `root()` itself never reads it stale (it checks `structureVersion`) but the SERIALIZER walks the raw field, so a stale pointer dragged destroyed subtrees — and their unserializable handler functions — into capture-mode world snapshots |
| `Widget` (damage bookkeeping) | `paintBoundsMaybeChanged`, `fullPaintBoundsMaybeChanged`, `clippedBoundsWhenLastPainted`, `fullClippedBoundsWhenLastPainted`, `srcDamageRectIndex`, `dstDamageRectIndex` | per-frame damage-rect bookkeeping, each field paired with never-serialized world-level flush state (the `widgetsWithMaybeChanged(Full)PaintBounds` work-lists / the flesh-out). A restored `true` dedupe flag has no matching work-list entry, so `_changed()`/`_fullChanged()` would be permanently suppressed on the restored widget — the 2026-07-22 bug: a snapshot saved from a menu click baked the triggering click's `bringToForeground` → `_fullChanged()` mark into the menu's record, and the restored menu left repaint artifacts when moved |
| `FrameWdgt` | `isPopUpMarkedForClosure` | pairs with the `world.popUpsMarkedForClosure` set; the triggering menu-item click marks its menu for closure before the action runs. It sat on `Widget` while the merge was broken (the base was the only place a declaration was safe); with the merge fixed it is declared by the class that owns and reads it |
| `DesktopAppearance` | `pattern`, `currentPattern` | `pattern` is a `CanvasPattern` (the first thing a whole-world serialize crashed on); both re-derive from `world.wallpaper.patternName` |
| `CalculatingPatchNodeWdgt` | `functionFromCompiledCode` | the user formula COMPILED; `recalculateOutput` re-derives it from the (serialized) formula text on every recompute. Was long documented here as the canonical example yet never actually declared — every snapshot containing a patch-programming window crashed until 2026-07-23 |
| `ScriptWdgt` | `functionFromCompiledCode` | the saved script COMPILED (`@savedScript` is the truth); `doAll` recompiles it on demand after a restore |

The declarations are the inventory — `grep -rn "@serializationTransients" src/` lists all
ten classes that carry one, and the table above keeps only the rows a reader could not
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
copy call re-derives the persistent one.

**Instance-assigned handler functions are BANNED as a state idiom** (2026-07-23): a mode a
widget can be in must be a serializable FIELD consumed by prototype methods, never a pair
of own function properties installed by an `enable*` call. The one historical case —
`StringWdgt.enableSelecting`'s own `mouseDownLeft`/`mouseMove` closures, which crashed
every snapshot containing a document, text panel, or patch-programming pane — is now the
serializable `isSelectable` flag. (`injectProperty` remains the sanctioned path for
USER-authored instance methods: it stores the `<name>_source` sibling that serializes as
`{"$src": …}`.)

---

## 6. Per-type handlers

Native / special types the walkers special-case (duplication: the `Duplicator`'s
`_copy*` handlers; serialization: the `$`-tagged record encoders — both recognising
types through the shared `NativeValueKinds`, which duck-types the canvas kind so the
SWCanvas variant is caught too; its gradient predicate is duplication-only — see the
gradient row):

| Type | Serialize record | Notes |
|---|---|---|
| `Array` | `$Array` `items` | element-wise; own table slot; can be shared between properties |
| `Date` | `$Date` `ms` | the tagged record is what keeps it restorable — a raw `Date` stringifies to a bare ISO string and cannot be deserialized back |
| `Image` | `$Image` `src` | async decode on restore → the `whenReady` promise |
| `HTMLCanvasElement` | `$Canvas` `w`/`h`/`data`(dataURL) | SWCanvas decode is async → `whenReady`; factory yields the SWCanvas variant when `FIZZYGUM_USE_SWCANVAS` |
| `HTMLVideoElement` | `$Video` `src`/`autoplay`/`currentTime` | tagged on its own record; mis-tagging it as a canvas crashes the restore |
| `CanvasGradient` | *(no encoder)* | DUPLICATION clones it as `undefined` (`Duplicator._copyGradient`, via `NativeValueKinds.isGradientLike` — its one caller) and consumers rebuild. The SERIALIZER has no gradient branch: a gradient in an own property is emitted as an ordinary class record under the native backend, and raises the unrecognized-type `SerializationError` under SWCanvas. Keep gradients out of serialized own properties, or declare the property transient. |
| plain `{}` / `Map` / `Set` | `$Object` / `$Map` / `$Set` | each has its own encoder; without one the walker throws |
| `Color` | `Color` `rgba` | restored through `Color.create` (immutable dedupe) |

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
`.stack` and a multi-line `toString()`. Menu/file actions catch it and `world.inform` the
message; headless rigs assert on the structured fields. The old `debugger`/`console.log`/
`alert` leftovers in the ser/deser path are removed with the rewrite.

---

## 9. Deserializer

`src/serialization/Deserializer.coffee`, five passes: (1) instantiate shells /
native-type factories; (2) populate & link, resolving `$r`/`$wk`/`$src`/`$ext` at any
nesting depth; (3) identity & registration (`registerThisInstance`); (4) fixups
(compile `$src`, decode async assets into one `whenReady` promise,
re-register `memberships`, per-class `_afterDeserialization` hook); (5) deliver a detached
`{ widget, whenReady }` for the caller to attach. `Widget.deserialize` /
`world.deserialize` become thin delegates.

---

## 10. File save/load over `file://`

`FileSaving.coffee` (`Blob` → `URL.createObjectURL` → synthetic `<a download>` → revoke;
Safari `data:` fallback) and `FileLoading.coffee` (drag-drop via `WorldWdgt`'s drop
handler + a hidden `<input type=file>`; envelope-sniff router on the `kind` field). Single
extension `*.fzw.json` for both widget and world files (owner decision, plan §8.3);
routing is on `kind`, never the filename. **Ships in every profile** — `src/serialization` is
`core`-part code and file save/load is a product feature (`buildSystem/parts.json`).
`file://` capability map: works — Blob
download, `input type=file`, drag-drop + FileReader, `data:` URLs, script-tag injection;
does NOT work — `fetch`/XHR of local files.

---

## 11. Whole-world snapshot (`kind:"world"`)

`WorldWdgt.serializeWorldSnapshot` / `loadWorldSnapshot` (both PRODUCT — `core`-part code, so
every profile ships them).
Save downloads `world.fzw.json` ("save world snapshot…" world menu); load routes through the
`kind` field (the drop handler / "open from file…").

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
and re-sorts on the first cycle after load), each non-undefined app-slot window
(`Serializer.WORLD_APP_SLOTS` — may be orphaned-but-revivable), and
`world.simpleEditorTemplates`. `widgetSet` = the union of their subtrees; the
world itself is excluded (a pointer *to* it becomes `{"$wk":"world"}`).

**`onExternalPointer: "capture"`** (world default, vs `"throw"` for widgets): an off-tree
widget reached only via a property — e.g. a non-empty folder window's `defaultContents`
placeholder — is pulled into the table as its own record, so "everything reachable is
in-structure" holds and no world state is silently dropped. Self-policing: a genuinely
unserializable value still raises the rich `SerializationError`.

**The `world` envelope section** (outside `objects`, plain and greppable): `children`
(`[{$r}…]`), `desktopColor` (`{$r}`), `alpha`, `isDevMode`, `wallpaperPatternName`,
`numberOfIconsOnDesktop`, `infoDocFlags` (the `world.infoDoc_*_created` own booleans),
`untitledNamingCounters`, `appSlots` (`{slot:{$r}}`), `simpleEditorTemplates` (`{$r}`),
`bin` (`{$r}`), `shelf` (`{$r}`), `preferences` (a FORCED data record — `refFor` would give the
`{"$wk":"preferences"}` symbolic link, but the section needs the actual values, restored onto
the static `WorldWdgt.preferencesAndSettings`), `idCounters` (per-class
`lastBuiltInstanceNumericID`, `WorldWdgt`/zeros skipped), and `sourceEdits` (§12).

**Restore** — `loadWorldSnapshot(envelope, {skipConfirm})` — a PUBLIC orchestrator (like
`resetWorld`), so its `setColor`/`_settleLayoutsAfter` calls are the sanctioned public path:
1. Confirm (a file/menu load warns it replaces the desktop AND can run code — §4.12; the rig /
   a macro pass `skipConfirm`), then **pre-load what the file needs, before touching anything** —
   two bail-out-then-re-enter guards, in that order. Their POSITION is the whole correctness
   argument: step 2 destroys the desktop, so anything that fails to load must leave the user's
   world intact, and they sit after the confirm so the user is asked exactly once (the re-entry
   passes `skipConfirm` for that reason and no other).
   - **Lazy parts.** `Serializer.classNamesIn` reads the envelope (a pure read) for record classes
     and `app:` well-known keys; any class living in a LAZY part this page has never loaded is
     fetched via `world.parts.ensureAllLoaded`, and the loader then RE-ENTERS itself.
   - **The META-SYSTEM, same shape.** On a `sources: "lazy"` build whose file carries class- or
     mixin-scope source edits, `ensureReflectiveLayerLoaded()` then re-enter. A build that can
     NEVER load it (`sources: "none"`) does not come through here at all — it takes the refusal
     instead, telling the user once, before the world is rebuilt, how many class-level edits it
     cannot re-apply (`SourceEditsRegistry.unreplayableSourceEditsCount` — §12).
2. **Structural teardown** — `_teardownWorldStructureNoSettle`, the SHARED shipping core this and
   the TEST-REPO teardown (`_resetWorldNoSettle`, in
   `Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee`, which travels with
   the `harness` part) both call. Its contract: after
   `fullDestroyChildren`, the world holds no reference to anything just destroyed, and no
   bookkeeping that assumed it still exists — the tree, `binWdgt`/`shelfWdgt`, the app slots +
   `simpleEditorTemplates`, the highlight tracking structures, `errorConsole` /
   `lastEditedText` / `_editorSelectedWidget`, the tooltip / pop-up / clicked-hierarchy / handle /
   scroll-momentum / paint-error collections, the `_damageSuppressionDepth` counter, and the
   one-shot `infoDoc*` flags. Restoring what the world should LOOK like afterwards is the
   CALLER's job, which is what steps 3-5 below are. `fullDestroyChildren` also zeroes every per-class
   `lastBuiltInstanceNumericID`, giving the clean id space the restored iids need.
   ⚠ The `infoDoc*` clear is load-bearing for step 4: that restore is **additive only**, so a flag
   the live world has and the file lacks can only be removed here. The rig gate is
   `world.teardownHygiene.*` in `Fizzygum-tests/scripts/serialization-roundtrip-headless.js`.
3. Restore `idCounters` **before** deserializing (so `registerThisInstance` sees the right
   high-water marks), then `Deserializer.deserialize` (`kind:"world"` preserves each `iid`;
   returns `shells` so the loader resolves the `world` section's `{$r}` refs).
4. Restore the static `preferences` bag; apply the scalars (isDevMode/alpha/infoDoc/naming/
   icon-count) to the LIVE world; **swap** in the restored (self-contained, off-tree)
   `binWdgt` and `shelfWdgt` so every `{$r}` pointer at them (the bin opener's target, …)
   stays consistent; re-bind the app-slot / templates windows (orphaned-but-revivable — not
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
`WindowedApp` subclass is a stateless config holder (its one window lives on
`world[@slot]`, not on the app), so a fresh instance is behaviourally identical and safe to
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
uniqueID?, propertyName, source}` — plain JSON, embedded verbatim in `world.sourceEdits` (§11).

Three scopes, captured at the three edit choke points (function edits only — the `$src`-backed
ones):

- **instance** — `Widget.injectProperty` records `recordInstanceEdit(widget, name, txt)`. These
  ALSO ride serialization on their own: the widget carries a `<name>_source` string →
  `{"$src"}` → re-injected on restore (§5). The registry adds auditability.
- **class** — `ClassInspectorWdgt.applyPropertyEdit` records `recordClassEdit(prototype, name,
  txt)` (its `@inspectedObject` is the class prototype — `new ClassInspectorWdgt window[className].prototype`)
  for EVERY member kind, methods and fields alike (both apply via `Class.applyMemberEdit`, which
  keeps the `<name>_source` sibling for both). This is the ESSENTIAL case: a prototype edit
  mutates the live class but leaves no other serializable trace (§2.7).
- **mixin** — the same `ClassInspectorWdgt.applyPropertyEdit`, when the selected member's
  source comes from a mixin (and the class body doesn't shadow it), routes the save to the
  DONOR — `Mixin.applyMemberEdit` recompiles the member (mixin super rewrite, function name
  restored for the fake-super companion lookup) and re-injects it into every non-shadowing
  consumer class — and records `recordMixinEdit(mixinName, name, txt)`. Like a class edit,
  a mixin edit leaves no other serializable trace. Two record variants share the scope:
  a donated STATIC's edit records `static: true` (replayed via `Mixin.applyStaticEdit`,
  which re-copies onto consumer constructors), and a member REMOVAL records
  `deleted: true` (`recordMixinMemberRemoval`, replayed via `Mixin.removeMember`);
  replay walks the records in order, so remove-then-re-add lands in its final state.

**Restore** (`loadWorldSnapshot`): the registry is rebuilt from `world.sourceEdits`
(`SourceEditsRegistry.fromRecords`) and its **mixin- then class-scope edits are replayed
BEFORE deserialization** (`replayMixinEdits` then `replayClassEdits` — mixin first, the
boot-order analogy: `augmentWith` runs before class-body assignments, so a class-scope edit
of the same member keeps winning), so a shell (`Object.create(prototype)`) already sees the
edited methods; an edit that no longer compiles is logged, not fatal. Both replays are gated on
`SourceEditsRegistry.canReplaySourceEdits()` — class- and mixin-scope replay drives the
META-SYSTEM (`Class.applyMemberEdit`, `Mixin.allMixines`), and `Class`/`Mixin` arrive only with
the class SOURCE TEXT. An artifact built `sources: "none"` therefore cannot replay them at all,
and says so once (`unreplayableSourceEditsCount` → one `inform`) rather than dropping the user's
class edits silently. Instance-scope edits
ride the normal `{"$src"}` path on their own widget — those still load on such a build, since
they need only the compiler every profile ships. The rebuilt registry is installed AFTER deserialize (so the
`$src` re-injections don't double-log into it). A file/menu load confirms first, warning that a
snapshot can execute code (§4.12 of the plan). Proven fresh-session: an `injectProperty` method
edit and a `ClassInspectorWdgt` prototype edit both survive into a fresh page where the prototype
had no such method (`serialization-roundtrip-headless.js` source-edit leg).

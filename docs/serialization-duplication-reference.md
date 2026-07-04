# Serialization / Deserialization / Duplication — the reference

**This is the ONE home for all serialization, deserialization, and duplication
documentation.** The format spec, the traversal contract the two walkers share, the
per-class protocol, the per-type handlers, and the `file://` capability map all live
here. CLAUDE.md files only LINK here (per owner direction, 2026-07-04) — never copy this
content into a CLAUDE.md.

Companion: `docs/serialization-deserialization-plan.md` is the phased execution plan
(current-state survey, spike-verified defect catalog, design rationale, exit gates,
owner-resolved decisions, landed-status). This reference is the *durable* description of
how the machinery works; the plan is the *build order*.

> **Implementation status.** Markers below say what is live vs planned:
> **[LIVE]** in the build · **[Ph N]** lands in plan Phase N. As of **Phase 3**: the whole
> widget serialization round-trip is **LIVE and wired** — `Widget.serialize` →
> `Serializer.serializeWidget` (the §3 envelope), `Widget.deserialize` / `world.deserialize`
> → `Deserializer.deserialize`; the old `doSerialize=true` prototype and its dead trio are
> deleted; duplication (`DeepCopierMixin`, `doSerialize`-free) is unchanged and pixel-verified.
> Restored widgets are byte-identical to the originals (same-page AND cross-session). **File
> save/load over `file://` (§10) is also LIVE** — `Widget.saveToFile` / `FileSaving`, the
> `WorldWdgt` drop handler / `FileLoading`, `*.fzw.json` routed on `kind`. Still [Ph N]: the
> whole-world snapshot (§11, Ph 5 — `FileLoading`'s `kind:"world"` branch + `WellKnownObjects.resolveApp`
> are stubbed for it), source-edit capture (§12, Ph 6).
>
> NB: `buildSystem/build.py` discovers sources via an explicit directory allowlist — any new
> `src/` subdirectory (like `src/serialization/`) must be added there or its classes never
> enter the build.

---

## 1. Two modes, one body of knowledge

Fizzygum has a single object-graph copier, `DeepCopierMixin`, historically used in two
modes via a `doSerialize` flag:

- **Duplication** (`doSerialize=false`) — **[LIVE], load-bearing.** `Widget.fullCopy` →
  `deepCopy false, …`. Clones a widget subtree into live sibling widgets; the SystemTest
  suite bakes its exact pixels in. **This mode is not being changed** by the serialization
  arc, and must stay pixel-identical.
- **Serialization** (`doSerialize=true`) — a **dev-only prototype**, being **replaced**.
  `Widget.serialize` → `deepCopy true, …` emitted a fragile JSON-lines-with-comments
  string with 13 spike-verified defects (see the plan §3). It is superseded by the new
  `Serializer`/`Deserializer` pair; the `doSerialize` branches are deleted once that lands
  (plan Phase 2).

The design decision (plan §4.6) is to **split the walkers but share the knowledge**: the
duplication walker keeps its entangled clone-as-you-traverse behaviour (the SystemTests
depend on it); the serializer is a separate, side-effect-free record builder. What they
share — and what this doc is the single source of truth for — is the per-class *knowledge*:

- the **traversal contract** (own-properties, the cycle/shared-object table, the
  external-widget test against `allWidgetsInStructure`) — §2 below;
- `@serializationTransients` (fields to skip) and `wellKnownKey` (symbolic singletons) —
  §5, §4; both consulted by duplication too;
- the `rebuildDerivedValue(s)` derived-value protocol — §5;
- the native-type handlers' logic (Array/Date/Image/Canvas/Video) — §6.

Keeping this in one doc is what stops the two walkers from drifting silently.

---

## 2. The traversal contract (shared) — **[LIVE]**

`src/mixins/DeepCopierMixin.coffee` walks an object graph cycle-safely:

- Each non-primitive encountered gets one **table slot**; a re-encounter emits a back
  reference (duplication: the memoized clone; serialization: a reference token). This is
  what makes shared substructure and cycles round-trip uniformly — e.g. an array shared
  between two properties is copied once and referenced twice.
- **`own` enumerable properties only** are walked (`recursivelyCloneContent`). Inherited
  prototype methods/fields are not copied — the shell is created with
  `Object.create(Class.prototype)` so they come from the prototype.
- A property whose value has a **`rebuildDerivedValue`** method is a *derived* value: it
  is skipped and later regenerated (only canvas 2D contexts define it — they rebuild from
  their sibling canvas by naming convention).
- A property whose value is flagged **`keptByReferenceOnDeepCopy`** (world-level shared
  singletons: `Wallpaper`, `WidgetFactory`, `IconicDesktopSystemWindowedApp`) is kept by
  reference on duplication; the new serializer encodes it as a well-known `{"$wk"}` (§4).
- A `Widget` NOT in `allWidgetsInStructure` (the set of widgets in the subtree being
  copied) is **external**: duplication keeps the live reference (so a duplicate can stay
  wired to an outside widget); serialization cannot keep a live pointer, so this is where
  the well-known / error policy applies (§4).
- `instanceNumericID` is never copied (clones get fresh identity — §7).

The constructor is **never re-run** on a clone/restored shell (`Object.create` of the
prototype). Classes needing post-construction fixup use hooks (`_reactToBeingCopied` on
duplication; the new `_afterDeserialization` on restore — [Ph 3]).

---

## 3. Envelope format — **[Ph 2]**

The new serializer replaces the JSON-lines-with-comments format with a single versioned
JSON document. One table entry per non-primitive (so sharing/cycles keep working):

```jsonc
{
  "format": "fizzygum",
  "formatVersion": 1,
  "kind": "widget",                  // or "world" (whole-snapshot, [Ph 5])
  "savedAt": "…",                    // informational
  "build": "…",                      // build stamp, informational
  "root": 0,                         // index into objects
  "objects": [
    { "class": "WindowWdgt", "iid": 1, "memberships": [],
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
  "world": { … }                     // kind:"world" only ([Ph 5])
}
```

- **References are structured values, never in-band strings** — this is what fixes the old
  format's silent corruption of any user string starting with `$`. The three reference
  forms (§4) are `{"$r":n}`, `{"$wk":key}`, `{"$src":coffee}` (plus `{"$ext":id}` used
  internally by the world snapshot). A plain JSON object as a *value* is always a table
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

## 4. Reference policy — **[Ph 2 encode] / [Ph 3 resolve]**

At serialize time each encountered object is classified, in order:

1. **In-structure** (a widget in `allWidgetsInStructure`, or any non-widget reached by the
   walk) → table slot, `{"$r": n}`.
2. **Well-known** → `{"$wk": key}`, via `WellKnownObjects` (§4a).
3. **Root's `parent`** → `null`. Deserialization returns a *detached* widget; the caller
   (menu action / drop handler / snapshot loader) decides where to attach.
4. **Anything else** → **`SerializationError`** (§8) carrying the root, the full property
   path to the offending reference, a description of the offender, and remediation hints.
   An options bag `onExternalPointer: "throw" (default) | "nullify" | "record"` supports
   tolerant callers; `"record"` emits `{"$ext": id}` for same-world re-linking — used
   internally by the world snapshot, where a second pass resolves it because *everything*
   is in-structure.

Function-valued own properties are handled by the function policy (§5), not this
classification. Transient fields (§5) never reach classification at all.

### 4a. WellKnownObjects — **[LIVE] (registry) / [Ph 3+ consumers]**

`src/serialization/WellKnownObjects.coffee` is a two-way symbolic registry for the
singletons present in every world: `world`, `hand`, `wallpaper`, `widgetFactory`,
`basement`, `preferences`, and `app:<ClassName>` per windowed-app singleton.

- `WellKnownObjects.keyFor(obj)` → symbolic key or `nil`.
- `WellKnownObjects.resolve(key)` → the live object in the **current** world, or `nil`
  (an unknown key is the deserializer's cue to raise a rich error).

**It is lazy, not snapshotted.** Keys resolve against the live `world` on demand rather
than from a boot-time map. This is boot-order-safe (basement/apps are built after the
world) and — crucially — correct for cross-session restore: a key binds to the *new*
session's singletons, not to a stale map. The per-world singletons are matched by identity
against the live world in `keyFor`; the `wellKnownKey` marker on the collaborator classes
(`Wallpaper` → `"wallpaper"`, `WidgetFactory` → `"widgetFactory"`,
`IconicDesktopSystemWindowedApp` → `"app:" + @constructor.name`) is the general fallback
and documents intent (it is the eventual replacement for `keptByReferenceOnDeepCopy`).
App-singleton resolution (`resolveApp`) is stubbed until the whole-world snapshot phase.

This replaces the old bare `"$EXTERNAL"` token (which destroyed all identity) with a
reconstructable symbolic link.

---

## 5. Transients, derived values, and functions — **[LIVE] (protocol) / [Ph 2] (consumed)**

New per-class protocol, additive and inherited (merged up the chain like the codebase's
other class-body conventions):

```coffee
class Widget extends TreeNode
  @serializationTransients: ["lastTime", "cachedFullBounds", …]  # skipped at serialize
```

- **The reader** is `Serializer.transientsForClass(klass)` — walks the constructor chain,
  unioning each class's own `@serializationTransients` into one Set of names to skip. A
  subclass ADDS to (never shadows) its ancestors' declarations.
- **Derived values** keep the existing `rebuildDerivedValue` protocol (canvas 2D
  contexts): the serializer skips them; the deserializer runs `rebuildDerivedValues` to
  regenerate them ([Ph 3]).
- **Functions** ([Ph 2] policy): for an own function-valued property `foo` —
  - if a `foo_source` sibling exists (a user-injected method) → serialize `{"$src":
    <source>}` and let `foo_source` ride as a normal string; restore recompiles via the
    existing `injectProperty`/`evaluateString` path.
  - else if `foo` is in the class's transients → dropped; the class recomputes it (e.g.
    patch nodes recompute `functionFromCompiledCode` from their text; scroll-momentum
    `@step` closures simply stop, which is correct for a settled restore).
  - else → `SerializationError` with the property path (never a silent drop).

**Seed transients (Phase 1, grown as the serializer meets the long tail):**

| Class | Transients | Why |
|---|---|---|
| `Widget` | `lastTime`; the geometry caches `cachedFullBounds`/`checkFullBoundsCache`, `cachedFullClippedBounds`/`checkFullClippedBoundsCache`, `cachedVisibleBasedOnIsVisibleProperty`/`checkVisibleBasedOnIsVisiblePropertyCache`, `cachedClippedThroughBounds`/`checkClippedThroughBoundsCache`, `cachedClipThrough`/`checkClipThroughCache`, `cachedIsInCollapsedSubtree`/`checkIsInCollapsedSubtreeCache`, `childrenBoundsUpdatedAt` | frame timing + `WorldWdgt.geometryVersion`-keyed derived caches; re-derived on demand after restore |
| `DesktopAppearance` | `pattern`, `currentPattern` | `pattern` is a `CanvasPattern` (the first thing a whole-world serialize crashed on); both re-derive from `world.wallpaper.patternName` |

(Further seeds — `ScrollPanelWdgt.@step`, patch nodes' `functionFromCompiledCode`,
`RasterImageWdgt` onload bookkeeping, `WorldWdgt`'s ~25 transient Sets/queues/caches — are
added as Phases 2/5 consume them.)

---

## 6. Per-type handlers — **[LIVE] (dup) / [Ph 2] (serialize encoders)**

Native / special types the walker special-cases (in `boot/extensions/*-extensions.coffee`,
mirrored onto SWCanvas in `SWCanvasElement-extensions.coffee`):

| Type | Serialize record ([Ph 2]) | Notes |
|---|---|---|
| `Array` | `$Array` `items` | element-wise; own table slot; can be shared between properties |
| `Date` | `$Date` `ms` | the old handler pushed a raw `Date` → stringified to a bare ISO string → killed deserialize; the tagged record fixes it |
| `Image` | `$Image` `src` | async decode on restore → the `whenReady` promise ([Ph 3]) |
| `HTMLCanvasElement` | `$Canvas` `w`/`h`/`data`(dataURL) | SWCanvas decode is async → `whenReady`; factory yields the SWCanvas variant when `FIZZYGUM_USE_SWCANVAS` |
| `HTMLVideoElement` | `$Video` `src`/`autoplay`/`currentTime` | the old handler was broken (emitted `className:"Canvas"`, crashed); the tagged record fixes it |
| `CanvasGradient` | `nil` (both modes) | context-bound; consumers rebuild — keep |
| plain `{}` / `Map` / `Set` | `$Object` / `$Map` / `$Set` | the old walker threw on these; the new encoders add support |
| `Color` | `Color` `rgba` | restored through `Color.create` (immutable dedupe) |

---

## 7. Identity across modes — **[LIVE] (dup) / [Ph 2-3] (serialize/restore)**

Per-class static counters (`Widget.instancesCounter`, `Widget.lastBuiltInstanceNumericID`)
and per-class `instances` Sets; `assignUniqueID` stamps `instanceNumericID`; IDs are
session-local (creation-order dependent, reset by `WorldWdgt.fullDestroyChildren`).

- **Duplication / `kind:"widget"` restore** assign **fresh** IDs (a restored widget coexists
  with live widgets — collisions must be impossible). A saved `#n` differing from the
  restored `#n` is accepted (owner decision, plan §8.5).
- **The new serializer is side-effect-free** — it builds records directly, creating no
  shells, so it advances no counters and leaks no phantom `instances` entries; output is
  deterministic. `iid` in each record carries the original's ID.
- **`kind:"world"` restore** ([Ph 5]) restores `iid` and the per-class counters into a
  freshly-reset (empty) ID space.

---

## 8. Errors & UX — **[LIVE] (type) / [Ph 2+] (raised)**

`src/serialization/SerializationError.coffee` — a plain class (not `extends Error`, to
avoid a phantom boot dependency) carrying `name`, human `message`, and the structured
`rootDescription` / `path` / `offender` / `remediation` fields, plus a best-effort
`.stack` and a multi-line `toString()`. Menu/file actions catch it and `world.inform` the
message; headless rigs assert on the structured fields. The old `debugger`/`console.log`/
`alert` leftovers in the ser/deser path are removed with the rewrite.

---

## 9. Deserializer — **[Ph 3]**

`src/serialization/Deserializer.coffee`, five passes: (1) instantiate shells /
native-type factories; (2) populate & link, resolving `$r`/`$wk`/`$src`/`$ext` at any
nesting depth; (3) identity & registration (`registerThisInstance`); (4) fixups
(`rebuildDerivedValues`, compile `$src`, decode async assets into one `whenReady` promise,
re-register `memberships`, per-class `_afterDeserialization` hook); (5) deliver a detached
`{ widget, whenReady }` for the caller to attach. `Widget.deserialize` /
`world.deserialize` become thin delegates.

---

## 10. File save/load over `file://` — **[LIVE]**

`FileSaving.coffee` (`Blob` → `URL.createObjectURL` → synthetic `<a download>` → revoke;
Safari `data:` fallback) and `FileLoading.coffee` (drag-drop via `WorldWdgt`'s drop
handler + a hidden `<input type=file>`; envelope-sniff router on the `kind` field). Single
extension `*.fzw.json` for both widget and world files (owner decision, plan §8.3);
routing is on `kind`, never the filename. **Ships in all builds incl. `--homepage`** — no
homepage-strip markers (it is a product feature). `file://` capability map: works — Blob
download, `input type=file`, drag-drop + FileReader, `data:` URLs, script-tag injection;
does NOT work — `fetch`/XHR of local files.

---

## 11. Whole-world snapshot (`kind:"world"`) — **[Ph 5]**

`WorldWdgt.serializeWorldSnapshot` / `loadWorldSnapshot`: snapshot roots = world subtree +
off-tree basement + non-nil app-slot windows; a `world` envelope section (outside the
object table) carries preferences, wallpaper pattern, desktop color/alpha, dev-mode flag,
info-doc flags, naming counters, app slots, basement ref, per-class ID counters, and the
source-edits registry. Restore tears the world down through the existing reset machinery,
restores counters, deserializes with preserved `iid`, re-links the world sections and
memberships, awaits `whenReady`, settles, repaints. `world.serialize()` becomes a guided
error pointing at `serializeWorldSnapshot`.

---

## 12. Source-edit capture — **[Ph 6]**

`SourceEditsRegistry.coffee` at `world.sourceEditsRegistry`, hooked at the two edit choke
points (`Widget.injectProperty`, `ClassInspectorWdgt.applyPropertyEdit`). The snapshot
embeds the registry; restore replays class-scope edits before instantiation (so prototypes
are correct) and lets instance-scope edits ride the normal `$src` mechanism. Loading from
file confirms first, warning that a snapshot can execute code (§4.12 of the plan).

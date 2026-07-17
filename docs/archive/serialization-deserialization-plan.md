> **ARCHIVED — COMPLETE (2026-07-17 restructure).** ARC COMPLETE; Phases 0-4 pushed 2026-07-04, Phases 5-6 landed same day; fully pushed per project ledger
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Serialization / deserialization plan — widgets → composites → whole-world snapshots, over `file://`

**Status: ARC COMPLETE (pending owner review/commit). Phases 0–4 LANDED + COMMITTED + PUSHED to
`master` (2026-07-04). Phases 5 (whole-world snapshot) and 6 (source-edit capture) LANDED
2026-07-04 (not yet committed) — desktop snapshots round-trip pixel-identical same-page AND
cross-session at dpr 1/2, and in-world instance+class source edits survive into a fresh session.
The whole serialization/deserialization/duplication machinery is now live. §9 is the per-phase
landed-status box. Cold-start execution prompt: `docs/archive/prompts/serialization-execution-starting-prompt.md`.**

This plan is self-contained: it embeds the current-state survey (with `file:line` references), the
empirically-verified defect catalog of the existing prototype (spike-tested against build
`040330e6`, 2026-07-03), the design, the phased execution plan with touch-lists and exit gates,
and the open questions. It can be executed cold.

---

## §0 TL;DR

Fizzygum already has ONE object-graph engine — `DeepCopierMixin.deepCopy(doSerialize, …)` — used in
two modes: `doSerialize=false` is the shipping **duplication** feature (`fullCopy`, exercised by
SystemTests everywhere), `doSerialize=true` is a **dev-only prototype serializer** wired to
`Widget.serialize`/`deserialize` and three "test menu" items. Spikes show the prototype
round-trips simple widgets structurally — even across browser sessions — but has 13 concrete
defects (silent data corruption on `$`-prefixed strings, all colors lost → black chrome, `Date`
kills deserialization, external pointers silently become `undefined`, serialization mutates live
ID counters and leaks phantom instances, no `Map`/`Set`/`{}` support, …).

The plan: keep duplication untouched (pixel-identical), build a proper **`Serializer` /
`Deserializer` pair** in a new `src/serialization/` family that shares the per-class *knowledge*
(transients, well-known singletons, per-type handlers) but not the entangled walker; a versioned
single-JSON envelope with structured (collision-free) reference tokens; **well-known objects**
(`world`, `wallpaper`, app singletons, …) encoded symbolically and re-resolved on restore;
**any other out-of-subtree pointer = a rich, path-carrying error at serialize time**; per-class
**transient/derived field declarations**; a **readiness promise** for async image/canvas decode;
then **file save/load over `file://`** (Blob + `<a download>` and `<input type=file>`/drag-drop +
FileReader — both spike-proven headless), and finally the **whole-world snapshot** (widget tree +
basement + app slots + preferences/wallpaper/naming-counters/ID-counters + a new source-edits
registry so in-world code edits survive).

Phases: **0** characterization rig → **1** scaffolding (error type, well-known registry,
transients protocol) → **2** new serializer → **3** new deserializer + in-memory round-trip green
(+ macro SystemTests) → **4** `file://` save/load → **5** whole-world snapshot → **6** source-edit
capture. Extensions banked in §5.8.

---

## §1 Goal and non-goals

**Goals** (in delivery order):

1. **Widget/composite serialization to a self-contained string** and deserialization into the
   *same or a different* session/world, with visual and behavioural fidelity. Composites include
   *running, inter-connected* widgets (the ControllerMixin `target`/`action` connection system,
   patch-programming nodes, stepping widgets like clocks).
2. **External-pointer policy**: pointers to the world and to "known" singletons that exist in
   every world are encoded symbolically and re-bound on restore; any other pointer that leaves
   the serialized structure raises an error *at serialize time* with the best possible
   explanation (who points, along which property path, at what).
3. **File-based save/load that works over the `file://` protocol** (the normal way Fizzygum runs).
4. **Whole-world snapshot**: serialize the entire world state and restore it in a fresh session —
   including (staged) in-world source edits.

**Non-goals for this arc** (explicitly banked, see §5.8):

- Cross-build/cross-version snapshot migration (format is versioned; per-class migration hooks are
  an extension point, not built now).
- Autosave / `localStorage` persistence, collaborative sync, partial/incremental snapshots.
- Serializing mid-gesture transients (hand grab state, open menus, scroll momentum, caret):
  these are *deliberately dropped* — a snapshot restores a settled world.

---

## §2 Ground truth — the machinery as it stands

### 2.1 One engine, two modes

`src/mixins/DeepCopierMixin.coffee` defines the whole protocol:

- `deepCopy(doSerialize, objOriginalsClonedAlready, objectClones, allWidgetsInStructure)` (L19)
  — cycle-safe graph walk. Already-seen → `"$"+index` token (serialize) or the memoized clone
  (dup). A `Widget` not in `allWidgetsInStructure` → `"$EXTERNAL"+uniqueIDString()` (serialize,
  L30) or the *shared live reference* (dup, L32). This is exactly the duplication behaviour the
  user brief describes: **duplication may keep external connections; serialization cannot**.
- `recursivelyCloneContent(cloneOfMe, doSerialize, …)` (L125) — walks **own** properties:
  `nil` → `nil`; object with `rebuildDerivedValue` → skipped (derived, L147-148); object flagged
  `keptByReferenceOnDeepCopy` → kept by reference / `"$EXTERNAL"` (L149-161); other object →
  recurse `deepCopy` (L167, **throws if the value has no `deepCopy`** — the `{}`/`Map`/`Set` gap,
  with a stray `debugger` at L166); primitive/function → copied, **except `instanceNumericID`**
  (L170).
- `getEmptyObjectOfSameTypeAsThisOne(doSerialize)` (L185) — `Object.create(@constructor::)` shell
  (constructor NOT run), `registerThisInstance?()` (L192), `className` tag when serializing
  (L195), `assignUniqueID?()` (L201-202).
- `rebuildDerivedValues(theOriginal)` (L113) — post-pass: for each property whose *original* value
  has `rebuildDerivedValue`, call it to regenerate on the clone. Only canvas 2D contexts define it
  (`CanvasRenderingContext2D-extensions.coffee:8` — rebuilds `fooContext` from the sibling `foo`
  canvas by naming convention; mirrored onto SWCanvas at `SWCanvasElement-extensions.coffee:156`).
  **Not run on the serialize path** (early return at L54-56).
- End-of-copy world-membership re-alignment (dup path only, L69-99):
  `alignCopiedWidgetToBrokenInfoDataStructures` (`Widget.coffee:2551`),
  `…ToSteppingStructures` (`:2562`, → `world.steppingWdgts`),
  `…ToKeyboardEventsReceiversSet` (`:2568`),
  `…ToReferenceTracker` (`IconicDesktopSystemShortcutWdgt.coffee:52`,
  → `world.widgetsReferencingOtherWidgets`).
- `_reactToBeingCopied?()` hook (L106; sole implementor `LabelButtonWdgt.coffee:169` — un-highlight).

**Entry points** (`src/basic-widgets/Widget.coffee`): `fullCopy` (L2579,
`@deepCopy false, [], [], @allChildrenBottomToTop()`), `duplicateMenuAction`/`…AndPickItUp`
(L2537/2544), `serialize` (L2588: `deepCopy true` then per-object `JSON.stringify` joined with
`\n// --------------------------- \n` comment separators, with leftover `console.log`/`debugger`
diagnostics), `deserialize(serializationString)` (L2608: regex-split on comment lines,
`JSON.parse` each, `Object.create window[className].prototype`, `assignUniqueID`, then a single
flat patch pass replacing `"$N"`-prefixed strings by `clonedWidgets[parseInt(...)]` — top-level
props and array elements only), `serialiseToMemory`/`deserialiseFromMemoryAndAttachToHand`/
`…ToWorld` (L3210-3219, via `world.lastSerializationString`, declared `WorldWdgt.coffee:47` with
the comment that it exists "to make serialization and deserialization tests easier").

### 2.2 Protocol-surface inventory

Classes applying `@augmentWith DeepCopierMixin` (15): `Widget` (`Widget.coffee:14` — hence every
widget), `Pin`, `MenusHelper`, `Point`, `Rectangle`, `Color`, `Point3D`, `PlaneGrid3D`, `Grid3D`,
`WindowContentLayoutSpec`, `VerticalStackLayoutSpec`, `ShadowInfo`, `PreferencesAndSettings`,
`Appearance`, `TextEditingState`.

Overrides / native-prototype handlers:

| Where | What it does (serialize mode) | Notes |
|---|---|---|
| `Color.coffee:247,255` | emits `{className:"Color", compactSerialisedForm:[r,g,b,a]}`; dup mode returns `@` (immutable, shared) | **deserializer never expands the compact form** (defect D5) |
| `Array-extensions.coffee:8` | element-wise; own table slot; `"$"+idx` token | arrays can be *shared* between properties — table-slot treatment is load-bearing |
| `Date-extensions.coffee:6` | pushes a raw cloned `Date` into the table | `JSON.stringify(Date)` → bare ISO string → kills deserialize (D4) |
| `Image-extensions.coffee:5` | `{className:"Image", src}` | onload re-attach TODO (`SERIALISATION_FOR_CLASSES_THAT_TRIGGER_ONLOAD_CALLBACK_NOT_COMPLETE`, L30) |
| `HTMLCanvasElement-extensions.coffee:5` | `{className:"Canvas", width, height, data: toDataURL()}` | deserialize decode is async under SWCanvas (`Widget.coffee:2630-2645`); factory yields `SWCanvasElement` when `FIZZYGUM_USE_SWCANVAS` (L52) |
| `HTMLVideoElement-extensions.coffee:5` | **broken**: emits `className:"Canvas"` (sic, L33) and crashes on `cloneOfMe.video.autoplay` (L35, `cloneOfMe` is `{}`) | D12 |
| `CanvasGradient-extensions.coffee:17` | returns `nil` both modes (context-bound; consumers must rebuild) | acceptable; keep |
| SWCanvas re-wiring (`SWCanvasElement-extensions.coffee`) | copies canvas/gradient `deepCopy` + context `rebuildDerivedValue` onto SWCanvas prototypes | keep pattern for any new handler |

`keptByReferenceOnDeepCopy: true` (world-level shared collaborators, checked only at
`DeepCopierMixin.coffee:149`): `Wallpaper.coffee:24`, `WidgetFactory.coffee:20`,
`IconicDesktopSystemWindowedApp.coffee:18`. Serialize emits a **bare** `"$EXTERNAL"` for these
(no identity at all).

`serializerVersion`/`classVersion`/`prepareBeforeSerialization` (`Point.coffee:23-32`,
`Rectangle.coffee:75-85`, `Color.coffee:214-217`) are **dead legacy** — never read anywhere.
Delete with the rewrite.

The `DUPLICATED_CODE_IN_DEEPCOPY` cycle-table boilerplate is copy-pasted across all 7 `deepCopy`
implementations (TODO id in each file, dated 6-Jun-2023).

### 2.3 Existing UI + test coverage

- The three serialise items live in `MenusHelper.testMenu` (`MenusHelper.coffee:771-775`), reachable
  via right-click → "test menu ➜" only when `isDevMode`/non-index page; the whole block plus
  `Widget.serialize`/`deserialize` (L2587-2683) and `serialiseToMemory` (L3203-3220) are
  homepage-excluded. **The prototype ships in dev/test builds only.**
- **Zero behavioural test coverage** of `doSerialize=true`: the only SystemTest touching the menu
  item (`SystemTest_macroRightClickClosesDownstreamSubMenus`) uses it as a *click target* for
  menu-cascade behaviour. The dup path (`doSerialize=false`) is exercised by every duplicate test.
- Historical design notes: `docs/archive/god-class-decomposition-plan.md:106` (the `$EXTERNAL` rule) and
  `:140` row C24 ("SWCanvas image-decode branch in `deserialize` is backend-sensitive").
  `SliderWdgt.coffee:59,87,121` carry deserialization guards — evidence of per-class workaround
  drift the new design must absorb systematically.

### 2.4 Identity system

Per-class static counters (`Widget.coffee:26-31`): `@instancesCounter`,
`@lastBuiltInstanceNumericID`; `assignUniqueID` (L307-310) increments both and stamps
`@instanceNumericID`; `uniqueIDString()` = `"<Class>#<n>"` (L292). Per-class `instances` Sets
(created in `meta/Class.coffee:407-408`) maintained by `registerThisInstance`/
`unregisterThisInstance` (L359-384) walking the superclass chain. IDs are **session-local**:
creation-order dependent, reset by `WorldWdgt.fullDestroyChildren` (`WorldWdgt.coffee:1990-2013`),
re-aligned to the next 1000 for test determinism (`Widget.coffee:323-329`). Clones always get
fresh IDs (`instanceNumericID` skipped at `DeepCopierMixin.coffee:170`).
(NB `docs/archive/widget-identity-decoupling-plan.md` is about `instanceof`-style type tests, *not* this
identity system — it explicitly left serialization alone.)

### 2.5 Cross-object pointer categories (what a serializer must decide about)

| # | Category | Representative fields | Policy (per §4.2/§4.3) |
|---|---|---|---|
| 1 | `parent` of the serialized root | `TreeNode` `parent` | serialize as `null`; attachment is the restorer's job |
| 2 | Controller connections | `ControllerMixin` `@target` + string `@action` (`ControllerMixin.coffee:29-48`; mixed into Slider/Palettes/StringWdgt/SimplePlainText/patch nodes); `ButtonWdgt` `@target/@action/@doubleClickAction/@dataSourceWidgetForTarget/@widgetEnv/@argumentToAction1..2` (`ButtonWdgt.coffee:13-50,111`); `MenuItemWdgt` (`:19`) | in-structure → `$r` ref; well-known → `$wk`; otherwise **error**. Action names are strings — free. |
| 3 | Desktop shortcuts | `IconicDesktopSystemShortcutWdgt.@target` (`:32`), registered in `world.widgetsReferencingOtherWidgets` | same as 2, + membership recorded/restored |
| 4 | Inspectors | `InspectorWdgt.@target` (`meta/InspectorWdgt.coffee:107`) — *any* object incl. class prototypes (`ClassInspectorWdgt` at `:388`) | usually external → the canonical rich-error case; class-prototype targets get a `$wk` form (`class:Name`) later if wanted (banked) |
| 5 | Caret ↔ text | `world.caret`, `CaretWdgt.target` (`CaretWdgt.coffee:5,10`), `world.lastEditedText` | transient: never serialized (caret is rebuilt by clicking; world snapshot drops it) |
| 6 | Window/scroll content | `WindowWdgt.@contents` (`WindowWdgt.coffee:27,106`), `ScrollPanelWdgt.contents` | in-structure children → `$r` (works today) |
| 7 | Hand/pointer transients | `ActivePointerWdgt` `mouseDownWdgt/wdgtToGrab/mouseOverList(Set)/…` (`:13-36`) | transient; hand never serialized |
| 8 | World singletons | `Wallpaper`, `WidgetFactory`, app objects (`IconicDesktopSystemWindowedApp`) | `$wk` well-known keys (replaces bare `"$EXTERNAL"`) |
| 9 | Function-valued own props | `@step =` closures (`MouseSensorWdgt.coffee:27`, `ScrollPanelWdgt.coffee:557,686`), patch nodes' `@functionFromCompiledCode` (recomputable from `@textWidget.text`, `CalculatingPatchNodeWdgt.coffee:140-145`), user-injected methods (with `<name>_source` sibling, `Widget.injectProperty` `Widget.coffee:2689-2697`) | `_source`-backed → re-inject on restore; declared-transient → drop & recompute; otherwise **error** |
| 10 | World-membership Sets | `steppingWdgts`, `keyboardEventsReceivers`, `widgetsReferencingOtherWidgets`, broken-rect arrays + ~15 more transient Sets (`WorldWdgt.coffee:175-181,214-231,253,318-320,373`) | recorded as per-widget membership flags at serialize time; re-registered at restore. Never serialized as data. |

Widgets reach the world via the ambient global `window.world` (`WorldWdgt.coffee:346`) — **no
widget stores a world pointer** (verified: no `@world` instance property anywhere), except that a
root widget's `parent` IS the world when it sits on the desktop.

There is **no wire/connector widget**: the connection system is exactly category 2 (directed
`target`+`action`), plus patch-programming pins (`FanoutWdgt` pins are in-subtree children that
are themselves controllers, `FanoutWdgt.coffee:7-31`; freshness tokens are plain numbers).
`Pin`/`PinType` (`ingoingLinks`/`outgoingLinks`) are dead legacy — nothing instantiates them.

### 2.6 World state beyond the widget tree (whole-snapshot inventory)

Classification: **(a)** rebuildable/derived — ignore; **(b)** in the widget tree anyway;
**(c)** genuine snapshot state.

- **(c) genuine**: `WorldWdgt.preferencesAndSettings` (class-static, `WorldWdgt.coffee:68,353`;
  a flat bag of primitives/Colors, DeepCopier-augmented — `PreferencesAndSettings.coffee`);
  `world.wallpaper.patternName` (`Wallpaper.coffee`); desktop `color`/`alpha` (`:362-365`);
  `world.isDevMode` (`:368`); `world.untitledNamingService` counters
  (`UntitledNamingService.coffee`); the `world.infoDoc_*_created` flags (8, set by apps);
  app-window slots `world.howToSaveDocWindow`/`sampleDashboardWindow`/`degreesConverterWindow`/
  `sampleDocWindow`/`sampleSlideWindow` (`IconicDesktopSystemWindowedApp.coffee:54` via
  `world[@slot]`; may hold **orphaned but revivable** windows — `:47` checks `parent?`);
  `world.simpleEditorTemplates`; per-class ID counters (§2.4) if identity must survive;
  **`world.basementWdgt` — OFF-TREE** (`WorldWdgt.coffee:236`, built at
  `globalFunctions.coffee:422`; its contents live under `@scrollPanel.contents.children`,
  `BasementWdgt.coffee:43,128`, NOT under `world.children` — a tree-rooted copy would miss it).
- **(a) transient** (must be *excluded*, several currently crash the walker): all broken-rects /
  highlight / pinout / popup / tooltip / momentum Sets and arrays; 7 × `LRUCache` (`:421-427`,
  hold `{}` hashes); `inputEventsQueue`; canvases/contexts; `DesktopAppearance.pattern/
  currentPattern` (a `CanvasPattern` — **the very first crash of a whole-world serialize**,
  spike-verified); error/report state; `hand`; `caret`; `lastEditedText`;
  `lastSerializationString`; event-listener fields (`:12-59`); Automator/MacroToolkit/macroVars
  (test-only, `if Automator?`-guarded, homepage-stripped).
- Boot facts a restore can lean on: `boot()` (`globalFunctions.coffee:86`) → class compilation →
  `startWorld` (`:387-440`) → `new WorldWdgt` → animloop → `menusHelper` → `basementWdgt` →
  `createDesktop` only `if isIndexPage` (`:427-428`; desktop contents built at
  `WorldWdgt.coffee:510-542`). The `?generatePreCompiled` image
  (`loading-and-compiling-coffeescript-sources.coffee:151-156`) is a **class-code image only** —
  it cannot carry instance state; a snapshot is orthogonal to it.

### 2.7 Source-edit machinery (for Phase 6)

Three tiers of source: shipped `window.Foo_coffeSource` strings; parsed
`Foo.class.nonStaticPropertiesSources` maps (`meta/Class.coffee:190-223`); and per-instance
`<method>_source` strings written by edits. Edit paths: instance-level
`Widget.injectProperty(propertyName, txt)` (`Widget.coffee:2689-2697` — `evaluateString` +
`@[name+"_source"] = txt`), driven by `InspectorWdgt.applyPropertyEdit`
(`meta/InspectorWdgt.coffee:634-655`); class-level `ClassInspectorWdgt.applyPropertyEdit`
(`meta/ClassInspectorWdgt.coffee:44-52` — evals against the prototype target, stores `_source` on
it, `notifyInstancesOfSourceChange` → `Class.coffee:435-445`). **No registry/diff of edits
exists**: neither `Foo_coffeSource` nor the parsed maps are written back; a class-level edit is
invisible to any text-level capture today. Per-instance `_source` strings DO ride the copier as
plain strings — but nothing re-`eval`s them on restore, and the live function object is dropped by
`JSON.stringify`.

### 2.8 File-I/O landscape + `file://` facts

- `src/` today contains **zero** `FileReader`/`Blob`/`createObjectURL`/`<a download>`/
  `input type=file`/`localStorage`/`indexedDB`/`fetch`/XHR. Everything loads via `<script>`-tag
  injection (`loadJSFilePromise`, `globalFunctions.coffee:42-63`) — which is *why* Fizzygum works
  over `file://`.
- The world's file-drop handler **exists but is empty** (`WorldWdgt.coffee:1858-1866` —
  `dragover` preventDefaults; `drop` does nothing).
- The only file-save code is in the test harness: FileSaver + JSZip
  (`Fizzygum-tests/Automator-and-test-harness-src/Automator.coffee:113-127`, Safari `data:` URL
  fallback at `:121-122`), vendored at `Fizzygum/auxiliary files/{FileSaver,JSZip}/`, loaded only
  when `BUILDFLAG_LOAD_TESTS` (`globalFunctions.coffee:283-285`) and **deleted from `--homepage`
  builds** (`build_it_please.sh:667-668`).
- The proven `file://` binary-load workaround is the SWCanvas atlas trick: wrap the binary as a
  `.js` file and inject a `<script>` (`SWCanvasElement-extensions.coffee:108-141`).
- **Spike-proven** (headless Chrome over `file://`, see Appendix A): `saveAs(new Blob(...))`
  download works and is byte-exact (captured via CDP `Browser.setDownloadBehavior`);
  `FileReader`+`input type=file`/drag-drop file ingestion is standard-supported over `file://`
  (upload side to be covered by the Phase 4 rig with in-page `new File(...)`).
- The headless harness has no download/upload plumbing today; it extracts data via
  `page.evaluate` return values (`run-macro-test-headless.js:176-185,309-345`) — the natural
  channel for round-trip tests too.

---

## §3 Empirical defect catalog of the prototype (all spike-verified on build `040330e6`)

Spike method: headless Puppeteer boot of `Fizzygum-builds/latest/index.html` (native backend),
programmatic widget construction, `serialize()`/`world.deserialize()` round-trips, pixel region
compares, fresh-page cross-session restore. Scripts summarized in Appendix A.

| ID | Defect | Evidence | Root cause |
|---|---|---|---|
| D1 | Fragile envelope: JSON objects joined by `//` comment lines, split by regex; per-object `console.log` spam + `debugger` statements in the hot path | code read | `Widget.coffee:2588-2602, 2608-2614, 2666` |
| D2 | **Silent data corruption**: any user string *starting with* `$` is treated as a reference on restore | `'$2 bill'` → restored `text` became a random object (empty string render) | in-band string tokens; `Widget.coffee:2666-2679` |
| D3 | **External pointers silently become `undefined`**: `"$EXTERNAL…"` → `parseInt("EXTERNAL…")` → `NaN` → `clonedWidgets[NaN]` | button with `target = world`: restored `target` is `undefined`; nothing ever resolves `$EXTERNAL` (whole-src grep) | `DeepCopierMixin.coffee:30,159` emitted, never parsed |
| D4 | **`Date` kills deserialization entirely** | `AnalogClockWdgt` (has `dateLastTicked`): `THROW Cannot read properties of undefined (reading 'prototype')` | `Date-extensions.coffee:18` pushes a raw `Date` → stringifies to a bare ISO string → no `className` |
| D5 | **All colors lost** → restored widgets render black / with stale styles | restored `Color` own-keys = `[className, compactSerialisedForm]`, `_r/_g/_b` = nil; window round-trip pixel diff 40 293/360 000 bytes; screenshots: black title bar, missing label; cross-session restore fully black | `Color.coffee:255-262` emits compact form; `deserialize` never expands it |
| D6 | **Serialization has side effects**: every serialize advances real per-class ID counters and registers phantom shells in `Class.instances` (leak: +1 per widget per serialize); output is therefore also non-deterministic (two consecutive `serialize()` of the same widget differ in every `instanceNumericID`) | spike: `RectangleWdgt.instances.size` 1→2 after one serialize; line-diff of back-to-back serializations shows only `instanceNumericID` fields changed | `DeepCopierMixin.coffee:192,201-202` runs `registerThisInstance`/`assignUniqueID` on serialize shells; shells are never unregistered |
| D7 | **Restore doesn't re-register anything**: restored widgets are missing from `Class.instances` (class-edit notification + basement GC blind to them), from `world.steppingWdgts` (a restored clock would never tick), `keyboardEventsReceivers`, `widgetsReferencingOtherWidgets` | code read + D4 blocking the clock case | `Widget.deserialize` never calls `registerThisInstance`; the four `alignCopiedWidgetTo*` hooks run only on the dup path (`DeepCopierMixin.coffee:54-56` early return) |
| D8 | **No `{}` / `Map` / `Set` support** — walker throws (after a stray `debugger`) on any own plain-object/Map/Set property | whole-world serialize dies immediately: `this[property].deepCopy is not a function` on `DesktopAppearance.pattern` (CanvasPattern); next in line: LRUCaches (`{}` hash), `ActivePointerWdgt.mouseOverList` (Set), world Sets | `DeepCopierMixin.coffee:162-167`; no Object/Map/Set handlers exist (`boot/extensions/` inventoried) |
| D9 | **Function-valued own properties silently dropped** by `JSON.stringify` (user-injected methods survive only as `_source` strings that are never re-injected; `@step` momentum closures vanish silently) | code read; §2.5 cat. 9 | serializer has no function policy; no restore-time re-injection |
| D10 | **Derived values never rebuilt on restore**: `rebuildDerivedValues` runs only on the dup path; SWCanvas image decode is async with no readiness signal (`Widget.coffee:2630-2645` comment admits the race) | code read | `DeepCopierMixin.coffee:54-58` |
| D11 | Restored `parent` dangles (D3 makes it `undefined`, but semantically the root's parent should never be serialized at all); attach is implicit | spike: works only because the menu action immediately `world.add`s | design gap |
| D12 | **Video serialize crashes + wrong class tag**: emits `className:"Canvas"` and throws `cloneOfMe.video is undefined` | code read (verified) | `HTMLVideoElement-extensions.coffee:33-35` |
| D13 | **No error story**: failures are `debugger` statements, console spam, `alert` (in `widgetFromUniqueIDString`), or silent `undefined`s | all spikes | throughout |

**What already works** (spike-verified, keep): structural round-trip of leaf and composite widgets
(window + 6 chrome children, slider with its button child, label text) **including into a fresh
browser session**; canvas → dataURL → canvas; the shared-object/cycle table (`$N` back-refs);
per-class shells without constructor re-run; `saveAs` Blob download over `file://` byte-exact.

---

## §4 Design

### 4.1 Format: one versioned JSON envelope

Replace the JSON-lines-with-comments format (D1) with a single JSON document:

```json
{
  "format": "fizzygum",
  "formatVersion": 1,
  "kind": "widget",                  // or "world"
  "savedAt": "2026-07-04T12:00:00Z", // informational
  "build": "<content of .build-stamp / git short hash if available>",
  "root": 0,                         // index into objects
  "objects": [
    { "class": "WindowWdgt", "iid": 1, "memberships": [],
      "props": { "labelContent": "my window",
                 "parent": null,
                 "children": {"$r": 3},
                 "color": {"$r": 7}, ... } },
    ...
    { "class": "$Array", "items": [ {"$r": 4}, {"$r": 5} ] },
    { "class": "Color",  "rgba": [248, 248, 248, 1] },
    { "class": "$Date",  "ms": 1783122262571 },
    { "class": "$Canvas","w": 300, "h": 200, "data": "data:image/png;base64,..." },
    { "class": "$Image", "src": "data:..." },
    { "class": "$Video", "src": "...", "autoplay": false, "currentTime": 0 },
    { "class": "$Object","props": { ... } },
    { "class": "$Map",   "entries": [ [k, v], ... ] },
    { "class": "$Set",   "items": [ ... ] }
  ],
  "world": { ... }                   // kind:"world" only — see §4.9
}
```

- **Every non-primitive gets a table slot** (as today), so shared structure and cycles keep
  working uniformly (e.g. the shared `buttons` array observed in `SwitchButtonWdgt`).
- **References are structured values, never in-band strings** (fixes D2): `{"$r": n}` internal,
  `{"$wk": "<key>"}` well-known (§4.2), `{"$src": "<coffee>"}` for `_source`-backed functions
  (§4.3). Plain user strings need no escaping; a plain `{}` **value** is encoded as a table slot
  (`$Object`), so `props` values that are JSON objects are always exactly one of the three `$`
  forms — unambiguous by construction.
- `iid` records the original `instanceNumericID` (informational for `kind:"widget"`; restored for
  `kind:"world"`, §4.9). `memberships` records world-set membership at serialize time (§4.5).
- Native types get `$`-prefixed class tags (user classes can never collide — class names are
  CoffeeScript identifiers). This absorbs and fixes the Date/Video handlers (D4, D12).
- `Color` keeps its compact form, renamed into an explicit record — restored **through the Color
  factory** (`Color.create`) so immutable dedupe is preserved (fixes D5).
- Output is deterministic given identical world state (no counters touched — §4.4); a
  `prettyPrint` option indents for humans/diffs.

### 4.2 Reference policy (the heart of the user brief)

At serialize time each encountered object is classified, in order:

1. **In-structure** (widget in `allWidgetsInStructure`, or any non-widget reached by the walk) →
   table slot, `{"$r": n}`.
2. **Well-known** → `{"$wk": key}`. New registry `src/serialization/WellKnownObjects.coffee`:
   a two-way map `key ⇄ live object`, populated at world boot. Initial keys: `world`, `hand`,
   `wallpaper`, `widgetFactory`, `basement`, `preferences`, `app:<ClassName>` for each
   `IconicDesktopSystemWindowedApp` subclass singleton. Mechanically: these objects get a
   `wellKnownKey` property next to (eventually replacing) `keptByReferenceOnDeepCopy`; the
   registry resolves keys on restore against the *current* world, lazily creating app singletons
   the way `createOpener`/`launch` do. This upgrades today's information-destroying bare
   `"$EXTERNAL"` into a reconstructable symbolic link — exactly the "known data structures that
   exist in all worlds" requirement.
3. **Root's `parent`** → `null` (fixes D11). Deserialization returns a *detached* widget; the
   caller (menu action / drop handler / snapshot loader) decides where to attach.
4. **Anything else** → **throw `SerializationError`** (new, `src/serialization/`), carrying:
   - the serialization root (`"WindowWdgt#1"`),
   - the full property path to the offending reference (the walker threads a path stack:
     `"WindowWdgt#1 → .contents (SliderWdgt#5) → .target"`),
   - the offending object (`"StringWdgt#9, which is outside the serialized structure and not a
     well-known object"`),
   - remediation hints ("serialize a common container holding both widgets; or clear the
     connection; or register the object as well-known").
   Menu/file actions catch it and `world.inform` the message (D13). An options bag
   `onExternalPointer: "throw" (default) | "nullify" | "record"` supports tolerant callers
   (`"record"` emits `{"$ext": "SliderWdgt#5"}` for same-world re-linking — used internally by
   the world snapshot, where a second pass can resolve it since *everything* is in-structure;
   surfaced to users only later if ever needed).

Transient pointer categories (§2.5 rows 5, 7, 10) never reach this classification because the
fields are declared transient (§4.3) — so a caret mid-edit or a hovered tooltip can't fail a save.

### 4.3 Transients, derived values, and functions

New per-class protocol, additive and inherited (merged up the chain, like the existing
class-body conventions):

```coffee
class Widget extends TreeNode
  @serializationTransients: ["lastTime", "destroyed", ...]   # skipped at serialize; restore leaves
                                                             # the prototype default / ctor-less nil
```

- **Derived values** keep the existing `rebuildDerivedValue` protocol (contexts) — the serializer
  skips them exactly like the dup path does (`DeepCopierMixin.coffee:147-148`), and the
  deserializer *runs* `rebuildDerivedValues` (fixes half of D10).
- **Functions** (fixes D9): for an own function-valued property `foo`,
  - if `foo_source` exists (user-injected method) → serialize `{"$src": <source>}` under `foo`
    (and the `foo_source` string rides along as a normal string); restore compiles it via the
    existing `evaluateString`/`injectProperty` machinery (`Widget.coffee:2689-2697`).
  - else if `foo` is listed in `serializationTransients` → dropped, class recomputes (e.g. patch
    nodes recompute `functionFromCompiledCode` from `@textWidget.text` on first use — already
    their behaviour; scroll-momentum `@step` closures simply stop, which is correct for a settled
    restore).
  - else → `SerializationError` with the property path (never a silent drop again).
- Seed transients list (initial sweep, grown during Phase 2 testing): `Widget.lastTime`;
  bounds/visibility cache fields (the Tier-J `checkFullBoundsCache` family — geometry re-derives);
  `DesktopAppearance.pattern`/`currentPattern`; `ScrollPanelWdgt.@step` (when own);
  patch nodes' `functionFromCompiledCode`; `RasterImageWdgt` onload bookkeeping;
  `WorldWdgt`'s ~25 transient Sets/arrays/caches/queues/listener fields (§2.6a — world-kind only).

### 4.4 Side-effect-free serialization; identity across modes

Fixes D6: the serializer **builds records directly** — it creates no shells at all, so nothing to
`registerThisInstance`/`assignUniqueID`, no counter drift, no `Class.instances` leak, and the
output becomes deterministic. `iid` in each record carries the *original's* ID.

On restore (§4.5): `kind:"widget"` assigns **fresh** IDs (like duplication — the restored widget
coexists with live widgets; collisions must be impossible); `kind:"world"` **restores** `iid` and
the per-class counters (the world was reset first, so the ID space is empty — §4.9).

### 4.5 Deserializer architecture

New `src/serialization/Deserializer.coffee` (the `Widget.deserialize`/`world.deserialize` name is
kept as a thin delegate). Five passes over the envelope:

1. **Instantiate**: for each record, `Object.create window[record.class].prototype` (constructor
   NOT run — the established, SliderWdgt-guarded convention), or the native factory for `$`-types
   (`$Canvas` → `HTMLCanvasElement.createOfPhysicalDimensions` / SWCanvas variant, `$Date` →
   `new Date(ms)`, `$Map`/`$Set`/`$Object`/`$Array` → empties). Unknown class name → rich error
   ("this snapshot references class X which does not exist in this build").
2. **Populate & link**: walk `props`/`items`/`entries` recursively, resolving `{"$r"}` /
   `{"$wk"}` / `{"$src"}` / `{"$ext"}` forms at **any nesting depth** (the old patcher only
   handled top-level props and flat arrays). Colors via `Color.create` dedupe.
3. **Identity & registration** (fixes D6/D7 asymmetries): per §4.4 assign or restore IDs; call
   `registerThisInstance()` on every widget.
4. **Fixups**: run `rebuildDerivedValues`; compile `$src` functions; decode async assets
   collecting per-asset promises (Image/Canvas/Video `onload`) into a single **`whenReady`
   promise** (fixes the SWCanvas decode race, D10 — macro tests await it; native path resolves
   immediately); re-register `memberships` (`stepping` → `world.steppingWdgts.add`,
   `referenceTracker` → `world.widgetsReferencingOtherWidgets.add`, …) — this replaces the
   dup-only `alignCopiedWidgetTo*` knowledge with recorded facts, so a **fresh session** (where
   the original is absent) restores them correctly; finally call the per-class hook
   `_afterDeserialization?()` (new, optional — absorbs the SliderWdgt-style guards).
5. **Deliver**: return `{ widget, whenReady }` detached; callers attach
   (`world.add w; w.rememberFractionalSituationInHoldingPanel()` — same as
   `duplicateMenuAction`, `Widget.coffee:2537-2542`) and the normal settle/repaint machinery does
   the rest.

### 4.6 Relationship to duplication: share knowledge, not the walker

Decision: **split the modes**. `DeepCopierMixin` keeps `doSerialize=false` exactly (duplication is
pixel-load-bearing across the SystemTest suite); its `doSerialize=true` branches are deleted once
the new pair lands (the flag parameter stays until then, then the signature simplifies —
mechanical sweep of the 7 `deepCopy` implementations). What IS shared, per the reuse preference:

- the per-class **knowledge**: `serializationTransients`, `wellKnownKey` (both consulted by dup
  too — dup keeps live references for well-knowns as today), `rebuildDerivedValue(s)`, the
  native-type handlers' *logic* (the new `$`-type encoders are written once and the dup-mode
  bodies of `Image/Canvas/Video/Date-extensions` keep delegating to their existing clone code);
- the traversal *contract* (own-props, cycle table, external-widget test against
  `allWidgetsInStructure`) — documented in one place, a **new dedicated reference doc
  `docs/architecture/serialization-duplication-reference.md`** covering serialization, deserialization AND
  duplication (format spec, traversal contract, per-class protocol, per-type handlers) — so the
  two walkers can't drift silently. Per owner direction (2026-07-04), **CLAUDE.md files only
  LINK to this doc, never carry the content**: one link line added to `Fizzygum/CLAUDE.md`, plus
  a link-only `src/serialization/CLAUDE.md` for the subdirectory-depth convention.

Rationale over "one walker, two emitters": the dup walker interleaves clone construction with
traversal order in ways the SystemTests bake into pixels; a record-building serializer shares no
mutable state with it, so neither can regress the other. (If review prefers full unification,
Phase 1 is the place to raise it — the plan keeps that door open but doesn't gamble the gauntlet
on it.)

`DUPLICATED_CODE_IN_DEEPCOPY` cleanup (the 7 copy-pasted cycle-table preambles) is folded into the
Phase 2/3 sweep of those files — dup-path-only after the split, one helper, zero behaviour change.

### 4.7 Errors & UX

- `SerializationError` (name, message, `path`, `rootDescription`, `offender`) — §4.2.
- All `debugger`/`console.log`/`alert` leftovers in the ser/deser path removed (D1/D13).
- Menu actions (`serialiseToMemory` etc. + the new file actions) catch and `world.inform` a
  human-readable multi-line message; headless rigs assert on the structured fields.

### 4.8 File save/load over `file://`

**Save** — new `src/serialization/FileSaving.coffee`:
`saveStringAsFile(string, suggestedName, mimeType)` = `Blob` → `URL.createObjectURL` → synthetic
`<a download>` click → revoke; Safari fallback via `data:` URL navigation (mirroring
`Automator.coffee:121-122`). ~30 lines, no dependency on the dev-only vendored FileSaver, **ships
in all builds including `--homepage`** (this is a product feature; do NOT wrap it in
homepage-strip markers). Spike-proven byte-exact over `file://` headless.

**Load** — new `src/serialization/FileLoading.coffee` + wiring:
- **Drag-and-drop**: implement the currently-empty `dropBrowserEventListener`
  (`WorldWdgt.coffee:1862-1866`): `event.dataTransfer.files` → `FileReader.readAsText` → envelope
  sniff (`format`/`kind`) → widget: deserialize + attach at drop point; world: confirm dialog then
  snapshot load. Non-Fizzygum files rejected with an inform (image-file ingestion is a natural
  future extension, banked).
- **Menu path**: a hidden `<input type=file accept=".json">` created on demand,
  `.click()` from "open from file…" (user-gesture-driven, `file://`-safe).
- File naming (owner-decided, §8.3): a **single extension `*.fzw.json` for both widget and world
  files** — plain JSON inside; the loader routes on the envelope's `kind` field, never on the
  filename. Suggested names: widgets `<colloquialName>.fzw.json`, worlds
  `world-<name>.fzw.json`.

**`file://` capability map** (documented in the code): works — Blob download, `input type=file`,
drag-drop + FileReader, `data:` URLs, script-tag injection (the atlas trick — available later for
"boot straight into a snapshot" .js-wrapped images, banked §5.8); does NOT work — `fetch`/XHR of
local files (never used), and the File System Access API pickers are Chrome-only/insecure-context
-quirky (banked; not core).

**Headless testability** (all spike-proven or standard):
downloads via CDP `Browser.setDownloadBehavior` → tmp dir → byte-compare; uploads by constructing
`new File([json], name)` **in-page** and dispatching a synthetic `drop` with a `DataTransfer`, or
`ElementHandle.uploadFile` on the hidden input. New harness helper in the Phase 4 rig.

### 4.9 Whole-world snapshot (`kind: "world"`)

**Serialize** — `WorldWdgt.serializeWorldSnapshot()`:
- `allWidgetsInStructure` = union of the **snapshot roots**: `world` subtree,
  `world.basementWdgt` subtree, each non-nil app-slot window (orphans included), each
  `world.hand`-held… no — the hand is transient; anything actually *held* is dropped (settled-
  world rule, §1). Cross-root pointers thus resolve as `$r` normally; stragglers use
  `onExternalPointer:"record"` + a resolution pass (§4.2).
- The world record itself is a normal table entry (class `WorldWdgt`) with the §4.3 world
  transients excluded; `world.children` etc. serialize normally.
- Envelope `world` section (outside the object table — plain, greppable):
  `preferences` (serialized `PreferencesAndSettings`), `wallpaperPatternName`,
  `desktopColor`/`alpha`, `isDevMode`, `infoDocFlags`, `untitledNamingCounters`,
  `simpleEditorTemplates`, `appSlots: {slotName: {"$r": n}}`, `basement: {"$r": n}`,
  `idCounters: {ClassName: lastBuiltInstanceNumericID}`, `sourceEdits` (Phase 6).
- Widget records carry `iid` + `memberships` as always.

**Restore** — `WorldWdgt.loadWorldSnapshot(envelopeString)`:
1. Confirm dialog (destructive + code-execution warning, §4.12).
2. Tear down: existing `fullDestroyChildren` (`WorldWdgt.coffee:1990-2013`, which also zeroes all
   per-class ID counters) + empty basement + nil app slots — the reset machinery already exists
   for the test harness (`_resetWorldNoSettle`, `:1946-1974`).
3. Restore `idCounters`, then deserialize the graph with **preserved `iid`** (empty ID space →
   no collisions; `uniqueIDString`-based references and user expectations survive).
4. Re-link: world sections (preferences → `WorldWdgt.preferencesAndSettings`, wallpaper pattern,
   desktop color, flags, naming counters, app slots, basement), memberships, `whenReady`, settle
   (`_settleLayoutsAfter` batch), full repaint.
- **The old `world.serialize()` becomes an explicit error** pointing at
  `serializeWorldSnapshot` (a world is not a widget subtree; D8's crash becomes a guided path).

### 4.10 Source-edit capture (Phase 6; the "could go very deep" part, staged)

- New `src/serialization/SourceEditsRegistry.coffee`, instance at `world.sourceEditsRegistry`.
  Record shape: `{scope: "instance"|"class", className, uniqueID?, propertyName, source, when}`.
- Hooked at the two edit choke points: `Widget.injectProperty` (`Widget.coffee:2689`) and
  `ClassInspectorWdgt.applyPropertyEdit` (`ClassInspectorWdgt.coffee:44`). (Instance-level edits
  are *also* already self-carrying via `_source` + §4.3 `$src`; the registry's marginal value at
  instance scope is auditability — its essential value is **class scope**, which is otherwise
  unrecorded, §2.7.)
- Snapshot embeds the registry; restore replays **class-scope edits before pass 1** (so
  prototypes are correct when shells are created) and lets instance-scope edits ride the normal
  `$src` mechanism.
- Staged extensions (banked): whole-class source replacement, classes *defined* in-world,
  exporting edits as a `.coffee` patch, baking edits into a `?generatePreCompiled` image.

### 4.11 Versioning & compatibility stance

`formatVersion: 1` + `build` stamp. Loader: hard error on unknown `format`/major version;
warn-and-proceed on build mismatch (snapshots are expected to be loaded by the same or a newer
build; per-class migration hooks are a designed-but-unbuilt extension point: a class may later
declare `@migrateSerializedRecord(record, fromVersion)`). The old prototype string format gets
**no loader** (it was dev-only, untested, and corrupts data — §8.2 confirms deletion).

### 4.12 Security stance

A Fizzygum file/world snapshot can carry code (`$src`, source edits) that runs on load — inherent
to serializing a live programming environment. Policy: loading from file always shows a
confirmation naming the file and warning that it can execute code; in-memory round-trips don't
prompt. No sandboxing attempted (out of scope; the whole world is user-programmable by design).

---

## §5 Phased execution

Standing rules for every phase: edit only `Fizzygum/src/**` (+ tests repo); verify with
`fg build` / `fg suite` (dpr 1) per iteration and `fg gauntlet` before calling a phase done;
never hand-edit `Fizzygum-builds`; new classes are one-per-file, named-as-file, referenced with
literal `new X`/`extends X` so `dependencies-finding.coffee` sees them; product code carries NO
homepage-strip markers (test-menu items keep theirs). Commits only after owner review at the end
of the arc (one review per the long-arc workflow), messages proposed per phase.

### Phase 0 — Characterization rig (tests repo only; no framework changes)

- **New** `Fizzygum-tests/scripts/serialization-roundtrip-headless.js` (modeled on
  `smoke-boot-headless.js`; productizes the session spikes): boots the build, runs a fixture
  battery — leaf `RectangleWdgt`; `StringWdgt('$2 bill')`; `WindowWdgt` composite;
  connected pair (a `PanelWdgt` holding a `SliderWdgt` whose `target`/`action` is a sibling
  `StringWdgt` — the ControllerMixin wire); `AnalogClockWdgt` (Date + stepping);
  `SimpleButtonWdgt(true, world, 'inform', …)` (well-known external); canvas-bearing widget.
  For each: `fullCopy` baseline, serialize, same-page restore, **fresh-page restore**, pixel
  region compare, and side-effect assertions (class counters unchanged, `instances.size`
  unchanged, back-to-back serializations byte-identical). Runs native + `?sw=1`. Exit ≠ 0 on any
  regression against an **expectations table** committed with the script (initially: the D-table
  of §3 as expected-fails; flipped green through Phases 2-3).
- `package.json` script `test:serialization`.
- **Exit gate**: rig runs on the current build reproducing §3's findings exactly.

### Phase 1 — Scaffolding (framework, behaviour-neutral)

- **New** `src/serialization/` classes: `SerializationError` (fields per §4.7),
  `WellKnownObjects` (registry; world boot populates it in `startWorld`/WorldWdgt ctor;
  `wellKnownKey` property added to `Wallpaper`, `WidgetFactory`,
  `IconicDesktopSystemWindowedApp` + `world`/`hand`/`basement`/`preferences` registrations),
  plus the dedicated reference doc `docs/architecture/serialization-duplication-reference.md` (§4.6) and its
  link lines (one in `Fizzygum/CLAUDE.md`; a link-only `src/serialization/CLAUDE.md`). The
  reference doc starts life documenting the EXISTING duplication engine + protocol (§2.1-2.2)
  and grows with each phase.
- `@serializationTransients` protocol: reader helper (merged-up-the-chain) + seed declarations
  (§4.3 list) — inert until Phase 2 consumes it.
- **Exit gate**: `fg gauntlet` green (nothing consumes the new code yet); boot-smoke green.

### Phase 2 — The new Serializer

- **New** `src/serialization/Serializer.coffee`: `Serializer.serializeWidget(root, opts)` →
  envelope string per §4.1-§4.4 (path-tracked walk, `$`-type encoders incl. fixed Date/Video,
  transients, function policy, well-known/external classification, deterministic output,
  `prettyPrint` opt).
- Rewire `Widget.serialize` (`Widget.coffee:2588`) to delegate; **delete** the old body, the
  `doSerialize=true` branches across `DeepCopierMixin` + the 7 extension files (dup signature
  cleanup + `DUPLICATED_CODE_IN_DEEPCOPY` consolidation ride along), and the dead
  `prepareBeforeSerialization`/`serializerVersion` trio (`Point/Rectangle/Color`).
- **Exit gate**: rig — serializer half of the battery green (valid envelopes, zero side effects,
  determinism, error-path test produces the §4.2 message with correct path);
  `fg gauntlet` green (duplication pixels untouched).

### Phase 3 — The new Deserializer + in-memory round-trip green

- **New** `src/serialization/Deserializer.coffee` (5 passes, `whenReady`, memberships,
  `_afterDeserialization` hook; SliderWdgt guards migrate into its hook), `world.deserialize`
  delegates; test-menu items (`Widget.coffee:3210-3219`) unchanged in UX, now lossless.
- `memberships` emission added to the Serializer (consults the live world sets at serialize
  time: `stepping`, `keyboardReceivers`, `referenceTracker`, `brokenInfo`).
- **New macro SystemTests** (authored via `/author-macro-test`, SWCanvas refs at dpr 1+2):
  `SystemTest_macroSerializeRoundTripWindow` (build window+slider+text via menus, serialize to
  memory, destroy original, deserialize+attach, screenshot parity),
  `SystemTest_macroSerializeConnectedControllers` (restored slider still drives its sibling
  target), `SystemTest_macroSerializeExternalPointerError` (friendly dialog screenshot),
  `SystemTest_macroSerializeClock` (restored clock ticks — stepping membership; uses the
  deterministic `WorldWdgt.dateOfCurrentCycleStart` clock).
- **Exit gate**: whole rig green including cross-session + pixel parity + `$`-string fidelity;
  `fg gauntlet` green; new macros pass at dpr 1+2 + webkit.

### Phase 4 — File save/load over `file://`

- **New** `FileSaving.coffee` / `FileLoading.coffee` (§4.8); implement
  `dropBrowserEventListener`; menu items: widget context menu "save to file…" (next to
  "duplicate"), desktop/world menu "open from file…"; envelope sniffing router.
- **New** rig extension `Fizzygum-tests/scripts/serialization-file-roundtrip-headless.js` (or a
  flag on the Phase 0 rig): CDP download capture → byte compare → re-ingest via in-page
  `new File` + synthetic drop → pixel parity. Chrome + WebKit legs (WebKit via the
  `headless-driver.js` adapter; skip download-capture there if Playwright's API differs —
  document).
- **Exit gate**: headless file round-trip green both backends; manual sanity in a real browser
  over `file://` (Chrome + Safari, Safari using the `data:` fallback).

### Phase 5 — Whole-world snapshot

- `WorldWdgt.serializeWorldSnapshot` / `loadWorldSnapshot` per §4.9 (+ the guided error on
  `world.serialize()`); world transients seeding completed; ID-counter restore; menu items
  "save world snapshot… / load world snapshot…".
- Tests: rig gains a world leg — default desktop round-trip into a fresh page (pixel compare vs
  a directly-booted desktop, clock region masked), populated-world round-trip (docs window +
  basement content + moved icons + wallpaper change + preference change), dpr 2 + webkit legs.
  A macro SystemTest for the in-world UX (`SystemTest_macroWorldSnapshotSaveLoad`) if the reset
  interaction proves macro-stable (the suite's `resetWorld` machinery is adjacent — reuse its
  patterns; see the settle-tier teardown gotcha in `settle-tier-teardown-flip` lore before
  looping teardown in a macro).
- **Exit gate**: rig world-leg green; `fg gauntlet` green.

### Phase 6 — Source-edit capture

- `SourceEditsRegistry` + hooks (§4.10); snapshot embed + replay ordering; load-time
  confirmation copy notes code execution (§4.12).
- Tests: rig leg — inject a method edit (`injectProperty`) on a widget, class-scope edit via
  `ClassInspectorWdgt.applyPropertyEdit` on a toy class, snapshot, fresh-session restore, assert
  edited behaviour (evaluate) + a macro test for the inspector-driven flow.
- **Exit gate**: rig green; gauntlet green; arc-end review package (summary + proposed commit
  messages for both repos) presented to owner.

### 5.8 Banked extensions (explicitly out of this arc)

Boot-from-snapshot `.js` wrapper (script-tag world image, atlas-trick precedent); image-file
drag-ingestion on the new drop handler; `localStorage` autosave; File System Access API pickers;
snapshot compression (JSZip is already vendored) and binary canvas payload dedup; per-class
format migrations; class-prototype `$wk` targets for inspectors; exporting source edits as
`.coffee` patches; baking edits into `pre-compiled.js`; a serialization **oracle sweep** (open
every app headless via `smoke-apps-headless.js` patterns, serialize+restore every top-level
widget, require no-throw + pixel parity — the J3 cache-oracle-style ratchet, valuable once
Phases 0-5 stabilize).

---

## §6 Risks & mitigations

1. **Duplication pixel regressions** while touching `DeepCopierMixin`/extensions — mitigation:
   mode split (§4.6), all dup-path edits mechanical, `fg gauntlet` per phase; benign inspector
   member-list recaptures are acceptable per standing owner policy.
2. **Long tail of ~470 classes** with odd own-props (closures, DOM refs) surfacing as
   `SerializationError`s — mitigation: errors are *the designed behaviour* (loud, pathful, fixed
   by adding a transient/`$wk`/handler); the banked oracle sweep systematizes discovery.
3. **SWCanvas async decode vs deterministic screenshots** — mitigation: `whenReady` (§4.5);
   macros await it; DETERMINISM.md rules apply (no wall-clock waits).
4. **World-restore interacting with the settle/layout machinery** (the historical minefield) —
   mitigation: restore builds a detached tree, attaches through the same public paths as
   duplication (`world.add` + settle batch), never calls layout cores directly.
5. **ID-collision subtleties** in `kind:"widget"` restores — mitigation: always-fresh IDs there;
   `iid` only informational; world-kind restores into a zeroed ID space and asserts emptiness.
6. **Snapshot size** (canvas dataURLs dominate; a fresh world serialized ≈ 60 widgets, trivial;
   drawing-heavy worlds grow) — acceptable for v1; compression banked.
7. **Format lock-in** — `formatVersion` + migration extension point (§4.11); format documented in
   `docs/architecture/serialization-duplication-reference.md`.

## §7 Effort shape (for scheduling, not commitments)

Phases 0-1 small; Phase 2 and 3 are the bulk (new engine + long-tail transient seeding);
Phase 4 small (spike-proven); Phase 5 medium (world sections + reset interaction); Phase 6 small
once 5 lands. Each phase is independently landable and reviewable; the arc follows the
run-straight-through-verify, one-end-of-arc-review convention.

## §8 Decisions (owner-resolved 2026-07-04 — do NOT re-open during execution)

1. **Ship serialization in `--homepage` production builds: YES.** Only the test-menu entries
   stay dev-only/homepage-stripped; all Phases 2-6 product code ships with NO strip markers.
2. **Delete the old prototype format with no back-compat loader: YES** (it was dev-only,
   corrupting, untested).
3. **File naming: single extension `*.fzw.json`** for both widget and world files; the loader
   routes on the envelope `kind` field (§4.8).
4. **Phase order confirmed**: file I/O (Phase 4) before world snapshot (Phase 5).
5. **`kind:"widget"` restores assign fresh IDs**: a restored widget's `#n` differing from the
   saved one is accepted (matches duplication semantics).
6. **Documentation placement** (feedback 2026-07-04): all ser/deser/duplication documentation
   lives in ONE dedicated reference doc, `docs/architecture/serialization-duplication-reference.md`;
   CLAUDE.md files only link to it (§4.6).

## §9 LANDED-STATUS

- **Phase 0 — Characterization rig — LANDED 2026-07-04 (tests repo only; not yet committed).**
  New `Fizzygum-tests/scripts/serialization-roundtrip-headless.js` + npm scripts
  `test:serialization` / `test:serialization:sw`. Boots the built world headless (native +
  SWCanvas `?sw=1`), builds the fixture battery (leaf `RectangleWdgt`; `StringWdgt('$2 bill')`;
  `WindowWdgt` composite; in-structure controller pair = `PanelWdgt` + `SimpleButtonWdgt`
  whose `target`/`action` is a sibling `StringWdgt` — a ControllerMixin/ButtonWdgt category-2
  wire, used in place of the plan's SliderWdgt for robustness, same reference-resolution path;
  `AnalogClockWdgt`; external-pointer button `target=world`; canvas-bearing widget), and for
  each runs fullCopy baseline + serialize + same-page restore + **fresh-page** restore +
  SWCanvas pixel-region parity + side-effect assertions. Verdict is driven by an EXPECTATIONS
  table keyed per check (`desirable` = "behaves as the finished system should"); the §3 D-table
  is encoded as expected-fails, flipped green through Phases 2-3.
  - **Gate — MET.** On the unmodified build `040330e6` the rig is green (exit 0, all
    expectations met) and reproduces §3 exactly: D2 `'$2 bill'`→`[]`; D3 `target=world`→nil;
    D4 clock deserialize throws `reading 'prototype'`; D5 `color._r=undefined` + window pixel
    divergence **same-page AND cross-session** (restored render is deterministically black,
    hash `1083582248` vs orig `2689043898`); D6 `RectangleWdgt.instances` 5→6 (phantom-shell
    leak) + back-to-back serialize non-identical; D8 `world.serialize()` throws
    `this[property].deepCopy is not a function`. Positives confirmed working: leaf/composite
    structural round-trip (window 6/6 children), in-structure controller ref resolves, canvas
    round-trip, cross-session structural restore.
  - Framework-neutral phase: no `Fizzygum/src/**` or `Fizzygum-tests/tests/**` (suite) change,
    so `fg gauntlet` has nothing new to exercise; the rig is Phase 0's gate. Baseline HEAD
    `040330e6`/`7f79c508d` is verified-green per the J6 arc.
- **Phase 1 — Scaffolding (framework, behaviour-neutral) — LANDED 2026-07-04 (not yet committed).**
  New `src/serialization/`: `SerializationError.coffee` (plain class — NOT `extends Error`,
  which would inject a phantom `"Error"` into the dependency finder's load order via
  `goodMatch`; carries `name`/`message`/`rootDescription`/`path`/`offender`/`remediation` +
  best-effort `.stack` + multi-line `toString`), `WellKnownObjects.coffee` (LAZY two-way
  registry — resolves keys against the live `world` on demand, not a boot-time snapshot;
  boot-order-safe and correct for cross-session restore; app resolution stubbed for Phase 5),
  `Serializer.coffee` (created one phase early as the natural home for the format constants +
  the `@serializationTransients` merged-up-the-chain reader `transientsForClass`; the
  `serializeWidget` engine is still Phase 2 — the file is inert), `CLAUDE.md` (link-only).
  New content-bearing doc `docs/architecture/serialization-duplication-reference.md` (documents the existing
  engine + the full design with [LIVE]/[Ph N] status markers; grows each phase). Link line added
  to `Fizzygum/CLAUDE.md` (Architecture/Mixins bullet). `wellKnownKey` markers added to
  `Wallpaper` ("wallpaper"), `WidgetFactory` ("widgetFactory"), `IconicDesktopSystemWindowedApp`
  (method → "app:"+ClassName). `@serializationTransients` seeds on `Widget` (lastTime + the
  geometry-cache family) and `DesktopAppearance` (pattern/currentPattern). All new code is inert
  (nothing consumes it yet).
  - **Design refinement vs plan (recorded):** `WellKnownObjects` is **lazy**, not eagerly
    populated at boot as §4.2 first framed it — smaller, boot-order-safe, and MORE correct for
    cross-session restore (binds keys to the destination world). Consistent with §4's design.
    `SerializationError` is a plain class, not `extends Error` (dependency-finder reason above).
    `Serializer.coffee` created in Phase 1 (utility only) rather than Phase 2.
  - **Gate — MET.** `fg build` 0 violations; boot-smoke native+SWCanvas clean; `fg gauntlet`
    **GREEN** (dpr1 166/0, dpr2 166/0, webkit 166/0, apps PASS, tiernaming + settle gates PASS)
    — **no inspector recaptures needed** (the new markers/statics shifted no inspected member
    list). Serialization rig still green (Phase 1 did not touch the serialize path — defects
    still present as expected).
- **Phase 2/3 boundary — REVISED 2026-07-04 (recorded before Phase 2 code).** The plan put
  the `Widget.serialize` rewire + old-body/`doSerialize`-branch/dead-trio deletion in Phase 2.
  But the rig's round-trip checks (positives like window-children AND the defect checks) need
  BOTH a new serializer AND a new deserializer to be coherent; rewiring `serialize` to the new
  envelope while `world.deserialize` is still the old parser would break every round-trip
  (old parser can't read the new single-JSON envelope) — turning the green positives red for a
  whole phase. So: **Phase 2 builds the new `Serializer.serializeWidget` engine and proves it in
  ISOLATION** (new rig checks parse the envelope / assert no-side-effects / determinism /
  well-known encoding / rich error-path — calling `Serializer.serializeWidget` directly), while
  `Widget.serialize`, `DeepCopierMixin`, and the extension handlers stay UNTOUCHED (dup + old
  serialize both unchanged → gauntlet stays trivially green). **Phase 3 then rewires BOTH ends
  together** (`Widget.serialize`→`Serializer`, `world.deserialize`→`Deserializer`), deletes the
  old bodies + `doSerialize=true` branches + dead trio, and flips the round-trip checks green.
  Smallest redesign consistent with §4; keeps every phase's rig coherent.
- **Phase 2 — The new Serializer engine (proven in isolation) — LANDED 2026-07-04 (not committed).**
  New `Serializer.serializeWidget(root, opts)` / `buildEnvelope` in
  `src/serialization/Serializer.coffee`: side-effect-free record-builder (no shells → no ID
  drift, no `Class.instances` leak), path-tracked graph walk, cycle/sharing table, `$`-type
  encoders (`$Array`/`$Date`/`$Image`/`$Canvas` [duck-typed on `getContext`+`toDataURL` to catch
  BOTH HTML and SWCanvas]/`$Video`/`$Map`/`$Set`/`$Object`, plus `Color`→`rgba`), the
  transients skip (via `transientsForClass`), the function policy (`$src` else
  `SerializationError`), well-known (`{"$wk"}`) / in-structure (`{"$r"}`) / external
  (`SerializationError` or `{"$ext"}`) classification, `memberships`, deterministic output,
  `prettyPrint`. **`Widget.serialize`/`DeepCopierMixin`/the extension handlers are UNTOUCHED**
  (per the revised 2/3 boundary above) — the engine is exercised directly by the rig.
  - **Build-system fix (important):** `buildSystem/build.py` discovers sources via an EXPLICIT
    directory allowlist (not a recursive `src/` walk), so the new `src/serialization/` dir had to
    be added there — until then the Phase-1 classes silently never entered the build (which is
    why Phase 1's "nothing consumes it" was doubly true). Added unconditionally (serialization
    ships in `--homepage`; only the dev test-menu items are stripped, via their own markers).
  - **Gate — MET.** Rig serializer-half GREEN both backends (native + SWCanvas): `validEnvelope`
    (WindowWdgt root, 93 objects), `dollarStringStored` ('$2 bill' verbatim — D2), `noSideEffects`
    (instances 8→8 — D6), `deterministic` (byte-identical — D6), `wellKnownEncoded`
    (target=world → `{"$wk":"world"}` — D3), `colorCompact` (`rgba:[255,0,0,1]` — D5),
    `dateEncoded` (`{"$Date",ms}` — D4), `errorPath`
    (`SerializationError path="SimpleButtonWdgt#10 → .target"`). Boot-smoke clean;
    `fg gauntlet` GREEN (dpr1/dpr2/webkit 166/0, apps PASS, tiernaming+settle) — no recaptures
    (dup pixels untouched). The existing round-trip rig checks still exhibit the OLD defects
    (Widget.serialize still old) — they flip in Phase 3.
- **Phase 3 — Deserializer + round-trip green (FRAMEWORK part) — LANDED 2026-07-04 (not committed).**
  New `src/serialization/Deserializer.coffee`: 5-pass restore (instantiate shells /
  native-factories → populate & link resolving `$r`/`$wk`/`$ext` at any depth → identity &
  registration [fresh id for kind:widget, `registerThisInstance`] → fixups [`$src` compile via
  `injectProperty`, derived-context rebuild, `memberships` re-register, `_afterDeserialization`
  hook] → deliver `{widget, whenReady}` detached). Async image/canvas decode collected into one
  `whenReady` promise (decodes via `<img>` onload for BOTH backends). `Widget.serialize`/
  `deserialize` rewired to thin delegates (`Serializer.serializeWidget` / `Deserializer.deserialize(...).widget`)
  and **de-homepage-stripped** (serialization ships in production). Back-buffer added to Widget
  transients (rebuilt on paint). **Dead-code sweep:** removed the `doSerialize` parameter + all
  serialize branches from `DeepCopierMixin` + the 6 native-type extension handlers (Array/Date/
  Image/HTMLCanvasElement/HTMLVideoElement/CanvasGradient), simplified `Color`'s copier overrides
  (`getEmptyObjectOfSameTypeAsThisOne → return @`; dropped the serialize-only
  `recursivelyCloneContent`), and deleted the dead `prepareBeforeSerialization`/`serializerVersion`/
  `classVersion` trio from Color/Point/Rectangle. `fullCopy` caller updated to the new arity.
  - **Gate (framework) — MET.** Rig FULLY GREEN both backends — the §3 D-table is now fixed
    end-to-end: `dollarFidelity` ('$2 bill' verbatim), `external.pointerResolves` (target===world),
    `clock.deserializeNoThrow`, `color.preserved` (_r=248), **`window.pixelParity.samePage`
    (restored#2689043898 == orig) AND `window.pixelParity.crossSession` (fresh-page restoredB ==
    origA)** — i.e. PIXEL-IDENTICAL restoration same-page and across sessions (vs Phase 0's black
    1083582248), plus counter/instances-stable + deterministic. `fg gauntlet` GREEN (dpr1/dpr2/
    webkit 166/0, apps, tiernaming, settle) — **duplication byte-identical after the dup-path
    sweep**. `fg homepage` boots clean (serialization ships). Boot-smoke clean.
  - **Deferred (recorded):** (i) SliderWdgt's deserialization `@button` guards LEFT AS-IS — inert
    with the new atomic deserializer (which resolves `@button` before any method runs) but
    harmless; migrating them to `_afterDeserialization` is cosmetic and deferred. (ii) The
    `DUPLICATED_CODE_IN_DEEPCOPY` cycle-table consolidation (7 near-identical preambles → one
    helper) NOT done — separable refactor, deferred to keep the dup-path edits minimal/reviewable.
  - **Macro SystemTests (Phase 3 completion) — DONE 2026-07-04.** Shipped
    **`SystemTest_macroSerializeRoundTripWindow`** (SWCanvas refs dpr 1+2 + visualisation): builds a
    window, serialises it to memory (via `serialiseToMemory`), destroys it, restores the copy to the
    same spot, and asserts `assertScreenshotsIdentical(image_0, image_1)` — a **byte-identical**
    round-trip render (`d179d65f` dpr1 / `dc29ddcb` dpr2), the visual proof of the fix. Also wired
    **`serialiseToMemory` to catch `SerializationError` → `world.inform`** (the §4.7 friendly-error UX;
    the Phase-4 file action reuses it). Scope decision: `macroSerializeExternalPointerError` was
    authored but **DROPPED** — the `world.inform` error dialog is nondeterministic under parallel
    suite load (passed in isolation, failed dpr2/webkit in the gauntlet); the rig's
    `serialize2.errorPath` gates that behaviour deterministically instead. `macroSerializeConnectedControllers`
    and `macroSerializeClock` NOT authored — covered by the rig (`connected.inStructureRef`,
    `clock.deserializeNoThrow` + `memberships`); a live "slider drives target"/"clock ticks" macro
    is deferred (higher determinism risk, marginal gain over the rig).
    **LESSON: an eval-driven round-trip (serialise/destroy/restore via `world.evaluateString`) +
    `assertScreenshotsIdentical` is the robust macro idiom; menu-driven navigation of the dev
    test-menu was flaky (missing-item → `undefined.x`), and the `world.inform` dialog is load-flaky.**
  - **Phase 3 exit gate — MET.** Rig fully green; `fg gauntlet` GREEN (167 tests incl. the new
    macro, dpr1/dpr2/webkit 0-failed, apps, tiernaming, settle); homepage boots; round-trip macro
    passes all four backend×density legs.
- **Phase 4 — File save/load over `file://` — LANDED 2026-07-04 (not committed).**
  New `src/serialization/FileSaving.coffee` (`saveStringAsFile`: Blob → `URL.createObjectURL` →
  synthetic `<a download>` → revoke; Safari `data:`-URL fallback; NO dev-FileSaver dependency;
  ships in all builds) and `FileLoading.coffee` (`openFromFileDialog` hidden `<input type=file>`;
  `loadFile`/`loadEnvelopeString` sniff the envelope and route by `kind` — widget → deserialize +
  attach at drop point + `whenReady` repaint; world → `loadWorldSnapshot` [Ph 5]; non-Fizzygum →
  friendly inform). Wired `WorldWdgt.dropBrowserEventListener` (was empty) to route dropped files;
  `Widget.saveToFile` (serialize prettyPrint → `FileSaving`; SerializationError → inform) +
  `WorldWdgt.openFromFile`. Menu items "save to file…" (widget menu) + "open from file…" (world
  menu) added to the **product (`isIndexPage`) branches only** — the harness (`isIndexPage=false`)
  omits them, so ZERO SystemTest menu-screenshot churn; the rig gates the functionality.
  Single ext `*.fzw.json`; routing on `kind`, never the filename.
  - **New file-roundtrip rig** `Fizzygum-tests/scripts/serialization-file-roundtrip-headless.js`
    (+ npm `test:serialization:file`): SWCanvas over `file://`, all 7 checks GREEN — `saveDownloads`
    + `saveByteExact` (downloaded bytes == in-memory serialize, captured via CDP
    `Page.setDownloadBehavior`), `saveValidEnvelope`, `dropHandlerRestores` + **`dropPixelParity`**
    (a real synthetic `drop` event carrying a `new File` restores the widget PIXEL-IDENTICAL —
    `dropped#4118064249 == orig#4118064249` — through the whole Blob→file→drop→FileReader→
    deserialize→render path), `nonFizzygumRejected`, `noPageErrors`.
  - **Gate — MET.** File rig green; in-memory rig green; `fg gauntlet` GREEN (167 tests dpr1/dpr2/
    webkit 0-failed, apps, gates).
  - **⚠ LESSON — `saveToFile` broke ONE existing test via the inherited-member list.**
    `Widget.saveToFile` (a new base method) appeared in `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly`'s
    inspector list (`inherited: on`), whose alpha-row scroll (`calculateVertBarMovement` with a
    `idx - visibleRows/2` CENTER target) was hyper-marginal — it landed `alpha` at the pane's
    bottom edge, and one extra method under-scrolled it just out of view, so the click selected the
    wrong row → neither rectangle faded → the test was DEFEATED (not a benign visual shift). Per
    owner policy (don't contort framework code; recapture benign inspector fails) the FRAMEWORK
    `saveToFile` stayed; the TEST's scroll was made robust (target `alpha` AT THE TOP `idx` — the
    consistent under-scroll then lands it mid-pane with the whole pane as margin), then a benign
    recapture for the 1-method scrollbar-thumb shift. DIAGNOSIS technique: rename the method to a
    `<a`-sorting name — the test passed, proving the alphabetical INSERTION POSITION (not the count)
    drove the tip. Manual `--browser` sanity in a real Chrome/Safari over `file://` NOT performed
    (headless CDP + synthetic drop is the automated gate; noted as a follow-up).
- **Phase 5 — Whole-world snapshot — LANDED 2026-07-04 (not committed).** New
  `Serializer.serializeWorld` (+ `@WORLD_APP_SLOTS`, `@collectIdCounters`, and the extracted
  shared encoder `@_buildObjectTable` that `serializeWidget` now also uses — one walker, no
  drift), `WorldWdgt.serializeWorldSnapshot` / `loadWorldSnapshot` / `saveWorldSnapshotToFile`
  / `_teardownForSnapshotLoadNoSettle` + the guided-error `WorldWdgt.serialize` override,
  `WellKnownObjects.resolveApp` completed (memoized fresh app singleton), `Deserializer`
  returns `shells` + resolves `{$ext}` by iid, "save world snapshot…" in the product world
  menu. Round-trip proven **pixel-identical same-page AND cross-session, dpr 1 + dpr 2**, for
  the default desktop (11 children incl. 8 app launchers whose targets re-bind via
  `app:<Class>` well-knowns, a basement with content, customized prefs, "dots" wallpaper) and
  a populated desktop (added window + moved icon + recoloured + "bricks" wallpaper).
  - **Design refinements vs the plan (recorded; all consistent with §4's intent):**
    1. **The world is NOT a table record.** §4.9 floated "the world record itself is a normal
       table entry with transients excluded" — but the empirical own-prop surface is ~50
       transient fields (canvases/contexts/7 LRUCaches/input queue/hand/caret/broken-rect
       trackers/`@appearance` CanvasPattern/a dozen event-listener CLOSURES). Serializing the
       world as a record needs ALL of them declared transient and still risks the D8 crash. So
       the world is captured ENTIRELY via the explicit greppable `world` section, and only the
       snapshot ROOTS (children + basement + app windows + templates) are walked. **Consequence:
       WorldWdgt needs NO `@serializationTransients`** — its transient surface is never visited.
    2. **`onExternalPointer:"capture"`** (a new mode) instead of `"record"`+resolution-pass:
       the sole off-tree straggler on a real desktop is a non-empty folder window's
       `defaultContents` placeholder (held for when the folder empties). `"record"` (`{$ext}`)
       would restore it to nil (it is in NO snapshot root, so the iid pass can't find it);
       `"capture"` pulls it into the table as a full record, realizing §4.9's "everything is
       in-structure" intent. Self-policing (still throws on a truly unserializable value). The
       `{$ext}` path + `shellByUniqueId` iid resolution stay as a defensive fallback (a settled
       world leaves none).
    3. **Product-safe teardown.** §4.9 said reuse `fullDestroyChildren`/`_resetWorldNoSettle` —
       but `resetWorld`/`_resetWorldNoSettle` are **homepage-stripped** and this ships in
       `--homepage`. Teardown is built from product primitives (`fullDestroyChildren` [product,
       and it zeroes the id counters] + `basementWdgt.empty` + nil the slots) in a NoSettle core.
    4. **Basement is SWAPPED, not contents-merged** (`world.basementWdgt = restoredBasement`) so
       every `{$r}` pointer at it (the basement opener's target) stays consistent; the basement
       is off-tree and self-contained, so the swap is safe.
    5. **`loadWorldSnapshot` is a PUBLIC orchestrator** (not `_`-prefixed) so its self-settling
       `setColor` / `_settleLayoutsAfter` calls pass layering gate [G] (a `_`-method calling a
       self-settling wrapper is a [G] violation — caught at build; fixed by making the
       orchestrator public, like `resetWorld`).
    6. **Confirm = native `window.confirm`** (works over `file://`; rig/macro pass
       `skipConfirm`) — Fizzygum has no styled confirm dialog; a styled one is a polish item.
  - **Gate — MET.** `fg build` 0 violations; serialization rig GREEN incl. the new world leg
    (dpr 1 AND dpr 2): `world.serializeHandled` (guided error), `world.samePage.pixelParity`,
    `.childrenPreserved`, `.statePreserved`, `world.populated.pixelParity`,
    `world.crossSession.pixelParity`, `.childrenPreserved`; file rig GREEN; widget rig GREEN
    (native+sw). `fg gauntlet` + `fg homepage` — see the Phase-5 exit-gate note.
  - **Deferred (recorded):** a webkit leg of the world RIG is NOT built (the rig is raw
    Puppeteer/Chrome; the widget path is already byte-identical cross-engine and the world
    restore reuses it, and the gauntlet's webkit SUITE run covers cross-engine rendering — so
    the marginal value is low). A live in-world macro (`SystemTest_macroWorldSnapshotSaveLoad`)
    was NOT authored: the destructive teardown/reset is exactly the settle-minefield the lore
    warns against driving from a macro, and the rig gates the functionality deterministically at
    both densities; noted as an optional follow-up.
- **Phase 6 — Source-edit capture — LANDED 2026-07-04 (not committed).** New
  `src/serialization/SourceEditsRegistry.coffee` at `world.sourceEditsRegistry` (constructed in
  the WorldWdgt ctor; product, ships in `--homepage`): logs function-source edits as plain-JSON
  `{scope, className, uniqueID?, propertyName, source}`. Hooked at BOTH edit choke points —
  `Widget.injectProperty` (`recordInstanceEdit`) and `ClassInspectorWdgt.applyPropertyEdit`
  (`recordClassEdit`, whose `@target` is the class prototype). `serializeWorld` embeds
  `serializableRecords()` in `world.sourceEdits`; `loadWorldSnapshot` rebuilds the registry
  (`fromRecords`) and **replays CLASS-scope edits BEFORE deserialization** (`replayClassEdits` →
  `prototype.evaluateString`), installs the registry AFTER deserialize (so the `$src`
  re-injections don't double-log). Instance-scope edits ride the normal `{"$src"}` path.
  - **Gate — MET.** `fg build` 0 violations; serialization rig GREEN incl. the new source-edit
    leg — `sourceEdits.instanceEditSurvives` (an `injectProperty` method edit → `"INST_A"` in a
    fresh page) and `sourceEdits.classEditReplayed` (a `ClassInspectorWdgt` prototype edit →
    `"CLASS_A"` replayed onto a fresh page whose prototype had NO such method, `absent-before=true`).
    Both exercise the REAL hooks. `fg gauntlet` + `fg homepage` — see the arc-end gate note.
  - **Deferred / banked (recorded):** the staged §4.10 extensions stay banked — whole-class
    source replacement, classes DEFINED in-world, exporting edits as a `.coffee` patch, baking
    edits into `?generatePreCompiled`. Instance-edit recording is deliberately function-only
    (a non-function `injectProperty` is a value set that rides normal serialization, not a
    "source edit" needing replay).

**Arc complete.** Phases 0–6 all landed; the whole serialization / deserialization / duplication
machinery is live (widgets, composites, connected controllers, `file://` save/load, whole-world
snapshots, in-world source edits). Final combined gate: `fg gauntlet` (167 tests, dpr1/dpr2/webkit
/apps/tiernaming/settle) + `fg homepage` boot + both serialization rigs, all green — recorded at
commit time. Awaiting owner review (the one end-of-arc review, per the long-arc workflow).

---

## Appendix A — Spike evidence (2026-07-04, build `040330e6`, native backend, headless Chrome)

Four throwaway scripts (session scratchpad, not committed; Phase 0 productizes them):

- **Spike 1 — battery**: `RectangleWdgt`, `StringWdgt`, `AnalogClockWdgt`, `SliderWdgt`,
  `SimpleButtonWdgt`: all `fullCopy` OK; all serialize OK (2-6 KB, every one containing
  `"$EXTERNALWorldWdgt#1"` tokens); deserialize OK *except* `AnalogClockWdgt` (D4 throw);
  restored button/slider structurally intact.
- **Spike 2 — edges**: `'$2 bill'` → corrupted to an object (D2); button `target === world` →
  restored `undefined` (D3); `WindowWdgt`+`RectangleWdgt` round-trip: 6/6 children, same size,
  **40 293 / 360 000 bytes differ** (D5 — black chrome, missing label in screenshot);
  `serialize()` twice → different strings (D6); `world.serialize()` → throws on
  `DesktopAppearance.pattern` (D8).
- **Spike 3 — root causes**: back-to-back serializations differ *only* in `instanceNumericID`
  fields (D6); restored `Color` own-keys `[className, compactSerialisedForm]`, `_r/_g/_b` nil
  (D5); labels survive as strings.
- **Spike 4 — capabilities**: `RectangleWdgt.instances.size` grows by 1 per serialize (D6 leak);
  `saveAs(Blob)` over `file://` headless → file lands, **byte-identical** (via CDP
  `Browser.setDownloadBehavior`); window+slider serialized in page A **restores in a fresh page
  B** (6 children, label intact) — rendered almost fully black (D5 compounding), proving
  cross-session structural viability and visual non-viability of the prototype.

## Appendix B — Touch-list index

**New files** — `Fizzygum/src/serialization/`: `SerializationError.coffee`,
`WellKnownObjects.coffee`, `Serializer.coffee`, `Deserializer.coffee`, `FileSaving.coffee`,
`FileLoading.coffee`, `SourceEditsRegistry.coffee`, plus a link-only `CLAUDE.md`.
`Fizzygum/docs/`: `serialization-duplication-reference.md` (the ONE content-bearing doc, §4.6/§8.6).
`Fizzygum-tests/scripts/`: `serialization-roundtrip-headless.js`
(+ file-roundtrip leg), 4-5 new `tests/SystemTest_macroSerialize*` dirs.

**Modified** — `src/mixins/DeepCopierMixin.coffee` (drop serialize mode);
`src/basic-widgets/Widget.coffee` (`serialize`/`deserialize` delegates at 2588/2608, delete old
bodies 2587-2683, menu additions near 3235-3248, transients seed, `injectProperty` hook at 2689);
`src/WorldWdgt.coffee` (well-known registration, `serializeWorldSnapshot`/`loadWorldSnapshot`,
drop handler 1858-1866, world transients, guided error);
`boot/extensions/{Date,Image,HTMLCanvasElement,HTMLVideoElement,CanvasGradient,Array}-extensions.coffee`
(serialize branches removed, video dup bug fixed, cycle-preamble consolidation);
`SWCanvasElement-extensions.coffee` (mirror any handler changes);
`src/basic-data-structures/{Color,Point,Rectangle}.coffee` (dead legacy removal; Color factory
restore path); `Wallpaper.coffee`/`WidgetFactory.coffee`/`IconicDesktopSystemWindowedApp.coffee`
(`wellKnownKey`); `src/basic-widgets/SliderWdgt.coffee` (guards → `_afterDeserialization`);
`src/DesktopAppearance.coffee` + patch-programming nodes + `ScrollPanelWdgt`/`MouseSensorWdgt`
(transients); `meta/ClassInspectorWdgt.coffee` (registry hook, Phase 6);
`menu-system/MenusHelper.coffee` (new file menu items; test menu unchanged);
`Fizzygum/CLAUDE.md` (one link line to the reference doc — link only, no content, per §8.6).

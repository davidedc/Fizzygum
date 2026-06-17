# OO code-smell refactoring backlog

A prioritized, dependency-aware backlog of object-oriented design cleanups for the Fizzygum
`src/` tree, distilled from a full smell audit (2026-06-17). It is the natural **next phase after
the `*Morph`→`*Wdgt` rename campaign** (which closed with `WorldMorph`→`WorldWdgt`; see
`class-modernization-playbook.md`): renaming made names consistent, this makes the *structure*
consistent.

This file is meant to be executable cold. It embeds the catalogue, the per-item touch-lists
(`file:line`), the volume/risk/determinism assessment, the verification recipe, and the ordering
rationale. You should not need the original audit conversation to act on any phase.

---

## Progress

| Phase | Status | Notes |
|---|---|---|
| 1a — `IconButtonWdgt` base | ✅ DONE 2026-06-17 | 6 icon buttons (Close/Collapse/Uncollapse/Edit/Internal/External) |
| 1b — `EditorContentPropertyChangerButtonWdgt` (+ `AlignButtonWdgt`) | ✅ DONE 2026-06-17 | 10 editor-toolbar buttons; base inconsistency resolved onto `IconWdgt` |
| 1c — `CreatorButtonWdgt` parameterized | ✅ DONE 2026-06-17 | 24 creator/toolbar buttons; `createWidgetToBeHandled` left per-leaf |
| 1d — `PaletteWdgt` base | ✅ DONE 2026-06-17 | `GrayPaletteWdgt` refused-bequest fixed (now a sibling); setters collapsed |
| 2 — thin the ~85 `IconWdgt` shells | ✅ DONE 2026-06-17 | `IconWdgt` got a `createAppearance` hook (method, not `@appearanceClass` field — keeps the dependency-finder edge); 89 shells de-constructored, incl. the `ExternalLink`→`VideoPlay` sub-lineage + 6 tooltip shells (which keep a slim ctor) |
| 0 — dead code (pixel-neutral subset) | ✅ DONE 2026-06-17 | removed the 118-line commented `processDrop` block + orphaned `droppedImage/SVG` stubs + `popUpCenteredInWorld` + video `isPlaying` (134 lines); see Phase 0 notes below for kept/deferred |
| 4 — `MenuItemSpec` parameter object | ✅ DONE 2026-06-17 | new `MenuItemSpec` value object kills the 17-arg `MenuItemWdgt` ctor (→6) + the `createMenuItem` comment wall (12 args →1); `addMenuItem`/`prependMenuItem` KEEP their positional public API (356 callers untouched — the "~25 call sites" estimate was for the wrong method) and build the spec internally; `maxWidthOfMenuEntries` `instanceof` chain → existence-guarded polymorphic `menuEntryPreferredWidth?()` on the 4 entry types (no `Widget` base method → no inspector recapture). 2 SystemTests that build `MenuItemWdgt` directly updated. |
| 3 — paint-preamble dedup (TARGETED, scope-reduced) | ✅ DONE 2026-06-17 | Investigation found the "uniform 14–18-copy preamble" premise false (4 skeletons + ~6 outliers, 2 hierarchies); per owner decision did the clean dedups only: lifted the byte-identical plot paint method onto `GraphsPlotsChartsWdgt` (Bar/Scatter/Function inherit; 3D kept — reparenting would change behaviour), and extracted a `LayoutChromeWdgt` base (paint scaffold + `drawLayoutChrome` hook) for the spacer/adder/adjuster trio. Left Shape-A/D + outliers as-is. 165/165 dpr1+dpr2+WebKit + --homepage, zero recapture. |
| 5 — decouple `Widget` from subclasses *(polymorphism-first)* | ◑ CLEAN WINS DONE (E/B/F/G → Phase 6) | **5a DONE 2026-06-17:** the smart-placer (`WidgetCreatorAndSmartPlacerOnClickMixin`) — two `instanceof` chains (4-type capability find + 3-vs-1 placement branch) collapsed into polymorphic `acceptsSmartPlacedWidgets`/`smartPlace` on `StretchableEditableWdgt` (covers `PatchProgramming`/`SimpleSlide` subclasses) & `SimpleDocumentWdgt`, dispatched via `?()` so nothing lands on `Widget` (no inspector recapture). 165/165 dpr1+dpr2+WebKit, zero recapture. **5b DONE 2026-06-17:** `WindowWdgt`→`isWindow?()` (Widget close-flow `:480` + context-menu `:3477`) and the `{Handle,Caret}` overlay-chrome filter→`isLayoutDecoration?()` (Widget content-bounds merge `:985` + `TreeNode.childrenNotHandlesNorCarets`), all via `?()` — decouples Widget/TreeNode from those leaf types with nothing on the base. 165/165 dpr1+dpr2+WebKit + `--homepage`, zero recapture (incl. no inspector recapture). **5c (a predicate sweep over ~18 structural Widget `instanceof`) REVERTED** — owner: predicates are "still bad" (a type-test renamed) and the attempt shipped a real regression. Superseded by a dedicated TRUE-POLYMORPHISM plan: **`docs/widget-identity-decoupling-plan.md`**. **Exemplar DONE 2026-06-17:** a `childGeometryChanged` notify-hook on `SimpleVerticalStackPanelWdgt` replaces Widget's 3 `instanceof SimpleVerticalStackPanelWdgt` layout-notify sites (165/165 dpr1+dpr2+WebKit, zero recapture). A probe established that adding methods to common base classes is inspector-safe — no recapture tax. **Cluster A DONE 2026-06-17:** a `ScrollPanelWdgt.reLayOutAfterContainedPanelChange` notify-hook (does the adjustContentsBounds+adjustScrollBars pair, returns true=absorbed) + a `ListWdgt` opt-out override replace `SimpleVerticalStackPanelWdgt`'s two `amIPanelOfScrollPanelWdgt()` sites; that predicate, now dead, was DELETED from `Widget`. Study finding: PanelWdgt's already-duck-typed sites and the stack's predicate sites are NOT the same notification (differ on List & SVStack/Window parents) so were deliberately NOT merged — left for Cluster B/Phase 6 with Widget's grandparent block. Confirms the **ADD/DELETE asymmetry**: deleting an inspector-visible Widget method forced exactly ONE inspector-test recapture (`macroDuplicatedInspectorDrivesCopiedTargetOnly`), regenerated + re-verified. 165/165 dpr1+dpr2+WebKit + `--homepage`. **Cluster C DONE 2026-06-17:** `Widget`'s two self `if @ instanceof ScrollPanelWdgt` attach-path checks (`newParentChoice`/`newParentChoiceWithHorizLayout`) → `@refitContentsAndScrollBars?()` — a new `ScrollPanelWdgt` method extracting the adjustContentsBounds+adjustScrollBars pair (inherited by `ListWdgt`, NO opt-out: Cluster C INCLUDES List, unlike A), dispatched via `?()` so nothing lands on `Widget` = zero recapture; `reLayOutAfterContainedPanelChange` now delegates to it. 165/165 dpr1+dpr2+WebKit + `--homepage`. **Phase 5 endgame (owner decision 2026-06-17):** after A/C, no clean behaviour-moves remain — E (lock/grab), B (`amIDirectlyInside*` scroll-structure), F (hierarchy-menu) are scroll-structure topology that DISSOLVES under the God-class split, and G (adder/droplet, entry-fields, shortcut, tooltip/handle/caret filters) are leaf-role filters convertible only to pattern-3 capability-queries. ALL FOLDED INTO Phase 6 (see `docs/god-class-decomposition-plan.md`, which has a per-check dissolution map). 5a/5b/exemplar/A/C are this phase's deliverable. |
| 6–8 | ☐ not started | |

All Phase 1 verified: **165/165 Chrome dpr1 + dpr2 + WebKit, `--homepage` boots, zero reference recapture.**

**Deferred from Phase 1** (lower-value / higher-risk — revisit later):
- 1c: the `wrapInWindow` + toolbar-scaffold helpers — the `WindowWdgt`-arg and extent-order
  variations across leaves make a shared helper messy for little gain.
- 1d: merging the two `{Color,Grayscale}PalettePatchProgrammingIconAppearance` files — pixel-sensitive
  drawing code that would risk a recapture.

**Phase 0 — kept / deferred (findings from verifying every "unused" claim against BOTH repos before deleting):**
- `Widget.setupTestScreen1` is NOT dead — `SystemTest_macroLayoutSpacerEatsSpareSpace` calls it. KEPT (the
  audit's headline 183-line removal was wrong; a method called by-name from a test, invisible to a `src` grep).
- `Widget` methods `isTouching` / `overlappingImage` / `drawCachedTexture` / `showMoveHandle` ARE dead, but the
  inspector with **"inherited: on"** lists inherited Widget methods, so removing them recaptures
  `macroDuplicatedInspectorDrivesCopiedTargetOnly` (one test; benign — the list is just 4 shorter). DEFERRED to a
  pass that owns the inspector recapture (Phase 6 re-baselines inspector tests anyway). Confirmed via the dumped
  failure: panes identical, only the property-list scroll extent shifts.
- `prepareBeforeSerialization` (Point/Rectangle/Color) is a live dynamic hook (`@[property].prepareBeforeSerialization?`),
  not unused — KEPT.
- Constant-naming (`ICON_SPECIFICATION_SIZE = Point 100,100` ×153, default-extent + macro-timing constants) —
  DEFERRED as its own focused sweep ("Phase 0b").
- `escalateEvent`'s `arg1..arg9` splat and the `unused`/`dontLayout` params — DEFERRED (signature changes → Phase 8).

---

## How items are ordered ("bang for the buck")

Priority = **volume of correction ÷ risk**, with two overrides:

1. **Dependency overrides bang-for-buck.** A subtle/risky change that *unblocks* a big payoff is
   slotted before that payoff even if its own ratio is poor. There is exactly one such case here:
   **Phase 5 (decouple `Widget` from its subclasses) must precede Phase 6 (God-Class split)** — you
   cannot cleanly lift `Widget`'s responsibilities while the base still hard-references ~25 of its
   own leaf classes. Everything in Phases 0–4 is independent of it.
2. **Risk is dominated by two things in this codebase:**
   - *Does the change alter rendered pixels?* If no → the byte-exact SystemTest suite is a free,
     total safety net and the change is low-risk regardless of size. If yes → a reference recapture
     is required and the change is a behaviour decision (flagged explicitly below).
   - *Does the change touch the rendering loop, `doLayout`, or `ActivePointerWdgt` input
     recognition?* Those are **determinism-sensitive** (`../Fizzygum-tests/DETERMINISM.md`): a
     refactor that is logically correct can still introduce a dpr-2/parallel-load pixel flake if it
     makes output depend on cycle/frame counts or wall-clock timers. Such items are pushed late and
     marked **[DET]**.

Result: voluminous + pixel-neutral + no-`[DET]` work goes first; behaviour- and determinism-
sensitive work goes last; the single architectural prerequisite is slotted by dependency.

---

## Verification recipe (run after every phase; per-item notes only call out deltas)

From `Fizzygum/` unless noted (commands and rationale in `Fizzygum/CLAUDE.md`):

1. `./build_it_please.sh` — CoffeeScript syntax gate (the build ships source-as-text; this is the
   parse-error net).
2. `./build_and_smoke.sh` — headless boot (native + SWCanvas); catches load-order / missing-class
   faults a base-class rename or a new `extends` edge can introduce. **Required net for any new
   base class or moved `new X`** — the dependency finder regex-scans for `extends X`/`@augmentWith
   X`/`new X`, so use those literal forms.
3. `./build_and_test.sh` — the whole macro SystemTest suite (currently **165 tests**), headless,
   parallel, `speed=fastest`, dpr 1 (~1 min). The default behavioural check.
4. **dpr 2 + WebKit** — the standing green bar for this project is *165/165 at Chrome dpr1+dpr2 +
   WebKit*. Always confirm dpr 2 and `npm run test:webkit` (one-time `npx playwright install
   webkit`) for any `[DET]` item before declaring done.
5. `--homepage` boot leg, as a **3-step cd sequence** (build in `Fizzygum/`, smoke in
   `Fizzygum-tests/`, restore): `./build_it_please.sh --homepage` → `cd ../Fizzygum-tests && node
   scripts/smoke-boot-headless.js --native-only` → restore the normal build. (Skips test +
   experimental code; the net for homepage-shipped classes. Experimental code — `fizzytiles/`,
   video player — is *stripped* here, so its net is the normal build, not this leg.)

**Recapture rule:** the suite asserts raw-pixel `dataHash` equality, so it *is* the oracle for
whether a refactor changed pixels — never pre-classify "this won't move pixels" and bless blind. A
behaviour-preserving extraction should yield **ZERO recapture**; if a test goes red, localize with
`node scripts/run-macro-test-headless.js SystemTest_<name> --dump-failures` before deciding whether
it's a benign shift (recapture) or a regression (fix).

---

## The catalogue (smells found, by family)

Condensed from the audit; each maps to phases below.

- **God Class** — `Widget.coffee` (4728 L / 314 methods, ≥10 responsibilities), `WorldWdgt.coffee`
  (2230 L / 112), `MenusHelper.coffee` (1170 L / 132, a per-demo-window dumping ground),
  `StringWdgt` (1423), `InspectorWdgt` (658).
- **Base knows its subclasses** — `Widget.coffee` does `instanceof`/`new` on ~25 descendants
  (`:480,608,985,1145,2206,2778,3477…`); `WorldWdgt:1972-2099` is a 20-type factory.
- **Type-check instead of polymorphism** — 178 `instanceof`; ~10 genuine clusters (containers/
  buttons interrogating contents/parent by class). No type-`switch` smell exists (all `switch` is on
  data).
- **Missing intermediate abstraction** — ~85 empty `XIconWdgt extends IconWdgt` shells; 6
  `*IconButtonWdgt` with no `IconButtonWdgt` base; 10 format/align buttons (split across `Widget`
  and `IconWdgt` bases); 17 `*CreatorButtonWdgt`.
- **Refused bequest** — `GrayPaletteWdgt extends ColorPaletteWdgt` (overrides the defining method,
  sole subclass, has a dead override).
- **Duplicated code** — the `paintIntoAreaOrBlitFromBackBuffer` preamble (14–18 copies, ~13 L each);
  `*CreatorButtonWdgt` ctor/factory shell (×17); `*IconButtonWdgt` ctor + stale comment (×6);
  format-button preamble (×10); `ColorPaletteWdgt` setters (×3 identical); palette patch-prog
  appearances (×2, ~40 L).
- **Long parameter list / comment-deodorant** — `MenuItemWdgt` ctor (17 params, `:11`),
  `createMenuItem` (12, `MenuWdgt:64,111,116`) annotated with a trailing comment per arg;
  `escalateEvent (functionName, arg1..arg9)` (`Widget:3899`).
- **Primitive obsession** — `(al,at,w,h)` 4-number tuples thread the paint pipeline instead of
  `Rectangle` (`Widget:1693`, `Appearance:31`, +call sites re-exploding a Rectangle); two clashing
  mouse-button string vocabularies (`"left button"` MacroToolkit vs `"left"` ActivePointerWdgt).
- **Flag arguments** — `doSerialize` (14+ branches), `doubleClickInvocation` (6 files),
  `beingDropped` on `add` (~12 widgets).
- **Temporary field** — `ActivePointerWdgt` drag/click scratch (`@wdgtToGrab`,
  `@nonFloatDraggedWdgt`, `@doubleClickWdgt`/`Position`, `@grabOrigin`); `InspectorWdgt.@currentProperty`.
- **Inappropriate intimacy / feature envy** — `CaretWdgt` ↔ `TextWdgt`/`StringWdgt` (71 `@target.*`,
  bidirectional writes); `SimplePlainTextWdgt:100-117` writes `@parent.parent.isTextLineWrapping`.
- **Message chains / LoD** — `world.basementWdgt.scrollPanel.contents.…` (`Widget:487`),
  `.contents.contents.add` (~8×).
- **Magic numbers** — `new Point 100,100` ×153 (icon sizes), the `globalAlpha = (if appliedShadow?…)
  * @alpha` idiom ×19, drifted shadow offsets `(4,4)/(5,5)/(7,7)/(6,6)`.
- **Speculative generality / dead code** — commented-out `processDrop` (~110 L,
  `ActivePointerWdgt:713-823`) + orphaned nil stubs; 24 single-child bases; confirmed-unused methods;
  `arg1..arg9`/`unused`/`dontLayout` params.

---

## Phase 0 — Surface reduction: delete dead code + name pixel-neutral constants

**Why first:** highest bang-for-buck — large line reduction, ~zero risk (deleting unreferenced code
and naming a constant to its *current* value changes no pixels), and it shrinks the surface every
later phase has to reason about.

Tasks:
- **Delete commented-out code blocks:** `ActivePointerWdgt.coffee:713-823` (the ~110-line dead
  `processDrop`) **together with** its orphaned no-op stubs `WorldWdgt.coffee:1738,1741`
  (`droppedImage:/droppedSVG: -> nil`); `TextWdgt.coffee:121-150`; `Widget.coffee:4041-4049`;
  `fizzytiles/LCLCodePreprocessor.coffee:496-510,1214-1241`.
- **Delete grep-verified unused methods** (confirm 1 hit = the definition, then remove):
  `Widget.coffee:3919 isTouching`, `:3926 overlappingImage`, `:1630 drawCachedTexture`,
  `:2802 showMoveHandle`; `PopUpWdgt.coffee:136 popUpCenteredInWorld`;
  `video-player/VideoPlayerCanvasWdgt.coffee:56 isPlaying`; the 3 identical
  `prepareBeforeSerialization` (`Point:35`, `Rectangle:87`, `Color:214`).
- **Remove the dev fixture off the base class:** `Widget.coffee:4472 @setupTestScreen1` (183 lines of
  test scaffolding that does not belong on the universal base). Grep-verify the caller; relocate to a
  dev/test location or delete.
- **Delete declared-unused params** named `unused`/`dontLayout` (`ToolPanelWdgt.coffee:14`,
  `HorizontalMenuPanelWdgt:18`, `SimpleVerticalStackPanelWdgt:17`, `ScrollPanelWdgt:186`) — sweep all
  override signatures together (positional args).
- **Name pixel-neutral constants** (value unchanged → zero recapture), into `PreferencesAndSettings`:
  `ICON_SPECIFICATION_SIZE = Point 100,100` (×153 across `icons/*Appearance`), default-extent
  constants (`460×400` ×14, `300×300` ×11, `75×75` ×18, `560×410` ×3), macro timing defaults
  (`1000` ×15, etc. in `MacroToolkit`).

**Volume:** ~400+ lines removed/clarified, ~200 literals named. **Risk:** LOW. **[DET]:** no.
**Recapture:** ZERO. **Explicitly NOT here:** shadow-offset reconciliation (changes pixels → Phase 8)
and the `arg1..arg9` splat (a signature change, not dead code → Phase 8).

---

## Phase 1 — Sibling-family base extraction & dedup *(contains the two seed examples)*

**Why here:** large mechanical dedup across leaf widget families; pixel-neutral (these are chrome
whose *rendering* is unchanged); the rename batches proved the button/palette families re-baseline
zero tests when their behaviour is preserved. Delivers the two originally-cited smells first.

- **1a — `IconButtonWdgt extends ButtonWdgt` base** (seed example #1). Pull the byte-identical
  constructor (`super true, @, 'actOnClick', new Widget`) + the orange `color_hover`/`color_pressed`
  pair + the (corrected, de-duplicated) header comment up into a new base; leaves keep only
  `actOnClick` + their appearance class + tooltip. Files: `buttons/{Close,Collapse,Uncollapse,Edit,
  External,Internal}IconButtonWdgt.coffee:12`. Drops ~110 L (incl. the stale 72-line comment copied
  ×6). *Note the genuine difference to preserve:* Close uses `Color.RED`, the others
  `Color.create 255,153,0`.
- **1b — `EditorContentPropertyChangerButtonWdgt` base** for the format/align family. Captures the
  `@augmentWith HighlightableMixin/ParentStainerMixin` lines, the three `color_*` fields, and the
  `@actionableAsThumbnail`/`@editorContentPropertyChangerButton` flags; **resolves the base
  inconsistency** (`Bold/Italic/AlignLeft/Center/Right` extend `Widget`; `ChangeFont/DecreaseFontSize/
  FormatAsCode/IncreaseFontSize/Templates` extend `IconWdgt` — pick one). Parameterize the Align
  trio's identical `mouseClickLeft` (`AlignLeftButtonWdgt:17` / Center / Right) on its
  `(alignMethod, layoutAlignSetter)`. ~130 L.
- **1c — Parameterize `CreatorButtonWdgt`.** Give the base a ctor reading class-level
  `@appearanceClass`/`@toolTip`, and a `wrapInWindow(content, extent = Point 200,200)` helper; 17
  leaves collapse to ~2 lines each. Add `ToolbarCreatorButtonWdgt.makeToolbarWindow(children,
  extent)` for the 5 toolbar variants. ~140 L.
- **1d — `PaletteWdgt` base** (seed example #2 — fixes the refused bequest). Extract a `PaletteWdgt`
  holding the drag-to-pick-pixel + target/menu plumbing + the shared `createRefreshOrGetBackBuffer`
  cache shell (cache-key → alloc → store) with an overridable `fillPaletteBuffer(ctx, extent)` hook;
  make `ColorPaletteWdgt` and `GrayPaletteWdgt` **siblings**, each supplying only its fill. Delete
  `GrayPaletteWdgt`'s dead `initialiseDefaultWindowContentLayoutSpec` override (identical to
  inherited). Collapse `ColorPaletteWdgt:65-81`'s 3 identical setter methods into one helper. Merge
  the 2 near-identical `icons/{Color,Grayscale}PalettePatchProgrammingIconAppearance.coffee` (~40 L
  shared) via a `gradientColorStops(g)` hook.

**⚠ Button-family internals to preserve (1a/1b/1c are all `ButtonWdgt`-rooted).** Current hierarchy:
`Widget → ButtonWdgt → { SimpleButtonWdgt, LabelButtonWdgt → { MenuItemWdgt, MagnetWdgt } }`. Four
traps recur for any new button base (learned the hard way in the Arc-5 `LabelButtonWdgt` extraction,
which stayed pixel-identical): (1) `HighlightableMixin.updateColor` calls `setColor`, which clobbers
`@color` (the normal fill) — inline `Widget`'s `mouseDownLeft` (`bringToForeground` + `escalateEvent`)
rather than `super`-ing into the mixin; (2) the mixin's `mouseUpLeft` resets `state→NORMAL`, breaking
any `STATE_PRESSED`-based selection — override to a no-op where that matters; (3) `ButtonWdgt.doLayout`
lays out a `faceMorph` — a button without one must call `Widget::doLayout.call @, …` directly (the 6
icon buttons pass `new Widget` as the faceMorph in `super true, @, 'actOnClick', new Widget` — preserve
that arg when lifting the ctor); (4) `ButtonWdgt`'s ctor takes `faceMorph` in slot 4 — mind the arg
mapping when the base forwards `super`. The metric to defend: menus/buttons stay **pixel-identical**.

**Volume:** ~520 L de-duplicated, 3 new base classes. **Risk:** LOW. **[DET]:** no. **Recapture:**
predict ZERO. *Watch:* the two palette set-target tests (`macroTargetingHighlightsCandidateMorph`,
`macroUniqueTargetAndPropertyAreStillPresented`) once re-baselined on a menu *label-width* change —
but a behaviour-preserving refactor doesn't change any drawn label, so still ZERO; confirm with the
suite. New bases ⇒ run `build_and_smoke` (load-order net). Phase 1 and Phase 2 are order-independent;
1 goes first only because it ships the seed examples at the lowest risk.

---

## Phase 2 — Thin the ~85 `XIconWdgt` shells (highest single-pattern volume)

**Why here:** the single biggest line/class reduction available, and it is **low-risk in the
keep-the-classes form** (behaviour identical → pixel-neutral). The ~85 `icons/*IconWdgt.coffee`
classes are each a 5-line shell whose whole body is
`constructor: (@color) -> super; @appearance = new XIconAppearance @`.

- **Low-risk form (recommended):** give `IconWdgt` a constructor that reads a class-level
  `@appearanceClass` (`@appearance = new @constructor.appearanceClass @`); each former shell becomes
  a bodyless `class BoldIconWdgt extends IconWdgt` + `@appearanceClass: BoldIconAppearance`. **Keeps
  the classes** → every `new BoldIconWdgt …` call site and all type identity are unchanged; only the
  ~85 duplicated constructor bodies disappear. Pairs naturally with Phase 0's
  `ICON_SPECIFICATION_SIZE` (defaulted on the base appearance).
- **Aggressive form (deferred / optional — do NOT bundle):** collapse the classes entirely to a
  registry/factory (`IconWdgt.named 'Bold'`). This removes the 85 declarations but forces a call-site
  migration and loses type identity; only worth it if a future need (e.g. data-driven icon menus)
  appears. Flag for an owner decision.

**Volume:** ~85 constructor bodies removed. **Risk:** LOW–MEDIUM (icons render in many tests, but
output is identical). **[DET]:** no. **Recapture:** ZERO. Depends on nothing hard (Phase 0 icon
constant is a nicety, not a prerequisite).

---

## Phase 3 — Paint-preamble Template Method **[DET]**

**Why here:** high volume (~180–230 L across 14–18 files) but it touches the **rendering path**, so
it ranks below the pixel-neutral non-render dedup and must be verified byte-exact at dpr 2 + WebKit.

- Add a `Widget`/`Appearance` `paintIntoAreaOrBlitFromBackBuffer` that runs the shared preamble
  (`calculateKeyValues` → `clipToRectangle` → `globalAlpha` → `useLogicalPixelsUntilRestore` →
  translate), calls an overridable `drawContents(aContext)` hook, then the postamble (`restore` +
  `paintHighlight`). Each leaf keeps only its draw tail. Sites include `icons/IconAppearance.coffee:69`,
  `UpperRightTriangleAppearance:14`, `HandleWdgt:65`, `LabelButtonWdgt:115`, `PenWdgt`,
  `basic-widgets/{Boxy,CircleBoxy}Appearance`, `LayoutSpacerWdgt`, `StackElementsSizeAdjustingWdgt`,
  `LayoutElementAdderOrDropletWdgt`, `apps/AnalogClockWdgt`, `graphs-plots-charts/Example{Bar,Scatter,
  Function,3D}PlotWdgt`. (`IconAppearance` already does this for *its* sub-family — lift the pattern
  one level up.)
- Fold the `globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha` idiom (×19)
  into a single `effectiveAlpha(appliedShadow)` helper while here.

**Volume:** ~200 L. **Risk:** MEDIUM (must be byte-exact). **[DET]:** yes — read
`../Fizzygum-tests/DETERMINISM.md`; confirm dpr 2 + WebKit. **Recapture:** ZERO if faithful (any diff
is a bug, not a baseline shift).

**✅ As built (2026-06-17) — SCOPE REDUCED after investigation (owner-approved):** Reading
`DETERMINISM.md` + mapping all 19 `paintIntoAreaOrBlitFromBackBuffer` sites showed the "uniform
14–18-copy preamble → one `drawContents` hook" premise does NOT hold: there are **4 distinct
skeletons + ~6 outliers across 2 class hierarchies** (Widget subclasses use `@alpha`/`@position()`;
Appearances use `@widget.alpha`/`@widget.position()`; preliminary-check is bare `return` vs `return
nil`; alpha multiplicand is `@alpha`/`@widget.alpha`/`@backgroundTransparency`; some pre-fill, some
don't, some don't even `save`/`clip`/translate). A single Template Method would need ~5 hooks and
still miss 6 outliers — negative bang-for-buck for the riskiest `[DET]` phase. Per owner decision,
did only the **clean, blatant-duplication dedups**:
- **Plot family** — the byte-identical paint method lifted onto `GraphsPlotsChartsWdgt`; `ExampleBar/
  Scatter/FunctionPlotWdgt` inherit it (each keeps its `renderingHelper`). `Example3DPlotWdgt` keeps
  its copy: it `extends Widget` directly and reparenting onto the base would also pull in that base's
  constructor + `KeepsRatioWhenInVerticalStackMixin` (a behaviour change). NB: the plot widgets are
  in NO SystemTest, so the suite is silent on them — this is a pure mechanical lift (identical body
  onto an already-extended base) backed by the boot-smoke, not the pixel oracle.
- **Spacer family** — new `LayoutChromeWdgt` base (homepage-stripped, like its leaves) holds the
  Shape-B scaffold (bg-box fill → logical px → translate → `drawLayoutChrome` hook) + the
  `thisSpacerIsTransparent` early-out; `LayoutSpacerWdgt`/`LayoutElementAdderOrDropletWdgt` use the
  base default `drawLayoutChrome` (their `spacerWidgetRenderingHelper`),
  `StackElementsSizeAdjustingWdgt` overrides it. These ARE suite-covered.

**Left as-is (documented not-worth-it):** Shape-A appearances (Boxy/CircleBoxy/UpperRightTriangle +
Handle), Shape-D (RectangularAppearance/DesktopAppearance), and the outliers (LabelButtonWdgt,
AnalogClock, PenWdgt, the icon scale-variant). Forcing them into a shared template is negative
bang-for-buck, and `CircleBoxyAppearance` carries a truncated-source `@paintHighlight … w,` defect
(missing the final `h` arg) best not disturbed under a dedup. The `effectiveAlpha` helper (×19 idiom)
was also skipped — the multiplicand varies, and putting it on Widget would risk the inspector
"inherited: on" recapture trap (cf. Phase 0 / Phase 4). Verified **165/165 Chrome dpr1+dpr2 + WebKit
+ `--homepage` boot, zero recapture.**

---

## Phase 4 — `MenuItemSpec` parameter object (kills the worst signatures + comment-deodorant)

**Why here:** medium volume, pixel-neutral (menu *rendering* is unchanged), but menus are heavily
photographed so it sits after the no-photograph chrome dedup.

- Introduce a `MenuItemSpec` value object (label, click/env handlers, target, action, tooltip, color,
  bold, italic, doubleClickAction, args, representsAWidget) and thread it through
  `MenuWdgt.coffee:64 createMenuItem`, `:111 addMenuItem`, `:116 prependMenuItem`, and the 17-arg
  `MenuItemWdgt.coffee:11` constructor. This deletes the per-argument trailing comments at
  `MenuWdgt:64-89` (comments that exist *only* because the positional call is unreadable).
- Same-file polymorphism fix: `MenuWdgt:206-211 maxWidthOfMenuEntries` branches on `instanceof
  MenuItemWdgt / StringFieldWdgt / ColorPickerWdgt / SliderWdgt` → add `menuEntryPreferredWidth()` to
  each entry type and take `Math.max` over it.

**Volume:** 4 signatures + ~25 call sites; deletes the comment wall. **Risk:** MEDIUM (menu surface).
**[DET]:** no. **Recapture:** predict ZERO.

**✅ As built (2026-06-17):** `MenuItemSpec` (`src/basic-widgets/menu-system/MenuItemSpec.coffee`)
holds the 12 per-item fields; menu-level context (font, the menu's environment) stays a
MenuWdgt-supplied constructor argument, NOT on the spec (it is identical for every row).
`MenuItemWdgt`'s ctor went 17→6 params; `createMenuItem` went 12→1 and lost its per-argument
comment wall. **Scope correction:** `addMenuItem` has **356** call sites (not the "~25" guessed
above — that was a mis-estimate), so churning them all would be the opposite of bang-for-buck;
its positional public API was deliberately KEPT and it builds the spec internally (the spec's
constructor defaults reproduce the old `createMenuItem` defaults exactly, so behaviour is
unchanged). The `maxWidthOfMenuEntries` polymorphism fix uses an **existence-guarded**
`item.menuEntryPreferredWidth?()` with the method added to the 4 entry types only
(`MenuItemWdgt` → `children[0].width()+8`; `StringFieldWdgt`/`ColorPickerWdgt`/`SliderWdgt` →
`@width()`) — deliberately **no `Widget` base default**, to avoid the inspector "inherited: on"
method-list recapture trap (cf. Phase 0). Two SystemTests build `MenuItemWdgt` directly
(`macroBareButtonFloatDragsWithoutTriggering`, `macroEditButtonLabelText`) — a test-API-by-name
caller invisible to a `src` grep — and were rewritten to the `(new MenuItemSpec …), font…` form
(byte-identical widget). Verified **165/165 Chrome dpr1+dpr2 + WebKit + `--homepage` boot, zero
recapture.** (`LabelButtonWdgt`'s own 17-arg ctor is the base-button contract and was left as-is
— out of scope.)

---

## Phase 5 — Decouple `Widget` from its subclasses (seed example #3) — **prerequisite for Phase 6**

**Why slotted here (the dependency override):** its own bang-for-buck is medium and it is subtler
than Phases 0–4, but it is the **gate on the God-Class split**: while `Widget` (and `WorldWdgt`)
hard-reference ~25 concrete leaves, you cannot lift their responsibilities without dragging the leaf
knowledge along. It also independently fixes seed example #3 (`instanceof` = missed polymorphism) and
the base-knows-subclasses smell.

**⤳ SUPERSEDED by the dedicated plan `docs/widget-identity-decoupling-plan.md`** (the predicate
sweep was reverted; do TRUE polymorphism via notify/override hooks, one cluster per step).
**CORRECTION:** adding methods to common base classes is inspector-SAFE (a probe confirmed it), so
the `?()`-dispatch noted below is about not bloating the God base *by design*, NOT about avoiding
recapture. The rest of this note is kept as rationale.

**Approach (owner-refined 2026-06-17): prefer TRUE polymorphism over predicates.** An `instanceof`
is usually *missed polymorphism*, so first try to MOVE THE BEHAVIOUR inside the branch onto the type
(`x.doIt()` overridden per class → the branch disappears) rather than just swapping in a capability
query (`x.isFoo()` — that drops the base→subclass coupling but keeps the branch: `instanceof` in a
nicer hat). Fall back to a query ONLY where the behaviour genuinely can't move — e.g. *filtering*
chrome out of a child-iteration, which is a property of the iteration, not behaviour you can push
into the widget. **Dispatch via an existential call (`x.method?()`) so the new methods live on the
relevant SUBCLASSES, not as a default on `Widget`** — that keeps the God-class method-list unchanged
and dodges the inspector "inherited: on" recapture trap (the Phase 0 / Phase 4 lesson). [5a applied
exactly this.]

With that lens, replace each *genuine* `instanceof` cluster, then delete the branch:
- `ScrollPanelWdgt:67-74` (drop-accept + display name) → `containerWantsDrops()` /
  `colloquialNameForContainer()` on the contents.
- `WidgetCreatorAndSmartPlacerOnClickMixin:18-30` (4-class chain, twice) → `smartPlace(widget)` on the
  content widgets (also kills the feature-envy at `:28-41`).
- `CaretWdgt:85,93` (`instanceof SimplePlainTextWdgt`; `constructor.name == "StringWdgt"`) →
  `tabInsertsSpaces()` / `enterKeyAccepts()`.
- The ~20 "exclude the chrome" guards (`instanceof HandleWdgt/CaretWdgt/…` when iterating children,
  across `Widget.coffee:608,985,2206`, `TreeNode:504`, `ScrollPanelWdgt:189`, etc.) → one
  `isLayoutDecoration()` predicate.
- `Widget:480,3477` etc. `instanceof WindowWdgt` → `isWindow()`; resize-handle guards →
  `acceptsResizeHandles()`; the scattered `instanceof FanoutPinWdgt` → `selectableAsTarget()`; the
  `Example3DPlotWdgt`/`KeepsRatioWhenInVerticalStackMixin` duplicate
  `instanceof SimpleVerticalStackPanelWdgt and not WindowWdgt` → `parentParticipatesInVerticalStackRatio()`;
  the 5 title-bar buttons' `instanceof WindowWdgt` (`buttons/*IconButtonWdgt:27`) → an `owningWindow()`
  helper.
- Begin moving the base's `new MenuWdgt`/halo/`new HandleWdgt` construction into collaborators (prep
  for 6b).
- **Leave alone** (legitimate, *not* in scope): the value-coercion `instanceof` in
  `Point`/`Rectangle`/`Color`, the serialization `.className` round-trip, and the
  reflection/test-harness class lookups (`MacroToolkit`, `InspectorWdgt`).

**Volume:** ~40 sites → predicates. **Risk:** MEDIUM (broad, base-level; predicates must return
exactly the booleans the `instanceof` did). **[DET]:** low (no timer surface) but broad — full suite.
**Recapture:** ZERO (logic-equivalent).

---

## Phase 6 — God-Class decomposition (the capstone; multi-sub-arc) **[DET on layout]**

**Why last of the "big" work:** highest architectural payoff but highest effort and blast radius; do
it only after Phase 5 has cut the base→leaf knowledge, and run it in small, individually-verified
sub-batches (not one mega-commit). Follow the **mixins→plain-OO-delegation** direction the codebase
already set: `MacroToolkit` was split out of `WorldWdgt` as the model (see `Fizzygum/CLAUDE.md`).

- **6a — `WorldWdgt` (2230 L → thinner):** extract a popup manager (`closePopUpsMarkedForClosure`,
  `mostRecentlyCreatedPopUp`, `freshlyCreatedPopUps`), a startup/URL service
  (`getParameterPassedInURL`, `nextStartupAction`, `createErrorConsole`), and a naming service
  (`getNextUntitled*ShortcutName`, `colloquialName`) as delegated collaborators à la `MacroToolkit`.
- **6b — `Widget` (4728 L → thinner):** peel cohesive clusters into mixins/collaborators in
  risk-ascending order — serialization/copy (finish the move into `DeepCopierMixin`), identity/inspect
  (`spawnInspector`, `uniqueID*`), animation — then last the **`doLayout` (`:4216`, 99 L) / geometry**
  cluster, which is **[DET]** (read `DETERMINISM.md`; layout output must stay a pure function of final
  geometry, not of intermediate passes). The dev fixture was already removed in Phase 0.
- **6c — `MenusHelper` (1170 L / 132 methods):** turn each per-demo-window builder
  (`createNewTemplatesWindow`, `createSampleDashboardWindow…`, the `degreesConverter` window, etc.)
  into its own `*Window` class/factory; the helper stops being a Divergent-Change magnet.

**Volume:** the largest by far. **Risk:** HIGH (broad; `doLayout` is determinism-sensitive). **[DET]:**
yes for the layout/geometry sub-step. **Recapture:** NOT zero for `Widget`/`WorldWdgt` method moves —
moving an inspector-visible method OFF the base shrinks the inspector's alphabetical method list and
recaptures the inspector test (PROVEN in Phase 5 Cluster A; this corrects the earlier "zero for pure
moves" assumption). `MenusHelper` moves are ~zero (separate singleton, not in the inspector pane).
Budget for deliberate regen; the oracle becomes "only the moved method-name rows changed", not "zero
recapture". Verify dpr 2 + WebKit each sub-batch, especially 6b's layout step. **A detailed,
self-contained execution plan now exists: `docs/god-class-decomposition-plan.md`** (study findings per
class with file:line, the recapture reality, a risk-ascending sub-arc, and the dissolution map for the
deferred Phase-5 checks).

---

## Phase 7 — Coupling cleanups (behaviour-sensitive → late) **[DET on input/text]**

**Why last:** these change *behaviour-adjacent* code (text editing, selection, input recognition) that
is both photographed in many tests and historically a determinism flake source — low bang-for-buck
relative to risk, so they tail the backlog.

- **7a — `CaretWdgt` ↔ `TextWdgt`/`StringWdgt` intimacy + feature envy** (the densest coupling: 71
  `@target.*` accesses with bidirectional writes — `CaretWdgt:22,166,222`; `StringWdgt:1392`). Give
  `TextWdgt` a caret/selection API (`beginEditSession`, `setCaretHint`, extend the existing
  `selectBetween`); move the slot-arithmetic/selection logic off the caret; stop the caret writing
  `@target.undoHistory`/`caretHorizPositionForVertMovement` directly. Photographed in 24+ tests →
  verify carefully.
- **7b — `ActivePointerWdgt` temporary fields → a per-gesture `DragGesture`/`ClickState` object**
  (`@wdgtToGrab`, `@nonFloatDraggedWdgt`, `@doubleClickWdgt`/`Position`, `@tripleClick*`,
  `@grabOrigin`). **[DET]-CRITICAL:** this class owns input/click recognition and is the source of
  three past dpr-2 flakes (multi-click event-time, scroll-thumb). Preserve the **event-time** gating
  (recognition must key off `event.time`, never wall-clock timers). Read `DETERMINISM.md` first;
  dpr 2 + WebKit mandatory.
- **7c — `SimplePlainTextWdgt:100-117`** grandparent writes → `setTextLineWrapping(bool)` on the
  container (which resizes its own content).
- **7d — `PromptWdgt:43-46`** sets `slider.button.{color,highlightColor,pressColor}` →
  `SliderButtonWdgt.setColorScheme(base)`.
- **7e — Demeter accessors:** `BasementWdgt.addLostWidget(w)` for the
  `world.basementWdgt.scrollPanel.contents.…` chain (`Widget:487`, `TemplatesButtonWdgt:28`); an
  `innerContents()` for the `.contents.contents` double-hop (`MenusHelper:863`,
  `IconicDesktopSystemFolderShortcutWdgt:7`).
- **7f — (optional)** `GlassBoxTopWdgt` mild Middle-Man — only if its sole role is event-blocking.

**Risk:** MEDIUM–HIGH. **[DET]:** 7a, 7b. **Recapture:** possible for caret/selection visuals;
expect to recapture deliberately and confirm the assertion content is identical.

---

## Phase 8 — Opportunistic / lower-bang (do as you pass through)

Independent, smaller-ratio items; pick up when already editing the relevant file.

- **Single-child base collapses** (24 classes): the `Video*` chains (`VideoThumbnailWdgt →
  SimpleRasterImageButtonWdgt → …`, `VideoScrubberWdgt → SliderWdgt → CircleBoxWdgt`,
  `VideoPlayPauseToggle → ToggleButtonWdgt → SwitchButtonWdgt`), `PopUpWdgt→MenuWdgt`,
  `BlinkerWdgt→CaretWdgt`, `UpperRightTriangleWdgt → …IconicButton → EditableMarkWdgt`. Collapse the
  base into the child (or vice-versa) unless a 2nd subclass is imminent; delete empty hooks
  (`ClassInspectorWdgt:30`, `SwitchButtonWdgt:60`).
- **Long-method extraction:** `ReconfigurablePaintWdgt:73 createToolsPanel` (276 L → split per tool
  group); `SystemInfo:29 constructor` (193 → `detect*` helpers); `WindowWdgt:391 adjustContentsBounds`
  (103); `InspectorWdgt:143 buildAndConnectChildren` (108 → per-pane builders).
- **Flag-argument splits:** `doubleClickInvocation` → a separate `mouseDoubleClickLeft` handler;
  `beingDropped` → distinct `drop`/`add` entry points; `doSerialize` → split clone vs serialize paths
  (touches `DeepCopierMixin` + every `*-extensions.coffee` — care); `escalateEvent`'s `arg1..arg9` →
  a splat / event object.
- **`MouseButton` enum** reconciling the `"left button"` (MacroToolkit) vs `"left"`
  (ActivePointerWdgt) vocabularies and the runtime `throw`-on-typo string compares — coordinate the
  test-harness side; dpr 2 verify.
- **Shadow constant reconciliation** *(intentional pixel change → recapture expected)*: the drifted
  offsets `Widget:2090 (4,4)`, `PopUpWdgt:123 (5,5)`, `ShadowInfo:10 (7,7)`,
  `ActivePointerWdgt:209 (6,6)` likely should share one `SHADOW_OFFSET`/`SHADOW_ALPHA`. **Owner
  decision** on the canonical value; then recapture the affected references.
- **Filename/class mismatch:** `info-widgets/HowToSaveMessageInfoWdgt.coffee` declares
  `class HowToSaveMessageInfoWdg` — violates the one-class-per-file rule `build.py` depends on; fix the
  name.

---

## At-a-glance ordering

| Phase | Theme | Volume | Risk | [DET] | Recapture | Gated by |
|---|---|---|---|---|---|---|
| 0 | Dead code + constant naming | High | Low | no | none | — |
| 1 | Sibling-family base extraction *(seeds #1, #2)* | High | Low | no | none | — |
| 2 | Thin ~85 `IconWdgt` shells | Highest | Low–Med | no | none | — |
| 3 | Paint-preamble Template Method | High | Med | **yes** | none if faithful | — |
| 4 | `MenuItemSpec` param object | Med | Med | no | none | — |
| 5 | Decouple `Widget` from subclasses *(seed #3)* | Med | Med | broad | none | — |
| 6 | God-Class split (World/Widget/Menus) | Highest | High | **layout** | none if pure moves | **Phase 5** |
| 7 | Coupling (Caret↔Text, pointer state, LoD) | Med | Med–High | **7a/7b** | some | — |
| 8 | Opportunistic (single-child, long methods, flags, shadows) | Low–Med | Low–Med | mixed | shadows only | — |

**Start with Phase 0, then 1 (ships your two seed examples at the lowest risk), then 2.** Those three
are pure bang-for-buck and independent. The only hard ordering constraint in the whole backlog is
**5 before 6**.

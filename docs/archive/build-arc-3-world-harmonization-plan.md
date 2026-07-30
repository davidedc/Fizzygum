# Arc 3 · World harmonization — one world design; retire the `»>>` region-marker mechanism entirely

**STATUS: EXECUTED IN FULL — COMPLETE 2026-07-30.** Phases 1–4: Fizzygum `faea99a6` + tests
`8da2d08ba`; phases 5–7: Fizzygum `7c8f49a3` + tests `4bc119caf` (menu topology per the
owner-ratified sub-plan `build-arc-3-phase-7-menu-topology.md`, archived alongside). Region
markers 63 → 0, all three build.py region regexes DELETED, `check-region-markers.js` holds
every kind at baseline 0 as a hard rule. 18 tests recaptured (dpr 1+2), suite 268 → 269,
gauntlet 13/13 + homepage green. Case law: `archive/INDEX.md`.

Original status: PLAN ONLY — AUTHORED 2026-07-28. Written to be executed COLD by an LLM/engineer
with ZERO prior context. Facts verified against the working tree 2026-07-28 (Fizzygum
`master @ ae45e0ff`, 268 SystemTests) including a full census of every marker site (§2.3–§2.4
— embedded; the census IS this plan's fact base). Line numbers drift; quoted symbols and
snippets are authoritative. **This is ARC 3 of the build-and-packaging program** — program
table + completion doctrine: `build-arc-4-dynamic-parts-plan.md` §0.1/§0.2 (binding here).
Requires arc 2 (`archive/build-arc-2-backend-split-precompile-plan.md` — DONE 2026-07-28) landed; arc 4 (parts)
follows this. **PREREQUISITE SATISFIED (owner-ordered 2026-07-29, DONE the same day):
`archive/resetworld-teardown-completeness-audit-plan.md` ran to completion — it audited the very
teardown machinery Phase 4 here relocates verbatim. ⚠ READ ITS §7.5 BEFORE Phase 4: the teardown
you are about to relocate is NOT the one this plan was written against. It grew 14 further resets
(app slots, `simpleEditorTemplates`, `errorConsole`, `lastEditedText`, the tooltip/pop-up/handle/
momentum sets, `widgetsGivingErrorWhileRepainting`, `trackChanges`, `numberOfIconsOnDesktop`, the
`infoDoc*` flags, `isDevMode`, the prefs bag, the world extent) plus a new completeness guard
(`_auditWorldResetCompletenessNoSettle` + `_worldStateAuditExemptions` + the `RESETWORLD_INCOMPLETE`
token, gated by both headless runners) and two new ctor-captured fields (`_bootExtent`,
`_bootAutoAdjustToFillEntireBrowserAlsoOnResize`). A verbatim relocation must carry ALL of it —
and note the guard reads `WorldWdgt.preferencesAndSettings` and `PreferencesAndSettings.resetToBootInputMode`,
so those move or stay reachable together.**

**SECOND PREREQUISITE (owner-ordered 2026-07-29, DONE the same day):
`archive/teardown-shared-core-plan.md` ran to completion — its §6 is BINDING here. It folded the
dangling-reference half of the teardown into a shared SHIPPING core
(`_teardownWorldStructureNoSettle`), which **this arc must NOT relocate**; Phase 4's move for this
machinery is now the test-only remainder plus the completeness guard. The §2.3 census row below
has been rewritten with the true post-refactor scope (`:2489`–`:2726`, 238 l). The ⚠ sizing in the
paragraph above describes the PRE-shared-core state — do NOT scope Phase 4 from it.**

**MANDATE.** Converge the homepage world and the dev/test world into ONE design, and retire the
in-file region-exclusion mechanism COMPLETELY in this arc: at close there are ZERO `»>>` region
markers of ANY kind in src/ and build.py's three region regexes
(`HOMEPAGE_EXCLUSION_PARTS`, `MACROS_INCLUSION_PARTS`, `VIDEOPLAYER_INCLUSION_PARTS`,
build.py:53-60) are DELETED. Whole-file markers are NOT this arc's mechanism — they die in
arc 4 (partition); this arc may *add* whole-file markers as a temporary landing zone (§5.5),
which is doctrine-legal (that mechanism's retirement hasn't started).

---

## §0 Orientation

### §0.1 Why this arc exists (owner history, 2026-07-28 — the reframe that reorders the program)

The homepage/dev split was born from the OLD test system: it recognised widgets by strings/IDs,
so menus could only ever grow additively and became byzantine; at launch the owner forked a
separately-designed homepage (harnesses stripped via markers, menus reorganised). The macro
test system killed that constraint — macros interrogate the live world, so reorganisation costs
a recapture wave (now mechanical: `fg recapture --auto`), not test rewrites. Standing owner
rules: recapture churn never dictates design; the owner explicitly dislikes the `»>>` markers —
**do NOT invent a replacement marker syntax; RE-HOME the code so no marker is needed.**

### §0.2 Critical reframes

- **H-R1: The markers hide TWO different things — and one of them is product code.** The census
  found ~14 of 58 region sites are NOT dev/test code: core layout machinery
  (`Widget.coffee` ~:4814 — `setMinAndMaxBoundsAndSpreadability`, the deferred-settle
  declaration window, recursive dim getters; ~:5048 — the horizontal-stack `else if` branch of
  `_reLayout`), class constants that become `nil` when stripped (`Widget` min/max width/height
  defaults ~:4695-4705, `LayoutSpec.@SPREADABILITY_*` :42), public API (padding setters
  ~:4251, `addAsSibling*` ~:3315, `LabelButtonWdgt.setLabel` :108), and real features
  (`_initVirtualKeyboard` touch input ~:2075, `PreferencesAndSettings.toggleInputMode` :87).
  **The homepage build ships a DIFFERENT, truncated layout engine.** Related latent breakage:
  whole-file-excluded `SimpleDropletWdgt`/`SimpleDropletAppearance` are constructed
  unconditionally by three SHIPPING widgets (`WidgetHolderWithCaptionWdgt`,
  `GenericShortcutIconWdgt`/`GenericObjectIconWdgt` family). Harmonization is therefore partly
  a correctness fix, not cosmetics.
- **H-R2: Three landing zones, no markers.** (1) **Promote** — product code gets unmarked; the
  homepage *gains* it (no dev-world pixel change ⇒ no suite churn). (2) **Tests repo** — test
  machinery moves to `Fizzygum-tests/Automator-and-test-harness-src/` as harness-side class
  extensions (the mechanism EXISTS: `SystemTestsControlPanelUpdater` already lives there,
  loads with the harness, and core code guards with `if SystemTestsControlPanelUpdater?`;
  harness sources are compiled in-page and can extend core prototypes). (3) **Extract to
  whole-file-marked collaborator classes** — demo/dev content trapped in regions inside shipped
  classes moves into its own classes (the `MacroToolkit` collaborator pattern), whole-file
  marked for now, becoming parts in arc 4. This is how the REGION mechanism dies in THIS arc
  without waiting for parts.
- **H-R3: Additive contributions via ONE small hook.** Where extracted/relocated code must
  appear in core-built UI (the world context menu's dev/demo/test sections), core exposes a
  minimal registration point (a `world.menuContributors` list appended at menu-build time);
  the dev/demo/test code registers when present. `if Automator?` existence checks remain
  legitimate (they ARE the pattern, crude form) but new code prefers the hook.
- **H-R4: Menu unification is owner-led and comes LAST.** Mechanical re-homing first (pixel-
  neutral by construction); redesigning the one world's menu topology is a separate phase with
  the owner choosing the target organisation, closed by one recapture wave.

### §0.3 Cold-execution protocol

`fg status` first; read this doc fully; re-grep every symbol before edit; phases in order,
gates green between. The §2.3/§2.4 disposition columns were **RATIFIED WHOLESALE by the owner
2026-07-29** — Phase 0 is satisfied, EXCEPT the explicit owner-call rows
(`obfuscateAsPassword`, `_showBrokenRects` gating, InformationIcon/SaveIcon,
ProfilingDataCollector, the WorldWdgt `:2732` split), which are raised with the owner
INDIVIDUALLY, code in view, as execution reaches each one. Never commit/push without owner
approval. Suite discipline:
background runs + logs + verdicts; boot-storm flake ≠ code bug; a pixel diff in a phase
declared pixel-neutral is a REGRESSION (do not recapture it away).

---

## §1 Goal and decisions

| # | Decision | Choice | Status |
|---|---|---|---|
| H-D1 | Region-marker mechanism (all three kinds) | Retired ENTIRELY this arc: 58 homepage + 3 macros + 2 video-player region sites re-homed; the three regexes deleted from build.py; a gate forbids `»>>` in src/ forever after. | LOCKED (owner marker-aversion + doctrine) |
| H-D2 | Mis-marked product code (H-R1 list) | PROMOTE — unmark; homepage converges to the one engine/API. | LOCKED (dispositions ratified wholesale 2026-07-29) |
| H-D3 | Test machinery in core classes | Relocate to harness-side extension files in the tests repo (verbatim moves — semantics-exact, the verbatim-fold rule). | LOCKED |
| H-D4 | Demo/dev content in regions | Extract to collaborator classes in NEW whole-file-marked files; register via the H-R3 hook; become parts in arc 4. | LOCKED |
| H-D5 | Dead accretion | DELETE (census `delete` rows) — not moved, not kept. | LOCKED (ratified wholesale 2026-07-29; owner-call rows raised individually in-flight) |
| H-D6 | Menu topology | One design for all builds (test/demo sections contributed additively). Target organisation chosen by owner in Phase 5; recapture wave accepted. | Owner-led |
| H-D7 | `src/macros/` (`FILE_ONLY_FOR_MACROS` whole-file mechanism) | UNTOUCHED this arc — it is a whole-file mechanism (arc 4 turns it into test-part membership). Only its three REGION sites (`MACROS_INCLUSION_PARTS`) are re-homed here. | LOCKED |

---

## §2 Exact current state (census 2026-07-28 — the fact base)

### §2.1 Mechanics

- Whole file: `build.py:325` — a file matching `FILE_NOT_IN_FIZZYGUM_HOMEPAGE` (or
  `FILE_ONLY_FOR_MACROS` / `FILE_ONLY_FOR_VIDEOPLAYER`) is simply never emitted for the
  homepage flavour.
- Region: `build.py:348-350` — `re.sub(<REGION_REGEX>, '', escaped_content)` for the three
  kinds. Region shape (example `LRUCache.coffee:15-21`): code sits between the
  `# »>> this part is excluded…` opener comment and a closer comment ending in `«`; `[^«]*`
  makes pairing unambiguous; all openers pair (63 total `»>>` = 58 homepage + 3 macros +
  2 video-player).

### §2.2 Region census — disposition summary (counts; full table §2.3)

| Disposition | Sites | Character |
|---|---|---|
| **promote** | ~17 | mis-marked product code/API/constants (H-R1) |
| **hook** (→ tests repo or extracted demo class + registration) | ~28 | test machinery, test menus, demo galleries, debug overlays |
| **delete** | ~11 | self-labelled "unused code", dead keypad/recorder rigs, dead menu items |
| **unclear/split** | ~2 | e.g. WorldWdgt:2732 dev-menu block — split item-by-item |

### §2.3 Region census — FULL TABLE (file : ~line : content : disposition)

**basic-data-structures (11):**
`LRUCache:15` values() "unused" → delete · `Point:57` mirror() → delete · `Point:92` divideBy()
→ delete · `Point:146` rotate/flip/distanceAngle trio → delete · `Point:185` rotateBy() →
delete · `Rectangle:124` corners() "unused" → delete · `TreeNode:230` depth() → delete ·
`TreeNode:285` allLeafsBottomToTop() → delete · `TreeNode:338` Automator widget-not-found
debugger → tests repo · `TreeNode:363` siblings family — **positionAmongSiblings IS used by
shipping code** → promote · `TreeNode:499` isADescendantOf() → delete.

**basic-widgets + menus (25):**
`BoxyAppearance:129` menu item → `doNothingInsetsFunctionalityHasBeenRemoved` → delete ·
`MenuRowsPanelWdgt:193` + `MenuWdgt:145` testItems/testNumberOfItems accessors → tests repo ·
`MenusHelper:51` (~116 l) demo-gallery factories → extract (demo class) · `MenusHelper:172`
newScriptWindow() → promote · `MenusHelper:178` (**~573 l** — the whole demo/parts-bin menu
tree + testMenu + ~70 factories) → extract (demo class; testMenu pieces → tests repo) ·
`StringWdgt:357` obfuscateAsPassword → owner call (promote or delete) · `Widget:363`
widgetFromUniqueIDString → tests repo · `Widget:398` constructor default
min/max-bounds+spreadability call → **promote (silent layout fork)** · `Widget:3067`
createPointerWdgt → extract w/ PointerWdgt (experimental) · `Widget:3171`
fullRenderCanvasAsItAppearsOnScreen/fullImageAsItAppearsOnScreen (screenshot-hash source) →
tests repo · `Widget:3315` addAsSibling{After,Before}Me → promote · `Widget:4138` pinouts +
serialiseToMemory fixtures → split: pinouts extract (debug), serialise fixtures → tests repo ·
`Widget:4251` setPadding* → promote · `Widget:4351`+`4396` attachWithHorizLayout → promote ·
`Widget:4580` allSetters() → promote · `Widget:4695/4701/4705` min/desired/max dim constants →
**promote (nil in homepage today)** · `Widget:4709` makeSpacersTransparent/Opaque → tests repo
(testMenu-only) · `Widget:4814` (**~141 l** core sizing/deferred-settle/recursive-dim
machinery) → **promote** · `Widget:5048` (**~97 l** horizontal-stack `_reLayout` branch) →
**promote (homepage runs a truncated layout engine)** · `Widget:5166` adders/droplets layout
chrome → extract (layout-editor family, w/ the whole-file-excluded chrome classes).

**root + events (4):**
`KeyupInputEvent:15` F2 → testMenuForMacros → tests repo · `LabelButtonWdgt:108`
setLabel/_setLabelNoSettle → promote · `LayoutSpec:42` @SPREADABILITY_* constants →
**promote (nil in homepage today)** · `PreferencesAndSettings:87` toggleInputMode → promote.

**WorldWdgt (19):**
`:58` dropBrowserEventListener field → promote · `:155` Thai-keyboard KEYPAD_* constants
(recorder-era hardware rig) → delete · `:187` ongoingUrlActionNumber → tests repo · `:288`
pinout sets → extract (debug) · `:378` doublePressOfZeroKeypadKey keypad rig → delete · `:648`
FridgeMagnetsApp opener at boot → registration by the (whole-file-marked) fizzytiles family ·
`:668` (~63 l) URL ?startupActions runner + getWidgetViaTextLabel → tests repo (lookup →
MacroToolkit) · `:1045` _showBrokenRects → promote behind a dev flag (owner call) · `:1362`
commented profiling call → delete · `:1528`+`:1895` addPinoutingWidgets + cycle call → extract
(debug, moves together) · `:1992` _sizeCanvasToTestScreenResolution (960×440) → tests repo ·
`:2075` _initVirtualKeyboard (touch input) → **promote (real feature)** · `:2366` (~62 l)
removeEventListeners ("a DETERMINISM MECHANISM", sole caller AutomatorPlayer) → tests repo ·
`:2489`–`:2726` (**238 l**, corrected 2026-07-29 — see the second-prerequisite note above; the
recorded `:2469 (~66 l)` was already stale by 4×) the WHOLE homepage-stripped teardown block →
tests repo: `resetWorld` (`:2498`) + `_resetWorldNoSettle` (`:2513`, now only **19 code lines** —
the structural half left for the shared SHIPPING core `_teardownWorldStructureNoSettle`, which
this arc must NOT move) + the completeness ratchet (`@_worldStateAuditExemptions` `:2617`,
`_pristineWorldFingerprint` `:2650`, `_summariseWorldStateValueNoSettle` `:2656`,
`_isDerivedCacheFieldName` `:2676`, `_fingerprintWorldStateNoSettle` `:2690`,
`_auditWorldResetCompletenessNoSettle` `:2711`) which is test-only tooling and belongs with the
harness. ⚠ The moved remainder still clears the three PINOUT tracking sets — they stay test-side
because pinouts are themselves homepage-stripped — and still reaches
`WorldWdgt.preferencesAndSettings` / `PreferencesAndSettings.resetToBootInputMode`, so those move
or stay reachable together. A relocated test teardown calling the shipping core is the RIGHT
dependency direction; verify the reverse never appears ·
`:2559` `if Automator?` pacing/label toggles → tests repo · `:2732` isDevMode world-menu block
→ SPLIT (inspect/color/wallpapers product-worthy → promote; demo ➜ / test ➜ → hook) · `:2766`
popUpSystemTestsMenu → tests repo (NOTE its entry at :2753 is `if Automator?`-guarded, not
region-marked — inconsistent today) · `:2800` (~57 l) popUpDemoMenu/layoutTestsMenu/
toggleDevMode → extract (demo class w/ WidgetFactory).

**Macros/video-player region sites (5):** 3 `MACROS_INCLUSION_PARTS` + 2
`VIDEOPLAYER_INCLUSION_PARTS` sites — same treatment: relocate into the corresponding
whole-file-marked families so the region kind dies. ⟨enumerate by grep at execution:
`# »>>.*[Mm]acro` / `[Vv]ideo`⟩

### §2.4 Whole-file census highlights (this arc touches only the flagged ones)

- ⚠ **Latent homepage breakage — fix THIS arc (promote):** `SimpleDropletWdgt` +
  `SimpleDropletAppearance` (constructed unconditionally by three shipping widgets) and
  `ScriptIconWdgt`/`ScriptIconAppearance` (used by shipping desktop script shortcuts).
- **Move to tests repo THIS arc:** `HashCalculator` (36 l, sole consumer
  `SystemTestsReferenceImage`), `SystemInfo` (234 l, reference-image fingerprint).
- **Delete candidates (owner ratify):** `MouseSensorWdgt` (self-labelled temporary),
  `PinType` (zero references), `ProfilingDataCollector` (all call sites commented out).
- Everything else whole-file-marked (demo icons, layout chrome, PenWdgt, WidgetFactory,
  patch-programming experimental family, fizzytiles) keeps its whole-file marker until arc 4
  partitions it.

---

## §3 Why it is shaped this way — and §4 the argument

The markers were the only tool available when the constraint was "tests freeze the UI"; they
then accreted for eight+ years without an audit, which is how product layout code ended up
stripped from the product. The census (this plan) is that audit. The argument for doing this
arc BEFORE the partition: arc 4's partition inherits whatever topology exists — re-homing and
unifying first means the parts are drawn around a clean world, and the region mechanism (the
owner's explicit irritant) dies without waiting for the parts machinery, via the whole-file
landing zone (H-R2).

---

## §5 Design & phases

Each phase = one disposition bucket = pixel-neutral unless stated; gate after each.

- **Phase 0 — dispositions ratified (DONE 2026-07-29, wholesale — no kickoff review).**
  Residual: the owner-call rows (`obfuscateAsPassword`, `_showBrokenRects` flag,
  InformationIcon/SaveIcon, ProfilingDataCollector, the `:2732` split) are raised with the
  owner individually during whichever phase touches them; amend the table in place as answers
  land.
- **Phase 1 — ratchet gate.** `buildSystem/check-region-markers.js`: counts `»>>` sites
  against a committed baseline; any INCREASE fails the build (wired like the existing gates,
  runs every flavour). Land before any conversion.
- **Phase 2 — PROMOTE (+ the two whole-file promotions).** Delete the marker lines around
  every `promote` row; `SimpleDroplet*`/`ScriptIcon*` unmarked. Dev-world pixels unchanged BY
  CONSTRUCTION (the code was already in the dev build) ⇒ `fg gauntlet` zero-churn gate;
  `fg homepage` green (homepage now runs the full layout engine for the first time — expect
  behavioural improvement, verify boot + owner eyeball of the homepage desktop).
- **Phase 3 — DELETE.** Remove `delete` rows (code + markers). Run the dead-method gate
  (⚠ case law: it must include `Automator-and-test-harness-src/` before declaring anything
  dead). Gauntlet zero-churn.
- **Phase 4 — TESTS-REPO relocation.** New harness-src extension files (e.g.
  `WorldTestSupport.coffee`, `WidgetTestSupport.coffee` in
  `../Fizzygum-tests/Automator-and-test-harness-src/`) install the relocated methods onto the
  core prototypes at harness load (pattern: harness sources compile in-page after core boots;
  `SystemTestsControlPanelUpdater` precedent). Verbatim moves ONLY (H-D3) — resetWorld and
  removeEventListeners are settle-critical (see `settle-tier-teardown-flip` +
  `resetworld-state-leak-between-tests` case law; a behavioural drift here shows up as
  passes-alone-fails-in-suite). `HashCalculator`/`SystemInfo` move as whole files. Gauntlet
  zero-churn (the harness world is unchanged — same code, new home); the homepage build no
  longer contains the machinery at all (assert absent).
- **Phase 5 — EXTRACT demo/dev content + the hook.** `world.menuContributors` registration
  point in core menu building; new whole-file-marked collaborator classes (e.g.
  `DemoPartsBinMenus`, joining `WidgetFactory`) absorb the MenusHelper/WorldWdgt demo regions;
  fizzytiles opener registered by its own family; pinout overlay + layout-adder chrome extract
  with their existing whole-file-marked classes; the 5 macros/video-player region sites fold
  into their families. Menu CONTENT byte-identical (same items, same order, built via the
  hook) ⇒ gauntlet zero-churn gate.
- **Phase 6 — retire the mechanism + docs sync.** Assert zero `»>>` in src/; DELETE the three
  region regexes and their `re.sub`/search applications from build.py; flip the Phase-1 gate to
  forbid the pattern outright. `fg gauntlet` + `fg homepage`. Docs: CLAUDE.md marker/homepage
  sections present-tense; **`docs/explainers/` pages 1–3 carry UNSYNCED arc-1/arc-2 debt**
  (they still describe `?sw=1`, the single bundle, and the tests copy in present tense) —
  bring them current with arcs 1–3 here, per the explainers bucket rule.
- **Phase 7 — menu unification (owner-led, H-D6).** Owner specifies the one menu topology;
  implement; ONE recapture wave (`fg recapture --auto`, gated COMPLETE); homepage inherits the
  same topology minus absent (whole-file-marked) families. This phase may also promote the
  `isDevMode` boundary decision (what ships visible vs dev-flag-gated) — owner's design call.

## §6 Risks

| # | Risk | Mitigation |
|---|---|---|
| R-1 | A "promote" silently changes dev-world behaviour (marker also guarded state) | promotes only delete comment lines; gauntlet zero-churn gate per phase |
| R-2 | Relocated resetWorld/removeEventListeners drift breaks suite determinism | verbatim moves; the settle case-law files read BEFORE Phase 4; suite is the gate |
| R-3 | Homepage behaviour change from gaining the full layout engine | intended (bug fix); homepage smoke + owner eyeball; no homepage pixel suite exists |
| R-4 | Extraction reorders menu items → pixel churn in a "neutral" phase | build menus from the same ordered registration; any diff = regression, fix not recapture |
| R-5 | Harness extension load order (extensions before core class exists) | harness sources load after boot completes (existing manifest ordering); smoke on harness page |
| R-6 | Long tail (the doctrine's target) | Phase-1 ratchet + Phase-6 zero-assert + regex deletion are numbered gates, not aspirations |

## §7 Verification protocol

`fg presuite` inner loop; `fg gauntlet` at every phase close; `fg homepage` at Phases 2/6;
Phase 7 ends with `fg recapture --auto` printing COMPLETE then a full `fg gauntlet`. Marker
count: `grep -rn "»>>" src --include='*.coffee' | wc -l` tracked in each phase's close note.

## §8 Rejected alternatives

1. **A new, nicer marker syntax** — owner-rejected category; re-home instead.
2. **Opportunistic marker retirement across arcs** — the exact long-tail pattern the
   completion doctrine forbids.
3. **Waiting for parts (arc 4) to re-home demo content** — unnecessary; the whole-file landing
   zone lets the region mechanism die now (H-R2), and arc 4 consumes the landed files.
4. **Keeping the truncated homepage layout engine "since it works"** — it is an unaudited
   fork; promote list H-R1 closes it.

## §9 References

Program + doctrine: `build-arc-4-dynamic-parts-plan.md` §0.1/§0.2. Siblings:
`archive/build-arc-2-backend-split-precompile-plan.md`, `build-arc-5-packaging-profiles-plan.md`.
Case law: `settle-tier-teardown-flip`, `resetworld-state-leak-between-tests`,
`dead-code-gate-must-include-harness-src` (memory); mixin-fold verbatim-move rule. Census
provenance: Explore-agent pass 2026-07-28, every region read and classified; recommendations
verified per-site, dispositions owner-ratified at Phase 0.

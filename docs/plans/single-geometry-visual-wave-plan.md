# Single geometry — the visual wave (probe page → three dials → indicator scrollbars → THE one recapture)

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-24 against Fizzygum `bf6e494e` / Fizzygum-tests `341ad470c` (suite 318
SystemTests, build FRESH, gauntlet-green heads). Every `file:line` was verified on that date —
**line numbers DRIFT; the method name / quoted code is authoritative, so `grep` before trusting
a number.** Plan 3 of the program
[`frames-input-touch-program.md`](frames-input-touch-program.md): the decisions this plan
implements are **owner rulings recorded there (IDs G1–G7 — G3/G5/G6 as amended 2026-08-24;
tail T11, T2-absorbed, T3-ruled; boundaries T6, T7, I2/H2)** — cite them, do not re-argue
them. Plans 1 and 2 are EXECUTED AND CLOSED (archived:
`../archive/frame-lifetime-and-docking-plan.md`, `../archive/pointer-events-plan.md`); this plan
is authored against the post-Plan-2 tree per the program's just-in-time rule (§6).

Two ledger citations have drifted on this tree and are re-located here (report-only — the
ledger's dated citations stand as history): the world menu's input-mode row is at
`WorldWdgt.coffee:3220` (G1 cites `:3205`), and `toggleInputMode` is at
`PreferencesAndSettings.coffee:126` (G1 cites `:108`).

**STATUS BOX** (fill per phase as executed)
- P0 re-verification + measurements: **DONE 2026-08-24** (two Sonnet workers). Census
  (`Fizzygum-tests/.scratch/geometry-census.js`, harness page): menu row **15 px**, 10-row menu
  171 px, title strip 17 px, frame bar 26 px, list row 15 px, scrollbar 10 px, over-tall menu
  clamps to 440. Fact re-verify: 19/20 confirmed; F16 sub-counts corrected (menus 145,
  windows/frames 182 — "frame" over-matches as a substring — scroll 62; headline 290/287
  stand). Owner PRE-RULED the P2 queue same day, pre-probe (ledger G3/G5/G6 amendments +
  T2/T3 rows): `menuRowHeight` 44 · T3 = (a) big glyph · `_makePrettier` fold YES ·
  `toolRows` 1 with T2's chevron ABSORBED into this plan · G6 factor 2 · prompter/prompt
  buttons/slider thumbs join the ≥44 rule. P2 remains the eyes-on confirmation; any dial may
  still be re-turned there.
- P1 T11 deletion + row-height plumbing (byte-identical): —
- P2 the probe page + eyes-on confirmation of the pre-ruled dials (G7 gate): —
- P3 wave step A — dials + fold + indicators + chevron at CONSTANT extent (reviewed recapture): —
- P4 wave step B — test-world extent + Automator version bump (reviewed recapture): —
- P5 docs, close, tail: —

---

## MANDATE

**Eliminate the per-device interface entirely and land the ONE touch-capable geometry** — not a
"touch mode", not a bigger skin beside the old one. At close: the live input-mode toggle and its
whole apparatus GONE (T11: the world-menu row, `toggleInputMode` / `setTouchInputMode` /
`setMouseInputMode` / `inputMode` / `INPUT_MODE_*`); ONE preference block holding every chrome
dial, with the suite-vs-product value fork (`_makePrettier`, §1 F4) dissolved into it; the three
dials turned (G3: targets ≥ 44, glyphs ~24 inset, indicators thin); scrollbars transformed into
overlay INDICATORS that appear on scroll, fade on the event clock, and fatten under a hovering
pointer (G4); the docked toolbar collapsed to ONE row of 44 px tools with an overflow CHEVRON
popping the remainder as a menu (T2, ABSORBED into this plan 2026-08-24 — §2.7); the test
world scaled with the geometry (G6); all of it shown to the owner on a probe page BEFORE any
reference moves (G7), then landed as the program's ONE sanctioned recapture wave (program §4
rule 3). Out of scope, each with its ruled address: the gesture grammar (I2 → Plan 4), hover
affordances on touch (T6 → Plan 4), `isTouchDevice` / the virtual keyboard (T7 → Plan 4),
pinch (T4 → BACKLOG).

---

## §0 Orientation

**The project.** Fizzygum is a CoffeeScript GUI framework ("web operating system") rendered on
one HTML5 canvas. Three sibling repos under `Fizzygum-all/`: `Fizzygum/` (source — this plan
edits `src/`), `Fizzygum-tests/` (the SystemTest suite + Automator harness source, served
through the `latest/js/tests` symlink — test edits need NO rebuild; harness `.coffee` edits DO),
`Fizzygum-builds/` (generated, never edited). Every build/test command goes through
`/Users/davidedellacasa/code/Fizzygum-all/fg` (ABSOLUTE path, never `./fg`); bare `fg` prints
the roster. Read the root `CLAUDE.md`, `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md`
before touching anything. No module system: every class is a global; one class per file,
filename = class name.

**The vocabulary:**
- **The one preference block** = `src/PreferencesAndSettings.coffee` (282 lines), a per-world
  singleton reached as the static `WorldWdgt.preferencesAndSettings`. Program ruling G2 (landed
  in Plan 1 P0) made every chrome dimension a named preference there and every thickness a
  formula over them — the wave is close to a one-block edit BECAUSE of that.
- **Chrome** = the frame family (`FrameWdgt` bar/pieces/resizer — Plan 1's output), the menu
  system (`src/basic-widgets/menu-system/` — `MenuWdgt`/`PromptWdgt` are framed citizens,
  rows are `MenuItemWdgt`), the scrolling composite (`ViewportWdgt` + its five subclasses:
  `TextAreaWdgt`, `ListWdgt`, `VerticalStackViewportWdgt`, `PopUpRowsViewportWdgt`,
  `ToolbarWdgt` — verify: `grep -rn "extends ViewportWdgt" src/`), the handles (`HandleWdgt`).
- **The event clock** = `WorldWdgt.timeOfEventBeingProcessed`, set per drained event by
  `WorldWdgt._playQueuedEvents`. The house determinism rule: render/layout/input is a pure
  function of the event stream, never wall clock (`Fizzygum-tests/DETERMINISM.md`). The
  dual-clock idiom this plan reuses is `DragChargingRingWdgt._elapsedForCharge` (§1 F14).
- **The test world** = a 960×440 logical canvas the harness forces
  (`WorldTestSupport._sizeCanvasToTestScreenResolution`), × `ceilPixelRatio` device pixels.
  Every committed reference is a screenshot of it.

**Why this plan exists now.** Plan 1 rebuilt the container/chrome structure and put every chrome
dimension behind a named preference (G2), deliberately pixel-identical. Plan 2 rebuilt the input
plumbing, deliberately pixel-identical. The program parked every deliberate pixel change here
(§3: "All deliberate pixel change lands in Plan 3") so that the suite stayed a byte-exact safety
net through both structural arcs. This plan now spends that budget ONCE: the single geometry
that works for mouse AND finger (G1), reviewed by the owner before capture (G7), recaptured as
one wave (§4 rule 3). Plan 4 (gesture grammar + finger harness) captures at THIS plan's final
geometry (program §3: "3 → 4"), which is why extent and dials must settle here.

**Critical reframes — do not lose these:**
1. **The suite and the product render DIFFERENT chrome today.** `WorldWdgt._makePrettier`
   rewrites a dozen preference values (menuFontSize 12→14, header 12→13, bold→regular, four
   colours, …) but runs only from `createDesktop`, which runs only `if theWorld.isIndexPage`
   (`src/boot/globalFunctions.coffee:470`) — and `isIndexPage` is false exactly on the harness
   page. So every committed reference shows chrome NO USER EVER SEES. The wave folds
   `_makePrettier`'s preference writes into the one block (RULED 2026-08-24, G5 amendment;
   §2.2), so the pixels the owner approves on the probe page are the pixels the suite then
   pins.
2. **The T11 row appears in ZERO committed references.** No macro ever opens the WORLD's own
   context menu (all 43 `openMenuOf` call sites target widgets — §1 F7), and no test names
   the row or its verbs. So the T11 deletion is a ZERO-recapture structural phase (P1), gated
   byte-identical — it does NOT have to ride the wave. Its runtime coverage is `fg menusweep`
   (which walks the world-menu roots) and the build's `check-dead-methods`.
3. **The G6 extent change forces the WHOLE suite to recapture regardless of chrome exposure**
   — a canvas of different dimensions changes every screenshot byte. That is why the wave is
   split into two reviewed capture steps (§5 P3/P4): step A moves the dials at CONSTANT extent,
   where `fg diffpage`'s difference-blend review is meaningful; step B moves the extent, where
   every pixel trivially differs and review degrades to side-by-side sampling. One step would
   save a recapture pass and forfeit the only reviewable diff of the dial consequences.
4. **The extent lives in the HARNESS, so the version-bump question has a hard answer.**
   `_sizeCanvasToTestScreenResolution` is harness source
   (`Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee:127`), and the
   Automator version means exactly "what the harness captures" (tests-repo CLAUDE.md). Step B
   is therefore the grammar's textbook bump case: **bump `0.2.0 → 0.3.0` WITH the extent
   change** — `check-refs.js`'s `STALE AUTOMATOR VERSION` gate then structurally enforces
   recapture completeness. Step A (framework-side dials) warrants NO bump: the harness still
   captures the same way, and Plan 2's precedent ("a bump 'to be safe'" is a rejected
   alternative) holds for it.
5. **Bar-visibility is load-bearing as a SCROLLABILITY proxy today.** Two drag-scroll gates key
   on `anyScrollBarShowing()` (`Widget.coffee:4007`, `PanelWdgt.coffee:159`). Under G4 the bars
   are usually invisible while the pane is still scrollable — those consumers must be re-keyed
   to overflow, or drag-scroll silently dies the moment the indicator fades (§2.4).

---

## §0.5 Cold-execution protocol

**Who executes (program §3.1):** a **COORDINATOR** (the session model, Fable) delegates every
phase to a **WORKER on a cheaper model** — Opus for phase execution, Sonnet for mechanical
sub-steps — via the `Agent` tool (`subagent_type: general-purpose`, `model: "opus"`/`"sonnet"`;
never `fork`, never `isolation: worktree` — the build hard-codes the sibling layout and the
tests symlink). §9 is the delegation map. The steps below are written for the WORKER; the
coordinator runs step 1, briefs per §9, reads reports, decides at gates, hosts the P2 owner
review, and talks to the owner. **The coordinator does not edit source or run suites itself.**

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — orient (heads, build freshness, test
   count, zombie browsers → `fg killz`). Expect heads at or after the header's.
2. Read this plan in full, then the program doc §2.2 (G1–G7, with the 2026-08-24 amendments
   on G3/G5/G6) and §5 (T2, T3, T6, T7, T11), §4 (recapture policy — rules 2–4 govern
   P3/P4). Then read, in this order:
   `src/PreferencesAndSettings.coffee` IN FULL (282 lines), `src/WorldWdgt.coffee` — the
   `_makePrettier`/`createDesktop` block (~:658–:770) and the world-menu builder around the
   input-mode row (~:3180–:3240), `src/FrameWdgt.coffee` — the bar-spec family
   (`_persistentBarSpec` region ~:180–:200, `_barAxis`, `_transientBarSpec` ~:227–:250) and
   `_chromePadding` (~:503), `src/basic-widgets/ViewportWdgt.coffee` — construction (~:119–:177),
   `_reLayoutScrollbars` (~:429–:520) and the scroll entry points it lists,
   `src/basic-widgets/menu-system/MenuItemWdgt.coffee` (`_createLabel`),
   `src/basic-widgets/Widget.coffee` — `isPointerTargetAt`/`catchesPointerAt` (~:474–:512),
   `src/DragChargingRingWdgt.coffee` (the dual-clock idiom), `src/HandleWdgt.coffee` +
   `src/HandleAppearance.coffee`, `src/app-kit/ToolbarWdgt.coffee` +
   `src/app-kit/ToolPanelWdgt.coffee` (the §2.7 chevron seam), `src/PromptWdgt.coffee`
   (~:136 — the button row is MENU ROWS, F21); then
   `Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee`
   (`_sizeCanvasToTestScreenResolution`),
   `Fizzygum-tests/Automator-and-test-harness-src/SystemTestsSystemInfo.coffee` (the version),
   `Fizzygum-tests/CLAUDE.md` (the reference grammar + bump rules + recapture tooling),
   `Fizzygum-tests/DETERMINISM.md` §1–§3, `Fizzygum/src/macros/CLAUDE.md`, and
   `docs/architecture/viewports-and-planes.md` + `docs/architecture/lint-and-static-checks.md`.
3. Execute phases IN ORDER, P0 → P5. Each phase ends with its own gate (§7) and a proposed
   commit. **Owner preference: ask before every commit/push — present a summary and the
   proposed message (`git commit -F <file>`, never backticks in `-m`), then wait.** P2 ends
   with the owner's eyes-on CONFIRMATION (and any re-turned dials), not a commit — nothing
   lands until the owner has seen the ruled geometry live.
4. Long ops (`fg gauntlet`, `fg presuite`, `fg recapture`): launch ONCE with the Bash tool's
   `run_in_background` redirected to a log; peek `cat /tmp/fg-<cmd>.verdict` at a ~5-min
   cadence; never pipe the gating call through `| tail`/`| grep`; never edit src/tests/fg while
   a run is in flight. ⚠ `fg recapture --auto` discovers against the EXISTING build — build
   first, never edit mid-run (program §4 rule 4).
5. If a fix shape is falsified twice, STOP and re-frame — never a third variant (owner rule).
6. Comments you write state what IS — present tense, no history narration (`check-stinks.js`
   fails the build on it). `undefined` is the one absence value (`nil` is retired and gated).
7. Probes live under `Fizzygum-tests/.scratch/` (gitignored) — NEVER the session scratchpad
   (Node resolves `require` from the script's directory).
8. Anything this plan defers goes into the program doc's tail ledger with a destination
   (program §5) — never a "for later" in this file.

---

## §1 The system as it stands (verified 2026-08-24; re-verify in P0)

Each fact records its verification command. Line numbers drift — grep the quoted code.

- **F1 — the one preference block, and its geometry names.** `src/PreferencesAndSettings.coffee`
  (282 lines) declares the chrome-geometry group (G2's landing, its own comment block ~:58):
  `barIconSize 16`, `barGlyphSize 16` ("equal today, so the button's hit box and its drawn
  glyph are the same size … kept as two preferences because a touch target and its glyph are
  different dials (G3)"), `barPadding 5`, `menuHeaderCornerRadius 3`, `menuRowsBorder 2`,
  `toolThumbnailSize 30`, `toolInternalPadding 5`, `toolExternalPadding 10`, `toolRows 2`,
  `toolbarDockThickness 95`, `dockBandDepth 30`; plus the older dials `menuFontSize 12`,
  `menuHeaderFontSize 12`, `titleBarTextFontSize 12`, `titleBarTextHeight 15`,
  `handleSize 15`, `scrollBarsThickness 10`, and the fonts/colours (§2.1's table enumerates all
  values). All are assigned in ONE method, `setMouseInputMode` (~:168–:254), called from the
  constructor (~:124). Verify: `sed -n '1,282p' src/PreferencesAndSettings.coffee`.
- **F2 — `toolbarDockThickness` is an INDEPENDENT constant, not the G2-ledger formula.** Its
  comment says so ("an independent constant, not a formula over the grid metrics above") and
  `ToolbarWdgt` reads it directly (`src/app-kit/ToolbarWdgt.coffee:42` —
  `@dockThickness = WorldWdgt.preferencesAndSettings.toolbarDockThickness unless @dockThickness?`).
  The ledger G2's "`dockThickness` must become `rows·(thumb+gap)+2·externalPadding`" was
  falsified in Plan 1's execution (the program's own memory records it among the falsified
  premises); the wave retunes the VALUE, not a formula. Verify: `grep -n "toolbarDockThickness"
  src/PreferencesAndSettings.coffee src/app-kit/ToolbarWdgt.coffee`.
- **F3 — the T11 cluster, complete inventory.** In `src/`:
  `PreferencesAndSettings.coffee` — `@INPUT_MODE_MOUSE`/`@INPUT_MODE_TOUCH` (:9–10),
  `inputMode` (:35), the constructor's `@setMouseInputMode()` (:124), `toggleInputMode`
  (:126–:136, ends `world.dataflow.markStale @`), `dataflowValue: -> @inputMode` (:141),
  `currentInputMode` (:144), `setMouseInputMode` (:168), `setTouchInputMode` (:256–:281 —
  rewrites `menuFontSize 24`, `bubbleHelpFontSize 18`, `prompterFontSize 24`,
  `prompterSliderSize 20`, `handleSize 26`, `scrollBarsThickness 24`, `useSliderForInput true`);
  `WorldWdgt.coffee:3220–3226` — the "touch screen settings" menu row with its
  `MenuRowReflectionSpec` reading `currentInputMode` against `INPUT_MODE_MOUSE`;
  `MenuRowReflectionSpec.coffee:4` — a doc-comment naming the row as its example. In
  `Fizzygum-tests/`: exactly ONE hit — `scripts/menu-click-sweep-headless.js:64`, a `KNOWN`
  allowlist entry for `toggleInputMode` ("flips a GLOBAL preference…"). ZERO hits in
  `tests/**` and the harness. Verify: `grep -rn
  "inputMode\|INPUT_MODE\|setTouchInputMode\|setMouseInputMode\|toggleInputMode\|touch screen"
  Fizzygum/src Fizzygum-tests --include="*.coffee" --include="*.js"`.
- **F4 — `_makePrettier`: the suite-vs-product value fork.** `WorldWdgt._makePrettier`
  (~:658–:690) reassigns preference values: `menuFontSize 14`, `menuHeaderFontSize 13`,
  `menuHeaderColor 125³`, `menuHeaderBold false`, `menuStrokeColor 186³`,
  `menuBackgroundColor 250³`, `menuButtonsLabelColor 50³`, `normalTextFontSize 13`,
  `titleBarTextFontSize 13`, `titleBarTextHeight 16`, `titleBarBoldText false`,
  `bubbleHelpFontSize 12`, `iconDarkLineColor 37³`, `defaultPanelsBackgroundColor 249³`,
  `defaultPanelsStrokeColor 198³` (plus `@wallpaper.setPattern "dots"` and the desktop colour,
  which are desktop furnishing, not preferences). Called ONLY from `createDesktop` (:709),
  which `startWorld` runs `if theWorld.isIndexPage` (`src/boot/globalFunctions.coffee:470`
  — "isIndexPage is false exactly on the test-harness page"). The block's own `# 14`-style
  comments beside the 12s record the same fork. Consequence: every committed reference renders
  the RAW constructor values; every product page renders the prettier ones. Verify:
  `grep -rn "_makePrettier" src/` and read both blocks.
- **F5 — bar metrics all derive from the block.** `FrameWdgt`'s window-bar spec:
  `thickness: Math.round preferences.barIconSize + 2 * preferences.barPadding` (= 26 today),
  `slotSize: barIconSize`, `glyphSize: barGlyphSize`, `padding: barPadding`,
  `textHeight/fontSize` from the titleBar pair (~:192–:198). The pop-up strip
  (`_transientBarSpec`, ~:227–:250): `thickness: (if titled then textHeight + 2 else 0)`,
  `padding: menuRowsBorder`, `fontSize: menuHeaderFontSize`. The frame's body margin is
  `_chromePadding` → `barPadding` (~:503–:507). `closeIconSize =
  WorldWdgt.preferencesAndSettings.barIconSize` also at ~:1734. `dockBandDepth`'s comment ties
  it to the bar ("at least a bar thickness (barIconSize + 2*barPadding = 26)"). Verify:
  `grep -n "barIconSize\|barGlyphSize\|barPadding" src/FrameWdgt.coffee`.
- **F6 — menu row height is the LABEL's height; there is no row-height dial yet.**
  `MenuItemWdgt._createLabel` commits `@__commitExtent @label.extent().add new Point 8, 0` —
  width = label + 8, height = label height EXACTLY, label at `position().add new Point 4, 0`
  (`src/basic-widgets/menu-system/MenuItemWdgt.coffee:111–129`). Row height therefore tracks
  `menuFontSize` (suite 12, product 14) with zero vertical padding. G5's dial (44 per HIG, 40
  floor) requires a NEW preference consumed as a minimum row box (§2.3). The same class is the
  LIST row (`isListItem()` keys on the container), so the dial reaches `ListWdgt` rows too —
  intended (G1: one geometry). Verify: `sed -n '105,130p'
  src/basic-widgets/menu-system/MenuItemWdgt.coffee`.
- **F7 — no reference shows the world menu or the T11 row.** 43 tests call `openMenuOf` and
  every first target is a widget, none the world; 0 tests match
  `touch screen|toggleInputMode|inputMode`; the only 2 `preferencesAndSettings` matches in
  macro sources are prose comments. `bringUpTestMenu_InputEvents` is an F2-key shortcut to the
  TEST menu, used by 0 tests. Verify: `cd Fizzygum-tests/tests && grep -il "openMenuOf"
  */SystemTest_*_automationCommands.js | wc -l` (43) and the per-target sample
  `grep -H "openMenuOf" …` (targets: rect/txt/win.label/…).
- **F8 — scrollbars today: two `SliderWdgt` children, PERSISTENT while overflowing, overlaying
  the plane.** `ViewportWdgt` builds `@hBar`/`@vBar` as `new SliderWdgt … color: @sliderColor`,
  applies `scrollBarsThickness` (:160–:166), wires `trackTarget @, "setScrollX"/"setScrollY"`.
  `_reLayoutScrollbars` (:429–:498) `show()`s a bar whenever `@scrollPolicy isnt 'never'` and
  the content overflows by ≥1px, `hide()`s otherwise, and PLACES the bars INSIDE the viewport
  (`@bottom() - @hBar.height()`, `@right() - @vBar.width()`): G4's premise VERIFIED — no
  thickness formula anywhere adds `scrollBarsThickness` to a frame; bars overlay the plane. The
  only geometry read is `spaceToLeaveOnOneSide = Math.max(@scrollBarsThickness,
  preferences.handleSize) + 2 * @padding` (:440), which shortens the BARS to clear the resizer
  corner. Verify: read `_reLayoutScrollbars`.
- **F9 — bar visibility doubles as the SCROLLABILITY signal.** `anyScrollBarShowing()` (:398)
  is consumed by the foreground drag-scroll gate (`Widget.coffee:4007` —
  `@parent.parent.canScrollByDraggingForeground and @parent.parent.anyScrollBarShowing()`) and
  the background drag-scroll gate (`PanelWdgt.coffee:159`); `MACRO-PATTERNS.md:1281` documents
  the coupling. G4 must decouple: visibility becomes presentation, scrollability must be asked
  of overflow (§2.4 step 5). Verify: `grep -rn "anyScrollBarShowing" src/`.
- **F10 — the hit test is two members, and hit-beyond-ink is ALREADY the mechanism.**
  `Widget.isPointerTargetAt` (:486 — clipped bounds ∧ shown ∧ `catchesPointerAt` ∧ not
  ephemeral) and `catchesPointerAt` (:508 — the appearance's `shapeContainsPoint`, "NOT 'am I
  see-through here'… a StringWdgt is ~97% ink-free and stays clickable"). So G3's rider ("a
  widget's hit box may exceed what it paints") holds STRUCTURALLY wherever the appearance
  claims its box: a 44-slot bar button painting a 24 glyph is hit on the whole slot with no new
  mechanism. Where the wave must INTRODUCE it: the resize handle (T3, §2.5) and the indicator's
  thin-state OPT-OUT (a thin indicator must NOT catch the pointer — G3 "indicators are NOT
  targets"). Verify: `sed -n '474,512p' src/basic-widgets/Widget.coffee`.
- **F11 — the resize handle today.** `HandleWdgt` sits in a `CornerInternalLayoutSpec` with
  `fixedSize = preferences.handleSize` (15) (`src/HandleWdgt.coffee:52`); ~10 app layouts
  (`BinWdgt`, `ErrorsLogViewerWdgt`, `CodePromptWdgt`, `ConsoleWdgt`, `ScriptWdgt`,
  `InspectorWdgt`, …) reserve a `handleSize` band in their own arithmetic — a `handleSize`
  change moves those layouts too. Verify: `grep -rn "handleSize" src/ | grep -v
  PreferencesAndSettings`.
- **F12 — the test world extent is ONE harness method + three runner viewports.**
  `WorldTestSupport._sizeCanvasToTestScreenResolution`
  (`Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee:127–:138`):
  `worldCanvas.width = Math.round(960 * ceilPixelRatio)`, height 440·cpr, CSS `"960px"`/
  `"440px"`, plus the `background` div styled 960×720. Headless viewports: `{width: 1100,
  height: 800, deviceScaleFactor: 1}` in `scripts/run-macro-test-headless.js:211`,
  `scripts/run-all-headless.js:161`, and the default in `scripts/lib/headless-driver.js:49`.
  18 test `_automationCommands.js` files contain "960"/"440" — read as a sample, they are
  fit-the-canvas PROSE plus coincidental coordinates (`new Point 440, 55`); a GROWN world
  invalidates none of them (everything that fit still fits; macros ask the live world where
  things are). `SystemTestsReferenceImage.coffee:45` documents the constant. Verify:
  `grep -rn "960" Fizzygum-tests/Automator-and-test-harness-src Fizzygum-tests/scripts`.
- **F13 — the Automator version and its gate.** `SystemTestsSystemInfo`'s constructor sets
  0/2/0 (`Automator-and-test-harness-src/SystemTestsSystemInfo.coffee:20–24`) — the ONE source
  of truth, read back by `refpaths.currentAutomatorVersion()`
  (`scripts/lib/refpaths.js:40`). `check-refs.js:97` fails the BUILD on any reference at
  another version (`STALE AUTOMATOR VERSION … recapture them (fg recapture --auto)`).
  References on disk: **1,878 `.png` + 1,878 `.js` = 3,756 files** across 287 of the 318 test
  dirs (31 tests are assertion-only, no screenshots); `tests/` weighs 39 MB. Verify:
  `find tests -path "*automation-assets*" -name "*.png" | wc -l` etc.
- **F14 — the sanctioned dual clock for chrome animation.**
  `DragChargingRingWdgt._elapsedForCharge` (`src/DragChargingRingWdgt.coffee:54–:62`): under
  the Automator (`Automator? and Automator.animationsPacingControl and Automator.state ==
  Automator.PLAYING`) elapsed = `WorldWdgt.timeOfEventBeingProcessed − originEventTime`
  (frozen between drained events ⇒ deterministic screenshots); in production elapsed =
  `WorldWdgt.dateOfCurrentCycleStart − originWallTime`. The ring also quantizes its
  presentation (`dwellRingSteps`, preferences :113) and calls `_changed()` only when the
  quantized step moves. This is the exact shape the indicator fade copies (§2.4). The hand's
  own dwell/multi-click decisions are pure event-time, evaluated AT events
  (`ActivePointerWdgt` :258, :277–:279, :850). Verify: `sed -n '40,65p'
  src/DragChargingRingWdgt.coffee`.
- **F15 — what stays: the T7/G1-adjacent preferences.** `useSliderForInput` (read at
  `Widget.coffee:4371` — `opts.ceilingNum? or preferences.useSliderForInput` routes a number
  prompt to a slider) and `isTouchDevice`/`useVirtualKeyboard` (read at `WorldWdgt` ~:2162 and
  ~:3403, virtual-keyboard gating) survive this plan untouched — T7 (Plan 4) owns them. The
  wave deletes only the MODE apparatus (F3). Verify: `grep -rn
  "useSliderForInput\|isTouchDevice" src/ | grep -v PreferencesAndSettings`.
- **F16 — blast-radius proxies (measured; sub-counts corrected at P0).** 290 of 318 macro
  sources mention chrome vocabulary
  (`menu|window|frame|toolbar|scroll|handle|resiz|inspector|popup|prompt`, case-insensitive);
  145 mention menus, 182 windows/frames (⚠ "frame"/"window" over-match as substrings —
  an upper bound, not an exact chrome count), 62 scroll, 9 toolbars. 287 tests carry
  screenshots.
  Expected wave footprint: step A changes SOME screenshot in the large majority of the 287
  (any visible menu row, window bar, list, scrollbar, handle, prompt, inspector moves);
  step B changes ALL 287 tests' 3,756 files (extent) — plus the new G4 witness tests' own
  references. Verify: `cd Fizzygum-tests/tests && grep -il "menu\|window\|frame\|toolbar\|
  scroll\|handle\|resiz\|inspector\|popup\|pop-up\|prompt"
  */SystemTest_*_automationCommands.js | wc -l`.
- **F17 — the probe scene exists in the product.** The dev desktop (`createDesktop`) draws the
  app icons; `SimpleDocumentApp` ("Docs Maker") opens a `DocumentWdgt` window whose frame docks
  a `TextToolbarWdgt` in its toolbar slot (`src/authoring/SimpleDocumentApp.coffee:8`,
  `src/authoring/DocumentWdgt.coffee:45–47`); right-click on the desktop opens the world menu.
  So "one window, one menu, one docked toolbar" (G7) is two clicks on the built dev
  `index.html`. The `?startupActions` mechanism is harness-owned test-running vocabulary
  (`WorldTestSupport.nextStartupAction`) — NOT usable to stage the scene on the product page.
- **F18 — pop-up cap (C10) and the MEASURED geometry (P0 census, 2026-08-24).** The
  `POPUP_LARGER_THAN_WORLD` guard is `FrameWdgt.coffee:1390`; the rows-viewport cap + scroll
  carries over-tall menus (`SystemTest_macroOverTallMenuScrollsToReachItsLastRow` exercises
  it). The census probe (`Fizzygum-tests/.scratch/geometry-census.js`, run on the BUILT
  harness page) measured today's suite chrome exactly: **menu row 15 px**, 10-row menu
  171 px, pop-up title strip 17 px, frame bar 26 px, `ListWdgt` row 15 px, scrollbar width
  10 px, and an over-tall menu clamped to the 440 px world. These are the numbers §2.6's
  factor arithmetic stands on.
- **F19 — serialization posture.** `PreferencesAndSettings` is a well-known object
  (`wellKnownKey: "preferences"`, `keptByReferenceOnDeepCopy: true`, both with doc-comments
  citing the T11 row as their example — the comments need rewording when the row dies, the
  FLAGS stay: identity semantics are about the singleton, not the row). New transient fields on
  `ViewportWdgt` (§2.4) go on `@serializationTransients` — the subclass list MERGES with the
  chain since Plan 1 T16's fix. Gates: both serialization rigs ride the gauntlet.
- **F20 — gates this plan meets** (index: `docs/architecture/lint-and-static-checks.md`):
  `check-dead-methods` + `check-unresolved-sends` (the T11 verbs and any missed caller),
  `check-menu-actions` (the row's removal is clean — no dangling target/action),
  `fg menusweep` (the row's runtime removal; its `KNOWN` entry must go with it, F3),
  `check-stinks` (comment narration; the reworded doc-comments), `check-argument-holes`,
  `NON_INTEGER_GEOMETRY` (every new formula rounds — label centring in a 44-row included),
  tests-repo `check-refs` (the version gate, F13), `check-visualisations` (recapture
  regenerates pages at the write site), `check-macro-source-discipline` (the new G4 tests),
  `fg doc-narration` (P5 docs sweep). The suite fail-gates `WORLD_CONSTRUCTION_DRIFT` — new
  preference fields are constructor-assigned, so the fingerprint stays deterministic.
- **F21 — prompt/prompter chrome (the G3-amendment fact-check).** The prompt's Ok/Close
  buttons are MENU ROWS, not a separate button family: `PromptWdgt`'s button-row builder
  (~:136–:146) does `panel.addMenuItem "Ok", @, "deliverValue"` (+ "Close"), and
  `SaveShortcutPromptWdgt` swaps in its own three rows the same way — so the `menuRowHeight`
  dial covers every prompt confirmation target with ZERO new mechanism. `prompterFontSize`
  readers: `PromptWdgt.coffee:127`, `SaveShortcutPromptWdgt.coffee:36`. `prompterSliderSize`
  reader: `NumberPromptWdgt.coffee:30` — `slider.__commitHeight …prompterSliderSize`, i.e.
  the input slider's CROSS AXIS is its thumb height, so this preference IS the thumb-target
  dial. Verify: `grep -rn "prompterFontSize\|prompterSliderSize\|addMenuItem \"Ok\"" src/ |
  grep -v PreferencesAndSettings`.
- **F22 — the toolbar grid mechanics (the T2-absorption fact-check).** `ToolbarWdgt extends
  ViewportWdgt` (:14) over a `ToolPanelWdgt extends PanelWdgt` grid. The grid's
  `_layOutOwnContents` row-wraps its cells at pitch `@thumbnailSize + @internalPadding`,
  wrapping against `@parent?.widthContentsMustFitWithin?() ? @width()` — "the toolpanel must
  never scroll horizontally (only vertically)" (its own comment) — and each cell is a
  `GlassBoxBottomWdgt` square of `@thumbnailSize` wrapped around one tool in `_addNoSettle`.
  The bar pieces are the `IconButtonWdgt` family (`src/buttons/IconButtonWdgt.coffee:16`;
  `CloseIconButtonWdgt`/`EditIconButtonWdgt`/…), and `FrameWdgt`'s bar-roster derive already
  CONSTRUCTS pieces inside the arrange through NoSettle cores ("a piece gained here is placed
  in this same pass") — the construction idiom §2.7's chevron copies. Verify: `sed -n
  '90,130p' src/app-kit/ToolPanelWdgt.coffee` and `grep -n "IconButtonWdgt"
  src/FrameBarWdgt.coffee`.

### 1.3 Why it is shaped this way

The per-device toggle is 2010s-era adaptive UI: when Fizzygum was born, "touch support" meant a
mode that swaps a dozen constants (Squeak-style), and the toggle predates both the G2
constants discipline and the modern one-interface convention (macOS Lion's overlay scrollbars,
iPadOS's 44-pt-target-single-layout) the owner ruled into G1/G4. `_makePrettier` is a boot-time
styling pass that never reached the harness page because the harness predates it — an accident
now load-bearing in 3,756 reference files. The scrollbars are classic Morphic furniture:
permanent `SliderWdgt` children, correct for 2015 mouse-only worlds, and exactly the fat
always-there bars G4 retires. Each piece was right when built; the program's Plans 1–2 removed
every structural obstacle, so what remains is precisely values + one behaviour + one harness
constant — which is why this is the ONE wave and why it is safe to do now.

---

## §2 The mechanism this plan installs (target design)

### 2.1 The dial table (G3/G5) — every value the wave moves, in ONE block

The wave's step A edits `setMouseInputMode`'s body (folded into the constructor by P1, §2.3)
and nothing else for values. Columns: today-suite (the constructor block), today-product
(after `_makePrettier`, F4), proposed. **The owner PRE-RULED the headline dials 2026-08-24
(ledger G3/G5/G6 amendments + T2/T3 rows): `menuRowHeight` 44, T3 = big glyph, the fold,
`toolRows` 1 + the chevron, factor 2, prompter/prompt targets in. The remaining "proposed"
values are the author's opening bid; the P2 probe page is the eyes-on confirmation where the
owner may still re-turn ANY dial — re-turned values are recorded in the STATUS box before P3
briefs.** Rationale anchors: targets ≥ 44 (G3, amended: prompter family, prompt Ok/Cancel
buttons and input-slider thumbs are targets — "a confirmation button is the most consequential
tap in the interface"), glyphs ~24 (G3), indicators thin (G3/G4), menu row height
44-by-taste-40-floor (G5), bar strip ≈ 50 (Apple iPad-bar precedent, program §7).

| preference | suite today | product today | proposed | note |
|---|---|---|---|---|
| `menuFontSize` | 12 | 14 | **14** | fold; row height comes from the new dial, not the font |
| `menuHeaderFontSize` | 12 | 13 | **13** | fold |
| `menuHeaderBold` | true | false | **false** | fold |
| `menuHeaderColor` | 77³ | 125³ | **125³** | fold |
| `menuStrokeColor` | 210³ | 186³ | **186³** | fold |
| `menuBackgroundColor` | 249³ | 250³ | **250³** | fold |
| `menuButtonsLabelColor` | BLACK | 50³ | **50³** | fold |
| `normalTextFontSize` | 12 | 13 | **13** | fold |
| `titleBarTextFontSize` | 12 | 13 | **13** | fold |
| `titleBarTextHeight` | 15 | 16 | **16** | fold; bar thickness comes from barIconSize |
| `titleBarBoldText` | true | false | **false** | fold |
| `bubbleHelpFontSize` | 10 | 12 | **12** | fold |
| `iconDarkLineColor` | BLACK | 37³ | **37³** | fold |
| `defaultPanelsBackgroundColor` | 255,250,245 | 249³ | **249³** | fold |
| `defaultPanelsStrokeColor` | 100³ | 198³ | **198³** | fold |
| `menuRowHeight` **(NEW, G5)** | — | — | **44** | RULED 2026-08-24 (40 was the floor); also the prompt Ok/Close target — those buttons ARE menu rows (F21) |
| `barIconSize` | 16 | 16 | **44** | the bar button TARGET box (G3) |
| `barGlyphSize` | 16 | 16 | **24** | the ink, inset in the box (G3) |
| `barPadding` | 5 | 5 | **3** | bar strip = 44 + 2·3 = **50** |
| `handleSize` | 15 | 15 | **44** | T3 RULED (a): glyph = box, a 44 px drawn grip (§2.5) |
| `scrollBarsThickness` | 10 | 10 | **12** | now the FAT (hovered) indicator width |
| `scrollIndicatorThickness` **(NEW, G4)** | — | — | **4** | the thin overlay width |
| `scrollIndicatorLingerMs` **(NEW, G4)** | — | — | **800** | full-alpha hold after last scroll activity |
| `scrollIndicatorFadeMs` **(NEW, G4)** | — | — | **250** | quantized fade span |
| `scrollIndicatorFadeSteps` **(NEW, G4)** | — | — | **4** | alpha quantization (the dwellRingSteps idiom) |
| `menuHeaderCornerRadius` | 3 | 3 | **4** | proportion nudge, owner's taste |
| `menuRowsBorder` | 2 | 2 | **2** | unchanged |
| `toolThumbnailSize` | 30 | 30 | **44** | tool thumbs are targets (G3) |
| `toolInternalPadding` | 5 | 5 | **6** | breathing room at 44 |
| `toolExternalPadding` | 10 | 10 | **10** | unchanged |
| `toolRows` | 2 | 2 | **1** | RULED 2026-08-24 (iPad convention); overflow pops via the chevron, §2.7 |
| `toolbarDockThickness` | 95 | 95 | **70** | = 44 + 6 + 2·10 (thumb + one internalPadding of allowance + margins), entered as a VALUE (F2). The tree's strict 1-row grid is 2·ext + thumb = 64; today's 95 likewise exceeds ITS strict 2·30+5+20 = 85 — the constant has always carried allowance |
| `dockBandDepth` | 30 | 30 | **50** | ≥ the new bar strip (its own comment's rule) |
| `prompterFontSize` | 12 | 12 | **14** | prompter family joins the scale (G3 amendment 2026-08-24) |
| `prompterSliderSize` | 10 | 10 | **44** | the prompt input slider's cross axis IS its thumb target (G3 amendment; F21 — `NumberPromptWdgt` commits it as the slider's height) |

Unchanged on purpose: `shortcutsFontSize`, `textInButtonsFontSize`, the window-bar colours,
`outlineColorString`, `grabDragThreshold`, `dwellToArmMs`, `dwellRingSteps`, `wheel*`,
`useSliderForInput`/`useVirtualKeyboard`/`isTouchDevice` (F15).

**Derived consequences the reviewer must expect (step A):** window/card bar strips 26 → 50 with
44-slot buttons drawing 24-glyphs; frame body margin (`_chromePadding` = `barPadding`) 5 → 3;
menu rows 15 → 44 with vertically centred labels (prompt Ok/Close rows included, F21); menu
title strips floored at the row dial (§2.3); the ~10 `handleSize`-band app layouts (F11)
thicken, and the handle draws a 44 px grip (T3-a); docked strips become ONE 44 px row at
thickness 70 with a trailing chevron wherever tools overflow (§2.7); prompt input sliders
10 → 44 tall; every `ListWdgt` row 44; collapsed frames' tap-bands 50 (C13/C17 carried
through the bar formulas).

### 2.2 The `_makePrettier` fold (the suite finally shows the product)

Delete `WorldWdgt._makePrettier`; its preference assignments become the block's values (the
"product today" column IS the "proposed" column for every folded row). `createDesktop` keeps
`@setColor Color.create 244,243,244` and RECEIVES `@wallpaper.setPattern "dots"` — today the
deleted method's last line (desktop furnishing, not a preference, so it MOVES, not folds). Product pages are pixel-UNCHANGED by the fold (they already ran these
values); the suite moves — which is the point: after the wave, the references pin the chrome
the owner approved on the probe page (reframe 1). **RULED 2026-08-24: the fold is IN**
(G5 amendment — recorded in the ledger, not re-arguable here).

### 2.3 T11 — the per-device toggle deleted (P1, zero-recapture)

- Delete the world-menu row (`WorldWdgt.coffee:3220–3226`) and its explanatory comment.
- `PreferencesAndSettings`: fold `setMouseInputMode`'s body into the constructor (the block
  keeps its G2 grouping comments); delete `setTouchInputMode`, `toggleInputMode`, `inputMode`,
  `INPUT_MODE_MOUSE`/`INPUT_MODE_TOUCH`, `dataflowValue`, `currentInputMode` (the last two
  exist only for the row's reflection — verify no other consumer:
  `grep -rn "currentInputMode\|dataflowValue" src/` must show only the prefs class and
  unrelated classes' own `dataflowValue`s). Reword the class doc-comment (:20–25) and
  `MenuRowReflectionSpec.coffee:4`'s example (F19: the `keptByReferenceOnDeepCopy` /
  `wellKnownKey` flags STAY).
- Tests repo: remove the `toggleInputMode` `KNOWN` entry
  (`scripts/menu-click-sweep-headless.js:64`).
- **Also in P1: the row-height plumbing at today's pixels.** Introduce `menuRowHeight: 0` and
  make `MenuItemWdgt._createLabel` honour it as a MINIMUM: row height =
  `Math.max @label.height(), preferences.menuRowHeight`, label vertically centred with rounded
  offset (`Math.round (rowH - labelH) / 2` — integer-placement law); the pop-up title strip
  (`_transientBarSpec`) thickness becomes `Math.max textHeight + 2, preferences.menuRowHeight`
  (the title is a tap-to-pin TARGET, C3). At 0 the maxes are identities ⇒ byte-identical, and
  the mechanism is proven before the values move. (Do NOT pre-introduce the G4/T3 preferences
  here — fields nothing reads yet say nothing and invite drift; they land with their consumers
  in P3.)
- Gate: `fg presuite` **byte-identical**, `fg menusweep` green (its breadth count shifts by the
  removed row — breadth, not a ratchet). If presuite shows ANY diff, the likely mechanism is an
  inspector member-list churn from the deleted members — that would mean some reference DOES
  show a prefs inspector, falsifying F7: STOP, re-measure, take it to the coordinator.

### 2.4 G4 — scrollbars become overlay indicators (the behaviour half of the wave)

ONE seam: `ViewportWdgt` owns every scrollbar in the system (F8; the five subclasses inherit).
The spreadsheet has no `SliderWdgt` bars (verified) and is untouched.

1. **Keep the two `SliderWdgt` children.** Their wiring (`trackTarget`, `isWiredTo`, the §P8
   announcement lane, serialization) is load-bearing and stays. They gain an indicator
   PRESENTATION state the viewport derives and applies: `indicatorMode ∈ 'hidden' | 'thin' |
   'fat'` plus a quantized `indicatorAlphaStep`. Thin: width/height =
   `scrollIndicatorThickness`, thumb-only painting (no track), rounded thumb; fat: today's
   full painting at `scrollBarsThickness`. A separate overlay class was considered and
   rejected (§8).
2. **Appear on scroll ACTIVITY, never on layout.** The viewport stamps
   `@_scrollActivityEventTime = WorldWdgt.timeOfEventBeingProcessed` at the USER-scroll entry
   points only — the wheel handler, slider-thumb/track interaction, drag-scroll
   (foreground/background), edge auto-scroll, momentum glide steps — never inside
   `_reLayoutScrollbars` (which resize/arrange also calls, F8). Plus one REVEAL case:
   when overflow is BORN (a pane first becomes scrollable, incl. an over-tall menu opening),
   stamp once — the macOS "flash on reveal" that keeps scrollability discoverable (C10's
   capped menus depend on it).
3. **Fade on the dual clock (F14's idiom, verbatim shape).** elapsed =
   event-clock under the Automator, wall-clock in production. Alpha: 1 while
   elapsed < `scrollIndicatorLingerMs` or the pointer hovers the band or a thumb-drag is live;
   then `scrollIndicatorFadeSteps` quantized steps across `scrollIndicatorFadeMs`; then
   hidden. While an indicator is live the bar steps (registered stepping widget, deregistered
   at hidden — bounded cost) and calls `_changed()` ONLY when its quantized step moves — so
   between drained events the pixels are FROZEN, and a macro screenshot after a scroll always
   lands on a deterministic step. **This is the determinism answer, stated:** captures are
   stable because the fade clock is the event clock under the Automator (frozen between
   events), the alpha is quantized, and the witness macros advance event time explicitly to
   reach the faded end-state; no wall-clock decision exists on the suite path
   (DETERMINISM.md's contract; the analog-clock/charging-ring precedents).
4. **Fatten under the hovering pointer (G4), event-driven.** A thin/hidden indicator must not
   catch the pointer (G3: indicators are NOT targets) — so hover cannot be its own
   `mouseEnter`. The VIEWPORT is always in the hand's mouse-over ancestry for content under
   the pointer, so the viewport's per-event hover pass checks pointer-in-band (within
   `scrollBarsThickness` of the scroll edge — the `:1029`-family inset precedent) and flips
   fat/thin. Fat ⇒ the slider catches the pointer again (today's full interactivity:
   thumb-drag, track-jump). On a finger there is no hover — plain-drag scrolling is Plan 4's
   grammar (I2) and the indicator stays an indicator; nothing here forks on pointerType.
5. **Decouple scrollability from visibility (F9).** Add
   `ViewportWdgt.isScrollableNow()` (overflow ∧ policy ≠ 'never') and re-key the two
   drag-scroll gates (`Widget.coffee:4007`, `PanelWdgt.coffee:159`) plus any other
   `anyScrollBarShowing` consumer P0's grep finds. `anyScrollBarShowing` itself stays for the
   genuinely-visual askers or is retired if none remain (`check-dead-methods` decides).
6. **Hit-test opt-out in thin state:** the slider answers `catchesPointerAt` false while
   `indicatorMode` is 'thin'/'hidden' (clicks pass to content under the band) and true when
   'fat' — the F10 members, used as designed.
7. **Transients:** `_scrollActivityEventTime`, `indicatorMode`, `indicatorAlphaStep` go on the
   `@serializationTransients` list (F19); a deserialized world wakes with indicators hidden.
8. **The resizer-corner clearance (:440) stays** — bars still shorten to clear the handle.
9. **Witness tests (NEW references, authored per `/author-macro-test`):**
   `SystemTest_macroScrollIndicatorAppearsAndFades` — build an overflowing `ListWdgt`; assert
   hidden-after-settle (event time advanced past linger+fade), wheel it: thin indicator at
   full alpha (screenshot), advance event time past linger+fade with pointer parked away:
   gone (screenshot), and the scroll POSITION held; `SystemTest_macroScrollIndicatorFattensAndDrags`
   — hover into the band: fat (screenshot), thumb-drag scrolls (assert scroll values), leave:
   thin again. Both macros advance time by queueing events (moves at later event times), never
   by waiting.

**Deliberately NOT deferred:** hover-fatten and the fade are IN this wave (G4 names all three
behaviours). The one G4-adjacent deferral: on-finger discoverability beyond the reveal-flash
(e.g. bounce/rubber-band hints) — not ruled anywhere, goes to the program tail as a Plan 4
grammar question if the owner wants it at all (§5 P5 tail).

### 2.5 T3 RULED — the resize handle: big glyph, glyph = box

**RULED 2026-08-24 (owner; ledger T3 row): shape (a) — `handleSize 44` and the drawn grip IS
the box.** "What you can hit is what you see": no invisible band, no `handleGlyphSize`
preference, no glyph-inset split on the handle (the ~24-glyph discipline stays for bar
buttons and the chevron, where the box also paints a background). Weighed and NOT chosen, for
the record: a small-glyph-large-hit variant (its invisible 20 px band over content would
catch clicks — F10's "alpha never consulted"), and edge-grab resizing (not wanted; no tail
row — the ledger says so). The ~10 `handleSize` layout consumers (F11) follow the 44 box
automatically; `HandleAppearance`'s grip must draw well at 44 (confirmed by eye at the P2
probe, where one band consumer — the Bin or the error console — is also shown).

### 2.6 G6 — the test world scales with the geometry (wave step B)

- **The rule, and the ruling:** scale the harness extent with the geometry. **RULED
  2026-08-24 (G6 amendment): factor 2 — 960×440 → 1920×880** (CSS strings and the
  `background` div 960×720 → 1920×1440 scale with it). Argued honestly against the census
  (F18): today's row is 15 px, so the STRICT row ratio is 44/15 ≈ 2.9 → factor 3, which is
  9× the pixel area — rejected on suite cost (compare/hash/render are per-pixel). At factor 2
  chrome's share of the world grows rather than holds: a ten-row menu is 171/440 ≈ 39% of the
  world today and (440 + ~46 header) / 880 ≈ 55% after — within taste, and every
  overflow/fit fixture keeps its MEANING (what overflowed still overflows, what fit still
  fits, with room to spare). The ruling is re-turnable at zero cost until P4 lands the extent
  (nothing before P4 depends on the number); the pre-offered fallback if P4's measured suite
  cost blows the envelope is 1.5 → 1440×660 (integer at cpr 1 and 2, so legal).
- **Edit sites (the complete set — F12):** `_sizeCanvasToTestScreenResolution` (the one
  method), the three runner viewports (1100×800 → 2040×1000 at factor 2), and the harness
  comment in `SystemTestsReferenceImage.coffee:45`. Completion check: `grep -rn
  "960\|1100" Automator-and-test-harness-src scripts` shows only prose that P5 rewords.
- **Blast radius, stated:** all 287 screenshot-bearing tests, 3,756 files, recaptured at dprs
  1+2 (reframe 3); reference bytes grow ~4× at factor 2 (repo `tests/` today 39 MB — expect
  roughly +80–120 MB; PNG compresses flat regions well, P4 records the real number). Suite
  wall-time grows with pixel area (compare/hash is per-pixel) — measured at P4, expected
  within the presuite/gauntlet envelope; if it blows the envelope the factor question goes
  back to the owner (stop rule: unruled decision). Contingency if dpr2 legs strain shard
  memory at the new extent: lower `AutomatorPlayer.FULL_FAILURE_IMAGE_BUDGET` (24 → 8) — a
  tests-repo constant whose comment explains exactly this failure mode.
- **Macros are extent-robust by construction** (they ask the live world; F12's 18 hits are
  prose/coincidence), but any test that ASSERTED a fit ("menu taller than the world") keeps
  its meaning only because chrome and world scaled together — that is G6's whole point; the
  over-tall-menu test (F18) is P4's canary: it must still scroll.
- **The Automator version bump rides THIS step** (reframe 4): `0/2/0 → 0/3/0` in
  `SystemTestsSystemInfo`'s constructor, same commit as the extent change; `check-refs` then
  refuses any straggler at 0.2.0, making the step-B recapture structurally complete.

### 2.7 T2 ABSORBED — the toolbar overflow chevron (the `toolRows 1` pair)

**RULED 2026-08-24 (ledger T2 row): with `toolRows 1`, the chevron is part of the
single-geometry toolbar answer, not an optional refinement** — a docked strip shows as many
44 px tools as fit and a trailing chevron pops the remainder as a menu (macOS/iPad toolbar
convention; T2's live motivation: the grip bar eats strip length, and today Docs Maker's last
tool already sits behind the strip's scroll). The mechanics stand on F22.

1. **Fit count is the arrange's own arithmetic.** `ToolPanelWdgt._layOutOwnContents` already
   computes the wrap against the strip's available run (`widthContentsMustFitWithin?()`,
   F22). For a one-row strip: fit = `Math.floor((available − 2·externalPadding +
   internalPadding) / (thumbnailSize + internalPadding))`, reserving the TRAILING slot for
   the chevron iff cellCount > fit. Cells beyond the visible prefix are hidden BY the layout
   — visibility as layout OUTPUT is legal (the ghost principle bans it as INPUT); the panel's
   children list stays the ONE source of truth, nothing reparented or destroyed.
2. **The chevron is one leaf in the existing icon-button family** —
   `OverflowChevronButtonWdgt extends IconButtonWdgt` (the bar-piece vocabulary, F22; no new
   widget family) — laid out as the trailing cell: a `thumbnailSize` (44) target drawing a
   ~`barGlyphSize` (24) chevron inset (G3). It exists ONLY while fit < count, built and
   retired by the same layout pass that hides cells, through the NoSettle cores — the
   `FrameWdgt._reDeriveBarRosterNoSettle` construction idiom (F22); a derive that CONSTRUCTS
   runs only inside a flush, and P3's gauntlet settle leg is the gate that catches it done
   wrong. When everything fits there is NO chevron — a control charging rent nothing asks
   for is the P2 bind-row lesson.
3. **The remainder menu is a transient `MenuWdgt` DERIVED at pop time**: the chevron's action
   builds it from the currently hidden cells — one `MenuItemWdgt` per hidden tool, label an
   `[icon, string]` tuple (`MenuItemSpec` already supports it), target/action = the same
   dispatch a tap on that grid cell makes. Rows are `menuRowHeight` targets like every other
   row. NO tracking wiring: derived-at-open + transient lifetime IS the one-staleness-signal
   answer (the P5/P7 rows-as-views lesson) — a strip that re-arranges under an open remainder
   menu dismisses it like any transient pop-up, never updates it in place.
4. **Vertical docks:** a left/right strip is one COLUMN; the fit axis is the strip's own
   axis — the same arithmetic over height.
5. **Witness test** (NEW references, `/author-macro-test`):
   `SystemTest_macroToolbarChevronPopsOverflow` — dock a strip sized so k of n tools fit:
   chevron present (screenshot); click it: the remainder menu lists exactly n−k tools
   (assert labels, screenshot); trigger one (assert the tool's action ran); resize so all n
   fit: chevron GONE (assert absent — the no-rent half).

### 2.8 Disposition table — every current member this plan touches

| today | fate |
|---|---|
| `PreferencesAndSettings.setMouseInputMode` | body folded into the constructor (P1) |
| `setTouchInputMode` / `toggleInputMode` / `inputMode` / `INPUT_MODE_*` / `currentInputMode` / `dataflowValue` | DELETED (P1, T11) |
| the world menu's "touch screen settings" row + its `MenuRowReflectionSpec` | DELETED (P1); menusweep `KNOWN` entry removed with it |
| `WorldWdgt._makePrettier` | DELETED; preference writes folded into the block (P3, owner-gated §2.2); the desktop colour stays in `createDesktop` and the `@wallpaper.setPattern "dots"` call MOVES there |
| the §2.1 dial values | retuned in ONE block edit (P3, at P2's ruled values) |
| `menuRowHeight` (new) | introduced at 0 in P1 (pixel-neutral minimum), turned in P3 |
| `MenuItemWdgt._createLabel` | honours the row-height minimum, centres the label (P1) |
| `FrameWdgt._transientBarSpec.thickness` | floored at `menuRowHeight` (P1 at 0 = identity; live in P3) |
| `ViewportWdgt` bars (`hBar`/`vBar`, `SliderWdgt`) | KEPT; gain indicator presentation state + dual-clock fade + hover-fatten (P3, §2.4) |
| `anyScrollBarShowing` consumers (Widget :4007, PanelWdgt :159) | re-keyed to `isScrollableNow()` (P3) |
| `HandleWdgt`/`HandleAppearance` + `handleSize` consumers | T3(a) applied: 44 box, glyph = box (P3, §2.5) |
| `ToolPanelWdgt._layOutOwnContents` | one-row fit count + trailing chevron slot + hidden-overflow prefix (P3, §2.7) |
| (nothing) | NEW: `OverflowChevronButtonWdgt extends IconButtonWdgt` + its pop-time remainder `MenuWdgt` (P3, §2.7) |
| `PromptWdgt`/`NumberPromptWdgt` prompter chrome | rides the dials — Ok/Close rows via `menuRowHeight` (F21), slider 44 (P3) |
| `WorldTestSupport._sizeCanvasToTestScreenResolution` + 3 runner viewports | scaled by the ruled factor (P4) |
| `SystemTestsSystemInfo` version | 0/2/0 → 0/3/0 (P4, with the extent) |
| every committed reference (3,756 files) | recaptured twice: step A (dials, reviewed via diffpage) and step B (extent, sampled review + version gate) |
| `useSliderForInput`, `isTouchDevice`, `useVirtualKeyboard`, the L1 macro verbs, widget dispatch names | UNTOUCHED (T7 / Plan 4) |

---

## §3 The axes (why this shape)

- **Delete the toggle BEFORE the wave, not inside it.** T11 is reference-invisible (reframe 2),
  so it can gate byte-identical — and a zero-recapture phase is a categorically stronger gate
  than a reviewed one. Everything that moves pixels is then values-and-behaviour only.
- **One preference block, then one edit.** The fold (§2.2) is what makes "the wave is a
  one-block edit" TRUE rather than nearly-true; without it every dial is written twice and the
  suite keeps certifying chrome nobody ships.
- **Two capture steps, one wave.** The program's "ONE recapture" is one ARC of deliberate pixel
  change, reviewed and owner-gated (program §4 rules 2–3) — not literally one invocation of the
  capture tool. Splitting dials (reviewable diff at constant extent) from extent (trivially
  all-different) preserves the only meaningful review the wave can have, and two commits keep
  the batch bisectable (the reference-grammar arc's committed-tolerance lesson). The recapture
  runs are background and cheap relative to a blind wave.
- **The event clock, not a switch.** The fade could have been "instant under the harness" — a
  per-page behaviour fork, exactly the class G1 exists to kill, and a suite blind spot. The
  dual-clock idiom (F14) is already the house answer: same code path, deterministic under
  capture, animated in production.
- **Keep the sliders, restyle them.** The bars carry tracking wiring, announcement lanes and
  serialization arms that a parallel overlay class would duplicate line for line (the P5/P7
  "rows as views" lesson: one widget, one staleness signal). Presentation state is cheap;
  a second controller family is not.
- **The bump is not optional and not conservative.** The version means "what the harness
  captures"; the harness's canvas IS what it captures. Bumping at step B costs nothing (the
  recapture is total anyway) and buys the `STALE AUTOMATOR VERSION` build gate as the
  completeness proof. Not bumping would leave 0.2.0 references describing a harness that no
  longer exists — silently satisfiable forever (the tests-repo CLAUDE.md's own warning).
- **Hit-beyond-ink via the appearance's shape, not a new hit API.** `catchesPointerAt` already
  separates surface from ink (F10); the bar buttons prove the slot/glyph split; the handle and
  the thin indicator are the same two members answered differently. No new mechanism.

---

## §4 The distilled argument

Plans 1 and 2 spent two arcs making this plan small: every chrome dimension now has one name in
one file, every bar and band is a formula over those names, and the input plumbing no longer
cares which device is attached. What remains of "touch support" is a value problem (one block
of numbers), one genuinely new behaviour (indicator scrollbars — a bounded state machine on one
class, with a house idiom for its clock), one deletion (the per-device toggle, provably absent
from every reference), and one harness constant (the world extent). The risk profile is
inverted from a normal arc: the code is easy and the PIXELS are the deliverable — which is why
the sequencing is probe-first (the owner sees the geometry live before a single reference
moves), why the wave is split where reviewability changes character, and why the version
grammar is used to make the final recapture self-enforcing. When this closes, Plan 4 captures
finger tests against a geometry that will not move under it.

---

## §5 Phases

Each phase: goal · steps · pixel impact · gate · commit. **Recapture budget: ZERO in P0–P2;
P3 = the reviewed step-A set (every diff must be a stated §2.1/§2.4/§2.5/§2.7 consequence);
P4 = the whole suite (extent + bump). Anything outside the budget at any gate: STOP (worker
rule 3) — the coordinator eyeballs `fg diffpage` and takes it to the owner. Never a silent
recapture.**

### P0 — Re-verification + measurements (~¼ session-day)

1. `fg status`; a green gauntlet baseline must exist for the current heads (run one in the
   background if the tree moved).
2. **Sonnet, read-only:** re-verify the §1 facts with the recorded commands; report drift
   (the coordinator amends §1 before P1 briefs — a plan's premises are hypotheses).
3. **Sonnet, probe (from this stated spec):** `Fizzygum-tests/.scratch/geometry-census.js` —
   boot the BUILT harness page headless; build a 10-row menu and read
   `row.height()`, `menu.height()`, a `FrameWdgt`'s bar thickness, a `ListWdgt` row height, a
   scrollbar's width; print them. These are the "today" numbers the probe page and the G6
   factor arithmetic cite (as executed: F18 and the STATUS box carry them — row 15 px).
4. **Sonnet:** the completion greps into the STATUS box: `anyScrollBarShowing` consumers,
   `handleSize` consumers, `960|440|1100` in the tests repo, `openMenuOf` world-target
   re-check, references count. These are P3/P4/P5's completion checks.
5. Nothing committed.

### P1 — T11 deletion + row-height plumbing, byte-identical (~⅓ session-day)

One Opus worker, one commit. Steps: §2.3 in full (src + the menusweep `KNOWN` entry;
`MenuRowReflectionSpec`/prefs doc-comments reworded present-tense).
**Gate:** `fg presuite` **byte-identical** (318/0, zero diffs) + `fg menusweep` OK. The build's
28 gates run inside presuite (`check-dead-methods`/`check-unresolved-sends` net the verbs).
Commit (coordinator proposes; owner approves).

### P2 — The probe page (G7) — the owner-review GATE (~½ session-day + owner time)

The probe is **the dev build of the working tree with §2.1's ruled/proposed column applied** — no
committed probe artifact, no product-build pollution, no new entry page (F17):

1. **Opus worker:** apply the §2.1 ruled/proposed values + the §2.2 fold + a FIRST CUT of
   §2.4 (indicators), §2.5's 44 px grip and §2.7 (one-row strip + chevron) to the working
   tree; `fg build` (dev profile). Report what compiled/renders; do NOT run the suite
   (pixels are moving by design; nothing commits from this tree state until P3's review).
2. **The owner opens `/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-builds/latest/index.html`**
   (one step — the coordinator hands exactly this path). The scene, two clicks: right-click
   the desktop → the world menu at the ruled row height; click the "Docs" desktop icon →
   a `DocumentWdgt` WINDOW with its docked `TextToolbarWdgt` as a ONE-ROW strip — narrowed
   until the chevron appears and its remainder menu pops (§2.7). Scrolling any overflowing
   pane shows the indicators live (appear/fade/fatten — wall clock on this page, F14). The
   window's resizer shows the T3(a) 44 px grip; the Bin/error-console shows a `handleSize`
   band consumer (§2.5); a number prompt shows the 44 slider + row-height Ok/Close (F21).
3. **Iteration loop:** owner asks for a variant → worker edits the block →
   `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum && ./build_as_soon_as_anything_changes.sh`
   or `fg build` → reload. (Preference values may
   also be poked live from the devtools console for instant A/B — a human tool, no discipline
   gate applies — with a close-and-reopen of the chrome being inspected.)
4. **The headline dials are PRE-RULED (2026-08-24 — the STATUS box lists them; the ledger's
   G3/G5/G6 amendments + T2/T3 rows are the record).** P2 is the eyes-on CONFIRMATION (G7):
   the owner sees every ruled value live and may re-turn ANY dial — a re-turned value is
   recorded in the STATUS box before P3 briefs, and the coordinator notes it on the ledger
   row (an owner ruling may overturn a row — recorded there, never re-argued here). The G6
   factor stays re-turnable at zero cost until P4 lands the extent. The author's opening-bid
   values that carry no ruling (barPadding 3, indicator timings, `menuHeaderCornerRadius` 4,
   `toolInternalPadding` 6, `prompterFontSize` 14, …) are confirmed or turned here too.
5. **Pixel impact: none committed.** The working tree stays dirty into P3 (same worker
   continues) or is stashed by plain file backup (never `git stash` — house ban).

### P3 — Wave step A: dials + fold + indicators + handle + chevron, at CONSTANT extent (~1½ session-days)

One Opus worker. Steps:
1. Finalize §2.1 (ruled values), §2.2, §2.4 (all nine points — incl. `isScrollableNow` re-key
   and transients), §2.5 (the 44 px grip), §2.7 (fit count + chevron + remainder menu). The
   THREE witness tests authored — the two G4 ones and §2.7's chevron test
   (`/author-macro-test` skill; macro-source discipline: no `world.evaluateString`, "Macro"
   only trailing) with their own references captured at dprs 1+2.
2. `fg build` (28 gates). Then discovery: `fg suite` in the background → the summary's
   `failed tests (N): [...]` array IS the step-A footprint (expected: most of the 287, F16).
3. **The review (program §4 rule 2):** `fg diffpage --tests-file=<footprint>` (serial dumps;
   it prints the `fg classify` triage table). The COORDINATOR eyeballs consequence pixels —
   every diff must read as a §2.1/§2.4/§2.5/§2.7 consequence (bars 26→50, rows →44,
   indicators replacing bars, 44 grips, one-row strips + chevrons, prompt sliders/rows,
   folded fonts/colours); `fg classify`'s BENIGN? bucket is a
   reading aid, never permission. Anything unexplainable = STOP. A digest (counts per
   consequence family + screenshots of exemplars) goes to the owner with the commit proposal.
4. `fg recapture --auto --dprs=1,2` (background; ⚠ the build from step 2 must still match the
   tree — no edits since). Verdict must be `✅ RECAPTURE COMPLETE`. UNSTABLE entries are
   investigated via DETERMINISM.md, never auto-recaptured — an indicator-state
   nondeterminism would surface exactly here (§6).
5. **Gate:** `fg presuite` green on the recaptured set; `fg menusweep` + `fg pinsweep` OK
   (chrome geometry moved under both sweeps); `fg fuzz` ONCE iff any wait/read plumbing was
   touched by §2.4's stepping (three outcomes; INVALID is not a pass; a fuzz failure is never
   a recapture reason). Then a full `fg gauntlet` (18 legs, background) BEFORE the commit
   proposal: P3 installs a stepping/settle-adjacent state machine — exactly the class the
   `settle`/`capstone`/`revisits` legs exist to catch and presuite structurally cannot (the
   Plan 1 lesson: a hook-path phase never closes on presuite alone). Commit (references + src
   together — one bisectable step).

### P4 — Wave step B: the extent + the version bump (~½ session-day)

1. §2.6's edit set (harness method + 3 viewports + `SystemTestsSystemInfo` 0/3/0 + the
   reference-image comment). Harness `.coffee` changed ⇒ `fg build` FIRST.
2. `fg recapture --auto --dprs=1,2` (background; discovery will find everything stale — the
   bump + the canvas see to it). Verdict `✅ RECAPTURE COMPLETE`; `check-refs` (in the next
   build) proves zero 0.2.0 stragglers.
3. **Sampled review:** `fg diffpage` on a ~20-test cross-family sample (menus, windows,
   lists, spreadsheet, inspectors, fizzytiles, transforms) — the blend column is meaningless
   across a resize; the ref|now columns are the review. The over-tall-menu canary (F18) must
   still scroll; `SystemTest_macroMenuPinnedByHeaderClick` and one docking test confirm chrome
   proportions at the new extent.
4. Record: suite wall-time delta, tests/ size delta, any `FULL_FAILURE_IMAGE_BUDGET` action
   (§2.6). **Gate:** `fg presuite` green; commit (harness + references, one step).

### P5 — Docs, close, tail (~⅓ session-day)

1. **Sonnet ×N (disjoint files):** weave (never append) — `docs/architecture/viewports-and-planes.md`
   (indicator states, the dual clock, `isScrollableNow`), `docs/architecture/lint-and-static-checks.md`
   only if a gate's text names deleted members, `Fizzygum-tests/CLAUDE.md` +
   `DETERMINISM.md` extent mentions (960×440 → the new constant; de-count where possible),
   `src/macros/MACRO-PATTERNS.md`'s bar-visibility gotcha (:1281) re-worded to
   `isScrollableNow`, the harness comments P0's grep listed. `fg doc-narration` after.
2. Program doc (coordinator): STATUS row for Plan 3; the G3/G5/G6/T3 amendment rows carry
   their rulings already — note any P2 re-turn on them (date + reason); T11 and T2 rows →
   closed; tail entries (below).
3. **Gate:** full `fg gauntlet` (18 legs, background, verdict-file peeks — webkit leg
   revalidates the recaptured references cross-engine) and `fg homepage` (the production page
   boots the folded block + indicator chrome). Commit; coordinator runs the close-arc ritual.

**Tail (drain before Plan 4 starts — program §5 rule 2):**
- Pre-filed candidates, each with a destination: finger-side scroll discoverability beyond
  the reveal-flash → Plan 4 (I2 grammar, with T6); `FULL_FAILURE_IMAGE_BUDGET` retune if P4
  deferred it → BACKLOG. (T2 is ABSORBED — §2.7 closes its ledger row with this plan; T3 is
  ruled with no residue: edge-grab was not wanted and gets no row.)
- Anything else discovered lands in the program ledger with a destination, per rule 1.

**ETA (owner preference: upfront):** P0 ¼ (done) + P1 ⅓ + P2 ½(+owner) + P3 1½ + P4 ½ + P5 ⅓ ≈
**~3¼–3½ session-days + owner review + tail.** The program's rough size (§3: "Plan 3 ≈ 1 +
owner review + tail") predates G4's promotion from constants to a full behaviour phase and
T2's absorption (+½, ruled 2026-08-24) — noted here as a sizing correction, not a scope
change. Status updates every ~5 min during long ops.

---

## §6 Central risks and how each is bounded

| risk | where | bound |
|---|---|---|
| A dial value looks wrong only at scale ("silly", G3's fear) | P3 | the probe page shows every dial live BEFORE capture; the owner turns them there (G7 is the gate, not the diff review) |
| Indicator fade/hover is nondeterministic under load | P3/P4 | the clock is the event clock under the Automator (F14 idiom), alpha quantized, `_changed()` on step-move only; witness macros advance time by events; `fg recapture`'s UNSTABLE bucket + the torture tool are the detectors; DETERMINISM.md is the playbook |
| Drag-scroll dies when bars hide | P3 | §2.4 step 5 re-keys the two `anyScrollBarShowing` gates to `isScrollableNow()`; the existing drag-scroll SystemTests are the witnesses (they fail loudly if missed) |
| The thin indicator steals clicks over content | P3 | `catchesPointerAt` false in thin/hidden state (F10); the fat state alone is interactive; the fatten trigger lives in the viewport's hover pass, not on the bar |
| The chevron menu goes stale against the strip, or the chevron charges rent | P3 | the remainder menu is DERIVED at pop time and transient — no tracking wiring (§2.7 point 3); the chevron exists only while fit < count, and the witness test asserts both halves (§2.7 point 5) |
| Chevron construction inside the arrange re-enters the settle | P3 | the NoSettle-core idiom is named (§2.7 point 2, the bar-roster precedent F22); P3's full gauntlet — settle/capstone/revisits legs — is the gate presuite cannot be |
| T11 deletion silently changes a reference | P1 | F7 measured ZERO exposure; the gate is byte-identical presuite — any diff is a STOP and a premise falsification, not a recapture |
| An inspector screenshot pins the deleted members | P1 | same byte-identical gate; the known mechanism (member-list churn) is named in §2.3 so the worker recognizes it in one sentence |
| Step-A review drowns in 287 diffs | P3 | constant extent keeps the blend meaningful; `fg classify` buckets; the review reads by CONSEQUENCE FAMILY (§5 P3.3) with exemplar screenshots to the owner — never "benign churn" |
| Extent change breaks a fixture's meaning (menu no longer overflows, window no longer fits) | P4 | the ruled factor 2 was argued against the measured census (§2.6/F18) and only GROWS chrome's share, the canary tests are named (§5 P4.3), and macros ask the live world (F12) |
| The bump is forgotten or half-applied | P4 | the bump and the extent share one commit; `check-refs`'s `STALE AUTOMATOR VERSION` fails every subsequent build until zero stragglers |
| Suite cost at the new extent blows the inner loop | P4 | measured and recorded at P4; the 1.5 fallback factor is pre-offered; an envelope breach returns to the owner (stop rule: unruled decision) |
| `fg recapture` inconclusive from a stale build | P3/P4 | build-first is a numbered step in both phases and the tool's own guard trips loudly (program §4 rule 4) |
| The fold changes product pixels unexpectedly | P3 | it cannot by construction (product already runs those values, F4); `fg homepage` at P5 is the witness on the production tree |

---

## §7 Verification protocol

- Inner loop: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` — **byte-identical is the
  gate for P1; green-on-recaptured-set for P3/P4**.
- The review pair: `fg diffpage <names|--tests-file=F>` then its `fg classify` table —
  ADVISORY triage; the coordinator's eyes are the gate (program §4 rule 2).
- Recapture: `fg recapture --auto --dprs=1,2`, background, verdict `✅ RECAPTURE COMPLETE`;
  UNSTABLE = investigate, never auto-recapture.
- Runtime sweeps at P3: `fg menusweep`, `fg pinsweep` (chrome moved under both). `fg fuzz`
  once iff wait/read plumbing changed (exit 0/1/2; 2 = INVALID = measured nothing).
- Phase closes P3 and P5: full `fg gauntlet` (18 legs) — P3 before its commit (hook-path
  phase; the deep legs are its real gate), P5 additionally `fg homepage` — background with
  `cat /tmp/fg-<cmd>.verdict` peeks at ~5-min cadence. `[shard N] did not start within 90s` /
  `CoffeeScript is not defined` = boot-storm infra flake; a serial-retry pass = load-flake
  warning, not a FAIL.
- Docs: `fg doc-narration` after the P5 sweep.
- Never pipe a gating `fg` call; never edit mid-run; probes in `Fizzygum-tests/.scratch/`.
- Gates that WILL fire if mishandled (F20): `check-dead-methods`/`check-unresolved-sends`
  (T11 — fix callers, never allowlist), `check-stinks` (present-tense comments),
  `NON_INTEGER_GEOMETRY` (round every centring formula), tests-repo `check-refs` (the version
  gate — the P4 commit must carry bump + references together), `check-visualisations`
  (recapture regenerates pages; do not hand-edit them), `check-macro-source-discipline`
  (the new tests' macros).

---

## §8 Rejected alternatives — do not re-attempt

- **A "touch mode" / per-device geometry in any form** — G1 forbids it; T11 deletes the last
  one. Do not reintroduce a mode, a flag, or a per-page preset for geometry.
- **Keeping `_makePrettier` and dialing both blocks** — two sources for one value re-creates
  the fork G2 exists to kill; the fold is RULED IN (G5 amendment, 2026-08-24).
- **A live-tracking remainder menu (the chevron's menu wired to the strip)** — a view kept in
  sync while closed is rent plus a second staleness signal; derived-at-pop + transient
  lifetime is the P5/P7-compliant shape (§2.7). Likewise a chevron that is always present
  ("for stability") is the P2 bind-row mistake.
- **A small-glyph resize handle over an invisible hit band, or edge-grab resizing** — weighed
  and NOT chosen (T3 ruling, 2026-08-24): the invisible band catches clicks over content, and
  edge-grab was not wanted (no tail row). Do not re-derive; the ruled shape is glyph = box.
- **An instant-under-harness fade (or fade disabled for tests)** — a per-page behaviour fork
  and a permanent suite blind spot; the dual clock (F14) costs one helper and forks nothing.
- **Wall-clock fade timers** — the DETERMINISM.md bug class, verbatim; banned on the suite
  path.
- **A separate overlay-indicator widget class beside the sliders** — duplicates tracking,
  announcement and serialization wiring; presentation state on the existing bars is the whole
  need (§3).
- **Keying hover-fatten on the bar's own `mouseEnter`** — a pass-through widget receives no
  enter; chicken-and-egg. The viewport's band check is the shape (§2.4 step 4).
- **One combined dials+extent recapture** — forfeits the only reviewable diff of the dial
  consequences (reframe 3) and makes the wave un-bisectable; two committed steps inside one
  arc is the program-compliant shape (§3).
- **Skipping the Automator bump ("matching is by hash anyway")** — leaves the tree's
  references describing a dead harness, silently satisfiable forever; the tests-repo
  CLAUDE.md names this exact failure. Conversely, bumping at step A ("to be safe") obliges a
  pointless extra 3,756-file recapture — Plan 2's rejected-alternative, still rejected.
- **Letting two Automator versions coexist "during the transition"** — ⛔ per the reference
  grammar: every reference is SWCanvas, one harness, one version; two versions = one is stale.
- **Scaling the extent by dpr instead of resizing the world** ("run everything at dpr 2.2") —
  dpr is a rendering density axis with its own directory meaning; the world's LOGICAL size is
  what G6 scales, and fixtures' meaning lives in logical pixels.
- **Uniform scaling of every constant by 44/16** — G3's explicit reason: "uniform scaling is
  what looks silly"; three kinds of thing scale three ways.
- **A committed probe page / new entry page / probe part** — pollutes the artifact for a
  one-review scene the dev desktop already stages in two clicks (F17).

---

## §9 Delegation map — coordinator and workers (program §3.1)

The coordinator (the session) never edits source or runs suites; it briefs, reads reports,
checks verdict files, decides at gates, hosts the P2 owner session, eyeballs every diff page,
and talks to the owner. Workers are fresh agents with no conversation context: `Agent` with
`subagent_type: general-purpose`, `model: "opus"` (phase work) or `"sonnet"` (mechanical work).
⛔ Never `fork`, never `isolation: worktree`. **One code worker at a time**; parallel workers
only for read-only work and docs edits to disjoint files.

### 9.1 Per-phase map

| phase | worker | parallel? | brief = plan section + | gate the worker runs | coordinator decides |
|---|---|---|---|---|---|
| P0 fact re-verify | Sonnet ×1 | yes (read-only) | §1's fact commands | none | records drift, amends §1 |
| P0 geometry census probe | Sonnet ×1 | yes (read-only) | §5 P0.3's stated spec | the probe script itself | the "today" numbers into STATUS; G6 arithmetic |
| P1 T11 + row-height plumbing | Opus ×1 | no | §2.3; F3/F6/F7/F19 | `fg presuite` byte-identical; `fg menusweep` | verdicts; commit proposal |
| P2 probe-tree prep + variants | Opus ×1 | no | §2.1 ruled column, §2.2, §2.4 first cut, §2.5, §2.7; F17 | `fg build` only | hosts the owner review; records re-turned dials in STATUS |
| P3 wave step A | same Opus ×1 | no | §2.1 (ruled), §2.2, §2.4 all points, §2.5, §2.7; F8–F11, F15, F19, F21, F22; the witness-test specs | `fg build`; `fg suite` (discovery); `fg recapture --auto --dprs=1,2`; `fg presuite`; sweeps; `fg gauntlet` | THE diffpage review (rule 2); owner digest; commit |
| P4 wave step B | Opus ×1 | no | §2.6; F12/F13; the canary list | `fg build`; `fg recapture --auto --dprs=1,2`; `fg presuite` | sampled review; cost numbers; commit |
| P5 docs sweep | Sonnet ×N | yes (disjoint files) | per file: the P0 grep list + the present-tense paragraph | `fg doc-narration` | reviews diffs |
| P5 close | coordinator | — | — | `fg gauntlet`, `fg homepage` | close-arc ritual, program STATUS/tail, memory, owner |
| tail | per item | per item | the ledger row + destination | as the item needs | ledger bookkeeping |

### 9.2 The worker brief (template — copy, fill the ⟨⟩, nothing else)

```
You are executing ⟨phase/sub-step⟩ of Fizzygum/docs/plans/single-geometry-visual-wave-plan.md.
Read that plan's §0, §0.5 and §⟨phase⟩ in full, then Fizzygum/docs/plans/frames-input-touch-program.md
§2.2 for rulings ⟨IDs⟩ and §4 (recapture policy). Also read Fizzygum-all/CLAUDE.md, Fizzygum/CLAUDE.md
and Fizzygum-tests/CLAUDE.md. All commands through /Users/davidedellacasa/code/Fizzygum-all/fg by
absolute path. Probes under Fizzygum-tests/.scratch/.
Do: ⟨the phase's step list, or "every step of §⟨phase⟩"⟩.
Gate: ⟨exact fg command(s)⟩ → expected ⟨verdict⟩. Launch long ops with run_in_background and wait for
the notification; never poll; never pipe the gating call. Build BEFORE any fg recapture.
Pixel budget: ⟨P1: ZERO — any diff is a STOP. P3: every diff must be a stated
§2.1/§2.4/§2.5/§2.7 consequence; list the footprint, produce fg diffpage, do NOT recapture until
the coordinator approves. P4: the whole suite; the version bump and the extent share your one
commit.⟩
Stop and report (do not improvise) if: a §1 fact is false; a fix shape is falsified twice; a gate
fails for a reason you cannot state in one sentence; a diff appears outside the budget; you need a
decision the ledger and the P2 rulings do not cover. Never recapture without the coordinator's
approval, never commit, never push.
Comments you write: present tense only, no history narration. `undefined` is the one absence value.
Report (≤ 60 lines): files changed (git diff --stat, both repos); each gate's literal
/tmp/fg-<cmd>.verdict line; counts measured; tests added/changed; the recapture verdict line if any;
open questions; which stop rule fired, if any.
```

### 9.3 What the coordinator checks on every report (cheap, never a re-do)

1. `cat /tmp/fg-<cmd>.verdict` for each gate the report claims — the literal line, not prose.
2. `git -C <repo> status --short` + `git diff --stat` in BOTH repos — the changed-file list
   matches the phase (P1 touches `src/` + one tests-repo script; P3 touches `src/` + new test
   dirs + recaptured references; P4 touches harness + scripts + references and NOTHING in
   `src/`; a stray file is a question).
3. P3/P4: the diffpage exists and the coordinator LOOKS at it (the one visual judgement it
   keeps), classify table read as an aid; then the owner digest.
4. A stop rule fired → read ONLY the quoted evidence; amend §1 or the brief; re-brief. Two
   stops on the same step → re-frame (never a third variant).
5. Then: commit proposal to the owner, or the next brief.

---

## §10 References

- Program: [`frames-input-touch-program.md`](frames-input-touch-program.md) — §2.2 rulings
  (G1–G7; G3/G5/G6 amended 2026-08-24), §3 sequencing + §3.1 execution model, §4 recapture
  policy (rules 2–4 govern P3/P4), §5 tail rules (T2 absorbed here, T3 ruled, T6, T7, T11),
  §6 just-in-time authoring.
- Plans 1–2 (closed): [`../archive/frame-lifetime-and-docking-plan.md`](../archive/frame-lifetime-and-docking-plan.md)
  (the bar-spec family this plan retunes; §9 the delegation-map shape),
  [`../archive/pointer-events-plan.md`](../archive/pointer-events-plan.md) (the §9 this §9
  copies; the no-bump precedent §8 inverts for step B).
- Living truth to update at P5: [`../architecture/viewports-and-planes.md`](../architecture/viewports-and-planes.md),
  [`../architecture/lint-and-static-checks.md`](../architecture/lint-and-static-checks.md) (only
  if gate text names deleted members), `Fizzygum-tests/CLAUDE.md` + `DETERMINISM.md` (extent
  prose), `src/macros/MACRO-PATTERNS.md` (:1281's bar-visibility gotcha).
- Doctrine the executor must hold: `Fizzygum-tests/DETERMINISM.md` (§1 contract, §3 cadence +
  case law), `Fizzygum-tests/CLAUDE.md` (the reference grammar, the bump rule, `fg recapture`'s
  completeness gate, `refpaths.js` as the one parser), `Fizzygum/src/macros/CLAUDE.md` (input
  through the queue), [`../architecture/integer-pixel-placement-and-sizing.md`](../architecture/integer-pixel-placement-and-sizing.md)
  (every new centring formula rounds).
- Memory notes the executor should know exist: ask-before-commit/push; long-op ETA + ~5-min
  status; no conclusions before evidence; stop after two falsified fixes; recapture is a
  decision to BELIEVE the pixels — eyeball consequence pixels, never "benign churn"; a
  tolerance/batch must be COMMITTED to stay bisectable (reference-grammar arc); `fg recapture
  --auto` needs a fresh build first; perl/sed blanket edits de-indent `.coffee` — use the Edit
  tool; the scroll-thumb dpr2 nondeterminism case (colour-state toggles on shared state) — the
  indicator state machine is exactly the shape to keep per-instance and event-driven.
- Precedents cited by the rulings (program §7): Apple HIG 44-pt targets and ~50-pt iPad bars;
  macOS Lion overlay scrollbars (thin, appear-on-scroll, fatten-on-hover); Fluent's 40-px
  touch floor.

---

### Start-prompt for a fresh coordinator session (copy-paste)

> You are the COORDINATOR for Plan 3 of the frames·input·touch program. Read
> `Fizzygum/docs/plans/single-geometry-visual-wave-plan.md` IN FULL, then the program doc's
> §2.2/§3.1/§4/§5. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status` and verify heads ≥
> the plan header's (Fizzygum `bf6e494e` / tests `341ad470c`); if the tree moved, expect §1
> drift and re-verify before briefing. Execute per the plan's §9 delegation map, phases P0→P5,
> one code worker at a time, briefs from the §9.2 template. The headline dials are PRE-RULED
> (2026-08-24 — the STATUS box and the ledger's G3/G5/G6/T2/T3 rows); P2 remains the OWNER
> GATE where every ruled value is confirmed by eye and may be re-turned before any capture.
> Pixel budget: zero through P2; P3/P4 are the program's one reviewed recapture wave — you
> eyeball every diff page yourself. Ask the owner before every commit/push.

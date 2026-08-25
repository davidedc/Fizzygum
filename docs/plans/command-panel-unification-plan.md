# Command-panel unification — ONE command model, two projection axes (T1 as expanded)

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-25 against Fizzygum `0d254caa` / Fizzygum-tests `10e5d6151` (suite 321
SystemTests at 1920×880, Automator 0.3.0, both trees clean, gauntlet-green heads). Every
`file:line` was verified on that date — **line numbers DRIFT; the method name / quoted code is
authoritative, so `grep` before trusting a number.** Plan 3.5 of the program
[`frames-input-touch-program.md`](frames-input-touch-program.md): the decision this plan
implements is **the tail-ledger T1 row AS EXPANDED BY THE OWNER 2026-08-24** (the command
model + the two projection axes + the chevron re-projection licence), together with the
rulings it stands on — **C16** (toolbar ⇄ menu is a payload-arrangement axis), **C11** (a
toolbar is a PAYLOAD, never a container peer), **C14** (menus/prompts are framed citizens
with the delegated row API untouched), **C5** (rosters/adjacency are DERIVED at arrange),
**C10** (the hugging-payload world cap), and the §2.2 G-rows for sizes (**G1** one geometry;
**G3** targets ≥ 44 / glyphs ~24 inset; **G5** `menuRowHeight` 44 + paint-only separators).
Also this plan's, by explicit routing (Plan 3 round 6, 2026-08-24, recorded in the archived
plan's STATUS box): **`PaintToolbarWdgt.dockThickness: 103`** — the Draw palette, a
`RadioButtonsHolderWdgt` on the dock duck contract, "stays a declared constant with Plan 3.5
as its destination — the command-panel unification absorbs the Draw palette and the
derivation comes free there". Cite these IDs; do not re-argue them. Plans 1–3 are EXECUTED
AND CLOSED (archived); this plan is authored against the post-Plan-3 tree per the program's
just-in-time rule (§6).

**Ledger drift, report-only (the dated ledger rows stand as history; facts below are the
tree's):**
- C14's counts have drifted on this tree: `new MenuWdgt` is **47** (ledger: 45);
  `addMenuItem`/`prependMenuItem` framework call sites are **322** (ledger: 315).
- ⚠⚠ **The T1 row's proof sentence is FALSIFIED on this tree.** The row says "The Plan 3
  chevron's derived remainder menu (`[icon, string]` rows) is the live proof the projection
  works." The remainder menu's rows are **STRING-labelled** —
  `OverflowChevronButtonWdgt.actOnClick` passes `(tool.toolTipMessage ? tool.colloquialName())`
  and nothing else — and the `[icon, string]` tuple exists ONLY as a comment claim on
  `MenuItemSpec.label` / `MenuItemWdgt`'s spec note, with **no mechanism behind it and zero
  callers** (F3). What Plan 3 proved live is the DERIVE-AT-POP re-projection and the one
  dispatch contract; the display axis has **no live proof yet** — building its first consumer
  is this plan's P2, not a confirmation.

**STATUS BOX** (fill per phase as executed)
- PRE-RULED 2026-08-25 (owner, at the plan review): **OD1 = (a)** `CommandPanelWdgt` +
  `CommandSpec` (the rename sweep is declared work) · **OD2 = (a)** the chevron's remainder
  rows go icon+label (the display axis's first consumer; small declared set). OD3 (the Draw
  palette's derived look) stays an eyes-on decision at P4 as authored.
- P0 re-verification + measurements: —
- P1 the command record + the display mechanism (inert): —
- P2 first display-axis consumer — the chevron's remainder rows go icon+label (reviewed set): —
- P3 the panel unification (structural, the migration executed): —
- P4 the Draw palette rides the unified panel (reviewed set; the 103 dies): —
- P5 docs + close + tail: —

---

## MANDATE

**Dissolve the two unrelated "bunch of commands" widget families into ONE command panel over
ONE command model** — not a third family beside them, not a compatibility shim. At close:
ONE command record (icon + label + target/action + selection state) that both projections
consume; the **display axis** (`'icon' | 'label' | 'icon+label'`) live with a real consumer
(the chevron's remainder rows show each hidden tool's icon beside its label); the
**arrangement axis** (`'column' | 'grid'`) expressed by ONE panel class with the migration
question answered in code (§2.3 — what survives as a name and what dissolves); the one
dispatch contract (`thumbnailClickReceiver()`) stated as the model's law rather than a
chevron-local fix; **selection state part of the model**, proven by the forcing case: the
Draw palette (`PaintToolbarWdgt`) re-based onto the unified panel, its tools commands, its
selection ONE fact, its `dockThickness: 103` — the tree's LAST declared dock-thickness
constant — dead by derivation. Every unbuilt projection combination is a stated no-rent
decision with a destination, never an implicit gap. Out of scope, each with its address:
the gesture grammar and hover affordances (Plan 4), desktop-edge docking (T5, BACKLOG),
`representativeIcon` (owner-gated BACKLOG residual, untouched).

---

## §0 Orientation

**The project.** Fizzygum is a CoffeeScript GUI framework ("web operating system") rendered
on one HTML5 canvas. Three sibling repos under `Fizzygum-all/`: `Fizzygum/` (source — this
plan edits `src/`), `Fizzygum-tests/` (SystemTests + Automator harness source, served through
the `latest/js/tests` symlink — test edits need NO rebuild; harness `.coffee` edits DO),
`Fizzygum-builds/` (generated, never edited). Every build/test command goes through
`/Users/davidedellacasa/code/Fizzygum-all/fg` (ABSOLUTE path, never `./fg`); bare `fg`
prints the roster. Read the root `CLAUDE.md`, `Fizzygum/CLAUDE.md` and
`Fizzygum-tests/CLAUDE.md` before touching anything. No module system: every class is a
global; one class per file, filename = class name.

**The vocabulary:**
- **The column family (core):** `MenuRowsPanelWdgt` (`src/basic-widgets/menu-system/`,
  extends `VerticalStackPanelWdgt` — the ONE vertical-stack engine) is the pure rows body of
  three consumers: `MenuWdgt` and `PromptWdgt` (framed citizens extending `FrameWdgt`, C14 —
  the panel sits DIRECTLY as the plane of a `PopUpRowsViewportWdgt`, no middle pane: the
  menu-sandwich dissolution) and `ListWdgt` (same panel with `selectsItemsOnClick: true`).
  Rows are `MenuItemWdgt` (a `LabelButtonWdgt`), built from a **`MenuItemSpec`**
  (label + target/action + nine opts incl. `reflection`) — the nearest thing the tree has to
  a command record.
- **The grid family (app-kit, LAZY):** `ToolbarWdgt` (a `ViewportWdgt`) over
  **`ToolPanelWdgt`** (extends `PanelWdgt`): fixed-pitch square cells
  (`toolThumbnailSize` 44), each a `GlassBoxBottomWdgt` (CORE, `src/` root) wrapping one tool
  — with a `GlassBoxTopWdgt` LID (app-kit) over tools that are drag-out templates — plus the
  `OverflowChevronButtonWdgt` the arrange builds and retires (T2, closed in Plan 3). Seven
  `ToolbarWdgt` subclasses supply item lists; the creator-button family
  (`CreatorButtonWdgt` / `ToolbarCreatorButtonWdgt` + `WidgetCreatorAndSmartPlacerOnClickMixin`)
  populates them.
- **The odd one out (authoring, LAZY):** `PaintToolbarWdgt extends RadioButtonsHolderWdgt` —
  the Draw palette; four radio TOGGLE tools (`ToggleButtonWdgt` pairs + `EditableMarkWdgt`
  source-edit marks, 93×55 px buttons), on the frame's dock DUCK contract
  (`dockSide` / `dockThickness` / the collapse cores / `_reLayout` /
  `excludedFromEditorFocusTracking`) rather than the `ToolbarWdgt` construction (an old
  Frame-model owner decision, D10 — superseded for this plan by the T1 expansion + the 103
  routing: D10's stated reason, "its items are stateful radio toggles, not drag-out
  thumbnails", dissolves exactly when the command model carries selection state).
- **The dispatch contract:** `GlassBoxBottomWdgt.thumbnailClickReceiver()` — what a tap on a
  cell actually reaches (the LID if `isGlassBoxLid`, else the tool) — consumed by the
  chevron's `triggerToolFromMenu` so a projection of a command invokes the SAME path as the
  primary projection. One contract, no per-family cases (Plan 3 round-4 item 13's law).
- **The rows-as-views doctrine (P5/P7):** a menu row that shows somebody's value declares a
  `MenuRowReflectionSpec` and subscribes ITSELF (`MenuItemWdgt._subscribeToMyReflectedSource`);
  a widget has ONE staleness signal; a derived pop-up is derived AT POP and transient, never
  live-tracked. Codified in `docs/archive/connector-ubiquity-and-reflection-plan.md`.

**Why this plan exists now.** Plan 1 made chrome derived (lifetime × parentage; roster by
fit), Plan 3 landed the single geometry — and its probe reviews kept running into the SAME
seam from both sides: the chevron had to invent a command projection ad hoc (rounds 3/4: the
dispatch contract, editor-chrome declaration, z-order), and the Draw palette had to be
patched around its non-membership in the toolbar family (rounds 4/6: `radioButtonWasSwitched`
as the ONE fact, `paintingOverlay` via the band, the 103 constant explicitly ROUTED here).
The owner expanded T1 at that probe: the two families are one thing — commands — projected
two ways, and the display axis is the third leg the remainder menu already gestures at.
Landing this BEFORE Plan 4 keeps the finger reference axis from being captured against
payload classes this plan churns (the T1 row's own sequencing reason).

**Critical reframes — do not lose these:**
1. **The display axis is DATA, not a mode.** A row shows an icon iff its command record
   carries one; a grid cell IS the `'icon'` display; a spec without an icon is the `'label'`
   display. No `display` field is stored on any panel — the three values are the three
   shapes the one row/cell vocabulary produces. (A stored display knob would be rent nothing
   reads — the P2 bind-row lesson.)
2. **Arrangement is fixed at construction, so a class MAY express it** — C2's tagged-state
   reasoning cuts the other way here: `lifetime` became a runtime tag because it changes
   mid-life; a panel never re-arranges from column to grid mid-life (the T1 licence "the
   same collection re-projected" is a NEW surface derived at pop — the chevron precedent —
   never a live flip). The "ONE command panel" therefore lands as ONE base class owning the
   model, with arrangement resolved at construction (§2.3), not as an if-ladder tag.
3. **The part boundary shapes the migration.** `core` owns the menu system and
   `src/buttons`; `app-kit` (LAZY) owns the toolbar/creator/lid machinery; `authoring`
   (LAZY, requires app-kit) owns the palettes. An unguarded core→part reference FAILS the
   build (`check-part-edges.js`), and menus are core — so the unified base MUST be core, and
   the template-cell machinery (lids, smart-placer mixin, chevron class) MUST stay behind
   the app-kit seam. That forces a thin app-kit LEAF to survive (§2.3), whatever the naming.
4. **The T1 proof sentence is falsified** (header): the remainder menu is label-only today.
   P2 is the display axis's FIRST consumer, a declared visible change with its own reviewed
   set — not a no-op confirmation.
5. **The class names are load-bearing CROSS-REPO.** `MenuRowsPanelTestSupport.installOnto
   MenuRowsPanelWdgt` runs from Fizzygum's own boot (`src/boot/globalFunctions.coffee:490`);
   `scripts/graph-liveness-headless.js:369` reads `m.rowsPanel.children`; four committed
   macros name `MenuRowsPanelWdgt`, two name `ToolPanelWdgt`, two reach
   `PaintToolbarWdgt` internals, one names `overflowChevron`. Any rename is a TWO-REPO sweep
   (the connector-P9 lesson: grep `Fizzygum-tests/scripts/` too), and renames churn the
   inspector's drawn member lists — pixel exposure is MEASURED in P0, never assumed zero.

---

## §0.5 Cold-execution protocol

**Who executes (program §3.1):** a **COORDINATOR** (the session model, Fable) delegates every
phase to a **WORKER on a cheaper model** — Opus for phase execution, Sonnet for mechanical
sub-steps — via the `Agent` tool (`subagent_type: general-purpose`, `model: "opus"`/`"sonnet"`;
never `fork`, never `isolation: worktree` — the build hard-codes the sibling layout and the
tests symlink). §9 is the delegation map. The steps below are written for the WORKER; the
coordinator runs step 1, briefs per §9, reads reports, decides at gates, hosts the P2/P4
owner reviews, and talks to the owner. **The coordinator does not edit source or run suites
itself.**

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — orient (heads, build freshness,
   test count, zombie browsers → `fg killz`). Expect heads at or after the header's.
2. Read this plan in full, then the program doc §2 (C5, C10, C11, C14, C16; G1/G3/G5) and
   §4 (recapture policy — rules 1–2 govern every phase here) and the T1/T2 tail rows. Then
   read, in this order:
   `src/basic-widgets/menu-system/MenuRowsPanelWdgt.coffee` IN FULL (310 lines),
   `src/basic-widgets/menu-system/MenuItemWdgt.coffee` (245 — `_createLabel`,
   `menuEntryPreferredWidth`, the reflection block, `isListItem`),
   `src/basic-widgets/menu-system/MenuItemSpec.coffee` (52),
   `src/basic-widgets/menu-system/MenuWdgt.coffee` + `src/PromptWdgt.coffee` (the framed
   citizens and their `_buildRowsPayload`), `src/ListWdgt.coffee` (:85 — the
   `selectsItemsOnClick: true` construction),
   `src/basic-widgets/menu-system/PopUpRowsViewportWdgt.coffee` (the measure contract),
   `src/app-kit/ToolPanelWdgt.coffee` IN FULL (232), `src/app-kit/ToolbarWdgt.coffee` (91),
   `src/GlassBoxBottomWdgt.coffee` + `src/app-kit/GlassBoxTopWdgt.coffee`,
   `src/app-kit/OverflowChevronButtonWdgt.coffee` (60),
   `src/authoring/PaintToolbarWdgt.coffee` (525) + `src/authoring/RadioButtonsHolderWdgt.coffee`
   (30) + `src/SwitchButtonWdgt.coffee` (the ONE-fact funnel + the "shown button" pin),
   `src/authoring/TextToolbarWdgt.coffee` (a representative `_toolbarItems`),
   `src/FrameBarWdgt.coffee` — the roster derive (`_pieceNamesThatFit` ~:477,
   `PIECE_DROP_ORDER` :42) as the C5 idiom reference; then
   `buildSystem/parts.json` (the `core` / `app-kit` / `authoring` entries and their `//`
   notes), `docs/architecture/lint-and-static-checks.md` (gates this plan meets),
   `docs/architecture/widget-authoring-guidelines.md` (the pin-setter and reflection
   sections), `docs/architecture/viewports-and-planes.md`, `Fizzygum-tests/CLAUDE.md`
   (reference grammar + recapture tooling), `Fizzygum/src/macros/CLAUDE.md`, and skim
   `docs/archive/menu-sandwich-dissolution-plan.md` (why NO middle pane) and
   `docs/archive/connector-ubiquity-and-reflection-plan.md` P5+P7 (rows as views).
3. Execute phases IN ORDER, P0 → P5. Each phase ends with its own gate (§7) and a proposed
   commit. **Owner preference: ask before every commit/push — present a summary and the
   proposed message (`git commit -F <file>`, never backticks in `-m`), then wait.** P2 and
   P4 each end with an OWNER eyes-on before their recapture — nothing visible lands
   unreviewed (program §4 rule 2).
4. Long ops (`fg gauntlet`, `fg presuite`, `fg recapture`): launch ONCE with the Bash tool's
   `run_in_background` redirected to a log; peek `cat /tmp/fg-<cmd>.verdict` at a ~5-min
   cadence; never pipe the gating call through `| tail`/`| grep`; never edit src/tests/fg
   while a run is in flight. ⚠ `fg recapture --auto` discovers against the EXISTING build —
   build first, never edit mid-run (program §4 rule 4).
5. If a fix shape is falsified twice, STOP and re-frame — never a third variant (owner rule).
6. Comments you write state what IS — present tense, no history narration (`check-stinks.js`
   fails the build on it). `undefined` is the one absence value (`nil` is retired and gated).
7. Probes live under `Fizzygum-tests/.scratch/` (gitignored) — NEVER the session scratchpad
   (Node resolves `require` from the script's directory).
8. Anything this plan defers goes into the program doc's tail ledger with a destination
   (program §5) — never a "for later" in this file.

---

## §1 The system as it stands (verified 2026-08-25; re-verify in P0)

Each fact records its verification command. Line numbers drift — grep the quoted code.

- **F1 — the column panel and its three consumers.** `MenuRowsPanelWdgt extends
  VerticalStackPanelWdgt` (310 lines, core): ONE client knob (`selectsItemsOnClick` — list
  rows SELECT, menu/prompt rows TRIGGER; `MenuItemWdgt.isListItem` dispatches on it via
  `?()`); rows added by the owner after construction (`addMenuItem` → `_menuItemSpecFrom` →
  `new MenuItemSpec` → `_createMenuItem` → `new MenuItemWdgt`); hug-width arrange
  (`_positionAndResizeChildren` :224 — hug, `super()`, `_deriveRowSeparators()`), pure
  measures (`preferredExtentForWidth`, `scrolledContentMeasure` +
  `scrolledContentMeasureIsMyFrame` — the committer contract `PopUpRowsViewportWdgt`
  consumes); `wantsDetachOfChild` = the row-extraction opt-in (an `action`-carrying row off a
  PINNED pop-up). Consumers: `MenuWdgt._buildRowsPayload`, `PromptWdgt._buildRowsPayload`,
  `ListWdgt:85` — exactly 3 `new MenuRowsPanelWdgt` sites. Verify:
  `grep -rn "new MenuRowsPanelWdgt" src/`.
- **F2 — the row, and where its box comes from.** `MenuItemWdgt extends LabelButtonWdgt`;
  `_createLabel` (:129) builds a `TextWdgt` label, commits row extent
  `labelExtent.x + 8` × `max(labelExtent.y, preferences.menuRowHeight)` (44), label at
  `x+4`, vertically centred rounded; `menuEntryPreferredWidth` (:197) reads
  **`@children[0].width() + 8`** — ⚠ a positional assumption (label = first child) any
  icon child must not break. Separators are paint-only (`_separatorAbove`, told by the
  panel's `_deriveRowSeparators` — the C5 derive idiom, ruling G5). Reflection: the row
  subscribes ITSELF (`_subscribeToMyReflectedSource`, one edge per reflecting row,
  `firesOnAnyChange`). Verify: `sed -n '129,160p;197,199p'
  src/basic-widgets/menu-system/MenuItemWdgt.coffee`.
- **F3 — the `[icon, string]` label is a COMMENT, not a mechanism.** `MenuItemSpec.coffee:25`
  ("labelString can also be a Widget or a Canvas or a tuple: [icon, string]") and
  `MenuItemWdgt.coffee:34` claim it; `_createLabel` does `new TextWdgt @labelString` —
  strings only — and **zero callers pass a non-string label** (`grep -rn "addMenuItem \["
  src/` = 0; the only widget-adjacent hits are `target` operands, not labels). The chevron's
  rows (`OverflowChevronButtonWdgt.actOnClick`) pass
  `(tool.toolTipMessage ? tool.colloquialName())` — a string. This falsifies the T1 row's
  proof sentence (header) and is the lie P1 deletes. Verify: read `actOnClick` +
  `grep -rn "Array.isArray" src/basic-widgets src/buttons` (no label consumer).
- **F4 — the grid panel.** `ToolPanelWdgt extends PanelWdgt` (232 lines, app-kit): cell
  dials from preferences in the ctor (`thumbnailSize` 44 / `internalPadding` 6 /
  `externalPadding` 10 — instance fields because callers retune per strip); the pitch pair
  `_cellPitch` / `_cellsFittingIn` and its stated INVERSE `_naturalRunFor`; the sizing
  capabilities **`naturalGridCrossExtent`** (:143 — one strip-depth, PURE, what a dock
  spec's thickness must be) and **`naturalGridExtentWithin room`** (:152 — the hug for a
  free-floating home, capped + quantized DOWN to whole cells, C10); the arrange
  `_layOutOwnContents` (:168 — toolRows against the run, trailing slot to the chevron,
  hidden cells parked in the chevron's slot: visibility as layout OUTPUT);
  `_layOutOverflowChevron` (:214 — build-and-retire through NoSettle cores, the bar-roster
  shape); `cellsBehindTheOverflowChevron` (:120 — CELLS, not tools, "only the cell knows
  what a tap on it reaches"); `_addNoSettle` wraps a non-wrapper tool in a
  `GlassBoxBottomWdgt` + optional `GlassBoxTopWdgt` LID for non-`actionableAsThumbnail`
  tools (templates), and routes the chevron past the wrapping. Verify: read the file.
- **F5 — the ONE dispatch contract.** `GlassBoxBottomWdgt.thumbnailClickReceiver()` (:34 —
  the lid if `isGlassBoxLid`, else `glassBoxItem()`); the chevron's `triggerToolFromMenu`
  does `(cell.thumbnailClickReceiver?() ? cell).mouseClickLeft?()` — "a row does what a TAP
  on its grid cell does", no per-family branch (Plan 3 round-4 item 13). The remainder menu
  is a transient `MenuWdgt` DERIVED at pop, `actsAsEditorChrome = true`, titled "more
  tools". Verify: read `OverflowChevronButtonWdgt.actOnClick` + `GlassBoxBottomWdgt`.
- **F6 — the toolbar viewport and the derivation that already exists.** `ToolbarWdgt extends
  ViewportWdgt` (91 lines): ctor `super new ToolPanelWdgt` then
  **`@dockThickness = @contents.naturalGridCrossExtent()`** (:41) — docked and free share
  ONE derivation (`naturalPayloadExtentWithin` → `naturalGridExtentWithin`); `dockSide`
  class default per subclass; born locked (`_disableDragsDropsAndEditingNoSettle` — items
  are templates); the wrap-first `_positionAndResizeChildren` fixed point. Subclasses
  (7): `SuperToolbarWdgt`, `TextToolbarWdgt`, `SlidesToolbarWdgt`, `DashboardsToolbarWdgt`,
  `WindowsToolbarWdgt`, `PatchProgrammingToolbarWdgt`, `PlotsToolbarWdgt` — each ONLY
  `_toolbarItems` (+ `dockSide`). Verify: `grep -rn "extends ToolbarWdgt" src/`.
- **F7 — the Draw palette, and the 103.** `PaintToolbarWdgt extends RadioButtonsHolderWdgt`
  (authoring; the ONLY subclass, and `new RadioButtonsHolderWdgt` = 0 sites): class field
  **`dockThickness: 103`** (:19 — "2 * internalPadding + button width 93 — byte-what the
  retired in-content tool column measured"), `internalPadding: 5`, buttons laid out at a
  literal **93×55** in `_positionAndResizeChildren` — the tree's last per-toolbar geometry
  constants (Plan 3 round 5 deleted the other six). Four tools as `ToggleButtonWdgt`
  pairs (OFF face carries the tool's injectable source, ON face the disarm) + four
  `EditableMarkWdgt`s (`editInjectableSource`); selection is already ONE fact on one path —
  `radioButtonWasSwitched` → `_armSelectedTool` → `resolveInjectionTarget()` (docked: the
  band's host surface; floating: `world.editorFocusWdgt`), with the mode hooks
  (`reactToEdit/ViewModeInFrame`) re-driving the same funnel. Built by ONE site:
  `ImageWdgt.buildToolbar` (:25). Consumed by the dock path:
  `FrameWdgt._dockFrameNoSettle` — `new EdgeDockLayoutSpec side, (payload.dockThickness ?
  across)` (:1053); `_buildDockedToolbarNoSettle` (:1110). Verify:
  `grep -rn "dockThickness" src/` (the :19 constant is the only declared literal left).
- **F8 — selection today is THREE mechanisms.** (a) list rows: `selectsItemsOnClick` +
  `MenuItemWdgt.mouseDownLeft`'s `@parent.unselectAllItems()` + `STATE_PRESSED` kept on
  mouse-up; (b) radio switches: `SwitchButtonWdgt.buttonShown` through the ONE funnel
  `_setToggleStateNoSettle` (announces; the "shown button" pin) + the parent capability
  `radioButtonWasSwitched`; (c) ticks: reflection rows (a tick is a VIEW of a value —
  P5/P7). `SwitchButtonWdgt`/`ToggleButtonWdgt` have many consumers OUTSIDE the palette
  (FrameBarWdgt's collapse pair :271, four Inspector toggles, ErrorsLog pause, video
  play/pause) — they STAY regardless of P4. Verify: `grep -rn "new ToggleButtonWdgt\|new
  SwitchButtonWdgt" src/`.
- **F9 — the framed citizens and the no-middle-pane law.** `MenuWdgt`/`PromptWdgt` extend
  `FrameWdgt`; the rows panel sits DIRECTLY as `PopUpRowsViewportWdgt`'s plane (the
  menu-sandwich dissolution: the panel's `scrolledContentMeasure` is committed VERBATIM;
  re-introducing an intermediate pane is a falsified-twice shape — ⛔ do not). The row API
  is DELEGATED (C14): `addMenuItem` etc. forward to the panel — 322 framework call sites
  ride it untouched. `PromptWdgt._addButtonsInto` makes Ok/Close MENU ROWS (`menuRowHeight`
  targets — Plan 3's F21). Verify: read `_buildRowsPayload` in both + `grep -c
  "addMenuItem\|prependMenuItem" -r src/ --include="*.coffee"` (322).
- **F10 — the part boundaries (the migration's hard wall).** `parts.json`: **core** owns
  `src`, `src/basic-widgets(/menu-system)`, `src/buttons` (so: the whole column family,
  `IconButtonWdgt`, and — note — `GlassBoxBottomWdgt`, which sits at `src/` root);
  **app-kit** (LAZY) owns `src/app-kit` — `ToolbarWdgt`, `ToolPanelWdgt`, `GlassBoxTopWdgt`,
  `OverflowChevronButtonWdgt` + its appearance, `CreatorButtonWdgt`,
  `ToolbarCreatorButtonWdgt`, `WindowedApp`, the two mixins; **authoring** (LAZY,
  `requires: ["app-kit"]`) owns the palettes incl. `PaintToolbarWdgt`,
  `RadioButtonsHolderWdgt`, `TextToolbarWdgt`. Laws: an unguarded core reference into a part
  fails the build (`check-part-edges.js`); an eager/core class can NEVER `extends` a lazy
  part's class; a base crossing a part boundary needs `requires`. Consequence: the unified
  BASE must be core (menus are core), and anything naming the lid/mixin/chevron classes
  stays app-kit. Verify: `python3 -c "import json;
  print(json.load(open('buildSystem/parts.json'))['parts']['app-kit']['dirs'])"` and the
  `//` notes.
- **F11 — cross-repo reach (the rename sweep's checklist).**
  `MenuRowsPanelTestSupport.installOnto MenuRowsPanelWdgt` called from
  `src/boot/globalFunctions.coffee:490` (the TestSupport class lives in
  `Fizzygum-tests/Automator-and-test-harness-src/`); `scripts/graph-liveness-headless.js:369`
  reads `m.rowsPanel.children` (the FIELD `rowsPanel` on MenuWdgt/PromptWdgt — survives);
  macros/metadata naming classes: `MenuRowsPanelWdgt` in 4 test dirs (`FontsMenuTick*`,
  `WallpaperMenuTick*`, `FontsMenuFollows*`, `WallpaperMenuFollows*`,
  `ExtractMenuRowFromPinnedMenu`), `ToolPanelWdgt` in 2 (`ToolbarChevronPopsOverflow`,
  `DropIntoTiltedStackInsertsAtVisualSlot`), `PaintToolbarWdgt` in 2
  (`DrawingsMakerReEnableEditing`, `EditModeTogglePencilEyeGlyph`), `overflowChevron` in 1.
  `MenuItemSpec` is named in 2+ test dirs. Verify: `grep -rln "<name>"
  Fizzygum-tests/tests Fizzygum-tests/scripts Fizzygum-tests/Automator-and-test-harness-src`.
- **F12 — the G-row dials are LANDED** (`PreferencesAndSettings.coffee`): `menuFontSize 17`
  (:136), `barIconSize 44`/`barGlyphSize 24` (:186–187), `menuRowHeight 44` (:196),
  `toolThumbnailSize 44` / `toolInternalPadding 6` / `toolExternalPadding 10` / `toolRows 1`
  (:207–210), `dockBandDepth 50` (:218), `menuRowSeparatorColor 225³` (:226),
  `iconDarkLineColor 37³` (:171). So the palette's derived numbers, should P4 land as
  specced: `_cellPitch` = 50, `naturalGridCrossExtent` = `_naturalRunFor(1, 50)` =
  50 − 6 + 20 = **64**, band frame ≈ **70** — against today's declared **103** (and 93×55
  buttons → 44×44 cells). A material, owner-eyes visible change. Verify: `sed -n
  '180,230p' src/PreferencesAndSettings.coffee`.
- **F13 — test exposure, ballpark (P0 measures precisely, by BEHAVIOUR).** 10
  `_automationCommands.js` mention "toolbar"; the chevron witness
  (`SystemTest_macroToolbarChevronPopsOverflow`) is the only test that opens the remainder
  menu (P0 confirms by running, not grepping — the F7-world-menu lesson: a census's axis is
  its blind spot); Draw-palette pixels appear in at least the 2 tests naming its internals.
  Inspector member-list churn from renames: expected zero tests inspect these classes — P0
  PROVES it with a spike run, because "expected" is a hypothesis. Verify: P0.
- **F14 — the macro toolkit reaches rows the supported way.**
  `MacroToolkit._menuRowScrolledIntoView` (:744) + the row locators; a toolkit note (:982)
  already encodes `menuRowHeight`-aware row geometry. New witness macros use toolkit
  locators, never hand-rolled row reaching (the Plan 3 de-drift lesson). Verify: `grep -n
  "_menuRowScrolledIntoView" src/macros/MacroToolkit.coffee`.
- **F15 — gates this plan meets** (index: `docs/architecture/lint-and-static-checks.md`):
  `check-part-edges` (F10 — the migration's structural gate), `check-dead-methods` +
  `check-unresolved-sends` (dissolved classes/verbs; `RadioButtonsHolderWdgt`'s fate),
  `check-menu-actions` (the remainder rows' `@`-targeted string actions — RULE 1b resolves
  them on the enclosing chain), `fg menusweep` (menu shape changes; its `MenuWdgt[own]`
  roots), `fg pinsweep` (the "shown button" pin if P4 touches switch usage; `announces`
  fixtures key on the DECLARING class), `check-stinks` (present-tense comments),
  `NON_INTEGER_GEOMETRY` (icon centring formulas round), `check-constructors-build` (new
  panel ctor shape), the serialization rigs (new spec fields; `@serializationTransients`
  MERGES since T16), tests-repo `check-refs`/`check-visualisations` (recaptures regenerate
  pages), `check-macro-source-discipline` (new macros). No Automator bump anywhere in this
  plan: the harness does not change what it captures (the grammar's letter).

### 1.3 Why it is shaped this way

The two families grew from opposite ends a decade apart: menus are Morphic's oldest
furniture (rows as label buttons, specs added later), while the tool grid grew out of the
demo "tools panel" (glass boxes to make small widgets grabbable), and nothing ever demanded
they agree — until the Frame-model arc made both of them FRAME PAYLOADS (C11/C14), Plan 1
made chrome rosters derived (C5), and Plan 3's chevron had to project one family INTO the
other live. The Draw palette predates the shared toolbar construction and kept its own
radio machinery under an explicit owner decision (D10) whose stated reason — selection
state has no home in the toolbar family — is precisely the gap the T1 command model closes.
Each piece was right when built; what remains is one record, one dispatch law, and one
panel over two arranges — which is why this is small enough to be its own arc and why it
must land before Plan 4 freezes finger references against these classes.

---

## §2 The mechanism this plan installs (target design)

### 2.1 The command record (the model)

`MenuItemSpec` IS the command record and GROWS into it — never a parallel class (a fact
stated twice will disagree — the connector-P1 lesson). Two additions:

1. **`icon`** — an optional widget-valued slot (a paint-only icon widget such as the
   `Pencil2IconWdgt` family, or a neutralized copy of a tool — §2.2). Absent ⇒ the row is
   the `'label'` display, exactly today's pixels. The dead `[icon, string]`/Widget/Canvas
   comment claims on `MenuItemSpec.label` and `MenuItemWdgt` are DELETED with the real
   slot's arrival (F3) — the spec's `label` is a STRING, stated plainly.
2. **Selection stays a VIEW, not a stored boolean.** The model's "selection state" is the
   P5/P7 shape the spec already carries: `reflection` (a `MenuRowReflectionSpec` reading the
   ONE selected-fact wherever it lives) for rows, and the panel-derived highlight for grid
   cells (§2.5). No `selected: true` field lands on the spec — a stored copy of a fact that
   lives on the panel/palette is the two-writers bug by construction.

Naming: the record KEEPS the name `MenuItemSpec` through P1–P2 (its consumers are
menu-side); **whether it renames to `CommandSpec` rides P3's one sweep** (owner decision
OD1, §2.7 — cross-repo: 2+ test dirs name it, F11). The `addMenuItem` verb family is
UNTOUCHED in every case (C14's letter; 322 sites).

### 2.2 The display axis — data-driven, landed where a consumer exists

- **`'label'`** = a spec without `icon` — every existing row, byte-identical.
- **`'icon'`** = the grid cell — already shipped (the tool IS the icon). No column
  icon-only row is built: the grid already is that projection and no surface asks
  (no-rent; recorded in §8).
- **`'icon+label'`** = a spec WITH `icon`: `MenuItemWdgt` places the icon at the row's left
  — a `barGlyphSize` (24) box inset in the `menuRowHeight` (44) row per G3's
  glyph-in-target discipline, vertically centred, rounded (integer-placement law) — label
  after it at the shifted offset; `menuEntryPreferredWidth` grows by the icon box + gap and
  **must stop reading `@children[0]`** (F2's positional trap): it reads `@label` and the
  icon slot by name.
- **The icon child is INERT.** A tap anywhere on the row is the ROW's click. Where the icon
  is a passive icon widget (the `IconWdgt` families) nothing is needed; where it is derived
  from a live tool (the chevron's rows — the hidden cell's tool may be a BUTTON), the row
  wraps it in a pass-through holder that declares `catchesPointerAt: -> false` — a ROLE
  declaration, the `PopUpRowsViewportWdgt` precedent ("alpha is painting, never
  hit-testing"; the role is the widget's business).
- **First consumer (P2): the chevron's remainder menu.** `OverflowChevronButtonWdgt
  .actOnClick` derives, per hidden cell, `icon:` = a neutralized miniature of the cell's
  tool (`glassBoxItem()`, via `fullCopy()` + the inert holder, sized to the 24 box) beside
  the existing label. The dispatch is untouched (`triggerToolFromMenu` — F5). This is the
  display axis's live proof, replacing the falsified T1 sentence with a true one.
- **NOT landed, each with a destination (§5 P5 tail):** icons on ordinary menus (world
  menu, context menus) — owner taste, BACKLOG until asked; the remainder popped AS A GRID
  ("a vertical toolbar") or as label-only — the T1 licence says "may", one projection ships
  (OD2), the others become one-line derivations once the model exists — BACKLOG row noting
  exactly that.

### 2.3 The arrangement axis — the MIGRATION question, answered

**The question, explicitly:** do `MenuRowsPanelWdgt` and `ToolPanelWdgt` survive as names,
or dissolve into one class? **Proposed answer (OD1 confirms naming; the SHAPE is the
plan's):**

- **ONE core base class — `CommandPanelWdgt` — created by RENAMING AND GENERALIZING
  `MenuRowsPanelWdgt`** (it is already the command column; the rename states what the
  ruling says it is). It keeps everything F1 lists verbatim as its `'column'` arrangement
  (the inherited `VerticalStackPanelWdgt` engine — the ONE stack engine, untouched), and
  gains the `'grid'` arrangement **as a construction-time choice** (reframe 2): the pitch
  arithmetic, the fit/hug inverse pair (`_cellPitch`/`_cellsFittingIn`/`_naturalRunFor`),
  the two sizing capabilities and the grid arrange MOVE UP from `ToolPanelWdgt` — none of
  which references an app-kit class (F4/F10; `GlassBoxBottomWdgt` is core). Where the grid
  arrange builds its overflow piece it calls a **HOOK** (`_makeOverflowPiece?()` — derived,
  capability-dispatched): the core base names no chevron class, so `check-part-edges` stays
  clean and a core grid panel simply has no overflow piece until a subclass answers.
- **`ToolPanelWdgt` SURVIVES as the thin app-kit leaf** (`extends CommandPanelWdgt`,
  arrangement `'grid'`): the glass-box TEMPLATE wrapping in `_addNoSettle` (its lid
  `GlassBoxTopWdgt` and the smart-placer mixin are app-kit — F10 forces this home), the
  `_makeOverflowPiece` answer (`new OverflowChevronButtonWdgt`), `viewportColloquialName`
  "toolbar", `cellsBehindTheOverflowChevron`. It survives because the PART BOUNDARY demands
  an app-kit home for template machinery — a structural reason, not nostalgia.
- **`MenuRowsPanelWdgt` DISSOLVES** (it IS the base, renamed): the three construction sites
  (F1) say `new CommandPanelWdgt …`; the boot install site and the harness
  `MenuRowsPanelTestSupport` re-target (F11); the four macro-naming tests are swept in the
  same batch (a family rename is ONE verifiable batch — the *Morph-migration lesson).
- **Why one class and not a shared mixin over two classes:** arrangement is fixed at
  construction, so the tagged-class objection does not apply (reframe 2), and the T1
  ruling's letter is "ONE command panel". The mixin shape ("command model injected into two
  unrelated branches") was weighed and is the FALLBACK, pre-authorized: **if the merged
  class's measure/membership contracts fork irreconcilably on arrangement twice** (the
  stack base's measures under grid mode are the risk — §6), the worker STOPS and the
  coordinator re-briefs onto the fallback — both classes stay, the model/dispatch/display
  land identically, and the ledger records the falsification. Either way every consumer
  behavior is preserved byte-identical in this phase.

### 2.4 The dispatch contract, stated as law

`thumbnailClickReceiver()` (F5) is promoted from a glass-box method to the model's stated
contract, on the base: *a projection of a command invokes the SAME action path as the
primary projection* — for a spec-built row that is the four-slot `trigger()` it already
has; for a cell that is a click on what the cell puts under the pointer. No new mechanism —
one comment block on `CommandPanelWdgt` naming the law and its two implementations, so the
next projection surface finds it (comments are a deliverable — owner preference).

### 2.5 Selection in the model — and the Draw palette as its forcing case (P4)

`PaintToolbarWdgt` re-bases onto the unified panel (superseding D10 per the header's
routing ruling):

- **Construction:** `PaintToolbarWdgt` becomes the palette VARIANT of the toolbar
  construction — a `ToolbarWdgt`-family strip whose panel holds FOUR COMMANDS (pencil /
  brush / toothpaste / eraser), each a spec: `icon:` the existing icon widget pair's OFF
  face art (`Pencil2IconWdgt` etc.), label the tool name, action = select-this-tool on the
  palette. The `ToggleButtonWdgt` pairs and the 93×55 layout dissolve; the
  `CodeInjectingSimpleRectangularButtonWdgt` sources move to a per-command record on the
  palette (the `@PENCIL_TOOL_SOURCE` statics stay where they are).
- **Selection = ONE fact, unchanged in spirit:** the palette keeps `_armed` + the armed
  tool as the single fact; a cell tap routes to the palette's select verb →
  `_armSelectedTool` → `resolveInjectionTarget()` (F7's funnel, byte-kept — the round-4
  "selection and active tool are one fact on one path" law). The cell's highlight is
  DERIVED from that fact at arrange/paint (`highlightedToolIconColor` on the selected
  command's icon — the C5 idiom; no stored per-cell boolean). Clicking the selected tool
  again disarms (today's ON-face semantics), preserved as the select verb's toggle.
- **The edit affordance survives:** `EditableMarkWdgt` attaches to the cell, targeting the
  command's `editInjectableSource` — the mark's existing verb, re-aimed.
- **The 103 dies by derivation:** the palette's panel answers `naturalGridCrossExtent()`
  like every strip (F6's ctor line) ⇒ dockThickness 64, band ≈ 70 (F12's arithmetic);
  `dockThickness: 103`, `internalPadding: 5` and the 93×55 literals are DELETED — zero
  declared dock-thickness constants remain tree-wide (the mandate's measurable close).
- **`RadioButtonsHolderWdgt` is left consumer-less** (F7: sole subclass, zero `new` sites)
  → deleted in P4 unless `check-dead-methods`/greps find a live duck consumer of
  `wantsButtonsToBehaveLikeRadioButtons` beyond `ToggleButtonWdgt`'s parent query (the
  protocol VERB `radioButtonWasSwitched` survives as a capability wherever switches sit —
  F8's other consumers are untouched).
- **The mode hooks** (`reactToEdit/ViewModeInFrame`) re-drive the same select funnel —
  their transition guards and the no-settling-setter constraint (F7's ⚠ comment) carry
  over verbatim.

### 2.6 Disposition table — every current member this plan touches

| today | fate |
|---|---|
| `MenuItemSpec` | GROWS `icon`; selection stays the `reflection` view (P1); rename to `CommandSpec` = OD1, in P3's sweep if ruled |
| the `[icon, string]`/Widget/Canvas label comments (F3) | DELETED (P1) — the label is a string, the icon is a named slot |
| `MenuItemWdgt._createLabel` / `menuEntryPreferredWidth` | icon-aware: 24-box inset left, label shifted, measure reads named fields not `children[0]` (P1, inert at no-icon) |
| `OverflowChevronButtonWdgt.actOnClick` | rows gain `icon:` (neutralized tool miniature) (P2 — the display axis's first consumer) |
| `MenuRowsPanelWdgt` | RENAMED/GENERALIZED → `CommandPanelWdgt` (core base, both arrangements; column = the untouched stack engine) (P3) |
| `ToolPanelWdgt` | SURVIVES as thin app-kit leaf: glass-box wrapping + `_makeOverflowPiece` + colloquial name (P3) |
| grid arithmetic + sizing capabilities (F4) | MOVE UP to the base, chevron construction behind the hook (P3) |
| `MenuWdgt`/`PromptWdgt`/`ListWdgt` construction sites | `new CommandPanelWdgt …` (P3); delegated row API (322 sites) UNTOUCHED (C14) |
| boot install + `MenuRowsPanelTestSupport` + macro/test names (F11) | swept in P3's one batch, BOTH repos |
| `PaintToolbarWdgt` | re-based onto the unified panel; tools = commands; selection = the ONE armed fact, highlight derived; `dockThickness: 103` + 93×55 literals DELETED (P4) |
| `RadioButtonsHolderWdgt` | deleted in P4 if consumer-less (expected); `radioButtonWasSwitched` survives as the capability F8's other consumers use |
| `SwitchButtonWdgt`/`ToggleButtonWdgt` + their pins | UNTOUCHED (F8 — other consumers) |
| `ToolbarWdgt` + 7 subclasses, creator buttons, glass boxes | behavior UNTOUCHED (the leaf keeps their contract); `ImageWdgt.buildToolbar` returns the re-based palette (P4) |
| `thumbnailClickReceiver` contract | promoted to the base's stated law (P3, comment + placement) |

### 2.7 Owner decisions this plan carries (each an OPTION set, decided at the named gate)

- **OD1 (P3 brief-time): naming.** (a — proposed) base `CommandPanelWdgt`, spec renamed
  `CommandSpec` in the same sweep; (b) base `CommandPanelWdgt`, spec keeps `MenuItemSpec`;
  (c) the base keeps the name `MenuRowsPanelWdgt` (rejected by the author: the name would
  state the column special case as the general thing). Cost identical, cross-repo sweep
  enumerated either way (F11).
- **OD2 (P2 eyes-on): the chevron's default projection.** (a — proposed) icon+label rows;
  (b) keep label-only (the display axis then lands with NO consumer — violates the
  no-rent landing rule, so (b) implies deferring P2's mechanism to a future consumer);
  (c) per-strip choice (rejected: a knob nobody asks for). The T1 licence's other
  projections (grid pop, label-only pop) are recorded as available-by-derivation, BACKLOG.
- **OD3 (P4 eyes-on): the Draw palette's new look.** 44-px cells in a 70-band (vs 93×55 in
  103), selection tint on the icon, edit marks on cells — the owner sees it on the dev
  build BEFORE any capture and may re-turn cell size/labeling; a veto here stops P4 with
  the palette unconverted and the 103 residue RETURNED to the program tail with the
  falsification recorded (it must not silently evaporate).

---

## §3 The axes (why this shape)

- **Model first, panels second, palette last.** The record + row mechanism (P1) is inert
  and byte-identical — provable by the whole suite. The first consumer (P2) is the
  smallest possible declared visible change (one test's references expected). The class
  merge (P3) is pure structure at frozen pixels. The palette (P4) is the one deliberate
  redesign, gated on owner eyes. Each cut point leaves a shippable, self-justifying tree
  (program §1's own rule).
- **The display axis as data beats a mode.** A `display` knob on panels would need a
  writer, a serializer arm, and an answer for mixed content; "a spec carries an icon or it
  does not" needs none of those and produces exactly the three ruled values (reframe 1).
- **One base + one part-bound leaf beats both extremes.** All-in-one-class founders on the
  part boundary (core cannot name the lid/mixin/chevron — F10); two-classes-plus-mixin
  under-delivers the ruling and leaves the model homeless. The base-with-hook shape gives
  the ruling's ONE panel, keeps `check-part-edges` structural, and costs one derived hook.
- **Selection as a view is already the tree's law.** The palette's own round-4 fix ("the
  highlight and the armed tool are two views of one fact"), the switch funnel's announce,
  and the tick reflections all converge on it; the command model writes it down rather
  than inventing a fourth mechanism.
- **The 103 dies by the same derivation that killed the other six** (Plan 3 round 5/6):
  once the palette's cells are grid cells, `naturalGridCrossExtent` answers, and a
  constant that restates a derivable fact is the drift bug waiting (G2's instinct,
  vindicated the same way twice).

---

## §4 The distilled argument

Plan 1 made chrome derived, Plan 3 made geometry one — and both, at their review gates,
kept paying a tax to the SAME seam: two unrelated widget families both meaning "a
collection of commands", so every projection across the seam (the chevron's menu, the Draw
palette's dock band) had to be hand-invented. The tree has already grown every ingredient
of the unification separately: the record (`MenuItemSpec`), the dispatch law
(`thumbnailClickReceiver`), the derive-at-pop projection (the chevron), the one-fact
selection (`radioButtonWasSwitched` → `_armSelectedTool`), the sizing derivation
(`naturalGridCrossExtent`). What remains is to put one name on them and delete the two
structures that predate them — a rename-heavy, behavior-light arc whose one genuinely new
pixel product (icons beside labels; the palette as a real strip) is small, owner-gated,
and measured before it lands. When this closes, Plan 4 captures finger references against
payload classes that will not move under it.

---

## §5 Phases

Each phase: goal · steps · pixel impact · gate · commit. **Recapture budget: P0/P1/P3 ZERO
(P3 caveat below); P2 = exactly the P0-measured remainder-menu set (expected:
`SystemTest_macroToolbarChevronPopsOverflow` alone); P4 = exactly the P0-measured
Draw-palette set. Anything outside the budget at any gate: STOP (worker rule 3) — the
coordinator eyeballs `fg diffpage` and takes it to the owner. Never a silent recapture.**

### P0 — Re-verification + measurements (~¼ session-day)

1. `fg status`; a green gauntlet baseline must exist for the current heads (run one in the
   background if the tree moved).
2. **Sonnet, read-only:** re-verify every §1 fact with its recorded command; report drift
   (the coordinator amends §1 before P1 briefs — a plan's premises are hypotheses; this
   program's case law is 3–8 falsified per fresh plan).
3. **Sonnet, behavioral measurements (spike builds allowed, nothing committed):**
   (a) the REMAINDER-MENU exposure set — which tests open the chevron's menu (run the suite
   over a scratch edit that visibly perturbs remainder rows, e.g. a temporary label prefix;
   the failed array IS the set; expected: the chevron witness alone — but MEASURE, F13);
   (b) the DRAW-PALETTE exposure set — same method over a scratch palette perturbation;
   (c) the RENAME exposure — suite over a scratch `MenuRowsPanelWdgt`→`CommandPanelWdgtX`
   rename spike (both repos' load-bearing sites, F11): expected ZERO failures (no inspector
   pins these classes) — if non-zero, list the tests; the owner's standing
   byte-identity-not-sacred note covers benign inspector churn but the set must be DECLARED;
   (d) counts: the F10/F11 greps, `new MenuWdgt` 47, addMenuItem 322.
   Revert every spike (plain file restore, never `git stash`).
4. Findings into the STATUS box. Nothing committed.

### P1 — The command record + the display mechanism, INERT (~⅓ session-day)

One Opus worker, one commit. Steps: §2.1 (the `icon` slot on `MenuItemSpec`, threaded
through `MenuRowsPanelWdgt.addMenuItem`'s opts forwarding — an opt added to one is
available on the other, its own comment says so); §2.2's row mechanism in `MenuItemWdgt`
(`_createLabel` icon-aware, `menuEntryPreferredWidth` de-positionalized, the inert holder
class for live-tool icons — small, core, beside the menu system); the F3 comment lies
deleted; the pass-through holder's `catchesPointerAt` role declaration with the
`PopUpRowsViewportWdgt` precedent cited in its comment.
**Gate:** `fg presuite` **byte-identical** (no caller passes an icon yet — the mechanism
proves itself inert against all 321), build's 28 gates green inside it. Commit.

### P2 — First display-axis consumer: the chevron's rows go icon+label (~⅓ session-day + owner eyes)

Same Opus worker. Steps: §2.2's chevron edit (`actOnClick` derives `icon:` per hidden
cell — `fullCopy()` of `glassBoxItem()`, neutralized in the holder, 24-box); extend the
existing witness test's assertions if row geometry moved (toolkit locators only, F14).
**Gate:** `fg build`; `fg suite` discovery — the failed set must EQUAL P0(a)'s measured
set exactly (one more or fewer = STOP); `fg diffpage` on it; **the COORDINATOR eyeballs
and the OWNER confirms OD2 on the exemplar crops** (consequence: icons at the rows' left,
nothing else); `fg recapture --auto --dprs=1,2` → `✅ RECAPTURE COMPLETE`; `fg presuite`
green; `fg menusweep` OK (the remainder rows' dispatch untouched — the sweep proves it);
`fg vmtruth` rides the next gauntlet (the icon copies must die with their transient menu —
the rows' `_fullDestroy` subtree covers them; the leg is the judge). Commit (src + the
declared references together).

### P3 — The panel unification (structural; the migration executed) (~1–1½ session-days)

One Opus worker for the design moves; ONE Sonnet mechanical sub-step for the enumerated
rename sweep (the coordinator hands it the literal token→token list over BOTH repos, from
P0(c/d) + F11 — including `src/boot/globalFunctions.coffee:490`, the harness TestSupport
file and its install target, the 4+2 macro-naming test dirs, and OD1's spec rename if
ruled). Steps: §2.3 in full (base + leaf + hook), §2.4 (the contract comment), consumers'
construction sites, `check-part-edges` implications verified by the build.
**Gate:** build 28 gates (part edges, dead methods, constructors); `fg presuite`
**byte-identical**, EXCEPT any P0(c)-declared inspector-churn set (expected empty; if
declared: `fg diffpage` + coordinator eyeball + recapture of exactly that set — benign
inspector churn under the owner's standing note, still never silent); then a full
`fg gauntlet` (18 legs) BEFORE the commit proposal — the arrange moved homes
(settle/capstone/revisits), classes renamed (BOTH serialization rigs; `menusweep`'s
`MenuWdgt[own]`/`PromptWdgt[own]` roots; `pinsweep`; the apps/parts legs read `index.html`
where the lazy app-kit boundary is real — exactly what the hook protects). Commit — one
bisectable batch, both repos.

### P4 — The Draw palette rides the unified panel; the 103 dies (~¾–1 session-day + owner eyes)

One Opus worker. Steps: §2.5 in full. Order inside the phase: (1) convert on the working
tree; (2) `fg build`, open the dev `index.html` → Docs icon has no palette — the scene is
the DRAW icon: **the owner eyeballs OD3 live** (cells, band 70, selection tint follows
taps, a tool press still paints, the edit mark opens the source, collapse/expand, float +
re-dock); any re-turn is recorded in the STATUS box; (3) only then the declared set:
`fg suite` discovery must equal P0(b)'s set; `fg diffpage`; coordinator eyeballs
consequence pixels (93×55 → 44 cells, 103 → 70 band, nothing else); `fg recapture --auto
--dprs=1,2` → COMPLETE; `fg presuite` green; `fg menusweep` + `fg pinsweep` (the palette's
menu rows and any pin surface moved); full `fg gauntlet` (the palette's arm/inject state
machine is settle-adjacent; the serialization rigs see the dissolved toggle fields).
`RadioButtonsHolderWdgt`'s deletion rides this commit iff consumer-less (the greps + 
`check-dead-methods` decide, §2.5). Commit (src + declared references).

### P5 — Docs, close, tail (~⅓ session-day)

1. **Sonnet ×N (disjoint files), weave never append:**
   `docs/architecture/viewports-and-planes.md` (the scrolling-composite roster names
   `ToolPanelWdgt`/the panel classes — re-state around the base/leaf),
   `docs/architecture/widget-authoring-guidelines.md` (the menus/pin sections if they name
   renamed classes), `docs/architecture/lint-and-static-checks.md` only if gate text names
   dissolved members, `src/macros/CLAUDE.md` + `MACRO-PATTERNS.md` mentions,
   `docs/BACKLOG.md` — the stale T1 and T2 rows under the program section are retired
   (T2's row still reads "after T1"; both are closed facts now), and the new BACKLOG rows
   §2.2/§2.7 name (icons-on-menus; other remainder projections). `fg doc-narration` after.
2. Program doc (coordinator): T1 row → closed (with the falsified proof sentence's
   correction dated); the 103 routing row's destination discharged; tail entries below;
   STATUS line for Plan 3.5; this file `git mv` to `docs/archive/` + INDEX line at the
   close commit.
3. **Gate:** full `fg gauntlet` + `fg homepage` (the production tree boots the app-kit leaf
   lazily — the parts legs already proved it in P3/P4; homepage is the production-round-trip
   witness). Commit; coordinator runs the close-arc ritual.

**Tail (drain before Plan 4 starts — program §5 rule 2):** pre-filed candidates, each with
a destination: icons on ordinary menus (BACKLOG, owner taste); remainder-menu alternative
projections — grid pop / label-only pop (BACKLOG, available-by-derivation note); the
column `'icon'`-only display (KILLED — the grid is that projection, no surface asks;
evidence: F13's zero consumers). Anything discovered lands in the program ledger with a
destination, per rule 1.

**ETA (owner preference: upfront):** P0 ¼ + P1 ⅓ + P2 ⅓(+owner) + P3 1–1½ + P4 ¾–1(+owner)
+ P5 ⅓ ≈ **~3–3¾ session-days + two owner reviews + tail.** Status updates every ~5 min
during long ops.

---

## §6 Central risks and how each is bounded

| risk | where | bound |
|---|---|---|
| The stack base's measure/membership contracts fork irreconcilably under grid arrangement | P3 | the pre-authorized FALLBACK (§2.3): two falsifications ⇒ STOP, re-brief onto model-level unification with both classes surviving; the ledger records it; P1/P2/P4 stand either way |
| An unguarded core→app-kit edge sneaks in with the grid move | P3 | the hook shape (§2.3) + `check-part-edges` fails the build structurally; the parts/apps gauntlet legs prove the lazy boundary live on `index.html` |
| The rename breaks a reader no grep found | P3 | P0(c)'s BEHAVIORAL spike (suite over the rename) + F11's enumerated two-repo list + the apps/parts legs (the P9 lesson: `scripts/` reads internals inside `page.evaluate`) |
| Inspector member-list churn turns the "byte-identical" P3 gate into surprise diffs | P3 | P0(c) measures the set in advance; a declared benign-inspector set is recaptured eyeballed (owner's standing note), an UNdeclared diff is a STOP |
| The icon copy of a live tool catches clicks or leaks | P1/P2 | the inert holder's `catchesPointerAt` role (the PopUpRowsViewport precedent); rows `_fullDestroy` their subtree; `fg vmtruth` is the lifetime judge |
| `menuEntryPreferredWidth`'s `children[0]` assumption breaks under the icon child | P1 | named-field reads land IN P1 while still inert — the byte-identical gate proves the refactor before any icon exists |
| The remainder-menu set is bigger than the witness test | P2 | P0(a) measures by BEHAVIOUR (the F7 world-menu lesson: a census's axis is its blind spot); the gate requires exact equality with the measured set |
| The palette conversion breaks arm/injection semantics (first-use, mode flips, docked vs floating) | P4 | the ONE-fact funnel is KEPT, not rebuilt (§2.5); the two Draw tests + `menusweep` + an owner live pass (OD3's checklist names float/re-dock/collapse) are the witnesses; two falsified fixes ⇒ STOP |
| The palette's new geometry displeases the owner after capture | P4 | eyes-on is STEP 2, capture is STEP 3 — nothing is captured before OD3; a veto returns the residue to the program tail explicitly |
| `RadioButtonsHolderWdgt` deletion severs a duck consumer | P4 | deletion is conditional on the greps + `check-dead-methods`/`check-unresolved-sends`; the capability VERB survives regardless (F8) |
| Serialization rigs trip on dissolved toggle fields / renamed classes | P3/P4 | NO compat obligations (owner standing rule) — but the RIGS run current classes: both ride the gauntlet at each phase close; `@serializationTransients` merges (T16) |
| The chevron menu's `check-menu-actions` RULE 1b misses the derived rows' string actions | P2 | the actions target `@` (the chevron) and resolve on its chain today (`triggerToolFromMenu`); the gate re-proves it every build; `menusweep` covers dispatch runtime |

---

## §7 Verification protocol

- Inner loop: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` — **byte-identical is
  the gate for P1 and P3 (modulo P3's pre-declared inspector set); green-on-recaptured-set
  for P2/P4**.
- The review pair: `fg diffpage <names|--tests-file=F>` then its `fg classify` table —
  ADVISORY triage; the coordinator's eyes are the gate (program §4 rule 2), the owner's
  eyes are OD2/OD3.
- Recapture: `fg recapture --auto --dprs=1,2`, background, verdict `✅ RECAPTURE COMPLETE`;
  UNSTABLE = investigate via DETERMINISM.md, never auto-recapture. Build FIRST.
- Runtime sweeps: `fg menusweep` at P2/P3/P4 (menu shapes and roots move); `fg pinsweep`
  at P3/P4.
- Phase closes P3, P4 and P5: full `fg gauntlet` (18 legs, background,
  `cat /tmp/fg-<cmd>.verdict` peeks at ~5-min cadence) — P3/P4 BEFORE their commit
  proposals (class-structure and state-machine phases never close on presuite alone); P5
  additionally `fg homepage`. `[shard N] did not start within 90s` / `CoffeeScript is not
  defined` = boot-storm infra flake; a serial-retry pass = load-flake warning, not FAIL.
- Docs: `fg doc-narration` after the P5 sweep.
- Never pipe a gating `fg` call; never edit mid-run; probes in `Fizzygum-tests/.scratch/`.
- Gates that WILL fire if mishandled (F15): `check-part-edges` (the hook, §2.3),
  `check-dead-methods`/`check-unresolved-sends` (dissolutions — fix callers, never
  allowlist), `check-stinks` (present-tense comments), `NON_INTEGER_GEOMETRY` (icon
  centring rounds), `check-constructors-build`, tests-repo `check-refs` /
  `check-visualisations` (recapture regenerates pages; never hand-edit),
  `check-macro-source-discipline`.

---

## §8 Rejected alternatives — do not re-attempt

- **The `[icon, string]` tuple label as the icon mechanism** — a positional lie inside a
  string-typed slot, dead-on-arrival for a decade (F3); the icon is a NAMED spec slot.
- **A parallel `CommandSpec` class beside `MenuItemSpec`** — a fact stated twice WILL
  disagree (connector-P1); the one record grows.
- **A stored `display` mode on panels** — rent with a serializer arm; display is data
  (reframe 1).
- **A runtime-flippable `arrangement` tag** — arrangement never changes mid-life; C2's
  tagged-state reasoning licenses a tag only for mid-life change. Re-projection = a NEW
  derived surface (the chevron precedent).
- **Moving the lid/creator/chevron machinery into core to get one monolithic class** —
  breaks the part layering (F10), taxes the lean/appliance artifact with template
  machinery it cannot use, and buys nothing the hook does not.
- **A middle pane between the panel and its viewport, or a second vertical-stack engine** —
  both falsified with measurements in `menu-sandwich-dissolution-plan.md` /
  `menu-row-conformance-plan.md`. The column arrangement stays the ONE stack engine.
- **A live-tracking remainder menu** — derived-at-pop + transient IS the staleness answer
  (P5/P7; already a rejected alternative in the archived Plan 3 — twice is enough).
- **Icons on every menu row "for consistency"** — rent on every menu nobody asked to
  decorate; icons land where a consumer exists (BACKLOG for the rest).
- **Keeping `dockThickness: 103` (or re-deriving it as a new constant)** — the routing
  ruling's whole point; a constant restating a derivable fact is the drift bug the round-6
  deletion of `toolbarDockThickness` already fixed once.
- **Keeping `RadioButtonsHolderWdgt` as a compat shim** — a class with zero consumers is
  what `check-dead-methods` exists to forbid; the capability verb is the survivor.
- **Converting `ListWdgt` away from the panel "while we're here"** — its
  `selectsItemsOnClick` construction already IS the unified panel's single-selection column
  face; out of scope, nothing to fix.

---

## §9 Delegation map — coordinator and workers (program §3.1)

The coordinator (the session) never edits source or runs suites; it briefs, reads reports,
checks verdict files, decides at gates, hosts the P2/P4 owner reviews, eyeballs every diff
page, and talks to the owner. Workers are fresh agents with no conversation context:
`Agent` with `subagent_type: general-purpose`, `model: "opus"` (phase work) or `"sonnet"`
(mechanical work). ⛔ Never `fork`, never `isolation: worktree`. **One code worker at a
time**; parallel workers only for read-only work and docs edits to disjoint files.

### 9.1 Per-phase map

| phase | worker | parallel? | brief = plan section + | gate the worker runs | coordinator decides |
|---|---|---|---|---|---|
| P0 fact re-verify | Sonnet ×1 | yes (read-only) | §1's fact commands | none | records drift, amends §1 |
| P0 exposure spikes (a–d) | Sonnet ×1 | no (spike builds) | §5 P0.3's stated specs | the spike suites | the three declared sets into STATUS |
| P1 record + row mechanism | Opus ×1 | no | §2.1, §2.2; F2/F3 | `fg presuite` byte-identical | verdicts; commit proposal |
| P2 chevron icons | same Opus | no | §2.2; F5/F14; P0(a)'s set | build; suite; diffpage; recapture; presuite; menusweep | OD2 with the owner; eyeballs; commit |
| P3 unification | Opus ×1 + Sonnet (rename sweep from the enumerated list) | no | §2.3, §2.4; F1/F4/F10/F11; P0(c); OD1's ruling | build; `fg presuite`; `fg gauntlet` | OD1 to the owner pre-brief; fallback call on 2 falsifications; commit |
| P4 Draw palette | Opus ×1 | no | §2.5; F7/F8/F12; P0(b)'s set | build; owner scene; suite; diffpage; recapture; presuite; sweeps; gauntlet | hosts OD3; eyeballs; commit |
| P5 docs sweep | Sonnet ×N | yes (disjoint files) | per file: the named paragraph | `fg doc-narration` | reviews diffs |
| P5 close | coordinator | — | — | `fg gauntlet`, `fg homepage` | close-arc ritual, program STATUS/tail, archive move, owner |
| tail | per item | per item | the ledger row + destination | as the item needs | ledger bookkeeping |

### 9.2 The worker brief (template — copy, fill the ⟨⟩, nothing else)

```
You are executing ⟨phase/sub-step⟩ of Fizzygum/docs/plans/command-panel-unification-plan.md.
Read that plan's §0, §0.5 and §⟨phase⟩ in full, then Fizzygum/docs/plans/frames-input-touch-program.md
§2 for rulings ⟨IDs⟩ and §4 (recapture policy). Also read Fizzygum-all/CLAUDE.md, Fizzygum/CLAUDE.md
and Fizzygum-tests/CLAUDE.md. All commands through /Users/davidedellacasa/code/Fizzygum-all/fg by
absolute path. Probes under Fizzygum-tests/.scratch/.
Do: ⟨the phase's step list, or "every step of §⟨phase⟩"⟩.
Gate: ⟨exact fg command(s)⟩ → expected ⟨verdict⟩. Launch long ops with run_in_background and wait for
the notification; never poll; never pipe the gating call. Build BEFORE any fg recapture.
Pixel budget: ⟨P1/P3: ZERO (P3: plus the pre-declared inspector set, if any) — any other diff is a
STOP. P2: exactly the P0(a) set. P4: exactly the P0(b) set; the owner's eyes-on comes BEFORE any
capture.⟩ List the footprint, produce fg diffpage, do NOT recapture until the coordinator approves.
Stop and report (do not improvise) if: a §1 fact is false; a fix shape is falsified twice; a gate
fails for a reason you cannot state in one sentence; a diff appears outside the budget; you need a
decision the ledger and §2.7's OD rulings do not cover. Never recapture without the coordinator's
approval, never commit, never push.
Comments you write: present tense only, no history narration. `undefined` is the one absence value.
Report (≤ 60 lines): files changed (git diff --stat, both repos); each gate's literal
/tmp/fg-<cmd>.verdict line; counts measured; tests added/changed; the recapture verdict line if any;
open questions; which stop rule fired, if any.
```

### 9.3 What the coordinator checks on every report (cheap, never a re-do)

1. `cat /tmp/fg-<cmd>.verdict` for each gate the report claims — the literal line, not prose.
2. `git -C <repo> status --short` + `git diff --stat` in BOTH repos — the changed-file list
   matches the phase (P1 touches menu-system + the holder; P2 touches the chevron + one
   test dir; P3 touches the panel family, boot, harness, and the named test dirs; P4
   touches authoring + app-kit + two test dirs; a stray file is a question).
3. P2/P4: the diffpage exists and the coordinator LOOKS at it; then the owner (OD2/OD3).
4. A stop rule fired → read ONLY the quoted evidence; amend §1 or the brief; re-brief. Two
   stops on the same step → re-frame (P3's stop has a pre-authorized fallback, §2.3).
5. Then: commit proposal to the owner, or the next brief.

---

## §10 References

- Program: [`frames-input-touch-program.md`](frames-input-touch-program.md) — §2 rulings
  (C5, C10, C11, C14, C16; G1/G3/G5), §3.1 execution model, §4 recapture policy, §5 tail
  rules + the T1 row as expanded (this plan's mandate) and T2 (closed — the chevron this
  plan builds on), §6 just-in-time authoring.
- Plan 3 (closed): [`../archive/single-geometry-visual-wave-plan.md`](../archive/single-geometry-visual-wave-plan.md)
  — §2.7 (the chevron's mechanics, F22), the round-3/4/5/6 STATUS entries (the dispatch
  contract's birth, the ONE-fact selection fix, the toolbar extent/thickness derivations,
  and the 103 routing ruling this plan discharges); its §9 is the shape this §9 copies.
- Case law (archive): [`../archive/menu-sandwich-dissolution-plan.md`](../archive/menu-sandwich-dissolution-plan.md)
  (no middle pane — measured falsifications), [`../archive/menu-row-conformance-plan.md`](../archive/menu-row-conformance-plan.md)
  (the one stack engine; the hug/measure design), [`../archive/connector-ubiquity-and-reflection-plan.md`](../archive/connector-ubiquity-and-reflection-plan.md)
  (P5+P7: rows as views, one staleness signal, one edge per reflecting row),
  [`../archive/onion-widget-composition-plan.md`](../archive/onion-widget-composition-plan.md)
  (§5.B framed citizens, §5.C the toolbar slot, §5.D the Draw-palette decisions incl. D10 —
  superseded here by the T1 routing).
- Living truth to update at P5: [`../architecture/viewports-and-planes.md`](../architecture/viewports-and-planes.md),
  [`../architecture/widget-authoring-guidelines.md`](../architecture/widget-authoring-guidelines.md),
  [`../architecture/lint-and-static-checks.md`](../architecture/lint-and-static-checks.md)
  (only if gate text names dissolved members), `docs/BACKLOG.md` (the stale T1/T2 rows).
- Doctrine the executor must hold: `docs/architecture/build-and-packaging.md` +
  `buildSystem/parts.json` `//` notes (the part laws, F10),
  [`../architecture/integer-pixel-placement-and-sizing.md`](../architecture/integer-pixel-placement-and-sizing.md),
  `Fizzygum-tests/DETERMINISM.md`, `Fizzygum-tests/CLAUDE.md` (reference grammar; NO bump
  here), `Fizzygum/src/macros/CLAUDE.md`.
- Memory notes the executor should know exist: ask-before-commit/push; long-op ETA + ~5-min
  status; stop after two falsified fixes; a recapture is a decision to BELIEVE the pixels —
  eyeball consequence pixels, never "benign churn"; byte-identity not sacred for benign
  inspector recapture (but always declared); a cross-repo rename MUST grep
  `Fizzygum-tests/scripts/` (P9); perl/sed blanket edits de-indent `.coffee` — use the Edit
  tool; `fg recapture --auto` needs a fresh build first.

---

### Start-prompt for a fresh coordinator session (copy-paste)

> You are the COORDINATOR for Plan 3.5 of the frames·input·touch program. Read
> `Fizzygum/docs/plans/command-panel-unification-plan.md` IN FULL, then the program doc's
> §2/§3.1/§4/§5 (the T1 row as expanded is your mandate). Run
> `/Users/davidedellacasa/code/Fizzygum-all/fg status` and verify heads ≥ the plan header's
> (Fizzygum `0d254caa` / tests `10e5d6151`); if the tree moved, expect §1 drift and
> re-verify before briefing. Execute per the plan's §9 delegation map, phases P0→P5, one
> code worker at a time, briefs from the §9.2 template. Three owner decisions ride the
> phases (§2.7: OD1 naming at P3 brief-time, OD2 the chevron projection at P2's eyes-on,
> OD3 the Draw palette look at P4's eyes-on) — present options, never decide them yourself.
> Pixel budget: zero in P1/P3 (P3 modulo the P0-declared inspector set); P2/P4 are small
> declared reviewed sets you eyeball yourself, owner eyes BEFORE any capture. Ask the owner
> before every commit/push.

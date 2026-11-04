> **ARCHIVED — COMPLETE (2026-11-04).** Plan and decision record of the spreadsheet UX arc (owner rulings
> R1–R13, §1); verification in §6a; the follow-ups after the close in §6b (the owner's nitpicks, live
> menu ticks) and §6c (the last build-time ticks). The present-tense description lives in `src/spreadsheet/CLAUDE.md`
> ("The UX arc"), `docs/specs/dataflow-engine-spec.md` §9.1, `docs/architecture/visual-design-system.md`
> (§4.2, §4.10, the font roles and the toolbar glyphs) and `src/macros/MACRO-PATTERNS.md` ("Spreadsheets");
> what the arc left out on purpose is in `docs/BACKLOG.md` under this file's name. Index: `docs/archive/INDEX.md`.

# Spreadsheet UX — plan

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.** Everything you need is
inline or one named-doc hop away. Owner rulings were made in conversation on 2026-11-04 and are recorded in §1;
do not re-litigate them.

**Mandate.** Transform the spreadsheet from a one-off PANE with accidental behaviours into a member of the
Makers family (Docs, Slides, Dashboards) on every axis — page gutter, its own toolbar, a desktop Maker plus a
folder example — and replace three accidental behaviours with rules: the toolbar acts on the sheet's
SELECTION (not on whatever leaf was clicked last), cell formatting is DOCUMENT STATE on the cell record (not
on a throwaway text widget), and Enter/Tab are one "commit and move" verb. Zoom is a re-layout at scaled
sizes, never a picture scale. No special cases where an existing mechanism serves.

**Status:** Phase 0 done (owner accepted the icons 2026-11-04: the paint bucket redrawn as a line glyph, typed
`.0`/`.00` one step bolder, the slider-node art reused, the three Super-toolbar entries wearing their Makers'
desktop icons in the toolbar's ink; zoom is a "100%" text button, so it needs no icon). Phases 1–6 COMPLETE
2026-11-04: every ruling landed, the spreadsheet tests re-aimed and recaptured, seven new tests, the gauntlet
green (§6a).

---

## §0 Orientation

- **Fizzygum** is a CoffeeScript GUI framework rendered on one `<canvas>` (descended from Morphic.js). Read
  `../../CLAUDE.md` (this repo) and the umbrella `../../../CLAUDE.md` first: build/test through
  `/Users/davidedellacasa/code/Fizzygum-all/fg` (absolute path), tests in the sibling `Fizzygum-tests` repo.
- **The spreadsheet** lives in `src/spreadsheet/` (the lazy `spreadsheet` part) on the core dataflow engine
  (`src/dataflow/`). Its depth doc is `src/spreadsheet/CLAUDE.md` — read it before touching anything there;
  §2 below summarises what this plan changes.
- **Prior arc:** toolbar grid + frame bar run (pushed Fizzygum `d8be5436`, tests `aba9c7c30`;
  `docs/archive/toolbar-grid-and-bar-run.md`). Relevant here: toolbars pack their tools and drop the last
  ones into `»` first, so tool ORDER decides what a narrow window shows.
- **Why now:** the owner reported six problems with a screenshot of a Spreadsheet window wearing a text
  toolbar they had docked by hand: (1) content stuck against the toolbar and window edges; (2) Enter should
  commit and select the cell below; (3) toolbar buttons act on a clicked cell but not on one reached by the
  arrow keys; (4) the Spreadsheet app is in the Examples folder, against the desktop-Maker / folder-example
  convention; (5) no dedicated toolbar or formula bar; (6) cells too small for touch. Options were
  brainstormed, prototyped as real renders, and ruled (§1).
- **Critical reframes (each was measured, not argued):**
  1. *The toolbar's target is the clicked LEAF, i.e. the cell's derived text widget.* A probe on a live sheet
     (2026-11-04): click A1, Bold → A1's scalar `StringWdgt` goes bold; ArrowDown → selection A2 but
     `world.editorFocusWdgt` is still A1's text, so the next Bold styles A1 again; scroll A1 out of view and
     back → the bold is gone (the off-screen cell widget is destroyed and rebuilt plain). By the code it is
     also lost on save/load: `_reindexCellsNoSettle` destroys every non-hosted child of a cell. The record
     (`SheetCellRecord`) has no style at all. ⇒ Issue (3) is not "keyboard selection forgot to set the
     focus"; formatting was never modelled.
  2. *The sheet is classified a PANE* in `docs/architecture/visual-design-system.md` §4.10 (flush; "the
     window's lines are its edges"). A spreadsheet is a surface you work ON, so it is a PAGE; the gutter
     machinery (`wantsWindowPageGutter`) already exists.
  3. *The caret reports Enter and click-away as ONE event* (`CaretWdgt.accept`), so "Enter moves down"
     needs the reason passed along; Tab already has its own climb (`Widget.tab` → `CellWdgt.nextTab`).
  4. *Picture zoom blurs.* A `setScaleFactor 1.5` island renders the sheet's text visibly soft (close-up
     compared 2026-11-04); re-laying the sheet out at 1.5× sizes renders it crisp. SWCanvas glyph atlases
     span 9–96 px in 0.5 px steps (`src/boot/extensions/SWCanvasElement-extensions.coffee`,
     `SWCANVAS_MIN_FONT_SIZE`/`MAX`), so any zoom level ≥ 9 px text is renderable.
  5. *The original reason for the Examples-folder placement is moot.* `src/spreadsheet/CLAUDE.md` (Phase 2a)
     says the launcher went in the folder "to avoid shifting the desktop icon grid (which would recapture many
     desktop screenshots)". Test worlds draw NO desktop: `createDesktop` runs only when `isIndexPage`
     (`src/boot/globalFunctions.coffee`, `theWorld.createDesktop() if theWorld.isIndexPage`).

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — confirm both repos clean at or after the commits in
   §0, build fresh. If the working tree is dirty with this plan's work, read the Status line above and the
   memory note `spreadsheet-ux-brainstorm.md` to find where you are.
2. Read §1 (rulings) in full, then §2 (current state) — grep each cited symbol fresh; line numbers drift,
   method names are authoritative.
3. Execute phases IN ORDER (§4). Each phase ends green on `fg presuite` (build + dpr1 suite + paint audit +
   fracplane rider) with every pixel change ATTRIBUTED to a ruling before any recapture (§6).
4. Phase 0 stops for owner review of the icons (a LOCAL html page, opened — never a claude.ai artifact).
   After that, run straight through Phases 1–6.
5. Close with `fg gauntlet` + `fg homepage`, the docs updates of Phase 6, ONE end-of-arc review, and commit
   messages proposed for approval (`git commit -F <file>`). Never commit or push without explicit approval.
6. If two fix attempts for the same problem are falsified, stop and re-frame (owner rule).

## §1 Owner rulings (2026-11-04) — do not re-litigate

**R1 Page.** The sheet is a PAGE: `SimpleSpreadsheetWdgt` answers `wantsWindowPageGutter: -> true`, so its
window keeps `Theme.windowPageGutter` (8) on every side and between it and any docked band. The sheet then
draws its own 1 px edge on all four sides in the `stretchablePageEdge` role, as a Stretchable page and Draw's
canvas do (`StretchablePanelWdgt._insetEdgeRects`). Partial edge cells end at that edge.

**R2 Sizes (100%).** Rows 36, columns 104, row-number header column 48, column-letter header row 36, cell
text 16 px, header label text 16 px; text vertically centred in its row (today it is top-inset 2). The
opening extent shows 5 columns × 10 rows. Cells remain CONTENT, exempt from the 44 rule (§4.2 of the design
doc) — touch is served by R6/R7, not by 44-tall rows.

**R3 Zoom = re-layout, never picture.** One factor multiplies the sheet's size dials (cells, headers, cell
and header text, the text's left inset), each rounded to whole pixels. Hairlines (gridlines, the sheet edge,
the selection ring) stay their width. A widget hosted in a cell grows with the cell (it is already sized to
fill it). The formula bar, the toolbar and the window chrome do NOT zoom. Levels: 60, 75, 100, 125, 150, 200%
(60% because 16 × 0.6 = 9.6 ≥ the renderer's 9 px floor). 100% is R2. The zoom is DOCUMENT state, saved with
the sheet (the `viewOriginCol/Row` own-only-when-set idiom).

**R4 Selection owns the toolbar.** A click anywhere in the sheet makes the SHEET the editor focus (not the
leaf hit); the toolbar's tools act on the sheet's SELECTED cell, whatever moved the selection (click, arrows,
Enter, Tab). The mechanism is a general capability (named by its question), not a spreadsheet special case:
see §4 Phase 2.

**R5 Formatting is document state on the cell record:** bold, italic, font, size, alignment, fill colour,
decimal places. It survives scroll, zoom, save/load and duplicate. Rows stay one fixed height: text larger
than the row is clipped (per-row heights are a later, separate step — BACKLOG).

**R6 Keys.** One verb, "commit and move one cell": while editing, Enter → down, Shift+Enter → up, Tab →
right, Shift+Tab → left; clicking elsewhere commits and leaves the selection where the click puts it; Escape
cancels. In selection mode Tab/Shift+Tab move right/left, Enter/F2 still start an edit, and Delete/Backspace
CLEAR the cell's content but keep its formatting. Errors never block a commit: an entry that is a `#SYNTAX`,
`#ERR` or `#LOOP` commits and moves like any other (errors are values, spec §9.6). Typing a bare word stays
CoffeeScript (`hello` → `#ERR`; text needs quotes) — the spec's "everything is CoffeeScript" rule stands.

**R7 Formula bar** — part of the sheet (a frozen row ABOVE the column headers, like the headers), NOT a
toolbar item. 44 tall (the 44 rule: it is chrome); its field 36 tall (the same as a 100% row), 4 px inset top
and bottom. Left: the selected cell's address over the row-number column; then the field showing the selected
cell's SOURCE; text 16 px in both (address in `spreadsheetHeaderText`, source in `spreadsheetValueText`); a
1 px `spreadsheetHeaderRule` line under the bar. When the selected cell holds an error, its message
(`#KIND: message`, `spreadsheetErrorText`) shows in the bar between the field and the zoom control. Editing:
you edit where you start — typing on a selected cell or double-clicking edits in the cell; clicking the field
edits in the bar; whichever is not being edited mirrors the text live. Enter/Tab/Escape behave identically in
both (R6).

**R8 Zoom control** at the formula bar's right end: ONE button labelled with the current level ("100%") that
opens a menu of the R3 levels, the current one ticked. Not a −/%/+ triple (three targets in a narrow window).

**R9 Toolbar.** `SpreadsheetWdgt` declares its own toolbar (`buildToolbar`), docked top, tools in this order
(the strip drops tools into `»` from the end): Bold, Italic, Fill colour, Fewer decimals, More decimals,
Align left, Align centre, Align right, Slider in cell, Font, Bigger text, Smaller text. Fill colour opens the
existing colour picker (`Widget.pickColor` → `ColorPromptWdgt`). Slider in cell enters the formula
`new SliderWdgt 1, 100, 50, 1` into the selected cell (so the bar shows where it came from). Decimals apply to
number values (display only). Numbers are RIGHT-aligned by default, everything else LEFT; an explicit
alignment overrides.

**R10 Super toolbar.** Every toolbar has an entry in the Super toolbar. Add three: the new sheet toolbar, the
Dashboards toolbar and the Paint toolbar (the latter two exist today without an entry; no recorded reason).
The sheet toolbar's entry is ALWAYS offered (unlike Plots', which appears only once the lazy plots part has
loaded): the sheet toolbar lives beside the other toolbars, and its tools only ask the focus.

**R11 Desktop + example.** Desktop Maker **"Sheets Maker"** placed right after "Docs Maker"; its windows are
titled "Sheets Maker" (as Docs Maker's are). The Examples folder keeps an example titled **"Spreadsheet"** (singular, like
"Document"/"Slide"/"Dashboard"): the PARTY BUDGET (§4 Phase 4), opening a window titled "Party budget".

**R12 Text spill.** Left-aligned TEXT runs on into EMPTY cells to its right, stopping at the first cell with
content (or the viewport edge); gridlines under spilled text are hidden. Numbers never spill; right- or
centre-aligned text does not spill.

**R13 Icons** (control faces are icons, never typed — except where a typed face is the established family:
B, I, `</>`). Decimals: typed faces `.0` / `.00`. Fill colour: reuse the existing paint-bucket art. Slider in
cell: reuse the slider-node art. Three Super-toolbar entry icons: candidates reviewed by the owner in Phase 0.

**Not in this arc** (BACKLOG lines at close): per-row heights; a view (non-edit) mode for the sheet (every
other Maker has one); ranges (multi-cell selection, SUM over a range); insert/delete row/column; fill down;
pinch-to-zoom as a world-wide gesture.

## §2 How it works today (grep fresh; lines drift)

- **Geometry dials** — `SimpleSpreadsheetWdgt` fields `headerColWidth: 34`, `headerRowHeight: 20`,
  `colWidth: 68`, `rowHeight: 20`, `defaultViewportCols: 6`, `defaultViewportRows: 14`, `sheetCols: 26`,
  `sheetRows: 100`. Every placement derives from them via `@position()`: `_buildChromeNoSettle` (panel bounds,
  corner/column/row headers), `_cellRectLocal`, `_cellAtLocal` (hit test), `_viewportCols/RowsPartial`
  and `…Full` (ceil/floor of `(extent − header) / cell`), `_defaultExtent`, `minimumExtent` (constructor:
  headers + one cell). Resizing re-derives everything in the `_reLayout` override (bounds-first, then
  `_buildChromeNoSettle` + `_reconcileViewportNoSettle`). ⇒ Zoom and the formula-bar offset slot into the
  same derivations; nothing caches a pixel position.
- **Text** — a cell's scalar text is a passive `StringWdgt` child built in `CellWdgt.showScalarNoSettle`
  with `fontRole: theme.fonts.spreadsheetCell` (Arial 12) at box inset `(4, 2)`; the overlay editor
  (`CellWdgt._mountEditorNoSettle`) uses the same role and inset; header labels in
  `SheetHeaderCellWdgt._syncLabelNoSettle` use `fonts.buttonLabel` (12) at `(4, 2)`. ⚠ `buttonLabel` is
  shared with buttons — give headers their own role. Fonts are passed as role OBJECTS; a zoomed sheet passes
  a scaled copy (prototyped: works).
- **Opening size** — `src/examples/sheet/SpreadsheetApp.coffee` `buildWindow`: content extent
  `new Point 446, 280` wrapped by `FrameWdgt.extentWrappingPayloadAt`.
- **Pane vs page** — `FrameWdgt._bodyMargin` / `_hostsAPage` / `pageGutterAround`; precedents answering
  `wantsWindowPageGutter`: `DocumentViewportWdgt`, `StretchableWidgetContainerWdgt`, `FridgeMagnetsWdgt`.
  The F5 pixel law in `src/spreadsheet/CLAUDE.md` ("the sheet's outer top and left boundary carries no edge
  … nobody strokes right/bottom") is what R1 replaces.
- **Editor focus** — read as `world.editorFocusWdgt`; WRITTEN only by `WorldWdgt._setEditorFocusNoSettle`
  (the one write; it already normalises — a top-level window is never selected). Callers:
  `ActivePointerWdgt` (drop site, hold-for-menu site, click site), `Widget._destroyNoSettle`,
  `_softResetWorld`. Text toolbars mirror the focus through one dataflow edge world → toolbar
  (`TextToolbarWdgt._followTheEditedText`), announced by `_setEditorFocusNoSettle` and
  `WorldWdgt.noteStyleChanged(aWdgt)` (only when `aWdgt is @editorFocusWdgt`).
- **Text tools' protocol on the focus** (every `src/authoring/*ButtonWdgt` subclass of
  `EditorContentPropertyChangerButtonWdgt`): methods `toggleWeight`, `toggleItalic`, `setFontName`,
  `setFontSize`, `alignLeft`/`alignCenter`/`alignRight`; FIELDS read directly: `isBold`, `isItalic`,
  `fontName`, `originallySetFontSize`, `horizontalAlignment`, and the font-stack constants
  (`monoFontStack`, `justArialFontStack`, `timesFontStack`, …) from `StringWdgt.prototype`.
  `AlignButtonWdgt` falls back to a layout-spec alignment via `findRootForGrab` when the focus has no direct
  method.
- **Keys** — `SimpleSpreadsheetWdgt.processKeyDown` → `_processKeyWhileSelectingNoSettle` (arrows move +
  scroll-follow; Enter/F2 edit; printable → type-to-edit; everything else ignored — Tab, Delete, Backspace do
  nothing). While a caret edit is live the CARET owns keys: `CaretWdgt` Enter → `@accept()` (only when
  `@target.enterKeyAccepts?()`); Escape → `@cancel()`; Tab → `@target.tab`/`backTab`, which climbs to
  `CellWdgt.nextTab`/`previousTab` (swallowed today). `CaretWdgt.accept` escalates `"accept"` from the
  target; the click-away funnel (`ActivePointerWdgt`) calls `world.caret.accept()` too. Exactly two
  `accept:` definitions exist (`CaretWdgt`, `CellWdgt`), so adding an argument to the escalation is safe.
  `CellWdgt.accept` → `SimpleSpreadsheetWdgt.acceptCellEdit` → `_commitEditNoSettle`.
- **Errors** — `FormulaCompiler.commit` keeps `cell.source` and sets a `#SYNTAX`/`#LOOP` `SheetError`
  (`{kind, message}`); a throw at recompute becomes `#ERR` via `SheetCellRecord.dataflowNoteError` (and a
  `DATAFLOW_ERROR` console line from `DataflowEngine._reportStashedErrors`).
- **Record** — `SheetCellRecord` persistent `{sheet, address, source, widgetEntry}`; derived fields in
  `@serializationTransients`. A blank commit keeps the node (so a format on it survives a clear).
- **Toolbars** — a frame docks its content's `buildToolbar?()` at construction
  (`FrameWdgt._buildDockedToolbarNoSettle`); precedents: `DocumentWdgt`, `SlideWdgt`, `DashboardWdgt`,
  `PatchProgrammingWdgt`, `ImageWdgt`. `SpreadsheetWdgt` declares none.
- **Super toolbar** — `src/authoring/SuperToolbarWdgt.coffee` `_toolbarItems`: Text, Useful text snippets,
  Slides, Plots (`if PlotsToolbarCreatorButtonWdgt?`), Patch programming components, Windows. Creator
  buttons extend `ToolbarCreatorButtonWdgt` (`src/app-kit/`) and build their window with `_buildToolWindow`.
  `DashboardsToolbarWdgt` and `PaintToolbarWdgt` (both `src/authoring/`) have no creator.
- **Desktop / folder** — `AppCatalog.entries` (titles + icon thunks, KEYED BY CLASS NAME STRING);
  `WorldWdgt.createDesktop` `addOpener` order (How to save?, Docs Maker, Draw, Slides Maker, Dashboards,
  Patch programming, Generic panel, Super toolbar, Fizzytiles); `ExamplesFolderWindowWdgt.whenReadyToBeBroughtUp`
  (C-F converter, Slide, Dashboard, Document, Spreadsheet). Parts (`buildSystem/parts.json`): `spreadsheet`
  (lazy, `src/spreadsheet`, no `requires`), `example-sheet` (lazy, `requires: ["app-kit"]`,
  `src/examples/sheet`), `authoring` (lazy, `requires: ["app-kit"]`, `src/authoring` + `src/authoring-icons`),
  `demos` (lazy, dev-only, owns `src/demos-icons` — where `PaintBucketIconAppearance` lives today, named only
  by a demo-menu row).
- **Icons in play** — `SliderNodeIconAppearance` (`src/authoring-icons`, legacy vector);
  `PaintBucketIconAppearance` (`src/demos-icons`, legacy vector); `SpreadsheetIconAppearance`,
  `DashboardsIconAppearance`, `SprayCanIconAppearance` (`src/icons`, size-aware, the desktop family);
  `BrushIconAppearance` (`src/authoring-icons`, legacy). Super-toolbar entry icons today:
  `TextToolbarIconAppearance` (a "T" outline), `SlidesToolbarIconAppearance`, `WindowsToolbarIconAppearance`
  (a window frame), `AllPlotsIconAppearance`, `PatchProgrammingComponentsIconAppearance`,
  `TemplatesIconAppearance` (snippets) — all legacy 100×100 vector. Typed faces: `TypedFaceIconAppearance`
  subclasses (`FormatAsCodeIconAppearance`: `faceText: "</>"`, `fonts.codeToolFace`).
- **Tests that open a sheet (20):** macroDesktopShortcutIcons, macroSpreadsheetColorCell,
  macroSpreadsheetEditCancel, macroSpreadsheetDropWidgetIntoCell, macroSpreadsheetLoopRejected,
  macroSpreadsheetErrorPropagation, macroSpreadsheetScrollWheel, macroSpreadsheetRefsRecalc,
  macroSpreadsheetDuplicate, macroSpreadsheetTiltedClickSelectsCell, macroSpreadsheetLiteralEntry,
  macroSpreadsheetScrollKeyboardFollow, macroSpreadsheetDragWidgetOutOfCell, macroSpreadsheetResizeViewport,
  macroSpreadsheetSelection, macroSpreadsheetEditCaret, macroSpreadsheetScrollRichCellRetain,
  macroSpreadsheetOpenGrid, macroSpreadsheetSliderCell, macroSpreadsheetSecondsCell. Expect all to change
  pixels (and some to need re-authored positions); the serialization rigs carry spreadsheet checks too
  (`Fizzygum-tests/scripts/serialization-roundtrip-headless.js`).
- **Scripts that list apps:** `Fizzygum-tests/scripts/staleness-census.js` (`APPS` array names
  `SpreadsheetApp`), `parts-lazy-icons-headless.js` (desktop/folder tiers; its comments count the Makers and
  the five example doors).

## §3 The distilled argument

The six complaints are three missing rules plus one misclassification. Fixing them case by case would add
spreadsheet exceptions to the focus write, the frame, the caret and the toolbar; instead each fix is an
existing mechanism given its general form:
- the PAGE capability already exists → the sheet answers it (R1);
- the focus write already normalises what a click names (a top-level window is never selected) → it learns
  one more general normalisation, "a widget that is focused as a whole" (R4);
- the text tools already duck-type the focus → they ask the focus for its *style subject* first, and a sheet
  hands over its selected cell's format (R4/R5) — ranges later hand over a range;
- the caret already escalates `accept` from its target → the escalation carries which key ended the edit
  (R6), and Tab's existing climb gets a real handler;
- `buildToolbar`, the Super toolbar's creator buttons, `AppCatalog` + `createDesktop`, and the Examples doors
  already exist → the sheet uses them like every other Maker (R9–R11);
- zoom is the re-layout the F6 resize path already performs, at scaled dials (R3).

## §4 Phases

### Phase 0 — icons (owner review; the arc's only mid-way stop)
Render candidates IN REAL TOOLBAR CELLS on `index-sw.html` via a runtime patch (pattern:
`Fizzygum-tests/.scratch/sheet-ux/proto.js` + `shoot.js`; `.scratch/` is gitignored), at dpr 1 and 2, and
present a LOCAL html page (opened with `open`). Show: the sheet toolbar with `.0`/`.00` typed faces,
paint bucket (fill), slider node (slider in cell); the Super toolbar with all nine entries. For each of the
three new entries show (a) the existing desktop icon of its subject reused (`SpreadsheetIconAppearance`,
`DashboardsIconAppearance`, `SprayCanIconAppearance`) and (b) a note that a new glyph in the entry family can
be drawn instead with the `convert-icon-size-aware` skill. Owner picks; draw anything new with that skill.
Moving `PaintBucketIconAppearance` into `src/authoring-icons/` (an icon belongs to whatever names it; the
demo row keeps working because `demos` requires `authoring`).

### Phase 1 — page, sizes, zoom geometry
1. `SimpleSpreadsheetWdgt.wantsWindowPageGutter: -> true`; the sheet's four 1 px edges in
   `stretchablePageEdge`, painted by the sheet's own appearance AFTER its children (`SheetAppearance.paintStroke`,
   which the clipping mixin calls), so no partial cell, header fill or hosted widget paints over them; the new
   pixel law is recorded in `src/spreadsheet/CLAUDE.md`.
2. Base dials to R2 (48/36/104/36), a new `Theme.fonts.spreadsheetHeader` (Arial 16) for header labels,
   `fonts.spreadsheetCell` size 16. Text vertically centred (a computed top inset from the row height and
   the font's line height, the same for resting text, the editor and header labels).
3. Zoom: `zoomFactor: 1` prototype default (own-only-when-set, NOT in `serializationTransients`); every dial
   read goes through one accessor per dial (e.g. `_colWidth()` = `Math.round(@colWidth * @zoomFactor)`),
   fonts through a scaled role copy; a public `setZoomFactor(f)` re-derives (chrome + viewport + every
   visible cell's text) and keeps the selection visible. Grep `@colWidth|@rowHeight|@headerColWidth|@headerRowHeight`
   across `src/spreadsheet/` and convert every read.
4. Formula-bar offset: one `_formulaBarHeight()` (Theme dial `spreadsheetFormulaBarHeight` = 44, never
   zoomed) added to every y derivation (column headers, row headers, panel, cell rects, hit test, viewport
   row counts, default extent, minimum extent). The bar widget itself lands in Phase 3; reserve the space
   here only if Phase 3 follows in the same push (it does).
5. Opening extent: 5 × 10 visible (`defaultViewportCols/Rows` 5/10; `_defaultExtent` and
   `SpreadsheetApp.buildWindow` agree — derive the app's extent from the sheet's `_defaultExtent` rather than
   a literal).
6. Tests: new `macroSpreadsheetPageAndZoom` (gutter on all sides incl. under a docked band; edge present;
   zoom 150% → dials and visible counts; zoom survives duplicate). Serialization rig: a zoomed sheet
   round-trips its zoom.

### Phase 2 — selection owns the toolbar; formatting on the record; keys
1. **Capability** `focusesAsAWhole: -> true` (name by its question; on `SimpleSpreadsheetWdgt`). In
   `WorldWdgt._setEditorFocusNoSettle`, map `aWdgt` to its nearest ancestor-or-self answering it BEFORE the
   existing top-level-window rule. Document it beside that rule. A hosted widget in a cell (a slider) still
   receives its own drags; only the focus names the sheet.
2. **Style subject.** `EditorContentPropertyChangerButtonWdgt._styleSubject: -> focus = world.editorFocusWdgt;
   focus?.textStyleSubject?() ? focus`; every text tool reads and writes `@_styleSubject()` instead of
   `world.editorFocusWdgt` (Bold, Italic, FormatAsCode, ChangeFont incl. `setFontNameFromMenu`,
   Increase/DecreaseFontSize, the three Align buttons — `AlignButtonWdgt`'s layout-spec fallback keeps using
   the focus itself). The sheet answers `textStyleSubject` with a `SheetCellStyle` (new plain class, spreadsheet
   part) bound to the selected address: the FIELDS the tools read (`isBold`, `isItalic`, `fontName`,
   `originallySetFontSize`, `horizontalAlignment`, the font-stack constants copied from `StringWdgt.prototype`)
   snapshot the record's format; the METHODS write it and ask the sheet to re-present that cell and
   `world.noteStyleChanged sheet`.
3. **Record format.** `SheetCellRecord.format` (undefined until set; a plain object
   `{bold, italic, fontName, fontSize, align, fill, decimals}`; serialized; copied by the generic deep copy).
   The cell's view derives from it (font role, alignment, later fill/decimals). Formatting an empty cell
   creates its record with a blank source.
4. **Announce selection moves**: whenever `selectedCol/Row` change, `world.noteStyleChanged @` (a no-op unless
   the sheet is the focus), so the tools' active states follow the keyboard.
5. **Keys** (R6). `CaretWdgt` Enter → `@accept (if shiftKey then "Shift+Enter" else "Enter")`, and
   `accept: (how) ->` escalates `"accept", how`; `CellWdgt.accept(how)` → `acceptCellEdit(how)` → commit, then
   move down/up when `how` says so (click-away passes nothing → stays). `CellWdgt.nextTab`/`previousTab` →
   commit + move right/left (the commit tears the live caret down — `_teardownEditorNoSettle` already does).
   Selection mode: Tab/Shift+Tab move; Delete/Backspace clear (blank commit through the normal path, which
   also clears a dropped widget entry; format kept). Moves clamp at the sheet edge and scroll-follow.
6. Tests: `macroSpreadsheetEnterTabMoves` (both modes, all four directions, click-away stays, Delete keeps
   bold); `macroSpreadsheetToolbarFollowsSelection` (arrow to a cell, Bold, the arrowed cell is bold and the
   previously clicked one is not; scroll away and back keeps it). Serialization rig: a bold cell's format
   round-trips save/load and duplicate.

### Phase 3 — toolbar, formula bar, zoom control, alignment, fill, decimals, slider
1. `SheetToolbarWdgt extends TextToolbarWdgt` in `src/authoring/` (it IS the text toolbar plus the sheet's
   tools: it inherits the focus-following edge, the docking side and the font-menu stash), items in R9's
   order.
   `SpreadsheetWdgt.buildToolbar: -> new SheetToolbarWdgt` ⇒ parts.json `spreadsheet` gains
   `requires: ["authoring"]` (`check-part-edges.js` enforces).
2. New tools (all `EditorContentPropertyChangerButtonWdgt`, duck-typing the subject): `FillColorButtonWdgt`
   (`subject.pickFillColor?()` → the sheet's `pickColor`), `FewerDecimalsButtonWdgt` / `MoreDecimalsButtonWdgt`
   (typed faces; from an undefined format, start from the displayed number's decimals), `SliderInCellButtonWdgt`
   (`subject.enterSource?` with R9's formula, through the normal commit path).
3. View rules in `CellWdgt`: fill (painted under the edges by `CellAppearance`), decimals (number values
   only, display), default alignment (numbers right, else left; format overrides), font/size/bold/italic from
   the format × zoom.
4. `SheetFormulaBarWdgt` (spreadsheet part) — DERIVED chrome like the headers (destroyed and rebuilt on
   restore, never adopted): address label, a field with the text-field look (`textFieldFill`,
   `textFieldCornerRadius`), the error label, the zoom button (a `SimpleButtonWdgt` labelled "NN%", opening a
   `MenuWdgt` with the six levels, current one ticked). Editing per R7: a click on the field starts an edit of
   the selected cell with the caret in the field; the other view mirrors on the caret's `reactToKeystroke`
   escalation; commit/cancel/move exactly as Phase 2. While not editing the field shows the selected
   record's source (a widget-entry cell has a blank source — show nothing).
5. Tests: `macroSpreadsheetFormulaBar` (source shown; edit in bar mirrors to cell; Enter moves; error
   message shown), `macroSpreadsheetFormatting` (fill, decimals, right-aligned numbers, slider in cell),
   `macroSpreadsheetZoomControl` (menu levels, ticked current, re-layout). `fg menusweep` must stay green
   (new menu rows: the zoom menu).

### Phase 4 — Super toolbar entries, Sheets Maker, the party budget
1. Creator buttons `SheetToolbarCreatorButtonWdgt`, `DashboardsToolbarCreatorButtonWdgt`,
   `PaintToolbarCreatorButtonWdgt` (`src/authoring/`, `_buildToolWindow new X`), icons per Phase 0. Super
   toolbar order: Text, Useful text snippets, Slides, Sheet, Dashboards, Plots (if loaded), Paint, Patch
   programming components, Windows.
2. Move `SpreadsheetApp` into `src/spreadsheet/` (door and engine in ONE part, the way the Makers live inside
   `authoring`: one click, one fetch); AppCatalog `"SpreadsheetApp": {title: "Sheets Maker", icon:
   SpreadsheetIconWdgt}`; `createDesktop` `addOpener "SpreadsheetApp"` right after `"SimpleDocumentApp"`;
   `SpreadsheetWdgt.colloquialName` → `"Sheets Maker"` (window title, as `DocumentWdgt` → "Docs Maker").
   Rewrite the packaging section of `src/spreadsheet/CLAUDE.md` and the `SpreadsheetApp` header comment.
3. New `SampleSheetApp` in `src/examples/sheet/` (part `example-sheet`, `requiredParts: ["spreadsheet"]`,
   `slot: "sampleSheetWindow"`), AppCatalog `"SampleSheetApp": {title: "Spreadsheet", icon: SpreadsheetIconWdgt}`,
   in `ExamplesFolderWindowWdgt` in place of `"SpreadsheetApp"`. Window title "Party budget"; content
   (strings need quotes):
   `A1 "Party budget"` (bold) · `A3 "Guests"`, `B3 new SliderWdgt 1, 40, 12, 1`, `C3 Math.round B3` ·
   `A4 "Per guest"`, `C4 15` · `A5 "Total"`, `C5 C3 * C4` · `A6 "Budget"`, `C6 250` · `A7 "Left"`,
   `C7 C6 - C5` · `A8 "Status"`, `C8 if C5 <= C6 then Color.SEAGREEN else Color.TOMATO` (verified to
   evaluate: C3=12, C5=180, C7=70, C8 a swatch). Close policy `'close'` (a sample is not worth a save prompt,
   as `SampleDocApp`).
4. Update `staleness-census.js` `APPS`, `parts-lazy-icons-headless.js` comments/samples, `AppCatalog`'s
   "desktop's nine" comment, and anything else a grep for `SpreadsheetApp`/`example-sheet` finds in BOTH
   repos (`scripts/` reads internals too).
5. Tests: `macroSuperToolbarOpensEveryToolbar` (the three new entries open their toolbars);
   `macroSampleSheetPartyBudget` (opens titled "Party budget"; drag the slider → C3/C5/C7 and the swatch
   follow). `fg parts` and `fg apps` legs green.

### Phase 5 — text spill (R12)
The sheet computes, per visible row at reconcile, how far each left-aligned text cell may run (consecutive
EMPTY cells to its right inside the viewport); the cell's text child widens over them and the cell's clip
widens with it; covered neighbours skip their left edge (`paintGridEdges`). Recompute on any commit in the
row, scroll, zoom and resize. Test `macroSpreadsheetTextSpill` (title spills; typing in the neighbour cuts it;
a number does not spill).

### Phase 6 — docs and close
- `docs/architecture/visual-design-system.md` §4.10: the spreadsheet moves from the PANE list to the PAGE
  list; a row for the formula bar and the zoom control; §4.2 note that a sheet's zoom is the touch answer.
- `src/spreadsheet/CLAUDE.md`: geometry (R2/R3), the page edge law (replacing F5's outer-boundary rule),
  the editing model (R6/R7), formatting on the record (R5), packaging (Phase 4).
- `docs/specs/dataflow-engine-spec.md` §9 where it describes the sheet's UI; `NOMENCLATURE.md` if a term
  is added; `src/macros/MACRO-PATTERNS.md` for any new verb.
- BACKLOG lines for "Not in this arc" (§1).
- `git mv` this plan to `docs/archive/` with a status stamp and an `archive/INDEX.md` line; memory note
  `spreadsheet-ux-brainstorm.md` → final state.

## §5 Central risks

- **Recapture scale.** Every test that opens a sheet changes pixels (sizes, gutter, edges, the new toolbar,
  the bar). Attribute before recapturing (the attribution rig of the toolbar arc:
  `Fizzygum-tests/.scratch/toolbar-proto/attribute.js` + `pair.js`, or `fg diffpage`); several tests click
  cells by position and may need their macros re-aimed (aim by MEANING — `MACRO-PATTERNS.md`).
- **Focus normalisation reach.** `focusesAsAWhole` changes what every click inside a sheet makes the focus,
  including the overlay editor, a hosted slider, and a sheet nested in a document. Check the selection ring
  (`WorldWdgt._widgetBeingEdited`, `FrameWdgt.hostsSelectionRingOf`) frames nothing new, and that the caret's
  click-away funnel still commits.
- **Two editors mirroring** (R7) must never both hold a caret; the edit state stays the sheet's
  (`_editing`, `_editCol/Row`), with one editor widget at a time and the other a passive mirror.
- **Zoom × integer geometry.** Every dial rounds; fractional placement fails the suite
  (`NON_INTEGER_GEOMETRY`). Text sizes may be fractional (snapped by the renderer).
- **Part edges.** `spreadsheet` requiring `authoring`; `SampleSheetApp` in `example-sheet`; the moved paint
  bucket. `check-part-edges.js` and `fg parts` are the judges.
- **Determinism.** Nothing here may read wall-clock time; zoom and mirroring are event-driven
  (`Fizzygum-tests/DETERMINISM.md`).

## §6 Verification protocol

- Inner loop per phase: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (launched with
  `run_in_background`, never piped).
- Before ANY recapture: attribute every failing test's pixel change to a ruling (diff clusters + reference
  vs live crops); a change no ruling explains is a finding, not a recapture.
- Recapture: `fg recapture --auto --dprs=1,2` then `fg recapture --auto --pointer=finger --dprs=1,2`;
  diff the recaptured set against the attributed set (they must be equal).
- New tests: capture both densities and both pointers; prove each with a follower
  (`node scripts/run-sequence-headless.js --pointer=<p> SystemTest_<new> SystemTest_macroWindowsEmptyCollapsingUncollapsing`,
  zero `WORLD_INVENTORY_` lines) on both pointers.
- Close: `fg gauntlet` (all legs; `serialization`, `menusweep`, `pinsweep`, `parts`, `apps` are the ones
  this arc stresses) + `fg homepage`, then `fg build` back to dev.

## §6a Verification (2026-11-04)

- **Build:** every static gate green; the argument-hole ratchet tightened 3 → 2 (the no-shadow scope named once,
  `Appearance._paintInUnshadowedScope`); `setZoomFactor` joined the public-API allowlist.
- **Recapture, attributed first:** the 19 existing `macroSpreadsheet*` tests changed, each by a ruling (gutter
  and edge, the 100% sizes, the formula bar, the docked sheet toolbar, numbers right, text centred on its
  row); 16 of them at finger too (`ResizeViewport`, `ScrollWheel`, `ScrollRichCellRetain` are mouse-only).
  Nothing outside the spreadsheet family changed. Both `fg recapture --auto` gates (mouse, finger; dpr 1 and 2)
  ended with the full suite green.
- **New tests** (both densities, both pointers, each proven with a follower — zero `WORLD_INVENTORY_` lines):
  `macroSpreadsheetPageAndZoom`, `…EnterTabDeleteMoves`, `…ToolbarActsOnSelection`,
  `…FormulaBarEditsAndErrors`, `…TextSpill`, `macroSampleSheetPartyBudget`, `macroSuperToolbarOpensEveryToolbar`.
- **Close:** `fg gauntlet` 19/19 legs green (dpr1, dpr2, webkit, finger, apps, parts, menusweep, pinsweep,
  graph, paint, tiernaming, settle, capstone, refs, revisits, census, serialization, storage, vmtruth) +
  `fg homepage` OK.
- **Found while verifying, fixed before the close:** (1) looking at the recaptured references, the
  focus-as-a-whole sheet inside a tilted (editable) container was outlined whole — `_widgetBeingEdited` walked past the sheet to the container; a focus that
  shows its own selection now opts out itself (`providesAmenitiesForEditing: false`, honoured on the focus).
  (2) the `settle` leg: rebuilding the formula bar on duplicate/restore built its zoom button, which
  settles, inside the copy/restore notifications — the bar is ADOPTED like the cells. (3) the `webkit` and `finger` legs:
  an engine-made error message differs between V8 and JSC while WebKit reuses Chrome's references — the error test shows a
  message it throws itself (`throw "over budget"`).

## §6b After the close: the owner's two nitpicks (2026-11-04)

Reported on the pushed arc (Fizzygum `0485b530`, tests `5a6cc24a3`), reproduced on the real build before any
change (probe: `Fizzygum-tests/.scratch/sheet-ux/nits.js`), and fixed the same day:

- **The alignment tools jumped as the selection moved.** `SheetCellStyle` answered a DEFAULT alignment for a
  cell that sets none (numbers right, the rest left), so align-left lit on an empty or text cell and
  align-right on a number. The style now answers only the alignment the cell's format SETS — none for
  the rest, so no tool is active there — while what the cell SHOWS is unchanged (`_textLookFor`: numbers
  right, else left, as Phase 3 step 3 ruled). The duplicate of the sheet's default rule in the style died with it.
- **A fresh sheet ignored typing until a click.** A1 showed selected, but the click on the launcher had
  made the LAUNCHER the editor focus and the sheet joined the keyboard receivers only on a click in it.
  `WorldWdgt.openFrameWith` now selects the content of a window it opens when that content is focused
  as a whole (only the sheet answers): it shows its own selection from the start, so the tools and the
  keys act on it at once.
- **Found while reproducing the second:** a sheet clicked once stayed a keyboard receiver for good — after a
  click on the desktop the arrows still moved its selection, and a key typed into another text started an
  edit in the sheet (whose caret then replaced the text's). The sheet now joins the receivers when built
  (as `VideoPlayerWdgt` does) and its `processKeyDown` acts only while it is `world.editorFocusWdgt` and no
  caret is live. `_takeKeyboardFocus` and its other-sheets sweep are gone: one focus means no lockstep.
- **Verification:** the dpr1 suite failed exactly 23 spreadsheet tests, every one on pixels; a per-image
  attribution of the diff page showed each change to be ONE 44 × 44 toolbar tool cell (two in `Duplicate`,
  whose screenshot shows two toolbars): an align tool no longer lit on a cell that sets no alignment, and in
  the party budget the bold tool now lit, its sheet opening focused on its bold title. New test
  `macroSpreadsheetKeysFollowFocus` (typing into a fresh sheet with no click, the tools on a number, a
  text and an empty cell, keys passing a sheet after a desktop click, two sheets).
- **Then the menus' ticks** (pushed as Fizzygum `4625354b`, tests `20b6115b8` before it): the toolbar's
  font menu ticked nothing, and — in the owner's own screenshot — a pinned zoom menu kept ticking 100%
  after a zoom to 75% (this arc's `ticked:` was a build-time snapshot). Both are now
  `MenuRowReflectionSpec` views: the zoom rows read the sheet (`currentZoomFactor`; the sheet announces
  every zoom), the font rows the TOOLBAR, the stable mirror of whatever is being edited
  (`TextToolbarWdgt.currentFontName`, re-announced from `mirrorTheEditedText`). One definition of the
  style the focus hands over now serves the tools and the toolbar (`WorldWdgt.editorStyleSubject`), and
  one font list both fonts menus (`StringWdgt.fontStackMenuEntries`, the text's own `_fontStackMenuEntries`
  lifted to the class). The zoom menu is editor chrome like the font menu, so choosing a level leaves
  the sheet the focus. Git history shows the toolbar's font menu never ticked; the text's own fonts menu
  always did. Suite: 7 tests moved — the toolbar font menu's reserved tick column in
  `macroFontMenuOpensAtVisualPositionInScrolledPane` (which now gives its stand-alone button a real toolbar as
  holder), and six inspectors whose StringWdgt member list lost the instance method. New test
  `macroSpreadsheetMenuTicksStayLive`. Same class, left as designed: the toolbar overflow's rows tick
  their tools at pop time (`OverflowChevronButtonWdgt`, "derive-at-pop").

## §6c The last build-time ticks (2026-11-04)

After §6b only two rows in `src` still fixed their tick when their menu was built, both exposed by
pinning. The toolbar overflow ("»", `OverflowChevronButtonWdgt`) ticked a hidden tool by `isActiveTool` at
pop time; its "derive-at-pop" design assumed a transient menu, which pinning makes it no longer. And
`SimpleTextWdgt`'s "Soft wrap" row fixed both its tick and its ACTION at build (`softWrapOff` while
wrapping, `softWrapOn` while not), so a pinned copy clicked twice did nothing the second time, beside
TextWdgt's own row, which already reflected `isSoftWrapping`.

- **Overflow rows reflect their tool's CELL** (`GlassBoxBottomWdgt.holdsActiveTool`, which the cell's
  own look now reads too). The cell is already told at every move of its tool's state by whoever
  decides it (`noteItemStateChanged`: TextToolbarWdgt on a focus or style move, PaintToolbarWdgt at
  its arrange, the pointer on hover/press), so it passes the news on with `markNonValueChange @`. A
  paint toolbar tells it from its arrange, which makes the cell the second layout-station announcer
  beside `ViewportWdgt._reLayoutScrollbars`: a paint tool's row re-ticks one cycle later. A pinned
  overflow is a palette of the tools it was popped with: its names and pictures stay as popped, its
  ticks are live.
- **One "Soft wrap" row for every text.** SimpleTextWdgt keeps TextWdgt's row (it removes it unless
  it is its viewport's LONE text, `_isMyViewportsLoneText`) and specialises the row's verb:
  `toggleSoftWrap` → `setSoftWrap not @isSoftWrapping()`, whose core flips the text's own `softWrap`,
  takes the viewport with it only for a lone text, and announces. One state (the text's `softWrap`), one
  reader, one verb name, one row. `softWrapOn`/`softWrapOff` are gone; the row now sits where TextWdgt
  puts it, before "Run contents".
- **The `ticked:` option is gone.** No caller passed it any more, and a tick always shows somebody's
  state, so `CommandSpec`'s `ticked` and its read in `MenuItemWdgt` are deleted: a reflection is the
  one door to a tick. Guidelines §10 states it, and adds that a toggle row's ACTION reads the state
  when clicked.
- **Found by the capstone gate, fixed at its root (owner's choice): a copy comes back DETACHED.** The
  new test is the first to pop a PAINT toolbar's overflow, and the gate counted 8 end-of-cycle pushes
  from the rows' miniatures: `_miniatureOf` resized and destroyed a `fullCopy` whose `parent` was still
  the ORIGINAL's parent. The Duplicator kept that outside widget by reference, as it keeps any, though
  that parent did not hold the copy. So the copy answered `isOrphan()` false and `root()` the world,
  and both acts pushed layout into the live strip outside any settle. The serializer had always returned
  a detach-root detached (reference §4, rule 3); the Duplicator now does the same
  (`_cloneContentInto`: an outside `parent` → `undefined`), one rule for both walkers. An in-page twin
  measured it first: 363/363 tests passing, pixels unchanged, 0 careless pushes suite-wide. One reader
  depended on the stale pointer: the hand inflated a template's copy dragged out of a toolbar because
  `oldParent instanceof GlassBoxBottomWdgt`, and no test covered it. The template branch now states
  where the pick-up starts (`grab`'s `origin`, the template's situation), the inflate reads it from
  `@grabOrigin` (the fact the sticky drop already used), and the overwrite of `@grabOrigin` after the
  grab is gone. New test `macroTemplateDraggedOutOfToolbarInflates` pins it. The next gauntlet's
  settle leg then caught `CACHED_DERIVATION_DIVERGED -- root is broken` in two duplication tests. A
  copied menu's rows viewport had cached its root as ITSELF inside the walk (a descendant's hook
  climbed `root()` before the viewport's `parent` was linked), and the Duplicator wired `parent`
  directly, without announcing it, so the cache stayed "current". Some later step of the old path
  happened to bump the structure version and hid it. Every `parent` link the Duplicator writes is now
  announced as `_addChild` announces one (`noteStructureChange`). A copy also no longer
  sends grab notifications to a parent that never held it (`_reactToChildGrabbed`, a `whereFrom`): a
  stacked widget's copy picked up by `duplicateAndPickItUp` keeps its copied ratio state, as the
  "Duplicate" menu's copy always did.
- **Verification.** Changed set predicted before building and attributed on the dpr1 diff page
  before recapture: one image, `macroTabletDockedToolbarChevron` image_2 (the overflow reserves its
  tick column); `fg recapture --auto` at dpr 1+2, mouse then finger, recaptured only it, both gates
  green. Two new tests, each captured at both densities on both pointers, followed by
  `macroWindowsEmptyCollapsingUncollapsing` on both pointers with no world-inventory line, and each
  proven to FAIL with its defect planted through `PRELUDE_JS`: `macroPinnedMenuTicksFollowTheirState`
  (rows that never re-read their reflection, and a Soft wrap row whose action always unwraps), and
  `macroTemplateDraggedOutOfToolbarInflates` (the grab's origin dropped: the copy arrives 44 x 44).
  Close: `fg gauntlet` 19/19 green with no retries (922 s), and `fg homepage` OK.

## §7 Rejected alternatives (do not re-attempt)

- **Picture zoom** (`setScaleFactor` on the sheet or window): text blurs — measured 2026-11-04.
- **Formula bar as a toolbar item spanning several cells:** breaks pack / spread-while-full / grid fill /
  side bar (every toolbar rule would need a span exception), and a floating toolbar would carry a field with
  no sheet behind it.
- **Refusing a commit on a malformed formula (Excel's dialog):** only `#SYNTAX` is knowable at commit;
  `#ERR`/`#LOOP` appear later — a partial exception against "errors are values".
- **Bare words as text / "=" for formulas:** overturns the spec's "everything is CoffeeScript" (owner kept it).
- **44-tall rows for touch:** 5–6 rows per window; cells are content (design doc §4.2).
- **Styling the cell's text widget (today's accident):** derived, so lost on scroll and save/load.
- **The sheet re-writing the focus after every move:** a patch on top of the click's own write; the
  capability in the one focus write is the rule.
- **A −/%/+ zoom triple:** three targets where one menu button does.
- **A status-bar message in the window's bottom strip:** would make the strip a payload-content host for
  every window; the bar sits next to the cause.

## §8 References

- Memory: `spreadsheet-ux-brainstorm.md` (rulings, evidence, prototype locations).
- Prototype rig (gitignored, local): `Fizzygum-tests/.scratch/sheet-ux/` — `proto.js` (runtime patch: page,
  sizes, centring, formula bar, sheet toolbar, budget), `shoot.js` (renders), `zoom.js` (close-ups),
  `probe.js` (the focus/style/scroll probe), `index.html` (the review page the owner ruled on).
- `src/spreadsheet/CLAUDE.md`, `src/dataflow/CLAUDE.md`, `docs/specs/dataflow-engine-spec.md` §9,
  `docs/architecture/visual-design-system.md` §4.2/§4.10, `docs/archive/toolbar-grid-and-bar-run.md`,
  `docs/architecture/build-and-packaging.md` §2 (parts, doors), `src/macros/MACRO-PATTERNS.md`.

## BACKLOG ledger

Items of `docs/BACKLOG.md` this arc closes (they leave that file when it lands):
- [x] The spreadsheet's two default extents disagreed (redesign W1 follow-up): `SpreadsheetApp` now
  opens its window around the sheet's own `defaultExtent()`, the one derivation.
- [x] The spreadsheet's last row was clipped by the window's rounded bottom corners (window-page-gutter
  survey): the sheet is a PAGE, so the gutter keeps it clear of the corners.
- [x] The last two build-time ticks (§6c): the toolbar overflow's rows and `SimpleTextWdgt`'s "Soft wrap"
  row are `MenuRowReflectionSpec` views, and the `ticked:` option is gone; a copy comes back detached.

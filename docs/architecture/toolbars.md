# Toolbars — who a tool works for

How a toolbar is built, where it can stand, and what each of its tools acts on. Present tense, verified
against `src/` on 2026-11-17. The rulings this describes, the alternatives they rejected and the measurements
behind them live in `docs/archive/docked-and-floating-toolbars-plan.md` (§4 rulings R1–R10 and decisions D1–D8,
§11 rejected alternatives).

**The rule in one paragraph.** A toolbar answers one question: *who do I work for*. Docked in a window's edge
slot, it works for that window, and its reach is that window's content and everything inside it; floating, it
works for the person. Each tool resolves its own subject from that answer, by its own kind, so a toolbar that
mixes kinds is right by construction. Where nothing in reach is something a tool applies to, the tool does
nothing: a docked toolbar never falls back to working for the person.

---

## 1. Construction

- **One construction for every toolbar.** `ToolbarWdgt` (`src/app-kit/`) is a `ViewportWdgt` around a
  `ToolPanelWdgt` grid. `ToolPanelWdgt._addNoSettle` stands each item in a **tool cell**
  (`GlassBoxBottomWdgt`). An item that acts on its own press (`actionableAsThumbnail: true`) is wrapped bare,
  and a tap on its cell reaches it. Any other item is there to be dragged out, and the cell puts a **lid**
  over it (`GlassBoxTopWdgt`), which takes the press and hands out a copy.
- **A subclass is an item list.** `_toolbarItems` returns the items, each a literal `new X` so the boot
  dependency finder sees the edge, and `dockSide` names the edge slot it takes by default (`'left'`; the text
  bar, and the sheet bar with it, say `'top'`). Everything else (docking, the refresh, the transfers of a paint tool) is the
  base's. `PaintToolbarWdgt` adds the stock paint-tool sources (§4.3), and `TextToolbarWdgt` the font menu's
  reader (`currentFontName`, §5.1).
- **Born locked.** `_buildAndConnectChildrenNoSettle` adds the items and disables drags, drops and editing
  on the strip: its items are tools to use or to drag out, never editable content.
- **Two homes, one object.** A toolbar is always a `FrameWdgt`'s payload. FLOATING, that frame is a desktop
  window (a toolbar creator button builds one, `ToolbarCreatorButtonWdgt._buildToolWindow`; the Super toolbar's app
  another, `world.openFrameHuggingPayload`). DOCKED, it is a
  band in a host window's edge slot. A Maker declares its toolbar with `buildToolbar`, and
  `FrameWdgt._buildDockedToolbarNoSettle` frames it and docks it at its `dockSide`
  (`FrameWdgt._dockFrameNoSettle`). The same object moves between the homes: a band's grip dragged onto the
  desktop makes it a window, and a toolbar window dropped on a window's edge, after the drag-embed dwell,
  makes it a band.
- **Hidden tools.** Tools the strip cannot show are reached through its overflow chevron
  (`OverflowChevronButtonWdgt`). Each row clicks the widget a tap on that cell reaches
  (`GlassBoxBottomWdgt.thumbnailClickReceiver`, `triggerToolFromMenu`), so a row and a tap obey one dispatch
  contract. A docked bar's chevron stays usable under a person's grip: a drag of a window's resize grip stops at
  the smallest extent at which every docked bar keeps its one-slot run (`ToolbarWdgt.shortestDockedRun`) and
  stays inside the window, and at which a strip carrying a title keeps close, collapse and its edit toggle whole
  (`FrameBarWdgt.shortestStripKeepingEveryPiece`): ONE floor, `FrameWdgt.smallestExtentKeepingMyControlsUsable`,
  asked by `FrameGripWdgt._extentMyDragAsksOfMyTarget`. A strip with no title (a toolbar window's, along its short
  side) is not floored. That is the person's gesture only, never a minimum: code can still force a window to any
  extent; in view mode the bands are disengaged and ask no floor, while the strip still does.
- **Chrome.** `ToolbarWdgt.excludedFromEditorFocusTracking` answers true: a press anywhere in a toolbar
  neither takes nor clears the editor focus, which is what its property tools act on. Every menu answers it
  too (`MenuWdgt`, pinned or not), a toolbar's overflow menu and the Fonts menu among them, so a menu's rows
  act on the selection without moving it. A prompt is no menu: the field a person types into takes the focus.

The toolbars: `TextToolbarWdgt`, `SheetToolbarWdgt` (the text bar plus the sheet's tools), `PaintToolbarWdgt`,
`SlidesToolbarWdgt`, `DashboardsToolbarWdgt`, `PatchProgrammingToolbarWdgt`, `PlotsToolbarWdgt`,
`WindowsToolbarWdgt` and `SuperToolbarWdgt` (which opens the others).

## 2. Docked means one thing

- **Docked = a band in a window's EDGE SLOT** (`FrameWdgt.dockHost`: my parent, when my layout spec is an
  edge dock; else undefined). A toolbar standing inside a window as its CONTENT is not docked and works for
  the person, exactly like a floating one.
- **Every edge-slot dock ties**, whatever the host holds: no content, or content that is itself a toolbar. A band
  never asks its host's content whom it works for. A window whose content is REPLACED (a widget dropped into an empty
  window, its content picked up or closed) retires every band it wears (`FrameWdgt._retireDockedFramesNoSettle`) and
  docks the new content's toolbar, if it declares one.
- **A band the host's view mode disengages is still docked.** It is hidden, and still listed among the
  host's payloads (`FrameWdgt.dockedPayloads`).
- **The seam.** `ToolbarWdgt.hostWindow` asks the toolbar's frame for its `dockHost` at every asking; nothing
  stores it. `ToolbarWdgt.hostWindowOf(aWidget)` (a static) is the one home every tool asks: it climbs from
  the tool, nearest first, to the first ancestor answering `hostWindow`. The climb tests a capability
  (`hostWindow?`), never a class, so a tool stands in any toolbar. A tool standing in no toolbar works for the person.
- **Reach.** "In reach of host H" means inside H's CONTENT subtree (`H.contents` is the widget or an ancestor
  of it). A band is not its host's content.

## 3. Who a tool works for, per kind

The kind belongs to the TOOL, never to the toolbar.

| Kind | Classes | Docked on host H | Floating (or in no toolbar) | Dimmed |
|---|---|---|---|---|
| **Mode** (paint) | `CodeInjectingSimpleRectangularButtonWdgt` | sets its tool on H, drawings inside or not | sets the person's tool | never |
| **Property** | the `EditorContentPropertyChangerButtonWdgt` family | acts on the editor focus only while it is in H's reach | acts on the editor focus wherever it is | while nothing offers its verb |
| **Creator** | `CreatorWdgt`: `CreatorButtonWdgt`, the lid `GlassBoxTopWdgt` | places into H's content when it takes a placed widget, else makes nothing | places into the topmost window that takes it, else beside the tool on the desktop | never |
| **Subject-less** | `ToolbarCreatorButtonWdgt` subclasses, `TemplatesButtonWdgt` | unaffected | unaffected | never |

**Why modes and properties differ.** A property tool is applied when the TOOL is pressed, so "the last thing
the person touched" is a usable subject. A mode tool is applied when the CONTENT is pressed, so its answer must
be known before the content is touched, and cannot depend on a focus that moves only when it is. Two property
bars cannot disagree either: both mirror one paragraph, while a mode is a standing choice two bars could hold
differently. Hence, for modes only, **the nearer holder wins**: the person's tool drives only the drawings that
stand in no window wearing drawing tools. A floating text bar still acts on a paragraph of a Docs Maker that
wears its own bar.

**Content in view mode refuses restyling**, whatever toolbar asks: it hands a property tool nothing
(`WorldWdgt.editableEditorFocus`, §5.1), and a drawing in view mode carries no tool (§4.2). A creator's click
into a window in view mode places nothing there (its content does not take placed widgets). It takes no drop
either: ONE door, `Widget.wantsDropOfChild`, answers "my drops are on and I sit in no view-mode content", and every
receiver's own answer goes through it (a viewport, a sheet's cell), so the hand's two drop climbs and a viewport's
edge auto-scroll all ask it. No drag takes anything out of it, by the mirror door: `Widget.grabsToParentWhenDragged` asks the holder
a widget would LEAVE the drop door's question (`@parent.sitsInViewModeContent()`), so a drag that would lift a widget
out of view-mode content, at any depth, climbs instead, as from an item the flip locked (the flip locks only the
content's own items), and takes the content as a whole; drags that lift nothing out (a slider's thumb, a handle, a
grip) keep their own answers, and a drag on a button there is cancelled, as on any button in content: it is no
payload, whatever its holder declares (`ButtonWdgt.isDetachablePayloadOfMyParent` asks the view-mode question
first), so no lift grip is drawn on it. (The base context menu's rows, "Pick up" among them, await the owner's
row-by-row ruling: BACKLOG.) A widget that answers edit mode itself (a folder link)
is held by its holder's answer too, while what a folder holds still lifts out. And the editor-focus outline never
frames it (`WorldWdgt._widgetBeingEdited` asks `sitsInViewModeContent` first).

**Which content is in view mode** (`Widget.sitsInViewModeContent`): view mode is inherited DOWNWARD, bounded by
windows.
- A window that offers its own edit toggle (`FrameWdgt.offersEditToggle`, the one definition its strip's pencil
  reads) answers alone for its content, by its mode. So an edit-mode Maker nested in a view-mode document stays
  editable.
- A mode held FIXED is always edit mode (`alwaysInEditMode`, declared by `FolderWindowWdgt`, `BinWdgt`,
  `FolderShortcutWdgt` and `BinOpenerWdgt`: taking widgets and giving them up is their job). Such a widget answers
  false itself, and a window holding one, itself or in its content, answers edit mode for its content as a window
  with its own toggle does; its chrome (a title, a link's caption) follows the content around it. So a folder window
  nested in a view-mode document, its panel, and a folder or bin link standing in one answer edit mode and keep
  taking drops. A folder
  window offers no pencil (`offersEditToggle`), and a declared widget asked to disable its editing stays on
  (`Widget._disableDragsDropsAndEditingNoSettle`, `FrameWdgt`'s).
- Any other mode holder in view mode makes everything in it view-only, whatever a holder nearer the widget says.
  So a bare drawing in a view-mode document refuses paint, although its own canvas, a holder by class, keeps its
  flag on: its surface carries no tool and its canvas stamps no drop.
- A sheet in a view-mode document takes no entry. Every door to a cell asks: an edit start, a commit (an edit
  open across the flip ends without writing), a clear, a drop into a cell, a drag out of one. The arrows still
  move its selection.
- Typing into a field authored to take it still works in view mode (the Degrees Converter's inputs): view mode is
  a USE mode, so no world-level or caret-level door refuses typing.

## 4. Mode tools: the holders and the paint surface

### 4.1 The holders

A paint tool is held by one of two HOLDERS, and both answer the same pair, `armedDrawingTool` (a tool KEY,
`'pencil' | 'brush' | 'toothpaste' | 'eraser'`, or undefined for none) and `armDrawingTool(key)` (the one write,
idempotent: holding what is already held changes nothing and tells no one):

- **The person**, `world.user` (`User`, a plain collaborator, not a widget). Born holding `'pencil'`. A change
  announces (`markNonValueChange`), which every toolbar hears (§7).
- **A window**, `FrameWdgt.armedDrawingTool`: a plain string field, undefined by default, riding the window's
  ordinary save and copy. A window's tool counts only while the window WEARS drawing tools: one of its docked payloads
  holds a tool naming a `drawingToolKey` (`ToolbarWdgt.holdsDrawingTools`, `ToolbarWdgt.wearsDrawingTools(aFrame)`).
  A palette destroyed in its slot (replaced, or retired with its host's content) leaves the field set, and nothing
  reads it until a palette arrives again.
  After a real change, `FrameWdgt.armDrawingTool` tells each payload it wears `noteToolStatesChanged`. A
  window holds only the key; what a key means is the parts' business.

Two palettes docked on one window agree, because the tool lives on the WINDOW, never on a palette.

**The palette tool** (`CodeInjectingSimpleRectangularButtonWdgt`) answers its own press. Its holder is
`ToolbarWdgt.hostWindowOf(@) ? world.user`, read at every asking. A press states
`holder.armDrawingTool (if @drawingToolKey is holder.armedDrawingTool then undefined else @drawingToolKey)`:
a second tap on the tool in hand puts it down, a meaning of the GESTURE, so nothing that merely re-states a tool
(a restored snapshot) can be mistaken for one. `isActiveTool` reads the same holder. A docked paint tool always
sets its host's tool, drawings inside or not: a window wearing a palette has a tool, as a drawing board has a
tray. A mode tool always has something to act on, so it never dims.

### 4.2 The surface takes its tool up at use

Nothing pushes a tool onto a drawing. The paint surface, `CanvasGlassTopWdgt` ("the glass", over the
drawing's canvas), owns the two pointer-move entries as CLASS methods, and both run one body:

- `hoverMoved` / `pressMoved` → `_applyToolInReach` → `_takeUpToolInReach`, then `@applyToolAt? pos, mouseButton`.
- `_takeUpToolInReach` compares the source it should carry now (`_sourceOfToolInReach`) with the one it last
  took up (`_takenUpToolSource`, a plain saved field). Unchanged: a string compare. Changed: it removes every
  member the previous source assigned, then injects the new one's, so two tools never mix on one surface.
- `_sourceOfToolInReach`: none while the drawing sits in view-mode content (`Widget.sitsInViewModeContent`);
  else what its holder's key means now (`PaintToolbarWdgt.sourceForToolKey`); none while the holder holds no key.
- `_toolHolder`: climbing the surface's ancestors, the first window whose CONTENT the climb came through and
  that wears drawing tools; none, and the person. A bare drawing nested in a Docs Maker that wears a palette follows
  that window; a Drawings Maker nested there wears its own palette and follows its own window.

So no change of hand, of window tool, of docking, of nesting or of mode can leave a surface carrying a stale
tool: the question is asked at the event that uses the answer. A finger has no hover, and the press path alone
takes the tool up. A take-up compiles CoffeeScript, a few milliseconds once per change; every profile ships the
compiler.

### 4.3 What a tool key means: the sources and the one table of edits

- **A tool source** is a blurb of `name = value` assignments the surface carries as its own instance members:
  `applyToolAt`, which both entries run, and any helpers it calls (the toothpaste's `paintBrush`, its queue's
  initialiser and the `pressEnded` that drains it). The stock sources are `PaintToolbarWdgt.PENCIL_TOOL_SOURCE` and its three siblings, chosen by
  `PaintToolbarWdgt.stockSourceForToolKey`. "No tool" is the absence of tool members.
- **A source must never assign `hoverMoved` or `pressMoved`** (`CanvasGlassTopWdgt.TOOL_ENTRIES`): an instance
  member of either name would shadow the class entry, and the drawing would never take its tool up again. The
  edit mark's save refuses such a source by its line (`CanvasGlassTopWdgt.refuseToolCodeAssigningMyEntries`); a
  loaded file's table is vetted only as text (§4.4, the load).
- **Edited tool code lives in ONE table, the person's** (`User.drawingToolOverrides`, tool key → source text).
  `PaintToolbarWdgt.sourceForToolKey` answers the person's edit, else the stock source. A palette cell's edit
  mark, docked or floating, opens the whole source its key means now (`editInjectableSource`) and saves through
  `modifyCodeToBeInjected`: the source is compiled as typed, read as assignments
  (`Widget.compilePropertyAssignments`), checked for the two entries, and only then stored
  (`User.overrideDrawingTool`). Every surface using that key takes the edit up at its next use. Holders hold
  only a key, so a key means the same code for every holder.

### 4.4 Docking and undocking a palette

One invariant: **moving a palette changes neither what it shows nor what the drawing it leaves or joins paints
with.** The frame tells its payload of its own arrival and departure, as guarded capability calls, so core stays
paint-agnostic; the logic lives on `ToolbarWdgt`, so a mixed bar transfers too.

- **Arrival** (`FrameWdgt._dockFrameNoSettle` ends with `payload.noteDockedOn? @`): when the toolbar holds
  drawing tools and no other payload the host wears does, the host adopts the person's tool as it stands (an
  empty hand included). A host already wearing drawing tools keeps its own, and the arriving palette shows it.
  A palette dropped into an OCCUPIED slot destroys the occupant first, so the host then adopts the hand (unless
  another of its slots still wears drawing tools).
- **Departure by re-homing** (`FrameWdgt._reactToChildRemoved` tells `noteUndockedFrom` to the payload of a band
  that was docked and is not destroyed): when the host is left wearing no drawing tools, the person takes the host's tool
  and the host gives it up. Every other drawing that follows the hand changes tool with it.
- **Not a departure:** a re-side, a view-mode disengage, a collapse, a destroy. Closing a window never writes
  the hand.
- **Both** end in `noteToolStatesChanged`, for every toolbar: one that docks or leaves changes whom it works for.
- **A new drawing** (`ImageWdgt._buildDockedToolbarNoSettle`, after `super`): a window that wears drawing tools
  and holds none takes `'pencil'`. Its palette's arrival has already adopted the hand's tool, so this is the
  empty hand's fallback, and it is the drawing's own choice: it puts nothing in the person's hand. It runs at
  birth, after a payload reset rebuilds the band, and from the "Toolbar" row of the drawing's menu.
- **A load re-docks nothing** (the deserializer restores structure directly), so no transfer runs and the
  saved tools stand. The person's table comes back from the file's `users` section, each edit vetted as a string
  and not compiled ([`serialization-duplication-reference.md`](serialization-duplication-reference.md), the `world`
  envelope section).

## 5. Property tools: the door and the contract

### 5.1 The door

ONE query decides what every property tool is handed, in core (`WorldWdgt`):

- `editableEditorFocus(hostWindow)`: undefined while the editor focus sits in view-mode content (the focus's own
  `sitsInViewModeContent`), or is on no screen (`surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage`:
  filed to the bin, hidden, in a collapsed window; a widget the hand carries is on screen), whatever the host;
  with no host, the focus wherever it is; with a host, the focus only while `hostWindow.contents` is it or an
  ancestor of it.
- `editorStyleSubject(hostWindow)`: what that focus hands over, its `textStyleSubject` when it has one (a sheet
  hands over its selected cell's `SheetCellStyle`), else the focus itself.

The editor focus itself stands: a click in view mode still sets it, and putting the focus away (a close to the
bin, a hide, a collapse) does not clear it, so once it shows again the tools act on it again. Every reader of the
subject goes through this
door: the family's `_styleSubject` (which passes `ToolbarWdgt.hostWindowOf @`), `AlignButtonWdgt`'s second
subject, and `TextToolbarWdgt.currentFontName`, which the font menu's rows read to decide which is ticked.

### 5.2 The contract (`EditorContentPropertyChangerButtonWdgt`)

- **A verb, named once, as data** (`verb`): the one method or field a subject must offer for the tool to act on
  it (`BoldButtonWdgt`: `"toggleWeight"`; a font size: `"originallySetFontSize"`, the size it steps from).
- **A subject** (`_subjectOfferingMyVerb`): what the door hands over, when it offers the verb (`_offersMyVerb`).
  A tool with a second kind of subject resolves it there too (`AlignButtonWdgt`: a stack element's layout spec).
- **Whether it has something to act on** (`hasSomethingToActOn`): the same answer, asked without pressing.
- **One refusal** (`activated`): act on the subject, or do nothing when there is none. A tap on the cell and a
  toolbar overflow row (`OverflowChevronButtonWdgt.triggerToolFromMenu`) both arrive here. The refusal holds
  wherever the tool stands, in a cell or not: the font tool with nothing selected opens no menu.
- **The act** (`actOn`): by default the verb called on the subject. It is PUBLIC, because it calls the subject's
  self-settling setters, which the `_`-tier may not (`check-layering` [A]); `public-api-allowlist.txt` lists it.
- **Whether it is the active tool** (`isActiveTool`), for a tool that toggles a state of the text (bold, italic,
  the mono font, an alignment): true while its subject has that state, so its cell MIRRORS the edited text.
- `TemplatesButtonWdgt` is the family's subject-less member: it keeps its own `activated` and always has
  something to act on.

### 5.3 Dimming

A tool with nothing to act on shows DIMMED. The CELL derives it: `GlassBoxBottomWdgt.holdsToolWithNothingToActOn`
(its tool answers `hasSomethingToActOn` false; a tool answering nothing never dims) drives both the cell's fill
and the tool's ink (`EditorContentPropertyChangerButtonWdgt._fillForMyState`), so the two cannot disagree. A tool in
no cell (the detached copy an overflow row photographs) wears the plain ink. The look itself (the glyph re-inked
`toolbarGlyphDimmed`, no hover, pressed or active fill) is in [`visual-design-system.md`](visual-design-system.md),
"The tool cell". Only property tools dim: creators, paint tools and subject-less actions never do. An overflow
row of a dimmed tool is DISABLED exactly while its cell dims the tool: its row carries the enablement
`MenuRowReflectionSpec.enabledWhile cell, "holdsToolWithNothingToActOn", false`
(`OverflowChevronButtonWdgt.actOnClick`), so it greys and refuses its tap, leaving the menu open, and it re-reads
whenever the cell announces, as its tick does. The tool's own refusal stays behind it. The font tool's Fonts menu
follows its tool the same way: each row is enabled while the tool has something to act on
(`MenuRowReflectionSpec.enabledWhile tool, "hasSomethingToActOn", true`, announced by the tool's toolbar,
`ToolbarWdgt.noteToolStatesChanged`), so a pinned copy greys while the tool's cell dims; a destroyed tool has nothing
to act on, so a copy left open past its window's end greys and refuses. A text's own menu follows
the same rule as the tools in view mode: a menu built there leaves its editing rows out, and one built in edit mode
and left open (pinned) across a flip to view mode greys them and they refuse, its Fonts menu's rows and "Soft wrap"
included (`StringWdgt._editingRowEnablement`: enabled while the text does not sit in view-mode content, announced
by the world at every flip).

## 6. Creators

`CreatorWdgt.activated` asks `ToolbarWdgt.hostWindowOf @`, then takes one of two paths:

- **Docked: `_placeIntoMyHost(host)`.** Into `host.contents` when it `acceptsSmartPlacedWidgets`, otherwise
  nowhere. Decided BEFORE `createWidgetToBeHandled`: a refused copy tells the person why, so a widget that cannot
  be placed must never be made.
- **Floating: `_placeForThePerson()`.** Into the topmost window whose content `acceptsSmartPlacedWidgets`, else
  beside the tool on the desktop.

A content takes no placed widget while its editing is off (a window in view mode), nor when it stamps what is
dropped on it (`StretchableWidgetContainerWdgt.acceptsSmartPlacedWidgets` asks its canvas
`stampsDroppedWidgets`: a drawing). So a click ends in the same KIND of result a drop there would, and a floating
creator's search passes over such a window to the next one down. A DRAG out of a creator is no click: the drop
names its own target, docked or not. The lid of a drag-out cell (`GlassBoxTopWdgt`) is a creator and inherits all
of this. `ToolbarCreatorButtonWdgt` overrides `activated`: it opens a window beside itself (a toolbar, or the snippets
window) and is untouched by docking.

## 7. The refresh

What a tool SHOWS (active, dimmed) is read when its cell is painted; the refresh only tells cells to repaint.

- **Two edges per toolbar**, made by `ToolbarWdgt._subscribeToWhatMyToolsShow` at build, after deserialization
  and after a copy (each guarded by `world.dataflow.hasEdge`, then one refresh):
  - `world → toolbar`: the editor focus moved (`WorldWdgt._setEditorFocusNoSettle`), its style moved
    (`noteStyleChanged`), an edit mode flipped (`noteEditModeChanged`: EVERY flip, whatever the focus, because a
    text's editing rows in a menu left open read a mode too, §5.3), or where the focus stands moved. That last one has no writer to tell it: a close to the bin, a hide, a collapse, a drag out of a window's
    reach are generic writes that know nothing of the focus. So the world DERIVES it once per cycle, just before
    the dataflow station (`WorldWdgt._keepEditingOnScreenNoSettle`): the focus with every widget above it, and
    whether the door hands it over, compared with its last look. A change is announced like a new focus, so a
    tool's look follows the door whatever moved it. The same station ends an edit whose text is on no screen, so
    no caret is left behind and keys edit nothing the person cannot see;
  - `world.user → toolbar`: the person's hand or tool code moved (`User.armDrawingTool`, `overrideDrawingTool`,
    `replaceDrawingToolOverrides`).

  Both are `firesOnAnyChange` with the action `noteToolStatesChanged`: neither announcement is a value, and
  nothing reads what is delivered. Every toolbar holds both, creator-only ones included. There is no list of
  toolbars anywhere: the dataflow engine's edge index is the set, and a destroyed toolbar leaves it.
- **Told directly:** a window whose own tool changes (`FrameWdgt.armDrawingTool`), and a toolbar that docks or
  leaves (`noteDockedOn` / `noteUndockedFrom`).
- **`ToolbarWdgt.noteToolStatesChanged`** tells every cell `noteItemStateChanged` (hidden ones too, so a cell the
  strip shows later is already right), then announces the toolbar itself (`markNonValueChange @`), which the text
  bar's font menu rows re-read: their ticks, and their enablement on the font tool's `hasSomethingToActOn`.
- **`GlassBoxBottomWdgt.noteItemStateChanged`** repaints the cell, its tool's glyph with it, and announces the cell,
  so a pinned overflow row for that tool re-reads its tick (`holdsActiveTool`).
- **Pointer state** is separate: the hand tells a tool `notePointerStateChanged`, and every tool family passes it to
  its cell (`@parent?.noteItemStateChanged?()`). Tools `lightsAToolCell`, so the cell shows their hover and press.

The drain runs in the cycle's dataflow station, before layout and paint, so what a cell shows is a function of the
event stream, with no timer.

## 8. Writing a tool

- **A property tool.** Subclass `EditorContentPropertyChangerButtonWdgt`. Name the `verb`; give
  `createAppearance` no colour of its own (the ink comes from `_fillForMyState`); set `toolTipMessage`. Override
  `actOn` only when the act is more than calling the verb, and answer `isActiveTool` only when the tool toggles a
  state. Never read `world.editorFocusWdgt` directly: a reader that bypasses the door acts across windows and in
  view mode. The subject's setters must announce while it is the focus (`noteStyleChanged`), or no toolbar refreshes.
- **A paint tool.** Add a stock source to `PaintToolbarWdgt` (`applyToolAt` and its helpers, never either entry),
  map its key in `stockSourceForToolKey`, and build a `CodeInjectingSimpleRectangularButtonWdgt` with that key and an
  icon face built in `toolbarGlyph` in `_toolbarItems`, into a field of its own that `_tools` lists (the strip and the
  edit marks both come from `_tools`). Nothing else: holders, take-up, transfers and the refresh are keyed generically.
- **A creator.** Subclass `CreatorButtonWdgt` (or `CreatorWdgt`) and answer `createWidgetToBeHandled`. Placement
  is the base's; never search for a target yourself.
- **A subject-less action.** Its own `activated`; answer no `hasSomethingToActOn` (or `true`, as Templates does).
- **A toolbar.** Subclass `ToolbarWdgt`: `_toolbarItems` (literal `new X` forms) and `dockSide` when not `'left'`.
  A Maker docks it by answering `buildToolbar`. A toolbar may mix kinds freely.

## 9. What guards it

SystemTests:

- view-mode refusal and click placement: `SystemTest_macroViewModeTextRefusesFloatingBold`,
  `SystemTest_macroDrawingTakesNoClickPlacedWidget`;
- holders, take-up, transfers, the one table: `SystemTest_macroTwoDrawingsKeepTheirOwnTools`,
  `SystemTest_macroPaletteDockUndockKeepsTheTool`, `SystemTest_macroDrawingToolReachesEveryDrawingOfItsHolder`;
- the tool-code save and its refusal of the two entries: `SystemTest_macroToolCodeSaveRefusesCodeThatDoesNotCompile`;
- reach of docked tools and the mixed bar's refresh: `SystemTest_macroDockedTextBarActsOnlyInItsWindow`,
  `SystemTest_macroDockedCreatorPlacesOnlyIntoItsHost`, `SystemTest_macroMixedToolbarKeepsEveryLookCurrent`;
- dimming: `SystemTest_macroDimmedToolsWakeWithTheirSubject`, `SystemTest_macroDimmedToolCellStaysDarkUnderThePointer`,
  `SystemTest_macroPinnedToolbarFontsMenuGreysWithItsTool`.

Macro authors: `src/macros/MACRO-PATTERNS.md` teaches that a tool acts on the focus only within the window its
toolbar works for, and how to assert a dimmed tool.

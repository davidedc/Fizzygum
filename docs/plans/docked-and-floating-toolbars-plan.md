# Docked and floating toolbars — who a tool works for

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
AUTHORED 2026-11-16 against Fizzygum master `14905c4c` and Fizzygum-tests master `f470874b0` (389
SystemTests). Nothing in this plan is implemented. Owner rulings R1–R10 (§4.1) and decisions D1–D8 (§4.2)
are LOCKED: the owner ratified D1–D8 on 2026-11-16, every recommendation. **No backward compatibility is
owed** (owner, 2026-11-16): ignore legacy code and every previously saved world, drawing and piece of tool
code — no migration, no compatibility branch, no code that exists only to read an older shape.

**Mandate: eliminate the cause, not the symptom.** The reported bug (a drawing paints with the previous
tool while every palette shows the new one) is one face of a missing rule: nothing states which content a
toolbar's tool acts on, so three tool families each answer it their own way and the answers disagree. This
arc states that rule ONCE, per tool, and removes every mechanism the rule makes redundant. It does not
patch the paint palette's target resolution.

Phase status (update this table as phases close):

| Phase | What | Status |
|---|---|---|
| P0 | Spike S1 (the paint mechanism, planted); measure M1 (test fallout). D1–D8 are already ratified | DONE 2026-11-16: S1 passes every row; M1a, M1b empty; M1c 26 shots in 12 tests (§8 "P0 results") |
| P1 | Content-side bugs: view-mode content refuses restyling; a drawing takes no click-placed widget | DONE 2026-11-16: `WorldWdgt.editableEditorFocus`, `StretchableCanvasWdgt.stampsDroppedWidgets`, two new tests; gauntlet green (§8 "P1 results") |
| P2 | The seam + paint: the surface takes up its tool at use; windows hold their own tool | DONE 2026-11-17: the glass's class entries + take-up, `FrameWdgt`'s holder pair, the D3 transfers, D2's table and its save, three new tests; gauntlet green (§8 "P2 results") |
| — | OWNER CHECKPOINT: dock / undock by hand, judge the feel (D3) | APPROVED 2026-11-17: D3 stands as built, with the three behaviours §8 "P2 results" lists |
| P3 | Text tools and creators onto the seam; the refresh moves to `ToolbarWdgt`; mixed bars | DONE 2026-11-17: the host-scoped door, the creators' host placement, the two edges and one refresh on `ToolbarWdgt`, three new tests; no existing test changed; gauntlet green (§8 "P3 results") |
| P4 | Tools with nothing to act on show dimmed (D5) | DONE 2026-11-17: one contract for the property tools (verb, subject, one refusal), the cell-derived dimmed look, two new tests, 17 tests recaptured; gauntlet green (§8 "P4 rulings", "P4 results") |
| — | OWNER CHECKPOINT: the owner picks the dimmed look, then sees the diff page before P4's recapture | APPROVED 2026-11-17: the look picked (§8 "P4 rulings"), the diff page (31 shots) reviewed before the recapture |
| P5 | Docs, archive, close | not started |

---

## 0. Orientation

**Fizzygum** is a CoffeeScript GUI framework rendered on one `<canvas>`: windows, a desktop, drag and
drop, live editing tools. Three sibling repos under a directory literally named `Fizzygum-all`:
`Fizzygum/` (source + build; the only place behaviour is edited), `Fizzygum-tests/` (the SystemTest suite
and its Node rigs), `Fizzygum-builds/` (generated; never edited). Read `Fizzygum/CLAUDE.md` and
`Fizzygum-tests/CLAUDE.md` before anything else; both are routers to the deeper docs.

**The apps involved.** Each "Maker" is a window (`MakerDocumentWdgt extends FrameWdgt`): Docs
(`DocumentWdgt`), Sheets (`SpreadsheetWdgt`), Drawings (`ImageWdgt`), Slides (`SlideWdgt`), Dashboards
(`DashboardWdgt`), Patch programming (`PatchProgrammingWdgt`), Generic panel (`GenericPanelWdgt`, no
toolbar). A Maker declares its toolbar with `buildToolbar`, and the frame docks it, framed, in one of its
four edge slots (`FrameWdgt._buildDockedToolbarNoSettle`). The same toolbar classes also float as desktop
windows, summoned from the Super toolbar.

**The immediately prior arcs** (both closed; read their rulings before touching this area):
- `docs/archive/onion-widget-composition-plan.md` §5.D (2026-07-20). D11: "docked acts on its own frame,
  floating follows focus". D12: injection stays the arming mechanism. At that time each drawing had its
  own tool and each palette showed its own selection.
- `docs/archive/command-panel-unification-plan.md`, P4 (2026-08-26). The armed tool became the PERSON's
  fact (`User.armedDrawingTool`): "arming anywhere arms everywhere". The palette highlight became a
  derived view of the hand. `resolveInjectionTarget` was kept "byte-identical".

**Why this plan exists now.** On 2026-11-16 the owner reported, and this session reproduced with real
mouse input, that with two Drawings Makers and one palette undocked, a tool tapped on one palette shows
on both palettes while the second drawing keeps painting with the old tool (§3).

> **THE CRITICAL REFRAME.** The August arc made WHAT THE PALETTES SHOW a derived value of one fact, and
> left WHAT A SURFACE DOES a stored copy that palettes push. D11 was a rule for a PRESS ("which drawing
> does this press act on"); after August it silently became "which drawing does this palette keep in
> sync", a question nobody decided. A floating palette answers it "the drawing clicked last, at the
> instant the hand changes", and the click is recorded at the RELEASE, after the stroke. So the letter of
> both rulings holds and the intent of the second does not. The fix is not a better push: it is to stop
> storing the answer. A surface takes up its tool WHEN IT IS USED, from the nearest thing that holds one.

**What the arc grew into.** The owner then chose a different model from August's (§4.1): two drawings may
hold different tools. A toolbar DOCKED on a window is tied to that window; a FLOATING one works for the
person. Checking the other toolbars against that rule (§3.2) showed it generalises, per tool, and that the
other two tool families have cross-window oddities of their own today. This plan covers all of it.

## 0.5 Cold-execution protocol

1. Run `fg status` (the `fg` wrapper is `Fizzygum/fg`; invoke it by absolute path, never `./fg`). Confirm
   both repos are clean and the build is FRESH. Compare the heads with the ones in this plan's header:
   if `src/authoring/PaintToolbarWdgt.coffee`, `src/app-kit/ToolbarWdgt.coffee`, `src/FrameWdgt.coffee`
   or `src/User.coffee` changed since, re-verify §1 before trusting it.
2. Read, in this order: this plan whole; `docs/architecture/widget-authoring-guidelines.md` (§16 for the
   home of a shared behaviour); `docs/architecture/lint-and-static-checks.md` (which gate sees what);
   `src/macros/CLAUDE.md` (macro tests); `src/serialization/CLAUDE.md` before P2's save work;
   `Fizzygum-tests/DETERMINISM.md` before touching anything a pointer event reaches.
3. **Line numbers in §1 drift. The method name and the quoted code are authoritative: grep them fresh.**
4. Execute phases in order. P1 is independent and may go first or be interleaved; P2 precedes P3; P4
   needs P3.
5. One phase = one commit point. At each: `fg gauntlet` green, then present a summary and a commit
   message and WAIT. The owner approves every commit and every push; no standing grant exists.
6. STOP and report, without improvising, when: a spike's acceptance fails; a measured set differs from
   the predicted one; two fix shapes in a row are falsified (the model is wrong: re-frame); an owner
   checkpoint is reached.
7. Never recapture a reference to make a failure go away. A pixel difference is explained first
   (`fg diffpage <test>`), shown to the owner where the look changed, and only then recaptured
   (`fg recapture --auto`, after a build).
8. A long `fg` op runs ONCE in the background with its output redirected to a log; wait for the
   notification. Never pipe a gating `fg` call through a filter.

---

## 1. The mechanism today (verified 2026-11-16)

### 1.1 Three tool families, three target rules

A toolbar is `ToolbarWdgt` (`src/app-kit/ToolbarWdgt.coffee`): a `ViewportWdgt` over a `ToolPanelWdgt`
grid. Each item sits in a cell (`GlassBoxBottomWdgt`, core) which paints the tool's hover, press and
ACTIVE look by asking the tool `isActiveTool?()`, and repaints when told `noteItemStateChanged()`. A
subclass supplies `_toolbarItems`. The KIND of a tool is a property of the tool's class, never of the
toolbar:

| Kind | Tool classes | Where the state lives | What it acts on today |
|---|---|---|---|
| **Mode** | `CodeInjectingSimpleRectangularButtonWdgt` (the four paint tools) | a standing choice: `world.user.armedDrawingTool` | pushed by the palette into ONE surface: docked → its host; floating → `world.editorFocusWdgt` |
| **Property** | `EditorContentPropertyChangerButtonWdgt` and its subclasses (bold, italic, align, font, size, code, fill, decimals, slider-in-cell) | in the content (a paragraph IS bold) | `world.editorStyleSubject()`: whatever was clicked last, anywhere |
| **Creator** | `CreatorWdgt` → `CreatorButtonWdgt` and its subclasses; `GlassBoxTopWdgt` (the lid over a plain widget in a cell) | none | drag: where it is dropped. Click: the front-most DIRECT child of the world that is a frame whose content `acceptsSmartPlacedWidgets`, else the desktop beside the tool |
| *(subject-less action)* | `ToolbarCreatorButtonWdgt` subclasses, `TemplatesButtonWdgt` | none | nothing: they open a window on the desktop |

Mixed toolbars exist: the text bar carries `TemplatesButtonWdgt`; and `ToolPanelWdgt._addNoSettle` wraps
any widget dropped into a toolbar as a drag-out cell (by reading, not run).

Toolbars and their items:
- `TextToolbarWdgt` (docked `top` in a Docs Maker): ten property tools incl. `TemplatesButtonWdgt`.
- `SheetToolbarWdgt extends TextToolbarWdgt` (docked in a Sheets Maker): twelve property tools.
- `PaintToolbarWdgt` (docked `left` in a Drawings Maker): four mode tools, each with an `EditableMarkWdgt`.
- `SlidesToolbarWdgt`, `DashboardsToolbarWdgt`, `PatchProgrammingToolbarWdgt`, `WindowsToolbarWdgt`,
  `PlotsToolbarWdgt` (`src/graphs-plots-charts/`): creators and plain widgets.
- `SuperToolbarWdgt`: nine toolbar creators.

Parts (`buildSystem/parts.json`): `FrameWdgt`, `User`, `WorldWdgt`, `ActivePointerWdgt`,
`GlassBoxBottomWdgt`, `CanvasWdgt`, `Widget` are **core**; `ToolbarWdgt`, `ToolPanelWdgt`, `CreatorWdgt`,
`CreatorButtonWdgt` are **app-kit** (lazy); everything under `src/authoring/` is **authoring** (lazy,
requires app-kit); `spreadsheet`, `plots`, `maps` require app-kit. Core may not name a part's class
unguarded (`buildSystem/check-part-edges.js`).

### 1.2 Paint: the code path of the bug

`src/authoring/PaintToolbarWdgt.coffee`:
- `_armed: true` (:35) — "my frame is in edit mode".
- `@TOOL_OFF_SOURCE` (:45), the four `@…_TOOL_SOURCE` statics, `@sourceForToolKey` (:391).
- `_subscribeToTheArmedDrawingTool` (:410): one dataflow edge `world.user → me`,
  `action: "applyArmedDrawingTool", firesOnAnyChange: true`; re-made in `_afterDeserialization` and
  `_reactToBeingCopied`.
- `resolveInjectionTarget` (:433):
  `@parent?.paintingOverlay?() ? world.editorFocusWdgt?.paintingOverlay?()`.
- `reactToEditModeInFrame` (:449) / `reactToViewModeInFrame` (:455): flip `_armed`, re-arm.
- `selectTool` (:471): `world.user.armDrawingTool (if tappedKey is world.user.armedDrawingTool then undefined else tappedKey)`.
- `applyArmedDrawingTool` (:478) → `_armSelectedTool` (:485):
  `@resolveInjectionTarget()?.injectProperties @_sourceOfSelectedTool()` then `@_invalidateLayout()`.
- `_deriveToolHighlights` (:519), run from `_reLayoutChildren` (:525).
- `newCodeToInjectFromButton` (:532).

`src/authoring/CodeInjectingSimpleRectangularButtonWdgt.coffee`: constructor `(palette, face, @drawingToolKey)`
(:41) with `target: palette, action: "selectTool"`; `sourceCodeToBeInjected` (the cell's editable copy of
its tool's code); `isActiveTool` (:71) asks the palette `holdsInHand`; `editInjectableSource` (:82);
`injectCodeIntoTarget` (:89); `modifyCodeToBeInjected` (:101).

`src/User.coffee`: `armedDrawingTool: 'pencil'`; `armDrawingTool` is idempotent and announces with
`world.dataflow?.markNonValueChange @`.

`src/authoring/ImageWdgt.coffee` `_makeStartingPayload`: builds a `StretchableWidgetContainerWdgt` over a
`StretchableCanvasWdgt`, adds a `CanvasGlassTopWdgt` (the paint surface, "the glass") on the canvas,
injects a `hoverExited` that clears the feedback, and injects
`PaintToolbarWdgt.sourceForToolKey (world.user?.armedDrawingTool ? 'pencil')`.

A tool source is a blurb of `name = value` assignments injected as INSTANCE members of the glass
(`Widget.injectProperties`). All four tools assign `hoverMoved`, `pressMoved` (both one line, routing to
`@applyToolAt`) and `applyToolAt`; the toothpaste also assigns `pressEnded`, `paintBrush`,
`initialiseQueueIfNeeded`. Inside them `@` is the glass (`@backBuffer`, `@underlyingCanvasWdgt`,
`@width()`, `@_changed()`, `@queue`).

The `paintingOverlay()` chain, whose ONLY consumer is `resolveInjectionTarget`: `CanvasGlassTopWdgt`
(`isPaintingOverlay`, `paintingOverlay`), `CanvasWdgt.paintingOverlay` (:60),
`StretchableWidgetContainerWdgt.paintingOverlay` (:110), `FrameWdgt.paintingOverlay` (:889, with a
docked-band branch).

`src/FrameWdgt.coffee`: `showEditModeInBar` (:2406) and `showViewModeInBar` (:2419) end in
`@_dockedToolbar()?.reactToEditModeInFrame?()` / `…reactToViewModeInFrame?()` — view mode stops a drawing
painting ONLY by having its docked palette inject the no-op.

How the pointer dispatches (`src/ActivePointerWdgt.coffee`, `_dispatchEventsFollowingMouseMove`):
`hoverMoved`, `pressMoved`, `hoverEntered`, `hoverExited` go, through `?.`, to EVERY widget under the
pointer — no climb to an implementor. `pressBegan` climbs while each receiver answers true;
`pressEnded` goes to every member of that audience through `?.`. A pressed pointer arriving from outside
reaches a widget's `pressMoved` without a `pressBegan` there. The editor focus is written at the CLICK,
inside `processPointerUp` (`world._setEditorFocusNoSettle w`).

### 1.3 Docking

- `FrameWdgt._myEdgeDockSpec` (:290): the edge spec a host handed me, or undefined. THE one "am I a
  band?" question. Private.
- `FrameWdgt.dockSideAt` (:1312) offers a band to ANY dragged frame (program ruling C12: "no type test on
  WHAT docks"). So any window docks on any window: a text bar on a Drawings Maker, two palettes on one
  drawing, a whole Maker as a band.
- Arrival: `FrameWdgt._dockFrameNoSettle(aFrame, side)` (:1376) — the drop's `dockSide` option, the
  "Toolbar" menu row and a Maker's own birth all land here.
- Departure by re-homing (a grab of the grip, `floatOutOfDock` :1532): `FrameWdgt._reactToChildRemoved`
  (:1155) → `_freeDockSlotOf`. A re-side (`_reSideMyDockNoSettle`) calls `_freeDockSlotOf` directly and
  re-assigns; a content change destroys the bands (`_retireDockedFramesNoSettle`).
- View mode DISENGAGES every dock (`_engageDocksNoSettle false`): the band is hidden, still docked.
- A toolbar window dropped INTO a window's content is nested, not docked: it has no edge spec.

### 1.4 Text tools, creators, the save

- `EditorContentPropertyChangerButtonWdgt._styleSubject` (:53) → `WorldWdgt.editorStyleSubject` (:1852):
  `focus?.textStyleSubject?() ? focus`. `AlignButtonWdgt.activated` also reads `world.editorFocusWdgt`
  directly for its stack-alignment fallback. `TextToolbarWdgt.currentFontName` reads the same subject.
- `TextToolbarWdgt._followTheEditedText`: one edge `world → me`, `action: "mirrorTheEditedText"`; the
  mirror tells every cell `noteItemStateChanged?()` and ends in `world.dataflow?.markNonValueChange @`
  (the font menu's ticks reflect the toolbar).
- `CreatorWdgt.activated` (`src/app-kit/CreatorWdgt.coffee:19`): `world.topmostChildSuchThat (w) ->
  w.isFrame?() and w.contents?.acceptsSmartPlacedWidgets?()`, then `where.contents.smartPlace`.
  `acceptsSmartPlacedWidgets` is `-> @dragsDropsAndEditingEnabled` on `DocumentViewportWdgt` (:37) and
  `StretchableWidgetContainerWdgt` (:150); the latter's `smartPlace` centres the widget and `@add`s it.
  `ToolbarCreatorButtonWdgt.activated` overrides all of that: always the desktop.
- A drop on a drawing's canvas STAMPS: `StretchableCanvasWdgt._reactToChildDropped` paints the widget's
  image and re-homes the widget to the world.
- The save: `Serializer` writes `section.users = ({armedDrawingTool: …} for …)`;
  `Deserializer._sectionUsersProblem` validates it; `WorldWdgt`'s restore calls
  `@users?[i]?.armDrawingTool eachRecord.armedDrawingTool`. A palette cell's `sourceCodeToBeInjected`
  and a glass's injected members (as `{"$src"}`) ride ordinary widget serialization.

---

## 2. Why it is shaped this way

- **D11** answered a real problem of July: a docked palette had to work before the drawing's first
  click, and a floating one needed some target. The focus pointer was the only "which content" fact.
- **D12** kept injection because it was proven, carried by a save, and live-editable.
- **The August ruling** moved the selection off the palette because a stored selection made a
  destination-generic instrument owner-specific by accident. It converted the highlight to a derived
  view and, to stay byte-identical, left the push in place. The push now runs on every hand change and
  targets a pointer that was designed to be read at a press.
- **View mode** was implemented as "the docked palette injects the no-op", which is only true while a
  palette is docked.
- **Text tools** were always "act on the focus", by design of the July arc (§5.C: "the buttons inside
  don't bind to an editor instance"). That is one coherent rule; its cost is that a bar docked on one
  window edits another.
- **Creators** predate docking: "the topmost window that takes widgets" was the only notion of a target.

---

## 3. Evidence (reproduced 2026-11-16, real CDP mouse input on `index-sw.html`)

The probes live in `Fizzygum-tests/.scratch/paint-two-makers/` (`probe.js`, `toolbar-matrix-probe.js`).
That folder is gitignored and may be gone: every scenario is restated here so it can be rebuilt. Each
builds its fixtures with the launcher apps' own calls (`world.openFrameWith (new ImageWdgt), (new Point
460, 400), …`), drives `page.mouse`, and reads state in the page. A stroke is classified by the bounding
box of the pixels it changed in `StretchableCanvasWdgt.behindTheScenesBackBuffer`: pencil 4 px tall,
brush 16 px. Which tool a glass carries is read with `Widget.keptSourceOf(glass.applyToolAt)`.

### 3.1 Paint

| Step | Hand | Palettes show | Drawing A (palette docked) | Drawing B (palette undocked) |
|---|---|---|---|---|
| Open A and B; drag B's band out by its grip | pencil | pencil / pencil | carries pencil | carries pencil |
| Tap BRUSH on A's palette (nothing clicked yet: focus none) | brush | brush / brush | carries brush | **carries pencil** |
| Stroke on A, then on B | brush | brush / brush | brush stroke | **pencil line** |
| Tap PENCIL on the floating palette (B clicked last) | pencil | pencil / pencil | pencil | pencil |
| Stroke on A, tap BRUSH on the floating palette (A clicked last) | brush | brush / brush | brush | **pencil** |
| B to view mode, stroke on B | brush | — | — | **still paints** |
| A to view mode, stroke on A, tap PENCIL on the floating palette, stroke on A | pencil | — | **paints in view mode** | — |

A plant of ONE candidate mechanism (the surface subscribes to the hand and re-derives; the palette
injects nothing) made all nine strokes right under the AUGUST model. It is evidence that "the surface
derives" closes the family. It is NOT evidence for §6's pull-at-use shape nor for the holder model: those
are proven by spike S1 (P0).

### 3.2 The other toolbars

| Case | Result today |
|---|---|
| T1. Docs A and Docs B; caret in B; Bold on the bar docked in A | B's paragraph goes bold; A comes to the front; both bars show Bold active |
| T2. Sheets S and Docs D; caret in D; Bold on S's bar | D's paragraph goes bold. And the reverse: a cell of S clicked, Bold on D's bar → the cell goes bold |
| C1. Slides L and Dashboards H; H clicked last; text-box creator on L's docked bar | lands in L — only because the press raises L first |
| C2. Drawings Maker G clicked last; text-box creator on a FLOATING Slides bar | a live `TextWdgt` becomes a child of G's `StretchableCanvasWdgt` (a drag of the same item stamps instead) |
| C3. Slides L carried into Docs D (dwell-embedded); creator on L's own docked bar | the text box lands in D's stack, not in L |
| X1. `G.dockFrame(textBarWindow, 'top')`; `D.dockFrame(paintBarWindow, 'right')`; caret in D; Bold on the bar worn by G | both dock; D's paragraph goes bold; the palette worn by D would inject into nothing |
| V1. Docs D; caret in its paragraph; D to view mode; click the paragraph; Bold on a floating text bar | the focus is the paragraph and it goes bold, in view mode |

Not checked: finger input; the Patch, Plots and Windows bars individually (same `CreatorWdgt` path).

---

## 4. The rule

### 4.1 Locked owner rulings (2026-11-16)

- **R1.** Two drawings may hold different tools at once. The tool is no longer only the person's.
- **R2.** A toolbar DOCKED on a window is tied to that window. Its reach is the window's content and
  everything inside it. Where nothing in reach is something a tool applies to, the tool does nothing.
  There is no fallback to floating behaviour: a text bar docked on a Drawings Maker is dead, and a Draw
  palette docked on a Docs Maker reaches only the drawings inside that document, never the hand.
- **R3.** "Docked" has only the strong sense: a band in a window's EDGE SLOT. A toolbar collected INSIDE
  a window as content is not docked and behaves as a floating one.
- **R4.** A FLOATING toolbar works for the person: a paint tool sets the hand; a property tool acts on
  the selection wherever it is; a creator's click goes to the front-most window that takes placed
  widgets, else the desktop.
- **R5.** For MODE tools the nearer holder wins: the hand drives only drawings that stand inside no
  window wearing drawing tools. This exclusion is specific to modes. A floating text bar still acts on a
  paragraph in a Docs Maker that wears its own bar.
- **R6.** The rule is stated PER TOOL. A toolbar answers one question — who do I work for — and each
  tool resolves its own subject from the answer. A toolbar mixing kinds must work.
- **R7.** Two palettes docked on one window agree: the tool lives on the WINDOW, never on a palette.
- **R8.** Content in view mode refuses restyling, whatever toolbar asks. (Bug; §3.2 V1.)
- **R9.** A click on a creator ends in the same KIND of result as dropping the created item on that
  target. A drawing stamps what is dropped on it, so it takes no click-placed widget: the item goes to the
  desktop beside the tool. (Bug; §3.2 C2.)
- **R10.** R2 holds for a Maker's own bar: with the caret in Docs B, Bold on Docs A's bar does nothing.

Why R5 is not arbitrary (the argument that keeps the families apart): a property tool is applied when
the TOOL is pressed, so "the last thing touched" is a usable subject. A mode tool is applied when the
CONTENT is pressed, so the answer must be known before the content is touched — it cannot depend on a
focus that moves only when the content is touched. And two property bars cannot disagree, because both
mirror one paragraph; only a mode is a standing choice two bars could hold differently.

### 4.2 Decisions D1–D8 — RATIFIED by the owner 2026-11-16, every recommendation

Locked: do not re-open them. Each keeps its alternative, as the road not taken. D3 alone has a later
check: it was argued from code, so the owner tries it by hand after P2 and may then revise it.

- **D1 — a new drawing's tool.** RULED: keep the 2026-08-26 ruling — born with what the hand holds,
  pencil when the hand is empty. It needs no special case: a birth docks a palette, and D3's dock rule
  adopts the hand's tool; the pencil fallback stays the drawing's own birth choice. Alternative: always
  pencil.
- **D2 — where edited tool code lives.** Today each palette cell keeps its own copy, so "pencil" can mean
  different things on different palettes. RULED: one table, the person's. `User` holds the
  OVERRIDES (key → source text); an unedited tool reads the stock table
  (`PaintToolbarWdgt.sourceForToolKey`). An edit mark on any cell, docked or floating, edits that one
  table. Windows hold only a KEY. Alternatives: per holder (a window's own pencil; needs the code to
  travel at dock/undock); per cell (today; two palettes on one window conflict).
- **D3 — dock and undock.** RULED, one invariant: *moving a palette changes neither what it shows
  nor what the drawing it leaves or joins paints with.* So on DOCK the window adopts the hand's tool, and
  on UNDOCK the hand takes the window's tool. Side effect to accept: undocking changes the tool of every
  other drawing that follows the hand. Alternative: no transfer (the drawing jumps at both moments).
  This was argued from code; the owner judges it by hand after P2.
- **D4 — a band on a window with nothing to act on** (no content; or content that is itself a toolbar).
  RULED: every edge-slot dock ties, whatever the host holds. Then holder-ness never changes when
  content arrives or leaves, and no hook is needed there. Alternative: the literal "a window with
  content", which makes a palette flip from floating to tied when content is dropped in.
- **D5 — a cue for a tool with nothing to act on.** R2 creates clicks that do nothing. RULED: such
  a tool shows dimmed and ignores its press; the look is chosen by the owner from a preview (P4).
  Alternative: no cue.
- **D6 — subject-less actions** (`ToolbarCreatorButtonWdgt` subclasses, `TemplatesButtonWdgt`).
  RULED: unaffected by docking and never dimmed — they act on nothing.
- **D7 — the tool source contract.** §6.2 moves the two event entries out of the tool sources: a source
  assigns `applyToolAt` (and any helpers), never `hoverMoved` / `pressMoved`. RULED: accept, and ignore
  everything saved in the old shape — drawings, worlds, tool code (see the header: no backward
  compatibility is owed). A save of a tool source assigning a reserved name is refused with a located
  message.
- **D8 — a docked sheet bar's subject.** RULED: uniform with R2 — the selection, when it is inside
  the host. Alternative: the host sheet's selected cell always (a sheet always has one), which no other
  content can match.

---

## 5. The distilled argument

1. **Stored answers go stale; derived ones cannot.** The bug is a cache (a surface's handlers) with
   incomplete invalidation. Under R1–R5 the events that change a surface's tool multiply: the hand
   changes; a window's tool changes; a palette docks or leaves; the drawing is carried into or out of a
   window wearing a palette; its mode flips; it is loaded or copied. Enumerating invalidation events is
   the bug class itself. So the surface resolves its tool AT THE EVENT THAT USES IT.
2. **Use has exactly two entries.** Every paint tool is entered through `hoverMoved` and `pressMoved`,
   and all four stock sources route both to `applyToolAt`. Making those two the surface's own class
   methods gives one place where "which tool, and may I be painted on" is asked, on every use, with
   nothing to subscribe, hook or restore.
3. **One protocol, two holders.** A tool is held by the person or by a window. Both answer
   `armedDrawingTool` and `armDrawingTool`. A palette tool and a surface each find their NEAREST holder;
   neither knows which kind it found.
4. **The kind belongs to the tool.** Targeting is already decided per tool. Only the refresh of the
   cells' looks is toolbar-class-bound (the text bar hears the selection, the palette hears the hand).
   Moving the refresh to `ToolbarWdgt` makes a mixed bar correct by construction and reduces the two
   subclasses to item lists — which is what `ToolbarWdgt`'s header already says a subclass is.
5. **Why earlier shapes failed, and what differs.** D11 resolved a target at a press and was right while
   the tool was per image. August moved the fact and kept the push. This plan removes the push.

---

## 6. Fix shape

Names below are proposals; the behaviour is the contract. Where a name is a new PUBLIC member on a core
class, check `lint-and-static-checks.md` for the gates that read it (dead methods, unresolved sends,
call separation, part edges).

### 6.1 The seam: who a toolbar works for

- `FrameWdgt` (core) gains a public, generic query: the window whose edge slot I occupy, or undefined
  (`@parent if @_myEdgeDockSpec()?`). `_myEdgeDockSpec` is private, so the seam needs this public door.
- `ToolbarWdgt.hostWindow()` = that query asked of my frame (`@parent`). Undefined means: I work for the
  person. Under D4 nothing else is tested.
- A tool finds the toolbar it stands in by a capability climb
  (`allParentsBottomToTopSuchThat (p) -> p.hostWindow?`, `src/basic-data-structures/TreeNode.coffee`),
  never by a class test. ⚠ Measured in P0: that helper's array is ROOT-first (self last), so the nearest
  match is its LAST element. A tool standing in no toolbar works for the person. Give this ONE home that all
  three tool families can ask (a static on `ToolbarWdgt` reaches them all: authoring requires app-kit;
  choose by `widget-authoring-guidelines.md` §16).
- "In reach of host H" = inside H's CONTENT subtree (`H.contents` is the widget or its ancestor). A band
  is not its host's content.

### 6.2 Paint

**The surface (`CanvasGlassTopWdgt`) owns the two entries, as class methods:**

```coffee
hoverMoved: (pos) -> @_applyToolInReach pos
pressMoved: (pos, mouseButton) -> @_applyToolInReach pos, mouseButton

_applyToolInReach: (pos, mouseButton) ->
  @_takeUpToolInReach()
  @applyToolAt? pos, mouseButton

# Bring my injected tool members in line with the tool I should carry NOW.
_takeUpToolInReach: ->
  wanted = @_sourceOfToolInReach()          # undefined: view mode, or a holder holding nothing
  return if wanted is @_takenUpToolSource
  # drop every member the previous source assigned, then inject the new one's
  if @_takenUpToolSource?
    @removeOwnProperty each.name for each in Widget.compilePropertyAssignments @_takenUpToolSource
  @injectProperties wanted if wanted?
  @_takenUpToolSource = wanted
```

- `_sourceOfToolInReach`: undefined unless my drawing may be painted on; else the key my nearest holder
  holds; else that key's source (D2: the person's override, else the stock table).
- "May be painted on": the edit mode of the widget that coordinates editing for my canvas (the nearest
  ancestor answering `coordinatesDragsDropsAndEditingForChildren?()`, asked `isInEditMode()`); a surface
  with no such ancestor is paintable. View mode is then a plain `if` at use.
- `_toolHolder`: climbing my ancestors, the first WINDOW that wears drawing tools and whose content holds
  me; none → `world.user`. "Wears drawing tools": one of its docked frames' payloads is a toolbar holding
  at least one tool with a `drawingToolKey`. `FrameWdgt` offers the docked payloads through a public,
  paint-agnostic query; the toolbar answers whether it holds drawing tools.
- `_takenUpToolSource` is an ordinary (saved) field: after a load it still names what the saved members
  came from, so the first use compares, removes and re-injects correctly.
- `hoverExited` (clear the feedback) becomes a class method; `ImageWdgt._makeStartingPayload` injects
  NOTHING.
- The four stock sources lose their `hoverMoved` / `pressMoved` lines. `TOOL_OFF_SOURCE` is deleted: "no
  tool" is the absence of tool members. The toothpaste's `pressEnded` stays an injected member (the
  pointer reaches it through `?.`) and leaves with the tool at the next take-up.
- Injection compiles CoffeeScript. It now happens at the first use after a change (a few milliseconds,
  once), inside a pointer dispatch. Every profile ships the compiler.

**The holders.** `User` keeps `armedDrawingTool` / `armDrawingTool`. `FrameWdgt` (core) gains the same
pair: a plain string field, default undefined, and an idempotent setter that, after a real change, tells
its docked payloads to refresh their tools (§6.5). Core names no part class: it holds a key, the parts
give it meaning. Under D2 `User` also holds the overrides table and announces when it changes.

**The palette tool** (`CodeInjectingSimpleRectangularButtonWdgt`) answers its own press: it finds its
holder (the toolbar's host window, else `world.user`) and states
`holder.armDrawingTool (if @drawingToolKey is holder.armedDrawingTool then undefined else @drawingToolKey)`
— the second tap still puts the tool down, and that meaning stays at the gesture. `isActiveTool` reads
the same holder. It no longer needs a palette: the constructor's `palette` argument and the
`sourceCodeToBeInjected` field go. Its edit mark reads and writes the person's table (D2), after the
existing two compile checks plus D7's reserved-name refusal.

A docked paint tool ALWAYS sets its host's tool, drawings inside or not: a window wearing a palette has
a tool, as a drawing board has a tray. Mode tools are never "with nothing to act on".

**Dock and undock (D3)**, as two notifications the frame sends its arriving / departing band's payload
through guarded capability calls, so `FrameWdgt` stays paint-agnostic:
- arrival, from `_dockFrameNoSettle`: a toolbar holding drawing tools, when it is the FIRST such toolbar
  on that host, has the host adopt the hand's tool as it stands (an empty hand included).
- departure by re-homing, from `_reactToChildRemoved`: when the host is left wearing no drawing tools,
  the hand takes the host's tool (`world.user.armDrawingTool …`, which announces) and the host's field is
  cleared.
- NOT a departure: a re-side, a view-mode disengage, a collapse, a destroy. **Closing a window never
  writes the hand** — prove it with a test.
- Birth (D1): after construction an `ImageWdgt` whose adopted tool is undefined takes `'pencil'`.

**What this makes redundant — delete it:** `PaintToolbarWdgt`'s `_armed`, `resolveInjectionTarget`,
`reactToEditModeInFrame`, `reactToViewModeInFrame`, `selectTool`, `applyArmedDrawingTool`,
`_armSelectedTool`, `_sourceOfSelectedTool`, `_armedTool`, `holdsInHand`, `_deriveToolHighlights`, its
`_reLayoutChildren` override, `newCodeToInjectFromButton` and its subscription trio (→ §6.5);
`CodeInjectingSimpleRectangularButtonWdgt.injectCodeIntoTarget`; the two `reactTo…ModeInFrame` calls in
`FrameWdgt`; the whole `paintingOverlay` / `isPaintingOverlay` chain (four classes), once a grep of BOTH
repos, `scripts/` included, shows no other reader. Check whether `_deriveToolHighlights`' re-inking of the
tool faces is still owed somewhere before deleting it.

**The save.** A window's `armedDrawingTool` rides ordinary widget serialization. Under D2 the `users`
section gains the overrides: extend `Serializer`, `Deserializer._sectionUsersProblem` and the restore in
`WorldWdgt` together, and the serialization rigs' expectations with them. A load re-docks nothing (the
deserializer restores structure directly), so no transfer runs and the saved tools stand.

### 6.3 Property tools

- ONE query decides the subject, in `WorldWdgt` (core, generic): the style subject **within a window**.
  With no window it is today's answer. With a window it is the same answer only when the editor focus is
  in that window's reach, else undefined. R8's refusal lives in the same query: content in view mode
  hands over no subject. P1 landed that half as a door, `WorldWdgt.editableEditorFocus` (the focus, or
  undefined while it sits in view-mode content), which `editorStyleSubject` and the align fallback
  already read: P3 gives the door the host, so both readers keep reading one answer (§8 "P1 results").
- `EditorContentPropertyChangerButtonWdgt._styleSubject` passes its toolbar's host. Every subclass
  already goes through it. Route the two direct readers through the same door:
  `AlignButtonWdgt.activated`'s fallback and `TextToolbarWdgt.currentFontName`.
- Nothing else changes for a floating bar (R4, R5): it acts on the selection anywhere, including inside
  a Maker that wears its own bar.

### 6.4 Creators

- `CreatorWdgt.activated`: with a host, place into the host's content when it
  `acceptsSmartPlacedWidgets`, and otherwise do nothing — decide BEFORE making the widget. With no host,
  today's search. `GlassBoxTopWdgt` inherits this.
- Dragging an item out is unchanged: the drop names its target.
- R9: a drawing's container stops answering true. The clean statement is a capability of the canvas
  ("I stamp what is dropped on me") that the container consults, rather than a test on the Maker.
- D6: `ToolbarCreatorButtonWdgt.activated` and `TemplatesButtonWdgt.activated` are left alone.

### 6.5 The refresh, on the base

`ToolbarWdgt` holds the two edges a tool's look can depend on — `world → me` (the selection and its
style) and `world.user → me` (the hand and the tool table) — made at build and re-made in
`_afterDeserialization` and `_reactToBeingCopied`, guarded by `world.dataflow.hasEdge` as
`TextToolbarWdgt._followTheEditedText` does today. Their one action tells every cell
`noteItemStateChanged?()` and announces the toolbar (`markNonValueChange @`, which the font menu's ticks
reflect). The same verb is what a window calls on its docked payloads when its own tool changes, and what
a toolbar calls on itself when it docks or leaves.

`TextToolbarWdgt` and `PaintToolbarWdgt` then keep an item list, a default `dockSide`, and (the palette)
the stock tool sources. Every toolbar now holds two edges, creators-only ones included; that is accepted
for uniformity (measure it if the dataflow rigs disagree).

### 6.6 Dimming (P4)

Each tool kind answers whether it has something to act on: a property tool, whether its subject exists
and offers the tool's verb; a creator docked on a host that takes no placed widget, false for its click
(decide with the owner whether a tool whose drag still works is dimmed); a mode tool and a subject-less
action, always true. The cell derives a DIMMED look from that answer (a new `Theme` role; `disabledText`
and `buttonDisabledFill` / `buttonDisabledStroke` are the existing disabled inks to stay consistent
with), and a dimmed tool ignores its press. The look is the owner's choice from a local HTML preview.

---

## 7. Central risks

1. **S1 falsifies pull-at-use** (an event path that reaches a tool without passing the two entries; a
   shadowing instance member). Then STOP: the fallback is §11 item 4, with its hooks, and it needs the
   owner's go-ahead.
2. **P3 changes a long-standing behaviour.** Tests that press a docked tool at something outside its host
   will fail by design. M1 predicts the set; a failure outside it is a finding, not a recapture.
3. **P4 is a mass recapture.** Docs Makers appear in many shots. M1 sizes it before P4 starts; a set far
   larger than a few dozen tests goes back to the owner before any of it is recaptured.
4. **The transitions.** A wrong hook writes the hand at a close, a re-side or a mode flip. Each
   non-departure in §6.2 gets a value assertion.
5. **Anything saved in the old shape is unsupported**, by ruling: a drawing saved before this arc carries
   instance `hoverMoved` / `pressMoved`, which shadow the class entries, and a `users` section or a
   palette cell in the old form is simply not read. Write no code for them. The one thing to check is the
   suite's own sake: grep both repos for a COMMITTED fixture the tests or rigs load that carries one, and
   regenerate it.
6. **Determinism.** Take-up must be a pure function of structure at the event: no timers, no cycle
   counts. Pressed moves are already event-only while a test plays.
7. **Core / part layering.** `FrameWdgt` and `WorldWdgt` gain generic members only; every call from core
   into a payload is an existence-guarded capability call.
8. **Finger input.** No hover exists; the press path alone must take the tool up. Every new test runs
   under both pointers. (P0 measured: a touch stroke's glass still hears one `hoverMoved`, the hand
   arriving at the touch point, before its `pressMoved`s; the press path alone was proven separately.)

---

## 8. Phases

### P0 — spike and measure (no source change)

1. D1–D8 are ratified (§4.2): there is nothing to ask before the spike.
2. **S1 — the paint mechanism, planted.** Rebuild §3.1's probe under `Fizzygum-tests/.scratch/` (Node
   resolves `require` from the script's folder; the session scratchpad will not work) and plant §6.2 in
   the page after boot: the two class entries, the take-up, the holder climb, the pair on
   `FrameWdgt.prototype`, the dock / undock transfer, the stock sources without their two event lines.
   Acceptance, measured off the painting buffer and the kept source:
   - A (docked) and B (undocked, so the hand took B's pencil): BRUSH tapped on A's palette → A paints
     brush, B paints pencil, the floating palette still shows pencil.
   - TOOTHPASTE tapped on the floating palette → B paints toothpaste (a box 18 px tall or more), A still
     brush; a third drawing C whose palette is also undocked paints toothpaste too.
   - A, then B, to view mode → neither takes paint; a tool tapped on the floating palette meanwhile
     changes nothing they do; back in edit mode each paints what its holder holds by then.
   - The floating palette re-docked on B → B keeps painting toothpaste, and a later hand change leaves B
     alone.
   - A's window closed → the hand is unchanged.
   - A second palette docked on A's other side → both highlight the same tool.
   Record the results in this plan.
3. **M1 — the fallout, measured.** Read `Fizzygum-tests/scripts/lib/page-rails.js` and one prelude under
   `scripts/audit-preludes/` for the rails (`--audit-prelude`, `--audit-dir`). Write preludes under
   `.scratch/` that LOG, never fail:
   - a. every activation of a docked property tool while the focus is outside its host's reach, and
     every docked creator click that does not place into its host, with the test name;
   - b. P3's rule planted (subject within host; creators into host) → the suite's failing set at dpr 1
     and under `--pointer=finger`;
   - c. at every screenshot, whether a showing docked bar holds a property tool with no subject in
     reach → the count of shots D5 would change.
   Record the three sets here. They are the PREDICTED sets for P3 and P4.
4. Acceptance: S1 all rows as stated; the three sets recorded. No commit (nothing in the repos changed
   but this plan). Report to the owner and wait for the go-ahead to start P1.

#### P0 results (recorded 2026-11-16; Fizzygum `93a5ddab` = authoring head + this plan, tests `f470874b0`, build FRESH, no source change)

**§1 re-verified.** Since `14905c4c` only this plan's own commit landed; the four files §0.5 names are
unchanged and every method §1 names sits where it says, line numbers included. One reader §1 does not
list: `Fizzygum-tests/scripts/serialization-roundtrip-headless.js` (`R.paintedSurface`) finds the glass
with `isPaintingOverlay`, so P2's deletion of that chain must re-point it (`instanceof CanvasGlassTopWdgt`).

**S1 — PASS: every acceptance row.** Probe `Fizzygum-tests/.scratch/paint-two-makers/s1-spike.js`, its
plant in `s1-plant.js` beside it (gitignored; restated here so it can be rebuilt). `index-sw.html`, dpr 1,
real CDP mouse input. Fixture: three Drawings Makers A, B, C at 400×620 (any shorter and the palette puts
toothpaste and eraser behind its overflow »); B's and C's palettes undocked by a press-drag on their band's
grip. A stroke is a press-drag across 60% of the glass; it is read twice and both readings must name the
same tool: the changed-pixel box in `StretchableCanvasWdgt.behindTheScenesBackBuffer`, scaled to screen
pixels (buffer px × canvas width ÷ buffer width: a canvas narrowed by a second band is drawn smaller than
its buffer, so a 16 px brush lays a 20 px band there), and the kept source of the glass's `applyToolAt`.
Pencil 4 px, brush 16, toothpaste 18 (17.4 after a rescale), view mode 0.

The plant, as §6.2 states it: on `CanvasGlassTopWdgt.prototype` the two entries, `_applyToolInReach`,
`_takeUpToolInReach` (compare, `removeOwnProperty` each name the previous source assigns, inject the new),
`_sourceOfToolInReach`, the edit-mode test (nearest ancestor answering
`coordinatesDragsDropsAndEditingForChildren`, asked `isInEditMode`), `_toolHolder` (climb; the first
`isFrame` whose `contents` is the child the climb came up through and that `wearsDrawingTools`, else
`world.user`) and `hoverExited` as a class method; on `FrameWdgt.prototype` `armedDrawingTool` /
`armDrawingTool` (idempotent; a change tells its docked payloads to refresh), `dockedPayloads`,
`wearsDrawingTools`, `dockHost` (`@parent if @_myEdgeDockSpec()?`); on `ToolbarWdgt.prototype`
`hostWindow`, `holdsDrawingTools` and the refresh verb (every cell `noteItemStateChanged`); the palette
tool's `activated` and `isActiveTool` against its holder; the stock sources compiled through
`Widget.compilePropertyAssignments` and re-joined without `hoverMoved` / `pressMoved` (pencil, brush,
eraser keep `applyToolAt`; toothpaste keeps `paintBrush`, `initialiseQueueIfNeeded`, `pressEnded`,
`applyToolAt`); `ImageWdgt._makeStartingPayload` wrapped to delete what it injected; the transfers on
`_dockFrameNoSettle` (first drawing-tool toolbar on the host: the host adopts the hand),
`_reactToChildRemoved` (a re-homed band, not destroyed, leaving the host wearing none: the hand takes the
host's tool, the host's field cleared) and `_buildDockedToolbarNoSettle` (D1: an empty hand at a birth
gives the window pencil); and every pusher §6.2 deletes neutralised: `_armSelectedTool` and
`applyArmedDrawingTool` refresh only, `reactToEditModeInFrame` / `reactToViewModeInFrame` deleted from the
prototype, `newCodeToInjectFromButton` and `injectCodeIntoTarget` no-ops.

The run (rows reordered only where a row's precondition needs it: row 6 runs before row 5, which closes A;
before row 4 the hand is put back on toothpaste, because row 3's tap moved it):

| Row | Measured |
|---|---|
| 1 | BRUSH on A's docked palette: A paints brush (16), B paints pencil (4); the floating palettes show pencil, A's shows brush; hand pencil |
| 2 | TOOTHPASTE on B's floating palette: B toothpaste (18), C (also undocked) toothpaste (18), A still brush; both floating palettes show toothpaste |
| 3 | A, then B, to view mode: neither takes paint and both glasses carry no tool members; PENCIL tapped on a floating palette meanwhile changes only the hand; back in edit mode A paints brush (its own), B pencil (the hand's by then) |
| 4 | the floating palette re-docked on B by a real drag (a ~1 s still hold over B's left band arms the drag-embed dwell): B adopts the hand's toothpaste, keeps painting it (17.4), its palette still shows toothpaste; a later PENCIL on C's floating palette leaves B on toothpaste while C follows (pencil) |
| 6 | a second palette, opened floating, docked on A's right by a real drag: no transfer (A already wears one); both of A's palettes highlight brush; ERASER on the second, then BRUSH on the first: both follow each time; A paints brush; the hand untouched |
| 5 | A closed from its bar, "Don't save" (a destroy): the hand unchanged. Extra: B closed, "OK" (saved, the window put on the shelf): the hand unchanged |

31 checks, 31 pass, no page error; no glass ever carried an OWN `hoverMoved` / `pressMoved` (checked after
every stroke). Transfers logged: three births adopting the hand, two departures (pencil), one re-dock
arrival adopting toothpaste, one second-palette arrival with no transfer.

Beyond the acceptance rows, same plant:
- **Finger** (`s1-finger.js`, touch-emulated page, CDP touch): a touch tap on a floating palette sets the
  hand; a touch stroke on a palette-less drawing paints it; a touch tap on a docked palette then a touch
  stroke paints the host's tool, the hand untouched; view mode lays nothing. 5 of 5. ⚠ §7 risk 8's
  premise is not literal here: a touch stroke's glass hears ONE `hoverMoved` (pointerType touch, the hand
  arriving at the touch point) before its `pressMoved`s, and the take-up ran there. The press path alone
  was then proven separately: the hand changed while the finger was down, and the next `pressMoved` took
  the new tool up (toothpaste, 18 px).
- **Cost** (`s1-cost.js`): a take-up after a change costs a median 2.0 / 5.0 / 6.6 / 1.9 ms (pencil /
  brush / toothpaste / eraser; worst 9.3), once per change; an unchanged take-up (the climb and the
  compare, paid on every move over a glass) about 1.7 µs.
- **Transitions** (`s1-transitions.js`, §7 risk 4, driven by the frames' own verbs; 10 of 10): with the
  window on brush and the hand on pencil, none of these writes the hand or the window's tool: a re-side
  (`dockAtSide`), the band collapsed, the window collapsed, view mode and back. A payload destroyed and
  rebuilt (`_resetToDefaultContents`) writes no hand either, and its FRESH palette's arrival makes the
  window adopt the hand (brush → pencil: the drawing is new, as D1 wants). A palette docked into a slot
  another palette holds keeps the window's tool and writes no hand. D1: a Maker born while the hand is
  empty takes pencil and leaves the hand empty. The holder climb through a nesting window: a bare drawing
  surface placed in a Docs Maker that wears a docked palette takes its tool from the Docs Maker (brush
  tapped there: the drawing takes brush, the hand stays pencil).

What S1 established for P2:
1. **Every pusher goes in the same step as the entries.** The first run left `reactToViewModeInFrame`
   live: at the mode flip it injected the old no-op `hoverMoved` / `pressMoved` onto the docked drawing's
   glass as INSTANCE members, which shadow the class entries, and the drawing then painted nothing in
   either mode. That is §7 risk 1's shadowing member, made by a pusher. P2's step order (§8 P2.1) must not
   leave a build where the entries exist and any pusher survives.
2. **A direct arming mixes with the take-up.** The take-up removes only what it injected itself
   (`_takenUpToolSource`), so a tool source injected onto a glass by anything else stays and is overlaid.
   The only such site outside `ImageWdgt` is `SystemTest_macroEveryPressIsToldItsEnding` §(d), which arms
   its glass with `injectProperties PaintToolbarWdgt.sourceForToolKey "toothpaste"`: P2 re-authors it to
   arm through the hand (`world.user.armDrawingTool 'toothpaste'`). Add it to §8 P2.4's re-read list.
3. **`_reactToChildRemoved` is also a destroy's notification** (`Widget._destroyNoSettle` →
   `previousParent._reactToChildRemoved`, with `child.destroyed` already true). In every destroy S1 drove
   (a window closed with "Don't save", a payload reset retiring its bands, a palette replacing a palette)
   the departure condition never held: the slot was freed first, or the toolbar was destroyed before its
   frame. Nothing structural guarantees that order, so the departure still excludes a destroy explicitly
   (`child.destroyed`), as the plant did.
4. **The climb helper §6.1 names is root-first.** `TreeNode.allParentsBottomToTopSuchThat` recurses to
   the root and pushes self last (measured: root, middle, self), so the NEAREST match is its LAST element;
   take that, or climb by hand.
5. **A second palette cannot keep D3's invariant.** Docked on a window that already wears one, it shows
   the window's tool, not the hand's it showed floating (pencil → brush in row 6). §6.2 already scopes
   the arrival transfer to the first such toolbar and R7 requires the agreement, so this is the expected
   consequence. It is one more thing the owner sees at the D3 checkpoint.
6. **Docking by drag needs the drag-embed dwell** (`ActivePointerWdgt.drop`: `wasArmed and
   releasedOverBand`). P2's docking tests use `dwellDragWindowByTitleToEmbed_InputEvents_Macro`.
7. **Readers to keep in view:** `SystemTest_macroPinnedMenuTicksFollowTheirState` reads
   `world.user.armedDrawingTool` through a FLOATING palette's overflow menu (expected unaffected);
   `SystemTest_macroToolCodeSaveRefusesCodeThatDoesNotCompile` reads `resolveInjectionTarget`,
   `sourceCodeToBeInjected` and `modifyCodeToBeInjected`; `SystemTest_macroDrawingsMakerReEnableEditing`
   reads the two mode hooks and the hand.

**M1 — the three sets.** Instruments under `Fizzygum-tests/.scratch/m1/` (gitignored):
`m1-observe-prelude.js` (log-only; joined behind `scripts/audit-preludes/audit-head.js` by
`node scripts/lib/audit-head.js` and run as `run-all-headless.js --audit-prelude=… --audit-dir=…`),
`m1-p3-plant.js` (P3's rule, `--prelude=`) with its witness `m1-plant-witness-prelude.js` (beside the plant,
as the `--audit-prelude`), and `analyse-m1.js` / `analyse-witness.js`. Each was proven on a positive control
before the full runs. The observer was run on seven toolbar tests; its first version installed 3 of its 14
hooks, because `allClassFunctions()` answers class FUNCTIONS, not names. The plant was run on §3.2's T1 and a
C1 variant (`ctl-plant.js`): today B's paragraph goes bold from A's bar and the text box lands in front-most
Docs D; planted, neither. Every suite run was dpr 1, 8 shards, valid and complete. The observer runs are green
(mouse 389/389, finger 374/374, a second mouse run 389/389) and are the baseline.

What the instruments mean by each word: a tool's toolbar is its nearest `ToolbarWdgt` ancestor; DOCKED when
that toolbar's frame answers `_myEdgeDockSpec()` (R3), the HOST being that frame's parent; IN REACH = inside
the host's `contents`. A PROPERTY tool is an `EditorContentPropertyChangerButtonWdgt` other than
`TemplatesButtonWdgt` (D6), hooked at each class's own `activated` and at
`ChangeFontButtonWdgt.setFontNameFromMenu` (the font tool applies from its menu row). A CREATOR is a
`CreatorWdgt` other than a `ToolbarCreatorButtonWdgt` (D6; the only override of `activated`). A shot is
`AutomatorPlayer.compareScreenshots`; a tool SHOWS when its `clippedThroughBounds()` is not empty.

- **M1a — EMPTY (mouse and finger).** The whole suite activates a docked property tool 9 times, every time
  with the focus in its host's reach: Bold in `macroSelectionOverlaySurvivesBringToFront` (Docs),
  `macroSpreadsheetEnterTabDeleteMoves` and `macroSpreadsheetToolbarActsOnSelection` (Sheets); AlignRight in
  `macroPinnedMenuTicksFollowTheirState` (Docs); AlignLeft in `macroSpreadsheetKeysFollowFocus`; the font row
  in `macroSpreadsheetMenuTicksStayLive`; FillColor, MoreDecimals and SliderInCell in
  `macroSpreadsheetToolbarActsOnSelection`. It activates no floating property tool, clicks no docked creator,
  and clicks one floating creator (a `GlassBoxTopWdgt` lid in `macroToolbarChevronPopsOverflow`, placed on
  the desktop).
- **M1b — EMPTY (mouse 389/389 and finger 374/374 pass with P3's rule planted).** The witness proves the
  plant was live at every shot (1033 of 1033 mouse, 990 of 990 finger) and consulted: it changed
  `_styleSubject`'s answer up to 165 (mouse) / 170 (finger) times per page, rising inside
  `macroDockAnyFrame`, `macroDocsToolbarDockSidesAndFloat`, `macroPageSelectionRingInWindowGutter`,
  `macroSpreadsheetDragWidgetOutOfCell`, `macroSpreadsheetKeysFollowFocus`,
  `macroTabletDockedToolbarChevron` (and, under finger, `macroSpreadsheetDropWidgetIntoCell`). All of
  those are highlight reads (`isActiveTool`) of a docked bar while the focus was elsewhere, on a subject
  that lacked the style, so no look changed. The align, font-name and creator counters stayed 0. So P3
  changes no existing test. Its coverage is §8 P3.2's new tests alone, and §8 P3.3's "the failing set must
  EQUAL M1b's" reads: no existing test may fail.
- **M1c — 26 shots in 12 tests (identical under finger, and across two mouse runs).** Read with §6.6's
  whole rule (a property tool whose subject, within its host when docked, is absent or does not offer its
  verb; docked or floating; plus a docked creator on a host that takes no placed widget). Every one is a
  property tool on `TextToolbarWdgt` docked on a Docs Maker (97 tool-showings), `TextToolbarWdgt` floating
  (43), or `SheetToolbarWdgt` docked on a Sheets Maker (27); creators: 0. Most show a Maker whose bar has
  nothing focused in reach: a freshly opened Maker has no editor focus. Asterisked shots are outside §8
  P0.3c's narrower count (a DOCKED bar with no subject in reach: 21 shots in 11 tests); §6.6's rule adds
  the floating bar's 5.

  | Test | Shots |
  |---|---|
  | `macroCollapsedDockIsAnEdgeSliver` | 0, 2 |
  | `macroDockAnyFrame` | 0, 1 |
  | `macroDockedFrameHasNoCloseNoResizer` | 0 |
  | `macroDocsToolbarDockSidesAndFloat` | 0, 1, 2*, 3 |
  | `macroDocsToolbarSlotEditViewToggle` | 0, 2 |
  | `macroPageSelectionRingInWindowGutter` | 0*, 2, 3 |
  | `macroSpreadsheetDragWidgetOutOfCell` | 2 |
  | `macroSpreadsheetDuplicate` | 1 |
  | `macroSpreadsheetKeysFollowFocus` | 2 |
  | `macroTabletDockedToolbarChevron` | 1, 2, 3 |
  | `macroToolbarGridPacksAndSpreadsOnlyWhenFull` | 0, 1, 2 |
  | `macroToolbarWindowBarCrossesItsRun` | 0*, 1*, 3* |

  R8 (P1's view-mode refusal, approximated with the selection ring's editing climb,
  `WorldWdgt._widgetBeingEdited`) adds 0 shots. So P4's recapture is these 12 tests at dpr 1 and 2,
  mouse and finger, well inside §7 risk 3's "a few dozen". Blind spots: a showing bar hidden behind
  another window is still counted (an over-count); the rows of an open overflow pop-up are not counted,
  so if P4 dims those rows too, shots with such a pop-up open join; "offers its verb" is read off each
  class's own `activated` (§6.6 leaves the verb test itself to P4).

### P1 — content-side bugs (independent of the rest)

1. R8: the view-mode refusal, at the one query (§6.3 describes where it ends up; in P1 it guards
   today's `editorStyleSubject` and the align fallback). Find how "this content is in view mode" is asked
   for a focused widget: which ancestor holds the mode, for a paragraph in a document, a text box in a
   slide, a cell of a sheet, a text on the bare desktop (which has no mode and stays editable).
2. R9: the drawing declines placement (§6.4).
3. Tests: one macro each. V1's scenario with the paragraph's weight asserted unchanged; C2's scenario
   with the new widget asserted a child of the world, plus the drag asserted to stamp as it does today.
4. Gates: `fg presuite`; the finger suite; `fg gauntlet`. Then summary + commit message; wait.

#### P1 results (recorded 2026-11-16, on Fizzygum `6b4c0d65` and tests `f470874b0`)

**R9: a drawing takes no click-placed widget.**
- The capability lives on the canvas. `StretchableCanvasWdgt.stampsDroppedWidgets` states it: what is dropped on me is
  stamped into my image and the widget is handed back to the world.
- The container consults it: `StretchableWidgetContainerWdgt.acceptsSmartPlacedWidgets` is now
  `@dragsDropsAndEditingEnabled and !@contents?.stampsDroppedWidgets?()`. `CreatorWdgt.activated`'s logic is unchanged.
- Measured on the build (`Fizzygum-tests/.scratch/p1-r9/r9-accept.js`, 6 of 6):
  - Slides, Dashboards, Patch programming, Generic panel and Docs still take a click-placed widget; Drawings does not.
  - C2 with only the drawing open: the text lands on the desktop beside the tool and the canvas is untouched, both
    by `activated()` and by a real click. A drag of the same creator still stamps.
- Consequences, as R4 states them:
  - With a Slides Maker behind the front-most drawing, the click places into the Slides Maker. The search passes over
    a window that takes no placed widget, as it already passes over a window in view mode.
  - A tool cell's lid (`GlassBoxTopWdgt`) behaves the same.
  - A drawing nested in a front-most Docs Maker leaves the click to the document, because the search reads only the
    world's direct children.

**R8: how "this content is in view mode" is asked.**
- The door: `WorldWdgt.editableEditorFocus`, public, answers the focus, or undefined while it sits in view-mode content.
- The question behind it is the widget's own: `Widget.sitsInViewModeContent`, a public query of a widget about
  itself.
  - It starts at the widget's PARENT, so a selected nested Maker answers to the content it stands in.
  - The first ancestor below the root answering `providesAmenitiesForEditing is true` decides, by `isInEditMode()`.
  - An ancestor answering `false` (a spreadsheet, a sheet's cell panel, a command panel) holds no mode and is passed
    over. The selection ring's walk stops there instead, because that container draws its own selection.
  - No holder below the root means no mode, so the content is restylable.
- `editorStyleSubject` and `AlignButtonWdgt.activated`'s stack-alignment fallback both read the door.
- **A text's own menu asks the same question.** `StringWdgt._addTextMenuEntries` offers none of its editing rows in
  view-mode content: Edit…, Font size…, Font, Bold, Italic, the header line, the alignments and the fitting rows.
  `TextWdgt` withholds its "Soft wrap" row there too, but keeps its run rows, because running code edits nothing.
  Before the fix, a right-click on a view-mode paragraph → "Text" → "Bold" bolded it (measured,
  `.scratch/p1-r8/r8-menu-door.js`). This is the content-side refusal of the owner's first direction, so R8 holds at
  the toolbars and at the content's own door alike.
  - The alignment and fitting rows moved to their own method, `_addAlignmentAndFittingMenuEntries`. The guard would
    have raised the method's complexity record, and those rows already formed groups of their own, all about placing
    the text in its box. Judged on its merits the split stands, and the record falls away.
  - A residual is filed: a text menu PINNED while its content was in edit mode keeps its rows after the mode flips,
    because a menu is built when it opens.
  - Two members joined the inspected chains (`Widget.sitsInViewModeContent`,
    `StringWdgt._addAlignmentAndFittingMenuEntries`), so the inspector member lists moved. 13 of the 16 tests in the
    measured churn set (`Fizzygum-tests/scripts/inspector-churn-set.json`) failed on exactly that, and were
    recaptured with `fg recapture-inspector`, mouse and finger, under the owner's standing ruling that inspector
    member-list churn is a non-cost.
  - The same shift exposed a HARNESS gap. `bringInViewAndClickOnListItem` nudges the list's thumb one pixel at a
    time, but on a long enough list one thumb pixel carries the window further than the pane is tall: measured, 228
    px per pixel on a 21,000 px class-member list under a 141 px pane. A row between two thumb stops was then
    unreachable: `macroClassEditShowsOnTheNextFrame`'s `linePitch` row swung across the gap and the macro threw.
    - The verb now finishes with wheel notches (`MacroToolkit.wheelListTowardItem_InputEvents`, which scroll by
      content pixels), and only once the thumb nudges have failed. So every scroll the nudges already finish replays
      byte-identically, and that test passes with no recapture.
- A mode flip above the focus is announced: `WorldWdgt.noteEditModeChanged`, told by `Widget`'s and `ViewportWdgt`'s
  mode cores through `@root()`. So a bar stops showing a tool active the moment its content goes to view mode.
  `ViewportWdgt`'s cores never reach `Widget`'s, so both tell it.
- Measured on the build (`.scratch/p1-r8/r8-accept.js`, 15 of 15, real clicks wherever a person would click):

| Focus | The holder that decides | Answer |
|---|---|---|
| a paragraph in a Docs Maker | `DocumentViewportWdgt` | refused in view mode, applied in edit mode |
| a text box in a slide | `StretchablePanelWdgt` | refused in view mode, applied in edit mode |
| a sheet (focused as a whole, handing over its cell's style) | none in its own window; a document's viewport when nested in one | a sheet in its own window has no mode and stays restylable; a sheet in a view-mode document refuses |
| a text on the bare desktop | none | restylable |
| nested Makers | the nearest | outer view, inner edit: restylable; outer edit, inner view: refused |
| a text in a desktop stack after "Disable editing" | the stack | refused |
| inspector, console and text-area texts (22 + 1 checked) | edit-mode panes, or none | never refused |

  Further measurements:
  - Each mode toggle makes two mirror calls, and a toggle on an unrelated window makes none.
  - A rectangle in a view-mode Docs Maker nested in an edit-mode one no longer moves its window when an align tool is
    pressed; in edit mode the align still works.
  - P0's M1c already measured that this refusal changes no existing shot. The suite agrees: no existing reference
    changed.

**Ratchets.**
- In `buildSystem/check-complexity-ratchets.js`, `WorldWdgt`'s method ceiling rises from 126 to 128 (the door and the
  notification) and `Widget`'s from 391 to 392 (`sitsInViewModeContent`), each with its reason beside the number.
  - The owner approved this on 2026-11-16: "if the right architectural shape needs a raise of the ratchet, go ahead.
    Don't make the solution worse because of the ratchet".
  - A zero-net reshape was tried first and reverted.
  - `StringWdgt#_addTextMenuEntries` leaves the complexity records (see the split above).
- The `comment-narration` stink falls from 83 to 82 (banked).
- ⚠ For P2: `FrameWdgt` and `ActivePointerWdgt` sit exactly at their ceilings (170 and 74). §6.1 and §6.2 put about five members on `FrameWdgt`: the dock-host query,
  `armedDrawingTool`, `armDrawingTool`, `dockedPayloads` and `wearsDrawingTools`. Judge the shape first, and raise
  the ceiling with its reason where the right shape needs it.

**Tests.**
- `SystemTest_macroViewModeTextRefusesFloatingBold` (V1) carries an edit-mode control proving the press is real.
  It then checks the text-menu door: the paragraph's own menu offers its weight and font rows in edit mode and none
  of its editing rows in view mode. That half bites on its own plant (`.scratch/p1-tests/bite-menu-plant.js`) under
  both pointers, failing at the view-mode row assertions with the toolbar half untouched.
- `SystemTest_macroDrawingTakesNoClickPlacedWidget` (C2) also drags the creator onto the drawing, which stamps. The
  dragged-out text is then moved off, so the screenshot shows the stamp.
- One screenshot each, at dpr 1 and 2, mouse and finger; the finger references are byte-identical to the mouse ones.
- Each test bites under both pointers with the bug planted through `--prelude=`
  (`.scratch/p1-tests/bite-v1-plant.js`, `bite-c2-plant.js`), failing first at its ruling's assertion.
- A follower (`run-sequence-headless.js <new> SystemTest_macroAnalogClockInspectEdit`) runs clean on both pointers,
  with no `WORLD_INVENTORY_` lines.

**Found on the way** (filed in BACKLOG; not in P1's scope):
- **A text menu pinned in edit mode keeps its editing rows after a flip to view mode.** See the residual above.
- **Choosing a context-menu row takes the editor focus, and closing the menu clears it.** The press on a menu row
  focuses the row, because an ordinary menu is not editor chrome, and the menu's teardown clears the focus. So a
  selected paragraph is unselected after its menu is used. Measured with a focus-write trace; V1's menu steps assert
  only that the closing press does not focus the desktop.
- **A sheet inside a view-mode document still takes typed entries.** Typing "42" then Enter stored A1 = 42. This is
  editing, not restyling.

**Gates.**
- `fg presuite` passed after R9 (389 of 389), after R8 (389 of 389) and after the tests (391 of 391). Each was
  paint-truthful, and no existing reference changed.
- The finger suite at dpr 1 passed: 376 of 376.
- `fg gauntlet` passed all 20 legs with no retry (1150 s): dpr1, dpr2, webkit, apps, parts, menusweep, pinsweep,
  graph, selftests, paint, tiernaming, settle, capstone, refs, revisits, census, serialization, storage, vmtruth and
  finger.
- The text-menu door and the list verb's wheel fallback were added after that.
  - Their presuite failed on exactly the 13 inspector-churn tests and the unreachable list row (both described
    above).
  - `fg recapture-inspector` then completed, with the full suite green mouse and finger at dpr 1 and 2.
  - The final `fg gauntlet` passed all 20 legs, again with no retry (1128 s).

### P2 — the seam and paint

1. §6.1, then §6.2 in this order: the surface's entries and take-up → the holder pair on `FrameWdgt` →
   the palette tool answering its own press → the transfers → D2's table and the save → the deletions.
   Build after each; the syntax gate runs on every build. ⚠ No build may hold the entries beside a
   surviving pusher: S1 measured a live `reactToViewModeInFrame` injecting instance `hoverMoved` /
   `pressMoved` that shadow the class entries (P0 results, finding 1). The stock sources lose their two
   lines, and the pushers (`_armSelectedTool`, the two `reactTo…ModeInFrame`, `newCodeToInjectFromButton`,
   `injectCodeIntoTarget`, `ImageWdgt`'s injection) stop pushing, in the SAME step as the entries.
2. Keep `PaintToolbarWdgt`'s refresh working through this phase with whatever is smallest (its own edge
   to the user may stay until P3 moves it to the base).
3. Tests (macros; assert VALUES with `assertValuesEqual` wherever a pixel is not the point; paint
   strokes are pixels): two drawings keep their own tools; an undocked palette drives every palette-less
   drawing and no docked one; view mode with the palette floating; the dock / undock invariant; a closed
   window leaves the hand alone; an edited tool reaches every drawing using that key (D2); a drawing
   nested in a window wearing a palette follows that window.
4. Existing tests to re-read, not just re-run: `SystemTest_macroDrawingsMakerReEnableEditing` (its
   image_0 == image_2 assertion and its comments name the hooks being deleted),
   `SystemTest_macroPencilPaintsStrokeOnLeftDrag`, `SystemTest_macroToolCodeSaveRefusesCodeThatDoesNotCompile`,
   `SystemTest_macroSuperToolbarOpensEveryToolbar`, `SystemTest_macroEditModeSlidingToggle`. True up their
   metadata prose where it describes the old mechanism. Also, from P0: re-author
   `SystemTest_macroEveryPressIsToldItsEnding` §(d), which arms its glass by injecting
   `PaintToolbarWdgt.sourceForToolKey "toothpaste"` directly (under the take-up that mixes two tools: arm
   through `world.user.armDrawingTool 'toothpaste'` instead); and re-point
   `Fizzygum-tests/scripts/serialization-roundtrip-headless.js` `R.paintedSurface`, which finds the glass
   with `isPaintingOverlay`, before that chain is deleted.
5. Gates: `fg presuite`; the finger suite; `fg gauntlet` (its `serialization`, `menusweep`, `pinsweep`,
   `vmtruth` and `storage` legs all touch this change). Expected pixel change: none outside the tests
   above; explain any other.
6. Summary + commit message; wait. **Then the owner checkpoint:** the owner docks and undocks palettes by
   hand and rules on D3.

#### P2 results (recorded 2026-11-17, on Fizzygum `fa5f3417` and tests `b7b071767`)

**The seam (§6.1), as built.**
- `FrameWdgt.dockHost` (public): the window whose edge slot I occupy, else undefined.
- `FrameWdgt.dockedPayloads` (public, paint-agnostic): what a window wears, in slot order; a disengaged band is
  still listed.
- `ToolbarWdgt.hostWindow`: who I work for — my frame's `dockHost`; undefined means the person.
- `ToolbarWdgt.hostWindowOf(aWidget)`, a static: the ONE home every tool asks. It climbs by hand, nearest first,
  to the first ancestor answering `hostWindow` (`allParentsBottomToTopSuchThat` is root-first; its sibling
  `allParentsTopToBottomSuchThat` is the nearest-first one — the names read backwards).
- `ToolbarWdgt.holdsDrawingTools` and the static `ToolbarWdgt.wearsDrawingTools(aFrame)`.

**Paint (§6.2), as built.**
- The surface owns the entries. `CanvasGlassTopWdgt`'s class `hoverMoved` / `pressMoved` run
  `_applyToolInReach`, and its `_takeUpToolInReach` is §6.2's block verbatim. Its `hoverExited` is a class
  method too, and `ImageWdgt._makeStartingPayload` injects nothing.
  - **Which tool:** `_sourceOfToolInReach` asks P1's ONE view-mode question, `Widget.sitsInViewModeContent`,
    rather than a second climb. For a glass, the deciding ancestor is its own canvas (a `PanelWdgt`), whose
    flag the drawing's container sets at every mode flip.
  - **Who holds it:** `_toolHolder` climbs to the first frame whose `contents` the climb came through and that
    wears drawing tools, else the person.
  - The only `injectProperties` call that injects a tool source in src is now the take-up.
- The holders.
  - `FrameWdgt.armedDrawingTool` is a plain field, and `armDrawingTool` is idempotent; after a real change it
    tells each docked payload `noteToolHolderChanged`.
  - `User` keeps its pair and holds D2's table: `drawingToolOverrides`, `drawingToolOverrideFor`,
    `overrideDrawingTool`, and `replaceDrawingToolOverrides` for the load.
- The palette tool answers its own press against `ToolbarWdgt.hostWindowOf(@) ? world.user`, and its
  `isActiveTool` reads the same holder.
  - Its constructor is `(face, drawingToolKey)`. `sourceCodeToBeInjected` and `injectCodeIntoTarget` are gone.
  - Its edit mark opens `PaintToolbarWdgt.sourceForToolKey`: the person's edit, else `stockSourceForToolKey`.
  - Its save keeps the two compile checks, then D7's refusal (`CanvasGlassTopWdgt.refuseToolCodeAssigningMyEntries`,
    the names in `CanvasGlassTopWdgt.TOOL_ENTRIES`), then writes the person's table.
- The transfers are two guarded notifications from core. Their logic lives on `ToolbarWdgt`, so a mixed bar
  transfers too.
  - `_dockFrameNoSettle` ends with `payload.noteDockedOn? @`.
  - `_reactToChildRemoved` tells `noteUndockedFrom` only to a band that was docked and is not destroyed.
  - D1 lives in `ImageWdgt`'s override of `_buildDockedToolbarNoSettle`: the window takes pencil when it wears
    drawing tools and holds none. That covers a birth, a payload reset and the "Toolbar" row.
- The refresh: `ToolbarWdgt.noteToolHolderChanged` tells every cell `noteItemStateChanged`.
  `PaintToolbarWdgt` keeps its one edge to the user (action `noteToolHolderChanged`) until P3.
- Deleted, as §6.2 lists them, plus `FrameWdgt._dockedToolbar`.
  - The whole `paintingOverlay` / `isPaintingOverlay` chain went. Its one other reader,
    `serialization-roundtrip-headless.js`'s `R.paintedSurface`, now finds the glass by class.
  - `_deriveToolHighlights`' re-inking of the faces was still owed, because an icon built without a colour
    takes `iconInk`, not `toolbarGlyph`. The faces are now built in `toolbarGlyph`, as every other toolbar's
    glyphs are, and every reference still matches.
- The save. Each `users` record carries `drawingToolOverrides` (left out while empty;
  `Serializer._userRecord`).
  - `Deserializer._userRecordProblem` refuses a table that is not a plain record of strings.
  - The load REPLACES the live person's table with the file's.
  - A window's tool rides ordinary widget serialization.

**Measured on the build** (acceptance probes in `Fizzygum-tests/.scratch/p2/`, gitignored, real CDP input, no
plant; each also passes on the pre-P2 build with S1's plant (`--plant-s1`) and fails there without it):
- `p2-accept.js`: 42 of 42, S1's six rows plus a D2 row. Edited pencil code reaches a palette-less drawing and a
  drawing whose window holds pencil, and leaves a toothpaste drawing alone. No glass ever carried its own
  `hoverMoved` / `pressMoved`, and every stroked glass carried exactly its source's members.
- `p2-finger.js`: 10 of 10. A hand change made while the finger is down is taken up at the next `pressMoved`.
- `p2-transitions.js`: 22 of 22. The holder climb through a Docs Maker holds, and a later hand change leaves
  the nested drawing alone.
  - ⚠ One row differs from S1: a palette dropped into an OCCUPIED slot. `_dockFrameNoSettle` destroys the
    occupant before the add, so the host wears no other palette and ADOPTS THE HAND (S1's plant compared
    against the state before the dock and kept the host's tool).
- **The owner's D3 checkpoint — APPROVED 2026-11-17**, D3 standing as built, with its three behaviours: a palette
  dropped into an occupied slot makes the window adopt the hand (above); a SECOND palette docked on a window shows
  the window's tool, not the hand's it showed floating (P0 finding 5); undocking changes the tool of every other
  drawing that follows the hand (D3's accepted side effect).
- `p2-cost.js`: 34 of 34. A take-up costs a median of 1.9 / 5.1 / 6.8 / 1.9 ms (pencil / brush / toothpaste /
  eraser), worst 13.5 ms, once per change. An unchanged use costs 0.1 µs under the hand and 1.4 µs under a
  window.

**Tests.**
- New, each with one screenshot at dpr 1 and 2, mouse and finger; finger references differ from mouse ones
  because a finger stroke's dabs fall elsewhere, while every value assertion is the same on both pointers:
  - `SystemTest_macroTwoDrawingsKeepTheirOwnTools` (24 assertions): two drawings, the floating palette driving
    only palette-less drawings, view mode with the palette floating.
  - `SystemTest_macroPaletteDockUndockKeepsTheTool` (29): the undock hands the window's tool to the person; the
    re-dock adopts it; a tap, a view-mode flip and a re-side write nothing; "Don't save" leaves the hand alone.
  - `SystemTest_macroDrawingToolReachesEveryDrawingOfItsHolder` (24): D2 through a real edit-mark prompt, and a
    drawing nested in a Docs Maker wearing a palette.
- Each bites under both pointers through `--prelude=` (`Fizzygum-tests/.scratch/p2-tests/`):
  - the hand-only holder fails the first test and the third's nesting half;
  - no transfers fails the second, and the arrival alone removed fails it at the re-dock;
  - the stock-only key table fails the third's edit half.
- Re-authored:
  - `SystemTest_macroToolCodeSaveRefusesCodeThatDoesNotCompile` now guards D7 for both entry names (it is the
    guard named by `TOOL_ENTRIES`' hand-list sanction) and a valid edit taken up at use.
  - `SystemTest_macroEveryPressIsToldItsEnding` §(d) arms through the person and takes the tool up with one
    move before its spy goes on (an earlier spy is overwritten by the take-up's injection).
- Prose trued up: `macroDrawingsMakerReEnableEditing`, `macroPencilPaintsStrokeOnLeftDrag`,
  `macroPinnedMenuTicksFollowTheirState`.

**Found on the way.**
- **Fixed in P2: "Don't save" leaked the closed window's whole subtree.** `SaveShortcutPromptWdgt`'s button
  dispatched a single-widget `destroy`, which empties `children` and leaves the canvas, glass, bar and docked
  palette alive and owned by nothing: 21 `WORLD_INVENTORY_` ESCAPED rows behind the new dock/undock test, on
  both pointers. It now dispatches `fullDestroy`. No earlier test drove "Don't save".
- Filed: a drawing standing bare in a view-mode document still takes paint (its canvas holds its own mode,
  which the document's flip does not reach — the shape of the sheet that still takes typing); Home and End are
  wrong in a multi-line text (`TextWdgt.startOfLine` / `endOfLine` read `.y` from `slotRowAndColumn`, which
  answers `[row, column]`).
- Not filed (no gesture reaches them): a programmatic `dockFrame` of a band onto its own host runs a departure
  and an arrival (`_addNoSettle` re-homes it), so it writes the hand; a band destroyed directly leaves its host's
  `armedDrawingTool` set, which nothing reads while the host wears no drawing tools and the next arrival
  overwrites.

**Ratchets and gates moved.**
- `FrameWdgt`'s method ceiling: 170 → 171, under the owner's standing ruling. In: `dockHost`, `dockedPayloads`,
  `armDrawingTool`. Out: `paintingOverlay`, `_dockedToolbar`.
- `CanvasGlassTopWdgt.TOOL_ENTRIES` carries a hand-list sanction naming the test that guards it.
- `check-unresolved-sends.js` BUILTINS gains `getImageData`, the canvas platform call the new tests read pixels
  with (src spells it without parentheses, so these macros are its first visible senders).
- The tier-naming audit's `NON_GEOMETRY` (`Fizzygum-tests/scripts/tier-naming-audit/tier-naming-prelude.js`) gains
  `_applyToolInReach`: an `_apply*` name that applies a tool, not a frame. Its absence failed the first P2
  gauntlet's `tiernaming` leg and, through that gate's own control run, its `selftests` leg (both deterministic;
  the other 18 legs passed).

**Gates.**
- `fg presuite` passed after the source change (391 of 391), after the save (391 of 391; the serialization rig at
  178 expectations, the file rig at 10 checks) and with the new tests (394 of 394). Each was paint-truthful, and no
  existing reference changed: P2 moved no pixel outside its new tests, and no inspector member list moved either.
- The finger suite at dpr 1 passed: 379 of 379.
- Each new test's follower runs clean on both pointers (no `WORLD_INVENTORY_` line).
- `fg gauntlet` passed all 20 legs with no retry (1233 s). The first run failed `tiernaming` and `selftests` on
  the unclassified `_applyToolInReach` alone (see above).

### P3 — text tools and creators on the seam; the refresh on the base

1. §6.3, §6.4, §6.5. The two subclasses reduce to their lists.
2. Tests: a docked text bar acts only inside its window (T1 inverted); a text bar docked on a Drawings
   Maker does nothing (X1); a floating text bar still acts inside a Maker wearing its own bar (R5); a
   creator docked on a nested Maker places into it (C3); a creator docked on a host that takes nothing
   does nothing while its drag still works; a MIXED bar (a property tool and a paint tool added to one
   toolbar) keeps both looks current.
3. The suite's failing set must EQUAL M1b's predicted set. Re-author each predicted test to say what it
   means (most will want a floating bar, or the selection inside the host); update
   `src/macros/MACRO-PATTERNS.md` where it teaches "a tool found by class acts on the focus".
4. Gates as P2. Summary + commit message; wait.

#### P3 results (recorded 2026-11-17, on Fizzygum `8e4393c6` and tests `f90f0741e`)

**Property tools (§6.3), as built.**
- P1's door takes the host: `WorldWdgt.editableEditorFocus(hostWindow)`.
  - With no host it gives today's answer.
  - With a host it answers the focus only when `hostWindow.contents` is the focus or an ancestor of it (the
    window's content reach; a band is not content). Otherwise it answers undefined.
  - The view-mode refusal still comes first.
- `editorStyleSubject(hostWindow)` passes the host on. `WorldWdgt` gains no member, so it stays at 128/128.
- Every property tool asks through `EditorContentPropertyChangerButtonWdgt._styleSubject`, which now passes
  `ToolbarWdgt.hostWindowOf @`.
- The two direct readers go through the same door: `AlignButtonWdgt.activated`'s fallback, and
  `TextToolbarWdgt.currentFontName` (with its own `hostWindow()`). `currentFontName` stays on the text bar,
  because it is the font menu's reflected reader.

**Creators (§6.4), as built.** `CreatorWdgt.activated` asks `ToolbarWdgt.hostWindowOf @` and then takes one of
two paths:
- `_placeIntoMyHost(host)`: it places into `host.contents` when that content `acceptsSmartPlacedWidgets`, and
  otherwise makes nothing. This is decided before `createWidgetToBeHandled`, since a refused copy tells the
  person why.
- `_placeForThePerson()`: the old body, verbatim.

The lid inherits it. `ToolbarCreatorButtonWdgt` and `TemplatesButtonWdgt` are untouched (D6).

**The refresh (§6.5), as built.**
- The verb is renamed `noteToolHolderChanged` → `ToolbarWdgt.noteToolStatesChanged`. It is now told when the
  selection, its style or its mode moves, not only when a holder changes, and the new name parallels the cell's
  `noteItemStateChanged`. No test or rig named the old verb.
- It tells every cell and then announces the toolbar itself (`markNonValueChange @`), which the font menu's
  ticks reflect.
- `ToolbarWdgt._subscribeToWhatMyToolsShow` makes both edges, `world → me` and `world.user → me`.
  - Each edge is guarded by `hasEdge`, and the method ends with a refresh.
  - It is called from `_buildAndConnectChildrenNoSettle`, `_afterDeserialization` and `_reactToBeingCopied`
    (the last two on `ToolbarWdgt`, after `super`).
- `noteDockedOn` / `noteUndockedFrom` now refresh EVERY toolbar, because a text bar that docks or leaves changes
  who it works for. The D3 transfer inside them stays guarded by `holdsDrawingTools`, byte-identical.
- `TextToolbarWdgt` loses `_followTheEditedText`, `mirrorTheEditedText` and its three hooks. It keeps
  `dockSide: 'top'`, `currentFontName` and its items.
- `PaintToolbarWdgt` loses `_subscribeToTheArmedDrawingTool` and its three hooks. It keeps its tool fields,
  stock sources and items.
- Every toolbar, creator-only ones included, now holds two edges and refreshes its cells on every focus move.
  This is accepted in §6.5.

**Measured on the build** (acceptance probe `Fizzygum-tests/.scratch/p3/p3-accept.js`, gitignored, real CDP
input, no plant): 46 of 46 checks pass under mouse and 46 of 46 under finger.
- T1 inverted, X1 and R5 each hold.
- The font menu reader holds, as does the align fallback across windows.
- C3 holds: a text box created on a nested Slides Maker's own bar lands in its content, and D's stack and the
  world are unchanged.
- A creator docked on a Drawings Maker makes nothing (`createWidgetToBeHandled` is never called), with a Slides
  Maker front-most.
- A floating creator is unchanged.
- The mixed bar holds: a creator-only bar given Bold and brush is refreshed by a focus move and by a hand tap,
  and both cells hold their active tool.
- Edges: every toolbar has both; a copy has both; a destroyed bar has neither.
- A text bar's undock and re-dock each refresh it.

**Tests.**
- Three new tests, each with one screenshot at dpr 1 and 2, mouse and finger. The finger references are
  byte-identical to the mouse ones.
  - `SystemTest_macroDockedTextBarActsOnlyInItsWindow` (22 assertions) covers three rulings.
    - T1 inverted: Bold on Docs A's bar with the caret in Docs B is delivered, leaves B's weight alone and
      shows inactive. The control press with the caret in A bolds A.
    - X1: a text bar docked on a Drawings Maker by a real drag-embed does nothing.
    - R5: a floating bar bolds a paragraph of a Docs Maker that wears its own bar.
  - `SystemTest_macroDockedCreatorPlacesOnlyIntoItsHost` (14) covers two cases.
    - C3: a Slides Maker is dwell-embedded into a Docs Maker. Its own bar's text-box creator places into it,
      and D's stack and the desktop stay unchanged.
    - A Slides bar dock-embedded on a Drawings Maker makes no text anywhere, with a Slides Maker front-most
      that would take one. A drag of the same creator still lands a text on the desktop.
  - `SystemTest_macroMixedToolbarKeepsEveryLookCurrent` (12) covers R6. A floating creators-only bar
    (`WindowsToolbarWdgt`) is given Bold and a brush tool, its overflow menu is pinned, and the focus and the
    hand are moved from outside it. Its Bold and Brush rows tick and untick with each change.
    - Those rows re-read only when their cell is told, so they read the refresh itself; a cell's look alone is
      read at paint time.
- Every press that must do nothing is shown delivered by the one value only it changes: it brings its
  toolbar's window to the front.
- Each test bites under both pointers through `--prelude=` (`Fizzygum-tests/.scratch/p3-tests/`):
  - property tools ignoring the host fail the first test at T1 inverted and at X1;
  - §11 item 5's rejected alternative (a floating bar refusing a focus inside a window that wears a bar) fails
    it at R5;
  - the pre-P3 creator search fails the second at C3 and at "nothing placed";
  - the pre-P3 per-class refresh (only a text bar hears the world, only a palette the person) fails the third
    at the focus move and at the hand move.
- Each test's follower (`run-sequence-headless.js <new> SystemTest_macroAnalogClockInspectEdit`) runs clean on
  both pointers, with no `WORLD_INVENTORY_` line.
- No existing test was re-authored. M1b predicted that none fails, and none did.
- `src/macros/MACRO-PATTERNS.md` now teaches that a tool acts on the focus only within the window its toolbar
  works for.

**Found on the way (not P3's).** A paint tool's miniature in a toolbar overflow menu's row draws as a stray
stroke: Pencil, Brush and Eraser do this, while Toothpaste draws whole. It is visible in
`macroPinnedMenuTicksFollowTheirState`'s reference since 2026-11-04 and in the new mixed-bar test's. Filed.

**Gates.**
- `fg presuite` passed after the source change (394 of 394) and with the new tests (397 of 397). Each run was
  paint-truthful, and no existing reference changed.
- The finger suite at dpr 1 passed: 379 of 379, then 382 of 382.
- M1b's prediction holds: no existing test changed, and no ceiling or allowlist moved.
- `fg gauntlet` passed all 20 legs with no retry (1325 s).
- Ledger: U1 (the source) and T (the tests) each landed with 0 bounces.

### P4 — dimming

1. Build the look options as a LOCAL HTML page and open it for the owner (the owner's standing
   preference for visual reviews); land the chosen one behind the cell's look derivation (§6.6).
2. `fg presuite` → the changed shots must equal M1c's predicted set → `fg diffpage` over a sample chosen
   with the owner → **owner checkpoint** → build → `fg recapture --auto --dprs=1,2`, then
   `fg recapture --auto --pointer=finger --dprs=1,2`.
3. `fg gauntlet`. Summary + commit message; wait.

#### P4 rulings (2026-11-17, the owner's look checkpoint)

The preview (`Fizzygum-tests/.scratch/p4-preview/`, the real build painting real toolbars) showed four looks:
faded to 50%, 35% and 20%, and the glyph re-inked grey. The owner rejected the 50% fade and left the pick among the
rest to architecture, code elegance and uniformity. The rulings:

- **Creators are never dimmed** (owner). A creator docked on a host that takes no placed widget keeps its
  look; its click still makes nothing (§6.4), and its drag works as before. So only PROPERTY tools ever dim.
- **The look: the glyph re-inked in `disabledText`**, through a new `Theme` role (`toolbarGlyphDimmed`).
  Every property tool is a one-ink glyph in `toolbarGlyph`. An icon already reads its ink from its widget's
  state at paint (`IconAppearance._iconColorString` → `_fillForMyState`; `IconButtonWdgt` is the precedent),
  so the dimmed look needs no new paint mechanism. Its ink is the one disabled buttons already use
  (`buttonDisabledText`). A fade would need an opacity path for one family; it earned its place only while
  full-colour creators could dim.
- **A dimmed cell shows no hover, pressed or active fill.** Every disabled control drops its hover and pressed look:
  `SimpleButtonWdgt`, `ChipWdgt` and `LabelledToggleWdgt`. The owner was unsure, so this follows that
  precedent; its tooltip still shows.
- **The cell derives the look.** The tool answers whether it has something to act on; the cell it stands in
  answers whether it holds a tool with nothing to act on; the tool's ink asks that cell. A tool in no cell
  (the detached copy an overflow row photographs) wears the plain ink.
- **A dimmed tool refuses its press in ONE place:** the family's `activated`, which every tap and every
  overflow row's `triggerToolFromMenu` reaches. Subclasses name their verb once (`_offersMyVerb`) and act
  through `_actOn`. The base resolves the subject, refuses when nothing offers the verb, and answers
  `hasSomethingToActOn`. `TemplatesButtonWdgt` is subject-less (D6): it keeps its own `activated` and always
  has something to act on.
- **Overflow rows are not dimmed in P4.** A row's picture wears the plain ink, and its tap is refused by the
  tool. Menu rows have no disabled look today; filed in BACKLOG.
- **The refusal holds wherever the tool stands** (owner, option A, after the first presuite). A property tool
  in no cell refuses a press with nothing to act on, though no cell shows it dimmed. Only the font tool
  behaves differently there: its act is a menu, which it used to open with nothing selected. The
  alternative kept "refused exactly while shown dimmed" true outside a toolbar too, at the price of a
  second rule (an act that needs no subject in hand). No product path puts a property tool outside a
  toolbar. `macroFontMenuOpensAtVisualPositionInScrolledPane` builds one bare, so its fixture selects a text
  before the click. Its subject, the pop-up's position, is unchanged; its menu shot gains the tick of that
  text's font.
- **The measured set.** The first presuite failed 17 tests. That is P0's model re-run over today's suite
  (16 tests, 30 shots: M1c's 12 plus `macroDockedCreatorPlacesOnlyIntoItsHost`,
  `macroDockedTextBarActsOnlyInItsWindow`, `macroDrawingToolReachesEveryDrawingOfItsHolder` and
  `macroViewModeTextRefusesFloatingBold`, added in P1–P3), plus the font-menu test above. The instrument
  is `Fizzygum-tests/.scratch/p4/` (`m1-observe-prelude-p4.js`, `forecast.js`).

#### P4 results (2026-11-17)

**As built.**
- `EditorContentPropertyChangerButtonWdgt` gives the family one contract:
  - a `verb` named once per tool, as data;
  - `_subjectOfferingMyVerb` and `hasSomethingToActOn`;
  - `activated`, the one refusal;
  - `actOn`, the act. It is public because it calls the subject's self-settling setters, which the
    `_`-tier may not (check-layering [A]), so it is allowlisted for call-separation [U] beside
    `createWidgetToBeHandled`.
- `AlignButtonWdgt` folds its second subject, a stack element's layout spec, into that contract
  (`alignDirectMethod` became the family's `verb`).
- `GlassBoxBottomWdgt.holdsToolWithNothingToActOn` drives the cell's fill and the tool's ink.
  `_fillForMyState` on the family answers `toolbarGlyph` or `toolbarGlyphDimmed`, and the family's
  appearances take no own colour.
- `IconAppearance._iconColor` holds the ink precedence, which `TypedFaceIconAppearance.livePictureOn` shares.

**Tests.**
- `macroDimmedToolsWakeWithTheirSubject` (both pointers): 3 shots, 23 assertions.
- `macroDimmedToolCellStaysDarkUnderThePointer` (mouse only): 2 shots.
- Each test fails under its plant (`Fizzygum-tests/.scratch/p4-tests/`): no dimming, a dimmed cell that lights,
  the font refusal removed. Each leaves the world clean for a follower.
- The acceptance probe `.scratch/p4/p4-accept.js` passes 46 of 46 (mouse) and 42 of 42 (finger).

**Measured.**
- The presuite's failing set is the forecast exactly: 17 tests at dpr 1, and the same 17 under the finger,
  each a screenshot mismatch only.
- The owner reviewed the diff page (31 shots) and approved the recapture.
- `fg recapture --auto --dprs=1,2`, then the same with `--pointer=finger`: both RECAPTURE COMPLETE.

**Found on the way.**
- The menu sweep's overflow root pressed the font row with nothing focused. It now focuses the narrow
  Maker's paragraph first, so the row still opens Fonts.
- A 90-wide Docs Maker clips its docked bar's overflow chevron to ~19 px (filed in BACKLOG).
- During a playing test a tooltip appears at once, not after its 500 ms. The hover test clears tooltips
  before each shot.

**Gates.** `fg gauntlet` passed all 20 legs with no retry (1289 s): dpr 1, dpr 2 and WebKit 399 of 399, finger 383 of
383, menu sweep OK, paint-truthful, every audit gate clean. Ledger: U1 (the source) and T (the tests) each landed with 0
bounces; the first presuite STOPPED on the one test outside the forecast, and the owner ruled (option A).

### P5 — docs and close

1. A present-tense reference for the subsystem: `docs/architecture/toolbars.md` (construction, the
   strong sense of docked, who a tool works for per kind, the holders, the refresh, how to write a
   tool), linked from `Fizzygum/CLAUDE.md`'s architecture list (mind that file's byte ceiling) and from
   `widget-authoring-guidelines.md`.
2. Rewrite the class headers that state the old model: `User.coffee`, `PaintToolbarWdgt`,
   `TextToolbarWdgt`, `ToolbarWdgt`, `CodeInjectingSimpleRectangularButtonWdgt`, `CanvasGlassTopWdgt`,
   `ImageWdgt`, `CreatorWdgt`, `EditorContentPropertyChangerButtonWdgt`. Check `InfoDocs.coffee` for
   user-facing text describing palettes.
3. `docs/architecture/serialization-duplication-reference.md`: the `users` section.
4. `git mv` this plan to `docs/archive/`, stamp it, add its `INDEX.md` line, move its BACKLOG lines into
   a `## BACKLOG ledger` section here (README rule 2), and file anything left open.

---

## 9. Verification protocol

All through the wrapper, by absolute path, from any directory:

- Inner loop: `fg presuite` (build + dpr-1 suite + paint audit + dpr-2 rider).
- Finger, dpr 1 (from `Fizzygum-tests/`): `node scripts/run-all-headless.js --pointer=finger`.
- One test: `node scripts/run-macro-test-headless.js SystemTest_<name> [--dpr=2] [--pointer=finger]`.
- A new test's references: `node scripts/capture-macro-test-references.js <name> --dprs=1,2`, then the
  same with `--pointer=finger`. Build first if any build input changed.
- A new test leaves the world as it found it — prove it with a FOLLOWER, on both pointers:
  `node scripts/run-sequence-headless.js SystemTest_<new> SystemTest_<any>`, zero `WORLD_INVENTORY_` lines.
- Prove each new test BITES: put the bug back through `--prelude=` and watch that test fail.
- Pictures of a failure: `fg diffpage <test>`.
- Commit point: `fg gauntlet`, launched once in the background with its output in a log.
- The probes of §3, rebuilt, are the end-to-end check that the reported steps now behave as R1–R5 say.

## 10. What is out of scope

- A world-level tool object or a new tool-head widget (the July arc's falsified D-2).
- Per-window focus memory (a window remembering its own last selection).
- Restricting what may dock where (ruling C12 stands).
- Multi-user input attribution.
- Renaming `CodeInjectingSimpleRectangularButtonWdgt`.

## 11. Rejected alternatives — do not re-attempt blind

1. **Keep the push; re-push when the focus changes.** The focus is written at the release (§1.2), so the
   first stroke on a newly clicked drawing is still wrong; the hover preview is stale; a drawing with no
   palette anywhere is never told; view mode stays open.
2. **Everything follows the hand** (the August model, completed). Planted and correct, but it forbids
   two drawings holding different tools, which R1 asks for.
3. **A tool per drawing, each palette mirroring the drawing clicked last** (the text model applied to
   paint). The highlight lags the first stroke after switching drawings, for the reason in §4.1.
4. **The surface SUBSCRIBES and re-derives on announcements.** This is the planted variant of §3.1. It is
   correct while the hand is the only holder. Under R1–R5 it needs an invalidation at every event of §5
   item 1, a drawing's nesting changing among them, with no existing hook. Fallback only, and only if S1
   falsifies §6.2.
5. **"A floating toolbar reaches only content that wears no toolbar", for property tools.** A floating
   text bar would refuse a paragraph in a Docs Maker. R5 confines the exclusion to modes.
6. **A docked toolbar falls back to floating behaviour when its host has nothing for it.** Proposed in
   this session and withdrawn on the owner's ruling R2: one rule, no exception.
7. **A window's tool follows the hand until its first tap** (copy on write). Two drawings then differ in
   whether they follow, by a history nobody can see.
8. **A click on a creator stamps into a drawing.** It would stamp an unedited placeholder; on the desktop
   the item can be edited, then dragged in.
9. **Inject the tool members onto a holder object whose prototype is the glass.** `@_changed()` and
   every field write would land on the holder, not the widget.

## 12. References

- `docs/archive/onion-widget-composition-plan.md` §5.C, §5.D (D10–D14, D-2-i…ii).
- `docs/archive/command-panel-unification-plan.md`, P4 and the OD3 owner direction.
- `docs/archive/frames-input-touch-program.md` (the program rulings table: C11 a toolbar is a payload, C12
  docked = a nested frame under a host-owned edge spec) and `docs/archive/frame-lifetime-and-docking-plan.md`
  (the bands as built).
- `docs/archive/focus-and-selection-plan.md` (the editor focus; D11 there is a different D11).
- `docs/architecture/widget-authoring-guidelines.md`, `lint-and-static-checks.md`,
  `serialization-duplication-reference.md`, `input-and-gestures.md`, `visual-design-system.md`.
- `src/macros/CLAUDE.md`, `src/macros/MACRO-PATTERNS.md`, `src/dataflow/CLAUDE.md`,
  `src/serialization/CLAUDE.md`; `Fizzygum-tests/CLAUDE.md`, `Fizzygum-tests/DETERMINISM.md`.
- Session memory note `paint-tool-stale-surface` (the investigation and the rulings as they were made).

## BACKLOG detail

### A text menu pinned in edit mode keeps its editing rows after a flip to view mode

A text's own menu leaves out its editing rows when the text sits in view-mode content
(`StringWdgt._addTextMenuEntries` asks `Widget.sitsInViewModeContent`; P1 results). It asks once, though: a menu is
built when it opens. So a text menu opened while its content was in edit mode, and then PINNED, keeps Bold, Italic,
Font, Font size…, Edit… and the alignment rows after the window is turned to view mode, and those rows still act.
The editing tools do not have this gap, because the mode flip is announced to them (`WorldWdgt.noteEditModeChanged`).

A person reaches it with a gesture: open the paragraph's menu, pin it, press the window's pencil, then choose Bold.
Two fixes are possible:
- the setters refuse in view-mode content; mind construction-time styling, which happens before a document is turned
  to view mode;
- a pinned text menu rebuilds or hides its editing rows when told of the flip.

Low severity.

### Choosing a context-menu row takes the editor focus, and closing the menu clears it

Found in P1 while extending `SystemTest_macroViewModeTextRefusesFloatingBold` with the text-menu door, and measured
with a focus-write trace (`Fizzygum-tests/.scratch/p1-tests/focus-trace-prelude.js`). The paragraph is selected; a
right-click opens the hierarchy menu, and the press on its "Text" row runs `_setEditorFocusNoSettle` with the
`MenuItemWdgt` from `ActivePointerWdgt.processPointerUp`. When the menus close, `MenuItemWdgt._destroyNoSettle`
clears the focus to undefined. So after using a widget's context menu, the paragraph that was selected is not, and
the text tools have nothing to act on until it is clicked again.

The cause: an ordinary menu is not editor chrome (`MenuWdgt.excludedFromEditorFocusTracking` answers
`@actsAsEditorChrome`, false by default), so a press in it is tracked like a press in content. To decide: whether every
pop-up menu is editor chrome for focus purposes (a press in it neither steals nor clears the selection), which is what
the toolbars already are.

### A sheet inside a view-mode document still takes typed entries

Found by P1's research and measured on the build: a Sheets Maker carried into a Docs Maker that is then turned to
view mode still accepts typing. A click on a cell, then "42" and Enter, stored A1 = 42.

R8 refuses restyling, so the sheet's style tools are refused there (P1 results), but the sheet's own key path
(`SimpleSpreadsheetWdgt.processKeyDown`, which acts while the sheet is the editor focus) asks no mode. A sheet in its
own window has no view mode at all, so the question only arises when it sits inside content that has one. The fix is
the content asking the same question as the text menu above.

## BACKLOG ledger

- [x] P0: spike S1 (the paint mechanism, planted) and measurement M1 (test fallout); decisions D1–D8 were ratified 2026-11-16 (§4.2) — CLOSED 2026-11-16: S1 passed every row; M1a and M1b empty; M1c 26 shots in 12 tests (§8 "P0 results"), Fizzygum `6b4c0d65`
- [x] P1: content in view mode refuses restyling from any toolbar; a drawing takes no click-placed widget (rulings R8, R9) — CLOSED 2026-11-16: `WorldWdgt.editableEditorFocus` and `StretchableCanvasWdgt.stampsDroppedWidgets`, two new tests (§8 "P1 results")
- [x] P2: a drawing paints with the previous tool while every palette shows the new one — the surface takes up its tool at use, windows hold their own (§6.2) — CLOSED 2026-11-17: `CanvasGlassTopWdgt._takeUpToolInReach`, `FrameWdgt.armedDrawingTool`, the D3 transfers on `ToolbarWdgt`, D2's table on `User` and its save, three new tests (§8 "P2 results")
- [x] OWNER CHECKPOINT after P2: dock and undock palettes by hand and rule on D3 — CLOSED 2026-11-17: the owner approved D3 as built, with the three behaviours §8 "P2 results" lists
- [x] P3: a toolbar docked on one window acts on another's selection; a creator docked on a nested Maker places outside it (§6.3–§6.5) — CLOSED 2026-11-17: `WorldWdgt.editableEditorFocus(hostWindow)`, `CreatorWdgt._placeIntoMyHost`, the refresh and its two edges on `ToolbarWdgt` (`noteToolStatesChanged`), three new tests (§8 "P3 results")
- [x] P4: tools with nothing to act on show dimmed (D5, §6.6) — CLOSED 2026-11-17: the property tools' one contract (`verb`, `_subjectOfferingMyVerb`, `hasSomethingToActOn`, the refusal in `activated`), `GlassBoxBottomWdgt.holdsToolWithNothingToActOn`, `toolbarGlyphDimmed`, two new tests, 17 tests recaptured (§8 "P4 rulings", "P4 results")
- [x] "Don't save" leaks the closed window's whole subtree (found in P2) — CLOSED 2026-11-17 in P2: `SaveShortcutPromptWdgt`'s button dispatches `fullDestroy`
- [x] A text's own menu restyles it in view mode (found in P1) — CLOSED 2026-11-16 in P1: `StringWdgt._addTextMenuEntries` and `TextWdgt`'s "Soft wrap" row ask `Widget.sitsInViewModeContent` and offer no editing row in view-mode content; V1 asserts it (§8 "P1 results")

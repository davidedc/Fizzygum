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
| P0 | Spike S1 (the paint mechanism, planted); measure M1 (test fallout). D1–D8 are already ratified | not started |
| P1 | Content-side bugs: view-mode content refuses restyling; a drawing takes no click-placed widget | not started |
| P2 | The seam + paint: the surface takes up its tool at use; windows hold their own tool | not started |
| — | OWNER CHECKPOINT: dock / undock by hand, judge the feel (D3) | — |
| P3 | Text tools and creators onto the seam; the refresh moves to `ToolbarWdgt`; mixed bars | not started |
| P4 | Tools with nothing to act on show dimmed (D5) | not started |
| — | OWNER CHECKPOINT: the owner picks the dimmed look, then sees the diff page before P4's recapture | — |
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
  never by a class test. A tool standing in no toolbar works for the person. Give this ONE home that all
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
  hands over no subject.
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
   under both pointers.

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

### P1 — content-side bugs (independent of the rest)

1. R8: the view-mode refusal, at the one query (§6.3 describes where it ends up; in P1 it guards
   today's `editorStyleSubject` and the align fallback). Find how "this content is in view mode" is asked
   for a focused widget: which ancestor holds the mode, for a paragraph in a document, a text box in a
   slide, a cell of a sheet, a text on the bare desktop (which has no mode and stays editable).
2. R9: the drawing declines placement (§6.4).
3. Tests: one macro each. V1's scenario with the paragraph's weight asserted unchanged; C2's scenario
   with the new widget asserted a child of the world, plus the drag asserted to stamp as it does today.
4. Gates: `fg presuite`; the finger suite; `fg gauntlet`. Then summary + commit message; wait.

### P2 — the seam and paint

1. §6.1, then §6.2 in this order: the surface's entries and take-up → the holder pair on `FrameWdgt` →
   the palette tool answering its own press → the transfers → D2's table and the save → the deletions.
   Build after each; the syntax gate runs on every build.
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
   metadata prose where it describes the old mechanism.
5. Gates: `fg presuite`; the finger suite; `fg gauntlet` (its `serialization`, `menusweep`, `pinsweep`,
   `vmtruth` and `storage` legs all touch this change). Expected pixel change: none outside the tests
   above; explain any other.
6. Summary + commit message; wait. **Then the owner checkpoint:** the owner docks and undocks palettes by
   hand and rules on D3.

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

### P4 — dimming

1. Build the look options as a LOCAL HTML page and open it for the owner (the owner's standing
   preference for visual reviews); land the chosen one behind the cell's look derivation (§6.6).
2. `fg presuite` → the changed shots must equal M1c's predicted set → `fg diffpage` over a sample chosen
   with the owner → **owner checkpoint** → build → `fg recapture --auto --dprs=1,2`, then
   `fg recapture --auto --pointer=finger --dprs=1,2`.
3. `fg gauntlet`. Summary + commit message; wait.

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

## BACKLOG ledger

(empty until items close — README rule 2)

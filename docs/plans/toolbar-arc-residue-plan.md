# The toolbar arc's residue — eight open items, fixed in one overnight loop

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
AUTHORED 2026-11-17 against Fizzygum master `2f4e8d98` and Fizzygum-tests master `732841f9f` (400 SystemTests,
build FRESH). Executed by an UNATTENDED overnight loop whose process (the per-unit cycle, the grants, park and stop
rules, the LEDGER) is `Fizzygum-tests/.scratch/overnight-toolbar-residue/BRIEF.md`. This document is the WHAT: each
unit's facts, ruled design, tests, predicted pixel set and proof.

**Mandate: eliminate each defect at its cause.** Every unit below names the mechanism that is wrong and replaces it;
none hides a symptom. Where two items share a cause, one change serves both (U5, U6+U7).

Status:

| Unit | Item (BACKLOG title, abridged) | Status |
|---|---|---|
| U1 | Home and End leave the caret wrong in a multi-line text | LANDED 2026-11-17 |
| U2 | A paint tool's miniature in a toolbar overflow menu's row draws as a stray stroke | not started |
| U3 | Choosing a context-menu row takes the editor focus, and closing the menu clears it | not started |
| U4 | A narrow Docs Maker's docked toolbar clips its overflow chevron | not started |
| U5 | A sheet inside a view-mode document still takes typed entries; a drawing standing bare in a view-mode document still takes paint | not started |
| U6 | A dimmed tool's row in a toolbar overflow menu does not look dimmed | not started |
| U7 | A text menu pinned in edit mode keeps its editing rows after a flip to view mode | not started |
| U8 | Close: this plan archived, or left open with what parked | not started |

---

## 0. Orientation

**Fizzygum** is a CoffeeScript GUI framework rendered on one `<canvas>`: windows, a desktop, drag and drop, live
editing tools. Three sibling repos under a directory named `Fizzygum-all`: `Fizzygum/` (source + build),
`Fizzygum-tests/` (the macro SystemTest suite and its Node rigs), `Fizzygum-builds/` (generated). Read
`Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md` first; both route to deeper docs.

**The prior arc.** `docs/archive/docked-and-floating-toolbars-plan.md` (CLOSED 2026-11-17) stated who a toolbar's tool
works for; its living truth is `docs/architecture/toolbars.md`. It left eight open items in `docs/BACKLOG.md` under its
section; three have full text in that plan's `## BACKLOG detail`. This plan fixes all eight.

**Research.** Four read-only research passes (2026-11-17) reproduced every item on the build, root-caused each, and
checked each recommended fix by planting it in the page. Their reports and probes are under
`Fizzygum-tests/.scratch/overnight-toolbar-residue/research/` (gitignored, on this machine):
- `A-homeend-B-miniature.md` (U1, U2), with probes and plants in `A/`, `B/`;
- `E-menufocus-gripfloor.md` (U3, U4), with `E-menufocus-forecast-prelude.js`, `E-menuchrome-patch-prelude.js`,
  `E-probe.js`;
- `C-viewmode-sheet-drawing.md` (U5), with `C-probe.js`, `C-probe-forward.out`;
- `D-disabled-menu-rows.md` (U6, U7), with `d-forecast.js`.
Each unit below cites its report's sections. **The report is the authority for code shapes, file:line and probes;
re-grep every symbol before editing (lines drift).** Where a unit below rules differently from its report, this plan
wins.

> **THE CRITICAL REFRAMES (what research overturned).**
> - U2: "Toothpaste draws whole" is false. Every paint tool's row picture is a CROP, because the row photographs the
>   tool's copy after resizing it without re-laying its children. Toothpaste's crop just happens to look like a tool.
> - U5: the obvious rule, "view mode wherever ANY enclosing holder is in view mode", is WRONG. It makes the content of
>   an edit-mode Maker nested in a view-mode one refuse editing, which reverses measured P1 behaviour. The right rule
>   is window-bounded inheritance (§U5).
> - U7: the pinned menu is not the gap. Nothing tells a row that reflects a text about a mode flip, because
>   `WorldWdgt.noteEditModeChanged` announces only flips above the editor focus.

## 0.5 Cold-execution protocol

1. The loop's process is `BRIEF.md` (beside the research dir). Read it whole before this plan's units.
2. `/Users/davidedellacasa/code/Fizzygum-all/fg status` (by absolute path, never `./fg`): both repos clean and level
   with origin, build FRESH.
3. Units run in the table's order (§U-order explains why). A PARKED unit does not stop the loop; a unit that needs a
   parked one waits on it.
4. Per unit: read its section here, then its report sections, then the code. Re-verify every fact a step relies on.
5. Commands: `fg build`, `fg presuite`, the finger suite (`node scripts/run-all-headless.js --pointer=finger` from
   `Fizzygum-tests/`), `fg diffpage`, `fg recapture --auto --dprs=1,2` (then `--pointer=finger`), `fg gauntlet`.
   Long ops run ONCE in the background with a log, never piped through a filter.

## 1. Rulings

**Owner (2026-11-17), verbatim in substance:**
- **#3 (U7):** a pinned text menu's editing rows grey out and refuse their press in view mode, like the toolbars' tools
  dim. It shares its mechanism with #7.
- **#4 (U3):** every pop-up menu is editor chrome: pressing it neither takes nor clears the selection. A prompt with a
  field the person types into still takes the focus.
- **#7 (U6):** a dimmed tool's overflow row looks disabled; "a reasonable look that is cohesive from both the UX and
  code / architecture standpoint".
- **#8 (U4):** NOT a general minimum size; Fizzygum's tradition is that any widget can be FORCED to any size. Only a
  PERSON's drag of a FREE-FLOATING window's resize grip stops at the narrowest extent keeping its docked bars' overflow
  chevron usable. That floor is worked out from the bars, per bar axis, through the existing
  `HandleWdgt._extentMyDragAsksOfMyTarget` seam (the `FrameGripWdgt` collapsed-bar precedent). It is never
  `minimumExtent`, and there is no "no jump" memory of the width at grab.
- **Grants and pixel policy for the loop:** see BRIEF.md.

**Ruled by the planning session from the owner's principles** (clean, minimal, uniform; ONE of each thing; derived
over pushed; reuse the existing mechanism). The loop lists them in the LEDGER digest under "Rulings for your second
look":
- U1: Home and End also set the caret's remembered column (`rememberCaretColumn`), as every horizontal move does.
- U2: a tool's row picture includes its edit mark, because the row stands for the tool as its cell shows it.
- U3 (report D-E4-a): the WHOLE menu is chrome, not only its rows. So a pinned menu dropped into a panel is no longer
  selected.
- U3 (report D-E4-b, and "Delete" exposed by the ruling): instead of a close hook, the door
  `WorldWdgt.editableEditorFocus` hands over nothing while the focus is not on any screen or not visible. It asks the
  ONE existing question for that, `surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage` (verify its body:
  visibility, collapsed subtree, orphanage; a widget the hand carries is no orphan). That covers a paragraph filed to
  the bin by "Delete" and one hidden by "Hide", with no hook, and does not dim tools mid-drag.
- U4 (D-E8-a): each band floors BOTH axes. Its run axis takes the chevron's one-slot run; the cross axis takes the
  host's chrome. Otherwise a Docs Maker reaches 125×20 with its band outside the window.
- U4 (D-E8-c): the run is the grid's own one-slot run (60 px measured), never a constant.
- U4 (D-E8-b): the window's own title strip clipping its edit toggle below ~175 px is out of scope (it exists today and
  is not a docked bar). FILE it in BACKLOG under this plan's section.
- U5: rule B, window-bounded inheritance. A mid-edit flip's commit is refused (no hook on the flip). Enter in a
  view-mode sheet does nothing; arrows and Tab still move the selection; zoom stays allowed. The Degrees Converter's
  formula boxes stop accepting restyling (R8 applied; typing still works).
- U6/U7 (report §10): a disabled row keeps its tick, greyed. A disabled submenu row's chevron is greyed. A tap on a
  disabled row leaves even an unpinned menu open. Item 3 covers the text's Fonts submenu and "Soft wrap". A menu
  OPENED in view mode still leaves its editing rows out, as today. The copied-menu edge gap is fixed in U6. The new
  concept's names are the report's §8 (`isDisabled`, `enablement`, `MenuRowReflectionSpec.enabledWhile`), never
  "dimmed" (`CommandSpec.dimmed` means something else) and never a method named `isEnabled` (a field of that name
  exists on `SimpleButtonWdgt`).

## U-order — why this order

U1–U4 are independent, smallest blast radius first. U2 precedes U6, because both touch `InertIconHolderWdgt`'s picture
code. U3 precedes U7: U7's test must establish the focus away from the paragraph, and U3 changes what a menu press does
to the focus. U5 precedes U7, because U7's rows reflect `sitsInViewModeContent`, whose rule U5 changes. U6 builds the
mechanism U7 reuses. U8 last.

---

## U1 — Home and End in a multi-line text (report A, "BUG A")

**Facts (VERIFIED).**
- `TextWdgt.slotRowAndColumn` answers an ARRAY `[row, col]`.
- `TextWdgt.startOfLine` / `endOfLine` read `.y` off it, which is undefined:
  - `startOfLine` answers undefined, and Home sets `world.caret.slot` undefined;
  - `endOfLine` throws a `TypeError`, which the world's input loop catches with `_softResetWorld`, opening the error
    console.
- Every other reader destructures correctly: `TextWdgt` (×4) and `MacroToolkit` `[0]`.
- `StringWdgt`'s single-line pair is correct.
- The only sender is `CaretWdgt.processKeyDown` → `goHome` / `goEnd`.
- **Second defect (VERIFIED):** `goHome` / `goEnd` never call `@target.rememberCaretColumn @slot`, while
  `goLeft` / `goRight` do. The contract comment in `StringWdgt` says every horizontal move sets the column, so after
  Home or End, Up and Down use a stale column.

**Fix.**
- `startOfLine`: `[row] = @slotRowAndColumn slot`; `@wrappedLineSlots[row]`.
- `endOfLine`: `[row] = @slotRowAndColumn slot`; `@wrappedLineSlots[row] + @wrappedLines[row].length - 1`.
- `goHome` / `goEnd`: last line `@target.rememberCaretColumn @slot`.
- `slotRowAndColumn` keeps its array; five readers depend on it.

**Tests.**
- **Existing:** only `macroSpreadsheetFormulaBarEditsAndErrors` presses End, on a single-line field. **Predicted pixel
  set: EMPTY.**
- **New:** `SystemTest_macroHomeAndEndInAMultiLineText`, value-only, both pointers. Shape: report A "Regression test" —
  End/Home/ArrowDown/End slots, Shift+End's selection, and a wrapped-row case after asserting the wrapping. Plants:
  `A/plant-a-homeend-misread.js` and `A/plant-a2-home-forgets-column.js`. Each must fail the new test.

**Docs.** None beyond the plan; no architecture doc states this. Time box 1.5 h.

**Landed 2026-11-17.**
- Built as the fix says:
  - `TextWdgt.startOfLine` / `endOfLine` destructure `[row]`;
  - `CaretWdgt.goHome` / `goEnd` end with `@target.rememberCaretColumn @slot`.
- Test: `SystemTest_macroHomeAndEndInAMultiLineText`, value-only. Every clicked and expected slot is named from the
  text, and every click is followed by the caret slot it placed.
  - A wide text: End, Home, Down after Home, End inside the last line, Up after End, Shift+End.
  - A narrow soft-wrapped text: End stops where the first row wraps; Home stops where the last row starts.
  - A `TextWdgt` scales its font to its box, so the test asserts the wrapped rows before relying on them.
- Bite:
  - `plant-a-homeend-misread` fails it on both pointers: End leaves the caret at 20, Home leaves it undefined, and the
    error console opens.
  - `plant-a2-home-forgets-column` fails it on both: Down after Home lands at 43, not 38; Up after End lands at 7,
    not 15.
- Followers: clean on both pointers.
- Prediction met: the presuite failed nothing (401 tests), and so did the finger suite; no reference changed.
- Filed from the review, under this plan's BACKLOG section:
  - the caret's remembered column, which some caret moves still do not set;
  - no keyboard way to a line's ends on a keyboard without Home and End.
- Commits: one per repo, each titled "Text: Home and End …".

## U2 — The overflow row's picture of a tool with children (report A, "BUG B")

**Facts (VERIFIED).**
- `OverflowChevronButtonWdgt._miniatureOf` copies the tool and builds `new InertIconHolderWdgt picture, fitInto: 24×24`.
- `InertIconHolderWdgt._takePictureOf` resizes the copy with `_applyExtent` and photographs it at once.
- For a widget with children, `Widget._applyExtent` only SCHEDULES the children's re-layout; the synchronous re-layout
  was retired in `b99eec6d`. So the 44×44 icon stays 44×44 and the photo is its top-left 24×24 crop.
- The comment at `_takePictureOf` claiming the apply re-lays the contents is false.
- Affected: all four paint tools, `SpeechBubbleWdgt` (Slides and Dashboards bars), and a bare brush button.

**Fix.**
- In the `InertIconHolderWdgt` constructor: when the pictured widget has children,
  `widgetToPicture.setExtent @_extentFitting widgetToPicture, opts.fitInto` before `@_takePictureOf`. It must be the
  constructor: check-layering [A] forbids `setExtent` in a `_`-method.
- Rewrite the false comment.
- Rejected: calling `_reLayout` by hand; another widget's `_settleLayoutsAfter`; picturing only the icon.

**Tests.**
- **Predicted pixel set (the fix's own target):** `macroPinnedMenuTicksFollowTheirState` image_1 (the four paint rows)
  and `macroMixedToolbarKeepsEveryLookCurrent` image_1 (the Brush row). Each at dpr 1 and 2 × mouse and finger: 8
  reference files. The diff must show whole tool pictures replacing crops, nothing else.
- **New:** `SystemTest_macroOverflowRowPicturesTheWholeTool`, value assertions from report A's table:
  - the row picture equals the picture of the plain icon at 24 px;
  - it is independent of the tool's earlier size;
  - every ink pixel of the plain icon is inked in the row.

  Read pixels as `macroIslandBufferCacheByteIdentity` does. Destroy every holder, copy, menu and window. Plant:
  `B/plant-b-unsettled-picture.js`.
- **Risk:** the extra re-layout per row on the `revisits` / `settle` / `capstone` / `vmtruth` legs. The gauntlet
  decides; a new revisit is a FINDING (park, do not baseline).

Time box 2 h.

## U3 — Every menu is editor chrome (report E, item 4)

**Facts (VERIFIED).**
- `MenuWdgt.excludedFromEditorFocusTracking` answers `@actsAsEditorChrome`, false by default. Three menus opt in:
  `ChangeFontButtonWdgt`, `OverflowChevronButtonWdgt`, `SheetFormulaBarWdgt`.
- `MenuWdgt` has no subclasses; all 46 `new MenuWdgt` sites build row menus.
- `PromptWdgt` extends `FrameWdgt`, not `MenuWdgt`, and its typed field takes the focus itself.
- The release (`ActivePointerWdgt.processPointerUp`), the finger hold and the drop write the focus through
  `WorldWdgt._setEditorFocusNoSettle`, honouring the opt-out by ancestry.
- "Closing clears it" is the generic `Widget._destroyNoSettle` clear (the focus must not point at a dying widget). It
  stays live for every widget.

**Fix.**
- `MenuWdgt`: delete the field `actsAsEditorChrome`; answer `excludedFromEditorFocusTracking: -> true`. Comment: every
  menu is chrome, pinned or not; a prompt is no menu, so its field takes the focus.
- Delete the three opt-ins and their justifying comments.
- `WorldWdgt.editableEditorFocus` also returns undefined while
  `focus?.surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage()` (ruling above). Add it beside the
  view-mode line, with the comment saying why ("a paragraph filed to the bin or hidden hands over nothing; a carried one
  still does").
- Fix the comments the change falsifies: report E §4.3 item 4 (`ActivePointerWdgt` ~914–931, `MenuItemWdgt` ~199–205,
  `WorldWdgt` ~1974).
- No ceiling moves.

**Tests.**
- **Predicted pixel set:** MEASURED before the change, not guessed.
  1. On the untouched tree, run the forecast prelude `research/E-menufocus-forecast-prelude.js` (observing only)
     through the whole suite on BOTH pointers: `run-all-headless.js --audit-prelude=… --audit-dir=…`; read its header
     first. Its output is the predicted set.
  2. The partial forecast was 18 shots in 10 tests at dpr 1 under the mouse, each a selection ring that now persists:
     report E §4.4 lists them. The full run supersedes it.
  3. The fix's own target is that every diff is a selection ring or a text tool's lit/dimmed look persisting after a
     menu press, or the ring missing on a dropped pinned menu (`macroSubMenuDroppedIntoPanelPinsItself`).
- **Existing prose to true up:** `macroViewModeTextRefusesFloatingBold` (~L79–86 describes today's behaviour);
  `macroMouseDragScrollOfMenuRowsFiresNoRow`, whose assertions still pass but no longer distinguish scroll from click.
  Strengthen them with a value that does.
- **New:** `SystemTest_macroMenuRowKeepsTheSelection`, both pointers (report E §4.5):
  - the hierarchy row keeps the focus;
  - Bold's row keeps it and lights Bold;
  - a pinned menu's row keeps it;
  - "Font size…"'s field takes the focus;
  - "Delete" leaves a floating Bold dimmed (the door);
  - "Hide" likewise.

  Plants: MenuWdgt answering false; PromptWdgt answering true; the door's new line removed.

**Docs.** `toolbars.md` §1 "Chrome" (every menu is chrome); `widget-authoring-guidelines.md` §9 chrome list.

Time box 3 h.

## U4 — The resize grip stops where docked bars stay usable (report E, item 8)

**Facts (VERIFIED).**
- `HandleWdgt._extentMyDragAsksOfMyTarget` is the seam; `FrameGripWdgt` overrides it for a collapsed bar only
  (`shortestBarKeepingMyGrip`).
- The grip shows only on free-floating frames (`FrameWdgt` `resizer: if @isFreeFloating() then "payloadSized" else
  "none"`), so the floor needs no free-floating test of its own.
- The chevron is a 44 px slot. The grid turns vertical when its box is taller than wide.
- Measured floors: top-band Makers (Docs, Sheets) **125 px wide**; left-band Makers (Drawings, Slides, Dashboards,
  Patch programming) **212 px tall**. At 90 wide the chevron shows 19 px and a press at its centre lands on the window.

**Fix (report E §8.3).**
- `ToolPanelWdgt.shortestUsableRun: -> @_naturalRunFor 1, @_alongPadding()`.
- `ToolbarWdgt.shortestDockedRun: -> @contents.shortestUsableRun()`, the twin of `dockThickness`.
- ONE public `FrameWdgt.smallestExtentKeepingMyBandsUsable`:
  - a Point, or undefined when no engaged, expanded band's payload answers `shortestDockedRun`;
  - a per-side loop;
  - BOTH axes per the ruling.
- `FrameGripWdgt._extentMyDragAsksOfMyTarget`:
  - the collapsed branch stays;
  - otherwise `floor = @target.smallestExtentKeepingMyBandsUsable()`, `return anExtent unless floor?`,
    `anExtent.max floor`.
- **Ceiling:** `FrameWdgt` 171 → 172 in `buildSystem/check-complexity-ratchets.js`, with a dated reason ("2026-11-17
  U4: the grip's band floor, owner ruling #8"). This raise and U5's are the ONLY ratchet raises this plan grants.

**Tests.**
- **Predicted pixel set: EMPTY.** None of the 29 tests that drag a grip takes a band-wearing window below its floor
  (report E §8.4).
- **New:** `SystemTest_macroGripStopsWhereDockedBarsStayUsable`, both pointers:
  - a Docs Maker and a Drawings Maker dragged toward zero stop at their floors (values);
  - the chevron is whole and its press opens its menu;
  - a programmatic `setExtent` to 90 wide is honoured, and a 1 px grip drag then snaps to the floor;
  - view mode has no floor (no engaged band).

  Plants: the grip seam restored; `shortestDockedRun` answering 0.
- **File in BACKLOG** (this plan's section): the title strip's edit toggle clipped below ~175 px.

**Docs.** `FrameGripWdgt` header; `toolbars.md` §1 "Hidden tools" (a person's grip drag stops where every docked bar's
chevron stays whole; code can still force any size); `src/macros/MACRO-PATTERNS.md` resize verbs' floor note.

Time box 2.5 h.

## U5 — View mode reaches every holder inside a window (report C)

**Facts (VERIFIED).**
- `Widget.sitsInViewModeContent` climbs from the parent; the first holder with `providesAmenitiesForEditing is true`
  decides.
- **Sheet (#1):** the climb already answers view mode for a sheet in a view-mode document, but nothing on the sheet's
  paths asks it. Typing, Delete, double-click edit, the formula bar, dropping into a cell, dragging out of a cell, and
  an edit open across the flip all still act (MEASURED).
- **Drawing (#5):** "bare" means a container, canvas and glass with no window, reached by "Pick up" from the context
  menu. The climb stops at the drawing's own canvas: every `PanelWdgt` is a holder by class default, and the
  document's flip reaches only its direct children. So it paints, and stamps drops.
- **Not a world or caret door:** the shipped Degrees Converter types into inputs that sit in view-mode content.

**Fix (report C §4.2, §5).**
- `Widget.sitsInViewModeContent` body replaced: window-bounded inheritance. A window offering its own edit toggle
  answers alone for its content; any other holder in view mode makes everything in it view-only. No new Widget member,
  so no inspector churn.
- New public `FrameWdgt.offersEditToggle`. `_barSpec`'s "edit" piece reads it, so there is ONE definition.
  **Ceiling:** `FrameWdgt` +1, a dated raise (172 → 173 after U4; 171 → 172 if U4 parked).
- Sheet doors, each asking `@sitsInViewModeContent()`:
  - `SimpleSpreadsheetWdgt._startEditNoSettle`;
  - `_commitEditNoSettle`, which tears down without writing;
  - `_clearSelectedCellNoSettle`;
  - `CellWdgt.wantsDropOfChild`;
  - `CellWdgt.wantsDetachOfChild`.
- Drawing: `StretchableCanvasWdgt.wantsDropOfChild: (aWdgt) -> super(aWdgt) and not @sitsInViewModeContent()`.
  `CanvasGlassTopWdgt` needs no change; update its `_sourceOfToolInReach` comment.
- Rejected: the "any ancestor" rule A (reverses P1's nested row and the grip rule; a decision left for the owner to
  revisit); pushed state (it must remember each container's own mode).

**Tests.**
- **Predicted pixel set: EMPTY**, and no existing assertion changes (report C §6.1).
- **Behaviour change (second look):** the Degrees Converter's formula boxes' text menus lose their editing rows and the
  text tools dim on them. Typing still works.
- **New** (report C §6.2), value assertions, both pointers:
  - `SystemTest_macroViewModeSheetRefusesEditing`: every refused entry, plus the edit-mode control;
  - `SystemTest_macroViewModeBareDrawingTakesNoPaint`: no stroke, a drop unstamped, and a nested Drawings Maker with
    its own pencil still paints.

  Plants: report C §6.3.
- **File in BACKLOG** (this plan's section): the selection ring frames a drawing's paint surface after a click in view
  mode (pre-existing, reachable).

**Docs.** `toolbars.md` §3 "Content in view mode" (the rule as stated); the archived plan is history.

Time box 3 h.

## U6 — A disabled menu row, and the overflow rows of dimmed tools (report D)

**The mechanism (report D §8; this plan's rulings above).**
- The existing tick reflection (`MenuRowReflectionSpec`: a source, a reader, a value, re-read over a
  `firesOnAnyChange` edge) gains a second slot, the row's ENABLEMENT:
  - `MenuRowReflectionSpec.enabledWhile(source, readerName, theValue, opts)`, with `opts.announcedBy` for an announcer
    that is not the source;
  - `CommandSpec` key `enablement:`;
  - `MenuItemWdgt.rowEnablement`, its edge, and `isDisabled()`, read live at paint and at press.
- Refusal: `MenuItemWdgt.activated` / `doubleActivated` return early while disabled. That means no action, no
  dismissal and no bring-to-front.
- Look: one Theme role `menuRowDisabledText = @disabledText` for everything the row draws:
  - the label's ink through `inkForChildText`;
  - the tick and chevron through `_fillForMyState`;
  - a raster picture as its silhouette (`HTMLCanvasElement.blackSilhouetteOf`, exact for the one-ink pictures);
  - a live typed face through the icon-ink precedence, `livePictureOn` handing the holder its pop-time ink;
  - no hover or press plate (`_shownState` answers "atRest");
  - kept: the rest fill, the pinned grip, the tooltip, the wording.
- Item 7: `OverflowChevronButtonWdgt.actOnClick` gives
  `enablement: MenuRowReflectionSpec.enabledWhile cell, "holdsToolWithNothingToActOn", false` to each row whose tool
  answers `hasSomethingToActOn`.
- The copied-menu gap: `MenuItemWdgt._reactToBeingCopied` and `_afterDeserialization` re-declare both edges, as
  `ToolbarWdgt` does. Today a copied pinned menu's ticks freeze (MEASURED).

**Tests.**
- **Predicted pixel set (report D §5): exactly** `macroTabletDockedToolbarChevron` image_2, where the dimmed tools'
  rows go grey: dpr 1 and 2 × mouse and finger, 4 files. The menu sweep calls actions directly and is unaffected;
  confirm it.
- **New:** `SystemTest_macroOverflowRowOfADimmedToolIsDisabled`, both pointers (report D §6 T7):
  - its rows read disabled exactly while their cell is dimmed;
  - a press leaves the menu open and changes nothing;
  - pinned and moved clear, the rows wake when the paragraph is clicked;
  - Bold's row then works;
  - a copied pinned menu keeps re-reading.

  It needs screenshots (a live read cannot see a missed repaint), with a premise assertion that the menu doesn't
  overlap the window. Plants: report D §6.

**Docs.** `toolbars.md` §5.3 (the overflow row now looks disabled); `visual-design-system.md` §4.3 and §5 "Rows" and
the tool-cell paragraph; `widget-authoring-guidelines.md` §10 (a row whose action can be refused declares when it is
enabled, and names its announcer); `MACRO-PATTERNS.md` (how to assert a disabled row).

Time box 4 h.

## U7 — A pinned text menu greys its editing rows in view mode (report D)

**Fix.**
- `WorldWdgt.noteEditModeChanged` announces on EVERY flip (`@dataflow?.markNonValueChange @`), with no focus guard,
  and its comment is rewritten.
- `StringWdgt._addTextMenuEntries`, `_addAlignmentAndFittingMenuEntries` and `fontsMenu`, and `TextWdgt`'s "Soft
  wrap", give each EDITING row
  `enablement: MenuRowReflectionSpec.enabledWhile @, "sitsInViewModeContent", false, announcedBy: world`.
- Keep every `addMenuItem` call literal, so `check-menu-actions` still sees the action strings.
- The build-time omission (a menu opened in view mode leaves the rows out) stays.
- **Trap:** widgets inside a toolbar also answer `sitsInViewModeContent` true. Only a text gets this spec about
  itself.

**Tests.**
- **Predicted pixel set: EMPTY.** Every toolbar now refreshes on every flip; the presuite must show that is
  pixel-neutral.
- **New:** `SystemTest_macroPinnedTextMenuGreysItsEditingRowsInViewMode`, both pointers (report D §6 T3):
  - pin the paragraph's menu and move it clear;
  - establish the focus AWAY from the paragraph (after U3, a menu press no longer moves it);
  - flip with the pencil: every editing row reads disabled and refuses, and "Run contents" stays enabled;
  - flip back: the rows work.

  Screenshots, as in U6. Plants: the world announcement focus-gated again; the spec dropped from the alignment rows.

**Docs.** `toolbars.md` §7 (the world announces every mode flip); `widget-authoring-guidelines.md` §10 if U6's bullet
needs the announcer example.

Time box 3 h.

## U8 — Close

- If every unit CLOSED:
  - `git mv` this plan to `docs/archive/` and stamp it CLOSED with the commits;
  - add its `archive/INDEX.md` line, with case law worth keeping from the LEDGER;
  - BACKLOG's section for this plan keeps only the items filed on the way.
- If any PARKED: the plan stays in `plans/` with each parked unit's question written into its section, and BACKLOG
  points at it.
- The memory note and its MEMORY.md line, either way.

---

## 2. Verification protocol (every unit)

- `fg build` after each step; `fg presuite`.
- For a unit that changes pixels or input handling, the finger suite at dpr 1.
- The new test passes under both pointers, and FAILS under each of its bite plants (`--prelude=`).
- Its follower is clean on both pointers: `run-sequence-headless.js SystemTest_<new> SystemTest_macroAnalogClockInspectEdit`,
  with zero `WORLD_INVENTORY_` lines.
- The failing set equals the unit's PREDICTED set. Each diff is checked in `fg diffpage` (saved to the unit's scratch
  dir) and is the fix's own target. Only then `fg recapture --auto --dprs=1,2`, then with `--pointer=finger`.
- `fg gauntlet` green (a leg passing only on its serial retry is a load flake ONLY if its log shows nothing this unit
  touches; read it). Then commit and push per BRIEF.md.

## 3. Rejected alternatives — do not re-attempt blind

1. U5 rule A, "view mode wherever any enclosing holder is in view": reverses measured nested-window behaviour (report
   C §4.4). Left for the owner, not for the loop.
2. U5 pushed state (the document's flip writes into nested containers): it must remember each container's own mode,
   and it is a second mechanism.
3. U5 a world-level or caret-level typing door: it would break the Degrees Converter (report C §2.3).
4. U4 `minimumExtent`: an always-on clamp, against the owner's tradition.
5. U3 an attachment guard (`root() is world`) at the door: it dims the tools while a widget is carried.
   `surelyNotShowingUp…` treats the hand as a screen.
6. U3 rows-only chrome: it needs code to tell a menu's rows from a prompt's; the whole menu is simpler.
7. U2 a hand-called `_reLayout`, another widget's `_settleLayoutsAfter`, or picturing only the icon.
8. U6 a reader method per row kind: the spec's value comparison already negates.

## 4. References

- `docs/archive/docked-and-floating-toolbars-plan.md`: rulings R1–R10, D1–D8, its `## BACKLOG detail`, §8 results.
- `docs/architecture/toolbars.md`, `visual-design-system.md`, `widget-authoring-guidelines.md`, `lint-and-static-checks.md`.
- `Fizzygum-tests/DETERMINISM.md` (§3g, §3p for the picture and text paths); `src/macros/CLAUDE.md`,
  `src/macros/MACRO-PATTERNS.md`.
- Research: `Fizzygum-tests/.scratch/overnight-toolbar-residue/research/` (A, C, D, E).

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] **Home and End leave the caret wrong in a multi-line text** — `TextWdgt.startOfLine` / `endOfLine` read `.y` from `slotRowAndColumn`, which answers `[row, column]`: End stays put, and Home after it leaves `world.caret` undefined (measured in a tool's code prompt); found in P2, independent of it — reachable, medium.
  — CLOSED 2026-11-17 (overnight loop, U1; filed under `archive/docked-and-floating-toolbars-plan.md`): `startOfLine` /
  `endOfLine` destructure `[row]`, and Home and End remember the caret's column like every horizontal move; covered
  by `SystemTest_macroHomeAndEndInAMultiLineText` (§U1, "Landed").

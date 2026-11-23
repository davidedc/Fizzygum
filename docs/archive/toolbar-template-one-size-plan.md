# Toolbar Templates — one way out of a tool cell, at one size

**Status: COMPLETE 2026-11-23.** Authored 2026-11-23 and executed cold the same day; Phases 0–6 landed as
written, with the owner's sizes (Candidate B) and one owner-approved addition, the finger fix the refused-copy
test found; the deviations are in the execution ledger at the end. The living truth is
`docs/architecture/toolbars.md` §1, §6, §8 and `docs/architecture/input-and-gestures.md` (the pick-up, the
hold's lift). Below, the plan as it was executed.

Authored against Fizzygum `12b38161` / Fizzygum-tests `4c56e739e` (both level with their remotes, build
FRESH, gauntlet 20/20); every number in §1–§4 was measured on that build by read-only probes (§9).

**Mandate: transformation, not accommodation.** After this plan a tool cell has ONE way of handing out its
tool. A click on the cell and a drag out of it run the same method and give the same widget at the same
size; the size is a fact the CELL keeps, not a field that travels on every copy; and the hand has no case
for toolbars. Nothing is patched so that two paths happen to agree: the second path is deleted.

---

## §0 Orientation

### What this workspace is (one hop each)

Fizzygum is a CoffeeScript GUI framework drawn on one `<canvas>`. Three sibling repos under
`/Users/davidedellacasa/code/Fizzygum-all/`: `Fizzygum/` (source; the only place behaviour is edited),
`Fizzygum-tests/` (the SystemTest suite and its references), `Fizzygum-builds/` (generated; never edited).
Read `Fizzygum-all/CLAUDE.md`, `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md` before the first command.
Every build and test command goes through the wrapper, by ABSOLUTE path:
`/Users/davidedellacasa/code/Fizzygum-all/fg <cmd>` (bare `fg` prints the roster).

### Why this plan exists

The owner noticed (2026-11-23, right after the toolbar band-depth arc, `docs/archive/toolbar-band-depth-plan.md`)
that some tools of the Slides toolbar come out at one size whether clicked or dragged (the map) and others
at two different sizes (the map pin). Measured: every one of the 20 "Template" tools comes out 32 × 32 on
a click and 50 × 40 on a drag (the speech bubble 105 × 80), and neither size was chosen by anyone.

### Vocabulary (the code's own words)

- **Tool cell**: `GlassBoxBottomWdgt`, the 44 × 44 square a toolbar's tool stands in. `ToolPanelWdgt` wraps
  every tool it is given in one.
- **Creator button**: a `CreatorButtonWdgt` subclass (text box, link, video, the maps, the plots). It answers
  `_createWidgetToBeHandled`, which BUILDS a fresh widget at a size the creator states.
- **Template**: a live widget standing in a cell as a sample (a rectangle, a map pin, a speech bubble, an
  icon, an arrow). What leaves the cell is a COPY of it. `Widget.isTemplate` is the mark.
- **Lid**: `GlassBoxTopWdgt`, the invisible widget over a Template in its cell. It takes the press.
  `class GlassBoxTopWdgt extends CreatorWdgt`.
- **Mark box**: the 32 × 32 square a tool's picture is drawn in inside its cell (`Theme.toolMarkSize`).
- **Roster**: a toolbar's item list, `_toolbarItems`.

### The critical reframe (three facts, each measured)

1. **The lid already IS a creator.** Its class extends `CreatorWdgt`, and a click on it runs the creator's
   `activated` and places what `_createWidgetToBeHandled` answers. Only the DRAG bypasses it: the lid's
   `findRootForGrab` hands the hand the Template itself, and the hand's generic Template arm makes a second
   copy by a second route. One tool, two makers, two sizes.
2. **No other tool in any toolbar reaches the hand's toolbar case.** The hand resizes a grabbed widget
   whose pre-grab parent is a cell (`@grabOrigin?.origin instanceof GlassBoxBottomWdgt`). Probed over every
   `ToolbarWdgt` subclass (§1.5): creator buttons hand out their own product; the text and sheet property
   buttons are marked `isTemplate` but a drag on one climbs to the WINDOW (it moves the toolbar); the paint
   tools reject the drag. So once the lid's drag goes through the creator's door, that branch of the hand
   serves nobody and is deleted, with its `instanceof`.
3. **The size is the cell's fact.** The cell is what shrinks a tool to 32 × 32, so the cell is what must
   remember the size it had. Today the size is a field written onto the WIDGET, only when absent, and it
   travels with every copy: a copy dragged out, resized to 300 × 200 and put into a toolbar again still
   carries 50 × 40 (measured, §1.4).

### What the owner decided, and what is open

- **Decided (2026-11-23):** a click places what a drag places. Templates stay (they are not turned into
  creator classes).
- **Open, and Phase 0 of this plan:** the size each Template comes out at. 50 × 40 is the size every widget
  is born at, not a choice. The owner picks from a rendered page.

---

## §0.5 Cold-execution protocol

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status`. Both repos must be level with their remotes and
   the build FRESH (if STALE: `fg build`). The only uncommitted files allowed in `Fizzygum/` are this plan
   and `docs/BACKLOG.md` (this plan's section), in case the plan was handed over before its commit;
   `Fizzygum-tests/` must be clean (its `.scratch/` is gitignored). Anything else: stop and report.
2. Read, in this order: this whole file; `Fizzygum/docs/architecture/toolbars.md` §1 and §6;
   `Fizzygum/docs/architecture/widget-authoring-guidelines.md` (§4.1 and the checklist);
   `Fizzygum/docs/architecture/lint-and-static-checks.md` §3b (how a gate finding is answered);
   `Fizzygum/src/macros/CLAUDE.md`; in `Fizzygum/src/macros/MACRO-PATTERNS.md` the entry "Drag a tool out
   of a toolbar".
3. Do the phases IN ORDER, with one exception that is deliberate: Phase 0 ends in a question to the owner,
   and Phases 1 and 2 do not depend on the answer. Ask, then carry on with Phases 1 and 2. Phase 3 needs
   the answer; if it has not come by then, do Phase 5's parts that do not name sizes, then wait.
4. Line numbers in this file drift. The quoted code and the method names are the authority: grep them fresh.
5. Rules that have each cost a re-run before:
   - never pipe a gating `fg` call through `| tail` / `| grep` (the pipe hides the exit code);
   - one long `fg` operation at a time; launch a long one with the Bash tool's `run_in_background: true`,
     output to a log file, and wait for the completion notice (no foreground polling loops);
   - a running long operation owns `src/` and `tests/`: do not edit them until it ends;
   - absolute paths and `git -C <abs-repo>` always; never `git stash` in these repos;
   - never aim a recursive delete at `Fizzygum-builds/latest/js/tests` (a symlink into the real suite);
   - ad-hoc Node probes live under `Fizzygum-tests/.scratch/` (gitignored), never elsewhere;
   - edit `.coffee` files with the Edit tool, never with `perl -pi` / `sed -i` (they de-indent).
6. A gate that fires is answered by its CLASS, never by bending the design: an invariant is fixed at its
   cause; a convention is met; a budget (a count or complexity ceiling) may be raised in the same change
   with a dated reason beside the number (owner ruling 2026-11-16: the right shape over the count). Read the
   gate's own advice row before choosing.
7. Comments and docs are a deliverable. Present tense only: the `comment-narration` stink fails the build on
   words like "no longer", "now", "used to", "previously" in a source comment.
8. **Never commit or push without the owner's word.** At the end present a summary, the two commit messages
   and the review of changed pictures, then wait. Commit with `git commit -F <absolute path to a message
   file>` (backticks in a shell-quoted message get corrupted).
9. Give an ETA before each long operation and a status line about every five minutes while it runs.
10. Sizing. This is ONE session's work (about four hours with the gates), not a loop: one owner decision at
    the start, eight source files for the mechanism, a one-line declaration on up to twenty tool classes,
    two new tests, a small recapture, one gauntlet.

---

## §1 The mechanism as it stands (verified 2026-11-23 at Fizzygum `12b38161`)

### §1.1 How a tool gets into a cell — `src/app-kit/ToolPanelWdgt.coffee`, `_addNoSettle`

```coffee
      if aWdgt.grabbedWidgetSwitcheroo == Widget::grabbedWidgetSwitcheroo
        aWdgt.isTemplate = true

      if !aWdgt.extentToGetWhenDraggedFromGlassBox?
        aWdgt.extentToGetWhenDraggedFromGlassBox = aWdgt.extent()

      unless aWdgt.standsAsAToolCell?()
        glassBoxBottom = new GlassBoxBottomWdgt
        glassBoxBottom.add aWdgt

        if !aWdgt.actionableAsThumbnail
          glassBoxTop = new GlassBoxTopWdgt
          glassBoxTop.toolTipMessage = aWdgt.toolName ? aWdgt.toolTipMessage
          glassBoxBottom.add glassBoxTop
          glassBoxBottom.lid = glassBoxTop
```

So: a tool with no drag product of its own is marked a Template; the size it has at that moment is written
onto the WIDGET, only when the widget has none; a tool that does not act on its own press gets a lid. The
cell then seats a lidded tool at the mark box (`GlassBoxBottomWdgt._reLayoutSelf`, `_seatAtSide w, markSide`),
which is why the size must be remembered at all.

### §1.2 The click — `src/app-kit/GlassBoxTopWdgt.coffee` (its two methods)

```coffee
  _createWidgetToBeHandled: ->
    # settling-call-sanctioned: fullCopy has no NoSettle core; a lid's copy is made at event time (a click on
    # its cell, CreatorWdgt.activated), outside any pass
    widgetToBeHandled = @parent.children[0].fullCopy()
    # refused (Widget.fullCopy has told the person why): nothing to hand over
    return undefined unless widgetToBeHandled?
    widgetToBeHandled.isTemplate = false
    return widgetToBeHandled

  # grab the widget inside the glass box
  findRootForGrab: ->
    return @parent.children[0]
```

A click runs `CreatorWdgt.activated` (`src/app-kit/CreatorWdgt.coffee`), which places what
`_createWidgetToBeHandled` answers: into the host window's content when the toolbar is docked, else into the
topmost window that takes a placed widget, else beside the tool on the desktop. The copy is made of the
thumbnail AS IT STANDS IN THE CELL and is never resized: 32 × 32. A toolbar overflow menu's row makes the
same call (`GlassBoxBottomWdgt.thumbnailClickReceiver`).

### §1.3 The drag — `src/ActivePointerWdgt.coffee`

The press records `@wdgtToGrab = w.findRootForGrab()`; on the lid that is the Template itself (§1.2). Then
`determineGrabs`:

```coffee
        if @wdgtToGrab.isTemplate
          if skipDragging or !@strokeMeansMouseDrag() then return

          w = @wdgtToGrab.fullCopy()
          unless w?
            @wdgtToGrab = undefined
            return
          w.isTemplate = false
          # the copy is picked up from where the TEMPLATE stands, so that is the grab's origin
          @grab w, displacementDueToGrabDragThreshold, false, @wdgtToGrab.situation()

        else if @wdgtToGrab.detachesWhenDragged()
          if skipDragging or !@strokeMeansMouseDrag() then return

          originalWdgtToGrab = @wdgtToGrab
          @wdgtToGrab = @wdgtToGrab.grabbedWidgetSwitcheroo()
          switcherooHappened = (originalWdgtToGrab != @wdgtToGrab)
          ...
          @wdgtToGrab = @wdgtToGrab._resolvePickUpFigure()
          w = @wdgtToGrab
          @grab w, displacementDueToGrabDragThreshold, switcherooHappened
```

and in `grab`:

```coffee
      if switcherooHappened
        # in this case the widget being grabbed is created on the fly
        # so just like the next case it's OK to center it under the pointer
        aWdgt.moveTo @position().subtract aWdgt.extent().floorDivideBy 2
        aWdgt._moveWithin world
      else if aWdgt.extentToGetWhenDraggedFromGlassBox? and (@grabOrigin?.origin instanceof GlassBoxBottomWdgt)
        # in this case the widget is "inflating". ...
        aWdgt.setExtent aWdgt.extentToGetWhenDraggedFromGlassBox
        aWdgt.moveTo @position().subtract aWdgt.extent().floorDivideBy 2
        aWdgt._moveWithin world
      else if displacementDueToGrabDragThreshold?
```

A Template's drag takes the FIRST arm (a copy made by the hand), then the "inflating" branch of `grab`. A
creator button's drag takes the SECOND arm: `CreatorButtonWdgt` answers
`grabbedWidgetSwitcheroo: -> @_createWidgetToBeHandled()` and `grabsToParentWhenDragged: -> false`
(`src/app-kit/CreatorButtonWdgt.coffee`), so its click and its drag run one method. Both arms end with the
widget centred under the pointer and fitted in the desktop.

### §1.4 The size field

`extentToGetWhenDraggedFromGlassBox` has exactly these sites in `src/` (grep it):
`ToolPanelWdgt._addNoSettle` (writes it when absent, §1.1), `ActivePointerWdgt.grab` (reads it, §1.3),
`SpeechBubbleWdgt` (declares it and sets `new Point 105, 80` in its constructor), and a paragraph of
`src/macros/MACRO-PATTERNS.md`. No other class states one, so every other Template gets the extent it has
when added: `Widget`'s constructor commits `new Rectangle 0,0,50,40`.

Measured: a copy made of the rectangle Template, resized to 300 × 200 and added to a second toolbar keeps
`extentToGetWhenDraggedFromGlassBox` = 50 × 40 (the "only when absent" write), so it would come out of that
toolbar at 50 × 40, not at the size it went in at. A speech bubble does the same with 105 × 80.

### §1.5 Measured today (software backend, density 1, Slides toolbar floating)

| Tool | Kind | Click makes | Drag makes |
|---|---|---|---|
| text box, link, video, world map, USA map | creator button | 150 × 75, 330 × 65, 330 × 65, 240 × 125, 230 × 145 | the same |
| rectangle, map pin, 5 small icons, 2 logos, vaporwave background and sun, 8 arrows (19 tools) | Template under a lid | 32 × 32 | 50 × 40 |
| speech bubble | Template under a lid | 32 × 32 | 105 × 80 |

Every toolbar, by what its cells hold and what a drag on the cell's press target would grab
(`thumbnailClickReceiver().findRootForGrab()`):

| Toolbar | Cells | A drag grabs |
|---|---|---|
| Slides | 5 creator buttons, 20 lidded Templates | creator: its product. Template: the Template (→ the hand's Template arm) |
| Dashboards | 8 creator buttons, 10 lidded Templates (map pin, speech bubble, the 8 arrows) | the same |
| Plots, Patch programming, Windows, Super | creator buttons only | its product |
| Text, Sheet | property buttons, lidless, marked `isTemplate` | the WINDOW (`FrameWdgt`): the drag moves the toolbar |
| Paint | 4 paint tools, lidless, marked `isTemplate` | nothing: the drag is rejected |

Lidded Templates exist only in the Slides and Dashboards toolbars, and the two share ten tool classes.
The only place outside `ToolPanelWdgt` that builds a cell by hand is `src/authoring/InfoDocs.coffee` (round
a lidless templates button); lids are built by `ToolPanelWdgt` alone.

An icon's picture is fitted into its box by ratio (`IconAppearance.calculateRectangleOfIcon`): in the
50 × 40 box a heart or an arrow is drawn 40 × 40 and the map pin 28 × 40.

### §1.6 The other users of `isTemplate` (untouched by this plan)

`DocumentViewportWdgt.makeAllContentIntoTemplates` (the "useful snippets" window that `TemplatesButtonWdgt`
opens: dragging a snippet gives a copy), `MagnetWdgt` (`isTemplate: true`, the Fizzytiles sample magnets) and
`StringWdgt._itemShape` (a Template text wears no item shape). None of them stands in a tool cell. They keep
the hand's Template arm exactly as it is.

---

## §2 Why it is shaped this way

The Template idea is the Morphic parts bin: a live sample you copy, so a tool needs no class. The steps, from
`git log`:

- `c30682c7` (2018-02-25) put a toolbar's items inside a glass box, "for better interaction": the lid as a
  larger target, its drag handing the hand the Template (`findRootForGrab`), the hand's generic rule
  ("dragging a Template carries a copy") doing the rest.
- `c0576720` (2018-03-16) named the size field `extentToGetWhenDraggedFromGlassBox`. Its name until then was
  `originalExtentBeforeBecomingThumbnail`, which is this plan's rule: the size the tool had when it went in.
  `8109ec7a`, the same day, added the speech bubble with a size of its own. The hand reads the field off
  the widget because the widget is all the hand has.
- `3b224e14` (2018-03-21) added the CLICK ("clicking on buttons, to automatically place items in the middle
  of a recently-used editable document"), as a second route beside the drag.
- `91f6fa81` (2026-11-12) gave the lid and the creator buttons one base, `CreatorWdgt`, for that click. The
  drag door stayed on `CreatorButtonWdgt` alone.
- `513839b6` gave `grab` its `origin` parameter, because a copy comes back a detached root and the hand
  could not otherwise tell it came from a cell (`docs/archive/spreadsheet-ux-plan.md` §6c).

Each step was local and reasonable; together they made two makers for one cell.

---

## §3 The distilled argument

- A person cannot see whether a cell holds a creator button or a Template, so one cell giving two sizes by
  gesture reads as arbitrary. The owner has ruled: one size.
- The creator buttons already show the shape: click and drag call one method. The lid is one inheritance
  step from it (`CreatorWdgt`), so the fix is to let the lid's drag use the door its click uses, and to move
  that door to the base both share.
- The planted prototype (§4) shows the whole dpr-1 mouse suite keeps 462 of 463 tests byte-identical under
  the new mechanism. The one that moves, `SystemTest_macroToolbarChevronPopsOverflow`, says in its own
  comment that a row "creates the tool's widget just as dragging the cell out would": the change makes that
  sentence true.
- The size belongs to the cell, and for a toolbar's own roster to the tool's CLASS, where `toolName`
  already lives ("what I am as a tool in a panel, in a word"). Stating it there gives the Slides and
  Dashboards toolbars one answer for the ten tools they share.

---

## §4 The target state (measured on the prototype, `Fizzygum-tests/.scratch/template-sizes/prototype.js`)

The prototype patches the planned mechanism into the page (Appendix B) and drives real synthesized input.

| Gesture | Today | Prototype |
|---|---|---|
| drag the speech bubble's cell to (700, 400) | 105 × 80 at (648, 360), text child 93 × 52 | identical |
| click the speech bubble's cell | 32 × 32, text child 20 × 14 | 105 × 80, text child 93 × 52 |
| click the map pin's cell | 32 × 32 | 50 × 40 (its size at entry; Phase 3 gives it the owner's) |
| drag the rectangle's cell | 50 × 40 | 50 × 40 |
| drag the USA map creator | 230 × 145 | 230 × 145 |
| a copy carries `extentToGetWhenDraggedFromGlassBox` as its own field | yes | no |
| drag a Template whose copy is REFUSED | nothing carried, no error | **`INPUT_ERROR … TypeError: Cannot read properties of undefined (reading '_resolvePickUpFigure')`** until the hand's creator arm gains a guard (Phase 2 step 5) |

`setExtent` and `_applyExtent` give identical results for the copy's resize in the prototype.

The rule a person sees: **a tool comes out of a toolbar at the size it went in at, whichever gesture takes
it out.** For a toolbar's own roster the tool goes in at the size its class states for a tool; for a widget a
person puts into a toolbar, at the size the person gave it.

---

## §5 The fix, by phase

### Phase 0 — the review page (the owner picks sizes)

1. The renderer is `Fizzygum-tests/.scratch/template-sizes/render-candidates.js` (if the file is missing,
   recreate it from Appendix A). It needs a FRESH dev build. Run it:
   `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node .scratch/template-sizes/render-candidates.js`
   (about 40 s). It writes `out/today-click.png`, `out/today-drag.png`, `out/A.png`, `out/B.png` and
   `review.html` in that directory. Each picture is a Slides Maker window holding the two reference
   products (the USA map 230 × 145 and the text box 150 × 75, which do not change), then every Template at
   the set's sizes in toolbar order, with a second map pin dropped on the map.
2. Look at each PNG yourself (the Read tool shows images) before showing the owner: every tool must be
   there, nothing clipped.
3. Open the page for the owner: `open /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/template-sizes/review.html`.
   The owner's standing preference is a LOCAL html file, not a claude.ai artifact. If the owner is following
   from another device, also send the four pictures as JPEGs no wider than 780 px.
4. Ask the owner which sizes to use. The candidates are the planner's, not the owner's:

   | Group | Today (drag) | A | B |
   |---|---|---|---|
   | rectangle | 50 × 40 | 150 × 100 | 200 × 130 |
   | map pin | 50 × 40 (picture 28 × 40) | 28 × 40 (same picture, box hugging it) | 35 × 50 |
   | speech bubble | 105 × 80 | 105 × 80 | 130 × 100 |
   | explosion, scratch area, flora, scooter, heart | 50 × 40 | 60 × 60 | 80 × 80 |
   | the two Fizzygum logos | 50 × 40 | 100 × 100 | 140 × 140 |
   | vaporwave background | 50 × 40 | 240 × 240 | 320 × 320 |
   | vaporwave sun | 50 × 40 | 100 × 100 | 140 × 140 |
   | the eight arrows | 50 × 40 | 60 × 60 | 80 × 80 |

   The owner may pick a set, mix groups, give other numbers, or keep 50 × 40 for a group. To show a new
   candidate, edit `SETS` in the renderer and run it again. Record the final answer in the table of Phase 3,
   with the date, before using it.
5. Do not wait idle: go on with Phases 1 and 2.

### Phase 1 — two tests, written first

Author both with the `/author-macro-test` skill of `Fizzygum-tests` (`.claude/skills/author-macro-test/`).
Assert with LITERAL expected values; never read a product method or field for the expected value. Keep every
fixture well inside the desktop (a widget lifted near the desktop's edge is fitted inside it at lift time,
and a finger lifts later than a mouse, so the two pointer kinds would disagree). Each test destroys what it
builds. Capture no references yet (Phase 4): until then judge these tests by their ASSERTION lines only (run
with `node scripts/run-macro-test-headless.js SystemTest_<name> --all-logs` from `Fizzygum-tests/`, and grep
`FAIL (assertion)`; the missing-reference failure of the screenshot is expected until Phase 4).

**Test 1 — `SystemTest_macroToolCellHandsOutOneSizeHoweverTaken`.** Scenario:
1. `bar = world.openFrameHuggingPayload (new SlidesToolbarWdgt), new Point 40, 40`; no other window, so a
   click places beside the tool on the desktop. Find the speech bubble Template by class
   (`bar.topWdgtSuchThat (w) -> w instanceof SpeechBubbleWdgt`); its cell is `template.parent`.
2. CLICK the cell (`@moveToAndClick_InputEvents cell`). Assert: exactly one `SpeechBubbleWdgt` is a desktop
   child; it is not the Template and `isTemplate` is false; its extent is `"105,80"`; the Template is still
   in its cell.
3. DRAG the cell out (`@dragWidgetTo_InputEvents cell, point`). Assert a second bubble, extent `"105,80"`,
   and that the two copies' text children have the same extent (two widgets made independently).
4. RE-ENTRY: resize the dragged copy with the public setter (`copy.setExtent new Point 300, 200`), open a
   second, empty toolbar (`tb = new ToolbarWdgt`, `world.openFrameHuggingPayload tb, …`) and put the copy
   into it (`tb.contents.add copy`, the call `SystemTest_macroToolCellAddedToAToolPanelIsNotWrappedAgain`
   makes; if an unlocked toolbar takes a real drop, prefer the drop and say which in `provenance`). Drag that
   cell out: assert `"300,200"`. Click that cell: assert `"300,200"`.
5. One screenshot before the clean-up; then destroy both windows and every copy.

On the UNCHANGED build, see it fail for exactly these reasons before touching `src/`: step 2 gives
`32,32`; step 4's drag gives `105,80` (the sticky field) and its click `32,32`. Step 3 passes. If the
failures differ, stop and understand why before going on.

**Test 2 — `SystemTest_macroRefusedToolCopyIsNotCarried`.** Scenario:
1. A floating Slides toolbar; the rectangle Template; give it a value the copier refuses:
   `template.somethingTheCopierRefuses = new DOMRect 0, 0, 1, 1` (measured: `fullCopy()` then answers
   `undefined` and informs the person).
2. Drag its cell out. Assert: nothing rides the hand afterwards, no new `RectangleWdgt` on the desktop, and
   the person was told (an inform is shown; find how an existing test meets and puts away an inform, for
   example `SystemTest_macroInspectorSaveRefusesCodeThatDoesNotCompile`). Put the inform away.
3. Click its cell. Assert: nothing made, told again. Put the inform away.
4. Control: delete the planted field, drag the cell out, assert one rectangle lands (the path is alive).
5. Clean up.

On the unchanged build this test PASSES (the hand's Template arm has its guard). Its bite is proven inside
Phase 2: it must FAIL between steps 3 and 5 there, with the `INPUT_ERROR` line of §4, and pass after step 5.
An `INPUT_ERROR` console line fails a test through the runners' fail-gate, so no assertion is needed for it.

### Phase 2 — the mechanism

Seven edits and two builds: one after step 4, only to see Test 2 fail, and one after step 7 (the syntax gate
and the static gates run in the build; answer what they report each time). Suggested names are used
consistently below; a better name is welcome if used everywhere.

**Step 1 — the cell keeps the size and makes the copy: `src/GlassBoxBottomWdgt.coffee`.** Declare the field
at class level beside `lid` (widget-authoring §4.1) and add one public method (the lid calls it, so it is
public: rule [U] of `check-call-separation`):

```coffee
  # THE SIZE MY TOOL CAME IN AT: its extent as the tool panel stood it in me (ToolPanelWdgt._addNoSettle
  # records it), before I fitted it to my mark box or to my whole square. A copy of my tool leaves me at
  # this size (copyOfToolToHandOut), so a tool comes out of a toolbar as large as it went in. A cell no tool
  # panel filled keeps none, and its copy leaves at the size the tool stands at in it. A value of my own,
  # so a copy of me and a save keep it.
  toolOwnExtent: undefined

  # THE ONE THING I HAND OUT, whichever gesture takes it: a fresh copy of my tool, no Template itself, at
  # the size my tool came in at. A click on my lid places it and a drag out of my lid carries it
  # (GlassBoxTopWdgt, through CreatorWdgt's two doors), so the two cannot disagree. Undefined when the copy
  # is refused (Widget.fullCopy has told the person why).
  copyOfToolToHandOut: ->
    copy = @glassBoxItem().fullCopy()
    return undefined unless copy?
    copy.isTemplate = false
    copy.setExtent @toolOwnExtent if @toolOwnExtent?
    copy
```

Also revise the class header comment: the lid paragraph says the lid is "the LID a press lands on"; add what
the cell hands out and that it keeps the tool's size.

**Step 2 — the panel records the size on the cell: `src/app-kit/ToolPanelWdgt.coffee`, `_addNoSettle`.**
Delete the two lines that write `extentToGetWhenDraggedFromGlassBox` onto the widget (§1.1). Inside
`unless aWdgt.standsAsAToolCell?()`, record on the cell BEFORE the cell takes the tool in:

```coffee
        glassBoxBottom = new GlassBoxBottomWdgt
        # the size the tool comes in at, read before the cell fits it: what a copy of it leaves the cell at
        glassBoxBottom.toolOwnExtent = aWdgt.extent()
        glassBoxBottom.add aWdgt
```

(The panel already writes `glassBoxBottom.lid` this way.) The `isTemplate` marking above it stays as it is.

**Step 3 — the lid asks its cell: `src/app-kit/GlassBoxTopWdgt.coffee`.** Replace the body of
`_createWidgetToBeHandled` and DELETE `findRootForGrab` with its comment:

```coffee
  # what a click on me places and what a drag out of me carries: the one copy my cell hands out (a lid
  # standing in no cell makes nothing)
  _createWidgetToBeHandled: ->
    @parent?.copyOfToolToHandOut?()
```

The `# settling-call-sanctioned` marker leaves with the `fullCopy` call it excused (a marker on a line that
no longer makes the call is reported stale by `check-layering`; if the gate then asks for
`SETTLING_CALL_MARKER_CEILING` to be lowered, lower it with a dated reason). Rewrite the class header: the lid
is the cell's creator; its click and its drag are `CreatorWdgt`'s.

**Step 4 — the drag door moves to the base: `src/app-kit/CreatorWdgt.coffee` and `CreatorButtonWdgt.coffee`.**
Add to `CreatorWdgt` (and say it in its header, where "A DRAG out of me is no click" is today):

```coffee
  # A DRAG OUT OF ME carries what a click on me would place: the hand asks me what comes onto it
  # (ActivePointerWdgt.determineGrabs), and I make it there and then, so my two gestures make one thing.
  grabbedWidgetSwitcheroo: ->
    @_createWidgetToBeHandled()

  # I am what the drag takes hold of, never the tool cell I stand in: otherwise the cell would answer the
  # drag and the hand would carry my cell's tool away instead of what I make
  grabsToParentWhenDragged: ->
    false
```

Delete both members, with their comment, from `CreatorButtonWdgt` (it inherits them). `ToolPanelWdgt`'s test
`aWdgt.grabbedWidgetSwitcheroo == Widget::grabbedWidgetSwitcheroo` is unaffected: a creator button still
answers a different function.

→ **Test 2 must be seen failing here.** `fg build`, run Test 2, and find the
`INPUT_ERROR … _resolvePickUpFigure` line in its log: the lid's drag goes through the creator arm, which has
no guard yet. If Test 2 passes at this point, its plant refuses nothing or the drag is not reaching the lid:
find out which before step 5.

**Step 5 — the hand: `src/ActivePointerWdgt.coffee`.** Two edits.

In `determineGrabs`, the creator arm gains the guard its Template arm already has:

```coffee
          originalWdgtToGrab = @wdgtToGrab
          @wdgtToGrab = @wdgtToGrab.grabbedWidgetSwitcheroo()
          # nothing made (a copy refused, and the person told why): nothing to carry, and with nothing left
          # to grab the next move of this press tries nothing again
          return unless @wdgtToGrab?
          switcherooHappened = (originalWdgtToGrab != @wdgtToGrab)
```

In `grab`, delete the whole `else if aWdgt.extentToGetWhenDraggedFromGlassBox? and (@grabOrigin?.origin
instanceof GlassBoxBottomWdgt)` branch with its comment and three statements (§1.3). Reword the two comments
that lean on it: the `switcherooHappened` branch's "so just like the next case it's OK to center it", and the
"WHERE THE PICK-UP STARTED" comment's "and for the glass-box inflation below". Leave `grab`'s `origin`
parameter and the Template arm that passes it exactly as they are (the snippets window and the magnets use
that arm, and the drop's sticky re-embed reads the origin).

Expected gate findings, each a BUDGET or a ratchet to tighten, answered per §0.5 rule 6:
- `buildSystem/check-complexity-ratchets.js` holds `'ActivePointerWdgt#determineGrabs': 37`; the guard adds
  to it. Raise the record to the number the gate prints, with a dated reason beside it.
- `buildSystem/check-stinks.js`, `instanceof-type-test`, `baseline: 64`: one `instanceof` leaves. If the gate
  asks to tighten, set 63 with a dated note in the row's comment.

**Step 6 — the speech bubble states its size as a tool: `src/app-kit/SpeechBubbleWdgt.coffee`.** Delete the
`extentToGetWhenDraggedFromGlassBox: undefined` declaration with its comment and the constructor line
`@extentToGetWhenDraggedFromGlassBox = new Point 105,80`. Beside `toolName`, declare:

```coffee
  # the size I have as a tool: a toolbar builds me at it before my cell takes me in (ToolbarWdgt), so a
  # copy of me leaves the cell at it. Outside a toolbar's own roster it is read by nothing: built anywhere
  # else I am born at Widget's size, and put into a toolbar by a person I keep the size I arrive at.
  toolExtent: new Point 105, 80
```

(A class-level initializer that BEGINS with `new Point` is an edge the boot dependency scanner sees; a
`Point` is immutable, so one instance shared by the class is safe.)

**Step 7 — a toolbar builds its roster at those sizes: `src/app-kit/ToolbarWdgt.coffee`.** In
`_buildAndConnectChildrenNoSettle`, replace `@_addManyNoSettle @_toolbarItems()` with
`@_addManyNoSettle @_rosterAtToolExtents()` and add:

```coffee
  # MY ROSTER, EACH TOOL AT ITS OWN SIZE: a tool whose class states the size it has as a tool (toolExtent:
  # a map pin's, a speech bubble's) is given it before its cell takes it in, so that is the size the cell
  # keeps (GlassBoxBottomWdgt.toolOwnExtent) and a copy leaves at. A tool that states none comes in as it
  # is built. Only my own roster passes here: a widget a person puts into a toolbar comes in at the size
  # the person gave it.
  _rosterAtToolExtents: ->
    for tool in @_toolbarItems()
      tool._applyExtent tool.toolExtent if tool.toolExtent?
      tool
```

Then:
1. `grep -rn extentToGetWhenDraggedFromGlassBox /Users/davidedellacasa/code/Fizzygum-all/Fizzygum/src` must
   show only `macros/MACRO-PATTERNS.md` (Phase 5 rewrites it).
2. `fg build`. Answer each gate finding by its class.
3. Run Test 1: every assertion passes (click `105,80`; re-entry `300,200` twice). Run Test 2: passes.
4. Run `SystemTest_macroTemplateDraggedOutOfToolbarInflates`
   (`/Users/davidedellacasa/code/Fizzygum-all/fg test SystemTest_macroTemplateDraggedOutOfToolbarInflates`):
   it must PASS against its committed reference, pixels included. If it does not, stop: the drag of a
   Template is meant to be unchanged.
5. Run `node .scratch/template-sizes/probe-all-toolbars.js` from `Fizzygum-tests/` if the file is there: the
   LID rows must now read `drag→GlassBoxTopWdgt` (the lid itself, whose product the hand takes), and no row
   may show a `field=` other than `none`.

### Phase 3 — the sizes the owner chose

The owner's sizes (owner, 2026-11-23: **Candidate B**, every group; "—" = keep the size the tool is born at,
declare nothing):

| Tool class (file under `Fizzygum/src/`) | `toolExtent` |
|---|---|
| `RectangleWdgt` (`basic-widgets/`) | 200 × 130 |
| `MapPinIconWdgt` (`authoring-icons/`) | 35 × 50 |
| `SpeechBubbleWdgt` (`app-kit/`) | 130 × 100 |
| `DestroyIconWdgt`, `ScratchAreaIconWdgt`, `FloraIconWdgt`, `ScooterIconWdgt`, `HeartIconWdgt` (`authoring-icons/`) | 80 × 80 |
| `FizzygumLogoIconWdgt`, `FizzygumLogoWithTextIconWdgt` (`authoring-icons/`) | 140 × 140 |
| `VaporwaveBackgroundIconWdgt` (`authoring-icons/`) | 320 × 320 |
| `VaporwaveSunIconWdgt` (`authoring-icons/`) | 140 × 140 |
| `ArrowNIconWdgt`, `ArrowSIconWdgt`, `ArrowWIconWdgt`, `ArrowEIconWdgt`, `ArrowNWIconWdgt`, `ArrowNEIconWdgt`, `ArrowSWIconWdgt`, `ArrowSEIconWdgt` (`authoring-icons/`) | 80 × 80 |

1. On each class with a chosen size, declare `toolExtent: new Point <w>, <h>` at class level, beside
   `toolName` where the class has one, with a one-line comment that points at `SpeechBubbleWdgt`'s for the
   rule. Integers only. Do not touch the rosters: `SlidesToolbarWdgt` and `DashboardsToolbarWdgt` list the
   same classes and get the same sizes through the class.
2. Extend Test 1 with literal assertions for three sized tools, each by a click AND a drag: the map pin, the
   rectangle, one arrow. If the owner kept 50 × 40 for one of them, assert `50,40`.
3. `fg build`; run Test 1 and Test 2.
4. Check a toolbar's own look did not move: a cell seats its tool at the 32 px mark box whatever size the
   tool came in at. `fg test SystemTest_macroToolbarBandIsAsDeepAsAStrip` must pass against its committed
   references.

### Phase 4 — the suite and the references

1. `/Users/davidedellacasa/code/Fizzygum-all/fg presuite > /tmp/fg-presuite-run.log 2>&1` in the background
   (about 4 min). Read the failure list from the summary's `failed tests (N): [...]` line, and grep
   `FAIL (assertion)` for assertion failures.
2. Expected, measured by running the dpr-1 mouse suite with the mechanism planted (Appendix B):
   **`SystemTest_macroToolbarChevronPopsOverflow` only** (images 3 and 4: the tool an overflow row places is
   32 × 32 there today). Beyond it, the sizes of Phase 3 may move: a test that takes a sized Template out of
   a toolbar, and an inspector's member list on a class that gained `toolExtent`. Every other failure is a
   finding: stop and investigate before any recapture.
3. Build a review page of the changed pictures BEFORE recapturing:
   `/Users/davidedellacasa/code/Fizzygum-all/fg diffpage <failing test names> --dprs=1,2`. Look at every
   difference. Each must be one of: a Template placed by a click or an overflow row at its own size; a
   Template at a size chosen in Phase 3; a member list with one more row. Keep the page for the owner.
4. Recapture, mouse then finger, each in the background, about 10 min each:
   `fg recapture --auto --dprs=1,2 > /tmp/fg-recapture-run.log 2>&1`, then
   `fg recapture --auto --pointer=finger --dprs=1,2 > /tmp/fg-recapture-finger-run.log 2>&1`. Each must end
   `RECAPTURE COMPLETE`. A benign inspector member-list change is a sanctioned recapture; if the gate names
   the inspector churn set, see `fg recapture-inspector` in the `fg` roster.
5. Capture the two new tests' references:
   `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/capture-macro-test-references.js SystemTest_macroToolCellHandsOutOneSizeHoweverTaken --dprs=1,2`,
   the same with `--pointer=finger`, and both again for `SystemTest_macroRefusedToolCopyIsNotCarried`. Look at
   each captured picture. A finger reference that differs from its mouse twin is a translation defect until
   proven otherwise: compare them.
6. Prove each new test leaves the world as it found it, on both pointers:
   `node scripts/run-sequence-headless.js SystemTest_<new> SystemTest_macroAnalogClockInspectEdit` and the
   same with `--pointer=finger`: zero `WORLD_INVENTORY_` lines.
7. Prove Test 1 bites, with a plant through `--prelude=` (a file under `.scratch/`): make
   `GlassBoxBottomWdgt.prototype.copyOfToolToHandOut` skip the resize. Test 1 must fail by its own click and
   drag lines. Remove the plant; it passes. (Test 2's bite was seen in Phase 2.)
8. Re-read the tests that still PASS but lean on what changed: grep `tests/` for
   `extentToGetWhenDraggedFromGlassBox`, `findRootForGrab` and `isTemplate`
   (`SystemTest_macroTemplateDraggedOutOfToolbarInflates` and
   `SystemTest_macroWidgetDestroyedOrClosedMidStrokeIsNotPickedUpAgain` name the last). Fix a comment or a
   metadata string that describes the old mechanism (the inflate test's `provenance` speaks of "the grab's
   stated origin"); a reference must not change for that.

### Phase 5 — docs, comments, backlog

1. `Fizzygum/docs/architecture/toolbars.md`, present tense: §1 "One construction for every toolbar" (the
   lid hands out the cell's one copy; the cell keeps the size the tool came in at; a toolbar builds its
   roster at each tool's `toolExtent`); §6 "Creators" (a drag out of a creator carries what a click places,
   stated on `CreatorWdgt`; the lid inherits both); the list "adding a tool" (a Template that should come
   out at a size of its own declares `toolExtent`).
2. `Fizzygum/src/macros/MACRO-PATTERNS.md`, the entry "Drag a tool out of a toolbar": rewrite what it says
   about `extentToGetWhenDraggedFromGlassBox`, the grab's origin and the 44 × 44 plant, to the mechanism as
   it is, and add that a click on the cell places the same widget.
3. `Fizzygum/docs/plans/creation-and-templates-plan.md` §2, "Creator buttons": one sentence, that the lid of
   a Template's cell is a `CreatorWdgt` whose product is a copy of its cell's tool, by click and by drag.
4. Source comments: every header touched in Phase 2 reads true and present-tense. Check the header of
   `GlassBoxBottomWdgt`, `GlassBoxTopWdgt`, `CreatorWdgt`, `CreatorButtonWdgt`, `ToolPanelWdgt._addNoSettle`.
5. `Fizzygum/docs/BACKLOG.md`: delete this plan's item line; its text goes VERBATIM to this plan's
   `## BACKLOG ledger` with how it closed. File what the arc leaves open only if it meets the bar (README
   rule 5). The two notes already in this plan's ledger stay there.
6. From `Fizzygum/`: `node buildSystem/check-doc-narration.js` must exit 0.

### Phase 6 — close

1. `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet > /tmp/fg-gauntlet-run.log 2>&1` in the background
   (about 15 to 26 min): all 20 legs PASS. Then `fg homepage` (about 2 min): OK.
2. Follow the `close-arc` skill: `git mv` this plan to `docs/archive/`, stamp its status, add its
   `docs/archive/INDEX.md` line, fill the ledger with the deviations from this plan.
3. Present to the owner: a summary, the review page of changed pictures, the two commit messages (Fizzygum,
   Fizzygum-tests) as files. **Wait for the owner's word before any commit or push.**

---

## §6 Central risks

| Risk | Where it bites | Answer |
|---|---|---|
| A refused copy on the creator arm | `determineGrabs` calls `_resolvePickUpFigure` on `undefined` (measured) | Phase 2 step 5's guard; Test 2 |
| The lid climbing to its cell on a drag | without `grabsToParentWhenDragged: -> false` the hand takes the Template out of the cell | Phase 2 step 4; the inflate test asserts the Template stays |
| A toolbar's own pictures moving | a tool's `toolExtent` must not reach its 32 px thumbnail | Phase 3 step 4; any toolbar picture in Phase 4's diff page is a finding |
| Finger and mouse twins of a new test differing | a copy fitted inside the desktop at lift time | fixtures well inside the desktop; Phase 4 step 5 |
| Ratchets | `determineGrabs` complexity record; the `instanceof` baseline; the settling-call marker ceiling | budgets: adjust with a dated reason, never reshape the code for the count |
| Saved toolbars | a cell saved before this change has no `toolOwnExtent` | by design its copy leaves at the thumbnail's size (the owner holds no serialization compatibility obligations); the serialization legs must stay green |
| A class-level `toolExtent` on a widely inspected class (`RectangleWdgt`) | an inspector's member list gains a row | benign, recaptured in Phase 4; look at each one on the diff page |

---

## §7 Verification protocol (summary)

| When | Command | Passes when |
|---|---|---|
| Phase 0 | the renderer | four pictures, every tool present; the owner has answered |
| Phase 1 | Test 1 and Test 2 on the unchanged build | Test 1 fails on `32,32` / `105,80` / `32,32` exactly; Test 2 passes |
| Phase 2, after step 4 | `fg build`, Test 2 | Test 2 FAILS with the `INPUT_ERROR … _resolvePickUpFigure` line |
| Phase 2, after step 7 | `fg build`; Tests 1 and 2; the inflate test | exit 0; both pass on assertions; the inflate test passes on pixels |
| Phase 3 | `fg build`; Tests 1 and 2; the band-depth test | all pass |
| Phase 4 | `fg presuite` | only the expected failures, each seen on the diff page |
| Phase 4 | `fg recapture --auto --dprs=1,2`, then with `--pointer=finger` | `RECAPTURE COMPLETE` twice |
| Phase 4 | the two follower runs per new test; Test 1's plant | zero `WORLD_INVENTORY_` lines; the plant fails Test 1 by its own lines |
| Phase 5 | `node buildSystem/check-doc-narration.js` (from `Fizzygum/`) | exit 0 |
| Phase 6 | `fg gauntlet`, `fg homepage` | all 20 legs PASS; homepage OK |

All `fg` commands by absolute path, never piped.

---

## §8 Rejected alternatives (do not re-attempt)

- **Turn the Templates into creator classes.** Twenty classes of boilerplate, and it removes the one way a
  widget becomes a tool with no class written for it (`ToolPanelWdgt` wraps any widget it is given). It also
  runs against `docs/plans/creation-and-templates-plan.md`, whose two creation primitives are "duplicate a
  template" and "run an assembler".
- **Patch only the click** (the lid applies the widget's size field to its copy). Two makers remain and must
  be kept in step by hand, and the stale size of §1.4 remains.
- **Keep the drag on the hand's Template arm and have the cell make the copy there too.** The hand would
  keep a toolbar case (the `instanceof`, or a test for "was the copy resized") to know when to centre the
  copy under the pointer. The creator arm already centres.
- **State the sizes in the rosters** (`_toolbarItems`). The Slides and Dashboards rosters share ten tool
  classes, so ten sizes would be written twice and could disagree.
- **Make the size the class's birth size** (set it in the constructor). It changes every `new` of these
  classes: `SampleDashboardApp`'s five pins (placed by hand for a 50-wide box), `SampleSlideApp`,
  `DemoMenus`, `WidgetFactory`, and at least eight tests that build these icons directly.
- **Have the panel read the class's size when it wraps a tool** (`aWdgt.toolExtent ? aWdgt.extent()`). A
  speech bubble a person resized and put into a toolbar would come out at the class's 105 × 80: the stale
  size of §1.4 by another door. The roster is built at `toolExtent`; a person's widget comes in as it is.
- **Unify the hand's two float arms, drop `grab`'s `origin`, or stop marking a cell's tool `isTemplate`.**
  Each is a wider change with its own behaviour (the snippets window and the magnets ride the Template arm
  and are not centred under the pointer). Out of this plan; noted in the ledger.

---

## §9 References

- Source, all under `Fizzygum/src/`: `GlassBoxBottomWdgt.coffee`, `app-kit/GlassBoxTopWdgt.coffee`,
  `app-kit/CreatorWdgt.coffee`, `app-kit/CreatorButtonWdgt.coffee`, `app-kit/ToolPanelWdgt.coffee`,
  `app-kit/ToolbarWdgt.coffee`, `app-kit/SpeechBubbleWdgt.coffee`, `ActivePointerWdgt.coffee`
  (`grab`, `determineGrabs`), `authoring/SlidesToolbarWdgt.coffee`, `authoring/DashboardsToolbarWdgt.coffee`.
- Gates: `buildSystem/check-complexity-ratchets.js` (`'ActivePointerWdgt#determineGrabs': 37`),
  `buildSystem/check-stinks.js` (`instanceof-type-test`, baseline 64), `buildSystem/check-layering.js`
  (the settling-call marker), `buildSystem/check-call-separation.js`.
- Tests that name this mechanism: `SystemTest_macroTemplateDraggedOutOfToolbarInflates` (the drag, by value
  and by picture), `SystemTest_macroToolbarChevronPopsOverflow` (an overflow row's click),
  `SystemTest_macroDockedCreatorPlacesOnlyIntoItsHost` (a docked creator's placement),
  `SystemTest_macroToolCellAddedToAToolPanelIsNotWrappedAgain` (a cell built by hand).
- Docs: `docs/architecture/toolbars.md`; `docs/archive/toolbar-band-depth-plan.md` (the mark box, the arc
  before this one); `docs/plans/creation-and-templates-plan.md`; `docs/archive/spreadsheet-ux-plan.md` §6c
  (why `grab` takes an `origin`).
- The authoring session's probes, gitignored, on this machine, all in
  `Fizzygum-tests/.scratch/template-sizes/`: `probe.js` (the click and drag sizes of §1.5, and the re-entry
  measurement of §1.4), `probe-all-toolbars.js` (the toolbar table of §1.5), `probe-refusal.js` (the refused
  copy; an icon's picture in its box), `prototype.js` (§4; run it as
  `node .scratch/template-sizes/prototype.js baseline|applyExtent|setExtent [refuse]`),
  `plant-mechanism.js` and `suite-with-plant.log` (the planted suite run: 463 tests, 1 failed),
  `render-candidates.js`, `review.html`, `out/` (Phase 0).

---

## Appendix A — the Phase 0 renderer (a copy of `Fizzygum-tests/.scratch/template-sizes/render-candidates.js`)

It must live under `Fizzygum-tests/.scratch/` (Node resolves `require` from the script's directory).

```js
const path = require('path');
const fs = require('fs');
const { requirePuppeteerOrExit } = require('../../scripts/lib/headless-boot.js');
const puppeteer = requirePuppeteerOrExit();
require('../../scripts/lib/tests-manifests').ensureTestsManifests({ quiet: true });
const url = 'file://' + path.resolve(__dirname, '../../../Fizzygum-builds/latest/worldWithSystemTestHarness.html');
const outDir = path.resolve(__dirname, 'out');
fs.mkdirSync(outDir, { recursive: true });
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

// one size per GROUP of tools; a group's tools are listed in GROUPS below
const SETS = {
  'today-click': { title: 'Today, placed by a CLICK: every Template 32 x 32', rectangle: [32, 32], pin: [32, 32], bubble: [32, 32], smallIcons: [32, 32], logos: [32, 32], background: [32, 32], sun: [32, 32], arrows: [32, 32] },
  'today-drag':  { title: 'Today, DRAGGED out: 50 x 40 (speech bubble 105 x 80)', rectangle: [50, 40], pin: [50, 40], bubble: [105, 80], smallIcons: [50, 40], logos: [50, 40], background: [50, 40], sun: [50, 40], arrows: [50, 40] },
  'A':           { title: 'Candidate A', rectangle: [150, 100], pin: [28, 40], bubble: [105, 80], smallIcons: [60, 60], logos: [100, 100], background: [240, 240], sun: [100, 100], arrows: [60, 60] },
  'B':           { title: 'Candidate B (larger)', rectangle: [200, 130], pin: [35, 50], bubble: [130, 100], smallIcons: [80, 80], logos: [140, 140], background: [320, 320], sun: [140, 140], arrows: [80, 80] },
};
const GROUPS = {
  rectangle: ['RectangleWdgt'], pin: ['MapPinIconWdgt'], bubble: ['SpeechBubbleWdgt'],
  smallIcons: ['DestroyIconWdgt', 'ScratchAreaIconWdgt', 'FloraIconWdgt', 'ScooterIconWdgt', 'HeartIconWdgt'],
  logos: ['FizzygumLogoIconWdgt', 'FizzygumLogoWithTextIconWdgt'], background: ['VaporwaveBackgroundIconWdgt'], sun: ['VaporwaveSunIconWdgt'],
  arrows: ['ArrowNIconWdgt', 'ArrowSIconWdgt', 'ArrowWIconWdgt', 'ArrowEIconWdgt', 'ArrowNWIconWdgt', 'ArrowNEIconWdgt', 'ArrowSWIconWdgt', 'ArrowSEIconWdgt'],
};

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--allow-file-access-from-files', '--no-sandbox'] });
  const shots = [];
  try {
    for (const [name, set] of Object.entries(SETS)) {
      const page = await browser.newPage();
      await page.setViewport({ width: 1100, height: 1000, deviceScaleFactor: 1 });
      page.on('pageerror', (e) => console.log('PAGEERROR', e.message));
      await page.goto(url + '?dpr=1&speed=normal&intro=0', { waitUntil: 'load', timeout: 120000 });
      await page.waitForFunction(() => window.world && window.world.hand && window.SlideWdgt && window.SimpleUSAMapIconWdgt, { timeout: 120000 });
      await wait(1000);
      // the harness page draws DOM over the canvas: hide everything but the world before a screenshot
      const canvasBox = await page.evaluate(() => {
        for (const el of document.querySelectorAll('body *')) if (el.id !== 'world' && el.id !== 'background') el.style.visibility = 'hidden';
        const r = document.getElementById('world').getBoundingClientRect(); return { x: r.left, y: r.top };
      });
      const clip = await page.evaluate((set, GROUPS) => {
        const frame = world.openFrameWith(new SlideWdgt(), new Point(780, 900), new Point(10, 10));
        const container = frame.contents.contents;               // the slide's sheet, as SampleSlideApp reaches it
        const origin = container.position();
        const runWidth = container.width() - 24;
        let x = 12, y = 12, rowHeight = 0;
        const place = (w, width, height) => {
          if (x + width > runWidth) { x = 12; y += rowHeight + 14; rowHeight = 0; }
          container.add(w);
          w._applyBounds(origin.add(new Point(x, y)), new Point(width, height));
          x += width + 14; rowHeight = Math.max(rowHeight, height);
          return w;
        };
        const map = place(new SimpleUSAMapIconWdgt(Color.create(183, 183, 183)), 230, 145);
        const text = new TextWdgt('insert text here');
        text.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP;
        text.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN;
        text.alignMiddle(); text.alignLeft();
        place(text, 150, 75);
        for (const [group, classNames] of Object.entries(GROUPS))
          for (const className of classNames) place(new window[className](), set[group][0], set[group][1]);
        // a second pin ON the map, where a person would put one
        const pin = new MapPinIconWdgt();
        container.add(pin);
        pin._applyBounds(map.position().add(new Point(150, 40)), new Point(set.pin[0], set.pin[1]));
        return { left: frame.left(), top: frame.top(), width: frame.width(), usedHeight: (container.top() - frame.top()) + y + rowHeight + 20 };
      }, set, GROUPS);
      await wait(900);
      const file = name + '.png';
      await page.screenshot({ path: path.join(outDir, file), clip: { x: canvasBox.x + clip.left, y: canvasBox.y + clip.top, width: clip.width, height: Math.min(clip.usedHeight, 980) } });
      shots.push({ name, file, set });
      console.log('rendered ' + name + '  ' + clip.width + 'x' + Math.min(clip.usedHeight, 980));
      await page.close();
    }
  } finally { await browser.close(); }
  const cell = (p) => p[0] + ' × ' + p[1];
  const rows = shots.map((s) => `<h2>${s.set.title}</h2><p class="sizes">rectangle ${cell(s.set.rectangle)} · map pin ${cell(s.set.pin)} · speech bubble ${cell(s.set.bubble)} · explosion, scratch area, flora, scooter, heart ${cell(s.set.smallIcons)} · the two logos ${cell(s.set.logos)} · vaporwave background ${cell(s.set.background)} · vaporwave sun ${cell(s.set.sun)} · the eight arrows ${cell(s.set.arrows)}</p><img src="out/${s.file}">`).join('\n');
  fs.writeFileSync(path.resolve(__dirname, 'review.html'), `<!doctype html><meta charset="utf-8"><title>Template sizes</title>
<style>body{font:15px/1.45 -apple-system,sans-serif;max-width:800px;margin:24px auto;padding:0 12px;color:#222}h2{margin:34px 0 4px;font-size:18px}.sizes{margin:0 0 8px;color:#555}img{max-width:100%;border:1px solid #ccc}</style>
<h1>What size should a toolbar's Template come out at?</h1>
<p>Each picture is a Slides Maker window. The map (230 × 145) and the text box (150 × 75) are what the creator buttons make today and do not change; everything after them is a Template at the set's size, in toolbar order, with a second map pin dropped on the map.</p>
${rows}`);
  console.log('wrote ' + path.resolve(__dirname, 'review.html'));
})().catch((e) => { console.error('RENDER FAILED', e); process.exit(1); });
```

## Appendix B — the mechanism as a page plant (the prototype of §4 and the suite measurement of Phase 4)

Pass it to any runner with `--prelude=<absolute path>`. It emulates Phase 2 on an UNCHANGED build (it reads
the size off the widget's old field, so it is of no use once Phase 2 has landed).

```js
(function () {
  var timer = setInterval(function () {
    if (!(window.GlassBoxTopWdgt && window.GlassBoxBottomWdgt && window.CreatorWdgt && window.CreatorButtonWdgt)) return;
    if (!(GlassBoxTopWdgt.prototype.findRootForGrab && GlassBoxBottomWdgt.prototype.glassBoxItem && CreatorWdgt.prototype.activated)) return;
    clearInterval(timer);
    GlassBoxBottomWdgt.prototype.copyOfMyToolToHandOut = function () {
      var tool = this.glassBoxItem();
      var copy = tool.fullCopy();
      if (copy == null) return undefined;
      copy.isTemplate = false;
      copy.setExtent(tool.extentToGetWhenDraggedFromGlassBox);
      return copy;
    };
    GlassBoxTopWdgt.prototype._createWidgetToBeHandled = function () { return this.parent.copyOfMyToolToHandOut(); };
    delete GlassBoxTopWdgt.prototype.findRootForGrab;
    CreatorWdgt.prototype.grabbedWidgetSwitcheroo = function () { return this._createWidgetToBeHandled(); };
    CreatorWdgt.prototype.grabsToParentWhenDragged = function () { return false; };
    console.log('PLANT installed: the lid hands out one copy for a click and a drag');
  }, 2);
})();
```

---

## BACKLOG ledger

- **Re-homed at authoring (2026-11-23)** from the section of `archive/toolbar-band-depth-plan.md`, where it
  was filed as an owner question; the owner answered it the same day (a click places what a drag places)
  and this plan carries the work. Its text as it stood: "**A Template placed by a CLICK on its lid takes its
  thumbnail's size** — 32 × 32 since the mark box (44 × 44 before), where a drag inflates it to its own size
  (50 × 40, a speech bubble 105 × 80): should a click place what a drag places? (`GlassBoxTopWdgt`; owner
  question) — reachable, low."
- Noted, not queued: a lidless tool in a cell (a text or sheet property button, a paint tool) is marked
  `isTemplate`, yet no drag ever grabs it (§1.5); after this plan the mark on a LIDDED tool is read by the
  hand only if its cell has lost its lid.
- Noted, not queued: `SampleDashboardApp` and `SampleSlideApp` build their map pins directly, at the 50 × 40
  birth box, so a sample's pin and a toolbar's pin may differ in box (never in picture) once Phase 3 lands.
- **CLOSED 2026-11-23** by this plan (Phases 1-5, see the execution ledger below). Its index line as it stood:
  "**A Template comes out of its tool cell at two sizes** — a click places 32 × 32, a drag 50 × 40 (the birth
  default; a speech bubble 105 × 80), and a copy put back into a toolbar forgets its new size — Slides and
  Dashboards toolbars, low." A click and a drag now take the cell's one copy, at the size the tool came into
  the cell at (the class's `toolExtent` for a toolbar's own roster, the owner's Candidate B), and a copy put back
  into a toolbar comes out at the size it went in at.

## Execution ledger (2026-11-23, one session) — deviations from this plan, and what each answered

- **Phase 0.** The renderer's window was widened from 780 to 1000 px (`render-candidates.js`): at 780 the
  harness world, 880 px tall, cut the last three arrows of set B. The owner chose **Candidate B** for every
  group (Phase 3's table).
- **Phase 1, Test 1.** The plan's "the two copies' text children have the same extent" is two LITERAL
  assertions, one per copy (each text child at the bubble's measured layout), so step 3 keeps passing on the
  unchanged build whatever step 2 found. The second toolbar is filled before its window opens: opened empty, a
  hugging window does not re-hug a cell added later and shows a scroll indicator, which is no part of this test.
  Seen failing on the unchanged build exactly as §7 says (click `32,32`, text `20,14`; re-entry drag `105,80`,
  click `32,32`); step 3 passed.
- **Phase 2.** Every gate answered by its class, as predicted: `determineGrabs` recorded 37 -> 41, the
  `instanceof-type-test` baseline 64 -> 63, `SETTLING_CALL_MARKER_CEILING` lowered 19 -> 18; one source comment
  reworded for `comment-narration`. Test 2 was seen failing with the `INPUT_ERROR … _resolvePickUpFigure` line
  after step 4, and passing after step 5. An extra presuite after Phase 2 (mechanism only, no sizes) failed only
  `SystemTest_macroToolbarChevronPopsOverflow` and the two new tests (no references yet).
- **The finger finding (owner ruled 2026-11-23: fix it in this arc).** Under `--pointer=finger`, Test 2 failed
  on "the person is told why, once": a finger's drag is a hold, then a slide, and the slide's sweep of the hold's
  menu (`cleanupMenuWdgts … alsoKillFreshMenus: true`) took every fresh pop-up, the refusal message the slide's
  own lift had just raised included (`determineGrabs` runs before `_advancePressAndHoldRecognition` in a move).
  Measured with a logging plant; present on the unchanged build too. Fixed in `ActivePointerWdgt`: the hold
  books the pop-up its menu request opened (`_pressHoldMenu`, forgotten with the hand's other bookings), and the
  lift sweeps naming that menu alone (`cleanupMenuWdgts`'s new `alsoKillTheseFreshMenus`). Implemented in
  source directly rather than first as a plant, since nothing is committed before the owner reviews it;
  `_advancePressAndHoldRecognition` recorded 29 -> 32. Test 2 under the finger is its proof (failing before,
  passing after); `docs/architecture/input-and-gestures.md` describes the hold's lift.
- **Phase 3.** Test 1's third sized tool is the north arrow of a floating DASHBOARDS toolbar: in the floating
  Slides column the arrows stand behind the overflow chevron, where no cell can be dragged. The speech bubble
  moved to 130 x 100, so `SystemTest_macroTemplateDraggedOutOfToolbarInflates` states 130 x 100 at (635, 350).
- **Phase 5, beyond its list.** `docs/architecture/input-and-gestures.md` also described the glass-box inflate
  (rewritten); `docs/plans/creation-and-templates-plan.md` said `CreatorButtonWdgt` extends `Widget` (it
  extends `CreatorWdgt`). `check-doc-narration.js` reports both CLAUDE.md files under their recorded ceilings,
  a gain from an earlier arc; not banked here.
- Noted, not queued: a Template whose cell has lost its lid (dev mode's Destroy on the lid) is pressed itself,
  and its drag takes the hand's Template arm, which no longer resizes: its copy leaves at the thumbnail's size.
  Dev mode only.
- **Close (2026-11-23).** `fg gauntlet` 20/20 PASS (1609 s, no load-flake retry); `fg homepage` OK on its second
  run: the first died creating its page (`ProtocolError: Network.enable timed out`, the smoke's own
  RULELESS_FAILURE, nothing measured) while Spotlight re-indexed the twice-rebuilt tree at a 1-minute load of 100.
  Recaptured, mouse and finger, dpr 1 and 2, each `RECAPTURE COMPLETE`: the three tests this plan predicted
  (`SystemTest_macroToolbarChevronPopsOverflow` images 3-4, `SystemTest_macroTemplateDraggedOutOfToolbarInflates`,
  and `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly` images 2-3: a rectangle's member list one row
  longer), each seen on the diff page first. The two new tests' mouse and finger references are byte-identical,
  after their toolbar moved from x 40 to x 300: at 40 a 200-wide copy was fitted inside the desktop as it was
  lifted, at a place the mouse (628) and the finger (622) disagreed on.

# The editing residue — text slots, keys, menus, view mode and windows, fixed in one unattended loop

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
AUTHORED 2026-11-18 against Fizzygum master `4f2f4b6f` and Fizzygum-tests master `9cf50d778` (409 SystemTests,
build FRESH). Executed by an UNATTENDED loop whose process (the per-unit cycle, the grants, the park and stop rules,
the LEDGER) is `Fizzygum-tests/.scratch/overnight-editing-residue/BRIEF.md`. This document is the WHAT: each unit's
facts, ruled design, tests, predicted pixel set and proof.

**Mandate: eliminate each defect at its cause.** Every unit names the mechanism that is wrong and replaces it; none
hides a symptom. Where one cause serves several items, one change serves them all (U1, U6, U7).

Status:

| Unit | Item | Status |
|---|---|---|
| U1 | The caret steps over a character whole (emoji, the smiley) | CLOSED 2026-11-18 (§U1) |
| U2 | The caret's remembered column is derived from its vertical run | CLOSED 2026-11-18 (§U2) |
| U3 | Line ends, document ends and word jumps follow the keyboard's platform | CLOSED 2026-11-18 (§U3) |
| U4 | A text menu shows its state as ticks; every editing row tested | CLOSED 2026-11-19 (§U4) |
| U5 | A pinned copy of the toolbar's Fonts menu greys with its tool | CLOSED 2026-11-19 (§U5) |
| U6 | Folders, the bin and their links hold a fixed edit mode | CLOSED 2026-11-19 (§U6) |
| U7 | View mode reaches every drop and the selection ring | CLOSED 2026-11-19 (§U7) |
| U8 | A mode flip repaints a hosted widget's grip | CLOSED 2026-11-19 (§U8) |
| U9 | A person's grip drag keeps a window's title strip whole | LANDED 2026-11-19 (§U9) |
| U10 | The logo tool's overflow row is pictured live | OPEN |
| U11 | A copy of a pinned wire menu drives the real wire | OPEN |
| U12 | The U3 off-screen test judges the drag-out look under both pointers | OPEN |
| U13 | Close: this plan archived, or left open with what parked | OPEN |

---

## 0. Orientation

**Fizzygum** is a CoffeeScript GUI framework rendered on one `<canvas>`: windows, a desktop, drag and drop, live
editing tools. Three sibling repos under a directory named `Fizzygum-all`: `Fizzygum/` (source + build),
`Fizzygum-tests/` (the macro SystemTest suite and its Node rigs), `Fizzygum-builds/` (generated). Read
`Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md` first; both route to deeper docs.

**The prior arc.** `docs/archive/toolbar-arc-residue-plan.md` (CLOSED 2026-11-18) fixed the toolbar arc's eight
residual items in one overnight loop plus two units after it. It filed items on the way (BACKLOG, its section) and
left three test gaps in its LEDGER. On 2026-11-18 the owner ruled on the ones that needed a decision and asked for
ONE more unattended loop over everything that no longer needs one, plus a new bug they observed (emoji). That is
this plan. One filed item is deliberately NOT here: "A widget's base context menu still acts on view-mode content"
awaits the owner's row-by-row ruling.

**Research.** Four read-only research passes (2026-11-18) reproduced every item on the build, root-caused each, and
checked each recommended fix by planting it in the page. Their reports and probes are under
`Fizzygum-tests/.scratch/overnight-editing-residue/research/` (gitignored, on this machine):
- `R1-text/R1-text.md` (U1 C, U2 A, U3 B), with `c-plant.js`, `b-plant.js`, drafts `TextSlots-draft.coffee`,
  `C-methods-draft.coffee`, `CaretWdgt-B-draft.coffee`, and `bite-plants/`;
- `R2-menus/R2-menus.md` (U4 J+L, U5 I, U11 H), with `r2-plants.js` and the measured suite forecast
  `forecast-JIH-mouse.log`, `fails-JIH.txt`;
- `R3-viewmode/R3-viewmode.md` (U7 G+F, U8 M), with `plants/forward-FGM-fix-prelude.js` and
  `plants/R3-forecast-prelude.js`;
- `R4-pictures-windows/R4-pictures-windows.md` (U10 D, U9 E, U12 K), with `D/`, `E/` plants.
- `owner-folder/folder-mode.js` (U6's one measured fact, below).
Each unit cites its report's sections. **The report is the authority for code shapes, file:line and probes;
re-grep every symbol before editing (lines drift).** Where a unit rules differently from its report, this plan wins.

> **THE CRITICAL REFRAMES (what research found).**
> - U1: the owner's guess holds and reaches further: EVERY slot reader (move, delete, click, selection, crop, mask)
>   counts UTF-16 units. A slot must stay a UTF-16 offset (every `slice` keeps working) that may only stand between
>   GRAPHEME clusters; code points are not enough (☹️, one of the SW font's own emoji aliases, would still split).
> - U2: the remembered column cannot be fixed by remembering at more sites; it must be DERIVED from the vertical run.
> - U4: ticks need ANNOUNCEMENTS: today no style setter but the font's announces, so a tick row would never move,
>   even after its own press (measured).
> - U6: a folder window offers the pencil today, and in view mode it refuses every drop (measured,
>   `owner-folder/folder-mode.js`: `dropBefore true`, `dropAfterFlip false`), defeating a folder's job.
> - U11: worse than filed: a copy made while a wire tracks, pressed on "Follows it too", cuts the REAL wire's back
>   link; the slider silently stops following.
> - U12: the masking repaint is the mouse leaving the docked bar's scroll band (`ViewportWdgt.hoverExited`), folded
>   into the drag's first cycle; the gap is the macro's, not inherent.

## 0.5 Cold-execution protocol

1. The loop's process is `BRIEF.md` (beside the research dir). Read it whole before this plan's units.
2. `/Users/davidedellacasa/code/Fizzygum-all/fg status` (by absolute path, never `./fg`): both repos clean and level
   with origin, build FRESH.
3. Units run in the table's order (§U-order explains why). A PARKED unit does not stop the loop; a unit that needs a
   parked one follows its own "if parked" line or waits on it.
4. Per unit: read its section here, then its report sections, then the code. Re-verify every fact a step relies on.
5. Commands: `fg build`, `fg presuite`, the finger suite (`node scripts/run-all-headless.js --pointer=finger` from
   `Fizzygum-tests/`), `fg diffpage`, `fg recapture --auto --dprs=1,2` (then `--pointer=finger`), `fg gauntlet`.
   Long ops run ONCE in the background with a log, never piped through a filter.

## 1. Rulings

**Owner (2026-11-18), verbatim in substance:**
- **Emoji (U1):** "caret movement around emojis is wrong … moving around emojis and also deleting them does odd
  things, likely because str.length gives the count of UTF-16 units. Verify, investigate, root cause and fix this
  ELEGANTLY."
- **Keys (U3):** follow each platform's convention, and add word jumps. Mac: Cmd+Left/Right to the line's ends,
  Cmd+Up/Down to the document's ends, Option+Left/Right word jumps. PC (Windows and Linux): Home/End line ends,
  Ctrl+Home/End document ends, Ctrl+Left/Right word jumps. Shift extends the selection with each. **Strict, no Emacs
  keys:** on a Mac only Cmd+A/Z select all and undo (Ctrl+A/Z do nothing in a text); on a PC only Ctrl+A/Z.
- **Tick rows (U4):** a text menu's label-swap rows become single rows showing a tick: a state is drawn as a tick,
  the label stays plain wording; "Bold" ticked while the text is bold; all three alignment rows shown with the
  current one ticked.
- **Fixed edit mode (U6):** folders and the bin are always in edit mode, with no toggle displayed: it is their job to
  accept drops and have things picked up from them; implement the concept cleanly. Links to them in view-mode content
  keep taking drops.
- **Strip floor (U9):** a person's grip drag of a free-floating window stops where the title strip's close, collapse
  and pencil stay whole, derived from the strip, through U4's seam (archived plan §U4), never a constant, never
  `minimumExtent`; code can still force any size. **Titled strips only:** toolbar windows (no title, strip on the
  short side) are not floored.
- **Left out:** the base context menu's view-mode rows (later, row by row).

**Ruled by the planning session from the owner's principles** (clean, minimal, uniform; ONE of each thing; derived
over pushed; reuse the existing mechanism). The loop lists them in the LEDGER digest under "Rulings for your second
look":
- U1 (R1 Q1, Q2, Q9, Q10): a hidden password shows one asterisk per CHARACTER; Backspace deletes a whole grapheme on
  every platform; `Intl.Segmenter` is required, with no code-point fallback (ONE definition); the password-caret
  drift and the named-key typing (C.1) ride in U1, since one definition fixes them.
- U1/U3 (R1 Q3): a WORD is a run of characters each beginning with a letter, a digit or `_` (`[\p{L}\p{N}_]`), so an
  identifier in a code pane is one word; 😀 separates words. (R1 proposed letters and digits; `_` added for code.)
- U3 (R1 Q4): word jumps land by each family's convention: Mac's Option+Right at the END of the word; PC's Ctrl+Right
  at the START of the next word (Windows'); both lefts at the word's start.
- U3 (R1 Q8): while a text is being edited, every key the caret acts on has its browser default prevented (so
  Cmd+Left never navigates Back; Alt+Left on a PC, which the caret reads as Left, does not either).
- U3 (R1 Q6, Q7): Ctrl+Y redo and the delete-word/delete-to-line-start chords are NOT in this plan: filed.
- U4 (R2 §Q 1–4, 6): keep "Hide characters"; the too-small fitting row is "→← Shrink to fit" (ticked while
  SCALEDOWN), beside "←→ Expand to fill" (ticked while SCALEUP); keep the glyph prefixes (label wording); accept a
  tick for a one-of-three choice and the reserved tick column; extend the U7 test with a phase B.
- U7 (R3 questions 2–5): the Degrees Converter's formula boxes stop being ringed in view mode; a nested window focused
  through its gutter inside a view-mode outer is not ringed (its content still is); the reluctant lock badge keeps
  naming the document; an empty window in view-mode content refuses drops.
- U10: the speech-bubble tool's row picture (cold-glyph boxes, and a 9 px "ell" crop even warm) is FILED for a later
  design, not fixed here (R4 §D9 Q1: no existing mechanism reaches a tool with children). The owner has the question.

## U-order — why this order

U1 first: it creates `TextSlots`, which U3's word jumps need, and it edits the caret methods U2 then simplifies
(R1 §0). U2, then U3. U4 before U5 and U11 (all three touch menu rows; U11 changes the shared
`MenuRowReflectionSpec` record, so it goes last among them). U6 before U7: U7's drop door must already find links and
folders answering their fixed mode, or links would refuse drops in view-mode content between the two commits. U6
before U9: folder windows lose the pencil, which U9's floor reads. U8, U10 and U12 are independent and small.

---

## U1 — The caret steps over a character whole (R1 §C)

**Facts (R1 §C.1–C.3).** Right/Left stop inside 😀; Backspace leaves half of it (drawn as a black box); a click
never lands just after it; a selection across it draws two plates that hide the next letter; crops can cut it; the
password mask shows two stars for it. Also: a password `StringWdgt`'s caret is placed by the hidden text, not the
asterisks; a named key types its name ("PageDown", Option+e "Dead"). The SW fonts draw 😊😀😃 as ☺ and 😢☹️ as ☹.

**Fix (R1 §C.4).** A new class `src/TextSlots.coffee` (core, beside `TextEditingState.coffee`; class-side members
only, the `Utils` shape): the ONE definition of where a caret may stand and how it steps. A slot stays a UTF-16
offset that falls between grapheme clusters (`Intl.Segmenter`, made lazily — a class-level `new Intl.Segmenter`
trips the boot scanner's `CONSTRUCTION_IN_CLASS_DECLARATION`). Members: `characters`, `slotsOf`, `count`, `isSlot`,
`slotAfter`, `slotBefore`, `isWordCharacter` (§1's word: letters, digits, `_`), `wordAround`. About 15 readers route
through it (the full list: R1 §C.3; draft `C-methods-draft.coffee`). `processKeyDown`'s one-character test goes in a
`_typeKey` member (else its complexity rises past its record 30, R1 §C.8).

**Test.** `SystemTest_macroCaretStepsOverTheSmileyWhole` (R1 §C.6), both pointers; bite plants in
`R1-text/bite-plants/`.

**Predicted pixel set.** EXACTLY `SystemTest_macroStringWdgtHideCharactersMasksTextNotEditing` image_3 (dpr 1 and 2,
mouse and finger, 4 files): the caret moves to the asterisks' width. No inspector churn (R1 §C.7).

**Docs.** The text docs that name a slot (grep `slot` in `docs/architecture/`); `MACRO-PATTERNS.md` on typing an
emoji; DETERMINISM.md if the segmenter's engine agreement is worth a line (R1 §C.4: identical on 13 probes).

Time box 3.5 h.

**Landed 2026-11-18.** `src/TextSlots.coffee` (core, class-side only) is the one definition: `spansOf`, `slotsOf`,
`characters`, `count`, `isOneCharacter`, `slotAtOrBefore`, `slotAtOrAfter`, `isSlot`, `slotAfter`, `slotBefore`,
`isWordCharacter` (`[\p{L}\p{N}_]`), `wordAround`, over a lazily made grapheme `Intl.Segmenter`. Every reader of §C.3
asks it; `_gotoSlotNoSettle` reports `INVARIANT_VIOLATED` for a slot inside a character and stands at its start; and,
from the unit's review, every PRODUCER of a slot answers one: the hit test, a string's line end and select-all
(`slotAtOrBefore`: a crop's ellipsis can hide a character longer than itself, as in a sheet cell's editor), a
wrapped line's end (a "\r\n" is one character), Backspace (its neighbours can join into one, two flag halves) and
the insert's advance (`slotAtOrAfter`: a typed flag half joins the one after it). `goRight` lost `howMany` (the
insert advances by the typed length); `String::isLetter` is deleted; `_drawTextLine` strips the invisible character at the
one line-draw seam (TextWdgt passes its line bare), and `eliminateInvisibleCharacter` strips every one. Ruled here:
`isOneCharacter` is a `TextSlots` member (the caret's `_typeKey` and the sheet's `_isPrintable` share it); `spansOf` is
kept beside `slotsOf` (the hit test and the selection paint walk pairs); `_typeKey` is sanctioned as the
keystroke dispatcher, as `_ctrl` is. The character at an offset is found by WALKING the segments
(`TextSlots._characterAt`), never by the segments' `containing`: the first gauntlet failed both WebKit legs on the
new test alone, and WebKit 26.4's `containing(2)` on "ab😀 cd_2" answers the "b" three units long (measured; its
iteration is right, which is all R1 had compared). The call-separation [U] query baseline banked 104 → 103 (the
new test reads `searchLongestFittingTextByMultiCroppingIt` from outside). Evidence: the new test passes under both
pointers, its follower is clean, and twelve plants each fail it under both pointers (slots by unit, hit test by
unit, mask by unit, crop by unit, coordinates by the stored text, a named key typing, a word of letters only, the
undo dedupe by unit, and no snap on the typed join, the Backspace join, a crop's shown end and a CRLF line end); the
crop plant needed R1's mixed text `a😀b😀c😀😀d😀` at every width (eight smileys alone never cut one in half). The presuite and the
finger suite failed exactly the predicted `HideCharacters` image_3; its diff is the caret moving from the hidden letters' width to
the asterisks'. The review's fix to `selectAll` then moved two churn-set tests that SHOW that method's source in an
inspector's code pane (`InspectorCodePaneRunsAgainstItsSubject` image_3, `InspectorResizingOKEvenWhenTakenApart`
image_2 and image_3): the shown line, and in the first a right-click at the code text's centre, which widens with it.
Commits: Fizzygum `3220143b`, Fizzygum-tests `ba196f192`, each titled "Text: a caret steps over a character whole …".

## U2 — The caret's remembered column is derived (R1 §A)

**Facts (R1 §A.1–A.2).** Five stale paths: double-click, triple-click, delete of a selection, Up collapsing a
selection, undo. The column is a field the moves must remember to set.

**Fix (R1 §A.3).** The caret keeps its VERTICAL RUN (`_verticalRun`: where the last Up/Down landed, in which text,
the column it keeps); a vertical move continues the run only while the caret stands where it left it, in the same
text; any other move breaks it without saying so. `TextWdgt.upFrom`/`downFrom` take the column slot as an argument.
Delete `rememberCaretColumn`, `caretHorizPositionForVertMovement`, their five calls and the comment that explains
them. `goUp` and `goDown` share one core.

**Test.** `SystemTest_macroUpAndDownLandUnderTheCaretAfterAnyMove` (R1 §A.5), values only, both pointers.

**Predicted pixel set.** Behaviour: none. Inspector churn: the tests of `scripts/inspector-churn-set.json` that show
`StringWdgt`'s members — R1 §A.6 lists up to 12; the loop confirms the set before the presuite.

**Needs:** U1 CLOSED or PARKED (if parked: re-derive the edit list on the untouched methods).

Time box 1.5 h.

**Landed 2026-11-18.** `CaretWdgt._verticalRun` ({text, columnSlot}), `_columnForVerticalMove` and one core
`_goVerticallyNoSettle shift, up`; `goUp`/`goDown` are thin self-settling wrappers, as `goLeft`/`goRight` are (a private
core may not call the self-settling `gotoSlot`). Every placement ENDS the run (`_gotoSlotNoSettle`, the funnel every
caret move passes) and the core starts it again after its own move, so any other move or edit ends it without saying
so -- the review found the first shape (the run went on while the caret stood where it had landed) let End, Left then
Right, x then Backspace or x then undo at the landing slot keep a stale column, and the test (every case began with a
click, which builds a new caret) could not see it. `TextWdgt.upFrom`/`downFrom` take the column slot; `StringWdgt`'s
single-line pair takes and ignores it. `rememberCaretColumn`, `caretHorizPositionForVertMovement`, their six calls (the
caret's Left, Right, Home, End, insert and Backspace) and the click's call are deleted. Evidence: the new
`SystemTest_macroUpAndDownLandUnderTheCaretAfterAnyMove` (a monospace three-line text; six moves after a run at
column 2; the run down and back up across a short line; four key moves that end where a Down left the caret)
passes under both pointers and WebKit, its follower is clean, and three plants fail it under both pointers (a column
kept per text across carets, the old storage, fails the move cases; a run forgetting its column fails the run down
and up; a run surviving placements fails the four key moves). Pixel set predicted by MEASUREMENT before the code was written (`u2/forecast-members-gone.js`: the two
`StringWdgt` members hidden from every member list, behaviour kept): 7 churn tests, 20 shots; the presuite failed
exactly those. Commits: Fizzygum `4aa89b4b`, Fizzygum-tests `d2fee7405`, each titled "Text: Up and Down take their
column from the caret's run …".

## U3 — Line ends, document ends and word jumps follow the keyboard's platform (R1 §B)

**Fix (R1 §B.3, with §1's rulings).**
- A boot fact `?keys=mac|pc` (else the platform's: Mac/iPhone/iPad/iPod → mac, every other → pc), parsed beside
  `?pointer=` in `src/boot/globalFunctions.coffee`.
- Its home is the person: `User.keyboardFamily`, set from the boot fact, never serialized.
- ONE table of chord → caret verb per family, class-side on `CaretWdgt`, read by `processKeyDown` and by the input
  bridge that prevents the browser's default. Strict per §1: mac `Meta+…` only, pc `Ctrl+…` only; Home and End
  stay in the shared switch. Word-right per family (§1): mac to the word's end (`TextSlots.wordEndAfter`), pc to the
  next word's start (`TextSlots.wordStartAfter`); word-left to the word's start (`wordStartBefore`).
- New caret verbs `goDocumentStart`, `goDocumentEnd`, `goWordLeft`, `goWordRight` (mac) and its pc twin,
  `selectAll`, all through ONE helper `_jumpTo slot, shift` that `goHome`/`goEnd` reuse. Delete `_ctrl`, `cmd`, and
  `cmd`'s line in `buildSystem/public-api-allowlist.txt`.
- The suite pin: `WorldTestSupport._afterWorldResetNoSettle` sets `world.user.keyboardFamily = "mac"` (the suite's
  keyboard is a Mac's as its screen is 1920×880); a test exercises pc by setting the field.
- §1: while a caret edits, every key the caret acts on has its browser default prevented.

**Test.** `SystemTest_macroCaretJumpsFollowTheKeyboardFamily` (R1 §B.6), values only, both pointers; both families
exercised; plants: the table's pc row swapped, `_jumpTo`'s selection update dropped, the pin removed.

**Predicted pixel set.** EMPTY (R1 §B.7). **Not checkable headless:** whether preventing the default stops a headed
Chrome's Back on Cmd+Left — record it in the digest for the owner's hand check.

**Needs:** U1 CLOSED (`TextSlots`); U1 PARKED ⇒ U3 parks.

Time box 3 h.

**Landed 2026-11-18.** The boot stashes `?keys=` raw (`window.FIZZYGUM_KEYS`, as `?pointer=` is) and the person derives
the family (`User.keyboardFamily` from `User.keyboardFamilyOfThisPage`). ONE definition, `CaretWdgt.verbFor`, reads
`chordVerbs[family]` (the plan's table, with word-right `goWordEnd` on a Mac, `goNextWordStart` on a PC) and then
`keyVerbs` (every family's arrows, Home and End, with any modifier but Ctrl or Cmd); `processKeyDown` and the browser
bridge both read it, the bridge through `_caretActsOnAsCommand`, which its canvas listener
(`_keydownDefaultIsPrevented`, extracted with its old Backspace, space and Tab rules) and the virtual keyboard's
input listener both ask (the review found the second one missed). One jump core `_jumpToNoSettle`; goHome, goEnd, goDocumentStart, goDocumentEnd, goWordStart,
goWordEnd, goNextWordStart are thin self-settling wrappers, selectAll asks the target. `TextSlots` walks a text's
words once (`_wordWalk`, starting at the slot at or before the one asked: a stale slot clamps, as the arrows
do) for `wordAround` and the three jumps. `_ctrl` and `cmd` are deleted, and the call-separation
allowlist lost seven entries (`cmd`; goHome, goEnd, goLeft, goRight, goUp, goDown, which the tables' strings now
name) and gained none. The first cut raised two complexity records (the boot function 30 → 33, the keydown
listener 19 → 22); restructured instead (the raw stash; the extracted method), both fell: the listener's record is
deleted, `processKeyDown`'s is 27. Ruled here: the verb names (by what they do) and `keyVerbs` as the shared table
the bridge's "every key the caret acts on" reads (typing never prevented). Evidence: the new
`SystemTest_macroCaretJumpsFollowTheKeyboardFamily` (values only) passes under both pointers and WebKit, its follower
is clean, six plants fail it under both pointers (the family ignored, Shift dropped, a PC page without the suite
pin, a PC's word-right to the end, the bridge never preventing, the bridge ignoring whether a caret is live: the
test reads the bridge's verdict on fake keydowns, an oracle); the presuite and the finger suite were green (the EMPTY
prediction). Filed from the review: AltGr typing on a PC (pre-existing), a sheet's selection-mode Cmd+Left. Hand check for the owner: in a
headed Chrome on a Mac, Cmd+Left in a text must not navigate Back. Commits: Fizzygum `ef925031`, Fizzygum-tests `63a044f84`, each titled "Text: a
caret's line, text and word jumps follow the keyboard family …".

## U4 — A text menu shows its state as ticks; every editing row tested (R2 §J, §L)

**Fix (R2 §J4).** Each label-swap pair becomes one row with a `MenuRowReflectionSpec.tickWhen`, keeping its
`enablement: editable` (U7 of the prior plan): "Bold", "Italic", "Header line", "Hide characters"; all three
horizontal and all three vertical alignment rows; "←→ Expand to fill" (SCALEUP) and "→← Shrink to fit" (SCALEDOWN).
Every `addMenuItem` stays literal. ONE reader per state, 8 public `StringWdgt` readers beside `currentFontName`
(`drawsBold`, `drawsItalic`, `drawsHeaderLine`, `hidesCharacters`, `currentHorizontalAlignment`,
`currentVerticalAlignment`, `currentFittingWhenBoundsTooLarge`, `currentFittingWhenBoundsTooSmall`); the alignment
rows share their axis's reader through `whenValue`. **Every writer announces** (`world.dataflow?.markNonValueChange
@`, only on a change, where the field changes: R2 §J4 lists the eight places), and the dataflow engine's header that
says layout passes have one non-value announcer gains this second one. `SimpleTextWdgt`'s by-label removals lose the
three keys that now match nothing, and its comment is rewritten.

**Tests.**
- New `SystemTest_macroTextMenuShowsItsStateAsTicks` (R2 §J6), both pointers.
- The U7 test gains PHASE B (R2 §L2): a Slides Maker's text box, a plain `TextWdgt` keeping the header-line,
  vertical-alignment and fitting rows; one new shot (image_4); three plants (each row group's enablement dropped).
- Macro edits for retired labels (R2 §J3): `MenuRowKeepsTheSelection` ("Normal weight" → "Bold" on a bold text),
  `ViewModeTextRefusesFloatingBold`, `TextWdgtCaretKeepsCorrectAlignment`, and the U7 test's label list.

**Predicted pixel set (R2 §P, measured with the fix planted).** PIXEL_J_MENU: `FontsMenuFollowsAnApiChange` 1, 2;
`FontsMenuTickTracksSelection` 1, 2; `OverTallMenuScrollsToReachItsLastRow` 2, 3;
`PinnedTextMenuGreysItsEditingRowsInViewMode` 1, 2, 3; `ScrollPanelMergesChildMenu` 1;
`TextMenuOffersOneConnectionBlock` 1; `TextRunRowsReflectSelection` 1, 2, 3; `AttachTargetExcludesClippedWidget` 1
(indirect: the wider menu moves the pointer). PIXEL_J_INSPECTOR: the 7 churn tests R2 §P names (20 shots). Each
shot is 4 files. Re-derive the inspector set if U2 landed first (U2 changes the same lists).

**Docs.** `widget-authoring-guidelines.md` §10: a STATE is a tick, never a label swap (the wording sibling of "a
row's ACTION must not be fixed at build"); `MACRO-PATTERNS.md` (R2 §J4 names the lines); `MenuRowReflectionSpec`'s
header (the text's style and placement tick too). BACKLOG: the label-swap item closes here.

Time box 3.5 h.

**Landed 2026-11-19.** As R2 §J4: every label-swap pair is ONE row ticked by its state (`MenuRowReflectionSpec.tickWhen`
over eight readers beside `currentFontName`: `drawsBold`, `drawsItalic`, `drawsHeaderLine`, `hidesCharacters`,
`currentHorizontalAlignment`, `currentVerticalAlignment`, `currentFittingWhenBoundsTooLarge`,
`currentFittingWhenBoundsTooSmall`), every alignment offered with the current one ticked, each `addMenuItem` literal
with its `enablement`; every writer announces (`markNonValueChange`, only on a change), the weight in its one core
`_setBoldNoSettle` (DataflowEngine's header names it as the second pass-time announcer); `SimpleTextWdgt` lost the
three keys that matched nothing. Measured before the code: the forecast prelude (R2's `plantJ` + `plantAlias`) gave
15 tests / 35 shots, mouse = finger; the presuite failed exactly those plus the new phase-B image_4. Evidence: the
new `SystemTest_macroTextMenuShowsItsStateAsTicks` (one shot) and six plants (no reflection on Bold; the weight, the
horizontal alignment, the header line unannounced; the bold reader reading the slant; the paragraph keeping Header
line), the U7 test's phase B (a Slides Maker's text box; image_4) and three plants (each row group's enablement
dropped), all failing under both pointers; followers clean; WebKit passes. Commits: Fizzygum `b0f447aa`, Fizzygum-tests `616b473da`, each titled
"Menus: a text menu shows its state as ticks …".

## U5 — A pinned copy of the toolbar's Fonts menu greys with its tool (R2 §I)

**Fix (R2 §I4).** One `enablement:` per row in `ChangeFontButtonWdgt`'s Fonts menu:
`MenuRowReflectionSpec.enabledWhile tool, "hasSomethingToActOn", true, announcedBy:` the tool's toolbar (which
re-announces in `ToolbarWdgt.noteToolStatesChanged`). No new method.

**Test.** `SystemTest_macroPinnedToolbarFontsMenuGreysWithItsTool` (R2 §I6), both pointers; screenshots with the
menu clear of everything and its premises. **Predicted pixel set:** EMPTY (R2 §I7).

Time box 1 h.

**Landed 2026-11-19.** As R2 §I4: `ChangeFontButtonWdgt.actOn` builds ONE `MenuRowReflectionSpec.enabledWhile @,
"hasSomethingToActOn", true, announcedBy: @fontSelectionMenuHolder` and hands it to every font row (one record for
many rows, as `StringWdgt._editingRowEnablement`); no new method; the adapter's comment says the row refuses first and
the style door stays as defence; `toolbars.md` §5.3 states the rule beside the overflow rows'. From the review (probed):
a menu outliving its destroyed toolbar read enabled and acted for whoever held the focus, so a destroyed tool has
nothing to act on (`EditorContentPropertyChangerButtonWdgt.hasSomethingToActOn`). Predicted EMPTY, met.
Evidence: the new `SystemTest_macroPinnedToolbarFontsMenuGreysWithItsTool` (one shot: every row greyed, none ticked
— the toolbar mirrors no text while the focus is elsewhere, as R2 §I1 measured) and R2's three plants, each failing
as R2 predicted under both pointers (no enablement and a constant one: the values; no announcer: image_1 alone),
and a fourth for the destroyed tool (step 6); follower clean; WebKit passes. Filed: a copied font tool — a duplicated
window's, with its Fonts menu pinned, or one dragged out of its bar — keeps the original toolbar as its menu holder, so
it re-pops the original's menu, whose rows ask the original tool. Commits: Fizzygum `087bf41c`, Fizzygum-tests `f6002e371`,
each titled "Menus: a pinned toolbar Fonts menu greys with its tool".

## U6 — Folders, the bin and their links hold a fixed edit mode (owner ruling; no research report)

**Facts.** `FrameWdgt.offersEditToggle` offers the pencil when the window's content `providesAmenitiesForEditing`;
`FolderPanelWdgt` inherits `true` from `PanelWdgt`, so a folder window offers it, and flipped to view mode it refuses
every drop (`owner-folder/folder-mode.js`). The bin window (`BinOpenerWdgt` wraps a `BinWdgt`, a plain `Widget`, in a
`FrameWdgt`) offers none today. Links: `DesktopLinkWdgt` (and `BinOpenerWdgt`, which extends it) file a widget
dropped on them; U7's drop door would make them refuse inside view-mode content unless they answer otherwise.

**Concept (ruled by the owner; the shape by this plan).** ONE class-level declaration on the widgets whose JOB is to
take and give up widgets — suggested name `alwaysInEditMode: true` (the unit may choose a better one from the house
vocabulary; record it) — read by the places that decide a mode, and nowhere else:
- `Widget.isInEditMode` answers true for it, whatever its flag;
- `FrameWdgt.offersEditToggle` offers no pencil for a window whose content declares it;
- `Widget.sitsInViewModeContent` treats it as a MODE BOUNDARY, as it treats a window with its own toggle: what
  stands around it does not reach in (a folder window nested in a view-mode document still takes drops), and the
  widget itself answers false (a link inside view-mode content still takes drops);
- the cores that write the mode leave it on (a script's "Disable editing" cannot turn a folder off), and no
  "Enable/Disable editing" menu row is offered for it.
Declared by: the folder's panel (`FolderPanelWdgt`), the bin's content holder (find which widget holds the bin's
items: `BinWdgt.viewport`'s panel), `DesktopLinkWdgt` (links and the bin opener). **Prepare must measure** before
editing: every class that is or contains a folder or bin store (`ExamplesFolderWindowWdgt`, `ShelfWdgt`, the
desktop itself), whether each takes drops by design today, and what a person sees. A class whose role is unclear is
a PARK question, not a ruling.

**Test.** A new value-and-shot test: a folder window shows no pencil (shot); a folder window nested in a view-mode
Docs Maker still takes a drop and gives one up; a folder link and the bin opener inside view-mode content still file
a dropped widget; `isInEditMode` true after a scripted disable. Plants: the declaration ignored by each reader in
turn (one plant per reader).

**Predicted pixel set.** Every shot that shows a folder window's strip loses its pencil: the loop FORECASTS it
before implementing (grep the tests for `FolderWindowWdgt`, `New folder`, folder icons opened, Examples; or a
forecast prelude like `research/d-forecast.js` of the prior loop that lists, at each shot, every showing window whose
`offersEditToggle` would flip). Plus inspector churn if a member is added to a class an inspector shows.

**Docs.** `toolbars.md` §3 ("Which content is in view mode": the fixed-mode boundary); `widget-authoring-guidelines.md`
(the declaration, beside `providesAmenitiesForEditing`).

Time box 3 h.

**Landed 2026-11-19.** Measured first: a folder window's CONTENT is a `ViewportWdgt` holding the `FolderPanelWdgt`
(`FolderWindowWdgt`'s constructor), so the readers that ask a window or its content (the pencil, the walk) cannot see a
declaration on the panel; the folder IS the window class. Declared `alwaysInEditMode: true` (the plan's name) on
`FolderWindowWdgt` (the Examples folder inherits it), `BinWdgt` (the bin window's content), `FolderShortcutWdgt` and
`BinOpenerWdgt` — the links TO folders and the bin, as ruled: `DesktopLinkWdgt` would also have covered app launchers
and document and script shortcuts, which take no drops (the review). `ShelfWdgt` (off-tree, never shown) and the
desktop (the root, never asked) declare nothing. Readers: `FrameWdgt.offersEditToggle` (a folder window offers no
pencil); `Widget.sitsInViewModeContent` (a declared widget answers false; a window holding a fixed mode, itself or in
its content, answers edit mode for its content, bounding only the walk that came through its content, as a window with
its own toggle does — so its chrome, a title or a link's caption, follows the content around it: the review's catch);
the disable cores (`Widget._disableDragsDropsAndEditingNoSettle`, `FrameWdgt`'s) refuse for a declared widget.
`isInEditMode` needs no reader: the cores keep a declared widget's flag on. No "Enable/Disable editing" row needs a
guard: only StretchableWidgetContainerWdgt, StretchablePanelWdgt and VerticalStackViewportWdgt offer it. The ONE ratchet
raise of the unit: `Widget#_disableDragsDropsAndEditingNoSettle` recorded at 16 (was at the ceiling, 15), the guard
belonging in the core that writes the mode. Pixels: forecast with a prelude (`u6/forecast-fixed-mode.js`), 2 tests / 2
shots, mouse = finger (`DesktopShortcutIcons_image_1`, `ExamplesDoorsNameTheirWindows_image_0`: the folder window's
strip loses its pencil); met. Evidence: the new `SystemTest_macroFoldersAndTheBinStayInEditMode` (one shot) and its
plants, one per reader and one for the chrome bound, each failing under both pointers; follower clean; WebKit passes.
Docs: `toolbars.md` §3, `widget-authoring-guidelines.md` §9. Filed (found by the first gauntlet's capstone leg, when the
test opened the bin's window by a press on a bin link's tile): that press places the new window with `_applyBounds`
outside a settle, a careless end-of-cycle push; the test builds the bin's window from code instead. Commits: Fizzygum
`9c5d1076`, Fizzygum-tests `4eb27a35b`, each titled "Folders: folders, the bin and their links stay in edit mode …".

## U7 — View mode reaches every drop and the selection ring (R3 §G, then §F)

**G first (R3 §G).** ONE door: `Widget.wantsDropOfChild` answers `@_acceptsDrops and not @sitsInViewModeContent()`;
`ViewportWdgt` and `CellWdgt` route through `super` (`CellWdgt` declares `_acceptsDrops: true`); U5's
`StretchableCanvasWdgt` override is DELETED as redundant. Links keep taking drops through U6's fixed mode (if U6
PARKED: R3 §G.6's one `DesktopLinkWdgt` override, as the owner ruled links keep taking drops). G's door-open plant
must make the prior plan's two U5 tests fail again.

**Then F (R3 §F).** One early return in `WorldWdgt._widgetBeingEdited` asking `sitsInViewModeContent`; the walk's
own mode test becomes redundant and goes (complexity 14 → 12; equivalence measured on 976 widgets). Three cases
covered, one more than filed: a view-mode Drawings Maker's surface, a bare drawing in a view-mode document, an item
in a bare slide panel in a view-mode document.

**Tests.** R3's designs for G and F, both pointers; bite plants in `R3-viewmode/plants/`.

**Predicted pixel set.** EMPTY (R3 Forecast: 409 tests at dpr 1, mouse, with the fixes planted). The presuite and the
finger suite confirm it on the real change.

**Needs:** U6 CLOSED or PARKED (its fallback above).

Time box 2.5 h.

**Landed 2026-11-19.** As R3 §G.4 and §F.4. G: `Widget.wantsDropOfChild` answers `@_acceptsDrops and not
@sitsInViewModeContent()`; `ViewportWdgt` and `CellWdgt` ask through `super(aWdgt)` (`CellWdgt` declares
`_acceptsDrops: true`); `StretchableCanvasWdgt`'s override is deleted; links take drops through U6's fixed mode, so no
`DesktopLinkWdgt` override. F: `WorldWdgt._widgetBeingEdited` returns undefined for view-mode content before anything
else, and its walk's mode test is gone. No ratchet moved. Evidence: R3's two tests, `SystemTest_macroViewModeContentTakesNoDrop`
and `SystemTest_macroViewModeContentShowsNoSelectionRing` (values only), each with a premise that its targets show whole
(the first runs missed: a rectangle left at its default place, a part clipped by the page), and R3's plants, each failing
exactly as R3 predicted under both pointers: the door opened (G steps 3 and 4, and the toolbar residue's two drop tests,
so their deleted conjuncts are carried by the base), the links' fixed mode removed (rewritten for U6's declaration: G
step 6 only), the shipped ring (F steps 2, 3, 5, 6), view mode through every window (F step 7 only); followers clean;
WebKit passes. Docs: `toolbars.md` §3, `visual-design-system.md` (the selection outline), the drag-embed spec (the accept
predicate, a reluctant ancestor), `src/spreadsheet/CLAUDE.md` (the accept gate). From the review: the ring's walk no
longer asks a container's flag, so a focus inside a bin window nested in a view-mode document (the bin's fixed mode bounds
the view mode) is ringed where it was not — consistent with `editableEditorFocus`, and unmeasured by R3's census, which
predates U6; filed: a widget lifts out of view-mode content but cannot be dropped back (the flip locks only direct
children), and "Edit layout" offers drop slots there. Commits: Fizzygum `d6fed5bf`, Fizzygum-tests `45a5a8878`, each titled "View
mode: content in view mode takes no drop and shows no selection ring …".

## U8 — A mode flip repaints a hosted widget's grip (R3 §M)

**Facts.** A label-button hosted in a sheet cell keeps its liftable-grip paint after the flip to view mode (44 stale
pixels), and stays without it after the flip back, wherever the flip moves nothing near it (a bare sheet in a
Generic panel; a menu opened from the button itself).

**Fix.** An unconditional `@_fullChanged()` in Widget's two mode cores (a conditional one raises the cores'
complexity past the ceiling, R3 §M).

**Test.** R3's design (screenshots, an incremental-vs-full repaint fact underneath), both pointers.
**Predicted pixel set.** EMPTY.

Time box 1.5 h.

**Landed 2026-11-19.** As R3 §M.4: both of Widget's mode cores (`_enableDragsDropsAndEditingNoSettle`,
`_disableDragsDropsAndEditingNoSettle`) call `@_fullChanged()` right after announcing the flip, unconditionally (no
ratchet moved: a call is no branch); the grip's comment (`LabelButtonAppearance._paintLiftableGrip`) says a hosted
payload's grip follows the flip that way. Evidence: R3's `SystemTest_macroViewModeFlipRepaintsAHostedGrip` (values and
the incremental-vs-full repaint oracle of `macroHiddenShadowChildLeavesNoBand`) and R3's plant (the flip's repaint
removed), which fails the two after-the-flip comparisons only, 44 stale pixels each, under both pointers — R3's
measurement; follower clean; WebKit passes; the boot smoke (flips on orphans and during construction now push damage)
passes. From the review: the test also counts the grip's painted rows (24 in edit mode, none in view mode; the plant
leaves 24 stale) and re-asserts after each flip that nothing else repaints the button; and a page picked out of a Generic
panel stays its container's `@contents`, so the window's toggle flips it where it stands, beyond the repaint (probed;
filed). Commits: Fizzygum `5887cf90`, Fizzygum-tests `895f2938c`, each titled "View mode: a mode flip repaints a hosted widget's grip
…".

## U9 — A person's grip drag keeps a window's title strip whole (R4 §E)

**Fix (R4 §E4).** `FrameBarWdgt.shortestStripKeepingEveryPiece` (the inverse of `_pieceNamesThatFit`'s room test for
the whole roster); RENAME `FrameWdgt.smallestExtentKeepingMyBandsUsable` → `smallestExtentKeepingMyControlsUsable`
and fold the strip's floor into it, only for a strip that shows a title (§1); `FrameGripWdgt` asks the new name.
`FrameWdgt`'s method count stays 173 (no raise). Floors (R4 §E1): Docs 170×171; Drawings, Slides, Dashboards, Patch
programming 170×212; Sheets 125×171 (no pencil); Generic panel 170×105; plain window 90×89; view mode 170×105.

**Tests.** R4 §E6's new test (values, both pointers, four plants) and the REWRITE of
`SystemTest_macroGripStopsWhereDockedBarsStayUsable` (it judges the top band on a Sheets Maker and view mode on the
height; the rewrite passes before and after, and U4's three plants still fail it).

**Predicted pixel set.** EMPTY; the suite fails only the U4 test until its rewrite (R4 §E7).

**Docs.** Prose naming the old method (R4 §E4 lists the five places, plus `check-complexity-ratchets.js`'s dated
reason: append "renamed …"); `toolbars.md` §1. BACKLOG: the strip item closes here.

**Needs:** U6 CLOSED or PARKED (folder windows' strips).

Time box 2.5 h.

**Landed 2026-11-19.** As R4 §E4, titled strips only (§1): `FrameBarWdgt.shortestStripKeepingEveryPiece` (the roster's
pieces end to end inside the frame border, the title aside); `FrameWdgt.smallestExtentKeepingMyBandsUsable` RENAMED
`smallestExtentKeepingMyControlsUsable`, its first line flooring a strip that carries a title (`showsText`) along it at
that length and across it at the chrome; `FrameGripWdgt` asks the new name; prose renamed in the five places R4 lists,
the ratchet's dated reason appended. `FrameWdgt`'s method count stays 173. Since U6 a folder window carries no pencil,
so its strip floors it at close and collapse (90). Evidence: R4's `SystemTest_macroGripKeepsTheTitleStripWhole` and four
plants (no strip term, the floor 1 px short, no cross term, every strip floored), failing 12, 11, 3 and 1 assertions
under both pointers, R4's numbers; the R4 revision of `SystemTest_macroGripStopsWhereDockedBarsStayUsable` (the band's run
judged on a Sheets Maker, view mode on the height) passes, and U4's three plants still fail it (17, 7, 3); followers
clean; WebKit passes. One slip of the loop's own rule: two comment edits (MacroToolkit, ToolbarWdgt) went through a
string-replace script, not the Edit tool; their diffs are exactly the intended comment lines. From the review: on every
window whose strip carries a title the strip's cross term equals the bands' (`_chromeHeight`), so no test can bite the
bands' cross term any more; it binds only on an untitled host wearing a band, which no test builds. Filed (R4 §E9 Q1): a
floating toolbar's strip, at the width it is born at, offers close only. Commits: one per repo,
each titled "Windows: a person's grip drag keeps a window's title strip whole …".

## U10 — The logo tool's overflow row is pictured live (R4 §D-i)

**Fix.** A face that types glyphs is pictured live, by the rule the holder already states: `IconAppearance` gains a
class-level `typesGlyphs: false` and the `livePictureOn` body moved up from `TypedFaceIconAppearance` (which declares
`typesGlyphs: true` and loses its own); `FizzygumLogoWithTextIconAppearance` declares `typesGlyphs: true`. The
holder's call is unchanged. Warm, the live picture is byte-identical to the raster (R4 §D4).

**Test.** `SystemTest_macroOverflowRowOfATypedLogoStaysLive` (R4 §D6). **Predicted pixel set.** EMPTY.

**File:** the speech-bubble tool's row picture (§1), one BACKLOG line pointing here; R4 §D4 D-ii holds what a fix
would need.

Time box 1.5 h.

## U11 — A copy of a pinned wire menu drives the real wire (R2 §H)

**Fix (R2 §H4).** The wire menu's rows carry the wire's (target, action) pair, as the wire LIST rows already do, and
tick by asking the controller; `MenuRowReflectionSpec` gains one optional field, `readerArguments`, read by `holds`.
No Duplicator change; a world snapshot round trip comes back correct.

**Test.** `SystemTest_macroCopiedWireMenuDrivesTheRealWire` (R2 §H6), values only, both pointers, including the
tracking-back-link case. **Predicted pixel set.** EMPTY.

**File:** a copied pinned "Layout in stack" menu drives a clone of the layout spec (R2 §H3; needs widget-side doors on
`Widget`, which is at its ceiling); a pinned wire menu's rows after Disconnect stay, unticked, doing nothing (R2 §Q5).

Time box 2 h.

## U12 — The U3 off-screen test judges the drag-out look under both pointers (R4 §K)

**Fix (tests only).** In `SystemTest_macroEditingFollowsAParagraphOffScreen`, move the pointer onto the paragraph as
its own step before the drag, with a mouse-only premise that it rests there. With it the prior plan's plant
`overnight-toolbar-residue/u3/plant-d-no-announcement.js` fails image_3 under BOTH pointers at dpr 1 and 2; unplanted,
the references still match (R4 §K). Update the archived plan's U3 note only through this plan's U12 section (archived
docs are not edited).

**Predicted pixel set.** EMPTY. Time box 1 h.

## U13 — Close

- If every unit CLOSED: `git mv` this plan to `docs/archive/` and stamp it CLOSED with the commits; add its
  `archive/INDEX.md` line, with case law worth keeping from the LEDGER; BACKLOG's section for this plan keeps only the
  items filed on the way.
- If any PARKED: the plan stays in `plans/` with each parked unit's question written into its section, and BACKLOG
  points at it.
- The memory note and its MEMORY.md line, either way.

Time box 1 h.

---

## 2. Verification protocol (every unit)

- `fg build` after each step; `fg presuite`.
- For a unit that changes pixels or input handling, the finger suite at dpr 1.
- The new test passes under both pointers, and FAILS under each of its bite plants (`--prelude=`), one plant per door.
- Its follower is clean on both pointers: `run-sequence-headless.js SystemTest_<new> SystemTest_macroAnalogClockInspectEdit`,
  with zero `WORLD_INVENTORY_` lines.
- The failing set equals the unit's PREDICTED set, inspector churn included. Each diff is checked in `fg diffpage`
  (saved to the unit's scratch dir) and is the fix's own target. Only then `fg recapture --auto --dprs=1,2`, then
  with `--pointer=finger`.
- `fg gauntlet` green (a leg passing only on its serial retry is a load flake ONLY if its log shows nothing this unit
  touches; read it). Then commit and push per BRIEF.md.

## 3. Rejected alternatives — do not re-attempt blind

1. U1 code points instead of graphemes: ☹️ (U+2639 U+FE0F), one of the SW font's own aliases, stays splittable; Right
   stops between two halves that measure the same and Backspace deletes an invisible selector (R1 §C.4).
2. U1 the segmenter's WORD granularity for words: Chrome and WebKit disagree ("foo.bar"); a word is defined in
   `TextSlots` instead (R1 §C.4).
3. U2 adding `rememberCaretColumn` calls at the five stale sites: the next move added forgets it again; a "keep
   column" flag through the `_gotoSlotNoSettle` funnel works with no inspector churn but keeps a stored answer fresh
   by every caller (R1 §A.4: the zero-churn fallback, not chosen: derived over stored).
4. U3 both families' chords everywhere with no platform fact: Ctrl+A (a Mac's line start) and Alt+Left (a PC's
   Back) conflict, against the ruling; `?keys=` passed by every runner: ~10 URL composers, and a hand-opened harness
   page on a PC breaks; per-test metadata applied at construction: trips `WORLD_CONSTRUCTION_DRIFT`; a run-wide
   family axis like `?pointer=`: doubles the suite for a handful of keys (R1 §B.5).
5. U4 a reader per row kind, or a label that re-derives live: the spec's `whenValue` already picks the row, and the
   house rule draws state as a tick (R2 §J5).
6. U7 a helper in the hand's drop climb: `ActivePointerWdgt` 74 → 75 (a raise), misses the viewport's auto-scroll,
   and leaves the question in three places; a holders-only door (panel and viewport): misses the empty window and
   keeps the cell's own question; pushing the flip into nested flags: stored state (R3 §G.5). U7's ring: writing the
   glass's flag at the flip, or asking `editableEditorFocus` (it reads the raw focus and hides an off-screen one)
   (R3 §F.5).
7. U9 flooring toolbar windows: the floor flips axis mid-drag; only 170×170 is stable, every floating toolbar jumps on
   its first grip pixel, six tests' slim toolbars break (R4 §E9, owner: titled strips only).
8. U10 "draw no text when it fits at no size": it blanks visible text in 11 tests (R4 §D5).
9. U11 keeping a `WireSpec` by reference on a deep copy: a copied CONTROLLER would share its records, and a copied
   slider-and-panel pair would drive the original panel; keeping the row's spec by reference: fixes the tick, not the
   action, and is wrong when the source is inside the copy (R2 §H5).
10. U12 accepting the mouse-only gap: the masking repaint is the macro folding a hover exit into the drag's first
    cycle, which a separate move step removes (R4 §K).

## 4. References

- `docs/archive/toolbar-arc-residue-plan.md` (the prior arc; its U1, U3, U4, U5, U6, U7 sections are this plan's
  precedents), `docs/architecture/toolbars.md`, `widget-authoring-guidelines.md`, `visual-design-system.md`,
  `lint-and-static-checks.md`.
- `Fizzygum-tests/DETERMINISM.md`; `src/macros/CLAUDE.md`, `src/macros/MACRO-PATTERNS.md`.
- Research: `Fizzygum-tests/.scratch/overnight-editing-residue/research/` (R1–R4, owner-folder).

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] **A narrow window's own title strip clips its edit toggle** — below ~175 px wide a window's strip shows close and collapse only and its pencil is laid past its edge (a Docs Maker at its grip floor, 125, shows no pencil; measured by the U4 research); not a docked bar, so U4's floor leaves it — reachable, low. — CLOSED 2026-11-19 (overnight loop, U9; filed under `archive/toolbar-arc-residue-plan.md`): a strip carrying a title floors the grip at every piece of its roster (`FrameBarWdgt.shortestStripKeepingEveryPiece`, folded into `FrameWdgt.smallestExtentKeepingMyControlsUsable`); `SystemTest_macroGripKeepsTheTitleStripWhole`.

- [x] **Other bare mode holders in view-mode content still take drops** — only a cell and a drawing's canvas ask the view mode around them, so a slide panel picked up into a Docs Maker, which is then flipped to view mode, still embeds a dropped widget (U5 review, read from code) — reachable, low. — CLOSED 2026-11-19 (overnight loop, U7; filed under `archive/toolbar-arc-residue-plan.md`): one door, `Widget.wantsDropOfChild` = drops on and not `sitsInViewModeContent`; `SystemTest_macroViewModeContentTakesNoDrop`.
- [x] **The selection ring frames a drawing's paint surface after a click in view mode** — the ring asks the clicked glass's own edit flag, which no mode flip writes, so a view-mode Drawings Maker, or a bare drawing in a view-mode document, rings its surface (research C §3.3, U5) — reachable, low. — CLOSED 2026-11-19 (overnight loop, U7; filed under `archive/toolbar-arc-residue-plan.md`): `WorldWdgt._widgetBeingEdited` asks `sitsInViewModeContent` first; `SystemTest_macroViewModeContentShowsNoSelectionRing`.

- [x] **A folder window offers a pencil, and in view mode refuses every drop** — folders and the bin are always in edit mode by the owner's ruling, and links to them keep taking drops in view-mode content (§U6) — reachable, low. — CLOSED 2026-11-19 (overnight loop, U6; filed under `plans/editing-residue-plan.md`): `alwaysInEditMode` on FolderWindowWdgt, BinWdgt and DesktopLinkWdgt, read by `offersEditToggle`, `sitsInViewModeContent` and the disable cores; `SystemTest_macroFoldersAndTheBinStayInEditMode`.

- [x] **A pinned copy of the toolbar's Fonts menu does not grey its rows while the font tool has nothing to act on** — they refuse silently and look enabled (§U7 "Landed") — reachable, low. — CLOSED 2026-11-19 (overnight loop, U5; filed under `archive/toolbar-arc-residue-plan.md`): each row's enablement asks the tool's `hasSomethingToActOn`, announced by its toolbar; `SystemTest_macroPinnedToolbarFontsMenuGreysWithItsTool`.

- [x] **A pinned text menu's label-swap rows keep the wording they were built with** — a pinned menu says "Bold" over a bold text, though its press still toggles (§U7 "Landed") — reachable, low. — CLOSED 2026-11-18 (overnight loop, U4; filed under `archive/toolbar-arc-residue-plan.md`): every label-swap pair is one row ticked by its state, every writer announces; `SystemTest_macroTextMenuShowsItsStateAsTicks`.

- [x] **No keyboard way to a line's ends on a keyboard without Home and End** — `CaretWdgt._ctrl` / `cmd` handle only `a` and `z`, so Cmd+Left/Right (a MacBook has no Home or End key) and Ctrl+Home/End do nothing in a text (found by the U1 review, read from code) — reachable, low. — CLOSED 2026-11-18 (overnight loop, U3; filed under `archive/toolbar-arc-residue-plan.md`): a caret follows its person's keyboard family (`CaretWdgt.verbFor`), with line and text ends and word jumps on a Mac and on a PC; `SystemTest_macroCaretJumpsFollowTheKeyboardFamily`.

- [x] **The caret splits an emoji** — moves, deletes, clicks, selections, crops and the password mask count UTF-16 units, so 😀 is stepped into, half-deleted and masked as two stars (owner report; §U1) — reachable, medium. — CLOSED 2026-11-18 (overnight loop, U1; filed under `plans/editing-residue-plan.md`): `TextSlots`, one definition of a slot (between grapheme clusters), asked by every slot reader; `SystemTest_macroCaretStepsOverTheSmileyWhole`.
- [x] **A caret's remembered column is not set by every caret move** — Home, End, Left and Right set it; a double- or triple-click, a delete of a selection and Up/Down collapsing a selection do not, so the next Up or Down lands under a stale slot (found by the U1 review, read from code) — reachable, low. — CLOSED 2026-11-18 (overnight loop, U2; filed under `archive/toolbar-arc-residue-plan.md`): the column lives only in the caret's vertical run (`CaretWdgt._columnForVerticalMove`), which every other placement ends, never in the text; `SystemTest_macroUpAndDownLandUnderTheCaretAfterAnyMove`.
- [x] **`eliminateInvisibleCharacter` strips only the first marker** — `String.replace` with a string pattern replaces one occurrence, so a text holding two U+2063 is measured with the second. — CLOSED 2026-11-18 (overnight loop, U1; filed under `archive/argument-holes-both-repos-plan.md`): it strips every one (`replaceAll`), and `_drawTextLine` strips them at the one line-draw seam; a password's mask pads with them.

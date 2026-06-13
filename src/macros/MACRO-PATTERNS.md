# Macro reuse patterns (the per-mechanic catalogue)

Worked patterns distilled from the macro tests — **what** framework behaviour each exercises,
**which verbs** drive it, the **test** that demonstrates it, and the **gotchas**. This is the detailed
reference; the lean router is `CLAUDE.md`, the authoring *workflow* is the `/author-macro-test` skill
(`../../../Fizzygum-tests/.claude/skills/author-macro-test/`), and the verb *signatures* are the
doc-comments in `MacroToolkit.coffee`. "No new verb" means the pattern is pure reuse of existing verbs.

Conventions used below: `@x` = a MacroToolkit helper; `world.x` = the live world; a bare `…_InputEvents_Macro`
call is an L3 verb. Drive every USER input through the event queue (`_InputEvents` verbs); only fixture
construction and genuinely-blocked UI triggers (`hide()/show()`, `toggleSoftWrap()`, `world.evaluateString`)
are called directly. See `CLAUDE.md` for those rules.

Byte-equality pairs (the no-op / round-trip idiom many entries below lean on) are ASSERTED IN-RUN, not just
claimed: every within-test "image_A is byte-identical to image_B" MUST call
`@assertScreenshotsIdentical "…_image_A", "…_image_B"` right after the later shot (full image names, earlier
first). The shared reference dataHash in the filenames is corroborating evidence, not the check — without the
assertion a recapture after a regression silently stores two different hashes and the claim evaporates.

---

## Text & caret

- **Caret placement by click** (`macroTextMorph2CaretPlacementByClick`): clicking inside an EDITABLE text places
  `world.caret` at the nearest slot (`StringMorph2.mouseClickLeft`, `:1242`, gated on `@isEditable`). A
  directly-built StringMorph2/TextMorph2 has **`isEditable = false`** (`:43`) — set `txt.isEditable = true` first
  (the demo widgets do). `@moveToAndClickAtFractionOf_InputEvents txt, [fx, fy]` places the caret on the clicked
  line: `[0.02, firstLineFrac]` before the first letter; a click past the last line's end clamps after the last
  letter. Size the widget so the wrapped text FITS (a cropped one opens the "edit:" prompt instead).
- **Caret is alignment-INVARIANT and placement is alignment-AWARE** (`macroTextMorph2CaretPlacementUnderAlignments`): TWO
  complementary halves (the alignment-aware sibling of caret-placement-by-click above, which is LEFT-only), both turning on the
  per-line shift `textHorizontalPosition` (`StringMorph2.coffee:607-614`, switched on `@horizontalAlignment` LEFT/CENTER/RIGHT).
  (1) **INVARIANCE:** once the caret is placed on a character, changing the alignment keeps it on the SAME character — it
  re-renders at its slot with the new shift (`TextMorph2.coffee:515`) and the menu-driven alignment change does NOT stop editing
  (clicking a menu item ABOUT the edited text is the carve-out at `ActivePointerWdgt.coffee:344-349`, so `world.caret` keeps its
  slot). So change alignment via the menu WITHOUT re-clicking and the caret follows the shifting line (image_1..3). (2)
  **AWARENESS:** the SAME fractional click lands on a DIFFERENT character once the line is shifted, because `slotAtSingleLineString`
  SUBTRACTS the shift before resolving the slot (`:791`) — re-click the same `[0.40,0.5]` under right vs the original left placement
  (image_4). Set alignment through the REAL context menu — for a `world.add`-ed widget in dev mode the morph menu is TOP-LEVEL (no
  "a TextMorph2 ➜" wrapper, `Widget.buildContextMenu:2913-2922`); items carry a leading glyph (`"∸ align center"` / `"→ align
  right"`) so match by SUBSTRING: `@openMenuOf_InputEvents txt` → `@moveToItemContainingOfMenuAndClick_InputEvents
  (@getMostRecentlyOpenedMenu()), "align center"`. Build an editable multi-line TextMorph2 (`\n` via `String.fromCharCode 10`)
  with DISTINCT per-line widths so the shift is obvious. GOTCHAS: `isEditable = true`; extent WIDE enough that the longest line
  FITS (else a click opens the "edit:" prompt, not an inline caret); settle (`yield "waitNoInputsOngoing"`) after each alignment
  change before the screenshot (the caret re-shows on the next paint via `gotoSlot`, blink frozen in playback). (Beware: TextMorph2
  has a SECOND, dead `@alignment`/`setAlignmentTo*` system unwired to any menu — drive `@horizontalAlignment` via the `align *`
  items, not that.) No new verb.
- **The caret stays GLUED to its slot through re-layouts — alignment AND style** (`macroTextMorph2CaretKeepsCorrectAlignment`):
  the RE-LAYOUT sibling of the invariance entry above — there the alignment changes under a parked caret; here the TEXT moves
  under it: in a CENTER+MIDDLE aligned TextMorph2 an Enter at the caret adds a line and re-centers the WHOLE block (everything
  shifts up half a line), Backspace re-joins and shifts it back, and an "italic" flip changes the font metrics and re-wraps
  every line — the caret must ride its logical slot through all three (any stale-pixel caret would detach visibly).
  GEOMETRY-FAITHFUL FIXTURE TRICK (reusable): when a recording's count-based selection (here Shift+ArrowDown×13 +
  Shift+ArrowLeft×9) depends on the wrap layout, reproduce the recorded box EXACTLY — `HandleMorph.nonFloatDragging` is
  grab-offset-PRESERVING (`HandleMorph.coffee:212-220`, the new extent is computed from the pointer minus the within-handle
  grab point), so press the recorded FRACTION of the handle (`@pointAtFractionOf cornerHandle, [0.733,0.667]`) and release at
  the recorded destination, and the resulting extent matches the recording to the pixel. Also here: the "font size..." item
  opens a `PromptMorph` (capture it fresh via `@getMostRecentlyOpenedMenu()`) whose field is focused with the caret at the
  END — `@repeatSpecialKey_InputEvents "Shift+ArrowLeft", 2` selects the old 2-digit value, type the new one over it, then
  click "Ok" on the captured prompt (the colour/transparency popup idiom). REP note: absorbs the style-axis sibling recording
  (italic+bold flips under a LEFT-aligned caret) — the italic beat is folded in on the harder centered fixture; bold is the
  same metrics-change rule. No new verb.
- **Caret at and BELOW the last row** (`macroTextMorph2PointingAtLastRow`): the last-row/below-text edge of
  caret-placement-by-click above. `TextMorph2.slotAt` (`:541`) scans wrapped rows by the click's y, then `slotAtRow`
  (`:521`) resolves WITHIN a row per-column (x past the row's end clamps after its last character) — but when the
  computed row is PAST the last wrapped line, the row-overflow guard returns `textPossiblyCroppedToFit.length`: the
  slot after the very last character of the WHOLE text, the x IGNORED. So a click in the background strip below the
  text at a small x produces the IDENTICAL caret (and reference dataHash) as a click far past the last row's end —
  capture both shots and the byte-equality IS the assertion. Fixture: the direct-build caret fixture
  (`isEditable = true`) PLUS `txt.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.FLOAT` — a
  directly-built TextMorph2 defaults to SCALEUP (`TextMorph2.coffee:52`), which would scale the text to fill the box
  and make the below-text strip an unpredictable font-search leftover; FLOAT keeps the natural font so the strip is a
  fixture constant. Author the row-targeting fracs from a first capture (rows ≈ extent/lineCount bands). No new verb.
- **Caret arrow-key navigation** (`macroCaretArrowKeyNavigation`): once `world.caret` is editing, `CaretMorph.processKeyDown`
  (`:62-68`) maps Arrow* to `goLeft/goRight/goUp/goDown` (Left/Right step a slot, wrapping over the soft break;
  Up/Down keep the column, clamping at first/last line). Place the caret (same `isEditable=true` fixture), then
  `@syntheticEventsShortcutsAndSpecialKeys_InputEvents "ArrowUp"` / `@repeatSpecialKey_InputEvents "ArrowDown", n`.
- **Shift-click extends a selection** (`macroShiftClickExtendsSelection`): a plain click drops a FIXED anchor caret;
  each `@shiftClickAtFractionOf_InputEvents txt, [fx,fy]` grows the selection from the anchor to the click point
  (StringMorph2/TextMorph2.mouseClickLeft reads shiftKey → `startSelectionUpToSlot`/`extendSelectionUpToSlot`).
  Gotchas: TextMorph2 softWrap wraps to the WIDGET width (`@width()`, not `maxTextWidth`) so size it big with
  `rawSetExtent` (tall enough not to crop); a shift-click PAST a line's end clamps to the line-end slot, so two
  clicks past the end produce identical shots — land clicks WITHIN the line text.
- **Keyboard selection — the anchor model in full** (`macroStringMorph2ImprovedSelection`): the KEYBOARD sibling of
  shift-click above. The rules, all driven by the caret's `cmd` off one clicked anchor slot: Shift+ArrowLeft/Right GROW
  a selection from the caret one slot at a time, and the moving end can cross THROUGH the anchor (the selection dies on
  one side and is reborn on the other, no special-casing); a PLAIN Arrow with a selection COLLAPSES it to an EDGE —
  Left/Up to the LEFT edge, Right/Down to the RIGHT edge — NOT to caret±1 and NOT to the text's extremities (mid-text
  collapses disambiguate); with NO selection, bare Up/Down act as Home/End in a single-line StringMorph2 (and
  Shift+Up/Down select to start/end); a selection grown then shrunk back to nothing is EXACTLY cancelled — typing
  INSERTS, deleting nothing; `@syntheticEventsShortcutsAndSpecialKeys_InputEvents "Meta+a"` selects all, leaving the
  caret line drawn at its slot inside the highlight. ASSERT-BY-BYTE-EQUALITY trick (reusable): different key routes to
  the SAME caret slot/selection produce byte-identical screenshots (same dataHash) — a no-op round-trip (ArrowLeft,
  Shift+Left, Shift+Right, ArrowRight) shoots identical to its predecessor, and three routes to one slot
  (type-at-caret / collapse-left / re-select-then-ArrowUp) all share one hash; state the equality in the metadata
  `assertions` and assert it in-run with `@assertScreenshotsIdentical` (see the preamble). Geometry note: count-based Shift+Arrow runs are relative to ONE
  clicked slot — keep the recorded fixture geometry (handle-fraction resize + recorded click fraction + font size) and
  the whole keyboard tail is geometry-free. No new verb.
- **Double/triple-click selects word/line** (`macroDoubleAndTripleClickThroughCaretMorph`): `@doubleClickAtFractionOf_InputEvents`
  / `@tripleClickAtFractionOf_InputEvents widget, [fx,fy]` enqueue a move + 2/3 consecutive left click-pairs that
  the HAND turns into a double/triple-click; targeting `world.caret` selects word/line at its slot. Recognition is
  proximity + the hand's real 300ms window (no speed gate; the verb spaces its clicks inside it), so it works at every
  global speed level — the test carries NO speed metadata.
  GOTCHA: a TextMorph2 opens an "edit:" PROMPT (not an inline caret) when its text is CROPPED, so ENLARGE the widget
  so the demo text fits → inline caret.
- **Double-click selects the WORD under the cursor (clean StringMorph2 + wrapped TextMorph2)** (`macroDoubleClickSelectsWord`): the
  distinct sibling of the through-the-caret entry above. `StringMorph2.mouseDoubleClick` (`:1212-1229`) reads the slot the prior click
  placed (`world.caret.slot`) and expands left/right while `String.isLetter()` (`String-extensions.coffee:43-45`, `[a-z]` only —
  spaces/punctuation/digits are boundaries) then `selectBetween()`s the contiguous letter run, so EXACTLY the word under the cursor
  selects (white-on-blue, `drawSelection :738-747`). TextMorph2 inherits it verbatim (extends StringMorph2 with no own
  `mouseDoubleClick`), resolving the slot per WRAPPED visual line. `@doubleClickAtFractionOf_InputEvents widget, [fx,fy]` is
  self-sufficient — its FIRST click focuses + places `world.caret`, the SECOND is recognised as the double-click — so no separate prior
  click is needed; double-clicking the TextMorph2 also CLEARS the StringMorph2's selection (focus moves). Fixture: a WIDE single-line
  StringMorph2 + a wrapped multi-line TextMorph2, BOTH `isEditable=true` (the gate, `:1213,1242`), each sized to FIT (a cropped one
  opens the "edit:" prompt, not an inline caret). No speed metadata — the double-click verb is recognised at every speed.
  Tune the deep-word fraction to the LIVE wrap at capture (here `[0.25,0.87]`
  landed on "condimentum" on the second-to-last line — eyeball which word the highlight covers; the exact word doesn't matter, a clean
  interior word does). Distinct from `macroDoubleAndTripleClickThroughCaretMorph` (double-clicks ON the caret of a tiny pre-typed
  TextMorph2 — pass-through); this proves word-granularity from a CLEAN state on a single-line StringMorph2 AND wrapped text. No new verb.
- **Triple-click scoping: whole string · VISUAL line · LOGICAL line** (`macroTripleClickSelection`): WHAT a triple-click
  selects, per class and wrap regime — the triple sibling of the word entry above. `StringMorph2.mouseTripleClick`
  (`:1231-1234`) is `selectAll()` + caret to the text's END: on a single-line string ANY click point selects the whole
  string. `TextMorph2.mouseTripleClick` (`:684-690`) overrides it: it `selectBetween()`s the clicked ROW's first and end
  slots — "the whole line (if it's wrapped, just what sits on the very line)" — so in soft-wrapped text the unit is the
  VISUAL line: a full-measure line, a short paragraph-closing line (the highlight stops mid-measure, plus the break slot),
  or the EMPTY separator line (just its newline — a one-character sliver). With `softWrap` OFF the rows ARE the logical
  lines, so the same gesture takes the WHOLE paragraph. Within one line the click x is IRRELEVANT (same selection, same
  end-slot caret), and text morphs add no hover/tooltip pixels — so repeats from DIFFERENT click points are byte-EQUAL:
  anchor equality pairs on them (unlike window-switch shots, which embed the last-clicked switch's hover). Fixture mirrors
  `macroDoubleClickSelectsWord` (direct build, clean ASCII, `isEditable=true`) but keeps TWO paragraphs
  (`String.fromCharCode 10`) — the break is load-bearing for the short-line/empty-line/no-wrap beats. The no-wrap finale
  calls `toggleSoftWrap()` + `togglefittingSpecWhenBoundsTooSmall()` directly (the two menu items' methods; the
  CROP→SCALEDOWN shrink is LOAD-BEARING — a cropped TextMorph2 opens the "edit:" prompt instead of the inline caret the
  triple needs). No speed metadata — the triple-click verb is recognised at every speed. Tune row fracs at capture — and
  remember the SCALEDOWN no-wrap rows are THIN (target the first row a few px under the box top). No new verb.
- **Clipboard cut/copy/paste** (`macroTextMorph2CutCopyPasteBasic`): after a Shift+Arrow selection,
  `clip = @cutSelection_InputEvents()` (or `@copySelection_InputEvents()`) reads + RETURNS the selection synchronously
  and enqueues a `Cut`/`CopyInputEvent`; later `@pasteText_InputEvents clip` enqueues a `PasteInputEvent`. Fizzygum has
  NO internal clipboard — synthetic Meta+x/c/v can't fire the browser's real clipboard EVENTS — so the text rides IN
  the event (a macro-local var), exactly as oncut/oncopy/onpaste → queue → `caret.process{Cut,Copy,Paste}`.
- **Undo** (`macroCaretResizesOKOnUndo`): `@repeatSpecialKey_InputEvents "Meta+z", 4` (the caret's `cmd` handles Meta+a
  and Meta+z). image-before and image-after-undo come out pixel-identical — the round-trip proof the caret resizes back;
  assert the pair with `@assertScreenshotsIdentical` (preamble).
- **The caret resizes with the auto-fit font (SCALEUP)** (`macroTextMorph2CaretResizing`): the forward sibling of the
  Undo entry above, and the SCALEUP counterpart of the SCALEDOWN shrink-to-fit entry below. A TextMorph2 made via the
  demo menu EXPANDS its font to fill its bounds — the ctor overrides the inherited FLOAT default to SCALEUP
  (`TextMorph2.coffee:52` vs `StringMorph2.coffee:73`; the `"←→ expand to fill"` / `"←☓→ don't expand to fill"` menu
  pair is ONE toggle, `togglefittingSpecWhenBoundsTooLarge`, `StringMorph2.coffee:1001-1026`) — so whenever the text
  fits at its set size, `fitToExtent` returns `searchLargestFittingFont` (`StringMorph2.coffee:286`, a deterministic
  binary search bounded at 200px and, under SWCanvas, at the largest shipped atlas size so the painted glyphs and the
  arithmetic `fontHeight` agree). DELETE a chunk and the font auto-GROWS to re-fill the box; the caret follows because
  `CaretMorph.updateDimension` (`CaretMorph.coffee:38-42`) sizes it from `@target.actualFontSizeUsedInRendering()` on
  every slot move/edit. Three Shift+Arrow-select + Backspace rounds make the growth monotone (~20→30→60→90px) with the
  caret glued to its slot throughout. Geometry-faithful fixture (the handle-fraction trick of the caret-glued entry):
  the wrap layout decides where the count-based selections end. A directly-built TextMorph2 also defaults to SCALEUP —
  the below-text-strip entry above NEUTRALISES it with FLOAT for the opposite reason (a fixture constant). No new verb.
- **Editing a CROPPED string defers to the "edit:" prompt** (`macroStringMorph2EditDefersToPromptWhenCropped`):
  `StringMorph2.edit` (`:1145-1150`) compares the rendered text with the full transformed text — equal → `world.edit @`
  (inline caret); different (the CROP spec ellipsised it) → `editPopup()` (`:873-882`), the "edit:" `PromptMorph` whose
  field is preloaded with `@text` and whose "Ok" commits via `setText` ("Close" discards — anchor that byte-exactly: a
  cancelled prompt leaves zero residue, same dataHash as the pre-prompt shot with the pointer parked). So the SAME click
  yields a caret or a modal purely by whether the text currently fits; widen the box (`rawSetExtent`) and the click takes
  the inline branch. Locate the prompt's field structurally (the prompt's editable `StringMorph`) and click it at the
  banked `topLeft+(3,8)` slot-0 idiom; capture the prompt via `getMostRecentlyOpenedMenu()` right after the opening click.
  This is the mechanic the NoJumps entry's tail deliberately skipped — now asserted. No new verb.
- **Inline typing refits per fitting mode — and hands off to the prompt when it crops**
  (`macroStringMorph2InlineTypingRefitsUnderFittingModes`): the StringMorph2 LIVE-TYPING matrix (every other auto-fit
  macro is TextMorph2-based; a StringMorph2 DEFAULTS to FLOAT+CROP, `:73`). Three same-text same-box fixtures, one per
  regime: under SCALEUP (toggled) each keystroke re-runs `searchLargestFittingFont` so the font steps DOWN live but keeps
  filling the box; under SCALEDOWN (toggled) typing past the width shrinks the whole single line so everything stays
  visible; under the defaults the SAME run ellipsises at the unchanged font — and the keystroke that makes the text no
  longer fit HANDS EDITING OFF to the "edit:" prompt MID-TYPING (the `edit()` deferral re-evaluated live): the rest of
  the typed run lands in the prompt's FIELD, not the morph; "Close" discards the tail and the morph keeps only its
  pre-crop inline prefix. Same-input fixtures make the contrast the assertion (shrink vs ellipsis from identical
  keystrokes). Bare `ArrowDown` = End (single-line) gives count-free end targeting. Also carries the caret-on-a-floated-
  line shot: `alignBottom()` + click → the caret stands ON the bottom-floated line. No new verb.
- **"Hide characters" masks the RENDERING, not the text** (`macroStringMorph2HideCharactersMasksTextNotEditing`):
  `toggleIsPassword` (`:1046-1048`, the "hide characters"/"show characters" menu pair, gated at `:978`) flips a pure
  draw-time transform — `transformTextOneToOne` (`:520-521`) renders every glyph as "*" while `@text` is untouched. The
  masked string still edits INLINE (the masked render equals the transformed text, so the deferral rule is satisfied);
  keyboard selection works on real slots; `copySelection_InputEvents` returns the REAL characters (`selection()` slices
  `@text`, `:1152-1155`) even though the screen shows asterisks; pastes grow the masked run; toggling back reveals the
  blind edits exactly. Both toggles `world.stopEditing()` (the fitting-toggle precedent) — reveal shots carry no caret.
  Keep the box wide enough that the text NEVER crops, or clicks deflect into the edit prompt (the deferral entry). No new verb.
- **Text ellipsisation** (`macroStringEllipsisation`): a `StringMorph2` does NOT grow to its text — when too narrow it
  crops to the longest fitting prefix + "…" (`fittingSpecWhenBoundsTooSmall` defaults to `CROP`; SCALEDOWN scales instead,
  the "crop/shrink to fit" item). `new StringMorph2 "long text", fontSize` (give a `backgroundColor` so the bounds show) +
  `rawSetExtent` to a narrow width ellipsises; a narrower extent crops more. The screenshot's settle re-crops.
- **Text shrink-to-fit (SCALEDOWN)** (`macroTextMorph2ShrinksToFitLongToken`): the SCALEDOWN counterpart of the CROP
  ellipsisation above. When a wrapping `TextMorph2` holds a single UNBREAKABLE token wider than the box, the WHOLE text's
  font is scaled DOWN uniformly until the token fits — `StringMorph2.fitToExtent` (`:537`, inherited) takes the SCALEDOWN
  branch (`:563-567`): keeps the full text and returns `searchLargestFittingFont` (a deterministic binary search) →
  `@fittingFontSize`. An unbreakable token forces it because TextMorph2's token-level wrapping is commented out
  (`TextMorph2.coffee:107-150`), so a space-less token is one over-wide line that only a font shrink can fit. A TextMorph2
  DEFAULTS to CROP (`TextMorph2.coffee:53`), so the fixture MUST set `txt.fittingSpecWhenBoundsTooSmall =
  FittingSpecTextInSmallerBounds.SCALEDOWN` — LOAD-BEARING: without it image_2 ellipsises instead of shrinking (proving the
  wrong mechanic). Build the TextMorph2 narrow (`rawSetExtent` width < the token's pixel width) with `softWrap` ON
  (default), then `txt.setText "<words> <80+-char token> <words>"` (the clean deterministic equivalent of caret typing —
  same `@text`, same fitting result; as macroNonWrappingTextResizesToContent argues). image_1 normal font → image_2 whole
  text uniformly smaller. No clicks (so no "edit:" prompt trap; `isEditable` not needed). No new verb.
- **SCALEUP tracks a TYPED growing token — no jumps** (`macroTextMorph2NoJumpsInLayoutOfLongLine`): the LIVE-typing
  complement of shrink-to-fit above, on the OTHER branch: `fittingSpecWhenBoundsTooLarge = SCALEUP` is the TextMorph2
  constructor DEFAULT (`TextMorph2.coffee:52` — the demo "TextMorph2 with background" ships it), and
  `StringMorph2.fitToExtent`'s SCALEUP branch (`:554`) re-runs `searchLargestFittingFont` on EVERY content change. So
  EMPTYING the text (click → `Meta+a` → `Backspace`, all queued input) maximises the font — the box shows a GIANT
  caret — and growing an unbreakable token through queued keystrokes (`@syntheticEventsStringKeys_InputEvents "aaaaaa"`)
  renders it giant on ONE line, stepping the whole line DOWN to the next largest fitting font exactly when one more
  character no longer fits (one step ≈ each glyph ~8% narrower: 12 glyphs span what 11 did), never wrapping (a
  space-less token can't split) and never jumping through a broken layout. Use the DEMO fixture (menu-create +
  resize/move) — it carries the spec under test and is editable. Burst sizes are tuned at capture so one shot pair
  straddles the first step-down. The recording's tail (at MINIMUM font the text finally crops and the "edit:" prompt
  pops mid-typing) is a separate cropped-text mechanic — deliberately not asserted here. No new verb.
- **Fill-mode SWITCHING mid-session, bold round-trip, paste-over-selection**
  (`macroTextMorph2FillModesWeightAndPasteOverSelection`): the residue laws of the retired endurance recording, in one
  9-shot fixture (a 320×360 editable TextMorph2, three short words — SCALEUP fits one giant word per line, so every
  transition is unmistakable). (1) `txt.togglefittingSpecWhenBoundsTooLarge()` (the "←☓→ don't expand to fill" item's
  method, `StringMorph2.coffee:1024-1027`) flips SCALEUP→FLOAT with content in place: the auto-grown font SNAPS back to
  the natural set size (the entries above assert each MODE; this asserts the live SWITCH). NB both fitting toggles call
  `world.stopEditing()` — the caret is gone after them, which is exactly what makes the next law shootable: (2)
  `txt.toggleWeight()` twice (bold → normal weight, `:1034-1036`) is a perfect round-trip — the pre-bold and post-normal
  shots share ONE reference dataHash (the no-op pixel-identical idiom; also the suite's only asserted BOLD pixels —
  italic is the caret-glued entry's). (3) a paste with a LIVE selection REPLACES it (`CaretMorph.processPaste` →
  `insert` → `@target.deleteSelection()` first): dblClick a word, `clip = @copySelection_InputEvents()`,
  `@pasteText_InputEvents clip` → text UNCHANGED, caret after the word; paste again → duplicates (the clipboard entry
  above pastes only at a bare caret). (4) `txt.alignBottom()` asserts the TextMorph2 BLOCK vertical-alignment axis
  (the alignment entry below is the StringMorph2 3×3). Finale: arm `txt.togglefittingSpecWhenBoundsTooSmall()`
  (CROP→SCALEDOWN) BEFORE pasting a ~650-char lorem over a dblClick-selected word — the replacement overflows the box
  HEIGHT and the whole text shrinks uniformly (the shrink-to-fit entry above is the WIDTH/long-token axis). Arming
  SCALEDOWN first is LOAD-BEARING twice: under default CROP the overflow would ellipsise AND the next click would open
  the "edit:" prompt instead of an inline caret (that prompt is exactly the retired recording's image_21 accident —
  its 18th paste overflowed under CROP). The double-click verb is recognised at every speed — no speed metadata.
  No new verb.
- **Text alignment** (`macroStringMorph2Alignments`): the converse — a StringMorph2 LARGER than its text doesn't grow it
  either (`fittingSpecWhenBoundsTooLarge` defaults to `FLOAT`); the text floats per `horizontalAlignment` (default LEFT)
  and `verticalAlignment` (default TOP). Drive `str.alignLeft()/alignCenter()/alignRight()` and
  `str.alignTop()/alignMiddle()/alignBottom()` DIRECTLY (the "align …" item methods); a synthetic right-click won't open
  its menu (TextMorph2-family drift). Give it a `backgroundColor` so the float position is visible.
- **Soft-wrap toggle** (`macroSoftWrapTogglesTextReflow`): `textBox.toggleSoftWrap()` DIRECTLY (the "✓ soft wrap" method) —
  a synthetic right-click on a TextMorph2 does NOT open a usable context menu in a macro (it does on plain widgets; and
  INSIDE a ScrollPanelWdgt the panel's COALESCED menu does open fine, with `SimplePlainTextWdgt`'s own `softWrapOff/On`
  items — see the Scroll section's in-panel soft-wrap entry).
  NB the box does NOT grow on toggle: the overflowing no-wrap line CROPS with an ellipsis at the unchanged box width
  (the default CROP spec) — see the desktop-editing entry below for the SCALEDOWN/editing interplay.
- **No-wrap desktop editing: caret-into-view slides the MORPH** (`macroSoftWrapping`): editing a no-wrap TextMorph2 on
  the bare desktop composes three mechanics. (1) The morph's EXTENT is independent of its no-wrap text — logical lines
  wider than the box just CLIP at its right edge (`breakTextIntoLines` uses an unbounded measure when `softWrap` is off,
  `TextMorph2.coffee:314-317`; nothing resizes the box), with SCALEDOWN re-fitting the FONT on every text change. (2)
  Backspace/Enter genuinely JOIN/SPLIT logical lines — no-wrap rows are real fragments. (3) There is no panel to scroll,
  so `CaretMorph.gotoSlot` (`CaretMorph.coffee:128-142`, gated on `@target.isScrollable` — StringMorph2 default true)
  SLIDES THE TARGET MORPH (`fullRawMoveLeftSideTo`) whenever the caret's new x falls outside the world's padded view:
  send the caret to the END of a wider-than-the-canvas line and the box's left edge drags OFF-canvas while the caret
  parks at the world's RIGHT edge — floating over the desktop BEYOND the box's painted width; land it near a line START
  (Enter at the text's end → empty last line, col 0) and the whole morph slides back right. The scroll-panel branch
  (`:147-148`) is the sibling the caret-into-view macros assert. AUTHORING RULES learned: after the first edit never
  trust a y-fraction (the SCALEDOWN re-fit moves every row) — click only the FIRST line at a live point
  (`txt.top() + 5`), drive everything else with keys; reach the tail's end with ArrowDown ON THE LAST LINE
  (`TextMorph2.downFrom` clamps to the text end, `:564-569`; a click BELOW the text does the same via `slotAtRow`'s
  row-overflow guard, `:521-524` — which is also how a stray low click can slide the morph when you didn't mean to);
  size the tail line to overshoot the world's right edge but keep the slid box partly on-canvas (~340 chars at the
  observed re-fit here — tune the split count at capture). Toggles direct, as in the soft-wrap entry above; the
  CROP→SCALEDOWN shrink is load-bearing for inline-caret clicks. No new verb.
- **Non-wrapping text self-resize** (`macroNonWrappingTextResizesToContent`): a `SimplePlainTextWdgt` (extends TextMorph2)
  resizes its OWN bounds to its text. Its ctor sets `@maxTextWidth = true` (wrap to own width); `@maxTextWidth = nil` then
  `reLayout()` turns wrapping OFF (what "soft wrap off" does, `:111-115`). In that mode `setText` re-lays-out SYNCHRONOUSLY
  (`:126-131 → reLayout :183`): width = LONGEST line, height = lineCount × fontHeight. Drive with `setText` (the clean
  deterministic equivalent of caret typing); multi-line strings via `String.fromCharCode(10)` (no literal newline in the
  backtick source). The WRAP branch — width kept, height follows — is the next entry.
- **Wrapping text self-resize — the WRAP branch: width KEPT, height follows**
  (`macroWrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved`): the wrap-mode twin of the entry above and the
  bare-desktop ground for the wrap-mode reLayout law: with `maxTextWidth` truthy, `reLayout`
  (`SimplePlainTextWdgt.coffee:183-199`) breaks the text at the widget's CURRENT width and re-extends to
  width = `@width()` — NEVER re-fit to content: gutting the lorem to four words leaves a ONE-LINE strip still the full
  500 wide, where the no-wrap branch would shrink to the longest line (THE distinguishing shot between the branches) —
  × height = lineCount × ceil(fontHeight(originallySetFontSize)). Every trigger converges there synchronously: `setText`
  (`:126-131`) for the add/remove axes, `setFontSize` (`:165-168`) for the font axis — and the StringMorph2 super parses
  a numeric `17` and the font prompt's string `"17"` to the IDENTICAL `originallySetFontSize`
  (`StringMorph2.coffee:1098-1112`), proven in pixels: the macro's direct `setFontSize 17` shot reproduced the retired
  prompt-driven recording's final shot hash-for-hash at both densities. Fixture:
  `world.createNewWrappingSimplePlainTextWdgtWithBackground()` (the banked creator) +
  `@findTopWidgetByClassNameOrClass SimplePlainTextWdgt`; drive with setText/setFontSize per the entry above (a bare
  TextMorph2-family widget's synthetic right-click opens no usable menu — the scoped drift — so the recorded menu/prompt
  routes are out of reach on the desktop anyway). Deterministic setText/setFontSize round trips are EXACT: the pristine,
  the post-restore and the font-round-trip shots all carry the recordings' own pristine dataHash. Pick a font beat that
  keeps the grown widget's BOTTOM EDGE in frame (17, not the recorded 20 that hung off the canvas — the moving bottom
  edge IS the assertion). No new verb.
- **Text reflow under HANDLE resize — old TextMorph (width-from-user, height-from-content)**
  (`macroTextRelayoutsCorrectlyOnResize`): the OLD `TextMorph` family's resize law, and the suite's only dedicated
  old-TextMorph assertion. `TextMorph.rawSetExtent` keeps ONLY the requested x — it becomes `@maxTextWidth`
  (`TextMorph.coffee:235`) — and `reLayout` re-breaks the text at that measure and `silentRawSetExtent`s the morph to
  (maxTextWidth, lineCount × fontHeight) (`:118-131`): the drag's y is DISCARDED. So a corner-handle drag released far
  ABOVE the content's eventual bottom yields a wide block SHORTER than the release point, and a hard narrow yields a
  column far TALLER than it — both directions in one test. Fixture: the world menu's "demo ➜" → "text" (the Lorelei
  `TextMorph` — `WorldMorph.createNewText`, isEditable, `maxTextWidth = 300`, rides the hand; drop with a click), then
  the REAL resize path: `@openMenuOf_InputEvents textM` → `"resize/move..."` →
  `@dragResizeMoveHandleTo_InputEvents "resizeBothDimensionsHandle", (new Point textM.left()+675, textM.top()+30)` —
  live-bounds deltas make the y-ignored proof explicit. The mode can stay on across BOTH drags (the handles follow the
  morph and appear in the shots, as the recording's did). Distinct from `macroNonWrappingTextResizesToContent` (box
  follows CONTENT change, no user drag) and from the WINDOW-chrome resize tests (the same law through WindowWdgt). No
  new verb.
- **Edit a button's text label in place** (`macroEditButtonLabelText`): clicking a button TRIGGERS it, so call
  `button.label.edit()` DIRECTLY (`= world.edit label`, sets `world.caret`, no isEditable gate — the "edit" item's method),
  then reuse the caret verbs (`"Meta+a"` → `@syntheticEventsStringKeys_InputEvents "new"`) and `world.stopEditing()` to
  commit. Use an OLD-family label (a `TriggerMorph`/`MenuItemMorph` `TextMorph`, which re-lays-out on setText) — a
  `SimpleButtonMorph`'s `StringMorph2` face crops; for a standalone TriggerMorph give it `centered=true` + a fixed
  `rawSetExtent` and `reLayout()` after each edit.
- **Caret brought into view only when MOVED** (`macroDocumentCaretBroughtIntoViewWhenMoved`): in a scrollable document the panel
  scrolls to keep the caret visible — but ONLY on a caret MOVE, not on a wheel scroll. `ScrollPanelWdgt.scrollCaretIntoView` (`:504`)
  repositions the contents so `world.caret` sits in the viewport; it is called from `CaretMorph.gotoSlot` (`:147`, gated on the caret
  being directly inside a scrollable panel), which fires on a click-placement or an arrow key — not on a wheel. Fixture: a small `new
  SimpleDocumentScrollPanelWdgt` + `doc.addNormalParagraph lorem` ×N so it OVERFLOWS; place the caret in the default (editable) paragraph
  (`@moveToAndClickAtFractionOf_InputEvents (doc.contents.childrenNotHandlesNorCarets())[0], [fx,fy]`), then `@wheelOn_InputEvents doc,
  bigDelta` scrolls the caret OUT of view (it STAYS out — the scroll did not recall it), and `@syntheticEventsShortcutsAndSpecialKeys_InputEvents
  "ArrowRight"` MOVES it → the document scrolls back to reveal it. First caret-auto-scroll test.
- **Caret stays visible while EDITING in a scroll panel** (`macroEditingStringInScrollablePanelCaretAlwaysVisible`): the bare-`ScrollPanelWdgt`
  sibling of the document caret-into-view above — the SAME `ScrollPanelWdgt.scrollCaretIntoView` (`:504`) / `CaretMorph.gotoSlot` (`:147`) path,
  but a large-font string overflows a small panel and the caret is WALKED with ArrowRight so the panel auto-scrolls HORIZONTALLY to keep it in
  view. Fixture: `panel = new ScrollPanelWdgt; panel.rawSetExtent (new Point 300,140); panel.add str` where `str = new StringMorph "Hello,
  World!", 60` (the 2nd ctor arg is fontSize, ~5× the default → overflows the viewport) with `str.isEditable = true` (the OLD single-line
  StringMorph defaults `isEditable=false`, `StringMorph.coffee:18`). Drive: `@moveToAndClickAtFractionOf_InputEvents str, [0.04,0.5]` (click
  WITHIN the leading glyphs → inline caret at the start), then `@repeatSpecialKey_InputEvents "ArrowRight", n` walks the caret past the right
  edge → the content scrolls left and the hBar shifts. GOTCHA: use the OLD `StringMorph` (not StringMorph2) — it is `isScrollable` (`:26`) and
  has NO "edit:" prompt-on-crop and NO `slotAt` overshoot throw (those are TextMorph2/multi-line traits, `TextMorph.coffee:283`), so a click
  always places an inline caret; drive the moves via the input-event verbs (never poke `world.caret`) so `scrollCaretIntoView` genuinely fires;
  the caret is non-blinking only under the `TurnOnAnimationsPacingControl` preamble (`BlinkerMorph.coffee:21-24`). The VERTICAL sibling
  (`macroScrollPanelCaretBroughtIntoViewWhenMoved`) exercises the SAME path via the V-branch (`:514-521`) and is the bare-`ScrollPanelWdgt`
  counterpart of `macroDocumentCaretBroughtIntoViewWhenMoved`: an editable string at the TOP + a tall `RectangleMorph` below it overflow
  VERTICALLY (a V-scrollbar); `@wheelOn_InputEvents panel, +Δ` scrolls the string+caret OUT of view above the viewport (the wheel alone does NOT
  recall it — `scrollCaretIntoView` fires on a caret MOVE, not a scroll), then `@syntheticEventsShortcutsAndSpecialKeys_InputEvents "ArrowRight"`
  MOVES the caret → the panel auto-scrolls back UP to reveal it. (An ArrowRight is a HORIZONTAL move, but `gotoSlot` runs the FULL
  `scrollCaretIntoView`, whose V-branch scrolls a caret that is above the viewport back into view.) Together the two tests cover the original
  recording's H and V caret-follow.
- **Typing multiline text AUTO-SCROLLS its input area** (`macroMultilineTextInputScrollsWell`): the growth variant of the
  caret-into-view family above — those MOVE the caret through non-growing content; here the CONTENT GROWS under the caret.
  Typing line after line (`@syntheticEventsStringKeys_InputEvents` + `"Enter"`) into an editable old `TextMorph` inside a
  `ScrollPanelWdgt` makes every keystroke run `CaretMorph.gotoSlot`'s scroll-panel branch (`amIDirectlyInsideScrollPanelWdgt
  → @parent.parent.scrollCaretIntoView`, `CaretMorph.coffee:147-148`), so once the text outgrows the pane the view tracks the
  typed TAIL line by line while `adjustScrollBars` materialises the V-bar (button at the BOTTOM). The counter-beat:
  `@dragSliderButtonToFraction_InputEvents pane.vBar, [0.5, 0.05]` drags the scrollbar button back to the top — the first
  lines return WITHOUT recalling the caret (scrolling alone never does). Fixture: the OLD inspector's ~3-line WORK pane
  (`insp.work`, an `isTextLineWrapping` ScrollPanelWdgt holding an empty editable old TextMorph, `InspectorMorph.coffee:176-186`).
  GOTCHA (the empty-TextMorph click crash): focus the field with a DIRECT `workText.edit()` (`world.edit`, the button-label
  idiom) — NEVER a click. The old `TextMorph.slotAt` has no row/col guard (`TextMorph.coffee:275-285`): on an EMPTY text any
  click-x past the left edge walks `lines[row][col] = undefined` into `measureText`, and SWCanvas's measureText reads
  `.length` of its argument → TypeError (native canvas coerces undefined to a string and survives — an SWCanvas-ONLY crash).
  That crash is exactly why the recorded original sat on the `SWCanvasBrokenTests` list (native refs only); the edit()-focused
  macro RESTORES SWCanvas coverage. Corollary: a deterministic crash SELF-VERIFIES — an Error-log window captured into the
  references still "passes" capture+verify, so only the EYEBALL catches it. No new verb.
- **Wrapping text FIELDS re-wrap on every container resize** (`macroWrappingTextFieldResizesOK`): the inspector's detail +
  work panes are WRAPPING TEXT FIELDS — `ScrollPanelWdgt`s with `isTextLineWrapping = true`, each holding an (initially
  empty, editable) old `TextMorph` (`InspectorMorph.coffee:163-186`). Text typed into them wraps to the pane width, and EVERY
  inspector resize re-wraps it: a drag of the inspector's own ctor resizer → `InspectorMorph.doLayout` resizes the panes →
  `ScrollPanelWdgt.rawSetExtent` (`ScrollPanelWdgt.coffee:222-233`) → `adjustContentsBounds` re-fits each contained TextMorph
  to the new pane width (`rawSetWidth` + `maxTextWidth`, `:258-267` — width imposed by the pane, height following the
  content) → `adjustScrollBars` shows the V-bar exactly when the re-wrapped text no longer fits. Probe the rule with a
  silhouette progression (wide → taller-at-same-width → narrow+tall → tiny): WIDTH changes re-break the lines; a pure HEIGHT
  change keeps the line breaks identical (wrap depends on width only) and just adds white space. After the edit dies, panes
  sit scrolled to the TOP (no caret holds the tail in view). Focus the empty fields with `text.edit()` — the empty-TextMorph
  click crash above. Distinct from `macroTextRelayoutsCorrectlyOnResize` (a STANDALONE old TextMorph, handles, no scroll
  panel) and `macroScrollBarsTrackContentChange` (content changes, not container resizes). No new verb.
- **Evaluation menu reflects text selection** (`macroEvaluationMenuReflectsTextSelection`): a TextMorph2's right-click menu
  depends on what is selected. `setReceiver obj` (`TextMorph2.coffee:657-659`) installs `evaluationMenu` as the widget's
  `overridingContextMenu` (so `Widget.buildContextMenu` returns it directly); that menu prepends "do all"/"select all" when
  `@text.length>0` (`:618`) and ALSO "do selection"/"show selection"/"inspect selection" ONLY when `@selection()` is non-empty
  (`:625`). Fixture: a STANDALONE `new TextMorph2("3 + 4", nil,nil,nil,nil, nil, bg, 1)` (the inspector value panes are OLD
  TextMorph — build the TextMorph2 directly to exercise THIS path), `isEditable=true` + `setReceiver world`, sized so the text
  FITS (else a click opens the "edit:" prompt). Beats: click in → `@openMenuOf_InputEvents txt` (UNSELECTED shot) → dismiss with
  a mouse-down on empty desktop, RE-CLICK in, `@syntheticEventsShortcutsAndSpecialKeys_InputEvents "Meta+a"` → `@openMenuOf_InputEvents
  txt` (SELECTED shot: text highlighted white-on-blue + the 3 extra items). GOTCHA: opening then dismissing the menu ENDS editing,
  so you MUST re-click into the field before Meta+a, or select-all routes nowhere and the selected shot silently equals the unselected one.
- **Empty editable text omits "select all"** (`macroEmptyStringDoesntGiveSelectAllOption`): the negative/exclusion sibling of the
  evaluation-menu entry above. `evaluationMenu` builds `@buildHierarchyMenu()` FIRST and only prepends "do all"/"select all" inside
  `if @text.length>0` (`TextMorph2.coffee:618`), so on an EMPTY field the right-click menu is JUST the hierarchy item `a TextMorph2 ➜`
  — neither item present. Same fixture as the selection sibling (`new TextMorph2("", …)` + `isEditable=true` + `setReceiver world`,
  sized to fit) but START EMPTY: right-click → screenshot (no select-all), then click in + `@syntheticEventsStringKeys_InputEvents
  "asdf"` (NON-empty, no selection) → right-click → screenshot ("do all"/"select all" now prepended above `a TextMorph2 ➜`). The two
  shots (absent vs present) ARE the assertion. GOTCHAS: do NOT select the text (Meta+a) — that trips the SEPARATE `:625` selection gate
  and adds the "…selection" items, muddying the empty-vs-filled contrast; re-click the field before typing (dismissing the first menu
  ends editing); screenshot-only (an exact menu-strings assertion is brittle — `evaluationMenu` prepends separator RectangleMorphs with no `labelString`).
- **Add an indented paragraph to a document via its layout menu** (`macroSimpleDocumentCanAddIndentedParagraph`): a
  `SimpleDocumentScrollPanelWdgt` ships ONE editable default paragraph ("A small string … here another.") as its first content child
  (`(doc.contents.childrenNotHandlesNorCarets())[0]`) — reformat THAT (add a Lorem paragraph below for reflow context). Drive its
  `"a SimplePlainText ➜"` → `"layout in stack ➜"` submenu (`VerticalStackLayoutSpec.coffee:42-53`): `"base width..."` opens a PromptMorph
  (narrows the box), `"align right"` (setAlignmentToRight) moves the box to the document's right edge; then click in, `Meta+a`, and type
  the indented body PER LINE with an `"Enter"` between (`@syntheticEventsStringKeys_InputEvents` has NO newline handling), the two leading
  spaces of `"  some code"` typed as literal space keys so the indent round-trips (Enter → `CaretMorph` inserts `"\n"`). TWO gotchas make
  base-width actually bite — both were initially mistaken for "the layout menu doesn't work under synthetic input"; it DOES: (1) the
  prompt's value lives in a `StringFieldMorph` that DEFAULTS to the current width, so CLICK the field to focus it
  (`StringFieldMorph.mouseClickLeft → @text.edit()`; reach it as `basePrompt.tempPromptEntryField`), `Meta+a`, type "300", then "Ok" —
  which reads the field's `getValue()` into `setWidthOfElementWhenAdded`. Typing WITHOUT focusing the field leaves the default, so Ok
  re-applies the current width = no visible change. (If instead you drive the prompt's `SliderMorph` via
  `@clickOnSliderTrackAtFraction_InputEvents`, pass a `[fx,fy]` POINT, NOT a scalar — a scalar indexes as `fraction[0]`=undefined → a NaN
  click point → a non-finite base-width → a "Point x must be finite" paint crash.) (2) base-width only bites when the paragraph's remembered
  `widthOfStackWhenAdded` equals the current available stack width; the SHIPPED default paragraph remembered it at CONSTRUCTION (before
  `doc.rawSetExtent`), so with elasticity 1 the proportional-width calc (`availW·baseWidth/stackWhenAdded`) cancels to full width — re-anchor
  the paragraph's initial dimensions to the resized stack in the FIXTURE: `target.layoutSpecDetails.rememberInitialDimensions target,
  doc.contents`.

## Menus & popups

- **Open a menu / click an item**: `@openMenuOf_InputEvents widget` (right-click) then `@moveToItemOfTopMenuAndClick_InputEvents
  "label"`, or the `clickMenuItemOfWidget_InputEvents_Macro widget, "label"` verb (composes both). Pop the WORLD menu at a
  deliberate spot: `@moveToAndClick_InputEvents (new Point X, Y), "right button"`.
- **`getMostRecentlyOpenedMenu()` is fresh-only.** It reads `world.freshlyCreatedPopUps`, which **every mouseUp clears**
  (`ActivePointerWdgt.processMouseUp`). Capture a popup reference RIGHT AFTER it opens and drive its later items through
  `@moveToItemOfMenuAndClick_InputEvents menu, "label"` whenever you touch the popup more than once (e.g. click a
  slider/palette INSIDE a prompt, THEN its "Ok").
- **Item-label matching variants**: exact (`moveToItemOfMenuAndClick_InputEvents`), **PREFIX**
  (`moveToItemStartingWithOfMenuAndClick_InputEvents` — for labels with a variable suffix, e.g. the "attach…"/"choose
  target:" labels are `toString() + " ➜"` like "a RectangleMorph#1 ➜"; match the stable class-name head), **SUBSTRING**
  (`moveToItemContainingOfMenuAndClick_InputEvents` — for a leading decoration, e.g. `"soft wrap".tick()` renders "✓ soft wrap").
- **Hierarchy menu (a non-world child)**: right-clicking a widget whose parent ≠ world opens the framework's ANCESTOR
  HIERARCHY menu (`Widget.buildContextMenu`/`buildHierarchyMenu`) — one "a X ➜" item per ancestor that has a menu (labels are
  `toString().replace("Wdgt","")` so a WindowWdgt reads "a Window ➜"). Navigate to the desired ancestor by class-name PREFIX
  to open ITS own menu (used to resize a content-covered panel, duplicate a nested widget, "pick up" an inspector part, …).
- **A coalescing scroll panel SUPPRESSES its child's hierarchy menu** (`macroScrollPanelCoalescesChildMenu`): the inverse of the
  rule above. A `SimplePlainTextScrollPanelWdgt` sets `takesOverAndCoalescesChildrensMenus = true` (`SimplePlainTextScrollPanelWdgt.coffee:25`),
  so `Widget.buildContextMenu` (`:2905-2908`) finds that ancestor and returns the PANEL'S OWN menu — right-clicking the inner text
  blurb produces no "a X ➜" disambiguation at all (the blurb is never offered as a separate target). A NEGATIVE assertion needs
  the baseline visible: pair it with a plain `PanelWdgt` + `RectangleMorph` child whose right-click DOES build the 2-item hierarchy
  menu (`@assertTopMenuItemStrings ["a RectangleMorph ➜", "a Panel ➜"]`) — same gesture, opposite menu. Build the panel directly:
  `new SimplePlainTextScrollPanelWdgt "text", false, 5` (ctor `(textAsString, wraps, padding)` auto-builds the inner blurb).
  image_1 (the panel's own coalesced menu) vs image_2 (the 2-item hierarchy menu) is the proof.
- **Submenu hopping — keep the common chain open** (`macroHoppingBetweenSubMenus`): an arrow item opens a submenu AT the
  clicked point on click (`TriggerMorph.trigger`). Clicking ANY item KEEPS the menus in its ASCENDING hierarchy
  (`PopUpWdgt.hierarchyOfPopUps`) and DISMISSES the DOWNSTREAM submenus — so re-click a world-menu sibling IN THE CHAIN to
  swap the branch under it; the world menu survives every hop until one final desktop click. **OCCLUSION:** a submenu pops at
  the clicked point and covers the sibling triggers, so click each world-menu sibling at its LEFT
  (`@moveToAndClickAtFractionOf_InputEvents sibling, [0.3,0.5]`, further left `[0.1,0.5]` for deeper hops); descend with a
  centre click. Do NOT re-grab a hopped-to submenu via `getMostRecentlyOpenedMenu()` — a hop's deferred auto-close re-clears
  the fresh-popup set; find items directly with `world.topWdgtSuchThat (w) -> w.labelString?.startsWith "demo"`.
- **Menu cascade auto-close on mouse-DOWN** (`macroMenusCloseOnMouseDownOutside`): an open menu (and any submenu) is dismissed
  by a mouse-DOWN on a NON-menu area (the hand's `cleanupMenuWdgts` tears down unpinned popups in
  `world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren`). The dismissal is on the DOWN, not the up, so capture it with
  `@moveToAndMouseDown_InputEvents (point)` (move + press, NO release) → `yield "waitNoInputsOngoing"` → screenshot →
  `@syntheticEventsMouseUp_InputEvents()`. (The same press-and-hold pattern captures a float-dragged morph being DROPPED.)
- **Right-click an UPSTREAM menu item closes its DOWNSTREAM submenus** (`macroRightClickClosesDownstreamSubMenus`): the right-click
  sibling of submenu-hopping. With a deep cascade open (world > test menu > others 2 > icons), a right-click (a mouse-DOWN) on an
  item in an UPSTREAM menu runs `cleanupMenuWdgts`, which KEEPS the pop-ups in that item's ASCENDING hierarchy
  (`PopUpWdgt.hierarchyOfPopUps`, walks `getParentPopUp` UP) and DISMISSES its DESCENDANTS — so the world menu + test menu stay
  while others-2 + icons close; the SAME right-click also opens the item's own hierarchy context menu (a TextMorph / a MenuItemMorph
  / a MenuMorph, `Widget.buildContextMenu`/`buildHierarchyMenu`). Descend by labelString prefix (reuse the hopping pattern), then
  `@moveToAndClickAtFractionOf_InputEvents item, [0.35,0.5], "right button"` (LEFT-ish fraction — submenus pop at the clicked point).
  Screenshot only; do NOT re-grab `getMostRecentlyOpenedMenu()` after the auto-close (deferred cleanup re-clears the fresh set).
- **Dragging MENUS keeps the cascade open; only a non-menu press closes it**
  (`macroMenusAndSubMenusRemainOpenWhileDraggingMenusOnly`): the drag-side complement of cascade auto-close above. The
  mouse-down cleanup spares a press that lands ON a menu of the chain, so grabbing any menu by its HEADER
  (`@syntheticEventsMouseMovePressDragRelease_InputEvents menu.label.center(), dest` — press-then-move is a grab, a click
  would pin) float-drags just that menu while the WHOLE cascade stays open — repeatable across several menus of the same
  chain. The first press on an ordinary widget kills the entire chain at the DOWN and then float-drags that widget normally
  (capture the menu-less held frame with moveToAndMouseDown → screenshot → held move → screenshot → mouseUp). Capture each
  sub-menu reference fresh right after the item click that opens it (a straight DESCEND, unlike hopping, leaves
  getMostRecentlyOpenedMenu valid). No new verb.
- **Pin a menu by its header** (`macroMenuPinnedByHeaderClick`): `@clickMenuHeaderToPin_InputEvents menu` clicks the menu's
  title bar (`.label` MenuHeader → `pinPopUp`) — drops the kill-on-click-outside flags (and tightens the shadow), so a later
  desktop click no longer dismisses it. The inverse of cascade auto-close.
- **A pop-up dropped INTO a panel auto-pins itself** (`macroSubMenuDroppedIntoPanelPinsItself`): the pin-on-drop sibling of the
  header-click pin above. Float-drag an unpinned pop-up (here the world menu's "demo ➜" sub-menu, titled "make a morph") OUT of its
  parent by its HEADER and release it INSIDE a `PanelWdgt`: `ActivePointerWdgt.drop` re-parents it under the panel (`_acceptsDrops:true`)
  and fires `PopUpWdgt.justDropped(whereIn)` (`PopUpWdgt.coffee:105`), which — because `whereIn != world` — calls `pinPopUp()`, clearing
  the menu's kill-on-click-outside flags. So the sub-menu becomes a PINNED child of the panel and SURVIVES the later dismissal of the
  parent menu (a drop onto the bare world, `whereIn == world`, would NOT pin). Open the sub-menu with
  `@moveToItemStartingWithOfMenuAndClick_InputEvents (@getMostRecentlyOpenedMenu()), "demo"` and capture `subMenu =
  @getMostRecentlyOpenedMenu()` while fresh, HOLDING the reference (the next mouseUp clears `freshlyCreatedPopUps`). **The
  FLOATING-vs-CLIPPED transition is the visible tell** (and is what the recording shows): grab by the HEADER and carry it on top of the
  panel with the held-button idiom — `@moveToAndMouseDown_InputEvents subMenu.label.center()` (press the header — a press on the body
  would hit a menu item; a press-then-MOVE is a grab, a CLICK would pin in place) → `@syntheticEventsMouseMove_InputEvents (panel point),
  "left button"` → screenshot WHILE held (the floating sub-menu is a hand-child drawn UNCLIPPED, overflowing the panel's bottom edge) →
  `@syntheticEventsMouseUp_InputEvents()` (drops INTO the panel, re-parented + pinned, now CLIPPED by the panel) → screenshot. image_1
  sub-menu cascading beside the empty panel → image_2 MID-DRAG floating on top, unclipped/overflowing → image_3 dropped+pinned, now
  clipped, world menu STILL up → image_4 world menu dismissed (only then), sub-menu survives. Drop high (~`[0.5,0.1]`) so the overflow
  (floating) vs clip-at-the-edge (dropped) difference is pronounced.
- **A menu pinned in a SCROLLABLE panel is live scrolling content** (`macroMenuPinnedInScrollPanel`): the ScrollPanelWdgt
  sibling of the drop-pin entry above. Drop the demo sub-menu into the demo "scrollable panel" (350x250 `ScrollPanelWdgt`
  via `world.create`; locate it with `@findTopWidgetByClassNameOrClass ScrollPanelWdgt` — its getTextDescription says
  "Panel", so pass the CLASS, not the string) and the taller-than-viewport menu is CLIPPED and makes the panel's own
  `panel.vBar` appear. Thereafter it behaves as ordinary content that is still a LIVE menu: move the panel by an empty
  corner (`[0.93,0.05]` — the spare width right of the ~140px menu is the clean grab area; don't narrow the panel) and the
  menu travels; `@dragSliderButtonToFraction_InputEvents panel.vBar, [0.5,0.85]` scrolls it (the header slides out past the
  viewport top); and a click on one of its still-visible items (`@getTextMenuItemFromMenuByPrefix subMenu, "color palette"`
  — the subMenu reference captured before the drop stays valid through re-parenting and scrolling) still fires, the created
  palette riding the hand onto the desktop. Check the clicked item is INSIDE the viewport after the scroll (a clipped-away
  item can't be hit). No new verb.
- **A menu in a WINDOW in a scroll-STACK is still a live menu** (`macroMenuInWindowInScrollStackStaysLive`): the
  double-wrapping composition of the pin-on-drop and in-panel-liveness entries. Drop the demo sub-menu by its HEADER into an
  empty internal window: the placeholder accepts it, `reactToDropOf` adopts + retitles, `justDropped` pins — and the window
  WRAPS down around the menu's natural narrow-tall shape (the wrap law applies to menus too; the preset extent is discarded).
  Drag that window by its TITLE BAR into a constrained scroll-stack: the cell's BAR takes the full stack width while the menu
  keeps its natural width inside; the tall cell overflows the viewport (scrollbar appears), a wheel slides the whole cell —
  bar and menu — under the viewport top, and a click on a still-visible item (`getTextMenuItemFromMenuByPrefix` on the subMenu
  reference captured BEFORE the drop — it survives both re-parentings) still FIRES, the made morph riding the hand to the
  desktop. GOTCHA: the header-drag's RELEASE point must be clear of every menu of the still-open world-menu cascade — a release
  over the cascade silently re-absorbs the dragged sub-menu (unpinned) and the later dismissal click destroys it. No new verb.
- **Pop-up (prompt/menu) shadow on drag** (`macroPromptShadowFollowsOnDrag`): a `PromptMorph` (extends MenuMorph extends
  PopUpWdgt) casts a drop shadow like every pop-up (`PopUpWdgt.popUp → addShadow`, offset (5,5) α0.2). Drag it by its TITLE
  BAR: `@syntheticEventsMouseMovePressDragRelease_InputEvents prompt.label.center(), dest` (a press-drag GRABS the whole
  pop-up; a CLICK on the header would PIN it; dragging the CENTRE hits the inner field/slider). On drop `PopUpWdgt.justDropped`
  re-runs `updatePopUpShadow`, so the shadow renders correctly at every position. Capture `prompt` fresh right after it opens.
- **Menu shadow is correct WHILE dragging and AFTER drop** (`macroMenuShadowCorrectWhileAndAfterDrag`): the mid-drag companion of the
  prompt-shadow entry above. A popped-up unpinned menu casts the at-rest pop-up shadow (`PopUpWdgt.addShadow` → offset (5,5) α0.2); while
  it is FLOAT-DRAGGED the grab swaps in the lifted drag shadow (`ActivePointerWdgt.grab` → addShadow offset (6,6) α0.1 — larger and
  fainter); on drop `PopUpWdgt.justDropped` restores the at-rest shadow. The difference is an OFFSET/ALPHA change on pickup, NOT clipping
  at the screen corner (the positive down-right offset is never clipped at the top-left). CAPTURE THE MID-DRAG FRAME with the held-button
  idiom: `@moveToAndMouseDown_InputEvents menu.label.center()` (press the header — a press-then-MOVE is a grab; a CLICK would PIN it) →
  `@syntheticEventsMouseMove_InputEvents dest, "left button"` (move while held → grabs+carries the menu) → screenshot (button STILL held)
  → `@syntheticEventsMouseUp_InputEvents()` → screenshot. image_2 (held, lifted shadow) and image_3 (dropped, rest shadow) sit at the SAME
  position so ONLY the shadow differs — the three dataHashes differ, so the subtle shadow change is real and deterministic. (Held-button
  screenshot idiom proven by `macroSliderButtonStateColors`, which captures a button mid-press/mid-drag.)
- **A pinned menu's shadow is untouched by bringToForeground** (`macroPinnedMenuKeepsCorrectShadowWhenBroughtToForeground`):
  completes the shadow trio (drag + prompt entries above). Raising a pinned menu must repaint the SAME tight pinned shadow,
  not re-apply the loose unpinned one. The user raise is a click on the menu's HEADER: `Widget.mouseDownLeft` (`:2678`) calls
  `bringToForeground` (`:2664`, `rootForFocus().moveAsLastChild()` — so any click on the menu raises the WHOLE menu), and the
  click's `pinPopUp` re-run is idempotent (`PopUpWdgt.coffee:77` — flags already clear, `updatePopUpShadow` re-applies the
  same shadow). Two observables: with NOTHING overlapping, the raise is a pixel-perfect NO-OP (before/after shots share a
  dataHash — aim every header click at the header's CENTRE so the pointer ends identically placed, no parking moves needed);
  then a rectangle made the user's way (a second world menu → "demo ➜" → "rectangle") is carry-dropped OVERLAPPING the menu,
  and one more header click lifts the menu above it with the tight shadow painted over the rectangle. The on-menu drop is
  safe twice over: a menu does not accept drops (`Widget._acceptsDrops:104` false; `dropTargetFor` walks up to the world, so
  the rectangle lands as a world child ABOVE the menu), and the drop CONSUMES the mouse-down
  (`ActivePointerWdgt.processMouseDown:372` → `drop()`, button nulled) so no `mouseDownLeft` reaches the menu to raise it
  prematurely — while the same drop still dismisses the unpinned creation menus (the pinned one survives). The recording
  drove the raise via a console eval of "@bringToForeground()" — the header click invokes the same method, minus the console
  fixture noise. No new verb.
- **Pick a colour / set transparency via a popup**: colour: `"color..."` opens a colour-picker menu — capture
  `picker = @getMostRecentlyOpenedMenu()`, click `picker.topWdgtSuchThat((m)-> m instanceof ColorPickerMorph).colorPalette`
  at `[fx,0.5]` (saturated; the palette is `hsl(360·fx,100%,50%)`), then `@moveToItemOfMenuAndClick_InputEvents picker, "Ok"`.
  COLOUR-PICKER TRAP: a `ColorPickerMorph` holds both a hue×lightness `.colorPalette` and a thin `.grayPalette` (a
  GrayPaletteMorph, which SUBCLASSES ColorPaletteMorph) — reach the colour one via the `.colorPalette` accessor, NOT an
  `instanceof ColorPaletteMorph` search. transparency: `"transparency..."` opens a `PromptMorph` —
  `@clickOnSliderTrackAtFraction_InputEvents prompt.topWdgtSuchThat((m)-> m instanceof SliderMorph), [fx,0.5]` then "Ok".

- **Popup repositioned to stay on-screen** (`macroMenuRepositionsToStayOnScreen`): a popup is never clipped by the
  world edge — it is shifted to stay fully visible. `PopUpWdgt.popUp` (`:143`) puts the popup's top-left at the requested
  point, then `@fullRawMoveWithin world` (`:153` → `Widget.fullRawMoveWithin`, `:1337`) CLAMPS it into the world
  rectangle (right/bottom shifted in first, top/left nudged last so a too-big popup still shows its top-left). It is
  unconditional, self-protecting (can't end up off-screen), and universal to every PopUpWdgt. Demonstrate with the
  bare-desktop right-click (the world menu) at three points via `@moveToAndClick_InputEvents pt, "right button"` using the
  LIVE `world.right()`/`world.bottom()`: comfortable (menu at the pointer, the baseline), near the right edge (menu shifts
  LEFT), near the bottom-right corner (menu shifts UP and LEFT). The shift away from the pointer is what proves it.
  (Distinct from `macroMenuFromFramedItemNotClipped`, where a popup escapes a CONTAINER frame's clip — not the screen edge.)
- **Menu from a framed item is not clipped by the frame** (`macroMenuFromFramedItemNotClipped`): a context menu opened
  from a widget INSIDE a clipping frame overflows the frame and is drawn in FULL — a context menu is a WORLD-level popup
  (`ActivePointerWdgt.openContextMenuAtPointer` `:104` → `buildContextMenu()` → `popUpAtHand()` → `PopUpWdgt.popUp(hand,
  world)`, attached to the WORLD), and clipping (`ClippingAtRectangularBoundsMixin`) only crops a frame's own DESCENDANTS,
  so a world-level sibling menu drawn over the frame is never clipped by it. Build a narrow `PanelWdgt` (a clipping frame)
  with a child straddling an edge (cropped → proves the clip is active) and an inner item; `@moveToAndClickAtFractionOf_InputEvents
  innerItem, [0.5,0.5], "right button"` opens the item's hierarchy menu ("a X ➜" — a non-world child →
  `buildHierarchyMenu`), which overflows the frame's edge in full while the frame still crops its own child. The
  frame-clip counterpart of macroMenuRepositionsToStayOnScreen (which is about the SCREEN edge). The recorded original
  (poppingUpSubMenuNotClipped) used an inspector's clipped list column; a plain frame demonstrates the same point.
- **A duplicated menu is born pinned** (`macroDuplicatedMenuAutoPinsOnDesktop`): right-clicking a menu ITEM raises that item's
  ancestor hierarchy menu ("a MenuItemMorph ➜" / "a MenuMorph ➜"); drilling "a MenuMorph ➜" → "duplicate" runs the MENU's own
  duplicate. Under the harness `world.isIndexPage` is false (`WorldMorph.coffee:277-278`) so it is `Widget.duplicateMenuActionAndPickItUp`
  (`:3489` → `fullCopy().pickUp()`) — the copy RIDES THE HAND (not the index page's +10,+10 plop). `PopUpWdgt.fullCopy` (`:92-97`)
  clears the copy's kill-on-click-outside flags, so `isPopUpPinned()` (`:59`) is true the instant the copy exists — pinned BEFORE it
  is dropped. Show the differential with an explicit unpinned FOIL: CARRY the hand-riding copy to the LEFT and drop it where the pointer
  releases it (`@syntheticEventsMouseMove_InputEvents leftPt, "no button"` then `@syntheticEventsMouseClick_InputEvents()` — let the pointer
  place it, do NOT API-reposition it), re-open a NORMAL world menu on the right (`@moveToAndClick_InputEvents pt, "right button"`), screenshot
  the two menus, then ONE `@moveToAndClick_InputEvents emptyPt, "left button"` outside both — the unpinned foil closes, the pinned duplicate
  survives. GOTCHA: the ORIGINAL world menu CLOSES during the duplicate navigation (eyeball-confirmed), so it can't be the contrast — open a
  fresh foil. (Baseline of a normal menu closing on an outside click: macroMenusCloseOnMouseDownOutside.)

## Windows (chrome + content)

- **Window-chrome buttons** (`macroWindowsEmptyClosing` / `…Collapsing…` / `…Resizing`): reach a window's OWN control by
  reference, not by hunting coordinates — `@closeWindow_InputEvents win` (`.closeButton`, a CloseIconButtonMorph),
  `@collapseOrUncollapseWindow_InputEvents win` (`.collapseUncollapseSwitchButton` — the SAME verb collapses or uncollapses
  per current state), `@dragWindowResizerTo_InputEvents win, (new Point win.right()+dx, win.bottom()+dy)` (`.resizer`, a
  bottom-right HandleMorph, non-float drag → setExtent; use deltas off the live bounds).
- **Resizing a window WHILE collapsed reverts on uncollapse** (`macroCollapsedWindowBarResizeRevertsOnUncollapse`): the
  collapsed-bar follow-on to the chrome-button entry above. Collapsing a `WindowWdgt` SAVES its pre-collapse size —
  `childBeingCollapsed`/`childCollapsed` store `@widthWhenUnCollapsed`/`@extentWhenCollapsed` (`WindowWdgt.coffee:208-232`) and shrink
  it to just its title bar at the SAME width; the `.resizer` stays present and draggable while collapsed (`adjustContentsBounds`
  repositions it unconditionally, `:536-537`), so `@dragWindowResizerTo_InputEvents` NARROWS the bar's width (height pinned to the bar,
  `:480-486`). But `childUnCollapsed` (`:234-244`) does `rawSetExtent @extentWhenCollapsed` then `rawSetWidth @widthWhenUnCollapsed` (the
  width captured BEFORE collapsing), so uncollapse RESTORES the full pre-collapse extent and DISCARDS the resize-while-collapsed — a
  round-trip REVERT for the EXPANDED size. But the COLLAPSED-bar size and the expanded size are tracked SEPARATELY, and the collapsed-bar
  size is STICKY: a later re-collapse returns the bar to its last resized (narrowed) width. So resizing while collapsed changes ONLY the
  collapsed-bar size (sticky across collapse cycles), never the expanded size. Reuse the empty-window fixture of
  macroWindowsEmptyCollapsingUncollapsing (`new WindowWdgt nil,nil,nil` external / `…,true` internal) and run collapse → resize-narrow →
  uncollapse → RE-collapse → uncollapse IN THAT ORDER. Park the pointer on a clear spot (`@syntheticEventsMouseMove_InputEvents pt, "no
  button"`) before each shot so no collapse-button hover tooltip lands on a window. image_1 two full 300×300 windows → image_2 collapsed
  FULL-WIDTH bars → image_3 NARROWED bars → image_4 back to full 300×300 (== image_1, expanded size preserved) → image_5 RE-collapsed =
  NARROWED again (pixel-identical to image_3 — the collapsed size is sticky, the identical dataHash IS the proof) → image_6 uncollapsed =
  full again (== image_4). Distinct from macroWindowsEmptyResizing (resizes while EXPANDED, which persists). No new verb.
- **Duplicating a COLLAPSED window keeps state, extent and content** (`macroDuplicatedCollapsedWindowKeepsStateAndContent`):
  the chrome-state axis of the duplicate family (menu duplicates: the born-pinned entry; composite duplicates keep wiring: the
  slider/inspector entries). A collapsed `WindowWdgt` stores its pre-collapse geometry (`@widthWhenUnCollapsed` /
  `@extentWhenCollapsed`, `WindowWdgt.coffee:208-232`) and keeps its adopted `@contents` attached — `fullCopy` deep-copies all
  of it, so the duplicate is BORN COLLAPSED (same content-derived title) and uncollapsing the COPY restores the COPIED stored
  extent (the CONTENT-WRAPPED one — the window shrank around its rectangle on adoption) and reveals the copied content, leaving
  the original bar untouched. Reach "duplicate" through the ancestor HIERARCHY menu: a right-click on the bar lands on a chrome
  CHILD (label/background), so descend `"a Window"` by prefix first; then the standard carry-drop (no-button move + click).
  Locate the copy STRUCTURALLY (`world.topWdgtSuchThat` on class + position) — original and copy share their title. No new verb.
- **Internal vs external window drop** (`macroInternalVsExternalWindowDrop`): a `WindowWdgt`'s 4th ctor arg is `internal`
  (default false). `WindowWdgt.rejectsBeingDropped` returns `!@internal`, and `ActivePointerWdgt.drop` forces `target = world`
  for a widget that rejectsBeingDropped (`:242`) — so an EXTERNAL window dropped over a container lands on the desktop (NOT
  nested) while an INTERNAL window nests into the morph under the point (e.g. a PanelWdgt, `_acceptsDrops:true`). Carry on the
  hand with `win.pickUp()` + a no-button `@syntheticEventsMouseMove_InputEvents`, drop with `@syntheticEventsMouseClick_InputEvents()`.
  Prove nesting with `panel.fullMoveTo …` (only the nested internal window travels).
- **Internal window dropped INTO a window → becomes its content** (`macroInternalWindowDroppedIntoWindowFits` /
  `macroResizeWindowContainingInternalWindow`): drop an internal window over an EMPTY external window — `WindowWdgt.add`
  (`:179`) re-parents it `ATTACHEDAS_WINDOW_CONTENT`, `adjustContentsBounds` (`:384`) COUPLES their bounds (the free-floating
  OUTER window sizes itself to WRAP the content + chrome), relabelled "window with an internal window". Then
  `@dragWindowResizerTo_InputEvents` resizes the outer and the inner content stretches to fill (the resizer sits at the inner
  window's corner, `resizerCanOverlapContents`). Shared fixture verbs: `buildExternalAndFreeInternalWindow_Macro()` (`return
  [extWin, intWin]`) + `dropInternalWindowIntoExternalWindow_InputEvents_Macro extWin, intWin` (`return extWin`) — see
  "Composing macros" in CLAUDE.md (one test owns the composite screenshot, the other reuses the fixture without re-shooting).
- **Close an inner (nested) window → the outer survives and stays reusable** (`macroClosingInnerWindowKeepsOuter`): the lifecycle
  follow-on to the bullet above. Once an internal window is the outer window's `@contents`, `@closeWindow_InputEvents intWin`
  (clicks the INNER window's own `.closeButton`) closes only it; the outer's `childBeingClosed(child)` (`WindowWdgt.coffee:204`)
  detects `child == @contents` and calls `resetToDefaultContents` (`:246`) — re-enabling drops and restoring the
  `WindowContentsPlaceholderText` ("Drop a widget in here") + the "empty window" label. The outer window is NEVER closed and stays
  functional: a fresh `@dragWidgetTo_InputEvents clock2, extWin` is accepted as its new content (relabelled "analog clock"). Build via
  the shared `buildExternalAndFreeInternalWindow_Macro()` and put an `AnalogClockWdgt` in the inner window with `intWin.add (new
  AnalogClockWdgt)` BEFORE `dropInternalWindowIntoExternalWindow_InputEvents_Macro extWin, intWin`. Three checkpoints (nested → inner
  closed, outer is a placeholder again → fresh clock dropped in) prove closing a CHILD window does not close its PARENT, which remains
  reusable. **DETERMINISM (this test is the one that exposed the SWCanvas cross-engine trig bug):** its nested clocks rendered 1–3 px
  differently between Safari's JavaScriptCore and Chrome's V8, because the platform `Math.sin/cos/atan2/acos` differ by ~1 ULP across JS
  engines and SWCanvas feeds them into `rotate()`/`arc()` flattening + the `acos`-driven arc segment count (axis-aligned window chrome,
  which avoids trig, matched byte-for-byte — the tell). FIXED at the framework level: the build installs `runtime-prelude/deterministic-
  trig.js` (a pure-arithmetic fdlibm port, only `+−×÷`/`sqrt`) over `Math.*` before any rendering, so all curved/rotated SWCanvas output
  is bit-identical on every engine (measured: matches native V8 pixel-for-pixel across the whole suite — a drop-in). So a dynamic
  `AnalogClockWdgt` is safe as a screenshot fixture; no need to swap it for a static stand-in. (A brief detour DID swap the clock for a
  static box; that masked the symptom — the right fix was making the engine deterministic, not avoiding curves.)
- **Window resizes to its content** (`macroWindowResizesToTextContent`): an empty `new WindowWdgt nil,nil,nil` adopts a dropped
  widget as content and a free-floating window sizes itself to WRAP it. Drop a wrapping `SimplePlainTextWdgt` via
  `@dragWidgetTo_InputEvents text, window`, then `text.setText longerString` ⇒ window grows, `shorterString` ⇒ shrinks. No caret
  editing — `setText` is enough. The content-driven converse of the handle-driven window resize.
- **Window with COMPOSITE (stack) content follows EVERY mutation; a SCROLL-panel content follows NONE**
  (`macroWindowWithSimpleVerticalPanelResizesAsContentChanges`): with a `SimpleVerticalStackPanelWdgt` as window content the
  chain is cell → stack wraps its cells → `adjustContentsBounds` wraps the window: dropping a wrapping lorem in resizes the
  window AROUND the re-wrapped cell, dropping an icon ON a cell inserts it AFTER the cell whose span contains the drop point
  (the document-stack insertion rule) and GROWS the window, Enter×3 at a caret inside a cell grows it again, and deleting the
  cell through its hierarchy menu (right-click the nested cell → "a SimplePlainText ➜" → "delete") COLLAPSES the window
  around what remains. The CONTRAST: a `SimpleVerticalStackScrollPanelWdgt` content (its ctor SEEDS a default "A small
  string / here another." paragraph, calls `disableDrops()` on the panel so drops route to the inner stack, and sets the
  inner stack `isLockingToPanels = true` so dragging it carries the WHOLE panel) absorbs overflow by CLIPPING — drop a big
  lorem after the seeded paragraph and the window's bounds are IDENTICAL before/after (no scrollbar at rest; the windowed
  scroll panel also adds the pencil/editing chrome to the titlebar). Fixture via the very creator methods the menu items
  call: `world.createSimpleVerticalStackPanelWdgt()` ((35,30) 370×325), `world.createSimpleVerticalStackScrollPanelWdgt()`
  ((430,25) 370×325), `world.createNewWrappingSimplePlainTextWdgtWithBackground()`, and `world.create new HeartIconMorph`
  (carried on the hand exactly like the "Heart icon" menu item — drop it with a no-button move +
  `@syntheticEventsMouseClick_InputEvents()`). No new verb.
- **Handle-resizing a wrapping-text window: width from the USER, height from the CONTENT**
  (`macroWindowWithPlainWrappingTextResizingFollowsContentSize`): the HANDLE-driven axis of the entry above. With a wrapping
  `SimplePlainTextWdgt` as window content, a `@dragWindowResizerTo_InputEvents` drag only decides the WIDTH: the text re-wraps to
  the new measure and the window's height snaps to the re-wrapped content, IGNORING the release point's y — widen (+140) and the
  window ends SHORTER than where the handle was released; narrow hard (to ~190) and it grows hundreds of pixels PAST the release
  point (off the canvas bottom — keep that clipping, the original's last shot had it; the visible release-vs-bottom gap IS the
  assertion). Fixture reuse: `world.createNewWrappingSimplePlainTextWdgtWithBackground()` builds the canonical two-paragraph
  yellow lorem VERBATIM (the 'simple plain text wrapping' menu item's own creator — locate it after with
  `@findTopWidgetByClassNameOrClass SimplePlainTextWdgt`); dropping the 500-wide lorem into a window wraps the window past the
  canvas's right edge — recover with the real user gesture, a TITLE-bar drag (`win.label.center()` + press-drag-release), not a
  programmatic move. No new verb.
- **Window CONTENT resize — free vs fixed width** (`macroWindowContentResizesFreely` / `macroWindowContentKeepsFixedWidth`): a
  dropped widget becomes `@contents`; on a window resize `WindowWdgt.adjustContentsBounds` (`:384`) resizes it per its
  `WindowContentLayoutSpec`'s `canSetWidthFreely`/`canSetHeightFreely`. A `CircleBoxMorph` has BOTH free → fills both dims; a
  `SliderMorph` keeps a FIXED width (`initialiseDefaultWindowContentLayoutSpec` makes width un-free) → stretches only in height,
  centred. DROP GOTCHA: a CircleBoxMorph drops fine with `@dragWidgetTo_InputEvents circle, win` (centre grab — no sub-widget),
  but a SliderMorph must be dropped with `slider.pickUp()` + a no-button move + `@syntheticEventsMouseClick_InputEvents()`
  (`@dragWidgetTo_InputEvents` would grab the slider's CENTRE = its BUTTON at value 50, moving the button not the slider).
- **Window CONTENT resize — aspect-CONSTRAINED (stays square)** (`macroClockInWindowKeepsSquareOnResize`): the third window-content
  case after free/fixed-width. An `AnalogClockWdgt` as window content keeps a SQUARE aspect at every window size — its
  `initialiseDefaultWindowContentLayoutSpec` sets `canSetHeightFreely=false` (`AnalogClockWdgt.coffee:32`) and it overrides
  `rawSetWidthSizeHeightAccordingly` to `@rawSetExtent new Point newWidth, newWidth` (`:36`) so width drives an EQUAL height; so
  `WindowWdgt.adjustContentsBounds` sizes the content from the recommended WIDTH and SKIPS the free-height branch (`:466-468`, gated
  on `contentsRecursivelyCanSetHeightFreely`). Build `new WindowWdgt nil,nil,nil` + `new AnalogClockWdgt` (self-sizes — no extent
  needed), drop the clock in with `@dragWidgetTo_InputEvents clock, win` (centre grab — no sub-widget), then
  `@dragWindowResizerTo_InputEvents win, …` OUT and IN — the clock stays circular/square both ways. Also the first DYNAMIC content
  (the clock, frozen during playback like the anchor test) inside a container.
- **Dropping INTO a NESTED window — and the square constraint through TWO layers**
  (`macroWindowWithAClockInAWindowConstructionTwo`): a window's drop gate only closes once it has REAL content — the ctor
  calls `disableDrops()` only when built WITH contents (`WindowWdgt.coffee:65-68`) and `reactToDropOf` does it on the first
  real drop (`:264-268`) — so an internal window ALREADY adopted as an external window's content still ACCEPTS a drop while
  empty: `@dragWidgetTo_InputEvents clock, intWin` (the nested inner's centre is its placeholder) makes the clock the INNER
  window's content (the inner relabels "analog clock", the outer keeps "window with an internal window"), and the aspect
  constraint then propagates through BOTH layers — `@dragWindowResizerTo_InputEvents extWin, …` re-fits the inner to the
  outer's content area and the clock stays SQUARE within the inner (the clock-square entry above, one nesting deeper).
  Fixture: the shared window-in-window verbs + a frozen `AnalogClockWdgt`. CONSTRUCTION-ORDER NOTE (REP): this is assembly
  order TWO (nest the EMPTY inner first, then fill it in place); order ONE (fill the free inner first, then nest the loaded
  composite) decomposes into beats already asserted — clock-into-a-free-window is the entry above, window-adopts-a-window is
  macroInternalWindowDroppedIntoWindowFits, loaded-composite resizes are macroResizeWindowContainingInternalWindow — which is
  why only order Two has a macro. No new verb.
- **NESTED collapse/uncollapse cascades through window layers — the full resize matrix** (`macroWindowsNestedCollapsingUncollapsing`):
  a window always WRAPS its content, so collapse state CASCADES through nesting. The switch collapses the window's CONTENT
  (`CollapseIconButtonMorph.actOnClick` → `@parent.parent.contents.collapse()`), the window reacts via
  `childBeingCollapsed`/`childCollapsed`/`childUnCollapsed` (`WindowWdgt.coffee:207-243`, store/restore extents) — with an
  internal window AS the outer's content (wrapping lorem AS the inner's), collapsing the INNER drops the OUTER to bar-plus-bar.
  The test resizes the EXTERNAL window in ALL FOUR (outer × inner) collapse combinations, each followed by the complete,
  step-by-step uncollapsing (a reviewer-requested matrix; the recording itself resized in only two of the four). The two
  regimes: a resize while the outer is UNCOLLAPSED (inner up or collapsed) is REAL — it persists through later uncollapses and
  the text re-wraps to it, both heights following the content, not the drag; a resize while the outer is COLLAPSED touches only
  the BAR (sticky across later collapses) and REVERTS on uncollapse — and what the revert restores depends on the INNER's state
  when the outer collapsed: the full composite (inner was up) or the short bar-plus-bar composite (inner was collapsed), which
  then needs the second, inner uncollapse step to re-inflate fully. (The single-EMPTY-window version of revert/stickiness is
  macroCollapsedWindowBarResizeRevertsOnUncollapse's.) TWO determinism gotchas pinned here: (1) macro shots deterministically
  include the LAST-CLICKED switch's hover + tooltip (the pointer rests on the icon that toggles into view under it — approved
  convention since macroWindowsEmptyCollapsingUncollapsing), so anchor byte-equality pairs on states produced by the SAME last
  click (no pointer-parking needed) — this test lands two such pairs (its step-by-step double restore == the earlier full state;
  an extra outer round trip == the case-3 restore); (2) a switch icon's PRISTINE construction-time paint is the class-default
  `Color.WHITE`, while any later repaint through `HighlightableMixin`'s state machine uses `color_normal` (245,244,245,
  `HighlightableMixin.coffee:14`) — the shift comes with the bar's first REPAINT (collapse/resize cycles trigger it regardless
  of the pointer), NOT with a pointer touch (verified: a restore shot byte-matched its partner even though one of them predated
  the switch's first-ever click), and it is exactly the 92 switch-glyph pixels separating the original recording's
  never-repainted fixture shot from its post-cycle restore — so geometry-restores byte-match each other but never the pristine
  fixture shot. Fixture: the shared window-in-window verbs + ONE lorem paragraph (same text/colors as
  `createNewWrappingSimplePlainTextWdgtWithBackground`) dropped into the inner window; drag the composite by its TITLE
  (`extWin.label.center()` + press-drag-release) so taller re-wrapped states stay on-canvas. No new verb.

## Scroll & scrollbars

- **ListMorph wheel scroll** (`macroListMorphWheelScroll`): a `ListMorph` (extends ScrollPanelWdgt) is a clipped column of rows.
  Build standalone — `new ListMorph nil, nil, [item strings]` — `rawSetExtent` SHORTER than its content so it overflows + shows
  a scrollbar; `@wheelOn_InputEvents list, deltaY` scrolls it (positive deltaY = DOWN). Tune the delta to the overflow (drop it
  if two later shots stop changing). Row-click highlight is NOT a reliable screenshot signal; scrolling is.
- **Slider/scrollbar TRACK click** (`macroSliderTrackClickMovesButton`): `@clickOnSliderTrackAtFraction_InputEvents doc.vBar,
  [0.5, fy]` clicks a SliderMorph's TRACK (background, OUTSIDE the button) to JUMP the button there — for a ScrollPanelWdgt's
  `@vBar`/`@hBar` this scrolls the content (`SliderMorph.mouseDownLeft` non-float-drags the button to the click when the
  slider's parent is a ScrollPanelWdgt OR PromptMorph; a slider parented to neither IGNORES it — the negative case). Click the
  TRACK not the button (a click ON the button just grabs it) — give enough overflow that the button is small.
- **Nested scroll-panel wheel routing + limit escalation** (`macroNestedScrollPanelsRouteWheel`): the wheel scrolls the INNERMOST
  scrollable under the pointer and ESCALATES to the container once the inner is maxed (`ActivePointerWdgt.processWheel` walks up
  to the nearest `wheel` handler; `ScrollPanelWdgt.wheel` scrolls itself UNLESS at the travel limit, then `escalateEvent 'wheel'`).
  Hold the pointer STILL near the inner's top (one `@syntheticEventsMouseMove_InputEvents (@pointAtFractionOf inner, [0.5,0.15]),
  "no button"`) then fire repeated `@syntheticEventsWheel_InputEvents 0, bigDelta` (the L1 primitive, NOT `wheelOn` which re-moves):
  the 1st bottoms the INNER, the next escalates to the OUTER. Build with a `SimpleDocumentScrollPanelWdgt` (`outer.add inner`
  between two `outer.addNormalParagraph "…"`) holding a fixed-height `ListMorph` (the stack constrains only WIDTH, so the inner
  keeps its height and overflows). FLANK the inner above AND below so it stays VISIBLE when the outer is fully scrolled.
- **Scrollbars track content** (`macroScrollBarsTrackContentChange`): `ScrollPanelWdgt.adjustScrollBars` (`:114`) shows the hBar
  only when `contents.width() >= width()+1` and the vBar only when `contents.height() >= height()+1`, sizing each thumb to the
  viewport/content ratio and positioning it by the scroll offset. Add a wrapping `SimplePlainTextWdgt` as a real SUBMORPH of the
  inner `@contents` (`panel.add text`); NARROW it (`text.rawSetWidth narrower` re-wraps it taller, synchronously, since
  `@maxTextWidth=true`) → vBar appears; MOVE it toward the bottom-right (`text.fullRawMoveTo`) → hBar appears + vBar thumb shrinks;
  re-run `panel.adjustContentsBounds()` + `panel.adjustScrollBars()` after each. TRAP: a single-widget contents (`new
  ScrollPanelWdgt child`) has no submorphs, so `adjustContentsBounds` re-fits it back to the viewport (undoing the overflow) —
  use a real submorph, or call `adjustScrollBars()` only.
- **Adding a child to a ListMorph recomputes its scroll** (`macroAddingMorphToListUpdatesScroll`): the recompute-on-ADD
  sibling of the content-change entry above (which recomputes on child MUTATION). `ScrollPanelWdgt.add` (`:186-194`) routes
  a non-handle widget into `@contents` and then AUTOMATICALLY calls `@adjustContentsBounds()` + `@adjustScrollBars()` — so
  adding a tall morph to a `ListMorph` (extends ScrollPanelWdgt) that previously just fit its rows makes a vertical
  scrollbar APPEAR, with NO manual recompute call (the recorded "attach...→a ListMorph" gesture IS exactly this `@add` +
  recompute, `Widget.coffee:3640-3645`). Build a standalone `new ListMorph nil, nil, [rows]` sized to ≈ its rows' height
  (so no scrollbar yet) + a distinct `RectangleMorph` positioned to PARTIALLY OVERLAP the list's lower edge and HANG BELOW
  it, then ATTACH it through the REAL menu (the recording's gesture — drive the menu, NOT an opaque `list.add`; reuses the
  `macroAttachResizingHandleToMorph` idiom): `@openMenuOf_InputEvents rect` → `@moveToItemOfTopMenuAndClick_InputEvents
  "attach..."` → `@moveToItemStartingWithOfMenuAndClick_InputEvents (@getMostRecentlyOpenedMenu()), "a ListMorph"`
  (class-name PREFIX). The OVERLAP is REQUIRED — `"attach..."` lists only bounds-intersecting targets
  (`world.plausibleTargetAndDestinationMorphs`), so a non-overlapping rect would not be offered the list. Widget.attach →
  list.add (ScrollPanelWdgt.add) re-parents the rect into `@contents` + auto-recomputes → image_2 shows the rect CLIPPED to
  the list (its hanging part cropped — proof it is now a child) AND a scrollbar APPEARED; then `@wheelOn_InputEvents list,
  delta` → rows + rect scroll together (image_3). Fills the gap `macroListMorphWheelScroll` explicitly LEFT OPEN (it
  distilled the same recording family to just the wheel-scroll core). GOTCHAS: size the list height ≈ its rows' height (so
  the attached rect lands just below the rows, not far down in dead viewport space → an ugly empty gap on scroll); place the
  rect's CENTRE on the part HANGING BELOW the list so the right-click lands cleanly on the rect, not the list. No new verb.
- **Add/remove at the document's END — the viewport stays ANCHORED to the end**
  (`macroSimpleDocumentRemovingLastParagraphUpdatesScrollbarAndLeavesViewportAtEndOfDocument`): the anchoring sibling of the
  two recompute entries above. Every paragraph DROP into / float-GRAB out of a `SimpleDocumentScrollPanelWdgt` re-runs
  `adjustContentsBounds` + `adjustScrollBars` (`ScrollPanelWdgt.reactToDropOf`/`reactToGrabOf`, `:236/:240`);
  `adjustContentsBounds` (`:244`) shrink-wraps the stack to its content (its `:277-290` comment NAMES the
  remove-at-the-bottom scenario) and `keepContentsInScrollPanelWdgt` (`:328`) clamps the view: while content overflows the
  BOTTOM-clamp keeps a fully-scrolled viewport pinned to the document's END (no vacant space in view); once content fits,
  the stack is grown to viewport height (`:302`) and the TOP-clamp re-anchors at the top — and `adjustScrollBars` hides the
  bar entirely. Fixture trick: use IDENTICAL lorem paragraphs (the Batch-47 document idiom — doc recipe at (35,30) 370×325
  + staged 500×300 lorems dropped in) so the bottom-anchored viewport is pixel-INVARIANT under removing the last paragraph
  (the window just slides up one identical paragraph): the only in-document delta is the SCROLLBAR — and an add-then-remove
  round-trip at the end restores the document region (text AND thumb) exactly. Dropping INTO the last visible paragraph's
  span while fully scrolled = append at the end JUST below the view (another scrollbar-only delta; wheel again to reach the
  new end). A freed paragraph lands on the desktop still wrapped at the document's content width
  (`macroDocumentPreservesDroppedWidgetSizes`'s mechanic, in reverse). Unlike a TIGHT-stack child (which needs the
  "pick up" hierarchy-menu gesture), a document paragraph IS directly float-draggable — grab it with
  `@dragWidgetTo_InputEvents` provided its centre is inside the visible clip. The Enter-typing growth-with-caret-follow
  variant of this family is `scrollCaretIntoView` = `macroDocumentCaretBroughtIntoViewWhenMoved`'s mechanic. The font-size
  and wrap-toggle twins of this clamp resolution are the next two entries. No new verb.
- **Font-size change under an END-SCROLLED viewport — the clamp re-anchors at the top**
  (`macroWrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo`): the FONT-driven sibling of the
  end-anchoring entry above, on a `SimplePlainTextScrollPanelWdgt`. `SimplePlainTextWdgt.setFontSize`
  (`SimplePlainTextWdgt.coffee:165-168`) re-breaks the text (`reLayout :183-199`: wrapped height = lineCount × fontHeight)
  and refreshes the enclosing panel, so the same `adjustContentsBounds` clamps resolve the new content extent: ENLARGING
  under a top-anchored view just grows the content downward (the V-bar appears, thumb at the top, viewport unmoved);
  SHRINKING back to the default WHILE FULLY SCROLLED DOWN makes the end offset impossible — the content fits again, so
  grow-to-viewport + TOP-clamp re-anchor the view at the top and `adjustScrollBars` hides the bar, BYTE-identical to the
  pristine fixture (the retired no-wrap flavour restored byte-for-byte too — the clamp path is wrap-agnostic). FIXTURE:
  the 'simple plain text scrollpanel wrapping' demo recipe (`Widget.createWrappingSimplePlainTextScrollPanelWdgt:3089` —
  (20,25) 390×305, padding 10, one wrapping lorem at the default font 12, which FITS: no bar at baseline). MENU
  DISCOVERY: the text is `lockToPanels`'d and the panel sets `takesOverAndCoalescesChildrensMenus`
  (`SimplePlainTextScrollPanelWdgt.coffee:25`), so a right-click opens ONE coalesced menu with 'font size...' at TOP
  level — NO hierarchy descent (unlike a document paragraph); then the banked Meta+a-overtype prompt dance. While
  end-scrolled the tall text's centre is above the viewport clip — right-click a bottom FRACTION (`[0.5, 0.95]`).
  No new verb.
- **Soft-wrap toggle INSIDE a scroll panel — `softWrapOff`/`softWrapOn`, NOT `toggleSoftWrap`**
  (`macroSimplePlainTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent`): on a `SimplePlainTextWdgt`
  inside its scroll panel the '☒/☐ soft wrap' items are the TEXT's OWN (`SimplePlainTextWdgt.coffee:90-98`, shown only
  when it is the panel's LONE child) and call `softWrapOff` (`:111-117`: panel `isTextLineWrapping` false +
  `maxTextWidth = nil`) / `softWrapOn` (`:103-109`: both back, plus re-homing the panel's contents to the panel origin) —
  TextMorph2's `toggleSoftWrap` is NOT involved. The bare-TextMorph2 no-menu drift does NOT apply here either: the
  coalesced in-panel menu OPENS for synthetic right-clicks, so drive the REAL items (match the decorated label by
  SUBSTRING, `moveToItemContainingOfMenuAndClick`). Toggling OFF while scrolled at the END collapses the content to its
  unbounded logical rows (width = LONGEST line, `reLayout :191-196`) → it fits vertically → the view re-anchors at the
  TOP with the V-bar swapped for an H-bar (thumb at the LEFT: the x offset was never touched); toggling ON re-wraps tall
  with the view at the top. Produce "at the bottom" via the CLIPBOARD: Meta+a + `copySelection_InputEvents` + ArrowRight
  + 3× `pasteText_InputEvents` quadruples the text and each paste's caret-follow (`CaretMorph.gotoSlot`'s scroll-panel
  branch) drags the view to the end — then drop the caret with a desktop click before the screenshot. Everything is
  exactly reversible: the wheel-to-end after the toggle round trip is byte-identical to the pre-toggle end view (this
  macro reproduced its recording's reference pixels hash-for-hash at both densities). No new verb.
- **A nested WINDOW's lifecycle re-syncs its scroll panel** (`macroScrollPanelUpdatesCorrectlyOnCollapsingAndUncollapsingAndClosingWindow`):
  the window-lifecycle sibling of the two recompute entries above. A `WindowWdgt` nested INSIDE a ScrollPanelWdgt actively refreshes it:
  `childCollapsed`/`childUnCollapsed` both END with `refreshScrollPanelWdgtOrVerticalStackIfIamInIt()` (`WindowWdgt.coffee:232/:244` →
  the `Widget.coffee` helper calls the enclosing panel's `adjustContentsBounds()` + `adjustScrollBars()` when the widget sits directly
  inside one) — so collapsing the nested window (content shrinks to its bar), uncollapsing (the stored pre-collapse extent re-overflows
  the viewport), and closing it (panel empties) each snap the scrollbars to the new content extent with no manual recompute. Beats:
  carry-drop an internal window (`pickUp` + no-button move + click — it nests, `macroInternalVsExternalWindowDrop`'s mechanic) so it
  OVERFLOWS the panel's right edge → hBar appears; collapse → bar-only content, scrollbars track; move the bar by its TITLE + narrow it
  via its resizer + park it inside the viewport → scrollbars RETRACT (the in-panel application of
  macroCollapsedWindowBarResizeRevertsOnUncollapse — narrow is sticky for the BAR, the expanded extent untouched, which is exactly why
  the next uncollapse re-overflows); close via the chrome button → empty panel, clean viewport. SEQUENCING GOTCHA: the nested bar's
  resizer starts CLIPPED outside the viewport — drag the bar INTO view by its title FIRST, then narrow, then park (the recording's own
  three-gesture order, decoded by pixel-diffing its references). Anchor a byte-equality on two shots produced by the SAME switch click
  (here both UNCOLLAPSE clicks: image_7 == image_5) — the last-clicked switch's hover + tooltip are part of macro shots, so equality
  pairs with different last gestures (the recording's bar-state pair) would differ by exactly that hover. Fixture: the demo
  "scrollable panel" via the real menu path + carry-drop (same as macroMenuPinnedInScrollPanel). No new verb.
- **Window CELLS in a constrained scroll-STACK: collapse/close reflow + live width tracking**
  (`macroWindowCellsInConstrainedScrollStackReflow`): the STACK-branch sibling of the entry above.
  `refreshScrollPanelWdgtOrVerticalStackIfIamInIt` (`Widget.coffee:1485-1490`) has TWO branches — directly-in-a-scroll-panel
  (the entry above) and `parent instanceof SimpleVerticalStackPanelWdgt`, where it calls the STACK's `adjustContentsBounds()`:
  collapsing/uncollapsing/closing a window CELL slides the cells below up/down and re-derives the enclosing panel's scrollbars.
  Fixture: a `SimpleVerticalStackScrollPanelWdgt` (a ScrollPanelWdgt whose contents is a constraining stack with
  `isLockingToPanels` — grabbing its interior grabs the WHOLE composite, which is how it drops into an outer window; clear its
  default `SimplePlainTextWdgt` first) + internal windows that adopt COLOURED RECTANGLES — the rectangles carry the width,
  because an adopting window WRAPS to its content (a preset extent is discarded), and they must be WIDER than the stack so the
  cap binds (it never stretches up). STAGE one drop at a time: grabs target widget CENTRES and the desktop is too small to park
  everything without something covering someone else's centre. Squeeze/widen via `dragWindowResizerTo_InputEvents` with DELTAS
  off `win.resizer.center()` (the verb releases the handle centre AT the destination — absolute corner targets shift the window
  by the handle-centre offset): the cells re-cap against the LIVE stack width both ways, and the round trip is byte-identical.
  The collapse round trip byte-anchor needs a SECOND round trip (post-repaint states match each other; the FIRST restore differs
  from the pristine shot by exactly the `HighlightableMixin` pristine-vs-repaint glyph rule of the nested-collapse entry). Park
  the pointer on one clear spot before every shot. No new verb.
- **Edge auto-scroll while dragging** (`macroListMorphAutoScrollsNearDraggedEdge`): a ScrollPanelWdgt auto-scrolls when a
  float-dragged morph it `wantsDropOf` is held near an edge band (≈`scrollBarsThickness*3`). Build a list overflowing BOTH ways,
  `pickUp` a rectangle (don't drop), then `@syntheticEventsMouseMove_InputEvents (a point in an edge band), "no button", …` and
  yield generously. MUST hold long enough that the `autoScroll` 500ms `Date.now()` settle elapses and the scroll CLAMPS — via a
  NON-scaled numeric `yield N` (real-time settle, speed-independent), so it's deterministic at every speed and needs no speed metadata.
- **Unplug an inspector scrollbar + the duplicate ASYMMETRY** (`macroInspectorScrollbarUnplugged`): open the OLD small
  `InspectorMorph` via the DIRECT "inspect" item (NOT `bringUpInspector_…_Macro`'s "dev → inspect", which opens InspectorMorph2).
  Capture `scrollbar1 = inspector.list.vBar` BEFORE detaching (the list doesn't rebuild it). Right-click its knob → hierarchy
  "a SliderMorph" → "pick up" → carry + drop CLEAR. It STILL drives the list: `@dragSliderButtonToFraction_InputEvents
  scrollbar1, [0.5, fy]` (`detachesWhenDragged` is false when the button's parent is a SliderMorph). DUPLICATE it ("duplicate"
  instead of "pick up"); `fullCopy` copies the `target` reference so the copy ALSO drives the list. ASYMMETRY: dragging the copy
  scrolls the list and `scrollbar1` FOLLOWS (the list updates its own @vBar via `adjustScrollBars`); dragging `scrollbar1`
  scrolls the list but the copy — which the list has no back-reference to — stays put.
- **A vertical scrollbar IGNORES the sideways component of a button drag**
  (`macroMovingSlidersSidewaysDoesntCauseContentToMoveSideways`): `SliderButtonMorph.nonFloatDragging` (`:68`) pins a
  vertical slider's button to its own column (`newX = @left()` — the drag's x is DISCARDED) and clamps the y to the
  track; `parent.updateValue()` fires only when the button actually MOVED, and `endOfNonFloatDrag` (`:90`) resets the
  button's visual state on release. So a pure-sideways press-drag-release
  (`@syntheticEventsMouseMovePressDragRelease_InputEvents (@pointAtFractionOf scrollbar.button, [0.5,0.5]), (new Point
  (x-80), sameY)`) is a COMPLETE no-op — capture before/after shots and their byte-equality (same reference dataHash)
  IS the assertion — while a diagonal drag scrolls by its vertical component only. Fixture: the old-inspector
  scrollbar (`inspector.list.vBar`, the unplug entry above). PARK the pointer at one fixed empty-desktop spot before
  EVERY shot (a no-button `@syntheticEventsMouseMove_InputEvents`) so hover state can never break the equality. No
  new verb.
- **A document flows, clips and scrolls live non-text widgets** (`macroDocumentScrollsMixedTextAndClocks`): a
  `SimpleDocumentScrollPanelWdgt` is a general widget container, not just a text flow. `doc.add widget` re-parents any widget into its
  inner `SimpleVerticalStackPanelWdgt` content stack (`ScrollPanelWdgt.add → @contents.add`, `:186-194`), which `@augmentWith
  ClippingAtRectangularBoundsMixin` clips to the panel box. On insert the stack re-squares an `AnalogClockWdgt` to its remembered width
  (`VerticalStackLayoutSpec.rememberInitialDimensions` + `AnalogClockWdgt.rawSetWidthSizeHeightAccordingly`); getWidthInStack DISPLAYS
  that remembered width CLAMPED to the current column — so clocks added at distinct sizes stay distinct, one wider than the column is shown
  clamped (clipped at the panel edges as you scroll), and it GROWS BACK toward its remembered size when the document is WIDENED (the clamp
  relaxes). Build the fixture DIRECTLY (`doc.addNormalParagraph "…"` + `doc.add clock`): the test targets the
  SCROLL/FLOW/CLIP of mixed content, not the drop GESTURE (covered by macroIconDroppedIntoDocumentFlows — and dragging several
  oversized clocks by hand is needless flakiness: a mis-grabbed big clock leaks onto the desktop). `@wheelOn_InputEvents doc, delta`
  scrolls (positive = down; `ScrollPanelWdgt.scrollY` clamps at the travel limits, so the top/bottom shots are deterministic). The
  clocks freeze (`new Date 2011,10,30`) during playback, so a LIVE dynamic widget is a safe screenshot fixture (precedent:
  macroAnalogClockInspectEdit). Interleave a tall text paragraph BEFORE and AFTER the clocks so the narrow-document scroll positions
  (top / oversized-clock-clipped / bottom-with-trailing-text) are distinct. Then `doc.rawSetExtent` to near-fullscreen (a fixture-state
  change) + `adjustContentsBounds`/`adjustScrollBars`: the text reflows wider and the clamped clock grows back, and a wheel-scroll back UP
  shows the reflowed content (image_4 widened+bottom / image_5 widened+mid / image_6 widened+top). First document-handles-a-dynamic-widget
  test. No new verb.
- **No SPURIOUS scrollbars on resize** (`macroNoSpuriousScrollbarsOnScrollPanelResize`): the NEGATIVE of
  `macroScrollBarsTrackContentChange` — a bar appears ONLY when content overflows, so moving content around inside a panel and
  RESIZING it while the content still FITS must spawn NONE. Same `adjustScrollBars` gate (`ScrollPanelWdgt.coffee:114`; hBar
  `:143-160` / vBar `:163-180`), re-evaluated on `rawSetExtent` (`:232-233`) AND on entering resize/move mode
  (`showResizeAndMoveHandlesAndLayoutAdjusters` override, `:204-207`). Build `new ScrollPanelWdgt` + a default `new BoxMorph`
  (Widget defaults: 50×40, dark, fits with room to spare) added via `panel.add box` (routes into `@contents`); move the box around
  with `@dragWidgetTo_InputEvents box, pt` (re-drop re-parents into `@contents`, re-runs the gate — still fits, no bar); then
  `@openMenuOf_InputEvents panel` → `@moveToItemOfTopMenuAndClick_InputEvents "resize/move..."` → `@dragResizeMoveHandleTo_InputEvents
  "resizeBothDimensionsHandle", dest` SHRINKS the panel (the final shot is taken WITH the handles showing — do NOT click empty
  desktop to leave the mode first, unlike `macroCanMoveAndResizeColorPaletteMorph`). MUST shrink not grow (growing the bottom-right
  extends the world's scrollable extent → perturbs the SWCanvas frame; compute `dest` from `panel.bottomRight()` minus a positive
  delta). No new verb.
- **A wheel-scroll DESTROYS the temporary resize/move handles** (`macroResizingScrollFrameThenImmediatelyScrollingTheHandlesDontStickToScrollPanelContent`):
  the handles-vs-scroll guard — `ScrollPanelWdgt.wheel`'s FIRST act, before any scrolling or limit escalation, is
  `world.hand.destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem @` (`ScrollPanelWdgt.coffee:540-542`; the src
  comment names the regression: "if we don't destroy the resizing handles, they'll follow the contents being moved!"). The
  handle life cycle: "resize/move..." runs `showResizeAndMoveHandlesAndLayoutAdjusters` (`Widget.coffee:2767-2790`) — a
  FREEFLOATING widget gets the four handles into `world.temporaryHandlesAndLayoutAdjusters`, a non-freefloating one RECURSES to
  its parent, so invoking it from a document's menu parks the handles on the freefloating scroll FRAME; `ScrollPanelWdgt.add`'s
  HandleMorph carve-out (`:186-194`) keeps them direct children of the frame (NOT inside the scrolled `@contents`); any
  mouse-DOWN on a non-handle also destroys them (`ActivePointerWdgt.coffee:378` — how a desktop click exits the mode). Fixture =
  the document-drop idiom (a `createSimpleDocumentScrollPanelWdgt` doc + two `createNewWrappingSimplePlainTextWdgtWithBackground`
  yellow texts dragged in with `@dragWidgetTo_InputEvents`; the stack inserts a drop AFTER the sibling whose vertical span
  contains the drop point — crib `macroIconDroppedIntoDocumentFlows`). MENU GOTCHA: the doc's stack cells are width-constrained
  to the FULL content width, so virtually any right-click inside the doc hits a CELL and opens the hierarchy/disambiguation
  menu (the recording threaded the few-pixel inter-cell gap to hit the stack directly — do NOT try to reproduce that); navigate
  it instead — `@openMenuOf_InputEvents firstElement` → `@moveToItemStartingWithOfMenuAndClick_InputEvents (@getMostRecentlyOpenedMenu()),
  "a SimpleDocumentScrollPanel"` → `"resize/move..."` (the stack panel itself is EXCLUDED from the hierarchy menu as redundant,
  `Widget.getHierarchyMenuMorphs:2955`). Assert by screenshot pair: handles parked on the frame, then `@wheelOn_InputEvents text, deltaY`
  twice → handles GONE + content scrolled; pick deltas that overshoot so the view CLAMPS at the content bottom (robust to small
  delta drift). No new verb.
- **Free-width scroll-stack shows a HORIZONTAL scrollbar** (`macroFreeWidthScrollStackShowsHorizontalScrollbar`): the FIRST
  horizontal-bar macro (every other scroll macro is vertical). `new SimpleVerticalStackScrollPanelWdgt false` (the
  `isTextLineWrapping=false` ctor arg) sets the inner stack's `constrainContentWidth=false` (`SimpleVerticalStackScrollPanelWdgt.coffee:6-7`),
  so a NON-wrapping child keeps its natural width (`SimpleVerticalStackPanelWdgt.coffee:92-104` left-aligns + skips the width clamp)
  → `@contents.width()` exceeds the viewport → `adjustScrollBars` shows the hBar (`ScrollPanelWdgt.coffee:143-145`, the
  `contents.width() >= width()+1` gate). Append a wide non-wrapping `SimplePlainTextWdgt` with `para.maxTextWidth = nil;
  para.reLayout()` (the wrap-OFF idiom, `SimplePlainTextWdgt.reLayout:186-196`; cribbed from `macroNonWrappingTextResizesToContent`)
  via `panel.add` — its long lines CLIP at the right edge. Scroll horizontally with `@wheelOn_InputEvents panel, 0, deltaX`
  (deltaY=0, positive deltaX scrolls RIGHT — `wheelOn_InputEvents`'s 3rd positional arg) → the clipped-off right portion comes into
  view, the horizontal thumb travels right. GOTCHAS: the free-width DEFAULT doc is already wider than a small viewport, so the hBar
  is present from image_1 (faithful to the original — frame it as "bar present + scroll it", not "bar appears"); set `maxTextWidth=nil`
  + `reLayout()` BEFORE `panel.add`; do NOT `setContents` (it wipes the default doc — use `add`). No new verb.

## Drag/drop, attach/detach, duplicate

- **Drag a widget into a container** (`macroSimpleDocumentManualBuildAndScroll`, `macroIconDroppedIntoDocumentFlows`):
  `@dragWidgetTo_InputEvents widget, target` float-grabs at the widget's centre (press-drag past the grab threshold) and drops it
  at a Point or onto a widget's centre. A SimpleDocument's INNER content panel (`SimpleVerticalStackPanelWdgt`,
  `_acceptsDrops:true`) flows arbitrary widgets, so a drop over its content area re-parents the widget as a flowing paragraph —
  no "enable editing" needed (the OUTER scroll panel's `@disableDrops` only gates its chrome). INSERTION INDEX ↔ drop Y:
  `SimpleVerticalStackPanelWdgt.add` (`:34-42`) inserts AFTER the sibling whose vertical span contains the drop Y, APPENDS if the
  Y is in a gap/below all — **index 0 is unreachable**; aim at a sibling's `.center()` for "after it", `lastEl.bottom()+N` to append.
- **`@dragWidgetTo_InputEvents` grabs the CENTRE — which may be a sub-widget.** For a SliderMorph (button at the centre at value 50)
  it grabs/moves the BUTTON, not the slider (the drop silently does nothing). Drop such a widget programmatically: `widget.pickUp()`
  + a no-button `@syntheticEventsMouseMove_InputEvents` + `@syntheticEventsMouseClick_InputEvents()`. A plain shape
  (BoxMorph/CircleBoxMorph/RectangleMorph) has no sub-widget, so `@dragWidgetTo_InputEvents` is fine.
- **Attach to a target** (`macroAttachResizingHandleToMorph`): drop the morph so it OVERLAPS the target (required —
  `Widget.attach` lists only morphs whose bounds INTERSECT it, `world.plausibleTargetAndDestinationMorphs`, excluding self +
  current parent), then `clickMenuItemOfWidget_InputEvents_Macro morph, "attach..."` → capture the "choose target:" menu →
  `@moveToItemStartingWithOfMenuAndClick_InputEvents menu, "a RectangleMorph"` (class-name PREFIX; the menu also lists the World).
  A HandleMorph so attached becomes the target's resize handle → drag it with `@dragResizeMoveHandleTo_InputEvents`.
- **"Attach…" with no targets → a message** (`macroAttachShowsNoTargetsMessage`): a morph alone (nothing overlapping) → `attach`
  pops a `MenuMorph` titled **"no morphs to attach to"** (`:3680`) instead of a target list; that titled, item-less menu IS the
  message. The negative path of attach.
- **Attach EXCLUDES the parent — a lonely widget attaches to NOTHING, not even the world**
  (`macroLonelySliderCantBeAttachedToAnything`): `Widget.attach` (`Widget.coffee:3657`) filters its
  `plausibleTargetAndDestinationMorphs` candidates by `each != @parent` — for a bare desktop widget the parent IS the world, so
  the list is EMPTY and the "no morphs to attach to" menu pops with ZERO items, while "set target"
  (`ControllerMixin.openTargetSelector`) on the SAME fixture keeps the world (re-attaching to your parent is a no-op; controlling
  it is meaningful). Assert the zero-item shape with `@assertTopMenuItemCount 0` + `@assertTopMenuItemStrings []` — the menu's
  title is NOT an item (`MenuMorph.testItems` excludes `@label`), so a titled-but-empty menu counts 0. Reuses
  macroLonelySliderTargetsWorldOnly's lone-slider fixture verbatim (right-click the LOWER track), so the attach-vs-set-target
  contrast is asserted on an identical scene. No new verb.
- **Attach/target candidates EXCLUDE a clipped morph** (`macroAttachTargetExcludesClippedMorph`): both "attach..."
  (`Widget.attach`) and a controller's "set target" (`ControllerMixin.openTargetSelector`) build their candidate menus
  from `world.plausibleTargetAndDestinationMorphs` (`Widget.coffee:846`), but a `PanelWdgt` (which `@augmentWith
  ClippingAtRectangularBoundsMixin`) OVERRIDES it (`ClippingAtRectangularBoundsMixin.coffee:17`) to recurse into its
  children ONLY where the PANEL's own bounds intersect the probe. So a child whose raw bounds stick out past the panel
  edge (clipped there) is UNREACHABLE as a candidate when the probe sits over the clipped-away part — the exclusion is a
  logical-AND of two raw-bounds intersections (`panel∩probe` AND `child∩probe`), NOT a per-pixel hit-test. Build `new
  PanelWdgt`, `panel.add rect`, `rect.fullMoveTo` to STRADDLE the right edge; drop a probe ENTIRELY right of the panel
  (over the rect's clipped-away raw bounds): `clickMenuItemOfWidget… "attach..."` → `@assertTopMenuItemCount 0` ("no
  morphs to attach to"); a slider's "set target" → `@assertTopMenuItemStrings ["a WorldMorph ➜"]`. KEY: the probe must
  overlap ONLY the clipped-away part — if it also overlaps the panel, the recursion runs and the rect reappears (leave a
  clear gap to the panel edge). Distinct from macroAttachShowsNoTargetsMessage (genuinely nothing overlapping) — here a
  morph IS there, but clipped out of the candidate list.
- **Detached morph stays float-draggable** (`macroDetachedMorphStaysFloatDraggable`): float-vs-non-float dragging is computed LIVE
  from the parent, not a stored flag — `Widget.grabsToParentWhenDragged` (`:2513`) is false when the parent is the WORLD (the hand
  grabs the morph itself = float drag) and true when the parent is another morph (dragging grabs the PARENT, so they move
  together). "attach…" re-parents under the chosen target (`Widget.attach → target.add`, `:3657/:3642`); "detaching" = pick up +
  drop on the desktop, which resets the parent to the world. So after attach + detach the morph float-drags independently again.
  GOTCHA: "attach…" is a TOP-LEVEL item, but "pick up" lives in the morph's "a <Class> ➜" HIERARCHY submenu — `clickMenuItemOfWidget
  …, "pick up"` finds nothing and crashes; use `pickUp()` directly or navigate the submenu.
- **Duplicate a widget — copy rides the hand** (`macroDuplicateSimpleWidgetRidesHand` / `…ComplexWidget…`): a normal widget's
  context menu carries a TOP-LEVEL "duplicate" (`Widget.duplicateMenuActionAndPickItUp` = `fullCopy().pickUp()`), so
  `clickMenuItemOfWidget_InputEvents_Macro widget, "duplicate"` makes the COPY ride the hand (already painted on pickup); carry it
  with `@syntheticEventsMouseMove_InputEvents` (a grabbed hand-child follows even a no-button move) and DROP with
  `@syntheticEventsMouseClick_InputEvents()`. **image_1 is taken with NO pointer movement after the click** — the copy must be
  fully painted the instant it is grabbed. Duplicating a COMPLEX/nested widget: right-click it → ancestor hierarchy menu →
  navigate by class-name PREFIX to the desired ancestor's own menu → "duplicate". (A MenuMorph CONTAINER is not right-clickable
  for a context menu, but a MenuItemMorph — an individual item — IS: see the next bullet.)
- **Duplicate a MENU ITEM into the bare world** (`macroMenuItemDuplicatesToStandaloneMorph`): a `MenuItemMorph` is an ordinary
  duplicable Widget. Right-click an item of an open menu (e.g. the world menu's "demo ➜") → its ANCESTOR hierarchy menu; under the
  determinism toggles the item's own entry is the clean `"a MenuItemMorph ➜"` (no instance number/bounds — `Widget.toString:467`
  with `HidingOfMorphsNumberIDInLabels`), so an EXACT match is stable. Drill `"a MenuItemMorph ➜"` → `"duplicate"`: the copy rides
  the hand; carry it with `@syntheticEventsMouseMove_InputEvents` and DROP with `@syntheticEventsMouseClick_InputEvents()` (the
  mouse-DOWN releases the float-drag). Capture the "demo ➜" target item from `getMostRecentlyOpenedMenu()` WHILE the world menu is
  still fresh (the next click clears `freshlyCreatedPopUps`). image_1 = a standalone "demo ➜" menu-item morph alone on the desktop.
  **The detached copy stays FUNCTIONAL:** because "demo ➜" is a submenu-opener, left-clicking the standalone item opens the demo
  menu (locate it via `world.topWdgtSuchThat (w) -> (w instanceof MenuItemMorph) and (w.labelString == "demo ➜")` — the only menu
  item left once the menus close), then `@moveToItemOfTopMenuAndClick_InputEvents "rectangle"` makes a rectangle that rides the
  hand → drop on the world. image_2 = the detached item + the rectangle it produced (reproducing the recording's full arc).
- **Duplicate an INSPECTOR → an independent second inspector (independent close)** (`macroDuplicatedInspectorsCloseIndependently`): the
  duplication trio's third case (after a plain widget and a menu item). The OLD `InspectorMorph` (a BoxMorph spawned by the
  context-menu top-level "inspect" — `clickMenuItemOfWidget_InputEvents_Macro string, "inspect"`; NOT the "dev ➜ → inspect"
  `InspectorMorph2`; demo string is the OLD `StringMorph`, so NO right-click drift) does not block duplication: right-click it → its
  child pane's ANCESTOR hierarchy menu → `"a InspectorMorph ➜"` → `"duplicate"` (= `fullCopy().pickUp()`, a DEEP copy) → carry +
  `@syntheticEventsMouseClick_InputEvents()` to drop. The copy is a fully INDEPENDENT live inspector. KEY: an InspectorMorph is NOT a
  `WindowWdgt`, so `@closeWindow_InputEvents` does NOT apply — close it via its OWN `@moveToAndClick_InputEvents inspector.buttonClose`
  (a "close" TriggerMorph, `InspectorMorph.coffee:15`). Disambiguate the two by object identity — `insp2 = world.topWdgtSuchThat (w) ->
  (w instanceof InspectorMorph) and w != insp1` — and lay them out with `fullMoveTo` for a clean shot. Closing one leaves the other
  untouched (two → one → only the string), proving duplicated inspectors have independent lifecycles.
- **Locking** (`macroLockToDesktopPreventsDrag` / `macroLockedCompositeWidgetPreventsDrag`):
  `@moveToItemOfMenuAndClick_InputEvents menu, "lock to desktop"` then later `"unlock"` (substring) — the "lock to/unlock from
  <desktop|panel>" items appear only when the morph's parent is a PanelWdgt (the world is one). A locked morph's drag grabs its
  PARENT (`grabsToParentWhenDragged → @isLockingToPanels`), so `@dragWidgetTo_InputEvents` leaves it put; unlock and it moves.
- **Contents-lock REJECTS drops** (`macroLockedDocumentRejectsDrop`): the drop-side sibling of the drag-lock above. A
  `SimpleDocumentScrollPanelWdgt` (ships its own default text; `new …; world.add`) accepts a dropped widget into its vertical
  stack while editing is ENABLED. Its "disable editing" item → `disableDragsDropsAndEditing` (`SimpleVerticalStackScrollPanelWdgt.coffee:34`
  → `ScrollPanelWdgt.coffee:630` → `disableDrops`) clears the inner content panel's `_acceptsDrops`; now
  `ActivePointerWdgt.dropTargetFor` walks PAST the locked doc up to the WORLD, so the next drop lands as a world child ON TOP of the
  doc, NOT in its flow. Reach "disable editing" by the hierarchy drill (right-click a doc blurb → `"a SimpleDocumentScrollPanel ➜"`
  → `"disable editing"`). Make the negative meaningful with the accepted-vs-rejected contrast: a blue box dropped while enabled
  flows into the stack (image_1), a red box dropped while locked floats over the doc (image_2). The accepted box uses
  `@dragWidgetTo_InputEvents box1, doc` (drops at the centre, flows in); **drop the REJECTED box STRADDLING the doc's right edge**
  (pass a Point, e.g. `@dragWidgetTo_InputEvents box2, (new Point 335, 170)` for a doc at x[50,370]) — an ACCEPTED in-flow widget is
  CLIPPED at the doc edge (a scroll panel crops its contents), so a visible right-side OVERHANG is unambiguous proof the rejected
  box is a world child painted ON TOP, not clipped document content. (Without the overhang, a box dropped at the doc centre reads
  ambiguously as "maybe inside".)
- **An inspector REJECTS a drop on ANY of its three panes** (`macroInspectorRejectsDrops`): the inspector counterpart of the contents-lock
  reject above. An OLD `InspectorMorph` (a BoxMorph) overrides neither `wantsDropOf` nor `_acceptsDrops`, so the inherited
  `Widget._acceptsDrops=false` (`Widget.coffee:104`) applies, AND each of its three panes — `@list` (left), `@detail` (upper-right),
  `@work` (lower-right) — additionally calls `disableDrops()` (`InspectorMorph.coffee:143/164/177`). **A drop is resolved by the POINTER's
  position over the destination**, so carry a second inspector and release it with the pointer over EACH pane in turn —
  `insp1.detail.center()`, `insp1.work.center()`, `insp1.list.center()` (the recording's pane order). Every time
  `ActivePointerWdgt.dropTargetFor` finds the pane refuses, walks PAST the inspector (also refuses) to the world (`WorldMorph extends
  PanelWdgt`, `_acceptsDrops:true`), and `world.add` re-homes the dragged inspector as a world SIBLING painted FULL-SIZE on top.
  **Full-size-on-top IS the per-shot visible proof of non-nesting** — a widget that had truly nested into a pane would be CLIPPED inside
  that clipping scroll/list pane; a rejected one stays full-size and unclipped. Open two inspectors with
  `clickMenuItemOfWidget_InputEvents_Macro s, "inspect"` twice on an OLD `new StringMorph` (move insp1 clear of the string before the
  second right-click); disambiguate by identity (`w instanceof InspectorMorph and w != insp1`). GRAB an inspector by its title bar
  `insp2.label.center()` (a NON-editable TextMorph) — its CENTRE is the editable detail/work text, which a press would edit instead;
  carry+release with `@syntheticEventsMouseMovePressDragRelease_InputEvents insp2.label.center(), insp1.<pane>.center()`. image_1 two
  apart → image_2/3/4 insp2 dropped over the detail/work/list pane in turn, each landing full-size on top — none of the three accept it.
- **Disassemble an inspector — pick its PARTS out onto the desktop** (`macroPickingUpPartsFromInspector`): the OLD `InspectorMorph` is built
  from independent part widgets (a left `@list`, an upper `@detail` + lower `@work` ScrollPanelWdgt, a footer of `@buttonSubset/buttonInspect/
  buttonEdit/buttonClose` TriggerMorphs — `InspectorMorph.coffee:135-214`), and each part's hierarchy-menu **"pick up" detaches the REAL part**:
  `Widget.pickUp` (`Widget.coffee:2705`) runs `world.hand.grab @` on the receiver itself (contrast "duplicate" = `fullCopy().pickUp()`, which
  grabs a COPY). So dropping a picked-up part on the bare desktop leaves a standalone widget and a GAP in the gutted inspector. Locate each part
  by its STRUCTURAL ref (`insp.detail`/`insp.work`/`insp.buttonClose`/`insp.buttonEdit` — the digest's by-meaning «Panel» is ambiguous across
  the 3 panes), captured UP FRONT (the inspector re-lays-out as parts leave). A per-test helper (in `extraSubroutineSources`) DRYs the gesture:
  right-click the part (`@moveToAndClickAtFractionOf_InputEvents part, [0.5,0.5], "right button"`) → its hierarchy submenu BY MEANING
  (`@moveToItemStartingWithOfMenuAndClick_InputEvents theMenu, "a ScrollPanel"|"a TriggerMorph"`) → `@moveToItemOfMenuAndClick_InputEvents
  (@getMostRecentlyOpenedMenu()), "pick up"` → carry on a no-button move → drop with `@syntheticEventsMouseClick_InputEvents()` (a mouse-DOWN
  releases a float-dragged morph). GOTCHA: the OLD InspectorMorph has NO `.closeButton` (it is a BoxMorph, not a WindowWdgt — `closeWindow_InputEvents`
  would crash); "pick up" lives in the morph's HIERARCHY submenu, not top-level; the whole menu needs `world.isDevMode` (true under the harness).
  First inspector-disassembly test. No new verb.
- **Dropped widgets keep their effective SIZE in a document** (`macroDocumentPreservesDroppedWidgetSizes`): the SimpleDocument does NOT
  normalise the size of widgets dropped into it — each keeps the effective extent it had when dropped. On a drop,
  `VerticalStackLayoutSpec.rememberInitialDimensions` (`VerticalStackLayoutSpec.coffee:18`) stores the widget's OWN width
  (`widthOfElementWhenAdded`), and `getWidthInStack` (`:31`, default elasticity 1) returns that remembered width CAPPED at the content
  width — it never stretches up; a plain `RectangleMorph` (no `rawSetWidthSizeHeightAccordingly` override) keeps that width AND its
  constructed height. So three boxes built at distinct sizes, dropped in via `@dragWidgetTo_InputEvents box, (new Point doc.center().x,
  doc.bottom()-40)` (aim low to append below the default text), stay at THREE DISTINCT sizes stacked vertically — the distinct sizes ARE
  the assertion (a width-CONSTRAINING container would force one common width). Keep each box width BELOW the doc content width
  (~content − padding − scrollbar) so none is capped. A clean directly-built fixture sidesteps the recording's ambiguous
  duplicated-heart targets. The size-preserving sibling of the flow-in (`macroIconDroppedIntoDocumentFlows`) and reject
  (`macroLockedDocumentRejectsDrop`) document-drop facets.
- **…but a DOC RESIZE re-flows the hosted content to the new width — both ways** (`macroSimpleDocumentHandlesOldInspector`): the
  other half of the document's layout contract. A deferred-layout composite (the OLD InspectorMorph, dragged in by its TITLE — a
  per-test `dragInspectorByTitleTo` helper; pressing a pane could pick the pane out) is hosted at its own size (oversized → CLIPPED
  at the doc edge), but resizing the DOCUMENT via its resize/move mode re-lays-out the in-document inspector to the FULL new doc
  width on a widen and squeezes it on a narrow; on exit it keeps the doc-imposed shape, and its own ctor resizer still works after
  every round-trip (the deferred-layout owner-note beat). GOTCHA: while doc-mode is on, TWO `resizeBothDimensionsHandle`s are
  alive (the mode corner + the hosted inspector's ctor resizer, both in the doc subtree) — scope the lookup
  (`doc.topWdgtSuchThat`); the mode handles are created last and frontmost, so it returns the mode corner.
- **The constraining stack CAPS oversized drops to its full width — it never stretches up**
  (`macroConstrainingStackForcesDroppedWidgetsToFullWidth`): `SimpleVerticalStackPanelWdgt`'s default
  (`constrainContentWidth = true`) runs `rawSetWidthSizeHeightAccordingly(getWidthInStack())` on every child, and
  `getWidthInStack` returns the remembered DROP-time width capped at the content width — so small widgets keep their sizes
  (`macroDocumentPreservesDroppedWidgetSizes`) and OVERSIZED ones come out at exactly ONE shared width (texts also get
  `maxTextWidth` → rewrap). To show the cap, build the parade WIDER than the stack. GOTCHA: a bare `SliderMorph` cannot be
  moved by a centre press — that lands on the value-50 BUTTON and non-float-drags it; grab a clear TRACK point
  (`@syntheticEventsMouseMovePressDragRelease_InputEvents (@pointAtFractionOf slider, [0.08, 0.5]), dest`).
- **The drag-to-scroll FLAGS — background pans, foreground pans** (`macroScrollPanelDragToScrollFlags`): two dedicated
  `ScrollPanelWdgt` flags, default false (`ScrollPanelWdgt.coffee:23-24`), distinct from the LOCK path:
  `canScrollByDraggingBackground` makes a held BACKGROUND drag pan the contents (`PanelWdgt.coffee:143`), and
  `canScrollByDraggingForeground` makes a held drag ON A CONTENT WIDGET pan too instead of float-dragging it out
  (`Widget.coffee:2520`). GOTCHAS: both are gated on `anyScrollBarShowing()` — and bars hide the moment the content fits
  again, so build the fixture content BIGGER than the viewport; pans CLAMP at the content edge — drag TOWARD the unseen
  overflow or nothing visibly happens. Set the flags directly (the recording's inspector-eval route is covered ground).
  DETERMINISM — three cadence couplings live in the drag-to-scroll step: (1) POST-RELEASE MOMENTUM (a per-frame glide,
  friction 0.8 on the last frame's hand delta until <0.5px; its DISTANCE is cadence-dependent) — suppressed under
  `Automator.animationsPacingControl`, and live glides register in `world.wdgtsWithOngoingScrollMomentum`, which gates
  the macro pump's `noInputsOngoing`/`readyForMacroScreenshot` (never capture while momentum settles). The `Date.now()`-
  driven EDGE AUTO-SCROLL is NOT suppressed — it is load-bearing with its own test (the edge-auto-scroll entry above):
  its contract is the same saturation rule as (3); (2) RELEASE TRUNCATION — the step samples the hand per FRAME, so the pointer-path tail
  that plays in the mouse-up's frame was never scrolled; a final FLUSH in the step's release branch now makes the held-drag
  total exactly release − press; (3) MID-RANGE PATH-DEPENDENCE — `scrollX`/`scrollY` clamp against the PREVIOUS frame's
  contents union while `adjustContentsBounds` re-derives it each frame, so a mid-range pan endpoint shifts a few pixels with
  event-into-frame batching. (3) is inherent: write drag-to-scroll macros by the SATURATION RULE — every pan axis either
  SATURATES (drag well past the clamp; the saturated state is the clamp's unique fixed point) or is exactly ZERO. And press
  the true background: the panel's bottom strip is the H-scrollbar, a press there silently does nothing.
- **Scroll-panel drag behaviour — default MOVES, locked SCROLLS, in-a-window moves the WINDOW** (`macroScrollPanelNotMovedViaNonFloatDragChild`
  / `macroLockedScrollPanelScrollsWhenDragged` / `macroScrollPanelInWindowMovesWindowWhenDragged`): pressing+dragging a `ScrollPanelWdgt`'s
  cream BACKGROUND resolves the grab via `Widget.findFirstLooseMorph` climbing `grabsToParentWhenDragged`. **DEFAULT desktop panel** (a plain
  `new ScrollPanelWdgt` ships `canScrollByDraggingBackground=false` — never set true): the climb reaches the ScrollPanelWdgt, which
  `detachesWhenDragged` → the whole panel **float-drags / MOVES** (it does NOT scroll — `ScrollPanelWdgt.mouseDownLeft`'s drag-scroll step is
  gated on `!wdgtToGrab.detachesWhenDragged()`, false here). Dragging a plain child (a `TextMorph`) **DETACHES** it; dragging a
  `nonFloatDragging` child (a `ColorPaletteMorph`) does NEITHER — it colour-picks (the `Widget.coffee:2549` short-circuit) — so the panel
  can't be dragged via the palette (image_1==image_2) while a background drag moves it (contrast). **LOCKED** (`panel.lockToPanels()` →
  `@isLockingToPanels=true`, `Widget.coffee:3714`): `grabsToParentWhenDragged` now returns true, the climb hits the unpickable world →
  `findFirstLooseMorph`=nil → no float-drag → the scroll-step runs → a background drag **SCROLLS** the contents (frame fixed, thumb moves).
  **IN A WINDOW** (`win.add panel`): a `WindowWdgt` isn't a `PanelWdgt`, so the climb falls through to the Window (detaches) → a content drag
  **MOVES THE WHOLE WINDOW** (a design wart — the title bar is the expected move handle). DRY: all three build the panel via the shared
  `buildOverflowingScrollPanelWithText_Macro(topLeft)` verb in `standardMacroSubroutines`. KEY: press a CLEAR background spot (right of the
  text, left of the scrollbar/handle), not a draggable child; in Automator PLAYING the grab threshold is skipped so even small drags grab.

- **A HandleMorph is itself resizable** (`macroHandleMorphIsItselfResizable`): a HandleMorph is an ordinary resizable
  Widget (`HandleMorph.coffee:4`), not just resize chrome on another morph — "resize/move..." on it adds its OWN four
  sub-handles (a moveHandle at the top-left; resizers around it), so FIVE HandleMorphs coexist, and dragging the
  bottom-right one resizes the handle itself (`HandleMorph.nonFloatDragging` `:219` → `@target.setExtent`). Build `new
  HandleMorph` (exactly what the demo "handle" item does — `WorldMorph.createNewHandle`; give it a `rawSetExtent` so the
  striped-triangle glyph is visible), `@moveToAndClickAtFractionOf_InputEvents handle, [0.72,0.75], "right button"` (it
  sets `noticesTransparentClick`, so any point in its box works; the painted part is the bottom-right) → "resize/move..."
  → `@dragResizeMoveHandleTo_InputEvents "resizeBothDimensionsHandle", dest`; click empty desktop to leave the mode.
  DISAMBIGUATION: the target handle ALSO has `type == "resizeBothDimensionsHandle"`, but `topWdgtSuchThat` tests the
  sub-handle (a child, added later → frontmost) BEFORE the target, so the verb grabs the resizer, not the target.
  Distinct from using a handle to resize ANOTHER widget (macroCanMoveAndResizeColorPaletteMorph).
- **A HandleMorph attached to NOTHING just float-moves** (`macroHandleAttachedToNothing`): a handle's resize powers come
  entirely from its `@target` (`HandleMorph.nonFloatDragging` returns early `unless @target`); built bare (`new HandleMorph()`,
  target `nil` — exactly what the demo "handle" item makes via `WorldMorph.createNewHandle`) and parented by the world,
  `detachesWhenDragged` (`HandleMorph.coffee:34`) is TRUE, so a press-drag-release
  (`@syntheticEventsMouseMovePressDragRelease_InputEvents` from a fraction of the handle to a desktop point) FLOAT-drags it
  like any plain morph: it relocates, resizes nothing, and the rest of the desktop is untouched. GOTCHA: the release leaves
  the pointer ON the dropped handle, whose `mouseEnter` (`:233`) renders it in its bluish HIGHLIGHTED state — park the pointer
  on the empty desktop (a no-button move) before the screenshot to show the NORMAL white grip. No new verb.
- **A pristine InspectorMorph resizes via its OWN built-in resizer** (`macroResizingPristineInspector`): an OLD
  `InspectorMorph` is a BoxMorph (not a WindowWdgt) that SHIPS its own bottom-right resizer, built in its ctor —
  `@resizer = new HandleMorph @` (`InspectorMorph.coffee:217`, default type `"resizeBothDimensionsHandle"`). So you
  resize it by dragging that handle DIRECTLY: `@dragResizeMoveHandleTo_InputEvents "resizeBothDimensionsHandle", dest`
  finds it via `topWdgtSuchThat instanceof HandleMorph` (it is the ONLY handle on screen — NO resize/move-mode menu
  needed, unlike `macroCanMoveAndResizeColorPaletteMorph`). `HandleMorph.nonFloatDragging → @target.setExtent`
  (`:212-221`) resizes the inspector and `InspectorMorph.doLayout` (`:344-446`) re-flows the three panes
  (`@list`/`@detail`/`@work`) + footer — the visible proof. Fixture = the StringMorph-inspect idiom
  (`clickMenuItemOfWidget_InputEvents_Macro s, "inspect"` → OLD InspectorMorph) but DO NOT park or pre-size it: the
  "pristine / unmoved & unresized" base case is the whole point (this is the one inspector macro that does NOT
  `insp.fullMoveTo`). SHRINK (compute the target from `insp.topLeft()`) so it stays in bounds and doesn't extend the
  world's scrollable extent (the SWCanvas systemInfoHash). Distinct from every other inspector macro (unplug /
  duplicate / reject-drop / eval / pick-up-parts / property-edit) — none resizes the inspector itself. No new verb.
- **A gutted inspector still resizes — and its detached parts still WORK** (`macroInspectorResizingOKEvenWhenTakenApart`):
  the COMPOSITE of the pristine-resize entry above and the pick-up-parts entry — take an OLD `InspectorMorph` apart (close +
  inspect buttons, detail pane, property list picked out to the desktop), then resize the gutted body AND the detached list,
  and prove the wiring survives. Three mechanics: (1) `InspectorMorph.doLayout` lays out each named part ONLY behind an
  `if part.parent == @` guard (`InspectorMorph.coffee:372,391,399,405,414,423,430,438`) — a gutted inspector re-flows just
  its REMAINING parts, gaps stay gaps, nothing crashes; (2) the list→detail wiring runs on OBJECT REFERENCES — the list's
  action `"selectionFromList"` fills `@detail` wherever it lives (`:323-340`), so a DETACHED list still drives the DETACHED
  detail pane, before and after resizes; (3) `buttonClose`'s action `"close"` (`:210-214`) closes the body from anywhere —
  the detached close button still kills the gutted inspector, leaving the other detached parts standing. THE HANDLE Z-ORDER
  GOTCHA (cost a capture): resize/move-mode handles attach to their TARGET (`HandleMorph.makeHandleSolidWithParentMorph`,
  `HandleMorph.coffee:32`), NOT to the world, and EVERY handle drag runs `@target.bringToForeground()` (`:208-210`) — so
  after the body's own resizer has been dragged, the BODY sits ABOVE the detached list in the world's z-order and
  `dragResizeMoveHandleTo`'s global topmost-first type lookup grabs (and drags!) the BODY's resizer instead of the list's
  mode handle. Scope the lookup to the target's subtree: `cornerHandle = theList.topWdgtSuchThat (m) -> (m instanceof
  HandleMorph) and m.type == "resizeBothDimensionsHandle"` + `@syntheticEventsMouseMovePressDragRelease_InputEvents
  cornerHandle.center(), dest`. (The body-resizer drags may keep the global lookup — run them only while no mode is active,
  when the ctor resizer is the only handle alive.) Click LIST ROWS near their LEFT edge (`row.topLeft() + (10,3)` — a row
  TextMorph spans the content's full width, which a narrowed list CLIPS, so a centre-click can miss the visible pane;
  the `clickOnListItemFromTopInspector` idiom). No new verb.
- **Resizing a button via its handle does NOT trigger it** (`macroResizingButtonDoesntCauseItToClick`): dragging a widget's resize
  handle runs `HandleMorph.nonFloatDragging → @target.setExtent`, never a click — `HandleMorph.mouseClickLeft` is EMPTY and its
  `mouseDownLeft` doesn't propagate ("otherwise the handle on a button will trigger the button when resizing"), so resizing a
  TriggerMorph cannot fire it. Fixture with a VISIBLE action: inspect an OLD StringMorph → OLD `InspectorMorph` (a BoxMorph;
  `insp.buttonClose` is the footer "close" TriggerMorph whose action closes the inspector), pick the close button onto the desktop
  (the PickingUpParts helper). Enter resize/move mode THROUGH THE MENU (manual mode throughout): a DETACHED widget's right-click opens an
  ANCESTOR-HIERARCHY MenuMorph, so navigate `"a TriggerMorph ➜"` → `"resize/move..."` (NOT `clickMenuItemOfWidget … "resize/move..."`,
  which searches a TOP menu that lacks the item — it's one level down the hierarchy). That adds the 4 resize/move handles; drag the
  resizeBothDimensions one (`@dragResizeMoveHandleTo_InputEvents "resizeBothDimensionsHandle", dest`, selected by type) → inspector STILL
  open (the negative assertion). GOTCHA: a click on the button WHILE in resize/move mode is CONSUMED by the mode (it never reaches the
  button), so to fire "close" you must FIRST click an empty part of the desktop to LEAVE the mode (dismissing the handles), THEN click the
  button → inspector closes (the positive contrast). Fully deterministic at dpr 1 & 2 — an earlier round mistook a CAPTURE-FLOW artifact
  for nondeterminism: `--clean --no-build` removes the SOURCE refs but leaves STALE refs in the BUILD, and any image whose fresh (correct)
  render happens to match a stale ref is scored PASS during capture and therefore NOT re-saved — so `--clean` leaves it reference-less and
  verify then reports "no screenshots like this one". Use the capture script's own full flow (rebuild→drop refs, capture, rebuild→publish,
  verify), not a manual `--clean --no-build` + separate rebuild. (The `systemInfoHash` in a reference's filename is just metadata; matching
  is purely the raw-pixel `dataHash`.)
- **A BARE button float-drags by its body and does NOT trigger mid-drag** (`macroBareButtonFloatDragsWithoutTriggering`): the third
  button-negative sibling (after the resize-handle case above and the same-morph-mouseup case `macroButtonTriggersOnlyOnSameMorphMouseUp`).
  `TriggerMorph.rejectDrags` returns false ONLY when the parent is the WORLD (`:191-195`), so a world-parented button does NOT arm its
  trigger on press: `Widget.findFirstLooseMorph` (`:2545`) returns the button ITSELF as the grab root (`grabsToParentWhenDragged` is false
  for a world child, `:2513-2536`), so the hand FLOAT-DRAGS it (`ActivePointerWdgt.determineGrabs → grab`). The action fires only via
  `mouseClickLeft → trigger()` (`TriggerMorph.coffee:232-238,198-202`), gated on a same-morph mouse-up; a float-drag ends in a DROP
  (`ActivePointerWdgt.processMouseUp:435-436`), never a click → no trigger. Build the button DIRECTLY wired to a VISIBLE action: `new
  TriggerMorph true, world, "popUpDemoMenu", "demo", 24, "sans-serif", true` (the same action the world menu's "demo" item uses,
  `WorldMorph.coffee:1940`; `popUpDemoMenu` self-pops at the hand, `:2241`) + `world.add` + `rawSetExtent` + `reLayout()` (a standalone
  TriggerMorph doesn't size its face to its label). Held-button mid-drag idiom for the negative shots: `@moveToAndMouseDown_InputEvents
  button.center()` → `@syntheticEventsMouseMove_InputEvents pt, "left button"` (lifts onto the hand — image_2) → carry →
  `@syntheticEventsMouseUp_InputEvents()` (DROP, no menu — image_3) → then `@moveToAndClickAtFractionOf_InputEvents button, [0.5,0.5]` (a
  REAL click) → `@moveToItemOfTopMenuAndClick_InputEvents "rectangle"` → carry+drop the new rectangle (image_4, the positive contrast). The
  button reads GREY in the dropped shot (the pointer hovers it post-drop → STATE_HIGHLIGHTED) and white once the pointer leaves —
  deterministic. Complement of `macroButtonTriggersOnlyOnSameMorphMouseUp` (a CONTAINER button with `rejectDrags=true` that AVOIDS
  float-drag) and `macroResizingButtonDoesntCauseItToClick` (a resize handle, not a body drag): this covers the world-parented,
  rejectDrags-false body-float-drag branch. Drop the "demo ➜" arrow glyph (absent from the SWCanvas bitmap font → a box) — plain "demo". No new verb.
- **A composite drags as one unit into/out of a scroll panel, clipped inside** (`macroCompositeDragsAsUnitIntoScrollPanel`): a
  composite (boxes parented under one top box) crosses a clipping container's boundary as a single assembly. A child parented under a
  non-world morph has `grabsToParentWhenDragged` true (`Widget.coffee:2513-2533`), so dragging any part climbs via `findFirstLooseMorph`
  (`:2545`) to the top box and carries the WHOLE subtree (children keep their relative offsets). A plain `new ScrollPanelWdgt` already accepts drops (`_acceptsDrops:true` via PanelWdgt — no
  enableDrops) and clips at its bounds; dropping the composite over it routes `ActivePointerWdgt.drop → ScrollPanelWdgt.add` (`:186`),
  which re-homes the whole composite into `@contents` (clipped where it overhangs), and `Widget.add` REMOVES the desktop shadow on the
  non-world re-parent (`:2210`) / RESTORES it on a world re-parent (`:2199`). So dragging ANY of the three boxes (each by its exposed
  TOP-RIGHT corner — the part not overlapped by a sibling) carries the whole composite, demonstrated in THREE in/out cycles (grab the 1st,
  then 2nd, then 3rd box). Per cycle the held-button choreography captures it floating over the panel (a hand-child, UNCLIPPED), dropped in
  (re-parented + CLIPPED where the trailing boxes overhang an edge, shadow gone), picked back up (lifted/unclipped), dragging out, and
  dropped on the desktop (intact, shadow restored). Drop near the bottom-right (trailing boxes clip the bottom) or the top-left (leading
  boxes clip the left) — and keep the GRABBED box itself INSIDE the panel so it can be re-pressed for the out-grab. **The load-bearing
  idiom for a HELD drag (and the #1 trap): `@moveToAndMouseDown_InputEvents pt` → `yield "waitNoInputsOngoing"` →
  `@syntheticEventsMouseMove_InputEvents dest, "left button"`. The YIELD is MANDATORY — it drains the queued press so
  `world.hand.position()` is actually AT `pt`; without it the move's default `orig` reads a STALE hand position and the grab offset throws
  the morph far off-target (here off-canvas).** Build with `topBox.add child` (NOT the "attach…" menu — identical state, simpler; same
  fixture style as macroCompositeMorphsHaveCorrectShadow); distinct box colours make "children keep their offsets" legible. Drop target =
  the POINTER position. CAPTURE GOTCHA (16 screenshots at dpr 2): building+returning all N large 2× reference images in ONE `page.evaluate`
  memory-blows the capture (and a refs-missing verify) to 30+ min — `run-macro-test-headless.js` extracts each ref in its OWN `page.evaluate`
  and frees it; a passing verify returns no failure images, so it stays fast. First composite-into-scroll-panel test. No new verb.
- **An embedded "duplicate" button is self-replicating (copy-of-a-copy)** (`macroEmbeddedDuplicateButtonReduplicates`): a Panel's OWN
  context-menu "duplicate" item, picked up out of the menu and dropped INTO the panel, becomes an in-panel `MenuItemMorph` (target = the panel,
  action `"duplicateMenuActionAndPickItUp"`, `Widget.coffee:3489`). Clicking it deep-copies the whole panel (`fullCopy().pickUp()`,
  `Widget.coffee:2299`); the deep copier rewires the COPIED button's target to the cloned panel (`DeepCopierMixin` parallel originals/clones
  arrays), so clicking the COPY's embedded button duplicates the copy, not the original — the duplicator survives `fullCopy` and replicates
  across generations (1 → 2 → 3 → 4). SETUP reuses the `macroMenuItemDuplicatesToStandaloneMorph` idiom: `@openMenuOf_InputEvents panel` →
  `@getTextMenuItemFromMenu @getMostRecentlyOpenedMenu(), "duplicate"` → `@openMenuOf_InputEvents dupItem` (right-click the item → its ancestor
  hierarchy menu) → `"a MenuItemMorph ➜"` → `"pick up"` → carry into the panel (no-button move) + `@syntheticEventsMouseClick_InputEvents()` to
  drop. Clicking the embedded button puts the copy ON THE HAND, so a plain move-then-click carries-and-drops it (NOT a held-drag — that is only
  for a free morph not already on the hand). Locate each generation's button by a LIVE-WORLD query — the new `PanelWdgt` not yet seen, then its
  descendant `MenuItemMorph` with `labelString == "duplicate"` (`topWdgtSuchThat`) — never recorded coordinates. (`justBeenCopied`,
  `TriggerMorph.coffee:219`, is only a cosmetic un-highlight, NOT the duplication mechanism.) No new verb.

## Controllers (patch-programming)

- **Set target** (`macroPaletteSetTargetRecolorsPanel`): `setControllerTargetToWidgetProperty_InputEvents_Macro controller,
  "a Panel", "color"` — right-click the controller (a ColorPaletteMorph / GrayPaletteMorph / SliderMorph / … with
  `ControllerMixin`) → "set target" (`openTargetSelector` lists only bounds-INTERSECTING widgets, so it MUST OVERLAP the target)
  → pick the target by class-name PREFIX → pick the property; thereafter acting on the controller calls `target[setter](value)`.
  4th arg `controllerMenuFraction` (default `[0.5,0.5]`): pass `[0.5,0.85]` for a SLIDER (its button covers the centre at value
  50, so target the LOWER TRACK). 5th arg `controllerHierarchyPrefix`: pass the controller's class-name prefix when it is INSIDE
  a container (right-clicking a non-world child opens the ancestor hierarchy menu); omit for a world-child.
- **Re-target** (`macroPaletteRetargetsToNewWidget`): run set-target AGAIN — `setTargetAndActionWithOnesPickedFromMenu` OVERWRITES
  `@target`/`@action`; the old target keeps its value but stops following. Put ONE palette over TWO targets of DIFFERENT classes
  (PanelWdgt + RectangleMorph) so each is picked unambiguously by class-name PREFIX; re-target back and forth.
- **Two controllers share one target** (`macroTwoPalettesShareOneTarget`): two ColorPaletteMorphs both set-target'd to the SAME
  panel's "color" (each overlapping the panel but NOT each other); clicking EITHER repaints, both bindings persist (most-recent
  click wins). One palette/many targets ⇒ re-targeting; many palettes/one target ⇒ shared control.
- **Slider drives a target live** (`macroSlidersControlTextMorph`): wire with the 4th/5th args above, then
  `@dragSliderButtonToFraction_InputEvents slider, [0.5, fy]` does a press-drag-release ON the BUTTON (a non-float child drag →
  `SliderButtonMorph.nonFloatDragging → SliderMorph.updateValue → setValue → updateTarget`), driving `target[setter](value)` LIVE
  the whole drag (larger fy = larger value). A slider's property menu lists only NUMERIC setters; `setTargetAndAction` pushes the
  current value on binding. Use the BUTTON-drag verb (not the track-click) for a free-standing controller slider. DUPLICATING a
  controller+target composite (a panel holding a text + its sliders) deep-copies the bindings remapped to the COPY's target.
- **Hover-to-highlight a candidate** (`macroTargetingHighlightsCandidateMorph`): hovering a "choose target:"/"choose new parent:"
  item highlights the morph it represents (`MenuItemMorph.mouseEnter → morphToBeHighlighted.turnOnHighlight()`,
  `MenuItemMorph.coffee:78` → `world.morphsToBeHighlighted` → a `HighlighterMorph` each cycle). Overlap a ColorPaletteMorph with a
  rect, `clickMenuItemOfWidget… "set target"`, grab the menu, find the candidate by prefix, then
  `@syntheticEventsMouseMove_InputEvents item.center(), "no button", …` to HOVER (no click) and screenshot the highlight tint.
- **The highlight covers the EXACT SUBTREE, tracks the hover, clears on leave** (`macroHierarchyMenuHoverHighlightsExactSubtree`):
  the ancestor-HIERARCHY menu's ▪-marked items are `representsAMorph` too — same mouseEnter/mouseLeave path — and on a nested
  composite (panel > box > rect) hovering an item floods exactly that ancestor's subtree, translucently, OVER the descendants'
  own colors: deeper item → strictly smaller region; moving between items moves the flood; hover-off clears with NO trace
  (final shot ≡ the menu-open baseline, the pixel-identical no-op idiom) while the menu stays open (menus dismiss on
  mouse-DOWN outside, not hover-out). Give the deepest fixture morph its own color (`new RectangleMorph extent, color`) or it
  hides dark-on-dark in the un-highlighted shots.
- **A FORCED set-target choice is still PRESENTED — hand-rolled chain with screenshots between menus**
  (`macroUniqueTargetAndPropertyAreStillPresented`): a lonely ColorPaletteMorph has exactly ONE plausible target (the world),
  yet `openTargetSelector` still opens the one-item "choose target:" menu (no silent auto-pick); clicking it opens the
  "choose target property:" menu (`ColorPaletteMorph.openTargetPropertySelector`, `ColorPaletteMorph.coffee:111`, from
  `target.colorSetters()` — the world offers "background color" + "color"), and picking "color" yields a binding a palette
  click then proves (the whole desktop recolours). To screenshot BETWEEN the menus, hand-roll the
  `setControllerTargetToWidgetProperty…` chain and capture each popup fresh (`targetMenu = @getMostRecentlyOpenedMenu()` right
  after "set target"; `propertyMenu = …` right after the target click), driving later clicks via the captured refs. GOTCHA:
  clicking "a WorldMorph ➜" parks the pointer on a candidate item whose hover highlight-tints the morph it represents — the
  WHOLE WORLD — and the property menu pops OVER the item so no mouseLeave fires; hover the property menu's "color" item
  (`@getTextMenuItemFromMenuByPrefix propertyMenu, "color"` + a no-button move) before the shot to clear the tint (and match
  the recording's hover-highlighted row). Prefix "color" is unambiguous: "background color" does not START with it. No new verb.
- **A two-way slider↔text patch cycle, text as SOURCE, guarded** (`macroSliderTextTwoWayPatchCycle`): wire `slider.value → text
  "text"` AND `text → slider "value"` so the two bind into a 2-node LOOP; driving either end chases the value to the other and
  `world.makeNewConnectionsCalculationToken()` (minted in `SliderMorph.setValue`/`SimplePlainTextWdgt.setText`, propagated by
  `updateTarget`, re-seen → early `return`) stops the loop after one hop. The TEXT is a controller SOURCE — TYPING into it moves the
  slider (visible, not just an internal back-edge). KEY: both controllers are world children positioned to OVERLAP, so each "set
  target" menu lists exactly ONE candidate of the wanted class (one text / one slider) and is unambiguous — **so NOTHING is
  repositioned to wire, and nothing jumps.** The minimal form of the cycle. A naive 3-node `slider→text→slider` ring tempts you to
  `fullMoveTo`-PARK a slider mid-wiring to disambiguate its `text→slider2` leg (the text hub overlaps BOTH sliders) — which reads on
  screen as the slider "jumping around for no reason" (an API reposition = a teleport, the anti-pattern flagged for dropped morphs);
  DON'T. Either use this 2-node cycle, or wire the full 3-node cycle WITHOUT moving anything by selecting the ambiguous leg BY MEANING
  (see `macroSliderTextSliderPatchCycle` below). Drive: `@dragSliderButtonToFraction_InputEvents slider, [0.5,fy]` (slider→text), then edit the text via
  `world.edit text` (escape hatch — left-clicking a short number in a wide box overshoots the empty-text `slotAt`, see
  `macroInspectorWorkAreaEvaluatesCoffeeScript`) + `Meta+a` + typed digits (text→slider). FIXTURE gotchas: KEEP the ctor's
  `maxTextWidth = true` (`nil` shrinks the box to its content, so it stops overlapping the slider and "set target" can't find it);
  `SliderMorph`'s track AND `SliderButtonMorph.normalColor` are both `Color.BLACK`, so tint the track light (`slider.color = …`) to
  make the button (= the value) visible. No new verb.
- **The full 3-node slider→text→slider cycle — each component drives the other two, wired with NOTHING moved**
  (`macroSliderTextSliderPatchCycle`): the 3-node sibling of the above. `slider1 → text "text"`, `text → slider2 "value"`,
  `slider2 → slider1 "value"` close a ring, so dragging slider1, dragging slider2, OR typing the text each drives the other two (the
  guard stops each lap). Wiring it IN PLACE needs two tricks: (1) place the two sliders ADJACENT with a ~1px bounding-box OVERLAP —
  enough that `slider2`'s "set target" lists `slider1` (so `slider2→slider1` wires unambiguously) while their BUTTONS stay distinct
  (give them different track colours too, so the two sliders are easy to tell apart); and (2) wire the one ambiguous leg —
  `text→slider2`, since the text overlaps BOTH sliders — BY MEANING instead of the prefix verb: right-click the text → "set target",
  then in the "choose target:" menu pick the item whose target IS slider2. **The reusable bit — selecting a target menu item by its
  morph reference:** `ControllerMixin.openTargetSelector` passes each candidate target widget as the menu item's `argumentToAction1`
  (via `MenuMorph.addMenuItem` → `MenuItemMorph`), so `slider2Item = menu.topWdgtSuchThat (item) -> (item instanceof MenuItemMorph) and
  (item.argumentToAction1 == slider2)`, then `@moveToAndClick_InputEvents slider2Item` and `@moveToItemOfMenuAndClick_InputEvents
  @getMostRecentlyOpenedMenu(), "value"`. The other two legs use the prefix verb (unambiguous). So when "set target" lists two
  same-class candidates, NEVER park a widget to disambiguate — pick the menu item by its `argumentToAction1` target reference. No new verb.

## Layout

- **Proportional stack cells** (`macroLayoutBasicProportions`): make a holder a horizontal stack —
  `holder.add cell, nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED` per cell + `cell.setMinAndMaxBoundsAndSpreadability(min,
  desired, k*LayoutSpec.SPREADABILITY_MEDIUM)` (k = its share of spare space). Position with `fullMoveTo` BEFORE `world.add`, then
  `new HandleMorph holder` (self-installs at the bottom-right; lone holder ⇒ lone handle). Resize via
  `@dragResizeMoveHandleTo_InputEvents` and the cells redistribute by spreadability. Distilled from the first holder of
  `Widget.setupTestScreen1`.
- **TEXT widgets as stack cells, via "attach with horizontal layout"** (`macroStringMorph2AndTextMorph2ResizingInLayout`): the
  text-in-layout bridge — the layout macros above use plain rectangles as cells, the text-resize macros resize FREE text; this
  one puts a `TextMorph2` and a `StringMorph2` INSIDE a stack and resizes the HOLDER. The menu mechanic: "attach with horizontal
  layout" (`Widget.attachWithHorizLayout:3684`) pops a choose-new-parent menu of INTERSECTING morphs (labels are
  `toString()`-based — match by prefix, "a RectangleMorph") whose pick runs `newParentChoiceWithHorizLayout` = `holder.add child,
  nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED` — turning a plain demo RectangleMorph into a
  horizontal stack that FITS to its cells when small and SPLITS its width between them when grown. Resizing through the real
  resize/move handles re-wraps the TextMorph2's paragraphs to its CELL width (and re-fits the font SMALLER when the cell
  narrows); the StringMorph2 cell honours its own menu — "∸ align center" (`StringMorph2.alignCenter:987`), "⍿ align middle"
  (`.alignMiddle:995`), "→← shrink to fit" (`.togglefittingSpecWhenBoundsTooSmall:1007`, inherited by TextMorph2) — the labels
  carry glyph decorations, so click via `@moveToItemContainingOfMenuAndClick_InputEvents`; and caret editing keeps working in a
  cell (`@moveToAndClickAtFractionOf_InputEvents` → `@repeatSpecialKey_InputEvents "Shift+ArrowRight", 3` → overtype). FIXTURE
  GOTCHAS: create the widgets through the REAL demo/test menus (`world.create` floats them on the hand, a mouse-down drops them;
  the demo StringMorph2 is `isEditable=true` unlike direct construction) and author the drop spots so the texts OVERLAP the
  rectangle (attach lists only intersecting morphs); reach the holder's menu from a CELL through the hierarchy menu ("a
  RectangleMorph" prefix); scope the corner-handle lookup to the holder's subtree (`rect.topWdgtSuchThat ... resizeBothDimensionsHandle`
  — mode handles attach to their TARGET); and `TextMorph2 extends StringMorph2`, so locate the string with an
  instanceof-TextMorph2 EXCLUSION. No new verb.
- **Re-proportion a stack LIVE by dragging the divider** (`macroStackDividerReproportionsCells`): the INTERACTIVE sibling of basic
  proportions above — a `StackElementsSizeAdjustingMorph` placed BETWEEN two cells in the stack (`holder.add lime/divider/blue, nil,
  LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED`; this is `setupTestScreen1`'s second holder, `Widget.coffee:4515`).
  Dragging the divider runs its `nonFloatDragging` (`StackElementsSizeAdjustingMorph.coffee:28`), which shifts the max-size (spreadability)
  allowance between the flanking cells — re-apportioning the split. Drive it with the HELD-DRAG idiom (a per-test helper): `p =
  divider.center(); @moveToAndMouseDown_InputEvents p; yield "waitNoInputsOngoing"; @syntheticEventsMouseMove_InputEvents (new Point (p.x+Δ),
  p.y), "left button"; @syntheticEventsMouseUp_InputEvents()`. GOTCHAS: a plain CLICK on the divider is a NO-OP (it early-returns on a nil drag
  delta, `:32-33`) — you MUST move while held; the post-mouse-down `yield "waitNoInputsOngoing"` is mandatory (else the grab offset is stale and
  it apportions by a bogus delta); the reachable range is BOUNDED — `setMaxDim` reverts a drag that would push a cell below its DESIRED width
  (`:65-76`), so only two split states are reachable (the spreadability baseline and the opposite-dominant bound), and the apportioning scales
  with the drag DISTANCE (one firm large move reaches the bound where several small moves do not). So drive ONE firm drag to the bound, not a
  back-and-forth (the return leg would mostly revert and duplicate the baseline shot). Resize the holder via its lone HandleMorph
  (`@dragResizeMoveHandleTo_InputEvents "resizeBothDimensionsHandle"`) to show the dragged split survives a container resize. First
  interactive-layout-re-proportioning test. No new verb.
- **Hiding a stack cell does NOT redistribute — visibility is layout-blind** (`macroLayoutsAndVisibility`): `hide()`/`show()`
  only flip paint state (`Widget.hide:1841`/`show:1860` touch `@isVisible` + the bounds caches; NEITHER calls
  `invalidateLayout`), and `doLayout`'s three stack-distribution loops filter children by `layoutSpec` only
  (`Widget.coffee:4334/4358/4392`) — `getDesiredDim`/`getMinDim` gate on `isCollapsed()`, never on visibility (`:4089-4098`).
  So a HIDDEN cell keeps its allocated slot (the holder's own background — Widget default `Color.create 80,80,80` — shows
  through the gap), keeps receiving its spreadability share when the holder is resized WHILE hidden, and `show()` paints it
  straight back into the kept slot with no fresh layout pass: a hide/show round-trip at a fixed size is BYTE-EQUAL (assert via
  matching dataHashes), and hide → resize → show ends pixel-identical to never having hidden at all. CONTRAST: `isCollapsed()`
  zeroes the layout dims, so COLLAPSE really does redistribute where HIDE does not — `macroLayoutsAndCollapsing`, the next
  entry, which reuses this fixture verbatim (the green|divider|blue equal-spreadability holder — `setupTestScreen1`'s second
  holder — plus its lone HandleMorph). The recording had to `show()` the cell back through an
  INSPECTOR eval (a hidden morph can't be right-clicked); the macro drives `blue.hide()`/`blue.show()` directly, the
  `macroHideUnhideMorphChain` convention. No new verb.
- **Collapsing a stack cell DOES redistribute — collapse is layout-aware** (`macroLayoutsAndCollapsing`): the contrast twin
  of the visibility entry above, same fixture VERBATIM, opposite mechanic. `collapse()`/`unCollapse()`
  (`Widget.coffee:1883/1895`) BOTH call `invalidateLayout()` (hide/show call neither), and the dimension getters the stack's
  distribution loops read — `getDesiredDim`/`getMinDim`/`getMaxDim` — gate on `isCollapsed()` and return zero for a
  collapsed cell (`:4089-4098`): the moment a cell collapses, `doLayout` re-runs and hands its WHOLE share to the siblings
  by spreadability (the divider rides to the holder's edge; no gap), every resize-while-collapsed keeps distributing to the
  others, and `unCollapse()` re-runs the same distribution off the UNTOUCHED `layoutSpecDetails` — a collapse/unCollapse
  round-trip at a fixed size is BYTE-EQUAL, and collapse → resize → unCollapse ends as if never collapsed. Verified
  cross-test: this macro's image_1/image_5 are byte-identical (same dataHash, both dprs) to `macroLayoutsAndVisibility`'s —
  the two tests share their exact endpoints and differ ONLY in who holds the space in between. Drive
  `blue.collapse()`/`blue.unCollapse()` DIRECTLY — they are the very methods the context "test menu"'s `collapse` /
  `un-collapse` items call (`Widget.coffee:3284-3288`), and the un-collapse item is unreachable by right-click anyway (a
  collapsed cell is zero-size; the recording used an inspector eval — scaffolding). No new verb.
- **Layout spacer / spring** (`macroLayoutSpacerEatsSpareSpace`): a `LayoutSpacerMorph` is a spring (ctor passes spreadability
  `weight*LayoutSpec.SPREADABILITY_SPACERS` = 1e8, a ~1e6 max that dwarfs any cell's), so in a stack it absorbs almost all spare
  width and the cells stay at DESIRED size. Reuse `Widget.setupTestScreen1()` (8 holders, several `[spacer|adj|green|adj|blue|adj|yellow|adj|spacer(2)]`);
  locate holders as `world.children.filter (c) -> c instanceof RectangleMorph and c.children.length > 0`, each handle a HandleMorph
  among the holder's OWN children. DRIFT: the current layout settles a stretched stack's cells at DESIRED width, so two holders
  match ONLY if their cells share a desired size — pick the two desired-30 holders differing in spreadability (MEDIUM vs NONE).
- **Stack grows with content** (`macroVerticalStackPanelGrowsWithContent`): a `SimpleVerticalStackPanelWdgt`
  (`constrainContentWidth` defaults true) stacks children, constrains each child's WIDTH to the panel, and — being `tight` —
  grows its HEIGHT to the children (`adjustContentsBounds`, `SimpleVerticalStackPanelWdgt.coffee:73-134`: sets each text child's
  `maxTextWidth` to the available width, sums child heights into `rawSetHeight`). Reproduce the demo widgets exactly (`new
  SimpleVerticalStackPanelWdgt` at 370×325 = `Widget.createSimpleVerticalStackPanelWdgt`; each text = `Widget.createNewWrappingSimplePlainTextWdgtWithBackground`,
  a 2-paragraph Lorem + cream bg); DROP each in with `@dragWidgetTo_InputEvents text, panel` (fires `reactToDropOf →
  adjustContentsBounds`), so a second drop ~doubles the height. (A tight EMPTY box taller than one child SHRINKS on the first add
  — start from substantial content.) The reusable fixture for the big `Width*VerticalStackPanel` family.
- **Stack SHRINKS when a child is removed** (`macroVerticalStackPanelShrinksOnParagraphRemoval`): the SHRINK complement of the
  grows entry above — a tight, width-constraining `SimpleVerticalStackPanelWdgt` tracks its height DOWN as well as up. Removing a
  child fires `childRemoved → adjustContentsBounds` (`SimpleVerticalStackPanelWdgt.coffee:52-57`), which re-sums the (now fewer)
  child heights with NO floor while tight & non-empty (`:130-131`) → the panel snaps down to hug the remaining paragraph. The
  removal hook fires when the dragged-out child is re-parented to the world (`Widget.coffee:2249-2250`). Build like the grows
  fixture (bare `new SimpleVerticalStackPanelWdgt`, two yellow wrapping `SimplePlainTextWdgt` dropped in via
  `@dragWidgetTo_InputEvents text, panel`), then REMOVE the last. KEY GESTURE: a child of a TIGHT stack is NOT independently
  float-draggable (a float-drag grabs the whole STACK — eyeball-caught: dragging the paragraph moved the entire stack), so detach
  it through its hierarchy menu's "pick up", reusing `pickUpPartToDesktop_InputEvents_Macro part, "a SimplePlainText", dropPoint`
  (right-click → "a SimplePlainText ➜" → "pick up" = `Widget.pickUp → world.hand.grab`, then carry + mouse-DOWN to drop; the
  subroutine from `macroPickingUpPartsFromInspector`). GOTCHAS: keep paragraphs MODERATE so the whole stack stays on-screen (a
  clean right-click on the last paragraph — tall paragraphs put its centre at the canvas edge); drop the removed paragraph well
  inside the desktop, clear of the stack, so the world extent (hence the SWCanvas frame) stays put. No new verb.
- **Font-size change REFLOWS the whole document — in place, and exactly reversibly**
  (`macroSimpleDocumentAllReflowsCorrectlyAsIChangeFontSize`): `SimplePlainTextWdgt extends TextMorph2` (default
  `originallySetFontSize = 12`, `SimplePlainTextWdgt.coffee:25`), so the real "font size..." prompt (Meta+a selects the value,
  overtype, Ok — the Text-section prompt idiom) re-renders a paragraph IN the flow; the width-constraining stack re-wraps the
  bigger glyphs to the document's width (at 90 the words wrap one per line), pushes the following siblings down, and the scroll
  panel's content extent — hence its scrollbar — tracks the growth while the VIEWPORT STAYS PUT (the reflow happens in place).
  The machinery is exactly reversible — assert the round-trips BY BYTE-EQUALITY: a wheel-down tour + wheel-back-to-top
  reproduces the pre-tour shot's dataHash (the clamp lands exactly on offset 0), and setting the size back to the DEFAULT 12
  reproduces the pre-change shot's dataHash pixel-for-pixel. FIXTURE: the document demo is just `new
  SimpleDocumentScrollPanelWdgt` at (35,30) 370×325 (`Widget.createSimpleDocumentScrollPanelWdgt:3250` — it ships with the
  default "A small string…" paragraph); drop-to-insert puts a dropped widget AFTER the sibling whose span contains the drop Y,
  appending below everything (`SimpleVerticalStackPanelWdgt.add:17`) — three authored drops produce lorem/small/lorem,
  including a REORDER of an existing paragraph by dropping it onto another paragraph's span (pick a drop Y inside that span
  under BOTH the pre- and post-grab layouts — the flow tightens the moment the grabbed paragraph leaves it). GOTCHA: after the
  font change a paragraph's CENTRE can lie below the viewport clip, so `@openMenuOf_InputEvents` (a centre right-click) would
  miss the document entirely — right-click a VISIBLE fraction instead: `@moveToAndClickAtFractionOf_InputEvents para, [0.5,
  0.04], "right button"`. A paragraph inside a document opens the HIERARCHY menu — descend via the "a SimplePlainText" prefix.
  No new verb.
- **Stack loose when empty, tight when filled — via the resize HANDLE** (`macroStackPanelLooseWhenEmptyTightWhenFilled`): a
  width-constraining `SimpleVerticalStackPanelWdgt` resizes COMPLETELY FREELY (both dims) while EMPTY but only in WIDTH once
  filled (HEIGHT fixed to the wrapped text). `adjustContentsBounds` (`:73`) sums child heights, then `if !@tight or
  childrenNotHandlesNorCarets.length == 0: newHeight = Math.max newHeight, @height()` (`:130-131`) keeps the dragged height ONLY
  when loose or EMPTY. Resize via the real HANDLE: `@openMenuOf_InputEvents panel` → "resize/move..." →
  `@dragResizeMoveHandleTo_InputEvents "resizeBothDimensionsHandle", dest`. KEY: once filled the text COVERS the panel, so bring up
  its handles via the text's "a SimpleVerticalStackPanel ➜" hierarchy submenu. Screenshot WITH the handles showing, then click
  empty desktop to exit. `world.add text` to detach the content and empty the stack.
- **A lone centered widget stays centered** (`macroCenteredWidgetStaysCenteredWhenAlone`): a stack child's
  `VerticalStackLayoutSpec.alignment` (`"left"|"center"|"right"`, default left) drives its horizontal placement; `setAlignmentToCenter`
  is what the "a X ➜ → layout in stack → align center" menu item calls — `heart.layoutSpecDetails.setAlignmentToCenter()` is the direct
  equivalent (sets the field AND relayouts). The centering SURVIVES the child becoming the only element: `ScrollPanelWdgt.adjustContentsBounds`
  has dedicated lone-centered-child support (`:288-303`) that keeps it centered instead of snapping its left to the viewport. Drop a `new
  HeartIconMorph (Color…)` into a `SimpleDocumentScrollPanelWdgt`, center it, then `@dragWidgetTo_InputEvents defaultText, (a desktop point)`
  to remove the default text — the heart stays centered alone. GOTCHA: a widget has NO `.remove()`; drag it out (or re-parent via `world.add`).
- **Padding is real morph area — sliders + palette-reveal + drag-by-the-band** (`macroPaddingAreaIsPartOfMorph`): a RectangleMorph paints
  two layers (`RectangularAppearance.coffee:71-88`) — `backgroundColor` over the FULL bounds, `color` over the padding-inset tight region
  `boundingBoxTight()` (`Widget.coffee:679-680`, edges inset by paddingTop/Bottom/Left/Right `:658-668`). The padding band between them is part
  of the morph, but while UNPAINTED it is click-through. Reproduce basicMorphPadding via PATCH-PROGRAMMING: build the rect + FIVE SliderMorphs
  + a ColorPaletteMorph all OVERLAPPING it (REQUIRED — "set target" lists only widgets whose bounds intersect the controller), then
  `setControllerTargetToWidgetProperty_InputEvents_Macro slider, "a RectangleMorph", "padding"|"padding top"|"…bottom"|"…left"|"…right", [0.5,0.85]`
  (the centred slider button covers a centre right-click → right-click the LOWER TRACK; a world-child controller needs no hierarchy prefix) and
  the palette → `"background color"`. `@dragSliderButtonToFraction_InputEvents slider,[0.5,frac]` insets the dark interior; a palette click
  (`@moveToAndClickAtFractionOf_InputEvents palette,[0.62,0.4]`) paints the BACKGROUND blue → the band shows (the morph extends beyond its paint);
  then DRAG the rect by that blue band to prove the padding area is a grabbable part of the morph. GOTCHAS: (a) wiring a slider applies its
  CURRENT value on bind, so padding is already on before you drive; (b) a free morph is dragged with the HELD-DRAG idiom
  (`@moveToAndMouseDown_InputEvents pt` → `yield "waitNoInputsOngoing"` → `@syntheticEventsMouseMove_InputEvents dest,"left button"` →
  `@syntheticEventsMouseUp_InputEvents()`), NEVER a one-shot press-drag-release (the grab never registers); (c) the drag-by-band works ONLY after
  the background is PAINTED — an unpainted band is click-through — so do the drag AFTER the palette click. Property labels read from the recording.
  First padding test (renamed from macroPaddingInsetsInterior).

## Sliders & popovers

- **Slider-button state colours + cross-slider grab** (`macroSliderButtonStateColors`): a `SliderButtonMorph` paints `@color` =
  `normalColor`/`highlightColor`/`pressColor` per state (`mouseEnter → setHiglightedColor`, `mouseDownLeft → setPressedColor`,
  `mouseLeave → setNormalColor`; each early-returns while the hand is dragging). `menusHelper.makeSlidersButtonsStatesBright()`
  (a global MenusHelper) recolours every EXISTING slider button BLACK/BLUE/LIME — call it AFTER `world.add`. HOLD each state:
  hover via a no-button move onto the button (highlighted, persists), then `@moveToAndMouseDown_InputEvents slider.button`
  (pressed, held). GOTCHA: a SliderMorph defaults to `alpha 0.1`, which mutes the colours into greys — set
  `slider.button.alpha = 1` (NOT `slider.alpha = 1`: the track's own colour is BLACK, so an opaque track swallows the black
  button). CROSS-SLIDER GRAB (two sliders): while one is GRABBED, a move with the button HELD (`…, "left button"`) over the OTHER
  handle does NOT highlight it (its mouseEnter early-returns while dragging), and the grabbed button FOLLOWS the hand vertically
  clamped to its own track.
- **Popover stays open while its slider is dragged out** (`macroPopoverStaysOpenWhenSliderDraggedOut`): a pop-up normally closes
  on a mouse-DOWN outside it, but DRAGGING its slider keeps it open even when the pointer leaves its bounds. Pressing a slider
  button whose slider's parent is a `PromptMorph` starts a NON-float drag (`SliderMorph.mouseDownLeft → nonFloatDragWdgtFarAwayToHere`;
  `SliderButtonMorph.detachesWhenDragged` is false while parented to a slider), and on the mouse-UP `cleanupMenuWdgts` is SKIPPED
  while a non-float drag is in progress. Open a RectangleMorph's "transparency..." popover, `prompt = @getMostRecentlyOpenedMenu()`,
  `slider = (prompt.children.filter (c) -> c instanceof SliderMorph)[0]`, then press-drag-release its button to a point far OUTSIDE
  the popover. The alpha commits on "Ok", so only the value FIELD changes live. The INVERSE of dismiss-on-mousedown-outside.
- **A slider dragged across surfaces keeps its button** (`macroSliderDraggedAcrossSurfacesKeepsButton`): grabbing a slider by
  its BACKGROUND (the track, NOT the button) and dragging it onto a plain panel, then a scroll panel, then the desktop never
  pages its button — a slider sitting on a panel/scroll-panel is NOT that panel's scrollbar. A standalone slider's track-press
  escalates (`SliderMorph.mouseDownLeft` gate at `:258` is false off a `ScrollPanelWdgt`/`PromptMorph` parent) and the float-drag
  grabs the WHOLE slider (`Widget.detachesWhenDragged` true; `findFirstLooseMorph` returns the slider) — so the slider moves and
  its button rides along, never calling `updateValue`. CRUX: dropping onto the scroll panel re-parents the slider into the panel's
  inner `@contents` (`ScrollPanelWdgt.add :186-194`), NOT as the `@vBar`, so the paging gate STAYS false in every state and a later
  track-grab still doesn't page. Grabbing the BUTTON instead would non-float-drag it and PAGE the value
  (`SliderButtonMorph.nonFloatDragging`) — so grab a track point OFF the button. There is NO from-a-fraction drag verb
  (`@dragWidgetTo_InputEvents` grabs at `center()` = the button), so compose the primitive:
  `@syntheticEventsMouseMovePressDragRelease_InputEvents (@pointAtFractionOf slider, [0.5, 0.15]), dropPoint` (one held drag-move
  is enough; the playback skips the grab threshold). Build a standalone vertical `new SliderMorph 1,100,50,10` + `slider.alpha = 1`
  (ctor defaults `@alpha = 0.1` ≈ invisible, `:38`) + `rawSetExtent 22×130` (height>width ⇒ vertical) + a `PanelWdgt` + an EMPTY
  `ScrollPanelWdgt` (empty ⇒ no bars ⇒ no extent growth). The button stays mid-track across all four shots = the proof. (The
  recorded original's DIGEST mislabels the drag source as the panel; its 4 screenshots show the SLIDER is the moving object —
  trust the screenshots. Don't over-distill to a bare track-CLICK no-op: the recording's real demonstration is this
  drag-across-surfaces, the scroll-panel surface being the crux.) No new verb.

## Rendering & hit-testing

- **Order-dependent transparency compositing** (`macroBoxTransparencyAndColorChanging`): two TRANSLUCENT, differently-coloured
  boxes overlapping a text backdrop blend differently depending on STACKING ORDER (which is in front). Set each box's colour +
  transparency via its "color..."/"transparency..." popups (see Menus), then a left-click on a box raises it
  (`Widget.mouseDownLeft → bringToForeground`), swapping the blend (image_1 green-over-magenta, image_2 magenta-over-green) with
  the text reading through both. Only TWO shots — the one variable that matters is the stacking order; a third would just repeat.
  (Transparency + colour set via a test-local helper in `extraSubroutineSources`.)
- **Panel + transparency + CROP + shadow; alpha does NOT cascade to children** (`macroPanelInPanelTransparencyAndStroke`): a
  `PanelWdgt` ships a cream fill + a dark 1px stroke (the `defaultPanels*` colours) and `@augmentWith
  ClippingAtRectangularBoundsMixin`, which CROPS its children to its bounds and re-paints the stroke AFTER the children (border on
  top of nested content). Nest a child inner panel AND a child box, each MOVED so part of it crosses the outer's RIGHT edge → both
  are CROPPED there (the crop), right where the outer (a world child) casts its desktop drop-shadow. Each widget multiplies only its
  OWN `@alpha` when painting (`RectangularAppearance`; stroke and fill share that one alpha — there is NO opaque-stroke-over-
  transparent-fill, the original test name notwithstanding), and a parent's alpha is NOT propagated to children — so
  `outer.setAlphaScaled 10` (the method the "transparency..." prompt's Ok calls) fades the outer (fill + border, desktop showing
  through) while the CROPPED inner panel + box stay FULLY opaque (alpha-non-cascade). First PanelWdgt-rendering test (stroke + crop +
  shadow + alpha-non-cascade; unlocks the panel-rendering family). GOTCHA: the children must STRADDLE the panel's edge (be moved so
  part crosses it) for the crop to be visible — fully-inside children show no clipping.
- **Composite drop-shadow** (`macroCompositeMorphsHaveCorrectShadow`): a shadow comes from `Widget.add`, NOT `attach` — `world.add
  widget` gives the desktop shadow (`addShadow`, offset (4,4) α0.2, `Widget.coffee:2199`), re-parenting to a non-world parent calls
  `removeShadow` (`:2210`). The shadow paints the recursive silhouette of the whole subtree, so `world.add parent` then
  `parent.add child` makes the parent's shadow outline the WHOLE composite. To force a shadow on a morph that never routed through
  `world.add`, call `widget.addShadow()` explicitly.
- **A widget is painted correctly the INSTANT it is picked up** (`macroPanelPaintedOkAsSoonAsPickedUp`): the grab path produces a complete,
  correct first frame WHILE the morph is held — synchronously, no settle. `ActivePointerWdgt.grab` does `@add aWdgt` (which FORCES the
  morph's first paint — its comment: "the shadow needs the image of the widget"), then `addShadow new Point(6,6),0.1` (the floaty drag
  shadow — larger+fainter than the at-rest (4,4)α0.2 desktop shadow), then `fullChanged()`. A `PanelWdgt` (cream fill + dark 1px stroke via
  `RectangularAppearance`, painted synchronously; `defaultPanels*`, `PreferencesAndSettings.coffee:122-123`) overrides nothing in the grab
  path, so its held frame is deterministic — no timer/animation/frame-race, and axis-aligned chrome (no trig → immune to the cross-engine
  `Math.sin/cos` issue). Build `new PanelWdgt` + `rawSetExtent` + `world.add` + `fullRawMoveTo` (equivalent to the demo "panel" item, since
  `WorldMorph.create` IS `pickUp()` and PanelWdgt overrides nothing in the grab path), then the held mid-drag idiom:
  `@moveToAndMouseDown_InputEvents panel.center()` → `@syntheticEventsMouseMove_InputEvents pt, "left button"` (lifts onto the hand) →
  `takeScreenshot…` (the held panel, fully painted with its drag shadow) → `@syntheticEventsMouseUp_InputEvents()`. The paint-on-pickup
  sibling of `macroDuplicateSimpleWidgetRidesHand` (a DUPLICATE painted-OK the instant it's grabbed) and the held-shadow companion of
  `macroCompositeMorphsHaveCorrectShadow`. No new verb.
- **Shape hit-test / click-through** (`macroRoundedBoxCornerClickThrough`): the pointer resolves to a morph by SHAPE, not bounding
  box — `ActivePointerWdgt.topWdgtUnderPointer` skips any morph that `isTransparentAt` the pointer (`:48`). A `BoxMorph` with a
  large `cornerRadius` is transparent at its corners (`BoxyAppearance.isTransparentAt` outside the rounded arc). Put a
  RectangleMorph backdrop behind a `new BoxMorph 55`, then `@moveToAndClickAtFractionOf_InputEvents box, [0.96,0.96]` (a corner —
  click passes THROUGH, backdrop comes forward) vs `[0.1,0.4]` (the body — box comes forward). The z-order flip on left-click
  (`bringToForeground`) is the observable.
- **Rectangular clipping** (`macroClippingBoxClipsChildAtBounds`): a `ClippingBoxMorph` is an ORDINARY BoxMorph that merely
  `@augmentWith ClippingAtRectangularBoundsMixin` (the whole class body) — the mixin clips children to its bounds. `new
  ClippingBoxMorph` (setColor/rawSetExtent/fullRawMoveTo/world.add), `clipBox.add child`, then move the child
  (`child.fullRawMoveTo …`) to STRADDLE each edge in turn — it's cut off at that edge, proving the clip is the box's fixed
  rectangle on every side.
- **Hide / show + subtree** (`macroHideUnhideMorphChain`): `widget.hide()` / `widget.show()` flip `@isVisible`; the paint
  recursion short-circuits at an invisible morph BEFORE its children (`Widget.preliminaryCheckNothingToDraw`), so hiding a
  mid-chain morph hides its WHOLE subtree, and `show()` restores it. Drive them DIRECTLY — `hide()` is the "hide" item's method,
  and `show()` MUST be programmatic (a hidden morph can't be right-clicked; recordings un-hide via an inspector `show()` eval).
  `show()` no-ops if the morph is already effectively visible (ancestor-chain AND), so a hide→show round-trip is image-identical.
- **Canvas / pen turtle drawing** (`macroSierpinskiInCanvas`): `canvas = new CanvasMorph; canvas.rawSetExtent (new Point W, H)`
  (REQUIRED — CanvasMorph ships no default extent), `canvas.fullRawMoveTo …; world.add canvas`; `pen = new PenMorph; canvas.add
  pen` — a PenMorph draws on its PARENT when that parent is a CanvasMorph (`PenMorph.forward → @parent.drawLine`), so attaching it
  to the canvas wires the turtle to the surface. Place with `pen.fullRawMoveTo …` and call a drawing method DIRECTLY, e.g.
  `pen.sierpinski 400, 40` (synchronous).

## Assertions & eval

- **Non-screenshot assertions** (`macroCheckNumberOfItemsInWorldMenu`, `macroLonelySliderTargetsWorldOnly`): with a menu open,
  `@assertTopMenuItemCount n` and `@assertTopMenuItemStrings ["label", …]` (reads each item's `labelString` via the menu's
  `testItems()`, compares the ordered array) → `world.automator.player.recordMacroAssertion(passed, desc, expected, found)` (the
  generic sink: flips `allTestsPassedSoFar`, records the failing test, logs expected-vs-found, but does NOT stop the macro). These
  MUST be `@assert…` toolkit methods — `recordMacroAssertion` has "Macro" mid-token, which the invocation rewriter would mangle in
  macro SOURCE. `macroLonelySliderTargetsWorldOnly`: a lone controller can only target the WORLD — `openTargetSelector` lists
  bounds-intersecting widgets + always the world (Widget.coffee:846); with nothing overlapping, "a WorldMorph ➜" is the only item.
- **Button-trigger discipline** (`macroButtonTriggersOnlyOnSameMorphMouseUp`): a button fires only when mouse-down AND mouse-up
  land on the SAME morph (`ActivePointerWdgt.processMouseUp` fires only `when w == @mouseDownWdgt`). To show "press then release
  elsewhere does NOT trigger", press on the button and release off it: `@syntheticEventsMouseMovePressDragRelease_InputEvents
  (@pointAtFractionOf button, [0.5,0.5]), (new Point X, Y)`. Parent the button INSIDE a container (window/panel), NOT bare on the
  world (`EmptyButtonMorph.rejectDrags` is false only when the parent is the world, so a loose button float-drags on the press).
- **In-system eval** (`macroEvaluateString`): `world.evaluateString "code"` runs arbitrary CoffeeScript against the live world
  INLINE (compile, run with `@`=world, relayout/repaint) — this is what the old recorded `AutomatorEventCommandEvaluateString` command did (that command no longer exists).
  Do NOT write `@evaluateString` (MacroToolkit's own binds `@` to the toolkit). No new verb; no input events, so just `yield
  "waitNoInputsOngoing"` before a screenshot.
- **Eval in the inspector work-area** (`macroInspectorWorkAreaEvaluatesCoffeeScript`): the (old) `InspectorMorph`'s lower "work" pane is a
  live CoffeeScript eval bound to the inspected object. Open it via the world menu's top-level **"inspect"** (NOT "dev ➜ → inspect", which
  opens InspectorMorph2 and a different pane), then reach the editable TextMorph as `inspector.work.contents.children[0]` (built with
  `ev.setReceiver @target`, `InspectorMorph.coffee:176-186`, which also installs the evaluation menu as the pane's `overridingContextMenu`).
  PLACE the code with `workArea.setText "@inform 'coffeescript!'"` (do NOT left-click an EMPTY old TextMorph to focus it — `slotAt` measures
  `@lines[0][col]`, undefined past the end of empty text, `TextMorph.coffee:283`, which throws under SWCanvas and pops an Error-log over the
  scene; the trap GENERALISES to any click past the END of a line — a short inspector detail value like "1" clicked with the detail +14px
  idiom dies the same way, so caret into a short text at slot 0: `valueText.topLeft().translateBy new Point 3, 8`, the idiom of
  `macroDuplicatedInspectorDrivesCopiedTargetOnly`), then `@openMenuOf_InputEvents workArea` → `@moveToItemOfTopMenuAndClick_InputEvents "do all"`: `doAll` selects-all and runs
  `@receiver.evaluateString @selection()` (`TextMorph.coffee:360-377`), so the snippet runs against the inspected World and pops an `@inform`
  bubble. The eval-acts-on-the-receiver sibling of `macroEvaluateString` (which calls `world.evaluateString` directly). Single quotes inside
  the snippet dodge double-quote escaping in the backtick source. No new verb.
- **No-op invariants via pixel-identical references** (`macroResizeMoveModeIsLosslessAndReenterable`): to assert "X changes
  NOTHING", screenshot the baseline, do X, screenshot again — SWCanvas + the event queue are deterministic, so the second
  capture comes out with the SAME `dataHash` as the first, and ANY side effect of X breaks the second match. Shipped example:
  a resize/move-mode enter/exit with no handle drag (right-click → "resize/move..." → click the empty desktop) is LOSSLESS
  (image_2 ≡ image_1, equal dataHash at both dprs) and the mode is RE-ENTERABLE (three sessions on one rectangle — no-op,
  grow, shrink — each entry building a fresh set of the four mode handles). Inherited from the recorded
  fiddlingWithResizerHandles, whose own references already held the law (its image_4 ≡ image_3 byte-identical in all six
  reference families: native/SWCanvas/Windows × dpr 1/2). No new verb.

## The verb-establishing pilots

- **`macroBasicWorldMenuAndBubble`** (from 89 cmds): open the world menu, hover "demo", `yield <ms>` for the help bubble, screenshot.
- **`macroAddEditSaveRenameRemoveProperty`** (from 1057 cmds, 5 shots): demo-menu a string, inspect it, then add / set-value+save /
  rename / remove a property via the inspector. INSPECTOR gotchas: context-menu "inspect" opens the OLD `InspectorMorph`; "dev ➜ →
  inspect" opens `InspectorMorph2` (the `*FromTopInspector*` helpers assume InspectorMorph2). A value/detail pane's text (e.g.
  "nil") is a `TextMorph` in a scroll-panel, NOT a text-described StringMorph — locate it by structure (`inspector.detail`) + click
  near its top-left, and `yield ~300` to let a freshly-updated pane lay out before clicking (its `center()` can be undefined).
- **`macroCanMoveAndResizeColorPaletteMorph`** (from 523 cmds): enter resize/move mode (`@openMenuOf_InputEvents` → "resize/move...")
  then drag a corner handle; click empty desktop to exit before the screenshot.
- **`macroSimpleDocumentProgrammaticBuildAndScroll` / `…ManualBuildAndScroll`**: build the SAME scrollable `SimpleDocumentScrollPanelWdgt`
  — one fills it via `doc.add`, the other by DRAGGING two desktop text widgets in (`@dragWidgetTo_InputEvents`) — then wheel-scroll.
  GOTCHA: `SimplePlainTextWdgt` width floors ~330px, so narrow the doc and place draggables SIDE BY SIDE (stacking overlaps them).
- **`macroDemoMenuCatalogueParade`** (from the recorded buildAllMorphs, 70 steps → 1 shot): the whole-catalogue construction smoke —
  every STATIC "demo ➜" item built via the real menu (a per-test `makeDemoWidget itemLabel, dropPoint` helper: right-click a
  RESERVED bare menu-home spot → "demo ➜" → item → the fresh widget rides the hand → a click at the authored grid spot drops it
  centered), one reference asserting every catalogue widget's constructor, defaults and first paint at once. When a new demo item
  lands, ADD it to the parade and re-capture. "animation demo" is deliberately excluded: its BouncerMorphs keep moving after the
  drop, so the single reference would depend on cycle count.

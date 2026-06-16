# Class-modernization playbook — lessons from the InspectorMorph → InspectorWdgt arc

This is a reusable playbook for **"bringing a class to latest"**: deleting a superseded legacy class,
renaming its modern replacement to the `*Wdgt` convention, making it the only implementation used
everywhere, and **re-authoring the macro SystemTests** that exercised it. It was distilled from the
2026-06 arc that deleted `InspectorMorph`, renamed `InspectorMorph2`→`InspectorWdgt` (+
`ClassInspectorMorph`→`ClassInspectorWdgt`), made the inspector windowed everywhere, and re-authored its
14 macro tests. Reuse the *process* and the *gotchas*; the inspector specifics are the worked example.

Companion docs: `src/CLAUDE.md` (build/run/test), `src/macros/CLAUDE.md` + `src/macros/MACRO-PATTERNS.md`
(macro subsystem), the `/author-macro-test` skill (in `Fizzygum-tests`).

---

## 0. Shape of the work

Two repos move together (keep them sibling; the build hard-codes `../`):
- **`Fizzygum/`** — source: the rename/delete/rewire + the docs. Small, mechanical.
- **`Fizzygum-tests/`** — the macro tests that used the class: re-author each, recapture references at
  dpr 1 & 2. **This is the bulk of the effort** — each test is its own author→build→capture→eyeball→verify loop.

Budget accordingly: the source change is an afternoon; re-authoring N tests is N iterative loops, and the
hard ones (anything touching the class's *internal structure* or *presentation*) each take several capture
cycles. Track every test explicitly (see §6) — it is easy to lose one.

---

## 1. The source rename/delete (mechanical, low-risk)

The build is **name-extraction-based**, so a class rename is just: rename the file, the `class X` line, and
every **bare-identifier** reference. There is no manifest.
- `git mv Foo.coffee Bar.coffee`; change `class Foo …` → `class Bar …`.
- Update bare-identifier refs: `extends Foo`, `@augmentWith Foo`, `new Foo`, `instanceof Foo`,
  `findTopWidgetByClassNameOrClass Foo`. Grep for the identifier across `src/**/*.coffee`.
- A subclass of a `*Wdgt` base should also be `*Wdgt` (e.g. `ClassInspectorMorph`→`ClassInspectorWdgt`).
- **No string-literal class refs** in source: serialization stores `@constructor.name` and restores via
  `window[className]`, both follow the rename automatically (only *committed saved snapshots* would break;
  there are none).
- **Renaming changes zero pixels** — a class's own name is never drawn (colloquialName uses the *target's*
  name), and SWCanvas reference matching is on the raw-pixel `dataHash`, keyed on OS+ceilPixRatio+`/SWCanvas/`,
  never on class name. So tests that already drove the *kept* class need only a **string/tag relabel**, not a
  recapture.
- After the source change: `./build_it_please.sh` (syntax gate) then `./build_and_smoke.sh` (headless
  native+SWCanvas boot — catches load-order / missing-class faults the syntax gate can't).

**Gotcha — find the bare `\bFoo\b`, not the substring.** `InspectorMorph` is a substring of `InspectorMorph2`;
grep with word boundaries and read each hit.

---

## 2. Presentation is part of "to latest" — don't assume the call site is fine

The biggest surprise of the arc: the kept class (`InspectorMorph2`) had been designed to live **inside a
window**, but the deleted class's call site (`spawnInspector`) opened the new one **naked** — and it rendered
*broken* (cramped, transparent, half-painted). The fix was an **owner decision** (windowed everywhere), not a
mechanical port.

**Lesson:** before re-authoring tests, *open the new class the way each call site does and LOOK at it.* If it
renders wrong, the presentation needs an explicit decision (ask the owner) — that decision then changes every
test. Don't grind tests against a broken-looking widget.

For the inspector the decision was: make **every** inspect path wrap it in a `WindowWdgt` (560×410). That in
turn changed the test mechanics (resize via the window resizer, close via the window button, and — critically —
the inspector is now an *external* window that **refuses to nest**; see §4).

---

## 3. The per-test re-authoring loop

For each test (use the `/author-macro-test` skill):
1. **Read the old macro + the new class's source.** Map old mechanics → new affordances. Recover a deleted
   class for reference with `git show HEAD:src/meta/Foo.coffee > /tmp/Foo.coffee`.
2. **Rewrite** `SystemTest_<name>_automationCommands.js` (the `mainMacroSource`) and the descriptive strings in
   `SystemTest_<name>.js` (`intent`/`scenario`/`assertions`/`provenance`/`tags`). Keep behaviour, not the old
   internals. `node --check` both files before building (the build's test-`.js` gate catches stray backticks).
3. **Capture at dpr 1 with `--no-verify` and EYEBALL the PNG first:**
   `node scripts/capture-macro-test-references.js SystemTest_<name> --clean --dprs=1 --no-verify`
   then read the written `automation-assets/.../ceilPixRatio_1/*image_*.png`. A green capture proves
   *determinism*, not *correctness* — the eyeball is what catches "selected the wrong row", "no visible
   change", "an Error-log window got captured". **Fix the macro, never the reference.**
4. **Full capture + verify at both densities** once the images look right:
   `node scripts/capture-macro-test-references.js SystemTest_<name> --clean --dprs=1,2`
   → expect `TEST PASSED` twice + `DONE`.
5. **Regenerate the visualisation:** `node scripts/make-visualisation.js SystemTest_<name>` (always — it's a
   build output; it embeds the new screenshots + metadata).

Distinct dataHashes across a test's images confirm each step *changed* something; identical hashes for two
shots either prove a no-op/round-trip (intended) or mean a step silently did nothing (bug).

---

## 4. Reusable mechanics & gotchas (these recur for any widget)

**Canvas / layout**
- The headless canvas is **960×440 at dpr 1**. A 560×410 window only just fits — park windows near the
  top-left (`win.fullRawMoveTo new Point …, ≤15`) so chrome and the bottom-right resizer stay on-canvas.
- After a drag that ends *on* a widget (resize, etc.), **move the pointer to a neutral empty spot before the
  screenshot** (`@syntheticEventsMouseMove_InputEvents clearPoint, "no button", 300`). A hover highlight left
  under the cursor is an invisible determinism trap (passed dpr1, failed dpr2 in the arc).

**Windows (`WindowWdgt`)**
- A widget built "to live in a window" is opened windowed via `Widget.spawnInspector`-style wrappers; find it
  with `@findTopWidgetByClassNameOrClass WindowWdgt`. Resize via `@dragWindowResizerTo_InputEvents win, dest`;
  close via `@closeWindow_InputEvents win`; duplicate via a title-bar → `"a Window ➜"` → `"duplicate"` helper.
- **External windows refuse to nest** (`WindowWdgt.rejectsBeingDropped = !@internal`) — a drop onto a
  container forces it to the world (it floats, never embeds). To drop a window into a document/panel, call
  **`win.makeInternal()`** first (the genuine internal/external toggle affordance, `WindowWdgt.coffee:106`).
- **Don't detach window chrome and then use it.** Picking the window's close button onto the desktop and then
  clicking it to close the window triggered a SWCanvas `"source rectangle outside image bounds"` paint fault.
  For "a button's action fires only on a real same-morph click" tests, build a **standalone** button
  (`new SimpleButtonMorph true, target, "action", "label"`) wired to a visible effect (e.g. `box.hide()`)
  rather than borrowing chrome.

**Lists & text panes (`ListWdgt`, `TextWdgt`/`SimplePlainTextWdgt`)**
- **Select a list row by SCROLLING to it first**, not by clicking a by-text match. A row that sorts below the
  visible area exists as a (clipped, off-pane) morph; clicking its `topLeft` lands outside the pane and selects
  the *wrong* visible row (this silently no-op'd a `save`). Scroll with the toolkit idiom
  (`@calculateVertBarMovement list.vBar, idx, list.elements.length` → `@syntheticEventsMouseMovePressDragRelease…`)
  then click the now-visible row at `row.topLeft() + (10,2)`.
- A **`TextWdgt`'s context menu can't be opened by a synthetic right-click** in a macro. So its "do all" /
  evaluation menu, soft-wrap toggle, etc. are not reachable that way — call the underlying method directly
  (`detailText.softWrapOn()`, `textBox.toggleSoftWrap()`) or use the dedicated UI affordance (see "eval" below).
- A `SimplePlainTextWdgt` detail/console pane **defaults to NON-wrapping** (long lines scroll horizontally).
  Call `detailText.softWrapOn()` (sets the scroll panel's `isTextLineWrapping`) to make it wrap, then container
  resizes re-wrap it.
- To focus an editable pane for typing without a click, call `pane.edit()` (`world.edit`) — the established
  idiom. (The old `StringMorph`/`TextMorph`, whose empty-field `slotAt` crashed under SWCanvas, are now deleted;
  the modern `StringWdgt`/`TextWdgt` are safe to click empty.)

**Eval / "run a snippet against this object"**
- Eval lives behind each widget's **"dev → console"** menu → a `ConsoleWdgt`: an editable code area +
  "run selection"/"run all" buttons; **"run all" → `doAll`** compiles the text and runs it with `@` = the
  console's target. Drive eval through that real UI (`consoleWdgt.textMorph.setText "…"` then click
  `consoleWdgt.runAllButton`) — prefer it over `world.evaluateString` (a workaround that bypasses the UI).
- "dev → X" menu items (inspect, console, …) are reached with
  `clickMenuItemOfWidget_InputEvents_Macro w, "dev ➜"` → `@moveToItemOfTopMenuAndClick_InputEvents "X"`.

**Property editing & saving**
- An inspector's `save` runs `@target.injectProperty(propertyName, txt)` → `@evaluateString "@<prop> = <txt>"`
  with `@` = the target — it SETS the value. But a **field change does NOT auto-repaint** the target the way a
  method change does; in a real UI test the surrounding interaction repaints it, so don't "fix" a missing
  repaint with `target.changed()` — fix the *interaction* (the wrong row was selected, the widget was hidden
  behind another, the value isn't visibly different). Make the visible effect unambiguous: small target, large
  inspector, a property whose change is obvious (alpha → transparency), targets positioned so the change shows.
- Inspectors **hide inherited properties by default** — toggle "inherited" on (`showInheritedToggle`) to reach
  e.g. `alpha`, and remember it then sorts among the other rows (scroll to it, §lists).

**Determinism & the capture script**
- `--clean --no-build` is a trap: `--clean` drops the *source* refs but the *build* keeps stale ones, so an
  image that happens to match a stale ref is scored PASS and never re-saved → it ends up reference-less and
  "fails" verify. Use the script's **own full flow** (no `--no-build`) when you want published refs; use
  `--no-verify` only to grab a PNG to eyeball.
- A `@assertScreenshotsIdentical` round-trip can be **too strict**: list sub-row scroll rendering left two
  visually-identical shots byte-DIFFERENT. If the round-trip is genuinely visual-only, drop the byte-assert and
  show it with the screenshots (note why in the macro/provenance).

---

## 5. Docs are a deliverable

Every modernization must also update the prose that describes the old class:
- `src/macros/CLAUDE.md` — the per-subsystem gotchas (e.g. the "inspector" note).
- `src/macros/MACRO-PATTERNS.md` — the per-test entries that describe the now-changed mechanics. Rewrite each
  affected entry; a future author consults these and will be misled by stale internals.
- The `/author-macro-test` skill (`Fizzygum-tests/.claude/skills/author-macro-test/SKILL.md`) — its gotchas
  and the `@`-vs-`world.` globals list.
- The auto-memory note for the project, so the next session starts with the new reality.

Keep *historical* prose accurate ("the old `Foo` was removed") — that's not a stale reference, it's provenance.

---

## 6. Process lessons

- **Track every affected test explicitly** (a task list). The arc nearly shipped with one test
  (`macroAddEditSaveRenameRemoveProperty`) un-re-authored because it had been filed as a "relabel" but actually
  drove the class — its macro still searched the deleted class as a *string*. A whole-repo grep + per-test
  accounting caught it. **The grep-clean intent is "no functional/code references to the deleted class"** — not
  "no mentions"; historical prose is fine.
- **Prefer the real UI path; ask before substituting.** When the new class lacks an affordance the old test
  used, surface it to the owner rather than silently working around it. The arc's eval test went
  workaround → (owner pointed out the console) → real "run all" button; the document/panel tests went
  "can't nest" → (owner chose) → `makeInternal`. Owner input turned three "blocked" tests into faithful ones.
- **A green capture is not a correct test.** SWCanvas is deterministic, so a wrong-but-stable macro captures and
  "passes". Eyeball every first capture.
- **Verify the whole suite at the end:** `cd Fizzygum && ./build_and_test.sh` → **160/160**. (If a shard
  reports `DISCONNECTED`/`did not start`, that's a browser-launch resource hiccup under parallel load, not a
  test failure — re-run `cd Fizzygum-tests && node scripts/run-all-headless.js`.)

---

## 7. Candidate next classes

The end state is **all-`*Wdgt`** — `Morph` is legacy and the `*Morph`→`*Wdgt` migration is WANTED. Do it
**deliberately and incrementally**: rename a coherent group (a class + its family) when there's a reason — a
duplicate to delete, a class surfacing in tests, or finishing a family a prior arc started — **not in one sweep**.
Two reasons it's incremental, not big-bang: (a) a rename here is not always pixel-free — the menu/hierarchy labels
strip `Wdgt`, so renaming a class whose colloquial name is *drawn* (e.g. a menu item, shown as `"a MenuItem ➜"`
instead of `"a MenuItemMorph ➜"`) shifts that label and forces screenshot recapture; verify per class — and (b)
each rename is a whole-tree identifier+file+serialization sweep, best done one verifiable batch at a time.
Candidates surfaced during the inspector arc: `RectangleMorph` (the `SimpleButton*` / button family
was migrated to `*Wdgt` in the TriggerMorph arc, below).

**DONE (2026-06): the String/Text arc.** Deleted the legacy `StringMorph`/`TextMorph` and renamed
`StringMorph2`→`StringWdgt`, `TextMorph2`→`TextWdgt`. The dominant cost was that the deprecated `TriggerMorph`
menu/button/tooltip chrome built its labels from the old family; re-pointing it onto the modern family (which
sizes the TEXT to a fixed box rather than the box to the text) needed a shared `StringWdgt#sizeToTextAndDisableFitting`
helper + the `autoSizeBoxToText` flag, and shifted the menu/header/tooltip pixels of ~76 tests (recaptured). New
lessons that bit hard and are now folded into §4 above:
- **Menu/target labels strip `Wdgt`** — a `TextWdgt` shows/navigates as `a Text ➜` (not `a TextWdgt`); the
  inspector hierarchy diagram and `findTopWidgetByClassNameOrClass`, by contrast, use the REAL class name. So the
  rename DID move pixels (inspector/menu displays) and DID need menu-nav-string edits — it was NOT pixel-free.
- **Renaming a class with a digit (`*Morph2`) via a word-boundary/lookbehind sweep**: a compound TEST NAME like
  `macroStringMorph2AndTextMorph2ResizingInLayout` has a SECOND class token not preceded by `macro`, so a naive
  `(?<!macro)` guard renames it and breaks the metadata var↔dir match (`reading 'testDuration' of undefined`).
  After any test-name-adjacent sweep, assert every `var SystemTest_<name>` matches its directory.
- A self-sizing chrome label needs to re-hug its text on **setText AND setFontSize** (the old family reLayout'd on
  both), else an edited/font-driven caption is crammed into the stale box.

(The content-text reflow follow-up it deferred is now DONE — see the FIT_BOX_TO_TEXT arc below.)

**DONE (2026-06-15): the content-text reflow / FIT_BOX_TO_TEXT arc (roadmap #1, the FIRST non-rename
technical cleanup).** Made a bare `TextWdgt` re-wrap + auto-grow/shrink its height as window/panel/scroll
CONTENT, like `SimplePlainTextWdgt` already did — done PROPERLY (not the cheap "widen `instanceof
SimplePlainTextWdgt` + propagate `maxTextWidth`"). Retired the dead-`TextMorph` `maxTextWidth` knob; WIRED the
pre-scaffolded `FittingSpecText` enums (`fittingSpec` mode + tight/loose + which-dimension sub-axes) into
`reflowText`/`TextWdgt::reLayout`/`createBufferCacheKey`; removed the 3 `instanceof SimplePlainTextWdgt` render
leaks (→ `fittingSpec == FIT_BOX_TO_TEXT`); moved the contained-reflow engine onto `TextWdgt::reLayout` gated by
the mode, leaving `SimplePlainTextWdgt` a thin mode-specialization; re-pointed the 3 content sites
(`WindowWdgt`/`SimpleVerticalStackPanelWdgt`/`ScrollPanelWdgt`) to RESPECT the mode. New lessons:
- **Wiring a mode that one subclass already half-implemented hides INCOMPLETE wiring — the new general-case
  tests expose it.** Two gaps only a *bare* `TextWdgt` hit (a `SimplePlainTextWdgt` dodged both via its ctor):
  (a) `reflowText` must SHORT-CIRCUIT `fitToExtent` for the box-to-text mode and render at the set font size —
  otherwise `SCALEUP`'s `searchLargestFittingFont` + the mode's "always measure at the set size" render leaks
  agree that *every* font size fits, so it picks the MAX (a giant font); SPTW's ctor pins `FLOAT`, so it never
  ran the scale-up search. (b) `WindowWdgt.contentsRecursivelyCanSetHeightFreely` must return false for the
  mode (height is content-driven) or the window follows the dragged height and won't auto-SHRINK on widen;
  SPTW pins `layoutSpecDetails.canSetHeightFreely = false`. Both fixes are byte-identical for SPTW (it already
  reached the same state) — so the "160/160 zero-recapture" invariant held for the refactor, and these were
  caught by the NEW capability tests, which is exactly why the owner asked for them.
- **Imposing the mode on `instanceof TextWdgt` at the layout sites catches the empty-window placeholder**
  (`WindowContentsPlaceholderText extends TextWdgt`) and breaks every empty/placeholder window. The sites must
  RESPECT the mode (`if morph.fittingSpec == FIT_BOX_TO_TEXT`), not impose it — a TextWdgt opts in itself
  (SPTW via ctor; a bare one via the caller), the placeholder stays `FIT_TEXT_TO_BOX`.
- **Adding properties to a base class is NOT pixel-free for inspector tests that introspect it.** The 3
  `fittingSpec*` props on `StringWdgt` made the Object Inspector's StringWdgt property LIST 3 rows taller, so 3
  inspector tests recaptured (the only churn; confirmed NOT load-order — a literal-default build rendered
  byte-identically — so it is inherent to the class gaining own props). Diff confined to the list column.
- **A drop-state vs a resize-state are different sizing paths** — a window-content round-trip asserts
  byte-equality between TWO resizes to the SAME absolute width, not drop-vs-resize-back.
- Result: **162/162 (Chrome + WebKit), `--homepage` boots** (the enums were de-excluded from the homepage
  strip — a base class now references them in production). New tests:
  `macroBareTextWdgtAsWindowContentReflowsOnResize`, `macroBareTextWdgtInVerticalStackReflows`; 6 existing
  macros migrated `maxTextWidth`→`softWrap`.
- **FOLLOW-UP (2026-06-15): bare-TextWdgt setText-reflow parity (closed the documented scope boundary).** The
  arc left a gap: a bare FIT_BOX_TO_TEXT TextWdgt reflowed on a container RESIZE (`rawSetExtent`→`reLayout`) but
  NOT on its OWN `setText` (that reLayout+refresh trigger still lived on `SimplePlainTextWdgt`). Moved it up: a
  new gated helper `TextWdgt::reLayoutAndRefreshContainerIfContainedText` (`if fittingSpec == FIT_BOX_TO_TEXT`
  then `reLayout` + `refreshScrollPanelWdgtOrVerticalStackIfIamInIt`), and `TextWdgt` now overrides the 7 edit
  methods (`setText`/`setFontSize`/`setFontName`/`toggleShowBlanks`/`toggleWeight`/`toggleItalic`/`toggleIsPassword`)
  as `super` + the helper. `SimplePlainTextWdgt` deleted its 6 pure-trigger overrides and keeps only `setText`,
  and only for the ControllerMixin plumbing (the `connectionsCalculationToken` guard + `updateTarget`) — it
  delegates the reflow to the base via `super`. Lessons reaffirmed: **(a)** keep the behaviour byte-identical for
  the subclass by having its retained override `super` into the moved-up logic (traced: same call order, same
  double-`updateTarget`) — its existing tests stayed green, suite **163/163 (Chrome + WebKit), `--homepage`
  boots**; **(b)** gate the moved-up trigger on the MODE, not the type, so the other FIT_TEXT_TO_BOX subclasses
  (`WindowContentsPlaceholderText`, `FizzytilesCodeMorph`) get a clean no-op (the "respect the mode" rule). New
  test `macroBareTextWdgtReflowsOnSetText` (desktop bare FBT TextWdgt; setText changes the line count → box
  height reflows; round-trip byte-asserted).

**DONE (2026-06): the TriggerMorph / button-family arc.** Deleted the deprecated `TriggerMorph`; re-based its
subclasses onto the modern button family and migrated that family's base to `*Wdgt`. Final hierarchy:
`Widget → ButtonWdgt → { SimpleButtonWdgt, LabelButtonWdgt → { MenuItemMorph, MagnetWdgt } }` (renames:
`EmptyButtonMorph`→`ButtonWdgt`, `SimpleButtonMorph`→`SimpleButtonWdgt`, `MagnetMorph`→`MagnetWdgt`). The deprecated
class's flat-label-button role was re-homed in a NEW shared base `LabelButtonWdgt` (non-deprecated, on the modern
family). Lessons folded in above and new ones:
- **Re-basing onto a class that `@augmentWith`s a behaviour mixin can silently change behaviour through the mixin.**
  `ButtonWdgt` augments `HighlightableMixin`; a naive re-base inherited its `updateColor` (which `setColor`s — would
  clobber the retained flat fill), its `mouseUpLeft` (resets `state`→NORMAL — breaks list-row selection that reads
  `STATE_PRESSED`), and its `doLayout` (lays out a `faceMorph` a label button hasn't). Each needed an explicit
  override; `mouseDownLeft` had to replicate `Widget`'s INLINE rather than `super` (which hits the mixin). Audit the
  new base's mixins before assuming a re-base is behaviour-preserving.
- **Keep the look by RETAINING paint, not adopting the new family's.** The button family draws no flat fill
  (`ButtonWdgt` is transparent, `SimpleButtonWdgt` is a rounded box), so menus stayed pixel-identical only because
  the flat `paintIntoAreaOrBlitFromBackBuffer` + state machine moved onto `LabelButtonWdgt` unchanged.
- **`MenuItemMorph` deliberately NOT renamed** — it's drawn in hierarchy nav labels (`"a MenuItemMorph ➜"`), so the
  menus-strip-`Wdgt` rule makes its rename a pixel/recapture event; left for a later batch (the incremental rule above).
- Result: suite 160/160, **zero reference-image churn** (the renames were pixel-neutral identifier swaps; the only 2
  changed tests build `new MenuItemMorph` and render byte-identical to their originals).

**DONE (2026-06-16): the TextWdgt-shadows arc (roadmap #3) — closed as SUBSUMED, a "don't build it; prove + document
the existing mechanism" arc.** A class-modernization arc is not always "add code": #3 asked to restore the deleted
`TextMorph` per-glyph `shadowOffset`/`shadowColor`, but investigation showed that was the WRONG thing to build. New
lessons, generally reusable:
- **Disambiguate the feature against what already exists BEFORE planning to build it.** "Shadow" meant two unrelated
  things: (a) the unified **widget drop-shadow** — a widget with `@shadowInfo` re-paints its whole subtree faintly +
  offset (`Widget.coffee:1777-1828`); `Widget.add` gives a free-floating world child offset (4,4)/α0.2 (`:2199`),
  `ActivePointerWdgt.grab` lifts it to (6,6)/α0.1 while dragged (`:209`), clipping panels clip it to their rect
  (`ClippingAtRectangularBoundsMixin`) — and `BackBufferMixin.coffee:114` blits each widget's buffer at
  `appliedShadow.alpha`, so a *transparent* text widget's drop-shadow already IS a faint copy of its glyphs; vs (b) the
  deleted **per-glyph baked emboss** (offset coloured glyph copies in the text's own back-buffer, always-on). The owner
  wanted (a)'s behaviour; (b) is redundant with it. Net: nothing to build — just a TEST + a doc fix.
- **Owner principle worth recording:** *no widget bakes its own shadow into its back-buffer* — the one unified
  mechanism casts every shadow (hand/pointer + the shadow pass itself excepted). A per-glyph "text style" shadow is a
  separate concept, deliberately not (re)introduced.
- **The existing suite already protects an "incidental" rendering** — ≥7 tests `world.add` a bare string/text, so the
  at-rest glyph drop-shadow was already captured + byte-locked; the only GAP was the *lifted* shadow on a bare text
  widget while dragged (every drag-shadow test used menus/prompts/panels). The new test fills exactly that gap.
- **A "tweak the docs" deliverable means hunting the MISLEADING wording, not every mention.** Audited shadow comments
  repo-wide; fixed only the genuinely-wrong ones — "silhouette"/"outline" (the shadow is a faint re-paint of the whole
  subtree's *actual pixels*, fill AND content, not an edge) and the stale `TreeNode` "shadow is the first child"
  (shadows became property objects in `3df93e5c`) — and ADDED the never-baked invariant at the canonical sites
  (`Widget.coffee` shadow doc-block, `TreeNode.coffee`, `StringWdgt.coffee` next to `hasDarkOutline` where #3's code
  used to live, `MACRO-PATTERNS.md`). Left historical provenance (`Fizzygum-tests/MIGRATION-PLAN.md`) and unrelated
  uses (icon "floppy silhouette") untouched — historical prose is provenance, not a stale reference (cf. §5).
- Result: **165/165 (Chrome + WebKit), dpr 1 + 2, ZERO reference churn on the existing 164** (the only source edits
  were comments — pixel-neutral). New test `macroBareTextWidgetDropShadowRestAndDrag` (rest -> lifted -> rest, three
  distinct dataHashes). No framework behaviour change.

**DONE (2026-06-16): the ListMorph → ListWdgt rename (BATCH 5 — the lowest-risk rename batch).** A pure
`*Morph`→`*Wdgt` identifier rename of a single **leaf** class (`class ListMorph extends ScrollPanelWdgt`, no
subclasses, no legacy/modern split) — the cheapest shape in §1. The whole source change was 6 bare-identifier refs
+ the filename: `git mv ListMorph.coffee ListWdgt.coffee`, the `class` line, **3** `instanceof ListMorph`
(`ScrollPanelWdgt.coffee:122`, `Widget.coffee:2587`/`:2593`), **1** `new ListMorph` (`InspectorWdgt.coffee:274`),
1 comment. ZERO string-literals (serialization follows `constructor.name`/`window[]` automatically). `MenuMorph` /
`MenuItemMorph` are COMPOSED inside a list (`@listContents = new MenuMorph`), NOT subclasses — out of scope (and
`MenuItemMorph` is the deliberately-deferred BATCH-4 item anyway). New lessons, generally reusable:
- **"Label-shifting" ≠ "recapture" — only a PHOTOGRAPHED label forces recapture.** ListWdgt's colloquial name IS
  drawn (the hierarchy / "choose target:" attach menus strip `Wdgt`, so the menu item shifts `"a ListMorph"` →
  `"a List"`), which §2/§7 flag as the recapture trigger. But the ONLY test that opens that menu
  (`macroAddingMorphToListUpdatesScroll`) screenshots the BEFORE / AFTER-ATTACH / AFTER-WHEEL states — the menu is
  already closed by every shot — so the shifted label is never captured. Net: a label-shifting rename with **ZERO
  reference churn**. Don't pre-classify recapture from "is the name drawn?"; the byte-exact suite IS the oracle —
  rename, run it, and the RED set is the exact recapture set (here: empty).
- **The menu-nav macro string changes to the Wdgt-STRIPPED colloquial, not the new class name:** `"a ListMorph"` →
  `"a List"` (NOT `"a ListWdgt"`). Bonus: `"a List"` is a prefix of BOTH the stripped (`"a List"`) and an unstripped
  (`"a ListWdgt"`) label, so a `moveToItemStartingWith` match is robust regardless of which labeller the menu uses —
  and it correctly stops matching the now-gone `"a ListMorph"`.
- **Test IDENTIFIERS are kept; only test CONTENT is renamed.** The directories/vars `macroListMorphWheelScroll`,
  `macroListMorphAutoScrollsNearDraggedEdge`, … stay (stable test-name convention, cf. the String/Text arc's
  "protect compound test names from the sweep" lesson). The `\b`-bounded grep that finds every real ref naturally
  EXCLUDES them (`ListMorph` isn't word-bounded inside `macroListMorph…`) — the same property that makes the sweep
  safe. Only the `new ListWdgt` fixtures + prose/tags were edited.
- **Distinguish class-noun refs from drawn-label refs when editing test prose.** In the one attach-menu test the
  metadata mixes both: "a ListMorph (extends ScrollPanelWdgt)" → `ListWdgt` (class noun) but the quoted menu choice
  "pick 'a ListMorph'" → `'a List'` (drawn label). A blind `ListMorph`→`ListWdgt` would have written a wrong macro
  string. The other 7 tests had only class-noun refs (bulk `perl -i 's/\bListMorph\b/ListWdgt/g'`); only this one
  was hand-edited.
- **Historical provenance left untouched** (per §5): `Fizzygum-tests/MIGRATION-PLAN.md` (the closed recorded→macro
  record), the `buildSystem/OBSOLETE generateOverviewDoc.py` frozen file-list (already names dozens of deleted
  classes), and provenance strings citing old recorded-test names (`SystemTest_autoScrollingForListMorphs`, …) — all
  provenance, not stale refs.
- Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, ZERO reference-image churn.** 8 tests
  touched (4 `new ListWdgt` fixtures + 1 menu-nav string in `macroAddingMorphToListUpdatesScroll` + prose/tags); no
  test added or removed. The pre-recorded BATCH-5 touch-list in `class-modernization-planning-starting-prompt.md`
  matched the live greps exactly.

**DONE (2026-06-16): the button-family rename completion (BATCH 4) — 6 `*Morph`→`*Wdgt` at once.** Renamed the last
`ButtonWdgt`-rooted `*Morph` leftovers: `MenuItemMorph`→`MenuItemWdgt` (`extends LabelButtonWdgt`),
`SimpleRectangularButtonMorph`→`…Wdgt` + its child `CodeInjectingSimpleRectangularButtonMorph`→`…Wdgt`, and the three
window-chrome icon buttons `Close`/`Collapse`/`UncollapseIconButtonMorph`→`…Wdgt` (`extends ButtonWdgt`). A PURE rename
— these already sat correctly in the modern hierarchy (unlike the TriggerMorph arc, which re-PARENTED), so it was
mechanically BATCH 5 ×6. The `*Button*`-named SEPARATE lineages (`SwitchButtonMorph`/`ToggleButtonMorph`,
`SliderButtonMorph extends CircleBoxMorph`, `RadioButtonsHolderMorph`, `UpperRightTriangleIconicButton`) were CONFIRMED
not to descend from `ButtonWdgt` and DEFERRED to BATCH 7 (owner decision UP FRONT). New lessons:
- **The recapture oracle beat the prediction — and the predicted movers were NOT the actual mover.** Scoping flagged
  the 2 tests whose MACRO string-matches the nav label (`"a MenuItemMorph ➜"`) as the likely recaptures. The suite
  found a DIFFERENT single test red — `macroRightClickClosesDownstreamSubMenus` — which PHOTOGRAPHS a hierarchy menu
  containing `a MenuItem` WITHOUT its macro ever naming the class; meanwhile the 2 predicted tests did NOT recapture
  (their menu closes before every shot). Exactly the BATCH 5 rule, now doubly proven: do not predict recapture from
  "which macro references the class" — rename, run the byte-exact suite, the RED set IS the recapture set (here: 1).
- **A multi-class rename is a safe bulk `\b`-sweep when there are zero string-literals** (verified for all 6). One
  `perl -i 's/\bOldN\b/NewN/g'` per class over `src/**/*.coffee` (CodeInjecting ordered BEFORE SimpleRectangular so the
  substring is `\b`-protected) handles decl+extends+new+instanceof in one pass; `git mv` the 6 files; a `.coffee`-only
  re-grep is the completeness check. The SAME two-pass split as BATCH 5 applies to tests AND to `MACRO-PATTERNS.md`:
  the drawn hierarchy-nav label `"a MenuItemMorph ➜"`→`"a MenuItem ➜"` (Wdgt STRIPPED) is a SEPARATE pass from the
  class-ref `\bMenuItemMorph\b`→`MenuItemWdgt` — a blind class-sweep would wrongly write `"a MenuItemWdgt ➜"`. After the
  doc sweep, grep the docs for the wrong `a <Name>Wdgt` (no ➜) to catch drawn-labels the class-pass over-converted
  (caught two in `MACRO-PATTERNS.md`, incl. a pre-existing stale `a TextMorph` on the same line).
- **The doc deliverable includes UN-deferring a prior arc's note.** `src/macros/CLAUDE.md` still carried the
  TriggerMorph-arc line "`MenuItemMorph` is NOT renamed, so `instanceof MenuItemMorph` and `"a MenuItemMorph ➜"` are
  unchanged" — now actively MISLEADING (a current author would copy a dead nav string). Rewrote it to the new reality.
  (The §7 historical entries above that say "deliberately NOT renamed / deferred to BATCH 4" are left intact —
  chronological provenance.)
- **`git add -A` discipline carried from BATCH 5:** stage specific files; the previous arc swept in a stray generated
  `before-after-comparison.html` (now gitignored). Commit messages with backticks/arrows via `git commit -F`.
- Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, exactly 1 reference recapture**
  (`macroRightClickClosesDownstreamSubMenus`, eyeballed: the hierarchy nav now reads `a MenuItem` between an unchanged
  `a Text` and an unchanged `a MenuMorph`). 22 test files edited (content only; test identifiers kept), no test
  added/removed.

**DONE (2026-06-16): the `RectangleMorph`→`RectangleWdgt` rename (BATCH 6) — the FIRST batch whose renamed class is
genuinely PHOTOGRAPHED.** Renamed the base `RectangleMorph`→`RectangleWdgt` AND its `*Morph` subclass
`HighlighterMorph`→`HighlighterWdgt` (the hover-highlight overlay; zero test refs, pixel-neutral), and re-pointed the
already-`*Wdgt` subclass `VideoControlsPaneWdgt`'s `extends`. A pure `\b`-sweep: ~44 `new` (31 in `Widget.coffee` layout-
demo methods) + 2 `extends` + 2 `instanceof` (`MenuMorph` separator lines) + 2 file renames; **`buildSystem` clean, zero
string-literals in src.** `WorldMorph.createNewRectangleMorph` (the method + its `addMenuItem … "createNewRectangleMorph"`
action strings) is `\b`-protected and deliberately KEPT (out of scope, like BATCH 5's `macroListMorph…` test ids). New
lessons that bit (and are the reason this batch mattered):
- **The recapture oracle beat BOTH predictions — a THIRD proof.** `RectangleMorph` is the go-to generic *fixture* (a plain
  coloured rectangle) AND the test *subject*, so its name is drawn wherever a test names the rect. The coarse menu agent
  predicted **8** tests "photograph the label"; a precise per-screenshot pass cut that to **2** "menu open in a shot". The
  byte-exact suite then went RED on **8** — neither prediction. So: do NOT pre-classify; rename, run the suite, the RED set
  IS the recapture set. (Owner accepted ~2 up front; the actual 8 are the same KIND of change — all benign label shifts —
  so no re-decision needed, but ALWAYS surface that the empirical set was wider.)
- **The 8 reds exercise BOTH label regimes at once** (reconfirming the String/Text-arc split): **(a) menu strip-`Wdgt`** —
  hierarchy / set-target / attach / context menus show `a Rectangle` (was `a RectangleMorph`): `macroHierarchyMenuHoverHighlightsExactSubtree`,
  `macroTargetingHighlightsCandidateMorph`, `macroScrollPanelCoalescesChildMenu`, `macroMenuFromFramedItemNotClipped`,
  `macroAttachShowsNoTargetsMessage` (the rect's context-menu header shifts where the popped message lands); **(b) PromptMorph
  title strip-`Wdgt`** — the transparency popover titled `<morph> alpha value:` → `Rectangle alpha value:`
  (`macroPromptShadowFollowsOnDrag`, `macroPopoverStaysOpenWhenSliderDraggedOut`); **(c) the Object Inspector hierarchy
  DIAGRAM uses the REAL name** → `TreeNode → Widget → RectangleWdgt → this object` (NOT stripped — `macroDuplicatedInspectorDrivesCopiedTargetOnly`).
  EYEBALL caught all three as benign (right content, right highlight, no Error window); none was a regression (a pure rename,
  boot-smoke green, nav strings resolve via the `"a Rectangle"` PREFIX).
- **The plural-boundary gotcha bites FILE SELECTION, not just substitution.** `rg -l '\bRectangleMorph\b'` does NOT list a
  file whose only hit is the plural `RectangleMorphs` (no `\b` between `h` and `s`), so a plural-only file (`macroEmptyStringDoesntGiveSelectAllOption.js`,
  "separator RectangleMorphs") was silently left out of the sweep set. FIX: make the sweep AND its verify plural-aware —
  `s/\bRectangleMorph(s?)\b/RectangleWdgt$1/g`, and a final catch-all `rg -o 'RectangleMorph\w*' | sort -u` to prove only the
  `createNewRectangleMorph` substring survives.
- **`visualisation.html` is git-TRACKED and generated** — it embeds each test's metadata + drawn-label prose, so the `.js`
  sweep leaves it stale. Regenerate every touched dir with `make-visualisation.js <name>` (37 here) or the `tests/` grep-clean
  fails on the stale HTML. (Same two-pass as the `.js`: class-noun→`RectangleWdgt`, drawn-label→`a Rectangle`; the
  `@assertTopMenuItemStrings ["a RectangleMorph ➜", …]` in `macroScrollPanelCoalescesChildMenu` is a FUNCTION-CRITICAL drawn
  label — it ERRORS, not just pixel-diffs, if left unstripped — and a wrapped `("a\nRectangleMorph" prefix)` comment evades a
  line-based `"a RectangleWdgt"` grep, so finish with `rg 'a RectangleWdgt'` AND `rg 'RectangleWdgt"'`.)
- **Doc deliverable also caught a prior-batch miss:** the `/author-macro-test` SKILL.md still said build a button as `MenuItemMorph`
  / `MenuItemMorph.mouseEnter` (BATCH 4 renamed it to `MenuItemWdgt`) — an author would copy a dead class name. Fixed it here
  and noted it (a doc-accuracy fix is in-scope wherever the stale wording lives; cf. §5).
- Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, 8 reference recaptures** (the 8 RED above,
  ≈26 PNGs across both densities), ~38 test files edited (content only; test identifiers kept) + 37 visualisations regenerated,
  no test added/removed. The pre-recorded BATCH-6 plan touch-list matched the live greps (the only surprises were the *recapture
  count* and the plural-only file — both caught by the suite/catch-all, exactly as the "suite is the oracle" rule predicts).

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

**DONE (2026-06-16): BATCH 7 — the Icon family (`IconMorph`→`IconWdgt` + 16 `*Morph` leaf icons; re-point 77 already-`*Wdgt`
children).** The first family of the BATCH-7 "long tail", and the first rename of a **heavily-subclassed BASE**. Renamed the base
`IconMorph`→`IconWdgt` + the 16 still-`*Morph` leaf icons in `src/icons/` (`AngledArrowUpLeft / Brush / CollapsedState / Destroy /
Eraser / External / Flora / Heart / Internal / Pencil2 / Pencil / Scooter / ScratchArea / Toothpaste / UncollapsedState /
UnderCarpet IconMorph`), and re-pointed **all 93** `extends IconMorph`→`extends IconWdgt`. New lessons, the first one load-bearing:
- **A `*Morph` BASE's family ≠ the count of `*Morph`-named classes — size it by `extends <Base>`, never by the surface
  `class \w+Morph` grep.** `class \w+Morph` showed 16 icon leaves; `rg 'extends IconMorph'` showed **93** — the other **77 children
  had been renamed to `*Wdgt` long ago but still pointed `extends` at the un-renamed base** (69 in `src/icons/`, 6 `*ButtonWdgt` in
  `src/buttons/`, 2 `*MapIconWdgt` in `src/maps/`). The family is **atomic**: renaming the base forces touching all 93 `extends`, and
  the 16 leaves can't be coherently split from the base. The initial "17-class" scoping was a ~5× under-count; a cross-check
  `rg -c 'extends IconMorph' | wc -l` (returned "93", which looked like an artifact) caught it BEFORE planning — **always run that
  `extends`-cross-check when a base class is in scope, and reconfirm the real size with the owner.**
- **Predicted ~0 recapture (BATCH-5-shaped: label-shifting-but-not-photographed) — and ACTUAL was 0**, despite a ~95-file diff. The
  robust negatives that made it safe: **zero** of the 77 already-`*Wdgt` icons is named in ANY test (toolbar/window icons appear only
  as rendered glyphs, never by class name); **no test inspects an icon** (so the base name never reaches a photographed Object-Inspector
  hierarchy DIAGRAM — the one regime that draws the REAL `IconWdgt`); the only leaf in tests (`HeartIconMorph`, 4 dirs) is bare-`new`
  fixtures whose colloquial is never in a shot; and the base is abstract (the only direct instances are blank `new IconMorph(nil)`
  placeholder faces). A big diff with ZERO reference churn — a base rename can be the cheapest KIND while having the largest blast radius.
- **The boot-smoke is the load-order net for a base rename.** 93 children `extends IconWdgt` — a single missed `extends` → that child
  cannot load → boot error. `build_and_smoke.sh` (native + SWCanvas) is what proved all 93 resolve, BEFORE the suite. Treat a clean
  boot as the green light when renaming a heavily-subclassed base.
- **Mechanics:** 17 `git mv` + ONE combined 17-substitution `\b`-sweep (`s/\bIconMorph\b/IconWdgt/g` + the 16 leaves) over
  `$(rg -l 'IconMorph' src --glob '*.coffee')` — order-independent (tokens are `\b`-distinct; the file list is a harmless superset, the
  subs no-op elsewhere). The catch-all `rg -o '\w*IconMorph\w*' | sort -u` proved only the keepers survive: the **`create…IconMorph`
  factory-method names** (incl. `createWorldMapIconMorph` / `createUSAMapIconMorph` / `createPencil1IconMorph`, which have NO matching
  class) + the camelCase var `pencilIconMorph` — all `\b`-protected (no word boundary before the class token inside them), kept exactly
  like BATCH 6's `createNewRectangleMorph`. ZERO dangerous string-literals, ZERO `instanceof`/`findTopWidgetByClassNameOrClass`, ZERO
  `buildSystem` refs.
- **Two pre-existing `filename != classname` anomalies left untouched** (out of scope; already-`*Wdgt`): `src/icons/SliderNodeCalculatingNodeIconWdgt.coffee`
  declares `class SliderNodeIconWdgt`; `src/icons/DegreesConverterNodeIconWdgt.coffee` declares `class DegreesConverterIconWdgt`. Only
  their `extends` line changed; they build fine (the gate predates this batch).
- Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, ZERO reference recapture.** ~95 src files (17 renamed +
  ~78 `extends`/`new`-only) + 4 test dirs (content-only, test identifiers kept) + 4 visualisations regenerated + 3 docs
  (`MACRO-PATTERNS.md`, `author-macro-test/SKILL.md` class-noun refs). No test added/removed. The pre-recorded BATCH-7 Icon plan
  touch-list matched the live greps exactly — the only "surprise", the 93-vs-16 family size, was caught at planning by the `extends`
  cross-check (the "size a base by `extends`" lesson above). Remaining long-tail families (CircleBox/Slider, Color palette,
  Switch/Toggle, HandleMorph, …, `WorldMorph` last) follow one coherent family at a time.

**DONE (2026-06-16): BATCH 8 — the Box family (`BoxMorph`→`BoxWdgt` + `ClippingBoxMorph`/`MouseSensorMorph`/`PointerMorph` → `*Wdgt`;
re-point 3 children).** The thematic successor to BATCH 6's `RectangleWdgt` — finishing the basic box/rect primitives. A small, clean
inheritance family: renamed the base + its 3 `*Morph` children, re-pointed the 3 already-non-`*Morph` children (`GlassBoxBottomWdgt`,
`BasementWdgt`, `MenuHeader`); 5 `new` sites; 0 `instanceof`/`findTop`/string-literals. Lessons (mostly reaffirming Icon/Rectangle):
- **The `extends`-lens (Icon's lesson) paid off again:** `rg 'extends BoxMorph'` = 6 children (3 `*Morph` to rename + 3 non-`*Morph` to
  re-point), not just the 3 `*Morph` names — sized correctly up front; the 3 leaves have no further subclasses.
- **`\bBoxMorph\b` is safe vs the SEPARATE `CircleBoxMorph` family** (the slider base, `extends Widget`): `CircleBoxMorph` *contains* the
  substring `BoxMorph` but the word boundary protects it — verified untouched in src + tests + docs after the sweep (it is a later batch).
  (Likewise `\bBoxMorph\b` doesn't touch `ClippingBoxMorph`; its own `\bClippingBoxMorph\b` sub does.)
- **The recapture oracle surfaced BOTH label regimes again — 2 reds, one UNPREDICTED:** `macroHierarchyMenuHoverHighlightsExactSubtree`
  (predicted — the hierarchy MENU middle line `"a BoxMorph"`→`"a Box"`, strip regime, incl. its function-critical
  `getTextMenuItemFromMenuByPrefix … "a Box"` nav) AND `macroDuplicateComplexWidgetRidesHand` (UNPREDICTED — it opens an Object Inspector
  on a `BoxWdgt`, whose hierarchy DIAGRAM uses the REAL name → `BoxWdgt`, the third regime — exactly BATCH 6's
  `macroDuplicatedInspectorDrivesCopiedTargetOnly` case). Both EYEBALLED benign (menu reads `a Rectangle / a Box / a Panel`; the inspector
  diagram reads `TreeNode → Widget → BoxWdgt → this object` and the duplicate rode the hand fully-painted), recaptured dpr 1+2. Confirms
  (4th time): don't pre-classify; the byte-exact suite RED set IS the recapture set; ALWAYS eyeball each red to tell a benign label shift
  from a regression — here the unpredicted red was an inspector-on-the-renamed-class, the standard "any test that inspects the class
  re-baselines its diagram" case.
- KEPT (`\b`-protected): `createNewBoxMorph` / `createNewClippingBoxMorph` / `createPointerMorph` method names. LEFT: `buildSystem/OBSOLETE
  generateOverviewDoc.py` provenance.
- Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, 2 reference recaptures** (≈14 PNGs across both densities). 4
  source renames + 6 `extends` re-points + 5 `new` sites + 26 test files (content-only, identifiers kept) + 16 visualisations regenerated +
  2 docs (`MACRO-PATTERNS.md`, `author-macro-test/SKILL.md`). Plan `~/.claude/plans/batch8-box-family-rename.md`. Remaining long-tail
  families: Color palette, Switch/Toggle, HandleMorph, …, `WorldMorph` last.

**DONE (2026-06-16): BATCH 9 — the CircleBox/Slider family (`CircleBoxMorph`/`SliderMorph`/`SliderButtonMorph` → `*Wdgt`; re-point
`VideoScrubberWdgt`).** Completed the basic shape-primitive trio (`RectangleWdgt` B6, `BoxWdgt` B8, now `CircleBoxWdgt`) and finished a
deferred BATCH-4 slider lineage. `SliderMorph` is the scrollbar thumb (`ScrollPanelWdgt` hBar/vBar) + the `PromptMorph` popover slider —
heavily constructed but the rename is pixel-neutral. **THE headline lesson — a NEW recapture-independent failure mode:**
- **A rename's `Wdgt`-stripped colloquial can become a PREFIX of a SIBLING's, breaking `moveToItemStartingWith` nav strings — a HANG/crash,
  not a pixel-diff.** `SliderMorph`→`SliderWdgt` makes the menu label `"a Slider"`, which is a PREFIX of `"a SliderButton"` (the renamed
  `SliderButtonWdgt`'s stripped label). The OLD `"a SliderMorph"` was NOT a prefix of `"a SliderButtonMorph"` — the `Morph` suffix had
  ACCIDENTALLY disambiguated them. So 3 tests whose nav matched `"a SliderMorph"` broke once both became `"a Slider…"`: the prefix now
  matched the button (or nothing) → `moveToAndClick undefined` → `TypeError: …reading 'x'` (a shard STALL / an isolated crash), NOT a
  screenshot mismatch. **Whenever a rename makes one family member's stripped label a prefix of another's, audit every
  `moveToItemStartingWith`/`getTextMenuItemFromMenuByPrefix`/controller-target nav that used the longer old name.**
- **Two fix idioms (both already in the suite's vocabulary):** (a) for a **set-target** menu, pick the target BY MEANING —
  `menu.topWdgtSuchThat (item) -> item instanceof MenuItemWdgt and item.argumentToAction1 == theWidget` (the test author already used this
  for its other ambiguous leg) — used in `macroSliderTextSliderPatchCycle` + `macroSliderTextTwoWayPatchCycle`; (b) for an **ancestor
  hierarchy** menu (right-clicking the slider's KNOB lists `"a SliderButton ➜"` THEN `"a Slider ➜"`), use the disambiguating prefix
  `"a Slider ➜"` (the trailing ` ➜` excludes `"a SliderButton ➜"`) — used in `macroInspectorScrollbarUnplugged`. The ancestor-prefix
  usage that right-clicks the slider's TRACK (`macroSlidersControlTextMorph`) stayed unambiguous (the knob, a CHILD, isn't in the slider's
  own ancestor menu) — left as `"a Slider"`.
- **Diagnosis process:** a STALL on a JUST-EDITED test is a real hang to INVESTIGATE, not auto-dismiss as parallel-load contention —
  confirmed by an isolated `run-macro-test-headless` (it crashed with the TypeError, deterministically). (Genuine contention also appeared
  this batch — a dpr-2 shard `DISCONNECTED` with 0 played; re-run with `--shards=4` → clean 165/165. Tell them apart: a stall/crash naming
  ONE test that reproduces solo = real; a shard that played 0/DISCONNECTED = infra.)
- **Recapture: ZERO — the batch is fully pixel-neutral** (sliders/scrollbars render identically; every nav menu CLOSES before each
  screenshot; no test inspects-and-photographs a slider). The owner had accepted this as the "heaviest recapture" family; in fact the cost
  was entirely the 3 nav-ambiguity fixes, not reference churn. (So "heaviest recapture" was wrong — but the suite, run + solo, was still the
  oracle: it surfaced the hang.)
- **Plural-boundary gotcha bit src COMMENTS** (`SliderMorphs`/`CircleBoxMorphs`/`SliderButtonMorphs`) — the `\bFooMorph\b` sweep skipped
  them; caught by the `rg -o '\w*FooMorph\w*' | sort -u` catch-all, fixed with a `(s?)` pass. Also fixed a drawn-label-in-COMMENT
  (`MacroToolkit` "a Slider ➜") the class-sweep over-converted, and a pre-existing stale `"a TextMorph"` in `author-macro-test/SKILL.md`.
- KEPT (`\b`-protected): `createNewSliderMorph` / `createNewCircleBoxMorph` method names. LEFT: OBSOLETE-script provenance.
- Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, ZERO reference recapture.** 3 renames + 1 `extends` re-point +
  ~36 src refs; ~36 test files (content-only, identifiers kept) incl. 3 nav-ambiguity fixes + 19 visualisations regenerated + 3 docs. Plan
  `~/.claude/plans/batch9-circlebox-slider-rename.md`. Remaining long-tail families: Color palette, Switch/Toggle, HandleMorph, …,
  `WorldMorph` last.

**DONE (2026-06-16): BATCH 10 — the Color family (`ColorPaletteMorph`/`GrayPaletteMorph`/`ColorPickerMorph` → `*Wdgt`).**
The cohesive, self-contained colour-picking UI: `Widget → ColorPaletteWdgt → GrayPaletteWdgt` + sibling `ColorPickerWdgt` (which
COMPOSES a `ColorPalette` + a `GrayPalette` + a feedback widget). The cleanest batch since BATCH 5 — a pixel-neutral identifier
swap with **0** nav-string edits and **0** hang risk. extends-lens: the ONLY subclass edge is `GrayPaletteMorph extends
ColorPaletteMorph` (both in-scope); nothing already-`*Wdgt` extends any of the three → **0 re-point children, 0 orphans** (contrast
Icon's 77). Src: ~17 refs, **0** string-literals, **0** `findTop…`, **1** `instanceof` (`ColorPickerMorph` at `MenuMorph:210`); the
5 `createNew*Morph` factory methods (`WorldMorph`) KEPT (`\b`-protected).
- **THE headline lesson — a rename can move pixels with NO label visibly changed, via a DEPENDENT menu's POSITION.** Two
  set-target tests (`macroTargetingHighlightsCandidateMorph`, `macroUniqueTargetAndPropertyAreStillPresented`) re-baselined even
  though the menus they photograph show only the CANDIDATES (`"a WorldMorph"`, `"a Rectangle"`) — never the palette's own name.
  Cause: the palette's CONTEXT menu (the parent), whose width derives from its now-shorter colloquial `"a ColorPalette"` (was
  `"a ColorPaletteMorph"` — menus strip `Wdgt`, not `Morph`), is narrower, so the selector menu that pops FROM it shifts ~11px. The
  menu CONTENT is identical (every `@assertTopMenuItemStrings`/`Count` passed); only its position moved. **So a "menu-strip
  recapture" can be INDIRECT — a layout knock-on of the shorter modern name, invisible at the label itself.**
- **Diagnosis when the RED shot shows no changed label: don't bless blind.** `run-macro-test-headless --dump-failures` + a PIL
  diff (committed-ref vs live-dump) localized every changed pixel to the menu bbox (e.g. `image_1 x[239..350] y[331..372]`; the
  highlighted rectangle + desktop byte-identical), proving a benign position shift, not a regression — THEN captured.
- **The theoretical prefix-collision was NEVER exercised (so no BATCH-9 hang).** After stripping, `"a ColorPalette"` IS a prefix
  of `"a ColorPaletteNodeCreatorButton"` (the patch-programming button) — but NO test navigates by the palette label (set-target
  tests navigate to the TARGET, e.g. `"a Rectangle"`/`"a WorldMorph"`; the picker is found BY MEANING via `instanceof
  ColorPickerWdgt`). Confirms the converse of the BATCH-9 rule: a prefix collision only bites if a test actually navigates by the
  shorter prefix — audit, but don't pre-emptively rewrite navs that don't use it.
- **A string-literal class lookup lived in a TEST, not src.** `macroCanMoveAndResizeColorPaletteMorph` does
  `@findTopWidgetByClassNameOrClass "ColorPaletteMorph"` — the `\b`-sweep correctly rewrote the quoted string to
  `"ColorPaletteWdgt"` (resolves to the renamed global). Its test-NAME identifier `macroCanMoveAndResizeColorPaletteMorph` is
  `\b`-protected (preceded by `Resize`) and KEPT, per convention.
- KEPT (`\b`-distinct, untouched): the lookalikes `ColorPaletteNodeCreatorButtonWdgt` / `GrayscalePaletteNodeCreatorButtonWdgt` /
  `ColorPalettePatchProgrammingIcon*` — the sweep updated only their `new ColorPaletteWdgt` refs, never their names.
- Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots; exactly 2 tests recaptured (their menu-bearing
  shots, both densities).** 3 renames + ~17 src refs; 9 test files (content-only, identifiers kept) + 9 visualisations regenerated
  + 2 docs (`MACRO-PATTERNS.md`, `author-macro-test/SKILL.md`). Plan `~/.claude/plans/batch10-color-family-rename.md`. Remaining
  long-tail families: Switch/Toggle, HandleMorph, …, `WorldMorph` last.

**DONE (2026-06-16): BATCH 11 — the Switch/Toggle/Radio button family (`SwitchButtonMorph`/`ToggleButtonMorph`/`RadioButtonsHolderMorph`
→ `*Wdgt`; re-point `VideoPlayPauseToggle`).** Finished the toggle-state button lineage DEFERRED from BATCH 4. Family:
`Widget → SwitchButtonWdgt → ToggleButtonWdgt → VideoPlayPauseToggle` + standalone `Widget → RadioButtonsHolderWdgt` (holds toggle
buttons). **The cleanest batch yet — pixel-neutral, ZERO recapture.** ~21 src refs, **0** string-literals, **0** `findTop…`, **0**
`instanceof`, **0** `createNew*` methods; the 3 tokens mutually `\b`-distinct.
- **THE headline lesson — usage BREADTH ≠ recapture; only a DRAWN or NAVIGATED class name recaptures.** These toggles are heavily-used
  CHROME — every `WindowWdgt` builds a `.collapseUncollapseSwitchButton`, the `InspectorWdgt` builds 4 (`new ToggleButtonMorph` for
  show methods/fields/inherited/own-props), plus `ReconfigurablePaintWdgt`'s 4 tool buttons, `ErrorsLogViewerMorph` pause, `BasementWdgt`,
  `MenusHelper` — so they RENDER in many tests (inspector shots, window shots, …). Yet recapture was ZERO: rendering is pixel-neutral
  (a rename changes no pixels), the class names appear in NO nav string, and they're icon-buttons (no class-name label in the UI) that no
  test inspects-by-name. **Don't equate "this class is everywhere on screen" with "expensive recapture" — measure the DRAWN/NAVIGATED
  surface, not the construction/ render surface.** (Only 1 test even references the family: `macroWindowsEmptyCollapsingUncollapsing`'s
  METADATA — intent prose + a `"SwitchButtonMorph"` keyword tag — swept to `…Wdgt`, not a macro command or drawn label.)
- KEPT (`\b`-protected, substrings not class names): the factory method `createSwitchButtonMorph` (`Widget`, `MenusHelper`) and property
  names `collapseUncollapseSwitchButton` / `internalExternalSwitchButton` / `resetSwitchButton` — per the `createNew*Morph`-keep convention.
- EXCLUDED `EditableMarkMorph` — it `extends UpperRightTriangleIconicButton`, a SEPARATE lineage (a later batch with
  `UpperRightTriangleIconicButton`), NOT the SwitchButton lineage.
- Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, ZERO reference recapture.** 3 renames + 1 `extends` re-point
  + ~21 src refs; 1 test file (metadata-only) + its visualisation regenerated; 0 docs (none mentioned the classes). Plan
  `~/.claude/plans/batch11-switch-toggle-radio-rename.md`. Remaining long-tail families: `HandleMorph`, the
  `UpperRightTriangleIconicButton`/`EditableMarkMorph` mark lineage, Canvas/Pen, Caret/Blinker, the layout `*Morph`s, the Fizzytiles app,
  `MenuMorph`/`PromptMorph` (high-recapture), …, `WorldMorph` last.

**DONE (2026-06-16): BATCH 12 — `HandleMorph` → `HandleWdgt` (the resize/move handle).** `extends Widget`, leaf (0 subclasses). The
single most widely-USED widget renamed so far — the `@resizer` of every `WindowWdgt`/`InspectorWdgt`/`BasementWdgt`, the world's
temporary resize/move handles, and 8 layout-element handles in `Widget`; ~11 `instanceof HandleMorph` layout/drag-exclusion checks across
the framework. **Yet ZERO recapture.** ~41 src refs, **0** string-literals, **0** `findTop…`; the factory `createNewHandle` has no `Morph`
token (untouched).
- **THE headline lesson — a THIRD, decisive confirmation that usage BREADTH ≠ recapture** (cf. BATCH 11). HandleMorph touches **40 test
  files** (17 executable: `instanceof`/`new`/the by-meaning resize helper `world.topWdgtSuchThat (i)-> i instanceof HandleMorph and
  i.type==…`; 23 metadata prose/tags), and dozens of tests literally DRAG a handle to resize — but the suite went RED on **none**. The
  pre-execution guess was "moderate inspector-DIAGRAM recapture" (handle-bearing hierarchy shots); WRONG — the inspector tests photograph
  the inspector's RENDER and property EDITS, not a hierarchy diagram that names a handle, and a handle is never inspected-by-name. **A
  class can be everywhere — constructed, dragged, type-checked framework-wide — and still ZERO-recapture, because recapture keys ONLY on a
  DRAWN label / NAVIGATED nav string / inspected-in-shot DIAGRAM, never the construction/render/drag surface.** Predicting a count remains
  futile (4th time the byte-exact suite overturned the guess) — settle the KIND, run the oracle.
- 0 `"a Handle…"` nav strings → no strips, no prefix-hang. Test-NAME identifiers (`macroHandleMorphIsItselfResizable`) `\b`-protected (preceded
  by `macro`) and KEPT.
- Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, ZERO reference recapture.** 1 rename + ~41 src refs; 40 test
  files swept (content-only, identifiers kept) + 24 visualisations regenerated + 3 docs (`MACRO-PATTERNS.md`, `macros/CLAUDE.md`,
  `author-macro-test/SKILL.md`). Plan `~/.claude/plans/batch12-handle-rename.md`. Remaining long-tail families: the
  `UpperRightTriangleIconicButton`/`EditableMarkMorph` mark lineage, Canvas/Pen, Caret/Blinker, the layout `*Morph`s, the Fizzytiles app,
  `MenuMorph`/`PromptMorph` (high-recapture), …, `WorldMorph` last.

**DONE (2026-06-16): BATCH 13 — the Caret/Blinker family (`BlinkerMorph`/`CaretMorph` → `*Wdgt`).** The text-cursor lineage:
`Widget → BlinkerWdgt → CaretWdgt` (`CaretMorph` is the only `BlinkerMorph` subclass; 0 orphans). `CaretMorph` = the text caret,
constructed once (`WorldMorph:2184 @caret = new CaretMorph …`), reached via the `world.caret` PROPERTY (not the class token — untouched) +
~7 `instanceof CaretMorph` layout/drag/hit-test exclusion checks. ~15 src refs, **0** string-literals, **0** `findTop…`, **0** `createNew*`.
**ZERO recapture** — a 4th zero-churn rename in the last five batches (only Color moved pixels, indirectly).
- **Reinforces the usage-breadth-≠-recapture lesson from the caret-RENDER angle.** The caret is DRAWN (the blinking cursor) and exercised in
  24 text-editing test files — typing, selection, multi-click word/line select, scroll-into-view — every one photographing the text+caret
  RENDER. Yet ZERO re-baselined: the rename is pixel-neutral and the class name `CaretMorph`/`BlinkerMorph` is never a drawn label, a nav
  string, or an inspected-in-shot diagram. (Even a class that is literally on screen as a blinking glyph in dozens of shots recaptures
  nothing, as long as its NAME isn't what's drawn.) 0 `"a Caret…"/"a Blinker…"` nav strings → no strips, no hang.
- The caret is determinism-/timing-sensitive (blink + the multi-click event-time selection logic, see DETERMINISM.md) but the rename is a
  pure identifier swap — no behaviour change; the suite stayed byte-exact at dpr 1 + 2 + WebKit. Test-NAME identifiers
  (`macroDoubleAndTripleClickThroughCaretMorph`, `macroCaret*`) `\b`-protected (preceded by a word char) and KEPT.
- Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, ZERO reference recapture.** 2 renames + ~15 src refs; 24 test
  files swept (content-only, identifiers kept) + 16 visualisations regenerated + 2 docs (`MACRO-PATTERNS.md`, `author-macro-test/SKILL.md`).
  Plan `~/.claude/plans/batch13-caret-blinker-rename.md`. Remaining long-tail families: the
  `UpperRightTriangleIconicButton`/`EditableMarkMorph` mark lineage, Canvas/Pen, the layout `*Morph`s, the Fizzytiles app,
  `MenuMorph`/`PromptMorph` (high-recapture), …, `WorldMorph` last.

**DONE (2026-06-16): BATCH 14 — the layout-helpers trio (`LayoutElementAdderOrDropletMorph`/`LayoutSpacerMorph`/`StackElementsSizeAdjustingMorph`
→ `*Wdgt`).** Three independent layout-machinery widgets (each `extends Widget`; 0 subclasses, 0 orphans; a coherent "layout helpers"
group): the spring (`LayoutSpacerWdgt`), the stack cell divider/reproportioner (`StackElementsSizeAdjustingWdgt`, the heaviest at ~27 refs,
deep in stack-layout code), and the add-element/droplet affordance (`LayoutElementAdderOrDropletWdgt`). ~48 src refs, **0** string-literals,
**0** `findTop…`; KEPT (`\b`-protected): `createNewStackElementsSizeAdjustingMorph` + `createNewLayoutElementAdderOrDropletMorph` (`WorldMorph`).
**ZERO recapture** — these are dragged (spacer/divider) and laid out in 8 layout test files (several via `Widget.setupTestScreen1`), all
pixel-neutral; 0 nav strings, no inspected-in-shot name. (By BATCH 14 the usage-breadth-≠-recapture rule is routine — construction/drag/
render/layout surfaces never recapture; only a drawn/navigated/inspected NAME does. Five of the last six batches were zero-churn.)
Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, ZERO recapture.** 3 renames + ~48 src refs; 8 test files
(content-only) + 5 visualisations regenerated + 2 docs (`MACRO-PATTERNS.md`, `author-macro-test/SKILL.md`). Plan
`~/.claude/plans/batch14-layout-helpers-rename.md`. Remaining long-tail families: the `UpperRightTriangleIconicButton`/`EditableMarkMorph`
mark lineage, Canvas/Pen, the Fizzytiles app, `ErrorsLogViewerMorph`, `MenuMorph`/`PromptMorph`/`CodePromptMorph` (high-recapture), …,
`WorldMorph` last.

**DONE (2026-06-16): BATCH 15 — Canvas + Pen (`CanvasMorph` → `CanvasWdgt` (base, re-point 6 children) + `PenMorph` → `PenWdgt`).** Two
drawing widgets: `CanvasMorph` (a `PanelWdgt` subclass — the raw-canvas base) and the standalone turtle `PenMorph` (`extends Widget`, 0
children). ~15 src refs, **0** string-literals, **0** `findTop…`. **ZERO recapture.**
- **A base-with-children (Icon-family pattern), correctly sized via the extends-lens.** `CanvasMorph` has **6 subclasses** —
  `VideoPlayerCanvasWdgt`, `StretchableCanvasWdgt`, `CanvasGlassTopWdgt`, `RasterImageWdgt` (4 already-`*Wdgt`) + `FridgeMagnetsCanvasMorph`,
  `FridgeMagnets3DCanvasMorph` (2 Fizzytiles `*Morph`). The single `\bCanvasMorph\b` sweep does it all: renames the base AND flips all 6
  `extends CanvasMorph` → `extends CanvasWdgt` — and is `\b`-SAFE against the `…CanvasMorph` SUFFIX in `FridgeMagnets[3D]CanvasMorph` (preceded
  by a word char), so those child NAMES are untouched. POST-SWEEP CHECK: `rg 'extends CanvasWdgt' src` = 6 (a base rename's whole risk is a
  missed `extends` — verify the count explicitly).
- **Scope decision (settled): deferred the whole Fizzytiles app to its own next batch.** The 2 Fizzytiles `*Morph` canvases keep their names
  here, just re-pointed to `extends CanvasWdgt` (a transient `*Morph`-extends-`*Wdgt` — harmless, the build keys off the literal `extends`
  token). The next batch renames all 5 Fizzytiles `*Morph` together. Avoids splitting the Fizzytiles app or renaming a class twice.
- KEPT (out of scope, like method names): the property `underlyingCanvasMorph` (`ReconfigurablePaintWdgt`, `CanvasGlassTopWdgt`) and
  `createNewPenMorph`/`createNewCanvas`/`createPencil*IconMorph` factory methods (all `\b`-protected or no `Morph` token).
- Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, ZERO recapture.** 2 renames + 6 `extends` re-points + ~15 src
  refs; 2 test files (`macroSierpinskiInCanvas`) + 1 visualisation regenerated + 3 docs. Plan `~/.claude/plans/batch15-canvas-pen-rename.md`.
  Remaining long-tail families: the Fizzytiles app (`Fridge*` + `FizzytilesCodeMorph`, incl. the 2 already-re-pointed canvas children), the
  `UpperRightTriangleIconicButton`/`EditableMarkMorph` mark lineage, `ErrorsLogViewerMorph`, `MenuMorph`/`PromptMorph`/`CodePromptMorph`
  (high-recapture), …, `WorldMorph` last.

**DONE (2026-06-16): BATCH 16 — the Fizzytiles app (`FridgeMorph`/`FridgeMagnetsMorph`/`FridgeMagnetsCanvasMorph`/`FridgeMagnets3DCanvasMorph`/`FizzytilesCodeMorph`
→ `*Wdgt`).** Five leaf classes of the self-contained fridge-magnets demo app (`extends` PanelWdgt / Widget / CanvasWdgt / CanvasWdgt /
TextWdgt — no internal hierarchy, 0 subclasses); finishes what BATCH 15 started (which re-pointed the 2 canvas children to `CanvasWdgt`).
~13 src refs, **0** string-literals, **0** `findTop…`, **0** test files. **ZERO recapture (guaranteed).**
- **The cleanest possible batch — EXPERIMENTAL, homepage-stripped, untested.** Every `src/fizzytiles/` file carries
  `# this file is excluded from the fizzygum homepage build` (+ `if Automator?` guards), so `--homepage` strips it (the homepage build never
  contains these — renaming can't affect it) and no SystemTest references the app → no possible recapture. **The verification net for such a
  batch is the NORMAL `build_and_smoke`/`build_and_test` (which DO compile fizzytiles), NOT the homepage boot leg** (which never sees it).
- 5 tokens mutually `\b`-distinct (`FridgeMorph` ⊄ `FridgeMagnets…`; `FridgeMagnetsMorph` ⊄ `FridgeMagnetsCanvasMorph`; etc.) — one sweep,
  order-irrelevant. No `createNew*Morph` methods for these.
- Result: **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, ZERO recapture.** 5 renames + ~13 src refs; 0 test files, 0
  docs. Plan `~/.claude/plans/batch16-fizzytiles-app-rename.md`. Remaining long-tail families: the
  `UpperRightTriangleIconicButton`/`EditableMarkMorph` mark lineage, `ErrorsLogViewerMorph`, `MenuMorph`/`PromptMorph`/`CodePromptMorph`
  (high-recapture), …, `WorldMorph` last.

**DONE (2026-06-16): BATCH 17 — `EditableMarkMorph` → `EditableMarkWdgt`.** The editable-mark leaf (the deferred-from-BATCH-4 "mark";
`extends UpperRightTriangleIconicButton`, 0 subclasses). 5 src refs (its decl + 4 `new EditableMarkMorph` in `apps/ReconfigurablePaintWdgt`),
**0** string-literals, **0** test files → **ZERO recapture.** Its base `UpperRightTriangleIconicButton` is already non-`*Morph` — an
INCONSISTENT name (neither `Morph` nor `Wdgt`), but NOT a `*Morph` rename target, so left as-is (candidate for a future "non-`Morph`-suffixed
names" consistency pass, separate from this `*Morph`→`*Wdgt` phase). **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, ZERO
recapture.** 1 rename + 5 src refs; 0 tests, 0 docs. Plan `~/.claude/plans/batch17-editablemark-rename.md`. Remaining long-tail families:
`ErrorsLogViewerMorph`, `MenuMorph`/`PromptMorph`/`CodePromptMorph` (high-recapture), …, `WorldMorph` last. (Non-`*Morph` naming-consistency
leftovers like `UpperRightTriangleIconicButton` are a SEPARATE possible pass.)

**DONE (2026-06-17): BATCH 18 — `ErrorsLogViewerMorph` → `ErrorsLogViewerWdgt`.** The errors-log viewer dev tool (`extends Widget`,
0 subclasses) — pops up only when injected code fails to compile, constructed inside a `WindowWdgt` by `WorldMorph.createErrorConsole`.
**The most trivial rename of the phase: exactly 2 src refs** — the `class` decl + ONE `new ErrorsLogViewerMorph` in `WorldMorph.coffee:437`;
**0** string-literals, **0** `findTop…`/`instanceof`/`createNew*`, **0** test files, **0** nav strings → **ZERO recapture** (predicted; suite
confirmed). The lowercase local `errorsLogViewerMorph` (case-distinct — `\bErrorsLogViewerMorph\b` won't match it) and the property `textMorph`
left as-is (separate non-`Morph` consistency pass). Unlike BATCH 16's experimental fizzytiles, this class DOES ship in the homepage build, so the
`--homepage` boot leg was a relevant net (boots clean). **165/165 (Chrome dpr 1 + 2, WebKit), `--homepage` builds + boots, ZERO recapture.**
1 rename + 2 src refs; 0 tests, 0 docs. Plan `~/.claude/plans/batch18-errorslogviewer-rename.md`. Remaining long-tail: `MenuMorph`/`PromptMorph`/
`CodePromptMorph` (high-recapture — the first big-recapture batch since RectangleMorph), …, `WorldMorph` last. (Non-`*Morph` naming-consistency
leftovers like `UpperRightTriangleIconicButton` remain a SEPARATE possible pass.)

> **★ THE `*Morph`→`*Wdgt` RENAME PHASE IS COMPLETE (2026-06-17, BATCH 20 = `WorldMorph`).** `rg 'class \w+Morph' src` = NONE; no `*Morph.coffee`
> files remain; the all-`*Wdgt` end state is reached. The ONLY remaining `*Morph` substrings live inside `\b`-protected COMPOUND identifiers that
> were deliberately kept throughout (method names `createNew*Morph` / `getHierarchyMenuMorphs` / `hierarchyMenuMorphs`, property `underlyingCanvasMorph`,
> lowercase locals `errorsLogViewerMorph`, and the already-non-`Morph`-but-inconsistent `UpperRightTriangleIconicButton`) — a SEPARATE, optional
> "naming-consistency" pass, NOT part of this now-closed class-RENAME phase.

**DONE (2026-06-17): BATCH 19 — the Menu/Prompt family (`MenuMorph`→`MenuWdgt`, `PromptMorph`→`PromptWdgt`, `CodePromptMorph`→`CodePromptWdgt`).**
The first genuinely high-recapture family since RectangleMorph (B6) — but it collapsed to ONE recapture. Hierarchy: `MenuWdgt extends PopUpWdgt`
(base, in `src/basic-widgets/menu-system/`) with 2 subclasses — `PromptWdgt` + the already-`*Wdgt` `SaveShortcutPromptWdgt` (its `extends`
re-pointed, not renamed); `PromptWdgt extends MenuWdgt`; `CodePromptWdgt extends Widget` (standalone despite the name). 75 MenuMorph src hits/23
files (incl. 4 active `instanceof`), 7 PromptMorph, 2 CodePromptMorph; **0** string-literals, **0** `findTop`. KEPT (`\b`-protected compound
identifiers, out of scope): the `getHierarchyMenuMorphs`/`hierarchyMenuMorphs` methods.
- **Behavioral nav fix (1 test):** `macroDuplicatedMenuAutoPinsOnDesktop` drills a hierarchy menu by `"a MenuMorph ➜"`; after the rename the drawn
  label strips to `"a Menu ➜"`. **Collision-safe** (the B9 hazard): that menu also holds `"a MenuItem ➜"`, and `"a Menu ➜"` diverges at index 6
  (space vs `I`) so it is NOT a prefix — the `➜` disambiguates (same shape as B9's `"a Slider ➜"`). No menu/prompt `@assertTopMenuItemStrings` exist
  (only `"a WorldMorph ➜"` — BATCH 20).
- **Recapture = exactly 1 test** (`macroRightClickClosesDownstreamSubMenus`, image_2 only) — the same test that recaptured in B4 for MenuItemMorph;
  it photographs a hierarchy submenu whose item shifted `"a MenuMorph"`→`"a Menu"` (eyeballed: only that label changed; the now-narrower submenu
  reveals a touch more of the menu behind it — benign). The duplicate-menu test photographs world menus (ACTION items, no class name) → nav-fix only,
  ZERO recapture; a prompt draws its caller-set TITLE, not the class name; no inspector test names a menu/prompt in a diagram. **So the "high-recapture
  family" collapsed to 1: breadth (menus drawn everywhere) again ≠ recapture — only the ONE photographed hierarchy-menu-that-names-a-menu re-baselined.**
- **Test-side mechanic:** blind `\b`-perl over test `.js` (3 tokens) handled tags + prose + comments, THEN a targeted strip of the drawn-label nav
  `"a MenuWdgt ➜"`→`"a Menu ➜"` (the sweep over-converts the drawn label to the class name; strip it back to the menu form). 30 test dirs
  content-touched + viz regenerated. **165/165 (Chrome dpr 1+2, WebKit), `--homepage` builds + boots, 1 recapture.** Plan
  `~/.claude/plans/batch19-menu-prompt-rename.md`. Remaining: **`WorldMorph` LAST** (the `window.world` singleton; `"a WorldMorph ➜"` is drawn AND
  asserted via `@assertTopMenuItemStrings` in several tests → genuine recapture).

**DONE (2026-06-17): BATCH 20 — `WorldMorph` → `WorldWdgt` (THE FINALE — closes the rename phase).** The global singleton root (`window.world`;
`class WorldWdgt extends PanelWdgt`, **0 subclasses** — a LEAF, just the widest: **330 src hits / 128 files** incl. 6 `instanceof` + the
`new WorldWdgt` singleton instantiation at `src/boot/globalFunctions.coffee:402`). 0 compound identifiers (catch-all = bare token only). Two
NON-`*.coffee` refs the `src/*.coffee` sweep misses, handled separately: the `src/index.html:34` COMMENT, and the one in-class string-literal
`WorldWdgt.coffee:1813 if eachMorphClass != "WorldWdgt"` (compares a global class-NAME string in `fullDestroyChildren`; the `\b`-perl converts it
correctly — `WorldWdgt` still ends in `Wdgt` so the reset-exclusion still fires; verified context). `buildSystem/OBSOLETE generateOverviewDoc.py`'s
path string left as-is (dead/historical, not run by the build).
- **Two DISTINCT drawn surfaces, BOTH benign (eyeballed):** (1) a menu HEADER/title shows the widget's FULL class name → `WorldMorph`→`WorldWdgt`
  (does NOT strip `Wdgt`; e.g. `macroBasicWorldMenuAndBubble`'s world-menu header); (2) hierarchy/targeting menu ITEMS strip `Wdgt` →
  `"a WorldMorph"`→`"a World"` (e.g. `macroTargetingHighlightsCandidateMorph`'s "choose target:" item). **The header-keeps-full-name vs
  item-strips-Wdgt split is the key WorldMorph-specific lesson** (earlier batches only ever exercised the item surface).
- **Behavioral test fixes:** 3× `@assertTopMenuItemStrings ["a WorldMorph ➜"]`→`["a World ➜"]` + 1× nav `"a WorldMorph"`→`"a World"` (collision-safe:
  no other `"a World…"` label). Proof the assert strips were right: the 2 assert-tests-with-screenshots went RED only on the SCREENSHOT (not the
  assertion), and the assert-ONLY `macroLonelySliderTargetsWorldOnly` wasn't RED at all.
- **Recapture = 14 tests** (the largest of the phase) — every test photographing the world-menu header, a targeting/hierarchy item naming the world, or
  an inspector diagram; all the two benign surfaces above. (`macroRightClickClosesDownstreamSubMenus` recaptured AGAIN — its header
  `WorldMorph`→`WorldWdgt` — after B19 had recaptured its submenu item.) Bulk-recaptured via the SAFE BATCHED flow (clean ALL SWCanvas refs → build
  once → `--capture-ref` ×28 → build once → verify) instead of 14× the single-test script (which rebuilds ~3× each) — replicating its
  clean-rebuild-FIRST / publish-rebuild-BEFORE-verify bracketing across all 14 at once.
- **Test-side mechanic:** blind `\b`-perl over test `.js` (tags+prose+comments), THEN strip ONLY the QUOTED drawn-label forms anchored on the quote
  `s/(["'])a WorldWdgt/${1}a World/` — leaving the class.method ref `WorldWdgt.createNewHandle` intact (a `via WorldWdgt` false-positive an
  UNanchored strip would have broken). 28 test dirs content/ref-touched + viz regenerated.
- **165/165 (Chrome dpr 1+2, WebKit), `--homepage` builds + boots, 14 recaptures.** Plan `~/.claude/plans/batch20-worldmorph-rename.md`. **★ With this,
  the `*Morph`→`*Wdgt` rename phase is COMPLETE** (see the banner above the BATCH-19 entry).

**DONE (2026-06-17): BATCH 21 — the naming-consistency pass (CLASS-ECHO scope).** SEPARATE from the (closed) class-RENAME phase: renames the
`\b`-protected COMPOUND identifiers that ECHO a now-renamed class, while DELIBERATELY LEAVING the generic `Morph`=widget vocabulary (`brokenMorph`,
`theMorph`, `faceMorph`, `allMorphsInStructure`, `*Morph` params — hundreds; the Morphic heritage noun). Owner picked the "class-echo" scope (of 4:
just-the-class / class-echo / full-eradication / skip). Plan `~/.claude/plans/batch21-naming-consistency-classecho.md`.
- **Renamed (all src-only → ZERO recapture):** (1) ~31 `create…Morph` factory/creator methods → `…Wdgt` — the def + every `\b` ref + its `"…"` string
  menu-action move together (a `\bNAME\b` sub matches inside quotes too) — incl. 16 `create…IconMorph` (echo `…IconWdgt`) + the 2 mid-`Morph`
  `create…PaletteMorphInWindow`; (2) 3 named echoes `underlyingCanvasMorph`/`errorsLogViewerMorph`/`pencilIconMorph` → `…Wdgt`; (3) the inconsistent
  CLASS lineage `UpperRightTriangle`→`UpperRightTriangleWdgt` + `UpperRightTriangleIconicButton`→`…Wdgt` (the BASE was INCLUDED beyond the owner's
  literal "the IconicButton class" — else a `*Wdgt` would `extend` a non-`Wdgt`; `EditableMarkWdgt` re-pointed; `UpperRightTriangleAppearance` LEFT —
  it's a drawing-object `*Appearance`, not a widget).
- **KEY: NOT a blind `create\w*Morph` sweep** — that wrongly catches the 3 GENERICS where `Morph` is a preposition-object
  (`createInAWhileIfHandStillContainedInMorph`, `createBubbleHelpIfHandStillOnMorph`, `makeHandleSolidWithParentMorph`); used an EXPLICIT per-name list.
  Generics + `getHierarchyMenuMorphs`/`hierarchyMenuMorphs` (generic "menu morphs") KEPT.
- **The trap (unlike class renames):** factory methods are invoked BY STRING (`menu.addMenuItem "rectangle", true, @, "createNewRectangleMorph"`), so
  def & action must stay in sync — the per-name `\b` sweep does both at once; `build_and_smoke` does NOT click menus so it can't catch a desync,
  `build_and_test` (demo/creation tests click "rectangle"/"box"/…) IS the net. Tests reference NO factory by name (they click LABELS) → src-only
  EXCEPT test PROSE (provenance/intent/comments in 3 tests named `createNewRectangleMorph`/`createHeartIconMorph`) — swept for consistency + 3 viz
  regenerated (content-only; the rename-phase's src-only sweeps had missed test prose).
- **165/165 (Chrome dpr 1+2, WebKit), `--homepage` builds + boots, ZERO recapture.** Remaining (optional, deferred): the FULL-eradication scope — the
  generic `Morph`=widget vocabulary (hundreds of identifiers across ~every file incl. serialization/mixin internals).

**DONE (2026-06-17): BATCH 22 — generic `Morph`=widget vocabulary → `Widget` (SRC-VOCABULARY scope).** Owner chose "src vocabulary only" (of
full/src-only/stop). **269 distinct generic identifiers / 849 occurrences** across ~every src file → `Widget` (full word — `eachWidget`/`theWidget`
already existed; NOT the class-name abbreviation `Wdgt`). Plan `~/.claude/plans/batch22-generic-vocabulary-eradication.md`.
- **Method:** a per-line **sentinel-protected substring sweep** (`s/Morph/Widget/g`, so `Morphs`→`Widgets`), protecting (`\b`-bounded) `Morphic`,
  `theWordMorph` (+ collision with the existing `theWordWidget`), the quoted `"Morph"` suffix-detection/strip logic strings, ALL capitalized standalone
  `*Morph` comment class-refs (`TriggerMorph`/`StringMorph`/`TextMorph`/…), and `macro*`/`SystemTest_*` test-name refs. A uniform substring sweep keeps
  def+all-callsites in sync. Pre-fixed a latent class-echo bug found during sizing: `new BouncerMorph` ×5 (class is `BouncerWdgt`) → `new BouncerWdgt`.
- **Harness (`Automator-and-test-harness-src/`):** targeted `\b` rename of ONLY the 4 mechanism props the 6 Automator commands set
  (`hidingOfMorphs…`/`alignmentOfMorphIDsMechanism`/`alignIDsOfNextMorphsInSystemTests` → `…Widgets…`) so they stay in sync with the src readers;
  KEPT the 6 Automator command CLASS names → **165 test files untouched**.
- **THE TRAP that bit (RED suite → fixed):** the test macros **call ~11 src widget methods/properties BY NAME** (`plausibleTargetAndDestinationMorphs`
  ×21, `findFirstLooseMorph`, `textMorph`, `subMorphsMergedFullBounds`, `representsAMorph`, `addMorphSpecificMenuEntries`, `addHighlightingMorphs`,
  `getHierarchyMenuMorphs`, `rightMorph`, `leftMorph`, `basicMorphPadding`) — de-facto test-facing API. Renaming them broke ~9 tests + STALLED one; the
  cross-repo residual sweep (test sources, excl. assets/test-names) located them; **reverted exactly those in src** (kept their `Morph` names, like the
  Automator commands) → suite green. LESSON: "src vocabulary only, tests untouched" still requires keeping any src method a test macro calls by name —
  enumerate them with `rg -oI '\b\w*Morphs?\w*\b' tests -g'!**/automation-assets/**'` minus test-names/commands.
- **Recapture = exactly 1** (`macroDuplicateComplexWidgetRidesHand`, image_1+2): it photographs the Object-Inspector method list, which introspects +
  displays method names → the renamed `choiceOfMorphToBePicked`→`choiceOfWidgetToBePicked` shows there (benign; eyeballed). Generic-vocab renames are
  otherwise invisible (identifiers, not drawn) — only the inspector's live introspection surfaces one.
- **165/165 (Chrome dpr 1+2, WebKit), `--homepage` builds + boots, 1 recapture.** **What remains in src** (deliberately kept): the ~11 test-API
  `*Morph` methods, the prep-object generics (`makeHandleSolidWithParentMorph`/`create…In/OnMorph`), `theWordMorph`+logic strings, capitalized
  comment class-refs, `Morphic`. Fully removing the test-API `*Morph` methods + the 6 Automator command names would require touching the 165 tests —
  the "full eradication incl. test-facing API" the owner declined.

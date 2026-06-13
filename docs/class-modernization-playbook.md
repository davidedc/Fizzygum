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

**Lists & text panes (`ListMorph`, `TextMorph2`/`SimplePlainTextWdgt`)**
- **Select a list row by SCROLLING to it first**, not by clicking a by-text match. A row that sorts below the
  visible area exists as a (clipped, off-pane) morph; clicking its `topLeft` lands outside the pane and selects
  the *wrong* visible row (this silently no-op'd a `save`). Scroll with the toolkit idiom
  (`@calculateVertBarMovement list.vBar, idx, list.elements.length` → `@syntheticEventsMouseMovePressDragRelease…`)
  then click the now-visible row at `row.topLeft() + (10,2)`.
- A **`TextMorph2`'s context menu can't be opened by a synthetic right-click** in a macro. So its "do all" /
  evaluation menu, soft-wrap toggle, etc. are not reachable that way — call the underlying method directly
  (`detailText.softWrapOn()`, `textBox.toggleSoftWrap()`) or use the dedicated UI affordance (see "eval" below).
- A `SimplePlainTextWdgt` detail/console pane **defaults to NON-wrapping** (long lines scroll horizontally).
  Call `detailText.softWrapOn()` (sets the scroll panel's `isTextLineWrapping`) to make it wrap, then container
  resizes re-wrap it.
- To focus an editable pane for typing without a click, call `pane.edit()` (`world.edit`) — the established
  idiom; never click an *empty* old `TextMorph` (its `slotAt` crashes under SWCanvas).

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

The convention is "don't mass-rename existing `*Morph` files", so modernize deliberately, one collaborator at a
time, when there's a reason (a duplicate to delete, a class surfacing in tests). Candidates surfaced during the
inspector arc: `ListMorph`, `TextMorph`/`TextMorph2`, `RectangleMorph`, `SimpleButtonMorph`. Also a deferred
**menu/method consolidation**: `inspect`/`spawnInspector` (naked, now windowed) and `inspect2`/`spawnInspector2`
both build `InspectorWdgt` — they can be collapsed into one entry point.

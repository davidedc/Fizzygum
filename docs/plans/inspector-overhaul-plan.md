# Inspector overhaul: one tool, a row of inspectors, each one a small composed widget

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
**STATUS: IN EXECUTION since 2026-11-24** (authored and spiked that day; §6's table says which units have
landed, and each landed unit's paragraph says what it corrected here). Every fact in §1 and §7 was read off the tree at
Fizzygum `f7aed9e0` / Fizzygum-tests `e78dc3e50` (471 SystemTests) on 2026-11-24. Line numbers drift:
the quoted method or symbol name is authoritative, so grep it fresh before trusting a number.
**The design was spiked the same day against the unmodified dev build** (§4): six page probes, no
source change. What the spike measured is stated as measured; what it did not reach is stated as a
step to verify.

## Mandate

**Replace** the object inspector and the class inspector with ONE tool, and leave nothing of the old
shape behind:

- one door ("Inspect"), one window: a **row of inspectors**, each on one subject, each subject chosen
  in the inspector to its left;
- the inspector **decomposed** into small widgets that each do one thing (a member list, a member
  editor, a band of controls), composed by the layout mechanisms the tree already has, with **no
  layout method of their own**;
- the object-versus-class difference held in **one place** (a member reference), not in a subclass
  of the whole tool.

This is a transformation, not a second tool beside the first: `ClassInspectorWdgt`, the breadcrumb,
the inspector's ~200 lines of hand-written layout, its own resizer and the hooks that only it defined
are **deleted**. Test churn, reference recapture and saved-world compatibility are not constraints
(owner, 2026-11-24).

---

## 0. Orientation

### 0.1 What Fizzygum is (one paragraph, then read the CLAUDE.md files)

Fizzygum is a CoffeeScript "web operating system" drawn on one HTML5 canvas, descended from
Morphic.js. Every class's source text ships in the page and is compiled in the browser; there is no
module system (every class is a global; load order is found by scanning source text for `extends X`
anywhere on a line, a comment's included, and for a class-body field line `name: new X`; a `new X`
inside a method is not read and needs no edge). The **inspector** is its live editing tool: it lists an object's members, shows a
member's CoffeeScript source, and saves an edit into the running object or class.

Workspace routing: the umbrella `CLAUDE.md` at `/Users/davidedellacasa/code/Fizzygum-all/`, then
`Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md`. Always use the `fg` wrapper by absolute path:
`/Users/davidedellacasa/code/Fizzygum-all/fg`. Never `./fg`, never a hand-chained build.

### 0.2 Series history, and why this plan exists now

- **`docs/archive/inspector-read-only-subjects-plan.md`** (COMPLETE, 2026-08): an inspector on a
  value that cannot service an edit became a read-only inspector. Its capability query
  (`_subjectIsEditable`) and the naming service (`Utils.colloquialNameOf`) survive here.
- **Many small inspector arcs since** (class edits through the meta-object and recorded for a
  snapshot; a class's prototype always opened in the class inspector; indexed subjects listed in
  order and bounded at 1000 items; the code pane's undo history per member; run rows in the code
  pane). Their behaviour is what "parity" means in this plan; their tests are listed in §7.1.
- **`docs/plans/smalltalk-talk-2026-11-plan.md`** (AUTHORED 2026-11-07, the owner's plan for a talk
  on 2026-11-25; none of its classes was built). Its U3 proposed a moldable "explorer" built
  **beside** the inspector, embedding a whole `InspectorWdgt` as one view and a whole
  `ClassInspectorWdgt` as a method's source view, with a real pager as a stretch goal. The owner
  reviewed that on 2026-11-24 and chose the opposite on three points, which this plan executes:
  1. **one tool**, replacing the inspector, since the churn the talk plan avoided is not a cost;
  2. **decompose, do not embed**;
  3. **the pager is the core**, not a stretch.

  This plan supersedes the talk plan's U3 and its decisions D3 and D4. The talk plan's U4 (class
  comment, protocols, senders, implementors) and U6 (other domains) are **not** in this plan; §11
  says how they sit on what this plan builds.

### 0.3 ⭐ Critical reframes: read these before anything else

1. **Today's inspector is already a two-column pager with the columns welded together.** Its body is
   a member list and, beside it, the code of the member selected in the list. Unweld them and the
   list is one inspector (subject: the object) and the code is the next (subject: one member of it).
   A double-click on a row, which today opens a separate windowless inspector at the pointer, is the
   same gesture with a different subject (the member's value). So the classic inspector, the class
   inspector and drilling are one mechanism: **choosing a row gives the next inspector its subject.**
2. **The object/class split is a property of a MEMBER, not of the tool.** `ClassInspectorWdgt` (117
   lines) overrides exactly: the four edit steps (add, save, rename, remove), the one notification,
   what a field's text is, editability, and the code receiver. All eight are questions about "this
   member of this holder". They move to a small `MemberRef` and its subclass `ClassMemberRef`; the
   widgets no longer know which kind they show.
3. **The layout needs no code.** A horizontal **division stack** with draggable splitters already
   exists (`StackLayoutEngine`, `DivisionStackLayoutSpec`, `StackElementsSizeAdjustingWdgt`) and is
   used today only by a `WidgetFactory` demo. The spike (§4) built the whole target shape from it:
   the row of inspectors, each inspector's bands, each band's controls. No `_reLayout`, no
   `_reLayoutChildren`, no read of a child's laid-out pixels.
4. **A member's editor is a `CodeAreaWdgt`.** The tree already has the family "a code area above a
   footer band of buttons" (`CodeAreaWdgt`: the script window, the code prompt, the console, the
   error log). The member editor joins that family instead of re-assembling it.
5. **Horizontal scrolling of the row is NOT free, and is not built.** As a viewport's content the row
   kept its own height when the window grew (measured, §4). The row instead **widens its window**
   when a drill does not fit. Nothing is ever dropped from the left, so no inspector with unsaved
   typing disappears on its own.
6. **Nothing may hold a closure or an off-tree widget.** A widget field holding a function makes the
   world unsaveable (`ListWdgt`'s header says so of its own format predicates), and
   `serialization-duplication-reference.md` §2 says "an owner keeps no widget OFF its tree". Every
   connection in this plan is a method NAME on a target, and every inspector is a child of its row.
7. **A split has two controls, both always there** (owner, 2026-11-24). The existing splitter is a
   6 px strip with a small dark bar on it: no finger's target (the house rule is 44 × 44 for every
   chrome target, drawn as big as it is, `visual-design-system.md` §4.2), and its mark reads as a
   scroll bar's thumb beside a list's bar. So:
   - **the divider**, the mouse's control: slightly thicker, showing grip dots;
   - **the split button**, the finger's control: 44 × 44, at the left end of the header of the
     inspector on the divider's right, a double arrow with a finger icon so it says what to do.
   Both are present whatever pointer is in use, because some devices have both. Nothing in the
   layout reads the pointer, so "one geometry serves mouse and finger alike" (`Theme.coffee`,
   program ruling G1) holds as it stands (§5.10).

### 0.4 Owner decisions

Ask the owner the OPEN ones at the start. On "go", use the defaults.

| # | Decision | Status |
|---|---|---|
| D1 | One tool: "Inspect" opens the row of inspectors; the old inspectors are deleted | **LOCKED** (owner, 2026-11-24) |
| D2 | Decompose into member list + member editor; the object/class split in a member reference | **LOCKED** (owner, 2026-11-24) |
| D3 | The row (pager) is the core shape | **LOCKED** (owner, 2026-11-24) |
| D4 | A drill that does not fit **widens the window**, no further than the desktop's right edge; past that the inspectors narrow. Nothing is dropped from the left | OPEN. Default: as stated (the alternative, horizontal scroll, needs new viewport code: §10) |
| D5 | **One class chip per inspector** (an object's class; a class's superclass) in the header, in place of the whole breadcrumb. Walking up the chain is one click per class, each a new inspector | OPEN. Default: yes. A wrapping breadcrumb cannot be a stack band (its height would depend on its width), and each class is its own inspector anyway |
| D6 | The four filter toggles (Methods, Fields, Inherited, Own props only) keep their meaning and their look, in the member list | OPEN. Default: unchanged. The parked BACKLOG question on what "Inherited" hides stays parked |
| D7 | **Rename… and Remove sit with Add… under the member list**; Save sits under the editor | OPEN. Default: yes. The list then owns every gesture that changes the member set, and no inspector has to refresh another |
| D8 | **No resizer of its own for a row with no window.** Its two hooks and their readers are deleted (§6 U2.2) | OPEN. Default: yes. Nothing in the product makes a windowless inspector any more (a drill used to); one picked out of its window resizes by the halo, as any widget |
| D9 | Starting window **760 × 480** (today 560 × 410) | OPEN. Default: yes (two inspectors at their least widths, §4) |
| D10 | One window title for every subject: **"Inspector — <name>"** (today "Object Inspector — …" / "Class Inspector — …") | OPEN. Default: yes |
| D11 | **A split's two controls, both always present** (owner, 2026-11-24, final): the divider slightly thicker with grip dots, for a mouse; and a 44 × 44 button in the header of the inspector on its right, a double arrow with a finger icon, for a finger. Both are there at all times, because some devices have both a mouse and a touch screen (§5.10) | **LOCKED**. Open details, each with a default: the divider's width (12 px) and dot field (2 × 4); the finger icon, which does not exist yet and is drawn with the owner (U3b) |
| D12 | Second phase (U4): the first object-list views, **Children**, **Instances**, **Subclasses**, and the view chooser they need | OPEN. Default: build. Senders, implementors and protocols stay out (§11) |
| D13 | Commits | Per house rule, **ask before every commit and push**. At the start, ask whether this plan gets a standing grant ("commit and continue while gates pass; ask before push") |
| D14 | The dotted divider is the look of **every** division stack's splitter (the halo's layout adjusters, "Edit layout"), not a look of the inspector's own | OPEN. Default: yes: one splitter class, one look. It recaptures the tests that show a splitter (16 test sources name a division stack) |
| D15 | **Duplicate…** beside Add… Rename… Remove (owner, 2026-11-24): a copy of the selected member under a new name | **LOCKED** for members. Open detail, default: a duplicated field that holds an object holds the SAME object (a copy of the slot, not of the thing). Duplicating a class waits for class-level verbs (§11) |
| D16 | Packages, categories, families of members, and comments (owner, 2026-11-24) | **Wanted; a plan of its own, authored AFTER this plan's switch (U2) has landed** (owner, 2026-11-24). §11 says how they sit on what this plan builds, and what is missing underneath |

### 0.5 Cold-execution protocol (read and run in this order)

1. **Orient:** `/Users/davidedellacasa/code/Fizzygum-all/fg status`. If `Fizzygum` or
   `Fizzygum-tests` is dirty with another arc's work, **stop and ask**: this plan touches `src/`,
   `buildSystem/`, both repos' docs and about fifty files of the tests repo.
2. **Read**, in this order: the three CLAUDE.md files; then in `Fizzygum/docs/architecture/`:
   - `widget-authoring-guidelines.md` (whole; every new class here is a widget class);
   - `layout.md` §2 (settle tiers), §4.2 (the layout-spec family), §8 (the rulebook);
   - `lint-and-static-checks.md` §3 (the gate table) and §3b (what a finding means: an invariant is
     fixed, a convention is met, a budget may be raised or lowered with a dated reason);
   - `serialization-duplication-reference.md` §2, §4a, §5, §9, §12;
   - `visual-design-system.md` §4.1 (seams), §4.3 (toggle, chip, footer band), §5;
   - `build-and-packaging.md` §2 (the lazy door);
   - `constructor-and-parameter-conventions.md`; `immutable-value-classes.md` (for `MemberRef`).
   Then `Fizzygum/src/macros/CLAUDE.md` and, in the tests repo, `DETERMINISM.md` §1–§2.
3. **Read the code this plan moves**, whole: `src/meta-tools/InspectorWdgt.coffee`,
   `src/meta-tools/ClassInspectorWdgt.coffee`, `src/CodeAreaWdgt.coffee`, `src/ScriptWdgt.coffee`,
   `src/ListWdgt.coffee`, `src/StackLayoutEngine.coffee`, `src/DivisionStackLayoutSpec.coffee`,
   `src/PromptButtonsRowWdgt.coffee` (the house's model of a small row widget).
4. **Ask the owner** the OPEN decisions of §0.4.
5. **Run the units of §6 in order.** Each ends with its gate, then the commit per D13, then a tick in
   §6's table. Nothing is pushed without approval.
6. **A failing reference is never "benign churn" unseen.** This plan changes every inspector
   screenshot on purpose (§7.1 predicts which); anything outside that set gets a pixel look first
   (`fg diffpage <test>`).
7. **Long operations** (`fg presuite`, `fg gauntlet`, `fg recapture`) run in the background with a
   log; peek at `/tmp/fg-<cmd>.verdict` every ~5 minutes, never in a polling loop. Never pipe a
   gating `fg` call through `tail` or `grep`.
8. **A gate finding is answered by its class** (`lint-and-static-checks.md` §3b). A shape is never
   bent to fit a count: where the right shape needs a budget moved, move it in the same change with
   a dated reason beside the number.

---

## 1. Current state (verified 2026-11-24)

This section describes the tree as it stood when the plan was authored. U1 has since moved the edit
steps and a member's text out of the two inspectors into `MemberRef` / `ClassMemberRef` (§6 U1,
"Landed"); everything else here stands until U2.

### 1.1 The two inspectors

`src/meta-tools/` is the lazy part **`meta-tools`** (`buildSystem/parts.json`: `eager: false`, no
`requires`). It holds four classes: `InspectorWdgt`, `ClassInspectorWdgt`, `BreadcrumbSeparatorWdgt`,
`ConsoleWdgt`.

**`InspectorWdgt extends ClippingWdgt`** (950 lines). Its one subject is the field `inspectedObject`
(named so on purpose: `target` elsewhere means dataflow or dispatch). Top to bottom it shows:

| Band | Built by | Laid out by |
|---|---|---|
| breadcrumb: "Class" caption, a `ChipWdgt` per class of the subject's chain, a `BreadcrumbSeparatorWdgt` between two chips | `_buildAndConnectBreadcrumb`, `_classChainLinks` | `_breadcrumbIn` (wraps to rows), `_layOutBreadcrumb` |
| toggles: four `LabelledToggleWdgt` (Methods, Fields, Inherited, Own props only) | `_buildAndConnectChildrenNoSettle`, `_buildAndConnectOwnPropsOnlyToggle` | `_layOutTogglesIn` |
| body: member list (`ListWdgt` in member mode) and code pane (`TextAreaWdgt`) | `_buildAndConnectMemberList`, inline | `_bandsIn`, `_reLayout` |
| footer: Add… Rename… Remove at the left, Save at the right; absent on a read-only subject | `_buildAndConnectEditRow` | `FooterBandLayout._arrange` |

Its parts, by line (grep the names):

- **Layout (lines ~626–826, about 200 lines):** `_reLayout`, `_bandsIn`, `_seamRects`,
  `_breadcrumbIn`, `_layOutBreadcrumb`, `_layOutTogglesIn`, `_toggles`, `_footerLeftButtons`,
  `_footerRightButtons`, `_clearPaneLook`. All of it is deleted by this plan.
- **Member set:** `_subjectsItemsAndNames` (an indexed subject's items first, at most
  `@MOST_ITEMS_LISTED` = 1000), `@_isAnIndex`, `_emptyPaneText` (says a cut list in the code pane),
  `_filteredMemberNames`, `memberFactsOf` (kind tag "fn"/"var", dimmed unless the subject's own class
  declares the member), `_subjectsClassPrototype`.
- **Filter:** `showingFields`/`showingMethods` (true), `showingInherited`/`showingOwnPropsOnly`
  (false), `toggleShowing*`, `_reflectFiltersOnToggles`, `_refilterMembers` (rebuilds only the list).
- **Selection:** `selectionFromList(name)` loads `_paneTextOfMember(name)` into the code pane; a
  reload of the member last loaded (`lastLoadedMember`) is one step of the pane's undo history, a
  load of another member forgets the history. `constructor` is shown, never editable.
  `inspectMemberValue(name)` (a row's double-click) opens a **windowless** inspector on the member's
  value at the pointer.
- **Edits:** `save`, `addProperty`/`addPropertyPopout`, `renameProperty`/`renamePropertyPopout`,
  `removeProperty`, each built on one overridable step: `applyPropertyEdit`,
  `_applyPropertyAddition`, `_applyPropertyRename`, `_applyPropertyRemoval`, and ending in
  `_notifyOfEdit`. Guards: `_subjectIsEditable`, `_selectedMemberCanBeRenamedOrRemoved`,
  `_refusesAsANewMemberName`.
- **Doors and hooks:** `@inspectorClassFor(value)` (a class's prototype gets the class inspector),
  `openClassInspector` (a chip's action; opens a new window), `codeReceiver`, `readsClassMemberMaps:
  true`, and for the windowless case a `HandleWdgt` resizer with `bottomRightCornerReachedBy` and
  `footerRightClearance`.

**`ClassInspectorWdgt extends InspectorWdgt`** (117 lines). Its subject is a class's PROTOTYPE. It
overrides: `_editClassMember`/`_removeClassMember` (the meta-object's edit plus its registry record),
`_notifyOfEdit` (`world.noteCodeChanged()`), `_subjectIsEditable` (`isAClassPrototype`),
`codeReceiver` (none), `_sourceForFieldMember`, `_applyPropertyRemoval`, `_applyPropertyRename`,
`_applyPropertyAddition`, `colloquialName`, `_buildAndConnectOwnPropsOnlyToggle` (builds none),
`applyPropertyEdit`.

### 1.2 What the inspectors stand on (all core unless noted)

| Thing | Where | What this plan needs of it |
|---|---|---|
| The door | `Widget.inspect` (:4961) → `Widget.spawnInspector(inspectee)` (:4997): `isAvailable "meta-tools"`, `whenAllLoaded ["meta-tools"]`, the reflective layer (synchronous when loaded), `new (InspectorWdgt.inspectorClassFor inspectee) inspectee`, `world.openFrameWith inspector, (new Point 560, 410), …` | Stays; builds the row instead. The class is named bare INSIDE the `whenAllLoaded` callback, which `check-part-edges.js` reads as the guard |
| Menu rows | "Inspect" in the widget context menu (`Widget.coffee:5163`), the desktop menu (`WorldWdgt.coffee:3504`), Dev tools (`MenusHelper.coffee:15`); "Inspect selection" in a text's run rows (`TextWdgt.coffee:655` → `inspectSelection` → `spawnInspector result`) | Unchanged |
| Instance edit protocol | `Widget.injectProperty(name, txt)` (:4273), `addOwnProperty(name)` (:4448), `removeOwnProperty(name)` (:4456), `renameOwnProperty(old, new)` (:4461), `sourceChanged()` (:3980); `Widget.keptSourceOf(fn)` (static, :4353) | Called from `MemberRef` |
| Class edit protocol | `Class.applyMemberEdit(name, source)`, `removeMember(name)`, `definesMember(name)`, statics `Class.memberRecordOf(fn)`, `Class.fieldRecordHolds(proto, name, value)`, `Class.refuseTheConstructor`; `nonStaticPropertiesSources`; `WorldWdgt.noteCodeChanged()` (:232) | Called from `ClassMemberRef` |
| The change list | `SourceEditsRegistry.recordInstanceEdit(widget, name, source)` (:33), `recordClassEdit(proto, name, source)` (:45), `recordClassMemberRemoval(proto, name)` (:56) | Called from the two refs |
| Saving typed code | `Widget._savingTypedCode(applyTypedCode)` (:5761): a compile error is reported beside the hand, not thrown; answers whether it saved | Called by the editor |
| Code receiver | `TextWdgt._codeReceiver` (:689) climbs parents to the nearest one that DEFINES `codeReceiver` | The editor defines it |
| Reflective layer | `Deserializer._needsTheReflectiveLayer` (:253) reads `classNamed(record.class)?.prototype.readsClassMemberMaps is true` for every record of a file | Each new widget class that shows member source declares it |
| Globals | `isAClassPrototype(value)` (`boot/globalFunctions.coffee:122`), `classNamed(name)` (:56), `allClassFunctions()` (:107), `reflectiveLayerIsLoaded()` (:357), `ensureReflectiveLayerLoaded()` (:353) | As is |
| Naming | `Utils.colloquialNameOf(value)` (`Utils.coffee:41`): asks the value, derives from its class when it cannot answer, never asks a class's prototype | The header title |
| Member list | `ListWdgt` (194 lines): `new ListWdgt elements, target:, action:, doubleClickAction:, memberFactsQuery:`. It dispatches the row's LABEL to `target[action]`. In member mode its rows are `MemberRowWdgt`, as wide as the list | U1–U3 use it as is; U4 extends it (§6) |
| Code area family | `CodeAreaWdgt extends Widget` (106 lines): `_newCodeArea`, `_buildEditableCodeAreaNoSettle(text)` (fields `tempPromptEntryField`, `textWidget`; modified-content indicator; notifies `textContentModified`/`textContentUnmodified`), `_footerLeftButtons`/`_footerRightButtons`, `_seamRects`, `_layOutOwnContents`, `SeamRulesAppearance`. `ScriptWdgt` is the model of a subclass with a Save | The editor's base |
| Footer band geometry | `FooterBandLayout` (class-side): `topIn`, `ruleIn`, `buttonBoundsIn`, `_arrange(host, lefts, rights)`; reads `host.footerRightClearance?()`. Hosts: `CodeAreaWdgt`, `BinWdgt`, `InspectorWdgt` | Stays for `CodeAreaWdgt` and `BinWdgt` |
| Controls | `ChipWdgt` (built only by the inspector today), `LabelledToggleWdgt`, `SimpleButtonWdgt`: `new X target:, action:, face:, arg1:, primary:, current:`. A button dispatches `target[action](button, subjectOfMenu, arg1, arg2)`: `arg1` arrives in the THIRD slot (`openClassInspector: (ignored, ignored2, className)`) | As is |
| Division stack | `holder.add child, layoutSpec: child.divisionBox()` (a horizontal row) or `child.divisionBox('y')`; `child.setMinAndMaxBoundsAndSpreadability(min, desired, spreadability)`; `DivisionStackLayoutSpec.SPREADABILITY_NONE` (10) / `_SPACERS` (1e8); `crossAlign` 'stretch' \| 'center' …; `StackElementsSizeAdjustingWdgt` (the splitter, a division element itself); `Widget.getRecursiveMinDim()` | The whole layout |
| Window | `world.openFrameWith(content, extent, position)` returns the `FrameWdgt`; `FrameWdgt.isMyContents(w)` (:1120); `Widget.isFreeFloating()` (:1006); `Widget.setExtent(point)` (:2566) | Widening |
| Taking a part out | `Widget.pickUp()` (the hierarchy menu's "Pick up"); `_reactToChildRemoved(child)` on the holder | A picked-out inspector |
| Theme | `inspectorBodyFill`, `inspectorPaneFill` (transparent), `inspectorPaneStroke`, `inspectorRuleWidth`, `breadcrumbBandHeight` 44, `breadcrumbInset` 12, `toggleBandHeight` 48, `toggleBandInset` 12, `toggleBandGap` 8, `footerBandHeight` 52, `footerInset` 12, `footerGap` 8, `seamRule`; fonts `buttonLabel`, `code`; ink `codeText`, `codePanePadding` | §5.9 |

### 1.3 Who else names the inspector

The complete touch-lists are §7: 32 SystemTests drive it, nine toolkit verbs locate its parts, about
twenty rig and tooling scripts reach into it, six build gates count something of it, and about
fifteen architecture docs describe it.

---

## 2. Why things are shaped this way

- **One class with a subclass, because the tool predates composition.** The inspector descends from
  Morphic.js's `InspectorMorph`: one widget that builds its panes and lays them out by hand. The
  class inspector was added as a subclass overriding the edit steps, which was the smallest change at
  the time. The redesign of 2026-10 re-drew its bands (breadcrumb, toggles, seams) inside the same
  hand layout, and added the gate `check-relayout-bounds-first.js` after that hand layout produced a
  one-frame lag flake at dpr 2.
- **The windowless inspector and its resizer exist because a drill opened one.** `inspectMemberValue`
  drops a bare inspector at the pointer, so the inspector had to size and resize itself with no
  window; `bottomRightCornerReachedBy` and `footerRightClearance` exist so a scroll bar and the footer
  keep clear of that resizer. Only `InspectorWdgt` defines either hook.
- **Member edits go through named steps so a snapshot can replay them.** A class edit must go through
  the meta-object and be recorded (`SourceEditsRegistry`), or the class's store of sources and its
  prototype disagree. That is why a class's prototype is never edited as an object, and why
  `inspectorClassFor` exists: so no door can open a prototype in the object inspector. In this plan
  the same rule is one line in `MemberRef.of`.
- **Lists dispatch method names, never closures,** so a copy of an inspector is driven by its own
  list and a saved world holds no function.
- **Dev tools live in a lazy part** so production's first load does not pay for them; the door awaits
  the part and names the class under the await.

---

## 3. The distilled argument

- **Why this shape.** "Choosing a row gives the next inspector its subject" is the whole tool. The
  object inspector is two inspectors (object, member). The class inspector is the same two with a
  class's prototype as the first subject. A drill is a third inspector. A class's chip is a choice
  like any other. Later, a list of senders or of a widget's children is one more view whose rows are
  subjects. One mechanism replaces: the welded body, the subclass, the separate window per class,
  the windowless inspector per drill.
- **Why it costs less code, not more.** Deleted: ~200 lines of layout, the breadcrumb and its wrap
  arithmetic, `ClassInspectorWdgt`, `BreadcrumbSeparatorWdgt`, the resizer and two hooks with their
  three readers, `inspectorClassFor`, `openClassInspector`, `lastLoadedMember`. Added: a row (~80
  lines), a band (~50), a split grip (~35), and glue. The member logic moves, it is not rewritten.
- **Why now, and why the earlier plan did not do it.** The talk plan kept the old inspector to spare
  sixteen tests before a deadline. With no deadline and churn accepted, keeping it would leave two
  tools that overlap.
- **Why it is safe to attempt.** The risky parts are the edit semantics and the layout. U1 moves the
  edit semantics alone, under the 32 existing tests and the serialization rig, with no pixel change.
  The layout was built whole in the spike with no error, integer bounds, and a forced re-layout that
  moved nothing.

---

## 4. The spike (2026-11-24): what was measured

Six Puppeteer probes drove the unmodified dev build's harness page and assembled the target from
existing classes at runtime. They live in `Fizzygum-tests/.scratch/inspector-overhaul-spike/`
(gitignored: present on the authoring machine, possibly absent on yours; nothing below depends on
them). Two pages there show pictures: **`how-it-will-look.html`**, a storyboard of the target
driven by real clicks on a working page-script prototype (one frame per gesture, every part
numbered, and a table of what is final and what is not: read this one first), and `review.html`,
the raw probes.

| Question | Result |
|---|---|
| Can the row be a horizontal division stack? | **Yes, with no layout code.** Three panes with splitters as a window's content: panes divide the width, re-divide when the window is resized, a real mouse drag on a splitter moves the split, a pane added or destroyed at runtime re-divides the rest. No console error, integer bounds, and `row._invalidateLayout(); world.recalculateLayouts()` moved nothing |
| Can an inspector be a vertical division stack of bands? | **Yes.** Header band, toggles band, member list, footer band, each a division element with `divisionBox('y')`; the list takes the slack |
| Can a band be a horizontal division stack of its controls? | **Yes**, with three facts to respect: (1) **a band is as tall as its tallest child**, not as tall as its own box says (a container with division children derives its box from them, `Widget._getRecursiveStackDim`), so a band's GAPS are made as tall as the band; (2) controls are fixed at their own `preferredExtent()` with `crossAlign` 'center'; (3) a **spring** takes the slack |
| ⚠ Hazard | **A division row whose children's desired widths sum to 0 divides by zero** (`StackLayoutEngine.arrange`, the third regime: `desC / totDesired`), and the always-on guard prints `NON_FINITE_GEOMETRY`. Reached by a spring of desired width 0 added first to an empty band. A spring's desired width is **1** (as `LayoutSpacerWdgt`'s is), and a band's children are added inside ONE settle |
| ⚠ Hazard | **A widget's `minimumExtent` defaults to 5 × 5** (`Widget.coffee:426`) and clamps what a stack hands it: a 1 px rule came out 5 px tall. A piece that must go below 5 px sets `minimumExtent` to 0 × 0 in its own constructor, as `StackElementsSizeAdjustingWdgt` and `LayoutSpacerWdgt` do |
| What is an inspector's least width? | **Derived**: the widest band's controls and gaps. With today's four toggles and their 12/8 px gaps the member list's least width is **352 px**; an editor with only Save is far narrower, so the editor's code area carries a floor of its own (§5.6) |
| Does it look like today's inspector? | Yes, band for band (`review.html`, picture 1) |
| Horizontal scrolling of the row | **Not free.** As a `ViewportWdgt`'s content, a 1100 × 300 row stayed 300 tall when the window's content box grew to 391. Tracking the viewport's height while owning its width is a new arrange in the viewport family: rejected (§10) |
| Widening instead | `row.getRecursiveMinDim().x` against `row.width()` gives the missing width; `frame.setExtent` by that much re-divided the row with every inspector at its least width |
| A copy | `window.fullCopy()` of a two-pane row: a separate tree; resizing the copy moved nothing in the original |
| Taking an inspector out by dragging | Not by a plain drag: a press on a pane's header float-drags the whole window (a child of a non-panel climbs to its parent, `Widget.grabsToParentWhenDragged`). The existing route is the hierarchy menu's "Pick up" (`Widget.pickUp`), which works on any part |
| Splitter by finger, as it is | The strip is 6 px wide (347..353). A touch drag pressed on it moves the split at once, with no press-and-hold (`ownsDragsStartingOnMe`). A press at 346 or 353 drags the window. The mouse is the same. **Not a finger's target** (the 44 rule, `visual-design-system.md` §4.2: every chrome target is at least 44 × 44, and a target that must be big is drawn big) |
| A split a finger can move, variant A: **the splitter 44 px wide** | Its division box set to 44 after construction. A touch drag pressed anywhere across the strip (374..418) moved the split by the drag; a press 2 px outside did nothing. Cost: a 44 px plate down the whole height between two inspectors (`review.html`, picture 6) |
| A split a finger can move, variant C: **a 44 × 44 grip in the header band** | A piece of layout chrome at the left end of the second inspector's header, relaying its drag to the thin splitter beside it (`splitter.nonFloatDragging` with the start point shifted by the distance between the two). A touch drag pressed anywhere on the grip (379..422) moved the split by the drag; the thin strip still works too. Cost: 44 px of the header band, which is 44 tall already; no content width (`review.html`, picture 7). **The plan's default** |
| The two controls, as the owner ruled them (`how-it-will-look.html`, the parts frame, frame 8 and "By finger") | Both in one window. **The divider:** the splitter 12 px wide, drawing a 2 × 4 field of the house's grip dots (2 px squares on a 6 px pitch, `FrameStripAppearance`'s) in place of its bar; a 70 px mouse drag on it moved the split 60 px. **The split button:** the header grip of the earlier variant C beside that divider; a real touch tap chose the member and a 70 px touch drag on the button moved the split 60 px |
| ⚠ For any probe that presses | World coordinates are CANVAS coordinates. The harness page has a 25 px strip above the canvas, so a `page.mouse` or `page.touchscreen` point is the world point plus the canvas's offset in the page (`document.getElementById('world').getBoundingClientRect()`). A probe that forgets it presses the window's title bar |
| Too narrow | When a band's controls do not fit, the stack's first regime shrinks every element in proportion (today's inspector keeps them at size and clips them at its right edge) |

---

## 5. The target

### 5.1 The classes

All in `src/meta-tools/` (the lazy `meta-tools` part), one class per file, file name = class name.

| Class | Is | Replaces | Size (guide) |
|---|---|---|---|
| `InspectorRowWdgt extends Widget` | the window's content: inspectors side by side, a splitter between two; where a choice goes; widening | the welded body, `inspectMemberValue`'s windowless inspector, `openClassInspector`'s window | ~90 lines |
| `InspectorWdgt extends Widget` | ONE subject (`inspectedObject`): a header band (name, class chip), a chooser band when the subject has more than one view, the view | `InspectorWdgt` (rewritten whole), `ClassInspectorWdgt` | ~120 |
| `MemberListWdgt extends Widget` | the view of an object's members: filter toggles, the list, Add… Rename… Remove | the inspector's left half | ~230, moved |
| `MemberEditorWdgt extends CodeAreaWdgt` | the view of one member: its source or value as text, Save | the inspector's right half | ~80 |
| `MemberRef` | one member of one holder: its text (`shownText`) and the edit steps | the inspector's edit hooks and `_paneTextOfMember` | ~130, moved (U1) |
| `ClassMemberRef extends MemberRef` | a member of a class's prototype | `ClassInspectorWdgt`'s overrides | ~80, moved |
| `BandWdgt extends Widget` | a row of controls at their own sizes, gaps between them, one spring, a rule along one edge | `_layOutTogglesIn`, the header's and the footer's hand placement | ~50 |
| `BandSpaceWdgt extends Widget` | a band's gap or spring: paints nothing, may be 0 wide, hidden from the hierarchy menu | (new) | ~20 |
| `SplitGripWdgt extends LayoutChromeWdgt` | a 44 × 44 grip in an inspector's header that drags the splitter before that inspector: the touch-sized way to move a split (D11) | (new) | ~35 |

Deleted files: `ClassInspectorWdgt.coffee`, `BreadcrumbSeparatorWdgt.coffee`.

### 5.2 The picture

```
window  "Inspector — analog clock"
┌──────────────────────────────────┬─┬──────────────────────────────────────┐
│ analog clock     [AnalogClockWdgt]│ │[↔] drawSecondsHand                   │  header band (44); [↔] = split grip
├──────────────────────────────────┤ ├──────────────────────────────────────┤
│ [Methods][Fields][Inherited][Own…]│s│ (context, squareDim) ->              │  toggles band (48) │ code
├──────────────────────────────────┤p│   @_drawHand context, squareDim, …   │
│ fn  _drawHand                     │l│                                      │
│ fn  drawSecondsHand   ← selected  │i│                                      │
│ var dateLastTicked                │t│                                      │
├──────────────────────────────────┤ ├──────────────────────────────────────┤
│ [Add…][Duplicate…][Rename…][Remove]│ │                              [Save] │  footer band (52)
└──────────────────────────────────┴─┴──────────────────────────────────────┘
  InspectorWdgt on the clock            InspectorWdgt on MemberRef(clock, "drawSecondsHand")
  view: MemberListWdgt                  view: MemberEditorWdgt
```

Structure (each indent is "a child of", `x`/`y` is the division axis):

```
InspectorRowWdgt                         paints the body fill; x-division
  InspectorWdgt                          y-division
    BandWdgt (header)                    x-division: 12, title, SPRING, chip, 12; rule at bottom
    [BandWdgt (chooser)]                 only when the subject has more than one view (U4)
    MemberListWdgt                       y-division, takes the slack
      BandWdgt (toggles)                 rule at bottom
      ListWdgt                           takes the slack
      [BandWdgt (cut notice)]            only when an indexed subject's items are cut
      [BandWdgt (footer)]                only when the subject is editable; rule at top
  StackElementsSizeAdjustingWdgt         the splitter
  InspectorWdgt
    BandWdgt (header)                    x-division: SplitGripWdgt, 8, title, SPRING[, chip], 12
    MemberEditorWdgt                     a CodeAreaWdgt: code area + its own footer band
```

### 5.3 The three protocols

**(a) A choice.** Anything in an inspector that stands for another subject tells the row:

```coffee
  # WHERE A CHOICE GOES. `chooser` -- an inspector, or a view inside one -- chose `subject`: the
  # inspector right of the chooser's shows it. Chosen again, the subject already there is RELOADED
  # (a member's editor takes its saved text back, as one step of its undo history); any other
  # subject replaces it, and everything further right goes either way. No subject (undefined) only
  # removes what stands right of the chooser: its view no longer stands for anything.
  #   A chooser in no row -- an inspector or a view a person picked out of its window -- opens the
  # subject in a window of its own.
  @showChoice: (chooser, subject) ->
```

Who calls it: a member row's click (`MemberListWdgt.selectionFromList(name)` → the `MemberRef`), a
row's double-click (`inspectMemberValue(name)` → the member's VALUE, when it is an object), the
header's chip (→ the class's prototype), a re-filter or a view switch (→ undefined), and in U4 a row
of an object list.

"The same subject" is identity, except that two `MemberRef`s naming the same member of the same
holder are the same subject (`MemberRef.sameMemberAs`). That exception is what keeps today's rule
"clicking the selected row again puts the saved source back over unsaved typing, and undo brings
the typing back" (the test `macroFormulaBarUndoStaysInItsEdit`, and `input-and-gestures.md`, the
keyboard family).

**(b) An edit.** Every edit is one step of a `MemberRef`, and each step makes the edit, records it
where a snapshot needs it, and tells once:

| Step | `MemberRef` (an object's member) | `ClassMemberRef` (a class's member) |
|---|---|---|
| `add()` | `holder.addOwnProperty name` | `class.applyMemberEdit name, "undefined"` + `recordClassEdit` |
| `save(text)` | `holder.injectProperty name, text`; a function is recorded with `recordInstanceEdit` | `class.applyMemberEdit name, text` + `recordClassEdit` |
| `duplicate(newName)` | `holder.duplicateOwnProperty name, newName`: a NEW verb of the instance edit protocol, beside `renameOwnProperty` in `Widget.coffee` (read that one and mirror it): the new name holds the same value, and an injected method is compiled again under the new name from its kept source | an edit under the new name of the member's recorded source (`_editClassMember newName, source`): exactly the first half of today's class rename, refused the same way when the class holds no source for what the member is now |
| `rename(newName)` | `holder.renameOwnProperty name, newName` | its own `duplicate(newName)`, then a removal of the old name: ONE path makes the copy; refused, with `world.inform`, when the class holds no source for what the member is now |
| `remove()` | `holder.removeOwnProperty name` | `class.removeMember name` + `recordClassMemberRemoval` |
| the one notice | `holder.sourceChanged()` | `world.noteCodeChanged()` |

These are today's bodies, moved (§12 gives the map; U1 landed all but `duplicate`), plus `duplicate` (D15), which is what a class rename already did before it removed the old name. ⚠ A gesture tells ONCE (`macroInspectorEditTellsOnce` counts it): a class `rename` built on a PUBLIC, notifying `duplicate` would tell twice, so the copy the two share is a step of its own that does not notify, and each of `duplicate` and `rename` ends in the one notice. The widgets keep the gesture logic: prompts,
refusals of `constructor`, enabling, re-filtering.

**(c) Who refreshes.** Only the member list changes the member SET (add, rename, remove: D7), and it
re-filters itself and tells the row there is no choice any more. A Save changes no set and refreshes
nothing, as today. No inspector reaches into another.

### 5.4 `InspectorRowWdgt`

```coffee
# The ROW OF INSPECTORS a window holds: the first on the subject a person asked to inspect, each
# next one on a subject chosen in the one to its left (showChoice). I am the inspector as a tool:
# "Inspect" opens me (Widget.spawnInspector).
#   I have no layout of my own. My inspectors are the elements of a horizontal DIVISION row
# (StackLayoutEngine), a splitter between two of them (StackElementsSizeAdjustingWdgt), so they
# divide my width, a person drags a splitter to re-divide it, and my least width is theirs and my
# splitters' together (Widget.getRecursiveMinDim). I paint the body every inspector of mine stands
# on (inspectorBodyFill); they paint only their rules.
class InspectorRowWdgt extends Widget

  constructor: (subject) ->
    super()
    # a row built with no window gives itself a usable extent, and Widget.spawnInspector opens my
    # window at this same extent: one place states it
    @__commitExtent new Point 760, 480
    @color = WorldWdgt.theme.inspectorBodyFill
    @appearance = new RectangularAppearance @
    @_buildAndConnectChildren subject        # shape per widget-authoring-guidelines §3

  # my inspectors, left to right: my children that are inspectors (my other children are splitters)
  inspectors: ->
    (child for child in @children when child.showsSubject?)

  colloquialName: ->
    @inspectors()[0]?.colloquialName() ? "Inspector"

  @showChoice: (chooser, subject) ->
    inspector = chooser
    inspector = inspector.parent until !inspector? or inspector.showsSubject?
    row = inspector?.parent
    if row?.showNextTo?
      row.showNextTo inspector, subject
    else if subject?
      fresh = new InspectorRowWdgt subject
      world.openFrameWith fresh, fresh.extent(), world.hand.position().subtract(new Point 50, 100)

  showNextTo: (inspector, subject) ->
    following = @_inspectorsAfter inspector
    if subject? and following[0]?.showsSubject subject
      @_settleLayoutsAfter => @_removeInspectorsNoSettle following[1..]
      following[0].reload()
      return
    @_settleLayoutsAfter =>
      @_removeInspectorsNoSettle following
      @_addInspectorNoSettle new InspectorWdgt subject  if subject?
    @_widenMyWindowToFit()
```

The rest, in words (write them in the house voice, each with its comment):

- **`_addInspectorNoSettle(inspector)`** adds it as my last child with
  `layoutSpec: inspector.divisionBox()`, then reconciles my splitters.
- **`_removeInspectorsNoSettle(inspectors)`** destroys each (`_fullDestroyNoSettle`), then reconciles.
- **`_reconcileSplittersNoSettle()`** is the ONE rule, in two halves. **Splitters:** exactly one
  between two consecutive inspectors, none anywhere else: walk `@children`; destroy a splitter that
  is first, last, or follows another splitter; add one (`new StackElementsSizeAdjustingWdgt`,
  `divisionBox()`, `atIndex:`) between two inspectors that touch. Identify a splitter by a
  capability it already answers (`ownsDragsStartingOnMe`), never by `instanceof`. **Split buttons:**
  then tell every inspector whether a splitter now stands before it, `inspector.wearSplitGrip
  true|false` (false for my first), so an inspector carries a split button exactly while a splitter
  stands on its left (§5.5, §5.10). Nothing here reads the pointer.
- **`_reactToChildRemoved(child)`** tells an inspector that leaves it wears no split grip any more
  (`child.wearSplitGrip? false`), then reconciles: an inspector leaves by another hand
  through a person's "Pick up" or a destroy. ⚠ It also fires while I am being destroyed and while
  my own removals run: read `FrameWdgt._reactToChildRemoved` and
  `PromptButtonsRowWdgt._reactToChildRemoved` and mirror their guards (an orphan, a destroyed
  holder) so a teardown builds nothing.
- **`_widenMyWindowToFit()`** runs at EVENT time only (the end of `showNextTo`), never in a layout
  pass: `missing = @getRecursiveMinDim().x - @width()`; if positive, and my parent is a window whose
  content I am (`@parent?.isMyContents? @`) and which is free-floating, widen it by
  `Math.min missing, Math.max(0, world.right() - @parent.right())` through its public `setExtent`.
  In any other holder I am not widened and my inspectors narrow.
- **No `readsClassMemberMaps` here**: I read no member map. The classes that do declare it (§5.5–5.6).

### 5.5 `InspectorWdgt`

```coffee
# AN INSPECTOR: one subject (inspectedObject), and one VIEW of it at a time. In a row of inspectors
# (InspectorRowWdgt) I am one column; my subject was chosen in the inspector to my left, and what
# is chosen in me goes to the one on my right (InspectorRowWdgt.showChoice).
#   Top to bottom, the elements of a vertical DIVISION stack: my HEADER band -- my subject's name,
# and a chip naming the class it is made by, whose press chooses that class; my CHOOSER band, a
# toggle per view, built only when my subject has more than one; and my view, which takes the rest.
class InspectorWdgt extends Widget

  # a file holding me needs the class member maps before I am restored (Deserializer._needsTheReflectiveLayer)
  readsClassMemberMaps: true

  # the object I am a view OF, and deliberately not called `target` (see the old header: keep that note)
  inspectedObject: undefined
  header: undefined
  classChip: undefined
  chooser: undefined
  viewToggles: undefined
  # the widget showing my subject now, and the title of the view it is
  view: undefined
  shownViewTitle: undefined
  # does my header open with a split button? My row says: while a splitter stands before me (wearSplitGrip)
  showsSplitGrip: false

  constructor: (@inspectedObject) ->
    @viewToggles = []
    super()
    @_buildAndConnectChildren()

  # THE VIEWS MY SUBJECT OFFERS, in order: [title, the name of my method that builds it].
  # One table, read by my chooser and by showView.
  _views: ->
    return [["Source", "_newMemberEditor"]]  if @inspectedObject?.editsAsAMember?()
    [["Members", "_newMemberList"]]

  _newMemberList: -> new MemberListWdgt @inspectedObject
  _newMemberEditor: -> new MemberEditorWdgt @inspectedObject

  showsSubject: (subject) ->
    subject is @inspectedObject or (@inspectedObject?.sameMemberAs? subject) is true

  reload: -> @view.reload?()

  colloquialName: -> "Inspector — " + @_subjectName()

  # a class is named as DATA, by its class's name; anything else through the service
  _subjectName: ->
    if isAClassPrototype @inspectedObject then @inspectedObject.constructor.name else Utils.colloquialNameOf @inspectedObject

  # The class my subject is made by: the first link ABOVE it on its prototype chain that is a
  # class's own prototype (it owns a `constructor` that is a function), unless that is Object. An
  # object's is its class; a class's prototype's is its superclass; a number's is Number. A member
  # has none: its holder's class is the inspector to my left.
  _classAbove: ->
    return undefined  if @inspectedObject?.editsAsAMember?()
    link = Object.getPrototypeOf Object @inspectedObject
    until !link? or ((Object::hasOwnProperty.call link, "constructor") and Utils.isFunction link.constructor)
      link = Object.getPrototypeOf link
    link  if link? and link.constructor.name isnt "Object"

  # my chip's action. My view's own choice, if it shows one, is no longer what stands on my right
  chooseMyClass: ->
    @view.clearChoice?()
    InspectorRowWdgt.showChoice @, @_classAbove()
```

Build (inside ONE settle, children added with the NoSettle tier):

- header: `new BandWdgt theme.inspectorHeaderHeight, [theme.inspectorHeaderInset, title,
  BandWdgt.SPRING, chip, theme.inspectorHeaderInset], rule: "bottom"` (the two metrics are today's
  `breadcrumbBandHeight` 44 and `breadcrumbInset` 12 under the names §5.9 gives them), the chip only
  when `_classAbove()` answers. The title is a `StringWdgt` in `theme.fonts.buttonLabel`, sized to
  its text (`_sizeToTextAndDisableFittingNoSettle`, as the old "Class" caption was). The chip is
  `new ChipWdgt target: @, action: "chooseMyClass", face: link.constructor.name, current: true`.
- the split grip: the header is built by ONE method (`_buildHeaderNoSettle`), which the constructor
  calls and **`wearSplitGrip(wanted)`** calls again. That public method keeps the answer in
  a declared boolean field (`showsSplitGrip`, false as built), does nothing when the answer is the
  one it has, and otherwise destroys my header band and builds it again in its place (index 0):
  wearing one, the band opens `[new SplitGripWdgt, theme.toggleBandGap, title, …]` in place of the
  left inset; wearing none (my row's first inspector, or an inspector in no row), as above. The header band is 44 tall and the grip 44 × 44, so
  the grip fills the band's height and the band's left end.
- **`splitterBeforeMe()`** answers the splitter itself, from STRUCTURE, each time it is asked: my
  parent's child just before me, when that child is a splitter (the capability the row's reconcile
  tests), else undefined. Nothing stores a splitter: a grip can then never drag a splitter of a row
  its inspector is not in.
- view: `@view = @[@_views()[0][1]]()`, added with `divisionBox('y')` and a box that takes the slack
  (a large max on both axes, as §5.6's code floor).
- The chooser band and `showView` are U4's (§6); in U1–U3 every subject has one view and no chooser.

### 5.6 `MemberListWdgt` and `MemberEditorWdgt`

**`MemberListWdgt extends Widget`** — `constructor: (@inspectedObject)`; `readsClassMemberMaps:
true`. A vertical division stack of: the toggles band (`rule: "bottom"`), the list, the cut-notice
band (only when `itemCount > items.length`: one `StringWdgt` saying today's `_emptyPaneText` wording,
"The first N of M items are listed."), the footer band (`rule: "top"`, only when
`MemberRef.canEdit @inspectedObject`).

It keeps, under their present names, everything of §1.1's "Member set", "Filter" and the member
gestures: the four `showing*` fields and `toggleShowing*`, the four toggles, `_filteredMemberNames`,
`_subjectsItemsAndNames`, `@MOST_ITEMS_LISTED`, `@_isAnIndex`, `memberFactsOf`,
`_subjectsClassPrototype`, `_buildAndConnectMemberList`, `_refilterMembers`,
`_reflectFiltersOnToggles`, `_reflectMemberSelection`, `_selectedMemberCanBeRenamedOrRemoved`,
`addProperty`/`addPropertyPopout`, `renameProperty`/`renamePropertyPopout`, `removeProperty`,
`_refusesAsANewMemberName`, the three buttons. It gains **Duplicate…** (D15), shaped exactly as
Rename… is: `duplicatePropertyButton` between Add… and Rename…, enabled with Rename… and Remove
(`_reflectMemberSelection`); `duplicatePropertyPopout` prompts for the new name with the selected
name as its default; `duplicateProperty(newName)` refuses the same name and `constructor`
(`_refusesAsANewMemberName`), refuses a name my subject already owns (say so with `@inform`: a
duplicate must not overwrite), calls the ref's `duplicate`, re-filters and tells the row there is
no choice. With four buttons the footer's controls need about 364 px, a little more than the
toggles band's 352: that becomes the member list's least width. Keeping the names is deliberate: the rigs and tests
of §7 then change WHERE they find a member, not what it is called.

What changes inside it:

- `selectionFromList(name)`: `_reflectMemberSelection()`, then
  `InspectorRowWdgt.showChoice @, MemberRef.of(@inspectedObject, name)`.
- `inspectMemberValue(name)`: when the value is an object (`Utils.isObject`),
  `InspectorRowWdgt.showChoice @, value`.
- **`clearChoice()`**: no row of mine is selected any more (my inspector's chip was pressed, so the
  inspector on my right no longer shows my selected member). `ListWdgt` has no way to drop its
  selection today: give it a small public `clearSelection` (`@selected = undefined`, then
  `@listContents.noteShownSelectionChanged()`, the two lines `select` ends in), call it, then
  `_reflectMemberSelection()`. The storyboard's frame 5 shows what happens without it: the row
  stays highlighted beside an inspector on something else.
- the four edits call the ref's step (`MemberRef.of(@inspectedObject, name).add()` …), then
  `_refilterMembers()`, then `InspectorRowWdgt.showChoice @, undefined`.
- a class's prototype builds no "Own props only" toggle: ask `isAClassPrototype @inspectedObject`
  where `ClassInspectorWdgt` overrode the builder.
- `_refilterMembersNoSettle` no longer touches a code pane (there is none here).
- the list wears the inspector's pane roles as today (`wearPaneRoles fill: "inspectorPaneFill",
  stroke: "inspectorPaneStroke"`), and it and its contents reject drops as today.

**`MemberEditorWdgt extends CodeAreaWdgt`** — `constructor: (@memberRef)`; `readsClassMemberMaps:
true`. Model it on `ScriptWdgt`:

```coffee
  _buildAndConnectChildrenNoSettle: ->
    @_buildEditableCodeAreaNoSettle @memberRef.shownText()
    # `constructor`'s code is shown, never edited: it is the class itself (Class.refuseTheConstructor)
    @textWidget.isEditable = @memberRef.name isnt "constructor"
    if MemberRef.canEdit @memberRef.holder
      @saveButton = new SimpleButtonWdgt target: @, action: "save", face: "Save", primary: true
      @_addNoSettle @saveButton
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()
    @_invalidateLayout()

  _footerRightButtons: -> [@saveButton]

  textContentModified: -> @saveButton?.setEnabled true
  textContentUnmodified: -> @saveButton?.setEnabled false

  # What code typed in me runs against (TextWdgt._codeReceiver): my member's holder, exactly while
  # it is an object my Save edits; a class's member, or a value no Save edits, gets no run rows.
  codeReceiver: -> MemberRef.codeReceiverOf @memberRef.holder

  # Answers whether it saved. An edit that does not compile changes nothing, is reported beside the
  # hand, and stays modified, Save still enabled (Widget._savingTypedCode).
  save: ->
    return false  unless @saveButton?
    return false  unless @_savingTypedCode => @memberRef.save @textWidget.text.toString()
    @textWidget.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()
    true

  # my member's text again, over whatever is typed: one step of my undo history, so the undo chord
  # brings the typing back (InspectorRowWdgt.showChoice, the subject chosen again)
  reload: ->
    @textWidget.setText @memberRef.shownText()
    @textWidget.pushUndoState @textWidget.text.length
    @textWidget.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()
```

Three things to settle while writing it:

- **A read-only member has no footer band.** `CodeAreaWdgt` always keeps a band today, because each
  of its four subclasses has buttons. Give the base ONE derived question, "do I have a footer band:
  is any button of my two groups my child", read by `_layOutOwnContents` (the code area runs to my
  bottom without one) and `_seamRects` (no rule without one). No subclass changes, and the four
  existing ones must stay byte-identical (presuite says).
- **The code area's floor.** In a division row the editor's inspector derives no width from an
  editor with one button, so give the editor a division box of its own: least width **280**, a large
  max on both axes.
- **Its look.** Dress the code area in the inspector's pane roles after the build (as
  `InspectorWdgt._clearPaneLook` does today), so it stands on the row's body fill like the list.

### 5.7 `MemberRef` and `ClassMemberRef`

Plain classes, not widgets, **immutable** (two fields, never written after construction; see
`immutable-value-classes.md`, and do NOT declare `keptByReferenceOnDeepCopy`: a copy of an inspector
together with its subject must point at the copied subject, which only an ordinary walk gives).

```coffee
# ONE MEMBER of one object: `name` in `holder`. What an inspector shows when a member is its
# subject, and the one place that knows HOW a member is edited: an object's member through the
# instance edit protocol (Widget.injectProperty and its three siblings), a class's through its
# meta-object and recorded for a snapshot to replay (ClassMemberRef).
class MemberRef

  holder: undefined
  name: undefined

  # the reference for the member `name` of `holder`: a class's member when holder is a Fizzygum
  # class's prototype, an object's otherwise
  @of: (holder, name) ->
    if isAClassPrototype holder then new ClassMemberRef holder, name else new MemberRef holder, name

  # Can `holder`'s members be edited at all? A class's prototype, through its class; an object that
  # answers the instance edit protocol (a capability, never `instanceof Widget`). A number, a Point,
  # a plain object, a built-in class's prototype, a class function: no.
  @canEdit: (holder) ->
    (isAClassPrototype holder) or holder?.injectProperty?

  # What code typed in a member's editor runs against: an object whose members are edited as an
  # object's; never a class's prototype (code run against it would change the class unrecorded).
  @codeReceiverOf: (holder) ->
    holder  if holder?.injectProperty? and !isAClassPrototype holder

  constructor: (@holder, @name) ->

  editsAsAMember: -> true
  colloquialName: -> @name
  sameMemberAs: (other) ->
    (other?.editsAsAMember?() is true) and other.holder is @holder and other.name is @name
```

**What U1 landed** (read the two files; they are the base U2 builds on): `holder`, `name`,
`@_recordedStaticSourceOf`, `shownText()` (the old `_paneTextOfMember`; not `text()`, which is a FIELD
of every text widget), `_fieldSource()` (the old `_sourceForFieldMember`), `canBeRenamedOrRemoved()`
(the old `_selectedMemberCanBeRenamedOrRemoved` without the selection read), `add()`, `save(txt)`,
`rename(newName)`, `remove()`, `_notifyOfEdit()`. `ClassMemberRef` overrides `_fieldSource`, the four
steps and `_notifyOfEdit`, with `_editClassMember` and `_removeClassMember` as its two helpers,
exactly as `ClassInspectorWdgt` had them. **What U2 adds**, each with its first reader: the three
statics above (`of`, `canEdit`, `codeReceiverOf`), `editsAsAMember`, `colloquialName`, `sameMemberAs`,
and `duplicate(newName)` on both classes (§5.3 b's warning: the copy is a step that does not notify).

⚠ No comment line of `MemberRef.coffee` may read ` extends <ClassName>`: the boot dependency scanner
(`src/boot/dependencies-finding.coffee`) reads that phrase anywhere on a line, a comment's included, as
"this file needs that class first", and its walk has no cycle guard. A `new X` inside a method body it
does not read, so `@of` above names both classes plainly.

The steps are public doors a widget calls, named for what they do (`add`, `save`, `rename`,
`remove`). (A consequence, not the reason: no member here is named `_apply…` or `_commit…`, a prefix
the tier-naming audit reads as a geometry corner: §7.3, `tier-naming-prelude.js`.)

### 5.8 `BandWdgt` and `BandSpaceWdgt`

```coffee
# A BAND: one row of controls across the widget that holds me -- a header, a row of toggles, a row
# of buttons. I am `height` tall, my rule included, and as wide as I am given; my controls keep
# their own sizes, centred down me, in the order written, with the gaps written between them, and
# my spring takes the slack.
#   I have no layout of my own: every item is an element of a horizontal DIVISION row
# (StackLayoutEngine). So my least width is my controls' and gaps' together, which the stack derives
# (Widget.getRecursiveMinDim), and the least width of whatever holds me follows from it.
#   An item is a widget (a control, fixed at its own preferredExtent, centred down me), a number (a
# gap that many px wide), or BandWdgt.SPRING. ⚠ A gap is as TALL as I am, and that is what makes me
# that tall: a division row is as tall as its tallest element, whatever its own box says. A band
# written with no spring gets one at its end: without one the slack would stretch my controls.
#   I paint nothing but my rule (SeamRulesAppearance): a line along my top or bottom edge.
class BandWdgt extends Widget
  @SPRING: "spring"
  # the edge my rule lies along -- "top" or "bottom" -- or undefined for none
  ruleEdge: undefined

  constructor: (height, items, opts = {}) ->
    super()
    @ruleEdge = opts.rule
    @appearance = new SeamRulesAppearance @
    ...                                   # ONE settle; every child added with the NoSettle tier

  _seamRects: ->
    return []  unless @ruleEdge?
    thickness = WorldWdgt.theme.inspectorRuleWidth
    if @ruleEdge is "top"
      [new Rectangle 0, 0, @width(), thickness]
    else
      [new Rectangle 0, @height() - thickness, @width(), @height()]
```

- A control: `control.setMinAndMaxBoundsAndSpreadability extent, extent,
  DivisionStackLayoutSpec.SPREADABILITY_NONE` with `extent = control.preferredExtent()`, and a
  division box whose `crossAlign` is 'center' (set it the way `DivisionStackLayoutSpec` offers for a
  widget not yet added; read its setters first).
- A gap: `new BandSpaceWdgt px, height`. A spring: `new BandSpaceWdgt 1, height, springs: true`.
- **`BandSpaceWdgt`**: no appearance (it paints nothing, as `PromptButtonsRowWdgt` paints nothing);
  `@minimumExtent = new Point 0, 0` in its constructor; its box is least = desired = the size
  given, spreadability NONE for a gap; for a spring least width 0, desired width **1** (never 0:
  §4's first hazard), spreadability `SPREADABILITY_SPACERS`; `hiddenFromHierarchyMenu: -> true`.
- A band and its spaces reject drops.

### 5.9 Theme, door, part

- **Theme (`src/Theme.coffee`).** Delete what loses its last reader: `inspectorBreadcrumbCaption`,
  `inspectorBreadcrumbSeparator`, `breadcrumbCaptionGap`, `breadcrumbGap`,
  `breadcrumbSeparatorSize`, `inspectorListColumnWidth`, and `footerGripClearance` (with D8). Rename
  the two that keep a reader under a name that would now lie: `breadcrumbBandHeight` →
  `inspectorHeaderHeight`, `breadcrumbInset` → `inspectorHeaderInset`. Rewrite the comments above
  each inspector metric to say what reads it now. Colours stay Theme roles (`raw-chrome-color` is
  held at 0).
- **Door (`Widget.spawnInspector`).** Inside the same two awaits:
  `row = new InspectorRowWdgt inspectee` then
  `world.openFrameWith row, row.extent(), world.hand.position().subtract(new Point 50, 100)`.
  `inspectorClassFor` is gone: `MemberRef.of` makes the one decision it made.
- **Part.** No partition change: every new class lives in `src/meta-tools`. Update the `//` comment
  of the `meta-tools` entry in `buildSystem/parts.json` to name the classes it holds now.

### 5.10 The split's two controls (D11)

The splitter (`StackElementsSizeAdjustingWdgt`, core) stays the division element between two
inspectors and keeps the solve that moves a split (`nonFloatDragging`: a closed form over the row's
division boxes, exact at any event cadence; read its long comment before touching anything near
it). A split gets two controls, both always present, one look whatever the pointer:

**The divider, for a mouse** (U1b). The splitter is `theme.layoutAdjusterThickness` wide (new
metric, 12; today its box is 5) and its mark is a small field of the house's grip dots in place of
today's bar (`drawLayoutChrome`, which reads `layoutAdjusterGrabMarkWidth`/`Length`: those two
metrics go). The dots are the ones a toolbar band's strip shows (`FrameStripAppearance`: 2 px
squares, `barGripMarkDotSize`, on a 6 px pitch, `barGripMarkPitch`, in the `muted` ink): lift that
dot-field arithmetic (`_dotStartsAlong` and the fill loop) to where both can call it, so there is
ONE dot field in the tree, and bound the splitter's field to a few rows along its length (4 in the
storyboard) so it reads as a grip, not a texture. Per D14 this is the look of every splitter, so it
is a change to the core class with no inspector in it, and lands as its own unit.

**The split button, for a finger** (U2). A `SplitGripWdgt` in the header band of the inspector on
the divider's right RELAYS its own drag to that splitter, so there is no second solve. An inspector
wears one exactly while a splitter stands before it (§5.4). A mouse may use it too.

**The finger icon** (U3b). The button's face is a double arrow with a finger on it, so it says what
to do. No finger or hand icon exists in `src/icons/`. Draw one as a size-aware icon with the
`/convert-icon-size-aware` skill of the umbrella (its probe, preview and owner-review loop), and
compose it with the double arrow in the grip's glyph. Until the owner has approved the icon the
button shows the double arrow alone; do not ship a stand-in drawing.

```coffee
# A SPLIT GRIP: the FINGER's way to move a split. I am a 44 x 44 piece of layout chrome (the
# 44 rule, visual-design-system §4.2: a target that must be big is drawn big) standing at the
# left end of an inspector's header band, right of the splitter that stands before that inspector.
# The splitter itself is the mouse's way; we are both always there, since a device can have both.
# A drag on me is a drag on that splitter: I hand it my drag, moved by the distance between us, so
# its leading edge follows the pointer exactly as if the press had landed on it. The split's
# arithmetic stays the splitter's own (StackElementsSizeAdjustingWdgt.nonFloatDragging).
#   I hold no splitter: I ask the inspector I stand in which one stands before it, as I am dragged
# (InspectorWdgt.splitterBeforeMe, read off the row's children), so a copy of me, or my inspector
# taken out of its row, drags nothing that is not its own.
class SplitGripWdgt extends LayoutChromeWdgt

  constructor: ->
    super()
    ...                                     # my box: minimumTargetSize square, fixed

  # I am CHROME, as the splitter is: a drag that starts on me moves my split, at once, for a
  # finger as for a mouse (ActivePointerWdgt._touchPressArmsAtOnce), and it never lifts me out
  ownsDragsStartingOnMe: -> true
  detachesWhenDragged: -> false
  grabsToParentWhenDragged: -> false

  # MY GLYPH: the double arrow across, as a layout spacer's (LayoutChromeWdgt._glyphOnMyPlate), and,
  # once it is drawn, the finger on it
  _glyphOnMyPlate: ->
    theme = WorldWdgt.theme
    [(new DoubleArrowIconAppearance @, theme.layoutChromeGlyph), theme.layoutSpacerGlyphSize]

  # the splitter before the inspector I stand in: the nearest container of mine that can say
  _mySplitter: ->
    holder = @parent
    holder = holder.parent  until !holder? or holder.splitterBeforeMe?
    holder?.splitterBeforeMe()

  # The splitter reads where its LEADING EDGE should be as the pointer less the grab point inside
  # ITSELF. My grab point is inside ME, so it is moved by how far right of the splitter I stand.
  # That distance is a difference of two laid-out positions that move TOGETHER through a drag, so
  # it is the same number on every move of a frame, whichever of them the frame has laid out.
  nonFloatDragging: (grabPointInMe, pos, deltaDragFromPreviousCall) ->
    splitter = @_mySplitter()
    return  unless splitter?
    grabPointInSplitter = new Point grabPointInMe.x + (@left() - splitter.left()), grabPointInMe.y
    splitter.nonFloatDragging grabPointInSplitter, pos, deltaDragFromPreviousCall
```

Notes for writing it:

- This is the spike's variant C made a class (§4): there the relay was an instance override on a
  second `StackElementsSizeAdjustingWdgt`; here it is a class of its own, so nothing holds a
  function. Read `StackElementsSizeAdjustingWdgt` whole first: it also sets the resize cursor on
  hover and restores it at the end of a drag (`hoverEntered`, `hoverExited`, `endOfNonFloatDrag`);
  give the grip the same three, or lift them where both can share them.
- If `check-layering.js` rule [O] (the callers allowed to defer a settle through a drag stream) or
  the call-separation gate objects to one widget calling another's drag handler, the answer is a
  PUBLIC, intent-named method on the splitter that both its own handler and the grip call (the
  body of `nonFloatDragging` from `targetLeft` on, taking the wanted leading edge), never a second
  copy of the solve.
- A row is horizontal, so the relay shifts `x`. Do not generalise it to a vertical stack before a
  vertical client exists.
- The grip, like a band and its spaces, rejects drops.
- **One case to decide while writing:** an inspector COPIED alone out of a row (the context menu's
  Duplicate) is built with `showsSplitGrip` true and stands in no row, so its grip shows and does
  nothing. `Widget._reactToBeingCopied` is the hook a copy gets once it is whole (read
  `ToolbarWdgt`'s and `ViewportWdgt`'s for what it may do, and call `super`): if it can clear the
  field and rebuild the header cleanly, do that; if it cannot, leave the idle grip and write one
  "noted, not queued" line in this plan's ledger at the close.
- `SplitGripWdgt` lives in `meta-tools` while the inspector is its only client. Every OTHER
  division stack's splitter gets the dotted look (D14) and no finger's way to move it: U5 files
  that.
- A mouse can still press the 12 px divider a finger cannot take reliably; that is intended. The
  divider stays a pointer target for every pointer (a finger that does land on it moves the split).

---

## 6. Work units

| Unit | What | Gate at its end | Done |
|---|---|---|---|
| U0 | Orient, decisions, a green baseline | `fg presuite` | [ ] |
| U1 | `MemberRef` / `ClassMemberRef` under the OLD inspectors: no pixel changes | `fg gauntlet` | [x] 2026-11-24 |
| U1b | The divider's look: every division stack's splitter 12 px wide with grip dots (D11, D14) | `fg gauntlet` | [ ] |
| U2 | The switch: the new widget classes, the door, the toolkit, 32 tests, the rigs, recapture | `fg gauntlet` + `fg homepage` | [ ] |
| U3 | Tests of what is new, each proven to bite | `fg presuite` | [ ] |
| U3b | The finger icon on the split button: candidates, then the owner's choice (D11) | `fg presuite` after the choice | [ ] |
| U4 | Object-list views (Children, Instances, Subclasses) and the chooser (D12) | `fg gauntlet` | [ ] |
| U5 | Docs, BACKLOG, churn set, close | `fg gauntlet` | [ ] |

### U0. Orient (0.5 hour)

1. §0.5 steps 1–4.
2. `fg presuite` in the background; it must be green before any edit. If it is not, stop and ask.
3. If `Fizzygum-tests/.scratch/inspector-overhaul-spike/` exists, open `review.html` and skim
   `spike5-target.js`: it is the target built in ~120 lines of page JavaScript.

### U1. The member reference, under the old inspectors (0.5–1 day)

**Goal:** the edit semantics move, alone, under the full existing safety net. No screenshot changes.

1. Add `src/meta-tools/MemberRef.coffee` and `ClassMemberRef.coffee` per §5.7 and §12.
2. In `InspectorWdgt`: `selectionFromList` reads `MemberRef.of(@inspectedObject, selected).text()`;
   `save`, `addProperty`, `renameProperty`, `removeProperty` call the ref's steps;
   `_subjectIsEditable` and `codeReceiver` read the ref's two statics;
   `_selectedMemberCanBeRenamedOrRemoved` reads `canBeRenamedOrRemoved()`. Delete what moved:
   `_paneTextOfMember`, `_sourceForFieldMember`, `@_recordedStaticSourceOf`, `applyPropertyEdit`,
   `_applyPropertyAddition`, `_applyPropertyRename`, `_applyPropertyRemoval`, `_notifyOfEdit`.
3. `ClassInspectorWdgt` shrinks to `colloquialName` and the empty own-props toggle builder. It and
   `inspectorClassFor` stay until U2.
   ⚠ One behaviour to keep exactly: today an OBJECT inspector holding a class's prototype (built by
   code or from a file) is read-only. With `MemberRef.of` it would become class-edited. In U1 keep
   `InspectorWdgt._subjectIsEditable` answering false for a prototype, as now; U2 removes the case
   with the class.
4. Outside `src`:
   - `Fizzygum-tests/scripts/tier-naming-audit/tier-naming-prelude.js` lines ~59–62: remove the three
     `_applyProperty*` names from `NON_GEOMETRY` (they fail `TIERNAMING-STALE` once gone).
   - `Fizzygum-tests/scripts/serialization-roundtrip-headless.js`: where an expectation calls a
     moved method (the comment at `check-call-separation.js:77` says a rig calls
     `InspectorWdgt.applyPropertyEdit`), call the ref's step instead. Grep the rig for every name
     deleted in step 2.
   - `buildSystem/check-complexity-ratchets.js` ~line 191: re-key `'InspectorWdgt#_paneTextOfMember':
     20` to the method's new key (`'MemberRef#text'`), with a dated reason ("moved").
   - `buildSystem/check-layering.js` ~lines 327–348: the two `settling-call-sanctioned` markers move
     with `_notifyOfEdit` into the two ref classes; the ceiling (18) does not change. Update the
     history note's file names.
5. **Gate:** `fg build` (every static gate), then `fg gauntlet`. Expected: green with **zero**
   reference changes. A changed reference here is a bug in the move, never churn.

**Landed 2026-11-24 (U1 of the inspector-overhaul loop).** Built as steps 1, 4 and 5 say; steps 2 and 3
were corrected by the unit's research, measured against the tree:
- **The ref follows the INSPECTOR class, not the holder.** `InspectorWdgt._memberRefOf(name)` answers a
  `MemberRef`, `ClassInspectorWdgt` overrides it to answer a `ClassMemberRef`, and both classes keep
  `_subjectIsEditable` and `codeReceiver` as they were (step 3's shrink would have made every class
  inspector read-only). Choosing by the holder (`MemberRef.of`) under the old inspectors would have
  changed what two (inspector × subject) pairs show for a field: an object inspector holding a class's
  prototype (the recorded source, for its value) and a class inspector holding an instance (its value,
  for an ancestor's recorded source). So `of`, `canEdit`, `codeReceiverOf`, `editsAsAMember`,
  `sameMemberAs`, `colloquialName` and `duplicate` are U2's, with their first readers, and step 3's
  temporary prototype guard was never needed. `ClassInspectorWdgt` keeps five members: `_memberRefOf`,
  `_subjectIsEditable`, `codeReceiver`, `colloquialName`, the empty own-props toggle builder.
- **The member's text is `shownText()`**, not `text()`: `text` is a field of every text widget, read as
  `x.text` all over both repos.
- **No widget holds a ref**: each is made for one gesture and dropped, so no snapshot or copy meets one
  before U2.
- **The one behaviour that differs, ruled:** a refused class rename is said through `world.inform` from
  inside `ClassMemberRef.rename` (a ref is no widget), where the class inspector's own `inform` said it:
  the bubble's opener, its target, its rows' target and its OK row's subject are the world. No pixel and
  no dismissal path differs.
- **Facts of this plan corrected in place:** the boot dependency scanner reads no `new X` inside a method
  body (§0.1, §5.7 and a row of §10 said it did), so `MemberRef.of` needs no indirection, while a comment
  line reading ` extends <Class>` IS read; a class rename written as "its own public `duplicate`, then a
  removal" would tell twice (§5.3 b); the complexity record sits at `check-complexity-ratchets.js` ~:195;
  the serialization rig called `_applyPropertyRename` too.
- **Outside `src`:** the tier-naming table's three rows removed; the serialization rig's five
  `applyPropertyEdit` calls and its `_applyPropertyRename` call go through `new ClassMemberRef(proto,
  name)` (the refusal caught on `world.inform`), three inspectors built only to make such a call dropped,
  every expectation name unchanged.
- **Evidence:** `fg build` clean; the ported serialization rig alone, every expectation met on both
  backends; `fg presuite` with an EMPTY failing set, as predicted, and no reference changed. The unit's
  review walked every gesture of both inspector classes over every kind of subject, the refused and the
  read-only paths included, and compared the sixteen moved bodies token by token: the one differing token
  is the `inform` above. It found no behaviour defect; it found sentences still naming the inspectors
  as the readers of the class records (the `ClassMemberRef` header, the comment of
  `InspectorWdgt.readsClassMemberMaps`, `parts.json`, `build-and-packaging.md`, two rig comments), all
  corrected, and that `Fizzygum/CLAUDE.md` taught the scanner fact this plan was built on, corrected
  there.
- **Ratchets:** the complexity record `'InspectorWdgt#_paneTextOfMember': 20` re-keyed to
  `'MemberRef#shownText': 20`, the body unchanged; the layering marker ceiling unchanged at 18 (the two
  marked calls moved with `_notifyOfEdit`); `Fizzygum/CLAUDE.md`'s byte ceiling 35421 → 35555 for the
  corrected scanner sentence, and `Fizzygum-tests/CLAUDE.md`'s banked down 67015 → 66434 (the gate's own
  offer).
- **Moved paths no test reaches**, read line by line in review instead: a Save of a non-function value
  recording nothing; a class rename refused because the class does not define the member; the class
  add's own record read on the editing page.
- **For U2** (seen here, not worked here): the ref's steps are public and assume their gesture's guards
  (a rename onto the member's own name would drop it; `constructor`); a refused class rename still
  re-filters the list, which loses the selection while the bubble says nothing was renamed.

### U1b. The divider's look (0.5 day)

A change to the core splitter with no inspector in it (§5.10, "The divider"), so it lands alone and
is judged alone.

1. `StackElementsSizeAdjustingWdgt`: its box from `theme.layoutAdjusterThickness` (12) in place of
   the literal 5 × 5 of its constructor; `drawLayoutChrome` paints the dot field in place of the
   bar. Its header comment says "a 5×5 grab strip": say what is true.
2. The dot field has ONE home: lift `FrameStripAppearance._dotStartsAlong` and its fill loop to
   where the strip's appearance and the layout chrome can both call them (read both callers first;
   the strip's field fills its plate, the splitter's is bounded to a few rows along its length and
   centred). `Theme.coffee`: add `layoutAdjusterThickness`, remove `layoutAdjusterGrabMarkWidth` and
   `layoutAdjusterGrabMarkLength` with their comments.
3. Read `Widget._showResizeAndMoveHandlesAndLayoutAdjustersNoSettle` (it inserts splitters around a
   division cell for the halo) and `WidgetFactory.createBorderLayoutScaffold`: nothing there states
   a thickness, but check.
4. **Predicted pixel set:** every test whose pictures show a splitter. From `Fizzygum-tests/`,
   `grep -l "divisionBox\|StackElementsSizeAdjustingWdgt\|createBorderLayoutScaffold\|Adjuster" tests/*/*_automationCommands.js`
   names the candidates (16 on 2026-11-24); a splitter 7 px thicker also moves the cells beside it,
   and a test that drags one presses where it now stands. Write the set down BEFORE the suite; the
   failing set must equal it.
5. `fg presuite`; `fg diffpage` of the failing set and look: each changed shot is a dotted, thicker
   splitter and the cells it pushed. Then `fg build`, `fg recapture --auto --dprs=1,2`,
   `fg recapture --auto --pointer=finger --dprs=1,2`. `visual-design-system.md` (the layout chrome's
   look, §4.3 or wherever the adjuster is described: grep "adjuster") says what is true.
6. **Gate:** `fg gauntlet`.

### U2. The switch (2–3 days)

One commit pair (both repos), because `InspectorWdgt` changes meaning in one step. Work in this
order and check at each numbered checkpoint; the suite is red between U2.1 and U2.8 by design.

**U2.1 Source.** (The divider already has its look: U1b.) Write `BandSpaceWdgt`, `BandWdgt`, `SplitGripWdgt`, `MemberEditorWdgt` (with `CodeAreaWdgt`'s
derived footer question), `MemberListWdgt`, `InspectorWdgt` (rewritten whole), `InspectorRowWdgt`,
per §5. Delete `ClassInspectorWdgt.coffee` and `BreadcrumbSeparatorWdgt.coffee`. Change the door and
the Theme (§5.9). Remove U1's temporary prototype guard: `MemberRef.canEdit` is the one answer now.

**U2.2 What loses its last definer (D8).** With the resizer gone, nothing defines
`bottomRightCornerReachedBy` or `footerRightClearance`, and `check-unresolved-sends.js` fails on
their three readers. Read each reader whole, then delete the dead branch:
- `Widget.noteCornerChainChanged` (`Widget.coffee` ~:1045): its walk visits only children a
  container names; with no container naming any it visits nothing. Find its callers
  (`HandleWdgt.updateVisibility` is one) and remove the method and the calls if nothing is left for
  it to do; `ScrollIndicatorHostWdgt.noteCornerResizerChanged` loses its only caller the same way.
- `ScrollIndicatorHostWdgt._resizerOverMyCorner` (~:240): its `while container?.bottomRightCornerReachedBy?(child)`
  climb never climbs; what remains is a resizer that is the host's own direct child (a viewport
  takes a handle directly, `attachesToViewportDirectly`). Keep exactly that.
- `FooterBandLayout._arrange` (:78) and `buttonBoundsIn`'s `rightClearance` parameter: remove both.
  `CodeAreaWdgt` and `BinWdgt` pass nothing, so their pixels do not move (presuite says).
- If `ChevronRightIconAppearance.inkSpanX` loses its last reader (`check-dead-methods.js` says),
  delete it; the class stays (`MenuItemWdgt` uses it).
⚠ This touches the scroll indicators. If reading a reader shows a second definer or a case this
note missed, stop and write it into this plan before going on.

**U2.3 Checkpoint: it builds.** `fg build`. Answer each gate by its class. Expected findings, each
with its answer:
- `census-widget-conformance.js` `BASELINE_PROLOGUE_COPIES` 8 → 7 (the inspector no longer repeats
  the `_reLayout` prologue): lower it, dated.
- `check-call-separation.js` `BASELINE_U_QUERY` (101) falls by the inspector's layout queries: lower
  it, dated.
- `check-relayout-bounds-first.js`: its header and its advice text name `InspectorWdgt._reLayout` as
  a reference shape (lines ~5, ~13, ~46, ~185). Name `FanoutWdgt._reLayout` alone, or another
  surviving example of the `@_applyMoveTo` + `@_applyExtent` form if one exists (grep).
- `gates.js` row comments (~286, ~302, ~317), `census-property-placement.js`, `lib/gate-advice.js`:
  prose only; correct what names a deleted thing.
- dead methods, unresolved sends, menu-action wiring: every `action:` string must name a method of
  its target (`chooseMyClass`, `save`, `toggleShowing*`, `addPropertyPopout`, …).

**U2.4 Checkpoint: it runs.** Write a probe under `Fizzygum-tests/.scratch/` (Node resolves
`require` from the script's folder, so it must live there) and run it with
`node .scratch/<name>.js` from `Fizzygum-tests/`:

```js
'use strict';
const path = require('path'), puppeteer = require('puppeteer');
const H = path.resolve(__dirname, '..', '..', 'Fizzygum-builds', 'latest', 'worldWithSystemTestHarness.html');
require('../scripts/lib/tests-manifests').ensureTestsManifests({ quiet: true });
(async () => {
  const br = await puppeteer.launch({ headless: 'new', args: ['--allow-file-access-from-files', '--no-sandbox'] });
  const p = await br.newPage(); await p.setViewport({ width: 1400, height: 800, deviceScaleFactor: 1 });
  const logs = []; p.on('pageerror', e => logs.push('[pageerror] ' + e.message));
  p.on('console', m => { if (m.type() === 'error') logs.push('[error] ' + m.text().slice(0, 400)); });
  await p.goto('file://' + H + '?dpr=1&speed=fastest&intro=0', { waitUntil: 'load', timeout: 120000 });
  await p.evaluate(() => new Promise(r => { const t = () => (window.world && window.InspectorRowWdgt) ? r() : setTimeout(t, 100); t(); }));
  const settle = (n) => p.evaluate((n) => new Promise(res => { let i = 0; const s = () => (++i >= n ? res() : requestAnimationFrame(s)); requestAnimationFrame(s); }), n);
  await p.evaluate(() => { world.resetWorld(); }); await settle(5);
  const facts = await p.evaluate(() => {
    const clock = new AnalogClockWdgt(); world.add(clock);
    const row = new InspectorRowWdgt(clock); const win = world.openFrameWith(row, row.extent(), new Point(20, 20));
    const list = row.inspectors()[0].view;
    list.selectionFromList('drawSecondsHand');
    const two = row.inspectors().length;
    const editor = row.inspectors()[1].view;
    const text = editor.textWidget.text;
    list.inspectMemberValue('bounds');
    return { two, text: String(text).slice(0, 60), afterDrill: row.inspectors().map(i => i.colloquialName()),
             title: row.colloquialName(), win: win.bounds.toString() };
  });
  await settle(6); await p.screenshot({ path: path.join(__dirname, 'switch-probe.png') });
  console.log(JSON.stringify(facts, null, 1)); console.log('LOGS\n' + logs.join('\n'));
  await br.close();
})();
```

Expect: two inspectors after the selection, the member's CoffeeScript in the editor, the second
inspector replaced by one on a Rectangle after the drill, an empty log. Look at the picture. Then
`cd Fizzygum && ./build_and_smoke.sh` is NOT yet expected green (the smoke's inspector probe is
ported in U2.7); the boot of the three pages with no console error is.

**U2.5 The toolkit (`src/macros/MacroToolkit.coffee`, `src/macros/CLAUDE.md`,
`src/macros/MACRO-PATTERNS.md`).** Keep every verb's NAME (32 tests and `aim-census.js`'s table
use them); change what each finds:

| Verb (line, 2026-11-24) | Finds today | Finds after |
|---|---|---|
| `_findTopInspector` (:2304) | topmost `InspectorWdgt` (or subclass) | topmost `InspectorRowWdgt`; keep the `return undefined unless InspectorRowWdgt?` guard and its comment (the lazy part) |
| `topInspectorList` (:2417) | `.list` | the `list` of the row's LAST inspector whose view is a member list (ask the view for a capability it answers, `selectionFromList?`) |
| `clickOnCodeBoxFromTopInspectorAtCodeString_InputEvents` (:2532) | `.textWidget` | the `textWidget` of the row's last inspector whose view is a member editor (`save?`) |
| `clickOnSaveButtonFromTopInspector_InputEvents` (:2544) | `.saveButton` | that editor's `saveButton` |
| `bringcodeStringFromTopInspectorInView_InputEvents` (:2554) | the inspector's `TextAreaWdgt` child, `.textWidget` | that editor's `tempPromptEntryField` and `textWidget` |
| `scrollInspectorListItemIntoView_InputEvents` (:2379), `bringUpInspector_…_Macro` (:2605), `bringUpInspectorAndSelectListItem_…_Macro` (:2614), `bringInViewAndClickOnListItemFromTopInspector_…_Macro` (:2620) | a list it is given; the "Inspect" row | unchanged |

Put the two locators ("the member list a person would pick from", "the editor it feeds") in the
toolkit, as two small methods the verbs share, not on the product classes. Rewrite
`src/macros/CLAUDE.md` lines ~316–321 and the "One inspector" passage (~405–428) to the new shape;
sweep `MACRO-PATTERNS.md` (the entries at ~383–449, ~1218–1238, ~1420–1499, ~1566–1597,
~2270–2461, ~2617, ~2682–2693; `:411` cites a verb that no longer exists: remove it).

**U2.6 The tests (`Fizzygum-tests/tests/`).** Port the 32 tests of §7.1. For each: read its
`intent`/`scenario`/`assertions`, port the macro with the map of §12, update the four metadata
strings to say what it now does, run it alone
(`node scripts/run-macro-test-headless.js SystemTest_<name>`) until only screenshot mismatches
remain. Rules:
- An assertion is ported, never deleted, unless what it asserts no longer exists; then the test's
  metadata says so. A green assertion is not a delivered intent: re-read each `intent` against what
  the ported test proves.
- A test whose NAME names something gone is renamed (directory, both files, the global, and every
  place §7.3 lists the name). `macroAnalogClockInspectEdit` keeps its name and an `image_0`: eleven
  rigs and self-tests use it as THE standard test (§7.3).
- The five tests that exercise only the deleted shape are re-purposed, not dropped:
  `macroInspectorBreadcrumbChipOpensClassInspector` → the header chip puts the class beside the
  object, and the class's chip its superclass; `macroNakedInspectorRendersResizesAndEdits` → a row
  with no window renders and edits (no resize of its own); `macroInspectorResizingOKEvenWhenTakenApart`
  and `macroPickingUpPartsFromInspector` → a member list and an editor picked out of the row, then
  the row and the parts resized; `macroInspectorOpensAClassInItsClassInspector` → a class's
  prototype, however it is reached, is edited as a class.

**U2.7 The rigs and tooling (`Fizzygum-tests/scripts/`).** §7.3 lists every one with what to do.
Run each rig alone after porting it.

**U2.8 Recapture.** `fg build`, then in the background, one after the other:
`fg recapture --auto --dprs=1,2` and `fg recapture --auto --pointer=finger --dprs=1,2`. Each must end
`RECAPTURE COMPLETE`. Before trusting the set, `fg diffpage` three tests of different kinds (a plain
edit, a duplicate, a taken-apart) and look. ⚠ `NEEDS RECAPTURE` reported right after a capture is a
finding, not noise. A test filed *needs-a-fix* is a ported macro that is wrong: fix the macro.

**U2.9 Gate.** `fg gauntlet`, then `fg homepage` (the only gate that boots the production tree and
restores an inspector there), then `fg build` again (a plain dev build, so the tree is the suite's).
Expected churn: only the tests of §7.1 and any test that shows an inspector window.

### U3. Tests of what is new (1 day)

Write each with the `/author-macro-test` skill of the tests repo. Each is proven to bite: plant the
bug through `--prelude=` (a file under `.scratch/`), watch the test fail on its own line, remove the
plant, watch it pass. Each is proven clean with a follower on both pointers:
`node scripts/run-sequence-headless.js SystemTest_<new> SystemTest_macroAnalogClockInspectEdit`, zero
`WORLD_INVENTORY_` lines, then again with `--pointer=finger`.

| Test | Proves | Plant that must fail it |
|---|---|---|
| `macroInspectorMemberClickOpensItsEditorBesideTheList` | a click adds the second inspector; another row REPLACES it (still two); the same row again RELOADS it (typed text gone, undo brings it back) | `showNextTo` always appends |
| `macroInspectorDrillWidensItsWindow` | a double-click on an object-valued field shows the value beside the list; a third inspector widens the window by the missing width; the first inspector is still there | `_widenMyWindowToFit` a no-op |
| `macroInspectorSplitMovesByDividerAndByButton` | the divider shows its dots and the second inspector's header opens with the split button, the first inspector's does not; a drag on the DIVIDER moves the split by the drag's travel and nothing else; a drag on the BUTTON does the same. The test runs on both pointer axes: the finger run is the proof D11 asks for (its button drag is a touch drag) | the button's relay a no-op |
| `macroInspectorTakenOutLeavesNoStraySplitter` | "Pick up" of the second inspector leaves one inspector and NO splitter; a choice made in the picked-out one opens a window of its own | `_reactToChildRemoved` a no-op |
| `macroInspectorRowSurvivesACopyAndASnapshot` | a duplicate of a two-inspector row drives its own editor; a snapshot round trip restores both inspectors and the member's source | (assert only; the serialization leg is the gate) |
| `macroInspectorReadOnlyMemberHasNoFooter` | on a Point: the list has no footer band, the editor no Save and no band | the derived footer question answering true |
| `macroInspectorDuplicateCopiesAMember` | on a widget: Duplicate… of an injected method under a new name gives a second member with the same source that runs, the original untouched; of a field, a second field holding the same value; a name the subject already owns is refused and nothing changes. On a class: the copy is recorded (a snapshot replays it) and `rename` leaves exactly what duplicate-then-remove leaves | `duplicate` writing under the OLD name |
| `macroInspectorCutListSaysSo` | an array of 1200 items: the list shows 1000 and the notice band says "The first 1000 of 1200 items are listed." | the notice band never built |

Add to `serialization-roundtrip-headless.js` (and `lib/serialization-expectations.js`) an
expectation that a snapshot holding a row whose second inspector's subject is a `MemberRef` restores
with that ref naming the restored holder. `MemberRef` is the first non-widget, non-value class a
widget of this tool holds: this is where a serializer rule about it would show.

### U3b. The finger icon (0.5 day of work, then the owner)

The split button ships from U2 with the double arrow alone. This unit draws the finger.

1. Use the umbrella's `/convert-icon-size-aware` skill: it is the house's way to author an icon
   whose geometry is right at every size on the non-antialiased backend, with a probe, an HTML
   preview and an owner-review loop.
2. Produce two or three candidates for "drag this sideways with a finger" at the size the button
   draws its glyph (`theme.layoutSpacerGlyphSize` inside a 44 × 44 plate): a fingertip under or
   beside the double arrow. Show them ON the button, in a real inspector, mouse and dpr 1 and 2, on
   a local review page (`Fizzygum-tests/.scratch/…`, opened), beside the arrow-only button.
3. **Stop for the owner's choice.** An icon is the owner's call. Until it is made, nothing of this
   unit is committed and the button keeps the arrow alone.
4. After the choice: the icon class in `src/icons/`, the grip's `_glyphOnMyPlate` composing it with
   the arrow, recapture of the pictures that show a split button, `fg presuite`.

### U4. Object-list views and the chooser (1 day, D12)

1. **`ListWdgt` (core): rows that stand for objects.**
   - It dispatches the ELEMENT, not the row's label, to `target[action]` and
     `target[doubleClickAction]`. A row's element is the one at the row's index. For a list of
     strings the element IS the label, so the member list and every other caller are unchanged
     (only the inspector passes a target today: grep to confirm).
   - A new option **`labelQuery`**: the name of the target's method that answers an element's label
     (the same shape as `memberFactsQuery`: a method name, no closure). Without it,
     `ListWdgt.labelOf` as now.
2. **`InspectorWdgt`: more than one view.**
   - `_views` gains rows, each guarded by a capability of the subject, never `instanceof`:
     `["Children", "_newChildrenList"]` for a widget (it answers the widget tree's own questions;
     pick the narrowest existing one), `["Instances", "_newInstancesList"]` and
     `["Subclasses", "_newSubclassesList"]` for a class's prototype.
   - The queries are one line each: `@inspectedObject.children`; the class's `instances` set as an
     array (`Class.coffee` emits one per class; widgets only register); the prototypes of the classes
     `allClassFunctions()` lists whose `__super__` is my subject.
   - One builder serves all three: `new ListWdgt objects, target: @, action: "chooseRow",
     labelQuery: "labelOfRow"`, with `chooseRow: (object) -> InspectorRowWdgt.showChoice @, object`
     and `labelOfRow` answering `_subjectName`'s rule for the object.
   - The chooser band (`theme.toggleBandHeight`, `rule: "bottom"`): one `LabelledToggleWdgt` per
     view, `action: "showViewNamed", arg1: title`, ON exactly for the shown view
     (`_reflectViewOnToggles`, the shape of `_reflectFiltersOnToggles`). Built only when `_views()`
     has more than one row.
   - `showViewNamed(ignored, ignored2, title)` → `showView(title)`: destroy the view, build the
     named one in its place (same index), reflect the toggles, and
     `InspectorRowWdgt.showChoice @, undefined`.
3. **Tests** (with bite-proofs and followers as U3): `macroInspectorChildrenViewWalksTheWidgetTree`
   (a window: Children, choose a child, choose its child: three inspectors, each titled with its
   widget); `macroInspectorClassViewsListInstancesAndSubclasses`;
   `macroInspectorViewSwitchDropsWhatWasChosen`.
4. `fg menusweep` and `fg pinsweep` alone, then `fg gauntlet`. Recapture what U4 moved (an inspector
   on a widget or a class now has a chooser band: every such screenshot).

### U5. Docs, BACKLOG, close (0.5 day)

1. **Architecture docs** (§7.4), present tense, no "was"/"no longer". The one that owns the new
   mechanism is `widget-citizenship.md` (the inspector as an assembly of ordinary widgets) plus a
   new short section in `layout.md` §4.2 naming `BandWdgt` as the division stack's first product
   client, with §4's two hazards as rules.
2. **`Fizzygum-tests/scripts/inspector-churn-set.json`:**
   `node scripts/derive-inspector-churn-set.js --write` (from `Fizzygum-tests/`), and read its diff.
   The script plants a member and sees which tests' pictures move; it assumes `_filteredMemberNames`
   and `showingInherited`, which `MemberListWdgt` keeps.
3. **`docs/BACKLOG.md`.** The inspector's open lines stay open and keep their wording where it is
   still true; correct any that names a deleted method or class. They are (search "inspector"):
   the Inherited filter (⛔ owner), "Is an inspector's subject always a page object?" (⛔ owner),
   the world's inspector editing its browser listeners, "A function held with no kept source shows
   compiled JavaScript" (⛔ owner), "A wrapped member reads as compiled text" (⛔ owner), "A scrolled
   pane keeps its height when its content shrinks", `fg recapture-inspector`'s blind recapture. Add,
   under this plan's section, what this arc leaves open:
   - every OTHER division stack's splitter has no finger's way to move it (the halo's layout
     adjusters, "Edit layout"): a general stack has no header band to stand a grip in;
   - a division row whose elements desire 0 width in all divides by zero (`StackLayoutEngine`);
   - two footer-band mechanisms stand: `FooterBandLayout` (the code-area family, the bin) and
     `BandWdgt`; one should serve both;
   - the talk plan's U3 is superseded by this plan (one line, so the owner's plan and this one do
     not both claim the explorer).
4. **Close the arc** with the `/close-arc` skill: final `fg gauntlet`, the plan `git mv`-ed to
   `docs/archive/` with its status stamp and its `archive/INDEX.md` line, the commit messages
   proposed, and the wait for approval.

---

## 7. Touch-lists (complete as of 2026-11-24)

### 7.1 The 32 SystemTests that drive the inspector

All are under `Fizzygum-tests/tests/SystemTest_macro<Name>/`. "Shots" is the number of screenshot
names; every shot of every one is recaptured at dpr 1 and 2, mouse and finger. Sixteen tests are
assertion-only.

| Test (`macro…`) | What it does today | Inspector internals it reads | Shots |
|---|---|---|---|
| AddEditSaveRenameRemoveProperty | add, save, rename, remove a property; list scroll | the four buttons, `detail.textWdgt.setText`, `list.elements/.selected/getScrollY` | 5 |
| AnalogClockInspectEdit | edits `drawSecondsHand`, saves | none (verbs only) | 1 |
| AStepThatThrowsStopsStepping | edits `step`; Save un-bans | `showInheritedToggle`, `detail.textWdgt.setText`, `saveButton` | 0 |
| ClassEditShowsOnTheNextFrame | 3 class + 3 object inspectors built in code | `showInheritedToggle`, `detail.textWdgt.text` | 11 |
| ClassInspectorSaveRefusesCodeThatDoesNotCompile | a bad class save is refused | `detail.textWdgt.setText`, `saveButton(.isEnabled)` | 0 |
| DuplicateComplexWidgetPaintsCleanly | duplicates the inspector window | none | 2 |
| DuplicatedInspectorDrivesCopiedTargetOnly | each copy's save hits its own rectangle | `showInheritedToggle`, `list.selected`, `detail.textWdgt.setText`, `saveButton` | 3 |
| DuplicatedInspectorsCloseIndependently | closes each copy | none | 3 |
| EveryCodeChangeGivesBannedWidgetsAnotherChance | class add/remove in code | `addProperty`, `removeProperty`, `list.listContents`, `list.select` | 0 |
| FormulaBarUndoStaysInItsEdit | the code pane's undo history | `detail.textWdgt` | 0 |
| InspectorBreadcrumbChipOpensClassInspector | chips open class inspectors | `classChips`, `inspectedObject`, `colloquialName()`, `parent` | 0 |
| InspectorCodePaneRunsAgainstItsSubject | run rows of the pane menu | `list`, `detail`, `detail.textWdgt`, `classChips`, `inspectedObject` | 3 |
| InspectorEditTellsOnce | counts how often each edit tells | `addProperty`, `save()`, `renameProperty`, `removeProperty`, `list.select`, `detail.textWdgt.setText` | 0 |
| InspectorOffersOnlyWhatItsSubjectOwns | Rename/Remove enabling | the buttons' `isEnabled`, `detail.textWdgt.isEditable`, `list.select`, `renameProperty`, `addProperty`, `toggleShowingInherited` | 0 |
| InspectorOnNonWidgetIsReadOnly | 42, a string, a Point, a widget | presence of the four buttons, `list.contents.children`, `colloquialName()` | 0 |
| InspectorOpensAClassInItsClassInspector | row double-click, `spawnInspector` on a prototype | `list.listContents/select`, `inspectedObject`, `saveButton?`, `colloquialName()`, the four edits, `constructor.name` | 0 |
| InspectorRejectsDrops | drops a box over both panes | `list`, `detail` (geometry) | 3 |
| InspectorResizingOKEvenWhenTakenApart | `pickUp` of list and detail; resizes | `list`, `detail` | 4 |
| InspectorSaveRefusesCodeThatDoesNotCompile | a bad value save is refused | `detail.textWdgt`, `saveButton.isEnabled` | 0 |
| InspectorScrollbarUnplugged | unplugs the list's scroll bar | `list.vBar` | 4 |
| InspectorShowsAnUndefinedFieldAsUndefined | a field's text | `list`, `detail.textWdgt.text` | 0 |
| MovingSlidersSidewaysDoesntCauseContentToMoveSideways | drags the list bar sideways | `list.vBar`, `list.getScrollX/Y` | 3 |
| MultilineTextInputScrollsWell | types into the code pane | `detail.textWdgt`, `detail.vBar` | 2 |
| NakedInspectorRendersResizesAndEdits | no window; edit, save, own resize | `resizer` | 3 |
| ObjectInspectorOnAClassShowsItsStaticsSource | an inspector on a class function | `list.selected`, `detail.textWdgt.text` | 0 |
| ObjectInspectorShowsTheFunctionItsSubjectHolds | 5 object + 1 class inspector | `list.selected`, `detail.textWdgt`, `saveButton`, `removePropertyButton.isEnabled`, `showInheritedToggle`, `renameProperty` | 0 |
| PaletteBufferKeyNamesItsOwnCode | saves then removes a member | `list`, `detail.textWdgt.setText`, `saveButton`, `removePropertyButton` | 0 |
| PickingUpPartsFromInspector | `pickUp` of detail, then list | `detail`, `list` | 3 |
| ResizingPristineInspector | resizes the window | `instanceof InspectorWdgt` | 2 |
| SimpleDocumentHandlesOldInspector | embeds the window in a document, drags it out | none | 3 |
| TextOwnCodeKeysTheCachesItRunsIn | saves/removes two members | `showInheritedToggle`, `list`, `detail.textWdgt.setText`, `saveButton`, `removePropertyButton` | 0 |
| WrappingTextFieldResizesOK | soft wrap; resizes | `detail.textWdgt` | 3 |

Also: `macroTextRunRowsReflectSelection` asserts the "Inspect selection" row's label (unchanged).
`macroInspectorWorkAreaEvaluatesCoffeeScript` drives `ConsoleWdgt` only (unchanged). Twenty-three
more tests name the inspector in a comment or a provenance string only; sweep them for a name that
has become false (`grep -l -i inspector tests/*/*.js`, skipping `automation-assets/`).

**Predicted outcome of the first suite run after U2.6:** exactly these 32 fail on pixels or pass on
assertions; any other failure is a finding.

### 7.2 Source outside the two inspector files

| File | What | Do |
|---|---|---|
| `src/basic-widgets/Widget.coffee` | `spawnInspector` (:4997); comments naming the inspectors (:190, :3467 the titles, :4266, :4446–4454, :4599, :4964–4996, :5201, :5615, :5700, :5718, :5755); `noteCornerChainChanged` (:1040–1047) | door per §5.9; comments to the new shape; U2.2 |
| `src/basic-widgets/TextWdgt.coffee` | `_codeReceiver` comment (:684–687) names both inspectors as receivers | name the member editor |
| `src/WorldWdgt.coffee` | comments (:215, :703, :763, :1710–1716, :2207, :2854, :3146, :3485, :3535, :3600, :3664) | correct what names a deleted class or method |
| `src/basic-widgets/menu-system/MenusHelper.coffee` | comment :9 | check |
| `src/serialization/` | `Deserializer` :246 comment; `SourceEditsRegistry` comments (:9–15, :32, :43, :54, :198, :204) naming the writers; `Serializer` remedy strings (:349, :352, :400) and `SerializationError` :93 naming "an inspector's Remove/Save"; `WellKnownObjects` :26; `NativeValueKinds` :62 | writers are now `MemberRef.save` / `ClassMemberRef`; the remedy strings stay true (the buttons exist) but check their wording against the serialization rig's regexes |
| `src/ListWdgt.coffee`, `CommandPanelWdgt.coffee`, `MemberRowWdgt.coffee`, `MenuItemWdgt.coffee` | member mode: unchanged in U1–U3; comments say "the Object Inspector's" | say "a member list's (MemberListWdgt)" |
| `src/ChipWdgt.coffee`, `LabelledToggleWdgt.coffee` | comments name the breadcrumb and the filter | to the new shape |
| `src/FooterBandLayout.coffee` | `footerRightClearance` (:78), comments :6, :18–19 | U2.2 |
| `src/basic-widgets/ScrollIndicatorHostWdgt.coffee`, `src/HandleWdgt.coffee` :173 | the corner hooks | U2.2 |
| `src/basic-widgets/ViewportWdgt.coffee` | `wearPaneRoles` comments (:74, :94, :180, :185, :978) | check |
| `src/CodeAreaWdgt.coffee` | the family header | add the member editor; the derived footer question |
| `src/Utils.coffee` :36 | "today the object inspector" | check |
| `src/PartsRegistry.coffee` (:107, :226, :311), `src/boot/globalFunctions.coffee` (:117, :261, :300, :311, :552), `src/meta/Class.coffee` (:263, :460, :621, :635), `src/meta-tools/ConsoleWdgt.coffee` | comments | check each names something that exists |
| `src/Theme.coffee` | §5.9; comments at :111, :240, :245, :343, :371, :507–519, :681, :693, :710, :761–765, :784–789, :1071–1117 | §5.9 |
| about twenty files with a one-line mention in a comment (`SwitchButtonWdgt` :67, `ButtonWdgt` :144, `ColorPickerWdgt` :146, `StretchablePanelWdgt` :144, `StretchableCanvasWdgt` :206, `SimpleSpreadsheetWdgt` :648, `BinWdgt` :22, `FrameWdgt` :973, `TransformFrameWdgt` :84, `FrameGripWdgt` :32, `HandleAppearance` :1, `BackBuffer` :3/:29, `ClippingWdgt` :5, `ActivePointerWdgt` :1925, `AnalogClockWdgt` :69, `AnalogClockAppearance` :6/:148, `FridgeMagnets3DCanvasWdgt` :92, `Duplicator` :37/:101/:214) | case law and examples | leave a dated case-law mention as it is; correct only a present-tense claim that became false |

### 7.3 Rigs, tooling and gates

| File | What reaches the inspector | Do |
|---|---|---|
| `Fizzygum-tests/scripts/menu-click-sweep-headless.js` | roots `InspectorWdgt` / `ClassInspectorWdgt` and the popout-button section (:806–904: `INSPECTOR_BUTTON_OF`, `inspectedObject`, `list.select`, `faceWidget.text`, `MenuSweepOwnWdgt`); three code-pane roots (:1127–1200); `PROMPTS_DRIVEN_FLOOR = 53` counting two prompts per inspector class (:79, :190–195) | two fixtures stay (a widget subject, a class subject), now rows; the popout buttons are the member list's, and there are THREE per fixture now (`INSPECTOR_BUTTON_OF` gains `duplicatePropertyPopout: duplicatePropertyButton`); the code-pane roots are member editors. The floor rises by the two new prompts: move it with its dated reason |
| `…/menu-click-sweep-selftest-headless.js` | plants on every `InspectorWdgt`, strips "…" off the two popout buttons (:118–154, :190) | plant on `MemberListWdgt` |
| `…/smoke-boot-headless.js` | `inPageInspectorState` counts `constructor.name === 'InspectorWdgt'` (:485–493); the restored-inspector probe builds a `ClassInspectorWdgt`, calls `selectionFromList`, reads `detail.textWdgt.text` (:550–630); rules at :735–766; `world.spawnInspector(world)` judged `inspectors === 1` (:860–871, :966–980) | the count still holds (one `InspectorWdgt` after an open); port the probe to a row on a class's prototype, its member list's `selectionFromList`, its editor's `textWidget.text` |
| `…/smoke-boot-selftest-headless.js` (:17, :173) | expects `RESTORED_INSPECTOR_VACUOUS` | re-run; fix the plant if the probe's shape moved |
| `…/smoke-apps-headless.js` (:28–32, :101–121, :268–276) and its selftest (:80) | `spawnInspector(world)` then counts `InspectorWdgt` | still one; re-run |
| `…/staleness-census.js` :156 | the `inspector-window` extra | unchanged; it now arranges the row: `fg census` must stay clean |
| `…/parts-snapshot-load-headless.js` :436 | `{$wk:'class:ClassInspectorWdgt'}` as a class of the lazy part | another class of the part (`InspectorRowWdgt`) |
| `…/serialization-roundtrip-headless.js` + `lib/serialization-expectations.js` | about twenty expectations: `world.saveRefusal.*` (:1205–1244), `inspector.onABuffer*` / `onAPaneRuntimeValue*` (:1250–1350; a regex on `(InspectorWdgt#N) → .inspectedObject`), `onAnUnrecognizedValue…`, `onAPrototypeLessObject…` (:1473–1504), `onAnIndexedSubjectListsItsItemsInOrderBounded` (:1600–1652), `aClassFieldRowShowsItsRecordOnlyWhileItsValueHolds` (:1670–1698), `onACanvasContext*` (:1724–1739), `world.inspector.survivesSnapshot` (:2642–2681), `world.inspector.classSubjectsSurviveSnapshot` (:2701–2801), `sourceEdits.class*` (:4818–4904), the load checks (:4940–5000), `valueClassEditReachesLiveValues` (:5175–5189) | port each with §12's map; **keep every expectation's name** (a name no backend reports is itself a mismatch). The `.inspectedObject` path in refusal texts still holds: an inspector still holds its subject under that name |
| `…/derive-inspector-churn-set.js`, `inspector-churn-set.json`, `lib/inspector-churn-set.js`, `classify-diff.js`, `classify-diff-selftest.js` | the 16 tests `fg recapture-inspector` recaptures | U5 step 2; a renamed test is renamed in the json |
| `…/aim-census.js` :314–320, :377 | table rows for seven inspector verbs, held to the toolkit | names unchanged; re-run on build |
| `…/tier-naming-audit/tier-naming-prelude.js` :59–62 | `NON_GEOMETRY` names three `_applyProperty*` | U1 step 4 |
| Standard-test users of `macroAnalogClockInspectEdit`: `lib/gate-bite-proof.js` :37, `preludes-install-selftest-headless.js` :34, `check-refs-selftest.js` :16 (reads its real `image_0` files on every build), `run-macro-test-headless.js` :123, `notification-settle-audit/cache-oracle-selftest-headless.js` :22, and six plants (`audit-preludes/revisit-plant.js`, `unobserved-bucket-plant.js`, `end-of-cycle-audit/careless-push-plant.js`, `paint-time-plant.js`, `notification-settle-audit/callback-flush-plant.js`, `tier-naming-audit/leaf-react-plant.js`) | the test's name and its `image_0` | keep both; after the recapture run `npm run selftest` in the tests repo and the gauntlet's `selftests` leg |
| `Fizzygum/buildSystem/fg-verbs.js` (:83–87, :282–319, :365–375) | `fg recapture-inspector` | unchanged |
| `Fizzygum/buildSystem/check-complexity-ratchets.js` | `'MemberRef#shownText': 20` (re-keyed by U1 from `'InspectorWdgt#_paneTextOfMember'`) | done in U1; nothing for U2 unless the body changes |
| `…/check-layering.js` :327–348 | two `settling-call-sanctioned` markers of 18 | U1 |
| `…/check-call-separation.js` :77 | `BASELINE_U_QUERY = 101` | U2.3 |
| `…/census-widget-conformance.js` :42–52 | `BASELINE_PROLOGUE_COPIES = 8` | U2.3 |
| `…/check-relayout-bounds-first.js` | the inspector as a reference shape | U2.3 |
| `…/parts.json` :152–156, `profiles/homepage.json` (:11, :21, :57), `profiles/lean.json` (:7, :12), `profiles/dev-precompiled.json` :23, `lib/profile.js` :236 | prose naming the part's classes | name what exists |

### 7.4 Architecture docs

Each is present-tense and must be true when U5 ends. Lines are of 2026-11-24.

| Doc | Where the inspector is described |
|---|---|
| `visual-design-system.md` | §1 :39 (metrics row); §2 :63, :67; §4.3 :176–204 (toggle, chip and breadcrumb band, footer band and the resizer clearance); §4.5 :286 (the breadcrumb's ›); §4.9 :398–403 (titles); §4.10 :420; §5 table :482, :496–498, :505 and prose :583, :591–594, :601–608; §6 :624 |
| `widget-authoring-guidelines.md` | §4.1 :219–234; §6.2 :445–449; §9 :608–618; §10 :655–662; §12 :964–968; §16 :1066; §18 :1139 |
| `serialization-duplication-reference.md` | header :24; §2 :106–107; §4a :330–349 (chips hold class names: the one chip holds none now, it asks `_classAbove` when pressed); §5 :457–459, :541; §6 :605; §9 :714–722; §11 :878; §12 :962–1050 (who records an edit) |
| `build-and-packaging.md` | §2 :183–187; §3 :337–370; §5 :432–473; §7 :675; §8 :691 |
| `lint-and-static-checks.md` | §3 :191, :193, :429, :437; §3b :614; §5 :1015; §6b :1133, :1154 |
| `widget-citizenship.md` | "The stance" :24; "The acid test" :134–139 |
| `viewports-and-planes.md` | :101, :180–224 (the windowless inspector's resizer, `bottomRightCornerReachedBy`), :404 |
| `input-and-gestures.md` | :415; :480–483 (the pane's undo history across reloads: now `InspectorRowWdgt.showChoice`) |
| `world-lifetime-and-inventory.md` §6 :245; `design-principles.md` :24, :46, :60, :98; `app-fit-criteria.md` :96, :155; `immutable-value-classes.md` :32–41 (add `MemberRef`); `layering-naming-convention.md` :383; `transforms.md` :292 | one-line mentions |
| `Fizzygum/CLAUDE.md` :17, :19; `src/spreadsheet/CLAUDE.md` :189; `src/macros/CLAUDE.md` (U2.5) | ⚠ `Fizzygum/CLAUDE.md` has a byte ceiling (`check-doc-narration.js`): edit in place, do not grow it |

---

## 8. Central risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | Another arc is uncommitted in the same trees | §0.5 step 1: stop and ask |
| R2 | The edit semantics change in the move (which source a member shows; what a rename records) | U1 moves them alone under the 32 tests and about twenty serialization expectations, with zero pixel change allowed |
| R3 | A band's derived height or width surprises (§4's facts) | `BandWdgt` is ~50 lines and is the only place the rules live; U2.4's probe shows it before any test is ported |
| R4 | `NON_FINITE_GEOMETRY` from a row of zero desired width | springs desire 1; one settle per band; the token fails every suite leg, so a miss is loud |
| R5 | `_reactToChildRemoved` reconciling during a teardown builds a splitter into a dying row, or the row's own removals re-enter it | mirror the two existing holders' guards (§5.4); `fg vmtruth` and the `WORLD_INVENTORY_` followers of U3 catch a leak; `fg revisits` catches a re-visit |
| R6 | `MemberRef` in a snapshot: a serializer or deserializer rule about a non-widget, non-value class refuses it | U3's added expectation, run first thing in U2.7 by hand: save and reload a world holding a two-inspector row. If refused, read the refusal: the answer is a declaration the class makes (§5 of the serialization reference), never a transient that loses the subject |
| R7 | Widening a window from inside its content surprises a frame (a docked band, a window in a document) | widened only when my parent is a free-floating window whose content I am; anything else narrows the inspectors; U3 tests the plain case and `macroSimpleDocumentHandlesOldInspector` the embedded one |
| R8 | The corner-hook cleanup (U2.2) breaks a scroll bar's reserve | read all three readers before deleting; presuite's scroll-indicator tests are many; stop if a second definer exists |
| R9 | Recapture hides a real break: a ported macro that passes for the wrong reason | each `intent` re-read against the port (U2.6); `fg diffpage` on three kinds; U3's bite-proofs |
| R10 | The inspector's pictures no longer match the owner's 2026-10 design | the bands, the list and the footer keep their metrics and looks (§4, picture 1); what moves is stated in D5, D7, D9, D10. Show the owner `fg diffpage` of `macroAnalogClockInspectEdit` at the end of U2 |
| R11 | A gate's baseline moves and is "fixed" by bending the code | §0.5 step 8; §6 names each expected baseline move and its answer |
| R14 | The splitter's new look (D14) moves the pixels of every test showing a division stack, and a test that drags a splitter presses where it now stands | Its own unit (U1b), its predicted set written down before the suite, the failing set held equal to it |
| R12 | The split grip's relay (one widget handing its drag to another's handler) trips a layering or call-separation rule, or drifts from the splitter's solve | §5.10's second note: one public method on the splitter that both callers use, never a second solve. U3's grip test asserts the split moves by exactly the drag, by mouse and by finger |

---

## 9. Verification protocol

- **Static gates:** `/Users/davidedellacasa/code/Fizzygum-all/fg build`.
- **Inner loop:** `fg presuite > /tmp/fg-presuite-run.log 2>&1` in the background, then
  `cat /tmp/fg-presuite.verdict`.
- **One test:** from `Fizzygum-tests/`, `node scripts/run-macro-test-headless.js SystemTest_<name>`
  (add `--pointer=finger`, `--dpr=2`, `--browser=webkit` as needed).
- **One rig:** `fg menusweep`, `fg pinsweep`, `fg census`, `fg revisits`, `fg vmtruth`; the
  serialization rigs from `Fizzygum-tests/`: `node scripts/serialization-roundtrip-headless.js`, then
  `node scripts/serialization-file-roundtrip-headless.js` (there is no `fg serialization` verb).
- **A leak:** `node scripts/run-sequence-headless.js SystemTest_<new> SystemTest_<any>` on both
  pointers; zero `WORLD_INVENTORY_` lines.
- **Recapture:** build first; `fg recapture --auto --dprs=1,2`, then
  `fg recapture --auto --pointer=finger --dprs=1,2`; `fg diffpage <test>` to look.
- **A test bites:** `--prelude=/abs/plant.js` on the single runner; the test must fail on its own
  line, then pass with the plant removed.
- **Commit point:** `fg gauntlet > /tmp/fg-gauntlet-run.log 2>&1` in the background (~15–27 min).
  A leg that fails in-wave and passes its serial retry is a load flake, said loudly; a leg that
  fails twice is a failure.
- **Production tree:** `fg homepage`, then `fg build` to return to the dev tree.

---

## 10. Rejected alternatives (do not re-attempt)

| Alternative | Why rejected |
|---|---|
| A second tool ("Explore") beside the inspector, embedding `InspectorWdgt` and `ClassInspectorWdgt` as views (the talk plan's U3) | Two tools, two doors, two drill behaviours; a whole class inspector per method to show one method. Owner, 2026-11-24 |
| A horizontally scrolling row (Finder columns, the GT pager) | Measured: as a viewport's content the row does not follow the viewport's height. It needs a new arrange in the viewport family, whose two-writer law (`viewports-and-planes.md`, the scrolled-content contract) has a history of livelocks |
| Dropping inspectors off the left when the row is full | An inspector with unsaved typing would vanish on its own; keeping it alive off the tree is forbidden (`serialization-duplication-reference.md` §2: an owner keeps no widget off its tree) |
| One window per drill, placed to the right of its parent (the talk plan's D3 default) | Windows clutter and the path is lost; the row gives the same picture in one window |
| A hand-written `_reLayout` for the inspector's bands (mirroring `_bandsIn`) | ~200 lines of it are what this plan deletes; the same shape once produced a dpr-2 lag flake and a gate to hold it |
| A band with its own small arrange (the `PromptButtonsRowWdgt` shape) instead of division elements | Viable and not spiked. It would need the band to publish its least width by hand for the row to derive from. The division band was measured end to end |
| Converting `CodeAreaWdgt` and `BinWdgt` to `BandWdgt` in this plan | Right in the end (one footer mechanism), but it moves the pixels of four unrelated tools. Filed for after (U5) |
| The whole breadcrumb in the header | Its height depends on its width when it wraps, which a stack band cannot express (a band's box is read from fields, never from laid-out pixels: `layout.md` §8 rule 1) |
| A view builder object handed to subject-defined view methods (`aView.list(items, label: fn, drill: fn)`, the talk plan) | It stores closures on widgets: an open explorer would make the world unsaveable |
| `MemberRef` kept by reference on a deep copy | A copy of an inspector WITH its subject would keep pointing at the original subject (`macroDuplicatedInspectorDrivesCopiedTargetOnly` is exactly this) |
| Naming the row `InspectorWdgt` and the single-subject widget something else | "An inspector holds one subject under `inspectedObject`" is what the docs, the rig regexes and the refusal messages say; the single-subject widget keeps the name so they stay true |
| Leaving the 6 px splitter strip as the only way to move a split | A split must work by touch (owner, 2026-11-24). Measured: a press 1 px off the strip drags the window |
| A wider hit area than the splitter draws | The 44 rule: a target never extends beyond the widget that owns it, and a target that must be big is drawn big (`visual-design-system.md` §4.2) |
| The splitter itself 44 px wide | Works, measured, and is one line; it puts a 44 px plate down the whole height between every two inspectors (88 px of a three-inspector row) |
| A dress per pointer (for a mouse the dotted divider and no button; for a finger a hairline and the button), switched at each choice in the row | The owner's own ruling for an hour on 2026-11-24, then withdrawn: some devices have both a mouse and a touch screen, so both controls stay at all times. It would also have been the first geometry to read the pointer |
| Changing what the Inherited filter shows while moving it | An owner design call, parked in BACKLOG; a move is not the place to decide it |

---

## 11. After this plan (not part of its done-ness)

- **Senders and implementors** (the talk plan's U4). Each is one more row of
  `InspectorWdgt._views` and one query, on U4's object lists. A list of senders is a list of
  `MemberRef`s; choosing one opens its editor.
- **Code organisation: packages, categories, families of members, and comments** (owner,
  2026-11-24, D16). The owner's frame: the metadata lives in the ordinary source as standard or
  special comments, a lint at build time enforces it, and an edit made in the inspector keeps it
  right. The row of inspectors holds all of it without a new mechanism, because each level is one
  more KIND of subject with a list view, and choosing a row is already how one gets to the next:

  | Level | What it is in this tree | Its inspector |
  |---|---|---|
  | package | a build PART (`buildSystem/parts.json`); a class's part is known at runtime already (`SourceVault.store name, text, part`) | a list of its categories or classes |
  | category | the source FOLDER a class's file is in; not known at runtime today (one class has a `category:` field, nothing reads it) | a list of its classes |
  | class | a class's prototype (this plan) | Members; a **Comment** view: the class's header comment, editable |
  | family | a named run of members. The tree has 48 hand-written banners of the kind `# Widget menus ////…` and no enforced form | a member list of that family; in the class's member list, a heading above each family |
  | member | `MemberRef` (this plan) | the editor shows the member's comment lines above its code, as the file has them, and Save keeps both |

  Uniform verbs follow from D7 and D15: every such list ends in the same footer, Add… Duplicate…
  Rename… Remove, acting on its selected row, each kind of subject carrying its own steps as
  `MemberRef` carries a member's. Duplicating, adding, renaming and removing a CLASS arrive there.

  What is missing underneath, and why this is its own plan and not a unit of this one:
  1. **The meta-object throws the comments away.** `Class.getSourceOfAllProperties` reads each
     member's preceding comment (`propertyComment`) and drops it; the constructor drops the class's
     header comment (`[name, ignored, sourceLines] = …`). A class's own record must keep its whole
     text faithfully: comments, family markers, member order.
  2. **Nothing writes an edit back to a `.coffee` file.** An inspector edit changes the running
     class and is recorded in the world's change list (`SourceEditsRegistry`); a world snapshot
     replays it. There is no file-out. "Edited in the inspector, correct in the source" needs a
     class's text regenerated from its record and a way out of the page (a downloaded file: a
     `file://` page cannot write one in place).
  3. **The marker's form and its lint.** A family opens with a marker comment the meta-object
     reads; a build gate holds every member to a family, as a budget that falls to zero (4,242
     methods are unmarked today), registered in the comment rubric so no audit rewords a marker.
     Package and category are better DERIVED than written: a file's folder and its part already say
     them, and a comment repeating them is a second copy that can disagree; the gate there is that
     the build hands the folder to the vault.
  4. **Classes made, renamed and removed at runtime**, and what a snapshot records of them.
- **Views declared by a subject's own class** (the talk plan's `explorerViews`, for domains such as
  the test suite or a folder). The seam is `_views`: it would append what
  `@inspectedObject.inspectorViews?()` answers, each a title and the name of a method of the
  SUBJECT that answers a widget. Build it with its first real client, not before.
- **One footer-band mechanism** (`CodeAreaWdgt` and `BinWdgt` on `BandWdgt`, `FooterBandLayout`
  deleted).
- **A touch-sized way to move every division stack's split**, not only the inspector's: a
  general stack has no header band to stand a grip in, so the shape there is still to design.
- **The parked owner questions** in BACKLOG (the Inherited filter; whether a subject is always a
  page object; compiled JavaScript in an editable pane).

---

## 12. The move map (old member → new home)

`I` = `InspectorWdgt`, `CI` = `ClassInspectorWdgt` (line numbers of 2026-11-24).

| Old | New |
|---|---|
| `I.inspectedObject` | `InspectorWdgt.inspectedObject` (same name); also `MemberListWdgt.inspectedObject`; a member editor holds `memberRef` (`.holder`, `.name`) |
| `I.list` | `MemberListWdgt.list` |
| `I.detail` (the `TextAreaWdgt`) | `MemberEditorWdgt.tempPromptEntryField` |
| `I.textWidget`, `I.detail.textWdgt` | `MemberEditorWdgt.textWidget` |
| `I.saveButton` | `MemberEditorWdgt.saveButton` |
| `I.addPropertyButton`, `renamePropertyButton`, `removePropertyButton` | `MemberListWdgt`, same names |
| `I.showMethodsToggle` … `showOwnPropsOnlyToggle`, `showing*`, `toggleShowing*` (:153–171), `_reflectFiltersOnToggles` (:355), `_toggles` (:807) | `MemberListWdgt`, same names (`_toggles` only if still read) |
| `I.classCaption`, `classChips`, `classSeparators`, `_buildAndConnectBreadcrumb` (:285), `_classChainLinks` (:314), `_breadcrumbIn` (:736), `_layOutBreadcrumb` (:782) | deleted; one `InspectorWdgt.classChip` and `_classAbove` |
| `I.openClassInspector` (:552) | `InspectorWdgt.chooseMyClass` |
| `I.@MOST_ITEMS_LISTED` (:110), `_subjectsItemsAndNames` (:120), `@_isAnIndex` (:139), `_filteredMemberNames` (:396), `_buildAndConnectMemberList` (:436), `memberFactsOf` (:457), `_subjectsClassPrototype` (:464), `_refilterMembers` (:367, :370), `_reflectMemberSelection` (:337), `_selectedMemberCanBeRenamedOrRemoved` (:348) | `MemberListWdgt`, same names; the last one's body is `MemberRef.of(@inspectedObject, name).canBeRenamedOrRemoved()` |
| `I._emptyPaneText` (:145) | `MemberListWdgt`'s cut-notice band text |
| `I.selectionFromList` (:604) | `MemberListWdgt.selectionFromList` (the choice); the load is the editor's build and `reload` |
| `I.lastLoadedMember` | deleted (`InspectorRowWdgt.showChoice` knows a subject chosen again) |
| `I.inspectMemberValue` (:474) | `MemberListWdgt.inspectMemberValue` (the choice of the value) |
| `I.@inspectorClassFor` (:496) | deleted; `MemberRef.of` |
| `I._subjectIsEditable` (:513), `CI._subjectIsEditable` | `MemberRef.canEdit(holder)` |
| `I.codeReceiver` (:521), `CI.codeReceiver` | `MemberEditorWdgt.codeReceiver` → `MemberRef.codeReceiverOf(holder)` |
| `I._paneTextOfMember` (:568) | `MemberRef.shownText()` (moved by U1) |
| `I._sourceForFieldMember` (:563), `CI._sourceForFieldMember` | `MemberRef._fieldSource()`, `ClassMemberRef._fieldSource()` |
| `I.@_recordedStaticSourceOf` (:488) | `MemberRef.@_recordedStaticSourceOf` |
| `I.save` (:842) | `MemberEditorWdgt.save` |
| `I.applyPropertyEdit` (:858), `CI.applyPropertyEdit` | `MemberRef.save(text)`, `ClassMemberRef.save(text)` |
| `I.addProperty` (:875), `addPropertyPopout` (:895), `_refusesAsANewMemberName` (:883), `renameProperty` (:913), `renamePropertyPopout` (:922), `removeProperty` (:939) | `MemberListWdgt`, same names |
| `I._applyPropertyAddition` (:891), `_applyPropertyRename` (:904), `_applyPropertyRemoval` (:935) and `CI`'s three | `MemberRef.add()`, `.rename(newName)`, `.remove()` and `ClassMemberRef`'s |
| `I._notifyOfEdit` (:866), `CI._notifyOfEdit` | `MemberRef._notifyOfEdit`, `ClassMemberRef._notifyOfEdit` |
| `CI._editClassMember`, `_removeClassMember` | `ClassMemberRef`, same names |
| `I.textContentModified` / `Unmodified` (:326, :329) | `MemberEditorWdgt` |
| `I._reLayout` (:626), `_bandsIn` (:680), `_seamRects` (:707), `_layOutTogglesIn` (:795), `_footerLeftButtons` (:813), `_footerRightButtons` (:816) | deleted (`BandWdgt`, division stacks; the editor's `_footerRightButtons` is `CodeAreaWdgt`'s hook) |
| `I._clearPaneLook` (:824) | the same `wearPaneRoles` call where the list and the code area are built |
| `I.resizer`, `bottomRightCornerReachedBy` (:200), `footerRightClearance` (:205) | deleted (D8, U2.2) |
| `I.colloquialName` (:104), `CI.colloquialName` | `InspectorWdgt.colloquialName` ("Inspector — …"), `InspectorRowWdgt.colloquialName` |
| `I.readsClassMemberMaps` (:46) | `InspectorWdgt`, `MemberListWdgt`, `MemberEditorWdgt` |
| `new InspectorWdgt(x)` / `new ClassInspectorWdgt(proto)` in a test or rig | `new InspectorRowWdgt(x)` (a class's prototype needs no other class) |
| `insp.list.select(row)` then reading `insp.detail.textWdgt.text` | `row.inspectors()[0].view.list.select(…)` then `row.inspectors()[1].view.textWidget.text` |

---

## 13. References

**In-repo (Fizzygum):** `docs/architecture/` — `widget-authoring-guidelines.md`, `layout.md`,
`lint-and-static-checks.md`, `serialization-duplication-reference.md`, `visual-design-system.md`,
`viewports-and-planes.md`, `build-and-packaging.md`, `widget-citizenship.md`,
`immutable-value-classes.md`, `constructor-and-parameter-conventions.md`, `input-and-gestures.md`;
`docs/archive/inspector-read-only-subjects-plan.md`; `docs/plans/smalltalk-talk-2026-11-plan.md`
(U3, U4, Appendix C: the owner's "browsers are just lists" note); `docs/BACKLOG.md`;
`src/macros/CLAUDE.md`.

**In-repo (Fizzygum-tests):** `CLAUDE.md`, `DETERMINISM.md`, `.claude/skills/author-macro-test/`.

**Spike (gitignored, authoring machine):**
`Fizzygum-tests/.scratch/inspector-overhaul-spike/` — `spike1.js` (the row), `spike2.js` (a
composed pane beside today's), `spike3-touch.js` (the splitter by finger), `spike4.js` (pick-out,
copy, viewport), `spike5-target.js` (the target), `spike6-touch-split.js` (two touch-sized
splits, by finger), `review.html` (the probes' pictures), `storyboard.js` + `make-how-page.js` →
`how-it-will-look.html` (the target as a storyboard).

**Memory** (`~/.claude/projects/-Users-davidedellacasa-code-Fizzygum-all/memory/`):
ask-before-commit-push, clean-minimal-uniform-architecture, prefers-reuse-and-breadcrumbs,
plans-must-be-fully-self-contained, ratchets-must-not-dictate-design,
no-chronological-notes-in-nonchronological-docs, local-html-for-visual-reviews,
byte-identical-not-sacred-for-benign-inspector-recapture, fizzygum-macro-test-system.

---

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] U1: the member reference (`MemberRef`, `ClassMemberRef`) under today's inspectors, no pixel change — CLOSED 2026-11-24 (inspector-overhaul loop, U1): the two classes landed under the old inspectors, each inspector class choosing its ref (`_memberRefOf`); presuite's failing set empty as predicted, no reference changed.

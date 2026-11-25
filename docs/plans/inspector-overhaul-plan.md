# Inspector overhaul: one tool, a row of inspectors, each one a small composed widget

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
**STATUS: IN EXECUTION since 2026-11-24** (authored and spiked that day; §6's table says which units have
landed, and each landed unit's paragraph says what it corrected here). Every fact in §1 and §7 was read off the tree at
Fizzygum `f7aed9e0` / Fizzygum-tests `e78dc3e50` (471 SystemTests) on 2026-11-24, but the test names, counts and
rig numbers §7 gives as U2 left them; §5 states the target as U2 built it, and what U4 is to add. Line numbers drift:
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

*(Written before U2: "today" in this section is the tree the plan started from (§1); §5 is the tool as built.)*

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
7. **A split has two controls, both always there** (owner, 2026-11-24). Before U1b the splitter was a
   5 px strip (laid out at 6 where its leading edge rounds up) with a small dark bar on it: no finger's target (the house rule is 44 × 44 for every
   chrome target, drawn as big as it is, `visual-design-system.md` §4.2), and its mark reads as a
   scroll bar's thumb beside a list's bar. So:
   - **the divider**, the mouse's control: slightly thicker, showing grip dots;
   - **the split button**, the finger's control: 44 × 44, at the left end of the header of the
     inspector on the divider's right, a double arrow (a finger icon on it, so it says what to do, is
     U3b's, which the owner ruled on 2026-11-24 is not run in the loop that built U2: the button ships
     with the double arrow alone).
   Both are present whatever pointer is in use, because some devices have both. Nothing in the
   layout reads the pointer, so "one geometry serves mouse and finger alike" (`Theme.coffee`,
   program ruling G1) holds as it stands (§5.10).

### 0.4 Owner decisions

Ask the owner the OPEN ones at the start. On "go", use the defaults. The inspector-overhaul loop took every
default (its prompt: "use the defaults"), and each row below says how it stands now.

| # | Decision | Status |
|---|---|---|
| D1 | One tool: "Inspect" opens the row of inspectors; the old inspectors are deleted | **LOCKED** (owner, 2026-11-24) |
| D2 | Decompose into member list + member editor; the object/class split in a member reference | **LOCKED** (owner, 2026-11-24) |
| D3 | The row (pager) is the core shape | **LOCKED** (owner, 2026-11-24) |
| D4 | A drill that does not fit **widens the window**, no further than the desktop's right edge; past that the inspectors narrow. Nothing is dropped from the left | **Default taken**, built (§5.4): the window widens by the missing least width, as far as the desktop's right edge (the alternative, horizontal scroll, needs new viewport code: §10) |
| D5 | **One class chip per inspector** (an object's class; a class's superclass) in the header, in place of the whole breadcrumb. Walking up the chain is one click per class, each a new inspector | **Default taken**, built (§5.5). A wrapping breadcrumb cannot be a stack band (its height would depend on its width), and each class is its own inspector anyway |
| D6 | The four filter toggles (Methods, Fields, Inherited, Own props only) keep their meaning and their look, in the member list | **Default taken**: unchanged (§5.6). The parked BACKLOG question on what "Inherited" hides stays parked |
| D7 | **Rename… and Remove sit with Add… under the member list**; Save sits under the editor | **Default taken**, built, Duplicate… among them (D15; §5.6). The list then owns every gesture that changes the member set, and no inspector has to refresh another |
| D8 | **No resizer of its own for a row with no window.** Its two hooks and their readers are deleted (§6 U2.2) | **Default taken**: U2.2 deleted the two hooks and their readers. Nothing in the product makes a windowless inspector any more (a drill used to); one picked out of its window resizes by the halo, as any widget |
| D9 | Starting window **760 × 480** (before U2: 560 × 410) | **Default taken**: `InspectorRowWdgt`'s constructor states it (two inspectors at their least widths, 663 together, fit its 758 px row) |
| D10 | One window title for every subject: **"Inspector — <name>"** (before U2: "Object Inspector — …" / "Class Inspector — …") | **Default taken**, built (`InspectorWdgt.colloquialName`; the window takes its row's first inspector's) |
| D11 | **A split's two controls, both always present** (owner, 2026-11-24, final): the divider slightly thicker with grip dots, for a mouse; and a 44 × 44 button in the header of the inspector on its right, a double arrow (with a finger icon once U3b draws one), for a finger. Both are there at all times, because some devices have both a mouse and a touch screen (§5.10) | **LOCKED**. Details as built: the divider 12 px with a 2 × 4 dot field (U1b); the button shows the double arrow alone: the owner ruled on 2026-11-24 that U3b, the finger icon, is not run in the inspector-overhaul loop, so it stays this plan's open item and the plan stays in `docs/plans/` at U5 |
| D12 | Second phase (U4): the first object-list views, **Children**, **Instances**, **Subclasses**, and the view chooser they need | **Default taken**: build (U4). Senders, implementors and protocols stay out (§11) |
| D13 | Commits | Per house rule, **ask before every commit and push**. At the start, ask whether this plan gets a standing grant ("commit and continue while gates pass; ask before push"). The inspector-overhaul loop runs under its prompt's grant: commit and push each unit after its green gauntlet |
| D14 | The dotted divider is the look of **every** division stack's splitter (the halo's layout adjusters, "Edit layout"), not a look of the inspector's own | **Default taken**, landed in U1b: one splitter class, one look. It recaptured the five tests that photograph a splitter (18 shots; the grep of U1b step 4 names 23 sources, ten of which build one) |
| D15 | **Duplicate…** beside Add… Rename… Remove (owner, 2026-11-24): a copy of the selected member under a new name | **LOCKED** for members; built in U2 (§5.3 b, §5.6). Its detail as built, the default: a duplicated field that holds an object holds the SAME object (a copy of the slot, not of the thing). Duplicating a class waits for class-level verbs (§11) |
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
3. **Read the code this plan built and builds on**, whole: every file in `src/meta-tools/` (the tool as
   U2 built it, §5), `src/CodeAreaWdgt.coffee`, `src/ScriptWdgt.coffee`, `src/ListWdgt.coffee`,
   `src/StackLayoutEngine.coffee`, `src/DivisionStackLayoutSpec.coffee`,
   `src/StackElementsSizeAdjustingWdgt.coffee`, `src/PromptButtonsRowWdgt.coffee` (the house's model of a
   small row widget), and the block "THE INSPECTOR'S TWO LOCATORS" of `src/macros/MacroToolkit.coffee`. The
   two inspectors U2 deleted, which §1 and §12 read against, are at Fizzygum `f7aed9e0`
   (`git -C <Fizzygum> show f7aed9e0:src/meta-tools/InspectorWdgt.coffee`, and `ClassInspectorWdgt.coffee`).
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

## 1. The state the plan started from (verified 2026-11-24)

This section describes the tree as it stood when the plan was authored (Fizzygum `f7aed9e0`), before U2
replaced the two inspectors with the tool of §5 (U1 had moved the edit steps and a member's text into
`MemberRef` / `ClassMemberRef`, §6 U1, "Landed"). It is kept as the record the move map (§12) reads
against: the two inspectors of §1.1 exist no more, and the tool as built is §5.

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

*(Written before U2: "today" in this section is the tree the plan started from (§1); §5 is the tool as built.)*

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
| Can a band be a horizontal division stack of its controls? | **Yes**, with three facts to respect: (1) **a band is as tall as its tallest child**, not as tall as its own box says (a container with division children derives its box from them, `Widget._getRecursiveStackDim`), so a band's GAPS are made as tall as the band; (2) controls are fixed at their own `preferredExtent()` with `crossAlign` 'center'; (3) a **spring** takes the slack. A fourth the spike did not reach, read off the engine by U2's research: a FIXED piece pins its MOST size too (least = desired = most, spreadability 0: `SPREADABILITY_NONE` still leaves a tenth of the desired size to take slack, and a piece that takes slack wobbles a px as the band's width changes), the band's own height included |
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

| Class | Is | Replaces | Lines (as built, comments included) |
|---|---|---|---|
| `InspectorRowWdgt extends ClippingWdgt` | the tool: a window's content (or a widget with no window), inspectors side by side, a splitter between two, derived from them; where a choice goes, a split a person set kept across it; widening on the desktop; it clips its children to its box | the welded body, `inspectMemberValue`'s windowless inspector, `openClassInspector`'s window | 267 |
| `InspectorWdgt extends Widget` | ONE subject (`inspectedObject`), one view: a header band (name, class chip; a split button while a splitter stands before it), the view (a chooser band when the subject has more than one view is U4's) | `InspectorWdgt` (rewritten whole), `ClassInspectorWdgt` | 239 |
| `MemberListWdgt extends Widget` | the view of an object's members: filter toggles, the list, a cut notice, Add… Duplicate… Rename… Remove | the inspector's left half | 494, moved |
| `MemberEditorWdgt extends CodeAreaWdgt` | the view of one member: its source or value as text, Save | the inspector's right half | 105 |
| `MemberRef` | one member of one holder: its text (`shownText`), the edit steps, and three questions about a holder (`of`, `canEdit`, `codeReceiverOf`) | the inspector's edit hooks and `_paneTextOfMember` | 190, moved (U1) |
| `ClassMemberRef extends MemberRef` | a member of a class's prototype | `ClassInspectorWdgt`'s overrides | 120, moved |
| `BandWdgt extends Widget` | a row of controls at their own sizes, gaps between them, ONE taker of the slack (a spring, or a text that gives), a rule along one edge | `_layOutTogglesIn`, the header's and the footer's hand placement | 122 |
| `BandSpaceWdgt extends Widget` | a band's gap or spring, or the place a view left in its inspector: paints nothing, may be 0 wide, hidden from the hierarchy menu | (new) | 39 |
| `SplitGripWdgt extends LayoutChromeWdgt` | a 44 × 44 grip in an inspector's header that drags the splitter before that inspector: the touch-sized way to move a split (D11) | (new) | 76 |

Deleted files: `ClassInspectorWdgt.coffee`, `BreadcrumbSeparatorWdgt.coffee`. In core U2 added
`Widget.duplicateOwnProperty`, `ListWdgt.clearSelection`, `CodeAreaWdgt._hasAFooterBand`, the splitter's solve as a
query (`StackElementsSizeAdjustingWdgt.maxDimsPuttingMyLeadingEdgeAt`, §5.10), the resize-cursor hover trio on
`LayoutChromeWdgt` (behind `_resizeCursor`), and `DivisionStackLayoutSpec.maxFor(desired, spreadability)`, the ONE
statement of a division box's most-size arithmetic (`desired + spreadability·desired/100`), which
`Widget.setMinAndMaxBoundsAndSpreadability` writes its two most sizes through and an inspector reads its default most
width by (§5.5). A widget joins a division stack along the axis its cells already run, whether attached
(`Widget.newParentChoiceWithHorizLayout`, "Attach with horizontal layout") or dropped on an "Edit layout" slot
(`LayoutElementAdderOrDropletWdgt`: the dropped widget and the new slot beside it take the slot's axis): an inspector
and a member list are columns.

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
InspectorRowWdgt                         paints the body fill, clips its children; x-division
  InspectorWdgt                          y-division
    BandWdgt (header)                    x-division: 12, title (gives: the band's spring), chip, 12; rule at bottom
    [BandWdgt (chooser)]                 only when the subject has more than one view (U4)
    MemberListWdgt                       y-division, takes the slack
      BandWdgt (toggles)                 12, toggles 8 apart, SPRING, 12; rule at bottom
      ListWdgt                           takes the slack
      [BandWdgt (cut notice)]            12, notice (gives), 12; rule at top; only when an indexed subject's items are cut
      [BandWdgt (footer)]                12, Add… Duplicate… Rename… Remove 8 apart, SPRING, 12; rule at top;
                                         only when the subject's members are edited (MemberRef.canEdit)
    [BandSpaceWdgt (viewsPlace)]         in the view's place, only while a person has taken the view out
  StackElementsSizeAdjustingWdgt         the splitter, 12 across
  InspectorWdgt
    BandWdgt (header)                    x-division: SplitGripWdgt, 8, title (gives)[, chip], 12
    MemberEditorWdgt                     a CodeAreaWdgt: code area + its own footer band (none when no Save edits the member)
```

Measured on the built tool, dpr 1 and 2 alike: a member-list inspector's least / desired width is 371 / 372 (364 /
365 on a subject with no footer), an editor's 280 / 280, the splitter 12. In the 760 × 480 window the row is
758 × 391 and the default split 372 | 12 | 374; two member lists share the spare evenly (373 | 12 | 373); a
list-and-editor row's least width is 663, a list alone 371. Every band keeps its height at any window size (header
44, toggles 48, footer 52), and a change of the window's height goes all to the list or the code area.

### 5.3 The three protocols

**(a) A choice.** Anything in an inspector that stands for another subject tells the row:

```coffee
  # WHERE A CHOICE GOES. `chooser` -- an inspector, or a view inside one -- chose `subject`: the
  # inspector right of the chooser's shows it. Chosen again, the subject already there is RELOADED
  # (a member's editor takes its saved text back, as one step of its undo history); any other
  # subject replaces it, and everything further right goes either way. No subject (undefined) only
  # removes what stands right of the chooser: what its view stood for has gone, or it chose a row
  # that names no member (MemberListWdgt.selectionFromList).
  #   A chooser in no row -- an inspector or a view a person picked out of its window -- opens the
  # subject in a window of its own, a row of its own.
  #   Every gesture asks me AFTER its own settle, never inside it (asked inside an open settle on a
  # row in the world, a choice throws): my row settles once per choice.
  @showChoice: (chooser, subject) ->
```

Who calls it: a member row's click (`MemberListWdgt.selectionFromList(name)` → the `MemberRef`), a
row's double-click (`inspectMemberValue(name)` → the member's VALUE, when it is an object), the
header's chip (→ the class's prototype), a re-filter by a filter toggle or by an edit of the member set
(→ undefined), and in U4 a view switch (→ undefined) and a row of an object list. A row that names no
member (a list's placeholder "(empty)", or a member gone since the list was built: `MemberListWdgt._memberNamedBy`)
is a choice of NO subject (→ undefined): what stood right of its list goes.

"The same subject" is identity, except that two `MemberRef`s naming the same member of the same
holder are the same subject (`MemberRef.sameMemberAs`). That exception is what keeps the rule
"clicking the selected row again puts the saved source back over unsaved typing, and undo brings
the typing back" (the test `macroFormulaBarUndoStaysInItsEdit`, and `input-and-gestures.md`, the
keyboard family). An inspector shows a subject only while its view stands in it
(`InspectorWdgt.showsSubject`): one whose view a person took out is replaced by a fresh inspector when its
subject is chosen again.

**(b) An edit.** Every edit is one step of a `MemberRef`, and each step makes the edit, records it
where a snapshot needs it, and tells once:

| Step | `MemberRef` (an object's member) | `ClassMemberRef` (a class's member) |
|---|---|---|
| `add()` | `holder.addOwnProperty name` | `class.applyMemberEdit name, "undefined"` + `recordClassEdit` |
| `save(text)` | `holder.injectProperty name, text`; a function is recorded with `recordInstanceEdit` | `class.applyMemberEdit name, text` + `recordClassEdit` |
| `duplicate(newName)` | `holder.duplicateOwnProperty name, newName`, the instance edit protocol's verb beside `renameOwnProperty` in `Widget.coffee`: the new name holds the same value, and an injected method is injected again under the new name from its kept source (a function with none is copied as the slot) | `_editCopyUnder newName, "duplicate"`: an edit under the new name of the member's recorded source (`_editClassMember newName, source`), refused through `world.inform` when the class holds no source for what the member holds now |
| `rename(newName)` | `holder.renameOwnProperty name, newName` | the same copy (`_editCopyUnder newName, "rename"`), then `_removeClassMember name`: ONE path makes the copy; refused, with `world.inform`, when the class holds no source for what the member is now |
| `remove()` | `holder.removeOwnProperty name` | `class.removeMember name` + `recordClassMemberRemoval` |
| the one notice | `holder.sourceChanged()` | `world.noteCodeChanged()` |

These are the old inspectors' bodies, moved (§12 gives the map; U1 landed all but `duplicate`), plus `duplicate` (D15), which is what a class rename already did before it removed the old name. ⚠ A gesture tells ONCE (`macroInspectorEditTellsOnce` counts it): a class `rename` built on a PUBLIC, notifying `duplicate` would tell twice, so the copy the two share is a step of its own that does not notify (`ClassMemberRef._editCopyUnder`, which answers whether it made the copy), and each of `duplicate` and `rename` ends in the one notice. Every step ANSWERS whether it made its edit: an object's always answers true; a class's `duplicate` or `rename` that is refused answers false, changes nothing and tells no one. Nothing records an object member's duplicate or rename (a copied method rides a save as its own `{"$src"}`). The widgets keep the gesture logic: prompts,
refusals of `constructor` and of a name the subject already owns (Duplicate…), enabling, re-filtering; and the
gesture of a refused step neither re-filters nor drops its choice.

**(c) Who refreshes.** Only the member list changes the member SET (add, duplicate, rename, remove: D7,
D15), and it re-filters itself and then, after its own settle, tells the row there is no choice any more; a
filter toggle does the same, since a re-filter's fresh list selects nothing. A Save changes no set and
refreshes nothing. No inspector reaches into another.

### 5.4 `InspectorRowWdgt`

```coffee
# The ROW OF INSPECTORS a window holds: the first on the subject a person asked to inspect, each
# next one on a subject chosen in the one to its left (showChoice). I am the inspector as a tool:
# "Inspect" opens me (Widget.spawnInspector).
#   I have no layout of my own. My inspectors are the elements of a horizontal DIVISION row
# (StackLayoutEngine), a splitter between two of them (StackElementsSizeAdjustingWdgt), so they
# divide my width, a person drags a splitter -- or the split button right of it (SplitGripWdgt) --
# to re-divide it, and my least width is theirs and my splitters' together
# (Widget.getRecursiveMinDim). I paint the body every inspector of mine stands on
# (inspectorBodyFill); they paint only their rules. I CLIP my children to my box, the house way (a
# ClippingWdgt): squeezed below my least width, a member editor's footer still places its Save at
# the button's own size, past an editor narrower than that, and I am what cuts it, in a window or
# with none.
class InspectorRowWdgt extends ClippingWdgt

  constructor: (subject) ->
    super()
    # a row built with no window gives itself a usable extent, and Widget.spawnInspector opens my
    # window at this same extent: one place states it
    @__commitExtent new Point 760, 480
    @color = WorldWdgt.theme.inspectorBodyFill
    @appearance = new RectangularAppearance @
    @_buildAndConnectChildren subject        # its core adds my first inspector

  # my inspectors, left to right: my children that are inspectors (my other children are splitters,
  # or not mine to arrange)
  inspectors: ->
    (child for child in @children when child.showsSubject?)

  colloquialName: ->
    @inspectors()[0]?.colloquialName() ? "Inspector"

  @showChoice: (chooser, subject) ->
    inspector = chooser
    inspector = inspector.parent  until !inspector? or inspector.showsSubject?
    row = inspector?.parent
    if row?.showNextTo?
      row.showNextTo inspector, subject
    else if subject?
      fresh = new InspectorRowWdgt subject
      world.openFrameWith fresh, fresh.extent(), world.hand.position().subtract new Point 50, 100
    return

  # one settle per choice, the widening inside it
  showNextTo: (inspector, subject) ->
    @_settleLayoutsAfter => @_showNextToNoSettle inspector, subject

  # THE SPLIT A PERSON SET stays across a choice. A drag TRADES most width between the two cells
  # beside a split, their sum unchanged, so across the boundary a choice removes everything right of,
  # exactly one trade stands: what the removed inspectors gave away, summed (their trades among
  # themselves cancel). ONE heir settles it (_removeInspectorsNoSettle): a fresh inspector whose view
  # asks the weight the first removed one's asked takes its default less that trade, and the split
  # stands; otherwise the chooser gives it back, and the default returns; a subject chosen again, the
  # kept neighbour.
  _showNextToNoSettle: (inspector, subject) ->
    following = @_inspectorsAfter inspector
    if subject? and following[0]?.showsSubject subject
      @_removeInspectorsNoSettle following[1..], following[0]
      following[0]._reloadNoSettle()
    else
      fresh = new InspectorWdgt subject  if subject?
      sameKind = fresh? and fresh.view.rowSlackWeight() is following[0]?.view.rowSlackWeight()
      @_removeInspectorsNoSettle following, (if sameKind then fresh else inspector)
      @_addInspectorNoSettle fresh  if fresh?
    @_widenMyWindowToFitNoSettle()
```

The rest, in words (each written in the house voice, with its comment):

- **`_addInspectorNoSettle(inspector)`** adds it right after my last inspector (`atIndex:`; a halo's handle or
  a widget attached to me may stand after it) with `layoutSpec: inspector.divisionBox()`, then reconciles my
  splitters.
- **`_removeInspectorsNoSettle(inspectors, heir)`**: while they still stand, sums what they gave away
  (`InspectorWdgt.mostWidthGivenAway`: each one's default most width less its own) and has `heir` give that up
  (`_giveUpMostWidthNoSettle`), writing nothing when the sum is 0, as it always is with no drag; then destroys each
  (`_fullDestroyNoSettle`), and each tells me it left (`_reactToChildRemoved`), which reconciles. **The split a
  person set** follows (the comment above `_showNextToNoSettle`): it stays across every choice that puts a view of
  the same kind (the same `rowSlackWeight`) right of it, and the default returns when another kind takes that
  place, or none does. A "Pick up" or a Destroy of an inspector reaches no choice and re-boxes nothing: the
  neighbour it leaves keeps its box. Measured, by mouse on the splitter and by touch on the split button alike:
  372 | 12 | 374, a drag of +47 → 419 | 12 | 327, kept across other members chosen and the same member chosen
  again; from there a double-click on an object-valued member puts its value's list there at 376 | 12 | 370 (the
  default for a list beside a value's list); a member again, 372 | 12 | 374; a filter toggle then a member,
  372 | 12 | 374.
- **`_reconcileSplittersNoSettle()`** is the ONE rule. **Splitters:** exactly one between two consecutive
  inspectors, none anywhere else, read over my CELLS (`_myCells`: my inspectors and my splitters, in order; any
  other child, a halo's handle, a widget attached to me, an "Edit layout" adder, is left where it is): destroy a
  splitter that is first, last, or follows another splitter (`_dropStraySplittersNoSettle`); add one
  (`new StackElementsSizeAdjustingWdgt`, `divisionBox()`, `atIndex:`) between two inspectors that touch
  (`_addMissingSplittersNoSettle`). A splitter of mine is recognised from STRUCTURE (`_isMySplitter`): a division
  cell that answers the split's solve (`maxDimsPuttingMyLeadingEdgeAt?`, the one question its split button asks
  of it); never by `instanceof`, nor by `nonFloatDragging?` or `ownsDragsStartingOnMe`, which handles, palettes,
  frame bars, grips and slider buttons answer too (a row under "Resize/move…" has the halo's handles among its
  children, and a palette dropped on an "Edit layout" slot of mine is a cell). **Split buttons:** then every inspector re-derives its own
  (`InspectorWdgt._reconcileSplitGripNoSettle`, §5.5), so an inspector carries one exactly while a splitter stands
  before it among my cells (**`splitterBefore(inspector)`**, which its split button asks). **Title:** last, when my
  first inspector is another one than my name was last taken from (`_inspectorNamingMe`), the window whose content
  I am re-titles itself from my name, my first inspector's (`FrameWdgt.noteContentsNameMayHaveChanged`): a "Pick
  up" of my first inspector changes it; while it is the same one, a title something else gave that window (a
  shortcut's) stands. The reconcile runs
  under a flag (`_reconcilingSplitters`, in a try/finally): the splitters it destroys tell me they left, and must
  not reconcile again inside it. Nothing here reads the pointer. "Edit layout" on a row puts adders around its
  cells, and each choice leaves behind the adders that flanked a destroyed inspector, the window widened by their
  width: as built, an open question for the owner.
- **`_reactToChildRemoved(child)`** returns while I am destroyed, while I am destroyed whole
  (`_beingFullDestroyed`, set at the entry of my `_fullDestroyNoSettle`, as `FrameWdgt`'s flag) and while my
  reconcile runs; otherwise a child that LEFT me (neither destroyed nor back in me: a person's "Pick up", an
  "Attach", a drop into another widget) re-derives its split button where it now stands
  (`child._reconcileSplitGripNoSettle?()`), and my splitters are reconciled. A splitter a person destroys is put
  back at once.
- **`_widenMyWindowToFitNoSettle()`** runs inside the choice's one settle (the end of `_showNextToNoSettle`),
  never in a layout pass: `missing = @getRecursiveMinDim().x - @width()` (division boxes are fields, so my least
  width is current inside the settle that added an inspector); if positive, and my parent is a window whose content
  I am (`@parent?.isMyContents? @`) and which stands on the desktop (its parent is the world, so its bounds are the
  desktop's own px), widen it by
  `Math.min missing, Math.max(0, world.right() - @parent.screenBounds().right())` through the frame's own core
  (`_setExtentNoSettle`: a public `setExtent` would be a second settle). In any other holder (a window in a panel, a
  document or a dock, a docked band, a transform island, no window) I am not widened and my inspectors narrow
  (measured: a window in a panel stays 500 wide where the same window on the desktop widens by the missing 165). A
  widening gives exactly the missing LEAST width, so a third inspector's editor lands at its least 280 even where
  the desktop has room to spare, and the row then stands at its least width, below its desired, outside the regime
  in which a split moves (§5.10), so every split of it is inert until the window is made wider: as built, an open
  question for the owner. Nothing stops a window being made narrower than my least width (by its
  grip, or by a document's column cap, which the window keeps after it leaves): the division row then shrinks
  every cell below its own least, buttons narrower than their labels: as built, an open question for the owner.
- **No `readsClassMemberMaps` here**: I read no member map. The classes that do declare it (§5.5–5.6).

### 5.5 `InspectorWdgt`

```coffee
# AN INSPECTOR: one subject (inspectedObject), and one VIEW of it. In a row of inspectors
# (InspectorRowWdgt) I am one column: my subject was chosen in the inspector to my left, and what is
# chosen in me goes to the one on my right (InspectorRowWdgt.showChoice).
#   Top to bottom, the elements of a vertical DIVISION stack: my HEADER band -- my subject's name,
# and a chip naming the class it is made by, whose press chooses that class -- and my VIEW, which
# takes the rest: a member's editor (MemberEditorWdgt) when my subject is one member of an object (a
# MemberRef: it answers editsAsAMember), the list of my subject's members (MemberListWdgt) for
# anything else.
class InspectorWdgt extends Widget

  # the object I am a view OF, and deliberately not called `target` (that means information flow or
  # a tracked reference edge elsewhere). My FIRST own field, assigned before my base constructor writes any other, so every walk of
  # me meets it first (a save's refusal names the path it took: `(InspectorWdgt#N) → .inspectedObject`)
  inspectedObject: undefined
  # a file holding me needs the class member maps before I am restored (Deserializer._needsTheReflectiveLayer)
  readsClassMemberMaps: true
  header: undefined
  headerTitle: undefined
  classChip: undefined
  # the widget showing my subject: a member editor or a member list
  view: undefined
  # does my header open with a split button? Derived from where I stand (_reconcileSplitGripNoSettle)
  showsSplitGrip: false
  # the PLACE my view left in me, while a person has taken it out (below)
  viewsPlace: undefined
  # am I being destroyed whole? Then my view leaving me is my teardown, and no place is kept
  _beingFullDestroyed: undefined

  # my own division box, stated ONCE (_defaultBox): least = desired = 1 x 1, and my view's WEIGHT of my
  # row's spare width (rowSlackWeight) times a spacer's spreadability, which makes my most width
  constructor: (@inspectedObject) ->
    super()
    @_buildAndConnectChildren()
    {least, desired, spreadability} = @_defaultBox()
    @setMinAndMaxBoundsAndSpreadability least, desired, spreadability

  _defaultBox: ->
    one = new Point 1, 1
    {least: one, desired: one, spreadability: @view.rowSlackWeight() * DivisionStackLayoutSpec.SPREADABILITY_SPACERS}

  # the most width I gave away across the splits beside me: my default box's less my own box's (0 with
  # no drag, negative where I gained), read through the box's one arithmetic (DivisionStackLayoutSpec.maxFor)
  mostWidthGivenAway: ->
    {desired, spreadability} = @_defaultBox()
    (DivisionStackLayoutSpec.maxFor desired.x, spreadability) - @_divisionBoxOrDefaults().maxWidth

  # my most width less `width`, given up across a split as a drag trades it (my row's choice names ONE
  # heir to do it: §5.4). Only my width: a row divides its width. A core my row calls inside its settle
  _giveUpMostWidthNoSettle: (width) ->
    box = @_divisionBoxOrDefaults()
    @_setMaxDimNoSettle new Point (box.maxWidth - width), box.maxHeight

  _buildAndConnectChildrenNoSettle: ->
    @_buildHeaderNoSettle()
    @view = if @inspectedObject?.editsAsAMember?() then new MemberEditorWdgt @inspectedObject else new MemberListWdgt @inspectedObject
    @_addNoSettle @view, layoutSpec: @view.divisionBox('y')

  # my subject, or the same member made again as a new reference -- and only while my view stands in me
  showsSubject: (subject) ->
    return false unless @view?.parent is @
    subject is @inspectedObject or (@inspectedObject?.sameMemberAs? subject) is true

  # my subject chosen again: my view takes it back -- an editor puts its member's text back, a list drops
  # its choice (both views answer). A core: my row calls it in its settle
  _reloadNoSettle: ->
    @view._reloadNoSettle()
    return

  colloquialName: -> "Inspector — " + @_subjectName()

  # a class is named as DATA, by its class's name; anything else through the service
  _subjectName: ->
    if isAClassPrototype @inspectedObject then @inspectedObject.constructor.name else Utils.colloquialNameOf @inspectedObject

  # The class my subject is made by: the first link ABOVE it on its prototype chain that is a
  # class's own prototype (it owns a `constructor` that is a function), unless that is Object. An
  # object's is its class; a class's prototype's is its superclass; a number's is Number. A member
  # has none: its holder's class is the inspector to my left's.
  _classAbove: ->
    return undefined  if @inspectedObject?.editsAsAMember?()
    link = Object.getPrototypeOf Object @inspectedObject
    until !link? or ((Object::hasOwnProperty.call link, "constructor") and Utils.isFunction link.constructor)
      link = Object.getPrototypeOf link
    link  if link? and link.constructor.name isnt "Object"

  # my chip's action. My view's own choice, if it shows one, is no longer what stands on my right
  chooseMyClass: ->
    @view?.clearChoice?()
    InspectorRowWdgt.showChoice @, @_classAbove()

  # the splitter that stands before me in my row, read off its cells each time; none anywhere else
  splitterBeforeMe: ->
    @parent?.splitterBefore? @
```

Build (inside ONE settle, children added with the NoSettle tier):

- header, built by ONE core (`_buildHeaderNoSettle`): `new BandWdgt theme.inspectorHeaderHeight,
  [theme.inspectorHeaderInset, {gives: @headerTitle}, chip, theme.inspectorHeaderInset], rule: "bottom"` (the two
  metrics are the old `breadcrumbBandHeight` 44 and `breadcrumbInset` 12 under the names §5.9 gives them), the chip
  only when `_classAbove()` answers. The title (`headerTitle`) is a `StringWdgt` of the subject's name in
  `theme.fonts.buttonLabel`, its ink `theme.inspectorHeaderTitle`, written as a text that GIVES (§5.8): it IS its
  header's spring, its box taking all the width the header's other pieces leave and running up to the chip, its
  text cropped with "…" where the box is narrower than it and standing at the box's start where the box is wider.
  Its length claims nothing, so there is no cap on a title: a header's least and desired widths are its other
  pieces' and the title's 5 px floor, and a long name widens no window and holds no split. The chip is
  `new ChipWdgt target: @, action: "chooseMyClass", face: link.constructor.name, current: true`.
- the split grip, DERIVED from where I stand and never told: **`_reconcileSplitGripNoSettle()`** asks whether a
  splitter stands before me (`splitterBeforeMe()?`); when `showsSplitGrip` (false as built) already says so, it
  does nothing; otherwise it RE-LEADS my header in place (`BandWdgt._replacePiecesBeforeNoSettle @headerTitle,
  lead`): every piece before the title gives way to `[new SplitGripWdgt, theme.inspectorHeaderGap]`, or to
  `[theme.inspectorHeaderInset]` alone. The title, the chip and the band stay the same widgets, and nothing made
  there settles as it is made. My row's reconcile runs it, and so do `_reactToBeingCopied` and
  `_afterDeserialization` (no class above me defines either, so neither calls `super`): an inspector copied or
  saved alone out of a row stands in none and sheds its grip; inside a copied or restored row the row's structure
  gives it back. A header or a title a person took out of me is not re-led. The header band is 44 tall and the
  grip 44 × 44, so the grip fills the band's height and its left end, over the band's rule.
- **`splitterBeforeMe()`** answers the splitter itself, from STRUCTURE, each time it is asked: my row's
  (`InspectorRowWdgt.splitterBefore`: the cell just before me, when it is one of the row's splitters), else
  undefined. Nothing stores a splitter: a grip can then never drag a splitter of a row its inspector is not in.
- view: built inline (U2 has no `_views` table: `editsAsAMember?()` decides), added with `divisionBox('y')`; its
  own box takes my slack (a spacer's spreadability), and it answers **`rowSlackWeight`**, my weight of my row's
  spare width: a member editor 100 (my most width 100,000,001 px), a member list 0.01 (10,001 px). So a list
  beside an editor lays out at exactly its desired width and the editor takes the rest, two lists share the spare
  evenly, and a split can move: a division row moves a split by trading the most widths of the cells on either
  side of it, and the split a person set stays across a choice that puts a view of the same kind on its far side (§5.4:
  the choice reads `mostWidthGivenAway`, and its one heir gives that up, `_giveUpMostWidthNoSettle`).
- **the view's place** (`viewsPlace`): when my view leaves me (picked out, carried off, binned, attached
  elsewhere, destroyed), `_reactToChildRemoved` keeps its PLACE, once: a `BandSpaceWdgt` spring desiring the width
  my view desired as my stack read it and 1 px tall, with a spacer's spreadability, right after my header.
  Without it my pinned header, alone in my stack, would take all my height (a division stack hands its spare by
  desired size when no cell has a margin), and my width would fall to my header's. The place claims no least
  width, so a row at least as wide as its inspectors desire lays out as it did with the view in, and a narrower
  one gives up the place's room before it squeezes a control. Not while I am destroyed whole, and not for a view
  that has not left (a transform island wraps it in place: `!@isAncestorOf child`). A member list destroyed whole (the dev
  menu's Destroy) answers after its own cells are gone, so its place is 1 px wide (an editor's keeps its 280). While my view is out,
  `showsSubject` is false, and a choice of my subject replaces me with a fresh inspector. A view picked out of me
  stands on no body (only the row paints one; my panes are transparent), its own shadow showing through it: as
  built, an open question for the owner.
- The chooser band, `_views` and `showView` are U4's (§6), with the fields they need (`chooser`, `viewToggles`,
  `shownViewTitle`); in U1–U3 every subject has one view and no chooser.

### 5.6 `MemberListWdgt` and `MemberEditorWdgt`

**`MemberListWdgt extends Widget`** — `constructor: (@inspectedObject)`; `readsClassMemberMaps:
true`; its own box 1 × 1 with a spacer's spreadability (it takes its inspector's slack; its least and desired
sizes are its cells'), and `rowSlackWeight: -> 0.01` (§5.5). A vertical division stack of: the toggles band
(`theme.toggleBandHeight`, `rule: "bottom"`: `toggleBandInset`, the toggles `toggleBandGap` apart, a spring,
`toggleBandInset`), the list, the cut-notice band (`cutNoticeBand`, only when `itemCount > items.length`:
`theme.inspectorHeaderHeight` tall, `rule: "top"`, `inspectorHeaderInset` at each end of a `StringWdgt` in
`fonts.buttonLabel` that gives, saying `_cutNoticeText()`: "The first N of M items are listed."), the footer band
(`footerBand`: `theme.footerBandHeight`, `rule: "top"`, `footerInset`, the four buttons `footerGap` apart, a
spring, `footerInset`; only when `MemberRef.canEdit @inspectedObject`). Every band ends with its inset, so its
least width keeps that inset clear right of its last control.

It keeps, under their present names, everything of §1.1's "Member set", "Filter" and the member
gestures: the four `showing*` fields and `toggleShowing*`, the four toggles, `_filteredMemberNames`,
`_subjectsItemsAndNames`, `@MOST_ITEMS_LISTED`, `@_isAnIndex`, `memberFactsOf`,
`_subjectsClassPrototype`, `_buildAndConnectMemberList`, `_refilterMembers`,
`_reflectFiltersOnToggles`, `_reflectMemberSelection`, `_selectedMemberCanBeRenamedOrRemoved`,
`addProperty`/`addPropertyPopout`, `renameProperty`/`renamePropertyPopout`, `removeProperty`,
`_refusesAsANewMemberName`, the three buttons. It gains **Duplicate…** (D15), shaped exactly as
Rename… is: `duplicatePropertyButton` between Add… and Rename…, enabled with Rename… and Remove
(`_reflectMemberSelection`); `duplicatePropertyPopout` prompts "name of the copy:" with the selected
name as its default; `duplicateProperty(newName)` refuses `constructor` (`_refusesAsANewMemberName`) and
any name my subject already OWNS, the selected one's included (it says "<name> is a member already: a
duplicate replaces no member" with `@inform`: a duplicate must not overwrite), calls the ref's `duplicate`,
and, when the step answers true, re-filters and tells the row there is no choice. With four buttons the
footer band's least width is 371 (desired 372) and the toggles band's 364 (365): the member list's least and
desired widths are 371 / 372, and 364 / 365 on a subject with no footer. Keeping the names is deliberate: the rigs and tests
of §7 then change WHERE they find a member, not what it is called.

What changes inside it:

- `selectionFromList(name)`: it reflects the selection on my buttons (`_reflectMemberSelection()`), then tells my
  row the choice: `InspectorRowWdgt.showChoice @, MemberRef.of(@inspectedObject, name)`, or, for a label that names
  no member of my subject (`_memberNamedBy`: the list's "(empty)" placeholder row, or a member gone since the list
  was built), NO subject: what stood on my right goes, and my buttons show nothing to act on. Every reader of a
  label of mine asks `_memberNamedBy`, the member buttons through `_selectedMemberName()`. (A clicked placeholder
  still wears the list's selection fill, `ListWdgt.select`'s own.)
- `inspectMemberValue(name)`: when the member's value is an object (`Utils.isObject`),
  `InspectorRowWdgt.showChoice @, value`. The first click of a double-click chooses the member, whose editor
  narrows a lone full-width list to 372 px, so a second click right of x 372 lands on the splitter or the editor
  and the double-click shows the member's editor, not its value (a double-click on the NAME is unaffected): as
  built, an open question for the owner. A function is an object too, so a double-click on a METHOD's row replaces
  its editor with an inspector on the function, a member list whose one row is "(empty)" (a click on the row
  brings the editor back): as built, an open question for the owner.
- **`clearChoice()`** and the list's **`_reloadNoSettle()`** are ONE act, "drop my choice": what stands on my
  right shows something other than my choice, or nothing, so `@list?.clearSelection()` (`ListWdgt.clearSelection`:
  `@selected = undefined`, then `@listContents.noteShownSelectionChanged()`, the two lines `select` opens with),
  then `_reflectMemberSelection()`. Two doors reach it: my inspector's chip pressed (`chooseMyClass` asks
  `clearChoice`, at the press) and my subject chosen again (my inspector's `_reloadNoSettle`, inside my row's
  settle, which removes what stood right of me), so the chip pressed again leaves the class's list on its right
  with no selection. Paint only, so a core both doors reach. The storyboard's frame 5 shows what happens without
  it: the row stays highlighted beside an inspector on something else.
- the four edits (`addProperty`, `duplicateProperty`, `renameProperty`, `removeProperty`) call the ref's step
  (`MemberRef.of(@inspectedObject, name).add()` …); when it answers true, `_refilterMembers()`, then, after that
  settle, `InspectorRowWdgt.showChoice @, undefined`. A step that answers false (a class's member with no source to
  copy) changed nothing, so the list keeps its selection and the row its choice.
- each `toggleShowing*` flips its field and re-filters inside ONE settle, then, after it,
  `InspectorRowWdgt.showChoice @, undefined`: a re-filter's fresh list selects nothing. Every gesture asks the row
  after its own settle, never inside it.
- a class's prototype builds no "Own props only" toggle: the build asks `isAClassPrototype @inspectedObject`
  where `ClassInspectorWdgt` overrode the builder.
- `_refilterMembersNoSettle` touches no code pane (there is none here): it builds the list again
  (`_buildAndConnectMemberList`: the old list, while still mine, destroyed and the new one in its place; a list a
  person took out stays where it is, and the new one stands before the cut-notice and footer bands), then reflects
  the selection and the toggles; every other child stays the same widget.
- the list wears the inspector's pane roles (`wearPaneRoles fill: "inspectorPaneFill",
  stroke: "inspectorPaneStroke"`), takes no drops (`disableDrops`; its contents neither), and has a box of its own
  (least `theme.minimumTargetSize` square, a spacer's spreadability: my stack's slack is its).

**`MemberEditorWdgt extends CodeAreaWdgt`** — `constructor: (@memberRef)`; fields `memberRef`, `saveButton`;
`readsClassMemberMaps: true`. Modelled on `ScriptWdgt`:

```coffee
  constructor: (@memberRef) ->
    super()
    theme = WorldWdgt.theme
    # my division box: a floor of my own, since I have no division children to derive one from
    least = new Point theme.inspectorEditorLeastWidth, theme.footerBandHeight
    @setMinAndMaxBoundsAndSpreadability least, least, DivisionStackLayoutSpec.SPREADABILITY_SPACERS
    @_buildAndConnectChildren()

  # my inspector's weight of its row's spare width (§5.5): nearly all of it, since code is what wants width
  rowSlackWeight: -> 100

  _buildAndConnectChildrenNoSettle: ->
    @_buildEditableCodeAreaNoSettle @memberRef.shownText()
    # dressed in the inspector's pane roles, so the row's body shows through me as through a member list
    @tempPromptEntryField.wearPaneRoles fill: "inspectorPaneFill", stroke: "inspectorPaneStroke"
    @textWidget.backgroundColor = WorldWdgt.theme.inspectorPaneFill
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
  # hand, and stays modified, Save still enabled (Widget._savingTypedCode). It asks MemberRef.canEdit
  # too, not only my build: a restored editor keeps the button its file holds.
  save: ->
    return false  unless @saveButton? and MemberRef.canEdit @memberRef.holder
    return false  unless @_savingTypedCode => @memberRef.save @textWidget.text.toString()
    @textWidget.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()
    true

  # my member's text again, over whatever is typed: one step of my undo history, so the undo chord
  # brings the typing back (InspectorRowWdgt.showChoice, the subject chosen again). A core: the row
  # calls it inside its one settle.
  _reloadNoSettle: ->
    @textWidget._setTextNoSettle @memberRef.shownText()
    @textWidget.pushUndoState @textWidget.text.length
    @textWidget.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()
    return
```

Three things it settles:

- **A read-only member has no footer band.** `CodeAreaWdgt` always kept a band, because each of its four other
  subclasses has buttons. The base has ONE derived question, `_hasAFooterBand`: did my build make a footer button
  at all (a button of my two groups, whether or not it is still my child: a band a person emptied by picking its
  buttons out stays), read by `_layOutOwnContents` (the code area runs to my bottom without one) and `_seamRects`
  (no rule without one). No subclass changed, and the four others keep their 52 px band.
- **The code area's floor.** In a division row an editor with one button derives no width of its own, so its own
  division box states one: least `theme.inspectorEditorLeastWidth` (280) wide and `theme.footerBandHeight` tall,
  a spacer's spreadability.
- **Its look.** The code area wears the inspector's pane roles, and its text the pane fill as its background,
  from the build on (the old `InspectorWdgt._clearPaneLook` is gone), so it stands on the row's body fill like the
  list.

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

**What U1 landed**: `holder`, `name`,
`@_recordedStaticSourceOf`, `shownText()` (the old `_paneTextOfMember`; not `text()`, which is a FIELD
of every text widget), `_fieldSource()` (the old `_sourceForFieldMember`), `canBeRenamedOrRemoved()`
(the old `_selectedMemberCanBeRenamedOrRemoved` without the selection read), `add()`, `save(txt)`,
`rename(newName)`, `remove()`, `_notifyOfEdit()`. `ClassMemberRef` overrides `_fieldSource`, the four
steps and `_notifyOfEdit`, with `_editClassMember` and `_removeClassMember` as its two helpers,
exactly as `ClassInspectorWdgt` had them. **What U2 added**, each with its first reader: the three statics
above (`of`: the member list's choice and its gestures; `canEdit`: the list's and the editor's builds and every
edit gesture; `codeReceiverOf`: `MemberEditorWdgt.codeReceiver`), `editsAsAMember` and `sameMemberAs`
(`InspectorWdgt`: its view, `_classAbove`, `showsSubject`), `colloquialName` (the header's title, through
`Utils.colloquialNameOf`), and `duplicate(newName)` on both classes, with `ClassMemberRef._editCopyUnder(newName,
verb)` the copy its `duplicate` and `rename` share (§5.3 b's warning: the copy is a step that does not notify).
Every step answers whether it made its edit (§5.3 b). A member reference IS held now: by a member editor
(`memberRef`) and, as its `inspectedObject`, by the inspector the editor stands in, so a copy and a world save
carry it as an ordinary object of its class (a snapshot restores each editor's `memberRef.holder` as the restored
subject).

⚠ No comment line of `MemberRef.coffee` may read ` extends <ClassName>`: the boot dependency scanner
(`src/boot/dependencies-finding.coffee`) reads that phrase anywhere on a line, a comment's included, as
"this file needs that class first", and its walk has no cycle guard. A `new X` inside a method body it
does not read, so `@of` above names both classes plainly.

The steps are public doors a widget calls, named for what they do (`add`, `save`, `rename`,
`remove`). (A consequence, not the reason: no member here is named `_apply…` or `_commit…`, a prefix
the tier-naming audit reads as a geometry corner: §7.3, `tier-naming-prelude.js`.)

### 5.8 `BandWdgt` and `BandSpaceWdgt`

```coffee
# A BAND: one row of controls across the widget that holds me -- an inspector's header, a member
# list's row of toggles, its row of buttons. I am `height` tall, my rule included, and as wide as I
# am given; my controls keep their own sizes, centred down me, in the order written, with the gaps
# written between them, and my spring -- or a text that gives, in its place -- takes the slack.
#   I have no layout of my own: every piece is an element of a horizontal DIVISION row
# (StackLayoutEngine). So my least width is my pieces' together, which the stack derives
# (Widget.getRecursiveMinDim), and the least width of whatever holds me follows from it.
#   An item is a widget (a control, fixed at its own preferredExtent, centred down me), a number (a
# gap that many px wide), BandWdgt.SPRING, or `{gives: aText}` (a line of text that gives way: it IS
# my spring). ⚠ A gap is as TALL as I am, and that is what makes me that tall: a division row is as
# tall as its tallest element, whatever its own box says; my own box pins my height too. A band
# written with neither a spring nor a text that gives gets a spring at its end: without one the slack
# would go to my controls. One written with both is refused at its build.
#   I paint nothing but my rule (SeamRulesAppearance): a line along my top or bottom edge, inside my height.
class BandWdgt extends Widget
  @SPRING: "spring"
  # the edge my rule lies along -- "top" or "bottom" -- or undefined for none
  ruleEdge: undefined
  # my height, my rule included: what my box pins, and how tall my gaps and my spring stand
  bandHeight: undefined

  constructor: (height, items, opts = {}) ->
    super()
    @bandHeight = height
    @ruleEdge = opts.rule
    @appearance = new SeamRulesAppearance @
    @setMinAndMaxBoundsAndSpreadability (new Point 0, height), (new Point 0, height), 0
    @_buildAndConnectChildren items        # ONE settle; every piece added with the NoSettle tier

  _seamRects: ->
    return []  unless @ruleEdge?
    thickness = WorldWdgt.theme.inspectorRuleWidth
    if @ruleEdge is "top"
      [new Rectangle 0, 0, @width(), thickness]
    else
      [new Rectangle 0, @height() - thickness, @width(), @height()]
```

- A control: `control.setMinAndMaxBoundsAndSpreadability extent, extent, 0` with
  `extent = control.preferredExtent()`: spreadability 0, never `SPREADABILITY_NONE`, which still leaves a tenth of
  the desired size to take slack (a "fixed" control would wobble a px as the band's width changes); and
  `control.divisionBox()._setCrossAlignNoSettle "center"` (the spec's public setters settle, and the band's build
  is a core).
- A text that gives (`{gives: aText}`): that `StringWdgt` itself as my spring, least = desired = its box's least
  width (`getMinimumExtent().x`, 5 px) by its one line's height (`linePitch` at the size it is set in), a spacer's
  spreadability: it takes all the width my fixed pieces leave, and its own fitting crops its text with "…" or
  stands it at the box's start. Its length is in none of my widths.
- A gap: `new BandSpaceWdgt px, height`. A spring: `new BandSpaceWdgt 1, height, springs: true`.
- **`_replacePiecesBeforeNoSettle(piece, items)`** re-leads me: every piece before `piece` destroyed and the
  pieces `items` write put in their place (gaps and controls: my one taker of the slack was written at my build).
  A core that settles nothing, for a holder's re-lead (an inspector's split button, §5.5).
- **`BandSpaceWdgt`** `constructor: (width, height, opts = {})`: no appearance (it paints nothing, as
  `PromptButtonsRowWdgt` paints nothing); `@minimumExtent = new Point 0, 0` in its constructor; a gap's box is
  least = desired = most = the size given, spreadability 0; a spring's least width 0, desired width **1** (never 0:
  §4's first hazard), spreadability `SPREADABILITY_SPACERS` (an inspector's view's place is the same spring down
  its stack: 1 px desired there, the view's desired width across); `hiddenFromHierarchyMenu: -> true`.
- A band and its spaces take no drops: `Widget`'s own answer, with no call (only the member list's `ListWdgt`
  needs `disableDrops`).

### 5.9 Theme, door, part

- **Theme (`src/Theme.coffee`).** Deleted, each with its last reader: `inspectorBreadcrumbCaption`,
  `inspectorBreadcrumbSeparator`, `breadcrumbGap`, `breadcrumbSeparatorSize`, `inspectorListColumnWidth`, and
  `footerGripClearance` (with D8). Renamed under names that say what reads them now: `breadcrumbBandHeight` →
  `inspectorHeaderHeight` (44), `breadcrumbInset` → `inspectorHeaderInset` (12; a member list's cut-notice band
  reads both too), `breadcrumbCaptionGap` → `inspectorHeaderGap` (8: the gap after the split button). New:
  `inspectorEditorLeastWidth` (280, a member editor's floor) and the role `inspectorHeaderTitle` (`ink`: the
  header title's). The comment above each inspector metric says what reads it. Colours stay Theme roles
  (`raw-chrome-color` is held at 0).
- **Door (`Widget.spawnInspector`).** Inside the same two awaits:
  `row = new InspectorRowWdgt inspectee` then
  `world.openFrameWith row, row.extent(), world.hand.position().subtract(new Point 50, 100)`.
  `inspectorClassFor` is gone: `MemberRef.of` makes the one decision it made.
- **Part.** No partition change: every new class lives in `src/meta-tools`. The `//` comment of the
  `meta-tools` entry in `buildSystem/parts.json` names the classes it holds, and `profiles/lean.json`'s prose the
  tool it leaves out.

### 5.10 The split's two controls (D11)

The splitter (`StackElementsSizeAdjustingWdgt`, core) stays the division element between two
inspectors and keeps the solve that moves a split, a closed form over the row's division boxes, exact at any event
cadence (read its long comment before touching anything near it). The solve is a QUERY,
`maxDimsPuttingMyLeadingEdgeAt(targetLeft)`: the two cells flanking the splitter and the most sizes the split asks
of them (`{before, beforeMax, after, afterMax}`), or undefined when nothing can move (no cell on one side, the row
outside its third regime, or nothing left once the move is clamped). Each drag handler that moves a split (the
splitter's own `nonFloatDragging`, the split button's) maps the raw pointer into its own plane on the line that
reads it, asks the query, and makes the two `_setMaxDimDeferredSettle` writes itself: one solve, two handlers, each
the mapper of its own pointer and the declared deferrer of its own stream. The solve clamps each neighbour at its
DESIRED width, so from the default split (a member list at its desired 372) a split moves right only, as far as the
editor's least 280. A split gets two controls, both always present, one look whatever the pointer:

**The divider, for a mouse** (U1b, landed). The splitter is `theme.layoutAdjusterThickness` across
(12) and its mark is a small field of the house's grip dots: the ones a toolbar band's strip shows
(2 px squares, `gripDotSize`, on a 6 px pitch, `gripDotPitch`), in `layoutAdjusterGripMark` (`muted`).
There is ONE dot field in the tree, `Appearance._paintGripDots`: the strip's appearance calls it over
its plate, and the layout chrome's appearance for a piece that DECLARES dots
(`LayoutChromeWdgt._gripDotsOnMyPlate`: their ink and the most of them along the long side; the
splitter answers `layoutAdjusterGripDotsAlong`, 4), so the field reads as a grip, not a texture. Per
D14 this is the look of every splitter, a change to the core class with no inspector in it.

**The split button, for a finger** (U2). A `SplitGripWdgt` in the header band of the inspector on
the divider's right asks that splitter's solve for the split its own drag means, so there is no second solve. An
inspector wears one exactly while a splitter stands before it (§5.4). A mouse may use it too. Measured: the divider
by mouse and the button by mouse and by touch each move the split by exactly the travel after the first move (a
chrome drag has no threshold), the button's left edge is the splitter's right edge after every layout, the window
never moves, and the cursor reads `col-resize` over both.

**The finger icon** (U3b; by the owner's ruling not run in the loop that built U2: §0.4 D11). The
button's face is to be a double arrow with a finger on it, so it says what to do; until then it shows the double
arrow alone. No finger or hand icon exists in `src/icons/`. Draw one as a size-aware icon with the
`/convert-icon-size-aware` skill of the umbrella (its probe, preview and owner-review loop), and
compose it with the double arrow in the grip's glyph. Until the owner has approved the icon the
button shows the double arrow alone; do not ship a stand-in drawing.

```coffee
# A SPLIT GRIP: the FINGER's way to move a split. I am a 44 x 44 piece of layout chrome (the 44
# rule, visual-design-system §4.2: a target that must be big is drawn big) standing at the left end
# of an inspector's header band, right of the splitter that stands before that inspector. The
# splitter itself is the mouse's way; we are both always there, since a device can have both. A drag
# on me moves that splitter's split exactly as a drag on the splitter does: the split's arithmetic is
# the splitter's own (StackElementsSizeAdjustingWdgt.maxDimsPuttingMyLeadingEdgeAt), and I only say
# where its leading edge should be.
#   I hold no splitter: I ask the inspector I stand in which one stands before it, as I am dragged
# (InspectorWdgt.splitterBeforeMe, read off its row's children), so a copy of me, or my inspector
# taken out of its row, drags nothing that is not its own.
class SplitGripWdgt extends LayoutChromeWdgt

  # my box is a chrome target's side square, fixed: my band holds me at my own size
  constructor: ->
    super()
    side = WorldWdgt.theme.minimumTargetSize
    extent = new Point side, side
    @__commitExtent extent
    @setMinAndMaxBoundsAndSpreadability extent, extent, 0

  # I am CHROME, as the splitter is: a drag that starts on me moves my split, at once, for a
  # finger as for a mouse (ActivePointerWdgt._touchPressArmsAtOnce), and it never lifts me out
  ownsDragsStartingOnMe: -> true
  detachesWhenDragged: -> false
  grabsToParentWhenDragged: -> false

  # MY GLYPH: the double arrow across, as a layout spacer's (LayoutChromeWdgt._glyphOnMyPlate)
  _glyphOnMyPlate: ->
    theme = WorldWdgt.theme
    [(new DoubleArrowIconAppearance @, theme.layoutChromeGlyph), theme.layoutSpacerGlyphSize]

  # my hover shows the cursor a row's splitter shows (LayoutChromeWdgt.hoverEntered)
  _resizeCursor: -> "col-resize"

  # the splitter before the inspector I stand in: the nearest container of mine that can say
  _mySplitter: ->
    holder = @parent
    holder = holder.parent  until !holder? or holder.splitterBeforeMe?
    holder?.splitterBeforeMe()

  # The split moves so that the splitter's LEADING EDGE lands where the pointer, less where I was
  # grabbed, less the splitter's own width says: I stand flush after it. That width is the one its
  # division BOX states (getDesiredDim), never the width it was laid out at (12, or 13 by the rounding
  # of the last layout pass, which would move the wanted edge by a px with how many moves a frame
  # drained: DETERMINISM.md's class). I read no laid-out position at all. A row divides its width,
  # so only x moves.
  nonFloatDragging: (grabPointInMe, pos, deltaDragFromPreviousCall) ->
    return unless deltaDragFromPreviousCall?
    splitter = @_mySplitter()
    return unless splitter?
    wantedLeadingEdge = (@screenPointToMyPlane pos).x - grabPointInMe.x - splitter.getDesiredDim().x
    split = splitter.maxDimsPuttingMyLeadingEdgeAt wantedLeadingEdge
    return unless split?
    # a drag-move STREAM, as the splitter's own: the deferred-settle entrypoint check-layering [O] allows here
    split.before._setMaxDimDeferredSettle split.beforeMax
    split.after._setMaxDimDeferredSettle split.afterMax
```

Notes, as built:

- This is the spike's variant C made a class (§4): there the relay was an instance override on a
  second `StackElementsSizeAdjustingWdgt`; here it is a class of its own, so nothing holds a function. The
  splitter's resize cursor on hover and its restore at the end of a drag (`hoverEntered`, `hoverExited`,
  `endOfNonFloatDrag`) are lifted to `LayoutChromeWdgt` behind one hook, `_resizeCursor` (undefined by default;
  the splitter answers by its axis, the grip `"col-resize"`): one copy of the cursor logic.
- The first shape, a one-line relay handing the raw `pos` on to `splitter.nonFloatDragging`, reads a raw pointer
  unmapped (`check-plane-discipline` C2, held at zero), and its fallback, a public method on the splitter making
  the deferred writes, puts `*DeferredSettle` calls outside a stream handler (`check-layering` [O]). The shape
  inside both rules is the shared QUERY above. [O]'s allowlist is keyed by the handler's name, `nonFloatDragging`,
  which covers three callers (`HandleWdgt`, the splitter, the grip), and its self-test's stale-allowlist plant
  covers `meta-tools/SplitGripWdgt.coffee`; the complexity record follows the solve
  (`'StackElementsSizeAdjustingWdgt#maxDimsPuttingMyLeadingEdgeAt': 18`, recorded at 19 as `#nonFloatDragging`).
- A row is horizontal, so only x moves. Do not generalise it to a vertical stack before a vertical
  client exists.
- The grip takes no drops, as every plain widget.
- An inspector COPIED alone out of a row (the context menu's Duplicate), or saved alone, stands in no row:
  `InspectorWdgt._reactToBeingCopied` and `_afterDeserialization` re-derive its split button from where it
  stands, so it sheds the grip (§5.5).
- `SplitGripWdgt` lives in `meta-tools` while the inspector is its only client. Every OTHER
  division stack's splitter has the dotted look (D14) and no finger's way to move it: U5 files
  that.
- A mouse can still press the 12 px divider a finger cannot take reliably; that is intended. The
  divider stays a pointer target for every pointer (a finger that does land on it moves the split).

---

## 6. Work units

| Unit | What | Gate at its end | Done |
|---|---|---|---|
| U0 | Orient, decisions, a green baseline | `fg presuite` | [ ] |
| U1 | `MemberRef` / `ClassMemberRef` under the OLD inspectors: no pixel changes | `fg gauntlet` | [x] 2026-11-24 |
| U1b | The divider's look: every division stack's splitter 12 px wide with grip dots (D11, D14) | `fg gauntlet` | [x] 2026-11-24 |
| U2 | The switch: the new widget classes, the door, the toolkit, 32 tests, the rigs, recapture | `fg gauntlet` + `fg homepage` | [x] |
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
   names the candidates (23 files on 2026-11-24, ten of which build a splitter and five photograph one); a splitter 7 px thicker also moves the cells beside it,
   and a test that drags one presses where it now stands. Write the set down BEFORE the suite; the
   failing set must equal it.
5. `fg presuite`; `fg diffpage` of the failing set and look: each changed shot is a dotted, thicker
   splitter and the cells it pushed. Then `fg build`, `fg recapture --auto --dprs=1,2`,
   `fg recapture --auto --pointer=finger --dprs=1,2`. `visual-design-system.md` (the layout chrome's
   look, §4.3 or wherever the adjuster is described: grep "adjuster") says what is true.
6. **Gate:** `fg gauntlet`.

**Landed 2026-11-24 (U1b of the inspector-overhaul loop).** Built as steps 1–6 say, with these corrections,
measured:
- **The splitter declares its mark and the appearance paints it.** Step 1's "`drawLayoutChrome` paints the
  dot field" would have had the widget's drawing tail reach back into its appearance for the shared routine;
  the layout chrome already has the declaration shape (`_glyphOnMyPlate`). So `LayoutChromeWdgt` answers
  `_gripDotsOnMyPlate` (none by default; the splitter: its ink and the most dots along its long side),
  `LayoutChromeAppearance` paints them inside its plate (kept `layoutChromeGripDotsInset`, the border and one
  clear pixel, in from its edge across the short side, the plate's rounding off its rounded ends along the long
  one, oriented by aspect as the bar was), and `drawLayoutChrome` is gone: the splitter was its one implementer. The two comments that cited it
  as a precedent cite `drawPlot` alone.
- **The one dot field is `Appearance._paintGripDots`** (with `_gripDotStartsAlong`), beside `_paintPlate`: the
  nearest home common to `FrameStripAppearance` and `LayoutChromeAppearance`. The strip calls it with its plate
  inset by `barGripMarkInset`; its dots stand where they stood (the inset is an integer: checked by arithmetic
  for every plate length, and held by the band-strip tests, which stayed green).
- **Theme:** `layoutAdjusterThickness` (12), `layoutAdjusterGripDotsAlong` (4) and `layoutChromeGripDotsInset` (2) in, the two
  `layoutAdjusterGrabMark…` metrics out; `barGripMarkDotSize` / `barGripMarkPitch` renamed `gripDotSize` /
  `gripDotPitch` (two readers); a role of its own for the dots' ink, `layoutAdjusterGripMark` (`muted`): the plan
  named none, and a role names one surface.
- **Facts corrected here:** the old strip's box was 5 × 5 and laid out at 5, or 6 where its leading edge's
  fraction rounded up (the spike's row landed on 6); at 12 it lays out 12, rarely 13. Step 4's grep names 23
  files, not 16; ten build a splitter; FIVE photograph one.
- **The plate's ends** round at half its thickness now (the plate's own rule: `min(radius, half the short
  side)`), as the storyboard shows them.
- **Pixels:** the predicted set was written first, by reading and by a prototype suite run, and the failing set
  equalled it under mouse and under finger: `macroLayoutSpacerEatsSpareSpace` (2 shots),
  `macroLayoutsAndCollapsing` (5), `macroLayoutsAndVisibility` (5), `macroStackDividerReproportionsCells` (3),
  `macroVerticalDivisionBorderSkeleton` (3), on pictures only. Every one of the 18 shots was looked at before
  the recapture (a 12 px plate with a 2 × 4 field of muted dots, 4 × 2 on a lying splitter, the cells beside it narrower by
  the difference, nothing else); 72 references recaptured (18 × 2 densities × 2 pointers). The unit's review
  then found the dots of a SQUEEZED splitter touching its border (the inset was the border's width alone: a
  4 px strip read border, dot, dot, border, and an 11 px one stood its first column on the border): the inset
  became `layoutChromeGripDotsInset` (2), identical at 12 to 15 px, a single clear column on a strip squeezed
  a little, none on one too thin, and the one test showing squeezed splitters
  (`macroLayoutSpacerEatsSpareSpace`) was predicted, looked at and recaptured again. The prose of three tests that stated the old look says the new.
- **Ratchets:** none moved.
- **Not pictured anywhere** (the same class and paint path as the pictured ones): a splitter the halo inserts
  around a division cell; a splitter shorter than its dot field (fewer rows, none below 14 px); the 13 px
  rounding; the dev menu's free-floating "Adjuster widget" (a 50 × 40 box: a block of dots).
- **The 44 rule** (`visual-design-system.md` §4.2) is untouched here: the divider is the mouse's control, and U2
  states the two-controls rule when the finger's control exists.

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

**Landed 2026-11-25 (U2 of the inspector-overhaul loop).** Built in the checkpoints above, in this order as it
turned out: the source (U2.1), the corner hooks (U2.2), the menu sweep's port BEFORE the first build could pass
(once `ClassInspectorWdgt` was gone, `check-hand-lists` failed the build on the sweep's marker), the first build
(U2.3), three probe rounds in a browser (U2.4), the toolkit (U2.5), the 32 tests in four batches (U2.6), the other
rigs (U2.7), the suites and the recapture (U2.8). §5 states the tool AS BUILT; what follows is how it came to
differ from this plan's first text, measured:
- **What the research corrected before a line was written:** the one-line relay from the split button to the
  splitter's handler reads a raw pointer unmapped (`check-plane-discipline` C2) and its fallback seam defers a
  settle outside a stream handler (`check-layering` [O]), both invariants, so the splitter's solve became a QUERY
  (`maxDimsPuttingMyLeadingEdgeAt`) that each of the two drag handlers asks, mapping its own pointer and making its
  own deferred writes; a splitter is recognised from STRUCTURE (handles, palettes, frame bars and sliders answer
  `ownsDragsStartingOnMe` too, and a windowless row under "Resize/move…" has the halo's handles as children); a
  fixed piece of a band pins its MOST size (spreadability 0: `SPREADABILITY_NONE` still leaves a tenth to take
  slack); an inspector needs a most width of its own or its split cannot move; a class `rename` built on a
  notifying `duplicate` would tell twice (one non-notifying copy serves both); `_resizerOverMyCorner` and
  `HandleWdgt.cornerFootprint` went WHOLE with the corner chain; the scanner needs no variable around `new X` in a
  method.
- **What the read of the first source diff changed, before it ran:** the split button's wanted edge reads the
  splitter's BOX width, never its laid-out one (12 or 13 by the rounding of the last pass); and the row's spare
  width goes by the VIEW (a member list keeps its desired width, an editor takes the rest: `rowSlackWeight`).
- **What three probe rounds changed (seven fixes, each measured again):** the row CLIPS (a `ClippingWdgt`:
  squeezed with no window it painted and took presses outside its box); every band ends with its inset (the
  footer's last button stood flush on the edge); an inspector whose view was taken out shows no subject (the
  same choice left a husk); the row tells its window its name may have changed; a list's placeholder row names no
  member; a long title no longer widened the window; and, in the second round, a header's title became its band's
  SPRING, a text that gives (a title that claimed its text's width as desired pushed the row out of the regime in
  which a split moves: a 70-character member froze the split; there is no title cap).
- **Two defects other units' tools found, fixed at their cause:** the menu sweep's first run wrote 1088
  `MIXED_DIVISION_AXES` errors: the dev row "Attach with horizontal layout" added its widget along x into a
  parent whose cells run y, a gap older than this unit that an inspector left open by an earlier row now
  exposed; `Widget.newParentChoiceWithHorizLayout` joins along the axis the parent's cells already run. And a
  ported test pinned a view-less inspector's header band stretching to the inspector's full height at its next
  layout, its width falling to its header's (a division stack hands ALL its spare room to its cells, and the
  pinned band was alone): the place a view stood keeps the view's claim (`viewsPlace`, a spring with the view's
  desired width and no least width), so a gutted row lays out as the intact one did (measured 372 | 12 | 374 with
  both views out; 294 | 12 | 217 at 525 wide; headers 44 at the top).
- **The toolkit:** three locators that ask what a part ANSWERS, never its class (the toolkit is the eager harness
  part, the tool a lazy one): `topMemberList`, `memberEditorFedBy(memberList)` (read off the row's structure: the
  editor stands IN the next inspector, on a member of the list's own subject), `topMemberEditor`; every verb keeps
  its name and parameters; the code-pane verbs throw `NO MEMBER EDITOR` when no member is chosen.
- **The tests:** all 32 ported, six renamed (§7.1). One assertion was LOST in the ports and given back after the
  review found it (a read-only member's editor has no Save: the old helper read the Save, the ports read only the
  member list's footer); no other was lost without a successor asserted; one found
  VACUOUS and made real (`list.contents.children` counted the list's one rows container); one RESTORED
  (`macroAddEditSaveRenameRemoveProperty`'s first and last shots are byte-identical again, at both densities and
  pointers); value checks added beside the pictures. The five re-purposed tests pin the successors of what they
  lost (the same chip pressed again reloads the same inspector; a row built by code on a prototype is edited as a
  class; a choice in a picked-out list opens exactly one new window; the windowless row has no handle of its own
  and is resized by the halo; a gutted row keeps its shape).
- **The rigs:** the menu sweep (two row fixtures, three popout buttons per fixture, three member-editor roots;
  82 prompt OKs driven; its first run found the axis defect below, and it is green since that fix), the
  serialization rig (every expectation name and refusal regex untouched; three fixture translations where the thing
  judged was a type that is gone, each keeping the judged fact; risk R6 retired: the first save and load of a member
  reference held by a widget was refused by nothing), the boot smoke and the parts rig, each of these three green on
  its first run after its port, with its self-test (the boot smoke's restored-inspector probe is judged only on a
  production tree, by `fg homepage`).
- **Pixels:** the predicted set was written before the first suite run (16 tests, 46 shots; the other 16 ported
  tests and every test outside the 32 unchanged); the failing set EQUALLED it under mouse and under finger; every
  changed shot was looked at before the recapture (and each dpr-2 render measured against its dpr-1 one: the
  same layout at both densities); 184 references recaptured (46 × 2 densities × 2 pointers).
- **Ratchets (each a budget, dated beside its number):** `BASELINE_PROLOGUE_COPIES` 8 → 7 (the inspector has no
  `_reLayout`); the splitter's complexity record re-keyed to its solve, 19 → 18; `PROMPTS_DRIVEN_FLOOR` 53 → 55;
  `check-layering-selftest`'s stale-allowlist plant covers the split button's file. `BASELINE_U_QUERY` stays 101.
  The doc ceiling of `Fizzygum-tests/CLAUDE.md` is banked 12 bytes lower (66434 → 66422). No rule of any gate
  changed, no allowlist grew.
- **Docs:** 78 passages of the living docs made true (the visual design system's band rule and two-controls rule,
  the serialization reference, the viewports doc's corner reserve, `layout.md`'s tool-as-composition paragraph, the
  citizenship acid test, the macro-authoring skill among them) and 34 core comments that still named the old
  tools.
- **What the two independent reviews changed** (one of the source, one of the tests, rigs and docs; both asked first
  whether any shape was chosen for a number or to quiet a gate, and found none): a split a person DRAGGED was lost
  at the next member choice (the fresh inspector took its default most width beside a neighbour that kept its
  dragged one: 419 landed at 403): a choice now has ONE heir give up the most width the removed inspectors had given
  away across its boundary, so the split stays beside a view of the same kind and the default returns beside
  another kind or none (§5.4; measured by mouse and by touch); a splitter is recognised by the solve its split
  button asks (`maxDimsPuttingMyLeadingEdgeAt?`), not by a drag handler palettes and handles also have; the chip
  pressed again and a label naming no member no longer leave a selection with nothing on its right; only a window
  on the desktop is widened; the window is re-titled only when the row's first inspector changes; a drop on an
  "Edit layout" slot joins along the slot's axis (the twin of the attach defect); the box's max arithmetic has one
  statement (`DivisionStackLayoutSpec.maxFor`). In the tests: the lost assertion above; two sentences that claimed
  an owner's approval of the picked-out views' look that was not given (it is an open question); and BITE-PROOFS:
  no new assertion of the ports had been seen failing, so each got a plant through `--prelude` and was seen failing
  on its own line.
- **Left open, each stated in §5 where it applies as "an open question for the owner":** "Edit layout" adders
  left behind a choice; a widening that gives a new editor only its least 280; a window narrower than its row's
  least width; a double-click on the right part of a lone list's row; a view picked out of its inspector standing
  on no body (darker than the old panes did); a double-click on a method's row replacing its editor with an empty
  list on the function. And, as built and unfiled: a clicked "(empty)" row wears the
  list's selection fill; a member's footer buttons follow the choice, not a Save that makes the member the
  widget's own (as before this unit); a whole-widget Destroy of a member list leaves its place 1 px wide.
- **Not run:** U3b (the owner, 2026-11-24): the split button shows the double arrow alone.
- **Evidence:** `fg gauntlet` OK, all 20 legs in wave with no retry, twice: on the unit before the reviews' fixes
  (1667 s) and after them (1561 s), the second with an empty predicted failing set; `fg homepage` OK, where the
  boot smoke's restored-inspector check ran for the first time on a production tree (a row on a class's prototype
  restored from a widget file and from a world file: each door waited for the reflective layer, and the member
  editor a row click opens shows the member's CoffeeScript).

### U3. Tests of what is new (1 day)

Write each with the `/author-macro-test` skill of the tests repo. Each is proven to bite: plant the
bug through `--prelude=` (a file under `.scratch/`), watch the test fail on its own line, remove the
plant, watch it pass. Each is proven clean with a follower on both pointers:
`node scripts/run-sequence-headless.js SystemTest_<new> SystemTest_macroAnalogClockInspectEdit`, zero
`WORLD_INVENTORY_` lines, then again with `--pointer=finger`.

U2's 32 ported tests (§7.1) and two rigs already pin part of what this unit was to prove: the third column says
which test pins what, so a new test need prove only what is left. Find the tool's parts with the toolkit's
locators (`@topMemberList()`, `@memberEditorFedBy memberList`, `@topMemberEditor()`; `src/macros/CLAUDE.md`, "One
inspector tool"), and re-locate an editor after every choice. Geometry of the built tool, its window at (x, y): the
row at (x+1, y+46), 758 × 391; the member list's list at (x+1, y+138), 372 × 247; the editor's code area at
(x+385, y+90), 374 × 295; with no member chosen the one inspector and its list run the full 758. From the default
split a split moves right only (§5.10). Picture nothing below a row's least width (§5.4: an open question).

| Test | Proves | Already pinned by U2's ports | Plant that must fail it |
|---|---|---|---|
| `macroInspectorMemberClickOpensItsEditorBesideTheList` | a click adds the second inspector; another row REPLACES it (still two); the same row again RELOADS it (typed text gone, undo brings it back) | the reload and its undo, and another member's NEW editor beside the list: `macroFormulaBarUndoStaysInItsEdit`; the same subject chosen again reloads the same inspector, and a choice further left removes what stands right of it: `macroInspectorClassChipShowsTheClassBesideIt`. Unpinned: the count "still two" after another member | `_showNextToNoSettle` always appends |
| `macroInspectorDrillWidensItsWindow` | a double-click on an object-valued field shows the value beside the list; a third inspector widens the window by the missing width; the first inspector is still there | the drill to a second and a third inspector: `macroInspectorEditsAClassPrototypeAsAClass`; a three-inspector window 1048 wide, by its PIXELS only: `macroInspectorCodePaneRunsAgainstItsSubject` image_3. Unpinned: the widening by the missing least width as a value, and its stop at the desktop's right edge | `_widenMyWindowToFitNoSettle` a no-op |
| `macroInspectorSplitMovesByDividerAndByButton` | the divider shows its dots and the second inspector's header opens with the split button, the first inspector's does not; a drag on the DIVIDER moves the split by the drag's travel and nothing else; a drag on the BUTTON does the same. The test runs on both pointer axes: the finger run is the proof D11 asks for (its button drag is a touch drag) | the second inspector's split button (`showsSplitGrip`): `macroPickingUpPartsFromInspector`, `macroInspectorResizingOKEvenWhenTakenApart`. Unpinned: every drag; that the first inspector carries none; a dragged split kept across a member choice, and its return to the default after a kind change (a drill to a value) or a filter toggle (measured in a browser, §5.4; pinned by no test) | `SplitGripWdgt.nonFloatDragging` a no-op |
| `macroInspectorTakenOutLeavesNoStraySplitter` | "Pick up" of the second inspector leaves one inspector and NO splitter; a choice made in the picked-out one opens a window of its own | a picked-out VIEW's choice opening exactly one new window, the row left as it was: `macroInspectorResizingOKEvenWhenTakenApart`. Unpinned: a whole inspector picked out, the splitter it leaves, the grip it sheds, and the window's title following the row's new first inspector | `InspectorRowWdgt._reactToChildRemoved` a no-op |
| `macroInspectorRowSurvivesACopyAndASnapshot` | a duplicate of a two-inspector row drives its own editor; a snapshot round trip restores both inspectors and the member's source | the copy: `macroDuplicatedInspectorDrivesCopiedTargetOnly` (the copy's editor saves into the copied subject only), `macroDuplicatedInspectorsCloseIndependently` and `macroDuplicateComplexWidgetPaintsCleanly` (a row of its own); the snapshot: the serialization rig's `world.inspector.classSubjectsSurviveSnapshot` (rows with a member chosen restore with the same pixels, each editor on its member of the restored subject, a Save still editing). Nothing is left unpinned | (assert only; the serialization leg is the gate) |
| `macroInspectorReadOnlyMemberHasNoFooter` | on a Point: the list has no footer band, the editor no Save and no band | PARTLY: the list's missing footer band on a number, a string and a Point, and, given back after U2's review found it lost in the port, a member's editor there with no Save, no Save child and no band, its code area to its bottom: `macroInspectorOnNonWidgetIsReadOnly`; the same of a class function's member, beside a prototype's `constructor` editor with its Save and its 52 px band: `macroInspectorEditsAClassPrototypeAsAClass`. Unpinned: the plant seen failing those assertions | `CodeAreaWdgt._hasAFooterBand` answering true |
| `macroInspectorDuplicateCopiesAMember` | on a widget: Duplicate… of an injected method under a new name gives a second member with the same source that runs, the original untouched; of a field, a second field holding the same value; a name the subject already owns is refused and nothing changes. On a class: the copy is recorded (a snapshot replays it) and `rename` leaves exactly what duplicate-then-remove leaves | Duplicate… enabled by Rename…'s rule and refused to `constructor`: `macroInspectorOffersOnlyWhatItsSubjectOwns`; its prompt's OK dispatched with no throw: `fg menusweep`. Unpinned: every copy, the owned-name refusal, the record, and that a duplicate tells once (`macroInspectorEditTellsOnce` counts add, save, rename and remove) | `duplicate` writing under the OLD name |
| `macroInspectorCutListSaysSo` | an array of 1200 items: the list shows 1000 and the notice band says "The first 1000 of 1200 items are listed." | the serialization rig's `inspector.onAnIndexedSubjectListsItsItemsInOrderBounded`: a typed array and a string of 3000 list `MOST_ITEMS_LISTED` items, and the cut-notice band's text says so. Unpinned: a plain Array, in a SystemTest | the notice band never built |

The rig expectation this unit was to add (a snapshot holding a row whose second inspector's subject is a
`MemberRef` restores with that ref naming the restored holder) landed in U2.7, in
`world.inspector.classSubjectsSurviveSnapshot` (`serialization-roundtrip-headless.js`, held by
`lib/serialization-expectations.js`): the plan's risk R6, met (§8).

`fg menusweep` has no ROOT for an inspector PART's own menus (a header's, a band's, a view's, a splitter's: the
division stack's "Layout in row/column", "Cross: …" and "Edit layout" rows on them were fired once by a scratch
probe, 494 rows, no throw). U3 adds one, a nested root as the sweep's member-editor roots are.

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
     (only a member list, `MemberListWdgt`, passes a target: grep to confirm). A list with no
     elements shows its placeholder "(empty)" AS its one element, so its target is handed that
     string: an object list's takes it as no choice (as `MemberListWdgt._memberNamedBy` does for a
     label that names no member).
   - A new option **`labelQuery`**: the name of the target's method that answers an element's label
     (the same shape as `memberFactsQuery`: a method name, no closure). Without it,
     `ListWdgt.labelOf` as now.
2. **`InspectorWdgt`: more than one view.**
   - Add the table U2 did not need, `_views`: THE VIEWS MY SUBJECT OFFERS, in order, each [title, the name
     of my method that builds it], read by the chooser and by `showView`. Its first rows are the choice
     U2's `_buildAndConnectChildrenNoSettle` makes inline (§5.5): `[["Source", "_newMemberEditor"]]` for a
     subject that answers `editsAsAMember`, `[["Members", "_newMemberList"]]` otherwise, with
     `_newMemberList` / `_newMemberEditor` and the fields `chooser`, `viewToggles`, `shownViewTitle` declared
     at class level; the build then shows `_views()[0]`. Then rows, each guarded by a capability of the
     subject, never `instanceof`: `["Children", "_newChildrenList"]` for a widget (it answers the widget
     tree's own questions; pick the narrowest existing one), `["Instances", "_newInstancesList"]` and
     `["Subclasses", "_newSubclassesList"]` for a class's prototype.
   - The queries are one line each: `@inspectedObject.children`; the class's `instances` set as an
     array (`Class.coffee` emits one per class; widgets only register); the prototypes of the classes
     `allClassFunctions()` lists whose `__super__` is my subject.
   - One builder serves all three: `new ListWdgt objects, target: @, action: "chooseRow",
     labelQuery: "labelOfRow"`, with `chooseRow: (object) -> InspectorRowWdgt.showChoice @, object`
     and `labelOfRow` answering `_subjectName`'s rule for the object.
   - What every view answers, as U2's two do: `rowSlackWeight` (the inspector's constructor sets its own most
     width from its view's, unguarded, through `_defaultBox`: §5.5), so an object list answers one (a list's, 0.01: it
     keeps the width its rows need), and the weight is also the view's KIND to a choice's split rule (§5.4: an object
     list replacing a member list keeps a dragged split); `clearChoice` (`chooseMyClass` asks it through `?.`), so an
     object list's drops its list's selection (`ListWdgt.clearSelection`); and `_reloadNoSettle`, which the
     inspector's reload asks of its view unguarded (a list's drops its choice, as `MemberListWdgt`'s does).
   - The chooser band (`theme.toggleBandHeight`, `rule: "bottom"`, written as the toggles band is:
     `toggleBandInset`, the toggles `toggleBandGap` apart, `BandWdgt.SPRING`, `toggleBandInset`), between the
     header and the view: one `LabelledToggleWdgt` per
     view, `action: "showViewNamed", arg1: title`, ON exactly for the shown view
     (`_reflectViewOnToggles`, the shape of `_reflectFiltersOnToggles`). Built only when `_views()`
     has more than one row.
   - `showViewNamed(ignored, ignored2, title)` → `showView(title)`, in ONE settle: build the named view,
     make it `@view` and add it at the old view's index, THEN destroy the old one (a view that leaves while
     it is still `@view` leaves its PLACE: `viewsPlace`, `InspectorWdgt._reactToChildRemoved`), re-box the
     inspector through `_defaultBox` for the new view, keeping the trade its box holds with its left neighbour
     (less what `mostWidthGivenAway` read before the switch: a dragged split stands, §5.4), and reflect the toggles; then,
     after that settle, `InspectorRowWdgt.showChoice @, undefined` (a gesture asks the row after its own
     settle, never inside it: §5.3 a). A view's place stands right after the header
     (`@children.indexOf(@header) + 1`): with a chooser band, it must stand after the chooser.
3. **Tests** (with bite-proofs and followers as U3): `macroInspectorChildrenViewWalksTheWidgetTree`
   (a window: Children, choose a child, choose its child: three inspectors, each titled with its
   widget); `macroInspectorClassViewsListInstancesAndSubclasses`;
   `macroInspectorViewSwitchDropsWhatWasChosen`.
4. `fg menusweep` and `fg pinsweep` alone, then `fg gauntlet`. Recapture what U4 moved (an inspector
   on a widget or a class now has a chooser band: every such screenshot).

### U5. Docs, BACKLOG, close (0.5 day)

1. **Architecture docs** (§7.4), present tense, no "was"/"no longer". U2 made §7.4's docs true of the
   tool it built, the two that own the mechanism among them: `widget-citizenship.md` (the inspector as an
   assembly of ordinary widgets) and `layout.md` §4.2's paragraph naming the tool as composition, with the
   three rules a band keeps (§4's two hazards and the fixed-piece rule). U5 re-verifies every §7.4 doc
   against the tree U3 and U4 leave (U4's views and chooser, U3's tests by name), and corrects two passages
   stale from before U2: the checks index's [O] row (`lint-and-static-checks.md` ~:941) names
   `*Coalesced` / `COALESCED_CALLER_ALLOWLIST` where `check-layering.js` says `*DeferredSettle` /
   `DEFERRED_SETTLE_CALLER_ALLOWLIST`; `docs/tooling/duplicated-code-detection.md` (~:121) gives
   `meta/*Inspector*` for files in `src/meta-tools/`. And one label U2 left as it was: the build explainer's
   part-size bar (`docs/explainers/build-and-packaging.html`, "meta-tools (lazy) — 47.7 KB") was measured before
   the tool's rewrite; re-measure it the way that bar's other labels were measured (a production build's parts:
   `fg fingerprint homepage`), or all of them together.
2. **`Fizzygum-tests/scripts/inspector-churn-set.json`:**
   `node scripts/derive-inspector-churn-set.js --write` (from `Fizzygum-tests/`), and read its diff.
   The script plants a member and sees which tests' pictures move; it assumes `_filteredMemberNames`
   and `showingInherited`, which `MemberListWdgt` keeps. U2 renamed `macroSimpleDocumentHandlesOldInspector` to
   `macroSimpleDocumentHandlesInspector` in the json with its test; the prose still names the old tools: the json's `why` ("an object inspector's or a
   class inspector's"), the deriver's header (`InspectorWdgt._filteredMemberNames`, "class inspectors") and
   `lib/inspector-churn-set.js`'s header. Say what is true.
3. **`docs/BACKLOG.md`.** The inspector's open lines stay open and keep their wording where it is
   still true; correct any that names a deleted method or class. They are (search "inspector"):
   the Inherited filter (⛔ owner), "Is an inspector's subject always a page object?" (⛔ owner),
   the world's inspector editing its browser listeners, "A function held with no kept source shows
   compiled JavaScript" (⛔ owner), "A wrapped member reads as compiled text" (⛔ owner), "A scrolled
   pane keeps its height when its content shrinks", `fg recapture-inspector`'s blind recapture. Add,
   under this plan's section, what this arc leaves open:
   - every OTHER division stack's splitter has no finger's way to move it (the halo's layout
     adjusters, "Edit layout"): a general stack has no header band to stand a grip in;
   - a division row whose elements desire 0 width in all divides by zero (`StackLayoutEngine`, its third
     regime), and one whose least widths sum to 0 laid out at width 0 does too (its first regime: a
     spring-only band at width 0);
   - two footer-band mechanisms stand: `FooterBandLayout` (the code-area family, the bin) and
     `BandWdgt`; one should serve both;
   - the talk plan's U3 is superseded by this plan (one line, so the owner's plan and this one do
     not both claim the explorer);
   - U3b, the finger icon on the split button, not run in the inspector-overhaul loop by the owner's
     ruling (§0.4 D11): its line stays open under this plan's section;
   - the questions parked for the owner at U2, each where §5 states it as built ("an open question for
     the owner"): "Edit layout" adders left behind a choice (§5.4); a widening that gives a new editor only its
     least width and leaves every split of the row inert (§5.4); a window narrower than its row's least width
     (§5.4); a double-click on the right part of a lone list's row (§5.6); a view picked out of its inspector
     standing on no body (§5.5); a double-click on a METHOD's row replacing its editor with an empty list on the
     function (§5.6). Each is filed, built or dropped as the owner answers;
   - a holder keeps the place of its slack taker: a header whose title a person picks out stretches its
     controls, and a member list whose list is picked out stretches its bands (the engine rule `viewsPlace`
     answers for a view, one level down: a division stack hands all its spare to its cells by their desired
     sizes when none has a margin);
   - Add… with a name the subject already owns replaces that member with undefined, silently (as before U2),
     beside a Duplicate… that refuses the same name;
   - and, filed or kept as ledger lines by the house bar (a reachable or medium item is queued), the low lines
     U2's two reviews listed: an inspector ATTACHED into a row is not reconciled until something leaves the row,
     and one attached free-floating counts as a cell; a view attached back onto its inspector shares the height
     with its place; a row whose only inspector was picked up stays a blank window titled "Inspector"; a split
     button whose header band a person rotates maps its pointer in another plane; a member reference cannot be
     inspected as an object; an old one-class inspector's record loads as a shell whose old controls throw at a
     press (no compatibility is owed); no toolkit locator finds an editor that is its row's first inspector; a
     double-click in a list standing in no row cannot complete (the fourth question's family); the menu sweep's
     `POPOUT_BUTTON_UNSWEPT` scans the member list only; `world.inspector.survivesSnapshot`'s `rows > 0` counts the
     placeholder row too; the rigs open rows in 560 × 410 windows; a lone view saved in a file is probed nowhere;
     unsaved typing a re-filter takes away cannot be undone (ruled in U2's preparation, stated in no doc);
     `docs/BACKLOG.md`'s Inherited-filter line still says "An object inspector's…".
4. **Close the arc** with the `/close-arc` skill: final `fg gauntlet`, the commit messages proposed,
   and the wait for approval. The plan STAYS in `docs/plans/`: U3b, the finger icon, is still open by the
   owner's ruling (§0.4 D11), so the status line at its top says which units landed and that U3b waits for
   the owner, and its `docs/BACKLOG.md` section keeps U3b's line; the `git mv` to `docs/archive/`, its status
   stamp and its `archive/INDEX.md` line wait for U3b's close.

---

## 7. Touch-lists (complete as of 2026-11-24)

U2 worked §7.1–§7.3 through. What they name is of 2026-11-24, so a member or a line a row names may be
gone (§12 says where it went); a row says where U2 left it when a later unit still acts on it. §7.4 is
what U5 verifies.

### 7.1 The 32 SystemTests that drive the inspector

All are under `Fizzygum-tests/tests/SystemTest_macro<Name>/`, named as U2 left them: six were renamed
because their names named something gone, each row giving the old name after the new. "Shots" is the
number of screenshot names; the two middle columns say what each test did and read before U2 (its port
reads them through §12's map). Seventeen tests have pictures and fifteen are assertion-only. Sixteen of
the seventeen change in U2 (46 shots, each recaptured at dpr 1 and 2, mouse and finger):
`ClassEditShowsOnTheNextFrame`'s eleven shots show no inspector and match unchanged, as does
`DuplicatedInspectorsCloseIndependently`'s image_3, which shows only the string.

| Test (`macro…`) | What it does today | Inspector internals it reads | Shots |
|---|---|---|---|
| AddEditSaveRenameRemoveProperty | add, save, rename, remove a property; list scroll | the four buttons, `detail.textWdgt.setText`, `list.elements/.selected/getScrollY` | 5 |
| AnalogClockInspectEdit | edits `drawSecondsHand`, saves | none (verbs only) | 1 |
| AStepThatThrowsStopsStepping | edits `step`; Save un-bans | `showInheritedToggle`, `detail.textWdgt.setText`, `saveButton` | 0 |
| ClassEditShowsOnTheNextFrame | 3 class + 3 object inspectors built in code | `showInheritedToggle`, `detail.textWdgt.text` | 11 |
| InspectorSaveOfAClassMemberRefusesCodeThatDoesNotCompile (was ClassInspectorSaveRefusesCodeThatDoesNotCompile) | a bad class save is refused | `detail.textWdgt.setText`, `saveButton(.isEnabled)` | 0 |
| DuplicateComplexWidgetPaintsCleanly | duplicates the inspector window | none | 2 |
| DuplicatedInspectorDrivesCopiedTargetOnly | each copy's save hits its own rectangle | `showInheritedToggle`, `list.selected`, `detail.textWdgt.setText`, `saveButton` | 3 |
| DuplicatedInspectorsCloseIndependently | closes each copy | none | 3 |
| EveryCodeChangeGivesBannedWidgetsAnotherChance | class add/remove in code | `addProperty`, `removeProperty`, `list.listContents`, `list.select` | 0 |
| FormulaBarUndoStaysInItsEdit | the code pane's undo history | `detail.textWdgt` | 0 |
| InspectorClassChipShowsTheClassBesideIt (was InspectorBreadcrumbChipOpensClassInspector) | chips open class inspectors | `classChips`, `inspectedObject`, `colloquialName()`, `parent` | 0 |
| InspectorCodePaneRunsAgainstItsSubject | run rows of the pane menu | `list`, `detail`, `detail.textWdgt`, `classChips`, `inspectedObject` | 3 |
| InspectorEditTellsOnce | counts how often each edit tells | `addProperty`, `save()`, `renameProperty`, `removeProperty`, `list.select`, `detail.textWdgt.setText` | 0 |
| InspectorOffersOnlyWhatItsSubjectOwns | Rename/Remove enabling | the buttons' `isEnabled`, `detail.textWdgt.isEditable`, `list.select`, `renameProperty`, `addProperty`, `toggleShowingInherited` | 0 |
| InspectorOnNonWidgetIsReadOnly | 42, a string, a Point, a widget | presence of the four buttons, `list.contents.children`, `colloquialName()` | 0 |
| InspectorEditsAClassPrototypeAsAClass (was InspectorOpensAClassInItsClassInspector) | row double-click, `spawnInspector` on a prototype | `list.listContents/select`, `inspectedObject`, `saveButton?`, `colloquialName()`, the four edits, `constructor.name` | 0 |
| InspectorRejectsDrops | drops a box over both panes | `list`, `detail` (geometry) | 3 |
| InspectorResizingOKEvenWhenTakenApart | `pickUp` of list and detail; resizes | `list`, `detail` | 4 |
| InspectorSaveRefusesCodeThatDoesNotCompile | a bad value save is refused | `detail.textWdgt`, `saveButton.isEnabled` | 0 |
| InspectorScrollbarUnplugged | unplugs the list's scroll bar | `list.vBar` | 4 |
| InspectorShowsAnUndefinedFieldAsUndefined | a field's text | `list`, `detail.textWdgt.text` | 0 |
| MovingSlidersSidewaysDoesntCauseContentToMoveSideways | drags the list bar sideways | `list.vBar`, `list.getScrollX/Y` | 3 |
| MultilineTextInputScrollsWell | types into the code pane | `detail.textWdgt`, `detail.vBar` | 2 |
| NakedInspectorRendersResizesAndEdits | no window; edit, save, own resize | `resizer` | 3 |
| InspectorOnAClassShowsItsStaticsSource (was ObjectInspectorOnAClassShowsItsStaticsSource) | an inspector on a class function | `list.selected`, `detail.textWdgt.text` | 0 |
| InspectorShowsTheFunctionItsSubjectHolds (was ObjectInspectorShowsTheFunctionItsSubjectHolds) | 5 object + 1 class inspector | `list.selected`, `detail.textWdgt`, `saveButton`, `removePropertyButton.isEnabled`, `showInheritedToggle`, `renameProperty` | 0 |
| PaletteBufferKeyNamesItsOwnCode | saves then removes a member | `list`, `detail.textWdgt.setText`, `saveButton`, `removePropertyButton` | 0 |
| PickingUpPartsFromInspector | `pickUp` of detail, then list | `detail`, `list` | 3 |
| ResizingPristineInspector | resizes the window | `instanceof InspectorWdgt` | 2 |
| SimpleDocumentHandlesInspector (was SimpleDocumentHandlesOldInspector) | embeds the window in a document, drags it out | none | 3 |
| TextOwnCodeKeysTheCachesItRunsIn | saves/removes two members | `showInheritedToggle`, `list`, `detail.textWdgt.setText`, `saveButton`, `removePropertyButton` | 0 |
| WrappingTextFieldResizesOK | soft wrap; resizes | `detail.textWdgt` | 3 |

Also: `macroTextRunRowsReflectSelection` asserts the "Inspect selection" row's label (unchanged).
`macroInspectorWorkAreaEvaluatesCoffeeScript` drives `ConsoleWdgt` only (unchanged). The other
tests that name the inspector do so in a comment or a provenance string only; sweep them for a name that
has become false (`grep -l -i inspector tests/*/*.js`, skipping `automation-assets/`).

**Predicted outcome of the first suite run after U2.6:** exactly the sixteen tests whose pictures change
fail, on pixels only (46 shots), under mouse and finger, at dpr 1 and 2; the other sixteen pass with no
reference touched; no test outside the 32 changes. Any other failure is a finding.

### 7.2 Source outside the two inspector files

| File | What | Do |
|---|---|---|
| `src/basic-widgets/Widget.coffee` | `spawnInspector` (:4997); comments naming the inspectors (:190, :3467 the titles, :4266, :4446–4454, :4599, :4964–4996, :5201, :5615, :5700, :5718, :5755); `noteCornerChainChanged` (:1040–1047) | door per §5.9; comments to the new shape; U2.2 |
| `src/basic-widgets/TextWdgt.coffee` | `_codeReceiver` comment (:684–687) names both inspectors as receivers | name the member editor |
| `src/WorldWdgt.coffee` | comments (:215, :703, :763, :1710–1716, :2207, :2854, :3146, :3485, :3535, :3600, :3664) | correct what names a deleted class or method |
| `src/basic-widgets/menu-system/MenusHelper.coffee` | comment :9 | check |
| `src/serialization/` | `Deserializer` :246 comment; `SourceEditsRegistry` comments (:9–15, :32, :43, :54, :198, :204) naming the writers; `Serializer` remedy strings (:349, :352, :400) and `SerializationError` :93 naming "an inspector's Remove/Save"; `WellKnownObjects` :26; `NativeValueKinds` :62 | writers are now `MemberRef.save` / `ClassMemberRef`; the remedy strings stay true (the buttons exist) but check their wording against the serialization rig's regexes |
| `src/ListWdgt.coffee`, `CommandPanelWdgt.coffee`, `MemberRowWdgt.coffee`, `MenuItemWdgt.coffee` | member mode: unchanged in U1–U3 but for `ListWdgt.clearSelection`, which U2 added; comments say "the Object Inspector's" | say "a member list's (MemberListWdgt)" |
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
| `Fizzygum-tests/scripts/menu-click-sweep-headless.js` | roots `InspectorWdgt` / `ClassInspectorWdgt` and the popout-button section (:806–904: `INSPECTOR_BUTTON_OF`, `inspectedObject`, `list.select`, `faceWidget.text`, `MenuSweepOwnWdgt`); three code-pane roots (:1127–1200); `PROMPTS_DRIVEN_FLOOR = 53` counting two prompts per inspector class (:79, :190–195) | ported in U2: two fixtures, `InspectorRowWdgt[widget]` and `InspectorRowWdgt[class]` (a rectangle; a class of the sweep's own); the popout buttons are each row's member list's, THREE per fixture (`INSPECTOR_BUTTON_OF` gains `duplicatePropertyPopout: duplicatePropertyButton`); the three code-pane roots are member editors, each checked to stand on the member it means; the `hand-list-sanctioned` marker over the two class names deleted (once `ClassInspectorWdgt` was gone, `check-hand-lists` failed the build on it, `SANCTION_STALE`, so the sweep is ported before any build passes); `PROMPTS_DRIVEN_FLOOR` 53 → 55, dated |
| `…/menu-click-sweep-selftest-headless.js` | plants on every `InspectorWdgt`, strips "…" off the two popout buttons (:118–154, :190) | plant on `MemberListWdgt` |
| `…/smoke-boot-headless.js` | `inPageInspectorState` counts `constructor.name === 'InspectorWdgt'` (:485–493); the restored-inspector probe builds a `ClassInspectorWdgt`, calls `selectionFromList`, reads `detail.textWdgt.text` (:550–630); rules at :735–766; `world.spawnInspector(world)` judged `inspectors === 1` (:860–871, :966–980) | the count still holds (one `InspectorWdgt` after an open); port the probe to a row on a class's prototype, its member list's `selectionFromList`, its editor's `textWidget.text` |
| `…/smoke-boot-selftest-headless.js` (:17, :173) | expects `RESTORED_INSPECTOR_VACUOUS` | re-run; fix the plant if the probe's shape moved |
| `…/smoke-apps-headless.js` (:28–32, :101–121, :268–276) and its selftest (:80) | `spawnInspector(world)` then counts `InspectorWdgt` | still one; re-run |
| `…/staleness-census.js` :156 | the `inspector-window` extra | unchanged; it now arranges the row: `fg census` must stay clean |
| `…/parts-snapshot-load-headless.js` :436 | `{$wk:'class:ClassInspectorWdgt'}` as a class of the lazy part | another class of the part (`InspectorRowWdgt`) |
| `…/serialization-roundtrip-headless.js` + `lib/serialization-expectations.js` | about twenty expectations: `world.saveRefusal.*` (:1205–1244), `inspector.onABuffer*` / `onAPaneRuntimeValue*` (:1250–1350; a regex on `(InspectorWdgt#N) → .inspectedObject`), `onAnUnrecognizedValue…`, `onAPrototypeLessObject…` (:1473–1504), `onAnIndexedSubjectListsItsItemsInOrderBounded` (:1600–1652), `aClassFieldRowShowsItsRecordOnlyWhileItsValueHolds` (:1670–1698), `onACanvasContext*` (:1724–1739), `world.inspector.survivesSnapshot` (:2642–2681), `world.inspector.classSubjectsSurviveSnapshot` (:2701–2801), `sourceEdits.class*` (:4818–4904), the load checks (:4940–5000), `valueClassEditReachesLiveValues` (:5175–5189) | port each with §12's map; **keep every expectation's name** (a name no backend reports is itself a mismatch). The `.inspectedObject` path in refusal texts still holds: an inspector still holds its subject under that name |
| `…/derive-inspector-churn-set.js`, `inspector-churn-set.json`, `lib/inspector-churn-set.js`, `classify-diff.js`, `classify-diff-selftest.js` | the 16 tests `fg recapture-inspector` recaptures | U5 step 2; a renamed test is renamed in the json in the same change (U2 renamed `macroSimpleDocumentHandlesInspector` there: `classify-diff-selftest.js` reads it on every build) |
| `…/aim-census.js` :314–320, :377 | table rows for seven inspector verbs, held to the toolkit | names unchanged; re-run on build |
| `…/tier-naming-audit/tier-naming-prelude.js` :59–62 | `NON_GEOMETRY` names three `_applyProperty*` | U1 step 4 |
| Standard-test users of `macroAnalogClockInspectEdit`: `lib/gate-bite-proof.js` :37, `preludes-install-selftest-headless.js` :34, `check-refs-selftest.js` :16 (reads its real `image_0` files on every build), `run-macro-test-headless.js` :123, `notification-settle-audit/cache-oracle-selftest-headless.js` :22, and six plants (`audit-preludes/revisit-plant.js`, `unobserved-bucket-plant.js`, `end-of-cycle-audit/careless-push-plant.js`, `paint-time-plant.js`, `notification-settle-audit/callback-flush-plant.js`, `tier-naming-audit/leaf-react-plant.js`) | the test's name and its `image_0` | keep both; after the recapture run `npm run selftest` in the tests repo and the gauntlet's `selftests` leg |
| `Fizzygum/buildSystem/fg-verbs.js` (:83–87, :282–319, :365–375) | `fg recapture-inspector` | unchanged |
| `Fizzygum/buildSystem/check-complexity-ratchets.js` | `'MemberRef#shownText': 20` (re-keyed by U1 from `'InspectorWdgt#_paneTextOfMember'`) | done in U1. U2 re-keyed the splitter's `'StackElementsSizeAdjustingWdgt#nonFloatDragging': 19` to its solve, `'StackElementsSizeAdjustingWdgt#maxDimsPuttingMyLeadingEdgeAt': 18`, dated (§5.10) |
| `…/check-layering.js` :327–348 | two `settling-call-sanctioned` markers of 18 | U1; U2 kept the ceiling at 18, and the split button became a third caller of rule [O]'s allowlisted handler name `nonFloatDragging`: the gate's comment names the three, and `check-layering-selftest.js`'s stale-allowlist plant covers `meta-tools/SplitGripWdgt.coffee` |
| `…/check-call-separation.js` :77 | `BASELINE_U_QUERY = 101` | unchanged: no inspector method was among its candidates (it read 104 only while the toolkit's three locators had no test caller) |
| `…/census-widget-conformance.js` :42–52 | `BASELINE_PROLOGUE_COPIES = 7` (8 before U2) | done in U2.3 |
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
| R1 | Another arc is uncommitted in the same trees | §0.5 step 1: stop and ask. **U2:** met (both trees clean and level at its start) |
| R2 | The edit semantics change in the move (which source a member shows; what a rename records) | U1 moves them alone under the 32 tests and about twenty serialization expectations, with zero pixel change allowed. **U2:** met: no reference moved in U1, and each step tells exactly once on a widget and on a class (U2.4's probe, `macroInspectorEditTellsOnce`) |
| R3 | A band's derived height or width surprises (§4's facts) | `BandWdgt` is ~50 lines and is the only place the rules live; U2.4's probe shows it before any test is ported. **U2:** met: the research read off the engine that a fixed piece pins its most size, and three probe rounds found what neither it nor the spike had reached (every band ends with its inset, a title's desired width froze the split), each fixed before a test was ported; 0 wobble over 421 window heights and 541 widths |
| R4 | `NON_FINITE_GEOMETRY` from a row of zero desired width | springs desire 1; one settle per band; the token fails every suite leg, so a miss is loud. **U2:** no band the tool builds reaches it (each has an inset); a spring-only band set to width 0 still lays its spring NaN wide (the engine's FIRST regime dividing 0 by 0: least 0 into width 0), a second engine item beside the third regime's, both filed by U5 |
| R5 | `_reactToChildRemoved` reconciling during a teardown builds a splitter into a dying row, or the row's own removals re-enter it | mirror the two existing holders' guards (§5.4); `fg vmtruth` and the `WORLD_INVENTORY_` followers of U3 catch a leak; `fg revisits` catches a re-visit. **U2:** the guards are built (the row's `_beingFullDestroyed` and `_reconcilingSplitters`, §5.4; the inspector's own `_beingFullDestroyed` for its view's place, §5.5) |
| R6 | `MemberRef` in a snapshot: a serializer or deserializer rule about a non-widget, non-value class refuses it | U3's added expectation, run first thing in U2.7 by hand: save and reload a world holding a two-inspector row. If refused, read the refusal: the answer is a declaration the class makes (§5 of the serialization reference), never a transient that loses the subject. **U2:** retired: the first save and load of a member reference held by a widget (`world.inspector.classSubjectsSurviveSnapshot`, U2.7) was refused by nothing, and each restored editor's `memberRef.holder` is the restored subject |
| R7 | Widening a window from inside its content surprises a frame (a docked band, a window in a document) | widened only when my parent is a free-floating window whose content I am; anything else narrows the inspectors; U3 tests the plain case and `macroSimpleDocumentHandlesInspector` the embedded one. **U2:** built tighter: only a window standing on the desktop (its parent the world) is widened, and one free in a panel narrows its inspectors as a docked or nested one does (§5.4); a document caps a window nested in it at its column, even below its row's least width (§5.4, an open question) |
| R8 | The corner-hook cleanup (U2.2) breaks a scroll bar's reserve | read all three readers before deleting; presuite's scroll-indicator tests are many; stop if a second definer exists. **U2:** met: no second definer in either repo; `ScrollIndicatorHostWdgt._resizerOverMyCorner` went whole and `HandleWdgt.cornerFootprint` with it, the other-bar branch of `_cornerReserveFor` kept |
| R9 | Recapture hides a real break: a ported macro that passes for the wrong reason | each `intent` re-read against the port (U2.6); `fg diffpage` on three kinds; U3's bite-proofs. **U2:** each port's `intent` re-read; one vacuous assertion made real (`list.contents.children` counted the one rows container); U2's review found ONE lost with no successor (a read-only member's editor has no Save), given back in `macroInspectorOnNonWidgetIsReadOnly` and `macroInspectorEditsAClassPrototypeAsAClass`, and has each new assertion of U2's proven to bite by a plant through `--prelude=` |
| R10 | The inspector's pictures no longer match the owner's 2026-10 design | the bands, the list and the footer keep their metrics and looks (§4, picture 1); what moves is stated in D5, D7, D9, D10. Show the owner `fg diffpage` of `macroAnalogClockInspectEdit` at the end of U2. **U2:** U2.4's probe matched the storyboard band for band; its two differences: Duplicate… in the footer is the owner's (D15), and a band's rule lying inside its height is the loop's own ruling, argued from the storyboard, for the owner's second look. The loop ran unattended, so the owner is shown the diff page on its review page (U5) |
| R11 | A gate's baseline moves and is "fixed" by bending the code | §0.5 step 8; §6 names each expected baseline move and its answer. **U2:** each move class C, dated beside its number: `BASELINE_PROLOGUE_COPIES` 8 → 7, the splitter's complexity record re-keyed to its solve (19 → 18), `PROMPTS_DRIVEN_FLOOR` 53 → 55; `BASELINE_U_QUERY` stays 101; the doc ceiling of `Fizzygum-tests/CLAUDE.md` banked 12 bytes lower |
| R14 | The splitter's new look (D14) moves the pixels of every test showing a division stack, and a test that drags a splitter presses where it now stands | Its own unit (U1b), its predicted set written down before the suite, the failing set held equal to it. **U1b:** retired: the failing set equalled the predicted one under mouse and finger (five tests, 18 shots) |
| R12 | The split grip's relay (one widget handing its drag to another's handler) trips a layering or call-separation rule, or drifts from the splitter's solve | §5.10's second note: one public method on the splitter that both callers use, never a second solve. U3's grip test asserts the split moves by exactly the drag, by mouse and by finger. **U2:** met: the relay would trip `check-plane-discipline` C2 and the public seam `check-layering` [O], so the solve became a query both handlers ask (§5.10); the probe measured the split moving by exactly the travel, by divider and by button, mouse and touch, and a split a person set, by either control, staying across a choice that puts a view of the same kind on its far side (§5.4) |

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
- **One footer-band mechanism** (the `CodeAreaWdgt` family, the member editor among it, and `BinWdgt` on
  `BandWdgt`, `FooterBandLayout` deleted).
- **A touch-sized way to move every division stack's split**, not only the inspector's: a
  general stack has no header band to stand a grip in, so the shape there is still to design.
- **The parked owner questions** in BACKLOG (the Inherited filter; whether a subject is always a
  page object; compiled JavaScript in an editable pane).

---

## 12. The move map (old member → new home)

`I` = `InspectorWdgt`, `CI` = `ClassInspectorWdgt`, as they stood before U2 (line numbers of Fizzygum `f7aed9e0`, 2026-11-24: `git show f7aed9e0:src/meta-tools/InspectorWdgt.coffee`).

| Old | New |
|---|---|
| `I.inspectedObject` | `InspectorWdgt.inspectedObject` (same name); also `MemberListWdgt.inspectedObject`; a member editor holds `memberRef` (`.holder`, `.name`) |
| `I.list` | `MemberListWdgt.list` |
| `I.detail` (the `TextAreaWdgt`) | `MemberEditorWdgt.tempPromptEntryField` |
| `I.textWidget`, `I.detail.textWdgt` | `MemberEditorWdgt.textWidget` |
| `I.saveButton` | `MemberEditorWdgt.saveButton` |
| `I.addPropertyButton`, `renamePropertyButton`, `removePropertyButton` | `MemberListWdgt`, same names |
| `I.showMethodsToggle` … `showOwnPropsOnlyToggle`, `showing*`, `toggleShowing*` (:153–171), `_reflectFiltersOnToggles` (:355), `_toggles` (:807) | `MemberListWdgt`, same names; `_toggles` deleted (no reader: the toggles stand in their band); `I._buildAndConnectOwnPropsOnlyToggle` and `CI`'s empty one became the build's `isAClassPrototype` question |
| `I.classCaption`, `classChips`, `classSeparators`, `_buildAndConnectBreadcrumb` (:285), `_classChainLinks` (:314), `_breadcrumbIn` (:736), `_layOutBreadcrumb` (:782) | deleted; one `InspectorWdgt.classChip` and `_classAbove` |
| `I.openClassInspector` (:552) | `InspectorWdgt.chooseMyClass` |
| `I.@MOST_ITEMS_LISTED` (:110), `_subjectsItemsAndNames` (:120), `@_isAnIndex` (:139), `_filteredMemberNames` (:396), `_buildAndConnectMemberList` (:436), `memberFactsOf` (:457), `_subjectsClassPrototype` (:464), `_refilterMembers` (:367, :370), `_reflectMemberSelection` (:337), `_selectedMemberCanBeRenamedOrRemoved` (:348) | `MemberListWdgt`, same names (`MOST_ITEMS_LISTED` and `_isAnIndex` its statics); the last one's body is `name? and (MemberRef.canEdit @inspectedObject) and MemberRef.of(@inspectedObject, name).canBeRenamedOrRemoved()`, `name` the selected member's (`_selectedMemberName`, through `_memberNamedBy`) |
| `I._emptyPaneText` (:145) | `MemberListWdgt._cutNoticeText`, the text of its cut-notice band (`cutNoticeBand`) |
| `I.selectionFromList` (:604) | `MemberListWdgt.selectionFromList` (the choice); the load is the editor's build and `_reloadNoSettle` |
| `I.lastLoadedMember` | deleted (`InspectorRowWdgt.showChoice` knows a subject chosen again) |
| `I.inspectMemberValue` (:474) | `MemberListWdgt.inspectMemberValue` (the choice of the value) |
| `I._buildAndConnectEditRow` (:531) | `MemberListWdgt._buildAndConnectEditRow`: the footer band's Add… Duplicate… Rename… Remove (the Save is the member editor's) |
| `I.@inspectorClassFor` (:496), and U1's `I._memberRefOf` / `CI._memberRefOf` | deleted; `MemberRef.of` |
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
| `insp.list.select(row)` then reading `insp.detail.textWdgt.text` | `row.inspectors()[0].view.list.select(…)` then `row.inspectors()[1].view.textWidget.text`; in a macro, hold the member list (`row.inspectors()[0].view`, or `@topMemberList()`) and read its editor after each choice (`@memberEditorFedBy memberList`) |
| `MacroToolkit._findTopInspector` | deleted; the toolkit's locators `topMemberList()`, `memberEditorFedBy(memberList)` and `topMemberEditor()` (`src/macros/MacroToolkit.coffee`, "THE INSPECTOR'S TWO LOCATORS"); every verb keeps its name |

New in U2, the home of no old member: all of `InspectorRowWdgt` (`_inspectorNamingMe` among it), `BandWdgt`,
`BandSpaceWdgt` and `SplitGripWdgt`; in `InspectorWdgt`, `header`, `headerTitle`, `view`, `showsSplitGrip`, `viewsPlace`,
`_defaultBox`, `mostWidthGivenAway`, `_giveUpMostWidthNoSettle`, `_buildHeaderNoSettle`, `showsSubject`,
`_reloadNoSettle`, `_subjectName`, `splitterBeforeMe`, `_reconcileSplitGripNoSettle`, `_reactToChildRemoved`,
`_fullDestroyNoSettle`, `_reactToBeingCopied`, `_afterDeserialization`; in `MemberListWdgt`, `rowSlackWeight`,
`cutNoticeBand`, `footerBand`, `_addCellNoSettle`, `_memberNamedBy`, `_selectedMemberName`, `clearChoice`,
`_reloadNoSettle`, `duplicatePropertyButton`, `duplicatePropertyPopout`, `duplicateProperty`; in `MemberEditorWdgt`,
`memberRef` and `rowSlackWeight`; `MemberRef.of` / `canEdit` / `codeReceiverOf`, `editsAsAMember`, `colloquialName`,
`sameMemberAs`, `duplicate`, and `ClassMemberRef._editCopyUnder` and `duplicate`; in core, `Widget.duplicateOwnProperty`,
`ListWdgt.clearSelection`, `CodeAreaWdgt._hasAFooterBand`, `DivisionStackLayoutSpec.maxFor`,
`StackElementsSizeAdjustingWdgt.maxDimsPuttingMyLeadingEdgeAt` (the solve its `nonFloatDragging` held) and
`LayoutChromeWdgt._resizeCursor` with the hover trio lifted from the splitter; in the toolkit, `_topMemberEditorFor`
(the code-pane verbs' NO MEMBER EDITOR).

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
- [x] U1b: every division stack's splitter 12 px wide with grip dots — CLOSED 2026-11-24 (inspector-overhaul loop, U1b): `Theme.layoutAdjusterThickness` 12, the house's grip dots from one routine (`Appearance._paintGripDots`) shared with a band's strip; five tests' 18 shots recaptured, the predicted set.
- [x] U2: the switch — the row, the rewritten inspector, the member list and editor, the split button; 32 tests and the rigs ported; recapture — CLOSED 2026-11-25 (inspector-overhaul loop, U2): one tool, `InspectorRowWdgt`, a division row of `InspectorWdgt`s each with a `MemberListWdgt` or a `MemberEditorWdgt`, on `BandWdgt`s, with a splitter and a 44 × 44 split button (`SplitGripWdgt`) between two; `ClassInspectorWdgt`, the breadcrumb and the corner chain deleted; the 32 tests ported (six renamed) and the menu sweep, serialization, boot-smoke and parts rigs with them; the suite's failing set equalled the predicted one (16 tests, 46 shots) under mouse and finger, 184 references recaptured. Its Landed paragraph (§6 U2) has what changed against the plan's first text.

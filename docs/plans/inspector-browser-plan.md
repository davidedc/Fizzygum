# The inspector as a browser: a set of columns that scrolls, the body below, packages, method categories and comments

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
**STATUS: AUTHORED 2026-11-26, NOTHING BUILT.** The shape was chosen by the owner over five prototype rounds on the
real build patched at page load (no source change), and the parts no prototype could reach were spiked the same day
(§4). Every fact in §1 and §7 was read off the tree at Fizzygum `6c1f379e` / Fizzygum-tests `701606ae9` (486
SystemTests, gauntlet 20 of 20 legs green on 2026-11-26 03:28). Line numbers drift: the quoted method or symbol name
is authoritative, so grep it fresh before trusting a number. What a prototype or a spike measured is stated as
measured; what it did not reach is stated as a step to verify.

## Mandate

**Turn** the inspector into the one browser the owner chose, and leave nothing of the shape it replaces behind:

- **one tool, a general SET OF COLUMNS** (a choice in one column shows in the next) that **scrolls sideways and
  stops on a whole column** when its columns do not fit. The window's size is the person's: **nothing widens
  itself**, in any holder, at any width;
- the set's **last column, the BODY** (a member's editor, a class's comment), stands where a **setting of the
  browser** puts it. This browser's setting is **below the lists, at the window's full width**, with a divider a
  person drags. The setting is the browser's, never a rule inside the set;
- for code, **four full lists above**: packages, classes, **method categories**, methods and fields;
- a **where-you-are band**, the class named by a **plain button**, **every list its own footer of drawn icon
  buttons**, and **"Open in a new inspector"** by a menu row and by Cmd-click;
- underneath, what the lists need and the product lacks: the meta-object **keeps a class's comments and its
  methods' categories**, read from marker comments in the ordinary source and held to them by a build gate.

This is a transformation, not a second mode beside the first. The window widening itself, the trading of width
between columns that existed to serve it, and the class chip's "toggle that is on" look are **deleted** in the unit
that makes each redundant. Test churn, reference recapture and saved-world compatibility are not constraints (owner,
2026-11-24, standing).

---

## 0. Orientation

### 0.1 What Fizzygum is (one paragraph, then read the CLAUDE.md files)

Fizzygum is a CoffeeScript "web operating system" drawn on one HTML5 canvas. Every class's source text ships in the
page and is compiled in the browser by the meta-system (`src/meta/Class.coffee`), each member alone; there is no
module system (every class is a global; load order is found by scanning source text for `extends X` anywhere on a
line, a comment's included). The **inspector** is its live editing tool: it lists an object's or a class's members,
shows a member's CoffeeScript source, and saves an edit into the running object or class.

Workspace routing: the umbrella `CLAUDE.md` at `/Users/davidedellacasa/code/Fizzygum-all/`, then
`Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md`. Always use the `fg` wrapper by absolute path:
`/Users/davidedellacasa/code/Fizzygum-all/fg`. Never `./fg`, never a hand-chained build, never piped.

### 0.2 Series history, and why this plan exists now

- **`docs/plans/inspector-overhaul-plan.md`** (every unit closed 2026-11-25, its three follow-ups landed
  2026-11-26; the owner has not closed the arc, so it stays in `docs/plans/`). It replaced the two old inspectors
  with ONE tool: a **row of inspectors** in a window (`InspectorRowWdgt`), each inspector one subject and one view
  of it at a time (`InspectorWdgt`), its views small composed widgets (`MemberListWdgt`, `MemberEditorWdgt`,
  `ObjectListWdgt`), the object-versus-class difference held in a member reference (`MemberRef`,
  `ClassMemberRef`). **§5 of that plan is the tool as it stands today; read it.** Its D4 made a drill that does not
  fit WIDEN the window; its §10 rejected a scrolling row; its D16 and §11 named packages, categories and comments
  as "a plan of its own". **This is that plan**, and it overturns D4 and that §10 row (§12 here lists every
  statement it overturns).
- **The owner's doubt, 2026-11-25 evening**: "I'm perplexed because currently it works by expanding the content,
  and the columns _as a whole_ cannot be scrolled. […] And also typically widgets don't expand on their own." A
  scrolling set was agreed, then stopped by a second doubt on 2026-11-26 ("I'm not sure it's going to work well when
  we'll introduce packages and method categories and comments"), which proved right.
- **Five prototype rounds, 2026-11-26** (`Fizzygum-tests/.scratch/inspector-columns/`: the handoff `DECISIONS.md`,
  the dated `LEDGER.md`, the prototype's own record `compare/REPORT.txt`, the pages the owner looked at
  `compare/index.html` and `round2.html` … `round5.html`, the patches `compare/probes/patches/`). Round 1 compared
  five shapes (today's widening; full columns scrolling; light columns; lists above with code below; a fixed
  inspector whose drill opens a window) and refused both the widening and the plain scrolling of full columns at
  every size. Rounds 2 to 5 converged, each on the owner's words, on the shape in §0.4.

### 0.3 ⭐ Critical reframes: read these before anything else

1. **The body's place is a SETTING, and the set does not know it.** The owner, after round 3: "although I want the
   editing window to always be below the columns, don't bake this i.e. don't ruin the general concept of multiple
   columns with one that might be under. I just happen to always have it under, but other generic browsers might do
   otherwise." So the tool is two things: a **sequence of inspectors** with the one rule of choice (what stands
   after the chooser goes; the chosen subject comes), and a **browser** that says where each inspector of that
   sequence stands. Round 4 ran the same code with the setting at "below" and at "beside"
   (`compare/img4/r4ibeside-laptop-mouse-A-end.png`): 10 lines of body below, 28 beside, the row's own logic
   untouched.
2. **The shape is the easy half. Categories and kept comments do not exist in the product.** The prototypes stood
   them in: packages were the build's parts, method categories came from a name rule corrected by hand, comments
   were read from the `.coffee` files in Node. The meta-object reads every member's preceding comment and throws it
   away. Half of this plan's units build what the lists show, not the lists.
3. **A scrolling row settles. The fear that rejected it was not measured.** The earlier plan's §10 rejected a
   scrolling row citing the viewport family's history of livelocks. Run for the first time in round 1, it settled
   at the first attempt at every size, because the row declares its measure to be its whole frame
   (`scrolledContentMeasureIsMyFrame`, `docs/architecture/viewports-and-planes.md`, "The scrolled-content
   contract"): the two writers of the plane's box then write the same box.
4. **A rule that reads a size its own effect changes flip-flops.** Round 2 placed the body by the room left beside
   the lists; one drag of a window's corner moved it 23 times. Every rule here reads a FIELD (a column's stated
   width, a division box), never a laid-out pixel its own outcome moves (`docs/architecture/layout.md` §8 rule 1).
5. **The extra level LOWERED the cost.** With method categories as a list of their own, reaching a method at a
   laptop went from 8 gestures to 3: short lists need no scrolling. The level is no tax to minimise.
6. **Icon footers are what lets four full lists stand whole.** Text footers force about 372 px a list and push the
   package list off a 1366 px screen; drawn icon buttons keep the lists at 236 / 236 / 383 px with the last taking
   the rest, all four whole (`compare/img5/c5-icons-laptop.png`).
7. **Nothing may hold a closure or an off-tree widget** (the earlier plan's reframe 6, unchanged): a widget field
   holding a function makes the world unsaveable, and an owner keeps no widget off its tree
   (`docs/architecture/serialization-duplication-reference.md` §2). Every connection here is a method NAME on a
   target; every inspector of the sequence is a child of the browser's tree; a subject that is no widget is a small
   VALUE an inspector holds and a save carries (`MemberRef` is the worked case).
8. **A table keyed by member names meets `constructor`.** Three prototype bugs were one bug: a lookup in a plain
   object keyed by `"constructor"` answers `Object`. Every store here keyed by member names is made with
   `Object.create null` (as `Class.getSourceOfAllProperties` makes its two), or asked with an own-key test.

### 0.4 The owner's rulings, and the open decisions

**LOCKED** (the owner, 2026-11-25 and 2026-11-26; the words are quoted in
`Fizzygum-tests/.scratch/inspector-columns/DECISIONS.md` §1, and a prototype page and these words disagreeing, the
words win):

| # | Ruling |
|---|---|
| L1 | One tool, a general SET OF COLUMNS. The window's size is the person's: nothing widens itself. The set scrolls sideways and stops on a whole column |
| L2 | The body is the set's LAST column, and where it stands is a SETTING of the browser that uses the set ("don't bake this"). This browser's setting: below the lists, at the window's full width, always, a draggable divider between them |
| L3 | For code, FOUR FULL lists: packages, classes, method categories, methods and fields. "Full": the class's list shows its views as toggles (Categories, Comment, Instances, Subclasses); the member list keeps Methods, Fields, Inherited (and "Own props only" where the product shows it). Nothing folded away |
| L4 | Categories are Smalltalk-style METHOD categories ("initialization", "accessing", "testing"…), a list of their own; the first row "all", not chosen at the start; no "fields" category |
| L5 | Every list its OWN footer of DRAWN ICON buttons, the marks placeholders: the same verbs in the same order; a verb that can never apply to a kind of list is ABSENT, one that cannot apply now is DISABLED |
| L6 | A where-you-are band under the title: each level a finger-sized button that brings its level into view, drawn chevrons centred between them |
| L7 | The class is named by something that does not look like a toggle that is on |
| L8 | "Open in a new inspector" by a menu row (right-click or a hold) AND by Cmd-click, on every thing whose press would add a column; the original stays as it was. No pop-out button in a header |
| L9 | The object flows (a widget, its class, Instances, Subclasses, Children, a field holding an object) run in the same tool and shape |
| L10 | Test churn, reference recapture and saved-world compatibility are not constraints (2026-11-24, standing) |
| L11 | A choice that REMOVES columns leaves the set's scroll where the choice found it; a gap it leaves at the right closes at the next scroll or choice (2026-11-26, over the double-click a removal's clamp would break: §5.3; built in U2) |
| L12 | The where-you-are band's labels are in SENTENCE case ("Class RectangleWdgt", "Child Rectangle 2"), data never re-cased; its buttons are the house's 36 px button in a 52 px band (2026-11-26) |
| L13 | The strip of lists stands 312 px tall over the body below (a member list's three whole rows and most of a fourth; an object column's about two); a divider's drag sets it and it stays (2026-11-26) |
| L14 | The marker gate's budget counts CLASSES holding an unmarked method, not methods (2026-11-26; §5.10) |

**OPEN: ask the owner at the start. On "use the defaults", run on the default of each row.** D1 and D2 decide the
arc's size; the rest are a pass of yes or no.

| # | Decision | Default the loop runs on, and why |
|---|---|---|
| **D1** | **Where real categories come from, and how much of the tree gets them in this arc** | The source says them, as marker comments (`  #: accessing`, §5.10), the meta-object keeps them, a build gate holds them, as a budget that falls. **This arc marks the 64 classes a person opens first**: the `meta-tools` part, `Widget`, `FrameWdgt`, `StringWdgt`, `TextWdgt`, `WorldWdgt`, `ListWdgt`, `PanelWdgt`, `RectangleWdgt`, `Point`, `Rectangle`, `Color`, the desktop's and the Examples folder's apps and what their windows hold, and every superclass of those (so Inherited inside a category finds its methods): 1594 of the tree's 4764 methods. No method is moved in its file (markers are inserted; a category may open more than once in a file). A class with no marker shows "all" alone. Options and their cost: below |
| **D2** | **Which verbs work on CLASSES at first landing** | **Add** (a new class in a package; a new subclass of a class) and **remove of a class made at run time** (no instance, no subclass, named by no other class's code). Duplicate and rename are ABSENT and filed. For a class the build ships, rename and remove are not honourable without writing files out (§4.4). It is its own unit, U9, the last to build, so everything else lands whatever becomes of it. Options and their cost: below |
| D3 | Comments | Shown and EDITABLE: a member's comment stands above its code and Save keeps both; a class's comment is its "Comment" view, with a Save. §4.2 measured that the edit path already takes a comment typed above a function; what U5 adds is that it is kept as the member's comment and survives a snapshot |
| D4 | Writing an edit back to a `.coffee` file | NOT in this arc. Edits live in the running classes and in the world's change list, as today. Filed (§11) |
| D5 | The default window | 1000 × 808, clamped to the desktop (§5.13). 760 × 528 (the ruling of 2026-11-24, for the earlier shape) shows one line of body here. The review page shows it at a desk, a laptop, a tablet and a phone |
| D6 | How a person opens the code browser | A row "Code browser" in the "Dev tools" menu, beside "Inspect" and "Console" (§5.12). No desktop icon: the desktop's icons are the owner's curation |
| D7 | Finding by name (a class in another package costs about a hundred wheel notches; a widget's `color` about 250 rows) | NOT built unseen. U10 builds two candidates on the real build patched at load (a filter line over a long list; a "Find…" prompt that jumps to a class or a member by name), puts them on the review page with counted gestures, and PARKS for the owner's choice |
| D8 | The Fields toggle inside a category | ABSENT there (a category lists methods); under "all" the list is today's. Round 5 pictured both (`compare/img5/b5-alt-laptop-category.png` is this one). The Methods toggle stays, as pictured, though a category holds only methods: say if it should go too |
| D9 | The object flows' rough edges (§4.1's last bullet): which are fixed here | FIXED: the trail's wording (a level made through the class button or a list of objects says its relation: "class RectangleWdgt", "instance Rectangle", "child Rectangle 2", §5.5); a walk keeps its view (a subject chosen in a list of objects opens on the view of the same title when it offers one that is not empty: a subclass chosen in Subclasses opens on its Subclasses, a child on its Children, a leaf on its first view). FILED, each a BACKLOG line: an instance named "Rectangle" in a list and "rectangle" in its header; a drilled value leaving the body empty (it is the model: the body is the set's last column); a class's view toggle closing what stands right of the class; a separately opened window that looks like its original |
| D10 | The table of which buttons, and when (§5.7) | As §5.7: the product's rule for members unchanged; children and instances duplicate and remove (never a window's content) — PARKED as U3.2 and asked of the owner 2026-11-27: the premise does not hold (§5.7 "As built in U3"); categories add, rename, remove-when-empty, never duplicate, nothing on "all"; packages no button; classes by D2 |
| D11 | The icons | The arc ships four simple drawn marks. Final icons are the owner's (the umbrella's `/convert-icon-size-aware` way), filed |
| D12 | Where a separately opened inspector lands, and its title | Beside the original where the desktop has room (right, then left, then below), else cascaded 48 px; inside the desktop always. Its title names the thing alone ("Inspector — color") |
| D13 | A class with no category | Its list shows "all" alone, and that row is chosen as the list opens (L4's "not chosen" is about a list with more than one row) |
| D14 | Moving a method to another category | A row "Move to category" in the member row's menu, opening the class's categories as a menu (§5.14). Not prototyped: the review page shows it, and it is one row to take out |
| D15 | A package whose part is not loaded yet | Listed; choosing it loads it, then lists its classes (§5.11) |
| D16 | The finger's control for the split between the lists and the body (the prototypes drew a 12 px divider alone, which no finger's rule allows) | A tab joined to the divider, at the left end of the body's header: the split button of today turned a quarter (§5.4). NOT seen by the owner: on the review page before U2's gauntlet |

**D1, the options.** All share the mechanism (U5: the marker, the meta-object's stores, the gate). They differ in
U6, the comment-only edits:

| Option | Classes, methods | What the browser shows | Cost of U6 | Risk |
|---|---|---|---|---|
| a. The inspector's own classes only | 12 classes, 186 methods | Categories in the `meta-tools` package; "all" alone everywhere else | half a day | The level looks empty wherever a person looks first |
| **b. The classes a person opens first, with their superclasses (default)** | **64 classes, 1594 methods** (a third of the tree; `Widget`, `FrameWdgt`, `StringWdgt` and `WorldWdgt` hold 858 of them) | Categories on every widget's inherited members and on the classes the desktop leads to | 1 to 2 days: one careful agent pass per big class, small classes in batches, a sampled review; about 900 marker lines | The four big classes are where a name rule did worst (a quarter to a third right): they are read, not ruled |
| c. The whole tree | 560 classes, 4764 methods | Categories everywhere | 4 to 6 days; 1600 to 2500 marker lines in about 370 files; about 3100 placements by judgment | Too many judgments to review in one arc; the budget lets the rest fall over time instead |

Whatever the option, the gate's budget is set at what is left, and falls as classes are marked.

**D2, the options** (costs from spike S3's run, in lines of product code, tests apart):

| Option | What the classes list offers | Cost | What it risks |
|---|---|---|---|
| a. Nothing yet | No footer on a package's classes or on Subclasses; filed | 0 | The browser cannot make a class |
| b. Add only | Add | about 90 lines, one new snapshot record replayed before a load's teardown | A class made by mistake stays until the page reloads, and rides every snapshot |
| **c. Add, and remove of a class made at run time (default)** | Add; Remove, enabled only for such a class with no instance, no subclass and no code naming it | about 135 lines, the same record | The load path changes (its first step); an inspector left open on a removed class is the worst outcome found, and remove closes them first |
| d. All four, for classes made at run time | Add, Duplicate, Rename, Remove | about 250 lines | Rename breaks every other class's code that names the old class, changes every instance's id and leaves subclasses' texts stale; duplicate copies references to its own name as references to the original |

### 0.5 Cold-execution protocol (read and run in this order)

1. **Orient:** `/Users/davidedellacasa/code/Fizzygum-all/fg status`. If `Fizzygum` or `Fizzygum-tests` is dirty with
   another arc's work, **stop and ask**: this plan touches `src/meta-tools/`, `src/meta/`, `src/serialization/`,
   `src/basic-widgets/`, `src/macros/`, `buildSystem/`, both repos' docs and about fifty tests.
2. **Read**, in this order: the three CLAUDE.md files; `docs/plans/inspector-overhaul-plan.md` §0.3, §5 whole (the
   tool as it stands) and §8 (what its risks turned out to be); then in `Fizzygum/docs/architecture/`:
   - `widget-authoring-guidelines.md` (whole: every new class here is a widget class or a value an inspector holds);
   - `layout.md` §2 (settle tiers), §4.2 (the layout-spec family), §8 (the rulebook);
   - `viewports-and-planes.md` whole ("The scrolled-content contract" and "Drag-to-scroll" twice);
   - `input-and-gestures.md` (who keeps a press; the direction latch; a hold by finger);
   - `lint-and-static-checks.md` §3 (the gate table), §3b (what a finding means), §8 ("Add a new gate");
   - `serialization-duplication-reference.md` §2, §4a, §5, §9, §12 (the world's change list);
   - `visual-design-system.md` §4.1 (seams), §4.2 (the 44 rule), §4.3 (toggle, chip, footer band), §5;
   - `build-and-packaging.md` §2 and §5 (the lazy doors; when the reflective layer arrives);
   - `constructor-and-parameter-conventions.md`; `immutable-value-classes.md` (for the new values).
   Then `Fizzygum/src/macros/CLAUDE.md` and, in the tests repo, `DETERMINISM.md` §1–§2.
3. **Read the code this plan builds on**, whole: every file in `src/meta-tools/`, `src/meta/Class.coffee`,
   `src/serialization/SourceEditsRegistry.coffee`, `src/basic-widgets/ViewportWdgt.coffee` (its arrange and its
   scroll step), `src/VerticalStackViewportWdgt.coffee` and
   `src/basic-widgets/menu-system/PopUpRowsViewportWdgt.coffee` (the two models of a role-named viewport),
   `src/ListWdgt.coffee`, `src/StackLayoutEngine.coffee`, `src/StackElementsSizeAdjustingWdgt.coffee`,
   `src/LayoutChromeWdgt.coffee`, `src/PartsRegistry.coffee`, and the block "THE INSPECTOR'S TWO LOCATORS" of
   `src/macros/MacroToolkit.coffee`.
4. **Look at what the owner saw**: `Fizzygum-tests/.scratch/inspector-columns/DECISIONS.md`, then the pictures
   `compare/img5/c5-icons-laptop.png`, `compare/img5/a5-code-menu-laptop-s2.png`, and the object flows of
   `compare/round4.html`. The patches that made them are no model for the code (they hang functions on widgets and
   lay a holder out by hand).
5. **Ask the owner** the OPEN decisions of §0.4.
6. **Run the units of §6 in order.** Each ends with its gate, then the commit (ask before every commit and push,
   unless the owner has granted otherwise), then a tick in §6's table.
7. **A failing reference is never "benign churn" unseen.** U2 and U3 change nearly every inspector screenshot on
   purpose (§7.1 names which); every changed shot is looked at before it is re-taken (`fg diffpage <test>`), and a
   test outside the predicted set is a finding.
8. **Long operations** (`fg presuite`, `fg gauntlet`, `fg recapture`) run in the background with a log; peek at
   `/tmp/fg-<cmd>.verdict` every ~5 minutes, never in a polling loop. Never pipe a gating `fg` call.
9. **A gate finding is answered by its class** (`lint-and-static-checks.md` §3b). A shape is never bent to fit a
   count: where the right shape needs a budget moved, move it in the same change with a dated reason beside the
   number.

---

## 1. What stands today (verified 2026-11-26)

The tool as built is §5 of `docs/plans/inspector-overhaul-plan.md`, class by class with its code; this section
states only what this plan changes or leans on. Files are in `Fizzygum/src/meta-tools/` unless a path says
otherwise. The research that read all of it, every fact with its line, is
`Fizzygum-tests/.scratch/inspector-columns/RESEARCH.txt` (written before the follow-ups landed: grep the names).

### 1.1 The row, its columns and what the widening needs

- **`InspectorRowWdgt`** (a `ClippingWdgt`) is the tool: the content of the window "Inspect" opens
  (`Widget.spawnInspector`, `src/basic-widgets/Widget.coffee`), 760 × 528 (`InspectorRowWdgt.defaultExtent`). Its
  children are its inspectors and the splitters between them, the elements of ONE horizontal division row
  (`StackLayoutEngine`): the row is always DIVIDED, so its cells share exactly the width it is given.
- **The rule of choice** is the row's: `InspectorRowWdgt.showChoice chooser, subject` (a static: it climbs from the
  chooser to the inspector, then asks that inspector's PARENT, one level up, for `showNextTo`), `showNextTo`,
  `_showNextToNoSettle`. A subject the next inspector already shows is RELOADED there (a member's editor takes its
  saved text back as one step of its undo history); any other replaces everything right of the chooser. A chooser
  in no row opens the subject in a window of its own.
- **The widening.** A choice that leaves the row narrower than its cells' least widths widens its WINDOW
  (`_widenMyWindowToFitNoSettle`, toward `_normalWidthOf` the added inspector), only when that window stands on the
  desktop, only rightward, only as far as the desktop's right edge. In any other holder (a panel, a document, a
  dock, a transform island) and past that edge the inspectors NARROW and the row cuts them. One click therefore
  behaves differently by where the window stands, what holds it and the screen.
- **What exists only because the row trades width** (a drag on a splitter raises the most width of the cell on one
  side and lowers the other's, `StackElementsSizeAdjustingWdgt.maxDimsPuttingMyLeadingEdgeAt`):
  `InspectorWdgt._defaultBox`, `mostWidthGivenAway`, `_giveUpMostWidthNoSettle`; `rowSlackWeight` on
  `MemberEditorWdgt` (100), `MemberListWdgt` (0.01) and `ObjectListWdgt` (0.01); the HEIR rule and `sameKind` in
  `InspectorRowWdgt._showNextToNoSettle` / `_removeInspectorsNoSettle`; the widths an object list keeps across a
  view switch (`ObjectListWdgt.leastWidthKept` / `desiredWidthKept`, `InspectorWdgt._showViewNoSettle`'s `kept`);
  the width a view's PLACE desires (`InspectorWdgt.viewsPlace`).
- **The splitters are derived** (`_reconcileSplittersNoSettle`: exactly one between two inspectors side by side),
  each a `StackElementsSizeAdjustingWdgt`, the class the halo's layout adjusters and "Edit layout" use for every
  division stack. The split button (`SplitGripWdgt`, a tab joined to the splitter in the header of the inspector on
  its right) finds its splitter by asking its inspector, which asks ITS PARENT (`InspectorWdgt._splitterBeforeMe`:
  `@parent?.splitterBefore? @`).
- **Neither the splitter nor the split button keeps the press** (no `pressBegan` of their own; the handle that
  does: `HandleWdgt.pressBegan`), so inside a pane that scrolls by a plain drag the pane scrolls under their drag.
- **The body the inspectors stand on** is painted by the row (`laysTheInspectorBodyUnderItsParts`,
  `InspectorBodyAppearance`, which asks the widget's PARENT).
- **Who assumes "an inspector's parent is the row, and the editor is the row's next inspector"**: `showChoice`
  and `_splitterBeforeMe` above; the macro toolkit's `memberEditorFedBy` (`src/macros/MacroToolkit.coffee`, the
  block "THE INSPECTOR'S TWO LOCATORS": `inspector = memberList?.parent; row = inspector?.parent;
  row.inspectors()`), `topMemberList` (the RIGHTMOST member list of the front window); the rigs of §7.3.

### 1.2 The header, the chooser, the lists, the editor

- **`InspectorWdgt`**: a vertical division stack of its header band (its subject's name; a `ChipWdgt` built
  `current: true` naming the class above the subject, whose press chooses that class: `chooseMyClass`), its chooser
  band when its subject offers more than one view (`_views`, a hand-kept table by what the subject holds or
  answers: "Source" for a member; else "Members", then "Children" for a widget, "Instances" and "Subclasses" for a
  class's prototype), and its view. `ChipWdgt` has no other user in `src/`; its `current` look is the theme's
  `chipCurrentFill` / `chipCurrentStroke` / `chipCurrentText`, the values of a toggle that is on.
- **`MemberListWdgt`**: a toggles band (Methods, Fields, Inherited, and "Own props only" on an object), the list,
  a footer band of four TEXT buttons (Add… Duplicate… Rename… Remove) built only where the subject's members can be
  edited (`MemberRef.canEdit`). Add… is never disabled; the other three are enabled exactly while the chosen
  member is one the subject owns and is not `constructor` (`_reflectMemberSelection`,
  `MemberRef.canBeRenamedOrRemoved`). With the footer its desired width is about 372 px.
- **`ObjectListWdgt`**: one list of objects by a named derivation (`_childrenOfMySubject`,
  `_instancesOfMySubject`, `_subclassesOfMySubject`), no footer; the objects are derived, never carried by a copy or
  a file.
- **`MemberEditorWdgt`** (the code-area family): the text its member reference shows (`MemberRef.shownText`) and a
  Save that hands the text to `MemberRef.save`. Everything the editor asks of its subject is five things:
  `holder`, `name`, `shownText()`, `save(text)`, and the class question `MemberRef.canEdit holder`.
- **The door on a member**: `Widget.spawnInspector inspectee, member: name` opens the row and calls
  `InspectorRowWdgt.chooseMember`, which asks the FIRST inspector's view to choose it
  (`MemberListWdgt.chooseMember`). The paint tools are edited through it (`_memberToEdit`, "Edit code").
- **A click already carries its modifiers**: `ActivePointerWdgt` hands `activated` the event's `ctrlKey`,
  `shiftKey`, `altKey` and `metaKey`. No widget reads `metaKey` at a click.
- **User mode builds no widget's menu** unless the widget names code a person edits (`Widget.buildContextMenu`'s
  branch for `_memberToEdit`: a one-row menu titled with the widget's name). Developer mode builds the hierarchy
  menu.
- **The widget menu's "Duplicate" is a copy in place** (`duplicateMenuAction`), its "Close" / "Delete" is `close`.

### 1.3 The model: what the meta-object keeps, and what it throws away

- **A class's text is parsed by lines** (`src/meta/Class.coffee`: `_parsedSource`, `getSourceOfAllProperties`,
  `findUpTo`). A member starts at a line `  name: …` (two spaces; `@name:` is a static). Its BODY runs to the next
  line that is a comment at exactly two spaces (`topLevelCommentRegex`) or another member's line. What stands
  between one member's body and the next member's line is that member's STASH (`propertyComment = returned[1]`),
  read and DROPPED; so is everything before the `class` line (`[name, ignored, sourceLines] = …`), and everything
  after the last member's body.
- **What it keeps**: two stores, name to source, both made with `Object.create null`:
  `nonStaticPropertiesSources` and `staticPropertiesSources`, each in the order written. With each function it
  makes it keeps the source that made it (`Class.memberRecordOf`), and with each prototype the value each field's
  source made (`Class.fieldRecordHolds`).
- **An edit** is `Class.applyMemberEdit memberName, source` (compiles first, changes nothing on an error) or
  `removeMember`; a rename is an edit under the new name and a removal of the old. Only
  `ClassMemberRef._editClassMember` / `_removeClassMember` call them from a gesture, each then recording
  (`SourceEditsRegistry.recordClassEdit`: `{scope: "class", className, propertyName, source}`;
  `recordClassMemberRemoval`: `{…, deleted: true}`) and telling the world once (`WorldWdgt.noteCodeChanged`).
- **A world snapshot** carries those records (`section.sourceEdits`) and replays them at load, before any widget
  is restored: the page's classes are first returned to their boot sources
  (`SourceEditsRegistry.returnThePageToBootSources`, by `Class.membersAwayFrom store, boot`, which compares SOURCE
  strings only), then the file's records are applied in order (`replayClassEdits`). A record with extra fields is
  not refused (`SourceEditsRegistry.isARecord`).
- **Where a meta-object exists**: on the compile-at-boot pages (every dev page, the harness page) for every class
  at boot; on a pre-compiled tree (`homepage`) only once the reflective layer is loaded, which opening an inspector
  already awaits (`new Class text, false, false`: a parse only); on a lazy part's classes when the part loads; on
  `lean` never (it ships no inspector either). `Class` itself has no meta-object.
- **A class's statics** show only in an inspector on the class FUNCTION (reached by a double press on a prototype's
  `constructor` row), read-only, never recorded. A prototype's member list never lists them.
- **A package** is a build part. The page knows a class's part two ways that agree: the build manifest
  (`window.FIZZYGUM_PARTS[part].classes`, present from boot for every part but `core`, a lazy part's included) and
  the vault's tag (`SourceVault.store name, text, part`, for every source the page holds, `core` included;
  `SourceVault.namesForPart`). No API lists the parts. On a tree whose sources are lazy the vault is empty until the
  reflective layer loads.
- **A class can be made at run time today**, by the boot's own path (`new Class text, false, true`); two SystemTests
  do it, no product code does. Nothing records it: a snapshot holding its instance is refused in a fresh page
  ("it uses SpikeFooWdgt, which this build does not have"), before anything changes.

---

## 2. Why things are shaped this way

- **Why the window widens today.** The earlier plan measured, in its spike, that a row made a viewport's content
  "kept its own height when the window grew", and read the viewport family's history of two-writer livelocks as the
  cost of fixing it. So it kept the row DIVIDED (the stack engine hands out exactly the width it is given) and let a
  drill that did not fit widen the window instead (its D4), "nothing ever dropped from the left". The measurement
  was of a plane that had declared nothing: the five declarations of §5.3 are what that spike lacked.
- **Why columns trade width.** A divided row moves a split by trading the most widths of the two cells beside it,
  their sum unchanged. Everything in §1.1's fourth bullet exists to keep a person's split standing across a choice
  in a row that trades. A row whose columns each have a width of their own has no trade to remember.
- **Why the class is a chip that looks ON.** The chip was the one survivor of the old breadcrumb, whose current
  class wore the accent; alone in a header it reads as a toggle that is on (owner, after round 3).
- **Why the meta-object drops comments.** `Class` was written to turn a class's text into its members' code; an
  inspector that showed a member's source came later and read the same stores. Nothing has needed a comment at
  run time until now (§1.3).
- **Why there are no method categories.** The source has never had them: a handful of files carry hand-drawn
  banners, most carry nothing (§4.3).

---

## 3. The distilled argument

1. **Widening is the wrong mechanism, by the owner's own test** ("typically widgets don't expand on their own"),
   and by measurement: at every size round 1 tried, the widening columns and the plain scrolling of FULL columns
   were both refused once a fourth and fifth level existed (about 1900 px of lists and editor).
2. **What a level COSTS decides the shape, not how the row overflows.** Two levers made four levels fit: the body
   out of the row (below, at full width, where code wants to be), and footers that do not set a list's width
   (icons). With both, a laptop shows all four lists whole and ten lines of code.
3. **The set stays general because the body's place is the browser's setting.** The same sequence, the same rule
   of choice and the same set serve "below" and "beside"; another browser sets the other. Nothing in the set
   knows.
4. **A scrolling set is uniform where the widening forked**: one behaviour in every holder and at every width, down
   to one column in view. The one place where the holder decided behaviour is deleted, not guarded.
5. **The model is small where it touches the meta-object** (§4.2): the parse already walks every comment line it
   drops; keeping them is two stores beside the two it fills, and a category is one more read of the same lines.
6. **What failed before, and what is different**: the scrolling row was rejected unmeasured (reframe 3); the first
   scrolling design of this arc kept the lists full and the editor in the row, and the owner's doubt stopped it
   before it was built; the shape here was compared on the real build, five times, before a line of plan.

---

## 4. What was measured (2026-11-26): the prototypes, then four spikes

Nothing in this section changed a source file. The prototypes are patches applied to the running page
(`Fizzygum-tests/.scratch/inspector-columns/compare/probes/patches/`); the spikes are read-only probes and their
reports (`Fizzygum-tests/.scratch/inspector-browser-loop/spikes/S1-REPORT.md` … `S4-REPORT.md`, each fact with its
file and line, each number with how it was measured).

### 4.1 The shape (prototype rounds 4 and 5; `compare/COUNTS-4.md`, `COUNTS-5.md`, `REPORT.txt` from line 505)

- **The scrolling set settles** at every size tried (760 × 720, 1366 × 768, 1440 × 800, a tablet, a phone both
  ways), mouse and finger, with the five declarations of §5.3. The two hazards (§5.3) were each reproduced and each
  fixed, with a control run.
- **Rows and lines.** With full lists and the body below, the strip of lists was 312 px at every size and the
  lists showed 6 / 6 / 5 / 4 rows (packages, classes, categories, members); with a footer on every list 6 / 5 / 4 /
  4 (the package list has none). The body: 10 lines × 191 characters at 1366 × 768, 7 × 104 at 760 × 720, 11 × 202
  at 1440 × 800, 10 × 142 on the tablet, 14 × 52 on the upright phone.
- **The least window for five rows a list and ten lines of body is 807 px tall**, at any width: the member list's
  own bands (144 px) decide it. A 1366 × 768 screen is 39 px short. Today's default window is 760 × 528.
- **Widths, icon footers**: 236 / 236 / 383 px and the last list the rest. The class's list is 383 px because of
  its four view toggles, in every footer variant.
- **Gestures** (presses plus wheel notches) at a laptop, code tasks: reach a method from a package 5; a sibling
  method 2; a method in another category 7; a sibling class 4; a class's comment 2; edit and save and save back 13.
- **The object flows** cost far more, for a reason that is the product's and not the shape's: a widget's own
  `color` is not in its member list until Inherited is pressed, and then stands about 250 rows down (137 gestures
  to change a rectangle's colour, 107 of them reaching the row). "Own props only" with Inherited leaves 33 rows,
  `color` the 20th.
- **Opening separately**: the menu row costs 2 gestures, Cmd-click 1, and each left the original identical in every
  run. At a laptop a browser fills the screen, so the new window cascaded every time.
- **What confused**, seen in the pictures: the trail reading "rectangle › RectangleWdgt" and "rectangle › rectangle
  › rectangle"; an instance named "Rectangle" in a list and "rectangle" in its header; each Subclasses level needing
  a second press; a drilled value emptying the body; a class's view toggle closing everything right of the class; a
  separately opened window looking exactly like its original; developer mode's menu putting the new row above eight
  rows naming the widgets under the pointer.

### 4.2 The meta-object: comments, the edit path, the cost (spike S1)

- **The parse drops about 47 % of the shipped class text**: 1.77 MB of stashes before members (3756 of 6833
  members have a comment there) and 354 KB of class headers (330 of 560 classes have one). It is lossless at the
  line level (all 560 files regenerate byte for byte from the lines it walks); the strings it KEEPS are not (a body
  that is one blank line joins to the empty string).
- **A stash is not simply "this member's comment"**: about 240 section banners in four hand-drawn styles stand in
  stashes; 137 stashes hold two or more comment groups; 76 end in a blank line (a note detached from the member);
  229 classes have a comment in their FIRST member's stash, 79 of them with no header before `class` (their class
  description is written inside the body). Four classes lose real notes written after their last member. No member
  body anywhere holds a two-space `#` line that would end it early. Store order is source order in every class; no
  member name is integer-like.
- **A comment typed above a class member's function in the editor is accepted today**: compiled, kept word for
  word in the store and with the function, shown back, recorded and replayed. The BOOT path cannot take a comment
  glued to a member's text (the compiled function loses its parse-time name, and a member that needs a helper trips
  `HELPER_VAR_NOT_STRIPPED`). So a member's comment lives in a store of its own, never in its source string.
- **`Class.membersAwayFrom` and `replayClassEdits` compare and apply source strings only**: a comment or a category
  kept beside the source and changed by an edit would not be returned to boot at a load, counted in the load's
  confirm, or replayed, unless both are taught. Duplicate and rename copy the source string only.
- **Keeping every stash costs** (`index-sw.html`, Chrome, medians of 5): the parse 26.2 ms to 39.8 ms; the boot
  1916 ms to 1920 ms (within noise); the heap after a collection 63.65 MB to 68.00 MB. The vault already holds every
  byte for the page's lifetime: the kept comments are copies.
- **Who else reads what this touches**: the `null-literal` stink's sanction for `getSourceOfAllProperties` pins
  exactly two `Object.create null` there; `buildSystem/lib/call-sites.js` maps a member's lines back onto its file
  verbatim (a source string must never gain its stash's lines); the serialization rig's `bootOfClass` reads the two
  parse functions' results BY POSITION (`[2]`, `[1]`: elements may be appended, never reordered); seven SystemTests
  read the stores (S1's Q3 names them), one of which opens an inspector ON a meta-object and lists its fields.
- NOT RUN: a pre-compiled tree and `lean` (none on disk; a spike may not build). `fg homepage` after U5 is their
  first run.

### 4.3 The tree's methods, and what organisation exists (spike S2)

- **4485 instance methods and 279 static ones in 560 classes** (1793 instance fields, 276 static). Per class: median
  2, ninth decile 17, largest `Widget` with 396; 367 classes have five or fewer; seven have more than a hundred.
- **Existing banners are not categories**: 83 classes carry a decorated or titled comment line at the member column
  (about 290 lines in six forms), 477 carry none. They name topics and cite plans; read as "applies until the next
  marker" they over-apply (`TextWdgt`'s one banner would file 24 members under "text widget measuring", `edit` and
  `tripleActivated` among them). Only 44 lines of Morphic heritage (`# Point comparison:`) are category-shaped.
- **The prototype's name rule does not scale**: over the whole tree 50.7 % of instance methods land in a fallback
  ("as yet unclassified" 28.4 %, "private" 22.3 %). Judged by hand on six classes (290 methods), 63 % needed a move.
  Assigning the whole tree is therefore about 4760 methods to read, about 3100 of them placed by hand, and 1600 to
  2500 marker lines in about 370 files if no method is moved in its file.
- **A vocabulary** the data supports (S2's Q3, "Vocabulary"): sixteen names that recur across the tree's kinds of
  class, most of them already implied by a house convention, with the classic value-class names beside them. The
  prototype's "choosing", "filtering", "member editing" are the inspector's own verbs: right there, wrong elsewhere.
  A few big classes want a name or two of their own.

### 4.4 Class-level verbs, run in a live page (spike S3)

- **Add works today with no product change to make the class**: `new Class text, false, true` on a one-line text
  (`class X extends Y`) gives a class that the member list, the class button, Instances and the parent's Subclasses
  all show at once, whose members are edited and recorded as any class's.
- **A snapshot does not carry it**: saved, and loaded in the same page, fine; in a fresh page the load is refused
  before anything changes. ONE more record in the same ordered log, carrying the class's whole text and its part,
  applied by hand before the load, made the fresh-page load work (the instance back, the member edits replayed, the
  inspectors on its prototype restored). It must be replayed at the load's first step
  (`Deserializer.loadWhatItNeeds`), not after the teardown: the checks that run before the teardown leave a class
  that is still to arrive unjudged.
- **A new class's name must be checked first**: an existing class's name silently redefines it and leaves the world
  unsaveable; `Audio` overwrites the browser's own constructor; `toString` becomes a class. One test refuses them
  all: a capitalised identifier, not a reserved word, and no `name of window`.
- **Remove works for a class made at run time** with no instance and no subclass (the global, the vault's entry and
  its line count go; its records must be pruned or a fresh page makes it again). **Rename works for one too**, at
  the highest cost: every other class's code naming the old global throws, every instance's id changes, a subclass's
  text still says the old name.
- **For a class the build ships, rename and remove are not honourable**: a fresh page boots the old name;
  `RectangleWdgt` is named in the code of 5 other classes and in 171 test files, `Point` in 241 classes.
- **Duplicate** from the current stores compiles to a working class; it loses every comment (until U5 keeps them)
  and its references to its own name still name the original.
- **The worst outcome found**: an inspector left open on a removed or renamed class's prototype still takes edits;
  its Save writes a record for a class that is gone, throws in layout (`LAYOUT_ERROR`), and the world cannot be
  saved while it stays open.
- **Packages**: nineteen parts on the page tried, their classes 242 (`core`) down to 1; no verb on a package has an
  honest meaning at run time (a part is build data: a fresh page has it as the build made it).
- NOT RUN: `index.html` (a lazy part not yet loaded), any pre-compiled tree, anything about categories (nothing
  exists to run).

### 4.5 The prediction: the suite under the whole shape (spike S4, then two suite runs)

The prototype's chosen shape (round 5: the set in a viewport, the body below with its divider, the trail, the plain
class button, icon footers, the menu row) was assembled as ONE prelude that installs itself in the harness page for
every test and opens it through the product's own doors (`spikes/s4-shape-prelude.js`, built by
`s4-build-prelude.js` from the seven patch files copied unchanged; a second file, `s4-shape-prelude-locator.js`, is
the same with the macro toolkit's `memberEditorFedBy` taught to find a body that stands below). Proved on single
tests first (a test that opens no inspector passes byte for byte with the prelude installed; the picture
`spikes/s4-proof-inspect.png` shows the shape on screen through "Inspect"), then the whole dpr-1 suite, mouse, was
run under each (`node scripts/run-all-headless.js --prelude=<file> --max-stalls=60`, from `Fizzygum-tests/`; logs
`spikes/suite-under-locator-prelude.log` and `suite-under-base-prelude.log`; the reading `spikes/PREDICTION.md`).

- **Under the shape with the toolkit's locator taught: 486 played, all 8 shards complete, 43 FAILED, 443 passed.**
  Every one of the 43 is among the 48 tests that touch the inspector by code (§7.1). **No test outside them failed:**
  the shape reaches nothing that does not open an inspector.
- The 5 that touch the inspector and still pass: `macroAStepThatThrowsStopsStepping`,
  `macroInspectorOnAClassShowsItsStaticsSource`, `macroInspectorOnNonWidgetIsReadOnly`,
  `macroInspectorSaveRefusesCodeThatDoesNotCompile`, `macroInspectorShowsAnUndefinedFieldAsUndefined`.
- All 21 tests of the churn set fail, as they must (their pictures show a member list).
- **Most of the 43 do not fail on pixels alone**: three do (`macroAnalogClockInspectEdit`,
  `macroInspectorCutListSaysSo`, `macroInspectorShowsAValueAsCode`); the others break a macro's step or an
  assertion first, by the mechanisms §7.1 tabulates (a window read from a list by a `.parent` chain; a row index;
  a class opening on its categories; asserted widths of a widened window; a target scrolled out sideways, which the
  toolkit reports as an aim missed). The ports are the larger half of U1 and U2, not the recapture.
- **Under the shape with the toolkit untouched: 47 failed**, the same 43 and four more that fail ONLY on the
  toolkit's locator (the editor read as "the row's next inspector"): `macroAStepThatThrowsStopsStepping`,
  `macroInspectorOnAClassShowsItsStaticsSource`, `macroInspectorSaveRefusesCodeThatDoesNotCompile`,
  `macroInspectorShowsAnUndefinedFieldAsUndefined`. One touching test passes under both:
  `macroInspectorOnNonWidgetIsReadOnly`. So the port of the locator alone (U1.6) clears four tests, and no more.
- **What the picture says of the default window**: opened at today's 760 × 528, an object's column (header,
  chooser, toggles, footer) shows ONE row and the body two lines of code (`spikes/s4-proof-inspect.png`). Decision
  D5 is not a nicety.
- **What this run cannot see**: it is the WHOLE shape at once, so each unit still predicts its own set (U1 claims
  far fewer); the prelude stands in no packages and no comments (a door on a class opens on that class's stood-in
  categories); a row built with no window keeps its body beside; Cmd-click is inert (the toolkit queues world
  events, never DOM ones); finger, dpr 2 and WebKit were not run.
- **A run under a prelude that makes macros throw needs `--max-stalls=60`**: a macro that throws never ends its
  test, the runner waits 30 s for each and abandons a shard after 12, and the 27 `macroInspector*` tests sort into
  one shard.

---

## 5. The target

§5.1 to §5.8 are the SHELL (units U1 to U4): the shape, on the subjects the tool has today. §5.9 to §5.13 are the
MODEL and the levels it feeds (units U5 to U8). Code here is a sketch checked against the tree on 2026-11-26, not
text to paste: every member is checked against the file as it stands, `docs/architecture/widget-authoring-guidelines.md`
and the gates. A header comment given here is the class's contract: the unit that builds the class writes it true.

### 5.1 The classes

| Class | Kind | What it is |
|---|---|---|
| `InspectorBrowserWdgt` | NEW, the tool | What "Inspect" opens and a window holds. It owns the SEQUENCE of inspectors and the rule of choice, and says where each inspector stands: its lists in the set, its body where its setting says (`bodyPlace`: `"below"` or `"beside"`). Top to bottom the cells of one vertical division stack: the trail band, the set's viewport, and, when the body stands below, a divider and the body's place |
| `InspectorRowViewportWdgt` | NEW, the set's viewport | A `ViewportWdgt` of the house's role-named family (`VerticalStackViewportWdgt`, `PopUpRowsViewportWdgt` are the models): content-sizing, its plane holding no loose content, no drops, no scroll-policy toggle, no editing amenities. It scrolls sideways only, rests on column edges, and reveals a column |
| `InspectorRowWdgt` | CHANGED, the set | The ROW of inspectors and the dividers between them, the plane of that viewport. It keeps its structure (its cells, its derived dividers, each inspector's split button) and gains its measure. It LOSES the rule of choice (to the browser), the widening and the trading |
| `InspectorColumnDividerWdgt` | NEW | The divider between two columns of the set: the look and the joined split button of today's splitter, a drag that sizes the ONE column on its left. It keeps the press |
| `InspectorWdgt` | CHANGED | One column: unchanged in what it is. Its class is named by a plain button; it holds its stated column width; the trading members go |
| `MemberListWdgt`, `ObjectListWdgt` | CHANGED | Each ends in the one icon footer (§5.7); the object list gains derivations (§5.11) |
| `ListVerbsBandWdgt` | NEW | The ONE footer of every list: a band of drawn icon buttons, one per verb its list's kind offers, each enabled by the list's own rule |
| `PackagesRef`, `PackageRef`, `CategoryRef`, `ClassCommentRef` | NEW, values | The subjects of the new levels (§5.11), small values an inspector holds and a save carries, as `MemberRef` is |
| `ChipWdgt` and the theme's `chip*` roles | DELETED | Their one user, the class chip, becomes a plain button (U2) |

All of it stays in the lazy `meta-tools` part (`buildSystem/parts.json`), reached from core through the doors of
§5.12 only, each under `world.parts.whenAllLoaded` (the two existing doors' comments in `Widget.spawnInspector` say
why a class-existence guard is wrong for a lazy part).

### 5.2 The picture

The owner looked at `Fizzygum-tests/.scratch/inspector-columns/compare/img5/c5-icons-laptop.png` (the code path)
and `compare/round4.html`'s object flows. In words, top to bottom, a 1366 × 768 window on the code path:

```
┌ Inspector — Packages ─────────────────────────────────────────────────────────────────────────────┐  title bar
│ [meta-tools] › [InspectorRowWdgt] › [choosing] › [showNextTo]                                       │  trail band, 52
├───────────┬─┬────────────────┬─┬───────────────────────────────┬─┬────────────────────────────────┤
│ Packages  │⋮│▒ meta-tools     │⋮│▒ InspectorRowWdgt [ClippingWdgt]│⋮│▒ choosing                       │  headers, 44
│           │⋮│                │⋮│ Categories Comment Inst… Subcl…│⋮│ Methods  Fields  Inherited     │  toggles, 48
│ fizzytiles│⋮│ InspectorBody… │⋮│ accessing                      │⋮│ _removeInspectorsNoSettle      │
│ harness   │⋮│▓InspectorRowW… │⋮│ testing                        │⋮│ _showNextToNoSettle            │  rows, 42 each
│ maps      │⋮│ InspectorWdgt  │⋮│▓choosing                       │⋮│ chooseMember                   │
│▓meta-tools│⋮│ MemberEditorW… │⋮│ layout                         │⋮│▓showNextTo                     │
│           │⋮│ [+][⧉][✎][🗑]   │⋮│ [+][✎][🗑]                      │⋮│ [+][⧉][✎][🗑]                   │  icon footers, 52
├───────────┴─┴────────────────┴─┴───────────────────────────────┴─┴────────────────────────────────┤
│ ⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯  the divider (dragged)  ⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯ │  12
│ showNextTo                                                                                         │  the body's header
│ # `subject` shown right of `inspector`, mine, as one settle (showChoice says what that means).     │
│ (inspector, subject) ->                                                                            │  the body: comment,
│     @_settleLayoutsAfter => @_showNextToNoSettle inspector, subject                                │  then code
│                                                                                            [Save]  │
└────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

Measured in round 5 at that size: the lists 236 / 236 / 383 px wide and the last taking the rest (473), all four
whole; 6 / 5 / 4 / 4 rows in view; the body 10 lines of 191 characters. At 760 × 720 the first two lists are
scrolled out and the last two stand whole, the body 7 lines. On a phone held upright one list stands whole and the
body has 14 lines; held sideways this shape gives the body no room (known, and chosen: the owner ruled "always
below" after seeing it).

### 5.3 The set that scrolls (U1)

**The measure.** A column's width is a FIELD: its NATURAL width (what its cells desire: its header's, its
chooser's, its view's) until a divider sizes it, then its STATED width (`InspectorWdgt.statedWidth`, never below
the column's least width). Only the set's LAST column may take more than that. The set's width is the larger of its
columns' and dividers' widths together and its viewport's width, then widened, when it overflows, so that its END
is a column's left edge (the last column takes that slack too). Its height is its viewport's. That box is the
row's measure, the row's own layout pass lands on it, and the row declares the measure to be its whole frame:

```coffee
  # (InspectorRowWdgt, as its viewport's plane: what it declares, as built)
  scrolledContentMeasure: (viewWidth) ->        # read from fields and the viewport's size only
  scrolledContentMeasureIsMyFrame: -> true      # my measure is committed verbatim: no window floor, no grow-to-fill
  implementsDeferredLayout: -> true             # my division row's own pass places my cells: a committed frame owes it
  columnLefts: ->                               # where my columns stand, from fields: the measure, the rest points
  takesMySlack: (column) ->                     # only my last column takes the spare room
  # (InspectorRowViewportWdgt)
  _isContentSizing: -> true                     # without it the measure is never asked
```

As built, the set is the ONE writer of its frame: it declares neither `arrangesOwnScrolledChildren` (the viewport
would then call an arrange the row lacks: it throws) nor `viewportConstrainsMyWidth` nor `managesOwnScrollPinning`
(inert on this plane); it declares `implementsDeferredLayout`, without which a frame the viewport commits silently,
while the browser's own arrange sizes the viewport, leaves the columns placed for an old width. The column ANSWERS its
own width (`InspectorWdgt.getDesiredDim` from `statedWidth`; `getMaxDim` asking its set `takesMySlack`), not its
division box (the engine ignores a container cell's own least and desired). Measured over 865 window sizes and
choices: the set's box always its measure, every column where `columnLefts` says, no re-visit. The prototype's
two-writer patch (`compare/probes/patches/scroll.js`, `shape6.js`) proved the behaviour; it is no model for the code.

**Scrolling.** Sideways only (the set's height is its viewport's, so there is no travel down). The REST POINTS are
0, the columns' left edges short of the scroll's end, and the end itself (`InspectorRowViewportWdgt._restOffsets`;
the end is a column's left edge whenever the last column is no wider than the view). A notch's travel enters by ONE
branch-free seam of the base, `ViewportWdgt._wheelTravelX` (`scrolledBy` stands at the complexity ceiling), and the
scroll bar's own write, a wire's delivery onto the "scroll x" pin, rests too (`setScrollX`, the sheet's whole-cell
precedent). A sideways wheel notch moves one rest point and, at the end, passes
to the pane outside (the house's wheel rule). A drag comes to rest on the nearest rest point at the stroke's END
event, never in a later frame (`ViewportWdgt._stopScrollStep` is where every scroll step ends; the momentum glide
is already suppressed while a test plays). By touch a plain sideways drag anywhere on the columns scrolls the set
(the direction latch: a list takes a vertical stroke, the set a sideways one). The scroll bar is no finger control.

**A choice reveals its column** (`InspectorRowViewportWdgt.revealColumn inspector`, read from fields): after the
choice's settle the set scrolls the least way, to a rest point, that shows the column whole (its start, when it is
wider than the view). As built (U2), `InspectorBrowserWdgt.showChoice` reveals the inspector the choice SHOWS, which
`showNextTo` answers (the fresh or reloaded one; the chooser after a choice of no subject), once `showNextTo` has
returned: the thin-wraps convention keeps `showNextTo` the plain settle wrapper; a body below is no column, and its
reveal moves nothing. **A choice that removes columns HOLDS the scroll where it found it** (the owner's ruling L11,
which overturned U1's "scrolls back by the arrange's clamp alone": the clamp slid the chooser under a double-click's
pointer): the set keeps a held offset (`InspectorRowWdgt._heldScrollOffset`, transient) and is at least that offset
plus its viewport's width, its last column taking the rest; the next SCROLL by any path drops it (they all meet in
`ViewportWdgt._scrollX`), and the gap closes by the clamp at a rest point. A choice that changes no column (a reload,
another member shown in the body below) keeps it, so nothing slides under a person's pointer.

**The two hazards, each fixed where it lives and each with a control run** (`compare/probes/hazards.js` reproduces
both):
- a divider, or the split button joined to it, pressed inside a pane that scrolls by drag, lets the pane scroll
  under its own drag. Both KEEP the press (`pressBegan` answers false after `bringToForeground`, as
  `SliderButtonWdgt.pressBegan` does). As built the home is `LayoutChromeWdgt.pressBegan`, for a piece that owns
  its drags (`ownsDragsStartingOnMe`: a splitter, a split button), so every division stack's splitter in a
  scrolling pane is safe; a spacer and an adder own no drag and pass the press on as before (no reader of the kept
  press was found);
- on an ordinary viewport plane each inspector would be LOOSE content, and a mouse drag on a column's header would
  lift the column out of the set (`Widget._amIDirectlyInsideViewport`). The set's viewport answers
  `contentsPanelHoldsLooseContent` false, as `ListWdgt` does, so that drag moves the window as it does today.

**The column divider** (built in U1 as `InspectorColumnDividerWdgt`; generalised by axis in U2 as `InspectorDividerWdgt`,
whose seam reads `dragPlane` / `dragAnchorAt` / `sizeDraggedTo` and writes `_setStatedSizeDeferredSettle`, the same
divider sizing the strip of lists below the set; a kind of `StackElementsSizeAdjustingWdgt`: the halo's
"Resize/move…" tests a neighbour for that class, and a sibling class would get a trading adjuster inserted beside
it; its box exactly its thickness, spreadability 0). A drag sizes the column on its LEFT: that column's stated
width follows the pointer's travel since the drag began, from the width it had then, floored at its least width;
the columns right of it shift. The ONE seam is three queries on the divider (`dragPlane`, `columnDragAnchorAt`,
`columnWidthDraggedTo`) that both handlers ask, each mapping its own pointer and writing the column
(`_setColumnWidthDeferredSettle`) itself. The solve reads two things fixed at the drag's start (the pointer's place in the
VIEWPORT's plane, the column's width), never the row's place under the pointer, so a drag at the scroll's far end
cannot run away as the clamp slides the plane (RESEARCH Q3b's inferred hazard; the unit proves it by a run at the
far end). The split button moves the same split through ONE seam on the divider that both drags use (the earlier
plan's R12 says which two gates, `check-plane-discipline` C2 and `check-layering` [O], refused a relay from one
widget's handler to the other's: the seam is a query both ask, or a core both call, never a relay).
`InspectorRowWdgt._isMySplitter` asks the capability that seam gives. `StackElementsSizeAdjustingWdgt` is not
changed in what it does for any other stack.

**What is deleted in U1**, each with its comments and every reader: `_widenMyWindowToFitNoSettle`,
`_normalWidthOf`; `InspectorWdgt._defaultBox`, `mostWidthGivenAway`, `_giveUpMostWidthNoSettle`; `rowSlackWeight`
on the three views; the heir rule and `sameKind`; `ObjectListWdgt.leastWidthKept` / `desiredWidthKept` and the
`kept` a view switch hands (a switch keeps the column's own width field); the width a view's place desires (the
place stays: it still takes the column's spare height); `dressAsAViewsList`'s two width parameters; the split
button's trading drag (the splitter's own solve, now `_maxDimsPuttingMyLeadingEdgeAt`, has its own handler as its
one caller). The row stops being a `ClippingWdgt`: its viewport clips, and the browser clips the tool.

**What must still hold, and where it moves**: the body under the inspectors (as built the BROWSER paints it, once,
and the row, the inspectors' parent, answers `laysTheInspectorBodyUnderItsParts` and paints nothing); the derived dividers and split buttons (the row's
reconcile, unchanged in rule, building the divider); the window's title (the browser's
`colloquialName` is its first inspector's; the reconcile's re-title asks the browser's window).

### 5.4 The browser, and the body's place (U1 builds the browser with the body beside; U2 puts it below)

```coffee
# THE BROWSER: the inspector as a tool. "Inspect" opens me (Widget.spawnInspector), in a window or with none.
#   I hold a SEQUENCE of inspectors (InspectorWdgt): the first on the subject a person asked for, each next one
# on a subject chosen in the one before it. A CHOICE replaces whatever follows the inspector it was made in, in
# ONE settle (showNextTo): the subject the next inspector already shows is reloaded there, any other subject gets
# a new inspector, and no subject only removes what follows the chooser. Nothing else ever removes an inspector.
#   WHERE each inspector stands is mine to say, never the sequence's. My LISTS stand in my set, a row that scrolls
# sideways (InspectorRowWdgt in its viewport). My BODY -- the inspector of my sequence that shows one thing as
# text (its subject answers editsAsText: a member, a class's comment), always my last -- stands where my setting
# says: bodyPlace "below" puts it under my set, at my full width, a divider between them that a person drags;
# "beside" leaves it my set's last column. The setting is fixed as I am built.
#   Top to bottom, the cells of one vertical DIVISION stack (StackLayoutEngine), so I have no layout of my own:
# my TRAIL band; my set's viewport; and, with my body below, my divider (InspectorDividerWdgt, a kind of the
# stack's splitter whose drag STATES the strip's height, never a trade) and my body.
# The place is never empty: while my sequence ends on a list it holds a body that shows nothing.
class InspectorBrowserWdgt extends ClippingWdgt
  bodyPlace: "below"
  constructor: (subject, opts = {}) ->          # opts.bodyPlace
  inspectors: ->                                # my sequence, in order: my set's, then my body when it stands below
  @holding: (widget) ->                         # the browser a widget stands in: the nearest ancestor answering showNextTo
  @openInAWindowOn: (subject) ->                # a browser in a window by the hand: the door's and a lone chooser's one statement
  @showChoice: (chooser, subject) ->            # from the chooser up to its inspector, then up to its browser
  showNextTo: (inspector, subject) ->
  chooseMember: (name) ->                       # the door on a member (§5.12)
  revealTrailLevel: (ignored, ignored2, index) ->
  colloquialName: ->                            # my first inspector's
  @defaultExtent: ->                            # §5.13
```

- **As built in U1** (the body beside): the browser is a `ClippingWdgt` (it takes over the row's reason to clip) and
  paints the body once; its cell is the set's viewport (`viewport`), whose plane is the set (`row`, its columns
  `columns()`); U1 has no `bodyPlace` field (one value and no reader would be a knob with nothing behind it: U2 adds it
  with its second branch); the row takes no subject, and the browser places every inspector (`_placeNoSettle`); the
  window's re-title is the browser's, told by the row's reconcile (a "Pick up" of a column reaches only the row).
- **The climb.** `showChoice` climbs from the chooser to the nearest ancestor that answers `showsSubject` (the
  inspector), then to the nearest ancestor that answers `showNextTo` (the browser). The second climb is more than
  one level now (inspector, row, viewport, browser; or the body's place, browser). A chooser under no browser opens
  the subject in a browser of its own, in a window, as today.
- **`_showNextToNoSettle`** is the row's of today (§1.1) over `@inspectors()`, minus the heir rule and the
  widening: reload when the next inspector shows the subject, else destroy what follows and place a fresh inspector
  (`_placeNoSettle`: the body's place when `bodyPlace` is `"below"` and the fresh inspector shows a body, else the
  row's end); then the row's reconcile; then the trail rebuilt; then, after the settle, the reveal.
- **What "a body" is** is asked of the subject, never of a view's class: the question `editsAsText`, answered by
  `MemberRef` (which answers `editsAsAMember` today: `InspectorWdgt._views` builds an editor by it) and by
  `ClassCommentRef` (§5.11). As built (U2): ONE question, `editsAsText` (`editsAsAMember` deleted), asked through the
  inspector (`InspectorWdgt.showsOneText`); `MemberRef.sameMemberAs` guards on its own capability.
- **The split between lists and body** is the division stack's own arithmetic, read from fields. The viewport's
  cell states its height (desired = most, no margin): 312 px as built (header 44 + toggles 48 + footer 52 + 4 × 42,
  the strip the owner saw at every size; with the list pane's 4-px padding that is THREE whole member rows and most of
  a fourth, and in a column with a chooser — every widget's and every class's — about two: the owner's ruling L13); the
  body's cell takes the stack's spare. The divider's drag STATES that height (the strip's division box), the size it
  had plus the pointer's travel, floored at the strip's least and capped so the stack stays at every cell's desired
  size; a window resized after a drag keeps the person's split. **As built, NOT the splitter's own trade**: a trade
  clamps each neighbour at its desired size, so the strip could only grow, and a traded split is a share of the spare
  that moves with every resize (U2's research; the prototype the owner saw stated it too). The strip's LEAST is
  derived, the tallest least among the set's columns (190 for a member list, 236 for a column with a chooser), so the
  divider never squeezes a column's bands. Dragged in round 4: the strip 312 to 440 (9 / 9 / 8 / 7 rows, 3 lines of
  body) and to 202 (3 / 3 / 2 / 1 rows, 16 lines).
- **That split has both controls, as every split of this tool has** (the owner's rule of 2026-11-24: a split must
  work by touch, and both controls stay on screen): the 12 px divider for a mouse, and, joined to it as one flat
  piece, a TAB at the left end of the body's header band for a finger: the split button turned a quarter (a chrome
  target's side wide, `splitButtonWidth` tall, so divider and tab together are 44 px down). `SplitGripWdgt` asks
  the inspector it stands in which splitter it moves; the body's inspector answers the browser's divider. The
  prototypes drew the divider alone, so the owner has NOT seen this tab: decision D16, shown on the review page
  before U2's gauntlet, measured by a finger's drag.
- **The empty body** is an inspector on no subject showing a header that reads "(nothing chosen)" over an empty
  pane, so the lists never change height when a member is chosen. As built (U2): its subject is `undefined`, the
  house's one absence value (no new value class: nothing a person inspects is ever undefined), its one view "Nothing"
  a `BandSpaceWdgt` spring of an editor's least size; it is no step of the sequence and names no trail level.
- **With no window** the browser stands on the desktop as any widget and is resized by the halo; a column picked
  out of the set keeps today's rule (its choice opens a window of its own); the plane picked out of its viewport, or
  the body picked out of its place, must leave nothing that throws (U1 and U2 each probe their own).

### 5.5 The where-you-are band (U2)

A `BandWdgt` 52 px tall, first cell of the browser, rebuilt inside the settle of every choice from the sequence:
one plain button (`SimpleButtonWdgt`, 44 px tall, never narrower than 44) per CHOSEN subject, in order, each
pressing `revealTrailLevel` with its level as its argument (a method name and an argument: no closure); between two
buttons the product's drawn chevron (`MenuRowIndicatorWdgt` with `ChevronRightIconAppearance`, the menu row's
submenu mark, in `menuRowSubmenuChevron`), its glyph square 12 px so its ink (about 10 px) stands at the buttons'
capital height, centred on the buttons' centre line, with `toggleBandGap` of clear space from each button to the
chevron's INK (`ChevronRightIconAppearance.inkSpanX` gives the ink's span; `compare/probes/patches/round4.js`,
`rebuildPathNoSettle`, has the arithmetic, and `compare/probes/crops4.js` measured the result: 10 px tall, centred,
8 px each side). A press brings into view the column in which that subject was chosen, and that list's chosen row.

- A subject that was not chosen names no level: the browser's first subject when it is the packages root
  (§5.11). An object a person asked to inspect is the first level.
- **The level's wording** (decision D9): the subject's name; and, where the choice was made by the class button or
  in a list of objects, the relation first, in words: "class RectangleWdgt", "instance Rectangle", "subclass
  BlinkerWdgt", "child Rectangle 2" (the singular of the view's title; "class" for the class button). Round 4's
  trails read "rectangle › RectangleWdgt" and "rectangle › rectangle › rectangle".
- **As built in U2** (the owner's ruling L12 and the unit's rulings): the buttons are the house's 36-px button in the
  52-px band (the 44 rule met by the band), at the footer band's metrics (inset 12, gap 8); the chevron in a role of
  its own, `inspectorTrailChevron` (the menu row's role names the menu row's surface), at `inspectorTrailChevronSize`
  12, its ink ([4, 9] of its square) `footerGap` clear of each button; the wording in SENTENCE case where the words are
  ours — "Class RectangleWdgt", "Instance Rectangle", "Subclass BlinkerWdgt", "Child Rectangle 2", a widget's level its
  row name ("Rectangle") — and data never re-cased (a member's name, a class's name); the words DERIVED when the band
  is built, from how the chooser's column made the choice (`InspectorWdgt.nameOfMyChoice`), nothing stored; the band
  rebuilt only when its faces would change; a press reveals level k's column (the one it was chosen in, k − 1; level
  0 its own) and that column's chosen row. A trail longer than its browser squeezes its buttons (filed).
- A level's button offers "Open in a new inspector" as every such thing does (§5.8).
- The window's title stays the first inspector's ("Inspector — Packages", "Inspector — rectangle").

### 5.6 The header and the class button (U2)

`InspectorWdgt._buildHeaderNoSettle` builds `classChip` (the field keeps its meaning; the unit renames it
`classButton` everywhere it is read, tests and rigs included) as a plain `SimpleButtonWdgt` with the class's name
as its face and `chooseMyClass` as its action: the house's "a bordered rounded rectangle means press me", the look
of "Add…". `ChipWdgt`, and every theme role only it reads, is deleted in the same unit (grep both repos first: a
role another widget reads stays).

### 5.7 Every list its own footer of drawn icon buttons (U3)

**One mechanism.** `ListVerbsBandWdgt` is a `BandWdgt` standing last in a list view: `footerInset`, then one
44 × 44 `SimpleButtonWdgt` per verb with a drawn icon as its face and `footerGap` between them, a spring,
`footerInset`; its rule along its top. The verbs are always in ONE order: add, duplicate, rename, remove. Each
button carries a tooltip naming its verb ("Add…", "Duplicate…", "Rename…", "Remove"), since an icon alone does not.

**Absent, disabled, enabled.** The list's KIND says which verbs it can ever offer: one that can never apply is not
built (no gap left for it), and a kind that offers none builds no band. A verb that cannot apply NOW is disabled
(the button's own disabled look: no fill, the disabled stroke). Both are asked of the list view by method name, as
a list asks its row facts today (`memberFactsQuery`): the view answers `verbsOffered()` (a subset of the four
names, in order) and `verbApplies(verb)` (asked after every choice, every re-filter and every edit:
`MemberListWdgt._reflectMemberSelection` is the existing seat). The view performs a verb through the reference of
what is chosen, as a member list does through `MemberRef` today.

| List | add | duplicate | rename | remove |
|---|---|---|---|---|
| methods and fields (a class, or an object that takes the instance edit protocol) | always | a member the subject itself holds, not `constructor` | as duplicate | as duplicate |
| methods and fields of a value no edit reaches (a Point, a Color) | — | — | — | — |
| children of a widget | — | a child chosen | — | a child chosen, not a window's content |
| instances of a class | — | an instance chosen | — | an instance chosen, not a window's content |
| packages | — | — | — | — |
| classes of a package; subclasses of a class | §0.4 D2 | §0.4 D2 | §0.4 D2 | §0.4 D2 |
| method categories | always | — | a category chosen, not "all" | an EMPTY category chosen, not "all" |

"—" is absent. The first row is the product's rule today, unchanged. Children and instances follow the widget
menu's own verbs: duplicate is `duplicateMenuAction` (a copy in place), remove is `close`; the list is read again
afterwards. The last two rows land with their levels (U7, U8).

**The four icons are PLACEHOLDERS** (owner: "DRAWN ICON buttons (placeholders)"): simple size-aware marks drawn
with standard drawing commands. A plus and a bin exist (`PlusIconAppearance`, `BinIconAppearance`); the unit draws
a "two overlapping sheets" mark and a "pencil" mark (`compare/probes/patches/round5.js`, `R5DupMark` and
`R5PencilMark`, are the prototype's). Final icons are the owner's, the umbrella's `/convert-icon-size-aware` way,
filed (D11).

The member list's four text buttons, their `…Button` fields and `_buildAndConnectEditRow` go; the prompts they
open and their refusals (`addPropertyPopout` and its twins) stay as they are.

- **As built in U3** (the loop's rulings, `u3/PREP.md` §2, on the research's findings, `u3/research/R3-A-…`, `R3-B-…`):
  - **Only the MEMBER lists have a band.** The table's children and instances rows are PARKED as U3.2 and asked of the
    owner (decision D10): their premise does not hold. The widget menu's Duplicate (`duplicateMenuAction`) stands the
    copy on the DESKTOP (`world.add`, 10 px right and down), so a Children list shows nothing new; its remove is
    `close`, into the bin, so an Instances list keeps listing what it removed; the menu offers both in developer mode
    only, the inspector in every mode; and an Instances list reaches the world, the hand, the bin and shelf, menus and
    the inspector's own parts, which neither verb refuses. What the two verbs mean there is a product decision; until it
    is ruled, a Children, Instances or Subclasses list offers no verb and builds no band (the table's own rule for a list
    that offers none).
  - **The buttons are 44 × 36, not 44 × 44**: the house's rule for every button. `SimpleButtonWdgt.preferredExtent` holds
    every text button to `max(minimumTargetSize, …)` wide and the house's one button height (`buttonHeight`, 36) tall, and a
    mark-faced one is (`max(minimumTargetSize, buttonHeight)`, `buttonHeight`): the button meets the 44 rule across by
    itself, and the 52 band it stands in meets it down — L12's reasoning, the trail's. PREP (§2) had said 36 × 36, a
    `buttonHeight` square that skipped the width every text button keeps; the orchestrator found it while checking a
    review-page claim, and the house's rule, applied as it stands, settled it with no product question. The table above
    predates both. A `SimpleButtonWdgt` whose face is a drawn MARK (`MenuRowIndicatorWdgt`, `glyphSize` the new metric
    `inspectorVerbMarkSize`, 16) sizes itself so, centres the mark's square in it (14 px in from its sides, 10 from its
    top and bottom) and inks it as a text face is (`SimpleButtonWdgt._faceIsAMark`): no icon-faced button existed.
  - **The words are each button's TOOLTIP**: the words its text button bore ("Add…", "Duplicate…", "Rename…",
    "Remove"), which the menu sweep's "…" and sentence-case rules judge. They belong to the VIEW: `verbsOffered()` is a
    TABLE keyed by verb, each entry its action's method name and its words (a verb's words depend on what its press
    does), never a list literal of names; the ONE order and each verb's mark are the band's (`ListVerbsBandWdgt._verbsInOrder`),
    and the band answers both of a reader's questions itself, its verbs in that order (`verbs()`) and a verb's button
    (`buttonFor(verb)`), so no reader outside it (the toolkit, the menu sweep) reads its pieces.
  - **The seats, and ONE seat for what a member step changes.** `_reflectMemberSelection` is gone: its four callers (the
    build, a re-filter, a row's choice, a reload) ask the band (`ListVerbsBandWdgt.reflectVerbs`), which asks the view's
    `verbApplies(verb)` for each button. "Every edit" needs what the subject OWNS seen as it moves, and that has ONE
    seat: the tail every member step ends in (`MemberRef._notifyOfEdit`, which `ClassMemberRef` inherits, overriding only
    `_tellWhatTheEditReaches`: the holder's `sourceChanged` for an object, `world.noteCodeChanged` for a class) tells
    `MemberListWdgt.noteMembersMayHaveChanged` the step's holder, and every member list on it reflects its verbs again.
    So an add, duplicate, rename or remove through ANY list on that holder (a second browser on the same widget) and a
    SAVE in the body (a Save is a step, and ends in the same tail) show in every list at once: an inherited member saved into
    an own one has duplicate, rename and remove at once. What no step makes is not seen there — a run in an editor
    (`Widget._runningAPersonsCode`, which tells the holder's `sourceChanged` itself) and a product write (a menu's
    `setColor`) — and the next choice asks again. CP1 had the Save call it directly (`MemberEditorWdgt.save`), which
    saw a Save and missed another list's step (Review A, A1); the call moved to the tail, and the Save's own went.
  - **The marks are placeholders** (D11): the plus reused (`PlusIconAppearance`), and three new size-aware marks drawn as
    fills on the control glyph's line, named by their picture — two overlapping sheets (`TwoSheetsIconAppearance`), a text
    cursor in a field (`TextCursorIconAppearance`: never a pencil, which means "edit" in this house, the mark that opens
    the inspector on a member), a bin in outline (`BinOutlineIconAppearance`: the desktop's `BinIconAppearance` misfits a
    button face, its paper interiors showing on the hover and pressed fills, its lines a hairline beside a control glyph).
  - **The member list's natural width falls** to its widest remaining cell: 365 on a widget (its band of filter toggles;
    least 364), a class prototype's own list 246 in a column of 286 (its chooser band; least 285); the band of verbs
    desires 12 + 4 × 44 + 3 × 8 + 1 + 12 = 225 (its spring's 1; least 224), never the widest. The width was the four text buttons' (372) before,
    so every number derived from it moved, and five tests lost the overflow their premise needed, each now stating a
    narrower window: ColumnsScroll, BehavesTheSame, BodyStands' second part and BodyBeside at 900, ChildrenView at 700.
    Four GESTURES changed length too, each for a reason the narrower columns gave (Review B, A3 and A7): ColumnsScroll's
    sideways wheel 300 → 200 (a finger's swipe stays inside the list it starts on, and a class column's list shows
    262 px, so 300 arrived as two 150 px swipes, each resting back on 377, and a later wheel aimed at a column still
    scrolled out: AIM MISSED under the finger; 200 is one swipe, reach 258, with the same rest points), and BodyStands'
    wheel over a class column the same 300 → 200 for the same reason (at 300 its expected value held, but for another
    reason than its comment gave); SidewaysDrag's mouse drag 300 → 200 (at the offset 377 the second column stands
    0..286 in the view and the press about 243 in, so 300 ends past the view's edge, off the set; 200 ends inside and
    still carries the set past the midpoint, 577, nearer 675); DividerSizes' drag 200 → 300 (200 would leave the set
    644 + 12 + 286 = 942 inside the 998 viewport, so the no-squeeze line would see no overflow; 300 makes it 1042).

### 5.8 "Open in a new inspector" (U4)

**What.** On every thing whose press would add a column: a row of an object list (the object), a row of a member
list (the value, when it holds an object worth a list; else the member, opened as the door on a member opens it),
the class button (the class), a trail level (its subject). The thing opens in a NEW browser in a window of its own;
the original stays exactly as it was (round 5 compared its trail, columns, chosen rows and body before and after,
in every run: identical).

**Two asks, both always there.**
- **A menu row**, by right-click or a hold. In user mode a one-row menu titled with the thing's name, the
  precedent being `Widget.buildContextMenu`'s branch for `_memberToEdit` and its "Edit code" row; in developer mode
  one more row, first, of the menu that is already there. The widget under the pointer is a generic list row, a
  button: it cannot know what an inspector is. The thing is named by a capability the menu's climb reaches, a
  method that answers the door's own two operands or nothing (`{subject, member}`, exactly what `_memberToEdit`
  answers), asked of the list view through its list by a method NAME (`ListWdgt`'s `memberFactsQuery` is the
  precedent for a list asking its target about a row). The unit's research reads
  `ActivePointerWdgt.openContextMenuAtPointer` and the two menu builders and chooses the seat.
- **Cmd-click**, the mouse's shortcut: `metaKey` reaches `activated` already (§1.2), and no click reads it today.
  A Cmd-click on such a thing opens it separately INSTEAD of choosing it. The macro toolkit gains the verb a test
  needs to click with a modifier, if it has none.

**Where it lands, what it is called** (decision D12): beside the original where the desktop has room for a window
of the default extent (its right, then its left, then below it, 16 px apart), else cascaded 48 px right and down
from it; always inside the desktop (`WorldWdgt.openFrameWith` already keeps a window within the world). Its title
names the thing alone, as any inspector's does.

No pop-out button stands in a column's header (owner, 2026-11-26).

### 5.9 The meta-object keeps comments and categories (U5)

**What a class's record gains**, beside its two stores of sources (every store keyed by member names made with
`Object.create null`, reframe 8):

| Kept | From | Asked as |
|---|---|---|
| the class's comment | the lines before the `class` line, as written, blank lines trimmed at its ends | `classComment` |
| a member's comment | its stash (§1.3) with the marker lines taken out, each line less the two spaces of the member column, blank lines trimmed at its ends; several groups stay several groups | `commentOf name` |
| a member's category | the last marker above it in the class's text; none before the first marker | `categoryOf name` |
| the class's categories | the marker names in the order first met, each once, and any a person added that holds no method yet | `categories()` |

- **One pass, the one the parse already makes.** `getSourceOfAllProperties` walks every stash line today and drops
  it. It keeps what the table says, for static members as for instance members (the loop is one), and returns its
  two source stores at the positions they have today, anything new AFTER them (the serialization rig reads the
  result by position, §4.2). A member's SOURCE string is unchanged, byte for byte: `lib/call-sites.js` maps it back
  onto the file line by line.
- **A marker gives its category to every member after it; which of them are METHODS is asked where it is used.**
  The browser lists a category's methods by the member list's own rule (a member whose value is a function); a
  field under a marker shows under "all" only. The parse tokenises nothing to decide it (6833 lexer runs at every
  boot would be a cost with no reader); the build gate, which has the time, uses the lexer (§5.10).
- **The limits, stated.** The comment a class writes INSIDE its body before its first member (229 classes) is its
  first member's comment, as the parse reads it; text after a class's last member is dropped as today (four classes);
  the order of statics among instance members is not kept. None is needed here; the vault holds the whole text.
- **An edit keeps them.** `applyMemberEdit: (memberName, source, opts = {})`: `opts.comment` and `opts.category`,
  each KEPT as the member has it when its key is absent, set (or cleared, by `undefined`) when present.
  `removeMember` drops both with the source. The class's own: `setClassComment text`, `addCategory name`,
  `renameCategory oldName, newName` (every member in it follows), `removeCategory name` (refused while a method is
  in it). Each compiles nothing and tells no one, as `removeMember` does: telling is the caller's.
- **Boot, and away from boot.** `bootMemberSources` becomes the class's whole boot record (sources, comments,
  categories, the class's comment, its category list), re-read from the vault's text by the same parse.
  `Class.membersAwayFrom` lists a member whose source, comment or category differs;
  `SourceEditsRegistry.returnThePageToBootSources` returns all three, and the class's comment and category list;
  the load's confirm counts them.
- **A snapshot's records** (`SourceEditsRegistry`; a record with fields it does not know is already accepted):
  a member's edit record carries `comment` and `category` when the edit set them
  (`{scope: "class", className, propertyName, source, comment, category}`), and `replayClassEdits` hands them on;
  two record kinds more, each validated by `isARecord` and replayed in the log's order:
  `{scope: "class", className, classComment: text}` and `{scope: "class", className, categories: [names]}`.
- **What the editor shows and saves.** Wherever the text an editor shows is a class member's recorded source (a
  class's own member, or a member an object inherits), the member's comment stands above it, as the file has it:
  `shownText` answers the comment, a line break, the source. `ClassMemberRef.save` splits the typed text at the end
  of its leading block of blank and `#` lines: that block is the comment, the rest the source
  (`Class.splitLeadingComment`, the one place that rule lives, pure), and hands both to `applyMemberEdit`. So a
  comment typed above a method is the method's comment from then on, and joining the two gives back exactly the
  text typed, which is what lets the editor keep its caret and undo history across a Save. An OBJECT's Save hands
  the text on as typed, as it does today (measured: accepted, kept, replayed). `ClassMemberRef`'s duplicate and
  rename carry the comment and the category with the source (`_editCopyUnder`).
- **Cost, measured**: about 14 ms more parse and 4.4 MB more heap on a page that builds every meta-object at boot
  (§4.2). On a production tree nothing is paid until the reflective layer loads.
- **Out of scope, said**: a class's STATICS stay where they are (shown read-only on the class function, never
  recorded); their comments and categories are kept by the same pass and shown by nothing yet. No file is written
  out (decision D4).

### 5.10 The marker, the vocabulary and the gate (U5)

**The marker's form** (spike S2 planted six candidates in copies of the tree and ran the real parse, the real
compile, the boot's dependency scan and thirty gates over each):

```coffee
  #: accessing

  # my inspectors, left to right
  inspectors: ->
```

A line that is exactly two spaces, `#:`, one space and the category's name, `/^  #: ([a-z][a-z ]*[a-z])$/`, a blank
line above it and below it. No line of the tree begins `#:` at any indent today, so nothing existing reads as a
category and no banner must be decided first (the dashed, ruled and slashed banner forms would each claim 10 to 89
existing lines); dropping the `#` by mistake is a compile error the syntax gate already reports (where
`# category: x` would silently make a field); compiled output, dependency edges and every gate were identical with
410 markers planted. **It excludes nothing and changes no shipped byte of code**: it is no successor of the two
retired exclusion markers (`check-region-markers.js`, `check-whole-file-markers.js`), whose lesson was that
invisible text-level EXCLUSION is the wrong tool. A category's name is lower-case words; the word `extends` is
refused in one (the boot scanner reads it anywhere on a line).

**The vocabulary is recommended, not closed**: a class may name a category of its own where none fits (the
inspector's "choosing", "filtering", "member editing", which the owner saw and liked). The standard names, each
with what belongs there, live in a new `docs/architecture/method-categories.md` (with the marker's form and the
gate), drawn from what recurs across the tree (§4.3):

> initialization · accessing · testing · geometry · layout · drawing · event handling · drag and drop ·
> notifications · structure · lifecycle · menus · pins and dataflow · copying and serialization · printing ·
> private — and, on value classes, comparing · converting · arithmetic

"private" is for a helper with no topical home, not for every underscored name: the underscore already says
private, and a `_setXNoSettle` core sits with the `setX` it serves.

**The gate**: `buildSystem/check-method-categories.js`, a row of `buildSystem/gates.js`, with its rule registry
(`lib/gate-rules.js`), its advice rows (`lib/gate-advice.js`), its bite-proof (`check-method-categories-selftest.js`
through `lib/planted-src.js` `proveGate`, every rule planted and seen failing by its own line) and its line in
`lint-and-static-checks.md` §3 and §3b. `check-complexity-ratchets.js` is the model for its shape,
`check-stinks.js`'s inline baseline with a dated comment for its one number. It reads members by the REAL
meta-compiler's boundaries (as `check-coffee-syntax.js` loads it), never by `lib/coffee-method-header.js`'s spans,
which do not end at a member-column comment. Its rules:

| Rule | Class | Fails on |
|---|---|---|
| `MARKER_MISINDENTED` | B, zero | a line shaped like a marker that is not at exactly two spaces (it silently becomes method text) |
| `STASH_HOLDS_CODE` | B, zero | a line of code between two members (a marker written inside a body truncates the method; today five dead lines of `src/fizzytiles/LCLProgramRunner.coffee`, which U5 deletes after proving the compiled output identical without them) |
| `CATEGORY_NAME_MALFORMED` | B, zero | a `#:` line whose name is not lower-case words, or holds the word `extends` |
| `EMPTY_CATEGORY` | B, zero | a marker with no method under it before the next marker or the class's end |
| `MARKED_CLASS_UNMARKED_METHOD` | B, zero | in a class that has a marker, an instance method above the first one |
| `UNMARKED_METHODS_ABOVE_BUDGET` | C, falls | the tree's instance methods with no category are more than the number recorded (4485 on 2026-11-26, before U6) |

A method is decided by the lexer (the member's first token is `->`, or a parameter list and then `->`), which is
right on all 4764 of the tree where a regex on the first line is wrong on five. Fields and statics are not counted.

**The comment rubric** (the umbrella's `.claude/comment-rubric.md`) gains `#:` in its list of machine-read markers
that no audit edits, counts or reflows, and one hard rule: an audit never moves a member across a marker.

### 5.11 The new subjects and their views (U7)

Each is a small VALUE of `meta-tools`, as `MemberRef` is: an inspector holds it, a copy and a save carry it, and it
answers by what it is, never by a type test. All answer `colloquialName` (how a header, a row and a trail level
name it) and `sameSubjectAs other` (two values made at two presses for one thing are one subject: what
`MemberRef.sameMemberAs` is today, renamed, so `InspectorWdgt.showsSubject` and an object list's "is it still
there" ask one question of every value).

| Subject | Fields | Its views (`InspectorWdgt._views` asks what it answers) |
|---|---|---|
| `PackagesRef` | none | "Packages": an object list of every part this artifact ships (`_packagesOfMySubject`), by name. Its header reads "Packages". It names no trail level |
| `PackageRef` | `name` | "Classes": an object list of the class prototypes whose source the vault tags with that part (`SourceVault.namesForPart`), by name (`_classesOfMySubject`) |
| a class's prototype (as today) | — | **"Categories"** first (an object list of `CategoryRef`s, `_categoriesOfMySubject`: "all", then `categories()` in order), **"Comment"**, then "Instances" where instances register, "Subclasses". Its "Members" view of today is what "all" opens |
| `CategoryRef` | `holder` (the class's prototype), `name` (none for "all") | a `MemberListWdgt` on `holder` showing that category's methods: `new MemberListWdgt holder, category: name` |
| `ClassCommentRef` | `holder` | answers `editsAsText`: a member editor on the class's comment (`shownText`, `save` through `setClassComment` and its record) |

- **The class's column**, the widest list (383 px in every prototype: its four toggles decide it). Pressing
  "Comment" shows the class's comment in the BODY (a choice of the `ClassCommentRef`, so the lists right of the
  class go, as after any choice in the class's column) and leaves the toggle of the list still shown lit; the
  unit's research settles how the chooser tells "a view of this column" from "a subject shown in the body" without
  a second mechanism (the prototype special-cased the title "Comment": `compare/probes/patches/round4.js`).
- **"all" is the first row and is not chosen as the list opens** (owner). A class with NO category lists "all"
  alone, and that one row is chosen as the list opens: a list of one needs no choice (decision D13).
- **A category's member list** lists the methods whose category, as their own class gives it, is that name; with
  Inherited on, the superclasses' methods of the same name's category too. Fields belong to no category: in a
  category's list the Fields toggle is ABSENT, under "all" the list is today's (decision D8).
  Add… in a category's list adds the member IN that category.
- **A package not loaded yet** (a lazy part on `index.html`, on a production tree) shows in the list; choosing it
  loads it first (`world.parts.whenAllLoaded [name]`, inline when it is loaded, as every door into a lazy part
  does) and the choice is made when it has arrived. `PartsRegistry` gains the one public answer the list needs (the
  parts this artifact ships, by name); the class-to-part answer is the vault's tag.
- **A member's comment above its code** (§5.9) shows in every editor from this unit on.

### 5.12 The doors (U7)

- **"Inspect"** (every existing row, `Widget.spawnInspector`) opens the browser on the thing, as today.
- **"Code browser"**, a new row of the "Dev tools" menu (`MenusHelper.popUpDevToolsMenu`, beside "Inspect" and
  "Console", so it is on every widget's Dev menu and the desktop's) opens the browser on the packages. It is a
  third site where core reaches `meta-tools`, under the same two awaits and the same guard law as the other two
  (the part, then the reflective layer; the class named inside the `whenAllLoaded` callback:
  `buildSystem/check-part-edges.js` reads line by line). No desktop icon (decision D6).
- **The door on a member** (`spawnInspector subject, member: name`, the paint tools' "Edit code", a trail level
  that names a member opened separately): `InspectorBrowserWdgt.chooseMember name`. Where the first inspector's
  view lists members, as today. Where it lists a class's CATEGORIES, the member's own category is chosen first
  ("all" when it has none), then the member in the list that opens.

### 5.13 The default window (U2, decision D5)

`InspectorBrowserWdgt.defaultExtent()` states it once: **1000 × 808** — under the 312-px strip the body shows twelve
lines of code (the round-4 prototype's 808 was the least height for five rows a list at a taller strip; with the strip
the owner ruled, ten lines need only 765) — **clamped to the desktop's extent** when the desktop is smaller. The window
opens where it does today (at the hand, less 50 and 100 px) and `WorldWdgt.openFrameWith` keeps it within the
world. On a 1366 × 768 screen the window is 768 tall: ten lines.

### 5.14 The verbs of categories and of classes (U8, U9)

- **Categories** (U8), through `CategoryRef` and the class's record (§5.9), each recorded and told once
  (`WorldWdgt.noteCodeChanged`): **add** (a prompt for a name: lower-case words, not one the class has; the
  category stands empty until a method is added in it), **rename** (the prompt; every method follows), **remove**
  (only an empty one). **A method moves to another category** by a row of the member row's menu, "Move to
  category", opening a menu of the class's categories (decision D14): the same right-click or hold that offers
  "Open in a new inspector", finger-sized rows, no drag needed.
- **Classes** (U9, decision D2), through one new step in `meta-tools` and one new record:
  - **add** in a package's class list (a class with no superclass named, in that package) and in a class's
    Subclasses list (a subclass of it, in its package): a prompt for a name, refused unless it is a capitalised
    identifier, no reserved word, and nothing `window` already answers; the class made from a one-line text by the
    boot's own path; its text stored in the vault under the package; **one record**, `{scope: "class", className,
    defines: {source, part}}`, written before any edit of its members, validated by `isARecord`, counted by the
    load's pre-teardown checks as a class that can still arrive, and replayed at the load's FIRST step
    (`Deserializer.loadWhatItNeeds`), before the teardown (§4.4);
  - **remove**, enabled only for a class made at run time that has no instance, no subclass, and that no other
    class's source names; it closes every inspector on the class first (§4.4's worst outcome), then forgets the
    global, the vault's entry and its records;
  - **duplicate and rename are ABSENT**: neither can be honoured yet (§4.4), and each is filed with what it needs.
  - A class the build ships offers add only (remove is disabled there, with its reason as the button's tooltip).

---

## 6. Work units

Each unit lands on its own: green on its own gauntlet, its pictures looked at and re-taken, its docs true, one commit
per repo. Each is cut so that ONE Opus agent can implement one of its checkpoints from a written brief. What a unit
makes redundant is deleted in that unit. A unit's tests are named here; its research names every existing test,
rig and doc it touches before any edit (§7 is the starting list).

| Unit | What lands | Needs | Days | Done |
|---|---|---|---|---|
| U0 | Orient: read, verify, ask the open decisions | — | 0.5 | |
| U1 | The set scrolls, and the tool is a browser (the body still beside); the widening and the trading deleted | — | 2–3 | ✓ 2026-11-26 |
| U2 | The body below, the where-you-are band, the default window, the class button | U1 | 2–3 | ✓ 2026-11-27 |
| U3 | Every list its own footer of drawn icon buttons, each verb absent, disabled or enabled by one rule | U2 | 1–1.5 | ✓ 2026-11-27 (U3.2 parked) |
| U4 | "Open in a new inspector": the menu row and Cmd-click | U2 | 1–1.5 | |
| U5 | The meta-object keeps comments and method categories; edits and snapshots keep them; the marker gate | — | 2 | |
| U6 | The first classes get their categories (comment-only edits, D1) | U5 | 1–2 | |
| U7 | The code browser: packages, classes, categories, a class's comment, comments above code, its door | U2, U3, U5, U6 | 2–3 | |
| U8 | The verbs of categories; a method moved to a category | U7 | 1.5 | |
| U9 | The verbs of classes: add, and remove of a class made at run time (D2) | U7 | 2–3 | |
| U10 | Finding by name: candidates on a review page, parked for the owner (D7) | U7 | 0.5 | |
| U11 | Close: docs, BACKLOG, the churn set, the review page | all CLOSED or PARKED | 0.5 | |

U5 and U6 touch no file the shell units touch (`src/meta/`, `src/serialization/`, `buildSystem/`, comment lines),
so their RESEARCH may run beside U1 to U4's; their edits take their turn like any unit's.

### U0. Orient (0.5 day)

§0.5 steps 1 to 4. Verify §1 against the tree (the plan was read at `6c1f379e` / `701606ae9`). Re-run nothing of §4
unless a fact of §1 has moved.

### U1. The set scrolls, and the tool is a browser (2–3 days)

**Goal.** §5.3 and §5.4 with `bodyPlace` at `"beside"` as the built default for this unit only: the tool looks as it
does today in its default window on a widget with a member chosen (a list at its natural width, the editor taking
the rest), and differs exactly where it should: a drill that does not fit SCROLLS the set to its new column and
the window keeps its size; a divider sizes the column on its left; in a document, a panel or a dock the tool
behaves as it does on the desktop.

**Checkpoints** (each one agent brief; `fg build` between; the suite is red between U1.1 and U1.5 by design).
1. **U1.1 The browser owns the sequence.** `InspectorBrowserWdgt` built around today's row with no viewport yet:
   the rule of choice moves to it (`showChoice`, `showNextTo`, `_showNextToNoSettle`, `chooseMember`,
   `colloquialName`, `defaultExtent`, the window's re-title), the two climbs of §5.4. `Widget.spawnInspector` and
   `InspectorBrowserWdgt.showChoice`'s "window of its own" open the browser. Every `InspectorRowWdgt.showChoice`
   caller (`InspectorWdgt.showViewNamed` and `chooseMyClass`, `MemberListWdgt`, `ObjectListWdgt`) asks the browser.
2. **U1.2 The row is a plane.** `InspectorRowViewportWdgt`; the five declarations and `_wantedExtent`; the column's
   width field; the row no longer a `ClippingWdgt`; the body under the inspectors still painted once. Probe first
   (the agent writes it, you run it): a window dragged by its corner through 400 widths and heights, zero
   `RECALC_NONCONVERGENCE`, zero re-visits, the row's box equal to its measure at every step.
3. **U1.3 The deletions**: everything §5.3 lists, with its comments and readers, in both repos.
4. **U1.4 The column divider and the two hazards**: `InspectorColumnDividerWdgt`, the ONE seam the split button
   shares, the kept press, the plane that holds no loose content. Probes: a drag of the divider and of the tab, in
   the middle and with the set at its far end, mouse and finger, the left column's width moving by exactly the
   travel and the set's offset not at all; a mouse drag on a header moving the window.
5. **U1.5 Scrolling, rest points, the reveal**: the wheel's one column a notch and its pass outward at the end, the
   stroke's rest at its end event, `revealColumn` after a choice, the clamp after a removal.
6. **U1.6 The toolkit and the tests.** `src/macros/MacroToolkit.coffee`'s inspector block: `memberEditorFedBy` and
   `topMemberList` ask the browser's sequence (`browser.inspectors()`), never a parent chain; a verb that brings a
   column into view the way a person does (a sideways notch, a swipe) where a test must press something scrolled
   out. Every `new InspectorRowWdgt` in a test or rig becomes `new InspectorBrowserWdgt`; every
   `row.inspectors()` asks the browser.
7. **U1.7 The rigs** of §7.3, one by one, what each judges unchanged.

**Tests.** New, each with one plant per rule, both pointers:
- `macroInspectorColumnsScrollAndStopOnAColumn`: a drill past the window's width leaves the window's extent as it
  was and the new column whole in view; a sideways notch moves exactly one column; at the end it passes to the pane
  outside; a removal scrolls back. It REPLACES `macroInspectorDrillWidensItsWindow`, which is deleted.
- `macroInspectorDividerSizesOneColumn`: the divider and its tab, in the middle and at the far end, mouse and
  finger: the left column by exactly the travel, floored at its least width, the set not scrolling under the drag.
  `macroInspectorSplitMovesByDividerAndByButton` is ported into it or beside it (its research decides which of its
  assertions still state a truth).
- `macroInspectorSidewaysDragScrollsTheSet` (named in this plan first `…SetScrollsByDragOnlyByFinger`; renamed in U1,
  since a mouse's sideways drag on a list row scrolls the set too): a finger's sideways drag on a list row scrolls the
  set and chooses nothing, its vertical drag scrolls the list, its tap chooses; a mouse's drag on a column's header
  moves the window and lifts no column.
- `macroInspectorBehavesTheSameInEveryHolder`: the same drill in a window on the desktop, in a document and with no
  window: no window resized, no column narrowed below its natural width.

**Predicted failing set** (written into `u1/PREP.md` before the suite, test by test): the tests about the widening,
the trading and the divider (RESEARCH Q6 counted 11), the tests with a picture of more than two columns or of a
widened window (3), the ports of U1.6. **Every other inspector picture is predicted UNCHANGED**: the default window
looks as it does today. A changed picture outside the named set is a finding about the measure, never churn.

**Stop conditions.** `RECALC_NONCONVERGENCE`, a re-visit (`fg revisits`), or a wobble in U1.2's probe that two fix
shapes do not remove: PARK, the patches kept (§8 R1). A second reader of a splitter's press that the kept press
would starve: PARK U1.4's general home and keep the press in the column divider and its tab only.

**Docs.** `viewports-and-planes.md` (the family gains a member; the contract's fifth declaration gains a second
user), `layout.md` where it describes the row, `src/macros/CLAUDE.md` and `MACRO-PATTERNS.md` (the locators),
`build-and-packaging.md` §2 and `parts.json`'s note for `meta-tools` (the door's class), the three CLAUDE.md files
where they name the row as the tool.

**Landed 2026-11-26** (inspector-browser loop; one commit per repo, this unit's). **Built**: `InspectorBrowserWdgt` (a
`ClippingWdgt`, the tool: the sequence, the rule of choice, the two climbs, `@openInAWindowOn`, the body painted once,
the re-title); `InspectorRowViewportWdgt` (the set's role-named viewport: content-sizing, no loose content, no drops,
no glide, hidden from the hierarchy menu, no look of its own; rest points, the wheel's one-rest-point notch through the
base's one seam `ViewportWdgt._wheelTravelX`, the rest at a SCROLLING stroke's end, the scroll bar's write resting,
`revealColumn`); `InspectorRowWdgt` as the set (no subject, `columns()`, the measure, `implementsDeferredLayout`,
`columnLefts`, `takesMySlack`, `_placedByMyHolder` so a column's "Resize/move…" goes past it to the window);
`InspectorColumnDividerWdgt` (a kind of the splitter; the seam `dragPlane` / `columnDragAnchorAt` /
`columnWidthDraggedTo` both handlers ask); the column's `statedWidth`; the kept press in
`LayoutChromeWdgt.pressBegan`; the toolkit's column verbs (`bringColumnIntoView_InputEvents_Macro`,
`wheelSetTowardColumn_InputEvents`, `assertColumnInView`). **Deleted**: everything §5.3 lists, the split button's
trading drag, `dressAsAViewsList`'s widths; `macroInspectorDrillWidensItsWindow` (successor
`macroInspectorColumnsScrollAndStopOnAColumn`); `macroInspectorSplitMovesByDividerAndByButton` (rewritten as
`macroInspectorDividerSizesOneColumn`). **Ruled in the loop** (PREP §2): the field `statedWidth`; R1, a column's natural
width is its cells' (a gutted or switched column falls to its bands' width); no `bodyPlace` field yet; the row's
`columns()` and the browser's `inspectors()` two names; the browser paints the body once; the divider a kind of the
splitter (the halo's type test); the reveal asked by `showChoice` (thin wraps); the test renamed
`macroInspectorSidewaysDragScrollsTheSet` (a mouse's sideways drag on a row scrolls the set too). **Evidence**: a plane
probe (865 window sizes and choices: the set's box always its measure, every column where `columnLefts` says, 0
re-visits, 0 errors); a divider probe and a scroll probe by real mouse and finger; a fixes probe with a control per fix;
four new tests passing at their first run with every expected value derived from the code, 40 plants each seen failing
its own line under its own pointer on the final build, followers clean; every rig green; the dpr-1 and finger suites
failing exactly the predicted pictures; two independent reviews, every (A) finding fixed or ruled. **Ratchets moved**:
`check-complexity-ratchets.js` re-keys `StackElementsSizeAdjustingWdgt#_maxDimsPuttingMyLeadingEdgeAt` (score 18
unchanged: the query lost its one outside caller and became private); `Fizzygum-tests/CLAUDE.md`'s byte ceiling 66361
→ 66368 (the menu sweep's roots renamed to what is true). **Filed**: three BACKLOG items (the set resting off a column
edge after its edges move; a trackpad swipe a column per event; a double-click on a member in the set's rightmost
column, for U2 to close).

### U2. The body below, the where-you-are band, the default window, the class button (2–3 days)

**Goal.** §5.4's `"below"` as the browser's default, §5.5, §5.6, and decision D5's default window. After this unit
the object flows look as round 4 pictured them.

**Checkpoints.**
1. **U2.1 The body's place**: the browser's vertical stack with its divider and the place; `_placeNoSettle`; the
   empty body; `inspectors()` across both places; the reload of a member chosen again proved to keep its undo step
   (the body is no longer the row's next inspector); the finger's tab on the divider (D16: the body's inspector
   asks the browser which splitter stands before it, and the split button's look and drag turn a quarter). Probes:
   the divider dragged from 312 px to its two ends by mouse, and by a finger on its tab, the rows and lines counted
   against §5.4's numbers; a window resized through 400 heights with no wobble.
2. **U2.2 The trail** (§5.5), rebuilt inside each choice's settle; its level wording (D9).
3. **U2.3 The class button** and the deletion of `ChipWdgt` with its theme roles.
4. **U2.4 The default window** (D5) and where it opens.
5. **U2.5 The toolkit, the tests, the rigs** again where the body's place moves what they read.

**Tests.** New:
- `macroInspectorBodyStandsBelowItsLists`: a member chosen shows below at the window's full width; chosen again it
  is reloaded and one undo brings the typing back; before any choice the place shows "(nothing chosen)"; the divider
  moves the split by exactly its travel, by mouse and by finger.
- `macroInspectorBodyBesideIsTheSetsLastColumn`: a browser built with `bodyPlace: "beside"` keeps the body as the
  set's last column and scrolls to it. This is the test that keeps the setting from being baked in.
- `macroInspectorTrailNamesAndRevealsEachLevel`: the levels' names and wording on the object flows of round 4
  (a widget, its class, an instance, a subclass, a child), a press revealing the column scrolled out.
- `macroInspectorOpensInsideTheDesktop`: on a tablet's and a phone's extent (a test's own `testScreenExtent`) the
  window opens within the desktop at the clamped extent. As built: TWO tests, `macroInspectorOpensInsideATabletDesktop`
  and `macroInspectorOpensInsideAPhoneDesktop` (a test declares one `testScreenExtent`).

**Predicted failing set**: EVERY test whose pictures show an inspector (§7.1's list, re-derived by
`node scripts/derive-inspector-churn-set.js --check` and by §4.5's run), every shot of each; the assertion-only
tests that read the editor through a locator pass once ported.

**Pictures for the owner before the gauntlet**: the seven object flows of round 4 and the default window, at a
desk, a tablet and a phone extent, on the review page beside round 4's own pictures.

**Docs.** `visual-design-system.md` §4.3 (the chip is gone; the trail band; the chevron's metrics),
`src/macros/CLAUDE.md` (the tool's shape, the default extent), the three CLAUDE.md files.

**Landed 2026-11-27** (inspector-browser loop; one commit per repo, this unit's). **Built**: the browser's division
stack [trail · the set's viewport · divider · body] with `bodyPlace` "below" (the default) or "beside"; the body derived
from the children, the EMPTY body an inspector on `undefined` ("(nothing chosen)", no step); `_reconcileMyStructureNoSettle`
and `_reactToChildRemoved` rebuilding the body, its divider, its tab and the trail; `InspectorDividerWdgt` (U1's column
divider by axis: a drag STATES the cell before it, a column's width or the strip's height; the seam `dragPlane` /
`dragAnchorAt` / `sizeDraggedTo`; in regime 1 a drag states nothing); the strip's stated height and DERIVED least (the
tallest least of the set's columns); the turned tab (`SplitGripWdgt` by axis, `BandWdgt.crossAlignInABand`); the reveal
of what a choice shows (`revealLastColumn` deleted; the reveal settles itself); the held scroll (L11, kept by a choice
that changes no column, honoured at the width it was written at, released by the next scroll, a stroke where it rests);
the trail (§5.5 as built); the walk keeping its view through the toggle path; `classButton` (`ChipWdgt` deleted with
its twelve roles); `defaultExtent` clamped to the desktop (D5); the toolkit's Point delta and list-scroll lead.
**Ruled in the loop** (PREP §2 and the LEDGER): the divider states, never trades (§5.4 corrected); the strip's least
derived; the anchor `min(desired, most)`; the empty body's subject `undefined`; one question `editsAsText`; the
derived wording; a walk switching after the choice (no constructor option); a level's name never throws; the trail
rebuilt only when out of place; two Opens tests. **Evidence**: probes on real mouse and finger input (the divider and
tab to both ends, 400 heights against the engine re-derived for every cell, picks, copies and a snapshot, U1's probes
on a beside browser, the double-click cases with controls, the default window at three desktops, the trail on every
object flow, a stroke keeping the hold); five new tests, ~35 ported; 36 plants each seen failing its own line under
both pointers; followers clean; every rig green; the dpr-1 mouse and finger suites failing exactly the predicted 26
pictures; two independent reviews, every (A) finding fixed. **Found on the way**: the gauntlet's tier-naming leg missed
one picture of the new body test; a virtual clock reproduced it exactly: `ListWdgt._applyExtent` moved a growing list's
rows inside its pinned plane by whichever extent a frame applied (a render the cadence chose) — deleted, with a
cadence-free regression line; a ported test's 2200 characters typed unwrapped crashed a back buffer at dpr 2 (soft
wrap now on first; the product's limit filed). **Ratchets moved**: `PROMPTS_DRIVEN_FLOOR` 87 → 99 (the
menu sweep's new roots); `METHOD_CEILINGS.Widget` 396 → 395 (lowered: a mover gone with its one caller); `Fizzygum-tests/CLAUDE.md`'s byte ceiling 66368 → 66319 (lowered). **Filed**: a trail longer
than its browser squeezes; a class reached by its `constructor` row is named "Function"; beside keeps U1's
double-click miss.

### U3. Every list its own footer of drawn icon buttons (1–1.5 days)

**Goal.** §5.7 for the lists that exist: methods and fields, children, instances; subclasses stays without a band
until U9 gives classes their verbs.

**Checkpoints.** U3.1 `ListVerbsBandWdgt`, the two placeholder marks, `verbsOffered` / `verbApplies` on
`MemberListWdgt` (its rule unchanged) with the text buttons deleted. U3.2 `ObjectListWdgt`'s band for children and
instances, their two verbs through the widget's own, the list read again afterwards. U3.3 the tests and the rigs
(`menu-click-sweep-headless.js` drives the member list's buttons by name and presses their prompts' OK: its fixture
section and `PROMPTS_DRIVEN_FLOOR` follow, what it judges unchanged).

**Tests.** New: `macroInspectorListFootersOfferOnlyTheirVerbs` (per kind of list: which buttons exist; disabled with
nothing chosen, on `constructor`, on an inherited member; a value's list with no band; duplicate and remove of a
child and of an instance; remove disabled for a window's content), under both pointers (a finger's 44 px).
Ported: every test that presses "Add…", "Duplicate…", "Rename…" or "Remove" by its label
(`macroAddEditSaveRenameRemoveProperty`, `macroInspectorDuplicateCopiesAMember` and the others the research names)
presses the button by its verb through one toolkit verb.

**Predicted failing set**: every picture showing a member list's footer or an object list (all of U2's set that
shows a list), plus the ports.

**Docs.** `visual-design-system.md` §4.3 (the footer of icon buttons; absent versus disabled), the icon inventory
if one lists drawn marks.

**Landed 2026-11-27** (inspector-browser loop; one commit per repo, this unit's: U3.1 and U3.3; U3.2 PARKED). **Built**:
`ListVerbsBandWdgt` (a kind of `BandWdgt`, `src/meta-tools`: built from its view's `verbsOffered()`, one button per verb
offered in the ONE order add, duplicate, rename, remove, at the footer band's metrics, its rule along its top, no field
of its own; `reflectVerbs` sets each button enabled from the view's `verbApplies(verb)`; `verbs()` and `buttonFor(verb)`
answer the toolkit and the sweep, so neither reads the band's pieces); the mark-faced `SimpleButtonWdgt` (`_faceIsAMark`:
44 × 36, `max(minimumTargetSize, buttonHeight)` by `buttonHeight` as every button is held to 44 across, the mark's square
centred, inked as a text face); `MenuRowIndicatorWdgt`'s third holder, the button; three placeholder marks
(`TwoSheetsIconAppearance`, `TextCursorIconAppearance`, `BinOutlineIconAppearance`) beside the reused plus, at the new
metric `inspectorVerbMarkSize` (16); `MemberListWdgt.verbsOffered` (a table: none unless `MemberRef.canEdit`, its rule
unchanged), `verbApplies`, `verbsBand`, and `MemberListWdgt.noteMembersMayHaveChanged`, which the tail every member step
ends in (`_notifyOfEdit`) calls, so every member list on the holder follows a step made through any of them, a Save
included; the toolkit's locator `listVerbButtonOf`, its reader `listVerbsOf` (the band's `verbs()`), and the verbs
`clickListVerb_InputEvents_Macro` and `answerListVerbPrompt_InputEvents_Macro (listView, verb, typed, options = {})`
(`options.replacing`; one of each: the three test-local prompt answerers replaced), with their two aim-census rows.
**Deleted**: the four text buttons, their fields (`addPropertyButton` and its three twins), `footerBand`,
`_buildAndConnectEditRow`, `_reflectMemberSelection`. **Ruled in the loop** (PREP §2 and the LEDGER): §5.7 as built (the
member lists only, the object lists' band PARKED as U3.2 and asked; 44 × 36 buttons, the house's rule for every button,
where PREP had said 36 × 36; the words as tooltips, the view's; ONE seat for what a member step changes, the steps' tail,
where CP1 had the Save tell the lists itself; the marks named by picture, the rename mark no pencil; the verbs a table,
never a list literal of names); the menu sweep finds the band's buttons by verb (`buttonFor`) and judges their tooltip
words, its rule `BUTTON_FACE_MISSING` renamed `BUTTON_WORDS_MISSING` (a verb button's words are its tooltip, the bin's its
face), and drives the same six prompts (`PROMPTS_DRIVEN_FLOOR` 99 unchanged); its self-test's UNBUILT plant builds a
fifth band button through the product's own table, its EMPTIED plant strips "…" from the tooltips; the serialization rig
reads `verbsBand` and `verbApplies("rename")`. **Tests**: new `macroInspectorListFootersOfferOnlyTheirVerbs` (both
pointers, its own two classes deleted in its `finally`; 18 assertions and 15 plants across it and the three tests that
would have passed vacuously as CP2 built it; the fix pass made its add line tell add from duplicate and rename, added a
line of two member lists on one holder, and planted the press lines no plant had bitten and the one seat); 35 tests
ported (presses by verb, enabled states through the locator, the three vacuous reads now reading the band both ways it
can stand, every width re-derived from 365 / 364 / 286 / 285 / 246, five windows restated where the set no longer
overflowed, four gestures re-lengthened, §5.7). **Evidence**: a footer probe on real mouse and finger input
(`u3/cp1/probe-footer.js`, VERDICT OK: the band's order, sizes, actions, tooltips and measured ink, the states at every
seat with a control for the Save seat, real presses opening the same prompts, no band on a Point's list or on a
Children, Instances or Subclasses list, the widths 365, 246 and 286 as predicted); the marks' geometry at 16, 32, 24 and
13 px (`u3/cp1/marks-ascii.js`: every rect integral, inside its square, no pixel painted twice); the footer looked at, at
dpr 1 and 2; the new test passing under both pointers. Then, on CP1–CP3's build (before the reviews' fix pass): the dpr-1
presuite (paint audit and fracplane rider PASS) and the finger suite each failing exactly PREP §4's predicted set, 25
picture tests (U2's 26 less CutListSaysSo, matched by name), the finger run with one ASSERTION more, ColumnsScroll's AIM
MISSED (traced, `u3/cs-finger/trace-swipes.js`: its wheel 300 → 200, §5.7), both pointers' assertions passing after;
followers clean under both pointers (no `WORLD_INVENTORY_` line); the menu sweep OK (8192 items, 126 prompt OKs, U2's
count, 20 of 20 contributors) and its self-test 24 of 24 rules planted; the serialization rig OK (198 expectations) and
its self-test 7 of 7; 104 + 18 plant runs (`u3/plants/`, `u3/plants-ported/RESULTS.txt`), no rule unbitten once the
stale ones were ported: the 15 new plants first on their headers' lines under both pointers; the 74 U1 and U2 plants of
the re-numbered tests (mouse), 59 on the same line as in their units, 7 on the same line reworded or re-numbered,
ColumnsScroll's notch plant tripping the toolkit's aim check first, its latch plant failing no line under the mouse as
in U1 (its rule is the finger's), and SIX found STALE since U2 (`PLANT_NOT_APPLIED`: they hooked
`InspectorColumnDividerWdgt.columnWidthDraggedTo` and `revealLastColumn`, which U2 reworked and deleted without
re-running them, a hole in U2's evidence) — five ported (`u3/plants-ported/`, DividerSizes', each failing first on its
own line under both pointers), the sixth (ColumnsScroll's removal leaving the offset past the end) not ported, its rule
REVERSED by U2's ruling (a removal holds the scroll) and U2's own plants covering the hold and its release; and
ColumnsScroll's 8 U1 plants re-run under the finger once its wheel changed, each as in U1, its stroke plant now on its
own line. The difference page (`fg diffpage`, the 25 tests at dpr 1 and 2: 50 changed groups, 114 changed shots,
0 unchanged, 0 INVALID), every shot looked at on contact sheets (`u3/look1`, `u3/look2`): the four text buttons become
the four icon buttons, the list 7 px narrower, the windows the ported tests state; ONE state change, correct
(NakedInspector's two shots after its Save: duplicate, rename and remove enabled where the reference kept them disabled,
the Save seat); every dpr-2 change region exactly twice its dpr-1 one (57 of 57); no paint error. **Reviews**: two,
independent and read-only. Review A (the source) found nothing bent for a number, and: the verbs missing a step made
through ANOTHER list on the same holder, with comments claiming every seat (→ the ONE seat at the steps' tail, the
comments saying what is seen and what is not); `listVerbsOf` reading the band's pieces' order (→ `verbs()`); the text
cursor's geometry overlapping below about 14 device px, in the button's shrink branch only (→ made to hold, CP4a); the
button's header claiming its row meets the 44 rule (→ the 44 × 36 button); `answerListVerbPrompt`'s bare boolean
(→ `options.replacing`, every caller ported); a tooltip appearing after a finger's tap, and a band a dev-mode Destroy
destroyed kept by its list (→ BACKLOG); `popUpIdWhenHoldScheduled` never cleared (unreached) and
`_selectedMemberCanBeRenamedOrRemoved` naming two of the three verbs it gates (→ LEDGER lines). Review B (the tests,
plants, rigs and docs) found: the new test's add line unable to tell add from duplicate or rename, and three press lines
no plant had bitten (→ the line made to tell them, a plant each); ColumnsScroll's finger plants not run after its wheel
changed (→ run, above); BodyStands still wheeling 300 over a class column (→ 200); MACRO-PATTERNS' 300 and its notch
plant, ColumnsScroll's provenance, EditTellsOnce's scenario, this plan's silence on the changed gestures (→ made true);
the claims that the 44 rule is met (→ the 44 × 36 button); the serialization rig's comment and two stories naming the
old footer's add button as the band's (→ made true); the sweep's renamed rule's verb branch never planted, and the
verbs' ORDER in EditsAClassPrototypeAsAClass's and OnNonWidgetIsReadOnly's positive lines unplanted (→ a plant each).
**After the fix pass**: the footer probe VERDICT OK again (44 × 36, the band's least 224 and desired 225, and a new
flow: two browsers on one rectangle, a stubbed-seat control, then one list's real Remove and Add… followed at once by
the other's buttons and ink, both pointers); `marks-ascii.js` over 8..48 px, every claim of every mark's header holding
at all 41 sizes (the text cursor 25 of 41 before its fix, pixel-identical after at 16, 32 and 48); the new test (19
assertions) passing under both pointers; the presuite and the finger suite each failing exactly the same 25 picture
tests, with no assertion failure; followers clean; the menu sweep OK (126 prompt OKs) and its self-test 44 cases, 24
of 24 rules, the verb branch planted; the serialization rig and its self-test OK; 63 plant runs, every one applied and
none passing — each of the 22 plants of this unit failing first on the line its header names under both pointers,
BodyStands' U2 plants under the finger failing as in U2. The difference page again (the same 50 groups, 114 shots),
looked at: between the two rounds every render changed only inside the band's 36 px row (the buttons 44 wide), every
dpr-2 region twice its dpr-1 one. Recaptured by name, mouse then finger, dpr 1 and 2: exactly the 25 tests, each run COMPLETE (the full
suite green); `fg gauntlet` OK, 20 legs, clean; `fg homepage` OK. **Ratchets moved**: the tests' CLAUDE.md byte ceiling
66319 → 66313 (lowered).

### U4. "Open in a new inspector" (1–1.5 days)

**Goal.** §5.8.

**Checkpoints.** U4.1 the capability and the menu row in both modes (research first: the menu's climb, the two
builders, `fg menusweep`'s derivation of menu contributors, which will require the new row to be dispatched). U4.2
Cmd-click on a list row, the class button and a trail level. U4.3 where the window lands (D12). U4.4 the tests and
the sweep's root for the new row.

**Tests.** New: `macroInspectorOpensAThingInANewInspector`: each of the four kinds of thing by the menu row in user
mode, one by the row in developer mode, each by Cmd-click; after each, the original's trail, columns, chosen rows
and body read as before; the new window's title, extent and place; a member opened this way stands chosen in its
holder. The menu row by a finger's hold. `pointerKinds: ["mouse"]` only for the Cmd-click half, with its reason.

**Predicted failing set**: none beyond the new test's first captures, unless a test opens a developer-mode menu
over an inspector's list row (the research greps for one).

### U5. The meta-object keeps comments and categories; the marker gate (2 days)

**Goal.** §5.9 and §5.10. Nothing a person sees changes: no widget reads the new stores before U7. That is the
unit's check: **predicted failing set EMPTY, no picture moves.**

**Checkpoints.**
1. **U5.1 The parse keeps what it drops**, static and instance alike; the accessors; `Class.splitLeadingComment`.
   A Node proof first (the agent writes it under `u5/`, through `buildSystem/lib/meta-compiler.js`): over all 560
   class files, every member's SOURCE string identical to today's, byte for byte; the compiled output of every class
   identical; a class's text rebuilt from header, comments, markers and sources differing from the file only by
   what §5.9 says is not kept (state the count).
2. **U5.2 The edits**: `applyMemberEdit`'s two options, `removeMember`, the class's comment and category list, the
   boot record, `membersAwayFrom` over all three, `returnThePageToBootSources`.
3. **U5.3 The records**: a member's record carrying comment and category; the two new kinds; `isARecord`;
   `replayClassEdits`; `Deserializer`'s validation of the section (`_sectionSourceEditsProblem`).
4. **U5.4 `ClassMemberRef`**: `shownText` with the comment above, `save` through the split, duplicate and rename
   carrying both. (From here an editor on a class's member SHOWS its comment: that moves pictures, so U5.4 lands
   with U7 if the unit's prediction is to stay empty. Decide in PREP.md; the default is to hold U5.4 for U7.)
5. **U5.5 The gate**: `check-method-categories.js`, its registry, advice rows, bite-proof, its row in `gates.js`,
   its lines in `lint-and-static-checks.md` §3 and §3b; the five dead lines of `LCLProgramRunner.coffee` deleted
   (compiled output proved identical); the budget recorded at the measured count with its date.
6. **U5.6 The docs and the rubric**: `docs/architecture/method-categories.md` (new: the marker, the rule, the
   vocabulary, the gate); `serialization-duplication-reference.md` §12 (the records); the comment rubric's line
   (the grant decides who commits it).

**Tests.** The serialization rigs gain expectations (`serialization-roundtrip-headless.js`, the block that edits
class members over a page and loads): a member's comment and category set by an edit survive a save and a load in
the same page and in a fresh one; a load returns a changed comment to boot; a class's comment and an added, empty
category likewise; a file whose record carries a malformed category is refused before anything changes. One
SystemTest, assertion-only, `macroClassKeepsItsCommentsAndCategories`: on a class made in the test from a text with
a header, two markers and commented members, the record answers each; an edit with and without the options; the
split and its join. Each rule of the gate is planted by its bite-proof.

**Ratchets that move, each class C, dated**: the `null-literal` sanction for `getSourceOfAllProperties` (exactly
two today); `Class`'s method ceiling and complexity records where a method grows or moves; the new budget itself.

**Stop conditions.** Any member's source string or any class's compiled output differing in U5.1's proof: stop,
the parse changed what it must not. `fg homepage` failing after the gauntlet (the first run of the kept stores on a
pre-compiled tree, where meta-objects are built at the reflective layer's load): read it as a real break.

### U6. The first classes get their categories (1–2 days, D1)

**Goal.** Marker lines in the source of the classes D1 names, and nothing else: no code line touched, no method
moved, no comment reworded.

**How.** One Opus agent per big class (`Widget`, `FrameWdgt`, `StringWdgt`, `WorldWdgt`, `ViewportWdgt`), each
reading the WHOLE class before placing a marker; the rest in batches of about ten classes. Each brief gives the
vocabulary and what belongs in each name (`method-categories.md`), the form, and the rule that a category may open
more than once. Each agent returns, with its diff, a table of every method and its category, and the methods it
was least sure of. An existing banner that says what a marker would say is REPLACED by the marker (one line for
one line); a banner that names a topic stays, the marker beside it.

**Proof.** The build's compiled output for every touched class byte-identical to the last commit's (comment-only);
the gate green with its budget LOWERED to the new count, dated; `git diff --stat` showing insertions only, plus the
replaced banners. A sampled review (Review B): one method in ten, across every class, judged against the
vocabulary; a class whose sample is under four in five right goes back to its agent once.

**Predicted failing set: EMPTY** (no widget reads a category before U7).

### U7. The code browser (2–3 days)

**Goal.** §5.11, §5.12, and U5.4 if it was held: the four lists of the owner's picture, on real packages, real
categories and real comments.

**Checkpoints.** U7.1 the four values and `sameSubjectAs`. U7.2 `ObjectListWdgt`'s three derivations and how a row
of values reads; `_views` for each subject. U7.3 a class's column: "Categories" first, "Comment" in the body. U7.4
a category's member list (the filter, the toggles, Add… in the category, D13's lone "all"). U7.5 the door and the
"Code browser" row; `PartsRegistry`'s list of parts; a package loaded on its choice. U7.6 the door on a member
through a class's categories (the paint tools' "Edit code" opens on an object, so it is unchanged: prove it).
U7.7 the footers of the new lists by §5.7's table (packages none; categories and classes built with the verbs U8
and U9 give them, so in this unit categories and classes have NO band yet). U7.8 the toolkit (a verb to choose a
row of each list by its label; `topMemberList` across a category's list), the tests, the rigs (the sweep's roots
gain the new parts of the tool in their places; `smoke-apps` and the parts rigs where the Dev tools menu is
walked).

**Tests.** New:
- `macroCodeBrowserWalksPackageClassCategoryMethod`: the door; a package, a class, a category, a method; the trail
  at each step; the lists' widths and what stands whole at 1366 × 768 (the owner's picture, taken as a reference);
  the body showing the method's comment above its code.
- `macroCodeBrowserCategoriesListAndFilter`: "all" first and not chosen; a category's list shows its methods only,
  no Fields toggle; with Inherited the superclass's methods of that category; a class with no category opens on
  "all" chosen.
- `macroCodeBrowserClassCommentShowsAndSaves`: the Comment view in the body; an edit saved; the member's comment
  edited above its code and kept across a choice of another member and back.
- `macroCodeBrowserDoorOnAMemberGoesThroughItsCategory`; and `macroInspectorDoorOpensOnAMember` ported (an object:
  unchanged).
- `macroCodeBrowserLoadsAPackageOnItsChoice` cannot be a SystemTest (the harness page has every part eager):
  it is a section of `parts-lazy-load-headless.js` on `index.html`, its rule planted.
- A snapshot: an expectation in the serialization rig that a browser saved open on a package, a class, a category
  and a class's comment restores each (the four values in a file).

**Predicted failing set**: every picture of an inspector on a CLASS (its column gains Categories and Comment, its
members move one list right): named from U2's recaptured set before the suite; every picture of an editor on a
class's member that has a comment (if U5.4 lands here); the ports.

**Pictures for the owner before the gauntlet**: the code path at 1366 × 768, 760 × 720, a tablet and a phone,
beside round 5's `c5-icons-*` pictures.

**Docs.** `src/macros/CLAUDE.md` (the tool's levels, the door), `build-and-packaging.md` §2 (the third door),
`visual-design-system.md` where it pictures the inspector, `method-categories.md` (how the browser reads them).

### U8. The verbs of categories; a method moved to a category (1.5 days)

**Goal.** §5.14's first half, and the categories list's band (add, rename, remove). Tests:
`macroCodeBrowserCategoryVerbs` (add an empty category, add a method in it, rename it and see the method follow,
refuse to remove it while it holds the method, move the method out by the menu row, remove it; "all" offers add
alone; every refusal's bubble), both pointers; the serialization rig's expectation that each survives a save and a
fresh-page load. The sweep presses the three buttons' prompts (its floor follows).
**Predicted failing set**: the pictures of a categories list (they gain a band).

### U9. The verbs of classes: add, and remove of a class made at run time (2–3 days, D2)

**Goal.** §5.14's second half as D2 rules it. If D2 is ruled "nothing yet", this unit does not run and its BACKLOG
line stands.

**Checkpoints.** U9.1 the name's check, the making of a class from its one-line text, the vault entry, the record,
`noteCodeChanged`, every open class list read again. U9.2 the load: `isARecord`, the pre-teardown checks' "can
still arrive", the replay at `Deserializer.loadWhatItNeeds`, a name that collides with a class the page has (refused
before the teardown). U9.3 remove: the guards, the inspectors on it closed first, the records pruned. U9.4 the
classes' and subclasses' bands. U9.5 tests and rigs.

**Tests.** `macroCodeBrowserMakesAndRemovesAClass` (add in a package and as a subclass; each refused name with its
bubble: an existing class's, `Audio`, `toString`, a lower-case one, a reserved word; the new class listed, opened,
given a method, instantiated; remove disabled while it has an instance, a subclass, or a class naming it, enabled
after; a class the build ships offers add alone), and it must leave the page as it found it (the classes it made
removed: its follower proves it). The serialization rigs: a world holding an instance of a class made at run time
loads in a FRESH page; a file defining a class the page already has under another text is refused before the
teardown; `parts-snapshot-load-headless.js` where a defined class's superclass is in a lazy part. `fg homepage`.

**Stop conditions.** A load that tears the desktop down and then fails on a define record: PARK the unit (a load
must refuse before it changes anything). A class whose removal leaves any registry of §4.4's table naming it: PARK
remove, land add.

### U10. Finding by name: candidates for the owner (0.5 day, D7)

Two candidates on the real build patched at load (no source change), on the tasks round 4 found costly (a class in
another package; a widget's own `color`), gestures counted, at a desk and on a phone, by mouse and by finger: a
filter line at the top of a long list; a "Find…" prompt that jumps to a class or a member by name. On the review
page, then PARKED: the owner chooses, and the build is a unit of its own afterwards. Nothing is committed.

### U11. Close (0.5 day)

1. `node scripts/derive-inspector-churn-set.js --write` from `Fizzygum-tests/`, its diff read (the tool's own
   BACKLOG item, an INVALID end on a no-picture test, is the owner's: if it still ends so, say so and leave the
   file).
2. Every doc of §7.4 true; `check-doc-narration` green.
3. `docs/BACKLOG.md`: this plan's section holds what the arc leaves open (§11, the decisions' filed halves, what
   the units filed); every line of `inspector-overhaul-plan.md`'s section that the new shape settles or changes is
   re-read (the widening's two lines; "A window does not honour its content's least size"; "A member editor has no
   visible 'open the value' control"; "A double-click in a list standing in no row"; "An inspector attached into a
   row"; "A row whose only inspector was picked up") and closed, re-worded or left, each by what is true now.
4. The review page finished and opened; the memory note; the final digest.
5. The plan STAYS in `docs/plans/` with its units ticked: the owner closes the arc.

---

## 7. Touch-lists (as of 2026-11-26; each unit's research re-derives its own before it edits)

The lists were derived by scanning code lines (spike S4, `spikes/s4-static.js` and `s4-static.json`; the earlier
research's test-by-test reading is `Fizzygum-tests/.scratch/inspector-columns/RESEARCH.txt` Q6, which quotes the
line each assertion stands on) and checked against the suite run of §4.5.

### 7.1 The SystemTests that touch the inspector: 48, declaring 67 screenshots

**The 21 with pictures of a member list** (`Fizzygum-tests/scripts/inspector-churn-set.json`: every shot of each
changes in U2, most again in U3, those on a class again in U7): `macroAddEditSaveRenameRemoveProperty`,
`macroAnalogClockInspectEdit`, `macroDuplicateComplexWidgetPaintsCleanly`,
`macroDuplicatedInspectorDrivesCopiedTargetOnly`, `macroDuplicatedInspectorsCloseIndependently`,
`macroInspectorChildrenViewWalksTheWidgetTree`, `macroInspectorCodePaneRunsAgainstItsSubject`,
`macroInspectorDoorOpensOnAMember`, `macroInspectorDrillWidensItsWindow`, `macroInspectorRejectsDrops`,
`macroInspectorResizingOKEvenWhenTakenApart`, `macroInspectorScrollbarUnplugged`,
`macroInspectorShowsAValueAsCode`, `macroInspectorSplitMovesByDividerAndByButton`,
`macroMovingSlidersSidewaysDoesntCauseContentToMoveSideways`, `macroMultilineTextInputScrollsWell`,
`macroNakedInspectorRendersResizesAndEdits`, `macroPickingUpPartsFromInspector`,
`macroResizingPristineInspector`, `macroSimpleDocumentHandlesInspector`, `macroWrappingTextFieldResizesOK`.

**The 27 others** (24 take no screenshot and must PASS once ported; three take pictures that show an inspector
window without a member list's rows deciding them: `macroClassEditShowsOnTheNextFrame` 11 shots,
`macroDrawingToolReachesEveryDrawingOfItsHolder` 1, `macroInspectorCutListSaysSo` 1):
`macroAStepThatThrowsStopsStepping`, `macroClassEditShowsOnTheNextFrame`,
`macroDrawingToolReachesEveryDrawingOfItsHolder`, `macroEditMarkAndMenuRowOpenTheSameMember`,
`macroEveryCodeChangeGivesBannedWidgetsAnotherChance`, `macroFormulaBarUndoStaysInItsEdit`,
`macroInspectorClassButtonShowsTheClassBesideIt`, `macroInspectorClassViewsListInstancesAndSubclasses`,
`macroInspectorCutListSaysSo`, `macroInspectorDuplicateCopiesAMember`, `macroInspectorEditTellsOnce`,
`macroInspectorEditsAClassPrototypeAsAClass`, `macroInspectorMemberClickOpensItsEditorBelowTheLists`,
`macroInspectorOffersOnlyWhatItsSubjectOwns`, `macroInspectorOnAClassShowsItsStaticsSource`,
`macroInspectorOnNonWidgetIsReadOnly`, `macroInspectorSaveOfAClassMemberRefusesCodeThatDoesNotCompile`,
`macroInspectorSaveRefusesCodeThatDoesNotCompile`, `macroInspectorShowsAnUndefinedFieldAsUndefined`,
`macroInspectorShowsTheFunctionItsSubjectHolds`, `macroInspectorTakenOutLeavesNoStraySplitter`,
`macroInspectorViewSwitchDropsWhatWasChosen`, `macroInspectorViewThatCannotBeBuiltLeavesItWhole`,
`macroPaletteBufferKeyNamesItsOwnCode`, `macroTextOwnCodeKeysTheCachesItRunsIn`,
`macroToolCodeSaveRefusesCodeThatDoesNotCompile`, `macroToolMemberThatCannotBeMadeErrsOnce`.

**What breaks a test, by mechanism** (a test may carry several; counts by a scan of code lines, a starting point):

| Mechanism | Tests | Unit that meets it |
|---|---|---|
| The editor found as "the row's next inspector" (`memberEditorFedBy`, `topMemberEditor`, the three code-pane verbs) | 36 | U1.6 (the locator asks the browser's sequence), then U2 (the body leaves the row) |
| A window read from a list by a `.parent` chain (`memberList.parent.parent.parent`, `row.parent`) | 20 | U1.6: a toolkit verb answers a list's window; the chains go |
| A row index (`inspectors()[1]`, `inspectors().length`) | 12 | U1.6 (the browser's sequence) |
| A class's prototype as the subject: its first view becomes its categories | 9 | U7 |
| The split between a list and its editor (`dragSplitControlBy`, `SplitGripWdgt`, `splitterBefore`) | 5 | U1 (a column divider sizes one column), U2 (list and editor are split by the browser's divider) |
| Asserted widths of a widened window, of traded columns | 6 (RESEARCH Q6 A) | U1: rewritten or retired, test by test |
| Buttons pressed by their text ("Add…", "Rename…") | the unit's research counts them | U3 |

`macroInspectorDrillWidensItsWindow` is retired (U1). `macroInspectorMemberClickOpensItsEditorBesideTheList` and
`macroInspectorClassChipShowsTheClassBesideIt` are renamed when what their names say stops being true (U2):
`macroInspectorMemberClickOpensItsEditorBelowTheLists` and `macroInspectorClassButtonShowsTheClassBesideIt`.

### 7.2 Product code outside `src/meta-tools/`

- `src/basic-widgets/Widget.coffee`: `inspect`, `inspectMemberToEdit`, **`spawnInspector`** (the door: the
  browser's construction, its opening extent, `chooseMember`); `buildContextMenu`'s user-mode branch (U4's
  precedent); `buildBaseWidgetClassContextMenu` ("Inspect"), `_addEditCodeMenuEntry` ("Edit code").
- `src/WorldWdgt.coffee`: the desktop's "Inspect" row; `openFrameWith`; `noteCodeChanged`; `loadWorldSnapshot`
  (U5, U9). `src/basic-widgets/menu-system/MenusHelper.coffee` `popUpDevToolsMenu` (U7's "Code browser" row).
- `src/basic-widgets/TextWdgt.coffee` `inspectSelection`; `src/authoring/EditableMarkWdgt.coffee` `activated`.
- `src/StackElementsSizeAdjustingWdgt.coffee`, `src/LayoutChromeWdgt.coffee` (the kept press, the joined piece),
  `src/basic-widgets/ViewportWdgt.coffee` (read, extended by a subclass, not changed in what it does for others),
  `src/ListWdgt.coffee` (a row's menu question, U4), `src/SimpleButtonWdgt.coffee` and `src/ChipWdgt.coffee` with
  `src/Theme.coffee`'s `chip*` roles (U2), the icon appearances (U3).
- `src/meta/Class.coffee`, `src/serialization/SourceEditsRegistry.coffee`, `Serializer.coffee`,
  `Deserializer.coffee` (`_needsTheReflectiveLayer`, `_sectionSourceEditsProblem`, `loadWhatItNeeds`,
  `whyItCanNeverBeRestored`), `src/PartsRegistry.coffee`, `src/boot/source-vault.coffee` (U5, U7, U9).
- `src/macros/MacroToolkit.coffee` (the block "THE INSPECTOR'S TWO LOCATORS" and the inspector verbs around it; the
  window verbs that take a frame).
- Comments that describe the row's shape and must stay true: `src/PartsRegistry.coffee`, `src/Theme.coffee`,
  `src/LayoutChromeWdgt.coffee`, `src/StackElementsSizeAdjustingWdgt.coffee`, `src/basic-widgets/BackBuffer.coffee`,
  `src/ListWdgt.coffee`, `src/BinWdgt.coffee`, `src/boot/globalFunctions.coffee`.
- `buildSystem/`: `parts.json` (the `meta-tools` note), `check-stinks.js` (the `null-literal` sanction),
  `check-complexity-ratchets.js` (method ceilings and records re-keyed), `gates.js` and the new gate's five files
  (U5), `lib/call-sites.js` and `check-coffee-syntax.js` (read: they must see no difference).

### 7.3 Rigs, tooling and gates (`Fizzygum-tests/scripts/`; what each JUDGES stays as it is)

- **`serialization-roundtrip-headless.js`**: its inspector helpers assume the row (`R.memberListOf row`: "its
  first inspector's view"; `R.inspectorBeside`; `R.memberEditorBeside`: "the member editor standing in the
  inspector right of"; `R.chooseMember`); `insp.parent instanceof InspectorRowWdgt`; rows opened on class
  prototypes; `bootOfClass`, which reads the parse's results by position (U5). New expectations: U5, U7, U8, U9.
- **`menu-click-sweep-headless.js`**: `INSPECTOR_FIXTURES` (`InspectorRowWdgt[widget]`, `[class]`),
  `memberListOf`, `codePaneOf` (`row.inspectors()[1]`), `inspectorWindowWithAMemberChosen` (it asserts the row is
  the window's content, two inspectors, a splitter and a split button: nine roots hang on it),
  `inspectorWindowShowingChildren`, the member list's buttons driven by name, `PROMPTS_DRIVEN_FLOOR`; its self-test
  `menu-click-sweep-selftest-headless.js` (plants on a row's inspectors). New roots: the trail band, the body's
  place, the browser's divider and its tab (U2); the footer band (U3); the row that opens a new inspector (U4);
  the lists of U7 with their bands (U8, U9); the "Code browser" row.
- **`smoke-boot-headless.js`** (`fg homepage`): `inPageMakeInspectorFiles`, `inPageOpenInspectorFile` (a restored
  inspector on a class's prototype, its first view a member list, the editor "beside, in the row").
- **`staleness-census.js`**: `inspector-window`, `tool-inspector-window` (opened, then resized by its battery).
- `smoke-apps-headless.js` (counts inspectors by name), `parts-snapshot-load-headless.js` (a class key
  `class:InspectorRowWdgt`; U9's lazy-part case), `parts-lazy-load-headless.js` (U7's package loaded on its
  choice), `derive-inspector-churn-set.js` and `scripts/inspector-churn-set.json` (U11), `aim-census.js` (the
  inspector verbs by name), `pin-sweep-headless.js` (new widget classes are swept: none advertises a pin).
- The audit preludes name the inspector in comments only.

### 7.4 Docs that describe the inspector, and what each unit makes untrue

- `Fizzygum/src/macros/CLAUDE.md`, the bullet "One inspector tool — a ROW of inspectors": the 760 × 528 window and
  its row, "The first view is always the member list", the editor "there" beside the list, the widening and its
  374, `memberEditorFedBy` as "the inspector standing next after that list's own in its row", "An inspector's
  `parent` is its row and the row's the window", the split between two inspectors. `MACRO-PATTERNS.md` beside it
  (about fifteen passages: the `.parent` chains, "760 × 528 … its row 758 × 439", the widening's arithmetic).
- `docs/architecture/layout.md` ("A TOOL is composition the same way. The inspector (`InspectorRowWdgt`) is an 'x'
  division row…"); `widget-citizenship.md` (the inspector as an assembly of ordinary widgets);
  `visual-design-system.md` §4.2 (the 44 rule's worked split), §4.3 and its widget table (the row, the header with
  its `ChipWdgt`, the footer); `input-and-gestures.md` (the split button as a press-keeping control: the divider
  joins it); `viewports-and-planes.md` (the family, the contract); `lint-and-static-checks.md` (the sweep's
  inspector roots; the new gate's row in §3 and its rules in §3b); `build-and-packaging.md` §2 (the doors);
  `serialization-duplication-reference.md` §12 (the records); NEW `method-categories.md` (U5).
- `Fizzygum-tests/CLAUDE.md`, the `menu-click-sweep-headless.js` bullet ("each PART of an inspector in its place").
  The umbrella's and `Fizzygum/CLAUDE.md` state nothing of the inspector's shape.
- `docs/BACKLOG.md`, the earlier plan's section: the lines U11 step 3 names.

---

## 8. Central risks

| # | Risk | Mitigation, and when to stop |
|---|---|---|
| R1 | The scrolling row does not settle in the PRODUCT though it did in the prototype (the prototype overrode two measure queries on the inspector; the product states the width some other way) | U1.2's probe before anything else is built on it: 400 widths and heights, zero `RECALC_NONCONVERGENCE`, zero re-visits, the row's box equal to its measure. `fg revisits` and the `settle` leg hold it after. Two fix shapes falsified: PARK U1 with its patches; the prototype's override is then the known-good fallback to re-frame from |
| R2 | The kept press starves something that listened to it (a splitter inside a pane that scrolls, the halo's adjusters, "Edit layout") | U1.4 greps every `pressBegan`, every division stack inside a viewport, and runs the two halo tests that drag a splitter. If a reader exists, the press is kept in the column divider and its tab only |
| R3 | U1 moves pictures it claimed it would not | That claim is the unit's regression net, not a hope: a moved picture outside the named set is first read as a defect in the measure (the last column's slack, the body under the inspectors, the viewport's indicators) and fixed at its cause. Only a difference that is the target's own consequence, said in the LEDGER with its pixels looked at, is re-taken |
| R4 | The body out of the row loses what "the row's next inspector" gave for free: the reload with its undo step, `showsSubject`, the split button, the body painted once | U2.1 moves the rule of choice over the whole sequence first and proves the reload by a test (`macroInspectorBodyStandsBelowItsLists`); the body's place paints its own body (`InspectorBodyAppearance` asks the parent: the place answers) |
| R5 | A rule that reads a size its own effect changes (reframe 4) creeps back in: the split between lists and body, the default extent's clamp, the reveal | Every such rule is written from fields; U2.1's probe drags a window's corner through 400 heights and counts the split's moves (0 expected beyond the stack's own arithmetic) |
| R6 | A value subject in a snapshot is refused, or a copy of a browser shares what it should not | `MemberRef` already rides copies and saves as an ordinary object (the earlier plan's R6, retired by a real save and load); each new value gets the same expectation in the serialization rig in the unit that makes it. A refusal is answered by a declaration the class makes, never by a transient that loses the subject |
| R7 | Changing the parse changes a compiled byte, or a member's source string, and with it boot | U5.1's proof over all 560 classes BEFORE the build: every source string and every compiled class identical. `fg homepage` after the gauntlet. A difference stops the unit |
| R8 | The kept comments cost boot time or memory a person feels | Measured: about 14 ms and 4.4 MB on a page that builds every meta-object at boot; nothing on a production tree until the reflective layer loads. Re-measured in U5 by the same probe (`spikes/s1-*`) |
| R9 | The new gate's budget is treated as a wall, or the marker spreads as a new exclusion syntax | §5.10 says it in the gate's own header: it excludes nothing; its one number falls; a class B rule is met, never suppressed. The rubric registers the marker so an audit does not reword it |
| R10 | Categories assigned by agents are wrong in bulk | They are metadata: wrong ones break nothing. One agent reads a whole big class; a one-in-ten sample is judged; the owner sees them in the browser, which is the point of the arc |
| R11 | Recapture hides a real break: a ported macro that passes for the wrong reason | Each ported test's `intent` re-read against the port (Review B); every new assertion planted; the failing set equal to the prediction under each pointer |
| R12 | A class made at run time corrupts a load (U9) | The define record is replayed before the teardown, and a file that cannot define its class is refused with the desktop untouched; the rigs load such a file in a fresh page. U9 is last and parks alone |
| R13 | The pictures no longer match what the owner chose | Each unit a person sees puts its real pictures beside the prototype's on the review page BEFORE its gauntlet |
| R14 | Another arc is uncommitted in the same trees | §0.5 step 1: stop and ask |
| R15 | A phone held sideways gets no body, and someone "fixes" it by placing the body by the window's shape | Known and chosen (§5.2). The body's place is a setting, fixed as the browser is built (L2); a rule that moves it is in §10 |

---

## 9. Verification protocol

- **Static gates:** `/Users/davidedellacasa/code/Fizzygum-all/fg build` (every gate of `buildSystem/gates.js`, each
  gate's own bite-proof first).
- **Inner loop:** `fg presuite > /tmp/fg-presuite-run.log 2>&1` in the background, then
  `cat /tmp/fg-presuite.verdict`. For a unit that changes pixels or input, also the finger suite at dpr 1, from
  `Fizzygum-tests/`: `node scripts/run-all-headless.js --pointer=finger` (in the background, with a log).
- **One test:** from `Fizzygum-tests/`, `node scripts/run-macro-test-headless.js SystemTest_<name>` (add
  `--pointer=finger`, `--dpr=2`, `--browser=webkit`, `--all-logs` to read every assertion). It kills leftover
  headless browsers at its start: never beside another browser op.
- **A prediction, before a unit's suite:** the unit's set is written down first (§7.1 is the starting list). Where
  a unit's change can be stood in by a patch at load, run the suite under it as a prelude first
  (`node scripts/run-all-headless.js --prelude=/abs/file.js`): §4.5 did this for the whole shape.
- **A leak:** `node scripts/run-sequence-headless.js --pointer=<p> SystemTest_<new> SystemTest_<any>` on both
  pointers; zero `WORLD_INVENTORY_` lines.
- **One rig:** `fg menusweep`, `fg pinsweep`, `fg census`, `fg revisits`, `fg vmtruth`, `fg storage`, `fg graph`;
  the serialization rigs from `Fizzygum-tests/`: `node scripts/serialization-roundtrip-headless.js`, then
  `node scripts/serialization-file-roundtrip-headless.js`.
- **The pictures:** `fg diffpage <tests> --dprs=1,2 --out=<abs dir>`, every changed shot LOOKED at, before any
  recapture. Then, a build first, `fg recapture --auto --dprs=1,2`, then
  `fg recapture --auto --pointer=finger --dprs=1,2`, each ending `✅ RECAPTURE COMPLETE` on exactly the predicted
  tests. Never `fg recapture-inspector`; never an Automator version bump.
- **A test bites:** `--prelude=/abs/plant.js` on the single runner, one plant per rule of the test, under both
  pointers; the test fails on its own line, then passes with the plant removed. Plants are re-copied and re-run on
  the FINAL build.
- **Commit point:** `fg gauntlet > /tmp/fg-gauntlet-run.log 2>&1` in the background (about 15 to 30 minutes), a
  peek at `/tmp/fg-gauntlet.verdict` at most every ten minutes. A leg that fails in its wave and passes its serial
  retry is a load flake only once its log shows nothing the unit touches.
- **The production tree:** `fg homepage` after the gauntlet of every unit that touches `src/meta/`, `src/boot/`,
  the build or a door into `meta-tools` (U1, U5, U7, U8 at least), then `fg build` to return to the dev tree. It is
  the only gate that restores an inspector, and replays class edits, on a production tree.
- **The docs gate:** `node /Users/davidedellacasa/code/Fizzygum-all/Fizzygum/buildSystem/check-doc-narration.js`.

---

## 10. Rejected alternatives (do not re-attempt)

Each row was built on the real build and looked at, unless it says "by reading". The pages:
`Fizzygum-tests/.scratch/inspector-columns/compare/`.

| Alternative | Why rejected |
|---|---|
| Today's columns, each level a full column, the window widening itself | Round 1: refused at every size once packages and categories exist; one click behaves differently by where the window stands. The owner: "typically widgets don't expand on their own" |
| The same full columns as a plain scrolling set, the editor in the row | Round 1: refused at every size (about 1900 px of content; names cut at rest; the code a sliver). It was about to be built when the owner's doubt stopped it |
| LIGHT columns (plain name lists, the filters and verbs folded behind "Filter…" and "Edit…") | Round 2 and round 3's V4. The owner after round 3: "I don't want the 'light' columns": the Methods / Fields / Inherited toggles stay fleshed out |
| Categories and method groups as HEADINGS inside a list instead of a list of their own | Round 2. The owner after it: packages "DISTINCT FROM CATEGORIES, then methods / fields, and the body (so basically one more column)". Measured in round 3: the extra list lowered the gesture counts |
| The body placed by the window's shape (beside when there is room, below otherwise) | Rounds 2 and 3 (V1). A rule that reads a size its own effect changes moved the body 23 times in one drag before it was made to read a fixed quantity; and the owner chose "always below" |
| The body's place baked into the set | The owner after round 3: "don't bake this". Round 4 proved the setting costs the set nothing |
| "all" chosen as a class's list opens (round 3's V3) | Reaching a method in another category cost 8 gestures where "not chosen" costs 3; the owner chose "all" first and NOT chosen |
| A "fields" category; categories "public", "private", "class side" | The owner after round 4: "'fields' might be redundant as it's a filter in the next column"; "I had in mind more smalltalk-like categories e.g. 'initialization' 'accessing'" |
| Text footers on every list | Round 5: 236 / 372 / 383 / 585 px, the package list off a laptop screen |
| One footer band for the whole set, acting on the list last pressed in | Round 5: all four lists whole, but it costs every list a row and must name in words the list it acts on. The owner: "for footers, go with 2", every list its own |
| A pop-out button in every column's header | Round 5: it cannot open anything the original has not first chosen, so it always changes the original first. The owner: "ignore the pop-out button in the column's header" |
| A fixed two-pane inspector whose drill opens another window | Round 1: refused on small screens (a phone holds one window), and the path is lost. It survives as an ASK ("Open in a new inspector"), never as the default |
| The typed ">" between trail buttons | Round 4 measured it: ink 5 px tall, 12.5 px above the buttons' centre line, 9 px of space on its left and 52 on its right. The owner: "wildy uncentered and I think they are too small" |
| The class as a chip wearing the accent | The owner after round 3: "it looks like some kind of toggle" |
| Dropping columns off the left when the set is full | An inspector with unsaved typing would vanish on its own (the earlier plan's §10, unchanged) |
| A hand-written `_reLayout` for the browser's four cells | The prototype's holder had one because a patch at load cannot make a stack of foreign widgets; the product composes division cells (the earlier plan's reframe 3). By reading |
| The trading splitter kept between the set's columns | A row at its content's width has no spare to trade (`maxDimsPuttingMyLeadingEdgeAt` answers nothing unless there is spare); a divider there sizes one column. By reading (RESEARCH Q3) |
| Package and source folder written into each class as a comment | A second copy of what the build's part and the file's folder already say, which can disagree (the earlier plan's §11). The part is read from the vault |
| A member's category held in a table beside the source | The owner's frame (2026-11-24): the metadata lives in the ordinary source as comments, a lint holds it, an edit in the inspector keeps it right. A side table drifts from the file it describes. By reading |

---

## 11. After this plan (not part of its done-ness)

- **Writing an edit back to a `.coffee` file** (D4). A class's record now keeps what a file needs but three things
  (§5.9's limits: a class's in-body description, the tail after its last member, the order of statics among
  members); a text regenerated from the record and a way out of the page (a downloaded file) is its own plan.
- **Duplicate and rename of a class; remove of a class the build ships** (D2, §4.4 says what each needs: a rewrite
  of the references to the class's own name; every other class's code that names it; the tests and the build that
  name it).
- **The class side**: a class's statics as a second face of its column, their comments and categories already
  kept (§5.9), edits of a static recorded.
- **The rest of the tree's categories**: the gate's budget, falling (D1).
- **One marker per category per class** (methods grouped in the file): a whole-tree reorder; 629 comment lines say
  "above" or "below" and would go stale (§4.3).
- **Finding by name**, once the owner has chosen among U10's candidates.
- **The final icons** of the four verbs (D11).
- **Senders and implementors**, as lists of member references (the earlier plan's §11).
- **The earlier plan's §11 items this plan does not touch**: views declared by a subject's own class; one
  footer-band mechanism; a touch-sized way to move every division stack's split.

---

## 12. What this plan overturns in `docs/plans/inspector-overhaul-plan.md`

Each is marked in that file, where it stands, "OVERTURNED 2026-11-26", with a pointer here. Until U1 and U2 land,
that plan's §5 is still the tool as built; each unit corrects THIS plan's §5 to the tool as built, and U11 leaves
both true.

| Its statement | What stands instead |
|---|---|
| Reframe 5: "Horizontal scrolling of the row is NOT free, and is not built… The row instead widens its window" | The row scrolls (reframe 3 here, §5.3); nothing widens itself |
| D4: a drill that does not fit widens the window, the inspectors narrowing past the desktop's edge | L1; U1 deletes `_widenMyWindowToFitNoSettle`, `_normalWidthOf` and what the trading needed |
| D9: the default window 760 × 528 | D5 here: 1000 × 808, clamped to the desktop |
| §10's row rejecting "A horizontally scrolling row" | Built (U1); the measurement that rejected it was of a plane that declared nothing |
| D16 and §11's table: a category is the source folder, a "family" a heading inside a list, each level a column beside the editor | L3, L4: a METHOD category is a list of its own between a class and its members; the editor stands below |
| §5.4 `InspectorRowWdgt` as the tool, with the rule of choice | §5.4 here: `InspectorBrowserWdgt` is the tool; the row is the set |
| §5.5: the class chip, `current: true` | §5.6 here: a plain button; `ChipWdgt` deleted |
| §5.6 and D7: Add… Duplicate… Rename… Remove as four text buttons under the member list | §5.7 here: the same four verbs as drawn icon buttons, on every list that has verbs |
| §5.10 and D11: the split's two controls, between the editor and its list | Unchanged in what they are (a divider for a mouse, a tab for a finger, one piece); they stand between the SET's columns, and size one column instead of trading. The split between the lists and the body below has the same two controls, turned a quarter (§5.4, decision D16) |

---

## 13. References

**In-repo (Fizzygum):** `docs/plans/inspector-overhaul-plan.md` (§0.3, §5, §8, §10, §11: the tool this plan
rebuilds, and the plan it overturns in part); `docs/architecture/` — `viewports-and-planes.md`, `layout.md`,
`input-and-gestures.md`, `widget-authoring-guidelines.md`, `lint-and-static-checks.md`,
`serialization-duplication-reference.md`, `visual-design-system.md`, `build-and-packaging.md`,
`layering-naming-convention.md`, `immutable-value-classes.md`, `constructor-and-parameter-conventions.md`,
`widget-citizenship.md`; `docs/BACKLOG.md`; `src/macros/CLAUDE.md` and `MACRO-PATTERNS.md`.

**In-repo (Fizzygum-tests):** `CLAUDE.md`, `DETERMINISM.md`, `.claude/skills/author-macro-test/`,
`scripts/inspector-churn-set.json` and `scripts/derive-inspector-churn-set.js`.

**The prototypes and the handoff (gitignored, authoring machine):**
`Fizzygum-tests/.scratch/inspector-columns/` — `DECISIONS.md` (the owner's words, what was measured, what was stood
in), `LEDGER.md`, `RESEARCH.txt` (the product's facts with their lines, as of 2026-11-25),
`compare/REPORT.txt`, `compare/index.html` and `round2.html` … `round5.html` (the pages the owner looked at),
`compare/COUNTS.md` … `COUNTS-5.md`, `compare/COLD-READ.txt`, `compare/probes/patches/` (`scroll.js` the set as a
plane; `shape6.js` the rest points; `round4.js` the body's place, the trail, the class button; `round5.js` the
footers, the menu row, Cmd-click), `compare/probes/hazards.js`.

**The spikes of 2026-11-26 (gitignored, authoring machine):**
`Fizzygum-tests/.scratch/inspector-browser-loop/spikes/` — `S1-REPORT.md` (the meta-object), `S2-REPORT.md` (the
tree's methods, the marker), `S3-REPORT.md` (class-level verbs, run), `S4-REPORT.md` and `PREDICTION.md` (the whole
shape as a prelude, and the suite under it), each with its probes beside it.

**The loop:** `Fizzygum-tests/.scratch/inspector-browser-loop/BRIEF.md`, `LEDGER.md`, `LOOP-PROMPT.md`.

**Memory** (`~/.claude/projects/-Users-davidedellacasa-code-Fizzygum-all/memory/`): inspector-scrollable-columns,
inspector-followups-2026-11, inspector-overhaul-plan, ask-before-commit-push, plan-on-fable-execute-on-opus,
touch-workable-controls, local-html-for-visual-reviews, clean-minimal-uniform-architecture,
ratchets-must-not-dictate-design, dont-let-recapture-churn-dictate-design, plans-must-be-fully-self-contained,
no-conclusions-before-evidence, loaded-file-trust-and-backlog-bar.

---

## BACKLOG detail (open items)

(Each unit files here what it leaves open, under a heading equal to its BACKLOG line's bold title.)

### The set can rest off a column edge after its edges move

Filed by U1 (2026-11-26). The set's scroll rests on a column's left edge after every stroke, notch, bar write and reveal
(`InspectorRowViewportWdgt`), but a change that MOVES the edges under a still offset leaves the offset where it was: a window
narrowed while the set stands at an end no column edge marks (its last column wider than the view), a divider's drag of a
column left of the view or at the far end, a view picked out of a column left of the view (the column falls to its bands'
width). The view then starts mid-column until the next notch or stroke rests it. Resting the offset at every arrange would
also stop a stroke mid-drag; the shape is a rest after such a change, asked of the fields the rest points are read from.

### A double-click on a member in the set's rightmost column can miss

Filed by U1 (2026-11-26), to close with U2. A double-click is recognised only when both clicks meet one widget
(`ActivePointerWdgt`, its double-click recogniser). While the body stands beside the lists (U1), a member's first click
adds its editor as a column; when the set must scroll to show it, the reveal moves the set under the pointer, and the
second click meets another widget: the member's value is not opened (in the default window, inspecting a rectangle and
double-clicking `constructor`, then `__super__` in the second column). Only a member list has a double-click action
(`inspectMemberValue`). U2 puts the body below the lists, so a member's first click adds no column and nothing scrolls;
U2's test of the body below proves the double-click, and U2's research weighs the residue (a choice that removes columns
lets the clamp slide the chooser).

### A trackpad's sideways swipe moves the set a column per wheel event

Filed by U1 (2026-11-26). A sideways notch moves the set one rest point whatever its size (`InspectorRowViewportWdgt._wheelTravelX`,
the sheet's precedent: `SimpleSpreadsheetWdgt.scrolledBy`). A trackpad's swipe is many small wheel events, so a gentle swipe
moves a column per event and races across the set. No notch accumulator exists in the house; it would serve the sheet too.

### Under a finger a tooltip comes up after a tap

Filed by U3 (2026-11-27; Review A's B2, verified in the code). A pointer entering a widget that carries a `toolTipMessage`
starts the tip's countdown (`ActivePointerWdgt._dispatchEventsFollowingMouseMove` → `Widget.startCountdownForBubbleHelp` →
`ToolTipWdgt.createInAWhileIfHandStillContainedInWidget`, a 500 ms timer), and a finger enters at its touch-down
(`processPointerDown` runs the move pipeline for the down's own position). The pending timer is cancelled only by a
widget added to the world (`Widget._addNoSettle` → `ToolTipWdgt.cancelAllScheduledToolTips`, which is why a press that
opens a prompt or a menu shows no tip) and by a world's reset; the touch-up's `_dissolveHoverStateOfTouchStroke` takes
down the tips SHOWN (`world.destroyToolTips`) and leaves the pending one. When it fires,
`ToolTipWdgt.createBubbleHelpIfHandStillOnWidget` asks only whether the widget is in the world and the hand's LAST
position inside it, which a lifted finger leaves there, so the tip opens over the control about 500 ms after the tap,
with no pointer on the glass, and stays until the next press. It is reached by a tap whose press adds nothing to the
world: a member list's Remove, any disabled verb (a disabled button does nothing with its press), and every other
tooltipped control of that kind. The band of verbs says its words only by tooltips (§5.7), so it shows there most.

### A member list keeps a band a dev-mode Destroy destroyed

Filed by U3 (2026-11-27; Review A's B3, verified in the code). In developer mode a click for a menu on a verb button
opens the hierarchy menu, which lists the band (`Widget.getHierarchyMenuWidgets`: nothing hides a `BandWdgt`), and every
widget's menu there ends in "Destroy" (`fullDestroy`). Destroyed, the band leaves the list and holds no buttons
(`Widget._destroyNoSettle` empties its children), but `MemberListWdgt.verbsBand` still names it: the list has no
`_reactToChildRemoved`. So a live list retains a destroyed widget, and every later choice, re-filter, reload or member
step asks it to reflect its verbs (`reflectVerbs` over no buttons, so nothing shows). `cutNoticeBand` is kept the same
way; the list's rebuild already reads both only while the list is their parent (`band?.parent is @`).

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] U1: the set of columns scrolls sideways and stops on a column, and the tool is a browser that owns the rule of choice; the window widening itself and the trading of width between columns deleted (§5.3, §5.4). — CLOSED 2026-11-26 (inspector-browser loop, U1): `InspectorBrowserWdgt`, `InspectorRowViewportWdgt`, `InspectorColumnDividerWdgt`, the set as a viewport's plane; the widening and the trade deleted (§6 U1, its Landed paragraph).
- [x] U2: the body below the lists as a setting of the browser, the where-you-are band, the default window, the class named by a plain button (§5.4 to §5.6, §5.13). — CLOSED 2026-11-27 (inspector-browser loop, U2): the body below, the trail, the class button, the clamped window, the held scroll (§6 U2, its Landed paragraph).
- [x] U3: every list its own footer of drawn icon buttons, each verb absent, disabled or enabled by one rule; the four marks are placeholders (§5.7). — CLOSED 2026-11-27 (inspector-browser loop, U3): the member lists' band of drawn icon buttons, one seat for what a member step changes; U3.2 (the object lists') PARKED (§6 U3, its Landed paragraph).
- [x] §11: packages, categories, families of members and comments in the inspector — a plan of its own, authored after U2 lands (owner, 2026-11-24) — CLOSED 2026-11-26: this plan is that plan (moved from the `plans/inspector-overhaul-plan.md` section; the work itself is this plan's units, each with its own line).

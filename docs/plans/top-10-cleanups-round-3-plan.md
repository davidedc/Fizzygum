# Top 10 code and architecture cleanups, round 3 — a survey, ordered by effort

> **PLAN ONLY. Written to be read and executed COLD by an LLM/engineer with ZERO prior context.**
> This is a SURVEY of ten candidate arcs, authored 2026-11-15 and ordered by effort, smallest
> first. Each item is a proposal with its evidence. Four of the ten need an owner decision before
> any code moves, and two more need a smaller ruling (marked in the table under "The list at a
> glance").
>
> **Relation to the earlier surveys.** `docs/plans/top-10-cleanups-plan.md` (2026-11-11) took the
> framework's structure and the build; nine of its ten items have landed and its §9 (icon shells)
> is kept open by the owner. `docs/plans/top-10-cleanups-round-2-plan.md` (2026-11-13) took the
> test harness, the reference set and the verification tooling; nine landed and its §10 (the
> reference set) was left out for now by the owner. Nothing here repeats either: this round was
> surveyed on the tree as they left it. Two items take up something those rounds named and did
> not queue (§6, §9), and say so.
>
> **STATUS (owner, 2026-11-15).** The owner approved §1, §2, §3, §5, §6, §8 and §10, and left §4,
> §7 and §9 for a later day (they stay on `docs/BACKLOG.md` and are not taken up until asked
> for). Ruled the same day: §3 pins the tools through npm (`npm ci`), not by vendoring; §5
> generates the pages and stops committing them; §8 shortens every item AND applies the
> 2026-11-11 bar to what is already filed; §10 lands and is pushed when every proof of its own
> plan (`docs/plans/fg-node-port-plan.md`) passes. An unattended `/loop`, launched by the owner,
> executes the approved items one unit at a time; its brief and ledger are local to the loop
> (`Fizzygum-tests/.scratch/cleanups-loop-3/`). An item's section gains a `**Landed <date>.**`
> paragraph as it lands, and the table's last column says where each stands. Landed: §1
> (2026-11-15).
>
> **Mandate.** Each item aims at ELIMINATING a duplicated mechanism or a dead one, not at making it
> easier to live with. Where an item stops short of elimination, it says why.
>
> **Baseline.** Every number below was measured on 2026-11-15 at Fizzygum `58885ce0` and
> Fizzygum-tests `12bbcbdb2` (both clean; the last gauntlet, 2026-11-14, green at 20 of 20 legs).
> Line numbers drift: the method name or the quoted code is the authority, and every item carries
> the command that re-measures it. Statements are labelled **MEASURED** (a command was run),
> **READ** (the code was read) or **UNVERIFIED** (a hypothesis the item's first step must test).

---

## 0. Orientation

**The project.** Fizzygum is a CoffeeScript GUI framework drawn on one `<canvas>`. Three sibling
git repos sit under an umbrella directory `Fizzygum-all/` (itself a small private repo of
workspace tooling): `Fizzygum/` (source, build, and the `fg` workflow wrapper), `Fizzygum-tests/`
(the SystemTest suite, the Automator harness and the headless rigs) and `Fizzygum-builds/`
(generated output). Read `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md` before touching
anything.

**Why a third survey.** The first two rounds removed the large structural debts, and the usual
instruments now read clean: `fg critique` reports every stink at its baseline, every method
ceiling at its count, zero unresolved sends, zero argument holes. A third list made by reading
the ratchets would be empty. This round looked for what the ratchets do not measure.

**Three reframes that shaped the list.**

1. **A zero that nothing holds does not stay zero.** The project gates what it has decided. What
   it has only measured drifts back. The hierarchy census was swept to zero on 2026-07-15 and
   reads eight today, because it is advisory (§1). The owner's bar for what enters the backlog
   was ruled on 2026-11-11 and is written in no file a session reads, so the backlog does not
   follow it (§8). The build's minifier is pinned in `package.json` and the build does not run
   that copy (§3).
2. **The recorder is gone; its shape is not.** Round 2 removed the recorded-test machinery. What
   remains is the layout that machinery needed: two files per test, metadata fields nothing
   reads, a page generator with a branch for recorded tests, three per-test switches that are
   now a function of "a test is playing", and comments that mark where recording would hook in
   (§1, §5, §6, §9).
3. **A mechanism that only a person can start has no proof that it starts.** The build and the
   gauntlet run 217 of the 265 tooling scripts. The other 48 are on-demand tools. One of them
   stopped working for three months unnoticed (the similar-code mirror, in `docs/BACKLOG.md`).
   The same holds for a source part that only the dev demo menu reaches (§4, §7).

**How the list was made.** `fg critique` and each census with `--full`; the stink baselines; a
census of `src/` by directory and by code lines; `buildSystem/lib/what-runs.js`'s run set
subtracted from its own list of tooling files; a read of the harness loader, the input event
family, the cache classes, `fg` and the build script; the shape of one test directory and of
the committed generated pages; byte and line counts of `docs/BACKLOG.md`. Each candidate was
then checked against `docs/BACKLOG.md`, the active plans and `docs/archive/INDEX.md`, and
dropped if an active plan already owns it (§12) or if earlier case law bounds it (§13).

**Order.** Effort, smallest first, so the cheap items can be taken without reading the expensive
ones. Effort means the whole item including its verification runs (one gauntlet is about 18
minutes). The figures are ESTIMATES in working days; none is measured, and two items within half
a day of each other could swap. The table's "Payoff rank" keeps the other ordering: removed
mechanism, weighted by confidence in the evidence, divided by cost and risk (1 is the best
return).

---

## 0.5 Cold-execution protocol

1. **This document is a menu, not a script.** Pick ONE item. Items are independent except where
   one names a dependency (§9 is easier after §5; §10 should come after every other item that
   edits `fg`).
2. **Re-measure first.** Run the item's re-measure command and compare with the numbers here. If
   they differ materially, the tree moved: re-read the code before trusting the fix shape.
3. **Items marked "owner decision first" stop at the decision.** Present the evidence and the
   options; do not start the code.
4. **An item that is taken up becomes its own plan** in `docs/plans/` when it is more than a
   day's work (§7, §9, §10), following `docs/README.md`'s filing rules; its line in
   `docs/BACKLOG.md` then points at the new plan and this survey's line for it is removed.
5. **Verify with the shared protocol in §14**, plus whatever the item adds.
6. **Never commit or push without the owner's approval.** Present a summary and the proposed
   commit message and wait.
7. **If a long operation is running in another session** (`cat /tmp/fg-*.verdict` shows
   `RUNNING`), do not edit sources or run a build: a running `fg` operation owns its inputs.
8. **An item that touches `tests/` in bulk (§5, §9) is a parse-and-re-emit job, never a blanket
   regex edit**, and its proof is that every macro source and every reference's bytes are
   identical before and after.

---

## The list at a glance

Ordered by effort, smallest first. Effort is an estimate in working days for the whole item.
The fourth column says what is removed, then says the item again in plain words for a reader
who has never seen the code. The fifth says why the change is worth making and what it costs,
as one would explain it to a five-year-old; each item's own section has the precise version.

| # | Cleanup | Effort (estimate) | What goes away, and in plain words | Why, and the trade-offs (ELI5) | Pixel risk | Owner decision first | Payoff rank | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | Overrides that override nothing | ½ day | 8 methods identical to the one they inherit, 2 empty subclasses, 6 comments about a removed recorder; the provable part of an advisory count becomes a build gate. **In plain words:** some classes re-declare a method exactly as their parent already has it. The copies were cleaned out once and grew back because nothing checks. Remove them and add the check. | **Why:** if the same recipe is written on two pages of the cookbook, one day somebody fixes one page and forgets the other. Keep one page, and have the build refuse a second. **Trade-offs:** the new check adds about a second to every build; a copy that someone keeps on purpose needs a one-line note saying why; a few inspector screenshots may show fewer rows. | Low (inspector member lists) | No | 3 | Landed 2026-11-15 (§1, "Landed") |
| 2 | The LRU cache on a `Map` | ½ day | A linked-list class, a 24-hour expiry no caller varies, 3 of the 8 remaining wall-clock reads. **In plain words:** the text caches keep their entries in a hand-built list and stamp each one with the time of day. JavaScript's own `Map` already remembers insertion order, so the list and the clock are not needed. | **Why:** the cache is a toy box that throws out the toy nobody has touched for longest. Today it also looks at a clock every time a toy is touched, so it can throw out toys left alone for a whole day, which never matters. A box that just remembers the order is enough, and the code that draws text stops looking at clocks. **Trade-offs:** this box is opened thousands of times a second, so the new one must be timed to be sure it is not slower; and a toy left for a day is no longer thrown out (still correct: the same text always measures the same). | None expected (hot path: measure speed) | No | 8 | ⛔ Parked 2026-11-15 on a speed trade (§2, "OWNER DECISION") |
| 3 | One pinned toolchain | ½ to 1 day | Two global installs, a version nobody chose in the production artifact, two unused pinned packages, a second copy of an analyzer. **In plain words:** the build shrinks its output with whatever version of a tool happens to be installed on the machine, while the version the project wrote down sits unused. Use the written-down one. | **Why:** a cake recipe that says "use whatever oven is in the house" gives a different cake in every house, and nobody can tell whether the cake changed or the oven did. Write the oven down and use that one. **Trade-offs:** a fresh machine runs one install command in this folder before it can build; upgrading the tool becomes something a person does on purpose, never something that happens by itself. | None (byte-identical trees expected) | No | 1 | Approved by the owner (2026-11-15); queued |
| 4 | The experimental patch-programming part | ½ to 1 day (deletion) | 6 classes (495 lines) that production never ships, that no test builds, and that only three rows of the dev demo menu can create; the stated reason one base class is held in core. **In plain words:** a folder labelled "unfinished" holds three building blocks for wiring widgets together: a splitter, a text-comparing box and a find-and-replace box. No test uses any of them, a user of the shipped product cannot reach them, and the splitter's job is now done by every widget on its own. Finish them or delete them. | **Why:** it is a half-built toy left in the middle of the room. Nobody plays with it, but everybody has to step around it and dust it whenever the room is tidied. Finish it or put it away. **Trade-offs:** putting it away loses the half-done work from the tree (git still has it) and its three rows in the dev demo menu; no test changes. Finishing the two text boxes instead is real feature work, not tidying, and only worth it if they are wanted in the product. | None expected (no test builds any of the six or opens their menu) | Yes | 5 | Left for a later day by the owner (2026-11-15) |
| 5 | Visualisation pages are generated, not committed | 1 day | 375 committed generated files (4.2 MB), the build gate that exists to catch them going stale, the generator's branches for recorded tests and native references. **In plain words:** each test has a web page describing it, made by a script and then saved in git, with a check that fails when the saved copy falls behind. Make the page when it is wanted and stop saving it. | **Why:** keeping a photo of every drawing means taking a new photo each time a drawing changes, and somebody has to keep checking that no photo is old. Twice the photos were old. Look at the drawing instead: make the page when you want to see it. **Trade-offs:** the pages can no longer be opened straight from the repository without running a command first; making all of them takes some seconds that have not been measured yet. | None | Yes | 7 | Approved by the owner (2026-11-15); queued |
| 6 | Three test switches become one question | 1 day | Three class statics, their reset, and a call from the shipping teardown into the test harness. **In plain words:** three on/off switches are flipped on when a test starts and off when it ends. They always agree with "a test is running", which the code can already ask. Ask that and drop the switches. | **Why:** three light switches are always flipped together when the game starts and together when it ends. One sign that says "game on" tells you the same thing, and nobody can forget a switch. It also means the everyday code no longer has to reach into the test kit to flip them back. **Trade-offs:** no switch can be flipped on its own any more (nothing does that today); and the instant between "old world gone" and "test started" has to be measured first, because a label built in that instant could come out different. | Low (the start cycle) | No | 4 | Approved by the owner (2026-11-15); queued |
| 7 | On-demand tools: one roster, each proven to start | 1 to 2 days | A tool nothing references, nine profiling scripts kept under `docs/`, a second front door (28 npm scripts) beside `fg`. **In plain words:** about fifty helper scripts are only ever started by hand, so nothing notices when one breaks. Keep one list of them, check that each still starts, and delete the ones nobody can reach. | **Why:** tools kept in a drawer and never tried may turn out broken on the very day you need them; one already sat broken for three months. Keep a list of what is in the drawer and press each tool's "on" button whenever the big check runs. **Trade-offs:** the big check gets a little longer; "it switches on" is not the same as "it still works properly"; and throwing a tool away risks losing one that somebody uses twice a year. | None | Partly (which tools go) | 9 | Left for a later day by the owner (2026-11-15) |
| 8 | The backlog is an index again | 1 day | About 105 KB that cannot be read in one pass; items the owner's own bar keeps out. **In plain words:** the list of open work says it is only an index, but many entries are half a page long, and it has grown past what the tools can read at once. Shorten each entry to a line or two and move the detail to the plan that owns it. | **Why:** a to-do list so long that nobody reads to the end stops working as a list: the same thing gets written down twice, and the important things hide among the small ones. Give each thing a line or two and keep its long story in the folder it belongs to. **Trade-offs:** reading an item's whole story takes one more hop to another file; and moving 212 items risks dropping a sentence, so a script has to check that every sentence landed somewhere. | None | Yes (the bar applies to what is already filed) | 6 | Approved by the owner (2026-11-15); queued |
| 9 | A test is one file | 2 to 3 days | 389 files, a second script load per test, a load of every test's metadata before any run, fields nothing reads. **In plain words:** every test is split across two files for a reason that no longer exists, and before running anything the test page loads a file for every test in the suite. One file per test, and a generated list that says which tests exist. | **Why:** every test keeps its instructions in one envelope and its name tag in another, and before any test starts, the page opens the name-tag envelope of every test in the building. One envelope per test, and one printed list of who is here. **Trade-offs:** every tool that reads tests has to learn the new shape in the same change (19 files name the old one); 778 files change in one commit; and the printed list becomes something a test run cannot do without. | None (macro sources byte-identical) | Yes (rename or fold; this item recommends fold) | 2 | Left for a later day by the owner (2026-11-15) |
| 10 | `fg` in the toolchain's language | 4 to 5 days | 856 lines of bash run by a 2007 shell, 45 hops from bash into Node, a table printed by Node for bash to parse. **In plain words:** the command that runs every check is a long shell script, executed by the old shell macOS ships, and it calls into JavaScript dozens of times. Write it in JavaScript like the rest of the tooling. | **Why:** the one who marks everybody's homework writes in a different language from everybody else, so none of the class's spell-checkers can read the marker's own notes, and that old dialect has already hidden mistakes. Have the marker write in the class's language. **Trade-offs:** it is a rewrite of the very thing that says "safe to commit", so a slip here is the expensive kind; it takes about a week and adds no feature; and shell is naturally good at starting and stopping programs, which takes more care to do as well in JavaScript. | None | No | 10 | Approved by the owner (2026-11-15); queued |

---

## §1. Overrides that override nothing

**Effort.** About half a day: ten small deletions, one census facet turned into a gate with its
bite proof, one gauntlet.

**Evidence.**
- MEASURED: `node buildSystem/census-hierarchy-duplication.js --full` lists 8
  `IDENTICAL-TO-INHERITED` methods: `FrameWdgt.add`, `ToolPanelWdgt.add` and
  `VerticalStackPanelWdgt.add` (each equal to `Widget.add`); `enableDragsDropsAndEditing` and
  `disableDragsDropsAndEditing` on `FrameWdgt` and on `ViewportWdgt` (each equal to `Widget`'s);
  `SimpleTextWdgt.colloquialName` (equal to `StringWdgt`'s).
- READ: seven of the eight are the public settle wrapper, for example
  `add: (aWdgt, opts = {}) -> @_settleLayoutsAfter => @_addNoSettle aWdgt, opts`. What the
  subclass really overrides is the `_…NoSettle` core, which the inherited wrapper already
  reaches by late binding.
- READ: `docs/archive/duplication-triage-2026-07-15-hierarchy-round4.md` took this count from 10
  to 0 on 2026-07-15 and stated the rule: "the parent owns the ONE public settle-wrapper;
  subclasses override only cores". The census is advisory (it runs under `fg critique`, which
  gates nothing), so nothing held the zero.
- MEASURED: none of the eight bodies contains `super`.
- READ: the census's own header forbids promoting it ("WHY THIS CAN NEVER BE A GATE … do not
  'promote' it"). Its reason is specific: a `super` binds to the class whose body it is written
  in, so the same text in a subclass and in its superclass can call different methods, and equal
  text is then no proof of equal dispatch. The reason does not reach a body with no `super` in
  it.
- MEASURED: five class files hold a class line and nothing else. Two of them add neither
  behaviour nor meaning: `InputDOMElementForVirtualKeyboardKeydownInputEvent extends
  KeydownInputEvent` and `InputDOMElementForVirtualKeyboardKeyupInputEvent extends
  KeyupInputEvent` (the same event, named after the DOM element it arrived through). Each is
  named at one site (`BrowserInputBridge`) and by no test, rig or build script. Of the other
  three, `CopyInputEvent` stays (READ: having no `processEvent` is its behaviour, and the macro
  toolkit passes the class as a value); `MenuAppearance` and `CFDegreesConverterIconAppearance`
  were not examined.
- READ: `KeyboardInputEvent.fromBrowserEvent` builds `new @ …`, so an instance of the empty
  subclass differs from its parent's only in its class name, and no file under
  `src/events-input/` reads a class name.
- MEASURED: six comments read `PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED` (five under
  `src/events-input/`, one in `Widget.coffee`). The recorder was removed
  (`Fizzygum-tests/CLAUDE.md`, "the old test recorder … has been removed").

**Why it matters.** Each copy is a second place to edit when the wrapper changes, and a reader
of `FrameWdgt.add` reasonably assumes it differs from `Widget.add`. The larger point is the
regrowth: a count the project drove to zero and wrote a rule about is at eight four months
later.

**Fix shape.**
- Delete the eight overrides. A comment that documents the subclass's behaviour (`FrameWdgt.add`
  explains `opts.notContent`) moves to the `_…NoSettle` core it describes.
- The bridge pushes `KeydownInputEvent.fromBrowserEvent event` and
  `KeyupInputEvent.fromBrowserEvent event`; the two empty classes go. The keyup class's comment
  (a soft-keyboard release must dispatch `processKeyUp`, or every keystroke doubles) moves to
  the listener that makes the choice.
- Delete the six recorder markers.
- **The check that holds the zero.** The census is NOT promoted as it stands (its header says
  why, above). It gains a `--gate` mode that judges only the subset its objection cannot reach:
  an override whose signature and body equal the nearest inherited definition's AND whose body
  holds no `super`. Such an override is the same code with nothing bound to its class, so
  deleting it cannot change dispatch. That subset is gated at zero: a row in
  `buildSystem/gates.js`, a named rule (`buildSystem/lib/gate-rules.js`) and a self-test that
  plants one, exactly as `census-widget-conformance.js` gates two of its facets and leaves the
  rest advisory. Every other finding (a body with `super`, `JUST-SENDS-SUPER`) stays advisory
  under `fg critique`.
- One exception needs a sanction: code that reads whether a prototype OWNS a member (the
  inspector's own-member list; the menu sweep derives its contributors from which prototypes own
  `addWidgetSpecificMenuEntries`). An override kept identical on purpose, as such a marker,
  states it in a comment the gate reads (`# identical-override-sanctioned: <why>`), the
  pattern `# nosettle-sanctioned:` already sets.
- It runs in the build, not as a new `fg` verb and not only under `fg critique`: a verb is one
  more check only a person starts (§7), and `fg critique` is where the count has been printed
  since July while it grew back. Cost: about one second a build.
- No check is added for the other two kinds. Five empty class files with three of them
  deliberate is a judgement, not a rule; the recorder comment is a single phrase with nothing
  left to copy it from.

**Risk.** The gate's subset is sound for dispatch, and the eight findings are all inside it;
still read each of the eight before deleting it, since the census is a text comparison.
`FrameWdgt` sits exactly at its method
ceiling (173), so the count drops and the ceiling is banked in the same change
(`check-complexity-ratchets.js`). An object inspector lists a class's own members, so a test
that opens one on a frame or a viewport may show three fewer rows: the round-4 triage removed
ten such methods with zero recaptures, which is a precedent, not a proof.

**First step.** For each of the eight, open the override and the definition the census names
beside it, and confirm no class between them defines the method. Then delete one (`ToolPanelWdgt.add`)
and run `fg presuite`.

**Re-measure.**
`cd Fizzygum && node buildSystem/census-hierarchy-duplication.js --full | grep -A10 'IDENTICAL-TO-INHERITED ('`
and `grep -rn "RECORDING IF NEEDED" Fizzygum/src | wc -l`.

**Landed 2026-11-15.** Nine overrides are gone, each read first: no class between it and the
definition it equals defines the member, and none holds `super`. Eight are the census's; the
ninth, `DocumentShortcutWdgt._reactToChildDropped`, is an empty body identical to
`ShortcutWdgt`'s, which the census used to skip ("two empty bodies — nothing to say") and the gate
found once it judged empty bodies too. The comments that described the subclass moved to the core
they describe (`FrameWdgt._addNoSettle` now documents `opts.notContent`,
`VerticalStackPanelWdgt._addNoSettle` `opts.positionInPlane`, and the frame's two edit-mode cores
say that Widget's wrappers reach them). `BrowserInputBridge` pushes
`KeydownInputEvent`/`KeyupInputEvent` and the two empty classes are deleted (the keyup class's
comment is on the keyup listener); the six recorder markers are deleted. `FrameWdgt`'s method
ceiling is banked at 170. The gate is `census-hierarchy-duplication.js --gate`, the LAST row of
`gates.js` (row 35, so no row number in the lint index moved): rule `IDENTICAL_OVERRIDE`, at zero,
judging only an override with no `super` in its body (read on the bare view) whose signature and
body equal the NEAREST definition of its name, with `# identical-override-sanctioned: <why>` on or
directly above the header for a copy whose ownership is read (none today). Making it a gate
tightened the census's reading, in both modes: a signature is the parameter list read to its
balanced parenthesis plus the arrow (`->`/`=>`), and one it cannot read whole equals nothing (the
old pattern read any list holding a `)` as empty, so `(w = @top()) -> @f w` and `-> @f w` compared
equal); the nearest definition is the nearest class defining the NAME, a field included; two empty
bodies count. Its self-test plants a plain, an empty, a default-holding-a-call, a
`super`-only-in-a-string, a reasonless-marker and a harness override (each fires), and in the
control a `super`-holding one, two sanctioned ones, a different list, a default against no list, a
different arrow and a field in a class between (none fires); its pass line names no count. The two
summary lines `fg critique` prints are unchanged. One finding while building:
`check-layering-selftest.js` planted renames on the deleted `add:` overrides to empty
`WRAPPER_EXCLUDED`; it now renames the four widget classes that still define `add:` (Widget's
the one settling one) and still sees `G_STALE_WRAPPER_EXCLUDED` fire. Prose naming a deleted member
was corrected (one src comment, two lines of `src/macros/MACRO-PATTERNS.md`, ten lines of test
prose, whose six pages were regenerated and pass `check-visualisations --strict`; the end-of-cycle
layout prelude's comment), as were the docs that said the census can never gate. Evidence: a
resolution map of every class before and after (547 → 545 classes) changed only where explained —
the two classes' 18 lines; the frame cores' and three `processEvent`s' comment-only text; and
`initVirtualKeyboard`, whose old hash comes back when its two class names and its two added
comment lines are undone. Every deleted member resolves, on every class, to a function with the
same hash as before. A probe dispatching a keydown and a keyup on the virtual-keyboard input saw
the same `processEvent` and fields before and after.
No pixel moved and no reference was recaptured: the presuite (389 of 389, the paint audit and
the dpr-2 rider), the gauntlet (20 of 20 legs, its dpr-2, WebKit and finger legs included, no
serial retry) and `fg homepage` all passed.

---

## §2. The LRU cache on a `Map`

**Effort.** About half a day, most of it the speed measurement.

**Evidence.**
- READ: `src/basic-data-structures/LRUCache.coffee` (46 code lines) keeps a plain-object hash of
  nodes and a `DoubleLinkedList` (26 code lines) for recency. `DoubleLinkedList` has no other
  user.
- MEASURED: eight instances exist — seven built in `WorldWdgt`'s constructor (the text
  measurement, paragraph, wrapping and back-buffer caches) and `Color._cache`, a class static (the
  colour intern table; a first count of seven missed it) — and every one passes the same second
  argument, `1000*60*60*24`: a 24-hour maximum age.
- READ: the age is enforced by reading `Date.now()` in `set`, `_refreshNode` and
  `_isExpiredNode`, so every cache hit reads the wall clock.
- MEASURED: `node buildSystem/check-stinks.js --list clock-read` counts 8 sites at baseline 8;
  three of them are these.
- MEASURED: no call site passes `set`'s third parameter, `onDispose`. One wrapper forwards it
  (`swCanvasInstallPoisonedKeyRecorder` in `SWCanvasElement-extensions.coffee`).
- READ: the cached values are functions of their key (a text and a font; a content key for a
  back buffer), so an entry does not go stale with time.
- MEASURED (2026-11-15, the owner asked whether a sibling repository uses this cache): none
  does. The SWCanvas text demo (`examples/text-lru-atlas-demo.html`) uses a DIFFERENT class,
  `AtlasLRU`, whose source is `BitmapText.js/src/utils/AtlasLRU.js` (vendored byte-identical into
  SWCanvas, and so present inside Fizzygum's vendored `swcanvas.js`). It already keeps a `Map`,
  and no Fizzygum source instantiates it. This item changes nothing there.

**Why it matters.** The determinism contract says render and layout code must not depend on the
wall clock (`Fizzygum-tests/DETERMINISM.md`). These three reads cannot change a result inside a
24-hour session, which is why they are tolerated; they are still three of the eight exceptions
the stink carries, on the hottest read path of text layout, for an expiry nobody asked for.

**Fix shape.** `LRUCache` holds one `Map`. `get` deletes and re-sets the key to refresh it;
`set` at capacity evicts `map.keys().next().value`. `maxAge`, `lastVisitTime`, `onDispose` and
`DoubleLinkedList.coffee` go. The public surface (`get`, `set`, `has`, `remove`, `reset`,
`keys`, `size`) stays, so the 30 call sites and the SWCanvas wrapper do not change. The
`clock-read` baseline drops from 8 to 5.

**Risk.** Speed, on a hot path: measure it as the first survey's case law says (§13), with the
real methods on two builds, runs alternating. Key identity: an object hash turns every key into
a string, so the number `5` and the text `"5"` are one entry today and two in a `Map`.
UNVERIFIED that no cache is written with one form and read with the other (the keys are
`hashOfString` numbers or prefixed strings such as `"fontBox-" + font`). `WorldInventory`
declares these caches bounded because the class evicts at capacity, which stays true.

**First step.** A prelude that wraps `LRUCache.prototype.get` and `set` and records, per cache,
the `typeof` of every key over one suite run. One type per cache is the go-ahead.

**Re-measure.**
`grep -rn "new LRUCache" Fizzygum/src --include='*.coffee'` (eight lines, one age) and
`cd Fizzygum && node buildSystem/check-stinks.js --list clock-read | head -10`.

**OWNER DECISION (OPEN, raised 2026-11-15 by the loop).** The `Map` cache was built, proven
equivalent and timed, and is PARKED on a speed trade the plan's own rule leaves to the owner
("land only if no case is slower"). A person using Fizzygum sees and feels nothing either way: the
choice is between a few hundred nanoseconds on a rare path and keeping the linked list.
- What was measured. The first step: each of the eight caches is asked with ONE kind of key over a
  whole suite (two by number, six by string), so a `Map` takes a key as given. The old class (from
  HEAD) and the new one, driven by the same 200,000 and 1,000,000 random operations, agreed on every
  return, size, key set and evicted key. No caller reads `keys()` or a return of `set`/`remove`/
  `reset`. A resolution map changed only `LRUCache`'s lines and dropped `DoubleLinkedList`'s.
- Shape 1, a fresh `keys().next()` per eviction (median ns per call over three alternating runs of
  the real methods, HEAD's build → the change's): hit by string key 60 → 42.5, hit by number key
  62.5 → 35, miss then set 77.5 → 72.5, **eviction 100 → 292.5 (×2.9)**. A `Map` keeps a deleted
  entry's slot until it compacts, and an LRU deletes at the front, so each fresh iterator steps over
  every hole earlier evictions left.
- Shape 2, one key iterator kept for the cache's life, was faster everywhere (eviction 117.5 → 62.5)
  and is RULED OUT: V8 moves an iterator onto a `Map`'s current table only when it is advanced, so it
  pins every superseded table — about 40 bytes per hit, released only by the next eviction
  (measured with the cache kept live: 6.13 MB flat without it, 10.09 MB after 100,000 hits and
  14.05 MB after 200,000 with it). The documented interactive profile shows the back-buffer cache at
  175–189 of 1000 entries with no eviction, so that growth would be unbounded in a real session.
- The options. (a) Shape 1: the plan's shape as written; `DoubleLinkedList`, the expiry and three
  clock reads go; an eviction costs about 190 ns more, and it only ever follows a miss that does the
  real work (a text measurement or a back-buffer render, microseconds and up). (b) Keep the linked
  list and remove only the expiry and its clock reads (`maxAge`, `lastVisitTime`, `onDispose`):
  `clock-read` still falls to 5, `DoubleLinkedList` stays, speed unmeasured. (c) A third shape (an
  iterator kept only across back-to-back evictions, or a periodic compaction): unmeasured, and it
  needs the equivalence, timing and retention probes again.
- Recommendation: (a). Its slower case is the rare one and is dwarfed by the miss it follows; its
  faster cases are the hot ones.
- The work is kept: `Fizzygum-tests/.scratch/cleanups-loop-3/u2-lru-map/` — `PARKED-Fizzygum.patch`
  (shape 2 with its docs, applies to `4921a02b`), `LRUCache.shape1.coffee` (shape 1's class), the
  probes (`old-vs-new.js`, `timing-probe.js`, `cross-build-timing.sh`, `lru-keytype-prelude.js`)
  and `PREP.md`. Taking it up again: the review's notes are in `PREP.md` — among them that
  `boot/dependencies-finding.coffee`'s REQUIRES hint has no other user that needs it at class
  definition time (`Color._cache` builds an `LRUCache` while classes are being defined; the harness's
  hints are read only inside methods), so its comment's example is the one to reword.

---

## §3. One pinned toolchain

**Effort.** Half a day to a day: four lines of the build script, one loader, the setup
paragraph of two instruction files, and a fingerprint of three profiles.

**Evidence.**
- READ: `build_it_please.sh` checks for `coffee` and `terser` with `command -v` and runs them
  from `PATH` (grep `coffee -b -c` and `terser --compress`): the boot bundle, the boot scripts
  and the production image `js/pre-compiled-min.js` are compiled and minified by whatever is
  installed globally. `Fizzygum/CLAUDE.md` states it as the rule: "Prerequisites are installed
  globally, not via `npm`".
- MEASURED: `package.json` lists `coffeescript ^2.7.0` and `terser ^5.0.0` as devDependencies.
  No script in `buildSystem/`, `fg`, the build scripts or `Fizzygum-tests/scripts/` requires
  either package or runs its `node_modules/.bin` entry.
- MEASURED on this machine: the global `terser` is 5.39.1; `node_modules/terser` is 5.0.0. The
  global `coffee` is 2.7.0, equal to the pinned one.
- READ: `buildSystem/lib/cognitive-complexity.js` goes out of its way to find the GLOBAL
  CoffeeScript package (through the `coffee` symlink on `PATH`, or Node's global prefix), passes
  over `node_modules/.bin/coffee`, and refuses any version but 2.7.0, because complexity scores
  are specific to a compiler version.
- MEASURED: the complexity analyzer exists twice: vendored
  (`vendor/coffeescript-cognitive-complexity/`, loaded by the gate) and as a devDependency
  (`fg cc` runs `node_modules/.bin/coffee-cc`).
- READ: the static gates and the browser share one compiler,
  `vendor/coffeescript/fizzygum-coffeescript-min.js` (`buildSystem/lib/meta-compiler.js`). That
  half is already right.
- UNVERIFIED: why the two tools are global. No architecture doc gives a reason.

**Why it matters.** The production artifact's bytes depend on a version nobody chose. `fg
fingerprint` compares build trees byte by byte to prove a packaging change is neutral, and a
global upgrade between the two builds would read as a difference in every minified file. The
complexity gate already had to write a version check and a search of the global install to
protect itself from this.

**Fix shape.** Pin `terser` to the exact version production is built with today and
`coffeescript` to 2.7.0, in `package.json` and its lockfile. The build runs
`node_modules/.bin/coffee` and `node_modules/.bin/terser`, and says "run `npm ci`" when they are
missing. `lib/cognitive-complexity.js` requires the pinned package and drops its search of the
global install. One copy of the analyzer stays (the vendored one, which the gate already
loads), and `fg cc` runs it. `fswatch` stays global: it is a system tool used by one optional
script.

**Risk.** A different minifier version changes bytes, so pin to the version in use and prove it
with `fg fingerprint`. Setup changes for a bare clone: `npm ci` in `Fizzygum/` replaces two
global installs (the tests repo already needs `npm i`). The pinned-version check for complexity
scores stays; only where it looks changes.

**Ruled 2026-11-15 (owner).** npm-pinned: exact versions in `package.json` and its lockfile, the
build runs `node_modules/.bin`, and a fresh machine runs `npm ci` in `Fizzygum/`. Not vendored.

**First step.** Put `node_modules/.bin` (with `terser` at the global's version) first on `PATH`
for one `fg fingerprint dev`, one `homepage` and one `lean`: three identical trees are the
proof that the switch itself moves nothing.

**Re-measure.**
`terser --version; node -p 'require("./node_modules/terser/package.json").version'` from
`Fizzygum/`, and `grep -n -E '(coffee|terser) -' Fizzygum/build_it_please.sh`.

---

## §4. The experimental patch-programming part: finish it or delete it

**Effort.** Half a day to a day for deletion. Finishing it is a feature, not a cleanup, and is
not estimated here.

**What the part is.** "Patch programming" is how a Fizzygum user wires widgets together so that
one drives another: a slider drives a number, a palette drives a colour. A patch NODE is a box on
that wiring that computes something from what flows into it. One node ships to users:
`CalculatingPatchNodeWdgt`, a formula box, in the `authoring` part. This part holds three more
building blocks, none of them shipped:
- **The fanout** (`FanoutWdgt`, its four `FanoutPinWdgt`s and their two appearances): a
  splitter. One value comes in, and each of its four pins can be wired to a different target. It
  was written when a widget could hold only ONE wire, as the only way to drive several things
  from one source.
- **`DiffingPatchNodeWdgt`**: two texts in, their differences out.
- **`RegexSubstitutionPatchNodeWdgt`**: a text, a pattern and a replacement in; the substituted
  text out.

**Evidence.**
- READ: the splitter's job is done without it. `ControllerWdgt.wireTo` ADDS a wire to a list
  (`@wires`), and its comment says so: "a controller drives as many things as it is connected
  to, so fan-out stops needing FanoutWdgt". `SystemTest_macroPaletteFansOutAndDisconnects`
  proves it: one palette drives a panel and a rectangle, with no fanout in the test.
- MEASURED: no test's macro builds any of the six classes or opens the menu that creates them.
  (One test file names `FanoutWdgt`, in the prose describing what replaced it.)
- MEASURED: the only way to create one is the dev-mode demo menu's "Patch programming" submenu
  (three of its five rows), which lives in the `demos` part. The production profile lists
  neither `demos` nor this part, so a user of the shipped product can neither make one nor
  load one.
- MEASURED (`fg hypopart src/patch-programming-experimental`): 6 files, 19.1 KB of source; three
  references into the part from outside it, all in `DemoMenus`; no class outside it inherits
  from it.
- MEASURED: `PatchNodeWdgt` has three subclasses: the two text nodes here, and the shipped
  `CalculatingPatchNodeWdgt`.
- UNVERIFIED: what exactly is unfinished. The partition file says the part is; this survey found
  no list of what is missing.
- READ: `buildSystem/parts.json` describes the part `patch-programming-experimental` as "the
  unfinished half of patch programming: fanout, diffing, regex-substitution nodes".
- MEASURED: six classes, 342 code lines (`FanoutWdgt`, `FanoutPinWdgt`, their two appearances,
  `DiffingPatchNodeWdgt`, `RegexSubstitutionPatchNodeWdgt`).
- MEASURED: no file under `buildSystem/profiles/` names the part. READ: `dev` takes everything;
  `homepage` and `lean` list their parts and omit it, so production has never shipped it.
- MEASURED: outside the part, code that names its classes is `DemoMenus` only (three `create…`
  methods and three rows of the dev demo menu). Five core files name them in comments
  (`Theme`, `TextAreaWdgt`, `PatchNodeWdgt`, `ControllerWdgt`, `WireSpec`).
- MEASURED: three rigs carry the part: the menu sweep keeps a root for a fanout's pin, the
  staleness census opens a fanout window, and the pin sweep resolves every class's pins, these
  six included.
- READ: `docs/BACKLOG.md` records that fan-out no longer needs the class ("`FanoutWdgt` is now a
  visual affordance over a capability every citizen has, rather than the only way to fan out"),
  that a dead-code prune is blocked by it ("⚠ FanoutPin uses `_paintRoundedSquareBadge`"), and
  that this part is the stated reason `PatchNodeWdgt` stays in core ("the EAGER
  `patch-programming-experimental` part EXTENDS `PatchNodeWdgt`, and an eager part cannot derive
  from a lazy one").

**Why it matters.** The first survey's §3 made the same case for the video player: a part no
user reaches and almost no gate exercises still costs every rename, every theme change and
every sweep fixture, and here it also pins a base class in the core image.

**What keeping it as it is costs.** The six classes are held to every gate, so each convention
sweep, rename and theme change has to carry them (the pin sweep's header records an analysis
that wrongly accused `DiffingPatchNodeWdgt` of two defects). Two rigs keep fixtures for them.
And because this part is loaded eagerly and extends `PatchNodeWdgt`, that base class has to sit
in the core image every production user downloads, although its one shipped subclass loads
lazily.

**Options (the owner's).**
- (a) Delete all six, with the three demo rows and the two rig fixtures. The splitter is
  redundant, and the two text nodes are unreached and untested. Git keeps the code.
- (b) Delete the fanout family (four classes) and leave the two text nodes where they are. This
  removes the redundant piece and keeps the limbo for the other two.
- (c) Delete the fanout family and FINISH the two text nodes: a test each, a place in the
  `authoring` part beside the calculating node, and a way for a user to create them. This is
  feature work.
- (d) Leave everything.

**Recommendation.** The fanout family goes under every option but (d): its reason to exist is
gone. For the two text nodes the question is a product one that only the owner can answer: are a
text-comparing box and a find-and-replace box wanted in the product? If yes, (c). If not, or not
now, (a).

**Risk.** No test builds any of the six, so no reference is expected to move; a full suite run
confirms it. The menu sweep's root for a fanout pin and the staleness census's fanout window go
with the classes, and the sweep's coverage number drops with them (it is breadth, not a
ratchet). A world file saved in a dev build with one of these on the desktop no longer loads
its class. `docs/BACKLOG.md` forbids re-attempting the move of `PatchNodeWdgt` out of core "for
the bytes": this item does not make that move. Under (a) the base would have one subclass left,
in a lazy part, and whether it then moves beside it is a separate decision.

**First step.** The owner's answer to the one product question above.

**Re-measure.**
`grep -rln "FanoutWdgt\|DiffingPatchNodeWdgt\|RegexSubstitutionPatchNodeWdgt" Fizzygum/src Fizzygum-tests/tests Fizzygum-tests/scripts --include='*.coffee' --include='*.js' | grep -v '\.scratch'`.

---

## §5. Visualisation pages are generated, not committed

**Effort.** About a day: one ignore rule, one generation hook, the removal of a gate with its
self-test, and the generator's dead branches.

**Evidence.**
- MEASURED: 375 `tests/*/visualisation.html` files are committed, 4.2 MB in all.
- READ: `scripts/make-visualisation.js` says of them "ALWAYS script-generated — never hand-edit
  it". A page is a function of the test's metadata, its macro's step comments and its reference
  filenames.
- READ: `scripts/check-visualisations.js` is a build gate (a row of `buildSystem/gates.js`)
  whose header says why it exists: a committed page embeds reference filenames, so any rename or
  recapture leaves it pointing at files that are gone, "and nothing in CI opens these pages". It
  records two incidents (10 of 305 pages broken on 2026-08-21; 279 that a rename would have
  broken on 2026-08-22). Its `--strict` mode (page equals what the generator would write now) is
  kept off the build because a template edit would fail every page until all are regenerated.
- READ: the capture path regenerates a test's page at the moment it writes a reference
  (`run-macro-test-headless.js`), to keep the committed copy current.
- READ: the generator still carries a recorded-test branch and a native-reference fallback
  (`isMacro ? 'macro test' : 'recorded test'`, "SWCanvas preferred with a NATIVE fallback").
  MEASURED: 389 of 389 tests are macro tests, and the tests repo's notes say no native reference
  is left.
- READ: the two test manifests set the precedent. They are generated, ignored by git, and
  rewritten by the build and by every runner, because "committing them would only create a
  staleness trap" (`Fizzygum-tests/.gitignore`).

**Why it matters.** A derived file in version control needs a writer at every place its inputs
change and a gate for the places that forget. All of that machinery exists here and has failed
twice. Generating the page when it is wanted removes the copy, and with it the staleness.

**Options (the owner's).**
- (a) Ignore `tests/*/visualisation.html`; generate the pages in the step that already writes
  the manifests, or on demand through one `fg` verb. `check-visualisations.js`, its self-test,
  its gate row, the `--strict` script and the regeneration at the capture site go. Recommended.
- (b) Keep the pages committed (if they are read somewhere a generated copy cannot reach, such
  as the repository's web view) and only remove the generator's recorded and native branches.

**Risk.** No pixel is involved. UNVERIFIED how long generating all 389 pages takes
(`time node scripts/make-visualisation.js`): if it is more than a second or two it belongs
behind a verb, not in every runner's startup. The per-test launch links inside a page point at
the built harness, which is unchanged.

**Ruled 2026-11-15 (owner).** Option (a): the pages are generated and no longer committed. A
capture still writes its test's page locally, and one `fg` verb regenerates them all.

**First step.** Time the generator, and run `check-visualisations.js --strict` on the untouched
tree: every committed page must equal what the generator writes now, or the difference is
understood before the copies go.

**Re-measure.**
`git -C Fizzygum-tests ls-files tests | grep -c visualisation.html` and
`grep -c -i "recorded\|native" Fizzygum-tests/scripts/make-visualisation.js Fizzygum-tests/scripts/macro-page-lib.js`.

---

## §6. Three test switches become one question

**Effort.** About a day, including a whole-suite measurement before and after.

This item takes up what round 2 named and did not queue: its §8 says "folding the three toggles
into 'a test is playing'" is a decision of its own, because a test that loads a world snapshot
mid-test would run on with them off.

**Evidence.**
- READ: `Automator` holds three class statics, all `false` by default: `animationsPacingControl`,
  `hidingOfWidgetsNumberIDInLabels`, `hidingOfWidgetsContentExtractInLabels`.
- READ: `AutomatorPlayer` turns the three on together at each test's start (grep
  `Automator.animationsPacingControl = true`: two sites, the second where a run completes).
  `WorldTestSupport._resetAutomatorTogglesNoSettle` turns the three off together.
- READ: the shipping teardown calls that harness method through an existence check
  (`@_resetAutomatorTogglesNoSettle?()` in `WorldWdgt.fullDestroyChildren`). The tests repo's
  own rule is "shipping code must never call anything that lives in this repo"; this soaked call
  is how the exception is spelled.
- MEASURED: core code reads the pacing switch on 9 lines and each label switch on 1. Core
  already asks `aTestIsPlaying()` on 18 lines (round 2's §5).
- READ: round 2's §8 measured the start over the whole suite, twice: the reset turns the three
  off and the start turns them back on in the reset's own cycle, identically for all 389 tests.
- MEASURED: no macro source names a switch (five tests mention pacing in their metadata prose),
  and no macro calls `loadWorldSnapshot` (one metadata string mentions it). So the case round 2
  held the fold back for is exercised by no test.

**Why it matters.** Three pieces of state, two writers and a reset exist to restate a fact the
player already knows. The reset is the reason shipping teardown code knows the harness has
switches at all.

**Fix shape.** The three questions become answers derived from the player's state (a test is
playing, or a run has just completed, for pacing), asked through the seam round 2 built. The
three statics, their writes, `_resetAutomatorTogglesNoSettle` and its call in
`fullDestroyChildren` go. The eleven read sites change spelling only.

**Risk.** The interval between a reset and the test's start: today the fresh world is built
with the switches off and they turn on later in the same cycle. If "a test is playing" is
already true during construction, a label built in that interval could differ. That is the
"Low (the start cycle)" in the table, and the first step measures it. A person driving the
harness page by hand gets the derived answers instead of the defaults, which is the same thing
whenever a test is running. No menu or panel offers the switches (MEASURED: the harness's menu
support names none).

**First step.** Before any code moves, a prelude that turns each static into an accessor and, at
every READ, compares its value with the derived answer, over the whole suite on both pointers.
Zero disagreements is the go-ahead; any disagreement names the cycle and the reader.

**Re-measure.**
`grep -rn "animationsPacingControl\|hidingOfWidgets" Fizzygum/src Fizzygum-tests/Automator-and-test-harness-src | grep -v -E ':[0-9]+:\s*#' | wc -l`
(22 today).

---

## §7. On-demand tools: one roster, each proven to start

**Effort.** One to two days: the roster, a start-proof per tool, the moves and the deletions.

**Evidence.**
- MEASURED: `buildSystem/lib/what-runs.js` lists 265 tooling files in the two repos and finds
  that the build and the legs run 217. The other 48 (8,300 lines) are started only by a person:
  through an `fg` verb, an npm script, or a path typed by hand.
- MEASURED: `buildSystem/census-doc-member-refs.js` (151 lines) is named by no `fg` verb, no npm
  script, no other script and no document, plans and archive included.
- MEASURED: `docs/profiling/` holds nine scripts and a results directory. They are code filed
  under `docs/`, outside the tooling files `what-runs.js` scans; their last changes are dated
  2026-07-08 to 2026-08-19; `docs/BACKLOG.md` records that they "keep their own world waits …
  outside the shared boot wait".
- MEASURED: `scripts/coalescing-measure/aggregate.js` was last changed on 2026-06-26.
- READ: `scripts/end-of-cycle-audit/run-audit-loop.sh` and `audit-one.sh` are a bash survey
  beside the Node audited-suite driver that round 2's §6 wrote for the gates.
- MEASURED: the tests repo's `package.json` offers 28 npm scripts. Many name a tool that an `fg`
  verb also starts (`recapture`, `fuzz`, `vmtruth`, `menu-sweep`, `pin-sweep`, `run-sequence`).
  `fg` adds what the npm script lacks: the right directory, the leftover-browser sweep, the
  verdict file.
- READ: the cost is on record. `docs/BACKLOG.md`: "Nothing keeps the similar-code mirror
  working … a construct the two compilers read differently stopped the scan unnoticed from
  f002a7b7 (2026-08-16) to 2026-11-10".

**Why it matters.** The build refuses a gate that no proof launches. An on-demand tool has no
such floor: it breaks silently when a core member is renamed, and is found broken on the day it
is needed.

**Fix shape.**
- One roster of on-demand tools, as data beside `buildSystem/legs.js`, read by `fg`'s usage
  text and by `what-runs.js`: each row a tool, its verb and one line saying what it is for.
- Every tool on the roster answers a cheap start-proof (`--help`, or a dry run on a fixture,
  exiting 0), and the `selftests` leg runs them all. A tool that cannot start fails that leg.
- A tool with no row is deleted or given one. Candidates to delete, each the owner's call:
  `census-doc-member-refs.js`, the `coalescing-measure` pair, the two bash audit scripts if the
  Node driver covers their use.
- The profiling scripts move out of `docs/` to a tooling directory and wait for their pages
  through the shared boot wait, or go.
- The npm scripts shrink to the ones the notes teach (`npm test`, `npm run smoke`,
  `npm run selftest`); the rest are reached through `fg`.

**Risk.** Deleting a tool someone uses twice a year. The roster's one-line purpose and the
owner's read of the candidates are the guard. A start-proof shows a tool starts, not that it
still measures what it claims; that is all this item buys, and it says so.

**First step.** Print the 48 with, for each, who names it (`fg`, npm, another script, a live
document, plans only, nobody) and its last change date, and put that table in front of the
owner.

**Re-measure.** In a scratch file under `Fizzygum-tests/.scratch/`:
`const W = require('<abs>/Fizzygum/buildSystem/lib/what-runs.js'); const ran = W.runSet().files; console.log(W.scriptFiles().filter(f => !ran.has(f)).join('\n'))`.

---

## §8. The backlog is an index again

**Effort.** About a day of careful moving, with no code beyond one small rule in a docs gate.

**Evidence.**
- MEASURED: `docs/BACKLOG.md` is 679 lines and 104,776 bytes, holding 212 open items (counted
  before this survey's own ten lines were added to it).
- READ: its header says "Index only: the executable detail lives in the linked plan section".
- MEASURED: 32 items run past five lines; several are a page of options and analysis.
- MEASURED: the file cannot be read in one pass by the tool sessions use: a whole-file read
  stops at line 352 of 679 (its 25,000-token page). A session that reads "the backlog" has read
  half of it.
- MEASURED: 26 items mark themselves "low", and 37 lines say the finding was made "by reading".
- READ: the owner ruled a bar for this file on 2026-11-11: an item is filed only if a person
  reaches it through the product and would notice, or if it is medium or worse whatever its
  reach; a low finding nobody reaches gets one line in the closing plan's ledger and never
  enters the backlog. UNVERIFIED that the bar is written in any file of the repos: it was found
  in session notes only, and `docs/README.md`'s filing rules do not state it.

**Why it matters.** The backlog is how a session learns what is already known. At this size it
is read partially, so items are re-found and re-filed, and the items that matter sit between
contrived ones.

**Fix shape.**
- The bar becomes a filing rule in `docs/README.md` and a sentence in the backlog's header.
- Each item becomes at most two lines: what is wrong, its reach or severity, and the plan
  section that owns the detail. The detail moves verbatim to that section (or to the owning
  plan's ledger), as README rule 2 already does for closed items.
- An item below the bar moves to its owning plan's ledger as noted and not queued.
- `check-doc-narration.js` already fails on a closed item left in the file. It gains a ceiling
  on an item's length, so the index stays an index.

**Risk.** Losing a finding in the move. The proof is mechanical: every sentence of the old file
appears in exactly one place afterwards (the new backlog, a plan section or a ledger), checked
by script before the commit. An owner-pending decision keeps its line however long its options
are; only the options move.

**Ruled 2026-11-15 (owner).** Shorten every item AND apply the bar to what is already filed.
Nothing is deleted: text moves verbatim into the plan that owns the item (an archived plan gains
a trailing `## BACKLOG detail` section, and README's "archive is immutable" rule gains that
exception). An item waiting on the owner keeps its line and its ⛔. The loop writes a table of
every item with its classification, for the owner's review afterwards.

**First step.** A table of the 212 items: lines, self-declared severity, reach (reached,
by reading, unstated), owner-pending or not. That table is the proposal.

**Re-measure.** `wc -lc Fizzygum/docs/BACKLOG.md; grep -c '^\s*- \[ \]' Fizzygum/docs/BACKLOG.md`.

---

## §9. A test is one file

**Effort.** Two to three days: one re-emitter with its byte-identity proof, the two definitions
of a test's files, the loader, the manifest generator, and every Node reader.

This item takes up the open line under round 2 in `docs/BACKLOG.md` ("§8 follow-up (⛔ owner
ruling): each test's `_automationCommands.js` now holds only its macro sources … rename it, or
fold it into the metadata file") and adds what was measured since.

**Evidence.**
- MEASURED: each of the 389 tests has two JavaScript files, `SystemTest_<name>.js` (metadata)
  and `SystemTest_<name>_automationCommands.js` (the macro sources): 778 files.
- READ: the two are loaded on two paths. `AutomatorLoader._loadTestMetadata` appends one
  `<script>` per test for EVERY test in the manifest, one after another, and both entry points
  call it for the whole manifest before anything runs (`AutomatorPlayer.runAllSystemTests` and
  `AutomatorLoader.selectTestsFromTagsOrTestNames`). `loadTest` then appends the second file as
  each test starts.
- READ: each of those script elements stays in `document.head` for the life of the page, and the
  comment at that site records a retention bug it caused (a handler left on 300 head scripts
  kept a dissolved world alive).
- UNVERIFIED: what the up-front load costs a shard. Each of the 8 shards of each suite leg
  loads all 389 metadata files to play about 49 tests.
- MEASURED: what the up-front load is for is small: `tags` (selection), `pointerKinds` and
  `mouseOnlyReason` (the finger filter, 15 tests), `testScreenExtent` (three tests),
  `testDuration` (the control panel's progress bar).
- MEASURED: `timeRecorded` is in every metadata file and no script, harness class or source
  reads it. `testDurationInMilliseconds` is in one file and nothing reads it.
- READ: the generated manifest already exists. `scripts/generate-tests-manifests.js` writes
  `tests/testsManifest.js` at every build and at every runner's start, from the tree.
- READ: `docs/BACKLOG.md` holds two more lines this dissolves: "Every test's metadata header
  still calls a macro test 'the new style'" (387 files) and "No gate holds a commands-file
  header to its own test".

**Why it matters.** The split dates from when the second file was a recorded command sequence,
large and separate from the description. It now holds one or two strings. The price is a second
definition of "a test's files" in every reader, a second load, and a load of the whole suite's
metadata on every page.

**Fix shape.**
- One file per test, `SystemTest_<name>.js`: the descriptive fields and the macro sources in one
  object.
- The generated manifest carries what selection needs for every test (name, tags, pointer
  kinds, extent). A page then loads only the files of the tests it plays, and
  `loadTestsMetadata` goes.
- `timeRecorded` and `testDurationInMilliseconds` are not re-emitted.
- The re-emitter parses each pair and writes the one file. Its proof: every macro source string
  is byte-identical before and after (compare the strings, not the files), and every reference
  path is untouched.
- `buildSystem/lib/tests-repo-code.js` (`testNames`, the one definition every Node reader
  shares) and `AutomatorLoader` change together.

**Not in this item.** All 389 test names begin `SystemTest_macro`, a prefix that once told a
macro test from a recorded one. Dropping it renames every test directory and all 8,092
reference files, so it belongs with round 2's §10 (the reference tree's one rename), not here.

**Risk.** Readers. Grep both repos for `_automationCommands` (19 files name it today: the
loader, the player, the toolkit, the manifest library and ten self-tests among them). No
pixel can move if the macro strings are identical; the gauntlet's `finger` leg and the WebKit
leg confirm it. The manifest becomes load-bearing for selection, so a hand-edited manifest
(`--keep-manifests`) must still carry the facts.

**Owner decision.** Rename or fold (the BACKLOG line's question). This item recommends fold.

**First step.** A prelude that makes the harness ignore every metadata script load and take
`tags`, `pointerKinds` and `testScreenExtent` from a manifest generated with those fields, for
one suite run on each pointer. A green run proves selection needs nothing else.

**Re-measure.**
`ls Fizzygum-tests/tests | grep -c SystemTest_` and
`grep -rl '"timeRecorded"' Fizzygum-tests/tests --include='*.js' | wc -l`.

---

## §10. `fg` in the toolchain's language

**Effort.** Four to five days: the port, the launch census that proves it, and a full gauntlet
on the parallel and the serial paths.

**Evidence.**
- MEASURED: `Fizzygum/fg` is 856 lines of bash (236 of them comments) in 20 functions. It
  launches `node` on 45 lines, and 97 lines deal with verdict files.
- MEASURED: it runs under macOS's `/bin/bash`, version 3.2.57.
- READ: its leg table is JavaScript (`buildSystem/legs.js`), which bash reads by running
  `node buildSystem/legs.js --shell …` and parsing what that prints.
- READ: `buildSystem/lib/what-runs.js` carries a shell lexer (`shellCommands`,
  `shellInvocations`, `matchParen`) and a list of four `fg` function names it must find
  (`FG_FUNCTIONS`), "or the reading is an ERROR", so that the build can learn from a bash file
  which scripts the legs launch.
- READ: the round-2 loop's ledger (local, `Fizzygum-tests/.scratch/cleanups-loop-2/LEDGER.md`)
  records defects that came from the shell itself: a `case` inside `$( … )` that bash 3.2
  misparses and `bash -n` does not catch (verdict files garbled, exit codes intact), a reader
  that took stderr lines for table rows, and shell `sort` and `comm` following the caller's
  locale so a listing's order differed between machines.
- READ: the precedent is the first survey's §10, which ported the build's Python to Node and
  proved it with build-tree fingerprints.

**Why it matters.** `fg` decides whether a commit point is green. It is the one large program
in the workspace written in a language none of the gates read, checked by none of the static
rules, and run by an interpreter whose parser has already hidden two defects.

**Honest scope.** This is a port. It removes a language boundary and the code that exists to
cross it; it removes no feature. That is why it ranks last on payoff.

**Fix shape.** `fg` becomes a Node program under `buildSystem/` (the `fg` file stays as a short
launcher, as the umbrella's shim is today). Legs are read as data from `legs.js`, and its
`--shell` printer goes. Kept exactly: the verdict files, the `caffeinate` hold, killing a leg's
whole process group, the one serial retry, the exit codes 0, 1, 2 and 3. `what-runs.js` reads
`fg`'s launches as it reads any JavaScript; its shell lexer stays for `build_it_please.sh` and
`build_and_smoke.sh`.

**Risk.** The commit-point check itself. Process groups, signals and the timeout idiom (`perl -e
'alarm …'`) behave differently from Node's child-process API and must be reproduced, not
approximated. The umbrella's guard hook and every instruction file name `fg` by path, which
does not change.

**Its own plan.** `docs/plans/fg-node-port-plan.md` holds the inventory of what `fg` does today,
the full matrix of process situations (a child that hangs, crashes, ignores a signal or leaves
descendants; `fg` itself interrupted, killed or throwing; a closed stdout; a second run; sleep),
the deliberate differences, and the ten-step proof. **Ruled 2026-11-15 (owner):** land and push
when every proof there passes; the bash `fg` leaves the repo and a copy stays in the loop's
scratch directory.

**First step.** Re-run round 2's launch census (logging stand-ins for `node`, `perl`, `pkill`
ahead of `PATH`, with data reads passed through) on today's `fg` for `presuite`, both gauntlet
paths and each standalone verb, and keep the logs. The port is done when it reproduces them
launch for launch.

**Re-measure.** `wc -l Fizzygum/fg; grep -c -E '\bnode +["$./A-Za-z]' Fizzygum/fg; /bin/bash --version | head -1`.

---

## 11. Measured and deliberately not listed

- **The input event class family.** Sixteen classes under `src/events-input/`, most of three to
  six code lines, one per browser event. Each carries its own `processEvent`: this is ordinary
  polymorphism, and only the two empty ones are residue (§1).
- **Baseline histories in `check-stinks.js`.** Six lines of that file are over 400 characters
  (the longest 2,994): each baseline's whole tightening history, in a line comment. The file
  says the history is deliberate (a baseline carries its reasons). Left; git holds the same
  story if the owner ever wants the lines short.
- **`serialization-roundtrip-headless.js`.** 5,262 lines in one file. Both earlier surveys left
  it; it has grown by 239 lines since the first, and still nothing depends on its shape.
- **The property-placement census.** 26 "demote to a local" candidates, of which 15 are
  `Theme`'s palette intermediates, and 418 write-only fields the census itself withholds as
  inspector payload. Advisory, and each field touched costs inspector references.
- **`FrameWdgt`'s docking family.** The first survey's "second candidate", still unexamined and
  still on `docs/BACKLOG.md`. This survey did not establish a seam either.
- **The five one-class `example-*` parts.** Five parts of one class each, because the loading
  unit is the part. The alternative (an example as a saved file, loaded through the file door)
  is a product design, not a cleanup.
- **The two boot paths.** Compile-at-boot cannot be retired in favour of the pre-compiled
  image: the image is harvested by booting the compile-at-boot tree.
- **The flat top level of `src/`.** 101 class files. Same verdict as both earlier surveys.
- **The seven conveniences patched onto built-in prototypes.** Round 2 measured and left them.

## 12. Already owned elsewhere (not listed again)

| Topic | Owner |
|---|---|
| Icon shells: one `IconWdgt` and a derived catalog | `plans/top-10-cleanups-plan.md` §9 (kept open by the owner) |
| The reference set: live path axes, one file per reference; and with it the `macro` prefix of every test name | `plans/top-10-cleanups-round-2-plan.md` §10 (left out for now by the owner) |
| Audit instruments that share a suite pass | `plans/top-10-cleanups-round-2-plan.md` §6 step 2 (measured; the owner's decision) |
| The creator-button and toolbar-button classes | `plans/creation-and-templates-plan.md` §4.3 |
| Two icon-appearance generations and pixel icons | `plans/pixel-icons-plan.md` |
| LiveCodeLang, its four vocabulary lists, `Number::times` | `plans/livecodelang-cleanup-and-extensions-plan.md` |
| Every gate re-masking all sources (about 13 s a build) | BACKLOG, under `archive/argument-holes-both-repos-plan.md` |
| The similar-code mirror nobody runs | BACKLOG, same section (§7 here would give it a start-proof) |
| Context-menu construction inside `Widget` | BACKLOG one-liner, `archive/god-class-decomposition-plan.md` Tier 3 |
| `fg status` reading build freshness its own way; `fg`'s stale budget comment | BACKLOG one-liners (§10 touches the same text) |

## 13. Case law that bounds these items (do not re-attempt blind)

- **A public settle wrapper belongs to the parent; subclasses override cores.** The round-4
  duplication triage (`docs/archive/duplication-triage-2026-07-15-hierarchy-round4.md`) both
  states the rule and records that deleting such wrappers kept `check-thin-wraps` green. §1
  re-applies it.
- **The hierarchy census is never promoted to a gate as it stands.** Its header gives the
  reason (`buildSystem/census-hierarchy-duplication.js`, "WHAT IS GATED, AND WHY ONLY THAT"):
  equal text that contains `super` is not equal dispatch. §1 gates only the bodies with no
  `super`, and leaves the rest advisory.
- **Removing a member from a core prototype is not automatically pixel-free.** Inspector member
  lists are screenshotted (`docs/archive/god-class-decomposition-plan.md`, guardrail 1). §1 and
  §4 budget for it.
- **A fair speed comparison is the real methods on two builds, runs alternating.** A freshly
  evaluated copy timed against the live method is biased by the engine's inline caches (the
  first survey's §6, "Landed"). §2 measures that way.
- **`PatchNodeWdgt` and `CanvasWdgt` stay in core, and the move is not to be re-attempted for
  the bytes** (`docs/BACKLOG.md`, under `archive/shared-base-layer-part-plan.md`). §4 does not
  move them.
- **Text-level exclusion is retired.** Whatever §4 chooses, it adds no marker and no flag
  (`Fizzygum/CLAUDE.md`, "How a build flavour excludes code").
- **The three test switches flip at every world teardown on purpose**, so that a mid-test
  snapshot load is covered (`WorldTestSupport`, the comment over
  `_resetAutomatorTogglesNoSettle`). §6 removes them only after measuring that no reader ever
  sees them differ from the derived answer.
- **A timing rewrite is proven with a prelude on hooks the old and the new code share**, stamped
  with the page's own cycle counter (round 2's §8, "Landed"). §6 and §9 use that instrument.
- **A blanket script edit of structured files has cost the project before.** §5, §8 and §9 parse
  and re-emit, then diff.
- **A reference is never recaptured to make a change pass.** Every item here expects zero pixel
  changes except where its table cell says otherwise; a difference is a finding about the
  change (`Fizzygum-tests/DETERMINISM.md`).
- **A gate that was ported is a gate that may have stopped biting.** Every gate's every rule is
  planted by a self-test (`docs/architecture/lint-and-static-checks.md` §3). §1's new gate ships
  with its plant; §5 removes a gate together with its proof; §10 is done when every leg's proof
  passes unchanged.
- **`fg` is read, never executed, by the tools that reason about it**, and a stand-in that
  answers a refactor's own data reads makes it pass vacuously (round 2's §7, "The table
  landed"). §10's census passes data reads through.

## 14. Shared verification protocol

Invoke the wrapper by absolute path; never pipe a gating call through a filter.

```
/Users/davidedellacasa/code/Fizzygum-all/fg status      # orient: heads, dirty counts, build freshness, verdicts
/Users/davidedellacasa/code/Fizzygum-all/fg build       # every static gate and every gate's bite proof
/Users/davidedellacasa/code/Fizzygum-all/fg presuite    # inner loop: build, dpr-1 suite, paint audit, fracplane rider
/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet    # commit point: 20 legs, run in the background, log to a file
/Users/davidedellacasa/code/Fizzygum-all/fg homepage    # production profile boot and snapshot round-trip (§3, §4)
/Users/davidedellacasa/code/Fizzygum-all/fg fingerprint # build-tree diff against a baseline ref (§3, §4)
/Users/davidedellacasa/code/Fizzygum-all/fg critique    # the advisory censuses and every ratchet (§1, §2)
```

Items that touch `tests/` (§5, §9) rely on the gauntlet's `finger` leg as much as on its mouse
legs, and leave every reference's bytes alone: no path under `tests/*/automation-assets/`
changes.

## 15. References

- `Fizzygum/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md`, `Fizzygum-tests/DETERMINISM.md`
- `docs/README.md` (filing rules), `docs/BACKLOG.md`, `docs/archive/INDEX.md`
- `docs/plans/top-10-cleanups-plan.md` and `docs/plans/top-10-cleanups-round-2-plan.md` (the two
  earlier surveys; their "Landed" paragraphs are the precedents cited above)
- `docs/architecture/lint-and-static-checks.md` (the gate index and the bite-proof rule; §1, §5)
- `docs/architecture/build-and-packaging.md` (parts and profiles; §3, §4)
- `docs/archive/duplication-triage-2026-07-15-hierarchy-round4.md` (§1)
- `buildSystem/lib/what-runs.js`, `buildSystem/legs.js`, `buildSystem/gates.js` (§7, §10)
- `buildSystem/lib/tests-repo-code.js`, `Fizzygum-tests/scripts/lib/tests-manifests.js` (§9)

## 16. Start prompt for a fresh session

```
Read Fizzygum/docs/plans/top-10-cleanups-round-3-plan.md in full (a survey of ten candidate
cleanups, ordered by effort). Then run /Users/davidedellacasa/code/Fizzygum-all/fg status and
confirm no long operation is running.

I want to take up item §<N>. Do this, in order:
1. Run the item's "Re-measure" command and tell me whether the numbers still match the plan.
2. Read the code the item cites and tell me anything that contradicts its evidence or its
   fix shape. Treat every statement marked UNVERIFIED as a question to answer first.
3. If the item is marked "owner decision first", stop there and lay out the options.
4. Otherwise carry out the item's "First step" exactly as stated, show me what it found,
   and wait for my go-ahead before the change itself. Verify with the plan's §14 protocol.
Do not commit or push without asking me.
```

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] §1 (½ day): overrides that override nothing — 8 methods identical to the one they inherit, 2 empty event subclasses, 6 recorder comments; the census's `super`-free subset becomes a build gate at zero (the census itself stays advisory)
  — CLOSED 2026-11-15 (loop U1): nine identical overrides, the two empty event classes and the six markers are gone, and
  `census-hierarchy-duplication.js --gate` holds the `super`-free subset at zero on every build (§1, "Landed").

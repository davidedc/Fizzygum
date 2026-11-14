# Top 10 code and architecture cleanups, round 2 — a survey, ordered by effort

> **PLAN ONLY. Written to be read and executed COLD by an LLM/engineer with ZERO prior context.**
> This is a SURVEY of ten candidate arcs, authored 2026-11-13 and ordered by effort, smallest
> first. Each item is a proposal with its evidence. Two of the ten need an owner decision before
> any code moves, and two more have a second step that does (marked in the table under "The list
> at a glance").
>
> **Relation to the first survey.** `docs/plans/top-10-cleanups-plan.md` (authored 2026-11-11) is
> the first round. Nine of its ten items have landed and its §9 (icon shells) is kept open by the
> owner. Nothing here repeats it: this round was surveyed on the tree as that round left it.
>
> **STATUS (owner, 2026-11-13).** The owner agreed with §1 to §9 and left §10 out for now. §4 is
> ruled: option (a), delete. §9 is agreed on its stated criterion. An unattended `/loop`, launched
> by the owner, executes §1 to §9 one unit at a time; its brief and ledger are local to the loop
> (`Fizzygum-tests/.scratch/cleanups-loop-2/`). The second step of §6 stays a measurement followed
> by an owner decision. An item's section gains a `**Landed <date>.**` paragraph as it lands, and
> the table's last column says where each stands. Landed so far: §1 to §5, §7's first step. Items the loop closes leave
> `docs/BACKLOG.md` for this plan's trailing BACKLOG ledger.
>
> **Mandate.** Each item aims at ELIMINATING a duplicated mechanism or a dead one, not at making it
> easier to live with. Where an item stops short of elimination, it says why.
>
> **Baseline.** Every number below was measured on 2026-11-13 at Fizzygum `5e657f92` and
> Fizzygum-tests `422aee506` (both clean, gauntlet green at 20 of 20 legs). Line numbers drift:
> the method name or the quoted code is the authority, and every item carries the command that
> re-measures it. Statements are labelled **MEASURED** (a command was run), **READ** (the code was
> read) or **UNVERIFIED** (a hypothesis the item's first step must test).

---

## 0. Orientation

**The project.** Fizzygum is a CoffeeScript GUI framework drawn on one `<canvas>`. Three sibling
git repos sit under an umbrella directory `Fizzygum-all/` (itself a small private repo of
workspace tooling): `Fizzygum/` (source, build, and the `fg` workflow wrapper), `Fizzygum-tests/`
(the SystemTest suite, the Automator harness and the headless rigs) and `Fizzygum-builds/`
(generated output). Read `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md` before touching
anything.

**Why a second survey.** The first round took the structural debt of the framework and of the
build: the mixins and their mechanism are gone, the build is bash and Node with its gates in one
table, the plane walk has one protocol, method counts and complexity are ratcheted. What that
round did not look at is the layer the project trusts most and reads least: the test harness, the
reference set, and the verification tooling around them.

**Two reframes that shaped the list.**

1. **The oldest code in the workspace is now the test harness.** The framework has been swept
   by 34 static gates and a dozen arcs. The Automator harness still carries the shape of two
   retired eras: the input RECORDER (a per-test command sequence, played by a timed cursor, for
   tests that are all one macro today: §8) and NATIVE references that forked by OS and browser
   (a five-segment directory chain with one value in every segment, and each reference stored
   twice: §10; a second, in-browser way to capture references: §4). The gates hold the harness
   to every rule they hold `src/` to, but no gate asks whether a mechanism still has more than
   one case to serve.
2. **Hand-kept rosters drift, and one has.** The first round turned the build's gate sequence
   into a table. The commit-point check did not get the same treatment: `fg` states its leg
   roster in six places, and the serial gauntlet path has silently lost three of the twenty legs
   (§7). The audit gates behind six of those legs exist in two generations, bash and Node, with
   different failure behaviour (§6).

**How the list was made.** A code and comment census of both repos by file; a census of class
families by base class; the stink and complexity ratchets; a read of `fg`, the gate table, the
audit gates and the harness; a census of the reference tree; byte counts of the instruction
files. Each candidate was then checked against `docs/BACKLOG.md`, the active plans and
`docs/archive/INDEX.md`, and dropped if an active plan already owns it (§12) or if earlier case
law bounds it (§13).

**Order.** Effort, smallest first, so the cheap items can be taken without reading the expensive
ones. Effort means the whole item including its verification runs (one gauntlet is about 20
minutes). The figures are ESTIMATES in working days; none is measured, and two items within half
a day of each other could swap. The table's "Payoff rank" keeps the other ordering: removed
mechanism, weighted by confidence in the evidence, divided by cost and risk (1 is the best
return).

---

## 0.5 Cold-execution protocol

1. **This document is a menu, not a script.** Pick ONE item. Items are independent except where
   one names a dependency (§10 step 2 depends on §4's decision; §8 is easier after §5).
2. **Re-measure first.** Run the item's re-measure command and compare with the numbers here. If
   they differ materially, the tree moved: re-read the code before trusting the fix shape.
3. **Items marked "owner decision first" stop at the decision.** Present the evidence and the
   options; do not start the code.
4. **An item that is taken up becomes its own plan** in `docs/plans/` when it is more than a
   day's work (§6 to §10), following `docs/README.md`'s filing rules; its line in
   `docs/BACKLOG.md` then points at the new plan and this survey's line for it is removed.
5. **Verify with the shared protocol in §14**, plus whatever the item adds.
6. **Never commit or push without the owner's approval.** Present a summary and the proposed
   commit message and wait.
7. **If a long operation is running in another session** (`cat /tmp/fg-*.verdict` shows
   `RUNNING`), do not edit sources or run a build: a running `fg` operation owns its inputs.
8. **An item that touches `tests/` in bulk (§8, §10) is a parse-and-re-emit job, never a blanket
   regex edit**, and its proof is that every macro source and every reference's pixels are
   byte-identical before and after.

---

## The list at a glance

Ordered by effort, smallest first. Effort is an estimate in working days for the whole item.
The fourth column says what is removed, then says the item again in plain words for a reader
who has never seen the code.

| # | Cleanup | Effort (estimate) | What goes away, and in plain words | Pixel risk | Owner decision first | Payoff rank | Status |
|---|---|---|---|---|---|---|---|
| 1 | Class source text ships as a plain string literal | ½ day | A three-glyph escape, its decoder at boot, a build refusal, three characters no source may contain. **In plain words:** to store each class's source in a file, the build swaps quotes, backslashes and line breaks for three look-alike characters, and the page swaps them back when it starts. JavaScript already has a standard way to write any text safely, so neither swap is needed. | None | No | 8 | Landed 2026-11-13 |
| 2 | `hashCode` leaves `Object.prototype` | ½ day | The last enumerable key on `Object.prototype`, and the reason the rigs give for never using `waitForFunction`. **In plain words:** a small helper for hashing text was attached to every object on the page. Every object then carries one extra visible property, which loops and test tools trip over. Make it an ordinary function that only text uses. | None | No | 6 | Landed 2026-11-13 |
| 3 | Map outlines are data | ½ day | About 3,000 of `src/`'s 37,681 code lines (8%), written as 2,638 `lineTo` statements. **In plain words:** the two maps are drawn by thousands of hand-written "draw a line to this point" instructions. Keep the points in a list and let one short loop draw them. | None expected (one test draws both maps) | No | 10 | Landed 2026-11-13 |
| 4 | The in-browser failure zip | ½ to 1 day | A second, ungated way to capture references; two vendored libraries; about 260 harness lines. **In plain words:** there are two ways to save new expected screenshots: a command that checks its own work, and an old button in the test page that downloads a zip with a copy script. Remove the old button and the two libraries only it needs. | One test shows the menu that loses two rows | Ruled 2026-11-13: delete | 7 | Landed 2026-11-14 |
| 5 | One seam for "a test is playing" | 1 day | 46 lines in 15 core files that name the harness; two spellings of one question; core fading the harness's DOM. **In plain words:** many widgets ask "is a test driving me right now?", each in its own wording. Give them one shared way to ask, and stop the framework from reaching into the test page's own buttons and indicators. | Low | No | 5 | Landed 2026-11-14 |
| 6 | One audited-suite gate driver, then shared passes | 2 days, then 1 to 2 | Three bash gates, their bash library, the bash twin of the rule registry, five hard-coded home paths; then up to three of eleven suite passes per gauntlet. **In plain words:** six checks each re-run the whole test suite with a different measuring tool attached. Half are written in shell and half in Node, and the two halves react differently when a browser dies. Write them one way; then see whether several tools can share one run. | None | Step 2: measured first | 4 | Step 1 queued for the loop; step 2's measurement queued last, its decision the owner's |
| 7 | The `fg` leg roster as a table | 2 to 3 days | A roster written six times; a serial gauntlet that runs 17 of 20 legs and says OK. **In plain words:** the list of checks to run before a commit is written out by hand in six places. One copy fell behind and skips three checks while still reporting success. Keep one list that every place reads. | None | No | 1 | First step (the serial path's three legs) landed 2026-11-14; the table queued for the loop |
| 8 | A test is its macro | 2 to 3 days | The six command classes, the timed command cursor, 389 copies of one preamble, about 38,900 log lines a run. **In plain words:** every test file still opens with the same five-step recipe, left from when tests were recordings played back step by step. A test is now a single script, so the recipe and the player built for it can go. | Low (the macro's start cycle) | No | 3 | Queued for the loop |
| 9 | Instruction files: a budget and one home per fact | 2 to 3 days | About 171 KB loaded into every session; each gate's story told in up to six places. **In plain words:** the notes every session must read before it starts have grown to the length of a short book, and the same explanation appears in several files. Keep the rules there and give each explanation one home. | None | Agreed 2026-11-13, on the item's criterion | 9 | Queued for the loop, last |
| 10 | The reference set: live axes, then one file per reference | 1 to 2 days, then 3 | Five single-valued path segments, the user-agent spoof, 213 lines of UA sniffing; then 4,046 files, 45.8 MB, and the reference loader. **In plain words:** every expected screenshot sits five folders deep in folders that never vary (one operating system, one browser), and is saved twice: as a picture and as the same picture wrapped in a script. Flatten the folders, then keep only the picture. | None (pixels untouched) | Step 2 depends on §4 | 2 | Not queued: left out for now by the owner (2026-11-13) |

---

## §1. Class source text ships as a plain string literal

**Effort.** About half a day: two lines of `build.js`, three of the vault, one regex of the
fingerprint tool, and a proof that every class's text comes back byte-identical.

**Evidence.**
- READ: `buildSystem/build.js` writes each class's source into a batch file as
  `SourceVault.store("<Name>", "<escaped>", "<part>")`, where the text is escaped by replacing
  `"` with `＂`, `\` with `⧹` and each newline with `⤶` (grep `STRING_BLOCK`).
- READ: `src/boot/source-vault.coffee` `store` undoes it with three global regex replaces, run
  over every class source at every compile-at-boot start and every lazy-part load.
- READ: because the three glyphs are the escape, no source may contain them: `build.js` refuses
  the build when one does (grep `already holds`). The comment above `STRING_BLOCK` records the
  choice: of three ways to embed the text, swapping the characters was "the easiest". The same
  comment rules out `.json` FILES (not loadable over `file://`); a JSON-escaped literal inside
  the `.js` batch is a different thing and has no such limit.
- READ: `Fizzygum-tests/scripts/build-tree-fingerprint.js` reads the batch files with a regex
  whose comment states it is safe ONLY because of this escape (grep `cannot run past`).
- MEASURED: the three glyphs appear on 4 lines of `build.js`, 3 of the vault and 2 of the
  fingerprint tool, and nowhere else in either repo's code.

**Why it matters.** The build is Node now. `JSON.stringify(text)` is a correct JavaScript string
literal for any text, so the escape, its decoder, the refusal and the rule "these three
characters are forbidden in source" are all one line's worth of work done by hand. Each glyph is
three bytes of UTF-8 where a JSON escape is two, so the batch files get smaller too.

**Fix shape.** `STRING_BLOCK` emits `'SourceVault.store(' + JSON.stringify(name) + ', ' +
JSON.stringify(content) + ', ' + JSON.stringify(part) + ');'`. `SourceVault.store` keeps the
text as given. The refusal and the long comment go. The fingerprint tool's `STORE` regex reads a
real string literal (`"(?:[^"\\]|\\.)*"`), or parses the batch with the vendored acorn.

**Risk.** None on pixels: the compiled classes are a function of the text, and the text is
unchanged. The batch files' bytes change, so a build-tree fingerprint differs there by design.
`JSON.stringify` leaves U+2028 and U+2029 raw, which a string literal accepts since ES2019;
confirm on WebKit with a source that holds one.
UNVERIFIED: that nothing else reads a batch file by pattern. `buildSystem/check-source-vault.js`
and `src/PartsRegistry.coffee` name `SourceVault.store` in comments only (MEASURED: zero glyph
lines in either), but grep both repos for `sources_batch` before changing the shape.

**First step.** A probe page that records `SourceVault.get name` for every `SourceVault.names()`
on the current build. After the change, the same probe must print the same texts, and
`js/pre-compiled.js` of a `--profile homepage` build must be byte-identical.

**Re-measure.**
`grep -c '＂\|⧹\|⤶' Fizzygum/buildSystem/build.js Fizzygum/src/boot/source-vault.coffee Fizzygum-tests/scripts/build-tree-fingerprint.js`.

**Landed 2026-11-13.** `STRING_BLOCK` writes its three arguments with `JSON.stringify`;
`SourceVault.store` keeps the text as given; the escape, its decoder, the build's refusal and the
comment that chose the escape are gone, and the fingerprint tool's `STORE` reads a real string
literal (it still reads a tree built before). The re-measure command now prints 0 for all three
files. Nothing else read the encoded form: every other reader goes through `SourceVault.get` or
`names`. Evidence: a probe read every `SourceVault.names()` entry on `index-sw.html` before and
after, on Chrome and on WebKit: 553 sources, each text's SHA-256 and the vault's insertion order
identical (the emission order `findLoadOrder` walks, so the load order follows), every text
byte-equal to its file; a plant made by the build's own `STRING_BLOCK` (raw U+2028 and U+2029, `"`, `\`, a tab, a
CR, `</script>`, the three retired glyphs) read back equal on both engines, loaded as a script
file and as a DOM-inserted inline script (which no HTML parser reads, so it says nothing about
a `<script>` block written inline in an HTML file). The batch cut still measures the text a batch holds, which JSON makes longer in
code points, so nine batches hold a different run of sources (core 3 to 8, authoring 0 to 2);
every part keeps its batch list and the load order is the same, and the batches are 92,691 bytes
smaller (4,362,726 to 4,270,035; `Class-source.js` 42,874 to 41,820). The resolution map is identical. `fg fingerprint <profile> HEAD`
for all five profiles: the same multiset of (source, part) on both sides; the files that differ
are the batch files and `Class-source.js` wherever a profile ships them, and the boot bundle,
whose ONE difference (seen by building both and diffing) is `store` losing its decoder, 72 bytes;
`js/pre-compiled.js` is byte-identical on `dev-precompiled`, `homepage` and `lean`.

---

## §2. `hashCode` leaves `Object.prototype`

**Effort.** About half a day: one boot function, 14 call sites, three comments in the rigs, and
one measurement of `waitForFunction`.

**Evidence.**
- READ: `src/boot/extensions/Object-extensions.coffee` assigns `Object::hashCode`, a memoized
  32-bit hash of `@toString()`. A plain assignment is ENUMERABLE, so every object on the page
  inherits an enumerable key.
- MEASURED: 14 call sites: `TextWdgt` 5, `StringWdgt` 5, `PanelWdgt` 2, `Widget` 1, and the
  harness's `HashCalculator` 1. Twelve are called on a string. The two in `PanelWdgt` hash a
  widget's `toString()`, one of them through the inherited method (`aWdgt.hashCode()`).
- READ: three places pay for the enumerable key. `src/boot/source-vault.coffee` warns that an
  un-`own`ed `for … of` over a plain object sees it. `Fizzygum-tests/scripts/smoke-boot-headless.js`
  (grep `ENUMERABLE member`) says it is the only such member and is why the rigs poll inside the
  page and never use `page.waitForFunction`. `run-all-headless.js` and
  `run-macro-test-headless.js` say the same in their headers, in older words ("patches built-in
  prototypes heavily").
- READ: `docs/BACKLOG.md` holds the open line: whether `waitForFunction` works today is
  unmeasured, and the two headers are stale either way.

**Why it matters.** One convenience method forces a rule on every loop over a plain object and
on every rig. It is a string hash; nothing needs it on every object.

**Fix shape.** A boot function, `stringHash text` (in `src/boot/globalFunctions.coffee`, beside
`textOfThrownValue`), holding the same memo; the 14 sites call it (`stringHash aWdgt.toString()`
for the inherited one); `window.stringHashCacheForAudit` and its `WorldInventory` policy line
stay as they are. `Object-extensions.coffee` is deleted. Then measure `waitForFunction` on the
harness page, close the BACKLOG line with the result, and make the three rig comments say what
is true.

**Risk.** None on pixels if the hash values are unchanged: `PanelWdgt` scatters by them, and
`HashCalculator` writes them into failure records. A macro source could call `.hashCode()`:
MEASURED zero in `tests/`.

**Measured and left.** The other built-in patches are each a live convenience, called on
between one and six lines, with no cost outside themselves: `Array::remove`, `Array::chunk`,
`Number::toRadians` and `toDegrees`, `String::isLetter`,
`String::getNthPositionInStringBeforeOrAfter`, `Math.getRandomInt`. None is on
`Object.prototype`. Not part of this item.

**First step.** `Object.keys(Object.prototype)` in a page, before and after: `["hashCode"]`,
then `[]`.

**Re-measure.**
`grep -rn '\.hashCode()' Fizzygum/src Fizzygum-tests/Automator-and-test-harness-src --include='*.coffee' | grep -v 'boot/extensions' | grep -vc ':[0-9]*:\s*#'`.

**Landed 2026-11-13.** The string hash is `hashOfString text`, a boot function in
`src/boot/globalFunctions.coffee` (named as its neighbours are, for what it returns:
`textOfThrownValue`, `superclassOf`; the harness's records already say `hashOfData`). Its memo
block MOVED there verbatim, with the assignment and `@toString()` → `text.toString()` the only
changed code lines; `Object-extensions.coffee` is deleted with its `parts.json` row. The 14 call
sites call it; `WorldInventory`'s report key is `hashOfString.stringHashCache` (renamed with its
family and the inventory doc: nothing else read it). The re-measure command prints 0. Evidence:
the old and the new function, each compiled from its file, agree on 36,710 inputs (every source
text, 5,000 random strings around and past the 2,048-character cache limit, passes that hit and
overflow the memo); `Object.keys(Object.prototype)` was `["hashCode"]` (on the harness page and
`index.html` under Chrome and the harness page under WebKit) and is `[]` on `index.html`,
`index-sw.html`, the harness page and a `homepage` tree; the resolution map changes
exactly the 12 methods that hold a call site or the inventory key, wherever they are inherited.
**`waitForFunction`, measured:** it works on the harness page and `index.html` under Puppeteer and
on the harness page under Playwright WebKit — before this change too (`hashCode` survived
Puppeteer's export walk) — so the rigs' comments now say their bounded in-page polls are a
choice; no rig's wait was converted.

---

## §3. Map outlines are data

**Effort.** About half a day: a throwaway converter that parses the two paint bodies and
re-emits them as tables, one loop per file, and an operation-log proof.

**Evidence.**
- MEASURED: `src/maps/SimpleUSAMapIconAppearance.coffee` is 2,261 code lines and
  `SimpleWorldMapIconAppearance.coffee` 803: together 3,064 of `src/`'s 37,681 code lines, 8%.
  The first is the second-largest file in the tree by code, behind only `Widget.coffee`.
- MEASURED: their bodies are 2,638 `context.lineTo` statements in 81 polygons (50 and 31
  `beginPath` calls), each polygon followed by the same `closePath` / `fillStyle` / `fill`.
- MEASURED: one SystemTest draws a map: `SystemTest_macroSampleDashboardPlots`, whose sample
  dashboard holds a USA map and a world map (its image 0 shows both). So both maps' pixels are
  held by that test's references. (Corrected 2026-11-14 by the loop: this read "world maps" and
  "the USA map's by none".)

**Why it matters.** Polygon coordinates are data written as code. As code they are compiled in
the browser on every compile-at-boot start of the `maps` part, masked by every static gate on
every build (the BACKLOG's "every gate re-masks all of the compiled sources" line), and counted
by every census. As a table they are one array literal each.

**Fix shape.** Each class holds its outlines as a class-level list of flat coordinate arrays
(one per polygon, in today's order) and paints them with one loop that issues exactly today's
calls. Any polygon that differs from the common shape (a different fill, a `translate`) is kept
as a row with its own fields, never special-cased in code.

**Risk.** None expected on references. The proof is not a screenshot: wrap a recording context
around `paintFunction` on the old and the new class and require the two call logs (method names
and arguments, in order) to be identical. That is stronger than pixels, covers every polygon
whether or not a screenshot shows it, and needs no capture; the dashboard test then confirms
both maps at both densities.

**First step.** Write the recorder and take the old logs. Then write the converter as
parse-and-re-emit (the workspace rule for bulk edits of structured files), never a regex pass.

**Re-measure.**
`grep -c 'context.lineTo' Fizzygum/src/maps/SimpleUSAMapIconAppearance.coffee Fizzygum/src/maps/SimpleWorldMapIconAppearance.coffee`.

**Landed 2026-11-13.** Each map appearance holds its outlines as a class-level table, `@outlines`:
one row per polygon in painting order, its `contours` a list of flat `[x, y, x, y, …]` lists and,
on the one world polygon drawn shifted, a `translate` field; `paintFunction` is one loop that
issues exactly the old calls in the old order (the per-polygon `fillStyle` set included).
Maryland is the one polygon with two contours, a row like any other. A throwaway converter
parsed each paint body with a strict per-line grammar (anything else stops it), kept every
number's source text, and checked its own output by compiling the table back and walking it.
The files went from 2,261 and 803 code lines to 410 and 171 (64,215 and 23,034 bytes to 25,691
and 9,579); the re-measure command prints 1 for each (the loop's one `lineTo`). Evidence: a
recording context (every call with its arguments and every property set, in order) driven
through each appearance's `_paintColoredIcon`, the path a paint takes into `paintFunction`, at
two widget sizes: the four operation logs (2,261 and 803 operations) are byte-identical old
and new; the resolution map changes the two `paintFunction` members and nothing else;
`SystemTest_macroSampleDashboardPlots` passes untouched at both densities and both pointers.

---

## §4. The in-browser failure zip: a second way to capture references

**Owner decision first.** This removes a facility a person reaches from the harness page's
control panel and from the world's test menu.

**Owner ruling 2026-11-13.** Option (a): delete it.

**Effort.** Half a day to a day (deletion): about 260 lines of `AutomatorPlayer`, two methods of
`Automator`, two menu rows, a control-panel button, two vendored files and their `parts.json`
rows, one sweep allowlist entry, and one stale procedure document.

**Evidence.**
- READ: `AutomatorPlayer.saveFailedScreenshots` builds a zip in the page: each failed
  screenshot as `.js` and `.png`, a red difference image per reference
  (`_subtractScreenshots`, `createImageFromImageData`), and a generated shell script,
  `replace_all_images.sh`, that copies the obtained files over the references.
  `Automator.packUpForDownload` saves it, with a Safari branch. MEASURED: the three
  `AutomatorPlayer` methods span lines 513 to 770.
- MEASURED: no script calls it. Its callers are a menu row and a control-panel button
  (`WorldTestSupport`, `SystemTestsControlPanelUpdater`). The headless tools read failure images
  straight from `world.automator.collectedFailureImages`.
- READ: it is the only user of the two libraries the `harness` part vendors, `vendor/jszip/`
  (102,328 bytes) and `vendor/filesaver/`. `src/serialization/FileSaving.coffee` states that
  the product's own saving does not use them.
- READ: `Fizzygum-tests/scripts/README-swcanvas-tests.md` still teaches this path as THE way to
  record references (run the suite in a browser, download the zip, run the shell script). The
  workspace's stated way is `fg recapture --auto`, which has a completeness gate; `fg diffpage`
  is the stated way to see a difference.
- READ: `menu-click-sweep-headless.js` carries an `ELLIPSIS_EXCEPTIONS` entry only because this
  row's download starts after the sweep has read the act.

**Why it matters.** Two ways to turn a failure into references, one gated and one not. The
ungated one writes files with a generated `rm` and `cp` script, and it is the reason a
reference's `.js` record carries its pixels as base64 (§10 step 2).

**Options.** (a) Delete it: the zip, the difference images, the shell script, "Show test
source" (a `window.open` of the command sequence, which §8 empties), both libraries, the README
procedure. (b) Keep a download of the obtained images only, through the product's own
`FileSaving`, and delete the rest. Recommendation: (a). A person at the browser who wants the
pictures can run `fg diffpage <test>`.

**Risk.** One test draws what this deletes: `SystemTest_macroHoppingBetweenSubMenus` opens
the world menu's "System tests" submenu, which holds the two rows ("Show test source", "Save
failed screenshots…"). Its shots of that submenu lose two rows and are recaptured; every other
pixel in the suite must stay put. The harness part's fingerprint changes (two files leave
`js/libs`).

**First step.** Ask the owner whether the browser-side download is still used.

**Re-measure.**
`grep -rn 'saveFailedScreenshots\|packUpForDownload\|JSZip' Fizzygum-tests/Automator-and-test-harness-src Fizzygum-tests/scripts --include='*.coffee' --include='*.js' | grep -vc '^\S*:[0-9]*:\s*[#/]'`.

**Landed 2026-11-14.** Deleted: `AutomatorPlayer.saveFailedScreenshots`, `createImageFromImageData`,
`_subtractScreenshots` and the kept-references static `loadedImagesToBeKeptForLaterDiff` that only
the zip read; `Automator.showTestSource` and `packUpForDownload`; the two menu rows;
`SystemTestsReferenceImage`'s two zip writers; `vendor/jszip/` and `vendor/filesaver/` with their
`parts.json` rows and their two boot loads. The control panel's failed-tests counter stays, as a
counter: its click and its link styling went. Kept, because a headless tool reads them:
`collectedFailureImages`, the failure budget, a record's `imageData`, `createJSContent`. Two checks
lost subjects with the code: the unresolved-sends allowlist's JSZip entries are retired, and so are
five `BUILTINS` names (plus the `window` receiver) that no remaining call sends in the form the gate
reads, `.name(` (`drawImage`, `getImageData`, `toDataURL` and `window.open` are still used, written
without parentheses, which that gate does not read); its self-test control names
`bitmapText.loadFont()` as its allowlisted example, whose entry is load-bearing (removed, the gate
fails at the name's real call site); the menu sweep's one ellipsis exception went. `README-swcanvas-tests.md`'s
capture procedure is the headless one. The re-measure command prints 0. Evidence: a census of every
deleted name in both repos (only this plan, the lint index's note and dated records remain); the
resolution map loses exactly the seven methods and changes three bodies; `fg menusweep` green.
`fg fingerprint` shows the two libraries leaving `js/libs` in `dev`, every boot bundle 122 bytes
shorter (the two loads and the boot log's names, the one difference a bundle A/B shows), the
harness batches and the core batch holding `FileSaving`'s comment changing, and
`js/pre-compiled.js` byte-identical in `homepage` and `lean`. One test changed, as this
section's Risk said: `SystemTest_macroHoppingBetweenSubMenus` image 5, its submenu two rows
shorter, every changed pixel inside the submenu's old box; recaptured at both densities for
both pointers.

---

## §5. One seam for "a test is playing"

**Effort.** About a day: one question with one home, 17 call sites, the hand's indicator calls
moved behind a harness-installed member, and a gauntlet.

**Evidence.**
- MEASURED: 46 non-comment lines in 15 core files (outside `src/macros`) name `Automator` or
  `AutomatorPlayer`, each behind an existence guard.
- MEASURED: 17 of them test the automator's state, in two spellings: `Automator.state ==
  Automator.PLAYING` (9) and `Automator.state != Automator.IDLE` (8). READ: the state has two
  values and two assignments (`AutomatorPlayer`, grep `Automator.state =`), so the spellings
  ask the same question.
- READ: nine sites add `and Automator.animationsPacingControl`, a toggle every test turns on
  at its start and EVERY world teardown turns off (§8): `ToolTipWdgt`, `DragChargingRingWdgt`, `ActivePointerWdgt` (2),
  `ViewportWdgt`, `BlinkerWdgt`, `AnalogClockAppearance`, `Example3DPlotWdgt`,
  `GraphsPlotsChartsWdgt`. Two more read the label toggles (`Widget`, `StringWdgt`).
- READ: the toggles are NOT redundant with the state. `WorldWdgt.fullDestroyChildren` resets
  all three (grep `_resetAutomatorTogglesNoSettle`), and its comment says why the call sits
  there: a test that loads a whole-world snapshot MID-test runs its remainder with the toggles
  off, and its references were captured that way.
- MEASURED: `ActivePointerWdgt` calls `Automator.fade` six times, on the left and right
  mouse-button indicators, and looks up `mousePointerIndicator` by id: core code animating DOM
  elements of the harness's control panel.
- READ: `Example3DPlotWdgt` says in a comment that it inlines the test because it cannot inherit
  `GraphsPlotsChartsWdgt._animationFrozenForDeterministicReplay`.

**Why it matters.** "Is my time driven by the event stream?" is the determinism contract's
central question (`Fizzygum-tests/DETERMINISM.md`), and it is written out by hand at each site
with small variations. A widget author copying one of them picks a spelling at random. The hand
reaching into the harness's DOM is the wrong direction for the part boundary, even guarded.

**Fix shape.** The established one for this boundary. The question gets one core home that
needs no harness, for example `world.timeFollowsEvents()`, which answers false unless the
harness says otherwise; the 17 sites ask it. The pointer indicators become a member the harness
installs (a `*TestSupport` class, the pattern `Fizzygum-tests/CLAUDE.md` describes), called
through an existence test, which `check-part-edges.js` already accepts as a guard.

**Risk.** Low. The two spellings of the STATE test are equivalent today, so each site is a
rename. The toggles are a different fact (the bullet above): each site keeps its toggle beside
the shared question, exactly as today. Any site where the answer is read on a hot path (the
hand, per event) must stay a field read.

**First step.** List the 17 sites with what each does when the answer is yes, and which toggle
each reads beside the state. The change must leave every site's condition with the same truth
table.

**Re-measure.**
`grep -rn '\bAutomator\(Player\)\?\b' Fizzygum/src --include='*.coffee' | grep -v ':[0-9]*:\s*#' | grep -vc 'src/macros/'`.

**Landed 2026-11-14.** The question is `aTestIsPlaying()`, a boot function in
`src/boot/globalFunctions.coffee` holding the one guarded read of the automator's state (false
without the harness part). It is asked of no world: the automator outlives worlds and a widget may
ask while none stands. (A `WorldWdgt` static was tried first: it raised that class's method
ceiling, which a ratchet forbids.) The 17 sites ask it; each keeps its toggle beside it, with its
own `Automator?` guard, operands in the site's order; the two spellings were equal because the
state starts IDLE and is only ever set IDLE or PLAYING. The hand's four reaches into the harness
page's DOM moved, bodies verbatim, into `ActivePointerTestSupport`, installed onto
`ActivePointerWdgt` at boot like the other five; the hand calls each through an existence test
(`@_showButtonIndicatorPressed? e if aTestIsPlaying()`). The install lines moved, verbatim, into
their own boot function, `installTestSupportMembers`, which the complexity ratchet required
(`createWorldAndStartStepping` fell below the threshold and its record went; two of the hand's
records fell, 22 to 17 and 80 to 76). The re-measure command prints 29 (46 before). Evidence:
the site table with each old and new condition (equal truth tables); the resolution map changes
exactly the methods holding a site and adds the four members; `check-part-edges` green. One cost,
kept on purpose: six sites (the frame loop, the hand's down, up and move, the context-menu open, a
3D canvas's clock) used to be stripped from a production build by their `Automator?` guard; they
now make one cheap call there that answers false.
U6-PENDING

---

## §6. One audited-suite gate driver, then instruments that share a pass

**Effort.** About two days for step 1 (three gates ported, each with its bite proof re-pointed).
Step 2 is one to two days and starts with a measurement.

**Evidence.**
- READ: six gauntlet legs are the same thing: one full dpr-1 suite pass under one
  `--audit-prelude=` instrument, then a verdict read from the per-test buckets. Three are bash
  (`tier-naming-audit/run-tier-naming-gate.sh`, `notification-settle-audit/run-notification-settle-gate.sh`,
  `end-of-cycle-audit/run-capstone-gate.sh`: 147, 99 and 140 lines) and three are Node
  (`revisit-gate.js`, `storage-invariant-gate.js`, `vm-truth-gate.js`).
- READ: the bash three share `scripts/lib/audited-suite-with-infra-retry.sh` (167 lines), which
  holds a bash twin of the rule registry (`gate_rules_init` / `gate_rule`, the twin of
  `Fizzygum/buildSystem/lib/gate-rules.js`) with a self-test of its own
  (`lib/gate-rules-sh-selftest.js`). They compute their verdicts with `grep | wc -l` and `sed`
  over logs.
- MEASURED: the two generations fail differently. The bash library retries a dropped shard once
  at three shards and exits 3 on a second drop; none of the three Node gates has that path
  (`grep -i 'retry\|infra'` finds nothing in them), so the same dropped shard is an in-gate
  retry on `tiernaming` and a failed leg on `revisits`.
- MEASURED: the only machine-specific paths in either repo's code are here: five scripts open
  with `cd /Users/<name>/code/Fizzygum-all/Fizzygum-tests` (the three gates, `audit-one.sh`,
  `run-audit-loop.sh`).
- READ: `Fizzygum/buildSystem/lib/what-runs.js` states a blind spot these scripts cause: a
  prelude handed to a shell function (`run_audited_suite x-prelude.js`) is a launch it cannot
  see.
- MEASURED: a gauntlet runs the whole suite eleven times: `dpr1`, `dpr2`, `webkit`, `finger`,
  and seven instrumented dpr-1 passes (`paint`, `tiernaming`, `settle`, `capstone`, `revisits`,
  `storage`, `vmtruth`). The last green run took 203 to 245 s for each of the six in wave B.
  `fg`'s own comments record wave B tipping the machine at 14 legs.

**Why it matters.** This is the first survey's §10 again, one level up: one mechanism in two
languages, with the copies already disagreeing. And seven instrumented passes is the largest
single cost of a commit point.

**Fix shape.**
- **Step 1: one driver.** A Node module, `scripts/lib/audited-suite.js`: run the suite under an
  instrument, the infra retry, "every bucket was measured", the three exits. The three bash
  gates become Node gates that use it and name their rules through `gate-rules.js`; the three
  existing Node gates adopt it and gain the retry. The bash library, its registry twin, that
  twin's self-test and the five home paths go. `what-runs.js` loses the blind spot.
- **Step 2: shared passes (measure first).** `run-all-headless.js` takes one `--audit-prelude=`
  today. If it took several, instruments that only OBSERVE could ride one pass.
  UNVERIFIED: that any two compose. All preludes print under one prefix (`LAYOUTAUDIT`,
  MEASURED 37 sites), so each line needs its instrument's tag first; the settle prelude also
  arms the cached-versus-slow twins check, which changes speed; the storage prelude drains and
  reclassifies at each reset, which changes state at the seam; `vmtruth` forces collections and
  needs its own Chrome flags, so it stays alone. The candidates are `tiernaming`, `settle`,
  `capstone` and `revisits`.

**Risk.** Step 1: a gate that stops biting. Every gate has a bite proof
(`*-gate-selftest-headless.js`) that plants each rule; the port is done when each proof passes
unchanged against the new gate. Step 2: an instrument perturbing another's reading.

**First step (step 2).** Run the four candidates together on the whole suite and compare each
gate's verdict and per-test profile with its solo run. Only an exact match on every test admits
a pair to a shared pass. Bring the result to the owner: it trades four narrow legs for one
wider one.

**Re-measure.**
`wc -l Fizzygum-tests/scripts/*-audit/run-*-gate.sh Fizzygum-tests/scripts/lib/audited-suite-with-infra-retry.sh; git -C Fizzygum-tests grep -c '/Users/' -- scripts`.

---

## §7. The `fg` leg roster as a table

**Effort.** Two to three days: a table, a runner that `fg` calls for the waves and for the
serial path, `what-runs.js` reading the table, and the usage text generated from it. The proof
is a gauntlet whose per-leg command lines are identical before and after.

**Evidence.**
- READ: `Fizzygum/fg` states the gauntlet's legs in six places: the `run_leg` case (each leg's
  command, alarm and exit rule), the `legs_pending` list, the wave lists, the serial path's own
  hand-written sequence, `leg_headline`'s pattern, and the usage text. Nine legs are also
  standalone verbs (`census`, `revisits`, `storage`, `vmtruth`, `apps`, `menusweep`,
  `pinsweep`, `graph`, `finger`) that repeat the leg's command line with other shard counts.
- MEASURED: **the serial path has drifted.** `FG_GAUNTLET_SERIAL=1 fg gauntlet` runs 17 legs.
  `parts`, `storage` and `vmtruth` are in `legs_pending` and in the waves and are never run by
  the serial path, which then prints `GAUNTLET OK`. The umbrella notes describe that path as
  "the old sequential path, for load-sensitivity diagnosis".
- READ: the comment above `legs_pending` records the same class of slip once already: a leg
  missing from that list showed the previous run's log as this run's result.
- READ: `what-runs.js` finds what the legs launch by lexing the bodies of four `fg` functions as
  shell, and states that "a leg of `fg` is trusted to be in a wave".

**Why it matters.** A commit-point check that can silently run fewer legs than it names is the
failure the whole gate system exists to prevent, and the serial path did it until the first step
landed (2026-11-14). The build's gates got a table
for this reason (`buildSystem/gates.js`, run by `run-gates.js`).

**Fix shape.** One table (a Node module beside `gates.js`), a row per leg: name, command, alarm,
wave, exit rule (the legs that also need a line in the log, the gates whose exit 3 is a load
flake), headline pattern, and whether it is a standalone verb and at what shards. One runner
executes a row. The parallel path runs the rows wave by wave; the serial path runs the same
rows one after another, so it cannot run fewer. `legs_pending`, the usage roster and the
standalone verbs read the table. `what-runs.js` reads the rows as it reads the gate table's,
and its "trusted to be in a wave" blind spot becomes a check.

**Risk.** `fg` is the workspace's most-run file; a mistake costs every session. Keep bash as the
entry point and move only the roster and the per-leg execution. `fg` holds the machine awake,
writes the verdict files and applies the alarms: those stay where they are.

**First step.** Fix the serial path's three missing legs today as a three-line change of its
own (it is a defect, and it stands whether or not the table is built). Then record every leg's
exact command line from a green gauntlet's logs as the fixture the table must reproduce.

**Re-measure.**
`sed -n '/SERIAL escape hatch/,/PARALLEL path/p' Fizzygum/fg | grep -cE 'parts-lazy|storage-invariant|vm-truth|run_leg (parts|storage|vmtruth)'`
(0 before the first step landed: the serial path launched none of the three).

**First step landed 2026-11-14.** The serial path runs `storage`, `parts` and `vmtruth` through
`run_leg`, after `serialization`, each as that branch's other legs run: browsers killed first, its
verdict in the tally, a short grep of its log on failure. The re-measure command prints 4: the
three launches, and the `vmtruth` line's own failure grep, whose pattern names `vm-truth-gate:`.
The first serial run then showed a second drift: the serial path audited paint in one browser
(`--shards=1`, "~7 min"), which can no longer finish the 389-test suite inside the audit's own
600 s bound (measured alone at load 9: 0 tests checked), so the serial gauntlet could not pass
before this step either; it now runs `paint` through `run_leg` too, as the waves do. Evidence:
`FG_GAUNTLET_SERIAL=1 fg gauntlet` ran green, its tally naming the same 20 legs as
`legs_pending`, in 37 minutes (the first, failing run took 44). The first step's second half, every leg's command line
recorded as the table's fixture, is the table unit's launch census, taken before its first edit;
the table itself is its own unit.

---

## §8. A test is its macro

**Effort.** Two to three days: the player's start sequence, the loader, five classes deleted,
389 files re-emitted by a parser, the Node readers of those files, and a gauntlet with its
dpr-2 and finger legs.

**Evidence.**
- MEASURED: all 389 tests carry the same command sequence in
  `SystemTest_<name>_automationCommands.js`: `ResetWorld`, `TurnOnAnimationsPacingControl`,
  `TurnOnHidingOfWidgetsNumberIDInLabels`, `TurnOnHidingOfWidgetsContentExtractInLabels`, then
  one `StartMacro` with `millisecondsSincePreviousCommand: 200`. No test varies it.
- READ: the sequence is played by a cursor from the recorder's era
  (`AutomatorPlayer.replayTestCommands`): a wall-clock wait per command, each record given its
  class's prototype by name (`Object.setPrototypeOf`), and a special case whose comment says
  what is left of it: the three middle commands are dispatched "immediately, on back-to-back
  cycles", because that "fixes the macro's START CYCLE, which deferred-cleanup-sensitive shots
  depend on".
- READ: there are six command classes: a base and five commands, of which four are three code
  lines each. The three toggles they set are class statics that every test turns on at its
  start and every world teardown turns off, a mid-test snapshot load included (§5), so they
  are not constants under a test (§5 reads them at 11 core sites).
- READ: the loader and the phantom-pass guard both walk the sequence looking for the one
  `StartMacro` (`AutomatorLoader.loadImagesOfTest`, `AutomatorPlayer.stopTestPlaying`).
- READ: `Automator.clearCommandSeqAndImagesRelatedToTest` logs one line for each of 100
  possible image numbers at the end of every test ("we assume that no-one is going to write a
  test with more than 100 reference images"): about 38,900 console lines a suite run, which
  every runner relays and filters.
- MEASURED: "fail the current test" is written out five times in `AutomatorPlayer` (flag,
  failed list, counter, background, console), and the copies differ: the command-exception copy
  does not update the counter or the background.

**Why it matters.** A test has one moving part, its macro. The harness still models it as a
timed sequence of typed commands, and the model's remaining job is to reproduce its own timing.

**Fix shape.** Starting a test is one method: reset, set the determinism state, start the macro
at the cycle it starts at today. The test's file holds `mainMacroSource` and
`extraSubroutineSources` and nothing else (or the two test files become one: decide in the
plan). `AutomatorEventCommand` and its four small subclasses go; `StartMacro`'s checks
(`_checkMandatoryDescriptiveFields` and its two siblings, `screenshotImageNamesFromMacroSources`)
move to the player or the loader. The three toggles stay three statics, set by the start
method at the moments the three commands set them today. One `failCurrentTest message`. The
100-line loop clears the names the macro declares.

**Not in this item: folding the three toggles into "a test is playing".** A test that loads a
world snapshot mid-test runs on with the toggles off (§5), so the fold changes what those tests
draw. It is a decision of its own: recapture them, or keep the flip.

**Risk.** Low, and it is exactly one thing: the cycle on which the macro starts, relative to
the reset. The proof is the suite at dpr 1 and 2, mouse and finger, with zero reference
changes; `macroHoppingBetweenSubMenus` image 5 is the named canary. Every Node reader of the
test files must move in the same change. MEASURED: 15 tooling files name `_automationCommands`
(`grep -rl '_automationCommands' Fizzygum/buildSystem Fizzygum-tests/scripts Fizzygum-tests/.claude`):
the two definitions, `buildSystem/lib/tests-repo-code.js` (`testNames` requires both files)
and `scripts/lib/tests-manifests.js`; `check-tests-syntax.js`; a row of `gates.js`; ten
self-test fixtures; and the `/author-macro-test` skill's template. Readers that reach the
sources through those definitions (`lib/macro-sources.js`, the macro-source gate, the
visualisation pages, `aim-census.js`) follow them, and each must be run.

**First step.** Instrument the player to log the world cycle number at which each test's macro
takes its first step, over one suite run. That log is the fixture: the new start sequence must
reproduce it for every test before any test file is rewritten.

**Re-measure.**
`cd Fizzygum-tests/tests && grep -h '"automatorEventCommandName"' */*_automationCommands.js | grep -o 'AutomatorEventCommand[A-Za-z]*' | sort | uniq -c`
(five names, 389 each).

---

## §9. Instruction files: a budget and one home per fact

**Owner decision first** on what must stay always-on. The owner treats comments and docs as a
deliverable; this item changes where a story lives, not whether it is told.

**Owner ruling 2026-11-13.** Agreed, on the criterion under "Fix shape": a file keeps what
changes a reader's next action, and a story moves only to a home shown to tell it.

**Effort.** Two to three days: an inventory of each paragraph's other homes, the moves, and a
ratchet.

**Evidence.**
- MEASURED: the three instruction files a session loads when it touches both repos total
  171,280 bytes: the umbrella `CLAUDE.md` 21,782, `Fizzygum/CLAUDE.md` 49,133,
  `Fizzygum-tests/CLAUDE.md` 100,365. That is roughly 40,000 tokens before any work, in every
  session and again after every compaction.
- MEASURED: `Fizzygum-tests/CLAUDE.md` has single lines of 10,931, 7,341 and 4,522 characters.
- MEASURED: one gate's story has up to six homes. The menu sweep is told in its script header
  (about 140 lines), in `Fizzygum-tests/CLAUDE.md` (about 21,800 characters of lines naming it), in
  `Fizzygum-tests/package.json` (a `"//menu-sweep"` key of 1,656 characters), in `fg` (comments
  and usage), in `docs/architecture/lint-and-static-checks.md`, and in `Fizzygum/CLAUDE.md`.
  `package.json` carries eleven such comment keys, 16,029 characters.
- READ: the umbrella root also holds an `AGENTS.md` (7,310 bytes) that orients the same
  workspace in different words.
- READ: the instruction files already refuse to state a live count in prose (they point at
  `fg status` for the number of tests). A story with six copies is the same hazard: one of
  them is corrected, and the others go on being read.

**Why it matters.** The cost is paid per session, and a paragraph with six homes is corrected
in one. The first survey counted lines of code; this is the same count for the text every
session must read before it can start.

**Fix shape.** Each file keeps what changes a reader's NEXT ACTION: routing, the commands, the
rules with a consequence (never pipe a gating call, the tests link, ask before commit), and one
line per rig naming it and pointing at its header. A rig's mechanism, history and case law live
in its script header, which already holds them. `package.json`'s comment keys go, replaced by
one line each. Then a ratchet in the `check-doc-narration.js` family: a byte ceiling per
instruction file, lowered as files shrink.

**Risk.** Losing a warning that was only ever in `CLAUDE.md`. The inventory is the guard: a
paragraph moves only when its other home is shown to say the same thing; a paragraph with no
other home gets one first.

**First step.** For `Fizzygum-tests/CLAUDE.md`'s "Maintenance scripts" section alone (the bulk
of the file), list each paragraph with the header that tells the same story. Show the owner the
before and after of that one section.

**Re-measure.**
`cat CLAUDE.md Fizzygum/CLAUDE.md Fizzygum-tests/CLAUDE.md | wc -c` (from the umbrella).

---

## §10. The reference set: a path of live axes, then one file per reference

**Effort.** Step 1, one to two days: a pure rename of 8,092 files, one parser, the loader's
selection, the capture writers. Step 2, about three days: the loader's design, every reader of
a reference record, and a second mass change of the tree. Take them as one move if both are
approved: the tree is rewritten once.

**Evidence (step 1, the path).**
- MEASURED: every reference lives under
  `automation-assets/Mac-OS-X/10_15_7/Chrome/148_0_0_0/SWCanvas/ceilPixRatio_<N>/[finger/]`.
  The first five segments have one value across all 8,092 files. The live axes are the pixel
  ratio (1, 2) and the pointer kind.
- READ: the version segment is held constant by a spoof: the capture path overrides the
  browser's user agent with a canonical one so that files land under `Chrome/148_0_0_0`
  (`run-macro-test-headless.js`, grep `canonicalUA`; `run-paint-audit.js` does the same).
- READ: the loader selects by pixel ratio, pointer kind and, "when available", by OS
  (`AutomatorLoader.loadImagesOfTest`, `_checkIfthisTestHasImagesFromThisOS`). On any other OS
  it falls back to every asset, so the OS segment selects nothing in practice.
- READ: the harness's `SystemInfo.coffee` (213 code lines of user-agent sniffing) exists to
  fill those segments and the provenance record.
- READ: `docs/archive/reference-filename-grammar-plan.md` made this argument for the FILENAME
  ("the environment hash outlived the variation it was built to disambiguate") and left the
  directories, naming them as axes that "can legitimately change pixels". For SWCanvas
  references that holds for the pixel ratio and the pointer kind only: the same plan records
  that output is identical across OS, browser and engine, which the WebKit leg proves on every
  gauntlet by matching Chrome-captured references.

**Evidence (step 2, the format).**
- MEASURED: each reference is stored twice: a `.png` (30.2 MB in all) and a `.js` (45.8 MB)
  that pushes a record holding the same PNG as base64 into `AutomatorPlayer.loadedImages`. The
  tests repo's pack is 3.24 GiB, and every recapture adds both copies to it.
- READ: comparison needs none of the pixels. `matchOrRecordSWCanvasScreenshot` compares the
  live raw-pixel hash with each candidate's `hashOfData`, and that hash is in the filename
  (`-dataHash<sha256>`), as is the automator version; the generated `testsAssetsManifest.js`
  already lists every filename.
- READ: the loader appends one `<script>` per reference to `document.head` for the life of the
  page and tracks their loads, with a fallback timer. `docs/BACKLOG.md` holds an open defect of
  exactly this step: a reference that never loaded reports as a pixel mismatch.
- READ: at run time a record's pixels were read in one place, the in-browser difference image
  of §4; since §4 landed (2026-11-14) nothing reads them, so step 2's dependency on §4 is met.
  `check-refs.js --pixels` (the gauntlet's `refs` leg, about 4 minutes) exists to catch a `.js`
  whose stored hash and pixels have drifted apart, which is a failure only a second copy can
  have. Its other half, re-hashing each PNG against the hash in its name, stays.

**Why it matters.** The reference set is the suite's ground truth, and half its bytes and all
of its loading machinery serve a variation (native forks) and a consumer (the in-browser zip)
that are gone or going.

**Fix shape.**
- **Step 1.** `automation-assets/ceilPixRatio_<N>/[finger/]<file>`. `scripts/lib/refpaths.js`
  is the one parser and changes first. The loader drops its OS logic; the capture path drops
  the spoof; `SystemInfo` shrinks to what the record still says, or goes with step 2.
- **Step 2.** A reference is its `.png`. The loader builds each test's candidates from the
  manifest's filenames (name, version, hash) and loads nothing. The record's provenance blob
  goes, since every value in it is constant. `SystemTestsReferenceImage.createJSContent`, the
  script-load tracker and the `.js` half of every capture writer go.

**Risk.** No pixel changes: step 1 moves files and step 2 deletes a copy. The risks are
readers. Every script that walks the tree must go through `refpaths.js` (check
`check-refs.js`, `check-visualisations.js`, `make-visualisation.js`,
`recompress-swcanvas-references.js`, `recapture.js`, `capture-macro-test-references.js`,
`macro-page-lib.js`, and the self-tests that spell the path: `check-refs-selftest.js`,
`check-visualisations-selftest.js`). Every committed `visualisation.html` embeds reference
paths and must be regenerated in the same commit (`check-visualisations.js` fails the build
otherwise). Step 2 needs §4 decided first: with the in-browser difference image kept, a record
still needs its pixels.

**First step.** For step 1: `git mv` one test's references to the new shape on a scratch branch,
update `refpaths.js`, and run that test under mouse and finger at both densities and under
WebKit. For step 2: a prelude that makes the loader ignore every record's `imageData` and
`systemInfo` for one full suite run; a green run is the proof that comparison needs neither.

**Re-measure.**
`git -C Fizzygum-tests ls-files tests | grep automation-assets | sed -E 's#tests/[^/]+/automation-assets/##; s#/[^/]+$##' | sort | uniq -c`.

---

## 11. Measured and deliberately not listed

- **The other built-in prototype patches.** Seven conveniences with one to six call sites each,
  none on `Object.prototype` (§2's "Measured and left").
- **`serialization-roundtrip-headless.js`.** 5,262 lines in one file, the largest in either
  repo. The first survey's §11 left it; nothing has changed.
- **`build_it_please.sh`.** 665 lines, of which 245 are comments. What remains after the gate
  table is sequencing, the tests link and the boot bundle's assembly. Not a second language for
  one fact any more.
- **The flat top level of `src/`.** 101 class files. Same verdict as the first survey: a
  navigation benefit only, to take when a subsystem is reworked.
- **`FrameWdgt`'s docking family.** The first survey's "second candidate", still unexamined
  (`docs/BACKLOG.md`). `FrameWdgt` holds 173 methods and three roles (window chrome, dock host,
  pop-up lifetime). The docking family is about 25 methods, but its slots are layout specs the
  frame's own `_reLayout` reads, so a seam is UNVERIFIED and this survey did not establish one.
- **`src/macros` living in the Fizzygum repo while belonging to the `harness` part.** Moving it
  beside the harness would make the part one directory, but the toolkit reads core internals,
  and keeping it in the framework repo lets a core rename and its toolkit fix be one commit.
  A trade, not a cleanup.
- **The shell-class census.** 218 of 547 source files hold 12 code lines or fewer. The families
  are the icon shells (72 classes, the first survey's §9, open) and the creator buttons (37
  classes, owned by `plans/creation-and-templates-plan.md` §4.3).
- **The harness's control panel.** `AutomatorPlayer` writes the panel's DOM directly at 12
  places beside `SystemTestsControlPanelUpdater`'s 5. Worth folding into §8's
  `failCurrentTest`, not an item of its own.

## 12. Already owned elsewhere (not listed again)

| Topic | Owner |
|---|---|
| Icon shells: one `IconWdgt` and a derived catalog (and `DemoMenus`' roughly 60 `create…IconWdgt` methods) | `plans/top-10-cleanups-plan.md` §9 (kept open by the owner) |
| The creator-button and toolbar-button classes | `plans/creation-and-templates-plan.md` §4.3 |
| Two icon-appearance generations and pixel icons | `plans/pixel-icons-plan.md` |
| LiveCodeLang, `LCLCodePreprocessor`, `LCLProgramRunner` | `plans/livecodelang-cleanup-and-extensions-plan.md` |
| Every gate re-masking all sources (about 13 s a build) | BACKLOG, under `archive/argument-holes-both-repos-plan.md` |
| The similar-code mirror nobody runs | BACKLOG, same section |
| A screenshot whose reference never loaded reads as a mismatch | BACKLOG, "Tooling arc 2026-10-29" (§10 step 2 dissolves it) |
| Whether `waitForFunction` works today | BACKLOG one-liner (§2 closes it) |
| `fg` still naming mixins in two places | BACKLOG one-liner (§7 touches the same text) |

## 13. Case law that bounds these items (do not re-attempt blind)

- **A retired identity axis may still group something.** The filename-grammar arc's lesson
  (`docs/archive/reference-filename-grammar-plan.md`): before removing an axis, ask what else
  grouped by it. For §10 that is the ambiguous-references guard, which groups by directory and
  automator version, and `check-refs.js`'s duplicate rule over (test, image, density, OS).
- **A reference is never recaptured to make a change pass.** §8 and §10 expect zero pixel
  changes. A difference there is a finding about the change, to be attributed before anything
  is captured (`Fizzygum-tests/DETERMINISM.md`).
- **The automator version means "what the harness captures".** Neither §8 nor §10 changes that,
  so neither bumps it (`Fizzygum-tests/CLAUDE.md`, "BUMPING the Automator version").
- **The three test toggles flip at every world teardown, on purpose**
  (`WorldWdgt.fullDestroyChildren`, the comment over `_resetAutomatorTogglesNoSettle`): moving
  or folding them changes pacing under a running test that loads a snapshot. §5 and §8 leave
  them where they are.
- **A blanket script edit of structured files has cost the project before** (a `perl -pi`
  de-indenting CoffeeScript). §3, §8 and §10 parse and re-emit, then diff.
- **The determinism core was assessed and left** (`docs/archive/god-class-decomposition-plan.md`,
  Tier 4). §5 renames a question the core asks; it moves no decision out of the hand or the
  world cycle.
- **A gate that was ported is a gate that may have stopped biting.** Every gate's every rule is
  planted by a self-test (`docs/architecture/lint-and-static-checks.md` §3). §6 and §7 are done
  when those proofs pass unchanged.
- **A "pixel-neutral" expectation is a hypothesis until measured.** Every item above that
  expects zero reference changes says how to confirm it.

## 14. Shared verification protocol

Invoke the wrapper by absolute path; never pipe a gating call through a filter.

```
/Users/davidedellacasa/code/Fizzygum-all/fg status      # orient: heads, dirty counts, build freshness, verdicts
/Users/davidedellacasa/code/Fizzygum-all/fg build       # every static gate and every gate's bite proof
/Users/davidedellacasa/code/Fizzygum-all/fg presuite    # inner loop: build, dpr-1 suite, paint audit, fracplane rider
/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet    # commit point: 20 legs, run in the background, log to a file
/Users/davidedellacasa/code/Fizzygum-all/fg homepage    # production profile boot and snapshot round-trip (§1, §2)
/Users/davidedellacasa/code/Fizzygum-all/fg fingerprint # build-tree diff against a baseline ref (§1, §4)
```

Items that touch `tests/` (§8, §10) rely on the gauntlet's `finger` leg as much as on its
mouse legs, and must leave every reference's bytes alone. For §8 no path under
`tests/*/automation-assets/` changes at all. For §10 step 1 every staged change there is an
exact rename:
`git -C Fizzygum-tests diff --cached -M100% --name-status -- 'tests/*/automation-assets' | grep -vc '^R100'`
prints 0.

## 15. References

- `Fizzygum/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md`, `Fizzygum-tests/DETERMINISM.md`
- `docs/README.md` (filing rules), `docs/BACKLOG.md`, `docs/archive/INDEX.md`
- `docs/plans/top-10-cleanups-plan.md` (the first survey; its §9 is open, its §10 is the
  precedent for §6 and §7 here)
- `docs/architecture/build-and-packaging.md` (§1, §4)
- `docs/architecture/lint-and-static-checks.md` (the gate index and the bite-proof rule; §6, §7)
- `docs/archive/reference-filename-grammar-plan.md`,
  `docs/archive/recorded-to-macro-migration-plan.md` (§8, §10)
- `buildSystem/gates.js`, `buildSystem/run-gates.js`, `buildSystem/lib/what-runs.js` (§7)
- `Fizzygum-tests/scripts/lib/refpaths.js`, `scripts/lib/gate-bite-proof.js` (§10, §6)

## 16. Start prompt for a fresh session

```
Read Fizzygum/docs/plans/top-10-cleanups-round-2-plan.md in full (a survey of ten candidate
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

- [x] §1 (½ day): class source text ships as a plain string literal (`JSON.stringify`) — the three-glyph escape, its decoder in `SourceVault.store` and the build's refusal go
  — CLOSED 2026-11-13 (loop U1): `STRING_BLOCK` writes JSON string literals; the escape, its decoder and the refusal
  are gone (§1, "Landed").
- [x] §2 (½ day): `hashCode` leaves `Object.prototype` for a boot function — then measure `waitForFunction` and close the one-liner below that asks
  — CLOSED 2026-11-13 (loop U2): `hashOfString` in `src/boot/globalFunctions.coffee`; `Object.prototype` carries no
  enumerable key (§2, "Landed").
- [x] `archive/mixin-removal-plan.md` §7 Phase 8 (found by its U9 sweep, unmeasured): `Fizzygum-tests/scripts/run-all-headless.js` (~:18) and `run-macro-test-headless.js` (~:15) say Fizzygum's patched built-in prototypes make `waitForFunction` throw in the page. The cause measured at U9 was an inherited ENUMERABLE key on `Object.prototype` (`Object::augmentWith`, now deleted), which Puppeteer's injected bundle turns into a getter and calls; `hashCode` is the one such key left and survives the call. Whether `waitForFunction` works today is unmeasured — measure it, then correct the two comments (and keep or drop the polling-by-evaluate rule they justify).
  — CLOSED 2026-11-13 (loop U2; filed under BACKLOG's "One line each" section, owner `archive/mixin-removal-plan.md` §7
  Phase 8): MEASURED — `page.waitForFunction` works on the harness page and `index.html` (Puppeteer) and on the harness
  page (Playwright WebKit), both before U2 (`hashCode` survived the call) and after (no enumerable key); the comments
  say so, and the rigs keep their bounded, named polls as a choice (§2, "Landed").
- [x] §3 (½ day): map outlines are data — 2,638 `lineTo` statements in two files become coordinate tables and one loop, proven by an operation log
  — CLOSED 2026-11-13 (loop U3): `@outlines` tables and one loop in each map appearance; the operation logs are
  byte-identical (§3, "Landed").
- §7, in part — the line read: "§7 (2 to 3 days): the `fg` leg roster as a table. **A defect stands until then: `FG_GAUNTLET_SERIAL=1 fg gauntlet` runs 17 of the 20 legs (`parts`, `storage` and `vmtruth` are missing) and prints OK** — a three-line fix of its own, the item's first step". — LANDED IN PART 2026-11-14 (loop U4): the serial path
  runs all 20 legs (§7, "First step landed"). BACKLOG keeps the table.
- [x] §4 (½ to 1 day): the in-browser failure zip, a second and ungated way to capture references, with the vendored JSZip and FileSaver (the owner ruled 2026-11-13: delete)
  — CLOSED 2026-11-14 (loop U5): the zip, its two libraries, its two menu rows and the counter's download are gone
  (§4, "Landed").
- [x] §5 (1 day): one seam for "a test is playing" — 46 lines in 15 core files name the harness, in two spellings; the hand fades the harness's DOM
  — CLOSED 2026-11-14 (loop U6): `aTestIsPlaying()` asked at the 17 sites; the hand's harness DOM in
  `ActivePointerTestSupport` (§5, "Landed").

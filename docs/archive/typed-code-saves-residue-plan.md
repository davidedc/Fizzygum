# Typed-code saves residue: tool-code lines outside an assignment, a sequence run of names it cannot play, and a census that reads prose

**STATUS (2026-11-06): CLOSED — all three units done in one session, ARCHIVED.** Owner rulings: D1 = (a) refuse,
D2 = (a) read code and triage now. The units ran in the order 1 → 2 → 3.

**Closing gates (after the review fixes, on the committed tree):**
- `fg gauntlet`: 19/19 OK, no retries, 881 s;
- `npm run selftest` OK;
- the census `--self-test` PASS;
- `check-visualisations --strict` OK.

`fg homepage` was not run: neither `src/boot` nor `src/meta` changed. One independent end-of-arc review; its findings are folded into the ledger. The residue is in BACKLOG. The text below is the plan as executed.

Ledger (one entry per landed step; proofs inline):
- **Owner rulings (2026-11-06).** D1 = **(a) refuse** in the one parse (§2.2). D2 = **(a) read code, and triage
  now** per §3.3 (§3.2).
- **Unit 1 (2026-11-06).** `run-sequence-headless.js` refuses, exit 2 and nothing played, any name with no
  `tests/<name>/` directory (before a browser launches) and any named test the page's `testsList()` drops (after the
  selection, before playing: pointer-kind skips quote `mouseOnlyReason`, others name `SWCanvasBrokenTests`). The
  post-run `missing` is gone. The header and `Fizzygum-tests/CLAUDE.md`'s bullet state the exit contract.
  - Proofs:
    - `SystemTest_noSuchTest`: exit 2, 0 s, no browser.
    - `[AnalogClockInspectEdit, noSuchTest]`: exit 2, 0 s.
    - `--pointer=finger HoverMovePositionMappedInRotatedIsland`: exit 2, 3 s, reason quoted. Before the fix it
      exited 0 in 3 s with "ran : <name>".
    - The same plus a playable test: exit 2, nothing played.
    - Plant `.scratch/residue/u1-broken-at-dpr1-plant.js` (AnalogClockInspectEdit listed in
      `SWCanvasBrokenTests.testNamesDpi1`): exit 2, "filtered out at this density".
    - The real pair `[ToolCodeSaveRefuses…, AnalogClockInspectEdit]`: exit 0, both played in order.
  - Gate: `fg presuite` OK (dpr1 93 s, 373 tests, 0 failed, 0 gate violations; paint 152 s; fracplane 5 s — the
    fracplane rider runs through this runner).
- **Unit 2 (2026-11-06), D1 = (a).**
  - **Code.** `Widget.compilePropertyAssignments` checks each gap between the splitter's matches (and the tail)
    with the new `Widget._refuseCodeOutsideAssignments`. That throws an `isCompileError` refusal at the first
    line that is neither blank nor a comment, with `typedLocation = {line}` (no column) mapped back to the typed
    text. `_informOfCompileErrorOrRethrow` prints a column-less location as `line N`. The save's comment
    (`CodeInjectingSimpleRectangularButtonWdgt.modifyCodeToBeInjected`) and `widget-authoring-guidelines.md` §9
    say so.
  - **Mapping probe** `.scratch/residue/u2-line-mapping-probe.js`: on 20,000 random blurbs (12,520 refused) the
    mapped line is the offending typed line every time, and the eight named shapes give their expected lines
    (`a = 1\n@foo()\nb = 2` passes: a continuation runs, out of class).
  - **Test.** `SystemTest_macroToolCodeSaveRefusesCodeThatDoesNotCompile` gains:
    - the unarmed eraser's OK on `hoverMoved = … / foo() / pressMoved = …`: title exactly `Cannot save this as
      code (line 2): not inside a name = value assignment`, source unchanged, prompt open, no Error log;
    - a direct `injectProperties` of the after-comment blurb: refused at `typedLocation.line` 3, `hoverMoved`
      unchanged.

    Its metadata is updated and its visualisation regenerated.
  - Gate: `fg presuite` OK (dpr1 93 s, paint 148 s, fracplane 5 s).
- **Unit 3 (2026-11-06), D2 = (a).**
  - **Reader.** `buildSystem/lib/coffee-mask.js` holds `maskLine`, moved out of the census byte-identical (the
    census re-exports it for `census-hierarchy-duplication.js`), plus `codeOfCoffeeLine`.
    `buildSystem/lib/tests-repo-code.js` yields the tests repo's code:
    - harness `.coffee`, read by `maskLine`;
    - the macro command files: CoffeeScript bodies read by `maskLine`, the JS around them with full-line comments
      cut;
    - `scripts/**/*.js` with full-line comments cut (`node_modules` excluded);
    - nothing else.

    A probe (`.scratch/residue/u3-js-comment-variants.js`) found that cutting trailing `//` comments too changes
    nothing, so the reader keeps the cut that can never cut code.
  - **Census.** R4's external harvest is the reader; its header says so. R4 = 148 (it was 120), exactly the probe's
    prediction, and the census runs in 354 ms (it was ~500: the 45 MB of reference records are no longer read).
  - **Self-test.** `census-public-private-calls.js --self-test` gains 17 reader cases: what the code names, what
    comments, prose, records, manifests and `node_modules` do not, and the unpaired-backtick fallback.
  - **Self-test mutants** (a copy in `.scratch/residue/bsm/`): each turns the self-test red.
    - M1 reads metadata: 2 failures.
    - M2 keeps CoffeeScript comments: 2.
    - M3 drops `scripts/`: 3.
    - M4 keeps JS comments: 3.
  - **Triage (§3.3 as landed).**
    - Six names are `_`-renamed across `src/`, `MACRO-PATTERNS.md`, the live docs (`input-and-gestures.md`,
      `drag-embed-interaction-spec.md`, `affine-transforms-plan.md`, `livecodelang-cleanup-and-extensions-plan.md`,
      `DETERMINISM.md`) and 13 tests' prose and macro comments, whose visualisation pages are regenerated
      (`check-visualisations --strict` OK). `docs/archive/` stays verbatim.
    - Allowlist +12 (the 8 deliberate-API names, the 4 structural ones) and −4 stale (`setSoftWrap`,
      `recalculateOutput`, `addDragAffordanceWidgets`, `setLifetime`, which `scripts/` rigs call).
    - The structural reasons are measured, not argued. The `_` forms were tried, and the build's layering gate
      ([G] on `_addHighlightingWidgets`) or a direct run of the call-separation and layering gates (two [S]
      effectful, one [S] settling, one [G]) refused them. The two `.coffee` files of that direct run were edited
      by a ^-anchored perl from byte backups and restored from them; `git diff` is clean.
  - **Baseline.** `BASELINE_U_QUERY` 99 → 113, its reason in the ledger comment. `BASELINE_U_EFFECTFUL` stays HARD
    at 0.
  - **Plants on the real tree** (each reverted from a backup; `git diff` confirms no residue):
    - R1: the prose plant (a metadata `intent` newly naming `obfuscateAsPassword`). It stays in R4, and the gate is
      unmoved at 113/113.
    - R2: the scripts plant (the serialization rig's `ci.applyPropertyEdit(` written as a computed name). R4 lists
      `applyPropertyEdit`, and the gate FAILS: "QUERY self-only public methods: 114 EXCEEDS the baseline 113".
  - `fg build` OK: `[call-separation] OK — [S] 0/0 + 0/0; [U] 0/0 effectful + 113/113 query (29 allowlisted)`,
    dead-methods and unresolved-sends OK.
  - **`fg presuite` FAILED: 6 tests at dpr1, the same 6 on the serial retry.** All six are pixel mismatches, no
    assertion: `macroAddEditSaveRenameRemoveProperty`, `InspectorResizingOKEvenWhenTakenApart`,
    `InspectorScrollbarUnplugged`, `MovingSlidersSidewaysDoesntCauseContentToMoveSideways`,
    `MultilineTextInputScrollsWell` and `WrappingTextFieldResizesOK`. Paint and fracplane passed.
    - All six are in the derived inspector churn set (`scripts/inspector-churn-set.json`).
    - Attribution (`.scratch/residue/u3-diffbox.js` on `WrappingTextFieldResizesOK_image_1`): 11,980 pixels
      differ, all inside the inspector's member list (x 10..241, y 153..324). The renamed
      `_extendSelectionUpToSlot` now sorts among the `_` members.
    - That is the owner's standing "just recapture" class, so `fg recapture-inspector` (mouse + finger,
      dpr 1 + 2, gated).
    - Recapture: RECAPTURE-INSPECTOR OK, 15 tests, mouse + finger, 11 min, both pointers "RECAPTURE COMPLETE — the
      full suite is GREEN at every recaptured density". References changed for the six plus
      `macroNakedInspectorRendersResizesAndEdits`. `check-visualisations --strict` OK.
- **Gauntlet before the review (19:04):** 19/19 OK, no retries, 896 s. `npm run selftest` OK.
- **End-of-arc review (2026-11-06):** an independent fresh Opus agent was given both diffs and the plan's goals,
  not this ledger. 10 findings:
  - **R1, bug.** run-sequence's pre-check used `existsSync`, which on macOS answers any letter case. Its in-page
    check compared against the SELECTION. So a wrong-case name, or a name a hand-cut `--keep-manifests` manifest
    lacks, was dropped and the run exited 0.
    - Fix: exact directory names (`readdirSync`), and `testsList()` compared against the NAMED list, with the
      reason "not in this run's tests manifest".
    - Proof: the wrong-case name exits 2 in 1 s. The hand-cut manifest (AnalogClockInspectEdit removed) exits 2
      in 2 s with that reason. The real pair exits 0.
  - **R2, bug.** A `###` block comment was refused as code. Pre-existing: a `name = value` line inside one was
    injected.
  - **R3, bug.** Pasted CRLF gave fractional typed lines and refused blank lines.
  - **Fix for R2 and R3:** `Widget._blurbAsTyped`, run before the split, line for line. It turns CRLF/CR into
    "\n", and each top-level `###` block's lines gain a leading `#`. The gap rule's blank test is `\s`.
    - Mapping probe extended (`###` and CRLF in its vocabulary, the review's inputs as fixed cases): 20,000 random
      blurbs, 13,084 refused, all exact.
    - The tool-code test gains a `###` case (not refused; probeA 1 and probeC 3 injected, probeB not), a CRLF
      stray call (line 1) and a CRLF blank line (not refused, probeF 6).
    - Plant `.scratch/residue/rev-blurb-as-typed-plant.js` (`_blurbAsTyped` the identity): the block case fails
      ("line 3 … not inside", probeA/probeC undefined), and the CRLF line reads 1.5. The CRLF blank line passes
      under that plant too, because the `\s` blank test also covers it.
    - Follower clean on mouse and finger.
  - **R4, risk/doc.** The reader's "never invents a candidate" claim was false. A `#` inside a regex literal, a
    multi-line "…" string or a quote nested in `#{}` (`maskLine`'s misreadings), and a JS line starting with `/*`
    inside a template literal (it opened a block running to the next `*/`), can cut code.
    - Probe: cutting only line-start CoffeeScript comments would mask `evaluationMenu` (named in a trailing
      comment), so the landed cut stays.
    - The JS block now continues only while its lines look like comment lines; a probe shows no name lost (302 =
      302).
    - The header and the doc state the true limits, the loud failure mode, and the reviewer's measurement: no
      code cut in today's corpus.
  - **R5.** The reader read gitignored `scripts/.scratch/`. Fix: dot-directories are skipped.
    - The self-test adds `scratchProbe` (must not count) and `afterTemplate` / `later` (code after a `/*` inside a
      template must count). A copy with both fixes reverted FAILS those 3 cases.
  - **R6.** The baseline ledger cited 104 → 101 for `catchesPointerAt`, which belongs to 106 → 104. Fixed in the
    gate's comment and in §3.1.
  - **R7.** The BACKLOG item for adopting the reader was promised but missing. Filed at the archive (below).
  - **R9.** A historical observation in `livecodelang-cleanup-and-extensions-plan.md` (old line numbers) had been
    renamed. Reverted to the name the code then had.
  - **Kept, with the reason:**
    - R8: a column-0 `else` is refused with "not inside a name = value assignment". The refusal is right; it
      catches a pre-existing silent drop of the else branch.
    - R10: `fg`'s leg headline shows the run-sequence line. That is local tooling, and exit 2 still fails the
      leg.
- **Closing gauntlet (19:22, the final tree):** 19/19 OK, no retries, 881 s. `npm run selftest` OK. The plan is
  archived, with an INDEX line. The three BACKLOG items moved into the ledger below, and the residue item (the
  other tests-repo readers) is filed under this plan's name. It passes alone, and the follower
    `[it, AnalogClockInspectEdit]` passes on mouse and finger with zero `WORLD_INVENTORY_` lines.
  - **Plants.**
    - `.scratch/residue/u2-no-gap-rule-plant.js` (the rule a no-op): the four eraser assertions FAIL ("refusal is
      shown", "names the line", "source unchanged", "OK did not close"), and the macro then stops at the missing
      message.
    - `.scratch/residue/u2-inject-only-plant.js` (`injectProperties` alone without the rule): only the direct
      case FAILS ("refused at its typed line — found undefined", "injects nothing").
  - `fg build` OK.

**Mandate: eliminate each class, not its known member.**
- Unit 1: no named test that `run-sequence-headless.js` cannot play reads as anything but "nothing was measured".
- Unit 2: no line of a tool-code blurb is stored and then never run without the person being told (subject to D1).
- Unit 3: no public method leaves rule [U]'s self-only census because prose names it, and none stays in it while
  test tooling really calls it (subject to D2).

Each unit ends with a check that fails when a new member of its class appears, proven by a plant that makes it fail.

---

## §0 Orientation

**Fizzygum** is a CoffeeScript GUI framework rendered on one HTML5 canvas; `Fizzygum-all/` holds three sibling
repos: `Fizzygum/` (source + build), `Fizzygum-tests/` (the SystemTest suite, the harness, and the Node `scripts/`
that drive it), `Fizzygum-builds/` (generated). Read `Fizzygum-all/CLAUDE.md` first; it routes to each repo's own.

**The prior arc** is `docs/archive/typed-code-saves-and-error-tokens-plan.md` (CLOSED and pushed 2026-11-06:
Fizzygum `219320fe`, Fizzygum-tests `312ae9a20`). It made five save routes refuse typed code that does not compile,
tokenized every `console.error`, and made the three test runners fail-closed. It left three items in
`docs/BACKLOG.md` under its name. This plan works them. Read that plan's §1 (Unit A) and its ledger's review
findings F3 and F7: they shaped the tool-code save this plan's Unit 2 extends.

**Critical reframes found while verifying the BACKLOG items against current code (2026-11-06):**
- Unit 1 is TWO defects, not one. Given only unknown names the runner plays the whole manifest (exit 1, ~3 min),
  AND given a real test the page then filters out (a mouse-only test under `--pointer=finger`, or one in
  `SWCanvasBrokenTests` for the density) it plays NOTHING, prints `ran : <name>` and exits **0**. Measured:
  `run-sequence-headless.js --pointer=finger SystemTest_macroHoverMovePositionMappedInRotatedIsland` exits 0 in 3 s.
- Unit 2's class is wider than "`foo()` between assignments". The splitter drops ANY text outside an assignment's
  value. That includes an INDENTED line that follows a column-0 comment: CoffeeScript reads it as part of the
  function above the comment, but the splitter ends that value at the comment.
- Unit 3 is not one name. Reading only code, 40 public methods join the self-only census, not just
  `applyPropertyEdit`: 21 effectful, against a baseline held HARD at 0, and 19 queries. And the census has a blind
  spot in the other direction too: it never reads `Fizzygum-tests/scripts/`, whose `page.evaluate` bodies call core
  methods (`applyPropertyEdit` among them), so it can list a method as self-only while a gauntlet rig calls it.

House rules for the executing session (all from the workspace CLAUDE.md files and the owner's standing rules):
- `fg` only by absolute path, `/Users/davidedellacasa/code/Fizzygum-all/fg <cmd>`; never pipe a gating fg call.
  Long ops (`fg gauntlet`, `fg presuite`) run in the background, with an ETA up front and a status every ~5 min.
  A running fg op OWNS `src/`, `tests/` and `scripts/`: edit only docs and memory meanwhile.
- Edit `.coffee` with the Edit tool only (never perl/sed). Comments and docs are present tense.
- Node probes and plants live in `Fizzygum-tests/.scratch/` (gitignored). A plant's own `console.error` must OPEN
  with an ALL-CAPS token (`PLANT_NOT_APPLIED: …`), or the fail-closed runners fail the test on the plant itself.
- A check is believed only after a plant has been seen to make it fail.
- zsh: pass a list of test names as an array, `N=(a b); cmd "${N[@]}"`; quote `--include='*.coffee'`.
- Never commit or push without the owner's explicit approval of that commit; `git commit -F <file>`.

---

## §1 Unit 1 — `run-sequence-headless.js` refuses any name it cannot play

### §1.1 Current state (grep the names; line numbers drift)

`Fizzygum-tests/scripts/run-sequence-headless.js` normalizes the names (`names = argv.filter(…).map(n =>
n.startsWith('SystemTest_') ? n : 'SystemTest_' + n)`), boots the harness page, and in one `page.evaluate`:

```js
world.automator.loader.selectTestsFromTagsOrTestNames(names.slice());
await until(() => world.automator.selectedTestsBasedOnTags && world.automator.selectedTestsBasedOnTags.length >= 1, 20000);
const found = world.automator.selectedTestsBasedOnTags;
world.automator.selectedTestsBasedOnTags = names.filter((n, i) => found.includes(n) && names.indexOf(n) === i);
const selected = (world.automator.selectedTestsBasedOnTags || []).slice();
world.automator.player.runAllSystemTests();
```

Only AFTER the run does Node compute `missing = names.filter(n => !result.selected.includes(n))`, print
`⚠ not found in the build (skipped)` and fold it into exit 1.

Two harness facts make that wrong (`Fizzygum-tests/Automator-and-test-harness-src/AutomatorLoader.coffee`):
- `selectedOrAllTests` answers the WHOLE manifest when the selection is empty. So all-unknown names play the whole
  suite, after a 20 s wait for a selection that never comes.
- `testsList` filters the selection AFTER it is made: `SWCanvasBrokenTests` per density, then the run's pointer
  kind (`testRunsUnderPointerKind`). A named test filtered there is in `selected`, so it is not `missing`, and it
  never plays. With nothing else named, the run plays zero tests and exits 0.

The single-test runner already refuses both, before playing (`run-macro-test-headless.js`, `drivePage`):
`selectionError` (exit 2), `skipped` for a pointer-kind skip (exit 2, `mouseOnlyReason` quoted) and `filteredOut`
for any other filter (exit 2). `recapture.js` refuses a non-test name up front with `isTestName` (a
`tests/<name>/` directory; exit 2). Exit 2 is the runners' "nothing was measured" family.

### §1.2 Fix shape (a tooling decision: no owner ruling)

1. In Node, before launching a browser: every name must be a test, by the same test as `recapture.js`
   (`tests/<name>/` exists). Any that is not: print them, exit 2. No browser, so it answers in about a second.
2. In the page, after the selection and the reorder, and BEFORE `runAllSystemTests`: ask
   `world.automator.loader.testsList()`, the list the player will play. It must equal the named list (deduplicated,
   in order). If a name is missing from it, return without playing. Node prints each such name with its reason
   (the pointer-kind skip's `mouseOnlyReason` from `testsSkippedByPointerKind()`, else "filtered out for this
   density, see SWCanvasBrokenTests") and exits 2.
3. Delete the post-run `missing` computation: both refusals make it unreachable.
4. The header comment and `Fizzygum-tests/CLAUDE.md`'s `run-sequence-headless.js` bullet say so: "Exit 0 iff every
   named test played and passed; exit 2 when any named test cannot be played (no such test, or this run's pointer
   kind or density filters it out); nothing is played then."

### §1.3 Proof

- Before (measured 2026-11-06): the finger case above exits 0 in 3 s; all-unknown names play the manifest.
- After:
  - `SystemTest_noSuchTest` alone exits 2 in seconds with no browser launched.
  - `[SystemTest_macroAnalogClockInspectEdit, SystemTest_noSuchTest]` also exits 2, with nothing played.
  - The finger case exits 2, quoting the test's `mouseOnlyReason`.
  - A real pair, `SystemTest_macroToolCodeSaveRefusesCodeThatDoesNotCompile SystemTest_macroAnalogClockInspectEdit`,
    exits 0, with both played in the named order.
- These runs ARE the plants: each refusal is seen to bite on a real input that the old code passed or misplayed.

---

## §2 Unit 2 — a tool-code blurb whose code is not all assignments (D1)

### §2.1 Current state

A paint tool's code (the Drawings Maker's pencil/brush/toothpaste/eraser) is a BLURB: CoffeeScript holding
`name = value` assignments, each injected onto the painting surface as `@name = value`.
`Widget.compilePropertyAssignments` (`src/basic-widgets/Widget.coffee`) is the one parse:

```coffee
  @compilePropertyAssignments: (codeBlurb) ->
    codeBlurb = codeBlurb.replace(/^[ \t]*$/gm,"\n")
    codeBlurb = codeBlurb + "\n# end injected code"
    regex = /^([a-zA-Z_$][0-9a-zA-Z_$]*)[ \t]*=[ \t]*([^]*?)(?=^[\w#$])/gm
    assignments = []
    while (m = regex.exec(codeBlurb))?
      if m.index == regex.lastIndex
        regex.lastIndex++
      assignments.push name: m[1], source: m[2]
    for each in assignments
      … compileFGCode (Widget.propertyAssignmentSource each.name, each.source) …   # throws, naming `typedIn`
    assignments
```

- Each value runs from its `name =` up to the next line that STARTS with a word character, `#` or `$`: a
  "boundary" line.
- A boundary line that is not `name =` begins a stretch that no assignment owns: `foo()`, `a.b = 1`, `a += 1`, a
  column-0 comment, or anything before the first assignment. That stretch also covers the lines that follow it,
  up to the next assignment.
- The stretch is skipped. When it is code, the code is stored and never runs.

Callers of the parse:
- `Widget.injectProperties` (all-or-none);
- `CodeInjectingSimpleRectangularButtonWdgt.modifyCodeToBeInjected`, the tool-code SAVE behind the edit mark's
  `CodePromptWdgt`. It runs `compileFGCode newSource, true` (the text AS TYPED, giving exact error positions), then
  the parse, then stores.

The injectors are `ImageWdgt` (the pencil at build), `PaintToolbarWdgt` (the chosen tool), the button's
`injectCodeIntoTarget`, and one test, `SystemTest_macroEveryPressIsToldItsEnding`, which injects the shipped
toothpaste source directly.

What survives today (the shipped sources pass the as-typed compile and the per-assignment compile):
- `a = 1\nfoo()\nb = 2`: stored; `foo()` never runs.
- `a = ->\n  x\n# note\n  y\nb = 2`: stored. CoffeeScript reads `y` as part of `a`'s body, and the splitter ends `a`
  at the comment, so `y` never runs.
- `foo()` alone: stored; injects nothing.

Out of the class, stated so nobody re-reads it as a gap: a column-0 line that starts with anything else (`)`, `]`,
`@`, a quote) CONTINUES the value above it. That is what lets a multi-line value close at column 0. So `@foo()`
there runs as part of injecting that value: it runs, it is not dropped.

### §2.2 D1 — OWNER DECISION

- **(a) Refuse (recommended).** The parse refuses a blurb with any text outside an assignment's value that is not a
  blank or comment line, naming the line as typed: `Cannot save this as code (line 3): not inside a name = value
  assignment`. The rule is DERIVED from the splitter's own match spans (the gaps between them), so it cannot
  disagree with what is injected. Living in the one parse, it holds for every caller: the save refuses (nothing
  stored, prompt open, as for a compile error), and a direct `injectProperties` throws before injecting anything.
  - A blurb of only comments and blank lines stays legal: it says nothing and does nothing.
  - Shipped sources: PENCIL/BRUSH/ERASER/TOOL_OFF are assignments and indented bodies only. TOOTHPASTE adds column-0
    comment lines between assignments, which are comments. All pass (verified by the suite, which arms every tool).
- **(b) Document it as the format and keep it.** The splitter's skip becomes the stated rule in the save's comment
  and in `widget-authoring-guidelines.md` §9. Nothing refuses; a person who types `foo()` still loses it silently.

The question of WHERE the rule lives is folded into (a): in the one parse, not the save only. A save-only rule
would leave `injectProperties` with a second, looser notion of a blurb, and every caller of the parse should see
one definition.

### §2.3 Fix shape under (a)

1. `Widget.compilePropertyAssignments`: track the end of the previous match (`regex.lastIndex` after it). Before
   each match, and once after the last one up to the sentinel, check the gap's lines. Each must be blank
   (`/^[ \t]*$/`) or a comment (`/^[ \t]*#/`). The first line that is neither throws a refusal.
2. The refusal's place is the line AS TYPED. The parse runs on the reshaped text, where every blank line is doubled
   (`/^[ \t]*$/gm` → `"\n"`). So the typed line index of an offending (non-blank) reshaped line is: (non-blank
   lines before it) + (blank lines before it) / 2. Prove that mapping with a plain-node property check over random
   blurbs before trusting it (the probe lives in `.scratch/`).
3. The refusal is an `Error` marked like a compile error (`isCompileError = true`), with
   `cause = new Error "not inside a name = value assignment"` and `typedLocation = line: n` (NO column). The parse is
   where a blurb "compiles as a blurb", and the save's reporter (`Widget._informOfCompileErrorOrRethrow`) already
   keys off that mark.
4. The reporter prints a location with no column as `line N`. Today it always prints `line N, column M`.
5. Comments: the parse's header says what a blurb is (assignments, comments, blank lines) and that the parse
   refuses anything else, by its line. `modifyCodeToBeInjected`'s comment drops the "(a stray `foo(` between
   assignments)" example, which the as-typed compile catches, in favour of the new rule.
   `widget-authoring-guidelines.md` §9 (the typed-code save section) gains one sentence.

### §2.4 Proof under (a)

- A new case in `SystemTest_macroToolCodeSaveRefusesCodeThatDoesNotCompile`: an unarmed tool, the blurb
  `hoverMoved = (pos) -> return\nfoo()\npressMoved = (pos) -> return`, OK. The title is exactly
  `Cannot save this as code (line 2): not inside a name = value assignment`, nothing is stored, no Error log, and the
  prompt is still open.
- A second, direct case: `injectProperties` on the comment-then-indented-line blurb throws, and `hoverMoved` is
  unchanged.
- The test's `assertions` / `scenario` / `provenance` fields are updated. Its `visualisation.html` is regenerated
  (`node scripts/make-visualisation.js SystemTest_<name>`) BEFORE the gauntlet, or the refs leg fails.
- Plant (`PRELUDE_JS`): `Widget.compilePropertyAssignments` without the gap check (the old body, re-installed). The
  new cases must FAIL (stored silently / no throw). Then remove it; they pass.
- `fg presuite`: the shipped sources pass the rule (the suite arms every tool; `macroEveryPressIsToldItsEnding`
  injects toothpaste directly).

---

## §3 Unit 3 — the call census reads the tests repo's CODE, and all of it (D2)

### §3.1 Current state

- **The gate.** `check-call-separation.js` rule [U] fails the build on a NEW public method that only `@`-self calls
  reference. It reads R4 from `buildSystem/census-public-private-calls.js`:
  - `BASELINE_U_EFFECTFUL = 0` is HARD since an owner triage (T5, 2026-07-12);
  - `BASELINE_U_QUERY = 99` is a ratchet, with a long comment ledger;
  - `buildSystem/public-api-allowlist.txt` lists methods public on purpose, and a stale entry fails the build.
- **The external harvest.** R4's "never referenced outside src" half is `harvestExternal`. It counts EVERY word of:
  - `Fizzygum-tests/Automator-and-test-harness-src/*.coffee`, cut at the first `#` on a line (a `#` inside a
    string, as in `"#{x}"`, cuts the code after it too);
  - every `.js` file under `Fizzygum-tests/tests/`, with nothing cut:
    - the 373 macro command files: their CoffeeScript macro sources (code, strings, `#` comments) and the JS
      around them (`//` comments);
    - the 373 metadata files: descriptive prose only (`description`, `intent`, `scenario`, `assertions`,
      `provenance`, `tags`, …);
    - 4,018 reference-image records: base64 PNG plus a systemInfo blob, 45.5 MB of the 50.3 MB read;
    - the two generated, gitignored manifests.

  It reads strings ON PURPOSE: a menu row or a macro dispatches by name. Prose and comments are not dispatch.
- **It does not read `Fizzygum-tests/scripts/`.** Those Node rigs call core methods inside `page.evaluate` (the
  workspace CLAUDE.md: "scripts/ reads core internals as hard as any macro does").

Measured 2026-11-06 (probes `Fizzygum-tests/.scratch/r4-harvest-sources-probe.js` and `r4-codeonly-probe.js`; R4
today = 120 names, candidates 0 effectful + 99 query once the allowlist is applied):
- **Prose masks 40 names.** With the tests repo read as code only (macro CoffeeScript code and strings, macro-file
  JS outside `//` comments, metadata/records/manifests skipped), 40 names join R4: 21 effectful and 19 query.
  17 of them are named only in metadata prose; the other 23 also in macro `#` comments.
- **`scripts/` callers are missed.** Reading `scripts/` as code takes 12 names out again (real rig callers, plus
  `cmd`, a JS local's name — see §3.5). Among them are `applyPropertyEdit` (`serialization-roundtrip-headless.js`
  calls `ci.applyPropertyEdit(…)`) and four ALLOWLISTED names (`setSoftWrap`, `recalculateOutput`,
  `addDragAffordanceWidgets`, `setLifetime`). Those four entries would go stale.
- **Net under both changes:** 18 effectful candidates (gate: 0, HARD) and 113 query (gate: 99).
  - The 18 effectful: `scrollX`, `scrollY`, `dispatchEventsFollowingMouseMove`, `setHorizontalAlignment`,
    `setVerticalAlignment`, `updateDragEmbedStateMachine`, `addHighlightingWidgets`, `autoScroll`,
    `startAutoScrolling`, `discardPushedMatrix`, `extendSelectionUpToSlot`, `startSelectionUpToSlot`,
    `fitToExtent`, `goLeft`, `goRight`, `goUp`, `goDown`, `wrapContent`.
  - The 17 new queries: `slotAtRow`, `cleanupMenuWdgts`, `dropTargetFor`, `drawSelection`,
    `searchLargestFittingFont`, `searchLongestFittingTextByMultiCroppingIt`, `slotAtSingleLineString`,
    `catchesPointerAt`, `checkDraggingThreshold`, `evaluationMenu`, `fillPaletteBuffer`, `findFirstLooseWidget`,
    `hasStartingContentBeenChangedByUser`, `isLayoutChrome`, `maxWidthOfMenuEntries`, `obfuscateAsPassword`,
    `resolveDragEmbedCandidates`.
  - Three queries leave: `takeInventory`, `unregisterThisInstance`, `buildBaseWidgetClassContextMenu`.
- The reference records and manifests contribute no hit today; they are pure cost (and base64 can spell a short
  name by chance).
- `BASELINE_U_QUERY`'s ledger says 106 → 104 banked `catchesPointerAt` as "now asked from outside". In fact a test's
  metadata names it and no macro calls it. That entry was the same mask.

`lint-and-static-checks.md` (the paragraph after "On `census-public-private-calls.js` specifically") documents the
macro-comment half as an advisory blind spot. `check-dead-methods.js` reads the tests repo the same way and states
its own consequence there ("a method whose NAME is an ordinary English word is effectively unkillable"). Other
`buildSystem/` readers of the tests repo: `census-call-arity`, `census-property-placement`, `check-hand-lists`,
`check-relayout-repaints`, `check-unresolved-sends`.

### §3.2 D2 — OWNER DECISION

- **(a) Read code, and triage what it unmasks now (recommended).**
  - A shared reader, `buildSystem/lib/tests-repo-code.js`, yields the tests repo's CODE:
    - harness `.coffee` through the census's own CoffeeScript masker (`maskLine`; comments cut, strings kept);
    - each macro command file's CoffeeScript bodies (the backtick templates) through `maskLine`, and its JS
      outside full-line `//` / `/* */` comments;
    - `scripts/**/*.js` the same way (`node_modules` excluded);
    - nothing else.
  - The census's R4 harvest uses it.
  - The 18 effectful names are triaged per §3.3 (renames + allowlist entries, the T5 procedure). The four stale
    allowlist entries go. `BASELINE_U_QUERY` is re-banked to the measured number, with its reason in the ledger.
  - The `lint-and-static-checks.md` paragraph is rewritten to the new rule.
  - Adopting the reader in the other tests-repo readers (`check-dead-methods` first) is filed to BACKLOG: each may
    unmask findings of its own, which are that gate's arc.
- **(b) Read code, park the triage.** As (a), but `BASELINE_U_EFFECTFUL` becomes a ratchet at the measured count
  (18) instead of HARD 0, and the triage goes to BACKLOG. Cheaper now; it turns a hard gate into a debt.
- **(c) Keep reading prose; document it.** The census stays as it is; the doc paragraph also names metadata prose.
  `applyPropertyEdit` stays out of R4 because two sentences name it; the 40 stay masked and `scripts/` stays unread.

### §3.3 The triage under (a) — the 18 effectful names

The T5 procedure (`docs/archive/public-private-call-separation-plan.md` §6): a method public only so its own class can
call it gets the `_` prefix. A method that is deliberate user or scripting surface gets an allowlist entry with its
reason. Proposed:

| Name | Class | Proposal | Why |
|---|---|---|---|
| `goLeft` `goRight` `goUp` `goDown` | CaretWdgt | allowlist | caret keyboard verbs, siblings of the allowlisted `goHome`/`goEnd`/`deleteLeft`/`deleteRight` |
| `setHorizontalAlignment` `setVerticalAlignment` | StringWdgt | allowlist | user-facing setters (the align rows call them), sibling of `setSoftWrap` |
| `scrollX` `scrollY` | ViewportWdgt | allowlist | a pane's scroll-by verbs, siblings of `scrollToBottom`/`setScrollPolicy`, which macros call |
| `dispatchEventsFollowingMouseMove` `updateDragEmbedStateMachine` | ActivePointerWdgt | `_` rename | pointer machinery |
| `addHighlightingWidgets` | WorldWdgt | `_` rename | one in-class caller |
| `autoScroll` `startAutoScrolling` | ViewportWdgt | `_` rename | drag auto-scroll machinery |
| `extendSelectionUpToSlot` `startSelectionUpToSlot` `fitToExtent` | StringWdgt | `_` rename | click-selection and font-fitting machinery |
| `wrapContent` | TransformFrameWdgt | `_` rename | constructor helper |
| `discardPushedMatrix` | LCLTransforms | `_` rename | matrix-stack machinery |

**As landed** (the gates decided four of the ten): six renamed — `_dispatchEventsFollowingMouseMove`,
`_updateDragEmbedStateMachine`, `_extendSelectionUpToSlot`, `_startSelectionUpToSlot`, `_fitToExtent`,
`_discardPushedMatrix`. Four went to the allowlist with their structural reason:
- `addHighlightingWidgets`: [G], it destroys highlighters through the public `fullDestroy`;
- `autoScroll`: [S], it scrolls through the public `scrollX`/`scrollY`;
- `startAutoScrolling`: [S], its step drives the public `autoScroll`;
- `wrapContent`: [S]/[G], it builds through the public settling `add`.

A rename that a gate forbids becomes an allowlist entry that names the structural reason, as T5's did ("[A]
forbids the _-form"). The gates that can forbid it: call-separation [S] (a private method `@`-calling a public
command), layering [A]/[G], tier naming. Each rename must also be swept through both repos, `scripts/` included:
- the definition and every call;
- test prose and comments that name the method (prose rewritten to the new name; the edited tests' visualisation
  pages regenerated);
- docs.

The 17 queries are banked, not triaged: the query baseline has always been a ratchet drawn down by later arcs.

### §3.4 Proof under (a) or (b)

- `--self-test` gains cases for the reader:
  - a macro `#` comment naming a method is NOT a reference, and a macro string naming it IS;
  - a metadata file is not read;
  - a `scripts/` call IS a reference, and a full-line `//` comment there is not;
  - a harness `"#{x}" ; foo()` line still counts `foo`.
- Plants:
  - R1: a test's metadata prose newly names an R4 candidate (pick one: the R4 list prints it). The census must
    still list it (before the change it drops out). Revert.
  - R2: delete `serialization-roundtrip-headless.js`'s `applyPropertyEdit` call, in `.scratch/` copy form: point
    the reader at a fixture dir, or drive the self-test. R4 must then list `applyPropertyEdit`. Revert.
- `fg build` green with the re-banked numbers and the triage applied. The gate's [U] summary line records the
  counts in the ledger.

### §3.5 Stated limits (kept, not fixed)

- The census stays NAME-keyed. A JS local or a field with a method's name still counts as a reference (`cmd` in
  `build-tree-fingerprint.js` keeps `CaretWdgt.cmd` out of R4). That is the sound direction: it hides a candidate,
  it never demands a rename.
- Line-anchored JS comment stripping keeps a trailing `// …` comment's words as references (the same direction).
- A macro file whose backticks do not pair is read whole, comments included (the same direction; zero such files
  measured).
- In the OTHER direction (the review's R4), a few shapes can cut code. Each would invent a candidate and fail the
  build loudly, naming a method whose caller is plain to see:
  - `maskLine`'s misreadings of CoffeeScript: a `#` in a regex literal, a "…" string spanning lines, a quote
    nested in `#{…}`;
  - a JS line starting with `//` or `/*` inside a template literal (a `/*` block runs on only while its lines look
    like comment lines, so the cut is one line).

  A token-by-token comparison against real lexers found none in the repo (2026-11-06). Cutting only comments that
  start a line would avoid the CoffeeScript shapes, but it masks `evaluationMenu`, which a trailing comment names.

---

## §4 Cold-execution protocol

1. Orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status` (both repos clean at the arc's base SHAs,
   build FRESH). Read this plan's ledger; continue from the first step it does not record.
2. Owner decisions D1 and D2 in ONE `AskUserQuestion` round, each with its recommendation. Record the rulings in the
   ledger.
3. Unit 1 (no ruling): edit, run §1.3, then `fg presuite` (background, ~3–4 min). Ledger.
4. Unit 2 per D1: edit `Widget.coffee` (and `CodeInjectingSimpleRectangularButtonWdgt.coffee` comments), run
   `fg build`, run the mapping probe, extend the test and regenerate its visualisation, run the plant, run
   `fg presuite`. Ledger.
5. Unit 3 per D2: the reader + census change, `--self-test`, plants R1/R2, the triage (each rename built and gated,
   one class at a time), the allowlist and baseline edits, `fg build`, `fg presuite`. Ledger.
6. Close:
   - regenerate every edited test's `visualisation.html`;
   - `fg gauntlet` (background, ~17 min; ETA and ~5-min statuses);
   - `fg homepage` only if `src/boot` or `src/meta` changed (this plan expects neither);
   - `cd Fizzygum-tests && npm run selftest`.
7. ONE independent end-of-arc review: a fresh Opus agent given both repos' diffs and this plan's §1–§3, not the
   ledger's conclusions. Fold its findings in, re-gate what they touch.
8. Archive: `mv` this plan to `docs/archive/` (it is untracked until the commit, so a plain mv), stamp STATUS, add
   the `docs/archive/INDEX.md` line, move the three BACKLOG items into a `## BACKLOG ledger` section here, and add
   any residue to BACKLOG under this plan's name.
9. Draft the commit messages (one per repo) and WAIT for approval. Ask about push separately.

## §5 Verification summary

| Unit | Proof | Plant | Gate |
|---|---|---|---|
| 1 | bogus / mixed / finger-filtered / real pair runs (§1.3) | the runs themselves | `fg presuite` |
| 2 | the extended tool-code test (§2.4) | the parse without the gap check | `fg build`, `fg presuite` |
| 3 | census `--self-test` + the [U] summary (§3.4) | R1 prose plant, R2 scripts plant | `fg build`, `fg presuite` |
| all | — | — | `fg gauntlet`, `npm run selftest`, one review |

## §6 Rejected alternatives (do not re-attempt)

- **Unit 1: filter unknown names and run the rest (today's behaviour, minus the whole-manifest fallback).** A
  sequence run exists to reproduce an ORDER; dropping one name silently changes the experiment, and the result
  then reads as a pass or fail of a sequence nobody asked for. Refusal is the only honest answer.
- **Unit 2: refuse every column-0 line that is not `name =` or `#`.** It refuses `]`, `)` and a closing `"""` at
  column 0, which legitimately end a multi-line value today.
- **Unit 2: replace the splitter with the CoffeeScript parse (`CoffeeScript.nodes`, top-level `Assign`s).** It is
  the language's own reading. But it changes every injected value's text (blank-line doubling, the `_source` a
  function keeps, which serialization carries), it is a different arc, and the gap rule already closes the "dropped
  silently" class with the splitter unchanged.
- **Unit 3: skip only the metadata files.** That catches 17 of the 40 names. The other 23 are also masked by macro
  `#` comments, and `scripts/` would stay unread.

## §7 References

- `docs/archive/typed-code-saves-and-error-tokens-plan.md` — the prior arc: Unit A (§1), review findings F3/F7.
- `docs/archive/public-private-call-separation-plan.md` — rules [S]/[U], T4/T5 triage procedure.
- `docs/architecture/lint-and-static-checks.md` — the call-separation row and the census paragraph.
- `docs/architecture/widget-authoring-guidelines.md` §9 — typed-code saves.
- `Fizzygum-tests/CLAUDE.md` — the runners, the exit-2 family, `PRELUDE_JS` plants.
- Memory: `typed-code-saves-and-error-tokens.md`, `hand-lists-residue.md`, `public-private-call-separation-arc.md`.

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

Filed under `archive/typed-code-saves-and-error-tokens-plan.md`'s section; closed by this plan, 2026-11-06.
- [x] **A tool-code blurb's non-assignment line that IS CoffeeScript is still skipped silently** — Unit 2 (D1 = refuse):
      the one parse refuses code outside the blurb's assignments by its typed line, for the save and for
      `injectProperties` alike; `###` blocks and CRLF read as typed (review R2/R3).
- [x] **`run-sequence-headless.js` given only unknown names plays the WHOLE manifest** — Unit 1: any name it cannot play
      (no exact `tests/<name>/`, not in the run's manifest, or filtered by pointer kind or density) is refused, exit 2,
      nothing played.
- [x] **check-call-separation's R4 census counts a public method NAMED in test metadata prose as a reference** — Unit 3
      (D2 = read code, triage now): the census reads the tests repo's code only, `scripts/` included, through
      `buildSystem/lib/tests-repo-code.js`; the 40 names prose masked were triaged (six renamed, the rest allowlisted
      or banked: query 99 → 113). `applyPropertyEdit` stays out of R4 for a real reason, the serialization rig's call.

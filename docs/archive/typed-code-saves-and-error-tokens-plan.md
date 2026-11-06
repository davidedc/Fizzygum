# Typed-code saves that do not compile, and `console.error`s no runner reads

**STATUS (2026-11-06): CLOSED — all three units done in one session, ARCHIVED.** The units:
- Units A and B are the two findings the hand-kept-lists arc's Tier 1 left in `docs/BACKLOG.md`
  (`archive/hand-kept-lists-plan.md`, §3 ledger and its 2026-11-06 follow-ups).
- Unit C is the owner's D2 ruling: fail-closed runners, built on Unit B.

They ran in the order B → C → A (§3). The ledger below records every proof.

**Closing gates (after the review fixes):**
- `fg gauntlet`: 18/19 legs green. The refs leg failed only on two visualisation pages left stale by the fixes'
  test edits; after regenerating them, refs ran green alone (4018 references verified, `check-visualisations
  --strict` clean).
- `fg homepage` OK; `npm run selftest` OK.

One end-of-queue review: an independent read of both diffs, its findings folded into the ledger. Residue is in
BACKLOG. The text below is the plan as executed.

Ledger:
- **Owner rulings (2026-11-06).**
  - D1 = **(a) refuse atomically** (§1.4).
  - D2 = **(b)**: the static token rule (Unit B), THEN fail-closed runners as their own unit (Unit C, §2.6).
- **Unit B (2026-11-06).**
  - R5 re-measured on every 12:43-gauntlet leg log (dpr1, dpr2, webkit, finger, tiernaming, settle, revisits,
    storage, vmtruth, capstone, paint): zero hits for the 15 messages, zero `pageerror`.
  - `gate-tokens-selftest.js` landed the UNTOKENIZED rule first. On the unchanged tree it failed on exactly the 15
    §2.1 sites: that run is the static plant.
  - The 15 sites are tokenized with the §2.1 names (the video player's two lines folded into one), and
    `GATE_TOKENS` holds 23 entries (no token contains another). The selftest is green: 60 calls, all tokenized.
  - Runtime plant `.scratch/typed-code-saves/b-appcatalog-plant.js`: AppCatalog answers no `GenericPanelApp` and,
    while a test plays, the plant asks the real `AppLauncherWdgt.forAppNamed` for it.
    `SystemTest_macroOneWindowAppsKeepTheirWindowOnTheShelf` (assertion-only) then FAILS:
    `gate-token violation … APP_CATALOG_ENTRY_MISSING`. Clean, it passes.
  - ⚠ A first plant that only dropped the entry stayed green: that test builds one launcher, not the desktop, so
    the guard never ran. No test builds the full desktop.
  - Gates: `fg build` OK; `fg presuite` OK (dpr1 99 s, paint 150 s, fracplane 6 s).
- **Unit C (2026-11-06).**
  - `lib/gate-tokens.js` holds the one rule: `failingConsoleLine(type, text)` and `failingPageError(message)`,
    each answering `{token, line}` or null. `NOT_GATED` entries carry `{kind, reason}`, and only `by-design`
    (`DATAFLOW_ERROR`) excuses an error line, and only when it OPENS the line.
  - The three runners call the rule. The suite runner files a failing line under the current test (or
    `(boot/setup)`) through one `fileGateViolation`; its `onPageError` now files too, where it only logged.
  - The selftest adds 13 fail-closed cases plus the kinds check. Three mutants of the rule (excuse
    not-distinctive, ignore the error type, a null page error) each turn it red: 1, 6 and 1 failures.
  - Plants (`.scratch/typed-code-saves/c*.js`), single and sequence runners:
    - c0 (a by-design line): PASSES;
    - c1 (an untokenized error): FAILS with `UNTOKENIZED_CONSOLE_ERROR`;
    - c2 (an uncaught throw): FAILS with `UNCAUGHT_PAGE_ERROR`;
    - c3 (a not-distinctive token): FAILS.
  - Suite under `c-suite-combined.js`: SUITE FAILED with gate-violations 6 (8 untokenized lines, one per shard,
    and 5 page errors). Attribution lags onto `(boot/setup)` and neighbouring tests, because the shard's current
    test is poll-updated.
  - Clean `fg presuite` under the fail-closed runners: OK (369 tests, failed 0, gate-violations 0; paint and
    fracplane PASS).
- **Unit A (2026-11-06).**
  - **Code.** `compileFGCode` takes `opts.typedFrom` and sets `typedLocation`. `Widget.evaluateString` forwards
    it; `injectProperty`, `Class.applyMemberEdit` and `Mixin.applyMemberEdit` / `applyStaticEdit` pass their
    prefix's length. `Widget` gains:
    - `@propertyAssignmentSource` (one definition of the injected program);
    - `@compilePropertyAssignments` (one parse; it compiles every assignment and names the failing one,
      `typedIn`);
    - `injectProperties`, now all-or-none over it;
    - one reporter, `_informOfCompileErrorOrRethrow`, behind the run adapter `_reportingCompileErrors` and the
      new save adapter `_savingTypedCode`.
  - **Routes.**
    - S1: `ScriptWdgt.saveScript` compiles first and answers a boolean; `saveScriptAndClose` closes only on a
      save.
    - S2/S3: `InspectorWdgt.save` runs the apply through `_savingTypedCode` and answers a boolean.
    - S4: the mixin route's catch-all is gone; `overrideInThisClass` restores the attribution on a refusal.
    - S5: `CodePromptWdgt.deliverValue` answers a boolean and `deliverValueAndClose` closes only on delivery;
      `modifyCodeToBeInjected` compiles before it stores.
  - **Tests.** T1–T4 were authored as planned, assertion-only; each passes alone. T4 checks injectProperties'
    all-or-none by a direct call (a try in the macro body), because the prompt now refuses such a blurb before
    any injection.
  - **Plants.** Each turns its tests red:
    - PA1 (`_savingTypedCode` rethrows): T1–T4;
    - PA2 (script stores first): T1, "saved script unchanged";
    - PA3 (mixin catch-all): T3, "mixin route: Save still enabled";
    - PA4 (inject one by one): T4, "injects not even its first";
    - PA5 (tool stores first): T4, "unarmed: the tool's source is unchanged". The later arm then throws, and
      Unit C files it as `UNCAUGHT_PAGE_ERROR`.
  - **Follower.** The four tests plus `macroAnalogClockInspectEdit`, on mouse and on finger: 5/5, zero
    `WORLD_INVENTORY_`, zero gate lines.
  - **Benign churn.** `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly` (inherited members ON) shifts:
    the two new Widget instance methods sort above "alpha". This is the owner's standing "just recapture" class.
    Recaptured with `fg recapture --dprs=1,2`, then again with `--pointer=finger`: both RECAPTURE COMPLETE (the
    full suite green at dpr 1 and 2).
  - **Build.** The call-separation gate first failed. `saveScript`'s allowlist entry went stale (T1 calls it for
    its fixture), so it was deleted. The query census also dropped 101 → 99, banked: T3 reads
    `ButtonWdgt::triggerDoubleClick`, and two tests' metadata NAME `applyPropertyEdit` in prose (the census reads
    strings).
- **End-of-queue review (2026-11-06, an independent read of both diffs, given the code, not these conclusions):**
  9 findings and a nit.
  - **F1.** A boot the suite runner abandons and reloads (the boot-storm retry) left its page errors filed under
    `(boot/setup)`, failing a run that recovered. Fix: the retry discards the abandoned page's violations.
  - **F2.** The dormant cache-oracle gate announced itself with `console.error('CACHEORACLE-READY …')`, which
    now fails. Fix: the announcement is a `LAYOUTAUDIT installed …` log line, relayed by `AUDIT_ECHO`, the rail
    every other prelude heartbeat uses.
  - **F3.** The tool-code save checked only the assignments the splitter finds: a non-assignment line was
    dropped and `garbage(((` was accepted. Fix: the save first compiles the text AS TYPED, giving exact positions,
    then each assignment as it will be injected. A per-assignment failure names the assignment and no position.
  - **F4.** "Override in this class" lost the mixin attribution when the save threw a NON-compile error. Fix: it
    restores the attribution whenever the save did not complete.
  - **F5.** A `super` that the class/mixin route rewrites shifts later columns on its line. Kept as the stated
    blind spot; the comment now says so.
  - **F6, F9.** Tool-code positions counted inside the reshaped value. F3's as-typed compile makes them exact.
  - **F7.** The minimal compiler throws a location-less TypeError on `import`/`export`, which the reporter did
    not recognise. Fix: `compileFGCode` marks every error it throws (`isCompileError`), and the reporter keys off
    the mark; there is no position when the compiler gave none.
  - **F8.** With `AUDIT_ECHO`, a `LAYOUTAUDIT…` error line returned before the fail-closed check, so a display
    flag changed the verdict. Fix: the check runs before the audit branch.
  - **Nit.** A tautological `ledBy` in the selftest corpus: removed.
  - **Proofs of the fixes.**
    - T1 gains an `import` save: refused, no position, no Error log. Plant PA7 (the reporter recognising a
      compile failure only by `cause.location`) fails it.
    - T4 now expects the as-typed place, "(line 2, column 26)". PA6 (no as-typed compile) fails it, reading
      "(in pressMoved)".
    - PA1 and PA5 still fail their tests. T1–T4 pass on the fixed build.
    - The cache-oracle gate PASSES: 8/8 shards READY through the echo rail, zero mismatches. Its self-test shows
      the plant heartbeat on 8/8 shards and the failure flood. That run was stopped at 66/373: with every test
      failing it ran ~45 min, a property of the planted flood, not of this change.
    - `npm run selftest` OK.
    - F1 and F4 are fixed by code read only: no gesture reaches F4's non-compile throw, and a boot storm cannot
      be staged on demand.
  - **Gauntlet before the fixes (16:42):** 19/19 OK with one load-flake. menusweep hung in parallel at
    `browser.close()` after a complete 6.9 s sweep, and passed alone in 6 s; infrastructure, not this change.

**Mandate: eliminate each class, not its known members.**
- Unit A: no SAVE gesture over typed code can throw a compile error into the world's crash path, or leave state
  half-applied.
- Unit B: no `console.error` in Fizzygum's source, or in the harness source, can go unread by every runner.
- Unit C: no error-type console line and no uncaught page error, from any source, passes a suite runner unless it
  is excused by name.

Each unit ends with a check that fails when a new member of its class appears, and that check is proven by a
plant that makes it fail.

---

## §0 Orientation

**Fizzygum** is a CoffeeScript GUI framework rendered on one `<canvas>`, with no module system (every class is a
global). The workspace `Fizzygum-all/` holds three sibling repos: `Fizzygum/` (source plus build), `Fizzygum-tests/`
(the macro SystemTests plus the headless runners) and `Fizzygum-builds/` (generated output). Read the root
`CLAUDE.md`, then `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md`. Build and test through the `fg` wrapper,
always by absolute path: `/Users/davidedellacasa/code/Fizzygum-all/fg <cmd>`. Run it bare to see the roster.

**The immediately prior work.** A follow-up of the hand-kept-lists arc (2026-11-06) sent every RUN gesture over
typed text through `Widget._reportingCompileErrors` (`src/basic-widgets/Widget.coffee`, grep the name). The RUN
gestures are `TextWdgt`'s Run contents, Do all and Do/Show/Inspect selection, the console's two, and the script's
Try it.
- Text that does not compile is reported beside the hand ("Cannot run this as code (line L, column C): …"). The
  helper reads the compiler's own error, which `compileFGCode` keeps as the thrown Error's `cause`; only that error
  carries a `location`.
- Code that compiles and then throws still reaches the Error log, where the stack shown is the person's own code.

The SAVE gestures were left out of that change, because a save needs its own answer for the half-applied state.
That is Unit A.

**The gate-token machinery.** The headless runners (`Fizzygum-tests/scripts/run-all-headless.js`,
`run-macro-test-headless.js`, `run-sequence-headless.js`) fail a test when a console line carries a token from
`Fizzygum-tests/scripts/lib/gate-tokens.js` (`GATE_TOKENS`, substring match). `lib/gate-tokens-selftest.js` (in
`npm run selftest`) holds that list to the source in both directions:
- every `console.error "<TOKEN>…"` in `Fizzygum/src` and `Fizzygum-tests/Automator-and-test-harness-src` is either
  gated or excused in `NOT_GATED` with its reason;
- every entry of either list is still emitted somewhere.

A `console.error` whose message does NOT open with an ALL-CAPS token is invisible to both the list and the
selftest, and every runner lets it through. That is Unit B.

**Critical reframes (fact-checked 2026-11-06; re-verify, do not trust):**
- **R1. There are five SAVE gestures, not two.** BACKLOG names two: the script's "Save + close" and the inspectors'
  save. The census (§1.1) finds five routes: the script, the object inspector, the class inspector's class-member
  route, its mixin route, and the paint toolbar's tool-code prompt (`CodePromptWdgt` "Save"/"OK").
- **R2. Atomicity is already true on three routes; two routes store first.** The object inspector, the class route
  and the mixin route compile before they mutate anything. Their defect is only the throw, plus the "saved" marking
  that should not happen. `ScriptWdgt.saveScript` stores `@savedScript` before it compiles. The tool-code prompt
  stores the source before anything compiles it, and then re-injects it on every later arm of the tool.
- **R3. The route BACKLOG calls "already reports" has its own defect.** `ClassInspectorWdgt.applyPropertyEdit`'s
  mixin branch catches every error, informs "mixin edit failed: …" and RETURNS NORMALLY. `InspectorWdgt.save` then
  marks the text as saved (`considerCurrentTextAsReferenceText`), which disables Save on a failed edit.
- **R4. There are 15 untokenized `console.error` calls in 9 files, not four.** The census is in §2.1. The
  structural fix is a selftest rule, not 15 hand-picked edits: every `console.error` opens with a token. Once that
  rule holds, each site needs only one decision, gated or `NOT_GATED`.
- **R5. Green runs emit none of the 15.** This was measured from the leg logs of the 2026-11-06 12:43 gauntlet.
  - The suite runners relay every `error`-type console line.
  - `/tmp/fg-dpr1.log`, `fg-dpr2.log` and `fg-finger.log` carry no error line except `DATAFLOW_ERROR`, which is
    by design.
  - The `apps`, `parts`, `menusweep`, `pinsweep`, `graph`, `paint`, `capstone` and `census` logs carry only their
    own PASS lines.

  So gating all 15 turns nothing red today. Re-measure before landing (§2.5 step 1).

---

## §1 Unit A — a SAVE of typed code that does not compile

### §1.1 Current state: the five routes (grep the method names; line numbers drift)

| # | Gesture | Route | Compiles before storing? | What a compile error does today |
|---|---|---|---|---|
| S1 | Script window "Save + close" | `ScriptWdgt.saveScriptAndClose` → `saveScript` | **No.** `@savedScript = @textWidget.text` is the first line, `compileFGCode` the second. | Throws to the crash path. `@savedScript` already holds the bad text while `@functionFromCompiledCode` keeps the OLD function. After a snapshot restore, `doAll` recompiles the bad text, so a double-click on the script's desktop shortcut throws. The window does not close. |
| S2 | Object inspector "Save" | `InspectorWdgt.save` → `applyPropertyEdit` → `Widget.injectProperty` → `evaluateString` | Yes (`evaluateString` compiles, then evals) | Throws to the crash path; nothing is assigned. |
| S3 | Class inspector "Save", class member | `ClassInspectorWdgt.applyPropertyEdit` → `Class.applyMemberEdit` (`src/meta/Class.coffee`) | Yes (compile, eval, then `proto[name] = …`) | Throws to the crash path; nothing is assigned. |
| S4 | Class inspector "Save", mixin-donated member | the same method's `@currentPropertySourceMixin?` branch → `Mixin.applyMemberEdit` / `applyStaticEdit` | Yes (the source is recorded after the eval) | Caught, informed "mixin edit failed:\n…", returns normally, so `save` marks the text SAVED (R3). |
| S5 | Paint toolbar tool "Code" prompt, "Save" or "OK" | `CodePromptWdgt.deliverValue` → `CodeInjectingSimpleRectangularButtonWdgt.modifyCodeToBeInjected` → (if armed) `PaintToolbarWdgt.newCodeToInjectFromButton` → `injectCodeIntoTarget` → `Widget.injectProperties` → `injectProperty` × N | **No.** `@sourceCodeToBeInjected = newSource` comes first; nothing compiles it unless the tool is armed. | Armed: the source is stored, then the throw reaches the crash path; the prompt stays open, because `deliverValueAndClose` never reaches `@close()`. Not armed: stored SILENTLY, and every later arm (`_armSelectedTool` → `injectProperties`) throws. `injectProperties` injects property by property, so in a multi-property blurb the properties before the bad one are already injected. |

All five gestures are a click on a button (`SimpleButtonWdgt`). A throw from the action reaches the world's
input-event catch, which soft-resets the world, pops the Error log with a stack of the framework's own calls, and
leaves the window as it was.

**In scope by census and NOT a save.**
- `CalculatingPatchNodeWdgt.recalculateOutput` compiles its typed formula on every recompute. It runs inside the
  dataflow drain (`PatchNodeWdgt.dataflowRecompute`), so a compile error there is already DATA (`DATAFLOW_ERROR`,
  green by design), the spreadsheet-formula law. Out of scope.
- Snapshot replays (`Deserializer`, `SourceEditsRegistry.replay*`) load a file, not typed text, and have their own
  reporter (`FileLoading._reportingSerializationErrors`). Out of scope.

### §1.2 Why it is shaped this way

The RUN gestures got one reporter because a run is stateless: nothing to undo, so refusing is enough. A save mutates
state: the stored text, a compiled function, a member, a tool's source. So the reporter alone is not an answer.
The save must also not mark the text as saved, and must not close its window. On S1 and S5 it must also not store
before it knows the text compiles. That is why the Tier 1 change stopped at the run gestures.

### §1.3 The fix shape (subject to D1)

1. **One reporter, two adapters.**
   - Factor the compile-error test and the message out of `_reportingCompileErrors` into one private helper:
     cause-with-location, else rethrow.
   - Add a sibling for saves, `Widget._savingTypedCode (applyTypedCode) -> true | false`. It runs the apply and
     answers `true`; on a compile error it reports "Cannot save this as code (line L, column C): <compiler
     message>" beside the hand and answers `false`; any other error rethrows, as on the run side.
   - ONE message builder for both verbs.
2. **S1.** `saveScript` compiles first, inside `_savingTypedCode`, and assigns `@savedScript` and
   `@functionFromCompiledCode` only on success. It answers the boolean, and `saveScriptAndClose` closes only on
   `true`.
3. **S2 and S3.** `InspectorWdgt.save` runs `@applyPropertyEdit …` inside `_savingTypedCode`. On `false` it returns
   before `considerCurrentTextAsReferenceText`, so the edit stays MODIFIED and Save stays enabled. It answers the
   boolean.
4. **S4.** Delete the mixin branch's catch-all, so a compile error takes the same path as S3. ⚠ The consequence: a
   NON-compile error in a mixin save, a field whose value expression throws, then reaches the Error log, as it does
   on the class route. Today it is an inform. This is part of D1.
   - **`overrideInThisClass` needs care.** It clears `@currentPropertySourceMixin`, the button and the donor label
     BEFORE it calls `@save()`, and informs "overridden in …" after. On a refused save it must put the mixin
     attribution back and must not inform. Read the method; the simplest shape that holds is to capture, attempt,
     and restore on `false`.
5. **S5.**
   - `CodePromptWdgt.deliverValue` runs the callback inside `_savingTypedCode` and, on `false`, does not reset its
     reference text. `deliverValueAndClose` closes only on `true`.
   - `modifyCodeToBeInjected` compiles the new source the way `injectProperties` will (each `@name = <txt>` chunk)
     BEFORE it stores anything. Give `Widget` one parse for the blurb, which `injectProperties` uses too, so
     "the way it will be injected" has one definition.
   - Also make `injectProperties` compile every chunk before it injects any, so the method is atomic for every
     caller, not only this one.
   - `CodePromptWdgt` has ONE caller today (`CodeInjectingSimpleRectangularButtonWdgt.editInjectableSource`, via
     `Widget.textPrompt`; grep `new CodePromptWdgt` and `textPrompt ` to re-verify).
6. **The position must be in the person's text. FINDING (2026-11-06, probe
   `.scratch/typed-code-saves/compile-location-probe.js`):** the save routes compile the typed text BEHIND a prefix:
   - injectProperty uses `"@" + name + " = "`;
   - the Class and Mixin edits use `"window.__fzEditedClassMember = "` / `"…MixinMember = "`.

   So the compiler's line-1 column is off by the prefix's length ("x = (" reads column 5 typed, 13 behind
   `@prop = `, 36 behind the class prefix). Later lines are exact.
   - **Fix:** `compileFGCode` takes the index where the typed text begins (`typedFrom`, default 0) and puts the
     error's position IN THAT TEXT on the thrown Error (`typedLocation`), which the one reporter reads.
   - **Callers:** `evaluateString` forwards it (opts), and each prefixing route passes its prefix's length.
   - **S5** (as landed, after review F3) compiles the blurb AS TYPED first, so the line and column name a place
     in the prompt, and a line the splitter would skip is refused. It then compiles each assignment as it will
     be injected; a failure there names the assignment (`typedIn`) and gives no position, since the splitter
     reshapes the text.
   - **Stated blind spot:** a `super` the class and mixin routes rewrite (`_equivalentforSuper`) shifts columns
     later on its own line.
7. **Comments are present tense.** `_reportingCompileErrors`'s header comment already states the run law. Extend it
   to the save law: "the SAVE gestures … run their apply through `_savingTypedCode`: text that does not compile
   changes nothing and is reported; the gesture neither marks it saved nor closes".

### §1.4 D1 — OWNER DECISION: what a save of uncompilable text does

- **(a) Refuse atomically (RECOMMENDED).** Nothing changes: no stored text, no function, no member, no tool
  source. The text is reported at the hand, the editor stays open with the typed text still marked modified, and a
  "… + close" / "OK" gesture does not close. The person fixes the text and saves again, and nothing is lost,
  because the window is still open.
  - It is the one answer S2–S4 already give by construction (they compile first).
  - It makes S1 and S5 match them.
  - S4's runtime-error path joins S3's (the Error log).
- **(b) Keep the text, report, leave the behaviour as it was.** Store the typed source as saved and keep the old
  function or member. Half-applied by design: a later reload or arm recompiles the stored text and fails then,
  which is exactly S1's and S5's bug today.
- **(c) Keep the text and disable.** Store the source and clear the compiled function, so the script or tool does
  nothing until it is fixed. A silent no-op where a person expects their code, for every later click.

**RULED 2026-11-06: (a).**

### §1.5 Tests (assertion-only macro tests: no screenshots, so no reference capture)

Author each with the `/author-macro-test` skill in `Fizzygum-tests`, modelled on the tests that already drive the
same windows:
- `SystemTest_macroAddEditSaveRenameRemoveProperty`: object inspector, edit and save.
- `SystemTest_macroMixinEditDonorAndOverride`: class inspector, mixin route and override.
- `SystemTest_macroNakedInspectorRendersResizesAndEdits`.

For a script window and the paint toolbar, grep the tests for `ScriptWdgt` and for `PaintToolbarWdgt` /
`EditableMarkWdgt`. Every new test asserts:
1. the inform is SHOWN (`@popUpIsShown`, MacroToolkit: built is not shown) and titled
   `Cannot save this as code (line …` (assert the prefix, plus the line number of the planted bad line);
2. `world.errorConsole` is undefined (the crash path never ran: each test starts on a freshly constructed world);
3. the state is unchanged (the route's own field, read back);
4. the editor is still open, its text is the typed text, and Save is still enabled;
5. for S1 and S5, the window or prompt did not close.

Proposed tests:
- **T1** `SystemTest_macroScriptSaveRefusesCodeThatDoesNotCompile`, for S1. `savedScript` and
  `functionFromCompiledCode` are unchanged.
- **T2** `SystemTest_macroInspectorSaveRefusesCodeThatDoesNotCompile`, for S2. The inspected property is
  unchanged.
- **T3** `SystemTest_macroClassInspectorSaveRefusesCodeThatDoesNotCompile`, for S3 and S4: one class-member save,
  then one mixin-member save.
  - The prototype member, the mixin's `nonStaticPropertiesSources` entry and the consumer prototypes are all
    unchanged.
  - Then "override in this class" with the bad text still in the editor: the attribution survives and no
    "overridden" inform appears.
- **T4** `SystemTest_macroToolCodeSaveRefusesCodeThatDoesNotCompile`, for S5.
  - Bad code saved into an UNARMED tool's prompt: refused, prompt open, `sourceCodeToBeInjected` unchanged.
  - Then arm that tool: no Error log.
  - Then an ARMED tool's prompt plus OK: refused, prompt open.
  - Use a two-assignment blurb whose SECOND chunk is bad, and assert that the first property was not injected.
    That assertion is what proves `injectProperties` is atomic.

Uncompilable text that names its own position: `x = (` or `foo: ->\n  )(`. Pick one whose `location` the
CoffeeScript compiler reports, and assert the line it names.

### §1.6 Plants (each must turn its test RED, then be reverted)

Plant through `PRELUDE_JS` (single runner) and `AUDIT_PRELUDE` (suite), never by editing src. Plant files go under
`Fizzygum-tests/.scratch/<this-plan>/`.
- **PA1.** `Widget::_savingTypedCode` rethrows every error. T1–T4 all fail on assertion 2.
- **PA2.** `ScriptWdgt::saveScript` restored to store first. T1 fails on assertion 3.
- **PA3.** The mixin branch's catch-all restored (an override of `ClassInspectorWdgt::applyPropertyEdit` that
  catches and informs). T3 fails on assertion 4, because Save is disabled.
- **PA4.** `injectProperties` restored to inject chunk by chunk. T4 fails on the first-property assertion.
- **PA5.** `modifyCodeToBeInjected` restored to store first. T4 fails on the unarmed case.

A plant that leaves its test GREEN is a finding: the test is blind. Fix the test, never the plant. This happened
in the residue queue's §1: `getMostRecentlyOpenedMenu` answers the pop-up most recently BUILT, so assert
`popUpIsShown`.

### §1.7 Risks

- **`menusweep` calls actions directly.** It clicks every menu row, including inspectors' rows, and must stay
  green. A save action that now answers a boolean is fine, but run `fg menusweep` (a gauntlet wave-A leg).
- **The paint toolbar re-arms on many gestures.** `injectProperties` now compiles twice per arm (once to validate,
  once inside `evaluateString`). Tool sources are a few hundred characters, so the cost is negligible. If it is
  not, compile once and eval the compiled JS: make `evaluateString`'s compile reusable, and do not add a second
  eval path.
- **Rows may move pixels.** If a test reference shows an inspector after a save, an extra or removed inform could
  shift it. The suite will say so. Investigate any red: a refused save in an existing test would mean that test
  saved bad code.

---

## §2 Unit B — every `console.error` carries a classified token

### §2.1 Current state: the census (2026-11-06)

Re-run the census before trusting it. It lists every code-line `console.error` not opening with a token, skipping
comment lines:
```
cd /Users/davidedellacasa/code/Fizzygum-all
grep -rn "console\.error" Fizzygum/src Fizzygum-tests/Automator-and-test-harness-src --include='*.coffee' \
  | grep -vE ":[0-9]+:\s*#" \
  | grep -vE "console\.error\s*\(?\s*[\"'][A-Z][A-Z0-9_]{3,}([^A-Za-z0-9_]|$)"
```
At planning there are 62 code-line `console.error`s; 15 carry no token:

| File (method) | Message today | Proposed token | Gate? |
|---|---|---|---|
| `StackLayoutEngine.coffee` (distribution), ×3 | "this shouldn't happen, extraSpace is negative", "this shouldn't happen, maxMargin negative", "division-stack distribution overflowed its allocated extent by …" | `STACK_DISTRIBUTION_INVARIANT` | gated |
| `basic-widgets/Widget.coffee` `_divisionChildrenAxis` | "mixed division axes under one container (…)" | `MIXED_DIVISION_AXES` | gated (its own comment calls it a configuration error) |
| `AppLauncherWdgt.coffee` `@_fromCatalogEntry` | "AppCatalog has no entry for '…'" | `APP_CATALOG_ENTRY_MISSING` | gated |
| `duplication/Duplicator.coffee` `_copyFizzygumObject` | "Duplicator: cannot duplicate a value of unrecognized type (…)" (then throws) | `DUPLICATE_UNRECOGNIZED_TYPE` | gated (the throw may be caught by the crash path; the token fails the test regardless) |
| `boot/globalFunctions.coffee` (SWCanvas font bootstrap), ×2 | "Fizzygum: SWCanvas font bootstrap failed / threw (text may be broken):", err | `SWCANVAS_FONT_BOOTSTRAP_FAILED` | gated (files under `(boot/setup)`) |
| `meta/Mixin.coffee` + `meta/Class.coffee` `_removeHelperFunctions`, ×2 | "code contains a helper var, it shouldn't: …" | `HELPER_VAR_NOT_STRIPPED` | gated |
| `meta/Class.coffee` `_nameTheConstructorFunction` | "could not give the constructor of … a parse-time name: …" | `CONSTRUCTOR_NOT_NAMED` | gated |
| `meta/Mixin.coffee` + `meta/Class.coffee` (create-pass eval), ×2 | " error " + err + " evaling : " + JS | `SOURCE_EVAL_FAILED` | gated |
| `video-player/VideoPlayerWithRecommendationsWdgt.coffee`, ×2 (two lines) | "error loading manifest" / the error | `VIDEO_MANIFEST_LOAD_FAILED` (fold into ONE call carrying the error) | gated (the part ships only with `--includeVideoPlayer`, never on the harness page) |

Token rules (from `gate-tokens.js`'s header): ALL-CAPS, at least 4 characters, distinctive, because the runners
match a token as a SUBSTRING of every console line. No token may contain another; check the new names against
`GATE_TOKENS`, e.g. `SOURCE_EVAL_FAILED` against `SOURCE_COMPILE_FAILED`. Keep the context after the token
(`TOKEN: <the message as it reads today>`). Only the opening changes.

### §2.2 Why it is shaped this way

The selftest matches only `console.error` strings that already OPEN with a token (`EMIT_RE`), because it was built
to keep the token LIST honest, not to find errors that have no token. So an author who writes `console.error "this
shouldn't happen"` has written an assertion no runner reads. It is the same hand-kept-list rot the arc was about,
one level up: the "list" here is the set of console errors someone meant to be loud.

### §2.3 The fix shape (subject to D2)

1. **`gate-tokens-selftest.js` gains the rule.** Every code-line `console.error` call under `ROOTS` opens with a
   token literal. A call that does not is reported:
   `UNTOKENIZED console.error at <file:line> — open its message with an ALL-CAPS token, then classify the token`.
   That covers a bare variable (`console.error error`), a lowercase string, and `"Fizzygum: …"`. Comment lines
   stay skipped. The existing `classify` then decides gated or `NOT_GATED` per token, unchanged.
2. **Corpus cases**, which the rule must report:
   - `console.error "this shouldn't happen"` → UNTOKENIZED;
   - `console.error error` → UNTOKENIZED;
   - `console.error "Fizzygum: x"` → UNTOKENIZED (the current corpus asserts this yields no token; keep that
     assertion and add the new report);
   - `  # console.error "x"` → nothing.
   - A control: a tokenized call is not reported.
3. **The 15 sites get their tokens (§2.1), and `GATE_TOKENS` gets the new names**, each documented in the
   `gate-tokens.js` header beside its emitting guard, as every existing token is.
4. **Stated blind spots** (into the selftest header):
   - an aliased call (`log = console.error`) or `console["error"]`; none exist today, so grep for both;
   - errors raised by non-Fizzygum code (the browser, vendored SWCanvas, the CoffeeScript compiler).

### §2.4 D2 — OWNER DECISION: static rule or fail-closed runners

- **(a) Static: every `console.error` opens with a classified token (RECOMMENDED).** It extends the one mechanism
  that exists: one list, held to the source both ways.
  - It fails `npm run selftest` when the line is WRITTEN, not only when some test happens to reach it.
  - Each site carries a deliberate decision (gated, or excused with one of the two legitimate reasons).
  - Cost: 15 one-line edits, one selftest rule.
- **(b) Fail-closed runners: any `error`-type console line fails the test unless its token is excused.**
  - It catches runtime-built messages and browser and vendor errors as well.
  - It changes runner semantics in three runners plus the suite summary, and every other rig that reads the console
    keeps its own policy.
  - Browser-originated errors (a failed resource load) become failures. None occur in a green run today (R5),
    but that is a property of today.
  - Strictly larger than (a), and (a) is a prerequisite either way: a failure needs a name to be reported by.
  - If the owner wants (b), do (a) first and file (b) as its own unit.

**RULED 2026-11-06: (b).** Unit B lands (a); Unit C (§2.6) is the fail-closed half.

### §2.5 Execution steps and the plant

1. **Re-measure R5.** Grep the newest gauntlet leg logs (`/tmp/fg-dpr1.log`, `fg-dpr2.log`, `fg-finger.log`,
   `fg-webkit.log` if present) for each §2.1 message. Any hit means that test emits the error today: investigate
   it as a bug before gating its token. Gating makes it red, which is correct, but the fix comes first.
2. **Land the selftest rule FIRST, before the sites change.** `npm run selftest` must then FAIL, listing exactly
   the 15 sites. That run is the plant for the static rule: the tree itself is the planted state. Record the count.
3. Tokenize the sites, add the gate entries, and get `npm run selftest` green.
4. **Runtime plant.** Make one guard's CONDITION happen without touching the guard, and see the runner fail the
   test.
   - The likely candidate is a `PRELUDE_JS` plant that drops one `AppCatalog` entry. `AppCatalog.get` reads
     `@entries()[name]`; wrap `AppCatalog.entries` to delete one key. A launcher built from that name then fires
     `APP_CATALOG_ENTRY_MISSING` and the test fails as a gate violation.
   - Pick a single test that builds that launcher: grep the tests for the app's name.
   - Run: `PRELUDE_JS=<plant> node scripts/run-macro-test-headless.js SystemTest_<name>`, from `Fizzygum-tests/`.
     It must print `gate-token violation` and `TEST FAILED`. Without the plant it passes.

### §2.6 Unit C — fail-closed runners (owner ruling D2 = (b))

**What changes.** Today the three suite runners fail a test only on a console line carrying a `GATE_TOKENS`
token. After Unit C, any of the following also fails the test, filed as a gate violation under the test the shard
was on, or under `(boot/setup)`:
- an **`error`-type console line** (`m.type() === 'error'`, in both Puppeteer and Playwright) that carries no
  token excused BY DESIGN;
- an **uncaught page error** (`onPageError`).

The decision lives in ONE function in `lib/gate-tokens.js`, which all three runners call in place of their bare
`gateTokenIn(text)`. For example, `failingConsoleLine(type, text)` answers the token to report, or `undefined`:
1. a `GATE_TOKENS` match on any line (as today);
2. else, for an `error`-type line: `undefined` if it carries a token excused by design, otherwise its own leading
   token, or `UNTOKENIZED_CONSOLE_ERROR`.

A page error answers `UNCAUGHT_PAGE_ERROR`. The suite summary already counts gate violations, so
`suite-summary.js` needs no change. Re-verify by reading `formatSuiteResult`.

**Current state, per runner (grep `gateTokenIn`; line numbers drift).**
- `run-all-headless.js`: its console handler gates on `gateTokenIn(t)` and only LOGS other `error` lines. Its
  `onPageError` only logs.
- `run-macro-test-headless.js`: it collects `error` lines and page errors into `errors`, then fails on
  `errors.filter(e => gateTokenIn(e))`.
- `run-sequence-headless.js`: it gates on `gateTokenIn(t)`. Read its page-error handling.

**⚠ `NOT_GATED` splits in two.** Its entries carry one of two reasons today, and under fail-closed they mean
different things:
- **by design**: `DATAFLOW_ERROR`, emitted by green runs (spreadsheet tests drive formulas that throw). It stays
  excused.
- **not distinctive**: `FIZZYGUM_USE_SWCANVAS`, `SHA256`. These were kept out of the substring match because the
  WORD appears in ordinary lines. As an `error`-type line, though, each is a real error: a page missing its preset,
  or a hasher self-test failing. Under fail-closed they must FAIL.

So give each `NOT_GATED` entry its kind, for example `{kind: 'by-design' | 'not-distinctive', reason}`. Only
`by-design` excuses an error line. Teach `gate-tokens-selftest.js` the field: an entry with no kind, or an
unknown kind, is a failure.

**Scope.** Only the three runners that consume `gate-tokens.js`. Every other rig keeps its own console policy, and
most already fail on any console or page error: the boot smoke, `parts`, `apps`. State this in the
`gate-tokens.js` header.

**Census before landing.** Re-measure R5 for page errors too. Grep the newest dpr1, dpr2, webkit and finger leg
logs for `pageerror:` and for every `error`-type relayed line. The suite runner relays both, so a green log
holding none means fail-closed turns nothing red. Any hit is investigated first, as a bug.

**Plants**, in `Fizzygum-tests/.scratch/<this-plan>/`. Each runs under the single runner (`PRELUDE_JS`), the
sequence runner, and the suite (`AUDIT_PRELUDE`, through `fg`). Each must turn its run RED, and a clean run stays
green.
- **PC1.** A prelude that, once a test is playing, `console.error`s plain words (`"plain words, no token"`).
  Expect a gate violation `UNTOKENIZED_CONSOLE_ERROR`. Emitting the error directly is right here: the property
  under test is the runner's reaction to ANY error line.
- **PC2.** A prelude that throws from a `setTimeout` while a test plays. Expect `UNCAUGHT_PAGE_ERROR`.
- **PC3, the control.** A prelude that `console.error`s `"FIZZYGUM_USE_SWCANVAS missing"`. Expect a FAIL: the
  not-distinctive kind does not excuse.
- **Kept green.** `SystemTest_macroSpreadsheetErrorPropagation`, which emits `DATAFLOW_ERROR` by design, still
  passes.
- **The selftest corpus** covers `failingConsoleLine`'s table: a gated token, a by-design token, a
  not-distinctive token, plain words, a non-error line carrying plain words, and a non-error line carrying a gate
  token.

**Risks.**
- **WebKit wording.** Playwright's WebKit can surface engine messages as `error`-type lines that Chrome does not.
  Run the webkit suite (a gauntlet wave-A leg) and read any new failure before excusing anything. A legitimate
  excuse needs a token and a by-design reason, never a prose match.
- **Boot-time lines.** A boot-time error line in every shard fails the whole run under `(boot/setup)`, which is
  the right outcome: today it passes silently.
- **`recapture.js` reads gate violations**, through `suite-summary.js`. A run that newly fails only on an error
  line now re-verifies or calls INCONCLUSIVE rather than reading GREEN, which is the right reading.

---

## §3 Cold-execution protocol

1. **Orient.** `/Users/davidedellacasa/code/Fizzygum-all/fg status`: both repos clean and level with origin, build
   FRESH. Read this doc fully. Re-run both censuses (§1.1: grep `compileFGCode`, `evaluateString`, `injectPropert`,
   `applyMemberEdit`, `applyStaticEdit` in `Fizzygum/src`; §2.1: the grep above). If either has grown, extend the
   tables before coding.
2. **Owner rulings.** D1 and D2 are recorded in the ledger (2026-11-06). A future change of course is the
   owner's call, so ask.
3. **Unit B first.** It is smaller and independent: §2.5 steps 1–4, then `fg presuite`.
4. **Unit C next** (§2.6), because it builds on B's names:
   1. the census;
   2. the `NOT_GATED` kinds and the selftest;
   3. `failingConsoleLine` and the three runners;
   4. plants PC1–PC3;
   5. `fg presuite`.
5. **Unit A** in this order:
   1. the shared reporter plus `_savingTypedCode`;
   2. S1;
   3. S2/S3 (`InspectorWdgt.save`);
   4. S4 and `overrideInThisClass`;
   5. S5 (`injectProperties` parse/atomic, `modifyCodeToBeInjected`, `CodePromptWdgt`);
   6. the tests T1–T4, run singly (`node scripts/run-macro-test-headless.js SystemTest_<name>` from
      `Fizzygum-tests/`, after `fg build`);
   7. plants PA1–PA5;
   8. `fg presuite`.
6. **Close.**
   - `fg gauntlet` (background, ETA ~15 min with today's 19 legs; status every ~5 min), `fg homepage` (it touches
     `src/meta` messages only, but run it: the meta-system ships in production), and `npm run selftest`.
   - Then ONE end-of-arc review: an independent read of both diffs, given the code and not these conclusions.
   - Then docs (§4), the ledger, archive this plan (`git mv` to `docs/archive/`, plus an INDEX line), and move the
     two BACKLOG items into this plan's BACKLOG ledger.
   - Propose the commit messages and WAIT for approval. Ask about push separately.

House rules that apply (all from the CLAUDE.md files):
- **`fg` and shell discipline.**
  - Invoke `fg` by absolute path only.
  - Never pipe a gating `fg` call through `| tail` or `| grep`.
  - Long ops run in the background, with peeks at `/tmp/fg-<cmd>.verdict` at a ~5-minute cadence.
  - A running fg op owns `src/` and `tests/`: no edits and no probe browsers while it runs.
- **Editing and files.**
  - Edit `.coffee` with the Edit tool, never `perl -pi` or `sed`.
  - Node probes live under `Fizzygum-tests/.scratch/`.
  - Never touch `Fizzygum-builds/`, and never aim `rm -rf` or `find -L` at `latest/js/tests`.
  - Comments and docs are present tense.
  - `undefined` is the one absence value.
- **Commits.** Never commit or push without explicit owner approval. Use `git commit -F <file>`; messages end with
  the session's `Co-Authored-By` line.

## §4 Docs to update at the close

- `Fizzygum-tests/scripts/lib/gate-tokens.js` header: the new tokens, each beside its guard.
- `Fizzygum-tests/scripts/lib/gate-tokens-selftest.js` header: the new rule and its blind spots.
- `Fizzygum-tests/CLAUDE.md`, the `npm run selftest` paragraph: the selftest now also requires every
  `console.error` to open with a token.
- `Fizzygum/docs/architecture/lint-and-static-checks.md`, the gate-token paragraph (grep `gate-tokens.js`): state
  the rule. ⚠ The selftest is the tests repo's, not a build gate, so do not add a build-gate row.
- `Widget._reportingCompileErrors` and `_savingTypedCode` header comments: the run law and the save law.
- **Unit C, the runner policy itself.**
  - `gate-tokens.js` header: fail-closed, the `NOT_GATED` kinds, and the scope (three runners).
  - The three runners' gate comments.
  - `Fizzygum-tests/CLAUDE.md`, where it describes what fails a test.
  - Root `CLAUDE.md` and `Fizzygum/CLAUDE.md` only where they state what the fail-gate reads. Grep both for
    "fail-gate".
- `docs/BACKLOG.md`: the two items leave and land in this plan's ledger.

## §5 Rejected alternatives (do not re-attempt)

- **Wrapping each save in `_reportingCompileErrors` as it is.** It answers `undefined` both for a refusal and for a
  successful apply that returns nothing, so the gesture cannot tell whether to mark the text saved or close. A
  second adapter that answers a boolean is the smallest correct shape.
- **Validating a tool-code blurb ONLY by compiling it whole, as one script.** The blurb is injected chunk by chunk
  as `@name = <txt>` (`injectProperties`), and a whole-blurb compile is a different program, so on its own it
  would not prove the injection compiles. The save does both: as typed (the person's positions, and the lines
  the splitter skips), then exactly what will be injected, through the one parse. The review showed the
  per-assignment check alone is not enough either.
- **Gating the 15 messages by matching their free text in the runners** (`/shouldn't happen/`). That is a second
  token list, of prose, which nobody holds to the source. One mechanism (ALL-CAPS tokens held both ways) is the
  owner's standing principle (`clean-minimal-uniform-architecture`).
- **Fail-closed runners INSTEAD of the static rule.** Unit C needs Unit B's names: an error line is reported by its
  token. Unit B also catches a site when the line is written, not only when a test reaches it.
- **Keeping `NOT_GATED` as one bag under fail-closed.** Its "not distinctive" entries would then EXCUSE real error
  lines (a page missing its backend preset, a hasher self-test failing). Hence the two kinds in §2.6.

## §6 References

- `Fizzygum/docs/archive/hand-kept-lists-plan.md` §3 ledger and its 2026-11-06 follow-ups (the run-gesture change,
  the menusweep plant `THREW:doContents`).
- `Fizzygum/docs/archive/hand-lists-residue-plan.md` §1/§1b (built is not shown: `popUpIsShown`).
- `Fizzygum/src/macros/CLAUDE.md` and `MACRO-PATTERNS.md` (toolkit verbs; typing into text; menu assertions).
- `Fizzygum-tests/CLAUDE.md` (runners, `PRELUDE_JS`/`AUDIT_PRELUDE`, `LOG_FILE=` for the full console).
- `Fizzygum/docs/architecture/lint-and-static-checks.md` (tiers, the gate-token paragraph).

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

Two items relocated VERBATIM from `docs/BACKLOG.md` on 2026-11-06 (`docs/README.md` filing rule 2); how each closed
is in the ledger above (Units A, B and C). ⚠ The first item's "the class inspector's mixin route already reports" was
half wrong: it reported, then returned as if it had saved (reframe R3, §0).

- [x] **A SAVE of typed code that does not compile still throws into the crash path**: `ScriptWdgt.saveScript`
      ("Save + close", which sets `@savedScript` before it compiles) and the inspectors' save
      (`InspectorWdgt.applyPropertyEdit` → `injectProperty` → `evaluateString`; the class inspector's mixin route
      already reports) — the RUN gestures report through `Widget._reportingCompileErrors`; a save needs its own
      answer for the half-applied state, so it was left out of that change.
- [x] **An untokenized `console.error` fails nothing**: "this shouldn't happen" asserts in `StackLayoutEngine`,
      the mixed-division-axes warning, `Duplicator`'s unrecognized type, `AppLauncherWdgt`'s missing catalog entry —
      no gate token, so every runner lets them through (the gate-token selftest sees tokens only).

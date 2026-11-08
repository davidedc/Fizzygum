# Tests-repo readers: one definition of "a reference to a method", read from code, for every gate that asks

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**

**STATUS (2026-11-06): CLOSED — Units 0, A, B, C, E done in one session, ARCHIVED.** Unit D (`check-argument-holes`
over the tests repo) is its own arc by owner ruling D5 (BACKLOG). Owner rulings: D1 = (a) the generic reference rule for
both gates, D2 = (a) delete all four, D3 = (a) a real JS lexer, D4 = (c) both widenings, then D5 = Unit D as its own arc.

**Closing gates:**
- `fg gauntlet` 19/19, 944 s, no retries;
- `npm run selftest` OK;
- after the review fixes: `fg presuite` OK (dpr1:PASS(93s) paint:PASS(151s) fracplane:PASS(6s) total=175s), every touched gate and `--self-test` PASS,
  `check-visualisations --strict` OK.

`fg homepage` was not run: neither `src/boot` nor `src/meta` changed. The text below is the plan as executed; the
ledger records where execution corrected it (§3's +3 became +28).

Ledger (one entry per landed step; proofs inline):
- **Owner rulings (2026-11-06).**
  - D1 = (a): the generic rule, in `lib/method-references.js`, for check-dead-methods AND R4.
  - D2 = (a): delete all four.
  - D3 = (a): a real JS lexer.
  - D4 = (c): take BOTH widenings, as Units D (`check-argument-holes` reads the tests repo's code) and E
    (`check-unresolved-sends` reads macro sends).
- **Unit 0 (2026-11-06).** New `buildSystem/lib/js-mask.js`, one left-to-right JS lexer (comments anywhere, quoted
  strings, templates with `${…}` nesting, regex literals by the previous-significant-token rule, a `#!` first line).
  `tests-repo-code.js`'s `jsCode`/`macroCode` read through it, and a macro file's top-level templates go to
  coffee-mask. The reader's cases moved into the reader (`selfTest(log)`), run by the census's and the dead-method
  gate's `--self-test`.
  - Oracle `.scratch/tests-repo-readers/js-mask-vs-js-tokens.js`: 462 files, 3.3 M chars. Template spans agree in
    all 373 macro files. Comment spans agree everywhere but 2, both js-tokens misreading `n / 8));  // …` as a regex
    (it decides by lookahead alone); js-mask is right there.
  - Plants `.scratch/tests-repo-readers/plant-reader.js` (lib copies, one regression each), every one caught by name:
    - line-start comments only → `jsTrailing`, `scriptTrailing`, `afterDivision`, `tickComment`;
    - no CoffeeScript pass → `macroComment`, `macroTrailing`, the unterminated template;
    - the backtick split first (the header leak) → `headerTick`, `headerTock`;
    - no regex literals → `afterSlashRegex`, `tickComment`. A first, weaker regex case SURVIVED: a missed regex only
      mislabels code as a kept string. The cases that bite are a `//` inside a regex and a backtick inside one.
  - `check-call-separation` unchanged at 113/113: lexing JS moves no R4 name.
- **Unit A (2026-11-06), D1/D2 = (a).**
  - New `buildSystem/lib/method-references.js`: clauses 1–4 (§1.3), `reachedByComputedDispatch`, and its own
    `selfTest(log)`.
  - `check-dead-methods.js` reads src through `codeOfCoffeeLine` and the tests repo through `testsRepoCode`, both by
    the rule. Computed dispatch is resolved last against the inventory (owner `@computed`). The header-line special
    case is gone, and the header, the FAIL text and the `--update-allowlist` header state the rule.
  - Real tree before the deletions: FAIL naming exactly `dragWindowResizerTo_InputEvents`, `isSelected`, `siblings`
    and `theta`, and STALE naming exactly the 4 connectors and `isDesktopShortcut` (§1.4's prediction).
  - Allowlist: the 5 entries and their two section headers are deleted, and the header is rewritten present-tense.
  - Deleted (Edit tool): `Point.theta`, `TreeNode.siblings`, `SwitchButtonWdgt.isSelected`,
    `MacroToolkit.dragWindowResizerTo_InputEvents`.
    - aim-census's `VERBS` row deleted: it exits 0 with 83 verbs. A planted stale row prints `AIM-CENSUS STALE NAME`.
    - 10 MACRO-PATTERNS entries, `src/macros/CLAUDE.md`'s window-chrome list and 3 skill rows now name
      `resizeWindowBy`.
  - Gate: `[dead-methods] OK — 2673 method names, 10 dead (9 allowlisted + 1 symmetry-exempt), 0 new`.
  - Real-tree plants, each restored and each FAILING by name:
    - the rigs' `isDesktopShortcut` calls hidden → `isDesktopShortcut`;
    - `DataflowEngine`'s template assembled with `+` → the 4 connectors;
    - `FormulaHelpers[name]` routed through a local → `mix`.
  - Knock-ons the build caught:
    - `check-hand-lists` read two self-test fixtures naming real members as hand lists; the fixtures now use
      fictional names;
    - `theta` held the tree's last `Math.atan(` paren-call, so `check-unresolved-sends`'s `atan` BUILTINS entry went
      STALE and is deleted.
  - Docs: `lint-and-static-checks.md`'s dead-method row, and its bullet, which had run on inside the
    invalidation-receivers bullet and now stands alone.
- **Unit C (2026-11-06), D1 = (a): R4 reads references by the same rule, on BOTH halves.**
  - `method-references.js` gains per-occurrence position and form (`occurrences`: `@` / `.` / string), with a case.
  - R4's src half classifies code-line occurrences: `@` is self, `.`/`::` is member, any reference inside a string is
    `other` (macro heredocs and dispatch strings, the T5 lesson kept). A bare word or prose counts nothing, and the
    unused `defs` count is gone. The tests-repo half counts names by the rule, and computed dispatch is `other`.
  - ⚠ The §3 measurement (+3) covered the tests-repo half only. Applied to the src half the rule unmasks 25 more
    public queries, each hidden by a local (`textVerticalPosition = @textVerticalPosition …`), a debug-log label
    (`"addCommandsSeparations 1: "`) or a CSS-ish string (`"circle-box"`). R4: 142 → 170.
  - Triage, per the previous arc's rules:
    - 24 renamed `_`-tier (Edit tool; [G]/[S]/[A] accept every one): LCLCodePreprocessor's 18 pipeline steps
      (their debug labels follow), `StringWdgt._textVerticalPosition`/`_textHorizontalPosition`,
      `FridgeWdgt._topMostMagnet`/`_topLeftMostMagnet`, `Widget._firstParentOwningMyShadow`, and `_isContentSizing`
      in its 4 classes;
    - 3 allowlisted: `forward` (turtle API beside `setHeading`), `cmd` ([S] refuses `_cmd`, probed), and
      `syntheticEventsMouseShiftClick_InputEvents` (the L1 family);
    - `IconAppearance.circle` stays in the query residue beside `oval`, its drawing-primitive family (`arc` is the
      third; it escapes R4 only through canvas `ctx.arc`). That family's tier is the campaign's question, and `arc`
      is too common a word for a bounded rename. `BASELINE_U_QUERY` 113 → 114, ledgered.
  - Gates: `check-call-separation` OK (`[U]` 0/0 effectful, 114/114 query, 32 allowlisted); `check-layering` 0
    violations.
  - Live docs and test prose follow the renames: MACRO-PATTERNS, `viewports-and-planes.md`, and
    `macroTextWdgtCaretPlacementUnderAlignments`' comment and provenance (visualisation regenerated; `--strict` OK).
    The not-started LCL plan's citations stay; they still grep.
- **Unit B (2026-11-06): `census-call-arity` reads code.**
  - The scanner takes SOURCES (`{file, lines}`): `srcSources()` through coffee-mask, `testsRepoSources()` through
    the reader. `check-argument-holes` reads `census.srcSources()`.
  - `--holes` 49 → 39. All 10 dropped are prose: 8 metadata files, a block comment and a trailing `//` comment, the
    last now cut by the lexer. The 24 macro holes are unchanged and 0 real holes are lost. `check-argument-holes`:
    2 (baseline 2).
- **Unit E (2026-11-06), D4 = (c): `check-unresolved-sends` reads macro sends.**
  - New reader API `macroSources(root)`: each test's top-level templates (found by js-mask), with their line, and a
    reader case.
  - The gate harvests `[@.]name(` from those CoffeeScript sources with its own `stripLine`. Each site carries its
    macro's OWN defs (`local`): they resolve that macro's calls only and never widen the universe (a global macro-def
    harvest trips the BUILTINS form rules, measured by the survey).
  - 8019 → 10322 calls checked. One violation, `.map(` (`Array#map`), now in BUILTINS. Self-test PASS.
  - Plants `.scratch/tests-repo-readers/plant-unresolved-macro.js` (real files, restored), all behaving:
    - a paren-call nobody defines FAILS, naming the test file and line;
    - a macro's multi-line local helper resolves its own call (an INLINE `{ m: -> }` key defines nothing: the def
      harvest is line-anchored, a limit src shares);
    - the same helper called from ANOTHER macro FAILS;
    - a call in the JS around the template is not read.
- **Owner ruling D5 (2026-11-06): Unit D becomes its own fully planned arc.** Measured, a correct
  `check-argument-holes` over the tests repo needs two things:
  1. the hole census applying the conventions doc's CALLERS TEST (`undefined` at i reaching j is a hole iff another
     site of that callee passes fewer than j+1 arguments). By it, `processKeyDown` (3 sites, all arity 6) and
     `@assertValuesEqual "…", undefined, x` (its real sites all arity 3) are VALUES. That needs a code-only call
     parser: today's sweep misattributes `x = new Foo …` lines and counts a string's mention as a site;
  2. the button family's `(target, action, opts)` head moved into opts. `new SimpleButtonWdgt` has callers at
     arity 2 and 0, and `new ButtonWdgt` at arity 2, so the test fixtures' `undefined, undefined, face: …` are
     holes by BOTH of the doc's rules. `SimpleRectangularButtonWdgt` already takes `target:` in opts. This is a
     family conversion in both repos, about 45 sites plus `super` chains, pixel-neutral.

  `newParentChoice undefined, menu` is the §3 dispatcher exemption. Probe:
  `.scratch/tests-repo-readers/holes-callers-test.js`. `check-argument-holes`' header states the scope and points
  here.
- **Inspector churn (2026-11-06).** The deletions and `_`-renames shift inspector member lists; dpr1 failed on 4 tests
  of the derived churn set. Diff-box crops confirm the same members, the list scrolled one row (`TreeNode.siblings`)
  or two rows (StringWdgt's text-position pair) differently. `fg recapture-inspector`: 15 tests, mouse + finger,
  COMPLETE (691 s). References changed: AddEditSaveRenameRemoveProperty, DuplicatedInspectorDrivesCopiedTargetOnly,
  InspectorScrollbarUnplugged, MovingSlidersSidewaysDoesntCauseContentToMoveSideways.
- **Closing gate (2026-11-06).** `fg gauntlet` 19/19, 944 s, no retries; `npm run selftest` OK.
- **End-of-arc review (one independent Opus agent, given the goals and diffs), findings R1–R10, all addressed:**
  - R1 `widget-authoring-guidelines.md` told authors to allowlist a new `_<set>Connector`, which now fails STALE: it
    states the template reaches it.
  - R2 BUG: the `@m:` exclusion backtracked (`@make:` reached `mak`; live hits `@spanFactors:` → `spanFactor`,
    `@get:` → `ge`), which could fake an R4 self-call. Fixed with `(?![\w$])`, plus a case.
  - R3 js-mask's stated limits were incomplete. A regex right after `)` reads as a division and, holding `/*`, opens
    a multi-line block comment (latent: acorn finds 0 over the 462 files). The `}`/`++` misreads cut nothing. The
    js-mask, reader and lint-doc limits now say exactly that.
  - R4 clause 4 ignored inheritance and mixins, `C?[k]`, `C?.[k]` and a non-literal key (`C["set" + n]`), and a
    destructuring read (`{a} = x`, `const {a} = w`) counted as nothing; all broke "errs toward alive". Fixed: the
    callers supply the class chain (check-dead-methods derives parents and `@augmentWith` mixins, the census uses
    its `chainOf`), and destructuring is a clause-1 form. Cases added.
  - R5 the census's R4 header still said "never a bare identifier": restated.
  - R6 header attributions: the census `--self-test` now runs the rule's cases too, `check-argument-holes` is no
    reader, and a cut can hide a call-arity site.
  - R7 the argument-holes scope reason was stale in two docs, and its comment still listed 3 floor sites (stale
    before this arc). It now names the two real ones, the conventions doc's worked value cases.
  - R8 `plans/dataflow-engine-implementation-plan.md` (cold-executable) named the deleted verb; it now names
    `resizeWindowBy_InputEvents`.
  - R9 the edited test prose attributed `_textHorizontalPosition` to TextWdgt and kept a stale line reference. It
    now says StringWdgt; visualisation regenerated.
  - R10 a short-literal coercion template (`"#{n}px"`) reaches every method it matches: stated as a limit (it errs
    toward reached).
  - Plants `.scratch/tests-repo-readers/plant-rule.js`, each caught by name: the old `@m:` lookahead, no
    destructuring, a chain-blind computed access, the old `C[` key guard.
  - After: every touched gate and self-test passes with unchanged numbers (dead 10, `[U]` 114/114, unresolved 10322
    calls, argument-holes 2, `--holes` 39), and `check-visualisations --strict` passes.

## Mandate

Close the BACKLOG residue item filed under `archive/typed-code-saves-residue-plan.md`: *"The other gates that read the
tests repo still read its prose and comments."* Each gate that reads the sibling `Fizzygum-tests` repo either reads
it through the shared code-only reader (`buildSystem/lib/tests-repo-code.js`), or has its item CLOSED with a measured
reason. What a reader change unmasks is triaged in the same arc. Owner direction (2026-11-06): prefer the GENERIC
solution that fits the architecture, and ignore churn, recaptures and legacy.

## §0 Orientation

- **Fizzygum** (`Fizzygum/`) is a CoffeeScript GUI framework. Its build runs ~31 static gates
  (`Fizzygum/buildSystem/*.js`; index and stated blind spots in `docs/architecture/lint-and-static-checks.md`).
  The sibling **`Fizzygum-tests/`** repo holds:
  - the test harness (`Automator-and-test-harness-src/*.coffee`);
  - 373 macro SystemTests (`tests/<name>/<name>_automationCommands.js`, whose CoffeeScript macro sources sit in JS
    template literals, plus a METADATA file `tests/<name>/<name>.js` whose `intent`/`scenario`/`assertions`/
    `provenance` fields are English prose);
  - ~45 MB of base64 reference records (`tests/<name>/automation-assets/**.js`);
  - the Node rigs `scripts/**/*.js`, whose `page.evaluate` bodies call core methods directly.
- **The prior arc** (`docs/archive/typed-code-saves-residue-plan.md`, Unit 3, PUSHED as Fizzygum `fab3f8ad` and tests
  `0ea5d7dc0`) made `check-call-separation`'s census (rule R4: "is this public method referenced outside src?")
  read the tests repo's CODE through the new shared reader. The reader:
  - reads the harness, the macro command files and `scripts/**/*.js`;
  - cuts comments and keeps strings;
  - skips metadata, reference records, manifests and dot-dirs;
  - states its limits in its header.
- **This arc** carries the reader to the other gates that read the tests repo. A gate's PURPOSE decides whether the
  reader fits. `check-dead-methods` goes first because its blind spot is documented: *"a method whose name is an
  ordinary English word is effectively unkillable"*, since test prose names it.

## §1 Unit A — `check-dead-methods`, and what a REFERENCE is

### 1.1 What it reads FOR, and how (current code)

A REFERENCE set: a method name that appears anywhere it could be reached from is alive. A name appearing only on its
own def header is dead. More text read means more names alive: the gate errs fail-open (it hides dead methods; it
never invents one). `buildSystem/check-dead-methods.js` harvests EVERY identifier-shaped word (`/[A-Za-z_]\w*/g`):
- from src (comments cut by `name-definitions.js`'s naive `stripComment`);
- from the harness (the same cut, def headers stripped);
- from every line of every `tests/**/*.js`, comments included (grep `harvestExternal`). That covers metadata prose,
  macro `#` comments, JS `//` comments, the base64 reference records and the manifests. `scripts/` is never read.

### 1.2 The critical reframe: the question is not "which files", it is "what is a reference"

Measuring only the file set first, i.e. swapping the tests repo's half for the reader (probes
`.scratch/tests-repo-readers/dead-methods-probe.js`, `dead-methods-scopes.js`):

| `scripts/` counted | dead | new dead | stale allowlist entries |
|---|---|---|---|
| today: never; prose and records read | 16 | — | — |
| every word | 13 | `isSelected` | `bringUpTestMenu_InputEvents`, `_applyRowReflectionConnector`, `isDesktopShortcut` |
| not at all | 18 | `isSelected`, `dragWindowResizerTo_InputEvents` | — |

Neither row is right, and the reason is general. `scripts/` holds NAME TABLES, keys that name methods without
reaching them:
- `aim-census.js` classifies EVERY MacroToolkit verb, and fails on an unclassified one;
- the tier-naming prelude's `NON_GEOMETRY`;
- the capstone's wrap lists.

It also holds coincident locals (`const cmd = argv[0]`). 178 src method names appear in `scripts/` only that way, 65 of
them toolkit verbs. Counting every word makes each of them immortal; one already is (`dragWindowResizerTo_InputEvents`,
kept alive by `aim-census.js:278`). But the same flaw is in src: the gate's documented survivors are "LOCAL VARIABLES
sharing a method's name (`for toggle in …`)". **A bare word is never how a program reaches a method.**

### 1.3 The generic rule (one definition, every language, every source)

A method is reached in exactly these ways, in CoffeeScript and JS alike:
1. **property access**: `@m`, `x.m`, `x?.m`, `C::m`. A class-side def key `@m:` is not one.
2. **a whole-name string**: `"m"`, `'m'`, `` `m` ``. This is string dispatch, the idiom of menu actions, `PinSpec`
   setters, `x["m"]` and a harness's `@staticMembersToInstall`.
3. **a name template**: a string assembled around a literal (`"_#{@action}Connector"`) reaches every method matching
   it, with each `#{…}`/`${…}` as a wildcard. A template with no literal part (`"#{x}"`) is a coercion, not a name.
4. **a computed access on a NAMED class**: `FormulaHelpers[name]` reaches every class-side method of that class
   (`C::[k]` / `C.prototype[k]` every instance method). A write (`C[k] = …`) reaches nothing.

NOT a reference: a bare word (a local, a parameter, an object key, a def's own name), anything in a comment, any
prose. The rule reads CODE: src through `lib/coffee-mask.js` (one CoffeeScript reading for both repos), the tests repo
through `lib/tests-repo-code.js`. Text inside strings is read too, because this codebase keeps code in strings (macro
sources, tool-code blurbs, `"#{@m()}"`).

Every def header then needs no special case: its own name is a key, so it is not a reference, and a default parameter
(`foo: (x = @bar()) ->`) now counts `bar`. Today `raw.slice(gt + 1)` drops it.

**Clauses 3 and 4 are DERIVED from the dispatch site, which is what retires hand entries.** Measured over every source
(`.scratch/tests-repo-readers/computed-dispatch-shapes.js`):
- exactly ONE template with a literal part reaches methods: `"_#{…}Connector"` (`DataflowEngine.coffee`). It matches
  exactly the 5 connector methods, 4 of them allowlisted by hand today as "computed dispatch, invisible to a static
  scan";
- exactly one real computed access on a named class: `FormulaHelpers[name]` (`SheetCellRecord._resolveBoundName`).
  Its header promises that a new static method "and nothing else" makes a formula function, and the gate now honours
  that.

Its limits, all erring toward ALIVE (each can only hide a dead method):
- a string label that reads like code (`'MenuWdgt[own]'` in a rig) counts as code;
- a whole-word string equal to a method name counts (a static scan cannot tell a dispatch string from a table string;
  the capstone's `'setMaxDim'` wrap entry keeps `setMaxDim` alive);
- a spread `...rest` reads as `.rest`.

Still blind, as before: a name assembled with `+`, a computed access on an arbitrary object (`@target[action]`), and
two same-named methods on unrelated classes. Those are the allowlist's job.

### 1.4 Measurement under the generic rule (`.scratch/tests-repo-readers/dead-methods-generic.js`)

Today 16 dead (14 allowlisted, 2 symmetry-exempt); under the rule 14 dead.

- **Dead now (4), each verified by hand in both repos:** no property access, no string, no template, no dispatch.
  - `SwitchButtonWdgt.isSelected`. Its last caller, `RadioButtonsHolderWdgt`, was deleted on 2026-08-26 (97a7a647);
    since then only `SystemTest_macroSliderDrivesAToggleButton`'s provenance prose kept it. `getToggleState` (the
    `shown button` pin's getter) answers the question for an n-way switch.
  - `MacroToolkit.dragWindowResizerTo_InputEvents`. It is superseded by `resizeWindowBy`/`resizeWindowTo` (49 sites in
    25 tests), which state the EXTENT change and so do not depend on the grip's size or inset; the last test call went
    in 80ee6ca92. ⚠ It is still TAUGHT: 10 entries of `src/macros/MACRO-PATTERNS.md` and 2 rows of
    `Fizzygum-tests/.claude/skills/author-macro-test/SKILL.md`. Every test those entries describe already calls
    `resizeWindowBy`.
  - `TreeNode.siblings`. Its own comment says "Currently unused"; locals named `siblings` kept it.
  - `Point.theta`. It is the radians twin of `degrees`; locals named `theta` kept it.
- **Alive now (6):**
  - the 4 `_…Connector` entries (template-derived), and `isDesktopShortcut` (two rigs call it):
    5 allowlist entries go STALE and are deleted;
  - `setMaxDim` (a capstone wrap-list string). It is symmetry-exempt today, so it needs no entry either way.
- **Unchanged:** `bringUpTestMenu_InputEvents` and the LCL entries stay dead and allowlisted. A table key is not a
  reference, and those entries still being needed is itself proof of that. `mix` stays alive via clause 4.

### 1.5 Fix shape

1. **New `buildSystem/lib/method-references.js`**, the one definition. `methodReferences(codeLine)` returns
   `{ names, templates, classes }` for clauses 1–4. Its header states the rule, its fail-open limits and its blind
   spots, and names every consumer.
2. **`check-dead-methods.js`:**
   - the src harvest reads `codeOfCoffeeLine` lines through `methodReferences`, keeping the per-method owner
     attribution the settle-symmetry check needs;
   - the tests-repo harvest reads `testsRepoCode(root)` the same way;
   - after both, each template and each computed class adds its matching methods (owner `@computed`).

   The header-line special case goes (§1.3), and the header comment and the FAIL message state the rule.
   `--self-test` gains a tmp-fixture case. MUST reach:
   - a property call; a whole-name string;
   - a template's match;
   - a computed class's class-side member, and a prototype computed access's instance member;
   - a default parameter's call.

   MUST NOT reach:
   - a bare local; an object key; a class-side def key `@m:`;
   - a template with no literal part; a computed-access WRITE;
   - a metadata `intent` word; a macro `#` comment; a JS `//` comment;
   - a reference record; a manifest; a `.scratch/` probe.
3. **Allowlist:** delete the 4 connector entries and `isDesktopShortcut`; the "computed name" section header goes
   with them.
4. **Deletions (D2):** the 4 methods. For `dragWindowResizerTo_InputEvents`:
   - delete aim-census's `VERBS` row and re-run `node scripts/aim-census.js` to show exit 0. ⚠ No gate runs it, so
     nothing else would notice a stale row;
   - point the 10 MACRO-PATTERNS entries and 2 skill rows at `resizeWindowBy`, each stated as the extent change its
     test makes.

   Historical text stays: provenance fields, `docs/archive/`, plans' history.
5. **Docs:**
   - `lint-and-static-checks.md`'s dead-method row and its ⚠⚠ "unkillable" paragraph: the prose half and the
     local-variable half are CLOSED by the rule, and the whole-word-string and same-name halves stay, stated;
   - the reader's and coffee-mask's "Readers" lines.

### 1.6 Proofs (a check is believed only after a plant has failed it)

- `node buildSystem/check-dead-methods.js --self-test` PASS. It FAILS with each clause planted away (the self-test
  must name the clause), and with the bare-word harvest put back.
- Real tree, after step 2 and before step 4: the gate FAILS naming exactly the 4 dead methods, and reports the 5
  entries STALE.
- Real-tree plants, each restored with `git checkout --` and each failing the gate by name:
  - hide the two rigs' `isDesktopShortcut` member calls (clause 1 from `scripts/`);
  - change `DataflowEngine`'s template literal part (clause 3: the connectors go dead);
  - rename `FormulaHelpers[name]` to a local lookup (clause 4: `mix` goes dead).
- `fg build`, then `fg presuite`. Deleting a widget method can shift an inspector member list: confirm one image's
  pixels, then `fg recapture-inspector`.

## §1a Unit 0 — the reader reads JS by LEXING it (a defect the survey found, plus three stated limits)

`lib/tests-repo-code.js` reads JS by line heuristics:
- `jsCode` cuts a comment only when it STARTS a line;
- `macroCode` splits a macro command file on backticks FIRST, then cuts comments in the even (JS) parts.

**Defect (survey, 2026-11-06).** Every macro command file opens with a two-line `//` comment holding backticks
(`` `intent` / `scenario` / … ``). The split pairs those backticks as a template literal, so the comment's words are
read as CoffeeScript code: 744 comment lines in 372 of 373 files. That leaks `intent`, `scenario`, `provenance`,
`AutomatorEventCommandStartMacro`, …. No leaked word is a src method name today, so nothing changes yet; but the
mechanism is not a stated limit, and it errs in the direction (keep a word) that hides dead methods.

**Fix (D4).** New `buildSystem/lib/js-mask.js`, the JS twin of `lib/coffee-mask.js`. One left-to-right lexer labels
every character code / string / comment, handling:
- `//` and `/* */` anywhere, trailing comments included;
- quoted strings with escapes;
- template literals with `${…}` nesting;
- regex literals (the previous-significant-token rule).

`jsCode` becomes "mask, then blank the comments". `macroCode` lexes the file as JS and hands each template literal's
CONTENT to `coffee-mask` as CoffeeScript, so the backtick pairing comes from the lexer, not from a count. Three of the
reader's stated limits go with it:
- a trailing `// …` counts;
- a macro file whose backticks do not pair is read whole;
- a template-literal line starting `//`/`/*` is cut.

What remains is coffee-mask's own limits.

**Verified against `js-tokens` 4.0.0** (present in `Fizzygum-tests/node_modules`, so usable by a `.scratch/` probe;
not a build dependency): token by token over every `scripts/**/*.js` and every macro command file, the comment and
string spans must agree. Every disagreement is either fixed or stated in `js-mask.js`'s header.

## §2 The other readers (survey by one research agent, 2026-11-06; probes in `.scratch/tests-repo-readers/`)

Each probe ran the gate's own code with only the tests-repo read swapped, and each "today" number matches the real
gate's output.

| Gate | Reads the tests repo FOR | Measured, reader vs today | Verdict |
|---|---|---|---|
| `check-unresolved-sends` | harness as definitions AND call sites | 0 change; comments are already cut (`stripComment` on defs, `stripLine` on calls) | **CLOSE** |
| `check-hand-lists` | scripts + harness as SCAN TARGETS; comments are load-bearing (`hand-list-sanctioned:` markers, guard tokens) | the reader turns 27 sanctioned lists into unsanctioned ones (FAIL) and loses 90 guard tokens | **CLOSE**: it must read comments |
| `check-relayout-repaints` | a TOMBSTONE scan of src + harness, raw, comments included | 0 at every scope; the reader would let a comment mention pass | **CLOSE**: keep raw |
| `census-property-placement` | harness as a reference set (string words, `.name` reads) | 0 change: it already masks with `coffee-mask` | **CLOSE** |
| `census-call-arity` | tests + harness + scripts as CALL SITES (advisory) | 49 → 40 holes: −9, all prose (8 metadata, 1 block comment); 0 real holes lost; manifests and `scripts/.scratch` drop out | **ADOPT** (reader as is, `scripts/` whole) |
| `census-doc-member-refs` | harness class/member index for backticked doc refs | 219 = 219 members | **CLOSE** |
| `lib/install-edges.js` | harness `installOnto` member sets (definitions) | 38 = 38 | **CLOSE** |
| `check-layering` rule [D] | macros as scan target; its `# macro-private-call-sanctioned:` markers live in comments (31 in 5 files) | the reader would erase them | **CLOSE**: it must read comments |

Not to be used for `census-call-arity`: member-access-only scope for `scripts/`. It drops 2 REAL constructor holes
(`pin-sweep-headless.js` `new SimpleButtonWdgt(undefined, undefined, {face})`), because a hole is a CALL SHAPE, not a
reference. §1.3's rule answers "is it reached", not "how is it called".

**Two REACH questions the survey surfaced.** Each is a gate WIDENING with real findings to triage, beyond reading
prose:
- **`check-argument-holes`** excludes the tests repo for one stated reason, "its metadata is PROSE". The reader
  removes that reason. Through the reader the tests repo carries:
  - real holes against Fizzygum's own API, e.g. 5 macro constructor holes and pin-sweep's
    `new SimpleButtonWdgt(undefined, undefined, {face})`;
  - 18 `@assertValuesEqual "…", undefined, x` where `undefined` is the expected VALUE.

  Taking it on means triaging those (constructor conversions are family commits) and a ruling on the value case.
- **`check-unresolved-sends`** skips macro sources because "their template-literal bodies produce JS-side false
  positives". The reader removes that reason too: macros as call sites add 2091 sends and 1 false positive (`map`,
  `Array#map`, not in `BUILTINS`). A rename that misses a macro's paren-call would then fail the BUILD rather than
  the suite.

And one census asks a reference question with a bare-word answer: `census-property-placement`'s exclusion 1 counts
every WORD inside any string (`STRING_WORDS`, 3429). By §1.3 only a whole-name string can reach a property. It is
advisory, and its tests-repo reading is already right; filed rather than done.

## §3 Unit C — R4 reads references by the same rule

`census-public-private-calls.js` R4 asks the same question as the dead-method gate ("is this public method referenced
outside src?"). Its external half counts every word of the tests repo's code. Under §1.3's rule
(`.scratch/tests-repo-readers/r4-generic.js`) R4's candidates go 142 → 145. Each addition was masked by a word that
reaches nothing:
- `CaretWdgt.cmd`: a coincident JS local `cmd` in two rigs. Its sibling is already `_ctrl`, but the `_cmd` form is
  REFUSED by [S]: probed 2026-11-06, Edit-tool rename + `check-call-separation.js`, "CaretWdgt._cmd -> @undo". It
  dispatches meta-key commands to the public settling `undo`. Recommendation: allowlist with that reason (the prior
  arc's precedent for refused renames).
- `PenWdgt.forward`: the English word in an assertion message ("the forward direction…"). Recommendation:
  allowlist as PenWdgt turtle API, beside the existing `setHeading` entry.
- `MacroToolkit.syntheticEventsMouseShiftClick_InputEvents`: an aim-census table key. Recommendation: allowlist as
  an L1 synthetic-input primitive of the test-authoring family (the `bringUpTestMenu_InputEvents` precedent).

So all three go to `public-api-allowlist.txt` with their reasons, and `BASELINE_U_QUERY` is unchanged. Unit 0 can
move these numbers (a trailing `//` comment stops counting), so R4 is re-measured after it.

## §4 Owner decisions (one round)

- **D1 — the reference rule:** (a) §1.3's generic rule in `lib/method-references.js`, used by check-dead-methods
  AND R4, with R4's 3 unmasked names allowlisted as §3 says (recommended); (b) the rule for check-dead-methods only;
  (c) the reader only, every word still counted.
- **D2 — the 4 dead methods:** (a) delete all four, re-pointing MACRO-PATTERNS and the skill at `resizeWindowBy`
  (recommended); (b) keep `Point.theta` as polar API (allowlist), delete the rest.
- **D3 — the reader's JS (§1a):** (a) a real lexer, `lib/js-mask.js`, verified against `js-tokens` (recommended);
  (b) a targeted fix (cut the leading comment before the backtick split).
- **D4 — the two reach widenings (§2):** (a) file each as its own BACKLOG item with these numbers (recommended: each
  is a gate's scope change with its own triage); (b) take `check-argument-holes` into this arc; (c) take both.

Execution order: Unit 0 → Unit A → Unit C → `census-call-arity` adopts → the CLOSEs recorded.

## §5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status`: both repos clean at this plan's base (Fizzygum `fab3f8ad`,
   tests `0ea5d7dc0`) plus this arc's own work.
2. Re-run `.scratch/tests-repo-readers/dead-methods-generic.js`. If the numbers differ, re-derive §1.4 before acting.
3. Per unit: edit, then `node buildSystem/<gate>.js` (+ `--self-test`) from `Fizzygum/`, then the unit's plants, then
   `fg build`, then `fg presuite`. Every `fg` call by absolute path, long ones in the background. Never pipe a gating
   `fg` call.
4. Close:
   - `fg gauntlet` (background, ~15 min);
   - `cd Fizzygum-tests && npm run selftest`;
   - `fg homepage` only if `src/boot` or `src/meta` changed;
   - `node scripts/check-visualisations.js --strict` if any test's metadata or macro comments changed;
   - ONE independent end-of-arc review (a fresh agent given the diffs and §0's goals, not this ledger);
   - archive this plan (`mv` to `docs/archive/`, an INDEX line) and move the BACKLOG item into this ledger;
   - draft commit messages and WAIT for approval. Ask about push separately.

## §6 Rejected alternatives

- **Class-aware dead-method detection.** Measured 2026-08-18: only 10% of references to a colliding name carry class
  information, so it would flag 543 pairs to find a handful (`lint-and-static-checks.md`). Not re-attempted.
- **Swapping only the file set** (§1.2): either way the gate keeps counting bare words, so `scripts/`'s name tables
  (counted) or its real calls (uncounted) decide the answer by accident.
- **A member-access rule for `scripts/` only**: it is right for JS rigs, but a special case. The same bare-word flaw
  is in src and the harness, so the rule belongs to every source.
- **Per-name allowlist entries for computed dispatch**: they restate a fact the dispatch site already states, and
  `FormulaHelpers` would need one per helper against its own "and nothing else" promise. Clauses 3–4 derive them.
- **Stripping only the five metadata prose fields** (the 2026-08-18 survey `a2-prose-reference-survey.js`): a
  per-field mask is a second reader.

## §7 References

- `Fizzygum/buildSystem/lib/tests-repo-code.js` (the reader's header: every limit), `lib/coffee-mask.js`.
- `docs/archive/typed-code-saves-residue-plan.md` (Unit 3: the reader's origin and R4's triage).
- `docs/architecture/lint-and-static-checks.md` (the dead-method row and paragraph; R4's reader paragraph).
- `docs/archive/connector-ubiquity-and-reflection-plan.md` BACKLOG ledger (the 2026-08-18 prose survey).

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] **The other gates that read the tests repo still read its prose and comments.** `check-call-separation`'s
      census now reads the tests repo's CODE through `buildSystem/lib/tests-repo-code.js` (harness, macro sources
      and `scripts/`, comments cut, metadata prose and reference records unread). `check-dead-methods` (the
      "ordinary English word is unkillable" blind spot in `lint-and-static-checks.md`), `check-unresolved-sends`,
      `check-hand-lists`, `check-relayout-repaints` and the arity and property-placement censuses read it their own
      way. Adopting the reader may unmask findings of each gate's own (dead methods first), so each is its
      gate's arc: measure, then triage. (Section "archive/typed-code-saves-residue-plan.md".) — CLOSED here: the
      Mandate's Units.

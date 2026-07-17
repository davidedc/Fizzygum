# LiveCodeLang (Fizzytiles DSL) — deep analysis + ranked cleanup / improvement / extension plan

Status: **AUTHORED 2026-07-07, NOT STARTED.** Owner-initiated execution only.

This plan is self-contained and cold-executable: every claim below was verified
against the working tree on 2026-07-07 (file:line receipts inline), and the
headline defects were **reproduced empirically** through the real preprocessor
running headless in Node (recipe in §6 — it is itself the prototype of this
plan's top-ranked deliverable).

**Relationship to `docs/archive/fizzytiles-sw3d-port-plan.md` (authored earlier, also
not started):** that plan owns the *runtime/rendering* half (SW3D vendoring,
`FridgeMagnets3DCanvasWdgt` rewrite, `LCLTransforms` repair, command surface
v1, determinism clock). THIS plan owns the *language* half: the
preprocessor/translator, the compiler plumbing, the test corpus + harness, the
tile→text transliteration, and language-level extensions. §7 lists the three
places where this analysis feeds corrections INTO that plan. Either plan can
be executed first; T1/T2 here don't touch any file the SW3D plan rewrites
(sole exception: R14 deletes `LCLProgramRunner`, which SW3D D8 says "keep" —
resolved in R14).

**Relationship to `docs/archive/accidental-complexity-reduction-plan.md` (authored
2026-07-07 in a parallel session, also not started):** small overlap on dead
code. Its commented-code table already lists `adjustPostfixNotations`
(:496-510) and the commented regex corpses in `transformTimesSyntax` /
`rearrangeColorCommands` — same targets as R11 here (whichever plan executes
first does them; the other skips). It HOLDs `LCLTransforms` pending the SW3D
decision — consistent with this plan (SW3D D4 owns it). ONE conflict: its
keep-list marks `LCLProgramRunner.runProgram`/`runLastWorkingProgram` as
"subsystem entry points — NOT dead". That was a method-level judgment; the
*class-level* fact (verified here by grep, §2.1/D10) is that
`LCLProgramRunner` is never instantiated or referenced anywhere in `src/`
(sole mentions: its own file + a prose comment in `LCLCodeCompiler.coffee:11`)
— so R14's deletion proposal supersedes that keep-list line, with owner
sign-off as the tie-breaker.

---

## §1 Background — what the language is

LiveCodeLang is the DSL of LiveCodeLab (Della Casa & John, *LiveCodeLab 2.0
and its language LiveCodeLang*, FARM '14 — owner's copy at
`~/Downloads/2633638.2633650.pdf`). Design pillars (paper §5/§11):
parenthesis-free invocation (`a b c,d,e` ≡ `a(b(c,d,e))`), CSS color literals
as bare words, indentation to scope *graphics state* (`rotate` + indented
block ≡ push/pop), inlining implies nested scoping down the line
(`rotate red box`), `N times [with i]` loops, `<box>` chevron notation for
anonymous function references, commands with meaningful zero-arg animated
defaults (`rotate` alone = continuous rotation).

The paper describes two implementations: a **nanopass regex source-to-source
translator to CoffeeScript** (fast to iterate, known-inadequate for nested
constructs — paper §12) and a Jison LALR parser/AST interpreter. **Only the
nanopass one was ported into Fizzygum** (`src/fizzytiles/`), where it grew
organically. The paper's runtime (globals `time`/`wave`/color literals, the
quarantine/last-stable-program hot-swap, doOnce ticks, autocoder, sound) was
only partially ported — see D12/D13: large parts compile fine but **cannot
run** in Fizzygum today.

In Fizzytiles the "editor" is spatial: `FridgeWdgt` transliterates dragged
magnet tiles into program text (`putIntoWords`), so the language input is
machine-generated from tile positions *and* hand-editable in the code pane.

---

## §2 As-is inventory & architecture (receipts)

### 2.1 Files (`Fizzygum/src/fizzytiles/`, all homepage-excluded)

| file | lines | role | live? |
|---|---|---|---|
| `LCLCodePreprocessor.coffee` | 1964 | the language: ~33 regex passes LCL→CoffeeScript | LIVE |
| `LCLCodePreprocessor_Testing.coffee.txt` | 3531 | 300 test cases + harness, shipped as `.txt` (NOT compiled; meant to be hand-pasted into the class) | dormant |
| `LCLCodeCompiler.coffee` | 124 | preprocess → `CoffeeScript.compile` → `new Function` | LIVE |
| `LCLProgramRunner.coffee` | 111 | quarantine/last-stable-program + doOnce bookkeeping | **DEAD — zero references** |
| `LCLTransforms.coffee` | 347 | 4×4 matrix-stack runtime draft | **DEAD — zero references, crashes if called** (SW3D plan D4 owns repair) |
| `FridgeMagnetsWdgt.coffee` | 206 | 4-pane app widget | LIVE |
| `FridgeWdgt.coffee` | 185 | tile canvas + `putIntoWords` transliteration | LIVE |
| `FridgeMagnetsCanvasWdgt.coffee` | 258 | 2D runtime scope (runs programs; ctx transforms) | dormant (commented out at `FridgeMagnetsWdgt.coffee:39`) |
| `FridgeMagnets3DCanvasWdgt.coffee` | 571 | 3D pane; hard-coded twgl demo, **never calls `@graphicsCode`** | LIVE (SW3D plan rewrites) |
| `FizzytilesCodeWdgt.coffee` | 17 | code pane; manual edits recompile | LIVE |
| `MagnetWdgt.coffee` | 26 | draggable tile | LIVE |
| `FridgeMagnetsApp.coffee` | 16 | desktop launcher | LIVE |

Plus `src/boot/numbertimes.coffee`: `Number::times`/`Number::timesWithVariable`
global prototype extensions (`(scope, func)` signature — scope passed because
Fizzygum commands are widget methods, not globals; file is homepage-excluded).

### 2.2 Compile pipeline end-to-end

1. Tile drop/grab → `FridgeWdgt.compileTiles` (`FridgeWdgt.coffee:174-178`,
   fired from `_reactToChildGrabbed`/`_reactToChildDropped` :181-185) →
   `putIntoWords()` text → code pane + `fridgeMagnetsCanvas?.newGraphicsCode`.
   Manual pane edits: `FizzytilesCodeWdgt.setText` (:13-16) → same.
2. `LCLCodeCompiler.compileCode` (`LCLCodeCompiler.coffee:28-80`):
   whitespace→`status:'empty'`; else
   `codePreprocessor.preprocessAndBindFunctionsToThis code` → on error
   `status:'error'`; else `CoffeeScript.compile code, {bare:on}` (the
   framework's bundled in-browser compiler), the `var frame` local-var strip
   hack (:71), `new Function compiledOutput` → `status:'parsed'`.
3. Widget stores it: `newGraphicsCode` keeps `@oldGraphicsCode` and swaps only
   if `compilation.program?` (both canvas widgets, e.g. 2D :23-28); per-frame
   `try @graphicsCode() catch → rollback` (2D `paintNewFrame` :50-59). The 3D
   widget never invokes it (`FridgeMagnets3DCanvasWdgt.coffee:432-438` — the
   call exists only as comments; SW3D plan owns).
4. **Scope model:** `preprocessAndBindFunctionsToThis`
   (`LCLCodePreprocessor.coffee:1701-1712`) prefixes every *command* with `@`;
   program runs with `this` = the canvas widget, so commands must be widget
   methods. *Expressions* (`sin`, `wave`, `random`, `time`, …) and *color
   literals* are NOT `@`-bound and resolve to bare identifiers — see D12/D13.

### 2.3 The preprocessor pipeline (order as wired in `preprocess`, :1715-1851)

`[code, error]` tuples are hand-threaded through every pass; each pass starts
with `return [undefined, error] if error?` (30+ copies of the boilerplate).

| # | pass | line | one-liner |
|---|---|---|---|
| 1 | `removeStrings` | :234 | strings → `'STRINGS_TABLE>n<STRINGS_TABLE'` refs |
| 2 | `findUserDefinedFunctions` | :1243 | scan `a = ->` / `a = (…) ->` forms → regex fragments |
| 3 | `findBracketVariables` | :1283 | scan `a = <…>` → `BRACKETVAR a BRACKETVAR` marks |
| 4 | `stripCommentsAndStrings` | :338 | comments out (line-preserving); strings-less copy for checks |
| 5 | `removeTickedDoOnce` | :211 | `✓doOnce` → `if false` / `noOperation` |
| 6 | `checkBasicSyntax` | :426 | paired-delimiter parity count; rejects `;` typed by user |
| 7 | `substituteIfsInBracketsWithFunctionalVersion` | :1684 | `a = <if …>` → `ifFunctional(…)` |
| 8 | `removeDoubleChevrons` | :1411 | `>>` → space |
| 9 | `rearrangeColorCommands` | :1441 | `red fill`→`fill red`, bare color→`fill color`, redundancy errors |
| 10 | `normaliseTimesNotationFromInput` | :649 | `.times`/arrow variants → canonical `x times [with v:]` |
| 11 | `checkBasicErrorsWithTimes` | :669 | "how many times?" guards |
| 12 | `addTracingInstructionsToDoOnceBlocks` | :261 | `doOnce` → `addDoOnce(line); 1.times ->` |
| 13 | `identifyBlockStarts` | :1854 | indentation analysis (feeds 14) |
| 14 | `completeImplicitFunctionPasses` | :1906 | block-opening command lines get trailing `->` / `, ->` |
| 15 | `bindFunctionsToArguments` | :716 | `sin a` → `sin⨁a` (expr/arg tying; ⧻ blocker for `times`) |
| 16 | `transformTimesSyntax` | :743 | `N times` → `(N).times ->` (♦ marker choreography) |
| 17 | `transformTimesWithVariableSyntax` | :884 | `times with i` → `.timesWithVariable -> (i) ->` |
| 18 | `unbindFunctionsToArguments` | :702 | strip ⨁ |
| 19 | `findQualifiers` | :1071 | matrix/prim chain heads → `rotateing❤QUALIFIER` marks |
| 20 | `fleshOutQualifiers` | :1114 | qualifier marks → nested `(→ …)` closures |
| 21 | `adjustFunctionalReferences` | :915 | `<box>` → `(box♠)`; `<box 2>` → `((parametersForBracketedFunctions)->…)` |
| 22 | `addCommandsSeparations` | :1054 | `cmd cmd` → `cmd();cmd` |
| 23 | `adjustImplicitCalls` | :956 | bare commands/exprs get `()` (delimiter-aware) |
| 24 | `adjustDoubleSlashSyntaxForComments` | :1395 | `//` → `#` |
| 25 | `evaluateAllExpressions` | :1354 | more `()` explicitation around delimiters |
| 26 | `avoidLastArgumentInvocationOverflowing` | :1597 | close-paren counting so last args don't swallow chains (★/☆) |
| 27 | `fixParamPassingInBracketedFunctions` | :946 | `(), ->` cleanup for bracketed fns |
| 28 | `putBackBracketVarOriginalName` | :1310 | strip `BRACKETVAR` marks |
| 29 | `addScopeToTimes` | :1322 | `.times ` → `.times @, ` (scope arg for `Number::times`) |
| 30 | `beautifyCode` | :569 | ~25 normalization/cleanup replaces |
| 31 | `simplifyFunctionDoingSimpleInvocation` | :532 | `a -> b()` → `a b` |
| 32 | `simplifyFunctionsAloneInParens` | :545 | `(F)` → `F` |
| 33 | `injectStrings` | :249 | restore string literals |

Dead passes kept in the file: `adjustPostfixNotations` (:496-510, fully
commented), `identifyBlockEnd` (:1883, "we might not need this"),
`preprocessAndBindFunctionsToThis` is live (called by the compiler) despite
its comment claiming "not used at the moment" (:1698-1700).

### 2.4 Sentinel characters (in-band, single source of truth is "grep")

`→` (arrow protection), `♦` (times/color marker), `♠` (color-command marker
AND `>,` chevron protection), `❤` (`ing❤QUALIFIER`), `⨁` (expr-arg tie), `⧻`
(times blocker), `★`/`☆` (pass 26), `›` (functional-if protection), plus
user-visible `✓` (doOnce tick) and `▶` (tab notation in tests/docs). User
input containing any of these (except `✓`, which is validated :224-225) is
silently corrupted — there is no rejection check.

### 2.5 The test corpus & harness (`LCLCodePreprocessor_Testing.coffee.txt`)

- **300 test cases** (`testCases:` array), each `notes`/`input`/`expected`
  (or `error:`), `▶`≡tab. The corpus is the *de facto language spec* — richer
  than any doc: times variants, qualifier chains, color rearrangement error
  cases, chevron functions, ifFunctional, doOnce, idempotency notes.
- Harness (`test:` at txt:3426) checks: exact expected output, expected
  error, **idempotency** (`preprocess(preprocess(x).replace(/;/g,'')) ==
  preprocess(x)`), and two **robustness sweeps**: *moot appends/prepends* —
  rename every keyword occurrence by appending `s` / prepending `t` (making
  them plain user identifiers) and assert the preprocessor leaves the program
  unchanged. Moot failures only log + count; they never fail a case.
- Annotations present: `notIdempotent: true`×22 / `false`×11;
  `failsMootAppends: true`×46 / `false`×11; `failsMootPrepends: true`×25;
  `knownIssue` supported by the harness but used by 0 cases.
- **To run today** you must hand-copy `testCases`+`test` into the class
  (stubs at `LCLCodePreprocessor.coffee:23-24`) and call `…test()` from a
  browser console; the path hint in the header comment
  (`world.children[5].children[2].lclCodeCompiler…`, :10-13) is stale (the
  widget now lives inside a window opened by `FridgeMagnetsApp`/menu).
- **Baseline measured 2026-07-07** (headless, recipe §6): **300 pass, 0
  fail, 0 moot-append failures, 93 moot-prepend failures** (all 93 caused by
  one bug — D1; after the 5-character fix: **0**).

### 2.6 Runtime scope implementations (for reference)

2D `FridgeMagnetsCanvasWdgt` implements `scale/rotate/move` as ctx transforms
with the LCL appended-function protocol (save → run chained fns via
`.apply @` → restore; `!result?` → "fake function" undo, :74-204), `box` stub
(fixed `rect -50,-50,100,100`, args computed then ignored, :206-257), `pulse`
(wall-clock, :61-72). `LCLTransforms` duplicates all of this as a matrix
stack (dead+broken: `@scaleMatrix` called at :254 but `scaleMatrix` is a
class-body closure `=` var :35 → TypeError; `@backBufferContext` leftovers
:290,:331; bare `discardPushedMatrix()` :303,:344; `makeTranslation`
row-major :188-206 vs column-major everywhere else; third copy of `pulse`
:210-221). `pulse` exists 3×, `commonPrimitiveDrawingLogic`+`box` 2×.

---

## §3 Verified defect catalog

Every item below was **reproduced** (probe transcripts in §6.3) or read
directly from source at the cited lines. Severity: ● high ◐ medium ○ low.

**D1 ● `addScopeToTimes` string-regexes don't escape the dot**
(`LCLCodePreprocessor.coffee:1327,1331,1337,1343,1348` — `RegExp("\.times…")`
in a *string* is `.times` = any-char + `times`). Consequence: any user
identifier ending in `times` is captured — `20 ttimes trotate` →
`20 .times @, trotate`. **This one bug causes all 93 moot-prepend failures;
escaping the five dots → 0 failures, 300/300 still pass** (verified §6.3-a).

**D2 ● `preprocessAndBindFunctionsToThis` regex built from a string with
unescaped `\w`/`\d` + empty alternation branches** (:1707:
`RegExp("(|[^\w\d\r\n])(cmds)(|[^\w\d\r\n])")` → char class `[^wd\r\n]`, and
`(|…)` always matches empty). Net effect: **every command-name substring
anywhere gets `@`-prefixed**. Verified end-to-end: `outline = 5\nbox outline`
→ `out@line = 5\n@box out @line` (CoffeeScript syntax error → program
rejected with baffling error); `running = 4` → `@running = 4` (compiles;
**silently writes a persistent property onto the widget**, breaking the
language's stateless-per-frame model AND polluting the widget instance).

**D3 ● Command-adjacency passes lack right-boundary guards.**
`addCommandsSeparations` :1061 (`RegExp("(cmds)([ \t]*)(cmds)…")` — no
`(?![\w\d])`): `moveball` → `move();ball` (verified standalone). In
`findQualifiers` :1103 the spanned-to token is followed by
`([^\w\d\r\n]*)` which matches empty, so `box running` → qualifier capture →
`@box -> @running` (verified end-to-end). Same family as the moot-append
sweeps but on the *left* side of identifiers; today's corpus never feeds such
identifiers so the 300 stay green.

**D4 ◐ `[\\t ]` inside regex *literals* matches backslash/`t`/space, never
tab** — 5 sites: :573, :575 (beautify `.times` spacing), :785 (times normal
form), :1446, :1448 (`(^[\\t ]*…)` in redundant-stroke/fill checks). Double
defect (verified): the intended tab handling never fires (`.times\tx`
untouched) and `.timestamp` → `.times amp`. (All `RegExp("…[\\t ]…")`
*string* builds elsewhere are correct.)

**D5 ◐ Test harness flag semantics: existence beats value.**
txt:3445-3446: `testIdempotency = !error? and !(testCase.notIdempotent?)`,
`testMoots = !error? and !(testCase.failsMootAppends?)` — `?` tests
*existence*, so the 11 `notIdempotent: false` and 11 `failsMootAppends:
false` annotations **disable the very checks they claim to enable**.
`failsMootPrepends` (25 annotations) is **never read** by the harness at
all; moot results are counters only, never pass/fail. So the robustness
sweeps have quietly stopped gating anything.

**D6 ◐ `tan` (and only `tan`) is both a CSS color literal and an expression**
(`expressions` :123 vs `Color.TAN` — `colorsRegex` is built from all 138
uppercase `Color` constants, :148-154). Verified: `fill tan\nbox` →
`fill tan()\nbox()` → runtime `fill(NaN)`. The color *tan* is unusable.

**D7 ◐ `MagnetWdgt.leftCenter/rightCenter` overrides are wrong AND shadow
correct base methods** (`MagnetWdgt.coffee:22-26`: y = `@height()/2`,
position-independent — vs `Widget.coffee:917-921` delegating to `@bounds`).
Works today only because all magnets share one height (y-error is constant so
x decides). Fix = delete both overrides.

**D8 ◐ `FridgeWdgt.magnetFollowing` sorts candidates farthest-first**
(:75-80: comparator returns 1 when `arr[a] < arr[b]` — descending — under a
"Sort by distance" comment). The reciprocity walk (:88-93) then tests the
*farthest* same-line magnet first; with >2 tiles per line this can pick a
wrong successor. Fix = ascending sort (and a transliteration test, R6).

**D9 ○ `wasFunctionNameAlreadyFound` uses regex `match` for equality**
(:1207-1212: `strArray[j].match(str)`) — substring/regex semantics, so a new
function `a` is "already found" if `ab` was seen. Fix = `===` / `includes`.

**D10 ○ Dead/broken code inventory.** `LCLProgramRunner` — zero references
(§2.1); its class body uses `=` not `:` (:17-32) so those "fields" are
closure locals, never instance state; its `addToScope` calls a
`scope.addFunction` API that exists nowhere in Fizzygum. `LCLTransforms` —
dead + 5 distinct crashes/wrongness (§2.6; SW3D D4 owns repair).
`adjustPostfixNotations`, `identifyBlockEnd` — dead. `checkBasicSyntax` /
`checkBasicErrorsWithTimes` set a `programHasBasicError` var that's never
read (:457, :698). Stale header comment (§2.5). `FridgeWdgt.tabs: []`
class-level shared field is shadowed by a local and dead (:5 vs :138).

**D11 ○ O(n²) char-by-char scans.** `doesProgramContainStringsOrComments`
(:324-336) and `checkBasicSyntax` (:438-452) loop `code.slice(1)` per
character — quadratic on every keystroke-compile. Fine at toy sizes; trivial
to make single-pass indexed loops.

**D12 ● The expression surface is unimplemented at runtime.** Expressions
are deliberately not `@`-bound (§2.2), and nothing defines them: verified
`rotate wave\nbox` → `@rotate wave()`, `box time` → `@box time` — `wave`,
`time`, `sin`, `random`, `frame`, `noise`… are unbound identifiers in the
compiled `Function` → ReferenceError on first frame → silent rollback via
try/catch. In LiveCodeLab these were injected globals; the port never brought
the runtime. **Any program using any expression or `time` cannot run in
Fizzygum today** (it compiles and dies silently).

**D13 ● Color literals are unimplemented at runtime.** Verified: `fill red`
→ `@fill red` → `this.fill(red)` — `red` unbound → same silent-crash fate as
D12. (`rearrangeColorCommands` + `colorsRegex` handle colors *syntactically*
only.) The 138 `Color` uppercase constants exist (`Color.coffee`) but no
lowercase runtime names.

**D14 ◐ doOnce machinery is severed.** The translation passes emit
`addDoOnce(n)` calls (pass 12), but `addDoOnce` is not a command (not
`@`-bound) and only `LCLProgramRunner.addToScope` (dead) ever provided it →
ReferenceError at runtime. The tick-writeback path
(`LCLCodeCompiler.addCheckMarksAndUpdateCodeAndNotifyChange` :84-123) needs
`@eventRouter` — always `undefined` (both widgets do `new LCLCodeCompiler`
with no args, 2D :33 / 3D :57). doOnce = compiles, then crashes silently.

**D15 ○ `window.ifFunctional` is installed as a global from the
preprocessor's *constructor*** (:170-186) — a runtime dependency smuggled in
by a translator side effect; two `LCLCodePreprocessor` instances = two
overwrites. It also means the *translation* tests depend on constructing an
object that mutates `window` (the §6 harness must stub `window`).

### Design limitations (inherent, keep-or-accept — not "bugs")

- **L1** Regex nanopass cannot handle arbitrarily nested constructs
  (paper §12 acknowledges; the corpus documents the working envelope). The
  alternative (port the Jison/AST implementation) is a rewrite — banked, §8.
- **L2** Error messages surface CoffeeScript errors against the *transformed*
  code (`compileCode` returns the raw exception, :52-59) — line/column don't
  map back to what the user typed/tiled. Mitigation ideas in R17.
- **L3** "Function anywhere = function everywhere" for user identifiers
  (:1214-1241, self-documented) — acceptable, documented trade-off.
- **L4** `Number::times` prototype extension is enumerable global pollution
  (`boot/numbertimes.coffee:35-48`); low risk, homepage-excluded. Option:
  `Object.defineProperty` non-enumerable (R13).

---

## §4 Ranked plan

Ranking criteria: (value ÷ risk), with test-infrastructure first because it
converts everything else from "careful" to "mechanical". Effort: S < ½day,
M ≈ 1 day, L = multi-day. Each tier ends with the full gate (§6.1).

### T1 — Make the language testable from the command line (do first)

- **R1 (S) Headless preprocessor test gate.** Productionize the §6.2 harness:
  a Node script (proposed home: `Fizzygum-tests/scripts/test-lcl-preprocessor.js`,
  wired as `npm run test:lcl` and — optionally — into `fg gauntlet`) that
  (a) extracts the 138 color names from `src/basic-data-structures/Color.coffee`,
  (b) stubs `global.nil`/`global.window`/`global.Color`, (c) concatenates
  `LCLCodePreprocessor.coffee` (minus the two `nil` stub fields :23-24) with
  the `testCases`/`test` fields from the `.txt`, compiles with the global
  `coffee`, runs `test()`, and **fails on exit-code** if `failed > 0` or the
  moot counters exceed a checked-in baseline. Keep the `.txt` as the single
  source of the corpus (no duplication); the script assembles at run time.
  Verified feasible: this exact assembly ran the full corpus today (§6.2).
- **R2 (S) Fix D1** (escape the five dots in `addScopeToTimes`) and lock the
  moot-prepend baseline at **0** in R1's gate. Delete/repurpose now-moot
  `failsMootPrepends` annotations after re-measuring per-case.
- **R3 (S) Fix the harness itself (D5):** test flag *values* (`isnt true`),
  actually read `failsMootPrepends`, make moot failures fail unannotated
  cases, print per-case moot diffs only on failure. Re-annotate honestly from
  a fresh run (expect: append-annotations still true×~46; prepend ones now 0).
- **R4 (S) Update the stale run instructions** (`LCLCodePreprocessor.coffee:10-13`
  and the `.txt` header) to point at the R1 script; document the corpus's
  role as language spec.

### T2 — Correctness fixes in the live translation path

- **R5 (M) Rewrite `preprocessAndBindFunctionsToThis` (D2).** Correct
  escaping and boundaries — e.g. build from properly-escaped fragments:
  `RegExp("(^|[^\\w\\d@$.])(" + @allCommandsRegex + ")(?![\\w\\d$])", 'gm')`
  with `$1@$2` replacement — plus tests: extend R1's harness with a *binding
  sweep* (run every corpus case through
  `preprocessAndBindFunctionsToThis` and moot-style identifier mutations
  through it; today's moots only exercise `preprocess`). Acceptance probes
  (must hold): `outline = 5` untouched; `running = 4` untouched;
  `box()` → `@box()`; `fill red` → `@fill red`.
- **R6 (S) Word-boundary guards (D3):** `(?![\w\d])` on the right token of
  `addCommandsSeparations` :1061 and require ≥1 non-word char (not `*`) after
  the spanned-to token in `findQualifiers` :1103. Add corpus cases:
  `moveball = 3`, `box running`, `a = boxes`.
- **R7 (S) Regex-literal tab fixes (D4):** five sites; add corpus cases with
  real tabs around `.times` and a `.timestamp`-style identifier.
- **R8 (S) Magnet geometry (D7, D8):** delete the two `MagnetWdgt` overrides;
  flip `magnetFollowing`'s comparator to ascending. Cover with a small
  headless macro test *when the SW3D plan's B2 adds Fizzytiles macro
  coverage* (three tiles on one line, assert code-pane text) — or, cheaper,
  a pure-function probe of `putIntoWords` in the R1 script style.
- **R9 (S) `tan` collision (D6):** exclude `tan` from `colorsRegex` (one-line
  filter at :148-154) and document "the CSS color `tan` is reserved by trig"
  — OR context-resolve (color position wins after `fill/stroke/background`).
  Recommendation: exclude + document; revisit if color tiles arrive (R16).
  Add corpus case pinning whichever behavior is chosen.
- **R10 (S) `wasFunctionNameAlreadyFound` equality (D9)** + corpus case with
  functions `a` and `ab`.

### T3 — Dead weight & duplication (no behavior change; corpus must stay 300/0)

- **R11 (S) Delete dead code:** `adjustPostfixNotations` (:496-510),
  `identifyBlockEnd` (:1883-1904), `programHasBasicError` writes,
  `FridgeWdgt.tabs` class field, the `#@codePreprocessor` duplicate line
  (`LCLCodeCompiler.coffee:25`), commented-out regex corpses in
  `rearrangeColorCommands`/`evaluateAllExpressions` (keep the *explanatory*
  comments — they're breadcrumbs; delete only dead executable lines).
- **R12 (M) Deduplicate the runtime protocol helpers:** one `pulse` (per SW3D
  D6 it becomes the widget-clock version), one
  `commonPrimitiveDrawingLogic`/appended-function argument-classifier shared
  between widgets (small mixin-free helper class or base-class method — plain
  OO delegation per house style). Coordinate with SW3D B1 (it rewrites the 3D
  widget's copy anyway — do R12 after B1 lands, or fold into it).
- **R13 (S) `numbertimes.coffee` hygiene:** `Object.defineProperty`
  non-enumerable for `times`/`timesWithVariable` (L4); keep signatures.
- **R14 (S) `LCLProgramRunner`: delete** (D10). It is unreferenced, its
  fields are broken closure vars, its `scope.addFunction` API doesn't exist
  here, and `newGraphicsCode`+try/catch already provide the rollback the
  widgets need. SW3D plan D8 said "keep, don't wire" *within that arc's
  scope*; this plan proposes actual deletion as a separate owner-approved
  commit — the class survives in git history and in the LiveCodeLab repo.
  Port `run`'s semantics to the widget first (SW3D D7 does; see §7-i).
  If the owner prefers keeping a future quarantine mechanism visible, the
  fallback is R14': fix the `=`→`:` fields + comment "dormant, unwired".

### T4 — Preprocessor structural refactor (behavior-preserving, corpus-locked)

- **R15 (L) Pass-pipeline framework.** Replace the hand-threaded
  `[code, error]` tuples and 30+ `return [undefined,error] if error?` copies
  with a driver: `PASSES = [{name, fn}...]`, one loop, short-circuit on
  error, `detailedDebug` tracing (name + before/after) for free — and the
  per-pass numbered `console.log` clutter (~90 lines) deleted. Also: a
  `SENTINELS` constant + an up-front input check rejecting user code
  containing sentinel characters (§2.4) with a clear error (same style as
  the `✓` check :224-225). Acceptance: corpus 300/0, moots 0/0, plus a
  full-corpus *output snapshot diff* (byte-identical transformed output
  before/after — the harness already produces the strings; write them to a
  golden file once, compare after).
- **R15b (M, optional) Single keyword table.** `qualifyingCommands` /
  `primitives` / `commandsExcludingScaleRotateMove` / `expressions` +
  the widget's method surface + the magnet palette are today four
  hand-synced lists. One table (name → {kind: qualifier|primitive|command|
  expression, tile: bool}) consumed by preprocessor regex-building, widget
  stub generation (SW3D D7's no-op list), and `FridgeMagnetsWdgt`'s magnet
  construction. Do only if R16 (more tiles) is wanted; otherwise skip (YAGNI).

### T5 — Language/runtime extensions (each independently optional; owner picks)

- **R16 (M) Implement the missing runtime surface (D12, D13)** — makes the
  *language as documented* actually runnable in Fizzytiles. On the (post-SW3D)
  canvas widget: `time` (widget clock per SW3D D6, seconds), `frame`
  (incremented per step), `wave/beat/pulse` (clock-derived), math wrappers
  (`sin/cos/…/abs/…` → `Math.*`), `random/randomSeed/noise/noiseSeed`
  (seeded PRNG — deterministic under Automator per DETERMINISM.md), and the
  138 lowercase color literals (from `Color` constants; as getters returning
  whatever `fill` consumes per SW3D D7). Mechanism choice (decide at
  execution): (a) `@`-bind expressions too (extend R5's regex; colors become
  widget getters), or (b) inject a prologue into the compiled `Function`
  (`var sin = …, red = …;`). (a) keeps one binding mechanism — recommended.
  Acceptance: `rotate wave\nbox`, `fill red\nball`, `box time % 1` render
  without rollback; corpus untouched (translation output unchanged).
- **R17 (M) Error UX.** Two cheap wins: (1) `compileCode` maps CoffeeScript
  parse-error line numbers back through the (line-preserving) passes — most
  passes keep line counts stable (strings/comments/doOnce explicitly do);
  emit "line N of your code" with the offending *user* line quoted. (2)
  surface preprocessor errors (`"how many times?"`, `"redundant fill"`, …)
  in the Fizzytiles code pane (e.g. a one-line status under
  `liveCodeLangOutputHeader`) instead of silently keeping the old animation.
  (Runtime-crash indication — D12-style silent rollback — belongs with SW3D
  B1's try/catch; add a visible "program error, showing last good" hint.)
- **R18 (S) doOnce decision (D14).** Recommend **descope**: keep the
  translation passes + corpus cases (they're part of the language), but
  document "doOnce is inert in Fizzytiles v1" and make `addDoOnce` a no-op on
  the widget so programs using it *run* instead of silently dying. The full
  tick-writeback (editor round-trip via `FizzytilesCodeWdgt`) is banked in §8.
- **R19 (M) Grow the tile palette** once R16 lands: `fill` + a few color
  tiles, `ball`, `peg`, `N times` (number + times tiles), `move`. Pure
  Fizzytiles UX (magnets are 4 hard-coded `MagnetWdgt`s,
  `FridgeMagnetsWdgt.coffee:63-86`); the transliteration already handles
  arbitrary labels. Gate: each new tile's word round-trips through
  `putIntoWords` → compile → render.
- **R20 (L) Language-reference doc extracted from the corpus.** Generate
  `docs/livecodelang-reference.md` from the 300 cases' `notes`+`input`
  (+`expected` for the curious) — the corpus is already the spec; make it
  readable. Semi-automatable in the R1 script (`--emit-doc`).

**Suggested first bite:** T1 whole (R1–R4) + R5–R7 — one arc, ~2 days,
converts the language from "untested black box with 93 silent corruptions"
to "gated, boundary-safe, headless-verified", with zero behavior change for
existing tile programs. T5 items only after the SW3D plan's B1 lands (they
need a widget that actually runs programs).

---

## §5 Execution rules (owner's standing preferences)

- Phases run straight through with verification per phase; ONE end-of-arc
  review; **no commits/pushes without explicit approval** (present summary +
  message first).
- No "done/safe/byte-identical" claims before the corresponding gate has
  actually passed.
- Comments/docs are deliverables: when deleting dead code (R11/R14), keep
  explanatory breadcrumbs; when fixing regexes, comment the failure mode the
  fix prevents (one line each).
- If a fix shape gets falsified twice, stop and re-frame (don't iterate a
  third variant).

---

## §6 Gates, harness recipe, probe receipts

### 6.1 Full gate per tier

1. `test:lcl` (R1) — corpus 300/0, moot appends 0 over baseline, moot
   prepends 0 (post-R2), idempotency 0 unexpected.
2. `fg build` (syntax gate — the preprocessor is itself shipped source and
   must pass the fragmented-compile check).
3. `fg suite` 190/0 (blast radius on existing SystemTests is zero today — no
   test touches fizzytiles — but the gate is cheap insurance; keep webkit leg
   for anything touching rendering).
4. For T4 (refactor): golden-output byte-diff over all 300 transformed
   outputs, before vs after.

### 6.2 Headless harness recipe (verified working 2026-07-07)

```bash
SRC=Fizzygum/src/fizzytiles; SCRATCH=$(mktemp -d)
# 1. testCases+test fields (strip the .txt's column-0 header comments)
awk 'found||/^  testCases:/{found=1; print}' \
  $SRC/LCLCodePreprocessor_Testing.coffee.txt > $SCRATCH/fields.coffee
# 2. class minus its two nil stubs, plus fields, plus export
grep -v -E '^  (testCases|test): nil$' $SRC/LCLCodePreprocessor.coffee \
  > $SCRATCH/combined.coffee
cat $SCRATCH/fields.coffee >> $SCRATCH/combined.coffee
echo -e "\nmodule.exports = LCLCodePreprocessor" >> $SCRATCH/combined.coffee
coffee -cb $SCRATCH/combined.coffee
# 3. color names for the Color stub
grep -oE '@[A-Z_0-9]+:' Fizzygum/src/basic-data-structures/Color.coffee \
  | tr -d '@:' | sort -u > $SCRATCH/colornames.txt
# 4. run
node -e '
const fs=require("fs"),d=process.argv[1];
global.Color={};for(const n of fs.readFileSync(d+"/colornames.txt","utf8").trim().split("\n"))Color[n]=1;
global.nil=undefined; global.window={};
new (require(d+"/combined.js"))().test();' $SCRATCH
```

### 6.3 Probe receipts (all reproduced 2026-07-07 through the real pipeline)

a. **Baseline:** `passed: 300, failed: 0, moot appends: 0, moot prepends: 93`.
   After escaping the 5 dots in `addScopeToTimes` (D1/R2):
   `passed: 300, failed: 0, moot appends: 0, moot prepends: 0`.
   Sample corruption: `tmyFunc = -> 20 ttimes trotate tbox` →
   `tmyFunc = -> 20 .times @, trotate tbox`.
b. **D2:** `preprocessAndBindFunctionsToThis("outline = 5\nbox outline")` →
   `"out@line = 5\n@box out @line"`; `("running = 4\nbox running")` →
   `"@running = 4\n@box -> @running"` (the latter also exhibits D3's
   qualifier capture).
c. **D3 (standalone regex):** `moveball = 3` → `move();ball = 3`.
d. **D4:** `/\.times[\\t ]+/` : `.timestamp` → `.times amp`; `.times\tx`
   unmatched.
e. **D6:** `preprocess("fill tan\nbox")` → `"fill tan()\nbox()"`.
f. **D12/D13:** `bind("fill red\nbox")` → `"@fill red\n@box()"` (`red`
   unbound); `bind("rotate wave\nbox")` → `"@rotate wave()\n@box()"` (`wave`
   unbound); `bind("box time")` → `"@box time"` (`time` unbound).
g. **Working-envelope positives (for regression comfort):**
   `rotate (1+2)*sin(time), (wave 2)+1 box` →
   `rotate (1+2)*sin(time), (wave(2)+1), box`;
   `5 times with i / rotate / box i` → `5.timesWithVariable @, (i) ->…`;
   `either = (a,b) -> if random > 0.5 then run a else run b` +
   `either <box>, <peg>` → `either box, peg` (see §7-i for the `this` catch).

---

## §7 Feed-forward corrections INTO `fizzytiles-sw3d-port-plan.md`

i. **D7's `run` port must invoke with the widget as receiver.** `<box>`
   references collapse to bare `@box` method references (§6.3-g), so
   `run: (f, chained) ->` must call `f.call @` / `chained.call @` (the
   original `LCLProgramRunner.run` :52-62 calls `functionToBeRun()` unbound —
   `this` would be `undefined` and every primitive crashes). Same rule
   already followed by the appended-function protocol (`.apply @`).
ii. **B1's command stubs won't save expression/color programs** (D12/D13):
   with only D7's command surface, any tile/typed program using `wave`,
   `time`, or a color name still dies silently. Fine for v1 (4 magnets emit
   none of those) — but the B2 macro tests must only use command-surface
   programs, and R16 here is the real fix.
iii. **LCLTransforms repair checklist gains one item** beyond D4's list:
   `scaleMatrix` is a class-body closure `=` binding (:35) invoked as
   `@scaleMatrix` (:254) — TypeError even after the other four fixes; make it
   a real method.

---

## §8 Non-goals / banked ideas

- Porting the Jison/AST LiveCodeLang implementation (paper's second impl) —
  a rewrite; the nanopass + 300-case corpus is the asset here (L1 accepted).
- Autocoder, sound (`bpm`/`play` stay no-op stubs), code sharing — paper §14
  directions, out of scope.
- doOnce tick-writeback round-trip into `FizzytilesCodeWdgt` (R18 descopes).
- 2D `FridgeMagnetsCanvasWdgt` revival (stays dormant).
- On-the-fly symbol swaps (`->`→è etc.), camelCase autocorrect (paper §14).
- Web-Worker translation (paper §7 note) — pointless at Fizzytiles sizes.

## §9 Landing checklist (fill during execution)

- [ ] T1: `test:lcl` gate exists + green; D1 fixed; moot baselines locked
      (300/0/0/0); harness flag semantics fixed; docs/comments updated.
- [ ] T2: D2/D3/D4/D6/D7/D8/D9 fixed, each with a pinning corpus/probe case;
      binding sweep added; corpus grown accordingly (300 → ~310).
- [ ] T3: dead code gone (incl. R14 decision recorded); dedup done; corpus +
      suite + build gates green.
- [ ] T4: pass framework in; sentinel input check in; golden-output diff
      byte-identical; corpus green.
- [ ] T5: per-item acceptance probes green (R16: the three programs render;
      R17: both error paths visible; R19: each tile round-trips).
- [ ] End-of-arc review presented; commits proposed (not pushed) with
      messages per repo.

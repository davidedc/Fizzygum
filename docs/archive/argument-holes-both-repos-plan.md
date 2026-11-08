# The hole test over both repos: a code parser, the callers test, and the button family's head in opts

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**

**STATUS: CLOSED 2026-11-07 — Units 0, A–E done; close gauntlet 20/20 (twice: before and after the end-of-arc
review's fixes); one independent review, findings R1–R7 addressed (§9). Owner round answered (§9 "OWNER ROUND
ANSWERED" amends §4–§5). The gate: `[argument-holes] OK — 0 holes over 50837 calls`.** Owner ruling D5 of the tests-repo-readers arc
(`docs/archive/tests-repo-readers-plan.md`, ledger entry "Owner ruling D5") made this its own arc. Authored at
Fizzygum `47f42386` / Fizzygum-tests `a1627d4e8`, both trees clean, build FRESH, last `fg gauntlet` 20/20 OK.
⚠ Unit 0 overturned parts of §1.4 and §4 (D3(b)'s witness basis, D3(c), the family-site count, three residue
holes §1.4 does not list) — §9's Unit 0 entry is the authority until the round's answers amend them.

**MANDATE — elimination, not a better ratchet.** At the end of this arc:
1. `Fizzygum/buildSystem/check-argument-holes.js` judges every call site in **both** repos — `Fizzygum/src/**`, the
   tests repo's harness, every macro source, and `Fizzygum-tests/scripts/**/*.js` — with the conventions doc's
   **callers test** applied mechanically, by a real parser.
2. It is an **exact hard zero**. There is no `BASELINE`, no ratchet, no tighten-me note: one hole fails the build.
3. Every `undefined` it accepts is accepted for a stated reason — either the callers test judges it a VALUE (the
   gate can print which sites, and why), or it carries a sanction marker with its reason (D4). Every sanctioned value
   is listed in §9's ledger and printed by the gate's pass line.
4. The button family's `(target, action, opts)` head is gone: `ButtonWdgt` and every family member that shared that
   head take `(opts = {})`, in both repos, pixel-neutral, ONE commit per repo.
5. ONE parser serves the gate AND the advisory census (`census-call-arity.js`): the regex parser is deleted, not kept
   beside the new one.
6. The gate keeps its rule registry and gets a bite-proof that plants EVERY rule — including the callers test's
   value/hole distinction as a minimal pair, and a hole planted in the tests repo.

---

## §0 Orientation

### §0.1 The project in one paragraph

Fizzygum is a CoffeeScript GUI framework (a "web operating system" on one `<canvas>`). The umbrella directory
`/Users/davidedellacasa/code/Fizzygum-all/` is NOT a git repo; it holds three sibling repos: `Fizzygum/` (framework
source, ~560 `.coffee` files under `src/`, plus the build and its 33 static gates under `buildSystem/`),
`Fizzygum-tests/` (373 SystemTests — each a CoffeeScript **macro** inside a JS template literal — plus the Automator
harness in `Automator-and-test-harness-src/` and ~120 Node scripts and rigs in `scripts/`), and `Fizzygum-builds/` (generated).
Every class is a global; there is no module system. Classes ship as source TEXT and are compiled in the browser by
`src/meta/Class.coffee`, which splits each class into FRAGMENTS (constructor + each member) and compiles them one by
one with a vendored CoffeeScript **2.0.3** (`Fizzygum/auxiliary files/CoffeeScript/fizzygum-coffeescript-min.js`).
All build/test commands go through the wrapper `/Users/davidedellacasa/code/Fizzygum-all/fg` (ALWAYS by absolute
path; `fg` with no argument prints its live usage). Read the umbrella `CLAUDE.md` and `Fizzygum/CLAUDE.md` first.

### §0.2 The law this arc mechanizes

`Fizzygum/docs/architecture/constructor-and-parameter-conventions.md` (read R1–R3, R7, §3, §4, §5, §7 in full):

- **R3, the hole test:** *if any call site must pass `undefined` to reach a later argument, the parameter list is
  wrong.* A hole proves the skipped parameter is configuration, not identity; the remedy is a trailing
  `opts = {}` (or, for a class exempt under §3, a reorder).
- **R3, the CALLERS TEST** (the doc's own words): *a `undefined` is a hole iff some OTHER call site of the same callee
  OMITS that position's trailing tail.* The readers arc formalized it: an `undefined` at position i reaching a present
  argument at j > i is a hole iff another site of that callee passes fewer than j+1 arguments. Its worked cases:
  `Appearance._paintInLocalScope aContext, clip, undefined, bodyFn` = VALUE (every caller passes all four),
  `_applyTransformSugarNoSettle undefined, s` = VALUE (a symmetric two-slot record),
  `_insertAddersSuchThat scan, insert, undefined, isMember` = HOLE (the other caller stops at arity 3).
- **R3, "once there is a tail, every optional operand is a hole":** the head is what EVERY caller supplies. This is
  the rule that moves the button family's `target`/`action` into opts: `new SimpleButtonWdgt` has callers at arity 0
  and 2.
- **R7:** a base-class signature change ripples through every `super`; convert a family atomically. A **bare**
  `super` forwards the caller's raw `arguments`.
- **§6:** constructor changes are serialization/duplication-SAFE (both instantiate via `Object.create`); only
  explicit `new X` / `super` sites matter — in BOTH repos.

### §0.3 The arcs immediately before this one

- **Constructor-parameter conformance** (`docs/archive/constructor-parameter-conformance-plan.md`, CLOSED):
  `positional-hole` stink 51 → 0 (hard), and created `check-argument-holes.js` as the "honest count", left at a FLOOR
  of 2 because its regex cannot tell a value from a hole.
- **Tests-repo readers** (`docs/archive/tests-repo-readers-plan.md`, CLOSED 2026-11-06): made every tests-repo reader
  read CODE, not prose (`lib/tests-repo-code.js`). Its ruling **D5** carved out this arc: (1) a code-only call
  parser applying the callers test mechanically, (2) the button family's head moved into opts. Its probe:
  `Fizzygum-tests/.scratch/tests-repo-readers/holes-callers-test.js` (uses the OLD regex parser).
- **Every gate bites** (`docs/archive/every-gate-bites-plan.md`, CLOSED 2026-11-07): every gate has a rule
  REGISTRY (`buildSystem/lib/gate-rules.js`) and a standing bite-proof that plants every rule
  (`lib/planted-src.js` `proveGate`, judged by `lib/prove-rules.js`); the build's self-test runner refuses a gate
  with no registry or no proof. Read its §8.2 for the contract.
- **Page-stops-answering watchdog** (2026-11-07, `47f42386` / `a1627d4e8`): the last commits. Nothing here touches it.

### §0.4 Critical reframes — read these before anything else

1. ⭐⭐ **The floor of 2 is a PARSER defect, not a fact about the code.** Both src survivors are VALUES by the
   callers test. A gate that applies the test mechanically has a true floor of ZERO, which is why this arc can
   delete the baseline instead of tightening it.
2. ⭐⭐ **Arity must be the real argument count, or the callers test invents holes.** The regex counts an implicit
   CoffeeScript object `face: x, toolTip: y` as 2+ arguments, so `SimpleRectangularButtonWdgt (opts)` reads arity 2
   and an arity-COMPARING test built on it is wrong in both directions. Only a parser fixes this.
3. ⭐⭐ **Moving to an AST makes strings opaque — and some strings ARE code.** `src/macros/MacroToolkit.coffee` holds
   **15** `Macro.fromString """…"""` heredocs (the standard macro verbs). The regex read them (it reads every
   string); a naive AST reads none of them. The new reader must LIFT known code-strings and parse them, or it sees
   LESS than the parser it replaces. Unit 0 lists every string that holds call-shaped code (U0.5).
4. ⭐⭐ **No build gate parses macro CoffeeScript today.** `Fizzygum-tests/scripts/check-tests-syntax.js` runs
   `node --check` on the JS SHELL of each test file only; the CoffeeScript inside the template literal is first
   parsed at run time. This gate becomes its first static reader, so a source it cannot parse must be an INVALID
   verdict (exit 2, naming the file), never a skipped file.
5. ⭐ **Receiver-blind NAME grouping errs only toward reporting.** The hole condition is existential over the OTHER
   sites of the callee; grouping more sites under one name can only ADD witnesses, so it can turn a value into a
   (false) hole — loud — but never a hole into a value — silent. That is the safe direction; its price is false
   holes, which Unit 0 counts (D2).
6. ⭐ **There is no "§3 dispatcher exemption".** The D5 ledger calls `newParentChoice undefined, menu` "the §3
   dispatcher exemption", but the conventions doc's §3 table (E1–E5) has no such row; dispatch slots are discussed
   in R3 ("A MENU/TRIGGER ADAPTER IS NOT THE VERB"). Mechanically the site is a VALUE: `Widget.newParentChoice`
   is `(ignored, theWidgetToBeAttached)`, its only other caller is `ButtonWdgt`'s dispatcher (not a textual site),
   so no textual caller omits slot 2. The test emulates a dispatch, and the `undefined` stands for the menu item
   that fired. No exemption and no marker are needed; Unit 0 confirms the verdict.
7. ⭐ **`IconButtonWdgt`'s `(@target)` parameter is dead.** It is assigned, then `super @, 'actOnClick', …` makes
   `ButtonWdgt` assign `@target = @` (the button itself). The one caller that passes an argument
   (`new EditIconButtonWdgt @frame` in `FrameBarWdgt`) passes a value nothing reads. The conversion touches this
   super anyway (D6).

---

## §1 The mechanism today (verified 2026-11-07; line numbers drift — grep the quoted name)

### §1.1 The gate

`Fizzygum/buildSystem/check-argument-holes.js` (89 lines):
- reads `census.srcSources(SRC_DIR)` — `Fizzygum/src/**/*.coffee`, comments blanked by `lib/coffee-mask.js`,
  strings KEPT;
- `const BASELINE = 2;` with a header explaining the two survivors are values;
- one rule, `rules.fired('OVER_BASELINE', …)`, registry via `require('./lib/gate-rules').forGate(__filename)`;
- rail `--src=DIR` (via `lib/cli-args` `dirArg`); prints `[argument-holes] OK — N site(s) (baseline 2).`;
- run by `Fizzygum/build_it_please.sh` (grep `check-argument-holes`, ~line 527) under `if ! $noSyntaxCheck`. Its
  comment block says "Scans src/ only (the tests repo's metadata PROSE would false-positive a build)" — stale since
  the readers arc.
- Proof: `buildSystem/check-argument-holes-selftest.js` — `proveGate` with `from: null` (an empty fixture), plants
  BASELINE holes as the control and one more as the planted run; checks `@callee 1, undefined`, `fn.call undefined, 1`,
  a commented call and a multi-line call ending in `undefined` are NOT counted.

### §1.2 The parser it shares

`Fizzygum/buildSystem/census-call-arity.js` (240 lines) — advisory census AND the gate's engine:
- `srcSources(dir)`, `testsRepoSources()` (the latter via `lib/tests-repo-code.js` `testsRepoCode(root)`: harness
  `.coffee`, each macro file's template literals as CoffeeScript, `scripts/**/*.js`; comments cut, strings kept);
- `topLevelArgs`, `callArgText` (paren and paren-less forms, continuation lines), `scanRows` (modes: `new X`,
  `--super=`, `--call=`, tree-wide `sweepAll` — "any identifier followed by an argument list"), `isHole`
  (a bare `undefined` in non-final position; `.call/.apply/.bind` excluded), `dedupeBySite`, `collectHoles`.
- Consumers: the gate; the gate's self-test (indirectly); `fg critique` step 7 (umbrella-local `fg`, grep
  `census: argument holes`); `docs/architecture/lint-and-static-checks.md` §3 / §3c.

### §1.3 What it misreads (each seen in today's 40-row list)

| # | misread | live example |
|---|---|---|
| a | a non-call or an assignment read as the call; callee misattributed | `btn = new SimpleButtonWdgt …` → callee `btn`; `[entry, undefined, undefined]` (an array literal in `menu-click-sweep-headless.js`) → callee `entry`; JS `new SimpleButtonWdgt(undefined, …)` → callee `undefined` (`pin-sweep-headless.js`) |
| b | an implicit object's keys counted as separate arguments | `SimpleRectangularButtonWdgt`'s `super opts.target, opts.action, opts` sites; any `f a, face: x, toolTip: y` |
| c | string contents read as code | `@say "use undefined, then 1"` would count (BACKLOG, every-gate-bites §8.3 "File") |
| d | all-trailing `undefined`s counted though nothing present follows | `setValue(77, undefined, undefined)` ×5 in `serialization-roundtrip-headless.js` |
| e | foreign APIs judged | `JSON.stringify(x, undefined, 4)` (`Automator.coffee`, `aim-census.js`) |
| f | a paren-less NESTED implicit call's arguments counted at the outer level | `@assertValuesEqual "…", undefined, sales.dockSideAt new Point sales.center().x, stripTop + 10` reads arity 4; CoffeeScript passes 3 |

### §1.4 Today's hole list: `node buildSystem/census-call-arity.js --holes` → 40 sites (run from `Fizzygum/`)

| sites | callee / shape | where | verdict a correct reader should give |
|---|---|---|---|
| 1 | `_paintInLocalScope aContext, clip, undefined, bodyFn` | `src/Appearance.coffee` | VALUE (doc's worked case) |
| 1 | `_applyTransformSugarNoSettle undefined, s` | `src/basic-widgets/Widget.coffee` | VALUE (doc's worked case) |
| 18 | `@assertValuesEqual "…", undefined, x` | 11 macro files | VALUE if every site passes 3 (expected = `undefined`) — Unit 0 |
| 2 | `processKeyDown('9', undefined, false, false, false, false)` | `scripts/serialization-roundtrip-headless.js` | VALUE if every site passes 6 — Unit 0 (defined by `CaretWdgt`, `SimpleSpreadsheetWdgt`, `VideoPlayerWdgt`) |
| 2 | `JSON.stringify(x, undefined, n)` | `Automator.coffee`, `aim-census.js` | foreign (D3) |
| 1 | `visit(targetText, undefined, 0)` | `scripts/aim-census.js` | a FILE-LOCAL function: judge against that file's own sites — Unit 0 |
| 1 | `[entry, undefined, undefined]` | `scripts/menu-click-sweep-headless.js` | not a call (misread a) |
| 1 | `menu.addMenuItem('Plant no target', undefined, 'biteProofNoop')` | `scripts/menu-click-sweep-selftest-headless.js` | a deliberate PLANT of a target-less row; VALUE unless some `addMenuItem` caller passes fewer than 3 — Unit 0; the sanction-marker case if misjudged (D4) |
| 5 | `setValue(n, undefined, undefined)` | `scripts/serialization-roundtrip-headless.js` | trailing-only (D3); note `SliderWdgt.setValue` is `(newvalue)` — the two are dead arguments |
| 7 | the button family: `new SimpleButtonWdgt undefined, undefined, face: …` ×2 macros + 2 JS sites (`pin-sweep-headless.js`), `new ButtonWdgt world, undefined, face: …` ×2, `new LabelButtonWdgt undefined, undefined, labelString: …` ×1 | macros + scripts | HOLES — removed by the conversion (Unit A) |
| 1 | `artStandingForTheMenu.newParentChoice undefined, nestedMenu` | `SystemTest_macroDeletingMenuNestedInShortcutIconTerminates` | VALUE (§0.4 reframe 6) |

### §1.5 Parsers available (measured 2026-11-07)

- **CoffeeScript 2.0.3, the browser's own** (`Fizzygum/auxiliary files/CoffeeScript/fizzygum-coffeescript-min.js`,
  a compile-only fork; `README.md` beside it): `CoffeeScript.nodes(src)` EXISTS and returns the AST. ⚠ The bundle
  is MINIFIED, so node constructor names are mangled (`constructor.name === 'e'`); node kinds must be told
  STRUCTURALLY. Measured: a call node has `children` = `["variable","args"]`, an `isNew` flag, `args` (an implicit
  object is ONE argument: `new Foo a, face: 1, tip: 2` → 2 args), and `locationData.first_line` (0-based).
  ⚠ A **bare `super`** is a PARSE error in 2.0.3 (`unexpected indentation`), both in a fragment and in a whole
  class file; `super a, b` with arguments parses even outside a class.
- **`src/meta/Class.coffee` `_equivalentforSuper`** rewrites every `super` form BEFORE a member is compiled, in this
  order: `super()` → `<Cls>.__super__.<member>.call(this)`; a bare `super` ending a line →
  `<Cls>.__super__.<member>.apply(this, arguments)`; `super(` → `….call(this, `; `super ` → `….call this, `
  (`<member>` is `constructor` for a constructor). So a member fragment as the compiler sees it parses, and a super
  call is recoverable as: callee = `<Cls>`'s superclass's `<member>`, arguments = the `.call` arguments minus `this`;
  a `.apply(this, arguments)` is a FORWARDING site (arity = its own callers').
- **The fragmenting shim already exists:** `buildSystem/check-coffee-syntax.js` loads the real `Class.coffee` /
  `Mixin.coffee` into Node with a `window` Proxy and a `compileFGCode` stand-in, and drives each source through
  `new Class(src, true, false)` / `new Mixin(src, true, false)`; it taps `_equivalentforSuper` (to know the member)
  and `_removeHelperFunctions`. A `compileFGCode` tap therefore sees every fragment exactly as the browser compiles it.
- **Macros:** `Macro.fromString` (`src/macros/Macro.coffee`) rewrites `fooMacro args` →
  `yield from fooMacro.call this, args` before compiling (`_replaceMacroInvocationWithYieldingInvocations`); `linkTo`
  concatenates subroutines and prepends a pump header. Measured: a macro-shaped source (`x_Macro = -> … yield …
  fooMacro btn, 2`) parses with 2.0.3 `nodes()` BEFORE the rewrite. No macro file holds a JS `${` substitution (0 of 373).
- **acorn 7.4.1** is in `Fizzygum/node_modules` only as a TRANSITIVE dependency (jscpd → pug → is-expression). Trial:
  it parses **122 / 122** `Fizzygum-tests/scripts/**/*.js` at `ecmaVersion: 2021`. `@babel/parser` is transitive
  there too; `esprima` 4.0.1 and `js-tokens` are transitive in `Fizzygum-tests/node_modules` (via puppeteer).
- **CoffeeScript 2.7.0** (`Fizzygum/node_modules/coffeescript`, a DECLARED devDependency) supports
  `compile(src, {ast: true})` → an ESTree/Babel-shaped AST (`CallExpression`, `NewExpression`, `ObjectExpression`,
  `loc.start.line`). It refuses `super` outside an instance method, so it too needs the rewritten fragments.
- ⚠ **The build has ZERO npm dependencies today:** no gate under `buildSystem/` `require`s a module from
  `node_modules` (only the non-gate tool `coffee-to-js-mirror.js` uses `coffeescript-v1`). A fresh checkout builds
  without `npm i` in `Fizzygum/`. D1 decides whether this arc keeps that property.

### §1.6 The proof machinery

- `lib/gate-rules.js`: `rules.fired('<ID>', text)` records a rule (ids read from the gate's own literal `.fired(`
  first arguments); `rules.declare([...])` for table ids; a `// bite-unplantable: <ID> — <reason>` header line for a
  rule no plant can reach; on exit 1 it prints `[<gate>] RULES fired: … · of: …`. Exit 1 with no rule fired =
  `RULELESS_FAILURE` (exit 2).
- `lib/planted-src.js` `proveGate(spec)`: copies a tree (`from`, default `src/`; `from: null` = empty fixture),
  applies each run's `plants`/`unplant`/`edits`, runs the REAL gate with `rail + treeDir` plus the run's `args`,
  resets. ONE tree per proof; a second tree rides a run's `args` (precedent: `check-layering-selftest.js` builds a
  `mkdtemp` tests dir and passes `--tests-dir=` in one run's `args`).
- `lib/prove-rules.js` holds: the control exits 0 with its pass line and fires no rule; each planted run exits 1
  naming exactly the rules it planted, each by its own violation line; a run with `exit: 2` must exit 2 firing no
  rule (an INVALID is never a rule); the union of fired rules = the gate's `of`.
- `buildSystem/run-selftests.js` (build step #1) runs every `*-selftest.js` found by NAME (incl. `lib/`), and
  refuses a launched gate with no registry or no proof that launches it by `path.join(__dirname, '<gate>.js')`.
- Rule-id naming precedent for sanctions: `check-hand-lists.js` declares `SANCTION_EMPTY` and `SANCTION_STALE`.

### §1.7 The button family (18 classes; derived by walking `extends` over `src/` + the harness)

| class | head today | its `super` today |
|---|---|---|
| `ButtonWdgt` (`src/ButtonWdgt.coffee`) | `(@target, @action, opts = {})` | `super()` |
| `LabelButtonWdgt` | `(target, action, opts = {})` | `super target, action, opts` |
| `SimpleButtonWdgt` | `(target, action, opts = {})` | `super target, action, opts` |
| `ChipWdgt`, `LabelledToggleWdgt` (extend `SimpleButtonWdgt`) | `(target, action, opts = {})` | `super target, action, opts` |
| `SimpleRectangularButtonWdgt` (`src/authoring/`) | `(opts = {})` — the model | `super opts.target, opts.action, opts` |
| `CodeInjectingSimpleRectangularButtonWdgt` | `(palette, face, @drawingToolKey)` | `super target: palette, action: "selectTool", face: face` |
| `MenuItemWdgt` (`src/basic-widgets/menu-system/`), `MemberRowWdgt` | `(commandSpec, opts = {})` | `super commandSpec.target, commandSpec.action,` + an implicit object |
| `IconButtonWdgt` (`src/buttons/`) | `(@target)` — DEAD (§0.4 reframe 7) | `super @, 'actOnClick', face: new Widget` |
| `CloseIconButtonWdgt`, `CollapseIconButtonWdgt`, `UncollapseIconButtonWdgt`, `EditIconButtonWdgt`, `OverflowChevronButtonWdgt` | none (inherit `IconButtonWdgt`'s) | — |
| `MagnetWdgt` (`src/fizzytiles/`) | `(target)` | `super target, undefined` |
| `SimpleRasterImageButtonWdgt` (`src/video-player/`) | `(@imagePath, target, action, argumentToAction1)` (multi-line) | `super target, action,` + implicit object |
| `VideoThumbnailWdgt` (`src/video-player/`) | `(imagePath, @videoPath, target, action)` (multi-line) | (Unit 0) |

Facts that shape the conversion:
- Rough `new` counts (a regex, so a FLOOR; Unit 0 recounts by parser): `new SimpleButtonWdgt` src 31 / macros 5 /
  scripts 7; `new ButtonWdgt` macros 2 / scripts 1; `new LabelButtonWdgt` macros 1; `new LabelledToggleWdgt` src 5;
  `new ChipWdgt` src 1; `new MenuItemWdgt` src 3 / macros 3; `new MagnetWdgt` src 4.
- `ButtonWdgt`'s header comment ("target and action are the identity … the only two a typical caller passes") and
  `SimpleRectangularButtonWdgt`'s ("ButtonWdgt's head is `(target, action, opts)` and that is right for buttons at
  large") become FALSE and must be rewritten; `SimpleButtonWdgt`/`LabelButtonWdgt`/`ChipWdgt`/`LabelledToggleWdgt`
  each say "ButtonWdgt's head (target, action) and its opts".
- `ButtonWdgt`'s `(@target, @action, …)` are `@param`s: they assign UNCONDITIONALLY (R5), at the top of the
  constructor, before `super()`. A pixel-neutral conversion assigns `@target = opts.target` and
  `@action = opts.action` unconditionally, in the same place. (Whether any family member declares a prototype
  `target:`/`action:` that the `@param` has always clobbered is a Unit 0 question; changing that is NOT pixel-neutral
  and is out of scope — record it.)
- The `video-player` part is flag-gated (`--includeVideoPlayer`), so a default build's syntax gate does NOT list its
  files; check them with `node ./buildSystem/check-coffee-syntax.js --files src/video-player/<file>.coffee`.
- Dynamic constructions exist (`new (classNamed name)`, `new window[appClassName]`, `new (window["InspectorWdgt"])`,
  a rig's `REPRESENTATIVES` table with `makeArgs`, `staleness-census.js`'s `new K()`): a family member built that way
  with POSITIONAL arguments would silently mis-bind after the conversion. Unit 0 enumerates them (U0.6).

### §1.8 The `positional-hole` stink

`buildSystem/check-stinks.js` (grep `id: 'positional-hole'`), baseline 0 HARD, src only: ≥2 consecutive bare
`undefined` arguments on one line. Its own entry says to keep it as "the instant alarm for the worst shape". Its
self-test plant: `check-stinks-selftest.js` (`'positional-hole': '@bpHole undefined, undefined, 1'`). Once the gate is
an exact zero over both repos, the stink is a second, DISAGREEING definition of a hole (it fires on a trailing
`undefined, undefined` pair and on an array literal, which the callers test does not call holes). D5.

### §1.9 Prose that states the current shape (all must be true at the end)

`docs/architecture/constructor-and-parameter-conventions.md` §5 (says "ratcheted at **2**") and §7 (says "floor of
**3**" — already inconsistent with §5), R7's family list, R1's "an established convention like `target, action`";
`docs/architecture/lint-and-static-checks.md` §3 (the `argument-holes` row, ~line 155, cites "~:486" for the build
line, now ~527; the `positional-hole` stink row, ~line 294), §3c (the census), §5's marker table (its intro says
"All fifteen" over 17 rows), §7 boundaries, the appendix anchors; `Fizzygum/CLAUDE.md`'s constructor-convention
bullet ("the honest counter `check-argument-holes.js` at its floor"); `build_it_please.sh`'s gate comment;
`check-argument-holes.js` / `census-call-arity.js` headers; `docs/BACKLOG.md` (two items: the D5 entry under
"`archive/tests-repo-readers-plan.md`", and "`check-argument-holes` reads string contents as code" under the
every-gate-bites masks); `src/macros/MACRO-PATTERNS.md` and `src/macros/CLAUDE.md` (button fixture spellings); the
umbrella-local `fg` critique step 7. Unit 0 (U0.6) greps the complete list of old-spelling mentions.

---

## §2 Why it is shaped this way

- The regex parser was written in the conformance arc as a WORK-LIST tool ("ask this scanner whether a family is
  done"), where over-matching was harmless: a human read every row. Making it a gate exposed its misreads, which
  is why the gate was given a non-zero floor and kept to `src/`, where the misreads happen not to fire.
- The tests repo was excluded twice over: first because the reader then read test METADATA prose (fixed by the
  readers arc), then because most of its `undefined`s are values the regex cannot tell from holes.
- The button head `(target, action, opts)` was R1-correct when written ("the established pair"); the readers arc
  measured callers of `new SimpleButtonWdgt` at arity 0 and 2 and of `new ButtonWdgt` at arity 2, which by R3's
  "every optional operand is a hole" rule moves both operands into opts. `SimpleRectangularButtonWdgt` reached
  `(opts = {})` by the same reasoning earlier, alone.

## §3 The argument (distilled)

The hole test is only as good as two numbers per call site: WHICH callee it calls and HOW MANY arguments it
really passes. The regex gets both wrong in ways that are not patchable on a line (an implicit object, a nested
paren-less call and a string's contents need a grammar, not a better regex), so the old answer was a floor. A real
parser gets both right; the callers test is then a few lines over a table of call sites; and the one family whose
holes are real gets the conversion R3 already prescribes. With the residue judged, the gate can state "zero" and
mean it, and the census can share the same table so the two can never disagree. What is different from the
conformance arc's attempt: that arc had no grammar-level reader and no callers test; the tests repo's readers now
read code; and the meta-compiler shim that makes fragment-faithful parsing possible already exists in
`check-coffee-syntax.js`.

---

## §4 The owner decisions — ONE round, presented AFTER Unit 0, recommendation first

Nothing is edited before this round is answered. Unit 0 runs first because every decision below has a measured
number that confirms or overturns its recommendation. Present all six together, each with its Unit 0 numbers, in
one message; record the answers in §9.

**D1 — The parser.**
- **(a) RECOMMENDED: the browser's own CoffeeScript 2.0.3 `nodes()` for every CoffeeScript source, + acorn VENDORED
  for JS.** CoffeeScript through the fragmenting shim (§1.5) factored out of `check-coffee-syntax.js` into one shared
  `lib/` module both use; macro sources parsed whole (pre-rewrite, as authored); the 15 heredocs lifted. Node kinds
  read structurally (the bundle is minified), proven by the lib's own self-test and cross-checked once, in Unit 0,
  against CoffeeScript 2.7's `ast: true` as an oracle. acorn vendored as one pinned file (version and tarball hash in
  a README beside it) in a place no gate walks and the build never copies (U0.7 finds it). Why: what is judged is
  what the browser parses (the reason `check-coffee-syntax` drives the real compiler), and the build keeps ZERO npm
  dependencies. Overturned if: U0.1's structural shim disagrees with the oracle anywhere it cannot be fixed, or
  2.0.3 fails to parse a source that runs.
- (b) CoffeeScript 2.7 `compile(…, {ast: true})` + acorn as devDependencies: ONE ESTree walker for both languages.
  Costs: the build's first `node_modules` requirement (`npm i` in `Fizzygum/`), and a grammar one version family
  ahead of the browser's.
- (c) (a) for CoffeeScript, and a paren reader over `lib/js-mask.js` tokens instead of acorn (no vendored parser;
  JS has no paren-less calls and no implicit objects, so a correct lexer goes far). Costs: a hand-written reader
  where a real parser is available.
- Sub-question, same decision: which acorn (7.4.1 already on disk — parses 122/122 — or the newest 8.x, which needs
  `npm pack acorn@8` over the network at execution).
- Sub-question, same decision: `buildSystem/compile-fragment.js` (a tool, not a gate) TRANSCRIBES Class.coffee's super
  rewrite, as its header admits. With the shim factored into `lib/meta-compiler.js` (Unit B.1) it could drive the real
  one — a second copy deleted. RECOMMENDED: do it in Unit B if it is a few lines; otherwise a BACKLOG line.

**D2 — Callee identity for a receiver send `x.m args` / `@m` / `this.m(…)`.**
`new X` → the nearest class up `X`'s `extends` chain defining `constructor` (exact); a rewritten super (§1.5) →
the superclass's member (exact); a bare `f …` → the nearest lexical definition (the same macro source, the same JS
file), else the global name. For RECEIVER sends:
- **(a) RECOMMENDED: by NAME.** Every send of `m`, whatever its receiver, is one callee, provided some code in either
  repo defines `m` (else D3's foreign rule). Errs only toward reporting (§0.4 reframe 5). Confirmed if U0.4 finds no
  false hole, or only a handful the owner prefers to sanction.
- (b) by name, refined by FAMILY: split a name's sites by the definers' class hierarchy wherever the receiver's class
  is statically known (`@m` inside class C → C's chain; a local bound by `new X` then `.m`); an unknown receiver joins
  every group. Adopt only if (a) misjudges values that a sanction should not have to carry.
- (c) exact-only (judge only resolvable receivers). NOT recommended: blind to `holder.add w, undefined, spec`, the
  doc's own prime example of a hole.

**D3 — What the gate does not judge, and what "absent" is.**
- (a) **Foreign callees — RECOMMENDED: not judged.** A callee no code in either repo defines (`JSON.stringify`,
  `Math.max`, DOM/Node/Puppeteer/Playwright methods) is not ours; a hole there is not our parameter list. Plus the
  existing `.call`/`.apply`/`.bind` this-arg exclusion. (`fn.call undefined, a, undefined, b` forwards into `fn`,
  which the gate cannot resolve — a stated limit.)
- (b) **Trailing-only absences — RECOMMENDED: not holes, by definition** (they reach nothing). They still count as
  OMISSION witnesses at their effective arity (`super target, undefined` witnesses that `action` is optional). Unit 0
  lists them; optionally (owner) the arc deletes those that are dead arguments (the five `setValue(n, undefined,
  undefined)` pass three arguments to a one-parameter method).
- (c) **Absence spellings — RECOMMENDED: `undefined`, `null` and `void 0` alike** (a hole spelled `null` is the same
  defect; R2 reads opts with `?`, which treats both as absence), provided U0.3 shows the added candidates are judged
  correctly; else `undefined` only.
- (d) **Unknown-arity sites** (a splat `f args...`, a forwarding `.apply(this, arguments)`, a bare `super`) —
  RECOMMENDED: never a witness, counted and printed by the gate; a forwarding super's arity is PROPAGATED from its
  own constructor's callers only if U0.8 shows a verdict that depends on it.
- (e) §3-exempt classes (`Point`, `Rectangle`, `Color`, input events, published spellings) are **judged like any
  other** — §3 changes the remedy (reorder), not the verdict.

**D4 — A sanction marker for a value the test misjudges.**
- **(a) RECOMMENDED:** `# argument-hole-sanctioned: <why this absence is the value>` in CoffeeScript (incl. macro
  sources) and `// argument-hole-sanctioned: <why>` in JS, on the line the call STARTS on or the comment line(s)
  directly above it — the per-line placement `# macro-private-call-sanctioned` uses. Rules: `SANCTION_EMPTY` (no
  reason) and `SANCTION_STALE` (the call it reaches is not judged a hole — a value, no absence before a present
  argument, or no call starting there), the `check-hand-lists` ids. Used only where Unit 0 shows a real value
  judged a hole; each one listed in §9 and printed by the gate's pass line.
- (b) no marker: every misjudged value is reshaped instead (an adapter, a reorder). Purest, if U0.3 finds none.
- (c) a central allowlist in the gate. NOT recommended: the house rule is "the justification lives AT the site, no
  central allowlist" (`lint-and-static-checks.md` §5).

**D5 — The `positional-hole` stink.**
- **(a) RECOMMENDED: retire it** in the gate's commit — its id leaves `STINKS`, its self-test plant goes, its doc rows
  go. With the gate exact over both repos it is a second definition of a hole that disagrees with the first (it fires
  on a trailing pair and on an array literal) — "one of each thing".
- (b) keep it as a free instant alarm.

**D6 — The conversion's edges.**
- (a) **RECOMMENDED: `IconButtonWdgt`'s dead `(@target)` goes** (head `->`, `super target: @, action: 'actOnClick',
  face: new Widget`; `new EditIconButtonWdgt @frame` drops its dead argument) — if, and only if, U0.6 confirms no
  reader of an icon button's `target` expects the passed value (if one does, STOP: that is a live bug, not a cleanup).
- (b) **RECOMMENDED: the two `video-player` heads stay positional** (only their `super` lines change, per R7) unless
  U0.6 finds a hole among their callers.
- (c) the button head itself is NOT a decision — ruling D5 made it; the conversion follows R4/R6 (keys `target:` and
  `action:`, read where the `@param`s were assigned).

---

## §5 Units (each gated before the next; the protocol is §6)

⚠ **The owner round is ANSWERED — read §9's "OWNER ROUND ANSWERED" entry first: it amends the units below
(no sanction marker, effective-arity witnesses, the video-player heads converted, js-mask removed for acorn, one
verdict printer).**

Probe/scratch directory for the whole arc: `/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/argument-holes/`
(gitignored; Node resolves `require()` from the SCRIPT's directory, so probes must live there, not in a session
scratchpad). Outputs under its `out/`. Keep a running ledger in §9 of THIS file (docs and memory are safe to edit while
a long op runs; src/tests/fg are not).

### Unit 0 — the survey (READ-ONLY; nothing in either repo changes)

Write ONE probe, `.scratch/argument-holes/survey.js`, that builds the CALL TABLE the gate will need and reports every
measurement below. It is the prototype of Unit B's parser lib; write it so that Unit B can lift its code.

- **U0.1 Parse coverage.**
  - src: classify each `src/**/*.coffee` as class (`/^class +\w+/m`) / mixin (`/^(\w+Mixin)\s*=/m`) / other (boot
    etc.) — the same tests `check-coffee-syntax.js` uses. Drive classes and mixins through the real meta-compiler
    (copy its shim; tap `compileFGCode`) and run 2.0.3 `nodes()` on each fragment; run `nodes()` whole-file on the
    others. Report: files, fragments, parse failures (must be 0 for D1(a)), and the time taken.
  - Fragment → file LINE mapping: for every fragment, establish the file line of each fragment line (Class.coffee
    may dedent; the super rewrite is same-line). Report any fragment that cannot be mapped exactly; the fallback is
    `check-coffee-syntax.js`'s `fileLocation` (match the line's text).
  - harness (`Fizzygum-tests/Automator-and-test-harness-src/**/*.coffee`): same as src.
  - macro sources: every top-level template literal of every `tests/*/*_automationCommands.js` (reuse
    `lib/tests-repo-code.js` `macroSources`), `nodes()` pre-rewrite; for any failure, retry post-rewrite through the
    real `Macro` rewrite and report which form parses.
  - the 15 `Macro.fromString """…"""` heredocs in `src/macros/MacroToolkit.coffee`, and any other `Macro.fromString`
    with a literal argument: `nodes()` on the heredoc's content; map its lines back to the file.
  - JS: acorn 7.4.1 (`require` it by absolute path from `Fizzygum/node_modules/acorn`) over `scripts/**/*.js`
    (excluding dot-directories and `node_modules`, as `tests-repo-code.js` does) and over each macro file's JS shell.
  - The STRUCTURAL-KIND oracle: for every CoffeeScript fragment/source, compare the call records from 2.0.3 `nodes()`
    (structural) with CoffeeScript 2.7 `compile(src, {ast: true})` (`require` it by absolute path from
    `Fizzygum/node_modules/coffeescript`) — count, line, `isNew`, argument count, and which arguments are bare
    `undefined`/`null`/`void 0`. List every disagreement.
- **U0.2 The call table.** One row per call: file, line, kind (`new` / super / bare / receiver / `@` / JS
  `this.`), callee identity under D2 (a), (b) and (c), argument count, effective arity (1 + the index of the last
  argument that is not an absence; 0 if none), the positions of absences, splat/forwarding flag, string-lifted flag.
- **U0.3 The real hole list after the callers test**, under each D2 option × each D3(c) absence spelling. For every
  HOLE print its WITNESS (the other site whose effective arity is below this site's, with its file:line). For every
  VALUE candidate print the arity histogram of its callee's sites. Expected (verify, do not assume): the two src
  values, the 18 `assertValuesEqual`, the 2 `processKeyDown`, `newParentChoice` and `visit` are VALUES; the 7
  family sites are HOLES; `addMenuItem` depends on whether any `addMenuItem` caller passes fewer than 3.
- **U0.4 Name collisions.** For every callee NAME carrying a candidate (an absence before a present argument):
  its definers (class.member in src/harness, MacroToolkit verbs, macro-local defs, JS file-local functions, boot
  globals — reuse `lib/name-definitions.js` `harvestDefs` for the CoffeeScript half, so "is this name ours?" has ONE
  answer across gates), how many unrelated hierarchy roots they span, foreign-receiver sites (`JSON.`, `Math.`,
  `Object.`, `page.`, `browser.`, …) sharing the name, and whether the verdict differs between D2 (a), (b), (c).
- **U0.5 Old-vs-new delta (no silent coverage loss).** Classify EVERY row of today's
  `node buildSystem/census-call-arity.js --holes` (40): found by the new table / a misread (§1.3 a–f, say which) /
  foreign / trailing-only / a COVERAGE LOSS. Then list every string literal (in every parsed source) whose content
  holds call-shaped code with an absence (`/\b(undefined|null|void 0)\s*,/`), classified: a lifted heredoc / a
  spreadsheet formula / an `evaluateString` / a `page.evaluate` string / prose. A coverage loss is fixed in Unit B
  (lift that string kind) or stated as a limit — the owner sees the list in the round.
- **U0.6 The conversion's work list.** For the 18 classes of §1.7: every `new` site (by parser), every `super` site in
  a family constructor (and confirm none is a bare `super`), every DYNAMIC construction that could build a family
  member (`new (classNamed …)`, `new window[…]`, `new (window["…"])`, `new cls(…)`, `Reflect.construct`, a rig's
  `makeArgs`/representatives table, `page.evaluate` strings), every code-STRING construction (formula strings,
  evaluateString), every prototype `target:`/`action:` declaration in the family, every reader of an icon button's
  `target` (D6a), the callers of the two `video-player` heads (D6b), and every DOC/comment/skill mention of the old
  spelling (`docs/`, every `CLAUDE.md`, `src/macros/MACRO-PATTERNS.md`, family class comments, the umbrella
  `.claude/skills/` and `Fizzygum-tests/.claude/` if present). Cross-check the `new`-site list against today's regex
  census (`node buildSystem/census-call-arity.js SimpleButtonWdgt ButtonWdgt LabelButtonWdgt LabelledToggleWdgt
  ChipWdgt MenuItemWdgt MagnetWdgt` and `--super=…`): every regex row must be in the parser's list.
- **U0.7 Where acorn may live.** List the directories every buildSystem gate walks (at least `check-hand-lists.js`
  reads `buildSystem/`; `what-runs.js`, `check-trailing-whitespace.js`, `check-dead-methods.js` — read each) and what
  `build.py` copies; propose a vendor path outside all of them.
- **U0.8 Unknown-arity sites** (splat, `.apply(this, arguments)`, bare super) of every callee with a candidate, and
  whether treating them as witnesses would flip any verdict.
- **U0.9 Budget.** Wall time of the whole table (target: under ~3 s on an idle machine — `check-coffee-syntax`, which
  COMPILES all of src, takes ~1.4 s). Report it; do not optimize unless it is far over.

Unit 0's exit: §9 holds the numbers, U0.5 explains all 40 old rows, and the six decisions can be presented with
their evidence. **Present the round (§4) and STOP until it is answered.**

### Unit A — the button family conversion (both repos; ONE commit per repo; pixel-neutral)

Work list = U0.6. Edit every `.coffee` with the Edit tool (never `perl -pi` / `sed -i` on CoffeeScript — it
de-indents). Before converting, check each NEW spelling shape once with `buildSystem/compile-fragment.js` (its
header: "check a call/`super` spelling BEFORE converting a family — in particular that a trailing `key: value` lands
as a SEPARATE final argument rather than folding into the positionals"), e.g. from `Fizzygum/`:
`printf 'constructor: (commandSpec, opts = {}) ->\n  super\n    target: commandSpec.target\n    action: commandSpec.action\n    fill: 1\n' | node buildSystem/compile-fragment.js --stdin MenuItemWdgt`
must show ONE object argument.

⚠⚠ **Two spelling traps — measured 2026-11-07, both compile WITHOUT error and mis-bind:**
- **`super` alone on a line, keys indented below it** → `_equivalentforSuper`'s rule 2 sees a bare `super` ending the
  line and emits `X.__super__.constructor.apply(this, arguments)({target: …})`: it FORWARDS the raw arguments and
  then calls the result with the object. Write `super(` … `)` with the keys indented between the parens, or put the
  whole object on the `super` line.
- **Keys on the head line, a trailing comma, more keys indented** (`new X target: t, action: a,` / `  face: f`, the
  shape every positional site has today once `t, a` become keys) → TWO object arguments, `{target, action}` and
  `{face, …}`; the second is silently dropped by an `(opts)` head. For `new X` write `new X` with ALL keys in one
  indented block below it, or `new X(` … `)`; for `super`, the paren form.
Both are caught statically after the conversion: by the parser, every `new`/`super` site of a family class has
argument count ≤ 1, and no family constructor contains a forwarding (`.apply(this, arguments)`) super (Unit A.10,
Unit B.4). Rules:
1. `ButtonWdgt`: `constructor: (opts = {}) ->`, first two lines `@target = opts.target` and `@action = opts.action`
   (unconditional, where the `@param`s were — R6, pixel-neutral), rest unchanged. Rewrite its header comment to the
   new reason (R3's "once there is a tail, every optional operand is a hole": `new SimpleButtonWdgt` has callers that
   supply neither, so neither is identity), keeping the comment's other paragraphs.
2. `LabelButtonWdgt`, `SimpleButtonWdgt`, `ChipWdgt`, `LabelledToggleWdgt`: `(opts = {})`, `super opts`; keep each
   class's own pre-`super` option reads where they are. Fix each "ButtonWdgt's head (target, action)" comment.
3. `SimpleRectangularButtonWdgt`: `super opts`; rewrite its header (it is no longer the exception — it is the family's
   shape). `CodeInjectingSimpleRectangularButtonWdgt`: unchanged (already `target:`/`action:` keys) — confirm.
4. `MenuItemWdgt`: `super` with `target: commandSpec.target` and `action: commandSpec.action` as the first two keys
   of the existing implicit object (check `MemberRowWdgt` forwards correctly).
5. `MagnetWdgt`: `super target: target` (update its comment about the explicit call).
6. `IconButtonWdgt`: per D6(a). `SimpleRasterImageButtonWdgt` / `VideoThumbnailWdgt`: per D6(b) — their `super` lines
   to keys; verify with `node ./buildSystem/check-coffee-syntax.js --files src/video-player/SimpleRasterImageButtonWdgt.coffee src/video-player/VideoThumbnailWdgt.coffee`
   (run from `Fizzygum/`).
7. Every `new` site: positional `t, a, k: v …` → `target: t, action: a, k: v …` (drop `target:`/`action:` when the
   value was `undefined`); a site passing an opts VARIABLE `new X t, a, o` → `new X Object.assign({}, o, target: t,
   action: a)` (check precedence: an `o` that itself carries `target` is a finding); JS sites
   `new SimpleButtonWdgt(undefined, undefined, { face: 'a' })` → `new SimpleButtonWdgt({ face: 'a' })`. Every
   dynamic and code-string site U0.6 found.
8. Docs that SHOW the spelling (U0.6's list) are updated in this unit EXCEPT
   `constructor-and-parameter-conventions.md` and `lint-and-static-checks.md`, which are Unit E's (so commit 1 and
   commit 2 touch disjoint files).
9. **Temporary arity TRIPWIRE (not committed):** in each converted `(opts = {})` head add
   `throw new Error "BUTTON_HEAD_TRIPWIRE #{@constructor.name}: (opts) takes one object" if arguments.length > 1 or (opts instanceof Widget)`
   (and, if D6(a) leaves `IconButtonWdgt` with no parameter, `… if arguments.length > 0` there).
   Prove it bites first: plant one old-shape call in a scratch macro run (`fg test` on a test whose macro you
   temporarily edit, then restore with `git -C … checkout -- <file>`) and see the throw. Run the verification below
   WITH the tripwire, then remove every tripwire line and `fg build` again.
10. Verify (§6.2). Re-run U0.6's family census: zero old-shape sites in either repo, EVERY family `new`/`super` site
    at argument count ≤ 1 (the two-object trap), and no forwarding super in any family constructor (the bare-super
    trap).
11. **Write the commit-1 manifest:** `git -C /Users/davidedellacasa/code/Fizzygum-all/Fizzygum status --porcelain` and
    the same for `Fizzygum-tests`, saved to `.scratch/argument-holes/commit-1-manifest.txt` — MINUS this plan file
    (`docs/plans/argument-holes-both-repos-plan.md`, edited throughout for the ledger; it belongs to commit 2). From here on NO later
    unit may edit a file on that manifest; a needed edit there is a STOP (it means the conversion was incomplete —
    report it and ask).

### Unit B — one parser: the shared call-site lib, and the census re-engined

1. Factor the meta-compiler shim out of `check-coffee-syntax.js` into `buildSystem/lib/meta-compiler.js` (loads the
   bundled compiler + the real `Class`/`Mixin` from a given src dir, with the `window` Proxy and `compileFGCode`
   stand-in, and lets a caller tap fragments). `check-coffee-syntax.js` uses it; its PASS output must be
   byte-identical before/after (capture `node ./buildSystem/check-coffee-syntax.js > before.txt` first; diff), and
   its self-test must stay green.
2. Vendor acorn per D1 (one file + a README stating version, source tarball, sha, and "do not hand-edit").
3. Write `buildSystem/lib/call-sites.js`: from Unit 0's probe, the ONE reader of call sites in both repos —
   `callSites({ srcDir, testsRepoDir })` → `{ sites: [...], unreadable: [...], counts }`, each site as in U0.2. It
   implements the kinds, the super de-sugar, the lifted strings (per U0.5 and the round), D2 identity, D3 absences.
   Its self-test `buildSystem/lib/call-sites-selftest.js` (found by name by `run-selftests.js`; end with the shared
   verdict line from `lib/selftest-verdict.js`) holds a case per reading: implicit object = 1 argument; nested
   paren-less call (misread f); `super a, b` / `super()` / bare `super` after the rewrite; a string holding
   `"x, undefined, 1"` is not a call; a lifted heredoc's call IS a call, on the right file line; trailing-only
   effective arity; `.call undefined` this-arg; JS `new X(...)`, optional call, spread; a JS file-local function's
   identity; a macro-local helper's identity; each structural node kind.
4. Re-engine `census-call-arity.js` on `lib/call-sites.js`: keep its CLI modes (`<Class…>` = `new` sites,
   `--super=`, `--call=`, `--holes`, `--min=`) and its output shape; DELETE `topLevelArgs`, `callArgText`, `scanRows`'
   regex sweep, `dedupeBySite`. `--holes` now prints the callers test's verdicts (holes with witnesses; with
   `--values`, the value sites too). Record in §9 the census output before/after and explain every row that moved
   (U0.5 is the expected answer). Then re-run the family census on the NEW engine
   (`node buildSystem/census-call-arity.js ButtonWdgt SimpleButtonWdgt LabelButtonWdgt LabelledToggleWdgt ChipWdgt`
   and `--super=` over the 18 classes): every site is the `(opts)` shape at argument count ≤ 1 — the conversion is
   re-proved by the parser that will gate it.
5. `fg build` green (it runs every self-test).

### Unit C — the gate over both repos, an exact hard zero

1. Rewrite `check-argument-holes.js` on `lib/call-sites.js`:
   - rails `--src=DIR` (kept) and `--tests-repo=DIR` (new; default `../Fizzygum-tests` beside the Fizzygum repo).
     Tests repo absent → the tests half SKIPS and says so in its pass line (the `check-hand-lists` precedent).
   - rules: `HOLE` (violation line: file:line, callee identity, the arguments, and the WITNESS site, e.g.
     `  tests/SystemTest_X/SystemTest_X_automationCommands.js:67  new SimpleButtonWdgt  [ undefined | undefined | {…} ]  — HOLE: src/Y.coffee:12 passes 1`),
     and per D4 `SANCTION_EMPTY`, `SANCTION_STALE`. Delete `OVER_BASELINE` and `BASELINE`.
   - INVALID (exit 2, never a pass, never a rule): a source it cannot parse (name the file and the parser's message);
     a half that read nothing while its input is present (0 class fragments in src; 0 macro sources or 0 scripts
     with the tests repo present); a super call it cannot place on a class chain.
   - pass line: `[argument-holes] OK — 0 holes over <N> calls (src <a>, harness <b>, macros <c>, scripts <d>); <V>
     absences judged values; <S> sanctioned:` followed by one line per sanctioned site with its reason.
   - header: what it reads, the callers test as implemented (effective arity, witness), every D-ruling, its stated
     limits (foreign callees; forwarding `fn.call`; dynamic `new (classNamed …)`; strings other than the lifted
     kinds; unknown-arity sites per D3(d)).
2. Resolve the residue Unit 0 found (holes other than the family's): by the round's rulings — reshape, delete dead
   arguments (if D3(b) said so), or sanction (D4). Every sanction → a §9 line. A hole that turns out to be a real
   defect gets the R3 treatment (opts / reorder / adapter) in this unit.
3. `build_it_please.sh`: rewrite the gate's comment block (both repos, exact zero, no baseline; delete the stale
   "metadata PROSE" reason). The invocation line stays `node ./buildSystem/check-argument-holes.js` unless a flag is
   needed (if it changes, `fg homepage` joins §6.4).
4. Per D5: retire the `positional-hole` stink (`check-stinks.js` entry; `check-stinks-selftest.js` plant).
5. `fg build` green; then plant by hand ONE hole in a macro (edit a real test's source, run
   `node ./buildSystem/check-argument-holes.js` from `Fizzygum/`, see `HOLE` name it with its witness, restore with
   `git -C /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests checkout -- <file>`).

### Unit D — the bite-proof (`buildSystem/check-argument-holes-selftest.js`, rewritten in place)

`proveGate` with `gate: path.join(__dirname, 'check-argument-holes.js')` (spelled so `lib/what-runs.js` sees the
launch), `from: null` (a fixture src tree; plant `meta/Class.coffee` and `meta/Mixin.coffee` copied from the real
`src/meta/` if `lib/meta-compiler.js` loads them from the rail tree), and a fixture TESTS REPO built by the self-test
with `fs.mkdtempSync` (per run where its plants differ), passed in each run's `args` as `--tests-repo=<dir>`
(the `check-layering-selftest.js` precedent). Plants must not depend on prelude/ordering (bite-proofs lesson).
- **control** (exits 0 with the pass line): the callers-test VALUE half of the minimal pair — a fixture class with
  `bpCallee: (a, b, c) ->` and two sites `@bpCallee 1, undefined, 3` and `@bpCallee 4, 5, 6` (every site passes 3:
  VALUE); a trailing-only `@bpCallee 7, undefined, undefined`; a foreign `JSON.stringify x, undefined, 2`;
  `fn.call undefined, 1`; a string `"use undefined, then 1"`; an implicit-object call `@bpOpts 1, face: x, tip: y`
  beside `@bpOpts 2, face: z` (arity 2 both — no hole, though the regex read 3 vs 2); a correctly SANCTIONED
  misjudged value (if D4(a)); a fixture tests repo with one macro and one script holding only values.
- **run "the callers test flips a value into a hole"**: the control plus ONE more site `@bpCallee 8` (effective arity
  1). Expect `HOLE` on the `@bpCallee 1, undefined, 3` line, naming the new site as its witness. (The same `undefined`,
  value in the control, hole here: this is the distinction the gate exists for.)
- **run "a hole in the tests repo"**: a macro source with `new BpButton undefined, undefined, face: "x"` beside a
  `new BpButton face: "y"` (fixture class `BpButton` in the src fixture), and a script with
  `bpLocal(1, undefined, 3)` beside `bpLocal(1)` in the same file. Expect `HOLE` lines naming each tests-repo file.
- **run "sanctions"** (if D4(a)): a marker with no reason (`SANCTION_EMPTY`) and a marker on a value
  (`SANCTION_STALE`).
- **run "unreadable input" (`exit: 2`)**: a macro that does not parse; expect exit 2 naming it, no rule.
- **run "a half that reads nothing" (`exit: 2`)**: `--tests-repo=` an empty dir that exists.
- `prove-rules` then requires the union of fired rules = the gate's `of` (`HOLE`, plus `SANCTION_EMPTY` and
  `SANCTION_STALE` if D4(a); `HOLE` alone if D4(b)).
- **See it fail twice** (§6.3) before believing it.

### Unit E — docs, BACKLOG, local tooling

Present-tense, no chronology in non-chronological docs, no live counts in prose (say "the gate prints it"):
- `constructor-and-parameter-conventions.md`: R3 (the callers test is now mechanized: state effective arity and the
  witness), R1 (the `target, action` example), R7 (family list), §5 (rewrite: both repos, exact zero, the parser,
  the marker; delete the "hand sweep is load-bearing … nothing answers for the tests repo" paragraph's premise —
  keep its P4 lesson as the reason the gate reads the tests repo), §7 (conformance: both repos; fix the 2-vs-3
  inconsistency by stating no count; add the button head to the landed conversions).
- `lint-and-static-checks.md`: §3 `argument-holes` row; delete the `positional-hole` row (D5); §3c census row;
  §5 marker table (+ `# argument-hole-sanctioned` / `//` form; replace "All fifteen" with wording that states no
  count); §7 boundaries (the gate's stated limits); appendix anchors.
- `Fizzygum/CLAUDE.md` constructor bullet; `build_it_please.sh` (done in C); gate/census headers (done in B/C).
- `docs/BACKLOG.md`: close both items (§1.9) with a pointer to this plan; add a line for anything deferred.
- Umbrella `fg` (LOCAL, uncommitted): critique step 7's label ("gate is BLIND to most") and its command
  (`--holes` now prints verdicts).
- `node scripts/check-visualisations.js --strict` is NOT needed (no metadata changes) unless a test's metadata
  prose names the old spelling and is edited — then regenerate with `node scripts/make-visualisation.js <name>`.

### Close

1. `fg gauntlet` in the background (§6.4); all 20 legs.
2. ONE independent end-of-arc review: one fresh agent given §0 mandate, the rulings, and both repos' diffs (not
   your conclusions). Address every finding; log them R1… in §9.
3. Archive: move this file to `docs/archive/argument-holes-both-repos-plan.md` (plain `mv` if it was never committed —
   it was untracked when authored; `git -C /Users/davidedellacasa/code/Fizzygum-all/Fizzygum mv …` if the owner
   committed it meanwhile), stamp STATUS CLOSED with the closing gates; add an entry under `## OO cleanup, lint & modernization` in `docs/archive/INDEX.md` (the
   `tests-repo-readers-plan.md` / `every-gate-bites-plan.md` entries are the shape); BACKLOG pointers updated to
   `archive/`.
4. Memory: update `argument-holes-tests-arc.md` (closed; the lessons worth keeping) and its `MEMORY.md` line.
5. **Commits — draft, then WAIT for the owner's approval of EACH one** (never commit autonomously):
   - commit 1, one per repo: exactly the files on `commit-1-manifest.txt` (the conversion);
   - commit 2, one per repo: everything else (parser lib, vendored acorn, census, gate, proof, stink retirement,
     sanctions, docs, BACKLOG, archive move).
   Stage by explicit path (`git -C <repo> add <files>`; interactive staging is unavailable), write each message to a
   file and `git -C <repo> commit -F <file>`; messages end with exactly
   `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Show `git -C <repo> show --stat HEAD` after each.
6. Ask about PUSH separately, after all commits.

---

## §6 Cold-execution protocol and verification

### §6.1 How to run this doc

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — expect the SHAs in this doc's header (or later commits that
   do not touch the files named here; if they do, re-verify §1 before trusting it). `fg killz` if test browsers linger.
2. Read §0, then §1 against the code (grep each quoted name; line numbers drift), then the conventions doc R1–R7/§3–§7.
3. Unit 0 → the round (STOP) → A → B → C → D → E → Close. Each unit ends with its gates (§6.2) passing; log the unit
   in §9 with its proofs before starting the next.
4. If a fix shape is falsified twice, STOP and re-frame (the model is wrong) — do not try a third variant blind.
5. Everything long runs in the background (`run_in_background: true`, output to `/tmp/fg-<cmd>-run.log`); the
   harness notifies on exit. Peek at `/tmp/fg-<cmd>.verdict` at most every ~10 minutes and give the owner a one-line
   status each time. Never poll in a foreground loop (the guard hook blocks it). While a long op runs, src/,
   Fizzygum-tests/ and `fg` are READ-ONLY (it owns its inputs); this doc and memory are safe to edit.

### §6.2 Per-unit gates

- Every unit that edits code: `/Users/davidedellacasa/code/Fizzygum-all/fg build` (runs every static gate and every
  self-test) — never piped through `tail`/`grep` when its exit decides anything.
- Unit A additionally: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite > /tmp/fg-presuite-run.log 2>&1` in the
  background (~3 min: build + dpr1 suite ∥ paint audit ∥ fracplane dpr2 rider) — WITH the tripwire, then
  `fg menusweep`, `fg pinsweep`, `fg apps` (they construct buttons outside the suite); then without the tripwire,
  `fg build`. Pixel-neutral means the suite passes against the EXISTING references; a screenshot failure is a
  finding to diagnose, never a recapture.
- **After any edit to a file under `Fizzygum-tests/scripts/` that a page-driving rig or runner executes**: run one
  test under WebKit, `/Users/davidedellacasa/code/Fizzygum-all/fg test SystemTest_macroSliderDrivesAToggleButton --browser=webkit`
  (Playwright's `evaluate` takes ONE argument — a classic break), plus that rig's own `fg` leg (`fg pinsweep` for
  `pin-sweep-headless.js`, `fg menusweep` for the menu sweep, `fg graph`, …).
- Units B–D: `fg build`; `node ./buildSystem/check-argument-holes.js` and `node ./buildSystem/census-call-arity.js --holes`
  from `Fizzygum/`; `node ./buildSystem/run-selftests.js` from `Fizzygum/` (also `npm run selftest` in
  `Fizzygum-tests/` if a tests-repo self-test changed).
- After Unit E: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (background).

### §6.3 "A check is believed only after a plant has failed it"

- The tripwire (Unit A.9): seen throwing on a planted old-shape call before it is trusted.
- The gate (Unit C.5): a hand-planted macro hole fails it, naming the witness.
- The proof (Unit D): break the gate on purpose TWICE and see the proof fail each time — e.g. (1) make the callers
  test ignore witnesses (always VALUE): the "flips a value into a hole" run must fail; (2) make the tests half read
  nothing: the tests-repo run must fail. Restore after each.
- `lib/call-sites-selftest.js`: break one reading (e.g. count implicit-object keys) and see its case fail.

### §6.4 The closing gate

`/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet > /tmp/fg-gauntlet-run.log 2>&1` with `run_in_background: true`
(~16 min, 20 legs). Status to the owner about every ~10 minutes from `cat /tmp/fg-gauntlet.verdict` /
`tail -5 /tmp/fg-gauntlet-run.log`. A leg retried as a load-flake is a warning to report, not a failure; a hard FAIL is
diagnosed before anything is committed. `fg homepage` only if `build_it_please.sh`'s INVOCATION of the gate changed
(Unit C.3) — `src/boot` and `src/meta` are not touched by this arc.

---

## §7 Risks

| risk | consequence | mitigation |
|---|---|---|
| a dynamic or code-string construction of a family member keeps a positional call | silent mis-bind: `opts` = a widget, `target` lost | U0.6 census; the Unit A tripwire run through presuite + menusweep + pinsweep + apps |
| a converted multi-line site hits one of the two spelling traps (Unit A) | a forwarded-arguments super, or a second object silently dropped | `compile-fragment.js` on each new shape first; the parser's "argument count ≤ 1, no forwarding super" check over every family site; the tripwire |
| the parser sees LESS than the regex did (strings) | a hole goes unjudged, silently | U0.5 explains every old row and lists every code-string; the lifted kinds have self-test cases |
| fragment → file line mapping drifts | violation lines point at the wrong line | U0.1 verifies every fragment; text-match fallback |
| the structural node-kind reading of the minified 2.0.3 AST is wrong | wrong arity or a missed call | the 2.7 `ast: true` oracle cross-check in U0.1; one self-test case per kind |
| name grouping (D2a) produces false holes | the build fails on a value | U0.4 counts them before the round; D2(b) or D4 |
| build time | every build pays the parse | U0.9 budget; report if far over ~3 s |
| a later unit needs to edit a commit-1 file | commit 1 no longer matches its verified state | the manifest rule (Unit A.11): STOP and ask |
| the vendored acorn sits under a walked directory | another gate (hand-lists, trailing-whitespace) fails on it | U0.7 |
| the tests repo is absent (a production-profile build on another machine) | the gate must not fail or claim coverage | the tests half SKIPS and says so; the src half still judges |

## §8 Rejected alternatives (do not re-attempt)

- **Patch the regex parser's misreads.** An implicit object, a nested paren-less call and a string's contents need a
  grammar and a lexer, not a line regex (§1.3 a–f, all live).
- **Parse whole class files.** Bare `super` is a PARSE error in CoffeeScript 2.0.3 (measured: `unexpected
  indentation`), and a whole-file compile false-fails ~300 of ~500 files (`check-coffee-syntax.js` header). The
  fragments are what the browser parses.
- **Keep a baseline/ratchet.** The floor of 2 was two VALUES; a non-zero floor hides the rule it counts.
- **Exact-only callee identity (D2c).** Blind to the doc's prime hole example, `holder.add w, undefined, spec`.
- **A central allowlist for misjudged values (D4c).** The justification lives at the site (lint index §5).
- **Skip §3-exempt classes in the gate.** §3 changes the remedy, not the verdict.
- **Judge only the shippable set (`build.py --list-shippable`).** It omits the flag-gated `video-player` part; a hole
  there is still a hole.
- **Accept both button shapes during a transition (a compat shim).** Two spellings of one call is the cost the
  convention exists to remove, and the owner holds no compat obligations; R7 says one commit.
- **Land the gate before the conversion with a temporary baseline.** Contradicts the mandate (no baseline); the
  conversion comes first (Unit A).

## §9 Ledger (one entry per landed step; proofs inline)

- **2026-11-07 — authored** at Fizzygum `47f42386` / tests `a1627d4e8`. Facts in §1 verified that day: the 40-row
  census (§1.4), `nodes()` on the bundled 2.0.3 (structural kinds; bare `super` unparseable), acorn 7.4.1 122/122,
  2.7 `ast: true` (refuses `super` outside a method), the 18-class family, `IconButtonWdgt`'s dead parameter, zero
  npm dependencies in the build, no macro file with `${`, and the two multi-line spelling traps of Unit A (both
  reproduced with `compile-fragment.js` and the bundled compiler).
- **2026-11-07 — Unit 0 DONE (read-only; same SHAs, trees clean but this file).** Probe:
  `Fizzygum-tests/.scratch/argument-holes/survey.js` (`--real-compile`, `--no-oracle`); full report `out/report.txt`,
  call table `out/calls.json`, numbers `out/summary*.json`. Readings below are "D2(a), absences {undefined}, witness
  by WRITTEN count" unless stated.
  - **U0.1 parse coverage — 0 failures.** src: 561 `.coffee` (539 class, 8 mixin, 14 other); harness: 25 (all class).
    The real `Class`/`Mixin` driven through the `check-coffee-syntax` shim with the `_equivalentforSuper` output tapped
    (it is same-line; the constructor's later `_addInstancesTracker` INSERTS lines, so tapping `compileFGCode` would
    not map). **6363 class-member fragments, every one mapped EXACTLY** (fragment line 0 = the rest of the
    `  name: …` header line, line k = header + k, verified verbatim; the text-match fallback never needed). 389 macro
    sources = every top-level template literal of 373 macro files, read COOKED from acorn (0 with `${`, 0 whose cooked
    text shifts a line); 0 needed the post-rewrite retry. Heredocs: 17 `Macro.fromString` calls, the 15 with a
    literal argument lifted (0 content lines off their file line, content line k = the `"""` line + 1 + k); the other
    2 (`AutomatorEventCommandStartMacro`) take the macro sources themselves, already units. acorn 7.4.1: 122 scripts +
    373 macro JS shells. `compileFGCode` STUBBED (returns `'(function() {});'`): the call table is byte-identical to a
    real-compile run (sha `fb023510…`, same 6363 fragments, same 50,835 calls) — the gate need not compile.
  - ⭐⭐ **The 2.7 oracle caught a structural misread.** 6789 CoffeeScript units, 0 refused by 2.7. First run: 877
    disagreements, ALL `new`: in 2.0.3 an argument-LESS `new X` is not a Call node but `Op('new', X)` (873 sites), and
    `new X(args).prop` is `Op('new', Value(Call(X, args), [.prop]))` around a NON-new inner Call (2 sites,
    `src/boot/extensions/SWCanvasElement-extensions.coffee`; both compilers emit `new X(args).prop`). With both shapes
    taught: **0 disagreements, 38,130 calls agree.** It mattered: arity-0 `new` sites are WITNESSES — `new
    SimpleButtonWdgt` (no arguments) at `SystemTest_macroCornerRadiusPromptOnANonBoxWidget:37` witnesses 5 of the 8
    family holes. ⇒ Unit B.3's self-test needs one case per call shape: `Call`, bare `Op('new')`, `Op('new')` over a
    property chain.
  - **U0.2 the table:** 50,835 calls — CoffeeScript `new` 5071, super 376, `@m` 9767, receiver 20,573, bare 2343; JS
    bare 3757, receiver 8298, `new` 644, `this.` 6. Splat 74; forwarding supers 141; non-plain `new` 65. Candidates
    (an absence BEFORE a present argument): 50 under {undefined}, 65 under {undefined, null}, 65 adding `void 0`.
  - ⭐⭐ **U0.3 — the witness must be counted AS WRITTEN, not by effective arity** (§4 D3(b) says the opposite). By
    effective arity the doc's own worked VALUE `_applyTransformSugarNoSettle undefined, s` reads HOLE: its mirror
    `@_applyTransformSugarNoSettle deg, undefined` (`Widget.coffee:1926`) WRITES both slots but has effective arity 1.
    R3's wording is "OMITS that position's trailing tail", the readers arc's "passes fewer than j+1 arguments" — the
    written count. It is the only verdict the two bases disagree on. (Price, to state in the gate: a caller that pads
    its tail with `undefined` writes the slot and is no witness — the mirror case.) Result: **12 HOLES, 24 VALUES,
    2 foreign, 12 excluded** (`.call`/`.apply` this-arg).
    - HOLES — the family, **8 sites** (§1.4 said 7: the regex folded two calls on one line): `new SimpleButtonWdgt
      undefined, undefined, …` ×5 (EveryPressIsToldItsEnding:67, SliderDrivesAToggleButton:29 ×2, pin-sweep:274/275),
      `new ButtonWdgt world, undefined, …` ×2 (MixinEditDonorAndOverride:31, MixinFieldEditDonorAndOverride:32),
      `new LabelButtonWdgt undefined, undefined, …` ×1 (RelabelledLabelButtonsStayPlaced:30). Witnesses: `new
      SimpleButtonWdgt` (written 0), `graph-liveness-headless.js:199` `new ButtonWdgt(b, 'hide')` (2), MagnetWdgt's
      `super target, undefined` (2).
    - HOLE — `menu.addMenuItem('Plant no target', undefined, 'biteProofNoop')` (`menu-click-sweep-selftest-headless.js:60`;
      witness `BinWdgt.coffee:68` `addMenuItem "Cancel"`, written 1; 333 sites, written {1:2, 3:216, 4:115}). The
      absent target IS the plant (the sweep's `NO_TARGET` rule): a value the mechanical test calls a hole — D4's case.
    - ⭐ HOLES the regex never saw — `new FrameWdgt(undefined, { labelContent: … })` ×3
      (`serialization-roundtrip-headless.js:303`, `:1363`; `serialization-file-roundtrip-headless.js:132`; the regex
      took the first `undefined` as the callee). FrameWdgt ctor sites, written {0: 47, 1: 46, 2: 4}. Diagnosis: a DEAD
      argument — `FrameWdgt`'s constructor reads only `opts.closeButton`; the only `labelContent` in either repo is
      `WidgetHolderWithCaptionWdgt`'s own field. Each call ≡ `new FrameWdgt()`.
    - VALUES: `_paintInLocalScope` (27 sites, all 4); `_applyTransformSugarNoSettle` (2, both 2); the 18
      `@assertValuesEqual "…", undefined, x` (1540 sites, all 3); 2 `processKeyDown` (3 sites, all 6);
      `newParentChoice undefined, nestedMenu` (its only textual site — §0.4 reframe 6 confirmed); `aim-census.js`
      `visit` (file-local, 4 sites, all 3).
    - D2(a) vs D2(b): **0** verdicts differ, under every absence set. D2(c) leaves 4 candidates unjudged — the
      `addMenuItem` plant (a hole by the test), `newParentChoice`, both `processKeyDown`.
    - D3(c): adding `null` adds 0 real holes, **1 false hole** (`scripts/lib/diffwork-selftest.js:54`
      `run(null, '', 0, 'SIGKILL')` — `null` there is Node's exit code for a signal-killed child, a value), 1 value
      (`group(…, null, […])`), 11 foreign `JSON.stringify(x, null, n)`, 2 excluded `Math.max.apply(null, …)`. `void 0`:
      0 sites in either repo; CoffeeScript has no `void`.
    - The strict reading (a witness must stop before the FIRST present argument after the absence) changes nothing.
  - **U0.4:** grouping by name produced no false hole. Names carrying a candidate, with INDEPENDENT definitions (a
    definer no ancestor of which defines the name): `processKeyDown` 3 (CaretWdgt, SimpleSpreadsheetWdgt,
    VideoPlayerWdgt — every site passes 6), `addMenuItem` 2 (MenuWdgt, CommandPanelWdgt), `run` 2 + a JS file-local,
    the rest 1. `stringify`: 123 sites, every one on `JSON.`, defined nowhere — foreign.
  - **U0.5 — all 40 old rows explained, 0 coverage lost:** VALUE 24 rows (the 18 `assertValuesEqual` —
    WindowGripStrip:124 is misread (f), regex arity 4, CoffeeScript 3 — 2 `processKeyDown`, `_paintInLocalScope`,
    `_applyTransformSugarNoSettle`, `newParentChoice`, `visit`); HOLE 8 rows (the 7 family rows = 8 sites, every one
    misread (a) on its callee — `btn`, `button`, `new`, `undefined` ×2 — plus the `addMenuItem` plant); foreign (e) 2
    (`JSON.stringify`); trailing-only (d) 5 (`setValue(n, undefined, undefined)`: the only `setValue` is
    `SliderWdgt.setValue: (newvalue)`, so both are DEAD arguments); not a call (a) 1 (`[entry, undefined, undefined]`,
    `menu-click-sweep-headless.js:790`). Gains: the 3 FrameWdgt holes and the second SliderDrives site. Strings: ONE
    string literal in either repo holds an absence then a comma — `"undefined,B2"`
    (`SystemTest_macroSpreadsheetEnterTabDeleteMoves:61`), an assertion's expected VALUE (data); the lifted heredocs
    hold 72 calls, 0 candidates; no formula, `evaluateString` or `page.evaluate` string holds one. ⇒ no string kind
    beyond the heredocs needs lifting. Trailing-only `undefined` sites overall: 44 (src 28, macro 1, scripts 15).
  - **U0.6 the work list.** Family = 18 classes (walking `extends` over src + harness) = §1.7. `new` sites: **71**
    (src 52, macros 11, scripts 8) — SimpleButtonWdgt 25/5/7 (§1.7's "src 31" folded in LabelledToggle/Chip lines),
    LabelledToggleWdgt 5, MagnetWdgt 4, CodeInjectingSimpleRectangular 4, SimpleRectangular 3, CloseIcon 3,
    MenuItemWdgt 1 + 3 macros, ButtonWdgt 2 macros + 1 script, LabelButtonWdgt 1 macro, ChipWdgt / MemberRowWdgt /
    CollapseIcon / UncollapseIcon / EditIcon / OverflowChevron / VideoThumbnail 1 each; **46** carry the positional
    `(target, action, …)` head. The regex census's 71 family rows all coincide with a parser site (0 regex-only).
    Family constructor supers: 13, **0 forwarding**. No constructor (inherit IconButtonWdgt's head): CloseIcon,
    CollapseIcon, UncollapseIcon, EditIcon, OverflowChevron. Prototype `target:`/`action:`: only ButtonWdgt's own
    declarations — no subclass default the `@param` clobbered. Dynamic constructions (65 non-plain `new` plus
    `new <variable>`: `globalFunctions` `new ctor`, `WellKnownObjects` `new appClass`, MacroToolkit `new eventClass`,
    the menu sweep's `new Klass(...makeArgs())`, `staleness-census.js`'s `new K()`): none can build a family member
    (`REPRESENTATIVES` names none; K are app classes). Code strings naming a family class after `new`: 0. D6(a):
    `IconButtonWdgt (@target)` is DEAD by compile (`this.target = target;` then the super call passes `this`); no
    reader expects the passed value (`EditIconButtonWdgt.actOnClick` reaches its frame via `@parent`; the menu sweep's
    `chevron.target[chevron.action]` expects the button). ⚠ `FrameBarWdgt._createAndAddEditButtonNoSettle`'s "The
    button targets the FRAME (bound ref)" is FALSE — Unit A rewrites it. D6(b): VideoThumbnailWdgt's one caller and
    SimpleRasterImageButtonWdgt's one (that super) pass 4 positional, no hole. Mentions to update — Unit A: comments
    in ButtonWdgt (header), SimpleButtonWdgt:52, LabelledToggleWdgt:38, ChipWdgt:42, SimpleRectangularButtonWdgt:11,
    MagnetWdgt:23, FrameBarWdgt:490; `MACRO-PATTERNS.md` :1504–1505, :1607, :1665; `widget-authoring-guidelines.md`
    :609. Unit E: conventions doc :58 (R1) and :320, lint index :155, BACKLOG :19/:40/:45. Unit B: the reader lists
    in `lib/tests-repo-code.js` and `lib/coffee-mask.js` headers. Untouched: the dated
    `measurements/widget-practices-survey-2026-08-14.md`, every `addMenuItem label, target, action, opts` (another
    head). No `.claude/` skill shows the spelling.
  - **U0.7 vendor path.** Walked: `lib/what-runs.js` — `buildSystem/` recursively (`.js|.sh|.py`), Fizzygum's
    top-level `.sh`, the tests repo's `scripts/`; `check-hand-lists.js` — `buildSystem/` (`.js`, `.py`) and `src/`;
    `run-selftests.js` — the whole repo, for self-test-NAMED files only; trailing-whitespace / dead-methods /
    scheduled-checks / stringified-scripts — `src/`; jscpd — `src`. `vendor/` is read only through explicit lists
    (`parts.json` vendor entries, `build_it_please.sh`'s swcanvas lines) and `build.py` copies only what a shipping
    part names. ⇒ proposed `Fizzygum/vendor/acorn/acorn.js` = acorn 7.4.1 `dist/acorn.js` (one self-contained UMD
    file, 200,010 bytes, sha256 `927b7d8a9d2bf55926da92b2937fab23d7ca49ff17539fcd36cccea9e3ff44ba`) + a README.
  - **U0.8:** no unknown-arity site (74 splat, 141 forwarding supers) belongs to a callee with a candidate; read as
    witnesses at their minimum arity they flip nothing.
  - **U0.9 budget:** the whole table plus all 18 callers-test variants = **2.39 s** (stub compile, no oracle, load
    average ~5): fragmenting 0.26, 2.0.3 `nodes()` 1.13, acorn 0.15, heredocs 0.06, table 0.30, one variant ~0.025 ⇒
    the gate ~2.0 s, against today's hole gate 0.81 s and syntax gate 1.41 s. A real compile instead of the stub adds
    1.25 s; the oracle (Unit 0 only) ~6 s.
  - **Residue after Unit A on the recommended settings: 4** — the `addMenuItem` plant (D4) and the 3 dead
    `labelContent` arguments (each → `new FrameWdgt()`, Unit C.2).
- **2026-11-07 — Unit 0 recommendations re-checked against the owner's principles** (one of each thing, reuse the
  existing mechanism, delete what a fix makes redundant, the Right Thing regardless of churn). Four revised; the
  round is still pending.
  - **D3(b) REVERSED back to EFFECTIVE arity** (the plan's original wording). Counting witnesses as WRITTEN kept the
    doc's worked VALUE `_applyTransformSugarNoSettle undefined, s` — a mechanism bent to fit a doc example, and it
    makes the gate SPELLING-dependent (padding a tail with `undefined` hides a witness), while the codebase reads an
    explicit `undefined` as absence everywhere (R2's `?`). By R3's own SliderWdgt rule — DISJOINT tails, one caller
    wants only rotation, the other only scale — that record is an options bag: `_applyTransformSugarNoSettle
    rotation: deg` / `scale: s`, read `opts.rotation` / `opts.scale` guarded (2 private call sites, pixel-neutral).
    Unit E rewrites R3's worked-case row and the §5/§7 mentions accordingly. `_paintInLocalScope` stays the doc's
    worked value (all 27 sites pass 4 under either basis). Effective vs written differ on that one site only.
  - **D4 REVERSED to (b), no marker.** The one misjudged value is a test plant, and the same self-test already plants
    its other broken states by building normally and clearing a field (`p.okButton = undefined`,
    `p.okButton.action = undefined`): the target-less row follows that precedent (add the row with `this`, then clear
    the last row's `target`). With no sanction needed, the gate carries no exception mechanism (no
    `SANCTION_EMPTY`/`SANCTION_STALE`, no marker row); a future value the test misjudges is reshaped, or the marker is
    proposed then.
  - **D6(b) REVERSED: convert the two video-player heads.** After the conversion `target` / `action` / `arg1` are
    option KEYS throughout the family; `SimpleRasterImageButtonWdgt (@imagePath, target, action, argumentToAction1)`
    and `VideoThumbnailWdgt (imagePath, @videoPath, target, action)` would be the only members taking the generic
    pair positionally. → `(@imagePath, opts = {})` and `(imagePath, @videoPath, opts = {})`, the caller
    `new VideoThumbnailWdgt "…png", "…webm", target: @, action: "_onRecommendationClicked"`. The discriminator: a
    subclass that passes the GENERIC pair through takes keys; one that FIXES the action and names its own operand
    keeps its head (`CodeInjectingSimpleRectangularButtonWdgt (palette, face, @drawingToolKey)`,
    `MenuItemWdgt (commandSpec, opts)`).
  - **D3(b) dead arguments: delete them, not "optionally"** — the five `setValue(n, undefined, undefined)` (the only
    `setValue` takes one parameter) and the three `labelContent` calls.
  - **Unit B refinements (no decision needed):** "is this name ours?" = exactly `lib/name-definitions.js`
    `harvestDefs` (over src, harness, macro sources, heredocs) plus JS definitions — measured: identical verdicts in
    all 18 variants to the probe's wider set, so the lib adds no logic of its own. ONE macro-source reader:
    `lib/tests-repo-code.js` `macroSources` returns the COOKED text the page compiles (19 of 389 sources differ from
    the raw text today, all escapes in comments/strings) and the call-sites lib reads it rather than a second
    template finder. ONE verdict printer: the gate (with `--values` to list the judged values); the census keeps its
    query modes (`<Class…>`, `--super=`, `--call=`) and drops `--holes`; `fg` critique step 7 runs the gate.
  - **NEW question for the round (scope):** vendoring acorn leaves TWO JS readers in `buildSystem/` — acorn and the
    hand-written lexer `lib/js-mask.js` (115 lines, 8 consumers, stated limits). Recommendation: re-base `maskJs` on
    acorn's tokenizer in this arc (its API unchanged, gated on byte-identical output of every consumer), deleting
    the lexer and its limits; else a BACKLOG line.
- **2026-11-07 — OWNER ROUND ANSWERED: "go with the revised recommendations".** On js-mask: "depends on whether
  it's used at runtime by fizzygum. If so, I like minimal and clear solutions rather than canned libraries. If no,
  you can remove and use acorn." Verified build-time ONLY (no reference from `src/`, the harness, `build.py`,
  `parts.json`, `build_it_please.sh` or `runtime-prelude/`; its consumers are Node gates and tools) ⇒ the hand lexer
  goes and acorn serves its consumers. ⚠ The owner's standing preference this records: code that RUNS in Fizzygum is
  minimal and hand-written, never a canned library; build-time tooling may use a vendored one. **These rulings
  AMEND §4–§5; where a unit's text disagrees, this entry wins:**
  - **D1 (a):** browser 2.0.3 `nodes()` through `lib/meta-compiler.js` (tap `_equivalentforSuper`, `compileFGCode`
    stubbed — measured byte-identical); acorn **7.4.1** vendored at `Fizzygum/vendor/acorn/acorn.js` + README;
    `compile-fragment.js` drives the real rewrite (its transcription deleted). One self-test case per 2.0.3 call
    shape (`Call`, bare `Op('new')`, `Op('new')` over a property chain).
  - **js-mask (Unit B):** `lib/js-mask.js`'s hand lexer is removed; its consumers read JS through acorn (the mask
    API kept only if that is the minimal seam — decide in Unit B by reading the consumers), each consumer's output
    byte-identical before/after. `macroSources` returns COOKED text; the call-sites lib reads it.
  - **D2 (a)** by name; "ours" = `harvestDefs` (src, harness, macro sources, heredocs) + JS definitions, nothing more.
  - **D3:** (a) foreign callees not judged, `.call`/`.apply`/`.bind` this-arg excluded; (b) witness by EFFECTIVE
    arity; trailing-only absences are never candidates; **delete the dead arguments** (5 `setValue`, 3
    `labelContent`); `_applyTransformSugarNoSettle` → `rotation:` / `scale:` keys (Unit C.2; Unit E rewrites R3's
    worked-case row); (c) absence = `undefined` only; (d) unknown-arity sites never witness, counted in the pass
    line; (e) §3-exempt classes judged like any other.
  - **D4 (b): no marker.** The menu-sweep plant builds its row with `this` and clears the row's `target` (the
    file's own `p.okButton = undefined` precedent). The gate's rules: `HOLE` only (+ INVALID exits). Unit D drops
    the "sanctions" run and the sanctioned control item.
  - **D5 (a):** retire the `positional-hole` stink (entry, self-test plant, doc rows).
  - **D6:** (a) `IconButtonWdgt` takes no parameter (`super target: @, action: 'actOnClick', face: new Widget`),
    `new EditIconButtonWdgt` drops `@frame`, FrameBarWdgt's false "targets the FRAME" comment rewritten; (b)
    **CONVERT** the video-player heads: `SimpleRasterImageButtonWdgt (@imagePath, opts = {})`,
    `VideoThumbnailWdgt (imagePath, @videoPath, opts = {})` (Unit A, commit 1).
  - **Unit B/C:** ONE verdict printer — the gate (`--values` lists the judged values); `census-call-arity.js` keeps
    `<Class…>`, `--super=`, `--call=` and drops `--holes`; umbrella `fg` critique step 7 runs the gate.
  - Residue Unit C.2 resolves: the plant reshape, 3 `labelContent` deletions, 5 `setValue` dead-argument deletions,
    the `_applyTransformSugarNoSettle` keys. Expected exact zero after it.
- **2026-11-07 — Unit A (the button family conversion) DONE.**
  - New spellings checked first with `compile-fragment.js`: MenuItemWdgt's multi-line super in the paren form → ONE
    object; the trap form (`super target: …, action: …,` + indented keys) reproduced → TWO objects; IconButtonWdgt,
    MagnetWdgt, SimpleRasterImageButtonWdgt (`Object.assign {}, opts, face:, padding:`), VideoThumbnailWdgt
    (`imagePath, Object.assign {}, opts, arg1: @videoPath`) → one object each.
  - Heads → `(opts = {})`: ButtonWdgt (`@target = opts.target`, `@action = opts.action` first, unconditional),
    LabelButtonWdgt, SimpleButtonWdgt, ChipWdgt, LabelledToggleWdgt; SimpleRectangularButtonWdgt now `super opts`;
    MenuItemWdgt `super(` target/action keys first `)`; MagnetWdgt `super target: target`; IconButtonWdgt no
    parameter; the video-player pair converted per D6(b). Call sites: 31 in src, `new EditIconButtonWdgt` (dropped
    `@frame`), the VideoThumbnail caller, 7 macro sites in 6 tests, 8 JS rig sites (graph-liveness, pin-sweep ×2,
    serialization-roundtrip ×3, staleness-census ×2). Comments rewritten (ButtonWdgt header, the four "head
    (target, action)" lines, SimpleRectangular's header, MagnetWdgt, IconButtonWdgt, FrameBarWdgt's false "targets
    the FRAME"); `MACRO-PATTERNS.md` ×3 and `widget-authoring-guidelines.md` ×1. The video-player files pass
    `check-coffee-syntax.js --files` (4 classes, 40 fragments).
  - Parser re-census (the survey, re-run): 71 family `new` sites; every site of an `(opts)`-headed class passes ≤ 1
    argument (the only 2–3-argument ones go to the classes keeping a head of their own: CodeInjecting… `(palette,
    face, key)`, MenuItemWdgt/MemberRowWdgt `(commandSpec, opts)`, VideoThumbnail `(imagePath, videoPath, opts)`);
    13 family supers, 0 forwarding. Callers test: the 8 family holes gone; left exactly the Unit C residue (the
    plant, 3 `labelContent`, `_applyTransformSugarNoSettle`).
  - First build FAILED on my own comment ("where the head used to assign them" — `comment-narration` 88 > 87);
    reworded, build OK.
  - Tripwire (7 heads, `# TRIPWIRE-TEMP`): seen BITING before trusted — a `--prelude=` plant
    (`.scratch/argument-holes/plant-old-button.js`: `new SimpleButtonWdgt(world, 'hide', {…})`,
    `new EditIconButtonWdgt(world)`) fails SliderDrivesAToggleButton with both `BUTTON_HEAD_TRIPWIRE` page errors.
  - WITH the tripwire: `fg presuite` OK (dpr1 PASS 93 s, paint audit 0 offenders of 373, fracplane PASS — against the
    EXISTING references: pixel-neutral); `fg menusweep` OK (4969 items + 74 prompt OKs, 20/20 contributors), `fg
    pinsweep` OK, `fg apps` OK, `fg graph` OK (59 checks), `fg census` OK, `serialization-roundtrip-headless.js` OK
    (114 expectations), `fg test SystemTest_macroSliderDrivesAToggleButton --browser=webkit` PASSED; no
    `BUTTON_HEAD_TRIPWIRE` anywhere. ⚠ The first serialization run read INVALID (exit 2, "Target closed" at
    boot): I had started `fg test` beside it, and every `fg` verb opens with `kill_browsers` (`pkill` of every
    headless Chrome/WebKit) — never run an `fg` verb concurrently with a standalone rig. Re-run alone: OK.
  - Tripwire removed (0 `BUTTON_HEAD`/`TRIPWIRE-TEMP` left), `fg build` OK. Diff: Fizzygum 26 files ±102, tests 10
    files ±14.
  - **Commit-1 manifest** `.scratch/argument-holes/commit-1-manifest.txt`: the 36 files WITH the git blob sha of
    their verified content (`git hash-object -w`). ⚠ Deviation from A.11's "no later unit edits a manifest file":
    `scripts/serialization-roundtrip-headless.js` is in commit 1 (3 button sites) AND carries Unit C residue (2 dead
    `labelContent`, 5 dead `setValue` arguments) — an overlap the plan did not foresee, not an incomplete
    conversion. Commit 1 therefore stages each file by its manifest BLOB (`git update-index --cacheinfo
    100644,<sha>,<path>`), and every other manifest file must still hash to its sha at commit time — strictly
    stronger than the plan's rule. Owner told at the commit review.
- **2026-11-07 — Unit B (one parser) DONE.**
  - `vendor/acorn/` — acorn 7.4.1 `dist/acorn.js` (sha256 `927b7d8a…44ba`), its MIT `LICENSE`, a README (version,
    tarball, integrity, sha, who reads it, build-time only, do not hand-edit).
  - `lib/js-mask.js`: the hand lexer REMOVED (owner: build-time only ⇒ acorn); `maskJs` keeps its `{ mask, templates }`
    API, computed from `acorn.parse` (comments → cut; string/regex literals and template text → str; each `${…}`
    code), and refuses an unparseable text (`JS_MASK_UNPARSEABLE`). Dead `codeOfJs` deleted. Held byte-identical: a
    char-by-char mask + template comparison over every JS file a consumer reads (596) — identical but for the files
    edited in the step; `testsRepoCode`, `macroSources`, the run set identical; check-coffee-syntax, dead-methods,
    unresolved-sends, call-separation, public-private census, macro-source discipline, aim tables — outputs
    byte-identical; self-tests +1 case only. Bite: a plant that stops cutting comments fails 5+
    tests-repo-code-selftest cases.
  - `macroSources` returns the COOKED text (19 of 389 sources differ from raw, all escapes in comments/strings; 0
    lines move); `testsRepoFiles` is the one file-set decision (`macroFiles` shared). tests-repo-code-selftest:
    the lenient "unterminated template read to the end" case became "refused, naming why" + a cooked-text case.
  - `lib/meta-compiler.js` (the shim, factored out of check-coffee-syntax.js — its output byte-identical, self-test
    green); `compile-fragment.js` runs the REAL `_equivalentforSuper` (transcription deleted; the member name now
    read from the fragment's key).
  - `lib/call-sites.js` (+ `call-sites-selftest.js`, 24 cases): lifted from the probe. ⭐ The lib's own self-test
    caught a coverage gap the probe's verdicts never exercised — an INDENTED macro helper (`helper = (a, b) -> a`)
    is beyond harvestDefs' line forms, so it read as FOREIGN and would never be judged; a macro program's assigned
    functions are now names. ⭐ Mixin supers are placed by the INNERMOST function-valued property around them
    (two mixins indent members 4 spaces, not 6 — the regex the probe used missed both). Against the probe: 50,837
    sites both ways, identical verdicts. Bite: dropping the bare `Op('new')` shape fails 3 cases.
  - `census-call-arity.js` re-engined on the lib (regex parser deleted; `<Class…>`, `--super=` (the supers IN those
    classes), `--call=`, `--min=`; `--holes` refused, pointing at the gate). Family re-census on the new engine: all
    47 `new` sites of the `(opts)` heads pass ≤ 1 argument; every family-constructor super passes one object except
    MemberRow/VideoThumbnail (heads of their own).
- **2026-11-07 — Units C+D (the gate, its bite-proof) DONE.**
  - `check-argument-holes.js` rewritten on the lib: rails `--src=`, `--tests-repo=`; `--values`; one rule `HOLE`
    (with its witness); INVALID (exit 2) for an unreadable source / unplaceable super / a half that read nothing.
    First run: exactly the 5 residue holes. Residue resolved (C.2): `_applyTransformSugarNoSettle` → `rotation:` /
    `scale:` keys; the 3 dead `labelContent` → `new FrameWdgt()`; the 5 dead `setValue` arguments deleted; the
    menu-sweep plant builds its row whole then clears `target`. Result: **`[argument-holes] OK — 0 holes over 50837
    calls (src 24063, harness 666, macros 13403, scripts 12705); 23 absence(s) judged values`**.
  - `positional-hole` stink retired (entry + self-test plant; check-stinks green, 15 of 15 rules planted).
    `build_it_please.sh` comment rewritten (invocation unchanged ⇒ no `fg homepage`). Umbrella `fg` critique step 7
    runs the gate's verdict line.
  - C.5: a hand-planted `new SimpleButtonWdgt undefined, face: …` in a real macro fails the gate naming
    `BinWdgt.coffee:56` as witness; restored from a copy (NOT `git checkout` — that file carries a Unit A edit).
  - Unit D: `check-argument-holes-selftest.js` rewritten (21 cases): a values-only control (incl. an implicit-object
    minimal pair a key-counting reader would call a hole), the flip run (`@bpCallee 8` makes the value a HOLE naming
    its witness), a tests-repo run (a macro and a script hole), two INVALID runs. Seen failing twice: witnesses
    ignored ⇒ the flip and tests-repo runs fail; the tests half reading nothing ⇒ the control reads INVALID.
  - The rigs the residue edited, run alone: menu-click-sweep-selftest-headless (35 cases, NO_TARGET still bites),
    serialization-roundtrip OK, serialization-file-roundtrip OK (10 checks).
- **2026-11-07 — Unit E (docs) DONE.** Conventions doc (R1 example, R3's mechanized callers test + the worked-case
  row reversed with its reason, §5 rewritten — both repos, exact zero, the parser, stated limits incl. the
  positional-into-opts trap, P4 as the reason the gate reads the tests repo — §7 with no count); lint index (§3
  row, the stinks summary without `positional-hole`, its table row deleted, §3c census row + `fg critique`, the
  reader sections, `compile-fragment` how-to with the two mis-binding spellings, appendix anchors, "All fifteen"
  → no count); `Fizzygum/CLAUDE.md` constructor bullet; BACKLOG (2 closed as `[x]` stubs, this arc's 3 open items
  filed). `fg build` OK; `check-doc-narration` 0.
- **2026-11-07 — Close.** `fg gauntlet` 20/20 OK (947 s, no load-flake retry). ONE independent end-of-arc review (a
  fresh agent given the mandate, the rulings and both diffs): the conversion clean — no mis-bind, 0 trap spellings,
  field order unchanged; the reader accurate on 26 call shapes and on every line. Its findings, all in the gate and
  its proofs, all addressed:
  - **R1 (the dangerous direction): a witness could HIDE.** A bare call was keyed `local:<file>#n` whenever its own
    file declared n, while calls from other files keyed `name:n` — 67 names split (`loadJSFilePromise`: 10 local, 4
    elsewhere). Fixed by LEXICAL scope: a name is local only as a parameter or a definition nested in a function; a
    top-level one (a boot global, a JS module's function) is one `name:` group from every file. Grouping all bare
    calls by name instead was measured: it invents a false hole (aim-census's top-level `visit` against
    FrameWdgt's method-local `visit`), so the lexical rule is the precise one. Today: 0 holes either way.
  - **R2: classes a script or a macro defines were foreign.** JS `class` declarations and macro-program classes now
    join the class table; `new a.b.X` names X; `new @constructor` names its own class.
  - **R3: the harness half was neither proven nor guarded.** The gate is INVALID on a tests repo with no harness
    file; the gate's proof reads a harness class in every fixture and plants a harness HOLE; call-sites-selftest
    holds a harness case. The reviewer's mutation (harness loop deleted) now fails both proofs.
  - **R4: `ctorOwner` was untested.** A constructor-less subclass case; the mutation `ctorOwner = (n) => n` fails it.
  - **R5: an interpolated heredoc was skipped silently.** A `Macro.fromString` argument that is not a plain
    reference (`eachSource`, `@mainMacroSource`) and not a literal is UNREADABLE.
  - **R6: acorn 7.4.1 stopped at ES2021, and a refusal named no file.** Vendored acorn **8.19.0** (released
    2026-10-05; tarball sha512 checked against the registry), both parsers at `ecmaVersion: 'latest'` — js-mask over
    all 599 files identical under 7.4.1 and 8.19.0; `JS_MASK_UNPARSEABLE` names the file wherever the reader has it.
    (This revises the D1 sub-ruling "7.4.1 on disk": a class field in a rig would have crashed every masking gate.)
  - **R7 docs:** the archive links resolve (this move); §7's narration rephrased; the limits lists match the fixed
    identity rules; a self-test comment that contradicted its own assertion fixed; the callee formatter is ONE
    (`describeCallee` in the lib, used by the gate and the census).
  - Post-fix: call-sites-selftest 36 cases, the gate's proof 22; each new case seen failing under its mutation;
    consumers byte-identical; the gate `0 holes over 50837 calls`; `fg build` OK; the gauntlet re-run on this state.

## BACKLOG ledger

(Items this arc files or defers; each also gets a `docs/BACKLOG.md` line under this plan's heading.)
- CLOSED here: `docs/BACKLOG.md`'s "`check-argument-holes` over the tests repo's code (owner ruling D5)" (both
  pieces) and "`check-argument-holes` reads string contents as code" (every-gate-bites §8.3) — a real parser
  never reads a string as a call.
- FILED (open, `docs/BACKLOG.md` under this plan): a positional argument handed to an `(opts)` head has no static
  check (a "more arguments than the callee declares" rule over the call-sites table would also catch dead
  arguments); two readers of a test's macro sources (cooked/by-line vs raw/by-offset); `_equivalentforSuper`
  rewrites `super ` inside strings and comments too.

## References

- `docs/architecture/constructor-and-parameter-conventions.md` — the law (R1–R9, §3, §5, §7).
- `docs/architecture/lint-and-static-checks.md` — §3 gate index, §3c censuses, §5 markers, §7 boundaries.
- `docs/archive/tests-repo-readers-plan.md` — "Owner ruling D5" (this arc's origin), `lib/tests-repo-code.js`.
- `docs/archive/every-gate-bites-plan.md` — §8.2 (registry + proof contract), §8.3 (the strings-as-code mask).
- `docs/archive/constructor-parameter-conformance-plan.md` — the regex parser's birth, P0–P9, §7b/§7c.
- `buildSystem/compile-fragment.js` — compile one fragment the browser's way (check a new spelling before converting).
- `buildSystem/check-coffee-syntax.js` — the fragmenting shim; `buildSystem/lib/{gate-rules,planted-src,prove-rules,name-definitions,tests-repo-code,js-mask,coffee-mask}.js`.
- `src/meta/Class.coffee` `_equivalentforSuper`; `src/macros/Macro.coffee`; `src/macros/MacroToolkit.coffee` (`standardMacroSubroutines`).
- `Fizzygum-tests/.scratch/tests-repo-readers/holes-callers-test.js` — the readers arc's probe (old parser).
- Memory: `argument-holes-tests-arc.md` (pre-plan findings), `every-gate-bites-plan.md`, `bite-proofs.md`,
  `tests-repo-readers.md`, `constructor-parameter-conformance-arc.md`, `ask-before-commit-push.md`.

## Appendix A — sketches (verify against the code; these are shapes, not finished code)

**Tapping fragments** (inside `lib/meta-compiler.js`, from `check-coffee-syntax.js`'s shim):
```js
// compileFGCode is a factory PARAMETER the real Class/Mixin close over; replace it with a tap.
const fragments = [];
const compileFGCode = (src, bare) => { fragments.push({ file: currentFile, cls: currentClass, member: currentMember, src }); return ''; };
// drive: new Class(fileText, true, false)  — the 3rd arg false = build no objects (no eval)
```
⚠ Returning `''` instead of compiling may break a later step that expects compiled JS (e.g. `_removeHelperFunctions`);
if so, compile for real and ALSO record the source. Measure in Unit 0.

**Telling a call node in the minified 2.0.3 AST:**
```js
const isCall = (n) => Array.isArray(n.children) && n.children.join() === 'variable,args';
ast.traverseChildren(true, (n) => { if (isCall(n)) { /* n.isNew, n.args.length, n.locationData.first_line */ } });
```
An `undefined` argument: verify its shape in Unit 0 (a value node whose base is the undefined literal) — do not
guess; print the node.

**The callers test over the table:**
```js
// sites: [{ callee, reach, absentBefore: [i…], known: true }]
for (const s of sites) if (s.absentBefore.length) {
  const witness = sitesOf(s.callee).find((t) => t !== s && t.known && t.reach < s.reach);
  witness ? hole(s, witness) : value(s);
}
```

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] `check-argument-holes` reads string contents as code (`@say "use undefined, then 1"` counts as a hole),
      a reading it shares with the census parser; the code-only call parser of the tests-repo-readers D5 item
      (`archive/tests-repo-readers-plan.md`, below) would serve both. (Section "archive/every-gate-bites-plan.md",
      the masks Unit 0 found.) — CLOSED here: a real parser reads the calls, and a string's contents are never one.
- [x] **`check-argument-holes` over the tests repo's code (owner ruling D5: its own fully planned arc).** The
      gate is src-only because the hole census cannot yet tell an `undefined` VALUE from a hole. It needs two
      pieces:
  - [x] a code-only call parser that applies the conventions doc's CALLERS TEST mechanically. By that test,
        `@assertValuesEqual "…", undefined, x` and `processKeyDown key, undefined, …` are values.
  - [x] the button family's `(target, action, opts)` head moved into opts, as `SimpleRectangularButtonWdgt`
        already has it. Its tests-only target-less fixtures are holes by both of the doc's rules. About 45 sites
        plus `super` chains, both repos, pixel-neutral, one commit.

  Measurements and probe: that plan's ledger, "Owner ruling D5". (Section "archive/tests-repo-readers-plan.md".) —
  CLOSED here: both pieces landed — the code-only call parser with the callers test mechanized (an exact zero over
  both repos) and the button family's head in opts.
- [x] **Two readers of a test's macro sources.** — CLOSED 2026-11-07: ONE reader, `lib/tests-repo-code.js`
      `macroSourcesIn` — the value of `mainMacroSource` and each `extraSubroutineSources` entry, found in the parse
      (what the harness compiles), COOKED, each with its file line and its span; it refuses a source it cannot read
      statically (`${…}`, not a template literal) or whose lines do not sit on the file's. No raw-offset map: no reader
      maps a column back, and the lines are held aligned. The class was wider than filed — every Node reader of a
      macro source moved onto it: the call-sites table (its sources and its JS-shell read), unresolved-sends,
      `macroCode` (dead-methods, R4: it masked the JS-escaped text, which only happened to read right), the discipline
      gate's `macroSourcesOf` and aim-census's text-context labeller, `macro-page-lib`'s regex (it stopped at an
      escaped backtick: two visualisation pages had lost their whole step narration), the capture's whole-file
      screenshot-name scan, and layering's whole-file rule [D]; `lib/js-mask.js`'s template list, left with no reader,
      is gone. Every gate's output is byte-identical except where the cooked text differs from the escaped one
      (one aim-census snippet, seven regenerated visualisation pages).
- [x] **`Class._equivalentforSuper` rewrites `super ` inside a string literal or a comment too.** — CLOSED 2026-11-07:
      ONE super rewrite, `Class.rewriteSuperCalls` (Class's and Mixin's `_rewriteSuperCalls`, the old name's successor,
      each hand it the member its `super` means), reads which `super`s there are and what call each makes from the
      bundled compiler's lexer tokens, never from the text. The class was wider than filed: the text rules also rewrote
      the end of a name (`@_super a`, `x.super()`) and misread real calls — `return super if a` and `super⇥a` failed to
      compile, and silently: a `super` before an indented object called super's RESULT with it, `super + 1` passed `+1`
      as an argument, `"#{ super }"` dropped the arguments it forwards, and a `super` in a class nested in a member was
      bound to that member. The four-rule order and the trailing-space hazard behind the "thin vertical slice" bug
      went with the text rules. Measured over the 6691 fragments the meta-compiler compiles from every source but its
      own two: byte-identical except the comments of 8 fragments that said `super` (7 in the compiled JS); the
      pre-compiled image byte-identical; the call table differs only in Class's and Mixin's own code.
      `lib/meta-compiler-selftest.js` holds a case per reading (45; 31 mutations, all caught).
- [x] **`Class._addInstancesTracker` is a text substitution too** (found closing the `_equivalentforSuper` item, in the
      plan's ledger). It inserts
      `this.registerThisInstance?()` before every `return` that opens a line of a constructor's text, and appends a
      `return` when no line of the body opens with one. A `return` inside a nested function gets one:
      `VideoPlayerWithRecommendationsWdgt`'s manifest callback (`return if @destroyed`) re-registers a player that was
      destroyed before its manifest arrived, in every `instances` set — the corpse the door-callback law forbids (read,
      not run: the part is flag-gated and no test opens it). A mid-line `return` gets none, and an early body-level
      return with no final one leaves the fall-through unregistered (0 of each today). The appended `return` has a
      second job: it stops a constructor from returning its last expression, which `new` would hand back instead of
      the instance. And `registerThisInstance` walks the whole chain from `@constructor`, so the first constructor to
      finish (the root class's) already registers the object in every set and each later call is redundant. One
      registration per construction, in one place, and an unconditional `return` is the likely shape; it changes
      every constructor's compiled text, so it needs its own survey (the inventory audits; a constructor that never
      calls `super`). — CLOSED 2026-11-08: Widget's constructor registers each widget once, right after `super()`
      (`Widget.registerThisInstance`), the moment the root's constructor used to; the meta-system writes nothing into
      a constructor's text but a `return` (`Class.endingInReturn`, placed by the lexer: a block body at its first line's
      indentation, a one-line or empty body moved onto its own line first; a constructor that is no `->` function is
      refused, naming its class), and a class with no constructor gets the one CoffeeScript would,
      `constructor: -> super`, through the same path. Every widget constructor calls super on every path (132
      written, 157 forwarders); a suite run under a probe of every registration: before, 64,450 first registrations
      from TreeNode's constructor and 184,414 redundant ones; after, every first one from Widget's and none redundant,
      re-registered or of a destroyed widget, with the same first registrations per test (nine tests A/B against a
      HEAD build). The 6691 compiled fragments: 6126 identical, each constructor's JS its old JS with the registration
      cut (198; 4 more keep comments the injection lost, 2 that end in their own `return` emit it), 357 forwarders,
      Widget's one call, the Deserializer's two dead soaks, two corrected comments. `lib/meta-compiler-selftest.js` 72
      cases, 51 mutations all caught; `SystemTest_macroInstancesRegistry` pins the registry at run time (10 assertions,
      each seen failing under a plant).
- [x] **`Class.notifyInstancesOfSourceChange` reads a class's `instances` set as its own instances** (found closing
      the `_addInstancesTracker` item, in the plan's ledger). A widget is in the set of its class AND of every
      superclass (`Widget.registerThisInstance`), so an edit to a class's member already notifies every subclass
      instance through that class's set; the method then recurses into each subclass that does not redefine the
      member and notifies its instances again, and a subclass that DOES redefine it is notified through the parent's
      set all the same — the guard its comment states holds for the recursion only. Harmless today (`sourceChanged`
      re-lays-out and repaints an instance), read, not run; `SystemTest_macroClassSubclassesPropagation` stubs the
      recursion, so it cannot see the instance level. One walk would do: notify each instance in the class's set
      unless a class between the instance's own and this one redefines the member. — CLOSED 2026-11-08, and the
      shape filed here was wrong: an override can call super (203 of the tree's 1184 overriding members do), so a
      subclass that redefines the member can still be changed by the edit. Measured before the fix, one notification
      for `ButtonWdgt._reLayout`: a ButtonWdgt heard once, a SimpleRectangularButtonWdgt (inherits it) twice, a
      LabelButtonWdgt (overrides it) once. Now the method notifies every instance in the edited class's set once —
      exactly the instances of the class and of its subclasses — with no recursion and no member names (the
      parameter is gone from the whole family: Class, InspectorWdgt, ClassInspectorWdgt, and Mixin's three calls).
      `Class.subClasses` and `Class.superClass` lost their only reader and are gone; the prototype chain is the one
      record of the hierarchy (the smalltalk-talk plan's Hierarchy view derives subclasses from it).
      `SystemTest_macroClassSubclassesPropagation`, which pinned the registry and the recursion, is replaced by
      `SystemTest_macroClassEditNotifiesInstances` (3 counts, each seen failing under a plant: the old recursion
      re-planted, own-class-only, every widget, nobody).
- [x] **The instance inspector tells a widget of a rename or a removal twice** (found closing the
      `notifyInstancesOfSourceChange` item, in the plan's ledger). `Widget.renameOwnProperty` and `removeOwnProperty`
      call `@sourceChanged()` themselves, then `InspectorWdgt`'s rename and remove call `notifyInstancesOfSourceChange`,
      which calls the inspected widget's `sourceChanged()` again. One of the two is the edit's notification; the
      class inspector routes the same calls to its class, so which one goes needs reading both inspectors' paths. — CLOSED 2026-11-08: the edit
      makes its one notification, and the inspector's buttons never notify. Measured before the fix (told / re-laid out):
      instance add 1/1, save 1/2, rename 2/2, remove 2/2; the class inspector's plain add, save, rename and remove 1/1
      for each instance of the class (its mixin-routed edits notify inside Mixin's own methods, once per consumer).
      On a widget the edit methods notify (injectProperty and the new `addOwnProperty`, renameOwnProperty,
      removeOwnProperty): injectProperty has six callers outside the inspector that rely on it. The class inspector's raw
      steps each end in its one notification (`_notifyInstancesOfSourceChange`), since Class.applyMemberEdit leaves
      notifying to its caller; `InspectorWdgt.notifyInstancesOfSourceChange` lost its callers and is gone. The save's
      second re-layout was injectProperty evaluating through evaluateString, the run gesture, whose tail re-laid out and
      repainted before injectProperty's own notification: the evaluation is split out (`Widget._evaluateInMyScope`), and
      evaluateString ends in sourceChanged instead of a re-layout and a repaint of its own.
      `SystemTest_macroInspectorEditTellsOnce` pins both inspectors' plain add, save, rename and remove, and a run
      (evaluateString); on the tree before the fix it failed on exactly save, rename and remove. The two methods added to
      Widget show in an inspector that lists inherited members: `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly`
      scrolls such a list, and its images 2 and 3 moved by those two rows alone (with them hidden from the list it
      matched); recaptured with the owner's sign-off, mouse and finger at dpr 1 and 2.
- [x] **Hand-rolled `#` comment cutters beside `lib/coffee-mask.js`** (found closing "two readers of a test's macro
      sources", in the plan's ledger). Several gates
      cut CoffeeScript comments with their own per-line scan instead of coffee-mask, most of them at the first `#`
      even inside a string — so a `"#{…}"` interpolation or a `#` in a string hides the code after it on that line:
      `stripComment` in `check-stinks.js` (beside its string-aware twin), `check-invalidation-receivers.js` (filed
      below), `check-plane-discipline.js`, `check-relayout-bounds-first.js`; `stripLine` in
      `census-nosettle-naming.js`, `check-layering.js` and its kept-in-sync copy in `check-unresolved-sends.js`;
      layering rule [D]'s `indexOf('#')`; `lib/name-definitions.js`'s `stripComment`; and the tests repo's
      `check-macro-source-discipline.js` `stripComment` (quote-aware). One masker, measured gate by gate. — CLOSED 2026-11-08:
      one masker. `lib/coffee-mask.js` reads CoffeeScript with the CoffeeScript lexer (`CoffeeScript.tokens`, the bundled
      compiler) and gives every reader one call, `coffeeMask(text, where)`, one record per line, `{ mask, code, bare,
      comment, continuesLiteral }` (with `isCommentOnly`), each text lexed once per process; its cases are
      `lib/coffee-mask-selftest.js`. The ten filed were thirty-two: the
      naive first-`#` cut in thirteen places, `name-definitions`' `#{`-aware cut, seven quote-aware one-line scans, four
      stateful copies of `stripLine` (the census copy was live), aim-census' own lexer and four `"""` counters. All read
      the masker now, and coffee-mask's own character scan is gone with them: it misread a `#` or a quote inside a regex,
      took `///'''///` for a heredoc that never closes, and labelled interpolation code a string. Each gate's self-test
      gained a plant seen failing on the old reading, and the `lib/` readers that had no self-test (install-edges,
      settle-tiers, settling-setters) have one. What the move surfaced: `Macro.getName` was called only by
      `@getName()` inside a heredoc interpolation (call-separation [U], 115 > 114), so it is gone and the template reads
      `@_name`; `MacroToolkit._syntheticEventsConsecutiveLeftClicks_InputEvents` self-calls two public L1 primitives with
      a string first argument, which the dropped-strings reading hid ([S], two sites), sanctioned like its two sibling
      helpers; the commented-out tint line in `@PENCIL_TOOL_SOURCE` is a third colour in that tool's source text, whose
      sanction counts 3. `part-edge-scan` read a line ending in an existence test (`foo() if X?`) as unfinished, which
      had hidden that it never read `return <value> unless X?` as a bail-out; both are fixed and planted. The three
      `*-allowlist.txt` files have one reader, `lib/allowlist-file.js`. Where src's `Macro.fromString` heredoc bodies are
      found joins the four walks item.
- [x] **Four walks find a test's command files** (found closing "two readers of a test's macro sources", in the
      plan's ledger): `lib/tests-repo-code.js`'s
      `macroFiles` (every `*_automationCommands.js` under `tests/`, skipping `automation-assets/` and dot directories),
      `check-layering.js`'s `collectMacros` (every one, nothing skipped), and the discipline gate's and aim-census's
      `tests/SystemTest_*/<name>_automationCommands.js`. They agree today; the harness's own definition is the manifest
      (`tests/`'s subdirectories, `generate-tests-manifests.js`). One file set, the manifest's. Beside them, src's macro
      sources — the bodies of MacroToolkit's `Macro.fromString` heredocs — are found three ways (found closing the
      comment cutters item): `lib/call-sites.js` by parse, `check-layering.js`'s `macroVerbTexts` and `aim-census.js`'s
      `toolkitVerbs` by an opener regex and a lone closing `"""`, reading the raw lines rather than the value the
      compiler makes of them. One definition of where macro sources live, read as the text the page compiles. — CLOSED 2026-11-08: one definition of
      each. THE TESTS are `lib/tests-repo-code.js`'s `testNames`: every directory of `tests/`, each a `SystemTest_<x>`
      holding the two files the harness loads by its name (`metadataFileOf`, `commandFileOf`); a tree that breaks that
      is refused (`TESTS_DIRECTORY_MALFORMED`), never skipped, and `testNameOf` names a test from a word. The survey found
      seven restatements of the test set and seven of the command file, not four: every gate that reads the tests one
      by one (layering's [D], the discipline gate, aim-census, `check-tests-syntax`, `check-visualisations`,
      `check-hand-lists`), the manifest generator, and the name checks of the runners, the capture tools, `check-refs`,
      `recapture`, `reset-test-refs` and the churn set all read it now. Layering, the discipline gate, aim-census and the
      syntax and visualisation gates each plant a malformed tree, seen read past by the old walk. `planted-src`'s reset removes the directories a plant made. THE MACRO SOURCES are
      `lib/macro-sources.js`: `testMacroSourcesIn` (moved from `tests-repo-code`) and `verbMacroSourcesIn`, every
      `Macro.fromString` string literal of a CoffeeScript file, read off the lexer's tokens (so a file only the
      fragment compiler parses, as with a bare `super`, reads), cooked, each line on its file line, where `call-sites`
      had lifted them from its parse. Layering's [D] reads
      every src file's verbs, not MacroToolkit's alone; aim-census reads its verb table from it; and the two gates that
      read test macro sources but no verb now read both: unresolved-sends checks the verbs' 10 calls, and the discipline
      gate holds the 15 verbs to its three rules. Each reader's self-test plants a verb its old reading missed (a `'''`
      heredoc, a verb in another file, an escape that keeps its lines). That every build tool walks src itself is
      filed beside the item.

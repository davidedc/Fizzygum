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
- [x] **A mixin's static edit does not reach a consumer's subclasses** (found closing "two readers of a test's macro
      sources", in the plan's ledger).
      `Mixin.applyStaticEdit` writes the new static onto each consumer class, but `extend` copied a class's statics
      onto each subclass when the subclass was defined (`globalFunctions.coffee`'s `extend`), so a subclass keeps the
      old value while its instances are notified. No mixin declares a static today. — CLOSED 2026-11-08 by
      retirement: nothing could make the edit. No mixin declares a class-side key besides its
      `onceAddedClassProperties` hook, so the static parse always came up empty; and no static was ever SAVED: the
      class inspector lists a class's PROTOTYPE members (`for property of @inspectedObject`) while every static lives
      on a constructor, and an object inspector opened on a constructor itself (a `constructor` row's double-click)
      lists its statics read-only, its subject's own constructor being `Function`. No test or rig reached the leg. The
      class-side machinery the
      mixin-editing v2 plan's P4 added is deleted: Mixin's 2-space static parse and its `staticPropertiesSources`,
      `Mixin.applyStaticEdit`, `InspectorWdgt._mixinProvidingStaticMember`, `currentPropertySourceIsStatic` with every
      branch on it in `ClassInspectorWdgt`, `recordMixinEdit`'s `isStatic` and the registry's `static: true` replay;
      the build shim's `MixedClassKeywords` stand-in went with the parse that read it. Beside it,
      `selectionFromList`'s "static variables" branch is gone: for a non-function member whose value is undefined it
      showed the same-named property of the subject's CONSTRUCTOR, so an inspected plain object's undefined `name`
      read `"Object"` and its `length` read `1`. `SystemTest_macroInspectorShowsAnUndefinedFieldAsUndefined` plants
      that, failing on the old code. Measured first: no class's field shares a name with a static of its class (550
      classes, 14,508 undefined prototype fields), so no reference changed. `mixins.md` states that statics are outside
      the inspector's editing, and that an edit to one would have to reach every subclass, since `extend` gives each
      subclass its own copy.
- [x] **`Deserializer.compileFunction` compiles through the run gesture** (found closing the instance inspector's
      double notification, in the plan's ledger). A `{"$src"}` the load cannot hand to its widget's `injectProperty`
      (one nested in an array or a map, or one on a non-widget) is compiled by `world.evaluateString`, which ends in
      the world's `sourceChanged`: by reading, a repaint of the whole world per such function (the world's own
      re-layout is a no-op), not measured. Compiling a function source needs no widget at all. Measure how often a
      load takes this path first. — CLOSED 2026-11-08 by
      retirement: no load takes the path. Measured with a plant that fails any run reaching it (proven on hand-built
      envelopes): the dpr-1 suite, both serialization rigs and the parts snapshot rig reach it from no load, the one
      hit being a test calling it directly. No gesture's save writes such a `{"$src"}`: the Serializer encodes array,
      map and set items with no owner, so a function there fails the save, and no writer of a `<name>_source`
      (`injectProperty` and the rename, on a widget; `Class.applyMemberEdit`, on a prototype) reaches a non-widget.
      Only code a person runs could plant one (a plain object holding `f` and `f_source`, which the old save wrote
      through the chain read below); the save now refuses it as a function without its own source.
      `Deserializer.compileFunction` and both its call sites are deleted, so a `{"$src"}` has one meaning, a
      widget's injected method, compiled with that widget's `injectProperty`. A file holding one anywhere else is
      refused before anything is built or torn down: one in a tag record by `_envelopeShapeProblem`, one on
      a record of a class that cannot inject a method by `_functionSourceOnANonWidget`, which the world loader asks
      through `whyItCanNeverBeRestored` (again on its re-entry with a lazy part's classes resident) and
      `deserialize` asks before pass 1. The save's half matches: `encodeFunction` writes a `{"$src"}` only for an
      OWN `<name>_source` string on an owner whose class takes injected methods (`Serializer.classTakesInjectedMethods`,
      the load's own test), so a class edit's, on the prototype, is never written as an instance's. The
      serialization rig plants all three (`world.loadGuard.strayFunctionSourceRefused`,
      `widgetFileStrayFunctionSourceRefused`, `serialize2.functionSourceMustBeOwn`), each seen failing on the old
      code; `SystemTest_macroEvaluateStringReturnsItsValue` drops its `compileFunction` assertions. Filed beside it:
      a world snapshot cannot be saved while a class inspector is open.
- [x] **A plain class-member rename or removal does not survive a snapshot load** (found closing the same item, and
      stated in `ClassInspectorWdgt` at its raw steps). `_applyPropertyRemoval` / `_applyPropertyRename` delete and
      re-key the prototype member: a `<name>_source` live override stays behind under the old name, and the edit is
      not recorded in the `SourceEditsRegistry`, so a loaded world replays the class edits without it (the mixin path
      records its removal, `recordMixinMemberRemoval`). By reading: a leftover `<name>_source` is also what the shadow
      guards of `Mixin.applyMemberEdit` and `Mixin.removeMember` key off, so a removed override still blocks the
      mixin's edits and removals of that member. — CLOSED 2026-11-08. Every clause was measured true first, and more
      beside it: a renamed member lost its CoffeeScript and its `super` kept calling the old name, a removed override
      left the member undefined instead of giving back the mixin's, a class add was not recorded, and a donated
      member's rename re-keyed one consumer. Each meta-object now keeps the CURRENT source of every member it defines
      in `nonStaticPropertiesSources`, a `Class` as a `Mixin` already did: an edit writes it, `Class.removeMember`
      deletes it. So the prototype `<name>_source` retires (it means only a widget's own injected method), and a
      consumer's prototype holds its class's member, else its donor mixin's, else nothing: the live members are a
      function of the two stores, which the load's two-pass replay reproduces. A rename is an edit under the new name
      plus a removal of the old, recompiled so `super` follows the name (a member with no recorded source is refused);
      a removal gives back the donor's CURRENT member (`Mixin.injectCurrentMemberInto`); a donated member's rename goes
      to the donor; Mixin's two shadow guards are one (`_consumerDefinesItself`); a class removal is recorded
      (`recordClassMemberRemoval`, `deleted: true`) and replayed, and an add is an edit to "undefined".
      `ClassInspectorWdgt` has one step per scope and operation, each the meta-object's edit and its record, and each
      gesture notifies once (Class and Mixin notify no one; Mixin's edits answer the consumer classes they updated).
      Folded from the survey: F1, both meta-objects refuse `constructor` (`Class.refuseTheConstructor`) and both
      inspectors show its code read-only; F2, Rename and Remove are offered, and act, only for a member the
      inspector's subject OWNS (`InspectorWdgt._selectedMemberCanBeRenamedOrRemoved`: on a StringWdgt, 243 of 253
      default rows offered a Rename that left the world unsavable); F3, KeepsRatioWhenInVerticalStackMixin and
      BubblesEditModeToCoordinatorMixin re-indented to 6-space keys (8 members had no recorded source), and the boot
      reports any such member (`MIXIN_MEMBER_UNRECORDED`, a gate token); F4, a member's companions
      (`<m>_class_injected_in`, an injected method's `<m>_source`) are not listed. Plants, each seen failing on the
      old code: six serialization-rig checks (`sourceEdits.classRenameReplayed`, `classRenameRecompiles`,
      `classRemovalReplayed`, `classAddReplayed`, `removedOverrideRestoresDonor`, `donatedRenameRoutesToDonor`),
      `SystemTest_macroInspectorEditTellsOnce` without its hand cleanup (its own prototype assertion), the tripwire
      before the re-indent (8 lines), and the new `SystemTest_macroInspectorOffersOnlyWhatItsSubjectOwns` (6 of 8).
      16 inspector tests recaptured on the owner's approval, mouse and finger at dpr 1 and 2: Rename and Remove greyed
      on rows the subject does not own, and no companion rows. The independent review found that two mixins of one
      class can define the same member (`_updateColor`, from HighlightableMixin and ParentStainerMixin, on three
      classes), whose boot winner is the LAST: `Mixin.donorOf` now answers the last augmentation that defines a
      member, every mixin edit reaches only the consumers it donates to (`_isTheDonorTo`), and a mixin removal hands
      each such consumer the earlier donor's member, else none; a removal compiles what it falls back to before it
      changes anything; and Add… and Rename… refuse `constructor` as a new name. Planted first, each failing on the
      code before it: `sourceEdits.removedOverrideRestoresTheWinningDonor`, `sourceEdits.removalIsAllOrNothing`, and
      four constructor-as-a-name assertions in the new test. Filed beside it: a snapshot load never undoes the page's
      own earlier class edits; an object inspector opened on a class's prototype edits the class unrecorded; mixin
      editing holds only where the page compiled its mixins.
- [x] **`run-sequence-selftest-headless.js`'s "page stopping answering" case is load-sensitive** (seen closing the same
      item: the gauntlet's `selftests` leg failed in the parallel wave on 2026-11-08 and passed its serial retry). Under
      load the planted unresponsive page can run out the sequence's completion wait before the runner sees the page
      stop answering, so the run still reads INVALID (exit 2) but prints "the sequence did not finish within …" instead
      of the "page stopped answering" line the case requires. Make the case's two conditions unable to race. — CLOSED
      2026-11-09. The race was the case's, not the runner's: both lines are true readings, and the plant (the second
      test's cycle looping) fired about 1.8 s into a 5 s wall-clock window. CPU load barely moved it, while two levers
      printed the in-wave line exactly: `--complete-secs=1`, and the first test's cycles slowed by 200 ms each. The
      stuck plant now sticks in the very call that starts the sequence (`AutomatorPlayer.prototype.runAllSystemTests`),
      before the run's in-page completion wait has started its clock, at `--complete-secs=1`. That wait cannot end
      first at any load or window: under both levers it reads "stopped answering", and the case takes 8.5 s instead of
      12.7 s. Planted, it fails against a runner without the play phase's bound (the protocol timeout, never the line).
      The frozen plant freezes the first test, TEST, not the second. Folded: the suite-gate selftest's abandon case
      had the same shape. Its page hung 1.5 s into a 3 s stall window, and at `--test-stall-secs=1` the STALLED line lost
      "— the page stopped answering". Its page now stops answering right after the runner's first poll (scheduled
      from that poll's read of `Automator.prototype.collectedFailureImages`), so the look that closes the window is
      always unanswered: Chrome and WebKit, at 3 s and at 1 s. Folded too: every `PLANT_NOT_APPLIED` is said with
      console.error, and `lib/gate-bite-proof.js`'s header states why. Every runner and rig prints a page's error
      lines, and none prints a log line that does not read as a failure (measured through the sequence, suite and
      single runners and both sweeps). So ten console.log lines, in seven files, never reached the judge's "every
      plant applies", the check three `hand-list-sanctioned:` comments cite. Planted with a give-up its run reaches, a
      plant whose class never appears now fails that check by name. The independent review found that the frozen plant
      had lost its guard on the test-name query (a missing method would have thrown in every cycle and read as a
      freeze); the guard is back. It also found that the plants polling for classes give up only after 60–100 s, when
      their runs have closed the page. Filed beside it: the three suite runners wait for a page to boot three ways; a
      plant's give-up comes after its run has ended.
- [x] **Every build tool walks src for itself** (found closing the four walks item, in the plan's ledger). About
      forty build tools each list src's `.coffee` files with a walk of their own (`collectCoffee`, `walkFiles`, a local
      `walk`, `lib/macro-sources.js`'s `verbMacroSources`, …), with different skip rules: some pass over dot directories
      and `node_modules`, some pass over nothing, and some also read the harness. A file one walk skips is read by the
      others, and nothing says which set a gate read. One definition of src's files, as `lib/tests-repo-code.js`'s
      `testNames` is of the tests. — CLOSED
      2026-11-09. Measured first: about 45 walk definitions all read the same 561 src files, so the skip-rule split
      was latent (only symlinks were live: a symlinked directory was read, shipped and seen by nothing); the live split
      was the ROOT — 21 tools read src without the harness the build compiles beside it, and 7 of them fired on it.
      ONE definition, `buildSystem/lib/source-files.js`: `coffeeFilesIn(root)` (every `.coffee` file, a dot directory's
      and a `node_modules`' included, code-point order; a symlink anywhere, a missing root and an empty one REFUSED,
      `SOURCE_TREE_MALFORMED`), `srcFiles`, `harnessFiles`, `compiledFiles` (src and the harness), the two rails
      `--src=` / `--tests-repo=` (`sourceRoots`) and the printed names (`sourceName`: `harness/<rel>`). Every gate and
      census reads `compiledFiles`, and so do `testsRepoFiles`' harness, aim-census, the gate-tokens self-test and
      `assert-build-fresh` (`newestSource`, which torture and the single runner call; `fswalk.newestFile` deleted);
      `fg status` counts the harness. The coverage gate's full set is `compiledFiles` (`build.py --list-shippable` takes
      `--tests-repo=` too): planted, a dot directory, a dot file and a new harness subdirectory each fail as UNSHIPPED.
      `lib/planted-src.js` copies the tests repo's code (`testsRepo: true`: its harness, each test's two files and the
      scripts `lib/what-runs.js` reads; a plant keyed `harness/<rel>` lands in its harness; the copy is named
      `Fizzygum-tests`, so hand-lists' run set, now the rail's, finds its scripts by the paths the build names them by),
      and each gate reading the compiled sources (the syntax gate, aim-census and the macro-source discipline gate among
      them, each given `--tests-repo=`) plants one harness violation in its proof, each seen failing. The harness meets
      src's rules: the retired `»>>` markers (four pairs) and the four "Ex-`»>>`" headers, the two whole-file markers,
      seven empty first-line comments, a `debugger`, twelve commented-out debug lines and nine narrating comments are
      gone; `Automator.fade` reads the clock itself (its 26 callers, 6 in src, passed it: wall-clock 19 -> 13), and the
      harness's four real-time clocks, two DOM colours, three DOM `onload = null`s and one `SerializationError` catch
      are sanctioned by name; the paint audit carries three `cross-invalidation-sanctioned:` markers and layering [B]
      names it in `RECALC_ORACLES` (held stale, `B_STALE_RECALC_ORACLE`), the overlay's images `page-element-not-held:`;
      the reset seat `_beforeWorldDissolveNoSettle` is `_beforeBeingDissolved` (rule [L]); dead-methods inventories the
      harness, so `EventCommand.execute` and `addToZipAsJS` are deleted and `loadAndRunSingleTestFromName`, the console
      entry point, is allowlisted; call-separation's [U] counts a harness class's own `@` calls as self, so 17 harness
      methods and `WorldWdgt.invalidateCanvasPositionCache` (self-only once the harness's installed calls count as self)
      are `_`-tier, and two whose `_`-form [S] forbids are allowlisted. The independent review found [U] blind to the
      harness (it read it twice, once as external), the syntax gate handing build.py the `--tests-repo=` copy and
      reading the real harness, aim-census and the freshness guard refusing with exit 1, aim-census and the discipline
      gate without the harness's rail, [B]'s oracle entry held by nothing, call-arguments' half-read INVALID left
      unreached, the null and instanceof ratchets raised where the plan named sanctions, and the copy missing the
      tests repo's shell scripts; each is fixed as above. Folded: the orphan
      `combine-all-coffee-sources.sh` deleted. Filed beside it: the boot files are a hand-list in the build script; every
      gate re-masks all of the compiled sources; `find_similar_code.sh` stops at its mirror; build freshness reads only
      the sources' mtimes; every tool walks the tooling's own files for itself; the wall-clock stink does not see `new
      Date` without parentheses.
- [x] **A world snapshot cannot be saved while a class inspector is open** (found closing "`Deserializer.compileFunction`
      compiles through the run gesture", in the plan's ledger). A `ClassInspectorWdgt`'s subject is a class
      PROTOTYPE, and the save writes it as a record of all its own members, so it meets the prototype's methods and
      refuses: measured, `SerializationError: the function-valued property .constructor has no editable source`.
      The refusal is loud, and it costs the user the whole snapshot. One direction to measure: a prototype belongs
      to a class, not to the world, so a file could carry the class it names rather than its members. — CLOSED
      2026-11-09. Measured first, the fact was wider than the filing:
      - a CLOSED class inspector rests in the bin, a snapshot root, so the save stayed refused until the bin was
        emptied;
      - an object inspector on a class function (its `constructor` row) or on a prototype (its `__super__` row)
        refused alike;
      - "Save to file…" of a class inspector's window refused naming a widget that does not exist ("RectangleWdgt#0":
        a prototype answers `uniqueIDString`);
      - a class inspector on a `WindowedApp` subclass SAVED, and loaded onto the app's singleton instance, because the
        prototype answered its `app:` key through the inherited `wellKnownKey` method;
      - ANY inspector with a member selected refused, through three fields holding what no file can carry:
        `TextWdgt.overridingContextMenu` (`setReceiver` stored the method `evaluationMenu` in it),
        `InspectorWdgt.currentProperty` (the selected value, read nowhere) and `currentPropertySourceMixin` (the donor
        Mixin object; found by the new check's first run).
      What landed:
      - A class and its own prototype belong to the page, and a file names them by their class: `{"$wk":
        "class:<Name>"}` / `"prototype:<Name>"`. `WellKnownObjects.classKeyFor` answers them, asked first by the
        Serializer's `refFor` and by `keyFor`, before the singleton table and the marker; boot's `isAClassPrototype`
        sits beside `classNamed`. The load binds the key through `classNamed` in the loading page.
      - A key naming a class the page cannot provide is refused: `WellKnownObjects.resolve` throws, and
        `Deserializer.whyItCanNeverBeRestored` reads the key names (`Serializer.classKeyNamesIn`) as it reads record
        classes, before the teardown. `classNamesIn` hands the names to the lazy-part pre-load.
      - The Duplicator shares a class's prototype by the same predicate. A non-widget one used to be copied into an
        object posing as its prototype (measured on `SourceEditsRegistry`'s).
      - `currentProperty` is deleted. A text with a receiver answers its evaluation menu as `overridingContextMenu()`,
        a `?`-dispatched capability; Widget's field and its unresolved-sends allowlist entry go. The inspector holds
        its donor mixin's NAME (`currentPropertySourceMixinName`, resolved by `Mixin.named`).
      - A restored viewport lays itself out again at the next settle (`ViewportWdgt._afterDeserialization`; the
        two toolbars' hooks now call `super`). The new check found this: `SliderWdgt.indicatorMode` is
        transient, and nothing arranged a settled restore, so every restored viewport whose bars showed wore
        them in the plain slider's look (a hollow thumb) until its next arrange.
      - The long tail (a plain function, `window`, a DOM element, a Promise or a Mixin as a subject) stays a loud
        refusal.
      The proof is the serialization rig's `world.inspector.classSubjectsSurviveSnapshot`. It saves and loads a
      desktop holding:
      - a class inspector with a mixin-donated method selected, and an object inspector with that method selected;
      - one on the class function, and one on its `__super__`;
      - a `SpreadsheetApp` class inspector closed into the bin.
      It requires the same pixels, every subject the page's own, and the restored class inspector still editing. It
      was seen failing on its first two runs (the donor Mixin, then the hollow thumbs) and under three plants: no class
      keys; `setReceiver` keeping a function field; the marker answered before the class key.
      One test's pixels move: `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly` (images 2 and 3) lists
      inherited members, and Widget's `overridingContextMenu` row is gone. This was proven by a plant restoring exactly
      that field, under which the test passes on the old references. It was recaptured (mouse and finger, dpr 1 and
      2) with the owner's approval.
      The independent review found:
      - the check's row-click fact passed whatever the click did (the restored pane already held the text), and its
        donated member was chosen by key order: it now re-filters to an empty pane, names the donated member, and
        reads the donor attribution back before any click;
      - the refusal side was unchecked: `world.loadGuard.classKeyNotAClassRefused` (the world door, desktop kept) and
        `world.loadGuard.widgetFileClassKeyIsALoadError` (one load inform) now hold it, each seen failing under a
        plant (the refusal reading no class keys; an absent class key resolving to undefined);
      - a restored donor name the page cannot resolve would have routed an edit silently to the class: it throws,
        naming the mixin;
      - a key with no name after its prefix counted as a class key: it is none;
      - comments claimed the inspector's code pane shows the evaluation menu, which it never does (filed).
      Filed beside it: a value answering `rebuildDerivedValue` is dropped from a save, and breaks a copy, wherever it
      stands; the menu sweep builds its class inspector on an instance; the widget-file door never loads the lazy part a
      file needs; a restored inspector does not wait for the reflective layer; the evaluation menu is unreachable in an
      inspector's code pane.
- [x] **The widget-file door never loads the lazy part a file needs** (found closing the same item; measured).
      - A `FridgeMagnetsWdgt` file saved on the harness page and opened on `index.html` is refused with "it references
        the class 'FridgeMagnetsWdgt', which does not exist in this build", and the part is never fetched. The message
        is false: the build has the class, lazily.
      - `WorldWdgt.loadWorldSnapshot` first asks `parts.partsNeededFor Serializer.classNamesIn envelope`.
        `FileLoading.loadEnvelopeString`'s `widget` branch goes straight to `Deserializer.deserialize`. — CLOSED
      2026-11-09. Measured on the dev `index.html` (where parts are lazy) and on a `sources: "lazy"` tree, the fact was
      wider than the filing:
      - every widget file naming a lazy class was refused with that false message, so no inspector file could be
        opened on `index.html` or on `homepage`, where `meta-tools` is lazy;
      - an eager launcher's `app:` key loaded silently dead at the widget door, and its first click threw; a key
        naming an app no part provides loaded dead at BOTH doors (the world-inventory filing below, folded);
      - the refusal and the pre-load read two lists of the classes a file needs, which differed by exactly the app
        keys;
      - a world file whose part failed to load gave no message and an unhandled rejection, and `loadEnvelopeString`
        answered nothing a caller could await.
      What changes:
      - `Deserializer.classNamesIn` is the ONE list (record classes that are no tag, app keys, class keys; it
        replaces `Serializer.classNamesIn` and `classKeyNamesIn`), read by the refusal and by the pre-load.
      - A key that names a class must resolve: `WellKnownObjects.resolveApp` throws as `resolve` does for a class
        key, and `Deserializer.whyItCanNeverBeRestored` refuses such a file at either door before anything is built.
        An `app:` key with no name after its prefix is no key.
      - `Deserializer.loadWhatItNeeds` is the one step both doors take before anything changes: the missing lazy
        parts, then the reflective layer (`_needsTheReflectiveLayer`), one per trip, re-entering after each. A
        failure is a load `SerializationError` naming what did not arrive.
      - The widget door (`FileLoading._loadWidgetEnvelope`) takes the world door's guards before its first shell.
        `_reportingSerializationErrors` reports a returned promise's rejection as it reports a throw, and
        `loadEnvelopeString` returns the promise. This settles the "failed async door" owner decision for the two
        FILE doors (the decision stays open for the others).
      - One message for a class the page lacks, `SerializationError.forMissingClass`, in the refusal's words: "it
        uses X, which this page has not loaded" when a part of this build provides it, "…which this build does not
        have" otherwise.
      The proof:
      - `parts-snapshot-load-headless.js` (the `parts` leg, on `index.html`) gains `WIDGET_FILE_LOADS_ITS_PARTS`,
        `WIDGET_FILE_REFUSED_UP_FRONT` and `FILE_DOOR_REPORTS_A_FAILED_PART`, each seen failing alone under its plant
        in `parts-snapshot-load-selftest-headless.js` (the old widget door, no up-front refusal, a reporter of the
        synchronous half only);
      - the serialization rig's `world.loadGuard.appKeyNotAClassRefused` (the world door, desktop kept) and
        `widgetFileAppKeyIsALoadError` (one inform, and the net throwing) replace `appKeyNotAClassUnresolved`, each
        seen failing under a one-off plant (the refusal blind to app keys; `resolveApp` answering undefined);
      - the boot smoke (`fg homepage`) restores a class inspector from both kinds of file on a `sources: "lazy"`
        tree and requires its member's CoffeeScript, seen failing under a plant (no restore waiting for the layer).
      The independent review found (all fixed):
      - the one list had dropped names by their spelling (`$`-prefixed, empty), so the world door's refusal let a
        `{"class": "$Nope"}` record or a `"prototype:$Array"` key through to throw after the teardown. The list
        moved to `Deserializer.classNamesIn`, beside the tag table, and leaves out exactly the records the table
        builds and nothing by spelling; an empty record class is a malformed table. The serialization rig's
        `world.loadGuard.tagLikeNameRefused` and the empty-class corruption of `malformedEnvelopeRefused` hold it,
        each seen failing under a one-off plant (the `$` filter; the shape accepting an empty class);
      - the parts rig's absent-`app:`-key case passed with no refusal at all (the net threw the same words): each
        absent case now stands beside a class of a lazy part of its own, so a refusal that lets it through fetches;
      - every rejection of a part's load became a message, a bug while loading included: only a file that did not
        arrive (a string rejection, `loadJSFilePromise`'s) is the load failing, and anything else stays a rejection
        (the parts rig's third (E) case);
      - the boot smoke's fresh pages waited only for the world, which a precompiled tree builds before the file
        defining `compileFGCode` arrives: they wait for the boot to finish;
      - the layer predicate read every name for the declaration, keys included: it reads the records' classes;
      - one wording for a class the page lacks (the refusal's), one reader of an app key's name
        (`WellKnownObjects.appNameInAppKey`), and `Deserializer.resolveWellKnown`, a pass-through, inlined;
      - stale comments and docs (`PartsRegistry`, `SourceEditsRegistry.canReplaySourceEdits`, the explainer, an
        active plan).
      Filed beside it: a widget file runs the code it carries at load, with no confirm; an `app:` key naming a class
      that is no app is `new`-ed during a restore; the reflective layer reads as absent until the boot's tail has run.
- [x] **A restored inspector does not wait for the reflective layer** (found closing the same item; by reading).
      `Widget.spawnInspector` awaits the reflective layer for any inspector, because an inspector reads the class member
      maps. `loadWorldSnapshot` asks for the layer only when the file carries class or mixin edits
      (`_snapshotNeedsTheReflectiveLayer`). So on a `sources: "lazy"` build, a snapshot restores an inspector before
      its member maps exist. On such a build, a restored class inspector with a mixin-donated member selected
      resolves its donor by name (`InspectorWdgt._currentPropertySourceMixin`) through a `Mixin` that is not there
      yet. — CLOSED
      2026-11-09 with "The widget-file door never loads the lazy part a file needs" (above), folded as one question:
      what must be resident before a file is restored. MEASURED there on a `dev-precompiled` tree: a class inspector
      on a CORE class, restored from either kind of file before the layer, showed compiled JS for its selected
      member (a lazy part's class has its maps: its part load runs `new Class`). `InspectorWdgt` declares
      `readsClassMemberMaps`, and `Deserializer._needsTheReflectiveLayer` (replacing
      `WorldWdgt._snapshotNeedsTheReflectiveLayer`) asks for the layer for a file holding such a widget, at both
      doors. It asks whether the layer has LOADED rather than whether the meta-system is here: a lazy part's load
      brings `Class` and `Mixin` in on their own, so the old test (`Mixin?`) skipped the layer for a file whose
      parts had loaded first (by reading).
- [x] **An `app:` well-known key naming a class no build part provides restores a launcher with no target, silently** (found 2026-10-23, code-read only; the default desktop snapshot carries no `app:` keys): `WellKnownObjects.resolveApp` answers undefined and the load goes on. Owner's call whether such a launcher should be dropped, kept dead, or the file refused like an unbuildable record class. — CLOSED 2026-11-09 by
      "The widget-file door never loads the lazy part a file needs" (above, in this ledger). Measured: such a launcher
      loads with no target, and its first click throws. A key that names a class must resolve, so such a file is
      refused at either door before anything is built (`appKeyNotAClassRefused`, `widgetFileAppKeyIsALoadError`).
- [x] **An object inspector opened on a class's prototype edits the class unrecorded** (found by the independent
      review closing "A plain class-member rename or removal does not survive a snapshot load", in the plan's ledger;
      by reading, not measured). Double-clicking an object inspector's `constructor` row opens a read-only inspector
      on the class function, whose `__super__` row opens an OBJECT inspector on the superclass's prototype. That one
      is editable (a prototype inherits `injectProperty`), so its Save writes `<name>_source` onto the prototype and
      records an "instance" edit no load replays, and its Add, Rename and Remove change the prototype with no
      record, leaving the class's store of member sources stale. A prototype's edits belong to its class's
      inspector: such a subject could open read-only, or open the class inspector instead.
      — CLOSED 2026-11-09. MEASURED wider than filed (survey: `Fizzygum-tests/.scratch/prototype-inspector-edits/`):
      TWO doors handed an object inspector a class's prototype, the row double-click and `Widget.spawnInspector`
      (Inspect selection, any class); its Save, Add, Rename and Remove changed the class with a stale member store, a
      never-replayed `instance` record, and nothing on a fresh-page load; `sourceChanged` stamped widget-lifecycle
      fields onto the prototype (a new instance's `root()` answered the prototype); its `<m>_source` companion
      outranked the class's store in every inspector after; its title threw on five classes. One query,
      `InspectorWdgt.inspectorClassFor`, now picks the inspector a value calls for at both doors (a class's prototype
      gets its class inspector, and a class inspector's `constructor` row an object inspector); each inspector's
      `_subjectIsEditable` states its scope (an object inspector never a class's prototype; a class inspector the
      prototype of ANY Fizzygum class); `Utils.colloquialNameOf` names a class's prototype from its class. Owner
      ruling the same day: value classes are editable live, so the class inspector edits Point, Color, appearances…,
      and such an edit tells every widget once: `Class.widgetsAnEditCanChange` answers by class relation, and
      `Class.notifyWidgetsOfAnEditTo` tells the union of a gesture's classes once (it replaced
      `notifyInstancesOfSourceChange`). Read-only holds at the edit gestures too (save, add, rename, remove ask
      `_subjectIsEditable`), since a restored inspector keeps the buttons its file holds. Proven by
      `SystemTest_macroInspectorOpensAClassInItsClassInspector` (assertion-only) and a new union case in
      `SystemTest_macroClassEditNotifiesInstances`: eleven plants, each failing its own assertion and `world.inspector.classSubjectsSurviveSnapshot`'s new fact. "The menu sweep builds its class inspector on an instance" folded (below); the class
      inspector's code-pane receiver added to "The evaluation menu is unreachable in an inspector's code pane".
- [x] **The menu sweep builds its class inspector on an instance** (found closing the same item; by reading).
      `menu-click-sweep-headless.js`'s `ClassInspectorWdgt` root is `new Klass(t)` on a RectangleWdgt instance, while
      the product builds one only on a class's prototype. On a prototype, the sweep's driven Add… and Rename… OKs would
      edit a real class in the middle of the sweep, so the root wants a class of its own to edit.
      — CLOSED 2026-11-09, folded into "An object inspector opened on a class's prototype edits the class unrecorded"
      (above): a class inspector on an instance is read-only there, so the root had to change. MEASURED: the old root's
      Add… OK already added `property` to the RectangleWdgt CLASS mid-sweep. The root and its button fixture now
      inspect the prototype of `MenuSweepOwnWdgt`, a class the sweep makes in the page with the meta-system
      (`new Class source, false, true`), so its OKs edit no class the sweep uses.
- [x] **The evaluation menu is unreachable in an inspector's code pane** (found by the independent review closing the
      same item; by reading). The inspector arms its code pane's text with a receiver (`TextWdgt.setReceiver`), and a
      text with a receiver answers its evaluation menu ("Do all", "Inspect selection", …) as its
      `overridingContextMenu`. But that text sits inside a `TextAreaWdgt`, which takes over its children's menus
      (`takesOverAndMergesChildrensMenus`), so a right-click asks the `TextAreaWdgt`, which answers no such menu, and
      the generic menu shows. The macro tests of the evaluation menu build a standalone `TextWdgt` for this reason
      (MACRO-PATTERNS.md, "Evaluation menu reflects text selection").
      Once it is reachable, a CLASS inspector's pane runs against the class's PROTOTYPE (its receiver,
      `codePaneRunsAgainstItsSubject` in the serialization rig): its run gestures would call `Widget.evaluateString` on
      the prototype, whose `sourceChanged` stamps widget-lifecycle fields onto it (measured closing "An object inspector
      opened on a class's prototype edits the class unrecorded": a new instance's `root()` then answers the prototype),
      and any `@x = …` typed there edits the class unrecorded. A value class's prototype (Point, Color: their class
      inspector edits them) has no `evaluateString` at all, so each run gesture there would throw; and a read-only
      object inspector holding a prototype (built by code, or from a file) has the same receiver. The fix must choose
      that pane's receiver.
      — CLOSED 2026-11-09. MEASURED wider than filed (survey: `Fizzygum-tests/.scratch/inspector-code-pane-menu/`): no
      press — a right-click or a finger hold, on an object inspector on a widget, 42 or a Point, a class inspector on a
      widget class or on Point, or an object inspector holding a prototype — opened the evaluation menu, since
      `Widget.buildContextMenu` asked the TAKER, and its one product setter was the inspector's pane, so the menu was
      reachable by nothing. The pane's one reachable run row, "Run contents" (the area's merged menu, under dev mode's
      hierarchy menu), ran the pane against its receiver: on 42, a Point or `Point.prototype` it threw to the Error log; in
      a class inspector it stamped widget-lifecycle fields onto the prototype, unrecorded. Four run families disagreed on
      `@` (a text with no receiver ran against ITSELF; a script window's "Try it" against the world; a console through
      its own evaluator). Rulings (owner: "proceed with your recommendations"): a text's run rows ("Run selection", "Show
      selection", "Inspect selection" while something is selected, "Run contents") live among its own rows
      (`TextWdgt._addTextMenuEntries`), and the overriding menu, `evaluationMenu`, the `receiver` field, `setReceiver`,
      `doAll`, `doSelection`, `doContents`, `selectAllAndEdit` and `buildContextMenu`'s hook are deleted; what they run
      against is a QUERY of the text's place (`TextWdgt._codeReceiver`: the nearest container defining `codeReceiver`
      answers — `WorldWdgt` itself, `ConsoleWdgt` its target, `InspectorWdgt` its subject while it edits it,
      `ClassInspectorWdgt` nothing); a console's and a script window's buttons dispatch their text's own run verbs
      (`ConsoleWdgt.addRunMenuEntriesForText`, `ScriptWdgt.tryIt` and the console's dead `functionFromCompiledCode`
      field are gone). A selection runs as selected, its indentation included; a run leaves the text's editing as it finds it; a run whose text no longer stands where a receiver is named says so. A run is no source edit (`Widget.evaluateString`'s header). Proven by
      `SystemTest_macroTextRunRowsReflectSelection` and `SystemTest_macroInspectorCodePaneRunsAgainstItsSubject` (mouse
      and finger), which replace `SystemTest_macroEvaluationMenuReflectsTextSelection` and the retired
      `SystemTest_macroEmptyStringDoesntGiveSelectAllOption`; the menu sweep's console root and three code-pane roots (an object inspector on a widget and on a Point, a class inspector); and
      `world.inspector.classSubjectsSurviveSnapshot`'s rewritten `codePaneRunsAgainstItsSubject` and new
      `classCodePaneRunsNothing` — each failed by its own plant. Filed: "A run that sets a widget field to a function
      blocks every world snapshot".
- [x] **A class edit refreshes only what a repaint shows** (found by the independent review closing "An object
      inspector opened on a class's prototype edits the class unrecorded", in the plan's ledger; by reading). A class
      inspector's edit tells each widget it can have changed through `Widget.sourceChanged`: the widget's own
      `_reLayoutSelf` hook (empty on most classes), a repaint, and the editor's style note. It neither invalidates a
      layout nor flushes a cache built from the edited code (`world.cacheForImmutableBackBuffers`, a text's measured
      lines). So an edit that changes geometry or cached text — of a widget class, and now of a value class, an
      appearance or a layout spec, whose edit tells every widget — shows only once something else invalidates it.
      — CLOSED 2026-11-09. MEASURED wider than filed (survey: `Fizzygum-tests/.scratch/class-edit-refresh/`): a geometry
      edit (a widget method, a field default, a Remove, a layout-spec field, a run) never showed until something else
      re-laid the widget; a cached paint or measured-lines edit stayed stale even after a resize BACK (the caches are
      keyed by content, so the old key returned); a world census of 835 widgets left 767 stale after one
      `FrameWdgt._titlebarHeight` edit; a warm page's snapshot load restored the OLD code's pixels (a load keeps its
      world and its caches); an instance's own `_drawTextLine` took its twin's buffer, then painted the twin after any
      flush; and the instance verbs were also product plumbing (a patch node's `evaluateString` on every recompute,
      `ImageWdgt`, the paint tools and the Deserializer's `injectProperty`), which logged 4 "person's" instance records
      per `ImageWdgt`. Rulings (owner: "revise/confirm per clean minimal + Do The Right Thing regardless of churn, then
      proceed"), under ONE principle — a meta-object or a meta-verb EDITS; the person's GESTURE TELLS and RECORDS:
      `WorldWdgt.noteCodeChanged` (public) drops the six text caches and the immutable back buffers
      (`resetImmutableBackBuffersCache`) and runs every live widget's `Widget._codeChangedNoSettle` (its `_reLayoutSelf`
      heal, `_invalidateLayout`, the style note) in one settle, off-tree widgets included;
      `Class.widgetsAnEditCanChange` and `Class.notifyWidgetsOfAnEditTo` are deleted, and the class inspector's gestures
      end in ONE `_notifyOfEdit` (`world.noteCodeChanged`). `Widget.sourceChanged` is the canonical self-settling wrap
      of `_sourceChangedNoSettle` (the step plus `_fullChanged`), reached only from the person's gestures: the object
      inspector's four (its `_notifyOfEdit`) and a text's run rows (`TextWdgt._runningTypedCode`). `injectProperty`, its
      add, rename and remove twins and `evaluateString` (now the evaluation alone; `_evaluateInMyScope` folded in) tell
      no one; `injectProperty` records nothing, and the object inspector's Save records a function it saves
      (`InspectorWdgt.applyPropertyEdit`, the one writer of `recordInstanceEdit`). A text holding code of its own adds a
      hash of that code to the keys of its back buffer, its wrap and its line breaks (`StringWdgt._ownCodeKeySuffix`, a
      plain field set by `sourceChanged`'s core) — the ruled shape keyed by the text's IDENTITY, and the item's
      independent review found by reading that a second own-code edit then met its first edit's buffer, and an own
      `linePitch` read its twin's cached fit. The two snapshot replays answer how many records they applied, and
      `loadWorldSnapshot` calls `noteCodeChanged` when any did. The principle and what a code edit refreshes are stated
      once, in `docs/architecture/mixins.md` §2. Measured on the fixed build with the survey's probes: every class-side
      case shows its edit on the next frame, the census leaves 0 stale (bar A1), warm load = cold load, and an
      `ImageWdgt` logs 0 records. Proven by the new `SystemTest_macroClassEditShowsOnTheNextFrame` (mouse and finger;
      test-own classes made and deleted in the test; each edit's shot against a rebuild after the oracle's own flush;
      its fifth step, added after the review, re-edits a string's own code and saves a fitted text's own `linePitch`
      beside an unedited twin), the rewritten `SystemTest_macroInspectorEditTellsOnce` (gestures, verbs alone, every
      live widget once, the record column) and the serialization rig's `sourceEdits.warmLoadEqualsColdLoad`; each failed
      by its own plant (`plants/` in the survey directory: no layout invalidation in the step, no text-cache flush, no
      back-buffer flush, no own-code key, the reviewed identity key and a code hash on the buffer only fail the new
      test's identities; the narrow scope, the refresh put back in the verbs, the verbs recording and the Save not
      recording fail TellsOnce's rows; no load refresh fails the rig's warm-load fact; the controls pass).
      `SystemTest_macroClassEditNotifiesInstances` is retired (its subject, a class relation choosing whom to tell, is
      deleted); `SystemTest_macroInspectorOpensAClassInItsClassInspector` drops its value-class "every widget hears"
      assertions. The inspector member-list churn set (and `InspectorCodePaneRunsAgainstItsSubject`, whose class
      inspector on `StringWdgt` lists the class's new members) was recaptured, owner-approved. Toolkit:
      `scrollInspectorListItemIntoView_InputEvents` presses no bar on a list that fits. Filed: "A scrolled pane keeps
      its height when its content shrinks in the same settle", "A value's per-instance memo outlives an edit of the
      method that fills it", "A palette's back-buffer key names its class and extent, not code of its own" and "The
      inspector churn set cannot see a class inspector's member list move".
- [x] **A run that sets a widget field to a function blocks every world snapshot** (found closing "The evaluation menu is
      unreachable in an inspector's code pane", in the plan's ledger; measured). Code run against a widget (a text's run
      rows, a console's buttons) that assigns a function to a field — `@f = -> 42` — leaves an own function property with
      no source, and `serializeWorldSnapshot` then throws "the function-valued property .f has no editable source and is
      not a serialization transient", for every later save, until the field is removed by hand. The recorded way to give
      a widget a method is the inspector's Add / Save (`injectProperty` keeps `<m>_source`). Whether such a field should be
      carried as source, refused at the run, or reported at the save with a way out is open.
      — CLOSED 2026-11-09 (self-ruled overnight). MEASURED (survey: `Fizzygum-tests/.scratch/function-field-snapshot/`):
      eight shapes of a function a run leaves in state — an own field (`-> 42`, `=> @width()`), a closure over a run's
      local, a class member's reference, a native, a function in a plain object, in an array, and on ANOTHER widget —
      each refused the world save and the widget save alike; a Remove of the field cleared every one, and a Save as
      CoffeeScript (`injectProperty`, which keeps a source for a function value only) each function held directly in a
      field; a Duplicate shares the function. What blocked the person was the REPORT: its
      path, `the world → .children → .f`, named no widget (`serializeWorld` refed every desktop child at that one
      path, and entering a widget's record added nothing to it, though the `SerializationError` header documents
      `… → .contents (SliderWdgt#5) → …`); a function in an array slot read "the function-valued property
      .undefined", "Declare undefined in …"; and the remedy named `@serializationTransients` and `injectProperty`, a
      developer's, not the gestures that clear it. Rulings (self-ruled overnight, under "clean minimal + Do The Right
      Thing"): the save is where such a function is handled — carrying it as source is unfaithful (a run's function
      has only compiled JS, and a closure, a native or a member's body restores wrong or not at all), and a run sees
      only its receiver (three of the eight shapes are not the receiver's own field) and edits state by contract; the
      save already refuses, and keeps refusing (never a silent drop). Landed: `Serializer._pathEntering` names each
      widget as the walk enters it, the world section indexes its children (`the world → .children[3]
      (RectangleWdgt#12) → .f`), a slot's function is "a function has no editable source" at its path, and the remedy
      names the person's gestures first (for a function held directly in a widget's field, the inspector's Remove or
      its Save as CoffeeScript; for one held deeper, the Remove of the field that follows the last widget the path
      names) and the class's `@serializationTransients` second; `Widget.evaluateString` and the reference doc (§5
      functions, §8) state that a function a run leaves has no source a file could carry. Proven by the serialization rig's
      `world.saveRefusal.namesTheWidget` / `namesTheSlot` / `wayOutClears`, each failed by its own plant (`plants/`:
      no widget name, no child index, a slot read as a property, a developer's remedy, a Save that keeps no source;
      the control passes). The item's independent review found the claims of what clears it wider than measured (scoped
      as above) and two adjacent defects. Filed: "A save refused for a function a run left does not offer its
      way out" (owner-gated), "An object inspector hides a widget's own field that shadows a member it inherits" and
      "A save writes NaN and ±Infinity as null".
- [x] **A snapshot load never undoes the page's own earlier class edits** (found closing "A plain class-member rename
      or removal does not survive a snapshot load", in the plan's ledger; by reading, not measured).
      `loadWorldSnapshot` replays the file's mixin- and class-scope records onto the page's classes AS THEY STAND:
      a page that edited a class (or a mixin) before loading a file that never did keeps that edit, so the world it
      loads is the file's edits on top of the page's, not the world the file was saved from. The two stores
      (`Class` / `Mixin` `nonStaticPropertiesSources`) say what each class defines now; what the page booted with
      is the class's source text (`SourceVault`), so a load could first return every edited member to it.
      — CLOSED 2026-11-09 (self-ruled overnight). MEASURED (survey: `Fizzygum-tests/.scratch/load-undoes-page-edits/`): on
      `index-sw.html`, a page that added `RectangleWdgt.probeAdded`, edited `colloquialName`, removed
      `TextWdgt.doesTextFitInExtent` and edited `HighlightableMixin._updateColor` (each as the class inspector's gesture
      does, verb and record) kept all four after loading a pristine file; and the load installed the file's registry,
      so the page held 0 records while it ran the four edits — a re-save carried none of them. One file, two worlds:
      the page showed the edits, the file it saved restored without. Parsing each class's vault text as its
      constructor did and comparing with its store read 550 classes in 18 ms, 0 differences on a pristine page, and
      exactly the edited members after the edits. Rulings (self-ruled overnight, under "clean minimal + Do The Right
      Thing"): the load returns the page to boot before it replays the file (the replay's own premise: the records
      reproduce a session's members from boot); what the page edited is read from the stores against the vault, never
      from a registry (a world's registry lists the edits made under it, while the prototypes are the page's: the
      harness's `resetWorld` builds a world with an empty registry on an edited page); the return goes through each
      meta-object's own `applyMemberEdit` / `removeMember`, mixins first, as boot injected them; the confirm names how
      many members it returns. Landed: `Class._parsedSource` (the constructor's parse, one helper) and
      `Class.bootMemberSources`; `Mixin.bootMemberSources` (a Mixin made without its create flags only parses);
      `SourceEditsRegistry.returnThePageToBootSources` and `membersAwayFromBootCount`; `loadWorldSnapshot` returns the
      page to boot before its replays, refreshes when any member returned or record replayed, and its confirm says
      "returns N edited class members to their source at boot" when there are any; the registry header, `Class`'s
      live-editing comment and the reference doc §12 state it. Proven by the serialization rig's
      `sourceEdits.loadOverPageEditsIsTheFilesWorld` (a page's edit, addition, removal, donor edit and re-edit of the
      file's member, then the file again: exactly the file's members away from boot, its version, its records),
      `sourceEdits.loadConfirmNamesTheEditsItReturns` and `sourceEdits.loadReturnsThePageToBoot` (the file stripped
      of its records: nothing away from boot, no record, a re-save carries none) — each failed by its plants
      (`plants/`: no return, classes only, edited members only, the return after the replay, a silent confirm; the
      control passes). The item's independent review found the return reaching an open defect: a pre-compiled page
      registered no parsed mixin (the first half of "Mixin editing holds only where the page compiled its mixins"),
      so a donated member the page had edited on its CLASS was deleted outright by the return, with no donor to give
      back. Folded here (self-ruled overnight: fix the root): `Mixin.register`, called by the one boot step that
      ingests a page's sources on both its paths, once per name, so every mixin a page parses is registered and a
      Mixin made only to parse never is; proven on the `homepage` tree by `fg homepage`'s production smoke (every
      mixin a class augments with is parsed; a donated member edited on its class returns to its donor's), both
      failed by a plant that registers none. Also from the review: each member's return is caught and logged, as each
      record's replay is (the desktop is gone by then); the rig's deltas are exact. That item's other half stays
      open: "A class a lazy part defines after a mixin edit takes the mixin's boot member".
- [x] **A class a lazy part defines after a mixin edit takes the mixin's boot member** (the half of "Mixin editing
      holds only where the page compiled its mixins" left open when its other half — a pre-compiled page registered
      no parsed mixin — closed with "A snapshot load never undoes the page's own earlier class edits", in the plan's
      ledger; by reading, not measured). A consumer class is augmented from its mixin's compiled LITERAL
      (`augmentWith`, `onceAddedClassProperties`), never from the mixin's store, so where parts load lazily a class
      defined after an edit of its mixin gets the mixin's boot member, and its prototype disagrees with the store
      the class inspector shows and a snapshot load returns from.
      — CLOSED 2026-11-10 (self-ruled overnight). MEASURED (survey: `Fizzygum-tests/.scratch/lazy-consumer-mixin-edit/`):
      on the dev `index.html`, after `HighlightableMixin`'s `hoverExited` was edited, a member added and `pressCancelled`
      removed (its own verbs), the core consumer `ButtonWdgt` held all three as the store says, while
      `CreatorButtonWdgt`, made when the lazy `app-kit` part loaded after the edits, held the BOOT member on all three
      — though `Mixin.donorOf` answered Highlightable for it. Cause: `Object::augmentWith` injects the literal's
      members, compiled at boot; a mixin edit reaches only the consumers recorded at its moment. Rulings (self-ruled
      overnight, under "clean minimal + Do The Right Thing"): a class made after its mixins' edits takes, once whole
      (its body assigned, its meta-object bound), what the consumer rule `Mixin`'s header states gives it from the
      stores — its own member, else its last augmentation's (`donorOf`), else none — not in `augmentWith`, where the
      class body is not assigned and `theClass.class` is still the parent's meta-object, and not by keeping a second,
      recompiled copy of the literal. Landed: `Class._takeMixinMembersFromTheStores` (the create pass, after `.class`
      is bound), `Class.membersAwayFrom` (the one store-vs-boot comparison, which `SourceEditsRegistry` now reuses),
      `membersAwayFromBoot` on both meta-objects, `Mixin.bootMemberSources` parsed once; `docs/architecture/mixins.md`
      states it. On the fixed build the lazy consumer takes all three. Proven by `parts-lazy-load-headless.js`'s
      `LAZY_CONSUMER_TAKES_MIXIN_EDITS` (the `plots` part made after `KeepsRatioWhenInVerticalStackMixin`'s edit,
      addition and removal on members only a holder frame's drag reaches; then a return to boot reaching the new
      consumer too), failed by its bite-proof's plants (the take made a no-op; the new class dropped from the
      mixin's consumers before the return). The item's independent review found no defect in the take and these to
      tighten, landed: it compiles every member before it changes anything (all or nothing, as both removal verbs),
      and injects only where the stores' answer differs from what the augmentation left (an unrelated mixin's
      unchanged member keeps the one function every consumer shares, which the same-mixin-twice guard compares);
      `Mixin.withdrawFrom` is the one undoing of an injection; and on the pre-compiled tree `fg homepage`'s
      production smoke holds a class made at run time after a mixin edit to the store's member (failed by the same
      no-op plant). Filed: "A snapshot's source edits of a lazy part's classes are dropped when the file holds none of
      its widgets".
- [x] **A value answering `rebuildDerivedValue` is dropped from a save, and breaks a copy, wherever it stands**
      (found closing "A world snapshot cannot be saved while a class inspector is open", in the plan's ledger;
      measured).
      - An inspector on a canvas context (a world inspector's `worldCanvasContext` row) saves without its subject, and
        the restored inspector throws at its first row click (`Cannot read properties of undefined (reading
        'canvas')`). A Duplicate of it throws (`… reading 'getContext'`).
      - The Serializer's skip (`encodeOwnProps`) and the Duplicator's rebuild (`_rebuildDerivedValues`) both rely on a
        precondition, a `<name>Context` field beside its canvas `<name>`, that neither one states.
      - The Serializer's comment says the deserializer rebuilds the value, but the Deserializer's pass 4(b) reads a
        `record.derived` list that no save writes. After a load, each widget rebuilds its own context, lazily.
      — CLOSED 2026-11-10 (self-ruled overnight). MEASURED (survey: `Fizzygum-tests/.scratch/derived-value-position/`):
      an inspector whose subject is a canvas context — the world's, and a `CanvasWdgt`'s back buffer's — threw on
      Duplicate (`… reading 'getContext'`); a world save left its subject out, and the restored inspector threw at
      every re-lay (`LAYOUT_ERROR … _subjectIsEditable`) and at a row click. Both walkers judged "derived" by the value
      alone, while a context's rebuild reads a canvas from its PLACE (`<name>Context` beside canvas `<name>`); the
      SWCanvas context holds no `.canvas` to ask instead. A census of the live widgets found every widget's context in
      that place. Rulings (self-ruled overnight, under "clean minimal + Do The Right Thing"): derivedness is a fact of
      the place, asked in one predicate both walkers share; a context anywhere else is a page object like any other —
      a save refuses it (never a silent drop, as for a function), a copy keeps it by reference (as for an outside
      widget); the deserializer's dead rebuild pass goes. Landed: `NativeValueKinds.isCanvasContext` and `isDerivedAt`
      (a stamped runtime object is derived wherever it stands, a context only beside its canvas);
      `Serializer.encodeOwnProps` and the Duplicator skip and rebuild only what `isDerivedAt` answers; the Duplicator
      keeps a context standing apart from its canvas by reference; the closed-set refusal of a context says what a
      context needs and the person's way out (close what holds it); `Deserializer` pass 4(b) (`record.derived`, which
      no save writes) deleted; the reference doc's derived-value paragraph states it. Proven by the serialization
      rig's `inspector.onACanvasContextDuplicates` and `inspector.onACanvasContextRefusesTheSave` (both backends, both
      subjects), each failed by its own plant (`plants/`: the value-only rule restored fails both; contexts not kept by
      reference fails the first; the generic remedy fails the second; the control passes). The item's independent
      review found no defect at its first severity and these, landed: "drawn from" is asked exactly, of the canvas
      (`canvas.getContext "2d" is value` — a canvas keeps one 2D context on both backends), not inferred from a
      canvas merely standing beside it; a context in a SLOT (an array, a Map, a cache) is kept by reference too, the
      rule moved into `Duplicator._duplicate`; the reference doc's §2 traversal contract states the place rule; the
      rig checks a context in an array, settles each copy in the world, and cleans up on failure. The positive branch
      — a context beside its canvas still derived — fails, planted out, the rig's `world.everyAppSnapshot.FizzyPaintApp`
      (its `behindTheScenesBackBufferContext`). Filed: "A runtime object stamped derived is dropped from an inspector
      holding it".
- [x] **An `app:` key naming a class that is no app is `new`-ed during a restore** (found by the independent review
      closing "The widget-file door never loads the lazy part a file needs", in the plan's ledger; by reading).
      `WellKnownObjects.resolveApp` builds an instance of whatever class `classNamed` answers, so
      `{"$wk": "app:WorldWdgt"}` would run `new WorldWdgt` in the middle of a restore, and that constructor's first act
      is to make itself `window.world`. A key that names a class must name one of the KIND the key stands for (an app
      key, a `WindowedApp` subclass, which core cannot name: the part-edges gate), and the refusal must say so too.
      — CLOSED 2026-11-10 (self-ruled overnight). MEASURED (survey: `Fizzygum-tests/.scratch/app-key-kind/`):
      `resolveApp('RectangleWdgt')` built a RectangleWdgt, and a world file carrying `{"$wk": "app:StringWdgt"}`
      passed the doors' up-front refusal and loaded, `new`-ing a StringWdgt mid-restore. Rulings (self-ruled
      overnight, under "clean minimal + Do The Right Thing"): the kind is the save's own reading — a load accepts an
      app key only for a class whose instances a save writes as that very key (their `wellKnownKey`), so it accepts
      exactly what a save writes and names no app-kit class (measured: exactly the 16 apps and their stateless base);
      refused up front by both file doors (re-judged on their re-entry once a lazy part arrives) and by the net.
      Landed: `WellKnownObjects.isAppClass` and `notAnApp` (one message); `Deserializer.whyItCanNeverBeRestored` refuses
      such a key before a world load's teardown and a widget file's first shell; `resolveApp` throws a load
      `SerializationError` in the same words; the reference doc §4a states it. Proven by the serialization rig's
      `world.loadGuard.appKeyNotAnAppRefused` (desktop kept, the informs name the class) and
      `world.loadGuard.widgetFileAppKeyNotAnAppIsALoadError` (the widget door's informs, and the net building
      nothing), failed by their plants (`plants/`: every class an app fails both; no up-front judgement fails the
      world door's; no net fails the widget door's net; the control passes). The item's independent review found the
      same bug class one door over, and these, landed: a lazy launcher's click `new`ed `window[appClassName]` — a
      name a file carries — and now resolves it through `classNamed` and launches only an app (`isAppClass`), else
      says so (`world.loadGuard.launcherAppNameNotAnAppLaunchesNothing`, failed by its plant); `isAppClass` reads the
      save's own `keyFor`; one refusal wording, singular and plural; the refusal's comments and the reference doc
      §9/§11 name the app kind among the reasons a lazy part's arrival can still refuse (on the re-entry, after the
      confirm and the part's fetch); the widget door's check now proves the refusal comes before
      `Deserializer.deserialize` (a spy; the no-up-front plant fails it) and drives the net through a direct
      deserialize. The lazy re-entry is held by reading: the same predicate re-runs. Filed (low): "A load judges an
      app key's kind by the page's edited members, then returns them to boot".
- [x] **The reflective layer reads as absent until the boot's tail has run** (found by the same review; by reading).
      On a compile-at-boot page, `reflectiveLayerHasLoaded` turns true only after `createWorldAndStartStepping` and
      `runPostBootActionsOnce`, though the world was compiled from the layer. If a post-boot step throws, the flag
      stays false and the memoized promise rejected: every later inspector open (`Widget.spawnInspector`) and every
      file holding an inspector (`Deserializer._needsTheReflectiveLayer`) then waits on, or is refused for, a layer
      that is there.
      — CLOSED 2026-11-10 (self-ruled overnight). MEASURED (survey: `Fizzygum-tests/.scratch/reflective-layer-tail/`):
      `index-sw.html` booted with a malformed `?startupActions=` (the tail's `world.nextStartupAction` throws) ran its
      world with every source in, yet `reflectiveLayerIsLoaded()` answered false and `world.spawnInspector world` never
      opened an inspector (the memoized promise rejected, surfacing again as a page error); a clean boot opened one.
      Ruling (self-ruled overnight, under "clean minimal + Do The Right Thing"): a flag named "the layer has loaded"
      means that — the layer's promise covers the meta-system, the batches and their ingest or compile, and the boot
      chains its tail after it, apart from it; a clean boot keeps the order of its work (manifests, world, post-boot
      actions), and the flag now turns true before the world is built (no reader runs in that window, read reader by
      reader). Landed: `loadReflectiveLayerPromise` ends at the ingest/compile; `finishBootAfterTheLayer` is the boot's
      tail; the post-boot actions' once-only guard, which the split made redundant (its two callers are now mutually
      exclusive endings of the boot), is deleted (`runPostBootActions`); `docs/architecture/build-and-packaging.md` §5
      states it, and `docs/plans/single-file-save-plan.md`'s description of the chain follows. On the fixed build the
      malformed tail leaves the layer loaded and an inspector opening. Proven by the `apps` leg's new rule
      `LAYER_ABSENT_AFTER_A_FAILED_TAIL` (`smoke-apps-headless.js`: the tail's own throw required, else INVALID; the
      inspector, which waits on the lazy `meta-tools` part, polled for), failed by its bite-proof's plant (the layer
      coupled to the tail again). The independent review found no defect in the split and the rig's fixed 2 s wait,
      the vacuous case and the guard's stale reason, landed as above; the pre-compiled "background" ending has no
      shipped profile and no rig.
- [x] **A palette's back-buffer key names its class and extent, not code of its own** (found by the independent review
      closing "A class edit refreshes only what a repaint shows", in the plan's ledger; by reading; low).
      `PaletteWdgt.createBufferCacheKey` (`PaletteWdgt.coffee:81`) keys the shared buffer by class and extent alone,
      so an object inspector's Save of `fillPaletteBuffer` on one palette hits the shared entry and shows nothing, and
      after any flush whichever same-class, same-size palette paints first fills that entry for all of them. Texts carry
      a hash of the code they hold of their own in their keys (`StringWdgt._ownCodeKeySuffix`); palettes do not.
      — CLOSED 2026-11-10 (self-ruled overnight). MEASURED (survey: `Fizzygum-tests/.scratch/palette-own-code-key/`): two
      120×80 ColorPaletteWdgts; the first given an own `fillPaletteBuffer` painting red (the inspector Save's verbs):
      the red never showed (the shared entry for class + extent answered), and after a flush with the first painting
      first its unedited twin showed red. Ruling (self-ruled overnight, under "clean minimal + Do The Right Thing"): one
      mechanism for "the code a widget holds of its own keys every shared cache it fills" — the field and its upkeep
      move from StringWdgt to Widget (`Widget._ownCodeKeySuffix`, kept by `Widget._sourceChangedNoSettle`, the
      gesture's core; StringWdgt's copy deleted), and PaletteWdgt gains `createBufferCacheKey` (one spelling with the
      texts') carrying it. On the fixed build both palettes show their own code in every paint order. Proven by the new
      assertion-only `SystemTest_macroPaletteBufferKeyNamesItsOwnCode` (mouse and finger; real inspector Save and
      Remove presses; follower proof clean on both), failed by its plants (`plants/`: the key without the suffix; the
      gesture's core keeping none); `docs/architecture/mixins.md` states it. Moving the two members off StringWdgt shifted
      eight tests' inspector member lists (the seven of the churn set and `InspectorCodePaneRunsAgainstItsSubject`'s
      class inspector on StringWdgt, the churn set's known blind spot): every changed shot checked by eye
      (`diffpage/`, `crops/`), all member-list churn, recaptured under the overnight grant, mouse and finger at dpr 1
      and 2, both completeness gates green. The item's independent review found no defect in the move and these,
      landed: the test pinned the key method, not the lookup (an inline key restored would have passed it) — it now
      reads each palette's buffer through `getPixelColor` in both paint orders after a flush, and a third plant (the
      inline key) fails it; a Save then a Remove left an own `_ownCodeKeySuffix` behind, now deleted when the widget
      holds no own code; the palette passages of `PaletteAppearance`, `BackBufferMixin`, the appearance-paint
      convention and the widget-authoring guidelines name the own code; `ClassEditShowsOnTheNextFrame`'s intent no
      longer names the retired `_holdsOwnCode`. Filed: "A text's measurement, wrapping and split caches name no code
      of its own" (the docs name the caches the suffix reaches).
- [x] **The inspector churn set cannot see a class inspector's member list move** (found closing the same item;
      measured). `scripts/derive-inspector-churn-set.js` plants one enumerable own field on every widget, which moves
      every OBJECT inspector's member list; a member added to a CLASS moves a class inspector's list instead, which that
      plant never touches. Closing the item added `StringWdgt._ownCodeKeySuffix` and `_sourceChangedNoSettle`, and
      `SystemTest_macroInspectorCodePaneRunsAgainstItsSubject` (whose image 3 is a class inspector on `StringWdgt`) moved
      with the churn set while not in it — so `fg recapture-inspector` and `classify-diff.js`'s corroboration pass over
      it. A second plant, a member added to a class's prototype, would derive the class half.
      — CLOSED 2026-11-10 (self-ruled overnight). MEASURED: with `derive-inspector-churn-set.js`'s plant extended to
      give every class's PROTOTYPE the same no-op member once every class is compiled (a class inspector lists its
      subject prototype's own members), `--check` found 3 tests the set lacked, each confirmed single-process (fails
      alone with the plant, by pixels; passes alone without it): `InspectorCodePaneRunsAgainstItsSubject` (the one
      that moved outside the set twice, with this item's two predecessors — authored after the set was last derived,
      so a single union run cannot say which half reaches it), `MixinEditDonorAndOverride` and
      `MixinFieldEditDonorAndOverride` (in the tree when the set was last derived and absent from it: only the class
      half reaches them); no test outside the inspector family moved. Ruling (self-ruled overnight): the second plant
      the item named, in the same run as the first (one derivation, the union), each half proven live. Landed: the
      class-prototype half of `inspectorChurnPlant` and its liveness proof, per suite shard ("no class prototype
      carried the field" → INVALID) and per single-test confirmation; a give-up naming the missing symbol once the
      world is up; `scripts/inspector-churn-set.json` written (18 tests, its own description updated, since `--write`
      keeps it); the tests repo's CLAUDE.md and `docs/plans/pixel-icons-plan.md`'s count state it. The liveness check
      bites: the real planted log with its class lines stripped reads INVALID for every shard, the log as written reads
      valid (`Fizzygum-tests/.scratch/derive-class-liveness-bite.js`, not committed). The independent review's
      findings — the confirmations not checking the class half, stale self-descriptions, an unbounded poll, the
      attribution — landed as above. Filed: "`fg recapture-inspector` recaptures a churn-set test's behaviour shots
      blindly".
- [x] **A plant's give-up comes after its run has ended** (found by the independent review closing the same item, in
      the plan's ledger). Twelve plant polls, in nine `*-selftest-headless.js` files, say `PLANT_NOT_APPLIED` only after
      12000 or 20000 polls of 5 ms (60–100 s). The runs measured close their page sooner: the sequence proof's four
      runs take 36 s together, the menu and pin sweeps' proofs 23 s and 12 s. So a renamed class fails its case only
      as a rule not fired, never by the "every plant applies" line that the `hand-list-sanctioned:` comments in the
      suite-gate, menu-sweep and pin-sweep proofs cite. Measured on the harness page and `index-sw.html`:
      `window.world` stays undefined until the world is built, after every eager class is defined, so "the world is
      up and the class is not" is a give-up a run reaches. It does not fit every plant: the staleness census boots
      `index.html`, where `SpreadsheetApp` arrives with a lazy part after the world, and one census give-up waits for
      the world itself.
      — CLOSED 2026-11-10 (self-ruled overnight). MEASURED: fourteen polls, not twelve (the library's shared
      `suiteFailurePlant` and the census's boot poll, which had NO give-up), and fourteen more hook waits that never
      gave up at all (graph-liveness, parts-snapshot-load ×4, parts-lazy-load ×3, parts-lazy-icons, smoke-apps, the
      nested waits in the menu sweep ×2 and the pin sweep, and the file plant
      `notification-settle-audit/cache-oracle-plant.js`). A
      one-off bite (`Fizzygum-tests/.scratch/plant-give-up/bite.js`, not committed) ran the pin sweep — 3.7 s from
      launch to close — with the old poll on a missing class: no `PLANT_NOT_APPLIED` line inside the run. It also
      measured that even 200 polls after the world come too late, and boot's `startWorld` builds the world and its
      bin, shelf and desktop in ONE synchronous call, so no poll ever sees a world without them. Ruling (self-ruled
      overnight): ONE way a `proveLeg` proof's inline plant waits for its hook, `whenPresent(what, hooks, act, opts)`
      in `scripts/lib/gate-bite-proof.js` — hooks as global names or dotted paths (or a page function, given the
      world, for a hook no path names), giving up at the FIRST poll that sees the world, and, for a hook a LAZY part
      brings (`opts.part`), once every class the build manifest lists for that part is in the page; waits for a moment
      the run reaches (a test playing, a rig's probe) stay their plants' own. THE WORLD is a `WorldWdgt`: until the
      boot bundle's own `world` variable shadows it, `window.world` is the page's `<canvas id="world">` (an element's
      id is a window property) — the first gauntlet's `selftests` leg gave up falsely through it in three proofs, and
      the independent review found the same, along with a `world.children` hook that would have acted on the canvas.
      All thirteen proofs use it; `cache-oracle-plant.js` gives up as the other file plants do (60 frames after the
      world), and its proof holds both its runs to every plant applying. Its own node self-test,
      `scripts/lib/gate-bite-proof-selftest.js`, stages a boot on a fake page (the canvas phase, the world, a lazy part
      arriving class by class), and fails on each defect this item had (the canvas as the world, the manifest read at
      document start, a part's hooks skipped while it settles: `.scratch/plant-give-up/selftest-bite.js`). The bite,
      re-run: a missing eager hook reads "not there once the world appeared" inside the 3.7 s pin sweep, a missing lazy
      hook "not there once part spreadsheet arrived" on the census, a part the build lacks "(this build has no part
      …)". The tests repo's CLAUDE.md (the plant rail) and `lint-and-static-checks.md` §3 (the judge: every plant
      applies) state it. Converting plant bodies from template text to code let two gates see them, and both found a
      real defect: a HOLE (`arg` was configuration and moved into `opts`) and an EXTRA_ARGUMENT (a plant's replacement
      for `Deserializer.whyItCanNeverBeRestored` declared no parameters).
- [x] **The three suite runners wait for a page to boot three ways** (found closing
      "`run-sequence-selftest-headless.js`'s 'page stopping answering' case is load-sensitive", in the plan's ledger).
      The suite runner gives a shard 90 s of boot looks, each answered up to its 5-min backstop, and names a page that
      never starts; the single runner bounds each wait of its drive; the sequence runner makes 300 looks of up to 5 s
      each, so a page stuck while it boots is waited on for about 25 minutes in silence (measured: no line in 120 s,
      then killed), and a world that never boots but answers falls through to a raw ReferenceError that names no rule
      (by reading). One boot wait, with one bound and one named line, shared by the three, as `answerWithin` is.
      — CLOSED 2026-11-10 (self-ruled overnight). MEASURED on a world that never arrives (its `window.world`
      assignment swallowed): the sequence runner ended in 32 s on a raw `TypeError: Cannot read properties of undefined
      (reading 'automator')`, exit 2, no rule; the single runner printed TEST FAILED after 31 s with no line saying the
      page never booted. Ruling (self-ruled overnight): ONE boot wait for a runner's test page, `startedWithin(page, ready, { lookMs, arg })`
      in `scripts/lib/headless-driver.js` beside `answerWithin` — the suite's: 90 s of looks, each waiting out a long
      boot (boot is where a page goes silent legitimately, measured in-wave), one line, `did not start
      within 90s` (+ ` (the page stopped answering)`), the wording the docs already quote — with one page predicate,
      `HARNESS_WORLD_STANDS` (a `WorldWdgt` in `window.world`, never the page's `<canvas id="world">`), which the suite
      asks with its startup run begun. The suite's own `until` for its shard pages went with it; the single runner's in-page ready
      step left its drive (DRIVE_ANSWER_MS 210 → 180 s); the sequence runner fails on a new rule, `DID_NOT_START`,
      planted by its proof (a world that never arrives). After: the sequence runner prints `✗ the page did not start
      within 90s — nothing was played` and exits 1, the single runner `…: the page did not start within 90s` + TEST
      FAILED (both in 90 s, the one bound); `DETERMINISM.md` and the tests repo's CLAUDE.md state the wait beside
      `answerWithin`. The independent review's findings landed: a look the protocol itself timed out reads as stopped
      answering (the sequence runner's 240 s protocol timeout came before the look's bound); the single and sequence
      runners look up to a minute (`BOOT_LOOK_MS`), so their verdict lands before their callers' 4–6 min kill timers
      (the suite keeps its 5-min backstop); a page or browser LOST while it boots ends the wait at once, said so (the
      sequence runner exits 2 on it, nothing measured), never read as a boot failure; the capture tool keeps the new
      lines; the suite asks the same predicate, `{ playing: true }`; the sequence runner prints its header before the
      boot and states its boot exits. Filed: "The paint audit waits on its pages with no bound, and for boot inside the
      page", "The suite's probe page waits for boot its own way" (the review's HIGH: the suite counts its tests on a
      probe page that waits for boot in-page, unbounded, and meets a broken boot first), "`heap-forensics.js` waits for
      its page to boot its own way".
- [x] **A value's per-instance memo outlives an edit of the method that fills it** (found closing the same item; by
      reading; low). `Color.toString` memoizes into `_derived_String` (`Color.coffee:216`): an edit of `toString` that
      keeps the memo guard leaves every live colour — the interned theme colours among them — answering its old
      string, and no flush reaches a value's own memo (`WorldWdgt.noteCodeChanged` drops the caches built from code,
      not state a value keeps).
      — CLOSED 2026-11-10 (owner-ruled: option (a), the memo dropped). Parked by the overnight loop as a trade-off
      (`Fizzygum-tests/.scratch/value-memo-edit/PARKED.md`), then MEASURED (`perf-probe.js`, `perf-probe-d.js` there, not
      committed):
      in Chrome's V8 on real colours, the memo's read is ~4 ns a call, a memo keyed by the function that built it the
      same, one container the class holds (a WeakMap, emptied by `WorldWdgt.noteCodeChanged`) ~9 ns, and no memo
      ~45 ns; the product calls `toString` 179 times per full desktop repaint and ~215–293 per cycle in two
      paint-heavy tests (6,121 and 7,382 in their heaviest cycles). No memo costs ~10 µs a frame, ~0.3 ms in the
      heaviest measured cycle. Ruling: (a) — a colour's string is a pure function of fields that never change, so
      holding no copy leaves nothing a class edit can leave stale, and `Color` is no longer written after it is
      made. `Color.toString` builds its string on every call; its comment names the cache that would fit if it ever
      shows up hot (the WeakMap that `noteCodeChanged` empties, never a field on the instance).
      `immutable-value-classes.md` states the rule (a value keeps no copy of what its code derives; a cache of it is
      one container the class holds and the notification empties); the perf plan's two passages that counted on the
      memo are corrected. Rig: `sourceEdits.valueClassEditReachesLiveValues` (`serialization-roundtrip-headless.js`,
      its own page) — the class inspector edits `Color.toString` ("rgb(" made "RGB(") and an interned colour that
      painted before answers the edited string at once, then its boot string after the page returns to boot.
- [x] **The suite's probe page waits for boot its own way** (found by the independent review closing "The three
      suite runners wait for a page to boot three ways"; by reading). Before any shard, `scripts/lib/shards.js`
      `probeTestsOrExit` boots the harness page once to count the run's tests and waits for the world INSIDE one raw
      `page.evaluate` (60 s, no `answerWithin`), retries once, then exits 1 naming no rule (`RULELESS_FAILURE`, exit 2).
      A world that never arrives meets this page first, so a real boot break reads as an operational failure, and a
      page stuck while it boots is waited on until the protocol timeout (10 min, twice) in silence. The paint audit
      shares it. The suite-gate proof keeps its plants off the probe page by design, so a planted proof of it needs
      that rail first.
      — CLOSED 2026-11-10 (self-ruled). MEASURED by reading and by plants: the probe was the one test page the run
      boots with no rail (`run-all`'s `--prelude=`/`--audit-prelude=` and console rule reached only shard pages) and it
      booted a shard URL, so it started playing the suite while it counted (hence `pinSingleGroup`); the proof kept
      plants off it only so its SHARD_SHORT plant would not shorten the probe's count. Rulings (self-ruled, SURVEY in
      `Fizzygum-tests/.scratch/probe-page-boot-wait/`): the probe (`lib/shards.js` `probeTests`) boots through the
      runners' one boot wait (`startedWithin` + `HARNESS_WORLD_STANDS`, the caller's own look bound — the suite's
      `STALL_MS`) and asks for its list within 30 s; it opens the harness with no `?startupActions`, in both callers
      (nothing plays on it; `pinSingleGroup` is gone, the groups' defaults are 1/0), through one URL base the shards'
      URLs extend (`harnessUrl()`); the suite sets it up like every page it boots (`installRails`, and its failing
      lines filed under `(probe)` — fail-closed); a probe page that does not start or does not list its tests fails the
      run as `DID_NOT_START` (the sequence runner's name for the fact), `the probe page did not start within 90s —
      nothing was played`, never retried — boot awaits every script; only a probe that threw or lost its page is
      retried once (infrastructure; `lib/headless-driver.js` `pageGone`, now shared with `startedWithin`). A plant
      found that a selection which drops its callback has its pending promise collected ("Promise was collected"),
      which the first shape read as infrastructure; only a lost page is. Proven: the suite-gate proof plants
      DID_NOT_START on both engines (the world's assignment swallowed on every page: the probe page meets it first;
      90 s each, the shared bound), its SHARD_SHORT plant now drops its test only on a page that plays, and three
      one-off plants bite (a list look whose callback is dropped / held → DID_NOT_START with its own line; an error
      line only the probe page raises → the run fails naming UNTOKENIZED_CONSOLE_ERROR during `(probe)`, its shard
      ok). The paint audit adapts its call and reads a probe page that did not start INVALID, as before, until its
      own page waits name it (its BACKLOG item says so, and that its probe page's console is not read). The three JS
      audit gates (storage, revisits, vmtruth) now read a probe page that never started as their embedded suite
      failing (exit 1), not INVALID — as they read a shard that never starts. A failing line every page emits at boot
      is filed twice, `(probe)` and `(boot/setup)`, with no verdict changed. The independent review's findings landed:
      a renderer crash on the probe page closes its browser at once, as a shard's does, and `pageGone` counts a
      crashed target, so the probe's look fails as infrastructure (retried) instead of waiting out its bound into
      DID_NOT_START; the list look waits as long as a boot look (selecting loads every test's metadata script — 30 s
      could trip under load); the dropped-`--tests` check comes before the zero check; a probe page whose rails fail
      to install closes its browser. Measured: the proof's two 90 s runs took the one proof file to 343 s in the
      gauntlet (its kill is 480 s) and made the selftests leg wave A's longest (343 s, total 1066 s against 991 s), so
      the proof is one self-test per engine (`suite-gate-chrome-…`, `suite-gate-webkit-…`, sharing
      `lib/suite-gate-proof.js`; the census holds each file to launching the runner itself) and the leg runs them at
      once; `NEVER_STARTS` is `lib/gate-bite-proof.js`'s, shared with the sequence runner's proof; the every-rule run
      also asserts an error line only the probe page raises. Not planted: a renderer crash (no page script can cause
      one). Filed: "The rigs wait for their pages to boot a dozen ways, most of them in-page and unbounded".
- [x] **The paint audit waits on its pages with no bound, and for boot inside the page** (found closing "The three
      suite runners wait for a page to boot three ways", in the plan's ledger; by reading). `run-paint-audit.js` drives
      each page through one raw `page.evaluate(driveAuditSuite, …)` — no `answerWithin` — whose in-page waits begin
      with a boot wait of its own (90 s on a shard, 30 s for a single run), so a page stuck in a script is waited on
      until the protocol timeout, and its boot is another copy of the wait the three runners now share
      (`scripts/lib/headless-driver.js` `startedWithin`). Its probe (`lib/shards.js` `probeTests`, shared with the
      suite) boots through `startedWithin`, but a probe page that did not start is thrown into the audit's catch and
      reads INVALID (exit 2): the audit names no rule for a page that never starts, and it reads no console line of its
      probe page (its pages' console rule is attached per shard, not by its page factory).
      — CLOSED 2026-11-10 (self-ruled). MEASURED by reading and by plants: each page ran in one raw `page.evaluate`
      holding an in-page boot wait of its own (90 s a shard, 30 s the single page) and an in-page completion wait
      (600 s), so a page stuck in a script was waited on until the protocol timeout (640 s, behind fg's 720 s alarm); a
      world that never booted read INVALID, which the file's own comments called a coverage hole; the probe page's
      console was read by nobody, and the console rule was attached twice, near-identically. Rulings (self-ruled, SURVEY
      in `Fizzygum-tests/.scratch/paint-audit-page-waits/`), the sequence runner's split: a page that did not start —
      a shard's, the single page, the probe — is a finding, `DID_NOT_START` (`✗ PAINT-TRUTHFULNESS GATE FAILED: [shard 0]
      the page did not start within 90s; … — nothing was audited there`), and the run's verdict (what other pages
      measured is printed, and their unaudited tests are not also a COVERAGE_HOLE); a page that stops answering
      mid-run leaves the measurement unfinished — INVALID, named on time. `newAuditPage(label, errors)` sets up every
      audit page one way (the plant, the flag, the UA, the console rule, a renderer crash closing the browser);
      `auditOnPage` boots through `startedWithin` + `HARNESS_WORLD_STANDS` (its startup run begun, on a shard page) and
      polls the page from Node, each poll bounded (5 s), a page silent for 30 s named `the page stopped answering for
      30s — a script stuck in a loop?`, the suite given 600 s; the in-page `driveAuditSuite` is gone. Proven: the
      proof plants DID_NOT_START (NEVER_STARTS on both shard pages); one-off plants (`.scratch/paint-audit-page-waits/`):
      the probe path (no `--tests`) and the single page under NEVER_STARTS → DID_NOT_START, a page stuck in a loop once
      its second test plays → INVALID 30 s later (it was 640 s). The independent review's findings landed: the single
      flow (`--shards=1`, fg's serial retry) selected its tests and started the run without waiting for the selection —
      the race `AutomatorLoader.selectTestsFromTagsOrTestNames` forbids, under which a `--tests=` run could audit the
      manifest's first test in place of a named one — and is now one shard of one group, whose `?startupActions` runner
      waits; a call made after a page's session closed answers Puppeteer's "Attempted to use detached Frame", which
      `pageGone` now counts (for every runner's boot wait), so a crash between two calls reads as a lost page, not one
      still answering or never started; the run's whole bound counts from its navigation (600 s), inside fg's 720 s
      alarm (the bounds had summed to ~820 s); a failing line no longer repeats its token; errors under a verdict that
      does not judge them print under a heading; an audit error prints a `GATE INVALID` line fg's summary greps.
- [x] **`heap-forensics.js` waits for its page to boot its own way** (found by the same review; by reading). A
      120 s loop of raw `page.evaluate` looks (`window.world && WorldWdgt.frameCount > 5`, no `answerWithin`), ending
      in a bare `Error('harness did not boot')`; it runs in the `selftests` leg through its proof.
      — CLOSED 2026-11-10 (self-ruled). MEASURED by reading and by plants: the boot loop's looks were raw (a stuck page
      held each one for the 240 s protocol timeout before the 120 s deadline was read), and its `--test=` path started
      the run one second after a `selectTestsFromTagsOrTestNames` with no callback — the race the loader's own comment
      forbids (a run started before the selection lands falls back to the whole manifest). Rulings (self-ruled, SURVEY
      in `Fizzygum-tests/.scratch/heap-forensics-boot-wait/`): the page boots through the runners' one boot wait
      (`startedWithin` + `HARNESS_WORLD_STANDS` on its raw Puppeteer page; the `frameCount > 5` heuristic is gone, and
      the tool's findings on its own self-test are unchanged — measured against the committed tool); the run starts in
      the selection's callback (bounded by the boot look's minute); the run's finish is the runners' wait for it,
      `lib/headless-driver.js` `finishedWithin` (each look 5 s, a page with no clean answer for 30 s named — stopped
      answering, or the error it kept answering — the whole run 300 s), which the paint audit's `auditOnPage` now uses
      too, so the loop exists once. A page that did not load or start, like a run that did not finish, measured
      nothing: status 2, `heap-forensics: the page did not start within 90s — nothing was measured`, no stack (it is a
      forensic tool with no rule registry; its exit contract already said 2). The independent review's findings
      landed: the old `frameCount > 5` had also proved two things — lens 2's wrap in place before the plant and the
      reset, and the world's cycle alive — so after the boot wait the tool asks for both in bounded looks (the prelude
      flags its install; `WorldWdgt.frameCount` must advance within 30 s), else status 2 named; `goto` takes the
      runners' 60 s `load` bound and its failure is named; a throw from `runAllSystemTests` or from the selection is
      named, a lost page said whole; the header's `--tests=A,B,C` says the manifest's order (the page plays them so).
      Proven: its self-test (the plant found end to end, the in-band gate silent) passes; one-off harnesses wrapping
      `puppeteer.launch` (`.scratch/heap-forensics-boot-wait/plant-harness.js`): NEVER_STARTS → status 2 with that line
      after 90 s, a world frozen once it stands → `the world stood but did not cycle for 30s`; a `--test=` run →
      CLEAN; the paint audit's stuck-page plant through `finishedWithin` → INVALID in 30 s.
- [x] **The wall-clock stink does not see `new Date` without parentheses** (found closing the same item; by reading).
      Its pattern is `new Date\s*\(`, so a paren-less read of the clock is not counted: `WorldWdgt`'s cycle-start
      `new Date`, `AnalogClockWdgt`'s constructor, the harness's command pacing (`(new Date).getTime()` in
      `AutomatorPlayer.replayTestCommands`) and `EventCommand`'s `@date = new Date`.
      — CLOSED 2026-11-10 (self-ruled). MEASURED: the four sites are the only paren-less clock reads in either tree;
      four more `new Date <argument>` sites are VALUES, not clock reads (`WorldWdgt._updateTimeReferences`'s previous
      cycle, `Deserializer`'s `record.ms`, `Duplicator`'s copy, `AnalogClockAppearance`'s pinned date), and the old
      pattern would also count a `new Date(x)`. Rulings (self-ruled, SURVEY in
      `Fizzygum-tests/.scratch/wall-clock-paren-less/`): the stink names a clock READ — `Date.now(` or a `new Date`
      given no argument (`new Date()`, or one followed by the end of the line, a closing bracket, `.`, `,`, `;` or a
      keyword operator); the world's cycle clock is sanctioned (the one read every widget takes its time from), the
      analog clock's constructor too (a clock built outside a cycle has no cycle time and shows the real time until its
      first tick; a playing test pins the date it draws), and the harness's command pacing (a clock no world reads);
      `EventCommand`'s `@date` / `@dateJSON` were read by nothing — commands are rehydrated from their JSON, never
      constructed — so the class goes, and `AutomatorEventCommand`, whose constructor only called `super()`, becomes
      the root with no constructor. Its `@date.toJSON()` was the tree's one `toJSON(` call, so `check-unresolved-sends.js`'s
      `toJSON` BUILTINS entry went stale and goes too. The baseline stays 13. Proven: `check-stinks-selftest.js` plants
      `bpT = new Date` (the paren-less read) as the stink's spelling, and requires `Date.now()` and `(new Date).getTime()`
      lines to be hits and `new Date bpMs` not; run against the old pattern it fails. The static-checks index's table
      states the rule, its sanctions and what it cannot see (its `wall-clock`, `null-literal`, `instanceof-type-test`
      and `comment-narration` baselines had gone stale: 19, 8, 75, 88 for 13, 6, 74, 87). The independent review's
      findings landed: a `new Date` followed by a symbolic operator (`new Date - @start`, the usual elapsed-time
      spelling, `/ 1000`, `||`, `>`, `?`, …, `instanceof`, `in`, `of`, a trailing loop) is a read too — a `-`/`+`
      counts only when binary (touching `new Date`, or spaced on both sides), since `new Date -x` passes `-x`; the
      self-test plants `new Date - bpStart`, `[new Date]` and `new Date or bpY` as hits and `new Date -bpMs` as a
      value, and fails against the pattern before that fix; a read inside a string interpolation cannot be seen (the
      mask blanks `#{ }`, where `new Date "2020"` would read the same), which the rule and the index state;
      `DETERMINISM.md`'s busy-wait note names the `wall-clock` ratchet, not the `timer` stink. Filed: "The wall-clock
      stink does not see `performance.now()`" (the rule's wording names the wall clock meanwhile), "The automator event
      commands' constructors are code nothing runs".
- [x] **The boot files are a hand-list in the build script** (found closing "Every build tool walks src for itself",
      in the plan's ledger). `build_it_please.sh` cats and compiles the 14 `src/boot` files by name, and
      `check-shippable-coverage.js` exempts `src/boot/` whole, so a new boot file ships nothing and no gate notices.
      Boot's order as data, one list the build and the gates read, is its own design.
      — CLOSED 2026-11-10 (self-ruled). MEASURED by reading: the bundle was the build flags, `source-vault`, the
      generated parts manifest, `globalFunctions` and eight extensions, each `cat` by name, then the shipping parts'
      `bootPrelude` (fizzytiles' `numbertimes`); three standalone scripts were compiled by name; the coverage gate's one
      allowlist entry exempted `src/boot/` whole. Rulings (self-ruled, SURVEY in
      `Fizzygum-tests/.scratch/boot-files-as-data/`): boot's order is data in `parts.json`, reusing the mechanism
      fizzytiles' piece already rode — core declares its `bootPrelude` (the SourceVault first, then `globalFunctions` and
      the extensions) and a new `bootScripts` (`dependencies-finding`, `loading-and-compiling-coffeescript-sources`,
      `logging-div`); the bundle is its generated head (the flags, then the manifest — nothing reads it before boot
      runs) and every shipping part's `bootPrelude` in partition order; `build_it_please.sh` loops over
      `PROFILE_BOOT_PRELUDE` and `PROFILE_BOOT_SCRIPTS` (`buildProfile.py`). `build.py --list-boot` lists every declared
      boot file (flavour-independent; one not under `src/boot/`, missing, or named twice fails the build), and
      `check-shippable-coverage.js` holds the compiled sources to `--list-shippable ∪ --list-boot`, so a boot file no
      part declares is UNSHIPPED; the exemption, the allowlist mechanism and its STALE_ALLOWLIST_PREFIX rule are gone.
      Proven: the coverage self-test plants an undeclared `src/boot` file and one under `src/boot/extensions` →
      UNSHIPPED; the three boot scripts are byte-identical to the previous build's, and the two bundles differ only in
      statement order (the manifest moved) and the build stamp; the gauntlet and `fg homepage`. The independent
      review's findings landed: core's pieces come first in code (`buildProfile.bootPrelude`), never by parts.json's key
      order; the declarations are checked at the build's first step (`buildProfile.py --shell`), so a bad one fails
      naming itself rather than as the coverage gate's operational failure; a `..` in a piece and two boot scripts of
      one name are refused, the "declared twice" line names both parts; `--list-boot` with `--list-shippable` is refused;
      the loop quotes its paths; the boot explainer's bundle table, the vault's "must come FIRST" (it must be defined
      before any batch runs) and six comments state the new shape. Filed: "The boot scripts' names are listed twice",
      "Three tools read `src/boot` for themselves".
- [x] **`find_similar_code.sh` stops at its mirror** (found closing the same item; measured).
      `buildSystem/coffee-to-js-mirror.js` fails on `src/meta/Class.coffee` under CoffeeScript 1 ("unexpected ."),
      exits 1, and the script stops at "mirror compile FAILED". Class.coffee last changed in 7891f3a8, 2243cab7 and
      57959d14 (2026-11-08).
      — CLOSED 2026-11-10 (self-ruled). MEASURED: the failure is `Class.coffee:411`, `while returned = @findUpTo
      remainingSourceLines, @augmentRegex, abortOn: @propertyRegex` followed by its block — a paren-less call ending in an
      implicit object, as a condition, which CoffeeScript 2 (the page's) ends at the line and CoffeeScript 1 (the
      mirror's) reads as continuing into the block; `:440` has the same shape. Not recent: it began at f002a7b7
      (2026-08-16, the commit that gave `Class.findUpTo` its options; 92a010a4, 2026-08-13, compiles), and every
      version since fails the same way; the three November commits above were a guess.
      Ruling (self-ruled, SURVEY in `Fizzygum-tests/.scratch/similar-code-mirror/`): both calls are parenthesized — the
      call's extent explicit to both compilers and to a reader; measured byte-identical JavaScript under the bundled
      CoffeeScript 2, so the page runs the same code. The mirror compiles all 561 files and `find_similar_code.sh` runs
      to its report again (129 structural matches). The independent review compiled the whole file both ways (byte-
      identical) and compared every compiler-inserted token of CoffeeScript 1 and 2 over all 585 compiled sources: no
      other instance, refusing or silently misread. Its findings landed: the mirror's header (where the scan's failure
      message points) states the shape and the remedy, and that a clean mirror is no proof CS1 read a file as the page
      does (`await f()`); the tooling doc says the same, without its stale counts. Filed: "Nothing keeps the
      similar-code mirror working" (an owner trade-off: a build step costs seconds per build).
- [x] **Build freshness reads only the sources' mtimes** (found closing the same item; by reading). An edit to
      `parts.json`, `buildSystem/*`, `src/index.html` or the runtime prelude leaves a stale build reading FRESH, to
      `lib/assert-build-fresh.js` (and every runner that asks it) and to the umbrella `fg status`.
      — CLOSED 2026-11-10 (self-ruled). MEASURED by reading and by plants: the runners' guard
      (`Fizzygum-tests/scripts/lib/assert-build-fresh.js`) and the single runner's and torture's own checks compared
      only `compiledFiles` against the build — the single runner against the harness page's mtime, not the stamp; and
      the stamp, touched at the build's END, let an input edited during the ~57 s build read FRESH, and a build that
      failed kept the previous stamp. Rulings (self-ruled, SURVEY in `Fizzygum-tests/.scratch/build-freshness-inputs/`):
      a build's inputs are the FILES its output is made from, one definition, `buildSystem/lib/build-inputs.js`
      `newestBuildInput()` — every compiled source and `src/index.html`, the build script and its Python, `parts.json`
      and the profiles, each part's declared `assets` and `vendor` pieces, the files the build script names itself and
      every file under `font-assets/` — never the directories holding them; the gates and the pre-compile driver are not
      inputs; `build_it_please.sh` lays `.build-start` before its first input read, removes the stamp at its first write
      to the tree and gives the stamp the marker's time at its end (`touch -r`, checked), so a build that did not
      complete leaves none and an edit during a build reads STALE; `lastBuildTime` and the stamp's path live beside the definition; the guard refuses a listing it
      cannot make (exit 2); the single runner and torture ask the same two answers, and the single runner warns when no
      build completed. The boot minify's exit is checked (it read the next `echo`'s). The FIRST shape walked `src/`,
      `vendor/` and `auxiliary files/` whole with their directories' mtimes, to see deletions; the independent review
      found it counted what the build never reads — a subsystem's `CLAUDE.md`, `.DS_Store`, an editor's swap file, a
      gate's vendored parser — so a docs edit during a gauntlet would refuse every later leg; it was replaced before
      landing. Proven by one-off plants: `src/index.html` or a font file touched → STALE naming it; `src/macros/
      CLAUDE.md` touched, a dotfile made and removed in `src/`, `vendor/acorn` touched → FRESH; a source touched while a
      build ran → STALE once it completed; a build aborted by a failing self-test → "no .build-stamp". The second
      review's findings landed: a fresh clone fetches the vendored SWCanvas BEFORE the start marker (else its first
      build read STALE on inputs it fetched itself); the build clears its scratch at the start (the newly checked minify
      exit could leave intermediates the boot bundle's appends then built on — planted: garbage left in the scratch, the
      next build passes); the old stamp goes only at the build's first write, so a build stopped by an unknown profile
      keeps the tree and stamp it found (planted); the runners' freshness reports refuse a failed listing (exit 2); the
      docs name which runners ask the guard. Filed: "A deleted input leaves a build reading FRESH", "`fg status` reads
      build freshness from the sources alone" (fg is outside the loop), "The sequence runner never asks whether the build
      is stale", "A build that fails a step can still stamp itself".
- [x] **Every tool walks the tooling's own files for itself** (found closing the same item; by reading). About seven
      walks list the `.js` files of `buildSystem/` and `scripts/`, with different skip rules: `lib/what-runs.js`,
      `run-selftests.js` and `check-hand-lists.js` pass over dot directories, `node_modules` and `__pycache__`;
      `lib/tests-repo-code.js`'s scripts walk, dot directories and `node_modules`; `lib/cli-selftest.js`, `node_modules`
      in one walk and dot directories too in another; `find_similar_code.sh`, `node_modules` and `.scratch`. Latent
      today (`scripts/` holds no dot directory). It is the compiled sources' defect on another tree, where
      `node_modules` is real, so it wants a definition of its own.
      — CLOSED 2026-11-10 (self-ruled). MEASURED (a read-only census of every walk, SURVEY in
      `Fizzygum-tests/.scratch/tooling-files/`): thirteen walks, seven rules, and they disagreed TODAY — not latent:
      `scripts/.scratch/` exists (gitignored) and its `cache-oracle-gate/composed-selftest-prelude.js` was read by
      `cli-selftest.js`'s first walk and by the duplicate-code scan (jscpd's ignore globs miss a `../` root) and by none
      of the others; `Fizzygum/scripts/vendor-swcanvas.sh`, which the build LAUNCHES, sat in no root, so the gate census
      never judged it. Rulings (self-ruled): the one definition is the shared walk that already existed,
      `buildSystem/lib/what-runs.js` `scriptFiles(layout)` (it carries the workspace-layout rail run-selftests' bite-proof
      uses) — it gains the `Fizzygum/scripts/` root, refuses a symlink (`TOOLING_TREE_MALFORMED`, as `lib/source-files.js`
      refuses one in the sources), exports `skippedEntry` (dot entries, `node_modules`, `__pycache__`) and a
      `--list-scripts` CLI; `run-selftests.js`'s repo-wide name scan shares `skippedEntry`; `lib/tests-repo-code.js`'s rig
      set, `check-hand-lists.js`'s scan and guard-name set, `scripts/lib/cli-selftest.js`'s
      two walks, and `find_similar_code.sh` / `find_duplicated_code.sh` (`--tests`; jscpd now gets the scripts as files,
      so its `.scratch` filter went) all read it. `vendor-swcanvas.sh` states `not-a-gate` (a vendoring step). Proven:
      the rig set is unchanged (125 files); every self-test and gate passes; one-off plants — the header removed →
      `GATE_WITHOUT_REGISTRY` + `GATE_WITHOUT_PROOF` naming `Fizzygum/scripts/vendor-swcanvas.sh` (so the new root
      reaches the census), a symlink in `scripts/` → `TOOLING_TREE_MALFORMED`; both scans run, no `.scratch` file in
      either. `fg`'s lint (`git status` over changed files) is fg's own (outside the loop). The independent review's
      findings landed: standing cases in `lib/what-runs-selftest.js` (the `scripts/` root — seen failing with the root
      removed — the skipped entries, the top-level rule, the symlink refusal, the CLI); Fizzygum's top level gets the
      same rules as the roots; the shell scans read the list into arrays of `../Fizzygum-tests/scripts/…` paths, so
      where the umbrella lives never enters an argument; a refused tooling tree reads INVALID in `check-call-arguments.js`
      and `check-hand-lists.js`, as a refused source tree does; the guard-name set keeps its scope (widening it let a
      sanction cite `vendor-swcanvas.sh`, which judges nothing); stale comments and the duplicate-code doc's §6.
      Filed: "A hand-list sanction can cite a script that judges nothing" (older than this item).
- [x] **An object inspector hides a widget's own field that shadows a member it inherits** (found by the independent
      review closing "A run that sets a widget field to a function blocks every world snapshot", in the plan's ledger;
      by reading). With "inherited" off (the default), `InspectorWdgt._filteredMemberNames` keeps a member only if the
      subject's own class's prototype defines it or no prototype up the chain does, so a run's `@step = -> …` (an own
      field named like `Widget.step`) is not listed; with "inherited" on, selecting it shows the CLASS's recorded
      source, not the widget's own function (`selectionFromList` walks the class chain before the value's own text).
      What "inherited" should hide for an own field that shadows a declaration is a question for the inspector's
      design: every widget's own state fields (`color`, `bounds`, …) shadow a prototype declaration the same way.
      — its CODE PANE half CLOSED 2026-11-10 (self-ruled); its FILTER half stays open in the BACKLOG, retitled "An
      object inspector's "Inherited" filter hides a value a widget holds under a name a superclass declares", parked
      for the owner. MEASURED (a probe on the live page, `Fizzygum-tests/.scratch/inspector-own-shadow/`): a run's
      `@step = -> 42` on a rectangle is listed only with "Inherited" on, and selected there the pane read `noOperation`
      — `Widget`'s recorded `step` — not the rectangle's function; the world's own listener closures (fields `WorldWdgt`
      declares `: undefined`) read "undefined" the same way. `selectionFromList` was the one place that showed a held
      function as another member's source. RULED: the pane shows the member the subject HAS, read where it is held —
      the first link of the prototype chain holding it decides: held by anything but a Fizzygum class's prototype, it
      reads as the source kept beside it (`<name>_source`), else its compiled text; held by a class's prototype, the
      class walk answers as before (a prototype-level wrapper still shows the CoffeeScript a class up the chain keeps).
      The filter half is a design question (what "Inherited" and "Own props only" mean for an own value), so it is
      parked, its options in the BACKLOG item. LANDED: `InspectorWdgt.selectionFromList`. PROVEN: of 6462 function
      members on the six object and six class inspectors measured, only the world's 17 listener closures read
      differently (now their code; elsewhere a viewport's own `step` and a patch node's compiled formula read their code
      too); the new assertion-only `SystemTest_macroObjectInspectorShowsTheFunctionItsSubjectHolds` (an own `step` reads
      its own text and offers Remove; Saved as `-> 7` and re-selected it reads `-> 7`; a twin reads `Widget`'s source and
      offers no Remove) — two plants applied through `Class.applyMemberEdit` fail exactly its targets: the class walk
      put back first fails the first leg's two pane assertions, the kept source ignored fails the Save leg's; its
      follower clean on both pointers. The independent review's findings landed (the first-holder walk, the Save leg, the
      comment's wording and the walk's old chronological comment, the test's metadata). Filed: "A drag-scroll leaves a
      viewport holding a function no save can write" (measured: a world snapshot is refused after one), "A run that
      replaces a saved method leaves its kept source describing the old one", "An object inspector on a class shows its
      statics as compiled text", "The world's inspector offers to edit its browser listeners", "A function held with no
      kept source shows compiled JavaScript in an editable CoffeeScript pane" (the owner's call).
- [x] **A save writes NaN and ±Infinity as null** (found by the same review; by reading). `Serializer`'s `refFor`
      answers a number as itself, and `JSON.stringify` writes `NaN`, `Infinity` and `-Infinity` as `null`, so a field
      holding one restores as `null`, with no word: the silent drop the serializer otherwise refuses.
      — CLOSED 2026-11-10 (self-ruled). MEASURED (a probe on the live page, `Fizzygum-tests/.scratch/nonfinite-numbers/`):
      NaN, Infinity and -Infinity — in a field, an `$Array` item, a `$Map` key or value, a `$Set` item, an `$Object` prop —
      were written `null` and restored `undefined`; -0 restored as 0; an invalid `Date` restored as the epoch (its `ms`
      NaN, written `null`); a `Color` component NaN was written `null`. A booted world holds none: they come from runs and
      data. RULED: carry them, never refuse (a number has a faithful text; the serializer refuses only what no text
      restores), as a structured reference form `{"$num": text}` (the format's rule: references are structured, never
      in-band strings), for every number JSON does not write as itself (NaN, ±Infinity AND -0, one rule), through one
      encoder and one decoder for every number a record holds (references, `$Date`'s `ms`, `Color`'s `rgba`); a load
      refuses up front a `{"$num"}` naming any other text and a `$Date` time or `Color` component that is no number;
      `FORMAT_VERSION` unchanged (no compat obligations). LANDED: `Serializer.NUMBERS_JSON_CANNOT_WRITE` (the one list) +
      `numberRef`, `Deserializer.numberFrom` + the vetting in `_envelopeShapeProblem`; reference doc §3, §6, §9, §11.
      The first plant showed a `$Date` whose `ms` is no number threw a TypeError in the builder, so the vetting holds
      the format's number fields too. The independent review's findings landed: a save now REFUSES a `Color` whose
      component is no number (a run's string alpha saved, and the load refused the file: the closed-set rule); a
      `Color`'s rgba is vetted as four numbers (a missing one threw after the teardown); the `$num` tests are
      own-property ones (a `{"$num": null}` slipped the vetting); refusal texts are bounded and claim nothing about older
      saves; the vetting walks a record's references once (and no longer copies a `$Map`'s entries quadratically);
      `Color.create` keeps no -0 — its cache key read -0 and 0 as one colour, so a save's bytes would have depended on
      which minted it first; `whyItCanNeverBeRestored`'s promise restated. PROVEN: the probe's every case round-trips
      (`Object.is`); serialization-rig checks `serialize2.numbersJsonCannotWrite` (read back through every reference
      kind; the `$Date` and `Color` forms asserted as written, since interning and NaN make their read-back
      unobservable), `serialize2.colorComponentNotANumberRefused`, `world.loadGuard.unknownNumberTextRefused` (a bad
      text in each reference kind, `null` included) and `world.loadGuard.numberFieldNotANumberRefused` (six bad
      fields) — each fails under its plant (numbers written raw again; texts unvetted; number fields unvetted; the
      save's colour refusal emptied, by recompiling the static from its recorded source), the control green. Filed: "A
      load reads a reference form it does not know as undefined" (with the world section's own reader), "A tag
      record's other fields are not vetted on load", "`Color.create` never checks its components".
- [x] **A snapshot's source edits of a lazy part's classes are dropped when the file holds none of its widgets**
      (found by the independent review closing "A class a lazy part defines after a mixin edit takes the mixin's boot
      member", in the plan's ledger; by reading, not measured). `Deserializer.classNamesIn` reads the object records
      and the well-known keys, never `world.sourceEdits`, so `loadWhatItNeeds` does not load the part a class- or
      mixin-scope record names; `replayClassEdits` / `replayMixinEdits` then pass over a class or mixin the page does
      not have without a word, while the file's registry is installed whole: a re-save carries the record the page
      never ran. On the dev `index.html`: edit `ParentStainerMixin._updateColor` (app-kit) or a `CreatorButtonWdgt`
      member, close every app-kit widget, save, and load the file in a fresh page.
      — CLOSED 2026-11-10 (self-ruled). MEASURED (a probe on the dev `index.html`,
      `Fizzygum-tests/.scratch/lazy-part-source-edits/`): a world file carrying a class-scope edit of
      `CreatorButtonWdgt` and a mixin-scope edit of `ParentStainer` (app-kit), holding none of app-kit's widgets,
      loaded on a fresh page without loading app-kit, installed both records, said nothing, and neither edit was in
      force once the part loaded later; a re-save carried both. A mixin record holds the parsed name ("ParentStainer"),
      the part manifest the source name ("ParentStainerMixin"); and the manifest lists no core sources, so a core
      mixin answers `canEverProvideClass` false. RULED: the part pre-load (`Deserializer.loadWhatItNeeds`) also reads
      the code the file's source edits name — `SourceEditsRegistry.namesOfTheCodeEditedIn`, a class's name and a
      mixin's source name — reusing the one pre-load mechanism; NOT the refusal list (`classNamesIn`): an edit whose
      code no part provides does not make the restore throw (the replay passes it over), and the core-mixin case
      would refuse every file carrying a core mixin edit. So a class-level record the replay does not apply is told by
      the load's existing notice (the lean build's "cannot re-apply"), never dropped in silence, and rides on for a
      build that has the code. LANDED: `SourceEditsRegistry.namesOfTheCodeEditedIn` (a mixin taken by either
      spelling, as `Mixin.named` takes it), read by `Deserializer.loadWhatItNeeds`; the notice counts the class-level
      records the replay did NOT apply (`classLevelRecordCount` − applied: no meta-system, absent code, and a record
      whose source this build does not compile — that last was log-only), the old predicting count deleted; one
      `SourceEditsRegistry.isClassLevel`; the reference doc §9/§11/§12, build-and-packaging's `none` row and both
      explainers (they said such edits are refused: they are told, not re-applied), the `parts` leg rows. PROVEN: the
      probe — app-kit loads with the file, both edits in force; new sections of `parts-snapshot-load-headless.js` (the
      `parts` leg): `SOURCE_EDITS_LOAD_THEIR_PARTS` — a class-only and a mixin-only file, each on its own page, each
      needing no part through its classes, each edit in force after the load (the mixin's on the consumer's live
      member), nothing said — and `UNREPLAYABLE_EDITS_ARE_TOLD` (an edit of a class no part provides, and one that does
      not compile here: the file loads, one inform each, the record kept); the bite-proof plants each half of the name
      mapping and the notice counting nothing, 8 of 8 rules. The independent review's findings landed (the split
      files, the counted-not-predicted notice, the live-member check, the precondition as the pre-load's own
      question, the docs drift). Filed: "A return to boot that fails is only logged", "A world file's source-edit
      list is not vetted on load", "No gate loads an edit-carrying world on a `sources: "none"` or `"lazy"` tree".
- [x] **A drag-scroll leaves a viewport holding a function no save can write** (found by the independent review
      closing "An object inspector hides a widget's own field that shadows a member it inherits", in the plan's
      ledger; measured). `ViewportWdgt._stopDragScrollStep` — at the next press, and where a stroke's glide ends — and
      the auto-scroll's end stop the step by assigning `@step = noOperation`: an OWN function with no kept source, and
      `step` is no serialization transient. Measured on `index-sw.html`: a ListWdgt after `_stopDragScrollStep`
      refuses a world snapshot and its own save ("the function-valued property .step has no editable source and is not
      a serialization transient"), and a copy owns the `step` too. A press on a lone drag-scrolling pane takes the
      stroke (`pressBegan` → `takeStrokeScrollFrom`). serialization-duplication-reference.md's "scroll-momentum `@step`
      closures simply stop" names a transient no class declares. Shape: end the step by deleting the own field (the
      class's `step` shows through), and decide what a save during a stroke writes.
      — CLOSED 2026-11-10 (self-ruled). MEASURED (`Fizzygum-tests/.scratch/viewport-own-step/`): the probe as filed,
      and every instance — ViewportWdgt is the only class assigning its own `step`: the stroke's closure
      (`takeStrokeScrollFrom`), the edge auto-scroll's closure, and `noOperation` at both ends. Beyond the refusal after a
      stroke: a save DURING a stroke or glide was refused too, and a COPY made mid-gesture was aligned into the stepping
      set holding the original's bound closure — it stepped the original's scroll each frame and never left the set. No
      viewport subclass defines a `step` of its own. RULED: the gesture's step is runtime state, never a member: it
      lives in `_scrollStep` (undefined while no gesture runs), a `@serializationTransients` entry (a restored world has
      no gesture in progress), dropped by a copy (`_reactToBeingCopied`, which also leaves the stepping set it was
      aligned into); ViewportWdgt's class `step` runs it, and the stroke's ending calls it directly. So `step` is never
      an own field unless a person makes it one. Rejected: deleting `step` at the two stops (leaves the mid-gesture
      refusal and the copy driving its original); declaring `step` itself a transient (would drop a person's own `step`
      method from a save in silence). LANDED: `ViewportWdgt` (`_scrollStep`, `step`, `_reactToBeingCopied`, the four
      sites, `pressEnded`/`pressCancelled`); the reference doc §5's line (it named a transient no class declared).
      PROVEN: the probe — after a stroke the world and the widget save, a copy owns no `step`; the new assertion-only
      `SystemTest_macroDragScrolledPaneStillSaves` (a real background drag-scroll under both pointers, then both saves;
      a copy made mid-stroke stays out of the stepping set) — two plants fail exactly their targets (the old own-step
      assignment back; the copy keeping the scroll step), its follower clean on both pointers. The independent
      review's findings landed: the two toolbars overriding `_reactToBeingCopied` without `super` (TextToolbarWdgt,
      PaintToolbarWdgt) call it, else their copies still drove the original; a viewport saved mid-gesture came back in
      the stepping set with nothing to step, so a restore and a copy leave the set unconditionally and "a gesture of
      mine runs" is one predicate (`_scrollStep?`) everywhere; a person's or a subclass's own `step` replaces the
      class's as any override does, so it calls `super` to keep the gestures scrolling (ruled, stated where `step`
      is); the test now saves, restores and copies MID-stroke, and plants prove each: the scroll step taken out of the
      transients fails the mid-stroke saves, a restore keeping its membership fails the restore's check; ListWdgt's
      false comment on `step` deleted. Filed: "A viewport's gesture bookkeeping outlives its gesture", "Widget's
      `step` documentation is false", "A hook override that skips `super` is unguarded", "An object inspector removes
      its list's contents from a set nothing adds them to".
- [x] **A runtime object stamped derived is dropped from an inspector holding it** (found by the independent review
      closing "A value answering `rebuildDerivedValue` is dropped from a save, and breaks a copy, wherever it
      stands", in the plan's ledger; by reading, not measured). A value a class stamps with a no-op
      `rebuildDerivedValue` (`FridgeMagnets3DCanvasWdgt._markTransient`: its `transforms`, `meshCache`,
      `lclCodeCompiler`, `surface`, `depth`, `engine`, `imageData`) is derived wherever it stands
      (`NativeValueKinds.isDerivedAt`), so an inspector opened on one (a 3D pane's member row, double-clicked) loses
      its subject on a Duplicate (the copy's first re-lay throws in `_subjectIsEditable`) and on a world save (the
      restored inspector throws at every re-lay) — what a canvas context did before it became derived only beside its
      canvas. Such a value is derived where its holder rebuilds it: the class that stamps it (its
      `@serializationTransients` names the same fields), not an inspector.
      — CLOSED 2026-11-10 (self-ruled). MEASURED (a probe on index-sw.html, `Fizzygum-tests/.scratch/derived-at-home/`):
      worse than filed — a Duplicate of an inspector on the 3D pane's `transforms`, `meshCache` or `surface` THREW in
      the copy (its subject came back undefined), and a world save SUCCEEDED, dropping the subject in silence; the pane
      itself copies (its runtime rebuilt) and saves. RULED: a value that rebuilds itself is derived WHERE ITS HOLDER
      REBUILDS IT — a canvas context beside its canvas (as before), any other in a field its holder's class declares
      in `@serializationTransients` (the declaration the pane already makes; the Duplicator skips no field for being
      declared there, which is why the pane stamps) — and anywhere else it is a page object: the copy keeps it by reference, the save
      refuses it, one remedy for every kind. The canvas context's own special cases in the two walkers became the one
      rule (`Duplicator._duplicate` keeps any value answering `rebuildDerivedValue` by reference; the Serializer refuses
      one at the top of `populateRecord`, the context-only remediation deleted). LANDED: `NativeValueKinds.isDerivedAt`,
      `Duplicator._duplicate`, `Serializer`; the pane's comment; the reference doc §2/§5 — including its guidance for a
      runtime-only object (stamp AND declare: the stamp alone now makes a page object). PROVEN: the probe — the copy
      keeps the subject, the save is refused naming `.inspectedObject`; new serialization-rig checks
      `paneRuntime.derivedInThePanesOwnFields`, `inspector.onAPaneRuntimeValueDuplicates`,
      `inspector.onAPaneRuntimeValueRefusesTheSave` (the pane's runtime fields derived from its declaration, both
      backends), the context checks green under the shared remedy — four plants (stamped values derived everywhere; derived
      nowhere; the copy deep-copying them; the save not refusing them) each fail their checks. The independent
      review's findings landed: ONE test of "rebuilds itself" (`NativeValueKinds.rebuildsItself`: it answers a
      rebuildDerivedValue FUNCTION — a field of that name holding anything else used to count) in all three sites; the reference doc's "the Duplicator never consults `@serializationTransients`" (now
      false) restated, §6 says such a value is asked about before any handler; the rig waits for the pane's first
      render (its engine fields were otherwise unjudged) and asserts a copy's runtime field is DROPPED; the remedy
      also names a field a run filled. Filed: "Three plans teach a stamp without its declaration", "Nothing holds every
      stamped field to its declaration", "An inspector's Duplicate throws on a subject the copier refuses", "Is an
      inspector's subject always a page object?" (the owner's).
- [x] **A load reads a reference form it does not know as undefined** (found closing "A save writes NaN and
      ±Infinity as null", in the plan's ledger; by reading). `Deserializer.resolveRef` answers any object value carrying
      none of `$r`, `$wk`, `$ext`, `$num` (a `$src` is compiled apart) with `undefined`, and `_envelopeShapeProblem`
      does not vet the forms: a file holding one — a newer build's form, a hand-edited file — loads with that value
      silently gone. The world section has its own reader (`WorldWdgt.loadWorldSnapshot`'s `resolve`), which hands an
      unknown object back raw, and nothing vets the section (`children`, `bin`, `shelf`, `alpha` take anything).
- [x] **A tag record's other fields are not vetted on load** (found by the independent review closing "A save writes
      NaN and ±Infinity as null", in the plan's ledger; by reading). `_envelopeShapeProblem` holds a `$Date`'s time and
      a `Color`'s components to numbers, but a `$Canvas`'s `w`/`h`/`pr`/`data` and a record's `iid` take anything: a
      malformed one throws after a world load's teardown, or builds garbage in silence.
- [x] **A world file's source-edit list is not vetted on load** (found by the same review; by reading).
      `_envelopeShapeProblem` does not look at `world.sourceEdits`: a non-array (`fromRecords`' `.slice`) or a `null`
      entry throws after the teardown and leaves an empty desktop, and on a `sources: "lazy"` tree
      `_needsTheReflectiveLayer` throws a TypeError before it.
      — the three CLOSED 2026-11-10 together (self-ruled; loop unit U3, "the load vets the whole envelope up front").
      MEASURED (`Fizzygum-tests/.scratch/envelope-vetting/probe.js`, one corruption per fresh page): THROWN AFTER THE
      TEARDOWN, leaving an empty or broken desktop — an unknown reference form as an `$Array` item or a world child, a
      `$Canvas` of no size, a `$Set` with no items, a source-edit list that is no list or holds `null`; LOADED SILENTLY
      WRONG — an unknown form in a field (gone), a raw `bin`, `children` that are no list (an EMPTY desktop, no word), a
      string `alpha`, a `{$r}` past the table, a `$Canvas` with no data, `$Array`/`$Map`/`$Object` fields of the wrong
      shape, a string `iid`, a source edit with no scope. RULED: the load's own rule applied whole — a file a restore
      would throw on or get wrong is refused up front, the desktop kept — with one home for each kind of knowledge:
      each TAG states its record's shape in its `TAG_BUILDERS` entry (beside its build and populate; item 11's
      `$Date`/`Color` number checks fold in), ONE reference-form check (`Deserializer._refProblem`), a class record's
      own fields (`_classRecordShapeProblem`), ONE world-section check (`_worldSectionProblem`, every field the save
      writes; an info-doc flag only under an `infoDoc…` name, since the load sets each on the world); the world loader's
      own resolver is deleted for the Deserializer's (`resolve`, one reader of the forms). LANDED: `Deserializer`,
      `WorldWdgt.loadWorldSnapshot`; the reference doc §3/§9/§11. PROVEN: the probe's 17 corruptions each refused up
      front, the desktop kept; every real save still loads (both serialization rigs green); serialization-rig load
      guards `world.loadGuard.unknownReferenceFormRefused`, `malformedRecordRefused`, `malformedWorldSectionRefused`
      (both backends), each failing under its plant (references unvetted; record shapes unvetted; the section
      unvetted), with the earlier number guards. The independent review's findings landed: a section reference must
      name a record of the KIND its place holds (children and app windows a widget's — judged when the class is
      resident, the door's re-entry judging a lazy one; the bin a `BinWdgt`'s, the shelf a `ShelfWdgt`'s, the
      preferences and desktop colour their classes') — a `Point` child still threw after the teardown and a non-bin
      bin would have stopped the world loop; a widget file's `root` is vetted the same way; `memberships` must be a list
      on a widget's record; an own `__proto__` in props is refused; the one false refusal (a zero-sized canvas's
      `"data:,"`) accepted; the source-edit record shape moved to its writer (`SourceEditsRegistry.isARecord`, a unique
      id optional as declared); the dead `shells` field deleted; the type test `_couldBeAWidgetClass` sanctioned in
      `check-stinks.js` (a class a file names, judged before an instance exists). Rig: (1i)/(1j) plant a `Point` child,
      a non-bin bin, memberships on a non-widget, an own `__proto__`; ACCEPT CONTROL `world.loadGuard.wellFormedEdgeShapesAccepted`
      (six edge shapes a save writes pass), `widgetFile.rootVetted`; plants: kinds unjudged, an over-strict vetting
      (caught by the accept control). Filed: "A `$Canvas`'s size is not bounded by the backend's surface",
      "Duplicate or over-counter iids load", "Some envelope fields are type-checked only", "A user object with an own
      `$wk` key saves and then is refused", "A widget file's source edits pre-load parts", "The info-doc prefix has four
      homes".
- [x] **A return to boot that fails is only logged** (found by the independent review closing "A snapshot's source
      edits of a lazy part's classes are dropped when the file holds none of its widgets", in the plan's ledger; by
      reading). `SourceEditsRegistry.returnThePageToBootSources` catches a member it cannot return and only
      `console.log`s it, after the teardown: the loaded world then runs the page's edited member where the file
      expects boot's, with no word to the person and no gate token.
- [x] **No gate loads an edit-carrying world on a `sources: "none"` or `"lazy"` tree** (found by the same review; by
      reading). The lean build's "cannot re-apply" notice and a lazy build's trip order (the part, then the reflective
      layer, then the replay) are proven by reading only: the rigs that load worlds with source edits drive the dev
      tree, and `fg homepage`'s smoke round-trips a snapshot that carries none.
      — both CLOSED 2026-11-10 (self-ruled; loop unit U4, with "A load judges an app key's kind by the page's edited
      members" PARKED for the owner, its options in the BACKLOG item). RULED: what the return to boot could not undo is
      told in the load's ONE notice, beside the records the replay did not apply, COUNTED after the replay rather than
      predicted from the return — `SourceEditsRegistry.returnThePageToBootSources` answers {returned, unreturned}, the
      members it LEFT each with the source it was left running, and `SourceEditsRegistry.stillRunning` counts those that
      still hold it once the replay is done (a file's own record of such a member replaces it, and is then not told):
      "The loaded world still runs N edited class member(s) of this page: … did not return to … source at boot." No
      gate token for an unreturned member: the product's rail is the person's notice, which the rig's checks prove, and
      a token would fail the one check that plants the failure. And the production smoke loads an edit-carrying world
      on a production tree, reading what must follow off the TREE (`BUILDFLAG_SOURCES`), never off its own flags.
      LANDED: `SourceEditsRegistry`, `WorldWdgt.loadWorldSnapshot`; the `smoke-boot-headless.js --production` leg (a
      fresh page: the booted world's own file plus class-scope edits — always a CORE class's, `StringWdgt`, whose
      meta-object only the reflective layer's ingest provides, and app-kit's `CreatorButtonWdgt` where app-kit is absent
      at boot, on a file that needs app-kit for nothing else; on `sources: "lazy"` the part, then the layer, then both
      replayed, nothing said; on `sources: "none"`, told once that the edit cannot be re-applied); both legs that load
      code on a precompiled tree check their boot wait; the reference doc §11/§12, `Fizzygum/CLAUDE.md`'s lean bullet,
      build-and-packaging §8, the boot explainer, the tests CLAUDE.md, the lean profile's own note (it said such edits
      are "refused"). PROVEN: the serialization rig's `sourceEdits.unreturnedPageEditIsTold` (a page member whose return
      the rig makes fail: one notice, the member still on the page) fails, alone, under a plant reporting no member left,
      and `sourceEdits.unreturnedPageEditTheFileReplacesIsNotTold` (the file's own record replaces it: no notice, the
      file's version in force) fails, alone, under a plant telling every member left; the production smoke passes on
      `homepage`, `lean` and `dev-precompiled` (`build_and_smoke.sh --profile …`), and fails on homepage under a plant
      skipping the reflective layer (the core edit not in force, a notice) and under one pre-loading no edit's code
      (app-kit not loaded, a notice). Measured: the whole production smoke takes 6 s.
- [x] **A run that replaces a saved method leaves its kept source describing the old one** (found by the same review;
      by reading). `Widget.injectProperty` keeps `<name>_source` beside the function it compiles; a run that reassigns
      the field (`@m = -> …`, `Widget.evaluateString`) leaves the companion in place. The inspector's pane, a save's
      `{"$src"}` (which the load compiles back) and `_sourceChangedNoSettle`'s own-code key then all read the OLD
      source: a save silently restores code the widget no longer ran. Its mirror: a run that deletes the own function
      while a class still declares the name leaves an orphaned `<name>_source`, which the inspector hides as a
      companion (`_isACompanion`) and a save carries as a string.
- [x] **A text's measurement, wrapping and split caches name no code of its own** (found by the independent review
      closing "A palette's back-buffer key names its class and extent, not code of its own", in the plan's ledger; by
      reading, not measured). `Widget._ownCodeKeySuffix` keys a text's back buffer and its two top-level text caches
      (TextWdgt's wrap and line breaks), but four shared caches its code also fills do not carry it:
      `cacheForParagraphsWrappingData` (`TextWdgt.coffee`, filled through `@measureText`), `cacheForTextMeasurements`
      (`StringWdgt.coffee`), and the paragraph and word split caches. Twin texts of one font, width and paragraph: an
      inspector Save of A's own `measureText` misses at A's top-level key and then hits the paragraph entry B filled,
      so A's edit never shows; after a flush, whichever wraps first fills the entry for both.
      — both CLOSED 2026-11-11 (self-ruled; loop unit U5). RULED: the source belongs to the FUNCTION, and only to a
      function the injection makes; and a shared cache is keyed by a widget's own code wherever its work runs that
      code. LANDED: `Widget.injectProperty` keeps the source WITH the function it compiles, in a weak store keyed by the
      function (`Widget._keptSources`, a WeakMap: it writes to no function and keeps none alive), and only when txt
      SPELLS a function literal — read from the lexer's tokens (`Widget._spellsAFunctionLiteral`: the first token the
      person wrote opens a parameter list or is the arrow), so a txt naming a function (`@f`, a class member,
      `Math.max`) keys nothing and the function it names keeps the source it has, or none. ONE accessor,
      `Widget.keptSourceOf`, is read by the object inspector, the own-code key (`_sourceChangedNoSettle`) and the save's
      `{"$src"}` (`Serializer`). The `<name>_source` field, its two followers (`removeOwnProperty` /
      `renameOwnProperty`) and the inspector's companion rule for it are gone, so a run that replaces or deletes a member
      takes the member's source with its function, and no orphan can be left. `TextWdgt.getWrappingData` (whose work
      runs `@measureText`) and `StringWdgt.measureText` (whose work runs `@eliminateInvisibleCharacter`) key their caches
      with `@_ownCodeKeySuffix`, as the top-level two and the back buffers do; the paragraph and word splits run no code
      of the widget's (a plain `text.split`, like the font-box static) and stay keyed by their text. No compat
      obligation for files carrying `<name>_source` strings (owner standing rule): such a field loads as the plain
      string it is. The independent review found the first shape keyed whatever function an injection left — so an
      inspector Save of `@f` naming a run's function gave it the source "@f", whose save no longer refused and whose
      load ran `@f = @f` — which the literal rule closes; it also showed the split keys guarded nothing. PROVEN:
      `SystemTest_macroObjectInspectorShowsTheFunctionItsSubjectHolds` gains a save of the kept source and a "replaced"
      leg (a run replaces the saved method: the pane shows the run's function, a save refuses it naming it), whose two
      assertions alone fail under a plant keeping a source per widget and member name (the old field's behaviour); the
      new `SystemTest_macroTextOwnCodeKeysTheCachesItRunsIn` (twin texts; one given its own measureText, then its own
      eliminateInvisibleCharacter, by inspector Saves) fails under a plant dropping the own-code key from the
      paragraph-wrapping key, and exactly at its measured-widths leg under one dropping it from measureText's key; the
      serialization rig's `serialize2.runReplacedMethodIsRefused`, `serialize2.keptSourceFollowsItsFunction` and
      `serialize2.keptSourceSurvivesACopyAndALoad` (replacing the two guards that existed for the field's drift,
      `functionSourceMustBeOwn` / `functionSourceMustBeAString`) each fail under their plant (a source per name; a
      rename that hands over a new function; every function keyed, literal or not).
      `SystemTest_macroInspectorOffersOnlyWhatItsSubjectOwns` drops its `_source` companion half. Followers clean on both
      pointers.
- [x] **`Color.create` never checks its components** (found by the same review; by reading). It rounds r, g and b and
      takes any alpha, so a run's `Color.create 200, 0, 0, "0.5"` makes a colour whose cache key ("200,0,0,0.5") is the
      number alpha's too: the first one minted is every later `Color.create 200, 0, 0, 0.5` on the page. (A save
      refuses such a colour, naming it.)
      — CLOSED 2026-11-11 (self-ruled; loop unit U6). RULED: a colour HOLDS NUMBERS, normalized in one place both
      doors read — never refused: a component given as anything else is read as a number, as the house's numerical
      pins read their input (Number). LANDED: `Color._channel` (Math.round of the number, -0 to 0) and `Color._alpha`
      (the number, -0 to 0), read by `Color.create` BEFORE it keys and by the constructor, so a string alpha "0.5" is
      the number 0.5 — one key, one instance, holding a number, whichever spelling is minted first — and `new Color`
      keeps no -0 either (it used to, against the reference's "a save's bytes do not depend on which spelling came
      first"). No Color can then hold a non-number, so the save's own refusal of one (`Serializer`'s Color branch) is
      unreachable and is deleted — the load's vetting of a FILE's Color records stays (a file is outside input). The
      first shape REFUSED a non-number component, after a census (the suite, the menu sweep, the apps smoke and the
      pin sweep, under a prelude failing on any non-number reaching `Color.create`) met none; the independent review
      showed it would have broken a path the census could not see — a spreadsheet formula over a text cell
      (`new Color A1, 0, 0`, A1 reading "200"), which Math.round had always read as 200 — so the rule follows the
      house's convention for numerical input instead. Whether a non-finite or out-of-range component should be
      refused or clamped is FILED for the owner. Docs: the serialization reference §3, `immutable-value-classes.md`.
      PROVEN: the serialization rig's `serialize2.colorComponentsAreNumbers` (a number alpha then its text, and the
      reverse: one instance, a number held; a text red and alpha through `new`; a -0 red and alpha through `new` held
      as 0; the string-minted colour saved as four numbers and loaded back as that very instance) fails under a plant
      restoring the old create and constructor.
- [x] **An object inspector on a class shows its statics as compiled text** (found by the same review; by reading).
      `Class.staticPropertiesSources` keeps a class's static members' CoffeeScript; `selectionFromList` on a class
      FUNCTION (`inspectorClassFor`) never reads it, and a static `extend` copied down has its source on the parent.
      — CLOSED 2026-11-11 (self-ruled; loop unit U7). RULED: a static function's pane shows the CoffeeScript recorded
      for THAT function, else its compiled text — never another class's code for a function this one does not run.
      LANDED: `InspectorWdgt._recordedStaticSourceOf`, asked in `selectionFromList`'s holder branch after
      `Widget.keptSourceOf`: for a Fizzygum class function, its own class's record when that class declares the static,
      else the record of the first class up `superclassOf` that owns that VERY function under the name (a static
      `extend` copied down); each store read for its OWN entries (a plain object's prototype answers `constructor`,
      `hashCode`). Static FIELDS keep showing their value. The first shape read an ancestor's record by NAME, mirroring
      the prototype class walk; the independent review showed it then put Widget's code in the pane for a static a run
      had replaced on RectangleWdgt, where the identity test falls back to compiled text, which is true — so the walk
      takes the test. A static a class itself declares and a run then replaced still reads as its record: FILED with
      its prototype twin, with how statics could be made checkable. Docs: `mixins.md`, MACRO-PATTERNS (an entry).
      PROVEN: the new assertion-only `SystemTest_macroObjectInspectorOnAClassShowsItsStaticsSource` (Color's own
      `create`; PasteInputEvent's override of `fromBrowserEvent`; RectangleWdgt's copied-down `keptSourceOf`, then that
      copy replaced as a run does; Widget's harness-installed `widgetFromUniqueIDString`, recorded nowhere) fails its
      four record-expecting pane assertions under a plant restoring the old reading, and exactly the replaced case
      under the first shape. Follower clean on both pointers.
- [x] **The rigs wait for their pages to boot a dozen ways, most of them in-page and unbounded** (found closing "The
      suite's probe page waits for boot its own way", in the plan's ledger; by reading). A rig that boots a product
      page waits for its world its own way: `scripts/lib/headless-boot.js` `inPageWaitReady` (one raw in-page poll,
      given 60–120 s, bounded by `answerWithin` only in `smoke-apps-headless.js`; the graph and serialization rigs
      wait on it raw, and the menu and pin sweeps also discard its answer, so a world that never arrives meets their
      sweep as a raw TypeError), and local copies in `smoke-boot-headless.js` (`inPageWaitFor`),
      `parts-lazy-icons-headless.js` (its own `inPageWaitReady`), `parts-lazy-load-headless.js`,
      `parts-snapshot-load-headless.js`, `serialization-file-roundtrip-headless.js`,
      `staleness-census.js`, `derive-inspector-churn-set.js` and `generate-pre-compiled-headless.js`, each with its own
      predicate, bound and line. A page stuck while it boots is waited on until the protocol timeout. The runners'
      pages share `startedWithin` (`lib/headless-driver.js`); a rig's page asks a different question (a product world,
      no harness), so the rigs' one wait is `startedWithin` with a predicate of their own beside `HARNESS_WORLD_STANDS`.
- [x] **The sequence runner never asks whether the build is stale** (found by the second independent review closing
      "Build freshness reads only the sources' mtimes", in the plan's ledger; by reading). `run-sequence-headless.js` —
      presuite's `fracplane` rider and every new test's follower proof — boots the harness with no
      `lib/assert-build-fresh` call, so an edit not yet built is tested as if it were in the build, passing or failing
      vacuously; the suite and single runners refuse such a build.
      — both CLOSED 2026-11-11 (self-ruled; loop unit U8). RULED: one boot wait for every page a script boots, and
      every runner asks whether the build is stale. LANDED: `lib/headless-driver.js` `PRODUCT_WORLD_STANDS` beside
      `HARNESS_WORLD_STANDS` (a WorldWdgt in `window.world` with its render canvas, canvas and context; with
      `{ booted: true }`, `stillLoadingSources === false` too) and `notStartedLine` (why a page did not start, as a
      sentence — a lost page's own line said whole); graph-liveness, parts-lazy-icons, the menu and pin sweeps,
      smoke-apps, both serialization rigs, the two parts load rigs (`booted`), the staleness census, the boot smoke
      (its boot `booted`, since its probes load code on a precompiled tree, and its two legs) and the HiDPI check each
      wait through `startedWithin` with it and read its answer by their subject: a boot check (the boot smoke, the HiDPI
      check, smoke-apps' launch pages, WORLD_NOT_READY) fails it; any other rig has measured NOTHING, its own INVALID /
      exit-2 path (the menu and pin sweeps, which discarded the answer and would have swept no world, now throw to
      theirs). `lib/headless-boot.js` `inPageWaitReady` and the local copies are deleted. A wait for something other
      than a world standing stays its own (derive-inspector-churn-set's in-page plant poll, generate-pre-compiled's
      harvest signal, the boot smoke's text-settle and reflective-layer waits — their missing outside bound FILED).
      `run-sequence-headless.js` asks `lib/assert-build-fresh` before it launches (its `--list` / `--before` listings
      exempt). Docs: the tests CLAUDE.md, build-and-packaging §6, the guard's header, the sequence runner's help.
      PROVEN: the menu sweep under a plant whose world never arrives exits 2 with "the page did not start within 90s —
      nothing was swept" after the shared bound; smoke-apps' self-test plants the shared `NEVER_STARTS` on a launch page
      (WORLD_NOT_READY) and on every page (INVALID) and pays the shared 90 s bound for each, as the runners' DID_NOT_START
      proofs already do (no flag shortens it; the selftests leg measured 319 s before, 326 s after); the sequence runner
      refuses a build an input is newer than, exit 2; two gauntlets green with every touched rig, `fg homepage` green
      (the boot smoke on the production tree), and by hand the boot smoke on the dev tree, on `--profile lean`, and the
      HiDPI check.
- [x] **A deleted input leaves a build reading FRESH** (found closing "Build freshness reads only the sources'
      mtimes", in the plan's ledger; by reading). Freshness compares the newest mtime among the files a build is made
      from (`buildSystem/lib/build-inputs.js`) against `.build-stamp`; a file DELETED since the build moves no
      surviving file's time, so a removed class source (or a removed asset) leaves the build reading FRESH while it still
      ships what is gone. The build could record the input list it read beside the stamp, and the check compare the
      two lists as well as their times.
- [x] **A build that fails a step can still stamp itself** (found by the same review; by reading). `build_it_please.sh`
      checks the boot minify's exit, but not the SWCanvas fetch (`vendor-swcanvas.sh`), the boot `coffee -b -c`
      (caught only through the minify that follows), the SWCanvas bundle's `cat`s, the `bootScripts` loop's
      `coffee`/`terser`, nor the `cp`s of the pre-compiled stub and `font-assets`: one of them failing still ends with a
      stamp, and the runners test a tree that is missing a piece.
      — both CLOSED 2026-11-11 (self-ruled; loop unit U9). RULED: the build records WHAT it read — each input as it
      was when the build began — outside the tree it writes, and every command that builds, copies, links or removes
      the tree's contents checks its own exit. LANDED: `buildSystem/lib/build-inputs.js` `buildInputs()` (profiles'
      `*.json` only now, not an editor's backup beside them), `--record <start marker>` (each input's path, mtime and
      size, headed by the marker's time), the pure `compareRecords`, and `buildStaleness()` — the ONE freshness question
      every reader asks (the runners' guard, the single runner's capture-path warning, torture's report; the old
      newest-mtime-against-the-stamp check folds into it). `build_it_please.sh` writes the record with the start marker
      to `Fizzygum/.latest-build-inputs.reading` (gitignored), removes the previous stamp and record at its first write,
      and promotes the record as it stamps; node is checked up front (the build needs it whatever it skips); the stamp
      step names a concurrent build again; `build_failed "<what>"`, the script's own error idiom in function form, on
      every formerly unchecked step (the SWCanvas fetch, the boot compile and its harness-check strip, the parts
      manifest's join, the bundles' `cat`s, the cleanups and directories, the tests link, the font-assets copy, the boot
      scripts' compile and minify, the stub and video copies, the pre-compiled image's strip, minify and move, lean's
      drops); font-assets copied AFRESH, so a font deleted from the source leaves the tree; `build.py`'s escape refusal
      exits 1 (a bare `exit()` ended it with status 0 half-way, and the build stamped a tree with no parts manifest or
      entry pages). The independent review found the first shape kept a names-only record INSIDE the tree (464 KB in
      every artifact, the lean appliance's included, and an `fg fingerprint` that could never read identical), missed a
      file put back with an older time, kept serving deleted fonts, and still had build.py's exit and a dozen steps
      unchecked: each is fixed above. Docs: build-and-packaging §6, the tests CLAUDE.md, the guard's, the build's and
      build-inputs.js's own comments. PROVEN: `build-inputs-selftest.js` (node tier, every build: an edit, an older
      time, another size, a deletion, an old-time addition, a rename each read as a change; unchanged and reordered as
      none); by hand, on the final shape, a font asset given an older time reads STALE (changed), its time put back
      reads fresh, moved away reads STALE (gone) and is GONE from the tree a rebuild then makes; a vault escape character
      planted in a class source stops the build at build.py with no stamp and no record; the pre-compiled stub moved
      away stops it at its copy (first shape, same helper); the gauntlet and `fg homepage` green on the final shape.
- [x] **The boot scripts' names are listed twice** (found by the independent review closing "The boot files are a
      hand-list in the build script", in the plan's ledger; by reading; low). `parts.json` core's `bootScripts` names the
      three scripts the build compiles, and `src/boot/globalFunctions.coffee` fetches them by hand-written name
      (`js/src/dependencies-finding-min.js`, `…loading-and-compiling-coffeescript-sources-min.js`,
      `…logging-div-min.js`), as `build_it_please.sh`'s lean drop names `dependencies-finding-min.js`: rename one side
      and the build stays green while the page fails its fetch at boot, caught only by a boot.
- [x] **Three tools read `src/boot` for themselves** (found by the same review; by reading; low).
      `check-coffee-syntax.js` takes "the helper globals boot provides" from every `src/boot` file (the later-loaded
      `bootScripts` and fizzytiles' piece included), `check-part-edges.js` attributes every boot file to core, and
      `what-pins-core.js` roots its walk in all of them; each could read `build.py --list-boot` (its pieces in order,
      by the part that declares them) instead of walking the directory.
      — both CLOSED 2026-11-11 (self-ruled; loop unit U10). RULED: parts.json is the one definition of the boot files,
      read through ONE listing, and a GATE holds boot's by-name fetches to it. LANDED: `build.py --list-boot` prints each
      declared piece as `<file>\t<part>\t<prelude|script>` (`buildProfile.bootFiles` answers the tuples and refuses, with
      its other malformations, a boot script that is no `.coffee` file), read through `buildSystem/lib/boot-pieces.js` by
      the coverage gate (its files, and the fetches), the syntax gate (the helper globals from CORE's boot files —
      measured: the compile scheduler, a core boot SCRIPT, assigns `hasProp`/`indexOf`/`slice`, so "the bundle only"
      would refuse the real tree, as that gate's own self-test showed at once), the part-edges gate (each file in its
      own part; an empty listing refused) and `what-pins-core.js` (rooted in core's files and every shipped part's
      bundle pieces, listed once at load). `check-shippable-coverage.js`'s two new rules: BOOT_FETCH_UNDECLARED (a
      `js/src/<name>-min.js` in a boot file's CODE, its comments blanked by `lib/coffee-mask.js`, that is no boot script
      of the fetcher's own part, named file:line) and BOOT_SCRIPT_UNFETCHED (a declared script its part's boot files
      never fetch so). Lean's drop of the reflective layer's script fails a lean build when that file was not built.
      The first shape put the fetch check inside `buildProfile.py`, whose header says it judges no code — a rule the
      gate census therefore never asked a proof of, over raw text that counted a comment as a fetch; the independent
      review caught both, and the rule moved to a gate. Docs: build-and-packaging §1, the static-checks index (the
      gate's row, §3c). PROVEN: `check-shippable-coverage-selftest.js` plants a fetch renamed in globalFunctions alone,
      firing exactly both rules by their own lines, and its control carries a comment naming a retired script and
      passes; the four readers' self-tests pass; a lean build and smoke pass by hand.
- [x] **The wall-clock stink does not see `performance.now()`** (found by the independent review closing "The
      wall-clock stink does not see `new Date` without parentheses", in the plan's ledger; by reading). Its rule names
      the WALL clock (`Date.now()`, a `new Date` given no argument); `performance.now()` is a clock read it never
      counts: `WorldWdgt.doOneCycle`'s `cycleStartPerfMs` (the end-of-frame compile budget, every cycle) and seven in
      `src/boot/loading-and-compiling-coffeescript-sources.coffee` (the compile scheduler's per-frame budget). A
      `performance.now()` added to render or layout code passes unseen. Each needs counting and sanctioning (a budget
      that paces work, never what a widget draws) or fixing.
      — CLOSED 2026-11-11 (self-ruled; loop unit U11). RULED: one stink for every clock read, named for what it
      counts. LANDED: `check-stinks.js` `wall-clock` is now `clock-read` and also counts `performance.now()`, either
      clock existentially too (`performance?.now()`, `Date.now?()`); its eight `performance.now()` reads are
      sanctioned by member, each reason saying the condition it rests on — the compile scheduler's frame budget
      (`WorldWdgt.doOneCycle`'s cycle start, `SourceCompileScheduler.drainAtEndOfCycle` and `_drain`) decides how many
      queued sources compile a frame, so on index.html in which frame a lazy part's door opens, and a page under test
      queues no compile behind a running world; the ingest's debug timing
      (`storeSourceAndPotentiallyCompileItAndExecuteIt`) is read only under `srcLoadCompileDebugWrites`. The baseline
      stays 13 (the unsanctioned wall-clock reads). The stink's member rule now stops at the left margin: code there
      ends the body above it and names the member `lib/name-definitions.js` `definedName` reads (a boot file's
      top-level function, an expando, a prototype extension), any other code `(top)`; a heredoc's body is skipped and
      `Foo::bar =` is no key. Before, a read in a top-level function was filed under the nearest class-body key ABOVE
      it, in another object (`_updateBootLog`), and a top-level statement under the function before it; no existing
      sanction moved. Docs: the static-checks index's row and §member, DETERMINISM.md's spin note, the talk plan's
      three lines. PROVEN: `check-stinks-selftest.js` plants `performance.now()`, `performance?.now()` and
      `Date.now?()` among the clock spellings, each a hit, and a clock read inside the sanctioned top-level function
      (its entry then expects 2 and finds 3) with one at the left margin after it, which is `(top)` and leaves that
      count at 3; the real tree reads 13 at its baseline with 15 sanctioned.
- [x] **The automator event commands' constructors are code nothing runs** (found by the same review; by reading).
      Commands are rehydrated from their test's JSON (`Object.setPrototypeOf`), never constructed, so the eight
      `AutomatorEventCommand*` subclasses' constructors (each `super()` + `@automatorEventCommandName`; StartMacro's
      also `@mainMacroSource`, `@extraSubroutineSources`) never run, and their comments name a "static method
      executeEventCommand" that is an instance method found through `classNamed`.
      — CLOSED 2026-11-11 (self-ruled; loop unit U12). RULED: a command is DATA, so its class declares the fields its
      records carry, defines no constructor, and exists only while a record names it. LANDED: the eight constructors
      are deleted (StartMacro's `(@mainMacroSource, @extraSubroutineSources)` with them), and so are their "static
      method" comments; each class keeps its class-level fields and `executeEventCommand`. Three whole classes go too
      (found by the independent review): `AutomatorEventCommandTurnOff{AnimationsPacingControl,
      HidingOfWidgetsContentExtractInLabels,HidingOfWidgetsNumberIDInLabels}`, which no record, rig or doc names —
      each test's preamble is ResetWorld, the three TurnOn toggles and StartMacro, and the reset puts the toggles back
      itself (`WorldTestSupport._resetAutomatorTogglesNoSettle`). `AutomatorEventCommand`'s header states the
      contract: a test's `_automationCommands.js` holds a command as a record naming its class, and playback gives the
      record that class's prototype and calls `executeEventCommand` (`AutomatorPlayer.replayTestCommands`, whose own
      comments now name the StartMacro command where they named a retired EvaluateString one, and three toggles where
      they said four). Measured beside it: 18 of the 383 tests' commands-file headers said the four descriptive fields
      were on the StartMacro command, and two more did not name the metadata file they are on; all 20 now name it, as
      the other headers that say where the fields live do (one header says nothing of them, and its "four
      determinism toggles" now says three). StartMacro's header no longer describes recorded tests in the present
      tense. A probe of every class whose constructor no `new` reaches (it or a descendant, over src, the harness,
      `tests/` and `scripts/`) found 12 of 205: the eight, `LCLProgramRunner` (dead whole, owned by the LiveCodeLang
      cleanup plan's R14) and three built dynamically (`new @`, a class held in a variable), so no gate: the class
      has no other member. Docs: none describe the constructors or the classes. PROVEN: the build (syntax,
      call-arguments, dead-method gates) and two gauntlets (20/20 each); nothing a test runs changed.
- [x] **A viewport's gesture bookkeeping outlives its gesture** (found by the independent review closing "A
      drag-scroll leaves a viewport holding a function no save can write", in the plan's ledger; by reading). The edge
      auto-scroll's end (`ViewportWdgt`, the auto-scroll's own step) does not clear `world.wdgtsWithOngoingScrollMomentum`,
      so an auto-scroll that replaced a running glide leaves `anyScrollMomentumOngoing()` true; `Widget._destroyNoSettle`
      leaves a pane destroyed mid-glide in that set until a teardown; and `_stopDragScrollStep` ending an auto-scroll
      leaves `autoScrollTrigger` set, so the next auto-scroll skips its 500 ms delay.
      — CLOSED 2026-11-11 (self-ruled; loop unit U13). RULED: what a gesture knows rides on its step, and the step
      ends at one place, so nothing is kept beside it for an end, a replacement, a destroy, a copy or a save to
      forget. LANDED: `world.wdgtsWithOngoingScrollMomentum` is deleted (field, construction, teardown clear);
      `WorldWdgt.anyScrollMomentumOngoing` asks every stepping widget `isScrollGliding?()`, as `anyKnobSlideOngoing`
      already asks `isKnobSliding?()`, and `ViewportWdgt.isScrollGliding` reads a flag the glide sets on its own step
      function. The `autoScrollTrigger` field is deleted: the auto-scroll's start is a local of its step, which waits
      half a second from it; a running auto-scroll is marked on its step, so a re-entry keeps its start. Every scroll
      step ends through `_stopScrollStep` (was `_stopDragScrollStep`): the auto-scroll's own end, a press, a glide's
      fade, `startAutoScrolling` replacing a glide, and a copy's `_reactToBeingCopied`. Found beside the item, by
      reading: the trigger was a plain field, so once a press had stopped an auto-scroll every later save of that
      pane wrote a wall-clock time into the file, and a copy carried it (measured: the copy skipped its wait). Docs:
      viewports-and-planes (the glide paragraph), the serialization reference's teardown list, Fizzygum/CLAUDE.md's
      teardown list, MACRO-PATTERNS.md (twice), DETERMINISM.md's §3l fix line, the WorldWdgt teardown comment, one
      test's intent and its visualisation page; the serialization rig's planted glide corpse is gone with the set.
      PROVEN: a scratch probe (`.scratch/viewport-gesture-bookkeeping/probe.js`), each case on a fresh index-sw.html
      page — on the old code (HEAD's two files put back and built) the control passes and A (destroyed mid-glide: a
      glide still reported), B (an auto-scroll replaced a glide: still reported), C (an auto-scroll stopped, then a
      second begun 700 ms later: 324 px scrolled by 300 ms) and D (the same on a copy) each fail, and E (a first
      auto-scroll: nothing by 300 ms, scrolled by 900 ms) passes; on the new code all six pass.
- [x] **Widget's `step` documentation is false** (found by the independent review closing "A drag-scroll leaves a
      viewport holding a function no save can write", in the plan's ledger; by reading). `Widget.coffee`'s note on
      `step: noOperation` says a `step` left as the no-op lets the children's steps run while an undefined one stops
      them; `_runChildrensStepFunction` walks the flat stepping set, so nothing traverses children, and an undefined
      `step` throws in the loop's `try`, soft-resetting the world.
      — CLOSED 2026-11-11 (self-ruled; loop unit U14, with the next item). RULED: a comment states what IS, and
      code nothing reaches goes. LANDED: Widget's note over `step: noOperation` says the world calls `step` on each
      frame its fps is due, while — and only while — the widget is in `world.steppingWdgts`, a FLAT set (a widget
      steps because it joined, never because an ancestor did; its children are not visited); the no-op is what a
      member without a step of its own runs; an undefined step is an error the loop catches by soft-resetting the
      world (and shows it in the error console, on every frame the step is due). Beside it, by reading: Widget's
      `onNextStep` field ("Not currently used"; its one writer, `nextSteps`, was deleted on 2026-07-12 as dead, and
      nothing has set it since) and `WorldWdgt._stepWidget`'s branch for it are deleted — so an object inspector's
      Inherited view lists one row fewer — and so is `_stepWidget`'s `debugger` for an undefined step (the catch
      below it already handles one; `debugger-statement` 33 → 32, the static-checks table with it). Docs: the
      authoring guide's §12 already described stepping truly; no living doc described a child walk or `onNextStep`.
- [x] **An object inspector removes its list's contents from a set nothing adds them to** (found by the same review;
      by reading). `InspectorWdgt._buildAndConnectMemberList` deletes `@list.listContents` from `world.steppingWdgts`
      and says the list itself "still steps (its scrollbars need it)"; nothing adds a list's contents to the set, and
      a list steps only while a gesture of its own runs.
      — CLOSED 2026-11-11 (self-ruled; loop unit U14, with the item above). LANDED: the no-op delete and its false
      comment are gone from `InspectorWdgt._buildAndConnectMemberList`. Measured: every class that joins
      `world.steppingWdgts` itself (17, in src; the harness joins none) defines its own `step`, and none adds a list's
      `listContents`; a copy (`alignCopiedWidgetToSteppingStructures`) or a loaded file's marker can enrol one only
      where its original or its file says so, and there it would run the no-op — so the line was dead on every path.
      A ListWdgt is a ViewportWdgt, stepping only while a scroll gesture of its own runs. Docs: none described it.
      PROVEN (both items): the build (the stinks at 32 of 32) and the gauntlet; its one failure was predicted by the
      review — `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly`, whose Inherited member lists lost the
      `onNextStep` row (images 2 and 3, both densities: the same rows one row lower, the lists' own thumbs moved,
      every difference mask black outside the lists; looked at in `fg diffpage`) — recaptured through the gated
      recapture, mouse then finger (both COMPLETE); then a gauntlet (20/20) and the homepage, green.
- [x] **Nothing holds every stamped field to its declaration** (found by the independent review closing "A runtime
      object stamped derived is dropped from an inspector holding it", in the plan's ledger; by reading). A field a class
      stamps (`FridgeMagnets3DCanvasWdgt._markTransient`) and leaves out of `@serializationTransients` is shared by every
      copy (two panes rendering into one Surface); only the serialization rig's pane save would notice.
      — CLOSED 2026-11-11 (self-ruled; loop unit U15). RULED: the stamp names the field it fills and asks the
      derivation itself whether the value is derived there, so the two cannot disagree. LANDED:
      `FridgeMagnets3DCanvasWdgt._markTransient obj` is now `_keepTransient field, obj`: it stamps the object, stores
      it in `@[field]`, and reports — `console.error "TRANSIENT_FIELD_UNDECLARED <Class>.<field> …"`, a gate token
      (`Fizzygum-tests/scripts/lib/gate-tokens.js`) — a field its class does not declare at class level, or where
      `NativeValueKinds.isDerivedAt` (the predicate both walkers ask) does not hold. The class-level half replaces
      what the build's field census can no longer see (`census-widget-conformance.js` facet 1 reads `@field =`
      writes, not `@[field] =`). The suite builds panes (two Fizzytiles tests), so a stamp added without both
      declarations fails it at once. The seven stamping sites name their fields. Docs: the authoring guide's §4.2
      (stamp AND declare, the worked example), the serialization reference's derived-values paragraph,
      NativeValueKinds' comment, the gate-token registry's header, the serialization rig's section comment. PROVEN:
      the single runner on `SystemTest_macroFizzytilesBoxTileRendersStaticCube` with a `--prelude=` plant fails naming
      `TRANSIENT_FIELD_UNDECLARED FridgeMagnets3DCanvasWdgt.surface` for each half — one plant drops `surface` from the
      class's transients, the other deletes its class-level declaration — and unplanted it passes; two gauntlets
      green (its `parts` leg drives the lazy Fizzytiles part on index.html; production ships no Fizzytiles, so
      `fg homepage` does not reach this).
- [x] **An inspector's Duplicate throws on a subject the copier refuses** (found by the independent review closing "A
      runtime object stamped derived is dropped from an inspector holding it", in the plan's ledger; by reading). An
      inspector opened on a `Uint8ClampedArray` (the `data` row of a pane's `imageData`, a mesh's positions) duplicates
      into `DUPLICATE_UNRECOGNIZED_TYPE`; its subject is a page object it inspects, not structure to copy.
      — CLOSED 2026-11-11 (self-ruled; loop unit U16, second shape). RULED: a buffer is DATA, which the copier copies
      as it copies an Array — its own documented rule ("we deep-copy all kinds of data structures") — so the crash
      goes and nothing the owner holds open is decided (the item below: whether an inspector's subject is a page
      object; the W3 plan's S2 duplication default, "deep-copies with the group … owner picks"). The first shape
      (a buffer as a page object: shared on copy, refused with a page-object remedy) was falsified by the
      independent review: the copier meets every buffer, not only an inspector's subject, so a typed array a person
      put in a widget's field would have been aliased between copies while an Array beside it was copied; it
      answered both owner questions; and "every buffer is part of a 3D pane's runtime" is false (every SWCanvas back
      buffer holds one). LANDED: `NativeValueKinds.isBuffer` (an ArrayBuffer, or a view onto one: a typed array, a
      DataView) and `Duplicator._copyBuffer`: an ArrayBuffer byte for byte; a view rebuilt over the COPY of its
      buffer at its offset and length, the buffer going through the identity bookkeeping so views sharing one buffer
      share one in the copy. The Serializer is unchanged: it has no arm for a buffer (the W3 plan's S1 spike owns
      that format), so its closed set refuses one, as before. `WorldInventory` asked the buffer question in its own
      spelling and asks the one predicate now (its `instanceof ArrayBuffer` moves with it; the instanceof stink
      stays 74); `check-unresolved-sends-selftest.js`'s stale-platform-global plant follows `ArrayBuffer`'s one send
      to its new home. A second independent review of this shape found no bug; its fixes: the view test is one
      predicate (`NativeValueKinds.isBufferView`), the rig's inspector check asserts no throw and a subject equal in
      kind and bytes but NOT shared-vs-copied (the owner's question), the sharing check stands in its own block with a
      DataView, and a plant proves the save check. Docs: the serialization reference (the dispatch order, §5's
      warning that a buffer no longer crashes the copy, §6's table row). PROVEN: the serialization rig's `samePage`
      section, both backends — `inspector.onABufferDuplicates` (on the buffers ≤ 1 KB the runtime's own fields hold,
      and the ArrayBuffer under each, found by the language's own `ArrayBuffer.isView` so a plant of the predicate
      cannot blind the search: here `transforms.worldMatrix` and its buffer — the BACKLOG item's own example, an
      ImageData's pixels, is over that size and stands by analogy), `inspector.onABufferRefusesTheSave`, and
      `duplicate.buffersSharingOneStayShared` (two typed arrays and a DataView onto one buffer a widget holds). Three
      plants, each seen failing its own checks: `isBuffer` answering no — the inspector and sharing checks THREW
      (closed set); a `_copyBuffer` that skips the identity bookkeeping — only the sharing check ("one buffer in the
      copy: false"); a view read as an Array — the save check ("SAVED"), the inspector check ("subject Array") and the
      sharing check (the DataView misplaced). Unplanted, all pass (61 native, 62 SWCanvas); a gauntlet and the
      homepage green on the shape before review #2's fixes, and again after them (20/20).
- [x] **Duplicate or over-counter iids load** (found by the independent review closing "The load vets the
      whole envelope up front", in the plan's ledger; by reading). Two records of one class with
      one `iid`, or an `iid` above the file's own `idCounters` for its class, pass the vetting: two widgets then share a
      `uniqueIDString`, or the next widget built collides with a restored one. No save writes either.
      — CLOSED 2026-11-11 (self-ruled; loop unit U17). RULED: a file no save writes is refused before anything
      changes, as the rest of the envelope already is. LANDED, in `Deserializer._envelopeShapeProblem`: a second
      record of one widget class with one `iid` is refused ("entry i is a second Class#iid": no save writes one; a
      world load would restore two widgets sharing a `uniqueIDString`, an `{"$ext"}` resolving to the last); and, in
      every WORLD file, with a section or without, a widget record's `iid` above its class's count in the section's
      `idCounters` (absent = 0: the save took the iid from that very counter, so one above it is an id a widget of
      its class built after the load would take again) — checked after the section's own shape, so a malformed
      `idCounters` keeps its own refusal. Both judge a widget class this page HAS (`classNamed` +
      `_couldBeAWidgetClass`): the first cut judged every record and the rig caught it — six existing refusals of a
      name the build lacks (`$NotATag`, `constructor`, …) read "above its class's count" instead of naming the class;
      a lazy part's class is judged when its door re-enters. The independent review traced every way a real save
      writes ids and found neither shape writable; its fixes: the counter rule moved out of the world-section check
      (a world file with no section escaped it), and the comments and docs that list the load's refusals name the
      two rules. Docs: the serialization reference's list of up-front refusals and of the reasons that wait for a
      lazy part. PROVEN: the serialization rig's `crossSession` section, both backends — four cases in
      `world.loadGuard.malformedRecordRefused` (a record duplicated; its class's count below its iid; its class
      missing from the counters; a world file with no section); a `--prelude=` plant that makes the vetting forget
      exactly the two rules fails it (the corrupt files loaded: "desktop kept 0/17"); unplanted, all pass (39 native,
      40 SWCanvas), the accept control among them; a gauntlet and the homepage green on the first shape, and again
      after the review's fixes (20/20).
- [x] **A user object with an own `$wk` key saves and then is refused** (found by the independent review closing "The load vets the
      whole envelope up front", in the plan's ledger; by reading).
      `Serializer.wellKnownKeysIn` visits a record's `props` container as if it were a reference, so a plain object a run
      stores with an own `"$wk"` key saves, and the file is refused on load ("names the well-known object …").
- [x] **A widget file's source edits pre-load parts** (found by the independent review closing "The load vets the
      whole envelope up front", in the plan's ledger; by reading). `loadWhatItNeeds` reads
      `envelope.world.sourceEdits` for a widget file too, fetching parts and the reflective layer for edits that door
      never replays (a widget file carries none a save writes).
- [x] **The info-doc prefix has four homes** (found by the independent review closing "The load vets the
      whole envelope up front", in the plan's ledger; by reading). `InfoDocs`, `Serializer`,
      `Deserializer._worldSectionProblem` and `WorldWdgt` each spell `infoDoc` for the world's own info-doc flags.
- [x] **`Serializer.numberRef` writes a non-number through unchanged** (found by the independent review closing "`Color.create` never
      checks its components", in the plan's ledger; by reading).
      It is the one writer of every number a record holds (a reference, a `$Date`'s time, a Color's components), and
      a value that is not a number — a console's `c._a = "x"` on a colour — is written as it is, so the save writes a
      file the load refuses. One refusal there would cover every number the format keeps.
      — CLOSED 2026-11-11 (self-ruled; loop unit U18, the four items above together). RULED: what the format says
      is read where the format puts it, and a name has one home. LANDED: (1) the well-known keys are read by
      POSITION — `wellKnownKeysIn` moves to the Deserializer (its only reader) and takes a single-key
      `{"$wk": string}` only from each record's references (`_refsOf`: items, map entries, the VALUES of props —
      never a props container, whose own keys are property names; a world section holds its widgets as `{"$r"}`s, so
      it carries none), so an object a run gave a widget with an own `$wk` key (alone, shaped exactly like a
      reference, or beside others) round-trips;
      (2) `_envelopeShapeProblem` refuses a widget file that carries a world section (no widget save writes one), so
      neither `loadWhatItNeeds` nor `_needsTheReflectiveLayer` can fetch for source edits the widget door never
      replays; (3) `WorldWdgt.infoDocFlagName` / `isInfoDocFlagName` are the info-doc flag's one name, asked by
      InfoDocs, the save, the load's vetting and the teardown (the old spellings: `indexOf("infoDoc")` twice,
      `/^infoDoc/`, `"infoDoc_" + key`); the rig keeps its own count, independent of the predicate under test;
      (4) the save's Color branch refuses a colour whose component is not a number (`Serializer._colorComponentsProblem`,
      naming the component and its kind, with the path), and a `$Date`'s time is read through `Date`'s own `getTime`
      — so nothing hands `numberRef` a non-number, and it states that contract. The independent review found no
      high-severity bug; its fixes: a stale claim that a save never meets such a Color (doc + comment), the new reader
      set above `_refsOf`'s own comment, a remedy fit for an interned colour (a written-into colour has changed every
      holder of it: put it back), a refusal message that cannot itself throw, the world-section walk dropped (no
      cycle hazard; truly by position), the flag predicate the full `infoDoc_<key>_created` shape, and two rig checks
      made able to fail (an unknown key beside others; the refusal's path). Docs: the serialization reference (the
      well-known-key read, the up-front refusals, the info-doc flags, the Color row), `Fizzygum/CLAUDE.md`'s flag
      spelling.
      PROVEN: the serialization rig, both backends — `plainObject.ownWkKeyRoundTrips`, `color.writtenIntoRefusedBySave`
      (`samePage`) and `widgetFile.worldSectionRefused` (`crossSession`), each seen failing its own plant alone: the
      position-blind walk put back ("threw: it names the well-known object 'not a well-known key'"), the Color check
      off ("SAVED"), the widget-file refusal off ("NOT REFUSED"); unplanted, all pass (63 native, 64 SWCanvas; 40 native,
      41 SWCanvas); a gauntlet and the homepage green before the review's fixes (one leg, the menu sweep, hung in
      `browser.close()` under the wave's load after its sweep had returned, and passed its serial retry), and again
      after the review's fixes (20/20, no flake).
- [x] **A page member the load could not return to boot runs in the loaded world but is recorded nowhere** (found by
      the independent review closing "A failed return to boot is only logged", in the plan's ledger; by reading). The
      load's notice says so, and then installs the file's registry (`WorldWdgt.loadWorldSnapshot`): a save of the
      loaded world omits that member's edit, so the file it writes differs from the world that wrote it.
- [x] **The world load promises "Everything else in the file loads normally" before deserialization can throw**
      (found by the independent review closing "A failed return to
      boot is only logged", in the plan's ledger; pre-existing). `WorldWdgt.loadWorldSnapshot`'s step-2b notice precedes `Deserializer.deserialize`;
      a restore that throws after it has told the person the rest loaded.
      — CLOSED 2026-11-11 (self-ruled; loop unit U19, the two items above together). RULED: the loaded world's registry
      describes the code it runs, and a promise is made once it is true. LANDED: `SourceEditsRegistry
      .returnThePageToBootSources` tags each member it could not return with its scope and the source it was left
      running, read as the class's OWN source (`_ownSourceIn` — a removed member named like an `Object.prototype` one
      must not read the inherited function as its source); after the replay, the restored registry's
      `pageMembersStillRunning` names each such member still running the page's edit — unless the file's own last
      record of it says the same, which makes it the file's code — and `recordMembersStillRunning` records each one
      (its source, or a removal) exactly as the page's own edit would have been recorded, so a save of the loaded
      world carries the code it runs and reloads into it, and a save→load cycle never grows the registry. The notice
      counts what was recorded and is said ONCE: after step 9, once the rest has loaded ("Everything else in the file
      loaded normally"), or, on a restore that throws, the counts alone before the error goes on — the return and the
      replays did change the page's code. The independent review found no high-severity bug; its fixes are the
      own-source read and the not-recorded-twice rule above (both by reading), the counts told on a failed restore
      (it had been silent there), and the key order of a produced record matched to the session writers'. Docs: the
      registry's header (a world load is its one other recorder), the serialization reference's account of the
      notice and of the unreturned members (§11, §12), `mixins.md`. PROVEN: the serialization rig's `world` section
      (SWCanvas, 48 checks) — `sourceEdits.unreturnedPageEditIsRecorded` (an added AND a removed member the load
      could not return are in the loaded world's registry and its next save, which the load's own vetting accepts
      and which, reloaded on a page at boot, runs both edits), `sourceEdits.recordedEditIsNotRecordedTwice` (a file
      already recording the member gains no second record, and says nothing of it) and
      `sourceEdits.failedRestoreTellsTheCountsWithoutThePromise` (a restore made to throw tells the counts once,
      without the promise); planted, `recordMembersStillRunning` emptied fails the recorded check, the told check
      and both checks that read the notice ("recorded [] / saved []"), the file's last record ignored fails the
      not-twice check alone ("records of the added member 2, of the removed one 2"), and the promise said where the
      counts are known — the old order — fails the told check and the failed-restore check (two informs, the first
      "Everything else in the file loads normally."); unplanted, all 48 pass. A gauntlet and the homepage green
      before the review's fixes, and again after them.
- [x] **A text that meets its twin's back buffer never reflows** (found by the independent review closing "A run that
      replaces a saved method leaves its kept source describing the old one", in the plan's ledger; by reading, and the
      measured `[2, 0]` in MACRO-PATTERNS' wrap-reading entry). `TextWdgt._createRefreshOrGetBackBuffer` takes its key
      before `reflowText` and returns on a hit, so of two texts of one font, extent and text the second keeps an empty
      `wrappedLines`; `slotAt` reads it, so a first click into that text can put the caret at its end.
- [x] **An own FIELD read inside cached text work keys nothing** (same review; by reading). The own-code key covers own
      functions: an inspector Save of a text's own `emptyCharacter` (read in `TextWdgt.getWrappingData`) leaves twins
      sharing entries computed with either value.
- [x] **A kept source of a fat-arrow method keeps its first receiver in copies** (same review; by reading;
      pre-existing). An injected `=> @x` is one bound function, shared by a copy (the Duplicator passes functions
      through), so the copy runs it on the original; a save and load re-bind it to the loaded widget.
      — CLOSED 2026-11-11 (self-ruled; loop unit U20, the three items above together). RULED: a text's model
      describes the pixels it shows; a constant of the text model is no widget's field; a copy makes its injected
      methods as a load does. MEASURED first: the first item's caret claim does not hold — placing a caret reflows the
      text (`slotCoordinates` calls `reflowText`), so a first click into the twin lands where it is aimed even on the
      old code; what holds is the stale wrap itself (the twin wraps on 0 lines beside the first's 4), read by every
      reader that does not reflow first (`slotAt`'s line test, a macro reading `wrappedLines`), and StringWdgt's buffer
      method had the same hit-before-reflow shape (a twin keeps its pre-reflow fit and crop). LANDED: (1) both
      `StringWdgt._createRefreshOrGetBackBuffer` and `TextWdgt._createRefreshOrGetBackBuffer` meet any buffer they are
      not already showing — painted now, or a twin's — reflowed, and tell the caret then; a buffer equal to
      `@backBuffer` needs nothing (every blit and hit test asks for the buffer, so a reflow per hit would pay a fit
      search per paint); (2) the line-end marker is `StringWdgt.INVISIBLE_CARRIAGE_RETURN`, a class constant, replacing
      the prototype member `emptyCharacter`, which nothing set per widget and which an own visible value would have
      broken (`eliminateInvisibleCharacter` strips the first such letter from every measured string) — keying it would
      have touched five caches, the TextWdgt back buffer among them, its paint drawing the marker; (3)
      `Duplicator._compileInjectedMethods` compiles each injected method afresh on the copy, from its kept source with
      the copy's own `injectProperty`, for every own field of a widget (`Serializer.classTakesInjectedMethods`, now
      asked by the copy too) holding one, so a fat arrow binds the copy. Docs: the
      serialization reference's function row, `MACRO-PATTERNS.md`'s wrap-reading entry (the `[2, 0]` caveat gone),
      `Widget.keptSourceOf`'s and the Duplicator's comments. The independent review found no paint loop or
      re-entrancy (the reflow is idempotent; a key settles within two frames, as on a miss) and one regression: a copy
      of an injected method RENAMED to a name that is no identifier (`my method`) threw mid-copy, as a load of one
      already did — `@my method = …` reads as a call — so `Widget.propertyAssignmentSource` names the member by key
      (`@["…"] = …`, its `#` escaped), mending both; its other fixes: a twin StringWdgt held too (its crop; TextWdgt
      overrides the buffer method without super), the copy's fields said truly (a transient's injected method is
      re-made too: the save drops it, a copy keeps it), the marker's last literal (`slotAtSingleLineString`) read from
      the model, the reference doc's function and Duplicator-mechanism lines, the test's premise made non-vacuous and
      its widgets destroyed; four findings filed. PROVEN: new assertion-only
      `SystemTest_macroTwinTextWrapsOnItsOwn` (twin texts: the second shows the first's buffer and wraps on as many
      lines, more than one; twin single-line texts: the same buffer and the same crop) — both old buffer methods
      re-applied through each class's own member edit fail every twin assertion (the wrap "found: 0" against 4, the
      crop the whole sentence), StringWdgt's alone fails exactly the line assertions; a follower on both pointers
      clean; the serialization rig's new `serialize2.copiedFatArrowMethodAnswersTheCopy` (a copy's `=> @x` answers
      the copy, a loaded one the loaded widget, under a plain and under a renamed `serRig probe #{answer}` name) —
      `_compileInjectedMethods` emptied fails it on both backends ("copy": "the original"), the bare-name assignment
      put back fails it ("probe is not defined"); unplanted, the `samePage` section passes (64 native, 65 SWCanvas);
      `SystemTest_macroTextOwnCodeKeysTheCachesItRunsIn` reads the marker from the model and passes. Seven inspector
      tests recaptured at dpr 1 and 2, mouse and finger, under the loop's member-list grant: every one of the 40 moved
      shots, looked at in `fg diffpage`, was the same member-list rows scrolled a few pixels with the list's thumb dot
      moved (one row fewer, `emptyCharacter`); both recaptures' completeness gates green. A gauntlet before the
      review's fixes green but for one stale visualisation page (the own-code test's, regenerated) and the homepage
      green; again after them.
- [x] **A run that replaces a class's member reads as a recorded source it no longer runs** (found by the independent
      review closing "An object inspector on a class shows its statics as compiled text", in the plan's ledger; by
      reading). The inspector reads the source a class's meta-object records for a NAME, never for a function: a run's
      `Klass::m = -> …` on a prototype member shows `Klass`'s record — or, where `Klass` records none
      (`RectangleWdgt::step = …`), the first class up the chain that does (Widget's `step`) — and a run's `Klass.s = ->
      …` on a static `Klass` itself declares shows its record. (A static the holder copies from an ancestor is shown
      only while it IS the ancestor's function, so a run's static on a child reads as compiled text.) For statics there
      is no edit path, so `Class` could keep each static's compiled function at creation or ingest and the question
      becomes answerable; for prototype members the class inspector's edits are the record, and a run's are not.
- [x] **The inspector's class walk reads a recorded source through the store's prototype** (same review; by reading).
      `selectionFromList`'s class walk asks `theClass.nonStaticPropertiesSources[selected]?` of a plain `{}`, so
      selecting `constructor` on a class that writes none shows `Object`'s native text; which source a constructor
      row should show (the class's own, CoffeeScript-generated when it writes none) is the open part.
      — CLOSED 2026-11-11 (self-ruled; loop unit U21, the two items above together). RULED: a source is kept WITH the
      function made from it, never read by a name, and a record store answers no inherited name. MEASURED first: a
      mixin's literal is evaluated afresh for every class it augments, so each consumer holds its OWN function for a
      mixin member; the function itself is the identity that holds everywhere (the rule `Widget.keptSourceOf` keeps for
      injected methods). LANDED: `Class.memberRecordOf` / `keepMemberRecord`, a weak store beside — never merged into —
      `Widget._keptSources`, which the save reads (a class member written as a widget's `{"$src"}` would compile on its
      own, `super` and all); a record is the source text, and a function's FIRST record is its record (a member whose
      source names a function made elsewhere, `step: noOperation`, an edit to `Widget::bar`, leaves that function's
      record alone). Kept where a member's function is made: a class made or ingested (`Class._keepMyMembersRecords`:
      its own keys only — its members, statics, its class function for a constructor it writes, each member a mixin
      injected with its donor's source), a class edit, every mixin member compiled
      (`Mixin._compiledMember`, which also names only a function its source MAKES — `Widget.spellsAFunctionLiteral`,
      made public for it). The inspector asks the function a class prototype holds (`selectionFromList`, the
      name-keyed class walk gone) and a class function's static (`_recordedStaticSourceOf`); a donated member is
      attributed by the class chain (the class does not define it, its donor does: `Mixin.donorOf`), never by a
      record, since one function can stand in several places. A class inspector's rename renames the source the
      held function keeps, and refuses a member whose function keeps none. The record stores (`Class` instance and
      static, `Mixin`) are `Object.create null` (two `null-literal` sanctions: Object.create's argument for no
      prototype), so the hand-written own-ness reads go — both `definesMember`, `membersAwayFrom`, the constructor
      test at class creation, the boot-donor test, U19's `SourceEditsRegistry._ownSourceIn` — and the inspector
      shows a subject with no prototype (`_subjectsClassPrototype`; a store, or a run's own `Object.create null`).
      FIELDS keep the record by name (filed). The independent review found a crash it fixed — an inspector on a
      meta-object's store, or the meta-object's row holding one, threw — and the rest: a shared function's record and
      mixin label overwritten by its last writer (a Save then routed to the
      wrong mixin), a rename recompiling a record the pane no longer showed, a whole-chain walk at every class's
      creation (`Object.keys` now), an unreachable consumer-side writer (`Mixin._keepConsumersRecords`, deleted),
      stale comments and docs, a test restore outside `finally`. Its ingest-time finding (a run's function replacing
      a member before the reflective layer arrives is recorded as the class's) was fixed by skipping anonymous
      functions at ingest and FALSIFIED by the production smoke — the minified image keeps no function names, so
      every member went unrecorded on `homepage` — and reverted; it is filed with its options. Docs: `mixins.md`,
      `MACRO-PATTERNS.md`. Filed: the mixin double-injection guard (measured), a field row read by name, the talk
      plan's wrapped-member premise, the pre-compiled tree's run-before-the-layer edge.
      PROVEN: `SystemTest_macroObjectInspectorShowsTheFunctionItsSubjectHolds` extended — the twin rectangle's
      `constructor` row reads the constructor RectangleWdgt writes; a heart icon's createAppearance reads its record,
      the run's replacement its compiled text (and a class inspector's rename of it is refused, the run's function
      staying, no member made under the new name), put back the record again; its `constructor` row the class
      function's own text; HeartIconWdgt defines neither `toString` nor `constructor`; an alias edit leaves the
      function's record; an inspector on the record store and one on the Class meta-object both open and read —
      plants: the old name-keyed walk fails the run-replaced, constructor and meta-object assertions; the records
      answering nothing fail all five recorded-source ones; prototype-backed stores fail both `definesMember`; the
      last writer winning fails the alias; the old rename fails both rename assertions; a class prototype read off
      a subject with none throws. `SystemTest_macroObjectInspectorOnAClassShowsItsStaticsSource` extended (Color's own
      `create` replaced by a run) and changed (the harness-installed `widgetFromUniqueIDString` reads as
      WidgetTestSupport's CoffeeScript for that very function — measured in the page) — the old static lookup fails
      exactly those two, the records answering nothing all five. A follower of both on both pointers clean; the dpr1
      suite moved no reference. A gauntlet and the homepage green before the review's fixes; after them the gauntlet
      green and the homepage smoke failing the ingest filter (above); with it reverted, both green.
- [x] **Waits for something other than a world standing are in-page polls with no outside bound** (found by the
      independent review closing "The rigs wait for their pages to boot a dozen ways", in the plan's ledger; by
      reading). The boot smoke's text-settle, reflective-layer and lazy-part waits and parts-lazy-load's launch, settle
      and lazy-consumer waits each poll inside the page with an in-page timeout, so a page stuck in a script holds them
      until the protocol timeout; `answerWithin` would bound each from outside, as the boot wait is.
- [x] **The menu sweep waits on `browser.close()` with no bound** (found closing the serialization cleanup, in the plan's
      ledger; measured; low). In a parallel gauntlet wave `menu-click-sweep-headless.js` printed `swept`, then never
      `browser closed`: Chrome hung shutting down and the leg held until `fg`'s 300 s alarm (its serial retry passed).
      The sweep's result was already in hand; a bounded close (`answerWithin`) would let the rig report it.
      — CLOSED 2026-11-11 (self-ruled; loop unit U22, the two items above together). RULED: every wait a script makes is
      bounded from OUTSIDE — the rule `answerWithin` already kept for boot — closing the family, not the one rig.
      MEASURED: 24 sites in 14 scripts awaited a raw `browser.close()`, and the adapter's own `close()` was unbounded
      too; the boot smoke's text-settle, lazy-part and reflective-layer waits and parts-lazy-load's launch, settle and
      lazy-consumer waits polled inside the page, and so did parts-snapshot-load's make and load waits, the HiDPI
      check's text settle and the pre-compile generator's compile wait. LANDED (tests repo): `closedWithin(browser)` in
      `scripts/lib/headless-driver.js` — the close raced against 30 s, then the browser's process killed (Puppeteer's;
      a Playwright browser hands none) and one line naming the script; a rejecting close still rejects — through which
      every script closes its browser, the adapter included; `waitedInPage(page, {what, ms}, fn, …)` — an in-page poll
      handed its own timeout `ms` (so the two bounds cannot be stated apart) and raced against it plus 30 s,
      throwing "the page stopped answering in its <what> wait" into the script's own failure path (a boot check
      FAILS, a rig reads INVALID), at all ten such polls in five scripts. A single evaluate awaiting a PRODUCT promise
      is no such poll (its bound is filed). Docs: the tests repo's CLAUDE.md, the driver's API header. The
      independent review found no regression; its fixes: four polls the first pass had not reached (the claim
      "every poll" was false), the self-test's guard naming the case that never settled, the timeout stated once,
      a wider margin, the doc's "killed" true only for a Puppeteer browser; filed: the production smoke's
      follow-on evaluates. PROVEN: new node-tier `scripts/lib/headless-driver-selftest.js` (10 cases on fakes that never settle,
      with a guard timer, since a never-settling promise keeps no process alive) — each helper put back unbounded fails
      it ("a case never settled"); a page planted to get stuck in a script inside parts-lazy-load's launch wait reads
      INVALID naming the wait after 92 s (its bound 90 s), where HEAD's rig waited the protocol timeout (182 s,
      "Runtime.callFunctionOn timed out"); one planted stuck in the boot smoke's waits FAILS naming the lazy-part
      wait after 53 s (bound 45 s); the four converted rigs' controls pass. A gauntlet and the homepage green before
      the review's fixes; again after them.
- [x] **The boot smoke is a gate with no rule registry and no standing bite-proof** (found by the independent review
      closing "A failed return to boot is only logged", in the plan's ledger; by reading).
      `Fizzygum-tests/scripts/smoke-boot-headless.js` is launched by `fg homepage` and `build_and_smoke.sh`, neither of
      them a root `lib/what-runs.js` walks, so the gate census never asked it for `lib/gate-rules.js` rules nor a
      `proveLeg` proof: its legs' bites rest on `.scratch` plants (the class-level-edit leg's three).
- [x] **The production boot smoke's follow-on checks can outlast `fg homepage`'s alarm with no verdict** (found by the
      independent review closing "Waits for something other than a world standing are in-page polls with no outside
      bound", in the plan's ledger; reached: `fg homepage` with a product hang in a part's or the reflective layer's
      load). After its bounded waits, `smoke-boot-headless.js --production` opens fresh pages and awaits product
      promises (`ensureLoaded('meta-tools')`, `loadEnvelopeString`, `loadWorldSnapshot`, the snapshot round-trip, the
      rotation probe) through single unbounded evaluates, each up to Puppeteer's default 180 s protocol timeout; two of
      them outlast `fg`'s 300 s alarm, which kills the smoke before it prints `BOOT OK` or `BOOT SMOKE FAILED`. A
      single evaluate awaiting a product promise is not an in-page poll (`waitedInPage`): it wants a bound of its own.
      — CLOSED 2026-11-11 (self-ruled; loop unit U23, the two items above together — the second folded in as the same
      script). RULED: the census reads what a VERSIONED root launches — `build_and_smoke.sh`, the build's own
      pre-commit check, becomes a root of `buildSystem/lib/what-runs.js` beside the build (no change to `fg`, which
      stays read through its four leg functions) — and the boot smoke is then a gate like any other: it names every rule
      it fails on, and a self-test plants each rule a dev tree can reach. LANDED: the census root (read when present,
      like `fg`; its self-test gains the case, 65); `smoke-boot-headless.js` names 21 rules over its 32 failure lines
      (`Fizzygum/buildSystem/lib/gate-rules.js`: `NO_ERRORS`, `PAGE_LOAD`, `WORLD_STANDS`, `LAZY_SPLIT_EAGER_PRESET`,
      `LAZY_SPLIT`, `LAZY_PART_*`, `LAZY_SOURCES_*`, `HARNESS_INSTALLED`, `ROTATION`, `FORBIDDEN_PATH_SHIPPED`,
      `DEV_PATH_MISSING`, `PRECOMPILED_IMAGE`, `NO_COMPILE_LOG_DIV`, `SNAPSHOT_ROUND_TRIP`, `CLASS_EDIT_FILE_LOADS`,
      `RESTORED_INSPECTOR_WAITS`, and each check's vacuity its own: `SNAPSHOT_ROUND_TRIP_VACUOUS`,
      `RESTORED_INSPECTOR_VACUOUS`), one declared `bite-unplantable` (`RESTORED_INSPECTOR_WAITS`: a door waiting for a
      reflective layer absent when the files are made, which only a `sources: "lazy"` tree has); EVERY evaluate it makes
      bounded — an in-page poll through `waitedInPage`, every single evaluate through `answeredWithin` (45 s, now
      `lib/headless-driver.js`'s, which the parts-snapshot rig can take) — failing the rule its step serves, naming the
      step; a page that stops answering stops every later probe on it (one hang, one rule); `WORLD_STANDS` only where
      the world never stood; the lazy-part walk stops at the first part that does not load (a rejected one answers at
      once); a page or browser lost reads INVALID, exit 2. So a product hang can no longer outlast `fg homepage`'s
      alarm: the worst case, a broken lazy-part bootstrap, is one part's 15 s, the layer's 15 s and two fresh pages'
      45 s. Docs: the lint index's census, both repos' CLAUDE.md, the census headers. PROVEN: new
      `scripts/smoke-boot-selftest-headless.js` (`proveLeg`; the gauntlet's `selftests` leg) plants all 20 plantable
      rules on the dev tree, read as the tree each rule needs, in nine runs: an error at boot, a rotation that rotates
      nothing and an empty test manifest; `index.html`'s every-part-eager flag read true once boot is done; the
      fizzytiles engine class in the page at boot, the first lazy part fetching an eager batch as it loads and the
      second refusing to load (the rest "not loaded after the first that failed"); `index.html` stuck in a script inside the
      text-settle wait (its world stood: `PAGE_LOAD` alone) and from its first line (`PAGE_LOAD`, `WORLD_STANDS`); the
      sources flag read `"lazy"` once boot is done (this tree fetched its sources at boot and holds its layer, so the
      restored-inspector probe reads VACUOUS) with the mixin reading finding none parsed; and `--production` on the dev
      tree (which it is not: `FORBIDDEN_PATH_SHIPPED` and `PRECOMPILED_IMAGE` fire by the tree itself) twice — the log
      div put back and every world load stuck (the round-trip read "did not answer within 45s (the snapshot
      round-trip)", its page then skipping every later probe, said once; the edit-carrying file the same on its own
      page); and the round-trip's fixture bringing up nothing — and a `--require` preload telling the smoke's own reading
      of the tree that `font-assets/` is absent (`DEV_PATH_MISSING`; a mirror of the tree without it was measured and
      dropped: the SWCanvas pages cannot stand without their fonts). Every plant is deterministic: a flag read
      through a getter keyed on boot's end, a hook on a prototype present before the world. The census's own new cases
      fail with the root removed. The independent review closing this unit found eleven defects in the first shape
      (three false `bite-unplantable` reasons among them), all fixed above. `fg gauntlet` green (20 legs, 1243 s; the `selftests` leg runs the new proof), `fg homepage`
      BOOT OK.
- [x] **A step that throws throws on every frame it is due** (found by the independent review closing "Widget's `step`
      documentation is false", in the plan's ledger; by reading; low). `WorldWdgt._stepWidget`'s
      catch soft-resets the world and reports to the error console, and leaves the member in the stepping set, so a
      broken `step` repeats both on every due frame, with no removal or back-off.
      — CLOSED 2026-11-11 (self-ruled; loop unit U24). Reached through the product: a person's broken `step` (an
      inspector Save, a typed run) soft-resets the world on every frame it is due — the hand's carry and hover, any
      drag — so nothing can be dragged. RULED: reuse the paint path's rule whole, not a new one — a widget whose paint
      throws is hidden and banned (`widgetsGivingErrorWhileRepainting`) until an inspector's Save gives every banned
      widget another chance, and the error log says so; a widget whose step throws now gets the same: banned
      (`widgetsGivingErrorWhileStepping`, which the stepping loop passes by), its error shown once, the log saying
      it is not stepped any more, and the same Save lifting the ban. It stays a member of `steppingWdgts`: membership
      is the widget's (a saved world keeps it), the ban is the world's. The unit's first shape removed the offender
      from the set instead, leaving re-joining "its own business"; the independent review closing this unit showed
      that leaves no way back — a widget that joins the set at construction (a clock) could never step again, and an
      active plan's "fix a failing step and watch it heal" beat could not work — where the paint path gives one.
      LANDED: `WorldWdgt.giveBannedWidgetsAnotherChance` (the one re-admission, both bans; `InspectorWdgt.save` calls
      it), the stepping twin list (declared, set in the constructor, emptied by the teardown core and the dissolve
      beside its paint twin, which the serialization rig's teardown-hygiene fixture now dirties too), the loop's pass-by, the error log's stepping notice; `Widget.step`'s doc and the
      authoring guidelines' §12. PROVEN: new `SystemTest_macroAStepThatThrowsStopsStepping` (assertion-only: a
      rectangle whose fps-0 step counts and throws a string; after ten frames it stepped once, is banned yet still a
      member, and the log says so; an inspector Save of a fixed step lifts the ban and it steps again) passes at dpr 1
      and 2, under `--pointer=finger` and on WebKit; with the old `_stepWidget` re-applied through WorldWdgt's own
      member edit it stepped 10 times, unbanned, the log silent (and the inspector could not be driven); with the old
      `InspectorWdgt.save` the ban stayed and the fixed step never ran. `fg gauntlet` green (20 legs; `vmtruth` a load
      flake: INVALID at its pin cap in the parallel wave, 0 retained, passed alone), `fg homepage` BOOT OK.
- [x] **A Duplicate of an inspector on a SWCanvas Surface throws** (found by the independent review closing "An
      inspector's Duplicate throws on a subject the copier refuses", in the plan's ledger; by reading). A world
      inspector's `worldRenderCanvas` → `_surface` (or any SWCanvas widget's back buffer's) is an instance of a vendored
      class the copier's closed set does not know: `DUPLICATE_UNRECOGNIZED_TYPE`. The same class of crash one level
      above a buffer; whether the copy should share or copy it is the item below.
- [x] **A save refused for a buffer an inspector or a run holds names a class author's fix** (found by the second
      independent review closing "An inspector's Duplicate throws on a subject the copier refuses", in the plan's
      ledger; by reading; low; pre-existing). The Serializer's closed-set remedy says "Declare the property holding it
      in @serializationTransients", which neither an inspector's `.inspectedObject` nor a field a run filled can do.
      — CLOSED 2026-11-11 (self-ruled; loop unit U28, the two items above together). Reached through the product: on
      the SWCanvas page (the owner's), an inspector drilled into the render canvas's `_surface` (a vendored
      `SWCanvas.Core.Surface`, whose width, height and stride are non-enumerable: no field copy is faithful), or any
      native a run put in a widget's field, and Duplicate: a crash (`console.error` token, `debugger`, a bare throw);
      and the save of the same refused with a remedy only a class author can take. RULED: ONE refusal for both walkers
      — a copy refuses a value it cannot copy exactly as a save refuses one it cannot write — and ONE remedy text, the
      person's gestures first (close an inspector open on it; remove a field a run filled, with an inspector's
      Remove), then the class author's in the one form both walkers honour (make it a value its holder rebuilds:
      stamp a `rebuildDerivedValue` on it and declare its field in `@serializationTransients`); and a refusal leaves
      no half-built widget behind, so the copy is BUILT WHOLE before any of it reaches the world. Not decided here (the
      owner's): whether an inspector's copy shares or copies its subject. LANDED: `SerializationError` serves a third
      direction, "copy" ("Cannot copy: "), and carries `@UNRECOGNIZED_TYPE_REMEDY`, which both closed sets read; the
      Duplicator's closed set throws it (no console line, no `debugger`: `DUPLICATE_UNRECOGNIZED_TYPE` leaves the gate
      tokens, and the `debugger-statement` stink drops 32→31) and, as the save's does, takes a prototype-less object
      for a plain one (a class's member stores are made so; `_shellFor` and `_rebuildDerivedValues` serve one, the
      last `hasOwnProperty` send in src going with it, and its `BUILTINS` entry in `check-unresolved-sends.js`); its
      Note 3: each widget shell's registration (in build order) and each object's alignment into the world's
      trackers and its `_reactToBeingCopied` (in finish order, a child before its parent, as they ran before) wait
      until `duplicate` has copied everything; `Widget.fullCopy` tells the refusal (`@inform`), beside its dead-item
      refusal, and the sites that use its result guard it (`FrameWdgt.fullCopy`, `ActivePointerWdgt`'s template copy
      — which also ends that grab, so the next move does not try and tell again — `GlassBoxTopWdgt`, the smart
      placer); `fg menusweep` fails a representative's refused copy (`COPY_REFUSED`: a fresh widget keeping a value
      no copy carries in a field of its own, the class author's defect the retired token used to catch), its proof
      planting it. Stinks: the catch and the `Object.create null` sanctioned (precedents: `serialiseToMemory`, the
      member stores). Docs: the serialization reference (the hooks' timing, the refusal), the lint index's table.
      PROVEN: the serialization rig's `samePage` section, both backends — `duplicate.refusedPartWayLeavesNoHalfBuiltWidget`
      (a copy refused at a rectangle holding a DOMRect, after it finished a stepping sibling: nothing left registered
      or stepping), `inspector.onAnUnrecognizedValueRefusesTheDuplicate` (a DOMRect; on SWCanvas also the render
      canvas's `_surface`, this item's own example: the real inform pop-up says "Cannot copy: a value of an
      unrecognized type (…) cannot be copied" with the remedy and fits the world, nothing thrown),
      `inspector.onAPrototypeLessObjectDuplicates` and `inspector.onABufferRefusalNamesThePersonsRemedyFirst`; and
      `menu-click-sweep-selftest-headless.js` planting `COPY_REFUSED`. Four plants, each seen failing its own line:
      the old closed set, shells registered as built, finishings run as each object is finished, the old remedy text.
      The independent review closing this unit found fourteen defects in the first shape (a remedy false for the
      copier, the lost menu-sweep detection, a prototype-less object refused, stale and overbroad claims), all fixed
      above; filed from it: "A copy's refusal names the value but not where it is held". `fg gauntlet` green on
      both shapes (20 legs each, no flake), `fg homepage` BOOT OK on both.
- [x] **A kept source runs every statement it holds on every load and copy** (found by the independent review closing
      "A kept source of a fat-arrow method keeps its first receiver in copies", in the plan's ledger; by reading).
      `Widget.spellsAFunctionLiteral` reads only the FIRST token, so a Save of `-> 1` followed by a second line
      (`world.inform "x"`) keeps the whole text as the function's source; `injectProperty` runs it as
      `@["m"] = -> 1` then `world.inform "x"`, which every load ({"$src"}) and now every copy
      (`Duplicator._compileInjectedMethods`) runs again.
      — CLOSED 2026-11-11 (self-ruled; loop unit U29, second shape). Reached through the product: an inspector Save
      of a method's text holding a second statement after the function kept the whole text as the function's
      source, so every copy and every load of a saved world ran that statement again — code run unasked; and a class's
      or a mixin's member edit replayed by every load ran its second statement the same way. RULED: a member's code
      that opens with a function IS that function, read as the compiler reads the text (the lexer's tokens: past a
      parameter list, whose defaults may be functions of their own, to the function's own arrow; past its body's
      INDENT … OUTDENT only line ends and comments) — so every door that stores a member's code refuses one with a
      statement after its function, before anything runs or changes, as code that does not compile is refused, and a
      loaded file is held to the same, the safety half. The first shape only stopped KEEPING such a text as the
      function's source; the independent review closing this unit showed that left the person stuck (the save's
      remedy, "Save it there as CoffeeScript", would refuse again forever), unnamed a mixin member edited that way
      (its fake `super` then threw on every call) and left the class and mixin doors replaying the statement on every
      load. LANDED: `Widget.functionLiteralReading` (the one reading: no function / one, or the line of the first
      statement after it); `Widget.spellsAFunctionLiteral` reads it (its users, `injectProperty` keeping a source and
      `Mixin._compiledMember` naming the function it makes); `Widget.refuseCodeAfterAFunction`, a refusal that reads
      like a compile error placed on the statement's line (`isCompileError`, `typedLocation`), which
      `_savingTypedCode` tells ("Cannot save this as code (line 2): a method's code is one function, and nothing may
      follow it"), called by `injectProperty`, `compilePropertyAssignments` (a paint tool's code blurb, whose splitter
      read a line not starting a name into the value before it), `Class.applyMemberEdit` and `Mixin.applyMemberEdit`;
      the load refuses a `{"$src"}` that is not one function literal (`_refProblem`) and a source-edit record whose
      code has a statement after its function (`_worldSectionProblem`). The rule was measured on twenty texts with the
      global CoffeeScript 2.7 lexer; the reviewer re-ran about 110 on the page's bundled 2.0.3 and both agree. Docs:
      the serialization reference (§5's kept source, §9's vetting). PROVEN: the serialization rig —
      `serialize2.aStatementAfterAFunctionIsRefused` (each of the four doors refuses `-> 1⏎window.…++` at line 2,
      storing nothing and running nothing; the inspector Save's gesture answers false and tells the person; a
      multi-line function and one with a function default keep their sources), the load guards
      `world.loadGuard.sourceWithASecondStatementRefused` (a `{"$src"}`) and
      `world.loadGuard.sourceEditWithASecondStatementRefused` (a class-level record), and (10)'s stray-source guard now
      held to its own refusal's words; with the old first-token reading planted, every door stored the text and ran
      it, and both loads took the file. `fg gauntlet` green (20 legs, no flake), `fg homepage` BOOT OK.
- [x] **An inspector on a typed array orders its indices as strings, and enumerates all of them** (found by the
      independent review closing "An inspector's Duplicate throws on a subject the copier refuses", in the plan's
      ledger; by reading; low). `InspectorWdgt` keeps the original order only for an `Array`, so a typed array lists 0, 1, 10,
      11, … 2; and it lists and sorts every index on each re-lay, so one on a surface's pixels (millions) hangs the page.
      — CLOSED 2026-11-11 (self-ruled; loop unit U30, second shape). Reached through the product: on the SWCanvas
      page an inspector drilled into the render canvas's surface and then its `data` (millions of bytes) builds a row
      WIDGET per index and sorts them as strings — the page hangs; a typed array of more than ten items lists 0, 1, 10,
      11, …, 2; and a long string, inspected with "Inspect selection", hangs the same way. RULED: ONE rule for every
      INDEXED subject — an Array (a subclass too, as the meta-system's `InputEventsQueue` is), a typed array (a buffer
      view with a length), a string — its items listed first, in index order, then its other members sorted as every
      other subject's are; at most `InspectorWdgt.MOST_ITEMS_LISTED` (1000) items, since no list of a million rows is
      one a person scrolls, and the CUT said where every inspector shows it, its code pane while no member is selected
      ("The first 1000 of 6758400 items are listed."), so the list never reads as the whole collection. The first
      shape said the cut in the window's title; the independent review closing this unit showed a drilled-in
      inspector stands without a window (the very reach path), the strip crops a title's tail, and the title went
      stale on a re-filter — so the pane, rebuilt with the list, says it. LANDED in `InspectorWdgt`:
      `_subjectsItemsAndNames` (a typed array's or a string's items by index below its length, with no walk of its own
      names — a key per item, millions on a surface; an Array's items the indices it HOLDS, read off the one walk of
      its names, so a sparse Array lists what it has), `_isAnIndex` (below 2^32 − 1), `_filteredMemberNames` (the
      methods and fields toggles hold for items too, an Array may hold functions), `_emptyPaneText`. A typed array's
      own named expandos are not listed (its own names are not walked). PROVEN: the serialization rig's
      `inspector.onAnIndexedSubjectListsItsItemsInOrderBounded` — a 12-byte typed array and a 12-character string list
      0…11 in order with an empty pane; a 3,000-byte typed array and a 3,000-character string list fewer items than
      they hold, in order, and the pane says how many of how many (the cut asserted against the collection, never the
      page's own cap, which a plant can move); an Array lists its items and then its named members sorted; a sparse
      Array its one held item; the methods toggle hides an item that is a function. Sizes the old listing still builds
      quickly (two of 20,000 outran the protocol timeout under a plant), so a plant of it fails rather than hanging
      the rig. Three plants, each failing it: the old rule (no
      items: every name walked and sorted as a string), no cap, the cut said nowhere. `fg gauntlet` green (20 legs, no
      flake), `fg homepage` BOOT OK.
- [x] **A class inspector's field row reads its record by NAME, whatever value the prototype now holds** (found by the
      independent review closing "A run that replaces a class's member reads as a recorded source it no longer runs",
      in the plan's ledger; reached: a run's `Klass::f = 2` on a field Klass records as `1`, then a class inspector's
      `f` row). `ClassInspectorWdgt._sourceForFieldMember` shows the class's (or the donor's) recorded source for a
      field: a value has no identity to key a record to, so a run's write, or a method a run replaced with a value,
      reads as a source the prototype no longer holds. Functions read the source kept with them (`Class.memberRecordOf`).
      — CLOSED 2026-11-11 (self-ruled; loop unit U31). RULED: the field twin of the function rule — keep, WITH each
      prototype, the VALUE each recorded field source made there, and show a field's recorded source only while the
      inspected subject still reads that very value; otherwise the row shows the value, as an object inspector does;
      and a rename carries a field's source only then too. LANDED: `Class.fieldRecordHolds` over a WeakMap of
      prototype → Map of name → value (compared by `Object.is`), filled two ways — `keepFieldRecord`, a class BODY's
      field (own, and its mixins' donated ones: `_keepMyMembersRecords`), kept ONCE as a function's record is, so the
      reflective layer's later ingest of a class already made keeps the record it has; `refreshFieldRecord`, an EDIT
      (`Class.applyMemberEdit`, `Class.removeMember`, `Mixin.injectInto`, `Mixin.withdrawFrom`), the record becoming
      the value the edit made and dropped when the member is gone or is now a function; `ClassInspectorWdgt.
      _sourceForFieldMember` asks it for the class's own source and the donor's alike (a write shadowing a field
      further down reads as its value too), and `_applyPropertyRename`'s guard asks it for a field as it asks
      `memberRecordOf` for a function. Docs: `mixins.md`'s donated-field attribution; the record-keeping header. The
      first shape kept the LATEST value made everywhere and kept no record for a function: the independent review
      closing this unit showed a re-ingest then overwrote a correct record with a run's value, a field edited into a
      function kept a stale record that later vouched for a wrong source, and a rename of a row showing its value
      carried the recorded source; all three fixed above. Left in the filed pre-compiled item: a run's write made
      before the layer arrives on a pre-compiled tree, where no earlier record exists to keep. PROVEN: the
      serialization rig's `inspector.aClassFieldRowShowsItsRecordOnlyWhileItsValueHolds` — a class body's record shows
      (Widget's `clickOutsideMeOrAnyOfMeChildrenCallback`, whose source `[undefined]` is no value's text); on
      `ListWdgt`'s `offersScrollPolicyToggle` a run's write reads as its value, a rename then is refused, a class edit
      reads as its source, a field edited into a function and written back by a run as its value; on
      `VerticalStackPanelWdgt`'s `clipsAtRectangularBounds` (donated by `ClippingAtRectangularBoundsMixin`) the donor's
      source shows, attributed, a run's write as its value, a mixin edit as its source; every prototype and the mixin's
      store put back. Two plants, each failing it: the old by-name reading (`fieldRecordHolds` answering yes) and the
      first shape's record keeping (a member edited into a function keeping its stale field record). `fg gauntlet`
      green on both shapes (20 legs each, no flake), `fg homepage` BOOT OK on both.
- [x] **The parts-snapshot rig awaits product promises through unbounded evaluates** (found by the independent review
      closing "The boot smoke is a gate with no rule registry and no standing bite-proof", in the plan's ledger;
      reached: the gauntlet's `parts` leg, with a product hang in a part's load or a file's restore).
      `Fizzygum-tests/scripts/parts-snapshot-load-headless.js` makes eight single evaluates that await a product promise
      — making the widget files, the rejecting load, the file doors' report, opening the widget files twice, making and
      loading the source-edit files — each bounded only by Puppeteer's 180 s protocol timeout; two of them outlast the
      leg's 300 s alarm, which kills the rig before it says which step hung. The boot smoke's are bounded through
      `lib/headless-driver.js` `answeredWithin(promise, ms, what)`, which this rig can take as it stands.
      — CLOSED 2026-11-12 (self-ruled; loop unit U33). MEASURED first: at idle the filed alarm claim did not hold — a
      step stuck in a script waited the protocol timeout, and the rig ended INVALID at 194 s, inside `fg`'s 300 s alarm
      for it, saying only "Runtime.callFunctionOn timed out", no step named; a hang in a later step, or on a loaded
      machine, can still pass the alarm. RULED: the boot smoke's bound, taken as it stands, by all three of the `parts`
      leg's rigs (the independent review of the first shape found the two siblings unbounded the same way: the same
      family, so one fix) — every single evaluate through `answeredWithin(promise, STEP_MS, what)` (60 s), so a hang
      reads as each rig reads anything that stops it measuring, INVALID (exit 2), naming the step, at 60 s. LANDED:
      `parts-snapshot-load-headless.js`'s eight evaluates (making the widget files, the rejecting load, the file doors
      reporting a failed part, opening the widget files, opening the files no part can serve, making the source-edit
      files, loading the class- and the mixin-edit file); `parts-lazy-icons-headless.js`'s seven (reading the desktop
      at boot, opening the Examples folder, reading every icon's class name, the bin route and its on-tree reading,
      clicking each sampled app and reading what it defined: each waits seconds on the page's own timers, which a
      stuck page never runs); `parts-lazy-load-headless.js`'s five readings beside its polls. PROVEN: each rig's
      proof gains an INVALID run (exit 2, its line, no rule) planting a hang in the earliest step it reaches — the
      snapshot rig's the authoring part's load never settling ("… (making the widget files)", page 1, the first step
      to ask for it; the pending load held, as the registry holds one in flight — a promise nothing holds is collected,
      and the protocol answers at once, "Promise was collected", no step named), the icons rig's the folder's shortcut stuck in a script when pressed ("… (opening the Examples
      folder)"), the load rig's a widget's layout editing stuck ("… (arming the destroy-mid-load race)"); with the
      snapshot rig's bound removed (a copy of the rig), a stuck step waited the protocol timeout and named no step.
      The proofs: 30 cases (252 s), 13 (126 s), 15 (131 s). `fg gauntlet` green on both shapes (20 legs each).
- [x] **Only an inspector's Save gives a banned widget another chance** (found by the independent review closing "A step
      that throws throws on every frame it is due", in the plan's ledger; reached: a person fixes a widget whose paint
      or step threw by running typed code — a console's "Run all" redefining the method — or by a class edit's other
      doors). `WorldWdgt.giveBannedWidgetsAnotherChance` is called by `InspectorWdgt.save` alone, so the widget stays
      hidden or unstepped though its code is fixed, while the error log tells the person "Edit/save any source code to
      give them another chance". The world already has one notice that code changed (`noteCodeChanged`, a class
      edit's or a load's) and a typed run tells its receiver (`TextWdgt._runningTypedCode`): the re-admission belongs
      where code changes, wherever that is.
      — CLOSED 2026-11-12 (self-ruled; loop unit U34). MEASURED (the callers, by grep): a person's code edits and the
      text run rows end in one of two notices — `Widget.sourceChanged` (a person's edit or run under one widget: an
      object inspector's save, add, rename and remove, and every text run row, `TextWdgt._runningTypedCode`) and
      `WorldWdgt.noteCodeChanged` (a class inspector's member edits and mixin rows, `ClassInspectorWdgt._notifyOfEdit`;
      a load's replay calls it too, after its teardown emptied both ban lists, so it finds no one there) — and the
      re-admission sat beside neither. RULED: the re-admission rides both notices, so every gesture that tells anyone
      it changed something gives every banned widget another chance, now and for any later gesture that tells; the
      Save's own call is deleted (its edit reaches one of the two). LANDED: `Widget._sourceChangedNoSettle` (the core:
      `sourceChanged` stays the canonical wrap, the thin-wraps gate's rule) and `noteCodeChanged` each call
      `giveBannedWidgetsAnotherChance` (which settles nothing: it shows and un-bans), `InspectorWdgt.save`'s call gone;
      the verb's, the notices' and widget-authoring-guidelines.md's stepping paragraph say so. The stated cost: the
      world cannot tell which change is the mend, so a change that mended nothing has the widget throw once more, at a
      throw's whole cost — the error log shown again and brought to the front, and for a step the world soft-reset
      (what the hand carries dropped, its hover and the editing focus cleared) — what an inspector's Save that mended
      nothing always cost, now on every run row too (the independent review's A1; ruled acceptable, the retry being
      the point). Two gestures that change something tell NO notice, and so re-admit nothing: a run that throws after
      changing something, and a script shortcut's press — filed ("A run that throws, or a script shortcut's press,
      tells no one it changed anything"). PROVEN: a new assertion-only test,
      `SystemTest_macroEveryCodeChangeGivesBannedWidgetsAnotherChance` — a console's run of a fixed step lifts a step
      ban, a class inspector's Add steps a still-broken probe exactly once more — passing alone and as a FOLLOWER
      (`run-sequence-headless.js`, mouse and finger, no `WORLD_INVENTORY_` line); two plants, each taking the
      re-admission out of one notice, fail its checks (the run's two; the class edit's "stepped once more"), and the
      `sourceChanged` one also fails `SystemTest_macroAStepThatThrowsStopsStepping`'s Save half, which keeps proving
      the Save.

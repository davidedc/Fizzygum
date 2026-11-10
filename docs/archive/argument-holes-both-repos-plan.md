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

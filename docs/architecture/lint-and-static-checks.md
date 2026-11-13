# Fizzygum build-time lint & static-checks — reference

**What this is.** The durable, living reference for Fizzygum's build-time checking system — every gate that
`build_it_please.sh` runs, what each enforces, how they're wired, the predicates and rules they key off, the in-code
markers that exempt a line, the reasoned boundaries (what is deliberately *not* checked, and why), and how to extend or
debug the system. Written to be picked up **cold** by a maintainer with no prior context.

**What this is NOT.** It is not the *why* of the runtime layout architecture — for the flush model, the settle tiers,
the convergence loop, and the invariant these gates protect, see **`docs/archive/layout-system-architecture-assessment.md`**
(the engine) — this doc says *what is checked + how to extend*; that one says *why*. It is also not a to-do: the arc
that built rule [G] and these notes is recorded in **`docs/archive/lint-ratchet-static-checks-plan.md`** (STATUS: EXECUTED),
which now points *here* for current state and keeps only the execution / rejected-transitive history.

> **Orientation.** Fizzygum ships its ~490 class sources as escaped TEXT and compiles them *in-browser* at boot
> (no module system; every class is a global). The build only runs `coffee` over `src/boot/*`. So a green build had,
> historically, never checked the *syntax* — let alone the *flow soundness* — of the class files; a fault surfaced only
> when a human opened the build in a browser. These gates close that gap at build time. They are **pure tooling**
> (`buildSystem/*.js` is not compiled into the world): editing a gate needs no behaviour rebuild, only a re-run of the
> build to see the verdict; a gate edit *cannot* change a screenshot.

---

## 1. The runtime invariant the layering gate protects (summary)

**THE INVARIANT: one flush per OUTERMOST public mutation; low-level code never settles.** A *public* geometry/structure
mutator (`setExtent`/`setBounds`/`setWidth`/`setHeight`/`moveTo`, the text setters, `add`/`destroy`/`close`/
`fullDestroy`/`collapse`/`unCollapse`/…) leaves the world consistent on return by self-settling through the single
settle tier `_settleLayoutsAfter` (`Widget.coffee`), which sets `world._inLayoutMutation`, runs the mutation's
non-settling core, then flushes `recalculateLayouts()` **exactly once**. Nested public calls must NOT each open their
own flush — internal/low-level code is *forced* onto the non-settling `_<name>NoSettle` cores and the raw/silent
setters, which schedule nothing. (Depth: `docs/archive/layout-system-architecture-assessment.md`.)

**Two RUNTIME backstops** raise this from convention to a checked property — the static gates make the same checks
*exhaustive and preventive*, and catch the name-recognized/direct cases at build time; the throws backstop the
**dynamic/transitive** cases the name-scanner cannot see:

| Runtime throw | Where (grep the symbol; lines drift) | Fires when | Static twin |
|---|---|---|---|
| One-flush re-entrancy | `Widget.coffee` `_settleLayoutsAfter` (~:928) | a public geometry setter is reached on an *attached* widget while `_inLayoutMutation`/`_recalculatingLayouts` is already true | rules **[A]/[G]** (low-level code must not reach the public/wrapper layer) |
| `FLOWRULE_VIOLATION` | `Widget.coffee` `_invalidateLayout` (~:4919) | an immediate-mutator corner/convenience (`_apply*`/`_commit*`/`_move*`) schedules layout during a pass | rule **[E]** |

The gates "cannot be spoofed" (they read all shipped source, not a runtime token) but only see what a NAME scanner can;
the throws see the real dynamic receiver but only on tested paths. They are complementary.

---

## 2. The tier predicates — the single source of truth

The layout-method layering is **formally defined**, once, in `buildSystem/check-layering.js`. Two nested tiers:

```js
// LOW-LEVEL (rule [A]/[G] subject): must not reach UP into the public self-flushing layer.
const isLowLevel = (name) =>
  /^_/.test(name) ||          // any leading underscore — the _ internal + __ leaf private tiers
  /NoSettle$/.test(name);     // the *NoSettle cores
// (the old /^raw[A-Z]/ arm is retired: zero raw* defs exist in src; rule [M] keeps them out)
// the strict INNER subset (rule [E] subject): may MUTATE geometry, never SCHEDULE.
const isImmediateMutator = (name) =>
  MUTATORS.polymorphicApplies.includes(name) ||   // the polymorphic apply corners `_apply<Geom>`, `_applyGrantedBounds` among them
  MUTATORS.conveniences.includes(name);           // the convenience movers / setters / resizer (`_move*`, `_setWidthSizeHeightAccordingly`, `_resizeToWithoutSpacing`)
```

`MUTATORS` is `buildSystem/lib/immediate-mutators.js`: the apply 2x2's NAMED groups (`polymorphicApplies`,
`bypassTwins`, `commitCorners`, `conveniences`), asserted against src both ways — every entry names a method defined in
src, and every Widget-own `_apply*`/`_commit*` method is claimed by a group or stated in its `NOT_CORNERS` table — so a
renamed corner makes the gate exit 2 instead of quietly leaving rule [E]'s subject. The predicate deliberately reads two
groups: the `_apply*Base` bypass twins and the silent `_commitBounds` are not [E]'s subject (rule [K] reads all three
corner groups; `census-nosettle-naming.js` reads every group). `isLowLevel ⊃ isImmediateMutator` (every immediate
mutator is `_`-prefixed). **Prose must POINT at these predicates, never re-define the tiers** — any doc that says
"low-level"/"immediate mutator" means *exactly whatever these match*.
The names come from the geometry-apply **2×2** of the naming convention (post-Tier-B REACT × DISPATCH: `__commit*` leaf /
`_apply*Base` override-bypass arrange twin / `_apply*` polymorphic apply / `_commit*AndNotify` notify-only); the old
`raw`/`silent`/`fullRaw` prefixes were
retired (a build-time fragment-ban, rule **[M]**, keeps them out) and the `__` leaf tier has its own no-orchestration
rule **[I]**. Full convention + rationale: `docs/architecture/layering-naming-convention.md`.

---

## 3. Gate inventory

All gates are plain Node line-scanners in `buildSystem/` (or, for the test gates, `Fizzygum-tests/scripts/`), wired into
`build_it_please.sh` with the **same shape**: behind `if ! $noSyntaxCheck`, an explicit `$?` check, and a loud
`exit 1` on failure. (Most carry their own `if` block; the seven small ones from trailing-whitespace to part-edges share
one — the per-gate `$?`/`exit 1` is the invariant, the block boundary is not.) **Exit codes:** `0` clean · `1` violation
· `2` operational error. **Shared escape hatch:**
`--noSyntaxCheck` skips *every* gate (use to bisect a gate bug; never to ship).

**Every check this relies on RUNS, and the two places reliance is written in code are held to it.** A check nothing runs
proves nothing: a self-test rots, a stale-name check goes stale silently, and a sanction can name a guard that never
fires. `buildSystem/lib/what-runs.js` is the ONE statement of what runs — the scripts the build, the discovered
self-tests and the umbrella `fg`'s presuite/gauntlet legs LAUNCH, plus the naming table the discovering runners read.
A launch is a shell command that executes the script or hands it to an interpreter (read by a small shell lexer, so an
echo, a test, a heredoc or a comment that names a script runs nothing), a JS `require`, or a script named in a
`path.join`/`path.resolve` call; a self-test's own edges are not followed (it exercises its subject on fixtures). The
blind spots are in its header. It also holds the ONE definition of the TOOLING'S OWN FILES (`scriptFiles`): Fizzygum's
`buildSystem/` and `scripts/` and top-level shell scripts, and the tests repo's `scripts/` — `.js`, `.sh`, `.py`; never a
dot entry (a gitignored `scripts/.scratch`), a `node_modules` or a `__pycache__` (`skippedEntry`), and a symlink is refused
(`TOOLING_TREE_MALFORMED`). Every reader of the tooling takes its files from it — the run set and discovery, the hand-list
scan, the Node rigs' code set (`lib/tests-repo-code.js`), the tooling's own source-scanning self-tests, and the similar-
and duplicate-code scans (`node buildSystem/lib/what-runs.js --list-scripts`) — as every reader of the CoffeeScript takes
it from `lib/source-files.js`. Two rules read it:
- **A SELF-TEST is a FILE, found by name and run** — `<subject>-selftest.js` (pure Node; the build's FIRST GATE runs every
  one in both repos) or `<subject>-selftest-headless.js` (needs the built page; the gauntlet's `selftests` leg). Each ends
  with the shared verdict line and its case count (`lib/selftest-verdict.js`). There is no self-test switch: one offered
  in a script's code (`SELFTEST_OUTSIDE_CONVENTION`) or a file named like a self-test that no tier runs
  (`SELFTEST_UNDISCOVERED`) fails the build, and a gate refuses an argument it does not know (exit 2; a `--self-test`
  is told the name of its self-test file). A new self-test is a new file: nothing to register.
- **A SANCTION's guard must RUN** (`check-hand-lists`, row below) — a guard that exists and never runs fails as
  `SANCTION_GUARD_NEVER_RUNS`, and a token guard must be EMITTED (in a string, in code) by a file that runs.
⚠ What neither can hold is PROSE: a doc saying a gate runs at a commit point is checked by reading `fg`. Arc:
`docs/archive/unrun-checks-plan.md`.

**Every gate's every RULE is proven to BITE by a self-test that runs the GATE — and the build refuses a gate without
one.** A rule proven by a planted violation once, at authoring, can stop biting and stay green, so the plant is a
standing self-test, not a recipe in a header; and it runs the REAL gate, never just an engine or the instrument under it
(a proof of the instrument alone leaves the gate's own greps, counts and exit codes unproven, and that is where a
reformatted line goes blind). Three pieces hold it:
- **The registry** (`buildSystem/lib/gate-rules.js`): a gate NAMES every rule it fails on — `rules.fired('<ID>', line)`,
  the ids read from its own CODE (a `.fired(` literal) or `declare`d from a table it already keeps (stinks ids, gate
  tokens, a prelude's finding kinds). On the way out it prints `[<gate>] RULES fired: … · of: … · unplantable: …`; an
  exit 1 that named no rule reads as exit 2 (`RULELESS_FAILURE`: a failure no rule names is operational), a rule fired
  on an exit 0 likewise (`RULE_FIRED_BUT_PASSED`). A rule no plant can reach says why in the gate's header,
  `// bite-unplantable: <ID> — <reason>` (stale if the gate cannot fire it). A gate run as a program writes its stdout
  and stderr synchronously: on macOS a pipe write is asynchronous in Node, and a gate that prints and then calls
  `process.exit` loses what a slow reader had not yet taken — every line of it, measured. The shell gates' twin is
  `gate_rules_init` / `gate_rule` in `Fizzygum-tests/scripts/lib/audited-suite-with-infra-retry.sh` (an EXIT trap).
- **The proof**, one judge (`buildSystem/lib/prove-rules.js`) behind two runners: a static gate's `<gate>-selftest.js`
  plants a copy of its input tree (`lib/planted-src.js` `proveGate`, through the gate's `--src=` / `--tests-repo=` /
  `--tests-dir=` / `--docs=` / `--parts=` / `--umbrella=` rail; a gate reading the compiled sources takes `testsRepo:
  true`, a copy of the tests repo's code where a plant keyed `harness/<rel>` lands); a gauntlet leg's `<rig>-selftest-headless.js` plants page JavaScript
  through the rig's `--prelude=` (`Fizzygum-tests/scripts/lib/gate-bite-proof.js` `proveLeg`), with the rig's own subset
  rails keeping it cheap (`--tests=`, `--apps=`, `--sections=`, `--expectations=`, `--baseline=`, `--audit-dir=`).
  The judge holds: the CONTROL (the input unplanted, plus every sanctioned form) passes firing no rule; each planted
  run fails naming exactly the rules it planted, each matched by ITS OWN violation line (a crash is no bite, and a
  summary count matches whatever happens); every plant APPLIES (a page plant that cannot find its hook says
  `PLANT_NOT_APPLIED` — an inline one through `gate-bite-proof.js` `whenPresent`, which gives up at the world, or once a
  lazy part has arrived, so inside the run; a file plant 60 frames after the world); a plant of a
  measurement failure reads INVALID (exit 2, never a rule); and
  together the runs plant EVERY rule the gate can fire — a gate that grows a rule fails its proof until the proof
  plants it.
- **The census** (`run-selftests.js`, the build's first gate): every script the build, its pre-commit check
  (`build_and_smoke.sh`, which launches the boot smoke) or an `fg` leg LAUNCHES
  (`lib/what-runs.js`'s run set: ANY launch edge makes a script a program, however else it is reached — but never a
  `*-prelude.js` instrument a gate injects, nor a self-test, which is a proof the runner judges by its own
  `SELFTEST_*` rules) is a gate unless its HEADER says `not-a-gate: <reason>` (the build steps, a tool or reader a gate
  runs and judges, a sourced library), and fails the build as `GATE_WITHOUT_REGISTRY` or `GATE_WITHOUT_PROOF` (no
  self-test that calls a proof helper — `proveGate` / `proveLeg` — launches it, by `path.join(__dirname, '<gate>')`).
  That census IS this table's proof column: every row below, and every gauntlet leg, has its proof, and a new gate
  arrives with one or fails the build. A value flag written with a space (`--src DIR`, `--prelude FILE`, `--tests X`)
  is refused (exit 2) by the shared readers (`lib/cli-args.js`, the tests repo's `lib/cli.js` and `lib/page-rails.js`):
  its value would be dropped, and the run would check the default tree, unplanted.
Arcs: `docs/archive/bite-proofs-plan.md`, `docs/archive/every-gate-bites-plan.md`.

| Gate | File | Wired (`build_it_please.sh` — grep `check-<name>.js`; lines drift) | Enforces | Ratchet mechanism |
|---|---|---|---|---|
| **self-tests** | **`buildSystem/run-selftests.js`** | **~:333 (FIRST: a gate whose proof fails gives verdicts not worth reading)** | **every `<subject>-selftest.js` among the tooling's own files (`lib/what-runs.js` `scriptFiles`: Fizzygum's `buildSystem/` and `scripts/`, and when present `Fizzygum-tests/scripts/`), found by NAME, exits 0 AND ends with the shared verdict line (`lib/selftest-verdict.js`: `[name] SELFTEST PASS — N cases`) with N ≥ 1 — else `SELFTEST_FAILED` / `SELFTEST_NO_VERDICT` / `SELFTEST_VACUOUS`; a self-test switch (`--self-test`, `--selftest`, a `…SELFTEST` variable, a `lib/cli.js` reader asking for one) offered in a script's CODE is `SELFTEST_OUTSIDE_CONVENTION`, and a file in either repo named like a self-test that no tier runs (misspelt, misplaced, wrong extension) is `SELFTEST_UNDISCOVERED`; and the GATE CENSUS (above): every launched gate names its rules (`GATE_WITHOUT_REGISTRY`) and has a proof that launches it (`GATE_WITHOUT_PROOF`). ~5 s. `--headless` runs the `-selftest-headless.js` tier instead (the gauntlet's `selftests` leg); `--repo=tests` is `npm run selftest`** | — (discovery IS the registration: a new self-test is a new file) |
| aim-census tables | `Fizzygum-tests/scripts/aim-census.js --tables-only` | ~:928 | the aim census's own TABLES — every MacroToolkit verb classified, every class and member they name declared — held to Fizzygum's source and to the tests' calls both ways (`AIM-CENSUS STALE NAME` / `UNCLASSIFIED VERB` / `UNKNOWN VERB`, exit 1; `EMPTY DERIVATION`, exit 2), so a verb deleted or renamed in `src/macros` fails the change that did it. Its MEASUREMENT (where each test aims, and how much each aim assumes) stays advisory. ~0.2 s | — (runs whenever the sibling repo is present, whatever the profile ships) |
| syntax | `buildSystem/check-coffee-syntax.js` | ~:343 | CoffeeScript *parse* errors, compiled the **fragmented** way the browser does; and a class MEMBER that LOSES A NAME to the meta-system's helper strip (its compiled `var` head declares anything outside the helper globals boot provides — a `modulo`/`splice` helper, a hoisted compiler temporary) | — (the provided set is read from `Class._memberNamesThatMustStayAnonymous` and held against boot's `window.<helper> =` assignments) |
| shippable-coverage | `buildSystem/check-shippable-coverage.js` | ~:366 | every directory of the compiled sources (§3c: `src/` and the harness) holding `.coffee` files is CLAIMED BY A PART in `parts.json`, and every `src/boot` file DECLARED by one (its `bootPrelude` or `bootScripts`) — a dir no part claims, or a boot file none declares, ships NOTHING (`UNSHIPPED`); and boot's by-name fetches (`js/src/<name>-min.js` in a boot file's CODE, comments blanked) agree with the declared boot scripts of the fetcher's own part, both ways (`BOOT_FETCH_UNDECLARED`, naming file:line; `BOOT_SCRIPT_UNFETCHED`), so a rename on one side fails the build instead of 404ing at every boot, exits 0, and surfaces only at runtime (a `<NewClass> is not defined`) | none: a `src/boot` file is held to a declaration too — its part's `bootPrelude` or `bootScripts` (`build.py --list-boot`) |
| **layering** | **`buildSystem/check-layering.js`** | **~:388** | **flow soundness + the naming convention — rules [A]–[T] (§4); a class-side method's tier is read from its bare name (§6b)** | per-method `# layout-apply-sanctioned` [F] / `# nosettle-sanctioned` [G] / `# early-return-sanctioned` [H] markers; per-line `# macro-private-call-sanctioned: <reason>` [D] for a test ORACLE that must call a private verb (the `world._fullChanged()` ground-truth repaints) |
| **invalidation-receivers** | **`buildSystem/check-invalidation-receivers.js`** | **~:407** | **widget-citizenship point 2: invalidation is SELF-invalidation, and PRIVATE (`_changed`/`_fullChanged`) — no `<expr>._changed()`/`<expr>._fullChanged()` on another widget (if A's action affects B, B marks itself changed in the method A invoked on it). The ONLY allowed receiver is `@` (dotless, never matches); the singletons are NOT exempt — cross-object repaint goes through their intent-named public methods (`noteWallpaperChanged`/`resetImmutableBackBuffersCache`/`noteTextChanged`/`noteCarriedWidgetChanged`); there is NO general-purpose public repaint verb. The paint executor `_repaintDamagedRects` (the world's once-per-cycle damage-rect flush) is in the same gated private family. The gated names are READ, not spelled: the repaint verbs from Widget's own definitions (`lib/repaint-verbs.js`, shared with `check-layering` and the call census), each also in its legacy public spelling so it cannot slip back in, plus the paint executor, whose name is asserted against `WorldWdgt.coffee` (stale ⇒ fail)** | `# cross-invalidation-sanctioned: <reason>` on or directly above the line (the structural add (the re-homed widget's old footprint and its new one)/drop/z-order/shadow dispatchers, the world's selection-overlay reconciler (two), the world's atlas-warm orchestration, FileLoading's async-asset repaint, the own-sub-part marks in FrameWdgt (its rows, after a pin) and FrameBarWdgt (its background), and the harness's paint-truthfulness audit (three: the oracle's frame completion, its forced full repaint and the flush that paints it)) |
| dead-method | `buildSystem/check-dead-methods.js` | ~:425 | a method defined in the compiled sources, src and the harness (class methods and class-side methods alike — the latter inventoried under their BARE name) that nothing REACHES, by the one reference rule `lib/method-references.js` (a property access, a whole-name string, a name template, a computed access on a named class — §3c) read from the CODE of src and the tests repo (harness, macro sources, `scripts/` rigs; never prose); a name ASSEMBLED with `+` or dispatched through an arbitrary object (`@target[action]`) reads dead | allowlist `dead-method-allowlist.txt`; fails on a NEW dead method, and on an entry no longer dead (`STALE_ALLOWLIST_ENTRY`) |
| hand-lists | `buildSystem/check-hand-lists.js` | ~:446 | a STRING-LIST literal naming classes or members (at least two items, and at least half of them, are class or member names) is a DECLARATION (`@serializationTransients`, `requiredParts`, `optionalParts`) or carries `# hand-list-sanctioned: <what fails>` naming a guard that RUNS — a gate/rig file the build, a discovered self-test or an `fg` presuite/gauntlet leg launches (`lib/what-runs.js`), a `SystemTest_<name>`, or a failure token a running file emits, resolved mechanically — or it counts as UNSANCTIONED. Multi-line by design (the lists that rot are one name per line). Scans src + buildSystem and, when present, the tests repo's scripts + harness (that half SKIPS without it). ⚠ Blind to object tables, regex alternations, `switch` arms, push sequences and runtime-built names (§5). Modes: `--census` (every list, classified, each guard as runs / never runs), `--files` (plants: every unsanctioned list fails), `--fg=<path>` (read another fg, or none); its self-test is `check-hand-lists-selftest.js` | inline per-repo `BASELINE_FIZZYGUM` / `BASELINE_TESTS` of unsanctioned lists (the stinks idiom); a sanction naming no guard, one whose every guard never runs (`SANCTION_GUARD_NEVER_RUNS`), an empty one and a stale one (sanctioning no name list) fail outright; without the umbrella's `fg` a guard that may run only in a leg is a NOTE |
| **unresolved-sends** | **`buildSystem/check-unresolved-sends.js`** | **~:467** | the INVERSE of dead-method: a CALL `[@.]name(` in src, the harness or a test's macro source that NOBODY implements — a guaranteed runtime `TypeError` on any path reaching it (a macro's own definitions resolve only its own calls) | allowlist `unresolved-sends-allowlist.txt` (vendor + dynamic, `name # reason`); in-file `BUILTINS` for platform API, BARE (`push`) by default and KEYED by receiver (`Math.round`) for a name Fizzygum also defines that only a platform global sends — the form held to the sends (`BUILTINS_NOT_KEYED`, `BUILTINS_KEYED_NOTHING_TO_UNMASK`, `BUILTINS_KEYED_OFF_PLATFORM`, a stated `PLATFORM_GLOBALS`) — and an entry excusing nothing fails (`STALE_ALLOWLIST_ENTRY`) in either |
| stinks | `buildSystem/check-stinks.js` | ~:465 | named smells driven to a baseline COUNT | per-smell inline `baseline`; fails on EXCEEDING it |
| call-arguments | `buildSystem/check-call-arguments.js` | ~:529 | every call's ARGUMENTS against its callee, over EVERY call site of BOTH repos (src, the harness, every macro source, the `MacroToolkit` heredocs, the tests repo's scripts), read by real parsers (`lib/call-sites.js`: the browser's own meta-compiler and CoffeeScript 2.0.3, acorn for JS — an implicit object is ONE argument, a string is never a call). Three rules, the law in [`constructor-and-parameter-conventions.md`](constructor-and-parameter-conventions.md) §5: `HOLE` — R3's **hole test** with its CALLERS TEST mechanized (an `undefined` before a present argument is a hole iff another call of the same callee reaches less far; that WITNESS is printed; otherwise a VALUE, `--values` lists them); `EXTRA_ARGUMENT` — more arguments than any definition the call can reach declares (judged only where its TARGET is certainly among the definitions it reaches — what runs where it runs (page code, a macro program, a script module), a bare call resolved lexically, a `new` of the one class its name means there, a send to `@`/`this` or `X.` of a class whose whole chain was read — the widest of them; by name alone `Math.max a, b, c` would read against `Point::max`); `POSITIONAL_INTO_OPTIONS` — `@`, a literal, an array, a function or a `new` in an `opts = {}` slot. INVALID (exit 2) for a source it cannot read, a super it cannot place, or a half that read nothing. `census-call-arity.js` queries the same table (§3c) | none — an exact zero: no baseline and no sanction marker (a call the gate misjudges is reshaped). Its stated limits — foreign callees, a dynamic `new`, this-args, code in strings other than the heredocs, unknown-arity calls; for the arity rules a receiver the parse cannot see or a class with a foreign ancestor, a callee also bound or assigned as a value (`canvas.width = …` leaves `@width()` unjudged), a callee taking any number, a method no code defines as a member or field, a script's call of a name its module neither binds nor imports, `new @constructor`, a lone variable in an options slot — are in its header and the conventions doc's §5 |
| **menu-actions** | **`buildSystem/check-menu-actions.js`** | **~:509** | **menu-item wiring. A menu action is dispatched through ButtonWdgt's fixed four-slot convention (`@target[@action].call @target, menuItem, panelTarget, arg1, arg2`), which the call site never names. HARD (sound): a function literal in the action slot (`@target[@action]` coerces it to a string key, so the click throws); a string literal where `opts` goes; and — RULE 1b — a `@`-targeted string action that RESOLVES nowhere. RATCHET at 0: an UNREAD parameter on a menu-dispatched verb must be NAMED as unread (`ignored`/`unused`) — padding a signature to reach the slot you want puts widgets into parameters whose names promise otherwise, and forces every other caller to punch `undefined` through.** ⚠ TWO blind spots, both structural: it cannot see whether a parameter that IS read is read as the right THING; and it cannot see a parameter that is MISSING — a verb needing a subject it never declares reads as clean, because there is nothing unread to flag. (A THIRD is covered by RULE 1b: an action naming a method NOTHING defines. The general case stays unresolvable — the receiver of `addMenuItem "…", someExpression, "verb"` is a runtime value — but `@` names its receiver structurally, so the rule resolves the string against the union of `chainOf(X)` over every X whose chain contains the enclosing class, which is exactly the set `@` could be an instance of, plus the methods a `*TestSupport` class installs onto a core class. That union is what makes it SOUND: `Widget` wires `"setTargetAndActionWithOnesPickedFromMenu"`, which lives in `ControllerWdgt`. 136 rows covered; the dead `"pin"` row of 2018 is the shape it catches. The runtime twin still owns the rest: non-`@` targets, and the dispatch itself.) Those blind spots are the class of bug only a rig that CLICKS the item can catch, which is why `fg menusweep` exists beside it — it resolves every row's action against its target BEFORE the liveness skip (so a row sitting behind a destructive one in the same walk is resolution-checked even where it is never dispatched) and carries a `MenuWdgt` and a `PromptWdgt` root, the two classes whose own context menu no other root stands in. It is also where a row's `opensSubmenu` flag (the drawn chevron) meets the act: each dispatched row must open a menu exactly when it is flagged (`SUBMENU_FLAG_MISMATCH`, allowlist `CONDITIONAL_OPENERS`), because no text scan can tell what an action opens — and where its LABEL meets the act too: "…" ends it exactly when the act asks for more from you (`ELLIPSIS_MISMATCH`, allowlist `ELLIPSIS_EXCEPTIONS`; ASCII "..." fails on its own, `ASCII_ELLIPSIS`), and every row seen is in sentence case (`SENTENCE_CASE`, allowlist `SENTENCE_CASE_EXCEPTIONS`). ⓘ RULE 1 has TWO DOORS: besides `addMenuItem`/`prependMenuItem`, `prompt`/`textPrompt` take a `callback` that the prompt's OK delivers to (`PromptWdgt.deliverValue`: `@target[@callback].call @target, value`) — the same proof applies, and those callbacks count as menu-dispatched verbs for the RULE 3 ratchet too. ⚠ A prompt's BUTTONS themselves (`PromptWdgt._addButtonsInto`: `close`, `deliverValue`; the save-shortcut prompt's `destroy`, `close`, `createReferenceAndCloseFromMenu`) are `new SimpleButtonWdgt target, "action"` constructions, which this gate does not read; `fg menusweep` covers the OK at runtime (it presses every prompt's `okButton` and fails on a prompt with none, `PROMPT_OK_MISSING`, or a run under its prompt floor, `PROMPT_OK_CHECK_VACUOUS`), and Close / Cancel / Don't save dispatch the parameterless `Widget.close` / `Widget.destroy`, which only the suite presses | rules 1–2 are HARD; the unread-parameter rule is the inline `RULE3_BASELINE = 0` ratchet |
| thin-wrap | `buildSystem/check-thin-wraps.js` | ~:527 | a method owning a `_<name>NoSettle` twin — public `<name>` or private `_<name>` — is the ONE canonical mechanical wrap | per-method `# thin-wrap-exempt: <reason>`; SKIPS a twinless `*NoSettle` |
| trailing-whitespace | `buildSystem/check-trailing-whitespace.js` | ~:546 | no trailing whitespace on a line that has CONTENT (`/\S[ \t]+$/`) — source hygiene (whitespace does not change what a `super` calls: the super rewrite reads tokens) | — (whitespace-only lines are deliberately NOT flagged: invisible, harmless, and in the hundreds) |
| scheduled-checks | `buildSystem/check-scheduled-checks.js` | ~:555 | a `# CHECK AFTER <date>` time-bomb reminder must not be OVERDUE — nor unparseable, since one that can never fire defeats the purpose | — (act on it, then delete the marker or push the date forward) |
| stringified-scripts | `buildSystem/check-stringified-scripts.js` | ~:564 | `new ScriptWdgt """…"""` stringified code belongs in USER code, not the core framework; core is at 0 and stays there | `# stringified-script-sanctioned: <reason>` on the line or in the comment block directly above |
| region-markers [tombstone] | `buildSystem/check-region-markers.js` | ~:573 | the per-REGION `# »>>` text-exclusion mechanism (retired in arc 3, after it was found stripping PRODUCT code out of production) must stay at zero, and an opener must never be unpaired | inline per-kind `baseline`, all three at 0 = HARD |
| source-vault [tombstone] | `buildSystem/check-source-vault.js` | ~:582 | the retired per-class `window.<Name>_coffeSource` global + the `Object.keys(window)` suffix scan in `src/boot/**` (arc 4) must not return; sources arrive only through `SourceVault.store` | — (forbidden outright, comments included — the conversion completed inside its own phase) |
| whole-file-markers [tombstone] | `buildSystem/check-whole-file-markers.js` | ~:591 | the per-FILE exclusion comments (`# this file is excluded from the fizzygum homepage build`, the Macros and VideoPlayer twins) must stay at zero (arc 4); parts + profiles say the same thing visibly and at slice granularity | inline per-kind `baseline`, all three at 0 = HARD. ⛔ Do not invent a replacement marker syntax |
| part-edges | `buildSystem/check-part-edges.js` | ~:603 | CORE must never name a PART's class unguarded — the one structural defence for an artifact built without that part (the suite runs the harness page, which carries every part; the smoke never opens the menu item that would throw). A REFERENCE is fixable in place (`if DemoMenus?` / `world.pinouts?.…` / an `ensureLoaded` await); `extends` is not guardable at all and means the PARTITION is wrong. A member a part INSTALLS onto a class outside itself (`*TestSupport.installOnto <CoreClass>` in `src/boot/globalFunctions.coffee`, harvested by `buildSystem/lib/install-edges.js`, which `check-menu-actions.js` shares) is that part's symbol too, when no shippable file outside the part defines the name (the shared implementor harvest, `buildSystem/lib/name-definitions.js`): an unguarded `@m` / `x.m` (a), a string literal that is exactly `m` — a by-name dispatch such as a menu row (b) — or a `super` in an `m` override with nothing outside the part above it (c) fails the build, because on an artifact without the part nothing implements it. The name-resolution gates cannot see this by construction (they count the harness in their universe, correctly: their question is "does anything implement it?", this gate's is "is it there on every build that ships the caller?"). ⚠ Blind spots: a dispatch of an installed member that a class outside the part ALSO defines (only its `super` is judged), a computed name, a `#{…}` interpolation, `src/boot` (unscanned by both rules), a class-side `super`, and a member put on a class by anything but an `installOnto` edge. That half SKIPS when the tests repo is absent. It also fails a parts.json `requires` entry that no CODE reference of the requiring part backs (a class of the required part named outside comments and strings): an unused entry still orders a fetch, and the reason written beside it no longer holds. `check-part-edges-selftest.js` drives all three clauses, the member guard and the unused-`requires` rule both ways | `buildSystem/lib/part-edge-scan.js` is the shared scanner; a guard IS the exemption, and an eager part's `declaredRequires` discounts the parts it legitimately depends on. For an installed member the guard is the part's (`if WidgetTestSupport?`) or an existence test on the member itself (`@m?()`, `if x.m?`, `return unless x.m?`), which opens the same scope `if X?` does |
| **constructor-build** | **`buildSystem/check-constructors-build.js`** | **~:623** | a `constructor:` body must not build its own children inline — `@add`/`@addMany`/`@addNoSettle`/`@_addNoSettle`/`@__add`/… on `this` belong in `_buildAndConnectChildrenNoSettle`, reached via the settling wrapper | per-constructor `# constructor-build-exempt: <reason>` (no central allowlist; currently ZERO — the 4 menu/slider-family `@__add` ctors were converted 2026-07-12, `docs/archive/menu-slider-ctor-conversion-plan.md`) |
| **call-separation** | **`buildSystem/check-call-separation.js`** | **~:645** | **rules [S]/[U]: [S] a private method must not `@`-self-call a public COMMAND (settling/effectful callee; queries + `changed`/`fullChanged` stay free); [U] a public method referenced ONLY by `@`-self calls is not external API and must be `_`-tier. Measurement engine: `census-public-private-calls.js`. [U] self-skips without the sibling tests repo** | inline count baselines (`BASELINE_S_*`/`BASELINE_U_*`, the stinks idiom); per-caller `# public-call-sanctioned: <why>` for [S]; `public-api-allowlist.txt` for [U] (deliberate end-user inspector/scripting API) |
| relayout-bounds-first | `buildSystem/check-relayout-bounds-first.js` | ~:664 | a `_reLayout` override must APPLY its own bounds before its first own-geometry read (else children lay out against the previous pass's frame — the "one-cadence-lag" flake). Also follows the own-contents TEMPLATE: a `_reLayout` delegating to `Widget._reLayoutWithOwnContents` is apply-first by construction (counted separately, never as "positions no children"), and a `_layOutOwnContents` reading own geometry without that delegation is a violation. ⚠ Blind to a file defining the hook and NO `_reLayout` — it inherits one this line-scanner cannot follow | `# relayout-bounds-first-exempt: <reason>` above the method header |
| widget-conformance `--gate` | `buildSystem/census-widget-conformance.js --gate` | ~:686 | the two OBJECTIVE facets of the widget-practices survey: **instance fields written but never DECLARED at class level** (until declared, a lazily-initialised field is invisible to duplication, serialization and the inspector) and **`_reLayout` prologue copies** (classes not taking `Widget._reLayoutWithOwnContents`). It reads a class's CODE only — comments and block strings out: a block string is data even when it holds CoffeeScript (`PaintToolbarWdgt`'s tool sources run on the paint surface they are injected onto, so their `@queue` is `CanvasGlassTopWdgt`'s field, declared there). Its default, gate-less run is the advisory census (§3c) | inline `BASELINE_UNDECLARED_CLASSES`/`_FIELDS` = **0/0** and `BASELINE_PROLOGUE_COPIES` = **8**. ⚠ **A BASELINE HERE IS A FLOOR, NOT A ZERO** — undeclared fields reached a true 0/0, so that one IS an inventory; prologue copies stay at 8 (two deliberate non-conversions plus six genuinely different shapes), each named in the script |
| back-buffer-memos | `buildSystem/check-back-buffer-memos.js` | ~:695 | a widget keeps no memo of its back buffer: every `@field` a back-buffer builder (`_createRefreshOrGetBackBuffer`, plus the same-file methods it reaches through `@name`, transitively) ASSIGNS must be a serialization transient of the class chain (merged up `extends` the way `classStaticListMergedUpTheChain` merges at runtime — each class's OWN list) or a field declared saved content. The back buffer is itself a transient, so a memo of it that rides a save outlives the raster it describes and the restored widget skips the paint it needs. Reads ALL of `src/`, every part shipped or not — the one static check over the flag-gated `video-player` part, where both measured cases lived (`SimpleImageWdgt` restored BLACK, `VideoPlayerCanvasWdgt` restored its letterbox in its paper colour). A KEYED builder (it answers from `world.cacheForImmutableBackBuffers`: StringWdgt, TextWdgt, PaletteWdgt — no per-instance raster to describe) is read for its own body only. ⚠ Blind to a memo written outside the builder's reach (an onload or step handler — `SimpleImageWdgt.imageLoaded`'s shape), to cross-file and dynamic calls, and to writes through an alias; refuses LOUDLY a builder whose header the shared matcher cannot see; exit 2 when it found no builder at all | `# saved-content: <what makes it content>` on or directly above the field declaration (ONE site: `CanvasWdgt.drawnRaster`) |
| page-loaded-elements | `buildSystem/check-page-loaded-elements.js` | ~:715 | an element the page loads is a PAGE FACT derived from its holder's own path: every `@field` a class ASSIGNS an element (`new Image`/`new Audio`, `document.createElement` of an img, video or audio — any call spelling) must be (a) a serialization transient of the class chain (the same `extends` merge as back-buffer-memos) and (b) re-made by the chain, which defines BOTH `_afterDeserialization` and `_reactToBeingCopied` — because neither walker carries an element (the Serializer has no encoder and refuses one, the Duplicator leaves the field `undefined`; `serialization-duplication-reference.md` §5). Reads ALL of `src/`, every part — both holders (`SimpleImageWdgt.img`, `VideoPlayerCanvasWdgt.video`) live in the flag-gated `video-player` part no suite, rig or smoke runs. An element constructed into no field is refused as unattributed unless marked. ⚠ Blind to an element reached without construction syntax on the line (handed in, returned by a helper in another file — the helper's own line is refused), to one stored INTO a field's contents (`@a.b = …`), and to a hook that exists but does not re-make the element ((b) asks that both hooks are DEFINED); refuses LOUDLY a hook header the shared matcher cannot see; exit 2 when it found no element construction at all | `# page-element-not-held: <reason>` on or directly above the constructing line (ONE site: the Deserializer's `$Canvas` decoder image) |
| relayout-repaints [INV-1 tombstone] | `buildSystem/check-relayout-repaints.js` | ~:710 | the RETIRED paired suppression verbs (`disableTrackChanges`/`maybeEnableTrackChanges` — the arc that removed them is [`../archive/repaint-as-one-unit-plan.md`](../archive/repaint-as-one-unit-plan.md)) must not reappear in src or harness src — [INV-1]'s covering-repaint obligation is now STRUCTURAL in `Widget._repaintAsOneUnit` (the `finally` restores the suppression depth and fires the covering `_fullChanged` — skipped only when provably vacuous: zero suppressed mark attempts inside the unit and fn completed; runtime twin = the paint-truthfulness audit, unchanged) | — (no exemption: a suppression window IS `@_repaintAsOneUnit`) |
| raw-pointer-reads | `buildSystem/check-raw-pointer-reads.js` | ~:731 | a pointer-event HANDLER body (`press*`/`hover*`/`activated`/`scrolledBy`/`nonFloatDragging`/…, closures included — plus the two drag-scroll methods that sample or consume the pointer per frame / per event though no dispatcher calls them by a handler name, `ViewportWdgt.takeStrokeScrollFrom` (it installs the drag-scroll `@step`) and `latchStrokeScroll`) must not consume the raw SCREEN-plane `world.hand.position()` unmapped — consume the plane-mapped `pos` PARAMETER the dispatcher hands every handler (affine 4A), or map the sample at the read site (`screenPointToMyPlane` on the same line, the drag-scroll idiom). The dispatched handler names, and what position each is handed, are ONE table both body gates read (`buildSystem/lib/pointer-handlers.js`), held against `ActivePointerWdgt` both ways on every build: a table name the dispatcher never names fails, and so does a method the dispatcher hands a pointer position to that the table lacks (unless it is a stated `POSITION_QUERIES` entry); a NEW handler dispatched with NO position is the stated blind spot. Off-island the mapped point IS the raw point, so the bug class is invisible until a widget is TILTED (the 2026-07-17 spreadsheet tilted-selection bug). Helpers a handler calls are NOT scanned (heuristic tripwire — the deliberate raw-screen rotate-angle helper lives in one); a handler handed no `pos` (`pressCancelled`) maps its own read; `ActivePointerWdgt` itself skipped | `# raw-screen-pointer-sanctioned: <reason>` DIRECTLY above the handler header — any code line between breaks the comment block, so a marker inside the previous method's body exempts nothing (currently ZERO sites) |
| plane-discipline | `buildSystem/check-plane-discipline.js` | ~:740 | the three statically-checkable rules of the paint-time scroll model ([`viewports-and-planes.md`](viewports-and-planes.md)): **A)** `scrollOffsetX/Y` assigned ONLY inside `_writeScrollOffset` (a bare write skips the `geometryVersion` bump — the measured hit-invisible-scrolled-row class); **B)** a count RATCHET over lines mixing two DISTINCT receivers' POSITIONAL geometry (plane-relative, unlike the plane-invariant extents) with no mapping call on the line — the position queries are READ from Widget.coffee (its no-parameter methods answering a one-line `@bounds` delegation, or named `…Bounds`) minus a stated `NOT_POSITIONAL` table (the sizes, the screen-family query, a predicate; an entry the derivation no longer catches fails as stale, a derivation finding nothing exits 2) — the silent dormant-at-offset-0/identity class every hard bug of the scroll arc belonged to; same-plane-by-construction sites are legitimate, so new lines are CLASSIFIED (map, or raise the baseline with a reason) and drops ratchet down; **C1)** on a `scrollTranslationOfChild` provider (transitive via `extends`), a handler reached by `escalateEvent` (the names are derived from every `escalateEvent "<name>"` call in src — `activated`, `doubleActivated` today) must not read its `pos` at all but re-derive the point from the hand — the escalated `pos` is a descendant's plane (the measured stationary-click-slams-to-clamp defect); the press facts are exempt by construction (the hand maps the pointer for each receiver of the climb and its endings); **C2)** `nonFloatDragging`'s raw-SCREEN `pos` (its second parameter), on any class, must be mapped on the same line it is read. ⚠ Blind by design to CROSS-LINE flows: a positional value stored in one method and consumed in another plane elsewhere, or forwarded through an opts key — those are the deep-audit's job (the 2026-08-20 review census), not a line scanner's | A/C: hard zero; B: inline `CROSS_PLANE_MIX_BASELINE` (every line a genuine two-widget mix, each same-plane by construction; a widget's own `@bounds` chain folds into `@`); C: `# escalated-pos-sanctioned: <reason>` above the handler header (currently ZERO sites) |
| test-.js syntax | `Fizzygum-tests/scripts/check-tests-syntax.js` | ~:770 | JS syntax of the macro SystemTest `.js` files the build is about to serve | — (self-skips unless `$PROFILE_SHIPS_TESTS`, or when the sibling repo is absent) |
| macro source discipline | `Fizzygum-tests/scripts/check-macro-source-discipline.js` | ~:794 | three rules over MACRO SOURCES only (every test's — its command file's `mainMacroSource` and `extraSubroutineSources` — and every verb's, a `Macro.fromString` literal of src, as the page compiles them — `lib/macro-sources.js` — `#` comments stripped): **A)** `@evaluateString` is ALWAYS wrong — in macro source `@` is the `MacroToolkit`, whose `evaluateString` is a DIFFERENT method (it binds `@` to the toolkit); it compiles fine and misbehaves at run time. **B)** `world.evaluateString` only where the test DECLARES the eval as its subject, via the `evaluateString` tag in its metadata (so never in a verb, which has no tags) — because a macro body IS CoffeeScript, so the string form throws away the widget binding, the syntax gate and any rename sweep's chance of finding it, and fails at run time where the statement fails at the build (`Widget.evaluateString` is the evaluation alone: it tells no one, and a person's run gesture tells the receiver). ⭐ A DECLARATION, not a count: there is no baseline number to rot, a legitimate new eval-subject test just tags itself, and the tag is reviewable in the diff (the `storage-invariant-gate.js` no-baseline pattern). **C)** "Macro" only as a TRAILING suffix — `Macro._replaceMacroInvocationWithYieldingInvocations` rewrites every `…Macro` not followed by `(` into a `yield from`, so a mid-name one (`recordMacroAssertion`) is silently MANGLED; that is why the assertion sink is reachable only from a toolkit `@assert…` method. ⛔ A FOURTH rule was measured and DECLINED — "`@x` in macro source must be a MacroToolkit member", which `src/macros/CLAUDE.md` calls the `@`-vs-`world.` "#1 trap": the census found ZERO real violations and exactly one hit that was the CHECKER's own false positive (`box.hoverMoved = (pos) -> @recordedHoverMovedPos = pos` is correct — `->` REBINDS `@`), and checking it properly needs `@`-rebinding analysis through `->` vs `=>` that a line scanner cannot do. ⚠ Scans macro sources ONLY, and that precision is load-bearing — metadata prose and macro comments legitimately discuss `world.evaluateString`, so a whole-file grep would fire on tests doing exactly the right thing | — (self-skips like the test gate). Its own acceptance corpus is `check-macro-source-discipline-selftest.js` (the self-tests step, every build), whose ship gate is the NEGATIVE cases plus a CONTROL differing from a caught case only by the tag |
| ref-image integrity | `Fizzygum-tests/scripts/check-refs.js` | ~:817 | >1 `dataHash` per `(test,image,dpr,OS)` or an orphaned `.js`/`.png` reference | — (self-skips like the test gate). Its PIXEL half, `--pixels`, is deliberately NOT on the build: it runs as the gauntlet's `refs` leg |
| visualisation pages | `Fizzygum-tests/scripts/check-visualisations.js` | ~:836 | **(1)** every local `<img src>` in every committed `visualisation.html` resolves to a file that exists, and **(2)** a test that HAS reference images HAS a page at all — (2) exists because an ABSENT page contains no broken image, so (1) structurally cannot see it (the 2026-08-21 sweep found 3 tests with no page whatsoever). ⚠ (2) keys on HAVING REFERENCES, not on being a test: a test dir mid-authoring legitimately has neither yet and its page is written by the first capture, so requiring a page of every test would fail the build on a half-authored one — a false positive, not a find. Assertion-only tests are exempt by that rule and have pages anyway. ⭐ The break it catches is SILENT and therefore unbounded in time: a page EMBEDS its reference filenames, a reference filename carries the image's `dataHash`, and **nothing in CI ever opens these pages** — so a page orphaned by a rename or a recapture is indistinguishable from a working one until a human clicks it. Measured twice: 10 of 305 pages were already broken on 2026-08-21, and the 2026-08-22 reference filename-grammar migration would have broken 279 in a single commit. The capture path regenerates a page at its write site (`run-macro-test-headless.js`), which covers captures; this gate covers **everything else** — bulk renames, hand edits, a deleted reference — by checking the property itself instead of trusting every writer to remember the rule. No image decode, no browser. ⚠ It checks RESOLUTION, not freshness: a page whose `<img>`s all resolve can still show the wrong step order or stale prose | — (self-skips like the test gate). Fix with `node scripts/make-visualisation.js <name>` (no arg = every test). Its `--strict` mode also requires each page to EQUAL what the generator produces now — freshness, not just resolution — and is deliberately NOT on the build: that residue is cosmetic, while a page-TEMPLATE edit would otherwise break every build until all pages are regenerated (`npm run check-visualisations:strict`). Acceptance corpus: `check-visualisations-selftest.js` (the self-tests step, every build) |

**Per-gate notes:**

- **syntax (`check-coffee-syntax.js`).** The browser NEVER compiles a whole class file — `src/meta/Class.coffee` splits
  each class into fragments (constructor + every field), rewrites every `super` form, and
  compiles each fragment with `{bare:true}`. A whole-file `CoffeeScript.compile(src,{bare:true})` therefore false-fails
  on ~300 of ~500 files. To avoid drift this gate **loads and runs the real `Class.coffee`** to compile
  each source the faithful way. **DO NOT "simplify" it to a whole-file compile.** Its SECOND check taps the real
  `Class._removeHelperFunctions`, which cuts the compiled `var` head out of every member fragment: the compiler declares
  there the helpers a construct needs (`%%` → `modulo`, a range assignment → `splice`) and the temporaries it hoists out
  of a parameter default (`(c = @a ? @b()) ->` → `ref`), so any name in that head other than the three helper globals
  boot provides (`hasProp`/`indexOf`/`slice`) is gone — a ReferenceError when the body calls it, a silent page-wide
  global when the body assigns it first (`CanvasWdgt.clear` leaked `window.ref` on every call until this check named it).
  The compiler's output is the authority on which helpers exist, so no helper is listed to ban; the only list is the
  PROVIDED one. `--files <paths…>` checks
  given files instead of the shippable set (its plants live under `Fizzygum-tests/.scratch/`). Beyond these two, for
  load-order/runtime faults boot the build (`./build_and_smoke.sh`).
- **invalidation-receivers (`check-invalidation-receivers.js`).** Enforces widget-citizenship contract point 2 after the
  2026-07-22 audit fixed the 17 feature-code deviations it found (37 cross-receiver sites total: 15 category-C fixed, 4
  redundant own-sub-part deleted, 9 singleton-allowed, 9 sanctioned). The redundancy argument the fixes rest on: broken
  rects are fleshed out at the END-of-cycle flush — source from `*clippedBoundsWhenLastPainted` (recorded at paint time),
  destination from current bounds read at flush — so ONE `_fullChanged()` anywhere in the cycle (e.g. the one inside
  `_addNoSettle`) covers every same-cycle geometry mutation, and a trailing `w._fullChanged()` after `add w` +
  `setExtent` is dead weight. The conforming shape for a genuine repaint need is receiver-side: the method A invokes on B
  ends with `@_changed()` (e.g. `StretchableCanvasWdgt.getContextForPainting` marks its own canvas; the paint-tool
  sources no longer reach back). Scanner is line-based, over each line's bare code (§6c); `@_changed()`
  self-calls are dotless and never match, so only dotted receivers are judged.
- **dead-method (`check-dead-methods.js`).** Inventories every method header in the compiled sources, src and the
  harness (§3c; a class's, and a class-side one under its BARE name) and reads every place a method could be
  REACHED from, as code: the compiled sources through `lib/coffee-mask.js`, each reference credited to the method it
  sits in, and the tests repo's macro sources and `scripts/` rigs through `lib/tests-repo-code.js`.
  What reaches a method is the one rule in `lib/method-references.js` (§3c): a property access, a whole-name string, a
  name template (`"_#{@action}Connector"`) or a computed access on a named class (`FormulaHelpers[name]`); a bare word or
  a comment reaches nothing. A method nothing reaches is DEAD. Genuine exceptions (a family member kept for symmetry, a
  name assembled with `+`) go in `dead-method-allowlist.txt`. `--update-allowlist` re-seeds the baseline. Needs the
  sibling tests repo for an accurate reference set; SKIPS (not false-fails) if it is absent.
- **unresolved-sends (`check-unresolved-sends.js`).** The exact INVERSE of the dead-method gate (that one: defined but
  never sent; this one: sent but never defined). Pharo's `ReSentNotImplementedRule`, carried over 2026-07-15. It harvests
  every call-shaped `[@.]name(` across src, the harness and every MACRO SOURCE (`lib/macro-sources.js`: the CoffeeScript
  alone, as the page compiles it — a test's, never the JS around it, and a verb's, which a reading of src's own code sees
  only as a string) and fails on any name that NOTHING
  in the universe implements. A macro calls core methods as directly as the harness does, so a rename that misses a
  macro's `.name(` fails the build rather than the suite; a macro's own definitions (a local helper, an object of
  handlers) resolve its own calls only, and never widen the shared universe.
  Like dead-method it **SKIPS** (exit 0 + a loud note) when the sibling tests repo is absent — the harness is part of the
  definition universe (src calls into it behind `if Automator?`). It landed green on day one (7046 calls, 0 unresolved,
  ~0.1 s). Counting the harness as defined is right for ITS question and is exactly why it cannot see a shipping caller
  of a harness-only member — `check-part-edges.js` asks that one, reading the same implementor harvest
  (`buildSystem/lib/name-definitions.js`), so the two gates cannot disagree about what is defined.
  It is deliberately built for **ZERO false positives at the cost of reach** — a false FAIL breaks the build on correct
  code, while a miss merely leaves a fault for the boot smoke / SystemTests. That trade is an ASYMMETRY in which
  reading of a line (§6c) each side takes, and both halves err toward "fewer flags": **defs are CALLABLE** — a method
  header (`name:` / `@name:` whose value is an arrow after a paren-counted parameter list, a signature wrapped after
  its `(`, or a `\` continuation), a prototype extension, an expando function, or a top-level function; a data key or
  an indented local defines nothing — read off each line's CODE, literals KEPT (a heredoc holds code that defines
  names, MacroToolkit's verbs), so a def found inside a string only ever adds an implementor; while **calls are
  UNDER-approximated**, read off each line's BARE code (literal contents blanked, `#{…}` interpolation kept as the
  code it is).
  Accepted reach limits (each a miss, never a false-fail): paren-calls only (paren-less `@foo arg` is too noisy to gate
  on — §8.7 of the carryover plan); string-dispatched sends are invisible (menu/button actions — that hole needs the
  action-string checker); capital-initial names are skipped (the boot dependency finder's jurisdiction); the def harvest is
  line-anchored, so an inline object's key (`{ m: -> }`) defines nothing — written multi-line it does; no receiver typing, so a name defined ANYWHERE resolves a call EVERYWHERE.
  **The one receiver it reads** is a literal identifier written right against the dot, and only to match a KEYED
  `BUILTINS` entry. A platform name is BARE by default and excuses every call of it; it is KEYED (`Math.round`) when
  Fizzygum also defines the name and the platform has it only as a static of a global, so `Math.round(` is excused
  and `@bounds.round(` is judged against Fizzygum's own `round` implementors — deleting every one of them fails the
  build. Keying is for UNMASKING: while Fizzygum defines the name, every call of it resolves through that definition,
  so a receiver the gate cannot read never false-fails; the one bounded exception is the moment every definition of a
  keyed name is gone, when a platform call of it with an unreadable receiver (`window.Math.round(`, none today) fails
  beside the real ones. The form is held to the sends: a bare name Fizzygum defines, which every call sends to a
  `PLATFORM_GLOBALS` receiver, fails as `BUILTINS_NOT_KEYED`; a keyed name Fizzygum does not define, with no unresolved
  call of it left, has nothing to unmask and fails as `BUILTINS_KEYED_NOTHING_TO_UNMASK`; a keyed receiver outside
  `PLATFORM_GLOBALS` fails as `BUILTINS_KEYED_OFF_PLATFORM`; an entry no call sends — bare, keyed with no `Recv.name(`,
  or a `PLATFORM_GLOBALS` name no `BUILTINS` call is sent to — as `STALE_ALLOWLIST_ENTRY`. ⚠ Blind spots, stated:
  `BUILTINS_NOT_KEYED` cannot see a shared name that a non-global receiver also sends (`abs` beside `@origin.abs(`) —
  whether the platform has the name as an instance method is the keyed entry's own claim, which the gate cannot check;
  a receiver is matched by NAME, so a local that borrows a global's name (`console = …`) reads as the global; a BARE
  name Fizzygum also implements (`save`, `get`, `clear`, `fill`, `stroke`, `scale`, `measureText`, `keys`, `has`,
  `toString`, …) still excuses a Fizzygum-receiver call after every Fizzygum implementor of it is deleted — `toString`
  cannot throw at all (it answers `"[object Object]"`, which a canvas style property silently ignores); and a property
  that HOLDS a closure is no definition, so a call of one (`drawFunction`) resolves only through its allowlist entry, which
  says so.
  **Two exemption lists, on purpose:** the in-file `BUILTINS` set is a fact about the PLATFORM (JS/DOM/canvas), while
  `unresolved-sends-allowlist.txt` is a fact about Fizzygum's VENDOR dependencies — one named API we reach at a few
  sites, where the recorded reason is worth more than the suppression (JSZip, WebCrypto, the LCL event router, the
  SWCanvas bitmapText API, a Firefox-legacy guarded `toSource`). Seeded at exactly 9 entries, each triaged against its
  real call site.
- **stinks (`check-stinks.js`).** A "stink" is a smell driven to zero, ratcheted at a `baseline` (max tolerated count)
  that lives **inline** next to the rule (a smell is a count, not a named set — no separate allowlist). Build FAILS when
  a stink EXCEEDS its baseline; when it drops below, tighten the baseline to lock the gain (the gate prints a reminder;
  `fg critique` resurfaces it). Baseline 0 = a HARD rule. Reads the compiled sources, src and the harness alike (§3c's
  `lib/source-files.js`: each repo's conventions claim its harness — one absence value, no retired markers), per-LINE,
  over each line's bare code (§6c: a string that mentions `null` is not
  a `null`) — except a stink declaring `scope: 'comments'`, which matches the line's COMMENT instead (the
  comment-hygiene ratchets). A stink may also declare `exclude` (src-relative path prefixes it does not scan —
  anything unlisted, a new file included, IS scanned), `readsLiterals: true` (it matches the line's code with its
  literals kept, for a smell written inside a string: a CSS `'#rrggbb'`, a tool source's colours) and
  `sanctioned` (`{file, member, count, why}` entries naming hits INSIDE scanned files that are not the smell; a hit's
  member is the nearest class-body key above it at the 2-space indent (`Object::x =` is no key) — a data
  member's key as well as a method's, since a sanctioned literal can sit in a field — or, reached first, the code at
  the left margin: a definition there (`lib/name-definitions.js`: a top-level function, an expando, a prototype
  extension) names the member, any other code is `(top)`; a literal's body never counts; an entry matches
  only at its exact count, and fails the build otherwise, so it is a declaration that cannot rot into a hiding place).
  **Current stinks: seven seeded 2026-07-15**, **three comment-hygiene
  ratchets added at the 2026-07-17 comments cleanup**, `comment-past-receipt` (2026-08-09) and `raw-chrome-color`
  (2026-10-17). (There is no `positional-hole` stink: the call-arguments gate in §3 judges every call in both repos by
  the callers test, and a line regex for two adjacent `undefined`s was a second, disagreeing definition of a hole —
  it fired on a trailing pair and on an array literal, and saw no single-`undefined` or multi-line hole.) (`helper-compiling-operator`, the line ban on `%%`, is subsumed by
  the syntax gate's lost-helper check, which reads every helper from the compiler's own output.) One of the original
  seven, `undefined-literal`, has since been REPLACED rather than removed — see `nil-literal` below. Every baseline was MEASURED by the engine on its seeding day and
  every stink spot-checked against its real hits; they are ratchets recording that day's count, not verdicts — driving
  any of them down is a future arc:

  | stink | baseline | why |
  |---|---|---|
  | `debugger-statement` | 0 | HARD: a `debugger` statement in any spelling (standing, `… then debugger`, after an arrow; blind only to one inside embedded JavaScript, which the mask blanks as a literal) is debug cruft that hard-stops execution whenever devtools are open and reports nothing otherwise; a branch that detects a broken invariant reports it under `INVARIANT_VIOLATED`, a gate token (Pharo: `ReCodeCruftLeftInMethodsRule`) |
  | `nil-literal` | 0 | HARD: the `nil = undefined` global is RETIRED (`archive/nil-global-retirement.md`), so a `nil` is a ReferenceError waiting to happen. Replaced `undefined-literal` (baseline 83), which enforced the now-inverted convention |
  | `null-literal` | 6 | `undefined` is the ONE absence value; the JS-interop sites (`JSON.stringify`'s arg, `onload = null`) are the tolerated tail |
  | `clock-read` | 13 | a read of a clock — the wall clock (`Date.now()`, or a `new Date` given no argument, followed by an operator, a closing bracket, punctuation or the end of the line; `new Date x` / `new Date -x` are values) or the monotonic one (`performance.now()`) — breaks event-stream determinism (DETERMINISM.md — recognition keys off EVENT timestamps); sanctioned by name: the world's one per-cycle clock (`WorldWdgt._updateTimeReferences`), a clock widget built outside a cycle, the harness's own clocks, the compile scheduler's frame budget (`WorldWdgt.doOneCycle`, `SourceCompileScheduler.drainAtEndOfCycle` / `_drain`) — which paces how much compiling a frame does: on the pages the suite drives nothing is queued behind a running world, so no reference pixel depends on it, while on `index.html` it decides in which frame a lazy part's door opens (why laziness is held by rigs, not SystemTests) — and the ingest's debug timing. Its existential spellings count too (`performance?.now()`, `Date.now?()`). Cannot see: a read inside a string interpolation (the mask blanks `#{ }`); a clock passed uncalled (`performance.now.bind performance`, `opts.now ? Date.now`), read through a string key (`performance['now']()`) or by `do`; `Date()` without `new`; and clocks read through other APIs (`performance.timeOrigin`, `event.timeStamp`, a `requestAnimationFrame` callback's timestamp, `document.timeline`) |
  | `timer` | 4 | `setTimeout`/`setInterval` diverge at dpr2 under parallel load (bug-class B); the cycle/step machinery is the sanctioned clock |
  | `math-random` | 5 | breaks byte-exact screenshot determinism in render/layout/input code |
  | `instanceof-type-test` | 74 | locks the type-test-elimination campaign's tail against regrowth — prefer polymorphism (Pharo: `ReBadMessageRule`) |
  | `raw-chrome-color` | 0 | a colour literal (`Color.create`, `new Color`, `Color.<CONSTANT>`, a CSS `'#hex'` / `'rgb(…)'` / `'rgba(…)'` string) in a CHROME file is a look decided outside `src/Theme.coffee` ([`visual-design-system.md`](visual-design-system.md)), so a restyle cannot reach it — read the surface's `WorldWdgt.theme` role (add one when the surface has none). Uses `exclude` (Theme, the Color class and value plumbing, CONTENT directories, ICON art — a NEW file is counted by default), `readsLiterals`, and `sanctioned`: the literals inside counted files that are DATA, not a look decision (wallpaper patterns, palette data, the paint tools' source strings, a new shape's content default, the debug overlay, DOM input styling, a pixel read), each declared by file and enclosing member with its count and reason — an entry whose member holds a different number of hits fails the build (`SANCTION COUNT`, or `STALE SANCTION` at 0), so the list can neither outlive nor widen what it names. At 0 it is a HARD rule: a chrome colour is a `Theme` role, read where it is used (a class-level state colour is derived at each state change, since a class-level declaration may not reference another class); `fg stinks --list raw-chrome-color` lists the sanctioned sites with their reasons |
  | `comment-meta-edit` | 0 | HARD: a comment arguing with itself ("the below is actually correct", "to be clear,") is process residue — state the surviving constraint once |
  | `comment-narration` | 87 | history narration in comments ("used to", "previously", "no longer", "in the old model") — history's home is `docs/archive/` + a pointer; a comment states what IS | <!-- narration-ok: this row DEFINES the narration rule, so it must quote its own trigger words -->
  | `commented-out-debug` | 0 | HARD: commented-out `alert(`/`debugger`/`console.log` is dead debug cruft — delete it; git remembers |
  | `comment-past-receipt` | 0 | HARD: a `was <old code>` conversion receipt narrates history — state the surviving present-tense contract (what the predicate answers, or why this spelling) and let `docs/archive/` keep the before-picture |

  There is no multi-line matcher — an empty-catch stink would need one (§8.9).
- **thin-wrap (`check-thin-wraps.js`).** For a private `_<name>NoSettle`, its settling twin in the SAME class — the
  public `<name>` (e.g. `setLabel`) OR a private `_<name>` (e.g. the construction wrapper `_buildAndConnectChildren`,
  which is exactly what the constructor-build gate sends every widget author to) — must be, after comments/blanks:
  `[zero+ return if/unless guards]` then `@_settleLayoutsAfter => @_<name>NoSettle <args>` — it does no work of its own.
  Complements `check-layering` (which enforces the CORE reaches no public setter). A twinless
  `_<name>NoSettle` (e.g. `_addInPseudoRandomPositionNoSettle`) is SKIPPED — no twin to constrain.
- **constructor-build (`check-constructors-build.js`).** Locks in the "all constructors settle" end-state (Topic 4
  part 2): a `constructor:` body must NOT build its own children inline. An `inctor` state machine (set on `constructor:`,
  cleared by the next 2-space class header — so it handles multi-line ctor headers, mirroring the FNR audit awk) scans
  each constructor and FAILS on `@_{0,2}add(Many)?(NoSettle)?` called on `this` (the `__add` structural leaf counts
  too — 2026-07-12; the menu/slider-family ctors that built through it were converted the same day,
  `docs/archive/menu-slider-ctor-conversion-plan.md`). The child-building belongs in
  `_buildAndConnectChildrenNoSettle`, reached from the ctor via the settling wrapper `@_buildAndConnectChildren()` (or
  `@_buildViewportChrome()` for the ViewportWdgt base) — so the settle-tier FLUSHES a top-level `new X()` and AUTO-DEFERS
  one built in-flush (inside a callback). Building INTO a sub-child (`@contents._addNoSettle …`) is NOT matched — that
  `.`-qualified form is not `@`-prefixed. Genuine exceptions carry `# constructor-build-exempt: <reason>` (in the body or
  the comment block directly above the header); no central allowlist.

**Two RUNTIME naming-audit gates (suite-run, NOT build-time).** The naming convention also carries two off-by-default
runtime audits that run over the WHOLE SystemTest suite (not `build_it_please.sh`) — each an injected prelude that wraps
prototypes before the page's own scripts run, with a standalone `run-*-gate.sh`, siblings of the end-of-cycle
capstone gate (whose pass also carries the paint-read-only audit) and wired into `fg gauntlet`. ⚠ Unlike that sibling,
neither carries a `WorldWdgt` audit flag:
all their observation lives in the prelude's own wrappers, so there is nothing for a flag to switch:
- **tier-naming** (`Fizzygum-tests/scripts/tier-naming-audit/`) — the dynamic twin of
  rules [I]/[K]: HARD-fails a `__commit*` leaf or an arrange `_apply*Base` bypass twin that fires the seam/react at
  runtime; reports the polymorphic `_apply*`→seam coverage as INFORMATIONAL (a runtime observation can't soundly
  distinguish a mislabel from an unexercised seam path — and it is vacuously 0, there being no `_announce*` seam).
- **notification-settle** (`Fizzygum-tests/scripts/notification-settle-audit/`) — the dynamic twin of rule [J]: HARD-fails a `_reactTo*`/`_before*` callback that
  OPENS A FLUSH — an ATTACHED-receiver `_settleLayoutsAfter` (it would throw) or any `recalculateLayouts`. It PERMITS an
  ORPHAN-receiver `_settleLayoutsAfter` reached in a callback: that is a constructor settling its own orphan (the window
  chrome buttons `FrameWdgt._reactToChildDropped` rebuilds), which provably takes the in-flush+orphan auto-defer branch
  (`return coreThunk() if @isOrphan()`) — it records the change, never flushes/recurses. (The "all constructors settle"
  campaign added this orphan exemption — `docs/archive/all-constructors-settle-plan.md`; it makes the gate PRECISE, since the old
  premise "any nested settle in a callback would re-enter/throw" is false for an orphan. It still catches the INDIRECT
  attached leak the static [J] cannot follow.)

⭐ **A gate must be able to tell BLINDNESS from CLEANLINESS, and most of these cannot yet.** Every gate here passes on
"zero findings", which measuring nothing satisfies perfectly — so a prelude that fails to install, a wrapper that stops
matching after a rename, or an audit flag lost on a reconstructed world all read as GREEN. Measured 2026-08-21: with
`auditUndeclaredEndOfCycle` lost on reconstructed worlds, 307 real careless pushes produced a green capstone run. Two
gates now carry a POSITIVE-COVERAGE assertion that closes this, in two shapes worth copying:
- **The flag is armed on THIS world** (`capstone`, once per audit it carries: `capstone-armed`, `paint-armed`) — one per-test line emitted only when the CURRENT
  world carries the audit flag, and the gate requires that count to equal the test count. Use this when the recording
  lives in product code behind a flag, since a reconstructed world must come up armed.
- **The audit RAN TO COMPLETION** (`storage`) — the prelude emits one marker per bucket at the END of the audit, and a
  distinct `…-SKIPPED:<what was missing>` line on the early return that would otherwise make the whole audit a silent
  no-op. Use this when the audit is a function that can decline to run. ⚠ Keep the marker OFF the finding channel:
  `LAYOUTAUDIT STORAGE-AUDITED` deliberately has no space after `STORAGE`, so the findings regex cannot match it.
  A shortfall exits **2 = INVALID**, not 1 — the absence of a measurement is not a finding about the product.
- **The WRAPPERS actually fired** (`tiernaming`, `settle`, `revisits`) — the shape-2 variant for a gate whose whole
  verdict comes from prototype wrappers rather than from product code. Their install-time counts prove only that the
  wrappers were ATTACHED; a rename that stopped them matching, or a prelude installed against the wrong prototypes,
  leaves every count full and every finding list empty. Each prelude now emits one `…-OBSERVED` line per test on the
  first real firing (a wrapped corner, a wrapped `_reactTo*`/`_before*` callback, a flush that visited any widget), and
  the gate requires it in every bucket.
All of these mirror `run-paint-audit.js`'s `checked == expectedTotal` and `vm-truth-gate.js`'s three INVALID paths.
⭐ **Every suite-wide audit gate carries one, and its bite-proof re-proves it on every gauntlet** (the rule above,
"every gate's every RULE is proven to BITE"): a test bucket holding nothing but the runner's synthesised `prelude installed`
header must read INVALID. That header is in every bucket of a shard whose prelude announced itself, which is precisely
why the install count was never coverage — with the wrappers suppressed, `prelude installed` reads `307/307` beside
`0/307` observed. The standing rule is the fuzz/vmtruth doctrine — **an unmeasured run is NEVER a pass**.
⚠ A coverage shortfall exits **2 = INVALID** everywhere, so a runner or wrapper that greps verdict lines must know the
word (the local `fg` wrapper's `leg_headline` does; `fg` is uncommitted workspace tooling, so that is not in git).
⭐ **And a gate must not restate a rule the product already owns.** The paint-read-only audit (a rider on the `capstone` leg) used to carry its own copy of <!-- narration-ok: the lesson IS the divergence: a gate that copied a product predicate drifted from it -->
`Widget._invalidateLayout`'s predicate; the two had silently diverged (the copy excluded freefloating-triggered
schedules, the product's never did) while its comment claimed to record "the EXACT set". The prelude now observes the
product's DECISION — whether the call appended to `world._paintTimeLayoutSchedules` — so there is one definition, in
the product, and the gate reads it. That is why its coverage assertion is not optional: the observation is now only as
alive as the flag.

**Two RUNTIME WIRING sweeps (on-demand / gauntlet legs, NOT build-time).** Where the audits above wrap prototypes over
the whole suite, these BOOT A PAGE and drive one mechanism to exhaustion — each the runtime half of a static gate whose
blind spot is structural:
- **menu sweep** (`Fizzygum-tests/scripts/menu-click-sweep-headless.js`, `npm run menu-sweep`, `fg menusweep`) —
  DISPATCHES EVERY MENU ACTION **and presses every prompt's OK** (by meaning: the prompt's `okButton`; a prompt without one
  fails, and so does a run that drives fewer prompts than its floor), failing on a throw from either; the other half of
  `check-menu-actions.js`, which cannot see a parameter that is read as the wrong THING. ⭐ The prompt step is the one
  that matters for an item ending in `"…"`: such an item does its real work in the prompt's callback, dispatched as
  `@target[@callback].call` with NO `?.`, so a rig that stops at the menu action covers it only as far as the prompt
  APPEARING — which is the point at which everything still looks fine. A prompt is not a `MenuWdgt` (both are framed
  citizens of `FrameWdgt` — menus/prompts carry no class of their own beneath it), so the submenu walk cannot reach one
  and it needs its own query. OK is pressed with the prompt's own
  default contents, so this asks "does the callback resolve and run", never "is this a good value".
  ⭐ It also proves the WORDING rules at runtime, since a label cannot be read for what its action does any more than a
  name can: a dispatched row (and the inspector's "Add…"/"Rename…" and the bin's "Empty bin…", the buttons no menu walk
  reaches) ends in "…" exactly when its act opened a prompt, a code prompt, the file chooser, a download, a confirmation
  or the resize handles (`ELLIPSIS_MISMATCH`; ASCII "..." is `ASCII_ELLIPSIS`). The file I/O and `window.confirm` are
  counters in the page, so the file rows are dispatched, not skipped, and nothing reaches the browser. Every label seen
  starts with a capital or a non-letter (`SENTENCE_CASE`). Each rule has a stated-decision allowlist
  (`ELLIPSIS_EXCEPTIONS`, `SENTENCE_CASE_EXCEPTIONS`) and a vacuity guard (`ELLIPSIS_CHECK_VACUOUS`,
  `SENTENCE_CASE_CHECK_VACUOUS`).
  ⚠ Its coverage model is REPRESENTATIVES, not exhaustion: 24 roots (two world roots, 16 representative widget classes,
  the inspector pair — whose prompts open from a BUTTON row no menu walk can reach — a `MenuWdgt`/`PromptWdgt` pair,
  each popped up and right-clicked on ITSELF, since no other root stands in a pop-up and so nothing else walks a
  transient frame's own entries, and the P5 docking pair (`FrameWdgt[docked band]` / `FrameWdgt[host with an empty
  slot]` — a Docs Maker's own docked toolbar, built and floated the product way, since a bare `FrameWdgt` representative
  is free-floating with an empty slot and offers neither side's dock rows)), so a class not among them is
  unreached. That is why
  it and the pin sweep are complementary rather than redundant — with the corner-radius defect planted back in, this rig
  catches 2 of the 16 affected classes and the pin sweep catches all 16.
  ⚠⚠ **A menu built behind a BRANCH is only swept in the branch the rig happens to be standing in**, and an action can
  flip the very flag that decides the shape (`Switch to user mode` dispatches `toggleDevMode`) — so `sweepRoot` restores
  `isDevMode`/`isIndexPage` per root; without that, one root's click left every later widget menu EMPTY and was reported
  as "no menu returned". The desktop menu is now ONE list gated per item (`@isDevMode`, `world.parts.isAvailable
  "demos"`, `Automator?`) rather than forked on which page booted the world, and the rig sweeps it as two roots
  (`world[product]`, `world[desktop]`) so both dev-mode shapes are walked. ⇒ **when a rig STATES a coverage, check the
  statement**: for as long as the desktop menu forked on `isIndexPage`, the world root walked 4 of its 13 rows while the
  rig's own comment called it "the door to the demo tree" — which is how a dispatch to `WorldWdgt.about`, a method
  deleted in 2017 whose menu row stayed, survived nine years in the first menu anyone opens.
- **pin sweep** (`Fizzygum-tests/scripts/pin-sweep-headless.js`, `npm run pin-sweep`, `fg pinsweep`; a gauntlet wave-A
  leg beside `menusweep`) — EVERY PIN A CLASS ADVERTISES
  MUST BE SERVICEABLE. A `PinSpec` names its setter/getter by STRING and the dataflow dispatches them as
  `consumer[name]?.call`, so an unresolved one is offered in the "target property" chooser, accepts a wire, and
  silently does nothing forever. It is a sweep rather than a scan for the same reason the menu one is: `pins()` is
  COMPOSED (`super().concat @_inputPins()`) and a subclass can NARROW it, so a textual analysis reports pins a class does
  not have. The rule resolves DOWNWARD with no `isAbstract` marker — a pin must resolve on every class that is a LEAF or
  is somewhere `new`-ed, so a base declaring pins for its subclasses is skipped by what the class graph already states.
  Two extra sections: appearance-contributed pins (invisible to a bare prototype, since `@appearance` is assigned in a
  constructor) checked on the classes that WEAR the appearance; and `announces`, checked by a per-pin FIXTURE that drives
  the setter and watches for a dataflow mark — a NECESSARY condition, never a proof, since no analysis can enumerate a
  pin's write paths. ⭐ Its first run found `corner radius` advertised by 16 classes with no `setCornerRadius`, which was
  also a hard THROW in the shape's own prompt.

They verify the *behaviour* the names promise (the ground truth the static scanner can't follow through dynamic
dispatch). Full description: `docs/architecture/layering-naming-convention.md`.

**The ALWAYS-ON runtime asserts (no flag, no prelude).** A handful of invariants are cheap enough to check
inline and are caught nowhere else, so they `console.error` a TOKEN that the three headless runners fail on
(`run-all-headless.js`, `run-macro-test-headless.js`, `run-sequence-headless.js`; the list is
`Fizzygum-tests/scripts/lib/gate-tokens.js`). The runners are FAIL-CLOSED beyond the list: any error-type
console line, and any uncaught page error, fails the test too, unless the line OPENS with a token excused by
design (`DATAFLOW_ERROR`, a formula that throws). And every `console.error` in `src/` and the harness opens with
an ALL-CAPS token, held by `lib/gate-tokens-selftest.js` (run on every build): an error with no name is an
assertion nothing could report by name, so the selftest refuses it when it is written, and the token it gets is
then either gated or excused with one of two stated kinds (`by-design`, or `not-distinctive` — a word too common
to match as a substring, which still fails as an error line). Each always-on assert exists because the
screenshot suite structurally cannot see the violation:
- `NON_FINITE_GEOMETRY` / `NON_INTEGER_GEOMETRY` — `Widget._assertBoundsWellFormed`, see
  [`integer-pixel-placement-and-sizing.md`](integer-pixel-placement-and-sizing.md).
- `POPUP_LARGER_THAN_WORLD` — `FrameWdgt._assertFitsInTheWorld`: a pop-up bigger than the world has rows
  nothing can click. A reference image disagrees only if a macro happens to click the row that went
  missing, which is exactly why menus shipped rows off the bottom edge unnoticed for years — so the
  invariant is asserted rather than left to be noticed.
- `DOWNWALK_UNREACHABLE_CHAINTOP` — `WorldWdgt`: a settle round made no progress with widgets still
  invalid; the convergence loop's own non-termination alarm.
- `DAMAGE_SUPPRESSION_UNBALANCED` — `WorldWdgt`: a non-zero `_damageSuppressionDepth` at cycle end. The
  structural half of [INV-1] lives in `Widget._repaintAsOneUnit`'s `finally`; this is the tripwire that
  says it was bypassed.
- `STORAGE_INVARIANT` — `StorageSorter`: a destroyed / misclassified / parent-desynced resident in the bin
  or on the shelf (its from-scratch twin is the gauntlet's `storage` leg).

⚠ One more token rides the same fail-gate but is NOT shipping code: `WORLD_CONSTRUCTION_DRIFT`, the
construction-determinism ratchet, lives in
`Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee` (arc 3 moved the test-only teardown
out of core), so it fires only on a build whose profile ships the `harness` part. Drifted page state reaches
the NEXT world the page builds, so no single test's pixels reveal it.

Beside that ratchet, at the same seam and in the same fail-gate, sits the object-lifetime audit's
`WORLD_INVENTORY_*` token family (`_DRIFT`/`_ESCAPED`/`_ZOMBIE`, emitted by
`WorldTestSupport._auditWorldInventoryNoSettle` driving `src/WorldInventory.coffee`) — it covers
exactly what the ratchet is structurally blind to: class statics, collaborator internals, module state, the
DOM, and widget IDENTITY. Doctrine + how to read a failure:
[`world-lifetime-and-inventory.md`](world-lifetime-and-inventory.md). (The runners consume the one shared
token list, `Fizzygum-tests/scripts/lib/gate-tokens.js`.)

---

## 3b. The THREE tiers, and which one a new rule belongs in (severity policy)

Make the implicit explicit — the tier is decided by the SIGNAL's soundness, never by how much we care:

- **A sound NEGATIVE ⇒ a HARD GATE.** If a true finding is *provably* wrong code and the checker cannot produce a false
  positive, fail the build (`check-layering`, `check-unresolved-sends`, the syntax gate). Land it green.
- **A count-shaped smell ⇒ a RATCHETED stink/baseline.** Real but tolerated-at-today's-count, driven down over time
  (`check-stinks`, `check-call-separation`'s `BASELINE_*`, the dead-method allowlist).
- **A SUSPECTED / heuristic signal ⇒ an ADVISORY exit-0 census.** If the finding needs a human to confirm it, it must
  never gate (`census-*.js`).

**An unsound signal must never gate.** The asymmetry is the point: a false gate-FAIL blocks correct work and trains
people to reach for `--noSyntaxCheck`, and — worse — a false gate-PASS bakes regressions into byte-exact references.
The same safety asymmetry is documented for `fg classify` (a BENIGN? verdict is a hint for reading a diff faster, never
permission to recapture). When in doubt, ship the rule one tier weaker and promote it once the evidence is in.

## 3b-docs. The DOCS ratchet — `check-doc-narration.js` (`fg doc-narration`)

The docs-side twin of the `comment-narration` stink. `docs/README.md` files every doc by what it IS,
and each bucket carries a TENSE; filing rule 3 requires durable residue to land in `architecture/`
"present tense, no changelog prose. The plan keeps the history; the architecture doc keeps only the
current truth." Nothing enforced that, so a doc could drift into explaining a live mechanism by naming
the dead one it replaced — and eventually contradict itself, one section stating a change landed while
another still proposed it.

**Scope is deliberately narrow.** It scans `architecture/` + `tooling/` (present tense by definition)
for narration, and `BACKLOG.md` for ONE thing — a closed item, read at the end of this section — and
NOTHING else: `specs/` is excluded because a spec's change/landing statements are load-bearing
(owner direction), and `plans/`, `archive/` and `measurements/` are chronological BY DESIGN — archive
is immutable past tense, plans are future tense, measurements are dated snapshots.

**It is a RATCHET at a HARD ZERO** — the per-file baseline in
`buildSystem/check-doc-narration-baseline.json` is EMPTY, so any narrating line in these buckets fails
it. It was seeded as a burn-down ratchet (19 lines, concentrated here and in
`layering-naming-convention.md`, where a ban is often explained by narrating what it removed); the debt
is paid, and an empty baseline is the honest end state — a number nobody can justify is a number nobody
defends. ⚠ Zero does NOT mean the buckets contain no history: five lines carry
`<!-- narration-ok: reason -->` because the ban or warning they state has no force without naming what
it bans. Reach for that hatch — with a real reason — rather than `--write-baseline`, which would bank
drift as accepted. A provenance stamp ("verified against `src/` <date>")
is NOT narration and is skipped; `<!-- narration-ok: reason -->` exempts a line that must quote the
trigger words. Fenced blocks and inline code are stripped before matching, so file paths and SHAs
cannot trip it. Not on the build — docs prose should not block a build — so it rides the gauntlet's `refs` leg (a commit point); `fg doc-narration` runs it alone.

**`BACKLOG.md` holds OPEN items only** (filing rule 2: a closed item moves, verbatim, into the trailing
`## BACKLOG ledger` of the plan that closed it), so a closed task item there (`- [x]` at any depth,
under any bullet, outside a fenced block) is an item that never moved: `BACKLOG_CLOSED_ITEM`, a hard
zero with no baseline and no hatch. Nothing else in the file is judged — an open item's "found
2026-10-23" is its provenance, not narration — and the OK line states the open count it read. A docs
tree with no `BACKLOG.md` is INVALID (exit 2), never a pass.

## 3c. The ANALYSIS tools (advisory censuses — never gates)

**§3 is everything that can fail your build; this section is everything that cannot** — the split that §3b's severity
policy prescribes. Five read-only censuses, all exit 0 (2 on operational error), all ≲1 s. Four are `--json`-capable and print
SUMMARY COUNTS by default, with `--full` for the lists; `census-call-arity.js` is the exception — it is query-shaped
(`--call=` / `--super=` / bare `new <Class>` names) and prints only what you asked for. One of them,
`census-widget-conformance.js`, ALSO has a `--gate` mode that the build runs — that half is a gate and lives in §3's
table. Run them from `Fizzygum/`
— or all at once, with every ratchet's "tighten me" note, via **`fg critique`** (~5 s, read-only). It deliberately
excludes jscpd/jsinspect (minutes-slow — those stay on-demand behind `./find_duplicated_code.sh` /
`./find_similar_code.sh`).

⚠ **`fg` is LOCAL workspace tooling and is committed to NO repo** (the umbrella `Fizzygum-all/` is not a git repo), so
`fg critique` does not exist in a fresh checkout — only the `node ./buildSystem/census-*.js` commands below do. That is
by design, but it means this doc, not `fg`, is the durable description. `fg critique` runs, in order: `check-stinks`,
`check-dead-methods`, `check-unresolved-sends`, `check-call-separation` (reprinting only each one's `UNDER` / stale-entry
NOTE), then four censuses' summary counts — `census-public-private-calls`, `census-hierarchy-duplication`,
`census-property-placement`, `census-widget-conformance` (its advisory view) — and the call-arguments gate's own verdict
line (it also runs on every build), then an advisory-only footer.

**When do these run?** The GATES run automatically on every build (any `build_it_please.sh`, `fg build/presuite/gauntlet`,
`build_and_test.sh`, the save-watcher) — there is no CI here, so "automatic" means the build on your machine, and
`--noSyntaxCheck` skips all of them. The CENSUSES never run automatically: they are advisory, so they run only when a
human asks (`fg critique`, or directly). The clone scanners are on-demand only (minutes).

| Census | Measures | Notes |
|---|---|---|
| `census-public-private-calls.js` | public/private SELF-call mixing (R1–R4) | ALSO the measurement ENGINE behind the [S]/[U] gate. Its `runCensus()` exports the whole-system **class model** (`classInfo` / `chainOf` / `resolve` — parent + methods + resolution order); the two censuses below REUSE it rather than re-implement it. |
| `census-hierarchy-duplication.js` | overrides that add nothing: `IDENTICAL-TO-INHERITED`, `JUST-SENDS-SUPER` | Pharo `ReEquivalentSuperclassMethods`/`ReJustSendsSuper`. The hierarchy-aware complement to jscpd/jsinspect, which know nothing of inheritance and so can never say "REMOVABLE". |
| `census-property-placement.js` | properties at the wrong level (`PULL-UP`) or wrong scope (`DEMOTE`) | Pharo `ReInstVarInSubclasses`/`ReVariableReferencedOnce`. |
| `census-widget-conformance.js` | the mechanical facets of `measurements/widget-practices-survey-2026-08-14.md`, so that survey is re-runnable rather than a one-off | Its ADVISORY run (exit 0, `--json`) prints six facets; the two OBJECTIVE ones are what `--gate` ratchets on the build (§3). Facet 5 (the pin setters) reads methods through the shared grouping (§6b), and only a setter that takes a value counts. ⚠ Facets 3–6 are heuristics with real exceptions and must NEVER gate — and facet 3 in particular is **not a gap count**: since the widget arc's W7 made `colloquialName` DERIVE from the class name, a class declaring none still answers a true name, so the number says how much of the tree the derivation carries, not how much work is left. On the gated pair: green means "nothing got worse"; only a baseline of 0 also means "nothing is left" |
| `census-call-arity.js` | call sites with their REAL argument count: `new <Class>` names, `--super=<classes>` (the supers IN those classes), `--call=<methods>`, `--min=N` | The work-list tool for converting a family. It reads the call-arguments gate's own table (`lib/call-sites.js` — real parsers, both repos), so an implicit object is one argument and a string's contents are never a call, and the two cannot disagree about what a call is; the VERDICT on an `undefined` is the gate's (§3; `--values` there lists the values), never this tool's. A forwarding bare `super` shows `?`: its arity is its caller's. |

**Why the hierarchy-duplication and property-placement censuses can never be promoted to gates** — the reasons are
specific, not ceremonial:
- **A `super` binds to the class whose body it is written in** (`src/meta/Class.coffee`'s `_rewriteSuperCalls`
  spells it `<ThatClass>.__super__.<member>`), so the same body text in a subclass and in its superclass calls
  different methods. Textual body equivalence is **not** dispatch equivalence.
- **Property access is partly DYNAMIC** (the `Duplicator` engine walks `@[property]`; serialization drives off name
  STRINGS), so "unused" is never statically provable.

Both censuses therefore carry SOUNDNESS RULES earned from false positives they actually produced — documented in their
headers and in the `duplication-report/triage-report.md` ROUND-4/4b sections. Do not "simplify" them away: the method
SIGNATURE is compared, not just the body (`(@color) -> super` is not removable); occurrences outside any method body
count as a distinct user (a multi-line ctor param list is public API); a `.name` member read from another file vetoes
a DEMOTE (22 settings fields — the global settings surface, `PreferencesAndSettings` and `Theme` — looked local); and a WRITE-ONLY
property is never a DEMOTE (it is presumed enumeration payload — see the fix note below). Findings withheld by those
last two rules are COUNTED and printed **separately**, never dropped silently.

**Findings land in the triage ledger, not in a commit:** `duplication-report/triage-report.md` (gitignored working
state; conventions in `docs/tooling/duplicated-code-detection.md`). The report IS the deliverable — acting on it is a separate,
verified arc. The closed round-4 record + its case law: `docs/archive/duplication-triage-2026-07-15-hierarchy-round4.md`.
**The findings have their own plan — now CLOSED: `docs/archive/census-findings-triage-plan.md`.** Phase 0 (fix the write-only
DEMOTE bug) DONE; Phase 3 DONE (13 of 20 actioned, DEMOTE 20 → 7 → 4, zero recaptures); Phase 1 DONE
(`BubblyAppearance.constructor` deleted ⇒ **`census-hierarchy-duplication` is now ZERO on all three of its reports**);
**Phase 2 CLOSED with ZERO actionable — all 10 PULL-UP findings falsified or forbidden.** Read it before acting on ANY
finding.

⚠⚠ **A non-zero census count is not a backlog, and both censuses' most-recommended items were FALSE POSITIVES.**
Across the arc they produced **26 findings that were technically true and wrong to act on** (16 write-only, 10
pull-up) against **13 worth taking**. PULL-UP's own strongest finding — 3 verbatim-identical colour defaults —
would have turned the desktop icons near-white, because each subclass's prototype also received the same properties
from elsewhere (in that 2026-07-15 tree, a mixin injecting them **onto the subclass prototype**), so the class-body
default existed to OVERRIDE that value, not to duplicate the parent: a default is a duplicate only if nothing else
writes the same key between the parent and the class. The other rejections: dynamic member access by a computed
name (`@[name + "IsConnected"]` in that tree), whole-object enumeration, and deliberate per-family conventions. None is visible to a name
scanner — which is exactly why these are advisory and can never be gates. **Treat a finding as a question, never an
instruction.** Full case law (14 entries): `docs/archive/duplication-triage-2026-07-15-hierarchy-round4.md`.

**The DEMOTE rule requires the property to be READ.** As
originally shipped it did not, so a **WRITE-ONLY** field was reported as demotable. That was wrong twice: demoting a
write-only field makes it **dead**, not local; and a write-only field is usually **enumeration payload** — reached by
`JSON.stringify(obj)` / the `Duplicator` engine's `@[property]` walk / the serializer, none of which a name scanner sees
(the census's KNOWN BLIND SPOT, now stated in its header). It cost **16 false positives out of 36 findings**, of which
**12 were `SystemInfo` fields that ARE a reference image's recorded provenance** — `SystemTestsReferenceImage.coffee`
serializes `JSON.stringify(@systemInfo)` into every reference record, so demoting them would have silently emptied that
blob in every reference captured from then on. The fix is **exclusion 4**: at least one occurrence must be a
non-assignment. **DEMOTE 36 → 20**; PULL-UP unaffected (byte-identical).

⚠ The test is *"at least one NON-ASSIGNMENT occurrence"*, **not** the `uses >= 2` originally proposed: `@x = 0` followed
by `@x += 1` is two uses and still write-only in effect. Compound assignments count as writes here, deliberately, to
keep the census conservative.

⚠ **The fix also corrected a misleading statistic** — exclusion 3's withheld count fell **49 → 3** (write-only is now
tested first). The `.name` member-read veto was being *blamed* for withholding 49 findings when its true cost is **3**:
the other 46 were write-only false positives it happened to suppress for the wrong reason. Both counts are printed
separately, so neither exclusion can hide behind the other again. The write-only bucket (62) is **not a backlog**:
separating dead state from enumeration payload needs exactly the analysis a name scanner cannot do.

**Considered and REJECTED** (so they are not re-proposed):
- A **`constructor.name` stink** — `new @constructor` / `@constructor.name` is a legitimate universal idiom here, so it
  would ratchet an idiom, not a smell.
- A **`console.log` stink, and `drop_console` in the production build — both rejected 2026-07-15, decided, do not
  re-open without new evidence.** It is true that console.logs are NOT stripped from production (`drop_console` appears
  nowhere in `build_it_please.sh`; `terser --compress` keeps `console.*`), but that fact is operationally empty: of 224
  non-comment sites, **201 are behind an explicit debug flag** (`@detailedDebug`, `window.srcLoadCompileDebugWrites`)
  and all 23 others are multi-line guards, audit blocks, Automator-only paths, or error handlers — **nothing logs in
  normal operation**. `drop_console` would be actively HARMFUL (it strips the error diagnostics we want in prod), and it
  could not shrink the bundle anyway: class sources ship as escaped TEXT and compile in-browser, so terser never sees
  them. A stink at ~213 would ratchet a disciplined idiom — the `constructor.name` mistake again. The one real finding
  inside the item (6 error paths using `console.log` where `console.error` is the verb the gates key off) was fixed.
  Full evidence: carryover plan §8.6.
- Anything **TRANSITIVE** — already rejected as intractable, see §7.

**On `census-public-private-calls.js` specifically** (the oldest of the five, and the only one that is also a gate
ENGINE): it measures public/private SELF-call mixing — private→public-command calls, double-settle shapes, and public
methods only ever `@`-self-called (privatization candidates). `check-call-separation.js` requires it as a module and
enforces the [S]/[U] count baselines on its numbers, and rule [T] (in `check-layering.js`) is the static twin of its
narrowed-R2 report. The campaign that owns the drawdown is **`docs/archive/public-private-call-separation-plan.md`** — re-run
the census at every tranche start. Methodology and blind spots are in the tool's header. Run from `Fizzygum/`:
`node ./buildSystem/census-public-private-calls.js [--full|--json out.json]` (its fixtures: `census-public-private-calls-selftest.js`).

⚠⚠ **What counts as a REFERENCE to a method is ONE stated rule, `buildSystem/lib/method-references.js`, read
from CODE.** Two gates ask it: `check-dead-methods` (is the method reached at all?) and R4 here (is it reached other
than by its own `@`-self-calls?). A method is reached in exactly four ways, in CoffeeScript and JS alike:
1. a property access: `@m`, `x.m`, `x?.m`, `C::m`, and a destructuring read of one (`{m, n: k} = x`,
   `const { m } = x`, `({m}) ->`, `for {m} in xs`); a class-side def key `@m:` is not one;
2. a whole-name string: `"m"` — string dispatch, the idiom of menu actions, `PinSpec` setters and `x["m"]`;
3. a name template: `"_#{@action}Connector"` reaches every method it matches, each interpolation a wildcard (one with
   no literal part, `"#{x}"`, is a coercion, not a name);
4. a computed access on a named class: `FormulaHelpers[name]` (or `C?[k]`, `C?.[k]`) reaches every class-side
   method of that class, `C::[k]` every instance method — its own and its ancestors'; a key that is one
   whole literal (`C["m"]`) is clause 2's, and a write (`C[k] = …`) reaches nothing.

A BARE WORD reaches nothing — a local (`for toggle in …`), a parameter, an object key, a def's own name — and neither
does a comment or prose. So a sentence in a test's `intent`, a `#` note in a macro, a debug-log label
(`"addCommandsSeparations 1: "`) or a local named like a method keeps nothing alive. The code is read through two
readers: the compiled sources, src and the harness, through `lib/coffee-mask.js` (§6c); the rest of the sibling tests
repo through `lib/tests-repo-code.js`, which reads each macro command file (its JS PARSED by `lib/js-mask.js`, on acorn, its macro sources through coffee-mask)
and `scripts/**/*.js` (whose `page.evaluate` bodies call core methods as directly as a macro does), and never the
metadata prose, the reference-image records or the generated manifests. Clauses 3 and 4 are DERIVED from the
dispatch site, so the connector lane and the formula helpers need no allowlist entry: a new `FormulaHelpers` static is
reached the moment it exists, as that class's header promises. Inside a string, R4 counts any reference as `other`
(macro heredocs and dispatch strings are external surface) — an interpolation's code is code, so `"#{@m()}"` is an
@-self call —, and a method computed dispatch reaches is `other` too.

The COMPILED SOURCES — the CoffeeScript the build compiles: `src/` and the tests repo's harness
(`Automator-and-test-harness-src/`, the other half of the `harness` part) — have ONE definition, `lib/source-files.js`
`compiledFiles({ src, testsRepo })` (`srcFiles` and `harnessFiles` its halves, `coffeeFilesIn(root)` the one walk under
both), and EVERY gate and census reading them takes its files from it (the syntax gate reads the partition, which the
coverage gate holds to it): no two gates can disagree about which files exist, and the
harness is held to src's rules (the retired region and whole-file markers at zero, comments that state what IS, a
wall-clock read sanctioned by name). The rule is `testNames`' (below): refuse, never skip. Every `.coffee` file is read,
one in a dot directory or a `node_modules`, or named with a leading dot, included — `check-shippable-coverage.js`, whose
full set is the same `compiledFiles`, fails each such file as UNSHIPPED, so none sits unseen. A SYMLINK anywhere under a
root is REFUSED (`SOURCE_TREE_MALFORMED`, naming it): build.py's glob follows a symlinked file and does not descend a
symlinked directory, so a file behind one would ship by a meaning no gate shares, or ship and be seen by nothing. A
missing root and one holding no `.coffee` file are refused too (a gate that reads nothing passes); an absent tests repo
leaves src alone. The order is code point. A gate prints a src file's name as it always has and a harness file's as
`harness/<rel>` (`sourceName`), and takes both trees as rails, `--src=DIR` and `--tests-repo=DIR` (`sourceRoots`), so
its bite-proof plants either (§3). The PARTITION (`parts.json`, `build.py --list-shippable`) answers another question
— which PART ships a file — and `src/boot`'s files are declared there apart from it (each part's `bootPrelude` /
`bootScripts`, `build.py --list-boot`, each file with its part and kind, read through `lib/boot-pieces.js`): the
coverage gate is the one place that holds the files to both, and every gate that needs the boot files' LIST — their
parts, their kinds — (the syntax gate, part-edges, what-pins-core) reads it there, never by walking `src/boot` (the
source-vault gate, which scopes a rule by the `src/boot/` path prefix over the files it reads anyway, asks no list).

The MACRO SOURCES — every CoffeeScript text the macro engine compiles — have ONE reader, `lib/macro-sources.js`, in two
kinds: a test's (`testMacroSourcesIn`: the value of its command file's `mainMacroSource` and each `extraSubroutineSources`
entry, found in the JS parse — what the harness compiles, never "every template literal") and a verb's
(`verbMacroSourcesIn`: each `Macro.fromString` string literal of a CoffeeScript file, read off the lexer's tokens —
§6c's reading, so a file only the fragment compiler parses, a bare `super` in it, reads — wherever in src it is
written; a reference argument, the harness compiling a test's sources, is none). Both are
COOKED, each escape read as the character it makes, so no gate reads escaped text as CoffeeScript. Every Node reader
takes them from it (these two gates, unresolved-sends, the call-arguments table, layering's [D], the macro source
discipline gate, aim-census, the capture's screenshot names, the visualisation pages' step comments). It REFUSES
(`MACRO_SOURCE_UNREADABLE`) a source the file does not hold as text (a test's that is neither a string literal nor a
template literal without `${…}`, an `extraSubroutineSources` that is no array — the page compiles each of its elements —,
a verb's that is computed when the page runs), and one whose escapes add or remove a line break (a written `\n`, a
`\⏎`), since every reader reports a source line by its file line.

The TESTS have one definition too, `lib/tests-repo-code.js`'s `testNames`: every directory of `tests/` (what the manifest
lists and the harness plays), each one a `SystemTest_<x>` holding the two files the harness loads by its name —
`<name>.js`, its metadata, and `<name>_automationCommands.js`, its commands (`metadataFileOf`, `commandFileOf`). A tree
that breaks that is REFUSED (`TESTS_DIRECTORY_MALFORMED`, naming the directory), never skipped: the harness would play
it, so a reader that passed it over would pass a test it never read. Every reader of the tests takes them from it —
the manifest generator, the gates that read the tests one by one (layering's [D], the macro source discipline gate,
aim-census, the test syntax and visualisation gates, hand-lists), and every name check — the reference gate's, the
runners', the capture tools' —
each naming a test the way `testNameOf` does (with or without its `SystemTest_` prefix).

Every limit errs toward ALIVE, so it can only HIDE a dead method or a privatization candidate:
- a whole-word string equal to a method's name counts — a scan cannot tell a dispatch string from a table string (the
  capstone's wrap list keeps `setMaxDim` reached);
- a string that reads like code counts (`'MenuWdgt[own]'`), because code lives in strings here (macro sources,
  tool-code blurbs);
- a coercion template with a short literal part (`"#{n}px"`) reaches every method it matches;
- two same-named methods on unrelated classes cover each other. Making the rule class-aware was MEASURED and rejected
  (`../archive/connector-ubiquity-and-reflection-plan.md`'s BACKLOG ledger): only 10% of references to a colliding
  name carry any class information, so it would flag 543 pairs to find a handful.

Still BLIND, as any name scan is: a name assembled with `+`, and a computed access on an arbitrary object
(`@target[action]`) — those are each gate's allowlist. Neither reader misreads its language: CoffeeScript is read by
its own lexer (§6c) and JS PARSED (`lib/js-mask.js`, on acorn), and each refuses a text it cannot read. ⇒ **both
gates are sound in the direction they
claim** (what they flag really is unreached) **and incomplete in the other**; do not read a green run as "no dead
methods".
⚠ The authoring corollary, for code you write: **never write a method's own exact name as a whole string inside its
own body** (a label, a log tag) — that is a reference the rule counts, so the method can never be reported dead. The
macro toolkit's aim-check labels (`_aimingAt target, "moveToAndClick"`) drop the `_InputEvents` suffix for exactly
this reason.
⭐⭐ **Why the residue is acceptable: the methods a static scan cannot judge are precisely the ones the two RUNTIME
sweeps above cover.** A method reached only by a dispatch string is a `PinSpec` setter or an `addMenuItem`/`wireTo`
action, and the pin sweep proves those setters RESOLVE while the menu sweep proves those actions do. "It resolves when
dispatched" is strictly stronger than "the name appears somewhere in the tree", and it lives in the place that can
establish it.

⚠ **The other gates that read the tests repo read it for other questions, each measured
(`../archive/tests-repo-readers-plan.md` §2).**
- `check-call-arguments` and `census-call-arity` read every CALL — through `lib/call-sites.js`, real parsers over the
  harness's class fragments, each macro source as the page compiles it, the heredocs and the scripts.
- `check-unresolved-sends` reads the harness as definitions and calls, and each macro's CoffeeScript sources as calls.
- `check-hand-lists` and `check-layering` rule [D] read comments ON PURPOSE: their sanction markers live there.
- `check-relayout-repaints` is a tombstone scan, which must see a retired name even in a comment.
- `census-property-placement` already masks the harness with coffee-mask.

---

## 4. `check-layering.js` rules

The scanner reads each line's bare code (§6c: comments and literal contents blanked) so a call-regex never matches a
name in a throw-message or comment, groups lines into methods with the shared `methodBoundary` (`lib/coffee-method-header.js`), and keys call detection off a leading
`@`/`.` + the lowercase public name (so `@setExtent`/`.moveTo` match while `@_applyExtent`/`@_applyExtentBase`/`@_setTextNoSettle`
do NOT — the leading `_` sits between the `@`/`.` and the verb). This co-design with the **naming convention** is why the
lint works at all (§6).

| Rule | Subject | Forbids | Why | Runtime twin | Marker |
|---|---|---|---|---|---|
| **[A]** | `isLowLevel` method | calling a public geometry setter (`setExtent`/`moveTo`/`setBounds`/`setWidth`/`setHeight`), a single-settling text setter (`setText`/`setFontSize`/`setFontName`/`toggleWeight`/`toggleItalic`/`toggleIsPassword`), or `recalculateLayouts` | low-level code mutates immediately and must never reach UP into the self-flushing layer | the one-flush throw | — (fix the code: use the `_<name>NoSettle` core / an apply corner) |
| **[B]** | any method not in `RECALC_WHITELIST` = `{doOneCycle, _settleLayoutsAfter, _settleLayoutsAfterOrJoinEnclosingPass}` + `RECALC_ORACLES` (`_checkPaintTruthfulness`, the harness's paint audit) | calling `recalculateLayouts()` | only the frame and the two settle tiers — the single-mutation tier and the reactive-connection lane (rule [P]) — may drive a flush, and an ORACLE outside the world completing the frame it observes | `RECALC_ORACLES` (an entry that drives no flush fails, `B_STALE_RECALC_ORACLE`) | — |
| **[C]** | a public geometry setter | calling another public geometry setter | would flush more than once per logical mutation | — | — |
| **[D]** | every macro source (`lib/macro-sources.js`): each test's (its command file's sources) and each verb's (a `Macro.fromString` literal anywhere in src) | calling a `_private` method or a `raw*` (pixel) accessor | macros must drive only the public surface (the gate that would have caught the original 16-macro mess) | — | — (HARD ban; the construction measure-and-size carve-out is now CLOSED — attach the widget first, then public setters, see §7) |
| **[E]** | `isImmediateMutator` (the `_apply*`/`_commit*` corners + the `_move*`/`_set*`/`_resize*` convenience) | calling `_invalidateLayout` | an immediate mutator may MUTATE geometry, never SCHEDULE a layout — scheduling during a pass re-dirties a container mid-pass and the convergence loop never terminates (the Phase-3b app-freeze) | `FLOWRULE_VIOLATION` (`Widget._invalidateLayout`) | — |
| **[F]** | a method that is NEITHER low-level NOR an immediate mutator (handler / property setter / menu action / gesture / constructor) | calling a container-refit apply (`_reLayoutChildren`/`_positionAndResizeChildren`/`_reLayoutScrollbars`/`_reLayout`) synchronously OFF-settle | such a handler must DEFER (record intent via `_invalidateLayout`; let the cycle apply it), unless the apply is genuinely AT a settle point / a documented determinism-exempt family | — | **`# layout-apply-sanctioned: <why>`** |
| **[G]** | `isLowLevel` method (not a settle tier) | calling a STRUCTURAL self-settling wrapper — discovered structurally as the `_settleLayoutsAfter` callers (`destroy`/`close`/`fullDestroy`/`createReference*`/`grab`/`drop`/`slideBackTo`/`setLabel`/`buildAndConnectChildren`/`resetWorld`/`sizeToTextAndDisableFitting`) — OR the unambiguous self-add `@add` | the structural-wrapper extension of [A]: each wrapper self-settles via `_settleLayoutsAfter`, so reaching one from a core/raw/pass re-enters the flush; low-level code must call the `_<name>NoSettle` core | the one-flush throw | **`# nosettle-sanctioned: <why>`** |
| **[H]** *(WARNING, non-fatal)* | a method that self-settles via `@_settleLayoutsAfter` | a GUARD `return` / `return if\|unless …` BEFORE the settle | a public settle-wrapper should be THIN; that early-return guard belongs INSIDE the `_<name>NoSettle` core (else the "already in this state" skip is split across wrapper + core) | — | **`# early-return-sanctioned: <why>`** |
| **[I]** | a `__` leaf method (HARD-FAIL) | `@`-self-calling the re-fit seam (`_reFitContainer*`/`_announce*`), a react step (`_reLayout*`, or a repaint verb — read from Widget by `lib/repaint-verbs.js`), a schedule/settle (`_invalidateLayout`/`recalculateLayouts`/`_settleLayoutsAfter*`), or a public setter | a `__` leaf is a true bottom — it triggers NO orchestration (the lowest tier of the naming convention, §1) | tier-naming runtime audit | — (DENYLIST; `@`-self-scoped) |
| **[J]** | a notification callback (`_reactTo*`/`_before*`) | calling `_settleLayoutsAfter` | a callback is a settle-neutral core; the gesture/structural DISPATCHER owns the one settle | notification-settle runtime audit | — |
| **[K]** | a 2×2 apply CORNER (`_apply<Geom>` polymorphic / `_apply<Geom>Base` override-bypass twin / `_commit<Geom>AndNotify` notify-only) | a `_apply*Base` bypass twin firing the container re-fit seam (`_reFitContainer*`/`_announce*`) or DISPATCHING to its polymorphic `_apply*` sibling; a `_commit*AndNotify` corner reacting (a repaint verb / `_reLayout*`) | post-Tier-B the corners are REACT × DISPATCH: a `_apply*Base` reacts but must BYPASS the override — not fire the seam, not route the arrange apply back through `_apply*`; the notify-only corner must not react. The two statically-sound NEGATIVES; the old positive "*AndNotify reaches the seam" is retired with the seam (deleted 2026-07-01) | tier-naming runtime audit (now vacuous) | — | <!-- narration-ok: the seam's absence is why this positive check is vacuous; without it the row reads as a live check -->
| **[L]** | a notification callback DEF (`_reactTo*`/`_before*`) | a name not matching `_(reactTo\|before)(Being\|Child\|HolderFrame)<Event>`, a `NoSettle` suffix, or a legacy fragment (`childX`/`justBeen`/`iHaveBeen`/`aboutTo`/`prepareTo`) | callbacks follow the derivable (perspective × phase) scheme | — | — |
| **[M]** | any method DEF | a retired geometry/structural naming fragment as the name — `raw[A-Z]…` / `^silent[A-Z]` / `^fullRaw`, unconditionally (the harness, which the gate reads like src, defines no `raw*` method: its raw-PIXEL data, `rawPixelInfo`, is a parameter) | the `raw*`/`silent*`/`fullRaw*` geometry+structural prefixes were eliminated (§2 of the convention); lock them out — note `full[A-Z]` stays legitimate (`fullBounds`/`fullPaintInto`/…) | — | — |
| **[N]** | any method DEF | a name matching `/^_announce\w*ToContainer$/` (the retired notify-by-mutation container seam) | the mutation-time re-fit seam was deleted 2026-07-01 and replaced by the settle-time up-edge `_reFitMyTrackingContainerAfterSettle`; this bans reviving the announce-up verbs on the DEF side (the CALL side is already [I]/[K]) | — | — | <!-- narration-ok: this rule exists to stop a deleted seam being revived, so it must name what it bans -->
| **[O]** | any method NOT in `COALESCED_CALLER_ALLOWLIST` (seeded `{nonFloatDragging}`) | a `[@.]…Coalesced` CALL to a `*Coalesced` entrypoint (`_setMaxDimCoalesced`/`_setExtentCoalesced`/`_moveToCoalesced`/`_setWidthCoalesced`/`_setHeightCoalesced`) | a `*Coalesced` entrypoint DEFERS its layout settle to the ONE end-of-cycle flush — byte-identical (sound) only for a per-event STREAM handler that never reads back the settled layout mid-cycle; a discrete caller must use the self-settling setter. These entrypoints are `_`-private for the same reason (only stream handlers may reach them) | — | — (add a genuine new stream handler's method name to `COALESCED_CALLER_ALLOWLIST`) |
| **[P]** | any method whose name does NOT end `Connector` | a `[@.]_settleLayoutsAfterOrJoinEnclosingPass` CALL | `_settleLayoutsAfterOrJoinEnclosingPass` is the reactive-connection settle lane — reached mid-pass it JOINS the open layout pass instead of throwing (so a wired reactive circuit — the °C↔°F converter — settles once); sound ONLY for a dedicated `_<name>Connector` entrypoint carrying the `connectionsCalculationToken` cycle-guard. A general/internal caller must use the self-settling `_settleLayoutsAfter` (surfaces the flow violation) or a `_<name>NoSettle` core | `Widget._settleLayoutsAfter` throw (§1) | — |
| **[Q]** | any method NOT in `CONNECTOR_CALLER_ALLOWLIST` (seeded `{recalculateOutput}`) | a hard-coded textual `[@.]_<name>Connector(` CALL | the connector lane JOINS an already-open pass instead of throwing ([P]), so a textual call to one smuggles a never-throwing setter past the flow guard. The reactive dispatch resolves the connector name at RUNTIME and needs no textual call — only a sanctioned mid-cascade self-render (a patch node's `recalculateOutput`) may call one directly | `Widget._settleLayoutsAfter` throw (§1) | — (add a genuine mid-cascade render's method name to `CONNECTOR_CALLER_ALLOWLIST`) |
| **[R]** | a method in a `USERLAND_FILES` file (the standard-user-use exemplars: the menu-built windows/panels of `MenusHelper`) | calling another widget's immediate cores (`<recv>._apply*`/`._move*` — a `@`-self call has no identifier+dot and is not matched) | userland is the worked example of the PUBLIC self-settling API (`setBounds`/`moveTo`/`setExtent`/`setWidth`/`setHeight`/`moveWithin`); the immediate cores are reserved for low-level / in-pass code | — | **`# private-use-sanctioned: <why>`** (per LINE) |
| **[T]** | a method whose own body calls `@_settleLayoutsAfter` (the same textual subject `discoverSettlingWrappers` keys off; the settle tiers in `RECALC_WHITELIST` are exempt) | ALSO `@`-self-calling a settling public method — a geometry setter, a text setter, a discovered settling wrapper (name-qualified via `nearestDefinerKind` like [G]), or the self-add `@add` | two flushes for one logical mutation — the whole-settling-surface generalization of [C]. `@`-self-scoped (a dotted receiver settles ANOTHER widget — untypeable). Branch-exclusive pairs (one flush per path, sound) are textually indistinguishable → marker. At rule birth (2026-07-12) exactly 3 sites, all conscious+marked: `grab` (hand-rolled sequential gesture settles) and `newParentChoice{,WithHorizLayout}` (documented idempotent re-fit flush after `@add`) | the one-flush throw | **`# double-settle-sanctioned: <why>`** |

**[G] specifics.** The wrapper set is **discovered**, never hand-listed: `discoverSettlingWrappers` collects every method
whose body calls `@_settleLayoutsAfter` (`SETTLE_CALL` anchors on that exact name, so the reactive-connection
`…OrJoinEnclosingPass` lane is not swept in), minus the geometry/text setters ([A] reports those, sharper) and minus
`WRAPPER_EXCLUDED` (§7). So a NEW single-settling wrapper is auto-covered. The `@add` self-form is checked separately (`SELF_ADD_CALL =
/@\s*add\b/`): inside a Widget method `@` is a Widget, so `@add child` is unambiguously `Widget.add` — the `\b` excludes
`@addMany`/`@_addNoSettle`, and the leading `@` (not `.`) excludes the Point#add-ambiguous member form.

---

## 5. The in-code markers + the two ratchet idioms

**Markers — "the justification lives AT the method, no central allowlist."** Each exempts a single method/line via a
comment carrying a reason. All of them, in one place:

| Marker | Gate / rule | Exempts |
|---|---|---|
| `# layout-apply-sanctioned: <why>` | `check-layering` [F] | a non-mutator method consciously applying a container refit off-settle (an in-pass deferred-seam arm, or a determinism-exempt family: scroll-input / collapse / construction) |
| `# nosettle-sanctioned: <why>` | `check-layering` [G] | a low-level method consciously reaching a settling wrapper / `@add` (e.g. a method mis-tagged low-level, or a genuinely safe outside-any-pass case) |
| `# early-return-sanctioned: <why>` | `check-layering` [H] *(warning)* | a public settle-wrapper that consciously keeps a guard `return` BEFORE its `_settleLayoutsAfter` (suppresses the non-fatal [H] warning) |
| `# double-settle-sanctioned: <why>` | `check-layering` [T] | a directly-settling method that consciously ALSO `@`-calls a settling public method — a deliberate sequential-flush design (`grab`, `newParentChoice`) or a branch-exclusive pair the line scanner cannot tell apart |
| `# public-call-sanctioned: <why>` | `check-call-separation` [S] | a private method consciously `@`-self-calling a public COMMAND (the census subtracts the site; use sparingly — the default fix is rename-to-`_` or the `_<name>NoSettle` core) |
| `# macro-private-call-sanctioned: <reason>` | `check-layering` [D] | one macro/heredoc LINE calling a `_private` verb — a test ORACLE that must reach ground truth (`world._fullChanged()`) |
| `# private-use-sanctioned: <why>` | `check-layering` [R] | one line in a userland exemplar file reaching another widget's private core |
| `# thin-wrap-exempt: <reason>` | `check-thin-wraps` | a method that owns a `_<name>NoSettle` twin but legitimately cannot be the canonical mechanical wrap |
| `# cross-invalidation-sanctioned: <reason>` | `check-invalidation-receivers` | one line marking ANOTHER widget changed (the structural dispatchers, the world's atlas-warm and selection-overlay reconcilers, an async-asset repaint, own-sub-part marks) |
| `# relayout-bounds-first-exempt: <reason>` | `check-relayout-bounds-first` | a `_reLayout` that consciously reads its own geometry before applying its own bounds |
| `# raw-screen-pointer-sanctioned: <reason>` | `check-raw-pointer-reads` | a pointer handler that genuinely wants the raw SCREEN-plane sample (currently ZERO sites) |
| `# escalated-pos-sanctioned: <reason>` | `check-plane-discipline` (C) | a pos-reading pointer handler on a scroll-translation provider that deliberately consumes a descendant-plane pos (currently ZERO sites) |
| `# constructor-build-exempt: <reason>` | `check-constructors-build` | a `constructor:` that legitimately must build its children inline (currently ZERO) |
| `# stringified-script-sanctioned: <reason>` | `check-stringified-scripts` | one `new ScriptWdgt """…"""` line in core |
| `# saved-content: <what makes it content>` | `check-back-buffer-memos` | a field a back-buffer builder writes that IS the saved picture rather than a memo of the cache — a declaration of what the field is, not a sanction; read from the field's DECLARATION line or the contiguous comment block directly above it (one site: `CanvasWdgt.drawnRaster`) |
| `# page-element-not-held: <reason>` | `check-page-loaded-elements` | a line that constructs an element the page loads into no field — why no widget holds it (one site: the Deserializer's `$Canvas` decoder image, dropped once its pixels are in the canvas) |
| `<!-- narration-ok: reason -->` | `check-doc-narration` | one docs LINE that must quote the narration trigger words (this doc's stink table does) |

**Placement is per-gate, and it is not decorative.** The `check-layering` per-method markers ([F]/[G]/[H]/[T]) and
`# public-call-sanctioned` are detected anywhere in the method's body and reset at each method header.
`# thin-wrap-exempt`, `# relayout-bounds-first-exempt` and `# raw-screen-pointer-sanctioned` are read ONLY from the
contiguous comment block *directly above the header* — one in the body does not exempt; `# constructor-build-exempt`
is read from either. The rest are per-LINE: `# cross-invalidation-sanctioned`, `# macro-private-call-sanctioned` and
`# stringified-script-sanctioned` on the line or the comment line(s) directly above it, `# private-use-sanctioned` and
`<!-- narration-ok -->` on the line itself.

⚠ **The reason is required by convention everywhere, but only some gates enforce it.** Seven match
`<marker>:\s*\S` and so reject a bare marker (thin-wrap, relayout-bounds-first, raw-screen-pointer,
constructor-build, cross-invalidation, stringified-script, and [D]'s macro marker); the six `check-layering`/
call-separation per-method markers match the bare string, so nothing but review makes you write the *why*.
Write it anyway — a marker without a reason is exactly the silent allowlist this idiom exists to avoid.

**Two ratchet idioms** (a convention that isn't a gate rots; new rules should use one so they land green today and
tighten incrementally):
- **baseline / allowlist** (`check-dead-methods`, `check-stinks`, `check-unresolved-sends`, `check-call-separation`):
  record the current count/set, fail on *regression*, drive the baseline down over time. To drive down: fix occurrences,
  then tighten the inline `baseline` (stinks, call-separation) or remove from `dead-method-allowlist.txt` /
  `unresolved-sends-allowlist.txt` to lock the gain. Baseline 0 / empty allowlist = a hard rule.
  **The central allowlist files** (each `name # reason`, one per line, `#` comments):
  `buildSystem/dead-method-allowlist.txt` (dead-method) · `buildSystem/unresolved-sends-allowlist.txt`
  (unresolved-sends: vendor + genuinely-dynamic names; platform API goes in that checker's in-file `BUILTINS` instead) ·
  `buildSystem/public-api-allowlist.txt` (call-separation [U]: deliberate end-user inspector/scripting API).
  Each of those gates **FAILS on a stale entry** — one that excuses nothing — naming it after the arc-wide
  word `STALE_ALLOWLIST_ENTRY` (see "Every stated table fails on an entry that names nothing" below); a count that
  falls below its baseline is a gain to bank, and stays a NOTE (`fg critique` resurfaces those).
- **per-method / per-line marker** (the fourteen in-code markers tabled above): the justification
  lives at the method, no central list; a NEW unmarked violation fails the build. Best when the exception is a property
  of one method or one line, not a count.

**The names a gate keys on are DERIVED, or ASSERTED — never a hand list that can silently check less.** A gate or rig
that recognises things by NAME (verbs, fields, slots, classes, tokens) and keeps those names beside the code that declares
them goes vacuous the day the declaration moves: the matcher still runs, matches nothing, and reports a clean verdict.
So a name list takes one of two shapes. **Derived** — read at the point of use from where the names are declared:
`lib/repaint-verbs.js` (Widget's own `_changed`/`_fullChanged…`, for `check-layering` [I]/[K], the call census and
`check-invalidation-receivers`), `lib/settle-tiers.js` (Widget's `_settleLayoutsAfter…` methods, each held to its body
both ways, for `check-layering` and both censuses), `lib/settling-setters.js` (the public geometry and text setters
that self-settle, for `check-layering` [A]/[C] and the call census), `check-plane-discipline` B's position queries
(Widget's frame delegations), the syntax gate's provided helpers (`Class._memberNamesThatMustStayAnonymous`), and, in
the tests repo's runtime rigs, the world's collections and drag-embed slots (serialization rig), the menu contributors
(menu sweep), an appearance's wearers (pin sweep), the app battery (census), the classes an audit prelude wraps
(every own declarer, through `allClassFunctions()`). **Asserted** — a stated table that fails BOTH ways, on an entry
naming nothing and on a name it should hold: `lib/pointer-handlers.js` against `ActivePointerWdgt`,
`lib/immediate-mutators.js` against Widget's `_apply*`/`_commit*` methods (§2), the tier-naming families against every
class's, a `*TestSupport`'s `@staticMembersToInstall` against its own class-side keys (`lib/install-edges.js`),
`GATE_TOKENS`/`NOT_GATED` against every `console.error "<TOKEN>` (its selftest), and every exclusion table beside a
derivation (`NOT_POSITIONAL`, the rig's `NOT_EMPTIED_BY_THE_TEARDOWN`, the census's `KNOWN_MOVERS`). Two invariants
make either shape trustworthy: **a derivation that finds nothing FAILS** (exit 2 / `*_VACUOUS`), because an empty set
certifies everything; and **a check is believed only after a PLANT has been seen to fail it** — the drift planted (a
`--prelude=` plant for the runtime rigs, `--files` or a scratch tree for the build gates) and removed. Plan + ledger:
[`../archive/hand-kept-lists-plan.md`](../archive/hand-kept-lists-plan.md).

**The rule holds for EVERY hand list, not only a gate's — and `check-hand-lists.js` holds the string-list shape of it.**
A list anywhere in src, buildSystem, the harness or the tests repo's scripts that names classes or members declared
elsewhere is DERIVED from the declaration, or ASSERTED against it both ways, or it is a second source of truth that
"silently checks less" — the one failure mode no gate may have — the day the declaration moves, and treats one member
differently from its siblings everywhere the list is read. The gate reads every string-list LITERAL with a multi-line tokenizer (the
lists that rot are one name per line, which no per-line stink sees) and calls one a NAME list when at least two of its
items, and at least half, are class or member names. Such a list is a DECLARATION (a class's own
`@serializationTransients`, `requiredParts`, `optionalParts`), or carries `# hand-list-sanctioned: <what fails>` on its
opening line or directly above it, whose text must NAME A REAL GUARD — an existing gate/rig file, an existing
`SystemTest_<name>`, or a failure token the code emits (resolved mechanically; `SANCTION_NAMES_NO_GUARD`,
`SANCTION_STALE` and `SANCTION_EMPTY` fail outright) — or it counts against a per-repo ratchet that only falls. Writing
the sanction is the point: it forces the author to say what goes red when the list goes stale, and a reviewer can check
the claim. ⚠ Blind spots, stated: it sees string-list literals only — not object tables keyed by names, regex
alternations, `switch`/`when` arms, sequences of pushes, or names assembled at runtime — and a list under half names
passes unseen; resolution proves the named guard EXISTS, not that it covers the list. **Every stated table fails on an
entry that names nothing**, its companion rule: an allowlist, exemption, skip, fixture or install list — the three
central `.txt` allowlists, `check-layering`'s caller allowlists and `USERLAND_FILES`, the stinks `exclude` prefixes,
`BUILTINS` and its `PLATFORM_GLOBALS`, the menu sweep's six tables, the pin sweep's `FIXTURES`, the lazy-icons `SAMPLE`, the serialization rig's
`DAMAGE_FIELDS` and `SWCANVAS_ONLY_CHECKS`, `_worldStateAuditExemptions`, `SWCanvasBrokenTests` — reports an entry
that matched nothing this run and FAILS on it, as `STALE_ALLOWLIST_ENTRY <table> <entry> — <why>` (a gate token in the
page, so the suite runners fail on it too). A stale entry is worse than none: it reads as a decision about something
that does not exist, and one keyed by a NAME silently excuses whatever next reuses that name.

---

## 6. The tier / naming convention, co-designed with the lints

`isLowLevel`/`isImmediateMutator` classify by NAME, and the call-detection regexes anchor on `[@.]` + the word-prefix —
so the **naming convention and the lints are co-designed** (the lint works at all only because the name encodes the
behaviour). This section covers just *why the names and the regexes fit together*; the full two-family convention (the
geometry-apply **2×2** + the notification **(perspective × phase)** grid) and its two runtime audits live in
`docs/architecture/layering-naming-convention.md`.
- **The geometry-apply tiers are all `_`/`__`-prefixed** — the leaf `__commit<Geom>`, the override-bypass arrange twin
  `_apply<Geom>Base`, the polymorphic apply `_apply<Geom>` (ex `_apply<Geom>AndNotify` — Tier B), the notify-only
  `_commit<Geom>AndNotify`, and the `_move*`/`_set*`/`_resize*` convenience. The leading underscore sits between the
  `@`/`.` and the verb, so `@_applyExtent`/`@_applyExtentBase` do NOT match the public-setter regex `[@.]\s*setExtent`. (`raw*` survives ONLY as the pixel accessors `rawPixelInfo`/`rawPixelHash`/
  `rawRGBA`; rule **[M]** bans any new `raw*`/`silent*`/`fullRaw*` geometry/structural name.)
- **`_<name>NoSettle` cores** — do the mutation + invalidate, never settle ("cores call cores"). The leading `_` makes
  `@_setTextNoSettle` invisible to the `[@.]\s*setText\b` text-setter regex.
- **`NoSettle` suffix = a "non-settling region" signal, TWIN-OPTIONAL** (owner-decided 2026-06-25) — it marks the
  *property* (nothing downstream settles), not "the core of a public/core pair". So a structural core can carry it with
  no public twin (`_addInPseudoRandomPositionNoSettle`); the thin-wrap gate SKIPS a twinless `*NoSettle`. (The
  notification callbacks that once mis-carried `NoSettle` — `_reactToGrabOfNoSettle` &c. — DROPPED it in the naming
  campaign: a callback is a settle-neutral core by rule [J], so the suffix said nothing.) Memory:
  `fizzygum-layering-naming-tiers`.

---

## 6b. What "this line defines a method" means — ONE shared matcher, and its guard

Ten gates and censuses group a `.coffee` file into methods: `census-public-private-calls`,
`census-nosettle-naming`, `check-dead-methods`, `check-raw-pointer-reads`, `check-plane-discipline`,
`check-layering`, `check-relayout-bounds-first`, `check-thin-wraps`, `check-menu-actions` and
`census-widget-conformance` (facet 5, the pin setters). They all take both the header spelling and the grouping from
**`buildSystem/lib/coffee-method-header.js`**: `METHOD_HEADER` / `STATIC_METHOD_HEADER` say what a
header line is; `methodBoundary` / `methodSpans` say which method a line belongs to — a class's 2-space
methods and its class-side `@name:` methods alike. A key written deeper (inside an object literal, or a
def nested in a method's body) is body, never a method of its own, so a member that lives anywhere but
a class body is seen by no gate: every home of a member is a class. Re-declare neither locally — the
module exists because six copies of one regex had drifted into a shared blind spot nobody could see, and
the grouping had been copied three times besides.

A **class-side key** bounds a method exactly as an instance key does: a class-side METHOD is a span of its
own, reported under its source spelling `@name` and flagged `static: true`, and any other class-side key
ends the method above it. So no gate keying by name can mistake a static for the instance method of the
same name, a gate about instance methods only (`check-call-separation`'s census, `census-nosettle-naming`)
skips it by the flag, `check-layering` reads its TIER from the bare name (`@_arrange` is in-pass,
exactly as `_arrange` would be) and leaves it out of settle-wrapper discovery (a static has no instance to
settle), and `check-dead-methods` inventories it under its bare name, which is how it is called
(`Class.name`, or `@name` between the statics of one class).

A header is either **closed on the line** (`foo: ->`, `foo: (a, b) ->`, `foo: (a)->`, `foo: (a) =>`,
`foo:  ->` with the body aligned past a run of spaces) or **opens a wrapped parameter list** (`foo: (`
with nothing after the paren; the continuation lines are ordinary body lines to every gate, which is
correct — they are the signature).

⚠ **The failure mode this protects against is silence, not noise.** A gate that cannot see a method does
not warn about it — it reports nothing, so its output looks healthy and its counts look stable. Both
spellings above escaped every gate until a reformatted signature moved the census's method total by
exactly two; the module's own header comment carries that account. What widening the matcher surfaced:

| revealed | what it was |
|---|---|
| `Widget.paintRectangle` | dead — a ~30-line legacy device-space paint helper with zero callers anywhere |
| 2 rule `[S]` sites | `FrameWdgt._reactToBeingDropped → @pinPopUp`, `Widget._destroyNoSettle → @onClickOutsideMeOrAnyOfMyChildren` — both conscious and correct, now carrying the `# public-call-sanctioned:` marker they could never be asked for |
| 1 rule `[U]` site | `InspectorWdgt.filterProperties`, an internal helper wearing a public name — renamed `_filterProperties` |
| +1 handler body | one pointer handler had never been scanned by `check-raw-pointer-reads` at all |

⚠ **It happened a THIRD time, 2026-08-24**, found while building RULE 1b of `check-menu-actions` (which
must know whether a class defines a method at all): the matcher demanded EXACTLY ONE space after the
colon, so nine methods whose author aligned a short body — `softWrapOn:  -> @setSoftWrap true`, the six
`buildWindow:  -> …` app doors, `DataflowEngine.frameSource`, `DoubleLinkedList.constructor` — were
checked by no gate. The guard could not see them either: its own precondition demanded `: \S`, and a
second space is not `\S`. Both now read `: +`. The lesson each time is the same one, and it is about
where the matcher's authority comes from: write it against the LANGUAGE, never against a house
formatting habit. Widening it moved the method total 3305 → 3314 and changed no gate's verdict.

⚠ **And a FOURTH time, 2026-10-25: the class side.** `methodBoundary` had no rule for a 2-space `@name:`
key, so 109 class-side methods were nobody's: 1259 of their body lines sat in no span at all, and 422 more
were credited to the INSTANCE method written above them (`ActivePointerWdgt.processWheel` "contained"
`@wheelTakerAbove`; five `InputEvent` constructors "contained" `@fromBrowserEvent`). A gate then
attributed what a static does to a method that does not do it — or saw none of it. What reading the class
side surfaced:

| revealed | what it was |
|---|---|
| `FooterBandLayout.@arrange` | rule `[F]`: an in-pass placement (every caller is its host's own arrange) wearing a public name — renamed `@_arrange` |
| `InfoDocs.@_buildInfoDocNextTo` | rule `[G]` ×4: a one-off builder wearing the low-level tier, calling four self-settling wrappers — folded into its single caller, the public `@createNextTo` |
| `StackElementsSizeAdjustingWdgt.@includeInNewWidgetMenu` | dead — the menu that asked it is long gone; deleted |

`unseenMethodHeaders()` in the same module is the **regression guard**: `check-dead-methods` (which owns
the method inventory) FAILS on any class-level line that ends in an arrow, or opens an unbalanced paren
list, that `METHOD_HEADER` does not match. A future spelling therefore becomes a build error that names
its own fix, instead of another silent hole. It reads the class-method indent only.

## 6c. What a line of CoffeeScript IS — ONE masker

Every gate and census that reads CoffeeScript as code reads it through **`buildSystem/lib/coffee-mask.js`**'s
`coffeeMask(text, where)`: one record per line, `{ mask, code, bare, comment, continuesLiteral }`.
- `mask` — per character, `'code'` | `'str'` | `'lit'` | `'cut'`: `'str'` is a string's or a heredoc's text with its
  quotes, `'lit'` any other literal's (a regex or heregex with its flags, a JS passthrough) — so a reader that wants
  the strings, a name dispatched by one, counts no word of a regex —, everything between an interpolation's braces is
  `'code'`, a comment `'cut'`.
- `code` — the line with its comment blanked, literals kept: for a rule that reads a name dispatched by a string, a
  colour written in a string, or the CoffeeScript a heredoc holds.
- `bare` — the line with its comment and every literal's contents blanked, each literal's delimiters and an
  interpolation's code kept: for a rule that reads code alone. `f "x", 1` reads `f " ", 1`, so a call given a literal
  still reads as a call given an argument.
- `comment` — the line's comment text, where a sanction marker is read; `isCommentOnly(record)` says whether a line
  holds a comment and nothing else (the line a marker for the code below it is written on).
- `continuesLiteral` — whether the line starts inside a literal an earlier line opened (a heredoc's body and closing
  line, a string spanning lines): a reader looking for a class-body key or a method boundary skips it. (A line that
  merely BEGINS with a literal does not continue one.)

Every view keeps every column. The reading is the CoffeeScript lexer's own (`CoffeeScript.tokens`, the bundled compiler
the page runs), so a `#` or a quote inside a string, a regex or a heregex, a string spanning lines, the `#` lines of a
heredoc, `#{…}` interpolation (a comment inside a multi-line one included), a heregex's own `# …` comments and a `###`
block all read as they compile; a text the lexer refuses is refused (`COFFEE_MASK_UNLEXABLE <where>:<line>`), never
read by a guess — a gate it stops ends as an operational failure (exit 2) naming the file and line. A heredoc holding
CoffeeScript (a tool's source, a `Macro.fromString` verb) is a literal like any string: a reader that treats one as code
masks the heredoc's text as a text of its own — for a verb, the text the compiler makes of it, which `lib/macro-sources.js`
hands every reader. A
process lexes a text once — the records are kept by the text they read, so every reader of a file shares its reading
(they are read-only) — and src costs about 0.4 s to lex.

Re-implement none of it. A per-line `#` cut hides the code after a `#` that a string or a regex holds, and reads a
heredoc's `#` lines as comments; a quote-aware line scan is opened by a quote inside a regex and then reads the
comment after it as code; a stateful character scan reads `///'''///` as a heredoc that never closes. Its cases are
`lib/coffee-mask-selftest.js`. A text that is not CoffeeScript has a reader of its own: a gate's `*-allowlist.txt`
(`name  # reason`) is read by `lib/allowlist-file.js`, a tests-repo JS file by `lib/js-mask.js`.

## 7. Documented BOUNDARIES (reasoned gaps, not silent ones)

What the layering gate deliberately does NOT cover, and why — so a maintainer reads a reasoned boundary, never a hole:

- **`escalateEvent`'s plane-local arguments are gated only where a static rule can be sound.**
  The press facts no longer escalate — the hand drives the press climb and maps the pointer into each
  receiver's plane — but base `Widget.activated` (and `doubleActivated`) still escalate their `pos` up the
  parent chain verbatim, so a pos that crosses a mapped-plane boundary (out of a scrolled pane or an island) is
  still plane-local to the SENDER; a pos-consuming gesture handler on a plane's ancestor must re-derive its
  point (`@screenPointToMyPlane world.hand.position()` — the paint-time-scroll arc's case law: a stationary
  click on scrolled content slammed the drag-to-scroll to its clamp). `check-plane-discipline` rule C1 holds it
  on the scroll-translation providers (the escalated handler names are derived from the `escalateEvent` calls in
  src); beyond them it stays a rule, enforced by review. No sound static check exists:
  whether a handler consumes `pos` GEOMETRICALLY (vs ignoring it, vs plane-safe same-plane use) is semantic, and
  the receiver set ("can this class sit above a mapped plane?") is a tree property no text scan sees. The rule
  lives in `docs/architecture/viewports-and-planes.md` (Boundaries and horizons); the raw-pointer lint covers the
  adjacent-but-different shape (raw `hand.position()` reads at band/containment sites).

- **The `.add` MEMBER form (`expr.add` / `@expr().add`) is excluded; the `@add` SELF form IS covered.** `.add` collides
  with `Point#add`/`Rectangle#add` (vector arithmetic, ubiquitous: `@topLeft().add pt`); a name scanner cannot tell a
  Widget structural add from a Point add on an expression without type inference (29 of 35 census hits were `Point#add`).
  `@add` is unambiguous (self == Widget.add) and IS rule [G]'s `SELF_ADD_CALL`. The runtime throw backstops the member
  form and construction-time `add()` on an orphan.
- **`collapse`/`unCollapse` are now COVERED by [G]** (they were once in `WRAPPER_EXCLUDED`). They appeared in layout
  passes (`FrameWdgt._positionAndResizeChildren`'s editButton/internalExternalSwitchButton); the end-of-cycle-flush drawdown convert routed those call-sites to the
  idempotent `_collapseNoSettle`/`_unCollapseNoSettle` cores, so `WRAPPER_EXCLUDED` does not carry them and [G] now
  guards them like any other wrapper. `WRAPPER_EXCLUDED` now holds only `add` (the `Point#add`-ambiguous member form, above).
- **The TRANSITIVE closure of [G] was prototyped and REJECTED as intractable — DO NOT re-attempt.** A name-based
  backward-reachability fixpoint ("a low-level method must not REACH a settling method by any path") balloons to
  ~720–870 names / ~500–710 false hits: `constructor → buildAndConnectChildren → add` is a universal hub reached by
  `new @constructor` / `@constructor.name` everywhere, and the raw setters / `*NoSettle` cores themselves land in the
  set — so it flags the very "cores call cores" pattern it should bless. Name-based reachability cannot model the orphan
  guard (a receiver's attached-ness is dynamic). The DIRECT rule [G] is the maximal SOUND static check; the throw
  backstops the transitive/dynamic cases. Evidence: `docs/archive/lint-ratchet-static-checks-plan.md` (EXECUTED).
- **(DONE) Rule [D] is now a HARD ban with no carve-out.** Forbidding macros from the private/immediate geometry API
  was once held back by the construction "measure-and-size" read-back (size a soft-wrapping text to its wrapped HEIGHT
  at a chosen WIDTH on an orphan). That carve-out is now CLOSED: the fix is to ATTACH the widget first (to its
  destination or the desktop) and use the PUBLIC setters — an attached `setWidth` self-settles, so the text wraps in
  place and its height is then readable. `MACRO_FORBIDDEN_CALL` accordingly bans every `_private` call and every `raw*`
  (now pixel-only) accessor in a macro, with no sanctioned escape; the retired `silent*`/`fullRaw*` arms were dropped
  with the §2 renames.
- **(DONE 2026-06-25) `isLowLevel`'s `/Layout$/` arm was VESTIGIAL — removed.** After the layout-method-family rename
  every real layout pass is `_reLayout*`-prefixed (already caught by `/^_/`), so `/Layout$/` only ever matched non-pass
  methods whose name ends in "Layout": `implementsDeferredLayout` (×3, capability queries), the `*HorizLayout` menu
  actions (`newParentChoiceWithHorizLayout` / `attachWithHorizLayout`), and `countOfChildrenInHorizontalStackLayout` (a
  query) — mis-classifying them as low-level. It was a TWO-PART change (the reason it wasn't a one-liner): reclassifying
  `Widget.implementsDeferredLayout` (`@_reLayout != Widget::_reLayout`, a method-REFERENCE comparison) to non-low-level
  makes it an `[F]` subject, and its `@_reLayout` would false-match `APPLY_CALL`. So the arm removal was PAIRED with a
  second `APPLY_CALL` lookahead that skips a comparison / `is` / `isnt` right after the name (a value compared, never
  applied), so `newParentChoiceWithHorizLayout` needs no `# nosettle-sanctioned` marker.
  Self-tested: `[F]` still flags a real `@_reLayout()` apply, skips `@_reLayout != Widget::_reLayout`. Gate green + suite
  165/165 byte-identical + apps 12/12.

---

## 8. How-to

**Add a new `check-layering` rule.** (1) Add the call-detecting regex/predicate near the other constants, comment the
rule (subject / forbidden / why / runtime twin / marker) the way [A]–[T] are. (2) Add the check inside `checkFile`'s
per-method loop, under the right tier guard (`isLowLevel(method)` / `isImmediateMutator(method)` / the non-mutator
branch). (3) If it needs an escape hatch, add a per-method marker (mirror the `methodNoSettleMarked` logic) rather than a
central allowlist. (4) Update the summary line + the failure footer to name the new letter. (5) **Land it green** — see
self-test below; triage every hit (fix the code, or mark with a reason); record the marker count.

**Add a new rule — pick the TIER first (§3b): sound negative ⇒ gate · count-shaped ⇒ ratcheted stink ⇒ heuristic ⇒
advisory census.** Shipping a heuristic as a gate is the one mistake this system cannot absorb.

**Add a new gate.** Clone an existing `buildSystem/check-*.js` (line scanner: exit `0`/`1`/`2`; read each file through
`lib/coffee-mask.js`'s `coffeeMask` (§6c) and group it with `lib/coffee-method-header.js` — `methodSpans` /
`methodBoundary`), then clone its **wiring block** in `build_it_please.sh`:
```sh
if ! $noSyntaxCheck ; then
  echo "checking <thing> ..."
  node ./buildSystem/check-<thing>.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: <thing> gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... <thing> OK"
fi
```
Place it among the other gates (~:337–780). If it scans the sibling tests, guard it
(`&& $PROFILE_SHIPS_TESTS && [ -d ../Fizzygum-tests ]`) so a build whose profile omits the `harness` part self-skips —
that derived fact is the same one that writes `BUILDFLAG_LOAD_TESTS`, so gate and world can never disagree about
whether this build has tests.

**Add an advisory census.** `require('./census-public-private-calls.js')` and call `runCensus()` — it hands you the
whole-system class model (`classInfo` / `chainOf` / `resolve`) and `allMethods` with per-method body lines and markers.
Do NOT re-implement the parse: Fizzygum is image-like (no module system, one class per file, every class a
global), so that model is the subtle part and a second copy would drift. Then: always exit 0 (2 on operational error),
support `--json <file>`, print SUMMARY COUNTS by default with `--full` for the lists, add a step to `fg critique`, and
write findings to the `duplication-report/triage-report.md` ledger rather than to a commit.
⚠ `runCensus()`'s `bodyLines` carry BARE code (literal contents blanked: fine for call extraction, wrong for comparing
bodies) — if you need text with strings intact, re-read the source and take `coffeeMask`'s `code` view, as
`census-hierarchy-duplication.js` does.

**`compile-fragment.js` — the hand tool beside the syntax gate.** `check-coffee-syntax.js` drives
every *shipped source* through the real `Class.coffee`; `compile-fragment.js` compiles ONE pasted
fragment the same fragmented way, for the question "what does this signature/call actually become".
Use it before converting a parameter list — especially to confirm a trailing `key: value` lands as a
SEPARATE final argument. Its `super` rewrite is `Class.coffee`'s own, run through `lib/meta-compiler.js`
(the shim the syntax gate uses), so it cannot drift from the browser's. ⚠⚠ A spelling that compiles
WITHOUT error and mis-binds: keys on the head line ending in a comma with more keys indented below
(`new X target: t, action: a,` / `  face: f` — TWO object arguments, the second dropped by an `(opts)`
head). Write `new X` with every key in one indented block. ⚠ `coffee -bcp <wholefile>` is NOT a substitute:
it applies ES-class semantics (parameters bound after `super`, bare `super` illegal as a
statement) that this tree's emit does not have, and false-fails on most files.

**Self-test a rule (a lint that can't fail is worthless).** Plant a known violation in a throwaway source file, confirm
the build/gate **aborts loudly** with the right message, confirm the marker exempts it, then **delete the fixture**:
```sh
printf 'class __X extends Widget\n  _someNoSettle: ->\n    @add aChild\n' > src/__X.coffee
node ./buildSystem/check-layering.js   # expect: [G] ... @add ... — exit 1
rm -f src/__X.coffee
node ./buildSystem/check-layering.js   # expect: 0 violations — exit 0
```

**Debug / bisect a gate.** `./build_it_please.sh --noSyntaxCheck` skips *all* gates — use it to confirm a build failure
is the gate and not the build, then run the single gate directly (`node ./buildSystem/check-<x>.js`, exit code +
stderr). A gate edit is pure tooling: re-run the gate, no behaviour rebuild; only re-run the suite if you ALSO moved
source to satisfy a new rule.

---

## Appendix — file:line anchors (grep the symbol; numbers drift)

- `buildSystem/check-layering.js` — `PUBLIC_SETTERS`/`TEXT_SETTERS`/`RECALC_WHITELIST`; `isLowLevel` /
  `isImmediateMutator` (the tier predicates, §2); `SETTLE_CALL`/`WRAPPER_EXCLUDED`/`SELF_ADD_CALL`/`NOSETTLE_MARKER` (the
  [G] constants); `LEAF_FORBIDDEN` ([I]); `APPLY_CORNER`/`K_SEAM_CALL`/`K_REACT_CALL`/`K_POLY_APPLY` ([K]);
  `CALLBACK_PREFIX`/`CALLBACK_SHAPE`/`LEGACY_CALLBACK_FRAGMENT` ([L]); `FRAGMENT_BANNED` ([M]);
  `SEAM_VERB_BANNED` ([N]); `COALESCED_CALL`/`COALESCED_CALLER_ALLOWLIST` ([O]);
  `CONNECTOR_CALL`/`CONNECTOR_CALLER_ALLOWLIST` ([Q]); `USERLAND_FILES`/`USERLAND_PRIVATE_CALL`/`PRIVATE_USE_MARKER`
  ([R]);
  `readingOf` (each file's `coffeeMask`, read once for the three passes); `methodBoundary` (imported from
  `lib/coffee-method-header.js`); `discoverSettlingWrappers`; `checkFile` (rules [A]–[T]);
  `checkMacroText` (rule [D], over `lib/macro-sources.js`); `DOUBLE_SETTLE_MARKER`/`T_SELF_PUB_CALL`/`checkDoubleSettle` ([T]).
- `buildSystem/check-call-separation.js` — `BASELINE_S_SETTLING`/`BASELINE_S_EFFECTFUL` ([S]) +
  `BASELINE_U_EFFECTFUL`/`BASELINE_U_QUERY` ([U]) inline ratchets; reads `public-api-allowlist.txt` (through
  `buildSystem/lib/allowlist-file.js`, the one reader of every `*-allowlist.txt`);
  requires `census-public-private-calls.js` (`runCensus`, `PUBLIC_CALL_MARKER`), whose R4 reads the tests repo's
  code through `buildSystem/lib/tests-repo-code.js` (`testsRepoCode` / `coffeeCode` / `jsCode` / `macroCode`, a test's
  macro sources read by `buildSystem/lib/macro-sources.js`) and reads CoffeeScript with
  `buildSystem/lib/coffee-mask.js` (`coffeeMask`, §6c); the reader's cases are `lib/tests-repo-code-selftest.js`, one
  per reading.
- `buildSystem/lib/source-files.js` — `coffeeFilesIn` (the one walk: `SOURCE_TREE_MALFORMED`), `srcFiles` /
  `harnessFiles` / `compiledFiles`, `sourceRoots` (`SOURCE_RAILS`), `sourceName`; its cases are
  `lib/source-files-selftest.js`. `buildSystem/lib/planted-src.js` `plantedTree({ testsRepo })` is the tests-repo copy a
  `harness/<rel>` plant lands in.
- `buildSystem/check-thin-wraps.js` — `HEADER`/`GUARD`/`EXEMPT`; twinless skip (`if (!byName.has(base)) continue`).
- `buildSystem/check-constructors-build.js` — `METHOD`/`BUILD`/`EXEMPT`; the `inctor` state machine (multi-line-ctor-header aware).
- `buildSystem/check-dead-methods.js` + `buildSystem/dead-method-allowlist.txt`.
- `buildSystem/check-unresolved-sends.js` + `buildSystem/unresolved-sends-allowlist.txt` — `CALL_RE` / `BUILTINS` /
  `readingOf`; `check-unresolved-sends-selftest.js` (which also pins the def forms and the call harvest). The
  implementor harvest itself — `DEF_FORMS` / `definedName` / `harvestDefs`, callable-only, over a text's `coffeeMask`
  reading — is `buildSystem/lib/name-definitions.js`, shared with `check-part-edges.js` and `lib/call-sites.js`.
- `buildSystem/check-stinks.js` — the inline `baseline` per stink; `--list <id>` enumerates one stink's sites.
- `buildSystem/check-part-edges.js` + `buildSystem/lib/part-edge-scan.js` — `stringLiteralsOf` /
  `guardedPartsPerLine` (its optional `ownerOfMember` is the member existence guard) / `declaredRequires` (the
  eager-vs-lazy discount, which `what-pins-core.js` reads too); `buildSystem/lib/install-edges.js` (`installEdges` / `harnessPresent`); `soleProviders` /
  `memberReaches` / `superReaches`; `check-part-edges-selftest.js`.
- the three retirement tombstones — `buildSystem/check-region-markers.js` (`# »>>`), `check-source-vault.js`
  (`_coffeSource` + boot-layer `Object.keys(window)`), `check-whole-file-markers.js` (the per-file exclusion comments):
  each an inline per-kind `baseline`, all at 0.
- `buildSystem/check-shippable-coverage.js` — shells `build.py --list-shippable` and `--list-boot` for the
  partition's own answer.
- `buildSystem/census-hierarchy-duplication.js` — `bodyTextOf` / `signatureOf` / `signatureHasEffect`.
- `buildSystem/census-property-placement.js` — `STRING_WORDS` / `MEMBER_FILES` + `readAsMemberElsewhere` (the three
  exclusions); `lineOwnerOf` (the `@classlevel` attribution).
- `buildSystem/check-coffee-syntax.js` — loads `src/meta/Class.coffee` through
  `buildSystem/lib/meta-compiler.js` (`loadMetaCompiler` / `bundledCoffeeScript` / `rewriteSuper`, shared with
  `lib/call-sites.js` and `compile-fragment.js`) to compile fragmented.
- `buildSystem/check-call-arguments.js` — `callersTest` and `arityTest` over `buildSystem/lib/call-sites.js`'s
  `callSites` (`csCallsOf`: the three 2.0.3 call shapes; the identity pass; the definitions table, `defs`;
  `lib/call-sites-selftest.js` holds one case per reading), which reads every macro source through
  `buildSystem/lib/macro-sources.js` (its cases `lib/macro-sources-selftest.js`);
  `census-call-arity.js` reads the same table. JS is parsed with `vendor/acorn/acorn.js` (pinned, README beside it),
  which `lib/js-mask.js` (`maskJs`) uses too.
- `Fizzygum-tests/scripts/check-tests-syntax.js`, `Fizzygum-tests/scripts/check-refs.js`,
  `Fizzygum-tests/scripts/check-visualisations.js`,
  `Fizzygum-tests/scripts/check-macro-source-discipline.js` — the last one's rule is a pure function
  (`violationsInTest`) so its acceptance corpus, `check-macro-source-discipline-selftest.js` (run on
  every build), can plant a violation in memory and require the gate to catch it.
- `buildSystem/run-selftests.js` + `buildSystem/lib/what-runs.js` (`scriptFiles` / `skippedEntry` / `--list-scripts`,
  `CONVENTIONS` / `discover` / `runSet`) + `buildSystem/lib/selftest-verdict.js` (`VERDICT_RE` / `cases` / `verdict`) —
  the self-tests step, the tooling's own files every reader of them shares, and the run set `check-hand-lists.js` reads.
- `build_it_please.sh` — gate wiring (~:333–945), each `if ! $noSyntaxCheck` + `$?`-gated `exit 1`; the four
  tests-repo gates additionally `&& $PROFILE_SHIPS_TESTS && [ -d ../Fizzygum-tests ]`.
- `src/basic-widgets/Widget.coffee` — `_settleLayoutsAfter` (~:928; the one-flush throw ~:952); `_invalidateLayout`
  (~:4919; `FLOWRULE_VIOLATION` ~:4959); the immediate-mutator apply corners (`_apply*`/`_commit*`) + the `_<name>NoSettle` cores.

## See also
- `docs/architecture/layering-naming-convention.md` — the full naming convention (the geometry-apply 2×2 + the notification
  (perspective × phase) grid) and its two runtime audit gates; rules [I]/[K]/[L]/[M] (and the [M] fragment-ban) enforce it.
- `docs/archive/layout-system-architecture-assessment.md` — the runtime flush model + the invariant in depth (the *why*).
- `docs/archive/lint-ratchet-static-checks-plan.md` — the arc that built rule [G] (STATUS: EXECUTED); the rejected-transitive record.
- `docs/archive/lint-generic-rules-carryover-plan.md` — the arc that carried over the generic (Pharo SmallLint/Renraku) rules:
  the unresolved-sends gate, the seven stinks, the two advisory censuses, `fg critique`. Its §8 is the surveyed-but-
  DEFERRED backlog (action-string resolution, must-call-super, paired-method contracts, dead classes, metrics ratchet,
  the console.log decision, paren-less call harvesting, the stink-masking upgrade, empty-catch).
- `docs/tooling/duplicated-code-detection.md` — the two clone scanners + the triage-ledger cycle the censuses feed.
- `docs/archive/public-private-call-separation-plan.md` — the AUTHORED (not started) command/query call-separation
  campaign: planned rules [S] (private must not self-call a public command) / [T] (a settling method must not
  call another settling public method) / [U] (self-only public methods must be `_`-tier), sized by
  `buildSystem/census-public-private-calls.js` (the analysis tool noted in §3c).
- `docs/archive/end-of-cycle-flush-drawdown-plan.md` / `end-of-cycle-flush-inventory.md` — the campaign that owns the
  collapse/unCollapse convert.
- Memory `fizzygum-layering-naming-tiers` — the tier predicates + the `NoSettle` convention.
